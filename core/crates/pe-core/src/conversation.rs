//! A conversation in the reading pane: a collapsed conversation's row opens all of its messages, one under another,
//! each folded to a row or open in a frame of its own, at its focus message (its oldest unread one, else its newest).
//!
//! The apps draw the stack with their own controls (docs/conversation-view-plan.md): a row for each folded message, a
//! frame for each open one, its body a web view of the message's own document. The view the core gives is the focus
//! message's own [`MessageView`] (the selected message: Reply, Forward, Print, the bars and Find act on it), with
//! [`MessageView::conversation`] listing the conversation's [`Entry`]s in the stack's order, each open one other than
//! the focus with its own view. The messages are the conversation's in every folder of its account but Junk E-mail
//! and Deleted Items ([`pe_store::Store::conversation_messages`]): the user's own replies, drafts and filed messages,
//! each marked with its folder. A signed or encrypted message is shown in the stack as it is shown alone: its view is
//! the page of its labelled parts ([`pe_html::secure_page`]), its pictures never loaded with the others'.
//!
//! What is open and which message is selected is kept here for each conversation shown lately, so a click
//! ([`crate::Core::conversation_select`] and the others) and the view built again agree.

use std::collections::{BTreeSet, HashMap, HashSet};
use std::sync::Mutex;

use pe_i18n::{Text, tr, tr_args};
use pe_store::{FolderId, Message, MessageRef, Protection, Store};

use crate::view::MessageView;

/// A run of at least this many read messages between the first message and the last two read ones is folded into
/// one row ("14 more messages")
pub(crate) const MIDDLE_AT_LEAST: usize = 4;

/// The conversations kept: the reading pane's and those of a few message windows
const KEPT: usize = 8;

/// A conversation shown in the reading pane, besides its selected message's view
#[derive(Debug, Clone, PartialEq, Eq, Default)]
pub struct ConversationInfo {
    /// Its messages in the stack (every one, the folded middle's too)
    pub count: usize,
    /// Its subject, as its first message has it
    pub subject: String,
    /// "7 messages, 2 unread"
    pub summary: String,
    /// Who wrote in it, in the order they first did, the user as "You": "Ann Example, Bob Harris, You"
    pub people: String,
    /// The line under the subject: the summary and the people, "7 messages, 2 unread · Ann Example, You"
    pub line: String,
    /// The rows and frames of the stack, in its order; the middle's folded messages are not among them
    /// ([`Entry::hidden_before`])
    pub entries: Vec<Entry>,
    /// Open messages whose source is still downloading: when one is ready ([`crate::Event::MessageReady`]), the app
    /// builds the view again
    pub waiting: Vec<MessageRef>,
}

/// One message of the stack: a row when folded, a frame when open
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct Entry {
    pub at: MessageRef,
    /// Its place in the conversation, what the operations on it take ([`crate::Core::conversation_select`])
    pub index: usize,
    /// Who sent it: their name, else their address; "You" for the user's own
    pub from: String,
    pub address: String,
    /// The user sent it (an address of the account)
    pub own: bool,
    /// When, seconds since the Unix epoch (the Date header, the received date without one); 0 for unknown. The apps
    /// write it as their message list does.
    pub date: i64,
    /// When, in full ("Thursday, November 26, 2026, 1:10 PM"): an open frame's header and a row's tooltip
    pub when: String,
    /// Its first words
    pub words: String,
    /// Who it went to: "to Ann, Carol"
    pub to: String,
    /// The folder it is filed in, when not the one the conversation was opened from: a folded row's chip; empty
    /// otherwise
    pub folder: String,
    /// The same as an open frame says it: "Found in Sent Items"; empty in the folder it was opened from
    pub found_in: String,
    /// Words on its state: "Draft", "Downloading…"; empty for none
    pub note: String,
    /// It is a draft: its frame offers Edit
    pub draft: bool,
    pub unread: bool,
    pub open: bool,
    /// Reply, Forward, Print and the bars act on it; its frame has the accent
    pub selected: bool,
    /// It has attachments: a folded row shows a paperclip
    pub attachments: bool,
    /// Its emoji reactions' badge ("👍❤️ 3"), empty for none
    pub reactions: String,
    /// The sender's picture ([`crate::senders::picture_key`]), drawn by [`crate::Core::picture_start`]; 0 for none
    pub picture: u64,
    /// The picture is the brand's logo, not a person's: drawn square
    pub logo: bool,
    /// The sender's initials, where there is no picture
    pub initials: String,
    /// Read messages of the folded middle right before this one, shown as one row ("14 more messages",
    /// [`crate::Core::conversation_show_middle`]); 0 for none
    pub hidden_before: usize,
    /// The words of the folded middle's row before it ([`hidden_words`]), empty for none
    pub hidden_text: String,
    /// Open and not the selected one: its own view, whose document its frame shows (the selected one's is the
    /// conversation's view itself); None when folded or still downloading
    pub view: Option<Box<MessageView>>,
}

/// One conversation as it was shown last
#[derive(Debug, Default)]
struct Shown {
    focus: Option<MessageRef>,
    open: BTreeSet<MessageRef>,
    /// The folded middle was clicked open: every message has its row
    all: bool,
    /// Its messages in the stack's order: an entry's index is its place here
    order: Vec<MessageRef>,
    /// The unread messages it shows open, marked read once the window says the view was shown
    marks: Vec<MessageRef>,
    /// Its unread messages when it was shown last: one unread now that was not then opens
    unread: BTreeSet<MessageRef>,
    /// When it was shown, to forget the oldest
    used: u64,
}

/// The conversations shown lately, by their id
#[derive(Debug, Default)]
pub(crate) struct Conversations {
    shown: Mutex<HashMap<i64, Shown>>,
    clock: std::sync::atomic::AtomicU64,
}

impl Conversations {
    fn with<T>(&self, thread: i64, run: impl FnOnce(&mut Shown) -> T) -> T {
        let mut shown = self.shown.lock().unwrap_or_else(|e| e.into_inner());
        let used = self.clock.fetch_add(1, std::sync::atomic::Ordering::Relaxed);
        if !shown.contains_key(&thread) && shown.len() >= KEPT {
            let oldest = shown.iter().min_by_key(|(_, s)| s.used).map(|(t, _)| *t);
            if let Some(oldest) = oldest {
                shown.remove(&oldest);
            }
        }
        let entry = shown.entry(thread).or_default();
        entry.used = used;
        run(entry)
    }

    /// `run` on a conversation shown, None when it is not one or has no focus
    fn with_shown<T>(&self, thread: i64, run: impl FnOnce(&mut Shown, MessageRef) -> Option<T>) -> Option<T> {
        let mut shown = self.shown.lock().unwrap_or_else(|e| e.into_inner());
        let entry = shown.get_mut(&thread)?;
        let focus = entry.focus?;
        run(entry, focus)
    }
}

/// The order and the choices of a conversation shown: which message is open, which is selected, which are folded into
/// the middle's row
pub(crate) struct Plan {
    /// The messages in the stack's order, each with whether it is open
    pub messages: Vec<(Message, bool)>,
    pub focus: MessageRef,
    /// The places of the messages folded into the middle's row
    pub hidden: BTreeSet<usize>,
}

/// Whether a message is signed or encrypted as a whole, as the store knows it: left out of the printout, and its
/// pictures never loaded with the conversation's
pub(crate) fn protected(message: &Message) -> bool {
    message.info.protection != Protection::None
}

impl Conversations {
    /// The plan of the conversation `thread` of `messages` (as they arrived) opened at `focus`: what was open when it
    /// was shown last, its unread messages that were not unread then (all of them the first time), and the focus open;
    /// the read middle folded; `newest_first` turns the order
    pub(crate) fn plan(&self, thread: i64, messages: Vec<Message>, focus: MessageRef, newest_first: bool) -> Plan {
        self.with(thread, |shown| {
            let present: BTreeSet<MessageRef> = messages.iter().map(Message::at).collect();
            // what is unread opens: the first time all of it, then what became unread since (a reply that came, one
            // marked unread); an unread one the user folded stays folded
            let unread: BTreeSet<MessageRef> = messages.iter().filter(|m| !m.info.seen()).map(Message::at).collect();
            shown.open.extend(unread.difference(&shown.unread).copied());
            shown.unread = unread;
            shown.open.retain(|at| present.contains(at));
            shown.focus = Some(focus);
            shown.open.insert(focus);
            let hidden_in_time = if shown.all {
                BTreeSet::new()
            } else {
                middle(&messages, &shown.open)
            };
            let count = messages.len();
            let mut messages: Vec<(Message, bool)> = messages
                .into_iter()
                .map(|m| {
                    let open = shown.open.contains(&m.at());
                    (m, open)
                })
                .collect();
            let hidden: BTreeSet<usize> = if newest_first {
                messages.reverse();
                hidden_in_time.into_iter().map(|i| count - 1 - i).collect()
            } else {
                hidden_in_time
            };
            shown.order = messages.iter().map(|(m, _)| m.at()).collect();
            shown.marks = messages
                .iter()
                .filter(|(m, open)| *open && !m.info.seen())
                .map(|(m, _)| m.at())
                .collect();
            Plan {
                messages,
                focus,
                hidden,
            }
        })
    }

    /// A message clicked (its row or its frame) in the conversation `thread`: a folded one opens; either way it is
    /// selected. The message to show now; None when there is no such message.
    pub(crate) fn select(&self, thread: i64, index: usize) -> Option<MessageRef> {
        self.with_shown(thread, |shown, _| {
            let at = *shown.order.get(index)?;
            shown.open.insert(at);
            shown.focus = Some(at);
            Some(at)
        })
    }

    /// A message's arrow clicked: a folded one opens and is selected; an open one folds (the selection stays, unless
    /// it was that one: then the nearest open message has it, or it stays, folded, when none is open). The message to
    /// show now.
    pub(crate) fn toggle(&self, thread: i64, index: usize) -> Option<MessageRef> {
        self.with_shown(thread, |shown, focus| {
            let at = *shown.order.get(index)?;
            if !shown.open.contains(&at) {
                shown.open.insert(at);
                shown.focus = Some(at);
                return Some(at);
            }
            shown.open.remove(&at);
            if at != focus {
                return Some(focus);
            }
            let nearest = shown
                .order
                .iter()
                .enumerate()
                .filter(|(_, m)| shown.open.contains(m))
                .min_by_key(|(i, _)| i.abs_diff(index))
                .map(|(_, m)| *m);
            shown.focus = Some(nearest.unwrap_or(at));
            shown.focus
        })
    }

    /// The message `step` places from the selected one in the stack's order (Next and Previous Message in
    /// Conversation): opened and selected. None at either end.
    pub(crate) fn step(&self, thread: i64, step: isize) -> Option<MessageRef> {
        self.with_shown(thread, |shown, focus| {
            let here = shown.order.iter().position(|m| *m == focus)?;
            let at = *shown.order.get(here.checked_add_signed(step)?)?;
            shown.open.insert(at);
            shown.focus = Some(at);
            Some(at)
        })
    }

    /// Open All Messages (`open`) or Fold All Messages: every message open, or every one folded but the selected one.
    /// The selected message, which stays.
    pub(crate) fn open_all(&self, thread: i64, open: bool) -> Option<MessageRef> {
        self.with_shown(thread, |shown, focus| {
            shown.open = if open {
                shown.order.iter().copied().collect()
            } else {
                BTreeSet::from([focus])
            };
            shown.all |= open;
            Some(focus)
        })
    }

    /// The folded middle's row clicked: every message has its row from now on
    pub(crate) fn show_middle(&self, thread: i64) {
        self.with(thread, |shown| shown.all = true);
    }

    /// The unread messages the conversation showed open, to mark read now that the window shows them
    pub(crate) fn marks(&self, thread: i64) -> Vec<MessageRef> {
        self.with(thread, |shown| std::mem::take(&mut shown.marks))
    }
}

/// The places (in time) of the read messages folded into the middle's row: each run of at least [`MIDDLE_AT_LEAST`]
/// folded messages that are neither the first one nor among the last two read ones
fn middle(messages: &[Message], open: &BTreeSet<MessageRef>) -> BTreeSet<usize> {
    let read: Vec<usize> = (0..messages.len()).filter(|&i| messages[i].info.seen()).collect();
    let last_read: BTreeSet<usize> = read.iter().rev().take(2).copied().collect();
    let foldable =
        |i: usize| i > 0 && messages[i].info.seen() && !open.contains(&messages[i].at()) && !last_read.contains(&i);
    let mut hidden = BTreeSet::new();
    let mut run: Vec<usize> = Vec::new();
    for i in 0..=messages.len() {
        if i < messages.len() && foldable(i) {
            run.push(i);
            continue;
        }
        if run.len() >= MIDDLE_AT_LEAST {
            hidden.extend(run.iter().copied());
        }
        run.clear();
    }
    hidden
}

/// A message's sender as its row names it: the name, else the address
fn sender(message: &Message) -> String {
    let info = &message.info;
    if info.from_name.trim().is_empty() {
        info.from_address.clone()
    } else {
        info.from_name.clone()
    }
}

/// What the core knows of the conversation's place besides its messages: the folder it was opened from, the folders
/// of its account and the user's own addresses (lowercase)
pub(crate) struct Place<'a> {
    pub home: FolderId,
    pub folders: &'a HashMap<FolderId, pe_store::FolderInfo>,
    pub own: &'a HashSet<String>,
}

/// The entries of a plan: each shown message's row and frame words, the views of the open ones but the selected one
/// (`views`, by message; taken), the middle's folded messages counted on the entry after them
pub(crate) fn entries(
    plan: &Plan,
    place: &Place,
    waiting: &[MessageRef],
    views: &mut HashMap<MessageRef, MessageView>,
) -> Vec<Entry> {
    let mut entries = Vec::new();
    let mut hidden_before = 0;
    for (index, (message, open)) in plan.messages.iter().enumerate() {
        if plan.hidden.contains(&index) {
            hidden_before += 1;
            continue;
        }
        let at = message.at();
        let info = &message.info;
        let own = place.own.contains(&info.from_address.to_lowercase());
        let folder_info = place.folders.get(&message.folder_id);
        let folder = match folder_info {
            Some(folder) if message.folder_id != place.home => crate::text::folder_name(folder),
            _ => String::new(),
        };
        let draft = folder_info.is_some_and(|f| f.special_use.as_deref() == Some("\\Drafts"));
        let note = if *open && waiting.contains(&at) {
            tr(Text::UiConversationDownloading)
        } else if draft {
            tr(Text::UiConversationDraft)
        } else {
            String::new()
        };
        let people = if info.recipient_people.is_empty() {
            &info.recipients
        } else {
            &info.recipient_people
        };
        let date = info.date.or(info.internal_date);
        let (kind, picture) = crate::senders::picture(message);
        entries.push(Entry {
            at,
            index,
            from: if own {
                tr(Text::UiConversationYou)
            } else {
                sender(message)
            },
            address: info.from_address.clone(),
            own,
            date: date.unwrap_or(0),
            when: date.map(crate::calendar::local_date_time).unwrap_or_default(),
            words: message.snippet.clone().unwrap_or_default(),
            to: if people.is_empty() {
                String::new()
            } else {
                tr_args(Text::UiConversationTo, &[("people", people.as_str().into())])
            },
            found_in: if folder.is_empty() {
                String::new()
            } else {
                tr_args(Text::UiConversationFoundIn, &[("folder", folder.as_str().into())])
            },
            folder,
            note,
            draft,
            unread: !info.seen(),
            open: *open,
            selected: at == plan.focus,
            attachments: info.has_attachments,
            reactions: crate::reactions::badge(&message.reactions),
            picture,
            logo: kind == crate::senders::PictureKind::Logo,
            initials: crate::text::initials(&info.from_name, &info.from_address),
            hidden_text: if hidden_before > 0 {
                hidden_words(hidden_before)
            } else {
                String::new()
            },
            hidden_before: std::mem::take(&mut hidden_before),
            view: if *open && at != plan.focus {
                views.remove(&at).map(Box::new)
            } else {
                None
            },
        });
    }
    entries
}

/// The conversation's words over the stack: its subject, how many messages and unread ones, who wrote in it
pub(crate) fn summary(plan: &Plan, own: &HashSet<String>) -> (String, String, String) {
    let mut in_time: Vec<&Message> = plan.messages.iter().map(|(m, _)| m).collect();
    in_time.sort_by_key(|m| m.info.date.or(m.info.internal_date).unwrap_or(0));
    let subject = in_time.first().map(|m| m.info.subject.clone()).unwrap_or_default();
    let unread = plan.messages.iter().filter(|(m, _)| !m.info.seen()).count();
    let mut counts = tr_args(Text::UiConversationMessages, &[("count", plan.messages.len().into())]);
    if unread > 0 {
        counts.push_str(", ");
        counts.push_str(&tr_args(Text::UiConversationUnread, &[("count", unread.into())]));
    }
    let mut people: Vec<String> = Vec::new();
    for message in in_time {
        let name = if own.contains(&message.info.from_address.to_lowercase()) {
            tr(Text::UiConversationYou)
        } else {
            sender(message)
        };
        if !name.is_empty() && !people.contains(&name) {
            people.push(name);
        }
    }
    (subject, counts, crate::text::word_list(&people))
}

/// The selected message's view with the conversation's entries: `views` the open messages' own views
pub(crate) fn into_view(
    mut view: MessageView,
    plan: &Plan,
    place: &Place,
    mut views: HashMap<MessageRef, MessageView>,
    waiting: Vec<MessageRef>,
) -> MessageView {
    let (subject, summary, people) = summary(plan, place.own);
    let entries = entries(plan, place, &waiting, &mut views);
    let line = [summary.as_str(), people.as_str()]
        .into_iter()
        .filter(|words| !words.is_empty())
        .collect::<Vec<_>>()
        .join(" \u{00B7} ");
    view.conversation = Some(ConversationInfo {
        count: plan.messages.len(),
        subject,
        summary,
        people,
        line,
        entries,
        waiting,
    });
    view
}

/// The printout of a conversation: each message's header lines and its text, in the page's order, as one document
/// (a printer prints no frames); the messages not downloaded and those signed or encrypted are left out
pub(crate) fn printout(store: &Store, messages: &[Message]) -> String {
    let mut parts: Vec<(usize, String)> = Vec::new();
    for (index, message) in messages.iter().enumerate() {
        let Ok(Some(source)) = store.source(message.folder_id, message.info.uid) else {
            continue;
        };
        if protected(message) {
            continue;
        }
        if let Some(body) = crate::view::print_body(&source) {
            parts.push((index, body));
        }
    }
    let subject = messages.first().map(|m| m.info.subject.clone()).unwrap_or_default();
    let header = [(tr(Text::HeaderSubject), subject)];
    let header: Vec<(&str, &str)> = header.iter().map(|(n, v)| (n.as_str(), v.as_str())).collect();
    pe_html::print_document_with(&pe_html::print_parts(&parts, &header), &[])
}

impl crate::Core {
    /// The messages Delete, Archive or Move would also take with "Whole Conversation": for each conversation of which
    /// `selected` holds two or more messages (a collapsed conversation's row, or several of its messages), its
    /// messages in the other folders of its account that the reading pane shows with it ([`Store::conversation_messages`])
    /// and `selected` does not hold. Archive and Move leave the user's sent messages and drafts where they are;
    /// Delete takes them too. Empty for a whole list (Select All) and for any other action: nothing to ask then.
    pub fn conversation_elsewhere(
        &self,
        selected: &crate::Selected,
        action: crate::Action,
    ) -> crate::Result<Vec<MessageRef>> {
        use crate::{Action, Selected};
        let Selected::Listed(refs) = selected else {
            return Ok(Vec::new());
        };
        let own_kept = match action {
            Action::Delete => false,
            Action::Archive | Action::Move(_) => true,
            _ => return Ok(Vec::new()),
        };
        let store = self.store();
        let mut threads: HashMap<i64, (FolderId, usize)> = HashMap::new();
        for at in refs {
            if let Some(thread) = store
                .message(at.folder, at.uid)?
                .and_then(|m| m.info.thread_id)
                .filter(|t| *t > 0)
            {
                threads.entry(thread).or_insert((at.folder, 0)).1 += 1;
            }
        }
        // the user's own sent messages and drafts, which Archive and Move leave where they are
        let mut kept: BTreeSet<FolderId> = BTreeSet::new();
        let mut accounts: BTreeSet<pe_store::AccountId> = BTreeSet::new();
        let mut seen = refs.iter().copied().collect::<BTreeSet<MessageRef>>();
        let mut others = Vec::new();
        for (thread, (folder, count)) in threads {
            if count < 2 {
                continue;
            }
            if own_kept && accounts.insert(store.folder_info(folder)?.0) {
                let account = store.folder_info(folder)?.0;
                kept.extend(
                    store
                        .folders(account)?
                        .into_iter()
                        .filter(|f| matches!(f.info.special_use.as_deref(), Some("\\Sent" | "\\Drafts")))
                        .map(|f| f.id),
                );
            }
            for message in store.conversation_messages(thread, folder)? {
                let at = message.at();
                if !kept.contains(&at.folder) && seen.insert(at) {
                    others.push(at);
                }
            }
        }
        Ok(others)
    }
}

/// A message shown alone, as a stack of one (its key 0, 0: the next message alone takes its frame and web view): its
/// view's own words, as a conversation's entry has them
pub fn alone(view: &MessageView) -> Entry {
    let people: Vec<String> = [&view.to, &view.cc]
        .into_iter()
        .filter(|p| !p.is_empty())
        .cloned()
        .collect();
    Entry {
        at: MessageRef { folder: 0, uid: 0 },
        index: 0,
        from: view.from.clone(),
        address: String::new(),
        own: false,
        date: view.date.unwrap_or(0),
        when: view.date.map(crate::calendar::local_date_time).unwrap_or_default(),
        words: String::new(),
        to: if people.is_empty() {
            String::new()
        } else {
            let people = crate::text::word_list(&people);
            tr_args(Text::UiConversationTo, &[("people", people.as_str().into())])
        },
        folder: String::new(),
        found_in: String::new(),
        note: String::new(),
        draft: false,
        unread: false,
        open: true,
        selected: true,
        attachments: !view.attachments.is_empty(),
        reactions: String::new(),
        picture: view.picture,
        logo: view.has_logo,
        initials: view.initials.clone(),
        hidden_before: 0,
        hidden_text: String::new(),
        view: None,
    }
}

/// The stack's entries of `view`, taken out of it: its conversation's, or the one of a message alone ([`alone`])
pub fn take_entries(view: &mut MessageView) -> Vec<Entry> {
    match view.conversation.as_mut() {
        Some(conversation) => std::mem::take(&mut conversation.entries),
        None => vec![alone(view)],
    }
}

/// The words of the folded middle's row: "14 more messages"
pub fn hidden_words(count: usize) -> String {
    tr_args(Text::UiConversationHidden, &[("count", count.into())])
}

/// What to ask before Delete, Archive or Move of a conversation with `count` messages elsewhere
/// ([`crate::Core::conversation_elsewhere`]): "This conversation also has 2 messages in other folders."
pub fn elsewhere_question(count: usize) -> String {
    tr_args(Text::UiConversationElsewhere, &[("count", count.into())])
}

#[cfg(test)]
mod tests {
    use super::*;
    use pe_store::{Message, MessageInfo};

    fn message(uid: u64, seen: bool) -> Message {
        Message {
            id: uid as i64,
            folder_id: 1,
            info: MessageInfo {
                uid,
                date: Some(uid as i64 * 100),
                from_name: format!("Sender {uid}"),
                from_address: format!("s{uid}@example.com"),
                subject: format!("Subject {uid}"),
                flags: if seen { vec!["\\Seen".into()] } else { Vec::new() },
                ..Default::default()
            },
            cached: true,
            thread: None,
            mark: Default::default(),
            snippet: Some(format!("words {uid}")),
            sender_auth: 0,
            logo: None,
            contact: None,
            snippet_is_state: false,
            reactions: Vec::new(),
        }
    }

    fn at(uid: u64) -> MessageRef {
        MessageRef { folder: 1, uid }
    }

    fn open(plan: &Plan) -> Vec<u64> {
        plan.messages
            .iter()
            .filter(|(_, open)| *open)
            .map(|(m, _)| m.info.uid)
            .collect()
    }

    fn hidden(plan: &Plan) -> Vec<u64> {
        plan.hidden.iter().map(|&i| plan.messages[i].0.info.uid).collect()
    }

    #[test]
    fn a_click_selects_and_only_the_arrow_folds() {
        let shown = Conversations::default();
        let all = || vec![message(1, true), message(2, false), message(3, true), message(4, false)];
        let plan = shown.plan(7, all(), at(2), false);
        assert_eq!(open(&plan), [2, 4], "the unread messages open, the focus among them");
        assert_eq!(shown.marks(7), [at(2), at(4)]);
        // a folded message clicked opens and is selected
        assert_eq!(shown.select(7, 0), Some(at(1)));
        assert_eq!(open(&shown.plan(7, all(), at(1), false)), [1, 2, 4]);
        // an open one clicked is only selected: it stays open, and so do the others
        assert_eq!(shown.select(7, 3), Some(at(4)));
        assert_eq!(open(&shown.plan(7, all(), at(4), false)), [1, 2, 4]);
        // the arrow folds another one: the selection stays
        assert_eq!(shown.toggle(7, 0), Some(at(4)));
        assert_eq!(open(&shown.plan(7, all(), at(4), false)), [2, 4]);
        // the arrow folds the selected one: the nearest open message is selected
        assert_eq!(shown.toggle(7, 3), Some(at(2)));
        assert_eq!(open(&shown.plan(7, all(), at(2), false)), [2]);
        // the arrow on a folded one opens and selects it
        assert_eq!(shown.toggle(7, 2), Some(at(3)));
        assert_eq!(open(&shown.plan(7, all(), at(3), false)), [2, 3]);
        assert_eq!(shown.select(7, 9), None, "a message that is not there");
        assert_eq!(shown.select(8, 0), None, "a conversation not shown");
        assert_eq!(shown.toggle(8, 0), None);
    }

    #[test]
    fn steps_and_open_or_fold_all() {
        let shown = Conversations::default();
        let all = || (1..=5).map(|uid| message(uid, true)).collect::<Vec<_>>();
        shown.plan(1, all(), at(5), false);
        assert_eq!(shown.step(1, -1), Some(at(4)), "the previous one opens and is selected");
        assert_eq!(open(&shown.plan(1, all(), at(4), false)), [4, 5]);
        assert_eq!(shown.step(1, 1), Some(at(5)));
        assert_eq!(shown.step(1, 1), None, "past the last one");
        assert_eq!(shown.open_all(1, true), Some(at(5)));
        assert_eq!(open(&shown.plan(1, all(), at(5), false)), [1, 2, 3, 4, 5]);
        assert_eq!(shown.open_all(1, false), Some(at(5)));
        assert_eq!(
            open(&shown.plan(1, all(), at(5), false)),
            [5],
            "Fold All leaves the selected one open"
        );
        assert_eq!(shown.step(2, 1), None, "a conversation not shown");
    }

    #[test]
    fn newest_first_turns_the_order() {
        let shown = Conversations::default();
        let plan = shown.plan(
            1,
            vec![message(1, true), message(2, true), message(3, false)],
            at(3),
            true,
        );
        let order: Vec<u64> = plan.messages.iter().map(|(m, _)| m.info.uid).collect();
        assert_eq!(order, [3, 2, 1]);
        assert_eq!(shown.select(1, 0), Some(at(3)), "the newest is the first row");
    }

    #[test]
    fn signed_or_encrypted_messages_open_in_the_stack() {
        let shown = Conversations::default();
        let mut sealed = message(2, false);
        sealed.info.protection = Protection::Encrypted;
        let plan = shown.plan(1, vec![message(1, false), sealed], at(1), false);
        assert_eq!(open(&plan), [1, 2]);
        assert_eq!(shown.marks(1), [at(1), at(2)]);
    }

    #[test]
    fn the_read_middle_of_a_long_conversation_folds_into_one_row() {
        let shown = Conversations::default();
        // 1 to 9 read, 10 unread
        let many = || (1..=10).map(|uid| message(uid, uid != 10)).collect::<Vec<_>>();
        let plan = shown.plan(1, many(), at(10), false);
        assert_eq!(
            hidden(&plan),
            [2, 3, 4, 5, 6, 7],
            "the first and the last two read ones stay"
        );
        // the selected message is never folded away, and a run shorter than four stays
        let plan = shown.plan(1, many(), at(5), false);
        assert!(plan.hidden.is_empty(), "runs of three (2 to 4) and two (6, 7) stay");
        // a short conversation folds nothing
        let fresh = Conversations::default();
        let few = || (1..=6).map(|uid| message(uid, uid != 6)).collect::<Vec<_>>();
        assert!(fresh.plan(2, few(), at(6), false).hidden.is_empty());
        // the row clicked: every message has its row
        shown.show_middle(1);
        assert!(shown.plan(1, many(), at(10), false).hidden.is_empty());
        // newest first: the same messages, at their places in that order
        let turned = Conversations::default();
        let plan = turned.plan(1, many(), at(10), true);
        assert_eq!(hidden(&plan), [7, 6, 5, 4, 3, 2]);
    }

    #[test]
    fn a_message_alone_is_a_stack_of_one() {
        pe_i18n::set_language("en");
        let mut view = MessageView {
            from: "Ann Lee <ann@example.com>".into(),
            initials: "AL".into(),
            to: "Bob <bob@example.com>".into(),
            cc: "Carol <carol@example.com>".into(),
            date: Some(1_700_000_000),
            picture: 7,
            ..MessageView::default()
        };
        let entries = take_entries(&mut view);
        assert_eq!(entries.len(), 1, "its one entry");
        let entry = &entries[0];
        assert_eq!(
            entry.at,
            MessageRef { folder: 0, uid: 0 },
            "the key the next message alone takes again"
        );
        assert!(entry.open && entry.selected, "open and selected");
        assert_eq!(entry.from, "Ann Lee <ann@example.com>");
        assert_eq!(entry.initials, "AL");
        assert_eq!(entry.picture, 7);
        assert_eq!(
            entry.to, "to Bob <bob@example.com>, Carol <carol@example.com>",
            "as a conversation's entry says it"
        );
        assert_eq!(
            entry.when,
            crate::calendar::local_date_time(1_700_000_000),
            "the date as the stack says it"
        );
        assert!(entry.hidden_text.is_empty());
    }

    #[test]
    fn entries_say_who_where_and_what() {
        pe_i18n::set_language("en");
        let shown = Conversations::default();
        let mut sent = message(2, true);
        sent.folder_id = 2;
        sent.info.from_address = "Me@Example.com".into();
        sent.info.recipient_people = "Ann".into();
        sent.info.has_attachments = true;
        let mut draft = message(3, true);
        draft.folder_id = 3;
        let plan = shown.plan(1, vec![message(1, false), sent, draft], at(1), false);
        let folder = |name: &str, special: Option<&str>| pe_store::FolderInfo {
            path: name.into(),
            name: name.into(),
            special_use: special.map(str::to_string),
            ..Default::default()
        };
        let folders = HashMap::from([
            (1, folder("INBOX", None)),
            (2, folder("Sent", Some("\\Sent"))),
            (3, folder("Drafts", Some("\\Drafts"))),
        ]);
        let own = HashSet::from(["me@example.com".to_string()]);
        let place = Place {
            home: 1,
            folders: &folders,
            own: &own,
        };
        let entries = entries(&plan, &place, &[], &mut HashMap::new());
        assert_eq!(entries[0].folder, "", "the folder it was opened from is not named");
        assert!(entries[0].selected && entries[0].open && entries[0].unread && !entries[1].open);
        assert_eq!(
            (
                entries[1].from.as_str(),
                entries[1].own,
                entries[1].folder.as_str(),
                entries[1].found_in.as_str()
            ),
            ("You", true, "Sent Items", "Found in Sent Items")
        );
        assert_eq!((entries[1].to.as_str(), entries[1].attachments), ("to Ann", true));
        assert_eq!((entries[2].note.as_str(), entries[2].draft), ("Draft", true));
        assert_eq!(entries[0].initials, "S", "the initials as the list draws them");
        let (subject, counts, people) = summary(&plan, &own);
        assert_eq!(subject, "Subject 1");
        assert_eq!(counts, "3 messages, 1 unread");
        assert_eq!(people, "Sender 1, You, Sender 3");
    }

    #[test]
    fn the_middle_is_counted_on_the_entry_after_it() {
        pe_i18n::set_language("en");
        let shown = Conversations::default();
        let many = (1..=10).map(|uid| message(uid, uid != 10)).collect::<Vec<_>>();
        let plan = shown.plan(1, many, at(10), false);
        let folders = HashMap::new();
        let own = HashSet::new();
        let place = Place {
            home: 1,
            folders: &folders,
            own: &own,
        };
        let entries = entries(&plan, &place, &[], &mut HashMap::new());
        let rows: Vec<(u64, usize)> = entries.iter().map(|e| (e.at.uid, e.hidden_before)).collect();
        assert_eq!(rows, [(1, 0), (8, 6), (9, 0), (10, 0)]);
        assert_eq!(
            entries[1].index, 7,
            "an entry's index is its place among all the messages"
        );
    }
}
