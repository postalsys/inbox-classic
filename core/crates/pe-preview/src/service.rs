//! The render thread and what watches it. Requests wait in a queue and are drawn one file at a time, in the order
//! they came (the document's), on a thread of their own: never a window's thread, never the core's async threads.
//!
//! A dispatcher thread takes each request, answers what it can from the cache, and hands the rest to the render
//! thread, waiting for each step of it no longer than its time ([`Settings::page_time`], [`Settings::picture_time`]).
//! A render that runs over is abandoned: a thread can not be stopped from outside, so it is left to finish on its own
//! (it may keep a core busy until the app quits), a new render thread takes its place, the file is never drawn again
//! ([`crate::marker`]), and after a PDF did that no PDF is drawn for the rest of the session. After
//! [`MAX_ABANDONED`] abandoned threads nothing is drawn.

use std::collections::{HashMap, HashSet, VecDeque};
use std::path::PathBuf;
use std::sync::atomic::{AtomicBool, Ordering};
use std::sync::mpsc::{self, Receiver, RecvTimeoutError, Sender};
use std::sync::{Arc, Condvar, Mutex, MutexGuard};
use std::time::{Duration, Instant};

use crate::cache::{Cache, Entry, Slot};
use crate::limits::{
    CACHE_BYTES, MAX_ABANDONED, MAX_FILE, MAX_PAGES, MESSAGE_PIXELS, PAGE_TIME, PICTURE_TIME, RENDER_STACK,
};
use crate::marker::Markers;
use crate::{Description, Key, Kind, Picture, Refusal, pdf, picture};

/// What draws a file: [`Real`] (the `image` crate and hayro), or a fake in tests that hangs or panics
pub trait Engine: Send + Sync + 'static {
    /// Draws `file`, a `kind` file: its description first, then its first `pages` pages (none for 0) while their
    /// pixels fit in `budget`, each step told to `emit`, which says whether to go on (false: the request was
    /// cancelled, stop). [`Step::Started`] comes before each part with a time limit
    fn run(&self, kind: Kind, file: &Arc<Vec<u8>>, pages: usize, budget: u64, emit: &mut dyn FnMut(Step) -> bool);
}

/// A step of a render
#[derive(Debug)]
pub enum Step {
    /// A part with a time limit starts: a page of a PDF (opening it counts as its first), or a whole picture
    Started(Kind),
    /// The file read: a refusal ends it
    Described(Result<Description, Refusal>),
    Page(usize, Result<Picture, Refusal>),
}

/// The engine of the app: pictures with the `image` crate, PDF files with hayro
pub struct Real;

impl Engine for Real {
    fn run(&self, kind: Kind, file: &Arc<Vec<u8>>, pages: usize, budget: u64, emit: &mut dyn FnMut(Step) -> bool) {
        match kind {
            Kind::Picture => {
                if !emit(Step::Started(Kind::Picture)) {
                    return;
                }
                let description = picture::describe(file);
                let size = description
                    .as_ref()
                    .ok()
                    .and_then(|d| d.sizes.first().copied().flatten());
                if !emit(Step::Described(description)) || pages == 0 {
                    return;
                }
                let Some((width, height)) = size else {
                    return;
                };
                let page = if u64::from(width) * u64::from(height) > budget {
                    Err(Refusal::OverBudget)
                } else {
                    picture::render(file)
                };
                emit(Step::Page(0, page));
            }
            Kind::Pdf => {
                if !emit(Step::Started(Kind::Pdf)) {
                    return;
                }
                let document = match pdf::Document::open(file.clone()) {
                    Ok(document) => document,
                    Err(refusal) => {
                        emit(Step::Described(Err(refusal)));
                        return;
                    }
                };
                let description = document.describe();
                let sizes = description.sizes.clone();
                if !emit(Step::Described(Ok(description))) {
                    return;
                }
                let drawn = document.pages();
                let mut left = budget;
                for (index, size) in sizes.into_iter().enumerate().take(pages.min(MAX_PAGES)) {
                    let page = match size {
                        None => Err(Refusal::TooLarge),
                        Some((width, height)) if u64::from(width) * u64::from(height) > left => {
                            Err(Refusal::OverBudget)
                        }
                        Some((width, height)) => {
                            left -= u64::from(width) * u64::from(height);
                            if !emit(Step::Started(Kind::Pdf)) {
                                return;
                            }
                            drawn.render(index)
                        }
                    };
                    if !emit(Step::Page(index, page)) {
                        return;
                    }
                }
            }
        }
    }
}

/// How a [`Previewer`] works: the defaults are the app's, tests change them
pub struct Settings {
    /// Where the crash markers and the list of files never drawn again are kept (the app's data folder's
    /// `previews`); None keeps no markers
    pub dir: Option<PathBuf>,
    pub page_time: Duration,
    pub picture_time: Duration,
    pub cache_bytes: usize,
    pub engine: Arc<dyn Engine>,
}

impl Default for Settings {
    fn default() -> Self {
        Settings {
            dir: None,
            page_time: PAGE_TIME,
            picture_time: PICTURE_TIME,
            cache_bytes: CACHE_BYTES,
            engine: Arc::new(Real),
        }
    }
}

/// A file to draw
#[derive(Clone)]
pub struct Request {
    /// Whose previews these are (a message view): its pixel budget ([`MESSAGE_PIXELS`]) and what
    /// [`Previewer::cancel`] drops
    pub owner: u64,
    /// The attachment of the owner's message: told back in each [`Outcome`]
    pub attachment: usize,
    pub file: Arc<Vec<u8>>,
    /// What the file is, written into its crash marker (its message and part)
    pub about: String,
    /// How many pages to draw: at most [`MAX_PAGES`] are; 0 describes the file only
    pub pages: usize,
    /// Whether its previews may be kept in the cache: not those of a decrypted part
    pub keep: bool,
}

/// What came of a request, told to the sink of the [`Previewer`] as it comes: [`Outcome::Described`] first (or a
/// refusal of the whole file), then each page, then [`Outcome::Done`]
#[derive(Debug, Clone)]
pub enum Outcome {
    Described {
        owner: u64,
        attachment: usize,
        description: Arc<Description>,
    },
    Page {
        owner: u64,
        attachment: usize,
        page: usize,
        picture: Arc<Picture>,
    },
    /// The whole file (`page` None) or a page of it has no preview: a tile
    Refused {
        owner: u64,
        attachment: usize,
        page: Option<usize>,
        reason: Refusal,
    },
    Done {
        owner: u64,
        attachment: usize,
    },
}

type Sink = Arc<dyn Fn(Outcome) + Send + Sync>;

struct Job {
    request: Request,
    /// Where its outcomes go in place of the sink ([`Previewer::describe`])
    reply: Option<Sender<Outcome>>,
}

#[derive(Default)]
struct Queue {
    jobs: VecDeque<Job>,
    closed: bool,
    /// The owner of the job being drawn, and what stops it
    running: Option<(u64, Arc<AtomicBool>)>,
    /// The pixels each owner's previews have used
    used: HashMap<u64, u64>,
}

struct Shared {
    queue: Mutex<Queue>,
    wake: Condvar,
    sink: Sink,
}

impl Shared {
    fn queue(&self) -> MutexGuard<'_, Queue> {
        self.queue.lock().unwrap_or_else(|p| p.into_inner())
    }
}

/// Draws previews on a render thread of its own; see the module's description
pub struct Previewer {
    shared: Arc<Shared>,
}

impl Previewer {
    /// Starts the dispatcher; the render thread starts with the first file. `sink` is called on the dispatcher's
    /// thread with each [`Outcome`]
    pub fn new(settings: Settings, sink: impl Fn(Outcome) + Send + Sync + 'static) -> Previewer {
        let shared = Arc::new(Shared {
            queue: Mutex::default(),
            wake: Condvar::new(),
            sink: Arc::new(sink),
        });
        let (markers, refused) = match settings.dir.as_deref().map(Markers::open) {
            Some(Ok((markers, refused))) => (Some(Arc::new(markers)), refused),
            _ => (None, HashSet::new()),
        };
        let mut dispatcher = Dispatcher {
            shared: shared.clone(),
            cache: Cache::new(settings.cache_bytes),
            markers,
            refused,
            pdfs_off: false,
            abandoned: 0,
            worker: None,
            settings,
        };
        let started = std::thread::Builder::new()
            .name("pe-preview".into())
            .spawn(move || dispatcher.serve());
        if started.is_err() {
            // no thread, no previews: every request is refused at once by a closed queue
            shared.queue().closed = true;
        }
        Previewer { shared }
    }

    /// Queues `request`: its outcomes come to the sink (at once, [`Refusal::Off`], when there is no render thread)
    pub fn request(&self, request: Request) {
        let (owner, attachment) = (request.owner, request.attachment);
        {
            let mut queue = self.shared.queue();
            if !queue.closed {
                queue.jobs.push_back(Job { request, reply: None });
                drop(queue);
                self.shared.wake.notify_one();
                return;
            }
        }
        let sink = &self.shared.sink;
        sink(Outcome::Refused {
            owner,
            attachment,
            page: None,
            reason: Refusal::Off,
        });
        sink(Outcome::Done { owner, attachment });
    }

    /// The description of `file` (a picture's size, a PDF's pages and title), read on the render thread ahead of
    /// every file waiting, waited for at most `wait`: what the reading pane needs before it shows a document. A file
    /// not read in time is [`Refusal::TimedOut`] here, while the render thread goes on with it under its own limits
    pub fn describe(&self, file: Arc<Vec<u8>>, about: String, wait: Duration) -> Result<Arc<Description>, Refusal> {
        let (reply, answers) = mpsc::channel();
        {
            let mut queue = self.shared.queue();
            if queue.closed {
                return Err(Refusal::Off);
            }
            let request = Request {
                owner: 0,
                attachment: 0,
                file,
                about,
                pages: 0,
                keep: true,
            };
            queue.jobs.push_front(Job {
                request,
                reply: Some(reply),
            });
        }
        self.shared.wake.notify_one();
        let until = Instant::now() + wait;
        loop {
            match answers.recv_timeout(until.saturating_duration_since(Instant::now())) {
                Ok(Outcome::Described { description, .. }) => return Ok(description),
                Ok(Outcome::Refused { page: None, reason, .. }) => return Err(reason),
                Ok(_) => {}
                Err(RecvTimeoutError::Timeout) => return Err(Refusal::TimedOut),
                Err(RecvTimeoutError::Disconnected) => return Err(Refusal::Unreadable),
            }
        }
    }

    /// Drops what `owner` asked for and still waits, stops its file being drawn after the page under way, and
    /// forgets the pixels its previews used: the message is no longer shown
    pub fn cancel(&self, owner: u64) {
        let mut queue = self.shared.queue();
        queue
            .jobs
            .retain(|job| job.reply.is_some() || job.request.owner != owner);
        queue.used.remove(&owner);
        if let Some((running, stop)) = &queue.running
            && *running == owner
        {
            stop.store(true, Ordering::Relaxed);
        }
    }
}

impl Drop for Previewer {
    fn drop(&mut self) {
        self.shared.queue().closed = true;
        self.shared.wake.notify_all();
    }
}

/// What the render thread sends back
enum Message {
    Step(Step),
    /// The engine panicked: caught, the file refused
    Panicked,
    /// The render ended and its marker is removed
    Finished,
}

struct Work {
    kind: Kind,
    file: Arc<Vec<u8>>,
    pages: usize,
    budget: u64,
    key: Key,
    about: String,
    stop: Arc<AtomicBool>,
    steps: Sender<Message>,
}

struct Dispatcher {
    shared: Arc<Shared>,
    settings: Settings,
    cache: Cache,
    markers: Option<Arc<Markers>>,
    /// The files never drawn again: they ended the app before, or hung
    refused: HashSet<Key>,
    pdfs_off: bool,
    abandoned: usize,
    /// The render thread's queue
    worker: Option<Sender<Work>>,
}

impl Dispatcher {
    fn serve(&mut self) {
        loop {
            let job = {
                let mut queue = self.shared.queue();
                loop {
                    if queue.closed {
                        return;
                    }
                    if let Some(job) = queue.jobs.pop_front() {
                        break job;
                    }
                    queue = self.shared.wake.wait(queue).unwrap_or_else(|p| p.into_inner());
                }
            };
            self.handle(job);
        }
    }

    fn handle(&mut self, job: Job) {
        let sink = self.shared.sink.clone();
        let tell = |outcome: Outcome| match &job.reply {
            Some(reply) => {
                let _ = reply.send(outcome);
            }
            None => sink(outcome),
        };
        let request = &job.request;
        let (owner, attachment) = (request.owner, request.attachment);
        match self.check(request) {
            Err(reason) => tell(Outcome::Refused {
                owner,
                attachment,
                page: None,
                reason,
            }),
            Ok((kind, key)) => {
                if !self.answer_cached(request, &key, &tell) {
                    // a description asked for by a window is not stopped by an owner's cancel
                    self.render(request, kind, key, job.reply.is_none(), &tell);
                }
            }
        }
        tell(Outcome::Done { owner, attachment });
    }

    /// The file's kind and key, or why it is not drawn
    fn check(&self, request: &Request) -> Result<(Kind, Key), Refusal> {
        if self.abandoned >= MAX_ABANDONED {
            return Err(Refusal::Off);
        }
        let kind = crate::kind_of(&request.file).ok_or(Refusal::Unsupported)?;
        if request.file.len() > MAX_FILE {
            return Err(Refusal::TooLarge);
        }
        if kind == Kind::Pdf && self.pdfs_off {
            return Err(Refusal::Off);
        }
        let key = crate::key_of(&request.file);
        if self.refused.contains(&key) {
            return Err(Refusal::Crashed);
        }
        Ok((kind, key))
    }

    /// Answers `request` from the cache when it holds the description and every page asked for
    fn answer_cached(&mut self, request: &Request, key: &Key, tell: &dyn Fn(Outcome)) -> bool {
        if !request.keep {
            return false;
        }
        let Some(Entry::Description(description)) = self.cache.get(key, Slot::Description) else {
            return false;
        };
        let wanted = request.pages.min(description.sizes.len()).min(MAX_PAGES);
        let mut pages = Vec::with_capacity(wanted);
        for page in 0..wanted {
            match self.cache.get(key, Slot::Page(page)) {
                Some(Entry::Page(picture)) => pages.push(picture),
                _ => return false,
            }
        }
        let (owner, attachment) = (request.owner, request.attachment);
        tell(Outcome::Described {
            owner,
            attachment,
            description,
        });
        for (page, picture) in pages.into_iter().enumerate() {
            match self.spend(owner, &picture) {
                true => tell(Outcome::Page {
                    owner,
                    attachment,
                    page,
                    picture,
                }),
                false => tell(Outcome::Refused {
                    owner,
                    attachment,
                    page: Some(page),
                    reason: Refusal::OverBudget,
                }),
            }
        }
        true
    }

    /// Counts `picture` against its owner's budget, unless it does not fit
    fn spend(&self, owner: u64, picture: &Picture) -> bool {
        let pixels = u64::from(picture.width) * u64::from(picture.height);
        let mut queue = self.shared.queue();
        let used = queue.used.entry(owner).or_default();
        if *used + pixels > MESSAGE_PIXELS {
            return false;
        }
        *used += pixels;
        true
    }

    fn budget(&self, owner: u64) -> u64 {
        MESSAGE_PIXELS.saturating_sub(self.shared.queue().used.get(&owner).copied().unwrap_or(0))
    }

    /// Hands `request` to the render thread and passes on its steps, abandoning it when a step runs over its time
    fn render(&mut self, request: &Request, kind: Kind, key: Key, cancellable: bool, tell: &dyn Fn(Outcome)) {
        let (owner, attachment) = (request.owner, request.attachment);
        let stop = Arc::new(AtomicBool::new(false));
        let (steps, messages) = mpsc::channel();
        let work = Work {
            kind,
            file: request.file.clone(),
            pages: request.pages.min(MAX_PAGES),
            budget: self.budget(owner),
            key: key.clone(),
            about: request.about.clone(),
            stop: stop.clone(),
            steps,
        };
        if !self.send(work) {
            tell(Outcome::Refused {
                owner,
                attachment,
                page: None,
                reason: Refusal::Off,
            });
            return;
        }
        if cancellable {
            self.shared.queue().running = Some((owner, stop));
        }
        let mut next_page = 0;
        let times = (self.settings.picture_time, self.settings.page_time);
        let ended = follow(&messages, kind, times, |step| match step {
            Step::Started(_) => {}
            Step::Described(Ok(description)) => {
                let description = Arc::new(description);
                if request.keep {
                    self.cache
                        .put(key.clone(), Slot::Description, Entry::Description(description.clone()));
                }
                tell(Outcome::Described {
                    owner,
                    attachment,
                    description,
                });
            }
            Step::Described(Err(reason)) => tell(Outcome::Refused {
                owner,
                attachment,
                page: None,
                reason,
            }),
            Step::Page(page, Ok(picture)) => {
                next_page = page + 1;
                let picture = Arc::new(picture);
                if !self.spend(owner, &picture) {
                    tell(Outcome::Refused {
                        owner,
                        attachment,
                        page: Some(page),
                        reason: Refusal::OverBudget,
                    });
                    return;
                }
                if request.keep {
                    self.cache
                        .put(key.clone(), Slot::Page(page), Entry::Page(picture.clone()));
                }
                tell(Outcome::Page {
                    owner,
                    attachment,
                    page,
                    picture,
                });
            }
            Step::Page(page, Err(reason)) => {
                next_page = page + 1;
                tell(Outcome::Refused {
                    owner,
                    attachment,
                    page: Some(page),
                    reason,
                });
            }
        });
        self.shared.queue().running = None;
        match ended {
            Ended::Finished => {}
            Ended::Panicked => tell(Outcome::Refused {
                owner,
                attachment,
                page: None,
                reason: Refusal::Unreadable,
            }),
            Ended::TimedOut => {
                self.abandon(kind, &key);
                tell(Outcome::Refused {
                    owner,
                    attachment,
                    page: (next_page > 0).then_some(next_page),
                    reason: Refusal::TimedOut,
                });
            }
        }
    }

    /// The render thread hung on the file of `key`: left to finish on its own, a new one for the next file, the file
    /// never drawn again, and after a PDF no PDF for the rest of the session
    fn abandon(&mut self, kind: Kind, key: &Key) {
        self.worker = None;
        self.abandoned += 1;
        if kind == Kind::Pdf {
            self.pdfs_off = true;
        }
        self.refused.insert(key.clone());
        if let Some(markers) = &self.markers {
            let _ = markers.refuse(key);
        }
    }

    /// Gives `work` to the render thread, starting one when there is none (or the last one is gone)
    fn send(&mut self, work: Work) -> bool {
        let mut work = Some(work);
        for _ in 0..2 {
            if self.worker.is_none() {
                self.worker = spawn_worker(self.settings.engine.clone(), self.markers.clone());
            }
            let Some(worker) = &self.worker else {
                return false;
            };
            match worker.send(work.take().expect("work is put back on failure")) {
                Ok(()) => return true,
                Err(mpsc::SendError(back)) => {
                    work = Some(back);
                    self.worker = None;
                }
            }
        }
        false
    }
}

enum Ended {
    Finished,
    Panicked,
    TimedOut,
}

/// Passes each step of a render to `step` until it ends, or until a step runs over its time: `times` of a picture
/// and of a PDF page
fn follow(
    messages: &Receiver<Message>,
    kind: Kind,
    (picture_time, page_time): (Duration, Duration),
    mut step: impl FnMut(Step),
) -> Ended {
    let time_of = |kind| match kind {
        Kind::Picture => picture_time,
        Kind::Pdf => page_time,
    };
    let mut deadline = Instant::now() + time_of(kind);
    loop {
        match messages.recv_timeout(deadline.saturating_duration_since(Instant::now())) {
            Ok(Message::Step(Step::Started(part))) => deadline = Instant::now() + time_of(part),
            Ok(Message::Step(next)) => step(next),
            Ok(Message::Panicked) => return Ended::Panicked,
            Ok(Message::Finished) => return Ended::Finished,
            Err(RecvTimeoutError::Timeout) => return Ended::TimedOut,
            // the render thread is gone without a word: as a panic
            Err(RecvTimeoutError::Disconnected) => return Ended::Panicked,
        }
    }
}

/// Starts a render thread: it draws each [`Work`] it is given until its queue is dropped
fn spawn_worker(engine: Arc<dyn Engine>, markers: Option<Arc<Markers>>) -> Option<Sender<Work>> {
    let (sender, works) = mpsc::channel::<Work>();
    std::thread::Builder::new()
        .name("pe-preview-render".into())
        .stack_size(RENDER_STACK)
        .spawn(move || {
            while let Ok(work) = works.recv() {
                let marker = markers.as_ref().map(|markers| markers.begin(&work.key, &work.about));
                let steps = work.steps.clone();
                let stop = work.stop.clone();
                let ran = std::panic::catch_unwind(std::panic::AssertUnwindSafe(|| {
                    engine.run(work.kind, &work.file, work.pages, work.budget, &mut |step| {
                        steps.send(Message::Step(step)).is_ok() && !stop.load(Ordering::Relaxed)
                    });
                }));
                drop(marker);
                if ran.is_err() {
                    let _ = work.steps.send(Message::Panicked);
                }
                let _ = work.steps.send(Message::Finished);
            }
        })
        .ok()?;
    Some(sender)
}
