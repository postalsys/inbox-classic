//! HTML of messages made safe to show. Message bodies are written by whoever sent the mail, so they are sanitized here
//! before the C++ app hands them to WebView2, which then shows them with scripts off and network requests refused.
//! The CSP of the document is one more layer on top of both.
#![forbid(unsafe_code)]

use std::borrow::Cow;
use std::collections::hash_map::Entry;
use std::collections::{HashMap, HashSet};
use std::sync::atomic::{AtomicBool, AtomicUsize, Ordering};
use std::sync::{Arc, OnceLock};

use base64::Engine;
use base64::engine::general_purpose::STANDARD;

mod bounce;
mod card;
mod css;
mod dark;
mod editor;
mod event;
mod help;
mod inline;
mod markdown;
mod otp;
mod platform;
mod previews;
mod secure;
mod visible;
pub use bounce::{
    BOUNCED_MESSAGE_LINK, BounceCard, CardDetail, CardPicture, CardReason, bounce_card, is_bounced_message_link,
};
pub use dark::{dark, set_dark};
pub use editor::{
    PICTURE_FILE_LIMIT, PICTURE_HEAD, Picture, draft_body, editor_document, is_plain, outgoing_html, picture_type,
    picture_uri, quote_html, quote_parts, signature_block, signature_html, written_part,
};
pub use event::{EventCard, OPEN_CALENDAR_LINK, event_card, is_open_calendar_link};
pub use help::{
    HELP_TOPIC_SCHEME, HelpSection, HelpTarget, HelpTopic, help_contents, help_context, help_export, help_link_topic,
    help_search, help_topic, settings_words,
};
pub use inline::{INLINE_BASE, InlineOptions, InlinePicture, MAX_INLINE, MAX_INLINE_BYTES};
pub use markdown::markdown_html;
pub use otp::{COPY_CODE_LINK, OtpCard, is_copy_code_link, otp_card};
pub use platform::{DOCUMENT_SCHEME, Platform, status_page, webkit_content_rules};
pub use previews::{
    PREVIEW_LINK, PREVIEW_PATH, PreviewFile, PreviewPage, PreviewSection, PreviewTile, PrintItem, is_preview_link,
    parse_preview_address, parse_preview_link, preview_address, preview_origin, preview_token,
};
pub use secure::{
    FIND_KEY_LINK, HEIGHT_SCRIPT, MEASURE_SCRIPT, PART_DOCUMENT, PART_LINK, PartTone, SecurePart, find_key_link,
    key_handle, part_document, part_link, secure_page,
};
pub use visible::visible_html;

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
    /// The document is a part of a signed or encrypted message, shown in a frame of [`secure_page`]: its links open
    /// in the top page (`<base target="_top">`), whose navigation the apps cancel and open in the browser. A link
    /// that navigated the frame would be refused by the page's `frame-src` before the app is asked, and never open
    pub in_frame: bool,
    /// The language of the message's text for the document (`<html lang>`): Japanese and Chinese share characters
    /// that each draws otherwise. A constant of the core's (the charset's language or the app's), never the
    /// message's own words; None for none.
    pub lang: Option<&'static str>,
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
        // elements whose text a browser never shows: removed with it, or a title would read as the body's first line
        .add_clean_content_tags(["title", "template", "noembed", "noframes", "iframe"])
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
        .add_allowed_classes("details", ["pe-fold"])
        // the signature in a message being written, which the editor swaps for another account's
        .add_allowed_classes("div", ["pe-signature"])
        // a plain text message (pe-core fold.rs), its lines kept to a length that reads well in a wide reading pane
        .add_allowed_classes("div", ["pe-plain"]);
    builder
}

/// The sanitizer of what the editor shows (a quote, a draft, a signature) with `images`, its `cid:` pictures as
/// `data:` URIs: the editor's page, and the message sent from it, carry them as they are. Mail layout lives in inline
/// styles, style elements and old presentational attributes. CSS can not run code, and what it could load from the
/// network is refused by the CSP and by the WebView2 request filter.
pub(crate) fn builder(images: &[InlineImage]) -> ammonia::Builder<'static> {
    let embedder = Embedder::new(images);
    let mut builder = mail_builder();
    builder.attribute_filter(move |element, attribute, value| {
        let img_src = element == "img" && attribute == "src";
        let address = url_text(value);
        match scheme_of(&address).as_str() {
            // data: is for images only, a data: link could open a document of its own
            "data:" if !img_src => None,
            scheme if scheme.starts_with("cid:") && (img_src || attribute == "background") => {
                Some(embedder.embed(&address).map_or(Cow::Borrowed(value), Cow::Owned))
            }
            _ => Some(Cow::Borrowed(value)),
        }
    });
    builder
}

/// An attribute's address as a URL parser reads it: without the controls and spaces around it, and without tabs and
/// newlines anywhere (`da&#9;ta:` is `data:`)
fn url_text(value: &str) -> Cow<'_, str> {
    let value = value.trim_matches(|c: char| c <= ' ');
    if value.contains(['\t', '\n', '\r']) {
        Cow::Owned(value.chars().filter(|c| !matches!(c, '\t' | '\n' | '\r')).collect())
    } else {
        Cow::Borrowed(value)
    }
}

/// The first five characters of an address ([`url_text`]), lowercased: its scheme when it is `data:` or `cid:`
fn scheme_of(address: &str) -> String {
    address.get(..5).map(str::to_ascii_lowercase).unwrap_or_default()
}

/// The sanitizer of a message shown in the reading pane: as [`builder`], but no picture of the message's text reaches
/// the web view as the sender wrote it. A `cid:` picture (of an `img` or a `background`) and a `data:` picture of an
/// `img` become preview addresses of the document, routed by `router` ([`inline`]), which the core answers with its
/// own encode; past the limits, or in a document without preview addresses, they show nothing. Sets `remote` when an
/// attribute loads a picture from the network: an `img` src, a `background`, or a CSS `url()` / `image-set()` in a
/// style attribute (decoded, as the sanitizer hands it over)
fn reading_builder(router: Arc<inline::Router>, remote: Arc<AtomicBool>) -> ammonia::Builder<'static> {
    let mut builder = mail_builder();
    builder.attribute_filter(move |element, attribute, value| {
        let img_src = element == "img" && attribute == "src";
        let address = url_text(value);
        let loads = match attribute {
            "style" => css_loads_remote(value),
            "background" => is_remote(&address),
            _ => img_src && is_remote(&address),
        };
        if loads {
            remote.store(true, Ordering::Relaxed);
        }
        // the message's own CSS: no picture of its own (only those on the internet, which the CSP and the apps
        // block until allowed), no font
        if attribute == "style" {
            return Some(css::clean(value));
        }
        let route = match scheme_of(&address).as_str() {
            "data:" if img_src => router.data(&address),
            "data:" => inline::Route::Drop,
            scheme if scheme.starts_with("cid:") && (img_src || attribute == "background") => router.part(&address),
            _ => inline::Route::Keep,
        };
        match route {
            inline::Route::To(address) => Some(Cow::Owned(address)),
            inline::Route::Keep => Some(Cow::Borrowed(value)),
            inline::Route::Drop => None,
        }
    });
    builder
}

/// Turns `cid:` URLs into `data:` URIs of the images they name, for the editor ([`builder`]). Only images: anything
/// else stays a `cid:` the editor can not load. The sanitizer wants a callback that owns its data, so the images are
/// copied in.
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
        let id = content_id(&url.trim_start()[4..]).to_lowercase();
        let index = *self.by_id.get(&id)?;
        let uri = self.uris[index].get_or_init(|| {
            let (mime_type, data) = &self.images[index];
            format!("data:{mime_type};base64,{}", STANDARD.encode(data))
        });
        let total = self.embedded.fetch_add(uri.len(), Ordering::Relaxed) + uri.len();
        (total <= MAX_EMBEDDED_BYTES).then(|| uri.clone())
    }
}

/// Removes everything from `html` that is not plain markup: scripts, event handlers, `javascript:` URLs, forms,
/// frames, `meta` and `base`. Returns a body fragment, whose pictures of its own (`cid:`, `data:`) show nothing.
pub fn sanitize(html: &str) -> String {
    let router = Arc::new(inline::Router::new(&[], None));
    css::clean_style_elements(&reading_builder(router, Arc::default()).clean(html).to_string())
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
    // brackets written as escapes (`cid:%3Cid%3E`)
    let id = String::from_utf8_lossy(&out);
    id.trim().trim_start_matches('<').trim_end_matches('>').to_string()
}

/// A message for the preview: sanitized, in a document with a CSP; its pictures of its own (`cid:`, `data:`) show
/// nothing without preview addresses ([`render_view_cards`] with [`Cards::inline`])
pub fn render_message(html: &str, options: &RenderOptions, images: &[InlineImage]) -> String {
    render_view(html, options, images, &[]).document
}

/// A message rendered for the preview
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct Rendered {
    pub document: String,
    /// The message has pictures on the internet, which the preview shows only after Download pictures
    pub remote_images: bool,
    /// The attachments whose previews the document shows after the text ([`Cards::previews`]), in order
    pub previewed: Vec<usize>,
    /// The document to print when this one shows previews: the same message wrapped again with none (the print
    /// windows serve none of their pictures; PDF pages are printed from their own program). None when it shows none
    pub print_document: Option<String>,
    /// What the printout of a document with previews or pictures in its text is made of again once their pictures
    /// are drawn ([`print_document_with`]); None when it shows none
    pub print: Option<PrintParts>,
    /// The pictures of its text ([`Cards::inline`]), each under the number of its preview address: the core answers
    /// them with its own encodes
    pub inline: Vec<InlinePicture>,
}

/// A sanitized message as [`render_view_cards`] wrapped it, kept to wrap it again for a printout with the pictures
/// of its previews ([`print_document_with`]): never cut out of a finished document
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct PrintParts {
    body: String,
    allow_remote_images: bool,
    lang: Option<&'static str>,
    header: Vec<(String, String)>,
    card: String,
    /// The parts of a message with signed or encrypted parts ([`print_parts`]), each sanitized on its own with its
    /// place among them: each part's pictures are printed after its own text. Empty for any other message (`body`)
    parts: Vec<(usize, String)>,
    /// The start of the preview addresses of the pictures of `body`'s text (`/pv/<token>-`) and their numbers: the
    /// printout puts the core's encodes in their place ([`PrintItem::Inline`])
    inline: Option<(String, Vec<usize>)>,
}

/// A printout of a message with previews of its attachments, its pictures put after its text as `data:` addresses
/// of the core's own encodes (the print windows serve nothing but the page), and a line for each file that is not
/// printed (a PDF file, printed from its own program). Each item names the part of a message with signed or encrypted
/// parts it belongs to: it is printed right after that part's text; one of no part ([`None`], any other message) after
/// all of it. The CSP lets pictures come from `data:` only, as any document of [`render_view`]
pub fn print_document_with(parts: &PrintParts, items: &[(Option<usize>, PrintItem)]) -> String {
    let header: Vec<(&str, &str)> = parts
        .header
        .iter()
        .map(|(name, value)| (name.as_str(), value.as_str()))
        .collect();
    let options = RenderOptions {
        allow_remote_images: parts.allow_remote_images,
        lang: parts.lang,
        ..Default::default()
    };
    // the section of the items whose part `pick` takes
    let section_of = |pick: &dyn Fn(Option<usize>) -> bool| {
        let picked: Vec<PrintItem> = items
            .iter()
            .filter(|(part, _)| pick(*part))
            .map(|(_, item)| *item)
            .collect();
        previews::print_section(&picked)
    };
    // the card is ours, the message's words in it escaped; made printable all the same
    let card = inline::printable(&parts.card);
    if parts.parts.is_empty() {
        let section = section_of(&|_| true);
        let body = printed_inline(parts, items);
        return wrap(&body, &options, &header, &card, After::Printed(&section), false).0;
    }
    // the look of the text alone, as without pictures: the sections' own rules are not the message's
    let text: Vec<&str> = parts.parts.iter().map(|(_, html)| html.as_str()).collect();
    let look = dark::look(&text.join(PART_RULE));
    let body: Vec<String> = parts
        .parts
        .iter()
        .map(|(part, html)| format!("{}{}", inline::printable(html), section_of(&|of| of == Some(*part))))
        .collect();
    // the items of no part printed come after all of it
    let known = |part: Option<usize>| part.is_some_and(|part| parts.parts.iter().any(|(at, _)| *at == part));
    let section = section_of(&|part| !known(part));
    let after = After::Printed(&section);
    wrap_as(&body.join(PART_RULE), look, &options, &header, &card, after, false).0
}

/// The text of a printout with each picture of it as a `data:` address of the core's encode ([`PrintItem::Inline`]),
/// or of an empty picture for one not drawn: the print windows load nothing but the page. The addresses replaced are
/// the router's, whose token the sender does not know
fn printed_inline(parts: &PrintParts, items: &[(Option<usize>, PrintItem)]) -> String {
    // no data: address of the sender's: the only ones are those put in here
    let body = inline::printable(&parts.body);
    let Some((prefix, numbers)) = &parts.inline else {
        return body;
    };
    // each picture's address by its number as the router wrote it: the first drawing of it, or the empty picture
    let mut addresses: HashMap<String, String> = HashMap::new();
    for (_, item) in items {
        if let PrintItem::Inline { number, mime, bytes } = *item
            && matches!(mime, "image/png" | "image/jpeg")
            && numbers.contains(&number)
        {
            let address = || format!("data:{mime};base64,{}", STANDARD.encode(bytes));
            addresses.entry(number.to_string()).or_insert_with(address);
        }
    }
    for number in numbers {
        let empty = || NOT_PRINTED_PICTURE.to_string();
        addresses.entry(number.to_string()).or_insert_with(empty);
    }
    // one pass over the text: `"<prefix><number>-0"` each
    let start = format!("\"{prefix}");
    let mut out = String::with_capacity(body.len());
    let mut rest = body.as_str();
    while let Some(at) = rest.find(&start) {
        out.push_str(&rest[..at]);
        let after = &rest[at + start.len()..];
        let digits = after.bytes().take_while(u8::is_ascii_digit).count();
        match addresses.get(&after[..digits]) {
            Some(address) if after[digits..].starts_with("-0\"") => {
                out.push_str(&format!("\"{address}\""));
                rest = &after[digits + 3..];
            }
            _ => {
                out.push_str(&start);
                rest = after;
            }
        }
    }
    out.push_str(rest);
    out
}

/// An empty picture (a transparent GIF of one pixel) where a picture of the text was not drawn
const NOT_PRINTED_PICTURE: &str = "data:image/gif;base64,R0lGODlhAQABAIAAAAAAAP///yH5BAEAAAAALAAAAAABAAEAAAIBRAA7";

/// What is printed between two parts of a message with signed or encrypted parts
const PART_RULE: &str = "<hr>";

/// What a printout of a message with signed or encrypted parts is wrapped from: each part's html (the core's own
/// markup: its words under its label), with its place among the parts, sanitized as any message, with no pictures
/// from the internet; with [`print_document_with`] it prints with each part's pictures after that part's text, or
/// with none
pub fn print_parts(parts: &[(usize, String)], header: &[(&str, &str)]) -> PrintParts {
    PrintParts {
        body: String::new(),
        allow_remote_images: false,
        lang: None,
        header: header
            .iter()
            .map(|(name, value)| (name.to_string(), value.to_string()))
            .collect(),
        card: String::new(),
        parts: parts
            .iter()
            .map(|(part, html)| (*part, builder(&[]).clean(html).to_string()))
            .collect(),
        inline: None,
    }
}

/// [`render_message`] with the header fields of the message (`From`, `Subject`, ...), which only a printout shows (on
/// screen the window shows them above the message), and whether the message has pictures on the internet
pub fn render_view(html: &str, options: &RenderOptions, images: &[InlineImage], header: &[(&str, &str)]) -> Rendered {
    render_view_with(html, options, images, header, None)
}

/// [`render_view`] with the card of a bounce above the message
pub fn render_view_with(
    html: &str,
    options: &RenderOptions,
    images: &[InlineImage],
    header: &[(&str, &str)],
    card: Option<&BounceCard>,
) -> Rendered {
    render_view_cards(
        html,
        options,
        images,
        header,
        &Cards {
            bounce: card,
            ..Default::default()
        },
    )
}

/// The cards of the app above a message: a one-time code's first, then an event's, then a bounce's; and the previews
/// of its attachments after it
#[derive(Default)]
pub struct Cards<'a> {
    pub otp: Option<&'a OtpCard>,
    pub event: Option<&'a EventCard>,
    pub bounce: Option<&'a BounceCard>,
    pub previews: Option<&'a PreviewSection>,
    /// The preview addresses of the pictures of its text; None: they show nothing
    pub inline: Option<&'a InlineOptions<'a>>,
}

/// [`render_view`] with the cards of the app above the message
pub fn render_view_cards(
    html: &str,
    options: &RenderOptions,
    images: &[InlineImage],
    header: &[(&str, &str)],
    cards: &Cards,
) -> Rendered {
    let remote = Arc::new(AtomicBool::new(false));
    let router = Arc::new(inline::Router::new(images, cards.inline));
    let body = reading_builder(router.clone(), remote.clone()).clean(html).to_string();
    // the style elements' text, which is no attribute: as the style attributes, without pictures or fonts of its own
    let body = css::clean_style_elements(&body);
    let (pictures, embedded) = router.finish(images);
    // the options and the start of the preview addresses of the pictures of the text, when it has any
    let routed = cards
        .inline
        .filter(|_| !pictures.is_empty())
        .map(|options| (options, format!("{PREVIEW_PATH}{}-", options.token)));
    // the size of each picture of the text where its img says none, so the text does not move when it comes
    let body = match &routed {
        Some((options, prefix)) => {
            let size = |number: usize| {
                let picture = pictures.iter().find(|picture| picture.number == number)?;
                (options.size)(picture)
            };
            inline::sized(&body, prefix, &size)
        }
        None => body,
    };
    let card = [
        cards.otp.map(otp_card),
        cards.event.map(event_card),
        cards.bounce.map(bounce_card),
    ]
    .into_iter()
    .flatten()
    .collect::<String>();
    let previews = cards.previews.map(|previews| Previews {
        section: previews,
        embedded: &embedded,
    });
    let after = previews.map_or(After::Nothing, After::Previews);
    let (document, previewed) = wrap(&body, options, header, &card, after, routed.is_some());
    // built from the same parts, never cut out of the document: the message's own style text may forge any marker
    let print_document =
        (!previewed.is_empty()).then(|| wrap(&body, options, header, &card, After::Nothing, routed.is_some()).0);
    let inline = routed.map(|(_, prefix)| (prefix, pictures.iter().map(|picture| picture.number).collect()));
    let print = (!previewed.is_empty() || inline.is_some()).then(|| PrintParts {
        allow_remote_images: options.allow_remote_images,
        lang: options.lang,
        header: header
            .iter()
            .map(|(name, value)| (name.to_string(), value.to_string()))
            .collect(),
        card: card.clone(),
        body: body.clone(),
        parts: Vec::new(),
        inline,
    });
    Rendered {
        // the attributes were seen while sanitizing; style elements are left, as their text is not an attribute
        remote_images: remote.load(Ordering::Relaxed) || style_elements_load_remote(&body),
        document,
        previewed,
        print_document,
        print,
        inline: pictures,
    }
}

/// What a document has after the message's text
enum After<'a> {
    Nothing,
    /// The previews of its attachments
    Previews(Previews<'a>),
    /// A printout's pictures and lines ([`print_document_with`])
    Printed(&'a str),
}

/// The previews to put after a message's text, and the pictures its HTML showed already
struct Previews<'a> {
    section: &'a PreviewSection,
    embedded: &'a HashSet<String>,
}

/// An address on the network: http(s) or protocol-relative (which the https preview page would load over https).
/// Only for offering Download pictures: what this misses (CSS escapes) stays blocked all the same.
fn is_remote(value: &str) -> bool {
    let value = value.trim_start().trim_start_matches(['"', '\'']).trim_start();
    let starts = |prefix: &str| {
        value
            .get(..prefix.len())
            .is_some_and(|start| start.eq_ignore_ascii_case(prefix))
    };
    starts("http:") || starts("https:") || value.starts_with("//")
}

/// Whether CSS text has a `url()` or `image-set()` with an address on the network
fn css_loads_remote(css: &str) -> bool {
    let bytes = css.as_bytes();
    ["url(", "image-set("].iter().any(|function| {
        bytes.windows(function.len()).enumerate().any(|(at, window)| {
            window.eq_ignore_ascii_case(function.as_bytes()) && is_remote(&css[at + function.len()..])
        })
    })
}

/// Whether the style elements of sanitized `body` load a picture from the network; the sanitizer writes them in
/// lowercase and leaves their text as it is
fn style_elements_load_remote(body: &str) -> bool {
    body.split("<style")
        .skip(1)
        .any(|element| css_loads_remote(&element[..element.find("</style>").unwrap_or(element.len())]))
}

/// Where the CSP of a document of [`wrap`] starts, the first thing in it and before anything of the message, and how
/// it ends: what [`print_page`] adds its script between
const CSP_START: &str = "content=\"default-src 'none'; ";
const DOCUMENT_END: &str = "</body></html>";

/// The script of a print page: word to the window once the print preview (opened by the window, WebView2's own
/// preview, as the page's print() would open the system dialog without one) is closed, printed or cancelled, so the
/// window goes too
const PRINT_SCRIPT: &str = "addEventListener('afterprint',()=>chrome.webview.postMessage('done'));";

/// A document of [`render_view`] made into the page of the Print window: the same sanitized message, plus one script
/// of ours, allowed by a nonce in the CSP (nothing else can run, the message has no scripts of its own), that says
/// when the print preview is closed. None for a document that is not one of ours. A document with previews is
/// printed from its [`Rendered::print_document`].
pub fn print_page(document: &str) -> Option<String> {
    let at = document.find(CSP_START)? + CSP_START.len();
    let end = document.rfind(DOCUMENT_END)?;
    let nonce = editor::nonce();
    Some(format!(
        "{}script-src 'nonce-{nonce}'; {}<script nonce=\"{nonce}\">{PRINT_SCRIPT}</script>{}",
        &document[..at],
        &document[at..end],
        &document[end..]
    ))
}

/// The preview document around a sanitized body, with `card` (markup of ours, [`bounce_card`]) above it and the
/// previews of its attachments after it; with the attachments it shows previews of. `routed`: the body's pictures
/// load from the document's preview addresses ([`inline`])
fn wrap(
    body: &str,
    options: &RenderOptions,
    header: &[(&str, &str)],
    card: &str,
    after: After,
    routed: bool,
) -> (String, Vec<usize>) {
    wrap_as(body, dark::look(body), options, header, card, after, routed)
}

/// [`wrap`] with the look decided already (a printout's, from its text without the pictures between its parts)
fn wrap_as(
    body: &str,
    look: dark::Look,
    options: &RenderOptions,
    header: &[(&str, &str)],
    card: &str,
    after: After,
    routed: bool,
) -> (String, Vec<usize>) {
    // pictures from `data:` only in a printout, whose pictures are the core's encodes put in by the core; a document
    // on screen gets the message's own pictures from its preview addresses, never from `data:`, which would hand the
    // sender's bytes (a `data:` address in its CSS) to the web view's decoders
    let printed = matches!(after, After::Printed(_));
    let mut image_sources: Vec<String> = Vec::new();
    if printed {
        image_sources.push("data:".into());
    }
    if options.allow_remote_images {
        image_sources.push("http: https:".into());
    }
    // the header of a printout, under a class and in a cascade layer the message can not guess: an important rule
    // of the first layer beats any important rule of the message's own style elements, whatever their selector, and
    // a message can not add rules to a layer it can not name. Its lines have inline important styles, which beat
    // the message's too. (The header the window shows is outside the message and can not be touched.)
    let class = format!("pe-print-{}", editor::nonce());
    // in a dark window: written mail dark (its own too dark colors lightened), designed mail light as it was made
    let marked;
    let body = match look {
        dark::Look::Dark { adapt: true } => {
            marked = dark::mark_dark_text(body);
            marked.as_str()
        }
        _ => body,
    };
    let (scheme, dark_style) = match look {
        dark::Look::Light => ("light", ""),
        dark::Look::Dark { .. } => ("light dark", dark::DOCUMENT_DARK),
    };
    // the previews after the text, their pictures from the preview path of the page's own origin and nowhere else
    let ours = match after {
        After::Nothing => previews::Shown::default(),
        After::Previews(previews) => {
            let embedded = |id: &str| previews.embedded.contains(id);
            previews::section(previews.section, &embedded, matches!(look, dark::Look::Dark { .. }))
        }
        After::Printed(section) => previews::Shown {
            html: section.to_string(),
            ..Default::default()
        },
    };
    let (section, previewed) = (ours.html, ours.files);
    if (ours.pictures || routed) && !printed {
        image_sources.push(previews::preview_source());
    }
    let image_sources = if image_sources.is_empty() {
        "'none'".to_string()
    } else {
        image_sources.join(" ")
    };
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
    // a part's frame: its links navigate the top page (the frame's sandbox lets a click do that, nothing else)
    let base = if options.in_frame { "<base target=\"_top\">" } else { "" };
    // a constant of the core's, never the message's own words
    let lang = options.lang.map(|lang| format!(" lang=\"{lang}\"")).unwrap_or_default();
    let printed = if printed.is_empty() {
        String::new()
    } else {
        format!("<div class=\"{class}\">{printed}</div>")
    };
    let document = format!(
        "<!doctype html><html{lang}><head><meta charset=\"utf-8\">\
         <meta http-equiv=\"Content-Security-Policy\" {CSP_START}img-src {image_sources}; style-src 'unsafe-inline'; font-src 'none'\">\
         <meta name=\"color-scheme\" content=\"{scheme}\">{base}\
         <style>html{{background:#fff}}body{{font:10pt Arial,sans-serif;margin:8px}}\
         div.pe-plain{{max-width:46em}}\
         details.pe-fold{{margin:6px 0}}\
         details.pe-fold>summary{{display:inline-flex;align-items:center;justify-content:center;box-sizing:border-box;\
         list-style:none;font:bold 9pt Arial,sans-serif;letter-spacing:1px;\
         color:#555;background:#eee;border:1px solid #ccc;border-radius:9px;padding:0 9px;height:17px;\
         cursor:pointer;margin-bottom:4px}}\
         details.pe-fold>summary::-webkit-details-marker{{display:none}}\
         details.pe-fold>summary::marker{{content:\"\"}}\
         details.pe-fold>summary:hover{{background:#e2e2e2;color:#000}}\
         {dark_style}\
         @page{{margin:0}}\
         @media print{{body{{margin:15mm}}}}\
         @layer {class}{{.{class}{{display:none}}\
         @media print{{.{class}{{{shown};border-bottom:1px solid #999!important;padding-bottom:6px!important;margin-bottom:10px!important}}}}}}\
         </style>\
         </head><body>{printed}{card}{body}{section}{DOCUMENT_END}"
    );
    (document, previewed)
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn the_document_has_the_language_it_is_given() {
        let options = |lang| RenderOptions {
            lang,
            ..Default::default()
        };
        let document = render_document("<p>会議</p>", &options(Some("ja")));
        assert!(
            document.starts_with("<!doctype html><html lang=\"ja\"><head>"),
            "{document}"
        );
        let document = render_document("<p>x</p>", &options(None));
        assert!(document.starts_with("<!doctype html><html><head>"), "{document}");
    }

    /// A whole document's title (a Stripe payout notice's "Your €1,910.91 payout ... is on the way") is not the
    /// body's first line: the text of an element a browser never shows goes with it, the body and its styles stay
    /// In a dark window, written mail goes dark with its too dark colors marked, designed mail stays light, and the
    /// CSP is the same either way
    #[test]
    fn written_mail_goes_dark_and_designed_mail_stays_light() {
        set_dark(true);
        let written = render_view(
            "<div style=\"color:#222\">Hi Ann</div>",
            &RenderOptions::default(),
            &[],
            &[],
        )
        .document;
        let designed = render_view(
            "<table bgcolor=\"#eee\"><tr><td>Sale</td></tr></table>",
            &RenderOptions::default(),
            &[],
            &[],
        )
        .document;
        set_dark(false);
        assert!(
            written.contains("content=\"light dark\"") && written.contains("data-pe-dark"),
            "{written}"
        );
        assert!(written.contains("prefers-color-scheme:dark"), "{written}");
        assert!(
            designed.contains("content=\"light\"") && !designed.contains("prefers-color-scheme"),
            "{designed}"
        );
        let csp = |d: &str| d[d.find(CSP_START).unwrap()..].split('>').next().unwrap().to_string();
        assert_eq!(csp(&written), csp(&designed));
    }

    #[test]
    fn a_title_is_not_shown_as_the_first_line() {
        let html = "<html><head><title>TITLE TEXT</title><style>p{color:red}</style></head>\
                    <body><p>body</p><template>TEMPLATE</template><noembed>NOEMBED</noembed>\
                    <noframes>NOFRAMES</noframes><iframe>IFRAME</iframe></body></html>";
        let clean = sanitize(html);
        for hidden in ["TITLE TEXT", "TEMPLATE", "NOEMBED", "NOFRAMES", "IFRAME"] {
            assert!(!clean.contains(hidden), "{clean}");
        }
        assert!(clean.contains("<style>p{color:red}</style>"), "{clean}");
        assert!(clean.contains("<p>body</p>"), "{clean}");
    }

    /// A part's document (in a frame of the page of a signed or encrypted message) sends its links to the top page,
    /// whose navigation the apps cancel and open in the browser; any other document has no base, and a message's own
    /// base or target is never kept
    #[test]
    fn a_part_in_a_frame_opens_its_links_from_the_top_page() {
        let html =
            "<base href=\"https://evil.example/\" target=\"x\"><a href=\"https://example.org/\" target=\"_self\">x</a>";
        let framed = render_view(
            html,
            &RenderOptions {
                in_frame: true,
                ..Default::default()
            },
            &[],
            &[],
        )
        .document;
        assert_eq!(framed.matches("<base").count(), 1, "{framed}");
        assert!(framed.contains("<base target=\"_top\">"), "{framed}");
        assert!(
            !framed.contains("evil.example") && !framed.contains("_self"),
            "{framed}"
        );
        let top = render_view(html, &RenderOptions::default(), &[], &[]).document;
        assert!(!top.contains("<base") && !top.contains("target="), "{top}");
    }

    /// The "..." of a folded quote has its dots in the middle of its pill, as the editor's button has them: a 17 pixel
    /// box with a 13 pixel line left them at the top
    #[test]
    fn the_fold_button_centres_its_dots() {
        let document = render_view("<p>hi</p>", &RenderOptions::default(), &[], &[]).document;
        let rule = document
            .split("details.pe-fold>summary{")
            .nth(1)
            .unwrap()
            .split('}')
            .next()
            .unwrap();
        for part in [
            "display:inline-flex",
            "align-items:center",
            "box-sizing:border-box",
            "height:17px",
        ] {
            assert!(rule.contains(part), "{rule}");
        }
        assert!(!rule.contains("line-height"), "{rule}");
    }

    #[test]
    fn a_print_page_runs_only_its_own_script() {
        let document = render_view("<p>hi<script>bad()</script></p>", &RenderOptions::default(), &[], &[]).document;
        let page = print_page(&document).unwrap();
        let nonce = page.split("'nonce-").nth(1).unwrap().split('\'').next().unwrap();
        assert_eq!(nonce.len(), 32);
        assert!(
            page.contains(&format!("script-src 'nonce-{nonce}'; img-src 'none'")),
            "{page}"
        );
        // one script, ours, at the end of the body; the message's own is gone as in the preview
        assert_eq!(page.matches("<script").count(), 1, "{page}");
        assert!(
            page.ends_with(&format!(
                "<script nonce=\"{nonce}\">{PRINT_SCRIPT}</script></body></html>"
            )),
            "{page}"
        );
        assert!(!page.contains("bad()"));
        assert_eq!(print_page("<html>not ours</html>"), None);
    }

    #[test]
    fn tells_whether_a_message_has_pictures_on_the_internet() {
        let options = RenderOptions::default();
        let remote = |html: &str| render_view(html, &options, &[], &[]).remote_images;
        for html in [
            "<img src=\"https://example.com/a.png\">",
            "<img src=\"HTTP://example.com/a.png\">",
            "<img src=\"//example.com/a.png\">",
            "<table background=\"http://example.com/bg.gif\"><tr><td>x</td></tr></table>",
            "<div style=\"background-image: url('https://example.com/bg.png')\">x</div>",
            "<div style='background:url(\"//example.com/bg.png\")'>x</div>",
            "<style>p { background: URL( http://example.com/p.png ) }</style><p>x</p>",
        ] {
            assert!(remote(html), "{html}");
        }
        for html in [
            "<p>Plain text with a link to https://example.com and <a href=\"https://example.com\">a link</a></p>",
            "<img src=\"data:image/png;base64,AAAA\">",
            "<img src=\"cid:logo@x\">",
            "<p>src=\"https://example.com\" written as text</p>",
            "<div style=\"color:red\">url( is only text here</div>",
            // written in the text, not an attribute: the old text scan took this for a picture
            "<p> src=\"https://example.com/x.png\" and url(https://example.com/y.png)</p>",
        ] {
            assert!(!remote(html), "{html}");
        }
    }

    const TOKEN: &str = "0123456789abcdef0123456789abcdef";

    /// [`render_view_cards`] with the pictures of the text routed under [`TOKEN`], each 600 by 200
    fn routed(html: &str, images: &[InlineImage]) -> Rendered {
        let size = |_: &InlinePicture| Some((600, 200));
        let inline = InlineOptions {
            token: TOKEN,
            first: INLINE_BASE,
            size: &size,
        };
        let cards = Cards {
            inline: Some(&inline),
            ..Default::default()
        };
        render_view_cards(html, &RenderOptions::default(), images, &[], &cards)
    }

    /// A `cid:` picture is shown from a preview address of the document, never as the bytes the sender wrote; its
    /// size is put in where its img says none; a part that is no picture, or a Content-ID of nothing, loads nothing
    #[test]
    fn a_cid_picture_is_routed_to_a_preview_address() {
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
        let rendered = routed(
            "<img src=\"cid:logo@x\"><img src=\"CID:%3Cpage@x%3E\"><table background=\"cid:missing\"></table>\
             <table background=\"CID:LOGO@X\"></table><a href=\"cid:logo@x\">x</a>",
            &[png, html_part],
        );
        let out = &rendered.document;
        let address = format!("/pv/{TOKEN}-{INLINE_BASE}-0");
        assert!(
            out.contains(&format!("<img src=\"{address}\" width=\"600\" height=\"200\">")),
            "{out}"
        );
        // one picture, once, however often it is shown
        assert!(out.contains(&format!("background=\"{address}\"")), "{out}");
        assert_eq!(rendered.inline.len(), 1);
        assert_eq!(rendered.inline[0].number, INLINE_BASE);
        assert_eq!(*rendered.inline[0].bytes, b"\x89PNG");
        // nothing of the bytes in the document, nothing of the other part
        assert!(!out.contains("iVBOR") && !out.contains("data:image"), "{out}");
        assert!(!out.contains("text/html") && !out.contains("PHNjcmlwdD4"));
        assert!(out.contains("background=\"cid:missing\""));
        assert!(out.contains("href=\"cid:logo@x\""), "{out}");
        // pictures from the document's preview path, never from data:
        let csp = out[out.find(CSP_START).unwrap()..].split('>').next().unwrap();
        assert!(csp.contains(&format!("img-src {}/pv/;", preview_origin())), "{csp}");

        // without preview addresses (no core to answer them), the picture shows nothing
        let out = render_message(
            "<img src=\"cid:logo@x\" alt=\"Logo\">",
            &RenderOptions::default(),
            &[png],
        );
        assert!(out.contains("<img alt=\"Logo\">"), "{out}");
        assert!(out.contains("img-src 'none';"), "{out}");
    }

    /// An address is read as a URL parser reads it: a tab or a newline in its scheme, or controls before it, hide no
    /// `data:` (or `cid:`) address from the sanitizer, on screen or in the editor
    #[test]
    fn a_data_address_is_found_however_it_is_written() {
        let png = InlineImage {
            content_id: "a@x",
            mime_type: "image/png",
            data: b"\x89PNG",
        };
        let rendered = routed(
            "<img src=\"da&#9;ta:image/gif;base64,R0lGODlh\"><img src=\"&#1;data:image/gif;base64,R0lGODlh\">\
             <img src=\" c&#10;id:a@x\"><table background=\"da&#9;ta:image/png;base64,AAAA\"></table>\
             <a href=\"da&#13;ta:text/html,x\">y</a>",
            &[png],
        );
        let out = &rendered.document;
        // the two data: pictures are one picture, the cid: one another
        assert_eq!(rendered.inline.len(), 2, "{out}");
        assert_eq!(out.matches(&format!("src=\"/pv/{TOKEN}-")).count(), 3, "{out}");
        let squeezed: String = out.chars().filter(|c| !c.is_control()).collect();
        assert!(!squeezed.to_ascii_lowercase().contains("data:"), "{out}");
        assert!(!out.contains("background=") && !out.contains("href="), "{out}");
        // the editor's sanitizer: a data: link is taken out, a cid: picture embedded
        let edited = builder(&[png])
            .clean("<a href=\"da&#9;ta:text/html,x\">y</a><img src=\"&#1;cid:a@x\">")
            .to_string();
        assert!(!edited.contains("href"), "{edited}");
        assert!(edited.contains("src=\"data:image/png;base64,iVBORw==\""), "{edited}");
    }

    /// A `data:` picture of an img is routed as a `cid:` one is; anywhere else a `data:` address is taken out, and the
    /// CSP of a document on screen never lets a picture come from `data:` (a message's CSS may name one)
    #[test]
    fn a_data_picture_never_reaches_the_web_view() {
        let rendered = routed(
            "<img src=\"data:image/gif;base64,R0lGODlh\" width=\"30\"><img src=\"data:text/html;base64,PHA+\">\
             <table background=\"data:image/png;base64,AAAA\"></table>\
             <div style=\"background:url(data:image/png;base64,AAAA)\">x</div>",
            &[],
        );
        let out = &rendered.document;
        assert!(
            out.contains(&format!(
                "<img src=\"/pv/{TOKEN}-{INLINE_BASE}-0\" width=\"30\" height=\"10\">"
            )),
            "{out}"
        );
        assert_eq!(rendered.inline.len(), 1);
        assert_eq!(*rendered.inline[0].bytes, b"GIF89a");
        assert!(!out.contains("PHA+") && !out.contains("background=\"data:"), "{out}");
        let csp = out[out.find(CSP_START).unwrap()..].split('>').next().unwrap();
        assert!(!csp.contains("data: ") && !csp.contains("data:;"), "{csp}");
        assert!(csp.contains("font-src 'none'"), "{csp}");
        // sanitized alone: nothing to route it to, so nothing
        let out = sanitize("<img src=\"data:image/png;base64,AAAA\">");
        assert!(!out.contains("data:"), "{out}");
    }

    /// The message's own CSS names no picture or font of its own, on screen or in the printout (whose CSP allows
    /// `data:` for the core's encodes), and no document allows a font from anywhere
    #[test]
    fn the_message_s_css_brings_no_picture_or_font_of_its_own() {
        let html = "<style>@font-face{font-family:X;src:url(data:font/woff2;base64,AAAA)}\
                    body{background:url(data:image/png;base64,AAAA)}li{list-style:u\\72l('d\\61ta:image/gif;base64,R0lG')}\
                    h1{background:url(https://example.com/h.png)}</style>\
                    <div style=\"background-image:url(data:image/png;base64,AAAA);border-image:url(&quot;data:x&quot;) 3\">x</div>\
                    <p style=\"content:image-set('data:image/png;base64,AA' 1x)\">y</p><img src=\"cid:a@x\">";
        let png = InlineImage {
            content_id: "a@x",
            mime_type: "image/png",
            data: b"\x89PNG",
        };
        let rendered = routed(html, &[png]);
        let printed = print_document_with(&rendered.print.clone().unwrap(), &[]);
        for document in [&rendered.document, &printed] {
            let lower = document.to_ascii_lowercase();
            let body = &lower[lower.find("<body>").unwrap()..];
            // the only data: left is the printout's own placeholder for the picture not drawn
            assert_eq!(
                body.matches("data:").count(),
                body.matches(&NOT_PRINTED_PICTURE.to_ascii_lowercase()).count(),
                "{document}"
            );
            assert!(
                !lower.contains("@font-face") && !lower.contains("@f\\6fnt"),
                "{document}"
            );
            assert!(!body.contains("d\\61ta"), "{document}");
            assert!(lower.contains("font-src 'none'"), "{document}");
            assert!(!lower.contains("font-src data:"), "{document}");
            // a picture on the internet stays, for Download Pictures
            assert!(document.contains("url(https://example.com/h.png)"), "{document}");
        }
        assert!(rendered.remote_images);
        assert!(rendered.document.contains("background:none"), "{}", rendered.document);
    }

    /// Past [`MAX_INLINE`] pictures (or [`MAX_INLINE_BYTES`] of them) the rest show nothing
    #[test]
    fn the_pictures_of_the_text_stop_at_the_limits() {
        let html: String = (0..MAX_INLINE + 5)
            .map(|n| {
                format!(
                    "<img src=\"data:image/png;base64,{}\">",
                    STANDARD.encode(format!("picture {n}"))
                )
            })
            .collect();
        let rendered = routed(&html, &[]);
        assert_eq!(rendered.inline.len(), MAX_INLINE);
        assert_eq!(rendered.document.matches(&format!("/pv/{TOKEN}-")).count(), MAX_INLINE);
        let big = vec![7; MAX_INLINE_BYTES / 2 + 1];
        let image = InlineImage {
            content_id: "big@x",
            mime_type: "image/png",
            data: &big,
        };
        let other = InlineImage {
            content_id: "other@x",
            ..image
        };
        let rendered = routed("<img src=\"cid:big@x\"><img src=\"cid:other@x\">", &[image, other]);
        assert_eq!(rendered.inline.len(), 1);
    }

    /// The printout of a message with pictures in its text has them where the text shows them, as `data:` addresses
    /// of the core's encodes (an empty picture for one not drawn); no preview address is left
    /// Whatever a message hides in its markup or its CSS, the only `data:` addresses of its printout (whose CSP allows
    /// them) are the core's: its encodes and the empty picture
    #[test]
    fn a_printout_has_no_data_address_but_the_core_s() {
        let png = InlineImage {
            content_id: "a@x",
            mime_type: "image/png",
            data: b"sender's bytes",
        };
        let html = "<style>p{background:image-set('da\tta:image/png;base64,AA' 1x)}\
                    q{background:image-set('da\\9 ta:x' 1x, '\\1 data:x' 2x)}\
                    b{background:url(\"https://a/\" /*(*/), image-set(\"data:image/png;base64,AA\" 1x) /*)*/}\
                    i{background:u\\72l(d\\61t\\61\\3a x)}</style>\
                    <img src=\"da&#9;ta:image/gif;base64,R0lGODlh\"><img src=\"&#1;data:image/gif;base64,R0lGODlh\">\
                    <table background=\"da&#9;ta:image/png;base64,AAAA\"></table>\
                    <div style=\"background:image-set('d&#9;ata:x' 1x)\">x</div>\
                    <p title=\"da&#10;ta:x\">Metadata: kept</p><img src=\"cid:a@x\">";
        let rendered = routed(html, &[png]);
        let items = [(
            None,
            PrintItem::Inline {
                number: INLINE_BASE + 1,
                mime: "image/png",
                bytes: b"\x89PNG",
            },
        )];
        let printed = print_document_with(&rendered.print.clone().unwrap(), &items);
        // read as a URL parser and CSS read it: tabs and newlines out, escapes decoded
        let body = &printed[printed.find("<body>").unwrap()..];
        let squeezed: String = body
            .replace("\\61", "a")
            .replace("\\3a", ":")
            .chars()
            .filter(|c| !matches!(c, '\t' | '\n' | '\r'))
            .collect::<String>()
            .to_ascii_lowercase();
        let ours = [
            "data:image/png;base64,iVBORw==",
            &NOT_PRINTED_PICTURE.to_ascii_lowercase(),
        ];
        let total = squeezed.matches("data:").count() - squeezed.matches("metadata:").count();
        let core: usize = ours
            .iter()
            .map(|address| squeezed.matches(&address.to_ascii_lowercase()).count())
            .sum();
        assert_eq!(total, core, "{printed}");
        assert!(core >= 2, "{printed}");
        assert!(printed.contains("Metadata: kept"), "{printed}");
    }

    #[test]
    fn a_printout_has_the_pictures_of_the_text_as_data() {
        let png = InlineImage {
            content_id: "a@x",
            mime_type: "image/png",
            data: b"sender's bytes",
        };
        let other = InlineImage {
            content_id: "b@x",
            ..png
        };
        let rendered = routed(
            "<p>hi</p><img src=\"cid:a@x\"><img src=\"cid:b@x\"><p>bye</p>",
            &[png, other],
        );
        assert_eq!(rendered.print_document, None);
        let parts = rendered.print.unwrap();
        let items = [(
            None,
            PrintItem::Inline {
                number: INLINE_BASE,
                mime: "image/png",
                bytes: b"\x89PNG",
            },
        )];
        let printed = print_document_with(&parts, &items);
        let at = |text: &str| printed.find(text).unwrap_or_else(|| panic!("{text} in {printed}"));
        assert!(at("<p>hi</p>") < at("data:image/png;base64,iVBORw==") && at("iVBORw==") < at("<p>bye</p>"));
        assert!(printed.contains(NOT_PRINTED_PICTURE), "{printed}");
        assert!(!printed.contains("/pv/") && !printed.contains(TOKEN), "{printed}");
        assert!(!printed.contains("pe-prt-"), "{printed}");
        assert!(printed.contains("img-src data:;"), "{printed}");
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
    fn keeps_mail_layout() {
        let out = sanitize(
            "<style>p{color:red}</style><table bgcolor=\"#fff\"><tr><td style=\"padding:4px\">x</td></tr></table>",
        );
        assert!(out.contains("<style>p{color:red}</style>"));
        assert!(out.contains("bgcolor=\"#fff\""));
        assert!(out.contains("style=\"padding:4px\""));
    }

    #[test]
    fn plain_text_keeps_a_line_length() {
        let out = sanitize("<div class=\"pe-plain\">a line</div><div class=\"other\">b</div>");
        assert!(out.contains("<div class=\"pe-plain\">a line</div>"), "{out}");
        assert!(!out.contains("other"), "{out}");
        let document = render_message("<div class=\"pe-plain\">a line</div>", &RenderOptions::default(), &[]);
        assert!(document.contains("div.pe-plain{max-width:46em}"));
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

    fn previews(token: &str) -> PreviewSection {
        PreviewSection {
            token: token.into(),
            files: vec![
                PreviewFile {
                    attachment: 0,
                    content_id: Some("<logo@x>".into()),
                    pages: vec![PreviewPage {
                        page: 0,
                        width: 64,
                        height: 32,
                        alt: "logo.png".into(),
                    }],
                    name: "logo.png".into(),
                    ..Default::default()
                },
                PreviewFile {
                    attachment: 1,
                    paper: true,
                    pages: vec![PreviewPage {
                        page: 0,
                        width: 620,
                        height: 877,
                        alt: "invoice.pdf, page 1 of 1".into(),
                    }],
                    name: "invoice.pdf".into(),
                    details: "1 page, 3 KB".into(),
                    ..Default::default()
                },
            ],
            notice: None,
            more_files: None,
        }
    }

    /// The previews come after the message's text, and the CSP lets pictures load from the preview path of the
    /// page's own origin only, and only when there are previews
    #[test]
    fn previews_follow_the_text_and_the_csp_allows_only_their_path() {
        let token = preview_token();
        let section = previews(&token);
        let cards = Cards {
            previews: Some(&section),
            ..Default::default()
        };
        // the message writes a section of its own, styles to hide ours, and an address of a preview it guessed
        let html = "<section class=\"pe-att-x\">fake</section><style>img{display:none!important}\
                    section{display:none!important}</style><img src=\"/pv/00000000000000000000000000000000-1-0\">";
        let rendered = render_view_cards(html, &RenderOptions::default(), &[], &[], &cards);
        let document = &rendered.document;
        assert_eq!(rendered.previewed, [0, 1]);
        let csp = document[document.find(CSP_START).unwrap()..].split('>').next().unwrap();
        assert!(csp.contains(&format!("img-src {}/pv/;", preview_origin())), "{csp}");
        assert!(!csp.contains("'self'"), "{csp}");
        // the message's own section is gone (its words stay); ours is the last thing in the body
        assert!(!document.contains("pe-att-x"), "{document}");
        let ours = document.find(previews::SECTION_START).unwrap();
        assert!(ours > document.find("fake").unwrap());
        assert!(
            document[ours..].ends_with(&format!("</section>{DOCUMENT_END}")),
            "{document}"
        );
        assert!(document.contains(&format!("src=\"/pv/{token}-1-0\"")), "{document}");
        // the message's guess stays an address no server answers: it does not carry the view's token
        assert_eq!(document.matches(&token).count(), 4, "{document}");

        // no previews, no preview path in the CSP
        let plain = render_view_cards("<p>hi</p>", &RenderOptions::default(), &[], &[], &Cards::default());
        assert!(plain.previewed.is_empty());
        assert!(!plain.document.contains("/pv/"), "{}", plain.document);
        assert!(plain.document.contains("img-src 'none';"));
        // with pictures from the internet allowed, both
        let remote = render_view_cards(
            "<p>hi</p>",
            &RenderOptions {
                allow_remote_images: true,
                ..Default::default()
            },
            &[],
            &[],
            &cards,
        );
        assert!(
            remote
                .document
                .contains(&format!("img-src http: https: {}/pv/;", preview_origin())),
            "{}",
            remote.document
        );
    }

    /// A picture the message's HTML shows by `cid:` is not shown again after it
    #[test]
    fn a_picture_shown_in_the_text_is_not_previewed_again() {
        let token = preview_token();
        let section = previews(&token);
        let cards = Cards {
            previews: Some(&section),
            ..Default::default()
        };
        let png = InlineImage {
            content_id: "<LOGO@x>",
            mime_type: "image/png",
            data: b"\x89PNG",
        };
        let rendered = render_view_cards(
            "<p>hi</p><img src=\"cid:logo@x\">",
            &RenderOptions::default(),
            &[png],
            &[],
            &cards,
        );
        assert_eq!(rendered.previewed, [1]);
        assert!(!rendered.document.contains(&format!("/pv/{token}-0-0")));
    }

    /// The print page has no previews: the print window serves none of their pictures
    #[test]
    fn a_print_page_has_no_previews() {
        let token = preview_token();
        let section = previews(&token);
        let cards = Cards {
            previews: Some(&section),
            ..Default::default()
        };
        let rendered = render_view_cards("<p>hi</p>", &RenderOptions::default(), &[], &[], &cards);
        assert!(rendered.document.contains(&format!("/pv/{token}")));
        let printed = rendered.print_document.unwrap();
        assert!(!printed.contains(&format!("/pv/{token}")), "{printed}");
        assert!(!printed.contains("pe-att-"), "{printed}");
        assert!(!printed.contains(&previews::preview_source()), "{printed}");
        let page = print_page(&printed).unwrap();
        assert!(page.contains("<p>hi</p>"));
        // a document without previews is printed as it is
        let plain = render_view_cards("<p>hi</p>", &RenderOptions::default(), &[], &[], &Cards::default());
        assert_eq!(plain.print_document, None);
    }

    /// The printout of a document with previews: wrapped again with its pictures as `data:` addresses and a line for
    /// each file not printed; nothing loads from the preview path, and the CSP lets pictures come from `data:` only
    #[test]
    fn a_printout_has_the_pictures_as_data() {
        let token = preview_token();
        let section = previews(&token);
        let cards = Cards {
            previews: Some(&section),
            ..Default::default()
        };
        let header = [("Subject", "Photos")];
        let rendered = render_view_cards("<p>hi</p>", &RenderOptions::default(), &[], &header, &cards);
        let parts = rendered.print.clone().unwrap();
        let items = [
            (
                None,
                PrintItem::Picture {
                    name: "red.png",
                    mime: "image/png",
                    bytes: b"\x89PNG",
                },
            ),
            (
                None,
                PrintItem::Line("invoice.pdf (1 page, 3 KB) is not printed. Open it to print it."),
            ),
        ];
        let printed = print_document_with(&parts, &items);
        assert!(printed.contains("<p>hi</p>"), "{printed}");
        assert!(printed.contains("Photos"), "{printed}");
        assert!(printed.contains("src=\"data:image/png;base64,iVBORw==\""), "{printed}");
        assert!(
            printed.contains("invoice.pdf (1 page, 3 KB) is not printed."),
            "{printed}"
        );
        assert!(!printed.contains(&token) && !printed.contains("/pv/"), "{printed}");
        let csp = printed[printed.find(CSP_START).unwrap()..].split('>').next().unwrap();
        assert!(csp.contains("img-src data:;"), "{csp}");
        // after the text, and a page of the print window as any printout
        assert!(printed.find("<p>hi</p>").unwrap() < printed.find("pe-prt-").unwrap());
        assert!(print_page(&printed).unwrap().contains("data:image/png;base64"));
        // a document without previews has none to print again
        let plain = render_view_cards("<p>hi</p>", &RenderOptions::default(), &[], &[], &Cards::default());
        assert_eq!(plain.print, None);
    }

    /// The markup of a document outside its style elements
    fn outside_styles(document: &str) -> String {
        let mut out = String::new();
        let mut rest = document;
        while let Some(start) = rest.find("<style") {
            out.push_str(&rest[..start]);
            rest = &rest[start..];
            rest = &rest[rest.find("</style>").map_or(rest.len(), |end| end + "</style>".len())..];
        }
        out.push_str(rest);
        out
    }

    /// The previews' markers forged in a message's own style element stay style text in the shown and the printed
    /// document: nothing is ever cut out of a finished document by them
    #[test]
    fn forged_preview_markers_stay_style_text() {
        let html = "<p>hi</p><style>@layer pe-att-x{}<section class=\"pe-att-y\"></section>\
                    <img src=x onerror=alert(1)><iframe srcdoc=x></iframe>\
                    <form action=https://e.example/><input name=p></form></style>";
        let token = preview_token();
        let section = previews(&token);
        let cards = Cards {
            previews: Some(&section),
            ..Default::default()
        };
        let rendered = render_view_cards(html, &RenderOptions::default(), &[], &[], &cards);
        let printed = rendered.print_document.clone().unwrap();
        let page = print_page(&printed).unwrap();
        for document in [&rendered.document, &printed, &page] {
            let markup = outside_styles(document);
            for tag in ["<iframe", "<form", "<input", "onerror"] {
                assert!(!markup.contains(tag), "{tag} in {document}");
            }
            // the forged text is still there, inside a style element
            assert!(document.contains("onerror=alert(1)"), "{document}");
        }
        // the shown document's pictures are its previews' only; the printed ones have none
        let shown = outside_styles(&rendered.document);
        assert_eq!(
            shown.matches("<img").count(),
            shown.matches("src=\"/pv/").count(),
            "{shown}"
        );
        assert!(!outside_styles(&printed).contains("<img"), "{printed}");
        assert!(!outside_styles(&page).contains("<img"), "{page}");
        // the plain print path (no previews) keeps it as style text too
        let plain = render_view_cards(html, &RenderOptions::default(), &[], &[], &Cards::default());
        assert_eq!(plain.print_document, None);
        let page = print_page(&plain.document).unwrap();
        let markup = outside_styles(&page);
        for tag in ["<img", "<iframe", "<form", "onerror"] {
            assert!(!markup.contains(tag), "{tag} in {page}");
        }
    }

    #[test]
    fn csp_follows_remote_images() {
        let blocked = render_document("x", &RenderOptions::default());
        assert!(blocked.contains("img-src 'none';"));
        let allowed = render_document(
            "x",
            &RenderOptions {
                allow_remote_images: true,
                ..Default::default()
            },
        );
        assert!(allowed.contains("img-src http: https:;"));
    }

    /// The core's own printout (a message with signed or encrypted parts): its markup sanitized, its header and
    /// pictures as any printout's, and with none the same document as before
    #[test]
    fn print_parts_wrap_the_core_s_own_markup() {
        let parts = print_parts(
            &[(
                0,
                "<p><b>Part 1: Signed</b></p><p>Hi</p><script>x()</script>".to_string(),
            )],
            &[("From", "Ann")],
        );
        let plain = print_document_with(&parts, &[]);
        assert!(
            plain.contains("<b>Part 1: Signed</b>") && !plain.contains("<script"),
            "{plain}"
        );
        assert!(
            plain.contains("img-src data:;") && plain.contains(":</span> Ann</div>"),
            "{plain}"
        );
        let items = [(
            Some(1),
            PrintItem::Picture {
                name: "Part 2: a.png",
                mime: "image/png",
                bytes: b"\x89PNG",
            },
        )];
        let printed = print_document_with(&parts, &items);
        assert!(
            printed.contains("<img src=\"data:image/png;base64,iVBORw==\""),
            "{printed}"
        );
        assert!(printed.contains("Part 2: a.png"), "{printed}");
    }

    /// Each part's pictures are printed right after that part's text, not after all of it: part 1's picture before
    /// part 2's words, part 2's after them
    #[test]
    fn each_part_prints_its_pictures_after_its_text() {
        let parts = print_parts(
            &[
                (0, "<p><b>Part 1: Not signed</b></p><p>FIRST</p>".to_string()),
                (1, "<p><b>Part 2: Encrypted</b></p><p>SECOND</p>".to_string()),
            ],
            &[],
        );
        let picture = |name| PrintItem::Picture {
            name,
            mime: "image/png",
            bytes: b"\x89PNG",
        };
        let items = [
            (Some(1), picture("Part 2: plan.png")),
            (Some(0), picture("Part 1: harbour.png")),
            (None, PrintItem::Line("LOOSE")),
        ];
        let printed = print_document_with(&parts, &items);
        let at = |text: &str| printed.find(text).unwrap_or_else(|| panic!("{text} in {printed}"));
        assert!(at("FIRST") < at("Part 1: harbour.png"));
        assert!(at("Part 1: harbour.png") < at("<hr>"));
        assert!(at("<hr>") < at("SECOND"));
        assert!(at("SECOND") < at("Part 2: plan.png"));
        assert!(at("Part 2: plan.png") < at("LOOSE"));
        assert_eq!(printed.matches("<img").count(), 2);
    }
}
