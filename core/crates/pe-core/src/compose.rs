//! New messages, replies and forwards: the drafts the compose window starts from, and the message a draft becomes
//! when it is sent. Recipients the user typed are parsed here, never in the window.

use std::path::PathBuf;

use pe_mime::Address;
use pe_mime::parser::{self, ParsedAddress, html_to_text, parse_addresses, text_addresses};
use pe_smtp::{Attachment, Message};
use pe_store::AccountSettings;

/// What the compose window sends
#[derive(Debug, Clone, PartialEq, Eq, Default)]
pub struct Outgoing {
    /// Address lists as typed: `Name <a@b.c>, d@e.f`
    pub to: String,
    pub cc: String,
    pub bcc: String,
    pub subject: String,
    pub text: String,
    /// Files to attach
    pub attachments: Vec<PathBuf>,
    pub in_reply_to: Option<String>,
    pub references: Vec<String>,
}

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum DraftKind {
    Reply,
    ReplyAll,
    Forward,
}

/// A message to start writing from
#[derive(Debug, Clone, PartialEq, Eq, Default)]
pub struct Draft {
    pub to: String,
    pub cc: String,
    pub subject: String,
    pub text: String,
    pub in_reply_to: Option<String>,
    pub references: Vec<String>,
}

#[derive(Debug, Clone, PartialEq, Eq)]
pub enum ComposeError {
    NoRecipients,
    /// An address without an `@`
    BadAddress(String),
    /// An attachment that could not be read
    Attachment(PathBuf, String),
}

impl std::fmt::Display for ComposeError {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        match self {
            ComposeError::NoRecipients => f.write_str("the message has no recipients"),
            ComposeError::BadAddress(address) => write!(f, "{address:?} is not an e-mail address"),
            ComposeError::Attachment(path, error) => write!(f, "{} could not be read: {error}", path.display()),
        }
    }
}

/// Recipients as typed, checked to be addresses
fn recipients(text: &str) -> Result<Vec<ParsedAddress>, ComposeError> {
    let list = parse_addresses(text);
    for mailbox in list.iter().flat_map(ParsedAddress::mailboxes) {
        let address = mailbox.address.trim();
        let valid = address
            .rsplit_once('@')
            .is_some_and(|(user, domain)| !user.is_empty() && !domain.is_empty());
        if !valid {
            let shown = if address.is_empty() {
                mailbox.name.clone()
            } else {
                address.to_string()
            };
            return Err(ComposeError::BadAddress(shown));
        }
    }
    Ok(list)
}

/// What can be checked before a message is queued: the recipients are addresses, the files are there
pub fn check(outgoing: &Outgoing) -> Result<(), ComposeError> {
    let lists = [
        recipients(&outgoing.to)?,
        recipients(&outgoing.cc)?,
        recipients(&outgoing.bcc)?,
    ];
    if lists.iter().flatten().all(|a| a.mailboxes().is_empty()) {
        return Err(ComposeError::NoRecipients);
    }
    for path in &outgoing.attachments {
        if !path.is_file() {
            return Err(ComposeError::Attachment(path.clone(), "there is no such file".into()));
        }
    }
    Ok(())
}

/// The message of `outgoing` from the account, at `now`, its attachments read
pub fn message(account: &AccountSettings, outgoing: &Outgoing, now: i64) -> Result<Message, ComposeError> {
    let to = recipients(&outgoing.to)?;
    let cc = recipients(&outgoing.cc)?;
    let bcc = recipients(&outgoing.bcc)?;
    if to.iter().chain(&cc).chain(&bcc).all(|a| a.mailboxes().is_empty()) {
        return Err(ComposeError::NoRecipients);
    }
    let mut attachments = Vec::new();
    for path in &outgoing.attachments {
        let content = std::fs::read(path).map_err(|e| ComposeError::Attachment(path.clone(), e.to_string()))?;
        let filename = path
            .file_name()
            .map(|n| n.to_string_lossy().into_owned())
            .unwrap_or_default();
        attachments.push(Attachment {
            content_type: pe_smtp::mime_types::mime_type(&filename).to_string(),
            filename,
            content,
            content_id: None,
        });
    }
    Ok(Message {
        from: Address {
            name: account.name.clone(),
            address: account.email.clone(),
        },
        to,
        cc,
        bcc,
        subject: outgoing.subject.clone(),
        text: Some(outgoing.text.clone()),
        attachments,
        in_reply_to: outgoing.in_reply_to.clone(),
        references: outgoing.references.clone(),
        date: now,
        ..Default::default()
    })
}

/// An address list to edit: what parses back into the same addresses. A name with anything but letters, digits
/// and spaces is quoted, so `Smith, John` stays one name and not two recipients.
fn editable(list: &[ParsedAddress]) -> String {
    let mailbox = |m: &Address| {
        if m.name.is_empty() {
            return m.address.clone();
        }
        let plain = m
            .name
            .chars()
            .all(|c| c.is_alphanumeric() || c == ' ' || c == '_' || c == '-' || c == '.');
        let name = if plain {
            m.name.clone()
        } else {
            pe_smtp::encoding::quote_string(&m.name)
        };
        format!("{name} <{}>", m.address)
    };
    let items: Vec<String> = list.iter().flat_map(ParsedAddress::mailboxes).map(mailbox).collect();
    items.join(", ")
}

/// `Re: ` or `Fw: ` in front, unless the subject already has it
fn prefixed(prefix: &str, subject: &str) -> String {
    let trimmed = subject.trim();
    let already = trimmed
        .get(..prefix.len())
        .is_some_and(|start| start.eq_ignore_ascii_case(prefix))
        || (prefix == "Fw: " && trimmed.get(..4).is_some_and(|s| s.eq_ignore_ascii_case("fwd:")));
    if already {
        trimmed.to_string()
    } else {
        format!("{prefix}{trimmed}")
    }
}

/// The addresses of `list` but `own`
fn others(list: &[ParsedAddress], own: &str) -> Vec<ParsedAddress> {
    list.iter()
        .flat_map(ParsedAddress::mailboxes)
        .filter(|m| !m.address.eq_ignore_ascii_case(own))
        .map(|m| ParsedAddress::Mailbox(m.clone()))
        .collect()
}

/// The draft of a reply, a reply to all or a forward of the message in `source`, for the account `own` address
pub fn draft(source: &[u8], kind: DraftKind, own: &str, date: Option<i64>) -> Draft {
    let Ok(message) = parser::parse(source) else {
        return Draft::default();
    };
    let original = message
        .text
        .clone()
        .or_else(|| message.html.as_deref().map(html_to_text))
        .unwrap_or_default();
    let from = message.from.as_slice();
    let sender = if message.reply_to.is_empty() {
        from
    } else {
        &message.reply_to
    };
    let header = format!(
        "\n\n----- Original Message -----\nFrom: {}\nTo: {}\n{}Sent: {}\nSubject: {}\n\n",
        text_addresses(from),
        text_addresses(&message.to),
        if message.cc.is_empty() {
            String::new()
        } else {
            format!("Cc: {}\n", text_addresses(&message.cc))
        },
        date.map(pe_smtp::message::format_date).unwrap_or_default(),
        message.subject.as_deref().unwrap_or_default(),
    );
    let mut draft = Draft::default();
    match kind {
        DraftKind::Reply | DraftKind::ReplyAll => {
            draft.to = editable(sender);
            if kind == DraftKind::ReplyAll {
                let mut to = others(sender, own);
                to.extend(others(&message.to, own));
                draft.to = editable(&to);
                draft.cc = editable(&others(&message.cc, own));
            }
            draft.subject = prefixed("Re: ", message.subject.as_deref().unwrap_or_default());
            let quoted: Vec<String> = original.lines().map(|line| format!("> {line}")).collect();
            draft.text = format!("{header}{}\n", quoted.join("\n"));
            draft.in_reply_to = message.message_id.clone();
            draft.references = message.reference_ids();
            draft.references.extend(message.message_id.clone());
        }
        DraftKind::Forward => {
            draft.subject = prefixed("Fw: ", message.subject.as_deref().unwrap_or_default());
            draft.text = format!("{header}{original}");
        }
    }
    draft
}

#[cfg(test)]
mod tests {
    use super::*;

    const ORIGINAL: &[u8] = b"From: Ann <ann@example.com>\r\nTo: me@example.com, bob@example.com\r\nCc: carl@example.com\r\nSubject: Plans\r\nMessage-ID: <m2@example.com>\r\nReferences: <m1@example.com>\r\n\r\nLet's meet.\r\nTomorrow?\r\n";

    fn account() -> AccountSettings {
        AccountSettings {
            name: "Me".into(),
            email: "me@example.com".into(),
            username: "me".into(),
            imap_host: "imap.example.com".into(),
            imap_port: 993,
            imap_security: pe_store::Security::Tls,
            smtp_host: "smtp.example.com".into(),
            smtp_port: 465,
            smtp_security: pe_store::Security::Tls,
        }
    }

    #[test]
    fn replies() {
        let reply = draft(ORIGINAL, DraftKind::Reply, "me@example.com", Some(1_759_744_800));
        assert_eq!(reply.to, "Ann <ann@example.com>");
        assert_eq!(reply.cc, "");
        assert_eq!(reply.subject, "Re: Plans");
        assert!(reply.text.contains("> Let's meet.\n> Tomorrow?"), "{}", reply.text);
        assert!(reply.text.contains("Sent: Mon, 06 Oct 2025 10:00:00 +0000"));
        assert_eq!(reply.in_reply_to.as_deref(), Some("<m2@example.com>"));
        assert_eq!(reply.references, ["<m1@example.com>", "<m2@example.com>"]);

        let all = draft(ORIGINAL, DraftKind::ReplyAll, "ME@example.com", None);
        assert_eq!(all.to, "Ann <ann@example.com>, bob@example.com");
        assert_eq!(all.cc, "carl@example.com");

        // names that would read as more recipients are quoted, and parse back to the same addresses
        let tricky = b"From: \"Smith, John\" <j@x.com>\r\nReply-To: \"a@b.c, <evil@y.com>\" <real@x.com>\r\nSubject: x\r\n\r\nx\r\n";
        let reply = draft(tricky, DraftKind::Reply, "me@example.com", None);
        let parsed = parse_addresses(&reply.to);
        assert_eq!(parsed.len(), 1, "{}", reply.to);
        assert_eq!(parsed[0].mailboxes()[0].address, "real@x.com");
        assert_eq!(parsed[0].mailboxes()[0].name, "a@b.c, <evil@y.com>");
        let smith = draft(&tricky[..tricky.len()], DraftKind::ReplyAll, "real@x.com", None);
        assert_eq!(
            parse_addresses(&smith.to).len(),
            0,
            "own address left out: {}",
            smith.to
        );

        let forward = draft(ORIGINAL, DraftKind::Forward, "me@example.com", None);
        assert_eq!((forward.to.as_str(), forward.subject.as_str()), ("", "Fw: Plans"));
        assert!(forward.text.contains("Let's meet.\nTomorrow?"));
        assert_eq!(forward.in_reply_to, None);

        assert_eq!(prefixed("Re: ", "RE: x"), "RE: x");
        assert_eq!(prefixed("Fw: ", "Fwd: x"), "Fwd: x");
    }

    #[test]
    fn messages_from_drafts() {
        let mut outgoing = Outgoing {
            to: "Bob <bob@example.com>, carl@example.com".into(),
            subject: "Hi".into(),
            text: "Hello".into(),
            ..Default::default()
        };
        let message = message(&account(), &outgoing, 0).unwrap();
        assert_eq!(message.from.address, "me@example.com");
        assert_eq!(message.to.len(), 2);

        outgoing.to = "not an address".into();
        assert!(matches!(
            self::message(&account(), &outgoing, 0),
            Err(ComposeError::BadAddress(_))
        ));
        outgoing.to = String::new();
        assert_eq!(self::message(&account(), &outgoing, 0), Err(ComposeError::NoRecipients));
        outgoing.to = "a@b.c".into();
        outgoing.attachments = vec![PathBuf::from("/no/such/file.pdf")];
        assert!(matches!(
            self::message(&account(), &outgoing, 0),
            Err(ComposeError::Attachment(..))
        ));
    }
}
