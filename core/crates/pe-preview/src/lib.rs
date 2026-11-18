//! Previews of attachments (docs/attachment-preview-plan.md): a picture or the first pages of a PDF file drawn in
//! Rust and encoded again as the core's own PNG or JPEG, so a web view never decodes the bytes a sender wrote.
//!
//! - [`picture`] reads JPEG, PNG, GIF (its first frame), WebP, BMP, ICO and TIFF with the `image` crate under its
//!   [`image::Limits`], turns the picture upright as its EXIF says, scales it to at most [`limits::MAX_SIDE`] pixels
//!   and writes it without its EXIF (its ICC profile kept).
//! - [`pdf`] reads a PDF file with hayro (Rust, its own crates without unsafe code): the page count and title, and
//!   the first [`limits::MAX_PAGES`] pages drawn on white, each measured first ([`streams`]) so that a bomb is not
//!   inflated.
//! - [`Previewer`] runs them on a render thread of its own, one file at a time, never on a window thread or the
//!   core's async threads. hayro has no limits or cancel of its own: a watchdog abandons a render that runs over its
//!   time ([`limits::PAGE_TIME`], [`limits::PICTURE_TIME`]) and starts a new thread; a crash marker written before
//!   each file and removed after names the file that ended the app (running out of memory ends the process, no
//!   thread can catch it), and that file is never drawn again. The previews are kept in memory only
//!   ([`limits::CACHE_BYTES`]).
#![forbid(unsafe_code)]

pub mod cache;
mod encode;
mod engine;
pub mod limits;
pub mod marker;
pub mod pdf;
pub mod picture;
mod service;
pub mod streams;

pub use engine::{Engine, Real, Step};
pub use service::{Outcome, Previewer, Request, Settings, What};

use std::sync::Arc;

/// The type of a preview's bytes: only these two ever reach a web view
#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash)]
pub enum Mime {
    Png,
    Jpeg,
}

impl Mime {
    /// The Content-Type a document server answers with
    pub fn as_str(self) -> &'static str {
        match self {
            Mime::Png => "image/png",
            Mime::Jpeg => "image/jpeg",
        }
    }
}

/// A preview as the core encoded it
#[derive(Clone, PartialEq, Eq)]
pub struct Picture {
    pub mime: Mime,
    pub bytes: Vec<u8>,
    pub width: u32,
    pub height: u32,
}

impl std::fmt::Debug for Picture {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        write!(
            f,
            "Picture({:?}, {}x{}, {} bytes)",
            self.mime,
            self.width,
            self.height,
            self.bytes.len()
        )
    }
}

/// What a file is, by its content (never its name or declared type)
#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash)]
pub enum Kind {
    Picture,
    Pdf,
}

/// The kind of `bytes` when they are a picture or PDF file that may get a preview, by their content: a `.jpg` that is
/// a PNG is a picture, a `.pdf` that is HTML is nothing. HEIC, AVIF, SVG and the rest are None (a tile)
pub fn kind_of(bytes: &[u8]) -> Option<Kind> {
    if pdf::is_pdf(bytes) {
        return Some(Kind::Pdf);
    }
    picture::format_of(bytes).map(|_| Kind::Picture)
}

/// The picture formats this crate knows but does not draw (docs/attachment-preview-plan.md, decision 3): their name
/// for the tile that stands for such a picture, by its content
#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash)]
pub enum NotDrawn {
    Heic,
    Avif,
    JpegXl,
}

impl NotDrawn {
    /// The format's name, the same in every language
    pub fn name(self) -> &'static str {
        match self {
            NotDrawn::Heic => "HEIC",
            NotDrawn::Avif => "AVIF",
            NotDrawn::JpegXl => "JPEG XL",
        }
    }
}

/// HEIC, AVIF or JPEG XL by the start of `bytes`: an ISO media file's `ftyp` box naming the brand (AVIF before the
/// HEIF brands, which an AVIF file names too), or JPEG XL's signature. None for anything else
pub fn not_drawn(bytes: &[u8]) -> Option<NotDrawn> {
    const JXL_BOX: &[u8] = b"\0\0\0\x0cJXL \r\n\x87\n";
    if bytes.starts_with(&[0xff, 0x0a]) || bytes.starts_with(JXL_BOX) {
        return Some(NotDrawn::JpegXl);
    }
    if bytes.get(4..8) != Some(b"ftyp") {
        return None;
    }
    let size = u32::from_be_bytes(bytes.get(..4)?.try_into().ok()?) as usize;
    let header = bytes.get(8..size.clamp(16, 256).min(bytes.len()))?;
    // the major brand, then (after the minor version) the compatible brands
    let compatible = header.get(8..).unwrap_or_default().as_chunks::<4>().0;
    let brands: Vec<&[u8]> = std::iter::once(header.get(..4)?)
        .chain(compatible.iter().map(|brand| brand.as_slice()))
        .collect();
    let named = |names: &[&[u8]]| brands.iter().any(|brand| names.contains(brand));
    if named(&[b"avif", b"avis"]) {
        return Some(NotDrawn::Avif);
    }
    let heif: &[&[u8]] = &[
        b"heic", b"heix", b"hevc", b"hevx", b"heim", b"heis", b"hevm", b"hevs", b"mif1", b"msf1",
    ];
    named(heif).then_some(NotDrawn::Heic)
}

/// What the reading pane says of a file before its previews are drawn, read from a picture's header or a PDF's page
/// tree
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct Description {
    pub kind: Kind,
    /// A PDF's pages, all of them; 1 for a picture
    pub pages: usize,
    /// A PDF's title (its Info's Title), when it has one
    pub title: Option<String>,
    /// The size of each preview drawn (a picture's one, a PDF's first [`limits::MAX_PAGES`] pages); None for a page
    /// that is not drawn (of no size, or of sizes that are not numbers)
    pub sizes: Vec<Option<(u32, u32)>>,
}

/// Why a file, or a page of it, has no preview: the reading pane shows a tile instead
#[derive(Debug, Clone, PartialEq, Eq)]
pub enum Refusal {
    /// Not a picture or PDF file this crate reads (HEIC, AVIF, SVG, anything else)
    Unsupported,
    /// Over a limit before anything was decoded: the file's size, a picture's sides or pixels, a page's size
    TooLarge,
    /// The message's previews already used [`limits::MESSAGE_PIXELS`]
    OverBudget,
    /// A PDF file that wants a password to open
    Password,
    /// Broken, or refused by the decoder
    Unreadable,
    /// Its render ran over its time and was abandoned
    TimedOut,
    /// It ended the app once (a crash marker was left behind), or hung before: never drawn again
    Crashed,
    /// Previews of this kind are off for the rest of the session: a PDF hung before
    Off,
    /// PDF files are not drawn: the user's setting, turned off by the core after a PDF file ended the app
    Disabled,
}

/// The key of a file: SHA-256 of its bytes, as hex
pub fn key_of(bytes: &[u8]) -> Key {
    use sha2::Digest;
    use std::fmt::Write;
    let digest = sha2::Sha256::digest(bytes);
    let mut hex = String::with_capacity(64);
    for byte in digest {
        let _ = write!(hex, "{byte:02x}");
    }
    Key(Arc::from(hex))
}

/// A file's key ([`key_of`])
#[derive(Debug, Clone, PartialEq, Eq, Hash, PartialOrd, Ord)]
pub struct Key(Arc<str>);

impl Key {
    pub fn as_str(&self) -> &str {
        &self.0
    }

    /// A key read back from a marker or the refused list: 64 hex digits, nothing else
    pub fn parse(text: &str) -> Option<Key> {
        let text = text.trim();
        (text.len() == 64 && text.bytes().all(|b| b.is_ascii_hexdigit() && !b.is_ascii_uppercase()))
            .then(|| Key(Arc::from(text)))
    }
}
