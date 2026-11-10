//! The OTP-Token header of draft-goto-otp-token-01, a port of postal-mime's src/otp-token.ts.
//!
//! The draft expires on 25 March 2027. By then check for a newer revision or a published RFC: the
//! header name and its parameters are still open questions in the draft.
//!
//! The header value is a structured field item (RFC 9651): a String holding the passcode, with an
//! `origin` parameter naming the origin the passcode is bound to. Unknown parameters are ignored,
//! but they still have to be valid, otherwise the whole field fails to parse.

use std::collections::HashMap;
use std::sync::LazyLock;

use regex::Regex;

use crate::parser::Header;

/// RFC 9651 lets a parser limit the size of a field. A passcode and an origin take well under a
/// kilobyte. Counted in UTF-16 code units, as postal-mime counts.
const MAX_FIELD_LENGTH: usize = 8192;

/// A one-time passcode from the OTP-Token header, so that a mail client can offer it for the
/// origin it is bound to. The header is set by the sender and not authenticated: check that the
/// message is signed by the domain of the origin before trusting it.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct OtpToken {
    /// The passcode, printable ASCII
    pub code: String,
    /// Canonical ASCII serialization of the origin the code is bound to, eg. `https://example.com`.
    /// The draft requires it, so a header without one gives no token at all.
    pub origin: String,
}

/// A parameter value: a String, or any other valid bare item.
#[derive(Debug, Clone, PartialEq, Eq)]
pub enum Param {
    String(String),
    Other,
}

/// A structured field item whose bare item is a String, with its parameters.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct StringItem {
    pub value: String,
    /// In the order of their first appearance; a later parameter with the same key replaces the value
    pub params: Vec<(String, Param)>,
}

struct Cursor<'a> {
    input: &'a [u8],
    pos: usize,
}

impl Cursor<'_> {
    fn peek(&self) -> Option<u8> {
        self.input.get(self.pos).copied()
    }

    fn at(&self, offset: usize) -> Option<u8> {
        self.input.get(self.pos + offset).copied()
    }

    /// The length of the run of bytes from `from` that pass `accept`.
    fn run(&self, from: usize, accept: impl Fn(u8) -> bool) -> usize {
        self.input[from.min(self.input.len())..]
            .iter()
            .take_while(|&&b| accept(b))
            .count()
    }

    fn spaces(&mut self) {
        self.pos += self.run(self.pos, |b| b == b' ');
    }
}

fn is_token_char(b: u8) -> bool {
    b.is_ascii_alphanumeric() || b"!#$%&'*+-.^_`|~:/".contains(&b)
}

fn is_key_char(b: u8) -> bool {
    b.is_ascii_lowercase() || b.is_ascii_digit() || b"_-.*".contains(&b)
}

/// RFC 9651 4.2.5, the unescaped String at the cursor, or None if there is no valid String there.
fn parse_string(cursor: &mut Cursor) -> Option<String> {
    if cursor.peek() != Some(b'"') {
        return None;
    }
    let mut out = String::new();
    let mut at = cursor.pos + 1;
    loop {
        match *cursor.input.get(at)? {
            b'"' => {
                cursor.pos = at + 1;
                return Some(out);
            }
            b'\\' => match *cursor.input.get(at + 1)? {
                escaped @ (b'"' | b'\\') => {
                    out.push(escaped as char);
                    at += 2;
                }
                _ => return None,
            },
            b @ 0x20..=0x7e => {
                out.push(b as char);
                at += 1;
            }
            _ => return None,
        }
    }
}

/// `-?(?:\d{1,12}\.\d{1,3}|\d{1,15})`: an Integer or a Decimal. Whatever follows is left for the
/// caller, which only accepts a parameter separator or the end, so a 16th digit fails there.
fn parse_number(cursor: &mut Cursor) -> bool {
    let start = cursor.pos + usize::from(cursor.peek() == Some(b'-'));
    let digits = cursor.run(start, |b| b.is_ascii_digit());
    if (1..=12).contains(&digits) && cursor.input.get(start + digits) == Some(&b'.') {
        let fraction = cursor.run(start + digits + 1, |b| b.is_ascii_digit());
        if fraction > 0 {
            cursor.pos = start + digits + 1 + fraction.min(3);
            return true;
        }
    }
    if digits == 0 {
        return false;
    }
    cursor.pos = start + digits.min(15);
    true
}

fn parse_token(cursor: &mut Cursor) -> bool {
    match cursor.peek() {
        Some(b) if b.is_ascii_alphabetic() || b == b'*' => {
            cursor.pos += 1 + cursor.run(cursor.pos + 1, is_token_char);
            true
        }
        _ => false,
    }
}

fn parse_byte_sequence(cursor: &mut Cursor) -> bool {
    let len = cursor.run(cursor.pos + 1, |b| b.is_ascii_alphanumeric() || b"+/=".contains(&b));
    if cursor.at(1 + len) != Some(b':') {
        return false;
    }
    cursor.pos += len + 2;
    true
}

fn parse_boolean(cursor: &mut Cursor) -> bool {
    if matches!(cursor.at(1), Some(b'0' | b'1')) {
        cursor.pos += 2;
        return true;
    }
    false
}

fn parse_date(cursor: &mut Cursor) -> bool {
    let start = cursor.pos + 1 + usize::from(cursor.at(1) == Some(b'-'));
    let digits = cursor.run(start, |b| b.is_ascii_digit());
    if digits == 0 {
        return false;
    }
    cursor.pos = start + digits.min(15);
    true
}

/// RFC 9651 4.2.10. The percent encoded bytes must be valid UTF-8.
fn parse_display_string(cursor: &mut Cursor) -> bool {
    if cursor.at(1) != Some(b'"') {
        return false;
    }
    let mut bytes = Vec::new();
    let mut at = cursor.pos + 2;
    let lower_hex = |b: u8| b.is_ascii_digit() || (b'a'..=b'f').contains(&b);
    loop {
        match cursor.input.get(at) {
            Some(b'"') => break,
            Some(b'%') => {
                let (Some(&high), Some(&low)) = (cursor.input.get(at + 1), cursor.input.get(at + 2)) else {
                    return false;
                };
                if !lower_hex(high) || !lower_hex(low) {
                    return false;
                }
                let hex = |b: u8| if b.is_ascii_digit() { b - b'0' } else { b - b'a' + 10 };
                bytes.push(hex(high) << 4 | hex(low));
                at += 3;
            }
            Some(&b) if (0x20..=0x7e).contains(&b) => {
                bytes.push(b);
                at += 1;
            }
            _ => return false,
        }
    }
    cursor.pos = at + 1;
    std::str::from_utf8(&bytes).is_ok()
}

/// RFC 9651 4.2.3.1: the value of a String, `Other` for any other valid bare item, None for an
/// invalid one.
fn parse_bare_item(cursor: &mut Cursor) -> Option<Param> {
    let valid = match cursor.peek() {
        Some(b'"') => return parse_string(cursor).map(Param::String),
        Some(b':') => parse_byte_sequence(cursor),
        Some(b'?') => parse_boolean(cursor),
        Some(b'@') => parse_date(cursor),
        Some(b'%') => parse_display_string(cursor),
        Some(b'-' | b'0'..=b'9') => parse_number(cursor),
        _ => parse_token(cursor),
    };
    valid.then_some(Param::Other)
}

/// Parses a structured field item (RFC 9651 4.2 with field_type "item") whose bare item is a
/// String. None if the value does not parse or the bare item is of another type.
pub fn parse_string_item(value: &str) -> Option<StringItem> {
    let mut cursor = Cursor {
        input: value.as_bytes(),
        pos: 0,
    };
    cursor.spaces();
    let item = parse_string(&mut cursor)?;

    let mut params: Vec<(String, Param)> = Vec::new();
    let mut index: HashMap<String, usize> = HashMap::new();
    while cursor.peek() == Some(b';') {
        cursor.pos += 1;
        cursor.spaces();
        let start = cursor.pos;
        match cursor.peek() {
            Some(b) if b.is_ascii_lowercase() || b == b'*' => {
                cursor.pos += 1 + cursor.run(cursor.pos + 1, is_key_char);
            }
            _ => return None,
        }
        let key = value[start..cursor.pos].to_string();
        let param = if cursor.peek() == Some(b'=') {
            cursor.pos += 1;
            parse_bare_item(&mut cursor)?
        } else {
            Param::Other
        };
        match index.get(&key) {
            Some(&at) => params[at].1 = param,
            None => {
                index.insert(key.clone(), params.len());
                params.push((key, param));
            }
        }
    }

    cursor.spaces();
    (cursor.pos == cursor.input.len()).then_some(StringItem { value: item, params })
}

static HOSTNAME: LazyLock<Regex> =
    LazyLock::new(|| Regex::new(r"^([a-z0-9_-]+\.)*[a-z0-9_-]+$|^\[[0-9a-f:.]+\]$").expect("valid"));
static LOOPBACK: LazyLock<Regex> =
    LazyLock::new(|| Regex::new(r"^(localhost|.+\.localhost|127(\.[0-9]+){3}|\[::1\])$").expect("valid"));

/// Whether the origin is the canonical ASCII serialization of a potentially trustworthy origin, as
/// the draft requires: https, or http on a loopback host.
pub fn is_otp_origin(origin: &str) -> bool {
    let Ok(url) = url::Url::parse(origin) else {
        return false;
    };
    // The URL parser lowercases the host, converts it to punycode and drops the default port, so a
    // value that is not canonical, or has a path, userinfo or an opaque origin, does not match its
    // own origin. The WHATWG parser lets characters such as a quote or a brace into a host, which
    // the origin grammar (RFC 6454) does not allow, so only a DNS name, an IPv4 address or a
    // bracketed IPv6 address is accepted.
    let host = url.host_str().unwrap_or("");
    if url.origin().ascii_serialization() != origin || !HOSTNAME.is_match(host) {
        return false;
    }
    url.scheme() == "https" || (url.scheme() == "http" && LOOPBACK.is_match(host))
}

/// The one-time passcode from the OTP-Token header of a message, following the receiver steps of
/// the draft (section 3.2), or None if the message has no valid one. Pass the headers of the
/// message itself: the draft has an OTP-Token of a MIME part ignored. More than one OTP-Token
/// header makes the message have none.
pub fn otp_token(headers: &[Header]) -> Option<OtpToken> {
    let mut found = headers.iter().filter(|h| h.key == "otp-token");
    let header = found.next()?;
    if found.next().is_some() {
        return None;
    }
    if header.value.len() > MAX_FIELD_LENGTH && header.value.encode_utf16().count() > MAX_FIELD_LENGTH {
        return None;
    }
    // The header value is already unfolded, which the draft requires before the structured field parse
    let parsed = parse_string_item(&header.value)?;
    let origin = parsed.params.iter().find(|(key, _)| key == "origin").map(|(_, p)| p);
    // An empty passcode is valid syntax, but there is nothing in it to fill in
    match origin {
        Some(Param::String(origin)) if !parsed.value.is_empty() && is_otp_origin(origin) => Some(OtpToken {
            code: parsed.value,
            origin: origin.clone(),
        }),
        _ => None,
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn accepts_canonical_potentially_trustworthy_origins() {
        for origin in [
            "https://example.com",
            "https://sub.example.com:8443",
            "https://xn--bcher-kva.example",
            "https://192.0.2.1",
            "https://[2001:db8::1]",
            "http://localhost",
            "http://localhost:3000",
            "http://app.localhost",
            "http://127.0.0.1:8080",
            "http://[::1]",
        ] {
            assert!(is_otp_origin(origin), "{origin}");
        }
    }

    #[test]
    fn rejects_non_canonical_or_untrustworthy_origins() {
        for origin in [
            "",
            "null",
            "example.com",
            "http://example.com",
            "ftp://example.com",
            "wss://example.com",
            "HTTPS://example.com",
            "https://Example.com",
            "https://example.com/",
            "https://example.com/path",
            "https://example.com:443",
            "http://localhost:80",
            "https://example.com:0443",
            "https://user@example.com",
            "https://bücher.example",
            "https://[2001:DB8::1]",
            "https://[2001:db8:0::1]",
            "https://01.2.3.4",
            "https://example.com:99999",
            "https://exa\"mple.com",
            "https://example.com.",
        ] {
            assert!(!is_otp_origin(origin), "{origin}");
        }
    }

    #[test]
    fn parse_string_item_reads_parameters() {
        let item = parse_string_item(r#""x";  a="1";b;c=2"#).unwrap();
        assert_eq!(item.value, "x");
        assert_eq!(
            item.params,
            vec![
                ("a".to_string(), Param::String("1".into())),
                ("b".to_string(), Param::Other),
                ("c".to_string(), Param::Other),
            ]
        );
    }

    #[test]
    fn a_repeated_parameter_keeps_its_place_and_takes_the_last_value() {
        let item = parse_string_item(r#""x"; a="1"; b; a="2""#).unwrap();
        assert_eq!(
            item.params,
            vec![
                ("a".to_string(), Param::String("2".into())),
                ("b".to_string(), Param::Other),
            ]
        );
    }
}
