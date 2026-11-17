//! Pictures to previews: each format, EXIF orientation applied, EXIF (GPS) left behind, the ICC profile kept, large
//! photos scaled, an animation's first frame, broken files refused without a panic

use std::io::Cursor;

use image::codecs::jpeg::JpegEncoder;
use image::codecs::png::PngEncoder;
use image::{DynamicImage, ImageDecoder, ImageEncoder, ImageFormat, ImageReader, Rgb, RgbImage, Rgba, RgbaImage};
use pe_preview::limits::MAX_SIDE;
use pe_preview::{Mime, Refusal, picture};

const RED: Rgb<u8> = Rgb([255, 0, 0]);
const BLUE: Rgb<u8> = Rgb([0, 0, 255]);

/// 60 by 20, its left third red, the rest blue: where the red ends up says how it was turned
fn marked() -> RgbImage {
    RgbImage::from_fn(60, 20, |x, _| if x < 20 { RED } else { BLUE })
}

/// EXIF (a TIFF structure, big endian) with the orientation and, when `gps`, a GPS latitude
fn exif(orientation: u16, gps: bool) -> Vec<u8> {
    let mut tiff = b"MM\0\x2a\0\0\0\x08".to_vec();
    let entries: u16 = if gps { 2 } else { 1 };
    tiff.extend(entries.to_be_bytes());
    // Orientation: SHORT, 1 value, inline
    tiff.extend([0x01, 0x12, 0, 3, 0, 0, 0, 1]);
    tiff.extend(orientation.to_be_bytes());
    tiff.extend([0, 0]);
    if gps {
        // GPSInfo: LONG pointer to the GPS IFD after this one
        let gps_at = 8 + 2 + 12 * u32::from(entries) + 4;
        tiff.extend([0x88, 0x25, 0, 4, 0, 0, 0, 1]);
        tiff.extend(gps_at.to_be_bytes());
    }
    tiff.extend([0, 0, 0, 0]);
    if gps {
        // GPSLatitudeRef "N", and a marker to look for in the output
        tiff.extend(1u16.to_be_bytes());
        tiff.extend([0, 1, 0, 2, 0, 0, 0, 2, b'N', 0, 0, 0]);
        tiff.extend([0, 0, 0, 0]);
        tiff.extend(b"GPS-SECRET-PLACE");
    }
    tiff
}

fn jpeg(image: &RgbImage, exif: Option<Vec<u8>>, icc: Option<Vec<u8>>) -> Vec<u8> {
    let mut out = Vec::new();
    let mut encoder = JpegEncoder::new_with_quality(&mut out, 95);
    if let Some(exif) = exif {
        encoder.set_exif_metadata(exif).unwrap();
    }
    if let Some(icc) = icc {
        encoder.set_icc_profile(icc).unwrap();
    }
    encoder
        .write_image(
            image.as_raw(),
            image.width(),
            image.height(),
            image::ExtendedColorType::Rgb8,
        )
        .unwrap();
    out
}

fn encoded(image: DynamicImage, format: ImageFormat) -> Vec<u8> {
    let mut out = Vec::new();
    image.write_to(&mut Cursor::new(&mut out), format).unwrap();
    out
}

fn decode(bytes: &[u8]) -> DynamicImage {
    image::load_from_memory(bytes).unwrap()
}

/// Whether the pixel is mostly red
fn is_red(image: &DynamicImage, x: u32, y: u32) -> bool {
    let [r, _, b, _] = image.to_rgba8().get_pixel(x, y).0;
    r > 200 && b < 60
}

#[test]
fn orientation_is_applied() {
    // (orientation, size after, where the red third is): 1 as it is; 2 mirrored; 3 turned half; 4 flipped;
    // 5 to 8 turned a quarter (and mirrored)
    type Point = (u32, u32);
    let cases: [(u16, Point, Point); 8] = [
        (1, (60, 20), (5, 10)),
        (2, (60, 20), (55, 10)),
        (3, (60, 20), (55, 10)),
        (4, (60, 20), (5, 10)),
        (5, (20, 60), (10, 5)),
        (6, (20, 60), (10, 5)),
        (7, (20, 60), (10, 55)),
        (8, (20, 60), (10, 55)),
    ];
    for (orientation, size, red) in cases {
        let file = jpeg(&marked(), Some(exif(orientation, false)), None);
        let preview = picture::render(&file).unwrap();
        assert_eq!((preview.width, preview.height), size, "orientation {orientation}");
        let shown = decode(&preview.bytes);
        assert_eq!((shown.width(), shown.height()), size);
        assert!(is_red(&shown, red.0, red.1), "orientation {orientation}");
        // what the pane reserves is the size drawn
        assert_eq!(
            picture::describe(&file).unwrap().sizes,
            [Some(size)],
            "orientation {orientation}"
        );
    }
}

#[test]
fn exif_is_left_behind_and_icc_kept() {
    let mut icc = vec![0u8; 300];
    icc[16..20].copy_from_slice(b"RGB ");
    icc[36..40].copy_from_slice(b"acsp");
    icc[200..216].copy_from_slice(b"PROFILE-MARKER-1");
    let file = jpeg(&marked(), Some(exif(1, true)), Some(icc.clone()));
    // the file as it came has both
    assert!(file.windows(16).any(|w| w == b"GPS-SECRET-PLACE"));
    let preview = picture::render(&file).unwrap();
    assert_eq!(preview.mime, Mime::Jpeg);
    assert!(!preview.bytes.windows(16).any(|w| w == b"GPS-SECRET-PLACE"));
    assert!(!preview.bytes.windows(4).any(|w| w == b"Exif"));
    let mut decoder = ImageReader::new(Cursor::new(&preview.bytes))
        .with_guessed_format()
        .unwrap()
        .into_decoder()
        .unwrap();
    assert_eq!(decoder.icc_profile().unwrap(), Some(icc));
    assert!(decoder.exif_metadata().unwrap().is_none());
}

#[test]
fn a_cmyk_profile_is_not_carried_to_rgb() {
    let mut icc = vec![0u8; 300];
    icc[16..20].copy_from_slice(b"CMYK");
    let preview = picture::render(&jpeg(&marked(), None, Some(icc))).unwrap();
    let mut decoder = ImageReader::new(Cursor::new(&preview.bytes))
        .with_guessed_format()
        .unwrap()
        .into_decoder()
        .unwrap();
    assert_eq!(decoder.icc_profile().unwrap(), None);
}

#[test]
fn each_format_becomes_a_jpeg_or_png() {
    let photo = DynamicImage::ImageRgb8(marked());
    let clear = DynamicImage::ImageRgba8(RgbaImage::from_fn(30, 30, |x, _| Rgba([0, 0, 0, (x * 8) as u8])));
    let cases = [
        (encoded(photo.clone(), ImageFormat::Jpeg), Mime::Jpeg),
        (encoded(photo.clone(), ImageFormat::Png), Mime::Png),
        (encoded(clear.clone(), ImageFormat::Png), Mime::Png),
        (encoded(photo.clone(), ImageFormat::Gif), Mime::Png),
        (encoded(photo.clone(), ImageFormat::Bmp), Mime::Png),
        (encoded(photo.clone(), ImageFormat::Tiff), Mime::Png),
        (encoded(photo.clone(), ImageFormat::WebP), Mime::Png),
        (encoded(clear.clone(), ImageFormat::Ico), Mime::Png),
    ];
    for (index, (file, mime)) in cases.into_iter().enumerate() {
        let preview = picture::render(&file).unwrap_or_else(|e| panic!("case {index}: {e:?}"));
        assert_eq!(preview.mime, mime, "case {index}");
        let shown = decode(&preview.bytes);
        assert_eq!((shown.width(), shown.height()), (preview.width, preview.height));
    }
    // see-through stays see-through, an opaque alpha channel is dropped
    let shown = decode(&picture::render(&encoded(clear, ImageFormat::Png)).unwrap().bytes);
    assert!(shown.color().has_alpha());
}

#[test]
fn a_large_photo_is_scaled_and_never_enlarged() {
    let big = RgbImage::from_fn(6000, 4000, |x, y| Rgb([(x % 256) as u8, (y % 256) as u8, 90]));
    let preview = picture::render(&encoded(DynamicImage::ImageRgb8(big), ImageFormat::Jpeg)).unwrap();
    assert_eq!((preview.width, preview.height), (MAX_SIDE, 1365));
    let small = picture::render(&encoded(DynamicImage::ImageRgb8(marked()), ImageFormat::Png)).unwrap();
    assert_eq!((small.width, small.height), (60, 20));
}

#[test]
fn an_animation_gives_its_first_frame() {
    use image::codecs::gif::GifEncoder;
    use image::{Delay, Frame};
    let mut file = Vec::new();
    {
        let mut encoder = GifEncoder::new(&mut file);
        encoder.set_repeat(image::codecs::gif::Repeat::Infinite).unwrap();
        for n in 0..200u32 {
            let color = if n == 0 {
                Rgba([255, 0, 0, 255])
            } else {
                Rgba([0, 0, 255, 255])
            };
            let frame = Frame::from_parts(
                RgbaImage::from_pixel(40, 30, color),
                0,
                0,
                Delay::from_numer_denom_ms(10, 1),
            );
            encoder.encode_frame(frame).unwrap();
        }
    }
    let preview = picture::render(&file).unwrap();
    assert_eq!((preview.width, preview.height), (40, 30));
    assert!(is_red(&decode(&preview.bytes), 20, 15));
}

#[test]
fn broken_and_foreign_files_are_refused_without_a_panic() {
    let file = encoded(DynamicImage::ImageRgb8(marked()), ImageFormat::Jpeg);
    for cut in [2, 10, 50, file.len() / 2] {
        // a truncated JPEG is either drawn as far as it goes or refused
        let _ = picture::render(&file[..cut]);
    }
    assert_eq!(
        picture::render(b"<svg xmlns='http://www.w3.org/2000/svg'/>"),
        Err(Refusal::Unsupported)
    );
    assert_eq!(picture::render(b""), Err(Refusal::Unsupported));
    let mut huge = b"\x89PNG\r\n\x1a\n".to_vec();
    huge.resize(pe_preview::limits::MAX_FILE + 1, 0);
    assert_eq!(picture::render(&huge), Err(Refusal::TooLarge));
}

#[test]
fn a_png_is_written_as_the_core_s_own() {
    // text chunks and the like of the file are not carried
    let mut file = Vec::new();
    PngEncoder::new(&mut file)
        .write_image(marked().as_raw(), 60, 20, image::ExtendedColorType::Rgb8)
        .unwrap();
    let mut with_text = file[..33].to_vec();
    let text = b"tEXtComment\0SENDER-TEXT";
    with_text.extend((text.len() as u32 - 4).to_be_bytes());
    with_text.extend(text);
    with_text.extend(crc(text).to_be_bytes());
    with_text.extend(&file[33..]);
    assert!(with_text.windows(11).any(|w| w == b"SENDER-TEXT"));
    let preview = picture::render(&with_text).unwrap();
    assert!(!preview.bytes.windows(11).any(|w| w == b"SENDER-TEXT"));
}

fn crc(bytes: &[u8]) -> u32 {
    let mut crc = 0xffff_ffffu32;
    for &byte in bytes {
        crc ^= u32::from(byte);
        for _ in 0..8 {
            crc = if crc & 1 != 0 {
                0xedb8_8320 ^ (crc >> 1)
            } else {
                crc >> 1
            };
        }
    }
    !crc
}
