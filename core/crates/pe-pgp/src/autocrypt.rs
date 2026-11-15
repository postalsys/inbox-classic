//! The `Autocrypt` header (Autocrypt Level 1, section 2.1): a sender's key carried in every message they send.

use base64::Engine;
use base64::engine::general_purpose::STANDARD;

use crate::MAX_CERT_BYTES;

/// An `Autocrypt` header, read.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct Header {
    /// The address the key is for, lower case. The caller checks it against the message's From.
    pub addr: String,
    /// `prefer-encrypt=mutual`.
    pub mutual: bool,
    /// The key, binary.
    pub keydata: Vec<u8>,
}

/// Reads a header's value. `None` when it breaks the specification: no `addr` or `keydata`, an attribute it does not
/// know that does not start with `_`, or key data that is not base64 or too large.
pub fn parse(value: &str) -> Option<Header> {
    let mut addr = None;
    let mut mutual = false;
    let mut keydata = None;
    for attribute in value.split(';') {
        let attribute = attribute.trim();
        if attribute.is_empty() {
            continue;
        }
        let (name, value) = attribute.split_once('=')?;
        match name.trim().to_ascii_lowercase().as_str() {
            "addr" if addr.is_none() => addr = Some(value.trim().to_lowercase()),
            "prefer-encrypt" => mutual = value.trim() == "mutual",
            "keydata" if keydata.is_none() => {
                let compact: String = value.chars().filter(|c| !c.is_whitespace()).collect();
                if compact.len() > MAX_CERT_BYTES * 4 / 3 + 4 {
                    return None;
                }
                keydata = Some(STANDARD.decode(compact).ok()?);
            }
            other if other.starts_with('_') => {}
            _ => return None,
        }
    }
    let addr = addr.filter(|a| crate::address_of(a).as_deref() == Some(a.as_str()))?;
    Some(Header {
        addr,
        mutual,
        keydata: keydata.filter(|k| !k.is_empty())?,
    })
}

/// A header's value for `addr` with the binary key `keydata`, the key data broken into lines of 76 characters with
/// spaces between them, where the header can be folded.
pub fn build(addr: &str, keydata: &[u8], mutual: bool) -> String {
    let encoded = STANDARD.encode(keydata);
    let lines: Vec<&str> = encoded
        .as_bytes()
        .chunks(76)
        .map(|chunk| std::str::from_utf8(chunk).unwrap_or_default())
        .collect();
    let prefer = if mutual { " prefer-encrypt=mutual;" } else { "" };
    format!("addr={addr};{prefer} keydata={}", lines.join(" "))
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn reads_the_header() {
        let header = parse("addr=Alice@Example.org; prefer-encrypt=mutual; keydata=AQID BAU=").unwrap();
        assert_eq!(header.addr, "alice@example.org");
        assert!(header.mutual);
        assert_eq!(header.keydata, [1, 2, 3, 4, 5]);
    }

    #[test]
    fn unknown_critical_attributes_void_it() {
        assert!(parse("addr=a@example.org; keydata=AQID; colour=blue").is_none());
        assert!(parse("addr=a@example.org; _colour=blue; keydata=AQID").is_some());
    }

    #[test]
    fn needs_addr_and_keydata() {
        assert!(parse("keydata=AQID").is_none());
        assert!(parse("addr=a@example.org").is_none());
        assert!(parse("addr=not an address; keydata=AQID").is_none());
        assert!(parse("addr=a@example.org; keydata=!!!").is_none());
    }

    #[test]
    fn builds_what_it_reads() {
        let key: Vec<u8> = (0..200u8).collect();
        let value = build("bob@example.net", &key, false);
        assert!(!value.contains("prefer-encrypt"));
        let header = parse(&value).unwrap();
        assert_eq!((header.addr.as_str(), header.keydata), ("bob@example.net", key));
    }
}
