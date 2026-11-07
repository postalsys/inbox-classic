//! JavaScript regular expressions on the `regex` crate, shared by the ports of JavaScript
//! libraries (pe-content, pe-bounce) so their patterns can be kept as the original writes them.
//!
//! A pattern keeps the meaning JavaScript gives it:
//!
//! - `\d`, `\w` and `\b` are ASCII only, `\s` is JavaScript's whitespace ([`is_space`]), and `.`
//!   stops at the four line terminators (`\n`, `\r`, U+2028, U+2029) unless the `s` flag is set.
//! - `i` without `u` folds case as JavaScript does ([`fold`]): every letter of the BMP folds to
//!   its single uppercase, never from outside ASCII into ASCII (the Kelvin sign is not `k`, `ſ` is
//!   not `s`), and nothing outside the BMP folds. The folding is written into the translated
//!   pattern as classes, so Rust's own `(?i)` is not used. With `u` as well, JavaScript folds by
//!   Unicode simple case folding, which is what `(?i)` does.
//! - `m` ends lines at `\n` and `\r` (Rust's CRLF mode). Two places differ from JavaScript, as
//!   the `regex` crate cannot express them: `^` and `$` never match between the `\r` and `\n` of a
//!   CRLF, and U+2028 and U+2029 do not end lines. None of the patterns of the ports depends on
//!   either.
//! - `g` is accepted and changes nothing; the caller decides how to iterate.
//!
//! Rust's engine runs in linear time, so none of the care a JavaScript pattern takes against
//! backtracking is needed. It has no lookaround and no backreferences. Lookaround is supported in
//! one shape only, a run of lookaheads right after a leading `^\s*`, and that shape is evaluated
//! exactly: the lookaheads and the rest are separate expressions tried at every place the leading
//! whitespace run can end, which is what a backtracking engine does. Any other lookaround is
//! reported as a pattern that does not compile.
#![forbid(unsafe_code)]

pub mod fold;
mod text;

pub use text::{SPACE_CLASS, advance_utf16, collapse, is_blank, is_space, trim, truncate_utf16, utf16_len, words};

use regex::{Regex, RegexBuilder};

const WORD_CLASS: &str = "0-9A-Za-z_";

/// A compiled JavaScript regular expression.
#[derive(Debug)]
pub struct JsRegex {
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

/// The flags that change how a pattern is translated.
#[derive(Clone, Copy, Default)]
struct Flags {
    dot_all: bool,
    unicode: bool,
    /// `i` without `u`: folding written into the pattern.
    fold: bool,
}

impl JsRegex {
    /// Compile `source` with JavaScript `flags`. `i`, `m`, `s`, `u` and `g` are accepted.
    pub fn new(source: &str, flags: &str) -> Result<JsRegex, String> {
        let mut prefix = String::new();
        let mut ignore_case = false;
        let mut multiline = false;
        let mut f = Flags::default();
        for flag in flags.chars() {
            match flag {
                'i' => ignore_case = true,
                'm' => multiline = true,
                's' => f.dot_all = true,
                'u' => f.unicode = true,
                'g' => {}
                _ => return Err(format!("unsupported flag {flag}")),
            }
        }
        if ignore_case && f.unicode {
            prefix.push_str("(?i)");
        }
        f.fold = ignore_case && !f.unicode;
        if multiline {
            prefix.push_str("(?mR)");
        }
        if let Some((looks, rest)) = split_leading_lookaheads(source)? {
            if multiline {
                // `^` could then start at any line, which the evaluation below does not try.
                return Err("lookaheads with the m flag are not supported".into());
            }
            let mut compiled = Vec::with_capacity(looks.len());
            for (negative, body) in looks {
                let body = translate(body, f)?;
                compiled.push((negative, build(&format!(r"{prefix}\A(?:{body})"))?));
            }
            let rest = translate(rest, f)?;
            return Ok(JsRegex {
                kind: Kind::Lookahead {
                    looks: compiled,
                    rest: build(&format!(r"{prefix}\A(?:{rest})"))?,
                },
            });
        }
        let body = translate(source, f)?;
        Ok(JsRegex {
            kind: Kind::Plain(build(&format!("{prefix}{body}"))?),
        })
    }

    /// Compile an expression known to be valid, for the expressions written into a port.
    ///
    /// # Panics
    ///
    /// When it does not compile.
    pub fn fixed(source: &str, flags: &str) -> JsRegex {
        match JsRegex::new(source, flags) {
            Ok(regex) => regex,
            Err(err) => panic!("built in expression {source:?} does not compile: {err}"),
        }
    }

    /// `RegExp.prototype.test`.
    pub fn is_match(&self, text: &str) -> bool {
        match &self.kind {
            Kind::Plain(regex) => regex.is_match(text),
            Kind::Lookahead { looks, rest } => {
                // Every place the leading `\s*` can stop, longest first like the engine.
                let mut ends = vec![0];
                for (at, c) in text.char_indices() {
                    if !is_space(c) {
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

    /// The underlying expression.
    ///
    /// # Panics
    ///
    /// For an expression with lookaheads, which has no single one.
    pub fn re(&self) -> &Regex {
        match &self.kind {
            Kind::Plain(regex) => regex,
            Kind::Lookahead { .. } => panic!("expression with lookaheads has no single regex"),
        }
    }
}

/// A JavaScript regular expression without lookarounds as a plain [`Regex`], for the expressions
/// written into a port.
///
/// # Panics
///
/// When it does not compile or has lookaheads.
pub fn regex(source: &str, flags: &str) -> Regex {
    match JsRegex::fixed(source, flags).kind {
        Kind::Plain(regex) => regex,
        Kind::Lookahead { .. } => panic!("{source:?} has lookaheads; use JsRegex"),
    }
}

fn build(pattern: &str) -> Result<Regex, String> {
    RegexBuilder::new(pattern)
        .size_limit(64 << 20)
        .dfa_size_limit(16 << 20)
        .build()
        .map_err(|err| err.to_string())
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

/// A literal character outside a class, as a class of what it matches when the case folds.
fn literal(c: char, f: Flags) -> String {
    if f.fold
        && let Some(group) = fold::equivalents(c)
    {
        let mut out = String::from("[");
        for &e in group {
            out.push_str(&class_literal(e));
        }
        out.push(']');
        return out;
    }
    if c.is_ascii_alphanumeric() || c == ' ' || !c.is_ascii() {
        c.to_string()
    } else {
        hex_char(c)
    }
}

/// A literal character inside a class.
fn class_literal(c: char) -> String {
    if c.is_ascii_alphanumeric() || (!c.is_ascii() && !is_space(c)) {
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
        's' => set(SPACE_CLASS, false),
        'S' => set(SPACE_CLASS, true),
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
fn translate(source: &str, f: Flags) -> Result<String, String> {
    let chars: Vec<char> = source.chars().collect();
    let mut out = String::with_capacity(source.len() * 2);
    let mut i = 0;
    while i < chars.len() {
        let c = chars[i];
        i += 1;
        match c {
            '\\' => match escape(&chars, &mut i, false, f.unicode)? {
                ClassItem::Char(c) => out.push_str(&literal(c, f)),
                ClassItem::Set(set) => out.push_str(&set),
            },
            '[' => i = class(&chars, i, &mut out, f)?,
            '.' => out.push_str(if f.dot_all {
                r"(?s:.)"
            } else {
                r"[^\n\r\x{2028}\x{2029}]"
            }),
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
            other => out.push_str(&literal(other, f)),
        }
    }
    Ok(out)
}

/// Translate a class starting after its `[`. Returns the index after its `]`.
///
/// When the case folds, what the class's characters fold to is added to it; a negated class then
/// leaves all of that out, as JavaScript's does.
fn class(chars: &[char], mut i: usize, out: &mut String, f: Flags) -> Result<usize, String> {
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
    // What the class's characters and ranges fold to, when the case folds.
    let mut folded = Vec::new();
    loop {
        let c = *chars.get(i).ok_or("unterminated class")?;
        if c == ']' {
            i += 1;
            break;
        }
        i += 1;
        let first = if c == '\\' {
            escape(chars, &mut i, true, f.unicode)?
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
                    escape(chars, &mut i, true, f.unicode)?
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
                        if f.fold {
                            fold::range_equivalents(low, high, &mut folded);
                        }
                    }
                    ClassItem::Set(set) => {
                        // `[a-\d]`: in JavaScript the dash is then a literal.
                        items.push_str(&class_literal(low));
                        items.push_str(&class_literal('-'));
                        items.push_str(&set);
                        if f.fold {
                            folded.extend(fold::equivalents(low).unwrap_or_default());
                        }
                    }
                }
            }
            ClassItem::Char(c) => {
                items.push_str(&class_literal(c));
                if f.fold {
                    folded.extend(fold::equivalents(c).unwrap_or_default());
                }
            }
            // The escapes (`\d`, `\w`, `\s` and their negations) are closed under folding without `u`.
            ClassItem::Set(set) => items.push_str(&set),
        }
    }
    folded.sort_unstable();
    folded.dedup();
    for c in folded {
        items.push_str(&class_literal(c));
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

    #[test]
    fn folds_case_like_javascript_without_u() {
        let spam = JsRegex::fixed("spam", "i");
        assert!(spam.is_match("SPAM"));
        assert!(!spam.is_match("\u{17F}pam"), "ſ is not s");
        assert!(
            !JsRegex::fixed("kelvin", "i").is_match("\u{212A}elvin"),
            "the Kelvin sign is not k"
        );
        assert!(JsRegex::fixed("straße", "i").is_match("STRAßE"));
        assert!(
            !JsRegex::fixed("ß", "i").is_match("\u{1E9E}"),
            "ß has no single uppercase"
        );
        assert!(JsRegex::fixed("überweisung", "i").is_match("ÜBERWEISUNG"));
        assert!(JsRegex::fixed("ответ", "i").is_match("ОТВЕТ"));
        assert!(JsRegex::fixed("σ", "i").is_match("ς"));
        assert!(
            !JsRegex::fixed("\u{10428}", "i").is_match("\u{10400}"),
            "nothing outside the BMP folds"
        );
        assert!(JsRegex::fixed("[a-c]x", "i").is_match("BX"));
        assert!(JsRegex::fixed("[à-ä]", "i").is_match("Â"));
        assert!(!JsRegex::fixed("[^a-c]", "i").is_match("B"));
        assert!(JsRegex::fixed("[^a-c]", "i").is_match("d"));
        assert!(!JsRegex::fixed("[k]", "i").is_match("\u{212A}"));
        assert!(JsRegex::fixed(r"\u0041", "i").is_match("a"));
        assert!(!JsRegex::fixed(r"\w", "i").is_match("\u{17F}"));
        // A pattern without i stays case sensitive.
        assert!(!JsRegex::fixed("spam", "").is_match("SPAM"));
    }

    #[test]
    fn folds_case_like_javascript_with_u() {
        // With u, JavaScript folds by simple case folding: ſ is s and the Kelvin sign is k.
        assert!(JsRegex::fixed("spam", "iu").is_match("\u{17F}pam"));
        assert!(JsRegex::fixed("kelvin", "iu").is_match("\u{212A}elvin"));
    }

    #[test]
    fn multiline_ends_lines_at_cr_and_lf() {
        let b = regex("^b$", "m");
        assert_eq!(b.find("a\rb").map(|m| m.start()), Some(2));
        assert_eq!(b.find("a\nb\r\nc").map(|m| m.start()), Some(2));
        assert_eq!(b.find("a\r\nb").map(|m| m.start()), Some(3));
        assert!(!regex("^b", "").is_match("a\nb"));
        assert!(JsRegex::new(r"^\s*(?=a)a", "m").is_err());
    }

    #[test]
    fn flags_and_plain_regex() {
        assert!(JsRegex::new("a", "x").is_err());
        assert!(JsRegex::new("a", "g").is_ok());
        assert!(regex("a.b", "s").is_match("a\nb"));
        assert!(!regex("a.b", "").is_match("a\rb"));
        assert!(regex(r"[^<>\s]+", "").is_match("ä"));
        assert!(!regex(r"a\sb", "").is_match("a\u{85}b"));
        let caps = regex(r"(\d{3})[\s-](?:x|y)", "").captures("550-x").unwrap();
        assert_eq!(&caps[1], "550");
    }

    #[test]
    #[should_panic(expected = "lookaheads")]
    fn plain_regex_refuses_lookaheads() {
        regex(r"^\s*(?=a)a", "");
    }
}
