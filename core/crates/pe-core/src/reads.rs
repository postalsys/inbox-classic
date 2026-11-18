//! What a window opens from a message without waiting for it: a reply, a reply to all or a forward, a saved draft to go
//! on writing, an attachment's content or its file to open. Each reads the message's source, and may parse and
//! decrypt it, on a store connection of the core's own (connections.rs) off the window thread; an event says it is
//! done, and the result is taken once. The calls that do the same on the calling thread stay, for tests and tools.

use std::sync::Arc;
use std::sync::atomic::Ordering;

use pe_store::FolderId;

use crate::connections::Connection;
use crate::opening::Opened;
use crate::requests::Requests;
use crate::{Core, Draft, DraftKind, Event, Result};

/// The reads under way and done, by what they read
#[derive(Default)]
pub(crate) struct Reads {
    /// Drafts to open in a compose window; None when the message is not in the store
    drafts: Requests<Option<Draft>>,
    /// Attachments' names, types and contents; None when the message or the attachment is not here
    attachments: Requests<Option<(String, String, Vec<u8>)>>,
    /// Attachments written where they can be opened, or why not
    opened: Requests<std::result::Result<Option<Opened>, String>>,
    /// Selected messages in numbers
    summaries: Requests<Option<crate::Summary>>,
}

impl Core {
    /// Runs `read` on the reads' connection off the window thread, its result kept in what `kind` picks (None when
    /// the core closes first): [`Event::ReadDone`] follows with the request this returns
    fn start_read<T: Send + 'static>(
        self: &Arc<Self>,
        kind: fn(&Reads) -> &Requests<Option<T>>,
        read: impl FnOnce(&Core) -> Option<T> + Send + 'static,
    ) -> Result<u64> {
        let request = self.next_request.fetch_add(1, Ordering::Relaxed);
        let work = self.in_background(Connection::Reads, read);
        let work = async move { work.await.flatten() };
        kind(&self.reads).start(self.runtime()?, request, work, self.events.clone(), |request| {
            Event::ReadDone { request }
        });
        Ok(request)
    }

    /// [`Core::draft`] off the window thread: [`Event::ReadDone`] follows, then [`Core::draft_result`]
    pub fn draft_start(self: &Arc<Self>, folder: FolderId, uid: u64, kind: DraftKind) -> Result<u64> {
        self.start_read(
            |reads| &reads.drafts,
            move |core| core.draft(folder, uid, kind).ok().flatten(),
        )
    }

    /// [`Core::reopen_draft`] off the window thread: [`Event::ReadDone`] follows, then [`Core::draft_result`]
    pub fn reopen_draft_start(self: &Arc<Self>, folder: FolderId, uid: u64) -> Result<u64> {
        self.start_read(
            |reads| &reads.drafts,
            move |core| core.reopen_draft(folder, uid).ok().flatten(),
        )
    }

    /// [`Core::attachment_with_type`] off the window thread: [`Event::ReadDone`] follows, then
    /// [`Core::attachment_result`]
    pub fn attachment_start(self: &Arc<Self>, folder: FolderId, uid: u64, index: usize) -> Result<u64> {
        self.start_read(
            |reads| &reads.attachments,
            move |core| core.attachment_with_type(folder, uid, index).ok().flatten(),
        )
    }

    /// [`Core::open_attachment`] off the window thread: [`Event::ReadDone`] follows, then
    /// [`Core::open_attachment_result`]
    pub fn open_attachment_start(self: &Arc<Self>, folder: FolderId, uid: u64, index: usize) -> Result<u64> {
        let request = self.next_request.fetch_add(1, Ordering::Relaxed);
        let work = self.in_background(Connection::Reads, move |core| {
            core.open_attachment(folder, uid, index)
                .map_err(|error| error.to_string())
        });
        let work = async move { work.await.unwrap_or_else(|| Err(crate::Error::Closed.to_string())) };
        self.reads
            .opened
            .start(self.runtime()?, request, work, self.events.clone(), |request| {
                Event::ReadDone { request }
            });
        Ok(request)
    }

    /// [`Core::summary_of`] off the window thread, for a selection of a whole list (Select All), which counts every
    /// message of the list: [`Event::ReadDone`] follows, then [`Core::summary_result`]
    pub fn summary_start(self: &Arc<Self>, selected: crate::Selected) -> Result<u64> {
        self.start_read(|reads| &reads.summaries, move |core| core.summary_of(&selected).ok())
    }

    /// The numbers a [`Core::summary_start`] counted, once
    pub fn summary_result(&self, request: u64) -> Option<crate::Summary> {
        self.reads.summaries.take(request).flatten()
    }

    /// The draft a [`Core::draft_start`] or [`Core::reopen_draft_start`] made, once: None while it is made, for
    /// another request, or when the message was not in the store
    pub fn draft_result(&self, request: u64) -> Option<Draft> {
        self.reads.drafts.take(request).flatten()
    }

    /// The attachment an [`Core::attachment_start`] read, once: its name to save it under, its type, its content
    pub fn attachment_result(&self, request: u64) -> Option<(String, String, Vec<u8>)> {
        self.reads.attachments.take(request).flatten()
    }

    /// The file an [`Core::open_attachment_start`] wrote, once, as [`Core::open_attachment`] gives it; Ok(None) also
    /// while it runs or for another request
    pub fn open_attachment_result(&self, request: u64) -> Result<Option<Opened>> {
        match self.reads.opened.take(request) {
            Some(opened) => opened.map_err(crate::Error::Unavailable),
            None => Ok(None),
        }
    }

    /// Drops a read nobody waits for any more (its window closed)
    pub fn read_cancel(&self, request: u64) {
        self.reads.drafts.cancel(request);
        self.reads.attachments.cancel(request);
        self.reads.opened.cancel(request);
        self.reads.summaries.cancel(request);
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::list_load::tests::opened;
    use std::sync::mpsc::Receiver;
    use std::time::{Duration, Instant};

    const SOURCE: &[u8] = b"From: Ann <ann@example.com>\r\nTo: a@example.com\r\nSubject: Plans\r\n\
Message-ID: <plans@example.com>\r\nDate: Mon, 16 Nov 2026 10:00:00 +0000\r\nMIME-Version: 1.0\r\n\
Content-Type: multipart/mixed; boundary=b\r\n\r\n--b\r\nContent-Type: text/plain\r\n\r\nSee the notes.\r\n\
--b\r\nContent-Type: text/plain; name=notes.txt\r\nContent-Disposition: attachment; filename=notes.txt\r\n\r\n\
the notes\r\n--b--\r\n";

    /// The next `ReadDone` or `ViewReady`, waiting a while for it
    fn done(events: &Receiver<Event>) -> u64 {
        let until = Instant::now() + Duration::from_secs(20);
        loop {
            match events.recv_timeout(until.saturating_duration_since(Instant::now())) {
                Ok(Event::ReadDone { request } | Event::ViewReady { request }) => return request,
                Ok(_) => {}
                Err(error) => panic!("no event: {error}"),
            }
        }
    }

    #[test]
    fn opened_off_the_window_thread_as_on_it() {
        let dir = pe_testkit::TempDir::new("core-reads");
        let (core, inbox, events) = opened(&dir, 2);
        core.store().set_source(inbox, 1, SOURCE).unwrap();

        // the calls return at once whatever the reads' connection is doing
        let held = crate::connections::open(&core.connections.reads, &dir.path().join("store.db")).unwrap();
        let asked = Instant::now();
        let view = core.message_view_start(inbox, 1, false).unwrap();
        let reply = core.draft_start(inbox, 1, DraftKind::ReplyAll).unwrap();
        let reopened = core.reopen_draft_start(inbox, 1).unwrap();
        let data = core.attachment_start(inbox, 1, 0).unwrap();
        let file = core.open_attachment_start(inbox, 1, 0).unwrap();
        let missing = core.draft_start(inbox, 2, DraftKind::Forward).unwrap();
        let mut list = crate::ListView::new();
        list.set_scope(Some(crate::Scope::Folder(inbox)));
        let all = crate::Selected::All {
            search: list.search().unwrap(),
            sort: list.sort(),
            count: 2,
        };
        let counted = core.summary_start(all.clone()).unwrap();
        assert!(asked.elapsed() < Duration::from_millis(100));
        std::thread::sleep(Duration::from_millis(100));
        assert!(events.try_recv().is_err(), "nothing read while the connection is held");
        drop(held);
        let mut seen: Vec<u64> = (0..7).map(|_| done(&events)).collect();
        seen.sort();
        assert_eq!(seen, [view, reply, reopened, data, file, missing, counted]);
        assert_eq!(core.summary_result(counted), Some(core.summary_of(&all).unwrap()));

        let built = core.message_view_result(view).unwrap();
        let here = core.message_view(inbox, 1, false).unwrap().unwrap();
        assert_eq!((&built.subject, &built.attachments), (&here.subject, &here.attachments));
        assert!(built.document.contains("See the notes."));
        assert_eq!(
            core.draft_result(reply),
            core.draft(inbox, 1, DraftKind::ReplyAll).unwrap()
        );
        let again = core.reopen_draft(inbox, 1).unwrap().unwrap();
        let draft = core.draft_result(reopened).unwrap();
        assert_eq!((draft.subject, draft.body), (again.subject, again.body));
        assert_eq!(
            core.attachment_result(data),
            core.attachment_with_type(inbox, 1, 0).unwrap()
        );
        assert_eq!(core.attachment_result(data), None, "taken once");
        let written = core.open_attachment_result(file).unwrap().unwrap();
        assert_eq!(std::fs::read(&written.path).unwrap(), b"the notes");
        assert_eq!(core.draft_result(missing), None, "no source");
    }

    /// The reading pane and a message window asking for one message at once (turning dark messages on reloads both)
    /// each get their view; only a reader's own cancel drops its view
    #[test]
    fn two_readers_of_one_message_each_get_a_view() {
        let dir = pe_testkit::TempDir::new("core-two-readers");
        let (core, inbox, events) = opened(&dir, 1);
        core.store().set_source(inbox, 1, SOURCE).unwrap();
        // held, so all three are asked for before any is built
        let held = crate::connections::open(&core.connections.reads, &dir.path().join("store.db")).unwrap();
        let pane = core.message_view_start(inbox, 1, false).unwrap();
        let window = core.message_view_start(inbox, 1, false).unwrap();
        let cancelled = core.message_view_start(inbox, 1, false).unwrap();
        core.message_view_cancel(cancelled);
        drop(held);
        let mut seen = [done(&events), done(&events)];
        seen.sort();
        assert_eq!(seen, [pane, window]);
        for request in [pane, window] {
            let view = core.message_view_result(request).expect("each reader's view");
            assert!(view.document.contains("See the notes."));
        }
        assert!(core.message_view_result(cancelled).is_none());
    }
}
