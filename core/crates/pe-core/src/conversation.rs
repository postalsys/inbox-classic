//! A conversation in the reading pane: a collapsed conversation's row opens all of its messages, one under another,
//! the read ones folded to a line, at its focus message (its oldest unread one, else its newest).
//!
//! The view is the focus message's own [`MessageView`] (its header, attachments and bars are what the window shows
//! around the page; Reply, Forward and Print act on it), with its `document` replaced by the conversation's page
//! ([`pe_html::conversation_page`]) and `part_documents` holding the document of each open message, served at `part-N`
//! as a signed message's parts are. The messages are the conversation's in every folder of its account but Junk
//! E-mail and Deleted Items ([`pe_store::Store::conversation_messages`]): the user's own replies, drafts and filed
//! messages, each labelled with its folder. A signed or encrypted message is never opened in the stack: its line says
//! it opens by itself, and a click shows it alone, as every such message is shown (docs/pgp-plan.md).
//!
//! What is open and which message has the focus is kept here for each conversation shown lately, so a line clicked
//! ([`Core::conversation_click`]) and the view built again agree.

use std::collections::{BTreeSet, HashMap};
use std::sync::Mutex;

use pe_i18n::{Text, tr, tr_args};
use pe_store::{FolderId, Message, MessageRef, Protection, Store};

use crate::view::MessageView;

/// How many lines a long conversation shows before "Show N earlier messages"
pub(crate) const SHOWN_AT_FIRST: usize = 20;

/// The conversations kept: the reading pane's and those of a few message windows
const KEPT: usize = 8;

/// What the reading pane shows of a conversation besides its focus message's view
#[derive(Debug, Clone, PartialEq, Eq, Default)]
pub struct ConversationInfo {
    /// Its messages in the reading pane
    pub count: usize,
    /// Open messages whose source is still downloading: when one is ready ([`crate::Event::MessageReady`]), the app
    /// builds the view again
    pub waiting: Vec<MessageRef>,
}

/// One conversation as it was shown last
#[derive(Debug, Default)]
struct Shown {
    focus: Option<MessageRef>,
    open: BTreeSet<MessageRef>,
    /// "Show N earlier messages" was clicked
    all: bool,
    /// Its messages in the order of the page's lines: a line's N is its place here
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
}

/// A message's line, as the page writes it
pub(crate) struct Line {
    pub at: MessageRef,
    /// Its place in the conversation: the N of its link and of its document's `part-N`
    pub index: usize,
    pub from: String,
    pub when: String,
    pub words: String,
    pub folder: String,
    pub note: String,
    pub unread: bool,
    pub open: bool,
    pub focus: bool,
}

/// The order and the choices of a conversation shown: which message is open, which has the focus, which lines show
pub(crate) struct Plan {
    /// The messages in the page's order, each with whether it is open
    pub messages: Vec<(Message, bool)>,
    pub focus: MessageRef,
    /// The place of the first line shown (the earlier ones wait behind a link)
    pub first: usize,
}

/// Whether a message is never opened in the stack, as the store knows it: signed or encrypted as a whole. One with a
/// signed or encrypted part inside is found when its view is built ([`crate::Core::conversation_view`]).
pub(crate) fn alone(message: &Message) -> bool {
    message.info.protection != Protection::None
}

impl Conversations {
    /// The plan of the conversation `thread` of `messages` (as they arrived) opened at `focus`: what was open when it
    /// was shown last, its unread messages that were not unread then (all of them the first time), and the focus open; `newest_first` turns the order
    pub(crate) fn plan(&self, thread: i64, messages: Vec<Message>, focus: MessageRef, newest_first: bool) -> Plan {
        let mut messages = messages;
        if newest_first {
            messages.reverse();
        }
        self.with(thread, |shown| {
            let present: BTreeSet<MessageRef> = messages.iter().map(Message::at).collect();
            // what is unread opens: the first time all of it, then what became unread since (a reply that came, one
            // marked unread); an unread one the user folded stays folded
            let unread: BTreeSet<MessageRef> = messages
                .iter()
                .filter(|m| !m.info.seen() && !alone(m))
                .map(Message::at)
                .collect();
            shown.open.extend(unread.difference(&shown.unread).copied());
            shown.unread = unread;
            shown.open.retain(|at| present.contains(at));
            shown.focus = Some(focus);
            shown.open.insert(focus);
            shown.order = messages.iter().map(Message::at).collect();
            let at = shown.order.iter().position(|m| *m == focus).unwrap_or(0);
            // a long conversation starts with its later lines (newest first: its first ones), the focus among them
            let first = match (shown.all, newest_first) {
                (true, _) | (_, true) => 0,
                (false, false) => messages.len().saturating_sub(SHOWN_AT_FIRST).min(at),
            };
            let last = match (shown.all, newest_first) {
                (false, true) => messages.len().min(SHOWN_AT_FIRST.max(at + 1)),
                _ => messages.len(),
            };
            let messages: Vec<(Message, bool)> = messages
                .into_iter()
                .take(last)
                .map(|m| {
                    let open = shown.open.contains(&m.at()) && !alone(&m);
                    (m, open)
                })
                .collect();
            shown.marks = messages
                .iter()
                .skip(first)
                .filter(|(m, open)| *open && !m.info.seen())
                .map(|(m, _)| m.at())
                .collect();
            Plan { messages, focus, first }
        })
    }

    /// A line clicked: a folded message opens and takes the focus; an open one folds (the focus stays where it is,
    /// unless it was that one: then the nearest open message has it). The message to show now, None when the line is
    /// not of a conversation shown.
    pub(crate) fn click(&self, thread: i64, index: usize) -> Option<MessageRef> {
        self.with(thread, |shown| {
            let at = *shown.order.get(index)?;
            let focus = shown.focus?;
            if !shown.open.contains(&at) {
                shown.open.insert(at);
                shown.focus = Some(at);
                return Some(at);
            }
            if at != focus {
                shown.open.remove(&at);
                return Some(focus);
            }
            // the focus folded: the open message nearest to it has it, or it stays, folded, when none is open
            shown.open.remove(&at);
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

    /// "Show N earlier messages" clicked: every line shows from now on
    pub(crate) fn show_all(&self, thread: i64) {
        self.with(thread, |shown| shown.all = true);
    }

    /// The unread messages the conversation showed open, to mark read now that the window shows them
    pub(crate) fn marks(&self, thread: i64) -> Vec<MessageRef> {
        self.with(thread, |shown| std::mem::take(&mut shown.marks))
    }

    /// Messages found to be signed or encrypted when their views were built: never in the stack, so neither open nor
    /// marked read by it
    pub(crate) fn alone_found(&self, thread: i64, found: &BTreeSet<MessageRef>) {
        if found.is_empty() {
            return;
        }
        self.with(thread, |shown| {
            shown.marks.retain(|at| !found.contains(at));
            shown.open.retain(|at| !found.contains(at) || shown.focus == Some(*at));
        });
    }
}

/// A message's sender as its line names it: the name, else the address
fn sender(message: &Message) -> String {
    let info = &message.info;
    if info.from_name.trim().is_empty() {
        info.from_address.clone()
    } else {
        info.from_name.clone()
    }
}

/// The lines of a plan: who, when, the first words or (open) who it went to, its folder when not `home`, and its state;
/// `protected`: messages found signed or encrypted when their views were built, shown folded as opening by themselves
pub(crate) fn lines(
    plan: &Plan,
    home: FolderId,
    folders: &HashMap<FolderId, pe_store::FolderInfo>,
    waiting: &[MessageRef],
    protected: &BTreeSet<MessageRef>,
) -> Vec<Line> {
    plan.messages
        .iter()
        .enumerate()
        .skip(plan.first)
        .map(|(index, (message, open))| {
            let at = message.at();
            let sealed = alone(message) || protected.contains(&at);
            let open = &(*open && !sealed);
            let info = &message.info;
            let place = folders.get(&message.folder_id);
            let folder = match place {
                Some(place) if message.folder_id != home => crate::text::folder_name(place),
                _ => String::new(),
            };
            let draft = place.is_some_and(|f| f.special_use.as_deref() == Some("\\Drafts"));
            let note = if sealed {
                tr(Text::UiConversationAlone)
            } else if waiting.contains(&at) {
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
            let words = match open {
                true if !people.is_empty() => tr_args(Text::UiConversationTo, &[("people", people.as_str().into())]),
                _ => message.snippet.clone().unwrap_or_default(),
            };
            let when = info
                .date
                .or(info.internal_date)
                .map(crate::calendar::local_date_time)
                .unwrap_or_default();
            Line {
                at,
                index,
                from: sender(message),
                when,
                words,
                folder,
                note,
                unread: !info.seen(),
                open: *open,
                focus: at == plan.focus,
            }
        })
        .collect()
}

/// The words of the link to a long conversation's earlier lines, None when every line shows
pub(crate) fn earlier_words(plan: &Plan) -> Option<String> {
    (plan.first > 0).then(|| tr_args(Text::UiConversationEarlier, &[("count", plan.first.into())]))
}

/// The page of `lines` with the focus message's view: its document goes to the focus's place among the parts, each
/// other open message's document (`documents`, by place) to its own, the page in its place; what is printed stays the
/// focus message's own
pub(crate) fn into_view(
    mut view: MessageView,
    plan: &Plan,
    lines: &[Line],
    mut documents: HashMap<MessageRef, String>,
    pictures: bool,
    waiting: Vec<MessageRef>,
) -> MessageView {
    let focus_document = std::mem::take(&mut view.document);
    view.print_document = Some(view.print_document.take().unwrap_or_else(|| focus_document.clone()));
    documents.insert(plan.focus, focus_document);
    let mut parts = vec![String::new(); plan.messages.len()];
    for line in lines {
        if line.open
            && let Some(document) = documents.remove(&line.at)
        {
            parts[line.index] = document;
        }
    }
    let shown: Vec<pe_html::ConversationLine> = lines
        .iter()
        .map(|line| pe_html::ConversationLine {
            from: &line.from,
            when: &line.when,
            words: &line.words,
            folder: &line.folder,
            note: &line.note,
            unread: line.unread,
            // a message still downloading has no document yet: its line only
            open: line.open && !parts[line.index].is_empty(),
            focus: line.focus,
        })
        .collect();
    let earlier = earlier_words(plan);
    view.document =
        pe_html::conversation_page(&shown, plan.first, earlier.as_deref(), pictures || view.pictures_loaded);
    view.part_documents = parts;
    view.conversation = Some(ConversationInfo {
        count: plan.messages.len(),
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
        if alone(message) {
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

    #[test]
    fn opens_the_unread_ones_and_the_focus_and_keeps_what_was_clicked() {
        let shown = Conversations::default();
        let all = || vec![message(1, true), message(2, false), message(3, true), message(4, false)];
        let plan = shown.plan(7, all(), at(2), false);
        assert_eq!(open(&plan), [2, 4], "the unread messages open, the focus among them");
        assert_eq!(shown.marks(7), [at(2), at(4)]);
        // a folded line opens and takes the focus; an open one folds
        assert_eq!(shown.click(7, 0), Some(at(1)));
        assert_eq!(open(&shown.plan(7, all(), at(1), false)), [1, 2, 4]);
        assert_eq!(shown.click(7, 3), Some(at(1)), "folding another keeps the focus");
        assert_eq!(open(&shown.plan(7, all(), at(1), false)), [1, 2]);
        // the focus folded: the nearest open message has it
        assert_eq!(shown.click(7, 0), Some(at(2)));
        assert_eq!(open(&shown.plan(7, all(), at(2), false)), [2]);
        assert_eq!(shown.click(7, 9), None, "a line that is not there");
        assert_eq!(shown.click(8, 0), None, "a conversation not shown");
        // marks are taken once
        shown.plan(9, all(), at(4), false);
        assert_eq!(shown.marks(9), [at(2), at(4)]);
        assert!(shown.marks(9).is_empty());
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
        assert_eq!(shown.click(1, 0), Some(at(3)), "the newest is the first line");
    }

    #[test]
    fn signed_or_encrypted_messages_never_open_in_the_stack() {
        let shown = Conversations::default();
        let mut sealed = message(2, false);
        sealed.info.protection = Protection::Encrypted;
        let plan = shown.plan(1, vec![message(1, false), sealed], at(1), false);
        assert_eq!(open(&plan), [1]);
        assert_eq!(
            shown.marks(1),
            [at(1)],
            "an encrypted message stays unread until it is opened by itself"
        );
    }

    #[test]
    fn a_long_conversation_shows_its_later_lines_first() {
        let shown = Conversations::default();
        let many = || (1..=30).map(|uid| message(uid, uid != 30)).collect::<Vec<_>>();
        let plan = shown.plan(1, many(), at(30), false);
        assert_eq!(plan.first, 10, "20 lines, the newest among them");
        pe_i18n::set_language("en");
        assert_eq!(earlier_words(&plan).as_deref(), Some("Show 10 earlier messages"));
        // the focus is always shown
        assert_eq!(shown.plan(1, many(), at(3), false).first, 2);
        shown.show_all(1);
        assert_eq!(shown.plan(1, many(), at(30), false).first, 0);
        assert!(earlier_words(&shown.plan(1, many(), at(30), false)).is_none());
        // newest first: its first 20 lines
        let fresh = Conversations::default();
        let plan = fresh.plan(1, many(), at(30), true);
        assert_eq!((plan.first, plan.messages.len()), (0, 20));
    }

    #[test]
    fn lines_say_where_each_message_is() {
        pe_i18n::set_language("en");
        let shown = Conversations::default();
        let mut sent = message(2, true);
        sent.folder_id = 2;
        sent.info.recipient_people = "Ann".into();
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
        let lines = lines(&plan, 1, &folders, &[], &BTreeSet::new());
        assert_eq!(lines[0].folder, "", "the folder it was opened from is not named");
        assert_eq!(lines[0].words, "words 1", "open with no recipients: its first words");
        assert_eq!(
            (lines[1].folder.as_str(), lines[1].words.as_str()),
            ("Sent Items", "words 2")
        );
        assert_eq!((lines[2].folder.as_str(), lines[2].note.as_str()), ("Drafts", "Draft"));
        assert!(lines[0].focus && lines[0].open && lines[0].unread && !lines[1].open);
    }
}
