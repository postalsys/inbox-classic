//! Conversations: the messages of an account that answer each other, found by the Message-IDs they name (their own,
//! In-Reply-To and References, as JWZ threading has it, without guessing from subjects) and, on Gmail, by Gmail's own
//! conversation id. Each account keeps a map from those ids to a conversation id (`thread_ids`); a message that names
//! ids of two conversations joins them into one.

use std::collections::{HashMap, HashSet};

use rusqlite::types::Value;
use rusqlite::{OptionalExtension, params, params_from_iter};

use crate::messages::{COLUMNS, from_row};
use crate::selection::numbered_marks;
use crate::{AccountId, FolderId, Message, MessageInfo, MessageRef, Result, Search, Sort, SortField, Store};

/// At most this many References a message brings: the last ones, nearest to it (a long thread's header lists every
/// message before it, and a hostile one any number of ids)
pub const MAX_REFERENCES: usize = 50;

/// The longest Message-ID kept: longer ones are not real ids
const MAX_ID: usize = 998;

/// The Message-IDs of a References (or In-Reply-To) header, `<...>` each, in order, without the brackets' spaces, the
/// last [`MAX_REFERENCES`] of them
pub fn parse_references(header: &str) -> Vec<String> {
    let mut ids = Vec::new();
    let mut rest = header;
    while let Some(start) = rest.find('<') {
        let Some(end) = rest[start..].find('>') else {
            break;
        };
        let id: String = rest[start..start + end + 1]
            .chars()
            .filter(|c| !c.is_whitespace())
            .collect();
        if id.len() > 2 && id.len() <= MAX_ID {
            ids.push(id);
        }
        rest = &rest[start + end + 1..];
    }
    let skip = ids.len().saturating_sub(MAX_REFERENCES);
    ids.split_off(skip)
}

/// The References as the store keeps them, ids separated by spaces (an id has none)
pub(crate) fn split_references(stored: &str) -> Vec<String> {
    stored
        .split(' ')
        .filter(|id| !id.is_empty())
        .map(str::to_string)
        .collect()
}

/// The keys a message joins its conversation by: its own Message-ID, the ids it answers, and Gmail's conversation id
pub(crate) fn thread_keys(message: &MessageInfo) -> Vec<String> {
    keys_of(
        message.message_id.as_deref(),
        message.in_reply_to.as_deref(),
        &message.references,
        message.gmail_thread,
    )
}

/// [`thread_keys`] from the ids themselves
fn keys_of(
    message_id: Option<&str>,
    in_reply_to: Option<&str>,
    references: &[String],
    gmail: Option<u64>,
) -> Vec<String> {
    let mut keys: Vec<String> = Vec::new();
    let mut add = |id: &str| {
        let id = id.trim();
        if id.len() > 2 && id.len() <= MAX_ID && !keys.iter().any(|k| k == id) {
            keys.push(id.to_string());
        }
    };
    if let Some(id) = message_id {
        add(id);
    }
    for id in references {
        add(id);
    }
    if let Some(parent) = in_reply_to {
        for id in parse_references(parent) {
            add(&id);
        }
    }
    if let Some(gmail) = gmail {
        add(&format!("gm:{gmail}"));
    }
    keys
}

impl Store {
    /// The conversation of a message of `account` with these keys ([`thread_keys`]): the one they name, a new one when
    /// they name none, or, when they name several, those joined into the oldest
    pub(crate) fn thread_of(&self, account: AccountId, keys: &[String]) -> Result<i64> {
        let mut known = self
            .db
            .prepare_cached("SELECT thread_id FROM thread_ids WHERE account_id = ?1 AND key = ?2")?;
        let mut found: Vec<i64> = Vec::new();
        for key in keys {
            if let Some(thread) = known
                .query_row(params![account, key], |row| row.get::<_, i64>(0))
                .ok()
                .filter(|t| !found.contains(t))
            {
                found.push(thread);
            }
        }
        found.sort_unstable();
        let thread = match found.first() {
            Some(&oldest) => oldest,
            None => self.new_thread()?,
        };
        // the others become this one: their keys and their messages
        for &other in found.iter().skip(1) {
            self.db.execute(
                "UPDATE thread_ids SET thread_id = ?3 WHERE account_id = ?1 AND thread_id = ?2",
                params![account, other, thread],
            )?;
            self.db.execute(
                "UPDATE messages SET thread_id = ?3 WHERE thread_id = ?2 \
                 AND folder_id IN (SELECT id FROM folders WHERE account_id = ?1)",
                params![account, other, thread],
            )?;
        }
        let mut add = self.db.prepare_cached(
            "INSERT INTO thread_ids (account_id, key, thread_id) VALUES (?1, ?2, ?3) \
             ON CONFLICT (account_id, key) DO NOTHING",
        )?;
        for key in keys {
            add.execute(params![account, key, thread])?;
        }
        Ok(thread)
    }

    /// A conversation id no message has, from the sequence of handed out ones (never reused: a joined one is left)
    fn new_thread(&self) -> Result<i64> {
        self.db.execute("INSERT INTO threads DEFAULT VALUES", [])?;
        Ok(self.db.last_insert_rowid())
    }

    /// Puts up to `limit` messages that are in no conversation yet (stored before conversations were kept) into
    /// theirs, the oldest first so a conversation starts with its first message. Returns how many; 0 when all are.
    pub fn thread_unthreaded(&self, account: AccountId, limit: usize) -> Result<usize> {
        let tx = rusqlite::Transaction::new_unchecked(&self.db, rusqlite::TransactionBehavior::Immediate)?;
        let mut statement = self.db.prepare_cached(
            "SELECT m.id, m.message_id, m.in_reply_to, COALESCE(m.refs, '') FROM messages m \
             JOIN folders f ON f.id = m.folder_id WHERE m.thread_id < 0 AND f.account_id = ?2 \
             ORDER BY COALESCE(m.date, m.internal_date) LIMIT ?1",
        )?;
        let rows: Vec<Unthreaded> = statement
            .query_map(params![limit as i64, account], |row| {
                Ok((row.get(0)?, row.get(1)?, row.get(2)?, row.get(3)?))
            })?
            .collect::<rusqlite::Result<_>>()?;
        let mut set = self
            .db
            .prepare_cached("UPDATE messages SET thread_id = ?2 WHERE id = ?1")?;
        for (id, message_id, in_reply_to, refs) in &rows {
            let keys = keys_of(
                message_id.as_deref(),
                in_reply_to.as_deref(),
                &split_references(refs),
                None,
            );
            let thread = self.thread_of(account, &keys)?;
            set.execute(params![id, thread])?;
        }
        tx.commit()?;
        Ok(rows.len())
    }

    /// Messages of `account` stored before their References were kept, the newest first, all of one folder (the
    /// newest one's), at most `limit`: (message id, folder, uid)
    pub fn messages_without_references(&self, account: AccountId, limit: usize) -> Result<Vec<(i64, FolderId, u64)>> {
        let mut statement = self.db.prepare_cached(
            "SELECT m.id, m.folder_id, m.uid FROM messages m INDEXED BY messages_unreferenced \
             JOIN folders f ON f.id = m.folder_id WHERE m.refs IS NULL AND f.account_id = ?1 \
             ORDER BY COALESCE(m.date, m.internal_date) DESC LIMIT ?2",
        )?;
        let found: Vec<(i64, FolderId, u64)> = statement
            .query_map(params![account, limit as i64], |row| {
                Ok((row.get(0)?, row.get(1)?, row.get(2)?))
            })?
            .collect::<rusqlite::Result<_>>()?;
        let folder = found.first().map(|(_, f, _)| *f);
        Ok(found.into_iter().filter(|(_, f, _)| Some(*f) == folder).collect())
    }

    /// The References of a message stored before they were kept (`None`: the server did not give them, kept as none),
    /// and its conversation again with them, joining others it names. Returns whether its conversation changed.
    pub fn set_references(&self, message: i64, references: &[String]) -> Result<bool> {
        let (account, message_id, in_reply_to, thread): (AccountId, Option<String>, Option<String>, i64) =
            self.db.query_row(
                "SELECT f.account_id, m.message_id, m.in_reply_to, m.thread_id FROM messages m \
                 JOIN folders f ON f.id = m.folder_id WHERE m.id = ?1",
                [message],
                |row| Ok((row.get(0)?, row.get(1)?, row.get(2)?, row.get(3)?)),
            )?;
        self.db.execute(
            "UPDATE messages SET refs = ?2 WHERE id = ?1",
            params![message, references.join(" ")],
        )?;
        if references.is_empty() || thread < 0 {
            // nothing new to join by, or not threaded yet (thread_unthreaded reads the References now kept)
            return Ok(false);
        }
        let keys = keys_of(message_id.as_deref(), in_reply_to.as_deref(), references, None);
        let joined = self.thread_of(account, &keys)?;
        if joined != thread {
            self.db.execute(
                "UPDATE messages SET thread_id = ?2 WHERE id = ?1",
                params![message, joined],
            )?;
        }
        Ok(joined != thread)
    }
}

/// A row's place in a list grouped by conversation ([`Search::threads`]). The apps read [`ThreadPlace::opens`],
/// [`ThreadPlace::collapsed`] and [`Message::bold`] rather than decide from these numbers.
#[derive(Debug, Clone, Copy, PartialEq, Eq, Default)]
pub struct ThreadPlace {
    pub thread: i64,
    /// 0 for a conversation's first message, 1 for the others under it when it is expanded
    pub depth: u32,
    /// The messages of the conversation in the list, and how many of them are unread
    pub count: u32,
    pub unread: u32,
    /// The conversation is expanded (its other messages under this row)
    pub expanded: bool,
}

impl ThreadPlace {
    /// The row is the first of a conversation of several messages: it opens and closes (a + or a -)
    pub fn opens(&self) -> bool {
        self.depth == 0 && self.count > 1
    }

    /// The row stands for all of its conversation's messages, as they are not shown under it
    pub fn collapsed(&self) -> bool {
        self.opens() && !self.expanded
    }
}

/// A message to thread: its row id, its Message-ID, In-Reply-To and References as stored
type Unthreaded = (i64, Option<String>, Option<String>, String);

/// A conversation of the grouped list: its id, how many messages it has in the list and how many of them are unread
type Group = (i64, u32, u32);

/// A row of the grouped list as an action on it sees it
enum RowRefs {
    /// A message of its own
    Message(MessageRef),
    /// A collapsed conversation: all of its messages in the list
    Conversation(i64),
}

const WHEN: &str = "COALESCE(date, internal_date)";

/// The conversations of the messages `condition` finds, as a `WITH g` of their id (`t`), their numbers (`n`, `u`), and
/// what they are ordered by: their newest date, or for another column their first message's value of it (`k`)
fn groups(condition: &str, sort: Sort) -> String {
    let ordered = match sort.field {
        SortField::Date => format!("MAX({WHEN}) AS newest"),
        SortField::Received => "MAX(internal_date) AS newest_received".to_string(),
        // the first message's: with one MIN and no other MIN or MAX, SQLite takes a bare column from that row
        field => format!(
            "MIN({WHEN} * 1000000000000 + uid) AS first_at, {} AS k",
            key_column(field)
        ),
    };
    format!(
        "WITH g AS (SELECT thread_id AS t, COUNT(*) AS n, SUM(1 - seen) AS u, {ordered} \
         FROM messages WHERE {condition} GROUP BY thread_id)"
    )
}

/// The column of an order other than by date, as [`Sort::order_by`] has it, without its collation
fn key_column(field: SortField) -> &'static str {
    match field {
        SortField::From => "(CASE from_name WHEN '' THEN from_address ELSE from_name END)",
        SortField::To => "recipients",
        SortField::Subject => "subject",
        SortField::Size => "size",
        SortField::Date | SortField::Received => "date",
    }
}

/// The order of the conversations of [`groups`]: by Date or Received, by their newest message, as mail that came last
/// is on top; by another column, by their first message's
fn group_order(sort: Sort) -> String {
    let direction = if sort.ascending { "ASC" } else { "DESC" };
    let first = match sort.field {
        SortField::Date => "newest".to_string(),
        SortField::Received => "newest_received".to_string(),
        SortField::Size => "k".to_string(),
        _ => "k COLLATE NOCASE".to_string(),
    };
    format!("{first} {direction}, t {direction}")
}

impl Store {
    /// The conversations in what `search` finds, in the order of `sort` ([`group_order`]): `limit` of them from
    /// `offset` on, with how many messages each has there and how many of those are unread. One pass over the
    /// list's messages, grouped by conversation on its index.
    fn thread_page(&self, search: &Search, sort: Sort, offset: u64, limit: u64) -> Result<Vec<Group>> {
        let (condition, mut values) = search.condition(false);
        let at = values.len();
        values.push(Value::Integer(limit as i64));
        values.push(Value::Integer(offset as i64));
        let mut statement = self.db.prepare_cached(&format!(
            "{} SELECT t, n, u FROM g ORDER BY {} LIMIT ?{} OFFSET ?{}",
            groups(&condition, sort),
            group_order(sort),
            at + 1,
            at + 2
        ))?;
        statement
            .query_map(params_from_iter(values), |row| {
                Ok((row.get(0)?, row.get(1)?, row.get(2)?))
            })?
            .collect()
    }

    /// The conversations with rows in `offset..offset + limit` of the grouped list, with the conversations `expanded`
    /// open, and how many rows of the first one are above `offset`. One ranking of the list's conversations, each
    /// counted as its rows (one, or all of its messages when open) on from those above it.
    fn thread_window(
        &self,
        search: &Search,
        sort: Sort,
        expanded: &[i64],
        offset: u64,
        limit: u64,
    ) -> Result<(Vec<Group>, u64)> {
        let (condition, mut values) = search.condition(false);
        let open = numbered_marks(&mut values, expanded);
        let at = values.len();
        values.push(Value::Integer(offset as i64));
        values.push(Value::Integer(offset.saturating_add(limit) as i64));
        values.push(Value::Integer(limit as i64));
        let mut statement = self.db.prepare(&format!(
            "{}, spans AS (SELECT t, n, u, h, SUM(h) OVER (ORDER BY {} ROWS UNBOUNDED PRECEDING) AS e \
             FROM (SELECT *, CASE WHEN t IN ({open}) THEN n ELSE 1 END AS h FROM g)) \
             SELECT t, n, u, e - h FROM spans WHERE e > ?{} AND e - h < ?{} ORDER BY e LIMIT ?{}",
            groups(&condition, sort),
            group_order(sort),
            at + 1,
            at + 2,
            at + 3
        ))?;
        let mut above = 0;
        let page = statement
            .query_map(params_from_iter(values), |row| {
                Ok(((row.get(0)?, row.get(1)?, row.get(2)?), row.get::<_, u64>(3)?))
            })?
            .enumerate()
            .map(|(i, found)| {
                let (group, start) = found?;
                if i == 0 {
                    above = offset.saturating_sub(start);
                }
                Ok(group)
            })
            .collect::<Result<_>>()?;
        Ok((page, above))
    }

    /// The first message of each of the conversations `threads` in what `search` finds, by conversation: one query,
    /// whose numbering finds each conversation's first on its index and reads only those rows whole
    fn thread_firsts(&self, search: &Search, threads: &[i64]) -> Result<HashMap<i64, Message>> {
        if threads.is_empty() {
            return Ok(HashMap::new());
        }
        let (condition, mut values) = search.condition(false);
        let marks = numbered_marks(&mut values, threads);
        let mut statement = self.db.prepare(&format!(
            "SELECT {COLUMNS} FROM messages WHERE id IN (SELECT id FROM (SELECT id, ROW_NUMBER() OVER \
             (PARTITION BY thread_id ORDER BY {WHEN}, uid, id) AS k FROM messages \
             WHERE {condition} AND thread_id IN ({marks})) WHERE k = 1)"
        ))?;
        statement
            .query_map(params_from_iter(values), from_row)?
            .map(|found| found.map(|m| (m.info.thread_id.unwrap_or_default(), m)))
            .collect()
    }

    /// The messages of the conversations `threads` in what `search` finds, by conversation, each's first first
    fn thread_lists(&self, search: &Search, threads: &[i64]) -> Result<HashMap<i64, Vec<Message>>> {
        let mut lists: HashMap<i64, Vec<Message>> = HashMap::new();
        if threads.is_empty() {
            return Ok(lists);
        }
        let (condition, mut values) = search.condition(false);
        let marks = numbered_marks(&mut values, threads);
        let mut statement = self.db.prepare(&format!(
            // the conversations' rows found by their index, then ordered (+ keeps the planner off the date index)
            "SELECT {COLUMNS} FROM messages WHERE {condition} AND thread_id IN ({marks}) ORDER BY +{WHEN}, uid, id"
        ))?;
        for found in statement.query_map(params_from_iter(values), from_row)? {
            let message = found?;
            lists
                .entry(message.info.thread_id.unwrap_or_default())
                .or_default()
                .push(message);
        }
        Ok(lists)
    }

    /// A collapsed conversation's row shows the dates of its newest message, as the list places it by them. Its own
    /// small query on the conversations' index rather than a MAX in [`groups`]: with a MAX there besides the MIN, SQLite
    /// would no longer take the key sorts' bare column (`k`) from the first message's row.
    fn date_collapsed(&self, search: &Search, rows: &mut [Message]) -> Result<()> {
        let threads: Vec<i64> = rows
            .iter()
            .filter_map(|m| m.thread.filter(ThreadPlace::collapsed))
            .map(|t| t.thread)
            .collect();
        if threads.is_empty() {
            return Ok(());
        }
        let (condition, mut values) = search.condition(false);
        let marks = numbered_marks(&mut values, &threads);
        let mut statement = self.db.prepare(&format!(
            "SELECT thread_id, MAX(date), MAX(internal_date) FROM messages WHERE {condition} AND thread_id IN ({marks}) \
             GROUP BY thread_id"
        ))?;
        let newest: HashMap<i64, (Option<i64>, Option<i64>)> = statement
            .query_map(params_from_iter(values), |row| {
                Ok((row.get(0)?, (row.get(1)?, row.get(2)?)))
            })?
            .collect::<Result<_>>()?;
        for row in rows {
            if let Some(place) = row.thread.filter(ThreadPlace::collapsed)
                && let Some(&(date, received)) = newest.get(&place.thread)
            {
                let info = &mut row.info;
                info.date = date.or(info.date);
                info.internal_date = received.or(info.internal_date);
            }
        }
        Ok(())
    }

    /// The messages of the conversation `thread` in what `search` finds, the first first
    pub fn thread_messages(&self, search: &Search, thread: i64) -> Result<Vec<Message>> {
        Ok(self
            .thread_lists(search, &[thread])?
            .remove(&thread)
            .unwrap_or_default())
    }

    /// Next Unread in the list grouped by conversation, as if every conversation were open: an unread message after
    /// the message `uid` of `folder` in its own conversation, or else the first unread message of the next
    /// conversation that has one (from the top when `uid` is 0 or not in the list). The list opens its conversation.
    pub(crate) fn next_unread_in_threads(
        &self,
        search: &Search,
        sort: Sort,
        folder: FolderId,
        uid: u64,
    ) -> Result<Option<MessageRef>> {
        let first_unread = |thread: i64, after: Option<i64>| -> Result<Option<MessageRef>> {
            let messages = self.thread_messages(search, thread)?;
            let start = after
                .and_then(|id| messages.iter().position(|m| m.id == id))
                .map_or(0, |at| at + 1);
            Ok(messages[start.min(messages.len())..]
                .iter()
                .find(|m| !m.info.seen())
                .map(Message::at))
        };
        let current = self.message(folder, uid)?.and_then(|m| Some((m.info.thread_id?, m.id)));
        if let Some((thread, id)) = current
            && let Some(found) = first_unread(thread, Some(id))?
        {
            return Ok(Some(found));
        }
        let (condition, mut values) = search.condition(false);
        values.push(Value::Integer(current.map_or(0, |(thread, _)| thread)));
        let mut statement = self.db.prepare_cached(&format!(
            "{}, ranked AS (SELECT t, u, ROW_NUMBER() OVER (ORDER BY {}) AS r FROM g) \
             SELECT t FROM ranked WHERE u > 0 AND r > COALESCE((SELECT r FROM ranked WHERE t = ?{}), 0) \
             ORDER BY r LIMIT 1",
            groups(&condition, sort),
            group_order(sort),
            values.len()
        ))?;
        let next: Option<i64> = statement
            .query_row(params_from_iter(values), |row| row.get(0))
            .optional()?;
        match next {
            Some(thread) => first_unread(thread, None),
            None => Ok(None),
        }
    }

    /// Where the conversations `threads` are among the conversations of the list (their first message's row without
    /// the expanded ones above), and how many messages each has there; those not in the list left out
    fn thread_ranks(&self, search: &Search, sort: Sort, threads: &[i64]) -> Result<Vec<(u64, i64, u64)>> {
        if threads.is_empty() {
            return Ok(Vec::new());
        }
        let (condition, mut values) = search.condition(false);
        let marks = numbered_marks(&mut values, threads);
        let mut statement = self.db.prepare(&format!(
            "{} SELECT r, t, n FROM (SELECT t, n, ROW_NUMBER() OVER (ORDER BY {}) - 1 AS r FROM g) \
             WHERE t IN ({marks}) ORDER BY r",
            groups(&condition, sort),
            group_order(sort),
        ))?;
        statement
            .query_map(params_from_iter(values), |row| {
                Ok((row.get(0)?, row.get(1)?, row.get(2)?))
            })?
            .collect()
    }

    /// How many rows the list grouped by conversation has, with the conversations `expanded` open: one a
    /// conversation, and the others of the open ones' messages
    pub(crate) fn count_thread_rows(&self, search: &Search, expanded: &[i64]) -> Result<u64> {
        let (condition, mut values) = search.condition(false);
        let conversations: u64 = self
            .db
            .prepare_cached(&format!(
                "SELECT COUNT(DISTINCT thread_id) FROM messages WHERE {condition}"
            ))?
            .query_row(params_from_iter(values.clone()), |row| row.get(0))?;
        if expanded.is_empty() {
            return Ok(conversations);
        }
        let marks = numbered_marks(&mut values, expanded);
        let mut statement = self.db.prepare(&format!(
            "SELECT COUNT(*) FROM messages WHERE {condition} AND thread_id IN ({marks}) GROUP BY thread_id"
        ))?;
        let opened = statement
            .query_map(params_from_iter(values), |row| row.get::<_, u64>(0))?
            .try_fold(0u64, |sum, n| Ok::<_, crate::Error>(sum + n?.saturating_sub(1)))?;
        Ok(conversations + opened)
    }

    /// `limit` rows of the list grouped by conversation from `offset` on: each conversation's first message, and
    /// under each of the conversations `expanded` its other messages, oldest first; each with its place
    pub(crate) fn thread_rows(
        &self,
        search: &Search,
        sort: Sort,
        expanded: &[i64],
        offset: u64,
        limit: u64,
    ) -> Result<Vec<Message>> {
        let open: HashSet<i64> = expanded.iter().copied().collect();
        // the conversations with rows on the page, and how many rows of the first one are above it
        let (page, mut above) = if open.is_empty() {
            (self.thread_page(search, sort, offset, limit)?, 0)
        } else {
            self.thread_window(search, sort, expanded, offset, limit)?
        };
        let (opened, closed): (Vec<i64>, Vec<i64>) = page.iter().map(|g| g.0).partition(|t| open.contains(t));
        let mut firsts = self.thread_firsts(search, &closed)?;
        let mut lists = self.thread_lists(search, &opened)?;
        let mut rows = Vec::new();
        for (thread, count, unread) in page {
            let expanded = open.contains(&thread);
            let messages = if expanded {
                lists.remove(&thread).unwrap_or_default()
            } else {
                firsts.remove(&thread).into_iter().collect()
            };
            let place = ThreadPlace {
                thread,
                depth: 0,
                count,
                unread,
                expanded,
            };
            let skip = std::mem::take(&mut above) as usize;
            for (at, message) in messages.into_iter().enumerate().skip(skip) {
                if rows.len() as u64 >= limit {
                    break;
                }
                rows.push(Message {
                    thread: Some(ThreadPlace {
                        depth: u32::from(at > 0),
                        ..place
                    }),
                    ..message
                });
            }
        }
        self.date_collapsed(search, &mut rows)?;
        Ok(rows)
    }

    /// The conversation of the message `uid` of `folder`, None when that message is not in what `search` finds
    fn thread_in_list(&self, search: &Search, folder: FolderId, uid: u64) -> Result<Option<i64>> {
        let (condition, mut values) = search.condition(false);
        let at = values.len();
        values.push(Value::Integer(folder));
        values.push(Value::Integer(uid as i64));
        let mut statement = self.db.prepare_cached(&format!(
            "SELECT thread_id FROM messages WHERE folder_id = ?{} AND uid = ?{} AND {condition}",
            at + 1,
            at + 2
        ))?;
        statement
            .query_row(params_from_iter(values), |row| row.get(0))
            .optional()
    }

    /// Where the message `uid` of `folder` is in the list grouped by conversation: its own row when its conversation is
    /// open or it is the first, its conversation's row otherwise; None when it is not in the list
    pub(crate) fn thread_row_index(
        &self,
        search: &Search,
        sort: Sort,
        expanded: &[i64],
        folder: FolderId,
        uid: u64,
    ) -> Result<Option<u64>> {
        let Some(thread) = self.thread_in_list(search, folder, uid)? else {
            return Ok(None);
        };
        let at = MessageRef { folder, uid };
        Ok(self
            .thread_positions(search, sort, expanded, &[(at, thread)])?
            .first()
            .copied())
    }

    /// The rows of the messages `found` (each with its conversation, all in the list) in the list grouped by
    /// conversation, in the order of `found`: one ranking of their conversations and the open ones, and the order of
    /// the open ones among them
    pub(crate) fn thread_positions(
        &self,
        search: &Search,
        sort: Sort,
        expanded: &[i64],
        found: &[(MessageRef, i64)],
    ) -> Result<Vec<u64>> {
        if found.is_empty() {
            return Ok(Vec::new());
        }
        let open: HashSet<i64> = expanded.iter().copied().collect();
        let mut wanted: Vec<i64> = found.iter().map(|&(_, t)| t).chain(open.iter().copied()).collect();
        wanted.sort_unstable();
        wanted.dedup();
        // each conversation's first row: its rank, and the rows of the open ones above it
        let mut first_rows: HashMap<i64, u64> = HashMap::new();
        let mut opened_above = 0;
        for (rank, thread, n) in self.thread_ranks(search, sort, &wanted)? {
            first_rows.insert(thread, rank + opened_above);
            if open.contains(&thread) {
                opened_above += n.saturating_sub(1);
            }
        }
        // in an open conversation each message has its own row, in the conversation's order
        let mut opened: Vec<i64> = found.iter().map(|&(_, t)| t).filter(|t| open.contains(t)).collect();
        opened.sort_unstable();
        opened.dedup();
        let mut under: HashMap<MessageRef, u64> = HashMap::new();
        let mut counted: HashMap<i64, u64> = HashMap::new();
        for (thread, member) in self.thread_members(search, &opened)? {
            let at = counted.entry(thread).or_default();
            under.insert(member, *at);
            *at += 1;
        }
        Ok(found
            .iter()
            .filter_map(|(at, thread)| {
                let first = *first_rows.get(thread)?;
                if open.contains(thread) {
                    Some(first + under.get(at)?)
                } else {
                    Some(first)
                }
            })
            .collect())
    }

    /// The conversation the message `uid` of `folder` is hidden in, in the list `search` makes: its conversation when
    /// the list is grouped, that conversation is not expanded and the message is not its first there (whose row stands
    /// for it). None when the message has its own row, or is not in the list.
    pub fn hidden_in(&self, search: &Search, folder: FolderId, uid: u64) -> Result<Option<i64>> {
        let Some(expanded) = &search.threads else {
            return Ok(None);
        };
        let Some(thread) = self.thread_in_list(search, folder, uid)? else {
            return Ok(None);
        };
        if expanded.contains(&thread) {
            return Ok(None);
        }
        let first = self.thread_firsts(search, &[thread])?.remove(&thread);
        Ok(first.filter(|m| m.at() != MessageRef { folder, uid }).map(|_| thread))
    }

    /// The conversations in what `search` finds that have more than one message there: what Expand All opens
    pub fn threads_with_replies(&self, search: &Search) -> Result<Vec<i64>> {
        let (condition, values) = search.condition(false);
        let mut statement = self.db.prepare_cached(&format!(
            "SELECT thread_id FROM messages WHERE {condition} GROUP BY thread_id HAVING COUNT(*) > 1"
        ))?;
        statement
            .query_map(params_from_iter(values), |row| row.get(0))?
            .collect()
    }

    /// The messages of the rows in `ranges` (start included, end not) of the list grouped by conversation: a collapsed
    /// conversation's row stands for all of its messages in the list
    pub(crate) fn thread_refs_in_ranges(
        &self,
        search: &Search,
        sort: Sort,
        ranges: &[(u64, u64)],
    ) -> Result<Vec<MessageRef>> {
        // the rows in list order; a collapsed conversation's row stands for its messages, oldest first, in its place
        let mut rows = Vec::new();
        for &(start, end) in ranges {
            for message in self.search(search, sort, start, end - start)? {
                rows.push(match message.thread.filter(ThreadPlace::collapsed) {
                    Some(place) => RowRefs::Conversation(place.thread),
                    None => RowRefs::Message(message.at()),
                });
            }
        }
        let collapsed: Vec<i64> = rows
            .iter()
            .filter_map(|row| match row {
                RowRefs::Conversation(thread) => Some(*thread),
                RowRefs::Message(_) => None,
            })
            .collect();
        let mut members: HashMap<i64, Vec<MessageRef>> = HashMap::new();
        for (thread, found) in self.thread_members(search, &collapsed)? {
            members.entry(thread).or_default().push(found);
        }
        let mut seen = HashSet::new();
        let mut refs = Vec::new();
        for row in rows {
            let found = match row {
                RowRefs::Message(found) => vec![found],
                RowRefs::Conversation(thread) => members.remove(&thread).unwrap_or_default(),
            };
            refs.extend(found.into_iter().filter(|r| seen.insert(*r)));
        }
        Ok(refs)
    }

    /// The messages of the conversations `threads` in the list `search` makes, each with its conversation, oldest
    /// first
    fn thread_members(&self, search: &Search, threads: &[i64]) -> Result<Vec<(i64, MessageRef)>> {
        if threads.is_empty() {
            return Ok(Vec::new());
        }
        let (condition, mut values) = search.condition(false);
        let marks = numbered_marks(&mut values, threads);
        let mut statement = self.db.prepare(&format!(
            "SELECT thread_id, folder_id, uid FROM messages WHERE {condition} AND thread_id IN ({marks}) \
             ORDER BY +{WHEN}, uid, id"
        ))?;
        statement
            .query_map(params_from_iter(values), |row| {
                Ok((
                    row.get(0)?,
                    MessageRef {
                        folder: row.get(1)?,
                        uid: row.get::<_, i64>(2)? as u64,
                    },
                ))
            })?
            .collect()
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::{AccountSettings, FolderInfo};

    fn setup() -> (Store, AccountId, FolderId, FolderId) {
        let store = Store::open_in_memory().unwrap();
        let account = store.add_account(&AccountSettings::example("a@example.com")).unwrap();
        let folder = |path: &str| FolderInfo {
            path: path.into(),
            name: path.into(),
            selectable: true,
            ..Default::default()
        };
        store.set_folders(account, &[folder("INBOX"), folder("Sent")]).unwrap();
        let folders = store.folders(account).unwrap();
        (store, account, folders[0].id, folders[1].id)
    }

    /// A message `uid` dated `at`, with its own id and the ids it answers (its References)
    fn mail(uid: u64, at: i64, id: &str, answers: &[&str], seen: bool) -> MessageInfo {
        MessageInfo {
            uid,
            date: Some(at),
            subject: id.trim_matches(['<', '>']).into(),
            message_id: Some(id.into()),
            references: answers.iter().map(|a| a.to_string()).collect(),
            flags: if seen { vec!["\\Seen".into()] } else { Vec::new() },
            ..Default::default()
        }
    }

    fn place(row: &Message) -> ThreadPlace {
        row.thread.expect("a row of a grouped list")
    }

    fn subjects(rows: &[Message]) -> Vec<(String, u32)> {
        rows.iter().map(|r| (r.info.subject.clone(), place(r).depth)).collect()
    }

    #[test]
    fn groups_replies_into_conversations() {
        let (store, _, inbox, sent) = setup();
        // a: the start, b answers a, c answers b (naming both), d stands alone; e answers a in Sent Items
        store
            .add_messages(
                inbox,
                &[
                    mail(1, 100, "<a@x>", &[], true),
                    mail(2, 200, "<d@x>", &[], true),
                    mail(3, 300, "<b@x>", &["<a@x>"], false),
                    mail(4, 400, "<c@x>", &["<a@x>", "<b@x>"], true),
                ],
            )
            .unwrap();
        store
            .add_messages(sent, &[mail(1, 350, "<e@x>", &["<a@x>"], true)])
            .unwrap();
        let list = Search::folder(inbox);
        let newest = Sort::default();

        // collapsed: a's conversation (newest message 400) above d's (200); a stands for b and c
        let rows = store.thread_rows(&list, newest, &[], 0, 10).unwrap();
        assert_eq!(subjects(&rows), [("a@x".into(), 0), ("d@x".into(), 0)]);
        assert_eq!(
            rows[0].info.date,
            Some(400),
            "collapsed: the date of its newest message"
        );
        assert_eq!(
            (place(&rows[0]).count, place(&rows[0]).unread),
            (3, 1),
            "the conversation's messages in this folder"
        );
        assert_eq!(store.count_thread_rows(&list, &[]).unwrap(), 2);
        // the reply in Sent Items is in the same conversation, not in this list
        let a = place(&rows[0]).thread;
        assert_eq!(store.message(sent, 1).unwrap().unwrap().info.thread_id, Some(a));

        // expanded: its other messages under it, oldest first, and the pages agree
        let open = [a];
        let rows = store.thread_rows(&list, newest, &open, 0, 10).unwrap();
        assert_eq!(
            subjects(&rows),
            [
                ("a@x".into(), 0),
                ("b@x".into(), 1),
                ("c@x".into(), 1),
                ("d@x".into(), 0)
            ]
        );
        assert_eq!(store.count_thread_rows(&list, &open).unwrap(), 4);
        assert_eq!(rows[0].info.date, Some(100), "expanded: its own");
        let paged: Vec<(String, u32)> = (0..4)
            .flat_map(|at| subjects(&store.thread_rows(&list, newest, &open, at, 1).unwrap()))
            .collect();
        assert_eq!(paged, subjects(&rows), "a page from inside a conversation");
        assert_eq!(
            subjects(&store.thread_rows(&list, newest, &open, 2, 2).unwrap()),
            [("c@x".into(), 1), ("d@x".into(), 0)]
        );
        // a message's row: its own when open, its conversation's otherwise
        assert_eq!(store.thread_row_index(&list, newest, &open, inbox, 4).unwrap(), Some(2));
        assert_eq!(store.thread_row_index(&list, newest, &[], inbox, 4).unwrap(), Some(0));
        assert_eq!(store.thread_row_index(&list, newest, &open, inbox, 2).unwrap(), Some(3));
        assert_eq!(store.threads_with_replies(&list).unwrap(), [a]);

        // the same through the list's own calls, grouped: a collapsed row selects its conversation
        let grouped = Search {
            threads: Some(Vec::new()),
            ..Search::folder(inbox)
        };
        assert_eq!(
            store.count_search(&grouped).unwrap(),
            (4, 1),
            "messages, grouped or not"
        );
        assert_eq!(store.count_rows(&grouped).unwrap(), 2, "rows: a conversation's one");
        assert_eq!(store.count_rows(&list).unwrap(), 4, "ungrouped: one a message");
        let picked = store.refs_in_ranges(&grouped, newest, &[(0, 1)]).unwrap();
        assert_eq!(picked.len(), 3, "the three messages of the collapsed conversation");
        let both = store.refs_in_ranges(&grouped, newest, &[(0, 2)]).unwrap();
        assert_eq!(
            both.iter().map(|r| r.uid).collect::<Vec<_>>(),
            [1, 3, 4, 2],
            "in list order: the conversation oldest first in its row's place, then d"
        );
        assert_eq!(
            store.positions(&grouped, newest, &picked).unwrap(),
            [0],
            "all on its one row"
        );
        let open = Search {
            threads: Some(vec![a]),
            ..Search::folder(inbox)
        };
        assert_eq!(
            store.refs_in_ranges(&open, newest, &[(1, 2)]).unwrap().len(),
            1,
            "an open one's row is one message"
        );
        assert_eq!(
            store.search(&open, newest, 0, 10).unwrap()[0]
                .thread
                .map(|t| t.expanded),
            Some(true)
        );
        let (before, after) = store.neighbours(&open, newest, inbox, 3).unwrap().unwrap();
        assert_eq!(
            (before.map(|r| r.uid), after.map(|r| r.uid)),
            (Some(1), Some(4)),
            "the rows around b"
        );
        // Next Unread finds the unread reply b in the collapsed conversation, from the top and from a
        let collapsed = Search {
            threads: Some(Vec::new()),
            ..Search::folder(inbox)
        };
        for from in [0, 1] {
            assert_eq!(
                store
                    .next_unread(&collapsed, newest, inbox, from)
                    .unwrap()
                    .map(|r| r.uid),
                Some(3),
                "from {from}"
            );
        }
        // after b, the rest is read
        assert_eq!(store.next_unread(&collapsed, newest, inbox, 3).unwrap(), None);
    }

    /// Four conversations in the Inbox: G (7, 8) newest at 500, A (1, 3, 4) at 400 with a reply in Sent Items, E (5,
    /// 6) at 250, D (2) alone at 200; 3 and 6 unread
    fn four_conversations() -> (Store, FolderId, FolderId) {
        let (store, _, inbox, sent) = setup();
        store
            .add_messages(
                inbox,
                &[
                    mail(1, 100, "<a@x>", &[], true),
                    mail(2, 200, "<d@x>", &[], true),
                    mail(3, 300, "<b@x>", &["<a@x>"], false),
                    mail(4, 400, "<c@x>", &["<a@x>", "<b@x>"], true),
                    mail(5, 150, "<e@x>", &[], true),
                    mail(6, 250, "<f@x>", &["<e@x>"], false),
                    mail(7, 50, "<g@x>", &[], true),
                    mail(8, 500, "<h@x>", &["<g@x>"], true),
                ],
            )
            .unwrap();
        store
            .add_messages(sent, &[mail(1, 350, "<x@x>", &["<a@x>"], true)])
            .unwrap();
        (store, inbox, sent)
    }

    #[test]
    fn grouped_list_calls_agree_with_its_rows() {
        let (store, inbox, sent) = four_conversations();
        let thread = |uid: u64| store.message(inbox, uid).unwrap().unwrap().info.thread_id.unwrap();
        let (a, e, g) = (thread(1), thread(5), thread(7));
        let refs: Vec<MessageRef> = (1..=8)
            .map(|uid| MessageRef { folder: inbox, uid })
            .chain([MessageRef { folder: sent, uid: 1 }])
            .collect();
        let sorts = [
            Sort::default(),
            Sort {
                ascending: true,
                ..Sort::default()
            },
            Sort {
                field: SortField::Subject,
                ascending: true,
            },
            Sort {
                field: SortField::Received,
                ascending: false,
            },
        ];
        for expanded in [vec![], vec![a], vec![a, g], vec![e, a], vec![a, e, g, 12345]] {
            let search = Search {
                threads: Some(expanded.clone()),
                ..Search::folder(inbox)
            };
            for sort in sorts {
                let what = format!("{expanded:?} {sort:?}");
                let all = store.search(&search, sort, 0, 100).unwrap();
                // where each message is, read off the rows: a collapsed row stands for its conversation's messages
                let mut oracle: HashMap<MessageRef, u64> = HashMap::new();
                for (i, row) in all.iter().enumerate() {
                    if place(row).collapsed() {
                        for member in store.thread_messages(&search, place(row).thread).unwrap() {
                            oracle.insert(member.at(), i as u64);
                        }
                    } else {
                        oracle.insert(row.at(), i as u64);
                    }
                }
                assert_eq!(oracle.len(), 8, "{what}");
                assert_eq!(store.count_rows(&search).unwrap(), all.len() as u64, "{what}");
                assert_eq!(store.count_search(&search).unwrap(), (8, 2), "{what}");
                let mut expected: Vec<u64> = oracle.values().copied().collect();
                expected.sort_unstable();
                expected.dedup();
                assert_eq!(store.positions(&search, sort, &refs).unwrap(), expected, "{what}");
                for r in &refs {
                    assert_eq!(
                        store.search_index(&search, sort, r.folder, r.uid).unwrap(),
                        oracle.get(r).copied(),
                        "{what} {r:?}"
                    );
                }
                // pages of any size agree with the whole list
                for size in [1, 2, 3] {
                    let paged: Vec<Message> = (0..all.len() as u64)
                        .step_by(size)
                        .flat_map(|at| store.search(&search, sort, at, size as u64).unwrap())
                        .collect();
                    assert_eq!(paged, all, "{what} pages of {size}");
                }
                // the neighbours of the top row, and of one in the middle
                let top = all[0].at();
                assert_eq!(
                    store.neighbours(&search, sort, top.folder, top.uid).unwrap(),
                    Some((None, Some(all[1].at()))),
                    "{what}"
                );
                let middle = all[2].at();
                assert_eq!(
                    store.neighbours(&search, sort, middle.folder, middle.uid).unwrap(),
                    Some((Some(all[1].at()), all.get(3).map(Message::at))),
                    "{what}"
                );
            }
        }
    }

    #[test]
    fn hidden_in_its_collapsed_conversation() {
        let (store, inbox, sent) = four_conversations();
        let thread = |uid: u64| store.message(inbox, uid).unwrap().unwrap().info.thread_id.unwrap();
        let a = thread(1);
        let collapsed = Search {
            threads: Some(Vec::new()),
            ..Search::folder(inbox)
        };
        assert_eq!(store.hidden_in(&collapsed, inbox, 3).unwrap(), Some(a), "a reply");
        assert_eq!(store.hidden_in(&collapsed, inbox, 4).unwrap(), Some(a));
        assert_eq!(
            store.hidden_in(&collapsed, inbox, 1).unwrap(),
            None,
            "the first has the row"
        );
        assert_eq!(store.hidden_in(&collapsed, inbox, 2).unwrap(), None, "alone");
        assert_eq!(store.hidden_in(&collapsed, sent, 1).unwrap(), None, "not in the list");
        assert_eq!(store.hidden_in(&collapsed, inbox, 99).unwrap(), None, "gone");
        let open = Search {
            threads: Some(vec![a]),
            ..Search::folder(inbox)
        };
        assert_eq!(store.hidden_in(&open, inbox, 3).unwrap(), None, "expanded");
        assert_eq!(
            store.hidden_in(&Search::folder(inbox), inbox, 3).unwrap(),
            None,
            "ungrouped"
        );
    }

    #[test]
    fn bold_rows() {
        let (store, inbox, _) = four_conversations();
        let thread = |uid: u64| store.message(inbox, uid).unwrap().unwrap().info.thread_id.unwrap();
        let bold = |search: &Search| -> Vec<(u64, bool)> {
            store
                .search(search, Sort::default(), 0, 100)
                .unwrap()
                .iter()
                .map(|m| (m.info.uid, m.bold()))
                .collect()
        };
        let collapsed = Search {
            threads: Some(Vec::new()),
            ..Search::folder(inbox)
        };
        // G read; A and E stand for their unread replies; D read
        assert_eq!(bold(&collapsed), [(7, false), (1, true), (5, true), (2, false)]);
        let open = Search {
            threads: Some(vec![thread(1)]),
            ..Search::folder(inbox)
        };
        // open, each row its own message's
        assert_eq!(
            bold(&open),
            [(7, false), (1, false), (3, true), (4, false), (5, true), (2, false)]
        );
        let rows = store.search(&open, Sort::default(), 0, 100).unwrap();
        let places: Vec<(bool, bool)> = rows.iter().map(|m| (place(m).opens(), place(m).collapsed())).collect();
        assert_eq!(
            places,
            [
                (true, true),
                (true, false),
                (false, false),
                (false, false),
                (true, true),
                (false, false)
            ]
        );
        assert!(
            bold(&Search::folder(inbox))
                .iter()
                .all(|&(uid, bold)| bold == (uid == 3 || uid == 6))
        );
    }

    #[test]
    fn a_reply_that_comes_first_joins_its_parent_later() {
        let (store, _, inbox, _) = setup();
        // the reply arrives before what it answers, and a third names both conversations' ids
        store
            .add_messages(inbox, &[mail(1, 200, "<r@x>", &["<p@x>"], true)])
            .unwrap();
        store
            .add_messages(inbox, &[mail(2, 100, "<other@x>", &[], true)])
            .unwrap();
        store
            .add_messages(inbox, &[mail(3, 300, "<both@x>", &["<p@x>", "<other@x>"], true)])
            .unwrap();
        store.add_messages(inbox, &[mail(4, 50, "<p@x>", &[], true)]).unwrap();
        let rows = store
            .thread_rows(&Search::folder(inbox), Sort::default(), &[], 0, 10)
            .unwrap();
        assert_eq!(rows.len(), 1, "one conversation: {:?}", subjects(&rows));
        assert_eq!(place(&rows[0]).count, 4);
        assert_eq!(rows[0].info.subject, "p@x", "its first message stands for it");
    }

    /// How long a page of a big folder grouped by conversation takes (cargo test --release -- --ignored big_folder)
    #[test]
    #[ignore]
    fn big_folder() {
        let (store, _, inbox, _) = setup();
        let messages: Vec<MessageInfo> = (1..=120_000u64)
            .map(|uid| {
                // conversations of one to four messages
                let parent = format!("<{}@x>", uid - uid % 4);
                let answers: Vec<&str> = if uid % 4 == 0 {
                    Vec::new()
                } else {
                    vec![parent.as_str()]
                };
                mail(uid, uid as i64, &format!("<{uid}@x>"), &answers, uid % 7 != 0)
            })
            .collect();
        for chunk in messages.chunks(5000) {
            store.add_messages(inbox, chunk).unwrap();
        }
        let list = Search::folder(inbox);
        let started = std::time::Instant::now();
        store.thread_page(&list, Sort::default(), 0, 100).unwrap();
        eprintln!("page of ids {:?}", started.elapsed());
        let started = std::time::Instant::now();
        store.thread_page(&list, Sort::default(), 0, 100).unwrap();
        eprintln!("page of ids again {:?}", started.elapsed());
        let (condition, _) = list.condition(false);
        let plan: Vec<String> = store
            .db
            .prepare(&format!(
                "EXPLAIN QUERY PLAN {} SELECT t FROM g ORDER BY {} LIMIT 100",
                groups(&condition, Sort::default()),
                group_order(Sort::default())
            ))
            .unwrap()
            .query_map(params_from_iter(list.condition(false).1), |row| row.get::<_, String>(3))
            .unwrap()
            .map(|r| r.unwrap())
            .collect();
        eprintln!("plan {plan:?}");
        let started = std::time::Instant::now();
        let rows = store.thread_rows(&list, Sort::default(), &[], 0, 100).unwrap();
        let first = started.elapsed();
        let started = std::time::Instant::now();
        let counts = store.count_thread_rows(&list, &[]).unwrap();
        let count = started.elapsed();
        let open = [place(&rows[3]).thread];
        let started = std::time::Instant::now();
        store.thread_rows(&list, Sort::default(), &open, 20_000, 100).unwrap();
        let deep = started.elapsed();
        eprintln!("first page {first:?}, count {count:?} ({counts:?}), a deep page with one open {deep:?}");
        // through the list's own calls
        let grouped = Search {
            threads: Some(Vec::new()),
            ..Search::folder(inbox)
        };
        let time = |what: &str, f: &dyn Fn()| {
            let started = std::time::Instant::now();
            f();
            eprintln!("{what}: {:?}", started.elapsed());
        };
        time("grouped first page", &|| {
            store.search(&grouped, Sort::default(), 0, 100).unwrap();
        });
        time("grouped page 500", &|| {
            store.search(&grouped, Sort::default(), 50_000, 100).unwrap();
        });
        let refs: Vec<MessageRef> = (1..=1000u64)
            .map(|i| MessageRef {
                folder: inbox,
                uid: i * 97,
            })
            .collect();
        time("positions of 1000 refs, collapsed", &|| {
            store.positions(&grouped, Sort::default(), &refs).unwrap();
        });
        let open = Search {
            threads: Some(store.threads_with_replies(&grouped).unwrap()[..2000].to_vec()),
            ..Search::folder(inbox)
        };
        time("positions of 1000 refs, 2000 open", &|| {
            store.positions(&open, Sort::default(), &refs).unwrap();
        });
        time("first page, 2000 open", &|| {
            store.search(&open, Sort::default(), 0, 100).unwrap();
        });
    }

    #[test]
    fn references_fetched_later_join_conversations() {
        let (store, account, inbox, _) = setup();
        // c answers b with no In-Reply-To the store has: only its References, fetched later, say so
        store
            .add_messages(
                inbox,
                &[mail(1, 100, "<b@x>", &[], true), mail(2, 200, "<c@x>", &[], true)],
            )
            .unwrap();
        store.db.execute("UPDATE messages SET refs = NULL", []).unwrap();
        let list = Search::folder(inbox);
        assert_eq!(store.thread_rows(&list, Sort::default(), &[], 0, 10).unwrap().len(), 2);
        let waiting = store.messages_without_references(account, 10).unwrap();
        assert_eq!(
            waiting.iter().map(|(_, _, uid)| *uid).collect::<Vec<_>>(),
            [2, 1],
            "newest first"
        );
        assert!(
            store.set_references(waiting[0].0, &["<b@x>".to_string()]).unwrap(),
            "joined"
        );
        assert!(!store.set_references(waiting[1].0, &[]).unwrap());
        assert!(store.messages_without_references(account, 10).unwrap().is_empty());
        assert_eq!(store.thread_rows(&list, Sort::default(), &[], 0, 10).unwrap().len(), 1);
    }

    #[test]
    fn messages_stored_before_conversations_are_threaded_later() {
        let (store, _, inbox, _) = setup();
        store
            .add_messages(
                inbox,
                &[
                    mail(1, 100, "<a@x>", &[], true),
                    mail(2, 200, "<b@x>", &["<a@x>"], true),
                ],
            )
            .unwrap();
        // as a store from before: no conversations
        store.db.execute("UPDATE messages SET thread_id = -id", []).unwrap();
        store.db.execute("DELETE FROM thread_ids", []).unwrap();
        let list = Search::folder(inbox);
        assert_eq!(
            store.thread_rows(&list, Sort::default(), &[], 0, 10).unwrap().len(),
            2,
            "each its own meanwhile"
        );
        let account = store.accounts().unwrap()[0].id;
        assert_eq!(store.thread_unthreaded(account, 10).unwrap(), 2);
        assert_eq!(store.thread_unthreaded(account, 10).unwrap(), 0);
        assert_eq!(store.thread_rows(&list, Sort::default(), &[], 0, 10).unwrap().len(), 1);
    }

    #[test]
    fn reads_the_ids_of_a_references_header() {
        assert_eq!(
            parse_references("<a@x>\r\n <b@x> junk <c @x>"),
            ["<a@x>", "<b@x>", "<c@x>"]
        );
        assert!(parse_references("no ids <> here").is_empty());
        let many: String = (0..80).map(|i| format!("<{i}@x> ")).collect();
        let kept = parse_references(&many);
        assert_eq!(kept.len(), MAX_REFERENCES);
        assert_eq!(kept.last().map(String::as_str), Some("<79@x>"), "the nearest ones kept");
    }
}
