//! The engine against ImapKit (core/e2e), the way the windows drive it: add an account, sync,
//! read the folder tree and the message list, open a message, mark it read.
//!
//! Skipped without Node.js and `npm ci` in core/e2e, unless PE_E2E_REQUIRED is set.

use std::sync::mpsc::{Receiver, channel};
use std::time::Duration;

use pe_core::{Action, Core, Event, FailureKind, MessageRef, Search};
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
    assert!(message.contains("check that the app's scopes"), "{message}");

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
    let report = s
        .core
        .import_files(inbox, &[written[0].clone(), notes.clone()])
        .unwrap()
        .unwrap();
    assert!(report.contains("notes.txt") && !report.contains("Lunch"), "{report}");
    assert!(pe_core::is_message_file(&written[0]) && !pe_core::is_message_file(&notes));
    assert_eq!(s.core.import_files(inbox, &[written[0].clone()]).unwrap(), None);

    // one gone from the server can not be had: told, the others still come
    let gone = s.server.add_message("INBOX", &rfc822("Gone", "x"), &[]);
    s.core.sync(account).unwrap();
    s.wait(|e| *e == Event::SyncFinished { account, failure: None });
    s.server.expunge("INBOX", &[gone]);
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
    assert!(refused.to_string().contains("\"/\""), "{refused}");
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
    assert!(s.server.subjects("Drafts").is_empty());
    assert_eq!(s.server.subjects("INBOX"), ["Plans"]);
    let sent = pe_testkit::raw_text(&s.server.messages("INBOX")[0]);
    // the Bcc of the draft is not in what was sent
    assert!(
        !sent.contains("Bcc:") && sent.contains(&format!("Message-ID: {message_id}")),
        "{sent}"
    );
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
