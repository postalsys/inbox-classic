//! String operations with JavaScript's meaning: its whitespace, and lengths counted in UTF-16 code
//! units.

/// JavaScript's `\s`: WhiteSpace and LineTerminator. Also what `String.prototype.trim` removes.
pub fn is_space(c: char) -> bool {
    matches!(
        c,
        '\t' | '\n' | '\u{0B}' | '\u{0C}' | '\r' | ' ' | '\u{A0}' | '\u{1680}' | '\u{2000}'
            ..='\u{200A}' | '\u{2028}' | '\u{2029}' | '\u{202F}' | '\u{205F}' | '\u{3000}' | '\u{FEFF}'
    )
}

/// The members of [`is_space`] as the inside of a `regex` character class.
pub const SPACE_CLASS: &str =
    r"\t\n\x0B\x0C\r \x{A0}\x{1680}\x{2000}-\x{200A}\x{2028}\x{2029}\x{202F}\x{205F}\x{3000}\x{FEFF}";

/// `String.prototype.trim`
pub fn trim(s: &str) -> &str {
    s.trim_matches(is_space)
}

/// True when `s` has nothing but JavaScript whitespace.
pub fn is_blank(s: &str) -> bool {
    s.chars().all(is_space)
}

/// `s.split(/\s+/).filter(Boolean)`
pub fn words(s: &str) -> impl Iterator<Item = &str> {
    s.split(is_space).filter(|word| !word.is_empty())
}

/// `s.replace(/\s+/g, ' ').trim()`
pub fn collapse(s: &str) -> String {
    let mut out = String::with_capacity(s.len());
    for word in words(s) {
        if !out.is_empty() {
            out.push(' ');
        }
        out.push_str(word);
    }
    out
}

/// `String.prototype.length`: UTF-16 code units.
pub fn utf16_len(s: &str) -> usize {
    if s.is_ascii() {
        s.len()
    } else {
        s.chars().map(char::len_utf16).sum()
    }
}

/// The longest start of `s` that is at most `max` UTF-16 code units, as `substring(0, max)`
/// (which can split a surrogate pair; this leaves the whole character out instead).
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

/// Byte index of the position `units` UTF-16 code units after the byte index `from`, or the end
/// of `s`.
pub fn advance_utf16(s: &str, from: usize, units: usize) -> usize {
    let mut taken = 0;
    for (at, c) in s[from..].char_indices() {
        if taken >= units {
            return from + at;
        }
        taken += c.len_utf16();
    }
    s.len()
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn helpers() {
        assert_eq!(collapse("  a \u{A0}\n b  "), "a b");
        assert_eq!(trim("\u{FEFF} x \u{2028}"), "x");
        assert!(!is_space('\u{85}'));
        assert!(is_blank(" \u{3000}\t"));
        assert_eq!(words(" a  b ").collect::<Vec<_>>(), ["a", "b"]);
        assert_eq!(utf16_len("a😀"), 3);
        assert_eq!(truncate_utf16("a😀b", 2), "a");
        assert_eq!(truncate_utf16("a😀b", 3), "a😀");
        assert_eq!(advance_utf16("a😀b", 0, 3), 5);
        assert_eq!(advance_utf16("ab", 1, 9), 2);
    }
}
