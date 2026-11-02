//! The detector pattern sets, compiled once from the JSON files embedded at build time.
//!
//! Patterns are data, kept in the same `patterns/*.json` files email-content ships, so the two
//! stay comparable file for file. A pattern that does not compile is skipped and its id recorded
//! in `invalid`; a test asserts that none of the bundled ones is.

use std::sync::LazyLock;

use serde_json::Value;

use crate::jsre::JsRegex;

pub(crate) struct LinePattern {
    pub id: String,
    pub role: Option<String>,
    pub strength: f64,
    pub regex: JsRegex,
}

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub(crate) enum SelectorRole {
    Quote,
    Attribution,
    Separator,
    Signature,
    Disclaimer,
    New,
    Hint,
}

/// The simple selector forms html-clients.json uses: `tag`, `.class`, `#id`, `[attr=value]`, each
/// with an optional tag in front.
#[derive(Debug, Clone)]
pub(crate) struct Selector {
    pub tag: Option<String>,
    pub class_name: Option<String>,
    pub id: Option<String>,
    pub attr: Option<(String, String)>,
}

#[derive(Debug, Clone)]
pub(crate) struct SelectorPattern {
    pub id: String,
    pub role: SelectorRole,
    pub strength: f64,
    pub selector: Selector,
}

pub(crate) struct PatternSets {
    pub reply_headers: Vec<LinePattern>,
    pub forward_headers: Vec<LinePattern>,
    pub quoted_header_fields: Vec<LinePattern>,
    pub inline_announcements: Vec<LinePattern>,
    pub signature_delimiters: Vec<LinePattern>,
    pub signature_phrases: Vec<LinePattern>,
    pub disclaimer_phrases: Vec<LinePattern>,
    pub html_selectors: Vec<SelectorPattern>,
    /// Ids of patterns that failed to compile. Checked by a test.
    #[cfg_attr(not(test), allow(dead_code))]
    pub invalid: Vec<String>,
}

const REPLY_HEADERS: &str = include_str!("../patterns/reply-headers.json");
const FORWARD_HEADERS: &str = include_str!("../patterns/forward-headers.json");
const QUOTED_HEADERS: &str = include_str!("../patterns/quoted-headers.json");
const SIGNATURES: &str = include_str!("../patterns/signatures.json");
const DISCLAIMERS: &str = include_str!("../patterns/disclaimers.json");
const HTML_CLIENTS: &str = include_str!("../patterns/html-clients.json");

pub(crate) static PATTERNS: LazyLock<PatternSets> = LazyLock::new(load);

pub(crate) fn patterns() -> &'static PatternSets {
    &PATTERNS
}

fn compile_lines(input: Option<&Value>, invalid: &mut Vec<String>) -> Vec<LinePattern> {
    let Some(items) = input.and_then(Value::as_array) else {
        return Vec::new();
    };
    let mut out = Vec::new();
    for item in items {
        let id = item.get("id").and_then(Value::as_str);
        let source = item.get("pattern").and_then(Value::as_str);
        let (Some(id), Some(source)) = (id, source) else {
            invalid.push(id.unwrap_or("unnamed").to_string());
            continue;
        };
        let strength = item.get("strength").and_then(Value::as_f64).unwrap_or(0.5);
        let flags = item.get("flags").and_then(Value::as_str).unwrap_or("");
        // A strength outside [0, 1] would outrank every anchor, and g or y make a JavaScript regex
        // stateful; both count as a pattern that does not compile, as in email-content.
        if !(0.0..=1.0).contains(&strength) || flags.contains(['g', 'y']) {
            invalid.push(id.to_string());
            continue;
        }
        match JsRegex::new(source, flags) {
            Ok(regex) => out.push(LinePattern {
                id: id.to_string(),
                role: item.get("role").and_then(Value::as_str).map(str::to_string),
                strength,
                regex,
            }),
            Err(_) => invalid.push(id.to_string()),
        }
    }
    out
}

/// Parse a selector of the forms html-clients.json uses.
pub(crate) fn parse_selector(selector: &str) -> Selector {
    let tag_of = |tag: &str| (!tag.is_empty()).then(|| tag.to_string());
    let is_tag = |tag: &str| tag.bytes().all(|b| b.is_ascii_alphanumeric() || b == b'-');
    let is_ident = |name: &str| {
        !name.is_empty()
            && name
                .bytes()
                .all(|b| b.is_ascii_alphanumeric() || b == b'_' || b == b'-')
    };

    // ^([a-z0-9-]*)\[([a-z-]+)=["']?([^\]"']+)["']?\]$
    if let Some(open) = selector.find('[')
        && selector.ends_with(']')
        && is_tag(&selector[..open])
    {
        let inner = &selector[open + 1..selector.len() - 1];
        if let Some(eq) = inner.find('=') {
            let name = &inner[..eq];
            let value = inner[eq + 1..].trim_matches(['"', '\'']);
            if !name.is_empty()
                && name.bytes().all(|b| b.is_ascii_alphabetic() || b == b'-')
                && !value.is_empty()
                && !value.contains([']', '"', '\''])
            {
                return Selector {
                    tag: tag_of(&selector[..open]),
                    class_name: None,
                    id: None,
                    attr: Some((name.to_string(), value.to_lowercase())),
                };
            }
        }
    }
    if let Some(hash) = selector.find('#')
        && is_tag(&selector[..hash])
        && is_ident(&selector[hash + 1..])
    {
        return Selector {
            tag: tag_of(&selector[..hash]),
            class_name: None,
            id: Some(selector[hash + 1..].to_lowercase()),
            attr: None,
        };
    }
    if let Some(dot) = selector.find('.')
        && is_tag(&selector[..dot])
        && is_ident(&selector[dot + 1..])
    {
        return Selector {
            tag: tag_of(&selector[..dot]),
            class_name: Some(selector[dot + 1..].to_lowercase()),
            id: None,
            attr: None,
        };
    }
    Selector {
        tag: tag_of(&selector.to_lowercase()),
        class_name: None,
        id: None,
        attr: None,
    }
}

fn compile_selectors(input: Option<&Value>, invalid: &mut Vec<String>) -> Vec<SelectorPattern> {
    let Some(items) = input.and_then(Value::as_array) else {
        return Vec::new();
    };
    let mut out = Vec::new();
    for item in items {
        let id = item.get("id").and_then(Value::as_str);
        let selector = item.get("selector").and_then(Value::as_str);
        let (Some(id), Some(selector)) = (id, selector) else {
            invalid.push(id.unwrap_or("unnamed").to_string());
            continue;
        };
        let role = match item.get("role").and_then(Value::as_str).unwrap_or("hint") {
            "quote" => SelectorRole::Quote,
            "attribution" => SelectorRole::Attribution,
            "separator" => SelectorRole::Separator,
            "signature" => SelectorRole::Signature,
            "disclaimer" => SelectorRole::Disclaimer,
            "new" => SelectorRole::New,
            _ => SelectorRole::Hint,
        };
        out.push(SelectorPattern {
            id: id.to_string(),
            role,
            strength: item.get("strength").and_then(Value::as_f64).unwrap_or(0.5),
            selector: parse_selector(selector),
        });
    }
    out
}

fn json(source: &str) -> Value {
    serde_json::from_str(source).expect("bundled pattern file is valid JSON")
}

fn load() -> PatternSets {
    let mut invalid = Vec::new();
    let reply = json(REPLY_HEADERS);
    let forward = json(FORWARD_HEADERS);
    let quoted = json(QUOTED_HEADERS);
    let signatures = json(SIGNATURES);
    let disclaimers = json(DISCLAIMERS);
    let clients = json(HTML_CLIENTS);
    PatternSets {
        reply_headers: compile_lines(reply.get("patterns"), &mut invalid),
        forward_headers: compile_lines(forward.get("patterns"), &mut invalid),
        quoted_header_fields: compile_lines(quoted.get("fields"), &mut invalid),
        inline_announcements: compile_lines(reply.get("inlineAnnouncements"), &mut invalid),
        signature_delimiters: compile_lines(signatures.get("delimiters"), &mut invalid),
        signature_phrases: compile_lines(signatures.get("phrases"), &mut invalid),
        disclaimer_phrases: compile_lines(disclaimers.get("phrases"), &mut invalid),
        html_selectors: compile_selectors(clients.get("selectors"), &mut invalid),
        invalid,
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn compiles_every_bundled_pattern() {
        let sets = patterns();
        assert!(
            sets.invalid.is_empty(),
            "patterns that do not compile: {:?}",
            sets.invalid
        );
        assert_eq!(sets.reply_headers.len(), 64);
        assert_eq!(sets.inline_announcements.len(), 5);
        assert_eq!(sets.forward_headers.len(), 8);
        assert_eq!(sets.quoted_header_fields.len(), 7);
        assert_eq!(sets.signature_delimiters.len(), 2);
        assert_eq!(sets.signature_phrases.len(), 7);
        assert_eq!(sets.disclaimer_phrases.len(), 23);
        assert_eq!(sets.html_selectors.len(), 24);
    }

    #[test]
    fn parses_selectors() {
        let attr = parse_selector("blockquote[type=cite]");
        assert_eq!(attr.tag.as_deref(), Some("blockquote"));
        assert_eq!(attr.attr, Some(("type".into(), "cite".into())));
        let id = parse_selector("div#divRplyFwdMsg");
        assert_eq!(id.id.as_deref(), Some("divrplyfwdmsg"));
        let class = parse_selector(".gmail_quote");
        assert_eq!(class.tag, None);
        assert_eq!(class.class_name.as_deref(), Some("gmail_quote"));
        assert_eq!(parse_selector("blockquote").tag.as_deref(), Some("blockquote"));
    }
}
