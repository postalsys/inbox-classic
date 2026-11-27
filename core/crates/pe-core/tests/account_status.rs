//! Whether an account is signed in and can connect, against ImapKit (core/e2e): a password the server stops taking
//! and the right one given again, a server that is busy or down for two syncs and back, IMAP turned off, and for an
//! account that signs in through the browser (ImapKit's OpenID Connect provider) a revoked sign-in signed in again, an
//! access token the server stopped taking, a provider that is down, an organization that wants its administrator, and
//! a sign-in that came back with another address.
//!
//! Skipped without Node.js and `npm ci` in core/e2e, unless PE_E2E_REQUIRED is set.

use std::sync::Arc;
use std::sync::mpsc::{Receiver, channel};

use pe_core::i18n::{Text, tr_args};
use pe_core::tree::TreeList;
use pe_core::{AccountState, Core, Event, FailureKind, Prompt, Reauthorized, SignInReason, StatusAction, TreeMark};
use pe_store::AccountId;
use pe_testkit::{ImapKit, PASSWORD, TempDir, USER, eventually, patience};
use serde_json::{Value, json};

struct Setup {
    server: ImapKit,
    core: Arc<Core>,
    events: Receiver<Event>,
    /// How many times the core asked the app for its one dialog (`AccountStateChanged` with `prompt`), in every event
    /// received so far
    asked: std::cell::Cell<usize>,
    /// What the last `Failed` said
    failed: std::cell::RefCell<String>,
    _dir: TempDir,
}

fn setup(config: Value) -> Option<Setup> {
    let server = ImapKit::start(config)?;
    let dir = TempDir::new("status");
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
    core.set_download_ahead(pe_store::Ahead::Never).unwrap();
    core.set_send_delay(0).unwrap();
    Some(Setup {
        server,
        core: Arc::new(core),
        events,
        asked: Default::default(),
        failed: Default::default(),
        _dir: dir,
    })
}

impl Setup {
    /// An event received: counted when it asks for the dialog
    fn saw(&self, event: &Event) {
        match event {
            Event::AccountStateChanged { prompt: true, .. } => self.asked.set(self.asked.get() + 1),
            Event::Failed { message, .. } => *self.failed.borrow_mut() = message.clone(),
            _ => {}
        }
    }

    /// Waits up to [`patience`] for an event `accept` takes
    fn wait(&self, accept: impl Fn(&Event) -> bool) -> Event {
        let until = std::time::Instant::now() + patience();
        loop {
            let left = until.saturating_duration_since(std::time::Instant::now());
            let event = self.events.recv_timeout(left).expect("the event in time");
            self.saw(&event);
            if accept(&event) {
                return event;
            }
        }
    }

    fn drain(&self) {
        while let Ok(event) = self.events.try_recv() {
            self.saw(&event);
        }
    }

    /// A sync the user asked for, to its end: what it failed with, and how many times the core asked for the sign-in
    /// dialog so far (this sync and the work before it, which a worker does before it takes the sync)
    fn sync(&self, account: AccountId) -> (Option<FailureKind>, usize) {
        self.drain();
        self.core.sync(account).unwrap();
        let finished = self.wait(|e| matches!(e, Event::SyncFinished { account: a, .. } if *a == account));
        let Event::SyncFinished { failure, .. } = finished else {
            unreachable!()
        };
        (failure, self.asked.get())
    }

    fn state(&self, account: AccountId) -> AccountState {
        self.core.account_state(account)
    }

    /// Waits until `account` shows `state`
    fn wait_state(&self, account: AccountId, state: AccountState) {
        eventually(|| self.state(account) == state, &format!("{state:?}"));
    }

    /// The account's title, as the folder list and the words name it
    fn title(&self, account: AccountId) -> String {
        let accounts = self.core.accounts().unwrap();
        let titles = pe_core::account_titles(&accounts);
        accounts.iter().zip(titles).find(|(a, _)| a.id == account).unwrap().1
    }

    /// The marks of the folder tree's rows that have one
    fn marks(&self) -> Vec<(pe_core::tree::TreeRowKind, AccountId, TreeMark)> {
        self.core
            .folder_tree()
            .unwrap()
            .into_iter()
            .filter(|row| row.mark != TreeMark::None)
            .map(|row| (row.kind, row.account, row.mark))
            .collect()
    }

    /// Every connection to the server dropped, as after a sleep: the next work connects (and signs in) again
    fn reconnect(&self) {
        self.core.woke();
    }
}

fn password_settings(server: &ImapKit) -> pe_store::AccountSettings {
    let mut settings = server.account_settings();
    settings.smtp_security = pe_store::Security::StartTls;
    settings
}

/// A password the server stops taking: the account needs a sign-in, said once by a dialog and meanwhile by its state
/// (the tree's mark, the status bar, the bar's words); the timer's syncs leave it alone; the right password signs it in
#[test]
fn a_refused_password_until_the_right_one_is_given() {
    let Some(s) = setup(json!({})) else { return };
    let account = s.core.add_account(&password_settings(&s.server), PASSWORD).unwrap();
    assert_eq!(s.sync(account), (None, 0));
    assert_eq!(s.state(account), AccountState::Connected);
    assert_eq!(s.core.accounts_status_text().unwrap(), None);
    assert!(s.marks().is_empty());

    // the password changed on the server
    s.server.request(
        "PUT",
        &format!("/v1/users/{USER}"),
        Some(json!({ "password": "changed" })),
    );
    s.reconnect();
    assert_eq!(s.sync(account), (Some(FailureKind::Authentication), 1));
    s.wait_state(account, AccountState::SignInNeeded(SignInReason::Refused));
    let title = s.title(account);
    let status = s.core.account_status(account).unwrap();
    assert_eq!(
        (status.action, status.prompt, status.can_sign_in_again),
        (StatusAction::EnterPassword, Prompt::Password, true)
    );
    assert!(!status.password_hint.is_empty());
    // the bar over its Inbox, and over All Inboxes, speaks for it
    let inbox = s
        .core
        .folders(account)
        .unwrap()
        .iter()
        .find(|f| f.info.path == "INBOX")
        .unwrap()
        .id;
    assert_eq!(
        s.core.status_account_for(TreeList::Folder, inbox).unwrap(),
        Some(account)
    );
    assert_eq!(
        s.core.status_account_for(TreeList::AllInboxes, 0).unwrap(),
        Some(account)
    );
    assert_eq!(
        status.bar,
        tr_args(Text::AccountStateBarRefusedPassword, &[("account", (&title).into())])
    );
    assert_eq!(
        s.core.accounts_status_text().unwrap(),
        Some(tr_args(Text::AccountStatusSignIn, &[("account", (&title).into())]))
    );
    assert_eq!(s.core.accounts_needing_sign_in(), 1);
    // one account: its Inbox carries the mark
    assert_eq!(
        s.marks(),
        [(pe_core::tree::TreeRowKind::Folder, account, TreeMark::SignIn)]
    );

    // the dialog was asked for once: the user's next sync fails without asking again, the state still says it
    assert_eq!(s.sync(account), (Some(FailureKind::Authentication), 1));
    assert!(matches!(s.state(account), AccountState::SignInNeeded(_)));
    // the timer's sync leaves it alone for now
    assert!(!s.core.sync_scheduled(account).unwrap());

    // a message sent meanwhile waits in the Outbox, which says why
    let outgoing = pe_core::Outgoing {
        to: "friend@example.com".into(),
        subject: "Written while signed out".into(),
        text: "Hello".into(),
        ..Default::default()
    };
    s.core.send(account, outgoing).unwrap();
    s.wait(|e| *e == Event::OutboxChanged { account });
    let waiting = s.core.outbox().unwrap();
    assert_eq!(waiting.len(), 1);
    assert_eq!(
        waiting[0].problem,
        Some(tr_args(Text::AccountStateOutboxSignIn, &[("account", (&title).into())]))
    );

    // a new password: its sync signs in, then the Outbox goes
    s.core.set_password(account, "changed");
    assert_eq!(s.sync(account), (None, 1));
    s.wait_state(account, AccountState::Connected);
    eventually(|| s.core.outbox().unwrap().is_empty(), "the message left the Outbox");
    assert_eq!(s.core.status_account_for(TreeList::Folder, inbox).unwrap(), None);
    assert_eq!(s.core.accounts_status_text().unwrap(), None);
    assert!(s.marks().is_empty());
    assert!(s.core.sync_scheduled(account).unwrap(), "connected: the timer syncs it");
}

/// A server that refuses the sign-in only because it is busy (`[UNAVAILABLE]`) refuses no password: the account
/// shows that it can not connect once that lasted two syncs, never asks for a sign-in, and is connected once the
/// server takes it again
#[test]
fn a_busy_server_is_no_refused_sign_in() {
    let Some(s) = setup(json!({})) else { return };
    let account = s.core.add_account(&password_settings(&s.server), PASSWORD).unwrap();
    assert_eq!(s.sync(account), (None, 0));

    let rule = json!({
        "on": "command",
        "match": "(LOGIN|AUTHENTICATE) ",
        "send": "$TAG NO [UNAVAILABLE] Try later\r\n"
    });
    s.server.request("POST", "/v1/script/rules", Some(rule));
    s.reconnect();
    assert_eq!(s.sync(account), (Some(FailureKind::Network), 0));
    assert_eq!(
        s.state(account),
        AccountState::Connected,
        "one sync alone shows nothing"
    );
    // but the status bar says what failed, in the account's name
    let failed = s.failed.borrow().clone();
    assert_eq!(
        s.core.accounts_status_text().unwrap(),
        Some(tr_args(
            Text::AccountStatusFailed,
            &[("account", (&s.title(account)).into()), ("reason", (&failed).into())]
        ))
    );
    assert_eq!(s.sync(account), (Some(FailureKind::Network), 0));
    s.wait_state(account, AccountState::CannotConnect);
    let title = s.title(account);
    assert_eq!(
        s.core.accounts_status_text().unwrap(),
        Some(tr_args(
            Text::AccountStatusCannotConnect,
            &[("account", (&title).into())]
        ))
    );
    assert_eq!(s.core.account_status(account).unwrap().action, StatusAction::SyncNow);
    assert_eq!(
        s.marks(),
        [(pe_core::tree::TreeRowKind::Folder, account, TreeMark::CannotConnect)]
    );
    assert_eq!(s.core.accounts_needing_sign_in(), 0);
    // the timer keeps trying an account that can not connect
    s.drain();
    assert!(s.core.sync_scheduled(account).unwrap());
    s.wait(|e| matches!(e, Event::SyncFinished { account: a, .. } if *a == account));

    s.server.request("DELETE", "/v1/script/rules", None);
    assert_eq!(s.sync(account), (None, 0));
    s.wait_state(account, AccountState::Connected);
}

/// A server that closes every connection at once (down) for two syncs: the account can not connect; then it is back
#[test]
fn a_server_that_is_down_and_back() {
    let Some(s) = setup(json!({})) else { return };
    let account = s.core.add_account(&password_settings(&s.server), PASSWORD).unwrap();
    assert_eq!(s.sync(account), (None, 0));
    s.server.request(
        "POST",
        "/v1/script/rules",
        Some(json!({ "on": "greeting", "close": "reset" })),
    );
    s.reconnect();
    assert_eq!(s.sync(account), (Some(FailureKind::Network), 0));
    s.sync(account);
    s.wait_state(account, AccountState::CannotConnect);
    s.server.request("DELETE", "/v1/script/rules", None);
    assert_eq!(s.sync(account), (None, 0));
    s.wait_state(account, AccountState::Connected);
}

/// The provider says IMAP is turned off for the mailbox: a sign-in is needed, and the bar's button is Help
#[test]
fn imap_turned_off_for_the_mailbox() {
    let Some(s) = setup(json!({})) else { return };
    let account = s.core.add_account(&password_settings(&s.server), PASSWORD).unwrap();
    let rule = json!({
        "on": "command",
        "match": "(LOGIN|AUTHENTICATE) ",
        "send": "$TAG NO [ALERT] Your account is not enabled for IMAP use. Please visit your Gmail settings page and enable your account for IMAP access. (Failure)\r\n"
    });
    s.server.request("POST", "/v1/script/rules", Some(rule));
    assert_eq!(s.sync(account), (Some(FailureKind::Authentication), 1));
    s.wait_state(account, AccountState::SignInNeeded(SignInReason::ImapOff));
    let status = s.core.account_status(account).unwrap();
    assert_eq!(
        (status.action, status.help_topic.as_str()),
        (StatusAction::Help, "password-not-accepted")
    );
    // the user turned it on: connected with the next sync
    s.server.request("DELETE", "/v1/script/rules", None);
    assert_eq!(s.sync(account), (None, 1));
    s.wait_state(account, AccountState::Connected);
}

const ALICE: &str = "alice@example.com";

/// An account added through ImapKit's OpenID Connect provider (a sign-in app with the client that always allows),
/// synced once
fn signed_in() -> Option<(Setup, AccountId)> {
    let config = json!({
        "users": {
            ALICE: { "password": "pw", "displayName": "Alice Example" },
            "bob@example.com": { "password": "pw" }
        },
        "oauth": {}
    });
    let s = setup(config)?;
    let issuer = s.server.oauth.clone().expect("ImapKit with its OAuth provider");
    let check = s.core.sign_in_app_check(&issuer).unwrap();
    s.wait(|e| *e == Event::SignInAppChecked { request: check });
    let form = pe_core::SignInAppForm {
        name: "ImapKit".into(),
        issuer: format!("{issuer}/"),
        client_id: "imapkit-approve".into(),
        scopes: "openid email profile offline_access mail".into(),
        imap_host: "127.0.0.1".into(),
        imap_port: s.server.imaps,
        imap_security: pe_store::Security::Tls,
        smtp_host: "127.0.0.1".into(),
        smtp_port: s.server.smtp,
        smtp_security: pe_store::Security::StartTls,
    };
    let app = s
        .core
        .save_sign_in_app(None, &form, pe_core::SecretChange::Keep)
        .unwrap();
    let (request, url) = s.core.sign_in_begin(pe_core::SignInWith::App(app), ALICE).unwrap();
    pe_testkit::oauth_follow(&url);
    s.wait(|e| *e == Event::SignInDone { request });
    let account = s.core.add_signed_in_account(request, "").unwrap();
    assert_eq!(s.sync(account), (None, 0));
    Some((s, account))
}

impl Setup {
    /// Signs `account` in again in the "browser" (Sign In Again): the page it opened, and how reauthorize ended
    fn sign_in_again(&self, account: AccountId) -> (String, pe_core::Result<Reauthorized>) {
        let (request, url) = self.core.sign_in_again_begin(account).unwrap();
        pe_testkit::oauth_follow(&url);
        self.wait(|e| *e == Event::SignInDone { request });
        (url, self.core.reauthorize(account, request))
    }

    /// The access tokens ALICE has, as ImapKit counts them
    fn access_tokens(&self) -> usize {
        let tokens = self
            .server
            .request("GET", "/v1/oauth/tokens?user=alice%40example.com&type=access", None);
        tokens.as_array().map_or(0, Vec::len)
    }

    /// The server stops taking the access tokens it gave
    fn expire_access_tokens(&self) {
        self.server
            .request("POST", "/v1/oauth/tokens/expire", Some(json!({ "user": ALICE })));
    }

    /// The token endpoint answers the next refreshes with `fault`
    fn token_fault(&self, fault: Value) {
        let mut fault = fault;
        fault["grant"] = json!("refresh_token");
        fault["count"] = json!(100);
        self.server.request("POST", "/v1/oauth/token-faults", Some(fault));
    }
}

/// An access token the server stopped taking is made again from the refresh token before anything counts as refused,
/// for IMAP and for SMTP
#[test]
fn an_access_token_the_server_stopped_taking_is_made_again() {
    let Some((s, account)) = signed_in() else { return };
    let before = s.access_tokens();
    s.expire_access_tokens();
    s.reconnect();
    assert_eq!(s.sync(account), (None, 0));
    assert_eq!(s.state(account), AccountState::Connected);
    assert!(s.access_tokens() > before);

    // SMTP too: the message goes
    s.expire_access_tokens();
    s.drain();
    let outgoing = pe_core::Outgoing {
        to: "bob@example.com".into(),
        subject: "After a token ran out".into(),
        text: "Hello".into(),
        ..Default::default()
    };
    s.core.send(account, outgoing).unwrap();
    s.wait(|e| matches!(e, Event::MessageSent { .. }));
    assert_eq!(s.state(account), AccountState::Connected);
}

/// A provider that answers its token endpoint with an error page or 503 keeps the account signed in (a connection
/// that failed); a revoked refresh token needs a sign-in, which Sign In Again gives
#[test]
fn a_revoked_sign_in_is_signed_in_again() {
    let Some((s, account)) = signed_in() else { return };

    for fault in [
        json!({ "html": true, "status": 502 }),
        json!({ "error": "temporarily_unavailable", "status": 503 }),
    ] {
        s.token_fault(fault.clone());
        s.expire_access_tokens();
        s.reconnect();
        assert_eq!(s.sync(account), (Some(FailureKind::Network), 0), "{fault}");
        assert!(!matches!(s.state(account), AccountState::SignInNeeded(_)), "{fault}");
        s.server.request("DELETE", "/v1/oauth/token-faults", None);
        assert_eq!(s.sync(account), (None, 0));
        s.wait_state(account, AccountState::Connected);
    }

    s.server.request(
        "POST",
        "/v1/oauth/tokens/revoke",
        Some(json!({ "user": ALICE, "type": "refresh" })),
    );
    s.expire_access_tokens();
    s.reconnect();
    assert_eq!(s.sync(account), (Some(FailureKind::Authentication), 1));
    s.wait_state(account, AccountState::SignInNeeded(SignInReason::Refused));
    let status = s.core.account_status(account).unwrap();
    assert_eq!(
        (status.action, status.prompt),
        (StatusAction::SignInAgain, Prompt::BrowserSignIn)
    );
    assert_eq!(
        status.bar,
        tr_args(
            Text::AccountStateBarRefusedBrowser,
            &[("account", (&s.title(account)).into()), ("provider", "ImapKit".into())]
        )
    );

    let (url, reauthorized) = s.sign_in_again(account);
    assert!(!url.contains("prompt=select_account"), "{url}");
    assert_eq!(reauthorized.unwrap(), Reauthorized::SignedIn);
    // reauthorize synced it
    s.wait_state(account, AccountState::Connected);
    assert_eq!(s.sync(account), (None, 1));
    s.wait_state(account, AccountState::Connected);
}

/// An organization that has not approved the app: only its administrator can help, with the link the state gives
#[test]
fn an_organization_that_wants_its_administrator() {
    let Some((s, account)) = signed_in() else { return };
    s.token_fault(json!({
        "error": "invalid_grant",
        "description": "AADSTS65001: The user or administrator has not consented to use the application.",
        "status": 400
    }));
    s.expire_access_tokens();
    s.reconnect();
    assert_eq!(s.sync(account), (Some(FailureKind::Authentication), 1));
    s.wait_state(account, AccountState::SignInNeeded(SignInReason::AdminConsent));
    let status = s.core.account_status(account).unwrap();
    assert_eq!(status.action, StatusAction::CopyAdminLink);
    assert_eq!(status.admin_link, pe_oauth::admin_consent_url("imapkit-approve"));
}

/// Signing in again in a browser that came back with another address: the state names it, and Try Again asks the
/// provider for its account picker
#[test]
fn a_sign_in_with_another_address() {
    let Some((s, account)) = signed_in() else { return };
    s.server.request(
        "POST",
        "/v1/script/rules",
        Some(json!({
            "on": "command",
            "match": "(LOGIN|AUTHENTICATE) ",
            "send": "$TAG NO [AUTHENTICATIONFAILED] Invalid credentials\r\n"
        })),
    );
    s.reconnect();
    s.expire_access_tokens();
    let (failure, _) = s.sync(account);
    assert_eq!(failure, Some(FailureKind::Authentication));
    s.wait_state(account, AccountState::SignInNeeded(SignInReason::Refused));

    s.server.request(
        "POST",
        "/v1/oauth/token-faults",
        Some(json!({ "grant": "authorization_code", "claims": { "email": "bob@example.com" } })),
    );
    let (_, reauthorized) = s.sign_in_again(account);
    assert_eq!(reauthorized.unwrap(), Reauthorized::OtherAddress);
    let other = AccountState::SignInNeeded(SignInReason::OtherAddress("bob@example.com".into()));
    s.wait_state(account, other.clone());
    let status = s.core.account_status(account).unwrap();
    assert_eq!(
        (status.action, status.prompt, status.can_sign_in_again),
        (StatusAction::SignInAgain, Prompt::Inform, true)
    );
    assert!(
        status.bar.contains("bob@example.com") && status.bar.contains(ALICE),
        "{}",
        status.bar
    );
    // the old sign-in refused again tells nothing new
    assert_eq!(s.sync(account), (Some(FailureKind::Authentication), 1));
    assert_eq!(s.state(account), other);

    // Try Again: the account picker, then the right account
    s.server.request("DELETE", "/v1/script/rules", None);
    let (url, reauthorized) = s.sign_in_again(account);
    assert!(url.contains("prompt=select_account"), "{url}");
    assert_eq!(reauthorized.unwrap(), Reauthorized::SignedIn);
    // the dialog was asked for once in all: another address is said by the bar alone
    assert_eq!(s.sync(account), (None, 1));
    s.wait_state(account, AccountState::Connected);
}
