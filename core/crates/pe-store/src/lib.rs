//! The local mail store: accounts, folders, the summaries of messages for the message list, and
//! message sources cached for reading offline. SQLite, one file per profile.
//!
//! The store keeps what the server said, already parsed and checked: nothing here reads remote
//! data, so it never needs to be trusted beyond its own consistency. Calls are short and
//! synchronous; the sync runs them between network round trips.
#![forbid(unsafe_code)]

mod accounts;
mod agents;
mod bounces;
mod cards;
mod contacts;
mod download;
mod fold;
mod folders;
mod marks;
mod messages;
mod outbox;
mod pgp;
mod query;
mod recovery;
mod rules;
mod schema;
mod search;
mod selection;
mod senders;
mod sign_in_apps;
pub(crate) mod threads;
mod transfers;
mod trusted;
#[cfg(test)]
mod turkish;

use std::path::Path;

use rusqlite::OptionalExtension;

pub use accounts::{Account, AccountId, AccountSettings, Auth, Security, app_provider};
pub use agents::{AgentHost, AgentHostId, AgentLevels, AgentLogEntry, NewLogEntry};
pub use cards::{Card, CardId, Group, GroupId, Member, MemberRow, display_name};
pub use contacts::Contact;
pub use download::{Ahead, AheadRule, DEFAULT_LIMIT_MB, Downloaded, RECENT_DAYS, RECENT_MAX_SIZE, ToDownload};
pub use folders::{Folder, FolderId, FolderInfo, SyncState};
pub use marks::{Conversation, ThreadMark};
pub use messages::{FLAG_COLOR_BITS, FlagColor, Message, MessageInfo, Sort, SortField};
pub use outbox::Queued;
pub use pgp::{KeyAddress, PgpIdentity, PgpPeer, StoredKey, normal_address};
pub use query::Query;
pub use recovery::Recovery;
pub use rules::{Rule, RuleId};
pub use rusqlite::Error;
pub use search::{IndexText, Scope, Search, Show};
pub use selection::{MessageRef, Picked};
pub use senders::{LOGO_KEPT_MS, LOGO_RETRY_MS, StoredLogo, ToJudge};
pub use sign_in_apps::{SignInApp, SignInAppId, StoredSignInApp};
pub use threads::{MAX_REFERENCES, RowRef, ThreadPlace, parse_references};
pub use transfers::Transfer;
pub use trusted::TrustedSender;

pub type Result<T> = std::result::Result<T, Error>;

pub struct Store {
    db: rusqlite::Connection,
    /// Which store of this process it is, for [`Generation`]
    id: u64,
    /// The rows this connection wrote to its temporary tables (the messages a selection names), which change nothing
    /// a list shows, so [`Generation`] leaves them out
    scratch: std::sync::atomic::AtomicU64,
}

/// What a store holds at one moment, as [`Store::generation`] tells it: equal values of one store mean nothing was
/// written in between, by this connection or another, so what was read then is still so
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub struct Generation {
    store: u64,
    /// SQLite's `data_version`, which changes with every commit of another connection
    data: i64,
    /// The rows this connection inserted, changed or deleted since it opened, those of its temporary tables not counted
    changes: u64,
}

impl Store {
    /// Opens the store at `path`, creating it or bringing its schema up to date
    pub fn open(path: impl AsRef<Path>) -> Result<Store> {
        Self::init(rusqlite::Connection::open(path)?)
    }

    /// A store that lives in memory, for tests
    pub fn open_in_memory() -> Result<Store> {
        Self::init(rusqlite::Connection::open_in_memory()?)
    }

    fn init(db: rusqlite::Connection) -> Result<Store> {
        // WAL lets the UI read the message list while a sync writes
        db.pragma_update(None, "journal_mode", "WAL")?;
        db.pragma_update(None, "foreign_keys", true)?;
        db.pragma_update(None, "synchronous", "NORMAL")?;
        db.busy_timeout(std::time::Duration::from_secs(5))?;
        fold::register(&db)?;
        static OPENED: std::sync::atomic::AtomicU64 = std::sync::atomic::AtomicU64::new(0);
        let id = OPENED.fetch_add(1, std::sync::atomic::Ordering::Relaxed);
        let mut store = Store {
            db,
            id,
            scratch: Default::default(),
        };
        schema::migrate(&mut store.db)?;
        Ok(store)
    }

    /// What the store holds now, as a value that changes with every write to it ([`Generation`])
    pub fn generation(&self) -> Result<Generation> {
        let data = self
            .db
            .prepare_cached("PRAGMA data_version")?
            .query_row([], |row| row.get(0))?;
        Ok(Generation {
            store: self.id,
            data,
            changes: self.db.total_changes() - self.scratch.load(std::sync::atomic::Ordering::Relaxed),
        })
    }

    /// A random ID of this store, made with it: what keeps the passwords of its accounts apart from those of
    /// another store on the same machine
    pub fn profile_id(&self) -> Result<String> {
        self.db
            .query_row("SELECT value FROM settings WHERE key = 'profile'", [], |row| row.get(0))
    }

    /// Messages on a dark background when the window is dark (the Mac and Linux), on until turned off
    pub fn dark_messages(&self) -> Result<bool> {
        self.bool_setting("view.dark_messages", true)
    }

    pub fn set_dark_messages(&self, on: bool) -> Result<()> {
        self.set_bool_setting("view.dark_messages", on)
    }

    /// View > Text Size: the place of the size in use among the sizes offered (pe-core `TEXT_ZOOMS`), None when it
    /// was never chosen
    pub fn text_size(&self) -> Result<Option<usize>> {
        Ok(self
            .text_setting("view.text_size")?
            .and_then(|value| value.parse().ok()))
    }

    pub fn set_text_size(&self, size: usize) -> Result<()> {
        self.set_text_setting("view.text_size", &size.to_string())
    }

    /// The note that an encrypted message's attachment is stored decrypted while it is open was shown
    pub fn decrypted_open_noted(&self) -> Result<bool> {
        self.bool_setting("attachments.decrypted_noted", false)
    }

    pub fn set_decrypted_open_noted(&self) -> Result<()> {
        self.set_bool_setting("attachments.decrypted_noted", true)
    }

    /// A setting that is on or off, `fallback` when it was never set
    pub(crate) fn bool_setting(&self, key: &str, fallback: bool) -> Result<bool> {
        Ok(self.text_setting(key)?.map_or(fallback, |value| value == "1"))
    }

    pub(crate) fn set_bool_setting(&self, key: &str, on: bool) -> Result<()> {
        self.set_text_setting(key, if on { "1" } else { "0" })
    }

    /// A setting of the app as it is kept, None when it was never set
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

    /// Runs `f` in one transaction: a sync step lands as a whole or not at all. Rolled back when
    /// `f` fails or panics, or the commit fails.
    pub fn transaction<T>(&mut self, f: impl FnOnce(&Store) -> Result<T>) -> Result<T> {
        let tx = rusqlite::Transaction::new_unchecked(&self.db, rusqlite::TransactionBehavior::Immediate)?;
        let value = f(self)?;
        tx.commit()?;
        Ok(value)
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn reopens_a_file_store() {
        let dir = std::env::temp_dir().join(format!("pe-store-test-{}", std::process::id()));
        std::fs::create_dir_all(&dir).unwrap();
        let path = dir.join("store.db");
        {
            let store = Store::open(&path).unwrap();
            store.add_account(&AccountSettings::example("a@example.com")).unwrap();
        }
        let store = Store::open(&path).unwrap();
        assert_eq!(store.accounts().unwrap().len(), 1);
        drop(store);
        std::fs::remove_dir_all(&dir).unwrap();
    }

    #[test]
    fn the_generation_changes_with_every_write() {
        let dir = std::env::temp_dir().join(format!("pe-store-generation-{}", std::process::id()));
        std::fs::create_dir_all(&dir).unwrap();
        let path = dir.join("store.db");
        let store = Store::open(&path).unwrap();
        let other = Store::open(&path).unwrap();
        let before = store.generation().unwrap();
        store.accounts().unwrap();
        assert_eq!(store.generation().unwrap(), before, "a read changes nothing");
        assert_ne!(other.generation().unwrap(), before, "another store's is its own");
        let account = store.add_account(&AccountSettings::example("a@example.com")).unwrap();
        let written = store.generation().unwrap();
        assert_ne!(written, before, "its own write");
        // the messages a selection names, in a temporary table of its own
        let picked = [MessageRef { folder: 1, uid: 1 }];
        store.positions(&Search::folder(1), Sort::default(), &picked).unwrap();
        assert_eq!(
            store.generation().unwrap(),
            written,
            "a selection looked for writes nothing"
        );
        other.remove_account(account).unwrap();
        assert_ne!(store.generation().unwrap(), written, "another connection's commit");
        drop((store, other));
        std::fs::remove_dir_all(&dir).unwrap();
    }

    #[test]
    fn profile_ids_stay_and_differ() {
        let a = Store::open_in_memory().unwrap();
        let id = a.profile_id().unwrap();
        assert_eq!(id.len(), 32);
        assert_eq!(a.profile_id().unwrap(), id);
        assert_ne!(Store::open_in_memory().unwrap().profile_id().unwrap(), id);
    }

    #[test]
    fn transactions_roll_back() {
        let mut store = Store::open_in_memory().unwrap();
        let result: Result<()> = store.transaction(|store| {
            store.add_account(&AccountSettings::example("a@example.com"))?;
            Err(Error::QueryReturnedNoRows)
        });
        assert!(result.is_err());
        assert!(store.accounts().unwrap().is_empty());
        store
            .transaction(|store| store.add_account(&AccountSettings::example("b@example.com")))
            .unwrap();
        assert_eq!(store.accounts().unwrap().len(), 1);
    }

    #[test]
    fn a_panic_rolls_back() {
        let mut store = Store::open_in_memory().unwrap();
        let panicked = std::panic::catch_unwind(std::panic::AssertUnwindSafe(|| {
            let _ = store.transaction(|store| -> Result<()> {
                store.add_account(&AccountSettings::example("a@example.com"))?;
                panic!("in the middle");
            });
        }));
        assert!(panicked.is_err());
        assert!(store.accounts().unwrap().is_empty());
        store
            .transaction(|store| store.add_account(&AccountSettings::example("b@example.com")))
            .unwrap();
        assert_eq!(store.accounts().unwrap().len(), 1);
    }
}
