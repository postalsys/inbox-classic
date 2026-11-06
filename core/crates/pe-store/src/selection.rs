//! The messages selected in a list: found by their places in it (the list shows rows by position, so a selection of
//! the windows is ranges of positions), and found again after the list changed (new mail moves the positions).

use std::collections::HashSet;

use rusqlite::params_from_iter;
use rusqlite::types::Value;

use crate::{FolderId, Result, Search, Sort, Store};

/// A message the windows point at: its folder and UID
#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash, PartialOrd, Ord)]
pub struct MessageRef {
    pub folder: FolderId,
    pub uid: u64,
}

/// What an action on picked messages needs of each: where it is, its flags and its Message-ID
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct Picked {
    pub at: MessageRef,
    /// As the store keeps them: sorted, space separated
    pub flags: String,
    pub message_id: Option<String>,
}

impl Picked {
    pub fn has_flag(&self, flag: &str) -> bool {
        self.flags.split(' ').any(|f| f.eq_ignore_ascii_case(flag))
    }
}

/// SQLite's limit on the values of one statement is 32766; picked messages go in by this many at a time
const CHUNK: usize = 400;

impl Store {
    /// The messages at positions `ranges` (start included, end not) of what `search` finds in the order of `sort`, in
    /// that order
    pub fn refs_in_ranges(&self, search: &Search, sort: Sort, ranges: &[(u64, u64)]) -> Result<Vec<MessageRef>> {
        let ranges: Vec<(u64, u64)> = ranges.iter().copied().filter(|(start, end)| start < end).collect();
        if ranges.is_empty() {
            return Ok(Vec::new());
        }
        let (condition, mut values) = search.condition(false);
        let mut wanted = Vec::with_capacity(ranges.len());
        for (start, end) in &ranges {
            values.push(Value::Integer(*start as i64));
            values.push(Value::Integer(*end as i64));
            wanted.push(format!(
                "(position >= ?{} AND position < ?{})",
                values.len() - 1,
                values.len()
            ));
        }
        let mut statement = self.db.prepare(&format!(
            "SELECT folder_id, uid FROM (SELECT folder_id, uid, ROW_NUMBER() OVER (ORDER BY {}) - 1 AS position \
             FROM messages WHERE {condition}) WHERE {} ORDER BY position",
            sort.order_by(),
            wanted.join(" OR ")
        ))?;
        statement
            .query_map(params_from_iter(values), |row| {
                Ok(MessageRef {
                    folder: row.get(0)?,
                    uid: row.get(1)?,
                })
            })?
            .collect()
    }

    /// Where `refs` are now in what `search` finds in the order of `sort`, ascending; those no longer there are left
    /// out. One pass over the list, however many there are.
    pub fn positions(&self, search: &Search, sort: Sort, refs: &[MessageRef]) -> Result<Vec<u64>> {
        if refs.is_empty() {
            return Ok(Vec::new());
        }
        let wanted: HashSet<MessageRef> = refs.iter().copied().collect();
        let folders: HashSet<FolderId> = refs.iter().map(|r| r.folder).collect();
        let (condition, values) = search.condition(false);
        let mut statement = self.db.prepare(&format!(
            "SELECT folder_id, uid, ROW_NUMBER() OVER (ORDER BY {}) - 1 FROM messages WHERE {condition}",
            sort.order_by()
        ))?;
        let mut rows = statement.query(params_from_iter(values))?;
        let mut found = Vec::new();
        while let Some(row) = rows.next()? {
            let at = MessageRef {
                folder: row.get(0)?,
                uid: row.get(1)?,
            };
            if folders.contains(&at.folder) && wanted.contains(&at) {
                found.push(row.get::<_, u64>(2)?);
            }
        }
        found.sort_unstable();
        Ok(found)
    }

    /// The messages of `refs` still in the store, with their flags and Message-IDs, in the order of `refs`
    pub fn picked(&self, refs: &[MessageRef]) -> Result<Vec<Picked>> {
        let mut picked = Vec::with_capacity(refs.len());
        let mut by_folder: Vec<(FolderId, Vec<u64>)> = Vec::new();
        for r in refs {
            match by_folder.iter_mut().find(|(folder, _)| *folder == r.folder) {
                Some((_, uids)) => uids.push(r.uid),
                None => by_folder.push((r.folder, vec![r.uid])),
            }
        }
        let mut found = std::collections::HashMap::new();
        for (folder, uids) in &by_folder {
            for chunk in uids.chunks(CHUNK) {
                let marks = vec!["?"; chunk.len()].join(", ");
                let mut statement = self.db.prepare(&format!(
                    "SELECT uid, flags, message_id FROM messages WHERE folder_id = ? AND uid IN ({marks})"
                ))?;
                let values = std::iter::once(Value::Integer(*folder))
                    .chain(chunk.iter().map(|&uid| Value::Integer(uid as i64)))
                    .collect::<Vec<_>>();
                let mut rows = statement.query(params_from_iter(values))?;
                while let Some(row) = rows.next()? {
                    let at = MessageRef {
                        folder: *folder,
                        uid: row.get(0)?,
                    };
                    found.insert(at, (row.get::<_, String>(1)?, row.get::<_, Option<String>>(2)?));
                }
            }
        }
        for r in refs {
            if let Some((flags, message_id)) = found.remove(r) {
                picked.push(Picked {
                    at: *r,
                    flags,
                    message_id,
                });
            }
        }
        Ok(picked)
    }

    /// The UIDs in `folder` of messages with these Message-IDs, the newest of each
    pub fn uids_of_message_ids(&self, folder: FolderId, message_ids: &[String]) -> Result<Vec<u64>> {
        let mut uids = Vec::new();
        for id in message_ids {
            if let Some(uid) = self.uid_of_message_id(folder, id)? {
                uids.push(uid);
            }
        }
        uids.sort_unstable();
        uids.dedup();
        Ok(uids)
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::{AccountSettings, FolderInfo, MessageInfo, Scope};

    fn setup() -> (Store, FolderId, FolderId) {
        let store = Store::open_in_memory().unwrap();
        let account = store.add_account(&AccountSettings::example("a@example.com")).unwrap();
        let folder = |path: &str| FolderInfo {
            path: path.into(),
            name: path.into(),
            selectable: true,
            ..Default::default()
        };
        store
            .set_folders(account, &[folder("INBOX"), folder("Archive")])
            .unwrap();
        let folders = store.folders(account).unwrap();
        let (inbox, archive) = (folders[0].id, folders[1].id);
        let message = |uid: u64, flags: &[&str]| MessageInfo {
            uid,
            flags: flags.iter().map(|f| f.to_string()).collect(),
            date: Some(uid as i64 * 100),
            message_id: Some(format!("<{uid}@example.com>")),
            ..Default::default()
        };
        store
            .add_messages(
                inbox,
                &[message(1, &[]), message(2, &["\\Seen"]), message(3, &["\\Flagged"])],
            )
            .unwrap();
        store.add_messages(archive, &[message(4, &["\\Seen"])]).unwrap();
        (store, inbox, archive)
    }

    fn at(folder: FolderId, uid: u64) -> MessageRef {
        MessageRef { folder, uid }
    }

    #[test]
    fn finds_rows_by_position_and_positions_by_row() {
        let (store, inbox, archive) = setup();
        let everywhere = Search::default();
        let sort = Sort::default();
        // newest first: 4 (archive), 3, 2, 1
        let refs = store.refs_in_ranges(&everywhere, sort, &[(0, 1), (2, 4)]).unwrap();
        assert_eq!(refs, vec![at(archive, 4), at(inbox, 2), at(inbox, 1)]);
        assert_eq!(store.refs_in_ranges(&everywhere, sort, &[(3, 3)]).unwrap(), vec![]);
        assert_eq!(store.refs_in_ranges(&everywhere, sort, &[(9, 20)]).unwrap(), vec![]);

        // a new message on top moves them down; one taken away is left out
        store
            .add_messages(
                inbox,
                &[MessageInfo {
                    uid: 9,
                    date: Some(10_000),
                    ..Default::default()
                }],
            )
            .unwrap();
        store.remove_messages(inbox, &[2]).unwrap();
        assert_eq!(store.positions(&everywhere, sort, &refs).unwrap(), vec![1, 3]);

        let one_folder = Search {
            scope: Scope::Folder(inbox),
            ..Default::default()
        };
        assert_eq!(store.positions(&one_folder, sort, &refs).unwrap(), vec![2]);
    }

    #[test]
    fn picked_keeps_the_order_and_skips_what_went() {
        let (store, inbox, archive) = setup();
        let picked = store
            .picked(&[at(inbox, 3), at(archive, 4), at(inbox, 7), at(inbox, 1)])
            .unwrap();
        let uids: Vec<u64> = picked.iter().map(|p| p.at.uid).collect();
        assert_eq!(uids, vec![3, 4, 1]);
        assert!(picked[0].has_flag("\\flagged"));
        assert!(!picked[2].has_flag("\\Seen"));
        assert_eq!(picked[1].message_id.as_deref(), Some("<4@example.com>"));

        // more than one statement's worth
        let many: Vec<MessageRef> = (0..1000).map(|uid| at(inbox, uid)).collect();
        assert_eq!(store.picked(&many).unwrap().len(), 3);

        assert_eq!(
            store
                .uids_of_message_ids(inbox, &["<3@example.com>".into(), "<4@example.com>".into()])
                .unwrap(),
            vec![3]
        );
    }
}
