//! What a PDF page would make hayro allocate, measured before it is drawn. hayro inflates a stream whole and keeps a
//! page's paths in memory, with no limit of its own: a 1 MB file can inflate to a gigabyte (the spike's
//! `hostile_flate_bomb_1g.pdf` took 1 GB), and running out of memory ends the app. So every stream a page reaches (its
//! content, the forms, pictures, fonts and patterns of its resources, its annotations' appearances) is measured
//! first, and every inline picture (BI ... ID ... EI) in the content streams among them: the compressing filters run
//! counting their output, never keeping it, as hayro would read them ([`inflate`]), and a picture counts as its pixels
//! in RGBA by the larger of its dictionary's size and its codec's ([`codecs`]). A page over [`MAX_STREAM`],
//! [`MAX_CONTENT`] or, with the pages before it, [`MAX_DECODED`] is not drawn.

mod codecs;
mod filters;
mod inflate;

use std::collections::HashSet;

use hayro::hayro_syntax::content::TypedIter;
use hayro::hayro_syntax::content::ops::TypedInstruction;
use hayro::hayro_syntax::object::{Array, Dict, MaybeRef, Name, ObjRef, Object, ObjectIdentifier, Stream};
use hayro::hayro_syntax::page::Page;
use hayro::hayro_syntax::xref::XRef;

pub(crate) use filters::decoded_size;

use crate::Refusal;

/// The most a stream may inflate to, or a picture take as RGBA
pub const MAX_STREAM: u64 = 160 * 1024 * 1024;

/// The most the content streams of one page may inflate to: hayro keeps every path of a page until it is drawn
/// (about 50 bytes of memory for each byte of path in the spike), so a 20 MB content stream of lines took 1 GB
pub const MAX_CONTENT: u64 = 8 * 1024 * 1024;

/// The most all the streams of the pages drawn of a file may inflate to together (each counted once)
pub const MAX_DECODED: u64 = 384 * 1024 * 1024;

/// The most objects followed from a page
pub const MAX_OBJECTS: usize = 100_000;

/// Measures the pages of one file in turn: what they share (fonts, pictures) counts once
#[derive(Default)]
pub(crate) struct Meter {
    seen: HashSet<(u32, i32)>,
    decoded: u64,
}

/// An object to measure, and whether a stream reached through it is a content stream (whose operators may hold
/// inline pictures): the page's own, a form's, a tiling pattern's, a Type 3 glyph's, an annotation's appearance
struct Reached<'a> {
    object: Object<'a>,
    content: bool,
}

impl Meter {
    /// Measures `page`: Err when drawing it would take too much
    pub(crate) fn page(&mut self, page: &Page<'_>) -> Result<(), Refusal> {
        let xref = page.xref();
        let mut stack: Vec<Reached<'_>> = Vec::new();
        // the page's own content streams first, counted as content
        let mut content = 0u64;
        if let Some(contents) = page.raw().get::<Object<'_>>(b"Contents") {
            let streams: Vec<Stream<'_>> = match contents {
                Object::Stream(stream) => vec![stream],
                Object::Array(array) => array.iter::<Stream<'_>>().collect(),
                _ => Vec::new(),
            };
            for stream in &streams {
                content = content.saturating_add(self.stream(stream)?);
            }
            if content > MAX_CONTENT {
                return Err(Refusal::TooLarge);
            }
            for stream in &streams {
                self.inline_pictures(stream)?;
            }
        }
        self.entries(page.raw(), &mut stack, xref, true, false);
        let mut objects = 0usize;
        while let Some(Reached { object, content }) = stack.pop() {
            objects += 1;
            if objects > MAX_OBJECTS {
                return Err(Refusal::TooLarge);
            }
            match object {
                Object::Dict(dict) => self.entries(&dict, &mut stack, xref, false, content),
                Object::Array(array) => self.items(&array, &mut stack, xref, content),
                Object::Stream(stream) => {
                    self.stream(&stream)?;
                    if content || is_content(stream.dict()) {
                        self.inline_pictures(&stream)?;
                    }
                    self.entries(stream.dict(), &mut stack, xref, false, false);
                }
                _ => {}
            }
        }
        Ok(())
    }

    /// Counts `stream` once (by its object number): Err when it is over [`MAX_STREAM`] or the file over
    /// [`MAX_DECODED`]; the size it inflates to otherwise
    fn stream(&mut self, stream: &Stream<'_>) -> Result<u64, Refusal> {
        let id = stream.obj_id();
        let size = decoded_size(stream, MAX_STREAM, false);
        let new = self.seen.insert((id.obj_number, id.gen_number)) || id.obj_number == 0;
        self.count(size, new)?;
        Ok(size)
    }

    fn count(&mut self, size: u64, new: bool) -> Result<(), Refusal> {
        if size > MAX_STREAM {
            return Err(Refusal::TooLarge);
        }
        if new {
            self.decoded = self.decoded.saturating_add(size);
        }
        if self.decoded > MAX_DECODED {
            return Err(Refusal::TooLarge);
        }
        Ok(())
    }

    /// Measures the inline pictures of a content stream (already measured itself, so decoding it is bounded): hayro
    /// decodes each with all its filters
    fn inline_pictures(&mut self, stream: &Stream<'_>) -> Result<(), Refusal> {
        let Ok(data) = stream.decoded() else {
            return Ok(());
        };
        let mut operators = TypedIter::new(&data);
        while let Some(operator) = operators.next() {
            if let TypedInstruction::InlineImage(picture) = operator {
                self.count(decoded_size(picture.0, MAX_STREAM, true), true)?;
            }
        }
        Ok(())
    }

    /// The values of `dict` to follow: not the page tree (Parent, Kids), not another page (an annotation's P), and of
    /// a page tree node only its Resources, which a page inherits. What a Type 3 font's glyphs (CharProcs) and an
    /// annotation's appearances (AP) hold are content streams, as is what a `content` dictionary holds
    fn entries<'a>(
        &mut self,
        dict: &Dict<'a>,
        stack: &mut Vec<Reached<'a>>,
        xref: &'a XRef,
        page: bool,
        content: bool,
    ) {
        let pages_node = dict.get::<Name<'_>>(b"Type").is_some_and(|t| t.as_ref() == b"Pages");
        for (key, value) in dict.entries() {
            let key: &[u8] = key.as_ref();
            let follow = match key {
                // the page's own content streams were measured already
                b"Contents" => !page,
                b"Kids" | b"P" | b"Dest" | b"A" | b"Next" | b"Prev" | b"First" | b"Last" | b"Thumb" => false,
                b"Parent" | b"Resources" => true,
                _ => !pages_node,
            };
            if follow {
                let content = content || matches!(key, b"CharProcs" | b"AP");
                self.push(value, stack, xref, content);
            }
        }
    }

    fn items<'a>(&mut self, array: &Array<'a>, stack: &mut Vec<Reached<'a>>, xref: &'a XRef, content: bool) {
        for value in array.raw_iter() {
            self.push(value, stack, xref, content);
        }
    }

    fn push<'a>(&mut self, value: MaybeRef<Object<'a>>, stack: &mut Vec<Reached<'a>>, xref: &'a XRef, content: bool) {
        let object = match value {
            MaybeRef::Ref(ObjRef { obj_number, gen_number }) => {
                // a stream is counted once by Self::stream; other objects are followed once
                if self.seen.contains(&(obj_number, gen_number)) {
                    return;
                }
                let Some(object) = xref.get::<Object<'_>>(ObjectIdentifier::new(obj_number, gen_number)) else {
                    return;
                };
                if !matches!(object, Object::Stream(_)) {
                    self.seen.insert((obj_number, gen_number));
                }
                object
            }
            MaybeRef::NotRef(object @ (Object::Dict(_) | Object::Array(_) | Object::Stream(_))) => object,
            MaybeRef::NotRef(_) => return,
        };
        stack.push(Reached { object, content });
    }
}

/// Whether a stream is a form or a tiling pattern, whose content hayro interprets
fn is_content(dict: &Dict<'_>) -> bool {
    dict.get::<Name<'_>>(b"Subtype").is_some_and(|s| s.as_ref() == b"Form")
        || dict.get::<f32>(b"PatternType") == Some(1.0)
}

#[cfg(test)]
pub(crate) mod tests {
    /// A raw deflate start that flate2 refuses and hayro's lenient decoder skips: a fixed block whose one code refers
    /// to before the start, then an empty stored block that ends on a byte boundary
    pub(crate) fn bad_reference_prefix() -> Vec<u8> {
        let mut bits: Vec<bool> = Vec::new();
        let mut put = |value: u32, count: u32, msb_first: bool| {
            for i in 0..count {
                let bit = if msb_first { count - 1 - i } else { i };
                bits.push(value >> bit & 1 == 1);
            }
        };
        // not final, fixed codes; length code 257 (7 bits 0000001), distance code 0 (5 bits), end of block (0000000)
        put(0, 1, false);
        put(1, 2, false);
        put(1, 7, true);
        put(0, 5, true);
        put(0, 7, true);
        // not final, stored
        put(0, 1, false);
        put(0, 2, false);
        let mut bytes: Vec<u8> = bits
            .chunks(8)
            .map(|chunk| {
                chunk
                    .iter()
                    .enumerate()
                    .fold(0u8, |b, (i, &bit)| b | (u8::from(bit) << i))
            })
            .collect();
        // the stored block's length and its complement
        bytes.extend([0, 0, 0xff, 0xff]);
        bytes
    }
}

#[cfg(test)]
mod parity {
    use std::io::Write;
    use std::sync::Arc;

    use hayro::hayro_syntax::Pdf;
    use hayro::hayro_syntax::object::Stream;

    use super::*;

    /// A one page PDF whose content stream is `data` with `filter`
    fn pdf(data: &[u8], filter: &str) -> Vec<u8> {
        let objects = [
            b"<< /Type /Catalog /Pages 2 0 R >>".to_vec(),
            b"<< /Type /Pages /Kids [3 0 R] /Count 1 >>".to_vec(),
            b"<< /Type /Page /Parent 2 0 R /MediaBox [0 0 100 100] /Contents 4 0 R >>".to_vec(),
            [
                format!("<< /Length {} /Filter /{filter} >>\nstream\n", data.len()).as_bytes(),
                data,
                b"\nendstream",
            ]
            .concat(),
        ];
        let mut out = b"%PDF-1.7\n".to_vec();
        let mut offsets = Vec::new();
        for (i, object) in objects.iter().enumerate() {
            offsets.push(out.len());
            writeln!(out, "{} 0 obj", i + 1).unwrap();
            out.extend(object);
            out.extend(b"\nendobj\n");
        }
        let xref = out.len();
        write!(out, "xref\n0 5\n0000000000 65535 f \n").unwrap();
        for offset in offsets {
            writeln!(out, "{offset:010} 00000 n ").unwrap();
        }
        write!(out, "trailer\n<< /Size 5 /Root 1 0 R >>\nstartxref\n{xref}\n%%EOF\n").unwrap();
        out
    }

    fn raw_deflate(data: &[u8]) -> Vec<u8> {
        let mut e = flate2::write::DeflateEncoder::new(Vec::new(), flate2::Compression::best());
        e.write_all(data).unwrap();
        e.finish().unwrap()
    }

    /// What hayro inflates the content stream to, and what the meter counts for it
    fn both(data: &[u8], filter: &str) -> (usize, u64) {
        let pdf = Pdf::new(Arc::new(pdf(data, filter))).unwrap();
        let page = &pdf.pages()[0];
        let hayro = page.page_stream().map_or(0, <[u8]>::len);
        let stream = page.raw().get::<Stream<'_>>(b"Contents").unwrap();
        (hayro, decoded_size(&stream, u64::MAX - 1, false))
    }

    #[test]
    fn the_meter_counts_what_hayro_inflates() {
        let text: Vec<u8> = (0..300_000u32)
            .map(|i| b"q 1 0 0 1 0 0 cm Q\n"[(i % 19) as usize])
            .collect();
        // ordinary zlib and raw deflate: what flate2 reads
        let mut zlib = flate2::write::ZlibEncoder::new(Vec::new(), flate2::Compression::best());
        zlib.write_all(&text).unwrap();
        let zlib = zlib.finish().unwrap();
        assert_eq!(both(&zlib, "FlateDecode"), (text.len(), text.len() as u64));
        assert_eq!(
            both(&raw_deflate(&text), "FlateDecode"),
            (text.len(), text.len() as u64)
        );
        // a reference to before the start: only hayro's lenient decoder reads it
        let lenient = [tests::bad_reference_prefix(), raw_deflate(&text)].concat();
        assert_eq!(both(&lenient, "FlateDecode"), (text.len(), text.len() as u64));
        // a bad checksum: flate2 fails at the end, the lenient decoder reads it all
        let mut bad_sum = zlib.clone();
        let end = bad_sum.len() - 1;
        bad_sum[end] ^= 0xff;
        let (hayro, counted) = both(&bad_sum, "FlateDecode");
        assert_eq!(counted, hayro as u64);
    }
}
