//! What a message list shows, kept by the core: the folder (or All Inboxes), the words typed in the Find box, what
//! View > Current View shows, the order, whether it is grouped by conversation and which conversations are open, and
//! whether ignored conversations are hidden. The apps hold a [`ListView`] (through C, a `PeListView`), change it as
//! the user does, and read the list's rows, counts and places from it; the rules (the conversations closed when the
//! folder changes, Expand All, a message hidden in a collapsed conversation opened to be shown) are here once.
//!
//! Every list call builds the [`Search`] the store reads from the view, so the queries are those of [`Core::search`]
//! and its kin. What they read is kept ([`Memo`]): the counts while the store is unchanged, which a list of one row a
//! message has as its row count too, and which messages the rows of the pages shown are, which a click then selects
//! without reading the whole list again.

use std::collections::BTreeSet;
use std::sync::atomic::{AtomicU64, Ordering};
use std::sync::{Arc, Mutex};

use pe_store::{Anchor, FolderId, Generation, Message, MessageRef, RowRef, Scope, Search, Show, Sort};

use crate::{Action, Core, NextUnread, Result, Selected, Summary};

/// When a list begins, in milliseconds since the epoch, as the store notes when a message became read: a tenth of a
/// second early, as SQLite's clock (`seen_at`) can lag behind this one (on Windows by a tick of about 16 ms)
pub(crate) fn now_ms() -> i64 {
    const SLACK: i64 = 100;
    std::time::SystemTime::now()
        .duration_since(std::time::UNIX_EPOCH)
        .map_or(0, |d| d.as_millis() as i64)
        - SLACK
}

/// The pages of rows a view keeps at most ([`Memo`]): those shown and one or two around them
const KEPT_PAGES: usize = 4;

/// The waits of the three apps' lists, stated once. How long the changes to the list shown are gathered before it is
/// read again (a sync writes many in a row), in milliseconds
pub const LIST_GATHER_MS: u32 = 300;

/// How long anything the user waits for shows nothing busy, in milliseconds: a folder chosen waits this long for its
/// list before the list says "Loading..." (counted from the first click of the wait; later clicks do not start it
/// again), and a message, a reply, an attachment or an action on many messages as long before it says it is busy
pub const LIST_LOADING_MS: u32 = 400;

/// How long the Address Book's find boxes wait after the last key before they search, in milliseconds
pub const FIND_PAUSE_MS: u32 = 150;

/// How strongly the window's colour covers the rows of the list shown while the list of a folder chosen waits
/// (the rows show through at 45 percent)
pub const LIST_DIM: f64 = 0.55;

/// What a view read last, of the list it lists now (its search and order). Its counts and the pages it read answer
/// again while nothing was written to the store ([`Generation`]) in the same minute (words like `newer_than:` count
/// from now). The pages also say which messages the rows show until the list is counted again, as the apps do when
/// they read it again: a click selects what its row shows. A copy of the view starts without.
/// Shared by a view and the loads it started in the background ([`ListView::snapshot`]), which keep what they read
/// in it; `id` tells the view apart from others for its loads (the newest wins)
struct Memo {
    id: u64,
    kept: Arc<Mutex<Option<Kept>>>,
}

impl Default for Memo {
    fn default() -> Memo {
        static NEXT: AtomicU64 = AtomicU64::new(1);
        Memo {
            id: NEXT.fetch_add(1, Ordering::Relaxed),
            kept: Arc::default(),
        }
    }
}

/// What [`Memo`] keeps, and of which list
struct Kept {
    search: Search,
    sort: Sort,
    /// When the counts were read
    at: When,
    counts: Option<(u64, u64)>,
    rows: Option<u64>,
    /// The pages read since the list was last counted, the last read last
    pages: Vec<Page>,
}

/// Which messages a page of rows of the list shows (what a click on them selects), and when it was read
struct Page {
    offset: u64,
    limit: u64,
    at: When,
    rows: Vec<RowRef>,
}

/// What the store held and the minute, when something was read
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub(crate) struct When {
    generation: Generation,
    minute: i64,
}

impl Clone for Memo {
    fn clone(&self) -> Memo {
        Memo::default()
    }
}

/// Views are alike by what they list, whatever they kept
impl PartialEq for Memo {
    fn eq(&self, _: &Memo) -> bool {
        true
    }
}

impl Eq for Memo {}

impl std::fmt::Debug for Memo {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        f.write_str("Memo")
    }
}

/// Which list is read, and when
#[derive(Clone, Copy)]
struct Moment<'a> {
    search: &'a Search,
    sort: Sort,
    at: When,
}

impl Memo {
    /// `f` with what is kept of the list read at `moment`: nothing when it was another list, no counts when they were
    /// read before a write or in another minute
    fn with<T>(&self, moment: Moment, f: impl FnOnce(&mut Kept) -> T) -> T {
        let mut kept = self.kept.lock().unwrap_or_else(|e| e.into_inner());
        let same_list = kept
            .as_ref()
            .is_some_and(|k| k.sort == moment.sort && k.search == *moment.search);
        let kept = match kept.as_mut() {
            Some(k) if same_list => k,
            _ => kept.insert(Kept {
                search: moment.search.clone(),
                sort: moment.sort,
                at: moment.at,
                counts: None,
                rows: None,
                pages: Vec::new(),
            }),
        };
        if kept.at != moment.at {
            kept.at = moment.at;
            kept.counts = None;
            kept.rows = None;
        }
        f(kept)
    }
}

impl Kept {
    /// The count `field` picks, read with `read` when it is not kept; counting the list again starts its pages anew
    fn counted<T: Copy>(
        &mut self,
        field: fn(&mut Kept) -> &mut Option<T>,
        read: impl FnOnce() -> Result<T>,
    ) -> Result<T> {
        if let Some(value) = *field(self) {
            return Ok(value);
        }
        let value = read()?;
        *field(self) = Some(value);
        self.pages.clear();
        Ok(value)
    }

    /// A page read, in place of one read before from the same offset
    fn keep(&mut self, page: Page) {
        self.pages.retain(|p| (p.offset, p.limit) != (page.offset, page.limit));
        if self.pages.len() >= KEPT_PAGES {
            self.pages.remove(0);
        }
        self.pages.push(page);
    }

    /// The rows at `ranges` as the pages read show them (the last read first), None when one of them is not there.
    /// Rows past the end of the list, where the last page shorter than asked for ends, are none.
    fn rows_at(&self, ranges: &[(u64, u64)]) -> Option<Vec<RowRef>> {
        let end = self
            .pages
            .iter()
            .rev()
            .find(|p| (p.rows.len() as u64) < p.limit)
            .map_or(u64::MAX, |p| p.offset + p.rows.len() as u64);
        let mut found = Vec::new();
        for &(start, stop) in ranges {
            for at in start..stop.min(end) {
                let page = self
                    .pages
                    .iter()
                    .rev()
                    .find(|p| at >= p.offset && at - p.offset < p.rows.len() as u64)?;
                found.push(page.rows[(at - page.offset) as usize]);
            }
        }
        Some(found)
    }

    /// The row of `wanted` in the pages read at `at` (the list as it is now), the one nearest `hint` should it be in
    /// several; None when they do not have it
    fn row_near(&self, wanted: MessageRef, hint: u64, at: When) -> Option<u64> {
        self.pages
            .iter()
            .filter(|p| p.at == at)
            .flat_map(|p| (p.offset..).zip(&p.rows))
            .filter(|(_, row)| row.at == wanted)
            .map(|(index, _)| index)
            .min_by_key(|index| index.abs_diff(hint))
    }

    /// Where the page of `limit` rows at `offset` can be read from rather than counted from the top (keyset paging,
    /// see [`pe_store::Anchor`]): the row just above it or just below it in a page read at `at`, or else the end of
    /// the list when the page is nearer to it. None for the top, and for a list with conversations open, whose rows
    /// are not all of their own conversations.
    fn anchor(&self, offset: u64, limit: u64, at: When) -> Option<Anchor> {
        if offset == 0 || self.search.threads.as_ref().is_some_and(|open| !open.is_empty()) {
            return None;
        }
        let row = |index: u64| {
            self.pages
                .iter()
                .rev()
                .filter(|p| p.at == at)
                .find(|p| index >= p.offset && index - p.offset < p.rows.len() as u64)
                .map(|p| p.rows[(index - p.offset) as usize].at)
        };
        if let Some(above) = offset.checked_sub(1).and_then(row) {
            return Some(Anchor::Above(above));
        }
        if let Some(below) = row(offset + limit) {
            return Some(Anchor::Below(below));
        }
        let rows = self.rows.filter(|_| self.at == at)?;
        (offset > rows / 2).then_some(Anchor::End(rows))
    }

    /// Whether the list was counted at `at` (nothing was written since)
    fn counted_at(&self, at: When) -> bool {
        self.at == at && self.counts.is_some()
    }
}

/// A message list's view: see the module's comment
#[derive(Debug, Clone, PartialEq, Eq, Default)]
pub struct ListView {
    /// The folder, All Inboxes or every folder; None for no folder (an account's own item, which lists nothing
    /// without words)
    scope: Option<Scope>,
    /// The words searched for, as typed; empty for none
    text: String,
    show: Show,
    sort: Sort,
    /// One row a conversation, rather than one a message
    grouped: bool,
    /// View > Hide Ignored Conversations
    hide_ignored: bool,
    /// The open conversations of a grouped list
    expanded: BTreeSet<i64>,
    /// With Show Unread: when this list began (milliseconds since the epoch); the messages read since stay in it, until
    /// another folder, other words or another Show
    since: i64,
    memo: Memo,
}

impl ListView {
    /// A list of no folder, every message shown, newest first, not grouped
    pub fn new() -> ListView {
        ListView::default()
    }

    /// The folder, All Inboxes or every folder, as set (words typed search every folder whatever it is)
    pub fn scope(&self) -> Option<Scope> {
        self.scope
    }

    /// Another folder (or All Inboxes, or none): the conversations opened were the other one's, so all are closed.
    /// False when it was the one shown already.
    pub fn set_scope(&mut self, scope: Option<Scope>) -> bool {
        if self.scope == scope {
            return false;
        }
        self.scope = scope;
        self.expanded.clear();
        self.since = now_ms();
        true
    }

    /// The words searched for, as typed
    pub fn text(&self) -> &str {
        &self.text
    }

    /// Other words searched for: another list, every conversation closed. False when they are the same.
    pub fn set_text(&mut self, text: &str) -> bool {
        if self.text == text {
            return false;
        }
        self.text = text.to_string();
        self.expanded.clear();
        self.since = now_ms();
        true
    }

    /// Whether words are searched for: the list is then of every folder of every account (`in:` narrows that)
    pub fn searching(&self) -> bool {
        !self.text.is_empty()
    }

    /// Whether the list has messages of several folders: a search, All Inboxes or every folder (the lists with a
    /// Folder or Account column)
    pub fn several_folders(&self) -> bool {
        self.searching()
            || matches!(
                self.scope,
                Some(Scope::AllInboxes | Scope::AllSent | Scope::AllDrafts | Scope::Everywhere | Scope::Flagged)
            )
    }

    /// Whether it lists one folder of every account (All Inboxes, All Sent, All Drafts, no words): its place column
    /// is Account (a search's and Flagged's is Folder), naming the account alone, and a message shown from elsewhere
    /// that is in it stays in it
    pub fn gathers_accounts(&self) -> bool {
        !self.searching() && matches!(self.scope, Some(Scope::AllInboxes | Scope::AllSent | Scope::AllDrafts))
    }

    /// The folder it lists, without words: what Empty Folder, Import Messages and files dropped on the list act on;
    /// None for a list of several folders
    pub fn own_folder(&self) -> Option<pe_store::FolderId> {
        match self.scope {
            Some(Scope::Folder(folder)) if !self.searching() => Some(folder),
            _ => None,
        }
    }

    /// Whether Mark All Read applies to it: a folder's list or All Inboxes, without words
    pub fn marks_all_read(&self) -> bool {
        self.own_folder().is_some() || (!self.searching() && self.scope == Some(Scope::AllInboxes))
    }

    /// Whether the list lists anything: a folder, All Inboxes, or words; not an account's own item
    pub fn active(&self) -> bool {
        self.searching() || self.scope.is_some()
    }

    pub fn show(&self) -> Show {
        self.show
    }

    /// What the list shows by the messages' state; with Unread a message read stays until the list changes
    pub fn set_show(&mut self, show: Show) {
        if self.show != show {
            self.since = now_ms();
        }
        self.show = show;
    }

    pub fn sort(&self) -> Sort {
        self.sort
    }

    pub fn set_sort(&mut self, sort: Sort) {
        self.sort = sort;
    }

    pub fn grouped(&self) -> bool {
        self.grouped
    }

    /// Grouping by conversation turned on or off: every conversation closed. False when it was so already.
    pub fn set_grouped(&mut self, grouped: bool) -> bool {
        if self.grouped == grouped {
            return false;
        }
        self.grouped = grouped;
        self.expanded.clear();
        true
    }

    pub fn hide_ignored(&self) -> bool {
        self.hide_ignored
    }

    /// View > Hide Ignored Conversations; the open conversations stay open
    pub fn set_hide_ignored(&mut self, hide: bool) {
        self.hide_ignored = hide;
    }

    /// Whether the conversation `thread` is open
    pub fn is_expanded(&self, thread: i64) -> bool {
        self.expanded.contains(&thread)
    }

    /// The open conversations, ascending
    pub fn expanded(&self) -> impl Iterator<Item = i64> + '_ {
        self.expanded.iter().copied()
    }

    /// Opens the conversation `thread`; false when it was open, or the list is not grouped
    pub fn expand(&mut self, thread: i64) -> bool {
        self.grouped && thread != 0 && self.expanded.insert(thread)
    }

    /// Closes the conversation `thread`; false when it was not open
    pub fn collapse(&mut self, thread: i64) -> bool {
        self.expanded.remove(&thread)
    }

    /// Opens the conversation `thread` when it is closed, closes it when it is open (the + and - of its row); whether
    /// it is open now
    pub fn toggle(&mut self, thread: i64) -> bool {
        if !self.collapse(thread) {
            self.expand(thread);
        }
        self.is_expanded(thread)
    }

    /// View > Collapse All Conversations; false when none was open
    pub fn collapse_all(&mut self) -> bool {
        let changed = !self.expanded.is_empty();
        self.expanded.clear();
        changed
    }

    /// View > Expand All Conversations: every conversation of the list with more than one message there opened (the
    /// others have nothing to show under them); false when that changed nothing or the list is not grouped
    pub fn expand_all(&mut self, core: &Core) -> Result<bool> {
        if !self.grouped {
            return Ok(false);
        }
        let Some(search) = self.search() else {
            return Ok(false);
        };
        let open: BTreeSet<i64> = core.threads_with_replies(&search)?.into_iter().collect();
        if open == self.expanded {
            return Ok(false);
        }
        self.expanded = open;
        Ok(true)
    }

    /// The message `uid` of `folder` given a row of its own when it is hidden in a collapsed conversation (Next Unread
    /// and Find find those): its conversation opened. True when one was opened, and the list changed.
    pub fn reveal(&mut self, core: &Core, folder: FolderId, uid: u64) -> Result<bool> {
        let Some(search) = self.search() else {
            return Ok(false);
        };
        Ok(match core.hidden_in(&search, folder, uid)? {
            Some(thread) => self.expand(thread),
            None => false,
        })
    }

    /// The search the store reads for this list: words typed search every folder of every account, without them the
    /// folder or every Inbox. None when the list lists nothing.
    pub fn search(&self) -> Option<Search> {
        let scope = if self.searching() {
            Scope::Everywhere
        } else {
            self.scope?
        };
        Some(Search {
            scope,
            show: self.show,
            text: self.text.clone(),
            threads: self.grouped.then(|| self.expanded.iter().copied().collect()),
            hide_ignored: self.hide_ignored,
            read_since: (self.show == Show::Unread).then_some(self.since),
            uids: None,
            up_to: None,
        })
    }

    /// `f` with the search of the list, `empty` when it lists nothing
    fn listed<T>(&self, empty: T, f: impl FnOnce(&Search) -> Result<T>) -> Result<T> {
        match self.search() {
            Some(search) => f(&search),
            None => Ok(empty),
        }
    }

    /// `f` with the search of the list and the moment it is read at ([`Memo`]), `empty` when it lists nothing
    fn remembered<T>(&self, core: &Core, empty: T, f: impl FnOnce(&Search, Moment) -> Result<T>) -> Result<T> {
        let Some(search) = self.search() else {
            return Ok(empty);
        };
        let moment = Moment {
            search: &search,
            sort: self.sort,
            at: When {
                generation: core.generation()?,
                minute: now_ms() / 60_000,
            },
        };
        f(&search, moment)
    }

    /// A page of the list's rows, from `offset` on; which messages they are is kept for a click on them
    pub fn rows(&self, core: &Core, offset: u64, limit: u64) -> Result<Vec<Message>> {
        self.remembered(core, Vec::new(), |search, moment| {
            let rows = core.search(search, self.sort, offset, limit)?;
            let page = Page {
                offset,
                limit,
                at: moment.at,
                rows: rows.iter().map(RowRef::of).collect(),
            };
            self.memo.with(moment, |kept| kept.keep(page));
            Ok(rows)
        })
    }

    /// How many rows the list has: grouped, one a conversation and the other messages of the open ones; otherwise its
    /// messages, as [`ListView::counts`] has them
    pub fn row_count(&self, core: &Core) -> Result<u64> {
        if !self.grouped {
            return Ok(self.counts(core)?.0);
        }
        self.remembered(core, 0, |search, moment| {
            self.memo
                .with(moment, |kept| kept.counted(|k| &mut k.rows, || core.count_rows(search)))
        })
    }

    /// The messages of the list and how many of them are unread, for the status bar (see [`Core::count_search`])
    pub fn counts(&self, core: &Core) -> Result<(u64, u64)> {
        self.remembered(core, (0, 0), |search, moment| {
            self.memo.with(moment, |kept| {
                kept.counted(|k| &mut k.counts, || core.count_search(search))
            })
        })
    }

    /// [`ListView::counts`] and [`ListView::row_count`] together, as a list read again wants them: the messages, the
    /// unread ones and the rows
    pub fn counts_and_rows(&self, core: &Core) -> Result<(u64, u64, u64)> {
        self.remembered(core, (0, 0, 0), |search, moment| {
            self.memo.with(moment, |kept| {
                let (total, unread) = kept.counted(|k| &mut k.counts, || core.count_search(search))?;
                let rows = kept.counted(|k| &mut k.rows, || rows_of(core, search, self.grouped, total))?;
                Ok((total, unread, rows))
            })
        })
    }

    /// Whether something was written to the store since the list was last counted (or it was not counted yet): read
    /// again, it might show something else. A change the user's own command made, read again at once, does not need
    /// the reload that the change's event asks for a moment later.
    pub fn stale(&self, core: &Core) -> Result<bool> {
        self.remembered(core, false, |search, moment| {
            let kept = self.memo.kept.lock().unwrap_or_else(|e| e.into_inner());
            Ok(!kept
                .as_ref()
                .is_some_and(|k| k.sort == moment.sort && k.search == *search && k.counted_at(moment.at)))
        })
    }

    /// The row of the message `uid` of `folder` (its conversation's while that is collapsed); None when it is not in
    /// the list
    pub fn index_of(&self, core: &Core, folder: FolderId, uid: u64) -> Result<Option<u64>> {
        self.listed(None, |search| core.search_index(search, self.sort, folder, uid))
    }

    /// [`ListView::index_of`], looked for first in the rows read since the list was counted, nearest `hint` (the row
    /// the message had before the list was read again): a list read again with the message shown where it was, or a
    /// few rows lower as mail came above it, finds it without going through the whole list. Read the page with the
    /// hint's row first.
    pub fn index_of_near(&self, core: &Core, folder: FolderId, uid: u64, hint: u64) -> Result<Option<u64>> {
        let wanted = MessageRef { folder, uid };
        let near = self.remembered(core, None, |_, moment| {
            Ok(self.memo.with(moment, |kept| kept.row_near(wanted, hint, moment.at)))
        })?;
        match near {
            Some(index) => Ok(Some(index)),
            None => self.index_of(core, folder, uid),
        }
    }

    /// The messages before and after the message `uid` of `folder` (see [`Core::neighbours`])
    #[allow(clippy::type_complexity)]
    pub fn neighbours(
        &self,
        core: &Core,
        folder: FolderId,
        uid: u64,
    ) -> Result<Option<(Option<MessageRef>, Option<MessageRef>)>> {
        self.listed(None, |search| core.neighbours(search, self.sort, folder, uid))
    }

    /// One step of Next Unread from the message `uid` of `folder` (see [`Core::next_unread_step`]); nothing when the
    /// list lists nothing
    pub fn next_unread_step(&self, core: &Core, folder: FolderId, uid: u64) -> Result<NextUnread> {
        self.listed(NextUnread::None, |search| {
            core.next_unread_step(search, self.sort, folder, uid)
        })
    }

    /// The messages at the rows `ranges` (start included, end not), in the list's order: those the rows show, from the
    /// pages read since the list was last counted when they have those rows (a click on a row shown, whatever was
    /// written since), otherwise from the list as it is now
    pub fn refs_in_ranges(&self, core: &Core, ranges: &[(u64, u64)]) -> Result<Vec<MessageRef>> {
        // one row a message, the list's order whatever the order of the ranges, as the store reads them
        let mut ordered = ranges.to_vec();
        if !self.grouped {
            ordered.sort_unstable();
        }
        self.remembered(core, Vec::new(), |search, moment| {
            match self.memo.with(moment, |kept| kept.rows_at(&ordered)) {
                Some(rows) => core.refs_of_rows(search, &rows),
                None => core.refs_in_ranges(search, self.sort, ranges),
            }
        })
    }

    /// Select All: every message of the list (a collapsed conversation's too), counted, not listed: counted from what
    /// the view kept when nothing was written since it counted the list. Bound to the messages stored when it is
    /// chosen ([`Search::up_to`]): mail stored after it is neither counted nor acted on. Listed by
    /// [`Core::selected_refs`] when a command needs them.
    pub fn select_all(&self, core: &Core) -> Result<Selected> {
        let Some(search) = self.search() else {
            return Ok(Selected::default());
        };
        let (up_to, count) = self.bounded_count(core)?;
        Ok(Selected::All {
            search: Search {
                up_to: Some(up_to),
                ..search
            },
            sort: self.sort,
            count,
        })
    }

    /// The list read again with every row selected (`selected` Select All of this list): whether it still is the
    /// whole list, no message stored since in it; then `selected` is counted again with its bound (those gone since
    /// left out). Otherwise a Select All is listed, the messages it had, for the window to select where they are now,
    /// the newer ones not.
    pub fn select_all_again(&self, core: &Core, selected: &mut Selected) -> Result<bool> {
        let Selected::All { search: chosen, .. } = &*selected else {
            return Ok(false);
        };
        let before = core.generation()?;
        if self.still_all(core, chosen)? {
            let count = self.counts(core)?.0;
            if core.generation()? == before {
                *selected = Selected::All {
                    search: chosen.clone(),
                    sort: self.sort,
                    count,
                };
                return Ok(true);
            }
        }
        *selected = Selected::Listed(core.selected_refs(selected)?);
        Ok(false)
    }

    /// The newest message stored and the messages of the list, counted at the same moment: from what the view kept
    /// when nothing is written meanwhile, otherwise counted with the bound
    fn bounded_count(&self, core: &Core) -> Result<(i64, u64)> {
        for _ in 0..3 {
            let before = core.generation()?;
            let up_to = core.store().newest_message()?;
            let count = self.counts(core)?.0;
            if core.generation()? == before {
                return Ok((up_to, count));
            }
        }
        let up_to = core.store().newest_message()?;
        let search = Search {
            up_to: Some(up_to),
            ..self.search().unwrap_or_default()
        };
        Ok((up_to, core.count_search(&search)?.0))
    }

    /// Where the messages `refs` are now, ascending; those no longer in the list left out
    pub fn positions(&self, core: &Core, refs: &[MessageRef]) -> Result<Vec<u64>> {
        self.listed(Vec::new(), |search| core.positions(search, self.sort, refs))
    }

    /// The rows of the messages the last Undo brought back ([`Core::undo`]), and of those the store took back of an
    /// action the server refused, for the window to select them once its list has them: empty while none is back yet. None when something was written since the list was last counted: the
    /// rows found now could be other rows of the list shown (the messages back in the store, the list counted before
    /// them), so the list is read again first and the messages kept for then.
    pub fn restored(&self, core: &Core) -> Result<Option<Vec<u64>>> {
        self.remembered(core, Some(Vec::new()), |search, moment| {
            let counted = self
                .memo
                .kept
                .lock()
                .unwrap_or_else(|e| e.into_inner())
                .as_ref()
                .is_some_and(|k| {
                    k.sort == moment.sort
                        && k.search == *search
                        && k.counts.is_some()
                        && k.at.generation == moment.at.generation
                });
            if !counted {
                return Ok(None);
            }
            core.take_restored(|refs| {
                if refs.is_empty() {
                    return Ok(Some(Vec::new()));
                }
                let rows = core.positions(search, self.sort, refs)?;
                // a write meanwhile: the rows may already be another list's
                Ok((core.generation()? == moment.at.generation).then_some(rows))
            })
        })
    }

    /// Whether the list names whom its messages went to (see [`Core::lists_recipients`])
    pub fn lists_recipients(&self, core: &Core) -> Result<bool> {
        self.listed(false, |search| core.lists_recipients(search))
    }

    /// Whether `action` on the messages of `summary` takes them out of this list (see [`Summary::leaves_list`])
    pub fn leaves_list(&self, summary: &Summary, action: Action) -> bool {
        summary.leaves_list(action, self.hide_ignored)
    }

    /// Which view this is, for its loads in the background (a copy is another view)
    pub(crate) fn view_id(&self) -> u64 {
        self.memo.id
    }

    /// A copy of the view for a load in the background: what it reads is kept for this view too
    pub(crate) fn snapshot(&self) -> ListView {
        ListView {
            memo: Memo {
                id: self.memo.id,
                kept: self.memo.kept.clone(),
            },
            ..self.clone()
        }
    }

    /// What the store holds now and the minute, read on the windows' connection: what a load started now is kept as
    /// (a write after it makes the list stale, so it is never older than what it read)
    pub(crate) fn moment_now(core: &Core) -> Result<When> {
        Ok(When {
            generation: core.generation()?,
            minute: now_ms() / 60_000,
        })
    }

    /// Reads the list as a load does, on the connection of the thread: the counts, the row count and the page at
    /// `offset` (with `counted`; otherwise the page alone), and with `reselect` the rows to select in it
    /// ([`Reselected`]). None when `dropped` says a newer load took its place, between the steps. Kept for the view as
    /// read at `at`, as the calls of the window thread keep what they read.
    pub(crate) fn load(
        &self,
        core: &Core,
        at: When,
        offset: u64,
        counted: bool,
        reselect: Option<&Reselect>,
        dropped: &dyn Fn() -> bool,
    ) -> Result<Option<ListLoad>> {
        let mut load = ListLoad {
            offset,
            counted,
            ..ListLoad::default()
        };
        let Some(search) = self.search() else {
            return Ok(Some(load));
        };
        for attempt in 1..=READ_AGAIN {
            let before = core.generation()?;
            if counted {
                load.lists_recipients = core.lists_recipients(&search)?;
                (load.total, load.unread) = core.count_search(&search)?;
                load.rows = rows_of(core, &search, self.grouped, load.total)?;
                if dropped() {
                    return Ok(None);
                }
            }
            let moment = Moment {
                search: &search,
                sort: self.sort,
                at,
            };
            // from a row of a page read before next to it, or from the end, rather than from the top
            load.messages = match self.memo.with(moment, |kept| kept.anchor(offset, LIST_PAGE, at)) {
                Some(anchor) => core.search_from(&search, self.sort, offset, LIST_PAGE, anchor)?,
                None => core.search(&search, self.sort, offset, LIST_PAGE)?,
            };
            if dropped() {
                return Ok(None);
            }
            let page = Page {
                offset,
                limit: LIST_PAGE,
                at,
                rows: load.messages.iter().map(RowRef::of).collect(),
            };
            self.memo.with(moment, |kept| {
                if counted {
                    kept.counts = Some((load.total, load.unread));
                    kept.rows = Some(load.rows);
                    kept.pages.clear();
                }
                kept.keep(page);
            });
            let Some(reselect) = reselect else {
                break;
            };
            let found = Found {
                moment,
                rows: load.rows,
                total: load.total,
                before,
                last: attempt == READ_AGAIN,
            };
            // None: the store changed under the rows of what Undo brought back, so the list is read again
            if let Some(reselected) = self.reselect(core, &found, reselect)? {
                load.reselected = reselected;
                break;
            }
        }
        Ok(Some(load))
    }

    /// The rows to select in the list a load read (`found`) for what the window had selected ([`Reselect`]); None
    /// when what Undo brought back is in the list but the store changed since it was read
    fn reselect(&self, core: &Core, found: &Found, reselect: &Reselect) -> Result<Option<Reselected>> {
        if let Some(after) = reselect.after {
            return self.row_after(core, found, after).map(Some);
        }
        let mut selected = reselect.selected.clone();
        if let Selected::All { search: chosen, .. } = &selected {
            if self.still_all(core, chosen)? {
                return Ok(Some(Reselected {
                    how: Reselection::All,
                    selection: Selected::All {
                        search: chosen.clone(),
                        sort: self.sort,
                        count: found.total,
                    },
                    ..Reselected::default()
                }));
            }
            // no longer the whole list: the messages Select All had, found where they are now, the newer ones not
            selected = Selected::Listed(core.selected_refs(&selected)?);
        }
        if reselect.restored {
            match self.restored_rows(core, found)? {
                Back::Found(back) => return Ok(Some(back)),
                Back::Behind if !found.last => return Ok(None),
                // the last read: they are left for the next load
                Back::Behind | Back::None => {}
            }
        }
        let Selected::Listed(refs) = selected else {
            return Ok(Some(Reselected::default()));
        };
        let search = found.moment.search;
        let rows = match refs.as_slice() {
            [] => Vec::new(),
            // the message shown: looked for first in the page read, nearest the row it had
            [one] => match self.memo.with(found.moment, |kept| {
                kept.row_near(*one, reselect.hint.unwrap_or(0), found.moment.at)
            }) {
                Some(row) => vec![row],
                None => core
                    .search_index(search, self.sort, one.folder, one.uid)?
                    .into_iter()
                    .collect(),
            },
            several => core.positions(search, self.sort, several)?,
        };
        let Some(&first) = rows.first() else {
            return Ok(Some(Reselected::default()));
        };
        Ok(Some(Reselected {
            how: Reselection::Kept,
            // one message: its row seen; several stay where the list is scrolled to
            focus: (refs.len() == 1).then_some(first),
            rows,
            selection: Selected::Listed(refs),
        }))
    }

    /// The row `after` selected (where rows an action took out of the list were), the last row when the list is
    /// shorter now
    fn row_after(&self, core: &Core, found: &Found, after: u64) -> Result<Reselected> {
        let Some(last) = found.rows.checked_sub(1) else {
            return Ok(Reselected::default());
        };
        let row = after.min(last);
        let refs = core.refs_in_ranges(found.moment.search, self.sort, &[(row, row + 1)])?;
        Ok(Reselected {
            how: Reselection::After,
            rows: vec![row],
            focus: Some(row),
            selection: Selected::Listed(refs),
        })
    }

    /// The rows of what the last Undo brought back and of what the store took back of a refused action, in the list
    /// `found`: taken when they are in it (forgotten when they are not), left when the store changed since it was
    /// read
    fn restored_rows(&self, core: &Core, found: &Found) -> Result<Back> {
        let mut behind = false;
        let taken = core.take_restored(|refs| {
            if refs.is_empty() {
                return Ok(None);
            }
            let rows = core.positions(found.moment.search, self.sort, refs)?;
            if core.generation()? != found.before {
                behind = true;
                return Ok(None);
            }
            let Some(&first) = rows.first() else {
                return Ok(Some(None));
            };
            // only what this list shows: what came back elsewhere is not selected, so no command acts on it unseen
            let shown = core.store().refs_found(found.moment.search, refs)?;
            Ok(Some(Some(Reselected {
                how: Reselection::Restored,
                rows,
                focus: Some(first),
                selection: Selected::Listed(shown),
            })))
        })?;
        Ok(match taken.flatten() {
            Some(back) => Back::Found(back),
            None if behind => Back::Behind,
            None => Back::None,
        })
    }

    /// Whether the Select All `chosen` is still the whole of this list: no message stored since it in it
    fn still_all(&self, core: &Core, chosen: &Search) -> Result<bool> {
        let this_list = self.search().is_some_and(|s| {
            Search {
                up_to: None,
                ..chosen.clone()
            } == s
        });
        Ok(this_list && !core.store().found_after(chosen, chosen.up_to.unwrap_or(i64::MAX))?)
    }
}

/// The rows a list has: grouped, as the store counts them; otherwise one a message, `total`
fn rows_of(core: &Core, search: &Search, grouped: bool, total: u64) -> Result<u64> {
    match grouped {
        true => core.count_rows(search),
        false => Ok(total),
    }
}

/// How many times a load reads the list when the store changes under the rows of what Undo brought back
const READ_AGAIN: u32 = 3;

/// The list a load read, for the rows to select in it
struct Found<'a> {
    moment: Moment<'a>,
    rows: u64,
    total: u64,
    /// What the store held when it was read, on the load's connection
    before: Generation,
    /// The last read of the list: what it finds is taken
    last: bool,
}

/// What Undo brought back, in a list
enum Back {
    None,
    Found(Reselected),
    /// The store changed since the list was read
    Behind,
}

/// The rows a list load reads at a time
pub const LIST_PAGE: u64 = 100;

/// What the window has selected when it asks for its list ([`Core::list_load`]), for the load to select it again where
/// it is now ([`Reselected`])
#[derive(Debug, Clone, Default, PartialEq, Eq)]
pub struct Reselect {
    /// The messages selected: one (the message shown, or one the app chose to show), several, Select All, or none
    pub selected: Selected,
    /// With one message: the row it had, looked near first (a list read again with mail come above it finds it at
    /// once)
    pub hint: Option<u64>,
    /// The row to select in place of the selection: where the rows an action took out of the list were (the last row
    /// when the list is shorter now)
    pub after: Option<u64>,
    /// The messages the last Undo brought back, or the store took back as the server refused an action, selected in
    /// place of the selection when the list has them (after `ActionUndone` or an Undo)
    pub restored: bool,
}

/// How a load selected rows for what the window had selected
#[derive(Debug, Clone, Copy, Default, PartialEq, Eq)]
pub enum Reselection {
    /// Nothing selected: nothing was, or none of it is in the list
    #[default]
    None,
    /// The messages selected before, where they are now (some may be gone): only their numbers change
    Kept,
    /// Select All is still the whole list: every row selected, counted again
    All,
    /// What Undo brought back, or the store took back of a refused action: a new selection, its first row focused
    Restored,
    /// The row after a removal: a new selection
    After,
}

/// The rows a load selected ([`ListLoad::reselected`])
#[derive(Debug, Clone, Default, PartialEq, Eq)]
pub struct Reselected {
    pub how: Reselection,
    /// The rows to select, ascending; none for [`Reselection::All`], which selects every row
    pub rows: Vec<u64>,
    /// The row to focus and scroll to, None to leave the scrolling as it is
    pub focus: Option<u64>,
    /// The selection now: Select All counted again, or the messages the rows are of
    pub selection: Selected,
}

/// What a list load read in the background ([`Core::list_load`], [`Core::list_load_page`])
#[derive(Debug, Clone, Default, PartialEq, Eq)]
pub struct ListLoad {
    /// Where its rows start in the list
    pub offset: u64,
    /// It read the counts (a load of the list); a page alone did not, and has them 0
    pub counted: bool,
    /// The messages of the list, the unread ones, and its rows (one a conversation when grouped)
    pub total: u64,
    pub unread: u64,
    pub rows: u64,
    /// Whether the list names whom its messages went to ([`Core::lists_recipients`])
    pub lists_recipients: bool,
    /// The rows from `offset` on, [`LIST_PAGE`] at most
    pub messages: Vec<Message>,
    /// The rows to select for what the window had selected (a load of the list; nothing for a page)
    pub reselected: Reselected,
}

#[cfg(test)]
mod tests {
    use super::*;
    use pe_store::{AccountSettings, FolderInfo, MessageInfo};

    fn opened(dir: &pe_testkit::TempDir) -> Core {
        let options = crate::Options {
            passwords: crate::PasswordStore::Memory,
            ..Default::default()
        };
        Core::open_with(dir.path().join("store.db"), options, |_| {}).unwrap()
    }

    /// A message `uid` dated `at`, with its own id and the ids it answers
    fn mail(uid: u64, at: i64, id: &str, answers: &[&str]) -> MessageInfo {
        MessageInfo {
            uid,
            date: Some(at),
            subject: id.trim_matches(['<', '>']).into(),
            message_id: Some(id.into()),
            references: answers.iter().map(|a| a.to_string()).collect(),
            flags: vec!["\\Seen".into()],
            ..Default::default()
        }
    }

    /// An Inbox with two conversations of several messages (a: 1, 3, 4; e: 5, 6) and one of one (d: 2)
    fn inbox(core: &Core) -> FolderId {
        let store = core.store();
        let account = store
            .add_account(&AccountSettings {
                email: "a@example.com".into(),
                ..Default::default()
            })
            .unwrap();
        let folder = FolderInfo {
            path: "INBOX".into(),
            name: "INBOX".into(),
            selectable: true,
            ..Default::default()
        };
        store.set_folders(account, &[folder]).unwrap();
        let inbox = store.folders(account).unwrap()[0].id;
        store
            .add_messages(
                inbox,
                &[
                    mail(1, 100, "<a@x>", &[]),
                    mail(2, 200, "<d@x>", &[]),
                    mail(3, 300, "<b@x>", &["<a@x>"]),
                    mail(4, 400, "<c@x>", &["<a@x>", "<b@x>"]),
                    mail(5, 150, "<e@x>", &[]),
                    mail(6, 250, "<f@x>", &["<e@x>"]),
                ],
            )
            .unwrap();
        inbox
    }

    fn thread(core: &Core, folder: FolderId, uid: u64) -> i64 {
        core.store()
            .message(folder, uid)
            .unwrap()
            .unwrap()
            .info
            .thread_id
            .unwrap()
    }

    #[test]
    fn a_new_scope_or_words_close_the_conversations() {
        let mut view = ListView::new();
        assert!(!view.active() && view.search().is_none(), "no folder lists nothing");
        assert!(!view.expand(7), "not grouped: nothing opens");
        assert!(view.set_scope(Some(Scope::Folder(1))));
        view.set_grouped(true);
        assert!(view.expand(7) && view.expand(9) && !view.expand(7));
        assert!(!view.expand(0), "no conversation");
        assert_eq!(view.search().unwrap().threads, Some(vec![7, 9]));

        assert!(!view.set_scope(Some(Scope::Folder(1))), "the same folder");
        assert!(view.is_expanded(7), "kept");
        assert!(view.set_scope(Some(Scope::AllInboxes)));
        assert_eq!(view.expanded().count(), 0, "another folder closes them");

        view.expand(7);
        assert!(!view.set_text(""));
        assert!(view.set_text("report"));
        assert!(!view.is_expanded(7), "words close them");
        let search = view.search().unwrap();
        assert_eq!((search.scope, search.text.as_str()), (Scope::Everywhere, "report"));
        assert!(view.searching() && view.several_folders());
        assert!(view.set_scope(None) && view.active(), "words list without a folder");

        view.expand(7);
        view.set_hide_ignored(true);
        assert!(view.is_expanded(7), "hiding ignored ones keeps them open");
        assert!(view.search().unwrap().hide_ignored);
        assert!(view.set_grouped(false));
        assert_eq!(view.search().unwrap().threads, None, "ungrouped");
        assert!(!view.is_expanded(7), "grouping closes them");
    }

    #[test]
    fn toggle_and_collapse_all() {
        let mut view = ListView::new();
        view.set_scope(Some(Scope::Folder(1)));
        view.set_grouped(true);
        assert!(view.toggle(3), "open now");
        assert!(!view.toggle(3), "closed again");
        view.toggle(3);
        view.toggle(4);
        assert!(view.collapse(4) && !view.collapse(4));
        assert!(view.collapse_all() && !view.collapse_all());
        assert_eq!(view.expanded().count(), 0);
    }

    /// View > Hide Read Messages: the unread messages, and one read since stays until the list changes, so it does not
    /// vanish from under the user the moment the reading pane marks it read
    #[test]
    fn unread_only_keeps_a_message_read_until_the_list_changes() {
        let dir = pe_testkit::TempDir::new("core-list-view-unread");
        let core = opened(&dir);
        let inbox = inbox(&core);
        thread(&core, inbox, 1);
        let mut view = ListView::new();
        view.set_scope(Some(Scope::Folder(inbox)));
        let all = view.rows(&core, 0, 10).unwrap();
        let (first, second) = (all[0].info.uid, all[1].info.uid);
        core.set_seen(inbox, first, false).unwrap();
        core.set_seen(inbox, second, false).unwrap();

        view.set_show(Show::Unread);
        let shown: Vec<u64> = view.rows(&core, 0, 10).unwrap().iter().map(|m| m.info.uid).collect();
        assert_eq!(shown.len(), 2, "the unread ones only");
        core.set_seen(inbox, first, true).unwrap();
        assert_eq!(view.row_count(&core).unwrap(), 2, "the one read stays");
        assert_eq!(view.counts(&core).unwrap(), (2, 1));

        // another folder and back: only the unread one
        std::thread::sleep(std::time::Duration::from_millis(250));
        view.set_scope(Some(Scope::AllInboxes));
        view.set_scope(Some(Scope::Folder(inbox)));
        assert_eq!(view.row_count(&core).unwrap(), 1);
        view.set_show(Show::All);
        assert_eq!(view.row_count(&core).unwrap(), all.len() as u64);
    }

    /// What a view keeps answers as the store does, and only while nothing was written: rows a click selects from
    /// the pages shown, the counts, the row count
    #[test]
    fn what_a_view_keeps_answers_as_the_store_does() {
        let dir = pe_testkit::TempDir::new("core-list-view-memo");
        let core = opened(&dir);
        let inbox = inbox(&core);
        let a = thread(&core, inbox, 1);
        let ranges: [&[(u64, u64)]; 6] = [
            &[(0, 1)],
            &[(1, 2)],
            &[(0, 3)],
            &[(2, 3), (0, 1)],
            &[(0, 2), (1, 3)],
            &[(1, 40)],
        ];
        for (grouped, open) in [(false, None), (true, None), (true, Some(a))] {
            let mut view = ListView::new();
            view.set_scope(Some(Scope::Folder(inbox)));
            view.set_grouped(grouped);
            if let Some(thread) = open {
                view.expand(thread);
            }
            let search = view.search().unwrap();
            let what = format!("grouped {grouped}, open {open:?}");
            // before any page is read, then from the pages read: a short one, which ends the list, and a page of one
            for read in [None, Some((0, 2)), Some((2, 10))] {
                if let Some((offset, limit)) = read {
                    view.rows(&core, offset, limit).unwrap();
                }
                for wanted in ranges {
                    assert_eq!(
                        view.refs_in_ranges(&core, wanted).unwrap(),
                        core.refs_in_ranges(&search, view.sort(), wanted).unwrap(),
                        "{what}, {read:?} read, rows {wanted:?}"
                    );
                }
            }
            let messages = core.count_search(&search).unwrap();
            assert_eq!(view.counts(&core).unwrap(), messages, "{what}");
            assert_eq!(
                view.row_count(&core).unwrap(),
                core.count_rows(&search).unwrap(),
                "{what}"
            );
            if !grouped {
                assert_eq!(view.row_count(&core).unwrap(), messages.0, "one row a message");
            }

            // a write: what was kept is read again
            core.set_seen(inbox, 4, false).unwrap();
            assert_eq!(view.counts(&core).unwrap(), (messages.0, messages.1 + 1), "{what}");
            core.store()
                .add_messages(inbox, &[mail(7, 500, "<g@x>", &["<a@x>"])])
                .unwrap();
            assert_eq!(
                view.row_count(&core).unwrap(),
                core.count_rows(&search).unwrap(),
                "{what}"
            );
            let page = view.rows(&core, 0, 10).unwrap();
            assert_eq!(page, core.search(&search, view.sort(), 0, 10).unwrap(), "{what}");
            assert!(
                page.iter().any(|m| m.info.uid == 7) || (grouped && open.is_none()),
                "{what}"
            );
            core.store().remove_messages(inbox, &[7]).unwrap();
            core.set_seen(inbox, 4, true).unwrap();
        }
    }

    /// A click selects what its row shows: mail that came after the page was read moves the list, not the rows shown,
    /// until the list is counted and read again, as the apps do when it changes
    #[test]
    fn a_click_selects_what_its_row_shows() {
        let dir = pe_testkit::TempDir::new("core-list-view-click");
        let core = opened(&dir);
        let inbox = inbox(&core);
        let mut view = ListView::new();
        view.set_scope(Some(Scope::Folder(inbox)));
        let at = |uid: u64| MessageRef { folder: inbox, uid };
        view.counts(&core).unwrap();
        let shown = view.rows(&core, 0, 10).unwrap();
        assert_eq!(shown[0].info.uid, 4, "the newest on top");
        core.store()
            .add_messages(inbox, &[mail(7, 900, "<new@x>", &[])])
            .unwrap();
        assert_eq!(view.refs_in_ranges(&core, &[(0, 1)]).unwrap(), [at(4)], "the row shown");
        assert_eq!(
            view.rows(&core, 0, 10).unwrap()[0].info.uid,
            7,
            "a page read again is read anew"
        );
        assert_eq!(
            view.refs_in_ranges(&core, &[(0, 1)]).unwrap(),
            [at(7)],
            "as that page shows"
        );
        view.counts(&core).unwrap();
        assert_eq!(
            view.refs_in_ranges(&core, &[(0, 2)]).unwrap(),
            [at(7), at(4)],
            "counted again: from the list"
        );
    }

    /// The pages a view keeps say which messages the rows are, as a fresh read of the list does
    #[test]
    fn the_pages_kept_are_the_rows_read() {
        let dir = pe_testkit::TempDir::new("core-list-view-kept");
        let core = opened(&dir);
        let inbox = inbox(&core);
        let a = thread(&core, inbox, 1);
        for (grouped, open) in [(false, None), (true, None), (true, Some(a))] {
            let mut view = ListView::new();
            view.set_scope(Some(Scope::Folder(inbox)));
            view.set_grouped(grouped);
            if let Some(thread) = open {
                view.expand(thread);
            }
            let search = view.search().unwrap();
            view.counts_and_rows(&core).unwrap();
            view.rows(&core, 0, 2).unwrap();
            view.rows(&core, 2, 10).unwrap();
            let fresh: Vec<RowRef> = core
                .search(&search, view.sort(), 0, 10)
                .unwrap()
                .iter()
                .map(RowRef::of)
                .collect();
            let kept = view.memo.kept.lock().unwrap();
            let pages = &kept.as_ref().unwrap().pages;
            let kept: Vec<RowRef> = pages.iter().flat_map(|p| p.rows.iter().copied()).collect();
            assert_eq!(kept, fresh, "grouped {grouped}, open {open:?}");
            assert_eq!(
                kept.iter().any(|r| r.collapsed.is_some()),
                grouped,
                "grouped {grouped}, open {open:?}"
            );
        }
    }

    /// The counts and the row count together, as each alone gives them
    #[test]
    fn counts_and_rows_together() {
        let dir = pe_testkit::TempDir::new("core-list-view-counts");
        let core = opened(&dir);
        let inbox = inbox(&core);
        let mut view = ListView::new();
        assert_eq!(view.counts_and_rows(&core).unwrap(), (0, 0, 0), "no folder");
        view.set_scope(Some(Scope::Folder(inbox)));
        core.set_seen(inbox, 2, false).unwrap();
        assert_eq!(view.counts_and_rows(&core).unwrap(), (6, 1, 6));
        view.set_grouped(true);
        assert_eq!(view.counts_and_rows(&core).unwrap(), (6, 1, 3));
        view.expand(thread(&core, inbox, 1));
        assert_eq!(view.counts_and_rows(&core).unwrap(), (6, 1, 5));
        assert_eq!(
            (view.counts(&core).unwrap(), view.row_count(&core).unwrap()),
            ((6, 1), 5)
        );
    }

    /// A list is stale until it is counted, again after a write, and not after a read
    #[test]
    fn stale_after_a_write_not_after_a_read() {
        let dir = pe_testkit::TempDir::new("core-list-view-stale");
        let core = opened(&dir);
        let inbox = inbox(&core);
        let mut view = ListView::new();
        assert!(!view.stale(&core).unwrap(), "it lists nothing");
        view.set_scope(Some(Scope::Folder(inbox)));
        assert!(view.stale(&core).unwrap(), "not counted yet");
        view.counts_and_rows(&core).unwrap();
        assert!(!view.stale(&core).unwrap(), "counted");
        view.rows(&core, 0, 10).unwrap();
        core.store().message(inbox, 1).unwrap();
        assert!(!view.stale(&core).unwrap(), "a read changes nothing");
        core.set_seen(inbox, 1, false).unwrap();
        assert!(view.stale(&core).unwrap(), "a write");
        view.counts(&core).unwrap();
        assert!(!view.stale(&core).unwrap(), "counted again");
        view.set_sort(Sort {
            ascending: true,
            ..view.sort()
        });
        assert!(view.stale(&core).unwrap(), "another order is another list");
        view.counts_and_rows(&core).unwrap();
        // a write by another connection, as a worker's
        let other = pe_store::Store::open(dir.path().join("store.db")).unwrap();
        other.add_messages(inbox, &[mail(8, 800, "<h@x>", &[])]).unwrap();
        assert!(view.stale(&core).unwrap(), "another connection's write");
    }

    /// What Undo brought back is given as rows only of the list as it was counted: messages back in the store after
    /// the count wait for the list to be read again, and are kept until then
    #[test]
    fn restored_rows_only_of_the_list_counted() {
        let dir = pe_testkit::TempDir::new("core-list-view-restored");
        let core = opened(&dir);
        let inbox = inbox(&core);
        let mut view = ListView::new();
        view.set_scope(Some(Scope::Folder(inbox)));
        assert_eq!(view.restored(&core).unwrap(), None, "not counted yet");
        view.counts_and_rows(&core).unwrap();
        assert_eq!(view.restored(&core).unwrap(), Some(vec![]), "no Undo");

        // Undo of two moved away, the list counted before they are back
        *core.restored.lock().unwrap() = vec![crate::selection::Back::Moving(
            inbox,
            vec!["<g@x>".into(), "<h@x>".into()],
        )];
        assert_eq!(view.restored(&core).unwrap(), Some(vec![]), "none back yet");
        // back in the store, as the worker's sync writes them: the list counted before is behind
        let other = pe_store::Store::open(dir.path().join("store.db")).unwrap();
        other
            .add_messages(inbox, &[mail(7, 900, "<g@x>", &[]), mail(8, 800, "<h@x>", &[])])
            .unwrap();
        assert_eq!(view.restored(&core).unwrap(), None, "the list shown does not have them");
        assert_eq!(view.restored(&core).unwrap(), None, "kept until it is read again");
        assert_eq!(view.counts_and_rows(&core).unwrap().0, 8);
        assert_eq!(
            view.restored(&core).unwrap(),
            Some(vec![0, 1]),
            "the newest two, at the top"
        );
        assert_eq!(
            view.restored(&core).unwrap(),
            Some(vec![]),
            "forgotten once all were given"
        );
    }

    /// The row of the message shown after the list is read again: from the pages read, nearest the hint, or from the
    /// whole list when they do not have it
    #[test]
    fn index_of_near_looks_near_then_everywhere() {
        let dir = pe_testkit::TempDir::new("core-list-view-near");
        let core = opened(&dir);
        let inbox = inbox(&core);
        let a = thread(&core, inbox, 1);
        for (grouped, open) in [(false, None), (true, None), (true, Some(a))] {
            let mut view = ListView::new();
            view.set_scope(Some(Scope::Folder(inbox)));
            view.set_grouped(grouped);
            if let Some(thread) = open {
                view.expand(thread);
            }
            let what = format!("grouped {grouped}, open {open:?}");
            view.counts_and_rows(&core).unwrap();
            view.rows(&core, 0, 2).unwrap();
            for uid in 1..=6 {
                let whole = view.index_of(&core, inbox, uid).unwrap();
                for hint in [0, 1, 3, 40] {
                    assert_eq!(
                        view.index_of_near(&core, inbox, uid, hint).unwrap(),
                        whole,
                        "{what}, uid {uid}, hint {hint}"
                    );
                }
            }
            assert_eq!(view.index_of_near(&core, inbox, 99, 0).unwrap(), None, "{what}");

            // found in the pages read: the first rows, and none once the store changed since they were read
            let first = view.rows(&core, 0, 2).unwrap()[0].at();
            let found = |view: &ListView| {
                let moment_at = When {
                    generation: core.generation().unwrap(),
                    minute: now_ms() / 60_000,
                };
                let kept = view.memo.kept.lock().unwrap();
                kept.as_ref().unwrap().row_near(first, 1, moment_at)
            };
            assert_eq!(found(&view), Some(0), "{what}");
            core.set_seen(first.folder, first.uid, false).unwrap();
            assert_eq!(found(&view), None, "{what}: read before the write");
            assert_eq!(
                view.index_of_near(&core, first.folder, first.uid, 0).unwrap(),
                Some(0),
                "{what}"
            );
            core.set_seen(first.folder, first.uid, true).unwrap();
        }
    }

    #[test]
    fn expand_all_and_reveal_through_the_core() {
        let dir = pe_testkit::TempDir::new("core-list-view");
        let core = opened(&dir);
        let inbox = inbox(&core);
        let (a, e) = (thread(&core, inbox, 1), thread(&core, inbox, 5));

        let mut view = ListView::new();
        assert!(!view.expand_all(&core).unwrap(), "no folder");
        assert_eq!(view.row_count(&core).unwrap(), 0);
        assert_eq!(view.counts(&core).unwrap(), (0, 0));
        view.set_scope(Some(Scope::Folder(inbox)));
        assert!(!view.expand_all(&core).unwrap(), "not grouped");
        assert_eq!(view.row_count(&core).unwrap(), 6);
        view.set_grouped(true);
        assert_eq!(view.row_count(&core).unwrap(), 3, "a row a conversation");
        assert_eq!(view.counts(&core).unwrap(), (6, 0), "the messages counted all the same");

        // Expand All opens those with replies, not the one of one message
        assert!(view.expand_all(&core).unwrap());
        assert_eq!(view.expanded().collect::<Vec<_>>(), {
            let mut both = vec![a, e];
            both.sort();
            both
        });
        assert!(!view.expand_all(&core).unwrap(), "already open");
        assert_eq!(view.row_count(&core).unwrap(), 6);
        assert!(view.collapse_all());

        // a reply hidden in its collapsed conversation is revealed, its first message and an open one are not
        assert!(!view.reveal(&core, inbox, 1).unwrap(), "the first has the row");
        assert!(!view.reveal(&core, inbox, 2).unwrap(), "alone");
        assert!(!view.reveal(&core, inbox, 99).unwrap(), "not there");
        assert_eq!(
            view.index_of(&core, inbox, 4).unwrap(),
            Some(0),
            "its conversation's row"
        );
        assert!(view.reveal(&core, inbox, 4).unwrap());
        assert!(view.is_expanded(a) && !view.is_expanded(e));
        assert_eq!(view.index_of(&core, inbox, 4).unwrap(), Some(2), "a row of its own");
        assert!(!view.reveal(&core, inbox, 3).unwrap(), "open already");

        // the rows and selections read through the view
        let rows = view.rows(&core, 0, 10).unwrap();
        assert_eq!(rows.len(), 5);
        assert_eq!(
            view.refs_in_ranges(&core, &[(0, 1)]).unwrap().len(),
            1,
            "an open conversation's first row"
        );
        assert_eq!(
            view.refs_in_ranges(&core, &[(3, 4)]).unwrap(),
            [
                MessageRef { folder: inbox, uid: 5 },
                MessageRef { folder: inbox, uid: 6 }
            ],
            "a collapsed one's row stands for its messages"
        );
        assert_eq!(
            view.positions(&core, &[MessageRef { folder: inbox, uid: 4 }]).unwrap(),
            [2]
        );
        assert!(!view.lists_recipients(&core).unwrap());
    }
}
