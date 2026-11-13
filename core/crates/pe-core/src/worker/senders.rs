//! The background worker's share of the senders' pictures (crate::senders): the provider's verdicts fetched with
//! the summaries read into bits and logo addresses, locally; then the verdicts of mail stored before they were
//! fetched, a FETCH of those header fields a batch at a time, newest first, after the rest of the background work.

use pe_store::Store;

use super::{Failure, Worker};
use crate::{Event, FailureKind, authres, senders};

/// How many messages are read or fetched at a time
const BATCH: usize = 100;

impl Worker {
    /// Reads the verdicts that wait in the store; how many messages that was (0: none waits). The lists are told when
    /// a logo turned up, so their rows show it
    pub(super) fn judge_senders(&mut self, store: &mut Store) -> Result<usize, Failure> {
        let pending = store.messages_to_judge(self.account, BATCH)?;
        if pending.is_empty() {
            return Ok(0);
        }
        let trusted = authres::trusted(&store.account(self.account)?.settings);
        let judged: Vec<(i64, senders::Judged)> = pending
            .iter()
            .map(|p| (p.message, senders::judge(&p.headers, &p.from_address, &trusted)))
            .collect();
        let logos = store.transaction(|store| {
            for (message, judged) in &judged {
                store.set_sender_auth(*message, judged.bits, judged.logo_url.as_deref())?;
            }
            Ok(judged.iter().any(|(_, judged)| judged.logo_url.is_some()))
        })?;
        if logos {
            self.emit(Event::FoldersChanged { account: self.account });
        }
        Ok(pending.len())
    }

    /// Fetches the verdicts of the newest messages stored before they came with the summary, for
    /// [`Self::judge_senders`]; how many messages that was (0: none is left). A batch the server refuses is taken as
    /// having none, so it is not asked for again
    pub(super) async fn fetch_sender_verdicts(&mut self, store: &mut Store) -> Result<usize, Failure> {
        let batch = store.messages_without_auth(self.account, BATCH)?;
        let Some(&(_, folder, _)) = batch.first() else {
            return Ok(0);
        };
        let messages: Vec<(i64, u64)> = batch
            .iter()
            .filter(|(_, f, _)| *f == folder)
            .map(|(message, _, uid)| (*message, *uid))
            .collect();
        let uids: Vec<u64> = messages.iter().map(|(_, uid)| *uid).collect();
        let client = self.client(store).await?;
        let fetched = match pe_sync::fetch_auth_headers(client, store, folder, &uids).await {
            Ok(fetched) => fetched,
            Err(error) => {
                let failure = Failure::from(error);
                if failure.kind != FailureKind::Other {
                    return Err(failure);
                }
                Vec::new()
            }
        };
        store.transaction(|store| {
            for (message, uid) in &messages {
                let headers = fetched
                    .iter()
                    .find(|(found, _)| found == uid)
                    .map_or("", |(_, headers)| headers.as_str());
                store.set_auth_headers(*message, headers)?;
            }
            Ok(())
        })?;
        Ok(messages.len())
    }
}
