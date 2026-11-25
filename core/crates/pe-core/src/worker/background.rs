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

use pe_store::{AccountId, FolderId, IndexText, Store};

use crate::protect::KeyRing;
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
        // the keys read again for this pass: one imported since is used
        self.decrypt_ring = None;
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
        self.decrypt_ring = None;
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
    /// text of encrypted mail downloaded (decrypted here), the snippets of mail indexed before there were any, then
    /// the verdicts of mail stored before they were fetched.
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
        if self.index_texts(store, &Store::messages_to_index).await? > 0 {
            return Ok(true);
        }
        if self.decrypt_stored(store).await? > 0 {
            return Ok(true);
        }
        if self.index_texts(store, &Store::messages_without_snippet).await? > 0 {
            return Ok(true);
        }
        if self.reactions_stored(store).await? > 0 {
            return Ok(true);
        }
        Ok(self.fetch_sender_verdicts(store).await? > 0)
    }
}

/// How many encrypted messages one batch of the background pass decrypts
const DECRYPT_BATCH: usize = 8;

/// An encrypted message to decrypt: its id, folder and UID, and its source
type Sealed = (i64, FolderId, u64, Option<Vec<u8>>);
/// What decrypting it gave the index: its text and its protected Subject; None when nothing opened
type Opened = (i64, FolderId, u64, Option<(IndexText, Option<String>)>);

/// What decrypting each of `sources` with `ring` gave for the index (its text, its protected Subject), None for one
/// it does not open: on the blocking pool, as decrypting and parsing would hold an async thread the syncs and the opens
/// need
fn decrypt_all(sources: Vec<Sealed>, ring: &KeyRing) -> Vec<Opened> {
    open_each(sources, |source| crate::search::decrypted_text(source, ring))
}

/// `open` of each source. Anyone can encrypt a message to the user, so what decrypts and parses it runs inside a
/// panic boundary, as the reading pane's path does at the C API: a message that makes rPGP or the parser panic counts
/// as one that does not open (and is marked tried), rather than failing its batch on every pass and stopping the
/// background work behind it
fn open_each(sources: Vec<Sealed>, open: impl Fn(&[u8]) -> Option<(IndexText, Option<String>)>) -> Vec<Opened> {
    sources
        .into_iter()
        .map(|(message, folder, uid, source)| {
            let text = source.and_then(|source| {
                std::panic::catch_unwind(std::panic::AssertUnwindSafe(|| open(&source)))
                    .ok()
                    .flatten()
            });
            (message, folder, uid, text)
        })
        .collect()
}

impl Worker {
    /// The user's keys the background pass decrypts with: read once a pass (the master key, every private key
    /// unwrapped, the cards of the addresses), not for every batch
    fn decrypt_ring(&mut self, store: &Store) -> Arc<KeyRing> {
        if let Some(ring) = &self.decrypt_ring {
            return ring.clone();
        }
        let ring = Arc::new(
            crate::keys::Book::new(store, &self.ctx.secrets, &self.ctx.pgp_certs)
                .and_then(|book| book.ring())
                .unwrap_or_default(),
        );
        self.decrypt_ring = Some(ring.clone());
        ring
    }

    /// One batch of encrypted mail whose source is here, decrypted for the search with the user's keys as they are,
    /// never asking for anything (docs/pgp-plan.md): its text indexed, its snippet and protected Subject in the list.
    /// One no key here opens is left for when the user opens it, and so is the whole batch while no private key is
    /// at hand. Nothing while the switch in Settings is off. How many messages that was; the windows hear of the
    /// folders whose list changed.
    pub(super) async fn decrypt_stored(&mut self, store: &mut Store) -> Result<usize, Failure> {
        let batch = store.messages_to_decrypt(self.account, DECRYPT_BATCH)?;
        if batch.is_empty() {
            return Ok(0);
        }
        let ring = self.decrypt_ring(store);
        if ring.keys.is_empty() {
            let ids: Vec<i64> = batch.iter().map(|(message, ..)| *message).collect();
            store.mark_decrypt_tried(&ids)?;
            return Ok(batch.len());
        }
        let mut sources = Vec::new();
        for (message, folder, uid) in &batch {
            sources.push((*message, *folder, *uid, store.source(*folder, *uid)?));
        }
        let read = tokio::task::spawn_blocking(move || decrypt_all(sources, &ring))
            .await
            .map_err(|error| Failure::said(crate::FailureKind::Other, error.to_string()))?;
        let mut changed = std::collections::BTreeSet::new();
        let mut tried = Vec::new();
        for (message, folder, uid, text) in &read {
            match text {
                Some((text, subject)) => {
                    if crate::search::store_decrypted(store, *folder, *uid, text, subject.as_deref())? {
                        changed.insert(*folder);
                    }
                }
                None => tried.push(*message),
            }
        }
        store.mark_decrypt_tried(&tried)?;
        for folder in changed {
            self.emit(crate::Event::FolderChanged {
                account: self.account,
                folder,
            });
        }
        Ok(batch.len())
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn a_message_that_panics_counts_as_not_opened_and_the_rest_open() {
        let sources: Vec<Sealed> = (1..=3).map(|n| (n, 1, n as u64, Some(vec![n as u8]))).collect();
        let opened = open_each(sources, |source| {
            if source == [2] {
                panic!("a hostile message");
            }
            Some((IndexText::default(), Some(format!("{}", source[0]))))
        });
        let subjects: Vec<Option<String>> = opened
            .iter()
            .map(|(.., text)| text.as_ref().and_then(|(_, subject)| subject.clone()))
            .collect();
        assert_eq!(subjects, [Some("1".into()), None, Some("3".into())]);
    }
}
