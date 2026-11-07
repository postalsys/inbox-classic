//! A port of the tree building of node-html-parser 9, which email-content segments HTML with.
//!
//! email-content relies on its exact behaviour: which elements a start or end tag closes, that
//! `<pre>`, `<script>`, `<style>` and `<noscript>` content is raw text, that an element closed
//! implicitly keeps the range of its start tag, and that elements left open at the end are removed
//! with their children moved up. All of that is reproduced, with source ranges as byte offsets.
//!
//! node-html-parser finds markup with one regular expression run with a backtracking engine. The
//! tokenizer here matches the same text, chosen the same way, but in a single forward pass: what
//! the expression accepts after a tag name reduces to a scan that can only fail when no `>`
//! follows, and every search for a closing delimiter that found nothing is remembered. The tree is
//! an arena, walked without recursion, so deep nesting cannot overflow the stack.

use std::collections::HashMap;
use std::sync::LazyLock;

use crate::html_text::decode_entities;
use pe_jsre::{JsRegex, is_space};

const FRAME: &str = "documentfragmentcontainer";
/// Length of `<documentfragmentcontainer>`, which the source is wrapped in.
const FRAME_OFFSET: usize = 27;

#[derive(Debug)]
pub(crate) enum NodeKind {
    Root,
    Element {
        /// The tag name as written.
        tag: String,
        /// Lowercased tag name.
        lower: String,
        /// Attributes, keys lowercased, values entity decoded.
        attrs: Vec<(String, String)>,
    },
    Text,
}

#[derive(Debug)]
pub(crate) struct Node {
    pub kind: NodeKind,
    pub parent: Option<usize>,
    pub children: Vec<usize>,
    /// Byte range in the source.
    pub range: (usize, usize),
}

pub(crate) struct Dom {
    pub nodes: Vec<Node>,
}

pub(crate) const ROOT: usize = 0;

impl Dom {
    pub fn lower_tag(&self, node: usize) -> Option<&str> {
        match &self.nodes[node].kind {
            NodeKind::Element { lower, .. } => Some(lower),
            _ => None,
        }
    }

    /// `getAttribute`, with the key lowercased.
    pub fn attribute(&self, node: usize, key: &str) -> Option<&str> {
        match &self.nodes[node].kind {
            NodeKind::Element { attrs, .. } => attrs
                .iter()
                .rev()
                .find(|(name, _)| name == key)
                .map(|(_, value)| value.as_str()),
            _ => None,
        }
    }

    fn tag(&self, node: usize) -> Option<&str> {
        match &self.nodes[node].kind {
            NodeKind::Element { tag, .. } => Some(tag),
            _ => None,
        }
    }

    fn append(&mut self, parent: usize, child: usize) {
        self.nodes[child].parent = Some(parent);
        self.nodes[parent].children.push(child);
    }

    fn remove_child(&mut self, parent: usize, child: usize) {
        if let Some(at) = self.nodes[parent].children.iter().rposition(|&c| c == child) {
            self.nodes[parent].children.remove(at);
        }
    }

    fn reparent_children(&mut self, source: usize, parent: usize) {
        let children = std::mem::take(&mut self.nodes[source].children);
        for child in children {
            self.append(parent, child);
        }
    }
}

/// The rawAttributes expression of node-html-parser.
static ATTRIBUTE: LazyLock<JsRegex> = LazyLock::new(|| {
    JsRegex::fixed(
        r#"([_a-zA-Z()[\]#@$.?:][a-zA-Z0-9-._:()[\]#]*)(?:\s*=\s*((?:'[^']*')|(?:"[^"]*")|\S+))?"#,
        "",
    )
});

/// Attributes the way node-html-parser reads them: the first of each spelling wins, then keys are
/// lowercased and a later spelling overwrites an earlier one.
fn parse_attributes(raw: &str) -> Vec<(String, String)> {
    let mut raw_attrs: Vec<(&str, Option<&str>)> = Vec::new();
    for caps in ATTRIBUTE.re().captures_iter(raw) {
        let key = caps.get(1).map_or("", |m| m.as_str());
        if key == "__proto__" || raw_attrs.iter().any(|(k, _)| *k == key) {
            // `attrs[key] = attrs[key] || val`: a later value only fills an empty first one.
            if let Some(existing) = raw_attrs.iter_mut().find(|(k, _)| *k == key)
                && existing.1.is_none_or(str::is_empty)
            {
                existing.1 = caps.get(2).map(|m| unquote(m.as_str()));
            }
            continue;
        }
        raw_attrs.push((key, caps.get(2).map(|m| unquote(m.as_str()))));
    }
    raw_attrs
        .into_iter()
        .map(|(key, value)| (key.to_lowercase(), decode_entities(value.unwrap_or(""))))
        .collect()
}

fn unquote(value: &str) -> &str {
    let bytes = value.as_bytes();
    if !bytes.is_empty() && (bytes[0] == b'"' || bytes[0] == b'\'') {
        // `val.slice(1, val.length - 1)`: an unclosed `\S+` value loses its last character too.
        let mut inner = value[1..].chars();
        inner.next_back();
        inner.as_str()
    } else {
        value
    }
}

/// Characters node-html-parser accepts in a tag name after the first letter.
fn is_name_char(c: char) -> bool {
    let code = c as u32;
    matches!(c, '-' | '.' | ':' | '@' | '0'..='9' | 'A'..='E')
        || (0x46..=0x1FFF).contains(&code)
        || (0x200C..=0x200D).contains(&code)
        || (0x203F..=0x2040).contains(&code)
        || (0x2070..=0x218F).contains(&code)
        || (0x2C00..=0x2FEF).contains(&code)
        || (0x3001..=0xD7FF).contains(&code)
        || (0xF900..=0xFDCF).contains(&code)
        || (0xFDF0..=0xFFFD).contains(&code)
}

enum MatchKind {
    Comment,
    Cdata,
    Tag {
        closing: bool,
        name: (usize, usize),
        attrs: (usize, usize),
        self_closing: bool,
    },
}

struct Match {
    start: usize,
    end: usize,
    kind: MatchKind,
}

/// Forward searches with memory: the cursor only advances, so a needle that is absent after one
/// position is absent after every later one, and a found occurrence answers every query between
/// the previous query and itself.
#[derive(Default)]
struct Finder {
    cache: HashMap<String, (usize, Option<usize>)>,
}

impl Finder {
    fn find(&mut self, data: &str, needle: &str, from: usize) -> Option<usize> {
        if let Some(&(last_from, result)) = self.cache.get(needle)
            && from >= last_from
            && result.is_none_or(|found| from <= found)
        {
            return result;
        }
        let result = data.get(from..).and_then(|rest| rest.find(needle)).map(|at| from + at);
        self.cache.insert(needle.to_string(), (from, result));
        result
    }
}

struct Tokenizer<'d> {
    data: &'d str,
    has_cdata: bool,
    last_gt: Option<usize>,
    finder: Finder,
}

impl Tokenizer<'_> {
    fn char_at(&self, at: usize) -> Option<char> {
        self.data.get(at..).and_then(|rest| rest.chars().next())
    }

    fn skip_ws(&self, mut at: usize) -> usize {
        while let Some(c) = self.char_at(at) {
            if !is_space(c) {
                break;
            }
            at += c.len_utf8();
        }
        at
    }

    fn has_gt_from(&self, at: usize) -> bool {
        self.last_gt.is_some_and(|gt| gt >= at)
    }

    /// `\s*(\/?)>` at `at`: the end of the match and whether a slash closed it.
    fn exit(&self, at: usize) -> Option<(usize, bool)> {
        let w = self.skip_ws(at);
        let rest = &self.data[w..];
        if rest.starts_with("/>") {
            Some((w + 2, true))
        } else if rest.starts_with('>') {
            Some((w + 1, false))
        } else {
            None
        }
    }

    /// `((?:\s+[^>]*?(?:'[^']*'|"[^"]*")?)*)\s*(\/?)>` anchored at `q`, as a backtracking engine
    /// would match it. Returns the end of the attribute group, the end of the match and the slash.
    ///
    /// Inside the group the lazy run moves forward one character at a time, first trying to jump
    /// over a quoted string, then to start a new iteration at whitespace, then to finish at `>` or
    /// `/>`. A path from a whitespace position succeeds exactly when a `>` follows, so the scan
    /// never needs to backtrack.
    fn tail(&mut self, q: usize) -> Option<(usize, usize, bool)> {
        let first = self.char_at(q)?;
        if !is_space(first) {
            return self.exit(q).map(|(end, slash)| (q, end, slash));
        }
        let mut j = self.skip_ws(q);
        if !self.has_gt_from(j) {
            return None;
        }
        loop {
            let c = self.char_at(j)?;
            if (c == '"' || c == '\'')
                && let Some(close) = self.find_char(c, j + 1)
            {
                let after = close + 1;
                if self.char_at(after).is_some_and(is_space) {
                    let next = self.skip_ws(after);
                    if self.has_gt_from(next) {
                        j = next;
                        continue;
                    }
                }
                if let Some((end, slash)) = self.exit(after) {
                    return Some((after, end, slash));
                }
            }
            if is_space(c) {
                let next = self.skip_ws(j);
                if !self.has_gt_from(next) {
                    return None;
                }
                j = next;
                continue;
            }
            if let Some((end, slash)) = self.exit(j) {
                return Some((j, end, slash));
            }
            if c == '>' {
                return None;
            }
            j += c.len_utf8();
        }
    }

    fn find_char(&mut self, c: char, from: usize) -> Option<usize> {
        let mut buf = [0u8; 4];
        let needle: &str = c.encode_utf8(&mut buf);
        let data = self.data;
        self.finder.find(data, needle, from)
    }

    fn match_at(&mut self, lt: usize) -> Option<Match> {
        let data = self.data;
        let rest = &data[lt..];
        if rest.starts_with("<!--")
            && let Some(close) = self.finder.find(data, "-->", lt + 4)
        {
            return Some(Match {
                start: lt,
                end: close + 3,
                kind: MatchKind::Comment,
            });
        }
        if self.has_cdata
            && rest.starts_with("<![CDATA[")
            && let Some(close) = self.finder.find(data, "]]>", lt + 9)
        {
            return Some(Match {
                start: lt,
                end: close + 3,
                kind: MatchKind::Cdata,
            });
        }
        let bytes = data.as_bytes();
        let closing = bytes.get(lt + 1) == Some(&b'/');
        let name_start = lt + 1 + usize::from(closing);
        if !bytes.get(name_start).is_some_and(u8::is_ascii_alphabetic) {
            return None;
        }
        // The name is greedy; it gives characters back only where whitespace can then follow.
        let base = name_start + 1;
        let mut name_end = base;
        let mut ws_inside = Vec::new();
        for (at, c) in data[base..].char_indices() {
            if !is_name_char(c) {
                break;
            }
            if is_space(c) {
                ws_inside.push(base + at);
            }
            name_end = base + at + c.len_utf8();
        }
        let candidates = std::iter::once(name_end).chain(ws_inside.into_iter().rev());
        for end_of_name in candidates {
            if let Some((attrs_end, end, self_closing)) = self.tail(end_of_name) {
                return Some(Match {
                    start: lt,
                    end,
                    kind: MatchKind::Tag {
                        closing,
                        name: (name_start, end_of_name),
                        attrs: (end_of_name, attrs_end),
                        self_closing,
                    },
                });
            }
        }
        None
    }

    fn next_match(&mut self, from: usize) -> Option<Match> {
        let mut at = from;
        loop {
            let lt = at + self.data.get(at..)?.find('<')?;
            if let Some(found) = self.match_at(lt) {
                return Some(found);
            }
            at = lt + 1;
        }
    }
}

fn in_table(table: &[(&str, &[&str])], parent: &str, child: &str) -> bool {
    table.iter().any(|(key, set)| {
        (*key == parent || key.to_uppercase() == parent)
            && set.iter().any(|name| *name == child || name.to_uppercase() == child)
    })
}

const CLOSED_BY_OPENING: &[(&str, &[&str])] = &[
    ("li", &["li"]),
    ("p", &["p", "div"]),
    ("b", &["div"]),
    ("td", &["td", "th", "tr", "tbody", "tfoot"]),
    ("th", &["td", "th", "tr", "tbody", "tfoot"]),
    ("tr", &["tr", "tbody", "tfoot"]),
    ("thead", &["tbody", "tfoot"]),
    ("tbody", &["tbody", "tfoot"]),
    ("h1", &["h1"]),
    ("h2", &["h2"]),
    ("h3", &["h3"]),
    ("h4", &["h4"]),
    ("h5", &["h5"]),
    ("h6", &["h6"]),
    ("dt", &["dt", "dd"]),
    ("dd", &["dt", "dd"]),
];

const CLOSED_BY_CLOSING: &[(&str, &[&str])] = &[
    ("li", &["ul", "ol"]),
    ("a", &["div"]),
    ("b", &["div"]),
    ("i", &["div"]),
    ("p", &["div"]),
    ("td", &["tr", "table", "thead", "tbody", "tfoot"]),
    ("th", &["tr", "table", "thead", "tbody", "tfoot"]),
    ("tr", &["table", "thead", "tbody", "tfoot"]),
    ("tbody", &["table"]),
    ("tfoot", &["table"]),
    ("dt", &["dl", "body", "html"]),
    ("dd", &["dl", "body", "html"]),
];

const P_NOT_CLOSED_BY: &[&str] = &["a", "audio", "del", "ins", "map", "noscript", "video"];

const VOID_TAGS: &[&str] = &[
    "area", "base", "br", "col", "embed", "hr", "img", "input", "link", "meta", "param", "source", "track", "wbr",
];

fn is_void(name: &str) -> bool {
    VOID_TAGS.iter().any(|tag| *tag == name || tag.to_uppercase() == name)
}

fn is_raw_text(name: &str) -> bool {
    ["script", "noscript", "style", "pre"]
        .iter()
        .any(|tag| tag.eq_ignore_ascii_case(name))
}

/// Parse `html` the way `parse(html, { comment: false })` of node-html-parser does.
pub(crate) fn parse(html: &str) -> Dom {
    let data = format!("<{FRAME}>{html}</{FRAME}>");
    let data_end = data.len() - FRAME_OFFSET - 1;
    // Ranges are as node-html-parser reports them. An end tag swallowed by an unterminated quote
    // can put an end past the source; users of ranges clamp when they slice.
    let clamp = |at: usize| at.saturating_sub(FRAME_OFFSET);
    let mut dom = Dom {
        nodes: vec![Node {
            kind: NodeKind::Root,
            parent: None,
            children: Vec::new(),
            range: (0, html.len()),
        }],
    };
    let mut tokenizer = Tokenizer {
        data: &data,
        has_cdata: data.contains("<![CDATA["),
        last_gt: data.rfind('>'),
        finder: Finder::default(),
    };
    let mut stack = vec![ROOT];
    let mut current = ROOT;
    let mut last_text_pos: Option<usize> = None;
    let mut position = 0;

    let new_text = |dom: &mut Dom, parent: usize, start: usize, end: usize| {
        let id = dom.nodes.len();
        dom.nodes.push(Node {
            kind: NodeKind::Text,
            parent: None,
            children: Vec::new(),
            range: (clamp(start), clamp(end)),
        });
        dom.append(parent, id);
    };

    while let Some(found) = tokenizer.next_match(position) {
        let (tag_start, tag_end) = (found.start, found.end);
        if let Some(text_pos) = last_text_pos
            && text_pos < tag_start
        {
            new_text(&mut dom, current, text_pos, tag_start);
        }
        last_text_pos = Some(tag_end);
        position = tag_end;

        let (closing, name, attrs, self_closing) = match found.kind {
            MatchKind::Cdata => {
                new_text(&mut dom, current, tag_start, tag_end);
                continue;
            }
            MatchKind::Comment => continue,
            MatchKind::Tag {
                closing,
                name,
                attrs,
                self_closing,
            } => (closing, &data[name.0..name.1], &data[attrs.0..attrs.1], self_closing),
        };
        if name == FRAME {
            continue;
        }
        let mut leading_slash = closing;
        if !closing {
            if !self_closing {
                while dom
                    .tag(current)
                    .is_some_and(|tag| in_table(CLOSED_BY_OPENING, tag, name))
                {
                    stack.pop();
                    current = *stack.last().unwrap_or(&ROOT);
                }
            }
            // `attributes.slice(1)`: the whitespace that separates them from the name is dropped.
            let raw_attrs = attrs.char_indices().nth(1).map_or("", |(at, _)| &attrs[at..]);
            let id = dom.nodes.len();
            dom.nodes.push(Node {
                kind: NodeKind::Element {
                    tag: name.to_string(),
                    lower: name.to_lowercase(),
                    attrs: parse_attributes(raw_attrs),
                },
                parent: None,
                children: Vec::new(),
                range: (clamp(tag_start), clamp(tag_end)),
            });
            dom.append(current, id);
            stack.push(id);
            current = id;
            if is_raw_text(name) {
                let close_markup = format!("</{name}>");
                let close = tokenizer.finder.find(&data, &close_markup, tag_end);
                let text_end = close.unwrap_or(data_end);
                if text_end > tag_end && !data[tag_end..text_end].chars().all(is_space) {
                    new_text(&mut dom, current, tag_end, text_end);
                }
                match close {
                    None => {
                        last_text_pos = Some(data.len() + 1);
                        position = data.len() + 1;
                    }
                    Some(close) => {
                        last_text_pos = Some(close + close_markup.len());
                        position = close + close_markup.len();
                        leading_slash = true;
                    }
                }
            }
        }

        if leading_slash || self_closing || is_void(name) {
            loop {
                let end = last_text_pos.unwrap_or(0).max(tag_end);
                if dom.tag(current) == Some(name) {
                    dom.nodes[current].range.1 = clamp(end);
                    stack.pop();
                    current = *stack.last().unwrap_or(&ROOT);
                    break;
                }
                let Some(open) = dom.tag(current) else {
                    break;
                };
                if in_table(CLOSED_BY_CLOSING, &open.to_uppercase(), name) {
                    stack.pop();
                    current = *stack.last().unwrap_or(&ROOT);
                    continue;
                }
                if open.eq_ignore_ascii_case("p")
                    && stack.len() > 1
                    && dom.lower_tag(stack[stack.len() - 2]) == Some(name.to_lowercase().as_str())
                    && !P_NOT_CLOSED_BY.contains(&name.to_lowercase().as_str())
                {
                    dom.nodes[current].range.1 = clamp(end);
                    stack.pop();
                    current = *stack.last().unwrap_or(&ROOT);
                    continue;
                }
                break;
            }
        }
    }

    // Elements left open are removed, their children moved up.
    while stack.len() > 1 {
        let Some(last) = stack.pop() else { break };
        let one_before = *stack.last().unwrap_or(&ROOT);
        let Some(parent) = dom.nodes[last].parent else { continue };
        if dom.nodes[parent].parent.is_none() {
            continue;
        }
        let same_tag = dom.tag(last).map(str::to_uppercase) == dom.tag(one_before).map(str::to_uppercase);
        if parent == one_before && same_tag {
            dom.remove_child(one_before, last);
            if let Some(grandparent) = dom.nodes[one_before].parent {
                dom.reparent_children(last, grandparent);
            }
            stack.pop();
        } else {
            dom.remove_child(one_before, last);
            dom.reparent_children(last, one_before);
        }
    }
    dom
}

/// A compact dump of the tree, for the comparison with node-html-parser.
#[cfg(test)]
pub(crate) fn dump(dom: &Dom, html: &str) -> String {
    let units = |at: usize| crate::util::js_len(&html[..at.min(html.len())]) + at.saturating_sub(html.len());
    let mut out = String::new();
    let mut stack: Vec<(usize, bool)> = dom.nodes[ROOT].children.iter().rev().map(|&c| (c, false)).collect();
    while let Some((node, closing)) = stack.pop() {
        if closing {
            out.push(')');
            continue;
        }
        let (start, end) = dom.nodes[node].range;
        match &dom.nodes[node].kind {
            NodeKind::Text => out.push_str(&format!("t{},{};", units(start), units(end))),
            NodeKind::Element { tag, .. } => {
                out.push_str(&format!("<{tag} {},{}(", units(start), units(end)));
                stack.push((node, true));
                stack.extend(dom.nodes[node].children.iter().rev().map(|&c| (c, false)));
            }
            NodeKind::Root => {}
        }
    }
    out
}

#[cfg(test)]
mod tests {
    use super::*;
    use serde_json::Value;

    fn fnv64(text: &str) -> String {
        let mut hash: u64 = 0xcbf29ce484222325;
        for byte in text.bytes() {
            hash ^= u64::from(byte);
            hash = hash.wrapping_mul(0x100000001b3);
        }
        format!("{hash:x}")
    }

    #[test]
    fn drops_the_last_character_of_an_unclosed_quoted_value() {
        // Found by fuzzing: the cut used to land inside a multibyte character.
        let dom = parse("<a b='x\u{20ac}>t</a>");
        let a = dom.nodes[ROOT].children[0];
        assert_eq!(dom.attribute(a, "b"), Some("x"));
    }

    #[test]
    fn builds_the_trees_node_html_parser_builds() {
        let cases: Value = serde_json::from_str(include_str!("../tests/fixtures/dom-cases.json")).unwrap();
        let mut failures = Vec::new();
        for case in cases["edge"].as_array().unwrap() {
            let html = case["html"].as_str().unwrap();
            let got = dump(&parse(html), html);
            if got != case["dump"].as_str().unwrap() {
                failures.push(format!("{html:?}\n  expected {}\n  got      {got}", case["dump"]));
            }
        }

        let all: Value = serde_json::from_str(include_str!("../tests/fixtures/cases.json")).unwrap();
        let mut bodies: Vec<&str> = Vec::new();
        for entry in all.as_array().unwrap() {
            let content = &entry["content"];
            let sections = content["sections"]
                .as_array()
                .cloned()
                .unwrap_or_else(|| vec![content.clone()]);
            for section in sections {
                if let Some(html) = section["html"].as_str()
                    && !crate::util::js_trim(html).is_empty()
                {
                    // Leaked so the borrowed list outlives the cloned sections.
                    let html: &'static str = Box::leak(html.to_string().into_boxed_str());
                    if !bodies.contains(&html) {
                        bodies.push(html);
                    }
                }
            }
        }
        let mut body_failures = 0;
        for entry in cases["hashes"].as_array().unwrap() {
            let html = bodies[entry["index"].as_u64().unwrap() as usize];
            if fnv64(&dump(&parse(html), html)) != entry["hash"].as_str().unwrap() {
                body_failures += 1;
                if body_failures <= 3 {
                    failures.push(format!("body {} differs", entry["index"]));
                }
            }
        }
        assert!(
            failures.is_empty(),
            "{} edge/body differences:\n{}",
            failures.len(),
            failures.join("\n")
        );
    }
}
