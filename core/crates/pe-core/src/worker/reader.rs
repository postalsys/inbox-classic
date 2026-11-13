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

/// What ended the reader's wait
enum Woke {
    Command(Option<Command>),
    /// Time for the NOOP that keeps the connection
    KeepAlive,
    /// The main worker's first sync is done, or it took too long: time to connect
    Synced,
    /// The computer woke from sleep
    Slept,
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
            let keep_alive = tokio::time::Instant::from_std(self.last_used + KEEP_ALIVE);
            let first_wait = first_sync.is_some() && warm && !connected;
            let woke = tokio::select! {
                command = commands.recv() => Woke::Command(command),
                () = tokio::time::sleep_until(keep_alive), if connected => Woke::KeepAlive,
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
            };
            match woke {
                Woke::Command(None) => break,
                Woke::Command(Some(command)) => {
                    // only the message asked for last: those the user moved past on the way to it are not waited for
                    let mut open = None;
                    let mut next = Some(command);
                    while let Some(command) = next {
                        match command {
                            Command::FetchSource { folder, uid, asked } => open = Some((folder, uid, asked)),
                            Command::Connect => warm = true,
                            _ => {}
                        }
                        next = commands.try_recv().ok();
                    }
                    if let Some((folder, uid, asked)) = open
                        && self.read_one(store, folder, uid, asked).await
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
                Woke::KeepAlive => self.keep_alive(store).await,
                Woke::Synced => {
                    first_sync = None;
                    self.connect_reader(store).await;
                }
                // client() drops the connection of before the sleep
                Woke::Slept if warm => self.connect_reader(store).await,
                Woke::Slept => {}
            }
        }
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
        self.emit(Event::MessageReady { folder, uid });
        // the search finds it by what the parser reads in it from now on, after the window has it
        if let (Some(source), Some(message)) = (source, store.message(folder, uid)?) {
            // where a panic is caught: a message the parser can not read does not end the worker
            if let Ok(text) = tokio::task::spawn_blocking(move || crate::search::index_text(&source)).await {
                // its index row replaced at once, never missing for a search meanwhile
                store.transaction(|store| store.set_indexed(message.id, &text))?;
            }
        }
        Ok(())
    }

    /// Downloads a message the user opened into the store, timing each step on `clock`
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
        let source = pe_sync::fetch_raw(client, store, folder, uid).await?;
        clock.timing.first_byte = client.answered_at().map(|at| clock.at(at));
        clock.timing.last_byte = Some(clock.now());
        clock.timing.size = source.len() as u64;
        store.set_source(folder, uid, &source)?;
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
