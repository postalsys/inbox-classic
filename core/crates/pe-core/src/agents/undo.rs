//! Taking back what agents did: one entry of the log (its Undo in the AI Agents window, or an agent's own
//! `undo_my_change`), one change of many messages with one Undo All, and everything a program did since a moment, newest
//! first. Each message goes back only while it is as the change left it: one the user or the server changed since is
//! left alone, and the report says, in plain words, what could not be taken back.

use std::collections::BTreeMap;

use pe_i18n::{Text, tr, tr_args};
use pe_store::{AccountId, AgentHostId, AgentLogEntry, FlagColor, FolderId, MessageRef};

use super::{AgentHost, host_one, now};
use crate::{Core, Error, Event, Result};

/// How a change of an agent is taken back, as the log keeps it
#[derive(Debug, Clone, PartialEq, Eq)]
pub enum Undo {
    /// The flag of the message in `folder` was `was` before
    Flag {
        folder: FolderId,
        uid: u64,
        flag: String,
        was: bool,
    },
    /// The message with `message_id` went from `from` to `to`
    Move {
        from: FolderId,
        to: FolderId,
        message_id: String,
    },
    /// The message with `message_id` waits in the Outbox of `account`
    Unsend { account: AccountId, message_id: String },
    /// The message with `message_id` was archived from `from` (into the Archive folder, or off its Gmail labels)
    Archive { from: FolderId, message_id: String },
    /// The message with `message_id` was marked junk (or not junk) in `from` and went to `to` (the same folder when
    /// it was there already)
    Junk {
        from: FolderId,
        to: FolderId,
        junk: bool,
        message_id: String,
    },
    /// The message in `folder` was flagged in colour `was`, or not flagged (None)
    Color {
        folder: FolderId,
        uid: u64,
        was: Option<FlagColor>,
    },
    /// One change of many messages (apply_to_search): each message's own, taken back together (Undo All)
    Many(Vec<Undo>),
}

/// The first word of [`Undo::Many`] as the log keeps it, each message's on a line of its own after it
const MANY: &str = "many";

impl Undo {
    pub fn write(&self) -> String {
        match self {
            Undo::Many(items) => std::iter::once(MANY.to_string())
                .chain(items.iter().map(Undo::write_one))
                .collect::<Vec<_>>()
                .join("\n"),
            one => one.write_one(),
        }
    }

    /// One message's, on one line
    fn write_one(&self) -> String {
        let line = match self {
            Undo::Flag { folder, uid, flag, was } => format!("flag {folder} {uid} {} {flag}", u8::from(*was)),
            Undo::Move { from, to, message_id } => format!("move {from} {to} {message_id}"),
            Undo::Unsend { account, message_id } => format!("unsend {account} {message_id}"),
            Undo::Archive { from, message_id } => format!("archive {from} {message_id}"),
            Undo::Junk {
                from,
                to,
                junk,
                message_id,
            } => format!("junk {from} {to} {} {message_id}", u8::from(*junk)),
            Undo::Color { folder, uid, was } => {
                format!("color {folder} {uid} {}", was.map_or("none", FlagColor::id))
            }
            // never one inside another
            Undo::Many(_) => String::new(),
        };
        line.replace(['\r', '\n'], " ")
    }

    pub(crate) fn read(text: &str) -> Option<Undo> {
        match text.strip_prefix(MANY) {
            Some(rest) if rest.is_empty() || rest.starts_with('\n') => rest
                .lines()
                .skip(1)
                .map(Undo::read_one)
                .collect::<Option<_>>()
                .map(Undo::Many),
            _ => Undo::read_one(text),
        }
    }

    fn read_one(text: &str) -> Option<Undo> {
        // words, the last one (a flag, a Message-ID) being the rest of the line
        let words = |count: usize| -> Vec<&str> { text.splitn(count, ' ').collect() };
        match text.split(' ').next()? {
            "flag" => match words(5)[..] {
                [_, folder, uid, was, flag] => Some(Undo::Flag {
                    folder: folder.parse().ok()?,
                    uid: uid.parse().ok()?,
                    was: was == "1",
                    flag: flag.to_string(),
                }),
                _ => None,
            },
            "move" => match words(4)[..] {
                [_, from, to, message_id] => Some(Undo::Move {
                    from: from.parse().ok()?,
                    to: to.parse().ok()?,
                    message_id: message_id.to_string(),
                }),
                _ => None,
            },
            "archive" => match words(3)[..] {
                [_, from, message_id] => Some(Undo::Archive {
                    from: from.parse().ok()?,
                    message_id: message_id.to_string(),
                }),
                _ => None,
            },
            "junk" => match words(5)[..] {
                [_, from, to, junk, message_id] => Some(Undo::Junk {
                    from: from.parse().ok()?,
                    to: to.parse().ok()?,
                    junk: junk == "1",
                    message_id: message_id.to_string(),
                }),
                _ => None,
            },
            "color" => match words(4)[..] {
                [_, folder, uid, was] => Some(Undo::Color {
                    folder: folder.parse().ok()?,
                    uid: uid.parse().ok()?,
                    was: FlagColor::ALL.into_iter().find(|c| c.id() == was),
                }),
                _ => None,
            },
            "unsend" => match words(3)[..] {
                [_, account, message_id] => Some(Undo::Unsend {
                    account: account.parse().ok()?,
                    message_id: message_id.to_string(),
                }),
                _ => None,
            },
            _ => None,
        }
    }

    /// Each message's undo
    fn items(self) -> Vec<Undo> {
        match self {
            Undo::Many(items) => items,
            one => vec![one],
        }
    }
}

/// The flags a change of an agent can set, as the store names them
pub fn flag_name(flag: &str) -> Option<&'static str> {
    match flag {
        "\\Seen" => Some("\\Seen"),
        "\\Flagged" => Some("\\Flagged"),
        _ => None,
    }
}

/// What taking back did, in numbers of messages, and why the rest was left
#[derive(Debug, Clone, Default, PartialEq, Eq)]
pub struct UndoReport {
    /// The entries of the log taken back, wholly or in part
    pub entries: u64,
    /// The messages (and messages in the Outbox) put back
    pub undone: u64,
    /// Not where the change put them: moved or deleted since, or not in the folder they went to yet
    pub gone: u64,
    /// Changed since, by the user or on the server: left as they are
    pub changed: u64,
    /// Gone from the Outbox: sent
    pub sent: u64,
    /// Entries that can not be taken back at all
    pub impossible: u64,
    /// Why the first that was left was left, for the refusal of one entry
    first: Option<Text>,
}

impl UndoReport {
    fn left(&mut self, why: Text, count: u64) {
        if count == 0 {
            return;
        }
        let field = match why {
            Text::AgentUndoSent => &mut self.sent,
            Text::AgentUndoChanged => &mut self.changed,
            Text::AgentUndoImpossible => &mut self.impossible,
            _ => &mut self.gone,
        };
        *field += count;
        self.first.get_or_insert(why);
    }

    /// Why nothing was taken back, in a few words ("the message is no longer in the Outbox"); None when something was
    pub fn refusal(&self) -> Option<String> {
        (self.undone == 0).then(|| tr(self.first.unwrap_or(Text::AgentUndoImpossible)))
    }

    /// What was taken back, in a sentence: "Took back 3 changes."
    pub fn summary(&self) -> String {
        tr_args(Text::AgentUndoDone, &[("count", self.entries.into())])
    }

    /// What was left and why, a sentence each; empty when nothing was
    pub fn left_lines(&self) -> Vec<String> {
        [
            (self.gone, Text::AgentUndoLeftGone),
            (self.changed, Text::AgentUndoLeftChanged),
            (self.sent, Text::AgentUndoLeftSent),
            (self.impossible, Text::AgentUndoLeftImpossible),
        ]
        .into_iter()
        .filter(|(count, _)| *count > 0)
        .map(|(count, text)| tr_args(text, &[("count", count.into())]))
        .collect()
    }

    /// Everything to tell the user: the summary, then what was left, a line each
    pub fn text(&self) -> String {
        std::iter::once(self.summary())
            .chain(self.left_lines())
            .collect::<Vec<_>>()
            .join("\n")
    }

    /// Nothing was left behind
    pub fn whole(&self) -> bool {
        self.gone + self.changed + self.sent + self.impossible == 0
    }
}

/// How far back "Undo everything since..." reaches, as the AI Agents window offers it: a word for its label and the
/// seconds before now
pub const UNDO_SPANS: [(&str, i64); 6] = [
    ("quarter", 15 * 60),
    ("hour", 3600),
    ("hours", 4 * 3600),
    ("day", 86_400),
    ("week", 7 * 86_400),
    ("all", pe_store::LOG_KEPT),
];

/// The label of span `index` of [`UNDO_SPANS`], "In the last hour"; None past the end
pub fn undo_span_label(index: usize) -> Option<String> {
    let (span, _) = UNDO_SPANS.get(index)?;
    Some(tr_args(Text::AgentUndoSpan, &[("span", (*span).into())]))
}

/// The moment span `index` reaches back to from now; None past the end
pub fn undo_span_since(index: usize) -> Option<i64> {
    UNDO_SPANS.get(index).map(|(_, seconds)| now() - seconds)
}

/// The question before taking back the `count` changes `host` made in a span, and the words under it
pub fn undo_since_question(host: &AgentHost, count: u64) -> (String, String) {
    let program = host_one(host);
    (
        tr_args(
            Text::AgentUndoSinceQuestion,
            &[("program", (&program).into()), ("count", count.into())],
        ),
        tr(Text::AgentUndoSinceDetail),
    )
}

/// `item` under `key` in `groups`
fn group<K: Ord, V>(groups: &mut BTreeMap<K, Vec<V>>, key: K, item: V) {
    groups.entry(key).or_default().push(item);
}

/// The undos of messages put together the way they are taken back: a command for each folder's
#[derive(Default)]
struct Groups {
    flags: BTreeMap<(FolderId, String, bool), Vec<u64>>,
    colors: BTreeMap<(FolderId, Option<FlagColor>), Vec<u64>>,
    /// (from, to, junk keyword taken away first)
    moves: BTreeMap<(FolderId, FolderId, Option<bool>), Vec<String>>,
    archives: BTreeMap<FolderId, Vec<String>>,
    unsend: Vec<(AccountId, String)>,
}

impl Groups {
    fn of(items: Vec<Undo>) -> Groups {
        let mut groups = Groups::default();
        for item in items {
            match item {
                Undo::Flag { folder, uid, flag, was } => group(&mut groups.flags, (folder, flag, was), uid),
                Undo::Color { folder, uid, was } => group(&mut groups.colors, (folder, was), uid),
                Undo::Move { from, to, message_id } => group(&mut groups.moves, (from, to, None), message_id),
                Undo::Junk {
                    from,
                    to,
                    junk,
                    message_id,
                } => group(&mut groups.moves, (from, to, Some(junk)), message_id),
                Undo::Archive { from, message_id } => group(&mut groups.archives, from, message_id),
                Undo::Unsend { account, message_id } => groups.unsend.push((account, message_id)),
                Undo::Many(_) => {}
            }
        }
        groups
    }
}

impl Core {
    /// The messages `uids` of `folder` that are still there, as the store has them
    fn still_there(&self, folder: FolderId, uids: &[u64]) -> Result<Vec<pe_store::Picked>> {
        let refs: Vec<MessageRef> = uids.iter().map(|&uid| MessageRef { folder, uid }).collect();
        Ok(self.store().picked(&refs)?)
    }

    /// Puts `flag` of messages `uids` of `folder` back to `was`, those still as the change left them
    fn undo_flags(
        &self,
        (folder, flag, was): (FolderId, String, bool),
        uids: &[u64],
        report: &mut UndoReport,
    ) -> Result<()> {
        let Some(flag) = flag_name(&flag) else {
            report.left(Text::AgentUndoImpossible, uids.len() as u64);
            return Ok(());
        };
        let there = self.still_there(folder, uids)?;
        report.left(Text::AgentUndoNotInFolder, (uids.len() - there.len()) as u64);
        let (back, changed): (Vec<_>, Vec<_>) = there.iter().partition(|p| p.has_flag(flag) != was);
        report.left(Text::AgentUndoChanged, changed.len() as u64);
        let back: Vec<u64> = back.iter().map(|p| p.at.uid).collect();
        if back.is_empty() {
            return Ok(());
        }
        if flag == "\\Flagged" && !was {
            // a flag taken away takes its colour along
            self.set_flag_color_many(folder, &back, None)?;
        } else {
            self.set_flag_many(folder, &back, flag, was)?;
        }
        report.undone += back.len() as u64;
        Ok(())
    }

    /// Puts the flag colour of messages `uids` of `folder` back to `was`
    fn undo_colors(
        &self,
        (folder, was): (FolderId, Option<FlagColor>),
        uids: &[u64],
        report: &mut UndoReport,
    ) -> Result<()> {
        let there: Vec<u64> = self.still_there(folder, uids)?.iter().map(|p| p.at.uid).collect();
        report.left(Text::AgentUndoNotInFolder, (uids.len() - there.len()) as u64);
        if !there.is_empty() {
            self.set_flag_color_many(folder, &there, was)?;
            report.undone += there.len() as u64;
        }
        Ok(())
    }

    /// Moves the messages with `message_ids` back from `to` to `from`, those that are in `to`; with `junk`, the
    /// keyword marking them junk (or not junk) taken away first
    fn undo_moves(
        &self,
        (from, to, junk): (FolderId, FolderId, Option<bool>),
        message_ids: &[String],
        report: &mut UndoReport,
    ) -> Result<()> {
        let uids = self.store().uids_of_message_ids(to, message_ids)?;
        report.left(
            Text::AgentUndoNotArrived,
            (message_ids.len() - uids.len().min(message_ids.len())) as u64,
        );
        if uids.is_empty() {
            return Ok(());
        }
        if let Some(junk) = junk {
            let (given, _) = crate::junk_keywords(junk);
            self.set_flag_many(to, &uids, given, false)?;
        }
        if to != from {
            self.move_messages(to, &uids, from)?;
        }
        report.undone += uids.len() as u64;
        Ok(())
    }

    /// Brings archived messages back to `from`: the worker finds them where archiving put them
    fn undo_archives(&self, from: FolderId, message_ids: Vec<String>, report: &mut UndoReport) -> Result<()> {
        let account = self.store().folder(from)?.account_id;
        report.undone += message_ids.len() as u64;
        self.send_command(
            account,
            crate::worker::Command::UndoMoves {
                moves: vec![crate::selection::UndoMove {
                    from,
                    to: from,
                    message_ids,
                    flag: None,
                    archived: true,
                }],
            },
        )
    }

    /// Takes a message an agent sent out of the Outbox, while it still waits there
    fn undo_unsend(&self, account: AccountId, message_id: &str, report: &mut UndoReport) -> Result<()> {
        // the store's guard let go before deleting, which takes it again
        let queued = self.store().outbox_with_message_id(account, message_id)?;
        match queued {
            Some(queued) => {
                self.outbox_delete(queued)?;
                report.undone += 1;
            }
            None => report.left(Text::AgentUndoSent, 1),
        }
        Ok(())
    }

    /// Takes back `items`, each folder's messages together
    fn undo_items(&self, items: Vec<Undo>, report: &mut UndoReport) -> Result<()> {
        let groups = Groups::of(items);
        for (key, uids) in groups.flags {
            self.undo_flags(key, &uids, report)?;
        }
        for (key, uids) in groups.colors {
            self.undo_colors(key, &uids, report)?;
        }
        for (key, ids) in groups.moves {
            self.undo_moves(key, &ids, report)?;
        }
        for (from, ids) in groups.archives {
            self.undo_archives(from, ids, report)?;
        }
        for (account, message_id) in groups.unsend {
            self.undo_unsend(account, &message_id, report)?;
        }
        Ok(())
    }

    /// Takes back `entry` as far as it can be, marking it taken back when any of it was
    fn undo_entry(&self, entry: &AgentLogEntry, report: &mut UndoReport) -> Result<()> {
        if entry.undone {
            return Ok(());
        }
        let Some(undo) = entry.entry.undo.as_deref().and_then(Undo::read) else {
            report.left(Text::AgentUndoImpossible, 1);
            return Ok(());
        };
        let before = report.undone;
        self.undo_items(undo.items(), report)?;
        if report.undone > before {
            self.store().set_agent_log_undone(entry.id)?;
            report.entries += 1;
        }
        Ok(())
    }

    /// Takes back what entry `id` of the log did, every message of it that is still as it left it. Refused with the
    /// reason when none of it can be (a message that is no longer in the Outbox, one that is not where it went); what
    /// was left of a change of many messages is in the report.
    pub fn agent_undo_report(&self, id: i64) -> Result<UndoReport> {
        let entry = self.store().agent_log_entry(id)?.ok_or(Error::NotFound)?;
        let mut report = UndoReport::default();
        if entry.undone {
            return Ok(report);
        }
        self.undo_entry(&entry, &mut report)?;
        if let Some(why) = report.refusal() {
            return Err(Error::Unavailable(why));
        }
        self.post(Event::AgentLogChanged)?;
        Ok(report)
    }

    /// [`Core::agent_undo_report`] for one entry, whatever was left of it
    pub fn agent_undo(&self, id: i64) -> Result<()> {
        self.agent_undo_report(id).map(|_| ())
    }

    /// An agent takes back one of its own changes, entry `id` of the log: another program's is not found
    pub fn agent_undo_own(&self, host: AgentHostId, id: i64) -> Result<UndoReport> {
        let entry = self.store().agent_log_entry(id)?.ok_or(Error::NotFound)?;
        if entry.entry.host != host {
            return Err(Error::NotFound);
        }
        if entry.undone {
            return Err(Error::Unavailable("it was taken back already".into()));
        }
        self.agent_undo_report(id)
    }

    /// How many changes of program `host` since `since` can still be taken back
    pub fn agent_undoable_since(&self, host: AgentHostId, since: i64) -> Result<u64> {
        Ok(self.store().agent_undoable_since(host, since)?.len() as u64)
    }

    /// Takes back everything program `host` did since `since` that can be, newest first, so a message moved and then
    /// flagged is unflagged where it went before it goes back. What could not be taken back is in the report.
    pub fn agent_undo_since(&self, host: AgentHostId, since: i64) -> Result<UndoReport> {
        let entries = self.store().agent_undoable_since(host, since.min(now()))?;
        let mut report = UndoReport::default();
        for entry in &entries {
            self.undo_entry(entry, &mut report)?;
        }
        if !entries.is_empty() {
            self.post(Event::AgentLogChanged)?;
        }
        Ok(report)
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn undo_is_kept_as_text() {
        let each = [
            Undo::Flag {
                folder: 3,
                uid: 7,
                flag: "\\Seen".into(),
                was: false,
            },
            Undo::Move {
                from: 1,
                to: 2,
                message_id: "<a b@c>".into(),
            },
            Undo::Archive {
                from: 3,
                message_id: "<a b@c>".into(),
            },
            Undo::Unsend {
                account: 4,
                message_id: "<x@y>".into(),
            },
            Undo::Junk {
                from: 1,
                to: 5,
                junk: true,
                message_id: "<a b@c>".into(),
            },
            Undo::Color {
                folder: 2,
                uid: 9,
                was: Some(FlagColor::Purple),
            },
            Undo::Color {
                folder: 2,
                uid: 9,
                was: None,
            },
        ];
        for undo in each.clone() {
            assert_eq!(Undo::read(&undo.write()), Some(undo));
        }
        // a change of many, each message on its line
        let many = Undo::Many(each.to_vec());
        assert_eq!(many.write().lines().count(), each.len() + 1);
        assert_eq!(Undo::read(&many.write()), Some(many));
        assert_eq!(Undo::read("many"), Some(Undo::Many(Vec::new())));
        assert_eq!(Undo::read("other 1 2"), None);
        assert_eq!(Undo::read("many\nflag 1 2 0 \\Seen\nother 1"), None);
        assert_eq!(Undo::read("manyx 1"), None);
        // a line break in a Message-ID can not start another line
        let broken = Undo::Move {
            from: 1,
            to: 2,
            message_id: "<a\nmove 9 9 x>".into(),
        };
        assert_eq!(Undo::Many(vec![broken]).write().lines().count(), 2);
    }

    #[test]
    fn what_was_left_is_said() {
        let mut report = UndoReport {
            entries: 2,
            undone: 5,
            ..Default::default()
        };
        assert!(report.whole());
        assert_eq!(report.text(), "Took back 2 changes.");
        report.left(Text::AgentUndoNotArrived, 3);
        report.left(Text::AgentUndoChanged, 1);
        report.left(Text::AgentUndoSent, 0);
        assert!(!report.whole());
        assert_eq!(
            report.left_lines(),
            [
                "3 messages were no longer where the change put them.",
                "1 message was changed since, by you or on the server, and was left as it is."
            ]
        );
        assert_eq!(report.refusal(), None);
        let nothing = UndoReport {
            first: Some(Text::AgentUndoSent),
            sent: 1,
            ..Default::default()
        };
        assert_eq!(
            nothing.refusal().as_deref(),
            Some("the message is no longer in the Outbox")
        );
        assert_eq!(undo_span_label(1).as_deref(), Some("In the last hour"));
        assert!(undo_span_label(UNDO_SPANS.len()).is_none());
        assert!(undo_span_since(0).is_some_and(|since| (now() - since - 900).abs() <= 1));
    }
}
