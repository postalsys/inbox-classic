//! A picture file to its preview: read with the `image` crate under hard limits, turned upright as its EXIF says,
//! scaled to at most [`MAX_SIDE`] pixels and encoded again ([`crate::encode`]), its EXIF (camera, place, time) left
//! behind

use std::io::Cursor;

use image::{DynamicImage, ImageDecoder, ImageError, ImageFormat, ImageReader, Limits, imageops::FilterType};

use crate::limits::{MAX_FILE, MAX_PICTURE_ALLOC, MAX_PICTURE_PIXELS, MAX_PICTURE_SIDE, MAX_SIDE};
use crate::{Description, Kind, Picture, Refusal};

/// The format of `bytes` by their content, when it is one previews read
pub fn format_of(bytes: &[u8]) -> Option<ImageFormat> {
    match image::guess_format(bytes).ok()? {
        format @ (ImageFormat::Jpeg
        | ImageFormat::Png
        | ImageFormat::Gif
        | ImageFormat::WebP
        | ImageFormat::Bmp
        | ImageFormat::Ico
        | ImageFormat::Tiff) => Some(format),
        _ => None,
    }
}

/// The size a picture's preview will have (turned upright, scaled), read from its header only: what the reading
/// pane reserves before the preview is drawn
pub fn describe(bytes: &[u8]) -> Result<Description, Refusal> {
    let (_, mut decoder) = open(bytes)?;
    let (width, height) = decoder.dimensions();
    let turned = decoder.orientation().is_ok_and(swaps_sides);
    let (width, height) = fit(width, height);
    Ok(Description {
        kind: Kind::Picture,
        pages: 1,
        title: None,
        sizes: vec![Some(if turned { (height, width) } else { (width, height) })],
    })
}

/// The preview of a picture file
pub fn render(bytes: &[u8]) -> Result<Picture, Refusal> {
    let (format, mut decoder) = open(bytes)?;
    let orientation = decoder.orientation().ok();
    let icc = decoder.icc_profile().ok().flatten();
    let image = DynamicImage::from_decoder(decoder).map_err(refusal)?;
    let mut image = scale(image);
    if let Some(orientation) = orientation {
        image.apply_orientation(orientation);
    }
    crate::encode::encode(image, is_photo(format, bytes), icc)
}

/// A decoder of `bytes` with the limits set, its size checked before anything is decoded
fn open(bytes: &[u8]) -> Result<(ImageFormat, impl ImageDecoder + '_), Refusal> {
    if bytes.len() > MAX_FILE {
        return Err(Refusal::TooLarge);
    }
    let format = format_of(bytes).ok_or(Refusal::Unsupported)?;
    if format == ImageFormat::WebP && webp_chunks(bytes).is_none() {
        return Err(Refusal::Unreadable);
    }
    let mut reader = ImageReader::with_format(Cursor::new(bytes), format);
    reader.limits(limits());
    let decoder = reader.into_decoder().map_err(refusal)?;
    let (width, height) = decoder.dimensions();
    if width == 0 || height == 0 {
        return Err(Refusal::Unreadable);
    }
    if !within(width, height) || decoder.total_bytes() > MAX_PICTURE_ALLOC {
        return Err(Refusal::TooLarge);
    }
    Ok((format, decoder))
}

fn limits() -> Limits {
    let mut limits = Limits::default();
    limits.max_image_width = Some(MAX_PICTURE_SIDE);
    limits.max_image_height = Some(MAX_PICTURE_SIDE);
    limits.max_alloc = Some(MAX_PICTURE_ALLOC);
    limits
}

/// Whether a picture of `width` by `height` is read at all
pub(crate) fn within(width: u32, height: u32) -> bool {
    width <= MAX_PICTURE_SIDE
        && height <= MAX_PICTURE_SIDE
        && u64::from(width) * u64::from(height) <= MAX_PICTURE_PIXELS
}

fn refusal(error: ImageError) -> Refusal {
    match error {
        ImageError::Limits(_) => Refusal::TooLarge,
        ImageError::Unsupported(_) => Refusal::Unsupported,
        _ => Refusal::Unreadable,
    }
}

/// `width` by `height` scaled to fit [`MAX_SIDE`], never enlarged
pub(crate) fn fit(width: u32, height: u32) -> (u32, u32) {
    let longest = width.max(height);
    if longest <= MAX_SIDE {
        return (width, height);
    }
    let scale = f64::from(MAX_SIDE) / f64::from(longest);
    let side = |n: u32| ((f64::from(n) * scale).round() as u32).clamp(1, MAX_SIDE);
    (side(width), side(height))
}

/// `image` at most [`MAX_SIDE`] pixels on its longest side. Far larger pictures are averaged (each pixel read once,
/// no buffer of the full size in floats); those only a little larger are filtered, which looks better there
fn scale(image: DynamicImage) -> DynamicImage {
    let (width, height) = fit(image.width(), image.height());
    if (width, height) == (image.width(), image.height()) {
        return image;
    }
    if image.width() >= width * 2 {
        image.thumbnail_exact(width, height)
    } else {
        image.resize_exact(width, height, FilterType::Triangle)
    }
}

fn swaps_sides(orientation: image::metadata::Orientation) -> bool {
    use image::metadata::Orientation::*;
    matches!(orientation, Rotate90 | Rotate270 | Rotate90FlipH | Rotate270FlipH)
}

/// Whether a picture is a photo, written as a JPEG: a JPEG, or a WebP compressed as one (VP8, not the lossless VP8L)
fn is_photo(format: ImageFormat, bytes: &[u8]) -> bool {
    match format {
        ImageFormat::Jpeg => true,
        ImageFormat::WebP => webp_chunks(bytes)
            .and_then(|chunks| chunks.into_iter().find(|name| name == b"VP8 " || name == b"VP8L"))
            .is_some_and(|name| &name == b"VP8 "),
        _ => false,
    }
}

/// The names of a WebP file's chunks, in order; None when one says it is longer than what is left of the file.
/// image-webp allocates a metadata chunk (EXIF, ICC) at the length it says before reading it: a 684 byte file whose
/// EXIF chunk said 4 GB made it ask for 4 GB (found by the fuzz target `preview_picture`)
pub(crate) fn webp_chunks(bytes: &[u8]) -> Option<Vec<[u8; 4]>> {
    let mut names = Vec::new();
    // after the RIFF header: four bytes of name, four of length (little endian), the data padded to even
    let mut at = 12usize;
    while let Some(head) = bytes.get(at..at + 8) {
        let length = u32::from_le_bytes([head[4], head[5], head[6], head[7]]) as usize;
        let data_end = at.checked_add(8)?.checked_add(length)?;
        if data_end > bytes.len() {
            return None;
        }
        names.push([head[0], head[1], head[2], head[3]]);
        at = data_end + (length & 1);
    }
    Some(names)
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn fits_the_longest_side_and_never_enlarges() {
        assert_eq!(fit(100, 50), (100, 50));
        assert_eq!(fit(8192, 6144), (2048, 1536));
        assert_eq!(fit(6144, 8192), (1536, 2048));
        assert_eq!(fit(16_384, 1), (2048, 1));
        assert_eq!(fit(MAX_SIDE, MAX_SIDE), (MAX_SIDE, MAX_SIDE));
    }

    #[test]
    fn the_side_and_pixel_limits() {
        assert!(within(10_000, 10_000));
        assert!(within(MAX_PICTURE_SIDE, 6000));
        assert!(!within(MAX_PICTURE_SIDE + 1, 1));
        assert!(!within(1, MAX_PICTURE_SIDE + 1));
        assert!(!within(MAX_PICTURE_SIDE, MAX_PICTURE_SIDE));
    }

    #[test]
    fn formats_by_content_only() {
        assert_eq!(format_of(b"\x89PNG\r\n\x1a\n...."), Some(ImageFormat::Png));
        assert_eq!(format_of(b"\xff\xd8\xff\xe0...."), Some(ImageFormat::Jpeg));
        assert_eq!(format_of(b"<svg xmlns=\"http://www.w3.org/2000/svg\"/>"), None);
        assert_eq!(format_of(b"<html><body>"), None);
        // HEIC's ftyp box: a tile
        assert_eq!(format_of(b"\0\0\0\x18ftypheic\0\0\0\0mif1heic"), None);
    }

    #[test]
    fn lossy_webp_is_a_photo() {
        assert!(is_photo(ImageFormat::WebP, b"RIFF\0\0\0\0WEBPVP8 \0\0\0\0"));
        assert!(!is_photo(ImageFormat::WebP, b"RIFF\0\0\0\0WEBPVP8L\0\0\0\0"));
        let mut extended = b"RIFF\0\0\0\0WEBPVP8X\x0a\0\0\0".to_vec();
        extended.extend([0u8; 10]);
        extended.extend(b"ALPH\x03\0\0\0abc\0");
        extended.extend(b"VP8 \0\0\0\0");
        assert!(is_photo(ImageFormat::WebP, &extended));
        assert!(!is_photo(ImageFormat::Png, b""));
    }

    #[test]
    fn a_webp_chunk_longer_than_the_file_is_refused() {
        let mut file = b"RIFF\0\0\0\0WEBPVP8X\x0a\0\0\0".to_vec();
        file.extend([0u8; 10]);
        assert_eq!(webp_chunks(&file), Some(vec![*b"VP8X"]));
        // an EXIF chunk that says 4 GB
        file.extend(b"EXIF\xff\xff\xff\xffabc");
        assert_eq!(webp_chunks(&file), None);
        assert_eq!(render(&file), Err(Refusal::Unreadable));
    }
}
