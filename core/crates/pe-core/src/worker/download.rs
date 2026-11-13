//! Messages downloaded before they are opened (docs/open-speed-plan.md, phase 3), by the background worker: new mail
//! as it arrives and the rest of the setting's messages ([`pe_store::Ahead`]), newest first, the Inbox first, in
//! batches of about [`BATCH_BYTES`], until the account keeps the limit the user set; then the oldest go first. The
//! reader fetches the messages next to the one opened.
//!
//! What is downloaded ahead is untrusted mail parsed without the user opening it: a panic of the parser is caught
//! ([`crate::search::read_index_text`]), and a message it can not read is marked and not tried again in the
//! background.

use std::collections::HashSet;
use std::sync::{Arc, Mutex};

use pe_store::{Ahead, AheadRule, FolderId, Store};

use super::{Failure, Worker, unix_now};

/// About how much one FETCH of messages downloaded ahead brings, so a command the user gives waits for little
const BATCH_BYTES: u64 = 512 * 1024;
const MB: u64 = 1024 * 1024;

/// The messages opened since the app started, whose sources are never removed to keep the limit
pub(crate) type Opened = Arc<Mutex<HashSet<(FolderId, u64)>>>;

/// The largest message the setting downloads ahead, None for any
fn max_size(ahead: Ahead) -> Option<u64> {
    match ahead {
        Ahead::Recent => Some(pe_store::RECENT_MAX_SIZE),
        Ahead::All | Ahead::Never => None,
    }
}

impl Worker {
    /// One batch of messages downloaded ahead; how many (0: none is left to)
    pub(super) async fn download_ahead(&mut self, store: &mut Store) -> Result<usize, Failure> {
        let ahead = store.download_ahead()?;
        if ahead == Ahead::Never {
            return Ok(0);
        }
        let limit = store.download_limit_mb()?.saturating_mul(MB);
        let kept = store.downloaded(self.account)?;
        let rule = AheadRule {
            since: (ahead == Ahead::Recent).then(|| unix_now() - pe_store::RECENT_DAYS * 86_400),
            max_size: max_size(ahead),
            // full: only what is newer than the oldest kept, which goes to make room for it
            newer_than: if kept.bytes >= limit { kept.oldest } else { None },
        };
        let Some((folder, batch)) = store.messages_to_download(self.account, &rule, BATCH_BYTES)? else {
            return Ok(0);
        };
        let uids: Vec<u64> = batch.iter().map(|(_, uid, _)| *uid).collect();
        self.download_many(store, folder, &uids).await?;
        self.keep_under_limit(store, limit)?;
        Ok(batch.len())
    }

    /// The messages above and below the one opened, when the setting downloads them ahead: Next and Previous open
    /// at once
    pub(super) async fn download_neighbors(
        &mut self,
        store: &mut Store,
        folder: FolderId,
        uid: u64,
    ) -> Result<(), Failure> {
        let ahead = store.download_ahead()?;
        if ahead == Ahead::Never {
            return Ok(());
        }
        let largest = max_size(ahead).unwrap_or(u64::MAX);
        let uids: Vec<u64> = store
            .neighbors_to_download(folder, uid)?
            .into_iter()
            .filter(|(_, size)| *size <= largest)
            .map(|(uid, _)| uid)
            .collect();
        if uids.is_empty() {
            return Ok(());
        }
        self.download_many(store, folder, &uids).await?;
        self.keep_under_limit(store, store.download_limit_mb()?.saturating_mul(MB))
    }

    /// Downloads messages of a folder in one FETCH and keeps each with its search text, in one transaction. One the
    /// server does not give, or the parser can not read, is marked and not tried again in the background.
    async fn download_many(&mut self, store: &mut Store, folder: FolderId, uids: &[u64]) -> Result<(), Failure> {
        let mut fetched = pe_sync::fetch_sources(self.client(store).await?, store, folder, uids).await?;
        let texts: Vec<_> = fetched
            .iter()
            .map(|(_, source)| crate::search::read_index_text(source))
            .collect();
        store.transaction(|store| {
            for &uid in uids {
                let Some(message) = store.message(folder, uid)? else {
                    continue;
                };
                let at = fetched.iter().position(|(found, _)| *found == uid);
                match at.and_then(|at| texts[at].as_ref().map(|text| (at, text))) {
                    Some((at, text)) => {
                        store.set_source(folder, uid, &std::mem::take(&mut fetched[at].1))?;
                        store.set_indexed(message.id, text)?;
                    }
                    None => store.mark_fetch_failed(message.id)?,
                }
            }
            Ok(())
        })?;
        Ok(())
    }

    /// The oldest sources of the account removed until they take at most `limit`; never those of messages opened
    /// since the app started
    fn keep_under_limit(&self, store: &Store, limit: u64) -> Result<(), Failure> {
        let opened = self.ctx.opened.lock().unwrap_or_else(|p| p.into_inner());
        store.remove_oldest_sources(self.account, limit, &|folder, uid| opened.contains(&(folder, uid)))?;
        Ok(())
    }
}
