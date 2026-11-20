//! What a list showed last and the row of the folder tree chosen, so a folder opens with a message: coming back to a
//! list selects the message it showed when it was left, else its newest (list_view.rs `arrived`), and the app starts
//! with the row it was closed on. Kept in the store from one start to the next; the window thread only touches the
//! copy in memory, and the store is written on the actions' connection.

use std::collections::{HashMap, HashSet};
use std::sync::{Arc, Mutex, MutexGuard};

use pe_store::{MessageRef, Scope};

use crate::connections::Connection;
use crate::list_view::ListView;
use crate::{Core, Result};

/// The key of the folder tree's row chosen
const ROW: &str = "tree_row";

/// What is remembered, by key, as the store keeps it (read from the store the first time it is asked for), the keys
/// changed since the store was written, and whether a write is on its way
#[derive(Default)]
pub(crate) struct Shown {
    state: Mutex<State>,
}

#[derive(Default)]
struct State {
    known: HashMap<String, Option<String>>,
    changed: HashSet<String>,
    writing: bool,
}

impl Shown {
    fn state(&self) -> MutexGuard<'_, State> {
        self.state.lock().unwrap_or_else(|e| e.into_inner())
    }
}

/// The key of what a list of `scope` remembers; None for a list that remembers nothing (a search of every folder)
fn list_key(scope: Scope) -> Option<String> {
    Some(match scope {
        Scope::Folder(folder) => format!("shown.folder:{folder}"),
        Scope::AllInboxes => "shown.inboxes".into(),
        Scope::AllSent => "shown.sent".into(),
        Scope::AllDrafts => "shown.drafts".into(),
        Scope::Flagged => "shown.flagged".into(),
        _ => return None,
    })
}

fn message_text(message: MessageRef) -> String {
    format!("{}:{}", message.folder, message.uid)
}

fn message_of(text: &str) -> Option<MessageRef> {
    let (folder, uid) = text.split_once(':')?;
    Some(MessageRef {
        folder: folder.parse().ok()?,
        uid: uid.parse().ok()?,
    })
}

impl Core {
    /// The value kept under `key`, read from the store the first time
    fn shown_value(&self, key: &str) -> Result<Option<String>> {
        if let Some(value) = self.shown.state().known.get(key) {
            return Ok(value.clone());
        }
        let value = self.store().remembered(key)?;
        self.shown.state().known.entry(key.to_string()).or_insert(value.clone());
        Ok(value)
    }

    /// `value` kept under `key`: in memory now, in the store on the actions' connection. One write is on its way at a
    /// time and writes what changed when it runs, so arrow keys held through the list make a write or two, not one a
    /// row.
    fn keep_shown(self: &Arc<Self>, key: String, value: String) -> Result<()> {
        let start = {
            let mut state = self.shown.state();
            if state.known.insert(key.clone(), Some(value)).flatten() == state.known[&key] {
                return Ok(());
            }
            state.changed.insert(key);
            !std::mem::replace(&mut state.writing, true)
        };
        if start {
            let write = self.in_background(Connection::Actions, |core| {
                loop {
                    let changed: Vec<(String, String)> = {
                        let mut state = core.shown.state();
                        let keys: Vec<String> = state.changed.drain().collect();
                        if keys.is_empty() {
                            state.writing = false;
                            return;
                        }
                        keys.into_iter()
                            .filter_map(|k| Some((k.clone(), state.known.get(&k)?.clone()?)))
                            .collect()
                    };
                    // not kept, the next start opens the folder's newest message: nothing to tell the user
                    for (key, value) in changed {
                        let _ = core.store().remember(&key, &value);
                    }
                }
            });
            self.runtime()?.spawn(write);
        }
        Ok(())
    }

    /// The message the list `view` shows in the reading pane now, for the list to select it again when it is come back
    /// to (also after a restart). A list of words typed remembers nothing; nor does one that shows several messages, so
    /// the last one shown stays.
    pub fn list_shown(self: &Arc<Self>, view: &ListView, message: MessageRef) -> Result<()> {
        if !view.text().is_empty() {
            return Ok(());
        }
        let Some(key) = view.scope().and_then(list_key) else {
            return Ok(());
        };
        self.keep_shown(key, message_text(message))
    }

    /// The message the list of `scope` showed last, None when it showed none (or no longer exists: the caller looks)
    pub(crate) fn shown_in(&self, scope: Scope) -> Result<Option<MessageRef>> {
        let Some(key) = list_key(scope) else {
            return Ok(None);
        };
        Ok(self.shown_value(&key)?.as_deref().and_then(message_of))
    }

    /// The row of the folder tree the user chose ([`crate::tree::TreeRow::key`]), for the app to start with it
    pub fn tree_chosen(self: &Arc<Self>, key: &str) -> Result<()> {
        self.keep_shown(ROW.into(), key.into())
    }

    /// The key of the row of the folder tree chosen when the app was closed, for the app to start with it when it is
    /// still in the tree; None when none was
    pub fn tree_start(&self) -> Result<Option<String>> {
        self.shown_value(ROW)
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn a_message_is_kept_as_text_and_read_back() {
        let message = MessageRef { folder: 12, uid: 4501 };
        assert_eq!(message_of(&message_text(message)), Some(message));
        assert_eq!(message_of("12"), None);
        assert_eq!(message_of("x:1"), None);
    }

    #[test]
    fn only_the_lists_of_the_tree_remember() {
        assert_eq!(list_key(Scope::Folder(7)).as_deref(), Some("shown.folder:7"));
        assert_eq!(list_key(Scope::Flagged).as_deref(), Some("shown.flagged"));
        assert_eq!(list_key(Scope::Everywhere), None);
    }
}
