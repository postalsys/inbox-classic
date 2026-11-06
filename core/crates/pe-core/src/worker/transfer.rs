//! Messages moved or copied to a folder of another account, by the worker of the account they come from: the message
//! from its server (or the store), into the other account's folder with an APPEND on a connection of that account, and
//! only once that server took it, out of its own folder. Each step is kept in the store (`transfers`), so a crash, a
//! quit or a lost connection in the middle loses nothing, and an APPEND tried before is not made twice.

use std::collections::{BTreeMap, BTreeSet};

use pe_store::{AccountId, FolderId, Store, Transfer};
use pe_sync::{expunge_messages, fetch_raw, has_message_id};

use super::{Failure, Outcome, Worker};
use pe_i18n::{Text, tr, tr_args};

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

/// A failure that trying again does not help
fn gone(message: &str) -> Failure {
    Failure {
        kind: FailureKind::Other,
        message: message.into(),
    }
}

impl Worker {
    /// Moves or copies every message waiting to go from this account, oldest first: each copied to its account, then
    /// the originals of the moves taken out of their folders with one command a folder. Stops at a failure of the
    /// network, leaving the rest for later (the next sync); a message that can not go is shown in its folder again and
    /// told. [`Event::Transferring`] says how far it is, and at the end what was done.
    pub(super) async fn transfer(&mut self, store: &mut Store) -> Outcome {
        let total = store.transfers_left(self.account)?;
        if total == 0 {
            return Ok(());
        }
        let mut others: BTreeMap<AccountId, Worker> = BTreeMap::new();
        let mut arrived: BTreeSet<FolderId> = BTreeSet::new();
        let mut back: BTreeSet<FolderId> = BTreeSet::new();
        // the originals of moves whose copies arrived: (transfer, folder, uid), out of their folders at the end
        let mut copied: Vec<(i64, FolderId, u64)> = Vec::new();
        let mut last = 0;
        let mut failed: Vec<(Transfer, Failure)> = Vec::new();
        let mut copy = false;
        let mut done = 0;
        let mut outcome = Ok(());
        while let Some(t) = store.next_transfer(self.account, last)? {
            last = t.id;
            done += 1;
            copy = t.copy;
            let target = store.folder(t.to).ok();
            let place = target.as_ref().map_or_else(
                || tr(Text::TransferAnotherAccount),
                |f| crate::text::folder_name(&f.info),
            );
            let text = if t.copy {
                Text::TransferCopying
            } else {
                Text::TransferMoving
            };
            self.emit(Event::Transferring {
                text: tr_args(
                    text,
                    &[
                        ("done", done.into()),
                        ("messages", (&messages(total)).into()),
                        ("folder", (&place).into()),
                    ],
                ),
            });
            let Some(target) = target else {
                // the folder it was going to is gone
                store.remove_transfer(t.id)?;
                back.insert(t.from);
                failed.push((t, gone(&tr(Text::TransferFolderGone))));
                continue;
            };
            let other = others
                .entry(target.account_id)
                .or_insert_with(|| self.sibling(target.account_id));
            match self.copy_over(store, other, &t, &target.info.path).await {
                Ok(()) => {
                    arrived.insert(t.to);
                    if t.copy {
                        store.remove_transfer(t.id)?;
                    } else {
                        copied.push((t.id, t.from, t.uid));
                    }
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
        // the originals of what arrived, a folder at a time; kept on their way until then, so a try after a failure
        // here finds the copies there and only takes these out
        let mut by_folder: BTreeMap<FolderId, Vec<(i64, u64)>> = BTreeMap::new();
        for (id, folder, uid) in copied {
            by_folder.entry(folder).or_default().push((id, uid));
        }
        let mut moved = 0;
        for (folder, items) in by_folder {
            let uids: Vec<u64> = items.iter().map(|(_, uid)| *uid).collect();
            let removed = match self.client(store).await {
                Ok(client) => expunge_messages(client, store, folder, &uids)
                    .await
                    .map_err(Failure::from),
                Err(failure) => Err(failure),
            };
            match removed {
                Ok(()) => {
                    for (id, _) in &items {
                        store.remove_transfer(*id)?;
                    }
                    moved += items.len();
                }
                Err(failure) => outcome = outcome.and(Err(failure)),
            }
        }
        let mut arrived_names: Vec<String> = Vec::new();
        for folder in &arrived {
            let name = crate::text::folder_name(&store.folder(*folder)?.info);
            if !arrived_names.contains(&name) {
                arrived_names.push(name);
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
        let went = if copy { done - failed.len() } else { moved };
        // the folder they went to by its name, as the status bar says it for a move in one account
        let place = match arrived_names.as_slice() {
            [one] => one.clone(),
            _ => tr(Text::TheirFolders),
        };
        let text = match (went > 0, copy) {
            (true, copy) => tr_args(
                if copy { Text::DoneCopied } else { Text::DoneMoved },
                &[
                    ("messages", (&messages(went as u64)).into()),
                    ("folder", (&place).into()),
                ],
            ),
            (false, true) => tr(Text::TransferNoneCopied),
            (false, false) => tr(Text::TransferNoneMoved),
        };
        self.emit(Event::Transferring { text });
        if let Some((first, failure)) = failed.first() {
            let text = if first.copy {
                Text::TransferNotCopied
            } else {
                Text::TransferNotMoved
            };
            self.fail(Failure {
                kind: FailureKind::Other,
                message: tr_args(
                    text,
                    &[
                        ("messages", (&messages(failed.len() as u64)).into()),
                        ("reason", (&failure.message).into()),
                    ],
                ),
            });
        }
        outcome
    }

    /// One message: its source, then an APPEND by `other`, unless a try before got it there
    async fn copy_over(&mut self, store: &mut Store, other: &mut Worker, t: &Transfer, to_path: &str) -> Outcome {
        let source = match &t.source {
            Some(source) => source.clone(),
            None => {
                let source = match fetch_raw(self.client(store).await?, store, t.from, t.uid).await {
                    Ok(source) => source,
                    Err(pe_sync::Error::MessageGone) => return Err(gone(&tr(Text::TransferNotOnServer))),
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
