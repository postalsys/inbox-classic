//! Messages to send, built the way nodemailer's mail-composer and mime-node build them: text and HTML as
//! multipart/alternative, images an HTML part refers to by Content-ID in multipart/related beside it, other files in
//! multipart/mixed, headers encoded and folded, bodies in 7bit, quoted-printable or base64.

use pe_mime::Address;
use pe_mime::date::DateTime;
use pe_mime::parser::ParsedAddress;

use crate::address::{envelope_addresses, format_addresses, normalize_address};
use crate::encoding::{
    LINE_LENGTH, WORD_LENGTH, base64_lines_into, build_header_value, encode_header_text, encode_word, encode_words,
    fold_lines, has_longer_lines, is_header_control, is_plain_text, qp_encode, qp_wrap, quote_param_if_needed,
    text_encoding,
};

#[derive(Debug, Clone, PartialEq, Eq, Default)]
pub struct Attachment {
    pub filename: String,
    pub content_type: String,
    pub content: Vec<u8>,
    /// For an image the HTML shows: `cid:` this
    pub content_id: Option<String>,
}

#[derive(Debug, Clone, PartialEq, Eq, Default)]
pub struct Message {
    pub from: Address,
    pub to: Vec<ParsedAddress>,
    pub cc: Vec<ParsedAddress>,
    /// In the envelope only
    pub bcc: Vec<ParsedAddress>,
    pub reply_to: Vec<ParsedAddress>,
    pub subject: String,
    pub text: Option<String>,
    pub html: Option<String>,
    pub attachments: Vec<Attachment>,
    pub in_reply_to: Option<String>,
    pub references: Vec<String>,
    /// Seconds since the Unix epoch
    pub date: i64,
    /// With or without angle brackets; made up when empty
    pub message_id: String,
}

/// Who a message goes from and to in the SMTP transaction
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct Envelope {
    pub from: String,
    pub to: Vec<String>,
}

#[derive(Debug, Clone, PartialEq, Eq)]
pub struct Built {
    pub envelope: Envelope,
    /// With its angle brackets
    pub message_id: String,
    /// The message, CRLF line breaks
    pub raw: Vec<u8>,
}

/// A part of the MIME tree
struct Node<'a> {
    /// Numbered in the order nodemailer creates them, for the boundaries
    id: usize,
    /// The Content-Type value and its parameters
    content_type: (String, Vec<(String, String)>),
    filename: Option<String>,
    /// Headers in the order they were set; Content-Type is first until it moves to the end of the root
    headers: Vec<(String, String)>,
    /// Borrowed from the message: an attachment is not copied to be encoded
    content: Option<&'a [u8]>,
    children: Vec<Node<'a>>,
}

impl<'a> Node<'a> {
    fn new(id: usize, value: &str, params: &[(&str, &str)]) -> Node<'a> {
        Node {
            id,
            content_type: (
                value.to_string(),
                params.iter().map(|(k, v)| (k.to_string(), v.to_string())).collect(),
            ),
            filename: None,
            headers: vec![("Content-Type".into(), String::new())],
            content: None,
            children: Vec::new(),
        }
    }

    fn set_header(&mut self, key: &str, value: String) {
        match self.headers.iter_mut().find(|(k, _)| k == key) {
            Some(header) => header.1 = value,
            None => self.headers.push((key.to_string(), value)),
        }
    }

    fn header(&self, key: &str) -> Option<&str> {
        self.headers.iter().find(|(k, _)| k == key).map(|(_, v)| v.as_str())
    }

    fn is_multipart(&self) -> bool {
        self.content_type.0.starts_with("multipart/")
    }

    fn is_text(&self) -> bool {
        self.content_type.0.starts_with("text/")
    }

    /// The transfer encoding: as set, or 7bit for short plain text, quoted-printable or base64 for other text
    /// by what it holds, base64 for anything else
    fn transfer_encoding(&self) -> Option<String> {
        let content = self.content?;
        if let Some(set) = self.header("Content-Transfer-Encoding") {
            return Some(set.to_string());
        }
        if self.is_text() {
            let text = String::from_utf8_lossy(content);
            if is_plain_text(&text, false) && !has_longer_lines(&text, LINE_LENGTH) {
                return Some("7bit".into());
            }
            return Some(
                if text_encoding(&text) == 'Q' {
                    "quoted-printable"
                } else {
                    "base64"
                }
                .into(),
            );
        }
        (!self.is_multipart()).then(|| "base64".into())
    }
}

struct Composer<'a> {
    message: &'a Message,
    /// The text and HTML with CRLF line breaks
    text: Option<&'a str>,
    html: Option<&'a str>,
    next_id: usize,
}

impl<'a> Composer<'a> {
    fn node(&mut self, value: &str, params: &[(&str, &str)]) -> Node<'a> {
        self.next_id += 1;
        Node::new(self.next_id, value, params)
    }

    fn text_node(&mut self, value: &str, content: &'a str) -> Node<'a> {
        let mut node = self.node(value, &[("charset", "utf-8")]);
        node.content = Some(content.as_bytes());
        node
    }

    fn attachment_node(&mut self, attachment: &'a Attachment) -> Node<'a> {
        let mut node = self.node(&attachment.content_type, &[]);
        node.filename = Some(attachment.filename.clone()).filter(|f| !f.is_empty());
        if let Some(cid) = &attachment.content_id {
            node.set_header("Content-ID", format!("<{}>", cid.replace(['<', '>'], "")));
        }
        node.set_header("Content-Transfer-Encoding", "base64".into());
        let inline = attachment.content_id.is_some() && attachment.content_type.starts_with("image/");
        node.set_header(
            "Content-Disposition",
            if inline { "inline" } else { "attachment" }.into(),
        );
        node.content = Some(&attachment.content);
        node
    }

    fn alternatives(&mut self) -> Vec<Node<'a>> {
        let mut nodes = Vec::new();
        if let Some(text) = self.text {
            nodes.push(self.text_node("text/plain", text));
        }
        if let Some(html) = self.html {
            nodes.push(self.text_node("text/html", html));
        }
        nodes
    }

    /// The tree of the message, numbered as nodemailer numbers it
    fn compose(&mut self) -> Node<'a> {
        let message = self.message;
        let has_html = self.html.is_some();
        let (related, attached): (Vec<&'a Attachment>, Vec<&'a Attachment>) = message
            .attachments
            .iter()
            .partition(|a| has_html && a.content_id.is_some());
        let alternatives = usize::from(self.text.is_some()) + usize::from(has_html);
        let use_related = has_html && !related.is_empty();
        let use_alternative = alternatives > 1;
        let use_mixed = attached.len() > 1 || (alternatives > 0 && attached.len() == 1);

        if use_mixed {
            let mut mixed = self.node("multipart/mixed", &[]);
            if use_alternative {
                let alternative = self.alternative(&related, use_related);
                mixed.children.push(alternative);
            } else if use_related {
                let related_node = self.related(&related);
                mixed.children.push(related_node);
            } else {
                let nodes = self.alternatives();
                mixed.children.extend(nodes);
            }
            for attachment in attached {
                let node = self.attachment_node(attachment);
                mixed.children.push(node);
            }
            mixed
        } else if use_alternative {
            self.alternative(&related, use_related)
        } else if use_related {
            self.related(&related)
        } else {
            match self.alternatives().pop() {
                Some(node) => node,
                None => match attached.first() {
                    Some(attachment) => self.attachment_node(attachment),
                    None => self.text_node("text/plain", ""),
                },
            }
        }
    }

    fn alternative(&mut self, related: &[&'a Attachment], use_related: bool) -> Node<'a> {
        let mut node = self.node("multipart/alternative", &[]);
        if let Some(text) = self.text {
            let text = self.text_node("text/plain", text);
            node.children.push(text);
        }
        if let Some(html) = self.html {
            if use_related {
                let related = self.related(related);
                node.children.push(related);
            } else {
                let html = self.text_node("text/html", html);
                node.children.push(html);
            }
        }
        node
    }

    fn related(&mut self, related: &[&'a Attachment]) -> Node<'a> {
        let mut node = self.node("multipart/related", &[("type", "text/html")]);
        let html = self.text_node("text/html", self.html.unwrap_or_default());
        node.children.push(html);
        for attachment in related {
            let child = self.attachment_node(attachment);
            node.children.push(child);
        }
        node
    }
}

/// `Mon, 06 Oct 2025 10:00:00 +0000`
pub fn format_date(timestamp: i64) -> String {
    const DAYS: [&str; 7] = ["Thu", "Fri", "Sat", "Sun", "Mon", "Tue", "Wed"];
    let t = DateTime::from_timestamp(timestamp);
    let day = DAYS[timestamp.div_euclid(86_400).rem_euclid(7) as usize];
    format!(
        "{day}, {:02} {} {:04} {:02}:{:02}:{:02} +0000",
        t.day,
        t.month_name(),
        t.year,
        t.hour,
        t.minute,
        t.second
    )
}

/// `<id>`: what can not stand in a header out, the angle brackets added
fn message_id(value: &str) -> String {
    let cleaned: String = value
        .replace(['\r', '\n'], " ")
        .chars()
        // white space other than space and TAB would be a place to fold that is no fold
        .filter(|c| !is_header_control(*c) && !(c.is_whitespace() && !matches!(c, ' ' | '\t')))
        .collect();
    let cleaned = cleaned.trim();
    let open = if cleaned.starts_with('<') { "" } else { "<" };
    let close = if cleaned.ends_with('>') { "" } else { ">" };
    format!("{open}{cleaned}{close}")
}

/// `bytes` random bytes in hex, from the operating system; the clock when that fails
fn random_hex(bytes: usize) -> String {
    let mut random = vec![0u8; bytes];
    if getrandom::fill(&mut random).is_err() {
        let nanos = std::time::SystemTime::now()
            .duration_since(std::time::UNIX_EPOCH)
            .map_or(0, |d| d.as_nanos())
            .to_le_bytes();
        for (i, byte) in random.iter_mut().enumerate() {
            *byte = nanos[i % nanos.len()];
        }
    }
    random.iter().map(|b| format!("{b:02x}")).collect()
}

/// A message ID for a message from `from`: random, in the domain of the sender
pub fn new_message_id(from: &str) -> String {
    let hex = random_hex(16);
    let domain = from
        .rsplit('@')
        .next()
        .filter(|d| !d.is_empty() && from.contains('@'))
        .unwrap_or("localhost");
    format!(
        "<{}-{}-{}-{}-{}@{domain}>",
        &hex[..8],
        &hex[8..12],
        &hex[12..16],
        &hex[16..20],
        &hex[20..32]
    )
}

/// A random part of the boundaries of a message
pub fn new_boundary_base() -> String {
    random_hex(8)
}

struct Writer<'a> {
    boundary_base: &'a str,
    out: Vec<u8>,
}

impl Writer<'_> {
    fn boundary(&self, node: &Node) -> String {
        format!("--_NmP-{}-Part_{}", self.boundary_base, node.id)
    }

    fn content_type(&self, node: &Node) -> String {
        let (value, params) = &node.content_type;
        let mut params: Vec<(&str, &str)> = params.iter().map(|(k, v)| (k.as_str(), v.as_str())).collect();
        let boundary = self.boundary(node);
        if node.is_multipart() {
            params.push(("boundary", &boundary));
        }
        let mut header = build_header_value(value, &params);
        if let Some(filename) = &node.filename {
            // `name=` as well, for clients that only read that; an encoded word, which RFC 2231 would not allow
            let encoded = if filename.chars().any(|c| c.is_control()) {
                encode_word(filename, text_encoding(filename), WORD_LENGTH)
            } else {
                encode_words(filename, text_encoding(filename), WORD_LENGTH, true)
            };
            header.push_str("; name=");
            header.push_str(&quote_param_if_needed(&encoded, filename));
        }
        header
    }

    fn header_value(&self, node: &Node, key: &str, value: &str) -> String {
        match key {
            "Content-Type" => self.content_type(node),
            "Content-Disposition" => match &node.filename {
                Some(filename) => build_header_value(value, &[("filename", filename)]),
                None => build_header_value(value, &[]),
            },
            "Content-Transfer-Encoding"
            | "MIME-Version"
            | "Date"
            | "From"
            | "To"
            | "Cc"
            | "Reply-To"
            | "References" => value.to_string(),
            "Message-ID" | "In-Reply-To" | "Content-ID" => message_id(value),
            _ => encode_header_text(&value.replace(['\r', '\n'], " ")),
        }
    }

    fn write_headers(&mut self, node: &mut Node, root: bool) {
        if let Some(encoding) = node.transfer_encoding() {
            node.set_header("Content-Transfer-Encoding", encoding);
        }
        if node.filename.is_some() && node.header("Content-Disposition").is_none() {
            node.set_header("Content-Disposition", "attachment".into());
        }
        if root {
            node.set_header("MIME-Version", "1.0".into());
            // Content-Type last in the root
            let content_type = node.headers.remove(0);
            node.headers.push(content_type);
        }
        let lines: Vec<String> = node
            .headers
            .iter()
            .filter_map(|(key, value)| {
                let value = self.header_value(node, key, value);
                (!value.trim().is_empty()).then(|| fold_lines(&format!("{key}: {value}"), LINE_LENGTH, false))
            })
            .collect();
        self.out.extend_from_slice(lines.join("\r\n").as_bytes());
        self.out.extend_from_slice(b"\r\n\r\n");
    }

    fn write(&mut self, node: &mut Node, root: bool) {
        self.write_headers(node, root);
        if let Some(content) = node.content {
            match node.header("Content-Transfer-Encoding").unwrap_or_default() {
                "base64" => base64_lines_into(content, &mut self.out),
                "quoted-printable" => self
                    .out
                    .extend_from_slice(qp_wrap(&qp_encode(content), LINE_LENGTH).as_bytes()),
                _ => self.out.extend_from_slice(content),
            }
        }
        if node.is_multipart() {
            let boundary = self.boundary(node);
            let mut children = std::mem::take(&mut node.children);
            for (i, child) in children.iter_mut().enumerate() {
                if i > 0 {
                    self.out.extend_from_slice(b"\r\n");
                }
                self.out.extend_from_slice(format!("--{boundary}\r\n").as_bytes());
                self.write(child, false);
            }
            self.out.extend_from_slice(format!("\r\n--{boundary}--\r\n").as_bytes());
        }
    }
}

/// Text bodies with CRLF line breaks, as SMTP sends them
fn crlf(text: &str) -> String {
    let mut out = String::with_capacity(text.len() + text.len() / 40);
    let mut chars = text.chars().peekable();
    while let Some(c) = chars.next() {
        match c {
            '\r' => {
                out.push_str("\r\n");
                if chars.peek() == Some(&'\n') {
                    chars.next();
                }
            }
            '\n' => out.push_str("\r\n"),
            c => out.push(c),
        }
    }
    out
}

/// Builds the message with `boundary_base` in its boundaries
pub fn build_with(message: &Message, boundary_base: &str) -> Built {
    let text = message.text.as_deref().map(crlf);
    let html = message.html.as_deref().map(crlf);
    let from = normalize_address(&message.from.address);
    let message_id = if message.message_id.trim().is_empty() {
        new_message_id(&from)
    } else {
        self::message_id(&message.message_id)
    };

    let mut root = Composer {
        message,
        text: text.as_deref(),
        html: html.as_deref(),
        next_id: 0,
    }
    .compose();
    let from_list = [ParsedAddress::Mailbox(message.from.clone())];
    let fields: [(&str, String); 9] = [
        ("From", format_addresses(&from_list)),
        ("To", format_addresses(&message.to)),
        ("Cc", format_addresses(&message.cc)),
        ("Reply-To", format_addresses(&message.reply_to)),
        ("In-Reply-To", message.in_reply_to.clone().unwrap_or_default()),
        (
            "References",
            message
                .references
                .iter()
                .map(|r| self::message_id(r))
                .collect::<Vec<_>>()
                .join(" "),
        ),
        ("Subject", message.subject.clone()),
        ("Message-ID", message_id.clone()),
        ("Date", format_date(message.date)),
    ];
    for (key, value) in fields {
        if !value.is_empty() {
            root.set_header(key, value);
        }
    }

    let mut writer = Writer {
        boundary_base,
        out: Vec::new(),
    };
    writer.write(&mut root, true);
    let mut raw = writer.out;
    // the message ends with a line break
    match raw.last() {
        Some(b'\n') => {}
        Some(b'\r') => raw.push(b'\n'),
        _ => raw.extend_from_slice(b"\r\n"),
    }
    Built {
        envelope: Envelope {
            from,
            to: envelope_addresses([message.to.as_slice(), message.cc.as_slice(), message.bcc.as_slice()]),
        },
        message_id,
        raw,
    }
}

/// Builds the message, with random boundaries
pub fn build(message: &Message) -> Built {
    build_with(message, &new_boundary_base())
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn dates() {
        assert_eq!(format_date(1_759_744_800), "Mon, 06 Oct 2025 10:00:00 +0000");
        assert_eq!(format_date(0), "Thu, 01 Jan 1970 00:00:00 +0000");
    }

    #[test]
    fn ids() {
        assert_eq!(message_id("abc@x"), "<abc@x>");
        assert_eq!(message_id("<abc@x>"), "<abc@x>");
        let id = new_message_id("andris@example.com");
        assert!(
            id.starts_with('<') && id.ends_with("@example.com>") && id.len() > 40,
            "{id}"
        );
        assert_ne!(new_message_id("a@b"), new_message_id("a@b"));
        assert_eq!(new_boundary_base().len(), 16);
    }

    #[test]
    fn bcc_only_in_the_envelope() {
        let message = Message {
            from: Address {
                name: "A".into(),
                address: "a@example.com".into(),
            },
            to: vec![ParsedAddress::Mailbox(Address {
                name: String::new(),
                address: "b@example.com".into(),
            })],
            bcc: vec![ParsedAddress::Mailbox(Address {
                name: String::new(),
                address: "secret@example.com".into(),
            })],
            subject: "x".into(),
            text: Some("line\nbreaks\rhere".into()),
            ..Default::default()
        };
        let built = build(&message);
        let raw = String::from_utf8(built.raw).unwrap();
        assert!(!raw.contains("secret"), "{raw}");
        assert_eq!(built.envelope.to, ["b@example.com", "secret@example.com"]);
        assert!(raw.contains("line\r\nbreaks\r\nhere\r\n"), "{raw}");
    }
}
