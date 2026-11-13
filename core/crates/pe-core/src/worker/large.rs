//! Large messages (docs/open-speed-plan.md, phase 5): the text first, shown at once from its parts
//! ([`pe_sync::fetch_text_first`]), then the whole source in one FETCH, how far it is told for the status bar as it
//! comes. What is shown first is held in memory ([`Partials`]), never stored: Save As, View Source, Forward and the
//! attachments read the store, so they wait for the whole source as for a message not downloaded yet.

use std::collections::HashMap;
use std::sync::{Arc, Mutex, MutexGuard};

use pe_store::{FolderId, Store};

use super::{Failure, Worker};
use crate::Event;

/// A message over this size shows its text first
pub(crate) const TEXT_FIRST_OVER: u64 = 1024 * 1024;
/// How often the status bar hears how far a large message is: each time this much more came
const TOLD_EVERY: u64 = 1024 * 1024;

/// The text shown first of each large message being downloaded, by folder and UID
type ShownFirst = HashMap<(FolderId, u64), Arc<pe_sync::TextFirst>>;

/// The text shown first of the large messages being downloaded
#[derive(Clone, Default)]
pub(crate) struct Partials(Arc<Mutex<ShownFirst>>);

impl Partials {
    fn lock(&self) -> MutexGuard<'_, ShownFirst> {
        self.0.lock().unwrap_or_else(|p| p.into_inner())
    }

    pub(crate) fn get(&self, folder: FolderId, uid: u64) -> Option<Arc<pe_sync::TextFirst>> {
        self.lock().get(&(folder, uid)).cloned()
    }

    fn insert(&self, folder: FolderId, uid: u64, first: pe_sync::TextFirst) {
        self.lock().insert((folder, uid), Arc::new(first));
    }

    fn remove(&self, folder: FolderId, uid: u64) {
        self.lock().remove(&(folder, uid));
    }
}

impl Worker {
    /// Downloads a large message: its text first, shown at once ([`Event::MessageReady`]), then its whole source, how
    /// far it is told as it comes (that it is all here, once it is stored, by the reader). The source, and whether the
    /// window heard of it already.
    pub(super) async fn download_large(
        &mut self,
        store: &mut Store,
        folder: FolderId,
        uid: u64,
        size: u64,
    ) -> Result<(Vec<u8>, bool), Failure> {
        let client = self.client(store).await?;
        // a structure the text can not be had from first: the whole message as it comes
        let first = pe_sync::fetch_text_first(client, store, folder, uid).await?;
        let shown = first.is_some();
        if let Some(first) = first {
            self.ctx.partials.insert(folder, uid, first);
            self.emit(Event::MessageReady { folder, uid });
        }
        let source = self.download_told(store, folder, uid, size).await;
        // gone whatever happened: the whole source, or a failure the pane shows in its place
        self.ctx.partials.remove(folder, uid);
        Ok((source?, shown))
    }

    /// The whole source in one FETCH, how far it is told every [`TOLD_EVERY`] for the status bar
    async fn download_told(
        &mut self,
        store: &mut Store,
        folder: FolderId,
        uid: u64,
        size: u64,
    ) -> Result<Vec<u8>, Failure> {
        let events = self.ctx.events.clone();
        let mut told = 0;
        let client = self.client(store).await?;
        client.on_received(Some(Box::new(move |bytes| {
            if bytes / TOLD_EVERY > told / TOLD_EVERY {
                told = bytes;
                let text = crate::text::download_progress_text(bytes.min(size), size);
                events(Event::Transferring { text });
            }
        })));
        let fetched = pe_sync::fetch_raw(client, store, folder, uid).await;
        client.on_received(None);
        Ok(fetched?)
    }
}
