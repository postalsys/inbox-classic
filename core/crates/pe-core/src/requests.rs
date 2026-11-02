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
            // only for a request still listed: one cancelled while it finished is not kept (nobody takes it)
            let kept = match results.lock().unwrap_or_else(|p| p.into_inner()).get_mut(&request) {
                Some(entry) => {
                    *entry = State::Done(result);
                    true
                }
                None => false,
            };
            if kept {
                events(done(request));
            }
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

#[cfg(test)]
mod tests {
    use super::*;
    use std::time::Duration;

    fn runtime() -> tokio::runtime::Runtime {
        tokio::runtime::Builder::new_multi_thread()
            .worker_threads(1)
            .enable_all()
            .build()
            .unwrap()
    }

    fn sink() -> (EventSink, Arc<Mutex<Vec<u64>>>) {
        let seen: Arc<Mutex<Vec<u64>>> = Arc::default();
        let into = seen.clone();
        let sink: EventSink = Arc::new(move |event| {
            if let Event::ViewReady { request } = event {
                into.lock().unwrap().push(request);
            }
        });
        (sink, seen)
    }

    #[test]
    fn a_result_is_taken_once() {
        let runtime = runtime();
        let requests: Requests<u32> = Requests::default();
        let (events, seen) = sink();
        requests.start(&runtime, 7, async { 42 }, events, |request| Event::ViewReady {
            request,
        });
        for _ in 0..200 {
            if !seen.lock().unwrap().is_empty() {
                break;
            }
            std::thread::sleep(Duration::from_millis(5));
        }
        assert_eq!(*seen.lock().unwrap(), [7]);
        assert_eq!(requests.take(7), Some(42));
        assert_eq!(requests.take(7), None);
    }

    #[test]
    fn a_cancelled_request_leaves_nothing() {
        let runtime = runtime();
        let requests: Requests<u32> = Requests::default();
        let (events, seen) = sink();
        let (release, wait) = tokio::sync::oneshot::channel::<()>();
        requests.start(
            &runtime,
            9,
            async move {
                // finishes even if the abort comes late: it must still not be kept
                let _ = wait.await;
                1
            },
            events,
            |request| Event::ViewReady { request },
        );
        requests.cancel(9);
        let _ = release.send(());
        std::thread::sleep(Duration::from_millis(50));
        assert!(seen.lock().unwrap().is_empty());
        assert_eq!(requests.take(9), None);
        assert!(requests.map().is_empty());
    }
}
