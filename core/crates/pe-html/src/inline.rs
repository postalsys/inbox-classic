//! The pictures in a message's text (docs/attachment-preview-plan.md, decision 8): a `cid:` part the HTML shows, or a
//! `data:` address written into it, is never handed to the web view as the sender wrote it. Its address becomes a
//! preview address of the document (`/pv/<token>-<number>-0`), and the core answers it with a picture it decoded and
//! encoded again itself, as it answers the previews of attachments: the web view decodes only the core's PNG or JPEG.
//!
//! The sanitizer's attribute filter routes each such address ([`Router`]); the bytes of each picture go back to the
//! core with its number ([`InlinePicture`]). After sanitizing, an `img` with neither a width nor a height gets the size
//! of its preview ([`InlineOptions::size`]), so the text does not move when the picture comes; with one of them, the
//! other by the picture's proportions. A picture the core can not draw (HEIC, a broken file) is answered with a plain
//! placeholder, never the sender's bytes.

use std::collections::{HashMap, HashSet};
use std::sync::{Arc, Mutex};

use base64::Engine;

use crate::InlineImage;
use crate::previews::PREVIEW_PATH;

/// The number of the first picture of a message's text in its document's preview addresses: far above any attached
/// file's place in the strip, which the other preview addresses carry
pub const INLINE_BASE: usize = 500_000;

/// The most pictures a document's text shows: the rest show nothing
pub const MAX_INLINE: usize = 200;

/// The most bytes of pictures a document's text shows, the sender's bytes as they came (each picture once however
/// often it is shown): a picture past it shows nothing
pub const MAX_INLINE_BYTES: usize = 32 * 1024 * 1024;

/// The highest number a preview address carries ([`crate::parse_preview_address`] reads six digits)
const MAX_NUMBER: usize = 999_999;

/// How a document routes the pictures of its text to the core
pub struct InlineOptions<'a> {
    /// The token of the document's preview addresses ([`crate::preview_token`])
    pub token: &'a str,
    /// The number of its first picture: [`INLINE_BASE`], or after the pictures of the parts before it, so the pictures
    /// of a view's documents never share a number
    pub first: usize,
    /// The size of a picture's preview (its own, as the core will draw it), asked for an `img` that says neither its
    /// width nor its height; None when it is not known in time
    pub size: &'a dyn Fn(&InlinePicture) -> Option<(u32, u32)>,
}

/// A picture of a message's text, as the sender wrote it, under the number of its document's address
#[derive(Clone, PartialEq, Eq)]
pub struct InlinePicture {
    pub number: usize,
    pub bytes: Arc<Vec<u8>>,
}

impl std::fmt::Debug for InlinePicture {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        write!(f, "InlinePicture({}, {} bytes)", self.number, self.bytes.len())
    }
}

/// Where a picture of the text comes from
enum Origin {
    /// The `index`th picture the message carries for its HTML
    Part(usize),
    /// A `data:` address's bytes
    Data(Arc<Vec<u8>>),
}

#[derive(Default)]
struct State {
    /// The number of each part shown, by its index
    parts: HashMap<usize, usize>,
    /// The number of each `data:` picture, by its bytes
    data: HashMap<Arc<Vec<u8>>, usize>,
    /// Every picture routed, in the order of the text
    routed: Vec<(usize, Origin)>,
    bytes: usize,
    /// The Content-IDs (lowercase) the text showed
    noted: HashSet<String>,
}

/// What the attribute filter does with a picture's address of the message's text: the sanitizer wants a callback
/// that owns its data, so the parts are known by their Content-IDs and sizes only, and their bytes taken after
pub(crate) struct Router {
    /// The start of the document's preview addresses (`/pv/<token>-`); None for a document without them: its
    /// pictures show nothing
    prefix: Option<String>,
    first: usize,
    /// Content-ID, lowercased, to the picture's index and size; the first picture of an ID wins
    by_id: HashMap<String, (usize, usize)>,
    state: Mutex<State>,
}

/// What becomes of an address of the text
pub(crate) enum Route {
    /// A preview address of the document
    To(String),
    /// Left as it is: a `cid:` of no picture the message carries, which nothing loads
    Keep,
    /// Taken out: a picture past the limits, or of a document without preview addresses
    Drop,
}

impl Router {
    pub(crate) fn new(images: &[InlineImage], options: Option<&InlineOptions>) -> Router {
        let mut by_id = HashMap::new();
        for (index, image) in images.iter().enumerate() {
            if image.mime_type.starts_with("image/") {
                by_id
                    .entry(crate::content_id(image.content_id).to_lowercase())
                    .or_insert((index, image.data.len()));
            }
        }
        Router {
            prefix: options.map(|options| format!("{PREVIEW_PATH}{}-", options.token)),
            first: options.map_or(INLINE_BASE, |options| options.first),
            by_id,
            state: Mutex::default(),
        }
    }

    fn state(&self) -> std::sync::MutexGuard<'_, State> {
        self.state.lock().unwrap_or_else(|p| p.into_inner())
    }

    /// A `cid:` address (`url` with its scheme) of an `img` or a `background`
    pub(crate) fn part(&self, url: &str) -> Route {
        let id = crate::content_id(&url.trim_start()[4..]).to_lowercase();
        let Some(&(index, size)) = self.by_id.get(&id) else {
            return Route::Keep;
        };
        let mut state = self.state();
        state.noted.insert(id);
        let known = state.parts.get(&index).copied();
        self.address(&mut state, known, size, |state, number| {
            state.parts.insert(index, number);
            Origin::Part(index)
        })
    }

    /// A `data:` address of an `img`: a picture's bytes, `image/*` only
    pub(crate) fn data(&self, url: &str) -> Route {
        let Some(bytes) = data_picture(url) else {
            return Route::Drop;
        };
        let bytes = Arc::new(bytes);
        let mut state = self.state();
        let known = state.data.get(&bytes).copied();
        let size = bytes.len();
        self.address(&mut state, known, size, |state, number| {
            state.data.insert(bytes.clone(), number);
            Origin::Data(bytes)
        })
    }

    /// The address of a picture: its number when it was routed before (`known`), a new one while the limits allow,
    /// the picture then noted by `note`
    fn address(
        &self,
        state: &mut State,
        known: Option<usize>,
        size: usize,
        note: impl FnOnce(&mut State, usize) -> Origin,
    ) -> Route {
        let Some(prefix) = &self.prefix else {
            return Route::Drop;
        };
        let number = match known {
            Some(number) => number,
            None => {
                let number = self.first + state.routed.len();
                if state.routed.len() >= MAX_INLINE
                    || number > MAX_NUMBER
                    || size == 0
                    || state.bytes + size > MAX_INLINE_BYTES
                {
                    return Route::Drop;
                }
                state.bytes += size;
                let origin = note(state, number);
                state.routed.push((number, origin));
                number
            }
        };
        Route::To(format!("{prefix}{number}-0"))
    }

    /// The pictures routed, in the order of the text, their bytes taken from `images`; and the Content-IDs the text
    /// showed
    pub(crate) fn finish(&self, images: &[InlineImage]) -> (Vec<InlinePicture>, HashSet<String>) {
        let mut state = self.state();
        let pictures = std::mem::take(&mut state.routed)
            .into_iter()
            .map(|(number, origin)| InlinePicture {
                number,
                bytes: match origin {
                    Origin::Part(index) => Arc::new(images[index].data.to_vec()),
                    Origin::Data(bytes) => bytes,
                },
            })
            .collect();
        (pictures, std::mem::take(&mut state.noted))
    }
}

/// The bytes of a `data:` address of a picture (`data:image/png;base64,...`, or percent-escaped without `;base64`);
/// None for another type, a malformed address, or one past [`MAX_INLINE_BYTES`]
fn data_picture(url: &str) -> Option<Vec<u8>> {
    let rest = url.trim().get(5..)?;
    let (meta, data) = rest.split_once(',')?;
    let mut params = meta.split(';').map(str::trim);
    let mime = params.next()?.to_ascii_lowercase();
    if !mime.starts_with("image/") {
        return None;
    }
    let base64 = params.any(|param| param.eq_ignore_ascii_case("base64"));
    // base64 grows by a third; a percent escape triples a byte
    if data.len() > MAX_INLINE_BYTES / 3 * 4 + 4 {
        return None;
    }
    let data = percent_decoded(data);
    let bytes = if base64 {
        let text: Vec<u8> = data.into_iter().filter(|b| !b.is_ascii_whitespace()).collect();
        let engine = base64::engine::GeneralPurpose::new(
            &base64::alphabet::STANDARD,
            base64::engine::GeneralPurposeConfig::new()
                .with_decode_padding_mode(base64::engine::DecodePaddingMode::Indifferent),
        );
        engine.decode(text).ok()?
    } else {
        data
    };
    (!bytes.is_empty() && bytes.len() <= MAX_INLINE_BYTES).then_some(bytes)
}

/// `text` with its percent escapes decoded
fn percent_decoded(text: &str) -> Vec<u8> {
    let bytes = text.as_bytes();
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
    out
}

/// A sanitized body with the size of each picture of its text in the `img` that shows it, when the `img` says neither
/// its width nor its height (`size` of the picture's number), or the other one by the picture's proportions when it
/// says one in pixels. `prefix` is the start of the document's addresses (`/pv/<token>-`), which only the router
/// wrote: the token is not the sender's to know.
///
/// The body is the sanitizer's own serialization: tags and attribute names in lowercase, every value in double quotes
/// (a quote in it escaped), `<` in text escaped, and the only element whose text is not escaped is `style`.
pub(crate) fn sized(body: &str, prefix: &str, size: &dyn Fn(usize) -> Option<(u32, u32)>) -> String {
    let mut out = String::with_capacity(body.len() + 64);
    let mut rest = body;
    while let Some(at) = rest.find('<') {
        out.push_str(&rest[..at]);
        rest = &rest[at..];
        if rest.starts_with("<style") {
            // the style element's text as it is, up to its end
            let end = rest.find("</style").unwrap_or(rest.len());
            out.push_str(&rest[..end]);
            rest = &rest[end..];
            if rest.is_empty() {
                break;
            }
            out.push('<');
            rest = &rest[1..];
            continue;
        }
        let end = tag_end(rest);
        let tag = &rest[..end];
        match rest.starts_with("<img") {
            true => out.push_str(&sized_img(tag, prefix, size)),
            false => out.push_str(tag),
        }
        rest = &rest[end..];
    }
    out.push_str(rest);
    out
}

/// The length of the tag `text` starts with, through its `>`: quoted values may hold one
fn tag_end(text: &str) -> usize {
    let mut quoted = false;
    for (at, byte) in text.bytes().enumerate().skip(1) {
        match byte {
            b'"' => quoted = !quoted,
            b'>' if !quoted => return at + 1,
            _ => {}
        }
    }
    text.len()
}

/// The attributes of a tag as the sanitizer writes it: `name="value"` or a bare name
fn attributes(tag: &str) -> Vec<(&str, &str)> {
    let inner = tag.trim_start_matches('<').trim_end_matches('>').trim_end_matches('/');
    let mut out = Vec::new();
    // past the tag's name
    let mut rest = inner.split_once(char::is_whitespace).map_or("", |(_, rest)| rest);
    loop {
        rest = rest.trim_start();
        if rest.is_empty() {
            return out;
        }
        let name_end = rest.find(|c: char| c == '=' || c.is_whitespace()).unwrap_or(rest.len());
        let name = &rest[..name_end];
        rest = &rest[name_end..];
        if let Some(value) = rest.strip_prefix("=\"") {
            let end = value.find('"').unwrap_or(value.len());
            out.push((name, &value[..end]));
            rest = value.get(end + 1..).unwrap_or("");
        } else {
            out.push((name, ""));
        }
    }
}

/// An `img` tag with the size of its picture added where it says none, when its `src` is a picture of the text
fn sized_img(tag: &str, prefix: &str, size: &dyn Fn(usize) -> Option<(u32, u32)>) -> String {
    let attributes = attributes(tag);
    let value = |name: &str| attributes.iter().find(|(n, _)| *n == name).map(|(_, v)| *v);
    let number = value("src")
        .and_then(|src| src.strip_prefix(prefix))
        .and_then(|rest| rest.strip_suffix("-0"))
        .and_then(|number| number.parse::<usize>().ok());
    let Some(number) = number else {
        return tag.to_string();
    };
    // a size in pixels, as a browser reads the attribute: its digits, a "px" after them at most
    let pixels = |name: &str| {
        let text = value(name)?.trim();
        let digits = text.trim_end_matches("px");
        (!digits.is_empty() && digits.len() <= 6 && digits.bytes().all(|b| b.is_ascii_digit()))
            .then(|| digits.parse::<u64>().ok())
            .flatten()
    };
    let added = match (value("width"), value("height")) {
        (Some(_), Some(_)) => return tag.to_string(),
        (None, None) => size(number).map(|(w, h)| (u64::from(w), u64::from(h))),
        (Some(_), None) => pixels("width")
            .zip(size(number))
            .and_then(|(width, (w, h))| (w > 0).then(|| (width, (width * u64::from(h)).div_ceil(u64::from(w)).max(1)))),
        (None, Some(_)) => pixels("height").zip(size(number)).and_then(|(height, (w, h))| {
            (h > 0).then(|| ((height * u64::from(w)).div_ceil(u64::from(h)).max(1), height))
        }),
    };
    let Some((width, height)) = added else {
        return tag.to_string();
    };
    let mut extra = String::new();
    if value("width").is_none() {
        extra.push_str(&format!(" width=\"{width}\""));
    }
    if value("height").is_none() {
        extra.push_str(&format!(" height=\"{height}\""));
    }
    let close = if tag.ends_with("/>") {
        tag.len() - 2
    } else {
        tag.len() - usize::from(tag.ends_with('>'))
    };
    format!("{}{extra}{}", &tag[..close], &tag[close..])
}

#[cfg(test)]
mod tests {
    use super::*;

    const PREFIX: &str = "/pv/0123456789abcdef0123456789abcdef-";

    #[test]
    fn data_addresses_of_pictures_are_read() {
        assert_eq!(
            data_picture("data:image/png;base64,iVBORw=="),
            Some(b"\x89PNG".to_vec())
        );
        assert_eq!(
            data_picture(" DATA:Image/GIF;BASE64,R0lG\nODlh"),
            Some(b"GIF89a".to_vec())
        );
        assert_eq!(data_picture("data:image/png;base64,iVBORw"), Some(b"\x89PNG".to_vec()));
        assert_eq!(data_picture("data:image/svg+xml,%3Csvg%3E"), Some(b"<svg>".to_vec()));
        for wrong in [
            "data:text/html;base64,PHA+",
            "data:,x",
            "data:image/png;base64,!!!!",
            "data:image/png;base64,",
            "data:image/png",
        ] {
            assert_eq!(data_picture(wrong), None, "{wrong}");
        }
    }

    fn size(number: usize) -> Option<(u32, u32)> {
        (number == INLINE_BASE).then_some((600, 200))
    }

    #[test]
    fn a_picture_without_a_size_gets_its_own() {
        let body = format!("<p>x</p><img src=\"{PREFIX}{INLINE_BASE}-0\" alt=\"a > b\"><img src=\"/x\">");
        assert_eq!(
            sized(&body, PREFIX, &size),
            format!(
                "<p>x</p><img src=\"{PREFIX}{INLINE_BASE}-0\" alt=\"a > b\" width=\"600\" height=\"200\"><img src=\"/x\">"
            )
        );
        // one side given: the other by the picture's proportions
        let body = format!("<img width=\"300\" src=\"{PREFIX}{INLINE_BASE}-0\">");
        assert!(sized(&body, PREFIX, &size).ends_with("height=\"100\">"));
        let body = format!("<img src=\"{PREFIX}{INLINE_BASE}-0\" height=\"50px\">");
        assert!(sized(&body, PREFIX, &size).ends_with("height=\"50px\" width=\"150\">"));
        // both, or a side that is no number of pixels: as it is
        for body in [
            format!("<img src=\"{PREFIX}{INLINE_BASE}-0\" width=\"10\" height=\"10\">"),
            format!("<img src=\"{PREFIX}{INLINE_BASE}-0\" width=\"100%\">"),
            // its size not known in time
            format!("<img src=\"{PREFIX}{}-0\">", INLINE_BASE + 1),
        ] {
            assert_eq!(sized(&body, PREFIX, &size), body);
        }
    }

    /// A style element's text is not markup: an `img` written in it is left as it is, and so is what follows it
    #[test]
    fn style_text_is_not_sized() {
        let body = format!(
            "<style>p::after{{content:\"<img src=\\\"{PREFIX}{INLINE_BASE}-0\\\" x=\\\"\"}}</style>\
             <img src=\"{PREFIX}{INLINE_BASE}-0\">"
        );
        let out = sized(&body, PREFIX, &size);
        assert!(out.starts_with(&body[..body.find("</style>").unwrap()]), "{out}");
        assert!(
            out.ends_with(&format!(
                "</style><img src=\"{PREFIX}{INLINE_BASE}-0\" width=\"600\" height=\"200\">"
            )),
            "{out}"
        );
    }

    #[test]
    fn the_router_numbers_each_picture_once_within_the_limits() {
        let png = InlineImage {
            content_id: "<a@x>",
            mime_type: "image/png",
            data: b"\x89PNG one",
        };
        let options = InlineOptions {
            token: "0123456789abcdef0123456789abcdef",
            first: INLINE_BASE + 10,
            size: &|_| None,
        };
        let router = Router::new(&[png], Some(&options));
        let first = format!("{PREFIX}{}-0", INLINE_BASE + 10);
        assert!(matches!(router.part("cid:A@X"), Route::To(address) if address == first));
        assert!(matches!(router.part("CID:%3Ca@x%3E"), Route::To(address) if address == first));
        assert!(matches!(router.part("cid:none@x"), Route::Keep));
        let second = format!("{PREFIX}{}-0", INLINE_BASE + 11);
        assert!(matches!(router.data("data:image/gif;base64,R0lGODlh"), Route::To(address) if address == second));
        assert!(matches!(router.data("data:image/gif;base64,R0lGODlh"), Route::To(address) if address == second));
        assert!(matches!(router.data("data:text/html,x"), Route::Drop));
        let (pictures, noted) = router.finish(&[png]);
        assert_eq!(pictures.len(), 2);
        assert_eq!(*pictures[0].bytes, b"\x89PNG one");
        assert_eq!(*pictures[1].bytes, b"GIF89a");
        assert_eq!(noted, HashSet::from(["a@x".to_string()]));

        // no addresses for the document: its pictures show nothing
        let router = Router::new(&[png], None);
        assert!(matches!(router.part("cid:a@x"), Route::Drop));
        assert!(router.finish(&[png]).0.is_empty());

        // past the count
        let router = Router::new(&[], Some(&options));
        for n in 0..MAX_INLINE {
            let url = format!(
                "data:image/png;base64,{}",
                base64::engine::general_purpose::STANDARD.encode(n.to_string())
            );
            assert!(matches!(router.data(&url), Route::To(_)));
        }
        assert!(matches!(router.data("data:image/png;base64,AAAA"), Route::Drop));
    }
}
