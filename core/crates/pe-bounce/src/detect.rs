//! Finds the failed recipient and the remote server's reply in a bounce. A port of EmailEngine's
//! `lib/bounce-detect.js`: the RFC 3464 report (message/delivery-status), the headers or the whole
//! of the returned message, `X-Failed-Recipients`, the formats of Amazon WorkMail and Zoho, and
//! text heuristics for the MTAs that write only prose (Postfix, Exim, qmail, Gmail's old format,
//! mobile carriers).
//!
//! One difference: EmailEngine only calls it for messages that look like bounces, while this runs
//! on any message, so the text heuristics run only when the message is plausibly a bounce (see
//! [`is_plausible_bounce`]). Ordinary mail that quotes an SMTP error is not taken for one.

use std::borrow::Cow;
use std::collections::HashMap;
use std::sync::LazyLock;

use pe_mime::parser::{Attachment, Message, ParsedAddress, html_to_text};
use regex::Regex;

use crate::headers::{self, Headers};
use crate::heuristics;
use crate::js::{self, regex};

/// The longest text the heuristics read; bounce details come early in a notice
pub const MAX_TEXT_LENGTH: usize = 50_000;

/// The remote server's reply
#[derive(Debug, Clone, Default, PartialEq, Eq)]
pub struct Response {
    /// The reply text, `550 5.1.1 <user@example.com>: Recipient address rejected`
    pub message: Option<String>,
    /// The enhanced status code, `5.1.1`
    pub status: Option<String>,
    /// The diagnostic type, `smtp`
    pub source: Option<String>,
}

/// One per-recipient block of a delivery report, with the per-message fields
#[derive(Debug, Clone, Default, PartialEq, Eq)]
pub struct Report {
    pub recipient: Option<String>,
    pub action: Option<String>,
    pub response: Option<Response>,
    /// Remote-MTA, lowercase
    pub remote_mta: Option<String>,
    /// Reporting-MTA, lowercase
    pub reporting_mta: Option<String>,
    pub queue_id: Option<String>,
    pub message_id: Option<String>,
}

/// What EmailEngine's `bounceDetect()` returns, field for field, and a little more
#[derive(Debug, Clone, Default, PartialEq, Eq)]
pub struct Detection {
    /// The failed recipient (the first one, when a report names several)
    pub recipient: Option<String>,
    /// `failed`, or what the report says (`delayed`, `delivered`, ...). None for a notice the
    /// heuristics found to be a delay, see `delay_notice`
    pub action: Option<String>,
    pub response: Option<Response>,
    /// Remote-MTA, else Reporting-MTA, else the host a notice names
    pub mta: Option<String>,
    /// Postfix's queue id
    pub queue_id: Option<String>,
    /// Message-ID of the returned message
    pub message_id: Option<String>,
    /// Headers of the returned message
    pub message_headers: Option<Headers>,
    /// The heuristics found a failure but the wording says delivery is still being tried
    pub delay_notice: bool,
    /// Remote-MTA of the described recipient, or the host a notice names
    pub remote_mta: Option<String>,
    /// Reporting-MTA of the report
    pub reporting_mta: Option<String>,
    /// Every recipient block of the delivery report, in order
    pub reports: Vec<Report>,
    /// Whether the text heuristics ran
    pub heuristics: bool,
}

/// Whether a value is set and not empty, as JavaScript tests a string
pub(crate) fn truthy(value: &Option<String>) -> bool {
    value.as_deref().is_some_and(|v| !v.is_empty())
}

/// `slot = slot || value`
pub(crate) fn fill(slot: &mut Option<String>, value: impl FnOnce() -> String) {
    if !truthy(slot) {
        *slot = Some(value());
    }
}

/// `slot = value` when the value is there, as `Object.assign` copies a key
fn assign<T>(slot: &mut Option<T>, value: Option<T>) {
    if value.is_some() {
        *slot = value;
    }
}

static DELAY_NOTICE: LazyLock<Regex> = LazyLock::new(|| {
    regex(
        r"WARNING MESSAGE ONLY|DO NOT NEED TO RESEND|has not yet been delivered|will keep trying|delivery attempts will continue|delivery (?:is|has been) delayed",
        "i",
    )
});

// A final bounce often quotes the last temporary reply ("(#4.4.1)" and then "I'm not going to
// try again"), so a 4.x.x status alone does not make a notice a delay
static GAVE_UP: LazyLock<Regex> = LazyLock::new(|| {
    regex(
        r"permanent error|given up|not going to try again|retry timeout exceeded|will not be retried|could not be delivered",
        "i",
    )
});
static TEMPORARY_REPLY: LazyLock<Regex> = LazyLock::new(|| regex(r"^4\d{2}[\s-]", ""));
static ORIGINAL_HEADERS_START: LazyLock<Regex> = LazyLock::new(|| regex(r"^\s*(Received|Message-ID|Date|From):", "im"));
static BOUNCE_SENDER_NAME: LazyLock<Regex> = LazyLock::new(|| {
    regex(
        r"Mail Delivery System|Mail Delivery Subsystem|Internet Mail Delivery|Mailer[- ]?Daemon|NDR Administrator",
        "i",
    )
});
static BOUNCE_SENDER_ADDRESS: LazyLock<Regex> =
    LazyLock::new(|| regex(r"mailer-?daemon@|postmaster@|^mailer-?daemon$", "i"));

/// Whether a notice the heuristics took for a failure reports a delay instead
fn is_delay_notice(text: &str, response: Option<&Response>) -> bool {
    if DELAY_NOTICE.is_match(text) {
        return true;
    }
    let status = response.and_then(|r| r.status.as_deref()).unwrap_or_default();
    let message = response.and_then(|r| r.message.as_deref()).unwrap_or_default();
    let temporary = status.starts_with("4.") || TEMPORARY_REPLY.is_match(message);
    temporary && !GAVE_UP.is_match(text)
}

/// Splits a message/delivery-status body into its header blocks (RFC 3464: one per message, then
/// one per recipient, with empty lines between)
fn delivery_status_blocks(content: &str) -> Vec<Headers> {
    let normalized = content.replace("\r\n", "\n").replace('\r', "\n");
    let mut blocks = Vec::new();
    let mut rest = normalized.as_str();
    loop {
        // split(/\n{2,}/)
        let (block, next) = match rest.find("\n\n") {
            Some(pos) => {
                let after = rest[pos..].trim_start_matches('\n');
                (&rest[..pos], Some(after))
            }
            None => (rest, None),
        };
        let headers = headers::decode(block);
        // A block of nothing but a continuation line decodes to one empty name, not a header
        if headers.has_named() {
            blocks.push(headers);
        }
        match next {
            Some(next) => rest = next,
            None => break,
        }
    }
    blocks
}

fn is_recipient_block(block: &Headers) -> bool {
    block.get("final-recipient").is_some() || block.get("original-recipient").is_some()
}

/// The first value of every name in the per-message blocks, with the position of its block
type MessageFields<'a> = HashMap<&'a str, (usize, &'a str)>;

fn message_fields(blocks: &[Headers]) -> MessageFields<'_> {
    let mut fields = HashMap::new();
    for (i, block) in blocks.iter().enumerate().filter(|(_, b)| !is_recipient_block(b)) {
        for (key, values) in block.iter() {
            if let Some(value) = values.first() {
                fields.entry(key).or_insert((i, value.as_str()));
            }
        }
    }
    fields
}

/// The first value of a name in the per-message fields merged with one per-recipient block, in
/// the order the blocks come in. A recipient is never paired with another one's diagnostic code
fn merged_first<'a>(fields: &MessageFields<'a>, recipient: Option<(usize, &'a Headers)>, key: &str) -> Option<&'a str> {
    let own = recipient.and_then(|(i, block)| Some((i, block.first(key)?)));
    match (fields.get(key).copied(), own) {
        (Some((m, value)), Some((r, _))) if m < r => Some(value),
        (_, Some((_, value))) | (Some((_, value)), None) => Some(value),
        (None, None) => None,
    }
}

fn parse_report<'a>(first: impl Fn(&str) -> Option<&'a str>) -> Report {
    let mut report = Report {
        recipient: first("final-recipient").map(|v| headers::split_address_type(v).1.to_string()),
        ..Report::default()
    };
    if !truthy(&report.recipient)
        && let Some(v) = first("original-recipient")
    {
        report.recipient = Some(headers::split_address_type(v).1.to_string());
    }
    report.action = first("action").map(str::to_string);
    if let Some(v) = first("diagnostic-code") {
        let (source, message) = headers::split_address_type(v);
        report.response = Some(Response {
            message: Some(message.to_string()),
            source: source.filter(|s| !s.is_empty()).map(str::to_string),
            status: None,
        });
    }
    if let Some(v) = first("status") {
        report.response.get_or_insert_with(Response::default).status = Some(v.to_string());
    }
    let mta = |key: &str| first(key).map(|v| headers::split_address_type(v).1.to_lowercase());
    report.remote_mta = mta("remote-mta");
    report.reporting_mta = mta("reporting-mta");
    report.queue_id = first("x-postfix-queue-id").map(|v| js::trim(v).to_string());
    report.message_id = first("x-original-message-id").map(|v| js::trim(v).to_string());
    report
}

/// A delivery report: its first recipient, as EmailEngine describes it, and every recipient
fn parse_delivery_status(content: &str) -> (Report, Vec<Report>) {
    let blocks = delivery_status_blocks(content);
    let fields = message_fields(&blocks);
    let all: Vec<Report> = blocks
        .iter()
        .enumerate()
        .filter(|(_, block)| is_recipient_block(block))
        .map(|recipient| parse_report(|key| merged_first(&fields, Some(recipient), key)))
        .collect();
    // A body naming no recipient is read whole
    let first = all
        .first()
        .cloned()
        .unwrap_or_else(|| parse_report(|key| merged_first(&fields, None, key)));
    (first, all)
}

/// The state of one run
struct Context<'a> {
    parsed: &'a Message,
    result: Detection,
    delivery_status: Option<&'a Attachment>,
    message_headers: Option<&'a Attachment>,
    original_message: Option<&'a Attachment>,
    zoho_original_message: Option<&'a Attachment>,
}

fn find_attachment<'a>(attachments: &'a [Attachment], content_type: &str) -> Option<&'a Attachment> {
    attachments
        .iter()
        .find(|a| a.mime_type.eq_ignore_ascii_case(content_type))
}

/// The decoded values of a header of the bounce
fn header_values<'a>(parsed: &'a Message, key: &'a str) -> impl Iterator<Item = String> + 'a {
    parsed
        .headers
        .iter()
        .filter(move |h| h.key == key)
        .map(|h| pe_mime::decode_words(&h.value))
}

fn has_header(parsed: &Message, key: &str) -> bool {
    parsed.headers.iter().any(|h| h.key == key)
}

impl Context<'_> {
    /// Applies a delivery report the way `Object.assign` merges it into the result
    fn apply_report(&mut self, (report, all): (Report, Vec<Report>)) {
        let result = &mut self.result;
        let mta = report.remote_mta.clone().or_else(|| report.reporting_mta.clone());
        assign(&mut result.recipient, report.recipient);
        assign(&mut result.action, report.action);
        assign(&mut result.response, report.response);
        assign(&mut result.mta, mta);
        assign(&mut result.queue_id, report.queue_id);
        assign(&mut result.message_id, report.message_id);
        assign(&mut result.remote_mta, report.remote_mta);
        assign(&mut result.reporting_mta, report.reporting_mta);
        if !all.is_empty() {
            result.reports = all;
        }
    }

    /// Exchange's header naming the failed recipients
    fn read_failed_recipients_header(&mut self) {
        let first = header_values(self.parsed, "x-failed-recipients")
            .flat_map(|v| {
                v.split(|c: char| c == ',' || js::is_space(c))
                    .map(|a| js::trim(a).to_string())
                    .collect::<Vec<_>>()
            })
            .find(|a| !a.is_empty());
        if let Some(first) = first {
            self.result.recipient = Some(first);
        }
    }

    /// Amazon WorkMail writes the report as text after "Technical report:"
    fn read_workmail_report(&mut self) {
        if !has_header(self.parsed, "x-mailer") {
            return;
        }
        let first = |key| header_values(self.parsed, key).next().unwrap_or_default();
        let x_mailer = first("x-mailer");
        let thread_topic = first("thread-topic");
        if js::trim(&x_mailer) != "Amazon WorkMail" || js::trim(&thread_topic) != "Undelivered Mail Returned to Sender"
        {
            return;
        }
        let text = self.parsed.text.as_deref().unwrap_or_default();
        let marker = "Technical report:";
        if let Some(pos) = text.find(marker) {
            let details = js::trim(&text[pos + marker.len()..]);
            self.apply_report(parse_delivery_status(headers::cap_str(details)));
        }
    }

    /// The delivery report and the returned message's headers (text/rfc822-headers)
    fn read_report_parts(&mut self) {
        if let Some(part) = self.delivery_status {
            self.apply_report(parse_delivery_status(&headers::cap_bytes(&part.content)));
        }
        if let Some(part) = self.message_headers {
            let entries = headers::decode(&headers::cap_bytes(&part.content));
            assign(&mut self.result.message_id, message_id_of(&entries));
            self.result.message_headers = Some(entries);
        }
    }

    /// The returned message, attached whole (message/rfc822)
    fn read_original_message(&mut self) {
        let Some(part) = self.original_message else {
            return;
        };
        let Ok(original) = pe_mime::parser::parse_keeping_attached_messages(&part.content) else {
            return;
        };
        // Decoded like the other header blocks, so every source gives the same unfolded values
        let block: Vec<&str> = original.header_lines.iter().map(|h| h.line.as_str()).collect();
        self.result.message_headers = Some(headers::decode(&block.join("\n")));
        if !truthy(&self.result.message_id)
            && let Some(id) = original.message_id.as_deref().filter(|id| !id.is_empty())
        {
            self.result.message_id = Some(id.to_string());
        }
        // Some bounces carry the report inside the returned message
        if self.delivery_status.is_none()
            && let Some(part) = find_attachment(&original.attachments, "message/delivery-status")
        {
            self.apply_report(parse_delivery_status(&headers::cap_bytes(&part.content)));
        }
        if self.message_headers.is_none()
            && let Some(part) = find_attachment(&original.attachments, "text/rfc822-headers")
        {
            let entries = headers::decode(&headers::cap_bytes(&part.content));
            assign(&mut self.result.message_id, message_id_of(&entries));
        }
    }

    /// Zoho attaches the returned message's headers as text/rfc822, written as an indented body
    fn read_zoho_original_message(&mut self) {
        let Some(part) = self.zoho_original_message else {
            return;
        };
        if !is_zoho_bounce(self.parsed) {
            return;
        }
        let Ok(original) = pe_mime::parser::parse_keeping_attached_messages(&part.content) else {
            return;
        };
        let text = original.text.as_deref().unwrap_or_default();
        if text.is_empty() || original.header_lines.iter().any(|h| !h.key.is_empty()) {
            return;
        }
        let content = unindent_lines(headers::cap_str(text));
        if !ORIGINAL_HEADERS_START.is_match(&content) {
            return;
        }
        let entries = headers::decode(&content);
        if entries.get("message-id").is_some() {
            assign(&mut self.result.message_id, message_id_of(&entries));
            self.result.message_headers = Some(entries);
        }
    }
}

/// Removes one space at the start of a line when no other space follows it, as
/// `.replace(/^ (?=[^ ])/gm, '')` does
fn unindent_lines(text: &str) -> String {
    let mut out = String::with_capacity(text.len());
    let mut line_start = true;
    let mut chars = text.chars().peekable();
    while let Some(c) = chars.next() {
        if line_start && c == ' ' && chars.peek().is_some_and(|n| *n != ' ') {
            line_start = false;
            continue;
        }
        line_start = matches!(c, '\n' | '\r' | '\u{2028}' | '\u{2029}');
        out.push(c);
    }
    out
}

fn message_id_of(entries: &Headers) -> Option<String> {
    entries.first("message-id").map(|v| js::trim(v).to_string())
}

/// A text/rfc822 part only counts in a bounce Zoho sent
fn is_zoho_bounce(parsed: &Message) -> bool {
    ["x-mailer", "from", "user-agent"]
        .iter()
        .any(|key| header_values(parsed, key).any(|v| v.as_bytes().windows(4).any(|w| w.eq_ignore_ascii_case(b"zoho"))))
}

/// The text the heuristics read: the message's text, or a part without a type, capped
fn heuristic_text(parsed: &Message) -> String {
    let text: Cow<'_, str> = match (&parsed.text, &parsed.html) {
        (Some(text), _) => Cow::Borrowed(text),
        (None, Some(html)) => Cow::Owned(html_to_text(html)),
        (None, None) => match parsed.attachments.iter().find(|a| a.mime_type.is_empty()) {
            Some(part) => String::from_utf8_lossy(&part.content),
            None => Cow::Borrowed(""),
        },
    };
    js::truncate_utf16(&text, MAX_TEXT_LENGTH).to_string()
}

/// Whether a message may be a bounce, which is when the text heuristics run: it comes from a
/// mailer daemon or a postmaster, it was sent automatically (Auto-Submitted other than `no`), or
/// it carries a delivery report
pub fn is_plausible_bounce(parsed: &Message) -> bool {
    if let Some(ParsedAddress::Mailbox(from)) = &parsed.from
        && (BOUNCE_SENDER_NAME.is_match(&from.name) || BOUNCE_SENDER_ADDRESS.is_match(&from.address))
    {
        return true;
    }
    let auto_submitted = parsed.headers.iter().filter(|h| h.key == "auto-submitted").any(|h| {
        let value = js::trim(h.value.split(';').next().unwrap_or_default());
        !value.is_empty() && !value.eq_ignore_ascii_case("no")
    });
    auto_submitted || find_attachment(&parsed.attachments, "message/delivery-status").is_some()
}

/// Parses a raw message for [`detect_parsed`]: attached messages stay attachments, as mailparser
/// keeps them, so the returned message is never mixed into the notice's text
pub fn parse(raw: &[u8]) -> Option<Message> {
    pe_mime::parser::parse_keeping_attached_messages(raw).ok()
}

/// Reads a raw message
pub fn detect(raw: &[u8]) -> Detection {
    parse(raw).map(|parsed| detect_parsed(&parsed)).unwrap_or_default()
}

/// Reads a parsed message. Parse it with [`parse`]: pe-mime's own `parse` puts an attached
/// message into the text when the bounce has no delivery report
pub fn detect_parsed(parsed: &Message) -> Detection {
    let attachments = &parsed.attachments;
    let mut ctx = Context {
        parsed,
        result: Detection::default(),
        delivery_status: find_attachment(attachments, "message/delivery-status"),
        message_headers: find_attachment(attachments, "text/rfc822-headers"),
        original_message: find_attachment(attachments, "message/rfc822"),
        zoho_original_message: find_attachment(attachments, "text/rfc822"),
    };
    ctx.read_failed_recipients_header();
    ctx.read_workmail_report();
    ctx.read_report_parts();
    ctx.read_original_message();
    ctx.read_zoho_original_message();

    // Only a claim the heuristics made is reconsidered as a delay below
    let structured_action = ctx.result.action.is_some();
    if is_plausible_bounce(parsed) {
        let text = heuristic_text(parsed);
        heuristics::run(&mut ctx.result, &text);
        if !truthy(&ctx.result.message_id)
            && !text.is_empty()
            && let Some(entries) = heuristics::embedded_headers(&text)
        {
            ctx.result.message_id = message_id_of(&entries);
            ctx.result.message_headers = Some(entries);
        }
        let result = &mut ctx.result;
        result.heuristics = true;
        if !structured_action
            && result.action.as_deref() == Some("failed")
            && is_delay_notice(&text, result.response.as_ref())
        {
            result.action = None;
            result.delay_notice = true;
        }
    }
    ctx.result
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn reads_the_recipient_block_after_the_message_block() {
        let (first, all) = parse_delivery_status(
            "Reporting-MTA: dns; mx.example.com\r\nArrival-Date: Mon, 10 Oct 2022 01:37:21 -0400\r\n\r\nFinal-Recipient: rfc822; user@example.com\r\nAction: failed\r\nStatus: 5.1.1\r\n",
        );
        assert_eq!(first.recipient.as_deref(), Some("user@example.com"));
        assert_eq!(first.action.as_deref(), Some("failed"));
        assert_eq!(first.reporting_mta.as_deref(), Some("mx.example.com"));
        assert_eq!(all.len(), 1);
    }

    #[test]
    fn does_not_pair_a_recipient_with_another_ones_diagnostic() {
        let (first, all) = parse_delivery_status(
            "Reporting-MTA: dns; mx.example.com\n\nFinal-Recipient: rfc822; first@example.com\nAction: failed\n\nFinal-Recipient: rfc822; second@example.com\nAction: failed\nDiagnostic-Code: smtp; 550 No such user",
        );
        assert_eq!(first.recipient.as_deref(), Some("first@example.com"));
        assert_eq!(first.response, None);
        assert_eq!(all[1].recipient.as_deref(), Some("second@example.com"));
        assert_eq!(
            all[1].response.as_ref().unwrap().message.as_deref(),
            Some("550 No such user")
        );
        assert_eq!(all[1].reporting_mta.as_deref(), Some("mx.example.com"));
    }

    #[test]
    fn merges_a_body_without_recipients_whole() {
        let (first, all) = parse_delivery_status("Reporting-MTA: dns; mx.example.com\n\nAction: failed");
        assert_eq!(first.action.as_deref(), Some("failed"));
        assert!(all.is_empty());
    }

    #[test]
    fn ignores_a_block_of_only_a_continuation_line() {
        let blocks = delivery_status_blocks("Reporting-MTA: dns; x\n\n  orphaned continuation\n\nAction: failed");
        assert_eq!(blocks.len(), 2);
    }

    #[test]
    fn tolerates_an_empty_body() {
        assert_eq!(parse_delivery_status(""), (Report::default(), Vec::new()));
    }

    #[test]
    fn unfolds_a_diagnostic_code() {
        let (first, _) = parse_delivery_status(
            "Final-Recipient: rfc822; user@example.com\r\nDiagnostic-Code: smtp; 550 5.1.1 <user@example.com>: Recipient address\r\n    rejected",
        );
        let response = first.response.unwrap();
        assert_eq!(response.source.as_deref(), Some("smtp"));
        assert_eq!(
            response.message.as_deref(),
            Some("550 5.1.1 <user@example.com>: Recipient address rejected")
        );
    }

    #[test]
    fn unindents_like_the_zoho_reader() {
        assert_eq!(unindent_lines(" a\n  b\n c\n \n"), "a\n  b\nc\n\n");
    }
}
