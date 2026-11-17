//! The counts that do not grow with the store. Each folder keeps how many messages it has, how many of them are unread
//! and flagged, and how many conversations; each conversation of a folder keeps a row of its own (`conversations`:
//! its messages there, unread and flagged, its newest dates and its first message). The schema's triggers keep both
//! as messages come, change and go, whoever writes them. A list of whole folders (no words, every message shown) is
//! counted from them, and grouped from them, without reading its messages; a search or a Show choice still reads the
//! messages it finds.

use std::collections::HashMap;

use rusqlite::params_from_iter;
use rusqlite::types::Value;

use crate::query::Query;
use crate::search::{DRAFTS, INBOXES, SENT};
use crate::selection::FolderSummary;
use crate::{FolderId, Result, Scope, Search, Show, Store};

#[cfg(test)]
thread_local! {
    /// Set by the tests that compare what is kept with what the messages say: every list read from its messages
    pub(crate) static RECOUNT: std::cell::Cell<bool> = const { std::cell::Cell::new(false) };
}

/// A conversation is not ignored (View > Hide Ignored Conversations), as SQL on a row (`row`: its table's alias and a
/// dot, or empty) with its `thread_id`
fn not_ignored(row: &str) -> String {
    format!(
        "{row}thread_id NOT IN (SELECT thread_id FROM thread_marks WHERE mark = {})",
        crate::marks::IGNORE
    )
}

impl Scope {
    /// A page of this list walks the order's index over every folder rather than sort what the indexes of its folders
    /// find (a `+` keeps SQLite off them): All Inboxes, which holds most of the mail
    pub(crate) fn walks_every_folder(self) -> bool {
        self == Scope::AllInboxes
    }

    /// Each conversation of the list is in one of its folders, so the conversations kept are its conversations: one
    /// folder, or the Inbox of each account (an account's conversations span its folders, and every folder lists none
    /// of them whole; an account with two Sent folders is not ruled out, so All Sent and All Drafts group what they
    /// find)
    fn groups_kept(self) -> bool {
        matches!(self, Scope::Folder(_) | Scope::AllInboxes)
    }
}

/// The whole folders a list shows ([`Search::kept`]): what each keeps counts it, and its conversations' rows there
pub(crate) struct Kept {
    /// The folders, as SQL that selects their ids, with its values
    pub folders: String,
    pub values: Vec<Value>,
    scope: Scope,
    hide_ignored: bool,
}

impl Kept {
    /// Its rows in `conversations`, as a WHERE. `in_order`: for a page, which walks the order's index
    /// ([`Scope::walks_every_folder`]).
    pub fn condition(&self, in_order: bool) -> String {
        self.condition_of("", in_order)
    }

    /// [`Kept::condition`] of a table named `row` (an alias and a dot)
    fn condition_of(&self, row: &str, in_order: bool) -> String {
        let plus = if in_order && self.scope.walks_every_folder() {
            "+"
        } else {
            ""
        };
        let mut condition = format!("{plus}{row}folder_id IN ({})", self.folders);
        if self.hide_ignored {
            condition.push_str(" AND ");
            condition.push_str(&not_ignored(row));
        }
        condition
    }

    /// Its rows of the conversations `threads`, as a WHERE with its values
    pub fn of_threads(&self, threads: &[i64]) -> (String, Vec<Value>) {
        let mut values = self.values.clone();
        let marks = crate::selection::id_list(&mut values, threads);
        (format!("{} AND thread_id IN ({marks})", self.condition(false)), values)
    }
}

impl Search {
    /// The whole folders the search lists ([`Kept`]): no words, no messages picked by UID or bound by Select All;
    /// every message shown, or with `unread` their unread ones too ([`Show::Unread`]). None when it lists only some of
    /// their messages (the Flagged folder is one: its messages are flagged ones of many folders).
    pub(crate) fn kept(&self, unread: bool) -> Option<Kept> {
        #[cfg(test)]
        if RECOUNT.with(std::cell::Cell::get) {
            return None;
        }
        let shown = self.show == Show::All || (unread && self.show == Show::Unread);
        if !shown || self.uids.is_some() || self.up_to.is_some() || !Query::parse(&self.text, 0).terms.is_empty() {
            return None;
        }
        let mut values = Vec::new();
        let folders = match self.scope {
            Scope::Folder(folder) => {
                values.push(Value::Integer(folder));
                "?1".to_string()
            }
            Scope::AllInboxes => INBOXES.to_string(),
            Scope::AllSent => SENT.to_string(),
            Scope::AllDrafts => DRAFTS.to_string(),
            Scope::Everywhere => "SELECT id FROM folders".to_string(),
            Scope::Flagged => return None,
        };
        Some(Kept {
            folders,
            values,
            scope: self.scope,
            hide_ignored: self.hide_ignored,
        })
    }

    /// The conversations kept for the list this makes grouped: those of whole folders whose conversations are each in
    /// one of them ([`Scope::groups_kept`])
    pub(crate) fn kept_conversations(&self) -> Option<Kept> {
        self.kept(false).filter(|kept| kept.scope.groups_kept())
    }
}

impl Store {
    /// `search` without Select All's bound ([`Search::up_to`]) when nothing it finds was stored after it: the same
    /// messages, which the counts kept then count
    pub(crate) fn unbounded(&self, search: &Search) -> Result<Option<Search>> {
        match search.up_to {
            Some(up_to) if !self.found_after(search, up_to)? => Ok(Some(Search {
                up_to: None,
                ..search.clone()
            })),
            _ => Ok(None),
        }
    }

    /// [`Store::count_search`] of a list of whole folders, from what the folders keep: None for another list. Their
    /// unread messages alone ([`Show::Unread`]) are counted so too, with those read since the list began
    /// ([`Search::read_since`]) found by when they were read.
    pub(crate) fn count_kept(&self, search: &Search) -> Result<Option<(u64, u64)>> {
        if let Some(unbounded) = self.unbounded(search)? {
            return self.count_kept(&unbounded);
        }
        let Some(kept) = search.kept(true) else {
            return Ok(None);
        };
        let sql = if search.hide_ignored {
            // the ignored conversations' messages left out
            format!(
                "SELECT COALESCE(SUM(total), 0), COALESCE(SUM(unread), 0) FROM conversations WHERE {}",
                kept.condition(false)
            )
        } else {
            format!(
                "SELECT COALESCE(SUM(total), 0), COALESCE(SUM(unread), 0) FROM folders WHERE id IN ({})",
                kept.folders
            )
        };
        let (total, unread): (u64, u64) = self
            .db
            .prepare_cached(&sql)?
            .query_row(params_from_iter(&kept.values), |row| Ok((row.get(0)?, row.get(1)?)))?;
        if search.show == Show::All {
            return Ok(Some((total, unread)));
        }
        let Some(since) = search.read_since else {
            return Ok(Some((unread, unread)));
        };
        let mut values = kept.values.clone();
        values.push(Value::Integer(since));
        let read: u64 = self
            .db
            .prepare_cached(&format!(
                // found by when they were read (the + keeps SQLite on that index)
                "SELECT COUNT(*) FROM messages WHERE seen_at >= ?{} AND seen = 1 AND +{}",
                values.len(),
                kept.condition(false)
            ))?
            .query_row(params_from_iter(values), |row| row.get(0))?;
        Ok(Some((unread + read, unread)))
    }

    /// How many conversations `kept` has: each folder counts its own, unless the ignored ones are left out
    pub(crate) fn count_kept_conversations(&self, kept: &Kept) -> Result<u64> {
        let sql = if kept.hide_ignored {
            format!("SELECT COUNT(*) FROM conversations WHERE {}", kept.condition(false))
        } else {
            format!(
                "SELECT COALESCE(SUM(threads), 0) FROM folders WHERE id IN ({})",
                kept.folders
            )
        };
        self.db
            .prepare_cached(&sql)?
            .query_row(params_from_iter(&kept.values), |row| row.get(0))
    }

    /// [`Store::search_summary`] of a list of whole folders, from their conversations: None for another list
    pub(crate) fn summary_kept(&self, search: &Search) -> Result<Option<Vec<FolderSummary>>> {
        if let Some(unbounded) = self.unbounded(search)? {
            return self.summary_kept(&unbounded);
        }
        let Some(kept) = search.kept(false) else {
            return Ok(None);
        };
        let mut summaries: Vec<FolderSummary> = self
            .db
            .prepare_cached(&format!(
                "SELECT c.folder_id, SUM(c.total), SUM(c.unread), SUM(c.flagged) FROM conversations c \
                 WHERE {} GROUP BY c.folder_id ORDER BY c.folder_id",
                kept.condition_of("c.", false)
            ))?
            .query_map(params_from_iter(&kept.values), |row| {
                Ok(FolderSummary {
                    folder: row.get(0)?,
                    count: row.get(1)?,
                    unread: row.get(2)?,
                    flagged: row.get(3)?,
                    ..FolderSummary::default()
                })
            })?
            .collect::<Result<_>>()?;
        // the marked conversations, few, each looked up in the folders
        let marked: HashMap<FolderId, (u64, u64)> = self
            .db
            .prepare_cached(&format!(
                "SELECT c.folder_id, SUM(c.total * (t.mark = {watch})), SUM(c.total * (t.mark = {ignore})) \
                 FROM thread_marks t CROSS JOIN conversations c ON c.thread_id = t.thread_id \
                 WHERE {} GROUP BY c.folder_id",
                kept.condition_of("c.", false),
                watch = crate::marks::WATCH,
                ignore = crate::marks::IGNORE,
            ))?
            .query_map(params_from_iter(&kept.values), |row| {
                Ok((row.get(0)?, (row.get(1)?, row.get(2)?)))
            })?
            .collect::<Result<_>>()?;
        for summary in &mut summaries {
            (summary.watched, summary.ignored) = marked.get(&summary.folder).copied().unwrap_or_default();
        }
        Ok(Some(summaries))
    }

    /// How many flagged messages the Flagged folder lists ([`Scope::Flagged`]), from what the folders keep
    pub fn flagged_count(&self) -> Result<u64> {
        self.db
            .prepare_cached(&format!(
                "SELECT COALESCE(SUM(flagged), 0) FROM folders WHERE id IN ({})",
                crate::search::FLAGGED_FROM
            ))?
            .query_row([], |row| row.get(0))
    }

    /// How many messages are unread in the Inboxes of all accounts, for the tray and the taskbar
    pub fn inbox_unread(&self) -> Result<u64> {
        self.db
            .prepare_cached(&format!(
                "SELECT COALESCE(SUM(unread), 0) FROM folders WHERE id IN ({INBOXES})"
            ))?
            .query_row([], |row| row.get(0))
    }
}
