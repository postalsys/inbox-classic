//! The text heuristics for bounces that carry no machine-readable report, run in EmailEngine's
//! order. Each only fills what the report parts (and the heuristics before it) left open.

use std::sync::LazyLock;

use regex::Regex;

use crate::detect::{Detection, Response, fill, truthy};
use crate::js::{self, regex};

macro_rules! pattern {
    ($name:ident, $source:expr, $flags:expr) => {
        static $name: LazyLock<Regex> = LazyLock::new(|| regex($source, $flags));
    };
}

pattern!(BLANK_LINE_OR_END, r"\r?\n\r?\n|$", "");
pattern!(ENHANCED_STATUS, r"[45]\d{2}[\s-](\d+\.\d+\.\d+)[\s-]", "");
pattern!(NEXT_TOKEN, r"^\s*(\S+)", "");
pattern!(
    HOST_SAID,
    r"<([^<>@\s]{1,256}@[^<>\s]{1,256})>:\s*host\s+([a-z0-9._-]+)(?:\[([^\]\s]{1,256})\])?\s+said:",
    "im"
);
pattern!(DELIVERY_FAILED, r"Delivery[^:]{0,100}failed[^:]{0,50}:", "im");
pattern!(AFFECTED, r"The following recipients were affected:", "im");
pattern!(LEADING_REPLY, r"^[ \t]*[45]\d{2}[\s-](\d+\.\d+\.\d+)[\s-]", "im");
pattern!(
    RECIPIENT_BLOCK,
    r"\n<([^<>@\s]{1,256}@[^<>\s]{1,256})>:[\s\r\n]{1,100}",
    ""
);
pattern!(QMAIL_STATUS, r"\(#(\d+\.\d+\.\d+)\)", "");
pattern!(
    UNDELIVERABLE_TO,
    r"The following message to <([^<>@\s]{1,256}@[^<>\s]{1,256})> was undeliverable",
    ""
);
pattern!(
    GOOGLE_LEGACY,
    r"Delivery to the following recipient(?:s)? failed permanently:\s+([^\s@]+@[^\s]+)",
    "i"
);
pattern!(
    TECHNICAL_DETAILS,
    r"Technical details of (?:permanent )?failure:\s*(.+?)(?:\n\n|-{3,}|Original message)",
    "is"
);
pattern!(ANY_STATUS, r"(\d+\.\d+\.\d+)", "");
pattern!(REASON, r"The reason for the problem:[ \t]*\r?\n(\d+\.\d+\.\d+)\s+", "");
pattern!(
    COULD_NOT_DELIVER_TO_ADDRESS,
    r"Your message could not be delivered to the following address:\s+<([^<>@\s]{1,256}@[^<>\s]{1,256})>",
    ""
);
// The original ends with `$` in multiline mode, which can not fail after `.*`: the dot stops only
// at a line terminator or the end, where `$` matches. Rust's `$` knows fewer line terminators, so
// it is left out
pattern!(REMOTE_HOST_SAID, r"Remote host said:\s*(.*)", "m");
pattern!(HOST_BLOCK, r"\shost\s+[^\n:]{1,256}:\s*(.+)", "s");
pattern!(EXIM_FAILED, r"The following address\(?es\)? failed:", "i");
pattern!(INDENTED, r"^\s{2,}", "");
pattern!(
    COULD_NOT_BE_DELIVERED_TO,
    r"Could not be delivered to:\s*<?([^\s<>\n]+@[^\s<>\n]+)>?",
    "i"
);
pattern!(
    PERMANENT_ERRORS,
    r"returned permanent errors?:\s*<?([^\s<>,\n]+@[^\s<>,\n]+)>?",
    "i"
);
pattern!(
    CARRIER_ERROR,
    r"(?:Message could not be delivered|Error:[^\n]{0,256}?(?:Invalid|No valid|not taken)[^\n]{0,512})",
    "i"
);
pattern!(RCPT_TO, r"RCPT TO:\s*<?([^\s<>\n]+@[^\s<>\n]+)>?", "i");
pattern!(GENERIC_CODE, r"\b(5[0-5]\d)\s*[-:]\s*([^\n]{10,100})", "");
pattern!(EMBEDDED_HEADERS, r"^(Received|Return-Path):", "im");
pattern!(
    SENT_COULD_NOT_BE_DELIVERED,
    r"A message that you sent could not be delivered",
    ""
);
pattern!(BLOCK_SEPARATOR, r"\r?\n\r?\n", "");
pattern!(LINE_SEPARATOR, r"\r?\n", "");

/// The heuristics in the order they run
const HEURISTICS: [fn(&mut Detection, &str); 16] = [
    host_said,
    delivery_failed_recipient,
    affected_recipients,
    leading_smtp_reply,
    recipient_block,
    undeliverable_message_to,
    google_legacy,
    reason_for_problem,
    remote_host_said,
    recipient_host_block,
    exim_failed_addresses,
    could_not_be_delivered_to,
    permanent_errors,
    carrier_error,
    rcpt_to,
    generic_smtp_code,
];

pub fn run(result: &mut Detection, text: &str) {
    for heuristic in HEURISTICS {
        heuristic(result, text);
    }
}

fn has_message(result: &Detection) -> bool {
    result.response.as_ref().is_some_and(|r| truthy(&r.message))
}

/// The text after `from` up to the next empty line or the end
fn up_to_blank_line(text: &str, from: usize) -> &str {
    let rest = &text[from..];
    let end = BLANK_LINE_OR_END.find(rest).map_or(rest.len(), |m| m.start());
    &rest[..end]
}

fn set_action_failed(result: &mut Detection) {
    fill(&mut result.action, || "failed".into());
}

fn set_message(result: &mut Detection, message: String) -> &mut Response {
    let response = result.response.get_or_insert_with(Response::default);
    fill(&mut response.message, || message);
    response
}

fn fill_enhanced_status(response: &mut Response, message: &str) {
    if !truthy(&response.status)
        && let Some(c) = ENHANCED_STATUS.captures(message)
    {
        response.status = Some(c[1].to_string());
    }
}

/// `<user@example.com>: host mx.example.com[192.0.2.4] said: 550 5.1.1 No such user`
fn host_said(result: &mut Detection, text: &str) {
    if truthy(&result.recipient) && has_message(result) {
        return;
    }
    let Some(c) = HOST_SAID.captures(text) else {
        return;
    };
    let end = c.get(0).map_or(0, |m| m.end());
    let message = js::collapse(up_to_blank_line(text, end));
    fill(&mut result.recipient, || js::trim(&c[1]).to_string());
    set_action_failed(result);
    let response = set_message(result, message.clone());
    fill_enhanced_status(response, &message);
    let host = js::trim(&c[2]).to_string();
    if !host.is_empty() {
        fill(&mut result.remote_mta, || host.clone());
        fill(&mut result.mta, || host);
    }
}

/// The address on the line after `Delivery to the following recipient failed permanently:`
fn delivery_failed_recipient(result: &mut Detection, text: &str) {
    if truthy(&result.recipient) {
        return;
    }
    if let Some(m) = DELIVERY_FAILED.find(text)
        && let Some(c) = NEXT_TOKEN.captures(&text[m.end()..])
        && c[1].contains('@')
    {
        result.recipient = Some(js::trim(&c[1]).to_string());
    }
}

/// The address after `The following recipients were affected:`
fn affected_recipients(result: &mut Detection, text: &str) {
    if truthy(&result.recipient) {
        return;
    }
    if let Some(m) = AFFECTED.find(text)
        && let Some(c) = NEXT_TOKEN.captures(&text[m.end()..])
        && c[1].contains('@')
    {
        result.recipient = Some(js::trim(&c[1]).to_string());
    }
}

/// An SMTP reply at the start of a line, `550-5.7.1 [192.0.2.1 11] Our system has detected ...`
fn leading_smtp_reply(result: &mut Detection, text: &str) {
    if has_message(result) {
        return;
    }
    let Some(m) = LEADING_REPLY.find(text) else {
        return;
    };
    let rest = up_to_blank_line(text, m.end());
    let message = js::collapse(&text[m.start()..m.end() + rest.len()]);
    set_action_failed(result);
    let response = set_message(result, message.clone());
    fill_enhanced_status(response, &message);
}

/// A line `<user@example.com>:` followed by the reply
fn recipient_block(result: &mut Detection, text: &str) {
    if truthy(&result.recipient) && has_message(result) {
        return;
    }
    let Some(c) = RECIPIENT_BLOCK.captures(text) else {
        return;
    };
    fill(&mut result.recipient, || c[1].to_string());
    let end = c.get(0).map_or(0, |m| m.end());
    let message = js::collapse(up_to_blank_line(text, end));
    set_action_failed(result);
    let response = set_message(result, message.clone());
    fill_enhanced_status(response, &message);
    if !truthy(&response.status)
        && let Some(s) = QMAIL_STATUS.captures(&message)
    {
        response.status = Some(s[1].to_string());
    }
}

/// `The following message to <user@example.com> was undeliverable`
fn undeliverable_message_to(result: &mut Detection, text: &str) {
    if !truthy(&result.recipient)
        && let Some(c) = UNDELIVERABLE_TO.captures(text)
    {
        result.recipient = Some(c[1].to_string());
    }
}

/// Google's format before 2015, the address and then `Technical details of permanent failure:`
fn google_legacy(result: &mut Detection, text: &str) {
    if truthy(&result.action) && has_message(result) {
        return;
    }
    let Some(c) = GOOGLE_LEGACY.captures(text) else {
        return;
    };
    fill(&mut result.recipient, || js::trim(&c[1]).to_string());
    set_action_failed(result);
    if let Some(t) = TECHNICAL_DETAILS.captures(text) {
        let details = &t[1];
        let response = set_message(result, js::collapse(details));
        if !truthy(&response.status)
            && let Some(s) = ANY_STATUS.captures(details)
        {
            response.status = Some(s[1].to_string());
        }
    }
}

/// `The reason for the problem:` and on the next line `5.1.0 - Unknown address error ...`
fn reason_for_problem(result: &mut Detection, text: &str) {
    if has_message(result) {
        return;
    }
    let Some(c) = REASON.captures(text) else {
        return;
    };
    let status = c[1].to_string();
    let end = c.get(0).map_or(0, |m| m.end());
    let message = format!("{status} {}", js::collapse(up_to_blank_line(text, end)));
    set_action_failed(result);
    let response = set_message(result, message);
    fill(&mut response.status, || status);
}

/// `Your message could not be delivered to the following address: <user@example.com>` and later
/// `Remote host said: ...`
fn remote_host_said(result: &mut Detection, text: &str) {
    if truthy(&result.recipient) || has_message(result) {
        return;
    }
    let Some(c) = COULD_NOT_DELIVER_TO_ADDRESS.captures(text) else {
        return;
    };
    fill(&mut result.recipient, || c[1].to_string());
    if let Some(r) = REMOTE_HOST_SAID.captures(text) {
        set_message(result, js::collapse(&r[1]));
    }
}

/// The recipient's own block of an MTA's notice, when a report gave the recipient and a status
/// but no reply: `host mx1.example.com [192.0.2.1]: 550 5.1.1 <user@example.com>: ...`
fn recipient_host_block(result: &mut Detection, text: &str) {
    let Some(recipient) = result.recipient.clone().filter(|r| !r.is_empty()) else {
        return;
    };
    if result.response.is_none() || has_message(result) || !SENT_COULD_NOT_BE_DELIVERED.is_match(text) {
        return;
    }
    for block in BLOCK_SEPARATOR.split(text) {
        if !block.contains(recipient.as_str()) {
            continue;
        }
        if let Some(c) = HOST_BLOCK.captures(block) {
            let message = js::collapse(&c[1]);
            if !message.is_empty() {
                result.response.get_or_insert_with(Response::default).message = Some(message);
                break;
            }
        }
    }
}

/// The indented lines after the recipient's line in an Exim block
fn exim_message_lines<'a>(block: &'a str, recipient: &str) -> Vec<&'a str> {
    let mut found = false;
    let mut lines = Vec::new();
    for line in LINE_SEPARATOR.split(block) {
        if !found {
            found = line.contains(recipient);
        } else if INDENTED.is_match(line) && !js::trim(line).is_empty() {
            lines.push(js::trim(line));
        } else {
            break;
        }
    }
    lines
}

/// Exim's `The following address(es) failed:`, the address indented and the reason more so
fn exim_failed_addresses(result: &mut Detection, text: &str) {
    let Some(recipient) = result.recipient.clone().filter(|r| !r.is_empty()) else {
        return;
    };
    if has_message(result) || !EXIM_FAILED.is_match(text) {
        return;
    }
    for block in BLOCK_SEPARATOR.split(text) {
        if !block.contains(recipient.as_str()) {
            continue;
        }
        let message = js::collapse(&exim_message_lines(block, &recipient).join(" "));
        if !message.is_empty() {
            result.response.get_or_insert_with(Response::default).message = Some(message);
            set_action_failed(result);
            break;
        }
    }
}

/// `Could not be delivered to: <user@example.com>`, as KDDI and other Japanese carriers write
fn could_not_be_delivered_to(result: &mut Detection, text: &str) {
    if !truthy(&result.recipient)
        && let Some(c) = COULD_NOT_BE_DELIVERED_TO.captures(text)
    {
        result.recipient = Some(js::trim(&c[1]).to_string());
        set_action_failed(result);
    }
}

/// `The following recipients returned permanent errors: user@example.com`
fn permanent_errors(result: &mut Detection, text: &str) {
    if !truthy(&result.recipient)
        && let Some(c) = PERMANENT_ERRORS.captures(text)
    {
        result.recipient = Some(js::trim(&c[1]).to_string());
        set_action_failed(result);
    }
}

/// A mobile carrier's `Message could not be delivered to mobile.` or `Error: No valid recipients`
fn carrier_error(result: &mut Detection, text: &str) {
    if has_message(result) {
        return;
    }
    if let Some(m) = CARRIER_ERROR.find(text) {
        set_action_failed(result);
        set_message(result, js::collapse(m.as_str()));
    }
}

/// `RCPT TO: user@example.com`
fn rcpt_to(result: &mut Detection, text: &str) {
    if !truthy(&result.recipient)
        && let Some(c) = RCPT_TO.captures(text)
    {
        result.recipient = Some(js::trim(&c[1]).to_string());
    }
}

/// Any 5xx reply, `550 - Requested action not taken: no such user here`
fn generic_smtp_code(result: &mut Detection, text: &str) {
    if has_message(result) {
        return;
    }
    let Some(c) = GENERIC_CODE.captures(text) else {
        return;
    };
    set_action_failed(result);
    let details = &c[2];
    let response = set_message(result, format!("{} {}", &c[1], js::trim(details)));
    if !truthy(&response.status)
        && let Some(s) = ANY_STATUS.captures(details)
    {
        response.status = Some(s[1].to_string());
    }
}

/// The headers of the returned message when a notice quotes them inline, from the first
/// `Received:` or `Return-Path:` line to the next empty line
pub fn embedded_headers(text: &str) -> Option<crate::headers::Headers> {
    let m = EMBEDDED_HEADERS.find(text)?;
    let rest = up_to_blank_line(text, m.end());
    let block = js::trim(&text[m.start()..m.end() + rest.len()]);
    let headers = crate::headers::decode(crate::headers::cap_str(block));
    headers
        .get("message-id")
        .is_some_and(|v| !v.is_empty())
        .then_some(headers)
}
