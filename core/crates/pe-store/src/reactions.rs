//! Emoji reactions (pe-core `reactions`): the reaction emails taken out of the lists and the reactions they carried.
//!
//! A reaction email recognised by the core leaves `messages` (so every list, count and conversation is as it was before
//! it came, through the triggers that keep them) and is kept here with its source, by its folder and UID: the sync
//! does not fetch it again, a deletion on the server takes it away, and Show as Email puts it back in the list (the
//! worker fetches it again). Its reaction is kept beside it, by the Message-ID of the message it is for.

use rusqlite::{OptionalExtension, params};

use crate::{AccountId, FolderId, Message, Result, Store};

/// A reaction someone sent to a message, as kept
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct ReactionRow {
    /// Where its email is (hidden): what Open Reaction Email and Show as Email take
    pub folder: FolderId,
    pub uid: u64,
    pub account: AccountId,
    /// The Message-ID of the reacted message, lower case, with its brackets
    pub target: String,
    /// The reacting person's address, lower case, and name
    pub address: String,
    pub name: String,
    pub emoji: String,
    /// When it arrived, seconds since 1970
    pub at: i64,
}

fn reaction_row(row: &rusqlite::Row) -> rusqlite::Result<ReactionRow> {
    Ok(ReactionRow {
        folder: row.get(0)?,
        uid: row.get(1)?,
        account: row.get(2)?,
        target: row.get(3)?,
        address: row.get(4)?,
        name: row.get(5)?,
        emoji: row.get(6)?,
        at: row.get(7)?,
    })
}

/// One emoji given to a message: (emoji, how many times, when first)
type Given = (String, u32, i64);

const REACTION_COLUMNS: &str = "folder_id, uid, account_id, target, address, name, emoji, at";

impl Store {
    /// The reaction email `folder`/`uid` taken out of the lists, kept with its `source`, and its `reaction`; nothing
    /// when it is not here (any longer)
    pub fn hide_as_reaction(&self, reaction: &ReactionRow, source: &[u8]) -> Result<bool> {
        self.atomic(|| {
            let removed = self.db.execute(
                "DELETE FROM messages WHERE folder_id = ?1 AND uid = ?2",
                params![reaction.folder, reaction.uid],
            )?;
            if removed == 0 {
                return Ok(false);
            }
            self.db.execute(
                "INSERT OR REPLACE INTO hidden_messages (folder_id, uid, source) VALUES (?1, ?2, ?3)",
                params![reaction.folder, reaction.uid, source],
            )?;
            self.db.execute(
                &format!(
                    "INSERT OR REPLACE INTO reactions ({REACTION_COLUMNS}) VALUES (?1, ?2, ?3, ?4, ?5, ?6, ?7, ?8)"
                ),
                params![
                    reaction.folder,
                    reaction.uid,
                    reaction.account,
                    reaction.target.to_lowercase(),
                    reaction.address.to_lowercase(),
                    reaction.name,
                    reaction.emoji,
                    reaction.at
                ],
            )?;
            Ok(true)
        })
    }

    /// The UIDs of a folder's hidden reaction emails, ascending: the sync counts them as known
    pub fn hidden_uids(&self, folder: FolderId) -> Result<Vec<u64>> {
        self.db
            .prepare_cached("SELECT uid FROM hidden_messages WHERE folder_id = ?1 ORDER BY uid")?
            .query_map([folder], |row| row.get(0))?
            .collect()
    }

    /// The source of a hidden reaction email (Open Reaction Email)
    pub fn hidden_source(&self, folder: FolderId, uid: u64) -> Result<Option<Vec<u8>>> {
        self.db
            .prepare_cached("SELECT source FROM hidden_messages WHERE folder_id = ?1 AND uid = ?2")?
            .query_row(params![folder, uid], |row| row.get(0))
            .optional()
    }

    /// A hidden reaction email let go with its reaction, for good (Show as Email: the worker fetches it into the list
    /// again, and it is never taken for a reaction again); whether it was hidden
    pub fn unhide(&self, folder: FolderId, uid: u64) -> Result<bool> {
        self.atomic(|| {
            self.looked_at_for_reaction(folder, uid)?;
            Ok(self.db.execute(
                "DELETE FROM hidden_messages WHERE folder_id = ?1 AND uid = ?2",
                params![folder, uid],
            )? > 0)
        })
    }

    /// Emails gone from the server: hidden ones let go with their reactions, and their marks (nothing to do in a
    /// folder without either)
    pub(crate) fn remove_hidden(&self, folder: FolderId, uids: &[u64]) -> Result<()> {
        let any: bool = self
            .db
            .prepare_cached(
                "SELECT EXISTS (SELECT 1 FROM hidden_messages WHERE folder_id = ?1) \
                 OR EXISTS (SELECT 1 FROM reaction_looked WHERE folder_id = ?1)",
            )?
            .query_row([folder], |row| row.get(0))?;
        if !any {
            return Ok(());
        }
        let mut hidden = self
            .db
            .prepare_cached("DELETE FROM hidden_messages WHERE folder_id = ?1 AND uid = ?2")?;
        let mut looked = self
            .db
            .prepare_cached("DELETE FROM reaction_looked WHERE folder_id = ?1 AND uid = ?2")?;
        for uid in uids {
            hidden.execute(params![folder, uid])?;
            looked.execute(params![folder, uid])?;
        }
        Ok(())
    }

    /// Each row's reactions ([`Message::reactions`]): to its message, or for a collapsed conversation's row to every
    /// message of its conversation, most given first. A page's reactions are read at once (they are few: one row a
    /// reaction ever received), and its collapsed conversations' Message-IDs in one query; nothing is read while no
    /// reaction is kept.
    pub fn add_reactions(&self, rows: &mut [Message]) -> Result<()> {
        use std::collections::HashMap;
        let mut given: HashMap<(AccountId, String), Vec<Given>> = HashMap::new();
        let mut statement = self.db.prepare_cached(
            "SELECT account_id, target, emoji, COUNT(*), MIN(at) FROM reactions GROUP BY account_id, target, emoji",
        )?;
        let mut found = statement.query([])?;
        while let Some(row) = found.next()? {
            given
                .entry((row.get(0)?, row.get(1)?))
                .or_default()
                .push((row.get(2)?, row.get(3)?, row.get(4)?));
        }
        if given.is_empty() {
            return Ok(());
        }
        let accounts: HashMap<FolderId, AccountId> = self
            .db
            .prepare_cached("SELECT id, account_id FROM folders")?
            .query_map([], |row| Ok((row.get(0)?, row.get(1)?)))?
            .collect::<rusqlite::Result<_>>()?;
        let threads: Vec<i64> = rows
            .iter()
            .filter_map(|m| m.thread.filter(crate::ThreadPlace::collapsed).map(|place| place.thread))
            .collect();
        let mut of_thread: HashMap<i64, Vec<String>> = HashMap::new();
        if !threads.is_empty() {
            let marks = vec!["?"; threads.len()].join(",");
            let mut statement = self.db.prepare(&format!(
                "SELECT thread_id, lower(message_id) FROM messages \
                 WHERE thread_id IN ({marks}) AND message_id IS NOT NULL"
            ))?;
            let mut found = statement.query(rusqlite::params_from_iter(&threads))?;
            while let Some(row) = found.next()? {
                of_thread.entry(row.get(0)?).or_default().push(row.get(1)?);
            }
        }
        for message in rows {
            let Some(&account) = accounts.get(&message.folder_id) else {
                continue;
            };
            let targets: Vec<String> = match message.thread.filter(crate::ThreadPlace::collapsed) {
                Some(place) => {
                    let mut ids = of_thread.remove(&place.thread).unwrap_or_default();
                    ids.sort_unstable();
                    ids.dedup();
                    ids
                }
                None => message.info.message_id.iter().map(|id| id.to_lowercase()).collect(),
            };
            let mut counts: Vec<(String, u32, i64)> = Vec::new();
            for target in targets {
                for (emoji, count, at) in given.get(&(account, target)).into_iter().flatten() {
                    match counts.iter_mut().find(|c| &c.0 == emoji) {
                        Some(c) => {
                            c.1 += count;
                            c.2 = c.2.min(*at);
                        }
                        None => counts.push((emoji.clone(), *count, *at)),
                    }
                }
            }
            counts.sort_by_key(|c| (std::cmp::Reverse(c.1), c.2));
            message.reactions = counts.into_iter().map(|(emoji, count, _)| (emoji, count)).collect();
        }
        Ok(())
    }

    /// Whether any reaction is kept: nothing to read for one while none is
    pub fn any_reactions(&self) -> Result<bool> {
        self.db
            .prepare_cached("SELECT EXISTS (SELECT 1 FROM reactions)")?
            .query_row([], |row| row.get(0))
    }

    /// Mail stored before reactions were recognised that may be reactions, a batch at a time, newest first from below
    /// `before` (a row id; the walk goes on from the last one given, once through the store): replies of the account
    /// up to `largest` bytes with first words (the core decides what a reaction is), not looked at yet. (row id,
    /// folder, UID); each is looked at once ([`Store::looked_at_for_reaction`]).
    pub fn reaction_candidates(
        &self,
        account: AccountId,
        largest: u64,
        before: i64,
        limit: usize,
    ) -> Result<Vec<(i64, FolderId, u64)>> {
        self.db
            .prepare_cached(
                "SELECT m.id, m.folder_id, m.uid FROM messages m JOIN folders f ON f.id = m.folder_id \
                 WHERE m.id < ?4 AND f.account_id = ?1 AND m.in_reply_to IS NOT NULL AND COALESCE(m.size, 0) <= ?2 \
                 AND m.snippet IS NOT NULL AND m.snippet != '' \
                 AND NOT EXISTS (SELECT 1 FROM reaction_looked l WHERE l.folder_id = m.folder_id AND l.uid = m.uid) \
                 ORDER BY m.id DESC LIMIT ?3",
            )?
            .query_map(params![account, largest as i64, limit as i64, before], |row| {
                Ok((row.get(0)?, row.get(1)?, row.get(2)?))
            })?
            .collect()
    }

    /// An email looked at for being a reaction, whatever it was: not looked at again
    pub fn looked_at_for_reaction(&self, folder: FolderId, uid: u64) -> Result<()> {
        self.db.execute(
            "INSERT OR IGNORE INTO reaction_looked (folder_id, uid) VALUES (?1, ?2)",
            params![folder, uid],
        )?;
        Ok(())
    }

    /// Whether an email was looked at for being a reaction (or listed again with Show as Email)
    pub fn looked_at(&self, folder: FolderId, uid: u64) -> Result<bool> {
        self.db
            .prepare_cached("SELECT EXISTS (SELECT 1 FROM reaction_looked WHERE folder_id = ?1 AND uid = ?2)")?
            .query_row(params![folder, uid], |row| row.get(0))
    }

    /// The reactions to the message `target` (its Message-ID with its brackets) of `account`, oldest first
    pub fn reactions_to(&self, account: AccountId, target: &str) -> Result<Vec<ReactionRow>> {
        self.db
            .prepare_cached(&format!(
                "SELECT {REACTION_COLUMNS} FROM reactions WHERE account_id = ?1 AND target = ?2 ORDER BY at, uid"
            ))?
            .query_map(params![account, target.to_lowercase()], reaction_row)?
            .collect()
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::test_support::*;

    /// A store with an account and its Inbox: (store, account, inbox)
    fn with_inbox() -> (Store, AccountId, FolderId) {
        let (store, inbox, _) = store_of("ann@example.org");
        let account = store.folder(inbox).unwrap().account_id;
        (store, account, inbox)
    }

    fn add(store: &Store, folder: FolderId, uids: &[u64]) {
        let messages: Vec<_> = uids
            .iter()
            .map(|&uid| message_to(uid, "Hi", ("Kate", "kate@studio.example"), "ann@example.org"))
            .collect();
        store.add_messages(folder, &messages).unwrap();
    }

    fn reaction(folder: FolderId, uid: u64, account: AccountId, emoji: &str) -> ReactionRow {
        ReactionRow {
            folder,
            uid,
            account,
            target: "<Original@Example.org>".into(),
            address: "Kate@Studio.example".into(),
            name: "Kate".into(),
            emoji: emoji.into(),
            at: 100 + uid as i64,
        }
    }

    #[test]
    fn a_reaction_email_leaves_the_lists_and_comes_back() {
        let (store, account, inbox) = with_inbox();
        add(&store, inbox, &[1, 2, 3]);
        let before = store.folder(inbox).unwrap();
        assert!(
            store
                .hide_as_reaction(&reaction(inbox, 3, account, "👍"), b"source")
                .unwrap()
        );
        // out of the folder and its counts, kept here
        assert_eq!(store.uids(inbox).unwrap(), [1, 2]);
        assert_eq!(store.folder(inbox).unwrap().total, before.total - 1);
        assert_eq!(store.hidden_uids(inbox).unwrap(), [3]);
        assert_eq!(store.hidden_source(inbox, 3).unwrap().as_deref(), Some(&b"source"[..]));
        let found = store.reactions_to(account, "<original@example.org>").unwrap();
        assert_eq!(
            (found.len(), found[0].emoji.as_str(), found[0].address.as_str()),
            (1, "👍", "kate@studio.example")
        );
        // a message that is not here is not hidden
        assert!(
            !store
                .hide_as_reaction(&reaction(inbox, 9, account, "🎉"), b"x")
                .unwrap()
        );
        // gone from the server: let go
        store.remove_hidden(inbox, &[3]).unwrap();
        assert!(store.hidden_uids(inbox).unwrap().is_empty());
        assert!(
            store
                .reactions_to(account, "<original@example.org>")
                .unwrap()
                .is_empty()
        );
        // Show as Email: let go too
        assert!(
            store
                .hide_as_reaction(&reaction(inbox, 2, account, "❤️"), b"y")
                .unwrap()
        );
        assert!(store.unhide(inbox, 2).unwrap());
        assert!(store.hidden_uids(inbox).unwrap().is_empty());
        // and never taken for a reaction again, though it comes back as a new row
        assert!(store.looked_at(inbox, 2).unwrap());
    }

    #[test]
    fn a_row_carries_its_reactions_most_first() {
        let (store, account, inbox) = with_inbox();
        let mut original = message_to(1, "Furniture", ("Ann", "ann@example.org"), "kate@studio.example");
        original.message_id = Some("<Original@Example.org>".into());
        store.add_messages(inbox, &[original]).unwrap();
        add(&store, inbox, &[2, 3, 4]);
        for (uid, emoji) in [(2, "❤️"), (3, "👍"), (4, "👍")] {
            store
                .hide_as_reaction(&reaction(inbox, uid, account, emoji), b"s")
                .unwrap();
        }
        let mut rows = store.messages(inbox, crate::Sort::default(), 0, 10).unwrap();
        store.add_reactions(&mut rows).unwrap();
        assert_eq!(rows.len(), 1);
        assert_eq!(rows[0].reactions, [("👍".to_string(), 2), ("❤️".to_string(), 1)]);
    }

    #[test]
    fn stored_replies_are_looked_at_once() {
        let (store, account, inbox) = with_inbox();
        let reply = |uid: u64, words: &str| {
            let mut message = message_to(uid, "Re: Hi", ("Kate", "kate@studio.example"), "ann@example.org");
            message.in_reply_to = Some("<original@example.org>".into());
            store.add_messages(inbox, &[message]).unwrap();
            let id = id_of(&store, inbox, uid);
            let text = crate::IndexText {
                snippet: words.into(),
                ..Default::default()
            };
            store.set_indexed(id, &text).unwrap();
        };
        reply(1, "👍 Kate reacted via Gmail");
        reply(2, "[like]  Kate reacted to your message:");
        // not a reply
        add(&store, inbox, &[4]);
        let found = |before| -> Vec<(FolderId, u64)> {
            store
                .reaction_candidates(account, 1 << 18, before, 10)
                .unwrap()
                .into_iter()
                .map(|(_, folder, uid)| (folder, uid))
                .collect()
        };
        assert_eq!(found(i64::MAX), [(inbox, 2), (inbox, 1)]);
        // the walk goes on below the last row given
        assert_eq!(found(id_of(&store, inbox, 2)), [(inbox, 1)]);
        store.looked_at_for_reaction(inbox, 2).unwrap();
        assert_eq!(found(i64::MAX), [(inbox, 1)]);
    }

    #[test]
    fn a_folder_reset_or_removed_takes_its_hidden_ones() {
        let (store, account, inbox) = with_inbox();
        add(&store, inbox, &[1]);
        store
            .hide_as_reaction(&reaction(inbox, 1, account, "👍"), b"s")
            .unwrap();
        store.reset_folder(inbox, Some(7)).unwrap();
        assert!(store.hidden_uids(inbox).unwrap().is_empty());
        assert!(
            store
                .reactions_to(account, "<original@example.org>")
                .unwrap()
                .is_empty()
        );
    }
}
