//! The messages selected in a list: found by their places in it (the list shows rows by position, so a selection of
//! the windows is ranges of positions), and found again after the list changed (new mail moves the positions).

use std::collections::{BTreeMap, HashMap};

use rusqlite::params_from_iter;
use rusqlite::types::Value;

use crate::messages::split_flags;
use crate::{FolderId, Result, Search, Sort, Store};

/// A message the windows point at: its folder and UID
#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash, PartialOrd, Ord)]
pub struct MessageRef {
    pub folder: FolderId,
    pub uid: u64,
}

impl MessageRef {
    /// The UIDs of `refs` by folder, in folder order, each folder's in the order given
    pub fn by_folder(refs: &[MessageRef]) -> BTreeMap<FolderId, Vec<u64>> {
        let mut groups: BTreeMap<FolderId, Vec<u64>> = BTreeMap::new();
        for r in refs {
            groups.entry(r.folder).or_default().push(r.uid);
        }
        groups
    }
}

/// What an action on picked messages needs of each: where it is, its flags and its Message-ID
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct Picked {
    pub at: MessageRef,
    pub flags: Vec<String>,
    pub message_id: Option<String>,
}

impl Picked {
    pub fn has_flag(&self, flag: &str) -> bool {
        self.flags.iter().any(|f| f.eq_ignore_ascii_case(flag))
    }

    pub fn seen(&self) -> bool {
        self.has_flag("\\Seen")
    }

    pub fn flagged(&self) -> bool {
        self.has_flag("\\Flagged")
    }
}

/// SQLite's limit on the values of one statement is 32766; picked messages go in by this many at a time
const CHUNK: usize = 400;

/// `?, ?, ?` for `n` values
fn marks(n: usize) -> String {
    vec!["?"; n].join(", ")
}

impl Store {
    /// The messages at positions `ranges` (start included, end not) of what `search` finds in the order of `sort`, in
    /// that order
    pub fn refs_in_ranges(&self, search: &Search, sort: Sort, ranges: &[(u64, u64)]) -> Result<Vec<MessageRef>> {
        let ranges: Vec<(u64, u64)> = ranges.iter().copied().filter(|(start, end)| start < end).collect();
        if ranges.is_empty() {
            return Ok(Vec::new());
        }
        let (positioned, mut values) = search.positioned(sort);
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
            "SELECT folder_id, uid FROM ({positioned}) WHERE {} ORDER BY position",
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
    /// out. One pass over the list, which hands back only theirs.
    pub fn positions(&self, search: &Search, sort: Sort, refs: &[MessageRef]) -> Result<Vec<u64>> {
        if refs.is_empty() {
            return Ok(Vec::new());
        }
        self.db.execute_batch(
            "CREATE TEMP TABLE IF NOT EXISTS picked_refs (folder_id INTEGER, uid INTEGER, PRIMARY KEY (folder_id, uid)) \
             WITHOUT ROWID; DELETE FROM temp.picked_refs;",
        )?;
        {
            let mut insert = self
                .db
                .prepare_cached("INSERT OR IGNORE INTO temp.picked_refs (folder_id, uid) VALUES (?1, ?2)")?;
            for r in refs {
                insert.execute(rusqlite::params![r.folder, r.uid])?;
            }
        }
        let (positioned, values) = search.positioned(sort);
        let found: Result<Vec<u64>> = {
            let mut statement = self.db.prepare(&format!(
                "SELECT l.position FROM ({positioned}) l JOIN temp.picked_refs p \
                 ON p.folder_id = l.folder_id AND p.uid = l.uid ORDER BY l.position"
            ))?;
            statement
                .query_map(params_from_iter(values), |row| row.get(0))?
                .collect()
        };
        self.db.execute("DELETE FROM temp.picked_refs", [])?;
        found
    }

    /// The messages of `refs` still in the store, with their flags and Message-IDs, in the order of `refs`
    pub fn picked(&self, refs: &[MessageRef]) -> Result<Vec<Picked>> {
        let mut found = HashMap::new();
        for (folder, uids) in MessageRef::by_folder(refs) {
            for chunk in uids.chunks(CHUNK) {
                let mut statement = self.db.prepare(&format!(
                    "SELECT uid, flags, message_id FROM messages WHERE folder_id = ? AND uid IN ({})",
                    marks(chunk.len())
                ))?;
                let values = std::iter::once(Value::Integer(folder))
                    .chain(chunk.iter().map(|&uid| Value::Integer(uid as i64)))
                    .collect::<Vec<_>>();
                let mut rows = statement.query(params_from_iter(values))?;
                while let Some(row) = rows.next()? {
                    let at = MessageRef {
                        folder,
                        uid: row.get(0)?,
                    };
                    found.insert(at, (split_flags(&row.get::<_, String>(1)?), row.get(2)?));
                }
            }
        }
        Ok(refs
            .iter()
            .filter_map(|r| {
                found.remove(r).map(|(flags, message_id)| Picked {
                    at: *r,
                    flags,
                    message_id,
                })
            })
            .collect())
    }

    /// The UIDs in `folder` of messages with these Message-IDs, the newest of each
    pub fn uids_of_message_ids(&self, folder: FolderId, message_ids: &[String]) -> Result<Vec<u64>> {
        let mut uids = Vec::new();
        for chunk in message_ids.chunks(CHUNK) {
            let mut statement = self.db.prepare(&format!(
                "SELECT MAX(uid) FROM messages WHERE folder_id = ? AND message_id IN ({}) GROUP BY message_id",
                marks(chunk.len())
            ))?;
            let values = std::iter::once(Value::Integer(folder))
                .chain(chunk.iter().map(|id| Value::Text(id.clone())))
                .collect::<Vec<_>>();
            let found: Vec<u64> = statement
                .query_map(params_from_iter(values), |row| row.get(0))?
                .collect::<Result<_>>()?;
            uids.extend(found);
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
