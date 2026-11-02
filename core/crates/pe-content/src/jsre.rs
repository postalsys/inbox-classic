//! JavaScript regular expressions on the `regex` crate.
//!
//! The detector patterns are data written for JavaScript (`patterns/*.json`), and the hard coded
//! expressions of email-content are JavaScript too. Both are translated here so they keep their
//! JavaScript meaning: `\d`, `\w` and `\b` are ASCII only, `\s` is the JavaScript whitespace set,
//! and `.` stops at the four JavaScript line terminators.
//!
//! The `regex` crate has no lookaround. The patterns use it in one shape only, a run of lookaheads
//! right after a leading `^\s*`, and that shape is evaluated exactly: the lookaheads and the rest
//! are separate expressions tried at every place the leading whitespace run can end, which is what
//! a backtracking engine does. Any other lookaround is reported as a pattern that does not compile.

use regex::{Regex, RegexBuilder};

/// The JavaScript `\s` set, as the inside of a character class.
pub(crate) const JS_WS_CLASS: &str =
    r"\t\n\x0B\x0C\r \x{A0}\x{1680}\x{2000}-\x{200A}\x{2028}\x{2029}\x{202F}\x{205F}\x{3000}\x{FEFF}";

const WORD_CLASS: &str = "0-9A-Za-z_";

/// A compiled JavaScript regular expression.
#[derive(Debug)]
pub(crate) struct JsRegex {
    kind: Kind,
}

#[derive(Debug)]
enum Kind {
    Plain(Regex),
    /// `^\s*` followed by lookaheads, then the rest, each anchored at the end of the whitespace.
    Lookahead {
        looks: Vec<(bool, Regex)>,
        rest: Regex,
    },
}

impl JsRegex {
    /// Compile `source` with JavaScript `flags`. Only `i`, `m`, `s` and `u` are accepted.
    pub(crate) fn new(source: &str, flags: &str) -> Result<JsRegex, String> {
        let mut prefix = String::new();
        let mut dot_all = false;
        let mut unicode = false;
        for flag in flags.chars() {
            match flag {
                'i' => prefix.push_str("(?i)"),
                'm' => prefix.push_str("(?m)"),
                's' => dot_all = true,
                'u' => unicode = true,
                _ => return Err(format!("unsupported flag {flag}")),
            }
        }
        if let Some((looks, rest)) = split_leading_lookaheads(source)? {
            let mut compiled = Vec::with_capacity(looks.len());
            for (negative, body) in looks {
                let body = translate(body, dot_all, unicode)?;
                compiled.push((negative, build(&format!("{prefix}^(?:{body})"))?));
            }
            let rest = translate(rest, dot_all, unicode)?;
            return Ok(JsRegex {
                kind: Kind::Lookahead {
                    looks: compiled,
                    rest: build(&format!("{prefix}^(?:{rest})"))?,
                },
            });
        }
        let body = translate(source, dot_all, unicode)?;
        Ok(JsRegex {
            kind: Kind::Plain(build(&format!("{prefix}{body}"))?),
        })
    }

    /// Compile an expression known to be valid. For the hard coded expressions of the port.
    pub(crate) fn fixed(source: &str, flags: &str) -> JsRegex {
        match JsRegex::new(source, flags) {
            Ok(regex) => regex,
            Err(err) => panic!("built in expression {source:?} does not compile: {err}"),
        }
    }

    /// `RegExp.prototype.test`.
    pub(crate) fn is_match(&self, text: &str) -> bool {
        match &self.kind {
            Kind::Plain(regex) => regex.is_match(text),
            Kind::Lookahead { looks, rest } => {
                // Every place the leading `\s*` can stop, longest first like the engine.
                let mut ends = vec![0];
                for (at, c) in text.char_indices() {
                    if !is_js_ws(c) {
                        break;
                    }
                    ends.push(at + c.len_utf8());
                }
                ends.iter().rev().any(|&at| {
                    let tail = &text[at..];
                    looks.iter().all(|(negative, look)| look.is_match(tail) != *negative) && rest.is_match(tail)
                })
            }
        }
    }

    /// The underlying expression, for expressions without lookaheads.
    pub(crate) fn re(&self) -> &Regex {
        match &self.kind {
            Kind::Plain(regex) => regex,
            Kind::Lookahead { .. } => panic!("expression with lookaheads has no single regex"),
        }
    }
}

fn build(pattern: &str) -> Result<Regex, String> {
    RegexBuilder::new(pattern)
        .size_limit(64 << 20)
        .dfa_size_limit(16 << 20)
        .build()
        .map_err(|err| err.to_string())
}

/// JavaScript whitespace: what `\s` matches and what `String.prototype.trim` removes.
pub(crate) fn is_js_ws(c: char) -> bool {
    matches!(
        c,
        '\t' | '\n' | '\u{0B}' | '\u{0C}' | '\r' | ' ' | '\u{A0}' | '\u{1680}' | '\u{2000}'
            ..='\u{200A}' | '\u{2028}' | '\u{2029}' | '\u{202F}' | '\u{205F}' | '\u{3000}' | '\u{FEFF}'
    )
}

/// Split `^\s*(?=..)(?!..)rest` into its lookaheads and the rest. `None` when the source does not
/// start that way; an error when it has lookaround anywhere else or alternation at the top level.
/// Lookahead bodies with their polarity (`true` for negative), and the rest of the pattern.
type Lookaheads<'s> = (Vec<(bool, &'s str)>, &'s str);

fn split_leading_lookaheads(source: &str) -> Result<Option<Lookaheads<'_>>, String> {
    let Some(mut tail) = source.strip_prefix(r"^\s*") else {
        return Ok(None);
    };
    if !tail.starts_with("(?=") && !tail.starts_with("(?!") {
        return Ok(None);
    }
    let mut looks = Vec::new();
    while tail.starts_with("(?=") || tail.starts_with("(?!") {
        let negative = tail.as_bytes()[2] == b'!';
        let close = group_end(tail).ok_or("unbalanced lookahead")?;
        looks.push((negative, &tail[3..close]));
        tail = &tail[close + 1..];
    }
    if has_top_level_alternation(tail) {
        return Err("alternation after a lookahead".into());
    }
    Ok(Some((looks, tail)))
}

/// Index of the `)` closing the group that opens at the start of `s`.
fn group_end(s: &str) -> Option<usize> {
    let bytes = s.as_bytes();
    let mut depth = 0usize;
    let mut i = 0;
    let mut in_class = false;
    while i < bytes.len() {
        match bytes[i] {
            b'\\' => i += 1,
            b'[' if !in_class => in_class = true,
            b']' if in_class => in_class = false,
            b'(' if !in_class => depth += 1,
            b')' if !in_class => {
                depth -= 1;
                if depth == 0 {
                    return Some(i);
                }
            }
            _ => {}
        }
        i += 1;
    }
    None
}

fn has_top_level_alternation(s: &str) -> bool {
    let bytes = s.as_bytes();
    let mut depth = 0usize;
    let mut i = 0;
    let mut in_class = false;
    while i < bytes.len() {
        match bytes[i] {
            b'\\' => i += 1,
            b'[' if !in_class => in_class = true,
            b']' if in_class => in_class = false,
            b'(' if !in_class => depth += 1,
            b')' if !in_class => depth = depth.saturating_sub(1),
            b'|' if !in_class && depth == 0 => return true,
            _ => {}
        }
        i += 1;
    }
    false
}

enum ClassItem {
    Char(char),
    /// The inside of a class, or a whole nested class.
    Set(String),
}

fn hex_char(c: char) -> String {
    format!("\\x{{{:X}}}", c as u32)
}

/// A literal character outside a class.
fn literal(c: char) -> String {
    if c.is_ascii_alphanumeric() || c == ' ' || !c.is_ascii() {
        c.to_string()
    } else {
        hex_char(c)
    }
}

/// A literal character inside a class.
fn class_literal(c: char) -> String {
    if c.is_ascii_alphanumeric() || (!c.is_ascii() && !is_js_ws(c)) {
        c.to_string()
    } else {
        hex_char(c)
    }
}

fn hex_value(chars: &[char], at: usize, len: usize) -> Option<char> {
    if at + len > chars.len() {
        return None;
    }
    let text: String = chars[at..at + len].iter().collect();
    if !text.chars().all(|c| c.is_ascii_hexdigit()) {
        return None;
    }
    // A lone surrogate cannot be a Rust char; it stands for the replacement character here.
    Some(char::from_u32(u32::from_str_radix(&text, 16).ok()?).unwrap_or('\u{FFFD}'))
}

/// Read one escape after a backslash at `chars[*i]`. Advances `*i` past it.
fn escape(chars: &[char], i: &mut usize, in_class: bool, unicode: bool) -> Result<ClassItem, String> {
    let c = *chars.get(*i).ok_or("trailing backslash")?;
    *i += 1;
    let set = |inner: &str, negated: bool| {
        if negated {
            ClassItem::Set(format!("[^{inner}]"))
        } else if in_class {
            ClassItem::Set(inner.to_string())
        } else {
            ClassItem::Set(format!("[{inner}]"))
        }
    };
    Ok(match c {
        'd' => set("0-9", false),
        'D' => set("0-9", true),
        'w' => set(WORD_CLASS, false),
        'W' => set(WORD_CLASS, true),
        's' => set(JS_WS_CLASS, false),
        'S' => set(JS_WS_CLASS, true),
        'b' if in_class => ClassItem::Char('\u{8}'),
        'b' => ClassItem::Set(r"(?-u:\b)".into()),
        'B' => ClassItem::Set(r"(?-u:\B)".into()),
        'n' => ClassItem::Char('\n'),
        'r' => ClassItem::Char('\r'),
        't' => ClassItem::Char('\t'),
        'f' => ClassItem::Char('\u{C}'),
        'v' => ClassItem::Char('\u{B}'),
        '0' if !chars.get(*i).is_some_and(|c| c.is_ascii_digit()) => ClassItem::Char('\0'),
        '1'..='9' => return Err("backreferences are not supported".into()),
        'u' => match hex_value(chars, *i, 4) {
            Some(value) => {
                *i += 4;
                ClassItem::Char(value)
            }
            None => ClassItem::Char('u'),
        },
        'x' => match hex_value(chars, *i, 2) {
            Some(value) => {
                *i += 2;
                ClassItem::Char(value)
            }
            None => ClassItem::Char('x'),
        },
        'c' if chars.get(*i).is_some_and(|c| c.is_ascii_alphabetic()) => {
            let letter = chars[*i];
            *i += 1;
            ClassItem::Char(char::from_u32(letter as u32 % 32).unwrap_or('\0'))
        }
        'p' | 'P' if unicode && chars.get(*i) == Some(&'{') => {
            let close = chars[*i..]
                .iter()
                .position(|&c| c == '}')
                .ok_or("unterminated property")?;
            let name: String = chars[*i..*i + close + 1].iter().collect();
            *i += close + 1;
            ClassItem::Set(format!("\\{c}{name}"))
        }
        'k' => return Err("named backreferences are not supported".into()),
        other => ClassItem::Char(other),
    })
}

/// Translate a JavaScript pattern (without lookarounds) to `regex` syntax.
fn translate(source: &str, dot_all: bool, unicode: bool) -> Result<String, String> {
    let chars: Vec<char> = source.chars().collect();
    let mut out = String::with_capacity(source.len() * 2);
    let mut i = 0;
    while i < chars.len() {
        let c = chars[i];
        i += 1;
        match c {
            '\\' => match escape(&chars, &mut i, false, unicode)? {
                ClassItem::Char(c) => out.push_str(&literal(c)),
                ClassItem::Set(set) => out.push_str(&set),
            },
            '[' => i = class(&chars, i, &mut out, unicode)?,
            '.' => out.push_str(if dot_all { r"(?s:.)" } else { r"[^\n\r\x{2028}\x{2029}]" }),
            '(' => {
                if chars.get(i) == Some(&'?') {
                    match chars.get(i + 1) {
                        Some(':') => {
                            out.push_str("(?:");
                            i += 2;
                        }
                        Some('<') if !matches!(chars.get(i + 2), Some('=') | Some('!')) => {
                            out.push_str("(?P<");
                            i += 2;
                        }
                        _ => return Err("lookaround is only supported after a leading ^\\s*".into()),
                    }
                } else {
                    out.push('(');
                }
            }
            '{' => {
                // A quantifier when it reads like one, a literal brace otherwise, as in JavaScript.
                let close = chars[i..].iter().take(24).position(|&c| c == '}');
                let inner: Option<String> = close.map(|close| chars[i..i + close].iter().collect());
                let quantifier = inner.as_deref().is_some_and(|inner| {
                    let mut parts = inner.splitn(2, ',');
                    let min = parts.next().unwrap_or("");
                    let max = parts.next();
                    !min.is_empty()
                        && min.chars().all(|c| c.is_ascii_digit())
                        && max.is_none_or(|max| max.chars().all(|c| c.is_ascii_digit()))
                });
                match (quantifier, inner, close) {
                    (true, Some(inner), Some(close)) => {
                        out.push('{');
                        out.push_str(&inner);
                        out.push('}');
                        i += close + 1;
                    }
                    _ => out.push_str(r"\{"),
                }
            }
            '}' => out.push_str(r"\}"),
            '^' | '$' | '|' | ')' | '*' | '+' | '?' => out.push(c),
            other => out.push_str(&literal(other)),
        }
    }
    Ok(out)
}

/// Translate a class starting after its `[`. Returns the index after its `]`.
fn class(chars: &[char], mut i: usize, out: &mut String, unicode: bool) -> Result<usize, String> {
    let negated = chars.get(i) == Some(&'^');
    if negated {
        i += 1;
    }
    if chars.get(i) == Some(&']') {
        // `[]` matches nothing and `[^]` anything.
        out.push_str(if negated { r"(?s:.)" } else { r"[^\x{0}-\x{10FFFF}]" });
        return Ok(i + 1);
    }
    let mut items = String::new();
    loop {
        let c = *chars.get(i).ok_or("unterminated class")?;
        if c == ']' {
            i += 1;
            break;
        }
        i += 1;
        let first = if c == '\\' {
            escape(chars, &mut i, true, unicode)?
        } else {
            ClassItem::Char(c)
        };
        let range_follows = chars.get(i) == Some(&'-') && chars.get(i + 1).is_some_and(|&next| next != ']');
        match first {
            ClassItem::Char(low) if range_follows => {
                i += 1;
                let next = chars[i];
                i += 1;
                let high = if next == '\\' {
                    escape(chars, &mut i, true, unicode)?
                } else {
                    ClassItem::Char(next)
                };
                match high {
                    ClassItem::Char(high) => {
                        if high < low {
                            return Err("range out of order".into());
                        }
                        items.push_str(&class_literal(low));
                        items.push('-');
                        items.push_str(&class_literal(high));
                    }
                    ClassItem::Set(set) => {
                        // `[a-\d]`: in JavaScript the dash is then a literal.
                        items.push_str(&class_literal(low));
                        items.push_str(&class_literal('-'));
                        items.push_str(&set);
                    }
                }
            }
            ClassItem::Char(c) => items.push_str(&class_literal(c)),
            ClassItem::Set(set) => items.push_str(&set),
        }
    }
    out.push('[');
    if negated {
        out.push('^');
    }
    out.push_str(&items);
    out.push(']');
    Ok(i)
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn keeps_javascript_meanings() {
        let word = JsRegex::fixed(r"\bwrote\b", "i");
        assert!(word.is_match("Bob wrote:"));
        assert!(word.is_match("éwrote"), "\\b is ASCII only in JavaScript");
        assert!(JsRegex::fixed(r"^\d+$", "").is_match("123"));
        assert!(!JsRegex::fixed(r"^\d+$", "").is_match("١٢"));
        assert!(JsRegex::fixed(r"^\s$", "").is_match("\u{FEFF}"));
        assert!(!JsRegex::fixed(r"^.$", "").is_match("\u{2028}"));
        assert!(JsRegex::fixed(r"[\w.+-]{2}", "").is_match("a-"));
        assert!(JsRegex::fixed(r"[^[\]@]x", "").is_match("ax"));
        assert!(JsRegex::fixed(r"a{2}", "").is_match("aa"));
        assert!(JsRegex::fixed(r"a{x}", "").is_match("a{x}"));
        assert!(JsRegex::fixed(r"\/\.\$", "").is_match("/.$"));
        assert!(JsRegex::fixed(r"[-\u2013]", "").is_match("\u{2013}"));
    }

    #[test]
    fn evaluates_leading_lookaheads() {
        let wrote = JsRegex::fixed(r"^\s*(?!(as|like)\b)(?!I\b).{3,200}?\bwrote\s*:\s*$", "i");
        assert!(wrote.is_match("Bob Smith wrote:"));
        assert!(!wrote.is_match("As I wrote:"));
        assert!(!wrote.is_match("I wrote:"));
        // The whitespace run can end before the lookahead position, as with backtracking.
        assert!(wrote.is_match(" As I wrote:"));
        let timed = JsRegex::fixed(r"^\s*(?=.*\d{1,2}:\d{2}).{3,200}?skrev\s*:\s*$", "i");
        assert!(timed.is_match("12:30 Bob skrev:"));
        assert!(!timed.is_match("Bob skrev:"));
        assert!(JsRegex::new(r"a(?=b)", "").is_err());
    }
}
