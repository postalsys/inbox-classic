//! Previews of a message's attachments (docs/attachment-preview-plan.md): the pictures and the first pages of the PDF
//! files a message carries, drawn by pe-preview on its render thread, never on a window's thread or the core's async
//! threads. The message's source is read and parsed on a thread of the core's blocking pool; what comes of each file
//! is kept here under the request ([`Core::previews_start`]) until it is cancelled, and announced by
//! [`Event::PreviewReady`]. The reading pane takes it with [`Core::preview_file`].
//!
//! The crash markers and the list of files never drawn again are kept in `previews` beside the store.

use std::collections::{BTreeMap, HashMap};
use std::sync::atomic::Ordering;
use std::sync::{Arc, Mutex, MutexGuard, OnceLock};

use pe_preview::{Outcome, Previewer, Request, Settings};
use pe_store::FolderId;

pub use pe_preview::limits::MAX_PAGES as PREVIEW_PAGES;
pub use pe_preview::{Description as PreviewDescription, Mime as PreviewMime, Picture, Refusal as PreviewRefusal};

use crate::connections::Connection;
use crate::{Core, Event, EventSink, Result, protect, view};

/// What came of one file's previews so far
#[derive(Debug, Clone, Default, PartialEq, Eq)]
pub struct PreviewFile {
    /// Its size or pages, before they are drawn
    pub description: Option<Arc<PreviewDescription>>,
    /// The whole file has no preview: a tile, and why
    pub refused: Option<PreviewRefusal>,
    /// Each page (a picture's one) drawn, or why not
    pub pages: BTreeMap<usize, std::result::Result<Arc<Picture>, PreviewRefusal>>,
    /// Nothing more comes
    pub done: bool,
}

type Files = Arc<Mutex<HashMap<(u64, usize), PreviewFile>>>;

#[derive(Default)]
pub(crate) struct Previews {
    /// Started with the first preview asked for
    previewer: OnceLock<Previewer>,
    /// The files of each request still wanted, by request and attachment
    files: Files,
}

fn lock(files: &Files) -> MutexGuard<'_, HashMap<(u64, usize), PreviewFile>> {
    files.lock().unwrap_or_else(|p| p.into_inner())
}

impl Core {
    /// Draws the previews of the listed attachments `attachments` (their indexes in [`crate::MessageView`]'s list) of
    /// a message in the background: each file described, then its pages (at most [`PREVIEW_PAGES`]), each step
    /// announced by [`Event::PreviewReady`] with the request this returns. A file that is not a picture or PDF the
    /// core reads is refused ([`PreviewRefusal::Unsupported`]); so is the whole request when the message is not in
    /// the store. The previews of an encrypted message are not kept once the request is cancelled.
    pub fn previews_start(self: &Arc<Self>, folder: FolderId, uid: u64, attachments: Vec<usize>) -> Result<u64> {
        let request = self.next_request.fetch_add(1, Ordering::Relaxed);
        {
            let mut files = lock(&self.previews.files);
            for &attachment in &attachments {
                files.insert((request, attachment), PreviewFile::default());
            }
        }
        let work = self.in_background(Connection::Reads, move |core| {
            core.request_previews(request, folder, uid, &attachments)
        });
        self.runtime()?.spawn(work);
        Ok(request)
    }

    /// What came of attachment `attachment` of the previews `request` so far; None for a request cancelled, or an
    /// attachment it did not ask for
    pub fn preview_file(&self, request: u64, attachment: usize) -> Option<PreviewFile> {
        lock(&self.previews.files).get(&(request, attachment)).cloned()
    }

    /// Forgets the previews `request` (the message is no longer shown): what still waits is not drawn, and the
    /// pixels its previews used are free for the next view
    pub fn previews_cancel(&self, request: u64) {
        lock(&self.previews.files).retain(|(r, _), _| *r != request);
        if let Some(previewer) = self.previews.previewer.get() {
            previewer.cancel(request);
        }
    }

    /// Reads the message once and hands its files to the render thread, on a thread of the blocking pool
    fn request_previews(&self, request: u64, folder: FolderId, uid: u64, attachments: &[usize]) {
        let found = {
            let store = self.store();
            store.source(folder, uid).ok().flatten().map(|raw| {
                // a decrypted part's previews are never kept in the cache
                let keep = !protect::has_encrypted(&raw);
                (self.shown(&store, raw), keep)
            })
        };
        let files = self.previews.files.clone();
        let events = self.events.clone();
        let Some((source, keep)) = found else {
            for &attachment in attachments {
                not_drawn(&files, &events, request, attachment);
            }
            return;
        };
        let listed = view::attachments(&source);
        let previewer = self.previewer();
        for &attachment in attachments {
            if !lock(&files).contains_key(&(request, attachment)) {
                // cancelled meanwhile
                continue;
            }
            match listed.get(attachment) {
                Some((_, bytes)) => previewer.request(Request {
                    owner: request,
                    attachment,
                    file: Arc::new(bytes.clone()),
                    about: format!("folder {folder}, message {uid}, attachment {attachment}"),
                    pages: PREVIEW_PAGES,
                    keep,
                }),
                None => not_drawn(&files, &events, request, attachment),
            }
        }
    }

    /// The render thread, started by the first preview
    fn previewer(&self) -> &Previewer {
        self.previews.previewer.get_or_init(|| {
            let files = self.previews.files.clone();
            let events = self.events.clone();
            let settings = Settings {
                dir: self.path.parent().map(|dir| dir.join("previews")),
                ..Settings::default()
            };
            Previewer::new(settings, move |outcome| record(&files, &events, outcome))
        })
    }
}

/// A file that is not there (the message left the store, or has no such attachment): refused, and done
fn not_drawn(files: &Files, events: &EventSink, request: u64, attachment: usize) {
    let refused = Outcome::Refused {
        owner: request,
        attachment,
        page: None,
        reason: PreviewRefusal::Unreadable,
    };
    record(files, events, refused);
    record(
        files,
        events,
        Outcome::Done {
            owner: request,
            attachment,
        },
    );
}

/// Keeps what came of a file under its request (unless the request was cancelled) and announces it
fn record(files: &Files, events: &EventSink, outcome: Outcome) {
    let (request, attachment) = match &outcome {
        Outcome::Described { owner, attachment, .. }
        | Outcome::Page { owner, attachment, .. }
        | Outcome::Refused { owner, attachment, .. }
        | Outcome::Done { owner, attachment } => (*owner, *attachment),
    };
    {
        let mut files = lock(files);
        let Some(file) = files.get_mut(&(request, attachment)) else {
            return;
        };
        match outcome {
            Outcome::Described { description, .. } => file.description = Some(description),
            Outcome::Page { page, picture, .. } => {
                file.pages.insert(page, Ok(picture));
            }
            Outcome::Refused {
                page: Some(page),
                reason,
                ..
            } => {
                file.pages.insert(page, Err(reason));
            }
            Outcome::Refused { page: None, reason, .. } => file.refused = Some(reason),
            Outcome::Done { .. } => file.done = true,
        }
    }
    events(Event::PreviewReady { request, attachment });
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::list_load::tests::opened;
    use base64::Engine;
    use std::sync::mpsc::Receiver;
    use std::time::{Duration, Instant};

    const INVOICE: &[u8] = include_bytes!("../../pe-preview/tests/files/invoice.pdf");

    /// A message with a PNG, a PDF file and a text file attached
    fn message() -> Vec<u8> {
        let png = {
            let picture = image::RgbImage::from_pixel(64, 32, image::Rgb([200, 30, 30]));
            let mut bytes = Vec::new();
            image::DynamicImage::ImageRgb8(picture)
                .write_to(&mut std::io::Cursor::new(&mut bytes), image::ImageFormat::Png)
                .unwrap();
            bytes
        };
        let base64 = |bytes: &[u8]| base64::engine::general_purpose::STANDARD.encode(bytes);
        format!(
            "From: Ann <ann@example.com>\r\nTo: a@example.com\r\nSubject: Photos\r\nMIME-Version: 1.0\r\n\
             Content-Type: multipart/mixed; boundary=b\r\n\r\n--b\r\nContent-Type: text/plain\r\n\r\nSee them.\r\n\
             --b\r\nContent-Type: image/png; name=red.png\r\nContent-Disposition: attachment; filename=red.png\r\n\
             Content-Transfer-Encoding: base64\r\n\r\n{}\r\n\
             --b\r\nContent-Type: application/pdf; name=invoice.pdf\r\nContent-Disposition: attachment; filename=invoice.pdf\r\n\
             Content-Transfer-Encoding: base64\r\n\r\n{}\r\n\
             --b\r\nContent-Type: text/plain; name=notes.txt\r\nContent-Disposition: attachment; filename=notes.txt\r\n\r\n\
             the notes\r\n--b--\r\n",
            base64(&png),
            base64(INVOICE)
        )
        .into_bytes()
    }

    /// The files of `request` once each is done
    fn finished(core: &Core, events: &Receiver<Event>, request: u64, attachments: &[usize]) -> Vec<PreviewFile> {
        let until = Instant::now() + Duration::from_secs(20);
        loop {
            let files: Vec<_> = attachments
                .iter()
                .map(|&a| core.preview_file(request, a).unwrap())
                .collect();
            if files.iter().all(|f| f.done) {
                return files;
            }
            match events.recv_timeout(until.saturating_duration_since(Instant::now())) {
                Ok(_) => {}
                Err(error) => panic!("previews not done: {error}"),
            }
        }
    }

    #[test]
    fn a_message_s_pictures_and_pdf_pages_are_drawn() {
        let dir = pe_testkit::TempDir::new("core-previews");
        let (core, inbox, events) = opened(&dir, 1);
        core.store().set_source(inbox, 1, &message()).unwrap();
        let request = core.previews_start(inbox, 1, vec![0, 1, 2, 7]).unwrap();
        let files = finished(&core, &events, request, &[0, 1, 2, 7]);

        let png = &files[0];
        assert_eq!(png.description.as_ref().unwrap().sizes, [Some((64, 32))]);
        let picture = png.pages[&0].as_ref().unwrap();
        assert_eq!(
            (picture.width, picture.height, picture.mime),
            (64, 32, PreviewMime::Png)
        );

        let pdf = &files[1];
        let description = pdf.description.as_ref().unwrap();
        assert_eq!(
            (description.pages, description.title.as_deref()),
            (1, Some("Invoice 2026-116"))
        );
        assert!(pdf.pages[&0].is_ok());

        assert_eq!(files[2].refused, Some(PreviewRefusal::Unsupported));
        assert_eq!(files[3].refused, Some(PreviewRefusal::Unreadable));

        // the crash markers' folder is beside the store, and no marker is left
        let markers = dir.path().join("previews");
        assert!(markers.is_dir());
        assert!(
            std::fs::read_dir(&markers)
                .unwrap()
                .flatten()
                .all(|e| !e.file_name().to_string_lossy().starts_with("rendering-"))
        );

        core.previews_cancel(request);
        assert_eq!(core.preview_file(request, 0), None);
    }

    #[test]
    fn a_message_not_in_the_store_is_refused() {
        let dir = pe_testkit::TempDir::new("core-previews-missing");
        let (core, inbox, events) = opened(&dir, 1);
        let request = core.previews_start(inbox, 1, vec![0]).unwrap();
        let files = finished(&core, &events, request, &[0]);
        assert_eq!(files[0].refused, Some(PreviewRefusal::Unreadable));
    }
}
