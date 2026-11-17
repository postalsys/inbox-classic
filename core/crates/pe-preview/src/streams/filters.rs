//! What one stream decodes to: its filters run in turn, the last one only counted, a picture's codec sized from its
//! own data ([`super::codecs`])

use std::borrow::Cow;

use hayro::hayro_syntax::Filter;
use hayro::hayro_syntax::object::{Array, Dict, Name, Object, Stream};

use super::{codecs, inflate};

/// What `stream` decodes to, at most `cap` + 1: what its filters write, and for a picture (`picture`, or a stream of
/// subtype Image) its pixels in RGBA by the larger of its dictionary's size and its codec's
pub(crate) fn decoded_size(stream: &Stream<'_>, cap: u64, picture: bool) -> u64 {
    let dict = stream.dict();
    let picture = picture || dict.get::<Name<'_>>(b"Subtype").is_some_and(|s| s.as_ref() == b"Image");
    let declared = if picture { declared_pixels(dict) } else { (0, 0) };
    let filters = stream.filters();
    let mut data: Cow<'_, [u8]> = stream.raw_data();
    for (index, filter) in filters.iter().enumerate() {
        let last = index + 1 == filters.len();
        let next = match filter {
            Filter::AsciiHexDecode => ascii_hex(&data),
            Filter::Ascii85Decode => ascii85(&data),
            Filter::FlateDecode | Filter::LzwDecode | Filter::RunLengthDecode => {
                let (size, kept) = match filter {
                    Filter::FlateDecode => inflate::count(&data, cap, !last),
                    Filter::LzwDecode => count_lzw(&data, &params(dict, index), cap, !last),
                    _ => count_run_length(&data, cap, !last),
                };
                if last || size > cap {
                    return size.max(rgba(declared, (0, 0), 4));
                }
                kept
            }
            Filter::DctDecode => return rgba(declared, (0, 0), 4).max(data.len() as u64),
            Filter::CcittFaxDecode => {
                let params = params(dict, index);
                let number = |key: &[u8], default: u64| {
                    params
                        .get::<f32>(key)
                        .filter(|n| n.is_finite() && *n > 0.0)
                        .map_or(default, |n| n as u64)
                };
                return rgba(declared, (number(b"Columns", 1728), number(b"Rows", 0)), 4);
            }
            Filter::JpxDecode => {
                return match codecs::jpx(&data) {
                    Some((width, height, components)) => rgba(declared, (width, height), components.max(4)),
                    None => cap + 1,
                };
            }
            Filter::Jbig2Decode => {
                let page = codecs::jbig2(&data).unwrap_or((0, 0));
                return rgba(declared, page, 4);
            }
            Filter::Crypt => continue,
        };
        data = Cow::Owned(next);
    }
    (data.len() as u64).max(rgba(declared, (0, 0), 4))
}

/// The bytes of a picture of the larger of two sizes, `channels` bytes a pixel
fn rgba((width, height): (u64, u64), (codec_width, codec_height): (u64, u64), channels: u64) -> u64 {
    width
        .max(codec_width)
        .saturating_mul(height.max(codec_height))
        .saturating_mul(channels)
}

/// A picture's width and height as its dictionary says (W and H in an inline image)
fn declared_pixels(dict: &Dict<'_>) -> (u64, u64) {
    let side = |key: &[u8], short: &[u8]| {
        dict.get::<f32>(key)
            .or_else(|| dict.get::<f32>(short))
            .filter(|n| n.is_finite() && *n > 0.0)
            .map_or(0, |n| n as u64)
    };
    (side(b"Width", b"W"), side(b"Height", b"H"))
}

/// The parameters of filter `index` (DecodeParms, DP in an inline image: a dictionary, or an array of them)
fn params<'a>(dict: &Dict<'a>, index: usize) -> Dict<'a> {
    let get = |key: &[u8]| dict.get::<Object<'_>>(key);
    match get(b"DecodeParms").or_else(|| get(b"DP")) {
        Some(Object::Dict(params)) if index == 0 => params,
        Some(Object::Array(array)) => nth_dict(&array, index).unwrap_or_default(),
        _ => Dict::default(),
    }
}

fn nth_dict<'a>(array: &Array<'a>, index: usize) -> Option<Dict<'a>> {
    array.iter::<Object<'_>>().nth(index)?.into_dict()
}

/// Calls `take` with the decoded bytes; counts them, keeps them when `keep`, and says whether to go on (under `cap`)
struct Counter {
    count: u64,
    kept: Vec<u8>,
    keep: bool,
    cap: u64,
}

impl Counter {
    fn new(cap: u64, keep: bool) -> Counter {
        Counter {
            count: 0,
            kept: Vec::new(),
            keep,
            cap,
        }
    }

    fn take(&mut self, chunk: &[u8]) -> bool {
        self.count += chunk.len() as u64;
        if self.keep && self.count <= self.cap {
            self.kept.extend_from_slice(chunk);
        }
        self.count <= self.cap
    }

    fn done(self) -> (u64, Vec<u8>) {
        (self.count, self.kept)
    }
}

/// What an LZW stream decodes to (EarlyChange as its parameters say, 1 when they do not)
fn count_lzw(data: &[u8], params: &Dict<'_>, cap: u64, keep: bool) -> (u64, Vec<u8>) {
    let early = params.get::<f32>(b"EarlyChange").is_none_or(|e| e != 0.0);
    let mut decoder = if early {
        weezl::decode::Decoder::with_tiff_size_switch(weezl::BitOrder::Msb, 8)
    } else {
        weezl::decode::Decoder::new(weezl::BitOrder::Msb, 8)
    };
    let mut counter = Counter::new(cap, keep);
    let mut input = data;
    let mut buffer = vec![0u8; 64 * 1024];
    loop {
        let result = decoder.decode_bytes(input, &mut buffer);
        input = &input[result.consumed_in..];
        if !counter.take(&buffer[..result.consumed_out]) {
            break;
        }
        match result.status {
            Ok(weezl::LzwStatus::Ok) if result.consumed_in > 0 || result.consumed_out > 0 => {}
            _ => break,
        }
    }
    counter.done()
}

/// What a RunLength stream decodes to
fn count_run_length(data: &[u8], cap: u64, keep: bool) -> (u64, Vec<u8>) {
    let mut counter = Counter::new(cap, keep);
    let mut at = 0usize;
    let mut run = [0u8; 128];
    while let Some(&length) = data.get(at) {
        at += 1;
        let more = match length {
            0..=127 => {
                let end = (at + usize::from(length) + 1).min(data.len());
                let more = counter.take(&data[at..end]);
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
                counter.take(&run[..n])
            }
        };
        if !more {
            break;
        }
    }
    counter.done()
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

    #[test]
    fn run_length_counts_runs() {
        // 3 literal bytes, then 128 copies of x (code 129), then the end
        let data = [2, b'a', b'b', b'c', 128 + 1, b'x', 128];
        assert_eq!(
            count_run_length(&data, 1000, true),
            (3 + 128, [b"abc".as_slice(), &[b'x'; 128]].concat())
        );
        assert_eq!(count_run_length(&[129, 0].repeat(10_000), 1000, false).0, 1024);
    }
}
