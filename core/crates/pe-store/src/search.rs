//! Searching the message list: by folder or in every folder, by state (unread, flagged, with files) and by what is
//! typed (see [`crate::query`], Gmail's syntax) in the full-text index (`messages_fts`, FTS5): subject, senders,
//! recipients, file names and its text (from its text part, fetched for the index, or from its cached source).

use rusqlite::types::Value;
use rusqlite::{OptionalExtension, params, params_from_iter};

use crate::keyset::{Cursor, Order, Rows, Walk};
use crate::messages::{COLUMNS, from_row};
use crate::query::{Field, Place, Query, Term, Word};
use crate::{AccountId, FolderId, Message, MessageRef, Result, Sort, SortField, Store};

/// Where a page is read from rather than counted from the top of the list ([`Store::search_from`]): a row next to it
/// in the list read before, the store unchanged since, or the end of the list
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum Anchor {
    /// The row just above the page
    Above(MessageRef),
    /// The row just below it
    Below(MessageRef),
    /// The end of the list, which has this many rows
    End(u64),
}

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
    /// The Sent Items of every account (the folders the server marks \Sent)
    AllSent,
    /// The Drafts of every account (the folders the server marks \Drafts)
    AllDrafts,
    /// Every folder of every account
    #[default]
    Everywhere,
    /// The flagged messages of every account, but those in Deleted Items or Junk E-mail; from an account with a folder
    /// of its flagged messages (Gmail's Starred) that folder's, so each is there once, archived ones too
    Flagged,
}

impl Scope {
    /// The folders an All list gathers from every account, as SQL: All Inboxes', All Sent's, All Drafts'
    fn gathered(self) -> Option<&'static str> {
        match self {
            Scope::AllInboxes => Some(INBOXES),
            Scope::AllSent => Some(SENT),
            Scope::AllDrafts => Some(DRAFTS),
            _ => None,
        }
    }

    /// Whether the list of an All row (All Inboxes, All Sent, All Drafts) holds the messages of `folder`: the rule its
    /// SQL has, for the folder list and a message's window to follow
    pub fn includes(self, folder: &crate::FolderInfo) -> bool {
        match self {
            Scope::AllInboxes => folder.path.eq_ignore_ascii_case("INBOX"),
            Scope::AllSent => folder.special_use.as_deref() == Some("\\Sent"),
            Scope::AllDrafts => folder.special_use.as_deref() == Some("\\Drafts"),
            _ => false,
        }
    }
}

/// The Inbox of every account, as SQL
pub(crate) const INBOXES: &str = "SELECT id FROM folders WHERE path = 'INBOX' COLLATE NOCASE";

/// The Sent Items of every account, as SQL
pub(crate) const SENT: &str = "SELECT id FROM folders WHERE special_use = '\\Sent'";

/// The Drafts of every account, as SQL
pub(crate) const DRAFTS: &str = "SELECT id FROM folders WHERE special_use = '\\Drafts'";

/// A message is flagged, as SQL; the same words as the index `messages_flagged`, so SQLite can use it
const IS_FLAGGED: &str = is_flagged!("");

/// The folders whose flagged messages [`Scope::Flagged`] lists: of an account with a folder of its flagged messages
/// (Gmail's Starred, \Flagged) that one alone, as the others hold the same messages again; of any other account every
/// folder but what was thrown away, junk and all mail
pub(crate) const FLAGGED_FROM: &str = "SELECT id FROM folders f WHERE CASE \
     WHEN EXISTS (SELECT 1 FROM folders s WHERE s.account_id = f.account_id AND s.special_use = '\\Flagged') \
     THEN f.special_use = '\\Flagged' \
     ELSE COALESCE(f.special_use, '') NOT IN ('\\Trash', '\\Junk', '\\All') END";

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
    /// Only these messages of the folder of `scope` (the new mail a message rule looks at); None for all
    pub uids: Option<Vec<u64>>,
    /// With `show` Unread, the messages read since this time (milliseconds since the epoch) stay in the list: those read
    /// since the list was turned to unread only, so a message does not leave it the moment it is read
    pub read_since: Option<i64>,
    /// Only the messages stored up to this one ([`Store::newest_message`]): Select All's, which acts on what was there
    /// when it was chosen, never on mail stored after it. None for all.
    pub up_to: Option<i64>,
    /// Leaves out the messages whose text in the index came from decrypting them when it looks for words: an agent's
    /// search never matches what only the user can read (its other terms, such as `is:encrypted`, still find them)
    pub no_decrypted: bool,
    /// Only the messages of these accounts (those an AI agent may use, which can be some only); None for every account
    pub accounts: Option<Vec<AccountId>>,
}

/// A word as FTS5 reads it, and nothing else: quoted (its own quotes dropped, so no FTS5 syntax can be typed), in its
/// column, matched at the start of a word so that results come while typing (a phrase: its last word whole). Segmented
/// as the index is ([`crate::fold::segment`]): characters of words without spaces (会议) a phrase of each (`"会 议"`),
/// which finds them next to each other inside any longer word. None when it has no word in it (only punctuation).
fn fts_word(word: &Word) -> Option<String> {
    // the quotes dropped after segmenting, which writes a full width quote as one; and NUL, where FTS5 reads the
    // query as ending, inside the quotes
    let text = crate::fold::indexed(&word.text).replace(['"', '\0'], "");
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
    // first letter typed would make the search read them all. So is one ending in a character segmented, which is a
    // whole word of the index.
    let ends_segmented = text.chars().next_back().is_some_and(crate::fold::is_segmented);
    let prefix = if word.phrase || ends_segmented || text.chars().count() < 2 {
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

/// The subject, senders, recipients and file names of a message as the search index has them, of the row `row`
/// (`new.` in the schema's trigger, empty in a SELECT): ı as i, which unicode61 does not fold, and `segmented`
/// ([`crate::fold::segment`]) when the store writes them. The schema's trigger does not segment: a function of ours
/// there would fail every write of an older version, which has none; the store segments what it stored after it
/// ([`Store::add_messages`]).
pub(crate) fn fts_columns(row: &str, segmented: bool) -> String {
    [
        format!("{row}subject"),
        format!("CASE {row}sender_people WHEN '' THEN {row}from_name || ' ' || {row}from_address ELSE {row}sender_people END"),
        format!("CASE {row}recipient_people WHEN '' THEN {row}recipients ELSE {row}recipient_people END"),
        format!("{row}attachment_names"),
    ]
    .iter()
    .map(|column| {
        let dotless = format!("replace({column}, 'ı', 'i')");
        if segmented { format!("segment({dotless})") } else { dotless }
    })
    .collect::<Vec<_>>()
    .join(", ")
}

/// Whether a page in the order of `sort` walks an index of every folder (date, received, sender, subject) for a list of
/// several folders, rather than sort what the folder indexes find ([`Search::condition`] `in_order`)
pub(crate) fn walks_index(sort: Sort) -> bool {
    matches!(
        sort.field,
        SortField::Date | SortField::Received | SortField::From | SortField::Subject
    )
}

/// The messages `search` finds, one row each, as keyset.rs reads them (`in_order` as for a page, see
/// [`Search::condition`])
fn message_rows(search: &Search, in_order: bool) -> Rows {
    let (condition, values) = search.condition(in_order);
    Rows {
        with: String::new(),
        from: "messages".into(),
        condition,
        values,
    }
}

/// The message of a row of `folder_id, uid`
fn message_ref(row: &rusqlite::Row) -> rusqlite::Result<MessageRef> {
    Ok(MessageRef {
        folder: row.get(0)?,
        uid: row.get::<_, i64>(1)? as u64,
    })
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

    /// Whether a message's place is counted on the order's index ([`crate::keyset`]): not in the Flagged folder, whose
    /// few messages its own index finds, ranked faster than the order's index ranges over every folder's (walking from
    /// a message to its neighbours or a page stops at the first few, and stays on the order's index there too)
    pub(crate) fn places_by_key(&self) -> bool {
        self.scope != Scope::Flagged
    }

    /// The same list, one row a message
    pub fn ungrouped(&self) -> Search {
        Search {
            threads: None,
            ..self.clone()
        }
    }

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

    /// The WHERE of the search and its values, ?1 on. `in_order`: for a page in an order that has an index over every
    /// folder ([`walks_index`]), which then walks it rather than sort all the Inboxes have.
    pub(crate) fn condition(&self, in_order: bool) -> (String, Vec<Value>) {
        self.condition_with(in_order, true)
    }

    /// [`Search::condition`] for a query that reads the messages of some conversations (`thread_id IN (...)`): the
    /// words searched for checked on each of their messages, never an index SQLite combines with the conversations',
    /// which would look up every message found for every conversation (a search with every conversation open took
    /// seconds)
    pub(crate) fn condition_of_threads(&self) -> (String, Vec<Value>) {
        self.condition_with(false, false)
    }

    /// [`Search::condition`]; `words_lead`: the messages the words find may be where SQLite starts (a search's list),
    /// otherwise only checked (`+id`)
    fn condition_with(&self, in_order: bool, words_lead: bool) -> (String, Vec<Value>) {
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
            scope @ (Scope::AllInboxes | Scope::AllSent | Scope::AllDrafts) => {
                let folders = scope.gathered().unwrap_or_default();
                // the + keeps SQLite off the folder indexes, which would sort every message of the Inboxes for a page;
                // Sent Items and Drafts hold a small part of the mail, which the folder indexes find at once
                let plus = if in_order && scope.walks_every_folder() {
                    "+"
                } else {
                    ""
                };
                parts.push(format!("{plus}folder_id IN ({folders})"));
            }
            Scope::Everywhere => {}
            Scope::Flagged => parts.push(format!("{IS_FLAGGED} AND folder_id IN ({FLAGGED_FROM})")),
        }
        if let Some(uids) = &self.uids {
            let listed: Vec<String> = uids
                .iter()
                .map(|&uid| value(&mut values, Value::Integer(uid as i64)))
                .collect();
            parts.push(if listed.is_empty() {
                "0".into()
            } else {
                format!("uid IN ({})", listed.join(", "))
            });
        }
        // the accounts' folders, whatever folders the search names
        if let Some(accounts) = &self.accounts {
            let listed: Vec<String> = accounts
                .iter()
                .map(|&account| value(&mut values, Value::Integer(account)))
                .collect();
            parts.push(if listed.is_empty() {
                "0".into()
            } else {
                format!(
                    "folder_id IN (SELECT id FROM folders WHERE account_id IN ({}))",
                    listed.join(", ")
                )
            });
        }
        // stored up to Select All's bound (the + keeps SQLite on the indexes of the list)
        if let Some(up_to) = self.up_to {
            parts.push(format!("+id <= {}", value(&mut values, Value::Integer(up_to))));
        }
        // unread, or read since the list was turned to unread only
        if let (Show::Unread, Some(since)) = (self.show, self.read_since) {
            parts.push(format!(
                "(seen = 0 OR seen_at >= {})",
                value(&mut values, Value::Integer(since))
            ));
        }
        let flagged = IS_FLAGGED;
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
                Term::Protection(level, on) => parts.push(format!(
                    "protection {} {}",
                    if *on { "=" } else { "!=" },
                    level.stored()
                )),
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
                Term::List { text, negated } => {
                    let has = format!(
                        "instr(lower(COALESCE(list_id, '')), {}) > 0",
                        value(&mut values, Value::Text(text.to_lowercase()))
                    );
                    parts.push(if *negated { format!("NOT {has}") } else { has });
                }
            }
        }
        // words looked for (or left out) would match what was decrypted: such a search passes over those messages
        let has_text = query.terms.iter().any(|term| matches!(term, Term::Text { .. }));
        if self.no_decrypted && has_text {
            parts.push("decrypted != 1".into());
        }
        if self.hide_ignored {
            parts.push(format!(
                "thread_id NOT IN (SELECT thread_id FROM thread_marks WHERE mark = {})",
                crate::marks::IGNORE
            ));
        }
        if !words.is_empty() {
            let matched = value(&mut values, Value::Text(words.join(" AND ")));
            let id = if words_lead { "id" } else { "+id" };
            parts.push(format!(
                "{id} IN (SELECT rowid FROM messages_fts WHERE messages_fts MATCH {matched})"
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
    /// The first words of what the sender wrote, for the message list (empty: the message has no text)
    pub snippet: String,
}

impl Store {
    /// A page of what `search` finds, in the order of `sort`
    pub fn search(&self, search: &Search, sort: Sort, offset: u64, limit: u64) -> Result<Vec<Message>> {
        if let Some(expanded) = &search.threads {
            return self.thread_rows(search, sort, expanded, offset, limit);
        }
        let (condition, mut values) = search.condition(walks_index(sort));
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

    /// [`Store::search`] read from `anchor` (keyset.rs): the same rows, found on the order's index from a row next to
    /// them (or from the end of the list) without going through those above them. From the top when the anchor is not
    /// in the list, or the list is grouped with conversations open or from what a search finds.
    pub fn search_from(
        &self,
        search: &Search,
        sort: Sort,
        offset: u64,
        limit: u64,
        anchor: Anchor,
    ) -> Result<Vec<Message>> {
        if let Some(expanded) = &search.threads {
            return match search.kept_conversations() {
                Some(kept) if expanded.is_empty() => self.kept_rows_from(search, &kept, sort, offset, limit, anchor),
                _ => self.search(search, sort, offset, limit),
            };
        }
        let place = |at: MessageRef| self.message_place(search, sort, at.folder, at.uid);
        let Some(walk) = Walk::from(anchor, offset, limit, place)? else {
            return self.search(search, sort, offset, limit);
        };
        let rows = message_rows(search, walks_index(sort));
        self.walk(&rows, &Order::messages(sort), &walk, COLUMNS, from_row)
    }

    /// The Inbox of every account, the folders [`Scope::AllInboxes`] lists
    pub fn inboxes(&self) -> Result<Vec<FolderId>> {
        let mut statement = self.db.prepare_cached(&format!("{INBOXES} ORDER BY account_id, id"))?;
        statement.query_map([], |row| row.get(0))?.collect()
    }

    /// The newest message stored, by its id: one stored later always has a higher id (the ids are never given
    /// again, see the `message_ids` migration), which bounds what Select All acts on ([`Search::up_to`])
    pub fn newest_message(&self) -> Result<i64> {
        self.db
            .prepare_cached("SELECT high FROM message_ids")?
            .query_row([], |row| row.get(0))
    }

    /// What `search` finds of the messages stored after the message `since` ([`Store::newest_message`]), in the order
    /// they were stored, at most `limit`: an agent's changes since its cursor. Read from those stored since, by id.
    pub fn stored_since(&self, search: &Search, since: i64, limit: u64) -> Result<Vec<Message>> {
        let (condition, mut values) = search.ungrouped().condition(false);
        values.push(Value::Integer(since));
        values.push(Value::Integer(limit as i64));
        let at = values.len();
        let mut statement = self.db.prepare_cached(&format!(
            "SELECT {COLUMNS} FROM messages WHERE id IN (SELECT id FROM messages WHERE id > ?{}) AND {condition} \
             ORDER BY id LIMIT ?{at}",
            at - 1
        ))?;
        statement.query_map(params_from_iter(values), from_row)?.collect()
    }

    /// Whether `search`, without its bound, finds a message stored after the message `id` ([`Store::newest_message`]):
    /// read from those stored since, so it takes what they are, not what the list is
    pub fn found_after(&self, search: &Search, id: i64) -> Result<bool> {
        let unbounded = Search {
            up_to: None,
            threads: None,
            ..search.clone()
        };
        let (condition, mut values) = unbounded.condition(false);
        values.push(Value::Integer(id));
        let mut statement = self.db.prepare_cached(&format!(
            "SELECT EXISTS (SELECT 1 FROM messages WHERE id IN (SELECT id FROM messages WHERE id > ?{}) AND {condition})",
            values.len()
        ))?;
        statement.query_row(params_from_iter(values), |row| row.get(0))
    }

    /// How many messages `search` finds, and how many of them are unread, grouped by conversation or not (see
    /// [`Store::count_rows`] for the rows of the list)
    pub fn count_search(&self, search: &Search) -> Result<(u64, u64)> {
        if let Some(counted) = self.count_kept(search)? {
            return Ok(counted);
        }
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
        if !search.places_by_key() {
            let (positioned, mut values) = search.positioned(sort);
            let at = values.len();
            values.push(Value::Integer(folder));
            values.push(Value::Integer(uid as i64));
            let mut statement = self.db.prepare_cached(&format!(
                "SELECT position FROM ({positioned}) WHERE folder_id = ?{} AND uid = ?{}",
                at + 1,
                at + 2
            ))?;
            return statement
                .query_row(params_from_iter(values), |row| row.get(0))
                .optional();
        }
        // the messages above it, counted on the order's index
        let Some(place) = self.message_place(search, sort, folder, uid)? else {
            return Ok(None);
        };
        let rows = message_rows(search, false);
        Ok(Some(self.count_before(&rows, &Order::messages(sort), &place)?))
    }

    /// Where the message `uid` of `folder` is in the order of `sort` ([`Cursor`]), None when `search` does not find it
    fn message_place(&self, search: &Search, sort: Sort, folder: FolderId, uid: u64) -> Result<Option<Cursor>> {
        let (condition, mut values) = search.condition(false);
        let at = values.len();
        values.push(Value::Integer(folder));
        values.push(Value::Integer(uid as i64));
        let mut statement = self.db.prepare_cached(&format!(
            "SELECT {}, uid, id FROM messages WHERE folder_id = ?{} AND uid = ?{} AND {condition}",
            crate::messages::sort_key(sort.field),
            at + 1,
            at + 2
        ))?;
        statement
            .query_row(params_from_iter(values), |row| {
                Ok(Cursor {
                    key: row.get(0)?,
                    ties: vec![row.get(1)?, row.get(2)?],
                })
            })
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
        // the nearest on each side, walking the order's index from it
        let Some(place) = self.message_place(search, sort, folder, uid)? else {
            return Ok(None);
        };
        let (rows, order) = (message_rows(search, walks_index(sort)), Order::messages(sort));
        let next = |after| -> Result<Option<MessageRef>> {
            let walk = Walk::next(place.clone(), after);
            Ok(self.walk(&rows, &order, &walk, "folder_id, uid", message_ref)?.pop())
        };
        Ok(Some((next(false)?, next(true)?)))
    }

    /// The first unread message after message `uid` of `folder` in what `search` finds in the order of `sort` (from the
    /// top when it is not in that list, or `uid` is 0): what Next Unread opens
    pub fn next_unread(&self, search: &Search, sort: Sort, folder: FolderId, uid: u64) -> Result<Option<MessageRef>> {
        if search.threads.is_some() {
            return self.next_unread_in_threads(search, sort, folder, uid);
        }
        let mut rows = message_rows(search, walks_index(sort));
        rows.condition.push_str(" AND seen = 0");
        match self.message_place(search, sort, folder, uid)? {
            // walking the order's index from it
            Some(place) => {
                let walk = Walk::next(place, true);
                Ok(self
                    .walk(&rows, &Order::messages(sort), &walk, "folder_id, uid", message_ref)?
                    .pop())
            }
            // from the top when it is not in the list
            None => {
                let mut statement = self.db.prepare_cached(&format!(
                    "SELECT folder_id, uid FROM messages WHERE {} ORDER BY {} LIMIT 1",
                    rows.condition,
                    sort.order_by()
                ))?;
                statement
                    .query_row(params_from_iter(rows.values), message_ref)
                    .optional()
            }
        }
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
        self.write_index_row(message, &crate::fold::indexed(&text.body))?;
        self.db
            .prepare_cached("UPDATE bodies SET indexed = 1 WHERE message_id = ?1 AND indexed = 0")?
            .execute([message])?;
        self.db
            .prepare_cached("UPDATE messages SET text_indexed = 1, snippet = ?2 WHERE id = ?1")?
            .execute(params![message, text.snippet])?;
        Ok(())
    }

    /// The bytes the search index's words take (FTS5's data blocks), for the speed test's record
    pub fn index_size(&self) -> Result<i64> {
        self.db.query_row(
            "SELECT COALESCE(SUM(length(block)), 0) FROM messages_fts_data",
            [],
            |row| row.get(0),
        )
    }

    /// The search index's row of a message just stored, its subject, people and file names segmented, which the
    /// schema's trigger wrote as they are ([`fts_columns`]); it has no text yet
    pub(crate) fn segment_stored(&self, message: i64) -> Result<()> {
        self.write_index_row(message, "")
    }

    /// The search index's row of a message written again: its columns as the message has them, and `body` as the
    /// index takes it
    fn write_index_row(&self, message: i64, body: &str) -> Result<()> {
        self.db
            .prepare_cached("DELETE FROM messages_fts WHERE rowid = ?1")?
            .execute([message])?;
        self.db
            .prepare_cached(&format!(
                "INSERT INTO messages_fts (rowid, subject, senders, recipients, attachments, body) \
                 SELECT id, {}, ?2 FROM messages WHERE id = ?1",
                fts_columns("", true)
            ))?
            .execute(params![message, body])?;
        Ok(())
    }

    /// [`Store::set_indexed`] with the text of an encrypted message, decrypted when it was opened or by the background
    /// pass: marked, so that the switch in Settings can take it out again and AI agents never search it. `subject`, its
    /// protected Subject when its layer was good, takes the place of the one it came with in the list (kept, to put
    /// back); the conversations kept follow it as any change of a subject. Nothing is written while the switch in
    /// Settings is off, read in the same transaction as the writes, so a switch turned off while the message was being
    /// decrypted leaves nothing decrypted behind (call it inside a transaction). Whether it was written.
    pub fn set_indexed_decrypted(&self, message: i64, text: &IndexText, subject: Option<&str>) -> Result<bool> {
        if !self.pgp_index_encrypted()? {
            return Ok(false);
        }
        if let Some(subject) = subject {
            // the Subject it came with is kept whatever the row says now
            self.db
                .prepare_cached(
                    "UPDATE messages SET outer_subject = COALESCE(outer_subject, subject), subject = ?2, \
                     sort_subject = ?3 WHERE id = ?1",
                )?
                .execute(params![message, subject, crate::fold::fold(subject)])?;
        }
        self.set_indexed(message, text)?;
        self.db
            .prepare_cached("UPDATE messages SET decrypted = 1 WHERE id = ?1")?
            .execute([message])?;
        Ok(true)
    }

    /// Takes the decrypted text of every encrypted message out of the index and the list (the switch in Settings
    /// turned off): each gets back the Subject it came with and is indexed again as it came, by its envelope alone,
    /// without the people and the names of the files inside. Those the background pass could not open are tried again
    /// once it is on.
    pub fn forget_decrypted(&self) -> Result<()> {
        let tx = self.db.unchecked_transaction()?;
        tx.execute(
            "UPDATE messages SET subject = outer_subject, sort_subject = fold(outer_subject), outer_subject = NULL \
             WHERE decrypted = 1 AND outer_subject IS NOT NULL",
            [],
        )?;
        tx.execute(
            "UPDATE messages SET snippet = '', sender_people = '', recipient_people = '', attachment_names = '', \
             attachment_count = 0 WHERE decrypted = 1",
            [],
        )?;
        tx.execute(
            "DELETE FROM messages_fts WHERE rowid IN (SELECT id FROM messages WHERE decrypted = 1)",
            [],
        )?;
        tx.execute(
            &format!(
                "INSERT INTO messages_fts (rowid, subject, senders, recipients, attachments, body) \
                 SELECT id, {}, '' FROM messages WHERE decrypted = 1",
                fts_columns("", true)
            ),
            [],
        )?;
        tx.execute("UPDATE messages SET decrypted = 0 WHERE decrypted != 0", [])?;
        tx.commit()
    }

    /// Whether the text of the message `uid` of `folder` should be indexed decrypted, now that it was: the user lets
    /// the index keep it (Settings), and it was not yet
    pub fn wants_decrypted_text(&self, folder: FolderId, uid: u64) -> Result<bool> {
        if !self.pgp_index_encrypted()? {
            return Ok(false);
        }
        Ok(self
            .db
            .query_row(
                "SELECT decrypted != 1 FROM messages WHERE folder_id = ?1 AND uid = ?2",
                params![folder, uid as i64],
                |row| row.get(0),
            )
            .optional()?
            .unwrap_or(false))
    }

    /// The decrypted text of the message `uid` of `folder` into the index ([`Store::set_indexed_decrypted`], in a
    /// transaction of its own); whether it was written (the message is here and the switch is on)
    pub fn index_decrypted(&self, folder: FolderId, uid: u64, text: &IndexText, subject: Option<&str>) -> Result<bool> {
        let id: Option<i64> = self
            .db
            .query_row(
                "SELECT id FROM messages WHERE folder_id = ?1 AND uid = ?2",
                params![folder, uid as i64],
                |row| row.get(0),
            )
            .optional()?;
        match id {
            Some(id) => {
                // the write lock first: the switch is read, then written by, this transaction
                let tx = rusqlite::Transaction::new_unchecked(&self.db, rusqlite::TransactionBehavior::Immediate)?;
                let written = self.set_indexed_decrypted(id, text, subject)?;
                tx.commit()?;
                Ok(written)
            }
            None => Ok(false),
        }
    }

    /// Encrypted messages of an account whose source is here and that were not decrypted for the index yet, newest
    /// first, while the user lets the index keep their text: (message id, folder, UID)
    pub fn messages_to_decrypt(&self, account: AccountId, limit: usize) -> Result<Vec<(i64, FolderId, u64)>> {
        if !self.pgp_index_encrypted()? {
            return Ok(Vec::new());
        }
        let mut statement = self.db.prepare_cached(
            "SELECT m.id, m.folder_id, m.uid FROM messages m INDEXED BY messages_to_decrypt \
             JOIN folders f ON f.id = m.folder_id WHERE m.protection = 2 AND m.decrypted = 0 AND f.account_id = ?1 \
             AND EXISTS (SELECT 1 FROM bodies b WHERE b.message_id = m.id) \
             ORDER BY COALESCE(m.date, m.internal_date) DESC LIMIT ?2",
        )?;
        statement
            .query_map(params![account, limit as i64], |row| {
                Ok((row.get(0)?, row.get(1)?, row.get(2)?))
            })?
            .collect()
    }

    /// The background pass could not open this one (no key here opens it, or the keys are not available without the
    /// user): left for when the user opens it, and not tried again until the switch in Settings is turned on again
    pub fn mark_decrypt_tried(&self, messages: &[i64]) -> Result<()> {
        if messages.is_empty() {
            return Ok(());
        }
        let mut values = Vec::new();
        let ids = crate::selection::id_list(&mut values, messages);
        self.db.execute(
            &format!("UPDATE messages SET decrypted = 2 WHERE id IN ({ids}) AND decrypted = 0"),
            rusqlite::params_from_iter(&values),
        )?;
        Ok(())
    }

    /// Which of the messages `uids` of `folder` the index does not have the text of yet (and the server has not
    /// refused): (message id, folder, UID)
    pub fn unindexed(&self, folder: FolderId, uids: &[u64]) -> Result<Vec<(i64, FolderId, u64)>> {
        let mut statement = self.db.prepare_cached(
            "SELECT id FROM messages WHERE folder_id = ?1 AND uid = ?2 AND text_indexed = 0 AND fetch_failed = 0",
        )?;
        let mut found = Vec::new();
        for &uid in uids {
            if let Some(id) = statement
                .query_row(params![folder, uid as i64], |row| row.get(0))
                .optional()?
            {
                found.push((id, folder, uid));
            }
        }
        Ok(found)
    }

    /// Messages of an account whose text the index does not have yet, newest first: (message id, folder, UID)
    pub fn messages_to_index(&self, account: AccountId, limit: usize) -> Result<Vec<(i64, FolderId, u64)>> {
        let mut statement = self.db.prepare_cached(
            "SELECT m.id, m.folder_id, m.uid FROM messages m INDEXED BY messages_text_unindexed \
             JOIN folders f ON f.id = m.folder_id WHERE m.text_indexed = 0 AND m.fetch_failed = 0 AND f.account_id = ?1 \
             ORDER BY COALESCE(m.date, m.internal_date) DESC LIMIT ?2",
        )?;
        statement
            .query_map(params![account, limit as i64], |row| {
                Ok((row.get(0)?, row.get(1)?, row.get(2)?))
            })?
            .collect()
    }

    /// Messages of an account indexed before the store kept snippets, newest first, without a cached source (those are
    /// read again where they are): (message id, folder, UID)
    pub fn messages_without_snippet(&self, account: AccountId, limit: usize) -> Result<Vec<(i64, FolderId, u64)>> {
        let mut statement = self.db.prepare_cached(
            "SELECT m.id, m.folder_id, m.uid FROM messages m INDEXED BY messages_snippet_missing \
             JOIN folders f ON f.id = m.folder_id WHERE m.snippet IS NULL AND m.text_indexed = 1 AND m.fetch_failed = 0 \
             AND f.account_id = ?1 AND NOT EXISTS (SELECT 1 FROM bodies b WHERE b.message_id = m.id) \
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
    use crate::test_support::{found, words};
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

    /// The marks of signed and encrypted mail are searched; the text decrypted from one is found by the user, never by
    /// an agent's words, and leaves the index (with the people and files inside) when the switch is turned off
    #[test]
    fn encrypted_mail_in_the_search() {
        let (store, inbox, _) = setup();
        let mut signed = message(1, "Signed", "Ann", &[]);
        signed.protection = crate::Protection::Signed;
        let mut encrypted = message(2, "Sealed", "Bob", &[]);
        encrypted.protection = crate::Protection::Encrypted;
        store
            .add_messages(inbox, &[signed, encrypted, message(3, "Plain", "Cid", &[])])
            .unwrap();
        assert_eq!(found(&store, &words(None, "is:signed")), [1]);
        assert_eq!(found(&store, &words(None, "is:encrypted")), [2]);
        assert_eq!(found(&store, &words(None, "-is:encrypted")), [1, 3]);
        assert_eq!(store.count_search(&words(Some(inbox), "is:encrypted")).unwrap().0, 1);

        let id: i64 = store
            .db
            .query_row("SELECT id FROM messages WHERE uid = 2", [], |row| row.get(0))
            .unwrap();
        assert!(store.wants_decrypted_text(inbox, 2).unwrap());
        let text = IndexText {
            sender_people: "Bob Inner".into(),
            attachment_names: "zebra.pdf".into(),
            attachment_count: 1,
            body: "the zebrafish plan".into(),
            snippet: "the zebrafish plan".into(),
            ..Default::default()
        };
        assert!(
            store
                .index_decrypted(inbox, 2, &text, Some("The zebrafish plan"))
                .unwrap()
        );
        // the protected Subject in the list, and an agent told the one it came with
        let row = |text: &str| {
            store
                .search(&words(None, text), Sort::default(), 0, 1)
                .unwrap()
                .remove(0)
        };
        let shown = row("is:encrypted");
        assert_eq!(shown.info.subject, "The zebrafish plan");
        assert_eq!(shown.info.outer_subject.as_deref(), Some("Sealed"));
        assert_eq!(found(&store, &words(None, "subject:zebrafish")), [2]);
        assert!(!store.wants_decrypted_text(inbox, 2).unwrap(), "once");
        let agent = |text: &str| Search {
            no_decrypted: true,
            ..words(None, text)
        };
        assert_eq!(found(&store, &words(None, "zebrafish")), [2]);
        assert_eq!(found(&store, &words(None, "filename:zebra")), [2]);
        assert_eq!(found(&store, &agent("zebrafish")), [] as [u64; 0]);
        assert_eq!(found(&store, &agent("-zebrafish")), [1, 3], "nor by leaving it out");
        assert_eq!(
            found(&store, &agent("is:encrypted")),
            [2],
            "its mark is no decrypted word"
        );

        store.set_pgp_index_encrypted(false).unwrap();
        store.forget_decrypted().unwrap();
        assert!(!store.wants_decrypted_text(inbox, 2).unwrap(), "off");
        assert_eq!(found(&store, &words(None, "zebrafish")), [] as [u64; 0]);
        assert_eq!(found(&store, &words(None, "filename:zebra")), [] as [u64; 0]);
        assert_eq!(
            found(&store, &words(None, "sealed bob")),
            [2],
            "its envelope is searched"
        );
        let plain = row("is:encrypted");
        assert_eq!(plain.snippet.as_deref(), Some(""));
        assert_eq!(plain.info.attachment_count, 0);
        assert_eq!(
            (plain.info.subject.as_str(), plain.info.outer_subject),
            ("Sealed", None)
        );
        let decrypted: i64 = store
            .db
            .query_row("SELECT decrypted FROM messages WHERE id = ?1", [id], |row| row.get(0))
            .unwrap();
        assert_eq!(decrypted, 0);

        // the background pass: one whose source is here, while the switch is on; one it could not open is left for
        // the user, and tried again once the switch is turned on again
        let account = store.folder(inbox).unwrap().account_id;
        store.set_pgp_index_encrypted(true).unwrap();
        assert!(
            store.messages_to_decrypt(account, 10).unwrap().is_empty(),
            "no source here"
        );
        store.set_source(inbox, 2, b"Subject: Sealed\r\n\r\n").unwrap();
        assert_eq!(store.messages_to_decrypt(account, 10).unwrap(), [(id, inbox, 2)]);
        store.mark_decrypt_tried(&[id]).unwrap();
        assert!(store.messages_to_decrypt(account, 10).unwrap().is_empty());
        assert!(
            store.wants_decrypted_text(inbox, 2).unwrap(),
            "opened by the user, it still is"
        );
        store.set_pgp_index_encrypted(false).unwrap();
        assert!(store.messages_to_decrypt(account, 10).unwrap().is_empty(), "off");
        store.forget_decrypted().unwrap();
        store.set_pgp_index_encrypted(true).unwrap();
        assert_eq!(store.messages_to_decrypt(account, 10).unwrap().len(), 1);
    }

    /// A decrypted message whose move the server refused comes back as it came: its outer Subject, nothing decrypted
    /// in it for agents to see or find, put back by the switch, and decrypted again with its outer Subject kept
    #[test]
    fn a_decrypted_message_stored_again_comes_as_it_came() {
        let (store, inbox, _) = setup();
        let mut sealed = message(1, "...", "Bob", &[]);
        sealed.protection = crate::Protection::Encrypted;
        store.add_messages(inbox, &[sealed]).unwrap();
        let text = IndexText {
            sender_people: "Inner Person".into(),
            attachment_names: "plans.pdf".into(),
            attachment_count: 1,
            body: "the zebrafish plan".into(),
            snippet: "the zebrafish plan".into(),
            ..Default::default()
        };
        assert!(
            store
                .index_decrypted(inbox, 1, &text, Some("The real subject"))
                .unwrap()
        );
        let decrypted = store.message(inbox, 1).unwrap().unwrap();
        assert_eq!(decrypted.agent_subject(), "...");
        // taken out for a move, put back when the server refused it
        store.remove_messages(inbox, &[1]).unwrap();
        store.add_messages(inbox, &[decrypted.info]).unwrap();
        let back = store.message(inbox, 1).unwrap().unwrap();
        assert_eq!(back.info.subject, "...");
        assert_eq!(back.agent_subject(), "...");
        assert!(!back.info.decrypted && back.info.sender_people.is_empty() && back.info.attachment_names.is_empty());
        let agent = |text: &str| Search {
            no_decrypted: true,
            ..words(None, text)
        };
        for word in ["zebrafish", "inner", "plans", "real"] {
            assert!(found(&store, &agent(word)).is_empty(), "{word}");
            assert!(found(&store, &words(None, word)).is_empty(), "{word}");
        }
        // decrypted again by the background pass: the outer Subject kept
        assert!(
            store
                .index_decrypted(inbox, 1, &text, Some("The real subject"))
                .unwrap()
        );
        let again = store.message(inbox, 1).unwrap().unwrap();
        assert_eq!(
            (again.info.subject.as_str(), again.agent_subject()),
            ("The real subject", "...")
        );
        // the switch off puts it back
        store.set_pgp_index_encrypted(false).unwrap();
        store.forget_decrypted().unwrap();
        let off = store.message(inbox, 1).unwrap().unwrap();
        assert_eq!((off.info.subject.as_str(), off.info.outer_subject), ("...", None));
        assert!(found(&store, &words(None, "zebrafish")).is_empty());
    }

    /// The switch turned off between decrypting a message and storing what it gave: nothing is stored
    #[test]
    fn nothing_decrypted_is_stored_once_the_switch_is_off() {
        let (store, inbox, _) = setup();
        let mut sealed = message(1, "...", "Bob", &[]);
        sealed.protection = crate::Protection::Encrypted;
        store.add_messages(inbox, &[sealed]).unwrap();
        // decrypted while it was on (the background pass's read)...
        assert_eq!(store.messages_to_decrypt(1, 10).unwrap().len(), 0, "no source");
        store.set_source(inbox, 1, b"Subject: ...\r\n\r\n").unwrap();
        let account = store.folder(inbox).unwrap().account_id;
        assert_eq!(store.messages_to_decrypt(account, 10).unwrap().len(), 1);
        let text = IndexText {
            body: "the zebrafish plan".into(),
            snippet: "the zebrafish plan".into(),
            ..Default::default()
        };
        // ...then the user turns it off before the write
        store.set_pgp_index_encrypted(false).unwrap();
        store.forget_decrypted().unwrap();
        assert!(
            !store
                .index_decrypted(inbox, 1, &text, Some("The real subject"))
                .unwrap()
        );
        let row = store.message(inbox, 1).unwrap().unwrap();
        assert_eq!((row.info.subject.as_str(), row.info.decrypted), ("...", false));
        assert!(found(&store, &words(None, "zebrafish")).is_empty());
        assert!(found(&store, &words(None, "real")).is_empty());
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
        // a NUL would end the query for FTS5 inside the quotes (found by the store_segment fuzz target)
        assert_eq!(fts_word(&word("ab\0c")).as_deref(), Some("\"abc\"*"));
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
    fn words_without_spaces_are_phrases_of_their_characters() {
        let fts = |text: &str| -> Vec<String> {
            Query::parse(text, 0)
                .terms
                .iter()
                .map(|term| match term {
                    Term::Text { any_of, negated } => {
                        format!(
                            "{}{}",
                            if *negated { "-" } else { "" },
                            fts_term(any_of).unwrap_or_default()
                        )
                    }
                    other => format!("{other:?}"),
                })
                .collect()
        };
        // a word of them a phrase of each, matched whole; one alone a plain word
        assert_eq!(fts("会议"), ["\"会 议\""]);
        assert_eq!(fts("会"), ["\"会\""]);
        assert_eq!(fts("회의"), ["\"회 의\""]);
        // mixed: the Latin end still matched as it starts, a word of its own after a space
        assert_eq!(fts("会议 report"), ["\"会 议\"", "\"report\"*"]);
        assert_eq!(fts("Q3会议rep"), ["\"Q3 会 议 rep\"*"]);
        // the full width space between words, full width letters as ASCII
        assert_eq!(fts("会议\u{3000}报告"), ["\"会 议\"", "\"报 告\""]);
        assert_eq!(fts("ＡＢＣ"), ["\"ABC\"*"]);
        // quoted, operators, negation, OR
        assert_eq!(fts("\"会议 报告\""), ["\"会 议 报 告\""]);
        assert_eq!(fts("subject:会议"), ["subject : \"会 议\""]);
        assert_eq!(fts("from:张伟"), ["senders : \"张 伟\""]);
        assert_eq!(fts("-会议"), ["-\"会 议\""]);
        assert_eq!(fts("会议 OR 打ち合わせ"), ["(\"会 议\" OR \"打 ち 合 わ せ\")"]);
        // a quote or an asterisk inside stays text: a full width quote is dropped as any quote, never closes the word
        assert_eq!(fts("会＂议"), ["\"会  议\""]);
        assert_eq!(fts("会\"OR\"议"), ["\"会 OR 议\""]);
        assert_eq!(fts("会*议"), ["\"会 * 议\""]);
        assert_eq!(fts("＂＊"), [""]);
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
            ..Default::default()
        };
        assert_eq!(found(&store, &search), [9]);
        // a message read since: still listed with the unread ones, by the time the store noted (in milliseconds)
        let since = std::time::SystemTime::now()
            .duration_since(std::time::UNIX_EPOCH)
            .unwrap()
            .as_millis() as i64
            - 100;
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
    fn flagged_lists_every_flagged_message_once_and_not_the_thrown_away() {
        let (store, inbox, archive) = setup();
        let gmail = store.add_account(&AccountSettings::example("b@gmail.com")).unwrap();
        let folder = |path: &str, special: Option<&str>| FolderInfo {
            path: path.into(),
            name: path.into(),
            special_use: special.map(str::to_string),
            selectable: true,
            ..Default::default()
        };
        store
            .set_folders(
                gmail,
                &[
                    folder("INBOX", None),
                    folder("[Gmail]/All Mail", Some("\\All")),
                    folder("[Gmail]/Starred", Some("\\Flagged")),
                    folder("[Gmail]/Trash", Some("\\Trash")),
                    folder("[Gmail]/Spam", Some("\\Junk")),
                ],
            )
            .unwrap();
        let folders = store.folders(gmail).unwrap();
        let id = |path: &str| folders.iter().find(|f| f.info.path == path).unwrap().id;
        let flagged = ["\\Flagged"];
        store
            .add_messages(
                inbox,
                &[
                    message(1, "Flagged here", "Ann", &flagged),
                    message(2, "Not flagged", "Ann", &[]),
                ],
            )
            .unwrap();
        store
            .add_messages(archive, &[message(3, "Flagged in Archive", "Ann", &flagged)])
            .unwrap();
        // on Gmail one message in its Inbox, All Mail and Starred, and one archived (All Mail and Starred): each listed
        // once, from Starred
        store
            .add_messages(id("INBOX"), &[message(4, "Starred on Gmail", "Bob", &flagged)])
            .unwrap();
        store
            .add_messages(
                id("[Gmail]/All Mail"),
                &[
                    message(40, "Starred on Gmail", "Bob", &flagged),
                    message(43, "Starred and archived", "Bob", &flagged),
                ],
            )
            .unwrap();
        store
            .add_messages(
                id("[Gmail]/Starred"),
                &[
                    message(41, "Starred on Gmail", "Bob", &flagged),
                    message(42, "Starred and archived", "Bob", &flagged),
                ],
            )
            .unwrap();
        store
            .add_messages(id("[Gmail]/Trash"), &[message(5, "Thrown away", "Bob", &flagged)])
            .unwrap();
        store
            .add_messages(id("[Gmail]/Spam"), &[message(6, "Junk", "Bob", &flagged)])
            .unwrap();
        let search = Search {
            scope: Scope::Flagged,
            ..Default::default()
        };
        assert_eq!(found(&store, &search), [1, 3, 41, 42]);
        assert_eq!(store.count_search(&search).unwrap().0, 4);
        // SQLite finds them by the index of flagged messages, not by reading every message
        let (condition, _) = search.condition(false);
        let plan: String = store
            .db
            .query_row(
                &format!("EXPLAIN QUERY PLAN SELECT COUNT(*) FROM messages WHERE {condition}"),
                [],
                |row| row.get::<_, String>(3),
            )
            .unwrap();
        assert!(plan.contains("messages_flagged"), "{plan}");
    }

    #[test]
    fn a_search_keeps_to_its_accounts() {
        let (store, inbox, archive) = setup();
        let first = store.folder(inbox).unwrap().account_id;
        let second = store.add_account(&AccountSettings::example("b@example.org")).unwrap();
        let folder = FolderInfo {
            path: "INBOX".into(),
            name: "INBOX".into(),
            selectable: true,
            ..Default::default()
        };
        store.set_folders(second, &[folder]).unwrap();
        let inbox2 = store.folders(second).unwrap()[0].id;
        store.add_messages(inbox, &[message(1, "Hello", "Ann", &[])]).unwrap();
        store.add_messages(archive, &[message(2, "Hello", "Ann", &[])]).unwrap();
        store.add_messages(inbox2, &[message(3, "Hello", "Ann", &[])]).unwrap();
        let found = |accounts: Option<Vec<AccountId>>, text: &str| -> Vec<u64> {
            let search = Search {
                text: text.into(),
                accounts: accounts.clone(),
                ..Default::default()
            };
            assert_eq!(
                store.count_search(&search).unwrap().0,
                store.search(&search, Sort::default(), 0, 10).unwrap().len() as u64,
                "{accounts:?} {text}"
            );
            let mut uids: Vec<u64> = store
                .search(&search, Sort::default(), 0, 10)
                .unwrap()
                .iter()
                .map(|m| m.info.uid)
                .collect();
            uids.sort_unstable();
            uids
        };
        assert_eq!(found(None, ""), [1, 2, 3]);
        assert_eq!(found(Some(vec![first]), ""), [1, 2]);
        assert_eq!(found(Some(vec![second]), "from:ann"), [3]);
        // a folder named does not reach past them
        assert_eq!(found(Some(vec![second]), "in:inbox"), [3]);
        assert_eq!(found(Some(vec![]), ""), Vec::<u64>::new());
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
            snippet: "the zebra crossing".into(),
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
    fn snippets_kept_and_missing_ones_found() {
        let (store, inbox, _) = setup();
        let account = store.folder(inbox).unwrap().account_id;
        store
            .add_messages(inbox, &[message(1, "Old", "Ann", &[]), message(2, "New", "Ann", &[])])
            .unwrap();
        let id = |uid| store.message(inbox, uid).unwrap().unwrap().id;
        // not read yet: no snippet, and not one to fetch again (the search fetches it first)
        assert_eq!(store.message(inbox, 1).unwrap().unwrap().snippet, None);
        assert!(store.messages_without_snippet(account, 10).unwrap().is_empty());
        let text = IndexText {
            body: "Lunch on Thursday? Ann".into(),
            snippet: "Lunch on Thursday?".into(),
            ..Default::default()
        };
        store.set_indexed(id(2), &text).unwrap();
        assert_eq!(
            store.message(inbox, 2).unwrap().unwrap().snippet.as_deref(),
            Some("Lunch on Thursday?")
        );
        // indexed before there were snippets: fetched again, unless its source is here to be read again
        store.set_indexed(id(1), &IndexText::default()).unwrap();
        assert_eq!(store.message(inbox, 1).unwrap().unwrap().snippet.as_deref(), Some(""));
        store.db.execute("UPDATE messages SET snippet = NULL", []).unwrap();
        let missing = |store: &Store| -> Vec<u64> {
            store
                .messages_without_snippet(account, 10)
                .unwrap()
                .into_iter()
                .map(|(_, _, uid)| uid)
                .collect()
        };
        assert_eq!(missing(&store), [2, 1]);
        store.set_source(inbox, 2, b"Subject: New\r\n\r\nLunch").unwrap();
        assert_eq!(missing(&store), [1]);
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
