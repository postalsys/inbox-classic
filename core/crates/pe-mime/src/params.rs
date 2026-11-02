//! Parameters of a structured header value, `filename*0*=utf-8''J%C3%B5ul; filename*1=.txt`:
//! RFC 2231 continuations and charsets joined and decoded, encoded words (RFC 2047) decoded too,
//! as senders use both. A port of imapflow's `getStructuredParams`.

use std::collections::BTreeMap;

use crate::charset;
use crate::words::decode_words;

struct Continuation {
    charset: Option<String>,
    parts: Vec<(u32, String)>,
}

/// Decodes `(name, value)` pairs into a map from the lowercase name to the decoded value
pub fn decode_params<'a>(pairs: impl IntoIterator<Item = (&'a str, &'a str)>) -> BTreeMap<String, String> {
    let mut plain = BTreeMap::new();
    for (name, value) in pairs {
        plain.insert(name.to_ascii_lowercase(), decode_words(value));
    }
    fix_unmarked_filename(&mut plain);

    let mut out = BTreeMap::new();
    let mut continued: BTreeMap<String, Continuation> = BTreeMap::new();
    for (name, value) in plain {
        let Some((base, number, extended)) = split_continuation(&name) else {
            out.insert(name, value);
            continue;
        };
        let entry = continued.entry(base.to_string()).or_insert(Continuation {
            charset: None,
            parts: Vec::new(),
        });
        let mut value = value;
        // the first extended part carries the charset and language: utf-8'en'J%C3%B5ul
        if number == 0 && extended {
            let mut fields = value.splitn(3, '\'');
            if let (Some(charset), Some(_language), Some(rest)) = (fields.next(), fields.next(), fields.next()) {
                entry.charset = Some(if charset.is_empty() {
                    "utf-8".into()
                } else {
                    charset.into()
                });
                value = rest.to_string();
            }
        }
        entry.parts.push((number, value));
    }

    for (name, mut continuation) in continued {
        continuation.parts.sort_by_key(|(number, _)| *number);
        let joined: String = continuation.parts.into_iter().map(|(_, value)| value).collect();
        let value = match continuation.charset {
            Some(name) => charset::decode(&percent_decode(&joined), &name),
            None => decode_words(&joined),
        };
        // a continued parameter wins over a plain one of the same name
        out.insert(name, value);
    }
    out
}

/// `name*`, `name*0`, `name*0*`: the base name, the part number and whether the value is extended
fn split_continuation(name: &str) -> Option<(&str, u32, bool)> {
    let (rest, extended) = match name.strip_suffix('*') {
        Some(rest) => (rest, true),
        None => (name, false),
    };
    let digits = rest.len() - rest.trim_end_matches(|c: char| c.is_ascii_digit()).len();
    let base = &rest[..rest.len() - digits];
    if digits > 0 {
        let base = base.strip_suffix('*')?;
        let number = rest[rest.len() - digits..].parse().ok()?;
        return Some((base, number, extended));
    }
    // "name*" alone
    extended.then_some((rest, 0, true))
}

/// Some senders put an RFC 2231 value in a plain `filename`, `utf-8''J%C3%B5ul.txt`
fn fix_unmarked_filename(params: &mut BTreeMap<String, String>) {
    let Some(filename) = params.get("filename") else { return };
    if params.contains_key("filename*") {
        return;
    }
    let mut fields = filename.splitn(3, '\'');
    let (Some(charset), Some(language), Some(value)) = (fields.next(), fields.next(), fields.next()) else {
        return;
    };
    let looks_encoded = !charset.is_empty()
        && charset
            .bytes()
            .all(|c| c.is_ascii_lowercase() || c.is_ascii_digit() || c == b'-' || c == b'_')
        && language.bytes().all(|c| c.is_ascii_lowercase())
        && !value.is_empty()
        && value
            .bytes()
            .all(|c| c.is_ascii() && c != b'\'' && (c >= 0x20 || c == b'\t' || c == b'\n' || c == b'\r'));
    if looks_encoded && charset::encoding_for(charset).is_some() {
        let value = format!("{charset}''{value}");
        params.insert("filename*".into(), value);
    }
}

/// %XX escapes to bytes, anything else as it is. A broken escape keeps its text with `=` for `%`,
/// as imapflow decodes the value as quoted-printable.
fn percent_decode(value: &str) -> Vec<u8> {
    let bytes = value.as_bytes();
    let mut out = Vec::with_capacity(bytes.len());
    let mut i = 0;
    while i < bytes.len() {
        let hex = |c: Option<&u8>| c.and_then(|c| (*c as char).to_digit(16));
        if bytes[i] == b'%'
            && let (Some(high), Some(low)) = (hex(bytes.get(i + 1)), hex(bytes.get(i + 2)))
        {
            out.push((high * 16 + low) as u8);
            i += 3;
            continue;
        }
        out.push(if bytes[i] == b'%' { b'=' } else { bytes[i] });
        i += 1;
    }
    out
}

#[cfg(test)]
mod tests {
    use super::*;

    fn params(pairs: &[(&str, &str)]) -> BTreeMap<String, String> {
        decode_params(pairs.iter().copied())
    }

    #[test]
    fn plain_and_encoded_words() {
        let out = params(&[("CHARSET", "utf-8"), ("name", "=?UTF-8?Q?J=C3=B5ul.txt?=")]);
        assert_eq!(out["charset"], "utf-8");
        assert_eq!(out["name"], "Jõul.txt");
    }

    #[test]
    fn continuations_with_charset() {
        let out = params(&[
            ("filename*1", ".txt"),
            ("filename*0*", "utf-8'et'J%C3%B5ul"),
            ("title*", "iso-8859-1''%F5%E4"),
            ("note*0", "a "),
            ("note*1", "b"),
        ]);
        assert_eq!(out["filename"], "Jõul.txt");
        assert_eq!(out["title"], "õä");
        assert_eq!(out["note"], "a b");
        assert!(!out.contains_key("filename*1"));
    }

    #[test]
    fn extended_value_wins_and_unmarked_filenames() {
        let out = params(&[("filename", "fallback.txt"), ("filename*", "utf-8''%C3%B5.txt")]);
        assert_eq!(out["filename"], "õ.txt");
        let out = params(&[("filename", "utf-8''J%C3%B5ul.txt")]);
        assert_eq!(out["filename"], "Jõul.txt");
        // not an RFC 2231 value
        let out = params(&[("filename", "it's a file's name")]);
        assert_eq!(out["filename"], "it's a file's name");
        // an empty charset is UTF-8, a broken escape stays
        let out = params(&[("x*", "''%C3%B5%Z1")]);
        assert_eq!(out["x"], "õ=Z1");
    }

    #[test]
    fn splits_names() {
        assert_eq!(split_continuation("filename"), None);
        assert_eq!(split_continuation("filename*"), Some(("filename", 0, true)));
        assert_eq!(split_continuation("filename*12"), Some(("filename", 12, false)));
        assert_eq!(split_continuation("filename*2*"), Some(("filename", 2, true)));
        assert_eq!(split_continuation("v2"), None);
    }
}
