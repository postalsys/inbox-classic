//! What the core is doing for the windows: the syncs asked for and not finished, the actions queued and not done.
//! [`Core::quiet`] says when there is none, so a test (the deep test's drivers, docs/deep-test-plan.md) waits for the
//! state rather than for a time: a sync asked for after a change is finished only once the commands queued before it
//! are, as each account's worker runs them in order.

use std::collections::HashSet;
use std::sync::{Mutex, MutexGuard};

use pe_store::AccountId;

use crate::{Core, Event, Result};

#[derive(Default)]
pub(crate) struct Activity {
    state: Mutex<State>,
}

#[derive(Default)]
struct State {
    syncing: HashSet<AccountId>,
    actions: u64,
    /// Barriers asked for and not answered by every account's worker
    barriers: u64,
}

impl Activity {
    fn state(&self) -> MutexGuard<'_, State> {
        self.state.lock().unwrap_or_else(|e| e.into_inner())
    }

    /// An event on its way to the windows: what it ends
    pub(crate) fn saw(&self, event: &Event) {
        match event {
            Event::SyncFinished { account, .. } => {
                self.state().syncing.remove(account);
            }
            Event::Acted { .. } => self.action_done(),
            _ => {}
        }
    }

    pub(crate) fn sync_asked(&self, account: AccountId) {
        self.state().syncing.insert(account);
    }

    pub(crate) fn action_queued(&self) {
        self.state().actions += 1;
    }

    /// An action queued is done, or was never queued after all
    pub(crate) fn action_done(&self) {
        let mut state = self.state();
        state.actions = state.actions.saturating_sub(1);
    }

    /// An account gone: its sync never finishes
    pub(crate) fn forget(&self, account: AccountId) {
        self.state().syncing.remove(&account);
    }
}

impl Core {
    /// Nothing asked of the core is under way: no sync asked for (Send/Recv, a new account) that has not finished, no
    /// action of the user's queued that is not done, no [`Core::sync_barrier`] not passed
    pub fn quiet(&self) -> bool {
        let state = self.activity.state();
        state.syncing.is_empty() && state.actions == 0 && state.barriers == 0
    }

    /// Every account synced, then a barrier behind the sync in each account's worker: [`Core::quiet`] is false until
    /// every barrier is passed, so until the syncs asked for now and everything queued before them are done. A sync
    /// that was running already when this was asked can not end it early, as a finished sync alone could. For tests
    /// (the deep test's drivers) that wait for the state, not for a time.
    pub fn sync_barrier(self: &std::sync::Arc<Self>) -> Result<()> {
        let mut answers = Vec::new();
        // read first: the store's lock is not held while the syncs are asked for, which take it themselves
        let accounts = self.store().accounts()?;
        for account in accounts {
            if self.sync(account.id).is_err() {
                continue;
            }
            let (reply, answer) = tokio::sync::oneshot::channel();
            if self
                .send_command(account.id, crate::worker::Command::Barrier { reply })
                .is_ok()
            {
                answers.push(answer);
            }
        }
        self.activity.state().barriers += 1;
        let activity = self.activity.clone();
        self.runtime()?.spawn(async move {
            for answer in answers {
                // a worker that stops answers no more: it is passed all the same
                let _ = answer.await;
            }
            let mut state = activity.state();
            state.barriers = state.barriers.saturating_sub(1);
        });
        Ok(())
    }
}

#[cfg(test)]
mod tests {
    use std::time::{Duration, Instant};

    #[test]
    fn a_barrier_is_passed_once_the_workers_are_done() {
        let dir = pe_testkit::TempDir::new("core-barrier");
        // an account whose server is not there: its sync fails, the barrier behind it is passed all the same
        let (core, _, _events) = crate::list_load::tests::opened(&dir, 3);
        assert!(core.quiet());
        core.sync_barrier().unwrap();
        assert!(!core.quiet(), "a barrier asked for is under way");
        let until = Instant::now() + pe_testkit::patience();
        while !core.quiet() {
            assert!(Instant::now() < until, "the barrier was never passed");
            std::thread::sleep(Duration::from_millis(50));
        }
    }
}
