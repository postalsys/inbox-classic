//! Pixels to the bytes a web view gets: a JPEG for photos, a PNG for the rest and for anything see-through. Nothing
//! but the pixels and an ICC profile that matches them is written: no EXIF, no text chunks.

use image::codecs::jpeg::JpegEncoder;
use image::codecs::png::{CompressionType, FilterType, PngEncoder};
use image::{DynamicImage, ExtendedColorType, ImageEncoder};

use crate::limits::{JPEG_QUALITY, MAX_ICC, PAGE_PNG};
use crate::{Mime, Picture, Refusal};

/// `image` encoded: a JPEG when `photo` and nothing in it is see-through, otherwise a PNG. `icc` is carried over when
/// it describes the colors written (an RGB profile for color, a gray one for gray; a CMYK JPEG's profile does not
/// describe the RGB it was turned into)
pub(crate) fn encode(image: DynamicImage, photo: bool, icc: Option<Vec<u8>>) -> Result<Picture, Refusal> {
    let gray = !image.color().has_color();
    let alpha = image.color().has_alpha() && uses_alpha(&image);
    let (width, height) = (image.width(), image.height());
    let (pixels, color) = match (gray, alpha) {
        (true, false) => (image.into_luma8().into_raw(), ExtendedColorType::L8),
        (true, true) => (image.into_luma_alpha8().into_raw(), ExtendedColorType::La8),
        (false, false) => (image.into_rgb8().into_raw(), ExtendedColorType::Rgb8),
        (false, true) => (image.into_rgba8().into_raw(), ExtendedColorType::Rgba8),
    };
    let icc = icc.filter(|icc| icc_matches(icc, gray));
    if photo && !alpha {
        let bytes = write(Mime::Jpeg, &pixels, width, height, color, icc)?;
        return Ok(Picture {
            mime: Mime::Jpeg,
            bytes,
            width,
            height,
        });
    }
    if alpha {
        let bytes = write(Mime::Png, &pixels, width, height, color, icc)?;
        return Ok(Picture {
            mime: Mime::Png,
            bytes,
            width,
            height,
        });
    }
    opaque(&pixels, width, height, color, icc)
}

/// RGB pixels of a drawn page (opaque), as [`opaque`] writes them
pub(crate) fn page(rgb: &[u8], width: u32, height: u32) -> Result<Picture, Refusal> {
    opaque(rgb, width, height, ExtendedColorType::Rgb8, None)
}

/// Opaque pixels that are not known to be a photo: a PNG, which keeps text and lines sharp; one whose PNG is over
/// [`PAGE_PNG`] (a scan, a photo in a lossless format) as a JPEG when that is less than half the size
fn opaque(
    pixels: &[u8],
    width: u32,
    height: u32,
    color: ExtendedColorType,
    icc: Option<Vec<u8>>,
) -> Result<Picture, Refusal> {
    let png = write(Mime::Png, pixels, width, height, color, icc.clone())?;
    let (mime, bytes) = if png.len() > PAGE_PNG {
        match write(Mime::Jpeg, pixels, width, height, color, icc) {
            Ok(jpeg) if jpeg.len() < png.len() / 2 => (Mime::Jpeg, jpeg),
            _ => (Mime::Png, png),
        }
    } else {
        (Mime::Png, png)
    };
    Ok(Picture {
        mime,
        bytes,
        width,
        height,
    })
}

fn write(
    mime: Mime,
    pixels: &[u8],
    width: u32,
    height: u32,
    color: ExtendedColorType,
    icc: Option<Vec<u8>>,
) -> Result<Vec<u8>, Refusal> {
    let mut out = Vec::new();
    let written = match mime {
        Mime::Jpeg => {
            let mut encoder = JpegEncoder::new_with_quality(&mut out, JPEG_QUALITY);
            if let Some(icc) = icc {
                let _ = encoder.set_icc_profile(icc);
            }
            encoder.write_image(pixels, width, height, color)
        }
        Mime::Png => {
            let mut encoder = PngEncoder::new_with_quality(&mut out, CompressionType::Default, FilterType::Adaptive);
            if let Some(icc) = icc {
                let _ = encoder.set_icc_profile(icc);
            }
            encoder.write_image(pixels, width, height, color)
        }
    };
    written.map_err(|_| Refusal::Unreadable)?;
    Ok(out)
}

/// Whether any pixel of `image` is see-through
fn uses_alpha(image: &DynamicImage) -> bool {
    match image {
        DynamicImage::ImageLumaA8(i) => i.pixels().any(|p| p.0[1] != u8::MAX),
        DynamicImage::ImageRgba8(i) => i.pixels().any(|p| p.0[3] != u8::MAX),
        DynamicImage::ImageLumaA16(i) => i.pixels().any(|p| p.0[1] != u16::MAX),
        DynamicImage::ImageRgba16(i) => i.pixels().any(|p| p.0[3] != u16::MAX),
        DynamicImage::ImageRgba32F(i) => i.pixels().any(|p| p.0[3] < 1.0),
        _ => false,
    }
}

/// Whether `icc` is a profile of the colors written: its header's data color space (bytes 16 to 19)
fn icc_matches(icc: &[u8], gray: bool) -> bool {
    if icc.len() < 128 || icc.len() > MAX_ICC {
        return false;
    }
    let space = &icc[16..20];
    if gray { space == b"GRAY" } else { space == b"RGB " }
}

#[cfg(test)]
mod tests {
    use super::*;

    fn profile(space: &[u8; 4]) -> Vec<u8> {
        let mut icc = vec![0u8; 200];
        icc[16..20].copy_from_slice(space);
        icc
    }

    #[test]
    fn only_a_matching_profile_is_kept() {
        assert!(icc_matches(&profile(b"RGB "), false));
        assert!(!icc_matches(&profile(b"CMYK"), false));
        assert!(!icc_matches(&profile(b"RGB "), true));
        assert!(icc_matches(&profile(b"GRAY"), true));
        assert!(!icc_matches(&[0; 20], false));
        let mut huge = profile(b"RGB ");
        huge.resize(MAX_ICC + 1, 0);
        assert!(!icc_matches(&huge, false));
    }

    #[test]
    fn opaque_alpha_is_dropped_and_real_alpha_kept() {
        let opaque = DynamicImage::ImageRgba8(image::RgbaImage::from_pixel(4, 4, image::Rgba([1, 2, 3, 255])));
        let encoded = encode(opaque, true, None).unwrap();
        assert_eq!(encoded.mime, Mime::Jpeg);
        let clear = DynamicImage::ImageRgba8(image::RgbaImage::from_pixel(4, 4, image::Rgba([1, 2, 3, 0])));
        let encoded = encode(clear, true, None).unwrap();
        assert_eq!(encoded.mime, Mime::Png);
        let read = image::load_from_memory(&encoded.bytes).unwrap();
        assert!(read.color().has_alpha());
    }
}
