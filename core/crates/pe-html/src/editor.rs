//! The documents of writing mail: the page of the compose window's editor, the quoted message of a reply or forward,
//! and the HTML that is sent.
//!
//! The editor is the one page with a script: `editor.js`, allowed by a random nonce in the CSP, so nothing else can
//! run. The quoted message waits in an inert template, without style elements, folded behind "..." in a reply; the
//! page puts it into the text when unfolded (or on Select All), inside a paint-contained block so its inline styles
//! can not cover the rest of the editor. Folded, it is added back when the message is sent.

use std::borrow::Cow;
use std::collections::HashMap;
use std::sync::{Arc, Mutex};

use base64::Engine;
use base64::engine::general_purpose::STANDARD;

use crate::{InlineImage, builder};

const EDITOR_SCRIPT: &str = include_str!("editor.js");

/// The pictures a message carries in its HTML: what every mail program shows
const PICTURE_TYPES: [&str; 4] = ["image/png", "image/jpeg", "image/gif", "image/webp"];

/// The most bytes of pictures a message carries in its HTML, all together
const MAX_PICTURE_BYTES: usize = 25 * 1024 * 1024;

/// The page of the editor. `quote` is HTML from [`quote_html`] (already sanitized), shown folded when `folded`;
/// `body` what was written so far, from [`draft_body`] for a saved draft opened again, or empty.
pub fn editor_document(quote: Option<&str>, folded: bool, body: &str) -> String {
    let nonce = nonce();
    // sanitized again, as the quote is
    let body = match draft_body(body, &[]) {
        body if body.trim().is_empty() => "<div><br></div>".to_string(),
        body => body,
    };
    // the quote waits in a template, which the page does not show, load or run: the editor's "..." (or Select All)
    // puts it into the text, where it is edited and selected like the rest. Sanitized again here, so whatever the
    // caller hands in, it is markup without scripts or handlers, and no `</template>` of it can end the template.
    let quote = quote.filter(|q| !q.trim().is_empty()).map_or(String::new(), |quote| {
        format!(
            "<div id=\"fold\"><button id=\"more\" type=\"button\" title=\"Show the quoted message\">&#8226;&#8226;&#8226;</button></div>\
             <template id=\"quote\" data-folded=\"{}\">{}</template>",
            if folded { "1" } else { "0" },
            quote_sanitizer(&[]).clean(quote)
        )
    });
    format!(
        "<!doctype html><html><head><meta charset=\"utf-8\">\
         <meta http-equiv=\"Content-Security-Policy\" content=\"default-src 'none'; script-src 'nonce-{nonce}'; style-src 'unsafe-inline'; img-src data:; font-src data:\">\
         <meta name=\"color-scheme\" content=\"light\">\
         <style>\
         html{{background:#fff}}\
         body{{margin:0;font:10pt Arial,sans-serif;color:#000}}\
         #body{{min-height:4.5em;padding:8px;outline:none;word-wrap:break-word}}\
         #body img{{max-width:100%}}\
         blockquote{{margin:0 0 0 .8ex;border-left:2px solid #036;padding-left:1ex}}\
         .quoted{{contain:paint}}\
         #fold{{padding:0 8px 4px}}\
         #fold[hidden]{{display:none}}\
         #more{{font:bold 9pt Arial,sans-serif;letter-spacing:1px;color:#555;background:#eee;border:1px solid #ccc;\
         border-radius:9px;padding:0 9px;height:17px;line-height:13px;cursor:pointer}}\
         #more:hover{{background:#e2e2e2;color:#000}}\
         #more:focus-visible{{outline:2px solid #036;outline-offset:1px}}\
         </style></head>\
         <body><div id=\"body\" contenteditable=\"true\" role=\"textbox\" aria-multiline=\"true\" aria-label=\"Message\">{body}</div>\
         {quote}<script nonce=\"{nonce}\">{EDITOR_SCRIPT}</script></body></html>"
    )
}

/// The part of the editor's HTML that the user wrote: up to the signature's block ([`signature_block`]), or a quoted
/// message put into the text ([`quote_html`]: a reply's blockquote, a forward's header)
pub fn written_part(html: &str) -> &str {
    let quote_header = text(&pe_i18n::tr(pe_i18n::Text::QuoteOriginal));
    let ends = [
        html.find("class=\"pe-signature\"").and_then(|at| html[..at].rfind('<')),
        html.find("<blockquote"),
        Some(quote_header.as_str())
            .filter(|h| !h.is_empty())
            .and_then(|h| html.find(h)),
    ];
    &html[..ends.into_iter().flatten().min().unwrap_or(html.len())]
}

/// The sanitizer of a quoted message: without style elements, which would restyle the whole page (the editor's, or
/// the sent message above the quote); inline styles stay
fn quote_sanitizer(images: &[InlineImage]) -> ammonia::Builder<'static> {
    let mut sanitizer = builder(images);
    sanitizer.rm_tags(["style"]).add_clean_content_tags(["style"]);
    sanitizer
}

/// What was written in a saved draft, to edit again: sanitized as a quote is, its `cid:` pictures as `data:` URIs,
/// which [`outgoing_html`] turns back into attachments when it is sent
pub fn draft_body(html: &str, images: &[InlineImage]) -> String {
    quote_sanitizer(images).clean(html).to_string()
}

/// A signature as it is kept: what was written in the signature editor, sanitized as a draft is (its pictures as
/// `data:` URIs), without the empty lines around it
pub fn signature_html(html: &str) -> String {
    let clean = draft_body(html, &[]);
    let mut text = clean.trim();
    loop {
        let before = text;
        for empty in ["<div><br></div>", "<p><br></p>", "<br>"] {
            text = text.strip_prefix(empty).unwrap_or(text).trim_start();
            text = text.strip_suffix(empty).unwrap_or(text).trim_end();
        }
        if text == before {
            return text.to_string();
        }
    }
}

/// What a new message, reply or forward starts with when the account has a signature: an empty line to write on,
/// then the signature after the usual "-- " line, in a block the editor knows to swap for another account's. Empty
/// without a signature.
pub fn signature_block(signature: &str) -> String {
    // kept sanitized (signature_html), and the editor sanitizes its page again
    let signature = signature.trim();
    if signature.is_empty() {
        return String::new();
    }
    format!("<div><br></div><div><br></div><div class=\"pe-signature\">-- <br>{signature}</div>")
}

/// The quoted message of a reply or forward for the editor and for sending: the header block in the manner of
/// Outlook Express, then the message, sanitized, its `cid:` pictures embedded. A reply is indented by a bar.
pub fn quote_html(header: &[(&str, String)], html: &str, images: &[InlineImage], reply: bool) -> String {
    let mut block = format!(
        "<div style=\"font:10pt Arial,sans-serif\">{}</div>",
        text(&pe_i18n::tr(pe_i18n::Text::QuoteOriginal))
    );
    for (name, value) in header.iter().filter(|(_, value)| !value.is_empty()) {
        block.push_str(&format!(
            "<div style=\"font:10pt Arial,sans-serif\"><b>{}:</b> {}</div>",
            text(name),
            text(value)
        ));
    }
    block.push_str(QUOTE_HEADER_END);
    block.push_str(&quote_sanitizer(images).clean(html).to_string());
    if reply {
        format!(
            "<blockquote type=\"cite\" style=\"margin:0 0 0 .8ex;border-left:2px solid #036;padding-left:1ex\">{block}</blockquote>"
        )
    } else {
        block
    }
}

/// Whether what was written has no formatting at all: nothing but text in paragraphs and lines, which then goes as
/// text/plain. Judged by sanitizing it twice, keeping only `div`, `p`, `br` and plain `span`, and as usual: the same
/// both times means there was nothing else.
pub fn is_plain(html: &str) -> bool {
    let mut plain = ammonia::Builder::empty();
    plain.tags(std::collections::HashSet::from(["div", "p", "br", "span"]));
    plain.clean(html).to_string() == crate::mail_builder().clean(html).to_string()
}

/// The empty line [`quote_html`] puts between the header block of a quoted message and the message
const QUOTE_HEADER_END: &str = "<div><br></div>";

/// A quoted message of [`quote_html`] (maybe trimmed by the user) apart: whether it is a reply's (in a blockquote),
/// its header block and the message after it
pub fn quote_parts(quote: &str) -> (bool, &str, &str) {
    let quote = quote.trim();
    let reply = quote.starts_with("<blockquote");
    let (header, body) = quote.split_once(QUOTE_HEADER_END).unwrap_or(("", quote));
    (reply, header, body)
}

/// A picture of the message, from a `data:` URI of its HTML, to go in multipart/related
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct Picture {
    /// Without angle brackets
    pub content_id: String,
    pub mime_type: String,
    pub data: Vec<u8>,
}

/// The HTML to send: what was written, then the quoted message (both sanitized again, as one), with its `data:`
/// pictures turned into `cid:` references to the pictures returned beside it. A picture that is not one, does not
/// decode or is past the budget is dropped. Identical pictures are sent once.
pub fn outgoing_html(written: &str, quote: Option<&str>, domain: &str) -> (String, Vec<Picture>) {
    let html = match quote.filter(|q| !q.trim().is_empty()) {
        Some(quote) => format!("{written}<div><br></div>{quote}"),
        None => written.to_string(),
    };
    let pictures: Arc<Mutex<Pictures>> = Arc::default();
    let collected = Arc::clone(&pictures);
    let domain = domain.to_string();
    let mut sanitizer = crate::mail_builder();
    sanitizer.attribute_filter(move |element, attribute, value| {
        let lower = value
            .trim_start()
            .get(..5)
            .map(str::to_ascii_lowercase)
            .unwrap_or_default();
        if lower != "data:" {
            return Some(Cow::Borrowed(value));
        }
        if element != "img" || attribute != "src" {
            return None;
        }
        let mut pictures = collected.lock().unwrap_or_else(|e| e.into_inner());
        pictures
            .add(value.trim(), &domain)
            .map(|cid| Cow::Owned(format!("cid:{cid}")))
    });
    let clean = sanitizer.clean(&html).to_string();
    drop(sanitizer);
    let pictures = std::mem::take(&mut pictures.lock().unwrap_or_else(|e| e.into_inner()).list);
    (clean, pictures)
}

#[derive(Default)]
struct Pictures {
    /// makes the Content-IDs of this message unique
    tag: String,
    list: Vec<Picture>,
    /// the data: URI to its Content-ID
    seen: HashMap<String, String>,
    bytes: usize,
}

impl Pictures {
    /// The Content-ID for a `data:` picture, None when it is no picture or over the budget
    fn add(&mut self, uri: &str, domain: &str) -> Option<String> {
        if let Some(cid) = self.seen.get(uri) {
            return Some(cid.clone());
        }
        let (meta, payload) = uri.get(5..)?.split_once(',')?;
        let mime_type = meta.strip_suffix(";base64")?.trim().to_ascii_lowercase();
        if !PICTURE_TYPES.contains(&mime_type.as_str()) {
            return None;
        }
        let payload: String = payload.chars().filter(|c| !c.is_ascii_whitespace()).collect();
        let data = STANDARD.decode(payload).ok()?;
        if data.is_empty() || self.bytes + data.len() > MAX_PICTURE_BYTES {
            return None;
        }
        self.bytes += data.len();
        if self.tag.is_empty() {
            self.tag = nonce();
        }
        let cid = format!("picture{}.{}@{domain}", self.list.len() + 1, self.tag);
        self.seen.insert(uri.to_string(), cid.clone());
        self.list.push(Picture {
            content_id: cid.clone(),
            mime_type,
            data,
        });
        Some(cid)
    }
}

/// The largest picture file Insert Picture puts in the text
pub const PICTURE_FILE_LIMIT: usize = 10 * 1024 * 1024;

/// The type of a picture every mail program shows, by its first bytes ([`PICTURE_HEAD`] of them are enough)
pub fn picture_type(head: &[u8]) -> Option<&'static str> {
    if head.starts_with(b"\x89PNG\r\n\x1a\n") {
        Some("image/png")
    } else if head.starts_with(b"\xff\xd8\xff") {
        Some("image/jpeg")
    } else if head.starts_with(b"GIF87a") || head.starts_with(b"GIF89a") {
        Some("image/gif")
    } else if head.len() >= 12 && head.starts_with(b"RIFF") && &head[8..12] == b"WEBP" {
        Some("image/webp")
    } else {
        None
    }
}

/// How many first bytes of a file [`picture_type`] needs
pub const PICTURE_HEAD: usize = 12;

/// A picture file for the editor's Insert Picture: a `data:` URI when `data` is a picture of a kind every mail
/// program shows, by its first bytes rather than its name
pub fn picture_uri(data: &[u8]) -> Option<String> {
    let mime_type = picture_type(data)?;
    (data.len() <= PICTURE_FILE_LIMIT).then(|| format!("data:{mime_type};base64,{}", STANDARD.encode(data)))
}

/// 128 random bits as hex, for the script nonce and Content-IDs. Should the system have no randomness to give, the
/// clock and a counter make it unique at least: the nonce adds to the sanitizer and the CSP, it is not the only guard.
pub(crate) fn nonce() -> String {
    static COUNTER: std::sync::atomic::AtomicU64 = std::sync::atomic::AtomicU64::new(0);
    let mut bytes = [0u8; 16];
    if getrandom::fill(&mut bytes).is_err() {
        let nanos = std::time::SystemTime::now()
            .duration_since(std::time::UNIX_EPOCH)
            .map_or(0, |d| d.as_nanos());
        let count = COUNTER.fetch_add(1, std::sync::atomic::Ordering::Relaxed);
        bytes[..8].copy_from_slice(&(nanos as u64).to_le_bytes());
        bytes[8..].copy_from_slice(&count.to_le_bytes());
    }
    bytes.iter().map(|b| format!("{b:02x}")).collect()
}

/// Text in HTML
pub(crate) fn text(value: &str) -> String {
    value.replace('&', "&amp;").replace('<', "&lt;").replace('>', "&gt;")
}

/// The tags an editor body is allowed to keep, for tests
#[cfg(test)]
fn tags(html: &str) -> std::collections::HashSet<String> {
    html.split('<')
        .skip(1)
        .filter_map(|t| t.split(|c: char| !c.is_ascii_alphanumeric()).next())
        .filter(|t| !t.is_empty())
        .map(str::to_ascii_lowercase)
        .collect()
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn keeps_a_signature_sanitized_without_empty_lines() {
        assert_eq!(
            signature_html(
                "<div><br></div><p><b>Ann</b> <a href=\"https://ann.example\">site</a></p><br><script>x()</script>"
            ),
            "<p><b>Ann</b> <a href=\"https://ann.example\" rel=\"noopener noreferrer\">site</a></p>"
        );
        assert_eq!(signature_html("<div><br></div>  <br>"), "");
        // pictures of its own are kept, as data: URIs, which go as attachments when sent
        assert!(signature_html("<img src=\"data:image/png;base64,iVBORw0KGgo=\">").contains("data:image/png"));
        let block = signature_block("<p>Ann</p>");
        assert_eq!(
            block,
            "<div><br></div><div><br></div><div class=\"pe-signature\">-- <br><p>Ann</p></div>"
        );
        assert_eq!(signature_block(" "), "");
        // the editor keeps the block as it is, for From to swap it
        assert!(editor_document(None, false, &block).contains("<div class=\"pe-signature\">-- <br><p>Ann</p></div>"));
    }

    #[test]
    fn the_editor_runs_only_its_own_script() {
        let page = editor_document(
            Some("<p>quoted<script>alert(1)</script></p></template><img src=x onerror=alert(2)>"),
            true,
            "",
        );
        let nonce = page.split("'nonce-").nth(1).unwrap().split('\'').next().unwrap();
        assert_eq!(nonce.len(), 32);
        assert!(page.contains(&format!("<script nonce=\"{nonce}\">")));
        // one script element, the editor's: the quote's own is gone, and so are its handlers
        assert_eq!(page.matches("<script").count(), 1, "{page}");
        assert!(!page.contains("onerror"), "{page}");
        // the quote waits in a template, folded; a `</template>` in it is text, not the end of the template
        assert!(
            page.contains("<template id=\"quote\" data-folded=\"1\"><p>quoted</p>"),
            "{page}"
        );
        assert_eq!(page.matches("</template>").count(), 1, "{page}");
        // its style elements would style the whole editor once it is unfolded
        let page = editor_document(
            Some("<style>body{display:none}</style><p style=\"color:red\">q</p>"),
            true,
            "",
        );
        assert!(
            page.contains("data-folded=\"1\"><p style=\"color:red\">q</p></template>"),
            "{page}"
        );
        // two pages have different nonces
        assert_ne!(
            editor_document(None, false, "").split("'nonce-").nth(1),
            page.split("'nonce-").nth(1)
        );
    }

    #[test]
    fn formatting_is_told_from_plain_text() {
        assert!(is_plain("<div>a</div><div><br></div><p>b</p><span>c</span>"));
        for formatted in [
            "<b>a</b>",
            "<div style=\"color:red\">a</div>",
            "<ul><li>a</li></ul>",
            "<img src=\"data:image/png;base64,AA\">",
        ] {
            assert!(!is_plain(formatted), "{formatted}");
        }
        let (reply, header, body) =
            quote_parts("<blockquote type=\"cite\"><div>From: a</div><div><br></div><p>hi</p></blockquote>");
        assert!(reply);
        assert_eq!(
            (header, body),
            ("<blockquote type=\"cite\"><div>From: a</div>", "<p>hi</p></blockquote>")
        );
    }

    #[test]
    fn a_new_message_has_no_quote() {
        let page = editor_document(None, false, "");
        assert!(!page.contains("<template") && !page.contains("id=\"more\""));
        assert!(page.contains("contenteditable=\"true\""));
        assert!(!editor_document(Some("  "), true, "").contains("<template"));
        // an empty body is one empty line to write on
        assert!(page.contains("aria-label=\"Message\"><div><br></div></div>"), "{page}");
    }

    #[test]
    fn a_draft_goes_on_where_it_was_left() {
        let page = editor_document(
            None,
            false,
            "<p>half <b>written</b></p><script>bad()</script><style>body{display:none}</style><img src=x onerror=y()>",
        );
        assert!(
            page.contains("aria-label=\"Message\"><p>half <b>written</b></p>"),
            "{page}"
        );
        assert_eq!(page.matches("<script").count(), 1, "{page}");
        assert!(!page.contains("onerror") && !page.contains("bad()"), "{page}");
        // its pictures come in as data: URIs, which sending turns back into attachments
        let image = InlineImage {
            content_id: "pic@x",
            mime_type: "image/png",
            data: b"png",
        };
        let body = draft_body("<p><img src=\"cid:pic@x\"></p><style>p{}</style>", &[image]);
        assert_eq!(body, "<p><img src=\"data:image/png;base64,cG5n\"></p>");
    }

    #[test]
    fn quotes_like_outlook_express() {
        let header = [
            ("From", "Ann <ann@example.com>".to_string()),
            ("Cc", String::new()),
            ("Subject", "Plans & <dates>".to_string()),
        ];
        let reply = quote_html(
            &header,
            "<style>div{display:none}</style><p onclick=x() style=\"color:red\">Hi</p><img src=\"cid:logo\">",
            &[],
            true,
        );
        // the quote's style elements go, its inline styles stay
        assert!(
            !reply.contains("display:none") && reply.contains("color:red"),
            "{reply}"
        );
        assert!(reply.starts_with("<blockquote type=\"cite\""), "{reply}");
        assert!(reply.contains("----- Original Message -----"));
        assert!(reply.contains("<b>From:</b> Ann &lt;ann@example.com&gt;"));
        assert!(reply.contains("<b>Subject:</b> Plans &amp; &lt;dates&gt;"));
        // an empty field is left out, the message is sanitized
        assert!(!reply.contains("Cc:") && !reply.contains("onclick"));
        let image = InlineImage {
            content_id: "logo",
            mime_type: "image/png",
            data: b"\x89PNG",
        };
        let forward = quote_html(&header, "<img src=\"cid:logo\">", &[image], false);
        assert!(!forward.contains("blockquote"));
        assert!(forward.contains("src=\"data:image/png;base64,iVBORw==\""), "{forward}");
    }

    #[test]
    fn pictures_go_as_attachments() {
        let png = format!("data:image/png;base64,{}", STANDARD.encode(b"\x89PNG one"));
        let written = format!(
            "<div>Hi <b>there</b></div><img src=\"{png}\"><img src=\"{png}\"><img src=\"data:text/html;base64,PHA+\">\
             <a href=\"data:text/html,x\">x</a><script>alert(1)</script>"
        );
        let (html, pictures) = outgoing_html(&written, Some("<blockquote>old</blockquote>"), "example.com");
        assert_eq!(pictures.len(), 1, "{pictures:?}");
        assert_eq!(pictures[0].mime_type, "image/png");
        assert_eq!(pictures[0].data, b"\x89PNG one");
        assert!(pictures[0].content_id.ends_with("@example.com"));
        // the same picture twice is one attachment referenced twice
        assert_eq!(
            html.matches(&format!("cid:{}", pictures[0].content_id)).count(),
            2,
            "{html}"
        );
        assert!(!html.contains("data:") && !html.contains("<script"), "{html}");
        assert!(
            html.contains("<b>there</b>") && html.ends_with("<blockquote>old</blockquote>"),
            "{html}"
        );
        assert!(tags(&html).is_subset(&std::collections::HashSet::from(
            ["div", "b", "img", "a", "blockquote", "br"].map(String::from)
        )));
    }

    #[test]
    fn pictures_have_a_budget() {
        let big = format!(
            "data:image/png;base64,{}",
            STANDARD.encode(vec![0u8; MAX_PICTURE_BYTES / 2 + 1])
        );
        let other = format!(
            "data:image/gif;base64,{}",
            STANDARD.encode(vec![1u8; MAX_PICTURE_BYTES / 2 + 1])
        );
        let (html, pictures) = outgoing_html(&format!("<img src=\"{big}\"><img src=\"{other}\">"), None, "x");
        assert_eq!(pictures.len(), 1);
        assert_eq!(html.matches("cid:").count(), 1, "{}", &html[..200.min(html.len())]);
    }

    #[test]
    fn picture_files_are_checked_by_content() {
        assert_eq!(
            picture_uri(b"GIF89a.."),
            Some("data:image/gif;base64,R0lGODlhLi4=".into())
        );
        assert!(
            picture_uri(b"\xff\xd8\xff\xe0")
                .unwrap()
                .starts_with("data:image/jpeg;")
        );
        assert_eq!(picture_uri(b"<svg onload=alert(1)>"), None);
        assert_eq!(picture_uri(b"MZ\x90\x00"), None);
        assert!(
            picture_uri(b"RIFF\x10\0\0\0WEBPVP8 ")
                .unwrap()
                .starts_with("data:image/webp;")
        );
    }
}
