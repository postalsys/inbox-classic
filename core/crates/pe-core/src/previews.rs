//! Previews of a message's attachments (docs/attachment-preview-plan.md): the pictures and the first pages of the PDF
//! files a message carries, drawn by pe-preview on its render thread, never on a window's thread or the core's async
//! threads. The message's source is read and parsed on a thread of the core's blocking pool; what comes of each file
//! is kept here under the request ([`Core::previews_start`]) until it is cancelled, and announced by
//! [`Event::PreviewReady`]. The reading pane takes it with [`Core::preview_file`].
//!
//! The reading pane shows them after a message's text (`pe_html::PreviewSection`): the view chooses the files and
//! reads their sizes ([`section`]), and the document's pictures are addressed under a token of the view that the
//! core keeps while the view is shown ([`Core::preview_ask`], [`Core::previews_end`]). The apps' document servers ask
//! for a picture and answer the web view when [`Event::PreviewAnswered`] says it is there.
//!
//! The crash markers and the list of files never drawn again are kept in `previews` beside the store. A marker left
//! behind means a file ended the app while it was drawn: the core then turns PDF previews off (a sender could change
//! a byte of the file for each message and end the app once a message), says so ([`Event::PdfPreviewsOff`],
//! [`Core::previews_notice`]) until the user turns them on again ([`Core::set_pdf_previews`]). Pictures stay on:
//! their decoders have hard limits.

use std::collections::{BTreeMap, HashMap, VecDeque};
use std::path::{Path, PathBuf};
use std::sync::atomic::Ordering;
use std::sync::{Arc, Mutex, MutexGuard, OnceLock};
use std::time::{Duration, Instant};

use pe_i18n::{Text, tr, tr_args};
use pe_preview::{Outcome, Previewer, Request, Settings, What};
use pe_store::{FolderId, Store};

pub use pe_preview::limits::MAX_PAGES as PREVIEW_PAGES;
use pe_preview::limits::{DESCRIBE_WAIT, MAX_FILE, MAX_PREVIEWS};
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
    /// The views whose previews the windows show, oldest first
    shown: Mutex<VecDeque<Shown>>,
    /// The pictures the document servers asked for, and their answers
    asks: Asks,
}

/// How long a view waits for its files' sizes ([`DESCRIBE_WAIT`]); the tests wait longer, as an unoptimized build
/// on a busy runner reads a PDF file's page tree slowly
const DESCRIBE: Duration = if cfg!(test) {
    Duration::from_secs(20)
} else {
    DESCRIBE_WAIT
};

/// The most views whose previews are answered at once: a window that never ends a view's previews does not keep
/// every message it showed
const MAX_SHOWN: usize = 16;

/// Where the files of a view's previews are read from when their pictures are asked for
#[derive(Debug, Clone, PartialEq, Eq)]
pub(crate) enum PreviewSource {
    /// A message of the store
    Stored { folder: FolderId, uid: u64 },
    /// A message file opened in a window of its own
    File(Arc<Vec<u8>>),
}

/// A view whose previews a window shows
struct Shown {
    token: String,
    source: PreviewSource,
    /// The attachments shown, each with how many pictures
    files: Vec<(usize, usize)>,
    /// The request drawing them, once the first picture was asked for
    request: Option<u64>,
}

/// A picture a document server asked for, waiting to be drawn
struct Ask {
    id: u64,
    request: u64,
    attachment: usize,
    page: usize,
}

#[derive(Default)]
struct AskState {
    next: u64,
    waiting: Vec<Ask>,
    /// The answers not taken yet: a picture, or None for no picture (the server answers "not found")
    answers: HashMap<u64, Option<Arc<Picture>>>,
}

type Asks = Arc<Mutex<AskState>>;

fn lock_asks(asks: &Asks) -> MutexGuard<'_, AskState> {
    asks.lock().unwrap_or_else(|p| p.into_inner())
}

fn lock_shown(shown: &Mutex<VecDeque<Shown>>) -> MutexGuard<'_, VecDeque<Shown>> {
    shown.lock().unwrap_or_else(|p| p.into_inner())
}

/// How the view shows a message's pictures and PDF files after its text ([`Core::preview_plan`])
pub(crate) struct PreviewPlan<'a> {
    /// The core whose render thread reads the files' descriptions
    pub core: &'a Core,
    /// PDF files are drawn
    pub pdfs: bool,
    /// What the section says when PDF files are not drawn because one ended the app ([`Core::previews_notice`])
    pub notice: Option<String>,
}

/// The previews of a message's listed attachments, in the order of the strip: each picture, and the first pages of
/// each PDF file, with the sizes read before the document is shown (at most [`DESCRIBE_WAIT`] for them all), at most
/// [`MAX_PREVIEWS`] pictures in all. A file that is not a picture or PDF file by its name and by its content, or one
/// not described in time, has none.
pub(crate) fn section(message: &pe_mime::parser::Message, plan: &PreviewPlan) -> pe_html::PreviewSection {
    let until = Instant::now() + DESCRIBE;
    let mut files = Vec::new();
    let mut left = MAX_PREVIEWS;
    let mut pdf_left_out = false;
    for (index, attachment) in view::listed(&message.attachments).enumerate() {
        let Some(pdf) = previewed_as_pdf(attachment) else {
            continue;
        };
        if pdf && !plan.pdfs {
            pdf_left_out = true;
            continue;
        }
        let wait = until.saturating_duration_since(Instant::now());
        if left == 0 || wait.is_zero() {
            continue;
        }
        let file = Arc::new(attachment.content.clone());
        let Ok(description) = plan.core.preview_describe(plan.pdfs, file, wait) else {
            continue;
        };
        if let Some(file) = preview_file(index, attachment, pdf, &description, left) {
            left -= file.pages.len();
            files.push(file);
        }
    }
    pe_html::PreviewSection {
        token: pe_html::preview_token(),
        files,
        notice: plan.notice.clone().filter(|_| pdf_left_out),
    }
}

/// Whether an attachment has previews, a picture or a PDF file by its name and by its content, and not too large:
/// Some(true) for a PDF file, Some(false) for a picture
fn previewed_as_pdf(attachment: &pe_mime::parser::Attachment) -> Option<bool> {
    use crate::opening::FileKind;
    let content = &attachment.content;
    if content.len() > MAX_FILE {
        return None;
    }
    let kind = crate::opening::file_kind_of(&attachment.safe_filename(), &attachment.mime_type, content);
    match (kind, pe_preview::kind_of(content)) {
        (FileKind::Image, Some(pe_preview::Kind::Picture)) => Some(false),
        (FileKind::Pdf, Some(pe_preview::Kind::Pdf)) => Some(true),
        _ => None,
    }
}

/// The previews of one file as its description has them, at most `left` pictures; None when it has none
fn preview_file(
    index: usize,
    attachment: &pe_mime::parser::Attachment,
    pdf: bool,
    description: &PreviewDescription,
    left: usize,
) -> Option<pe_html::PreviewFile> {
    let name = attachment.display_filename();
    let pages: Vec<pe_html::PreviewPage> = description
        .sizes
        .iter()
        .enumerate()
        .take(PREVIEW_PAGES)
        .filter_map(|(page, size)| size.map(|size| (page, size)))
        .take(left)
        .map(|(page, (width, height))| {
            if !pdf {
                return pe_html::PreviewPage {
                    page,
                    width,
                    height,
                    alt: name.clone(),
                };
            }
            // a PDF page is drawn for a display of two pixels a point of CSS: half its pixels wide
            let alt = tr_args(
                Text::PreviewPageAlt,
                &[
                    ("name", (&name).into()),
                    ("page", (page + 1).into()),
                    ("count", description.pages.into()),
                ],
            );
            pe_html::PreviewPage {
                page,
                width: width.div_ceil(2),
                height: height.div_ceil(2),
                alt,
            }
        })
        .collect();
    if pages.is_empty() {
        return None;
    }
    let size = crate::format_size(attachment.content.len() as u64);
    let details = if pdf {
        tr_args(
            Text::PreviewPdfDetails,
            &[("count", description.pages.into()), ("size", (&size).into())],
        )
    } else {
        size
    };
    let more = (pdf && description.pages > pages.len())
        .then(|| tr_args(Text::PreviewMorePages, &[("count", description.pages.into())]));
    Some(pe_html::PreviewFile {
        attachment: index,
        content_id: attachment.content_id.clone(),
        paper: pdf,
        pages,
        name,
        details,
        more,
    })
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
        self.previews_start_from(PreviewSource::Stored { folder, uid }, attachments)
    }

    /// [`Core::previews_start`] of a message in the store or of a message file
    fn previews_start_from(self: &Arc<Self>, source: PreviewSource, attachments: Vec<usize>) -> Result<u64> {
        let request = self.next_request.fetch_add(1, Ordering::Relaxed);
        {
            let mut files = lock(&self.previews.files);
            for &attachment in &attachments {
                files.insert((request, attachment), PreviewFile::default());
            }
        }
        let work = self.in_background(Connection::Reads, move |core| {
            core.request_previews(request, &source, &attachments)
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

    /// The UI tests only (the apps' test switch): PDF previews turned off as after a PDF file ended the app, and
    /// [`Event::PdfPreviewsOff`] said, without ending the app
    pub fn pdf_previews_crashed_for_tests(&self) -> Result<()> {
        {
            let store = self.store();
            store.set_pdf_previews(false)?;
            store.set_pdf_previews_crashed(true)?;
        }
        if let Some(previewer) = self.previews.previewer.get() {
            previewer.set_pdfs(false);
        }
        self.post(Event::PdfPreviewsOff)
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
            let settings = pe_html::settings_words("reading", pe_html::Platform::current(), pe_i18n::language());
            tr_args(
                Text::PreviewPdfOffCrashed,
                &[("option", (&option).into()), ("settings", (&settings).into())],
            )
        })
    }

    /// Reads the message once and hands its files to the render thread, on a thread of the blocking pool
    fn request_previews(&self, request: u64, from: &PreviewSource, attachments: &[usize]) {
        let found = {
            let store = self.store();
            let pdfs = store.pdf_previews().unwrap_or(true);
            match from {
                // a decrypted part's previews are never kept in the cache
                PreviewSource::Stored { folder, uid } => store
                    .source(*folder, *uid)
                    .ok()
                    .flatten()
                    .map(|raw| self.shown_decrypted(&store, raw))
                    .map(|(source, decrypted)| (source, !decrypted, pdfs)),
                // a message file's previews are of files that are not encrypted (an encrypted message has none)
                PreviewSource::File(source) => Some((source.to_vec(), true, pdfs)),
            }
        };
        let about = match from {
            PreviewSource::Stored { folder, uid } => format!("folder {folder}, message {uid}"),
            PreviewSource::File(_) => "a message file".to_string(),
        };
        let files = self.previews.files.clone();
        let asks = self.previews.asks.clone();
        let events = self.events.clone();
        let Some((source, keep, pdfs)) = found else {
            for &attachment in attachments {
                not_drawn(&files, &asks, &events, request, attachment);
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
                    about: format!("{about}, attachment {attachment}"),
                    pages: PREVIEW_PAGES,
                    keep,
                }),
                None => not_drawn(&files, &asks, &events, request, attachment),
            }
        }
    }

    /// The render thread, started by the first preview (`pdfs`: the user's setting then)
    fn previewer(&self, pdfs: bool) -> &Previewer {
        self.previews.previewer.get_or_init(|| {
            let files = self.previews.files.clone();
            let asks = self.previews.asks.clone();
            let events = self.events.clone();
            let settings = Settings {
                dir: markers_dir(&self.path),
                pdfs,
                ..Settings::default()
            };
            Previewer::new(settings, move |outcome| record(&files, &asks, &events, outcome))
        })
    }

    /// Options' "Show attachments in messages": pictures and PDF files after a message's text, on until turned off
    pub fn show_previews(&self) -> bool {
        self.store().show_previews().unwrap_or(true)
    }

    /// Turns previews on or off, for the views built from now on
    pub fn set_show_previews(&self, on: bool) -> Result<()> {
        Ok(self.store().set_show_previews(on)?)
    }

    /// How a view built now shows the attachments after the text, None when the user turned that off; read on the
    /// thread that builds the view
    pub(crate) fn preview_plan(&self) -> Option<PreviewPlan<'_>> {
        if !self.show_previews() {
            return None;
        }
        Some(PreviewPlan {
            core: self,
            pdfs: self.pdf_previews().unwrap_or(true),
            notice: self.previews_notice(),
        })
    }

    /// A file's description for the view, read on the render thread ahead of the files waiting
    fn preview_describe(
        &self,
        pdfs: bool,
        file: Arc<Vec<u8>>,
        wait: Duration,
    ) -> std::result::Result<Arc<PreviewDescription>, PreviewRefusal> {
        self.previewer(pdfs).describe(file, "a message shown".to_string(), wait)
    }

    /// A view taken by a window: its previews answered from now on, until [`Core::previews_end`] (or until
    /// [`MAX_SHOWN`] newer views were taken)
    pub(crate) fn previews_shown(&self, view: &mut crate::MessageView) {
        let (Some(token), Some(source)) = (view.preview_token.clone(), view.preview_source.take()) else {
            return;
        };
        let files = std::mem::take(&mut view.preview_files);
        let gone = {
            let mut shown = lock_shown(&self.previews.shown);
            shown.push_back(Shown {
                token,
                source,
                files,
                request: None,
            });
            let over = shown.len().saturating_sub(MAX_SHOWN);
            shown.drain(..over).collect::<Vec<_>>()
        };
        for shown in gone {
            self.forget_shown(shown);
        }
    }

    /// The previews of a view no longer shown (its window shows another message, or closed): their pictures are not
    /// drawn or answered anymore, and a picture still asked for is answered with none
    pub fn previews_end(&self, token: &str) {
        let gone = {
            let mut shown = lock_shown(&self.previews.shown);
            let at = shown.iter().position(|shown| shown.token == token);
            at.and_then(|at| shown.remove(at))
        };
        if let Some(shown) = gone {
            self.forget_shown(shown);
        }
    }

    fn forget_shown(&self, shown: Shown) {
        let Some(request) = shown.request else {
            return;
        };
        self.previews_cancel(request);
        let mut ended = Vec::new();
        {
            let mut asks = lock_asks(&self.previews.asks);
            let AskState { waiting, answers, .. } = &mut *asks;
            waiting.retain(|ask| {
                if ask.request != request {
                    return true;
                }
                answers.insert(ask.id, None);
                ended.push(ask.id);
                false
            });
        }
        for ask in ended {
            let _ = self.post(Event::PreviewAnswered { ask });
        }
    }

    /// A document server asks for the picture at `address` (`/pv/<token>-<attachment>-<page>`, or the whole URL on the
    /// reading pane's origin): the ask to wait for, answered by [`Event::PreviewAnswered`] (never on the calling
    /// thread) and taken with [`Core::preview_answer`]. None for an address that is no picture of a view shown: the
    /// server answers "not found" at once. Quick, for the window thread: the picture is drawn on the render thread
    /// (the message read first, off the window thread)
    pub fn preview_ask(self: &Arc<Self>, address: &str) -> Option<u64> {
        let (token, attachment, page) = pe_html::parse_preview_address(address)?;
        let request = {
            let mut shown = lock_shown(&self.previews.shown);
            let view = shown.iter_mut().find(|shown| shown.token == token)?;
            let pages = view.files.iter().find(|(a, _)| *a == attachment)?.1;
            if page >= pages {
                return None;
            }
            match view.request {
                Some(request) => request,
                None => {
                    // every file of the view, in the order of the document, so the first picture comes first
                    let attachments = view.files.iter().map(|(a, _)| *a).collect();
                    let request = self.previews_start_from(view.source.clone(), attachments).ok()?;
                    view.request = Some(request);
                    request
                }
            }
        };
        let id = {
            let mut asks = lock_asks(&self.previews.asks);
            asks.next += 1;
            let id = asks.next;
            asks.waiting.push(Ask {
                id,
                request,
                attachment,
                page,
            });
            id
        };
        // drawn before (the cache, or an earlier ask of the same picture): answered now, on a worker thread
        if let Some(file) = self.preview_file(request, attachment)
            && answer_waiting(&self.previews.asks, request, attachment, &file)
                .into_iter()
                .any(|answered| answered == id)
        {
            let _ = self.post(Event::PreviewAnswered { ask: id });
        }
        Some(id)
    }

    /// The answer to an ask of [`Core::preview_ask`], once, after its [`Event::PreviewAnswered`]: the picture to
    /// answer with (`image/png` or `image/jpeg`, the core's own encode), or None for "not found" (the view ended, or
    /// the ask is unknown)
    pub fn preview_answer(&self, ask: u64) -> Option<Arc<Picture>> {
        lock_asks(&self.previews.asks).answers.remove(&ask).flatten()
    }

    /// The attachment a preview's link (`inboxclassic:attachment-<token>-<attachment>`, clicked in the reading pane)
    /// opens, `expected` the token of the view that reader shows (`preview_token`); None for a link of another view
    /// (even one still shown elsewhere) or of no view shown: the window opens it as a double-click in the strip does
    pub fn preview_link(&self, uri: &str, expected: &str) -> Option<usize> {
        let (token, attachment) = pe_html::parse_preview_link(uri)?;
        if token != expected {
            return None;
        }
        let shown = lock_shown(&self.previews.shown);
        let view = shown.iter().find(|shown| shown.token == token)?;
        view.files.iter().any(|(a, _)| *a == attachment).then_some(attachment)
    }
}

/// The picture answered for a page that was not drawn (over a limit, refused, abandoned): a light gray square the
/// document stretches over the space kept for it, so the web view shows no broken picture
fn not_drawn_picture() -> Arc<Picture> {
    static PICTURE: OnceLock<Arc<Picture>> = OnceLock::new();
    PICTURE
        .get_or_init(|| {
            let pixel = image::RgbImage::from_pixel(1, 1, image::Rgb([0xe6, 0xe6, 0xe6]));
            let mut bytes = Vec::new();
            let _ = image::DynamicImage::ImageRgb8(pixel)
                .write_to(&mut std::io::Cursor::new(&mut bytes), image::ImageFormat::Png);
            Arc::new(Picture {
                mime: PreviewMime::Png,
                bytes,
                width: 1,
                height: 1,
            })
        })
        .clone()
}

/// Answers the asks waiting for pictures of `attachment` of `request` that `file` has now (drawn, refused, or the
/// file done without them); the asks answered
fn answer_waiting(asks: &Asks, request: u64, attachment: usize, file: &PreviewFile) -> Vec<u64> {
    let mut asks = lock_asks(asks);
    let AskState { waiting, answers, .. } = &mut *asks;
    let mut answered = Vec::new();
    waiting.retain(|ask| {
        if ask.request != request || ask.attachment != attachment {
            return true;
        }
        let picture = match file.pages.get(&ask.page) {
            Some(Ok(picture)) => picture.clone(),
            Some(Err(_)) => not_drawn_picture(),
            None if file.refused.is_some() || file.done => not_drawn_picture(),
            None => return true,
        };
        answers.insert(ask.id, Some(picture));
        answered.push(ask.id);
        false
    });
    answered
}

/// A file that is not there (the message left the store, or has no such attachment): refused, and done
fn not_drawn(files: &Files, asks: &Asks, events: &EventSink, request: u64, attachment: usize) {
    let refused = What::Refused {
        page: None,
        reason: PreviewRefusal::Unreadable,
    };
    for what in [refused, What::Done] {
        record(
            files,
            asks,
            events,
            Outcome {
                owner: request,
                attachment,
                what,
            },
        );
    }
}

/// Keeps what came of a file under its request (unless the request was cancelled) and announces it, answering the
/// document servers' asks it answers
fn record(
    files: &Files,
    asks: &Asks,
    events: &EventSink,
    Outcome {
        owner,
        attachment,
        what,
    }: Outcome,
) {
    let file = {
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
        file.clone()
    };
    for ask in answer_waiting(asks, owner, attachment, &file) {
        events(Event::PreviewAnswered { ask });
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
mod view_tests {
    use super::*;
    use crate::list_load::tests::opened;
    use std::sync::mpsc::Receiver;

    /// The answer to `ask` once its event came
    fn answered(core: &Core, events: &Receiver<Event>, ask: u64) -> Option<Arc<Picture>> {
        let until = Instant::now() + Duration::from_secs(20);
        loop {
            match events.recv_timeout(until.saturating_duration_since(Instant::now())) {
                Ok(Event::PreviewAnswered { ask: answered }) if answered == ask => return core.preview_answer(ask),
                Ok(_) => {}
                Err(error) => panic!("ask {ask} not answered: {error}"),
            }
        }
    }

    fn shown(core: &Core, inbox: FolderId) -> crate::MessageView {
        core.message_view(inbox, 1, false).unwrap().unwrap()
    }

    /// The previews' token as the document's addresses carry it
    fn token(view: &crate::MessageView) -> String {
        let token = view.preview_token.clone().unwrap();
        assert_eq!(token.len(), 32);
        assert!(token.bytes().all(|b| b.is_ascii_hexdigit()));
        token
    }

    #[test]
    fn a_view_shows_its_pictures_and_pdf_pages_after_the_text() {
        let dir = pe_testkit::TempDir::new("core-previews-view");
        let (core, inbox, _events) = opened(&dir, 1);
        core.store().set_source(inbox, 1, &super::tests::message()).unwrap();
        let view = shown(&core, inbox);
        let token = token(&view);
        let document = &view.document;
        // the picture at its size, the PDF's page at half its pixels, the text file not at all
        assert!(
            document.contains(&format!("src=\"/pv/{token}-0-0\" width=\"64\" height=\"32\"")),
            "{document}"
        );
        assert!(
            document.contains(&format!("src=\"/pv/{token}-1-0\" width=\"620\"")),
            "{document}"
        );
        assert!(!document.contains(&format!("/pv/{token}-2-")), "{document}");
        assert!(document.contains("alt=\"invoice.pdf, page 1 of 1\""), "{document}");
        assert!(document.contains("1 page, "), "{document}");
        assert!(
            document.contains(&format!("href=\"inboxclassic:attachment-{token}-1\"")),
            "{document}"
        );
        // after the text
        assert!(document.find("See them.").unwrap() < document.find("<section").unwrap());
        // the CSP lets pictures load from the preview path only
        assert!(
            document.contains(&format!("img-src data: {}/pv/;", pe_html::preview_origin())),
            "{document}"
        );
        // the printout has none of it
        let printed = view.print_document.as_deref().unwrap();
        assert!(!printed.contains("/pv/") && printed.contains("See them."), "{printed}");
    }

    #[test]
    fn a_picture_is_served_by_its_token_while_the_view_is_shown() {
        let dir = pe_testkit::TempDir::new("core-previews-serve");
        let (core, inbox, events) = opened(&dir, 1);
        core.store().set_source(inbox, 1, &super::tests::message()).unwrap();
        let view = shown(&core, inbox);
        let token = token(&view);

        // the whole URL on the page's origin, or its path
        let address = format!("{}/pv/{token}-0-0", pe_html::preview_origin());
        let ask = core.preview_ask(&address).unwrap();
        let picture = answered(&core, &events, ask).unwrap();
        assert_eq!(
            (picture.width, picture.height, picture.mime),
            (64, 32, PreviewMime::Png)
        );
        assert!(picture.bytes.starts_with(b"\x89PNG"));
        // taken once
        assert_eq!(core.preview_answer(ask), None);

        let ask = core.preview_ask(&format!("/pv/{token}-1-0")).unwrap();
        let page = answered(&core, &events, ask).unwrap();
        assert_eq!((page.width, page.mime), (1240, PreviewMime::Png));

        // asked again (a second web view, a reload): answered from what was drawn
        let ask = core.preview_ask(&format!("/pv/{token}-0-0")).unwrap();
        assert_eq!(answered(&core, &events, ask), Some(picture));

        // not a picture of the view: no ask, the server answers "not found" at once
        let other = "0123456789abcdef0123456789abcdef";
        for address in [
            format!("/pv/{other}-0-0"),
            format!("/pv/{token}-0-1"),
            format!("/pv/{token}-2-0"),
            format!("/pv/{token}-7-0"),
            format!("https://example.com/pv/{token}-0-0"),
            format!("/{token}-0-0"),
        ] {
            assert_eq!(core.preview_ask(&address), None, "{address}");
        }

        // the window shows another document: the token is gone
        core.previews_end(&token);
        assert_eq!(core.preview_ask(&format!("/pv/{token}-0-0")), None);
        assert_eq!(
            core.preview_link(&format!("inboxclassic:attachment-{token}-0"), &token),
            None
        );
    }

    #[test]
    fn a_link_names_an_attachment_of_a_view_shown() {
        let dir = pe_testkit::TempDir::new("core-previews-link");
        let (core, inbox, _events) = opened(&dir, 1);
        core.store().set_source(inbox, 1, &super::tests::message()).unwrap();
        let view = shown(&core, inbox);
        let token = token(&view);
        assert_eq!(
            core.preview_link(&format!("inboxclassic:attachment-{token}-1"), &token),
            Some(1)
        );
        // the text file has no preview, so no link of the view names it
        assert_eq!(
            core.preview_link(&format!("inboxclassic:attachment-{token}-2"), &token),
            None
        );
        assert_eq!(
            core.preview_link("inboxclassic:attachment-0123456789abcdef0123456789abcdef-1", &token),
            None
        );
        assert_eq!(core.preview_link("https://example.com/", &token), None);
        // another view still shown (another window's) does not open from this reader
        let other = shown(&core, inbox).preview_token.unwrap();
        assert_ne!(other, token);
        assert_eq!(
            core.preview_link(&format!("inboxclassic:attachment-{other}-1"), &token),
            None
        );
        assert_eq!(
            core.preview_link(&format!("inboxclassic:attachment-{token}-1"), &other),
            None
        );
        assert_eq!(
            core.preview_link(&format!("inboxclassic:attachment-{other}-1"), &other),
            Some(1)
        );
        assert_eq!(
            core.preview_link(&format!("inboxclassic:attachment-{token}-1"), &token),
            Some(1)
        );
    }

    /// Only the newest views' previews are answered: a window that never ends its views keeps no more than
    /// [`MAX_SHOWN`]
    #[test]
    fn tokens_expire_with_their_views() {
        let dir = pe_testkit::TempDir::new("core-previews-expire");
        let (core, inbox, _events) = opened(&dir, 1);
        core.store().set_source(inbox, 1, &super::tests::message()).unwrap();
        let first = token(&shown(&core, inbox));
        let tokens: Vec<String> = (0..MAX_SHOWN).map(|_| token(&shown(&core, inbox))).collect();
        assert!(!tokens.contains(&first));
        assert_eq!(
            core.preview_link(&format!("inboxclassic:attachment-{first}-0"), &first),
            None
        );
        assert_eq!(core.preview_ask(&format!("/pv/{first}-0-0")), None);
        for token in &tokens {
            assert_eq!(
                core.preview_link(&format!("inboxclassic:attachment-{token}-0"), token),
                Some(0)
            );
        }
    }

    /// A page that is not drawn (here: the view's previews end while it is asked for) is answered all the same, so
    /// no web view waits for ever
    #[test]
    fn an_ask_of_a_view_ended_is_answered_with_none() {
        let dir = pe_testkit::TempDir::new("core-previews-ended");
        let (core, inbox, events) = opened(&dir, 1);
        core.store().set_source(inbox, 1, &super::tests::message()).unwrap();
        let token = token(&shown(&core, inbox));
        let ask = core.preview_ask(&format!("/pv/{token}-1-0")).unwrap();
        core.previews_end(&token);
        // drawn before the end, or not: either way an answer comes, and nothing after the end
        let _ = answered(&core, &events, ask);
        assert!(lock_asks(&core.previews.asks).waiting.is_empty());
    }

    #[test]
    fn the_setting_turns_previews_off_and_pdf_files_can_stay_out() {
        let dir = pe_testkit::TempDir::new("core-previews-setting");
        let (core, inbox, _events) = opened(&dir, 1);
        core.store().set_source(inbox, 1, &super::tests::message()).unwrap();
        assert!(core.show_previews());

        // PDF files turned off by the user: the picture only, and no notice
        core.set_pdf_previews(false).unwrap();
        let view = shown(&core, inbox);
        let token = token(&view);
        assert!(view.document.contains(&format!("/pv/{token}-0-0")));
        assert!(!view.document.contains(&format!("/pv/{token}-1-")));
        assert!(!view.document.contains("class=\"w\""), "{}", view.document);
        assert_eq!(
            core.preview_link(&format!("inboxclassic:attachment-{token}-1"), &token),
            None
        );

        // turned off by the core after a PDF file ended the app: the notice says so where the PDF file would be
        core.store().set_pdf_previews_crashed(true).unwrap();
        let view = shown(&core, inbox);
        let notice = core.previews_notice().unwrap();
        assert!(view.document.contains(&pe_html_text(&notice)), "{}", view.document);
        core.set_pdf_previews(true).unwrap();

        // previews off: none at all, and the CSP as before
        core.set_show_previews(false).unwrap();
        assert!(!core.show_previews());
        let view = shown(&core, inbox);
        assert_eq!(view.preview_token, None);
        assert!(!view.document.contains("/pv/"), "{}", view.document);
        assert!(view.document.contains("img-src data:;"));
        assert_eq!(view.print_document, None);
    }

    /// The notice as the document writes it
    fn pe_html_text(text: &str) -> String {
        text.replace('&', "&amp;").replace('<', "&lt;").replace('>', "&gt;")
    }

    /// The wall of this PR: signed or encrypted mail (OpenPGP or S/MIME) gets no previews, so nothing of an encrypted
    /// part can show in a document of another part, or outside its frame
    #[test]
    fn signed_or_encrypted_mail_gets_no_previews() {
        let dir = pe_testkit::TempDir::new("core-previews-protected");
        let (core, inbox, _events) = opened(&dir, 1);
        let plain = String::from_utf8(super::tests::message()).unwrap();
        let (head, body) = plain.split_once("\r\n\r\n").unwrap();
        // the message's header without its Content-Type, which the wrapper gives
        let mixed = format!(
            "{}\r\n",
            head.replace("Content-Type: multipart/mixed; boundary=b", "").trim_end()
        );
        for wrapper in [
            "multipart/signed; protocol=\"application/pgp-signature\"; micalg=pgp-sha256",
            "multipart/signed; protocol=\"application/pkcs7-signature\"; micalg=sha-256",
        ] {
            let signature = if wrapper.contains("pgp") {
                "Content-Type: application/pgp-signature\r\n\r\n-----BEGIN PGP SIGNATURE-----\r\nAAAA\r\n-----END PGP SIGNATURE-----\r\n"
            } else {
                "Content-Type: application/pkcs7-signature; name=smime.p7s\r\nContent-Transfer-Encoding: base64\r\n\r\nAAAA\r\n"
            };
            let source = format!(
                "{mixed}Content-Type: {wrapper}; boundary=s\r\n\r\n--s\r\nContent-Type: multipart/mixed; boundary=b\r\n\r\n\
                 {body}\r\n--s\r\n{signature}--s--\r\n"
            );
            core.store().set_source(inbox, 1, source.as_bytes()).unwrap();
            let view = shown(&core, inbox);
            assert_eq!(view.preview_token, None, "{wrapper}");
            assert!(!view.document.contains("/pv/"), "{wrapper}: {}", view.document);
            // its files are still in the strip
            assert!(
                view.attachments.iter().any(|a| a.filename == "invoice.pdf"),
                "{wrapper}"
            );
        }
    }

    /// A message file opened in a window of its own shows its previews too, read from the file's bytes
    #[test]
    fn a_message_file_shows_its_previews() {
        let dir = pe_testkit::TempDir::new("core-previews-file");
        let (core, _inbox, events) = opened(&dir, 1);
        let path = dir.path().join("photos.eml");
        std::fs::write(&path, super::tests::message()).unwrap();
        let view = core.file_view(&path, false).unwrap();
        let token = token(&view);
        let ask = core.preview_ask(&format!("/pv/{token}-0-0")).unwrap();
        assert_eq!(answered(&core, &events, ask).unwrap().width, 64);
    }

    /// A long PDF file shows its first pages and a link to the rest, and a message's previews stop at
    /// [`MAX_PREVIEWS`] pictures, in the order of its files
    #[test]
    fn a_long_pdf_file_and_many_pictures_are_cut_short() {
        use base64::Engine;
        let dir = pe_testkit::TempDir::new("core-previews-many");
        let (core, inbox, _events) = opened(&dir, 1);
        let manual = include_bytes!("../../pe-preview/tests/files/manual-40-pages.pdf");
        let png = {
            let mut bytes = Vec::new();
            image::DynamicImage::ImageRgb8(image::RgbImage::from_pixel(8, 8, image::Rgb([9, 9, 9])))
                .write_to(&mut std::io::Cursor::new(&mut bytes), image::ImageFormat::Png)
                .unwrap();
            bytes
        };
        let base64 = |bytes: &[u8]| base64::engine::general_purpose::STANDARD.encode(bytes);
        let mut message = "From: a@example.com\r\nSubject: Many\r\nMIME-Version: 1.0\r\n\
                           Content-Type: multipart/mixed; boundary=b\r\n\r\n--b\r\nContent-Type: text/plain\r\n\r\nhi\r\n"
            .to_string();
        message.push_str(&format!(
            "--b\r\nContent-Type: application/pdf; name=manual.pdf\r\nContent-Disposition: attachment; \
             filename=manual.pdf\r\nContent-Transfer-Encoding: base64\r\n\r\n{}\r\n",
            base64(manual)
        ));
        for n in 0..20 {
            message.push_str(&format!(
                "--b\r\nContent-Type: image/png; name=p{n}.png\r\nContent-Disposition: attachment; filename=p{n}.png\r\n\
                 Content-Transfer-Encoding: base64\r\n\r\n{}\r\n",
                base64(&png)
            ));
        }
        message.push_str("--b--\r\n");
        core.store().set_source(inbox, 1, message.as_bytes()).unwrap();
        let view = shown(&core, inbox);
        let token = token(&view);
        assert_eq!(view.document.matches("<img").count(), MAX_PREVIEWS, "{}", view.document);
        assert!(view.document.contains(&format!("/pv/{token}-0-4")));
        assert!(!view.document.contains(&format!("/pv/{token}-0-5")));
        assert!(view.document.contains("Open to see all 40 pages"), "{}", view.document);
        assert!(view.document.contains("40 pages, "), "{}", view.document);
        assert!(view.document.contains(&format!("/pv/{token}-15-0")));
        assert!(!view.document.contains(&format!("/pv/{token}-16-0")));
        assert_eq!(view.preview_token.as_deref(), Some(token.as_str()));
        assert_eq!(
            core.preview_link(&format!("inboxclassic:attachment-{token}-16"), &token),
            None
        );
    }

    /// The messages of the UI tests' previews step (`scripts/ui-e2e/previews/`) show what the tests look for
    #[test]
    fn the_ui_tests_messages_read_as_the_tests_expect() {
        let dir = pe_testkit::TempDir::new("core-previews-ui");
        let (core, inbox, events) = opened(&dir, 1);
        core.store()
            .set_source(
                inbox,
                1,
                include_bytes!("../../../../scripts/ui-e2e/previews/photo-and-pdf.eml"),
            )
            .unwrap();
        let view = shown(&core, inbox);
        let token = token(&view);
        assert_eq!(view.document.matches("<img").count(), 4, "{}", view.document);
        assert!(
            view.document
                .contains(&format!("src=\"/pv/{token}-0-0\" width=\"1600\" height=\"1000\""))
        );
        assert!(view.document.contains(&format!("/pv/{token}-1-2")));
        assert!(view.document.contains("alt=\"invoice-2026-118.pdf, page 3 of 3\""));
        assert!(view.document.contains("3 pages, "));
        assert!(!view.document.contains("Open to see"));
        let ask = core.preview_ask(&format!("/pv/{token}-0-0")).unwrap();
        assert_eq!(answered(&core, &events, ask).unwrap().mime, PreviewMime::Jpeg);

        core.store()
            .set_source(
                inbox,
                1,
                include_bytes!("../../../../scripts/ui-e2e/previews/long-pdf.eml"),
            )
            .unwrap();
        let view = shown(&core, inbox);
        assert_eq!(view.document.matches("<img").count(), PREVIEW_PAGES);
        assert!(view.document.contains("Open to see all 12 pages"), "{}", view.document);
    }

    /// A message's HTML that names a preview's address or link guesses no token: nothing answers it
    #[test]
    fn a_message_can_not_reach_the_previews() {
        let dir = pe_testkit::TempDir::new("core-previews-guess");
        let (core, inbox, _events) = opened(&dir, 1);
        let message = String::from_utf8(super::tests::message()).unwrap().replace(
            "Content-Type: text/plain\r\n\r\nSee them.",
            "Content-Type: text/html\r\n\r\n<p>See them.</p><img src=\"/pv/00000000000000000000000000000000-0-0\">\
                 <a href=\"inboxclassic:attachment-00000000000000000000000000000000-0\">open</a>",
        );
        core.store().set_source(inbox, 1, message.as_bytes()).unwrap();
        let view = shown(&core, inbox);
        token(&view);
        assert_eq!(core.preview_ask("/pv/00000000000000000000000000000000-0-0"), None);
        assert_eq!(
            core.preview_link(
                "inboxclassic:attachment-00000000000000000000000000000000-0",
                "00000000000000000000000000000000"
            ),
            None
        );
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
        // names the place the way the platform does, as the key server notice does
        let settings = pe_html::settings_words("reading", pe_html::Platform::current(), pe_i18n::language());
        assert!(!settings.is_empty());
        assert!(notice.contains(&settings), "{notice}");

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

    /// The UI tests' way to the same state, without ending the app
    #[test]
    fn the_ui_tests_turn_pdf_previews_off_as_a_crash_does() {
        let dir = pe_testkit::TempDir::new("core-previews-crash-hook");
        let (core, _inbox, events) = opened(&dir, 1);
        core.pdf_previews_crashed_for_tests().unwrap();
        let until = Instant::now() + Duration::from_secs(10);
        while !matches!(
            events.recv_timeout(until.saturating_duration_since(Instant::now())),
            Ok(Event::PdfPreviewsOff)
        ) {
            assert!(Instant::now() < until, "no PdfPreviewsOff");
        }
        assert!(!core.pdf_previews().unwrap());
        assert!(core.previews_notice().is_some());
    }

    #[test]
    fn no_marker_leaves_pdf_previews_on() {
        let dir = pe_testkit::TempDir::new("core-previews-no-crash");
        let (core, ..) = opened(&dir, 1);
        assert!(core.pdf_previews().unwrap());
        assert_eq!(core.previews_notice(), None);
    }
}
