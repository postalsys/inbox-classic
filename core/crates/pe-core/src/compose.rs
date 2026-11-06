//! New messages, replies and forwards: the drafts the compose window starts from, and the message a draft becomes
//! when it is sent. Recipients the user typed are parsed here, never in the window.

use std::path::PathBuf;

use pe_html::InlineImage;
use pe_i18n::{Text, tr, tr_args};
use pe_mime::Address;
use pe_mime::parser::{self, ParsedAddress, html_to_text, parse_addresses, text_addresses, text_to_html};
use pe_smtp::{Attachment, Message};
use pe_store::AccountSettings;

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
    /// The quoted message was plain text ([`Draft::quote_text`] was there)
    pub quote_plain: bool,
    /// [`Draft::quote_text`], while the quote is the draft's as it was (not edited): the plain text quote of it
    pub quote_text: Option<String>,
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
    /// The quote as plain text, the original's own lines, when the message replied to or forwarded was plain text:
    /// with nothing formatted written above it, the reply goes as plain text too ([`Outgoing::quote_text`])
    pub quote_text: Option<String>,
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
            ComposeError::NoRecipients => f.write_str(&tr(Text::ErrorNoRecipients)),
            ComposeError::BadAddress(address) => {
                f.write_str(&tr_args(Text::ErrorBadAddress, &[("address", address.into())]))
            }
            ComposeError::Attachment(path, error) => f.write_str(&tr_args(
                Text::ErrorAttachment,
                &[("path", (&path.display().to_string()).into()), ("error", error.into())],
            )),
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
            return Err(ComposeError::Attachment(path.clone(), tr(Text::ErrorNoSuchFile)));
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
        Some(written) if let Some(text) = plain(written, outgoing) => (text, None),
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

/// The message as plain text, when it goes as such: nothing formatted in what was written (the editor is always
/// HTML), and nothing quoted but a plain text message, as the original decides for a reply or a forward. Then what
/// was written as text, and the quote: the original's own lines, or the user's edit of it as text.
fn plain(written: &str, outgoing: &Outgoing) -> Option<String> {
    let quote = outgoing.quote.as_deref().filter(|q| !q.trim().is_empty());
    if (quote.is_some() && !outgoing.quote_plain) || !pe_html::is_plain(written) {
        return None;
    }
    let mut text = html_to_text(written).trim().to_string();
    if let Some(quote) = quote {
        text.push_str("\n\n");
        text.push_str(&outgoing.quote_text.clone().unwrap_or_else(|| edited_quote_text(quote)));
    }
    // a space typed twice comes as a no-break space, which plain text has no need of
    text = text.replace('\u{a0}', " ");
    text.push('\n');
    Some(text)
}

/// The header block of a quote and its lines, "> " in front of them in a reply, as Outlook Express quotes in plain text
fn quoted_lines(header: Vec<String>, body: &str, reply: bool) -> String {
    let body = body.trim_matches('\n');
    let body = if reply {
        body.lines()
            .map(|line| {
                if line.trim().is_empty() {
                    ">".to_string()
                } else {
                    format!("> {line}")
                }
            })
            .collect::<Vec<_>>()
            .join("\n")
    } else {
        body.to_string()
    };
    format!("{}\n\n{body}", header.join("\n"))
}

/// The plain text quote of a plain text original: its header lines and its own lines, as they came
fn text_quote(header: &[(&str, String)], text: &str, reply: bool) -> String {
    let mut lines = vec![tr(Text::QuoteOriginal)];
    lines.extend(
        header
            .iter()
            .filter(|(_, v)| !v.is_empty())
            .map(|(name, value)| format!("{name}: {value}")),
    );
    quoted_lines(lines, &text.replace("\r\n", "\n"), reply)
}

/// A quote the user unfolded and maybe trimmed, as text: its header block a line each, then its message
fn edited_quote_text(quote: &str) -> String {
    let (reply, header, body) = pe_html::quote_parts(quote);
    let header = html_to_text(header)
        .lines()
        .map(str::trim)
        .filter(|line| !line.is_empty())
        .map(str::to_string)
        .collect();
    quoted_lines(header, &html_to_text(body), reply)
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
    let items: Vec<String> = list
        .iter()
        .flat_map(ParsedAddress::mailboxes)
        .map(|m: &Address| address_label(&m.name, &m.address))
        .collect();
    items.join(", ")
}

/// `Re: ` or `Fw: ` in front, unless the subject already has it
pub(crate) fn prefixed(prefix: &str, subject: &str) -> String {
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
        (tr(Text::HeaderFrom), text_addresses(from)),
        (tr(Text::HeaderTo), to),
        (tr(Text::HeaderCc), cc),
        (tr(Text::HeaderSent), sent),
        (tr(Text::HeaderSubject), message.subject.clone().unwrap_or_default()),
    ];
    let header: Vec<(&str, String)> = header
        .iter()
        .map(|(name, value)| (name.as_str(), value.clone()))
        .collect();
    let mut draft = Draft {
        quote: pe_html::quote_html(&header, &body, &images, reply),
        quote_folded: reply,
        quote_text: match (&message.html, &message.text) {
            (None, Some(text)) => Some(text_quote(&header, text, reply)),
            _ => None,
        },
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

/// Someone as they go in an address field, where commas part the addresses: `Name <address>`, a name with anything
/// but letters, digits and spaces quoted, so `Smith, John` stays one name and not two recipients; the address alone
/// without a name
pub fn address_label(name: &str, address: &str) -> String {
    let name = name.trim();
    if name.is_empty() || name.eq_ignore_ascii_case(address) {
        return address.to_string();
    }
    let plain = name
        .chars()
        .all(|c| c.is_alphanumeric() || c == ' ' || c == '_' || c == '-' || c == '.');
    let name = if plain {
        name.to_string()
    } else {
        pe_smtp::encoding::quote_string(name)
    };
    format!("{name} <{address}>")
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn labels_an_address_for_a_field() {
        assert_eq!(
            address_label("Anna Lind", "anna@example.com"),
            "Anna Lind <anna@example.com>"
        );
        assert_eq!(address_label("", "anna@example.com"), "anna@example.com");
        assert_eq!(
            address_label("anna@example.com", "anna@example.com"),
            "anna@example.com"
        );
        assert_eq!(
            address_label("Lind, Anna", "anna@example.com"),
            "\"Lind, Anna\" <anna@example.com>"
        );
        assert_eq!(
            address_label("A \"B\" C", "a@example.com"),
            "\"A \\\"B\\\" C\" <a@example.com>"
        );
    }

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

    #[test]
    fn nothing_formatted_goes_as_plain_text() {
        // `quote`, and whether the original was plain text with its own text quote (None once the user edited it)
        let send = |html: &str, quote: Option<&str>, quote_plain: bool, quote_text: Option<String>| {
            let outgoing = Outgoing {
                to: "ann@example.com".into(),
                html: Some(html.into()),
                quote: quote.map(str::to_string),
                quote_plain,
                quote_text,
                ..Default::default()
            };
            message(&account(), &outgoing, 0).unwrap()
        };
        // a new message as the editor gives it, lines and all: text/plain only
        let new = send(
            "<div>Hello&nbsp; Ann,</div><div><br></div><div>see you.</div>",
            None,
            false,
            None,
        );
        assert_eq!(new.html, None);
        assert_eq!(new.text.as_deref(), Some("Hello  Ann,\n\nsee you.\n"));
        // anything formatted, a picture or a link keeps it HTML
        assert!(send("<div>Hello <b>Ann</b></div>", None, false, None).html.is_some());
        assert!(
            send("<div><a href=\"https://example.com\">here</a></div>", None, false, None)
                .html
                .is_some()
        );

        // a reply to a plain text message, nothing formatted: plain text with the original's own lines quoted
        let original =
            b"From: Ann <ann@example.com>\r\nSubject: Plans\r\n\r\nLet's meet.\r\n  Room   4,\r\n\r\nTomorrow?\r\n";
        let reply = draft(original, DraftKind::Reply, "me@example.com", None);
        let quote_text = reply.quote_text.clone();
        assert!(quote_text.is_some());
        let plain = send("<div>Yes.</div>", Some(&reply.quote), true, quote_text);
        assert_eq!(plain.html, None);
        let text = plain.text.unwrap();
        assert!(
            text.starts_with("Yes.\n\n----- Original Message -----\nFrom: Ann <ann@example.com>\n"),
            "{text}"
        );
        // the spacing of the original as it came
        assert!(
            text.contains("\n> Let's meet.\n>   Room   4,\n>\n> Tomorrow?"),
            "{text}"
        );
        // the quote unfolded and trimmed by the user: its text from what is left
        let edited = reply.quote.replace("Tomorrow?", "");
        let text = send("<div>Yes.</div>", Some(&edited), true, None).text.unwrap();
        assert!(
            text.starts_with("Yes.\n\n----- Original Message -----") && text.contains("\n> Let's meet."),
            "{text}"
        );
        assert!(!text.contains("Tomorrow"), "{text}");
        // the original was HTML: the reply follows it
        let html = b"From: Ann <ann@example.com>\r\nSubject: Plans\r\nContent-Type: text/html\r\n\r\n<p>Let's <b>meet</b>.</p>\r\n";
        let html_reply = draft(html, DraftKind::Reply, "me@example.com", None);
        assert_eq!(html_reply.quote_text, None);
        assert!(
            send("<div>Yes.</div>", Some(&html_reply.quote), false, None)
                .html
                .is_some()
        );
        // a forward of a plain message: its lines as they are, without "> "
        let forward = draft(ORIGINAL, DraftKind::Forward, "me@example.com", None);
        let text = send("<div>FYI</div>", Some(&forward.quote), true, forward.quote_text.clone())
            .text
            .unwrap();
        assert!(
            text.contains("\nLet's meet.\nTomorrow?") && !text.contains("> Let"),
            "{text}"
        );
    }
}
