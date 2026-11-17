//! The render thread: its queue, the watchdog that abandons a render over its time, the crash markers, the cache,
//! cancelling and the pixel budget, with fake engines that hang, panic or count

use std::path::PathBuf;
use std::sync::atomic::{AtomicBool, AtomicUsize, Ordering};
use std::sync::mpsc::{self, Receiver};
use std::sync::{Arc, Mutex};
use std::time::{Duration, Instant};

use pe_preview::limits::{MAX_FILE, MESSAGE_PIXELS};
use pe_preview::{Description, Engine, Kind, Mime, Outcome, Picture, Previewer, Refusal, Request, Settings, Step};

/// A PDF file's start: enough for the kind to be told
const PDF: &[u8] = b"%PDF-1.7\n";
/// A PNG's signature
const PNG: &[u8] = b"\x89PNG\r\n\x1a\n";

fn file(start: &[u8], tag: &str) -> Arc<Vec<u8>> {
    let mut bytes = start.to_vec();
    bytes.extend_from_slice(tag.as_bytes());
    Arc::new(bytes)
}

fn request(owner: u64, attachment: usize, file: Arc<Vec<u8>>) -> Request {
    Request {
        owner,
        attachment,
        file,
        about: format!("message {owner}, attachment {attachment}"),
        pages: 5,
        keep: true,
    }
}

fn picture(width: u32, height: u32) -> Picture {
    Picture {
        mime: Mime::Png,
        bytes: vec![1; 100],
        width,
        height,
    }
}

/// A fake engine: a file whose bytes end in "hang" never finishes (until released), "panic" panics, anything else
/// gives a description and one page per `pages` of `size`
struct Fake {
    runs: AtomicUsize,
    release: AtomicBool,
    size: (u32, u32),
    pages: usize,
}

impl Fake {
    fn new() -> Arc<Fake> {
        Arc::new(Fake {
            runs: AtomicUsize::new(0),
            release: AtomicBool::new(false),
            size: (100, 50),
            pages: 1,
        })
    }
}

impl Engine for Fake {
    fn run(&self, kind: Kind, file: &Arc<Vec<u8>>, pages: usize, budget: u64, emit: &mut dyn FnMut(Step) -> bool) {
        self.runs.fetch_add(1, Ordering::SeqCst);
        if !emit(Step::Started(kind)) {
            return;
        }
        if file.ends_with(b"hang") {
            while !self.release.load(Ordering::SeqCst) {
                std::thread::sleep(Duration::from_millis(5));
            }
            return;
        }
        if file.ends_with(b"panic") {
            panic!("a decoder's bug");
        }
        let description = Description {
            kind,
            pages: self.pages,
            title: None,
            sizes: vec![Some(self.size); self.pages.min(5)],
        };
        if !emit(Step::Described(Ok(description))) {
            return;
        }
        let mut left = budget;
        for page in 0..pages.min(self.pages) {
            let pixels = u64::from(self.size.0) * u64::from(self.size.1);
            if pixels > left {
                emit(Step::Page(page, Err(Refusal::OverBudget)));
                continue;
            }
            left -= pixels;
            if !emit(Step::Started(kind)) {
                return;
            }
            std::thread::sleep(Duration::from_millis(2));
            if !emit(Step::Page(page, Ok(picture(self.size.0, self.size.1)))) {
                return;
            }
        }
    }
}

fn settings(engine: Arc<dyn Engine>, dir: Option<PathBuf>) -> Settings {
    Settings {
        dir,
        page_time: Duration::from_millis(300),
        picture_time: Duration::from_millis(300),
        engine,
        ..Settings::default()
    }
}

fn start(settings: Settings) -> (Previewer, Receiver<Outcome>) {
    let (sender, outcomes) = mpsc::channel();
    let sender = Mutex::new(sender);
    let previewer = Previewer::new(settings, move |outcome| {
        let _ = sender.lock().unwrap().send(outcome);
    });
    (previewer, outcomes)
}

/// The outcomes of one file, up to its Done
fn until_done(outcomes: &Receiver<Outcome>, owner: u64, attachment: usize) -> Vec<Outcome> {
    let mut seen = Vec::new();
    loop {
        let outcome = outcomes
            .recv_timeout(Duration::from_secs(10))
            .expect("an outcome in time");
        let done = matches!(outcome, Outcome::Done { owner: o, attachment: a } if o == owner && a == attachment);
        seen.push(outcome);
        if done {
            return seen;
        }
    }
}

fn refusal(outcomes: &[Outcome]) -> Option<(Option<usize>, Refusal)> {
    outcomes.iter().find_map(|o| match o {
        Outcome::Refused { page, reason, .. } => Some((*page, reason.clone())),
        _ => None,
    })
}

fn pages(outcomes: &[Outcome]) -> Vec<usize> {
    outcomes
        .iter()
        .filter_map(|o| match o {
            Outcome::Page { page, .. } => Some(*page),
            _ => None,
        })
        .collect()
}

fn dir(name: &str) -> PathBuf {
    let dir = std::env::temp_dir().join(format!("pe-preview-test-{name}-{}", std::process::id()));
    let _ = std::fs::remove_dir_all(&dir);
    dir
}

#[test]
fn a_file_is_described_then_drawn_then_done() {
    let fake = Fake::new();
    let (previewer, outcomes) = start(settings(fake.clone(), None));
    previewer.request(request(1, 0, file(PNG, "a")));
    let seen = until_done(&outcomes, 1, 0);
    assert!(matches!(&seen[0], Outcome::Described { description, .. } if description.sizes == [Some((100, 50))]));
    assert_eq!(pages(&seen), [0]);
    assert_eq!(seen.len(), 3);
}

#[test]
fn not_a_picture_or_pdf_is_refused_without_drawing() {
    let fake = Fake::new();
    let (previewer, outcomes) = start(settings(fake.clone(), None));
    // HEIC: a tile
    previewer.request(request(1, 0, Arc::new(b"\0\0\0\x18ftypheic\0\0\0\0mif1heic".to_vec())));
    assert_eq!(
        refusal(&until_done(&outcomes, 1, 0)),
        Some((None, Refusal::Unsupported))
    );
    let mut huge = PDF.to_vec();
    huge.resize(MAX_FILE + 1, b' ');
    previewer.request(request(1, 1, Arc::new(huge)));
    assert_eq!(refusal(&until_done(&outcomes, 1, 1)), Some((None, Refusal::TooLarge)));
    assert_eq!(fake.runs.load(Ordering::SeqCst), 0);
}

#[test]
fn the_cache_answers_a_file_drawn_before() {
    let fake = Fake::new();
    let (previewer, outcomes) = start(settings(fake.clone(), None));
    let shared = file(PNG, "same");
    previewer.request(request(1, 0, shared.clone()));
    until_done(&outcomes, 1, 0);
    // the same bytes in another message: no render
    previewer.request(request(2, 3, shared));
    let seen = until_done(&outcomes, 2, 3);
    assert_eq!(pages(&seen), [0]);
    assert_eq!(fake.runs.load(Ordering::SeqCst), 1);
    // a decrypted part's file is never kept, and so drawn again
    let mut private = request(3, 0, file(PNG, "private"));
    private.keep = false;
    previewer.request(private.clone());
    until_done(&outcomes, 3, 0);
    previewer.request(private);
    until_done(&outcomes, 3, 0);
    assert_eq!(fake.runs.load(Ordering::SeqCst), 3);
}

#[test]
fn a_hung_pdf_is_abandoned_and_pdfs_stop_for_the_session() {
    let fake = Fake::new();
    let markers = dir("hung-pdf");
    let (previewer, outcomes) = start(settings(fake.clone(), Some(markers.clone())));
    let hung = file(PDF, "hang");
    let started = Instant::now();
    previewer.request(request(1, 0, hung.clone()));
    let seen = until_done(&outcomes, 1, 0);
    assert_eq!(refusal(&seen), Some((None, Refusal::TimedOut)));
    assert!(
        started.elapsed() < Duration::from_secs(3),
        "abandoned after its time, not waited for"
    );
    // a picture still draws, on a new thread: the old one still hangs
    previewer.request(request(1, 1, file(PNG, "after")));
    assert_eq!(pages(&until_done(&outcomes, 1, 1)), [0]);
    // no PDF is drawn for the rest of the session
    previewer.request(request(1, 2, file(PDF, "another")));
    assert_eq!(refusal(&until_done(&outcomes, 1, 2)), Some((None, Refusal::Off)));
    fake.release.store(true, Ordering::SeqCst);
    drop(previewer);
    // and the file that hung is never drawn again, in the next session too
    let (previewer, outcomes) = start(settings(Fake::new(), Some(markers.clone())));
    previewer.request(request(1, 0, hung));
    assert_eq!(refusal(&until_done(&outcomes, 1, 0)), Some((None, Refusal::Crashed)));
    let _ = std::fs::remove_dir_all(markers);
}

#[test]
fn a_hung_picture_leaves_pdfs_on_and_two_hangs_stop_everything() {
    let fake = Fake::new();
    let (previewer, outcomes) = start(settings(fake.clone(), None));
    previewer.request(request(1, 0, file(PNG, "1hang")));
    assert_eq!(refusal(&until_done(&outcomes, 1, 0)), Some((None, Refusal::TimedOut)));
    previewer.request(request(1, 1, file(PDF, "fine")));
    assert_eq!(pages(&until_done(&outcomes, 1, 1)), [0]);
    previewer.request(request(1, 2, file(PNG, "2hang")));
    assert_eq!(refusal(&until_done(&outcomes, 1, 2)), Some((None, Refusal::TimedOut)));
    // two threads abandoned: each may keep a core busy, so nothing more is drawn
    previewer.request(request(1, 3, file(PNG, "fine too")));
    assert_eq!(refusal(&until_done(&outcomes, 1, 3)), Some((None, Refusal::Off)));
    fake.release.store(true, Ordering::SeqCst);
}

#[test]
fn a_panic_is_a_tile_and_the_next_file_draws() {
    let fake = Fake::new();
    let markers = dir("panic");
    let (previewer, outcomes) = start(settings(fake.clone(), Some(markers.clone())));
    previewer.request(request(1, 0, file(PNG, "panic")));
    assert_eq!(refusal(&until_done(&outcomes, 1, 0)), Some((None, Refusal::Unreadable)));
    previewer.request(request(1, 1, file(PNG, "fine")));
    assert_eq!(pages(&until_done(&outcomes, 1, 1)), [0]);
    // a caught panic is no crash: its marker is gone
    let left: Vec<_> = std::fs::read_dir(&markers)
        .unwrap()
        .flatten()
        .filter(|e| e.file_name().to_string_lossy().starts_with("rendering-"))
        .collect();
    assert!(left.is_empty());
    let _ = std::fs::remove_dir_all(markers);
}

#[test]
fn a_marker_left_behind_makes_its_file_a_tile() {
    let markers = dir("left-behind");
    std::fs::create_dir_all(&markers).unwrap();
    let crashed = file(PDF, "ended the app");
    // what the app left when it ended in the middle of drawing this file
    let key = pe_preview::key_of(&crashed);
    std::fs::write(
        markers.join(format!("rendering-{}", key.as_str())),
        "message 4, part 2\n",
    )
    .unwrap();
    let fake = Fake::new();
    let (previewer, outcomes) = start(settings(fake.clone(), Some(markers.clone())));
    previewer.request(request(1, 0, crashed));
    assert_eq!(refusal(&until_done(&outcomes, 1, 0)), Some((None, Refusal::Crashed)));
    assert_eq!(fake.runs.load(Ordering::SeqCst), 0);
    // other files draw
    previewer.request(request(1, 1, file(PDF, "fine")));
    assert_eq!(pages(&until_done(&outcomes, 1, 1)), [0]);
    let _ = std::fs::remove_dir_all(markers);
}

#[test]
fn cancel_drops_what_waits_and_stops_what_draws() {
    let fake = Arc::new(Fake {
        pages: 5,
        ..Arc::into_inner(Fake::new()).unwrap()
    });
    let (previewer, outcomes) = start(settings(fake.clone(), None));
    for attachment in 0..5 {
        previewer.request(request(7, attachment, file(PDF, &format!("doc {attachment}"))));
    }
    previewer.cancel(7);
    // what was not taken yet is gone; at most the one taken is done
    std::thread::sleep(Duration::from_millis(200));
    let done: Vec<_> = outcomes
        .try_iter()
        .filter(|o| matches!(o, Outcome::Done { .. }))
        .collect();
    assert!(done.len() <= 1, "{done:?}");
    assert!(fake.runs.load(Ordering::SeqCst) <= 1);
}

#[test]
fn the_message_budget_counts_every_preview() {
    // 5 pages of 4096 by 4096 pixels each: 16 MP, so 4 fit in the 64 MP budget
    let side = 4096;
    assert_eq!(MESSAGE_PIXELS / (side * side), 4);
    let fake = Arc::new(Fake {
        size: (side as u32, side as u32),
        pages: 5,
        ..Arc::into_inner(Fake::new()).unwrap()
    });
    let (previewer, outcomes) = start(settings(fake.clone(), None));
    previewer.request(request(1, 0, file(PDF, "big")));
    let seen = until_done(&outcomes, 1, 0);
    assert_eq!(pages(&seen), [0, 1, 2, 3]);
    assert_eq!(refusal(&seen), Some((Some(4), Refusal::OverBudget)));
    // another message has its own budget; the same message's next file has none left
    previewer.request(request(2, 0, file(PDF, "big")));
    assert_eq!(pages(&until_done(&outcomes, 2, 0)).len(), 4);
    previewer.request(request(1, 1, file(PDF, "big again")));
    assert!(pages(&until_done(&outcomes, 1, 1)).is_empty());
    // a message shown again after it was left starts over
    previewer.cancel(1);
    previewer.request(request(1, 2, file(PDF, "big")));
    assert_eq!(pages(&until_done(&outcomes, 1, 2)).len(), 4);
}

#[test]
fn describe_goes_ahead_of_the_queue_and_gives_up_in_time() {
    let fake = Fake::new();
    let (previewer, outcomes) = start(settings(fake.clone(), None));
    let description = previewer
        .describe(file(PNG, "header"), "message 1".into(), Duration::from_secs(5))
        .unwrap();
    assert_eq!(description.sizes, [Some((100, 50))]);
    // a file that hangs: the window waits only as long as it said
    let started = Instant::now();
    let answer = previewer.describe(file(PDF, "hang"), String::new(), Duration::from_millis(50));
    assert_eq!(answer, Err(Refusal::TimedOut));
    assert!(started.elapsed() < Duration::from_millis(250));
    fake.release.store(true, Ordering::SeqCst);
    drop(outcomes);
}

#[test]
fn the_real_engine_draws_a_picture_and_a_pdf() {
    let (previewer, outcomes) = start(Settings::default());
    let png = {
        let image = image::RgbaImage::from_pixel(300, 200, image::Rgba([10, 20, 30, 128]));
        let mut bytes = Vec::new();
        image::DynamicImage::ImageRgba8(image)
            .write_to(&mut std::io::Cursor::new(&mut bytes), image::ImageFormat::Png)
            .unwrap();
        Arc::new(bytes)
    };
    previewer.request(request(1, 0, png));
    let seen = until_done(&outcomes, 1, 0);
    let Some(Outcome::Page { picture, .. }) = seen.iter().find(|o| matches!(o, Outcome::Page { .. })) else {
        panic!("{seen:?}");
    };
    assert_eq!((picture.width, picture.height, picture.mime), (300, 200, Mime::Png));
    let pdf = std::fs::read(concat!(env!("CARGO_MANIFEST_DIR"), "/tests/files/invoice.pdf")).unwrap();
    previewer.request(request(1, 1, Arc::new(pdf)));
    let seen = until_done(&outcomes, 1, 1);
    assert!(
        matches!(&seen[0], Outcome::Described { description, .. } if description.pages == 1
        && description.title.as_deref() == Some("Invoice 2026-116"))
    );
    assert_eq!(pages(&seen), [0]);
}
