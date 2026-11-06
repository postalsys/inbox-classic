//! What the windows do to the messages selected in a list, one or many, from one folder or from several (All Inboxes,
//! a search): read and unread, flag, junk, delete, move and copy, each folder's messages with one command; what to
//! call it in the status bar; and Edit > Undo for the last move, delete or junk.

use std::collections::{BTreeMap, BTreeSet};

use pe_store::{FLAG_COLOR_BITS, FlagColor, FolderId, MessageRef, Picked, Search, Sort};

use crate::text::messages;
use crate::worker::Command;
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
    /// Flag them when one is not flagged, take the flags away when all are ([`Summary::flags`])
    ToggleFlag,
    /// Flag them in a colour, as Apple Mail does (`\\Flagged` and its `$MailFlagBit` keywords)
    FlagColor(FlagColor),
    /// Junk (true), into Junk E-mail; not junk, into the Inbox
    Junk(bool),
    /// Into Deleted Items, or for good from there and from an account without one ([`Summary::delete_question`])
    Delete,
    Move(FolderId),
    Copy(FolderId),
}

impl Action {
    /// What Edit > Undo calls taking it back ("Move" for "Undo Move"); None for what is not taken back
    fn undo_name(self) -> Option<&'static str> {
        match self {
            Action::Move(_) => Some("Move"),
            Action::Delete => Some("Delete"),
            Action::Junk(true) => Some("Mark as Junk"),
            Action::Junk(false) => Some("Mark as Not Junk"),
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

    /// The reading pane's page over several messages, in the style of its other states ([`crate::reader_page`])
    pub fn page(&self) -> String {
        pe_html::status_page(&self.title(), &self.detail(), false)
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

    /// Whether Flag flags them (one is not flagged) or takes the flags away (all are)
    pub fn flags(&self) -> bool {
        self.flagged < self.count
    }

    /// The title of the Move or Copy window (`copy`): "Move 3 Messages", "Copy Message"
    pub fn move_title(&self, copy: bool) -> String {
        let verb = if copy { "Copy" } else { "Move" };
        if self.count == 1 {
            format!("{verb} Message")
        } else {
            format!("{verb} {} Messages", self.count)
        }
    }

    /// What the Move or Copy window says over its folders: "Move the 3 selected messages to:"
    pub fn move_prompt(&self, copy: bool) -> String {
        let verb = if copy { "Copy" } else { "Move" };
        if self.count == 1 {
            format!("{verb} the selected message to:")
        } else {
            format!("{verb} the {} selected messages to:", self.count)
        }
    }

    /// What to ask before Delete when it removes some of them for good; None when it removes none
    pub fn delete_question(&self) -> Option<String> {
        match (self.for_good, self.count) {
            (0, _) => None,
            (1, 1) => Some("This message will be deleted for good. Delete it?".into()),
            (n, all) if n == all => Some(format!("These {n} messages will be deleted for good. Delete them?")),
            (n, all) => Some(format!(
                "{n} of the {all} messages will be deleted for good. Delete the messages?"
            )),
        }
    }
}

/// What Edit > Undo takes back: messages that went from one folder to another, found again by their Message-IDs
#[derive(Debug, Clone, PartialEq, Eq)]
pub(crate) struct Undo {
    /// "Undo Move" without its "Undo"
    what: &'static str,
    moves: Vec<UndoMove>,
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
        let mut accounts = BTreeSet::new();
        let mut colors = BTreeSet::new();
        for (folder, group) in by_folder(&picked) {
            let info = store.folder(folder)?;
            accounts.insert(info.account_id);
            summary.folders += 1;
            summary.in_junk &= info.info.special_use.as_deref() == Some("\\Junk");
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
        let picked = self.store().picked(refs)?;
        if picked.is_empty() {
            return Err(Error::Unavailable("The messages are no longer there.".into()));
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
                    return Err(Error::Unavailable("That folder does not hold messages.".into()));
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
                Some(account) => self.store().folder(*folder)?.account_id != account,
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
                });
            }
        }
        let text = self.done_text(action, picked.len() as u64, &undo, crossed)?;
        // what moved can be taken back; what is gone for good ends what came before it
        if let Some(what) = undo_name {
            *self.undo.lock().unwrap_or_else(|e| e.into_inner()) =
                (!undo.is_empty()).then_some(Undo { what, moves: undo });
        }
        Ok(text)
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
            _ => None,
        };
        for chunk in uids.chunks(PER_COMMAND) {
            match action {
                Action::Read(on) => self.set_flag_many(folder, chunk, "\\Seen", on)?,
                Action::Flag(true) => self.set_flag_many(folder, chunk, "\\Flagged", true)?,
                // the colour goes with the flag
                Action::Flag(false) => {
                    let mut remove = vec!["\\Flagged"];
                    remove.extend(FLAG_COLOR_BITS);
                    self.change_flags_many(folder, chunk, &[], &remove)?
                }
                Action::FlagColor(color) => {
                    let (mut add, mut remove) = (vec!["\\Flagged"], Vec::new());
                    for (i, bit) in FLAG_COLOR_BITS.iter().enumerate() {
                        if color.bits() & (1 << i) != 0 {
                            add.push(*bit);
                        } else {
                            remove.push(*bit);
                        }
                    }
                    self.change_flags_many(folder, chunk, &add, &remove)?
                }
                Action::Junk(junk) => self.mark_junk_many(folder, chunk, junk)?,
                Action::Delete => self.delete_messages(folder, chunk)?,
                Action::Move(_) | Action::Copy(_) | Action::ToggleFlag => unreachable!("handled before"),
            }
        }
        Ok(went)
    }

    /// What the status bar says once `action` is done to `count` messages
    fn done_text(&self, action: Action, count: u64, moved: &[UndoMove], crossed: bool) -> Result<String> {
        let n = messages(count);
        Ok(match action {
            Action::ToggleFlag => unreachable!("resolved by act"),
            Action::Read(true) => format!("Marked {n} as read"),
            Action::Read(false) => format!("Marked {n} as unread"),
            Action::Flag(true) => format!("Flagged {n}"),
            Action::Flag(false) => format!("Took the flag off {n}"),
            Action::FlagColor(color) => format!("Flagged {n} {}", color_name(color).to_lowercase()),
            Action::Delete if moved.is_empty() => format!("Deleted {n} for good"),
            Action::Delete | Action::Junk(_) => format!("Moved {n} to {}", self.places(moved.iter().map(|m| m.to))?),
            // to another account they go in the background, Event::Transferring says how far
            Action::Move(to) if crossed => format!("Moving {n} to {}...", self.places([to].into_iter())?),
            Action::Copy(to) if crossed => format!("Copying {n} to {}...", self.places([to].into_iter())?),
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

    /// The folders messages were moved or copied to last, the newest first, for the Move and Copy window
    pub fn recent_targets(&self, limit: u64) -> Result<Vec<FolderId>> {
        Ok(self.store().recent_targets(limit)?)
    }

    /// What Edit > Undo says it takes back, "Undo Move"; None when there is nothing
    pub fn undo_label(&self) -> Option<String> {
        let undo = self.undo.lock().unwrap_or_else(|e| e.into_inner());
        undo.as_ref().map(|u| format!("Undo {}", u.what))
    }

    /// Takes back the last move, delete into Deleted Items or junk: the messages go back to the folders they came
    /// from, found by their Message-IDs where they went, by the worker of their account (after the move it takes back,
    /// however soon it is asked). Returns what the status bar says.
    pub fn undo(&self) -> Result<String> {
        let undo = self.undo.lock().unwrap_or_else(|e| e.into_inner()).take();
        let Some(undo) = undo else {
            return Err(Error::Unavailable("There is nothing to undo.".into()));
        };
        let mut by_account: BTreeMap<pe_store::AccountId, Vec<UndoMove>> = BTreeMap::new();
        for m in &undo.moves {
            let account = self.store().folder(m.to)?.account_id;
            by_account.entry(account).or_default().push(m.clone());
        }
        for (account, moves) in by_account {
            self.send_command(account, Command::UndoMoves { moves })?;
        }
        let back = undo.moves.iter().map(|m| m.message_ids.len() as u64).sum();
        *self.restored.lock().unwrap_or_else(|e| e.into_inner()) =
            undo.moves.iter().map(|m| (m.from, m.message_ids.clone())).collect();
        Ok(format!(
            "Moved {} back to {}",
            messages(back),
            self.places(undo.moves.iter().map(|m| m.from))?
        ))
    }

    /// The messages the last Undo brought back that are in their folders again (they get there once the server has
    /// moved them and the folder is synced), for the window to select them. Forgotten once all are there.
    pub fn restored(&self) -> Result<Vec<MessageRef>> {
        let mut restored = self.restored.lock().unwrap_or_else(|e| e.into_inner());
        let mut found = Vec::new();
        let mut all = true;
        for (folder, ids) in restored.iter() {
            let uids = self.store().uids_of_message_ids(*folder, ids)?;
            all &= uids.len() >= ids.len();
            found.extend(uids.into_iter().map(|uid| MessageRef { folder: *folder, uid }));
        }
        if all {
            restored.clear();
        }
        Ok(found)
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

/// A flag colour's name, as the Flag menu lists them
pub fn color_name(color: FlagColor) -> &'static str {
    match color {
        FlagColor::Red => "Red",
        FlagColor::Orange => "Orange",
        FlagColor::Yellow => "Yellow",
        FlagColor::Green => "Green",
        FlagColor::Blue => "Blue",
        FlagColor::Purple => "Purple",
        FlagColor::Gray => "Gray",
    }
}
