//! Character classes of the IMAP formal syntax (RFC 3501 section 9, RFC 9051 section 9), on bytes.

/// atom-specials: `(` `)` `{` SP CTL list-wildcards quoted-specials resp-specials
fn is_atom_special(c: u8) -> bool {
    matches!(c, b'(' | b')' | b'{' | b' ' | b'%' | b'*' | b'"' | b'\\' | b']') || c < 0x20 || c == 0x7f
}

/// ATOM-CHAR: any 7-bit CHAR except atom-specials
pub(crate) fn is_atom_char(c: u8) -> bool {
    (0x01..=0x7f).contains(&c) && !is_atom_special(c)
}

/// ASTRING-CHAR: ATOM-CHAR or resp-specials
pub(crate) fn is_astring_char(c: u8) -> bool {
    is_atom_char(c) || c == b']'
}

/// What a response tag may hold: ASTRING-CHAR (which includes `+`), plus `*` for untagged responses
pub(crate) fn is_tag_char(c: u8) -> bool {
    is_astring_char(c) || c == b'*'
}

/// What a command or response name may hold
pub(crate) fn is_command_char(c: u8) -> bool {
    c.is_ascii_alphanumeric() || c == b'-'
}

/// The responses that carry a response code and human readable text
pub(crate) fn is_status_command(name: &str) -> bool {
    ["OK", "NO", "BAD", "PREAUTH", "BYE"]
        .iter()
        .any(|status| name.eq_ignore_ascii_case(status))
}

/// The whitespace that separates the elements of a line: JavaScript's `\s` on ASCII, as imapflow
/// splits lines with it. Not `u8::is_ascii_whitespace`, which leaves out the vertical tab.
pub(crate) fn is_space(c: u8) -> bool {
    matches!(c, b' ' | b'\t' | b'\n' | 0x0b | 0x0c | b'\r')
}

pub(crate) fn trim(bytes: &[u8]) -> &[u8] {
    let start = bytes.iter().position(|c| !is_space(*c)).unwrap_or(bytes.len());
    let end = bytes.iter().rposition(|c| !is_space(*c)).map_or(start, |p| p + 1);
    &bytes[start..end]
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn atom_chars() {
        for c in b"abcXYZ019.:,-_+=!#$&'<>[/~^`|" {
            assert!(is_atom_char(*c), "{}", *c as char);
        }
        for c in b"()\x7b %*\"\\]\x00\x1f\x7f\x80\xff" {
            assert!(!is_atom_char(*c), "{c:#x}");
        }
        assert!(is_astring_char(b']'));
        assert!(is_tag_char(b'*') && is_tag_char(b'+') && !is_tag_char(b'"'));
        assert!(is_command_char(b'-') && !is_command_char(b'.'));
    }

    #[test]
    fn trims_ascii_space() {
        assert_eq!(trim(b" \t a b \r\n"), b"a b");
        assert_eq!(trim(b"   "), b"");
        assert_eq!(trim(b""), b"");
    }
}
