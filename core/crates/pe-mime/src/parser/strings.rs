//! Decoding of text in messages, the way postal-mime (../postal-mime/src/decode-strings.ts) does
//! it. It differs from the libmime rules in [`crate::words`] in small ways that postal-mime has
//! reasons for: an unknown charset falls back to UTF-8 or Windows-1252, encoded words are joined
//! only when they can be, and a plain parameter wins over an RFC 2231 continuation of the same
//! name. The message parser follows postal-mime, the IMAP envelope follows imapflow.

use std::collections::BTreeMap;

use base64::Engine;
use base64::engine::general_purpose::STANDARD_NO_PAD;
use encoding_rs::{Encoding, UTF_16BE, UTF_16LE, WINDOWS_1252, X_USER_DEFINED};

pub(crate) fn is_wsp(c: u8) -> bool {
    c == b' ' || c == b'\t'
}

/// Charset names mail software uses that are not encoding labels
fn alias(normalized: &str) -> Option<&'static str> {
    Some(match normalized {
        "iso88598i" | "iso88598e" => "iso-8859-8",
        "shiftjis" | "windows31j" | "mskanji" => "shift_jis",
        "eucjp" => "euc-jp",
        "iso2022jp" | "iso2022jp1" | "iso2022jp2" | "junet" => "iso-2022-jp",
        "euckr" | "uhc" => "euc-kr",
        "tis620" => "windows-874",
        _ => return None,
    })
}

fn code_page(number: &str) -> Option<&'static str> {
    Some(match number {
        "932" => "shift_jis",
        "936" => "gbk",
        "949" => "euc-kr",
        "950" => "big5",
        "874" => "windows-874",
        "51932" => "euc-jp",
        "50220" | "50221" | "50222" => "iso-2022-jp",
        _ => return None,
    })
}

/// `x-ms-`, `x-` and `cs` prefixes and separators dropped: `x-Windows_1252` gives `windows1252`
fn normalize(charset: &str) -> String {
    let rest = ["x-ms-", "x-", "cs"]
        .iter()
        .find_map(|prefix| charset.strip_prefix(prefix))
        .unwrap_or(charset);
    rest.chars()
        .filter(|c| !c.is_whitespace() && !matches!(c, '.' | '_' | '-'))
        .collect()
}

/// The encoding of a charset, None when it is unknown. UTF-16 without a byte order is UTF-16LE,
/// [`decode_charset`] looks for a BOM first. UTF-16 only by its own name: the other WHATWG labels
/// of it ("unicode", "x-unicode", "ucs-2") go to the UTF-8 or Windows-1252 fallback, as in
/// postal-mime, so a part can not turn into UTF-16 markup by a charset name.
fn resolve(charset: &str) -> Option<&'static Encoding> {
    let label = charset.trim().to_ascii_lowercase();
    let label = if label.is_empty() { "utf8".to_string() } else { label };
    let encoding = resolve_label(&label)?;
    let utf16 = encoding == UTF_16LE || encoding == UTF_16BE;
    let named = ["utf-16", "utf16", "utf_16", "utf-16le", "utf-16be"].contains(&label.as_str());
    (!utf16 || named).then_some(encoding)
}

fn resolve_label(label: &str) -> Option<&'static Encoding> {
    if let Some(encoding) = Encoding::for_label(label.as_bytes()) {
        return Some(encoding);
    }
    let normalized = normalize(label);
    let digits = ["cp", "windows", "ms", "ibm"]
        .iter()
        .find_map(|prefix| normalized.strip_prefix(prefix))
        .filter(|rest| !rest.is_empty() && rest.bytes().all(|c| c.is_ascii_digit()));
    let name = digits
        .and_then(code_page)
        .or_else(|| alias(&normalized))
        .map_or(normalized.clone(), str::to_string);
    Encoding::for_label(name.as_bytes())
}

/// Bytes that are valid UTF-8 as UTF-8, anything else as Windows-1252
pub fn decode_utf8_or_windows1252(bytes: &[u8]) -> String {
    match std::str::from_utf8(bytes) {
        Ok(text) => text.strip_prefix('\u{feff}').unwrap_or(text).to_string(),
        Err(_) => WINDOWS_1252.decode_without_bom_handling(bytes).0.into_owned(),
    }
}

fn decode_with(encoding: &'static Encoding, bytes: &[u8]) -> String {
    encoding.decode_with_bom_removal(bytes).0.into_owned()
}

/// Bytes in a charset; an unknown charset is UTF-8, or Windows-1252 when they are not UTF-8
pub fn decode_charset(bytes: &[u8], charset: Option<&str>) -> String {
    let unordered_utf16 =
        charset.is_some_and(|c| ["utf-16", "utf16", "utf_16"].contains(&c.trim().to_ascii_lowercase().as_str()));
    if unordered_utf16 {
        let encoding = match bytes {
            [0xfe, 0xff, ..] => UTF_16BE,
            _ => UTF_16LE,
        };
        return decode_with(encoding, bytes);
    }
    match resolve(charset.unwrap_or("utf8")) {
        Some(encoding) if encoding == encoding_rs::REPLACEMENT => {
            if bytes.is_empty() {
                String::new()
            } else {
                "\u{fffd}".into()
            }
        }
        Some(encoding) => decode_with(encoding, bytes),
        None => decode_utf8_or_windows1252(bytes),
    }
}

/// The charset an HTML part declares in a `<meta>` tag in its first 1024 bytes
fn sniff_html_charset(bytes: &[u8]) -> Option<String> {
    let head = String::from_utf8_lossy(&bytes[..bytes.len().min(1024)]).to_lowercase();
    let mut pos = 0;
    while let Some(found) = head[pos..].find("<meta") {
        let start = pos + found;
        let end = head[start..].find('>').map_or(head.len(), |e| start + e);
        let tag = &head[start..end];
        if let Some(at) = tag.find("charset") {
            let rest = tag[at + 7..].trim_start();
            if let Some(rest) = rest.strip_prefix('=') {
                let rest = rest.trim_start().trim_start_matches(['"', '\'']).trim_start();
                let value: String = rest
                    .chars()
                    .take_while(|c| !c.is_whitespace() && !"\"';>".contains(*c))
                    .collect();
                if !value.is_empty() {
                    return Some(value);
                }
            }
        }
        pos = end;
    }
    None
}

/// The text of a body part: its charset, or what an HTML part declares, or UTF-8 or
/// Windows-1252
pub fn decode_text(bytes: &[u8], charset: Option<&str>, html: bool) -> String {
    if let Some(charset) = charset {
        return decode_charset(bytes, Some(charset));
    }
    let sniffed = if html {
        sniff_html_charset(bytes).and_then(|c| resolve(&c))
    } else {
        None
    };
    match sniffed {
        Some(encoding) if encoding == UTF_16LE || encoding == UTF_16BE => decode_utf8_or_windows1252(bytes),
        Some(encoding) if encoding == X_USER_DEFINED => decode_with(WINDOWS_1252, bytes),
        Some(encoding) => decode_with(encoding, bytes),
        None => decode_utf8_or_windows1252(bytes),
    }
}

/// Line breaks of a header value as spaces
pub fn fold_line_breaks(text: &str) -> String {
    let mut out = String::with_capacity(text.len());
    let mut in_break = false;
    for c in text.chars() {
        if c == '\r' || c == '\n' {
            if !in_break {
                out.push(' ');
            }
            in_break = true;
        } else {
            out.push(c);
            in_break = false;
        }
    }
    out
}

fn hex(c: u8) -> Option<u8> {
    (c as char).to_digit(16).map(|d| d as u8)
}

/// Base64 with whatever is not in the alphabet skipped, padding ending a group
pub(crate) fn decode_base64(text: &[u8]) -> Vec<u8> {
    let mut out = Vec::with_capacity(text.len() / 4 * 3);
    for piece in text.split(|c| *c == b'=') {
        let clean: Vec<u8> = piece
            .iter()
            .copied()
            .filter(|c| c.is_ascii_alphanumeric() || *c == b'+' || *c == b'/')
            .collect();
        let usable = clean.len() - usize::from(clean.len() % 4 == 1);
        out.extend(STANDARD_NO_PAD.decode(&clean[..usable]).unwrap_or_default());
    }
    out
}

fn decode_word(charset: &str, encoding: u8, text: &str) -> String {
    let charset = charset.split('*').next().unwrap_or("");
    let bytes = if encoding.eq_ignore_ascii_case(&b'Q') {
        // a soft line break inside the word, then '_' and white space as spaces
        let mut cleaned = String::with_capacity(text.len());
        let mut chars = text.chars().peekable();
        while let Some(c) = chars.next() {
            if c == '=' && chars.peek().is_some_and(|n| n.is_whitespace()) {
                let mut spaces = String::new();
                while let Some(&n) = chars.peek().filter(|n| n.is_whitespace()) {
                    spaces.push(n);
                    chars.next();
                }
                if chars.peek().is_some_and(char::is_ascii_hexdigit) {
                    cleaned.push('=');
                } else {
                    cleaned.push('=');
                    cleaned.push_str(&spaces);
                }
                continue;
            }
            cleaned.push(c);
        }
        let cleaned: String = cleaned
            .chars()
            .map(|c| if c == '_' || c.is_whitespace() { ' ' } else { c })
            .collect();
        let raw = cleaned.as_bytes();
        let mut out = Vec::with_capacity(raw.len());
        let mut i = 0;
        while i < raw.len() {
            if raw[i] == b'='
                && let (Some(h), Some(l)) = (
                    raw.get(i + 1).and_then(|c| hex(*c)),
                    raw.get(i + 2).and_then(|c| hex(*c)),
                )
            {
                out.push(h << 4 | l);
                i += 3;
                continue;
            }
            out.push(raw[i]);
            i += 1;
        }
        out
    } else {
        decode_base64(text.as_bytes())
    };
    fold_line_breaks(&decode_charset(&bytes, Some(charset)))
}

enum Piece<'a> {
    Text(&'a str),
    Word {
        charset: &'a str,
        encoding: u8,
        text: &'a str,
    },
}

/// `=?charset?Q?text?=`: the charset without white space, the text without `?`
fn split_words(value: &str) -> Vec<Piece<'_>> {
    let mut pieces = Vec::new();
    let mut pos = 0;
    let mut search = 0;
    while let Some(found) = value[search..].find("=?") {
        let start = search + found;
        let parsed = (|| {
            let rest = &value[start + 2..];
            let charset_end = rest.find('?')?;
            let charset = &rest[..charset_end];
            if charset.is_empty() || charset.chars().any(char::is_whitespace) {
                return None;
            }
            let rest = &rest[charset_end + 1..];
            let encoding = *rest.as_bytes().first()?;
            if !matches!(encoding, b'Q' | b'q' | b'B' | b'b') || rest.as_bytes().get(1) != Some(&b'?') {
                return None;
            }
            let text_end = rest[2..].find('?')?;
            if rest.as_bytes().get(2 + text_end + 1) != Some(&b'=') {
                return None;
            }
            let end = value.len() - rest[2 + text_end + 2..].len();
            Some((
                Piece::Word {
                    charset,
                    encoding,
                    text: &rest[2..2 + text_end],
                },
                end,
            ))
        })();
        match parsed {
            Some((word, end)) => {
                if start > pos {
                    pieces.push(Piece::Text(&value[pos..start]));
                }
                pieces.push(word);
                pos = end;
                search = end;
            }
            None => search = start + 1,
        }
    }
    if pos < value.len() {
        pieces.push(Piece::Text(&value[pos..]));
    }
    pieces
}

fn render(pieces: &[Piece<'_>], join: bool) -> String {
    struct Pending<'a> {
        charset: &'a str,
        encoding: u8,
        text: String,
        padded: bool,
    }
    let flush = |out: &mut String, pending: &mut Option<Pending<'_>>| {
        if let Some(word) = pending.take() {
            out.push_str(&decode_word(word.charset, word.encoding, &word.text));
        }
    };
    let mut out = String::new();
    let mut pending: Option<Pending<'_>> = None;
    for (i, piece) in pieces.iter().enumerate() {
        match piece {
            Piece::Text(text) => {
                let separator = !text.is_empty() && text.chars().all(|c| matches!(c, ' ' | '\t' | '\r' | '\n'));
                if pending.is_some() && separator && matches!(pieces.get(i + 1), Some(Piece::Word { .. })) {
                    continue;
                }
                flush(&mut out, &mut pending);
                out.push_str(text);
            }
            Piece::Word {
                charset,
                encoding,
                text,
            } => {
                let joins = pending.as_ref().is_some_and(|p| {
                    join && p.charset == *charset
                        && p.encoding.eq_ignore_ascii_case(encoding)
                        && (!encoding.eq_ignore_ascii_case(&b'B') || (p.text.len() % 4 == 0 && !p.padded))
                });
                if joins {
                    let word = pending.as_mut().expect("pending word");
                    word.text.push_str(text);
                    word.padded = text.ends_with('=');
                    continue;
                }
                flush(&mut out, &mut pending);
                pending = Some(Pending {
                    charset,
                    encoding: *encoding,
                    text: text.to_string(),
                    padded: text.ends_with('='),
                });
            }
        }
    }
    flush(&mut out, &mut pending);
    out
}

/// Decodes the encoded words of a header value. Adjacent words are joined before decoding,
/// unless that breaks a character; then each is decoded on its own.
pub fn decode_words(value: &str) -> String {
    let pieces = split_words(value);
    let joined = render(&pieces, true);
    if joined.contains('\u{fffd}') {
        render(&pieces, false)
    } else {
        joined
    }
}

/// Whether a value is only encoded words, with white space between them
pub fn is_encoded_words_only(value: &str) -> bool {
    let pieces = split_words(value);
    !pieces.is_empty()
        && matches!(pieces.first(), Some(Piece::Word { .. }))
        && pieces.iter().all(|p| match p {
            Piece::Word { .. } => true,
            Piece::Text(text) => text.chars().all(char::is_whitespace),
        })
}

/// %XX escapes as bytes in `charset`; other characters as their UTF-8
fn decode_percent(value: &str, charset: Option<&str>) -> String {
    let raw = value.as_bytes();
    let mut out = Vec::with_capacity(raw.len());
    let mut i = 0;
    while i < raw.len() {
        if raw[i] == b'%'
            && let (Some(h), Some(l)) = (
                raw.get(i + 1).and_then(|c| hex(*c)),
                raw.get(i + 2).and_then(|c| hex(*c)),
            )
        {
            out.push(h << 4 | l);
            i += 3;
            continue;
        }
        out.push(raw[i]);
        i += 1;
    }
    decode_charset(&out, Some(charset.unwrap_or("utf-8")))
}

/// Joins RFC 2231 continuations (`name*0*`, `name*1`) into one decoded parameter. A plain
/// parameter of the same name wins.
pub fn decode_continuations(params: &mut BTreeMap<String, String>) {
    struct Part {
        number: u32,
        value: String,
        encoded: bool,
    }
    let mut continued: BTreeMap<String, (Option<String>, Vec<Part>)> = BTreeMap::new();
    let keys: Vec<String> = params.keys().filter(|k| k.contains('*')).cloned().collect();
    for key in keys {
        let Some((base, number, encoded)) = split_key(&key) else {
            continue;
        };
        let mut value = params.remove(&key).unwrap_or_default();
        let entry = continued.entry(base.to_ascii_lowercase()).or_default();
        if number == 0 && encoded {
            let mut fields = value.splitn(3, '\'');
            if let (Some(charset), Some(_), Some(rest)) = (fields.next(), fields.next(), fields.next()) {
                entry.0 = Some(if charset.is_empty() {
                    "utf-8".into()
                } else {
                    charset.to_string()
                });
                value = rest.to_string();
            }
        }
        entry.1.push(Part { number, value, encoded });
    }
    for (name, (charset, mut parts)) in continued {
        if params.contains_key(&name) {
            continue;
        }
        parts.sort_by_key(|p| p.number);
        let mut result = String::new();
        let mut pending = String::new();
        for part in parts {
            if part.encoded {
                pending.push_str(&part.value);
                continue;
            }
            if !pending.is_empty() {
                result.push_str(&decode_percent(&std::mem::take(&mut pending), charset.as_deref()));
            }
            result.push_str(&part.value);
        }
        if !pending.is_empty() {
            result.push_str(&decode_percent(&pending, charset.as_deref()));
        }
        params.insert(name, result);
    }
}

/// `name*`, `name*2`, `name*2*`: the name, the part number and whether it is encoded
fn split_key(key: &str) -> Option<(&str, u32, bool)> {
    let (rest, encoded) = match key.strip_suffix('*') {
        Some(rest) => (rest, true),
        None => (key, false),
    };
    let digits = rest.len() - rest.trim_end_matches(|c: char| c.is_ascii_digit()).len();
    if digits > 0 {
        let base = rest[..rest.len() - digits].strip_suffix('*')?;
        return Some((base, rest[rest.len() - digits..].parse().unwrap_or(0), encoded));
    }
    encoded.then_some((rest, 0, true))
}

/// UTF-8 as Windows-1252 cannot read it: for header lines, which are not decoded as a whole
pub(crate) fn decode_header_line(bytes: &[u8]) -> String {
    match std::str::from_utf8(bytes) {
        Ok(text) => text.to_string(),
        Err(_) => WINDOWS_1252.decode_without_bom_handling(bytes).0.into_owned(),
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn charsets() {
        assert_eq!(decode_charset(b"\xe4", Some("x-Windows_1252")), "ä");
        assert_eq!(decode_charset(b"\x82\xa0", Some("cp932")), "あ");
        assert_eq!(decode_charset(b"\xff\xfea\x00", Some("utf-16")), "a");
        assert_eq!(decode_charset(b"\xfe\xff\x00a", Some("utf-16")), "a");
        assert_eq!(decode_charset(b"\xe4", Some("unknown")), "ä");
        assert_eq!(decode_charset("õ".as_bytes(), Some("unknown")), "õ");
        assert_eq!(decode_charset(b"x", Some("iso-2022-kr")), "\u{fffd}");
    }

    #[test]
    fn html_charset_is_sniffed() {
        let html = b"<html><head><meta charset=\"iso-8859-1\"></head><body>\xe4</body></html>";
        assert!(decode_text(html, None, true).contains('ä'));
        let html = b"<meta http-equiv=\"Content-Type\" content=\"text/html; charset=koi8-r\">\xd0";
        assert!(decode_text(html, None, true).ends_with('п'));
    }

    #[test]
    fn words_and_continuations() {
        assert_eq!(decode_words("=?UTF-8?Q?a?= =?UTF-8?Q?b?="), "ab");
        assert_eq!(decode_words("=?UTF-8?B?w6E=?= =?UTF-8?B?w6k=?="), "áé");
        assert!(is_encoded_words_only("=?UTF-8?Q?a?=  =?UTF-8?Q?b?="));
        assert!(!is_encoded_words_only("x =?UTF-8?Q?a?="));
        let mut params = BTreeMap::from([
            ("name*0*".to_string(), "utf-8''J%C3%B5".to_string()),
            ("name*1".to_string(), "ul".to_string()),
            ("file*".to_string(), "x".to_string()),
            ("file".to_string(), "plain wins".to_string()),
        ]);
        decode_continuations(&mut params);
        assert_eq!(params["name"], "Jõul");
        assert_eq!(params["file"], "plain wins");
        assert_eq!(params.len(), 2);
    }
}
