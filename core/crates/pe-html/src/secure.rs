//! The page of a message with signed or encrypted parts: the app's own labels, and each part a document of its own.
//!
//! The labels say what each part is ("Signed by Alice, key verified"), so nothing a sender writes may reach them.
//! This page holds no markup of the message: each part is a complete document of [`crate::render_view_cards`] in an
//! `iframe` of its own, sandboxed (no scripts, forms or popups; the page around it navigated by a click only). A
//! document can not draw outside its frame or style another document, which CSS rules of ours could only try to
//! prevent. The apps serve
//! the page at an address that ends in `/` and each part at `part-N` beside it ([`part_document`]), out of memory as
//! they serve the page (not `srcdoc`, which WebKit drops while page scripts are off). `allow-same-origin` lets the app
//! (never the message: it runs no script) measure each part's height and size its frame to it ([`MEASURE_SCRIPT`]).
//! A link clicked in a part (the mail's own, or a preview's `inboxclassic:attachment-...`) navigates the top page,
//! never the frame: the part's document has `<base target="_top">` ([`crate::RenderOptions::in_frame`]) and its
//! frame's sandbox `allow-top-navigation-by-user-activation`, so only a click does it (the part runs no script). The
//! apps' handler of the top page's navigation cancels it, as for any message, and opens the link in the browser or
//! the file (the core checks a preview link's token). A navigation of the frame itself would be refused by the page's
//! `frame-src 'self'` before the app is asked, and nothing would open. No navigation loads anything remote.

use crate::editor;

/// The link of a part's label: opens the Details window at that part
pub const PART_LINK: &str = "inboxclassic:part-";

/// Which part's label a link is, if it is one
pub fn part_link(uri: &str) -> Option<usize> {
    uri.strip_prefix(PART_LINK)?.parse().ok()
}

/// The link of Find Key beside the label of a part signed by a key not known here: `inboxclassic:find-key?<handle>`,
/// the handle the signature's fingerprint or key id ([`key_handle`]). The page holds it, never a part.
pub const FIND_KEY_LINK: &str = "inboxclassic:find-key?";

/// A fingerprint or key id as Find Key asks for it: hex only, 16 (a key id), 40 (a v4 fingerprint) or 64 (a v6
/// fingerprint) digits, in upper case; None for anything else. It comes from a link of a document, so nothing else
/// passes.
pub fn key_handle(handle: &str) -> Option<String> {
    let valid = matches!(handle.len(), 16 | 40 | 64) && handle.bytes().all(|b| b.is_ascii_hexdigit());
    valid.then(|| handle.to_ascii_uppercase())
}

/// The handle of a Find Key link ([`FIND_KEY_LINK`]), if it is one
pub fn find_key_link(uri: &str) -> Option<String> {
    key_handle(uri.strip_prefix(FIND_KEY_LINK)?)
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

/// One part: its label in words, its tone, and whether it has a document to show (false: nothing of it can be shown,
/// the label says why); the apps serve its document at `part-N`, N its place among the parts
pub struct SecurePart<'a> {
    pub tone: PartTone,
    pub label: &'a str,
    pub shown: bool,
    /// Find Key beside the label: the handle of the signature's key ([`key_handle`]) and the button's words; None
    /// for no button
    pub find_key: Option<(&'a str, &'a str)>,
}

/// What the address of a part's document ends with, after the page's own address: `part-N`
pub const PART_DOCUMENT: &str = "part-";

/// Which part's document an address (or its path) asks for: its last segment `part-N`
pub fn part_document(address: &str) -> Option<usize> {
    let path = address.split(['?', '#']).next().unwrap_or(address);
    path.rsplit('/').next()?.strip_prefix(PART_DOCUMENT)?.parse().ok()
}

/// The script the app runs in the page (page scripts are off; an app's script still runs) after it loaded, after
/// the pictures of a part loaded and when the window's width changed: each frame as tall as its document.
///
/// The root's own height, not the document's scroll height (never less than the frame's own height), so a frame
/// shrinks too when its part needs less room; the root, not the body, as a child's margin can collapse out of the body.
/// Never under 48 pixels: a part whose content is all out of the flow (fixed, pushed up) still shows what it draws.
pub const MEASURE_SCRIPT: &str = "for(const f of document.querySelectorAll('iframe.pe-d')){const d=f.contentDocument;\
const r=d&&d.documentElement;if(!r)continue;const h=Math.max(48,Math.ceil(r.getBoundingClientRect().height))+'px';\
if(f.style.height!==h)f.style.height=h}";

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
        let label = format!("<a class=\"pe-l\" href=\"{PART_LINK}{index}\">{label}</a>");
        // a handle that is not one is not written: the link would be refused when clicked
        let find = part
            .find_key
            .and_then(|(handle, words)| Some((key_handle(handle)?, editor::text(words))));
        match find {
            Some((handle, words)) => body.push_str(&format!(
                "<section class=\"pe-p pe-{tone}\"><div class=\"pe-r\">{label}\
                 <a class=\"pe-f\" href=\"{FIND_KEY_LINK}{handle}\">{words}</a></div>"
            )),
            None => body.push_str(&format!("<section class=\"pe-p pe-{tone}\">{label}")),
        }
        if part.shown {
            body.push_str(&format!(
                "<iframe class=\"pe-d\" sandbox=\"allow-same-origin allow-top-navigation-by-user-activation\" title=\"{}\" src=\"{PART_DOCUMENT}{index}\"></iframe>",
                attribute(part.label),
            ));
        }
        body.push_str("</section>");
    }
    format!(
        "<!doctype html><html><head><meta charset=\"utf-8\">\
         <meta http-equiv=\"Content-Security-Policy\" content=\"default-src 'none'; frame-src 'self'; \
         img-src {images}; style-src 'unsafe-inline'; font-src 'none'\">\
         <meta name=\"color-scheme\" content=\"light dark\">\
         <style>\
         html{{background:Canvas}}body{{margin:6px 8px;font:10pt Arial,sans-serif}}\
         .pe-p{{border:2px solid var(--c);border-radius:6px;margin:0 0 10px;overflow:hidden}}\
         .pe-l{{display:block;padding:4px 10px;font-weight:bold;font-size:9pt;color:var(--t);background:var(--b);\
         text-decoration:none;border-bottom:1px solid var(--c)}}\
         .pe-l:hover{{text-decoration:underline}}\
         .pe-r{{display:flex;align-items:center;background:var(--b);border-bottom:1px solid var(--c)}}\
         .pe-r .pe-l{{flex:1;border-bottom:0}}\
         .pe-f{{margin:2px 8px;padding:1px 10px;font-size:9pt;color:var(--t);border:1px solid var(--c);\
         border-radius:4px;text-decoration:none;white-space:nowrap}}\
         .pe-f:hover{{background:Canvas}}\
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
         </style></head><body>{body}</body></html>"
    )
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn labels_are_ours_and_parts_are_documents_of_their_own() {
        let page = secure_page(
            &[
                SecurePart {
                    tone: PartTone::Verified,
                    label: "Signed by Alice <a@x.org>",
                    shown: true,
                    find_key: None,
                },
                SecurePart {
                    tone: PartTone::Warning,
                    label: "Not shown",
                    shown: false,
                    find_key: None,
                },
            ],
            false,
        );
        // the label escaped as text, the part a document of its own at its address, nothing of it in the page
        assert!(page.contains("Signed by Alice &lt;a@x.org&gt;"));
        assert!(page.contains("sandbox=\"allow-same-origin allow-top-navigation-by-user-activation\""));
        // never scripts, popups, forms or a navigation of the top page without the user's click
        for flag in ["allow-scripts", "allow-popups", "allow-forms", "allow-top-navigation\""] {
            assert!(!page.contains(flag), "{flag}");
        }
        assert!(page.contains("src=\"part-0\""));
        assert!(page.contains("frame-src 'self';"));
        assert_eq!(page.matches("<iframe").count(), 1);
        assert!(page.contains(&format!("href=\"{PART_LINK}1\"")));
        assert!(page.contains("img-src data:;"));
    }

    #[test]
    fn part_documents() {
        assert_eq!(part_document("inboxclassic://preview/7/part-2"), Some(2));
        assert_eq!(
            part_document("https://preview.inboxclassic.invalid/7/part-0?x"),
            Some(0)
        );
        assert_eq!(part_document("inboxclassic://preview/7/"), None);
        assert_eq!(part_document("part-x"), None);
    }

    #[test]
    fn find_key_beside_the_label_of_an_unknown_key() {
        let handle = "0123456789abcdef0123456789ABCDEF01234567";
        let part = |find_key| SecurePart {
            tone: PartTone::Neutral,
            label: "Signed, but the key is not known",
            shown: true,
            find_key,
        };
        let page = secure_page(&[part(Some((handle, "Find <Key>")))], false);
        assert!(page.contains(&format!(
            "href=\"{FIND_KEY_LINK}{}\">Find &lt;Key&gt;</a>",
            handle.to_uppercase()
        )));
        assert!(page.contains(&format!("href=\"{PART_LINK}0\"")));
        // a handle that is not one gets no button
        for bad in ["\"><script>", "0123456789ABCDEF0", "", "0123456789ABCDEG"] {
            let page = secure_page(&[part(Some((bad, "Find Key")))], false);
            assert!(!page.contains(FIND_KEY_LINK) && !page.contains("<script"), "{bad}");
        }
        assert!(!secure_page(&[part(None)], false).contains(FIND_KEY_LINK));
    }

    #[test]
    fn find_key_links_are_strict() {
        let fingerprint = "0123456789ABCDEF0123456789ABCDEF01234567";
        assert_eq!(
            find_key_link(&format!("{FIND_KEY_LINK}{}", fingerprint.to_lowercase())).as_deref(),
            Some(fingerprint)
        );
        assert_eq!(
            find_key_link("inboxclassic:find-key?0123456789abcdef").as_deref(),
            Some("0123456789ABCDEF")
        );
        assert_eq!(key_handle(&"A".repeat(64)), Some("A".repeat(64)));
        for bad in [
            "inboxclassic:find-key?",
            "inboxclassic:find-key?0123456789ABCDE",
            "inboxclassic:find-key?0123456789ABCDEF0",
            "inboxclassic:find-key?0123456789ABCDEX",
            "inboxclassic:find-key?0123456789ABCDEF/",
            "inboxclassic:find-key?0x23456789ABCDEF",
            "inboxclassic:find-key?0123456789ABCDEF&x=1",
            "inboxclassic:find-key?%30123456789ABCDEF",
            "inboxclassic:find-key? 0123456789ABCDEF",
            "https://example.org/inboxclassic:find-key?0123456789ABCDEF",
            "inboxclassic:part-1",
        ] {
            assert_eq!(find_key_link(bad), None, "{bad}");
        }
    }

    #[test]
    fn part_links() {
        assert_eq!(part_link("inboxclassic:part-3"), Some(3));
        assert_eq!(part_link("inboxclassic:part-x"), None);
        assert_eq!(part_link("https://example.org/part-3"), None);
    }
}
