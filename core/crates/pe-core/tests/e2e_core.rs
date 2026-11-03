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
    s.core.sync(account).unwrap();
    s.wait(|e| *e == Event::SyncFinished { account });
    let on_server = s.server.messages("INBOX");
    assert_eq!(on_server.len(), 3);
    assert!(
        on_server
            .iter()
            .all(|m| m["flags"].as_array().unwrap().contains(&json!("\\Seen"))),
        "{on_server:?}"
    );
    assert_eq!(unread(&s), 0, "the sync keeps them read");
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
    wait(&|e| *e == Event::SyncFinished { account });
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
    wait(&|e| *e == Event::SyncFinished { account });
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
    wait(&|e| *e == Event::SyncFinished { account });
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
    s.wait(|e| *e == Event::SyncFinished { account });
    let folders = s.core.folders(account).unwrap();
    let inbox = folders.iter().find(|f| f.info.path == "INBOX").unwrap().id;
    let subjects = |folder: Option<i64>, text: &str| -> Vec<String> {
        let search = pe_core::Search {
            folder,
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
        folder: None,
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

    // a copy: still in the Inbox, and in the other folder once the server has it
    s.core.copy_message(inbox, flag, archive_folder).unwrap();
    s.wait(|e| {
        *e == Event::FolderChanged {
            account,
            folder: archive_folder,
        }
    });
    assert_eq!(in_store(inbox), ["Delete me", "Flag me"]);
    eventually(&|| s.server.subjects("Archive").len() == 2);
    assert!(s.core.copy_message(inbox, flag, inbox).is_err());
    assert!(s.core.copy_message(inbox, 999_999, archive_folder).is_err());

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

    // junk: $Junk on the server and into the Junk folder; not junk: $NotJunk, back in the Inbox
    let junk = id("Junk");
    s.core.mark_junk(inbox, flag, true).unwrap();
    assert!(in_store(inbox).is_empty());
    s.wait(|e| *e == Event::FolderChanged { account, folder: junk });
    assert_eq!(in_store(junk), ["Flag me"]);
    let junk_flags = |s: &Setup| s.server.messages("Junk").first().map(|m| m["flags"].clone());
    eventually(&|| junk_flags(&s).is_some_and(|f| f.as_array().unwrap().contains(&json!("$Junk"))));
    let in_junk = s.core.messages(junk, Sort::default(), 0, 10).unwrap()[0].info.uid;
    s.core.mark_junk(junk, in_junk, false).unwrap();
    s.wait(|e| *e == Event::FolderChanged { account, folder: inbox });
    assert_eq!(in_store(inbox), ["Flag me"]);
    eventually(&|| {
        s.server.messages("INBOX").first().is_some_and(|m| {
            let flags = m["flags"].as_array().unwrap();
            flags.contains(&json!("$NotJunk")) && !flags.contains(&json!("$Junk"))
        })
    });
    assert!(s.core.mark_junk(inbox, 999_999, true).is_err());
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

#[test]
fn creates_renames_and_deletes_folders() {
    let Some(s) = setup() else { return };
    let account = s.core.add_account(&settings(&s.server), PASSWORD).unwrap();
    s.core.sync(account).unwrap();
    s.wait(|e| *e == Event::SyncFinished { account });
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
    s.wait(|e| *e == Event::SyncFinished { account });
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
    s.wait(|e| *e == Event::SyncFinished { account });
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
        s.wait(|e| *e == Event::SyncFinished { account });
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
