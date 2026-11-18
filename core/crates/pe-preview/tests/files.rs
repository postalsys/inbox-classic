//! The files of the spike that are safe to keep (tests/files, made by generate.py): what each gives, its sizes or the
//! reason for a tile

use std::sync::Arc;
use std::sync::mpsc;
use std::time::{Duration, Instant};

use pe_preview::{Kind, Mime, Outcome, Previewer, Refusal, Request, Settings, What, pdf, picture};

fn read(name: &str) -> Arc<Vec<u8>> {
    let path = format!("{}/tests/files/{name}", env!("CARGO_MANIFEST_DIR"));
    Arc::new(std::fs::read(&path).unwrap_or_else(|e| panic!("{path}: {e}")))
}

/// A page drawn: its size and type, or why not
type Drawn = Result<(u32, u32, Mime), Refusal>;

/// What a PDF file gives: its page count and title, and each page drawn
fn pdf_pages(name: &str) -> Result<(usize, Option<String>, Vec<Drawn>), Refusal> {
    let document = pdf::Document::open(read(name))?;
    let description = document.describe();
    let pages = document.pages();
    let drawn = (0..description.pages.min(pe_preview::limits::MAX_PAGES))
        .map(|index| pages.render(index).map(|p| (p.width, p.height, p.mime)))
        .collect();
    Ok((description.pages, description.title, drawn))
}

#[test]
fn ordinary_pdf_files() {
    let (pages, title, drawn) = pdf_pages("invoice.pdf").unwrap();
    assert_eq!((pages, title.as_deref()), (1, Some("Invoice 2026-116")));
    assert_eq!(drawn, [Ok((1240, 1754, Mime::Png))]);

    let (pages, _, drawn) = pdf_pages("letter-two-pages.pdf").unwrap();
    assert_eq!(pages, 2);
    assert_eq!(drawn, [Ok((1240, 1605, Mime::Png)), Ok((1240, 1605, Mime::Png))]);

    // 40 pages: five drawn, the count told
    let (pages, title, drawn) = pdf_pages("manual-40-pages.pdf").unwrap();
    assert_eq!((pages, title.as_deref()), (40, Some("Manual")));
    assert_eq!(drawn.len(), 5);
    assert!(drawn.iter().all(|page| *page == Ok((1240, 1754, Mime::Png))));

    // a receipt roll ten times taller than wide: its top part, the long side at the limit
    let (_, _, drawn) = pdf_pages("receipt-roll.pdf").unwrap();
    assert_eq!(drawn, [Ok((512, 2048, Mime::Png))]);
}

#[test]
fn encrypted_pdf_files() {
    // printing allowed, no password to open (AES-256 and RC4): drawn
    for name in ["encrypted-empty-password.pdf", "encrypted-rc4-empty-password.pdf"] {
        let (pages, title, drawn) = pdf_pages(name).unwrap();
        assert_eq!((pages, title.as_deref()), (1, Some("Invoice 2026-116")), "{name}");
        assert_eq!(drawn, [Ok((1240, 1754, Mime::Png))], "{name}");
    }
    // a password to open: a tile that says so
    assert_eq!(pdf_pages("encrypted-password.pdf").unwrap_err(), Refusal::Password);
}

#[test]
fn broken_pdf_files() {
    // cut short: the cross-reference table is rebuilt, the page drawn as far as it goes
    let (pages, _, drawn) = pdf_pages("truncated.pdf").unwrap();
    assert_eq!(pages, 1);
    assert!(drawn[0].is_ok());
    assert_eq!(pdf_pages("header-only.pdf").unwrap_err(), Refusal::Unreadable);
    // a page of 1e30 points is no page
    assert_eq!(pdf_pages("mediabox-huge.pdf").unwrap_err(), Refusal::Unreadable);
    // a page tree that is its own kid: its one page
    let (pages, _, drawn) = pdf_pages("page-tree-cycle.pdf").unwrap();
    assert_eq!(pages, 1);
    assert!(drawn[0].is_ok());
}

#[test]
fn hostile_pdf_files_are_bounded() {
    // a 1 by 14,400 point page: its top four widths
    let (_, _, drawn) = pdf_pages("mediabox-thread.pdf").unwrap();
    assert_eq!(drawn, [Ok((512, 2048, Mime::Png))]);
    // what would make hayro allocate without limit is measured first and not drawn
    // and what hayro reads that flate2 does not, inline pictures, and pictures whose codec says a larger size than
    // their dictionary (before, these took 290 MB, 425 MB, 1.2 GB and 4.8 GB)
    for name in [
        "flate-bomb.pdf",
        "image-60000.pdf",
        "path-bomb.pdf",
        "lenient-flate-bomb.pdf",
        "inline-image-bomb.pdf",
        "ccitt-columns.pdf",
        "jpx-siz.pdf",
        "jbig2-page.pdf",
    ] {
        let started = Instant::now();
        let (_, _, drawn) = pdf_pages(name).unwrap();
        assert_eq!(drawn, [Err(Refusal::TooLarge)], "{name}");
        // a bound on the work, generous for unoptimized builds on slow runners: what it guards is that the meter stops
        // at its cap rather than inflating the whole bomb
        assert!(started.elapsed() < Duration::from_secs(15), "{name} measured quickly");
    }
    // nesting and a form that draws itself: drawn, bounded by hayro's own depth limits
    for name in ["deep-content.pdf", "xobject-self.pdf"] {
        let (_, _, drawn) = pdf_pages(name).unwrap();
        assert!(drawn[0].is_ok(), "{name}");
    }
    // scripts, a launch action and a link: a picture of the page, nothing run or followed
    let (_, _, drawn) = pdf_pages("scripts-and-actions.pdf").unwrap();
    assert_eq!(drawn, [Ok((1240, 1755, Mime::Png))]);
}

#[test]
fn hostile_pictures_are_refused_from_their_headers() {
    for name in [
        "png-100000.png",
        "png-16bit-16384.png",
        "bmp-50000.bmp",
        "tiff-100000.tif",
    ] {
        assert_eq!(picture::render(&read(name)), Err(Refusal::TooLarge), "{name}");
        assert_eq!(picture::describe(&read(name)).unwrap_err(), Refusal::TooLarge, "{name}");
    }
    // a WebP whose EXIF chunk says 4 GB (image-webp would allocate that before reading it): found by fuzzing
    assert_eq!(picture::render(&read("webp-exif-4gb.webp")), Err(Refusal::Unreadable));
    // the decoder refuses a frame of 65,000 by 65,000 itself
    assert!(picture::render(&read("jpeg-65000.jpg")).is_err());
}

#[test]
fn heic_and_avif_are_tiles() {
    for name in ["photo.heic", "photo.avif"] {
        assert_eq!(pe_preview::kind_of(&read(name)), None, "{name}");
    }
    assert_eq!(pe_preview::kind_of(&read("invoice.pdf")), Some(Kind::Pdf));
    // named on their tiles by what they are
    use pe_preview::{NotDrawn, not_drawn};
    assert_eq!(not_drawn(&read("photo.heic")), Some(NotDrawn::Heic));
    assert_eq!(not_drawn(&read("photo.avif")), Some(NotDrawn::Avif));
    assert_eq!(not_drawn(b"\xff\x0a\x00\x01"), Some(NotDrawn::JpegXl));
    assert_eq!(not_drawn(b"\0\0\0\x0cJXL \r\n\x87\n\0\0"), Some(NotDrawn::JpegXl));
    assert_eq!(NotDrawn::JpegXl.name(), "JPEG XL");
    assert_eq!(not_drawn(&read("invoice.pdf")), None);
    // an ISO media file of another brand (a video), and boxes that end early
    assert_eq!(not_drawn(b"\0\0\0\x18ftypisom\0\0\0\0isommp41"), None);
    assert_eq!(not_drawn(b"\0\0\0\x18ftyp"), None);
    assert_eq!(not_drawn(b"\0\0\0\x10ftypmif1\0\0\0\0"), Some(NotDrawn::Heic));
    assert_eq!(not_drawn(b""), None);
}

/// The forms of xobject-laughs.pdf draw each other 2^40 times: hayro never finishes. The watchdog abandons it, the
/// next PDF is not drawn, and the file is refused from then on
#[test]
fn a_pdf_that_never_finishes_is_abandoned() {
    let (sender, outcomes) = mpsc::channel();
    let sender = std::sync::Mutex::new(sender);
    let previewer = Previewer::new(
        Settings {
            page_time: Duration::from_millis(500),
            ..Settings::default()
        },
        move |outcome| {
            let _ = sender.lock().unwrap().send(outcome);
        },
    );
    let request = |attachment, file| Request {
        owner: 1,
        attachment,
        file,
        about: String::new(),
        pages: 5,
        keep: true,
        asked: false,
        inline: false,
    };
    let wait = |attachment| {
        let mut refused = None;
        loop {
            let outcome: Outcome = outcomes.recv_timeout(Duration::from_secs(10)).unwrap();
            match outcome.what {
                What::Refused { reason, .. } => refused = Some(reason),
                What::Done if outcome.attachment == attachment => return refused,
                _ => {}
            }
        }
    };
    let started = Instant::now();
    previewer.request(request(0, read("xobject-laughs.pdf")));
    assert_eq!(wait(0), Some(Refusal::TimedOut));
    assert!(started.elapsed() < Duration::from_secs(5));
    previewer.request(request(1, read("invoice.pdf")));
    assert_eq!(wait(1), Some(Refusal::Off));
}
