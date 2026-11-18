//! The pictures of a message's text (docs/attachment-preview-plan.md, decision 8): every `cid:` and `data:` picture
//! answered from the view's preview addresses with the core's own encode, never the sender's bytes; what the core can
//! not draw a plain placeholder; their sizes in the markup; another view's or another message's never answered; the
//! printout with them.

use std::sync::Arc;
use std::sync::mpsc::Receiver;
use std::time::{Duration, Instant};

use base64::Engine;
use base64::engine::general_purpose::STANDARD;
use pe_html::INLINE_BASE;

use super::*;
use crate::list_load::tests::opened;

fn encoded(image: image::DynamicImage, format: image::ImageFormat) -> Vec<u8> {
    let mut bytes = Vec::new();
    image.write_to(&mut std::io::Cursor::new(&mut bytes), format).unwrap();
    bytes
}

/// The PNG, 64 by 32, of one colour
fn png(colour: [u8; 3]) -> Vec<u8> {
    let picture = image::RgbImage::from_pixel(64, 32, image::Rgb(colour));
    encoded(image::DynamicImage::ImageRgb8(picture), image::ImageFormat::Png)
}

fn jpeg() -> Vec<u8> {
    let picture = image::RgbImage::from_pixel(40, 20, image::Rgb([20, 160, 40]));
    encoded(image::DynamicImage::ImageRgb8(picture), image::ImageFormat::Jpeg)
}

/// A GIF of one red pixel
const GIF: &str = "R0lGODdhAQABAPAAAP8AAAAAACwAAAAAAQABAAACAkQBADs=";
/// A PNG cut after its signature and a broken header
const BROKEN: &[u8] = b"\x89PNG\r\n\x1a\n\0\0\0\rIHDR\xff\xff\xff\xff";
/// The start of a HEIC file, which the core does not draw
const HEIC: &[u8] = b"\0\0\0\x18ftypheic\0\0\0\0mif1heic\0\0\0\0";
const SVG: &str = "<svg xmlns=\"http://www.w3.org/2000/svg\" width=\"30\" height=\"10\">\
                   <rect width=\"30\" height=\"10\" fill=\"#0000cc\"/><script>alert(1)</script></svg>";

fn part(content_type: &str, id: &str, bytes: &[u8]) -> String {
    format!(
        "--r\r\nContent-Type: {content_type}\r\nContent-ID: <{id}>\r\nContent-Transfer-Encoding: base64\r\n\r\n{}\r\n",
        STANDARD.encode(bytes)
    )
}

/// A newsletter: its HTML shows a PNG (no size), a JPEG (its width only), a GIF (both), a broken PNG, a HEIC
/// picture, an SVG one and a `data:` PNG
fn newsletter(red: [u8; 3]) -> Vec<u8> {
    let yellow = STANDARD.encode(png([230, 200, 0]));
    let html = format!(
        "<p>Hello</p><img src=\"cid:png@x\" alt=\"Logo\"><img src=\"cid:jpeg@x\" width=\"80\">\
         <img src=\"cid:gif@x\" width=\"5\" height=\"5\"><img src=\"cid:broken@x\"><img src=\"cid:heic@x\">\
         <img src=\"cid:svg@x\"><img src=\"data:image/png;base64,{yellow}\"><p>Bye</p>"
    );
    let mut message = format!(
        "From: news@example.com\r\nSubject: News\r\nMIME-Version: 1.0\r\n\
         Content-Type: multipart/related; boundary=r\r\n\r\n--r\r\nContent-Type: text/html\r\n\r\n{html}\r\n"
    );
    message.push_str(&part("image/png", "png@x", &png(red)));
    message.push_str(&part("image/jpeg", "jpeg@x", &jpeg()));
    message.push_str(&part("image/gif", "gif@x", &STANDARD.decode(GIF).unwrap()));
    message.push_str(&part("image/png", "broken@x", BROKEN));
    message.push_str(&part("image/heic", "heic@x", HEIC));
    message.push_str(&part("image/svg+xml", "svg@x", SVG.as_bytes()));
    message.push_str("--r--\r\n");
    message.into_bytes()
}

fn answered(core: &Core, events: &Receiver<Event>, ask: u64) -> Option<Arc<Picture>> {
    let until = Instant::now() + Duration::from_secs(60);
    loop {
        match events.recv_timeout(until.saturating_duration_since(Instant::now())) {
            Ok(Event::PreviewAnswered { ask: done }) if done == ask => return core.preview_answer(ask),
            Ok(_) => {}
            Err(error) => panic!("ask {ask} not answered: {error}"),
        }
    }
}

fn shown(core: &Core, events: &Receiver<Event>, inbox: FolderId) -> crate::MessageView {
    super::tests::settled(core, events, || core.message_view(inbox, 1, false).unwrap().unwrap())
}

/// The picture answered for picture `number` of the text of the document of `token`
fn picture(core: &Arc<Core>, events: &Receiver<Event>, token: &str, number: usize) -> Arc<Picture> {
    let ask = core
        .preview_ask(&format!("/pv/{token}-{number}-0"))
        .unwrap_or_else(|| panic!("no ask of {number}"));
    answered(core, events, ask).unwrap()
}

fn pixel(picture: &Picture, x: u32, y: u32) -> [u8; 4] {
    image::load_from_memory(&picture.bytes)
        .unwrap()
        .to_rgba8()
        .get_pixel(x, y)
        .0
}

fn near(a: [u8; 4], b: [u8; 4]) -> bool {
    a.iter().zip(b).all(|(a, b)| a.abs_diff(b) <= 12)
}

#[test]
fn every_picture_of_the_text_is_the_core_s_own_encode() {
    let dir = pe_testkit::TempDir::new("core-inline-pictures");
    let (core, inbox, events) = opened(&dir, 1);
    let source = newsletter([200, 30, 30]);
    core.store().set_source(inbox, 1, &source).unwrap();
    let view = shown(&core, &events, inbox);
    // a message with no file to preview has a token all the same: its text's pictures need it
    let token = view.preview_token.clone().unwrap();
    let document = &view.document;
    let address = |n: usize| format!("src=\"/pv/{token}-{}-0\"", INLINE_BASE + n);
    // the PNG's own size where its img says none, the JPEG's height by its proportions, the GIF's as written
    assert!(
        document.contains(&format!("<img {} alt=\"Logo\" width=\"64\" height=\"32\">", address(0))),
        "{document}"
    );
    assert!(
        document.contains(&format!("<img {} width=\"80\" height=\"40\">", address(1))),
        "{document}"
    );
    assert!(
        document.contains(&format!("<img {} width=\"5\" height=\"5\">", address(2))),
        "{document}"
    );
    // the SVG's size read by resvg; the broken and the HEIC picture have none
    assert!(
        document.contains(&format!("<img {} width=\"30\" height=\"10\">", address(5))),
        "{document}"
    );
    assert!(document.contains(&format!("<img {}>", address(3))), "{document}");
    assert!(document.contains(&format!("<img {}>", address(4))), "{document}");
    assert!(document.contains(&address(6)), "{document}");
    // nothing of the sender's pictures in the document, and the CSP lets pictures come from the preview path only
    assert!(
        !document.contains("data:image") && !document.contains("cid:"),
        "{document}"
    );
    assert!(!document.contains(&STANDARD.encode(png([200, 30, 30]))), "{document}");
    assert!(
        document.contains(&format!("img-src {}/pv/;", pe_html::preview_origin())),
        "{document}"
    );

    let red = picture(&core, &events, &token, INLINE_BASE);
    assert_eq!((red.mime, red.width, red.height), (PreviewMime::Png, 64, 32));
    assert_ne!(red.bytes, png([200, 30, 30]));
    assert_eq!(pixel(&red, 10, 10), [200, 30, 30, 255]);
    let green = picture(&core, &events, &token, INLINE_BASE + 1);
    assert_eq!((green.mime, green.width, green.height), (PreviewMime::Jpeg, 40, 20));
    assert_ne!(green.bytes, jpeg());
    assert!(near(pixel(&green, 10, 10), [20, 160, 40, 255]));
    // a GIF answered as a PNG of its first frame
    let gif = picture(&core, &events, &token, INLINE_BASE + 2);
    assert_eq!((gif.mime, gif.width), (PreviewMime::Png, 1));
    assert!(!gif.bytes.starts_with(b"GIF"));
    assert_eq!(pixel(&gif, 0, 0), [255, 0, 0, 255]);
    // what can not be drawn: the plain placeholder, never the bytes
    for number in [INLINE_BASE + 3, INLINE_BASE + 4] {
        let placeholder = picture(&core, &events, &token, number);
        assert_eq!((placeholder.width, placeholder.height), (1, 1));
        assert_eq!(pixel(&placeholder, 0, 0), [0xe6, 0xe6, 0xe6, 255]);
    }
    // the SVG drawn by resvg, its script never run (nothing runs it), a PNG
    let svg = picture(&core, &events, &token, INLINE_BASE + 5);
    assert_eq!((svg.mime, svg.width, svg.height), (PreviewMime::Png, 30, 10));
    assert_eq!(pixel(&svg, 5, 5), [0, 0, 0xcc, 255]);
    let yellow = picture(&core, &events, &token, INLINE_BASE + 6);
    assert_eq!(pixel(&yellow, 5, 5), [230, 200, 0, 255]);
    assert_ne!(yellow.bytes, png([230, 200, 0]));

    // a number the document does not show, or a link to a picture of the text: nothing
    assert_eq!(core.preview_ask(&format!("/pv/{token}-{}-0", INLINE_BASE + 7)), None);
    assert_eq!(core.preview_ask(&format!("/pv/{token}-{INLINE_BASE}-1")), None);
    assert_eq!(
        core.preview_link(&format!("inboxclassic:attachment-{token}-{INLINE_BASE}"), &token),
        None
    );
    // the view ends: its pictures are not answered anymore
    core.previews_end(&token);
    assert_eq!(core.preview_ask(&format!("/pv/{token}-{INLINE_BASE}-0")), None);
}

/// Each view's pictures under its own token: another message's view, with a picture of the same number, answers its
/// own picture, never this one's; and a view of the same message shown again answers from the cache
#[test]
fn a_picture_of_another_message_never_answers() {
    let dir = pe_testkit::TempDir::new("core-inline-other");
    let (core, inbox, events) = opened(&dir, 2);
    core.store().set_source(inbox, 1, &newsletter([200, 30, 30])).unwrap();
    core.store().set_source(inbox, 2, &newsletter([30, 30, 200])).unwrap();
    let first = shown(&core, &events, inbox).preview_token.unwrap();
    let second = super::tests::settled(&core, &events, || core.message_view(inbox, 2, false).unwrap().unwrap())
        .preview_token
        .unwrap();
    assert_ne!(first, second);
    assert_eq!(
        pixel(&picture(&core, &events, &first, INLINE_BASE), 5, 5),
        [200, 30, 30, 255]
    );
    assert_eq!(
        pixel(&picture(&core, &events, &second, INLINE_BASE), 5, 5),
        [30, 30, 200, 255]
    );
    core.previews_end(&first);
    assert_eq!(core.preview_ask(&format!("/pv/{first}-{INLINE_BASE}-0")), None);
    assert_eq!(
        pixel(&picture(&core, &events, &second, INLINE_BASE), 5, 5),
        [30, 30, 200, 255]
    );
}

/// The printout has the pictures of the text where the text shows them, as `data:` addresses of the core's encodes
/// (the print windows load nothing but the page); one the core can not draw is an empty picture
#[test]
fn the_printout_has_the_pictures_of_the_text() {
    let dir = pe_testkit::TempDir::new("core-inline-print");
    let (core, inbox, events) = opened(&dir, 1);
    core.store().set_source(inbox, 1, &newsletter([200, 30, 30])).unwrap();
    let view = shown(&core, &events, inbox);
    let token = view.preview_token.clone().unwrap();
    let request = core.print_start(&token).unwrap();
    let until = Instant::now() + Duration::from_secs(60);
    loop {
        match events.recv_timeout(until.saturating_duration_since(Instant::now())) {
            Ok(Event::PrintReady { request: done }) if done == request => break,
            Ok(_) => {}
            Err(error) => panic!("no printout: {error}"),
        }
    }
    let printed = core.print_result(request).unwrap();
    assert!(!printed.contains("/pv/") && !printed.contains(&token), "{printed}");
    assert!(!printed.contains(&STANDARD.encode(png([200, 30, 30]))), "{printed}");
    // the core's encode, the same the reading pane was answered with
    let red = picture(&core, &events, &token, INLINE_BASE);
    let red = format!("data:image/png;base64,{}", STANDARD.encode(&red.bytes));
    let at = |text: &str| printed.find(text).unwrap_or_else(|| panic!("{text} in {printed}"));
    assert!(at("<p>Hello</p>") < at(&red) && at(&red) < at("<p>Bye</p>"));
    assert_eq!(printed.matches("<img src=\"data:image/").count(), 7, "{printed}");
    assert!(printed.contains("img-src data:;"), "{printed}");
}

/// A picture of the text that is also listed (a part with a Content-ID in multipart/mixed, which the HTML shows):
/// shown in the text from the preview path, and not again after it
#[test]
fn a_listed_picture_the_text_shows_is_shown_once() {
    let dir = pe_testkit::TempDir::new("core-inline-listed");
    let (core, inbox, events) = opened(&dir, 1);
    let message = format!(
        "From: a@example.com\r\nSubject: x\r\nMIME-Version: 1.0\r\nContent-Type: multipart/mixed; boundary=b\r\n\r\n\
         --b\r\nContent-Type: text/html\r\n\r\n<p>See</p><img src=\"cid:red@x\">\r\n\
         --b\r\nContent-Type: image/png; name=red.png\r\nContent-Disposition: attachment; filename=red.png\r\n\
         Content-ID: <red@x>\r\nContent-Transfer-Encoding: base64\r\n\r\n{}\r\n--b--\r\n",
        STANDARD.encode(png([200, 30, 30]))
    );
    core.store().set_source(inbox, 1, message.as_bytes()).unwrap();
    let view = shown(&core, &events, inbox);
    let token = view.preview_token.clone().unwrap();
    assert_eq!(view.document.matches("<img").count(), 1, "{}", view.document);
    assert!(!view.document.contains("<figure>"), "{}", view.document);
    assert_eq!(view.attachments[0].show_in_message, ShowInMessage::None);
    assert_eq!(
        pixel(&picture(&core, &events, &token, INLINE_BASE), 5, 5),
        [200, 30, 30, 255]
    );
}
