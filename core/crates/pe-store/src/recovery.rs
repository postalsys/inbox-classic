//! The messages being written, kept as they were last saved until their window closes, so that a crash or a power
//! cut loses nothing: what is left here at the next start is opened again.

use std::path::PathBuf;

use rusqlite::params;

use crate::{AccountId, Result, Store};

/// A message being written, as it was last saved
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct Recovery {
    /// The Message-ID of its draft, which names it
    pub message_id: String,
    pub account_id: AccountId,
    /// The message as its draft is built, without its files
    pub source: Vec<u8>,
    /// The files attached, by their paths
    pub attachments: Vec<PathBuf>,
    /// Seconds since the Unix epoch
    pub saved: i64,
}

impl Store {
    /// Keeps `recovery` in place of the copy kept before under its Message-ID
    pub fn keep_recovery(&self, recovery: &Recovery) -> Result<()> {
        let attachments: Vec<String> = recovery
            .attachments
            .iter()
            .map(|path| path.to_string_lossy().into_owned())
            .collect();
        self.db.execute(
            "INSERT OR REPLACE INTO compose_recovery (message_id, account_id, source, attachments, saved) \
             VALUES (?1, ?2, ?3, ?4, ?5)",
            params![
                recovery.message_id,
                recovery.account_id,
                recovery.source,
                attachments.join("\n"),
                recovery.saved
            ],
        )?;
        Ok(())
    }

    /// The messages kept, oldest first
    pub fn recoveries(&self) -> Result<Vec<Recovery>> {
        let mut statement = self.db.prepare(
            "SELECT message_id, account_id, source, attachments, saved FROM compose_recovery ORDER BY saved, rowid",
        )?;
        let rows = statement.query_map([], |row| {
            let attachments: String = row.get(3)?;
            Ok(Recovery {
                message_id: row.get(0)?,
                account_id: row.get(1)?,
                source: row.get(2)?,
                attachments: attachments
                    .lines()
                    .filter(|l| !l.is_empty())
                    .map(PathBuf::from)
                    .collect(),
                saved: row.get(4)?,
            })
        })?;
        rows.collect::<rusqlite::Result<_>>()
    }

    /// Forgets the message kept under `message_id`: its window closed, or it was sent
    pub fn drop_recovery(&self, message_id: &str) -> Result<()> {
        self.db
            .execute("DELETE FROM compose_recovery WHERE message_id = ?1", [message_id])?;
        Ok(())
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::AccountSettings;

    fn kept(store: &Store, account: AccountId, id: &str, saved: i64) -> Recovery {
        let recovery = Recovery {
            message_id: id.into(),
            account_id: account,
            source: format!("Subject: {id}\r\n\r\nText\r\n").into_bytes(),
            attachments: vec![PathBuf::from("/tmp/a.pdf"), PathBuf::from("/tmp/b c.txt")],
            saved,
        };
        store.keep_recovery(&recovery).unwrap();
        recovery
    }

    #[test]
    fn keeps_replaces_and_drops() {
        let store = Store::open_in_memory().unwrap();
        let account = store.add_account(&AccountSettings::example("a@example.com")).unwrap();
        let first = kept(&store, account, "<1@example.com>", 20);
        let second = kept(&store, account, "<2@example.com>", 10);
        assert_eq!(store.recoveries().unwrap(), [second.clone(), first.clone()]);
        // saved again: the copy is replaced, not added
        let first = kept(&store, account, "<1@example.com>", 30);
        assert_eq!(store.recoveries().unwrap(), [second, first.clone()]);
        store.drop_recovery("<2@example.com>").unwrap();
        assert_eq!(store.recoveries().unwrap(), [first]);
    }

    #[test]
    fn go_with_their_account() {
        let store = Store::open_in_memory().unwrap();
        let account = store.add_account(&AccountSettings::example("a@example.com")).unwrap();
        kept(&store, account, "<1@example.com>", 20);
        store.remove_account(account).unwrap();
        assert!(store.recoveries().unwrap().is_empty());
    }
}
