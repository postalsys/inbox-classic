//! The local mail store: accounts, folders, the summaries of messages for the message list, and
//! message sources cached for reading offline. SQLite, one file per profile.
//!
//! The store keeps what the server said, already parsed and checked: nothing here reads remote
//! data, so it never needs to be trusted beyond its own consistency. Calls are short and
//! synchronous; the sync runs them between network round trips.
#![forbid(unsafe_code)]

mod accounts;
mod folders;
mod messages;
mod outbox;
mod query;
mod schema;
mod search;
mod sign_in_apps;

use std::path::Path;

pub use accounts::{Account, AccountId, AccountSettings, Auth, Security, app_provider};
pub use folders::{Folder, FolderId, FolderInfo, SyncState};
pub use messages::{Message, MessageInfo, Sort, SortField};
pub use outbox::Queued;
pub use query::Query;
pub use rusqlite::Error;
pub use search::{IndexText, Search, Show};
pub use sign_in_apps::{SignInApp, SignInAppId, StoredSignInApp};

pub type Result<T> = std::result::Result<T, Error>;

pub struct Store {
    db: rusqlite::Connection,
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
        let mut store = Store { db };
        schema::migrate(&mut store.db)?;
        Ok(store)
    }

    /// A random ID of this store, made with it: what keeps the passwords of its accounts apart from those of
    /// another store on the same machine
    pub fn profile_id(&self) -> Result<String> {
        self.db
            .query_row("SELECT value FROM settings WHERE key = 'profile'", [], |row| row.get(0))
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
