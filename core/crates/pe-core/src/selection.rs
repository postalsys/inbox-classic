//! What the windows do to the messages selected in a list, one or many, from one folder or from several (All Inboxes,
//! a search): read and unread, flag, junk, delete, move and copy, each folder's messages with one command; what to
//! call it in the status bar; and Edit > Undo for the last move, delete or junk.

use std::collections::BTreeMap;

use pe_store::{FolderId, MessageRef, Picked, Search, Sort};

use crate::text::messages;
use crate::{Core, Error, Result};

/// The most UIDs one command carries, so a command line stays short whatever was selected (a UID set of messages
/// that are not next to each other is as long as its UIDs)
const PER_COMMAND: usize = 1000;

/// What to do to the selected messages
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum Action {
    /// Read (true) or unread
    Read(bool),
    /// Flag (true) or take the flag away
    Flag(bool),
    /// Junk (true), into Junk E-mail; not junk, into the Inbox
    Junk(bool),
    /// Into Deleted Items, or for good from there and from an account without one ([`Core::delete_question`])
    Delete,
    Move(FolderId),
    Copy(FolderId),
}

/// The selected messages in numbers, for the reading pane, the status bar and which commands apply
#[derive(Debug, Clone, Default, PartialEq, Eq)]
pub struct Summary {
    pub count: u64,
    pub unread: u64,
    pub flagged: u64,
    /// Every one of them is in a Junk folder (Mark as Not Junk applies, not Mark as Junk)
    pub in_junk: bool,
    /// How many accounts and folders they are in
    pub accounts: u64,
    pub folders: u64,
    /// How many of them Delete removes for good
    pub for_good: u64,
}

impl Summary {
    /// "3 messages selected" for the reading pane
    pub fn title(&self) -> String {
        format!("{} selected", messages(self.count))
    }

    /// "2 unread, 1 flagged" under it; empty when neither
    pub fn detail(&self) -> String {
        let mut parts = Vec::new();
        if self.unread > 0 {
            parts.push(format!("{} unread", self.unread));
        }
        if self.flagged > 0 {
            parts.push(format!("{} flagged", self.flagged));
        }
        parts.join(", ")
    }
}

/// What Edit > Undo takes back: messages that went from one folder to another, found again by their Message-IDs
#[derive(Debug, Clone, PartialEq, Eq)]
pub(crate) struct Undo {
    /// "Undo Move" without its "Undo"
    what: &'static str,
    moves: Vec<UndoMove>,
}

#[derive(Debug, Clone, PartialEq, Eq)]
struct UndoMove {
    from: FolderId,
    to: FolderId,
    message_ids: Vec<String>,
    /// A flag junk set, taken away again before they go back
    flag: Option<&'static str>,
}

impl Core {
    /// The messages at positions `ranges` (start included, end not) of the list `search` and `sort` make, as the
    /// windows' selections are kept: in the list's order
    pub fn refs_in_ranges(&self, search: &Search, sort: Sort, ranges: &[(u64, u64)]) -> Result<Vec<MessageRef>> {
        Ok(self.store().refs_in_ranges(search, sort, ranges)?)
    }

    /// Where the messages `refs` are now in that list, ascending, to select them again after it changed
    pub fn positions(&self, search: &Search, sort: Sort, refs: &[MessageRef]) -> Result<Vec<u64>> {
        Ok(self.store().positions(search, sort, refs)?)
    }

    /// The selected messages in numbers; those that are gone meanwhile are not counted
    pub fn summary(&self, refs: &[MessageRef]) -> Result<Summary> {
        let store = self.store();
        let picked = store.picked(refs)?;
        let mut summary = Summary {
            count: picked.len() as u64,
            in_junk: !picked.is_empty(),
            ..Summary::default()
        };
        let mut accounts = Vec::new();
        for (folder, group) in by_folder(&picked) {
            let info = store.folder(folder)?;
            if !accounts.contains(&info.account_id) {
                accounts.push(info.account_id);
            }
            summary.folders += 1;
            summary.in_junk &= info.info.special_use.as_deref() == Some("\\Junk");
            let trash = store.special_folder(info.account_id, "\\Trash")?.map(|t| t.id);
            if trash.is_none() || trash == Some(folder) {
                summary.for_good += group.len() as u64;
            }
            for p in group {
                summary.unread += u64::from(!p.has_flag("\\Seen"));
                summary.flagged += u64::from(p.has_flag("\\Flagged"));
            }
        }
        summary.accounts = accounts.len() as u64;
        Ok(summary)
    }

    /// What to ask before Delete when it removes some of them for good; None when it removes none
    pub fn delete_question(&self, refs: &[MessageRef]) -> Result<Option<String>> {
        let summary = self.summary(refs)?;
        Ok(match (summary.for_good, summary.count) {
            (0, _) => None,
            (1, 1) => Some("This message will be deleted for good. Delete it?".into()),
            (n, all) if n == all => Some(format!("These {n} messages will be deleted for good. Delete them?")),
            (n, all) => Some(format!(
                "{n} of the {all} messages will be deleted for good. Delete the messages?"
            )),
        })
    }

    /// Does `action` to the messages `refs` (those still there), each folder's with one command: in the store now,
    /// on the server in the background, as the actions on one message do. Returns what the status bar says, "Moved 3
    /// messages to Archive". A move, delete into Deleted Items or junk becomes what Edit > Undo takes back.
    pub fn act(&self, refs: &[MessageRef], action: Action) -> Result<String> {
        let picked = self.store().picked(refs)?;
        if picked.is_empty() {
            return Err(Error::NotFound);
        }
        let groups = by_folder(&picked);
        if let Action::Move(to) | Action::Copy(to) = action {
            self.check_target(groups.keys().copied(), to)?;
        }
        let mut undo = Vec::new();
        for (folder, group) in &groups {
            let uids: Vec<u64> = group.iter().map(|p| p.at.uid).collect();
            let went = self.act_on_folder(*folder, &uids, action)?;
            if let Some((to, flag)) = went {
                undo.push(UndoMove {
                    from: *folder,
                    to,
                    message_ids: group.iter().filter_map(|p| p.message_id.clone()).collect(),
                    flag,
                });
            }
        }
        let count = picked.len() as u64;
        let what = match action {
            Action::Move(_) => Some("Move"),
            Action::Delete => Some("Delete"),
            Action::Junk(true) => Some("Mark as Junk"),
            Action::Junk(false) => Some("Mark as Not Junk"),
            _ => None,
        };
        let text = self.done_text(action, count, &undo)?;
        // what moved can be taken back; what is gone for good ends what came before it
        if let Some(what) = what {
            *self.undo.lock().unwrap_or_else(|e| e.into_inner()) =
                (!undo.is_empty()).then_some(Undo { what, moves: undo });
        }
        Ok(text)
    }

    /// Where messages can go from `folders`: a folder of the same account that holds messages. Checked for all before
    /// any of them moves.
    fn check_target(&self, folders: impl Iterator<Item = FolderId>, to: FolderId) -> Result<()> {
        let store = self.store();
        let target = store.folder(to)?;
        for folder in folders {
            if store.folder(folder)?.account_id != target.account_id || !target.info.selectable {
                return Err(Error::NotFound);
            }
        }
        Ok(())
    }

    /// One folder's part of [`Core::act`], a command per [`PER_COMMAND`] messages. Returns where they went and the
    /// flag set on the way, when they moved.
    fn act_on_folder(
        &self,
        folder: FolderId,
        uids: &[u64],
        action: Action,
    ) -> Result<Option<(FolderId, Option<&'static str>)>> {
        let went = match action {
            Action::Delete => self.trash_for(folder)?.map(|trash| (trash, None)),
            Action::Move(to) if to != folder => Some((to, None)),
            Action::Junk(junk) => self
                .junk_target(folder, junk)?
                .filter(|&to| to != folder)
                .map(|to| (to, Some(if junk { "$Junk" } else { "$NotJunk" }))),
            _ => None,
        };
        for chunk in uids.chunks(PER_COMMAND) {
            match action {
                Action::Read(on) => self.set_flag_many(folder, chunk, "\\Seen", on)?,
                Action::Flag(on) => self.set_flag_many(folder, chunk, "\\Flagged", on)?,
                Action::Junk(junk) => self.mark_junk_many(folder, chunk, junk)?,
                Action::Delete => self.delete_messages(folder, chunk)?,
                // already there: nothing to do
                Action::Move(to) | Action::Copy(to) if to == folder => {}
                Action::Move(to) => self.move_messages(folder, chunk, to)?,
                Action::Copy(to) => self.copy_messages(folder, chunk, to)?,
            }
        }
        Ok(went)
    }

    /// The folder junk (or not junk) goes to from `folder`: the account's Junk folder, or its Inbox
    fn junk_target(&self, folder: FolderId, junk: bool) -> Result<Option<FolderId>> {
        let store = self.store();
        let account = store.folder(folder)?.account_id;
        let target = if junk {
            store.special_folder(account, "\\Junk")?
        } else {
            store.find_folder(account, "INBOX")?
        };
        Ok(target.map(|f| f.id))
    }

    /// What the status bar says once `action` is done to `count` messages
    fn done_text(&self, action: Action, count: u64, moved: &[UndoMove]) -> Result<String> {
        let n = messages(count);
        Ok(match action {
            Action::Read(true) => format!("Marked {n} as read"),
            Action::Read(false) => format!("Marked {n} as unread"),
            Action::Flag(true) => format!("Flagged {n}"),
            Action::Flag(false) => format!("Took the flag off {n}"),
            Action::Delete if moved.is_empty() => format!("Deleted {n} for good"),
            Action::Delete | Action::Junk(_) => format!("Moved {n} to {}", self.places(moved.iter().map(|m| m.to))?),
            Action::Move(to) => format!("Moved {n} to {}", self.places([to].into_iter())?),
            Action::Copy(to) => format!("Copied {n} to {}", self.places([to].into_iter())?),
        })
    }

    /// The name of the folder they all went to, or "their folders" when they went to several
    fn places(&self, folders: impl Iterator<Item = FolderId>) -> Result<String> {
        let mut folders: Vec<FolderId> = folders.collect();
        folders.sort_unstable();
        folders.dedup();
        match folders.as_slice() {
            [one] => Ok(crate::text::folder_name(&self.store().folder(*one)?.info)),
            _ => Ok("their folders".into()),
        }
    }

    /// What Edit > Undo says it takes back, "Undo Move"; None when there is nothing
    pub fn undo_label(&self) -> Option<String> {
        let undo = self.undo.lock().unwrap_or_else(|e| e.into_inner());
        undo.as_ref().map(|u| format!("Undo {}", u.what))
    }

    /// Takes back the last move, delete into Deleted Items or junk: the messages go back to the folders they came
    /// from, found by their Message-IDs where they went. Returns what the status bar says. Refused when none of them is
    /// there (yet: the folder they went to has not shown them).
    pub fn undo(&self) -> Result<String> {
        let undo = self.undo.lock().unwrap_or_else(|e| e.into_inner()).take();
        let Some(undo) = undo else {
            return Err(Error::NotFound);
        };
        let mut back = 0;
        let mut found = Vec::new();
        for m in &undo.moves {
            let uids = self.store().uids_of_message_ids(m.to, &m.message_ids)?;
            if !uids.is_empty() {
                found.push((m, uids));
            }
        }
        if found.is_empty() {
            // kept for another try, once the folder they went to shows them
            *self.undo.lock().unwrap_or_else(|e| e.into_inner()) = Some(undo);
            return Err(Error::Unavailable(
                "The messages are not in the folder they went to yet. Try again in a moment.".into(),
            ));
        }
        for (m, uids) in &found {
            for chunk in uids.chunks(PER_COMMAND) {
                if let Some(flag) = m.flag {
                    self.set_flag_many(m.to, chunk, flag, false)?;
                }
                self.move_messages(m.to, chunk, m.from)?;
            }
            back += uids.len() as u64;
        }
        Ok(format!(
            "Moved {} back to {}",
            messages(back),
            self.places(found.iter().map(|(m, _)| m.from))?
        ))
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
