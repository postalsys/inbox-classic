//! The render thread and what watches it. Requests wait in a queue and are drawn one file at a time, in the order
//! they came (the document's), on a thread of their own: never a window's thread, never the core's async threads.
//!
//! A dispatcher thread takes each request, answers what it can from the cache, and hands the pages the cache does not
//! hold to the render thread, waiting for each step of it no longer than its time ([`Settings::page_time`],
//! [`Settings::picture_time`]). A render that runs over is abandoned: a thread can not be stopped from outside, so it
//! is left to finish on its own (it may keep a core busy until the app quits), a new render thread takes its place, the
//! file is never drawn again ([`crate::marker`]), and after a PDF did that no PDF is drawn for the rest of the session.
//! After [`MAX_ABANDONED`] abandoned threads nothing is drawn.

use std::collections::{HashMap, HashSet, VecDeque};
use std::path::PathBuf;
use std::sync::atomic::{AtomicBool, Ordering};
use std::sync::mpsc::{self, Receiver, RecvTimeoutError, SendError, Sender};
use std::sync::{Arc, Condvar, Mutex, MutexGuard};
use std::time::{Duration, Instant};

use crate::cache::{Cache, Entry, Slot};
use crate::engine::{Engine, Real, Step};
use crate::limits::{
    CACHE_BYTES, MAX_ABANDONED, MAX_FILE, MAX_PAGES, MESSAGE_PIXELS, PAGE_TIME, PICTURE_TIME, RENDER_STACK,
};
use crate::marker::Markers;
use crate::{Description, Key, Kind, Picture, Refusal};

/// How a [`Previewer`] works: the defaults are the app's, tests change them
pub struct Settings {
    /// Where the crash markers and the list of files never drawn again are kept (the app's data folder's
    /// `previews`); None keeps no markers
    pub dir: Option<PathBuf>,
    /// Whether PDF files are drawn at all: the user's setting ([`Previewer::set_pdfs`] changes it)
    pub pdfs: bool,
    pub page_time: Duration,
    pub picture_time: Duration,
    pub cache_bytes: usize,
    pub engine: Arc<dyn Engine>,
}

impl Default for Settings {
    fn default() -> Self {
        Settings {
            dir: None,
            pdfs: true,
            page_time: PAGE_TIME,
            picture_time: PICTURE_TIME,
            cache_bytes: CACHE_BYTES,
            engine: Arc::new(Real),
        }
    }
}

/// A file to draw
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
    /// Whether its previews may be kept in the cache: not those of a decrypted part, which are kept only under its
    /// owner until it is cancelled, and whose crash marker names the file by `about` ([`crate::key_of_place`]), never
    /// by its bytes or its type
    pub keep: bool,
    /// The user asked to see this file (Show in Message): a PDF file is drawn while PDF files are off by the setting
    /// ([`Refusal::Disabled`]), and its pictures have a budget of their own, not its owner's
    pub asked: bool,
}

/// Whose pixel budget a request's pictures are counted on: its owner's, or a file asked for its own
type Purse = (u64, Option<usize>);

fn purse(request: &Request) -> Purse {
    (request.owner, request.asked.then_some(request.attachment))
}

/// What came of a request, told to the sink of the [`Previewer`] as it comes: [`What::Described`] first (or a
/// refusal of the whole file), then each page, then [`What::Done`]
#[derive(Debug, Clone)]
pub struct Outcome {
    pub owner: u64,
    pub attachment: usize,
    pub what: What,
}

#[derive(Debug, Clone)]
pub enum What {
    Described(Arc<Description>),
    Page(usize, Arc<Picture>),
    /// The whole file (`page` None) or a page of it has no preview: a tile
    Refused {
        page: Option<usize>,
        reason: Refusal,
    },
    Done,
}

type Sink = Arc<dyn Fn(Outcome) + Send + Sync>;

/// What is called with a description that came after its wait ([`Previewer::describe_or_later`]), on the
/// dispatcher's thread
pub type Later = Box<dyn FnOnce(Result<Arc<Description>, Refusal>) + Send>;

/// Where a description asked for by a window goes: to the window waiting for it, or, once its wait is over, to what
/// it left to be called with it
enum Answer {
    Waiting(Sender<Outcome>),
    Later(Later),
    Told,
}

type Reply = Arc<Mutex<Answer>>;

fn lock_answer(reply: &Reply) -> MutexGuard<'_, Answer> {
    reply.lock().unwrap_or_else(|p| p.into_inner())
}

/// The description, or the refusal of the whole file, that `what` is; None for anything else
fn described(what: &What) -> Option<Result<Arc<Description>, Refusal>> {
    match what {
        What::Described(description) => Some(Ok(description.clone())),
        What::Refused { page: None, reason } => Some(Err(reason.clone())),
        _ => None,
    }
}

/// What a description asked for comes to: [`described`], or [`Refusal::Unreadable`] for a file done without either
fn finished(what: &What) -> Option<Result<Arc<Description>, Refusal>> {
    match what {
        What::Done => Some(Err(Refusal::Unreadable)),
        what => described(what),
    }
}

struct Job {
    request: Request,
    /// Where its outcomes go in place of the sink ([`Previewer::describe`])
    reply: Option<Reply>,
}

impl Job {
    fn tell(&self, sink: &Sink, what: What) {
        let outcome = Outcome {
            owner: self.request.owner,
            attachment: self.request.attachment,
            what,
        };
        match &self.reply {
            Some(reply) => answer(reply, outcome),
            None => sink(outcome),
        }
    }

    /// Refuses the whole file, then says it is done
    fn refuse(&self, sink: &Sink, reason: Refusal) {
        self.tell(sink, What::Refused { page: None, reason });
        self.tell(sink, What::Done);
    }
}

/// Gives an outcome of a description to the window waiting for it, or to what it left once it stopped waiting: that
/// is called once, with what the description [`finished`] as
fn answer(reply: &Reply, outcome: Outcome) {
    let mut answer = lock_answer(reply);
    let result = match &*answer {
        Answer::Waiting(window) => {
            let _ = window.send(outcome);
            return;
        }
        Answer::Told => return,
        Answer::Later(_) => match finished(&outcome.what) {
            Some(result) => result,
            None => return,
        },
    };
    let Answer::Later(later) = std::mem::replace(&mut *answer, Answer::Told) else {
        return;
    };
    drop(answer);
    later(result);
}

#[derive(Default)]
struct Queue {
    jobs: VecDeque<Job>,
    closed: bool,
    /// The owner of the job being drawn, and what stops it
    running: Option<(u64, Arc<AtomicBool>)>,
    /// The pixels each owner's previews have used (and those of each file asked for its own)
    used: HashMap<Purse, u64>,
}

struct Shared {
    queue: Mutex<Queue>,
    wake: Condvar,
    sink: Sink,
    /// The user's setting: PDF files drawn at all
    pdfs: AtomicBool,
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
            pdfs: AtomicBool::new(settings.pdfs),
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
        let job = Job { request, reply: None };
        let mut queue = self.shared.queue();
        if queue.closed {
            drop(queue);
            job.refuse(&self.shared.sink, Refusal::Off);
            return;
        }
        queue.jobs.push_back(job);
        drop(queue);
        self.shared.wake.notify_one();
    }

    /// Turns the drawing of PDF files on or off (the user's setting); off, they are [`Refusal::Disabled`]
    pub fn set_pdfs(&self, on: bool) {
        self.shared.pdfs.store(on, Ordering::Relaxed);
    }

    /// The description of `file` (a picture's size, a PDF's pages and title), read on the render thread ahead of
    /// every file waiting, waited for at most `wait`: what the reading pane needs before it shows a document. A file
    /// not read in time is [`Refusal::TimedOut`] here, while the render thread goes on with it under its own limits
    pub fn describe(&self, file: Arc<Vec<u8>>, about: String, wait: Duration) -> Result<Arc<Description>, Refusal> {
        self.describe_file(file, about, wait, false, true)
    }

    /// [`Previewer::describe`] of a file the user asked to see (`asked`, [`Request::asked`]): a PDF file is described
    /// while PDF files are off by the setting; `keep` false for a decrypted part's file ([`Request::keep`]): its
    /// description (a PDF file's title is its words) is not kept in the cache
    pub fn describe_file(
        &self,
        file: Arc<Vec<u8>>,
        about: String,
        wait: Duration,
        asked: bool,
        keep: bool,
    ) -> Result<Arc<Description>, Refusal> {
        self.describe_or_later(file, about, wait, asked, keep, Box::new(|_| {}))
            .unwrap_or(Err(Refusal::TimedOut))
    }

    /// [`Previewer::describe_file`] that does not give up on a file not read in time: None then, and `later` is
    /// called with what comes of it (once, on the dispatcher's thread), while the render thread goes on with it under
    /// its own limits; a description it reads is kept in the cache as any is (unless `keep` is false). `later` is not
    /// called when the answer is returned
    pub fn describe_or_later(
        &self,
        file: Arc<Vec<u8>>,
        about: String,
        wait: Duration,
        asked: bool,
        keep: bool,
        later: Later,
    ) -> Option<Result<Arc<Description>, Refusal>> {
        let (window, answers) = mpsc::channel();
        let reply: Reply = Arc::new(Mutex::new(Answer::Waiting(window)));
        {
            let mut queue = self.shared.queue();
            if queue.closed {
                return Some(Err(Refusal::Off));
            }
            let request = Request {
                owner: 0,
                attachment: 0,
                file,
                about,
                pages: 0,
                keep,
                asked,
            };
            queue.jobs.push_front(Job {
                request,
                reply: Some(reply.clone()),
            });
        }
        self.shared.wake.notify_one();
        let until = Instant::now() + wait;
        loop {
            match answers.recv_timeout(until.saturating_duration_since(Instant::now())) {
                Ok(outcome) => {
                    if let Some(result) = finished(&outcome.what) {
                        return Some(result);
                    }
                }
                Err(RecvTimeoutError::Timeout) => break,
                Err(RecvTimeoutError::Disconnected) => return Some(Err(Refusal::Unreadable)),
            }
        }
        // what comes from now on goes to `later`: the dispatcher tells nothing while the answer is locked, so what
        // it told as the wait ended is still taken here
        let mut answer = lock_answer(&reply);
        while let Ok(outcome) = answers.try_recv() {
            if let Some(result) = finished(&outcome.what) {
                return Some(result);
            }
        }
        *answer = Answer::Later(later);
        None
    }

    /// Drops what `owner` asked for and still waits, stops its file being drawn after the page under way, and
    /// forgets the pixels its previews used: the message is no longer shown
    pub fn cancel(&self, owner: u64) {
        let mut queue = self.shared.queue();
        queue
            .jobs
            .retain(|job| job.reply.is_some() || job.request.owner != owner);
        queue.used.retain(|(of, _), _| *of != owner);
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
    /// Not a decrypted part's file: its type may be written in its marker
    keep: bool,
    file: Arc<Vec<u8>>,
    pages: Vec<usize>,
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

/// A file being drawn: what its steps are told with
struct Drawing<'a> {
    job: &'a Job,
    key: Key,
    /// Its description was told already (from the cache)
    described: bool,
    /// The page after the last one told: where a render abandoned stopped
    next_page: usize,
}

/// A refusal that comes of the file itself, the same each time it is read, and so kept in the cache
fn is_fixed(reason: &Refusal) -> bool {
    matches!(
        reason,
        Refusal::Unsupported | Refusal::TooLarge | Refusal::Password | Refusal::Unreadable
    )
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
            self.handle(&job);
        }
    }

    fn handle(&mut self, job: &Job) {
        let sink = self.shared.sink.clone();
        match self.check(&job.request) {
            Err(reason) => return job.refuse(&sink, reason),
            Ok((kind, key)) => {
                if let Some((described, missing)) = self.answer_cached(job, &key)
                    && (!described || !missing.is_empty())
                {
                    self.render(job, kind, key, missing, described);
                }
            }
        }
        job.tell(&sink, What::Done);
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
        if kind == Kind::Pdf && !request.asked && !self.shared.pdfs.load(Ordering::Relaxed) {
            return Err(Refusal::Disabled);
        }
        if kind == Kind::Pdf && self.pdfs_off {
            return Err(Refusal::Off);
        }
        let key = match request.keep {
            true => crate::key_of(&request.file),
            false => crate::key_of_place(&request.about),
        };
        if self.refused.contains(&key) {
            return Err(Refusal::Crashed);
        }
        Ok((kind, key))
    }

    /// Tells what the cache holds of the file: its description and the pages asked for, drawn or refused for good.
    /// Whether it held the description, and the pages it does not hold, to be drawn; None when the cache answered the
    /// whole file (a refusal of it)
    fn answer_cached(&mut self, job: &Job, key: &Key) -> Option<(bool, Vec<usize>)> {
        let request = &job.request;
        let all: Vec<usize> = (0..request.pages.min(MAX_PAGES)).collect();
        if !request.keep {
            return Some((false, all));
        }
        let sink = self.shared.sink.clone();
        let wanted = match self.cache.get(key, Slot::Description) {
            Some(Entry::Description(description)) => {
                let wanted: Vec<usize> = all.into_iter().filter(|&page| page < description.sizes.len()).collect();
                job.tell(&sink, What::Described(description));
                wanted
            }
            Some(Entry::Refused(reason)) => {
                job.tell(&sink, What::Refused { page: None, reason });
                return None;
            }
            _ => return Some((false, all)),
        };
        let mut missing = Vec::new();
        for page in wanted {
            match self.cache.get(key, Slot::Page(page)) {
                Some(Entry::Page(picture)) => {
                    let what = if self.spend(purse(request), &picture) {
                        What::Page(page, picture)
                    } else {
                        What::Refused {
                            page: Some(page),
                            reason: Refusal::OverBudget,
                        }
                    };
                    job.tell(&sink, what);
                }
                Some(Entry::Refused(reason)) => job.tell(
                    &sink,
                    What::Refused {
                        page: Some(page),
                        reason,
                    },
                ),
                _ => missing.push(page),
            }
        }
        Some((true, missing))
    }

    /// Counts `picture` against its budget, unless it does not fit
    fn spend(&self, purse: Purse, picture: &Picture) -> bool {
        let pixels = u64::from(picture.width) * u64::from(picture.height);
        let mut queue = self.shared.queue();
        let used = queue.used.entry(purse).or_default();
        if *used + pixels > MESSAGE_PIXELS {
            return false;
        }
        *used += pixels;
        true
    }

    fn budget(&self, purse: Purse) -> u64 {
        MESSAGE_PIXELS.saturating_sub(self.shared.queue().used.get(&purse).copied().unwrap_or(0))
    }

    /// Hands the pages `pages` of the file to the render thread and passes on its steps, abandoning it when a step
    /// runs over its time
    fn render(&mut self, job: &Job, kind: Kind, key: Key, pages: Vec<usize>, described: bool) {
        let owner = job.request.owner;
        let stop = Arc::new(AtomicBool::new(false));
        let (steps, messages) = mpsc::channel();
        let work = Work {
            kind,
            keep: job.request.keep,
            file: job.request.file.clone(),
            pages,
            budget: self.budget(purse(&job.request)),
            key: key.clone(),
            about: job.request.about.clone(),
            stop: stop.clone(),
            steps,
        };
        if !self.send(work) {
            return job.tell(
                &self.shared.sink.clone(),
                What::Refused {
                    page: None,
                    reason: Refusal::Off,
                },
            );
        }
        // a description asked for by a window is not stopped by an owner's cancel
        if job.reply.is_none() {
            self.shared.queue().running = Some((owner, stop));
        }
        let mut drawing = Drawing {
            job,
            key,
            described,
            next_page: 0,
        };
        let times = (self.settings.picture_time, self.settings.page_time);
        let ended = follow(&messages, kind, times, |step| self.on_step(&mut drawing, step));
        self.shared.queue().running = None;
        self.on_end(&drawing, kind, ended);
    }

    /// Tells a step of a render, keeping in the cache what may be kept
    fn on_step(&mut self, drawing: &mut Drawing<'_>, step: Step) {
        let sink = self.shared.sink.clone();
        let keep = drawing.job.request.keep;
        let what = match step {
            Step::Started(_) => return,
            Step::Described(Ok(_)) if drawing.described => return,
            Step::Described(Ok(description)) => {
                let description = Arc::new(description);
                if keep {
                    self.cache.put(
                        drawing.key.clone(),
                        Slot::Description,
                        Entry::Description(description.clone()),
                    );
                }
                What::Described(description)
            }
            Step::Described(Err(reason)) => {
                if keep && is_fixed(&reason) {
                    self.cache
                        .put(drawing.key.clone(), Slot::Description, Entry::Refused(reason.clone()));
                }
                What::Refused { page: None, reason }
            }
            Step::Page(page, Ok(picture)) => {
                drawing.next_page = page + 1;
                let picture = Arc::new(picture);
                if keep {
                    self.cache
                        .put(drawing.key.clone(), Slot::Page(page), Entry::Page(picture.clone()));
                }
                if self.spend(purse(&drawing.job.request), &picture) {
                    What::Page(page, picture)
                } else {
                    What::Refused {
                        page: Some(page),
                        reason: Refusal::OverBudget,
                    }
                }
            }
            Step::Page(page, Err(reason)) => {
                drawing.next_page = page + 1;
                if keep && is_fixed(&reason) {
                    self.cache
                        .put(drawing.key.clone(), Slot::Page(page), Entry::Refused(reason.clone()));
                }
                What::Refused {
                    page: Some(page),
                    reason,
                }
            }
        };
        drawing.job.tell(&sink, what);
    }

    /// How a render ended: a panic refuses the file, a render over its time is abandoned
    fn on_end(&mut self, drawing: &Drawing<'_>, kind: Kind, ended: Ended) {
        let reason = match ended {
            Ended::Finished => return,
            Ended::Panicked => Refusal::Unreadable,
            Ended::TimedOut => {
                self.abandon(kind, &drawing.key);
                Refusal::TimedOut
            }
        };
        let page = (drawing.next_page > 0).then_some(drawing.next_page);
        drawing
            .job
            .tell(&self.shared.sink.clone(), What::Refused { page, reason });
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

    /// Gives `work` to the render thread, starting a new one when there is none or the last one is gone
    fn send(&mut self, work: Work) -> bool {
        let work = match &self.worker {
            Some(worker) => match worker.send(work) {
                Ok(()) => return true,
                Err(SendError(back)) => back,
            },
            None => work,
        };
        self.worker = spawn_worker(self.settings.engine.clone(), self.markers.clone());
        self.worker.as_ref().is_some_and(|worker| worker.send(work).is_ok())
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
                let marker = markers
                    .as_ref()
                    .map(|markers| markers.begin(&work.key, work.keep.then_some(work.kind), &work.about));
                let steps = work.steps.clone();
                let stop = work.stop.clone();
                let ran = std::panic::catch_unwind(std::panic::AssertUnwindSafe(|| {
                    engine.run(work.kind, &work.file, &work.pages, work.budget, &mut |step| {
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
