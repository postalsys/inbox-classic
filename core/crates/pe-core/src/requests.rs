//! Work the windows start and wait for (a lookup of servers, a sign-in in the browser): run in the background,
//! announced by an event when done, its result taken once, or cancelled

use std::collections::HashMap;
use std::sync::{Arc, Mutex, MutexGuard};

use crate::{Event, EventSink};

enum State<T> {
    Running(tokio::task::AbortHandle),
    Done(T),
}

pub(crate) struct Requests<T>(Arc<Mutex<HashMap<u64, State<T>>>>);

impl<T> Default for Requests<T> {
    fn default() -> Self {
        Requests(Arc::default())
    }
}

impl<T: Send + 'static> Requests<T> {
    fn map(&self) -> MutexGuard<'_, HashMap<u64, State<T>>> {
        self.0.lock().unwrap_or_else(|p| p.into_inner())
    }

    /// Runs `work` as `request`; `done` makes the event that says it finished
    pub(crate) fn start(
        &self,
        runtime: &tokio::runtime::Runtime,
        request: u64,
        work: impl Future<Output = T> + Send + 'static,
        events: EventSink,
        done: fn(u64) -> Event,
    ) {
        let results = self.0.clone();
        // held while the work starts, so it can not finish before it is listed as running
        let mut map = self.map();
        let task = runtime.spawn(async move {
            let result = work.await;
            results
                .lock()
                .unwrap_or_else(|p| p.into_inner())
                .insert(request, State::Done(result));
            events(done(request));
        });
        map.insert(request, State::Running(task.abort_handle()));
    }

    /// The result of finished work, taken; None while it runs or when there is no such request
    pub(crate) fn take(&self, request: u64) -> Option<T> {
        let mut map = self.map();
        match map.get(&request)? {
            State::Running(_) => None,
            State::Done(_) => match map.remove(&request) {
                Some(State::Done(result)) => Some(result),
                _ => None,
            },
        }
    }

    /// Takes the result when `keep` says so, otherwise leaves it; `inspect` sees it either way. None while the
    /// work runs or when there is no such request.
    pub(crate) fn inspect<R>(&self, request: u64, inspect: impl FnOnce(&T) -> (R, bool)) -> Option<R> {
        let mut map = self.map();
        let State::Done(result) = map.get(&request)? else {
            return None;
        };
        let (answer, keep) = inspect(result);
        if !keep {
            map.remove(&request);
        }
        Some(answer)
    }

    /// Stops work the user no longer waits for, and forgets it
    pub(crate) fn cancel(&self, request: u64) {
        if let Some(State::Running(task)) = self.map().remove(&request) {
            task.abort();
        }
    }
}
