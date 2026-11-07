//! Watch and Ignore Conversation: marking the conversations of the selected messages, and what a mark does to mail
//! that arrives in them (the worker's [`arrived`]).
//!
//! The rules:
//! - Watch Conversation or Ignore Conversation on messages whose conversations all have that mark takes it away;
//!   otherwise every one of their conversations gets it (in place of the other mark).
//! - Ignoring marks the conversation's unread messages read, as Thunderbird does, in the store now and on the server
//!   in the background, as Mark Read does.
//! - A message that arrives in an ignored conversation, in any folder, is marked read the same way and announced to
//!   nobody.
//! - New mail in the Inbox is announced as before; a message that arrives in a watched conversation in a folder of the
//!   user's (not Sent, Drafts, Junk, Trash, All Mail or another special folder) is announced too, and
//!   [`crate::Event::NewMail::watched`] says the newest is in a watched conversation.
//! - When a late message joins two conversations, the joined one is watched when either was and ignored only when both
//!   were (pe-store's `marks.rs`).

use pe_i18n::{Text, tr, tr_args};
use pe_store::{FolderInfo, Message, MessageRef, ThreadMark};

use crate::selection::PER_COMMAND;
use crate::{Core, Error, Event, Result};

impl Core {
    /// Watch Conversation (`mark` Watch) or Ignore Conversation (Ignore) on the messages `refs`: their conversations
    /// get the mark, or lose it when all of them have it already. Returns what the status bar says.
    pub(crate) fn mark_conversations(&self, refs: &[MessageRef], mark: ThreadMark) -> Result<String> {
        let (set, count, unseen, folders) = {
            let mut store = self.store();
            let conversations = store.conversations_of(refs)?;
            if conversations.is_empty() {
                return Err(Error::Unavailable(tr(Text::MessagesGone)));
            }
            let set = if conversations.iter().all(|c| c.mark == mark) {
                ThreadMark::None
            } else {
                mark
            };
            store.transaction(|store| {
                for c in &conversations {
                    store.set_thread_mark(c.account, c.thread, set)?;
                }
                Ok(())
            })?;
            let threads: Vec<i64> = conversations.iter().map(|c| c.thread).collect();
            let unseen = if set == ThreadMark::Ignore {
                store.unseen_in_threads(&threads)?
            } else {
                Default::default()
            };
            (
                set,
                conversations.len() as u64,
                unseen,
                store.folders_of_threads(&threads)?,
            )
        };
        for (folder, uids) in &unseen {
            for chunk in uids.chunks(PER_COMMAND) {
                self.set_flag_many(*folder, chunk, "\\Seen", true)?;
            }
        }
        // every list with a message of theirs shows the mark; set_flag_many announced those it marked read
        for (account, folder) in folders {
            if !unseen.contains_key(&folder) {
                self.post(Event::FolderChanged { account, folder })?;
            }
        }
        let text = match (mark, set) {
            (ThreadMark::Watch, ThreadMark::Watch) => Text::DoneWatched,
            (ThreadMark::Watch, _) => Text::DoneUnwatched,
            (_, ThreadMark::Ignore) => Text::DoneIgnored,
            _ => Text::DoneUnignored,
        };
        Ok(tr_args(text, &[("count", count.into())]))
    }
}

/// What the worker does with the unread messages that arrived in a folder (`fresh`, the newest first): the UIDs to
/// mark read, as their conversations are ignored, and those to announce, the newest first
pub(crate) struct Arrived {
    pub(crate) read: Vec<u64>,
    pub(crate) announced: Vec<Message>,
}

/// See [`Arrived`]: in the Inbox every one not ignored is announced; in a folder of the user's, those in watched
/// conversations; nothing elsewhere
pub(crate) fn arrived(folder: &FolderInfo, fresh: Vec<Message>) -> Arrived {
    let inbox = folder.path.eq_ignore_ascii_case("INBOX");
    let own = !pe_sync::is_special(folder);
    let mut read = Vec::new();
    let mut announced = Vec::new();
    for message in fresh {
        match message.mark {
            ThreadMark::Ignore => read.push(message.info.uid),
            ThreadMark::Watch if inbox || own => announced.push(message),
            ThreadMark::None if inbox => announced.push(message),
            _ => {}
        }
    }
    Arrived { read, announced }
}

#[cfg(test)]
mod tests {
    use super::*;
    use pe_store::MessageInfo;

    fn message(uid: u64, mark: ThreadMark) -> Message {
        Message {
            id: uid as i64,
            folder_id: 1,
            info: MessageInfo {
                uid,
                ..Default::default()
            },
            cached: false,
            thread: None,
            mark,
        }
    }

    fn folder(path: &str, special_use: Option<&str>) -> FolderInfo {
        FolderInfo {
            path: path.into(),
            name: path.into(),
            special_use: special_use.map(str::to_string),
            selectable: true,
            ..Default::default()
        }
    }

    fn fresh() -> Vec<Message> {
        vec![
            message(4, ThreadMark::Watch),
            message(3, ThreadMark::Ignore),
            message(2, ThreadMark::None),
            message(1, ThreadMark::Ignore),
        ]
    }

    fn uids(messages: &[Message]) -> Vec<u64> {
        messages.iter().map(|m| m.info.uid).collect()
    }

    #[test]
    fn the_inbox_announces_all_but_the_ignored_which_are_read() {
        let found = arrived(&folder("INBOX", None), fresh());
        assert_eq!(found.read, [3, 1]);
        assert_eq!(uids(&found.announced), [4, 2]);
    }

    #[test]
    fn a_folder_of_the_users_announces_only_the_watched() {
        let found = arrived(&folder("Lists/Rust", None), fresh());
        assert_eq!(found.read, [3, 1]);
        assert_eq!(uids(&found.announced), [4]);
    }

    #[test]
    fn special_folders_announce_nothing() {
        for (path, special) in [
            ("Sent", Some("\\Sent")),
            ("Junk", Some("\\Junk")),
            ("[Gmail]/All Mail", Some("\\All")),
            ("Deleted Items", Some("\\Trash")),
        ] {
            let found = arrived(&folder(path, special), fresh());
            assert!(found.announced.is_empty(), "{path}");
            assert_eq!(found.read, [3, 1], "{path}");
        }
    }
}
