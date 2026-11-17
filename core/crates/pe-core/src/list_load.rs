//! Message lists loaded off the window thread: a window asks for its list (the counts, the row count, the first page
//! and the rows to select for what it had selected) or for a page of it, and draws what [`Event::ListReady`] or [`Event::ListPageReady`]
//! brings. The work reads on a store connection of its own (connections.rs), so the window never waits for it. The
//! newest load of a view wins: one asked for later cancels those before it, and a page read for a list loaded since is
//! dropped.

use std::collections::HashMap;
use std::sync::{Arc, Mutex};

use crate::connections::Connection;
use crate::list_view::{ListLoad, ListView, Reselect};
use crate::requests::Requests;
use crate::{Core, Event, Result};

/// The loads under way and done, and which are each view's
#[derive(Default)]
pub(crate) struct ListLoads {
    results: Requests<std::result::Result<ListLoad, String>>,
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

    /// `request` no longer one of its view's: taken or cancelled
    fn forget(&self, request: u64) {
        self.views().retain(|_, loads| {
            loads.requests.retain(|r| *r != request);
            !loads.requests.is_empty()
        });
    }

    /// Whether `request` of the view `view` was not overtaken by a newer load of its list
    fn current(views: &Mutex<HashMap<u64, ViewLoads>>, view: u64, base: u64) -> bool {
        let views = views.lock().unwrap_or_else(|e| e.into_inner());
        views.get(&view).is_some_and(|loads| loads.newest == base)
    }
}

impl Core {
    /// Loads the list `view` shows in the background, on a store connection of its own: its counts, its row count, the
    /// first [`crate::LIST_PAGE`] rows and the rows to select in it for what the window had selected (`reselect`,
    /// answered in [`ListLoad::reselected`]). [`Event::ListReady`] follows with the request this returns, unless a
    /// newer load of the same view came first: that cancels this one and the pages asked for before it, and their
    /// events never come. What it read is kept for the view, as its calls on the window thread keep what they read.
    pub fn list_load(self: &Arc<Self>, view: &ListView, reselect: Reselect) -> Result<u64> {
        let request = self.next_request.fetch_add(1, std::sync::atomic::Ordering::Relaxed);
        let older = {
            let mut views = self.list_loads.views();
            let loads = views.entry(view.view_id()).or_default();
            loads.newest = request;
            std::mem::replace(&mut loads.requests, vec![request])
        };
        for old in older {
            self.list_loads.results.cancel(old);
        }
        self.start_load(view, request, request, 0, Some(reselect), |request| Event::ListReady {
            request,
        })
    }

    /// Loads [`crate::LIST_PAGE`] rows of the list `view` shows from `offset` on, in the background as
    /// [`Core::list_load`] does: [`Event::ListPageReady`] follows with the request this returns. A window asks for the
    /// page after the one shown too, so it is there when scrolled to. Dropped (no event) when a load of the whole list
    /// comes after it.
    pub fn list_load_page(self: &Arc<Self>, view: &ListView, offset: u64) -> Result<u64> {
        let request = self.next_request.fetch_add(1, std::sync::atomic::Ordering::Relaxed);
        let base = {
            let mut views = self.list_loads.views();
            let loads = views.entry(view.view_id()).or_default();
            loads.requests.push(request);
            loads.newest
        };
        self.start_load(view, request, base, offset, None, |request| Event::ListPageReady {
            request,
        })
    }

    /// Starts the load `request` of the list `view` shows (counted, with the rows to select, when `reselect` is given),
    /// dropped once the view's newest load is not `base`
    fn start_load(
        self: &Arc<Self>,
        view: &ListView,
        request: u64,
        base: u64,
        offset: u64,
        reselect: Option<Reselect>,
        done: impl FnOnce(u64) -> Event + Send + 'static,
    ) -> Result<u64> {
        let at = ListView::moment_now(self)?;
        let snapshot = view.snapshot();
        let id = snapshot.view_id();
        let views = self.list_loads.views.clone();
        let work = self.in_background(Connection::Lists, move |core| {
            let dropped = || !ListLoads::current(&views, id, base);
            let counted = reselect.is_some();
            snapshot.load(core, at, offset, counted, reselect.as_ref(), &dropped)
        });
        let work = async move {
            match work.await {
                Some(Ok(Some(load))) => Ok(load),
                Some(Err(error)) => Err(error.to_string()),
                // dropped for a newer load (whose event is the one that comes), or the core closing
                Some(Ok(None)) | None => Err(crate::Error::Closed.to_string()),
            }
        };
        self.list_loads
            .results
            .start(self.runtime()?, request, work, self.events.clone(), done);
        Ok(request)
    }

    /// What a load read, once its event came, taken once: Err with what the status bar says when the list could not be
    /// read (the window keeps the list it shows); None for an unknown request or one still running
    pub fn list_load_result(&self, request: u64) -> Option<std::result::Result<ListLoad, String>> {
        let load = self.list_loads.results.take(request);
        self.list_loads.forget(request);
        load
    }

    /// Drops a load nobody waits for (its window closed)
    pub fn list_load_cancel(&self, request: u64) {
        self.list_loads.results.cancel(request);
        self.list_loads.forget(request);
    }
}

#[cfg(test)]
pub(crate) mod tests {
    use super::*;
    use crate::list_view::{Reselected, Reselection};
    use crate::{ListView, Scope, Selected};
    use pe_store::{AccountSettings, FolderInfo, MessageInfo};
    use pe_store::{FolderId, MessageRef};
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

    /// The next list event, waiting a while for it: its request, and whether it is of a whole list
    fn next_ready(events: &Receiver<Event>) -> (u64, bool) {
        let until = Instant::now() + Duration::from_secs(20);
        loop {
            match events.recv_timeout(until.saturating_duration_since(Instant::now())) {
                Ok(Event::ListReady { request }) => return (request, true),
                Ok(Event::ListPageReady { request }) => return (request, false),
                Ok(_) => {}
                Err(error) => panic!("no list event: {error}"),
            }
        }
    }

    /// The list of `view` loaded with `reselect`, as the window takes it after its event
    fn loaded(core: &Arc<Core>, events: &Receiver<Event>, view: &ListView, reselect: Reselect) -> ListLoad {
        let request = core.list_load(view, reselect).unwrap();
        assert_eq!(next_ready(events), (request, true));
        core.list_load_result(request).unwrap().unwrap()
    }

    /// `refs` selected
    fn listed(refs: &[MessageRef]) -> Reselect {
        Reselect {
            selected: Selected::Listed(refs.to_vec()),
            ..Reselect::default()
        }
    }

    fn inbox_view(inbox: FolderId) -> ListView {
        let mut view = ListView::new();
        view.set_scope(Some(Scope::Folder(inbox)));
        view
    }

    #[test]
    fn a_load_answers_as_the_window_thread_reads() {
        let dir = pe_testkit::TempDir::new("core-list-load");
        let (core, inbox, events) = opened(&dir, 250);
        for grouped in [false, true] {
            let mut view = inbox_view(inbox);
            view.set_grouped(grouped);
            let request = core.list_load(&view, Reselect::default()).unwrap();
            assert_eq!(next_ready(&events), (request, true));
            let load = core.list_load_result(request).unwrap().unwrap();
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
            assert!(load.counted && !load.lists_recipients);
            assert_eq!(load.reselected, Reselected::default(), "nothing selected");

            // the next page, and one past the end
            let page = core.list_load_page(&view, 100).unwrap();
            assert_eq!(next_ready(&events), (page, false));
            let read = core.list_load_result(page).unwrap().unwrap();
            assert_eq!((read.offset, read.counted), (100, false));
            assert_eq!(read.messages, view.rows(&core, 100, crate::LIST_PAGE).unwrap());
            let past = core.list_load_page(&view, 10_000).unwrap();
            assert_eq!(next_ready(&events), (past, false));
            assert!(core.list_load_result(past).unwrap().unwrap().messages.is_empty());

            // what a load read is the view's: not stale, and a click selects from its page
            let view_now = view.clone();
            assert!(view_now.stale(&core).unwrap(), "a copy keeps nothing");
            loaded(&core, &events, &view, Reselect::default());
            assert!(!view.stale(&core).unwrap(), "grouped {grouped}");
        }
    }

    /// Pages read from a row of a page next to them, or from the end of the list, are those read from the top
    #[test]
    fn pages_read_from_their_neighbours_are_those_from_the_top() {
        let dir = pe_testkit::TempDir::new("core-list-load-anchored");
        let (core, inbox, events) = opened(&dir, 900);
        for grouped in [false, true] {
            let mut view = inbox_view(inbox);
            view.set_grouped(grouped);
            let rows = loaded(&core, &events, &view, Reselect::default()).rows;
            // the end first (nearer to it than to the top), then up from it, then down from the first page
            for offset in [rows - 60, rows - 160, 100, 150, rows - 5] {
                let page = core.list_load_page(&view, offset).unwrap();
                assert_eq!(next_ready(&events), (page, false));
                let read = core.list_load_result(page).unwrap().unwrap();
                let from_top = view.clone().rows(&core, offset, crate::LIST_PAGE).unwrap();
                assert_eq!(read.messages, from_top, "grouped {grouped}, offset {offset}");
                assert!(!from_top.is_empty());
            }
        }
    }

    #[test]
    fn a_view_listing_nothing_loads_nothing() {
        let dir = pe_testkit::TempDir::new("core-list-load-none");
        let (core, inbox, events) = opened(&dir, 3);
        let at = MessageRef { folder: inbox, uid: 1 };
        let load = loaded(&core, &events, &ListView::new(), listed(&[at]));
        assert_eq!((load.total, load.rows, load.messages.len()), (0, 0, 0));
        assert_eq!(load.reselected.how, Reselection::None);
    }

    /// The message shown is found where it is now: in the page read, nearest the row it had, or further down the list
    #[test]
    fn the_message_shown_is_found_near_its_row() {
        let dir = pe_testkit::TempDir::new("core-list-load-shown");
        let (core, inbox, events) = opened(&dir, 250);
        let at = |uid| MessageRef { folder: inbox, uid };
        let view = inbox_view(inbox);
        // newest first: 240 on row 10, in the first page; 3 on row 247, past it
        for (uid, row) in [(240, 10), (3, 247)] {
            let load = loaded(&core, &events, &view, listed(&[at(uid)]));
            assert_eq!(
                load.reselected,
                Reselected {
                    how: Reselection::Kept,
                    rows: vec![row],
                    focus: Some(row),
                    selection: Selected::Listed(vec![at(uid)]),
                }
            );
        }
        let gone = loaded(&core, &events, &view, listed(&[at(9999)]));
        assert_eq!(
            gone.reselected,
            Reselected::default(),
            "not in the list: nothing selected"
        );

        // grouped with every conversation open, the newest of one is on its conversation's row and on its own
        let mut view = inbox_view(inbox);
        view.set_grouped(true);
        view.expand_all(&core).unwrap();
        let first = loaded(&core, &events, &view, Reselect::default());
        let rows: Vec<u64> = (0..)
            .zip(&first.messages)
            .filter(|(_, m)| (m.folder_id, m.info.uid) == (inbox, 249))
            .map(|(row, _)| row)
            .collect();
        assert!(!rows.is_empty());
        for &row in &rows {
            let near = Reselect {
                hint: Some(row),
                ..listed(&[at(249)])
            };
            let load = loaded(&core, &events, &view, near);
            assert_eq!((load.reselected.rows, load.reselected.focus), (vec![row], Some(row)));
        }
    }

    /// Several messages stay selected where they are now, those gone left out, the scrolling as it is
    #[test]
    fn several_messages_stay_selected() {
        let dir = pe_testkit::TempDir::new("core-list-load-several");
        let (core, inbox, events) = opened(&dir, 250);
        let at = |uid| MessageRef { folder: inbox, uid };
        let view = inbox_view(inbox);
        let refs = [at(249), at(5), at(9999), at(200)];
        let load = loaded(&core, &events, &view, listed(&refs));
        assert_eq!(
            load.reselected,
            Reselected {
                how: Reselection::Kept,
                rows: vec![1, 50, 245],
                focus: None,
                selection: Selected::Listed(refs.to_vec()),
            }
        );
    }

    /// Select All stays the whole list while no mail comes, counted again; once mail came it is the messages it had,
    /// found where they are, the new one not selected
    #[test]
    fn select_all_is_kept_until_mail_comes() {
        let dir = pe_testkit::TempDir::new("core-list-load-all");
        let (core, inbox, events) = opened(&dir, 30);
        let view = inbox_view(inbox);
        let all = view.select_all(&core).unwrap();
        let again = Reselect {
            selected: all.clone(),
            ..Reselect::default()
        };
        core.store().remove_messages(inbox, &[1]).unwrap();
        let load = loaded(&core, &events, &view, again.clone());
        assert_eq!(load.reselected.how, Reselection::All);
        assert!(load.reselected.rows.is_empty() && load.reselected.focus.is_none());
        assert_eq!(load.reselected.selection.count(), 29, "counted again");
        assert!(matches!(load.reselected.selection, Selected::All { .. }));

        let new = pe_store::MessageInfo {
            uid: 100,
            date: Some(10_000),
            subject: "new".into(),
            ..Default::default()
        };
        core.store().add_messages(inbox, &[new]).unwrap();
        let load = loaded(&core, &events, &view, again);
        assert_eq!(load.reselected.how, Reselection::Kept);
        assert_eq!(
            load.reselected.rows,
            (1..30).collect::<Vec<u64>>(),
            "the new one on row 0 not"
        );
        assert_eq!(load.reselected.selection.count(), 29);
        assert!(matches!(load.reselected.selection, Selected::Listed(_)));
    }

    /// The row after a removal is selected in place of the selection, the last row when the list is shorter
    #[test]
    fn the_row_after_a_removal() {
        let dir = pe_testkit::TempDir::new("core-list-load-after");
        let (core, inbox, events) = opened(&dir, 30);
        let view = inbox_view(inbox);
        for (after, row, uid) in [(5, 5, 25), (100, 29, 1)] {
            let reselect = Reselect {
                after: Some(after),
                ..listed(&[MessageRef { folder: inbox, uid: 2 }])
            };
            let load = loaded(&core, &events, &view, reselect);
            assert_eq!(
                load.reselected,
                Reselected {
                    how: Reselection::After,
                    rows: vec![row],
                    focus: Some(row),
                    selection: Selected::Listed(vec![MessageRef { folder: inbox, uid }]),
                }
            );
        }
        let empty = inbox_view(-1);
        let request = core
            .list_load(
                &empty,
                Reselect {
                    after: Some(3),
                    ..Reselect::default()
                },
            )
            .unwrap();
        next_ready(&events);
        assert!(core.list_load_result(request).unwrap().is_err());
    }

    /// What the store took back of a refused action is selected in place of the selection once the list has it, and
    /// forgotten then; asked for while there is none, the selection stays
    #[test]
    fn restored_rows_are_selected() {
        let dir = pe_testkit::TempDir::new("core-list-load-restored");
        let (core, inbox, events) = opened(&dir, 30);
        let at = |uid| MessageRef { folder: inbox, uid };
        let view = inbox_view(inbox);
        let restored = Reselect {
            restored: true,
            ..listed(&[at(30)])
        };
        let load = loaded(&core, &events, &view, restored.clone());
        assert_eq!(load.reselected.how, Reselection::Kept, "none back: the selection stays");

        // what came back in another folder too: not in this list, so not in the selection either, where Delete would
        // reach it unseen
        let elsewhere = inbox + 1000;
        *core.restored.lock().unwrap() = vec![
            crate::selection::Back::There(inbox, vec![10, 12]),
            crate::selection::Back::There(elsewhere, vec![5]),
        ];
        let load = loaded(&core, &events, &view, restored.clone());
        assert_eq!(
            load.reselected,
            Reselected {
                how: Reselection::Restored,
                rows: vec![18, 20],
                focus: Some(18),
                selection: Selected::Listed(vec![at(10), at(12)]),
            }
        );
        assert!(core.restored.lock().unwrap().is_empty(), "taken");
        let load = loaded(&core, &events, &view, restored);
        assert_eq!(load.reselected.how, Reselection::Kept);
    }

    /// The store changing after the list was counted and before the rows of what came back were found: the list is
    /// read again, so they are the rows of the list drawn
    #[test]
    fn restored_rows_behind_the_list_read_again() {
        let dir = pe_testkit::TempDir::new("core-list-load-behind");
        let (core, inbox, _events) = opened(&dir, 30);
        let view = inbox_view(inbox);
        *core.restored.lock().unwrap() = vec![crate::selection::Back::There(inbox, vec![10])];
        let path = dir.path().join("store.db");
        let writes = std::cell::Cell::new(0);
        // a message comes from another connection while the first read of the list is under way
        let dropped = || {
            if writes.get() == 0 {
                let new = pe_store::MessageInfo {
                    uid: 100,
                    date: Some(10_000),
                    subject: "new".into(),
                    ..Default::default()
                };
                pe_store::Store::open(&path)
                    .unwrap()
                    .add_messages(inbox, &[new])
                    .unwrap();
            }
            writes.set(writes.get() + 1);
            false
        };
        let reselect = Reselect {
            restored: true,
            ..Reselect::default()
        };
        let at = ListView::moment_now(&core).unwrap();
        let load = view
            .load(&core, at, 0, true, Some(&reselect), &dropped)
            .unwrap()
            .unwrap();
        assert_eq!(load.total, 31, "read again");
        assert_eq!(load.reselected.how, Reselection::Restored);
        assert_eq!(
            load.reselected.rows,
            vec![21],
            "the row in the list drawn, the new one above it"
        );
    }

    /// A list that can not be read answers with why, and nothing to select: the window keeps the list it shows
    #[test]
    fn a_failed_load_says_why() {
        let dir = pe_testkit::TempDir::new("core-list-load-failed");
        let (core, inbox, events) = opened(&dir, 3);
        let view = inbox_view(inbox + 100);
        let request = core
            .list_load(&view, listed(&[MessageRef { folder: inbox, uid: 1 }]))
            .unwrap();
        assert_eq!(next_ready(&events), (request, true));
        let failed = core.list_load_result(request).unwrap();
        assert!(failed.is_err_and(|why| !why.is_empty()));
        assert!(core.list_load_result(request).is_none(), "taken once");
    }

    /// A load asked for while one runs takes its place: the older one is dropped, its event never comes, and the
    /// pages asked for before the newer load go with it
    #[test]
    fn the_newest_load_of_a_view_wins() {
        let dir = pe_testkit::TempDir::new("core-list-load-newest");
        let (core, inbox, events) = opened(&dir, 30);
        let view = inbox_view(inbox);
        let other = view.clone();
        // the loads wait while the test holds their connection
        let held = crate::connections::open(&core.connections.lists, &dir.path().join("store.db")).unwrap();
        let first = core.list_load(&view, Reselect::default()).unwrap();
        let page = core.list_load_page(&view, 100).unwrap();
        let elsewhere = core.list_load(&other, Reselect::default()).unwrap();
        let second = core.list_load(&view, Reselect::default()).unwrap();
        drop(held);
        let mut seen = vec![next_ready(&events), next_ready(&events)];
        seen.sort();
        let mut wanted = vec![(elsewhere, true), (second, true)];
        wanted.sort();
        assert_eq!(seen, wanted, "another view's load is not dropped");
        assert!(
            events.recv_timeout(Duration::from_millis(300)).is_err(),
            "nothing of the older ones"
        );
        assert!(core.list_load_result(first).is_none());
        assert!(core.list_load_result(page).is_none());
        assert_eq!(core.list_load_result(second).unwrap().unwrap().total, 30);
    }

    /// A sync writing meanwhile neither blocks a load nor makes it fail: it reads what was there before the write
    #[test]
    fn a_load_reads_while_a_sync_writes() {
        let dir = pe_testkit::TempDir::new("core-list-load-writing");
        let (core, inbox, events) = opened(&dir, 120);
        let view = inbox_view(inbox);
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
        let request = core.list_load(&view, Reselect::default()).unwrap();
        assert!(asked.elapsed() < Duration::from_millis(100), "the call returns at once");
        next_ready(&events);
        assert!(
            asked.elapsed() < Duration::from_millis(1000),
            "not waiting for the write"
        );
        let load = core.list_load_result(request).unwrap().unwrap();
        assert_eq!((load.total, load.unread), (120, 40), "as before the write");
        writer.join().unwrap();
        assert!(
            view.stale(&core).unwrap(),
            "the write after the load was asked for makes it stale"
        );
        assert_eq!(loaded(&core, &events, &view, Reselect::default()).unread, 43);
    }
}
