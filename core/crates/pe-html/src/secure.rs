//! The page of a message with signed or encrypted parts: the app's own labels, and each part a document of its own.
//!
//! The labels say what each part is ("Signed by Alice, key verified"), so nothing a sender writes may reach them.
//! This page holds no markup of the message: each part is a complete document of [`crate::render_view_cards`] in an
//! `iframe` of its own (`srcdoc`), sandboxed (no scripts, forms, popups or navigation of the page around it). A
//! document can not draw outside its frame or style another document, which CSS rules of ours could only try to
//! prevent. `allow-same-origin` lets the app (never the message: it runs no script) measure each part's height and
//! size its frame to it ([`MEASURE_SCRIPT`]).

use crate::editor;

/// The link of a part's label: opens the Details window at that part
pub const PART_LINK: &str = "inboxclassic:part-";

/// Which part's label a link is, if it is one
pub fn part_link(uri: &str) -> Option<usize> {
    uri.strip_prefix(PART_LINK)?.parse().ok()
}

/// How a part's label looks: the colour of its frame
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum PartTone {
    /// Signed by the sender with a key the user verified: green
    Verified,
    /// Signed by the sender, or encrypted: blue
    Good,
    /// Something is not right: amber
    Warning,
    /// Not signed, or not known: grey
    Neutral,
}

impl PartTone {
    fn class(self) -> &'static str {
        match self {
            PartTone::Verified => "v",
            PartTone::Good => "g",
            PartTone::Warning => "w",
            PartTone::Neutral => "n",
        }
    }
}

/// One part: its label in words, its tone, and its document (None: nothing of it can be shown, the label says why)
pub struct SecurePart<'a> {
    pub tone: PartTone,
    pub label: &'a str,
    pub document: Option<&'a str>,
}

/// The script the app runs in the page (page scripts are off; an app's script still runs) after it loaded, after
/// the pictures of a part loaded and when the window's width changed: each frame as tall as its document
pub const MEASURE_SCRIPT: &str = "for(const f of document.querySelectorAll('iframe.pe-d')){const d=f.contentDocument;\
if(d&&d.documentElement){f.style.height=Math.max(d.documentElement.scrollHeight,d.body?d.body.scrollHeight:0)+'px'}}";

/// A text as the value of an attribute
fn attribute(text: &str) -> String {
    let mut out = String::with_capacity(text.len() + text.len() / 8);
    for c in text.chars() {
        match c {
            '&' => out.push_str("&amp;"),
            '"' => out.push_str("&quot;"),
            '<' => out.push_str("&lt;"),
            '>' => out.push_str("&gt;"),
            _ => out.push(c),
        }
    }
    out
}

/// The page of `parts`, in their order. `remote_images`: some part may load pictures from the internet (each part's
/// own policy still decides for it).
pub fn secure_page(parts: &[SecurePart], remote_images: bool) -> String {
    let images = if remote_images { "data: http: https:" } else { "data:" };
    let mut body = String::new();
    for (index, part) in parts.iter().enumerate() {
        let label = editor::text(part.label);
        let tone = part.tone.class();
        body.push_str(&format!(
            "<section class=\"pe-p pe-{tone}\"><a class=\"pe-l\" href=\"{PART_LINK}{index}\">{label}</a>"
        ));
        if let Some(document) = part.document {
            body.push_str(&format!(
                "<iframe class=\"pe-d\" sandbox=\"allow-same-origin\" title=\"{}\" srcdoc=\"{}\"></iframe>",
                attribute(part.label),
                attribute(document)
            ));
        }
        body.push_str("</section>");
    }
    format!(
        "<!doctype html><html><head><meta charset=\"utf-8\">\
         <meta http-equiv=\"Content-Security-Policy\" content=\"default-src 'none'; img-src {images}; \
         style-src 'unsafe-inline'; font-src data:\">\
         <meta name=\"color-scheme\" content=\"light dark\">\
         <style>\
         html{{background:Canvas}}body{{margin:6px 8px;font:10pt Arial,sans-serif}}\
         .pe-p{{border:2px solid var(--c);border-radius:6px;margin:0 0 10px;overflow:hidden}}\
         .pe-l{{display:block;padding:4px 10px;font-weight:bold;font-size:9pt;color:var(--t);background:var(--b);\
         text-decoration:none;border-bottom:1px solid var(--c)}}\
         .pe-l:hover{{text-decoration:underline}}\
         .pe-d{{display:block;width:100%;border:0;height:120px}}\
         .pe-v{{--c:#2e7d32;--b:#e8f5e9;--t:#1b5e20}}\
         .pe-g{{--c:#1f5fae;--b:#e6eefa;--t:#174a87}}\
         .pe-w{{--c:#b26a00;--b:#fff4e0;--t:#7a4800}}\
         .pe-n{{--c:#9e9e9e;--b:#f2f2f2;--t:#444}}\
         @media (prefers-color-scheme:dark){{\
         .pe-v{{--c:#66bb6a;--b:#1b3320;--t:#a5d6a7}}\
         .pe-g{{--c:#7fb0f0;--b:#1f2c40;--t:#bcd6f7}}\
         .pe-w{{--c:#f0b45a;--b:#3a2c14;--t:#f6d29c}}\
         .pe-n{{--c:#777;--b:#2a2a2a;--t:#ccc}}}}\
         @media print{{.pe-d{{height:auto}}}}\
         </style></head><body>{body}</body></html>"
    )
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn labels_are_ours_and_parts_are_documents_of_their_own() {
        let document = "<!doctype html><html><body><p class=\"x\">Hi \"there\" &amp; you</p></body></html>";
        let page = secure_page(
            &[
                SecurePart {
                    tone: PartTone::Verified,
                    label: "Signed by Alice <a@x.org>",
                    document: Some(document),
                },
                SecurePart {
                    tone: PartTone::Warning,
                    label: "Not shown",
                    document: None,
                },
            ],
            false,
        );
        // the label escaped as text, the part only inside its srcdoc attribute, nothing of it as markup of the page
        assert!(page.contains("Signed by Alice &lt;a@x.org&gt;"));
        assert!(page.contains("sandbox=\"allow-same-origin\""));
        assert!(!page.contains("allow-scripts"));
        assert!(!page.contains("<p class=\"x\">"), "a part's markup is never the page's");
        assert!(page.contains("srcdoc=\"&lt;!doctype html&gt;"));
        assert!(page.contains("&quot;there&quot; &amp;amp; you"));
        assert_eq!(page.matches("<iframe").count(), 1);
        assert!(page.contains(&format!("href=\"{PART_LINK}1\"")));
        assert!(page.contains("img-src data:;"));
    }

    #[test]
    fn part_links() {
        assert_eq!(part_link("inboxclassic:part-3"), Some(3));
        assert_eq!(part_link("inboxclassic:part-x"), None);
        assert_eq!(part_link("https://example.org/part-3"), None);
    }
}
