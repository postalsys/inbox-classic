//! The engine against ImapKit (core/e2e), the way the windows drive it: add an account, sync,
//! read the folder tree and the message list, open a message, mark it read.
//!
//! Skipped without Node.js and `npm ci` in core/e2e, unless PE_E2E_REQUIRED is set.

use std::sync::mpsc::{Receiver, channel};
use std::time::Duration;

use pe_core::timing::{Link, Served};
use pe_core::{Action, Core, Event, FailureKind, MessageRef, Scope, Search};
use pe_store::{AccountSettings, Sort, SortField};
use pe_testkit::{ImapKit, PASSWORD, TempDir, USER, rfc822};
use serde_json::json;

struct Setup {
    server: ImapKit,
    core: Core,
    events: Receiver<Event>,
    _dir: TempDir,
}

fn setup() -> Option<Setup> {
    setup_with(json!({}))
}

/// [`setup`] with ImapKit started with `config` (its mailboxes, its plugins)
fn setup_with(config: serde_json::Value) -> Option<Setup> {
    let server = ImapKit::start(config)?;
    let dir = TempDir::new("core");
    let (sender, events) = channel();
    let trust = pe_net::Trust::Pinned(vec![server.cert.clone()]);
    let options = pe_core::Options {
        trust,
        passwords: pe_core::PasswordStore::Memory,
        ..Default::default()
    };
    let core = Core::open_with(dir.path().join("store.db"), options, move |event| {
        let _ = sender.send(event);
    })
    .unwrap();
    // the tests of opening see the message downloaded when it is opened; those of downloading ahead turn it on
    core.set_download_ahead(pe_store::Ahead::Never).unwrap();
    // a message sent goes at once, but in the tests of Undo Send
    core.set_send_delay(0).unwrap();
    Some(Setup {
        server,
        core,
        events,
        _dir: dir,
    })
}

fn settings(server: &ImapKit) -> AccountSettings {
    let mut settings = server.account_settings();
    // ImapKit's SMTP server takes AUTH after STARTTLS only
    settings.smtp_security = pe_store::Security::StartTls;
    settings
}

impl Setup {
    /// Waits for an event `accept` takes, failing on a Failed event it does not take
    fn wait(&self, accept: impl Fn(&Event) -> bool) -> Event {
        loop {
            let event = self
                .events
                .recv_timeout(Duration::from_secs(10))
                .expect("an event within 10 seconds");
            if accept(&event) {
                return event;
            }
            assert!(!matches!(event, Event::Failed { .. }), "{event:?}");
        }
    }
}

#[test]
fn reads_mail_like_the_windows_do() {
    let Some(s) = setup() else { return };
    s.server.add_message("INBOX", &rfc822("First", "Hello there"), &[]);
    let html = "From: Sender <sender@example.com>\r\nSubject: Styled\r\nContent-Type: text/html\r\n\r\n<p>Hi<script>x()</script></p>\r\n";
    let styled = s.server.add_message("INBOX", html, &[]);

    let account = s.core.add_account(&settings(&s.server), PASSWORD).unwrap();
    assert_eq!(s.core.accounts().unwrap()[0].id, account);
    s.core.sync(account).unwrap();
    s.wait(|e| *e == Event::FoldersChanged { account });
    s.wait(|e| *e == Event::SyncFinished { account, failure: None });

    let folders = s.core.folders(account).unwrap();
    let inbox = folders.iter().find(|f| f.info.path == "INBOX").unwrap();
    assert_eq!((inbox.total, inbox.unread), (2, 2));
    let list = s.core.messages(inbox.id, Sort::default(), 0, 50).unwrap();
    let subjects: Vec<&str> = list.iter().map(|m| m.info.subject.as_str()).collect();
    assert_eq!(subjects.len(), 2);
    assert!(subjects.contains(&"Styled"));

    // not cached yet: opened in the background
    assert_eq!(s.core.message_view(inbox.id, styled, false).unwrap(), None);
    s.core.open_message(inbox.id, styled).unwrap();
    s.wait(|e| {
        *e == Event::MessageReady {
            folder: inbox.id,
            uid: styled,
        }
    });
    let view = s.core.message_view(inbox.id, styled, false).unwrap().unwrap();
    assert_eq!(view.subject, "Styled");
    assert!(view.date.is_some(), "no Date header: the received date");

    // timed: the first open over a new connection, the second from the store
    s.core.open_message(inbox.id, styled).unwrap();
    s.wait(|e| {
        *e == Event::MessageReady {
            folder: inbox.id,
            uid: styled,
        }
    });
    let timings = s.core.open_timings();
    assert_eq!(timings.len(), 2, "{timings:?}");
    let (first, second) = (&timings[0], &timings[1]);
    // the reader connects after the first sync: by now, or for this open
    assert_eq!(first.served, Served::Reader);
    assert!(matches!(first.link, Link::New | Link::Reused), "{first:?}");
    assert_eq!(first.size, html.len() as u64);
    assert_eq!(first.host, "127.0.0.1");
    assert!(first.connected <= first.selected && first.selected <= first.first_byte);
    assert!(first.first_byte <= first.last_byte && first.last_byte <= first.ready);
    assert!(!first.failed);
    assert_eq!((second.served, second.link), (Served::Store, Link::None));
    assert!(second.ready.is_some() && second.connected.is_none());
    let index = s.core.message_index(inbox.id, Sort::default(), styled).unwrap();
    assert_eq!(list[index.unwrap() as usize].info.uid, styled);
    assert_eq!(view.from, "Sender <sender@example.com>");
    assert!(view.document.contains("<p>Hi</p>") && !view.document.contains("script"));

    // read: in the store right away, on the server when the worker got to it
    s.core.set_seen(inbox.id, styled, true).unwrap();
    s.wait(|e| {
        *e == Event::FolderChanged {
            account,
            folder: inbox.id,
        }
    });
    assert_eq!(
        s.core
            .folders(account)
            .unwrap()
            .iter()
            .find(|f| f.id == inbox.id)
            .unwrap()
            .unread,
        1
    );
    s.core.sync(account).unwrap();
    s.wait(|e| *e == Event::SyncFinished { account, failure: None });
    let on_server = s.server.messages("INBOX");
    let flags = on_server.iter().find(|m| m["uid"] == json!(styled)).unwrap()["flags"].clone();
    assert_eq!(flags, json!(["\\Seen"]));

    // new mail arrives with the next sync
    s.server.add_message("INBOX", &rfc822("Third", "x"), &[]);
    s.core.sync(account).unwrap();
    s.wait(|e| {
        *e == Event::FolderChanged {
            account,
            folder: inbox.id,
        }
    });
    assert_eq!(s.core.messages(inbox.id, Sort::default(), 0, 50).unwrap().len(), 3);

    // Mark All Read: every message of the folder, in the store at once and on the server with one STORE
    s.core.mark_all_read(inbox.id).unwrap();
    let unread = |s: &Setup| {
        s.core
            .folders(account)
            .unwrap()
            .iter()
            .find(|f| f.id == inbox.id)
            .unwrap()
            .unread
    };
    assert_eq!(unread(&s), 0);
    // on the server once the worker got to it (a SyncFinished of the sync before may still be on its way)
    let all_seen = |s: &Setup| {
        let on_server = s.server.messages("INBOX");
        on_server.len() == 3
            && on_server
                .iter()
                .all(|m| m["flags"].as_array().unwrap().contains(&json!("\\Seen")))
    };
    for _ in 0..200 {
        if all_seen(&s) {
            break;
        }
        std::thread::sleep(Duration::from_millis(25));
    }
    assert!(all_seen(&s), "{:?}", s.server.messages("INBOX"));
    s.core.sync(account).unwrap();
    s.wait(|e| *e == Event::SyncFinished { account, failure: None });
    assert_eq!(unread(&s), 0, "the sync keeps them read");
}

#[test]
fn opens_on_the_newest_message_of_the_first_inbox() {
    let Some(s) = setup() else { return };
    assert_eq!(s.core.start_message().unwrap(), None, "no account");
    let dated = |subject: &str, date: &str| {
        format!("From: Sender <sender@example.com>\r\nSubject: {subject}\r\nDate: {date}\r\n\r\nHi\r\n")
    };
    let newest = s
        .server
        .add_message("INBOX", &dated("Newest", "Tue, 7 Oct 2025 10:00:00 +0000"), &[]);
    // a higher UID, an older date: the date decides
    s.server
        .add_message("INBOX", &dated("Older", "Mon, 6 Oct 2025 10:00:00 +0000"), &[]);

    let account = s.core.add_account(&settings(&s.server), PASSWORD).unwrap();
    s.core.sync(account).unwrap();
    s.wait(|e| *e == Event::SyncFinished { account, failure: None });
    let inbox = s
        .core
        .folders(account)
        .unwrap()
        .into_iter()
        .find(|f| f.info.path == "INBOX")
        .unwrap();
    let start = pe_core::Start {
        all_inboxes: false,
        folder: inbox.id,
        uid: Some(newest),
    };
    assert_eq!(s.core.start_message().unwrap(), Some(start));
}

#[test]
fn sent_items_and_drafts_list_the_recipients() {
    let Some(s) = setup() else { return };
    let account = s.core.add_account(&settings(&s.server), PASSWORD).unwrap();
    s.core.sync(account).unwrap();
    s.wait(|e| *e == Event::SyncFinished { account, failure: None });
    let folders = s.core.folders(account).unwrap();
    let with_use = |special: &str| {
        folders
            .iter()
            .find(|f| f.info.special_use.as_deref() == Some(special))
            .unwrap_or_else(|| panic!("no {special} folder in {folders:?}"))
    };
    let sent = with_use("\\Sent");
    let to = |name: &str, address: &str, subject: &str| {
        format!("From: Me <me@example.com>\r\nTo: {name} <{address}>\r\nSubject: {subject}\r\n\r\nHi\r\n")
    };
    s.server
        .add_message(&sent.info.path, &to("Zoe", "zoe@example.com", "First"), &[]);
    s.server
        .add_message(&sent.info.path, &to("Adam", "adam@example.com", "Second"), &[]);
    s.core.sync(account).unwrap();
    s.wait(|e| *e == Event::SyncFinished { account, failure: None });

    let inbox = folders.iter().find(|f| f.info.path == "INBOX").unwrap();
    assert!(s.core.lists_recipients(&Search::folder(sent.id)).unwrap());
    assert!(
        s.core
            .lists_recipients(&Search::folder(with_use("\\Drafts").id))
            .unwrap()
    );
    assert!(!s.core.lists_recipients(&Search::folder(inbox.id)).unwrap());
    let searching = Search {
        text: "First".into(),
        ..Search::folder(sent.id)
    };
    assert!(
        !s.core.lists_recipients(&searching).unwrap(),
        "a search names the senders"
    );
    let all = Search {
        scope: Scope::AllInboxes,
        ..Default::default()
    };
    assert!(!s.core.lists_recipients(&all).unwrap());

    // the person column there is To: a From sort is by the recipients
    let by_recipient = Sort {
        field: SortField::From,
        ascending: true,
    };
    let listed: Vec<String> = s
        .core
        .search(&Search::folder(sent.id), by_recipient, 0, 10)
        .unwrap()
        .into_iter()
        .map(|m| m.info.recipients)
        .collect();
    assert_eq!(listed, ["Adam", "Zoe"]);
}

/// Waits up to 10 seconds for `done`
fn eventually(done: impl Fn() -> bool, what: &str) {
    for _ in 0..400 {
        if done() {
            return;
        }
        std::thread::sleep(Duration::from_millis(25));
    }
    panic!("did not get there: {what}");
}

#[test]
fn archives_into_an_archive_folder_made_for_it() {
    // no Archive folder on the server
    let Some(s) = setup_with(json!({ "storage": {
        "INBOX": {},
        "": { "separator": "/", "folders": {
            "Sent": { "special-use": "\\Sent" },
            "Trash": { "special-use": "\\Trash" }
        } }
    } })) else {
        return;
    };
    s.server.add_message("INBOX", &rfc822("Keep this", "One"), &[]);
    s.server.add_message("INBOX", &rfc822("And this", "Two"), &[]);
    let account = s.core.add_account(&settings(&s.server), PASSWORD).unwrap();
    s.core.sync(account).unwrap();
    s.wait(|e| *e == Event::SyncFinished { account, failure: None });
    let folders = s.core.folders(account).unwrap();
    let inbox = folders.iter().find(|f| f.info.path == "INBOX").unwrap().id;
    let sent = folders.iter().find(|f| f.info.path == "Sent").unwrap().id;
    assert!(s.core.can_archive(inbox).unwrap());
    assert!(!s.core.can_archive(sent).unwrap(), "Sent Items is not archived from");

    let all = s
        .core
        .refs_in_ranges(&Search::folder(inbox), Sort::default(), &[(0, 2)])
        .unwrap();
    assert_eq!(s.core.act(&all, Action::Archive).unwrap(), "Archived 2 messages");
    assert!(
        s.core.messages(inbox, Sort::default(), 0, 10).unwrap().is_empty(),
        "out of the list at once"
    );
    eventually(
        || {
            s.core
                .folders(account)
                .unwrap()
                .iter()
                .any(|f| f.info.special_use.as_deref() == Some("\\Archive"))
        },
        "the new folder is the account's Archive",
    );
    eventually(
        || s.server.subjects("Archive").len() == 2,
        "the Archive folder made, the messages in it",
    );
    assert!(s.server.subjects("INBOX").is_empty());

    assert_eq!(s.core.undo_label().as_deref(), Some("Undo Archive"));
    s.core.undo().unwrap();
    eventually(|| s.server.subjects("INBOX").len() == 2, "back in the Inbox with Undo");
    assert!(s.server.subjects("Archive").is_empty());
}

#[test]
fn steps_to_the_next_and_previous_message_of_a_list() {
    let Some(s) = setup() else { return };
    let dated = |subject: &str, date: &str| {
        format!("From: Sender <sender@example.com>\r\nSubject: {subject}\r\nDate: {date}\r\n\r\nHi\r\n")
    };
    let oldest = s
        .server
        .add_message("INBOX", &dated("Oldest", "Mon, 6 Oct 2025 10:00:00 +0000"), &[]);
    let middle = s
        .server
        .add_message("INBOX", &dated("Middle", "Tue, 7 Oct 2025 10:00:00 +0000"), &[]);
    let newest = s
        .server
        .add_message("INBOX", &dated("Newest", "Wed, 8 Oct 2025 10:00:00 +0000"), &[]);
    let account = s.core.add_account(&settings(&s.server), PASSWORD).unwrap();
    s.core.sync(account).unwrap();
    s.wait(|e| *e == Event::SyncFinished { account, failure: None });
    let inbox = s
        .core
        .folders(account)
        .unwrap()
        .iter()
        .find(|f| f.info.path == "INBOX")
        .unwrap()
        .id;
    let list = Search::folder(inbox);
    let at = |uid| MessageRef { folder: inbox, uid };
    // newest first: Next goes to older mail, as the list reads down
    let pair = |uid| s.core.neighbours(&list, Sort::default(), inbox, uid).unwrap();
    assert_eq!(pair(newest), Some((None, Some(at(middle)))), "nothing before the first");
    assert_eq!(pair(middle), Some((Some(at(newest)), Some(at(oldest)))));
    assert_eq!(pair(oldest), Some((Some(at(middle)), None)), "nothing after the last");
    assert_eq!(pair(9999), None, "a message not in the list");
    assert!(s.core.has_message(inbox, middle).unwrap() && !s.core.has_message(inbox, 9999).unwrap());
    // the list that is not all of the folder: only the unread
    let unread = Search {
        show: pe_core::Show::Unread,
        ..Search::folder(inbox)
    };
    s.core.set_seen(inbox, middle, true).unwrap();
    let pair = |uid| s.core.neighbours(&unread, Sort::default(), inbox, uid).unwrap();
    assert_eq!(
        pair(newest),
        Some((None, Some(at(oldest)))),
        "the read one is not in that list"
    );
    assert_eq!(pair(middle), None);
}

#[test]
fn next_unread_goes_on_to_the_next_folder() {
    let Some(s) = setup() else { return };
    let dated = |subject: &str, date: &str| {
        format!("From: Sender <sender@example.com>\r\nSubject: {subject}\r\nDate: {date}\r\n\r\nHi\r\n")
    };
    let read = s
        .server
        .add_message("INBOX", &dated("Read", "Wed, 8 Oct 2025 10:00:00 +0000"), &["\\Seen"]);
    let unread = s
        .server
        .add_message("INBOX", &dated("Unread", "Tue, 7 Oct 2025 10:00:00 +0000"), &[]);
    s.server
        .add_message("Archive", &dated("Filed", "Mon, 6 Oct 2025 10:00:00 +0000"), &[]);
    s.server
        .add_message("Junk", &dated("Spam", "Mon, 6 Oct 2025 10:00:00 +0000"), &[]);
    let account = s.core.add_account(&settings(&s.server), PASSWORD).unwrap();
    s.core.sync(account).unwrap();
    s.wait(|e| *e == Event::SyncFinished { account, failure: None });
    let folders = s.core.folders(account).unwrap();
    let id = |path: &str| folders.iter().find(|f| f.info.path == path).unwrap().id;
    let (inbox, archive) = (id("INBOX"), id("Archive"));
    let list = Search::folder(inbox);
    let next = |uid| s.core.next_unread(&list, Sort::default(), inbox, uid).unwrap();
    // newest first: the read one, then the unread one
    assert_eq!(
        next(read),
        Some(MessageRef {
            folder: inbox,
            uid: unread
        })
    );
    assert_eq!(
        next(0),
        Some(MessageRef {
            folder: inbox,
            uid: unread
        }),
        "from the top"
    );
    assert_eq!(next(unread), None, "none after the last unread");
    // on to the Archive, not Junk E-mail, whose unread mail does not count
    assert_eq!(s.core.next_unread_folder(inbox).unwrap(), Some(archive));
    assert_eq!(
        s.core.next_unread_question(inbox, archive).unwrap(),
        "There are no more unread messages in Inbox.\n\nGo to Archive, the next folder with unread messages?"
    );
    // around to the first: from the Archive back to the Inbox
    assert_eq!(s.core.next_unread_folder(archive).unwrap(), Some(inbox));
    // as one step: the message, then the question, then from the next folder's top
    let step = |search: &Search, uid| s.core.next_unread_step(search, Sort::default(), inbox, uid).unwrap();
    assert_eq!(
        step(&list, read),
        pe_core::NextUnread::Message(MessageRef {
            folder: inbox,
            uid: unread
        })
    );
    assert!(matches!(step(&list, unread), pe_core::NextUnread::Ask { folder, .. } if folder == archive));
    let filed = Search::folder(archive);
    assert!(matches!(
        s.core.next_unread_step(&filed, Sort::default(), archive, 0).unwrap(),
        pe_core::NextUnread::Message(MessageRef { folder, .. }) if folder == archive
    ));
}

#[test]
fn empties_deleted_items_and_junk() {
    let Some(s) = setup() else { return };
    s.server.add_message("Trash", &rfc822("Old one", "Gone"), &[]);
    s.server.add_message("Trash", &rfc822("Old two", "Gone"), &[]);
    s.server.add_message("Junk", &rfc822("Spam", "Buy"), &[]);
    s.server.add_message("INBOX", &rfc822("Keep", "Stays"), &[]);
    let account = s.core.add_account(&settings(&s.server), PASSWORD).unwrap();
    s.core.sync(account).unwrap();
    s.wait(|e| *e == Event::SyncFinished { account, failure: None });
    let folders = s.core.folders(account).unwrap();
    let id = |path: &str| folders.iter().find(|f| f.info.path == path).unwrap().id;
    let (trash, junk, inbox) = (id("Trash"), id("Junk"), id("INBOX"));

    assert!(s.core.can_empty(trash).unwrap() && s.core.can_empty(junk).unwrap());
    assert!(!s.core.can_empty(inbox).unwrap());
    assert_eq!(
        s.core.empty_folder_question(trash).unwrap().as_deref(),
        Some("Empty Deleted Items?\n\nThe 2 messages in it are deleted for good. They can not be brought back.")
    );
    assert_eq!(s.core.empty_folder_question(inbox).unwrap(), None);
    assert!(s.core.empty_folder(inbox).is_err(), "the Inbox is not emptied");

    assert_eq!(s.core.empty_folder(trash).unwrap(), "Deleted 2 messages for good");
    assert!(
        s.core.messages(trash, Sort::default(), 0, 10).unwrap().is_empty(),
        "out of the list at once"
    );
    eventually(|| s.server.subjects("Trash").is_empty(), "gone from the server");
    assert_eq!(
        s.core.empty_folder_question(trash).unwrap(),
        None,
        "nothing left to empty"
    );
    s.core.empty_folder(junk).unwrap();
    eventually(|| s.server.subjects("Junk").is_empty(), "Junk E-mail emptied too");
    assert_eq!(s.server.subjects("INBOX"), ["Keep"], "and nothing else");
}

#[test]
fn archives_on_gmail_by_taking_every_label_off() {
    let Some(s) = setup_with(json!({ "storage": {
        "INBOX": {},
        "": { "separator": "/", "folders": {
            "Work": {},
            "[Gmail]": { "folders": {
                "All Mail": { "special-use": "\\All" },
                "Sent Mail": { "special-use": "\\Sent" },
                "Trash": { "special-use": "\\Trash" }
            } }
        } }
    } })) else {
        return;
    };
    let uid = s.server.add_message("INBOX", &rfc822("Labelled", "Hi"), &[]);
    // Gmail keeps every message in All Mail too (one message there: ImapKit keeps a copy a mailbox, whose labels are
    // its own, so Undo's labels are looked for on the copy in All Mail)
    let all_mail = s.server.add_message("[Gmail]/All Mail", &rfc822("Labelled", "Hi"), &[]);
    let account = s.core.add_account(&settings(&s.server), PASSWORD).unwrap();
    s.core.sync(account).unwrap();
    s.wait(|e| *e == Event::SyncFinished { account, failure: None });
    let inbox = s
        .core
        .folders(account)
        .unwrap()
        .iter()
        .find(|f| f.info.path == "INBOX")
        .unwrap()
        .id;
    let labels = || gmail_labels(&s.server, "INBOX", uid);
    assert!(labels().contains(&"\\Inbox".to_string()), "{:?}", labels());

    let picked = [MessageRef { folder: inbox, uid }];
    assert_eq!(s.core.act(&picked, Action::Archive).unwrap(), "Archived 1 message");
    assert!(
        s.core.messages(inbox, Sort::default(), 0, 10).unwrap().is_empty(),
        "out of the list at once"
    );
    eventually(
        || !labels().contains(&"\\Inbox".to_string()),
        "the Inbox label taken off",
    );

    s.core.undo().unwrap();
    eventually(
        || gmail_labels(&s.server, "[Gmail]/All Mail", all_mail).contains(&"\\Inbox".to_string()),
        "and put back with Undo, where Gmail keeps the message",
    );

    // from a label's folder: that label goes
    let work_uid = s.server.add_message("Work", &rfc822("Filed", "For work"), &[]);
    s.core.sync(account).unwrap();
    s.wait(|e| *e == Event::SyncFinished { account, failure: None });
    let work = s
        .core
        .folders(account)
        .unwrap()
        .iter()
        .find(|f| f.info.path == "Work")
        .unwrap()
        .id;
    assert!(s.core.can_archive(work).unwrap());
    assert!(gmail_labels(&s.server, "Work", work_uid).contains(&"Work".to_string()));
    s.core
        .act(
            &[MessageRef {
                folder: work,
                uid: work_uid,
            }],
            Action::Archive,
        )
        .unwrap();
    eventually(
        || !gmail_labels(&s.server, "Work", work_uid).contains(&"Work".to_string()),
        "the Work label taken off",
    );
}

/// The Gmail labels of message `uid` of `mailbox`, over an IMAP connection of the test's own
fn gmail_labels(server: &ImapKit, mailbox: &str, uid: u64) -> Vec<String> {
    use pe_imap::client::FetchQuery;
    use pe_imap::{Client, Messages, SequenceSet};
    let runtime = tokio::runtime::Builder::new_current_thread()
        .enable_all()
        .build()
        .unwrap();
    runtime.block_on(async {
        let config = server.imap_config(pe_net::Security::Plain, pe_testkit::password());
        let (mut client, _events) = Client::connect(config).await.expect("connect");
        client.select(mailbox).await.expect("select");
        let query = FetchQuery {
            gmail_labels: true,
            ..Default::default()
        };
        let set = SequenceSet::from_numbers(&[uid]).unwrap();
        let fetched = client.fetch(&Messages::Uids(set), &query).await.expect("fetch");
        fetched.into_iter().next().and_then(|m| m.labels).unwrap_or_default()
    })
}

#[test]
fn keeps_an_address_book() {
    let Some(s) = setup() else { return };
    s.server.add_message(
        "INBOX",
        "From: Mary Smith <mary@example.com>\r\nSubject: Hello\r\nDate: Mon, 6 Oct 2025 10:00:00 +0000\r\n\r\nHi\r\n",
        &[],
    );
    s.server.add_message(
        "INBOX",
        "From: Marko Polo <marko@example.net>\r\nSubject: Travel\r\nDate: Mon, 6 Oct 2025 11:00:00 +0000\r\n\r\nHi\r\n",
        &[],
    );
    let account = s.core.add_account(&settings(&s.server), PASSWORD).unwrap();
    s.core.sync(account).unwrap();
    s.wait(|e| *e == Event::SyncFinished { account, failure: None });
    let inbox = s
        .core
        .folders(account)
        .unwrap()
        .iter()
        .find(|f| f.info.path == "INBOX")
        .unwrap()
        .id;
    let mary = s
        .core
        .search(&Search::folder(inbox), Sort::default(), 0, 10)
        .unwrap()
        .into_iter()
        .find(|m| m.info.subject == "Hello")
        .unwrap();

    // the sender added, once
    let added = s.core.add_sender(inbox, mary.info.uid).unwrap();
    let card = added.card;
    assert!(added.added);
    let again = s.core.add_sender(inbox, mary.info.uid).unwrap();
    assert_eq!((again.card, again.added), (card, false), "the same card again");
    let saved = s.core.card(card).unwrap().unwrap();
    assert_eq!((saved.first.as_str(), saved.last.as_str()), ("Mary", "Smith"));

    // a vCard and a CSV file read in, a card whose address is known left out
    let dir = TempDir::new("cards");
    let vcf = dir.path().join("cards.vcf");
    std::fs::write(
        &vcf,
        "BEGIN:VCARD\r\nVERSION:3.0\r\nFN:Team Lead\r\nEMAIL:lead@example.org\r\nEND:VCARD\r\n",
    )
    .unwrap();
    assert_eq!(
        s.core.import_cards(&[&vcf]),
        pe_core::book::Imported {
            added: 1,
            ..Default::default()
        }
    );
    let csv = dir.path().join("cards.csv");
    std::fs::write(
        &csv,
        "First Name,Last Name,E-mail Address\nMary,Smith,mary@example.com\nJohn,Doe,john@example.org\n",
    )
    .unwrap();
    assert_eq!(
        s.core.import_cards(&[&csv]),
        pe_core::book::Imported {
            added: 1,
            skipped: 1,
            ..Default::default()
        }
    );
    assert_eq!(s.core.cards("").unwrap().len(), 3);

    // written out, and read back the same
    let out = dir.path().join("out.vcf");
    assert_eq!(s.core.export_cards(&[], &out).unwrap(), 3);
    let again = pe_core::vcard::read_vcards(&std::fs::read_to_string(&out).unwrap());
    assert_eq!(again.len(), 3);

    // a group, and the completion: the book first, its groups, then people heard from, no address twice
    s.core
        .save_group(&pe_store::Group {
            name: "Marketing".into(),
            members: vec![pe_store::Member {
                card: Some(card),
                ..Default::default()
            }],
            ..Default::default()
        })
        .unwrap();
    let found = s.core.completions("mar", 10).unwrap();
    let labels: Vec<&str> = found.iter().map(|c| c.label.as_str()).collect();
    assert_eq!(
        labels,
        [
            "Mary Smith <mary@example.com>",
            "Mary Smith <mary@example.com>",
            "Marko Polo <marko@example.net>"
        ]
    );
    assert!(found[1].group && found[1].name == "Marketing");
}

#[test]
fn all_inboxes_list_and_mark_every_account() {
    let Some(s) = setup() else { return };
    // a second account on a server of its own (ImapKit has one mailbox a server)
    let Some(other_server) = ImapKit::start(json!({})) else {
        return;
    };
    let dated = |subject: &str, date: &str| {
        format!("From: Sender <sender@example.com>\r\nSubject: {subject}\r\nDate: {date}\r\n\r\nHi\r\n")
    };
    s.server
        .add_message("INBOX", &dated("First's", "Mon, 6 Oct 2025 10:00:00 +0000"), &[]);
    s.server
        .add_message("Archive", &dated("Archived", "Wed, 8 Oct 2025 10:00:00 +0000"), &[]);
    let first = s.core.add_account(&settings(&s.server), PASSWORD).unwrap();
    s.core.sync(first).unwrap();
    s.wait(|e| {
        *e == Event::SyncFinished {
            account: first,
            failure: None,
        }
    });
    let second = s.core.add_account(&settings(&other_server), PASSWORD).unwrap();
    s.core.sync(second).unwrap();
    s.wait(|e| {
        *e == Event::SyncFinished {
            account: second,
            failure: None,
        }
    });
    let inbox2 = s
        .core
        .folders(second)
        .unwrap()
        .into_iter()
        .find(|f| f.info.path == "INBOX")
        .unwrap()
        .id;
    let all = pe_core::Search {
        scope: pe_core::Scope::AllInboxes,
        ..Default::default()
    };
    let subjects = || -> Vec<String> {
        s.core
            .search(&all, Sort::default(), 0, 50)
            .unwrap()
            .into_iter()
            .map(|m| m.info.subject)
            .collect()
    };
    assert_eq!(subjects(), ["First's"], "the Archive is not an Inbox");

    // the rows under All Inboxes: each account's Inbox, in the accounts' order, named as the tree names the account
    let inbox1 = s
        .core
        .folders(first)
        .unwrap()
        .into_iter()
        .find(|f| f.info.path == "INBOX")
        .unwrap()
        .id;
    let rows = s.core.special_folders(pe_core::SpecialFolderKind::Inbox).unwrap();
    assert_eq!(
        rows.iter().map(|r| (r.account, r.folder, r.unread)).collect::<Vec<_>>(),
        [(first, inbox1, 1), (second, inbox2, 0)]
    );
    let email = settings(&s.server).email;
    let accounts = s.core.accounts().unwrap();
    assert_eq!(
        accounts[0].account_name,
        pe_core::default_account_name(&email),
        "a new account is named by its provider or domain"
    );
    s.core.set_account_name(first, "Work").unwrap();
    let rows = s.core.special_folders(pe_core::SpecialFolderKind::Inbox).unwrap();
    assert_eq!(
        (rows[0].name.as_str(), rows[0].title.as_str()),
        ("Work", "Inbox - Work")
    );
    // the second account dragged first: the accounts and All Inboxes' rows in that order; then back
    s.core.move_account(second, 0).unwrap();
    let order = |core: &pe_core::Core| core.accounts().unwrap().iter().map(|a| a.id).collect::<Vec<_>>();
    assert_eq!(order(&s.core), [second, first]);
    let rows = s.core.special_folders(pe_core::SpecialFolderKind::Inbox).unwrap();
    assert_eq!(rows.iter().map(|r| r.account).collect::<Vec<_>>(), [second, first]);
    s.core.move_account(second, 1).unwrap();
    assert_eq!(order(&s.core), [first, second]);

    // mail arriving in the second account's Inbox is listed, newest first, and opens the window
    let newest = other_server.add_message("INBOX", &dated("Second's", "Tue, 7 Oct 2025 10:00:00 +0000"), &[]);
    s.core.sync(second).unwrap();
    s.wait(|e| {
        *e == Event::FolderChanged {
            account: second,
            folder: inbox2,
        }
    });
    assert_eq!(subjects(), ["Second's", "First's"]);
    assert_eq!(s.core.count_search(&all).unwrap(), (2, 2));
    let start = pe_core::Start {
        all_inboxes: true,
        folder: inbox2,
        uid: Some(newest),
    };
    assert_eq!(s.core.start_message().unwrap(), Some(start));

    // Mark All Read reaches both servers
    s.core.mark_all_inboxes_read().unwrap();
    assert_eq!(s.core.count_search(&all).unwrap(), (2, 0));
    let all_seen = |server: &ImapKit| {
        server
            .messages("INBOX")
            .iter()
            .all(|m| m["flags"].as_array().unwrap().contains(&json!("\\Seen")))
    };
    for _ in 0..200 {
        if all_seen(&s.server) && all_seen(&other_server) {
            break;
        }
        std::thread::sleep(Duration::from_millis(25));
    }
    assert!(all_seen(&s.server) && all_seen(&other_server));
    assert_eq!(s.server.messages("Archive")[0]["flags"], json!([]), "only the Inboxes");

    // the account's Mark All Read: every folder of that account, no other account's
    other_server.add_message("INBOX", &dated("Second's again", "Wed, 8 Oct 2025 11:00:00 +0000"), &[]);
    s.core.sync(second).unwrap();
    // the message itself in the store, not just a change of that Inbox (the marking above makes some too)
    for _ in 0..400 {
        if s.core.count_search(&all).unwrap() == (3, 1) {
            break;
        }
        std::thread::sleep(Duration::from_millis(25));
    }
    s.core.mark_account_read(first).unwrap();
    let archive_seen = || {
        s.server.messages("Archive")[0]["flags"]
            .as_array()
            .unwrap()
            .contains(&json!("\\Seen"))
    };
    for _ in 0..200 {
        if archive_seen() {
            break;
        }
        std::thread::sleep(Duration::from_millis(25));
    }
    assert!(archive_seen(), "the first account's Archive is read");
    assert_eq!(
        s.core.count_search(&all).unwrap(),
        (3, 1),
        "the second account's new message is still unread"
    );
}

#[test]
fn a_wrong_password_is_reported() {
    let Some(s) = setup() else { return };
    let account = s.core.add_account(&settings(&s.server), "wrong").unwrap();
    s.core.sync(account).unwrap();
    let failed = s.wait(|e| matches!(e, Event::Failed { .. }));
    assert!(
        matches!(failed, Event::Failed { kind: FailureKind::Authentication, account: a, .. } if a == account),
        "{failed:?}"
    );
    s.wait(|e| {
        *e == Event::SyncFinished {
            account,
            failure: Some(FailureKind::Authentication),
        }
    });
    // told once: another sync with the same password fails quietly
    s.core.sync(account).unwrap();
    let next = s.wait(|e| matches!(e, Event::SyncFinished { .. } | Event::Failed { .. }));
    assert_eq!(
        next,
        Event::SyncFinished {
            account,
            failure: Some(FailureKind::Authentication)
        }
    );

    // with the right one it works
    s.core.set_password(account, PASSWORD);
    s.core.sync(account).unwrap();
    s.wait(|e| *e == Event::SyncFinished { account, failure: None });
    assert!(!s.core.folders(account).unwrap().is_empty());
}

#[test]
fn removing_an_account_removes_its_mail() {
    let Some(s) = setup() else { return };
    s.server.add_message("INBOX", &rfc822("First", "x"), &[]);
    let account = s.core.add_account(&settings(&s.server), PASSWORD).unwrap();
    s.core.sync(account).unwrap();
    s.wait(|e| *e == Event::SyncFinished { account, failure: None });
    s.core.remove_account(account).unwrap();
    assert!(s.core.accounts().unwrap().is_empty());
    assert!(s.core.folders(account).unwrap().is_empty());
    assert!(s.core.sync(account).is_err());
}

#[test]
fn sends_replies_and_keeps_a_copy() {
    let Some(s) = setup() else { return };
    let account = s.core.add_account(&settings(&s.server), PASSWORD).unwrap();
    s.core.sync(account).unwrap();
    s.wait(|e| *e == Event::SyncFinished { account, failure: None });

    let outgoing = pe_core::Outgoing {
        to: "Ann <ann@example.com>".into(),
        cc: "bob@example.com".into(),
        bcc: "hidden@example.com".into(),
        subject: "Plans for õhtu".into(),
        text: "Shall we meet?\n.and a dot line\n".into(),
        ..Default::default()
    };
    let sent_id = s
        .core
        .folders(account)
        .unwrap()
        .iter()
        .find(|f| f.info.special_use.as_deref() == Some("\\Sent"))
        .unwrap()
        .id;
    s.core.send(account, outgoing).unwrap();
    // with its subject, for the window to say what went
    let sent = s.wait(|e| matches!(e, Event::MessageSent { account: a, .. } if *a == account));
    assert_eq!(
        sent,
        Event::MessageSent {
            account,
            subject: "Plans for õhtu".into()
        }
    );
    // then the copy in Sent
    s.wait(|e| {
        *e == Event::FolderChanged {
            account,
            folder: sent_id,
        }
    });

    // ImapKit's SMTP server delivers to its INBOX
    let delivered = s.server.messages("INBOX");
    assert_eq!(delivered.len(), 1);
    let folders = s.core.folders(account).unwrap();
    let sent = folders.iter().find(|f| f.id == sent_id).unwrap();
    assert_eq!((sent.total, sent.unread), (1, 0), "a read copy in Sent");
    let copy = &s.core.messages(sent.id, Sort::default(), 0, 10).unwrap()[0].info;
    assert_eq!(copy.subject, "Plans for õhtu");
    assert_eq!(copy.recipients, "Ann");

    // the reply to what arrived
    s.core.sync(account).unwrap();
    s.wait(|e| *e == Event::SyncFinished { account, failure: None });
    let inbox = folders.iter().find(|f| f.info.path == "INBOX").unwrap().id;
    let uid = s.core.messages(inbox, Sort::default(), 0, 10).unwrap()[0].info.uid;
    s.core.open_message(inbox, uid).unwrap();
    s.wait(|e| *e == Event::MessageReady { folder: inbox, uid });
    let view = s.core.message_view(inbox, uid, false).unwrap().unwrap();
    assert!(
        view.document.contains(".and a dot line"),
        "dot-stuffing undone: {}",
        view.document
    );
    assert!(!view.to.contains("hidden"), "Bcc is not in the headers");
    let reply = s.core.draft(inbox, uid, pe_core::DraftKind::ReplyAll).unwrap().unwrap();
    assert_eq!(reply.subject, "Re: Plans for õhtu");
    assert_eq!(reply.to, "Ann <ann@example.com>");
    assert_eq!(reply.cc, "bob@example.com");
    assert!(reply.quote.contains("Shall we meet?"), "{}", reply.quote);
    assert!(reply.in_reply_to.is_some());

    // the reply as the editor sends it: HTML, the quote after it, a text part made from both
    let answer = pe_core::Outgoing {
        to: reply.to.clone(),
        subject: reply.subject.clone(),
        html: Some("<div>Yes, at <b>six</b>.</div>".into()),
        quote: Some(reply.quote.clone()),
        in_reply_to: reply.in_reply_to.clone(),
        references: reply.references.clone(),
        ..Default::default()
    };
    s.core.send(account, answer).unwrap();
    s.wait(|e| matches!(e, Event::MessageSent { account: a, .. } if *a == account));
    let delivered = s.server.messages("INBOX");
    let raw = delivered.last().unwrap()["raw"].as_str().unwrap();
    let raw =
        String::from_utf8(base64::Engine::decode(&base64::engine::general_purpose::STANDARD, raw).unwrap()).unwrap();
    assert!(raw.contains("multipart/alternative"), "{raw}");
    assert!(
        raw.contains("Content-Type: text/html") && raw.contains("Content-Type: text/plain"),
        "{raw}"
    );
    assert!(raw.contains("<b>six</b>") && raw.contains("Original Message"), "{raw}");

    // a recipient that is no address: nothing is sent
    let bad = pe_core::Outgoing {
        to: "not an address".into(),
        text: "x".into(),
        ..Default::default()
    };
    let refused = s.core.send(account, bad).unwrap_err();
    assert!(refused.to_string().contains("not an e-mail address"), "{refused}");
    assert_eq!(s.server.messages("INBOX").len(), 2);
}

#[test]
fn signs_in_with_oauth() {
    // the account is the one the ID token names, which XOAUTH2 signs in as
    const SIGNED_IN: &str = "testuser@example.com";
    let users =
        json!({ "users": { SIGNED_IN: { "password": PASSWORD, "xoauth2": { "accessToken": pe_testkit::TOKEN } } } });
    let Some(server) = ImapKit::start(users) else {
        return;
    };
    let token_port = pe_testkit::oauth_token_server(SIGNED_IN);
    let dir = TempDir::new("core-oauth");
    let (sender, events) = channel();
    let endpoint = |port| pe_oauth::Endpoint {
        host: "127.0.0.1".into(),
        port,
        security: pe_net::Security::Plain,
    };
    let mock = pe_oauth::Provider {
        kind: pe_oauth::ProviderKind::Google,
        imap: endpoint(server.imap),
        smtp: endpoint(server.smtp),
        authorize_url: "https://accounts.example.com/auth".into(),
        token_url: format!("http://127.0.0.1:{token_port}/token"),
        scopes: vec!["https://mail.google.com/".into()],
        client_id: "client".into(),
        client_secret: None,
        response_issuer: None,
    };
    let options = pe_core::Options {
        passwords: pe_core::PasswordStore::Memory,
        oauth_providers: vec![mock],
        ..Default::default()
    };
    let core = Core::open_with(dir.path().join("store.db"), options, move |event| {
        let _ = sender.send(event);
    })
    .unwrap();
    // a message sent goes at once, as in the other tests
    core.set_send_delay(0).unwrap();
    let wait = |accept: &dyn Fn(&Event) -> bool| loop {
        let event = events.recv_timeout(Duration::from_secs(10)).expect("an event");
        if accept(&event) {
            return event;
        }
        assert!(!matches!(event, Event::Failed { .. }), "{event:?}");
    };

    assert_eq!(
        core.oauth_provider_for("imap.gmail.com"),
        Some(pe_oauth::ProviderKind::Google)
    );
    let google = pe_core::SignInWith::Builtin(pe_oauth::ProviderKind::Google);
    let sign_in = |email: &str, code: &str| {
        let (request, url) = core.sign_in_begin(google, email).unwrap();
        assert!(url.starts_with("https://accounts.example.com/auth?"), "{url}");
        let page = pe_testkit::oauth_browser(&url, code);
        wait(&|e| *e == Event::SignInDone { request });
        (request, page)
    };
    // the built-in Google client is off out of the box: no new account with it
    assert!(!core.sign_in_enabled(google).unwrap());
    let (request, _) = sign_in(USER, "the-code");
    assert!(matches!(
        core.add_signed_in_account(request, ""),
        Err(pe_core::Error::TurnedOff)
    ));
    assert!(core.accounts().unwrap().is_empty());
    core.set_sign_in_enabled(google, true).unwrap();
    let (request, page) = sign_in(USER, "the-code");
    assert!(page.contains("You are signed in"));
    assert_eq!(core.sign_in_result(request), Ok(()));

    // the account is the one signed in to, named as its owner is at the provider, and signs in to ImapKit with
    // XOAUTH2 and the access token from the refresh token, at the provider's servers
    let account = core.add_signed_in_account(request, " ").unwrap();
    let added = &core.accounts().unwrap()[0].settings;
    assert_eq!(
        (added.name.as_str(), added.email.as_str(), added.username.as_str()),
        ("Signed In", SIGNED_IN, SIGNED_IN)
    );
    assert_eq!(added.smtp_host, "127.0.0.1");
    assert!(matches!(added.auth, pe_store::Auth::OAuth2(ref p) if p == "google"));
    core.sync(account).unwrap();
    wait(&|e| *e == Event::SyncFinished { account, failure: None });
    assert!(!core.folders(account).unwrap().is_empty());
    // the sign-in was taken
    assert!(core.add_signed_in_account(request, "Work").is_err());
    // signing in again takes a sign-in of the same account only, also with the client turned off since
    core.set_sign_in_enabled(google, false).unwrap();
    let (again, _) = sign_in(SIGNED_IN, "the-code");
    core.reauthorize(account, again).unwrap();
    let mut other = server.account_settings();
    other.email = "someone.else@example.com".into();
    core.update_account(account, &other).unwrap();
    let (again, _) = sign_in(SIGNED_IN, "the-code");
    let refused = core.reauthorize(account, again).unwrap_err();
    assert!(refused.to_string().contains(SIGNED_IN), "{refused}");
    // changing the settings keeps how it signs in, and its servers
    let mut elsewhere = server.account_settings();
    elsewhere.smtp_host = "smtp.attacker.example".into();
    core.update_account(account, &elsewhere).unwrap();
    let kept = &core.accounts().unwrap()[0].settings;
    assert!(matches!(kept.auth, pe_store::Auth::OAuth2(_)) && kept.smtp_host == "127.0.0.1");

    // a code the provider refuses
    let (refused, _) = sign_in(USER, "wrong-code");
    assert!(core.sign_in_result(refused).unwrap_err().contains("invalid_grant"));
    // told once, then forgotten
    assert!(core.sign_in_result(refused).unwrap_err().contains("not finished"));

    // a cancelled sign-in is forgotten
    let (cancelled, _) = core.sign_in_begin(google, USER).unwrap();
    core.sign_in_cancel(cancelled);
    assert!(core.sign_in_result(cancelled).is_err());
}

/// A sign-in app the user added, against ImapKit's OpenID Connect provider: discovery, the authorization code flow
/// with PKCE, the ID token naming the account, XOAUTH2 to IMAP and SMTP with the tokens, refreshing, turning the
/// app off, and what goes wrong (another issuer in the redirect, a denial, scopes without mail)
#[test]
fn signs_in_with_a_sign_in_app() {
    const ALICE: &str = "alice@example.com";
    let config = json!({
        "users": {
            ALICE: { "password": "pw", "displayName": "Alice Example" },
            "bob@example.com": { "password": "pw" }
        },
        "oauth": {}
    });
    let Some(server) = ImapKit::start(config) else {
        return;
    };
    let issuer = server
        .oauth
        .clone()
        .expect("ImapKit 5.3 or newer, with its OAuth provider");
    let dir = TempDir::new("core-app");
    let (sender, events) = channel();
    let options = pe_core::Options {
        trust: pe_net::Trust::Pinned(vec![server.cert.clone()]),
        passwords: pe_core::PasswordStore::Memory,
        ..Default::default()
    };
    let core = Core::open_with(dir.path().join("store.db"), options, move |event| {
        let _ = sender.send(event);
    })
    .unwrap();
    // a message sent goes at once, as in the other tests
    core.set_send_delay(0).unwrap();
    let wait = |accept: &dyn Fn(&Event) -> bool| loop {
        let event = events.recv_timeout(Duration::from_secs(10)).expect("an event");
        if accept(&event) {
            return event;
        }
    };

    // Check reads the discovery document; saving needs it
    let form = |client_id: &str, scopes: &str| pe_core::SignInAppForm {
        name: "ImapKit".into(),
        issuer: format!("{issuer}/"),
        client_id: client_id.into(),
        scopes: scopes.into(),
        imap_host: "127.0.0.1".into(),
        imap_port: server.imaps,
        imap_security: pe_store::Security::Tls,
        smtp_host: "127.0.0.1".into(),
        smtp_port: server.smtp,
        smtp_security: pe_store::Security::StartTls,
    };
    let mail_scopes = "openid email profile offline_access mail";
    let unchecked = core.save_sign_in_app(None, &form("imapkit-approve", mail_scopes), pe_core::SecretChange::Keep);
    assert!(matches!(unchecked, Err(pe_core::Error::Invalid(_))));
    assert!(core.sign_in_app_check("http://imapkit.example").is_err());
    let check = core.sign_in_app_check(&issuer).unwrap();
    wait(&|e| *e == Event::SignInAppChecked { request: check });
    let found = core.sign_in_app_check_result(check).unwrap().unwrap();
    assert_eq!(found.token_url, format!("{issuer}/token"));
    assert_eq!(found.response_issuer.as_deref(), Some(issuer.as_str()));
    let app = core
        .save_sign_in_app(None, &form("imapkit-approve", mail_scopes), pe_core::SecretChange::Keep)
        .unwrap();
    let with = pe_core::SignInWith::App(app);
    assert!(core.sign_in_enabled(with).unwrap());

    let sign_in = |with, email: &str| {
        let (request, url) = core.sign_in_begin(with, email).unwrap();
        assert!(url.starts_with(&format!("{issuer}/authorize?")), "{url}");
        let page = pe_testkit::oauth_follow(&url);
        wait(&|e| *e == Event::SignInDone { request });
        (request, page)
    };
    let (request, page) = sign_in(with, ALICE);
    assert!(page.contains("You are signed in"), "{page}");
    assert_eq!(core.sign_in_result(request), Ok(()));
    let account = core.add_signed_in_account(request, "").unwrap();
    let added = &core.account(account).unwrap().settings;
    assert_eq!((added.name.as_str(), added.email.as_str()), ("Alice Example", ALICE));
    assert_eq!(added.auth, pe_store::Auth::OAuth2(format!("app:{app}")));
    assert_eq!((added.imap_port, added.smtp_port), (server.imaps, server.smtp));

    // IMAP and SMTP with the access token
    core.sync(account).unwrap();
    wait(&|e| *e == Event::SyncFinished { account, failure: None });
    assert!(!core.folders(account).unwrap().is_empty());
    let outgoing = pe_core::Outgoing {
        to: "bob@example.com".into(),
        subject: "Signed in with a sign-in app".into(),
        text: "Hello".into(),
        ..Default::default()
    };
    core.send(account, outgoing).unwrap();
    wait(&|e| matches!(e, Event::MessageSent { .. }));
    let used = server.request("GET", "/v1/oauth/tokens?user=alice%40example.com&type=access", None);
    let first_tokens = used.as_array().map_or(0, Vec::len);
    assert!(first_tokens >= 1, "{used}");

    // a worker started again makes a new access token from the refresh token
    server.request("POST", "/v1/oauth/tokens/expire", Some(json!({ "user": ALICE })));
    core.update_account(account, &core.account(account).unwrap().settings)
        .unwrap();
    core.sync(account).unwrap();
    wait(&|e| *e == Event::SyncFinished { account, failure: None });
    let used = server.request("GET", "/v1/oauth/tokens?user=alice%40example.com&type=access", None);
    assert!(used.as_array().map_or(0, Vec::len) > first_tokens, "{used}");

    // the manager lists it with its account; removing it is refused while the account uses it
    let entries = core.sign_in_apps().unwrap();
    let entry = entries.iter().find(|e| e.with == with).unwrap();
    assert_eq!(
        (entry.name.as_str(), entry.used_by.as_slice()),
        ("ImapKit", &[ALICE.to_string()][..])
    );
    let in_use = core.remove_sign_in_app(app).unwrap_err();
    assert!(in_use.to_string().contains(ALICE), "{in_use}");

    // turned off: no new account with it, but its account signs in again
    core.set_sign_in_enabled(with, false).unwrap();
    let (request, _) = sign_in(with, ALICE);
    core.reauthorize(account, request).unwrap();
    let (request, _) = sign_in(with, "bob@example.com");
    assert!(matches!(
        core.add_signed_in_account(request, ""),
        Err(pe_core::Error::TurnedOff)
    ));
    core.set_sign_in_enabled(with, true).unwrap();

    // a redirect that names another issuer (RFC 9207), and a denial
    for (decision, reason) in [("wrong-iss", "another sign-in"), ("deny", "cancelled")] {
        server.request("POST", "/v1/oauth/decisions", Some(json!({ "decision": decision })));
        let (request, page) = sign_in(with, ALICE);
        let error = core.sign_in_result(request).unwrap_err();
        assert!(error.contains(reason), "{decision}: {error}\n{page}");
    }

    // scopes without mail: signing in works, the mail server refuses the token and says to check the scopes
    let check = core.sign_in_app_check(&issuer).unwrap();
    wait(&|e| *e == Event::SignInAppChecked { request: check });
    let no_mail = core
        .save_sign_in_app(
            None,
            &form("imapkit-approve", "openid email offline_access"),
            pe_core::SecretChange::Keep,
        )
        .unwrap();
    let (request, _) = sign_in(pe_core::SignInWith::App(no_mail), "bob@example.com");
    let bob = core.add_signed_in_account(request, "").unwrap();
    core.sync(bob).unwrap();
    let failed = wait(&|e| matches!(e, Event::Failed { account, .. } if *account == bob));
    let Event::Failed { kind, message, .. } = failed else {
        unreachable!()
    };
    assert_eq!(kind, FailureKind::Authentication);
    assert!(message.contains("check that the app\u{2019}s scopes"), "{message}");

    // removed once nothing uses it, and its account goes first
    core.remove_account(bob).unwrap();
    core.remove_sign_in_app(no_mail).unwrap();
    assert!(
        core.sign_in_apps()
            .unwrap()
            .iter()
            .all(|e| e.with != pe_core::SignInWith::App(no_mail))
    );
}

/// The search: what sync brings is found by its subject, its people (decoded) and its files, in a folder or in all of
/// them, with Gmail's operators; and their text, fetched in the background
fn raw_has(message: &serde_json::Value, text: &str) -> bool {
    pe_testkit::raw_text(message).contains(text)
}

#[test]
fn searches_the_local_index() {
    let Some(s) = setup() else { return };
    let report = "From: =?utf-8?q?=C3=95ie_S=C3=A4=C3=A4sk?= <oie@example.com>\r\nTo: Bob <bob@example.com>\r\n\
                  Cc: Carol <carol@example.com>\r\nSubject: =?utf-8?q?Kvartali_aruanne?=\r\nMessage-ID: <report@x>\r\n\
                  Date: Mon, 6 Oct 2025 10:00:00 +0000\r\nContent-Type: multipart/mixed; boundary=m\r\n\r\n\
                  --m\r\nContent-Type: text/plain\r\n\r\nThe numbers mention a zebra.\r\n\
                  --m\r\nContent-Type: application/pdf; name=\"q3-numbers.pdf\"\r\nContent-Disposition: attachment; \
                  filename=\"q3-numbers.pdf\"\r\nContent-Transfer-Encoding: base64\r\n\r\nJVBERg==\r\n--m--\r\n";
    let report_uid = s.server.add_message("INBOX", report, &["\\Seen"]);
    s.server
        .add_message("INBOX", &rfc822("Lunch", "a giraffe at noon"), &[]);
    s.server.add_message(
        "Archive",
        &rfc822("Old numbers", "nothing else"),
        &["\\Seen", "\\Flagged"],
    );
    let account = s.core.add_account(&settings(&s.server), PASSWORD).unwrap();
    s.core.sync(account).unwrap();
    s.wait(|e| *e == Event::SyncFinished { account, failure: None });
    let folders = s.core.folders(account).unwrap();
    let inbox = folders.iter().find(|f| f.info.path == "INBOX").unwrap().id;
    let subjects = |folder: Option<i64>, text: &str| -> Vec<String> {
        let search = pe_core::Search {
            scope: folder.map_or(pe_core::Scope::Everywhere, pe_core::Scope::Folder),
            text: text.into(),
            ..Default::default()
        };
        let mut found: Vec<String> = s
            .core
            .search(&search, Sort::default(), 0, 50)
            .unwrap()
            .into_iter()
            .map(|m| m.info.subject)
            .collect();
        found.sort();
        found
    };
    // decoded subject and people, the file name, from the summary alone
    assert_eq!(subjects(Some(inbox), "aruanne"), ["Kvartali aruanne"]);
    assert_eq!(subjects(Some(inbox), "from:saask"), ["Kvartali aruanne"]);
    assert_eq!(subjects(Some(inbox), "cc:carol"), ["Kvartali aruanne"]);
    assert_eq!(subjects(Some(inbox), "filename:q3"), ["Kvartali aruanne"]);
    assert_eq!(subjects(Some(inbox), "has:attachment"), ["Kvartali aruanne"]);
    assert_eq!(subjects(Some(inbox), "is:unread"), ["Lunch"]);
    // every folder, and in: ("numbers" is in a file name too)
    assert_eq!(subjects(None, "numbers"), ["Kvartali aruanne", "Old numbers"]);
    assert_eq!(subjects(None, "old"), ["Old numbers"]);
    assert_eq!(subjects(Some(inbox), "in:archive is:starred"), ["Old numbers"]);
    let search = pe_core::Search {
        text: "numbers".into(),
        ..Default::default()
    };
    assert_eq!(s.core.count_search(&search).unwrap(), (2, 0));
    // the text of every message, fetched in the background after the sync (only the text parts, without marking
    // anything read or downloading the messages)
    let deadline = std::time::Instant::now() + Duration::from_secs(20);
    while s.core.unindexed_count().unwrap() > 0 {
        assert!(std::time::Instant::now() < deadline, "the texts were not indexed");
        std::thread::sleep(Duration::from_millis(100));
    }
    assert_eq!(subjects(Some(inbox), "zebra"), ["Kvartali aruanne"]);
    assert_eq!(subjects(Some(inbox), "giraffe noon"), ["Lunch"]);
    assert_eq!(subjects(None, "zebra -filename:q3"), [] as [&str; 0]);
    let lunch = s
        .server
        .messages("INBOX")
        .into_iter()
        .find(|m| raw_has(m, "Lunch"))
        .unwrap();
    assert!(!lunch["flags"].to_string().contains("Seen"), "{lunch}");
    let listed = s.core.messages(inbox, Sort::default(), 0, 10).unwrap();
    assert!(listed.iter().all(|m| !m.cached), "only the text parts were fetched");
    // and the first words of each for the list, from the same text
    let snippet = |subject: &str| {
        listed
            .iter()
            .find(|m| m.info.subject == subject)
            .and_then(|m| m.snippet.clone())
    };
    assert_eq!(snippet("Lunch").as_deref(), Some("a giraffe at noon"));
    assert_eq!(
        snippet("Kvartali aruanne").as_deref(),
        Some("The numbers mention a zebra.")
    );
    // opened, the cached source indexes it again, with what the parser reads in it
    s.core.open_message(inbox, report_uid).unwrap();
    s.wait(|e| {
        *e == Event::MessageReady {
            folder: inbox,
            uid: report_uid,
        }
    });
    assert_eq!(subjects(Some(inbox), "zebra"), ["Kvartali aruanne"]);
}

#[test]
fn flags_moves_and_deletes_messages() {
    let Some(s) = setup() else { return };
    let flag = s.server.add_message("INBOX", &rfc822("Flag me", "1"), &[]);
    let archive = s.server.add_message("INBOX", &rfc822("Archive me", "2"), &[]);
    let delete = s.server.add_message("INBOX", &rfc822("Delete me", "3"), &[]);
    let account = s.core.add_account(&settings(&s.server), PASSWORD).unwrap();
    s.core.sync(account).unwrap();
    s.wait(|e| *e == Event::SyncFinished { account, failure: None });
    let folders = s.core.folders(account).unwrap();
    let id = |path: &str| folders.iter().find(|f| f.info.path == path).unwrap().id;
    let (inbox, archive_folder, trash) = (id("INBOX"), id("Archive"), id("Trash"));
    let in_store = |folder| -> Vec<String> {
        let mut subjects: Vec<String> = s
            .core
            .messages(folder, Sort::default(), 0, 100)
            .unwrap()
            .into_iter()
            .map(|m| m.info.subject)
            .collect();
        subjects.sort();
        subjects
    };
    // waits for the server to have what `done` checks
    let eventually = |done: &dyn Fn() -> bool| {
        for _ in 0..200 {
            if done() {
                return;
            }
            std::thread::sleep(Duration::from_millis(25));
        }
        panic!("the server did not get there");
    };

    // a flag: in the store at once, on the server soon
    s.core.set_flag_many(inbox, &[flag], "\\Flagged", true).unwrap();
    s.wait(|e| *e == Event::FolderChanged { account, folder: inbox });
    let row = s.core.messages(inbox, Sort::default(), 0, 100).unwrap();
    assert!(row.iter().find(|m| m.info.uid == flag).unwrap().info.flagged());
    eventually(&|| s.server.flags("INBOX", flag).contains(&"\\Flagged".to_string()));
    s.core.set_flag_many(inbox, &[flag], "\\Flagged", false).unwrap();
    eventually(&|| !s.server.flags("INBOX", flag).contains(&"\\Flagged".to_string()));

    // a move: gone from the list at once, in the other folder once the server has it
    s.core.move_messages(inbox, &[archive], archive_folder).unwrap();
    assert_eq!(in_store(inbox), ["Delete me", "Flag me"]);
    s.wait(|e| {
        *e == Event::FolderChanged {
            account,
            folder: archive_folder,
        }
    });
    assert_eq!(in_store(archive_folder), ["Archive me"]);
    assert_eq!(s.server.subjects("Archive"), ["Archive me"]);
    // not into a folder of another account, nor into the folder it is in
    assert!(s.core.move_messages(inbox, &[flag], inbox).is_err());

    // a copy: still in the Inbox, and in the other folder once the server has it
    s.core.copy_messages(inbox, &[flag], archive_folder).unwrap();
    s.wait(|e| {
        *e == Event::FolderChanged {
            account,
            folder: archive_folder,
        }
    });
    assert_eq!(in_store(inbox), ["Delete me", "Flag me"]);
    eventually(&|| s.server.subjects("Archive").len() == 2);
    assert!(s.core.copy_messages(inbox, &[flag], inbox).is_err());
    assert!(s.core.copy_messages(inbox, &[999_999], archive_folder).is_err());

    // deleting: into Deleted Items, and from there for good (which the window asks about first)
    assert!(!s.core.deletes_for_good(inbox).unwrap());
    assert!(s.core.deletes_for_good(trash).unwrap());
    s.core.delete_messages(inbox, &[delete]).unwrap();
    s.wait(|e| *e == Event::FolderChanged { account, folder: trash });
    assert_eq!(in_store(trash), ["Delete me"]);
    assert_eq!(s.server.subjects("Trash"), ["Delete me"]);
    let in_trash = s.core.messages(trash, Sort::default(), 0, 10).unwrap()[0].info.uid;
    s.core.delete_messages(trash, &[in_trash]).unwrap();
    assert!(in_store(trash).is_empty());
    eventually(&|| s.server.subjects("Trash").is_empty());
    assert_eq!(s.server.subjects("INBOX"), ["Flag me"]);

    // a sync agrees with all of it
    s.core.sync(account).unwrap();
    s.wait(|e| *e == Event::SyncFinished { account, failure: None });
    assert_eq!(in_store(inbox), ["Flag me"]);
    assert!(in_store(trash).is_empty());

    // junk: $Junk on the server and into the Junk folder; not junk: $NotJunk, back in the Inbox
    let junk = id("Junk");
    s.core.mark_junk_many(inbox, &[flag], true).unwrap();
    assert!(in_store(inbox).is_empty());
    s.wait(|e| *e == Event::FolderChanged { account, folder: junk });
    assert_eq!(in_store(junk), ["Flag me"]);
    let junk_flags = |s: &Setup| s.server.messages("Junk").first().map(|m| m["flags"].clone());
    eventually(&|| junk_flags(&s).is_some_and(|f| f.as_array().unwrap().contains(&json!("$Junk"))));
    let in_junk = s.core.messages(junk, Sort::default(), 0, 10).unwrap()[0].info.uid;
    s.core.mark_junk_many(junk, &[in_junk], false).unwrap();
    s.wait(|e| *e == Event::FolderChanged { account, folder: inbox });
    assert_eq!(in_store(inbox), ["Flag me"]);
    eventually(&|| {
        s.server.messages("INBOX").first().is_some_and(|m| {
            let flags = m["flags"].as_array().unwrap();
            flags.contains(&json!("$NotJunk")) && !flags.contains(&json!("$Junk"))
        })
    });
    assert!(s.core.mark_junk_many(inbox, &[999_999], true).is_err());
}

#[test]
fn acts_on_selected_messages_and_undoes() {
    let Some(s) = setup() else { return };
    let uids: Vec<u64> = ["One", "Two", "Three", "Four"]
        .iter()
        .map(|subject| s.server.add_message("INBOX", &rfc822(subject, "x"), &[]))
        .collect();
    let account = s.core.add_account(&settings(&s.server), PASSWORD).unwrap();
    s.core.sync(account).unwrap();
    s.wait(|e| *e == Event::SyncFinished { account, failure: None });
    let folders = s.core.folders(account).unwrap();
    let id = |path: &str| folders.iter().find(|f| f.info.path == path).unwrap().id;
    let (inbox, archive, trash, junk) = (id("INBOX"), id("Archive"), id("Trash"), id("Junk"));
    let at = |folder, uid| MessageRef { folder, uid };
    let eventually = |done: &dyn Fn() -> bool| {
        for _ in 0..400 {
            if done() {
                return;
            }
            std::thread::sleep(Duration::from_millis(25));
        }
        panic!("did not get there");
    };
    let in_store = |folder| -> Vec<String> {
        let mut subjects: Vec<String> = s
            .core
            .messages(folder, Sort::default(), 0, 100)
            .unwrap()
            .into_iter()
            .map(|m| m.info.subject)
            .collect();
        subjects.sort();
        subjects
    };

    // the list's rows by position, newest (the highest UID, as the dates are the same) first
    let list = Search::folder(inbox);
    let picked = s.core.refs_in_ranges(&list, Sort::default(), &[(0, 2)]).unwrap();
    assert_eq!(picked, [at(inbox, uids[3]), at(inbox, uids[2])]);
    assert_eq!(s.core.positions(&list, Sort::default(), &picked).unwrap(), [0, 1]);

    let three = [at(inbox, uids[0]), at(inbox, uids[1]), at(inbox, uids[2])];
    let summary = s.core.summary(&three).unwrap();
    assert_eq!((summary.count, summary.unread, summary.flagged), (3, 3, 0));
    assert_eq!((summary.accounts, summary.folders, summary.for_good), (1, 1, 0));
    assert!(!summary.in_junk);
    assert_eq!(summary.title(), "3 messages selected");
    assert_eq!(summary.move_title(false), "Move 3 Messages");
    assert_eq!(summary.move_prompt(true), "Copy the 3 selected messages to:");
    assert_eq!(summary.detail(), "3 unread");

    // read and flagged, with one command each
    assert_eq!(
        s.core.act(&three, Action::Read(true)).unwrap(),
        "Marked 3 messages as read"
    );
    s.core.act(&three[..2], Action::Flag(true)).unwrap();
    let summary = s.core.summary(&three).unwrap();
    assert_eq!((summary.unread, summary.flagged), (0, 2));
    assert!(summary.flags());
    // toggled: one is not flagged, so all are; then all are, so none
    // (what the server says of the flags meanwhile can show an older state for a moment; it settles on the last)
    s.core.act(&three, Action::ToggleFlag).unwrap();
    eventually(&|| !s.core.summary(&three).unwrap().flags());
    s.core.act(&three, Action::ToggleFlag).unwrap();
    eventually(&|| s.core.summary(&three).unwrap().flagged == 0);
    eventually(&|| {
        uids[..3]
            .iter()
            .all(|&uid| s.server.flags("INBOX", uid).contains(&"\\Seen".into()))
    });
    assert_eq!(s.core.undo_label(), None, "flags are not undone");

    // moved together, then back with Undo
    assert_eq!(
        s.core.act(&three, Action::Move(archive)).unwrap(),
        "Moved 3 messages to Archive"
    );
    assert_eq!(in_store(inbox), ["Four"]);
    assert_eq!(s.core.undo_label().as_deref(), Some("Undo Move"));
    // at once, before the folder they went to has shown them: the worker takes it back after the move
    assert_eq!(s.core.undo().unwrap(), "Moved 3 messages back to Inbox");
    assert_eq!(s.core.undo_label(), None);
    eventually(&|| in_store(inbox).len() == 4 && in_store(archive).is_empty());
    // the window selects them once they are back; then they are forgotten
    let restored = s.core.restored().unwrap();
    let mut back: Vec<u64> = restored.iter().map(|r| r.uid).collect();
    back.sort();
    assert_eq!(back.len(), 3);
    assert!(restored.iter().all(|r| r.folder == inbox));
    assert!(s.core.restored().unwrap().is_empty());
    assert_eq!(s.server.subjects("Archive").len(), 0);

    // deleted into Deleted Items, then back
    let all: Vec<MessageRef> = s.core.refs_in_ranges(&list, Sort::default(), &[(0, 4)]).unwrap();
    assert_eq!(s.core.summary(&all).unwrap().delete_question(), None);
    assert_eq!(
        s.core.act(&all[..2], Action::Delete).unwrap(),
        "Moved 2 messages to Deleted Items"
    );
    assert_eq!(s.core.undo_label().as_deref(), Some("Undo Delete"));
    eventually(&|| in_store(trash).len() == 2);
    s.core.undo().unwrap();
    eventually(&|| in_store(inbox).len() == 4 && s.server.subjects("Trash").is_empty());

    // junk and back: $Junk taken away again
    let all: Vec<MessageRef> = s.core.refs_in_ranges(&list, Sort::default(), &[(0, 4)]).unwrap();
    assert_eq!(
        s.core.act(&all[..1], Action::Junk(true)).unwrap(),
        "Moved 1 message to Junk E-mail"
    );
    eventually(&|| in_store(junk).len() == 1);
    assert_eq!(s.core.undo_label().as_deref(), Some("Undo Mark as Junk"));
    s.core.undo().unwrap();
    eventually(&|| in_store(inbox).len() == 4 && s.server.subjects("Junk").is_empty());
    eventually(&|| {
        s.server
            .messages("INBOX")
            .iter()
            .all(|m| !m["flags"].as_array().unwrap().contains(&json!("$Junk")))
    });

    // copies stay; from Deleted Items, delete asks first and removes for good
    let all: Vec<MessageRef> = s.core.refs_in_ranges(&list, Sort::default(), &[(0, 4)]).unwrap();
    assert_eq!(
        s.core.act(&all[..2], Action::Copy(archive)).unwrap(),
        "Copied 2 messages to Archive"
    );
    eventually(&|| in_store(archive).len() == 2);
    assert_eq!(in_store(inbox).len(), 4);
    let in_archive = s
        .core
        .refs_in_ranges(&Search::folder(archive), Sort::default(), &[(0, 2)])
        .unwrap();
    s.core.act(&in_archive, Action::Move(trash)).unwrap();
    eventually(&|| in_store(trash).len() == 2);
    let in_trash = s
        .core
        .refs_in_ranges(&Search::folder(trash), Sort::default(), &[(0, 2)])
        .unwrap();
    let mixed = [in_trash[0], all[0]];
    assert_eq!(
        s.core.summary(&mixed).unwrap().delete_question().as_deref(),
        Some("1 of the 2 messages will be deleted for good. Delete the messages?")
    );
    assert_eq!(
        s.core.summary(&in_trash).unwrap().delete_question().as_deref(),
        Some("These 2 messages will be deleted for good. Delete them?")
    );
    assert_eq!(
        s.core.act(&in_trash, Action::Delete).unwrap(),
        "Deleted 2 messages for good"
    );
    assert_eq!(s.core.undo_label(), None, "for good is not undone");
    eventually(&|| s.server.subjects("Trash").is_empty());

    // not into a folder of another account or one that holds no messages, and nothing when they are gone
    assert!(s.core.act(&[at(inbox, 999_999)], Action::Read(true)).is_err());
}

#[test]
fn moves_and_copies_between_accounts() {
    let Some(s) = setup() else { return };
    let Some(other_server) = ImapKit::start(json!({})) else {
        return;
    };
    let moved = s
        .server
        .add_message("INBOX", &rfc822("Move me", "x"), &["\\Seen", "\\Flagged"]);
    let copied = s.server.add_message("INBOX", &rfc822("Copy me", "y"), &[]);
    let first = s.core.add_account(&settings(&s.server), PASSWORD).unwrap();
    s.core.sync(first).unwrap();
    s.wait(|e| {
        *e == Event::SyncFinished {
            account: first,
            failure: None,
        }
    });
    let second = s.core.add_account(&settings(&other_server), PASSWORD).unwrap();
    s.core.sync(second).unwrap();
    s.wait(|e| {
        *e == Event::SyncFinished {
            account: second,
            failure: None,
        }
    });
    let folder = |account, path: &str| {
        s.core
            .folders(account)
            .unwrap()
            .into_iter()
            .find(|f| f.info.path == path)
            .unwrap()
            .id
    };
    let (inbox, archive2) = (folder(first, "INBOX"), folder(second, "Archive"));
    let at = |folder, uid| MessageRef { folder, uid };
    let eventually = |done: &dyn Fn() -> bool| {
        for _ in 0..400 {
            if done() {
                return;
            }
            std::thread::sleep(Duration::from_millis(25));
        }
        panic!("did not get there");
    };
    let in_store = |folder| -> Vec<String> {
        let mut subjects: Vec<String> = s
            .core
            .messages(folder, Sort::default(), 0, 100)
            .unwrap()
            .into_iter()
            .map(|m| m.info.subject)
            .collect();
        subjects.sort();
        subjects
    };

    // a move: out of the list at once, on the other server with its flags, then gone from the first
    assert_eq!(
        s.core.act(&[at(inbox, moved)], Action::Move(archive2)).unwrap(),
        "Moving 1 message to Archive..."
    );
    assert_eq!(in_store(inbox), ["Copy me"]);
    eventually(&|| other_server.subjects("Archive") == ["Move me"]);
    eventually(&|| s.server.subjects("INBOX") == ["Copy me"]);
    let there = &other_server.messages("Archive")[0];
    let flags = there["flags"].as_array().unwrap();
    assert!(
        flags.contains(&json!("\\Seen")) && flags.contains(&json!("\\Flagged")),
        "{there}"
    );
    eventually(&|| in_store(archive2) == ["Move me"]);
    assert_eq!(s.core.recent_targets(3).unwrap(), [archive2]);
    // the Move and Copy window: Recent first, named with the account; the folder they are in can not be chosen
    let rows = s.core.move_targets(Some(inbox), "").unwrap();
    assert_eq!(rows[0].kind, pe_core::TargetKind::Heading);
    assert_eq!((rows[1].kind, rows[1].folder), (pe_core::TargetKind::Recent, archive2));
    assert!(rows[1].label.starts_with("Archive ("), "{}", rows[1].label);
    let current = rows
        .iter()
        .find(|r| r.kind == pe_core::TargetKind::Folder && r.folder == inbox)
        .unwrap();
    assert_eq!(current.label, "Inbox (current)");
    assert!(!current.choosable);
    assert_eq!(
        rows.iter().filter(|r| r.kind == pe_core::TargetKind::Account).count(),
        2
    );
    // typed: what matches with the accounts above, without Recent, accents and case aside
    let rows = s.core.move_targets(Some(inbox), "ÁRCH").unwrap();
    let kinds: Vec<_> = rows.iter().map(|r| (r.kind, r.label.as_str())).collect();
    assert_eq!(
        kinds
            .iter()
            .filter(|(k, _)| *k == pe_core::TargetKind::Folder)
            .map(|(_, l)| *l)
            .collect::<Vec<_>>(),
        ["Archive", "Archive"]
    );
    assert!(rows.iter().all(|r| r.kind != pe_core::TargetKind::Recent));
    assert!(s.core.move_targets(None, "nothing like it").unwrap().is_empty());

    // a copy: both keep it
    s.core.act(&[at(inbox, copied)], Action::Copy(archive2)).unwrap();
    eventually(&|| other_server.subjects("Archive").len() == 2);
    assert_eq!(s.server.subjects("INBOX"), ["Copy me"]);

    // Undo takes the move back, across the accounts again
    assert_eq!(s.core.undo_label().as_deref(), Some("Undo Move"));
    s.core.undo().unwrap();
    eventually(&|| s.server.subjects("INBOX").len() == 2);
    eventually(&|| other_server.subjects("Archive") == ["Copy me"]);
    eventually(&|| in_store(inbox) == ["Copy me", "Move me"]);

    // a message the target refuses comes back where it was, and the user is told
    let gone = folder(second, "Junk");
    other_server.delete_folder("Junk");
    let back = s
        .core
        .refs_in_ranges(&Search::folder(inbox), Sort::default(), &[(0, 2)])
        .unwrap();
    s.core.act(&back[..1], Action::Move(gone)).unwrap();
    s.wait(|e| matches!(e, Event::Failed { account, message, .. } if *account == first && message.contains("could not be moved")));
    eventually(&|| in_store(inbox).len() == 2);
    assert_eq!(s.server.subjects("INBOX").len(), 2);
}

#[test]
fn a_move_between_accounts_cut_short_goes_on_without_a_second_copy() {
    let Some(s) = setup() else { return };
    let Some(other_server) = ImapKit::start(json!({})) else {
        return;
    };
    let raw = rfc822("Half moved", "x");
    let uid = s.server.add_message("INBOX", &raw, &[]);
    // the copy had arrived when the app stopped, the original was not removed yet
    other_server.add_message("Archive", &raw, &[]);
    let first = s.core.add_account(&settings(&s.server), PASSWORD).unwrap();
    s.core.sync(first).unwrap();
    s.wait(|e| {
        *e == Event::SyncFinished {
            account: first,
            failure: None,
        }
    });
    let second = s.core.add_account(&settings(&other_server), PASSWORD).unwrap();
    s.core.sync(second).unwrap();
    s.wait(|e| {
        *e == Event::SyncFinished {
            account: second,
            failure: None,
        }
    });
    let folder = |account, path: &str| {
        s.core
            .folders(account)
            .unwrap()
            .into_iter()
            .find(|f| f.info.path == path)
            .unwrap()
            .id
    };
    let (inbox, archive2) = (folder(first, "INBOX"), folder(second, "Archive"));
    {
        let store = pe_store::Store::open(s._dir.path().join("store.db")).unwrap();
        store
            .add_transfers(&[pe_store::Transfer {
                id: 0,
                account: first,
                from: inbox,
                uid,
                to: archive2,
                copy: false,
                message_id: Some("<Halfmoved@example.com>".into()),
                flags: String::new(),
                internal_date: None,
                source: None,
                tried: false,
            }])
            .unwrap();
        let id = store.next_transfer(first, 0).unwrap().unwrap().id;
        store.set_transfer_tried(id).unwrap();
    }
    // the next sync of the account finishes it
    s.core.sync(first).unwrap();
    s.wait(|e| {
        *e == Event::SyncFinished {
            account: first,
            failure: None,
        }
    });
    assert_eq!(other_server.subjects("Archive"), ["Half moved"]);
    assert!(s.server.subjects("INBOX").is_empty());
}

#[test]
fn messages_become_files() {
    let Some(s) = setup() else { return };
    let lunch = s.server.add_message("INBOX", &rfc822("Lunch", "first"), &[]);
    let lunch2 = s.server.add_message("INBOX", &rfc822("Lunch", "second"), &[]);
    let other = s.server.add_message("INBOX", &rfc822("Other", "third"), &[]);
    let account = s.core.add_account(&settings(&s.server), PASSWORD).unwrap();
    s.core.sync(account).unwrap();
    s.wait(|e| *e == Event::SyncFinished { account, failure: None });
    let inbox = s
        .core
        .folders(account)
        .unwrap()
        .into_iter()
        .find(|f| f.info.path == "INBOX")
        .unwrap()
        .id;
    let refs: Vec<MessageRef> = [lunch, lunch2, other]
        .iter()
        .map(|&uid| MessageRef { folder: inbox, uid })
        .collect();
    assert_eq!(
        s.core.export_names(&refs).unwrap(),
        ["Lunch.eml", "Lunch (2).eml", "Other.eml"]
    );
    // none was opened: they are downloaded for the files, and kept
    assert!(!s.core.all_downloaded(&refs).unwrap());
    let files = s.core.export_messages(&refs, Duration::from_secs(20)).unwrap();
    assert_eq!(files.len(), 3);
    let body = |f: &pe_core::Exported| String::from_utf8(f.source.clone().unwrap()).unwrap();
    assert!(body(&files[0]).contains("first") && body(&files[1]).contains("second"));
    assert!(s.core.all_downloaded(&refs).unwrap());

    // saved into a folder, never over a file there
    let dir = TempDir::new("export");
    std::fs::write(dir.path().join("Other.eml"), "mine").unwrap();
    let written = s
        .core
        .save_messages(&refs, dir.path(), Duration::from_secs(20))
        .unwrap();
    let mut names: Vec<String> = written
        .iter()
        .map(|p| p.file_name().unwrap().to_string_lossy().into_owned())
        .collect();
    names.sort();
    assert_eq!(names, ["Lunch (2).eml", "Lunch.eml", "Other (2).eml"]);
    assert_eq!(std::fs::read_to_string(dir.path().join("Other.eml")).unwrap(), "mine");

    // forwarded as attachments, the subject the first one's
    let draft = s
        .core
        .forward_as_attachments(&refs[1..], Duration::from_secs(20))
        .unwrap();
    assert_eq!(draft.subject, "Fw: Lunch");
    assert_eq!(draft.attachments.len(), 2);
    assert!(
        std::fs::read_to_string(&draft.attachments[1])
            .unwrap()
            .contains("third")
    );

    // for a drag: written into a folder of the user's own
    let dragged = s.core.drag_files(&refs[..2], Duration::from_secs(20)).unwrap();
    assert_eq!(dragged.len(), 2);
    assert!(std::fs::read_to_string(&dragged[1]).unwrap().contains("second"));
    // a file a drag promised: never over one there
    let promised = pe_core::write_file(dir.path(), "Other.eml", b"x").unwrap();
    assert_eq!(promised.file_name().unwrap().to_string_lossy(), "Other (3).eml");
    assert_eq!(
        pe_core::saved_text(3, dir.path()),
        format!(
            "Saved 3 messages to {}",
            dir.path().file_name().unwrap().to_string_lossy()
        )
    );

    // files dropped on a folder: the messages go in, the rest is told
    let notes = dir.path().join("notes.txt");
    std::fs::write(&notes, "not mail").unwrap();
    let (said, report) = s
        .core
        .import_files(inbox, &[written[0].clone(), notes.clone()])
        .unwrap();
    assert_eq!(said, "Put 1 message in Inbox");
    let report = report.unwrap();
    assert!(report.contains("notes.txt") && !report.contains("Lunch"), "{report}");
    assert!(pe_core::is_message_file(&written[0]) && !pe_core::is_message_file(&notes));
    assert_eq!(s.core.import_files(inbox, &[written[0].clone()]).unwrap().1, None);

    // one gone from the server can not be had: told, the others still come
    let gone = s.server.add_message("INBOX", &rfc822("Gone", "x"), &[]);
    s.core.sync(account).unwrap();
    s.wait(|e| *e == Event::SyncFinished { account, failure: None });
    s.server.expunge("INBOX", &[gone]);
    // the worker's session hears of the expunge first: until then a server may still answer for the message
    s.core.sync(account).unwrap();
    s.wait(|e| *e == Event::SyncFinished { account, failure: None });
    let files = s
        .core
        .export_messages(
            &[
                MessageRef {
                    folder: inbox,
                    uid: gone,
                },
                refs[2],
            ],
            Duration::from_secs(20),
        )
        .unwrap();
    assert!(files[0].source.is_err());
    assert!(files[1].source.is_ok());
}

#[test]
fn flags_in_colors_as_apple_mail_does() {
    let Some(s) = setup() else { return };
    let red = s.server.add_message("INBOX", &rfc822("Red one", "x"), &[]);
    let apple = s.server.add_message(
        "INBOX",
        &rfc822("From Apple Mail", "y"),
        &["\\Flagged", "$MailFlagBit2"],
    );
    let account = s.core.add_account(&settings(&s.server), PASSWORD).unwrap();
    s.core.sync(account).unwrap();
    s.wait(|e| *e == Event::SyncFinished { account, failure: None });
    let inbox = s
        .core
        .folders(account)
        .unwrap()
        .into_iter()
        .find(|f| f.info.path == "INBOX")
        .unwrap()
        .id;
    let at = |uid| MessageRef { folder: inbox, uid };
    let color = |uid| s.core.message(inbox, uid).unwrap().unwrap().info.flag_color();
    let eventually = |done: &dyn Fn() -> bool| {
        for _ in 0..400 {
            if done() {
                return;
            }
            std::thread::sleep(Duration::from_millis(25));
        }
        panic!("did not get there");
    };
    let has = |uid, flag: &str| s.server.flags("INBOX", uid).iter().any(|f| f == flag);

    // one flagged blue by Apple Mail reads as blue
    assert_eq!(color(apple), Some(pe_core::FlagColor::Blue));
    // green: \\Flagged with bits 0 and 1, on the server too
    assert_eq!(
        s.core
            .act(&[at(red)], Action::FlagColor(pe_core::FlagColor::Green))
            .unwrap(),
        "Flagged 1 message green"
    );
    assert_eq!(color(red), Some(pe_core::FlagColor::Green));
    eventually(&|| has(red, "\\Flagged") && has(red, "$MailFlagBit0") && has(red, "$MailFlagBit1"));
    // purple from blue: bit 0 added, bit 2 kept
    s.core
        .act(&[at(apple)], Action::FlagColor(pe_core::FlagColor::Purple))
        .unwrap();
    eventually(&|| has(apple, "$MailFlagBit0") && has(apple, "$MailFlagBit2"));
    // two colours: no one colour in the summary
    let summary = s.core.summary(&[at(red), at(apple)]).unwrap();
    assert_eq!((summary.flagged, summary.flag_color), (2, None));
    // red: no bits
    s.core
        .act(&[at(red), at(apple)], Action::FlagColor(pe_core::FlagColor::Red))
        .unwrap();
    assert_eq!(
        s.core.summary(&[at(red), at(apple)]).unwrap().flag_color,
        Some(pe_core::FlagColor::Red)
    );
    eventually(&|| !has(red, "$MailFlagBit0") && !has(apple, "$MailFlagBit2"));
    // the flag taken away takes its colour along
    s.core
        .act(&[at(apple)], Action::FlagColor(pe_core::FlagColor::Gray))
        .unwrap();
    s.core.act(&[at(apple)], Action::Flag(false)).unwrap();
    eventually(&|| color(apple).is_none());
    eventually(&|| !has(apple, "\\Flagged") && !has(apple, "$MailFlagBit1") && !has(apple, "$MailFlagBit2"));
}

#[test]
fn a_move_or_delete_the_server_does_not_do_comes_back() {
    let Some(s) = setup() else { return };
    let first = s.server.add_message("INBOX", &rfc822("First", "1"), &[]);
    let second = s.server.add_message("INBOX", &rfc822("Second", "2"), &[]);
    let account = s.core.add_account(&settings(&s.server), PASSWORD).unwrap();
    s.core.sync(account).unwrap();
    s.wait(|e| *e == Event::SyncFinished { account, failure: None });
    let folders = s.core.folders(account).unwrap();
    let id = |path: &str| folders.iter().find(|f| f.info.path == path).unwrap().id;
    let (inbox, archive, trash) = (id("INBOX"), id("Archive"), id("Trash"));
    let Setup {
        server,
        core,
        events,
        _dir,
    } = s;
    // the server goes away: nothing it was asked can happen
    drop(server);
    core.move_messages(inbox, &[first], archive).unwrap();
    core.delete_messages(inbox, &[second]).unwrap();
    // out of the list at once
    let mut changes = 0;
    let mut failures = 0;
    while failures < 2 || changes < 4 {
        match events.recv_timeout(Duration::from_secs(20)).expect("events") {
            Event::FolderChanged { folder, .. } if folder == inbox => changes += 1,
            Event::Failed { kind, .. } => {
                assert_ne!(kind, FailureKind::Authentication);
                failures += 1;
            }
            _ => {}
        }
    }
    // and back in once the server did not take them, not in Archive or Deleted Items
    let mut uids_now: Vec<u64> = core
        .messages(inbox, Sort::default(), 0, 10)
        .unwrap()
        .iter()
        .map(|m| m.info.uid)
        .collect();
    uids_now.sort();
    assert_eq!(uids_now, [first, second]);
    assert!(core.messages(archive, Sort::default(), 0, 10).unwrap().is_empty());
    assert!(core.messages(trash, Sort::default(), 0, 10).unwrap().is_empty());
}

#[test]
fn creates_renames_and_deletes_folders() {
    let Some(s) = setup() else { return };
    let account = s.core.add_account(&settings(&s.server), PASSWORD).unwrap();
    s.core.sync(account).unwrap();
    s.wait(|e| *e == Event::SyncFinished { account, failure: None });
    let path_of = |name: &str| {
        s.core
            .folders(account)
            .unwrap()
            .into_iter()
            .find(|f| f.info.path == name)
            .map(|f| f.id)
    };
    let archive = path_of("Archive").unwrap();

    s.core.create_folder(account, Some(archive), "2024").unwrap();
    s.wait(|e| *e == Event::FoldersChanged { account });
    let created = path_of("Archive/2024").expect("Archive/2024");

    s.core.rename_folder(created, "2025").unwrap();
    s.wait(|e| *e == Event::FoldersChanged { account });
    assert!(path_of("Archive/2024").is_none());
    let renamed = path_of("Archive/2025").expect("Archive/2025");

    s.core.delete_folder(renamed).unwrap();
    s.wait(|e| *e == Event::FoldersChanged { account });
    assert!(path_of("Archive/2025").is_none());

    // refused now, before anything goes to the server
    let inbox = path_of("INBOX").unwrap();
    let sent = path_of("Sent").unwrap();
    assert!(matches!(
        s.core.rename_folder(inbox, "Mail"),
        Err(pe_core::Error::Folder(_))
    ));
    assert!(matches!(s.core.delete_folder(sent), Err(pe_core::Error::Folder(_))));
    let refused = s.core.create_folder(account, None, "a/b").unwrap_err();
    assert!(refused.to_string().contains("\u{201c}/\u{201d}"), "{refused}");
}

#[test]
fn saves_and_imports_messages_as_files() {
    let Some(s) = setup() else { return };
    let uid = s
        .server
        .add_message("INBOX", &rfc822("Quarterly / report?", "the numbers"), &[]);
    let account = s.core.add_account(&settings(&s.server), PASSWORD).unwrap();
    s.core.sync(account).unwrap();
    s.wait(|e| *e == Event::SyncFinished { account, failure: None });
    let folders = s.core.folders(account).unwrap();
    let id = |path: &str| folders.iter().find(|f| f.info.path == path).unwrap().id;
    let (inbox, archive) = (id("INBOX"), id("Archive"));

    // not fetched yet: nothing to save
    assert!(s.core.message_source(inbox, uid).unwrap().is_none());
    s.core.open_message(inbox, uid).unwrap();
    s.wait(|e| *e == Event::MessageReady { folder: inbox, uid });
    let (name, source) = s.core.message_source(inbox, uid).unwrap().unwrap();
    // a name made safe: no path, no characters Windows refuses
    assert_eq!(name, "Quarterly - report.eml");
    // its headers for Message Properties, as text to show
    let headers = s.core.message_headers(inbox, uid).unwrap().unwrap();
    assert!(
        headers.contains("Subject: Quarterly / report?\r\n") && !headers.contains("the numbers"),
        "{headers}"
    );
    assert!(String::from_utf8_lossy(&source).contains("the numbers"));

    // back in, into another folder
    let dir = TempDir::new("eml");
    let file = dir.path().join(&name);
    std::fs::write(&file, &source).unwrap();
    s.core.import_message(archive, &file).unwrap();
    s.wait(|e| {
        *e == Event::FolderChanged {
            account,
            folder: archive,
        }
    });
    assert_eq!(s.server.subjects("Archive"), ["Quarterly / report?"]);

    // what is not a message is refused now
    let text = dir.path().join("notes.txt");
    std::fs::write(&text, "just some notes\nnothing else\n").unwrap();
    let refused = s.core.import_message(archive, &text).unwrap_err();
    assert!(refused.to_string().contains("not an e-mail message"), "{refused}");
    assert!(s.core.import_message(archive, &dir.path().join("missing.eml")).is_err());
}

#[test]
fn the_outbox_keeps_what_did_not_go() {
    let Some(s) = setup() else { return };
    // an outgoing server that is not there: the port of a listener that is closed again
    let closed = std::net::TcpListener::bind("127.0.0.1:0")
        .unwrap()
        .local_addr()
        .unwrap()
        .port();
    let mut unreachable = settings(&s.server);
    unreachable.smtp_port = closed;
    let account = s.core.add_account(&unreachable, PASSWORD).unwrap();
    let message = |subject: &str| pe_core::Outgoing {
        to: "Ann <ann@example.com>".into(),
        subject: subject.into(),
        text: "x".into(),
        ..Default::default()
    };
    // what a send that did not go says, once it waits in the Outbox
    let failure = || loop {
        if let Event::Failed { message, .. } = s.events.recv_timeout(Duration::from_secs(20)).expect("an event") {
            break message;
        }
    };

    // a send that can not go waits in the Outbox with the reason, not lost
    s.core.send(account, message("Waiting")).unwrap();
    let failed = failure();
    assert!(failed.contains("waits in the Outbox"), "{failed}");
    let queued = s.core.outbox().unwrap();
    assert_eq!(queued.len(), 1);
    assert_eq!(queued[0].subject, "Waiting");
    assert_eq!(queued[0].recipients, "Ann <ann@example.com>");
    assert!(queued[0].problem.is_some());
    assert!(s.server.subjects("INBOX").is_empty());

    // the server back: Send/Recv sends it, out of the Outbox
    s.core.update_account(account, &settings(&s.server)).unwrap();
    s.core.outbox_send().unwrap();
    s.wait(|e| matches!(e, Event::MessageSent { account: a, .. } if *a == account));
    assert!(s.core.outbox().unwrap().is_empty());
    assert_eq!(s.server.subjects("INBOX"), ["Waiting"]);

    // deleted without sending
    s.core.update_account(account, &unreachable).unwrap();
    s.core.send(account, message("Never")).unwrap();
    failure();
    let queued = s.core.outbox().unwrap();
    assert_eq!(queued.len(), 1);
    s.core.outbox_delete(queued[0].id).unwrap();
    assert!(s.core.outbox().unwrap().is_empty());
}

#[test]
fn a_message_sent_waits_and_can_be_taken_back() {
    let Some(s) = setup() else { return };
    let account = s.core.add_account(&settings(&s.server), PASSWORD).unwrap();
    s.core.sync(account).unwrap();
    s.wait(|e| *e == Event::SyncFinished { account, failure: None });
    s.core.set_send_delay(3).unwrap();
    let dir = TempDir::new("undo-send");
    let file = dir.path().join("plan.txt");
    std::fs::write(&file, "the plan").unwrap();
    let message = |subject: &str| pe_core::Outgoing {
        to: "Ann <ann@example.com>".into(),
        subject: subject.into(),
        html: Some("<p>Second thoughts</p>".into()),
        attachments: vec![file.clone()],
        ..Default::default()
    };

    // sent: it waits, and Edit > Undo says it takes the send back
    s.core.send(account, message("Taken back")).unwrap();
    let waiting = s.wait(|e| matches!(e, Event::SendWaiting { .. }));
    assert_eq!(
        waiting,
        Event::SendWaiting {
            account,
            subject: "Taken back".into(),
            seconds: 3
        }
    );
    eventually(
        || s.core.outbox().unwrap().len() == 1,
        "the message waits in the Outbox",
    );
    assert!(s.core.undo_is_send());
    assert_eq!(s.core.undo_label().as_deref(), Some("Undo Send"));
    assert!(
        s.core
            .send_waiting_text()
            .unwrap()
            .starts_with("Sending “Taken back” in "),
        "the status bar counts down"
    );
    let (taken, said) = s.core.undo_send().unwrap();
    assert_eq!(said, "“Taken back” was not sent. It is open again.");
    let (from, draft) = taken.unwrap();
    assert_eq!(from, account);
    assert_eq!(
        (draft.to.as_str(), draft.subject.as_str()),
        ("Ann <ann@example.com>", "Taken back")
    );
    assert!(draft.body.contains("Second thoughts"), "{}", draft.body);
    assert!(draft.message_id.is_some());
    assert_eq!(draft.attachments.len(), 1);
    assert_eq!(std::fs::read(&draft.attachments[0]).unwrap(), b"the plan");
    assert!(s.core.outbox().unwrap().is_empty());
    assert!(!s.core.undo_is_send());
    // taken back, it never goes
    std::thread::sleep(std::time::Duration::from_secs(4));
    s.core.sync(account).unwrap();
    s.wait(|e| *e == Event::SyncFinished { account, failure: None });
    assert!(s.server.subjects("INBOX").is_empty());

    // not taken back: it goes once its time came, and then it is too late
    s.core.send(account, message("Let go")).unwrap();
    s.wait(|e| matches!(e, Event::SendWaiting { .. }));
    assert!(s.server.subjects("INBOX").is_empty(), "nothing goes before its time");
    s.wait(|e| matches!(e, Event::MessageSent { account: a, .. } if *a == account));
    assert_eq!(s.server.subjects("INBOX"), ["Let go"]);
    let (taken, said) = s.core.undo_send().unwrap();
    assert!(taken.is_none() && said == "“Let go” was already sent.", "{said}");
    assert!(s.core.send_waiting_text().is_none());

    // one more that waits
    s.core.send(account, message("Moved after")).unwrap();
    s.wait(|e| matches!(e, Event::SendWaiting { .. }));
    assert!(s.core.undo_is_send());
    s.core.set_send_delay(0).unwrap();

    // quitting sends what waits at once
    s.core.send_waiting_now().unwrap();
    s.wait(|e| matches!(e, Event::MessageSent { subject, .. } if subject == "Moved after"));
    assert!(!s.core.undo_is_send());
}

#[test]
fn a_message_goes_from_another_address_of_the_account() {
    let Some(s) = setup() else { return };
    let account = s.core.add_account(&settings(&s.server), PASSWORD).unwrap();
    s.core.sync(account).unwrap();
    s.wait(|e| *e == Event::SyncFinished { account, failure: None });
    s.core
        .set_account_addresses_text(account, "Sales Desk <sales@example.com>\n\nalias@example.org")
        .unwrap();
    assert_eq!(
        s.core.account_addresses_text(account).unwrap(),
        "Sales Desk <sales@example.com>, alias@example.org"
    );
    assert!(s.core.set_account_addresses_text(account, "not an address").is_err());
    let choices = s.core.from_choices().unwrap();
    assert_eq!(choices.len(), 3);
    assert_eq!(choices[1].1.as_deref(), Some("sales@example.com"));
    assert!(
        choices[1].2.starts_with("Sales Desk <sales@example.com>"),
        "{}",
        choices[1].2
    );

    // sent as the other address: its From and its name
    let outgoing = pe_core::Outgoing {
        to: "Ann <ann@example.com>".into(),
        subject: "From the sales desk".into(),
        text: "Prices attached.".into(),
        from: Some("sales@example.com".into()),
        ..Default::default()
    };
    s.core.send(account, outgoing.clone()).unwrap();
    s.wait(|e| matches!(e, Event::MessageSent { .. }));
    let sent = pe_testkit::raw_text(&s.server.messages("INBOX")[0]);
    assert!(sent.contains("From: Sales Desk <sales@example.com>"), "{sent}");

    // someone else's address is refused while the message is open
    let forged = pe_core::Outgoing {
        from: Some("ceo@example.com".into()),
        ..outgoing
    };
    assert!(s.core.send(account, forged.clone()).is_err());
    assert!(s.core.save_draft(account, forged).is_err());

    // a reply to a message sent to the other address goes from it
    s.server.add_message(
        "INBOX",
        "From: Bob <bob@example.com>\r\nTo: sales@example.com\r\nSubject: Quote\r\nMessage-ID: <q@example.com>\r\n\r\nA quote please.\r\n",
        &[],
    );
    s.core.sync(account).unwrap();
    s.wait(|e| *e == Event::SyncFinished { account, failure: None });
    let inbox = s
        .core
        .folders(account)
        .unwrap()
        .into_iter()
        .find(|f| f.info.path == "INBOX")
        .unwrap()
        .id;
    let uid = s
        .server
        .messages("INBOX")
        .iter()
        .find(|m| pe_testkit::raw_text(m).contains("Subject: Quote"))
        .unwrap()["uid"]
        .as_u64()
        .unwrap();
    s.core.open_message(inbox, uid).unwrap();
    s.wait(|e| *e == Event::MessageReady { folder: inbox, uid });
    let reply = s.core.draft(inbox, uid, pe_core::DraftKind::Reply).unwrap().unwrap();
    assert_eq!(reply.from.as_deref(), Some("sales@example.com"));
}

#[test]
fn drafts_are_saved_reopened_and_gone_once_sent() {
    let Some(s) = setup() else { return };
    let account = s.core.add_account(&settings(&s.server), PASSWORD).unwrap();
    s.core.sync(account).unwrap();
    s.wait(|e| *e == Event::SyncFinished { account, failure: None });
    let drafts = s
        .core
        .folders(account)
        .unwrap()
        .into_iter()
        .find(|f| f.info.path == "Drafts")
        .unwrap()
        .id;
    let changed = |e: &Event| {
        *e == Event::FolderChanged {
            account,
            folder: drafts,
        }
    };
    let dir = TempDir::new("draft");
    let file = dir.path().join("plan.txt");
    std::fs::write(&file, "the plan").unwrap();

    // half written: no recipients yet, an address half typed in Bcc
    let mut outgoing = pe_core::Outgoing {
        bcc: "Boss <boss@example.com>".into(),
        subject: "Plans".into(),
        html: Some("<p>first <b>try</b></p>".into()),
        attachments: vec![file.clone()],
        ..Default::default()
    };
    let message_id = s.core.save_draft(account, outgoing.clone()).unwrap();
    // the window that saved it is told once the server has it
    let saved = s.wait(|e| matches!(e, Event::DraftSaved { .. }));
    assert_eq!(
        saved,
        Event::DraftSaved {
            account,
            message_id: message_id.clone(),
            problem: None
        }
    );
    s.wait(changed);
    assert_eq!(s.server.subjects("Drafts"), ["Plans"]);
    let first = s.server.messages("Drafts")[0]["uid"].as_u64().unwrap();
    assert!(s.server.flags("Drafts", first).contains(&"\\Draft".to_string()));

    // saved again: the new copy in place of the old
    outgoing.message_id = Some(message_id.clone());
    outgoing.to = "Ann <ann@example.com>".into();
    outgoing.html = Some("<p>second <b>try</b></p>".into());
    assert_eq!(s.core.save_draft(account, outgoing.clone()).unwrap(), message_id);
    s.wait(changed);
    let saved = s.server.messages("Drafts");
    assert_eq!(saved.len(), 1, "{saved:?}");
    let uid = saved[0]["uid"].as_u64().unwrap();
    assert_ne!(uid, first);

    // opened again: where it was left, with its file and its Bcc
    s.core.open_message(drafts, uid).unwrap();
    s.wait(|e| *e == Event::MessageReady { folder: drafts, uid });
    let draft = s.core.reopen_draft(drafts, uid).unwrap().unwrap();
    assert_eq!(
        (draft.to.as_str(), draft.bcc.as_str(), draft.subject.as_str()),
        ("Ann <ann@example.com>", "Boss <boss@example.com>", "Plans")
    );
    assert!(draft.body.contains("second <b>try</b>"), "{}", draft.body);
    assert_eq!(draft.message_id.as_deref(), Some(message_id.as_str()));
    assert_eq!(draft.attachments.len(), 1);
    assert!(draft.attachments[0].ends_with("plan.txt"));
    assert_eq!(std::fs::read(&draft.attachments[0]).unwrap(), b"the plan");

    // saved once more as it was opened, then sent right away: the draft goes
    let reopened = pe_core::Outgoing {
        to: draft.to,
        bcc: draft.bcc,
        subject: draft.subject,
        html: Some(draft.body + "<p>done</p>"),
        attachments: draft.attachments,
        message_id: draft.message_id,
        ..Default::default()
    };
    s.core.save_draft(account, reopened.clone()).unwrap();
    s.core.send(account, reopened).unwrap();
    s.wait(|e| matches!(e, Event::MessageSent { account: a, .. } if *a == account));
    // the drafts go through the uploader's queue, after the save of theirs
    eventually(
        || s.server.subjects("Drafts").is_empty(),
        "the drafts gone once it is sent",
    );
    assert_eq!(s.server.subjects("INBOX"), ["Plans"]);
    let sent = pe_testkit::raw_text(&s.server.messages("INBOX")[0]);
    // the Bcc of the draft is not in what was sent
    assert!(
        !sent.contains("Bcc:") && sent.contains(&format!("Message-ID: {message_id}")),
        "{sent}"
    );
}

#[test]
fn drafts_saved_automatically_are_kept_for_a_crash_and_discarded() {
    let Some(s) = setup() else { return };
    let account = s.core.add_account(&settings(&s.server), PASSWORD).unwrap();
    s.core.sync(account).unwrap();
    s.wait(|e| *e == Event::SyncFinished { account, failure: None });
    let dir = TempDir::new("autosave");
    let file = dir.path().join("notes.txt");
    std::fs::write(&file, "notes").unwrap();
    let gone = dir.path().join("gone.txt");
    std::fs::write(&gone, "soon gone").unwrap();

    // saved without being asked: in Drafts as a saved draft is, and kept here for a crash
    let mut outgoing = pe_core::Outgoing {
        to: "Ann <ann@example.com>".into(),
        subject: "Half written".into(),
        html: Some("<p>so far</p>".into()),
        attachments: vec![file.clone(), gone.clone()],
        ..Default::default()
    };
    let message_id = s.core.autosave_draft(account, outgoing.clone()).unwrap();
    let saved = s.wait(|e| matches!(e, Event::DraftSaved { .. }));
    assert_eq!(
        saved,
        Event::DraftSaved {
            account,
            message_id: message_id.clone(),
            problem: None
        }
    );
    eventually(
        || s.server.subjects("Drafts") == ["Half written"],
        "the draft in Drafts",
    );

    // saved again: one copy there, the newest, and here
    outgoing.message_id = Some(message_id.clone());
    outgoing.html = Some("<p>so far, and more</p>".into());
    assert_eq!(s.core.autosave_draft(account, outgoing.clone()).unwrap(), message_id);
    s.wait(|e| matches!(e, Event::DraftSaved { .. }));
    eventually(|| s.server.messages("Drafts").len() == 1, "one draft");

    // the app ended without closing the window: the message opens again as it was last saved, with the files
    // that are still there
    std::fs::remove_file(&gone).unwrap();
    let recovered = s.core.recovered().unwrap();
    assert_eq!(recovered.len(), 1);
    let (from, draft) = &recovered[0];
    assert_eq!(*from, account);
    assert_eq!(
        (draft.to.as_str(), draft.subject.as_str()),
        ("Ann <ann@example.com>", "Half written")
    );
    assert!(draft.body.contains("so far, and more"), "{}", draft.body);
    assert_eq!(draft.message_id.as_deref(), Some(message_id.as_str()));
    assert_eq!(draft.attachments, std::slice::from_ref(&file));

    // its window closed: nothing left to open again, the draft stays in Drafts
    s.core.compose_closed(&message_id).unwrap();
    assert!(s.core.recovered().unwrap().is_empty());
    assert_eq!(s.server.subjects("Drafts"), ["Half written"]);

    // closed without saving: the copy only the automatic saving made goes from Drafts too
    s.core.autosave_draft(account, outgoing.clone()).unwrap();
    s.wait(|e| matches!(e, Event::DraftSaved { .. }));
    s.core.discard_draft(account, &message_id).unwrap();
    eventually(|| s.server.subjects("Drafts").is_empty(), "the draft discarded");
    assert!(s.core.recovered().unwrap().is_empty());
}

#[test]
fn a_draft_follows_from_to_another_account() {
    let Some(s) = setup() else { return };
    // a second account on a server of its own (ImapKit has one mailbox a server)
    let Some(other_server) = ImapKit::start(json!({})) else {
        return;
    };
    let first = s.core.add_account(&settings(&s.server), PASSWORD).unwrap();
    let second = s.core.add_account(&settings(&other_server), PASSWORD).unwrap();
    for account in [first, second] {
        s.core.sync(account).unwrap();
        s.wait(|e| *e == Event::SyncFinished { account, failure: None });
    }
    let drafts_of = |account| {
        s.core
            .folders(account)
            .unwrap()
            .into_iter()
            .find(|f| f.info.path == "Drafts")
            .unwrap()
            .id
    };
    let (first_drafts, second_drafts) = (drafts_of(first), drafts_of(second));
    let mut outgoing = pe_core::Outgoing {
        subject: "Changing hands".into(),
        text: "x".into(),
        ..Default::default()
    };
    let message_id = s.core.save_draft(first, outgoing.clone()).unwrap();
    s.wait(|e| {
        *e == Event::FolderChanged {
            account: first,
            folder: first_drafts,
        }
    });
    assert_eq!(s.server.subjects("Drafts"), ["Changing hands"]);

    // From changed to the second account, then saved: the copy moves, the first account's Drafts is empty once the
    // second one has it
    outgoing.message_id = Some(message_id);
    outgoing.draft_account = Some(first);
    s.core.save_draft(second, outgoing.clone()).unwrap();
    s.wait(|e| {
        *e == Event::FolderChanged {
            account: second,
            folder: second_drafts,
        }
    });
    assert_eq!(other_server.subjects("Drafts"), ["Changing hands"]);
    assert!(s.server.subjects("Drafts").is_empty());

    // a save that fails at the server (the first account's server is gone) leaves the copy where it is: it is never
    // in neither Drafts
    let Setup {
        server, core, events, ..
    } = s;
    drop(server);
    outgoing.draft_account = Some(second);
    core.save_draft(first, outgoing.clone()).unwrap();
    loop {
        let event = events
            .recv_timeout(Duration::from_secs(20))
            .expect("the failed save is told");
        if matches!(event, Event::Failed { account, .. } if account == first) {
            break;
        }
    }
    assert_eq!(other_server.subjects("Drafts"), ["Changing hands"]);
}

/// With the app's setting on, a fresh message with a code, from a domain the provider says signed it, is announced
/// with its code first; an unsigned one is announced as any other
#[test]
fn new_mail_names_its_code_when_asked() {
    let Some(s) = setup() else { return };
    let account = s.core.add_account(&settings(&s.server), PASSWORD).unwrap();
    s.core.sync(account).unwrap();
    s.wait(|e| *e == Event::SyncFinished { account, failure: None });
    pe_core::otp::set_in_notifications(true);
    let date = pe_smtp::message::format_date(
        std::time::SystemTime::now()
            .duration_since(std::time::UNIX_EPOCH)
            .unwrap()
            .as_secs() as i64,
    );
    let code_mail = |verdict: &str, digits: &str| {
        format!(
            "{verdict}From: Example Accounts <no-reply@accounts.example.com>\r\nTo: testuser@inboxclassic.test\r\n\
             Subject: Your sign-in code\r\nDate: {date}\r\nContent-Type: text/plain; charset=utf-8\r\n\r\n\
             Hello,\r\n\r\nYour verification code is {digits}.\r\n\r\nIt expires in 10 minutes. If you did not ask for it, \
             ignore this email.\r\n"
        )
    };
    let text_of = |event: Event| match event {
        Event::NewMail { text, .. } => text,
        _ => unreachable!(),
    };
    s.server.add_message(
        "INBOX",
        // the provider of the test account is example.com: its verdict counts
        &code_mail(
            "Authentication-Results: mx.example.com; dkim=pass header.d=example.com\r\n",
            "482913",
        ),
        &[],
    );
    let text = text_of(s.wait(|e| matches!(e, Event::NewMail { .. })));
    assert!(
        text.starts_with("482913 is your code for accounts.example.com\n"),
        "{text}"
    );
    s.server.add_message("INBOX", &code_mail("", "771204"), &[]);
    let text = text_of(s.wait(|e| matches!(e, Event::NewMail { .. })));
    assert!(!text.contains("771204") && !text.contains("is your code"), "{text}");
    pe_core::otp::set_in_notifications(false);
}

#[test]
fn new_mail_comes_in_while_watching_the_inbox() {
    let Some(s) = setup() else { return };
    s.server.add_message("INBOX", &rfc822("Already there", "1"), &[]);
    let account = s.core.add_account(&settings(&s.server), PASSWORD).unwrap();
    s.core.sync(account).unwrap();
    s.wait(|e| *e == Event::SyncFinished { account, failure: None });
    // what was there with the first sync is not new
    // mail that arrives later is, without another sync: the worker watches the Inbox (IDLE)
    s.server.add_message(
        "INBOX",
        "From: Nora Example <nora@example.com>\r\nSubject: Fresh\r\n\r\nJust in.\r\n",
        &[],
    );
    let event = s.wait(|e| matches!(e, Event::NewMail { .. }));
    let Event::NewMail {
        account: from_account,
        count,
        from,
        subject,
        ..
    } = event
    else {
        unreachable!()
    };
    assert_eq!((from_account, count), (account, 1));
    assert_eq!((from.as_str(), subject.as_str()), ("Nora Example", "Fresh"));
    // and it is in the list
    let inbox = s
        .core
        .folders(account)
        .unwrap()
        .into_iter()
        .find(|f| f.info.path == "INBOX")
        .unwrap();
    let subjects: Vec<String> = s
        .core
        .messages(inbox.id, Sort::default(), 0, 10)
        .unwrap()
        .into_iter()
        .map(|m| m.info.subject)
        .collect();
    assert!(subjects.contains(&"Fresh".to_string()), "{subjects:?}");
    // mail that comes already read is not announced: the next event of the Inbox is no NewMail
    s.server
        .add_message("INBOX", &rfc822("Read elsewhere", "2"), &["\\Seen"]);
    let next = s.wait(|e| matches!(e, Event::NewMail { .. } | Event::FolderChanged { .. }));
    assert!(matches!(next, Event::FolderChanged { .. }), "{next:?}");
}

/// A message with its own Message-ID that answers `answers` (none for the start of a conversation)
fn in_conversation(subject: &str, id: &str, answers: &[&str]) -> String {
    let references = if answers.is_empty() {
        String::new()
    } else {
        let ids: Vec<String> = answers.iter().map(|a| format!("<{a}>")).collect();
        format!(
            "In-Reply-To: {}\r\nReferences: {}\r\n",
            ids.last().unwrap(),
            ids.join(" ")
        )
    };
    format!(
        "From: Nora Example <nora@example.com>\r\nSubject: {subject}\r\nMessage-ID: <{id}>\r\n{references}\r\nHi\r\n"
    )
}

#[test]
fn ignored_conversations_arrive_read_and_watched_ones_are_announced() {
    let Some(s) = setup_with(json!({ "storage": {
        "INBOX": {},
        "": { "separator": "/", "folders": {
            "Lists": {},
            "Sent": { "special-use": "\\Sent" }
        } }
    } })) else {
        return;
    };
    s.server
        .add_message("INBOX", &in_conversation("Noisy", "noisy@x", &[]), &["\\Seen"]);
    s.server
        .add_message("INBOX", &in_conversation("Noisy again", "noisy2@x", &["noisy@x"]), &[]);
    s.server
        .add_message("Lists", &in_conversation("Release plan", "plan@x", &[]), &["\\Seen"]);
    let account = s.core.add_account(&settings(&s.server), PASSWORD).unwrap();
    s.core.sync(account).unwrap();
    s.wait(|e| *e == Event::SyncFinished { account, failure: None });
    let folder = |path: &str| {
        s.core
            .folders(account)
            .unwrap()
            .into_iter()
            .find(|f| f.info.path == path)
            .unwrap()
            .id
    };
    let (inbox, lists) = (folder("INBOX"), folder("Lists"));
    let uid_of = |folder, subject: &str| {
        s.core
            .messages(folder, Sort::default(), 0, 50)
            .unwrap()
            .into_iter()
            .find(|m| m.info.subject == subject)
            .map(|m| m.info.uid)
    };

    // Ignore Conversation: its unread message is read at once, on the server too
    let noisy = MessageRef {
        folder: inbox,
        uid: uid_of(inbox, "Noisy").unwrap(),
    };
    s.core.act(&[noisy], Action::Ignore).unwrap();
    assert!(s.core.summary(&[noisy]).unwrap().ignored);
    let again = uid_of(inbox, "Noisy again").unwrap();
    eventually(
        || s.server.flags("INBOX", again).iter().any(|f| f == "\\Seen"),
        "the ignored conversation's unread message read on the server",
    );
    // Watch Conversation on the list's message
    let plan = MessageRef {
        folder: lists,
        uid: uid_of(lists, "Release plan").unwrap(),
    };
    s.core.act(&[plan], Action::Watch).unwrap();
    assert!(s.core.summary(&[plan]).unwrap().watched);

    // a reply in the ignored conversation arrives read and unannounced: the next announcement is of mail after it
    let reply = s.server.add_message(
        "INBOX",
        &in_conversation("Re: Noisy", "noisy3@x", &["noisy@x", "noisy2@x"]),
        &[],
    );
    eventually(
        || s.server.flags("INBOX", reply).iter().any(|f| f == "\\Seen"),
        "the reply in the ignored conversation read on the server",
    );
    s.server
        .add_message("INBOX", &in_conversation("Lunch?", "lunch@x", &[]), &[]);
    let event = s.wait(|e| matches!(e, Event::NewMail { .. }));
    let Event::NewMail {
        count,
        subject,
        watched,
        ..
    } = event
    else {
        unreachable!()
    };
    assert_eq!((count, subject.as_str(), watched), (1, "Lunch?", false));
    let stored = s.core.message(inbox, reply).unwrap().unwrap();
    assert!(stored.info.seen() && stored.mark == pe_core::ThreadMark::Ignore);

    // a reply in the watched conversation is announced from a folder of the user's too
    s.server.add_message(
        "Lists",
        &in_conversation("Re: Release plan", "plan2@x", &["plan@x"]),
        &[],
    );
    s.core.sync(account).unwrap();
    let event = s.wait(|e| matches!(e, Event::NewMail { .. }));
    let Event::NewMail {
        folder,
        subject,
        watched,
        title,
        text,
        ..
    } = event
    else {
        unreachable!()
    };
    assert_eq!((folder, subject.as_str(), watched), (lists, "Re: Release plan", true));
    // the notification's words, made by the core for every app
    assert_eq!(title, "Watched conversation");
    assert!(text.ends_with("\nRe: Release plan"), "{text}");

    // hidden from a list that hides ignored conversations
    let hidden = Search {
        hide_ignored: true,
        ..Search::folder(inbox)
    };
    let shown: Vec<String> = s
        .core
        .search(&hidden, Sort::default(), 0, 50)
        .unwrap()
        .into_iter()
        .map(|m| m.info.subject)
        .collect();
    assert_eq!(shown, ["Lunch?"]);
    // the status bar counts what the list shows: the folder's own counts, or what is left with ignored ones hidden
    let folder = s.core.folder(inbox).unwrap();
    assert_eq!(
        s.core.list_counts(&Search::folder(inbox)).unwrap(),
        (folder.total, folder.unread)
    );
    assert_eq!(s.core.list_counts(&hidden).unwrap(), (1, 1));
}

#[test]
fn unsubscribes_with_one_click() {
    let Some(s) = setup() else { return };
    // the list's server: one request, answered 200, kept for the test to read
    let listener = std::net::TcpListener::bind("127.0.0.1:0").unwrap();
    let port = listener.local_addr().unwrap().port();
    let server = std::thread::spawn(move || {
        use std::io::{Read, Write};
        let (mut stream, _) = listener.accept().unwrap();
        stream.set_read_timeout(Some(Duration::from_secs(10))).unwrap();
        let mut request = Vec::new();
        let mut buffer = [0u8; 4096];
        while !String::from_utf8_lossy(&request).contains("One-Click") {
            let read = stream.read(&mut buffer).unwrap();
            if read == 0 {
                break;
            }
            request.extend_from_slice(&buffer[..read]);
        }
        stream
            .write_all(b"HTTP/1.0 200 OK\r\nContent-Length: 2\r\n\r\nok")
            .unwrap();
        String::from_utf8_lossy(&request).into_owned()
    });
    let raw = format!(
        "Authentication-Results: mx.example.com; dkim=pass header.d=list.example.com\r\n\
         DKIM-Signature: v=1; d=list.example.com; s=s1; h=from:list-unsubscribe:list-unsubscribe-post; bh=x; b=y\r\n\
         From: News <news@list.example.com>\r\nSubject: Weekly news\r\n\
         List-Unsubscribe: <mailto:leave@list.example.com>, <http://127.0.0.1:{port}/u/42>\r\n\
         List-Unsubscribe-Post: List-Unsubscribe=One-Click\r\n\r\nThe news.\r\n"
    );
    let uid = s.server.add_message("INBOX", &raw, &[]);
    let account = s.core.add_account(&settings(&s.server), PASSWORD).unwrap();
    s.core.sync(account).unwrap();
    s.wait(|e| *e == Event::SyncFinished { account, failure: None });
    let inbox = s
        .core
        .folders(account)
        .unwrap()
        .into_iter()
        .find(|f| f.info.path == "INBOX")
        .unwrap()
        .id;
    // read once the message is opened: its source is in the store then
    assert!(s.core.unsubscribe(inbox, uid).is_err());
    s.core.open_message(inbox, uid).unwrap();
    s.wait(|e| *e == Event::MessageReady { folder: inbox, uid });
    let view = s.core.message_view(inbox, uid, false).unwrap().unwrap();
    assert!(
        matches!(&view.unsubscribe, Some(pe_core::unsubscribe::Unsubscribe::OneClick { url }) if url.ends_with("/u/42")),
        "{:?}",
        view.unsubscribe
    );
    let request = s.core.unsubscribe(inbox, uid).unwrap();
    let done = s.wait(|e| matches!(e, Event::Unsubscribed { .. }));
    assert_eq!(done, Event::Unsubscribed { request, problem: None });
    let sent = server.join().unwrap();
    assert!(sent.starts_with("POST /u/42 "), "{sent}");
    assert!(sent.contains("List-Unsubscribe=One-Click"), "{sent}");
    assert!(!sent.to_ascii_lowercase().contains("cookie"), "{sent}");
}

#[test]
fn shows_a_calendar_invitation() {
    let Some(s) = setup() else { return };
    let raw = "From: Ann <ann@example.com>\r\nSubject: Invitation: Planning\r\n\
        Content-Type: multipart/mixed; boundary=b\r\n\r\n--b\r\nContent-Type: text/plain\r\n\r\nSee you there.\r\n\
        --b\r\nContent-Type: text/calendar; method=REQUEST; charset=utf-8\r\n\r\n\
        BEGIN:VCALENDAR\r\nMETHOD:REQUEST\r\nBEGIN:VEVENT\r\nUID:p1@example.com\r\nSUMMARY:Planning\r\n\
        DTSTART:20261201T100000Z\r\nDTEND:20261201T110000Z\r\nLOCATION:Room 2\r\n\
        ORGANIZER;CN=Ann:mailto:ann@example.com\r\nEND:VEVENT\r\nEND:VCALENDAR\r\n--b--\r\n";
    let uid = s.server.add_message("INBOX", raw, &[]);
    let account = s.core.add_account(&settings(&s.server), PASSWORD).unwrap();
    s.core.sync(account).unwrap();
    s.wait(|e| *e == Event::SyncFinished { account, failure: None });
    let inbox = s
        .core
        .folders(account)
        .unwrap()
        .into_iter()
        .find(|f| f.info.path == "INBOX")
        .unwrap()
        .id;
    s.core.open_message(inbox, uid).unwrap();
    s.wait(|e| *e == Event::MessageReady { folder: inbox, uid });
    let view = s.core.message_view(inbox, uid, false).unwrap().unwrap();
    let invitation = view.invitation.expect("an invitation");
    assert_eq!(
        (invitation.summary.as_str(), invitation.location.as_str()),
        ("Planning", "Room 2")
    );
    assert_eq!(invitation.end.unwrap() - invitation.start.unwrap(), 3600);
    // the calendar part on its own, for the calendar program
    let dir = TempDir::new("calendar");
    let path = s.core.invitation_file(inbox, uid, dir.path()).unwrap().unwrap();
    assert_eq!(path.file_name().unwrap(), "invitation.ics");
    let written = std::fs::read_to_string(&path).unwrap();
    assert!(
        written.starts_with("BEGIN:VCALENDAR") && written.contains("SUMMARY:Planning"),
        "{written}"
    );
    // a message without one has none
    assert!(s.core.invitation_file(inbox, 999, dir.path()).unwrap().is_none());
}

#[test]
fn draws_a_bimi_logo_from_its_location() {
    let Some(s) = setup() else { return };
    let svg = "<svg xmlns=\"http://www.w3.org/2000/svg\" version=\"1.2\" baseProfile=\"tiny-ps\" viewBox=\"0 0 10 10\">\
               <title>Brand</title><rect width=\"10\" height=\"10\" fill=\"#0000ff\"/></svg>";
    // the brand's server: answers each request with the logo, counting them
    let listener = std::net::TcpListener::bind("127.0.0.1:0").unwrap();
    let port = listener.local_addr().unwrap().port();
    let served = std::sync::Arc::new(std::sync::atomic::AtomicUsize::new(0));
    let count = served.clone();
    let body = svg.to_string();
    std::thread::spawn(move || {
        use std::io::{Read, Write};
        for stream in listener.incoming() {
            let Ok(mut stream) = stream else { break };
            let mut buffer = [0u8; 2048];
            let _ = stream.read(&mut buffer);
            count.fetch_add(1, std::sync::atomic::Ordering::Relaxed);
            let answer = format!(
                "HTTP/1.0 200 OK\r\nContent-Type: image/svg+xml\r\nContent-Length: {}\r\n\r\n{body}",
                body.len()
            );
            let _ = stream.write_all(answer.as_bytes());
        }
    });
    let raw = format!(
        "Authentication-Results: mx.example.com; dmarc=pass header.from=brand.example; bimi=pass header.d=brand.example\r\n\
         BIMI-Location: v=BIMI1; l=http://127.0.0.1:{port}/logo.svg\r\nFrom: Brand <hello@brand.example>\r\nSubject: Hello\r\n\r\nHi.\r\n"
    );
    let uid = s.server.add_message("INBOX", &raw, &[]);
    let plain = s.server.add_message("INBOX", &rfc822("No logo", "x"), &[]);
    let account = s.core.add_account(&settings(&s.server), PASSWORD).unwrap();
    s.core.sync(account).unwrap();
    s.wait(|e| *e == Event::SyncFinished { account, failure: None });
    let inbox = s
        .core
        .folders(account)
        .unwrap()
        .into_iter()
        .find(|f| f.info.path == "INBOX")
        .unwrap()
        .id;
    for message in [uid, plain] {
        s.core.open_message(inbox, message).unwrap();
        s.wait(|e| {
            *e == Event::MessageReady {
                folder: inbox,
                uid: message,
            }
        });
    }
    assert!(s.core.message_view(inbox, uid, false).unwrap().unwrap().has_logo);
    assert!(!s.core.message_view(inbox, plain, false).unwrap().unwrap().has_logo);
    assert!(s.core.logo_start(inbox, plain, 32).is_err());
    // drawn twice, fetched once
    for _ in 0..2 {
        let request = s.core.logo_start(inbox, uid, 32).unwrap();
        s.wait(|e| *e == Event::LogoReady { request });
        let pixels = s.core.logo_result(request).expect("the logo");
        assert_eq!(pixels.len(), 32 * 32 * 4);
        // blue, BGRA
        assert_eq!(&pixels[(16 * 32 + 16) * 4..][..4], &[255, 0, 0, 255]);
    }
    assert_eq!(served.load(std::sync::atomic::Ordering::Relaxed), 1);
}

/// The list's pictures: a message whose provider passed the brand's logo gets the logo's key from the verdicts fetched
/// with the summary (without opening it), downloaded once however often it is drawn; another has its sender's
/// initials
#[test]
fn rows_get_their_senders_pictures() {
    let Some(s) = setup() else { return };
    let svg = "<svg xmlns=\"http://www.w3.org/2000/svg\" version=\"1.2\" baseProfile=\"tiny-ps\" viewBox=\"0 0 10 10\">\
               <title>Brand</title><rect width=\"10\" height=\"10\" fill=\"#00ff00\"/></svg>";
    let listener = std::net::TcpListener::bind("127.0.0.1:0").unwrap();
    let port = listener.local_addr().unwrap().port();
    let served = std::sync::Arc::new(std::sync::atomic::AtomicUsize::new(0));
    let count = served.clone();
    let body = svg.to_string();
    std::thread::spawn(move || {
        use std::io::{Read, Write};
        for stream in listener.incoming() {
            let Ok(mut stream) = stream else { break };
            let mut buffer = [0u8; 2048];
            let _ = stream.read(&mut buffer);
            count.fetch_add(1, std::sync::atomic::Ordering::Relaxed);
            let answer = format!(
                "HTTP/1.0 200 OK\r\nContent-Type: image/svg+xml\r\nContent-Length: {}\r\n\r\n{body}",
                body.len()
            );
            let _ = stream.write_all(answer.as_bytes());
        }
    });
    let raw = format!(
        "Authentication-Results: mx.example.com; dmarc=pass header.from=brand.example; bimi=pass header.d=brand.example\r\n\
         BIMI-Location: v=BIMI1; l=http://127.0.0.1:{port}/logo.svg\r\nFrom: Brand <hello@brand.example>\r\n\
         Subject: With a logo\r\n\r\nHi.\r\n"
    );
    s.server.add_message("INBOX", &raw, &[]);
    s.server.add_message("INBOX", &rfc822("No logo", "x"), &[]);
    // a forged one: the provider says the brand's domain failed
    let forged = format!(
        "Authentication-Results: mx.example.com; dmarc=fail header.from=brand.example; bimi=fail\r\n\
         BIMI-Location: v=BIMI1; l=http://127.0.0.1:{port}/logo.svg\r\nFrom: Brand <hello@brand.example>\r\n\
         Subject: Forged\r\n\r\nHi.\r\n"
    );
    s.server.add_message("INBOX", &forged, &[]);
    let account = s.core.add_account(&settings(&s.server), PASSWORD).unwrap();
    s.core.sync(account).unwrap();
    s.wait(|e| *e == Event::SyncFinished { account, failure: None });
    let inbox = s
        .core
        .folders(account)
        .unwrap()
        .into_iter()
        .find(|f| f.info.path == "INBOX")
        .unwrap()
        .id;
    let row = |subject: &str| {
        s.core
            .messages(inbox, Sort::default(), 0, 10)
            .unwrap()
            .into_iter()
            .find(|m| m.info.subject == subject)
            .unwrap()
    };
    // the background worker reads the verdicts after the sync
    let deadline = std::time::Instant::now() + Duration::from_secs(20);
    while row("With a logo").logo.is_none() {
        assert!(std::time::Instant::now() < deadline, "no logo on the row");
        std::thread::sleep(Duration::from_millis(100));
    }
    let (kind, key) = pe_core::senders::picture(&row("With a logo"));
    assert_eq!(kind, pe_core::senders::PictureKind::Logo);
    assert_ne!(key, 0);
    assert_ne!(row("With a logo").sender_auth & pe_core::senders::LOGO, 0);
    for subject in ["No logo", "Forged"] {
        assert_eq!(
            pe_core::senders::picture(&row(subject)).0,
            pe_core::senders::PictureKind::None,
            "{subject}"
        );
    }
    let plain = row("No logo");
    assert!(!pe_core::initials(&plain.info.from_name, &plain.info.from_address).is_empty());
    assert!(s.core.picture_start(0, 32).is_err());
    // drawn twice, downloaded once, and nothing was downloaded before it was drawn
    assert_eq!(served.load(std::sync::atomic::Ordering::Relaxed), 0);
    for _ in 0..2 {
        let request = s.core.picture_start(key, 32).unwrap();
        s.wait(|e| *e == Event::PictureReady { request });
        let pixels = s.core.picture_result(request).expect("the logo");
        assert_eq!(pixels.len(), 32 * 32 * 4);
        // green, BGRA
        assert_eq!(&pixels[(16 * 32 + 16) * 4..][..4], &[0, 255, 0, 255]);
    }
    assert_eq!(served.load(std::sync::atomic::Ordering::Relaxed), 1);
}

/// A contact's picture: the Address Book's card with a picture shows it on the rows of a sender the provider
/// confirmed, and in the reading pane where a logo would be; a forged message from the same address gets the initials
#[test]
fn rows_of_a_confirmed_contact_get_its_picture() {
    let Some(s) = setup() else { return };
    let confirmed = "Authentication-Results: mx.example.com; dmarc=pass header.from=friend.example\r\n\
                     From: Fay Friend <fay@friend.example>\r\nSubject: Confirmed\r\n\r\nHi.\r\n";
    let forged = "Authentication-Results: mx.example.com; dmarc=fail header.from=friend.example\r\n\
                  From: Fay Friend <fay@friend.example>\r\nSubject: Forged\r\n\r\nHi.\r\n";
    // a provider that gives no verdict of its own (as Microsoft's, without an authserv-id): anyone could write it
    let unjudged = "Authentication-Results: dkim=pass header.d=friend.example; dmarc=pass header.from=friend.example\r\n\
                    From: Fay Friend <fay@friend.example>\r\nSubject: Unjudged\r\n\r\nHi.\r\n";
    let uid = s.server.add_message("INBOX", confirmed, &[]);
    s.server.add_message("INBOX", forged, &[]);
    s.server.add_message("INBOX", unjudged, &[]);
    let account = s.core.add_account(&settings(&s.server), PASSWORD).unwrap();
    s.core.sync(account).unwrap();
    s.wait(|e| *e == Event::SyncFinished { account, failure: None });
    let inbox = s
        .core
        .folders(account)
        .unwrap()
        .into_iter()
        .find(|f| f.info.path == "INBOX")
        .unwrap()
        .id;
    // the card, its picture from a PNG file: a wide red picture, its middle square kept
    let card = s
        .core
        .save_card(&pe_store::Card {
            name: "Fay Friend".into(),
            addresses: vec!["fay@friend.example".into()],
            ..Default::default()
        })
        .unwrap();
    let file = std::env::temp_dir().join(format!("pe-card-{}.png", std::process::id()));
    image::RgbaImage::from_pixel(90, 60, image::Rgba([255, 0, 0, 255]))
        .save(&file)
        .unwrap();
    // prepared first (a window shows it), set once the user says OK
    let png = pe_core::card_pictures::prepare(&file).unwrap();
    s.core.set_card_picture_png(card, &png).unwrap();
    std::fs::write(&file, b"not a picture").unwrap();
    assert!(pe_core::card_pictures::prepare(&file).is_err(), "no picture refused");
    assert!(s.core.set_card_picture_png(card, b"not one of the core's").is_err());
    let _ = std::fs::remove_file(&file);
    assert!(s.core.card_has_picture(card));
    assert_eq!(s.core.card_picture(card, 64).map(|p| p.len()), Some(64 * 64 * 4));
    let row = |subject: &str| {
        s.core
            .messages(inbox, Sort::default(), 0, 10)
            .unwrap()
            .into_iter()
            .find(|m| m.info.subject == subject)
            .unwrap()
    };
    // the background worker reads the verdicts after the sync
    let deadline = std::time::Instant::now() + Duration::from_secs(20);
    while row("Confirmed").sender_auth == 0 {
        assert!(std::time::Instant::now() < deadline, "no verdict on the row");
        std::thread::sleep(Duration::from_millis(100));
    }
    let (kind, key) = pe_core::senders::picture(&row("Confirmed"));
    assert_eq!(kind, pe_core::senders::PictureKind::Contact);
    assert_eq!(
        pe_core::senders::picture(&row("Forged")).0,
        pe_core::senders::PictureKind::None
    );
    // no verdict of the provider's: the initials, not the face
    while row("Unjudged").sender_auth == 0 {
        assert!(std::time::Instant::now() < deadline, "no verdict on the row");
        std::thread::sleep(Duration::from_millis(100));
    }
    assert_ne!(row("Unjudged").sender_auth & pe_core::senders::NO_VERDICT, 0);
    assert_eq!(
        pe_core::senders::picture(&row("Unjudged")).0,
        pe_core::senders::PictureKind::None
    );
    let request = s.core.picture_start(key, 32).unwrap();
    s.wait(|e| *e == Event::PictureReady { request });
    let pixels = s.core.picture_result(request).expect("the contact's picture");
    assert_eq!(pixels.len(), 32 * 32 * 4);
    // red, BGRA
    assert_eq!(&pixels[(16 * 32 + 16) * 4..][..4], &[0, 0, 255, 255]);
    // the reading pane: the same picture where a logo would be
    s.core.open_message(inbox, uid).unwrap();
    s.wait(|e| *e == Event::MessageReady { folder: inbox, uid });
    let view = s.core.message_view(inbox, uid, false).unwrap().unwrap();
    assert!(!view.has_logo);
    assert_eq!(view.picture, key);
    // set again: a key of its own, so no window shows the old picture
    let file = std::env::temp_dir().join(format!("pe-card-{}-2.png", std::process::id()));
    image::RgbaImage::from_pixel(40, 40, image::Rgba([0, 0, 255, 255]))
        .save(&file)
        .unwrap();
    let png = pe_core::card_pictures::prepare(&file).unwrap();
    s.core.set_card_picture_png(card, &png).unwrap();
    let _ = std::fs::remove_file(&file);
    assert_ne!(pe_core::senders::picture(&row("Confirmed")).1, key);
    s.core.remove_card_picture(card).unwrap();
    assert_eq!(
        pe_core::senders::picture(&row("Confirmed")).0,
        pe_core::senders::PictureKind::None
    );
    // a key a window kept from before: drawn as nothing
    let request = s.core.picture_start(key, 32).unwrap();
    s.wait(|e| *e == Event::PictureReady { request });
    assert_eq!(s.core.picture_result(request), None);
}

/// A message the server can not give says so, for the reading pane, and opening it again tries again: an account
/// whose server is out of reach (its port changed to one nothing listens on), and back
#[test]
fn a_message_that_can_not_be_downloaded_says_why() {
    let Some(s) = setup() else { return };
    let uid = s
        .server
        .add_message("INBOX", &rfc822("Unread", "Not downloaded yet"), &[]);
    let good = settings(&s.server);
    let account = s.core.add_account(&good, PASSWORD).unwrap();
    s.core.sync(account).unwrap();
    s.wait(|e| *e == Event::SyncFinished { account, failure: None });
    let inbox = s
        .core
        .folders(account)
        .unwrap()
        .into_iter()
        .find(|f| f.info.path == "INBOX")
        .unwrap()
        .id;

    // a port nothing listens on: taken and given back
    let closed = std::net::TcpListener::bind("127.0.0.1:0")
        .unwrap()
        .local_addr()
        .unwrap()
        .port();
    let mut away = good.clone();
    away.imap_port = closed;
    s.core.update_account(account, &away).unwrap();
    s.core.open_message(inbox, uid).unwrap();
    let failed = s.wait(|e| matches!(e, Event::MessageFailed { .. }));
    let Event::MessageFailed {
        folder,
        uid: failed_uid,
        kind,
        message,
    } = failed
    else {
        unreachable!()
    };
    assert_eq!(
        (folder, failed_uid, kind),
        (inbox, uid, FailureKind::Network),
        "{message}"
    );
    assert!(!message.is_empty());
    let page = pe_core::reader_page(pe_core::ReaderState::Failed { kind, reason: &message });
    assert!(page.contains("could not be reached"), "{page}");

    // a sync that can not reach the server says so as it finishes: the windows do not try the message again yet
    s.core.sync(account).unwrap();
    s.wait(|e| matches!(e, Event::Failed { kind: FailureKind::Network, account: a, .. } if *a == account));
    s.wait(|e| {
        *e == Event::SyncFinished {
            account,
            failure: Some(FailureKind::Network),
        }
    });
    // the server back: opening it again downloads it
    s.core.update_account(account, &good).unwrap();
    s.core.open_message(inbox, uid).unwrap();
    s.wait(|e| *e == Event::MessageReady { folder: inbox, uid });
    let view = s.core.message_view(inbox, uid, false).unwrap().unwrap();
    assert!(view.document.contains("Not downloaded yet"));
}

/// A message opened while the account's worker is busy with a long sync comes from the reader, its own connection,
/// without waiting for the sync to end
#[test]
fn a_message_opened_during_a_sync_comes_at_once() {
    let Some(s) = setup() else { return };
    let warm = s.server.add_message("INBOX", &rfc822("First", "Opened first"), &[]);
    let uid = s
        .server
        .add_message("INBOX", &rfc822("Second", "Read me while it syncs"), &[]);
    let account = s.core.add_account(&settings(&s.server), PASSWORD).unwrap();
    s.core.sync(account).unwrap();
    s.wait(|e| *e == Event::SyncFinished { account, failure: None });
    let inbox = s
        .core
        .folders(account)
        .unwrap()
        .into_iter()
        .find(|f| f.info.path == "INBOX")
        .unwrap()
        .id;
    // the reader connected, as it is once the user has read a message
    s.core.open_message(inbox, warm).unwrap();
    s.wait(|e| {
        *e == Event::MessageReady {
            folder: inbox,
            uid: warm,
        }
    });
    // a folder with many messages, which its first sync takes a while to list
    let big = "Archive";
    for n in 0..400 {
        s.server.add_message(big, &rfc822(&format!("Old {n}"), "old"), &[]);
    }
    s.core.sync(account).unwrap();
    s.core.open_message(inbox, uid).unwrap();
    // the message before the sync is done
    let first = s.wait(|e| matches!(e, Event::MessageReady { .. } | Event::SyncFinished { .. }));
    assert_eq!(
        first,
        Event::MessageReady { folder: inbox, uid },
        "the message waited for the sync"
    );
    s.wait(|e| *e == Event::SyncFinished { account, failure: None });
}

#[test]
fn bounces_are_marked_and_explained() {
    let Some(s) = setup() else { return };
    let account = s.core.add_account(&settings(&s.server), PASSWORD).unwrap();
    s.core.sync(account).unwrap();
    s.wait(|e| *e == Event::SyncFinished { account, failure: None });
    let folders = s.core.folders(account).unwrap();
    let inbox = folders.iter().find(|f| f.info.path == "INBOX").unwrap().id;
    let sent = folders
        .iter()
        .find(|f| f.info.special_use.as_deref() == Some("\\Sent"))
        .unwrap();
    // the message that bounced, in Sent Items
    let sent_uid = s.server.add_message(
        &sent.info.path,
        "From: Me <me@example.com>\r\nTo: nobody@example.org\r\nSubject: The quarterly report\r\n\
         Message-ID: <report-1@example.com>\r\n\r\nHere it is.\r\n",
        &[],
    );
    let sent = sent.id;
    // a delivery report, which the list marks from its structure
    let report = s.server.add_message(
        "INBOX",
        "From: Mail Delivery System <MAILER-DAEMON@mx.example.com>\r\nTo: me@example.com\r\n\
         Subject: Undelivered Mail Returned to Sender\r\nMIME-Version: 1.0\r\n\
         Content-Type: multipart/report; report-type=delivery-status; boundary=\"B\"\r\n\r\n\
         --B\r\nContent-Type: text/plain\r\n\r\nYour message could not be delivered.\r\n\
         --B\r\nContent-Type: message/delivery-status\r\n\r\nReporting-MTA: dns; mx.example.com\r\n\r\n\
         Final-Recipient: rfc822; nobody@example.org\r\nAction: failed\r\nStatus: 5.1.1\r\n\
         Diagnostic-Code: smtp; 550 5.1.1 <nobody@example.org>: User unknown\r\n\
         --B\r\nContent-Type: text/rfc822-headers\r\n\r\nFrom: Me <me@example.com>\r\nTo: nobody@example.org\r\n\
         Subject: The quarterly report\r\nMessage-ID: <report-1@example.com>\r\n--B--\r\n",
        &[],
    );
    // a notice in plain text, a bounce only the heuristics find once it is opened
    let plain = s.server.add_message(
        "INBOX",
        "From: Mail Delivery System <MAILER-DAEMON@mx.example.com>\r\nTo: me@example.com\r\n\
         Subject: Undelivered Mail\r\nContent-Type: text/plain\r\n\r\n\
         <grace@example.org>: host mx.example.org[203.0.113.4] said: 552 5.2.2 Mailbox full\r\n\
         (in reply to RCPT TO command)\r\n",
        &[],
    );
    let ordinary = s.server.add_message(
        "INBOX",
        "From: Ann <ann@example.com>\r\nSubject: Lunch\r\n\r\nNoon?\r\n",
        &[],
    );
    s.core.sync(account).unwrap();
    s.wait(|e| *e == Event::SyncFinished { account, failure: None });

    let marked = |text: &str| -> Vec<u64> {
        let search = Search {
            text: text.into(),
            ..Search::folder(inbox)
        };
        let mut uids: Vec<u64> = s
            .core
            .search(&search, Sort::default(), 0, 10)
            .unwrap()
            .into_iter()
            .map(|m| m.info.uid)
            .collect();
        uids.sort();
        uids
    };
    assert_eq!(marked("is:bounce"), [report]);
    let listed = s.core.search(&Search::folder(inbox), Sort::default(), 0, 10).unwrap();
    let bounce_of = |uid: u64| listed.iter().find(|m| m.info.uid == uid).unwrap().info.bounce;
    assert!(bounce_of(report) && !bounce_of(plain) && !bounce_of(ordinary));

    // opened: the card, with the link to the message in Sent Items
    s.core.open_message(inbox, report).unwrap();
    s.wait(|e| {
        *e == Event::MessageReady {
            folder: inbox,
            uid: report,
        }
    });
    let view = s.core.message_view(inbox, report, false).unwrap().unwrap();
    assert!(view.bounce);
    assert_eq!(
        view.bounced_message,
        Some(MessageRef {
            folder: sent,
            uid: sent_uid
        })
    );
    assert!(
        view.document.contains("The address does not exist"),
        "{}",
        view.document
    );
    assert!(view.document.contains(pe_html::BOUNCED_MESSAGE_LINK));

    // the plain notice gets its mark once opened, on a worker as the reading pane builds it
    s.core.open_message(inbox, plain).unwrap();
    s.wait(|e| {
        *e == Event::MessageReady {
            folder: inbox,
            uid: plain,
        }
    });
    let request = s.core.message_view_start(inbox, plain, false).unwrap();
    s.wait(|e| *e == Event::FolderChanged { account, folder: inbox });
    s.wait(|e| *e == Event::ViewReady { request });
    let view = s.core.message_view_result(request).unwrap();
    assert!(view.bounce);
    assert!(view.document.contains("The mailbox is full"), "{}", view.document);
    // it names no message of the account
    assert_eq!(view.bounced_message, None);
    assert_eq!(marked("is:bounce"), [report, plain]);
    assert_eq!(marked("-is:bounce"), [ordinary]);

    // ordinary mail stays as it was
    s.core.open_message(inbox, ordinary).unwrap();
    s.wait(|e| {
        *e == Event::MessageReady {
            folder: inbox,
            uid: ordinary,
        }
    });
    let view = s.core.message_view(inbox, ordinary, false).unwrap().unwrap();
    assert!(!view.bounce && !view.document.contains("pe-bounce-"));
    assert_eq!(marked("is:bounce"), [report, plain]);
}

/// A trusted sender's pictures load by themselves when the provider confirms the message is theirs; a forged one
/// from the same address asks; Options' setting loads every message's
#[test]
fn a_trusted_senders_pictures_load_when_confirmed() {
    let Some(s) = setup() else { return };
    let body = "Content-Type: text/html\r\n\r\n<p>Sale!</p><img src=\"https://shop.example/pixel.png\">\r\n";
    let confirmed = s.server.add_message(
        "INBOX",
        &format!(
            "Authentication-Results: mx.example.com; dkim=pass header.d=shop.example; dmarc=pass header.from=shop.example\r\n\
             From: Shop <news@shop.example>\r\nTo: you@example.com\r\nSubject: Confirmed\r\nMIME-Version: 1.0\r\n{body}"
        ),
        &[],
    );
    let forged = s.server.add_message(
        "INBOX",
        &format!(
            "Authentication-Results: mx.example.com; dkim=fail header.d=shop.example; dmarc=fail header.from=shop.example\r\n\
             From: Shop <news@shop.example>\r\nTo: you@example.com\r\nSubject: Forged\r\nMIME-Version: 1.0\r\n{body}"
        ),
        &[],
    );
    let account = s.core.add_account(&settings(&s.server), PASSWORD).unwrap();
    s.core.sync(account).unwrap();
    s.wait(|e| *e == Event::SyncFinished { account, failure: None });
    let inbox = s
        .core
        .folders(account)
        .unwrap()
        .into_iter()
        .find(|f| f.info.path == "INBOX")
        .unwrap()
        .id;
    for uid in [confirmed, forged] {
        s.core.open_message(inbox, uid).unwrap();
        s.wait(|e| *e == Event::MessageReady { folder: inbox, uid });
    }
    let view = |uid| s.core.message_view(inbox, uid, false).unwrap().unwrap();

    let before = view(confirmed);
    assert!(before.remote_images && !before.pictures_loaded, "blocked until trusted");
    let sender = before.sender.clone().unwrap();
    assert_eq!(
        (sender.address.as_str(), sender.domain.as_str(), sender.verified),
        ("news@shop.example", "shop.example", true)
    );
    assert!(!pe_core::pictures::bar_words(&sender).always_domain.is_empty());

    s.core.trust_sender("shop.example", true).unwrap();
    assert!(view(confirmed).pictures_loaded, "trusted and confirmed");
    let forged_view = view(forged);
    assert!(!forged_view.pictures_loaded, "a forged sender still asks");
    let words = pe_core::pictures::bar_words(forged_view.sender.as_ref().unwrap());
    assert!(words.always_sender.is_empty() && !words.unconfirmed.is_empty());

    s.core.set_always_load_pictures(true).unwrap();
    assert!(view(forged).pictures_loaded, "every message's with the setting");
    let trusted = s.core.trusted_senders().unwrap();
    s.core.untrust_sender(trusted[0].id).unwrap();
    s.core.set_always_load_pictures(false).unwrap();
    assert!(!view(confirmed).pictures_loaded);
}

// ---- the reader: ready before the first click and kept ready (docs/open-speed-plan.md, phase 2) ----

/// The sessions ImapKit has open: (number, state)
fn sessions(server: &ImapKit) -> Vec<(u64, String)> {
    let listed = server.request("GET", "/v1/sessions", None);
    listed
        .as_array()
        .expect("a list")
        .iter()
        .map(|s| {
            (
                s["session"].as_u64().unwrap_or(0),
                s["state"].as_str().unwrap_or("").to_string(),
            )
        })
        .collect()
}

/// The reader's session, once the three workers are connected and done: the main worker's and the background
/// worker's have a folder selected, the reader's not before its first open
fn reader_session(server: &ImapKit) -> Option<u64> {
    let now = sessions(server);
    let waiting: Vec<u64> = now
        .iter()
        .filter(|(_, state)| state == "Authenticated")
        .map(|(number, _)| *number)
        .collect();
    (now.len() == 3 && waiting.len() == 1).then(|| waiting[0])
}

/// An account synced once, with these messages in its Inbox: (account, Inbox, their UIDs)
fn synced_with(s: &Setup, subjects: &[&str]) -> (pe_store::AccountId, pe_store::FolderId, Vec<u64>) {
    let uids = subjects
        .iter()
        .map(|subject| s.server.add_message("INBOX", &rfc822(subject, "Hello"), &[]))
        .collect();
    let account = s.core.add_account(&settings(&s.server), PASSWORD).unwrap();
    s.core.sync(account).unwrap();
    s.wait(|e| *e == Event::SyncFinished { account, failure: None });
    let inbox = s
        .core
        .folders(account)
        .unwrap()
        .into_iter()
        .find(|f| f.info.path == "INBOX")
        .unwrap()
        .id;
    (account, inbox, uids)
}

fn open(s: &Setup, folder: pe_store::FolderId, uid: u64) {
    s.core.open_message(folder, uid).unwrap();
    s.wait(|e| *e == Event::MessageReady { folder, uid });
}

#[test]
fn the_reader_is_connected_before_the_first_open() {
    let Some(s) = setup() else { return };
    let (_, inbox, uids) = synced_with(&s, &["One"]);
    eventually(
        || reader_session(&s.server).is_some(),
        "the reader connects after the first sync",
    );
    open(&s, inbox, uids[0]);
    let timing = s.core.open_timings().pop().unwrap();
    assert_eq!(
        (timing.served, timing.link),
        (Served::Reader, Link::Reused),
        "{timing:?}"
    );
    assert_eq!(timing.connected, None);
}

#[test]
fn a_dead_reader_connection_is_replaced_within_seconds() {
    let Some(s) = setup() else { return };
    let (_, inbox, uids) = synced_with(&s, &["One"]);
    eventually(|| reader_session(&s.server).is_some(), "the reader connects");
    // from now on the reader's session gets no answer, as one a NAT forgot
    let reader = reader_session(&s.server).expect("the reader's session");
    s.server.request(
        "POST",
        "/v1/script/rules",
        // what an open sends; the sign-in may still be finishing (ID, ENABLE), which the reader waits for
        Some(json!({
            "on": "command", "session": reader, "command": ["SELECT", "EXAMINE", "UID FETCH"], "drop": true
        })),
    );
    let started = std::time::Instant::now();
    s.core.open_message(inbox, uids[0]).unwrap();
    // the answer limit and a new connection: more than the 10 seconds of Setup::wait on a slow machine
    loop {
        let event = s.events.recv_timeout(Duration::from_secs(20)).expect("the message");
        if event
            == (Event::MessageReady {
                folder: inbox,
                uid: uids[0],
            })
        {
            break;
        }
        assert!(!matches!(event, Event::MessageFailed { .. }), "{event:?}");
    }
    let took = started.elapsed();
    let timing = s.core.open_timings().pop().unwrap();
    assert_eq!(timing.link, Link::Retried, "{timing:?}");
    assert!(took < Duration::from_secs(15), "{took:?}");
}

#[test]
fn connections_are_made_again_after_a_wake() {
    let Some(s) = setup() else { return };
    let (_, inbox, uids) = synced_with(&s, &["One"]);
    eventually(|| sessions(&s.server).len() >= 2, "the reader connects");
    let before: Vec<u64> = sessions(&s.server).into_iter().map(|(n, _)| n).collect();
    s.core.woke();
    eventually(
        || {
            // the main worker's and the reader's at least (the background worker's while it has work)
            let now = sessions(&s.server);
            now.len() >= 2 && now.iter().all(|(n, _)| !before.contains(n))
        },
        "both connections are new",
    );
    open(&s, inbox, uids[0]);
}

#[test]
fn opens_go_to_the_main_worker_when_the_server_allows_one_connection() {
    // every connection after the first is refused at its greeting
    let Some(s) = setup_with(json!({ "script": {
        "on": "greeting", "nth": 2, "send": "* BYE Too many connections\r\n", "close": true
    } })) else {
        return;
    };
    let (account, inbox, uids) = synced_with(&s, &["One", "Two"]);
    for uid in &uids {
        s.core.open_message(inbox, *uid).unwrap();
        // no failure for the account: doing without the reader is not one
        s.wait(|e| match e {
            Event::MessageReady { uid: ready, .. } => ready == uid,
            Event::MessageFailed { .. } => panic!("{e:?}"),
            Event::Failed { account: failed, .. } if *failed == account => panic!("{e:?}"),
            _ => false,
        });
    }
    let timings = s.core.open_timings();
    assert!(timings.iter().all(|t| t.served == Served::Main), "{timings:?}");
    assert!(s.core.message_view(inbox, uids[1], false).unwrap().is_some());
}

// ---- the background worker: what the user does not wait for, on a connection of its own (phase 3) ----

/// Whether the search finds `word` in the text of the mail of `folder`
fn finds(s: &Setup, folder: pe_store::FolderId, word: &str) -> bool {
    let search = Search {
        text: word.into(),
        ..Search::folder(folder)
    };
    !s.core.search(&search, Sort::default(), 0, 10).unwrap().is_empty()
}

#[test]
fn new_mail_shows_while_the_search_text_is_downloaded() {
    // the text of the mail comes slowly: seconds for each batch
    let Some(s) = setup_with(json!({ "script": {
        "on": "command", "match": "BODY\\.PEEK\\[1\\]", "delay": 3000
    } })) else {
        return;
    };
    let (account, inbox, _) = synced_with(&s, &["One", "Two"]);
    // the main worker is on the Inbox meanwhile, not in the batch
    std::thread::sleep(Duration::from_millis(300));
    s.server.add_message("INBOX", &rfc822("Three", "x"), &[]);
    let started = std::time::Instant::now();
    s.wait(|e| *e == Event::FolderChanged { account, folder: inbox });
    assert!(started.elapsed() < Duration::from_secs(2), "{:?}", started.elapsed());
    eventually(|| finds(&s, inbox, "Hello"), "the search text comes after");
}

#[test]
fn the_main_worker_does_the_background_work_when_the_server_allows_one_connection() {
    let Some(s) = setup_with(json!({ "script": {
        "on": "greeting", "nth": 2, "send": "* BYE Too many connections\r\n", "close": true
    } })) else {
        return;
    };
    let (account, inbox, _) = synced_with(&s, &["One"]);
    eventually(|| finds(&s, inbox, "Hello"), "the search text of the mail");
    // and new mail still comes in over IDLE
    s.server.add_message("INBOX", &rfc822("Two", "Later words"), &[]);
    s.wait(|e| *e == Event::FolderChanged { account, folder: inbox });
    eventually(|| finds(&s, inbox, "Later"), "the search text of new mail");
    assert_eq!(sessions(&s.server).len(), 1);
}

// ---- messages downloaded before they are opened (phase 3) ----

/// Adds a message that arrived long ago, as downloading ahead's "recent" leaves it
fn add_old(s: &Setup, mailbox: &str, subject: &str) -> u64 {
    let body = json!({
        "raw": rfc822(subject, "Old words"),
        "flags": [],
        "internaldate": "01-Jan-2020 10:00:00 +0000",
    });
    let path = format!("/v1/mailboxes/{mailbox}/messages");
    s.server.request("POST", &path, Some(body))["uid"].as_u64().unwrap()
}

fn downloaded(s: &Setup, folder: pe_store::FolderId, uid: u64) -> bool {
    s.core.message_source(folder, uid).unwrap().is_some()
}

#[test]
fn new_mail_is_downloaded_before_it_is_opened() {
    let Some(s) = setup() else { return };
    s.core.set_download_ahead(pe_core::Ahead::Recent).unwrap();
    let big = s
        .server
        .add_message("INBOX", &rfc822("Big", &"x".repeat(2 * 1024 * 1024)), &[]);
    let junk = s.server.add_message("Junk", &rfc822("Spam", "Buy"), &[]);
    let (account, inbox, uids) = synced_with(&s, &["One"]);
    eventually(|| downloaded(&s, inbox, uids[0]), "the Inbox message");
    // new mail over IDLE
    let new = s.server.add_message("INBOX", &rfc822("Two", "Fresh words"), &[]);
    eventually(|| downloaded(&s, inbox, new), "new mail as it arrives");
    // found by the words of its source, which came with it
    eventually(|| finds(&s, inbox, "Fresh"), "its search text");
    // opened from the store: no connection used
    open(&s, inbox, new);
    let timing = s.core.open_timings().pop().unwrap();
    assert_eq!(timing.served, Served::Store, "{timing:?}");
    // too large, or spam: when opened
    let junk_folder = s
        .core
        .folders(account)
        .unwrap()
        .into_iter()
        .find(|f| f.info.path == "Junk")
        .unwrap()
        .id;
    std::thread::sleep(Duration::from_millis(500));
    assert!(!downloaded(&s, inbox, big));
    assert!(!downloaded(&s, junk_folder, junk));
}

#[test]
fn the_messages_next_to_the_one_opened_are_downloaded() {
    let Some(s) = setup() else { return };
    let older: Vec<u64> = ["A", "B", "C", "D"]
        .iter()
        .map(|subject| add_old(&s, "INBOX", subject))
        .collect();
    let (_, inbox, _) = synced_with(&s, &[]);
    // recent only: these are older than that
    s.core.set_download_ahead(pe_core::Ahead::Recent).unwrap();
    std::thread::sleep(Duration::from_millis(500));
    assert!(older.iter().all(|uid| !downloaded(&s, inbox, *uid)));
    open(&s, inbox, older[1]);
    eventually(
        || downloaded(&s, inbox, older[0]) && downloaded(&s, inbox, older[2]),
        "the messages above and below",
    );
    assert!(!downloaded(&s, inbox, older[3]));
}

#[test]
fn a_moved_message_keeps_its_downloaded_source() {
    let Some(s) = setup() else { return };
    let (account, inbox, uids) = synced_with(&s, &["One"]);
    open(&s, inbox, uids[0]);
    let archive = s
        .core
        .folders(account)
        .unwrap()
        .into_iter()
        .find(|f| f.info.path == "Archive")
        .unwrap()
        .id;
    s.core.move_messages(inbox, &uids, archive).unwrap();
    eventually(
        || {
            let moved = s.core.messages(archive, Sort::default(), 0, 10).unwrap();
            moved.len() == 1 && downloaded(&s, archive, moved[0].info.uid)
        },
        "the source with the message where it went",
    );
}

#[test]
fn a_text_batch_the_server_refuses_is_fetched_one_message_at_a_time() {
    // a batch of more than one message is refused, one alone is not
    let Some(s) = setup_with(json!({ "script": {
        "on": "command", "match": "UID FETCH [0-9]+[:,][^ ]* \\(UID BODYSTRUCTURE\\)", "send": "$TAG NO not today\r\n"
    } })) else {
        return;
    };
    s.server.add_message("INBOX", &rfc822("A", "Apples"), &[]);
    s.server.add_message("INBOX", &rfc822("B", "Bananas"), &[]);
    let (_, inbox, _) = synced_with(&s, &[]);
    eventually(
        || finds(&s, inbox, "Apples") && finds(&s, inbox, "Bananas"),
        "both texts",
    );
    // the batch was refused indeed
    let rules = s.server.request("GET", "/v1/script/rules", None);
    assert!(rules[0]["hits"].as_u64().unwrap() >= 1, "{rules}");
}

#[test]
fn an_archived_message_keeps_its_downloaded_source() {
    let Some(s) = setup() else { return };
    let (account, inbox, uids) = synced_with(&s, &["One"]);
    open(&s, inbox, uids[0]);
    s.core.archive_messages(inbox, &uids).unwrap();
    let archive = s
        .core
        .folders(account)
        .unwrap()
        .into_iter()
        .find(|f| f.info.path == "Archive")
        .unwrap()
        .id;
    eventually(
        || {
            let archived = s.core.messages(archive, Sort::default(), 0, 10).unwrap();
            archived.len() == 1 && downloaded(&s, archive, archived[0].info.uid)
        },
        "the source with the message in the Archive",
    );
}

// ---- the user goes first (phase 4) ----

#[test]
fn a_draft_is_uploaded_on_a_connection_of_its_own() {
    // the server takes its time with every upload
    let Some(s) = setup_with(json!({ "script": { "on": "command", "command": "APPEND", "delay": 3000 } })) else {
        return;
    };
    let (account, inbox, uids) = synced_with(&s, &["One"]);
    let outgoing = pe_core::Outgoing {
        subject: "Plans".into(),
        html: Some("<p>first</p>".into()),
        ..Default::default()
    };
    let message_id = s.core.save_draft(account, outgoing.clone()).unwrap();
    // saved again while the first is on its way: queued, not waited for
    let again = pe_core::Outgoing {
        message_id: Some(message_id),
        html: Some("<p>second</p>".into()),
        ..outgoing
    };
    s.core.save_draft(account, again).unwrap();
    // meanwhile the main worker does what the user asks at once
    std::thread::sleep(Duration::from_millis(500));
    let started = std::time::Instant::now();
    s.core.set_seen(inbox, uids[0], true).unwrap();
    eventually(
        || s.server.flags("INBOX", uids[0]).contains(&"\\Seen".to_string()),
        "read on the server",
    );
    assert!(started.elapsed() < Duration::from_secs(2), "{:?}", started.elapsed());
    for _ in 0..2 {
        let saved = s.wait(|e| matches!(e, Event::DraftSaved { .. }));
        assert!(matches!(saved, Event::DraftSaved { problem: None, .. }), "{saved:?}");
    }
    // the second in place of the first
    eventually(|| s.server.subjects("Drafts") == ["Plans"], "one draft on the server");
}

#[test]
fn a_click_during_a_large_download_is_answered_first() {
    // the first download of the whole message waits at the server
    let Some(s) = setup_with(json!({ "script": {
        "on": "command", "match": "BODY\\.PEEK\\[\\]", "delay": 4000, "times": 1
    } })) else {
        return;
    };
    let big = s
        .server
        .add_message("INBOX", &rfc822("Big", &"x".repeat(600 * 1024)), &[]);
    let (_, inbox, uids) = synced_with(&s, &["Small"]);
    eventually(|| reader_session(&s.server).is_some(), "the reader connects");
    s.core.open_message(inbox, big).unwrap();
    std::thread::sleep(Duration::from_millis(500));
    let started = std::time::Instant::now();
    open(&s, inbox, uids[0]);
    assert!(started.elapsed() < Duration::from_secs(3), "{:?}", started.elapsed());
    // and the large one still comes
    s.wait(|e| {
        *e == Event::MessageReady {
            folder: inbox,
            uid: big,
        }
    });
}

// ---- large messages show their text first (phase 5) ----

#[test]
fn a_large_message_shows_its_text_before_its_attachment() {
    // the whole message comes slowly: in pieces of 256 KB, 300 ms apart
    let Some(s) = setup_with(json!({ "script": {
        "on": "response", "command": "UID FETCH", "untagged": true, "match": "BODY\\[\\] ", "chunk": 262144, "chunkDelay": 300
    } })) else {
        return;
    };
    use base64::Engine;
    let pdf = base64::engine::general_purpose::STANDARD.encode(vec![7u8; 3 * 1024 * 1024]);
    let lines: Vec<&str> = pdf
        .as_bytes()
        .chunks(76)
        .map(|c| std::str::from_utf8(c).unwrap())
        .collect();
    let raw = format!(
        "From: Ann <ann@example.com>\r\nSubject: The report\r\nMIME-Version: 1.0\r\n\
         Content-Type: multipart/mixed; boundary=\"b1\"\r\n\r\n\
         --b1\r\nContent-Type: text/plain; charset=utf-8\r\n\r\nThe numbers are attached.\r\n\
         --b1\r\nContent-Type: application/pdf; name=\"report.pdf\"\r\n\
         Content-Disposition: attachment; filename=\"report.pdf\"\r\nContent-Transfer-Encoding: base64\r\n\r\n\
         {}\r\n--b1--\r\n",
        lines.join("\r\n")
    );
    let big = s.server.add_message("INBOX", &raw, &[]);
    let (_, inbox, _) = synced_with(&s, &[]);
    s.core.open_message(inbox, big).unwrap();
    s.wait(|e| {
        *e == Event::MessageReady {
            folder: inbox,
            uid: big,
        }
    });
    // its text, while the rest is on its way: never stored
    assert!(s.core.message_downloading(inbox, big));
    assert!(s.core.message_source(inbox, big).unwrap().is_none());
    let view = s.core.message_view(inbox, big, false).unwrap().unwrap();
    assert!(view.document.contains("The numbers are attached."), "{}", view.document);
    assert_eq!(view.attachments.len(), 1);
    assert_eq!(view.attachments[0].filename, "report.pdf");
    let size = view.attachments[0].size;
    assert!(size > 3_000_000 && size < 3_300_000, "{size}");
    // how far it is, then that it is all here, without another MessageReady: the window has its text
    let progress = s.wait(|e| matches!(e, Event::Transferring { .. }));
    assert!(
        matches!(&progress, Event::Transferring { text } if text.starts_with("Downloading")),
        "{progress:?}"
    );
    loop {
        let event = s
            .events
            .recv_timeout(Duration::from_secs(20))
            .expect("the whole message");
        assert_ne!(
            event,
            Event::MessageReady {
                folder: inbox,
                uid: big
            }
        );
        if matches!(&event, Event::Transferring { text } if text.starts_with("Downloaded")) {
            break;
        }
    }
    assert!(!s.core.message_downloading(inbox, big));
    let (_, source) = s.core.message_source(inbox, big).unwrap().unwrap();
    assert_eq!(
        source.len(),
        s.server.messages("INBOX")[0]["size"].as_u64().unwrap() as usize
    );
    let view = s.core.message_view(inbox, big, false).unwrap().unwrap();
    assert_eq!(view.attachments[0].size, 3 * 1024 * 1024);
}
