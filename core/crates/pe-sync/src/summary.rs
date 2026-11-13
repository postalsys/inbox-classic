//! The message list fields of a fetched message

use pe_imap::client::FetchedMessage;
use pe_imap::{Address, BodyStructure};
use pe_store::MessageInfo;

fn display(address: &Address) -> &str {
    if address.name.is_empty() {
        &address.address
    } else {
        &address.name
    }
}

/// Whether a message is a delivery report (RFC 3464): `multipart/report; report-type=delivery-status`, a bounce or a
/// delay notice the list marks before it is opened
pub(crate) fn is_delivery_report(structure: &BodyStructure) -> bool {
    structure.content_type.eq_ignore_ascii_case("multipart/report")
        && structure.parameters.iter().any(|(key, value)| {
            key.eq_ignore_ascii_case("report-type") && value.trim().eq_ignore_ascii_case("delivery-status")
        })
}

/// The message list fields of a message fetched with the summary items; None without a UID
pub(crate) fn summary(message: FetchedMessage) -> Option<MessageInfo> {
    let uid = message.uid?;
    let envelope = message.envelope.unwrap_or_default();
    let date = envelope.timestamp();
    let recipients: Vec<&str> = envelope.to.iter().map(display).filter(|d| !d.is_empty()).collect();
    let recipients = recipients.join(", ");
    // everyone the message names, for the search: names and addresses, decoded
    let people = |lists: [&Vec<Address>; 3]| {
        let words: Vec<&str> = lists
            .into_iter()
            .flatten()
            .flat_map(|a| [a.name.as_str(), a.address.as_str()])
            .filter(|part| !part.is_empty())
            .collect();
        words.join(" ")
    };
    let sender_people = people([&envelope.from, &envelope.sender, &envelope.reply_to]);
    let recipient_people = people([&envelope.to, &envelope.cc, &envelope.bcc]);
    let attachments = message
        .body_structure
        .as_ref()
        .map(|b| b.attachments())
        .unwrap_or_default();
    let bounce = message.body_structure.as_ref().is_some_and(is_delivery_report);
    let attachment_names: Vec<&str> = attachments.iter().filter_map(|part| part.filename()).collect();
    let attachment_names = attachment_names.join("\n");
    let attachment_count = attachments.len() as u32;
    // the recipients, for the address book
    let correspondents = [&envelope.to, &envelope.cc, &envelope.bcc]
        .into_iter()
        .flatten()
        .map(|a| (a.name.clone(), a.address.clone()))
        .collect();
    let from = envelope.from.into_iter().next().unwrap_or_default();
    // the ids it answers, from the References header fetched with it, and the provider's verdicts
    let references = message.headers.as_deref().map(references_of).unwrap_or_default();
    let auth_headers = message.headers.as_deref().map(auth_fields);
    Some(MessageInfo {
        uid,
        modseq: message.modseq,
        flags: message.flags.unwrap_or_default(),
        internal_date: message.internal_date,
        date,
        size: message.size,
        subject: envelope.subject.unwrap_or_default(),
        from_name: from.name,
        from_address: from.address,
        recipients,
        message_id: envelope.message_id,
        in_reply_to: envelope.in_reply_to,
        has_attachments: attachment_count > 0,
        sender_people,
        recipient_people,
        attachment_names,
        attachment_count,
        correspondents,
        references,
        gmail_thread: message.thread_id,
        thread_id: None,
        bounce,
        auth_headers,
    })
}

/// The header fields of the provider's verdicts on the sender: Authentication-Results (DMARC, DKIM, BIMI), and
/// BIMI-Location with the logo's address, which the receiving server adds (BIMI-Indicator, the logo itself, is left
/// out: it is large)
const AUTH_FIELDS: [&str; 3] = ["Authentication-Results", "BIMI-Location", "BIMI-Selector"];

/// The most of those fields kept for a message: a provider's results fit in far less
const AUTH_LIMIT: usize = 4 * 1024;

/// `fields` and the verdict fields, for a FETCH of header fields
pub(crate) fn with_auth_fields(mut fields: Vec<String>) -> Vec<String> {
    fields.extend(AUTH_FIELDS.iter().map(|field| field.to_string()));
    fields
}

/// The verdict fields of a header block, in their order, folded lines kept, whole fields only up to [`AUTH_LIMIT`]
pub(crate) fn auth_fields(header: &[u8]) -> String {
    let text = String::from_utf8_lossy(header);
    let mut kept = String::new();
    let mut field = String::new();
    let mut inside = false;
    let flush = |field: &mut String, kept: &mut String| {
        if !field.is_empty() && kept.len() + field.len() <= AUTH_LIMIT {
            kept.push_str(field);
        }
        field.clear();
    };
    for line in text.lines() {
        if line.starts_with([' ', '\t']) {
            if inside {
                field.push_str(line);
                field.push_str("\r\n");
            }
            continue;
        }
        flush(&mut field, &mut kept);
        inside = line
            .split_once(':')
            .is_some_and(|(name, _)| AUTH_FIELDS.iter().any(|known| name.trim().eq_ignore_ascii_case(known)));
        if inside {
            field.push_str(line);
            field.push_str("\r\n");
        }
    }
    flush(&mut field, &mut kept);
    kept
}

/// The Message-IDs of the References field of a header block (folded or not)
pub(crate) fn references_of(header: &[u8]) -> Vec<String> {
    let text = String::from_utf8_lossy(header);
    let mut value = String::new();
    let mut inside = false;
    for line in text.lines() {
        if line.starts_with([' ', '\t']) {
            if inside {
                value.push(' ');
                value.push_str(line.trim());
            }
            continue;
        }
        inside = line
            .split_once(':')
            .is_some_and(|(name, _)| name.trim().eq_ignore_ascii_case("References"));
        if inside {
            value.push_str(line.split_once(':').map_or("", |(_, v)| v));
        }
    }
    pe_store::parse_references(&value)
}

#[cfg(test)]
mod tests {
    use super::*;
    use pe_imap::Envelope;

    fn address(name: &str, address: &str) -> Address {
        Address {
            name: name.into(),
            address: address.into(),
        }
    }

    #[test]
    fn keeps_the_verdict_fields() {
        let header = b"References: <a@x>\r\nAuthentication-Results: mx.example.com;\r\n\tdmarc=pass header.from=shop.example\r\n\
                       BIMI-Location: v=BIMI1;\r\n l=https://shop.example/logo.svg\r\nX-Other: no\r\n\r\n";
        let kept = auth_fields(header);
        assert_eq!(
            kept,
            "Authentication-Results: mx.example.com;\r\n\tdmarc=pass header.from=shop.example\r\n\
             BIMI-Location: v=BIMI1;\r\n l=https://shop.example/logo.svg\r\n"
        );
        assert_eq!(auth_fields(b"References: <a@x>\r\n\r\n"), "");
        // whole fields only, at most the limit
        let long = format!("Authentication-Results: {}\r\n", "x".repeat(AUTH_LIMIT));
        let header = format!("Authentication-Results: first\r\n{long}");
        assert_eq!(auth_fields(header.as_bytes()), "Authentication-Results: first\r\n");
    }

    #[test]
    fn summaries() {
        let message = FetchedMessage {
            uid: Some(7),
            flags: Some(vec!["\\Seen".into()]),
            envelope: Some(Envelope {
                subject: Some("Hello".into()),
                date: Some("Mon, 6 Oct 2025 10:00:00 +0000".into()),
                from: vec![address("Andris", "andris@example.com")],
                to: vec![address("", "a@example.com"), address("Bob", "b@example.com")],
                ..Default::default()
            }),
            size: Some(1234),
            ..Default::default()
        };
        let summary = summary(message).unwrap();
        assert_eq!(summary.uid, 7);
        assert_eq!(summary.subject, "Hello");
        assert_eq!(summary.date, Some(1_759_744_800));
        assert_eq!(
            (summary.from_name.as_str(), summary.from_address.as_str()),
            ("Andris", "andris@example.com")
        );
        assert_eq!(summary.recipients, "a@example.com, Bob");
        assert!(!summary.has_attachments);
        assert_eq!(summary.sender_people, "Andris andris@example.com");
        assert_eq!(summary.recipient_people, "a@example.com Bob b@example.com");
        assert!(super::summary(FetchedMessage::default()).is_none());
    }

    #[test]
    fn everyone_and_the_files_for_the_search() {
        use pe_imap::BodyStructure;
        let part = |content_type: &str, disposition: Option<&str>, name: Option<&str>| BodyStructure {
            content_type: content_type.into(),
            disposition: disposition.map(String::from),
            disposition_parameters: name
                .map(|n| [("filename".to_string(), n.to_string())].into())
                .unwrap_or_default(),
            ..Default::default()
        };
        let mut unnamed = part("application/octet-stream", Some("attachment"), None);
        unnamed.parameters = [("name".to_string(), "data.bin".to_string())].into();
        let message = FetchedMessage {
            uid: Some(1),
            envelope: Some(Envelope {
                from: vec![address("Õie Sääsk", "oie@example.com")],
                cc: vec![address("Carol", "carol@example.com")],
                bcc: vec![address("", "hidden@example.com")],
                reply_to: vec![address("Lists", "list@example.com")],
                ..Default::default()
            }),
            body_structure: Some(BodyStructure {
                content_type: "multipart/mixed".into(),
                children: vec![
                    part("text/plain", None, None),
                    part("application/pdf", Some("attachment"), Some("Aruanne õhtu.pdf")),
                    unnamed,
                    part("application/pgp-signature", None, Some("signature.asc")),
                ],
                ..Default::default()
            }),
            ..Default::default()
        };
        let summary = summary(message).unwrap();
        assert_eq!(
            summary.sender_people,
            "Õie Sääsk oie@example.com Lists list@example.com"
        );
        assert_eq!(summary.recipient_people, "Carol carol@example.com hidden@example.com");
        // the signature travels with the message, it is no file of it
        assert_eq!(
            (summary.attachment_names.as_str(), summary.attachment_count),
            ("Aruanne õhtu.pdf\ndata.bin", 2)
        );
        assert!(summary.has_attachments);
        assert!(!summary.bounce);
    }

    #[test]
    fn delivery_reports_are_bounces() {
        use pe_imap::BodyStructure;
        let report = |content_type: &str, report_type: &str| FetchedMessage {
            uid: Some(1),
            body_structure: Some(BodyStructure {
                content_type: content_type.into(),
                parameters: [("report-type".to_string(), report_type.to_string())].into(),
                children: vec![BodyStructure {
                    content_type: "text/plain".into(),
                    ..Default::default()
                }],
                ..Default::default()
            }),
            ..Default::default()
        };
        assert!(summary(report("multipart/report", "delivery-status")).unwrap().bounce);
        assert!(summary(report("multipart/report", "Delivery-Status")).unwrap().bounce);
        // a read receipt and a feedback report are reports of something else
        assert!(
            !summary(report("multipart/report", "disposition-notification"))
                .unwrap()
                .bounce
        );
        assert!(!summary(report("multipart/mixed", "delivery-status")).unwrap().bounce);
        // without a structure: not known to be one
        assert!(
            !summary(FetchedMessage {
                uid: Some(2),
                ..Default::default()
            })
            .unwrap()
            .bounce
        );
    }
}
