//! Messages parsed for display: headers, addresses, the text and HTML to show, and attachments.
//! A port of postal-mime (../postal-mime/src), with its limits against hostile input: nesting,
//! part count, header size, depth of attached messages, and addresses in attached messages.
//!
//! The helpers that decode header text the postal-mime way stay inside this module: the rest of
//! the crate decodes the libmime way, for IMAP, and mixing the two would show the same subject
//! differently depending on where it came from.

mod address;
mod entities;
mod filename;

/// A name to save a file under: no path, no control or direction characters, no name Windows reserves
pub use filename::{is_direction_mark, safe_filename};
mod node;
mod strings;
mod text;

use std::collections::HashMap;
use std::fmt;

pub use address::{ParsedAddress, parse_addresses};
pub use node::{Header, HeaderLine};
pub use text::{escape_html, html_to_text, text_addresses, text_to_html};

use crate::Address;
use node::{LineBreak, MimeNode, State};
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
    /// As the sender wrote it, for display; see [`Attachment::safe_filename`] for saving
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

impl Attachment {
    /// A name to save the attachment under: no path, no control or direction characters, no
    /// name Windows reserves, and one made from the type when the sender gave none
    pub fn safe_filename(&self) -> String {
        filename::safe_filename(self.filename.as_deref(), &self.mime_type)
    }

    /// The name to show: the sender's, without control or direction characters, so what is
    /// shown is what is saved (`photo\u{202e}gpj.exe` does not read as `photo.exe.jpg`); the safe
    /// name when the sender gave none
    pub fn display_filename(&self) -> String {
        match self
            .filename
            .as_deref()
            .map(filename::without_unsafe_marks)
            .filter(|f| !f.trim().is_empty())
        {
            Some(name) => name,
            None => self.safe_filename(),
        }
    }
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
    /// The Date header as written
    pub date: Option<String>,
    /// The Date header in seconds since the Unix epoch, when it parses
    pub timestamp: Option<i64>,
    /// The one-time passcode of the message's own OTP-Token header, when it has exactly one and it
    /// is valid. The header is not authenticated: check that the message is signed by the domain of
    /// the origin before trusting it.
    pub otp: Option<crate::OtpToken>,
    pub html: Option<String>,
    pub text: Option<String>,
    pub attachments: Vec<Attachment>,
}

impl Message {
    /// The message IDs of References, oldest first, for threading
    pub fn reference_ids(&self) -> Vec<String> {
        self.references.as_deref().map(message_ids).unwrap_or_default()
    }
}

/// The `<id>` items of a References or In-Reply-To value
pub fn message_ids(value: &str) -> Vec<String> {
    let mut ids = Vec::new();
    let mut rest = value;
    while let Some(start) = rest.find('<') {
        let Some(end) = rest[start..].find('>') else { break };
        let id = rest[start + 1..start + end].trim();
        if !id.is_empty() {
            ids.push(format!("<{id}>"));
        }
        rest = &rest[start + end + 1..];
    }
    ids
}

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
enum TextType {
    Plain,
    Html,
}

/// What the header block of an attached message shows
#[derive(Clone)]
struct AttachedHeader {
    from: Option<ParsedAddress>,
    subject: Option<String>,
    date: Option<String>,
    timestamp: Option<i64>,
    to: Vec<ParsedAddress>,
    cc: Vec<ParsedAddress>,
    bcc: Vec<ParsedAddress>,
}

enum TextItem {
    Text(String),
    Header(Box<AttachedHeader>),
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
    /// Also the source of the keys of text entries, unique across nested parsers
    part_count: usize,
    forwarded_addresses: usize,
}

struct Parser<'a> {
    limits: Limits,
    counters: &'a mut Counters,
    rfc822_depth: usize,
    nodes: Vec<MimeNode>,
    /// Text entry key of node 0
    key_base: usize,
    current: usize,
    /// Multiparts whose boundary is open, in order
    boundaries: Vec<usize>,
    text_entries: Vec<TextEntry>,
    text_index: HashMap<usize, usize>,
    has_plain: bool,
    has_html: bool,
    attachments: Vec<Attachment>,
    force_rfc822_attachments: bool,
    /// Every attached message stays an attachment, as in a delivery report
    keep_attached_messages: bool,
}

/// Parses a message
pub fn parse(raw: &[u8]) -> Result<Message, Error> {
    parse_with(raw, Limits::default())
}

pub fn parse_with(raw: &[u8], limits: Limits) -> Result<Message, Error> {
    let mut counters = Counters::default();
    let mut parser = Parser::new(limits, &mut counters, 0)?;
    parser.run(raw)
}

/// Parses a message keeping every attached message (message/rfc822) as an attachment, the way a
/// message with a delivery or feedback report is parsed, rather than showing an inline one as part
/// of the text. For reading a returned message out of a bounce that carries no report part.
pub fn parse_keeping_attached_messages(raw: &[u8]) -> Result<Message, Error> {
    let mut counters = Counters::default();
    let mut parser = Parser::new(Limits::default(), &mut counters, 0)?;
    parser.keep_attached_messages = true;
    parser.run(raw)
}

impl<'a> Parser<'a> {
    fn new(limits: Limits, counters: &'a mut Counters, rfc822_depth: usize) -> Result<Self, Error> {
        let key_base = counters.part_count;
        let mut parser = Parser {
            limits,
            counters,
            rfc822_depth,
            nodes: Vec::new(),
            key_base,
            current: 0,
            boundaries: Vec::new(),
            text_entries: Vec::new(),
            text_index: HashMap::new(),
            has_plain: false,
            has_html: false,
            attachments: Vec::new(),
            force_rfc822_attachments: false,
            keep_attached_messages: false,
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
        let parent_multipart = parent.and_then(|p| self.nodes[p].multipart.as_deref());
        let node = MimeNode::new(parent, depth, parent_multipart);
        self.nodes.push(node);
        let index = self.nodes.len() - 1;
        if let Some(parent) = parent {
            self.nodes[parent].children.push(index);
        }
        Ok(index)
    }

    fn run(&mut self, raw: &[u8]) -> Result<Message, Error> {
        let mut pos = 0;
        while pos < raw.len() {
            let (line, line_break, next) = read_line(raw, pos);
            pos = next;
            self.process_line(line, line_break, pos >= raw.len())?;
        }
        self.force_rfc822_attachments = self.keep_attached_messages || self.has_report_parts();
        self.collect(0, None, false)?;
        let mut message = self.build_message();
        if self.rfc822_depth == 0 {
            let (text, html) = self.render_text();
            message.text = text;
            message.html = html;
        }
        message.attachments = std::mem::take(&mut self.attachments);
        Ok(message)
    }

    fn process_line(&mut self, line: &[u8], line_break: LineBreak, last: bool) -> Result<(), Error> {
        if !self.at_boundary(line)? {
            let current = self.current;
            let max = self.limits.max_headers_size;
            let in_header = self.nodes[current].state == State::Header;
            let again = self.nodes[current].feed(line, line_break, &mut self.counters.header_size, max)?;
            if in_header && self.nodes[current].state == State::Body && self.nodes[current].boundary.is_some() {
                // a multipart whose headers just ended opens its boundary
                self.boundaries.push(current);
            }
            if again {
                return self.process_line(line, line_break, last);
            }
        }
        if last {
            self.finalize(0, false);
        }
        Ok(())
    }

    /// Handles `line` when it is a boundary of an open multipart
    fn at_boundary(&mut self, line: &[u8]) -> Result<bool, Error> {
        if line.len() <= 2 || !line.starts_with(b"--") {
            return Ok(false);
        }
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
            return Ok(true);
        }
        Ok(false)
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
            n.multipart.as_deref().is_none()
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
        let index = *self.text_index.entry(key).or_insert_with(|| {
            self.text_entries.push(TextEntry {
                key,
                plain: None,
                html: None,
            });
            self.text_entries.len() - 1
        });
        self.text_entries[index]
            .items(kind)
            .get_or_insert_with(Vec::new)
            .push(item);
        match kind {
            TextType::Plain => self.has_plain = true,
            TextType::Html => self.has_html = true,
        }
    }

    fn collect(&mut self, index: usize, mut alternative: Option<usize>, mut related: bool) -> Result<(), Error> {
        match self.nodes[index].multipart.as_deref() {
            None => self.collect_part(index, alternative, related)?,
            Some("alternative") => alternative = Some(index),
            Some("related") => related = true,
            Some(_) => {}
        }
        for i in 0..self.nodes[index].children.len() {
            let child = self.nodes[index].children[i];
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
            let text = self.nodes[index].take_text_content();
            let key = self.key_base + alternative.unwrap_or(index);
            self.add_text(key, kind, TextItem::Text(text));
        } else if node.content.is_some() {
            let attachment = self.attachment(index, related, depth_exceeded);
            self.attachments.push(attachment);
        }
        Ok(())
    }

    fn collect_sub_message(&mut self, index: usize) -> Result<(), Error> {
        let content = self.nodes[index].content.take().unwrap_or_default();
        let (mut message, entries, has_plain, has_html) = {
            let mut sub = Parser::new(self.limits, self.counters, self.rfc822_depth + 1)?;
            let message = sub.run(&content)?;
            (
                message,
                std::mem::take(&mut sub.text_entries),
                sub.has_plain,
                sub.has_html,
            )
        };
        let count = |list: &[ParsedAddress]| -> usize {
            list.iter()
                .map(|a| match a {
                    ParsedAddress::Mailbox(_) => 1,
                    ParsedAddress::Group { members, .. } => 1 + members.len(),
                })
                .sum()
        };
        self.counters.forwarded_addresses +=
            count(message.from.as_slice()) + count(&message.to) + count(&message.cc) + count(&message.bcc);
        if self.counters.forwarded_addresses > self.limits.max_forwarded_addresses {
            let max = self.limits.max_forwarded_addresses;
            return Err(Error::limit(
                "EMAXFORWARDEDADDRESSES",
                format!("Maximum forwarded address count of {max} addresses exceeded"),
            ));
        }
        let header = Box::new(AttachedHeader {
            from: message.from.take(),
            subject: message.subject.take(),
            date: message.date.take(),
            timestamp: message.timestamp,
            to: std::mem::take(&mut message.to),
            cc: std::mem::take(&mut message.cc),
            bcc: std::mem::take(&mut message.bcc),
        });
        let key = self.key_base + index;
        if has_plain || !has_html {
            self.add_text(key, TextType::Plain, TextItem::Header(header.clone()));
        }
        if has_html {
            self.add_text(key, TextType::Html, TextItem::Header(header));
        }
        for entry in entries {
            self.text_index.insert(entry.key, self.text_entries.len());
            self.text_entries.push(entry);
        }
        self.attachments.append(&mut message.attachments);
        Ok(())
    }

    fn attachment(&mut self, index: usize, related: bool, depth_exceeded: bool) -> Attachment {
        let node = &mut self.nodes[index];
        let calendar = matches!(node.content_type.value.as_str(), "text/calendar" | "application/ics");
        let (content, method) = if calendar {
            let text = node.take_text_content();
            let method = node.content_type.params.get("method").map(|m| m.trim().to_uppercase());
            (format!("{}\n", text.trim_end_matches('\n')).into_bytes(), method)
        } else {
            (node.content.take().unwrap_or_default(), None)
        };
        let filename = node
            .disposition
            .params
            .get("filename")
            .or_else(|| node.content_type.params.get("name"));
        Attachment {
            filename: filename
                .filter(|f| !f.is_empty())
                .map(|f| strings::decode_words(&strings::fold_line_breaks(f))),
            mime_type: node.content_type.value.clone(),
            disposition: Some(node.disposition.value.clone()).filter(|d| !d.is_empty()),
            related: related && node.content_id.is_some() && !depth_exceeded,
            description: node.description.as_deref().map(strings::decode_words),
            content_id: node.content_id.clone(),
            method,
            rfc822_depth_exceeded: depth_exceeded,
            content,
        }
    }

    /// The text and the HTML of the message: each part in its own type, or converted from the
    /// other one, attached messages with a header block
    fn render_text(&mut self) -> (Option<String>, Option<String>) {
        let mut plain: Option<Vec<String>> = None;
        let mut html: Option<Vec<String>> = None;
        let kinds: Vec<TextType> = [(self.has_plain, TextType::Plain), (self.has_html, TextType::Html)]
            .into_iter()
            .filter(|(present, _)| *present)
            .map(|(_, kind)| kind)
            .collect();
        for entry in std::mem::take(&mut self.text_entries) {
            for &kind in &kinds {
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

    fn build_message(&mut self) -> Message {
        let headers = std::mem::take(&mut self.nodes[0].headers);
        let header_lines = std::mem::take(&mut self.nodes[0].raw_header_lines);
        let header = |key: &str| {
            headers
                .iter()
                .find(|h| h.key == key)
                .map(|h| h.value.as_str())
                .filter(|v| !v.is_empty())
        };
        let first_address = |key: &str| header(key).and_then(|v| parse_addresses(v).into_iter().next());
        let plain_address = |key: &str| match first_address(key) {
            Some(ParsedAddress::Mailbox(Address { address, .. })) if !address.is_empty() => Some(address),
            _ => None,
        };
        let all = |key: &str| -> Vec<ParsedAddress> {
            headers
                .iter()
                .filter(|h| h.key == key && !h.value.is_empty())
                .flat_map(|h| parse_addresses(&h.value))
                .collect()
        };
        let words = |key: &str| header(key).map(strings::decode_words);
        let date = headers.iter().find(|h| h.key == "date").map(|h| h.value.clone());
        Message {
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
            timestamp: date.as_deref().and_then(crate::date::parse_date),
            date,
            otp: crate::otp_token(&headers),
            headers,
            header_lines,
            ..Default::default()
        }
    }
}

fn render_item(item: &TextItem, kind: TextType, convert: bool) -> String {
    match item {
        TextItem::Header(header) => {
            let fields = HeaderFields {
                from: header.from.as_ref(),
                subject: header.subject.as_deref(),
                date: header.date.as_deref(),
                timestamp: header.timestamp,
                to: &header.to,
                cc: &header.cc,
                bcc: &header.bcc,
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

/// The line at `pos` without its line break, the line break, and where the next line starts. The
/// carriage returns of a last line without a line feed are dropped.
fn read_line(raw: &[u8], pos: usize) -> (&[u8], LineBreak, usize) {
    let (end, next) = match raw[pos..].iter().position(|c| *c == b'\n') {
        Some(offset) => (pos + offset, pos + offset + 1),
        None => (raw.len(), raw.len()),
    };
    let content_end = raw[pos..end]
        .iter()
        .rposition(|c| *c != b'\r')
        .map_or(pos, |p| pos + p + 1);
    let crs = if next == end { 0 } else { end - content_end };
    (&raw[pos..content_end], LineBreak { crs }, next)
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

    fn mailbox(name: &str, address: &str) -> ParsedAddress {
        ParsedAddress::Mailbox(Address {
            name: name.into(),
            address: address.into(),
        })
    }

    #[test]
    fn keeps_attached_messages_when_asked() {
        let raw = b"Subject: Returned\r\nContent-Type: multipart/mixed; boundary=\"b\"\r\n\r\n--b\r\nContent-Type: text/plain\r\n\r\nNotice\r\n--b\r\nContent-Type: message/rfc822\r\n\r\nSubject: Original\r\nMessage-ID: <o@example.com>\r\n\r\nOriginal body\r\n--b--\r\n";
        let inline = parse(raw).unwrap();
        assert!(inline.attachments.is_empty());
        assert!(inline.text.unwrap().contains("Original body"));
        let kept = parse_keeping_attached_messages(raw).unwrap();
        assert_eq!(kept.text.as_deref(), Some("Notice"));
        assert_eq!(kept.attachments.len(), 1);
        assert_eq!(kept.attachments[0].mime_type, "message/rfc822");
        assert!(kept.attachments[0].content.starts_with(b"Subject: Original"));
    }

    #[test]
    fn simple_message() {
        let raw = b"From: Andris <andris@example.com>\r\nTo: a@b.c, Team: d@e.f;\r\nSubject: =?UTF-8?Q?Tere?=\r\nDate: Mon, 6 Oct 2025 10:00:00 +0000\r\nReferences: <a@x> <b@x>\r\n\r\nHello\r\nworld\r\n";
        let message = parse(raw).unwrap();
        assert_eq!(message.from, Some(mailbox("Andris", "andris@example.com")));
        assert_eq!(message.to.len(), 2);
        assert_eq!(message.subject.as_deref(), Some("Tere"));
        assert_eq!(message.date.as_deref(), Some("Mon, 6 Oct 2025 10:00:00 +0000"));
        assert_eq!(message.timestamp, Some(1_759_744_800));
        assert_eq!(message.reference_ids(), vec!["<a@x>".to_string(), "<b@x>".to_string()]);
        assert_eq!(message.text.as_deref(), Some("Hello\nworld\n"));
        assert_eq!(message.html, None);
    }

    #[test]
    fn alternative_and_attachment() {
        let raw = b"Content-Type: multipart/mixed; boundary=b1\r\n\r\npreamble\r\n--b1\r\nContent-Type: multipart/alternative; boundary=b2\r\n\r\n--b2\r\nContent-Type: text/plain\r\n\r\nplain\r\n--b2\r\nContent-Type: text/html\r\n\r\n<p>html</p>\r\n--b2--\r\n--b1\r\nContent-Type: application/pdf; name=\"../a.pdf\"\r\nContent-Transfer-Encoding: base64\r\n\r\nSGVsbG8=\r\n--b1--\r\n";
        let message = parse(raw).unwrap();
        assert_eq!(message.text.as_deref(), Some("plain"));
        assert_eq!(message.html.as_deref(), Some("<p>html</p>"));
        assert_eq!(message.attachments.len(), 1);
        assert_eq!(message.attachments[0].filename.as_deref(), Some("../a.pdf"));
        assert_eq!(message.attachments[0].safe_filename(), "a.pdf");
        assert_eq!(message.attachments[0].display_filename(), "../a.pdf");
        let tricky = Attachment {
            filename: Some("photo\u{202e}gpj.exe".into()),
            ..Default::default()
        };
        assert_eq!(tricky.display_filename(), "photogpj.exe");
        let unnamed = Attachment {
            filename: Some("\u{202e}".into()),
            mime_type: "application/pdf".into(),
            ..Default::default()
        };
        assert_eq!(unnamed.display_filename(), "attachment.pdf");
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

    #[test]
    fn message_id_lists() {
        assert_eq!(
            message_ids(" <a@b>\r\n <c@d>junk<>"),
            vec!["<a@b>".to_string(), "<c@d>".to_string()]
        );
        assert!(message_ids("none").is_empty());
    }
}
