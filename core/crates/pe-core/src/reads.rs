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

/// What a read in the background gave
pub(crate) enum Read {
    /// A draft to open in a compose window; None when the message is not in the store
    Draft(Option<Box<Draft>>),
    /// An attachment's name, type and content; None when the message or the attachment is not here
    Attachment(Option<(String, String, Vec<u8>)>),
    /// An attachment written where it can be opened, or why not
    Opened(std::result::Result<Option<Opened>, String>),
    /// Selected messages in numbers
    Summary(Option<crate::Summary>),
}

/// The reads under way and done
pub(crate) type Reads = Requests<Option<Read>>;

impl Core {
    /// Runs `read` on the reads' connection off the window thread: [`Event::ReadDone`] follows with the request this
    /// returns
    fn start_read(self: &Arc<Self>, read: impl FnOnce(&Core) -> Read + Send + 'static) -> Result<u64> {
        let request = self.next_request.fetch_add(1, Ordering::Relaxed);
        let work = self.in_background(Connection::Reads, read);
        self.reads
            .start(self.runtime()?, request, work, self.events.clone(), |request| {
                Event::ReadDone { request }
            });
        Ok(request)
    }

    /// [`Core::draft`] off the window thread: [`Event::ReadDone`] follows, then [`Core::draft_result`]
    pub fn draft_start(self: &Arc<Self>, folder: FolderId, uid: u64, kind: DraftKind) -> Result<u64> {
        self.start_read(move |core| Read::Draft(core.draft(folder, uid, kind).ok().flatten().map(Box::new)))
    }

    /// [`Core::reopen_draft`] off the window thread: [`Event::ReadDone`] follows, then [`Core::draft_result`]
    pub fn reopen_draft_start(self: &Arc<Self>, folder: FolderId, uid: u64) -> Result<u64> {
        self.start_read(move |core| Read::Draft(core.reopen_draft(folder, uid).ok().flatten().map(Box::new)))
    }

    /// [`Core::attachment_with_type`] off the window thread: [`Event::ReadDone`] follows, then
    /// [`Core::attachment_result`]
    pub fn attachment_start(self: &Arc<Self>, folder: FolderId, uid: u64, index: usize) -> Result<u64> {
        self.start_read(move |core| Read::Attachment(core.attachment_with_type(folder, uid, index).ok().flatten()))
    }

    /// [`Core::open_attachment`] off the window thread: [`Event::ReadDone`] follows, then
    /// [`Core::open_attachment_result`]
    pub fn open_attachment_start(self: &Arc<Self>, folder: FolderId, uid: u64, index: usize) -> Result<u64> {
        self.start_read(move |core| {
            Read::Opened(
                core.open_attachment(folder, uid, index)
                    .map_err(|error| error.to_string()),
            )
        })
    }

    /// [`Core::summary_of`] off the window thread, for a selection of a whole list (Select All), which counts every
    /// message of the list: [`Event::ReadDone`] follows, then [`Core::summary_result`]
    pub fn summary_start(self: &Arc<Self>, selected: crate::Selected) -> Result<u64> {
        self.start_read(move |core| Read::Summary(core.summary_of(&selected).ok()))
    }

    /// The numbers a [`Core::summary_start`] counted, once
    pub fn summary_result(&self, request: u64) -> Option<crate::Summary> {
        match self.reads.take(request).flatten()? {
            Read::Summary(summary) => summary,
            _ => None,
        }
    }

    /// The draft a [`Core::draft_start`] or [`Core::reopen_draft_start`] made, once: None while it is made, for
    /// another request, or when the message was not in the store
    pub fn draft_result(&self, request: u64) -> Option<Draft> {
        match self.reads.take(request).flatten()? {
            Read::Draft(draft) => draft.map(|draft| *draft),
            _ => None,
        }
    }

    /// The attachment an [`Core::attachment_start`] read, once: its name to save it under, its type, its content
    pub fn attachment_result(&self, request: u64) -> Option<(String, String, Vec<u8>)> {
        match self.reads.take(request).flatten()? {
            Read::Attachment(found) => found,
            _ => None,
        }
    }

    /// The file an [`Core::open_attachment_start`] wrote, once, as [`Core::open_attachment`] gives it; Ok(None) also
    /// while it runs or for another request
    pub fn open_attachment_result(&self, request: u64) -> Result<Option<Opened>> {
        match self.reads.take(request).flatten() {
            Some(Read::Opened(opened)) => opened.map_err(crate::Error::Unavailable),
            _ => Ok(None),
        }
    }

    /// Drops a read nobody waits for any more (its window closed)
    pub fn read_cancel(&self, request: u64) {
        self.reads.cancel(request);
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
}
