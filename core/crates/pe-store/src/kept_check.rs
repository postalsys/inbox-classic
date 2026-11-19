//! What the store keeps (counts.rs: each folder's counts, each conversation's row; keyset.rs: places from sort keys)
//! against what the messages say, after random writes of every kind: messages stored, stored again, flagged, read,
//! removed, moved between conversations, re-dated, folders reset and removed, conversations marked. Every list read
//! from what is kept equals the list read from the messages, row for row, with its counts, places and neighbours.

use std::collections::{BTreeMap, HashMap};

use pe_testkit::Rng;
use rusqlite::params;
use rusqlite::types::Value;

use crate::counts::RECOUNT;
use crate::{
    AccountId, AccountSettings, Anchor, FolderId, FolderInfo, Message, MessageInfo, MessageRef, Result, Scope, Search,
    Show, Sort, SortField, Store, ThreadMark,
};

/// `f` with every list read from its messages, as before anything was kept
fn recounted<T>(f: impl FnOnce() -> T) -> T {
    RECOUNT.with(|r| r.set(true));
    let found = f();
    RECOUNT.with(|r| r.set(false));
    found
}

/// The rows `sql` reads, every column
fn rows(db: &rusqlite::Connection, sql: &str) -> Vec<Vec<Value>> {
    let mut statement = db.prepare(sql).unwrap();
    let columns = statement.column_count();
    statement
        .query_map([], |row| (0..columns).map(|i| row.get(i)).collect())
        .unwrap()
        .map(Result::unwrap)
        .collect()
}

/// What the store keeps: the folders' counts and the conversations
fn kept(db: &rusqlite::Connection) -> (Vec<Vec<Value>>, Vec<Vec<Value>>) {
    (
        rows(
            db,
            "SELECT id, total, unread, flagged, threads FROM folders ORDER BY id",
        ),
        rows(db, "SELECT * FROM conversations ORDER BY folder_id, thread_id"),
    )
}

/// The store under test, with what the test knows of it
struct World {
    store: Store,
    rng: Rng,
    accounts: Vec<AccountId>,
    /// The Message-IDs given so far, which new mail answers
    ids: Vec<String>,
    next_uid: HashMap<FolderId, u64>,
}

/// Each account's folders: an Inbox, Sent and Drafts or Trash, a folder of their own
fn folder_list(account: usize) -> Vec<FolderInfo> {
    let folder = |path: &str, special: Option<&str>| FolderInfo {
        path: path.into(),
        name: path.into(),
        special_use: special.map(str::to_string),
        selectable: true,
        ..Default::default()
    };
    if account == 0 {
        vec![
            folder("INBOX", None),
            folder("Archive", None),
            folder("Sent", Some("\\Sent")),
            folder("Drafts", Some("\\Drafts")),
        ]
    } else {
        vec![
            folder("Inbox", None),
            folder("Sent Items", Some("\\Sent")),
            folder("Trash", Some("\\Trash")),
        ]
    }
}

impl World {
    fn new(seed: u64) -> World {
        let store = Store::open_in_memory().unwrap();
        let mut accounts = Vec::new();
        for (index, email) in ["a@example.com", "b@example.org"].into_iter().enumerate() {
            let account = store.add_account(&AccountSettings::example(email)).unwrap();
            store.set_folders(account, &folder_list(index)).unwrap();
            accounts.push(account);
        }
        World {
            store,
            rng: Rng::new(seed),
            accounts,
            ids: Vec::new(),
            next_uid: HashMap::new(),
        }
    }

    fn folders(&self) -> Vec<FolderId> {
        self.store
            .db
            .prepare("SELECT id FROM folders ORDER BY id")
            .unwrap()
            .query_map([], |row| row.get(0))
            .unwrap()
            .map(Result::unwrap)
            .collect()
    }

    /// A message stored in the folder (`uid` new, or one there already)
    fn stored(&mut self, folder: FolderId) -> Vec<(FolderId, u64)> {
        self.store
            .db
            .prepare("SELECT folder_id, uid FROM messages WHERE folder_id = ?1 ORDER BY uid")
            .unwrap()
            .query_map([folder], |row| Ok((row.get(0)?, row.get(1)?)))
            .unwrap()
            .map(Result::unwrap)
            .collect()
    }

    fn flags(&mut self) -> Vec<String> {
        let mut flags = Vec::new();
        for (flag, percent) in [
            ("\\Seen", 60),
            ("\\Flagged", 15),
            ("\\flagged", 5),
            ("\\Answered", 20),
            ("$Label1", 10),
        ] {
            if self.rng.chance(percent) {
                flags.push(flag.to_string());
            }
        }
        flags
    }

    fn message(&mut self, uid: u64) -> MessageInfo {
        let r = &mut self.rng;
        let id = format!("<m{}@x>", self.ids.len());
        // replies name earlier messages, or ones not here yet
        let mut references = Vec::new();
        if !self.ids.is_empty() && r.chance(50) {
            for _ in 0..1 + r.below(3) {
                references.push(r.pick(&self.ids).clone());
            }
        }
        if r.chance(5) {
            references.push(format!("<m{}@x>", self.ids.len() + 1 + r.below(5) as usize));
        }
        // dates in a narrow range, so they tie; never both missing (the first message of a conversation is the
        // first by arrival, and a message without either has none)
        let received = (!r.chance(10)).then(|| 1000 + r.below(60) as i64 * 10);
        let date = if received.is_none() || r.chance(80) {
            Some(990 + r.below(70) as i64 * 10)
        } else {
            None
        };
        let names = ["Ann", "ann", "Bob", "", "Émile", "Zed", "İpek"];
        let subjects = ["Hello", "hello", "Re: Hello", "Budget", "", "Ärger", "zebra"];
        let name = r.pick(&names).to_string();
        let subject = r.pick(&subjects).to_string();
        let recipients = r.pick(&["Ann", "Bob", "", "carol@x"]).to_string();
        let size = (!r.chance(10)).then(|| r.below(5) * 100);
        // OpenPGP: some signed, some encrypted, as the sync reads them from the structure
        let protection = *r.pick(&[
            crate::Protection::None,
            crate::Protection::None,
            crate::Protection::None,
            crate::Protection::None,
            crate::Protection::None,
            crate::Protection::None,
            crate::Protection::Signed,
            crate::Protection::Encrypted,
        ]);
        let flags = self.flags();
        self.ids.push(id.clone());
        MessageInfo {
            uid,
            flags,
            internal_date: received,
            date,
            size,
            subject,
            from_address: format!("{}@example.com", name.to_lowercase()),
            from_name: name,
            recipients,
            message_id: Some(id),
            in_reply_to: references.last().cloned(),
            references,
            protection,
            ..Default::default()
        }
    }

    /// One random write, of every kind: what the sync, the user's commands and the background workers write
    fn write(&mut self) {
        let folders = self.folders();
        let folder = *self.rng.pick(&folders);
        let stored = self.stored(folder);
        let one = (!stored.is_empty()).then(|| *self.rng.pick(&stored));
        match (self.rng.below(100), one) {
            (0..=34, _) => self.new_mail(folder, one),
            (35..=49, Some((folder, uid))) => {
                let flags = self.flags();
                self.store.set_flags(folder, uid, &flags, None).unwrap();
            }
            (50..=56, Some((folder, uid))) => {
                let flag = *self.rng.pick(&["\\Seen", "\\Flagged", "\\Answered"]);
                let on = self.rng.chance(50);
                self.store.set_flag(folder, uid, flag, on).unwrap();
            }
            (57..=60, _) => {
                let uids = self.some_of(&stored, 40);
                self.store
                    .change_flags_many(folder, &uids, &["\\Flagged"], &["\\Seen"])
                    .unwrap();
            }
            (61..=63, _) => {
                self.store.mark_all_seen(folder).unwrap();
            }
            (64..=75, _) => {
                let uids = self.some_of(&stored, 25);
                self.store.remove_messages(folder, &uids).unwrap();
            }
            (76..=80, Some(at)) => self.join_conversations(at),
            (81..=82, Some(at)) => self.thread_again(at),
            (83..=84, Some(at)) => self.redate(at),
            (85, Some(at)) => self.decrypt(at),
            (86..=88, Some(at)) => self.mark_conversation(at),
            (89..=90, _) => {
                if self.rng.chance(50) {
                    self.store.reset_folder(folder, Some(self.rng.below(9))).unwrap();
                }
            }
            (91..=92, _) => self.folder_gone_and_back(),
            (93, _) => self.account_removed_and_added(),
            (94.., _) => self.rolled_back(folder, one),
            _ => {}
        }
    }

    /// The UIDs of about `percent` in a hundred of `stored`
    fn some_of(&mut self, stored: &[(FolderId, u64)], percent: u64) -> Vec<u64> {
        stored
            .iter()
            .filter(|_| self.rng.chance(percent))
            .map(|s| s.1)
            .collect()
    }

    /// New mail, a few at a time, sometimes with one stored before again (only its flags change)
    fn new_mail(&mut self, folder: FolderId, one: Option<(FolderId, u64)>) {
        let mut batch = Vec::new();
        for _ in 0..1 + self.rng.below(4) {
            let uid = self.next_uid.entry(folder).or_insert(1);
            let current = *uid;
            *uid += 1 + self.rng.below(2);
            batch.push(self.message(current));
        }
        if let Some((_, uid)) = one
            && self.rng.chance(30)
        {
            let mut again = self.message(uid);
            again.subject = "never written".into();
            batch.push(again);
        }
        self.store.add_messages(folder, &batch).unwrap();
    }

    /// An encrypted message decrypted for the index, its protected Subject shown in the list (which moves it in the
    /// Subject order and may make it its conversation's first); now and then the switch turned off, which puts every
    /// Subject back
    fn decrypt(&mut self, (folder, uid): (FolderId, u64)) {
        if self.rng.chance(20) {
            self.store.forget_decrypted().unwrap();
            return;
        }
        let subject = *self
            .rng
            .pick(&["Aardvark plans", "zz inside", "Hello", "Ärger im Haus"]);
        let text = crate::IndexText {
            body: "the inside".into(),
            snippet: "the inside".into(),
            ..Default::default()
        };
        self.store.index_decrypted(folder, uid, &text, Some(subject)).unwrap();
        // a move the server refused: the row comes back as it came, nothing decrypted left in it unmarked
        if self.rng.chance(30)
            && let Some(message) = self.store.message(folder, uid).unwrap()
        {
            self.store.remove_messages(folder, &[uid]).unwrap();
            self.store.add_messages(folder, &[message.info]).unwrap();
            let back = self.store.message(folder, uid).unwrap().unwrap();
            assert!(!back.info.decrypted && back.info.outer_subject.is_none() && back.info.sender_people.is_empty());
        }
    }

    /// References fetched later join conversations
    fn join_conversations(&mut self, (folder, uid): (FolderId, u64)) {
        if self.ids.is_empty() {
            return;
        }
        let id = self.store.message(folder, uid).unwrap().unwrap().id;
        let parent = self.rng.pick(&self.ids).clone();
        self.store.set_references(id, &[parent]).unwrap();
    }

    /// As mail stored before conversations were kept, threaded again later
    fn thread_again(&mut self, (folder, uid): (FolderId, u64)) {
        self.store
            .db
            .execute(
                "UPDATE messages SET thread_id = -id WHERE folder_id = ?1 AND uid = ?2",
                params![folder, uid],
            )
            .unwrap();
        let account = self.store.folder(folder).unwrap().account_id;
        self.store.thread_unthreaded(account, 3).unwrap();
    }

    /// What it is placed by changed in place
    fn redate(&mut self, (folder, uid): (FolderId, u64)) {
        let received = 1000 + self.rng.below(60) as i64 * 10;
        let date = 990 + self.rng.below(70) as i64 * 10;
        let size = self.rng.below(5) as i64 * 100;
        self.store
            .db
            .execute(
                "UPDATE messages SET internal_date = ?3, date = ?4, size = ?5 WHERE folder_id = ?1 AND uid = ?2",
                params![folder, uid, received, date, size],
            )
            .unwrap();
    }

    /// Watch or Ignore Conversation, or neither
    fn mark_conversation(&mut self, (folder, uid): (FolderId, u64)) {
        let Some(thread) = self.store.message(folder, uid).unwrap().unwrap().info.thread_id else {
            return;
        };
        let account = self.store.folder(folder).unwrap().account_id;
        let mark = *self
            .rng
            .pick(&[ThreadMark::None, ThreadMark::Watch, ThreadMark::Ignore]);
        self.store.set_thread_mark(account, thread, mark).unwrap();
    }

    /// A folder gone from the server, with its messages, and back
    fn folder_gone_and_back(&mut self) {
        let index = self.rng.below(self.accounts.len() as u64) as usize;
        let mut list = folder_list(index);
        list.remove(1 + self.rng.below(list.len() as u64 - 1) as usize);
        self.store.set_folders(self.accounts[index], &list).unwrap();
        self.store
            .set_folders(self.accounts[index], &folder_list(index))
            .unwrap();
    }

    /// An account removed with all its mail, and added again
    fn account_removed_and_added(&mut self) {
        if !self.rng.chance(30) {
            return;
        }
        let index = self.rng.below(self.accounts.len() as u64) as usize;
        self.store.remove_account(self.accounts[index]).unwrap();
        let email = format!("again{}@example.net", self.rng.number());
        let account = self.store.add_account(&AccountSettings::example(&email)).unwrap();
        self.store.set_folders(account, &folder_list(index)).unwrap();
        self.accounts[index] = account;
    }

    /// Writes rolled back: nothing of them stays
    fn rolled_back(&mut self, folder: FolderId, one: Option<(FolderId, u64)>) {
        let uid = *self.next_uid.entry(folder).or_insert(1);
        let batch = [self.message(uid + 1000)];
        let _: Result<()> = self.store.atomic(|| {
            self.store.add_messages(folder, &batch)?;
            if let Some((folder, uid)) = one {
                self.store.remove_messages(folder, &[uid])?;
            }
            Err(rusqlite::Error::QueryReturnedNoRows)
        });
    }

    /// The folders' counts and the conversations kept equal those counted from the messages
    fn check_kept(&self) {
        let db = &self.store.db;
        assert_eq!(
            rows(
                db,
                "SELECT id, total, unread, flagged, threads FROM folders ORDER BY id"
            ),
            rows(
                db,
                concat!(
                    "SELECT f.id, (SELECT COUNT(*) FROM messages m WHERE m.folder_id = f.id), \
                     (SELECT COUNT(*) FROM messages m WHERE m.folder_id = f.id AND m.seen = 0), \
                     (SELECT COUNT(*) FROM messages m WHERE m.folder_id = f.id AND ",
                    is_flagged!("m."),
                    "), (SELECT COUNT(DISTINCT thread_id) FROM messages m WHERE m.folder_id = f.id) \
                     FROM folders f ORDER BY f.id"
                )
            ),
            "the folders' counts"
        );
        // as the migration counts them
        assert_eq!(
            rows(db, "SELECT * FROM conversations ORDER BY folder_id, thread_id"),
            rows(db, concat!(conversations_counted!(), " ORDER BY folder_id, thread_id")),
            "the conversations"
        );
        let flagged = Search {
            scope: Scope::Flagged,
            ..Default::default()
        };
        assert_eq!(
            self.store.flagged_count().unwrap(),
            self.store.count_search(&flagged).unwrap().0
        );
        let inboxes = Search {
            scope: Scope::AllInboxes,
            ..Default::default()
        };
        assert_eq!(
            self.store.inbox_unread().unwrap(),
            recounted(|| self.store.count_search(&inboxes).unwrap().1)
        );
        // each account's, as an agent's overview reads them
        for &account in &self.accounts {
            let counted = |scope| {
                let search = Search {
                    scope,
                    accounts: Some(vec![account]),
                    ..Default::default()
                };
                recounted(|| self.store.count_search(&search).unwrap())
            };
            let (inbox, inbox_unread) = counted(Scope::AllInboxes);
            let kept = crate::AccountCounts {
                inbox,
                inbox_unread,
                flagged: counted(Scope::Flagged).0,
                drafts: counted(Scope::AllDrafts).0,
            };
            assert_eq!(self.store.account_counts(account).unwrap(), kept);
        }
    }

    /// A random list as the windows show them
    fn list(&mut self) -> (Search, Sort) {
        let folders = self.folders();
        let r = &mut self.rng;
        let scope = match r.below(10) {
            0 => Scope::AllInboxes,
            1 => Scope::AllSent,
            2 => Scope::AllDrafts,
            3 => Scope::Everywhere,
            4 => Scope::Flagged,
            _ => Scope::Folder(*r.pick(&folders)),
        };
        let show = *r.pick(&[Show::All, Show::All, Show::All, Show::Unread, Show::Flagged]);
        let read_since = (show == Show::Unread && r.chance(50)).then(|| *r.pick(&[0, i64::MAX / 2]));
        let field = *r.pick(&[
            SortField::Date,
            SortField::Date,
            SortField::Received,
            SortField::From,
            SortField::To,
            SortField::Subject,
            SortField::Size,
        ]);
        let sort = Sort {
            field,
            ascending: r.chance(50),
        };
        let threads = match r.below(3) {
            0 => None,
            1 => Some(Vec::new()),
            _ => {
                // a few open, some not in the list
                let threads: Vec<i64> = self
                    .store
                    .db
                    .prepare("SELECT DISTINCT thread_id FROM messages")
                    .unwrap()
                    .query_map([], |row| row.get(0))
                    .unwrap()
                    .map(Result::unwrap)
                    .collect();
                let mut open: Vec<i64> = threads.into_iter().filter(|_| r.chance(30)).collect();
                open.push(987_654);
                Some(open)
            }
        };
        // now and then a search of a mark: its terms read the messages, in pages from a row next to them too
        let text = r
            .pick(&["", "", "", "", "", "is:encrypted", "is:signed", "-is:encrypted"])
            .to_string();
        // now and then an agent's list: the accounts it may use, one, none or all
        let accounts = match r.below(6) {
            0 => Some(vec![self.accounts[0]]),
            1 => Some(Vec::new()),
            2 => Some(self.accounts.clone()),
            _ => None,
        };
        let search = Search {
            scope,
            show,
            threads,
            hide_ignored: r.chance(30),
            read_since,
            text,
            accounts,
            ..Default::default()
        };
        (search, sort)
    }

    /// A search of a mark finds the messages that have it and no other
    fn check_marks(&self, search: &Search, sort: Sort, what: &str) {
        let wanted: fn(crate::Protection) -> bool = match search.text.as_str() {
            "is:encrypted" => |p| p == crate::Protection::Encrypted,
            "is:signed" => |p| p == crate::Protection::Signed,
            "-is:encrypted" => |p| p != crate::Protection::Encrypted,
            _ => return,
        };
        let found = self.store.search(&search.ungrouped(), sort, 0, 10_000).unwrap();
        assert!(found.iter().all(|m| wanted(m.info.protection)), "{what}");
    }

    /// Every call of the list reads what it read from the messages: rows, counts, places, neighbours, Next Unread and
    /// pages read from a row next to them
    fn check_list(&mut self, search: &Search, sort: Sort) {
        let what = format!("{search:?} {sort:?}");
        let all = self.store.search(search, sort, 0, 10_000).unwrap();
        assert_eq!(
            all,
            recounted(|| self.store.search(search, sort, 0, 10_000).unwrap()),
            "{what}"
        );
        self.check_counts(search, &all, &what);
        let members: Vec<MessageRef> = self
            .store
            .search(&search.ungrouped(), sort, 0, 10_000)
            .unwrap()
            .iter()
            .map(Message::at)
            .collect();
        self.check_marks(search, sort, &what);
        self.check_places(search, sort, &all, &members, &what);
        self.check_walks(search, sort, &all, &members, &what);
        self.check_anchored_pages(search, sort, &all, &what);
    }

    /// The counts of the list `all`, Select All's numbers and what Expand All opens
    fn check_counts(&self, search: &Search, all: &[Message], what: &str) {
        let store = &self.store;
        let counted = store.count_search(search).unwrap();
        assert_eq!(counted, recounted(|| store.count_search(search).unwrap()), "{what}");
        assert_eq!(store.count_rows(search).unwrap(), all.len() as u64, "{what}");
        assert_eq!(
            store.search_summary(search).unwrap(),
            recounted(|| store.search_summary(search).unwrap()),
            "{what}"
        );
        // Select All's bound, with nothing stored since
        let bounded = Search {
            up_to: Some(store.newest_message().unwrap()),
            ..search.clone()
        };
        assert_eq!(store.count_search(&bounded).unwrap(), counted, "{what}");
        if search.threads.is_some() {
            let mut replies = store.threads_with_replies(search).unwrap();
            let mut before = recounted(|| store.threads_with_replies(search).unwrap());
            replies.sort_unstable();
            before.sort_unstable();
            assert_eq!(replies, before, "{what}");
        }
    }

    /// Each message's row in the list `all` (its messages `members`): one by one, and several at once
    fn check_places(&mut self, search: &Search, sort: Sort, all: &[Message], members: &[MessageRef], what: &str) {
        let store = &self.store;
        // read off the rows: a collapsed one stands for its conversation's messages
        let mut row_of: BTreeMap<MessageRef, u64> = BTreeMap::new();
        for (index, row) in all.iter().enumerate() {
            match row.thread.filter(|t| t.collapsed()) {
                Some(place) => {
                    for member in store.thread_messages(search, place.thread).unwrap() {
                        row_of.insert(member.at(), index as u64);
                    }
                }
                None => {
                    row_of.insert(row.at(), index as u64);
                }
            }
        }
        assert_eq!(members.len(), row_of.len(), "{what}");
        for at in members {
            assert_eq!(
                store.search_index(search, sort, at.folder, at.uid).unwrap(),
                row_of.get(at).copied(),
                "{what} {at:?}"
            );
        }
        assert_eq!(
            store.search_index(search, sort, OUTSIDE.folder, OUTSIDE.uid).unwrap(),
            None
        );
        // placed one by one and by one ranking of the list
        let few: Vec<MessageRef> = members
            .iter()
            .copied()
            .filter(|_| self.rng.chance(10))
            .take(crate::selection::FEW)
            .collect();
        let mut expected: Vec<u64> = few.iter().filter_map(|at| row_of.get(at).copied()).collect();
        expected.sort_unstable();
        expected.dedup();
        assert_eq!(self.store.positions(search, sort, &few).unwrap(), expected, "{what}");
        let many: Vec<MessageRef> = members.iter().copied().chain([OUTSIDE]).collect();
        let mut expected: Vec<u64> = row_of.values().copied().collect();
        expected.sort_unstable();
        expected.dedup();
        if many.len() > crate::selection::FEW {
            assert_eq!(self.store.positions(search, sort, &many).unwrap(), expected, "{what}");
        }
    }

    /// The rows next to each message, and the next unread one below it
    fn check_walks(&mut self, search: &Search, sort: Sort, all: &[Message], members: &[MessageRef], what: &str) {
        let store = &self.store;
        if search.threads.is_some() {
            for at in members.iter().filter(|_| self.rng.chance(30)).chain([&OUTSIDE]) {
                assert_eq!(
                    store.next_unread(search, sort, at.folder, at.uid).unwrap(),
                    recounted(|| store.next_unread(search, sort, at.folder, at.uid).unwrap()),
                    "{what} {at:?}"
                );
            }
            return;
        }
        for (index, at) in members.iter().enumerate() {
            let next = (
                index.checked_sub(1).map(|i| members[i]),
                members.get(index + 1).copied(),
            );
            assert_eq!(
                store.neighbours(search, sort, at.folder, at.uid).unwrap(),
                Some(next),
                "{what} {at:?}"
            );
            let unread = all[index + 1..].iter().find(|m| !m.info.seen()).map(Message::at);
            assert_eq!(
                store.next_unread(search, sort, at.folder, at.uid).unwrap(),
                unread,
                "{what} {at:?}"
            );
        }
        assert_eq!(
            store.neighbours(search, sort, OUTSIDE.folder, OUTSIDE.uid).unwrap(),
            None
        );
    }

    /// Pages of the list `all` read from the row above them, the row below them and the end of the list
    fn check_anchored_pages(&mut self, search: &Search, sort: Sort, all: &[Message], what: &str) {
        let size = 1 + self.rng.below(4);
        for offset in (0..all.len() as u64 + 2).step_by(size as usize) {
            let page: Vec<Message> = all.iter().skip(offset as usize).take(size as usize).cloned().collect();
            let mut anchors = vec![Anchor::End(all.len() as u64)];
            if let Some(above) = offset.checked_sub(1).and_then(|i| all.get(i as usize)) {
                anchors.push(Anchor::Above(above.at()));
            }
            if let Some(below) = all.get((offset + size) as usize) {
                anchors.push(Anchor::Below(below.at()));
            }
            for anchor in anchors {
                assert_eq!(
                    self.store.search_from(search, sort, offset, size, anchor).unwrap(),
                    page,
                    "{what} page {offset}+{size} from {anchor:?}"
                );
            }
        }
    }
}

/// A message no list has
const OUTSIDE: MessageRef = MessageRef { folder: -5, uid: 1 };

#[test]
fn what_is_kept_follows_every_write() {
    for seed in [1, 0x9e37_79b9, 0x1234_5678_9abc] {
        let mut world = World::new(seed);
        for step in 0..400 {
            world.write();
            world.check_kept();
            if step % 8 == 0 {
                for _ in 0..6 {
                    let (search, sort) = world.list();
                    world.check_list(&search, sort);
                }
            }
        }
    }
}

/// A store from before the counts were kept gets them with the migration, as the triggers would have kept them
#[test]
fn the_migration_counts_what_was_stored_before() {
    let mut world = World::new(77);
    for _ in 0..300 {
        world.write();
    }
    let before = kept(&world.store.db);
    // the schema as it was before: no counts, no conversations, the orders over every folder without the folder
    world.store.db.execute_batch(
        "DROP TRIGGER messages_counted; DROP TRIGGER messages_uncounted; DROP TRIGGER messages_flags_counted; \
         DROP TRIGGER messages_recounted; DROP TRIGGER conversations_counted; DROP TRIGGER conversations_uncounted; \
         DROP TABLE conversations; \
         ALTER TABLE folders DROP COLUMN total; ALTER TABLE folders DROP COLUMN unread; \
         ALTER TABLE folders DROP COLUMN flagged; ALTER TABLE folders DROP COLUMN threads; \
         DROP INDEX messages_all_by_from; DROP INDEX messages_all_by_subject; DROP INDEX messages_read_at; \
         DROP INDEX messages_all_by_date; DROP INDEX messages_all_by_received; \
         CREATE INDEX messages_all_by_date ON messages (COALESCE(MIN(date, internal_date), date, internal_date), uid, id); \
         CREATE INDEX messages_all_by_received ON messages (internal_date, uid, id); \
         DROP INDEX messages_to_decrypt; ALTER TABLE messages DROP COLUMN protection; \
         ALTER TABLE messages DROP COLUMN decrypted; ALTER TABLE messages DROP COLUMN outer_subject; \
         DROP TABLE drafts_taken; DROP TABLE agent_reads; ALTER TABLE agent_log DROP COLUMN kind; \
         ALTER TABLE agent_log DROP COLUMN args; ALTER TABLE agent_log DROP COLUMN call_id; \
         ALTER TABLE agent_log DROP COLUMN hidden; ALTER TABLE agent_log DROP COLUMN changes; \
         DROP TABLE invitation_replies;",
    )
    .unwrap();
    // from the migration that counts, and those after it
    let counts = crate::schema::MIGRATIONS
        .iter()
        .position(|m| m.contains("CREATE TABLE conversations"))
        .unwrap();
    let db = &mut world.store.db;
    db.pragma_update(None, "user_version", counts).unwrap();
    crate::schema::migrate(db).unwrap();
    assert_eq!(kept(&world.store.db), before);
    // and keeps them from then on
    for _ in 0..100 {
        world.write();
    }
    world.check_kept();
}
