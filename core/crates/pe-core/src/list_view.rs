//! What a message list shows, kept by the core: the folder (or All Inboxes), the words typed in the Find box, what
//! View > Current View shows, the order, whether it is grouped by conversation and which conversations are open, and
//! whether ignored conversations are hidden. The apps hold a [`ListView`] (through C, a `PeListView`), change it as
//! the user does, and read the list's rows, counts and places from it; the rules (the conversations closed when the
//! folder changes, Expand All, a message hidden in a collapsed conversation opened to be shown) are here once.
//!
//! Every list call builds the [`Search`] the store reads from the view, so the queries are those of [`Core::search`]
//! and its kin.

use std::collections::BTreeSet;

use pe_store::{FolderId, Message, MessageRef, Scope, Search, Show, Sort};

use crate::{Action, Core, NextUnread, Result, Summary};

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
    /// With Show Unread: the messages the list has shown (store row ids), which stay in it when read, until another
    /// folder, other words or another Show
    shown: std::cell::RefCell<BTreeSet<i64>>,
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
        self.shown.borrow_mut().clear();
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
        self.shown.borrow_mut().clear();
        true
    }

    /// Whether words are searched for: the list is then of every folder of every account (`in:` narrows that)
    pub fn searching(&self) -> bool {
        !self.text.is_empty()
    }

    /// Whether the list has messages of several folders: a search, All Inboxes or every folder (the lists with a
    /// Folder or Account column)
    pub fn several_folders(&self) -> bool {
        self.searching() || matches!(self.scope, Some(Scope::AllInboxes | Scope::Everywhere))
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
            self.shown.borrow_mut().clear();
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
            keep: match self.show {
                Show::Unread => self.shown.borrow().iter().copied().collect(),
                _ => Vec::new(),
            },
        })
    }

    /// `f` with the search of the list, `empty` when it lists nothing
    fn listed<T>(&self, empty: T, f: impl FnOnce(&Search) -> Result<T>) -> Result<T> {
        match self.search() {
            Some(search) => f(&search),
            None => Ok(empty),
        }
    }

    /// A page of the list's rows, from `offset` on
    pub fn rows(&self, core: &Core, offset: u64, limit: u64) -> Result<Vec<Message>> {
        let rows = self.listed(Vec::new(), |search| core.search(search, self.sort, offset, limit))?;
        if self.show == Show::Unread {
            self.shown.borrow_mut().extend(rows.iter().map(|row| row.id));
        }
        Ok(rows)
    }

    /// How many rows the list has: grouped, one a conversation and the other messages of the open ones
    pub fn row_count(&self, core: &Core) -> Result<u64> {
        self.listed(0, |search| core.count_rows(search))
    }

    /// The messages of the list and how many of them are unread, for the status bar (see [`Core::list_counts`])
    pub fn counts(&self, core: &Core) -> Result<(u64, u64)> {
        self.listed((0, 0), |search| core.list_counts(search))
    }

    /// The row of the message `uid` of `folder` (its conversation's while that is collapsed); None when it is not in
    /// the list
    pub fn index_of(&self, core: &Core, folder: FolderId, uid: u64) -> Result<Option<u64>> {
        self.listed(None, |search| core.search_index(search, self.sort, folder, uid))
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

    /// The messages at the rows `ranges` (start included, end not), in the list's order
    pub fn refs_in_ranges(&self, core: &Core, ranges: &[(u64, u64)]) -> Result<Vec<MessageRef>> {
        self.listed(Vec::new(), |search| core.refs_in_ranges(search, self.sort, ranges))
    }

    /// Where the messages `refs` are now, ascending; those no longer in the list left out
    pub fn positions(&self, core: &Core, refs: &[MessageRef]) -> Result<Vec<u64>> {
        self.listed(Vec::new(), |search| core.positions(search, self.sort, refs))
    }

    /// Whether the list names whom its messages went to (see [`Core::lists_recipients`])
    pub fn lists_recipients(&self, core: &Core) -> Result<bool> {
        self.listed(false, |search| core.lists_recipients(search))
    }

    /// Whether `action` on the messages of `summary` takes them out of this list (see [`Summary::leaves_list`])
    pub fn leaves_list(&self, summary: &Summary, action: Action) -> bool {
        summary.leaves_list(action, self.hide_ignored)
    }
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
        view.set_scope(Some(Scope::AllInboxes));
        view.set_scope(Some(Scope::Folder(inbox)));
        assert_eq!(view.row_count(&core).unwrap(), 1);
        view.set_show(Show::All);
        assert_eq!(view.row_count(&core).unwrap(), all.len() as u64);
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
