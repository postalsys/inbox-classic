//! HTML of messages made safe to show. Message bodies are written by whoever sent the mail, so they are sanitized here
//! before the C++ app hands them to WebView2, which then shows them with scripts off and network requests refused.
//! The CSP of the document is one more layer on top of both.
#![forbid(unsafe_code)]

use std::borrow::Cow;
use std::collections::hash_map::Entry;
use std::collections::{HashMap, HashSet};
use std::sync::OnceLock;
use std::sync::atomic::{AtomicUsize, Ordering};

use base64::Engine;
use base64::engine::general_purpose::STANDARD;

mod editor;
pub use editor::{Picture, draft_body, editor_document, outgoing_html, picture_uri, quote_html};

/// An image a message carries for its HTML, referenced as `cid:` (multipart/related)
#[derive(Debug, Clone, Copy)]
pub struct InlineImage<'a> {
    /// The Content-ID, with or without its angle brackets
    pub content_id: &'a str,
    pub mime_type: &'a str,
    pub data: &'a [u8],
}

/// How a message document is rendered.
#[derive(Debug, Clone, Copy, Default)]
pub struct RenderOptions {
    /// Lets the CSP allow images from http(s), after the user clicked the blocked-pictures bar. The WebView2 request
    /// filter of the app has to allow them too.
    pub allow_remote_images: bool,
}

/// The most bytes the `data:` URIs of embedded images add to a message, so a small image referenced a million times
/// does not make a document of gigabytes
const MAX_EMBEDDED_BYTES: usize = 64 * 1024 * 1024;

/// The sanitizer of mail markup without an attribute filter (ammonia takes one, set by the caller). Mail layout lives
/// in inline styles, style elements and old presentational attributes. CSS can not run code, and what it could load
/// from the network is refused by the CSP and by the WebView2 request filter.
pub(crate) fn mail_builder() -> ammonia::Builder<'static> {
    let mut builder = ammonia::Builder::default();
    builder
        .rm_clean_content_tags(["style"])
        .add_tags(["style", "font", "center"])
        .add_generic_attributes([
            "style",
            "align",
            "valign",
            "bgcolor",
            "background",
            "width",
            "height",
            "border",
            "cellpadding",
            "cellspacing",
            "color",
            "face",
            "size",
            "dir",
        ])
        .url_schemes(HashSet::from(["http", "https", "mailto", "cid", "data"]))
        // the folds of earlier messages (pe-core fold.rs), styled by the preview document
        .add_allowed_classes("details", ["pe-fold"]);
    builder
}

/// The sanitizer for a message with `images`. Mail layout lives in inline styles, style elements and old presentational
/// attributes. CSS can not run code, and what it could load from the network is refused by the CSP and by the WebView2
/// request filter.
pub(crate) fn builder(images: &[InlineImage]) -> ammonia::Builder<'static> {
    let embedder = Embedder::new(images);
    let mut builder = mail_builder();
    builder.attribute_filter(move |element, attribute, value| {
        let img_src = element == "img" && attribute == "src";
        let scheme = value
            .trim_start()
            .get(..5)
            .map(str::to_ascii_lowercase)
            .unwrap_or_default();
        if scheme == "data:" && !img_src {
            // data: is for images only, a data: link could open a document of its own
            return None;
        }
        if scheme.starts_with("cid:")
            && (img_src || attribute == "background")
            && let Some(uri) = embedder.embed(value)
        {
            return Some(Cow::Owned(uri));
        }
        Some(Cow::Borrowed(value))
    });
    builder
}

/// Turns `cid:` URLs into `data:` URIs of the images they name. Only images: anything else stays a `cid:` the preview
/// can not load. The sanitizer wants a callback that owns its data, so the images are copied in.
struct Embedder {
    /// Content-ID, lowercased, to the image; the first image of an ID wins
    by_id: HashMap<String, usize>,
    images: Vec<(String, Vec<u8>)>,
    /// Each image encoded once, when it is first referenced
    uris: Vec<OnceLock<String>>,
    embedded: AtomicUsize,
}

impl Embedder {
    fn new(images: &[InlineImage]) -> Self {
        let mut by_id = HashMap::new();
        let mut owned = Vec::new();
        for image in images.iter().filter(|image| image.mime_type.starts_with("image/")) {
            if let Entry::Vacant(entry) = by_id.entry(content_id(image.content_id).to_lowercase()) {
                entry.insert(owned.len());
                owned.push((image.mime_type.to_string(), image.data.to_vec()));
            }
        }
        Embedder {
            by_id,
            uris: owned.iter().map(|_| OnceLock::new()).collect(),
            images: owned,
            embedded: AtomicUsize::new(0),
        }
    }

    /// The `data:` URI for a `cid:` URL, None for an unknown image or when the budget is spent
    fn embed(&self, url: &str) -> Option<String> {
        let index = *self.by_id.get(&content_id(&url.trim_start()[4..]).to_lowercase())?;
        let uri = self.uris[index].get_or_init(|| {
            let (mime_type, data) = &self.images[index];
            format!("data:{mime_type};base64,{}", STANDARD.encode(data))
        });
        let total = self.embedded.fetch_add(uri.len(), Ordering::Relaxed) + uri.len();
        (total <= MAX_EMBEDDED_BYTES).then(|| uri.clone())
    }
}

/// Removes everything from `html` that is not plain markup: scripts, event handlers, `javascript:` URLs, forms,
/// frames, `meta` and `base`. Returns a body fragment.
pub fn sanitize(html: &str) -> String {
    builder(&[]).clean(html).to_string()
}

/// Sanitizes `html` and wraps it in a complete document with a Content-Security-Policy, ready for the preview.
pub fn render_document(html: &str, options: &RenderOptions) -> String {
    render_message(html, options, &[])
}

/// The value of a `cid:` URL as a Content-ID: angle brackets and percent escapes removed
fn content_id(value: &str) -> String {
    let value = value.trim().trim_start_matches('<').trim_end_matches('>');
    let bytes = value.as_bytes();
    let mut out = Vec::with_capacity(bytes.len());
    let mut i = 0;
    while i < bytes.len() {
        let hex = |c: u8| (c as char).to_digit(16).map(|d| d as u8);
        if bytes[i] == b'%'
            && let (Some(high), Some(low)) = (
                bytes.get(i + 1).and_then(|c| hex(*c)),
                bytes.get(i + 2).and_then(|c| hex(*c)),
            )
        {
            out.push(high << 4 | low);
            i += 3;
            continue;
        }
        out.push(bytes[i]);
        i += 1;
    }
    String::from_utf8_lossy(&out).into_owned()
}

/// A message for the preview: sanitized, its `cid:` images embedded, in a document with a CSP
pub fn render_message(html: &str, options: &RenderOptions, images: &[InlineImage]) -> String {
    render_message_with_header(html, options, images, &[])
}

/// [`render_message`] with the header fields of the message (`From`, `Subject`, ...), which only a printout shows:
/// on screen the window shows them above the message
pub fn render_message_with_header(
    html: &str,
    options: &RenderOptions,
    images: &[InlineImage],
    header: &[(&str, &str)],
) -> String {
    let image_sources = if options.allow_remote_images {
        "data: http: https:"
    } else {
        "data:"
    };
    let body = builder(images).clean(html).to_string();
    // the header of a printout, under a class and in a cascade layer the message can not guess: an important rule
    // of the first layer beats any important rule of the message's own style elements, whatever their selector, and
    // a message can not add rules to a layer it can not name. Its lines have inline important styles, which beat
    // the message's too. (The header the window shows is outside the message and can not be touched.)
    let class = format!("pe-print-{}", editor::nonce());
    let shown = "display:block!important;visibility:visible!important;opacity:1!important;position:static!important;\
                 color:#000!important;font:10pt Arial,sans-serif!important";
    let printed: String = header
        .iter()
        .filter(|(_, value)| !value.is_empty())
        .map(|(name, value)| {
            format!(
                "<div style=\"{shown}\"><span style=\"font-weight:bold!important\">{}:</span> {}</div>",
                editor::text(name),
                editor::text(value)
            )
        })
        .collect();
    let printed = if printed.is_empty() {
        String::new()
    } else {
        format!("<div class=\"{class}\">{printed}</div>")
    };
    format!(
        "<!doctype html><html><head><meta charset=\"utf-8\">\
         <meta http-equiv=\"Content-Security-Policy\" content=\"default-src 'none'; img-src {image_sources}; style-src 'unsafe-inline'; font-src data:\">\
         <meta name=\"color-scheme\" content=\"light\">\
         <style>html{{background:#fff}}body{{font:10pt Arial,sans-serif;margin:8px}}\
         details.pe-fold{{margin:6px 0}}\
         details.pe-fold>summary{{display:inline-block;list-style:none;font:bold 9pt Arial,sans-serif;letter-spacing:1px;\
         color:#555;background:#eee;border:1px solid #ccc;border-radius:9px;padding:0 9px;height:17px;line-height:13px;\
         cursor:pointer;margin-bottom:4px}}\
         details.pe-fold>summary::-webkit-details-marker{{display:none}}\
         details.pe-fold>summary::marker{{content:\"\"}}\
         details.pe-fold>summary:hover{{background:#e2e2e2;color:#000}}\
         @page{{margin:0}}\
         @media print{{body{{margin:15mm}}}}\
         @layer {class}{{.{class}{{display:none}}\
         @media print{{.{class}{{{shown};border-bottom:1px solid #999!important;padding-bottom:6px!important;margin-bottom:10px!important}}}}}}\
         </style>\
         </head><body>{printed}{body}</body></html>"
    )
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn embeds_inline_images() {
        let png = InlineImage {
            content_id: "<logo@x>",
            mime_type: "image/png",
            data: b"\x89PNG",
        };
        let html_part = InlineImage {
            content_id: "page@x",
            mime_type: "text/html",
            data: b"<script>",
        };
        let out = render_message(
            "<img src=\"cid:logo@x\"><img src=\"CID:%3Cpage@x%3E\"><table background=\"cid:missing\"></table>",
            &RenderOptions::default(),
            &[png, html_part],
        );
        assert!(out.contains("<img src=\"data:image/png;base64,iVBORw==\">"), "{out}");
        // not an image: left as a cid: the preview can not load
        assert!(!out.contains("text/html") && !out.contains("PHNjcmlwdD4"));
        assert!(out.contains("background=\"cid:missing\""));
    }

    #[test]
    fn embeds_only_image_urls_within_the_budget() {
        let png = InlineImage {
            content_id: "a@x",
            mime_type: "image/png",
            data: &[0; 30],
        };
        let out = render_message(
            "<a href=\"cid:a@x\">x</a><table background=\"cid:A@X\"></table>",
            &RenderOptions::default(),
            &[png],
        );
        assert!(out.contains("href=\"cid:a@x\""), "{out}");
        assert!(out.contains("background=\"data:image/png;base64,AAAA"), "{out}");

        let big = vec![0; 1024 * 1024];
        let image = InlineImage {
            content_id: "big@x",
            mime_type: "image/png",
            data: &big,
        };
        let out = render_message(
            &"<img src=\"cid:big@x\">".repeat(100),
            &RenderOptions::default(),
            &[image],
        );
        let embedded = out.matches("data:image/png").count();
        assert!(embedded > 0 && embedded < 100, "{embedded}");
        assert!(out.len() < 2 * MAX_EMBEDDED_BYTES);
    }

    #[test]
    fn removes_scripts_and_handlers() {
        let out = sanitize("<p onclick=\"alert(1)\">hi</p><script>alert(2)</script><img src=x onerror=alert(3)>");
        assert!(!out.contains("script"));
        assert!(!out.contains("onclick"));
        assert!(!out.contains("onerror"));
        assert!(!out.contains("alert"));
        assert!(out.contains("<p>hi</p>"));
    }

    #[test]
    fn removes_javascript_and_data_links() {
        let out = sanitize("<a href=\"javascript:alert(1)\">a</a><a href=\" DATA:text/html,<b>x</b>\">b</a>");
        assert!(!out.contains("javascript"));
        assert!(!out.to_ascii_lowercase().contains("data:"));
    }

    #[test]
    fn keeps_embedded_images() {
        let out = sanitize("<img src=\"data:image/png;base64,AAAA\">");
        assert!(out.contains("src=\"data:image/png;base64,AAAA\""));
    }

    #[test]
    fn keeps_mail_layout() {
        let out = sanitize(
            "<style>p{color:red}</style><table bgcolor=\"#fff\"><tr><td style=\"padding:4px\">x</td></tr></table>",
        );
        assert!(out.contains("<style>p{color:red}</style>"));
        assert!(out.contains("bgcolor=\"#fff\""));
        assert!(out.contains("style=\"padding:4px\""));
    }

    #[test]
    fn removes_document_level_tags() {
        let out = sanitize(
            "<meta http-equiv=\"refresh\" content=\"0;url=https://x\"><base href=\"https://x/\"><iframe src=\"https://x\"></iframe><form><input></form>",
        );
        for tag in ["meta", "base", "iframe", "form", "input"] {
            assert!(!out.contains(tag), "{tag} in {out}");
        }
    }

    #[test]
    fn style_can_not_hide_a_script() {
        let out = sanitize("<style></style><script>alert(1)</script></style>");
        assert!(!out.contains("script"));
    }

    #[test]
    fn csp_follows_remote_images() {
        let blocked = render_document("x", &RenderOptions::default());
        assert!(blocked.contains("img-src data:;"));
        let allowed = render_document(
            "x",
            &RenderOptions {
                allow_remote_images: true,
            },
        );
        assert!(allowed.contains("img-src data: http: https:;"));
    }
}
