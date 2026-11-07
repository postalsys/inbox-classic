//! Conversations: the messages of an account that answer each other, found by the Message-IDs they name (their own,
//! In-Reply-To and References, as JWZ threading has it, without guessing from subjects) and, on Gmail, by Gmail's own
//! conversation id. Each account keeps a map from those ids to a conversation id (`thread_ids`); a message that names
//! ids of two conversations joins them into one.

use std::collections::{HashMap, HashSet};

use rusqlite::types::Value;
use rusqlite::{OptionalExtension, params, params_from_iter};

use crate::messages::{COLUMNS, from_row};
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

/// A row's place in a list grouped by conversation ([`Search::threads`])
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

/// A row of [`Store::thread_rows`] as a message of the list
pub(crate) fn placed(row: ThreadRow, expanded: &[i64]) -> Message {
    Message {
        thread: Some(ThreadPlace {
            thread: row.thread,
            depth: row.depth,
            count: row.count,
            unread: row.unread,
            expanded: expanded.contains(&row.thread),
        }),
        ..row.message
    }
}

/// A message to thread: its row id, its Message-ID, In-Reply-To and References as stored
type Unthreaded = (i64, Option<String>, Option<String>, String);

/// A row of the message list grouped by conversation: a conversation's first message (depth 0), standing for all of
/// them while it is collapsed, or, under one that is expanded, one of the others (depth 1)
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct ThreadRow {
    pub message: Message,
    pub thread: i64,
    pub depth: u32,
    /// The messages of the conversation in the list, and how many of them are unread (the same on each of its rows)
    pub count: u32,
    pub unread: u32,
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
    fn thread_page(&self, search: &Search, sort: Sort, offset: u64, limit: u64) -> Result<Vec<(i64, u32, u32)>> {
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

    /// The first message of each conversation in what `search` finds, with the conversation's numbers, in the order of
    /// `sort`: `limit` of them from `offset` on
    fn thread_heads(&self, search: &Search, sort: Sort, offset: u64, limit: u64) -> Result<Vec<ThreadRow>> {
        let mut rows = Vec::new();
        for (thread, count, unread) in self.thread_page(search, sort, offset, limit)? {
            if let Some(first) = self.thread_first(search, thread)? {
                rows.push(ThreadRow {
                    message: first,
                    thread,
                    depth: 0,
                    count,
                    unread,
                });
            }
        }
        Ok(rows)
    }

    /// A collapsed conversation's row shows the dates of its newest message, as the list places it by them
    fn date_collapsed(&self, search: &Search, open: &HashSet<i64>, heads: &mut [ThreadRow]) -> Result<()> {
        let threads: Vec<i64> = heads
            .iter()
            .filter(|h| h.count > 1 && !open.contains(&h.thread))
            .map(|h| h.thread)
            .collect();
        if threads.is_empty() {
            return Ok(());
        }
        let (condition, mut values) = search.condition(false);
        let first = values.len() + 1;
        let marks: Vec<String> = (0..threads.len()).map(|i| format!("?{}", first + i)).collect();
        values.extend(threads.iter().map(|&t| Value::Integer(t)));
        let mut statement = self.db.prepare(&format!(
            "SELECT thread_id, MAX(date), MAX(internal_date) FROM messages WHERE {condition} AND thread_id IN ({}) \
             GROUP BY thread_id",
            marks.join(", ")
        ))?;
        let newest: HashMap<i64, (Option<i64>, Option<i64>)> = statement
            .query_map(params_from_iter(values), |row| {
                Ok((row.get(0)?, (row.get(1)?, row.get(2)?)))
            })?
            .collect::<Result<_>>()?;
        for head in heads {
            if let Some(&(date, received)) = newest.get(&head.thread) {
                let info = &mut head.message.info;
                info.date = date.or(info.date);
                info.internal_date = received.or(info.internal_date);
            }
        }
        Ok(())
    }

    /// The first message of the conversation `thread` in what `search` finds
    fn thread_first(&self, search: &Search, thread: i64) -> Result<Option<Message>> {
        let (condition, mut values) = search.condition(false);
        values.push(Value::Integer(thread));
        let mut statement = self.db.prepare_cached(&format!(
            // the conversation's rows found by its index, then ordered (+ keeps the planner off the date index)
            "SELECT {COLUMNS} FROM messages WHERE {condition} AND thread_id = ?{} ORDER BY +{WHEN}, uid, id LIMIT 1",
            values.len()
        ))?;
        statement.query_row(params_from_iter(values), from_row).optional()
    }

    /// The messages of the conversation `thread` in what `search` finds, the first first
    pub fn thread_messages(&self, search: &Search, thread: i64) -> Result<Vec<Message>> {
        let (condition, mut values) = search.condition(false);
        values.push(Value::Integer(thread));
        let mut statement = self.db.prepare_cached(&format!(
            "SELECT {COLUMNS} FROM messages WHERE {condition} AND thread_id = ?{} ORDER BY +{WHEN}, uid, id",
            values.len()
        ))?;
        statement.query_map(params_from_iter(values), from_row)?.collect()
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
                .map(|m| MessageRef {
                    folder: m.folder_id,
                    uid: m.info.uid,
                }))
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

    /// The conversations in what `search` finds, and how many of their messages are unread
    fn thread_counts(&self, search: &Search) -> Result<(u64, u64)> {
        let (condition, values) = search.condition(false);
        let mut statement = self.db.prepare_cached(&format!(
            "SELECT COUNT(DISTINCT thread_id), COALESCE(SUM(NOT seen), 0) FROM messages WHERE {condition}"
        ))?;
        statement.query_row(params_from_iter(values), |row| Ok((row.get(0)?, row.get(1)?)))
    }

    /// Where the conversations `threads` are among the conversations of the list (their first message's row without
    /// the expanded ones above), and how many messages each has there; those not in the list left out
    fn thread_ranks(&self, search: &Search, sort: Sort, threads: &[i64]) -> Result<Vec<(u64, i64, u64)>> {
        if threads.is_empty() {
            return Ok(Vec::new());
        }
        let (condition, mut values) = search.condition(false);
        let first = values.len() + 1;
        let marks: Vec<String> = (0..threads.len()).map(|i| format!("?{}", first + i)).collect();
        values.extend(threads.iter().map(|&t| Value::Integer(t)));
        let mut statement = self.db.prepare(&format!(
            "{} SELECT r, t, n FROM (SELECT t, n, ROW_NUMBER() OVER (ORDER BY {}) - 1 AS r FROM g) \
             WHERE t IN ({}) ORDER BY r",
            groups(&condition, sort),
            group_order(sort),
            marks.join(", ")
        ))?;
        statement
            .query_map(params_from_iter(values), |row| {
                Ok((row.get(0)?, row.get(1)?, row.get(2)?))
            })?
            .collect()
    }

    /// How many rows the list grouped by conversation has, with the conversations `expanded` open, and how many of
    /// its messages are unread
    pub fn count_thread_rows(&self, search: &Search, sort: Sort, expanded: &[i64]) -> Result<(u64, u64)> {
        let (heads, unread) = self.thread_counts(search)?;
        let opened: u64 = self
            .thread_ranks(search, sort, expanded)?
            .iter()
            .map(|(_, _, n)| n.saturating_sub(1))
            .sum();
        Ok((heads + opened, unread))
    }

    /// `limit` rows of the list grouped by conversation from `offset` on: each conversation's first message, and
    /// under each of the conversations `expanded` its other messages, oldest first
    pub fn thread_rows(
        &self,
        search: &Search,
        sort: Sort,
        expanded: &[i64],
        offset: u64,
        limit: u64,
    ) -> Result<Vec<ThreadRow>> {
        let ranks = self.thread_ranks(search, sort, expanded)?;
        // the conversation row the page starts at, and how far under it (0: the row itself)
        let (mut head, mut under) = (offset, 0u64);
        for &(rank, _, n) in &ranks {
            let opened = n.saturating_sub(1);
            if rank < head {
                if head - rank <= opened {
                    // inside this one's messages
                    under = head - rank;
                    head = rank;
                    break;
                }
                head -= opened;
            } else {
                break;
            }
        }
        let open: HashSet<i64> = ranks.iter().map(|&(_, t, _)| t).collect();
        let mut rows = Vec::new();
        let mut heads = self.thread_heads(search, sort, head, limit)?;
        self.date_collapsed(search, &open, &mut heads)?;
        for (i, row) in heads.into_iter().enumerate() {
            if rows.len() as u64 >= limit {
                break;
            }
            let thread = row.thread;
            let (count, unread) = (row.count, row.unread);
            if !(i == 0 && under > 0) {
                rows.push(row);
            }
            if open.contains(&thread) {
                let skip = if i == 0 { under.saturating_sub(1) } else { 0 };
                for message in self
                    .thread_messages(search, thread)?
                    .into_iter()
                    .skip(1 + skip as usize)
                {
                    if rows.len() as u64 >= limit {
                        break;
                    }
                    rows.push(ThreadRow {
                        message,
                        thread,
                        depth: 1,
                        count,
                        unread,
                    });
                }
            }
        }
        Ok(rows)
    }

    /// Where the message `uid` of `folder` is in the list grouped by conversation: its own row when its conversation is
    /// open or it is the first, its conversation's row otherwise; None when it is not in the list
    pub fn thread_row_index(
        &self,
        search: &Search,
        sort: Sort,
        expanded: &[i64],
        folder: FolderId,
        uid: u64,
    ) -> Result<Option<u64>> {
        let Some(thread) = self
            .db
            .query_row(
                "SELECT thread_id FROM messages WHERE folder_id = ?1 AND uid = ?2",
                params![folder, uid],
                |row| row.get::<_, i64>(0),
            )
            .optional()?
        else {
            return Ok(None);
        };
        // its conversation's rank and the open ones above it, with one ranking of the list
        let mut wanted = expanded.to_vec();
        wanted.push(thread);
        let ranks = self.thread_ranks(search, sort, &wanted)?;
        let Some(&(rank, _, _)) = ranks.iter().find(|(_, t, _)| *t == thread) else {
            return Ok(None);
        };
        let above: u64 = ranks
            .iter()
            .filter(|(r, t, _)| *r < rank && expanded.contains(t))
            .map(|(_, _, n)| n.saturating_sub(1))
            .sum();
        let at = rank + above;
        if !expanded.contains(&thread) {
            return Ok(Some(at));
        }
        let members = self.thread_messages(search, thread)?;
        Ok(members
            .iter()
            .position(|m| m.folder_id == folder && m.info.uid == uid)
            .map(|i| at + i as u64))
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
        let mut rows: Vec<std::result::Result<MessageRef, i64>> = Vec::new();
        for &(start, end) in ranges {
            for message in self.search(search, sort, start, end - start)? {
                rows.push(match message.thread {
                    Some(place) if place.depth == 0 && !place.expanded && place.count > 1 => Err(place.thread),
                    _ => Ok(MessageRef {
                        folder: message.folder_id,
                        uid: message.info.uid,
                    }),
                });
            }
        }
        let collapsed: Vec<i64> = rows.iter().filter_map(|row| row.err()).collect();
        let mut members: HashMap<i64, Vec<MessageRef>> = HashMap::new();
        for (thread, found) in self.thread_members(search, &collapsed)? {
            members.entry(thread).or_default().push(found);
        }
        let mut seen = HashSet::new();
        let mut refs = Vec::new();
        for row in rows {
            let found = match row {
                Ok(found) => vec![found],
                Err(thread) => members.remove(&thread).unwrap_or_default(),
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
        let first = values.len() + 1;
        let marks: Vec<String> = (0..threads.len()).map(|i| format!("?{}", first + i)).collect();
        values.extend(threads.iter().map(|&t| Value::Integer(t)));
        let mut statement = self.db.prepare(&format!(
            "SELECT thread_id, folder_id, uid FROM messages WHERE {condition} AND thread_id IN ({}) \
             ORDER BY +{WHEN}, uid, id",
            marks.join(", ")
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

    /// The messages of the conversations of `refs` in the list `search` makes: what an action on a collapsed
    /// conversation's row acts on
    pub fn thread_refs(&self, search: &Search, threads: &[i64]) -> Result<Vec<MessageRef>> {
        Ok(self
            .thread_members(search, threads)?
            .into_iter()
            .map(|(_, found)| found)
            .collect())
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

    fn subjects(rows: &[ThreadRow]) -> Vec<(String, u32)> {
        rows.iter().map(|r| (r.message.info.subject.clone(), r.depth)).collect()
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
            rows[0].message.info.date,
            Some(400),
            "collapsed: the date of its newest message"
        );
        assert_eq!(
            (rows[0].count, rows[0].unread),
            (3, 1),
            "the conversation's messages in this folder"
        );
        assert_eq!(store.count_thread_rows(&list, newest, &[]).unwrap(), (2, 1));
        // the reply in Sent Items is in the same conversation, not in this list
        let a = rows[0].thread;
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
        assert_eq!(store.count_thread_rows(&list, newest, &open).unwrap().0, 4);
        assert_eq!(rows[0].message.info.date, Some(100), "expanded: its own");
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
        // what an action on the collapsed row acts on
        assert_eq!(store.thread_refs(&list, &[a]).unwrap().len(), 3);
        assert_eq!(store.threads_with_replies(&list).unwrap(), [a]);

        // the same through the list's own calls, grouped: a collapsed row selects its conversation
        let grouped = Search {
            threads: Some(Vec::new()),
            ..Search::folder(inbox)
        };
        assert_eq!(store.count_search(&grouped).unwrap(), (2, 1));
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
        assert_eq!(rows[0].count, 4);
        assert_eq!(rows[0].message.info.subject, "p@x", "its first message stands for it");
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
        let counts = store.count_thread_rows(&list, Sort::default(), &[]).unwrap();
        let count = started.elapsed();
        let open = [rows[3].thread];
        let started = std::time::Instant::now();
        store.thread_rows(&list, Sort::default(), &open, 20_000, 100).unwrap();
        let deep = started.elapsed();
        eprintln!("first page {first:?}, count {count:?} ({counts:?}), a deep page with one open {deep:?}");
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
