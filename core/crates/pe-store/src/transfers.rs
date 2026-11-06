//! Messages on their way to a folder of another account: kept here until the target server took them and the source
//! server let them go, so that moving between accounts survives a crash, a lost connection or a quit in the middle.

use rusqlite::{OptionalExtension, params};

use crate::{AccountId, FolderId, Result, Store};

/// One message to copy or move to a folder of another account
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct Transfer {
    pub id: i64,
    /// The account it comes from
    pub account: AccountId,
    pub from: FolderId,
    pub uid: u64,
    pub to: FolderId,
    /// A copy keeps the original
    pub copy: bool,
    pub message_id: Option<String>,
    /// As the store keeps them: sorted, space separated
    pub flags: String,
    pub internal_date: Option<i64>,
    /// The message, when it was here already; fetched from the server otherwise
    pub source: Option<Vec<u8>>,
    /// An APPEND was tried before: the target may have the copy already
    pub tried: bool,
}

const COLUMNS: &str =
    "id, account_id, from_folder, uid, to_folder, copy, message_id, flags, internal_date, source, tried";

fn from_row(row: &rusqlite::Row) -> rusqlite::Result<Transfer> {
    Ok(Transfer {
        id: row.get(0)?,
        account: row.get(1)?,
        from: row.get(2)?,
        uid: row.get(3)?,
        to: row.get(4)?,
        copy: row.get(5)?,
        message_id: row.get(6)?,
        flags: row.get(7)?,
        internal_date: row.get(8)?,
        source: row.get(9)?,
        tried: row.get(10)?,
    })
}

impl Store {
    /// Adds messages to send on their way; their ids
    pub fn add_transfers(&self, transfers: &[Transfer]) -> Result<Vec<i64>> {
        let mut statement = self.db.prepare_cached(
            "INSERT INTO transfers (account_id, from_folder, uid, to_folder, copy, message_id, flags, internal_date, \
             source) VALUES (?1, ?2, ?3, ?4, ?5, ?6, ?7, ?8, ?9)",
        )?;
        let mut ids = Vec::with_capacity(transfers.len());
        for t in transfers {
            statement.execute(params![
                t.account,
                t.from,
                t.uid,
                t.to,
                t.copy,
                t.message_id,
                t.flags,
                t.internal_date,
                t.source
            ])?;
            ids.push(self.db.last_insert_rowid());
        }
        Ok(ids)
    }

    /// Sends messages `uids` of `from` on their way to `to`, a folder of another account, each with what it takes (its
    /// source when it is here, its flags and date); a move takes them out of `from` here at once. In one transaction.
    pub fn start_transfers(&mut self, from: FolderId, uids: &[u64], to: FolderId, copy: bool) -> Result<AccountId> {
        let account = self.folder(from)?.account_id;
        let mut transfers = Vec::with_capacity(uids.len());
        for &uid in uids {
            let Some(message) = self.message(from, uid)? else {
                continue;
            };
            transfers.push(Transfer {
                id: 0,
                account,
                from,
                uid,
                to,
                copy,
                message_id: message.info.message_id.clone(),
                flags: message.info.flags.join(" "),
                internal_date: message.info.internal_date,
                source: self.source(from, uid)?,
                tried: false,
            });
        }
        self.transaction(|store| {
            store.add_transfers(&transfers)?;
            if !copy {
                store.remove_messages(from, uids)?;
            }
            Ok(())
        })?;
        Ok(account)
    }

    /// The next message on its way from `account`, oldest first
    pub fn next_transfer(&self, account: AccountId) -> Result<Option<Transfer>> {
        self.db
            .query_row(
                &format!("SELECT {COLUMNS} FROM transfers WHERE account_id = ?1 ORDER BY id LIMIT 1"),
                params![account],
                from_row,
            )
            .optional()
    }

    /// The accounts with messages on their way, to start again after a restart
    pub fn transfer_accounts(&self) -> Result<Vec<AccountId>> {
        let mut statement = self
            .db
            .prepare_cached("SELECT DISTINCT account_id FROM transfers ORDER BY account_id")?;
        statement.query_map([], |row| row.get(0))?.collect()
    }

    /// How many messages are on their way from `account`
    pub fn transfers_left(&self, account: AccountId) -> Result<u64> {
        self.db.query_row(
            "SELECT COUNT(*) FROM transfers WHERE account_id = ?1",
            params![account],
            |row| row.get(0),
        )
    }

    /// Keeps the source fetched for a transfer, and that an APPEND of it is being tried
    pub fn set_transfer_source(&self, id: i64, source: &[u8]) -> Result<()> {
        self.db
            .execute("UPDATE transfers SET source = ?2 WHERE id = ?1", params![id, source])?;
        Ok(())
    }

    pub fn set_transfer_tried(&self, id: i64) -> Result<()> {
        self.db
            .execute("UPDATE transfers SET tried = 1 WHERE id = ?1", params![id])?;
        Ok(())
    }

    /// Done with, or given up
    pub fn remove_transfer(&self, id: i64) -> Result<()> {
        self.db.execute("DELETE FROM transfers WHERE id = ?1", params![id])?;
        Ok(())
    }
}

impl Store {
    /// Notes `folder` as the newest place messages were moved or copied to (`used` counts up, so the order holds
    /// however quickly they come)
    pub fn note_target(&self, folder: FolderId) -> Result<()> {
        self.db.execute(
            "INSERT INTO recent_targets (folder_id, used) \
             VALUES (?1, (SELECT COALESCE(MAX(used), 0) + 1 FROM recent_targets)) \
             ON CONFLICT (folder_id) DO UPDATE SET used = excluded.used",
            params![folder],
        )?;
        Ok(())
    }

    /// The `limit` folders messages were moved or copied to last, the newest first
    pub fn recent_targets(&self, limit: u64) -> Result<Vec<FolderId>> {
        let mut statement = self
            .db
            .prepare_cached("SELECT folder_id FROM recent_targets ORDER BY used DESC, folder_id LIMIT ?1")?;
        statement.query_map(params![limit], |row| row.get(0))?.collect()
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::AccountSettings;

    #[test]
    fn keeps_transfers_until_done() {
        let store = Store::open_in_memory().unwrap();
        let a = store.add_account(&AccountSettings::example("a@example.com")).unwrap();
        let b = store.add_account(&AccountSettings::example("b@example.com")).unwrap();
        let transfer = |uid| Transfer {
            id: 0,
            account: a,
            from: 1,
            uid,
            to: 2,
            copy: false,
            message_id: Some(format!("<{uid}@x>")),
            flags: "\\Seen".into(),
            internal_date: Some(5),
            source: None,
            tried: false,
        };
        let ids = store.add_transfers(&[transfer(7), transfer(8)]).unwrap();
        assert_eq!(store.transfer_accounts().unwrap(), vec![a]);
        assert_eq!(store.transfers_left(a).unwrap(), 2);
        assert_eq!(store.transfers_left(b).unwrap(), 0);
        let next = store.next_transfer(a).unwrap().unwrap();
        assert_eq!((next.id, next.uid, next.tried), (ids[0], 7, false));
        store.set_transfer_source(next.id, b"raw").unwrap();
        store.set_transfer_tried(next.id).unwrap();
        let next = store.next_transfer(a).unwrap().unwrap();
        assert_eq!((next.source.as_deref(), next.tried), (Some(&b"raw"[..]), true));
        store.remove_transfer(next.id).unwrap();
        assert_eq!(store.next_transfer(a).unwrap().unwrap().uid, 8);
        // the folders moved to last, newest first; one used again goes on top
        store
            .set_folders(
                b,
                &[
                    crate::FolderInfo {
                        path: "X".into(),
                        name: "X".into(),
                        selectable: true,
                        ..Default::default()
                    },
                    crate::FolderInfo {
                        path: "Y".into(),
                        name: "Y".into(),
                        selectable: true,
                        ..Default::default()
                    },
                ],
            )
            .unwrap();
        let ids: Vec<FolderId> = store.folders(b).unwrap().iter().map(|f| f.id).collect();
        store.note_target(ids[0]).unwrap();
        store.note_target(ids[1]).unwrap();
        assert_eq!(store.recent_targets(5).unwrap(), vec![ids[1], ids[0]]);
        store.note_target(ids[0]).unwrap();
        assert_eq!(store.recent_targets(5).unwrap(), vec![ids[0], ids[1]]);
        assert_eq!(store.recent_targets(1).unwrap(), vec![ids[0]]);
        store.remove_account(b).unwrap();
        assert!(store.recent_targets(5).unwrap().is_empty());

        // an account removed takes its transfers along
        store.remove_account(a).unwrap();
        assert!(store.transfer_accounts().unwrap().is_empty());
    }
}
