//! What the windows do to the messages selected in a list, one or many, from one folder or from several (All Inboxes,
//! a search): read and unread, flag, junk, delete, move and copy, each folder's messages with one command; what to
//! call it in the status bar; and Edit > Undo for the last move, delete or junk.

use std::collections::{BTreeMap, BTreeSet};
use std::sync::{Arc, Mutex};

use pe_store::{FLAG_COLOR_BITS, FlagColor, FolderId, MessageRef, Picked, Search, Sort};

use pe_i18n::{Text, tr, tr_args};

use crate::text::messages;
use crate::worker::Command;
use crate::{Core, Error, Result};

/// The most UIDs one command carries, so a command line stays short whatever was selected (a UID set of messages
/// that are not next to each other is as long as its UIDs) and a server with MESSAGELIMIT acts on all of them
pub(crate) const PER_COMMAND: usize = pe_sync::PER_COMMAND;

/// What to do to the selected messages
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum Action {
    /// Read (true) or unread
    Read(bool),
    /// Flag (true) or take the flag away
    Flag(bool),
    /// Flag them when one is not flagged, take the flags away when all are ([`Summary::flags`])
    ToggleFlag,
    /// Flag them in a colour, as Apple Mail does (`\\Flagged` and its `$MailFlagBit` keywords)
    FlagColor(FlagColor),
    /// Junk (true), into Junk E-mail; not junk, into the Inbox
    Junk(bool),
    /// Into Deleted Items, or for good from there and from an account without one ([`Summary::delete_question`])
    Delete,
    /// Out of the Inbox (or a folder of the user's) into the account's Archive; on Gmail every label taken off, so they
    /// are left in All Mail ([`Core::can_archive`] says where it applies)
    Archive,
    Move(FolderId),
    Copy(FolderId),
    // Watch and Ignore act on conversations, which can have messages in any folder: `act` hands them to
    // `mark_conversations` (watch.rs) before anything else, so they never reach the per-folder path below it.
    /// Watch Conversation: their conversations watched, or no longer when all of them are ([`Summary::watched`])
    Watch,
    /// Ignore Conversation: their conversations ignored (and read), or no longer when all of them are
    /// ([`Summary::ignored`])
    Ignore,
}

impl Action {
    /// What Edit > Undo calls taking it back ("Move" for "Undo Move"); None for what is not taken back
    fn undo_name(self) -> Option<Text> {
        match self {
            Action::Move(_) => Some(Text::UndoMove),
            Action::Delete => Some(Text::UndoDelete),
            Action::Archive => Some(Text::UndoArchive),
            Action::Junk(true) => Some(Text::UndoJunk),
            Action::Junk(false) => Some(Text::UndoNotJunk),
            _ => None,
        }
    }
}

/// The selected messages in numbers, for the reading pane, the status bar and which commands apply
#[derive(Debug, Clone, Default, PartialEq, Eq)]
pub struct Summary {
    pub count: u64,
    pub unread: u64,
    pub flagged: u64,
    /// The colour all of them are flagged in; None when one is not flagged or their colours differ
    pub flag_color: Option<FlagColor>,
    /// Every one of them is in a Junk folder (Mark as Not Junk applies, not Mark as Junk)
    pub in_junk: bool,
    /// Every one of them can be archived (Archive applies), see [`crate::archivable`]
    pub archivable: bool,
    /// How many accounts and folders they are in
    pub accounts: u64,
    pub folders: u64,
    /// How many of them Delete removes for good
    pub for_good: u64,
    /// Every one of them is in a watched conversation, or in an ignored one: the check marks of Watch Conversation
    /// and Ignore Conversation, which then take the mark away
    pub watched: bool,
    pub ignored: bool,
}

impl Summary {
    /// "3 messages selected" for the reading pane
    pub fn title(&self) -> String {
        tr_args(Text::SelectionTitle, &[("count", self.count.into())])
    }

    /// The reading pane's page over several messages, in the style of its other states ([`crate::reader_page`])
    pub fn page(&self) -> String {
        pe_html::status_page(&self.title(), &self.detail(), false)
    }

    /// "2 unread, 1 flagged" under it; empty when neither
    pub fn detail(&self) -> String {
        let mut parts = Vec::new();
        if self.unread > 0 {
            parts.push(tr_args(Text::SelectionUnread, &[("count", self.unread.into())]));
        }
        if self.flagged > 0 {
            parts.push(tr_args(Text::SelectionFlagged, &[("count", self.flagged.into())]));
        }
        crate::text::word_list(&parts)
    }

    /// Whether `action` on them takes them out of the list, which then selects the row after them: Delete, Move,
    /// Junk, Not Junk and Archive, and Ignore Conversation while the list hides ignored conversations (`hide_ignored`)
    /// unless all of them are ignored already, when it takes the mark away
    pub fn leaves_list(&self, action: Action, hide_ignored: bool) -> bool {
        match action {
            Action::Delete | Action::Move(_) | Action::Junk(_) | Action::Archive => true,
            Action::Ignore => hide_ignored && !self.ignored,
            _ => false,
        }
    }

    /// Whether Flag flags them (one is not flagged) or takes the flags away (all are)
    pub fn flags(&self) -> bool {
        self.flagged < self.count
    }

    /// The title of the Move or Copy window (`copy`): "Move 3 Messages", "Copy Message"
    pub fn move_title(&self, copy: bool) -> String {
        let text = if copy {
            Text::MoveWindowTitleCopy
        } else {
            Text::MoveWindowTitleMove
        };
        tr_args(text, &[("count", self.count.into())])
    }

    /// What the Move or Copy window says over its folders: "Move the 3 selected messages to:"
    pub fn move_prompt(&self, copy: bool) -> String {
        let text = if copy {
            Text::MoveWindowPromptCopy
        } else {
            Text::MoveWindowPromptMove
        };
        tr_args(text, &[("count", self.count.into())])
    }

    /// What to ask before Delete when it removes some of them for good; None when it removes none
    pub fn delete_question(&self) -> Option<String> {
        match (self.for_good, self.count) {
            (0, _) => None,
            (1, 1) => Some(tr(Text::DeleteForGoodOne)),
            (n, all) if n == all => Some(tr_args(Text::DeleteForGoodAll, &[("count", n.into())])),
            (n, all) => Some(tr_args(
                Text::DeleteForGoodSome,
                &[("count", n.into()), ("total", all.into())],
            )),
        }
    }
}

/// What Edit > Undo takes back: messages that went from one folder to another, found again by their Message-IDs
#[derive(Debug, Clone, PartialEq, Eq)]
pub(crate) struct Undo {
    /// What Edit > Undo says, "Undo Move"
    what: Text,
    moves: Vec<UndoMove>,
}

/// Messages chosen in a list: listed, or every message of a list (Select All), listed only when a command needs them
#[derive(Debug, Clone, PartialEq, Eq)]
pub enum Selected {
    Listed(Vec<MessageRef>),
    /// Every message of the list `search` and `sort` make (a collapsed conversation's too), `count` of them when
    /// selected
    All {
        search: Search,
        sort: Sort,
        count: u64,
    },
}

impl Default for Selected {
    fn default() -> Selected {
        Selected::Listed(Vec::new())
    }
}

impl Selected {
    /// How many messages: those listed, or those the list had when it was selected
    pub fn count(&self) -> u64 {
        match self {
            Selected::Listed(refs) => refs.len() as u64,
            Selected::All { count, .. } => *count,
        }
    }
}

/// What Mark All Read marks ([`Core::mark_read_start`])
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum MarkRead {
    Folder(FolderId),
    /// Every folder of an account
    Account(pe_store::AccountId),
    /// Every account's Inbox
    AllInboxes,
}

/// Messages to move back, by the worker of the account they are in now ([`Command::UndoMoves`]): it runs after the
/// move it takes back and the sync of the folder they went to, so it finds them there however soon it is asked
#[derive(Debug, Clone, PartialEq, Eq)]
pub(crate) struct UndoMove {
    pub(crate) from: FolderId,
    pub(crate) to: FolderId,
    pub(crate) message_ids: Vec<String>,
    /// A keyword junk set, taken away again before they go back
    pub(crate) flag: Option<&'static str>,
    /// They were archived: the worker finds them where that put them (`to` is `from` then), and on Gmail puts their
    /// labels back
    pub(crate) archived: bool,
}

impl Core {
    /// The messages at positions `ranges` (start included, end not) of the list `search` and `sort` make, as the
    /// windows' selections are kept: in the list's order
    pub fn refs_in_ranges(&self, search: &Search, sort: Sort, ranges: &[(u64, u64)]) -> Result<Vec<MessageRef>> {
        let sort = self.list_sort(search, sort)?;
        Ok(self.store().refs_in_ranges(search, sort, ranges)?)
    }

    /// The messages of `rows` of the list `search` makes, read by [`Core::search`]: a collapsed conversation's row
    /// stands for its messages. What selecting rows already shown takes, without reading the list again.
    pub fn refs_of_rows(&self, search: &Search, rows: &[pe_store::RowRef]) -> Result<Vec<MessageRef>> {
        Ok(self.store().refs_of_rows(search, rows)?)
    }

    /// Where the messages `refs` are now in that list, ascending, to select them again after it changed
    pub fn positions(&self, search: &Search, sort: Sort, refs: &[MessageRef]) -> Result<Vec<u64>> {
        let sort = self.list_sort(search, sort)?;
        Ok(self.store().positions(search, sort, refs)?)
    }

    /// The selected messages in numbers; those that are gone meanwhile are not counted
    pub fn summary(&self, refs: &[MessageRef]) -> Result<Summary> {
        let store = self.store();
        let picked = store.picked(refs)?;
        let mut summary = Summary {
            count: picked.len() as u64,
            in_junk: !picked.is_empty(),
            archivable: !picked.is_empty(),
            ..Summary::default()
        };
        let mut accounts = BTreeSet::new();
        let mut colors = BTreeSet::new();
        for (folder, group) in by_folder(&picked) {
            let (account, info) = store.folder_info(folder)?;
            accounts.insert(account);
            summary.folders += 1;
            summary.in_junk &= info.special_use.as_deref() == Some("\\Junk");
            summary.archivable &= crate::archivable(&info);
            if crate::trash_in(&store, folder)?.is_none() {
                summary.for_good += group.len() as u64;
            }
            summary.unread += group.iter().filter(|p| !p.seen()).count() as u64;
            summary.flagged += group.iter().filter(|p| p.flagged()).count() as u64;
            for color in group.iter().filter_map(|p| p.flag_color()) {
                colors.insert(color);
            }
        }
        summary.accounts = accounts.len() as u64;
        summary.watched = !picked.is_empty() && picked.iter().all(|p| p.mark == pe_store::ThreadMark::Watch);
        summary.ignored = !picked.is_empty() && picked.iter().all(|p| p.mark == pe_store::ThreadMark::Ignore);
        // the colour of the Flag menu's check mark: all of them flagged, in one colour
        summary.flag_color = match colors.len() {
            1 if summary.flagged == summary.count => colors.first().copied(),
            _ => None,
        };
        Ok(summary)
    }

    /// Does `action` to the messages `refs` (those still there), each folder's with one command: in the store now,
    /// on the server in the background, as the actions on one message do. Returns what the status bar says, "Moved 3
    /// messages to Archive". A move, delete into Deleted Items or junk becomes what Edit > Undo takes back.
    pub fn act(&self, refs: &[MessageRef], action: Action) -> Result<String> {
        let (text, undo) = self.act_untracked(refs, action)?;
        // what moved can be taken back; what is gone for good ends what came before it
        if let Some(what) = action.undo_name() {
            self.sent_not_last();
            *self.undo.lock().unwrap_or_else(|e| e.into_inner()) =
                (!undo.is_empty()).then_some(Undo { what, moves: undo });
        }
        Ok(text)
    }

    /// [`Core::act`] without making it what Edit > Undo takes back (an AI agent's change has its own Undo, in the
    /// agents' log): what the status bar says, and the messages that moved
    pub(crate) fn act_untracked(&self, refs: &[MessageRef], action: Action) -> Result<(String, Vec<UndoMove>)> {
        match action {
            Action::Watch => return Ok((self.mark_conversations(refs, pe_store::ThreadMark::Watch)?, Vec::new())),
            Action::Ignore => return Ok((self.mark_conversations(refs, pe_store::ThreadMark::Ignore)?, Vec::new())),
            _ => {}
        }
        let picked = self.store().picked(refs)?;
        if picked.is_empty() {
            return Err(Error::Unavailable(tr(Text::MessagesGone)));
        }
        let groups = by_folder(&picked);
        let action = match action {
            Action::ToggleFlag => Action::Flag(picked.iter().any(|p| !p.flagged())),
            other => other,
        };
        // the account of the folder they go to, checked before any of them goes
        let target = match action {
            Action::Move(to) | Action::Copy(to) => {
                let store = self.store();
                let folder = store.folder(to)?;
                if !folder.info.selectable {
                    return Err(Error::Unavailable(tr(Text::FolderHoldsNoMessages)));
                }
                store.note_target(to)?;
                Some(folder.account_id)
            }
            _ => None,
        };
        let mut crossed = false;
        let undo_name = action.undo_name();
        let mut undo = Vec::new();
        for (folder, group) in &groups {
            let uids: Vec<u64> = group.iter().map(|p| p.at.uid).collect();
            let crosses = match target {
                Some(account) => self.store().folder_info(*folder)?.0 != account,
                None => false,
            };
            crossed |= crosses;
            let went = self.act_on_folder(*folder, &uids, action, crosses)?;
            if let (Some(_), Some((to, flag))) = (undo_name, went) {
                undo.push(UndoMove {
                    from: *folder,
                    to,
                    message_ids: group.iter().filter_map(|p| p.message_id.clone()).collect(),
                    flag,
                    archived: action == Action::Archive,
                });
            }
        }
        let text = self.done_text(action, picked.len() as u64, &undo, crossed)?;
        Ok((text, undo))
    }

    /// Moves (or copies) messages of `folder` to `to`: in their account with one command, to another account through
    /// the store's transfers ([`Core::transfer_messages`])
    fn move_anywhere(&self, folder: FolderId, uids: &[u64], to: FolderId, copy: bool, crosses: bool) -> Result<()> {
        if crosses {
            return self.transfer_messages(folder, uids, to, copy);
        }
        for chunk in uids.chunks(PER_COMMAND) {
            if copy {
                self.copy_messages(folder, chunk, to)?;
            } else {
                self.move_messages(folder, chunk, to)?;
            }
        }
        Ok(())
    }

    /// Moves or copies messages of `folder` to a folder of another account: each kept in the store with what it takes
    /// (its source when it is here, its flags and date), a move out of the list now; the worker of their account does
    /// the rest in the background ([`Event::Transferring`] says how far it is)
    fn transfer_messages(&self, folder: FolderId, uids: &[u64], to: FolderId, copy: bool) -> Result<()> {
        let account = self.store().start_transfers(folder, uids, to, copy)?;
        if !copy {
            self.post(crate::Event::FolderChanged { account, folder })?;
        }
        self.send_command(account, crate::worker::Command::Transfer)
    }

    /// One folder's part of [`Core::act`], a command per [`PER_COMMAND`] messages. Returns where they went and the
    /// keyword set on the way, when they moved.
    fn act_on_folder(
        &self,
        folder: FolderId,
        uids: &[u64],
        action: Action,
        crosses: bool,
    ) -> Result<Option<(FolderId, Option<&'static str>)>> {
        if let Action::Move(to) | Action::Copy(to) = action {
            // already there: nothing to do
            if to != folder {
                self.move_anywhere(folder, uids, to, matches!(action, Action::Copy(_)), crosses)?;
            }
            return Ok((matches!(action, Action::Move(_)) && to != folder).then_some((to, None)));
        }
        let went = match action {
            Action::Delete => self.trash_for(folder)?.map(|trash| (trash, None)),
            Action::Junk(junk) => {
                let to = self.junk_target(folder, junk)?;
                (to != folder).then_some((to, Some(crate::junk_keywords(junk).0)))
            }
            // where they go the worker knows: the Archive folder, made if need be, or All Mail on Gmail
            Action::Archive => Some((folder, None)),
            _ => None,
        };
        for chunk in uids.chunks(PER_COMMAND) {
            match action {
                Action::Read(on) => self.set_flag_many(folder, chunk, "\\Seen", on)?,
                Action::Flag(true) => self.set_flag_many(folder, chunk, "\\Flagged", true)?,
                // the colour goes with the flag
                Action::Flag(false) => self.set_flag_color_many(folder, chunk, None)?,
                Action::FlagColor(color) => self.set_flag_color_many(folder, chunk, Some(color))?,
                Action::Junk(junk) => self.mark_junk_many(folder, chunk, junk)?,
                Action::Delete => self.delete_messages(folder, chunk)?,
                Action::Archive => self.archive_messages(folder, chunk)?,
                Action::Move(_) | Action::Copy(_) | Action::ToggleFlag | Action::Watch | Action::Ignore => {
                    unreachable!("handled before")
                }
            }
        }
        Ok(went)
    }

    /// What the status bar says once `action` is done to `count` messages
    fn done_text(&self, action: Action, count: u64, moved: &[UndoMove], crossed: bool) -> Result<String> {
        let n = messages(count);
        let (text, folder) = match action {
            Action::ToggleFlag | Action::Watch | Action::Ignore => unreachable!("resolved by act"),
            Action::Read(true) => (Text::DoneRead, None),
            Action::Read(false) => (Text::DoneUnread, None),
            Action::Flag(true) => (Text::DoneFlagged, None),
            Action::Flag(false) => (Text::DoneUnflagged, None),
            Action::FlagColor(color) => {
                return Ok(tr_args(
                    Text::DoneFlaggedColor,
                    &[("messages", (&n).into()), ("color", color.id().into())],
                ));
            }
            Action::Delete if moved.is_empty() => (Text::DoneDeletedForGood, None),
            Action::Archive => (Text::DoneArchived, None),
            Action::Delete | Action::Junk(_) => (Text::DoneMoved, Some(self.places(moved.iter().map(|m| m.to))?)),
            // to another account they go in the background, Event::Transferring says how far
            Action::Move(to) if crossed => (Text::DoneMoving, Some(self.places([to].into_iter())?)),
            Action::Copy(to) if crossed => (Text::DoneCopying, Some(self.places([to].into_iter())?)),
            Action::Move(to) => (Text::DoneMoved, Some(self.places([to].into_iter())?)),
            Action::Copy(to) => (Text::DoneCopied, Some(self.places([to].into_iter())?)),
        };
        let folder = folder.unwrap_or_default();
        Ok(tr_args(
            text,
            &[
                ("messages", (&n).into()),
                ("count", count.into()),
                ("folder", (&folder).into()),
            ],
        ))
    }

    /// The name of the folder they all went to, or "their folders" when they went to several
    fn places(&self, folders: impl Iterator<Item = FolderId>) -> Result<String> {
        let mut folders: Vec<FolderId> = folders.collect();
        folders.sort_unstable();
        folders.dedup();
        match folders.as_slice() {
            [one] => Ok(crate::text::folder_name(&self.store().folder(*one)?.info)),
            _ => Ok(tr(Text::TheirFolders)),
        }
    }

    /// The folders messages were moved or copied to last, the newest first, for the Move and Copy window
    pub fn recent_targets(&self, limit: u64) -> Result<Vec<FolderId>> {
        Ok(self.store().recent_targets(limit)?)
    }

    /// What Edit > Undo says it takes back, "Undo Move"; None when there is nothing
    pub fn undo_label(&self) -> Option<String> {
        if self.undo_is_send() {
            return Some(tr(Text::UndoSend));
        }
        let undo = self.undo.lock().unwrap_or_else(|e| e.into_inner());
        undo.as_ref().map(|u| tr(u.what))
    }

    /// Takes back the last move, delete into Deleted Items or junk: the messages go back to the folders they came
    /// from, found by their Message-IDs where they went, by the worker of their account (after the move it takes back,
    /// however soon it is asked). Returns what the status bar says.
    pub fn undo(&self) -> Result<String> {
        let undo = self.undo.lock().unwrap_or_else(|e| e.into_inner()).take();
        let Some(undo) = undo else {
            return Err(Error::Unavailable(tr(Text::NothingToUndo)));
        };
        let mut by_account: BTreeMap<pe_store::AccountId, Vec<UndoMove>> = BTreeMap::new();
        for m in &undo.moves {
            let account = self.store().folder(m.to)?.account_id;
            by_account.entry(account).or_default().push(m.clone());
        }
        for (account, moves) in by_account {
            self.send_command(account, Command::UndoMoves { moves })?;
        }
        let back: u64 = undo.moves.iter().map(|m| m.message_ids.len() as u64).sum();
        *self.restored.lock().unwrap_or_else(|e| e.into_inner()) = undo
            .moves
            .iter()
            .map(|m| Back::Moving(m.from, m.message_ids.clone()))
            .collect();
        let folder = self.places(undo.moves.iter().map(|m| m.from))?;
        Ok(tr_args(
            Text::DoneMovedBack,
            &[
                ("messages", (&messages(back)).into()),
                ("count", back.into()),
                ("folder", (&folder).into()),
            ],
        ))
    }

    /// The messages the last Undo brought back that are in their folders again (they get there once the server has
    /// moved them and the folder is synced), and those the store took back as the server refused an action (there at
    /// once), for the window to select them. Each folder's forgotten once all of it is there.
    pub fn restored(&self) -> Result<Vec<MessageRef>> {
        self.take_restored(|found| Ok(Some(found.to_vec())))
            .map(Option::unwrap_or_default)
    }

    /// `f` with the messages the last Undo brought back that are in their folders again, and those the store took back
    /// of a refused action; when `f` took them (gave Some) those are forgotten, and what Undo still waits for is kept,
    /// all of them kept for the next time when it did not
    pub(crate) fn take_restored<T>(&self, f: impl FnOnce(&[MessageRef]) -> Result<Option<T>>) -> Result<Option<T>> {
        let mut restored = self.restored.lock().unwrap_or_else(|e| e.into_inner());
        let mut found = Vec::new();
        let mut waiting = Vec::new();
        for back in restored.iter() {
            let (folder, uids) = match back {
                Back::There(folder, uids) => (*folder, uids.clone()),
                Back::Moving(folder, ids) => {
                    let uids = self.store().uids_of_message_ids(*folder, ids)?;
                    if uids.len() < ids.len() {
                        waiting.push(Back::Moving(*folder, ids.clone()));
                    }
                    (*folder, uids)
                }
            };
            found.extend(uids.into_iter().map(|uid| MessageRef { folder, uid }));
        }
        let taken = f(&found)?;
        // taken: what is there is forgotten, what Undo still waits for kept
        if taken.is_some() {
            *restored = waiting;
        }
        Ok(taken)
    }
}

/// The messages for the window to select once they are in its list ([`Core::restored`]), shared with the workers
pub(crate) type Restored = Arc<Mutex<Vec<Back>>>;

pub(crate) enum Back {
    /// Brought back by Undo, by Message-ID: in the folder again once the server has moved them and it is synced
    Moving(FolderId, Vec<String>),
    /// Taken back in the store as the server refused an action, by UID: in the folder already
    There(FolderId, Vec<u64>),
}

impl Core {
    /// The messages of `selected`, in the list's order: for a selection of a whole list, listed now
    pub fn selected_refs(&self, selected: &Selected) -> Result<Vec<MessageRef>> {
        match selected {
            Selected::Listed(refs) => Ok(refs.clone()),
            Selected::All { search, sort, .. } => {
                // one row a message: a collapsed conversation's messages each in their place
                let search = Search {
                    threads: None,
                    ..search.clone()
                };
                self.refs_in_ranges(&search, *sort, &[(0, i64::MAX as u64)])
            }
        }
    }

    /// [`Core::summary`] of `selected`; a whole list's counted where its messages are, never listed, so it takes what
    /// a count takes whatever the size of the list (its flag colour is not told)
    pub fn summary_of(&self, selected: &Selected) -> Result<Summary> {
        let search = match selected {
            Selected::Listed(refs) => return self.summary(refs),
            Selected::All { search, .. } => search,
        };
        let folders = self.store().search_summary(search)?;
        let mut summary = Summary {
            in_junk: !folders.is_empty(),
            archivable: !folders.is_empty(),
            ..Summary::default()
        };
        let (mut watched, mut ignored) = (0, 0);
        let mut accounts = BTreeSet::new();
        for found in &folders {
            let store = self.store();
            let (account, info) = store.folder_info(found.folder)?;
            accounts.insert(account);
            summary.folders += 1;
            summary.count += found.count;
            summary.unread += found.unread;
            summary.flagged += found.flagged;
            summary.in_junk &= info.special_use.as_deref() == Some("\\Junk");
            summary.archivable &= crate::archivable(&info);
            if crate::trash_in(&store, found.folder)?.is_none() {
                summary.for_good += found.count;
            }
            watched += found.watched;
            ignored += found.ignored;
        }
        summary.accounts = accounts.len() as u64;
        summary.watched = summary.count > 0 && watched == summary.count;
        summary.ignored = summary.count > 0 && ignored == summary.count;
        Ok(summary)
    }

    /// [`Core::act`] off the window thread: the messages of `selected` listed, changed in the store on a connection
    /// of the core's own (the list shows it with the [`Event::FolderChanged`] that follows) and handed to the server,
    /// after the actions asked for before it; then [`Event::Acted`] with the request this returns and what the
    /// status bar says, or why not. When the server does not do it, the store takes it back:
    /// [`Event::ActionUndone`].
    pub fn act_start(self: &Arc<Self>, selected: Selected, action: Action) -> Result<u64> {
        self.start_action(move |core| {
            let refs = core.selected_refs(&selected)?;
            core.act(&refs, action)
        })
    }

    /// Mark All Read off the window thread, as [`Core::act_start`] does an action: [`Event::Acted`] follows with what
    /// the status bar says ("Marked 3 messages as read")
    pub fn mark_read_start(self: &Arc<Self>, what: MarkRead) -> Result<u64> {
        self.start_action(move |core| {
            let count = match what {
                MarkRead::Folder(folder) => core.mark_all_read(folder)?,
                MarkRead::Account(account) => core.mark_account_read(account)?,
                MarkRead::AllInboxes => core.mark_all_inboxes_read()?,
            };
            Ok(tr_args(
                Text::DoneRead,
                &[("messages", (&messages(count)).into()), ("count", count.into())],
            ))
        })
    }

    /// Queues the action `act`: [`Event::Acted`] with the request this returns once it ran
    fn start_action(self: &Arc<Self>, act: impl FnOnce(&Core) -> Result<String> + Send + 'static) -> Result<u64> {
        let request = self.next_request.fetch_add(1, std::sync::atomic::Ordering::Relaxed);
        self.activity.action_queued();
        let queued = self.queue_action(Box::new(move |core| {
            let said = act(core).map_err(|error| error.to_string());
            (core.events)(crate::Event::Acted { request, said });
        }));
        if queued.is_err() {
            self.activity.action_done();
        }
        queued.map(|()| request)
    }
}

/// The flags of a message flagged in `color` (`\\Flagged` and its `$MailFlagBit` keywords), as added and removed;
/// None takes the flag away with its colour
fn color_flags(color: Option<FlagColor>) -> (Vec<&'static str>, Vec<&'static str>) {
    let Some(color) = color else {
        let mut remove = vec!["\\Flagged"];
        remove.extend(FLAG_COLOR_BITS);
        return (Vec::new(), remove);
    };
    let (mut add, mut remove) = (vec!["\\Flagged"], Vec::new());
    for (i, bit) in FLAG_COLOR_BITS.iter().enumerate() {
        if color.bits() & (1 << i) != 0 {
            add.push(*bit);
        } else {
            remove.push(*bit);
        }
    }
    (add, remove)
}

impl Core {
    /// Flags messages `uids` of `folder` in `color`, or takes their flag away with its colour (None)
    pub fn set_flag_color_many(&self, folder: FolderId, uids: &[u64], color: Option<FlagColor>) -> Result<()> {
        let (add, remove) = color_flags(color);
        self.change_flags_many(folder, uids, &add, &remove)
    }
}

/// The picked messages by folder, in folder order, each folder's in the order picked
fn by_folder(picked: &[Picked]) -> BTreeMap<FolderId, Vec<&Picked>> {
    let mut groups: BTreeMap<FolderId, Vec<&Picked>> = BTreeMap::new();
    for p in picked {
        groups.entry(p.at.folder).or_default().push(p);
    }
    groups
}

/// A flag colour's name, as the Flag menu lists them ("Orange"), in the language in use. Kept once a language and a
/// colour (seven colours, a handful of languages), so the windows can hold it as a `&'static str`.
pub fn color_name(color: FlagColor) -> &'static str {
    static NAMES: std::sync::Mutex<Vec<(&'static str, FlagColor, &'static str)>> = std::sync::Mutex::new(Vec::new());
    let language = pe_i18n::language();
    let mut names = NAMES.lock().unwrap_or_else(|e| e.into_inner());
    if let Some((_, _, name)) = names.iter().find(|(l, c, _)| *l == language && *c == color) {
        return name;
    }
    let name: &'static str = Box::leak(tr_args(Text::FlagColor, &[("color", color.id().into())]).into_boxed_str());
    names.push((language, color, name));
    name
}

#[cfg(test)]
mod background_tests {
    use super::*;
    use crate::list_load::tests::opened;
    use crate::{Event, ListView, Scope};
    use std::time::{Duration, Instant};

    /// Select All counts the list without listing it, grouped or not, and its summary and messages are those of
    /// every row selected
    #[test]
    fn select_all_counts_without_listing() {
        let dir = pe_testkit::TempDir::new("core-select-all");
        let (core, inbox, _events) = opened(&dir, 30);
        core.store().set_flag(inbox, 4, "\\Flagged", true).unwrap();
        for (grouped, open) in [(false, false), (true, false), (true, true)] {
            let mut view = ListView::new();
            view.set_scope(Some(Scope::Folder(inbox)));
            view.set_grouped(grouped);
            if open {
                view.expand_all(&core).unwrap();
            }
            let all = view.select_all(&core).unwrap();
            assert_eq!(all.count(), 30, "grouped {grouped}, open {open}");
            let rows = view.row_count(&core).unwrap();
            let listed = view.refs_in_ranges(&core, &[(0, rows)]).unwrap();
            let mut refs = core.selected_refs(&all).unwrap();
            assert_eq!(refs.len(), 30);
            refs.sort();
            let mut by_rows = listed.clone();
            by_rows.sort();
            assert_eq!(refs, by_rows, "grouped {grouped}, open {open}");
            let summary = core.summary_of(&all).unwrap();
            assert_eq!(
                summary,
                Summary {
                    flag_color: None,
                    ..core.summary(&listed).unwrap()
                }
            );
            assert_eq!((summary.count, summary.unread, summary.flagged), (30, 10, 1));
        }
        assert_eq!(
            ListView::new().select_all(&core).unwrap(),
            Selected::default(),
            "no list"
        );
    }

    /// Select All acts on what was there when it was chosen: mail stored after it (in the place of a message deleted
    /// meanwhile too, whose id SQLite would give again) is neither counted nor acted on, and the list read again with
    /// such mail in it no longer takes it as the whole list
    #[test]
    fn select_all_leaves_out_mail_stored_after_it() {
        let dir = pe_testkit::TempDir::new("core-select-all-bound");
        let (core, inbox, events) = opened(&dir, 30);
        let mut view = ListView::new();
        view.set_scope(Some(Scope::Folder(inbox)));
        let all = view.select_all(&core).unwrap();
        assert_eq!(all.count(), 30);
        // the newest message goes, and two come
        core.store().remove_messages(inbox, &[30]).unwrap();
        let new = |uid| pe_store::MessageInfo {
            uid,
            date: Some(10_000),
            subject: format!("new {uid}"),
            ..Default::default()
        };
        core.store().add_messages(inbox, &[new(100), new(101)]).unwrap();
        let refs = core.selected_refs(&all).unwrap();
        assert_eq!(refs.len(), 29, "the one gone is not acted on");
        assert!(refs.iter().all(|r| r.uid < 30), "nor are those stored after Select All");
        assert_eq!(core.summary_of(&all).unwrap().count, 29);

        // the action takes only them
        let flagged = core.act_start(all.clone(), Action::Flag(true)).unwrap();
        loop {
            if let Event::Acted { request, said } = events.recv_timeout(Duration::from_secs(20)).unwrap() {
                assert_eq!(request, flagged);
                assert_eq!(said, Ok("Flagged 29 messages".to_string()));
                break;
            }
        }
        let is_flagged = |uid| {
            let message = core.store().message(inbox, uid).unwrap().unwrap();
            message.info.flags.iter().any(|f| f == "\\Flagged")
        };
        assert!(is_flagged(1) && is_flagged(29));
        assert!(
            !is_flagged(100) && !is_flagged(101),
            "mail stored after Select All is not flagged"
        );

        // read again, the list has newer mail: no longer the whole list, but what Select All had, listed
        let mut again = all.clone();
        assert!(!view.select_all_again(&core, &mut again).unwrap());
        assert_eq!(again, Selected::Listed(refs));
        // chosen now, it is the whole list and stays so while nothing comes
        let mut all = view.select_all(&core).unwrap();
        assert_eq!(all.count(), 31);
        assert!(view.select_all_again(&core, &mut all).unwrap());
        assert_eq!(all.count(), 31);
        core.store().remove_messages(inbox, &[1]).unwrap();
        assert!(
            view.select_all_again(&core, &mut all).unwrap(),
            "one gone: still the whole list"
        );
        assert_eq!(all.count(), 30, "counted again");
    }

    /// The actions run off the calling thread one after another in the order asked, and say what they did
    #[test]
    fn actions_run_in_the_background_in_order() {
        let dir = pe_testkit::TempDir::new("core-act-start");
        let (core, inbox, events) = opened(&dir, 30);
        let at = |uid| MessageRef { folder: inbox, uid };
        // the calls return at once whatever the actions' connection is doing
        let held = crate::connections::open(&core.connections.actions, &dir.path().join("store.db")).unwrap();
        let asked = Instant::now();
        let read = core.mark_read_start(MarkRead::Folder(inbox)).unwrap();
        let unread = core
            .act_start(Selected::Listed(vec![at(1), at(2)]), Action::Read(false))
            .unwrap();
        let gone = core
            .act_start(Selected::Listed(vec![at(99)]), Action::Read(true))
            .unwrap();
        assert!(asked.elapsed() < Duration::from_millis(100));
        assert_eq!(core.folder(inbox).unwrap().unread, 10, "nothing done yet");
        drop(held);
        let mut said = Vec::new();
        while said.len() < 3 {
            if let Event::Acted { request, said: done } = events.recv_timeout(Duration::from_secs(20)).unwrap() {
                said.push((request, done));
            }
        }
        assert_eq!(
            said,
            [
                (read, Ok("Marked 10 messages as read".to_string())),
                (unread, Ok("Marked 2 messages as unread".to_string())),
                (gone, Err("The messages are no longer there.".to_string())),
            ],
            "in the order asked"
        );
        assert_eq!(core.folder(inbox).unwrap().unread, 2);
    }
}
