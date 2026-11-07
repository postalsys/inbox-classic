//! Header blocks the way EmailEngine decodes them (libmime's `decodeHeaders` behind
//! `lib/utils/decode-headers.js`): lowercase names, every value of a name in order, values unfolded
//! and trimmed but not decoded.

use std::collections::HashMap;

use crate::js;

/// The largest header block decoded. libmime's unfolding was once quadratic, and the blocks come
/// from parts any sender writes, so EmailEngine cuts them first; no real header block is near this
pub const MAX_HEADER_BLOCK_SIZE: usize = 64 * 1024;

/// Header names in their order, each with its values
#[derive(Debug, Clone, Default, PartialEq, Eq)]
pub struct Headers {
    entries: Vec<(String, Vec<String>)>,
    /// The position of each name in `entries`
    index: HashMap<String, usize>,
}

impl Headers {
    /// The values of a lowercase name
    pub fn get(&self, key: &str) -> Option<&[String]> {
        self.index.get(key).map(|i| self.entries[*i].1.as_slice())
    }

    /// The first value of a lowercase name
    pub fn first(&self, key: &str) -> Option<&str> {
        self.get(key).and_then(|v| v.first()).map(String::as_str)
    }

    pub fn push(&mut self, key: &str, value: String) {
        // EmailEngine drops these two: they name members of every JavaScript object. Nothing here
        // is an object, but leaving them out keeps the result the same as EmailEngine's
        if key == "__proto__" || key == "constructor" {
            return;
        }
        match self.index.get(key) {
            Some(i) => self.entries[*i].1.push(value),
            None => {
                self.index.insert(key.to_string(), self.entries.len());
                self.entries.push((key.to_string(), vec![value]));
            }
        }
    }

    /// The names in their order, each with its values
    pub fn iter(&self) -> impl Iterator<Item = (&str, &[String])> {
        self.entries.iter().map(|(k, v)| (k.as_str(), v.as_slice()))
    }

    pub fn is_empty(&self) -> bool {
        self.entries.is_empty()
    }

    /// Whether some header has a name, as a block of nothing but a continuation line has not
    pub fn has_named(&self) -> bool {
        self.entries.iter().any(|(k, _)| !k.is_empty())
    }
}

/// A header block from a part's bytes, cut to [`MAX_HEADER_BLOCK_SIZE`] bytes first
pub fn cap_bytes(content: &[u8]) -> String {
    String::from_utf8_lossy(&content[..content.len().min(MAX_HEADER_BLOCK_SIZE)]).into_owned()
}

/// A header block from text, cut to [`MAX_HEADER_BLOCK_SIZE`] UTF-16 code units first
pub fn cap_str(content: &str) -> &str {
    js::truncate_utf16(content, MAX_HEADER_BLOCK_SIZE)
}

/// Splits text into lines at \r\n, \n or \r
pub fn lines(text: &str) -> Vec<&str> {
    let mut out = Vec::new();
    let mut start = 0;
    let bytes = text.as_bytes();
    let mut i = 0;
    while i < bytes.len() {
        match bytes[i] {
            b'\n' => {
                out.push(&text[start..i]);
                start = i + 1;
            }
            b'\r' => {
                out.push(&text[start..i]);
                if bytes.get(i + 1) == Some(&b'\n') {
                    i += 1;
                }
                start = i + 1;
            }
            _ => {}
        }
        i += 1;
    }
    out.push(&text[start..]);
    out
}

/// Decodes a header block, which ends at its first empty line. The caller caps its size
pub fn decode(block: &str) -> Headers {
    let all = lines(block);
    let start = all.iter().position(|l| !l.is_empty()).unwrap_or(all.len());
    let end = all[start..]
        .iter()
        .position(|l| l.is_empty())
        .map_or(all.len(), |p| start + p);
    let mut unfolded: Vec<String> = Vec::new();
    for line in &all[start..end] {
        match unfolded.last_mut() {
            Some(last) if line.starts_with([' ', '\t']) => {
                last.push_str("\r\n");
                last.push_str(line);
            }
            _ => unfolded.push(line.to_string()),
        }
    }
    let mut headers = Headers::default();
    for line in unfolded {
        let (key, value) = decode_line(&line);
        headers.push(&key, value);
    }
    headers
}

/// One unfolded header line as a lowercase name and its value
fn decode_line(line: &str) -> (String, String) {
    let mut joined = String::with_capacity(line.len());
    let mut rest = line;
    while let Some(pos) = rest.find(['\r', '\n']) {
        joined.push_str(&rest[..pos]);
        joined.push(' ');
        let mut after = &rest[pos..];
        after = after.strip_prefix('\r').unwrap_or(after);
        after = after.strip_prefix('\n').unwrap_or(after);
        rest = after.trim_start_matches([' ', '\t']);
    }
    joined.push_str(rest);
    let line = js::trim(&joined);
    // /^\s*([^:]+):(.*)$/: a name of at least one character before the first colon, and a value
    // the `.` can run to the end of
    match line.split_once(':') {
        Some((key, value)) if !key.is_empty() && !value.contains(['\u{2028}', '\u{2029}']) => {
            (js::trim(key).to_lowercase(), js::trim(value).to_string())
        }
        _ => (String::new(), String::new()),
    }
}

/// Splits the address type off a DSN value, `rfc822; user@example.com`
pub fn split_address_type(value: &str) -> (Option<&str>, &str) {
    match value.split_once(';') {
        Some((label, value)) => (Some(js::trim(label)), js::trim(value)),
        None => (None, js::trim(value)),
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn unfolds_and_stops_at_the_body() {
        let headers = decode("\r\n\r\nSubject: a\r\n  b\r\nX: 1\r\nx: 2\r\n\r\nBody: no");
        assert_eq!(headers.first("subject"), Some("a b"));
        assert_eq!(headers.get("x").unwrap(), ["1", "2"]);
        assert_eq!(headers.get("body"), None);
    }

    #[test]
    fn drops_prototype_names() {
        let headers = decode("__proto__: a\nconstructor: b\nAction: failed");
        assert_eq!(headers.iter().count(), 1);
    }

    #[test]
    fn a_line_without_a_name_has_an_empty_key() {
        let headers = decode(":x\n  only");
        assert_eq!(headers.first(""), Some(""));
        assert!(!headers.has_named());
    }
}
