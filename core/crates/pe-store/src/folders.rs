//! The folders of an account as the server lists them, with where the sync of each one got to

use rusqlite::{OptionalExtension, Row, params};

use crate::{AccountId, Result, Store};

pub type FolderId = i64;

/// A folder as LIST reports it
#[derive(Debug, Clone, PartialEq, Eq, Default)]
pub struct FolderInfo {
    /// The full name on the server, decoded
    pub path: String,
    /// The last part of the path, what the folder tree shows
    pub name: String,
    pub delimiter: Option<String>,
    /// LIST attributes, `\HasChildren`, ...
    pub flags: Vec<String>,
    /// The special-use flag, `\Sent`, `\Trash`, ...
    pub special_use: Option<String>,
    pub subscribed: bool,
    pub selectable: bool,
}

impl FolderInfo {
    /// How deep the folder is in the tree, 0 at the top
    pub fn depth(&self) -> usize {
        match self.delimiter.as_deref() {
            Some(delimiter) if !delimiter.is_empty() => self.path.matches(delimiter).count(),
            _ => 0,
        }
    }
}

/// Where the sync of a folder got to. A different UIDVALIDITY on the server means the cached
/// messages are no longer the server's messages.
#[derive(Debug, Clone, Copy, PartialEq, Eq, Default)]
pub struct SyncState {
    pub uid_validity: Option<u64>,
    pub uid_next: Option<u64>,
    /// For CONDSTORE: flag changes since this are fetched instead of all flags
    pub highest_modseq: Option<u64>,
}

#[derive(Debug, Clone, PartialEq, Eq)]
pub struct Folder {
    pub id: FolderId,
    pub account_id: AccountId,
    pub info: FolderInfo,
    pub state: SyncState,
    /// Cached messages, and those of them not seen
    pub total: u64,
    pub unread: u64,
}

const COLUMNS: &str = "f.id, f.account_id, f.path, f.name, f.delimiter, f.flags, f.special_use, f.subscribed, \
     f.selectable, f.uid_validity, f.uid_next, f.highest_modseq, \
     (SELECT COUNT(*) FROM messages m WHERE m.folder_id = f.id), \
     (SELECT COUNT(*) FROM messages m WHERE m.folder_id = f.id AND m.seen = 0)";

fn from_row(row: &Row) -> rusqlite::Result<Folder> {
    Ok(Folder {
        id: row.get(0)?,
        account_id: row.get(1)?,
        info: FolderInfo {
            path: row.get(2)?,
            name: row.get(3)?,
            delimiter: row.get(4)?,
            flags: crate::messages::split_flags(&row.get::<_, String>(5)?),
            special_use: row.get(6)?,
            subscribed: row.get(7)?,
            selectable: row.get(8)?,
        },
        state: SyncState {
            uid_validity: row.get(9)?,
            uid_next: row.get(10)?,
            highest_modseq: row.get(11)?,
        },
        total: row.get(12)?,
        unread: row.get(13)?,
    })
}

impl Store {
    /// Makes the folders of `account` the ones listed, in that order. Folders that are gone are
    /// removed with their messages; the others keep their messages and sync state. Run it in a
    /// [`Store::transaction`], so the list never shows half done.
    pub fn set_folders(&self, account: AccountId, folders: &[FolderInfo]) -> Result<()> {
        // every folder listed gets its position back, the rest are gone
        self.db
            .execute("UPDATE folders SET position = -1 WHERE account_id = ?1", [account])?;
        let mut upsert = self.db.prepare_cached(
            "INSERT INTO folders (account_id, path, name, delimiter, flags, special_use, subscribed, selectable, position) \
             VALUES (?1, ?2, ?3, ?4, ?5, ?6, ?7, ?8, ?9) \
             ON CONFLICT (account_id, path) DO UPDATE SET name = excluded.name, delimiter = excluded.delimiter, \
             flags = excluded.flags, special_use = excluded.special_use, subscribed = excluded.subscribed, \
             selectable = excluded.selectable, position = excluded.position",
        )?;
        for (position, folder) in folders.iter().enumerate() {
            upsert.execute(params![
                account,
                folder.path,
                folder.name,
                folder.delimiter,
                folder.flags.join(" "),
                folder.special_use,
                folder.subscribed,
                folder.selectable,
                position as i64
            ])?;
        }
        self.db
            .execute("DELETE FROM folders WHERE account_id = ?1 AND position = -1", [account])?;
        Ok(())
    }

    /// The folders of an account in the order they were listed
    pub fn folders(&self, account: AccountId) -> Result<Vec<Folder>> {
        let mut statement = self.db.prepare_cached(&format!(
            "SELECT {COLUMNS} FROM folders f WHERE f.account_id = ?1 ORDER BY f.position"
        ))?;
        statement.query_map([account], from_row)?.collect()
    }

    pub fn folder(&self, id: FolderId) -> Result<Folder> {
        self.db.query_row(
            &format!("SELECT {COLUMNS} FROM folders f WHERE f.id = ?1"),
            [id],
            from_row,
        )
    }

    pub fn find_folder(&self, account: AccountId, path: &str) -> Result<Option<Folder>> {
        self.db
            .query_row(
                &format!("SELECT {COLUMNS} FROM folders f WHERE f.account_id = ?1 AND f.path = ?2"),
                params![account, path],
                from_row,
            )
            .optional()
    }

    pub fn set_sync_state(&self, folder: FolderId, state: &SyncState) -> Result<()> {
        self.db.execute(
            "UPDATE folders SET uid_validity = ?2, uid_next = ?3, highest_modseq = ?4 WHERE id = ?1",
            params![folder, state.uid_validity, state.uid_next, state.highest_modseq],
        )?;
        Ok(())
    }

    /// Forgets the cached messages of a folder, for a new UIDVALIDITY
    pub fn reset_folder(&self, folder: FolderId, uid_validity: Option<u64>) -> Result<()> {
        self.db.execute("DELETE FROM messages WHERE folder_id = ?1", [folder])?;
        self.set_sync_state(
            folder,
            &SyncState {
                uid_validity,
                ..Default::default()
            },
        )
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::AccountSettings;

    fn info(path: &str) -> FolderInfo {
        FolderInfo {
            path: path.into(),
            name: path.rsplit('/').next().unwrap().into(),
            delimiter: Some("/".into()),
            flags: vec!["\\HasNoChildren".into()],
            special_use: (path == "Sent").then(|| "\\Sent".into()),
            subscribed: true,
            selectable: true,
        }
    }

    #[test]
    fn folder_lists_replace_and_keep_state() {
        let store = Store::open_in_memory().unwrap();
        let account = store.add_account(&AccountSettings::example("a@example.com")).unwrap();
        store
            .set_folders(account, &[info("INBOX"), info("Sent"), info("Old")])
            .unwrap();
        let inbox = store.find_folder(account, "INBOX").unwrap().unwrap();
        assert_eq!(inbox.info, info("INBOX"));
        let state = SyncState {
            uid_validity: Some(7),
            uid_next: Some(10),
            highest_modseq: Some(99),
        };
        store.set_sync_state(inbox.id, &state).unwrap();

        store
            .set_folders(account, &[info("Sent"), info("INBOX"), info("Work/Projects")])
            .unwrap();
        let folders = store.folders(account).unwrap();
        let paths: Vec<&str> = folders.iter().map(|f| f.info.path.as_str()).collect();
        assert_eq!(paths, ["Sent", "INBOX", "Work/Projects"]);
        assert_eq!(folders[1].id, inbox.id);
        assert_eq!(folders[1].state, state);
        assert_eq!(folders[0].info.special_use.as_deref(), Some("\\Sent"));
        assert_eq!((folders[1].info.depth(), folders[2].info.depth()), (0, 1));
        assert!(store.find_folder(account, "Old").unwrap().is_none());

        store.reset_folder(inbox.id, Some(8)).unwrap();
        let reset = store.folder(inbox.id).unwrap().state;
        assert_eq!(
            reset,
            SyncState {
                uid_validity: Some(8),
                ..Default::default()
            }
        );
    }

    #[test]
    fn accounts_keep_their_own_folders() {
        let store = Store::open_in_memory().unwrap();
        let a = store.add_account(&AccountSettings::example("a@example.com")).unwrap();
        let b = store.add_account(&AccountSettings::example("b@example.com")).unwrap();
        store.set_folders(a, &[info("INBOX")]).unwrap();
        store.set_folders(b, &[info("INBOX"), info("Sent")]).unwrap();
        store.set_folders(a, &[]).unwrap();
        assert!(store.folders(a).unwrap().is_empty());
        assert_eq!(store.folders(b).unwrap().len(), 2);
        store.remove_account(b).unwrap();
        assert!(store.folders(b).unwrap().is_empty());
    }
}
