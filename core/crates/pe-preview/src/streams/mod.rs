//! What a PDF page would make hayro allocate, measured before it is drawn. hayro inflates a stream whole and keeps a
//! page's paths in memory, with no limit of its own: a 1 MB file can inflate to a gigabyte (the spike's
//! `hostile_flate_bomb_1g.pdf` took 1 GB), and running out of memory ends the app. So every stream a page reaches (its
//! content, the forms, pictures, fonts and patterns of its resources, its annotations' appearances) is measured
//! first: the compressing filters are run counting their output, never keeping it, and a picture counts as its width
//! by its height in RGBA. A page over [`MAX_STREAM`], [`MAX_CONTENT`] or, with the pages before it, [`MAX_DECODED`]
//! is not drawn.

use std::borrow::Cow;
use std::collections::HashSet;
use std::io::Read;

use hayro::hayro_syntax::Filter;
use hayro::hayro_syntax::object::{Array, Dict, MaybeRef, Name, ObjRef, Object, ObjectIdentifier, Stream};
use hayro::hayro_syntax::page::Page;
use hayro::hayro_syntax::xref::XRef;

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

impl Meter {
    /// Measures `page`: Err when drawing it would take too much
    pub(crate) fn page(&mut self, page: &Page<'_>) -> Result<(), Refusal> {
        let xref = page.xref();
        let mut content = 0u64;
        // the page's own content streams first, counted as content
        if let Some(contents) = page.raw().get::<Object<'_>>(b"Contents") {
            let streams: Vec<Stream<'_>> = match contents {
                Object::Stream(stream) => vec![stream],
                Object::Array(array) => array.iter::<Stream<'_>>().collect(),
                _ => Vec::new(),
            };
            for stream in &streams {
                content = content.saturating_add(self.stream(stream)?);
            }
        }
        if content > MAX_CONTENT {
            return Err(Refusal::TooLarge);
        }
        let mut stack: Vec<Object<'_>> = Vec::new();
        let mut objects = 0usize;
        self.entries(page.raw(), &mut stack, xref, true);
        while let Some(object) = stack.pop() {
            objects += 1;
            if objects > MAX_OBJECTS {
                return Err(Refusal::TooLarge);
            }
            match object {
                Object::Dict(dict) => self.entries(&dict, &mut stack, xref, false),
                Object::Array(array) => self.items(&array, &mut stack, xref),
                Object::Stream(stream) => {
                    self.stream(&stream)?;
                    self.entries(stream.dict(), &mut stack, xref, false);
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
        let size = decoded_size(stream, MAX_STREAM);
        if size > MAX_STREAM {
            return Err(Refusal::TooLarge);
        }
        if self.seen.insert((id.obj_number, id.gen_number)) || id.obj_number == 0 {
            self.decoded = self.decoded.saturating_add(size);
        }
        if self.decoded > MAX_DECODED {
            return Err(Refusal::TooLarge);
        }
        Ok(size)
    }

    /// The values of `dict` to follow: not the page tree (Parent, Kids), not another page (an annotation's P), and of
    /// a page tree node only its Resources, which a page inherits
    fn entries<'a>(&mut self, dict: &Dict<'a>, stack: &mut Vec<Object<'a>>, xref: &'a XRef, page: bool) {
        let pages_node = dict.get::<Name<'_>>(b"Type").is_some_and(|t| t.as_ref() == b"Pages");
        for (key, value) in dict.entries() {
            let key: &[u8] = key.as_ref();
            let follow = match key {
                // the page's own content streams were counted already
                b"Contents" => !page,
                b"Kids" | b"P" | b"Dest" | b"A" | b"Next" | b"Prev" | b"First" | b"Last" | b"Thumb" => false,
                b"Parent" | b"Resources" => true,
                _ => !pages_node,
            };
            if follow {
                self.push(value, stack, xref);
            }
        }
    }

    fn items<'a>(&mut self, array: &Array<'a>, stack: &mut Vec<Object<'a>>, xref: &'a XRef) {
        for value in array.raw_iter() {
            self.push(value, stack, xref);
        }
    }

    fn push<'a>(&mut self, value: MaybeRef<Object<'a>>, stack: &mut Vec<Object<'a>>, xref: &'a XRef) {
        match value {
            MaybeRef::Ref(reference) => {
                let ObjRef { obj_number, gen_number } = reference;
                // a stream is counted once by Self::stream; other objects are followed once
                if !self.seen.contains(&(obj_number, gen_number))
                    && let Some(object) = xref.get::<Object<'_>>(ObjectIdentifier::new(obj_number, gen_number))
                {
                    if !matches!(object, Object::Stream(_)) {
                        self.seen.insert((obj_number, gen_number));
                    }
                    stack.push(object);
                }
            }
            MaybeRef::NotRef(object) => {
                if matches!(object, Object::Dict(_) | Object::Array(_) | Object::Stream(_)) {
                    stack.push(object);
                }
            }
        }
    }
}

/// What `stream` inflates to, at most `cap` + 1: its filters run in turn, the last one only counted; a picture's
/// codec (JPEG, JPEG 2000, JBIG2, CCITT) counts as its width by its height in RGBA
pub(crate) fn decoded_size(stream: &Stream<'_>, cap: u64) -> u64 {
    let filters = stream.filters();
    let dict = stream.dict();
    let picture = picture_bytes(dict);
    let mut data: Cow<'_, [u8]> = stream.raw_data();
    for (index, filter) in filters.iter().enumerate() {
        let last = index + 1 == filters.len();
        let next = match filter {
            Filter::AsciiHexDecode => ascii_hex(&data),
            Filter::Ascii85Decode => ascii85(&data),
            Filter::FlateDecode | Filter::LzwDecode | Filter::RunLengthDecode => {
                let (size, kept) = expand(*filter, &data, dict, cap, !last);
                if last || size > cap {
                    return size.max(picture);
                }
                kept
            }
            Filter::DctDecode | Filter::JpxDecode | Filter::Jbig2Decode | Filter::CcittFaxDecode => {
                return picture.max(data.len() as u64);
            }
            Filter::Crypt => continue,
        };
        data = Cow::Owned(next);
    }
    (data.len() as u64).max(picture)
}

/// A picture's width by its height in RGBA, from its dictionary (0 for anything else)
fn picture_bytes(dict: &Dict<'_>) -> u64 {
    let is_image = dict.get::<Name<'_>>(b"Subtype").is_some_and(|s| s.as_ref() == b"Image");
    if !is_image {
        return 0;
    }
    let side = |key: &[u8], short: &[u8]| {
        dict.get::<f32>(key)
            .or_else(|| dict.get::<f32>(short))
            .filter(|n| n.is_finite() && *n > 0.0)
            .map_or(0, |n| n as u64)
    };
    side(b"Width", b"W")
        .saturating_mul(side(b"Height", b"H"))
        .saturating_mul(4)
}

/// Runs an expanding filter over `data`, counting its output up to `cap` + 1; its output too when `keep` (a filter
/// that another follows)
fn expand(filter: Filter, data: &[u8], dict: &Dict<'_>, cap: u64, keep: bool) -> (u64, Vec<u8>) {
    let mut count = 0u64;
    let mut kept = Vec::new();
    let mut take = |chunk: &[u8]| -> bool {
        count += chunk.len() as u64;
        if keep && count <= cap {
            kept.extend_from_slice(chunk);
        }
        count <= cap
    };
    match filter {
        Filter::FlateDecode => {
            // as hayro reads it: a zlib stream, else raw deflate
            if !inflate(flate2::read::ZlibDecoder::new(data), &mut take) {
                inflate(flate2::read::DeflateDecoder::new(data), &mut take);
            }
        }
        Filter::LzwDecode => {
            let early = dict
                .get::<Dict<'_>>(b"DecodeParms")
                .and_then(|p| p.get::<f32>(b"EarlyChange"))
                .is_none_or(|e| e != 0.0);
            let mut decoder = if early {
                weezl::decode::Decoder::with_tiff_size_switch(weezl::BitOrder::Msb, 8)
            } else {
                weezl::decode::Decoder::new(weezl::BitOrder::Msb, 8)
            };
            let mut input = data;
            let mut buffer = vec![0u8; 64 * 1024];
            loop {
                let result = decoder.decode_bytes(input, &mut buffer);
                input = &input[result.consumed_in..];
                if !take(&buffer[..result.consumed_out]) {
                    break;
                }
                match result.status {
                    Ok(weezl::LzwStatus::Ok) if result.consumed_in > 0 || result.consumed_out > 0 => {}
                    _ => break,
                }
            }
        }
        Filter::RunLengthDecode => {
            let mut at = 0usize;
            let mut run = [0u8; 128];
            while let Some(&length) = data.get(at) {
                at += 1;
                let more = match length {
                    0..=127 => {
                        let end = (at + usize::from(length) + 1).min(data.len());
                        let more = take(&data[at..end]);
                        at = end;
                        more
                    }
                    128 => break,
                    _ => {
                        let Some(&byte) = data.get(at) else {
                            break;
                        };
                        at += 1;
                        let n = 257 - usize::from(length);
                        run[..n].fill(byte);
                        take(&run[..n])
                    }
                };
                if !more {
                    break;
                }
            }
        }
        _ => {
            take(data);
        }
    }
    (count, kept)
}

/// Reads what `reader` inflates to in pieces, handing each to `take` until it says stop; whether the stream was read
/// to its end without an error (a stopped one counts as read)
fn inflate(mut reader: impl Read, take: &mut impl FnMut(&[u8]) -> bool) -> bool {
    let mut buffer = vec![0u8; 64 * 1024];
    loop {
        match reader.read(&mut buffer) {
            Ok(0) => return true,
            Ok(n) => {
                if !take(&buffer[..n]) {
                    return true;
                }
            }
            Err(_) => return false,
        }
    }
}

fn ascii_hex(data: &[u8]) -> Vec<u8> {
    let mut out = Vec::with_capacity(data.len() / 2);
    let mut high: Option<u8> = None;
    for &byte in data {
        if byte == b'>' {
            break;
        }
        let Some(digit) = (byte as char).to_digit(16) else {
            continue;
        };
        match high.take() {
            Some(h) => out.push(h << 4 | digit as u8),
            None => high = Some(digit as u8),
        }
    }
    if let Some(h) = high {
        out.push(h << 4);
    }
    out
}

fn ascii85(data: &[u8]) -> Vec<u8> {
    let mut out = Vec::with_capacity(data.len() / 5 * 4 + 4);
    let mut group = [0u8; 5];
    let mut filled = 0usize;
    let data = data.strip_prefix(b"<~").unwrap_or(data);
    for &byte in data {
        match byte {
            b'~' => break,
            b'z' if filled == 0 => out.extend_from_slice(&[0; 4]),
            b'!'..=b'u' => {
                group[filled] = byte - b'!';
                filled += 1;
                if filled == 5 {
                    let value = group.iter().fold(0u64, |v, &d| v * 85 + u64::from(d));
                    out.extend_from_slice(&(value as u32).to_be_bytes());
                    filled = 0;
                }
            }
            _ => {}
        }
    }
    if filled > 1 {
        group[filled..].fill(84);
        let value = group.iter().fold(0u64, |v, &d| v * 85 + u64::from(d));
        out.extend_from_slice(&(value as u32).to_be_bytes()[..filled - 1]);
    }
    out
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn ascii_filters() {
        assert_eq!(ascii_hex(b"48 65 6c6C6f>"), b"Hello");
        assert_eq!(ascii_hex(b"7>"), [0x70]);
        assert_eq!(ascii85(b"<~87cURD]i,\"Ebo80~>"), b"Hello World!");
        assert_eq!(ascii85(b"z~>"), [0, 0, 0, 0]);
    }
}
