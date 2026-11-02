//! Mailbox names in modified UTF-7 (RFC 3501 section 5.1.3): printable ASCII as it is, `&` as
//! `&-`, anything else as `&` + modified base64 of UTF-16 + `-`. Servers without UTF8=ACCEPT
//! use it for names like "Sent Items" in other languages ("Saadetud kirjad" is plain, "Отправленные"
//! is not).

use base64::Engine;
use base64::alphabet::IMAP_MUTF7;
use base64::engine::general_purpose::{GeneralPurpose, NO_PAD};

const MUTF7: GeneralPurpose = GeneralPurpose::new(&IMAP_MUTF7, NO_PAD);

/// Whether a name needs encoding at all
pub fn needs_encoding(name: &str) -> bool {
    name.chars().any(|c| !(' '..='~').contains(&c) || c == '&')
}

pub fn encode(name: &str) -> String {
    let mut out = String::with_capacity(name.len());
    let mut pending: Vec<u16> = Vec::new();
    let flush = |out: &mut String, pending: &mut Vec<u16>| {
        if pending.is_empty() {
            return;
        }
        let bytes: Vec<u8> = pending.iter().flat_map(|unit| unit.to_be_bytes()).collect();
        out.push('&');
        out.push_str(&MUTF7.encode(bytes));
        out.push('-');
        pending.clear();
    };
    for c in name.chars() {
        if (' '..='~').contains(&c) {
            flush(&mut out, &mut pending);
            if c == '&' {
                out.push_str("&-");
            } else {
                out.push(c);
            }
        } else {
            let mut units = [0; 2];
            pending.extend_from_slice(c.encode_utf16(&mut units));
        }
    }
    flush(&mut out, &mut pending);
    out
}

/// Decodes a modified UTF-7 name. A name that is not valid modified UTF-7 is returned as it is:
/// some servers send UTF-8 names without UTF8=ACCEPT.
pub fn decode(name: &str) -> String {
    try_decode(name).unwrap_or_else(|| name.to_string())
}

fn try_decode(name: &str) -> Option<String> {
    let mut out = String::with_capacity(name.len());
    let mut rest = name;
    while let Some(start) = rest.find('&') {
        out.push_str(&rest[..start]);
        let after = &rest[start + 1..];
        let end = after.find('-')?;
        let encoded = &after[..end];
        if encoded.is_empty() {
            out.push('&');
        } else {
            let bytes = MUTF7.decode(encoded).ok()?;
            if bytes.len() % 2 != 0 {
                return None;
            }
            let units: Vec<u16> = bytes
                .chunks(2)
                .map(|pair| u16::from_be_bytes([pair[0], pair[1]]))
                .collect();
            out.push_str(&String::from_utf16(&units).ok()?);
        }
        rest = &after[end + 1..];
    }
    out.push_str(rest);
    Some(out)
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn round_trips() {
        for (plain, encoded) in [
            ("INBOX", "INBOX"),
            ("Tom & Jerry", "Tom &- Jerry"),
            ("Отправленные", "&BB4EQgQ,BEAEMAQyBDsENQQ9BD0ESwQ1-"),
            ("~peter/mail/台北/日本語", "~peter/mail/&U,BTFw-/&ZeVnLIqe-"),
            ("Šegregator/Społeczności", "&AWA-egregator/Spo&AUI-eczno&AVs-ci"),
            ("😀", "&2D3eAA-"),
        ] {
            assert_eq!(encode(plain), encoded, "{plain}");
            assert_eq!(decode(encoded), plain, "{encoded}");
        }
        assert!(needs_encoding("a&b") && needs_encoding("õ") && !needs_encoding("Sent Items"));
    }

    #[test]
    fn invalid_names_stay() {
        assert_eq!(decode("&"), "&");
        assert_eq!(decode("a&Zm9v"), "a&Zm9v");
        assert_eq!(decode("Õnn"), "Õnn");
        // a lone surrogate
        assert_eq!(decode("&2D0-"), "&2D0-");
    }
}
