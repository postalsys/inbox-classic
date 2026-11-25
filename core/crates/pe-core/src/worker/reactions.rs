//! New mail that is an emoji reaction (crate::reactions): before it is announced, each new reply to a message here is
//! looked at (small ones only, their source fetched as for a sign-in code); one the core recognises, from someone in
//! that message's conversation, is marked read on the server, taken out of the lists with its reaction kept
//! (pe-store reactions.rs), and announced as a reaction rather than as new mail.

use pe_store::reactions::ReactionRow;
use pe_store::{AccountId, FolderId, MessageRef, Store};

use super::{ANSWER_LIMIT, Failure, Worker, unix_now};
use crate::Event;

/// The largest reaction email looked at: the samples are 11 and 19 KB, with the whole message they answer quoted
const REACTION_SIZE_LIMIT: u64 = 256 * 1024;

/// A reaction taken out of new mail, the message it is for and that message's subject (for its notification)
pub(super) struct Reacted {
    pub row: ReactionRow,
    pub target: MessageRef,
    pub subject: String,
}

/// A new email that may be a reaction, by what the store knows of it: its UID, the message it answers and that
/// message's subject
struct Candidate {
    uid: u64,
    target: MessageRef,
    subject: String,
}

impl Worker {
    /// The messages `uids` of `folder` that are reactions, taken out of the lists; the others are left as they are.
    /// Each is looked at once: first by what the store knows (a small reply to a message here, from someone in its
    /// conversation), then those left by their sources, fetched in one command, and marked read in one more.
    pub(super) async fn take_reactions(
        &mut self,
        store: &mut Store,
        folder: FolderId,
        uids: &[u64],
    ) -> Result<Vec<Reacted>, Failure> {
        let mut candidates = Vec::new();
        for &uid in uids {
            if let Some(candidate) = candidate(store, self.account, folder, uid)? {
                candidates.push(candidate);
            }
        }
        if candidates.is_empty() {
            return Ok(Vec::new());
        }
        let wanted: Vec<u64> = candidates.iter().map(|c| c.uid).collect();
        let client = self.client(store).await?;
        client.limit_next_answer(ANSWER_LIMIT);
        let Ok(sources) = pe_sync::fetch_sources(client, store, folder, &wanted).await else {
            return Ok(Vec::new());
        };
        let trusted = crate::authres::verifiers(store, self.account)?;
        let mut found = Vec::new();
        for (uid, source) in sources {
            let Some(candidate) = candidates.iter().find(|c| c.uid == uid) else {
                continue;
            };
            let Ok(parsed) = pe_mime::parser::parse(&source) else {
                continue;
            };
            let Some(reaction) = crate::reactions::of(&source, &parsed, &trusted) else {
                continue;
            };
            let Some(message) = store.message(folder, uid)? else {
                continue;
            };
            let Some(original) = store.message(candidate.target.folder, candidate.target.uid)? else {
                continue;
            };
            if !in_conversation(&original.info, &reaction.from) {
                continue;
            }
            let row = ReactionRow {
                folder,
                uid,
                account: self.account,
                target: reaction.target,
                address: reaction.from,
                name: reaction.name,
                emoji: reaction.emoji,
                at: message
                    .info
                    .internal_date
                    .or(message.info.date)
                    .unwrap_or_else(unix_now),
            };
            found.push((row, source, candidate));
        }
        if found.is_empty() {
            return Ok(Vec::new());
        }
        let seen: Vec<u64> = found.iter().map(|(row, ..)| row.uid).collect();
        let client = self.client(store).await?;
        if pe_sync::set_flag(client, store, folder, &seen, "\\Seen", true)
            .await
            .is_err()
        {
            return Ok(Vec::new());
        }
        let mut taken = Vec::new();
        for (row, source, candidate) in found {
            if store.hide_as_reaction(&row, &source)? {
                // the reacted message's list shows its new reaction
                self.emit(Event::FolderChanged {
                    account: self.account,
                    folder: candidate.target.folder,
                });
                taken.push(Reacted {
                    row,
                    target: candidate.target,
                    subject: candidate.subject.clone(),
                });
            }
        }
        if !taken.is_empty() {
            self.emit(Event::FolderChanged {
                account: self.account,
                folder,
            });
        }
        Ok(taken)
    }
}

/// The new email `folder`/`uid` as a reaction may be, by what the store knows: a reply up to the size a reaction is,
/// to a message here, from that message's sender or one of its recipients, not looked at before. A reply is looked at
/// once, whatever comes of it (a reaction whose message is not here stays an ordinary email).
fn candidate(store: &Store, account: AccountId, folder: FolderId, uid: u64) -> Result<Option<Candidate>, Failure> {
    if store.looked_at(folder, uid)? {
        return Ok(None);
    }
    let Some(message) = store.message(folder, uid)? else {
        return Ok(None);
    };
    let Some(reply_to) = message.info.in_reply_to.as_deref() else {
        return Ok(None);
    };
    store.looked_at_for_reaction(folder, uid)?;
    if message.info.size.is_some_and(|size| size > REACTION_SIZE_LIMIT) {
        return Ok(None);
    }
    let Some(target) = store.find_message_id(account, reply_to)? else {
        return Ok(None);
    };
    let Some(original) = store.message(target.folder, target.uid)? else {
        return Ok(None);
    };
    if !in_conversation(&original.info, &message.info.from_address) {
        return Ok(None);
    }
    Ok(Some(Candidate {
        uid,
        target,
        subject: original.info.subject,
    }))
}

/// How many stored messages one background batch looks at for being reactions
const REACTIONS_BATCH: usize = 20;

impl Worker {
    /// Mail stored before reactions were recognised: the next batch of the walk through the account's stored replies
    /// (once through, from the newest), those that are reactions taken out as new ones are (not announced). How many
    /// were looked at.
    pub(super) async fn reactions_stored(&mut self, store: &mut Store) -> Result<usize, Failure> {
        if self.reactions_walk == 0 {
            return Ok(0);
        }
        let batch =
            store.reaction_candidates(self.account, REACTION_SIZE_LIMIT, self.reactions_walk, REACTIONS_BATCH)?;
        self.reactions_walk = match batch.last() {
            Some(&(id, ..)) if batch.len() == REACTIONS_BATCH => id,
            _ => 0,
        };
        let mut by_folder: std::collections::BTreeMap<FolderId, Vec<u64>> = std::collections::BTreeMap::new();
        for &(_, folder, uid) in &batch {
            by_folder.entry(folder).or_default().push(uid);
        }
        for (folder, uids) in by_folder {
            if crate::sender_cards_shown(&store.folder(folder)?.info) {
                Box::pin(self.take_reactions(store, folder, &uids)).await?;
            } else {
                for uid in uids {
                    store.looked_at_for_reaction(folder, uid)?;
                }
            }
        }
        Ok(batch.len())
    }

    /// A reaction announced as new mail is: "Kate Kalda reacted 👍" over "to “Furniture”" (or how many came)
    pub(super) fn announce_reaction(&self, newest: &Reacted, count: usize) {
        let who = crate::book::shown_name(&newest.row.name, &newest.row.address).to_string();
        let (title, text) = crate::text::reaction_words(&who, &newest.row.emoji, &newest.subject, count);
        self.emit(Event::NewMail {
            account: self.account,
            folder: newest.target.folder,
            uid: newest.target.uid,
            count,
            from: who,
            subject: newest.subject.clone(),
            watched: false,
            title,
            text,
        });
    }
}

/// Whether `address` is the sender of `message` or one of the people it was sent to
fn in_conversation(message: &pe_store::MessageInfo, address: &str) -> bool {
    let address = address.to_lowercase();
    message.from_address.to_lowercase() == address
        || message
            .recipient_people
            .to_lowercase()
            .split(|c: char| c.is_whitespace() || matches!(c, ',' | '<' | '>' | '"'))
            .any(|word| word == address)
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn the_reactor_is_in_the_conversation() {
        let message = pe_store::MessageInfo {
            from_address: "ann@example.org".into(),
            recipient_people: "Kate Kalda kate@studio.example, Bo <bo@x.example>".into(),
            ..Default::default()
        };
        assert!(in_conversation(&message, "Kate@Studio.example"));
        assert!(in_conversation(&message, "bo@x.example"));
        assert!(in_conversation(&message, "ANN@example.org"));
        // a part of an address is not the address
        assert!(!in_conversation(&message, "ate@studio.example"));
        assert!(!in_conversation(&message, "eve@studio.example"));
    }
}
