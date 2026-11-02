//! Messages parsed for display: headers, addresses, the text and HTML to show, and attachments.
//! A port of postal-mime (../postal-mime/src), with its limits against hostile input: nesting,
//! part count, header size, depth of attached messages, and addresses in attached messages.

mod address;
mod entities;
mod node;
mod strings;
mod text;

use std::fmt;

pub use address::{ParsedAddress, parse_addresses};
pub use node::{Header, HeaderLine, StructuredHeader};
pub use strings::{decode_charset, decode_text, decode_words as decode_header_words};
pub use text::{decode_html_entities, escape_html, html_to_text, text_to_html};

use node::{MimeNode, State};
use text::HeaderFields;

/// A message that can not be parsed within the limits
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct Error {
    /// postal-mime's code: `EMAXNESTINGDEPTH`, `EMAXPARTCOUNT`, `EMAXHEADERSIZE`, ...
    pub code: &'static str,
    pub message: String,
}

impl Error {
    pub(crate) fn limit(code: &'static str, message: String) -> Self {
        Error { code, message }
    }
}

impl fmt::Display for Error {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        write!(f, "{} ({})", self.message, self.code)
    }
}

impl std::error::Error for Error {}

#[derive(Debug, Clone, Copy)]
pub struct Limits {
    pub max_nesting_depth: usize,
    pub max_headers_size: usize,
    pub max_part_count: usize,
    pub max_rfc822_nesting_depth: usize,
    pub max_forwarded_addresses: usize,
}

impl Default for Limits {
    fn default() -> Self {
        Limits {
            max_nesting_depth: 256,
            max_headers_size: 2 * 1024 * 1024,
            max_part_count: 10_000,
            max_rfc822_nesting_depth: 10,
            max_forwarded_addresses: 10_000,
        }
    }
}

#[derive(Debug, Clone, Default, PartialEq, Eq)]
pub struct Attachment {
    pub filename: Option<String>,
    pub mime_type: String,
    pub disposition: Option<String>,
    /// An image of a multipart/related HTML part, referenced by its Content-ID
    pub related: bool,
    pub description: Option<String>,
    pub content_id: Option<String>,
    /// The METHOD of a calendar invitation
    pub method: Option<String>,
    /// An attached message nested too deep to be read, kept as a file
    pub rfc822_depth_exceeded: bool,
    pub content: Vec<u8>,
}

#[derive(Debug, Clone, Default, PartialEq, Eq)]
pub struct Message {
    pub headers: Vec<Header>,
    pub header_lines: Vec<HeaderLine>,
    pub from: Option<ParsedAddress>,
    pub sender: Option<ParsedAddress>,
    pub reply_to: Vec<ParsedAddress>,
    pub delivered_to: Option<String>,
    pub return_path: Option<String>,
    pub to: Vec<ParsedAddress>,
    pub cc: Vec<ParsedAddress>,
    pub bcc: Vec<ParsedAddress>,
    pub subject: Option<String>,
    pub message_id: Option<String>,
    pub in_reply_to: Option<String>,
    pub references: Option<String>,
    /// ISO 8601 in UTC, or the Date header as written when it does not parse
    pub date: Option<String>,
    pub html: Option<String>,
    pub text: Option<String>,
    pub attachments: Vec<Attachment>,
}

#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash)]
enum TextType {
    Plain,
    Html,
}

enum TextItem {
    Text(String),
    Message(Box<Message>),
}

/// The texts a part contributes, by type; the key is unique across nested parsers
struct TextEntry {
    key: usize,
    plain: Option<Vec<TextItem>>,
    html: Option<Vec<TextItem>>,
}

impl TextEntry {
    fn items(&mut self, kind: TextType) -> &mut Option<Vec<TextItem>> {
        match kind {
            TextType::Plain => &mut self.plain,
            TextType::Html => &mut self.html,
        }
    }
}

/// Counted across a message and the messages attached to it
#[derive(Default)]
struct Counters {
    header_size: usize,
    part_count: usize,
    forwarded_addresses: usize,
    /// For the keys of text entries
    next_key: usize,
}

struct Parser<'a> {
    limits: Limits,
    counters: &'a mut Counters,
    rfc822_depth: usize,
    nodes: Vec<MimeNode>,
    /// Node keys for text entries, `nodes` index + base
    key_base: usize,
    current: usize,
    /// Multiparts whose boundary is open, in order
    boundaries: Vec<usize>,
    text_entries: Vec<TextEntry>,
    text_types: Vec<TextType>,
    attachments: Vec<Attachment>,
    force_rfc822_attachments: bool,
}

/// Parses a message
pub fn parse(raw: &[u8]) -> Result<Message, Error> {
    parse_with(raw, Limits::default())
}

pub fn parse_with(raw: &[u8], limits: Limits) -> Result<Message, Error> {
    let mut counters = Counters::default();
    let mut parser = Parser::new(limits, &mut counters, 0)?;
    let (message, _) = parser.run(raw)?;
    Ok(message)
}

impl<'a> Parser<'a> {
    fn new(limits: Limits, counters: &'a mut Counters, rfc822_depth: usize) -> Result<Self, Error> {
        let key_base = counters.next_key;
        let mut parser = Parser {
            limits,
            counters,
            rfc822_depth,
            nodes: Vec::new(),
            key_base,
            current: 0,
            boundaries: Vec::new(),
            text_entries: Vec::new(),
            text_types: Vec::new(),
            attachments: Vec::new(),
            force_rfc822_attachments: false,
        };
        parser.add_node(None)?;
        Ok(parser)
    }

    fn add_node(&mut self, parent: Option<usize>) -> Result<usize, Error> {
        self.counters.part_count += 1;
        if self.counters.part_count > self.limits.max_part_count {
            let max = self.limits.max_part_count;
            return Err(Error::limit(
                "EMAXPARTCOUNT",
                format!("Maximum MIME part count of {max} parts exceeded"),
            ));
        }
        let depth = parent.map_or(0, |p| self.nodes[p].depth + 1);
        if depth > self.limits.max_nesting_depth {
            let max = self.limits.max_nesting_depth;
            return Err(Error::limit(
                "EMAXNESTINGDEPTH",
                format!("Maximum MIME nesting depth of {max} levels exceeded"),
            ));
        }
        let multipart = parent.and_then(|p| self.nodes[p].multipart.clone());
        self.nodes.push(MimeNode::new(parent, depth, multipart.as_deref()));
        self.counters.next_key += 1;
        let index = self.nodes.len() - 1;
        if let Some(parent) = parent {
            self.nodes[parent].children.push(index);
        }
        Ok(index)
    }

    /// Parses `raw`, returns the message and the text entries of a nested parser
    fn run(&mut self, raw: &[u8]) -> Result<(Message, Vec<TextEntry>), Error> {
        let mut pos = 0;
        while pos < raw.len() {
            let (line, line_break, next) = read_line(raw, pos);
            pos = next;
            self.process_line(line, line_break, pos >= raw.len())?;
        }
        self.force_rfc822_attachments = self.has_report_parts();
        self.collect(0, None, false)?;
        let mut message = self.build_message();
        if self.rfc822_depth == 0 {
            let (text, html) = self.render_text();
            message.text = text;
            message.html = html;
        }
        message.attachments = std::mem::take(&mut self.attachments);
        Ok((message, std::mem::take(&mut self.text_entries)))
    }

    fn process_line(&mut self, line: &[u8], line_break: &[u8], last: bool) -> Result<(), Error> {
        if line.len() > 2 && line.starts_with(b"--") {
            for i in 0..self.boundaries.len() {
                let node = self.boundaries[i];
                let Some(terminator) = boundary_match(line, self.nodes[node].boundary.as_deref().unwrap_or_default())
                else {
                    continue;
                };
                if terminator {
                    self.finalize(node, true);
                    self.current = self.nodes[node].parent.unwrap_or(0);
                } else {
                    self.finalize_children(node, true);
                    self.current = self.add_node(Some(node))?;
                }
                if last {
                    self.finalize(0, false);
                }
                return Ok(());
            }
        }
        let current = self.current;
        let max = self.limits.max_headers_size;
        let again = self.nodes[current].feed(line, line_break, &mut self.counters.header_size, max)?;
        self.register_boundary(current);
        if again {
            return self.process_line(line, line_break, last);
        }
        if last {
            self.finalize(0, false);
        }
        Ok(())
    }

    /// A multipart whose headers just ended opens its boundary
    fn register_boundary(&mut self, node: usize) {
        if self.nodes[node].state == State::Body
            && self.nodes[node].boundary.is_some()
            && !self.boundaries.contains(&node)
        {
            self.boundaries.push(node);
        }
    }

    fn finalize(&mut self, node: usize, boundary_ended: bool) {
        if self.nodes[node].state == State::Finished {
            return;
        }
        if let Some(position) = self.boundaries.iter().rposition(|n| *n == node) {
            self.boundaries.remove(position);
        }
        self.finalize_children(node, boundary_ended);
        self.nodes[node].finish_body(boundary_ended);
    }

    fn finalize_children(&mut self, node: usize, boundary_ended: bool) {
        while self.nodes[node].finalized_children < self.nodes[node].children.len() {
            let child = self.nodes[node].children[self.nodes[node].finalized_children];
            self.nodes[node].finalized_children += 1;
            self.finalize(child, boundary_ended);
        }
    }

    fn has_report_parts(&self) -> bool {
        self.nodes.iter().any(|n| {
            n.multipart.is_none()
                && ["message/delivery-status", "message/feedback-report"].contains(&n.content_type.value.as_str())
        })
    }

    fn is_inline_rfc822(&self, node: &MimeNode) -> bool {
        if self.force_rfc822_attachments || node.content_type.value != "message/rfc822" {
            return false;
        }
        if node.transfer_encoding == "base64" || node.transfer_encoding == "quoted-printable" {
            return false;
        }
        node.disposition.value.is_empty() || node.disposition.value == "inline"
    }

    fn is_inline_text(node: &MimeNode) -> bool {
        node.disposition.value != "attachment" && matches!(node.content_type.value.as_str(), "text/html" | "text/plain")
    }

    fn add_text(&mut self, key: usize, kind: TextType, item: TextItem) {
        let index = match self.text_entries.iter().position(|e| e.key == key) {
            Some(index) => index,
            None => {
                self.text_entries.push(TextEntry {
                    key,
                    plain: None,
                    html: None,
                });
                self.text_entries.len() - 1
            }
        };
        self.text_entries[index]
            .items(kind)
            .get_or_insert_with(Vec::new)
            .push(item);
        if !self.text_types.contains(&kind) {
            self.text_types.push(kind);
        }
    }

    fn collect(&mut self, index: usize, alternative: Option<usize>, related: bool) -> Result<(), Error> {
        let mut alternative = alternative;
        let mut related = related;
        match self.nodes[index].multipart.as_deref() {
            None => self.collect_part(index, alternative, related)?,
            Some("alternative") => alternative = Some(index),
            Some("related") => related = true,
            Some(_) => {}
        }
        for child in self.nodes[index].children.clone() {
            self.collect(child, alternative, related)?;
        }
        Ok(())
    }

    fn collect_part(&mut self, index: usize, alternative: Option<usize>, related: bool) -> Result<(), Error> {
        let node = &self.nodes[index];
        let inline_rfc822 = self.is_inline_rfc822(node);
        let depth_exceeded = inline_rfc822 && self.rfc822_depth >= self.limits.max_rfc822_nesting_depth;
        if inline_rfc822 && !depth_exceeded {
            return self.collect_sub_message(index);
        }
        if Self::is_inline_text(node) {
            let kind = if node.content_type.value == "text/html" {
                TextType::Html
            } else {
                TextType::Plain
            };
            let text = node.text_content();
            let key = self.key_base + alternative.unwrap_or(index);
            self.add_text(key, kind, TextItem::Text(text));
        } else if node.content.is_some() {
            let attachment = self.attachment(index, related, depth_exceeded);
            self.attachments.push(attachment);
        }
        Ok(())
    }

    fn collect_sub_message(&mut self, index: usize) -> Result<(), Error> {
        let content = self.nodes[index].content.clone().unwrap_or_default();
        let limits = self.limits;
        let depth = self.rfc822_depth + 1;
        let (message, entries, types) = {
            let mut sub = Parser::new(limits, self.counters, depth)?;
            let (message, entries) = sub.run(&content)?;
            (message, entries, sub.text_types.clone())
        };
        let count = |list: &[ParsedAddress]| {
            list.iter()
                .map(|a| 1 + a.mailboxes().len() * usize::from(matches!(a, ParsedAddress::Group { .. })))
                .sum::<usize>()
        };
        self.counters.forwarded_addresses += message
            .from
            .iter()
            .map(|a| count(std::slice::from_ref(a)))
            .sum::<usize>()
            + count(&message.to)
            + count(&message.cc)
            + count(&message.bcc);
        if self.counters.forwarded_addresses > self.limits.max_forwarded_addresses {
            let max = self.limits.max_forwarded_addresses;
            return Err(Error::limit(
                "EMAXFORWARDEDADDRESSES",
                format!("Maximum forwarded address count of {max} addresses exceeded"),
            ));
        }
        let (has_plain, has_html) = (types.contains(&TextType::Plain), types.contains(&TextType::Html));
        let key = self.key_base + index;
        let attachments = message.attachments.clone();
        let message = Box::new(message);
        if has_plain || !has_html {
            self.add_text(key, TextType::Plain, TextItem::Message(message.clone()));
        }
        if has_html {
            self.add_text(key, TextType::Html, TextItem::Message(message));
        }
        self.text_entries.extend(entries);
        self.attachments.extend(attachments);
        Ok(())
    }

    fn attachment(&self, index: usize, related: bool, depth_exceeded: bool) -> Attachment {
        let node = &self.nodes[index];
        let filename = node
            .disposition
            .params
            .get("filename")
            .or_else(|| node.content_type.params.get("name"));
        let mut attachment = Attachment {
            filename: filename
                .filter(|f| !f.is_empty())
                .map(|f| strings::decode_words(&strings::fold_line_breaks(f))),
            mime_type: node.content_type.value.clone(),
            disposition: Some(node.disposition.value.clone()).filter(|d| !d.is_empty()),
            related: related && node.content_id.is_some() && !depth_exceeded,
            description: node.description.as_deref().map(strings::decode_words),
            content_id: node.content_id.clone(),
            method: None,
            rfc822_depth_exceeded: depth_exceeded,
            content: node.content.clone().unwrap_or_default(),
        };
        if matches!(node.content_type.value.as_str(), "text/calendar" | "application/ics") {
            attachment.method = node.content_type.params.get("method").map(|m| m.trim().to_uppercase());
            let text = node.text_content();
            attachment.content = format!("{}\n", text.trim_end_matches('\n')).into_bytes();
        }
        attachment
    }

    /// The text and the HTML of the message: each part in its own type, or converted from the
    /// other one, attached messages with a header block
    fn render_text(&mut self) -> (Option<String>, Option<String>) {
        let mut plain: Option<Vec<String>> = None;
        let mut html: Option<Vec<String>> = None;
        for entry in &self.text_entries {
            for &kind in &self.text_types {
                let output = match kind {
                    TextType::Plain => plain.get_or_insert_with(Vec::new),
                    TextType::Html => html.get_or_insert_with(Vec::new),
                };
                let (own, other) = match kind {
                    TextType::Plain => (&entry.plain, &entry.html),
                    TextType::Html => (&entry.html, &entry.plain),
                };
                let convert = own.is_none();
                for item in own.as_ref().or(other.as_ref()).map(Vec::as_slice).unwrap_or_default() {
                    output.push(render_item(item, kind, convert));
                }
            }
        }
        let join = |parts: Option<Vec<String>>| parts.map(|p| p.join("\n")).filter(|t| !t.is_empty());
        (join(plain), join(html))
    }

    fn build_message(&self) -> Message {
        let root = &self.nodes[0];
        let header = |key: &str| {
            root.headers
                .iter()
                .find(|h| h.key == key)
                .map(|h| h.value.as_str())
                .filter(|v| !v.is_empty())
        };
        let first_address = |key: &str| header(key).and_then(|v| parse_addresses(v).into_iter().next());
        let plain_address = |key: &str| match first_address(key) {
            Some(ParsedAddress::Mailbox { address, .. }) if !address.is_empty() => Some(address),
            _ => None,
        };
        let all = |key: &str| -> Vec<ParsedAddress> {
            root.headers
                .iter()
                .filter(|h| h.key == key && !h.value.is_empty())
                .flat_map(|h| parse_addresses(&h.value))
                .collect()
        };
        let words = |key: &str| header(key).map(strings::decode_words);
        Message {
            headers: root.headers.clone(),
            header_lines: root.raw_header_lines.clone(),
            from: first_address("from"),
            sender: first_address("sender"),
            reply_to: all("reply-to"),
            delivered_to: plain_address("delivered-to"),
            return_path: plain_address("return-path"),
            to: all("to"),
            cc: all("cc"),
            bcc: all("bcc"),
            subject: words("subject"),
            message_id: words("message-id"),
            in_reply_to: words("in-reply-to"),
            references: words("references"),
            date: root
                .headers
                .iter()
                .find(|h| h.key == "date")
                .map(|h| match crate::date::parse_date(&h.value) {
                    Some(timestamp) => crate::date::to_iso(timestamp),
                    None => h.value.clone(),
                }),
            ..Default::default()
        }
    }
}

fn render_item(item: &TextItem, kind: TextType, convert: bool) -> String {
    match item {
        TextItem::Message(message) => {
            let fields = HeaderFields {
                from: message.from.as_ref(),
                subject: message.subject.as_deref(),
                date: message.date.as_deref(),
                to: &message.to,
                cc: &message.cc,
                bcc: &message.bcc,
            };
            match kind {
                TextType::Html => text::format_html_header(&fields),
                TextType::Plain => text::format_text_header(&fields),
            }
        }
        TextItem::Text(text) if !convert => text.clone(),
        TextItem::Text(text) => match kind {
            TextType::Html => text_to_html(text),
            TextType::Plain => html_to_text(text),
        },
    }
}

/// The line at `pos` without its line break, the line break, and where the next line starts.
/// Carriage returns at the end belong to the line break.
fn read_line(raw: &[u8], pos: usize) -> (&[u8], &[u8], usize) {
    let mut end = pos;
    let mut i = pos;
    while i < raw.len() {
        let c = raw[i];
        i += 1;
        if c != b'\r' && c != b'\n' {
            end = i;
        }
        if c == b'\n' {
            return (&raw[pos..end], &raw[end..i], i);
        }
    }
    (&raw[pos..end], b"\n", i)
}

/// Whether `line` is `--boundary` (Some(false)) or `--boundary--` (Some(true)), white space after
/// it allowed
fn boundary_match(line: &[u8], boundary: &[u8]) -> Option<bool> {
    let rest = line.strip_prefix(b"--")?.strip_prefix(boundary)?;
    let (terminator, rest) = match rest.strip_prefix(b"--") {
        Some(rest) => (true, rest),
        None => (false, rest),
    };
    rest.iter().all(|c| strings::is_wsp(*c)).then_some(terminator)
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn simple_message() {
        let raw = b"From: Andris <andris@example.com>\r\nTo: a@b.c, Team: d@e.f;\r\nSubject: =?UTF-8?Q?Tere?=\r\nDate: Mon, 6 Oct 2025 10:00:00 +0000\r\n\r\nHello\r\nworld\r\n";
        let message = parse(raw).unwrap();
        assert_eq!(
            message.from,
            Some(ParsedAddress::Mailbox {
                name: "Andris".into(),
                address: "andris@example.com".into()
            })
        );
        assert_eq!(message.to.len(), 2);
        assert_eq!(message.subject.as_deref(), Some("Tere"));
        assert_eq!(message.date.as_deref(), Some("2025-10-06T10:00:00.000Z"));
        assert_eq!(message.text.as_deref(), Some("Hello\nworld\n"));
        assert_eq!(message.html, None);
    }

    #[test]
    fn alternative_and_attachment() {
        let raw = b"Content-Type: multipart/mixed; boundary=b1\r\n\r\n--b1\r\nContent-Type: multipart/alternative; boundary=b2\r\n\r\n--b2\r\nContent-Type: text/plain\r\n\r\nplain\r\n--b2\r\nContent-Type: text/html\r\n\r\n<p>html</p>\r\n--b2--\r\n--b1\r\nContent-Type: application/pdf; name=\"a.pdf\"\r\nContent-Transfer-Encoding: base64\r\n\r\nSGVsbG8=\r\n--b1--\r\n";
        let message = parse(raw).unwrap();
        assert_eq!(message.text.as_deref(), Some("plain"));
        assert_eq!(message.html.as_deref(), Some("<p>html</p>"));
        assert_eq!(message.attachments.len(), 1);
        assert_eq!(message.attachments[0].filename.as_deref(), Some("a.pdf"));
        assert_eq!(message.attachments[0].content, b"Hello");
    }

    #[test]
    fn limits() {
        let mut raw = Vec::new();
        for i in 0..5 {
            raw.extend(format!("Content-Type: multipart/mixed; boundary=b{i}\r\n\r\n--b{i}\r\n").bytes());
        }
        let limits = Limits {
            max_nesting_depth: 3,
            ..Default::default()
        };
        assert_eq!(parse_with(&raw, limits).unwrap_err().code, "EMAXNESTINGDEPTH");
        assert!(parse(&raw).is_ok());
    }
}
