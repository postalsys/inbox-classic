//! Text in the charset a message declares, decoded to UTF-8. Any label the WHATWG Encoding Standard
//! knows works, plus the misspellings mail software uses; an unknown charset is read as UTF-8,
//! invalid sequences replaced, rather than failing the message.

use encoding_rs::{Encoding, REPLACEMENT};

/// The encoding of a charset label, None when it is unknown
pub fn encoding_for(charset: &str) -> Option<&'static Encoding> {
    // a RFC 2231 language suffix, "utf-8*en"
    let label = charset.split('*').next().unwrap_or("").trim().to_ascii_lowercase();
    let found = Encoding::for_label(label.as_bytes()).or_else(|| Encoding::for_label(normalize(&label).as_bytes()));
    // the replacement encoding turns everything into one U+FFFD, UTF-8 keeps more
    found.filter(|encoding| *encoding != REPLACEMENT)
}

/// Names mail software uses that are not encoding labels: win-1257, cp-1251, utf_8, latin-2
fn normalize(label: &str) -> String {
    let digits: String = label.chars().filter(char::is_ascii_digit).collect();
    let prefix = label.trim_end_matches(|c: char| c.is_ascii_digit() || c == '-' || c == '_');
    match prefix {
        "win" | "windows" | "cp" | "ms" | "x-cp" => format!("windows-{digits}"),
        "utf" => format!("utf-{digits}"),
        "latin" | "l" => format!("latin{digits}"),
        "iso" | "iso8859" | "iso-8859" | "iso_8859" => {
            let part = label.rsplit(['-', '_']).next().unwrap_or("");
            format!("iso-8859-{part}")
        }
        _ => label.replace('_', "-"),
    }
}

/// Decodes `bytes` from `charset`
pub fn decode(bytes: &[u8], charset: &str) -> String {
    match encoding_for(charset) {
        Some(encoding) => encoding.decode_without_bom_handling(bytes).0.into_owned(),
        None => String::from_utf8_lossy(bytes).into_owned(),
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn decodes_common_charsets() {
        assert_eq!(decode(b"\xf5\xe4\xf6\xfc", "iso-8859-1"), "õäöü");
        assert_eq!(decode(b"\xf5\xe4\xf6\xfc", "latin1"), "õäöü");
        assert_eq!(decode(b"\xd0\xc1", "koi8-r"), "па");
        assert_eq!(decode("õ".as_bytes(), "UTF-8"), "õ");
        assert_eq!(decode(b"\x82\xa0", "shift_jis"), "あ");
        assert_eq!(decode(b"\x1b$B$\"\x1b(B", "iso-2022-jp"), "あ");
    }

    #[test]
    fn decodes_misspelled_charsets() {
        assert_eq!(decode(b"\xe0", "win-1257"), "ą");
        assert_eq!(decode(b"\xe0", "cp-1251"), "а");
        assert_eq!(decode("õ".as_bytes(), "utf_8"), "õ");
        assert_eq!(decode(b"\xb1", "iso_8859_2"), "ą");
        assert_eq!(decode("õ".as_bytes(), "utf-8*en"), "õ");
    }

    #[test]
    fn unknown_charsets_are_utf8() {
        assert_eq!(decode("õ".as_bytes(), "x-unknown"), "õ");
        assert_eq!(decode(b"a\xffb", "x-unknown"), "a\u{fffd}b");
        // iso-2022-kr is the replacement encoding, which would lose everything
        assert_eq!(decode(b"abc", "iso-2022-kr"), "abc");
    }
}
