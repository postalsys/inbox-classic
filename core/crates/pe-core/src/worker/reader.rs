//! The reader: the worker that downloads the messages the user opens, on a connection of its own that is ready
//! before the first click and kept ready (docs/open-speed-plan.md, phase 2).
//!
//! - It connects once the main worker's first sync is done ([`Command::Connect`]), not at the first click.
//! - While it waits, a NOOP every [`KEEP_ALIVE`] keeps servers and NAT from dropping the connection; one that fails
//!   is replaced at once, so the next click finds a connection that works.
//! - On a connection it had already, the server has [`ANSWER_LIMIT`] ([`QUIET_ANSWER_LIMIT`] after a quiet minute) to
//!   start answering, not the minutes of [`pe_imap::client::Timeouts::response`]: a connection the network forgot is
//!   found dead in seconds, and the message is fetched again on a new one, with no such limit.
//! - When the computer wakes from sleep ([`Context::wake`]), its connection is dropped and made again.
//! - A server that refuses one more connection gets the opens through the main worker, and the reader tries again
//!   after [`super::LIMITED_FOR`].

use std::collections::HashSet;
use std::sync::Arc;
use std::time::{Duration, Instant};

use pe_store::{AccountId, FolderId, Store};
use tokio::sync::mpsc::UnboundedReceiver;

use super::{ANSWER_LIMIT, Command, Failure, Outcome, Role, Worker};
use crate::timing::{Clock, Link, Served};
use crate::{Event, FailureKind};

/// How often a quiet reader sends NOOP: within the 30 minutes servers allow (RFC 3501 5.4). TCP keepalive keeps NAT
/// and routers from forgetting the connection meanwhile.
const KEEP_ALIVE: Duration = Duration::from_secs(15 * 60);
/// [`ANSWER_LIMIT`] after the connection was quiet for [`QUIET`]: the likelier it is dead, the sooner it is replaced
const QUIET_ANSWER_LIMIT: Duration = Duration::from_secs(3);
const QUIET: Duration = Duration::from_secs(60);
/// The longest the reader waits for any read from the server: the user waits for all it does, its sign-in included
pub(super) const RESPONSE_LIMIT: Duration = Duration::from_secs(30);

/// The accounts whose main worker finished a sync, which the readers wait for before connecting
pub(crate) type Synced = tokio::sync::watch::Sender<HashSet<AccountId>>;

/// The main worker of `account` finished a sync
pub(crate) fn mark_synced(synced: &Synced, account: AccountId) {
    synced.send_if_modified(|accounts| accounts.insert(account));
}

/// A download over this size under way sends the next click to a second reader, not to wait for it
pub(crate) const LARGE_DOWNLOAD: u64 = 256 * 1024;
/// How long a second reader without an open keeps its connection
const SPARE_IDLE: Duration = super::IDLE_FOR;

/// The opens under way, which the background work steps aside for (one count for every account: they share the
/// line), the accounts whose reader has a large message to download, and the readers waiting with a connection
#[derive(Default)]
pub(crate) struct Opening {
    count: std::sync::atomic::AtomicUsize,
    done: tokio::sync::Notify,
    /// The large message each account's reader was given, from the click until the reader is done with it
    large: std::sync::Mutex<std::collections::HashMap<AccountId, (FolderId, u64)>>,
    ready: std::sync::Mutex<HashSet<AccountId>>,
}

impl Opening {
    /// An open starts; it ends when what this returns is dropped
    fn start(self: &Arc<Self>) -> OpenUnderWay {
        self.count.fetch_add(1, std::sync::atomic::Ordering::SeqCst);
        OpenUnderWay(self.clone())
    }

    /// Until no open is under way
    pub(crate) async fn quiet(&self) {
        loop {
            let done = self.done.notified();
            if self.count.load(std::sync::atomic::Ordering::SeqCst) == 0 {
                return;
            }
            done.await;
        }
    }

    /// Which reader of `account` an open of `folder`/`uid` goes to, decided when it is clicked: the spare one while
    /// the reader has a large message to download, else the reader, which a message of `size` over
    /// [`LARGE_DOWNLOAD`] that is not stored (`stored`) marks busy at once, before it connected or selected, so the
    /// next click does not queue behind it. Whether it goes to the spare reader.
    pub(crate) fn to_spare(&self, account: AccountId, folder: FolderId, uid: u64, size: u64, stored: bool) -> bool {
        let mut large = self.large_ones();
        if large.contains_key(&account) {
            return true;
        }
        if size > LARGE_DOWNLOAD && !stored {
            large.insert(account, (folder, uid));
        }
        false
    }

    /// The reader of `account` is done with the open of `folder`/`uid`: downloaded, failed, handed on or passed over
    /// for a later click
    pub(crate) fn opened(&self, account: AccountId, folder: FolderId, uid: u64) {
        let mut large = self.large_ones();
        if large.get(&account) == Some(&(folder, uid)) {
            large.remove(&account);
        }
    }

    /// The reader of `account` stopped: what it was given goes with it
    pub(crate) fn forget(&self, account: AccountId) {
        self.large_ones().remove(&account);
        self.set_ready(account, false);
    }

    fn large_ones(&self) -> std::sync::MutexGuard<'_, std::collections::HashMap<AccountId, (FolderId, u64)>> {
        self.large.lock().unwrap_or_else(|p| p.into_inner())
    }

    /// Whether the reader of `account` waits with a connection of its own, ready for the next open
    pub(crate) fn reader_ready(&self, account: AccountId) -> bool {
        self.ready.lock().unwrap_or_else(|p| p.into_inner()).contains(&account)
    }

    fn set_ready(&self, account: AccountId, ready: bool) {
        let mut readers = self.ready.lock().unwrap_or_else(|p| p.into_inner());
        if ready {
            readers.insert(account);
        } else {
            readers.remove(&account);
        }
    }
}

/// An open under way, see [`Opening::start`]
struct OpenUnderWay(Arc<Opening>);

impl Drop for OpenUnderWay {
    fn drop(&mut self) {
        if self.0.count.fetch_sub(1, std::sync::atomic::Ordering::SeqCst) == 1 {
            self.0.done.notify_waiters();
        }
    }
}

/// What ended the reader's wait
enum Woke {
    Command(Option<Command>),
    /// Time for the NOOP that keeps the connection
    KeepAlive,
    /// The main worker's first sync is done, or it took too long: time to connect
    Synced,
    /// The search text of a message opened was read, for its index row
    Parsed((i64, Option<pe_store::IndexText>)),
    /// The computer woke from sleep
    Slept,
    /// A second reader without opens for a while: its connection goes
    Idle,
}

impl Worker {
    /// The reader: the messages opened, each downloaded as it is asked for; one that can not be is reported for the
    /// reading pane ([`Event::MessageFailed`]), not as a failure of the account (the main worker reports those)
    pub(super) async fn read(&mut self, store: &mut Store, commands: &mut UnboundedReceiver<Command>) {
        let mut warm = false;
        // None once it is done
        let mut first_sync = Some(Box::pin(self.first_sync()));
        loop {
            let connected = self.connection.is_some();
            if !self.spare {
                self.ctx.opening.set_ready(self.account, connected);
            }
            let keep_alive = tokio::time::Instant::from_std(self.last_used + KEEP_ALIVE);
            let first_wait = first_sync.is_some() && warm && !connected;
            let woke = tokio::select! {
                command = commands.recv() => Woke::Command(command),
                () = tokio::time::sleep_until(keep_alive), if connected && !self.spare => Woke::KeepAlive,
                () = tokio::time::sleep(SPARE_IDLE), if connected && self.spare => Woke::Idle,
                true = async {
                    match first_sync.as_mut() {
                        Some(wait) => {
                            wait.await;
                            true
                        }
                        None => false,
                    }
                }, if first_wait => Woke::Synced,
                Ok(()) = self.ctx.wake.changed() => Woke::Slept,
                parsed = Self::next_parsed(&mut self.parsing), if !self.parsing.is_empty() => Woke::Parsed(parsed),
            };
            match woke {
                Woke::Command(None) => break,
                Woke::Command(Some(command)) => {
                    // only the message asked for last: those the user moved past on the way to it are not waited for
                    let mut open = None;
                    let mut asked_for = Vec::new();
                    let mut next = Some(command);
                    while let Some(command) = next {
                        match command {
                            Command::FetchSource { folder, uid, asked } => {
                                asked_for.push((folder, uid));
                                open = Some((folder, uid, asked));
                            }
                            Command::Connect => warm = true,
                            _ => {}
                        }
                        next = commands.try_recv().ok();
                    }
                    let mut opened = None;
                    if let Some((folder, uid, asked)) = open
                        && self.read_one(store, folder, uid, asked).await
                    {
                        opened = Some((folder, uid));
                    }
                    // a large one given to the reader no longer sends the next click to the spare reader
                    if !self.spare {
                        for (folder, uid) in asked_for {
                            self.ctx.opening.opened(self.account, folder, uid);
                        }
                    }
                    if let Some((folder, uid)) = opened
                        && commands.is_empty()
                    {
                        // the next click is most likely Next or Previous; one that comes meanwhile waits for this
                        // FETCH only
                        let _ = self.download_neighbors(store, folder, uid).await;
                    } else if warm && first_sync.is_none() && self.connection.is_none() {
                        // asked again after the first sync: connected now, should the first try have failed
                        self.connect_reader(store).await;
                    }
                }
                Woke::Parsed(parsed) => {
                    let _ = Self::index_parsed(store, parsed);
                }
                Woke::KeepAlive => self.keep_alive(store).await,
                Woke::Idle => self.log_out().await,
                Woke::Synced => {
                    first_sync = None;
                    self.connect_reader(store).await;
                }
                // client() drops the connection of before the sleep
                Woke::Slept if warm => self.connect_reader(store).await,
                Woke::Slept => {}
            }
        }
        if !self.spare {
            self.ctx.opening.set_ready(self.account, false);
        }
        let _ = self.index_all_parsed(store).await;
        self.log_out().await;
    }

    /// Connects when the server did not refuse a connection lately; a failure waits for the next open
    async fn connect_reader(&mut self, store: &mut Store) {
        if self.limited_lately() {
            return;
        }
        if self.client(store).await.is_ok() {
            self.last_used = Instant::now();
        }
    }

    /// A NOOP on the quiet connection; one that fails is replaced at once
    async fn keep_alive(&mut self, store: &mut Store) {
        self.last_used = Instant::now();
        let Some((client, _)) = self.connection.as_mut() else {
            return;
        };
        client.limit_next_answer(ANSWER_LIMIT);
        if client.noop().await.is_err() {
            self.connection = None;
            self.connect_reader(store).await;
        }
        self.discard_server_events();
    }

    /// What the server said of its folder: the main worker's to follow, not the reader's
    fn discard_server_events(&mut self) {
        let Some((_, server_events)) = &mut self.connection else {
            return;
        };
        loop {
            match server_events.try_recv() {
                Ok(_) => {}
                Err(tokio::sync::mpsc::error::TryRecvError::Empty) => break,
                Err(tokio::sync::mpsc::error::TryRecvError::Disconnected) => {
                    self.connection = None;
                    break;
                }
            }
        }
    }

    /// Opens one message; when the server does not take the reader's connection, the main worker does it. Whether
    /// this worker opened it.
    async fn read_one(&mut self, store: &mut Store, folder: FolderId, uid: u64, asked: Instant) -> bool {
        let forward = |worker: &Worker| {
            worker
                .fallback
                .as_ref()
                .is_some_and(|main| main.send(Command::FetchSource { folder, uid, asked }).is_ok())
        };
        // the main worker takes it, unless it is in the store already: that needs no connection
        if self.limited_lately() && !store.has_source(folder, uid).unwrap_or(false) && forward(self) {
            return false;
        }
        let started = Instant::now();
        let _under_way = self.ctx.opening.start();
        let Err(failure) = self.open_message(store, folder, uid, asked).await else {
            return true;
        };
        if !(self.refused_since(started) && forward(self)) {
            self.message_failed(folder, uid, failure);
        }
        false
    }

    /// Opens a message for the reading pane, timed: from the store, or downloaded on this worker's connection, once
    /// more on a new connection when the one it had turned out to be dead
    pub(super) async fn open_message(
        &mut self,
        store: &mut Store,
        folder: FolderId,
        uid: u64,
        asked: Instant,
    ) -> Outcome {
        if self.role == Role::Reader {
            self.discard_server_events();
        }
        let started = Instant::now();
        let mut clock = Clock::start(folder, uid, asked);
        let had_connection = self.connection.is_some();
        let mut outcome = self.fetch_for_view(store, folder, uid, &mut clock).await;
        if had_connection
            && outcome
                .as_ref()
                .is_err_and(|failure| failure.kind == FailureKind::Network)
        {
            self.connection = None;
            clock.timing.link = Link::Retried;
            outcome = self.fetch_for_view(store, folder, uid, &mut clock).await;
        }
        // a reader the server refused a connection hands the open to the main worker, which times it
        if outcome.is_err() && !self.refused_since(started) {
            clock.timing.failed = true;
            self.ctx.timings.add(&clock);
        }
        self.last_used = Instant::now();
        outcome
    }

    /// A message that could not be opened, told to the reading pane
    pub(super) fn message_failed(&mut self, folder: FolderId, uid: u64, failure: Failure) {
        self.reset_after(&failure);
        self.emit(Event::MessageFailed {
            folder,
            uid,
            kind: failure.kind,
            message: failure.message,
        });
    }

    /// The source of a message in the store, fetched when it is not there yet; [`Event::MessageReady`] once it is,
    /// and the search indexes it by its text from then on
    async fn fetch_for_view(&mut self, store: &mut Store, folder: FolderId, uid: u64, clock: &mut Clock) -> Outcome {
        let source = if store.has_source(folder, uid)? {
            clock.timing.size = store.message(folder, uid)?.and_then(|m| m.info.size).unwrap_or(0);
            None
        } else {
            Some(self.download(store, folder, uid, clock).await?)
        };
        clock.timing.ready = Some(clock.now());
        // kept before the window hears, so what it reads next includes it
        self.ctx.timings.add(clock);
        // its source stays while the app runs, whatever the limit of downloaded messages
        self.ctx
            .opened
            .lock()
            .unwrap_or_else(|p| p.into_inner())
            .insert((folder, uid));
        // a large message's window has its text already: told again now that the whole source is here, so its
        // files' "Downloading..." tiles give way to their previews (the apps keep the scroll position)
        self.emit(Event::MessageReady { folder, uid });
        // the search finds it by what the parser reads in it from now on, after the window has it: read on the
        // blocking pool, as parsing (and the first use of the patterns that find what a sender wrote) would hold the
        // async threads the syncs and the next open need; indexed when it is read
        if let (Some(source), Some(message)) = (source, store.message(folder, uid)?) {
            let parse = tokio::task::spawn_blocking(move || crate::search::read_index_text(&source));
            self.parsing.push_back((message.id, parse));
        }
        Ok(())
    }

    /// The oldest message opened whose search text is read, with it (None when the parser could not read it, or the
    /// parse ended without a result); pending while there is none
    pub(super) async fn next_parsed(
        parsing: &mut std::collections::VecDeque<super::Parsing>,
    ) -> (i64, Option<pe_store::IndexText>) {
        let Some((message, parse)) = parsing.front_mut() else {
            return std::future::pending().await;
        };
        let (message, text) = (*message, parse.await.ok().flatten());
        parsing.pop_front();
        (message, text)
    }

    /// The index row of a message opened, from its search text read on the blocking pool: replaced at once, never
    /// missing for a search meanwhile; a message the parser could not read is marked
    pub(super) fn index_parsed(store: &mut Store, (message, text): (i64, Option<pe_store::IndexText>)) -> Outcome {
        match text {
            Some(text) => store.transaction(|store| store.set_indexed(message, &text))?,
            None => store.mark_fetch_failed(message)?,
        }
        Ok(())
    }

    /// Indexes every message opened whose search text is being read, waiting for each
    pub(super) async fn index_all_parsed(&mut self, store: &mut Store) -> Outcome {
        while !self.parsing.is_empty() {
            let parsed = Self::next_parsed(&mut self.parsing).await;
            Self::index_parsed(store, parsed)?;
        }
        Ok(())
    }

    /// Downloads a message the user opened into the store, timing each step on `clock` (a large message's text
    /// first)
    async fn download(
        &mut self,
        store: &mut Store,
        folder: FolderId,
        uid: u64,
        clock: &mut Clock,
    ) -> Result<Vec<u8>, Failure> {
        clock.timing.served = match self.role {
            Role::Reader => Served::Reader,
            Role::Main | Role::Background => Served::Main,
        };
        let quiet = self.last_used.elapsed() > QUIET;
        let role = self.role;
        let made = self.connections_made;
        self.client(store).await?;
        let fresh = self.connections_made != made;
        clock.timing.host = self.host.clone();
        let (client, _) = self.connection.as_mut().expect("connected");
        if fresh {
            clock.timing.connected = Some(clock.now());
            if clock.timing.link != Link::Retried {
                clock.timing.link = Link::New;
            }
        } else {
            clock.timing.link = Link::Reused;
        }
        // a connection made just now is alive; one the reader had may be dead without knowing it: the first command
        // (SELECT, or the FETCH when the folder is selected) tells
        if role == Role::Reader && !fresh {
            client.limit_next_answer(if quiet { QUIET_ANSWER_LIMIT } else { ANSWER_LIMIT });
        }
        pe_sync::select_folder(client, store, folder).await?;
        clock.timing.selected = Some(clock.now());
        let size = store.message(folder, uid)?.and_then(|m| m.info.size).unwrap_or(0);
        let source = if role == Role::Reader && size > super::large::TEXT_FIRST_OVER {
            // its text first, the rest after (large.rs)
            self.download_large(store, folder, uid, size).await?
        } else {
            let (client, _) = self.connection.as_mut().expect("connected");
            pe_sync::fetch_raw(client, store, folder, uid).await?
        };
        let (client, _) = self.connection.as_mut().expect("connected");
        clock.timing.first_byte = client.answered_at().map(|at| clock.at(at));
        clock.timing.last_byte = Some(clock.now());
        clock.timing.size = source.len() as u64;
        store.set_source(folder, uid, &source)?;
        if size > super::large::TEXT_FIRST_OVER && role == Role::Reader {
            self.emit(Event::Transferring {
                text: crate::text::download_done_text(source.len() as u64),
            });
        }
        Ok(source)
    }
}

/// Whether the wall clock moved on `gap` while a timer of `tick` ran: the computer slept in between (the timers
/// stop while it sleeps on the Mac and Linux, and on Windows they run out at once after it)
fn slept(tick: Duration, gap: Duration) -> bool {
    gap > tick + SLEPT
}

/// How much more than a tick the wall clock must move to say the computer slept
const SLEPT: Duration = Duration::from_secs(60);

/// How often the core looks at the wall clock to notice a sleep
const SLEEP_TICK: Duration = Duration::from_secs(30);

/// A new number for the workers: the connections made before are gone
pub(crate) fn tell_woke(wake: &tokio::sync::watch::Sender<u64>) {
    wake.send_modify(|generation| *generation += 1);
}

/// Notices the computer waking from sleep, and tells the workers through `wake`
pub(crate) async fn watch_sleep(wake: Arc<tokio::sync::watch::Sender<u64>>) {
    let mut last = std::time::SystemTime::now();
    loop {
        tokio::time::sleep(SLEEP_TICK).await;
        let now = std::time::SystemTime::now();
        // a clock set back is no sleep
        let gap = now.duration_since(last).unwrap_or_default();
        last = now;
        if slept(SLEEP_TICK, gap) {
            tell_woke(&wake);
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn a_sleep_is_a_clock_that_jumped() {
        let tick = Duration::from_secs(30);
        assert!(!slept(tick, Duration::from_secs(30)));
        // a busy computer runs a timer late, not by a minute
        assert!(!slept(tick, Duration::from_secs(80)));
        assert!(slept(tick, Duration::from_secs(91)));
        assert!(slept(tick, Duration::from_secs(3600)));
    }

    #[tokio::test]
    async fn an_opened_message_is_indexed_when_its_text_is_read() {
        let mut store = Store::open_in_memory().unwrap();
        let account = store
            .add_account(&pe_store::AccountSettings {
                email: "a@example.com".into(),
                ..Default::default()
            })
            .unwrap();
        let folder_info = pe_store::FolderInfo {
            path: "INBOX".into(),
            name: "INBOX".into(),
            selectable: true,
            ..Default::default()
        };
        store.set_folders(account, &[folder_info]).unwrap();
        let folder = store.find_folder(account, "INBOX").unwrap().unwrap().id;
        let summary = pe_store::MessageInfo {
            uid: 1,
            subject: "Report".into(),
            ..Default::default()
        };
        store.add_messages(folder, &[summary]).unwrap();
        let source = b"From: Ann <ann@example.com>\r\nSubject: Report\r\n\r\nThe numbers mention a zebra.\r\n".to_vec();
        store.set_source(folder, 1, &source).unwrap();
        let message = store.message(folder, 1).unwrap().unwrap().id;
        // two opens: the texts read on the blocking pool, indexed in the order they were opened
        let mut parsing = std::collections::VecDeque::new();
        for source in [source.clone(), b"not a message".to_vec()] {
            let parse = tokio::task::spawn_blocking(move || crate::search::read_index_text(&source));
            parsing.push_back((message, parse));
        }
        let first = Worker::next_parsed(&mut parsing).await;
        assert!(
            first.1.as_ref().is_some_and(|text| text.body.contains("zebra")),
            "{first:?}"
        );
        assert_eq!(parsing.len(), 1, "the next one waits its turn");
        assert!(Worker::index_parsed(&mut store, first).is_ok());
        assert!(
            store.sources_to_index(10).unwrap().is_empty(),
            "its source counts as indexed"
        );
        let search = pe_store::Search {
            scope: pe_store::Scope::Folder(folder),
            text: "zebra".into(),
            ..Default::default()
        };
        assert_eq!(store.search(&search, Default::default(), 0, 10).unwrap().len(), 1);
        Worker::next_parsed(&mut parsing).await;
        assert!(parsing.is_empty());
        // none is pending: the reader's select waits on its other arms
        let pending = tokio::time::timeout(Duration::from_millis(50), Worker::next_parsed(&mut parsing)).await;
        assert!(pending.is_err());
    }

    #[tokio::test]
    async fn background_work_waits_while_a_message_is_opened() {
        let opening = Arc::new(Opening::default());
        // nothing under way: no wait
        opening.quiet().await;
        let first = opening.start();
        let second = opening.start();
        let waiting = opening.clone();
        let wait = tokio::spawn(async move { waiting.quiet().await });
        tokio::task::yield_now().await;
        drop(first);
        tokio::task::yield_now().await;
        assert!(!wait.is_finished(), "one still under way");
        drop(second);
        tokio::time::timeout(Duration::from_secs(1), wait)
            .await
            .unwrap()
            .unwrap();
    }

    #[test]
    fn a_large_download_sends_the_next_click_to_the_spare_reader_at_once() {
        let opening = Opening::default();
        let large = LARGE_DOWNLOAD + 1;
        // small, or large but stored: the reader, no mark
        assert!(!opening.to_spare(1, 10, 1, 100, false));
        assert!(!opening.to_spare(1, 10, 2, large, true));
        assert!(!opening.to_spare(1, 10, 3, 100, false));
        // large and not stored: the reader, marked from the click on, before it connected
        assert!(!opening.to_spare(1, 10, 4, large, false));
        assert!(opening.to_spare(1, 10, 5, 100, false));
        assert!(opening.to_spare(1, 10, 6, large, false), "a second large one too");
        assert!(
            !opening.to_spare(2, 20, 1, 100, false),
            "another account's reader is free"
        );
        // the reader done with another message keeps the mark; done with the large one ends it
        opening.opened(1, 10, 3);
        assert!(opening.to_spare(1, 10, 5, 100, false));
        opening.opened(1, 10, 4);
        assert!(!opening.to_spare(1, 10, 5, 100, false));
        // a removed account's mark goes with its reader
        assert!(!opening.to_spare(1, 10, 4, large, false));
        opening.forget(1);
        assert!(!opening.to_spare(1, 10, 5, 100, false));
    }

    #[tokio::test]
    async fn readers_wait_for_the_first_sync() {
        let synced = Arc::new(Synced::new(HashSet::new()));
        let mut waiting = synced.subscribe();
        let wait = tokio::spawn(async move { waiting.wait_for(|done| done.contains(&7)).await.is_ok() });
        tokio::task::yield_now().await;
        assert!(!wait.is_finished());
        mark_synced(&synced, 3);
        tokio::task::yield_now().await;
        assert!(!wait.is_finished());
        mark_synced(&synced, 7);
        assert!(
            tokio::time::timeout(Duration::from_secs(1), wait)
                .await
                .unwrap()
                .unwrap()
        );
    }
}
