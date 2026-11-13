//! Contacts' pictures (docs/column-layout-plan.md, step 5): a picture file the user chose, or one a vCard carries,
//! read here and kept as the core's own PNG of [`SIDE`] pixels square, never as the bytes that came. PNG and JPEG only,
//! told by their content; a file too big, a picture too large, or anything else is refused before it is decoded
//! whole. The windows get pixels ([`bgra`]), as they do for brands' logos, and decode nothing.

use std::io::Cursor;

use image::{DynamicImage, ImageDecoder, ImageFormat, ImageReader, Limits, imageops::FilterType};

/// The most a picture file may be
pub const MAX_FILE: usize = 10 * 1024 * 1024;
/// The widest and tallest a picture may be
pub const MAX_SIDE: u32 = 8000;
/// The side of the square the core keeps
pub const SIDE: u32 = 256;

/// Why a picture was refused
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum Refused {
    /// Not a PNG or JPEG picture, or a broken one
    NotPicture,
    /// A file or a picture larger than [`MAX_FILE`] or [`MAX_SIDE`]
    TooLarge,
}

impl Refused {
    /// What the window says of it, in the language in use
    pub fn text(self) -> String {
        match self {
            Refused::NotPicture => pe_i18n::tr(pe_i18n::Text::UiPictureNotPicture),
            Refused::TooLarge => pe_i18n::tr(pe_i18n::Text::UiPictureTooLarge),
        }
    }
}

/// `bytes` of a picture as the core keeps it: its middle square, turned upright as its EXIF says, [`SIDE`] pixels
/// square, as a PNG of the core's own
pub fn normalize(bytes: &[u8]) -> Result<Vec<u8>, Refused> {
    if bytes.len() > MAX_FILE {
        return Err(Refused::TooLarge);
    }
    let format = match image::guess_format(bytes) {
        Ok(format @ (ImageFormat::Png | ImageFormat::Jpeg)) => format,
        _ => return Err(Refused::NotPicture),
    };
    // a decoder that panics on a hostile file refuses it, as a broken one
    let square = std::panic::catch_unwind(|| decode(bytes, format))
        .map_err(|_| Refused::NotPicture)??
        .into_rgba8();
    let mut png = Vec::new();
    DynamicImage::ImageRgba8(square)
        .write_to(&mut Cursor::new(&mut png), ImageFormat::Png)
        .map_err(|_| Refused::NotPicture)?;
    Ok(png)
}

/// The picture decoded within the limits, upright, its middle square at [`SIDE`]
fn decode(bytes: &[u8], format: ImageFormat) -> Result<DynamicImage, Refused> {
    let mut reader = ImageReader::with_format(Cursor::new(bytes), format);
    let mut limits = Limits::default();
    limits.max_image_width = Some(MAX_SIDE);
    limits.max_image_height = Some(MAX_SIDE);
    limits.max_alloc = Some(512 * 1024 * 1024);
    reader.limits(limits);
    let refused = |error: image::ImageError| match error {
        image::ImageError::Limits(_) => Refused::TooLarge,
        _ => Refused::NotPicture,
    };
    let mut decoder = reader.into_decoder().map_err(refused)?;
    let orientation = decoder.orientation().ok();
    let mut picture = DynamicImage::from_decoder(decoder).map_err(refused)?;
    if let Some(orientation) = orientation {
        picture.apply_orientation(orientation);
    }
    let (width, height) = (picture.width(), picture.height());
    if width == 0 || height == 0 {
        return Err(Refused::NotPicture);
    }
    let side = width.min(height);
    let square = picture.crop_imm((width - side) / 2, (height - side) / 2, side, side);
    Ok(square.resize_exact(SIDE, SIDE, FilterType::Lanczos3))
}

/// A kept picture (the core's own PNG) as `size` x `size` pixels, BGRA with the alpha multiplied in, as the windows
/// draw them; None for a size out of 16 to 512 or a PNG that does not read
pub fn bgra(png: &[u8], size: u32) -> Option<Vec<u8>> {
    if !(16..=512).contains(&size) {
        return None;
    }
    let picture = image::load_from_memory_with_format(png, ImageFormat::Png).ok()?;
    let scaled = picture.resize_exact(size, size, FilterType::Lanczos3).into_rgba8();
    let mut out = Vec::with_capacity((size * size * 4) as usize);
    for pixel in scaled.pixels() {
        let [r, g, b, a] = pixel.0;
        let premultiply = |c: u8| ((u16::from(c) * u16::from(a) + 127) / 255) as u8;
        out.extend_from_slice(&[premultiply(b), premultiply(g), premultiply(r), a]);
    }
    Some(out)
}

#[cfg(test)]
pub(crate) mod tests {
    use super::*;

    /// A PNG `width` x `height`, its left half red and its right half blue
    pub(crate) fn png(width: u32, height: u32) -> Vec<u8> {
        let picture = image::RgbaImage::from_fn(width, height, |x, _| {
            if x < width / 2 {
                image::Rgba([255, 0, 0, 255])
            } else {
                image::Rgba([0, 0, 255, 255])
            }
        });
        let mut out = Vec::new();
        DynamicImage::ImageRgba8(picture)
            .write_to(&mut Cursor::new(&mut out), ImageFormat::Png)
            .unwrap();
        out
    }

    fn jpeg(width: u32, height: u32) -> Vec<u8> {
        let picture = image::RgbImage::from_pixel(width, height, image::Rgb([0, 160, 0]));
        let mut out = Vec::new();
        DynamicImage::ImageRgb8(picture)
            .write_to(&mut Cursor::new(&mut out), ImageFormat::Jpeg)
            .unwrap();
        out
    }

    fn side_of(png: &[u8]) -> (u32, u32) {
        let picture = image::load_from_memory_with_format(png, ImageFormat::Png).unwrap();
        (picture.width(), picture.height())
    }

    #[test]
    fn keeps_the_middle_square_at_its_side() {
        // wide: the middle square of a red and blue picture is half of each
        let kept = normalize(&png(600, 300)).unwrap();
        assert_eq!(side_of(&kept), (SIDE, SIDE));
        let picture = image::load_from_memory(&kept).unwrap().into_rgba8();
        assert_eq!(picture.get_pixel(10, 128).0, [255, 0, 0, 255]);
        assert_eq!(picture.get_pixel(245, 128).0, [0, 0, 255, 255]);
        assert_eq!(side_of(&normalize(&jpeg(300, 900)).unwrap()), (SIDE, SIDE));
        // a small one is made larger
        assert_eq!(side_of(&normalize(&png(20, 20)).unwrap()), (SIDE, SIDE));
    }

    #[test]
    fn refuses_what_is_no_picture() {
        assert_eq!(normalize(b"GIF89a....."), Err(Refused::NotPicture));
        assert_eq!(normalize(b"plain text, no picture"), Err(Refused::NotPicture));
        let mut broken = png(64, 64);
        broken.truncate(60);
        assert_eq!(normalize(&broken), Err(Refused::NotPicture));
        let mut jpeg = jpeg(64, 64);
        jpeg.truncate(jpeg.len() / 3);
        assert!(normalize(&jpeg).is_err());
    }

    #[test]
    fn refuses_what_is_too_large() {
        assert_eq!(normalize(&vec![0u8; MAX_FILE + 1]), Err(Refused::TooLarge));
        // a PNG that says it is 9000 pixels wide is refused before it is decoded
        let mut header = png(1, 1);
        // the IHDR's width, after the signature, the chunk's length and its type
        header[16..20].copy_from_slice(&9000u32.to_be_bytes());
        assert!(normalize(&header).is_err());
        let wide = png(MAX_SIDE + 1, 1);
        assert_eq!(normalize(&wide), Err(Refused::TooLarge));
    }

    #[test]
    fn pixels_for_the_windows() {
        let kept = normalize(&png(64, 64)).unwrap();
        let pixels = bgra(&kept, 32).unwrap();
        assert_eq!(pixels.len(), 32 * 32 * 4);
        // red, in BGRA
        assert_eq!(&pixels[..4], &[0, 0, 255, 255]);
        assert!(bgra(&kept, 8).is_none());
        assert!(bgra(b"not a png", 32).is_none());
    }
}
