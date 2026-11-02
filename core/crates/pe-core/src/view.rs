//! A message as the preview shows it: the header fields as text, the body as a sanitized
//! document with its inline images, and the attachments with names that are safe to save under

use pe_html::RenderOptions;
use pe_mime::parser::{self, Attachment, text_addresses, text_to_html};

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
}

/// The attachments the attachment bar lists: not the images of an HTML body
fn listed(attachments: &[Attachment]) -> impl Iterator<Item = &Attachment> {
    attachments.iter().filter(|a| !a.related)
}

#[cfg(test)]
pub(crate) fn build(source: &[u8], allow_remote_images: bool) -> MessageView {
    build_unless(source, allow_remote_images, &|| false).unwrap_or_default()
}

/// [`build`], given up (None) between its steps once `dropped` says nobody waits for it anymore
pub(crate) fn build_unless(
    source: &[u8],
    allow_remote_images: bool,
    dropped: &dyn Fn() -> bool,
) -> Option<MessageView> {
    let options = RenderOptions { allow_remote_images };
    let message = match parser::parse(source) {
        Ok(message) => message,
        Err(error) => {
            let text = format!("This message can not be shown: {error}");
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
    let header = [
        ("From", from.as_str()),
        ("Date", date.as_str()),
        ("To", to.as_str()),
        ("Cc", cc.as_str()),
        ("Subject", subject.as_str()),
    ];
    let rendered = pe_html::render_view(&body, &options, &images, &header);
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
        let shown = |c: char| c == '\t' || !(c.is_control() || parser::is_direction_mark(c));
        out.extend(line.chars().map(|c| if shown(c) { c } else { ' ' }));
        out.push_str("\r\n");
    }
    out
}

/// The content of the `index`th listed attachment, with the name to save it under
pub(crate) fn attachment(source: &[u8], index: usize) -> Option<(String, Vec<u8>)> {
    attachments(source).into_iter().nth(index)
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
        assert!(build_unless(MESSAGE, false, &|| true).is_none());
        assert!(build_unless(MESSAGE, false, &|| false).is_some());
        // once it is dropped halfway, after parsing
        let asked = std::cell::Cell::new(0);
        let dropped = || {
            asked.set(asked.get() + 1);
            asked.get() > 1
        };
        assert!(build_unless(MESSAGE, false, &dropped).is_none());
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
