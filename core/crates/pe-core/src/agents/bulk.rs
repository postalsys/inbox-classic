//! One change of many messages by an AI agent (decision 5 of the MCP plan): a dry run of a search counts the messages
//! an action would change and hands a ticket bound to that moment (those messages and no others, this program and its
//! accounts, a few minutes, one use); the ticket then runs the action through the actions' queue, off the windows'
//! thread, as the windows' own actions on many messages run, and the log keeps it as one entry with one Undo All.
//!
//! No question to the user: everything it does can be taken back, it never deletes for good and never sends. What
//! limits it is [`BULK_MAX`] and the program's ceiling of changes in the log, which counts every message of it.

use std::collections::HashMap;
use std::collections::hash_map::Entry;
use std::sync::Arc;

use pe_i18n::{Arg, Text};
use pe_store::{AccountId, AgentHostId, FlagColor, FolderId, MessageRef, NewLogEntry, Picked, Search, Sort};

use super::undo::color_now;
use super::{AgentHost, Undo, everywhere, log_entry, now};
use crate::selection::Action;
use crate::{Core, Error, Result};

/// The most messages one change of many may change. One command a folder carries up to 1000 UIDs
/// ([`crate::selection::PER_COMMAND`]), so a change never takes more than one command for each folder it touches; it
/// is twice what one call naming its messages may change (500), and a twentieth of what a program's log may hold in 30
/// days ([`pe_store::LOG_CEILING`]), so a program tricked by a message into one wrong change has done at most this
/// much, all of it with one Undo All.
pub const BULK_MAX: u64 = 1000;
/// The most messages a dry run looks through to find those its action changes: a search that finds more is too wide
const BULK_SCAN: u64 = 10 * BULK_MAX;
/// How long a dry run's ticket holds, in seconds
pub const TICKET_SECONDS: i64 = 300;
/// How many tickets are kept at once, of all programs: the oldest go first
const TICKETS_KEPT: usize = 100;

/// What a change of many does to each message
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum BulkAction {
    Read,
    Unread,
    Flag,
    Unflag,
    Color(FlagColor),
    /// Into another folder of the same account
    Move(FolderId),
    Archive,
    Junk,
    NotJunk,
    /// Into Deleted Items, never for good
    Delete,
}

impl BulkAction {
    /// The windows' action that does it
    fn action(self) -> Action {
        match self {
            BulkAction::Read => Action::Read(true),
            BulkAction::Unread => Action::Read(false),
            BulkAction::Flag => Action::Flag(true),
            BulkAction::Unflag => Action::Flag(false),
            BulkAction::Color(color) => Action::FlagColor(color),
            BulkAction::Move(to) => Action::Move(to),
            BulkAction::Archive => Action::Archive,
            BulkAction::Junk => Action::Junk(true),
            BulkAction::NotJunk => Action::Junk(false),
            BulkAction::Delete => Action::Delete,
        }
    }

    /// What the log says of it
    fn log_text(self) -> Text {
        match self {
            BulkAction::Read => Text::AgentLogBulkRead,
            BulkAction::Unread => Text::AgentLogBulkUnread,
            BulkAction::Flag => Text::AgentLogBulkFlagged,
            BulkAction::Unflag => Text::AgentLogBulkUnflagged,
            BulkAction::Color(_) => Text::AgentLogBulkColor,
            BulkAction::Move(_) => Text::AgentLogBulkMoved,
            BulkAction::Archive => Text::AgentLogBulkArchived,
            BulkAction::Junk => Text::AgentLogBulkJunk,
            BulkAction::NotJunk => Text::AgentLogBulkNotJunk,
            BulkAction::Delete => Text::AgentLogBulkDeleted,
        }
    }
}

/// What a folder is to a change of many: where junk and Deleted Items go from it, whether it is junk, archivable
struct Place {
    account: AccountId,
    /// Gmail's All Mail, which holds a copy of every message of the other folders
    all_mail: bool,
    junk: bool,
    archivable: bool,
    trash: Option<FolderId>,
    junk_target: Option<FolderId>,
    inbox: Option<FolderId>,
}

impl Core {
    /// The place of `folder`, kept in `places` once read
    fn place_in<'a>(&self, places: &'a mut HashMap<FolderId, Place>, folder: FolderId) -> Result<&'a Place> {
        Ok(match places.entry(folder) {
            Entry::Occupied(entry) => entry.into_mut(),
            Entry::Vacant(entry) => entry.insert(self.place(folder)?),
        })
    }

    fn place(&self, folder: FolderId) -> Result<Place> {
        let store = self.store();
        let (account, info) = store.folder_info(folder)?;
        let junk_folder = store.special_folder(account, "\\Junk")?.map(|f| f.id);
        Ok(Place {
            account,
            all_mail: info.special_use.as_deref() == Some("\\All"),
            junk: junk_folder == Some(folder),
            archivable: crate::archivable(&info),
            trash: crate::trash_in(&store, folder)?,
            junk_target: junk_folder,
            inbox: store.find_folder(account, "INBOX")?.map(|f| f.id),
        })
    }
}

/// How message `p` (in `place`) is taken back once `action` changed it; None when the action does not change it, or
/// does what can not be taken back
fn undo_of(action: BulkAction, p: &Picked, place: &Place) -> Option<Undo> {
    let (folder, uid) = (p.at.folder, p.at.uid);
    let flag = |flag: &str, was: bool| Undo::Flag {
        folder,
        uid,
        flag: flag.into(),
        was,
    };
    let moved = |to: FolderId| {
        p.message_id.clone().map(|message_id| Undo::Move {
            from: folder,
            to,
            message_id,
        })
    };
    let junk = |junk: bool, to: FolderId| {
        p.message_id.clone().map(|message_id| Undo::Junk {
            from: folder,
            to,
            junk,
            message_id,
        })
    };
    match action {
        BulkAction::Read => (!p.seen()).then(|| flag("\\Seen", false)),
        BulkAction::Unread => p.seen().then(|| flag("\\Seen", true)),
        BulkAction::Flag => (!p.flagged()).then(|| flag("\\Flagged", false)),
        // its colour comes back with it
        BulkAction::Unflag => p.flagged().then(|| Undo::Color {
            folder,
            uid,
            was: color_now(p),
            set: Some(None),
        }),
        BulkAction::Color(color) => (color_now(p) != Some(color)).then(|| Undo::Color {
            folder,
            uid,
            was: color_now(p),
            set: Some(Some(color)),
        }),
        BulkAction::Move(to) if to != folder => moved(to),
        BulkAction::Move(_) => None,
        BulkAction::Delete => moved(place.trash?),
        BulkAction::Archive if place.archivable => p.message_id.clone().map(|message_id| Undo::Archive {
            from: folder,
            message_id,
        }),
        BulkAction::Archive => None,
        BulkAction::Junk if !place.junk => junk(true, place.junk_target?),
        BulkAction::NotJunk if place.junk => junk(false, place.inbox?),
        BulkAction::Junk | BulkAction::NotJunk => None,
    }
}

/// Each message of `picked` once: on Gmail a message is in each of its labels' folders and in All Mail, so copies with
/// the same Message-ID in one account are one message, the copy outside All Mail kept (where the search found it in a
/// label). The store keeps no X-GM-MSGID, so the Message-ID is what tells them apart; one without is kept as it is.
/// `place` gives a folder's account and whether it is All Mail.
fn one_copy_each(picked: Vec<Picked>, place: impl Fn(FolderId) -> (AccountId, bool)) -> Vec<Picked> {
    let mut kept: Vec<Picked> = Vec::with_capacity(picked.len());
    let mut seen: HashMap<(AccountId, String), usize> = HashMap::new();
    for p in picked {
        let (account, all_mail) = place(p.at.folder);
        let Some(id) = p.message_id.clone() else {
            kept.push(p);
            continue;
        };
        match seen.get(&(account, id.clone())) {
            Some(&at) if place(kept[at].at.folder).1 && !all_mail => kept[at] = p,
            Some(_) => {}
            None => {
                seen.insert((account, id), kept.len());
                kept.push(p);
            }
        }
    }
    kept
}

/// A dry run's ticket: what one call of apply_to_search may change
#[derive(Debug, Clone)]
pub(crate) struct Ticket {
    host: AgentHostId,
    /// The accounts the program could use then, sorted
    accounts: Vec<AccountId>,
    action: BulkAction,
    query: String,
    /// The messages counted, each with how it is taken back
    messages: Vec<(MessageRef, Undo)>,
    expires: i64,
}

/// What a dry run found
#[derive(Debug, Clone)]
pub struct BulkPreview {
    /// The messages the action would change
    pub count: u64,
    /// The messages the search found that it would not change: already so, or where it does not apply (Deleted
    /// Items for a delete, Junk E-mail for junk, a special folder for archiving, another account for a move)
    pub unchanged: u64,
    /// A few of those it would change, newest first
    pub samples: Vec<MessageRef>,
    /// What the change takes, None when there is nothing to change or too much
    pub ticket: Option<String>,
    /// More than [`BULK_MAX`] would change: no ticket
    pub too_many: bool,
}

/// What a change of many did
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct BulkDone {
    /// The messages changed
    pub changed: u64,
    /// Counted by the dry run, but gone or changed since: left alone
    pub left: u64,
    /// The log's entry, which takes all of it back
    pub entry: i64,
}

/// A ticket nobody can guess: 32 hex digits from the system's randomness
fn ticket_id() -> String {
    pe_smtp::message::new_boundary_base() + &pe_smtp::message::new_boundary_base()
}

/// The accounts of `host`, sorted, as a ticket is bound to them
fn accounts_of(host: &AgentHost) -> Vec<AccountId> {
    let mut accounts = host.accounts.clone();
    accounts.sort_unstable();
    accounts
}

/// Why a ticket is refused, in a sentence the agent is told
fn refused(why: &str) -> Error {
    Error::Unavailable(format!(
        "{why} Nothing was changed: run apply_to_search with dry_run again for a new token."
    ))
}

impl Core {
    /// For tests: every ticket of a dry run expires now, as it would after [`TICKET_SECONDS`]
    #[doc(hidden)]
    pub fn agent_tickets_expire(&self) {
        for ticket in self.tickets().values_mut() {
            ticket.expires = now();
        }
    }

    fn tickets(&self) -> std::sync::MutexGuard<'_, HashMap<String, Ticket>> {
        self.agent_tickets.lock().unwrap_or_else(|p| p.into_inner())
    }

    /// The messages `search` finds that `action` would change, each with its undo; and how many it would not
    fn changes_of(&self, search: &Search, action: BulkAction) -> Result<(Vec<(MessageRef, Undo)>, u64)> {
        let refs = self.refs_in_ranges(search, Sort::default(), &[(0, BULK_SCAN)])?;
        let picked = self.store().picked(&refs)?;
        let mut places: HashMap<FolderId, Place> = HashMap::new();
        for p in &picked {
            self.place_in(&mut places, p.at.folder)?;
        }
        let picked = one_copy_each(picked, |folder| {
            places
                .get(&folder)
                .map_or((0, false), |place| (place.account, place.all_mail))
        });
        // a move goes within the account of the folder it goes to
        let target = match action {
            BulkAction::Move(to) => Some(self.store().folder(to)?.account_id),
            _ => None,
        };
        let mut changes = Vec::new();
        for p in &picked {
            let place = self.place_in(&mut places, p.at.folder)?;
            if target.is_some_and(|account| account != place.account) {
                continue;
            }
            if let Some(undo) = undo_of(action, p, place) {
                changes.push((p.at, undo));
            }
        }
        let unchanged = picked.len() as u64 - changes.len() as u64;
        Ok((changes, unchanged))
    }

    /// The dry run of `action` on what `query` finds in the accounts `host` may use (`account` alone, when given):
    /// how many messages it would change, a few of them, and the ticket that changes exactly those
    pub fn agent_bulk_preview(
        &self,
        host: &AgentHost,
        query: &str,
        account: Option<AccountId>,
        action: BulkAction,
    ) -> Result<BulkPreview> {
        let search = Search {
            text: query.to_string(),
            // as every search of an agent's: never by what only decrypting gives
            no_decrypted: true,
            accounts: Some(account.map_or_else(|| host.accounts.clone(), |a| vec![a])),
            ..everywhere(host)
        };
        let (found, _) = self.count_search(&search)?;
        if found > BULK_SCAN {
            return Ok(BulkPreview {
                count: found,
                unchanged: 0,
                samples: Vec::new(),
                ticket: None,
                too_many: true,
            });
        }
        let (messages, unchanged) = self.changes_of(&search, action)?;
        let count = messages.len() as u64;
        let samples = messages.iter().take(5).map(|(at, _)| *at).collect();
        let too_many = count > BULK_MAX;
        let ticket = (count > 0 && !too_many).then(|| self.keep_ticket(host, action, query, messages));
        Ok(BulkPreview {
            count,
            unchanged,
            samples,
            ticket,
            too_many,
        })
    }

    /// Keeps a ticket for `messages`, forgetting those expired and, past [`TICKETS_KEPT`], the oldest
    fn keep_ticket(
        &self,
        host: &AgentHost,
        action: BulkAction,
        query: &str,
        messages: Vec<(MessageRef, Undo)>,
    ) -> String {
        let id = ticket_id();
        let mut tickets = self.tickets();
        let at = now();
        tickets.retain(|_, ticket| ticket.expires > at);
        while tickets.len() >= TICKETS_KEPT {
            let Some(oldest) = tickets.iter().min_by_key(|(_, t)| t.expires).map(|(id, _)| id.clone()) else {
                break;
            };
            tickets.remove(&oldest);
        }
        tickets.insert(
            id.clone(),
            Ticket {
                host: host.id,
                accounts: accounts_of(host),
                action,
                query: query.to_string(),
                messages,
                expires: at + TICKET_SECONDS,
            },
        );
        id
    }

    /// Takes ticket `id` for `host`: once, by the program that got it, before it expires, while it may use the same
    /// accounts
    fn take_ticket(&self, host: &AgentHost, id: &str) -> Result<Ticket> {
        let mut tickets = self.tickets();
        let mine = tickets.get(id).is_some_and(|t| t.host == host.id);
        // another program's is not taken from it, nor told apart from one that does not exist
        let ticket = mine.then(|| tickets.remove(id)).flatten();
        drop(tickets);
        let ticket = ticket.ok_or_else(|| refused("This token is not known: it was used already, or never given."))?;
        if ticket.expires <= now() {
            return Err(refused("This token expired: it holds for 5 minutes."));
        }
        if ticket.accounts != accounts_of(host) {
            return Err(refused("The accounts this agent may use changed since the dry run."));
        }
        Ok(ticket)
    }

    /// The messages of `ticket` still as the dry run found them: each where it was, and still changed by the action
    fn still_changed(&self, ticket: &Ticket) -> Result<Vec<(MessageRef, Undo)>> {
        let refs: Vec<MessageRef> = ticket.messages.iter().map(|(at, _)| *at).collect();
        let picked: HashMap<MessageRef, Picked> = self.store().picked(&refs)?.into_iter().map(|p| (p.at, p)).collect();
        let mut places: HashMap<FolderId, Place> = HashMap::new();
        let mut kept = Vec::new();
        for (at, undo) in &ticket.messages {
            let Some(p) = picked.get(at) else {
                continue;
            };
            if undo_of(ticket.action, p, self.place_in(&mut places, at.folder)?).as_ref() == Some(undo) {
                kept.push((*at, undo.clone()));
            }
        }
        Ok(kept)
    }

    /// Runs the change of ticket `id` (from [`Core::agent_bulk_preview`]) for `host`: on the messages it counted that
    /// are still as they were, through the actions' queue, logged as one entry whose Undo takes all of it back.
    /// Refused for a ticket that is another program's, used, expired or of other accounts, and past the program's
    /// ceiling of changes in the log.
    pub async fn agent_bulk_apply(
        self: &Arc<Self>,
        host: &AgentHost,
        id: &str,
        call_id: Option<&str>,
    ) -> Result<BulkDone> {
        let ticket = self.take_ticket(host, id)?;
        let messages = self.still_changed(&ticket)?;
        let (did, _) = self.store().agent_log_live(host.id, now() - pe_store::LOG_KEPT)?;
        if did + messages.len() as u64 > pe_store::LOG_CEILING {
            return Err(Error::Unavailable(pe_i18n::tr(Text::AgentTooManyChanges)));
        }
        let changed = messages.len() as u64;
        let left = ticket.messages.len() as u64 - changed;
        if messages.is_empty() {
            return Err(refused(
                "None of the messages the dry run counted are as they were: they were changed or moved since.",
            ));
        }
        let refs: Vec<MessageRef> = messages.iter().map(|(at, _)| *at).collect();
        let action = ticket.action.action();
        let (sender, done) = tokio::sync::oneshot::channel();
        self.queue_action(Box::new(move |core| {
            let _ = sender.send(core.act_untracked(&refs, action).map(|_| ()));
        }))?;
        done.await.map_err(|_| Error::Closed)??;
        let entry = self.log_bulk(host, &ticket, messages, call_id)?;
        Ok(BulkDone { changed, left, entry })
    }

    /// The log's one entry of a change of many: what it did and to how many, with the Undo of every message
    fn log_bulk(
        &self,
        host: &AgentHost,
        ticket: &Ticket,
        messages: Vec<(MessageRef, Undo)>,
        call_id: Option<&str>,
    ) -> Result<i64> {
        let count = messages.len() as u64;
        let mut args: Vec<(&str, Arg)> = vec![("count", count.into()), ("query", (&ticket.query).into())];
        let folder = match ticket.action {
            BulkAction::Move(to) => crate::text::folder_name(&self.store().folder(to)?.info),
            _ => String::new(),
        };
        match ticket.action {
            BulkAction::Move(_) => args.push(("folder", (&folder).into())),
            BulkAction::Color(color) => args.push(("color", color.id().into())),
            _ => {}
        }
        let account = self.store().folder(messages[0].0.folder)?.account_id;
        let entry = NewLogEntry {
            account: Some(account),
            call_id: call_id.map(str::to_string),
            undo: Some(Undo::Many(messages.into_iter().map(|(_, undo)| undo).collect()).write()),
            changes: count,
            ..log_entry(host.id, "apply_to_search", ticket.action.log_text(), &args)
        };
        self.log_agent_ids(&[entry])?.first().copied().ok_or(Error::NotFound)
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    fn picked(flags: &[&str], message_id: Option<&str>) -> Picked {
        Picked {
            at: MessageRef { folder: 1, uid: 7 },
            flags: flags.iter().map(|f| f.to_string()).collect(),
            message_id: message_id.map(str::to_string),
            mark: Default::default(),
        }
    }

    fn place(junk: bool, trash: Option<FolderId>) -> Place {
        Place {
            account: 1,
            all_mail: false,
            junk,
            archivable: !junk,
            trash,
            junk_target: Some(5),
            inbox: Some(1),
        }
    }

    #[test]
    fn a_message_in_several_gmail_folders_counts_once() {
        let at = |folder, uid, id: Option<&str>| Picked {
            at: MessageRef { folder, uid },
            message_id: id.map(str::to_string),
            ..picked(&[], None)
        };
        // folder 9 is All Mail, 3 a label, 5 of another account
        let place = |folder| (if folder == 5 { 2 } else { 1 }, folder == 9);
        let kept = one_copy_each(
            vec![
                at(9, 1, Some("<a@x>")),
                at(3, 7, Some("<a@x>")),
                at(9, 2, Some("<b@x>")),
                at(5, 4, Some("<a@x>")),
                at(9, 3, None),
                at(3, 8, None),
            ],
            place,
        );
        let refs: Vec<(FolderId, u64)> = kept.iter().map(|p| (p.at.folder, p.at.uid)).collect();
        // the label's copy in place of All Mail's, another account's its own, those without a Message-ID each
        assert_eq!(refs, [(3, 7), (9, 2), (5, 4), (9, 3), (3, 8)]);
    }

    #[test]
    fn only_what_it_changes_is_counted() {
        let inbox = place(false, Some(4));
        let read = picked(&["\\Seen"], Some("<a@x>"));
        let unread = picked(&[], Some("<a@x>"));
        assert_eq!(undo_of(BulkAction::Read, &read, &inbox), None);
        assert_eq!(
            undo_of(BulkAction::Read, &unread, &inbox),
            Some(Undo::Flag {
                folder: 1,
                uid: 7,
                flag: "\\Seen".into(),
                was: false
            })
        );
        // a delete only where there is a Deleted Items to go to: never for good
        assert!(undo_of(BulkAction::Delete, &read, &inbox).is_some());
        assert_eq!(undo_of(BulkAction::Delete, &read, &place(false, None)), None);
        // nor what can not be found again to take it back
        assert_eq!(undo_of(BulkAction::Delete, &picked(&[], None), &inbox), None);
        // junk from anywhere but Junk E-mail, not junk only from there; archiving only where it applies
        assert!(undo_of(BulkAction::Junk, &read, &inbox).is_some());
        assert_eq!(undo_of(BulkAction::Junk, &read, &place(true, Some(4))), None);
        assert_eq!(undo_of(BulkAction::NotJunk, &read, &inbox), None);
        assert_eq!(undo_of(BulkAction::Archive, &read, &place(true, Some(4))), None);
        // a move to where it is already changes nothing
        assert_eq!(undo_of(BulkAction::Move(1), &read, &inbox), None);
        // the colour taken away comes back with its flag
        let purple = picked(&["\\Flagged", "$MailFlagBit0", "$MailFlagBit2"], None);
        assert_eq!(
            undo_of(BulkAction::Unflag, &purple, &inbox),
            Some(Undo::Color {
                folder: 1,
                uid: 7,
                was: Some(FlagColor::Purple),
                set: Some(None)
            })
        );
        assert_eq!(undo_of(BulkAction::Color(FlagColor::Purple), &purple, &inbox), None);
        assert_eq!(BULK_MAX as usize, crate::selection::PER_COMMAND);
    }
}
