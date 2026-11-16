//! Message lists loaded off the window thread: a window asks for its list (the counts, the row count, the first page
//! and where a message is) or for a page of it, and draws what [`Event::ListReady`] or [`Event::ListPageReady`]
//! brings. The work reads on a store connection of its own (connections.rs), so the window never waits for it. The
//! newest load of a view wins: one asked for later cancels those before it, and a page read for a list loaded since is
//! dropped.

use std::collections::HashMap;
use std::sync::{Arc, Mutex};

use pe_store::{FolderId, MessageRef};

use crate::connections::Connection;
use crate::list_view::{ListLoad, ListView};
use crate::requests::Requests;
use crate::{Core, Event, Result};

/// The loads under way and done, and which are each view's
#[derive(Default)]
pub(crate) struct ListLoads {
    results: Requests<Option<ListLoad>>,
    views: Arc<Mutex<HashMap<u64, ViewLoads>>>,
}

/// A view's loads
#[derive(Default)]
struct ViewLoads {
    /// Its newest load of the whole list
    newest: u64,
    /// Its loads not yet taken: those a newer load of the list cancels
    requests: Vec<u64>,
}

impl ListLoads {
    fn views(&self) -> std::sync::MutexGuard<'_, HashMap<u64, ViewLoads>> {
        self.views.lock().unwrap_or_else(|e| e.into_inner())
    }

    /// Whether `request` of the view `view` was not overtaken by a newer load of its list
    fn current(views: &Mutex<HashMap<u64, ViewLoads>>, view: u64, base: u64) -> bool {
        let views = views.lock().unwrap_or_else(|e| e.into_inner());
        views.get(&view).is_some_and(|loads| loads.newest == base)
    }
}

impl Core {
    /// Loads the list `view` shows in the background, on a store connection of its own: its counts, its row count, the
    /// first [`crate::LIST_PAGE`] rows and, when `place` names a message (and the row it had, when known), where that
    /// is. [`Event::ListReady`] follows with the request this returns and `generation`, the window's number for the
    /// load, unless a newer load of the same view came first: that cancels this one and the pages asked for before
    /// it. What it read is kept for the view, as its calls on the window thread keep what they read.
    pub fn list_load(
        self: &Arc<Self>,
        view: &ListView,
        generation: u64,
        place: Option<(FolderId, u64, Option<u64>)>,
    ) -> Result<u64> {
        let request = self.next_request.fetch_add(1, std::sync::atomic::Ordering::Relaxed);
        let id = view.view_id();
        let older = {
            let mut views = self.list_loads.views();
            let loads = views.entry(id).or_default();
            loads.newest = request;
            std::mem::replace(&mut loads.requests, vec![request])
        };
        for old in older {
            self.list_loads.results.cancel(old);
        }
        let place = place.map(|(folder, uid, hint)| (MessageRef { folder, uid }, hint));
        self.start_load(view, generation, request, request, 0, true, place, move |request| {
            Event::ListReady { request, generation }
        })
    }

    /// Loads [`crate::LIST_PAGE`] rows of the list `view` shows from `offset` on, in the background as
    /// [`Core::list_load`] does: [`Event::ListPageReady`] follows with the request this returns and `generation`. A
    /// window asks for the page after the one shown too, so it is there when scrolled to. Dropped when a load of the
    /// whole list comes after it.
    pub fn list_load_page(self: &Arc<Self>, view: &ListView, generation: u64, offset: u64) -> Result<u64> {
        let request = self.next_request.fetch_add(1, std::sync::atomic::Ordering::Relaxed);
        let base = {
            let mut views = self.list_loads.views();
            let loads = views.entry(view.view_id()).or_default();
            loads.requests.push(request);
            loads.newest
        };
        self.start_load(view, generation, request, base, offset, false, None, move |request| {
            Event::ListPageReady { request, generation }
        })
    }

    #[allow(clippy::too_many_arguments)]
    fn start_load(
        self: &Arc<Self>,
        view: &ListView,
        generation: u64,
        request: u64,
        base: u64,
        offset: u64,
        counted: bool,
        place: Option<(MessageRef, Option<u64>)>,
        done: impl FnOnce(u64) -> Event + Send + 'static,
    ) -> Result<u64> {
        let at = ListView::moment_now(self)?;
        let snapshot = view.snapshot();
        let id = snapshot.view_id();
        let views = self.list_loads.views.clone();
        let work = self.in_background(Connection::Lists, move |core| {
            let dropped = || !ListLoads::current(&views, id, base);
            let load = snapshot.load(core, at, offset, counted, place, &dropped).ok().flatten();
            load.map(|load| ListLoad { generation, ..load })
        });
        let work = async move { work.await.flatten() };
        self.list_loads
            .results
            .start(self.runtime()?, request, work, self.events.clone(), done);
        Ok(request)
    }

    /// What a load read, once its event came, taken once: None for an unknown request, one still running, or one
    /// that failed or was dropped
    pub fn list_load_result(&self, request: u64) -> Option<ListLoad> {
        let load = self.list_loads.results.take(request).flatten();
        let mut views = self.list_loads.views();
        views.retain(|_, loads| {
            loads.requests.retain(|r| *r != request);
            !loads.requests.is_empty()
        });
        load
    }

    /// Drops a load nobody waits for (its window closed)
    pub fn list_load_cancel(&self, request: u64) {
        self.list_loads.results.cancel(request);
        let mut views = self.list_loads.views();
        views.retain(|_, loads| {
            loads.requests.retain(|r| *r != request);
            !loads.requests.is_empty()
        });
    }
}

#[cfg(test)]
pub(crate) mod tests {
    use super::*;
    use crate::{ListView, Scope};
    use pe_store::{AccountSettings, FolderInfo, MessageInfo};
    use std::sync::mpsc::{Receiver, channel};
    use std::time::{Duration, Instant};

    /// A core with an Inbox of `count` messages, every third unread, in conversations of three; its events
    pub(crate) fn opened(dir: &pe_testkit::TempDir, count: u64) -> (Arc<Core>, FolderId, Receiver<Event>) {
        let (sender, events) = channel();
        let sender = Mutex::new(sender);
        let options = crate::Options {
            passwords: crate::PasswordStore::Memory,
            ..Default::default()
        };
        let core = Core::open_with(dir.path().join("store.db"), options, move |event| {
            let _ = sender.lock().unwrap().send(event);
        })
        .unwrap();
        let store = core.store();
        let account = store
            .add_account(&AccountSettings {
                email: "a@example.com".into(),
                ..Default::default()
            })
            .unwrap();
        let folder = FolderInfo {
            path: "INBOX".into(),
            name: "INBOX".into(),
            selectable: true,
            ..Default::default()
        };
        store.set_folders(account, &[folder]).unwrap();
        let inbox = store.folders(account).unwrap()[0].id;
        let messages: Vec<MessageInfo> = (1..=count)
            .map(|uid| {
                let first = uid - (uid - 1) % 3;
                MessageInfo {
                    uid,
                    date: Some(uid as i64 * 60),
                    subject: format!("m{uid}"),
                    message_id: Some(format!("<{uid}@x>")),
                    references: (uid != first).then(|| format!("<{first}@x>")).into_iter().collect(),
                    flags: if uid % 3 == 0 { vec![] } else { vec!["\\Seen".into()] },
                    ..Default::default()
                }
            })
            .collect();
        store.add_messages(inbox, &messages).unwrap();
        drop(store);
        (Arc::new(core), inbox, events)
    }

    /// The next list event, waiting a while for it
    fn next_ready(events: &Receiver<Event>) -> (u64, u64, bool) {
        let until = Instant::now() + Duration::from_secs(20);
        loop {
            match events.recv_timeout(until.saturating_duration_since(Instant::now())) {
                Ok(Event::ListReady { request, generation }) => return (request, generation, true),
                Ok(Event::ListPageReady { request, generation }) => return (request, generation, false),
                Ok(_) => {}
                Err(error) => panic!("no list event: {error}"),
            }
        }
    }

    #[test]
    fn a_load_answers_as_the_window_thread_reads() {
        let dir = pe_testkit::TempDir::new("core-list-load");
        let (core, inbox, events) = opened(&dir, 250);
        for grouped in [false, true] {
            let mut view = ListView::new();
            view.set_scope(Some(Scope::Folder(inbox)));
            view.set_grouped(grouped);
            let wanted = core.store().message(inbox, 3).unwrap().unwrap();
            let request = core.list_load(&view, 7, Some((inbox, 3, None))).unwrap();
            assert_eq!(next_ready(&events), (request, 7, true));
            let load = core.list_load_result(request).unwrap();
            assert!(core.list_load_result(request).is_none(), "taken once");
            let (total, unread, rows) = view.counts_and_rows(&core).unwrap();
            assert_eq!(
                (load.total, load.unread, load.rows),
                (total, unread, rows),
                "grouped {grouped}"
            );
            assert_eq!((total, unread), (250, 83));
            assert_eq!(load.messages, view.rows(&core, 0, crate::LIST_PAGE).unwrap());
            assert_eq!(load.messages.len() as u64, rows.min(100));
            assert_eq!(load.index, view.index_of(&core, wanted.folder_id, 3).unwrap());
            assert!(load.index.is_some() && load.counted && !load.lists_recipients);

            // the next page, and one past the end
            let page = core.list_load_page(&view, 7, 100).unwrap();
            assert_eq!(next_ready(&events), (page, 7, false));
            let read = core.list_load_result(page).unwrap();
            assert_eq!((read.offset, read.counted), (100, false));
            assert_eq!(read.messages, view.rows(&core, 100, crate::LIST_PAGE).unwrap());
            let past = core.list_load_page(&view, 7, 10_000).unwrap();
            assert_eq!(next_ready(&events), (past, 7, false));
            assert!(core.list_load_result(past).unwrap().messages.is_empty());

            // what a load read is the view's: not stale, and a click selects from its page
            let view_now = view.clone();
            assert!(view_now.stale(&core).unwrap(), "a copy keeps nothing");
            let request = core.list_load(&view, 8, None).unwrap();
            next_ready(&events);
            core.list_load_result(request).unwrap();
            assert!(!view.stale(&core).unwrap(), "grouped {grouped}");
        }
    }

    #[test]
    fn a_view_listing_nothing_loads_nothing() {
        let dir = pe_testkit::TempDir::new("core-list-load-none");
        let (core, _, events) = opened(&dir, 3);
        let request = core.list_load(&ListView::new(), 1, Some((1, 1, None))).unwrap();
        next_ready(&events);
        let load = core.list_load_result(request).unwrap();
        assert_eq!(
            (load.total, load.rows, load.messages.len(), load.index),
            (0, 0, 0, None)
        );
    }

    /// A load asked for while one runs takes its place: the older one is dropped, its event never comes, and the
    /// pages asked for before the newer load go with it
    #[test]
    fn the_newest_load_of_a_view_wins() {
        let dir = pe_testkit::TempDir::new("core-list-load-newest");
        let (core, inbox, events) = opened(&dir, 30);
        let mut view = ListView::new();
        view.set_scope(Some(Scope::Folder(inbox)));
        let other = view.clone();
        // the loads wait while the test holds their connection
        let held = crate::connections::open(&core.connections.lists, &dir.path().join("store.db")).unwrap();
        let first = core.list_load(&view, 1, None).unwrap();
        let page = core.list_load_page(&view, 1, 100).unwrap();
        let elsewhere = core.list_load(&other, 9, None).unwrap();
        let second = core.list_load(&view, 2, None).unwrap();
        drop(held);
        let mut seen = vec![next_ready(&events), next_ready(&events)];
        seen.sort();
        assert_eq!(
            seen,
            [(elsewhere, 9, true), (second, 2, true)],
            "another view's load is not dropped"
        );
        assert!(
            events.recv_timeout(Duration::from_millis(300)).is_err(),
            "nothing of the older ones"
        );
        assert!(core.list_load_result(first).is_none());
        assert!(core.list_load_result(page).is_none());
        assert_eq!(core.list_load_result(second).unwrap().generation, 2);
    }

    /// A sync writing meanwhile neither blocks a load nor makes it fail: it reads what was there before the write
    #[test]
    fn a_load_reads_while_a_sync_writes() {
        let dir = pe_testkit::TempDir::new("core-list-load-writing");
        let (core, inbox, events) = opened(&dir, 120);
        let mut view = ListView::new();
        view.set_scope(Some(Scope::Folder(inbox)));
        let (started, writing) = channel();
        let path = dir.path().join("store.db");
        let writer = std::thread::spawn(move || {
            let mut store = pe_store::Store::open(&path).unwrap();
            store
                .transaction(|store| {
                    for uid in [1, 2, 4] {
                        store.set_flags(inbox, uid, &[], None)?;
                    }
                    started.send(()).unwrap();
                    std::thread::sleep(Duration::from_millis(1500));
                    Ok(())
                })
                .unwrap();
        });
        writing.recv().unwrap();
        let asked = Instant::now();
        let request = core.list_load(&view, 1, None).unwrap();
        assert!(asked.elapsed() < Duration::from_millis(100), "the call returns at once");
        next_ready(&events);
        assert!(
            asked.elapsed() < Duration::from_millis(1000),
            "not waiting for the write"
        );
        let load = core.list_load_result(request).unwrap();
        assert_eq!((load.total, load.unread), (120, 40), "as before the write");
        writer.join().unwrap();
        assert!(
            view.stale(&core).unwrap(),
            "the write after the load was asked for makes it stale"
        );
        let request = core.list_load(&view, 2, None).unwrap();
        next_ready(&events);
        assert_eq!(core.list_load_result(request).unwrap().unread, 43);
    }
}
