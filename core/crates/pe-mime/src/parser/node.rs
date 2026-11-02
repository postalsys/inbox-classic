//! One part of a message while it is parsed: its header lines, its parsed content headers and
//! its decoded body. A port of postal-mime's mime-node.ts and its decoders.

use std::collections::BTreeMap;

use super::strings::{decode_base64, decode_continuations, decode_header_line, decode_text, fold_line_breaks, is_wsp};

/// A header value with parameters, `text/plain; charset=utf-8`
#[derive(Debug, Clone, Default, PartialEq, Eq)]
pub struct StructuredHeader {
    /// Lowercase
    pub value: String,
    pub params: BTreeMap<String, String>,
}

/// One header field: the lowercase key, the key as written, the unfolded value
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct Header {
    pub key: String,
    pub original_key: String,
    pub value: String,
}

/// A header field as it was written, folding kept
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct HeaderLine {
    pub key: String,
    pub line: String,
}

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub(crate) enum State {
    Header,
    Body,
    Finished,
}

/// The transfer decoding of a body
#[derive(Debug)]
pub(crate) enum Decoder {
    PassThrough {
        output: Vec<u8>,
        pending_break: Option<Vec<u8>>,
    },
    Base64 {
        output: Vec<u8>,
        remainder: Vec<u8>,
    },
    QuotedPrintable {
        output: Vec<u8>,
        pending_break: Option<Vec<u8>>,
    },
}

impl Decoder {
    fn new(encoding: &str) -> Self {
        match encoding {
            "base64" => Decoder::Base64 {
                output: Vec::new(),
                remainder: Vec::new(),
            },
            "quoted-printable" => Decoder::QuotedPrintable {
                output: Vec::new(),
                pending_break: None,
            },
            _ => Decoder::PassThrough {
                output: Vec::new(),
                pending_break: None,
            },
        }
    }

    fn update(&mut self, line: &[u8], line_break: &[u8]) {
        match self {
            Decoder::PassThrough { output, pending_break } => {
                if let Some(pending) = pending_break.take() {
                    output.extend_from_slice(&pending);
                }
                output.extend_from_slice(line);
                *pending_break = Some(line_break.to_vec());
            }
            Decoder::Base64 { output, remainder } => {
                let before = remainder.len();
                remainder.extend(
                    line.iter()
                        .copied()
                        .filter(|c| c.is_ascii_alphanumeric() || matches!(c, b'+' | b'/' | b'=')),
                );
                // padding ends a group: decode up to the last '=', keep the rest. Only the new
                // bytes can hold one, everything before was decoded at its '='.
                if let Some(last) = remainder[before..].iter().rposition(|c| *c == b'=').map(|p| before + p) {
                    output.extend(decode_base64(&remainder[..=last]));
                    remainder.drain(..=last);
                }
                // decode whole groups as they come, so a large attachment is not held twice
                if remainder.len() >= 100 * 1024 {
                    let aligned = remainder.len() / 4 * 4;
                    output.extend(decode_base64(&remainder[..aligned]));
                    remainder.drain(..aligned);
                }
            }
            Decoder::QuotedPrintable { output, pending_break } => {
                if let Some(pending) = pending_break.take() {
                    output.extend_from_slice(&pending);
                }
                let mut len = line.len();
                while len > 0 && is_wsp(line[len - 1]) {
                    len -= 1;
                }
                let soft_break = len > 0 && line[len - 1] == b'=';
                if soft_break {
                    len -= 1;
                }
                let hex = |c: u8| (c as char).to_digit(16).map(|d| d as u8);
                let mut i = 0;
                while i < len {
                    if line[i] == b'='
                        && i + 2 < len
                        && let (Some(high), Some(low)) = (hex(line[i + 1]), hex(line[i + 2]))
                    {
                        output.push(high << 4 | low);
                        i += 3;
                        continue;
                    }
                    output.push(line[i]);
                    i += 1;
                }
                *pending_break = (!soft_break).then(|| line_break.to_vec());
            }
        }
    }

    /// The decoded body. The line break before a boundary belongs to the boundary.
    fn finish(self, boundary_ended: bool) -> Vec<u8> {
        match self {
            Decoder::PassThrough {
                mut output,
                pending_break,
            }
            | Decoder::QuotedPrintable {
                mut output,
                pending_break,
            } => {
                if !boundary_ended && let Some(pending) = pending_break {
                    output.extend_from_slice(&pending);
                }
                output
            }
            Decoder::Base64 { mut output, remainder } => {
                output.extend(decode_base64(&remainder));
                output
            }
        }
    }
}

#[derive(Debug)]
pub(crate) struct MimeNode {
    pub parent: Option<usize>,
    pub children: Vec<usize>,
    pub finalized_children: usize,
    pub depth: usize,
    pub state: State,
    header_lines: Vec<String>,
    pub content_type: StructuredHeader,
    /// The subtype of a multipart (`mixed`, `alternative`), None otherwise
    pub multipart: Option<String>,
    pub transfer_encoding: String,
    pub disposition: StructuredHeader,
    pub content_id: Option<String>,
    pub description: Option<String>,
    pub headers: Vec<Header>,
    pub raw_header_lines: Vec<HeaderLine>,
    decoder: Option<Decoder>,
    pub content: Option<Vec<u8>>,
    /// The boundary this multipart's parts are separated with
    pub boundary: Option<Vec<u8>>,
}

const CONTENT_HEADERS: [&str; 5] = [
    "content-type",
    "content-transfer-encoding",
    "content-disposition",
    "content-id",
    "content-description",
];

impl MimeNode {
    pub fn new(parent: Option<usize>, depth: usize, parent_multipart: Option<&str>) -> Self {
        let default_type = if parent_multipart == Some("digest") {
            "message/rfc822"
        } else {
            "text/plain"
        };
        MimeNode {
            parent,
            children: Vec::new(),
            finalized_children: 0,
            depth,
            state: State::Header,
            header_lines: Vec::new(),
            content_type: StructuredHeader {
                value: default_type.into(),
                params: BTreeMap::new(),
            },
            multipart: None,
            transfer_encoding: String::new(),
            disposition: StructuredHeader::default(),
            content_id: None,
            description: None,
            headers: Vec::new(),
            raw_header_lines: Vec::new(),
            decoder: None,
            content: None,
            boundary: None,
        }
    }

    pub fn finish_body(&mut self, boundary_ended: bool) {
        if self.state == State::Header {
            self.end_headers();
        }
        self.content = self.decoder.take().map(|decoder| decoder.finish(boundary_ended));
        self.state = State::Finished;
    }

    /// Feeds a line. Returns true when the line was not a header line and ended the header: it
    /// has to be fed again, now as body.
    pub fn feed(
        &mut self,
        line: &[u8],
        line_break: &[u8],
        header_size: &mut usize,
        max_header_size: usize,
    ) -> Result<bool, super::Error> {
        match self.state {
            State::Header => {
                if line.is_empty() {
                    self.end_headers();
                    return Ok(false);
                }
                *header_size += line.len().max(64);
                if *header_size > max_header_size {
                    return Err(super::Error::limit(
                        "EMAXHEADERSIZE",
                        format!("Maximum header size of {max_header_size} bytes exceeded"),
                    ));
                }
                let text = decode_header_line(line);
                if !is_wsp(line[0]) && !is_field_start(&text) {
                    self.end_headers();
                    return Ok(true);
                }
                self.header_lines.push(text);
            }
            State::Body => {
                if let Some(decoder) = self.decoder.as_mut() {
                    decoder.update(line, line_break);
                }
            }
            State::Finished => {}
        }
        Ok(false)
    }

    fn end_headers(&mut self) {
        self.state = State::Body;
        self.process_headers();
    }

    fn process_headers(&mut self) {
        let mut folded: Vec<Vec<String>> = Vec::new();
        for line in std::mem::take(&mut self.header_lines) {
            match folded.last_mut() {
                Some(last) if line.starts_with([' ', '\t']) => last.push(line),
                _ => folded.push(vec![line]),
            }
        }
        let mut content = BTreeMap::new();
        for parts in folded {
            let raw = parts.join("\n");
            let raw_key = raw.split_once(':').map_or(raw.as_str(), |(k, _)| k);
            self.raw_header_lines.push(HeaderLine {
                key: raw_key.to_lowercase(),
                line: raw.clone(),
            });
            let unfolded = parts.concat();
            let (key, value) = match unfolded.split_once(':') {
                Some((key, value)) => (key.to_string(), trim_wsp(&fold_line_breaks(value)).to_string()),
                None => (unfolded.clone(), String::new()),
            };
            let lower = key.to_lowercase();
            if CONTENT_HEADERS.contains(&lower.as_str()) {
                content.entry(lower.clone()).or_insert_with(|| value.clone());
            }
            self.headers.push(Header {
                key: lower,
                original_key: key,
                value,
            });
        }
        self.apply_content_headers(content);
    }

    fn apply_content_headers(&mut self, mut content: BTreeMap<String, String>) {
        self.content_id = content.remove("content-id");
        self.description = content.remove("content-description");
        if let Some(value) = content.get("content-type") {
            self.content_type = parse_structured_header(value);
        }
        self.multipart = self.content_type.value.strip_prefix("multipart/").map(str::to_string);
        if self.multipart.is_some() {
            let boundary = self
                .content_type
                .params
                .get("boundary")
                .map(|b| b.trim_end().to_string())
                .unwrap_or_default();
            if boundary.is_empty() || !boundary.is_ascii() {
                // a multipart without a usable boundary is read as text
                self.content_type.value = "text/plain".into();
                self.multipart = None;
            } else {
                self.boundary = Some(boundary.into_bytes());
            }
        }
        self.disposition = parse_structured_header(content.get("content-disposition").map_or("", String::as_str));
        if let Some(end) = self.disposition.value.find([' ', '\t']) {
            self.disposition.value.truncate(end);
        }
        let encoding =
            strip_comments(content.get("content-transfer-encoding").map_or("", String::as_str)).to_lowercase();
        self.transfer_encoding = encoding
            .trim_start_matches([' ', '\t'])
            .chars()
            .take_while(|c| c.is_alphanumeric() || *c == '_' || *c == '-')
            .collect();
        self.decoder = Some(Decoder::new(&self.transfer_encoding));
    }

    /// The text of a text part, charset decoded, line breaks as `\n`, format=flowed joined
    pub fn text_content(&self) -> String {
        let Some(content) = &self.content else {
            return String::new();
        };
        let params = &self.content_type.params;
        let html = self.content_type.value == "text/html";
        let text = decode_text(content, params.get("charset").map(String::as_str), html).replace("\r\n", "\n");
        let flowed = params.get("format").is_some_and(|f| f.eq_ignore_ascii_case("flowed"));
        if self.content_type.value == "text/plain" && flowed {
            let del_sp = params.get("delsp").is_some_and(|d| d.eq_ignore_ascii_case("yes"));
            return decode_flowed(&text, del_sp);
        }
        text
    }
}

fn trim_wsp(text: &str) -> &str {
    text.trim_matches([' ', '\t'])
}

/// `From ` (an mbox line) or a field name and a colon
fn is_field_start(text: &str) -> bool {
    if text.starts_with("From ") {
        return true;
    }
    let name_end = text
        .find(|c: char| !matches!(c, '!'..='9' | ';'..='~'))
        .unwrap_or(text.len());
    text[name_end..].trim_start_matches([' ', '\t']).starts_with(':')
}

/// Comments in parentheses taken out of a structured header value. A `(` inside a parameter
/// value only opens a comment after white space; an unclosed comment before a `;` keeps the
/// value as it is.
pub(crate) fn strip_comments(text: &str) -> String {
    let chars: Vec<char> = text.chars().collect();
    let mut result = String::new();
    let mut depth = 0;
    let mut escaped = false;
    let mut in_quote = false;
    let mut comment_start = None;
    let mut in_parameter = false;
    let mut kept_any = false;
    let mut ends_with_wsp = false;
    for (i, &c) in chars.iter().enumerate() {
        let opens = || !in_parameter || !kept_any || ends_with_wsp;
        if escaped {
            escaped = false;
        } else if c == '\\' {
            escaped = true;
        } else if c == '"' && depth == 0 {
            in_quote = !in_quote;
        } else if !in_quote {
            if c == '(' && opens() {
                if depth == 0 {
                    comment_start = Some(i);
                }
                depth += 1;
                continue;
            }
            if c == ')' && depth > 0 {
                depth -= 1;
                continue;
            }
            if depth == 0 {
                if c == '=' {
                    in_parameter = true;
                } else if c == ';' {
                    in_parameter = false;
                }
            }
        }
        if depth == 0 {
            kept_any = true;
            ends_with_wsp = c == ' ' || c == '\t';
            result.push(c);
        }
    }
    if depth == 0 {
        return result;
    }
    let unclosed_before_parameter = comment_start.is_some_and(|start| chars[start..].contains(&';'));
    if unclosed_before_parameter {
        text.to_string()
    } else {
        result
    }
}

/// `text/plain; charset="utf-8"; format=flowed`
pub(crate) fn parse_structured_header(text: &str) -> StructuredHeader {
    let text = strip_comments(text);
    let mut header = StructuredHeader::default();
    let mut key: Option<String> = None;
    let mut value = String::new();
    let mut in_key = false;
    let mut pending_space = String::new();
    let mut quote_closed = false;
    let mut in_quote = false;
    let mut escaped = false;
    let store = |header: &mut StructuredHeader, name: String, result: String| {
        if !name.is_empty() {
            header.params.entry(name).or_insert(result);
        }
    };
    let push = |value: &mut String, pending_space: &mut String, c: char| {
        if !value.is_empty() {
            value.push_str(pending_space);
        }
        pending_space.clear();
        value.push(c);
    };
    for c in text.chars() {
        if in_key {
            match c {
                '=' => {
                    key = Some(std::mem::take(&mut value).trim().to_lowercase());
                    pending_space.clear();
                    quote_closed = false;
                    in_key = false;
                }
                ';' => {
                    let name = std::mem::take(&mut value).trim().to_lowercase();
                    pending_space.clear();
                    quote_closed = false;
                    store(&mut header, name, String::new());
                }
                _ => value.push(c),
            }
            continue;
        }
        if quote_closed && c != ';' {
            escaped = false;
            continue;
        }
        if escaped {
            push(&mut value, &mut pending_space, c);
        } else if in_quote && c == '\\' {
            escaped = true;
            continue;
        } else if in_quote && c == '"' {
            in_quote = false;
            quote_closed = true;
        } else if !in_quote && c == '"' {
            in_quote = true;
            if !value.is_empty() {
                value.push_str(&pending_space);
            }
            pending_space.clear();
        } else if !in_quote && c == ';' {
            let result = std::mem::take(&mut value);
            pending_space.clear();
            quote_closed = false;
            match key.take() {
                None => header.value = result,
                Some(name) => store(&mut header, name, result),
            }
            in_key = true;
        } else if !in_quote && (c == ' ' || c == '\t') {
            pending_space.push(c);
        } else {
            push(&mut value, &mut pending_space, c);
        }
        escaped = false;
    }
    if in_key {
        let name = value.trim().to_lowercase();
        store(&mut header, name, String::new());
    } else {
        match key {
            None => header.value = value,
            Some(name) => store(&mut header, name, value),
        }
    }
    header.value = header.value.to_lowercase();
    decode_continuations(&mut header.params);
    header
}

/// format=flowed (RFC 3676): lines ending in a space go on in the next line of the same quote
/// depth; with DelSp the space is removed
pub(crate) fn decode_flowed(text: &str, del_sp: bool) -> String {
    let mut out = String::with_capacity(text.len());
    let mut flowed = false;
    let mut depth = 0;
    for (index, line) in text.split('\n').enumerate() {
        let quote_depth = line.chars().take_while(|c| *c == '>').count();
        let content_start = if line[quote_depth..].starts_with(' ') {
            quote_depth + 1
        } else {
            quote_depth
        };
        let content = &line[content_start..];
        let signature = content == "-- ";
        if flowed && quote_depth == depth && !signature {
            if del_sp {
                out.pop();
            }
            out.push_str(content);
        } else {
            if index > 0 {
                out.push('\n');
            }
            out.push_str(if quote_depth > 0 { line } else { content });
        }
        flowed = !signature && content.ends_with(' ');
        depth = quote_depth;
    }
    out
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn structured_headers() {
        let header = parse_structured_header(
            "Text/Plain; charset=\"UTF-8\" (comment); format=flowed; name*0*=utf-8''J%C3%B5; name*1=ul",
        );
        assert_eq!(header.value, "text/plain");
        assert_eq!(header.params["charset"], "UTF-8");
        assert_eq!(header.params["format"], "flowed");
        assert_eq!(header.params["name"], "Jõul");
        let header = parse_structured_header("attachment; filename=\"a \\\"b\\\".txt\"; size=5");
        assert_eq!(header.params["filename"], "a \"b\".txt");
        assert_eq!(parse_structured_header("inline").value, "inline");
        assert_eq!(parse_structured_header("").value, "");
    }

    #[test]
    fn comments() {
        assert_eq!(
            strip_comments("text/plain (a (nested) comment); x=1"),
            "text/plain ; x=1"
        );
        assert_eq!(strip_comments("a; name=file(1).txt"), "a; name=file(1).txt");
        assert_eq!(strip_comments("\"(not a comment)\""), "\"(not a comment)\"");
    }

    #[test]
    fn flowed() {
        assert_eq!(decode_flowed("Hello \nworld\n", false), "Hello world\n");
        assert_eq!(decode_flowed("Hello \nworld", true), "Helloworld");
        assert_eq!(decode_flowed("> quoted \n> more\nplain", false), "> quoted more\nplain");
        assert_eq!(decode_flowed("sig \n-- \nme", false), "sig \n-- \nme");
    }

    #[test]
    fn quoted_printable_and_base64() {
        let mut qp = Decoder::new("quoted-printable");
        qp.update(b"caf=C3=A9 soft=", b"\r\n");
        qp.update(b"break  ", b"\r\n");
        assert_eq!(qp.finish(false), "café softbreak\r\n".as_bytes());
        let mut b64 = Decoder::new("base64");
        b64.update(b"SGVs", b"\n");
        b64.update(b"bG8=", b"\n");
        assert_eq!(b64.finish(true), b"Hello");
    }
}
