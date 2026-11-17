//! What a FlateDecode stream inflates to, as hayro reads it: flate2 on a zlib stream, else flate2 on raw deflate, and
//! when both fail its own lenient decoder (a port of pdf.js's), which skips back-references to before the start and
//! ignores stored lengths and the checksum. A stream only the lenient decoder reads would otherwise count as nothing
//! while hayro inflates it whole, so its semantics are ported here, counting the bytes it would write without keeping
//! them (hayro-syntax 0.9.0 `filter/lzw_flate.rs`, `fallback`, MIT or Apache-2.0).

use std::io::Read;

/// How a reading of a stream ended
enum Reading {
    /// To its end, without an error
    Ended,
    /// Stopped by the counter: over the cap
    Stopped,
    /// With an error: hayro then tries the next way
    Failed,
}

/// What `data` inflates to, at most `cap` + 1 counted; with the bytes when `keep` (a filter follows). A stream only the
/// lenient decoder reads is counted but not kept: a filter after it is refused (`cap` + 1)
pub(super) fn count(data: &[u8], cap: u64, keep: bool) -> (u64, Vec<u8>) {
    for zlib in [true, false] {
        let mut count = 0u64;
        let mut kept = Vec::new();
        let mut take = |chunk: &[u8]| {
            count += chunk.len() as u64;
            if keep && count <= cap {
                kept.extend_from_slice(chunk);
            }
            count <= cap
        };
        let read = if zlib {
            read_all(flate2::read::ZlibDecoder::new(data), &mut take)
        } else {
            read_all(flate2::read::DeflateDecoder::new(data), &mut take)
        };
        match read {
            Reading::Ended | Reading::Stopped => return (count, kept),
            Reading::Failed => {}
        }
    }
    if keep {
        return (cap + 1, Vec::new());
    }
    (lenient(data, cap), Vec::new())
}

/// Reads `reader` in pieces, handing each to `take` until it says stop
fn read_all(mut reader: impl Read, take: &mut impl FnMut(&[u8]) -> bool) -> Reading {
    let mut buffer = vec![0u8; 64 * 1024];
    loop {
        match reader.read(&mut buffer) {
            Ok(0) => return Reading::Ended,
            Ok(n) if !take(&buffer[..n]) => return Reading::Stopped,
            Ok(_) => {}
            Err(_) => return Reading::Failed,
        }
    }
}

/// What hayro's lenient decoder writes for `data`, at most `cap` + 1
pub(super) fn lenient(data: &[u8], cap: u64) -> u64 {
    let zlib = data.len() >= 2
        && data[0] & 0x0f == 0x08
        && (u16::from(data[0]) << 8 | u16::from(data[1])).is_multiple_of(31)
        && data[1] & 0x20 == 0;
    let mut stream = Lenient {
        data: if zlib { &data[2..] } else { data },
        pos: 0,
        code_buf: 0,
        code_size: 0,
        written: 0,
        cap,
        eof: false,
    };
    while !stream.eof && stream.pos < stream.data.len() && stream.written <= cap {
        stream.block();
    }
    stream.written
}

struct Lenient<'a> {
    data: &'a [u8],
    pos: usize,
    code_buf: u32,
    code_size: u8,
    /// The bytes written so far: only their count matters, as a back-reference copies only when its distance is
    /// within them
    written: u64,
    cap: u64,
    eof: bool,
}

struct Table {
    codes: Vec<u32>,
    max_len: u8,
}

impl Lenient<'_> {
    fn byte(&mut self) -> Option<u8> {
        let byte = *self.data.get(self.pos)?;
        self.pos += 1;
        Some(byte)
    }

    fn bits(&mut self, bits: u8) -> Option<u32> {
        while self.code_size < bits {
            let byte = self.byte()?;
            self.code_buf |= u32::from(byte) << self.code_size;
            self.code_size += 8;
        }
        let result = self.code_buf & ((1 << bits) - 1);
        self.code_buf >>= bits;
        self.code_size -= bits;
        Some(result)
    }

    fn code(&mut self, table: &Table) -> Option<u16> {
        while self.code_size < table.max_len {
            match self.byte() {
                Some(byte) => {
                    self.code_buf |= u32::from(byte) << self.code_size;
                    self.code_size += 8;
                }
                None => break,
            }
        }
        let code = *table.codes.get((self.code_buf & ((1 << table.max_len) - 1)) as usize)?;
        let length = (code >> 16) as u8;
        if length < 1 || self.code_size < length {
            return None;
        }
        self.code_buf >>= length;
        self.code_size -= length;
        Some((code & 0xffff) as u16)
    }

    fn block(&mut self) {
        let Some(header) = self.bits(3) else {
            self.eof = true;
            return;
        };
        if header & 1 != 0 {
            self.eof = true;
        }
        match header >> 1 {
            0 => self.stored(),
            1 => self.compressed(fixed_tables()),
            2 => match self.dynamic_tables() {
                Some(tables) => self.compressed(tables),
                None => self.eof = true,
            },
            _ => self.eof = true,
        }
    }

    fn stored(&mut self) {
        self.code_buf = 0;
        self.code_size = 0;
        let mut header = [0u8; 4];
        for byte in &mut header {
            match self.byte() {
                Some(b) => *byte = b,
                None => {
                    self.eof = true;
                    return;
                }
            }
        }
        // the length's check (its complement) is ignored
        let length = usize::from(u16::from_le_bytes([header[0], header[1]]));
        if length == 0 {
            if self.pos >= self.data.len() {
                self.eof = true;
            }
            return;
        }
        let end = (self.pos + length).min(self.data.len());
        self.written += (end - self.pos) as u64;
        if end - self.pos < length {
            self.eof = true;
        }
        self.pos = end;
    }

    fn compressed(&mut self, (literals, distances): (Table, Table)) {
        while self.written <= self.cap {
            let Some(code) = self.code(&literals) else {
                self.eof = true;
                return;
            };
            if code < 256 {
                self.written += 1;
                continue;
            }
            if code == 256 {
                return;
            }
            let info = LENGTH_DECODE.get(usize::from(code - 257)).copied().unwrap_or(0);
            let mut length = u64::from(info & 0xffff);
            let extra = (info >> 16) as u8;
            if extra > 0 {
                match self.bits(extra) {
                    Some(bits) => length += u64::from(bits),
                    None => {
                        self.eof = true;
                        return;
                    }
                }
            }
            let Some(info) = self
                .code(&distances)
                .and_then(|c| DIST_DECODE.get(usize::from(c)).copied())
            else {
                self.eof = true;
                return;
            };
            let mut distance = u64::from(info & 0xffff);
            let extra = (info >> 16) as u8;
            if extra > 0 {
                match self.bits(extra) {
                    Some(bits) => distance += u64::from(bits),
                    None => {
                        self.eof = true;
                        return;
                    }
                }
            }
            // a reference to before the start copies nothing (pdf.js skips it); any other copies `length` bytes
            if distance <= self.written {
                self.written += length;
            }
        }
    }

    fn dynamic_tables(&mut self) -> Option<(Table, Table)> {
        let literals = self.bits(5)? as usize + 257;
        let distances = self.bits(5)? as usize + 1;
        let lengths_codes = self.bits(4)? as usize + 4;
        let mut code_lengths = [0u8; 19];
        for &index in &CODE_LEN_CODE_MAP[..lengths_codes] {
            code_lengths[usize::from(index)] = self.bits(3)? as u8;
        }
        let code_table = table(&code_lengths);
        let total = literals + distances;
        let mut lengths = vec![0u8; total];
        let mut i = 0;
        while i < total {
            let (value, repeat) = match self.code(&code_table)? {
                code @ 0..=15 => (code as u8, 1),
                16 => (if i > 0 { lengths[i - 1] } else { 0 }, self.bits(2)? as usize + 3),
                17 => (0, self.bits(3)? as usize + 3),
                18 => (0, self.bits(7)? as usize + 11),
                _ => return None,
            };
            for _ in 0..repeat {
                if i < total {
                    lengths[i] = value;
                    i += 1;
                }
            }
        }
        Some((table(&lengths[..literals]), table(&lengths[literals..])))
    }
}

/// The table of a Huffman code of `lengths`, indexed by the code's bits reversed: (length << 16) | value
fn table(lengths: &[u8]) -> Table {
    let max_len = lengths.iter().copied().max().unwrap_or(0);
    if max_len == 0 {
        return Table {
            codes: vec![0],
            max_len: 1,
        };
    }
    let size = 1usize << max_len;
    let mut codes = vec![0u32; size];
    let mut code = 0u32;
    for len in 1..=max_len {
        for (value, &length) in lengths.iter().enumerate() {
            if length != len {
                continue;
            }
            let mut reversed = 0u32;
            let mut t = code;
            for _ in 0..len {
                reversed = (reversed << 1) | (t & 1);
                t >>= 1;
            }
            let mut i = reversed as usize;
            while i < size {
                codes[i] = (u32::from(len) << 16) | value as u32;
                i += 1 << len;
            }
            code += 1;
        }
        code <<= 1;
    }
    Table { codes, max_len }
}

/// The fixed codes of deflate: what pdf.js's tables hold (codes 286, 287, 30 and 31 decode to nothing that copies)
fn fixed_tables() -> (Table, Table) {
    let mut literals = [8u8; 288];
    literals[144..256].fill(9);
    literals[256..280].fill(7);
    (table(&literals), table(&[5u8; 32]))
}

const CODE_LEN_CODE_MAP: [u8; 19] = [16, 17, 18, 0, 8, 7, 9, 6, 10, 5, 11, 4, 12, 3, 13, 2, 14, 1, 15];

const LENGTH_DECODE: [u32; 29] = [
    0x00003, 0x00004, 0x00005, 0x00006, 0x00007, 0x00008, 0x00009, 0x0000a, 0x1000b, 0x1000d, 0x1000f, 0x10011,
    0x20013, 0x20017, 0x2001b, 0x2001f, 0x30023, 0x3002b, 0x30033, 0x3003b, 0x40043, 0x40053, 0x40063, 0x40073,
    0x50083, 0x500a3, 0x500c3, 0x500e3, 0x00102,
];

const DIST_DECODE: [u32; 30] = [
    0x00001, 0x00002, 0x00003, 0x00004, 0x10005, 0x10007, 0x20009, 0x2000d, 0x30011, 0x30019, 0x40021, 0x40031,
    0x50041, 0x50061, 0x60081, 0x600c1, 0x70101, 0x70181, 0x80201, 0x80301, 0x90401, 0x90601, 0xa0801, 0xa0c01,
    0xb1001, 0xb1801, 0xc2001, 0xc3001, 0xd4001, 0xd6001,
];

#[cfg(test)]
mod tests {
    use super::*;
    use std::io::Write;

    fn deflate(data: &[u8], zlib: bool) -> Vec<u8> {
        if zlib {
            let mut e = flate2::write::ZlibEncoder::new(Vec::new(), flate2::Compression::best());
            e.write_all(data).unwrap();
            e.finish().unwrap()
        } else {
            let mut e = flate2::write::DeflateEncoder::new(Vec::new(), flate2::Compression::best());
            e.write_all(data).unwrap();
            e.finish().unwrap()
        }
    }

    #[test]
    fn the_lenient_count_matches_what_a_valid_stream_holds() {
        let text: Vec<u8> = (0..200_000u32).map(|i| (i % 251) as u8 ^ (i / 7) as u8).collect();
        for zlib in [true, false] {
            assert_eq!(lenient(&deflate(&text, zlib), u64::MAX - 1), text.len() as u64);
            assert_eq!(lenient(&deflate(&[b' '; 1_000_000], zlib), u64::MAX - 1), 1_000_000);
        }
        // stored blocks
        let stored = {
            let mut e = flate2::write::DeflateEncoder::new(Vec::new(), flate2::Compression::none());
            e.write_all(&text).unwrap();
            e.finish().unwrap()
        };
        assert_eq!(lenient(&stored, u64::MAX - 1), text.len() as u64);
    }

    #[test]
    fn a_stream_only_the_lenient_decoder_reads_is_counted() {
        // a fixed block whose first code refers to before the start (flate2 refuses it, pdf.js skips it), then a
        // stored block to reach a byte boundary, then a megabyte of spaces
        let mut data = super::super::tests::bad_reference_prefix();
        data.extend_from_slice(&deflate(&[b' '; 1 << 20], false));
        assert!(
            flate2::read::DeflateDecoder::new(&data[..])
                .read_to_end(&mut Vec::new())
                .is_err()
        );
        let (size, _) = count(&data, u64::MAX - 1, false);
        assert_eq!(size, 1 << 20);
        // capped: it stops soon after the cap
        let capped = count(&data, 1000, false).0;
        assert!(capped > 1000 && capped < 2000, "{capped}");
        // a filter after it: refused
        assert!(count(&data, 1000, true).0 > 1000);
    }
}
