//! Previews of a message's attachments (docs/attachment-preview-plan.md): the pictures and the first pages of the PDF
//! files a message carries, drawn by pe-preview on its render thread, never on a window's thread or the core's async
//! threads. The message's source is read and parsed on a thread of the core's blocking pool; what comes of each file
//! is kept here under the request ([`Core::previews_start`]) until it is cancelled, and announced by
//! [`Event::PreviewReady`]. The reading pane takes it with [`Core::preview_file`].
//!
//! The crash markers and the list of files never drawn again are kept in `previews` beside the store. A marker left
//! behind means a file ended the app while it was drawn: the core then turns PDF previews off (a sender could change
//! a byte of the file for each message and end the app once a message), says so ([`Event::PdfPreviewsOff`],
//! [`Core::previews_notice`]) until the user turns them on again ([`Core::set_pdf_previews`]). Pictures stay on:
//! their decoders have hard limits.

use std::collections::{BTreeMap, HashMap};
use std::path::{Path, PathBuf};
use std::sync::atomic::Ordering;
use std::sync::{Arc, Mutex, MutexGuard, OnceLock};

use pe_i18n::{Text, tr, tr_args};
use pe_preview::{Outcome, Previewer, Request, Settings, What};
use pe_store::{FolderId, Store};

pub use pe_preview::limits::MAX_PAGES as PREVIEW_PAGES;
pub use pe_preview::{Description as PreviewDescription, Mime as PreviewMime, Picture, Refusal as PreviewRefusal};

use crate::connections::Connection;
use crate::{Core, Event, EventSink, Result, view};

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

/// The folder of the crash markers, beside the store at `store_path`
pub(crate) fn markers_dir(store_path: &Path) -> Option<PathBuf> {
    store_path.parent().map(|dir| dir.join("previews"))
}

/// At the start: when the app ended while a file was drawn (a crash marker was left behind), PDF previews are turned
/// off in `store`. Whether they were (the caller then announces it)
pub(crate) fn check_crash_markers(store_path: &Path, store: &Store) -> bool {
    let Some(dir) = markers_dir(store_path) else {
        return false;
    };
    if pe_preview::marker::left_behind(&dir) == 0 || !store.pdf_previews().unwrap_or(true) {
        return false;
    }
    store.set_pdf_previews(false).is_ok() && store.set_pdf_previews_crashed(true).is_ok()
}

/// What a tile says of a file without a preview, when the reason is the user's to change: PDF previews turned off
pub fn refusal_text(reason: &PreviewRefusal) -> Option<String> {
    matches!(reason, PreviewRefusal::Disabled).then(|| tr(Text::PreviewPdfOff))
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

    /// "Show PDF files in messages"
    pub fn pdf_previews(&self) -> Result<bool> {
        Ok(self.store().pdf_previews()?)
    }

    /// Turns PDF previews on or off; on again, the note that a PDF file ended the app is gone
    pub fn set_pdf_previews(&self, on: bool) -> Result<()> {
        {
            let store = self.store();
            store.set_pdf_previews(on)?;
            if on {
                store.set_pdf_previews_crashed(false)?;
            }
        }
        if let Some(previewer) = self.previews.previewer.get() {
            previewer.set_pdfs(on);
        }
        Ok(())
    }

    /// What the reading pane says where previews are shown, when PDF previews were turned off because a PDF file
    /// ended the app: why, and how to turn them on again. None otherwise
    pub fn previews_notice(&self) -> Option<String> {
        let store = self.store();
        let crashed = store.pdf_previews_crashed().unwrap_or(false) && !store.pdf_previews().unwrap_or(true);
        crashed.then(|| {
            let option = tr(Text::PreviewPdfOption);
            tr_args(Text::PreviewPdfOffCrashed, &[("option", (&option).into())])
        })
    }

    /// Reads the message once and hands its files to the render thread, on a thread of the blocking pool
    fn request_previews(&self, request: u64, folder: FolderId, uid: u64, attachments: &[usize]) {
        let found = {
            let store = self.store();
            // a decrypted part's previews are never kept in the cache
            let found = store
                .source(folder, uid)
                .ok()
                .flatten()
                .map(|raw| self.shown_decrypted(&store, raw));
            found.map(|(source, decrypted)| (source, !decrypted, store.pdf_previews().unwrap_or(true)))
        };
        let files = self.previews.files.clone();
        let events = self.events.clone();
        let Some((source, keep, pdfs)) = found else {
            for &attachment in attachments {
                not_drawn(&files, &events, request, attachment);
            }
            return;
        };
        let mut listed = view::attachments(&source);
        drop(source);
        let previewer = self.previewer(pdfs);
        for &attachment in attachments {
            if !lock(&files).contains_key(&(request, attachment)) {
                // cancelled meanwhile
                continue;
            }
            match listed.get_mut(attachment) {
                Some((_, bytes)) => previewer.request(Request {
                    owner: request,
                    attachment,
                    file: Arc::new(std::mem::take(bytes)),
                    about: format!("folder {folder}, message {uid}, attachment {attachment}"),
                    pages: PREVIEW_PAGES,
                    keep,
                }),
                None => not_drawn(&files, &events, request, attachment),
            }
        }
    }

    /// The render thread, started by the first preview (`pdfs`: the user's setting then)
    fn previewer(&self, pdfs: bool) -> &Previewer {
        self.previews.previewer.get_or_init(|| {
            let files = self.previews.files.clone();
            let events = self.events.clone();
            let settings = Settings {
                dir: markers_dir(&self.path),
                pdfs,
                ..Settings::default()
            };
            Previewer::new(settings, move |outcome| record(&files, &events, outcome))
        })
    }
}

/// A file that is not there (the message left the store, or has no such attachment): refused, and done
fn not_drawn(files: &Files, events: &EventSink, request: u64, attachment: usize) {
    let refused = What::Refused {
        page: None,
        reason: PreviewRefusal::Unreadable,
    };
    for what in [refused, What::Done] {
        record(
            files,
            events,
            Outcome {
                owner: request,
                attachment,
                what,
            },
        );
    }
}

/// Keeps what came of a file under its request (unless the request was cancelled) and announces it
fn record(
    files: &Files,
    events: &EventSink,
    Outcome {
        owner,
        attachment,
        what,
    }: Outcome,
) {
    {
        let mut files = lock(files);
        let Some(file) = files.get_mut(&(owner, attachment)) else {
            return;
        };
        match what {
            What::Described(description) => file.description = Some(description),
            What::Page(page, picture) => {
                file.pages.insert(page, Ok(picture));
            }
            What::Refused {
                page: Some(page),
                reason,
            } => {
                file.pages.insert(page, Err(reason));
            }
            What::Refused { page: None, reason } => file.refused = Some(reason),
            What::Done => file.done = true,
        }
    }
    events(Event::PreviewReady {
        request: owner,
        attachment,
    });
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
    pub(super) fn message() -> Vec<u8> {
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
    pub(super) fn finished(
        core: &Core,
        events: &Receiver<Event>,
        request: u64,
        attachments: &[usize],
    ) -> Vec<PreviewFile> {
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

#[cfg(test)]
mod crash_tests {
    use super::*;
    use crate::list_load::tests::opened;
    use std::time::{Duration, Instant};

    #[test]
    fn a_crash_marker_turns_pdf_previews_off_until_the_user_turns_them_on() {
        let dir = pe_testkit::TempDir::new("core-previews-crashed");
        let markers = dir.path().join("previews");
        std::fs::create_dir_all(&markers).unwrap();
        // the app ended while drawing this file
        std::fs::write(
            markers.join(format!("rendering-{}", "ab".repeat(32))),
            "Pdf\nmessage 3\n",
        )
        .unwrap();
        let (core, inbox, events) = opened(&dir, 1);
        let until = Instant::now() + Duration::from_secs(10);
        loop {
            match events.recv_timeout(until.saturating_duration_since(Instant::now())) {
                Ok(Event::PdfPreviewsOff) => break,
                Ok(_) => {}
                Err(error) => panic!("no PdfPreviewsOff: {error}"),
            }
        }
        assert!(!core.pdf_previews().unwrap());
        let notice = core.previews_notice().unwrap();
        assert!(notice.contains(&tr(Text::PreviewPdfOption)), "{notice}");

        // a PDF file is a tile that says why, a picture still draws
        core.store().set_source(inbox, 1, &super::tests::message()).unwrap();
        let request = core.previews_start(inbox, 1, vec![0, 1]).unwrap();
        let files = super::tests::finished(&core, &events, request, &[0, 1]);
        assert!(files[0].pages[&0].is_ok());
        assert_eq!(files[1].refused, Some(PreviewRefusal::Disabled));
        assert!(refusal_text(&PreviewRefusal::Disabled).is_some());

        // turned on again: the note is gone, PDF files draw
        core.set_pdf_previews(true).unwrap();
        assert_eq!(core.previews_notice(), None);
        let request = core.previews_start(inbox, 1, vec![1]).unwrap();
        let files = super::tests::finished(&core, &events, request, &[1]);
        assert!(files[0].pages[&0].is_ok());
    }

    #[test]
    fn no_marker_leaves_pdf_previews_on() {
        let dir = pe_testkit::TempDir::new("core-previews-no-crash");
        let (core, ..) = opened(&dir, 1);
        assert!(core.pdf_previews().unwrap());
        assert_eq!(core.previews_notice(), None);
    }
}
