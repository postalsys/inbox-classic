//! Stage 3: HTML block segmentation.
//!
//! One block per run of inline content between block level elements. Containers such as a Gmail
//! quote wrapper do not become blocks; every block inside records its ancestry, because
//! interleaved replies put new content inside and between quote containers.
//!
//! Blocks tile the source: each block reaches back to the end of the previous one and the last
//! runs to the end of the document. Offsets are bytes into the HTML as given.

use std::collections::HashMap;
use std::sync::LazyLock;

use crate::Representation;
use crate::block::{Block, BlockKind, Evidence, EvidenceKind, FeatureContext, compute_features};
use crate::detect::{
    detect_attribution_line, detect_disclaimer, detect_forward_marker, detect_inline_announcement,
    detect_quoted_header_block, detect_rule_separator, detect_signature_delimiter, detect_signature_phrases,
    detect_signature_shape,
};
use crate::dom::{Dom, NodeKind, ROOT, parse};
use crate::html_text::{collapse_projection, decode_entities, strip_tags_to_text};
use crate::jsre::{JsRegex, is_js_ws};
use crate::patterns::{Selector, SelectorRole, patterns};
use crate::util::{is_blank, js_len, js_trim};

/// Elements that break a run of inline content.
const BLOCK_TAGS: &[&str] = &[
    "address",
    "article",
    "aside",
    "blockquote",
    "body",
    "center",
    "dd",
    "div",
    "dl",
    "dt",
    "fieldset",
    "figcaption",
    "figure",
    "footer",
    "form",
    "h1",
    "h2",
    "h3",
    "h4",
    "h5",
    "h6",
    "header",
    "hr",
    "html",
    "li",
    "main",
    "nav",
    "ol",
    "p",
    "pre",
    "section",
    "table",
    "tbody",
    "td",
    "tfoot",
    "th",
    "thead",
    "tr",
    "ul",
];

/// Elements whose content is never visible text.
const INVISIBLE_TAGS: &[&str] = &[
    "script", "style", "head", "title", "noscript", "template", "meta", "link",
];

/// Nesting beyond which the rest of a subtree becomes one run instead of being descended into.
const MAX_DEPTH: usize = 150;

/// Elements left open at the end that the parser is allowed to clean up. See `scan_markup`.
const MAX_UNCLOSED_TAGS: usize = 500;

/// Runs of character data allowed before parsing is refused, set from the corpus.
const MAX_TEXT_RUNS: usize = 15000;

/// Markup that leaked into a text node: node-html-parser keeps `<pre>` content unparsed, but a
/// reader sees it rendered. Each pattern stops at the next `<` so an opener without a closer is
/// charged only up to the next opener.
static CONDITIONAL_COMMENT: LazyLock<JsRegex> = LazyLock::new(|| JsRegex::fixed(r"<!\[[^\]<>]*\]>", ""));
static DOCTYPE: LazyLock<JsRegex> = LazyLock::new(|| JsRegex::fixed(r"<!doctype[^>]{0,200}>", "i"));
static LEAKED_MARKUP: LazyLock<JsRegex> = LazyLock::new(|| JsRegex::fixed(r"<[a-z][a-z0-9]*(?:\s[^<>]*)?>", "i"));

/// What an ancestor element matched: selector patterns by index, and the synthetic top border.
#[derive(Clone, Copy)]
enum Matched {
    Selector(usize),
    TopBorder,
}

struct Run {
    nodes: Vec<usize>,
    ancestors: Vec<usize>,
    dom_path: String,
}

fn class_matches(dom: &Dom, node: usize, wanted: &str) -> bool {
    dom.attribute(node, "class")
        .unwrap_or("")
        .split(is_js_ws)
        .filter(|name| !name.is_empty())
        .any(|name| {
            let lowered = name.to_lowercase();
            lowered == wanted || lowered.strip_prefix("x_") == Some(wanted)
        })
}

fn element_matches(dom: &Dom, node: usize, selector: &Selector) -> bool {
    if let Some(tag) = &selector.tag
        && dom.lower_tag(node) != Some(tag.as_str())
    {
        return false;
    }
    if let Some(class_name) = &selector.class_name
        && !class_matches(dom, node, class_name)
    {
        return false;
    }
    if let Some(id) = &selector.id {
        let value = dom.attribute(node, "id").unwrap_or("").to_lowercase();
        if value != *id && value.strip_prefix("x_") != Some(id.as_str()) {
            return false;
        }
    }
    if let Some((name, wanted)) = &selector.attr
        && dom.attribute(node, &name.to_lowercase()).unwrap_or("").to_lowercase() != *wanted
    {
        return false;
    }
    true
}

/// `/border-top\s*:\s*(?!none)[^;]+/i`, which accepts `border-top: none` (the whitespace run can
/// give back a character to the lookahead) and rejects only `border-top:none`.
fn has_top_border(dom: &Dom, node: usize) -> bool {
    let style = dom.attribute(node, "style").unwrap_or("");
    let lower = style.to_ascii_lowercase();
    let mut from = 0;
    while let Some(found) = lower[from..].find("border-top") {
        let mut at = from + found + "border-top".len();
        from = at;
        at += style[at..].len() - style[at..].trim_start_matches(is_js_ws).len();
        if !style[at..].starts_with(':') {
            continue;
        }
        let colon_end = at + 1;
        let value = &style[colon_end..];
        let spaces = value.len() - value.trim_start_matches(is_js_ws).len();
        if spaces > 0 {
            return true;
        }
        if !lower[colon_end..].starts_with("none") && value.chars().next().is_some_and(|c| c != ';') {
            return true;
        }
    }
    false
}

/// Leading lines of a block, trimmed, for line anchored detectors.
fn first_lines(text: &str) -> Vec<&str> {
    text.split('\n')
        .take(3)
        .map(js_trim)
        .filter(|line| !line.is_empty())
        .collect()
}

/// Text projection of an inline run, with `<br>` becoming a newline. Walked without recursion.
fn project_text(dom: &Dom, html: &str, nodes: &[usize]) -> String {
    let mut out = String::new();
    let mut stack: Vec<usize> = nodes.iter().rev().copied().collect();
    while let Some(node) = stack.pop() {
        match &dom.nodes[node].kind {
            NodeKind::Text => {
                let (start, end) = dom.nodes[node].range;
                let raw = &html[start.min(html.len())..end.min(html.len())];
                let cleaned = CONDITIONAL_COMMENT.re().replace_all(raw, "");
                let cleaned = DOCTYPE.re().replace_all(&cleaned, "");
                if LEAKED_MARKUP.is_match(&cleaned) {
                    out.push_str(&strip_tags_to_text(&cleaned));
                } else {
                    out.push_str(&decode_entities(&cleaned));
                }
            }
            NodeKind::Element { lower, .. } => {
                if INVISIBLE_TAGS.contains(&lower.as_str()) || lower == "img" {
                    continue;
                }
                if lower == "br" {
                    out.push('\n');
                    continue;
                }
                stack.extend(dom.nodes[node].children.iter().rev());
            }
            NodeKind::Root => {}
        }
    }
    let out = out.replace("\r\n", "\n").replace('\r', "\n");
    collapse_projection(&out, |c| c != '\n' && is_js_ws(c))
}

fn evidence_from_ancestry(ancestors: &[usize], matches: &HashMap<usize, Vec<Matched>>) -> Vec<Evidence> {
    let selectors = &patterns().html_selectors;
    let mut evidence: Vec<Evidence> = Vec::new();
    for ancestor in ancestors {
        for matched in matches.get(ancestor).into_iter().flatten() {
            let (id, role, strength) = match *matched {
                Matched::Selector(index) => {
                    let pattern = &selectors[index];
                    (pattern.id.as_str(), pattern.role, pattern.strength)
                }
                Matched::TopBorder => ("outlook_border_separator", SelectorRole::Separator, 0.6),
            };
            let kind = match role {
                SelectorRole::Quote => EvidenceKind::QuoteContainer,
                SelectorRole::Attribution => EvidenceKind::Attribution,
                SelectorRole::Separator => EvidenceKind::Separator,
                SelectorRole::Signature => EvidenceKind::Signature,
                SelectorRole::Disclaimer => EvidenceKind::Disclaimer,
                SelectorRole::New => EvidenceKind::NewContent,
                SelectorRole::Hint => EvidenceKind::Hint,
            };
            let id = format!("html:{id}");
            match evidence.iter_mut().find(|existing| existing.id == id) {
                Some(existing) if existing.strength < strength => *existing = Evidence::new(id, kind, strength),
                Some(_) => {}
                None => evidence.push(Evidence::new(id, kind, strength)),
            }
        }
    }
    evidence
}

fn kind_for(dom: &Dom, run: &Run, text: &str, evidence: &[Evidence]) -> BlockKind {
    if is_blank(text) {
        let has = |tag: &str| run.nodes.iter().any(|&node| dom.lower_tag(node) == Some(tag));
        if has("img") {
            return BlockKind::Image;
        }
        return if has("hr") {
            BlockKind::Separator
        } else {
            BlockKind::Blank
        };
    }
    // Before the header block test: a forward repeats the original headers after its marker.
    if first_lines(text)
        .iter()
        .any(|line| detect_forward_marker(line).is_some())
    {
        return BlockKind::ForwardHeader;
    }
    let lines: Vec<&str> = text.split('\n').map(js_trim).collect();
    if detect_quoted_header_block(&lines, 0).is_some() {
        return BlockKind::QuotedHeaderBlock;
    }
    if evidence.iter().any(|item| item.kind == EvidenceKind::Attribution) {
        return BlockKind::ReplyHeader;
    }
    if !text.contains('\n') && detect_attribution_line(text).is_some() {
        return BlockKind::ReplyHeader;
    }
    let ancestor_tags: Vec<&str> = run.ancestors.iter().filter_map(|&node| dom.lower_tag(node)).collect();
    if ancestor_tags.contains(&"blockquote") {
        return BlockKind::Quote;
    }
    if ancestor_tags.contains(&"li") {
        return BlockKind::List;
    }
    if ancestor_tags.contains(&"td") || ancestor_tags.contains(&"th") {
        return BlockKind::Table;
    }
    BlockKind::Paragraph
}

/// What node-html-parser leaves open at the end of the document, and how many text runs it
/// creates, from one linear pass. Both make its tree building superlinear when large.
pub(crate) fn scan_markup(html: &str) -> (usize, usize) {
    let bytes = html.as_bytes();
    let mut stack: Vec<String> = Vec::new();
    let mut text_runs = 0;
    let mut absent: Vec<String> = Vec::new();
    let find = |absent: &mut Vec<String>, needle: &str, from: usize| -> Option<usize> {
        if absent.iter().any(|a| a == needle) {
            return None;
        }
        let found = html.get(from..).and_then(|rest| rest.find(needle)).map(|at| from + at);
        if found.is_none() {
            absent.push(needle.to_string());
        }
        found
    };

    let opening = |top: &str, name: &str| {
        const TABLE: &[(&str, &[&str])] = &[
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
        both_cases(TABLE, top, name)
    };
    let closing_rule = |top: &str, name: &str| {
        const TABLE: &[(&str, &[&str])] = &[
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
        both_cases(TABLE, &top.to_uppercase(), name)
    };

    let mut i = 0;
    while i < html.len() {
        let Some(found) = html[i..].find('<') else {
            text_runs += 1;
            break;
        };
        let lt = i + found;
        if lt > i {
            text_runs += 1;
        }
        if html[lt..].starts_with("<!--") {
            i = find(&mut absent, "-->", lt + 4).map_or(lt + 4, |end| end + 3);
            continue;
        }
        if html[lt..].starts_with("<![CDATA[") {
            i = find(&mut absent, "]]>", lt + 9).map_or(lt + 9, |end| end + 3);
            continue;
        }
        let closing = bytes.get(lt + 1) == Some(&b'/');
        let name_start = lt + if closing { 2 } else { 1 };
        if !bytes.get(name_start).is_some_and(u8::is_ascii_alphabetic) {
            i = lt + 1;
            continue;
        }
        let name_end = html[name_start..]
            .find(|c: char| is_js_ws(c) || c == '>')
            .map_or(html.len(), |at| name_start + at);

        let mut gt = None;
        let mut p = name_end;
        while p < html.len() {
            match bytes[p] {
                b'>' => {
                    gt = Some(p);
                    break;
                }
                quote @ (b'"' | b'\'') => {
                    let needle = if quote == b'"' { "\"" } else { "'" };
                    if let Some(close) = find(&mut absent, needle, p + 1) {
                        p = close;
                    }
                }
                _ => {}
            }
            p += 1;
        }
        let Some(gt) = gt else {
            text_runs += 1;
            break;
        };
        i = gt + 1;

        let mut name = &html[name_start..name_end];
        let self_closing = bytes[gt - 1] == b'/';
        if self_closing && name_end == gt {
            name = &name[..name.len() - 1];
        }
        if closing {
            close_element(&mut stack, name, &closing_rule);
            continue;
        }
        while !self_closing && stack.last().is_some_and(|top| opening(top, name)) {
            stack.pop();
        }
        if ["script", "noscript", "style", "pre"]
            .iter()
            .any(|tag| tag.eq_ignore_ascii_case(name))
        {
            let close_markup = format!("</{name}>");
            match find(&mut absent, &close_markup, gt + 1) {
                None => {
                    stack.push(name.to_string());
                    break;
                }
                Some(end) => {
                    i = end + name.len() + 3;
                    continue;
                }
            }
        }
        let void = [
            "area", "base", "br", "col", "embed", "hr", "img", "input", "link", "meta", "param", "source", "track",
            "wbr",
        ]
        .iter()
        .any(|tag| *tag == name || tag.to_uppercase() == name);
        if self_closing || void {
            continue;
        }
        stack.push(name.to_string());
    }
    (stack.len(), text_runs)
}

fn both_cases(table: &[(&str, &[&str])], top: &str, name: &str) -> bool {
    table.iter().any(|(key, set)| {
        (*key == top || key.to_uppercase() == top) && set.iter().any(|n| *n == name || n.to_uppercase() == name)
    })
}

fn close_element(stack: &mut Vec<String>, name: &str, closing_rule: &impl Fn(&str, &str) -> bool) {
    while let Some(top) = stack.last() {
        if top == name {
            stack.pop();
            return;
        }
        if closing_rule(top, name) {
            stack.pop();
            continue;
        }
        let below = stack.len().checked_sub(2).map(|at| stack[at].to_lowercase());
        let lower = name.to_lowercase();
        if top.eq_ignore_ascii_case("p")
            && below.as_deref() == Some(lower.as_str())
            && !["a", "audio", "del", "ins", "map", "noscript", "video"].contains(&lower.as_str())
        {
            stack.pop();
            continue;
        }
        return;
    }
}

/// True when markup is shaped badly enough that building its tree is not worth the time.
pub(crate) fn is_pathological_html(html: &str) -> bool {
    let (unclosed, text_runs) = scan_markup(html);
    unclosed > MAX_UNCLOSED_TAGS || text_runs > MAX_TEXT_RUNS
}

pub(crate) struct HtmlSegmentation {
    pub blocks: Vec<Block>,
    /// Parsing was refused and the body is one unclassified block.
    pub degraded: bool,
}

fn walk(
    dom: &Dom,
    node: usize,
    ancestors: &mut Vec<usize>,
    path: &str,
    runs: &mut Vec<Run>,
    matches: &mut HashMap<usize, Vec<Matched>>,
) {
    let children = &dom.nodes[node].children;
    if ancestors.len() > MAX_DEPTH {
        if !children.is_empty() {
            runs.push(Run {
                nodes: children.clone(),
                ancestors: ancestors.clone(),
                dom_path: path.to_string(),
            });
        }
        return;
    }
    let mut pending: Vec<usize> = Vec::new();
    let mut pending_index = 0;
    let flush = |pending: &mut Vec<usize>, pending_index: usize, runs: &mut Vec<Run>, ancestors: &[usize]| {
        if !pending.is_empty() {
            runs.push(Run {
                nodes: std::mem::take(pending),
                ancestors: ancestors.to_vec(),
                dom_path: format!("{path}/{pending_index}"),
            });
        }
    };

    for (child_index, &child) in children.iter().enumerate() {
        if let Some(tag) = dom.lower_tag(child) {
            if INVISIBLE_TAGS.contains(&tag) {
                continue;
            }
            if BLOCK_TAGS.contains(&tag) {
                flush(&mut pending, pending_index, runs, ancestors);
                let mut found: Vec<Matched> = patterns()
                    .html_selectors
                    .iter()
                    .enumerate()
                    .filter(|(_, pattern)| element_matches(dom, child, &pattern.selector))
                    .map(|(index, _)| Matched::Selector(index))
                    .collect();
                if has_top_border(dom, child) {
                    found.push(Matched::TopBorder);
                }
                matches.insert(child, found);
                ancestors.push(child);
                walk(dom, child, ancestors, &format!("{path}/{child_index}"), runs, matches);
                ancestors.pop();
                continue;
            }
        }
        if pending.is_empty() {
            pending_index = child_index;
        }
        pending.push(child);
    }
    flush(&mut pending, pending_index, runs, ancestors);

    // An empty <hr> or <br> still marks structure, so it becomes a block of its own.
    if children.is_empty() && matches!(dom.lower_tag(node), Some("hr" | "br")) {
        runs.push(Run {
            nodes: vec![node],
            ancestors: ancestors.clone(),
            dom_path: path.to_string(),
        });
    }
}

fn degraded(html: &str, mime_part: &str) -> HtmlSegmentation {
    // The projection keeps the content; the range keeps the tiling.
    let projected = strip_tags_to_text(html);
    let features = compute_features(
        &projected,
        &FeatureContext {
            start16: 0,
            total16: js_len(html),
            quote_depth: 0,
            blockquote_depth: 0,
        },
    );
    HtmlSegmentation {
        degraded: true,
        blocks: vec![Block {
            index: 0,
            source_index: 0,
            kind: BlockKind::Unknown,
            representation: Representation::Html,
            mime_part: mime_part.to_string(),
            start: 0,
            end: html.len(),
            html_start: Some(0),
            html_end: html.len(),
            content: projected,
            dom_path: None,
            features,
            evidence: Vec::new(),
        }],
    }
}

/// Segment an HTML part into blocks.
pub(crate) fn segment_html_blocks(html: &str, mime_part: &str) -> HtmlSegmentation {
    if is_pathological_html(html) {
        return degraded(html, mime_part);
    }
    let dom = parse(html);
    let mut runs = Vec::new();
    let mut matches = HashMap::new();
    walk(&dom, ROOT, &mut Vec::new(), "", &mut runs, &mut matches);

    let len = html.len();
    let mut blocks: Vec<Block> = Vec::new();
    let mut previous_end = 0;
    for run in &runs {
        let mut node_start = usize::MAX;
        let mut node_end = 0;
        for &node in &run.nodes {
            let (start, end) = dom.nodes[node].range;
            node_start = node_start.min(start);
            node_end = node_end.max(end);
        }
        if node_start == usize::MAX || node_end <= previous_end {
            continue;
        }
        let start = previous_end.min(node_start);
        let text = project_text(&dom, html, &run.nodes);
        let blockquote_depth = run
            .ancestors
            .iter()
            .filter(|&&node| dom.lower_tag(node) == Some("blockquote"))
            .count();
        let mut evidence = evidence_from_ancestry(&run.ancestors, &matches);
        let kind = kind_for(&dom, run, &text, &evidence);
        if kind == BlockKind::ReplyHeader
            && !evidence
                .iter()
                .any(|item| matches!(item.kind, EvidenceKind::ReplyAnchor | EvidenceKind::Attribution))
            && let Some(attribution) = detect_attribution_line(&text)
        {
            evidence.push(attribution);
        }
        let mut authored_lines_before_anchor = 0;
        if kind == BlockKind::QuotedHeaderBlock {
            let lines: Vec<&str> = text.split('\n').map(js_trim).collect();
            if let Some(found) = detect_quoted_header_block(&lines, 0) {
                evidence.push(found.evidence);
                // Outlook-era HTML glues the sign-off, the separator and the old headers into one
                // run divided only by <br>, so the block also holds what the sender typed.
                authored_lines_before_anchor = lines[..found.start_line]
                    .iter()
                    .filter(|line| {
                        !line.is_empty()
                            && detect_attribution_line(line).is_none()
                            && detect_rule_separator(line).is_none()
                    })
                    .count();
            }
        }
        if kind == BlockKind::ForwardHeader
            && let Some(forward) = first_lines(&text).iter().find_map(|line| detect_forward_marker(line))
        {
            evidence.push(forward);
        }
        let mut features = compute_features(
            &text,
            &FeatureContext {
                start16: 0,
                total16: 0,
                quote_depth: blockquote_depth,
                blockquote_depth,
            },
        );
        features.authored_lines_before_anchor = authored_lines_before_anchor;
        // node-html-parser can report an end past the source; slices are clamped.
        let end = node_end.min(len);
        blocks.push(Block {
            index: blocks.len(),
            source_index: blocks.len(),
            kind,
            representation: Representation::Html,
            mime_part: mime_part.to_string(),
            start: start.min(end),
            end,
            html_start: Some(node_start.min(end)),
            html_end: end,
            content: text,
            dom_path: Some(run.dom_path.clone()),
            features,
            evidence,
        });
        previous_end = node_end;
    }

    // Trailing markup belongs to the last block, so the blocks tile the whole document.
    if let Some(last) = blocks.last_mut() {
        if last.end < len {
            last.end = len;
        }
    } else if !html.is_empty() {
        blocks.push(Block {
            index: 0,
            source_index: 0,
            kind: BlockKind::Blank,
            representation: Representation::Html,
            mime_part: mime_part.to_string(),
            start: 0,
            end: len,
            html_start: Some(0),
            html_end: len,
            content: String::new(),
            dom_path: None,
            features: compute_features(
                "",
                &FeatureContext {
                    start16: 0,
                    total16: js_len(html),
                    quote_depth: 0,
                    blockquote_depth: 0,
                },
            ),
            evidence: Vec::new(),
        });
    }

    // Position from the projected text, the document the reader reads, not from markup offsets.
    let total: usize = blocks.iter().map(|block| js_len(&block.content)).sum();
    let mut before = 0;
    for block in &mut blocks {
        block.features.position = if total > 0 { before as f64 / total as f64 } else { 0.0 };
        before += js_len(&block.content);
    }

    find_split_header_blocks(&mut blocks);

    for block in &mut blocks {
        if block.kind == BlockKind::Blank || block.features.is_all_blank {
            continue;
        }
        let non_blank: Vec<&str> = block
            .content
            .split('\n')
            .filter(|line| !js_trim(line).is_empty())
            .collect();
        // An attribution leading a larger block: evidence only, the kind stays, and only the first
        // line is tested so nothing the sender wrote can sit above the anchor in the same block.
        if non_blank.len() > 1
            && matches!(block.kind, BlockKind::Paragraph | BlockKind::Table | BlockKind::List)
            && !block
                .evidence
                .iter()
                .any(|item| matches!(item.kind, EvidenceKind::ReplyAnchor | EvidenceKind::Attribution))
            && let Some(attribution) = detect_attribution_line(non_blank[0])
        {
            block.evidence.push(attribution);
        }
        // A rule drawn as text in a paragraph of its own.
        if block.kind == BlockKind::Paragraph
            && non_blank.len() == 1
            && let Some(separator) = detect_rule_separator(js_trim(non_blank[0]))
        {
            block.kind = BlockKind::Separator;
            block.evidence.push(separator);
        }
    }

    // A bare <hr> is the same boundary drawn with markup, at the same weak strength.
    for block in &mut blocks {
        if block.kind == BlockKind::Separator && !block.evidence.iter().any(|item| item.kind == EvidenceKind::Separator)
        {
            block
                .evidence
                .push(Evidence::new("html:hr_separator", EvidenceKind::Separator, 0.6));
        }
    }

    // Footer evidence, once positions are known.
    for block in &mut blocks {
        if block.kind == BlockKind::Blank || block.features.is_all_blank {
            continue;
        }
        let lines: Vec<&str> = block.content.split('\n').collect();
        let mut found: Vec<Evidence> = lines
            .iter()
            .find_map(|line| detect_signature_delimiter(js_trim(line)))
            .into_iter()
            .collect();
        found.extend(detect_signature_phrases(&lines));
        found.extend(detect_inline_announcement(&lines));
        found.extend(detect_signature_shape(&block.features));
        found.extend(detect_disclaimer(&block.content, &block.features));
        block.evidence.extend(found);
    }

    HtmlSegmentation {
        blocks,
        degraded: false,
    }
}

/// An embedded header block split across sibling elements, as Outlook desktop writes each field
/// in its own paragraph: scanned over the blocks' projected lines, with a blank line at each block
/// boundary.
fn find_split_header_blocks(blocks: &mut [Block]) {
    let rekindable = |kind: BlockKind| matches!(kind, BlockKind::Paragraph | BlockKind::Table | BlockKind::List);
    let mut line_texts: Vec<&str> = Vec::new();
    let mut line_owners: Vec<usize> = Vec::new();
    for block in blocks.iter() {
        // Whitespace-only blocks add no line, so the gap rule sees only the breaks a reader sees.
        if block.features.is_all_blank {
            continue;
        }
        for line in block.content.split('\n') {
            line_texts.push(js_trim(line));
            line_owners.push(block.index);
        }
        line_texts.push("");
        line_owners.push(block.index);
    }
    let mut bounds: HashMap<usize, (usize, usize)> = HashMap::new();
    for (i, line) in line_texts.iter().enumerate() {
        if line.is_empty() {
            continue;
        }
        bounds.entry(line_owners[i]).and_modify(|b| b.1 = i).or_insert((i, i));
    }
    let mut owned: Vec<(usize, Evidence, usize, usize)> = Vec::new();
    let mut scan_from = 0;
    while scan_from < line_texts.len() {
        let Some(found) = detect_quoted_header_block(&line_texts, scan_from) else {
            break;
        };
        // Owners in first appearance order.
        let mut covered: Vec<usize> = Vec::new();
        for &owner in &line_owners[found.start_line..=found.end_line] {
            if !covered.contains(&owner) {
                covered.push(owner);
            }
        }
        for owner in covered {
            owned.push((owner, found.evidence.clone(), found.start_line, found.end_line));
        }
        owned.push((usize::MAX, found.evidence.clone(), 0, 0));
        scan_from = found.end_line + 1;
    }
    let mut attached = false;
    for (owner, evidence, start, end) in owned {
        if owner == usize::MAX {
            attached = false;
            continue;
        }
        let fully = bounds
            .get(&owner)
            .is_some_and(|&(first, last)| first >= start && last <= end);
        let block = &mut blocks[owner];
        if !fully || !rekindable(block.kind) {
            continue;
        }
        block.kind = BlockKind::QuotedHeaderBlock;
        if !attached && !block.evidence.iter().any(|item| item.kind == EvidenceKind::ReplyAnchor) {
            block.evidence.push(evidence);
            attached = true;
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    fn joined(html: &str, blocks: &[Block]) -> String {
        blocks.iter().map(|b| &html[b.start..b.end]).collect()
    }

    #[test]
    fn tiles_the_source() {
        for html in [
            "<div>Hi</div><div class=\"gmail_quote\"><div class=\"gmail_attr\">On Mon, Bob wrote:</div><blockquote>old</blockquote></div>",
            "<p>a<p>b",
            "<a href=\"x",
            "text only",
            "<html><head><style>p{}</style></head><body><p>x</p></body></html>  ",
        ] {
            let result = segment_html_blocks(html, "1");
            assert_eq!(joined(html, &result.blocks), html, "{html}");
        }
    }

    #[test]
    fn records_blockquote_ancestry() {
        let result = segment_html_blocks("<p>new</p><blockquote><p>old</p></blockquote>", "1");
        assert_eq!(result.blocks[1].kind, BlockKind::Quote);
        assert_eq!(result.blocks[1].features.blockquote_depth, 1);
    }

    #[test]
    fn reads_top_borders_like_the_lookahead() {
        let dom = parse(
            "<div style=\"border-top: none\"></div><div style=\"border-top:none\"></div><div style=\"BORDER-TOP:solid\"></div>",
        );
        let divs = &dom.nodes[ROOT].children;
        assert!(has_top_border(&dom, divs[0]));
        assert!(!has_top_border(&dom, divs[1]));
        assert!(has_top_border(&dom, divs[2]));
    }

    #[test]
    fn counts_open_elements_like_the_parser() {
        for (unit, open) in [
            ("<b>x", 20),
            ("<p>para", 1),
            ("<b>x</b>", 0),
            ("<div><b>x</div>", 0),
            ("<tr>", 1),
            ("<br/>", 0),
        ] {
            assert_eq!(scan_markup(&unit.repeat(20)).0, open, "{unit}");
        }
        assert!(is_pathological_html(&format!("<div>{}</div>", "a<br>".repeat(20000))));
        assert!(!is_pathological_html(&format!("<div>{}</div>", "a<br>".repeat(5000))));
    }
}
