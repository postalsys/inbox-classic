//! New messages, replies and forwards: the drafts the compose window starts from, and the message a draft becomes
//! when it is sent. Recipients the user typed are parsed here, never in the window.

use std::path::PathBuf;

use pe_html::InlineImage;
use pe_mime::Address;
use pe_mime::parser::{self, ParsedAddress, html_to_text, parse_addresses, text_addresses, text_to_html};
use pe_smtp::{Attachment, Message};
use pe_store::AccountSettings;

/// Why a draft can not be saved
pub(crate) const NO_DRAFTS: &str = "the account has no Drafts folder to save the message in";

/// The Drafts folder of an account, where drafts are saved
pub(crate) fn drafts_folder(
    store: &pe_store::Store,
    account: pe_store::AccountId,
) -> pe_store::Result<Option<pe_store::Folder>> {
    store.special_folder(account, "\\Drafts")
}

/// `value` when it is one Message-ID of the form `<local@domain>`, as drafts are told apart by: anything looser
/// (a draft from elsewhere with `Message-ID: <`) would match other drafts
pub(crate) fn draft_id(value: &str) -> Option<String> {
    let value = value.trim();
    let [id] = parser::message_ids(value).try_into().ok()?;
    let inner = id.strip_prefix('<')?.strip_suffix('>')?;
    let well_formed = inner
        .split_once('@')
        .is_some_and(|(local, domain)| !local.is_empty() && !domain.is_empty() && !domain.contains('@'));
    (id == value && well_formed && !inner.chars().any(|c| c.is_whitespace() || c.is_control())).then_some(id)
}

/// The images of a message its HTML shows by `cid:`
pub(crate) fn inline_images(message: &parser::Message) -> Vec<InlineImage<'_>> {
    message
        .attachments
        .iter()
        .filter_map(|a| {
            Some(InlineImage {
                content_id: a.content_id.as_deref()?,
                mime_type: &a.mime_type,
                data: &a.content,
            })
        })
        .collect()
}

/// What the compose window sends
#[derive(Debug, Clone, PartialEq, Eq, Default)]
pub struct Outgoing {
    /// Address lists as typed: `Name <a@b.c>, d@e.f`
    pub to: String,
    pub cc: String,
    pub bcc: String,
    pub subject: String,
    /// The plain text, for a message written without the editor; ignored when `html` is there
    pub text: String,
    /// What was written in the editor, as HTML; the text part is made from it
    pub html: Option<String>,
    /// The quoted message of the draft ([`Draft::quote`]), added after `html`
    pub quote: Option<String>,
    /// Files to attach
    pub attachments: Vec<PathBuf>,
    pub in_reply_to: Option<String>,
    pub references: Vec<String>,
    /// The Message-ID of the draft this was saved as before (see [`Draft::message_id`]): it keeps the ID, and the
    /// saved copy is replaced on the next save and removed once the message is sent
    pub message_id: Option<String>,
    /// The account whose Drafts holds that saved copy, when it is not the one this goes from (From changed after it
    /// was saved): the copy there goes once this account has the message, so it is never in neither
    pub draft_account: Option<pe_store::AccountId>,
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
    /// The message replied to or forwarded, as sanitized HTML with its header block (see [`pe_html::quote_html`])
    pub quote: String,
    /// The quote starts folded behind "..." (a reply), or open (a forward, where it is what is sent)
    pub quote_folded: bool,
    pub in_reply_to: Option<String>,
    pub references: Vec<String>,
    pub bcc: String,
    /// What was written, as sanitized HTML, for a saved draft opened again; empty for a new message
    pub body: String,
    /// The files of a saved draft opened again, written out to be attached again
    pub attachments: Vec<PathBuf>,
    /// The Message-ID of a saved draft opened again, for [`Outgoing::message_id`]
    pub message_id: Option<String>,
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
    build(account, outgoing, now, [to, cc, bcc])
}

/// A draft to keep in the Drafts folder: as [`message`], with the recipients as far as they are typed (none, or
/// not yet addresses) and Bcc kept in the header, to be there when the draft is opened again
pub fn draft_message(account: &AccountSettings, outgoing: &Outgoing, now: i64) -> Result<Message, ComposeError> {
    let lists = [&outgoing.to, &outgoing.cc, &outgoing.bcc].map(|list| parse_addresses(list));
    let mut message = build(account, outgoing, now, lists)?;
    message.keep_bcc = true;
    Ok(message)
}

fn build(
    account: &AccountSettings,
    outgoing: &Outgoing,
    now: i64,
    [to, cc, bcc]: [Vec<ParsedAddress>; 3],
) -> Result<Message, ComposeError> {
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
    let (text, html) = match &outgoing.html {
        Some(written) => {
            let domain = account
                .email
                .rsplit_once('@')
                .map_or("inboxclassic.invalid", |(_, d)| d);
            let (html, pictures) = pe_html::outgoing_html(written, outgoing.quote.as_deref(), domain);
            attachments.extend(pictures.into_iter().map(|picture| Attachment {
                filename: String::new(),
                content_type: picture.mime_type,
                content: picture.data,
                content_id: Some(picture.content_id),
            }));
            (html_to_text(&html).trim_start().to_string(), Some(html))
        }
        None => (outgoing.text.clone(), None),
    };
    Ok(Message {
        from: Address {
            name: account.name.clone(),
            address: account.email.clone(),
        },
        to,
        cc,
        bcc,
        subject: outgoing.subject.clone(),
        text: Some(text),
        html,
        attachments,
        in_reply_to: outgoing.in_reply_to.clone(),
        references: outgoing.references.clone(),
        date: now,
        message_id: outgoing.message_id.clone().unwrap_or_default(),
        ..Default::default()
    })
}

/// A saved draft to go on writing: its fields, what was written as the body, and its attachments (name to save
/// them under, content) for the caller to write out
pub fn reopen(source: &[u8]) -> (Draft, Vec<(String, Vec<u8>)>) {
    let Ok(message) = parser::parse(source) else {
        return (Draft::default(), Vec::new());
    };
    let images = inline_images(&message);
    let body = match (&message.html, &message.text) {
        (Some(html), _) => pe_html::draft_body(html, &images),
        (None, Some(text)) => text_to_html(text),
        (None, None) => String::new(),
    };
    let draft = Draft {
        to: editable(&message.to),
        cc: editable(&message.cc),
        bcc: editable(&message.bcc),
        subject: message.subject.clone().unwrap_or_default(),
        body,
        in_reply_to: message
            .in_reply_to
            .as_deref()
            .and_then(|r| parser::message_ids(r).pop()),
        references: message.reference_ids(),
        message_id: message.message_id.as_deref().and_then(draft_id),
        ..Default::default()
    };
    // the pictures of the HTML are in the body already
    let files = message
        .attachments
        .into_iter()
        .filter(|a| !a.related)
        .map(|a| (a.safe_filename(), a.content))
        .collect();
    (draft, files)
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
    let from = message.from.as_slice();
    let sender = if message.reply_to.is_empty() {
        from
    } else {
        &message.reply_to
    };
    let reply = kind != DraftKind::Forward;
    let images = inline_images(&message);
    let body = match (&message.html, &message.text) {
        (Some(html), _) => html.clone(),
        (None, Some(text)) => text_to_html(text),
        (None, None) => String::new(),
    };
    let (to, cc) = (text_addresses(&message.to), text_addresses(&message.cc));
    let sent = date.map(pe_smtp::message::format_date).unwrap_or_default();
    let header = [
        ("From", text_addresses(from)),
        ("To", to),
        ("Cc", cc),
        ("Sent", sent),
        ("Subject", message.subject.clone().unwrap_or_default()),
    ];
    let mut draft = Draft {
        quote: pe_html::quote_html(&header, &body, &images, reply),
        quote_folded: reply,
        ..Default::default()
    };
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
            draft.in_reply_to = message.message_id.clone();
            draft.references = message.reference_ids();
            draft.references.extend(message.message_id.clone());
        }
        DraftKind::Forward => {
            draft.subject = prefixed("Fw: ", message.subject.as_deref().unwrap_or_default());
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
            auth: pe_store::Auth::Password,
        }
    }

    #[test]
    fn drafts_are_told_apart_by_a_whole_message_id() {
        assert_eq!(draft_id(" <a.b@example.com> ").as_deref(), Some("<a.b@example.com>"));
        for loose in [
            "<",
            "<>",
            "@",
            "<@>",
            "<a@>",
            "<@b>",
            "a@b",
            "<a@b> <c@d>",
            "<a b@c>",
            "x<a@b>",
            "<a@b@c>",
        ] {
            assert_eq!(draft_id(loose), None, "{loose}");
        }
        // one from elsewhere opens with a new ID on its first save
        let (draft, _) = reopen(b"Message-ID: <\r\nSubject: planted\r\n\r\nx\r\n");
        assert_eq!(draft.message_id, None);
    }

    #[test]
    fn a_draft_is_kept_as_far_as_it_is_written() {
        let outgoing = Outgoing {
            to: "ann@".into(),
            bcc: "Boss <boss@example.com>".into(),
            subject: "Half".into(),
            text: "not done".into(),
            message_id: Some("<d1@example.com>".into()),
            ..Default::default()
        };
        // not to send like this, but to keep
        assert_eq!(
            message(&account(), &outgoing, 0).unwrap_err(),
            ComposeError::BadAddress("ann@".into())
        );
        assert_eq!(
            message(&account(), &Outgoing::default(), 0).unwrap_err(),
            ComposeError::NoRecipients
        );
        let built = pe_smtp::build(&draft_message(&account(), &outgoing, 0).unwrap());
        let raw = String::from_utf8(built.raw).unwrap();
        assert!(raw.contains("Bcc: Boss <boss@example.com>\r\n"), "{raw}");
        assert!(raw.contains("Message-ID: <d1@example.com>\r\n"), "{raw}");
        assert!(draft_message(&account(), &Outgoing::default(), 0).is_ok());

        // opened again
        let (draft, files) = reopen(raw.as_bytes());
        assert_eq!(
            (draft.to.as_str(), draft.bcc.as_str(), draft.subject.as_str()),
            ("ann@", "Boss <boss@example.com>", "Half")
        );
        assert!(draft.body.contains("not done"), "{}", draft.body);
        assert_eq!(draft.message_id.as_deref(), Some("<d1@example.com>"));
        assert!(files.is_empty());
    }

    #[test]
    fn replies() {
        let reply = draft(ORIGINAL, DraftKind::Reply, "me@example.com", Some(1_759_744_800));
        assert_eq!(reply.to, "Ann <ann@example.com>");
        assert_eq!(reply.cc, "");
        assert_eq!(reply.subject, "Re: Plans");
        assert!(reply.quote.starts_with("<blockquote"), "{}", reply.quote);
        assert!(
            reply.quote.contains("Let's meet.") && reply.quote.contains("Tomorrow?"),
            "{}",
            reply.quote
        );
        assert!(reply.quote.contains("<b>Sent:</b> Mon, 06 Oct 2025 10:00:00 +0000"));
        assert!(reply.quote_folded);
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
        assert!(forward.quote.contains("Let's meet.") && !forward.quote.contains("<blockquote"));
        assert!(!forward.quote_folded);
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

    #[test]
    fn html_messages() {
        let reply = draft(ORIGINAL, DraftKind::Reply, "me@example.com", None);
        let picture = format!("data:image/gif;base64,{}", "R0lGODlhAQABAAAAACw=");
        let outgoing = Outgoing {
            to: reply.to.clone(),
            subject: reply.subject.clone(),
            html: Some(format!(
                "<div>Yes, <b>tomorrow</b>.</div><img src=\"{picture}\"><script>x()</script>"
            )),
            quote: Some(reply.quote.clone()),
            ..Default::default()
        };
        let message = message(&account(), &outgoing, 0).unwrap();
        let html = message.html.as_deref().unwrap();
        assert!(html.starts_with("<div>Yes, <b>tomorrow</b>.</div>"), "{html}");
        assert!(html.contains("Let's meet.") && !html.contains("<script"), "{html}");
        // the plain text part says the same
        let text = message.text.as_deref().unwrap();
        assert!(text.starts_with("Yes, tomorrow."), "{text}");
        assert!(text.contains("Let's meet."), "{text}");
        // the picture goes beside the HTML, referenced by its Content-ID
        assert_eq!(message.attachments.len(), 1);
        let cid = message.attachments[0].content_id.clone().unwrap();
        assert!(
            cid.ends_with("@example.com") && html.contains(&format!("cid:{cid}")),
            "{html}"
        );
        assert_eq!(message.attachments[0].content_type, "image/gif");
    }
}
