//! HTML of messages made safe to show. Message bodies are written by whoever sent the mail, so they are sanitized here
//! before the C++ app hands them to WebView2, which then shows them with scripts off and network requests refused.
//! The CSP of the document is one more layer on top of both.
#![forbid(unsafe_code)]

use std::borrow::Cow;
use std::collections::HashSet;
use std::sync::LazyLock;

use base64::Engine;
use base64::engine::general_purpose::STANDARD;

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

static SANITIZER: LazyLock<ammonia::Builder<'static>> = LazyLock::new(|| {
    let mut builder = ammonia::Builder::default();
    // Mail layout lives in inline styles, style elements and old presentational attributes. CSS can not run code, and
    // what it could load from the network is refused by the CSP and by the WebView2 request filter.
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
        // data: is for embedded images only, a data: link could open a document of its own
        .attribute_filter(|element, attribute, value| {
            let is_data = value
                .trim_start()
                .get(..5)
                .is_some_and(|scheme| scheme.eq_ignore_ascii_case("data:"));
            if is_data && !(element == "img" && attribute == "src") {
                None
            } else {
                Some(Cow::Borrowed(value))
            }
        });
    builder
});

/// Removes everything from `html` that is not plain markup: scripts, event handlers, `javascript:` URLs, forms,
/// frames, `meta` and `base`. Returns a body fragment.
pub fn sanitize(html: &str) -> String {
    SANITIZER.clean(html).to_string()
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

/// Points `src="cid:..."` and `background="cid:..."` of sanitized HTML at the images as data: URIs.
/// Only images: anything else stays a `cid:` the preview can not load.
fn embed_images(body: &str, images: &[InlineImage]) -> String {
    // the scheme in any case: ASCII lowercasing keeps every byte where it was
    let lower = body.to_ascii_lowercase();
    let mut out = String::with_capacity(body.len());
    let mut copied = 0;
    let mut search = 0;
    while let Some(found) = lower[search..].find("=\"cid:") {
        let value_start = search + found + 2;
        let Some(length) = body[value_start..].find('"') else {
            break;
        };
        let url = &body[value_start..value_start + length];
        let wanted = content_id(&url[4..].replace("&amp;", "&"));
        let image = images.iter().find(|image| {
            image.mime_type.starts_with("image/") && content_id(image.content_id).eq_ignore_ascii_case(&wanted)
        });
        out.push_str(&body[copied..value_start]);
        match image {
            Some(image) => {
                out.push_str("data:");
                out.push_str(image.mime_type);
                out.push_str(";base64,");
                out.push_str(&STANDARD.encode(image.data));
            }
            None => out.push_str(url),
        }
        copied = value_start + length;
        search = copied;
    }
    out.push_str(&body[copied..]);
    out
}

/// A message for the preview: sanitized, its `cid:` images embedded, in a document with a CSP
pub fn render_message(html: &str, options: &RenderOptions, images: &[InlineImage]) -> String {
    let image_sources = if options.allow_remote_images {
        "data: http: https:"
    } else {
        "data:"
    };
    let body = embed_images(&sanitize(html), images);
    format!(
        "<!doctype html><html><head><meta charset=\"utf-8\">\
         <meta http-equiv=\"Content-Security-Policy\" content=\"default-src 'none'; img-src {image_sources}; style-src 'unsafe-inline'; font-src data:\">\
         <meta name=\"color-scheme\" content=\"light\">\
         <style>html{{background:#fff}}body{{font:10pt Arial,sans-serif;margin:8px}}</style>\
         </head><body>{body}</body></html>"
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
