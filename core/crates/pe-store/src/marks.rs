//! Watch and Ignore Conversation: a mark on a conversation of an account (`thread_marks`, by its conversation id).
//! Every message of it, those that arrive later too, carries the mark ([`crate::Message::mark`]): the list shows it,
//! the core marks a message arriving in an ignored conversation read and announces one arriving in a watched one, and
//! [`crate::Search::hide_ignored`] leaves ignored conversations out of the list.
//!
//! When a late message joins two conversations into one ([`Store::thread_of`]), their marks go with it; when both
//! were marked differently, Watch wins: missing a reply one watches for is worse than seeing one of an ignored
//! conversation.

use std::collections::BTreeMap;

use rusqlite::{OptionalExtension, params};

use crate::{AccountId, MessageRef, Result, Store};

/// A conversation's mark
#[derive(Debug, Clone, Copy, PartialEq, Eq, Default, Hash, PartialOrd, Ord)]
pub enum ThreadMark {
    #[default]
    None,
    /// Watch Conversation: its new mail is always announced, and the list shows glasses
    Watch,
    /// Ignore Conversation: its new mail arrives read and unannounced, and the list shows it grey (or hides it)
    Ignore,
}

/// The number `thread_marks.mark` keeps of a mark that is not None; the lower one wins when conversations join
const WATCH: i64 = 1;
pub(crate) const IGNORE: i64 = 2;

impl ThreadMark {
    /// From `thread_marks.mark`, 0 (or anything else) for none
    pub(crate) fn of(number: i64) -> ThreadMark {
        match number {
            WATCH => ThreadMark::Watch,
            IGNORE => ThreadMark::Ignore,
            _ => ThreadMark::None,
        }
    }

    fn number(self) -> Option<i64> {
        match self {
            ThreadMark::None => None,
            ThreadMark::Watch => Some(WATCH),
            ThreadMark::Ignore => Some(IGNORE),
        }
    }
}

/// A conversation messages were picked in: its account, its id and its mark
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub struct Conversation {
    pub account: AccountId,
    pub thread: i64,
    pub mark: ThreadMark,
}

impl Store {
    /// The conversations of the messages `refs` (those still in the store), each once, in the order of `refs`. A
    /// message stored before conversations were kept is put into its conversation first, so a mark set on it lasts.
    pub fn conversations_of(&self, refs: &[MessageRef]) -> Result<Vec<Conversation>> {
        let mut found: Vec<Conversation> = Vec::new();
        let mut statement = self.db.prepare_cached(
            "SELECT m.id, f.account_id, m.thread_id FROM messages m JOIN folders f ON f.id = m.folder_id \
             WHERE m.folder_id = ?1 AND m.uid = ?2",
        )?;
        for r in refs {
            let Some((id, account, mut thread)) = statement
                .query_row(params![r.folder, r.uid], |row| {
                    Ok((row.get::<_, i64>(0)?, row.get(1)?, row.get::<_, i64>(2)?))
                })
                .optional()?
            else {
                continue;
            };
            if thread < 0 {
                thread = self.thread_message(id)?;
            }
            if !found.iter().any(|c| c.thread == thread) {
                found.push(Conversation {
                    account,
                    thread,
                    mark: self.thread_mark(thread)?,
                });
            }
        }
        Ok(found)
    }

    /// The mark of the conversation `thread`
    pub fn thread_mark(&self, thread: i64) -> Result<ThreadMark> {
        let number: Option<i64> = self
            .db
            .prepare_cached("SELECT mark FROM thread_marks WHERE thread_id = ?1")?
            .query_row([thread], |row| row.get(0))
            .optional()?;
        Ok(number.map_or(ThreadMark::None, ThreadMark::of))
    }

    /// Marks the conversation `thread` of `account`, or takes its mark away (None)
    pub fn set_thread_mark(&self, account: AccountId, thread: i64, mark: ThreadMark) -> Result<()> {
        match mark.number() {
            Some(number) => self
                .db
                .prepare_cached(
                    "INSERT INTO thread_marks (thread_id, account_id, mark) VALUES (?1, ?2, ?3) \
                 ON CONFLICT (thread_id) DO UPDATE SET mark = excluded.mark",
                )?
                .execute(params![thread, account, number])?,
            None => self
                .db
                .prepare_cached("DELETE FROM thread_marks WHERE thread_id = ?1")?
                .execute([thread])?,
        };
        Ok(())
    }

    /// The unread messages of the conversations `threads` in every folder, by folder (for one command a folder)
    pub fn unseen_in_threads(&self, threads: &[i64]) -> Result<BTreeMap<crate::FolderId, Vec<u64>>> {
        let mut found: BTreeMap<crate::FolderId, Vec<u64>> = BTreeMap::new();
        let mut statement = self
            .db
            .prepare_cached("SELECT folder_id, uid FROM messages WHERE thread_id = ?1 AND seen = 0 ORDER BY uid")?;
        for &thread in threads {
            for row in statement.query_map([thread], |row| Ok((row.get(0)?, row.get(1)?)))? {
                let (folder, uid) = row?;
                found.entry(folder).or_default().push(uid);
            }
        }
        Ok(found)
    }

    /// The folders the conversations `threads` have messages in, with their accounts: the lists that show their mark
    pub fn folders_of_threads(&self, threads: &[i64]) -> Result<Vec<(AccountId, crate::FolderId)>> {
        let mut found: Vec<(AccountId, crate::FolderId)> = Vec::new();
        let mut statement = self.db.prepare_cached(
            "SELECT DISTINCT f.account_id, m.folder_id FROM messages m JOIN folders f ON f.id = m.folder_id \
             WHERE m.thread_id = ?1",
        )?;
        for &thread in threads {
            for row in statement.query_map([thread], |row| Ok((row.get(0)?, row.get(1)?)))? {
                let row = row?;
                if !found.contains(&row) {
                    found.push(row);
                }
            }
        }
        found.sort_unstable();
        Ok(found)
    }

    /// The conversation `from` of `account` joined into `into`: its mark goes with it, Watch winning over Ignore
    pub(crate) fn merge_marks(&self, account: AccountId, from: i64, into: i64) -> Result<()> {
        let moved: Option<i64> = self
            .db
            .prepare_cached("DELETE FROM thread_marks WHERE thread_id = ?1 RETURNING mark")?
            .query_row([from], |row| row.get(0))
            .optional()?;
        if let Some(mark) = moved {
            self.db
                .prepare_cached(
                    "INSERT INTO thread_marks (thread_id, account_id, mark) VALUES (?1, ?2, ?3) \
                     ON CONFLICT (thread_id) DO UPDATE SET mark = MIN(mark, excluded.mark)",
                )?
                .execute(params![into, account, mark])?;
        }
        Ok(())
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::{AccountSettings, FolderId, FolderInfo, MessageInfo, Search, Sort};

    fn setup() -> (Store, AccountId, FolderId) {
        let store = Store::open_in_memory().unwrap();
        let account = store.add_account(&AccountSettings::example("a@example.com")).unwrap();
        let inbox = FolderInfo {
            path: "INBOX".into(),
            name: "INBOX".into(),
            selectable: true,
            ..Default::default()
        };
        store.set_folders(account, &[inbox]).unwrap();
        let folder = store.folders(account).unwrap()[0].id;
        (store, account, folder)
    }

    fn mail(uid: u64, at: i64, id: &str, answers: &[&str], seen: bool) -> MessageInfo {
        MessageInfo {
            uid,
            date: Some(at),
            subject: id.trim_matches(['<', '>']).into(),
            message_id: Some(id.into()),
            references: answers.iter().map(|a| a.to_string()).collect(),
            flags: if seen { vec!["\\Seen".into()] } else { Vec::new() },
            ..Default::default()
        }
    }

    fn at(folder: FolderId, uid: u64) -> MessageRef {
        MessageRef { folder, uid }
    }

    fn mark_of(store: &Store, folder: FolderId, uid: u64) -> ThreadMark {
        store.message(folder, uid).unwrap().unwrap().mark
    }

    #[test]
    fn a_mark_covers_the_conversation_and_mail_that_joins_it() {
        let (store, account, inbox) = setup();
        store
            .add_messages(
                inbox,
                &[
                    mail(1, 100, "<a@x>", &[], true),
                    mail(2, 200, "<b@x>", &["<a@x>"], true),
                    mail(3, 300, "<c@x>", &[], true),
                ],
            )
            .unwrap();
        let picked = store
            .conversations_of(&[at(inbox, 2), at(inbox, 1), at(inbox, 9)])
            .unwrap();
        assert_eq!(picked.len(), 1, "one conversation, once; a message not there left out");
        assert_eq!(picked[0].mark, ThreadMark::None);
        store
            .set_thread_mark(account, picked[0].thread, ThreadMark::Watch)
            .unwrap();
        assert_eq!(mark_of(&store, inbox, 1), ThreadMark::Watch);
        assert_eq!(mark_of(&store, inbox, 2), ThreadMark::Watch);
        assert_eq!(mark_of(&store, inbox, 3), ThreadMark::None);
        // a reply that arrives later carries it
        store
            .add_messages(inbox, &[mail(4, 400, "<d@x>", &["<a@x>", "<b@x>"], false)])
            .unwrap();
        assert_eq!(mark_of(&store, inbox, 4), ThreadMark::Watch);
        // taken away
        store
            .set_thread_mark(account, picked[0].thread, ThreadMark::None)
            .unwrap();
        assert_eq!(mark_of(&store, inbox, 4), ThreadMark::None);
        assert_eq!(store.thread_mark(picked[0].thread).unwrap(), ThreadMark::None);
    }

    #[test]
    fn joined_conversations_keep_a_mark_and_watch_wins() {
        let (store, account, inbox) = setup();
        // a and c start two conversations; b, arriving later, answers both and joins them
        store
            .add_messages(
                inbox,
                &[mail(1, 100, "<a@x>", &[], true), mail(2, 200, "<c@x>", &[], true)],
            )
            .unwrap();
        let a = store.conversations_of(&[at(inbox, 1)]).unwrap()[0].thread;
        let c = store.conversations_of(&[at(inbox, 2)]).unwrap()[0].thread;
        store.set_thread_mark(account, a, ThreadMark::Ignore).unwrap();
        store.set_thread_mark(account, c, ThreadMark::Watch).unwrap();
        store
            .add_messages(inbox, &[mail(3, 300, "<b@x>", &["<a@x>", "<c@x>"], false)])
            .unwrap();
        for uid in 1..=3 {
            assert_eq!(mark_of(&store, inbox, uid), ThreadMark::Watch, "message {uid}");
        }
        let marks: i64 = store
            .db
            .query_row("SELECT COUNT(*) FROM thread_marks", [], |row| row.get(0))
            .unwrap();
        assert_eq!(marks, 1, "the joined one's mark is gone with it");

        // an ignored one joining one without a mark stays ignored
        store
            .add_messages(
                inbox,
                &[mail(4, 400, "<e@x>", &[], true), mail(5, 500, "<f@x>", &[], true)],
            )
            .unwrap();
        let e = store.conversations_of(&[at(inbox, 4)]).unwrap()[0].thread;
        store.set_thread_mark(account, e, ThreadMark::Ignore).unwrap();
        store
            .add_messages(inbox, &[mail(6, 600, "<g@x>", &["<f@x>", "<e@x>"], false)])
            .unwrap();
        for uid in 4..=6 {
            assert_eq!(mark_of(&store, inbox, uid), ThreadMark::Ignore, "message {uid}");
        }
    }

    #[test]
    fn a_message_not_threaded_yet_is_threaded_to_be_marked() {
        let (store, account, inbox) = setup();
        store
            .add_messages(
                inbox,
                &[
                    mail(1, 100, "<a@x>", &[], true),
                    mail(2, 200, "<b@x>", &["<a@x>"], true),
                ],
            )
            .unwrap();
        // as mail stored before conversations were kept
        store.db.execute("UPDATE messages SET thread_id = -id", []).unwrap();
        store.db.execute("DELETE FROM thread_ids", []).unwrap();
        let picked = store.conversations_of(&[at(inbox, 2)]).unwrap();
        assert!(picked[0].thread > 0);
        store
            .set_thread_mark(account, picked[0].thread, ThreadMark::Ignore)
            .unwrap();
        // the rest of it joins it when threaded, mark and all
        store.thread_unthreaded(account, 100).unwrap();
        assert_eq!(mark_of(&store, inbox, 1), ThreadMark::Ignore);
        assert_eq!(mark_of(&store, inbox, 2), ThreadMark::Ignore);
    }

    #[test]
    fn hide_ignored_leaves_ignored_conversations_out() {
        let (store, account, inbox) = setup();
        store
            .add_messages(
                inbox,
                &[
                    mail(1, 100, "<a@x>", &[], true),
                    mail(2, 200, "<b@x>", &["<a@x>"], false),
                    mail(3, 300, "<c@x>", &[], false),
                    mail(4, 400, "<d@x>", &[], true),
                    mail(5, 500, "<e@x>", &["<d@x>"], true),
                ],
            )
            .unwrap();
        let a = store.conversations_of(&[at(inbox, 1)]).unwrap()[0].thread;
        let d = store.conversations_of(&[at(inbox, 4)]).unwrap()[0].thread;
        store.set_thread_mark(account, a, ThreadMark::Ignore).unwrap();
        store.set_thread_mark(account, d, ThreadMark::Watch).unwrap();
        let newest = Sort::default();
        let subjects = |search: &Search| -> Vec<String> {
            store
                .search(search, newest, 0, 10)
                .unwrap()
                .into_iter()
                .map(|m| m.info.subject)
                .collect()
        };

        // one row a message
        let shown = Search::folder(inbox);
        let hidden = Search {
            hide_ignored: true,
            ..Search::folder(inbox)
        };
        assert_eq!(subjects(&shown), ["e@x", "d@x", "c@x", "b@x", "a@x"]);
        assert_eq!(subjects(&hidden), ["e@x", "d@x", "c@x"]);
        assert_eq!(store.count_search(&shown).unwrap(), (5, 2));
        assert_eq!(store.count_search(&hidden).unwrap(), (3, 1));
        assert_eq!(store.count_rows(&hidden).unwrap(), 3);
        assert_eq!(store.search_index(&hidden, newest, inbox, 3).unwrap(), Some(2));
        assert_eq!(store.search_index(&hidden, newest, inbox, 2).unwrap(), None);
        assert_eq!(
            store.positions(&hidden, newest, &[at(inbox, 3), at(inbox, 1)]).unwrap(),
            [2]
        );
        assert_eq!(
            store.next_unread(&hidden, newest, inbox, 0).unwrap(),
            Some(at(inbox, 3)),
            "Next Unread passes the ignored one by"
        );
        let rows = store.search(&shown, newest, 0, 10).unwrap();
        let marks: Vec<ThreadMark> = rows.iter().map(|m| m.mark).collect();
        assert_eq!(
            marks,
            [
                ThreadMark::Watch,
                ThreadMark::Watch,
                ThreadMark::None,
                ThreadMark::Ignore,
                ThreadMark::Ignore
            ]
        );

        // grouped by conversation, collapsed and expanded
        let grouped = |hide_ignored: bool, open: Vec<i64>| Search {
            threads: Some(open),
            hide_ignored,
            ..Search::folder(inbox)
        };
        assert_eq!(subjects(&grouped(false, vec![])), ["d@x", "c@x", "a@x"]);
        assert_eq!(subjects(&grouped(true, vec![])), ["d@x", "c@x"]);
        assert_eq!(store.count_rows(&grouped(false, vec![a, d])).unwrap(), 5);
        assert_eq!(store.count_rows(&grouped(true, vec![a, d])).unwrap(), 3);
        assert_eq!(subjects(&grouped(true, vec![a, d])), ["d@x", "e@x", "c@x"]);
        assert_eq!(
            store
                .search_index(&grouped(true, vec![a, d]), newest, inbox, 3)
                .unwrap(),
            Some(2)
        );
        assert_eq!(
            store.search_index(&grouped(true, vec![d]), newest, inbox, 1).unwrap(),
            None
        );
        assert_eq!(
            store.refs_in_ranges(&grouped(true, vec![]), newest, &[(0, 2)]).unwrap(),
            [at(inbox, 4), at(inbox, 5), at(inbox, 3)]
        );
        let rows = store.search(&grouped(false, vec![]), newest, 0, 10).unwrap();
        assert_eq!(
            rows[2].mark,
            ThreadMark::Ignore,
            "a collapsed row carries its conversation's mark"
        );
        assert!(store.threads_with_replies(&grouped(true, vec![])).unwrap() == [d]);
    }

    #[test]
    fn unseen_messages_folders_and_picked_marks_of_conversations() {
        let (store, _, inbox) = setup();
        store
            .add_messages(
                inbox,
                &[
                    mail(1, 100, "<a@x>", &[], false),
                    mail(2, 200, "<b@x>", &["<a@x>"], true),
                    mail(3, 300, "<c@x>", &["<a@x>"], false),
                    mail(4, 400, "<d@x>", &[], false),
                ],
            )
            .unwrap();
        let a = store.conversations_of(&[at(inbox, 1)]).unwrap()[0].thread;
        let found = store.unseen_in_threads(&[a]).unwrap();
        assert_eq!(found.into_iter().collect::<Vec<_>>(), [(inbox, vec![1, 3])]);
        assert_eq!(store.folders_of_threads(&[a]).unwrap(), [(1, inbox)]);
        store.set_thread_mark(1, a, ThreadMark::Ignore).unwrap();
        let picked = store.picked(&[at(inbox, 2), at(inbox, 4)]).unwrap();
        assert_eq!(picked[0].mark, ThreadMark::Ignore);
        assert_eq!(picked[1].mark, ThreadMark::None);
    }
}
