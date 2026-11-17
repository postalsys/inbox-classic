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

/// A conversation is not ignored (View > Hide Ignored Conversations), as SQL on a row with its `thread_id`
pub(crate) fn not_ignored() -> String {
    format!(
        "thread_id NOT IN (SELECT thread_id FROM thread_marks WHERE mark = {})",
        crate::marks::IGNORE
    )
}

/// The conversations of a grouped list kept in `conversations` ([`Store::kept_conversations`])
pub(crate) struct Kept {
    /// The folders, as SQL that selects their ids, with its values
    pub folders: String,
    pub values: Vec<Value>,
    /// Of several accounts (All Inboxes)
    several: bool,
    hide_ignored: bool,
}

impl Kept {
    /// Its rows in `conversations`, as a WHERE. `in_order`: for a page of a list of several folders, which then walks
    /// the order's index over every folder rather than sort theirs (the + keeps SQLite off the folder's indexes).
    pub fn condition(&self, in_order: bool) -> String {
        let plus = if self.several && in_order { "+" } else { "" };
        let mut condition = format!("{plus}folder_id IN ({})", self.folders);
        if self.hide_ignored {
            condition.push_str(" AND ");
            condition.push_str(&not_ignored());
        }
        condition
    }
}

impl Search {
    /// The folders the search lists whole, as SQL that selects their ids (its values added to `values`): no words, no
    /// messages picked by UID or bound by Select All; every message shown, or with `unread` their unread ones too
    /// ([`Show::Unread`]). None when it lists only some of their messages (the Flagged folder is one: its messages are
    /// flagged ones of many folders).
    pub(crate) fn whole_folders(&self, unread: bool, values: &mut Vec<Value>) -> Option<String> {
        let shown = self.show == Show::All || (unread && self.show == Show::Unread);
        #[cfg(test)]
        if RECOUNT.with(std::cell::Cell::get) {
            return None;
        }
        if !shown || self.uids.is_some() || self.up_to.is_some() || !Query::parse(&self.text, 0).terms.is_empty() {
            return None;
        }
        Some(match self.scope {
            Scope::Folder(folder) => {
                values.push(Value::Integer(folder));
                format!("?{}", values.len())
            }
            Scope::AllInboxes => INBOXES.to_string(),
            Scope::AllSent => SENT.to_string(),
            Scope::AllDrafts => DRAFTS.to_string(),
            Scope::Everywhere => "SELECT id FROM folders".to_string(),
            Scope::Flagged => return None,
        })
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
        let mut values = Vec::new();
        let Some(folders) = search.whole_folders(true, &mut values) else {
            return Ok(None);
        };
        let ignored = if search.hide_ignored {
            format!(" AND {}", not_ignored())
        } else {
            String::new()
        };
        let sql = if search.hide_ignored {
            // the ignored conversations' messages left out
            format!(
                "SELECT COALESCE(SUM(total), 0), COALESCE(SUM(unread), 0) FROM conversations \
                 WHERE folder_id IN ({folders}){ignored}"
            )
        } else {
            format!("SELECT COALESCE(SUM(total), 0), COALESCE(SUM(unread), 0) FROM folders WHERE id IN ({folders})")
        };
        let (total, unread): (u64, u64) = self
            .db
            .prepare_cached(&sql)?
            .query_row(params_from_iter(&values), |row| Ok((row.get(0)?, row.get(1)?)))?;
        if search.show == Show::All {
            return Ok(Some((total, unread)));
        }
        let Some(since) = search.read_since else {
            return Ok(Some((unread, unread)));
        };
        values.push(Value::Integer(since));
        let read: u64 = self
            .db
            .prepare_cached(&format!(
                // found by when they were read (the + keeps SQLite on that index)
                "SELECT COUNT(*) FROM messages WHERE seen_at >= ?{} AND seen = 1 AND +folder_id IN ({folders}){ignored}",
                values.len()
            ))?
            .query_row(params_from_iter(values), |row| row.get(0))?;
        Ok(Some((unread + read, unread)))
    }

    /// The conversations kept for the list `search` makes grouped ([`Kept`]): for a list of whole folders
    /// ([`Search::whole_folders`]) of which no two are of one account, so that each conversation of the list has one
    /// row there (an account's conversations span its folders)
    pub(crate) fn kept_conversations(&self, search: &Search) -> Result<Option<Kept>> {
        let mut values = Vec::new();
        let Some(folders) = search.whole_folders(false, &mut values) else {
            return Ok(None);
        };
        let several = !matches!(search.scope, Scope::Folder(_));
        if several {
            let apart: bool = self
                .db
                .prepare_cached(&format!(
                    "SELECT COUNT(*) = COUNT(DISTINCT account_id) FROM folders WHERE id IN ({folders})"
                ))?
                .query_row(params_from_iter(&values), |row| row.get(0))?;
            if !apart {
                return Ok(None);
            }
        }
        Ok(Some(Kept {
            folders,
            values,
            several,
            hide_ignored: search.hide_ignored,
        }))
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
        let mut values = Vec::new();
        let Some(folders) = search.whole_folders(false, &mut values) else {
            return Ok(None);
        };
        let ignored = if search.hide_ignored {
            format!(" AND c.{}", not_ignored())
        } else {
            String::new()
        };
        let mut summaries: Vec<FolderSummary> = self
            .db
            .prepare_cached(&format!(
                "SELECT c.folder_id, SUM(c.total), SUM(c.unread), SUM(c.flagged) FROM conversations c \
                 WHERE c.folder_id IN ({folders}){ignored} GROUP BY c.folder_id ORDER BY c.folder_id"
            ))?
            .query_map(params_from_iter(&values), |row| {
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
                 WHERE c.folder_id IN ({folders}){ignored} GROUP BY c.folder_id",
                watch = crate::marks::WATCH,
                ignore = crate::marks::IGNORE,
            ))?
            .query_map(params_from_iter(&values), |row| {
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
