//! The engine against ImapKit (core/e2e), the way the windows drive it: add an account, sync,
//! read the folder tree and the message list, open a message, mark it read.
//!
//! Skipped without Node.js and `npm ci` in core/e2e, unless PE_E2E_REQUIRED is set.

use std::sync::mpsc::{Receiver, channel};
use std::time::Duration;

use pe_core::{Core, Event, FailureKind};
use pe_store::{AccountSettings, Sort};
use pe_testkit::{ImapKit, PASSWORD, TempDir, rfc822};
use serde_json::json;

struct Setup {
    server: ImapKit,
    core: Core,
    events: Receiver<Event>,
    _dir: TempDir,
}

fn setup() -> Option<Setup> {
    let server = ImapKit::start(json!({}))?;
    let dir = TempDir::new("core");
    let (sender, events) = channel();
    let trust = pe_net::Trust::Pinned(vec![server.cert.clone()]);
    let core = Core::open_with_trust(dir.path().join("store.db"), trust, move |event| {
        let _ = sender.send(event);
    })
    .unwrap();
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
    s.wait(|e| *e == Event::SyncFinished { account });

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
    s.wait(|e| *e == Event::SyncFinished { account });
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
    s.wait(|e| *e == Event::SyncFinished { account });
    // told once: another sync with the same password fails quietly
    s.core.sync(account).unwrap();
    let next = s.wait(|e| matches!(e, Event::SyncFinished { .. } | Event::Failed { .. }));
    assert_eq!(next, Event::SyncFinished { account });

    // with the right one it works
    s.core.set_password(account, PASSWORD);
    s.core.sync(account).unwrap();
    s.wait(|e| *e == Event::SyncFinished { account });
    assert!(!s.core.folders(account).unwrap().is_empty());
}

#[test]
fn removing_an_account_removes_its_mail() {
    let Some(s) = setup() else { return };
    s.server.add_message("INBOX", &rfc822("First", "x"), &[]);
    let account = s.core.add_account(&settings(&s.server), PASSWORD).unwrap();
    s.core.sync(account).unwrap();
    s.wait(|e| *e == Event::SyncFinished { account });
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
    s.wait(|e| *e == Event::SyncFinished { account });

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
    s.wait(|e| *e == Event::MessageSent { account });
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
    s.wait(|e| *e == Event::SyncFinished { account });
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
    assert!(reply.text.contains("> Shall we meet?"));
    assert!(reply.in_reply_to.is_some());

    // a recipient that is no address: nothing is sent
    let bad = pe_core::Outgoing {
        to: "not an address".into(),
        text: "x".into(),
        ..Default::default()
    };
    let refused = s.core.send(account, bad).unwrap_err();
    assert!(refused.to_string().contains("not an e-mail address"), "{refused}");
    assert_eq!(s.server.messages("INBOX").len(), 1);
}
