//! What the ported code needs to read text the way JavaScript does: its regular expressions, its
//! whitespace, and lengths counted in UTF-16 code units.
//!
//! The patterns are kept as the JavaScript source writes them and translated here, so they can be
//! compared with the original line by line. The translation gives them the meaning JavaScript
//! gives them without the `u` flag: `\w`, `\d` and `\b` are ASCII, `\s` is JavaScript's own set of
//! whitespace, `.` stops at the four line terminators, and the `i` flag folds ASCII letters only
//! (JavaScript never folds a letter outside ASCII into one inside it). Rust's engine runs in linear
//! time, so none of the care the JavaScript patterns take against backtracking is needed here; the
//! caps on input length are kept so the results stay the same.

use regex::Regex;

/// JavaScript's `\s`: WhiteSpace and LineTerminator
pub fn is_space(c: char) -> bool {
    matches!(
        c,
        '\t' | '\n' | '\u{0B}' | '\u{0C}' | '\r' | ' ' | '\u{A0}' | '\u{1680}' | '\u{2000}'
            ..='\u{200A}' | '\u{2028}' | '\u{2029}' | '\u{202F}' | '\u{205F}' | '\u{3000}' | '\u{FEFF}'
    )
}

/// The members of [`is_space`] for a character class
const SPACE_CLASS: &str =
    r"\t\n\x0B\x0C\r \u{A0}\u{1680}\u{2000}-\u{200A}\u{2028}\u{2029}\u{202F}\u{205F}\u{3000}\u{FEFF}";

/// `String.prototype.trim`
pub fn trim(s: &str) -> &str {
    s.trim_matches(is_space)
}

/// `.replace(/\s+/g, ' ').trim()`
pub fn collapse(s: &str) -> String {
    let mut out = String::with_capacity(s.len());
    for word in s.split(is_space).filter(|w| !w.is_empty()) {
        if !out.is_empty() {
            out.push(' ');
        }
        out.push_str(word);
    }
    out
}

/// The longest start of `s` that is at most `max` UTF-16 code units, as `substring(0, max)`
/// (which can split a surrogate pair; this leaves the whole character out instead)
pub fn truncate_utf16(s: &str, max: usize) -> &str {
    if s.len() <= max {
        return s;
    }
    let mut units = 0;
    for (i, c) in s.char_indices() {
        units += c.len_utf16();
        if units > max {
            return &s[..i];
        }
    }
    s
}

/// A JavaScript regular expression with its flags (`i`, `m`, `s`)
pub fn regex(pattern: &str, flags: &str) -> Regex {
    let mut out = String::from("(?");
    for flag in flags.chars() {
        match flag {
            'i' => out.push('i'),
            // JavaScript ends a line at \r as well as \n
            'm' => out.push_str("mR"),
            's' | 'g' => {}
            _ => panic!("unsupported flag {flag}"),
        }
    }
    out.push_str("-u)");
    let dot_all = flags.contains('s');
    let mut chars = pattern.chars().peekable();
    while let Some(c) = chars.next() {
        match c {
            '\\' => {
                let e = chars.next().expect("escape at the end of a pattern");
                out.push_str(&escape(e, &mut chars));
            }
            '.' if dot_all => out.push_str(r"(?su:.)"),
            '.' => out.push_str(r"(?u:[^\n\r\u{2028}\u{2029}])"),
            '[' => out.push_str(&class(&mut chars)),
            '(' if chars.peek() == Some(&'?') => {
                chars.next();
                match chars.next() {
                    Some(':') => out.push_str("(?:"),
                    other => panic!("unsupported group (?{other:?}"),
                }
            }
            c if c.is_ascii() => out.push(c),
            c => out.push_str(&format!("(?u:{})", regex::escape(c.encode_utf8(&mut [0; 4])))),
        }
    }
    Regex::new(&out).unwrap_or_else(|e| panic!("{pattern}: {e}"))
}

/// An escape outside a character class
fn escape(e: char, chars: &mut std::iter::Peekable<std::str::Chars<'_>>) -> String {
    match e {
        's' => format!("(?u:[{SPACE_CLASS}])"),
        'S' => format!("(?u:[^{SPACE_CLASS}])"),
        'W' => r"(?u:[^0-9A-Za-z_])".into(),
        'D' => r"(?u:[^0-9])".into(),
        'd' | 'w' | 'b' | 'B' | 'r' | 'n' | 't' | 'f' | 'v' => format!("\\{e}"),
        'u' => format!("(?u:\\u{{{}}})", hex(chars, 4)),
        'x' => format!("\\x{}", hex(chars, 2)),
        c if c.is_ascii_digit() => panic!("backreferences are not supported"),
        c => regex::escape(c.encode_utf8(&mut [0; 4])),
    }
}

fn hex(chars: &mut std::iter::Peekable<std::str::Chars<'_>>, len: usize) -> String {
    (0..len).map(|_| chars.next().expect("short hex escape")).collect()
}

/// A character class, after its `[`
fn class(chars: &mut std::iter::Peekable<std::str::Chars<'_>>) -> String {
    let mut body = String::new();
    let negated = chars.peek() == Some(&'^');
    if negated {
        chars.next();
    }
    // Unicode is needed for a negated class (it may match any character), for \s and for
    // characters outside ASCII
    let mut unicode = negated;
    loop {
        match chars.next().expect("unterminated class") {
            ']' => break,
            '\\' => match chars.next().expect("escape at the end of a class") {
                's' => {
                    body.push_str(SPACE_CLASS);
                    unicode = true;
                }
                'w' => body.push_str("0-9A-Za-z_"),
                'd' => body.push_str("0-9"),
                'u' => {
                    body.push_str(&format!("\\u{{{}}}", hex(chars, 4)));
                    unicode = true;
                }
                e @ ('r' | 'n' | 't' | 'f' | 'v') => {
                    body.push('\\');
                    body.push(e);
                }
                e => body.push_str(&regex::escape(e.encode_utf8(&mut [0; 4]))),
            },
            // Rust reads these as nested classes and set operations
            c @ ('[' | '&' | '~') => {
                body.push('\\');
                body.push(c);
            }
            c => {
                unicode |= !c.is_ascii();
                body.push(c);
            }
        }
    }
    let caret = if negated { "^" } else { "" };
    if unicode {
        format!("(?u:[{caret}{body}])")
    } else {
        format!("[{caret}{body}]")
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn word_and_boundary_are_ascii() {
        assert!(regex(r"\buser\b", "").is_match("é user"));
        assert!(regex(r"\buser\b", "").is_match("éuser"));
        assert!(!regex(r"\w", "").is_match("é"));
    }

    #[test]
    fn case_folds_ascii_only() {
        assert!(regex("spam", "i").is_match("SPAM"));
        assert!(!regex("kelvin", "i").is_match("\u{212A}elvin"));
        assert!(!regex("spam", "i").is_match("\u{17F}pam"));
    }

    #[test]
    fn space_and_dot() {
        assert!(regex(r"a\sb", "").is_match("a\u{FEFF}b"));
        assert!(!regex(r"a\sb", "").is_match("a\u{85}b"));
        assert!(!regex("a.b", "").is_match("a\u{2028}b"));
        assert!(regex("a.b", "s").is_match("a\nb"));
        assert!(regex(r"[^<>\s]+", "").is_match("ä"));
    }

    #[test]
    fn multiline_ends_lines_at_cr() {
        assert_eq!(regex("^b", "m").find("a\rb").map(|m| m.start()), Some(2));
    }

    #[test]
    fn helpers() {
        assert_eq!(collapse("  a \u{A0}\n b  "), "a b");
        assert_eq!(trim("\u{FEFF} x \u{2028}"), "x");
        assert_eq!(truncate_utf16("a😀b", 2), "a");
        assert_eq!(truncate_utf16("a😀b", 3), "a😀");
    }
}
