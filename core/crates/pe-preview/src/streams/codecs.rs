//! The size a picture codec decodes to, read from the codec's own data, as the decoders of hayro size their buffers:
//! a JPEG 2000 codestream by its SIZ marker, JBIG2 by its page information segment, CCITT fax by its Columns. The
//! dictionary's Width and Height are what the sender says; the codec's are what is allocated, so a picture counts as
//! the larger of the two.

/// Width, height and components of a JPEG 2000 file (a JP2 file's codestream, or a bare codestream), from its SIZ
/// marker; None when there is none (hayro-jpeg2000 can not decode it either, so it is refused)
pub(super) fn jpx(data: &[u8]) -> Option<(u64, u64, u64)> {
    let codestream = codestream(data)?;
    // SOC (FF4F), then SIZ (FF51): length, Rsiz, Xsiz, Ysiz, XOsiz, YOsiz, XTsiz, YTsiz, XTOsiz, YTOsiz, Csiz
    if codestream.get(..4)? != [0xff, 0x4f, 0xff, 0x51] {
        return None;
    }
    let siz = codestream.get(4..42)?;
    let u32_at = |at: usize| u64::from(u32::from_be_bytes([siz[at], siz[at + 1], siz[at + 2], siz[at + 3]]));
    let (x, y, x_offset, y_offset) = (u32_at(4), u32_at(8), u32_at(12), u32_at(16));
    let components = u64::from(u16::from_be_bytes([siz[36], siz[37]]));
    Some((x.saturating_sub(x_offset), y.saturating_sub(y_offset), components))
}

/// The codestream of a JP2 file (its `jp2c` box), or `data` when it is a bare codestream
fn codestream(data: &[u8]) -> Option<&[u8]> {
    if data.starts_with(&[0xff, 0x4f]) {
        return Some(data);
    }
    let mut at = 0usize;
    while let Some(header) = data.get(at..at + 8) {
        let length = u64::from(u32::from_be_bytes([header[0], header[1], header[2], header[3]]));
        let (start, end) = match length {
            // to the end of the file
            0 => (at + 8, data.len()),
            // the length in the eight bytes after the type
            1 => {
                let long = data.get(at + 8..at + 16)?;
                let long = u64::from_be_bytes(long.try_into().ok()?);
                (at + 16, usize::try_from(long).ok().and_then(|l| at.checked_add(l))?)
            }
            n => (at + 8, usize::try_from(n).ok().and_then(|l| at.checked_add(l))?),
        };
        if &header[4..8] == b"jp2c" {
            return data.get(start..end.min(data.len()));
        }
        if end <= at {
            return None;
        }
        at = end;
    }
    None
}

/// The tallest a JBIG2 page may be: hayro-jbig2 refuses more
pub(super) const JBIG2_MAX_SIDE: u64 = 65_535;

/// Width and height of the page of an embedded JBIG2 stream, from its page information segment; a page of unknown
/// height (striped) as tall as the decoder allows. None when the stream has no page information before a segment of
/// unknown length (the decoder then sizes the page from what follows: counted as the largest it allows), or none at
/// all, as hayro-jbig2 then refuses the stream
pub(super) fn jbig2(data: &[u8]) -> Option<(u64, u64)> {
    let mut at = 0usize;
    loop {
        let number = u32::from_be_bytes(data.get(at..at + 4)?.try_into().ok()?);
        let flags = *data.get(at + 4)?;
        let kind = flags & 0x3f;
        let long_page = flags & 0x40 != 0;
        let count_byte = *data.get(at + 5)?;
        let mut cursor = at + 6;
        let referred = match count_byte >> 5 {
            short @ 0..=4 => u64::from(short),
            7 => {
                let rest = data.get(cursor..cursor + 3)?;
                let count = u32::from_be_bytes([count_byte & 0x1f, rest[0], rest[1], rest[2]]);
                cursor += 3 + (count as usize + 1).div_ceil(8);
                u64::from(count)
            }
            _ => return None,
        };
        let number_size: u64 = if number <= 256 {
            1
        } else if number <= 65_536 {
            2
        } else {
            4
        };
        cursor = cursor.checked_add(usize::try_from(referred.checked_mul(number_size)?).ok()?)?;
        cursor += if long_page { 4 } else { 1 };
        let length = u32::from_be_bytes(data.get(cursor..cursor + 4)?.try_into().ok()?);
        cursor += 4;
        if kind == 48 {
            let info = data.get(cursor..cursor + 8)?;
            let width = u64::from(u32::from_be_bytes(info[..4].try_into().ok()?));
            let height = u64::from(u32::from_be_bytes(info[4..].try_into().ok()?));
            let height = if height == 0xffff_ffff { JBIG2_MAX_SIDE } else { height };
            return Some((width, height));
        }
        if length == 0xffff_ffff {
            // an immediate generic region of unknown length before the page information: the page is not known
            return Some((JBIG2_MAX_SIDE, JBIG2_MAX_SIDE));
        }
        at = cursor.checked_add(length as usize)?;
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    pub(crate) fn siz(width: u32, height: u32, components: u16) -> Vec<u8> {
        let mut out = vec![0xff, 0x4f, 0xff, 0x51, 0, 41, 0, 0];
        for value in [width, height, 0, 0, width, height, 0, 0] {
            out.extend(value.to_be_bytes());
        }
        out.extend(components.to_be_bytes());
        out.extend([7, 1, 1].repeat(usize::from(components)));
        out
    }

    #[test]
    fn jpx_sizes_from_siz() {
        assert_eq!(jpx(&siz(640, 480, 3)), Some((640, 480, 3)));
        // in a JP2 file: signature, ftyp, then the codestream box
        let mut jp2 = b"\0\0\0\x0cjP  \r\n\x87\n\0\0\0\x14ftypjp2 \0\0\0\0jp2 ".to_vec();
        let codestream = siz(60_000, 60_000, 4);
        jp2.extend(((codestream.len() + 8) as u32).to_be_bytes());
        jp2.extend(b"jp2c");
        jp2.extend(&codestream);
        assert_eq!(jpx(&jp2), Some((60_000, 60_000, 4)));
        assert_eq!(jpx(b"\0\0\0\x0cjP  \r\n\x87\n"), None);
        assert_eq!(jpx(b""), None);
    }

    pub(crate) fn page_info(width: u32, height: u32) -> Vec<u8> {
        // segment 0, page information (48), no referred segments, page 1, 19 bytes of data
        let mut out = vec![0, 0, 0, 0, 48, 0, 1, 0, 0, 0, 19];
        out.extend(width.to_be_bytes());
        out.extend(height.to_be_bytes());
        out.extend([0u8; 11]);
        out
    }

    #[test]
    fn jbig2_sizes_from_the_page_information() {
        assert_eq!(jbig2(&page_info(2480, 3508)), Some((2480, 3508)));
        assert_eq!(jbig2(&page_info(65_000, 0xffff_ffff)), Some((65_000, JBIG2_MAX_SIDE)));
        // after another segment (a symbol dictionary of 5 bytes)
        let mut stream = vec![0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 5, 1, 2, 3, 4, 5];
        let mut info = page_info(100, 200);
        info[3] = 1;
        stream.extend(info);
        assert_eq!(jbig2(&stream), Some((100, 200)));
        // a region of unknown length first: as large as the decoder allows
        let unknown = vec![0, 0, 0, 0, 38, 0, 1, 0xff, 0xff, 0xff, 0xff];
        assert_eq!(jbig2(&unknown), Some((JBIG2_MAX_SIDE, JBIG2_MAX_SIDE)));
        assert_eq!(jbig2(&[1, 2, 3]), None);
    }
}
