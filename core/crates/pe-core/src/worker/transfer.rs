//! Messages moved or copied to a folder of another account, by the worker of the account they come from: the message
//! from its server (or the store), into the other account's folder with an APPEND on a connection of that account, and
//! only once that server took it, out of its own folder. Each step is kept in the store (`transfers`), so a crash, a
//! quit or a lost connection in the middle loses nothing, and an APPEND tried before is not made twice.

use std::collections::{BTreeMap, BTreeSet};

use pe_store::{AccountId, FolderId, Store, Transfer};
use pe_sync::{expunge_messages, fetch_raw, has_message_id};

use super::{Failure, Outcome, Worker};
use crate::text::messages;
use crate::{Event, FailureKind};

/// Flags an APPEND can carry: system flags and keywords, as atoms; not `\Recent` (the server's to set) or `\Deleted`
fn appendable(flags: &str) -> Vec<&str> {
    flags
        .split(' ')
        .filter(|f| !f.is_empty() && !f.eq_ignore_ascii_case("\\Recent") && !f.eq_ignore_ascii_case("\\Deleted"))
        .filter(|f| {
            let name = f.strip_prefix('\\').unwrap_or(f);
            !name.is_empty()
                && name
                    .bytes()
                    .all(|b| b.is_ascii_graphic() && !b"(){%*\"\\]".contains(&b))
        })
        .collect()
}

impl Worker {
    /// Moves or copies every message waiting to go from this account, oldest first. Stops at a failure of the network,
    /// leaving the rest for later (the next sync); a message that can not go is shown in its folder again and told.
    pub(super) async fn transfer(&mut self, store: &mut Store) -> Outcome {
        let total = store.transfers_left(self.account)?;
        if total == 0 {
            return Ok(());
        }
        let mut others: BTreeMap<AccountId, Worker> = BTreeMap::new();
        let mut arrived: BTreeSet<FolderId> = BTreeSet::new();
        let mut back: BTreeSet<FolderId> = BTreeSet::new();
        let mut failed: Vec<(Transfer, Failure)> = Vec::new();
        let mut done = 0;
        let mut outcome = Ok(());
        while let Some(t) = store.next_transfer(self.account)? {
            done += 1;
            let target = store.folder(t.to).ok();
            let verb = if t.copy { "Copying" } else { "Moving" };
            let place = target
                .as_ref()
                .map_or_else(|| "another account".into(), |f| crate::text::folder_name(&f.info));
            self.emit(Event::Transferring {
                text: Some(format!("{verb} {done} of {} to {place}...", messages(total))),
            });
            let Some(target) = target else {
                // the folder it was going to is gone
                store.remove_transfer(t.id)?;
                back.insert(t.from);
                failed.push((
                    t,
                    Failure {
                        kind: FailureKind::Other,
                        message: "the folder it was going to is no longer there".into(),
                    },
                ));
                continue;
            };
            let other = match others.entry(target.account_id) {
                std::collections::btree_map::Entry::Occupied(entry) => entry.into_mut(),
                std::collections::btree_map::Entry::Vacant(entry) => entry.insert(self.sibling(target.account_id)),
            };
            match self.transfer_one(store, other, &t, &target.info.path).await {
                Ok(()) => {
                    store.remove_transfer(t.id)?;
                    arrived.insert(t.to);
                }
                Err(failure) if failure.kind != FailureKind::Other => {
                    // not reachable now: kept, to go with the next sync
                    outcome = Err(failure);
                    break;
                }
                Err(failure) => {
                    store.remove_transfer(t.id)?;
                    back.insert(t.from);
                    failed.push((t, failure));
                }
            }
        }
        for folder in arrived {
            let account = store.folder(folder)?.account_id;
            if let Some(other) = others.get_mut(&account)
                && let Err(failure) = other.sync_one(store, folder).await
            {
                self.fail(failure);
            }
        }
        // those that did not go are still on the server: a sync shows them again
        for folder in back {
            if let Err(failure) = self.sync_one(store, folder).await {
                self.fail(failure);
            }
        }
        self.emit(Event::Transferring { text: None });
        if let Some((first, failure)) = failed.first() {
            let verb = if first.copy { "copied" } else { "moved" };
            self.fail(Failure {
                kind: FailureKind::Other,
                message: format!(
                    "{} could not be {verb} to another account: {}",
                    messages(failed.len() as u64),
                    failure.message
                ),
            });
        }
        outcome
    }

    /// One message: its source, an APPEND by `other` (unless a try before got it there), then, for a move, out of the
    /// folder it came from
    async fn transfer_one(&mut self, store: &mut Store, other: &mut Worker, t: &Transfer, to_path: &str) -> Outcome {
        let source = match &t.source {
            Some(source) => source.clone(),
            None => {
                let source = match fetch_raw(self.client(store).await?, store, t.from, t.uid).await {
                    Ok(source) => source,
                    Err(pe_sync::Error::MessageGone) => {
                        return Err(Failure {
                            kind: FailureKind::Other,
                            message: "the message is no longer on the server".into(),
                        });
                    }
                    Err(error) => return Err(error.into()),
                };
                store.set_transfer_source(t.id, &source)?;
                source
            }
        };
        let there = match (&t.message_id, t.tried) {
            (Some(id), true) => has_message_id(other.client(store).await?, store, t.to, id).await?,
            _ => false,
        };
        if !there {
            store.set_transfer_tried(t.id)?;
            let flags = appendable(&t.flags);
            other
                .client(store)
                .await?
                .append(to_path, &source, &flags, t.internal_date)
                .await?;
        }
        if !t.copy {
            expunge_messages(self.client(store).await?, store, t.from, &[t.uid]).await?;
        }
        Ok(())
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn only_flags_an_append_can_carry() {
        assert_eq!(
            appendable("$Junk \\Deleted \\Flagged \\Recent \\Seen bad(flag \\"),
            vec!["$Junk", "\\Flagged", "\\Seen"]
        );
        assert!(appendable("").is_empty());
    }
}
