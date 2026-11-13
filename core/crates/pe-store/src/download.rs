//! Messages downloaded ahead, before the user opens them (docs/open-speed-plan.md, phase 3): the setting, which
//! messages are next, how much the sources of an account take, and the oldest removed past the limit the user set.

use rusqlite::{OptionalExtension, params};

use crate::{AccountId, FolderId, Result, Store};

const AHEAD: &str = "download.ahead";
const LIMIT: &str = "download.limit_mb";

/// What is downloaded before it is opened
#[derive(Debug, Clone, Copy, PartialEq, Eq, Default)]
pub enum Ahead {
    /// The last [`RECENT_DAYS`] days' messages up to [`RECENT_MAX_SIZE`]
    #[default]
    Recent,
    /// Every message, while the limit lets it
    All,
    /// None: a message is downloaded when it is opened
    Never,
}

impl Ahead {
    fn key(self) -> &'static str {
        match self {
            Ahead::Recent => "recent",
            Ahead::All => "all",
            Ahead::Never => "never",
        }
    }

    fn of(key: &str) -> Ahead {
        match key {
            "all" => Ahead::All,
            "never" => Ahead::Never,
            _ => Ahead::Recent,
        }
    }
}

/// How many days back [`Ahead::Recent`] reaches
pub const RECENT_DAYS: i64 = 30;
/// The largest message [`Ahead::Recent`] downloads
pub const RECENT_MAX_SIZE: u64 = 1024 * 1024;
/// The sources an account keeps at most, out of the box, in megabytes
pub const DEFAULT_LIMIT_MB: u64 = 1024;

/// The folders whose mail is not downloaded ahead: spam, the deleted, and Gmail's All Mail (the other folders' mail
/// again)
const NOT_AHEAD: &str = "COALESCE(f.special_use, '') NOT IN ('\\Junk', '\\Trash', '\\All')";

/// The Date order of the list ([`crate::messages`]' LIST_DATE), of the messages `n` and `m`
const LIST_DATE_N: &str = "COALESCE(MIN(n.date, n.internal_date), n.date, n.internal_date)";
const LIST_DATE_M: &str = "COALESCE(MIN(m.date, m.internal_date), m.date, m.internal_date)";

/// Which messages are downloaded next
#[derive(Debug, Clone, Copy, PartialEq, Eq, Default)]
pub struct AheadRule {
    /// Only those that arrived since (seconds since the Unix epoch)
    pub since: Option<i64>,
    /// Only those up to this size
    pub max_size: Option<u64>,
    /// Only those that arrived after it: when the limit is reached, nothing older than what is kept already
    pub newer_than: Option<i64>,
}

/// A message to download: (message id, UID, size)
pub type ToDownload = (i64, u64, u64);

impl Store {
    /// Options' and Settings' "Download messages ahead"
    pub fn download_ahead(&self) -> Result<Ahead> {
        Ok(self
            .text_setting(AHEAD)?
            .map_or_else(Ahead::default, |key| Ahead::of(&key)))
    }

    pub fn set_download_ahead(&self, ahead: Ahead) -> Result<()> {
        self.set_text_setting(AHEAD, ahead.key())
    }

    /// "Keep at most [n] MB of downloaded messages for each account"
    pub fn download_limit_mb(&self) -> Result<u64> {
        Ok(self
            .text_setting(LIMIT)?
            .and_then(|value| value.parse().ok())
            .unwrap_or(DEFAULT_LIMIT_MB))
    }

    pub fn set_download_limit_mb(&self, megabytes: u64) -> Result<()> {
        self.set_text_setting(LIMIT, &megabytes.to_string())
    }

    /// How many bytes the downloaded sources of an account take
    pub fn downloaded_size(&self, account: AccountId) -> Result<u64> {
        self.db.query_row(
            "SELECT COALESCE(SUM(b.size), 0) FROM bodies b JOIN messages m ON m.id = b.message_id \
             JOIN folders f ON f.id = m.folder_id WHERE f.account_id = ?1",
            params![account],
            |row| row.get(0),
        )
    }

    /// When the oldest message of an account whose source is kept arrived
    pub fn oldest_downloaded(&self, account: AccountId) -> Result<Option<i64>> {
        self.db.query_row(
            "SELECT MIN(m.internal_date) FROM bodies b JOIN messages m ON m.id = b.message_id \
             JOIN folders f ON f.id = m.folder_id WHERE f.account_id = ?1",
            params![account],
            |row| row.get(0),
        )
    }

    /// The next messages of an account to download ahead: of one folder (the Inbox first, then the others in their
    /// order), the newest first, together at most `budget` bytes (one at least). None when there is nothing to.
    pub fn messages_to_download(
        &self,
        account: AccountId,
        rule: &AheadRule,
        budget: u64,
    ) -> Result<Option<(FolderId, Vec<ToDownload>)>> {
        let folders: Vec<FolderId> = self
            .db
            .prepare_cached(&format!(
                "SELECT f.id FROM folders f WHERE f.account_id = ?1 AND f.selectable = 1 AND {NOT_AHEAD} \
                 ORDER BY f.path <> 'INBOX', f.position, f.id"
            ))?
            .query_map(params![account], |row| row.get(0))?
            .collect::<rusqlite::Result<_>>()?;
        let mut statement = self.db.prepare_cached(
            "SELECT m.id, m.uid, COALESCE(m.size, 0) FROM messages m \
             WHERE m.folder_id = ?1 AND m.fetch_failed = 0 \
             AND NOT EXISTS (SELECT 1 FROM bodies b WHERE b.message_id = m.id) \
             AND (?2 IS NULL OR m.internal_date >= ?2) AND (?3 IS NULL OR COALESCE(m.size, 0) <= ?3) \
             AND (?4 IS NULL OR m.internal_date > ?4) \
             ORDER BY m.internal_date DESC, m.uid DESC LIMIT 200",
        )?;
        for folder in folders {
            let rows: Vec<ToDownload> = statement
                .query_map(
                    params![folder, rule.since, rule.max_size.map(|s| s as i64), rule.newer_than],
                    |row| Ok((row.get(0)?, row.get(1)?, row.get(2)?)),
                )?
                .collect::<rusqlite::Result<_>>()?;
            if rows.is_empty() {
                continue;
            }
            let mut total = 0;
            let batch: Vec<ToDownload> = rows
                .into_iter()
                .take_while(|(_, _, size)| {
                    let first = total == 0;
                    total += size.max(&1);
                    first || total <= budget
                })
                .collect();
            return Ok(Some((folder, batch)));
        }
        Ok(None)
    }

    /// Messages that could not be downloaded ahead, or whose source the parser could not read: not tried again in the
    /// background (opening one still tries)
    pub fn mark_fetch_failed(&self, message: i64) -> Result<()> {
        self.db
            .execute("UPDATE messages SET fetch_failed = 1 WHERE id = ?1", params![message])?;
        Ok(())
    }

    /// Removes the sources of an account's oldest messages until they take at most `limit` bytes; never those of
    /// Drafts, nor those `spare` names (opened since the app started). How many bytes that freed.
    pub fn remove_oldest_sources(
        &self,
        account: AccountId,
        limit: u64,
        spare: &dyn Fn(FolderId, u64) -> bool,
    ) -> Result<u64> {
        let mut over = self.downloaded_size(account)?.saturating_sub(limit);
        if over == 0 {
            return Ok(0);
        }
        let oldest: Vec<(i64, FolderId, u64, u64)> = self
            .db
            .prepare_cached(
                "SELECT b.message_id, m.folder_id, m.uid, b.size FROM bodies b JOIN messages m ON m.id = b.message_id \
                 JOIN folders f ON f.id = m.folder_id \
                 WHERE f.account_id = ?1 AND COALESCE(f.special_use, '') <> '\\Drafts' \
                 ORDER BY COALESCE(m.internal_date, m.date), m.id",
            )?
            .query_map(params![account], |row| {
                Ok((row.get(0)?, row.get(1)?, row.get(2)?, row.get(3)?))
            })?
            .collect::<rusqlite::Result<_>>()?;
        let mut remove = self.db.prepare_cached("DELETE FROM bodies WHERE message_id = ?1")?;
        let mut freed = 0;
        for (message, folder, uid, size) in oldest {
            if over == 0 {
                break;
            }
            if spare(folder, uid) {
                continue;
            }
            remove.execute(params![message])?;
            freed += size;
            over = over.saturating_sub(size);
        }
        Ok(freed)
    }

    /// The messages next to one in its folder's list by date, the one above and the one below, those not downloaded
    /// yet nor failed: what Next and Previous open after it. (UID, size)
    pub fn neighbors_to_download(&self, folder: FolderId, uid: u64) -> Result<Vec<(u64, u64)>> {
        let mut found = Vec::new();
        for (compare, order) in [(">", "ASC"), ("<", "DESC")] {
            let next: Option<(u64, u64)> = self
                .db
                .prepare_cached(&format!(
                    "SELECT n.uid, COALESCE(n.size, 0) FROM messages n, messages m \
                     WHERE m.folder_id = ?1 AND m.uid = ?2 AND n.folder_id = ?1 \
                     AND ({LIST_DATE_N}, n.uid) {compare} ({LIST_DATE_M}, m.uid) \
                     ORDER BY {LIST_DATE_N} {order}, n.uid {order} LIMIT 1"
                ))?
                .query_row(params![folder, uid], |row| Ok((row.get(0)?, row.get(1)?)))
                .optional()?;
            found.extend(next);
        }
        let mut wanted = Vec::new();
        for (uid, size) in found {
            let pending: bool = self.db.query_row(
                "SELECT fetch_failed = 0 AND NOT EXISTS (SELECT 1 FROM bodies b WHERE b.message_id = messages.id) \
                 FROM messages WHERE folder_id = ?1 AND uid = ?2",
                params![folder, uid],
                |row| row.get(0),
            )?;
            if pending {
                wanted.push((uid, size));
            }
        }
        Ok(wanted)
    }

    /// Removes messages on their way to another folder of the account, their sources kept for the rows they become
    /// there ([`Store::adopt_moved_sources`]) or for theirs again ([`Store::restore_moved_sources`])
    pub fn remove_moving_messages(&self, folder: FolderId, uids: &[u64]) -> Result<usize> {
        let mut keep = self.db.prepare_cached(
            "INSERT OR REPLACE INTO moving_sources (folder_id, uid, source) \
             SELECT m.folder_id, m.uid, b.source FROM messages m JOIN bodies b ON b.message_id = m.id \
             WHERE m.folder_id = ?1 AND m.uid = ?2",
        )?;
        for uid in uids {
            keep.execute(params![folder, uid])?;
        }
        self.remove_messages(folder, uids)
    }

    /// The sources of moved messages given to the rows they became in `to` (`moved`: the UIDs in `from` and in `to`,
    /// from COPYUID); those of `uids` that found none are dropped
    pub fn adopt_moved_sources(&self, from: FolderId, to: FolderId, uids: &[u64], moved: &[(u64, u64)]) -> Result<()> {
        let mut adopt = self.db.prepare_cached(
            "INSERT OR REPLACE INTO bodies (message_id, source, size) \
             SELECT m.id, s.source, length(s.source) FROM moving_sources s, messages m \
             WHERE s.folder_id = ?1 AND s.uid = ?2 AND m.folder_id = ?3 AND m.uid = ?4",
        )?;
        for (uid, became) in moved {
            adopt.execute(params![from, uid, to, became])?;
        }
        self.forget_moved_sources(from, uids)
    }

    /// The sources of messages whose move failed, back with their rows
    pub fn restore_moved_sources(&self, folder: FolderId, uids: &[u64]) -> Result<()> {
        let mut restore = self.db.prepare_cached(
            "INSERT OR REPLACE INTO bodies (message_id, source, size) \
             SELECT m.id, s.source, length(s.source) FROM moving_sources s, messages m \
             WHERE s.folder_id = ?1 AND s.uid = ?2 AND m.folder_id = ?1 AND m.uid = ?2",
        )?;
        for uid in uids {
            restore.execute(params![folder, uid])?;
        }
        self.forget_moved_sources(folder, uids)
    }

    fn forget_moved_sources(&self, folder: FolderId, uids: &[u64]) -> Result<()> {
        let mut forget = self
            .db
            .prepare_cached("DELETE FROM moving_sources WHERE folder_id = ?1 AND uid = ?2")?;
        for uid in uids {
            forget.execute(params![folder, uid])?;
        }
        Ok(())
    }

    /// Drops what moves left when the app last ended in the middle of one: called once at start
    pub fn clear_moving_sources(&self) -> Result<()> {
        self.db.execute("DELETE FROM moving_sources", [])?;
        Ok(())
    }

    pub(crate) fn text_setting(&self, key: &str) -> Result<Option<String>> {
        self.db
            .query_row("SELECT value FROM settings WHERE key = ?1", [key], |row| row.get(0))
            .optional()
    }

    pub(crate) fn set_text_setting(&self, key: &str, value: &str) -> Result<()> {
        self.db.execute(
            "INSERT INTO settings (key, value) VALUES (?1, ?2) ON CONFLICT (key) DO UPDATE SET value = excluded.value",
            (key, value),
        )?;
        Ok(())
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::{AccountSettings, FolderInfo, MessageInfo};

    /// An account with an Inbox, Junk, an Archive and Drafts: (store, account, [Inbox, Junk, Archive, Drafts])
    fn setup() -> (Store, AccountId, [FolderId; 4]) {
        let store = Store::open_in_memory().unwrap();
        let account = store.add_account(&AccountSettings::example("a@example.com")).unwrap();
        let folder = |path: &str, special: Option<&str>| FolderInfo {
            path: path.into(),
            name: path.into(),
            selectable: true,
            special_use: special.map(Into::into),
            ..Default::default()
        };
        store
            .set_folders(
                account,
                &[
                    folder("INBOX", None),
                    folder("Junk", Some("\\Junk")),
                    folder("Archive", Some("\\Archive")),
                    folder("Drafts", Some("\\Drafts")),
                ],
            )
            .unwrap();
        let id = |path: &str| store.find_folder(account, path).unwrap().unwrap().id;
        let ids = [id("INBOX"), id("Junk"), id("Archive"), id("Drafts")];
        (store, account, ids)
    }

    fn message(uid: u64, arrived: i64, size: u64) -> MessageInfo {
        MessageInfo {
            uid,
            internal_date: Some(arrived),
            size: Some(size),
            ..Default::default()
        }
    }

    #[test]
    fn the_setting_is_recent_mail_and_a_gigabyte_out_of_the_box() {
        let (store, ..) = setup();
        assert_eq!(store.download_ahead().unwrap(), Ahead::Recent);
        assert_eq!(store.download_limit_mb().unwrap(), DEFAULT_LIMIT_MB);
        store.set_download_ahead(Ahead::Never).unwrap();
        store.set_download_limit_mb(250).unwrap();
        assert_eq!(store.download_ahead().unwrap(), Ahead::Never);
        assert_eq!(store.download_limit_mb().unwrap(), 250);
    }

    #[test]
    fn the_inbox_goes_first_newest_first_and_junk_never() {
        let (store, account, [inbox, junk, archive, _]) = setup();
        store.add_messages(junk, &[message(1, 900, 10)]).unwrap();
        store.add_messages(archive, &[message(1, 950, 10)]).unwrap();
        store
            .add_messages(inbox, &[message(1, 100, 10), message(2, 300, 10), message(3, 200, 10)])
            .unwrap();
        let rule = AheadRule::default();
        let (folder, batch) = store.messages_to_download(account, &rule, 1000).unwrap().unwrap();
        assert_eq!(folder, inbox);
        assert_eq!(batch.iter().map(|m| m.1).collect::<Vec<_>>(), [2, 3, 1]);
        // the Inbox done: the Archive, never Junk
        for (id, uid, _) in batch {
            store.set_source(inbox, uid, b"x").unwrap();
            let _ = id;
        }
        let (folder, _) = store.messages_to_download(account, &rule, 1000).unwrap().unwrap();
        assert_eq!(folder, archive);
        store.set_source(archive, 1, b"x").unwrap();
        assert_eq!(store.messages_to_download(account, &rule, 1000).unwrap(), None);
    }

    #[test]
    fn the_rule_and_the_budget_pick_the_batch() {
        let (store, account, [inbox, ..]) = setup();
        store
            .add_messages(
                inbox,
                &[
                    message(1, 100, 300),
                    message(2, 200, 5_000_000),
                    message(3, 300, 300),
                    message(4, 400, 300),
                ],
            )
            .unwrap();
        let rule = AheadRule {
            since: Some(150),
            max_size: Some(RECENT_MAX_SIZE),
            newer_than: None,
        };
        let uids = |budget| {
            let (_, batch) = store.messages_to_download(account, &rule, budget).unwrap().unwrap();
            batch.iter().map(|m| m.1).collect::<Vec<_>>()
        };
        assert_eq!(uids(1000), [4, 3], "too old, too large");
        assert_eq!(uids(400), [4], "the budget");
        assert_eq!(uids(10), [4], "one at least");
        let full = AheadRule {
            newer_than: Some(350),
            ..rule
        };
        let (_, batch) = store.messages_to_download(account, &full, 1000).unwrap().unwrap();
        assert_eq!(batch.iter().map(|m| m.1).collect::<Vec<_>>(), [4]);
        // a message that failed is not tried again
        store.mark_fetch_failed(batch[0].0).unwrap();
        assert_eq!(uids(1000), [3]);
    }

    #[test]
    fn the_neighbors_are_the_messages_above_and_below() {
        let (store, _, [inbox, ..]) = setup();
        store
            .add_messages(
                inbox,
                &[
                    message(1, 100, 10),
                    message(2, 200, 10),
                    message(3, 300, 10),
                    message(4, 400, 10),
                ],
            )
            .unwrap();
        assert_eq!(store.neighbors_to_download(inbox, 2).unwrap(), [(3, 10), (1, 10)]);
        assert_eq!(store.neighbors_to_download(inbox, 4).unwrap(), [(3, 10)]);
        store.set_source(inbox, 1, b"x").unwrap();
        assert_eq!(store.neighbors_to_download(inbox, 2).unwrap(), [(3, 10)]);
    }

    #[test]
    fn a_moved_message_keeps_its_source() {
        let (store, _, [inbox, _, archive, _]) = setup();
        store
            .add_messages(inbox, &[message(1, 100, 10), message(2, 200, 10)])
            .unwrap();
        store.set_source(inbox, 1, b"first").unwrap();
        store.set_source(inbox, 2, b"second").unwrap();
        store.remove_moving_messages(inbox, &[1, 2]).unwrap();
        assert!(store.message(inbox, 1).unwrap().is_none());
        // the server said 1 became 7 in the Archive; 2 found no row there
        store.add_messages(archive, &[message(7, 100, 10)]).unwrap();
        store
            .adopt_moved_sources(inbox, archive, &[1, 2], &[(1, 7), (2, 8)])
            .unwrap();
        assert_eq!(store.source(archive, 7).unwrap().as_deref(), Some(&b"first"[..]));
        assert_eq!(
            store
                .downloaded_size(store.folder(archive).unwrap().account_id)
                .unwrap(),
            5
        );
        // a move that failed: back with its row
        store.add_messages(archive, &[message(9, 300, 10)]).unwrap();
        store.set_source(archive, 9, b"third").unwrap();
        store.remove_moving_messages(archive, &[9]).unwrap();
        store.add_messages(archive, &[message(9, 300, 10)]).unwrap();
        store.restore_moved_sources(archive, &[9]).unwrap();
        assert_eq!(store.source(archive, 9).unwrap().as_deref(), Some(&b"third"[..]));
        let left: i64 = store
            .db
            .query_row("SELECT COUNT(*) FROM moving_sources", [], |row| row.get(0))
            .unwrap();
        assert_eq!(left, 0);
    }

    #[test]
    fn the_oldest_sources_go_past_the_limit() {
        let (store, account, [inbox, _, _, drafts]) = setup();
        store.add_messages(drafts, &[message(1, 1, 100)]).unwrap();
        store.set_source(drafts, 1, &[0; 100]).unwrap();
        for uid in 1..=4 {
            store
                .add_messages(inbox, &[message(uid, uid as i64 * 10, 100)])
                .unwrap();
            store.set_source(inbox, uid, &[0; 100]).unwrap();
        }
        assert_eq!(store.downloaded_size(account).unwrap(), 500);
        assert_eq!(store.oldest_downloaded(account).unwrap(), Some(1));
        // under the limit: nothing goes
        assert_eq!(store.remove_oldest_sources(account, 500, &|_, _| false).unwrap(), 0);
        // the oldest Inbox message was opened: the next one goes in its place; Drafts stay
        let freed = store
            .remove_oldest_sources(account, 300, &|folder, uid| folder == inbox && uid == 1)
            .unwrap();
        assert_eq!(freed, 200);
        assert!(store.has_source(drafts, 1).unwrap());
        assert!(store.has_source(inbox, 1).unwrap());
        assert!(!store.has_source(inbox, 2).unwrap() && !store.has_source(inbox, 3).unwrap());
        assert!(store.has_source(inbox, 4).unwrap());
    }
}
