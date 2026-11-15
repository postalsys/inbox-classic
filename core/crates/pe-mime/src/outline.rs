//! The tree of a message's MIME parts with where each lies in the raw bytes, nothing decoded.
//!
//! The parser (`parser`) flattens a message into its text, HTML and attachments, decoding as it goes; a signature
//! over a part is over the part's exact bytes, which that loses. Here every part is found by its boundaries and kept
//! as byte ranges of the source: the start of its headers, the start of its body, and its end, which is where the
//! line break before the next boundary begins (RFC 2046 section 5.1.1: that line break belongs to the boundary).

use std::collections::BTreeMap;

/// The most parts and the deepest nesting looked at; what lies beyond is part of the last part found
pub const MAX_PARTS: usize = 1000;
pub const MAX_DEPTH: usize = 32;

/// One MIME part
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct Part {
    /// Where its headers start
    pub start: usize,
    /// Where its body starts (after the empty line); `end` when it has no body
    pub body: usize,
    /// Where it ends
    pub end: usize,
    /// `type/subtype`, lower case; `text/plain` when it says none (`message/rfc822` under multipart/digest)
    pub content_type: String,
    /// Its Content-Type parameters, names lower case, decoded
    pub params: BTreeMap<String, String>,
    /// Content-Transfer-Encoding, lower case; empty for none
    pub transfer_encoding: String,
    /// `inline`, `attachment`, or empty
    pub disposition: String,
    /// The indices of its parts in `Outline::parts`, for a multipart
    pub children: Vec<usize>,
    pub depth: usize,
}

impl Part {
    pub fn is_multipart(&self) -> bool {
        self.content_type.starts_with("multipart/")
    }

    pub fn param(&self, name: &str) -> Option<&str> {
        self.params.get(name).map(String::as_str)
    }
}

/// A message's parts, the message itself first
#[derive(Debug, Clone, Default, PartialEq, Eq)]
pub struct Outline {
    pub parts: Vec<Part>,
}

impl Outline {
    pub fn root(&self) -> Option<&Part> {
        self.parts.first()
    }

    /// The bytes of part `index`, its headers and its body, as they are in `raw`
    pub fn bytes<'a>(&self, raw: &'a [u8], index: usize) -> &'a [u8] {
        self.parts
            .get(index)
            .and_then(|part| raw.get(part.start..part.end))
            .unwrap_or_default()
    }

    /// The body of part `index`, undecoded
    pub fn body<'a>(&self, raw: &'a [u8], index: usize) -> &'a [u8] {
        self.parts
            .get(index)
            .and_then(|part| raw.get(part.body..part.end))
            .unwrap_or_default()
    }
}

/// The outline of the message `raw`
pub fn outline(raw: &[u8]) -> Outline {
    let mut outline = Outline::default();
    add_part(raw, 0, raw.len(), 0, "text/plain", &mut outline);
    outline
}

/// Where the headers of the entity starting at `start` end, and where its body starts: after the first empty line
/// (CRLF CRLF or LF LF), or nowhere for headers only
fn header_end(raw: &[u8], start: usize, end: usize) -> (usize, usize) {
    let mut at = start;
    // an entity that starts with an empty line has no headers
    for eol in [&b"\r\n"[..], b"\n"] {
        if raw[start..end].starts_with(eol) {
            return (start, start + eol.len());
        }
    }
    while at < end {
        let line_end = memchr(b'\n', &raw[at..end]).map_or(end, |i| at + i + 1);
        let line = &raw[at..line_end];
        let next = &raw[line_end.min(end)..end];
        if line.ends_with(b"\n") && (next.starts_with(b"\r\n") || next.starts_with(b"\n")) {
            let blank = if next.starts_with(b"\r\n") { 2 } else { 1 };
            return (line_end, line_end + blank);
        }
        at = line_end;
    }
    (end, end)
}

fn memchr(byte: u8, haystack: &[u8]) -> Option<usize> {
    haystack.iter().position(|&b| b == byte)
}

/// The header fields of a header block, unfolded, names lower case
fn fields(block: &[u8]) -> Vec<(String, String)> {
    let text = String::from_utf8_lossy(block);
    let mut out: Vec<(String, String)> = Vec::new();
    for line in text.split('\n') {
        let line = line.trim_end_matches('\r');
        if line.starts_with([' ', '\t']) {
            if let Some((_, value)) = out.last_mut() {
                value.push(' ');
                value.push_str(line.trim());
            }
            continue;
        }
        if let Some((name, value)) = line.split_once(':') {
            out.push((name.trim().to_ascii_lowercase(), value.trim().to_string()));
        }
    }
    out
}

/// A structured value, `type/subtype; name=value; name="quoted"`: the first item lower case, and the parameters, read
/// the way the parser reads them, so the two never disagree about a message's structure
fn structured(value: &str) -> (String, BTreeMap<String, String>) {
    let header = crate::parser::parse_structured_header(value);
    (header.value.to_ascii_lowercase(), header.params.into_iter().collect())
}

/// Adds the entity in `raw[start..end]` and its parts; its index
/// `default_type` is what a part without a Content-Type is: `message/rfc822` in a multipart/digest (RFC 2046 5.1.5)
fn add_part(raw: &[u8], start: usize, end: usize, depth: usize, default_type: &str, outline: &mut Outline) -> usize {
    let (headers_end, body) = header_end(raw, start, end);
    let fields = fields(&raw[start..headers_end]);
    let field = |name: &str| fields.iter().rev().find(|(n, _)| n == name).map(|(_, v)| v.as_str());
    let (mut content_type, params) = structured(field("content-type").unwrap_or(""));
    if !content_type.contains('/') {
        content_type = default_type.into();
    }
    let (disposition, _) = structured(field("content-disposition").unwrap_or(""));
    let index = outline.parts.len();
    outline.parts.push(Part {
        start,
        body,
        end,
        content_type,
        params,
        transfer_encoding: field("content-transfer-encoding")
            .unwrap_or("")
            .trim()
            .to_ascii_lowercase(),
        disposition,
        children: Vec::new(),
        depth,
    });
    let part = &outline.parts[index];
    if !part.is_multipart() || depth >= MAX_DEPTH {
        return index;
    }
    let Some(boundary) = part.param("boundary").filter(|b| !b.is_empty()).map(str::to_string) else {
        return index;
    };
    for (child_start, child_end) in children(raw, body, end, &boundary) {
        if outline.parts.len() >= MAX_PARTS {
            break;
        }
        let default = if outline.parts[index].content_type == "multipart/digest" {
            "message/rfc822"
        } else {
            "text/plain"
        };
        let child = add_part(raw, child_start, child_end, depth + 1, default, outline);
        outline.parts[index].children.push(child);
    }
    index
}

/// The parts of a multipart body: each from after a delimiter line to the line break before the next delimiter
fn children(raw: &[u8], body: usize, end: usize, boundary: &str) -> Vec<(usize, usize)> {
    let delimiter = format!("--{boundary}");
    let delimiter = delimiter.as_bytes();
    let mut out = Vec::new();
    let mut open: Option<usize> = None;
    let mut at = body;
    while at < end {
        let line_end = memchr(b'\n', &raw[at..end]).map_or(end, |i| at + i + 1);
        let line = &raw[at..line_end];
        if line.starts_with(delimiter) {
            let rest = &line[delimiter.len()..];
            let closing = rest.starts_with(b"--");
            let rest = if closing { &rest[2..] } else { rest };
            // only transport padding may follow a delimiter
            if rest.iter().all(|b| matches!(b, b' ' | b'\t' | b'\r' | b'\n')) {
                if let Some(start) = open.take() {
                    // the line break before the delimiter belongs to it
                    let mut part_end = at;
                    if part_end > start && raw[part_end - 1] == b'\n' {
                        part_end -= 1;
                        if part_end > start && raw[part_end - 1] == b'\r' {
                            part_end -= 1;
                        }
                    }
                    out.push((start, part_end.max(start)));
                }
                if closing {
                    return out;
                }
                open = Some(line_end);
            }
        }
        at = line_end;
    }
    // no closing delimiter: the last part runs to the end
    if let Some(start) = open {
        out.push((start, end));
    }
    out
}

#[cfg(test)]
mod tests {
    use super::*;

    const SIGNED: &str = "From: alice@example.org\r\nContent-Type: multipart/signed; micalg=pgp-sha256;\r\n \
        protocol=\"application/pgp-signature\"; boundary=\"b1\"\r\n\r\nThis is an OpenPGP/MIME signed message.\r\n\
        --b1\r\nContent-Type: text/plain\r\n\r\nHello\r\n--b1\r\nContent-Type: application/pgp-signature\r\n\r\n\
        -----BEGIN PGP SIGNATURE-----\r\n...\r\n-----END PGP SIGNATURE-----\r\n--b1--\r\nepilogue\r\n";

    #[test]
    fn a_signed_message() {
        let raw = SIGNED.as_bytes();
        let outline = outline(raw);
        let root = outline.root().unwrap();
        assert_eq!(root.content_type, "multipart/signed");
        assert_eq!(root.param("protocol"), Some("application/pgp-signature"));
        assert_eq!(root.param("micalg"), Some("pgp-sha256"));
        assert_eq!(root.children, [1, 2]);
        // the signed part is exactly its headers and body, without the line break before the boundary
        assert_eq!(outline.bytes(raw, 1), b"Content-Type: text/plain\r\n\r\nHello");
        assert_eq!(outline.body(raw, 1), b"Hello");
        assert_eq!(outline.parts[2].content_type, "application/pgp-signature");
        assert!(outline.body(raw, 2).ends_with(b"-----END PGP SIGNATURE-----"));
    }

    #[test]
    fn nested_parts_and_bare_line_feeds() {
        let raw = "Content-Type: multipart/mixed; boundary=outer\n\n--outer\nContent-Type: multipart/alternative; \
                   boundary=\"inner\"\n\n--inner\nContent-Type: text/plain\n\nplain\n--inner\nContent-Type: text/html\n\n\
                   <p>html</p>\n--inner--\n--outer\nContent-Type: application/pdf; name=\"a b.pdf\"\nContent-Disposition: \
                   attachment\n\nPDF\n--outer--\n";
        let raw = raw.as_bytes();
        let outline = outline(raw);
        let kinds: Vec<&str> = outline.parts.iter().map(|p| p.content_type.as_str()).collect();
        assert_eq!(
            kinds,
            [
                "multipart/mixed",
                "multipart/alternative",
                "text/plain",
                "text/html",
                "application/pdf"
            ]
        );
        assert_eq!(outline.body(raw, 2), b"plain");
        assert_eq!(outline.body(raw, 3), b"<p>html</p>");
        assert_eq!(outline.parts[4].disposition, "attachment");
        assert_eq!(outline.parts[4].param("name"), Some("a b.pdf"));
        assert_eq!(outline.parts[3].depth, 2);
    }

    #[test]
    fn a_boundary_must_start_a_line_and_be_alone() {
        let raw =
            b"Content-Type: multipart/mixed; boundary=b\r\n\r\n--b\r\n\r\ntext --b inside\r\n--bx not one\r\n--b--\r\n";
        let outline = outline(raw);
        assert_eq!(outline.parts.len(), 2);
        assert_eq!(outline.body(raw, 1), b"text --b inside\r\n--bx not one");
    }

    #[test]
    fn no_closing_boundary_runs_to_the_end() {
        let raw = b"Content-Type: multipart/mixed; boundary=b\r\n\r\n--b\r\nContent-Type: text/plain\r\n\r\ncut";
        let outline = outline(raw);
        assert_eq!(outline.body(raw, 1), b"cut");
    }

    #[test]
    fn deep_nesting_stops() {
        let mut raw = String::new();
        for depth in 0..100 {
            raw.push_str(&format!(
                "Content-Type: multipart/mixed; boundary=b{depth}\r\n\r\n--b{depth}\r\n"
            ));
        }
        raw.push_str("Content-Type: text/plain\r\n\r\nx\r\n");
        let outline = outline(raw.as_bytes());
        assert_eq!(outline.parts.len(), MAX_DEPTH + 1);
    }

    #[test]
    fn a_single_part_message() {
        let raw = b"Subject: hi\r\n\r\nbody\r\n";
        let outline = outline(raw);
        assert_eq!(outline.parts.len(), 1);
        assert_eq!(outline.parts[0].content_type, "text/plain");
        assert_eq!(outline.body(raw, 0), b"body\r\n");
    }
}
