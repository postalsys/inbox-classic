//! The background worker: what the user does not wait for, on a connection of its own (docs/open-speed-plan.md,
//! phase 3). Messages downloaded before they are opened (download.rs), the conversations of mail stored before they
//! were kept, and the text of the mail for the search, a batch at a time, so the main worker stays on the Inbox
//! (IDLE) and the user's commands.
//!
//! - It starts once the main worker's first sync is done, and works whenever the main worker stored new mail
//!   ([`Nudges`]) until nothing is left; its connection is closed after [`IDLE_FOR`] without work.
//! - When it can not connect (a server that refuses one more connection), it hands the work to the main worker, a
//!   slice of [`MAIN_SLICE`] at a time between the main worker's commands ([`Command::Background`]), and tries a
//!   connection of its own again after [`super::LIMITED_FOR`].

use std::sync::Arc;
use std::time::Duration;

use pe_store::{AccountId, Store};
use tokio::sync::Notify;
use tokio::sync::mpsc::UnboundedReceiver;

use super::{Command, Failure, Worker, shared_of};

use super::IDLE_FOR;
/// How long the main worker works on what it was handed before it looks at the Inbox and its commands again
const MAIN_SLICE: Duration = Duration::from_secs(2);

/// A wake-up for each account's background work: new mail was stored
pub(crate) type Nudges = std::sync::Mutex<std::collections::HashMap<AccountId, Arc<Notify>>>;

/// There is work for `account`: its background worker starts on it (now, or when it is done with what it does)
pub(crate) fn nudge(nudges: &Nudges, account: AccountId) {
    shared_of(nudges, account).notify_one();
}

impl Worker {
    /// The background worker's life: a batch of work after another while there is some, then a wait for more
    pub(super) async fn background(&mut self, store: &mut Store, commands: &mut UnboundedReceiver<Command>) {
        self.first_sync().await;
        let nudge = shared_of(&self.ctx.nudges, self.account);
        // whether there may be work: at first, and after a nudge
        let mut work = true;
        loop {
            if work {
                self.work_through(store).await;
            }
            let connected = self.connection.is_some();
            tokio::select! {
                command = commands.recv() => match command {
                    None => break,
                    Some(_) => work = true,
                },
                () = nudge.notified() => work = true,
                () = tokio::time::sleep(IDLE_FOR), if connected => {
                    self.log_out().await;
                    work = false;
                }
                // a connection of before the sleep is gone: not kept open until the next work
                Ok(()) = self.ctx.wake.changed(), if connected => {
                    self.connection = None;
                    work = false;
                }
            }
        }
        self.log_out().await;
    }

    /// Batches until there is no work left, or one fails (tried again with the next work). When this worker can not
    /// connect, the main worker does them, a slice at a time between its commands.
    async fn work_through(&mut self, store: &mut Store) {
        if !self.limited_lately() {
            let started = std::time::Instant::now();
            loop {
                // the line is the user's while a message is opened
                self.ctx.opening.quiet().await;
                match self.background_batch(store).await {
                    Ok(true) => continue,
                    Ok(false) => return,
                    Err(_) if self.refused_since(started) => break,
                    Err(failure) => return self.reset_after(&failure),
                }
            }
        }
        while self.hand_to_main().await {}
    }

    /// A slice of the work done by the main worker; whether there is more
    async fn hand_to_main(&self) -> bool {
        let Some(main) = &self.fallback else {
            return false;
        };
        let (reply, more) = tokio::sync::oneshot::channel();
        main.send(Command::Background { reply }).is_ok() && more.await.unwrap_or(false)
    }

    /// The main worker's share of the background work: batches for [`MAIN_SLICE`] at most, then back to the Inbox
    /// and the user's commands. Whether there is more.
    pub(super) async fn background_slice(&mut self, store: &mut Store) -> bool {
        let until = std::time::Instant::now() + MAIN_SLICE;
        loop {
            match self.background_batch(store).await {
                Ok(true) if std::time::Instant::now() < until => {}
                Ok(more) => return more,
                Err(failure) => {
                    self.reset_after(&failure);
                    return false;
                }
            }
        }
    }

    /// One batch of what is done in the background: the senders' verdicts fetched with the summaries read (local,
    /// quick), messages downloaded ahead (with their search text), conversations, the search text of the rest, the
    /// snippets of mail indexed before there were any, then the verdicts of mail stored before they were fetched.
    /// Whether there may be more.
    async fn background_batch(&mut self, store: &mut Store) -> Result<bool, Failure> {
        if self.judge_senders(store)? > 0 {
            return Ok(true);
        }
        if self.download_ahead(store).await? > 0 {
            return Ok(true);
        }
        if self.thread_stored(store).await? > 0 {
            return Ok(true);
        }
        if self.index_texts(store, Store::messages_to_index).await? > 0 {
            return Ok(true);
        }
        if self.index_texts(store, Store::messages_without_snippet).await? > 0 {
            return Ok(true);
        }
        Ok(self.fetch_sender_verdicts(store).await? > 0)
    }
}
