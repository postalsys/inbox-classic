//! The flag changes the server still owes (`flags_owed`): the user's change is in `messages` at once and kept here
//! until the server says it made it. A dropped connection or no connection leaves it here, sent again before the
//! next sync of its folder (pe-core's worker), and laid over the flags a sync brings, which would otherwise undo it
//! unseen (a server with CONDSTORE never sends them again). A refusal takes the change back ([`Store::forgive`]).

use rusqlite::params;

use crate::messages::split_flags;
use crate::{FolderId, Result, Store};

/// A flag change of a message the server still owes
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct Owed {
    pub uid: u64,
    pub flag: String,
    /// added, or taken away
    pub on: bool,
}

impl Store {
    /// [`Store::change_flags_many`] as the user asks it: what changed owed to the server until it says it did it
    pub fn change_flags_owed(&self, folder: FolderId, uids: &[u64], add: &[&str], remove: &[&str]) -> Result<Vec<u64>> {
        let tx = rusqlite::Transaction::new_unchecked(&self.db, rusqlite::TransactionBehavior::Immediate)?;
        let changed = self.change_flags_in(folder, uids, add, remove)?;
        self.owe_flags(folder, &changed, add, remove)?;
        tx.commit()?;
        Ok(changed)
    }

    /// [`Store::set_flag_many`] as the user asks it ([`Store::change_flags_owed`])
    pub fn set_flag_many_owed(&self, folder: FolderId, uids: &[u64], flag: &str, on: bool) -> Result<Vec<u64>> {
        if on {
            self.change_flags_owed(folder, uids, &[flag], &[])
        } else {
            self.change_flags_owed(folder, uids, &[], &[flag])
        }
    }

    /// `add` and `remove` of messages of `folder` owed to the server, in the caller's transaction: the newest change
    /// of a flag replaces one owed before
    pub(crate) fn owe_flags(&self, folder: FolderId, uids: &[u64], add: &[&str], remove: &[&str]) -> Result<()> {
        let mut statement = self.db.prepare_cached(
            "INSERT INTO flags_owed (message_id, flag, set_on) \
             SELECT id, ?3, ?4 FROM messages WHERE folder_id = ?1 AND uid = ?2 \
             ON CONFLICT (message_id, flag) DO UPDATE SET set_on = excluded.set_on",
        )?;
        for &uid in uids {
            for (flags, on) in [(add, true), (remove, false)] {
                for flag in flags {
                    statement.execute(params![folder, uid, flag, on])?;
                }
            }
        }
        Ok(())
    }

    /// The flag changes of `folder` the server still owes, by UID
    pub fn owed(&self, folder: FolderId) -> Result<Vec<Owed>> {
        self.db
            .prepare_cached(
                "SELECT m.uid, o.flag, o.set_on FROM flags_owed o JOIN messages m ON m.id = o.message_id \
                 WHERE m.folder_id = ?1 ORDER BY m.uid",
            )?
            .query_map([folder], |row| {
                Ok(Owed {
                    uid: row.get(0)?,
                    flag: row.get(1)?,
                    on: row.get(2)?,
                })
            })?
            .collect()
    }

    /// The server did what was owed: `add` added and `remove` taken away on `uids`. A change of a flag made since
    /// (the other way) is still owed.
    pub fn paid(&self, folder: FolderId, uids: &[u64], add: &[&str], remove: &[&str]) -> Result<()> {
        let mut statement = self.db.prepare_cached(
            "DELETE FROM flags_owed WHERE flag = ?3 AND set_on = ?4 \
             AND message_id = (SELECT id FROM messages WHERE folder_id = ?1 AND uid = ?2)",
        )?;
        for &uid in uids {
            for (flags, on) in [(add, true), (remove, false)] {
                for flag in flags {
                    statement.execute(params![folder, uid, flag, on])?;
                }
            }
        }
        Ok(())
    }

    /// The server refused to change `flags` of `uids`: no longer owed, whichever way (the caller takes the change
    /// back)
    pub fn forgive(&self, folder: FolderId, uids: &[u64], flags: &[&str]) -> Result<()> {
        let mut statement = self.db.prepare_cached(
            "DELETE FROM flags_owed WHERE flag = ?3 \
             AND message_id = (SELECT id FROM messages WHERE folder_id = ?1 AND uid = ?2)",
        )?;
        for &uid in uids {
            for flag in flags {
                statement.execute(params![folder, uid, flag])?;
            }
        }
        Ok(())
    }

    /// The flags of a message as the server reports them, with what the server still owes laid over them: what a
    /// sync writes. False when they were already these.
    pub fn set_server_flags(&self, folder: FolderId, uid: u64, flags: &[String], modseq: Option<u64>) -> Result<bool> {
        let owed: Vec<(String, bool)> = self
            .db
            .prepare_cached(
                "SELECT o.flag, o.set_on FROM flags_owed o JOIN messages m ON m.id = o.message_id \
                 WHERE m.folder_id = ?1 AND m.uid = ?2",
            )?
            .query_map(params![folder, uid], |row| Ok((row.get(0)?, row.get(1)?)))?
            .collect::<Result<_>>()?;
        if owed.is_empty() {
            return self.set_flags(folder, uid, flags, modseq);
        }
        self.set_flags(folder, uid, &laid_over(flags.to_vec(), &owed), modseq)
    }

    /// What the server still owes of `folder` laid over the flags its messages have now (a message the server sent
    /// again with its own)
    pub(crate) fn lay_owed_over(&self, folder: FolderId) -> Result<()> {
        let rows: Vec<(u64, String, String, bool)> = self
            .db
            .prepare_cached(
                "SELECT m.uid, m.flags, o.flag, o.set_on FROM flags_owed o JOIN messages m ON m.id = o.message_id \
                 WHERE m.folder_id = ?1 ORDER BY m.uid",
            )?
            .query_map([folder], |row| Ok((row.get(0)?, row.get(1)?, row.get(2)?, row.get(3)?)))?
            .collect::<Result<_>>()?;
        let mut at = 0;
        while at < rows.len() {
            let uid = rows[at].0;
            let flags = split_flags(&rows[at].1);
            let owed: Vec<(String, bool)> = rows[at..]
                .iter()
                .take_while(|r| r.0 == uid)
                .map(|r| (r.2.clone(), r.3))
                .collect();
            at += owed.len();
            self.set_flags(folder, uid, &laid_over(flags, &owed), None)?;
        }
        Ok(())
    }
}

/// `flags` with each owed flag added or taken away
fn laid_over(mut flags: Vec<String>, owed: &[(String, bool)]) -> Vec<String> {
    for (flag, on) in owed {
        flags.retain(|f| !f.eq_ignore_ascii_case(flag));
        if *on {
            flags.push(flag.clone());
        }
    }
    flags
}

#[cfg(test)]
mod tests {
    use crate::{AccountSettings, FolderInfo, MessageInfo, Store};

    fn inbox() -> (Store, i64) {
        let store = Store::open_in_memory().unwrap();
        let account = store.add_account(&AccountSettings::example("a@example.com")).unwrap();
        let folder = FolderInfo {
            path: "INBOX".into(),
            name: "INBOX".into(),
            selectable: true,
            ..Default::default()
        };
        store.set_folders(account, &[folder]).unwrap();
        let inbox = store.folders(account).unwrap()[0].id;
        let message = |uid| MessageInfo {
            uid,
            ..Default::default()
        };
        store.add_messages(inbox, &[message(1), message(2)]).unwrap();
        (store, inbox)
    }

    fn flags(store: &Store, folder: i64, uid: u64) -> Vec<String> {
        store.message(folder, uid).unwrap().unwrap().info.flags
    }

    #[test]
    fn a_change_is_owed_until_paid_and_survives_the_servers_flags() {
        let (store, inbox) = inbox();
        assert_eq!(
            store.set_flag_many_owed(inbox, &[1, 2], "\\Seen", true).unwrap(),
            vec![1, 2]
        );
        assert_eq!(store.owed(inbox).unwrap().len(), 2);
        // a sync brings the flags the server has, without the change: it stays
        assert!(!store.set_server_flags(inbox, 1, &[], Some(9)).unwrap());
        assert_eq!(flags(&store, inbox, 1), vec!["\\Seen"]);
        // read again whole (a full sync): laid over too
        store
            .add_messages(
                inbox,
                &[MessageInfo {
                    uid: 2,
                    ..Default::default()
                }],
            )
            .unwrap();
        assert_eq!(flags(&store, inbox, 2), vec!["\\Seen"]);
        // the server did it for 1
        store.paid(inbox, &[1], &["\\Seen"], &[]).unwrap();
        assert_eq!(
            store.owed(inbox).unwrap().iter().map(|o| o.uid).collect::<Vec<_>>(),
            vec![2]
        );
        assert!(store.set_server_flags(inbox, 1, &[], None).unwrap());
        assert!(
            flags(&store, inbox, 1).is_empty(),
            "no longer owed: the server's flags are the truth"
        );
    }

    #[test]
    fn the_newest_change_wins_and_a_payment_for_an_older_one_keeps_it() {
        let (store, inbox) = inbox();
        store.set_flag_many_owed(inbox, &[1], "\\Seen", true).unwrap();
        store.set_flag_many_owed(inbox, &[1], "\\Seen", false).unwrap();
        let owed = store.owed(inbox).unwrap();
        assert_eq!(owed.len(), 1);
        assert!(!owed[0].on, "unread now");
        // the server says the first (read) was done: the unread one is still owed
        store.paid(inbox, &[1], &["\\Seen"], &[]).unwrap();
        assert_eq!(store.owed(inbox).unwrap().len(), 1);
    }

    #[test]
    fn a_refusal_forgives_and_a_message_gone_takes_its_debts() {
        let (store, inbox) = inbox();
        store
            .change_flags_owed(inbox, &[1, 2], &["\\Flagged"], &["$NotJunk"])
            .unwrap();
        store.forgive(inbox, &[1], &["\\Flagged", "$NotJunk"]).unwrap();
        assert!(store.owed(inbox).unwrap().iter().all(|o| o.uid == 2));
        store.remove_messages(inbox, &[2]).unwrap();
        assert!(store.owed(inbox).unwrap().is_empty());
    }

    #[test]
    fn mark_all_seen_is_owed() {
        let (store, inbox) = inbox();
        assert_eq!(store.mark_all_seen(inbox).unwrap(), vec![1, 2]);
        assert_eq!(store.owed(inbox).unwrap().len(), 2);
    }
}
