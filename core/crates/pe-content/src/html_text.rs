//! A cheap text projection of HTML, and entity decoding.
//!
//! The projection is used where segmentation degraded and for history documents. It is not a
//! sanitiser and not the DOM walk the segmenter does. Every byte is visited a constant number of
//! times: a construct that never closes is emitted as text and skipped, never rescanned.

use std::sync::LazyLock;

use crate::jsre::JsRegex;
use crate::util::advance_units;

/// Entities common in mail. Numeric references are handled separately.
const NAMED_ENTITIES: &[(&str, &str)] = &[
    ("amp", "&"),
    ("lt", "<"),
    ("gt", ">"),
    ("quot", "\""),
    ("apos", "'"),
    ("nbsp", "\u{a0}"),
    ("ndash", "\u{2013}"),
    ("mdash", "\u{2014}"),
    ("lsquo", "\u{2018}"),
    ("rsquo", "\u{2019}"),
    ("ldquo", "\u{201c}"),
    ("rdquo", "\u{201d}"),
    ("hellip", "\u{2026}"),
    ("bull", "\u{2022}"),
    ("middot", "\u{b7}"),
    ("laquo", "\u{ab}"),
    ("raquo", "\u{bb}"),
    ("copy", "\u{a9}"),
    ("reg", "\u{ae}"),
    ("trade", "\u{2122}"),
    ("euro", "\u{20ac}"),
    ("pound", "\u{a3}"),
    ("deg", "\u{b0}"),
    ("szlig", "\u{df}"),
    ("auml", "\u{e4}"),
    ("ouml", "\u{f6}"),
    ("uuml", "\u{fc}"),
    ("Auml", "\u{c4}"),
    ("Ouml", "\u{d6}"),
    ("Uuml", "\u{dc}"),
    ("aring", "\u{e5}"),
    ("Aring", "\u{c5}"),
    ("aelig", "\u{e6}"),
    ("oslash", "\u{f8}"),
    ("eacute", "\u{e9}"),
    ("egrave", "\u{e8}"),
    ("agrave", "\u{e0}"),
    ("ccedil", "\u{e7}"),
    ("ntilde", "\u{f1}"),
    ("shy", "\u{ad}"),
    ("zwnj", "\u{200c}"),
    ("zwj", "\u{200d}"),
];

static ENTITY: LazyLock<JsRegex> =
    LazyLock::new(|| JsRegex::fixed(r"&(#[xX]?[0-9a-fA-F]{1,12}|[a-zA-Z][a-zA-Z0-9]{1,31});", ""));

/// `parseInt(digits, radix)`: the leading run of valid digits, `None` when there is none.
fn parse_int(digits: &str, radix: u32) -> Option<u64> {
    let valid: String = digits.chars().take_while(|c| c.is_digit(radix)).collect();
    if valid.is_empty() {
        return None;
    }
    // Twelve digits at most, so this fits.
    u64::from_str_radix(&valid, radix).ok()
}

/// Decode HTML entities. Unknown entities are left as written.
pub(crate) fn decode_entities(input: &str) -> String {
    if !input.contains('&') {
        return input.to_string();
    }
    ENTITY
        .re()
        .replace_all(input, |caps: &regex::Captures| {
            let whole = &caps[0];
            let body = &caps[1];
            if let Some(number) = body.strip_prefix('#') {
                let (digits, radix) = match number.strip_prefix(['x', 'X']) {
                    Some(hex) => (hex, 16),
                    None => (number, 10),
                };
                return match parse_int(digits, radix) {
                    // A lone surrogate cannot be held in a Rust string; it reads as U+FFFD.
                    Some(code) if code <= 0x10ffff => char::from_u32(code as u32).unwrap_or('\u{FFFD}').to_string(),
                    _ => whole.to_string(),
                };
            }
            NAMED_ENTITIES
                .iter()
                .find(|(name, _)| *name == body)
                .map_or_else(|| whole.to_string(), |(_, value)| (*value).to_string())
        })
        .into_owned()
}

/// Elements whose content is code rather than prose.
const RAW_TEXT_TAGS: &[&str] = &["script", "style"];

/// Elements whose content is not rendered, but is still prose if the close tag is lost.
const HIDDEN_TAGS: &[&str] = &["head", "title", "noscript", "template"];

/// Elements that introduce a line break in the projection.
const BLOCK_BREAK_TAGS: &[&str] = &[
    "p",
    "div",
    "br",
    "tr",
    "li",
    "h1",
    "h2",
    "h3",
    "h4",
    "h5",
    "h6",
    "table",
    "blockquote",
    "pre",
    "hr",
    "section",
    "article",
    "ul",
    "ol",
    "dd",
    "dt",
];

/// Longest markup construct, in UTF-16 code units, scanned before its `<` is given up on.
const MAX_TAG_LENGTH: usize = 8192;

fn is_name_start(b: u8) -> bool {
    b.is_ascii_alphabetic()
}

fn is_name_char(b: u8) -> bool {
    b.is_ascii_alphanumeric() || matches!(b, b'-' | b':' | b'_')
}

/// End of a tag that opens at `from`, or `None` when no unquoted `>` appears within the cap.
fn tag_end(html: &str, from: usize) -> Option<usize> {
    let limit = advance_units(html, from, MAX_TAG_LENGTH);
    let bytes = html.as_bytes();
    let mut quote = 0u8;
    for (i, &b) in bytes.iter().enumerate().take(limit).skip(from) {
        if quote != 0 {
            if b == quote {
                quote = 0;
            }
            continue;
        }
        match b {
            b'"' | b'\'' => quote = b,
            b'>' => return Some(i),
            _ => {}
        }
    }
    None
}

/// `</name(?:\s[^>]*)?>`, case insensitive, at or after `from`. Returns the end of the match.
fn find_close_tag(html: &str, name: &str, from: usize) -> Option<usize> {
    let bytes = html.as_bytes();
    let mut at = from;
    while let Some(found) = html.get(at..).and_then(|rest| rest.find("</")) {
        let start = at + found;
        let name_end = start + 2 + name.len();
        if bytes.len() >= name_end && bytes[start + 2..name_end].eq_ignore_ascii_case(name.as_bytes()) {
            match html[name_end..].chars().next() {
                Some('>') => return Some(name_end + 1),
                Some(c) if crate::jsre::is_js_ws(c) => {
                    // `[^>]*>`: when no `>` follows, no later candidate can match either.
                    let gt = html[name_end..].find('>')?;
                    return Some(name_end + gt + 1);
                }
                _ => {}
            }
        }
        at = start + 2;
    }
    None
}

/// Cheap text projection of an HTML body. Not a sanitiser.
pub(crate) fn strip_tags_to_text(html: &str) -> String {
    let bytes = html.as_bytes();
    let length = html.len();
    let mut out = String::with_capacity(length);
    let mut i = 0;
    // Searches that found nothing once find nothing later either, since the cursor only advances.
    let mut no_comment_close = false;
    let mut no_raw_close: Vec<String> = Vec::new();

    let unterminated = |out: &mut String, lt: usize| -> usize {
        let end = advance_units(html, lt, MAX_TAG_LENGTH);
        out.push_str(&html[lt..end]);
        end
    };

    while i < length {
        let Some(found) = html[i..].find('<') else {
            out.push_str(&html[i..]);
            break;
        };
        let lt = i + found;
        if lt > i {
            out.push_str(&html[i..lt]);
        }
        let next = bytes.get(lt + 1).copied().unwrap_or(0);

        if next == b'!' {
            if html[lt..].starts_with("<!--") {
                let close = if no_comment_close {
                    None
                } else {
                    html[lt + 4..].find("-->").map(|at| lt + 4 + at)
                };
                match close {
                    None => {
                        no_comment_close = true;
                        out.push(' ');
                        i = lt + 4;
                    }
                    Some(close) => {
                        out.push(' ');
                        i = close + 3;
                    }
                }
                continue;
            }
            match tag_end(html, lt + 2) {
                None => i = unterminated(&mut out, lt),
                Some(close) => {
                    out.push(' ');
                    i = close + 1;
                }
            }
            continue;
        }

        if next == b'?' {
            match tag_end(html, lt + 2) {
                None => i = unterminated(&mut out, lt),
                Some(close) => {
                    out.push(' ');
                    i = close + 1;
                }
            }
            continue;
        }

        let closing = next == b'/';
        let name_start = if closing { lt + 2 } else { lt + 1 };
        if !bytes.get(name_start).is_some_and(|&b| is_name_start(b)) {
            out.push('<');
            i = lt + 1;
            continue;
        }
        let mut name_end = name_start;
        while name_end < length && is_name_char(bytes[name_end]) {
            name_end += 1;
        }
        let name = html[name_start..name_end].to_ascii_lowercase();

        let Some(close) = tag_end(html, name_end) else {
            i = unterminated(&mut out, lt);
            continue;
        };

        let raw = RAW_TEXT_TAGS.contains(&name.as_str());
        if !closing && (raw || HIDDEN_TAGS.contains(&name.as_str())) {
            let mut matched = None;
            if !no_raw_close.contains(&name) {
                matched = find_close_tag(html, &name, close + 1);
                if matched.is_none() {
                    no_raw_close.push(name.clone());
                }
            }
            if let Some(end) = matched {
                out.push(' ');
                i = end;
                continue;
            }
            if raw {
                out.push(' ');
                break;
            }
            out.push(' ');
            i = close + 1;
            continue;
        }

        if BLOCK_BREAK_TAGS.contains(&name.as_str()) {
            out.push('\n');
        }
        i = close + 1;
    }

    let text = decode_entities(&out);
    let text = text.replace("\r\n", "\n").replace('\r', "\n");
    collapse_projection(&text, |c| matches!(c, ' ' | '\t' | '\u{a0}'))
}

/// `[ws]+` to one space, ` *\n *` to a newline, `\n{3,}` to two, then trim.
pub(crate) fn collapse_projection(text: &str, is_space: impl Fn(char) -> bool) -> String {
    // Spaces collapse first, then spaces around newlines go, then newline runs are capped.
    let mut collapsed = String::with_capacity(text.len());
    let mut in_space = false;
    for c in text.chars() {
        if is_space(c) {
            if !in_space {
                collapsed.push(' ');
                in_space = true;
            }
        } else {
            collapsed.push(c);
            in_space = false;
        }
    }
    let mut around = String::with_capacity(collapsed.len());
    let mut pending_spaces = 0usize;
    let mut after_newline = false;
    for c in collapsed.chars() {
        match c {
            ' ' => pending_spaces += 1,
            '\n' => {
                pending_spaces = 0;
                around.push('\n');
                after_newline = true;
            }
            c => {
                if !after_newline {
                    around.extend(std::iter::repeat_n(' ', pending_spaces));
                }
                pending_spaces = 0;
                after_newline = false;
                around.push(c);
            }
        }
    }
    if !after_newline {
        around.extend(std::iter::repeat_n(' ', pending_spaces));
    }
    let mut capped = String::with_capacity(around.len());
    let mut newlines = 0;
    for c in around.chars() {
        if c == '\n' {
            newlines += 1;
            if newlines <= 2 {
                capped.push('\n');
            }
        } else {
            newlines = 0;
            capped.push(c);
        }
    }
    crate::util::js_trim(&capped).to_string()
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn projects_ordinary_markup() {
        assert_eq!(strip_tags_to_text("<p>one</p><p>two</p>"), "one\n\ntwo");
        assert_eq!(strip_tags_to_text("one<br>two"), "one\ntwo");
        assert_eq!(strip_tags_to_text("a &amp; b &#65; c"), "a & b A c");
        assert_eq!(strip_tags_to_text("<!--hidden--><p>shown</p>"), "shown");
        assert_eq!(strip_tags_to_text("<![if !supportLists]><p>item</p>"), "item");
        assert_eq!(strip_tags_to_text("<p>a &lt; b and 3 &gt; 2</p>"), "a < b and 3 > 2");
        assert_eq!(strip_tags_to_text("<p>a < b</p>"), "a < b");
        assert_eq!(strip_tags_to_text("<a title=\"a>b\">link</a>"), "link");
        assert_eq!(strip_tags_to_text("<p>text</p><div class=\"x"), "text\n<div class=\"x");
    }

    #[test]
    fn keeps_script_and_style_out() {
        let projected = strip_tags_to_text("<style>.a{color:red}</style><p>Visible</p><script>alert(\"x\")</script>");
        assert!(!projected.contains("color:red"));
        assert!(!projected.contains("alert"));
        assert!(projected.contains("Visible"));
        assert!(!strip_tags_to_text("<p>Visible</p><script>alert(\"x\")").contains("alert"));
    }

    #[test]
    fn decodes_entities_like_parse_int() {
        assert_eq!(
            decode_entities("&#5e; &#e5; &#xe5; &bogus; &amp"),
            "\u{5} &#e5; \u{e5} &bogus; &amp"
        );
    }
}
