//! The message list fields of a fetched message

use pe_imap::Address;
use pe_imap::client::FetchedMessage;
use pe_store::MessageInfo;

fn display(address: &Address) -> &str {
    if address.name.is_empty() {
        &address.address
    } else {
        &address.name
    }
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
    })
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
    }
}
