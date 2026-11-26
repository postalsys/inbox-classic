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
//! What the section shows of each file is decided in [`plan`]: drawn, a tile that says why not (a format not drawn,
//! a password, a file too large, one still downloading, one not described in time: "Preparing…", the window told
//! when it is, [`preparing`]), or counted in the line of files past the budget; the
//! strip's Show in Message draws or takes out one file while the message is shown ([`Core::preview_show`], never
//! kept). The printout puts the pictures in its document as `data:` addresses ([`print`], [`Core::print_start`]).
//!
//! The crash markers and the list of files never drawn again are kept in `previews` beside the store. A marker left
//! behind means a file ended the app while it was drawn: the core then turns PDF previews off (a sender could change
//! a byte of the file for each message and end the app once a message), says so ([`Event::PdfPreviewsOff`],
//! [`Core::previews_notice`]) until the user turns them on again ([`Core::set_pdf_previews`]). Pictures stay on:
//! their decoders have hard limits.

use std::collections::{BTreeMap, HashMap, VecDeque};
use std::path::{Path, PathBuf};
use std::sync::atomic::Ordering;
use std::sync::{Arc, Condvar, Mutex, MutexGuard, OnceLock};
use std::time::Duration;

use pe_i18n::{Text, tr, tr_args};
use pe_preview::{Outcome, Previewer, Request, Settings, What};
use pe_store::{FolderId, Store};

use pe_preview::limits::DESCRIBE_WAIT;
pub use pe_preview::limits::MAX_PAGES as PREVIEW_PAGES;
pub use pe_preview::{Description as PreviewDescription, Mime as PreviewMime, Picture, Refusal as PreviewRefusal};

use crate::connections::Connection;
use crate::{Core, Event, EventSink, Result, view};

mod plan;
mod preparing;
mod print;

pub(crate) use plan::{Among, Budget, Choices, Planned, PreviewPlan, part_section, section};
pub use plan::{ShowInMessage, tile_words};
pub(crate) use preparing::Preparing;

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

/// What came of the files of each request still wanted, by request and attachment, and word when more came
#[derive(Default)]
struct FilesState {
    map: Mutex<HashMap<(u64, usize), PreviewFile>>,
    changed: Condvar,
}

type Files = Arc<FilesState>;

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
    /// Show in Message, for each message while a window shows it ([`Core::preview_show`])
    choices: Mutex<Vec<(PreviewSource, Choices)>>,
    /// The printouts made ([`Core::print_start`]), by request with the token of their view, until they are taken
    prints: Mutex<HashMap<u64, (String, String)>>,
    /// The tests' engine in place of pe-preview's own, set before the first preview
    #[cfg(test)]
    pub(crate) engine: OnceLock<Arc<dyn pe_preview::Engine>>,
}

/// How long a view waits for its files' sizes ([`DESCRIBE_WAIT`]), the tests' too: a file not described by then is
/// "Preparing…" until it is ([`Event::PreviewsPrepared`])
pub(crate) const DESCRIBE: Duration = DESCRIBE_WAIT;

/// The longest a render step may take before it is abandoned: the app's limits, and longer in the tests, as an
/// unoptimized build on a busy runner reads a PDF file's page tree slowly (abandoned, a PDF file would turn PDF
/// previews off for the rest of the test)
const RENDER_TIMES: (Duration, Duration) = if cfg!(test) {
    (Duration::from_secs(60), Duration::from_secs(60))
} else {
    (pe_preview::limits::PICTURE_TIME, pe_preview::limits::PAGE_TIME)
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

impl PreviewSource {
    /// Where the message is, as a crash marker names it: its folder and UID, or a message file by a digest of its
    /// bytes as they are (encrypted, when it is), never anything decrypted
    pub(crate) fn about(&self) -> String {
        match self {
            PreviewSource::Stored { folder, uid } => format!("folder {folder}, message {uid}"),
            PreviewSource::File(source) => {
                format!("a message file {}", &pe_preview::key_of(source).as_str()[..16])
            }
        }
    }
}

/// One document of a view with previews after its text: the message's, or each part's of a message with signed or
/// encrypted parts, under a token of its own, so that one part's previews never answer in another part's document
#[derive(Debug, Clone, PartialEq, Eq)]
pub(crate) struct PreviewDocument {
    /// The token its addresses and links carry
    pub token: String,
    /// The part it is (its label names it in the printout); None for a message's one document
    pub part: Option<usize>,
    /// The attachments it shows, drawn or as tiles, in its order (numbered by their place in the strip)
    pub files: Vec<pe_html::PreviewFile>,
    /// The pictures of its text (`cid:`, `data:`), each under its number ([`pe_html::INLINE_BASE`] and on, unique in
    /// the view), with where it is for its crash marker: drawn from these bytes, held while the view is shown
    pub inline: Vec<InlineFile>,
    /// Its pictures may be kept in the cache: nothing of the message was decrypted
    pub keep: bool,
}

impl PreviewDocument {
    /// The pictures of attachment `attachment`, None for one it does not show
    fn file_pages(&self, attachment: usize) -> Option<usize> {
        self.files
            .iter()
            .find(|file| file.attachment == attachment)
            .map(|file| file.pages.len())
    }
}

/// A picture of a document's text
#[derive(Debug, Clone, PartialEq, Eq)]
pub(crate) struct InlineFile {
    pub picture: pe_html::InlinePicture,
    /// Where it is, as its crash marker names it ([`PreviewPlan::inline_about`])
    pub about: String,
}

/// How a request reads the files of a message
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
enum Read {
    /// As the message is shown: decrypted when it can be ([`Core::previews_start`])
    AsShown,
    /// As it is: a view of the message as any message is shown, which decrypted nothing
    Raw,
    /// As a view of its signed or encrypted parts showed them; nothing when they can not be read so now (the keys
    /// changed): a file is never taken from another listing than the one its document was made of
    Protected,
}

/// A view whose previews a window shows
struct Shown {
    /// The view's token: the apps name the view by it (`preview_token`); a message's one document carries it too
    token: String,
    source: PreviewSource,
    /// Its documents with previews
    documents: Vec<PreviewDocument>,
    /// Show in Message of each listed attachment
    states: Vec<ShowInMessage>,
    /// What its printout is made of again with the pictures drawn
    print: Option<pe_html::PrintParts>,
    /// The request drawing them, once the first picture was asked for
    request: Option<u64>,
    /// Its documents are a message's signed or encrypted parts
    protected: bool,
    /// Its files not described in time, and what came of them since
    preparing: Option<Arc<Preparing>>,
}

impl Shown {
    /// The pictures of attachment `attachment` in the document of `token`, or 1 for a picture of its text by its
    /// number; None for one that document does not show
    fn pages(&self, token: &str, attachment: usize) -> Option<usize> {
        let document = self.document(token)?;
        document.file_pages(attachment).or_else(|| {
            let inline = document.inline.iter().any(|inline| inline.picture.number == attachment);
            inline.then_some(1)
        })
    }

    /// The pictures of attachment `attachment` in the document of `token`, None for one that document does not show
    /// (a picture of its text is none: a link names a file of the strip only)
    fn file_pages(&self, token: &str, attachment: usize) -> Option<usize> {
        self.document(token)?.file_pages(attachment)
    }

    /// Its document that carries `token`
    fn document(&self, token: &str) -> Option<&PreviewDocument> {
        self.documents.iter().find(|document| document.token == token)
    }

    /// Whether one of its documents carries `token`
    fn has(&self, token: &str) -> bool {
        self.documents.iter().any(|document| document.token == token)
    }

    /// The files of all its documents, in order
    fn files(&self) -> impl Iterator<Item = &pe_html::PreviewFile> {
        self.documents.iter().flat_map(|document| &document.files)
    }
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
    /// The answers not taken yet, with the request they came of: a picture, or None for no picture (the server
    /// answers "not found")
    answers: HashMap<u64, (u64, Option<Arc<Picture>>)>,
}

type Asks = Arc<Mutex<AskState>>;

fn lock_asks(asks: &Asks) -> MutexGuard<'_, AskState> {
    asks.lock().unwrap_or_else(|p| p.into_inner())
}

fn lock_shown(shown: &Mutex<VecDeque<Shown>>) -> MutexGuard<'_, VecDeque<Shown>> {
    shown.lock().unwrap_or_else(|p| p.into_inner())
}

/// A lock that a thread which panicked while holding it does not keep from the others
fn unpoisoned<T>(mutex: &Mutex<T>) -> MutexGuard<'_, T> {
    mutex.lock().unwrap_or_else(|p| p.into_inner())
}

fn lock(files: &Files) -> MutexGuard<'_, HashMap<(u64, usize), PreviewFile>> {
    files.map.lock().unwrap_or_else(|p| p.into_inner())
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
        let attachments = attachments.into_iter().map(|attachment| (attachment, false)).collect();
        self.previews_start_from(PreviewSource::Stored { folder, uid }, attachments, Read::AsShown)
    }

    /// [`Core::previews_start`] of a message in the store or of a message file, each attachment with whether the user
    /// asked to see it ([`pe_preview::Request::asked`]), its files read as `read` says
    fn previews_start_from(
        self: &Arc<Self>,
        source: PreviewSource,
        attachments: Vec<(usize, bool)>,
        read: Read,
    ) -> Result<u64> {
        let request = self.next_request.fetch_add(1, Ordering::Relaxed);
        self.previews_start_as(request, source, attachments, read)?;
        Ok(request)
    }

    /// [`Core::previews_start_from`] under `request`
    fn previews_start_as(
        self: &Arc<Self>,
        request: u64,
        source: PreviewSource,
        attachments: Vec<(usize, bool)>,
        read: Read,
    ) -> Result<()> {
        {
            let mut files = lock(&self.previews.files);
            for &(attachment, _) in &attachments {
                files.insert((request, attachment), PreviewFile::default());
            }
        }
        if attachments.is_empty() {
            return Ok(());
        }
        let work = self.in_background(Connection::Reads, move |core| {
            core.request_previews(request, &source, &attachments, read)
        });
        self.runtime()?.spawn(work);
        Ok(())
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

    /// The files of the message `from` as `read` says, and whether they may be kept in the cache (nothing of the
    /// message was decrypted); None when it is not there, or its parts can not be read as its view read them
    fn preview_listing(&self, from: &PreviewSource, read: Read) -> Option<(Vec<u8>, bool)> {
        let store = self.store();
        let raw = match from {
            PreviewSource::Stored { folder, uid } => store.source(*folder, *uid).ok().flatten()?,
            PreviewSource::File(source) => source.to_vec(),
        };
        // a decrypted part's previews are never kept in the cache
        let (source, decrypted) = match read {
            Read::Raw => (raw, false),
            Read::AsShown => self.shown_decrypted(&store, raw),
            Read::Protected => {
                let ring = self.ring_for(&store, &raw)?;
                let from = crate::from_addresses(&raw);
                crate::protect::shown_decrypted(&raw, &ring, &from, crate::worker::unix_now())?
            }
        };
        Some((source, !decrypted))
    }

    /// Reads the message once and hands its files to the render thread, on a thread of the blocking pool
    fn request_previews(&self, request: u64, from: &PreviewSource, attachments: &[(usize, bool)], read: Read) {
        let pdfs = self.store().pdf_previews().unwrap_or(true);
        let found = self
            .preview_listing(from, read)
            .map(|(source, keep)| (source, keep, pdfs));
        let about = from.about();
        let files = self.previews.files.clone();
        let asks = self.previews.asks.clone();
        let events = self.events.clone();
        let Some((source, keep, pdfs)) = found else {
            for &(attachment, _) in attachments {
                not_drawn(&files, &asks, &events, request, attachment);
            }
            return;
        };
        let mut listed = view::attachments(&source);
        drop(source);
        let previewer = self.previewer(pdfs);
        for &(attachment, asked) in attachments {
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
                    asked,
                    inline: false,
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
            let (picture_time, page_time) = RENDER_TIMES;
            let settings = Settings {
                dir: markers_dir(&self.path),
                pdfs,
                picture_time,
                page_time,
                ..Settings::default()
            };
            #[cfg(test)]
            let settings = match self.previews.engine.get() {
                Some(engine) => Settings {
                    engine: engine.clone(),
                    ..settings
                },
                None => settings,
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

    /// How a view of the message `source` built now shows the attachments after the text: the setting, and what the
    /// user chose with Show in Message while the message is shown; read on the thread that builds the view
    pub(crate) fn preview_plan(&self, source: &PreviewSource) -> PreviewPlan<'_> {
        PreviewPlan {
            core: self,
            about: source.about(),
            auto: self.show_previews(),
            pdfs: self.pdf_previews().unwrap_or(true),
            notice: self.previews_notice(),
            choices: self.preview_choices(source),
            downloading: None,
            late: self.preview_late(source),
            preparing: Preparing::new(self.events.clone()),
            inline_until: OnceLock::new(),
        }
    }

    /// What came of the files of the message `source` that the views a window shows did not have in time, each under
    /// the key of the bytes it was read from: a view that read the message decrypted and one that read it as it is
    /// never take each other's
    fn preview_late(&self, source: &PreviewSource) -> preparing::Late {
        let shown = lock_shown(&self.previews.shown);
        let mut late = preparing::Late::new();
        for preparing in shown
            .iter()
            .filter(|shown| shown.source == *source)
            .filter_map(|shown| shown.preparing.as_ref())
        {
            late.extend(preparing.described());
        }
        late
    }

    /// What the user chose with Show in Message for the message `source`, while a window shows it
    fn preview_choices(&self, source: &PreviewSource) -> Choices {
        unpoisoned(&self.previews.choices)
            .iter()
            .find(|(of, _)| of == source)
            .map(|(_, choices)| choices.clone())
            .unwrap_or_default()
    }

    /// A file's description for the view, read on the render thread ahead of the files waiting; `asked` for a file
    /// the user asked to see (drawn while PDF files are off), `keep` false for a decrypted one (not kept, and named
    /// by `about`, where it is). None when it did not come in `wait`: `later` is called with it when it does
    #[allow(clippy::too_many_arguments)]
    fn preview_describe(
        &self,
        pdfs: bool,
        file: Arc<Vec<u8>>,
        about: String,
        wait: Duration,
        asked: bool,
        keep: bool,
        later: pe_preview::Later,
    ) -> Option<preparing::Described> {
        self.previewer(pdfs)
            .describe_or_later(file, about, wait, asked, keep, later)
    }

    /// The description of a picture of a message's text ([`pe_preview::Request::inline`]), read on the render thread
    /// ahead of the files waiting, waiting at most `wait`; `keep` false for a decrypted part's
    fn inline_describe(
        &self,
        file: Arc<Vec<u8>>,
        about: String,
        wait: Duration,
        keep: bool,
    ) -> std::result::Result<Arc<PreviewDescription>, PreviewRefusal> {
        let pdfs = self.pdf_previews().unwrap_or(true);
        self.previewer(pdfs).describe_inline(file, about, wait, keep)
    }

    /// Show in Message chosen in the strip for attachment `attachment` of the view `token` (`show`: draw it in the
    /// message; false: take it out), for as long as a window shows the message, never kept. Whether that changes the
    /// document: the window then builds the view again (its frame keeps its place in the stack). False for
    /// a file whose command is greyed or already as asked, or a view not shown
    pub fn preview_show(&self, token: &str, attachment: usize, show: bool) -> bool {
        let source = {
            let shown = lock_shown(&self.previews.shown);
            let Some(view) = shown.iter().find(|shown| shown.token == token) else {
                return false;
            };
            let state = view.states.get(attachment).copied().unwrap_or_default();
            if !matches!((state, show), (ShowInMessage::Off, true) | (ShowInMessage::On, false)) {
                return false;
            }
            view.source.clone()
        };
        let mut all = unpoisoned(&self.previews.choices);
        let at = match all.iter().position(|(of, _)| *of == source) {
            Some(at) => at,
            None => {
                all.push((source, Choices::default()));
                all.len() - 1
            }
        };
        let choices = &mut all[at].1;
        let (add, remove) = match show {
            true => (&mut choices.shown, &mut choices.hidden),
            false => (&mut choices.hidden, &mut choices.shown),
        };
        remove.remove(&attachment);
        // chosen already (the window has not shown the view built again yet)
        add.insert(attachment)
    }

    /// A view taken by a window: its previews answered from now on, until [`Core::previews_end`] (or until
    /// [`MAX_SHOWN`] newer views were taken)
    pub(crate) fn previews_shown(&self, view: &mut crate::MessageView) {
        let (Some(token), Some(source)) = (view.preview_token.clone(), view.preview_source.take()) else {
            return;
        };
        let documents = std::mem::take(&mut view.preview_documents);
        let states = view.attachments.iter().map(|a| a.show_in_message).collect();
        let print = view.preview_print.take();
        let preparing = view.preview_preparing.take();
        let gone = {
            let mut shown = lock_shown(&self.previews.shown);
            shown.push_back(Shown {
                token: token.clone(),
                source,
                documents,
                states,
                print,
                request: None,
                protected: view.protection.is_some(),
                preparing: preparing.clone(),
            });
            let over = shown.len().saturating_sub(MAX_SHOWN);
            shown.drain(..over).collect::<Vec<_>>()
        };
        for shown in gone {
            self.forget_shown(shown);
        }
        // told from now on, when its files not described in time are (it may be so already)
        if let Some(preparing) = preparing {
            preparing.shown(&token);
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

    /// A view's previews gone: what was drawn for it, its answers not taken and its printouts not taken are dropped
    /// (a decrypted part's pictures are kept nowhere else), and its asks still waiting answered with none
    fn forget_shown(&self, shown: Shown) {
        if let Some(preparing) = &shown.preparing {
            preparing.end();
        }
        self.forget_choices(&shown.source);
        unpoisoned(&self.previews.prints).retain(|_, (token, _)| *token != shown.token);
        let Some(request) = shown.request else {
            return;
        };
        self.previews_cancel(request);
        let mut ended = Vec::new();
        {
            let mut asks = lock_asks(&self.previews.asks);
            let AskState { waiting, answers, .. } = &mut *asks;
            answers.retain(|_, (of, _)| *of != request);
            waiting.retain(|ask| {
                if ask.request != request {
                    return true;
                }
                answers.insert(ask.id, (request, None));
                ended.push(ask.id);
                false
            });
        }
        for ask in ended {
            let _ = self.post(Event::PreviewAnswered { ask });
        }
    }

    /// Show in Message's choices for a message no window shows anymore are gone
    fn forget_choices(&self, source: &PreviewSource) {
        let still = lock_shown(&self.previews.shown)
            .iter()
            .any(|shown| shown.source == *source);
        if !still {
            unpoisoned(&self.previews.choices).retain(|(of, _)| of != source);
        }
    }

    /// The request drawing the pictures of `view`, started with the first picture asked for: every file of the view
    /// with pictures, in the order of the document, so the first picture comes first
    fn shown_request(self: &Arc<Self>, view: &mut Shown) -> Option<u64> {
        if let Some(request) = view.request {
            return Some(request);
        }
        let choices = self.preview_choices(&view.source);
        let attachments = view
            .files()
            .filter(|file| !file.pages.is_empty())
            .map(|file| (file.attachment, choices.shown.contains(&file.attachment)))
            .collect();
        let read = if view.protected { Read::Protected } else { Read::Raw };
        let request = self.next_request.fetch_add(1, Ordering::Relaxed);
        // the pictures of the text first: the text is above the files
        self.request_inline(request, &view.documents);
        if self
            .previews_start_as(request, view.source.clone(), attachments, read)
            .is_err()
        {
            self.previews_cancel(request);
            return None;
        }
        view.request = Some(request);
        Some(request)
    }

    /// Hands the pictures of the text of `documents` to the render thread under `request`: their bytes are the
    /// view's, nothing is read again
    fn request_inline(&self, request: u64, documents: &[PreviewDocument]) {
        let inline: Vec<(&InlineFile, bool)> = documents
            .iter()
            .flat_map(|document| document.inline.iter().map(|inline| (inline, document.keep)))
            .collect();
        if inline.is_empty() {
            return;
        }
        {
            let mut files = lock(&self.previews.files);
            for (inline, _) in &inline {
                files.insert((request, inline.picture.number), PreviewFile::default());
            }
        }
        // started already: the view read its pictures' sizes with it (the store is not read here, under the lock of the
        // views shown)
        let previewer = match self.previews.previewer.get() {
            Some(previewer) => previewer,
            None => self.previewer(self.pdf_previews().unwrap_or(true)),
        };
        for (inline, keep) in inline {
            previewer.request(Request {
                owner: request,
                attachment: inline.picture.number,
                file: inline.picture.bytes.clone(),
                about: inline.about.clone(),
                pages: 1,
                keep,
                asked: false,
                inline: true,
            });
        }
    }

    /// A document server asks for the picture at `address` (`/pv/<token>-<attachment>-<page>`, or the whole URL on the
    /// reading pane's origin): the ask to wait for, answered by [`Event::PreviewAnswered`] (never on the calling
    /// thread) and taken with [`Core::preview_answer`]. None for an address that is no picture of a document shown: the
    /// server answers "not found" at once. The token is a document's: a part of a signed or encrypted message has its
    /// own, and its address names only the files that part's document shows. Quick, for the window thread: the
    /// picture is drawn on the render thread (the message read first, off the window thread)
    pub fn preview_ask(self: &Arc<Self>, address: &str) -> Option<u64> {
        let (token, attachment, page) = pe_html::parse_preview_address(address)?;
        let request = {
            let mut shown = lock_shown(&self.previews.shown);
            let view = shown.iter_mut().find(|shown| shown.has(token))?;
            if page >= view.pages(token, attachment)? {
                return None;
            }
            self.shown_request(view)?
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
        lock_asks(&self.previews.asks).answers.remove(&ask)?.1
    }

    /// The attachment a preview's link (`inboxclassic:attachment-<token>-<attachment>`, clicked in the reading pane)
    /// opens, `expected` the token of the view that reader shows (`preview_token`); None for a link of another view
    /// (even one still shown elsewhere), of no view shown, or naming a file its document does not show (a part's
    /// link names only its own part's files): the window opens it as a double-click in the strip does
    pub fn preview_link(&self, uri: &str, expected: &str) -> Option<usize> {
        let (token, attachment) = pe_html::parse_preview_link(uri)?;
        let shown = lock_shown(&self.previews.shown);
        let view = shown.iter().find(|shown| shown.token == expected)?;
        view.file_pages(token, attachment).map(|_| attachment)
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
        answers.insert(ask.id, (request, Some(picture)));
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
    files.changed.notify_all();
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

    /// The view `build` makes as a window shows it once its files are all described: while it has "Preparing…"
    /// tiles, built again when the core says they are ([`Event::PreviewsPrepared`]), as the windows do, the view
    /// before it then ended. The tests wait for that, never on how long a file takes to describe
    pub(crate) fn settled(
        core: &Core,
        events: &Receiver<Event>,
        build: impl Fn() -> crate::MessageView,
    ) -> crate::MessageView {
        let mut view = build();
        while view.preparing {
            let token = view.preview_token.clone().expect("a view with previews has a token");
            prepared(events, &token);
            let again = build();
            core.previews_end(&token);
            view = again;
        }
        view
    }

    /// Waits for [`Event::PreviewsPrepared`] of the view `token`
    pub(crate) fn prepared(events: &Receiver<Event>, token: &str) {
        let until = Instant::now() + Duration::from_secs(120);
        loop {
            match events.recv_timeout(until.saturating_duration_since(Instant::now())) {
                Ok(Event::PreviewsPrepared { token: of }) if of == token => return,
                Ok(_) => {}
                Err(error) => panic!("the files of view {token} not prepared: {error}"),
            }
        }
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
    use pe_preview::limits::MAX_PREVIEWS;
    use std::sync::mpsc::Receiver;
    use std::time::Instant;

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

    fn shown(core: &Core, events: &Receiver<Event>, inbox: FolderId) -> crate::MessageView {
        super::tests::settled(core, events, || core.message_view(inbox, 1, false).unwrap().unwrap())
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
        let (core, inbox, events) = opened(&dir, 1);
        core.store().set_source(inbox, 1, &super::tests::message()).unwrap();
        let view = shown(&core, &events, inbox);
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
            document.contains(&format!("img-src {}/pv/;", pe_html::preview_origin())),
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
        let view = shown(&core, &events, inbox);
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
        let (core, inbox, events) = opened(&dir, 1);
        core.store().set_source(inbox, 1, &super::tests::message()).unwrap();
        let view = shown(&core, &events, inbox);
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
        let other = shown(&core, &events, inbox).preview_token.unwrap();
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
        let (core, inbox, events) = opened(&dir, 1);
        core.store().set_source(inbox, 1, &super::tests::message()).unwrap();
        let first = token(&shown(&core, &events, inbox));
        let tokens: Vec<String> = (0..MAX_SHOWN).map(|_| token(&shown(&core, &events, inbox))).collect();
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
        let token = token(&shown(&core, &events, inbox));
        let ask = core.preview_ask(&format!("/pv/{token}-1-0")).unwrap();
        core.previews_end(&token);
        // drawn before the end, or not: either way an answer comes, and nothing after the end
        let _ = answered(&core, &events, ask);
        assert!(lock_asks(&core.previews.asks).waiting.is_empty());
    }

    #[test]
    fn the_setting_turns_previews_off_and_pdf_files_can_stay_out() {
        let dir = pe_testkit::TempDir::new("core-previews-setting");
        let (core, inbox, events) = opened(&dir, 1);
        core.store().set_source(inbox, 1, &super::tests::message()).unwrap();
        assert!(core.show_previews());

        // PDF files turned off by the user: the picture drawn, the PDF file a tile that says so (and opens it), and
        // no notice
        core.set_pdf_previews(false).unwrap();
        let view = shown(&core, &events, inbox);
        let token = token(&view);
        assert!(view.document.contains(&format!("/pv/{token}-0-0")));
        assert!(!view.document.contains(&format!("/pv/{token}-1-")));
        assert!(!view.document.contains("class=\"w\""), "{}", view.document);
        assert!(view.document.contains(&tr(Text::PreviewPdfOff)), "{}", view.document);
        assert_eq!(
            core.preview_link(&format!("inboxclassic:attachment-{token}-1"), &token),
            Some(1)
        );
        assert_eq!(core.preview_ask(&format!("/pv/{token}-1-0")), None);
        let states: Vec<_> = view.attachments.iter().map(|a| a.show_in_message).collect();
        assert_eq!(states, [ShowInMessage::On, ShowInMessage::Off, ShowInMessage::None]);

        // turned off by the core after a PDF file ended the app: the notice says so where the PDF file would be
        core.store().set_pdf_previews_crashed(true).unwrap();
        let view = shown(&core, &events, inbox);
        let notice = core.previews_notice().unwrap();
        assert!(view.document.contains(&pe_html_text(&notice)), "{}", view.document);
        core.set_pdf_previews(true).unwrap();

        // previews off: none at all, and the CSP as before; the strip's Show in Message still draws one
        core.set_show_previews(false).unwrap();
        assert!(!core.show_previews());
        let view = shown(&core, &events, inbox);
        assert!(view.preview_token.is_some());
        assert!(
            !view.document.contains("/pv/") && !view.document.contains("<section"),
            "{}",
            view.document
        );
        assert!(view.document.contains("img-src 'none';"));
        assert_eq!(view.print_document, None);
        let states: Vec<_> = view.attachments.iter().map(|a| a.show_in_message).collect();
        assert_eq!(states, [ShowInMessage::Off, ShowInMessage::Off, ShowInMessage::None]);
        // a message with no picture or PDF file has no token
        core.store().set_source(inbox, 1, b"Subject: x\r\n\r\nhi\r\n").unwrap();
        assert_eq!(shown(&core, &events, inbox).preview_token, None);
    }

    /// The notice as the document writes it
    fn pe_html_text(text: &str) -> String {
        text.replace('&', "&amp;").replace('<', "&lt;").replace('>', "&gt;")
    }

    /// The token in the first preview address of `document`
    fn address_token(document: &str) -> String {
        let at = document.find("src=\"/pv/").expect("a preview address") + 9;
        document[at..at + 32].to_string()
    }

    /// Signed mail (OpenPGP, here with a signature that does not check) shows its files' previews in its part's own
    /// document under the part's own token, never in the page around the parts; S/MIME, whose signatures the app does
    /// not read, is shown as any message is, its previews too
    #[test]
    fn signed_mail_shows_previews_in_its_part_s_document() {
        let dir = pe_testkit::TempDir::new("core-previews-protected");
        let (core, inbox, events) = opened(&dir, 1);
        let plain = String::from_utf8(super::tests::message()).unwrap();
        let (head, body) = plain.split_once("\r\n\r\n").unwrap();
        // the message's header without its Content-Type, which the wrapper gives
        let mixed = format!(
            "{}\r\n",
            head.replace("Content-Type: multipart/mixed; boundary=b", "").trim_end()
        );
        let signed = |wrapper: &str, signature: &str| {
            format!(
                "{mixed}Content-Type: {wrapper}; boundary=s\r\n\r\n--s\r\nContent-Type: multipart/mixed; boundary=b\r\n\r\n\
                 {body}\r\n--s\r\n{signature}--s--\r\n"
            )
        };
        let pgp = signed(
            "multipart/signed; protocol=\"application/pgp-signature\"; micalg=pgp-sha256",
            "Content-Type: application/pgp-signature\r\n\r\n-----BEGIN PGP SIGNATURE-----\r\nAAAA\r\n-----END PGP SIGNATURE-----\r\n",
        );
        core.store().set_source(inbox, 1, pgp.as_bytes()).unwrap();
        let view = shown(&core, &events, inbox);
        assert!(view.protection.is_some());
        let token = token(&view);
        // the page of the parts holds no preview, the part's document does, under its own token
        assert!(!view.document.contains("/pv/"), "{}", view.document);
        let part = &view.part_documents[0];
        let own = address_token(part);
        assert_ne!(own, token);
        assert!(part.contains(&format!("src=\"/pv/{own}-0-0\" width=\"64\"")), "{part}");
        assert!(
            part.contains(&format!("img-src {}/pv/;", pe_html::preview_origin())),
            "{part}"
        );
        // answered by the part's token; the view's names no document
        assert_eq!(core.preview_ask(&format!("/pv/{token}-0-0")), None);
        let ask = core.preview_ask(&format!("/pv/{own}-0-0")).unwrap();
        assert_eq!(answered(&core, &events, ask).unwrap().width, 64);
        // the part's link opens its file from the reader of the view (its token), not from another's
        let link = format!("inboxclassic:attachment-{own}-1");
        assert_eq!(core.preview_link(&link, &token), Some(1));
        assert_eq!(core.preview_link(&link, &own), None);
        // its files are in the strip with Show in Message
        let states: Vec<_> = view.attachments.iter().map(|a| a.show_in_message).collect();
        assert_eq!(states, [ShowInMessage::On, ShowInMessage::On, ShowInMessage::None]);
        core.previews_end(&token);
        assert_eq!(core.preview_ask(&format!("/pv/{own}-0-0")), None);

        let smime = signed(
            "multipart/signed; protocol=\"application/pkcs7-signature\"; micalg=sha-256",
            "Content-Type: application/pkcs7-signature; name=smime.p7s\r\nContent-Transfer-Encoding: base64\r\n\r\nAAAA\r\n",
        );
        core.store().set_source(inbox, 1, smime.as_bytes()).unwrap();
        let view = shown(&core, &events, inbox);
        assert!(view.protection.is_none());
        let smime_token = super::view_tests::token(&view);
        assert!(
            view.document.contains(&format!("/pv/{smime_token}-0-0")),
            "{}",
            view.document
        );
    }

    /// A message file opened in a window of its own shows its previews too, read from the file's bytes
    #[test]
    fn a_message_file_shows_its_previews() {
        let dir = pe_testkit::TempDir::new("core-previews-file");
        let (core, _inbox, events) = opened(&dir, 1);
        let path = dir.path().join("photos.eml");
        std::fs::write(&path, super::tests::message()).unwrap();
        let view = super::tests::settled(&core, &events, || core.file_view(&path, false).unwrap());
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
        let (core, inbox, events) = opened(&dir, 1);
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
        let view = shown(&core, &events, inbox);
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
        let view = shown(&core, &events, inbox);
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
        let view = shown(&core, &events, inbox);
        assert_eq!(view.document.matches("<img").count(), PREVIEW_PAGES);
        assert!(view.document.contains("Open to see all 12 pages"), "{}", view.document);
    }

    /// A message's HTML that names a preview's address or link guesses no token: nothing answers it
    #[test]
    fn a_message_can_not_reach_the_previews() {
        let dir = pe_testkit::TempDir::new("core-previews-guess");
        let (core, inbox, events) = opened(&dir, 1);
        let message = String::from_utf8(super::tests::message()).unwrap().replace(
            "Content-Type: text/plain\r\n\r\nSee them.",
            "Content-Type: text/html\r\n\r\n<p>See them.</p><img src=\"/pv/00000000000000000000000000000000-0-0\">\
                 <a href=\"inboxclassic:attachment-00000000000000000000000000000000-0\">open</a>",
        );
        core.store().set_source(inbox, 1, message.as_bytes()).unwrap();
        let view = shown(&core, &events, inbox);
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
mod show_tests;

#[cfg(test)]
mod preparing_tests;

#[cfg(test)]
mod inline_tests;

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
