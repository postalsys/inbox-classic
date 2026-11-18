//! The previews of a message's attachments after its text (docs/attachment-preview-plan.md): a picture, or the first
//! pages of a PDF file, as pictures the core drew itself, with the file's name and size under them.
//!
//! The core decides which files have previews and their sizes ([`PreviewSection`]); this writes the markup. Each
//! picture's address is `/pv/<token>-<attachment>-<page>` on the reading pane's own origin, and each file links to
//! `inboxclassic:attachment-<token>-<attachment>`: the token is 128 random bits the core made for this view, so the
//! sender's HTML (which the sanitizer lets keep relative addresses) can not name a preview, and the apps' document
//! servers answer only the addresses of a view the core knows. The width and height of every picture are in the
//! markup, so the space is kept before the bytes come and nothing below moves.
//!
//! The section's rules sit in a cascade layer named by a nonce class, every declaration important, as the cards'
//! do ([`crate::card`]): the message's own style elements can not hide, move or restyle it. Its pictures are never
//! darkened, and a PDF page is drawn on white whatever the look of the document.

use crate::Platform;
use crate::card::{MAX_VALUE, shown};
use crate::editor::nonce;

/// Where the previews' pictures are served, on the origin of the reading pane's document
pub const PREVIEW_PATH: &str = "/pv/";

/// The start of the link of a preview: `inboxclassic:attachment-<token>-<attachment>`, which the apps take (their web
/// views cancel every navigation) and open as a double-click in the strip does
pub const PREVIEW_LINK: &str = "inboxclassic:attachment-";

/// The start of the section's markup, for the tests to find it (a message's style text may hold the same words, so
/// nothing finds or cuts the section by them)
#[cfg(test)]
pub(crate) const SECTION_START: &str = "<section class=\"pe-att-";

/// The origin of the reading pane's documents on this platform: WebView2 answers an https origin of the app's own,
/// WebKit a scheme of the app's ([`crate::DOCUMENT_SCHEME`])
pub fn preview_origin() -> &'static str {
    match Platform::current() {
        Platform::Windows => "https://preview.inboxclassic.invalid",
        Platform::Mac | Platform::Linux => "inboxclassic://preview",
    }
}

/// What a document's CSP allows pictures from for its previews: the preview path of the origin, nothing else of it
pub(crate) fn preview_source() -> String {
    format!("{}{PREVIEW_PATH}", preview_origin())
}

/// A new token of a view's previews: 128 random bits as hex
pub fn preview_token() -> String {
    nonce()
}

/// The previews after a message's text, as the core chose them
#[derive(Debug, Clone, PartialEq, Eq, Default)]
pub struct PreviewSection {
    /// The view's token ([`preview_token`])
    pub token: String,
    /// The files in the order of the strip
    pub files: Vec<PreviewFile>,
    /// Said where the previews are, when PDF files are not shown because one ended the app
    pub notice: Option<String>,
    /// The line after the files when the message has more than are shown ("3 more files are in the list above")
    pub more_files: Option<String>,
}

/// One file's previews
#[derive(Debug, Clone, PartialEq, Eq, Default)]
pub struct PreviewFile {
    /// Its place in the view's list of attachments (the strip's)
    pub attachment: usize,
    /// Its Content-ID: a file the message's HTML shows by `cid:` is shown there and not again here
    pub content_id: Option<String>,
    /// A PDF file's pages: on white, with an edge
    pub paper: bool,
    /// Its pictures: a picture's one, a PDF file's first pages
    pub pages: Vec<PreviewPage>,
    /// Its name, as the strip shows it
    pub name: String,
    /// Under the name: its size, and a PDF file's page count ("3 pages, 84 KB")
    pub details: String,
    /// The link under a PDF file with more pages than are shown ("Open to see all 12 pages")
    pub more: Option<String>,
    /// A file shown as a tile instead of pictures (it can not be drawn, or not yet); its `pages` are empty
    pub tile: Option<PreviewTile>,
}

/// What a tile says of a file it stands for, beside its name and details
#[derive(Debug, Clone, PartialEq, Eq, Default)]
pub struct PreviewTile {
    /// The file's type on its icon ("PDF", "HEIC"), a few letters
    pub label: String,
    /// Why it is a tile, in a few words ("Protected by a password", "Downloading…")
    pub reason: String,
}

/// One picture of a file
#[derive(Debug, Clone, PartialEq, Eq, Default)]
pub struct PreviewPage {
    /// The page (0 for a picture)
    pub page: usize,
    /// Its size shown, in CSS pixels at most (the reading pane narrows it, the height following)
    pub width: u32,
    pub height: u32,
    /// What a screen reader says of it ("Invoice.pdf, page 1 of 3")
    pub alt: String,
}

/// The address of a page's picture
pub fn preview_address(token: &str, attachment: usize, page: usize) -> String {
    format!("{PREVIEW_PATH}{token}-{attachment}-{page}")
}

/// The token, attachment and page of a preview's address as a web view asks for it: the whole URL on the reading
/// pane's origin ([`preview_origin`]), or its path. None for any other address
pub fn parse_preview_address(uri: &str) -> Option<(&str, usize, usize)> {
    let uri = uri.split(['?', '#']).next().unwrap_or(uri);
    let path = match uri.strip_prefix(preview_origin()) {
        Some(path) => path,
        None if uri.starts_with('/') => uri,
        None => return None,
    };
    let mut parts = path.strip_prefix(PREVIEW_PATH)?.split('-');
    let token = parts.next().filter(|token| is_token(token))?;
    let attachment = number(parts.next()?)?;
    let page = number(parts.next()?)?;
    parts.next().is_none().then_some((token, attachment, page))
}

/// The token and attachment of a preview's link ([`PREVIEW_LINK`]), None for any other link
pub fn parse_preview_link(uri: &str) -> Option<(&str, usize)> {
    let uri = uri.trim();
    let uri = uri.strip_suffix('/').unwrap_or(uri);
    let start = uri.get(..PREVIEW_LINK.len())?;
    if !start.eq_ignore_ascii_case(PREVIEW_LINK) {
        return None;
    }
    let (token, attachment) = uri[PREVIEW_LINK.len()..].split_once('-')?;
    is_token(token).then_some(())?;
    Some((token, number(attachment)?))
}

/// The link of a file's previews
fn link(token: &str, attachment: usize) -> String {
    format!("{PREVIEW_LINK}{token}-{attachment}")
}

/// 32 lowercase hex digits, as [`preview_token`] makes them
fn is_token(token: &str) -> bool {
    token.len() == 32 && token.bytes().all(|b| b.is_ascii_digit() || (b'a'..=b'f').contains(&b))
}

/// A number of decimal digits only (no sign, no spaces), not absurdly long
fn number(text: &str) -> Option<usize> {
    (!text.is_empty() && text.len() <= 6 && text.bytes().all(|b| b.is_ascii_digit()))
        .then(|| text.parse().ok())
        .flatten()
}

/// The section's rules, `C` standing for its class. Everything in it is first set back to its initial value, so no
/// rule of the message reaches it, then drawn as ours.
const RULES: &[(&str, &str)] = &[
    ("C", "all:initial"),
    ("C *", "all:unset"),
    ("C::before,C::after,C *::before,C *::after", "content:none;display:none"),
    (
        "C",
        "display:block;clear:both;box-sizing:border-box;margin:20px 0 0;padding:0;max-width:100%;background:#fff;\
         color:#5b5b5b;font:9pt/1.4 system-ui,-apple-system,'Segoe UI',Arial,sans-serif;text-align:left;\
         direction:ltr;overflow-wrap:anywhere",
    ),
    ("C figure", "display:block;margin:0 0 20px;padding:0"),
    ("C a", "display:block;color:inherit;text-decoration:none;cursor:pointer"),
    ("C a:focus-visible", "outline:2px solid #3c7fd1;outline-offset:2px"),
    (
        "C img",
        "display:block;box-sizing:border-box;max-width:100%;height:auto;margin:0 0 8px;border:0;padding:0",
    ),
    (
        "C img.p",
        "background:#fff;border:1px solid #c9c9c9;box-shadow:0 1px 3px rgba(0,0,0,.12)",
    ),
    (
        "C figcaption",
        "display:block;margin:0 0 6px;color:#5b5b5b;font:inherit",
    ),
    ("C .n", "display:inline;color:#1f1f1f;margin:0 8px 0 0;font:inherit"),
    ("C .d", "display:inline;color:#6b6b6b;font:inherit"),
    (
        "C a.m",
        "display:inline-block;margin:0;color:#0b5cad;text-decoration:underline",
    ),
    (
        "C .w",
        "display:block;box-sizing:border-box;margin:0 0 16px;padding:8px 12px;max-width:720px;\
         border:1px solid #f0dfbd;border-left:3px solid #9a5b00;border-radius:4px;background:#fff9ee;color:#1f1f1f;\
         font:inherit",
    ),
    (
        "C a.t",
        "display:flex;align-items:center;box-sizing:border-box;max-width:420px;min-height:66px;padding:10px 12px;\
         border:1px solid #d0d0d0;border-radius:4px;background:#fafafa;color:inherit;text-decoration:none",
    ),
    (
        "C .i",
        "display:flex;align-items:center;justify-content:center;flex:none;box-sizing:border-box;width:36px;\
         height:44px;margin:0 12px 0 0;border:1px solid #9a9a9a;border-radius:2px 9px 2px 2px;background:#fff;\
         color:#444;font:bold 8pt/1 system-ui,-apple-system,'Segoe UI',Arial,sans-serif;overflow:hidden",
    ),
    ("C .x", "display:block;min-width:0;font:inherit"),
    ("C .x>span", "display:block;margin:0"),
    ("C .r", "color:#5b5b5b;margin:2px 0 0"),
    ("C p.o", "display:block;margin:0 0 16px;color:#5b5b5b;font:inherit"),
];

/// The section's colors when the document is dark: its own background and words, the pictures as they are and PDF
/// pages still on white
const DARK_RULES: &[(&str, &str)] = &[
    ("C", "background:#1e1f22;color:#b9b9be"),
    ("C figcaption", "color:#b9b9be"),
    ("C .n", "color:#e3e3e6"),
    ("C .d", "color:#a6a6ab"),
    ("C a.m", "color:#8ab4f8"),
    ("C img.p", "border-color:#45464b;box-shadow:none"),
    (
        "C .w",
        "background:#45371f;border-color:#5a4a2a;border-left-color:#e8b55c;color:#e3e3e6",
    ),
    ("C a.t", "background:#2a2b2f;border-color:#45464b"),
    ("C .i", "background:#3a3b40;border-color:#6b6c72;color:#e3e3e6"),
    ("C .r", "color:#a6a6ab"),
    ("C p.o", "color:#a6a6ab"),
];

fn rules(class: &str, rules: &[(&str, &str)]) -> String {
    let class = format!(".{class}");
    let mut css = String::new();
    for (selectors, declarations) in rules {
        css.push_str(&selectors.replace('C', &class));
        css.push('{');
        for declaration in declarations.split(';') {
            css.push_str(declaration);
            css.push_str("!important;");
        }
        css.push('}');
    }
    css
}

/// What a document shows after the message's text: its markup, the attachments it shows (drawn or as tiles), and
/// whether any of them has pictures (the CSP then lets them load from the preview path)
#[derive(Debug, Default)]
pub(crate) struct Shown {
    pub html: String,
    pub files: Vec<usize>,
    pub pictures: bool,
}

/// The section as markup for the end of the document, `embedded` the Content-IDs (lowercase) the message's HTML
/// showed, `dark` whether the document follows a dark window. Empty when there is nothing to show.
pub(crate) fn section(previews: &PreviewSection, embedded: &dyn Fn(&str) -> bool, dark: bool) -> Shown {
    let files: Vec<&PreviewFile> = previews
        .files
        .iter()
        .filter(|file| !file.pages.is_empty() || file.tile.is_some())
        .filter(|file| {
            !file
                .content_id
                .as_deref()
                .is_some_and(|id| embedded(&crate::content_id(id).to_lowercase()))
        })
        .collect();
    if files.is_empty() && previews.notice.is_none() && previews.more_files.is_none() {
        return Shown::default();
    }
    let class = format!("pe-att-{}", nonce());
    let mut css = format!("<style>@layer {class}{{{}", rules(&class, RULES));
    if dark {
        css.push_str(&format!(
            "@media screen and (prefers-color-scheme:dark){{{}}}",
            rules(&class, DARK_RULES)
        ));
    }
    css.push_str("}</style>");
    // the style element before the section, as everything in the section is drawn by its rules
    let mut out = format!("{css}<section class=\"{class}\">");
    if let Some(notice) = &previews.notice {
        out.push_str(&format!("<p class=\"w\" role=\"note\">{}</p>", shown(notice, 1000)));
    }
    for file in &files {
        out.push_str(&figure(&previews.token, file));
    }
    if let Some(more) = &previews.more_files {
        out.push_str(&format!("<p class=\"o\">{}</p>", shown(more, MAX_VALUE)));
    }
    out.push_str("</section>");
    Shown {
        html: out,
        files: files.iter().map(|file| file.attachment).collect(),
        pictures: files.iter().any(|file| file.tile.is_none()),
    }
}

/// A file's figure: its name and size first (a long PDF file's name is not three pages away), then its pictures in
/// one link (one stop for Tab), and under a PDF file with more pages the link that opens it
fn figure(token: &str, file: &PreviewFile) -> String {
    let href = link(token, file.attachment);
    if let Some(tile) = &file.tile {
        return tile_figure(&href, file, tile);
    }
    let mut out = format!(
        "<figure><figcaption><span class=\"n\">{}</span><span class=\"d\">{}</span></figcaption><a href=\"{href}\">",
        shown(&file.name, MAX_VALUE),
        shown(&file.details, MAX_VALUE)
    );
    for page in &file.pages {
        // the size in an inline important style, which no rule of the message beats; the height follows the width
        out.push_str(&format!(
            "<img{} src=\"{}\" width=\"{w}\" height=\"{h}\" alt=\"{}\" style=\"width:{w}px!important;\
             aspect-ratio:{w}/{h}!important\">",
            if file.paper { " class=\"p\"" } else { "" },
            preview_address(token, file.attachment, page.page),
            attribute(&page.alt),
            w = page.width.max(1),
            h = page.height.max(1),
        ));
    }
    out.push_str("</a>");
    if let Some(more) = &file.more {
        out.push_str(&format!(
            "<a class=\"m\" href=\"{href}\">{}</a>",
            shown(more, MAX_VALUE)
        ));
    }
    out.push_str("</figure>");
    out
}

/// A file shown as a tile: its type on an icon, its name, size and why it is not drawn, all in one link that opens
/// it (one stop for Tab). Its size is the same whatever it says, so a tile that becomes pictures moves only what is
/// below it
fn tile_figure(href: &str, file: &PreviewFile, tile: &PreviewTile) -> String {
    format!(
        "<figure><a class=\"t\" href=\"{href}\"><span class=\"i\" aria-hidden=\"true\">{}</span><span class=\"x\">\
         <span class=\"n\">{}</span><span class=\"d\">{}</span><span class=\"r\">{}</span></span></a></figure>",
        shown(&tile.label, 4),
        shown(&file.name, MAX_VALUE),
        shown(&file.details, MAX_VALUE),
        shown(&tile.reason, MAX_VALUE)
    )
}

/// What the printout shows of a file after the message's text ([`crate::print_document_with`])
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum PrintItem<'a> {
    /// A picture as the core encoded it (`image/png` or `image/jpeg`; anything else is left out), with its name under
    /// it
    Picture {
        name: &'a str,
        mime: &'a str,
        bytes: &'a [u8],
    },
    /// A file that is not printed: a line that names it
    Line(&'a str),
    /// A picture of the message's text as the core encoded it, put where the text shows it (`number`: of its preview
    /// address, [`crate::InlinePicture`]); not in the section after the text
    Inline {
        number: usize,
        mime: &'a str,
        bytes: &'a [u8],
    },
}

/// The rules of a printout's section, `C` its class: its own look whatever the message's styles say
const PRINT_RULES: &[(&str, &str)] = &[
    ("C", "all:initial"),
    ("C *", "all:unset"),
    ("C::before,C::after,C *::before,C *::after", "content:none;display:none"),
    (
        "C",
        "display:block;clear:both;margin:16px 0 0;padding:0;color:#000;background:#fff;font:10pt Arial,sans-serif;\
         text-align:left;direction:ltr;overflow-wrap:anywhere",
    ),
    (
        "C figure",
        "display:block;margin:0 0 12px;break-inside:avoid;page-break-inside:avoid",
    ),
    (
        "C img",
        "display:block;width:auto;height:auto;max-width:100%;max-height:95vh;margin:0 0 4px;border:0;padding:0",
    ),
    ("C figcaption", "display:block;color:#333;font:inherit"),
    ("C p", "display:block;margin:0 0 8px;font:inherit"),
];

/// A printout's pictures and lines as markup, under a class and in a layer the message can not name, as the
/// section's. Each picture is a `data:` address of its bytes: the print windows load nothing but the page. Empty
/// when there is nothing to print
pub(crate) fn print_section(items: &[PrintItem]) -> String {
    use base64::Engine;
    let mut body = String::new();
    for item in items {
        match *item {
            PrintItem::Picture { name, mime, bytes } if matches!(mime, "image/png" | "image/jpeg") => {
                body.push_str(&format!(
                    "<figure><img src=\"data:{mime};base64,{}\" alt=\"{}\"><figcaption>{}</figcaption></figure>",
                    base64::engine::general_purpose::STANDARD.encode(bytes),
                    attribute(name),
                    shown(name, MAX_VALUE)
                ));
            }
            PrintItem::Picture { .. } | PrintItem::Inline { .. } => {}
            PrintItem::Line(line) => body.push_str(&format!("<p>{}</p>", shown(line, 1000))),
        }
    }
    if body.is_empty() {
        return body;
    }
    let class = format!("pe-prt-{}", nonce());
    format!(
        "<style>@layer {class}{{{}}}</style><section class=\"{class}\">{body}</section>",
        rules(&class, PRINT_RULES)
    )
}

/// The script the apps run in the reading pane before they show the same message's document again (Show in
/// Message, the whole message after its text): how far down it is scrolled, a number of CSS pixels
pub const SCROLL_SCRIPT: &str = "Math.round(window.scrollY||0)";

/// The script that scrolls the new document back to `y` ([`SCROLL_SCRIPT`]'s answer), run once it has loaded: its
/// text is where it was, as the previews after it keep their sizes
pub fn scroll_to_script(y: f64) -> String {
    let y = if y.is_finite() { y.clamp(0.0, 1e7).round() } else { 0.0 };
    format!("window.scrollTo(0,{y})")
}

/// A text as the value of an attribute, cut as a card's values are
fn attribute(text: &str) -> String {
    shown(text, MAX_VALUE).replace('"', "&quot;")
}

/// Whether a link clicked in the reading pane is a preview's ([`PREVIEW_LINK`])
pub fn is_preview_link(uri: &str) -> bool {
    parse_preview_link(uri).is_some()
}

#[cfg(test)]
mod tests {
    use super::*;

    const TOKEN: &str = "0123456789abcdef0123456789abcdef";

    #[test]
    fn addresses_carry_the_token_attachment_and_page() {
        let address = preview_address(TOKEN, 2, 4);
        assert_eq!(address, format!("/pv/{TOKEN}-2-4"));
        assert_eq!(parse_preview_address(&address), Some((TOKEN, 2, 4)));
        let full = format!("{}{address}?x#y", preview_origin());
        assert_eq!(parse_preview_address(&full), Some((TOKEN, 2, 4)));
        for wrong in [
            format!("https://example.com/pv/{TOKEN}-2-4"),
            format!("{}/1/pv/{TOKEN}-2-4", preview_origin()),
            format!("/pv/{}-2-4", &TOKEN[1..]),
            format!("/pv/{}-2-4", TOKEN.to_uppercase()),
            format!("/pv/{TOKEN}-2"),
            format!("/pv/{TOKEN}-2-4-1"),
            format!("/pv/{TOKEN}-+2-4"),
            format!("/pv/{TOKEN}--4"),
            "pv-x".to_string(),
        ] {
            assert_eq!(parse_preview_address(&wrong), None, "{wrong}");
        }
    }

    #[test]
    fn links_carry_the_token_and_attachment() {
        assert_eq!(
            parse_preview_link(&format!("inboxclassic:attachment-{TOKEN}-3")),
            Some((TOKEN, 3))
        );
        assert_eq!(
            parse_preview_link(&format!("INBOXCLASSIC:attachment-{TOKEN}-3/")),
            Some((TOKEN, 3))
        );
        assert!(is_preview_link(&format!("inboxclassic:attachment-{TOKEN}-0")));
        for wrong in [
            "inboxclassic:attachment-".to_string(),
            "inboxclassic:attachment-1-2".to_string(),
            format!("inboxclassic:attachment-{TOKEN}"),
            format!("inboxclassic:attachment-{TOKEN}-x"),
            format!("https://x/inboxclassic:attachment-{TOKEN}-1"),
        ] {
            assert_eq!(parse_preview_link(&wrong), None, "{wrong}");
        }
    }

    fn file(attachment: usize, pages: usize, paper: bool) -> PreviewFile {
        PreviewFile {
            attachment,
            content_id: Some(format!("<f{attachment}@x>")),
            paper,
            pages: (0..pages)
                .map(|page| PreviewPage {
                    page,
                    width: 620,
                    height: 877,
                    alt: format!("a\"<{page}>"),
                })
                .collect(),
            name: "<b>Invoice</b>.pdf".into(),
            details: "3 pages, 84 KB".into(),
            more: (pages > 1).then(|| "Open to see all 12 pages".into()),
            tile: None,
        }
    }

    #[test]
    fn a_section_has_a_figure_per_file_with_the_sizes_reserved() {
        let previews = PreviewSection {
            token: TOKEN.into(),
            files: vec![file(0, 1, false), file(2, 3, true), file(3, 0, false)],
            notice: None,
            more_files: None,
        };
        let Shown { html, files: shown, .. } = section(&previews, &|_| false, false);
        // the file without pages is left out
        assert_eq!(shown, [0, 2]);
        assert_eq!(html.matches("<figure>").count(), 2, "{html}");
        assert_eq!(html.matches("<img").count(), 4, "{html}");
        assert!(html.contains(&format!("src=\"/pv/{TOKEN}-2-1\"")), "{html}");
        assert!(html.contains("width=\"620\" height=\"877\""), "{html}");
        assert!(
            html.contains("width:620px!important;aspect-ratio:620/877!important"),
            "{html}"
        );
        assert_eq!(html.matches("class=\"p\"").count(), 3, "{html}");
        assert_eq!(
            html.matches(&format!("href=\"inboxclassic:attachment-{TOKEN}-2\""))
                .count(),
            2,
            "{html}"
        );
        // every value escaped
        assert!(html.contains("&lt;b&gt;Invoice&lt;/b&gt;.pdf"), "{html}");
        assert!(html.contains("alt=\"a&quot;&lt;1&gt;\""), "{html}");
        assert!(html.contains("Open to see all 12 pages"), "{html}");
        // no dark rules for a light document
        assert!(!html.contains("prefers-color-scheme"), "{html}");
    }

    #[test]
    fn every_rule_is_important_and_in_the_layer() {
        let previews = PreviewSection {
            token: TOKEN.into(),
            files: vec![file(0, 1, false)],
            notice: Some("PDF files are off".into()),
            more_files: None,
        };
        let html = section(&previews, &|_| false, true).html;
        let rest = html.split(SECTION_START).nth(1).unwrap();
        let class = format!("pe-att-{}", rest.split('"').next().unwrap());
        assert!(class.starts_with("pe-att-") && class.len() == 7 + 32, "{class}");
        let css = html.split("<style>").nth(1).unwrap().split("</style>").next().unwrap();
        assert!(css.starts_with(&format!("@layer {class}{{")), "{css}");
        assert_eq!(css.matches(';').count(), css.matches("!important;").count(), "{css}");
        assert!(css.contains("prefers-color-scheme:dark"), "{css}");
        // pictures are never darkened, PDF pages stay on white
        assert!(!css.contains("filter:invert"), "{css}");
        assert!(css.contains("img.p{background:#fff!important"), "{css}");
        assert!(
            html.contains("<p class=\"w\" role=\"note\">PDF files are off</p>"),
            "{html}"
        );
        // the style element comes before the section, which its rules draw from nothing
        assert!(html.starts_with("<style>@layer pe-att-"), "{html}");
    }

    #[test]
    fn a_file_the_html_shows_is_not_shown_again() {
        let previews = PreviewSection {
            token: TOKEN.into(),
            files: vec![file(0, 1, false), file(1, 1, false)],
            notice: None,
            more_files: None,
        };
        let Shown { html, files: shown, .. } = section(&previews, &|id| id == "f1@x", false);
        assert_eq!(shown, [0]);
        assert_eq!(html.matches("<figure>").count(), 1);
        // nothing at all: no section
        let Shown { html, files: shown, .. } = section(&previews, &|_| true, false);
        assert!(html.is_empty() && shown.is_empty());
    }

    fn tile(attachment: usize, reason: &str) -> PreviewFile {
        PreviewFile {
            attachment,
            name: "<i>photo</i>.heic".into(),
            details: "2.1 MB".into(),
            tile: Some(PreviewTile {
                label: "HEIC".into(),
                reason: reason.into(),
            }),
            ..Default::default()
        }
    }

    /// A file that is not drawn is a tile: its type, name, size and the reason in words, one link that opens it, no
    /// picture and nothing loaded
    #[test]
    fn a_tile_says_why_and_opens_the_file() {
        let previews = PreviewSection {
            token: TOKEN.into(),
            files: vec![tile(4, "HEIC pictures are not shown yet")],
            notice: None,
            more_files: None,
        };
        let shown = section(&previews, &|_| false, false);
        assert_eq!(shown.files, [4]);
        // no pictures: the CSP needs no preview path
        assert!(!shown.pictures);
        let html = &shown.html;
        assert!(!html.contains("<img") && !html.contains("/pv/"), "{html}");
        assert_eq!(html.matches("<a ").count(), 1, "{html}");
        assert!(
            html.contains(&format!(
                "<a class=\"t\" href=\"inboxclassic:attachment-{TOKEN}-4\"><span class=\"i\" aria-hidden=\"true\">HEIC</span>"
            )),
            "{html}"
        );
        assert!(
            html.contains("<span class=\"n\">&lt;i&gt;photo&lt;/i&gt;.heic</span>"),
            "{html}"
        );
        assert!(html.contains("<span class=\"d\">2.1 MB</span>"), "{html}");
        assert!(
            html.contains("<span class=\"r\">HEIC pictures are not shown yet</span>"),
            "{html}"
        );
        // its own size whatever it says, drawn by the section's important rules
        assert!(html.contains("min-height:66px!important"), "{html}");
        // a tile among pictures: the pictures still load from the preview path
        let mixed = PreviewSection {
            files: vec![file(0, 1, false), tile(1, "Downloading…")],
            ..previews
        };
        let shown = section(&mixed, &|_| false, false);
        assert!(shown.pictures);
        assert_eq!(shown.files, [0, 1]);
    }

    /// Past the message's budget, one line says how many files more are in the list
    #[test]
    fn more_files_are_named_in_one_line() {
        let previews = PreviewSection {
            token: TOKEN.into(),
            files: vec![file(0, 1, false)],
            notice: None,
            more_files: Some("4 more files are in the list above".into()),
        };
        let html = section(&previews, &|_| false, false).html;
        assert!(
            html.contains("<p class=\"o\">4 more files are in the list above</p></section>"),
            "{html}"
        );
        // the line alone still makes a section
        let alone = PreviewSection {
            files: Vec::new(),
            ..previews
        };
        let shown = section(&alone, &|_| false, false);
        assert!(shown.html.contains("4 more files"), "{}", shown.html);
        assert!(shown.files.is_empty() && !shown.pictures);
    }

    #[test]
    fn the_print_section_has_the_pictures_as_data_and_a_line_for_the_rest() {
        let items = [
            PrintItem::Picture {
                name: "a\"<b>.jpg",
                mime: "image/jpeg",
                bytes: b"\xff\xd8\xff",
            },
            // never another type, whatever the caller says
            PrintItem::Picture {
                name: "x.svg",
                mime: "image/svg+xml",
                bytes: b"<svg onload=alert(1)>",
            },
            PrintItem::Line("invoice.pdf (3 pages, 84 KB) is not printed. Open it to print it."),
        ];
        let html = print_section(&items);
        assert!(html.starts_with("<style>@layer pe-prt-"), "{html}");
        assert!(
            html.contains("<img src=\"data:image/jpeg;base64,/9j/\" alt=\"a&quot;&lt;b&gt;.jpg\">"),
            "{html}"
        );
        assert!(!html.contains("svg"), "{html}");
        assert!(
            html.contains("<p>invoice.pdf (3 pages, 84 KB) is not printed."),
            "{html}"
        );
        let css = html.split("<style>").nth(1).unwrap().split("</style>").next().unwrap();
        assert_eq!(css.matches(';').count(), css.matches("!important;").count(), "{css}");
        assert!(print_section(&[]).is_empty());
    }

    #[test]
    fn the_scroll_scripts() {
        assert_eq!(SCROLL_SCRIPT, "Math.round(window.scrollY||0)");
        assert_eq!(scroll_to_script(120.4), "window.scrollTo(0,120)");
        assert_eq!(scroll_to_script(-5.0), "window.scrollTo(0,0)");
        assert_eq!(scroll_to_script(f64::NAN), "window.scrollTo(0,0)");
        assert_eq!(scroll_to_script(f64::INFINITY), "window.scrollTo(0,0)");
    }
}
