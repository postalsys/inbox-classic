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
    let document = pe_html::render_message_with_header(&body, &options, &images, &header);
    Some(MessageView {
        subject,
        from,
        to,
        cc,
        date: message.timestamp,
        document,
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

/// The content of the `index`th listed attachment, with the name to save it under
pub(crate) fn attachment(source: &[u8], index: usize) -> Option<(String, Vec<u8>)> {
    let message = parser::parse(source).ok()?;
    let attachment = message.attachments.into_iter().filter(|a| !a.related).nth(index)?;
    Some((attachment.safe_filename(), attachment.content))
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
