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
        has_attachments: message.body_structure.is_some_and(|b| b.has_attachments()),
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
        assert!(super::summary(FetchedMessage::default()).is_none());
    }
}
