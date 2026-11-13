//! Large messages (docs/open-speed-plan.md, phase 5): the text first, shown at once from its parts
//! ([`pe_sync::fetch_text_first`]), then the whole source in ranges of [`RANGE`], each told with how far it is
//! ([`Event::MessageProgress`]). What is shown first is held in memory ([`Partials`]), never stored: Save As, View
//! Source, Forward and the attachments wait for the whole source, as for a message not downloaded yet.

use std::collections::HashMap;
use std::sync::{Arc, Mutex};

use pe_store::{FolderId, Store};

use super::{Failure, Worker};
use crate::Event;

/// A message over this size shows its text first
pub(crate) const TEXT_FIRST_OVER: u64 = 1024 * 1024;
/// How much of a large message one FETCH brings
const RANGE: u64 = 1024 * 1024;

/// The text shown first of the large messages being downloaded, by folder and UID
pub(crate) type Partials = Arc<Mutex<HashMap<(FolderId, u64), Arc<pe_sync::TextFirst>>>>;

impl Worker {
    /// Downloads a large message: its text first, shown at once ([`Event::MessageReady`]), then the whole source in
    /// ranges, each told
    pub(super) async fn download_large(
        &mut self,
        store: &mut Store,
        folder: FolderId,
        uid: u64,
        size: u64,
    ) -> Result<Vec<u8>, Failure> {
        let client = self.client(store).await?;
        // a structure the text can not be had from first: the whole message as it comes
        if let Some(first) = pe_sync::fetch_text_first(client, store, folder, uid).await? {
            self.partials().insert((folder, uid), Arc::new(first));
            self.emit(Event::MessageReady { folder, uid });
        }
        let source = self.download_ranges(store, folder, uid, size).await;
        self.partials().remove(&(folder, uid));
        source
    }

    /// The whole source, a range at a time, each told with how far it is
    async fn download_ranges(
        &mut self,
        store: &mut Store,
        folder: FolderId,
        uid: u64,
        size: u64,
    ) -> Result<Vec<u8>, Failure> {
        let mut source = Vec::with_capacity(usize::try_from(size).unwrap_or(0));
        loop {
            let client = self.client(store).await?;
            let range = pe_sync::fetch_range(client, store, folder, uid, source.len() as u64, RANGE).await?;
            let last = (range.len() as u64) < RANGE;
            source.extend_from_slice(&range);
            let text = match last {
                true => crate::text::download_done_text(source.len() as u64),
                false => crate::text::download_progress_text(source.len() as u64, size.max(source.len() as u64)),
            };
            self.emit(Event::MessageProgress { folder, uid, text });
            if last {
                return Ok(source);
            }
        }
    }

    fn partials(&self) -> std::sync::MutexGuard<'_, HashMap<(FolderId, u64), Arc<pe_sync::TextFirst>>> {
        self.ctx.partials.lock().unwrap_or_else(|p| p.into_inner())
    }
}
