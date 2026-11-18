//! The files of a view not described in time ([`super::DESCRIBE`]): shown as "Preparing…" tiles while the render
//! thread goes on reading them, and the window told once they all are ([`Event::PreviewsPrepared`]), to build the view
//! again with their previews. What came of them stays with the view while a window shows it, for the next view of the
//! message to take (never in the store, nor in the cache for a decrypted part's file), each under its file's key: a
//! view takes a description only for the very bytes it was read from, whatever place the file has in it.

use std::collections::BTreeMap;
use std::sync::{Arc, Mutex};

use super::{PreviewDescription, PreviewRefusal, unpoisoned};
use crate::{Event, EventSink};

/// What came of describing one file: its description, or why it has none
pub(crate) type Described = std::result::Result<Arc<PreviewDescription>, PreviewRefusal>;

/// What came of the files described late, by attachment (its place in the strip) and the key of its bytes
/// ([`pe_preview::key_of`], kept in memory only)
pub(crate) type Late = BTreeMap<(usize, pe_preview::Key), Described>;

/// The files of one view still being described
pub(crate) struct Preparing {
    state: Mutex<State>,
    events: EventSink,
}

#[derive(Default)]
struct State {
    /// Descriptions asked for and not come yet (or not known yet to have come in time)
    waiting: usize,
    /// A file was not described in time: the view shows it as "Preparing…"
    missed: bool,
    /// What came after the view was built
    described: Late,
    /// The view's token, once a window took it
    token: Option<String>,
    /// The window was told, or the view ended: nothing more is said
    over: bool,
}

/// A view's own: two are the same only when they are one
impl PartialEq for Preparing {
    fn eq(&self, other: &Self) -> bool {
        std::ptr::eq(self, other)
    }
}

impl Eq for Preparing {}

impl std::fmt::Debug for Preparing {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        f.debug_struct("Preparing").field("missed", &self.has_missed()).finish()
    }
}

impl Preparing {
    pub(crate) fn new(events: EventSink) -> Arc<Preparing> {
        Arc::new(Preparing {
            state: Mutex::default(),
            events,
        })
    }

    /// A description of attachment `attachment` (`file` its bytes) is asked for: what to call with it when it comes
    /// after the wait (given to [`pe_preview::Previewer::describe_or_later`]); [`Preparing::answered`] or
    /// [`Preparing::missed`] follows when the wait is over
    pub(crate) fn expect(self: &Arc<Self>, attachment: usize, file: Arc<Vec<u8>>) -> pe_preview::Later {
        unpoisoned(&self.state).waiting += 1;
        let preparing = self.clone();
        Box::new(move |described| preparing.arrived((attachment, pe_preview::key_of(&file)), described))
    }

    /// The description asked for came in time
    pub(crate) fn answered(&self) {
        let mut state = unpoisoned(&self.state);
        state.waiting = state.waiting.saturating_sub(1);
    }

    /// The description asked for did not come in time: the file is shown as "Preparing…"
    pub(crate) fn missed(&self) {
        unpoisoned(&self.state).missed = true;
    }

    /// Whether a file of the view was not described in time
    pub(crate) fn has_missed(&self) -> bool {
        unpoisoned(&self.state).missed
    }

    /// What came after the view was built, for the next view of the message
    pub(crate) fn described(&self) -> Late {
        unpoisoned(&self.state).described.clone()
    }

    /// A window took the view, `token` its `preview_token`: told when what it waits for is all there, now or later
    pub(crate) fn shown(&self, token: &str) {
        let mut state = unpoisoned(&self.state);
        state.token = Some(token.to_string());
        self.tell(state);
    }

    /// The view is no longer shown: nothing is said of it anymore
    pub(crate) fn end(&self) {
        let mut state = unpoisoned(&self.state);
        state.over = true;
        state.described.clear();
    }

    /// The description of a file (its attachment and key) came after the wait, on the render thread's dispatcher
    fn arrived(&self, file: (usize, pe_preview::Key), described: Described) {
        let mut state = unpoisoned(&self.state);
        state.waiting = state.waiting.saturating_sub(1);
        if !state.over {
            state.described.insert(file, described);
        }
        self.tell(state);
    }

    /// Tells the window once, when every file it shows as "Preparing…" is described and it shows the view
    fn tell(&self, mut state: std::sync::MutexGuard<'_, State>) {
        if state.over || !state.missed || state.waiting > 0 {
            return;
        }
        let Some(token) = state.token.clone() else {
            return;
        };
        state.over = true;
        drop(state);
        (self.events)(Event::PreviewsPrepared { token });
    }
}
