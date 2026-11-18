//! A message as the preview shows it: the header fields as text, the body as a sanitized
//! document with its inline images, and the attachments with names that are safe to save under

use pe_html::RenderOptions;
use pe_mime::parser::{self, Attachment, text_addresses, text_to_html};
use pe_store::MessageRef;

#[derive(Debug, Clone, PartialEq, Eq)]
pub struct AttachmentView {
    /// The name the sender gave, for display, without control or direction characters
    pub filename: String,
    /// The name to save it under
    pub safe_filename: String,
    pub mime_type: String,
    pub size: u64,
    /// Its size in words ("240 KB")
    pub size_text: String,
    /// What kind of file it is: its icon in the strip, and whether it may be opened (not a file that runs code)
    pub kind: crate::opening::FileKind,
    /// The strip's tooltip: the full name and size, and why it does not open when it does not, a line each
    pub tooltip: String,
    /// What to say when a file that does not open is opened anyway, naming it; None for one that opens
    pub refusal: Option<String>,
}

impl AttachmentView {
    fn of(attachment: &Attachment) -> AttachmentView {
        let safe_filename = attachment.safe_filename();
        let filename = attachment.display_filename();
        let size = attachment.content.len() as u64;
        let size_text = crate::format_size(size);
        let kind = crate::opening::file_kind_of(&safe_filename, &attachment.mime_type, &attachment.content);
        AttachmentView {
            tooltip: crate::opening::tooltip(&filename, &size_text, kind),
            refusal: crate::opening::refusal(&filename, kind),
            kind,
            safe_filename,
            filename,
            mime_type: attachment.mime_type.clone(),
            size,
            size_text,
        }
    }

    /// Its size as told apart from its content (a large message's text first, whose attachments are not here yet)
    pub(crate) fn set_size(&mut self, size: u64) {
        self.size = size;
        self.size_text = crate::format_size(size);
        self.tooltip = crate::opening::tooltip(&self.filename, &self.size_text, self.kind);
    }
}

#[derive(Debug, Clone, PartialEq, Eq, Default)]
pub struct MessageView {
    pub subject: String,
    pub from: String,
    pub to: String,
    pub cc: String,
    /// The Date header, the received date without one, seconds since the Unix epoch
    pub date: Option<i64>,
    /// The body for WebView2: a complete document with a CSP
    pub document: String,
    /// The message has pictures on the internet (shown or not, as the view was asked for)
    pub remote_images: bool,
    /// Its pictures on the internet are shown: asked for, or loaded by themselves (the setting, a trusted sender);
    /// the reading pane then shows no pictures bar
    pub pictures_loaded: bool,
    /// The sender as the pictures bar names them, None for a From that is no single address
    pub sender: Option<crate::pictures::Sender>,
    pub attachments: Vec<AttachmentView>,
    /// How the message lets its reader leave its mailing list, None when it does not say
    pub unsubscribe: Option<crate::unsubscribe::Unsubscribe>,
    /// The event of its calendar part (an invitation, an update, a cancellation), None without one
    pub invitation: Option<crate::calendar::Invitation>,
    /// The brand has a BIMI logo the receiving server passed ([`crate::Core::logo_start`] draws it)
    pub has_logo: bool,
    /// Without a logo: the picture of the Address Book's card with the sender's address, the list's key for the
    /// message decided as the list decides it ([`crate::senders::picture`]: a confirmed sender only, never in a Junk
    /// folder); [`crate::Core::picture_start`] draws it. 0 for none
    pub picture: u64,
    /// It is a bounce, a notice that a message was not delivered or not yet: the document starts with its card
    pub bounce: bool,
    /// The message the bounce returns, found in the account by its Message-ID (Sent Items first): the card links to
    /// it with [`pe_html::BOUNCED_MESSAGE_LINK`], and the apps select this one when that link is clicked
    pub bounced_message: Option<MessageRef>,
    /// The one-time code of the card at the top of the document (Copy puts it on the clipboard), None without one
    pub otp_code: Option<String>,
    /// For a message with signed or encrypted parts: what the bar over it says and what each part is; None for
    /// any other message
    pub protection: Option<ProtectionView>,
    /// What the message says for Autocrypt, learned when the window takes the view ([`crate::Core::learn_autocrypt`])
    pub autocrypt: Option<crate::autocrypt::Seen>,
    /// The document of each part of such a message, in order, served at `part-N` beside the page
    /// ([`pe_html::part_document`]); empty for a part with nothing to show
    pub part_documents: Vec<String>,
    /// What is printed of such a message, None for any other (its `document` is): one document of every part's
    /// text, as a printer prints no frames, the bar's words and each part's label in its printed header; for a
    /// message with previews of its attachments, its document without them
    pub print_document: Option<String>,
    /// An encrypted message's text, decrypted, for the search index (when Options lets it keep it), stored when the
    /// window takes the view
    pub(crate) decrypted: Option<(pe_store::FolderId, u64, pe_store::IndexText, Option<String>)>,
    /// What [`crate::protect::decrypted_for_index`] made of the message while the view was built (as it is shown, and
    /// its protected Subject), for `decrypted`; never kept past the view's building
    pub(crate) decrypted_source: Option<(Vec<u8>, Option<String>)>,
    /// The token of the previews of its attachments after its text: the addresses of their pictures and their links
    /// carry it, and the core answers them while the view is shown ([`crate::Core::preview_ask`]). None when the
    /// document shows no previews
    pub preview_token: Option<String>,
    /// The attachments the document shows previews of, each with how many pictures
    pub(crate) preview_files: Vec<(usize, usize)>,
    /// Where those files are read from when their pictures are asked for
    pub(crate) preview_source: Option<crate::previews::PreviewSource>,
}

/// What a signed or encrypted message is, for the bar over it (which mail can not draw) and its Details
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct ProtectionView {
    /// The colour of the bar: the whole message's, or the most worrying part's
    pub tone: crate::protect::Tone,
    /// What the bar says
    pub text: String,
    /// Each part as the page labels it, in order
    pub parts: Vec<PartView>,
    /// The message's envelope (the layers at its top) is encrypted
    pub encrypted: bool,
}

impl ProtectionView {
    /// The Details window's text: each part, its label and what there is to know of it
    pub fn details(&self) -> String {
        let mut out = vec![self.text.clone()];
        for (index, part) in self.parts.iter().enumerate() {
            out.push(String::new());
            out.push(pe_i18n::tr_args(
                pe_i18n::Text::PgpDetailsPart,
                &[("number", (index + 1).into()), ("label", (&part.label).into())],
            ));
            out.extend(part.details.iter().map(|line| format!("    {line}")));
        }
        out.join("\n")
    }
}

#[derive(Debug, Clone, PartialEq, Eq)]
pub struct PartView {
    pub tone: crate::protect::Tone,
    pub label: String,
    /// What Details says of it beyond its label
    pub details: Vec<String>,
}

/// Whose word counts for a message: the domains whose Authentication-Results verdicts the account's provider gives,
/// and whether its folder may show the card of a one-time code (not Junk E-mail, Sent Items or Drafts)
#[derive(Default)]
pub(crate) struct Trust<'a> {
    pub domains: &'a [String],
    pub codes: bool,
    /// Whether pictures load without the user's click (pictures.rs)
    pub pictures: crate::pictures::Rules<'a>,
    /// The keys to read a signed or encrypted message with; None for a message that is neither
    pub ring: Option<&'a crate::protect::KeyRing>,
    /// How to show the pictures and PDF files attached after the text; None when they are not shown
    pub previews: Option<&'a crate::previews::PreviewPlan<'a>>,
}

/// Finds a message of the account by its Message-ID, for the link of a bounce's card
pub(crate) type FindMessage<'a> = &'a dyn Fn(&str) -> Option<MessageRef>;

/// The calendar part of a message (`text/calendar`, `application/ics`)
pub(crate) fn calendar_part(attachments: &[Attachment]) -> Option<&Attachment> {
    attachments
        .iter()
        .find(|a| matches!(a.mime_type.as_str(), "text/calendar" | "application/ics"))
}

/// The parts of a delivery report written for mail servers (RFC 3464 and 6533): the bounce's card says what they say
const REPORT_PARTS: [&str; 4] = [
    "message/delivery-status",
    "message/global-delivery-status",
    "text/rfc822-headers",
    "message/global-headers",
];

/// The attachments the attachment bar lists: not the images of an HTML body, nor a delivery report's parts for servers
pub(crate) fn listed(attachments: &[Attachment]) -> impl Iterator<Item = &Attachment> {
    attachments.iter().filter(|a| is_listed(a))
}

/// The parts that carry a signature of the rest of the message, which the reading pane shows as the signature's
/// verdict, never as a file
const SIGNATURE_PARTS: [&str; 3] = [
    "application/pgp-signature",
    "application/pkcs7-signature",
    "application/x-pkcs7-signature",
];

/// The attachments an AI agent is told of and reads, in one numbering for both: those of the attachment bar, without
/// a signature's own part (the reading pane shows the signature's verdict instead)
pub(crate) fn agent_listed(attachments: &[Attachment]) -> impl Iterator<Item = &Attachment> {
    listed(attachments).filter(|a| !SIGNATURE_PARTS.iter().any(|p| a.mime_type.eq_ignore_ascii_case(p)))
}

/// The `index`th attachment of [`agent_listed`], with its name to save it under and its type
pub(crate) fn agent_attachment(message: &parser::Message, index: usize) -> Option<(String, String, Vec<u8>)> {
    let attachment = agent_listed(&message.attachments).nth(index)?;
    Some((
        attachment.safe_filename(),
        attachment.mime_type.clone(),
        attachment.content.clone(),
    ))
}

/// An attachment of the list: not a picture of the HTML body, not a part of a delivery report
fn is_listed(attachment: &Attachment) -> bool {
    !attachment.related
        && !REPORT_PARTS
            .iter()
            .any(|p| attachment.mime_type.eq_ignore_ascii_case(p))
}

#[cfg(test)]
pub(crate) fn build(source: &[u8], allow_remote_images: bool) -> MessageView {
    build_unless(source, allow_remote_images, &Trust::default(), &|| false, &|_| None).unwrap_or_default()
}

/// [`build`], given up (None) between its steps once `dropped` says nobody waits for it anymore; `find` looks up the
/// message a bounce returns
pub(crate) fn build_unless(
    source: &[u8],
    allow_remote_images: bool,
    trust: &Trust,
    dropped: &dyn Fn() -> bool,
    find: FindMessage,
) -> Option<MessageView> {
    let message = match parser::parse(source) {
        Ok(message) => message,
        Err(error) => {
            let options = RenderOptions { allow_remote_images };
            let text = pe_i18n::tr_args(
                pe_i18n::Text::ReaderUnreadable,
                &[("error", (&error.to_string()).into())],
            );
            return Some(MessageView {
                document: pe_html::render_document(&text_to_html(&text), &options),
                ..Default::default()
            });
        }
    };
    // a trusted sender the provider confirmed, or every message's when the user said so: the pictures load
    let sender = crate::pictures::sender(&message, trust.domains);
    let clicked = allow_remote_images;
    let allow_remote_images = allow_remote_images || crate::pictures::load(&trust.pictures, sender.as_ref());
    if let Some(ring) = trust.ring {
        let from = crate::from_addresses(source);
        if let Some(protected) = crate::protect::read(source, ring, &from, crate::worker::unix_now()) {
            let mut seen = crate::autocrypt::seen(&message, trust.pictures.junk, crate::worker::unix_now());
            if let Some(seen) = seen.as_mut() {
                seen.gossip = protected.gossip.clone();
            }
            // what the search index keeps of it, from this one decryption (decrypted_for_view takes it or drops it)
            let shown = crate::protect::decrypted_for_index(source, &protected);
            let mut view = protected_view(&message, protected, clicked, allow_remote_images, sender, trust);
            view.autocrypt = seen;
            view.decrypted_source = shown;
            return Some(view);
        }
    }
    let options = RenderOptions { allow_remote_images };
    let images = crate::compose::inline_images(&message);
    if dropped() {
        return None;
    }
    // the pictures and PDF files attached, shown after the text: never of signed or encrypted mail (yet)
    let planned = trust
        .previews
        .filter(|_| !may_be_signed_or_encrypted(source))
        .map(|plan| crate::previews::section(&message, plan));
    if dropped() {
        return None;
    }
    // the earlier messages of a reply or forward folded behind "..."
    let body = crate::fold::body(&message);
    if dropped() {
        return None;
    }
    let (from, to, cc) = (
        text_addresses(message.from.as_slice()),
        text_addresses(&message.to),
        text_addresses(&message.cc),
    );
    let subject = message.subject.clone().unwrap_or_default();
    // in the reader's day and time, as the list and the reading pane say it, not as the header has it
    let date = message
        .timestamp
        .map(crate::calendar::local_date_time)
        .unwrap_or_default();
    // for a printout: on screen the window shows these above the message
    use pe_i18n::{Text, tr};
    let names = [
        tr(Text::HeaderFrom),
        tr(Text::HeaderDate),
        tr(Text::HeaderTo),
        tr(Text::HeaderCc),
        tr(Text::HeaderSubject),
    ];
    let header = [
        (names[0].as_str(), from.as_str()),
        (names[1].as_str(), date.as_str()),
        (names[2].as_str(), to.as_str()),
        (names[3].as_str(), cc.as_str()),
        (names[4].as_str(), subject.as_str()),
    ];
    // a bounce: parsed again the way pe-bounce reads one, only when it may be one
    let bounce = pe_bounce::detect::may_be_bounce(&message)
        .then(|| pe_bounce::analyze(source))
        .flatten();
    if dropped() {
        return None;
    }
    let bounced_message = bounce
        .as_ref()
        .and_then(|b| b.original.as_ref()?.message_id.as_deref())
        .and_then(find);
    let card = bounce
        .as_ref()
        .map(|b| crate::bounce::card(b, bounced_message.is_some()));
    // a one-time code the domain it is for signed, above the message
    let code = trust.codes.then(|| crate::otp::of(&message, trust.domains)).flatten();
    let otp_card = code
        .as_ref()
        .map(|code| crate::otp::card(code, message.timestamp, crate::worker::unix_now()));
    // a calendar event: its card says when and where, and opens it in the calendar app
    let invitation = calendar_part(&message.attachments)
        .and_then(|part| crate::calendar::invitation(&String::from_utf8_lossy(&part.content), part.method.as_deref()));
    let event_card = invitation.as_ref().map(crate::calendar::card);
    let cards = pe_html::Cards {
        otp: otp_card.as_ref(),
        event: event_card.as_ref(),
        bounce: card.as_ref(),
        previews: planned.as_ref(),
    };
    let rendered = pe_html::render_view_cards(&body, &options, &images, &header, &cards);
    // the files the document shows (not those its HTML shows already), under the token of their addresses
    let (preview_token, preview_files) = match planned {
        Some(section) if !rendered.previewed.is_empty() => (
            Some(section.token),
            section
                .files
                .iter()
                .filter(|file| rendered.previewed.contains(&file.attachment))
                .map(|file| (file.attachment, file.pages.len()))
                .collect(),
        ),
        _ => (None, Vec::new()),
    };
    // the previews are not printed (the print windows serve none of their pictures)
    let print_document = pe_html::without_previews(&rendered.document);
    Some(MessageView {
        subject,
        from,
        to,
        cc,
        date: message.timestamp,
        document: rendered.document,
        remote_images: rendered.remote_images,
        pictures_loaded: allow_remote_images,
        sender,
        attachments: listed(&message.attachments).map(AttachmentView::of).collect(),
        unsubscribe: crate::unsubscribe::of(&message.headers, trust.domains),
        has_logo: crate::bimi::of(&message.headers, trust.domains).is_some(),
        picture: 0,
        invitation,
        bounce: bounce.is_some(),
        bounced_message,
        otp_code: code.map(|code| code.code),
        protection: None,
        autocrypt: crate::autocrypt::seen(&message, trust.pictures.junk, crate::worker::unix_now()),
        part_documents: Vec::new(),
        print_document,
        decrypted: None,
        decrypted_source: None,
        preview_token,
        preview_files,
        preview_source: None,
    })
}

/// Whether a message may have signed or encrypted parts, OpenPGP or S/MIME: such mail gets no previews of its
/// attachments yet (docs/attachment-preview-plan.md, PR 4), so nothing of an encrypted part can show in another
fn may_be_signed_or_encrypted(source: &[u8]) -> bool {
    crate::protect::may_be_protected(source)
        || pe_mime::outline::outline(source).parts.iter().any(|part| {
            matches!(
                part.content_type.as_str(),
                "multipart/signed" | "multipart/encrypted" | "application/pkcs7-mime" | "application/x-pkcs7-mime"
            )
        })
}

/// The view of a message with signed or encrypted parts: the page of its sections ([`pe_html::secure_page`]), each
/// rendered as any message is, its attachments from the sections, and what the bar says. Pictures from the internet
/// load in a decrypted part only on the user's click (`clicked`): never by the sender's trust or the "always"
/// setting, which `allow_remote_images` includes, and its label then says they were loaded.
fn protected_view(
    message: &parser::Message,
    protected: crate::protect::Protected,
    clicked: bool,
    allow_remote_images: bool,
    sender: Option<crate::pictures::Sender>,
    trust: &Trust,
) -> MessageView {
    use crate::protect::Tone;
    let mut documents = Vec::new();
    let mut parts = Vec::new();
    let mut attachments = Vec::new();
    let mut remote_images = false;
    // a part whose pictures did not load: the pictures bar shows
    let mut blocked = false;
    // the printout: every part's text in one document (a printer prints no frames), under the labels as words
    // each part's words (no markup of the message: one part's styles could hide another on the paper), by its place
    let mut print_texts: Vec<(usize, String)> = Vec::new();
    // parsed first: the printout's pictures borrow from them
    let parsed: Vec<Option<parser::Message>> = protected
        .sections
        .iter()
        .map(|section| section.entity.as_deref().and_then(|entity| parser::parse(entity).ok()))
        .collect();
    for (section, part) in protected.sections.iter().zip(&parsed) {
        let encrypted = section.verdict.as_ref().is_some_and(|verdict| verdict.encrypted);
        let allow = if encrypted { clicked } else { allow_remote_images };
        let mut label = match &section.verdict {
            Some(verdict) => verdict.label(),
            None => pe_i18n::tr(pe_i18n::Text::PgpPartNotSigned),
        };
        let tone = section
            .verdict
            .as_ref()
            .map_or(Tone::Neutral, crate::protect::Verdict::tone);
        let details = section.verdict.as_ref().map_or_else(
            || vec![pe_i18n::tr(pe_i18n::Text::PgpDetailsPlain)],
            crate::protect::Verdict::details,
        );
        let document = part.as_ref().map(|part| {
            let body = crate::fold::body(part);
            let images = crate::compose::inline_images(part);
            let rendered = pe_html::render_view_cards(
                &body,
                &RenderOptions {
                    allow_remote_images: allow,
                },
                &images,
                &[],
                &pe_html::Cards::default(),
            );
            remote_images |= rendered.remote_images;
            blocked |= rendered.remote_images && !allow;
            if encrypted && allow && rendered.remote_images {
                label = pe_i18n::tr_args(pe_i18n::Text::PgpPartPicturesLoaded, &[("label", (&label).into())]);
            }
            attachments.extend(listed(&part.attachments).map(AttachmentView::of));
            print_texts.push((parts.len(), parser::html_to_text(&body)));
            rendered.document
        });
        documents.push(document);
        parts.push(PartView { tone, label, details });
    }
    let page_parts: Vec<pe_html::SecurePart> = parts
        .iter()
        .zip(&documents)
        .map(|(part, document)| pe_html::SecurePart {
            tone: part.tone,
            label: &part.label,
            shown: document.is_some(),
        })
        .collect();
    let document = pe_html::secure_page(&page_parts, clicked || allow_remote_images);
    // the bar: the envelope's words when the message is one part; with several that differ, how many of each
    let differ = parts
        .windows(2)
        .any(|pair| (pair[0].tone, &pair[0].label) != (pair[1].tone, &pair[1].label));
    let (tone, text) = match (&protected.envelope, differ) {
        (Some(envelope), false) => (
            envelope.tone(),
            parts.first().map_or_else(|| envelope.label(), |p| p.label.clone()),
        ),
        _ if parts.len() == 1 => (parts[0].tone, parts[0].label.clone()),
        _ => {
            let worst = parts.iter().map(|part| part.tone).min_by_key(|tone| match tone {
                Tone::Warning => 0,
                Tone::Neutral => 1,
                Tone::Good => 2,
                Tone::Verified => 3,
            });
            (worst.unwrap_or(Tone::Neutral), counted(&parts))
        }
    };
    let any_encrypted = protected
        .sections
        .iter()
        .any(|section| section.verdict.as_ref().is_some_and(|verdict| verdict.encrypted));
    let print_document = print_document(message, &text, &parts, &print_texts);
    let subject = protected
        .subject
        .clone()
        .or_else(|| message.subject.clone())
        .unwrap_or_default();
    MessageView {
        subject,
        from: text_addresses(message.from.as_slice()),
        to: text_addresses(&message.to),
        cc: text_addresses(&message.cc),
        date: message.timestamp,
        document,
        remote_images,
        pictures_loaded: !blocked,
        // pictures of encrypted mail load on a click only, never remembered: the bar offers no "always"
        sender: if any_encrypted { None } else { sender },
        attachments,
        unsubscribe: crate::unsubscribe::of(&message.headers, trust.domains),
        has_logo: crate::bimi::of(&message.headers, trust.domains).is_some(),
        part_documents: documents.into_iter().map(Option::unwrap_or_default).collect(),
        print_document: Some(print_document),
        protection: Some(ProtectionView {
            tone,
            text,
            parts,
            encrypted: protected.envelope.as_ref().is_some_and(|envelope| envelope.encrypted),
        }),
        ..Default::default()
    }
}

/// The printout of a message with signed or encrypted parts: the header a printout has, then the bar's words and each
/// part's label (in the header, where the message's styles can not reach them), then each part's text, in order
fn print_document(message: &parser::Message, bar: &str, parts: &[PartView], texts: &[(usize, String)]) -> String {
    use pe_i18n::{Text, tr, tr_args};
    let date = message
        .timestamp
        .map(crate::calendar::local_date_time)
        .unwrap_or_default();
    let part_name = |index: usize| tr_args(Text::HeaderPart, &[("number", (index + 1).into())]);
    let mut lines: Vec<(String, String)> = vec![
        (tr(Text::HeaderFrom), text_addresses(message.from.as_slice())),
        (tr(Text::HeaderDate), date),
        (tr(Text::HeaderTo), text_addresses(&message.to)),
        (tr(Text::HeaderCc), text_addresses(&message.cc)),
        (tr(Text::HeaderSubject), message.subject.clone().unwrap_or_default()),
        (tr(Text::HeaderSecurity), bar.to_string()),
    ];
    for (index, part) in parts.iter().enumerate() {
        lines.push((part_name(index), part.label.clone()));
    }
    let header: Vec<(&str, &str)> = lines
        .iter()
        .map(|(name, value)| (name.as_str(), value.as_str()))
        .collect();
    // each part as plain text under its label in bold: no part has markup, so the bold labels can only be ours
    let body: String = texts
        .iter()
        .map(|(index, text)| {
            let label = format!("{}: {}", part_name(*index), parts[*index].label);
            format!("<p><b>{}</b></p>{}", escape_html(&label), text_to_html(text))
        })
        .collect::<Vec<_>>()
        .join("<hr>");
    pe_html::render_view_cards(
        &body,
        &RenderOptions {
            allow_remote_images: false,
        },
        &[],
        &header,
        &pe_html::Cards::default(),
    )
    .document
}

/// Text as HTML text
fn escape_html(text: &str) -> String {
    text.replace('&', "&amp;")
        .replace('<', "&lt;")
        .replace('>', "&gt;")
        .replace('"', "&quot;")
}

/// The bar of a message whose parts differ: how many parts, and how many of each tone
fn counted(parts: &[PartView]) -> String {
    use crate::protect::Tone;
    use pe_i18n::Text;
    let kinds = [
        (Tone::Verified, Text::PgpBarCountVerified),
        (Tone::Good, Text::PgpBarCountGood),
        (Tone::Warning, Text::PgpBarCountWarning),
        (Tone::Neutral, Text::PgpBarCountNeutral),
    ];
    let list: Vec<String> = kinds
        .iter()
        .filter_map(|(tone, text)| {
            let count = parts.iter().filter(|part| part.tone == *tone).count();
            (count > 0).then(|| pe_i18n::tr_args(*text, &[("count", count.into())]))
        })
        .collect();
    pe_i18n::tr_args(
        Text::PgpBarParts,
        &[("count", parts.len().into()), ("list", (&list.join(", ")).into())],
    )
}

/// The most of a header block shown in Message Properties; the store reads no more of a message than this
pub(crate) const MAX_HEADER_TEXT: usize = 256 * 1024;

/// The header block of a message (its start, see [`MAX_HEADER_TEXT`]) as text to show in Message Properties, as the
/// Details tab of Outlook Express: up to the first empty line, invalid UTF-8 replaced, control characters other than
/// tabs and direction marks turned into spaces (no escape or reordering reaches the window), line breaks as Windows
/// edit controls want them
pub(crate) fn header_text(source: &[u8]) -> String {
    let source = &source[..source.len().min(MAX_HEADER_TEXT)];
    let text = String::from_utf8_lossy(source);
    let mut out = String::with_capacity(text.len());
    for line in text.split('\n') {
        let line = line.strip_suffix('\r').unwrap_or(line);
        // the first empty line ends the header, whichever line breaks the message has
        if line.is_empty() {
            break;
        }
        push_shown(&mut out, line);
        out.push_str("\r\n");
    }
    out
}

/// A line of mail as a window may show it: control characters and direction marks (which could make it read as
/// something else) as spaces, tabs kept
fn push_shown(out: &mut String, line: &str) {
    let shown = |c: char| c == '\t' || !(c.is_control() || parser::is_direction_mark(c));
    out.extend(line.chars().map(|c| if shown(c) { c } else { ' ' }));
}

/// Text of mail as a window may show it, line by line as [`push_shown`] makes a line, its line breaks (`\n`) kept
pub(crate) fn shown_text(text: &str) -> String {
    let mut out = String::with_capacity(text.len());
    for (index, line) in text.split('\n').enumerate() {
        if index > 0 {
            out.push('\n');
        }
        push_shown(&mut out, line);
    }
    out
}

/// The most of a message's source View Source shows
pub(crate) const MAX_SOURCE_TEXT: usize = 4 * 1024 * 1024;

/// The whole source of a message as text safe to show in a window (View Source), from its first bytes (`source`, at
/// most [`MAX_SOURCE_TEXT`] of them shown) of `size` in all: line breaks as `\r\n`, each line made safe as a header
/// line is, bytes that are not UTF-8 as U+FFFD; past [`MAX_SOURCE_TEXT`] it is cut short, with a line that says so
pub(crate) fn source_text(source: &[u8], size: usize) -> String {
    let shown = &source[..source.len().min(MAX_SOURCE_TEXT)];
    let text = String::from_utf8_lossy(shown);
    let mut out = String::with_capacity(text.len() + text.len() / 40);
    for (index, line) in text.split('\n').enumerate() {
        if index > 0 {
            out.push_str("\r\n");
        }
        push_shown(&mut out, line.strip_suffix('\r').unwrap_or(line));
    }
    let size = size.max(source.len());
    if size > MAX_SOURCE_TEXT {
        out.push_str(&format!(
            "\r\n\r\n[{} more not shown. File > Save As keeps the whole message.]\r\n",
            crate::format_size((size - MAX_SOURCE_TEXT) as u64)
        ));
    }
    out
}

/// The content of the `index`th listed attachment, with the name to save it under
pub(crate) fn attachment(source: &[u8], index: usize) -> Option<(String, Vec<u8>)> {
    attachments(source).into_iter().nth(index)
}

/// One attachment taken out of its message to be opened: the name to save it under, the one to show, its type and
/// its content
pub(crate) struct Taken {
    pub name: String,
    pub display_name: String,
    pub mime_type: String,
    pub content: Vec<u8>,
}

/// The `index`th listed attachment, taken from the parse (its content not copied)
pub(crate) fn take_attachment(source: &[u8], index: usize) -> Option<Taken> {
    let message = parser::parse(source).ok()?;
    let position = message
        .attachments
        .iter()
        .enumerate()
        .filter(|(_, a)| is_listed(a))
        .nth(index)?
        .0;
    let mut attachments = message.attachments;
    let attachment = attachments.swap_remove(position);
    Some(Taken {
        name: attachment.safe_filename(),
        display_name: attachment.display_filename(),
        mime_type: attachment.mime_type,
        content: attachment.content,
    })
}

/// The `index`th listed attachment with the name to save it under and its type
pub(crate) fn attachment_with_type(source: &[u8], index: usize) -> Option<(String, String, Vec<u8>)> {
    let message = parser::parse(source).ok()?;
    let attachment = listed(&message.attachments).nth(index)?;
    Some((
        attachment.safe_filename(),
        attachment.mime_type.clone(),
        attachment.content.clone(),
    ))
}

/// The listed attachments (not the pictures of an HTML body), each with the name to save it under, from one parse
pub(crate) fn attachments(source: &[u8]) -> Vec<(String, Vec<u8>)> {
    let Ok(message) = parser::parse(source) else {
        return Vec::new();
    };
    message
        .attachments
        .into_iter()
        .filter(is_listed)
        .map(|a| (a.safe_filename(), a.content))
        .collect()
}

/// What Windows keeps beside a file that came from the internet (its Mark of the Web, zone 3): opened later, the
/// file gets SmartScreen and Office's Protected View, as one downloaded in a browser does
pub(crate) const ZONE_IDENTIFIER: &str = "[ZoneTransfer]\r\nZoneId=3\r\n";

/// Marks a saved attachment as from the internet, on Windows (an NTFS stream of the file); a file system without
/// streams keeps the file unmarked, as a browser's download there would be
pub(crate) fn mark_from_internet(path: &std::path::Path) {
    if cfg!(windows) {
        let mut stream = path.as_os_str().to_owned();
        stream.push(":Zone.Identifier");
        let _ = std::fs::write(stream, ZONE_IDENTIFIER);
    }
}

/// Writes `content` into `dir` as `name`, or as `name (2).ext`, `name (3).ext`... when that is taken: a file there is
/// never replaced, and creating it new (not checking first) leaves no moment for another to appear in between
pub(crate) fn write_new(dir: &std::path::Path, name: &str, content: &[u8]) -> std::io::Result<std::path::PathBuf> {
    use std::io::Write;
    let (stem, extension) = match name.rfind('.') {
        Some(dot) if dot > 0 => name.split_at(dot),
        _ => (name, ""),
    };
    for n in 1u32.. {
        let candidate = if n == 1 {
            name.to_string()
        } else {
            format!("{stem} ({n}){extension}")
        };
        let path = dir.join(candidate);
        match std::fs::OpenOptions::new().write(true).create_new(true).open(&path) {
            Ok(mut file) => {
                file.write_all(content)?;
                mark_from_internet(&path);
                return Ok(path);
            }
            Err(error) if error.kind() == std::io::ErrorKind::AlreadyExists && n < 10_000 => continue,
            Err(error) => return Err(error),
        }
    }
    unreachable!("the loop returns")
}

#[cfg(test)]
mod tests {
    use super::*;

    const MESSAGE: &[u8] = b"From: Andris <andris@example.com>\r\nTo: a@example.com, Team: b@example.com;\r\nSubject: Report\r\nDate: Mon, 6 Oct 2025 10:00:00 +0000\r\nContent-Type: multipart/mixed; boundary=m\r\n\r\n--m\r\nContent-Type: multipart/related; boundary=r\r\n\r\n--r\r\nContent-Type: text/html\r\n\r\n<p onclick=x()>Hi <img src=\"cid:logo@x\"></p><script>bad()</script>\r\n--r\r\nContent-Type: image/png\r\nContent-ID: <logo@x>\r\nContent-Transfer-Encoding: base64\r\n\r\niVBORw==\r\n--r--\r\n--m\r\nContent-Type: application/pdf; name=\"../../report.pdf\"\r\nContent-Transfer-Encoding: base64\r\n\r\nJVBERg==\r\n--m--\r\n";

    #[test]
    fn a_view_nobody_waits_for_gives_up() {
        assert!(build_unless(MESSAGE, false, &Trust::default(), &|| true, &|_| None).is_none());
        assert!(build_unless(MESSAGE, false, &Trust::default(), &|| false, &|_| None).is_some());
        // once it is dropped halfway, after parsing
        let asked = std::cell::Cell::new(0);
        let dropped = || {
            asked.set(asked.get() + 1);
            asked.get() > 1
        };
        assert!(build_unless(MESSAGE, false, &Trust::default(), &dropped, &|_| None).is_none());
    }

    #[test]
    fn views_a_message() {
        let view = build(MESSAGE, false);
        assert_eq!(view.subject, "Report");
        assert_eq!(view.from, "Andris <andris@example.com>");
        assert_eq!(view.to, "a@example.com, Team:b@example.com;");
        assert_eq!(view.date, Some(1_759_744_800));
        assert!(view.document.contains("Content-Security-Policy"));
        // the header for a printout, escaped, shown only in print
        assert!(
            view.document
                .contains(":</span> Andris &lt;andris@example.com&gt;</div>"),
            "{}",
            view.document
        );
        // under a class the message can not know
        assert!(view.document.contains("<div class=\"pe-print-"), "{}", view.document);
        assert!(view.document.contains("@media print"));
        // its rules in a layer as unguessable as the class: the message's important rules can not hide it
        let class = view
            .document
            .split("<div class=\"")
            .nth(1)
            .unwrap()
            .split('"')
            .next()
            .unwrap();
        assert!(
            view.document
                .contains(&format!("@layer {class}{{.{class}{{display:none}}")),
            "{}",
            view.document
        );
        assert!(
            view.document.contains("data:image/png;base64,iVBORw=="),
            "{}",
            view.document
        );
        assert!(!view.document.contains("script") && !view.document.contains("onclick"));
        // no pictures on the internet to offer to download
        assert!(!view.remote_images);
        let remote = build(
            b"Content-Type: text/html\r\n\r\n<img src=\"https://example.com/x.png\">\r\n",
            false,
        );
        assert!(remote.remote_images);
        assert_eq!(
            view.attachments,
            [AttachmentView {
                filename: "../../report.pdf".into(),
                safe_filename: "report.pdf".into(),
                mime_type: "application/pdf".into(),
                size: 4,
                size_text: crate::format_size(4),
                kind: crate::opening::FileKind::Pdf,
                tooltip: format!("../../report.pdf ({})", crate::format_size(4)),
                refusal: None,
            }]
        );
        assert_eq!(attachment(MESSAGE, 0), Some(("report.pdf".into(), b"%PDF".to_vec())));
        // taken out to be opened: the listed one (not the body's picture), its names and type
        let taken = take_attachment(MESSAGE, 0).unwrap();
        assert_eq!(
            (
                taken.name.as_str(),
                taken.display_name.as_str(),
                taken.mime_type.as_str()
            ),
            ("report.pdf", "../../report.pdf", "application/pdf")
        );
        assert_eq!(taken.content, b"%PDF");
        assert!(take_attachment(MESSAGE, 1).is_none());
        assert_eq!(attachment(MESSAGE, 1), None);
    }

    #[test]
    fn files_are_saved_without_replacing_any() {
        let dir = std::env::temp_dir().join(format!("pe-write-new-{}", std::process::id()));
        std::fs::create_dir_all(&dir).unwrap();
        let first = write_new(&dir, "report.pdf", b"one").unwrap();
        let second = write_new(&dir, "report.pdf", b"two").unwrap();
        let bare = write_new(&dir, ".hidden", b"three").unwrap();
        assert_eq!(first.file_name().unwrap(), "report.pdf");
        assert_eq!(second.file_name().unwrap(), "report (2).pdf");
        assert_eq!(bare.file_name().unwrap(), ".hidden");
        assert_eq!(std::fs::read(&first).unwrap(), b"one");
        assert_eq!(std::fs::read(&second).unwrap(), b"two");
        // marked as from the internet, where Windows keeps such marks
        if cfg!(windows) {
            let mut stream = first.as_os_str().to_owned();
            stream.push(":Zone.Identifier");
            assert_eq!(std::fs::read_to_string(stream).unwrap(), ZONE_IDENTIFIER);
        }
        std::fs::remove_dir_all(&dir).unwrap();
        // the attachments of a message, from one parse
        assert_eq!(attachments(MESSAGE), [("report.pdf".to_string(), b"%PDF".to_vec())]);
    }

    #[test]
    fn headers_to_show() {
        let source =
            b"From: Ann <ann@example.com>\r\nSubject: Hi \x1b[31m\xe2\x80\xaeevil\r\nX-Bad: \xff\r\n\r\nbody\r\n";
        let text = header_text(source);
        assert_eq!(
            text,
            "From: Ann <ann@example.com>\r\nSubject: Hi  [31m evil\r\nX-Bad: \u{fffd}\r\n"
        );
        // the whole source, made as safe to show; bare line feeds become CRLF
        assert_eq!(
            source_text(b"A: 1\nB: \x1b[31mx\r\n\r\nbody \xff\n", 0),
            "A: 1\r\nB:  [31mx\r\n\r\nbody \u{fffd}\r\n"
        );
        let large = vec![b'a'; MAX_SOURCE_TEXT + 2048];
        assert!(
            source_text(&large, large.len())
                .ends_with("[2 KB more not shown. File > Save As keeps the whole message.]\r\n")
        );
        // a message of bare line feeds, also when its body has CRLF blank lines, and one without a body
        assert_eq!(header_text(b"A: 1\nB: 2\n\nbody\r\n\r\nmore"), "A: 1\r\nB: 2\r\n");
        assert_eq!(header_text("A: \u{61c}x".as_bytes()), "A:  x\r\n");
        assert_eq!(header_text(b"A: 1"), "A: 1\r\n");
    }

    #[test]
    fn plain_text_is_escaped() {
        let view = build(b"Subject: x\r\n\r\n<b>not bold</b> & more\r\n", false);
        assert!(
            view.document.contains("&lt;b&gt;not bold") || view.document.contains("&#x3C;b"),
            "{}",
            view.document
        );
        assert!(!view.document.contains("<b>"));
    }

    fn bounce_fixture(name: &str) -> Vec<u8> {
        std::fs::read(format!(
            "{}/../pe-bounce/tests/fixtures/bounces/{name}",
            env!("CARGO_MANIFEST_DIR")
        ))
        .unwrap()
    }

    /// A delivery report for `recipient` with the server's `words`, returning the message `<sent@example.com>`
    fn report(recipient: &str, action: &str, status: &str, words: &str) -> Vec<u8> {
        [
            "From: Mail Delivery System <MAILER-DAEMON@mx.example.com>",
            "To: me@example.com",
            "Subject: Undelivered Mail Returned to Sender",
            "MIME-Version: 1.0",
            "Content-Type: multipart/report; report-type=delivery-status; boundary=\"B\"",
            "",
            "--B",
            "Content-Type: text/plain",
            "",
            "Your message could not be delivered.",
            "--B",
            "Content-Type: message/delivery-status",
            "",
            "Reporting-MTA: dns; mx.example.com",
            "",
            &format!("Final-Recipient: rfc822; {recipient}"),
            &format!("Action: {action}"),
            &format!("Status: {status}"),
            "Remote-MTA: dns; mx.remote.example",
            &format!("Diagnostic-Code: smtp; {words}"),
            "--B",
            "Content-Type: text/rfc822-headers",
            "",
            "From: me@example.com",
            "To: someone@example.com",
            "Subject: The quarterly report",
            "Message-ID: <sent@example.com>",
            "--B--",
            "",
        ]
        .join("\r\n")
        .into_bytes()
    }

    /// The text of a document, tags dropped, for looking for words in it
    fn shown(document: &str) -> String {
        let mut out = String::new();
        let mut inside = false;
        for c in document.chars() {
            match c {
                '<' => inside = true,
                '>' => inside = false,
                _ if !inside => out.push(c),
                _ => {}
            }
        }
        out
    }

    #[test]
    fn a_bounce_starts_with_its_card() {
        let view = build(&bounce_fixture("gmail.eml"), false);
        assert!(view.bounce);
        assert!(
            view.attachments
                .iter()
                .all(|a| !REPORT_PARTS.contains(&a.mime_type.as_str())),
            "the report's parts for servers are not listed: {:?}",
            view.attachments.iter().map(|a| &a.mime_type).collect::<Vec<_>>()
        );
        let document = &view.document;
        assert!(document.contains("role=\"note\""), "{document}");
        let text = shown(document);
        for words in [
            "Your message was not delivered",
            "Subject: proovikiri",
            "jhfthgfuyfhvjkugjhvjuyfv@hot.ee",
            "The address does not exist",
            "What you can do:",
            "Details",
            "550 5.1.1 &lt;jhfthgfuyfhvjkugjhvjuyfv@hot.ee&gt;: Recipient address rejected",
            "Status: 5.1.1",
            "Reported by: googlemail.com",
        ] {
            assert!(text.contains(words), "{words} in {text}");
        }
        // the card above the notice's own text, the CSP as for any message
        assert!(document.contains("</div></div><style>@layer pe-bounce-"), "{document}");
        assert!(document.contains("default-src 'none'") && !document.contains("<script"));
        // the message it returns is not in the store here: no link to it
        assert!(!document.contains(pe_html::BOUNCED_MESSAGE_LINK));
        assert_eq!(view.bounced_message, None);
    }

    #[test]
    fn every_fixture_gets_a_card() {
        let dir = format!("{}/../pe-bounce/tests/fixtures/bounces", env!("CARGO_MANIFEST_DIR"));
        for entry in std::fs::read_dir(dir).unwrap() {
            let path = entry.unwrap().path();
            let view = build(&std::fs::read(&path).unwrap(), false);
            assert!(view.bounce, "{}", path.display());
            assert!(view.document.contains("role=\"note\""), "{}", path.display());
        }
    }

    #[test]
    fn a_delay_says_it_is_still_on_its_way() {
        let view = build(&bounce_fixture("delayed.eml"), false);
        assert!(view.bounce);
        let text = shown(&view.document);
        assert!(text.contains("Your message has not been delivered yet"), "{text}");
        assert!(text.contains("You do not need to send it again"), "{text}");
        assert!(text.contains("user@example.com"), "{text}");
        assert!(text.contains("The receiving server had a problem"), "{text}");
        // what to do about a delay, not a failure's advice
        assert!(text.contains("Nothing yet. If it still cannot be delivered"), "{text}");
        assert!(!text.contains("Send it again later"), "{text}");
        // greylisted, with the wait the server asked for
        let view = build(
            &report(
                "grey@example.com",
                "delayed",
                "4.2.0",
                "450 4.2.0 Greylisted, try again in 5 minutes",
            ),
            false,
        );
        let text = shown(&view.document);
        assert!(text.contains("Your message has not been delivered yet"), "{text}");
        assert!(text.contains("Held back for a moment"), "{text}");
        assert!(text.contains("asked to wait 5 minutes"), "{text}");
    }

    #[test]
    fn a_delay_among_failures_is_drawn_and_advised_as_one() {
        let raw = [
            "From: Mail Delivery System <MAILER-DAEMON@mx.example.com>",
            "Content-Type: multipart/report; report-type=delivery-status; boundary=\"B\"",
            "",
            "--B",
            "Content-Type: message/delivery-status",
            "",
            "Reporting-MTA: dns; mx.example.com",
            "",
            "Final-Recipient: rfc822; first@example.com",
            "Action: failed",
            "Status: 5.1.1",
            "Diagnostic-Code: smtp; 550 5.1.1 User unknown",
            "",
            "Final-Recipient: rfc822; later@example.com",
            "Action: delayed",
            "Status: 4.2.2",
            "Diagnostic-Code: smtp; 452 4.2.2 Mailbox full",
            "--B--",
            "",
        ]
        .join("\r\n");
        let view = build(raw.as_bytes(), false);
        let document = &view.document;
        assert_eq!(document.matches("<div class=\"r y\">").count(), 1, "{document}");
        let text = shown(document);
        assert!(text.contains("Your message was not delivered"), "{text}");
        assert!(text.contains("Nothing yet. Your mail server is still trying"), "{text}");
        // the full mailbox's advice is for a failure; the note it replaces is not said twice
        assert!(!text.contains("Send it again in a few days"), "{text}");
        assert!(!text.contains("You do not need to send it again"), "{text}");
    }

    #[test]
    fn names_the_blocklist() {
        let view = build(
            &report(
                "user@example.org",
                "failed",
                "5.7.1",
                "554 5.7.1 Service unavailable; Client host [203.0.113.5] blocked using zen.spamhaus.org",
            ),
            false,
        );
        let text = shown(&view.document);
        assert!(text.contains("Your mail server is on a blocklist"), "{text}");
        assert!(text.contains("Blocklist: Spamhaus"), "{text}");
    }

    #[test]
    fn links_the_message_it_returns_when_it_is_there() {
        let sent = MessageRef { folder: 7, uid: 42 };
        let raw = report("nobody@example.com", "failed", "5.1.1", "550 5.1.1 User unknown");
        let asked = std::cell::RefCell::new(Vec::new());
        let find = |id: &str| {
            asked.borrow_mut().push(id.to_string());
            Some(sent)
        };
        let view = build_unless(&raw, false, &Trust::default(), &|| false, &find).unwrap();
        assert_eq!(asked.borrow().as_slice(), ["<sent@example.com>"]);
        assert_eq!(view.bounced_message, Some(sent));
        assert!(
            view.document.contains(&format!(
                "<a class=\"btn\" href=\"{}\" role=\"button\">Show the message that bounced</a>",
                pe_html::BOUNCED_MESSAGE_LINK
            )),
            "{}",
            view.document
        );
    }

    #[test]
    fn hostile_words_stay_text() {
        let raw = report(
            "<img src=x onerror=alert(1)>@example.com",
            "failed",
            "5.1.1",
            "550 <script>alert(2)</script></pre></details><a href=\"inboxclassic:bounced-message\">x</a> \u{202e}",
        );
        let view = build(&raw, false);
        assert!(view.bounce);
        assert!(
            !view.document.contains("<script") && !view.document.contains("<img"),
            "{}",
            view.document
        );
        // no direction marks reach the page
        assert!(!view.document.contains('\u{202e}'), "{}", view.document);
        // the link the words name stays text: the card has none, the message was not found
        assert!(!view.document.contains("<a "), "{}", view.document);
        assert!(
            view.document
                .contains("550 &lt;script&gt;alert(2)&lt;/script&gt;&lt;/pre&gt;"),
            "{}",
            view.document
        );
    }

    #[test]
    fn ordinary_mail_has_no_card() {
        let view = build(MESSAGE, false);
        assert!(!view.bounce);
        assert!(!view.document.contains("pe-bounce-"));
    }

    /// The card of a failure, a delay and a blocklist as documents to look at, written to the folder in
    /// PE_BOUNCE_PREVIEW (`PE_BOUNCE_PREVIEW=../build/bounce-preview cargo test -p pe-core bounce_previews`)
    #[test]
    fn bounce_previews() {
        let Some(dir) = std::env::var_os("PE_BOUNCE_PREVIEW") else {
            return;
        };
        let dir = std::path::PathBuf::from(dir);
        std::fs::create_dir_all(&dir).unwrap();
        let several = [
            "From: Mail Delivery System <MAILER-DAEMON@mx.example.com>",
            "Subject: Undelivered Mail Returned to Sender",
            "MIME-Version: 1.0",
            "Content-Type: multipart/report; report-type=delivery-status; boundary=\"B\"",
            "",
            "--B",
            "Content-Type: text/plain",
            "",
            "Some recipients failed.",
            "--B",
            "Content-Type: message/delivery-status",
            "",
            "Reporting-MTA: dns; mx.example.com",
            "",
            "Final-Recipient: rfc822; first@example.com",
            "Action: failed",
            "Status: 5.1.1",
            "Remote-MTA: dns; mx.first.example",
            "Diagnostic-Code: smtp; 550 5.1.1 User unknown",
            "",
            "Final-Recipient: rfc822; second@example.com",
            "Action: delayed",
            "Status: 4.2.0",
            "Diagnostic-Code: smtp; 450 4.2.0 Greylisted, try again in 5 minutes",
            "",
            "Final-Recipient: rfc822; fourth@example.com",
            "Action: failed",
            "Status: 5.2.2",
            "Diagnostic-Code: smtp; 552 5.2.2 Mailbox full",
            "--B--",
            "",
        ]
        .join("\r\n");
        let linked = |id: &str| (id == "<sent@example.com>").then_some(MessageRef { folder: 1, uid: 1 });
        let pages: [(&str, Vec<u8>); 6] = [
            ("failed.html", bounce_fixture("gmail.eml")),
            ("delayed.html", bounce_fixture("delayed.eml")),
            (
                "blocklist.html",
                report(
                    "user@example.org",
                    "failed",
                    "5.7.1",
                    "554 5.7.1 Service unavailable; Client host [203.0.113.5] blocked using zen.spamhaus.org; https://www.spamhaus.org/query/ip/203.0.113.5",
                ),
            ),
            ("several.html", several.into_bytes()),
            (
                "delayed-blocklist.html",
                report(
                    "user@example.org",
                    "delayed",
                    "4.7.1",
                    "451 4.7.1 Client host [203.0.113.5] blocked using zen.spamhaus.org; try again later",
                ),
            ),
            ("outlook.html", bounce_fixture("outlook.eml")),
        ];
        for (name, raw) in pages {
            let view = build_unless(&raw, false, &Trust::default(), &|| false, &linked).unwrap();
            std::fs::write(dir.join(name), view.document).unwrap();
        }
    }

    #[test]
    fn a_message_past_the_limits_says_so() {
        let mut deep = Vec::new();
        for i in 0..300 {
            deep.extend(format!("Content-Type: multipart/mixed; boundary=b{i}\r\n\r\n--b{i}\r\n").bytes());
        }
        let view = build(&deep, false);
        assert!(view.document.contains("can not be shown"), "{}", view.document);
    }
}
