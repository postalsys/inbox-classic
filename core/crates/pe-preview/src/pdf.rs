//! A PDF file to its description (page count, title) and the pictures of its first pages, with hayro: Rust, no
//! system font read (the standard 14 fonts and the predefined CMaps are built in), no script, link, action or
//! external reference followed, a page's appearance streams of form fields and notes drawn as the page shows them.
//!
//! hayro has no limits or cancel of its own: the page size is bounded here ([`page_size`]), the time and memory by
//! the render thread ([`crate::Previewer`]).

use std::cell::RefCell;
use std::sync::Arc;

use hayro::hayro_interpret::util::TransformExt;
use hayro::hayro_interpret::{InterpreterSettings, RenderContent};
use hayro::hayro_syntax::{LoadPdfError, Pdf};
use hayro::kurbo::Affine;
use hayro::vello_cpu::color::palette::css::WHITE;
use hayro::vello_cpu::{Pixmap, RasterizerSettings, RenderContext, Resources, TargetInit};
use hayro::{RenderCache, RenderSettings};

use crate::limits::{MAX_FILE, MAX_PAGE_RATIO, MAX_PAGES, MAX_SIDE, MAX_TITLE, PAGE_WIDTH};
use crate::streams::Meter;
use crate::{Description, Kind, Picture, Refusal};

/// Whether `bytes` are a PDF file: `%PDF-` in their first kilobyte, where readers look for it
pub fn is_pdf(bytes: &[u8]) -> bool {
    let start = &bytes[..bytes.len().min(1024)];
    start.windows(5).any(|w| w == b"%PDF-")
}

/// A PDF file read, its pages to be drawn
pub struct Document {
    pdf: Pdf,
}

impl Document {
    /// Reads `bytes` (a broken cross-reference table is rebuilt). A file that wants a password is refused; one
    /// encrypted with an empty user password (printing allowed, no password to open) is read
    pub fn open(bytes: Arc<Vec<u8>>) -> Result<Document, Refusal> {
        if bytes.len() > MAX_FILE {
            return Err(Refusal::TooLarge);
        }
        if !is_pdf(&bytes) {
            return Err(Refusal::Unsupported);
        }
        match Pdf::new(bytes) {
            // a file without a page hayro can read (a page tree of nothing, or of pages of no size)
            Ok(pdf) if pdf.pages().is_empty() => Err(Refusal::Unreadable),
            Ok(pdf) => Ok(Document { pdf }),
            Err(LoadPdfError::Decryption(_)) => Err(Refusal::Password),
            Err(LoadPdfError::Invalid) => Err(Refusal::Unreadable),
        }
    }

    pub fn describe(&self) -> Description {
        let pages = self.pdf.pages();
        Description {
            kind: Kind::Pdf,
            pages: pages.len(),
            title: self.pdf.metadata().title.as_deref().and_then(text_string),
            sizes: pages
                .iter()
                .take(MAX_PAGES)
                .map(|page| {
                    let (width, height) = page.render_dimensions();
                    page_size(width, height).map(|(w, h, _)| (w, h))
                })
                .collect(),
        }
    }

    /// The pages drawn one after another, sharing what they can (fonts, glyphs)
    pub fn pages(&self) -> Pages<'_> {
        Pages {
            document: self,
            meter: RefCell::new(Meter::default()),
            cache: RenderCache::new(),
            settings: InterpreterSettings {
                render_content: RenderContent::PAGE | RenderContent::ANNOTATIONS,
                ..InterpreterSettings::default()
            },
        }
    }
}

/// Draws the pages of a [`Document`]
pub struct Pages<'a> {
    document: &'a Document,
    /// What the pages drawn so far would make hayro allocate
    meter: RefCell<Meter>,
    cache: RenderCache<'a>,
    settings: InterpreterSettings,
}

impl Pages<'_> {
    /// Page `index` (from 0) drawn on white at [`page_size`], as a PNG (or a JPEG for a scan, [`crate::encode`])
    pub fn render(&self, index: usize) -> Result<Picture, Refusal> {
        let page = self.document.pdf.pages().get(index).ok_or(Refusal::Unreadable)?;
        let (width, height) = page.render_dimensions();
        let (width, height, scale) = page_size(width, height).ok_or(Refusal::TooLarge)?;
        self.meter.borrow_mut().page(page)?;
        let mut context = RenderContext::new(width as u16, height as u16);
        let transform = Affine::scale(scale) * page.initial_transform(true).to_kurbo();
        hayro::render_into(
            page,
            &self.cache,
            &self.settings,
            &RenderSettings::default(),
            &mut context,
            transform,
        );
        context.flush();
        let mut pixmap = Pixmap::new(context.width(), context.height());
        context.render_with(
            &mut pixmap,
            &mut Resources::default(),
            RasterizerSettings {
                target_init: TargetInit::Clear(WHITE),
                ..Default::default()
            },
        );
        // drawn over opaque white: every pixel is opaque, so the premultiplied values are the colors
        let rgba = pixmap.data_as_u8_slice();
        let mut rgb = Vec::with_capacity(rgba.len() / 4 * 3);
        for pixel in rgba.as_chunks::<4>().0 {
            rgb.extend_from_slice(&pixel[..3]);
        }
        crate::encode::page(&rgb, width, height)
    }
}

/// The preview size of a page of `width` by `height` points (as shown, rotation applied) and the scale from points:
/// [`PAGE_WIDTH`] wide, unless that makes its longest side over [`MAX_SIDE`]; a page taller than [`MAX_PAGE_RATIO`]
/// times its width shows its top part. None for a page of no size, or of sizes that are not numbers
pub fn page_size(width: f32, height: f32) -> Option<(u32, u32, f64)> {
    let (width, height) = (f64::from(width), f64::from(height));
    if !(width.is_finite() && height.is_finite() && width > 0.0 && height > 0.0) {
        return None;
    }
    let shown = height.min(width * MAX_PAGE_RATIO);
    let scale = (f64::from(PAGE_WIDTH) / width).min(f64::from(MAX_SIDE) / width.max(shown));
    let side = |points: f64| ((points * scale).round() as u32).clamp(1, MAX_SIDE);
    Some((side(width), side(shown), scale))
}

/// A PDF text string as text: UTF-16 with its byte order mark, UTF-8 with its mark (PDF 2.0), or PDFDocEncoding
/// (Latin-1 for what titles use); control characters dropped, at most [`MAX_TITLE`] characters. None when empty
fn text_string(bytes: &[u8]) -> Option<String> {
    let text: String = if let Some(utf16_be) = bytes.strip_prefix(b"\xfe\xff") {
        utf16(utf16_be, u16::from_be_bytes)
    } else if let Some(utf16_le) = bytes.strip_prefix(b"\xff\xfe") {
        utf16(utf16_le, u16::from_le_bytes)
    } else if let Some(utf8) = bytes.strip_prefix(b"\xef\xbb\xbf") {
        String::from_utf8_lossy(utf8).into_owned()
    } else {
        bytes.iter().map(|&b| char::from(b)).collect()
    };
    let text: String = text
        .chars()
        .map(|c| if c.is_control() { ' ' } else { c })
        .filter(|&c| !pe_mime::parser::is_direction_mark(c))
        .take(MAX_TITLE)
        .collect();
    let text = text.split_whitespace().collect::<Vec<_>>().join(" ");
    (!text.is_empty()).then_some(text)
}

/// UTF-16 in the byte order `unit` reads, a broken pair as the replacement character
fn utf16(bytes: &[u8], unit: fn([u8; 2]) -> u16) -> String {
    char::decode_utf16(bytes.as_chunks::<2>().0.iter().map(|&pair| unit(pair)))
        .map(|c| c.unwrap_or('\u{fffd}'))
        .collect()
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn page_sizes() {
        // A4 and US Letter: the page width
        assert_eq!(page_size(595.0, 842.0).map(|(w, h, _)| (w, h)), Some((1240, 1755)));
        assert_eq!(page_size(612.0, 792.0).map(|(w, h, _)| (w, h)), Some((1240, 1605)));
        // landscape A4
        assert_eq!(page_size(842.0, 595.0).map(|(w, h, _)| (w, h)), Some((1240, 876)));
        // A3 portrait: the same width
        assert_eq!(page_size(842.0, 1191.0).map(|(w, h, _)| (w, h)), Some((1240, 1754)));
        // a square-ish page taller than the longest side lets the page width be
        assert_eq!(page_size(600.0, 1200.0).map(|(w, h, _)| (w, h)), Some((1024, 2048)));
        // a receipt roll: its top four widths
        assert_eq!(page_size(200.0, 3000.0).map(|(w, h, _)| (w, h)), Some((512, 2048)));
        // a thread of a page, and a page of nothing
        assert_eq!(page_size(1.0, 10_000.0).map(|(w, h, _)| (w, h)), Some((512, 2048)));
        assert_eq!(page_size(10_000.0, 1.0).map(|(w, h, _)| (w, h)), Some((1240, 1)));
        assert_eq!(
            page_size(f32::MAX, f32::MAX).map(|(w, h, _)| (w, h)),
            Some((1240, 1240))
        );
        assert_eq!(page_size(0.0, 100.0), None);
        assert_eq!(page_size(f32::NAN, 100.0), None);
        assert_eq!(page_size(f32::INFINITY, 100.0), None);
        assert_eq!(page_size(-5.0, 100.0), None);
    }

    #[test]
    fn titles() {
        assert_eq!(text_string(b"Invoice 2026-114").as_deref(), Some("Invoice 2026-114"));
        assert_eq!(text_string(b"\xfe\xff\0R\0\xe4\0k").as_deref(), Some("Räk"));
        assert_eq!(text_string(b"\xff\xfeO\0K\0").as_deref(), Some("OK"));
        assert_eq!(text_string("\u{feff}Ünï".as_bytes()).as_deref(), Some("Ünï"));
        assert_eq!(text_string(b"a\x00\x07b\r\nc").as_deref(), Some("a b c"));
        let bidi: Vec<u8> = [0xfe, 0xff]
            .into_iter()
            .chain("x\u{202e}gpj.exe".encode_utf16().flat_map(u16::to_be_bytes))
            .collect();
        assert_eq!(text_string(&bidi).as_deref(), Some("xgpj.exe"));
        assert_eq!(text_string(b"   "), None);
        let long = "x".repeat(1000);
        assert_eq!(text_string(long.as_bytes()).unwrap().chars().count(), MAX_TITLE);
    }

    #[test]
    fn only_a_pdf_is_a_pdf() {
        assert!(is_pdf(b"%PDF-1.7\n"));
        assert!(is_pdf(b"\xef\xbb\xbf  junk %PDF-1.4"));
        assert!(!is_pdf(b"<html><body>"));
        let mut late = vec![b' '; 2000];
        late.extend(b"%PDF-1.4");
        assert!(!is_pdf(&late));
        assert!(matches!(
            Document::open(Arc::new(b"<html>".to_vec())),
            Err(Refusal::Unsupported)
        ));
    }
}
