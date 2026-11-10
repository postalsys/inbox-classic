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
    pub attachments: Vec<AttachmentView>,
    /// How the message lets its reader leave its mailing list, None when it does not say
    pub unsubscribe: Option<crate::unsubscribe::Unsubscribe>,
    /// The event of its calendar part (an invitation, an update, a cancellation), None without one
    pub invitation: Option<crate::calendar::Invitation>,
    /// The brand has a BIMI logo the receiving server passed ([`crate::Core::logo_start`] draws it)
    pub has_logo: bool,
    /// It is a bounce, a notice that a message was not delivered or not yet: the document starts with its card
    pub bounce: bool,
    /// The message the bounce returns, found in the account by its Message-ID (Sent Items first): the card links to
    /// it with [`pe_html::BOUNCED_MESSAGE_LINK`], and the apps select this one when that link is clicked
    pub bounced_message: Option<MessageRef>,
    /// The one-time code of the card at the top of the document (Copy puts it on the clipboard), None without one
    pub otp_code: Option<String>,
}

/// Whose word counts for a message: the domains whose Authentication-Results verdicts the account's provider gives,
/// and whether its folder may show the card of a one-time code (not Junk E-mail, Sent Items or Drafts)
#[derive(Default)]
pub(crate) struct Trust<'a> {
    pub domains: &'a [String],
    pub codes: bool,
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
fn listed(attachments: &[Attachment]) -> impl Iterator<Item = &Attachment> {
    attachments
        .iter()
        .filter(|a| !a.related && !REPORT_PARTS.iter().any(|p| a.mime_type.eq_ignore_ascii_case(p)))
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
    let options = RenderOptions { allow_remote_images };
    let message = match parser::parse(source) {
        Ok(message) => message,
        Err(error) => {
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
    let images = crate::compose::inline_images(&message);
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
    let date = message.timestamp.map(pe_smtp::message::format_date).unwrap_or_default();
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
    };
    let rendered = pe_html::render_view_cards(&body, &options, &images, &header, &cards);
    Some(MessageView {
        subject,
        from,
        to,
        cc,
        date: message.timestamp,
        document: rendered.document,
        remote_images: rendered.remote_images,
        attachments: listed(&message.attachments)
            .map(|a| AttachmentView {
                safe_filename: a.safe_filename(),
                filename: a.display_filename(),
                mime_type: a.mime_type.clone(),
                size: a.content.len() as u64,
            })
            .collect(),
        unsubscribe: crate::unsubscribe::of(&message.headers, trust.domains),
        has_logo: crate::bimi::of(&message.headers, trust.domains).is_some(),
        invitation,
        bounce: bounce.is_some(),
        bounced_message,
        otp_code: code.map(|code| code.code),
    })
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
    listed(&message.attachments)
        .map(|a| (a.safe_filename(), a.content.clone()))
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
                size: 4
            }]
        );
        assert_eq!(attachment(MESSAGE, 0), Some(("report.pdf".into(), b"%PDF".to_vec())));
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
