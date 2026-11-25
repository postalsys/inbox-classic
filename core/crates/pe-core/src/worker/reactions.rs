//! New mail that is an emoji reaction (crate::reactions): before it is announced, each new reply to a message here is
//! looked at (small ones only, their source fetched as for a sign-in code); one the core recognises, from someone in
//! that message's conversation, is marked read on the server, taken out of the lists with its reaction kept
//! (pe-store reactions.rs), and announced as a reaction rather than as new mail.

use pe_store::reactions::ReactionRow;
use pe_store::{FolderId, Store};

use super::{ANSWER_LIMIT, Failure, Worker, unix_now};
use crate::Event;

/// The largest reaction email looked at: the samples are 11 and 19 KB, with the whole message they answer quoted
const REACTION_SIZE_LIMIT: u64 = 256 * 1024;

/// A reaction taken out of new mail, and the subject of the message it is for (for its notification)
pub(super) struct Reacted {
    pub row: ReactionRow,
    pub subject: String,
}

impl Worker {
    /// The messages `uids` of `folder` that are reactions, taken out of the lists; the others are left as they are
    pub(super) async fn take_reactions(
        &mut self,
        store: &mut Store,
        folder: FolderId,
        uids: &[u64],
    ) -> Result<Vec<Reacted>, Failure> {
        let trusted = crate::authres::verifiers(store, self.account)?;
        let mut taken = Vec::new();
        for &uid in uids {
            let Some(message) = store.message(folder, uid)? else {
                continue;
            };
            let Some(reply_to) = message.info.in_reply_to.clone() else {
                continue;
            };
            if message.info.size.is_some_and(|size| size > REACTION_SIZE_LIMIT) {
                continue;
            }
            // a reaction without its message here stays an ordinary email
            let Some(at) = store.find_message_id(self.account, &reply_to)? else {
                continue;
            };
            let Some(original) = store.message(at.folder, at.uid)? else {
                continue;
            };
            let client = self.client(store).await?;
            client.limit_next_answer(ANSWER_LIMIT);
            let Ok(source) = pe_sync::fetch_source(client, store, folder, uid).await else {
                continue;
            };
            let Ok(parsed) = pe_mime::parser::parse(&source) else {
                continue;
            };
            let Some(reaction) = crate::reactions::of(&source, &parsed, &trusted) else {
                continue;
            };
            if !in_conversation(&original.info, &reaction.from) {
                continue;
            }
            let client = self.client(store).await?;
            if pe_sync::set_flag(client, store, folder, &[uid], "\\Seen", true)
                .await
                .is_err()
            {
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
            if store.hide_as_reaction(&row, &source)? {
                // the reacted message's list shows its new reaction
                self.emit(Event::FolderChanged {
                    account: self.account,
                    folder: at.folder,
                });
                taken.push(Reacted {
                    row,
                    subject: original.info.subject.clone(),
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

/// How many stored messages one background batch looks at for being reactions
const REACTIONS_BATCH: usize = 20;

impl Worker {
    /// Mail stored before reactions were recognised: a batch of the replies that may be reactions looked at, those
    /// that are taken out as new ones are (not announced). How many were looked at.
    pub(super) async fn reactions_stored(&mut self, store: &mut Store) -> Result<usize, Failure> {
        let candidates = store.reaction_candidates(self.account, REACTIONS_BATCH)?;
        let mut by_folder: std::collections::BTreeMap<FolderId, Vec<u64>> = std::collections::BTreeMap::new();
        for (folder, uid) in &candidates {
            by_folder.entry(*folder).or_default().push(*uid);
        }
        for (folder, uids) in by_folder {
            for uid in &uids {
                store.looked_at_for_reaction(folder, *uid)?;
            }
            Box::pin(self.take_reactions(store, folder, &uids)).await?;
        }
        Ok(candidates.len())
    }

    /// A reaction announced as new mail is: "Kate Kalda reacted 👍" over "to “Furniture”" (or how many came)
    pub(super) fn announce_reaction(&self, store: &Store, newest: &Reacted, count: usize) {
        let Ok(Some(at)) = store.find_message_id(self.account, &newest.row.target) else {
            return;
        };
        let who = if newest.row.name.is_empty() {
            newest.row.address.clone()
        } else {
            newest.row.name.clone()
        };
        let (title, text) = crate::text::reaction_words(&who, &newest.row.emoji, &newest.subject, count);
        self.emit(Event::NewMail {
            account: self.account,
            folder: at.folder,
            uid: at.uid,
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
