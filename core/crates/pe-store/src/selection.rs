//! The messages selected in a list: found by their places in it (the list shows rows by position, so a selection of
//! the windows is ranges of positions), and found again after the list changed (new mail moves the positions).

use std::collections::{BTreeMap, HashMap};

use rusqlite::params_from_iter;
use rusqlite::types::Value;

use crate::keyset::Order;
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

/// The messages of one folder in a list, in numbers ([`Store::search_summary`])
#[derive(Debug, Clone, Copy, PartialEq, Eq, Default)]
pub struct FolderSummary {
    pub folder: FolderId,
    pub count: u64,
    pub unread: u64,
    pub flagged: u64,
    /// In watched conversations, and in ignored ones
    pub watched: u64,
    pub ignored: u64,
}

/// What an action on picked messages needs of each: where it is, its flags and its Message-ID
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct Picked {
    pub at: MessageRef,
    pub flags: Vec<String>,
    pub message_id: Option<String>,
    /// Its conversation's mark (Watch or Ignore Conversation)
    pub mark: crate::ThreadMark,
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

    /// The colour of its flag, None when it is not flagged
    pub fn flag_color(&self) -> Option<crate::FlagColor> {
        crate::FlagColor::of(&self.flags)
    }
}

/// Up to this many messages or conversations are placed one by one from their sort keys (keyset.rs); more by one
/// ranking of the whole list
pub(crate) const FEW: usize = 8;

/// SQLite's limit on the values of one statement is 32766; picked messages go in by this many at a time
pub(crate) const CHUNK: usize = 400;

/// `?, ?, ?` for `n` values
fn marks(n: usize) -> String {
    vec!["?"; n].join(", ")
}

/// `ids` added to `values`, and their numbered places (`?4, ?5, ?6`) for an `IN (...)`: numbered, so that a statement
/// can name the same list twice, and can come after the values of a search's condition
pub(crate) fn numbered_marks(values: &mut Vec<Value>, ids: &[i64]) -> String {
    let first = values.len() + 1;
    values.extend(ids.iter().map(|&id| Value::Integer(id)));
    (first..first + ids.len())
        .map(|at| format!("?{at}"))
        .collect::<Vec<_>>()
        .join(", ")
}

/// More ranges than this are read as one span and picked out of it ([`Store::refs_in_ranges`])
pub(crate) const FEW_RANGES: usize = 64;

/// `ranges` in order, those that overlap or touch as one
pub(crate) fn merged(mut ranges: Vec<(u64, u64)>) -> Vec<(u64, u64)> {
    ranges.sort_unstable();
    let mut merged: Vec<(u64, u64)> = Vec::with_capacity(ranges.len());
    for (start, end) in ranges {
        match merged.last_mut() {
            Some(previous) if start <= previous.1 => previous.1 = previous.1.max(end),
            _ => merged.push((start, end)),
        }
    }
    merged
}

/// Whether one of `ranges` (merged) holds `position`: only the last one starting at or before it can
pub(crate) fn holds(ranges: &[(u64, u64)], position: u64) -> bool {
    let starts_before = ranges.partition_point(|(start, _)| *start <= position);
    starts_before > 0 && position < ranges[starts_before - 1].1
}

/// More ids than this go into a statement as one value ([`id_list`])
const INLINE_IDS: usize = 500;

/// `ids` for an `IN (...)`, of any number: a few as their numbered places ([`numbered_marks`]), more as one value, a
/// JSON array that `json_each` reads (`SELECT value FROM json_each(?7)`), so that a list of every conversation of a
/// huge folder (Expand All) stays within SQLite's limit of 32766 values a statement
pub(crate) fn id_list(values: &mut Vec<Value>, ids: &[i64]) -> String {
    if ids.len() <= INLINE_IDS {
        return numbered_marks(values, ids);
    }
    let mut json = String::with_capacity(ids.len() * 8 + 2);
    json.push('[');
    for (i, id) in ids.iter().enumerate() {
        if i > 0 {
            json.push(',');
        }
        json.push_str(&id.to_string());
    }
    json.push(']');
    values.push(Value::Text(json));
    format!("SELECT value FROM json_each(?{})", values.len())
}

impl Store {
    /// The messages at positions `ranges` (start included, end not) of what `search` finds in the order of `sort`, in
    /// that order
    pub fn refs_in_ranges(&self, search: &Search, sort: Sort, ranges: &[(u64, u64)]) -> Result<Vec<MessageRef>> {
        let ranges: Vec<(u64, u64)> = ranges.iter().copied().filter(|(start, end)| start < end).collect();
        if ranges.is_empty() {
            return Ok(Vec::new());
        }
        if search.threads.is_some() {
            return self.thread_refs_in_ranges(search, sort, &ranges);
        }
        if search.places_by_key() {
            return self.refs_by_key(search, sort, ranges);
        }
        self.refs_numbered(search, sort, ranges)
    }

    /// [`Store::refs_in_ranges`] of a list one row a message: walked on the order's index ([`Store::rows_at`]), the
    /// end known from the counts the folders keep (a search's would be one more pass over what it finds)
    fn refs_by_key(&self, search: &Search, sort: Sort, ranges: Vec<(u64, u64)>) -> Result<Vec<MessageRef>> {
        let rows = crate::search::message_rows(search, crate::search::walks_index(sort));
        let length = || Ok(self.count_kept(search)?.map(|(count, _)| count));
        self.rows_at(
            &rows,
            &Order::messages(sort),
            &merged(ranges),
            length,
            "folder_id, uid",
            crate::search::message_ref_at,
        )
    }

    /// [`Store::refs_in_ranges`] from every row of the list numbered: for the lists whose places are not counted on
    /// the order's index ([`Search::places_by_key`])
    fn refs_numbered(&self, search: &Search, sort: Sort, ranges: Vec<(u64, u64)>) -> Result<Vec<MessageRef>> {
        let (positioned, mut values) = search.positioned(sort);
        if ranges.len() > FEW_RANGES {
            return self.refs_in_many_ranges(&positioned, values, ranges);
        }
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

    /// [`Store::refs_in_ranges`] for more ranges than one statement's expression may name (SQLite stops at a depth of
    /// 1000, a selection made by clicking every other row has thousands): the rows from the first range's start to the
    /// last one's end, kept when a range holds them
    fn refs_in_many_ranges(
        &self,
        positioned: &str,
        mut values: Vec<Value>,
        ranges: Vec<(u64, u64)>,
    ) -> Result<Vec<MessageRef>> {
        let ranges = merged(ranges);
        let first = ranges[0].0;
        let last = ranges[ranges.len() - 1].1;
        values.push(Value::Integer(first as i64));
        values.push(Value::Integer(last as i64));
        let mut statement = self.db.prepare(&format!(
            "SELECT position, folder_id, uid FROM ({positioned}) WHERE position >= ?{} AND position < ?{} \
             ORDER BY position",
            values.len() - 1,
            values.len()
        ))?;
        let rows = statement.query_map(params_from_iter(values), |row| {
            Ok((
                row.get::<_, i64>(0)? as u64,
                MessageRef {
                    folder: row.get(1)?,
                    uid: row.get(2)?,
                },
            ))
        })?;
        let mut found = Vec::new();
        for row in rows {
            let (position, at) = row?;
            if holds(&ranges, position) {
                found.push(at);
            }
        }
        Ok(found)
    }

    /// Where `refs` are now in what `search` finds in the order of `sort`, ascending; those no longer there are left
    /// out. One pass over the list, which hands back only theirs.
    pub fn positions(&self, search: &Search, sort: Sort, refs: &[MessageRef]) -> Result<Vec<u64>> {
        if refs.is_empty() {
            return Ok(Vec::new());
        }
        if refs.len() <= FEW {
            // each counted on the order's index, never the list ranked
            let mut found = Vec::new();
            for r in refs {
                found.extend(self.search_index(search, sort, r.folder, r.uid)?);
            }
            found.sort_unstable();
            found.dedup();
            return Ok(found);
        }
        self.with_picked_refs(refs, || {
            if let Some(expanded) = &search.threads {
                // each message's row: its conversation's while that is collapsed, so several fall on one
                let mut found = self.thread_positions(search, sort, expanded, &self.picked_threads(search)?)?;
                found.sort_unstable();
                found.dedup();
                return Ok(found);
            }
            let (positioned, values) = search.positioned(sort);
            let mut statement = self.db.prepare(&format!(
                "SELECT l.position FROM ({positioned}) l JOIN temp.picked_refs p \
                 ON p.folder_id = l.folder_id AND p.uid = l.uid ORDER BY l.position"
            ))?;
            statement
                .query_map(params_from_iter(values), |row| row.get(0))?
                .collect()
        })
    }

    /// Those of `refs` that `search` finds, in the order given: a selection made of them holds only messages its list
    /// shows, never one of another folder or one that left it
    pub fn refs_found(&self, search: &Search, refs: &[MessageRef]) -> Result<Vec<MessageRef>> {
        if refs.is_empty() {
            return Ok(Vec::new());
        }
        let found: std::collections::HashSet<MessageRef> = self.with_picked_refs(refs, || {
            let (condition, values) = search.ungrouped().condition(false);
            let mut statement = self.db.prepare(&format!(
                "SELECT folder_id, uid FROM messages WHERE ({condition}) \
                 AND (folder_id, uid) IN (SELECT folder_id, uid FROM temp.picked_refs)"
            ))?;
            statement
                .query_map(params_from_iter(values), |row| {
                    Ok(MessageRef {
                        folder: row.get(0)?,
                        uid: row.get(1)?,
                    })
                })?
                .collect()
        })?;
        Ok(refs.iter().copied().filter(|r| found.contains(r)).collect())
    }

    /// `f` run with `refs` in the table `temp.picked_refs` (folder_id, uid), emptied again after
    fn with_picked_refs<T>(&self, refs: &[MessageRef], f: impl FnOnce() -> Result<T>) -> Result<T> {
        self.scratch(|| {
            self.db.execute_batch(
                "CREATE TEMP TABLE IF NOT EXISTS picked_refs (folder_id INTEGER, uid INTEGER, \
                 PRIMARY KEY (folder_id, uid)) WITHOUT ROWID; DELETE FROM temp.picked_refs;",
            )?;
            let mut insert = self
                .db
                .prepare_cached("INSERT OR IGNORE INTO temp.picked_refs (folder_id, uid) VALUES (?1, ?2)")?;
            for r in refs {
                insert.execute(rusqlite::params![r.folder, r.uid])?;
            }
            Ok(())
        })?;
        let found = f();
        self.scratch(|| self.db.execute("DELETE FROM temp.picked_refs", []))?;
        found
    }

    /// `f`, which writes only to temporary tables: its rows not counted as a change by [`Store::generation`]
    fn scratch<T>(&self, f: impl FnOnce() -> Result<T>) -> Result<T> {
        let before = self.db.total_changes();
        let done = f();
        let written = self.db.total_changes() - before;
        self.scratch.fetch_add(written, std::sync::atomic::Ordering::Relaxed);
        done
    }

    /// The messages of `temp.picked_refs` in the list `search` makes, each with its conversation
    fn picked_threads(&self, search: &Search) -> Result<Vec<(MessageRef, i64)>> {
        let (condition, values) = search.condition(false);
        let mut statement = self.db.prepare(&format!(
            // found by their own rows, not by a pass over the list
            "SELECT folder_id, uid, thread_id FROM messages WHERE id IN (SELECT m.id FROM temp.picked_refs p \
             JOIN messages m ON m.folder_id = p.folder_id AND m.uid = p.uid) AND {condition}"
        ))?;
        statement
            .query_map(params_from_iter(values), |row| {
                Ok((
                    MessageRef {
                        folder: row.get(0)?,
                        uid: row.get(1)?,
                    },
                    row.get(2)?,
                ))
            })?
            .collect()
    }

    /// What the list `search` makes has in each folder, in numbers, with one pass over it (counted where each row
    /// is, never listed): for a selection of the whole list (Select All), whatever its size
    pub fn search_summary(&self, search: &Search) -> Result<Vec<FolderSummary>> {
        // every message of the list, a collapsed conversation's too
        let search = Search {
            threads: None,
            ..search.clone()
        };
        if let Some(summary) = self.summary_kept(&search)? {
            return Ok(summary);
        }
        let (condition, values) = search.condition(false);
        let mut statement = self.db.prepare(&format!(
            "SELECT folder_id, COUNT(*), COALESCE(SUM(NOT seen), 0), \
             COALESCE(SUM(instr(' ' || lower(flags) || ' ', ' \\flagged ') > 0), 0), \
             COALESCE(SUM(mark = {watch}), 0), COALESCE(SUM(mark = {ignore}), 0) FROM \
             (SELECT folder_id, seen, flags, \
              COALESCE((SELECT mark FROM thread_marks t WHERE t.thread_id = messages.thread_id), 0) AS mark \
              FROM messages WHERE {condition}) GROUP BY folder_id ORDER BY folder_id",
            watch = crate::marks::WATCH,
            ignore = crate::marks::IGNORE,
        ))?;
        statement
            .query_map(params_from_iter(values), |row| {
                Ok(FolderSummary {
                    folder: row.get(0)?,
                    count: row.get(1)?,
                    unread: row.get(2)?,
                    flagged: row.get(3)?,
                    watched: row.get(4)?,
                    ignored: row.get(5)?,
                })
            })?
            .collect()
    }

    /// The messages of `refs` still in the store, with their flags and Message-IDs, in the order of `refs`
    pub fn picked(&self, refs: &[MessageRef]) -> Result<Vec<Picked>> {
        let mut found = HashMap::new();
        for (folder, uids) in MessageRef::by_folder(refs) {
            for chunk in uids.chunks(CHUNK) {
                let mut statement = self.db.prepare(&format!(
                    "SELECT uid, flags, message_id, \
                     COALESCE((SELECT mark FROM thread_marks t WHERE t.thread_id = messages.thread_id), 0) \
                     FROM messages WHERE folder_id = ? AND uid IN ({})",
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
                    let mark = crate::ThreadMark::of(row.get(3)?);
                    found.insert(at, (split_flags(&row.get::<_, String>(1)?), row.get(2)?, mark));
                }
            }
        }
        Ok(refs
            .iter()
            .filter_map(|r| {
                found.remove(r).map(|(flags, message_id, mark)| Picked {
                    at: *r,
                    flags,
                    message_id,
                    mark,
                })
            })
            .collect())
    }

    /// The UIDs in `folder` of messages with these Message-IDs: for a Message-ID named `n` times, the newest `n`
    /// messages that have it (two copies of one message moved together are both found again)
    pub fn uids_of_message_ids(&self, folder: FolderId, message_ids: &[String]) -> Result<Vec<u64>> {
        let mut wanted: std::collections::HashMap<&str, usize> = std::collections::HashMap::new();
        for id in message_ids {
            *wanted.entry(id.as_str()).or_default() += 1;
        }
        let distinct: Vec<&str> = wanted.keys().copied().collect();
        let mut uids = Vec::new();
        for chunk in distinct.chunks(CHUNK) {
            let mut statement = self.db.prepare(&format!(
                "SELECT message_id, uid FROM messages WHERE folder_id = ? AND message_id IN ({}) ORDER BY uid DESC",
                marks(chunk.len())
            ))?;
            let values = std::iter::once(Value::Integer(folder))
                .chain(chunk.iter().map(|id| Value::Text(id.to_string())))
                .collect::<Vec<_>>();
            let found: Vec<(String, u64)> = statement
                .query_map(params_from_iter(values), |row| Ok((row.get(0)?, row.get(1)?)))?
                .collect::<Result<_>>()?;
            for (id, uid) in found {
                if let Some(left) = wanted.get_mut(id.as_str())
                    && *left > 0
                {
                    *left -= 1;
                    uids.push(uid);
                }
            }
        }
        uids.sort_unstable();
        Ok(uids)
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::{AccountSettings, FolderInfo, MessageInfo, Scope, SortField};

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
    fn every_other_row_of_a_big_list_is_found() {
        let store = Store::open_in_memory().unwrap();
        let account = store.add_account(&AccountSettings::example("a@example.com")).unwrap();
        store
            .set_folders(
                account,
                &[FolderInfo {
                    path: "INBOX".into(),
                    name: "INBOX".into(),
                    selectable: true,
                    ..Default::default()
                }],
            )
            .unwrap();
        let inbox = store.folders(account).unwrap()[0].id;
        let messages: Vec<MessageInfo> = (1..=6000)
            .map(|uid| MessageInfo {
                uid,
                date: Some(uid as i64 * 100),
                ..Default::default()
            })
            .collect();
        store.add_messages(inbox, &messages).unwrap();
        let folder = Search {
            scope: Scope::Folder(inbox),
            ..Default::default()
        };
        // newest first, so position p is UID 6000 - p; 3000 ranges are more than one expression can hold
        let mut ranges: Vec<(u64, u64)> = (0..3000).map(|i| (i * 2, i * 2 + 1)).collect();
        ranges.push((10, 13)); // overlapping ones count once
        ranges.reverse();
        let refs = store.refs_in_ranges(&folder, Sort::default(), &ranges).unwrap();
        let mut wanted: Vec<MessageRef> = (0..3000).map(|i| at(inbox, 6000 - i * 2)).collect();
        wanted.insert(6, at(inbox, 6000 - 11));
        assert_eq!(refs, wanted);
    }

    /// Rows found by their sort keys from the nearest place known are those the whole list numbered gives: every
    /// order, both ways, with ties in the key and messages without one, at the list's start and end, past it, in the
    /// middle far from both, several ranges and more than one statement would name
    #[test]
    fn rows_found_by_key_are_those_numbered() {
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
        let names = ["anna", "Anna", "bob", "Carla", ""];
        let subjects = ["report", "Re: report", "Plan", "plan", ""];
        let message = |uid: u64| MessageInfo {
            uid,
            // seven messages a date, every fiftieth without one
            date: (!uid.is_multiple_of(50)).then_some((uid / 7) as i64 * 100),
            internal_date: (!uid.is_multiple_of(3)).then_some((uid / 5) as i64 * 100),
            from_name: names[uid as usize % names.len()].into(),
            subject: subjects[uid as usize / 3 % subjects.len()].into(),
            recipients: names[uid as usize / 2 % names.len()].into(),
            size: Some(uid % 13),
            ..Default::default()
        };
        let all: Vec<MessageInfo> = (1..=3000).map(message).collect();
        store.add_messages(inbox, &all).unwrap();
        // the same UIDs in another folder: ties broken by the row
        let other: Vec<MessageInfo> = (1..=500).map(message).collect();
        store.add_messages(archive, &other).unwrap();
        let lists = [
            Search {
                scope: Scope::Folder(inbox),
                ..Default::default()
            },
            Search::default(),
        ];
        let fields = [
            SortField::Date,
            SortField::Received,
            SortField::From,
            SortField::To,
            SortField::Subject,
            SortField::Size,
        ];
        let many: Vec<(u64, u64)> = (0..150).map(|i| (i * 2, i * 2 + 1)).collect();
        let many_to_the_end: Vec<(u64, u64)> = (0..100).map(|i| (3300 + i * 3, 3300 + i * 3 + 2)).collect();
        let wanted: Vec<Vec<(u64, u64)>> = vec![
            vec![(0, 1)],
            vec![(0, 5)],
            vec![(2995, 3000)],
            vec![(2999, 3005)],
            vec![(3495, 3600)],
            vec![(1500, 1503)],
            vec![(2500, 2501)],
            vec![(10, 12), (1200, 1210), (2990, 2995)],
            vec![(1400, 1401), (1402, 1404), (3400, 3401)],
            vec![(9, 5), (5, 9), (7, 12)],
            vec![(4000, 4010)],
            many,
            many_to_the_end,
        ];
        for search in &lists {
            for field in fields {
                for ascending in [true, false] {
                    let sort = Sort { field, ascending };
                    for ranges in &wanted {
                        let ranges: Vec<(u64, u64)> = ranges.iter().copied().filter(|(s, e)| s < e).collect();
                        let numbered = store.refs_numbered(search, sort, ranges.clone()).unwrap();
                        let by_key = store.refs_in_ranges(search, sort, &ranges).unwrap();
                        assert_eq!(by_key, numbered, "{:?} {sort:?} {ranges:?}", search.scope);
                    }
                }
            }
        }
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

    /// Two copies of one message (the same Message-ID) moved together are both found again: Undo brings both back
    #[test]
    fn copies_of_one_message_are_each_found() {
        let (store, inbox, _) = setup();
        let copy = |uid: u64| MessageInfo {
            uid,
            date: Some(uid as i64 * 100),
            message_id: Some("<copy@example.com>".into()),
            ..Default::default()
        };
        store.add_messages(inbox, &[copy(10), copy(11), copy(12)]).unwrap();
        let ids = |n: usize| vec!["<copy@example.com>".to_string(); n];
        // as many as were named, the newest first
        assert_eq!(store.uids_of_message_ids(inbox, &ids(2)).unwrap(), vec![11, 12]);
        assert_eq!(store.uids_of_message_ids(inbox, &ids(1)).unwrap(), vec![12]);
        assert_eq!(store.uids_of_message_ids(inbox, &ids(5)).unwrap(), vec![10, 11, 12]);
        let mut both = ids(2);
        both.push("<1@example.com>".into());
        assert_eq!(store.uids_of_message_ids(inbox, &both).unwrap(), vec![1, 11, 12]);
    }
}
