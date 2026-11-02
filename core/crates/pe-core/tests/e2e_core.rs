//! The engine against ImapKit (core/e2e), the way the windows drive it: add an account, sync,
//! read the folder tree and the message list, open a message, mark it read.
//!
//! Skipped without Node.js and `npm ci` in core/e2e, unless PE_E2E_REQUIRED is set.

use std::sync::mpsc::{Receiver, channel};
use std::time::Duration;

use pe_core::{Core, Event, FailureKind};
use pe_store::{AccountSettings, Sort};
use pe_testkit::{ImapKit, PASSWORD, TempDir, USER, rfc822};
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
    let options = pe_core::Options {
        trust,
        passwords: pe_core::PasswordStore::Memory,
        ..Default::default()
    };
    let core = Core::open_with(dir.path().join("store.db"), options, move |event| {
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
    s.wait(|e| *e == Event::MessageSent { account });
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
    let Some(server) = ImapKit::start(json!({})) else {
        return;
    };
    let token_port = pe_testkit::oauth_token_server();
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
    let (request, url) = core.sign_in_begin(pe_oauth::ProviderKind::Google, USER).unwrap();
    assert!(url.starts_with("https://accounts.example.com/auth?"), "{url}");
    assert!(pe_testkit::oauth_browser(&url, "the-code").contains("You are signed in"));
    wait(&|e| *e == Event::SignInDone { request });
    assert_eq!(core.sign_in_result(request), Ok(()));

    // the account signs in to ImapKit with XOAUTH2 and the access token from the refresh token, at the
    // provider's servers whatever the settings given said
    let mut elsewhere = server.account_settings();
    elsewhere.smtp_host = "smtp.attacker.example".into();
    let account = core.add_account_oauth(&elsewhere, request).unwrap();
    assert_eq!(core.accounts().unwrap()[0].settings.smtp_host, "127.0.0.1");
    assert!(matches!(core.accounts().unwrap()[0].settings.auth, pe_store::Auth::OAuth2(ref p) if p == "google"));
    core.sync(account).unwrap();
    wait(&|e| *e == Event::SyncFinished { account });
    assert!(!core.folders(account).unwrap().is_empty());
    // the sign-in was taken
    assert!(core.add_account_oauth(&server.account_settings(), request).is_err());
    // changing the settings keeps how it signs in, and its servers
    core.update_account(account, &elsewhere).unwrap();
    let kept = &core.accounts().unwrap()[0].settings;
    assert!(matches!(kept.auth, pe_store::Auth::OAuth2(_)) && kept.smtp_host == "127.0.0.1");

    // a code the provider refuses
    let (refused, url) = core.sign_in_begin(pe_oauth::ProviderKind::Google, USER).unwrap();
    pe_testkit::oauth_browser(&url, "wrong-code");
    wait(&|e| *e == Event::SignInDone { request: refused });
    assert!(core.sign_in_result(refused).unwrap_err().contains("invalid_grant"));
    // told once, then forgotten
    assert!(core.sign_in_result(refused).unwrap_err().contains("not finished"));

    // a cancelled sign-in is forgotten
    let (cancelled, _) = core.sign_in_begin(pe_oauth::ProviderKind::Google, USER).unwrap();
    core.sign_in_cancel(cancelled);
    assert!(core.sign_in_result(cancelled).is_err());
}

#[test]
fn flags_moves_and_deletes_messages() {
    let Some(s) = setup() else { return };
    let flag = s.server.add_message("INBOX", &rfc822("Flag me", "1"), &[]);
    let archive = s.server.add_message("INBOX", &rfc822("Archive me", "2"), &[]);
    let delete = s.server.add_message("INBOX", &rfc822("Delete me", "3"), &[]);
    let account = s.core.add_account(&settings(&s.server), PASSWORD).unwrap();
    s.core.sync(account).unwrap();
    s.wait(|e| *e == Event::SyncFinished { account });
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
    s.core.set_flagged(inbox, flag, true).unwrap();
    s.wait(|e| *e == Event::FolderChanged { account, folder: inbox });
    let row = s.core.messages(inbox, Sort::default(), 0, 100).unwrap();
    assert!(row.iter().find(|m| m.info.uid == flag).unwrap().info.flagged());
    eventually(&|| s.server.flags("INBOX", flag).contains(&"\\Flagged".to_string()));
    s.core.set_flagged(inbox, flag, false).unwrap();
    eventually(&|| !s.server.flags("INBOX", flag).contains(&"\\Flagged".to_string()));

    // a move: gone from the list at once, in the other folder once the server has it
    s.core.move_message(inbox, archive, archive_folder).unwrap();
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
    assert!(s.core.move_message(inbox, flag, inbox).is_err());

    // deleting: into Deleted Items, and from there for good (which the window asks about first)
    assert!(!s.core.deletes_for_good(inbox).unwrap());
    assert!(s.core.deletes_for_good(trash).unwrap());
    s.core.delete_message(inbox, delete).unwrap();
    s.wait(|e| *e == Event::FolderChanged { account, folder: trash });
    assert_eq!(in_store(trash), ["Delete me"]);
    assert_eq!(s.server.subjects("Trash"), ["Delete me"]);
    let in_trash = s.core.messages(trash, Sort::default(), 0, 10).unwrap()[0].info.uid;
    s.core.delete_message(trash, in_trash).unwrap();
    assert!(in_store(trash).is_empty());
    eventually(&|| s.server.subjects("Trash").is_empty());
    assert_eq!(s.server.subjects("INBOX"), ["Flag me"]);

    // a sync agrees with all of it
    s.core.sync(account).unwrap();
    s.wait(|e| *e == Event::SyncFinished { account });
    assert_eq!(in_store(inbox), ["Flag me"]);
    assert!(in_store(trash).is_empty());
}

#[test]
fn a_move_or_delete_the_server_does_not_do_comes_back() {
    let Some(s) = setup() else { return };
    let first = s.server.add_message("INBOX", &rfc822("First", "1"), &[]);
    let second = s.server.add_message("INBOX", &rfc822("Second", "2"), &[]);
    let account = s.core.add_account(&settings(&s.server), PASSWORD).unwrap();
    s.core.sync(account).unwrap();
    s.wait(|e| *e == Event::SyncFinished { account });
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
    core.move_message(inbox, first, archive).unwrap();
    core.delete_message(inbox, second).unwrap();
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
