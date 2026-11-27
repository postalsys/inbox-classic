//! An account that needs a sign-in or can not connect, against ImapKit's REST API: the password the server stops
//! taking (one dialog, Cancel, then only the mark, the bar and the status bar; Compose's note, and the message waiting
//! in the Outbox with the account's reason; the bar's Enter Password fixes it and the message goes), a server that resets every connection for two syncs (the gray mark, whose
//! click tries again), and an account that signs in through ImapKit's OAuth provider: its sign-in revoked, an
//! organization that wants its administrator, the browser signed in to another address, then signed in again. Every
//! account, sign-in app and rule of ImapKit is as it was afterwards.

use super::*;
use pe_core::{AccountState, SignInReason, StatusAction, TreeMark};
use serde_json::json;

/// The first account's password, as the other steps sign in with it
const PASSWORD: &str = "testpass";
const CHANGED: &str = "changed-by-the-status-step";
/// Who signs in through ImapKit's OAuth provider, and the address the browser comes back with in its place
const ALICE: &str = "alice@example.com";
const BOB: &str = "bob@example.com";
const OUTBOX_SUBJECT: &str = "Waits while the account is not signed in";

pub(super) async fn account_status(d: &Driver) {
    d.step("an account that needs a sign-in or can not connect");
    let Some(account) = shell().core.accounts().ok().and_then(|a| a.first().map(|a| a.id)) else {
        d.check(false, "there is an account to sign in");
        return;
    };
    let Some(inbox) = inbox_of(account) else {
        d.check(false, "the account has its Inbox");
        return;
    };
    shell().main().folders.select(inbox, false);
    wait_list_settled().await;
    password_refused(d, account, inbox).await;
    cannot_connect(d, account, inbox).await;
    signed_in_through_browser(d).await;
    // the first account's Inbox shown again, as the steps after expect
    shell().main().folders.select(inbox, false);
    wait_list_settled().await;
}

// ---- ImapKit and the core ----

/// A request to ImapKit's REST API, its failure a failed check
fn rest(d: &Driver, method: &str, path: &str, body: Option<Value>) {
    let body = body.map(|b| b.to_string());
    if let Err(error) = http(d.ports.rest, method, path, body.as_deref()) {
        d.check(false, &format!("ImapKit took {method} {path} ({error})"));
    }
}

/// The account's Inbox, whose row stands for the account (its Inbox alone, or under All Inboxes)
fn inbox_of(account: i64) -> Option<i64> {
    shell()
        .core
        .folders(account)
        .unwrap_or_default()
        .into_iter()
        .find(|f| pe_core::folder_name(&f.info) == "Inbox")
        .map(|f| f.id)
}

fn state(account: i64) -> AccountState {
    shell().core.account_state(account)
}

fn status(account: i64) -> pe_core::AccountStatus {
    shell().core.account_status(account).expect("the account's status")
}

/// Send/Recv, as the user asks for it, waited for to its end in every account
async fn send_receive(accounts: u64) -> bool {
    let before = shell().syncs_finished.get();
    command(Command::Sync);
    wait_until(90, || shell().syncs_finished.get() >= before + accounts).await
}

fn account_count() -> u64 {
    shell().core.accounts().map_or(1, |a| a.len() as u64)
}

/// The row `id` shows the account's mark and its tooltip as the core says them
fn marked(id: i64, status: &pe_core::AccountStatus) -> bool {
    status.mark != TreeMark::None && shell().main().folders.mark_of(id) == Some((status.mark, status.tooltip.clone()))
}

fn unmarked(id: i64) -> bool {
    shell().main().folders.mark_of(id) == Some((TreeMark::None, String::new()))
}

/// The bar over the list speaks for `account` with the core's words and button
fn bar_shows(account: i64, status: &pe_core::AccountStatus) -> bool {
    shell().main().account_bar() == (account, status.bar.clone(), status.button.clone())
}

fn bar_hidden() -> bool {
    shell().main().account_bar().0 == 0
}

/// The status bar says what the core says of all accounts, in place of Done
fn status_bar_says_state() -> bool {
    let expected = shell().core.accounts_status_text().ok().flatten();
    expected.is_some_and(|expected| shell().main().status_texts().0 == expected)
}

/// The labels of the folder tree's menu of row `id`, closed again
fn menu_of(id: i64) -> Vec<String> {
    let main = shell().main();
    let widget: gtk::Widget = main.folders.view.clone().upcast();
    main.folders.open_menu(&widget, 20.0, 20.0, id);
    let popover = main.folder_popover.borrow().clone();
    let labels = menu_labels(popover.as_ref());
    if let Some(popover) = popover {
        popover.popdown();
    }
    labels
}

/// No dialog asks again for a while (the core asks once for each kind of refusal)
async fn no_second_dialog() -> bool {
    !wait_until(5, || dialog_named("logon").is_some() || alert().is_some()).await
}

// ---- a password the server stops taking ----

async fn password_refused(d: &Driver, account: i64, inbox: i64) {
    let user = "/v1/users/testuser";
    crate::notify::SENT.with(|sent| sent.borrow_mut().clear());
    rest(d, "PUT", user, Some(json!({ "password": CHANGED })));
    // every connection signs in again, as after the computer slept
    shell().core.woke();
    command(Command::Sync);
    let logon = wait_dialog(90, "logon").await;
    d.check(
        logon.is_some(),
        "a password the server stopped taking is asked for, once",
    );
    let Some(logon) = logon else { return };
    let signed_out = wait_until(30, || {
        state(account) == AccountState::SignInNeeded(SignInReason::Refused)
    })
    .await;
    d.check(signed_out, "the account needs a sign-in");
    let status = status(account);
    d.check(
        status.action == StatusAction::EnterPassword,
        "a password account offers Enter Password",
    );
    d.check(
        wait_until(10, || marked(inbox, &status)).await,
        &format!(
            "its Inbox carries the warning mark with the core's tooltip ({})",
            status.tooltip
        ),
    );
    d.check(
        wait_until(10, || bar_shows(account, &status)).await,
        &format!(
            "the bar over the list says why, with {} ({:?})",
            status.button,
            shell().main().account_bar()
        ),
    );
    d.check(
        wait_until(20, status_bar_says_state).await,
        &format!(
            "the status bar says it in place of Done ({})",
            shell().main().status_texts().0
        ),
    );
    d.shot(&logon, "status-1-sign-in").await;
    // Cancel: no other dialog, the mark, the bar and the status bar stay
    logon.close();
    wait_gone(10, "logon").await;
    let synced = send_receive(account_count()).await;
    d.check(
        synced && no_second_dialog().await,
        "Send/Recv again fails without asking again",
    );
    d.check(
        marked(inbox, &status) && bar_shows(account, &status) && status_bar_says_state(),
        "after Cancel the mark, the bar and the status bar still say it",
    );
    d.check(
        command_enabled(Command::SignInAgain),
        "Tools > Sign In Again is on for the account",
    );
    let label = Command::SignInAgain.label().to_string();
    d.check(
        menu_of(inbox).contains(&label),
        "the account's menu in the folder list offers Sign In Again",
    );
    notified(d, &status);
    d.shot(&main_window(), "status-2-cancelled").await;
    let queued = compose_into_outbox(d, account, &status).await;

    // the right password given in the bar's Enter Password
    rest(d, "PUT", user, Some(json!({ "password": PASSWORD })));
    d.check(
        click(&main_window(), "account-bar-button"),
        "the bar's button can be clicked",
    );
    let Some(logon) = wait_dialog(20, "logon").await else {
        d.check(false, "Enter Password asks for the password");
        return;
    };
    set_text(logon.upcast_ref(), "form-0", PASSWORD);
    click(logon.upcast_ref(), "dialog-ok");
    let connected = wait_until(60, || state(account) == AccountState::Connected).await;
    d.check(connected, "with the right password the account is signed in");
    d.check(
        wait_until(20, || unmarked(inbox) && bar_hidden()).await,
        "the mark and the bar go",
    );
    let done = t!(UiDone);
    d.check(
        wait_until(30, || shell().main().status_texts().0 == done).await,
        &format!("the status bar says Done again ({})", shell().main().status_texts().0),
    );
    d.check(
        !command_enabled(Command::SignInAgain),
        "Sign In Again is off while the account is signed in",
    );
    d.shot(&main_window(), "status-7-fixed").await;
    if let Some(queued) = queued {
        outbox_sent(d, queued, inbox).await;
    }
}

/// The notification of the account that needs a sign-in: sent once while the window was not in front, in the core's
/// words
fn notified(d: &Driver, status: &pe_core::AccountStatus) {
    let sent = crate::notify::SENT.with(|sent| sent.borrow().clone());
    let expected = (status.notification_title.clone(), status.notification_text.clone());
    if main_window()
        .downcast_ref::<gtk::Window>()
        .is_some_and(|w| w.is_active())
    {
        d.write("   (the window is in front: a notification is not expected)");
        d.check(
            sent.iter().all(|s| *s == expected) && sent.len() <= 1,
            "at most one notification, in the core's words",
        );
        return;
    }
    d.check(
        sent == [expected],
        &format!("one notification says the account needs a sign-in ({sent:?})"),
    );
}

/// Compose from the account says the message will wait; sent, it waits in the Outbox with the account's reason.
/// The id of the message waiting
async fn compose_into_outbox(d: &Driver, account: i64, status: &pe_core::AccountStatus) -> Option<i64> {
    shell().new_message(account);
    let Some(c) = wait_compose(20).await else {
        d.check(false, "Create Mail opens a compose window");
        return None;
    };
    d.check(
        c.account_note() == status.compose_note,
        &format!(
            "Compose says under From that the account is not signed in ({})",
            c.account_note()
        ),
    );
    c.to.set_text("Erin <erin@example.com>");
    c.subject.set_text(OUTBOX_SUBJECT);
    c.editor.type_text("This waits until the account is signed in.");
    d.shot(&c.window, "status-8-compose").await;
    click(c.window.upcast_ref(), "compose-send");
    d.check(
        wait_until(10, || !c.window.is_visible()).await,
        "Send closes the message",
    );
    let reason = pe_core::i18n::tr_args(
        pe_core::i18n::Text::AccountStateOutboxSignIn,
        &[("account", (&shell().main().account_name(account)).into())],
    );
    let queued = wait_for(30, || {
        shell()
            .core
            .outbox()
            .ok()?
            .into_iter()
            .find(|q| q.subject == OUTBOX_SUBJECT && q.problem.as_deref() == Some(reason.as_str()))
            .map(|q| q.id)
    })
    .await;
    d.check(
        queued.is_some(),
        "the message waits in the Outbox, for the account to be signed in",
    );
    command(Command::Outbox);
    if let Some(dialog) = wait_dialog(10, "outbox-dialog").await {
        let rows: Vec<String> = descendants::<adw::ActionRow>(dialog.upcast_ref())
            .iter()
            .filter_map(|row| row.subtitle().map(|s| s.to_string()))
            .collect();
        d.check(
            rows.iter()
                .any(|r| r.contains(&reason) && !r.contains(&t!(UiOutboxStatusNotSent, reason = &reason))),
            &format!("the Outbox says why it waits, in the core's words as they are ({rows:?})"),
        );
        d.shot(&dialog, "status-9-outbox").await;
        dialog.close();
        wait_gone(10, "outbox-dialog").await;
    } else {
        d.check(false, "Tools > Outbox opens");
    }
    queued
}

/// The message that waited went once the account was signed in: it reached the server and left the Outbox; then
/// taken away again from every mailbox of the server (the Inbox it came to, Sent Items), and from the list
async fn outbox_sent(d: &Driver, queued: i64, inbox: i64) {
    let needle = format!("Subject: {OUTBOX_SUBJECT}");
    let arrived = wait_until(60, || d.find("INBOX", &needle).is_some()).await;
    let left = shell().core.outbox().is_ok_and(|q| q.iter().all(|q| q.id != queued));
    d.check(arrived && left, "signed in, the message that waited goes");
    for mailbox in d.mailboxes() {
        for message in d.messages(&mailbox) {
            if let Some(uid) = message["uid"].as_u64().filter(|_| raw_text(&message).contains(&needle)) {
                let path = format!("/v1/mailboxes/{}/messages/{uid}", mailbox.replace('/', "%2F"));
                let _ = http(d.ports.rest, "DELETE", &path, None);
            }
        }
    }
    send_receive(account_count()).await;
    let gone = wait_until(30, || {
        !listed_in_folder(inbox, 0, 500)
            .iter()
            .any(|m| m.info.subject == OUTBOX_SUBJECT)
    })
    .await;
    d.check(gone, "and is taken away again for the steps after");
}

// ---- a server that can not be reached ----

async fn cannot_connect(d: &Driver, account: i64, inbox: i64) {
    let rules = "/v1/script/rules";
    rest(d, "POST", rules, Some(json!({ "on": "greeting", "close": "reset" })));
    shell().core.woke();
    // one failed sync alone shows nothing; the second in a row does
    send_receive(account_count()).await;
    send_receive(account_count()).await;
    let down = wait_until(30, || state(account) == AccountState::CannotConnect).await;
    d.check(down, "two syncs that could not connect: the account cannot connect");
    let status = status(account);
    d.check(status.action == StatusAction::SyncNow, "it offers Try Again");
    d.check(
        wait_until(10, || marked(inbox, &status)).await,
        &format!(
            "its Inbox carries the quiet mark with the core's tooltip ({})",
            status.tooltip
        ),
    );
    d.check(
        wait_until(10, || bar_shows(account, &status)).await && status_bar_says_state(),
        "the bar and the status bar say it cannot connect",
    );
    d.check(no_second_dialog().await, "no dialog asks anything");
    d.shot(&main_window(), "status-6-cannot-connect").await;
    rest(d, "DELETE", rules, None);
    let mark = shell().main().folders.mark_button(inbox);
    d.check(mark.is_some(), "the mark is a button");
    if let Some(mark) = mark {
        mark.emit_clicked();
    }
    d.check(
        wait_until(60, || state(account) == AccountState::Connected).await,
        "a click on the mark tries again, and the account connects",
    );
    d.check(
        wait_until(20, || unmarked(inbox) && bar_hidden()).await,
        "the mark and the bar go",
    );
}

// ---- an account that signs in through the browser ----

/// A GET of `url` (http on this computer), its head and body whatever its status
fn get(url: &str) -> Result<(String, String), String> {
    let rest = url.strip_prefix("http://").ok_or("not http")?;
    let (authority, path) = rest.split_once('/').unwrap_or((rest, ""));
    let (host, port) = authority.split_once(':').ok_or_else(|| format!("no port in {url}"))?;
    let port = port.parse().map_err(|_| format!("no port in {url}"))?;
    exchange(host, port, "GET", &format!("/{path}"), None)
}

/// The browser's part of a sign-in: the provider's page (which approves at once) and its redirect back to the app
fn follow(page: &str) -> Result<(), String> {
    let (head, _) = get(page.trim())?;
    let location = head
        .lines()
        .find_map(|line| {
            let (name, value) = line.split_once(':')?;
            name.eq_ignore_ascii_case("location").then(|| value.trim().to_string())
        })
        .ok_or_else(|| format!("no redirect from the provider: {head}"))?;
    get(&location).map(|_| ())
}

/// The page the app wrote for the browser, taken (the file removed for the next sign-in)
async fn sign_in_page(d: &Driver) -> Option<String> {
    let file = d.out.join("sign-in-page.txt");
    let page = wait_for(30, || std::fs::read_to_string(&file).ok().filter(|p| !p.is_empty())).await;
    let _ = std::fs::remove_file(&file);
    page
}

/// Waits for request `request`'s event, as the dialogs do
async fn request_done(request: u64) -> bool {
    let (send, done) = async_channel::bounded(1);
    shell().watch_request(request, send);
    let answered = glib::future_with_timeout(Duration::from_secs(60), done.recv()).await;
    matches!(answered, Ok(Ok(true)))
}

/// ImapKit's OAuth provider as a sign-in app, and ALICE's account signed in with it and synced: the sign-in app and
/// the account, None when it could not be set up
async fn add_browser_account(d: &Driver) -> Option<(i64, i64)> {
    let core = &shell().core;
    let check = core.sign_in_app_check(&d.ports.oauth).ok()?;
    if !request_done(check).await {
        d.check(false, "ImapKit's OAuth provider can be read");
        return None;
    }
    let form = pe_core::SignInAppForm {
        name: "ImapKit".into(),
        issuer: format!("{}/", d.ports.oauth),
        client_id: "imapkit-approve".into(),
        scopes: "openid email profile offline_access mail".into(),
        imap_host: "127.0.0.1".into(),
        imap_port: d.ports.imaps,
        imap_security: pe_store::Security::Tls,
        smtp_host: "127.0.0.1".into(),
        smtp_port: d.ports.smtp,
        smtp_security: pe_store::Security::StartTls,
    };
    let app = core.save_sign_in_app(None, &form, pe_core::SecretChange::Keep).ok()?;
    let added = async {
        let (request, page) = core.sign_in_begin(pe_core::SignInWith::App(app), ALICE).ok()?;
        if let Err(error) = follow(&page) {
            d.write(&format!("   (the provider's page did not answer: {error})"));
            return None;
        }
        request_done(request).await.then_some(())?;
        core.add_signed_in_account(request, "").ok()
    }
    .await;
    let Some(account) = added else {
        d.check(false, "an account signs in through ImapKit's OAuth provider");
        let _ = core.remove_sign_in_app(app);
        return None;
    };
    shell().main().reload();
    let _ = core.sync(account);
    let synced = wait_until(60, || inbox_of(account).is_some()).await;
    d.check(synced, "an account signed in through the browser syncs");
    Some((app, account))
}

async fn signed_in_through_browser(d: &Driver) {
    let Some((app, alice)) = add_browser_account(d).await else {
        return;
    };
    if let Some(inbox) = inbox_of(alice) {
        revoked(d, alice, inbox).await;
    }
    // ImapKit, the account and the sign-in app as they were
    rest(d, "DELETE", "/v1/oauth/token-faults", None);
    let _ = shell().core.remove_account(alice);
    let _ = shell().core.remove_sign_in_app(app);
    shell().main().reload();
    d.check(
        wait_until(10, || shell().core.accounts().is_ok_and(|a| a.len() == 1)).await,
        "the account signed in through the browser is removed again",
    );
}

/// The sign-in revoked: one dialog, the marks and the bar; then an organization that wants its administrator, the
/// browser signed in to another address, and Try Again signing in
async fn revoked(d: &Driver, alice: i64, inbox: i64) {
    let accounts = account_count();
    shell().main().folders.select(inbox, false);
    wait_list_settled().await;
    rest(
        d,
        "POST",
        "/v1/oauth/tokens/revoke",
        Some(json!({ "user": ALICE, "type": "refresh" })),
    );
    rest(d, "POST", "/v1/oauth/tokens/expire", Some(json!({ "user": ALICE })));
    shell().core.woke();
    command(Command::Sync);
    let ask = wait_alert(90).await;
    d.check(ask.is_some(), "a revoked sign-in offers to sign in again, once");
    if let Some(ask) = ask {
        answer(&ask, "Cancel");
    }
    let refused = AccountState::SignInNeeded(SignInReason::Refused);
    d.check(
        wait_until(30, || state(alice) == refused).await,
        "the account needs a sign-in",
    );
    let status = status(alice);
    d.check(
        status.action == StatusAction::SignInAgain,
        "an account that signs in through the browser offers Sign In Again",
    );
    d.check(
        wait_until(10, || marked(inbox, &status) && marked(-alice, &status)).await,
        "its heading and its Inbox under All Inboxes carry the warning mark",
    );
    d.check(
        wait_until(10, || bar_shows(alice, &status)).await && status_bar_says_state(),
        &format!("the bar and the status bar say it ({:?})", shell().main().account_bar()),
    );
    d.check(
        send_receive(accounts).await && no_second_dialog().await,
        "Send/Recv again asks nothing",
    );
    let label = Command::SignInAgain.label().to_string();
    d.check(
        menu_of(-alice).contains(&label),
        "the account's heading menu offers Sign In Again",
    );
    // All Inboxes speaks for the account that needs a sign-in
    shell().main().folders.select(crate::folders::ALL_INBOXES, false);
    d.check(
        wait_until(10, || bar_shows(alice, &status)).await,
        "All Inboxes shows the bar of the account that needs a sign-in",
    );
    shell().main().folders.select(inbox, false);
    wait_list_settled().await;
    d.shot(&main_window(), "status-3-oauth").await;
    administrator(d, alice, accounts).await;
    other_address(d, alice, inbox).await;
}

/// The provider says the organization has not approved the app: said once, and the bar copies the administrator's
/// link
async fn administrator(d: &Driver, alice: i64, accounts: u64) {
    let faults = "/v1/oauth/token-faults";
    let fault = json!({
        "grant": "refresh_token",
        "error": "invalid_grant",
        "description": "AADSTS65001: The user or administrator has not consented to use the application.",
        "status": 400,
        "count": 100
    });
    rest(d, "POST", faults, Some(fault));
    command(Command::Sync);
    let admin = AccountState::SignInNeeded(SignInReason::AdminConsent);
    d.check(
        wait_until(90, || state(alice) == admin).await,
        "an organization that wants its administrator",
    );
    let status = status(alice);
    let told = wait_alert(30).await;
    let words = |text: &str| text.split_whitespace().collect::<Vec<_>>().join(" ");
    let said = told.as_ref().map(alert_text).unwrap_or_default();
    d.check(
        words(&said).contains(&words(&status.bar)),
        &format!("the new reason is said once, in the bar's words ({said})"),
    );
    if let Some(told) = told {
        answer(&told, "OK");
    }
    d.check(
        wait_until(10, || bar_shows(alice, &status)).await && status.action == StatusAction::CopyAdminLink,
        "the bar offers the administrator's link",
    );
    click(&main_window(), "account-bar-button");
    let copied = main_window()
        .clipboard()
        .read_text_future()
        .await
        .ok()
        .flatten()
        .map(|t| t.to_string())
        .unwrap_or_default();
    d.check(
        !status.admin_link.is_empty() && copied == status.admin_link,
        &format!("its button puts the link on the clipboard ({copied})"),
    );
    d.check(
        shell().main().status_texts().0 == t!(AccountStateAdminLinkCopied),
        "and the status bar says it was copied for the administrator",
    );
    d.shot(&main_window(), "status-4-admin").await;
    // the revoked sign-in refused again: back to Sign In Again, without a dialog
    rest(d, "DELETE", faults, None);
    send_receive(accounts).await;
    let refused = AccountState::SignInNeeded(SignInReason::Refused);
    d.check(
        wait_until(30, || state(alice) == refused).await && no_second_dialog().await,
        "the refusal again asks nothing",
    );
}

/// Sign In Again comes back signed in to another address: the bar says which, and Try Again asks the provider for
/// its account picker, which signs the account in
async fn other_address(d: &Driver, alice: i64, inbox: i64) {
    let faults = "/v1/oauth/token-faults";
    let _ = std::fs::remove_file(d.out.join("sign-in-page.txt"));
    rest(
        d,
        "POST",
        faults,
        Some(json!({ "grant": "authorization_code", "claims": { "email": BOB } })),
    );
    click(&main_window(), "account-bar-button");
    let Some(page) = sign_in_page(d).await else {
        d.check(false, "Sign In Again opens the provider's page");
        return;
    };
    d.check(follow(&page).is_ok(), "the provider's page answers");
    let other = AccountState::SignInNeeded(SignInReason::OtherAddress(BOB.into()));
    d.check(
        wait_until(30, || state(alice) == other).await,
        "the account knows which address it was",
    );
    let status = status(alice);
    d.check(
        wait_until(10, || bar_shows(alice, &status)).await
            && status.bar.contains(BOB)
            && status.bar.contains(ALICE)
            && status.action == StatusAction::SignInAgain,
        "the bar names both addresses and offers Try Again",
    );
    d.check(no_second_dialog().await, "and nothing else asks about it");
    d.shot(&main_window(), "status-5-other-address").await;
    rest(d, "DELETE", faults, None);
    click(&main_window(), "account-bar-button");
    let Some(page) = sign_in_page(d).await else {
        d.check(false, "Try Again opens the provider's page");
        return;
    };
    d.check(
        page.contains("prompt=select_account"),
        "Try Again asks the provider for its account picker",
    );
    d.check(follow(&page).is_ok(), "the provider's page answers");
    d.check(
        wait_until(60, || state(alice) == AccountState::Connected).await,
        "signed in again, the account is connected",
    );
    d.check(
        wait_until(20, || unmarked(inbox) && unmarked(-alice) && bar_hidden()).await,
        "the marks and the bar go",
    );
}
