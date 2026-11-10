//! Renders HTML into plain text while remembering how each piece of text was styled, because the
//! way a code is presented (big, bold, letter spaced, alone in its own cell) is the strongest signal
//! that a number is the one-time code and not an order number. A port of otp-detect's src/html.ts.
//!
//! This is not a browser and deliberately not an HTML5 parser: the model was trained on exactly
//! what this renderer makes of a message. It walks the tags in a single linear pass, applies the
//! handful of inline styles and elements that change how text looks, and treats everything else as
//! a container.

use std::collections::HashMap;
use std::rc::Rc;
use std::sync::LazyLock;

use pe_jsre::{is_space, trim};
use regex::{Captures, Regex};

use crate::doc::{DEFAULT_FONT_SIZE, DEFAULT_STYLE, Doc, DocBuilder, Source, Style};
use crate::js::{parse_float, parse_int};

const SKIP_CONTENT: &[&str] = &[
    "head", "script", "style", "title", "noscript", "template", "svg", "math", "xml",
];
const VOID: &[&str] = &[
    "br", "img", "hr", "meta", "link", "input", "wbr", "col", "area", "base", "source", "track", "embed", "param",
];
const BLOCK: &[&str] = &[
    "p",
    "div",
    "td",
    "th",
    "tr",
    "li",
    "ul",
    "ol",
    "table",
    "tbody",
    "thead",
    "tfoot",
    "h1",
    "h2",
    "h3",
    "h4",
    "h5",
    "h6",
    "section",
    "article",
    "header",
    "footer",
    "main",
    "nav",
    "aside",
    "blockquote",
    "center",
    "pre",
    "dd",
    "dt",
    "dl",
    "address",
    "form",
    "fieldset",
    "figure",
    "figcaption",
    "hr",
    "caption",
];
const MONO_TAGS: &[&str] = &["code", "pre", "tt", "kbd", "samp"];
// <font size="1"> to <font size="7"> in pixels, as browsers map them
const FONT_TAG_SIZE: [f64; 8] = [0.0, 10.0, 13.0, 16.0, 18.0, 24.0, 32.0, 48.0];

fn heading_size(tag: &str) -> Option<f64> {
    Some(match tag {
        "h1" => 32.0,
        "h2" => 24.0,
        "h3" => 19.0,
        "h4" => 16.0,
        "h5" => 13.0,
        "h6" => 11.0,
        // otp-detect looks tags up with `in`, which also finds what every JavaScript object
        // inherits; its value is a function, which as a font size is not a number
        "constructor" => f64::NAN,
        _ => return None,
    })
}

fn named_entity(name: &str) -> Option<&'static str> {
    Some(match name {
        "amp" => "&",
        "lt" => "<",
        "gt" => ">",
        "quot" => "\"",
        "apos" => "'",
        "nbsp" | "ensp" | "emsp" | "thinsp" => " ",
        "zwnj" | "zwj" | "shy" => "",
        "copy" => "©",
        "reg" => "®",
        "trade" => "™",
        "hellip" => "…",
        "mdash" | "ndash" => "-",
        "laquo" => "«",
        "raquo" => "»",
        "lsquo" | "rsquo" => "'",
        "ldquo" | "rdquo" | "bdquo" => "\"",
        "bull" => "•",
        "middot" => "·",
        "euro" => "€",
        "pound" => "£",
        "yen" => "¥",
        "cent" => "¢",
        "sect" => "§",
        "deg" => "°",
        "times" => "×",
        "auml" => "ä",
        "ouml" => "ö",
        "uuml" => "ü",
        "otilde" => "õ",
        "Auml" => "Ä",
        "Ouml" => "Ö",
        "Uuml" => "Ü",
        "Otilde" => "Õ",
        "scaron" => "š",
        "Scaron" => "Š",
        "zcaron" => "ž",
        "Zcaron" => "Ž",
        "szlig" => "ß",
        "aacute" => "á",
        "eacute" => "é",
        "iacute" => "í",
        "oacute" => "ó",
        "uacute" => "ú",
        "agrave" => "à",
        "egrave" => "è",
        "ecirc" => "ê",
        "ccedil" => "ç",
        "ntilde" => "ñ",
        "aring" => "å",
        "Aring" => "Å",
        "oslash" => "ø",
        "Oslash" => "Ø",
        "aelig" => "æ",
        "AElig" => "Æ",
        // otp-detect reads its entity table as a JavaScript object, so the names of what every
        // object inherits turn into the text of those functions
        "constructor" => "function Object() { [native code] }",
        "hasOwnProperty" => "function hasOwnProperty() { [native code] }",
        "isPrototypeOf" => "function isPrototypeOf() { [native code] }",
        "propertyIsEnumerable" => "function propertyIsEnumerable() { [native code] }",
        "toLocaleString" => "function toLocaleString() { [native code] }",
        "toString" => "function toString() { [native code] }",
        "valueOf" => "function valueOf() { [native code] }",
        _ => return None,
    })
}

static ENTITY: LazyLock<Regex> = LazyLock::new(|| {
    Regex::new(r"&(?:#([0-9]{1,7})|#[xX]([0-9a-fA-F]{1,6})|([a-zA-Z][a-zA-Z0-9]{1,31}));?").expect("valid")
});

pub fn decode_entities(input: &str) -> std::borrow::Cow<'_, str> {
    if !input.contains('&') {
        return input.into();
    }
    ENTITY.replace_all(input, |caps: &Captures| -> String {
        if let Some(name) = caps.get(3) {
            return named_entity(name.as_str()).unwrap_or(&caps[0]).to_string();
        }
        let code = match (caps.get(1), caps.get(2)) {
            (Some(dec), _) => dec.as_str().parse::<u32>(),
            (_, Some(hex)) => u32::from_str_radix(hex.as_str(), 16),
            _ => return caps[0].to_string(),
        }
        .unwrap_or(0);
        match char::from_u32(code) {
            Some(c) if code != 0 => c.to_string(),
            _ => "\u{FFFD}".to_string(),
        }
    })
}

/// The attributes element_style reads, `(?:^|\s)name\s*=\s*(?:"([^"]*)"|'([^']*)'|([^\s"'>]+))`
fn attr_regex(name: &str) -> Regex {
    pe_jsre::regex(
        &format!(r#"(?:^|\s){name}\s*=\s*(?:"([^"]*)"|'([^']*)'|([^\s"'>]+))"#),
        "i",
    )
}

static ATTRS: LazyLock<[Regex; 6]> = LazyLock::new(|| {
    [
        attr_regex("href"),
        attr_regex("size"),
        attr_regex("hidden"),
        attr_regex("style"),
        attr_regex("class"),
        attr_regex("type"),
    ]
});

#[derive(Clone, Copy)]
enum Attr {
    Href,
    Size,
    Hidden,
    Style,
    Class,
    Type,
}

fn attr(attrs: &str, name: Attr) -> Option<String> {
    let caps = ATTRS[name as usize].captures(attrs)?;
    let value = caps.get(1).or(caps.get(2)).or(caps.get(3)).map_or("", |m| m.as_str());
    Some(decode_entities(value).into_owned())
}

static CSS_LENGTH: LazyLock<Regex> = LazyLock::new(|| pe_jsre::regex(r"^\s*(-?[\d.]+)\s*(px|pt|em|rem|%)?", "i"));
static CSS_ZERO: LazyLock<Regex> = LazyLock::new(|| pe_jsre::regex(r"^\s*0\b", ""));

fn css_length(value: &str, parent_size: f64) -> Option<f64> {
    let Some(caps) = CSS_LENGTH.captures(value) else {
        return CSS_ZERO.is_match(value).then_some(0.0);
    };
    let n = parse_float(&caps[1]);
    if !n.is_finite() {
        return None;
    }
    let unit = caps.get(2).map_or("px".to_string(), |m| m.as_str().to_lowercase());
    Some(match unit.as_str() {
        "pt" => n * (4.0 / 3.0),
        "em" => n * parent_size,
        "rem" => n * DEFAULT_FONT_SIZE,
        "%" => (n / 100.0) * parent_size,
        _ => n,
    })
}

fn keyword_size(value: &str) -> Option<f64> {
    Some(match value {
        "xx-small" => 9.0,
        "x-small" => 10.0,
        "small" => 13.0,
        "medium" => 16.0,
        "large" => 18.0,
        "x-large" => 24.0,
        "xx-large" => 32.0,
        "xxx-large" => 48.0,
        // what every JavaScript object inherits, which is no number
        "constructor" | "__proto__" => f64::NAN,
        _ => return None,
    })
}

/// `.replace(/!important/i, '')`: the first one only
fn remove_important(value: &str) -> std::borrow::Cow<'_, str> {
    const IMPORTANT: &str = "!important";
    let bytes = value.as_bytes();
    let found = (0..bytes.len().saturating_sub(IMPORTANT.len() - 1))
        .find(|&i| bytes[i..i + IMPORTANT.len()].eq_ignore_ascii_case(IMPORTANT.as_bytes()));
    match found {
        Some(i) => format!("{}{}", &value[..i], &value[i + IMPORTANT.len()..]).into(),
        None => value.into(),
    }
}

/// Applies the inline CSS declarations that change how a code would look
fn apply_css(style: &mut Style, css: &str, parent_size: f64) {
    for decl in css.split(';') {
        let Some(colon) = decl.find(':') else {
            continue;
        };
        let prop = trim(&decl[..colon]).to_lowercase();
        let value = trim(&remove_important(&decl[colon + 1..])).to_lowercase();
        apply_declaration(style, &prop, &value, parent_size);
    }
}

static MONO_FONT: LazyLock<Regex> = LazyLock::new(|| Regex::new("mono|courier|consolas|menlo").expect("valid"));

fn apply_declaration(style: &mut Style, prop: &str, value: &str, parent_size: f64) {
    match prop {
        "font-size" => {
            if let Some(size) = keyword_size(value).or_else(|| css_length(value, parent_size)) {
                style.font_size = size;
                style.hidden |= size <= 1.0;
            }
        }
        "font-weight" => {
            style.bold = value == "bold" || value == "bolder" || parse_int(value) >= 600.0;
        }
        "letter-spacing" => {
            style.letter_spacing = css_length(value, parent_size).is_some_and(|spacing| spacing >= 1.0);
        }
        "font-family" => style.mono |= MONO_FONT.is_match(value),
        "display" => style.hidden |= value == "none",
        "visibility" => style.hidden |= value == "hidden",
        "opacity" => style.hidden |= parse_float(value) == 0.0,
        "max-height" | "height" => style.hidden |= value == "0" || value == "0px",
        _ => {}
    }
}

static QUOTE_CLASS: LazyLock<Regex> =
    LazyLock::new(|| pe_jsre::regex(r"\bgmail_quote\b|\byahoo_quoted\b|\bmoz-cite-prefix\b", "i"));

fn element_style(tag: &str, attrs: &str, parent: &Style) -> Style {
    let mut style = parent.clone();
    if tag == "b" || tag == "strong" {
        style.bold = true;
    } else if let Some(size) = heading_size(tag) {
        style.heading = true;
        style.bold = true;
        style.font_size = size;
    } else if tag == "a" && attr(attrs, Attr::Href).is_some_and(|href| !href.is_empty()) {
        style.link = true;
    } else if tag == "blockquote" {
        style.quote = true;
    } else if MONO_TAGS.contains(&tag) {
        style.mono = true;
    } else if tag == "font" {
        let size = parse_int(&attr(attrs, Attr::Size).unwrap_or_default());
        if (1.0..=7.0).contains(&size) {
            style.font_size = FONT_TAG_SIZE[size as usize];
        }
    }
    if attr(attrs, Attr::Hidden).is_some() {
        style.hidden = true;
    }
    if let Some(css) = attr(attrs, Attr::Style).filter(|css| !css.is_empty()) {
        apply_css(&mut style, &css, parent.font_size);
    }
    // Quoted reply history in the common clients
    let class = attr(attrs, Attr::Class).unwrap_or_default();
    if QUOTE_CLASS.is_match(&class) || attr(attrs, Attr::Type).is_some_and(|t| t.to_lowercase() == "cite") {
        style.quote = true;
    }
    style
}

/// One token of the HTML, as the alternatives of otp-detect's TOKEN_RE match it
enum Token<'a> {
    /// A comment, doctype or processing instruction
    Markup,
    Tag {
        close: bool,
        name: &'a str,
        attrs: &'a str,
    },
    /// Text, or a `<` that starts nothing
    Text(&'a str),
}

/// Splits HTML into tokens the way `/<!--[\s\S]*?(?:-->|$)|<![^<>]*>|<\?[^<>]*>|<(\/?)([a-zA-Z][a-zA-Z0-9:-]*)((?:[^>"'<]|"[^"]*"|'[^']*')*)>|[^<]+|</g`
/// does. Every alternative is deterministic, so this reads each at most once; a quote without its
/// closing quote is remembered, so an unclosed quote costs one scan to the end, not one per tag.
struct Tokenizer<'a> {
    html: &'a str,
    pos: usize,
    /// Offsets after which there is no `"` (index 0) or `'` (index 1)
    no_quote_after: [usize; 2],
}

impl<'a> Tokenizer<'a> {
    fn new(html: &'a str) -> Tokenizer<'a> {
        Tokenizer {
            html,
            pos: 0,
            no_quote_after: [usize::MAX; 2],
        }
    }

    /// The offset of the closing quote for a quote at `at`
    fn closing_quote(&mut self, at: usize, quote: u8) -> Option<usize> {
        let slot = usize::from(quote == b'\'');
        if at >= self.no_quote_after[slot] {
            return None;
        }
        match self.html.as_bytes()[at + 1..].iter().position(|&b| b == quote) {
            Some(i) => Some(at + 1 + i),
            None => {
                self.no_quote_after[slot] = at;
                None
            }
        }
    }

    /// `<![^<>]*>` and `<\?[^<>]*>`, the end of the token
    fn declaration(&self, from: usize) -> Option<usize> {
        let bytes = self.html.as_bytes();
        let stop = bytes[from..].iter().position(|&b| b == b'<' || b == b'>')?;
        (bytes[from + stop] == b'>').then_some(from + stop + 1)
    }

    /// `<(\/?)([a-zA-Z][a-zA-Z0-9:-]*)((?:[^>"'<]|"[^"]*"|'[^']*')*)>` at `start`
    fn tag(&mut self, start: usize) -> Option<(Token<'a>, usize)> {
        let bytes = self.html.as_bytes();
        let mut at = start + 1;
        let close = bytes.get(at) == Some(&b'/');
        at += usize::from(close);
        if !bytes.get(at).is_some_and(u8::is_ascii_alphabetic) {
            return None;
        }
        let name_start = at;
        at += 1;
        while bytes
            .get(at)
            .is_some_and(|&b| b.is_ascii_alphanumeric() || b == b':' || b == b'-')
        {
            at += 1;
        }
        let name_end = at;
        loop {
            match *bytes.get(at)? {
                b'>' => break,
                b'<' => return None,
                quote @ (b'"' | b'\'') => at = self.closing_quote(at, quote)? + 1,
                _ => at += 1,
            }
        }
        let html = self.html;
        Some((
            Token::Tag {
                close,
                name: &html[name_start..name_end],
                attrs: &html[name_end..at],
            },
            at + 1,
        ))
    }

    fn token_at(&mut self, start: usize) -> (Token<'a>, usize) {
        let html = self.html;
        let rest = &html.as_bytes()[start..];
        if rest[0] != b'<' {
            let end = rest.iter().position(|&b| b == b'<').map_or(html.len(), |i| start + i);
            return (Token::Text(&html[start..end]), end);
        }
        if rest.starts_with(b"<!--") {
            let end = html[start + 4..].find("-->").map_or(html.len(), |i| start + 4 + i + 3);
            return (Token::Markup, end);
        }
        if (rest.starts_with(b"<!") || rest.starts_with(b"<?"))
            && let Some(end) = self.declaration(start + 2)
        {
            return (Token::Markup, end);
        }
        if let Some(found) = self.tag(start) {
            return found;
        }
        (Token::Text(&html[start..start + 1]), start + 1)
    }
}

impl<'a> Iterator for Tokenizer<'a> {
    type Item = Token<'a>;

    fn next(&mut self) -> Option<Token<'a>> {
        if self.pos >= self.html.len() {
            return None;
        }
        let (token, end) = self.token_at(self.pos);
        self.pos = end;
        Some(token)
    }
}

struct Open {
    tag: String,
    style: Rc<Style>,
    block: bool,
}

/// The open elements, with how many of each tag are open, so a close tag without an open element
/// costs no walk down the stack
#[derive(Default)]
struct Stack {
    open: Vec<Open>,
    counts: HashMap<String, usize>,
}

impl Stack {
    fn push(&mut self, open: Open) {
        *self.counts.entry(open.tag.clone()).or_default() += 1;
        self.open.push(open);
    }

    fn pop(&mut self) -> Option<Open> {
        let open = self.open.pop()?;
        if let Some(count) = self.counts.get_mut(&open.tag) {
            *count -= 1;
        }
        Some(open)
    }

    fn has(&self, tag: &str) -> bool {
        self.counts.get(tag).is_some_and(|&n| n > 0)
    }
}

pub fn render_html(html: &str) -> Doc {
    let default = Rc::new(DEFAULT_STYLE);
    let mut doc = DocBuilder::new(Source::Html);
    let mut stack = Stack::default();
    let mut skip_until: Option<String> = None;

    for token in Tokenizer::new(html) {
        let (close, tag, attrs) = match token {
            Token::Tag { close, name, attrs } => (close, name.to_ascii_lowercase(), attrs),
            Token::Markup => continue,
            Token::Text(text) => {
                if skip_until.is_none() {
                    let style = stack.open.last().map_or(&default, |o| &o.style);
                    doc.text(&decode_entities(text), style);
                }
                continue;
            }
        };
        if let Some(skip) = &skip_until {
            if close && *skip == tag {
                skip_until = None;
            }
            continue;
        }
        if close {
            close_tag(&mut doc, &mut stack, &tag);
            continue;
        }
        let self_closing = attrs.trim_end_matches(is_space).ends_with('/');
        if SKIP_CONTENT.contains(&tag.as_str()) && !self_closing {
            skip_until = Some(tag);
            continue;
        }
        let parent = stack.open.last().map_or(&default, |o| &o.style).clone();
        open_tag(&mut doc, &mut stack, tag, attrs, self_closing, &parent);
    }
    doc.finish()
}

fn open_tag(doc: &mut DocBuilder, stack: &mut Stack, tag: String, attrs: &str, self_closing: bool, parent: &Style) {
    if tag == "br" {
        doc.newline();
        return;
    }
    let block = BLOCK.contains(&tag.as_str());
    if VOID.contains(&tag.as_str()) || self_closing {
        if block {
            doc.newline();
        }
        return;
    }
    if block {
        doc.open_block();
    }
    let style = Rc::new(element_style(&tag, attrs, parent));
    stack.push(Open { tag, style, block });
}

fn close_tag(doc: &mut DocBuilder, stack: &mut Stack, tag: &str) {
    // Close up to the matching element; a stray close tag with no match is ignored
    if !stack.has(tag) {
        return;
    }
    while let Some(open) = stack.pop() {
        if open.block {
            doc.close_block();
        }
        if open.tag == tag {
            break;
        }
    }
}
