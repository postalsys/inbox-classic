//! The store connections of the work the core does off the window thread. The windows read through the core's own
//! connection ([`Core::store`] on their threads); a list loaded in the background, a message's source read for the
//! reading pane, a draft and an attachment, the user's actions on many messages, and the pictures of the list each read
//! and write through a connection of their own, so the window thread never waits behind them (SQLite in WAL mode lets them read while
//! another writes).
//!
//! The code of the core asks [`Core::store`] for its connection wherever it runs: on a thread doing background work
//! ([`on`]) that is the work's connection, so the same functions serve both.

use std::cell::Cell;
use std::path::Path;
use std::sync::{Arc, Mutex, MutexGuard, OnceLock, Weak};

use pe_store::Store;

use crate::Core;

/// Which connection the code running on a thread uses
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub(crate) enum Connection {
    /// The windows' own
    Window,
    /// Lists loaded in the background (list_view.rs)
    Lists,
    /// Sources read for the reading pane, drafts and attachments
    Reads,
    /// The user's actions on messages, one after another
    Actions,
    /// The pictures of the list and the reading pane: contact pictures and the brands' logos kept
    Pictures,
}

thread_local! {
    static CURRENT: Cell<Connection> = const { Cell::new(Connection::Window) };
}

/// The connection of this thread
pub(crate) fn current() -> Connection {
    CURRENT.with(Cell::get)
}

/// Runs `f` with [`Core::store`] giving `connection` on this thread; the one before is back after
pub(crate) fn on<T>(connection: Connection, f: impl FnOnce() -> T) -> T {
    struct Back(Connection);
    impl Drop for Back {
        fn drop(&mut self) {
            CURRENT.with(|current| current.set(self.0));
        }
    }
    let _back = Back(CURRENT.with(|current| current.replace(connection)));
    f()
}

/// A connection held while it is used: the windows' own, or one of background work
pub(crate) enum Held<'a> {
    Window(MutexGuard<'a, Store>),
    Own(MutexGuard<'a, Option<Store>>),
}

impl std::ops::Deref for Held<'_> {
    type Target = Store;

    fn deref(&self) -> &Store {
        match self {
            Held::Window(store) => store,
            Held::Own(store) => store.as_ref().expect("opened"),
        }
    }
}

impl std::ops::DerefMut for Held<'_> {
    fn deref_mut(&mut self) -> &mut Store {
        match self {
            Held::Window(store) => store,
            Held::Own(store) => store.as_mut().expect("opened"),
        }
    }
}

/// `own`, opened when it is not yet; None when it can not be
pub(crate) fn open<'a>(own: &'a Mutex<Option<Store>>, path: &Path) -> Option<Held<'a>> {
    let mut held = own.lock().unwrap_or_else(|poisoned| poisoned.into_inner());
    if held.is_none() {
        *held = Store::open(path).ok();
    }
    held.is_some().then_some(Held::Own(held))
}

/// Work of the user's actions, run one after another in the order asked
pub(crate) type Job = Box<dyn FnOnce(&Core) + Send>;

/// The connections of background work, each opened by the first work that needs it
#[derive(Default)]
pub(crate) struct Connections {
    pub(crate) lists: Mutex<Option<Store>>,
    pub(crate) reads: Mutex<Option<Store>>,
    pub(crate) actions: Mutex<Option<Store>>,
    pub(crate) pictures: Mutex<Option<Store>>,
    /// Where the actions' work goes, started with the first
    queue: OnceLock<tokio::sync::mpsc::UnboundedSender<Job>>,
}

impl Core {
    /// Runs `work` on a thread of the core's blocking pool, on `connection`: None once the core is closing
    pub(crate) fn in_background<T: Send + 'static>(
        self: &Arc<Self>,
        connection: Connection,
        work: impl FnOnce(&Core) -> T + Send + 'static,
    ) -> impl Future<Output = Option<T>> + Send + 'static {
        in_background(Arc::downgrade(self), connection, work)
    }

    /// Queues `job`, an action of the user's, to run after the ones queued before it, on the actions' connection.
    /// Dropped when the core is closing.
    pub(crate) fn queue_action(self: &Arc<Self>, job: Job) -> crate::Result<()> {
        let queue = match self.connections.queue.get() {
            Some(queue) => queue,
            None => {
                let (sender, receiver) = tokio::sync::mpsc::unbounded_channel();
                // a race to start it: one wins, the other's receiver is dropped unused
                if self.connections.queue.set(sender).is_ok() {
                    self.runtime()?.spawn(run_actions(Arc::downgrade(self), receiver));
                }
                self.connections.queue.get().ok_or(crate::Error::Closed)?
            }
        };
        queue.send(job).map_err(|_| crate::Error::Closed)
    }
}

/// [`Core::in_background`] for work that holds the core only by a weak handle until it runs (a task of the core's own
/// runtime, which must never drop the last handle)
pub(crate) async fn in_background<T: Send + 'static>(
    core: Weak<Core>,
    connection: Connection,
    work: impl FnOnce(&Core) -> T + Send + 'static,
) -> Option<T> {
    tokio::task::spawn_blocking(move || {
        let core = core.upgrade()?;
        Some(on(connection, || work(&core)))
    })
    .await
    .ok()
    .flatten()
}

/// Runs the actions' jobs one at a time
async fn run_actions(core: Weak<Core>, mut jobs: tokio::sync::mpsc::UnboundedReceiver<Job>) {
    while let Some(job) = jobs.recv().await {
        let core = core.clone();
        let ran = tokio::task::spawn_blocking(move || {
            if let Some(core) = core.upgrade() {
                on(Connection::Actions, || job(&core));
            }
        });
        let _ = ran.await;
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn the_connection_is_the_threads_until_the_work_ends() {
        assert_eq!(current(), Connection::Window);
        on(Connection::Lists, || {
            assert_eq!(current(), Connection::Lists);
            on(Connection::Reads, || assert_eq!(current(), Connection::Reads));
            assert_eq!(current(), Connection::Lists);
            std::thread::spawn(|| assert_eq!(current(), Connection::Window))
                .join()
                .unwrap();
        });
        assert_eq!(current(), Connection::Window);
        let _ = std::panic::catch_unwind(|| on(Connection::Actions, || panic!("a panic")));
        assert_eq!(current(), Connection::Window, "back after a panic too");
    }
}
