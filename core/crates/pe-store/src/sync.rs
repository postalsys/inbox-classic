//! What settings sync keeps in the store (pe-core `sync`): the id each synced item has on every computer, the stamp
//! and a hash of each of its fields as this computer last synced them (a field whose hash changed since was changed
//! here), how far this computer has read each other computer's changes, and the edits a later one won over, kept so
//! they can be restored.
//!
//! Items are named by a kind (`account`, `card`, `rule`, ...) and their local key as text: a row id for most, the
//! natural key where there is one (a key's fingerprint, a setting's name). A field named [`DELETED`] marks an item
//! removed, with the stamp of its removal.

use rusqlite::{OptionalExtension, params};

use crate::{Result, Store};

/// The field that marks an item removed (its hash is empty)
pub const DELETED: &str = "_deleted";

/// A field as this computer last synced it
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct SyncedField {
    pub kind: String,
    pub id: String,
    pub field: String,
    /// When it was changed, a hybrid logical clock stamp (pe-core sync `Stamp`), as text that sorts in time order
    pub stamp: String,
    /// A hash of its value then, to tell a change made here since
    pub hash: String,
}

/// An edit that lost to a later one on another computer, kept for Restore
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct LostEdit {
    pub id: i64,
    /// When it was put aside, seconds since the Unix epoch
    pub at: i64,
    pub kind: String,
    pub item: String,
    pub field: String,
    /// Its value, as the sync record carries it (JSON)
    pub value: String,
    /// What the item is called, for the list ("Work", "Ann Lee")
    pub label: String,
    /// The computer whose edit was replaced (by this one's, made at the same time)
    pub source: String,
}

/// The edits kept for Restore
const LOST_KEPT: i64 = 200;

fn lost_edit(row: &rusqlite::Row) -> rusqlite::Result<LostEdit> {
    Ok(LostEdit {
        id: row.get(0)?,
        at: row.get(1)?,
        kind: row.get(2)?,
        item: row.get(3)?,
        field: row.get(4)?,
        value: row.get(5)?,
        label: row.get(6)?,
        source: row.get(7)?,
    })
}

impl Store {
    /// The sync id of the item `local` of `kind`, None while it has none
    pub fn sync_id(&self, kind: &str, local: &str) -> Result<Option<String>> {
        self.db
            .prepare_cached("SELECT id FROM sync_ids WHERE kind = ?1 AND local = ?2")?
            .query_row(params![kind, local], |row| row.get(0))
            .optional()
    }

    /// The local key of the item with the sync id `id`, None for one not here
    pub fn sync_local(&self, kind: &str, id: &str) -> Result<Option<String>> {
        self.db
            .prepare_cached("SELECT local FROM sync_ids WHERE kind = ?1 AND id = ?2")?
            .query_row(params![kind, id], |row| row.get(0))
            .optional()
    }

    /// Every item of `kind` with a sync id: (local key, sync id)
    pub fn sync_ids(&self, kind: &str) -> Result<Vec<(String, String)>> {
        self.db
            .prepare_cached("SELECT local, id FROM sync_ids WHERE kind = ?1 ORDER BY local")?
            .query_map(params![kind], |row| Ok((row.get(0)?, row.get(1)?)))?
            .collect()
    }

    /// The item `local` of `kind` is the one `id` names on every computer (a local key taken by another id lets it go)
    pub fn set_sync_id(&self, kind: &str, local: &str, id: &str) -> Result<()> {
        self.db.execute(
            "DELETE FROM sync_ids WHERE kind = ?1 AND (local = ?2 OR id = ?3)",
            params![kind, local, id],
        )?;
        self.db.execute(
            "INSERT INTO sync_ids (kind, local, id) VALUES (?1, ?2, ?3)",
            params![kind, local, id],
        )?;
        Ok(())
    }

    /// The item `local` of `kind` is gone here: its id no longer names a local item
    pub fn forget_sync_local(&self, kind: &str, local: &str) -> Result<()> {
        self.db.execute(
            "DELETE FROM sync_ids WHERE kind = ?1 AND local = ?2",
            params![kind, local],
        )?;
        Ok(())
    }

    /// Every field this computer has synced
    pub fn synced_fields(&self) -> Result<Vec<SyncedField>> {
        self.db
            .prepare_cached("SELECT kind, id, field, stamp, hash FROM sync_fields ORDER BY kind, id, field")?
            .query_map([], |row| {
                Ok(SyncedField {
                    kind: row.get(0)?,
                    id: row.get(1)?,
                    field: row.get(2)?,
                    stamp: row.get(3)?,
                    hash: row.get(4)?,
                })
            })?
            .collect()
    }

    /// A field as synced now: its stamp and its value's hash
    pub fn set_synced_field(&self, kind: &str, id: &str, field: &str, stamp: &str, hash: &str) -> Result<()> {
        self.db.execute(
            "INSERT INTO sync_fields (kind, id, field, stamp, hash) VALUES (?1, ?2, ?3, ?4, ?5) \
             ON CONFLICT (kind, id, field) DO UPDATE SET stamp = excluded.stamp, hash = excluded.hash",
            params![kind, id, field, stamp, hash],
        )?;
        Ok(())
    }

    /// Fields as synced at once, in one transaction: (kind, id, field, stamp, hash)
    pub fn set_synced_fields(&mut self, fields: &[(&str, &str, &str, &str, &str)]) -> Result<()> {
        self.transaction(|store| {
            for (kind, id, field, stamp, hash) in fields {
                store.set_synced_field(kind, id, field, stamp, hash)?;
            }
            Ok(())
        })
    }

    /// The highest change number applied from the computer `device`, 0 for none yet
    pub fn sync_device_seq(&self, device: &str) -> Result<u64> {
        Ok(self
            .db
            .prepare_cached("SELECT seq FROM sync_devices WHERE device = ?1")?
            .query_row(params![device], |row| row.get::<_, i64>(0))
            .optional()?
            .unwrap_or(0) as u64)
    }

    /// The changes of `device` applied up to `seq`
    pub fn set_sync_device_seq(&self, device: &str, seq: u64) -> Result<()> {
        self.db.execute(
            "INSERT INTO sync_devices (device, seq) VALUES (?1, ?2) \
             ON CONFLICT (device) DO UPDATE SET seq = MAX(seq, excluded.seq)",
            params![device, seq as i64],
        )?;
        Ok(())
    }

    /// The changes of `device` to be read again from the start
    pub fn reset_sync_device_seq(&self, device: &str) -> Result<()> {
        self.db
            .execute("DELETE FROM sync_devices WHERE device = ?1", params![device])?;
        Ok(())
    }

    /// Every computer read from, with how far: (device, seq)
    pub fn sync_devices(&self) -> Result<Vec<(String, u64)>> {
        self.db
            .prepare_cached("SELECT device, seq FROM sync_devices ORDER BY device")?
            .query_map([], |row| Ok((row.get(0)?, row.get::<_, i64>(1)? as u64)))?
            .collect()
    }

    /// How sync is set up here (pe-core sync `Setup`, JSON), None while it is off
    pub fn sync_setup(&self) -> Result<Option<String>> {
        self.text_setting("sync.setup")
    }

    pub fn set_sync_setup(&self, setup: Option<&str>) -> Result<()> {
        match setup {
            Some(setup) => self.set_text_setting("sync.setup", setup),
            None => {
                self.db.execute("DELETE FROM settings WHERE key = 'sync.setup'", [])?;
                Ok(())
            }
        }
    }

    /// Sync turned off on this computer: what it kept of the vault forgotten (the items stay as they are)
    pub fn forget_sync(&self) -> Result<()> {
        self.db.execute_batch(
            "DELETE FROM sync_ids; DELETE FROM sync_fields; DELETE FROM sync_devices; DELETE FROM sync_lost;",
        )?;
        Ok(())
    }

    /// An edit put aside for a later one, kept for Restore (the oldest go past [`LOST_KEPT`])
    pub fn keep_lost_edit(&self, edit: &LostEdit) -> Result<()> {
        self.db.execute(
            "INSERT INTO sync_lost (at, kind, item, field, value, label, source) \
             VALUES (?1, ?2, ?3, ?4, ?5, ?6, ?7)",
            params![
                edit.at,
                edit.kind,
                edit.item,
                edit.field,
                edit.value,
                edit.label,
                edit.source
            ],
        )?;
        self.db.execute(
            "DELETE FROM sync_lost WHERE id NOT IN (SELECT id FROM sync_lost ORDER BY id DESC LIMIT ?1)",
            params![LOST_KEPT],
        )?;
        Ok(())
    }

    /// The edits put aside, newest first
    pub fn lost_edits(&self) -> Result<Vec<LostEdit>> {
        self.db
            .prepare_cached("SELECT id, at, kind, item, field, value, label, source FROM sync_lost ORDER BY id DESC")?
            .query_map([], lost_edit)?
            .collect()
    }

    /// An edit taken out of the history (restored, or let go)
    pub fn take_lost_edit(&self, id: i64) -> Result<Option<LostEdit>> {
        self.db
            .prepare_cached(
                "DELETE FROM sync_lost WHERE id = ?1 RETURNING id, at, kind, item, field, value, label, source",
            )?
            .query_row(params![id], lost_edit)
            .optional()
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn ids_fields_devices_and_lost_edits() {
        let store = Store::open_in_memory().unwrap();
        // an item's id both ways; a local key given another id lets the old one go
        store.set_sync_id("card", "7", "c-1").unwrap();
        assert_eq!(store.sync_id("card", "7").unwrap().as_deref(), Some("c-1"));
        assert_eq!(store.sync_local("card", "c-1").unwrap().as_deref(), Some("7"));
        store.set_sync_id("card", "7", "c-2").unwrap();
        assert_eq!(store.sync_local("card", "c-1").unwrap(), None);
        assert_eq!(store.sync_ids("card").unwrap(), [("7".to_string(), "c-2".to_string())]);
        store.forget_sync_local("card", "7").unwrap();
        assert!(store.sync_ids("card").unwrap().is_empty());
        // a field's stamp and hash, replaced by the next
        store.set_synced_field("card", "c-2", "name", "a", "h1").unwrap();
        store.set_synced_field("card", "c-2", "name", "b", "h2").unwrap();
        assert_eq!(store.synced_fields().unwrap()[0].stamp, "b");
        assert_eq!(store.synced_fields().unwrap().len(), 1);
        // how far each computer was read, never back
        store.set_sync_device_seq("pc", 5).unwrap();
        store.set_sync_device_seq("pc", 3).unwrap();
        assert_eq!(store.sync_device_seq("pc").unwrap(), 5);
        assert_eq!(store.sync_device_seq("mac").unwrap(), 0);
        // an edit put aside, listed, and taken back
        let edit = LostEdit {
            id: 0,
            at: 100,
            kind: "account".into(),
            item: "a-1".into(),
            field: "signature".into(),
            value: "\"Regards\"".into(),
            label: "Work".into(),
            source: "MacBook".into(),
        };
        store.keep_lost_edit(&edit).unwrap();
        let kept = store.lost_edits().unwrap();
        assert_eq!((kept.len(), kept[0].label.as_str()), (1, "Work"));
        assert_eq!(store.take_lost_edit(kept[0].id).unwrap().unwrap().value, "\"Regards\"");
        assert!(store.lost_edits().unwrap().is_empty());
        store.forget_sync().unwrap();
        assert!(store.synced_fields().unwrap().is_empty() && store.sync_devices().unwrap().is_empty());
    }
}
