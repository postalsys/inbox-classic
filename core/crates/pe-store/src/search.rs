//! Searching the message list: by folder or in every folder, by state (unread, flagged, with files) and by what is
//! typed (see [`crate::query`], Gmail's syntax) in the full-text index (`messages_fts`, FTS5): subject, senders,
//! recipients, file names and its text (from its text part, fetched for the index, or from its cached source).

use rusqlite::types::Value;
use rusqlite::{OptionalExtension, params, params_from_iter};

use crate::messages::{COLUMNS, from_row};
use crate::query::{Field, Place, Query, Term, Word};
use crate::{AccountId, FolderId, Message, MessageRef, Result, Sort, SortField, Store};

/// Which messages of the list are shown, whatever words are searched for
#[derive(Debug, Clone, Copy, PartialEq, Eq, Default)]
pub enum Show {
    #[default]
    All,
    Unread,
    Flagged,
    WithAttachments,
}

/// The folders the message list shows
#[derive(Debug, Clone, Copy, PartialEq, Eq, Default)]
pub enum Scope {
    /// One folder
    Folder(FolderId),
    /// The Inbox of every account
    AllInboxes,
    /// Every folder of every account
    #[default]
    Everywhere,
}

/// The Inbox of every account, as SQL
pub(crate) const INBOXES: &str = "SELECT id FROM folders WHERE path = 'INBOX' COLLATE NOCASE";

/// What the message list shows
#[derive(Debug, Clone, PartialEq, Eq, Default)]
pub struct Search {
    pub scope: Scope,
    pub show: Show,
    /// The words searched for, as typed; empty for none
    pub text: String,
    /// Grouped by conversation, with these conversations expanded (any number, see `selection::id_list`); None for one
    /// row a message
    pub threads: Option<Vec<i64>>,
    /// View > Hide Ignored Conversations: the messages of ignored conversations left out
    pub hide_ignored: bool,
    /// With `show` Unread, the messages read since this time (milliseconds since the epoch) stay in the list: those read
    /// since the list was turned to unread only, so a message does not leave it the moment it is read
    pub read_since: Option<i64>,
}

/// A word as FTS5 reads it, and nothing else: quoted (its own quotes dropped, so no FTS5 syntax can be typed), in its
/// column, matched at the start of a word so that results come while typing (a phrase: its last word whole). None when
/// it has no word in it (only punctuation).
fn fts_word(word: &Word) -> Option<String> {
    let text = word.text.replace('"', "");
    if !text.chars().any(char::is_alphanumeric) {
        return None;
    }
    let column = match word.field {
        Field::Any => "",
        Field::Subject => "subject : ",
        Field::From => "senders : ",
        Field::To => "recipients : ",
        Field::Filename => "attachments : ",
    };
    // a word of one letter is matched whole: as the start of words it would match nearly every message, and the
    // first letter typed would make the search read them all
    let prefix = if word.phrase || text.chars().count() < 2 {
        ""
    } else {
        "*"
    };
    Some(format!("{column}\"{text}\"{prefix}"))
}

/// One term of words as an FTS5 query: its alternatives joined by OR; None when none of them has a word
fn fts_term(any_of: &[Word]) -> Option<String> {
    let words: Vec<String> = any_of.iter().filter_map(fts_word).collect();
    match words.len() {
        0 => None,
        1 => words.into_iter().next(),
        _ => Some(format!("({})", words.join(" OR "))),
    }
}

/// The current time, for `older_than:`
fn now() -> i64 {
    std::time::SystemTime::now()
        .duration_since(std::time::UNIX_EPOCH)
        .map_or(0, |d| d.as_secs() as i64)
}

impl Search {
    /// The whole list of a folder
    pub fn folder(folder: FolderId) -> Search {
        Search {
            scope: Scope::Folder(folder),
            ..Default::default()
        }
    }

    /// The same list, one row a message
    pub fn ungrouped(&self) -> Search {
        Search {
            threads: None,
            ..self.clone()
        }
    }

    /// The WHERE of the search and its values, ?1 on. `in_order`: for a page in an order that has an index over every
    /// folder (date, received), which then walks it rather than sort all the Inboxes have.
    /// What it finds with each message's place in the order of `sort` (from 0): `folder_id`, `uid`, `position`, as SQL
    /// to select from, with its values
    pub(crate) fn positioned(&self, sort: Sort) -> (String, Vec<Value>) {
        let (condition, values) = self.condition(false);
        let sql = format!(
            "SELECT folder_id, uid, ROW_NUMBER() OVER (ORDER BY {}) - 1 AS position FROM messages WHERE {condition}",
            sort.order_by()
        );
        (sql, values)
    }

    pub(crate) fn condition(&self, in_order: bool) -> (String, Vec<Value>) {
        let mut query = Query::parse(&self.text, now());
        // the Show choice is a term like the one typed for it
        query.terms.extend(match self.show {
            Show::All => None,
            Show::Unread if self.read_since.is_some() => None,
            Show::Unread => Some(Term::Seen(false)),
            Show::Flagged => Some(Term::Flagged(true)),
            Show::WithAttachments => Some(Term::Attachment(true)),
        });
        let mut parts: Vec<String> = Vec::new();
        let mut values: Vec<Value> = Vec::new();
        let value = |values: &mut Vec<Value>, v: Value| {
            values.push(v);
            format!("?{}", values.len())
        };
        // the folders shown, unless the search names its own (in:)
        match self.scope {
            _ if query.spans_folders() => {}
            Scope::Folder(folder) => parts.push(format!("folder_id = {}", value(&mut values, Value::Integer(folder)))),
            // the + keeps SQLite off the folder indexes, which would sort every message of the Inboxes for a page
            Scope::AllInboxes if in_order => parts.push(format!("+folder_id IN ({INBOXES})")),
            Scope::AllInboxes => parts.push(format!("folder_id IN ({INBOXES})")),
            Scope::Everywhere => {}
        }
        // unread, or read since the list was turned to unread only
        if let (Show::Unread, Some(since)) = (self.show, self.read_since) {
            parts.push(format!(
                "(seen = 0 OR seen_at >= {})",
                value(&mut values, Value::Integer(since))
            ));
        }
        let flagged = "instr(' ' || flags || ' ', ' \\Flagged ') > 0";
        let answered = "instr(' ' || flags || ' ', ' \\Answered ') > 0";
        let mut words: Vec<String> = Vec::new();
        let date = crate::messages::LIST_DATE;
        for term in &query.terms {
            match term {
                Term::Text { any_of, negated } => match (fts_term(any_of), negated) {
                    (Some(fts), false) => words.push(fts),
                    (Some(fts), true) => parts.push(format!(
                        "id NOT IN (SELECT rowid FROM messages_fts WHERE messages_fts MATCH {})",
                        value(&mut values, Value::Text(fts))
                    )),
                    // only punctuation: no word to find
                    (None, false) => parts.push("0".into()),
                    (None, true) => {}
                },
                Term::Seen(seen) => parts.push(format!("seen = {}", i64::from(*seen))),
                Term::Flagged(on) => parts.push(if *on { flagged.into() } else { format!("NOT {flagged}") }),
                Term::Answered(on) => parts.push(if *on {
                    answered.into()
                } else {
                    format!("NOT {answered}")
                }),
                Term::Attachment(on) => parts.push(format!("has_attachments = {}", i64::from(*on))),
                Term::Bounce(on) => parts.push(format!("bounce = {}", i64::from(*on))),
                Term::In { place, negated } => {
                    let folders = match place {
                        Place::Anywhere => continue,
                        Place::Inbox => INBOXES.to_string(),
                        Place::Special { special_use, name } => {
                            let special_use = value(&mut values, Value::Text(special_use.to_string()));
                            let name = value(&mut values, Value::Text(name.clone()));
                            format!(
                                "SELECT id FROM folders WHERE special_use = {special_use} OR name = {name} COLLATE NOCASE"
                            )
                        }
                        Place::Named(name) => {
                            let name = value(&mut values, Value::Text(name.clone()));
                            format!(
                                "SELECT id FROM folders WHERE name = {name} COLLATE NOCASE OR path = {name} COLLATE NOCASE"
                            )
                        }
                    };
                    let not = if *negated { "NOT " } else { "" };
                    parts.push(format!("folder_id {not}IN ({folders})"));
                }
                Term::Before(time) => parts.push(format!("{date} < {}", value(&mut values, Value::Integer(*time)))),
                Term::After(time) => parts.push(format!("{date} >= {}", value(&mut values, Value::Integer(*time)))),
                Term::Larger(size) => {
                    parts.push(format!("size > {}", value(&mut values, Value::Integer(*size as i64))))
                }
                Term::Smaller(size) => {
                    parts.push(format!("size < {}", value(&mut values, Value::Integer(*size as i64))))
                }
            }
        }
        if self.hide_ignored {
            parts.push(format!(
                "thread_id NOT IN (SELECT thread_id FROM thread_marks WHERE mark = {})",
                crate::marks::IGNORE
            ));
        }
        if !words.is_empty() {
            let matched = value(&mut values, Value::Text(words.join(" AND ")));
            parts.push(format!(
                "id IN (SELECT rowid FROM messages_fts WHERE messages_fts MATCH {matched})"
            ));
        }
        let condition = if parts.is_empty() {
            "1".to_string()
        } else {
            parts.join(" AND ")
        };
        (condition, values)
    }
}

/// What the index keeps of a message whose source was read (the core parses it): everyone it names, its files and
/// its text
#[derive(Debug, Clone, PartialEq, Eq, Default)]
pub struct IndexText {
    /// From, Sender and Reply-To; To, Cc and Bcc
    pub sender_people: String,
    pub recipient_people: String,
    /// One per line
    pub attachment_names: String,
    pub attachment_count: u32,
    pub body: String,
}

impl Store {
    /// A page of what `search` finds, in the order of `sort`
    pub fn search(&self, search: &Search, sort: Sort, offset: u64, limit: u64) -> Result<Vec<Message>> {
        if let Some(expanded) = &search.threads {
            return self.thread_rows(search, sort, expanded, offset, limit);
        }
        let in_order = matches!(sort.field, SortField::Date | SortField::Received);
        let (condition, mut values) = search.condition(in_order);
        let at = values.len();
        values.push(Value::Integer(limit as i64));
        values.push(Value::Integer(offset as i64));
        let mut statement = self.db.prepare_cached(&format!(
            "SELECT {COLUMNS} FROM messages WHERE {condition} ORDER BY {} LIMIT ?{} OFFSET ?{}",
            sort.order_by(),
            at + 1,
            at + 2
        ))?;
        statement.query_map(params_from_iter(values), from_row)?.collect()
    }

    /// The Inbox of every account, the folders [`Scope::AllInboxes`] lists
    pub fn inboxes(&self) -> Result<Vec<FolderId>> {
        let mut statement = self.db.prepare_cached(&format!("{INBOXES} ORDER BY account_id, id"))?;
        statement.query_map([], |row| row.get(0))?.collect()
    }

    /// How many messages `search` finds, and how many of them are unread, grouped by conversation or not (see
    /// [`Store::count_rows`] for the rows of the list)
    pub fn count_search(&self, search: &Search) -> Result<(u64, u64)> {
        let (condition, values) = search.condition(false);
        let mut statement = self.db.prepare_cached(&format!(
            "SELECT COUNT(*), COALESCE(SUM(NOT seen), 0) FROM messages WHERE {condition}"
        ))?;
        statement.query_row(params_from_iter(values), |row| Ok((row.get(0)?, row.get(1)?)))
    }

    /// How many rows the list of `search` has: grouped by conversation one a conversation, and under each expanded
    /// one its other messages; otherwise one a message, as [`Store::count_search`] counts
    pub fn count_rows(&self, search: &Search) -> Result<u64> {
        match &search.threads {
            Some(expanded) => self.count_thread_rows(search, expanded),
            None => Ok(self.count_search(search)?.0),
        }
    }

    /// Where the message `uid` of `folder` is in what `search` finds in the order of `sort`; None when it is not there
    pub fn search_index(&self, search: &Search, sort: Sort, folder: FolderId, uid: u64) -> Result<Option<u64>> {
        if let Some(expanded) = &search.threads {
            return self.thread_row_index(search, sort, expanded, folder, uid);
        }
        let (positioned, mut values) = search.positioned(sort);
        let at = values.len();
        values.push(Value::Integer(folder));
        values.push(Value::Integer(uid as i64));
        let mut statement = self.db.prepare_cached(&format!(
            "SELECT position FROM ({positioned}) WHERE folder_id = ?{} AND uid = ?{}",
            at + 1,
            at + 2
        ))?;
        statement
            .query_row(params_from_iter(values), |row| row.get(0))
            .optional()
    }

    /// The messages before and after message `uid` of `folder` in what `search` finds in the order of `sort`, with one
    /// pass over the list (LAG and LEAD of the ranked rows); None when the message is not in it
    #[allow(clippy::type_complexity)]
    pub fn neighbours(
        &self,
        search: &Search,
        sort: Sort,
        folder: FolderId,
        uid: u64,
    ) -> Result<Option<(Option<MessageRef>, Option<MessageRef>)>> {
        if search.threads.is_some() {
            // the rows above and below its row, read as one page from the row above (from its own at the top)
            let Some(at) = self.search_index(search, sort, folder, uid)? else {
                return Ok(None);
            };
            let rows: Vec<MessageRef> = self
                .search(search, sort, at.saturating_sub(1), if at == 0 { 2 } else { 3 })?
                .iter()
                .map(Message::at)
                .collect();
            let (before, after) = if at == 0 {
                (None, rows.get(1))
            } else {
                (rows.first(), rows.get(2))
            };
            return Ok(Some((before.copied(), after.copied())));
        }
        let (condition, mut values) = search.condition(false);
        let order = sort.order_by();
        let at = values.len();
        values.push(Value::Integer(folder));
        values.push(Value::Integer(uid as i64));
        let mut statement = self.db.prepare_cached(&format!(
            "SELECT pf, pu, nf, nu FROM (SELECT folder_id, uid, \
             LAG(folder_id) OVER w AS pf, LAG(uid) OVER w AS pu, LEAD(folder_id) OVER w AS nf, LEAD(uid) OVER w AS nu \
             FROM messages WHERE {condition} WINDOW w AS (ORDER BY {order})) WHERE folder_id = ?{} AND uid = ?{}",
            at + 1,
            at + 2
        ))?;
        let reference = |folder: Option<FolderId>, uid: Option<i64>| {
            Some(MessageRef {
                folder: folder?,
                uid: uid? as u64,
            })
        };
        statement
            .query_row(params_from_iter(values), |row| {
                Ok((reference(row.get(0)?, row.get(1)?), reference(row.get(2)?, row.get(3)?)))
            })
            .optional()
    }

    /// The first unread message after message `uid` of `folder` in what `search` finds in the order of `sort` (from the
    /// top when it is not in that list, or `uid` is 0): what Next Unread opens
    pub fn next_unread(&self, search: &Search, sort: Sort, folder: FolderId, uid: u64) -> Result<Option<MessageRef>> {
        if search.threads.is_some() {
            return self.next_unread_in_threads(search, sort, folder, uid);
        }
        if uid == 0 && search.show == Show::All {
            // from the top: the first unread one, without ranking the list
            let mut unread = search.clone();
            unread.show = Show::Unread;
            return Ok(self
                .search(&unread, sort, 0, 1)?
                .into_iter()
                .next()
                .map(|m| MessageRef {
                    folder: m.folder_id,
                    uid: m.info.uid,
                }));
        }
        let (condition, mut values) = search.condition(false);
        let order = sort.order_by();
        let at = values.len();
        values.push(Value::Integer(folder));
        values.push(Value::Integer(uid as i64));
        let mut statement = self.db.prepare_cached(&format!(
            "WITH ranked AS (SELECT folder_id, uid, seen, ROW_NUMBER() OVER (ORDER BY {order}) AS position \
             FROM messages WHERE {condition}) \
             SELECT folder_id, uid FROM ranked WHERE seen = 0 AND position > \
             COALESCE((SELECT position FROM ranked WHERE folder_id = ?{} AND uid = ?{}), 0) ORDER BY position LIMIT 1",
            at + 1,
            at + 2
        ))?;
        statement
            .query_row(params_from_iter(values), |row| {
                Ok(MessageRef {
                    folder: row.get(0)?,
                    uid: row.get::<_, i64>(1)? as u64,
                })
            })
            .optional()
    }

    /// Cached sources the index does not have the text of yet, a few at a time: (message id, source)
    pub fn sources_to_index(&self, limit: usize) -> Result<Vec<(i64, Vec<u8>)>> {
        let mut statement = self
            .db
            .prepare_cached("SELECT message_id, source FROM bodies WHERE indexed = 0 LIMIT ?1")?;
        statement
            .query_map([limit as i64], |row| Ok((row.get(0)?, row.get(1)?)))?
            .collect()
    }

    /// The index of a message with what its source says (see [`IndexText`]); the source counts as indexed
    pub fn set_indexed(&self, message: i64, text: &IndexText) -> Result<()> {
        if !text.sender_people.is_empty() || !text.recipient_people.is_empty() {
            self.db
                .prepare_cached(
                    "UPDATE messages SET sender_people = ?2, recipient_people = ?3, attachment_names = ?4, \
                 attachment_count = ?5 WHERE id = ?1",
                )?
                .execute(params![
                    message,
                    text.sender_people,
                    text.recipient_people,
                    text.attachment_names,
                    text.attachment_count
                ])?;
        }
        self.db
            .prepare_cached("DELETE FROM messages_fts WHERE rowid = ?1")?
            .execute([message])?;
        self.db.prepare_cached(
            "INSERT INTO messages_fts (rowid, subject, senders, recipients, attachments, body) \
             SELECT id, subject, CASE sender_people WHEN '' THEN from_name || ' ' || from_address ELSE sender_people END, \
             CASE recipient_people WHEN '' THEN recipients ELSE recipient_people END, attachment_names, ?2 \
             FROM messages WHERE id = ?1",
        )?
        .execute(params![message, text.body])?;
        self.db
            .prepare_cached("UPDATE bodies SET indexed = 1 WHERE message_id = ?1 AND indexed = 0")?
            .execute([message])?;
        self.db
            .prepare_cached("UPDATE messages SET text_indexed = 1 WHERE id = ?1")?
            .execute([message])?;
        Ok(())
    }

    /// Messages of an account whose text the index does not have yet, newest first: (message id, folder, UID)
    pub fn messages_to_index(&self, account: AccountId, limit: usize) -> Result<Vec<(i64, FolderId, u64)>> {
        let mut statement = self.db.prepare_cached(
            "SELECT m.id, m.folder_id, m.uid FROM messages m INDEXED BY messages_text_unindexed \
             JOIN folders f ON f.id = m.folder_id WHERE m.text_indexed = 0 AND f.account_id = ?1 \
             ORDER BY COALESCE(m.date, m.internal_date) DESC LIMIT ?2",
        )?;
        statement
            .query_map(params![account, limit as i64], |row| {
                Ok((row.get(0)?, row.get(1)?, row.get(2)?))
            })?
            .collect()
    }

    /// How many messages the index does not have the text of yet
    pub fn unindexed_count(&self) -> Result<u64> {
        self.db
            .query_row("SELECT COUNT(*) FROM messages WHERE text_indexed = 0", [], |row| {
                row.get(0)
            })
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::{AccountSettings, FolderInfo, MessageInfo};

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
        (store, folders[0].id, folders[1].id)
    }

    fn message(uid: u64, subject: &str, from: &str, flags: &[&str]) -> MessageInfo {
        MessageInfo {
            uid,
            flags: flags.iter().map(|f| f.to_string()).collect(),
            date: Some(uid as i64 * 100),
            subject: subject.into(),
            from_name: from.into(),
            from_address: format!("{}@example.com", from.to_lowercase()),
            ..Default::default()
        }
    }

    fn found(store: &Store, search: &Search) -> Vec<u64> {
        let mut uids: Vec<u64> = store
            .search(search, Sort::default(), 0, 100)
            .unwrap()
            .iter()
            .map(|m| m.info.uid)
            .collect();
        uids.sort();
        uids
    }

    fn words(folder: Option<FolderId>, text: &str) -> Search {
        Search {
            scope: folder.map_or(Scope::Everywhere, Scope::Folder),
            text: text.into(),
            ..Default::default()
        }
    }

    #[test]
    fn typed_text_can_only_be_words() {
        let word = |text: &str| Word {
            field: Field::Any,
            text: text.into(),
            phrase: false,
        };
        assert_eq!(fts_word(&word("budget")).as_deref(), Some("\"budget\"*"));
        // FTS5 syntax typed is taken as words
        assert_eq!(fts_word(&word("a\"OR\"b")).as_deref(), Some("\"aORb\"*"));
        assert_eq!(fts_word(&word("NEAR(x)")).as_deref(), Some("\"NEAR(x)\"*"));
        assert_eq!(fts_word(&word("...")), None);
        assert_eq!(fts_word(&word("a")).as_deref(), Some("\"a\""));
        let phrase = Word {
            field: Field::Subject,
            text: "q3 plans".into(),
            phrase: true,
        };
        assert_eq!(fts_word(&phrase).as_deref(), Some("subject : \"q3 plans\""));
        assert_eq!(
            fts_term(&[word("ab"), word("c")]).as_deref(),
            Some("(\"ab\"* OR \"c\")")
        );
    }

    #[test]
    fn finds_words_in_everything_indexed() {
        let (store, inbox, archive) = setup();
        let mut with_people = message(4, "Hello", "Bob", &[]);
        with_people.sender_people = "Bob bob@example.com".into();
        with_people.recipient_people = "Carol Sääsk carol@example.org Dave dave@example.net".into();
        with_people.attachment_names = "Q3 report.pdf\nphoto.jpg".into();
        with_people.attachment_count = 2;
        with_people.has_attachments = true;
        store
            .add_messages(
                inbox,
                &[
                    message(1, "Budget for 2025", "Ann", &["\\Seen"]),
                    message(2, "Lunch", "Ann", &[]),
                    message(3, "Õhtusöök", "Zed", &["\\Flagged \\Seen"]),
                    with_people,
                ],
            )
            .unwrap();
        store
            .add_messages(archive, &[message(9, "Budget, old", "Ann", &["\\Seen"])])
            .unwrap();
        let inbox_words = |text: &str| found(&store, &words(Some(inbox), text));
        // subject, sender, everyone named, file names; case and accents do not matter, words match as they start
        assert_eq!(inbox_words("budget"), [1]);
        assert_eq!(inbox_words("ANN"), [1, 2]);
        assert_eq!(inbox_words("zed@example.com"), [3]);
        assert_eq!(inbox_words("ohtu"), [3]);
        assert_eq!(inbox_words("saask"), [4]);
        assert_eq!(inbox_words("dave@example.net"), [4]);
        assert_eq!(inbox_words("report"), [4]);
        assert_eq!(inbox_words("phot"), [4]);
        // every word is needed
        assert_eq!(inbox_words("budget lunch"), [] as [u64; 0]);
        assert_eq!(inbox_words("  "), [1, 2, 3, 4]);
        assert_eq!(inbox_words("!!"), [] as [u64; 0]);
        // every folder
        assert_eq!(found(&store, &words(None, "budget")), [1, 9]);
        // the counts and the positions of the list found, which are per folder in every folder
        assert_eq!(store.count_search(&words(Some(inbox), "ann")).unwrap(), (2, 1));
        assert_eq!(store.count_search(&words(None, "budget")).unwrap(), (2, 0));
        let sort = Sort::default();
        assert_eq!(
            store.search_index(&words(None, "budget"), sort, archive, 9).unwrap(),
            Some(0)
        );
        assert_eq!(
            store.search_index(&words(None, "budget"), sort, inbox, 1).unwrap(),
            Some(1)
        );
        assert_eq!(
            store.search_index(&words(None, "budget"), sort, inbox, 2).unwrap(),
            None
        );
        // removed messages leave the index
        store.remove_messages(inbox, &[1]).unwrap();
        assert_eq!(found(&store, &words(None, "budget")), [9]);
    }

    #[test]
    fn shows_by_state() {
        let (store, inbox, archive) = setup();
        let mut files = message(4, "Files", "Bob", &["\\Seen"]);
        files.has_attachments = true;
        store
            .add_messages(
                inbox,
                &[
                    message(1, "Read", "Ann", &["\\Seen"]),
                    message(2, "Unread", "Ann", &[]),
                    message(3, "Flagged", "Ann", &["\\Flagged", "\\Seen"]),
                    files,
                ],
            )
            .unwrap();
        store
            .add_messages(archive, &[message(9, "Old unread", "Ann", &[])])
            .unwrap();
        let show = |folder: Option<FolderId>, show| {
            found(
                &store,
                &Search {
                    scope: folder.map_or(Scope::Everywhere, Scope::Folder),
                    show,
                    ..Default::default()
                },
            )
        };
        assert_eq!(show(Some(inbox), Show::All), [1, 2, 3, 4]);
        assert_eq!(show(Some(inbox), Show::Unread), [2]);
        assert_eq!(show(Some(inbox), Show::Flagged), [3]);
        assert_eq!(show(Some(inbox), Show::WithAttachments), [4]);
        assert_eq!(show(None, Show::Unread), [2, 9]);
        // with words too
        let search = Search {
            scope: Scope::Everywhere,
            show: Show::Unread,
            text: "old".into(),
            threads: None,
            hide_ignored: false,
            read_since: None,
        };
        assert_eq!(found(&store, &search), [9]);
        // a message read since: still listed with the unread ones, by the time the store noted (in milliseconds)
        let since = std::time::SystemTime::now()
            .duration_since(std::time::UNIX_EPOCH)
            .unwrap()
            .as_millis() as i64
            - 1;
        store
            .db
            .execute(
                "UPDATE messages SET seen = 1 WHERE id = (SELECT id FROM messages WHERE seen = 0 LIMIT 1)",
                [],
            )
            .unwrap();
        let kept = Search {
            scope: Scope::Everywhere,
            show: Show::Unread,
            read_since: Some(since),
            ..Default::default()
        };
        assert_eq!(found(&store, &kept).len(), 2, "the one read stays");
        let later = Search {
            read_since: Some(since + 3_600_000),
            ..kept
        };
        assert_eq!(found(&store, &later).len(), 1, "read before the list began: gone");
    }

    #[test]
    fn all_inboxes_lists_every_inbox_and_nothing_else() {
        let (store, inbox, archive) = setup();
        let second = store.add_account(&AccountSettings::example("b@example.org")).unwrap();
        let folder = |path: &str| FolderInfo {
            path: path.into(),
            name: path.into(),
            selectable: true,
            ..Default::default()
        };
        store.set_folders(second, &[folder("Inbox"), folder("Sent")]).unwrap();
        let folders = store.folders(second).unwrap();
        let (inbox2, sent2) = (folders[0].id, folders[1].id);
        // dates and received dates in other orders, so the two sorts differ
        let dated = |uid: u64, date: i64, received: i64, flags: &[&str]| MessageInfo {
            date: Some(date),
            internal_date: Some(received),
            ..message(uid, "Hello", "Ann", flags)
        };
        store
            .add_messages(inbox, &[dated(1, 100, 400, &[]), dated(2, 300, 350, &["\\Seen"])])
            .unwrap();
        store.add_messages(inbox2, &[dated(7, 200, 300, &[])]).unwrap();
        store.add_messages(archive, &[dated(5, 500, 500, &[])]).unwrap();
        store.add_messages(sent2, &[dated(6, 600, 600, &["\\Seen"])]).unwrap();
        let all = Search {
            scope: Scope::AllInboxes,
            ..Default::default()
        };
        let listed = |search: &Search, field| -> Vec<u64> {
            let sort = Sort {
                field,
                ascending: false,
            };
            store
                .search(search, sort, 0, 10)
                .unwrap()
                .iter()
                .map(|m| m.info.uid)
                .collect()
        };
        assert_eq!(listed(&all, crate::SortField::Date), [2, 7, 1]);
        assert_eq!(listed(&all, crate::SortField::Received), [1, 2, 7]);
        assert_eq!(store.count_search(&all).unwrap(), (3, 2));
        assert_eq!(store.inboxes().unwrap(), [inbox, inbox2]);
        let newest = Sort {
            field: crate::SortField::Date,
            ascending: false,
        };
        assert_eq!(store.search_index(&all, newest, inbox2, 7).unwrap(), Some(1));
        assert_eq!(store.search_index(&all, newest, archive, 5).unwrap(), None);
        // by state and words in the scope
        let unread = Search {
            show: Show::Unread,
            ..all.clone()
        };
        assert_eq!(found(&store, &unread), [1, 7]);
        // a typed in: looks where it says
        let sent = Search {
            text: "in:sent".into(),
            ..all.clone()
        };
        assert_eq!(found(&store, &sent), [6]);
    }

    #[test]
    fn indexes_the_text_of_cached_sources() {
        let (store, inbox, _) = setup();
        store
            .add_messages(
                inbox,
                &[message(1, "Plans", "Ann", &[]), message(2, "Other", "Bob", &[])],
            )
            .unwrap();
        assert!(store.sources_to_index(10).unwrap().is_empty());
        store
            .set_source(inbox, 1, b"Subject: Plans\r\n\r\nthe zebra crossing")
            .unwrap();
        let pending = store.sources_to_index(10).unwrap();
        assert_eq!(pending.len(), 1);
        let id = pending[0].0;
        assert_eq!(found(&store, &words(Some(inbox), "zebra")), [] as [u64; 0]);
        let text = IndexText {
            sender_people: "Ann ann@example.com".into(),
            recipient_people: "Mallory Mõis mallory@example.com".into(),
            attachment_names: "plan.xlsx".into(),
            attachment_count: 1,
            body: "the zebra crossing".into(),
        };
        store.set_indexed(id, &text).unwrap();
        assert!(store.sources_to_index(10).unwrap().is_empty());
        assert_eq!(found(&store, &words(Some(inbox), "zebra")), [1]);
        assert_eq!(found(&store, &words(Some(inbox), "mois")), [1]);
        assert_eq!(found(&store, &words(Some(inbox), "plan.xlsx")), [1]);
        // still by its subject and sender, and the people by where they are
        assert_eq!(found(&store, &words(Some(inbox), "plans ann")), [1]);
        assert_eq!(found(&store, &words(Some(inbox), "to:mois")), [1]);
        assert_eq!(found(&store, &words(Some(inbox), "from:mois")), [] as [u64; 0]);
        let message = store.message(inbox, 1).unwrap().unwrap();
        assert_eq!(
            (message.info.attachment_count, message.info.attachment_names.as_str()),
            (1, "plan.xlsx")
        );
        // a source cached again is indexed again
        store.set_source(inbox, 1, b"Subject: Plans\r\n\r\nnew text").unwrap();
        assert_eq!(store.sources_to_index(10).unwrap().len(), 1);
    }

    #[test]
    fn texts_to_index_newest_first() {
        let (store, inbox, archive) = setup();
        let account = store.folder(inbox).unwrap().account_id;
        store
            .add_messages(inbox, &[message(1, "Old", "Ann", &[]), message(3, "New", "Ann", &[])])
            .unwrap();
        store
            .add_messages(archive, &[message(2, "Middle", "Ann", &[])])
            .unwrap();
        let uids = |store: &Store| -> Vec<u64> {
            store
                .messages_to_index(account, 10)
                .unwrap()
                .into_iter()
                .map(|(_, _, uid)| uid)
                .collect()
        };
        assert_eq!(uids(&store), [3, 2, 1]);
        assert_eq!(store.unindexed_count().unwrap(), 3);
        let (id, folder, _) = store.messages_to_index(account, 1).unwrap()[0];
        assert_eq!(folder, inbox);
        let text = IndexText {
            body: "the zebra".into(),
            ..Default::default()
        };
        store.set_indexed(id, &text).unwrap();
        assert_eq!(uids(&store), [2, 1]);
        assert_eq!(store.unindexed_count().unwrap(), 2);
        // its text found, its subject and sender still
        assert_eq!(found(&store, &words(Some(inbox), "zebra")), [3]);
        assert_eq!(found(&store, &words(Some(inbox), "new ann")), [3]);
        // another account's are not this one's
        assert!(store.messages_to_index(account + 1, 10).unwrap().is_empty());
    }

    #[test]
    fn gmail_operators() {
        let (store, inbox, archive) = setup();
        let account = store.folder(inbox).unwrap().account_id;
        let sent = FolderInfo {
            path: "Sent Items".into(),
            name: "Sent Items".into(),
            special_use: Some("\\Sent".into()),
            selectable: true,
            ..Default::default()
        };
        let infos: Vec<FolderInfo> = store
            .folders(account)
            .unwrap()
            .into_iter()
            .map(|f| f.info)
            .chain([sent])
            .collect();
        store.set_folders(account, &infos).unwrap();
        let sent = store
            .folders(account)
            .unwrap()
            .into_iter()
            .find(|f| f.info.path == "Sent Items")
            .unwrap()
            .id;
        let mut report = message(1, "Q3 report", "Ann", &["\\Seen", "\\Answered"]);
        report.recipient_people = "Bob bob@example.com".into();
        report.attachment_names = "q3-report.pdf".into();
        report.has_attachments = true;
        report.size = Some(5 * 1024 * 1024);
        report.date = Some(1_738_281_600);
        let mut lunch = message(2, "Lunch next week", "Bob", &[]);
        lunch.recipient_people = "Ann ann@example.com".into();
        lunch.size = Some(2000);
        lunch.date = Some(1_738_281_600 + 10 * 86_400);
        store.add_messages(inbox, &[report, lunch]).unwrap();
        store
            .add_messages(archive, &[message(3, "Old report", "Ann", &["\\Flagged", "\\Seen"])])
            .unwrap();
        store
            .add_messages(sent, &[message(4, "Re: lunch", "Me", &["\\Seen"])])
            .unwrap();
        let inbox_query = |text: &str| found(&store, &words(Some(inbox), text));
        assert_eq!(inbox_query("is:unread"), [2]);
        assert_eq!(inbox_query("is:read"), [1]);
        assert_eq!(inbox_query("is:answered"), [1]);
        assert_eq!(inbox_query("has:attachment"), [1]);
        assert_eq!(inbox_query("-has:attachment"), [2]);
        assert_eq!(inbox_query("from:ann"), [1]);
        assert_eq!(inbox_query("to:ann"), [2]);
        assert_eq!(inbox_query("subject:lunch"), [2]);
        assert_eq!(inbox_query("subject:report from:bob"), [] as [u64; 0]);
        assert_eq!(inbox_query("filename:pdf"), [1]);
        assert_eq!(inbox_query("report -q3"), [] as [u64; 0]);
        assert_eq!(inbox_query("q3 OR lunch"), [1, 2]);
        assert_eq!(inbox_query("\"next week\""), [2]);
        assert_eq!(inbox_query("\"week next\""), [] as [u64; 0]);
        assert_eq!(inbox_query("larger:1M"), [1]);
        assert_eq!(inbox_query("smaller:10k"), [2]);
        assert_eq!(inbox_query("before:2025/02/01"), [1]);
        assert_eq!(inbox_query("after:2025/02/01"), [2]);
        // in: looks beyond the folder shown
        assert_eq!(inbox_query("in:sent"), [4]);
        assert_eq!(inbox_query("in:archive report"), [3]);
        assert_eq!(inbox_query("in:anywhere report"), [1, 3]);
        assert_eq!(inbox_query("in:anywhere is:starred"), [3]);
        assert_eq!(inbox_query("label:\"sent items\""), [4]);
        assert_eq!(inbox_query("in:anywhere -in:inbox -in:sent"), [3]);
        // older_than counts back from now: everything here is older than a day
        assert_eq!(inbox_query("older_than:1d"), [1, 2]);
        assert_eq!(inbox_query("newer_than:1d"), [] as [u64; 0]);
    }
}
