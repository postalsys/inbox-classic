//! Whether each account is signed in and can connect, kept by the core while it runs (after a restart the first sync
//! of each account tells it again), with the words the apps show for it: a mark and its tooltip in the folder list, a
//! bar over the list, the status bar, a dialog and a notification, a note in Compose and the reason of a message
//! waiting in the Outbox.
//!
//! - **Connected**: the last sign-in worked, or nothing failed yet.
//! - **Sign-in needed**: the server or the provider refused the password or the sign-in ([`SignInReason`] says how,
//!   and so what the user can do). It stays until a sign-in works. Scheduled syncs ([`Core::sync_scheduled`]) skip
//!   the account for a while after the refusal ([`backoff`]: 10 minutes, 30 minutes, an hour, then every 4 hours),
//!   so a password the server refuses is not tried every 10 minutes; anything the user does tries at once. Its Outbox
//!   waits meanwhile.
//! - **Cannot connect**: the server could not be reached or the connection could not be made secure, in two syncs in
//!   a row: one failure alone (a train going through a tunnel) still shows the account as connected. Scheduled syncs
//!   go on as before.
//!
//! Every change of what an account shows comes as [`Event::AccountStateChanged`], whose `prompt` says when the apps
//! show their one dialog for it (and, while in the background, a notification): the first time each kind of refusal
//! comes after the account was last signed in or given a new password or sign-in. The apps read
//! [`Core::account_status`], [`Core::accounts_status_text`] and the folder tree again on it.

use std::collections::{HashMap, HashSet};
use std::mem::Discriminant;
use std::sync::{Arc, Mutex, MutexGuard};
use std::time::{Duration, Instant};

use pe_i18n::{Text, tr, tr_args};
use pe_store::{AccountId, FolderId};

use crate::tree::TreeList;
use crate::{Core, Event, EventSink, Result};

/// Why an account needs the user to sign in
#[derive(Debug, Clone, PartialEq, Eq)]
pub enum SignInReason {
    /// The password, or the OAuth sign-in (`invalid_grant`, a refused access token), was refused, or there is none:
    /// signing in again or a new password helps
    Refused,
    /// The account's organization has not approved Inbox Classic (Microsoft Entra AADSTS65001, 90094, 90095): only its
    /// administrator can, at [`AccountStatus::admin_link`]
    AdminConsent,
    /// The provider says IMAP is turned off for the mailbox: its settings help, not another sign-in
    ImapOff,
    /// Signing in again in the browser came back signed in to this other address, not to the account's
    OtherAddress(String),
}

/// What an account is now, as the apps show it
#[derive(Debug, Clone, PartialEq, Eq, Default)]
pub enum AccountState {
    #[default]
    Connected,
    SignInNeeded(SignInReason),
    /// The server could not be reached, in two syncs in a row
    CannotConnect,
}

/// What the bar's button (and the account menu's Sign In Again) does
#[derive(Debug, Clone, Copy, PartialEq, Eq, Default)]
pub enum StatusAction {
    /// No button (connected)
    #[default]
    None,
    /// Sign In Again: an account that signs in through the browser starts a sign-in
    /// ([`Core::sign_in_again_begin`], which asks for the provider's account picker after another address) and gives
    /// its result to [`Core::reauthorize`]
    SignInAgain,
    /// Enter Password: the password dialog (with [`AccountStatus::password_hint`]), then [`Core::set_password`] and a
    /// sync
    EnterPassword,
    /// Copy Link for Administrator: [`AccountStatus::admin_link`] to the clipboard
    CopyAdminLink,
    /// Help: the help topic [`AccountStatus::help_topic`]
    Help,
    /// Try Again while the server can not be reached: a sync now ([`Core::sync`])
    SyncNow,
}

/// The dialog an app shows when [`Event::AccountStateChanged`] says `prompt`, as the account's state asks
#[derive(Debug, Clone, Copy, PartialEq, Eq, Default)]
pub enum Prompt {
    /// None
    #[default]
    None,
    /// The password dialog (with [`AccountStatus::password_hint`]), then [`Core::set_password`] and a sync
    Password,
    /// Asks whether to sign in again in the browser (the bar's words), then as [`StatusAction::SignInAgain`]
    BrowserSignIn,
    /// The bar's words with OK, and the bar's button where it has one (the administrator's link, Help)
    Inform,
}

/// The mark of an account's rows in the folder list: its heading, its Inbox under All Inboxes, and the Inbox of the
/// only account
#[derive(Debug, Clone, Copy, PartialEq, Eq, Default)]
pub enum TreeMark {
    #[default]
    None,
    /// A warning: the account needs the user to sign in
    SignIn,
    /// The account can not connect
    CannotConnect,
}

/// An account's state with everything the apps show for it, in the language in use. Strings are empty where the
/// state has nothing to show; while connected it is [`AccountStatus::default`].
#[derive(Debug, Clone, PartialEq, Eq, Default)]
pub struct AccountStatus {
    pub state: AccountState,
    pub action: StatusAction,
    /// The dialog to show when [`Event::AccountStateChanged`] says `prompt`
    pub prompt: Prompt,
    /// Sign In Again applies (menus, Tools, Properties): the account needs a sign-in the user can give (refused,
    /// waiting for the administrator, another address), with a password or in the browser
    pub can_sign_in_again: bool,
    /// The mark of its rows in the folder list ([`TreeMark`]) and its tooltip
    pub mark: TreeMark,
    pub tooltip: String,
    /// The bar over the message list of its folders ([`Core::status_account_for`]): "Work is not signed in: Microsoft
    /// did not accept its sign-in. Its mail may be out of date."; also the words of [`Prompt::BrowserSignIn`] and
    /// [`Prompt::Inform`]
    pub bar: String,
    /// The bar's button ("Sign In Again"), empty without one
    pub button: String,
    /// A desktop notification, when `prompt` comes while the app is in the background
    pub notification_title: String,
    pub notification_text: String,
    /// Under Compose's From while this account is chosen
    pub compose_note: String,
    /// Where its organization's administrator approves Inbox Classic ([`StatusAction::CopyAdminLink`]), else empty
    pub admin_link: String,
    /// The help topic about this state (`password-not-accepted`, `no-connection`), else empty
    pub help_topic: String,
    /// Under the password field of [`Prompt::Password`]: the provider's word on app passwords, else a general one
    pub password_hint: String,
}

/// When an account a sign-in was refused for is tried by a scheduled sync again: `tries` scheduled syncs after the
/// refusal went already. 10 minutes after it, 30, an hour, then every 4 hours.
pub fn backoff(tries: u32) -> Duration {
    const MINUTE: u64 = 60;
    let minutes = match tries {
        0 => 10,
        1 => 30,
        2 => 60,
        n => 60 + 240 * u64::from(n - 2),
    };
    Duration::from_secs(minutes * MINUTE)
}

/// How many syncs in a row must fail to connect before the account shows as not connecting
pub const CANNOT_CONNECT_AFTER: u32 = 2;

/// The clock of the back-off: the system's, or a test's
pub(crate) type Clock = Arc<dyn Fn() -> Instant + Send + Sync>;

/// A refused sign-in: why, when, and how many scheduled syncs tried since
#[derive(Debug, Clone)]
struct Refused {
    reason: SignInReason,
    since: Instant,
    tries: u32,
}

#[derive(Debug, Clone, Default)]
struct Entry {
    refused: Option<Refused>,
    /// Syncs in a row that could not connect
    unreachable: u32,
    /// The kinds of refusal the dialog was asked for since the account was last signed in or given a new secret
    prompted: HashSet<Discriminant<SignInReason>>,
    /// What the last failure of its work said ([`Event::Failed`]), with when (a number that grows), until a sync goes
    /// without one
    failure: Option<(u64, String)>,
}

impl Entry {
    fn state(&self) -> AccountState {
        match &self.refused {
            Some(refused) => AccountState::SignInNeeded(refused.reason.clone()),
            None if self.unreachable >= CANNOT_CONNECT_AFTER => AccountState::CannotConnect,
            None => AccountState::Connected,
        }
    }
}

#[derive(Default)]
struct Accounts {
    entries: HashMap<AccountId, Entry>,
    /// How many accounts are not connected, and how many have a failure to tell: both 0 is the cheap path of every
    /// question the windows ask
    not_connected: usize,
    failing: usize,
    /// The number of the last failure
    failures: u64,
}

/// What an account shows to the status bar: its state, and its last failure with its number
type Shown = (AccountId, AccountState, Option<(u64, String)>);

/// The state of every account, shared by the core and its workers
pub(crate) struct Status {
    accounts: Mutex<Accounts>,
    clock: Clock,
    events: EventSink,
}

impl Status {
    pub(crate) fn new(events: EventSink) -> Status {
        Status::with_clock(events, Arc::new(Instant::now))
    }

    pub(crate) fn with_clock(events: EventSink, clock: Clock) -> Status {
        Status {
            accounts: Mutex::default(),
            clock,
            events,
        }
    }

    fn accounts(&self) -> MutexGuard<'_, Accounts> {
        self.accounts.lock().unwrap_or_else(|p| p.into_inner())
    }

    /// Changes the entry of `account`; when what it shows changed, the windows hear of it, with `prompt` when the
    /// change asks for the dialog. Whether it changed.
    fn change(&self, account: AccountId, change: impl FnOnce(&mut Entry, Instant)) -> bool {
        let now = (self.clock)();
        let (changed, prompt) = {
            let mut accounts = self.accounts();
            let entry = accounts.entries.entry(account).or_default();
            let before = entry.state();
            let had_failure = entry.failure.is_some();
            change(entry, now);
            let after = entry.state();
            let failing = entry.failure.is_some();
            // a new kind of refusal asks for the dialog once (another address is the window's own answer already)
            let prompt = match &after {
                AccountState::SignInNeeded(SignInReason::OtherAddress(_)) => false,
                AccountState::SignInNeeded(reason) if after != before => {
                    entry.prompted.insert(std::mem::discriminant(reason))
                }
                _ => false,
            };
            let was = before != AccountState::Connected;
            let is = after != AccountState::Connected;
            accounts.not_connected = accounts.not_connected + usize::from(is) - usize::from(was);
            accounts.failing = accounts.failing + usize::from(failing) - usize::from(had_failure);
            (after != before, prompt)
        };
        if changed {
            (self.events)(Event::AccountStateChanged { account, prompt });
        }
        changed
    }

    /// What `account` shows now
    pub(crate) fn state(&self, account: AccountId) -> AccountState {
        let accounts = self.accounts();
        if accounts.not_connected == 0 {
            return AccountState::Connected;
        }
        accounts
            .entries
            .get(&account)
            .map_or(AccountState::Connected, Entry::state)
    }

    /// Whether `account` needs the user to sign in
    pub(crate) fn signed_out(&self, account: AccountId) -> bool {
        matches!(self.state(account), AccountState::SignInNeeded(_))
    }

    /// Whether every account is connected
    pub(crate) fn all_connected(&self) -> bool {
        self.accounts().not_connected == 0
    }

    /// Whether every account is connected and none has a failure to tell
    fn quiet(&self) -> bool {
        let accounts = self.accounts();
        accounts.not_connected == 0 && accounts.failing == 0
    }

    /// The server took the sign-in: connected
    pub(crate) fn connected(&self, account: AccountId) {
        self.change(account, |entry, _| {
            entry.refused = None;
            entry.unreachable = 0;
            entry.prompted.clear();
        });
    }

    /// The sign-in was refused for `reason`; whether what the account shows changed. A refusal while one is shown
    /// already keeps when it began and how many scheduled syncs tried, so the back-off goes on.
    pub(crate) fn refused(&self, account: AccountId, reason: SignInReason) -> bool {
        self.change(account, |entry, now| {
            entry.unreachable = 0;
            match &mut entry.refused {
                // the old token refused again after the browser signed in to another address: the other address is
                // still what there is to know
                Some(refused)
                    if reason == SignInReason::Refused && matches!(refused.reason, SignInReason::OtherAddress(_)) => {}
                Some(refused) => refused.reason = reason,
                None => {
                    entry.refused = Some(Refused {
                        reason,
                        since: now,
                        tries: 0,
                    })
                }
            }
        })
    }

    /// A sync could not connect (the network, the server, TLS). While a sign-in is needed that stays what is shown:
    /// nothing was learned about the sign-in.
    pub(crate) fn unreachable(&self, account: AccountId) {
        self.change(account, |entry, _| {
            if entry.refused.is_none() {
                entry.unreachable = entry.unreachable.saturating_add(1);
            }
        });
    }

    /// The account was given a new password or sign-in: each kind of refusal asks for the dialog again
    pub(crate) fn secret_changed(&self, account: AccountId) {
        self.change(account, |entry, _| entry.prompted.clear());
    }

    /// Work of `account` failed, as `message` says ([`Event::Failed`]): the status bar's words for it, until a sync
    /// goes without a failure
    pub(crate) fn failed(&self, account: AccountId, message: String) {
        let number = {
            let mut accounts = self.accounts();
            accounts.failures += 1;
            accounts.failures
        };
        self.change(account, |entry, _| entry.failure = Some((number, message)));
    }

    /// A sync went without a failure: connected, nothing to tell
    pub(crate) fn synced(&self, account: AccountId) {
        self.change(account, |entry, _| {
            entry.refused = None;
            entry.unreachable = 0;
            entry.prompted.clear();
            entry.failure = None;
        });
    }

    /// Whether a scheduled sync of `account` goes now: always, but while a sign-in is needed only once the back-off
    /// since the refusal is over (and then it counts as a try)
    pub(crate) fn scheduled_due(&self, account: AccountId) -> bool {
        let now = (self.clock)();
        let mut accounts = self.accounts();
        let Some(refused) = accounts
            .entries
            .get_mut(&account)
            .and_then(|entry| entry.refused.as_mut())
        else {
            return true;
        };
        if now < refused.since + backoff(refused.tries) {
            return false;
        }
        refused.tries = refused.tries.saturating_add(1);
        true
    }

    /// The account is gone
    pub(crate) fn forget(&self, account: AccountId) {
        self.change(account, |entry, _| *entry = Entry::default());
        self.accounts().entries.remove(&account);
    }

    /// How many accounts need the user to sign in
    pub(crate) fn signed_out_count(&self) -> usize {
        let accounts = self.accounts();
        if accounts.not_connected == 0 {
            return 0;
        }
        accounts
            .entries
            .values()
            .filter(|entry| entry.refused.is_some())
            .count()
    }

    /// Each of `accounts` (in their order) with its state and its last failure, for the status bar
    fn summary_of(&self, accounts: &[AccountId]) -> Vec<Shown> {
        let all = self.accounts();
        accounts
            .iter()
            .filter_map(|id| {
                all.entries
                    .get(id)
                    .map(|entry| (*id, entry.state(), entry.failure.clone()))
            })
            .collect()
    }
}

/// How an account signs in, for the words of its state
#[derive(Debug, Clone, PartialEq, Eq)]
pub(crate) enum SignsIn {
    Password,
    /// Through the browser, at this provider ("Microsoft", "Google", a sign-in app's name)
    Browser {
        provider: String,
        microsoft: bool,
    },
}

/// The mark of a state in the folder list and its tooltip: the one table for the tree and [`AccountStatus`]
fn look(state: &AccountState) -> (TreeMark, Option<Text>) {
    match state {
        AccountState::Connected => (TreeMark::None, None),
        AccountState::CannotConnect => (TreeMark::CannotConnect, Some(Text::AccountStateTooltipCannotConnect)),
        AccountState::SignInNeeded(reason) => (
            TreeMark::SignIn,
            Some(match reason {
                SignInReason::Refused => Text::AccountStateTooltipRefused,
                SignInReason::AdminConsent => Text::AccountStateTooltipAdmin,
                SignInReason::ImapOff => Text::AccountStateTooltipImapOff,
                SignInReason::OtherAddress(_) => Text::AccountStateTooltipOtherAddress,
            }),
        ),
    }
}

/// The reason a message of the account titled `title` waits in the Outbox while it is in `state`; None while connected
fn outbox_reason(state: &AccountState, title: &str) -> Option<String> {
    let text = match state {
        AccountState::Connected => return None,
        AccountState::SignInNeeded(_) => Text::AccountStateOutboxSignIn,
        AccountState::CannotConnect => Text::AccountStateOutboxCannotConnect,
    };
    Some(tr_args(text, &[("account", title.into())]))
}

/// What the apps show for `state` of the account titled `title` (as the folder list names it), whose address is
/// `email`, signing in as `signs_in`; `client_id` is the OAuth client's, for the administrator's link
pub(crate) fn words(
    state: AccountState,
    title: &str,
    email: &str,
    signs_in: &SignsIn,
    client_id: &str,
) -> AccountStatus {
    let account = || ("account", title.into());
    let (mark, tooltip) = look(&state);
    let tooltip = tooltip.map(tr).unwrap_or_default();
    let reason = match &state {
        AccountState::Connected => return AccountStatus::default(),
        AccountState::SignInNeeded(reason) => reason,
        AccountState::CannotConnect => {
            return AccountStatus {
                state,
                action: StatusAction::SyncNow,
                mark,
                tooltip,
                bar: tr_args(Text::AccountStateBarCannotConnect, &[account()]),
                button: tr(Text::AccountStateButtonTryAgain),
                notification_title: tr_args(Text::AccountNotifyTitleCannotConnect, &[account()]),
                notification_text: tr(Text::AccountNotifyTextCannotConnect),
                compose_note: tr(Text::AccountStateComposeCannotConnect),
                help_topic: "no-connection".into(),
                ..Default::default()
            };
        }
    };
    let domain = email.rsplit_once('@').map_or("", |(_, domain)| domain);
    let provider = match signs_in {
        SignsIn::Browser { provider, .. } => provider.clone(),
        SignsIn::Password => tr(Text::AccountStateMailServer),
    };
    let browser = matches!(signs_in, SignsIn::Browser { .. });
    let (bar, notification, action, button, prompt) = match reason {
        SignInReason::Refused if browser => (
            Text::AccountStateBarRefusedBrowser,
            Text::AccountNotifyTextRefusedBrowser,
            StatusAction::SignInAgain,
            Text::AccountStateButtonSignIn,
            Prompt::BrowserSignIn,
        ),
        SignInReason::Refused => (
            Text::AccountStateBarRefusedPassword,
            Text::AccountNotifyTextRefusedPassword,
            StatusAction::EnterPassword,
            Text::AccountStateButtonPassword,
            Prompt::Password,
        ),
        SignInReason::AdminConsent => (
            Text::AccountStateBarAdmin,
            Text::AccountNotifyTextAdmin,
            StatusAction::CopyAdminLink,
            Text::AccountStateButtonAdminLink,
            Prompt::Inform,
        ),
        SignInReason::ImapOff => (
            Text::AccountStateBarImapOff,
            Text::AccountNotifyTextImapOff,
            StatusAction::Help,
            Text::AccountStateButtonHelp,
            Prompt::Inform,
        ),
        SignInReason::OtherAddress(_) => (
            Text::AccountStateBarOtherAddress,
            Text::AccountNotifyTextOtherAddress,
            StatusAction::SignInAgain,
            Text::AccountStateButtonTryAgain,
            Prompt::Inform,
        ),
    };
    let other = match reason {
        SignInReason::OtherAddress(other) => other.as_str(),
        _ => "",
    };
    let args = [
        account(),
        ("provider", (&provider).into()),
        ("domain", domain.into()),
        ("email", other.into()),
        ("expected", email.into()),
    ];
    let admin_link = match (reason, signs_in) {
        (SignInReason::AdminConsent, SignsIn::Browser { microsoft: true, .. }) => {
            pe_oauth::admin_consent_url_in(client_id, domain)
        }
        (SignInReason::AdminConsent, _) => pe_oauth::admin_consent_url(client_id),
        _ => String::new(),
    };
    let password_hint = match signs_in {
        SignsIn::Password => pe_autoconfig::app_password(email, None)
            .and_then(|hint| hint.warning)
            .map_or_else(|| tr(Text::AccountStateAppPasswordHint), str::to_string),
        SignsIn::Browser { .. } => String::new(),
    };
    AccountStatus {
        state: state.clone(),
        action,
        prompt,
        can_sign_in_again: !matches!(reason, SignInReason::ImapOff),
        mark,
        tooltip,
        bar: tr_args(bar, &args),
        button: tr(button),
        notification_title: tr_args(Text::AccountNotifyTitleSignIn, &[account()]),
        // a notification may start with the provider's name, or "the mail server" in a language that writes it small
        notification_text: crate::text::capitalized(&tr_args(notification, &args)),
        compose_note: tr(Text::AccountStateComposeSignIn),
        admin_link,
        help_topic: "password-not-accepted".into(),
        password_hint,
    }
}

/// The status bar's words for the accounts titled as `titles` says, from what each shows and its last failure: an
/// account that needs a sign-in comes first (by its title, or several counted), then those that can not connect,
/// then the latest failure ("Work: the connection to the server failed"). None when there is nothing to say.
fn summary(accounts: &[Shown], title: impl Fn(AccountId) -> String) -> Option<String> {
    let of = |want: fn(&AccountState) -> bool| -> Vec<AccountId> {
        accounts
            .iter()
            .filter(|(_, state, _)| want(state))
            .map(|(id, _, _)| *id)
            .collect()
    };
    let signed_out = of(|state| matches!(state, AccountState::SignInNeeded(_)));
    let unreachable = of(|state| *state == AccountState::CannotConnect);
    let failure = accounts
        .iter()
        .filter(|(_, state, _)| *state == AccountState::Connected)
        .filter_map(|(id, _, failure)| failure.as_ref().map(|(number, text)| (*number, *id, text)))
        .max_by_key(|(number, _, _)| *number);
    let one = |text: Text, id: AccountId| tr_args(text, &[("account", (&title(id)).into())]);
    let many = |text: Text, count: usize| tr_args(text, &[("count", count.into())]);
    Some(match (signed_out.as_slice(), unreachable.as_slice()) {
        ([id], _) => one(Text::AccountStatusSignIn, *id),
        ([_, _, ..], _) => many(Text::AccountStatusSignInMany, signed_out.len()),
        ([], [id]) => one(Text::AccountStatusCannotConnect, *id),
        ([], [_, _, ..]) => many(Text::AccountStatusCannotConnectMany, unreachable.len()),
        ([], []) => {
            let (_, id, text) = failure?;
            tr_args(
                Text::AccountStatusFailed,
                &[("account", (&title(id)).into()), ("reason", text.into())],
            )
        }
    })
}

/// What the status bar says of every account, and how many need a sign-in (the tray's and the Dock's mark)
#[derive(Debug, Clone, PartialEq, Eq, Default)]
pub struct AccountsSummary {
    /// In place of "Done": None when there is nothing to say
    pub text: Option<String>,
    pub needing_sign_in: usize,
}

impl Core {
    /// How `account` signs in, for the words of its state, and its OAuth client id
    fn signs_in(&self, account: &pe_store::Account) -> (SignsIn, String) {
        let pe_store::Auth::OAuth2(name) = &account.settings.auth else {
            return (SignsIn::Password, String::new());
        };
        let provider = self.oauth.resolve(name, &self.store(), &self.secrets);
        let client_id = provider.as_ref().map(|p| p.client_id.clone()).unwrap_or_default();
        let microsoft = provider
            .as_ref()
            .is_some_and(|p| p.kind == pe_oauth::ProviderKind::Microsoft);
        let shown = match crate::SignInWith::of_auth(name) {
            Some(crate::SignInWith::Builtin(kind)) => pe_oauth::Preset::all()
                .into_iter()
                .find(|preset| pe_oauth::ProviderKind::of_issuer(preset.issuer) == kind)
                .map(|preset| preset.name.to_string())
                .unwrap_or_default(),
            Some(crate::SignInWith::App(id)) => {
                self.store().sign_in_app(id).map(|app| app.app.name).unwrap_or_default()
            }
            None => String::new(),
        };
        let provider = if shown.trim().is_empty() {
            tr(Text::AccountStateMailServer)
        } else {
            shown
        };
        (SignsIn::Browser { provider, microsoft }, client_id)
    }

    /// Each account with its title as the folder list names it, in the accounts' order
    pub(crate) fn titles(&self) -> Result<Vec<(pe_store::Account, String)>> {
        let accounts = self.store().accounts()?;
        let titles = crate::account_titles(&accounts);
        Ok(accounts.into_iter().zip(titles).collect())
    }

    /// The state of `account` and everything the apps show for it ([`AccountStatus`]); the default while it is
    /// connected, with nothing read from the store
    pub fn account_status(&self, account: AccountId) -> Result<AccountStatus> {
        let state = self.status.state(account);
        if state == AccountState::Connected {
            return Ok(AccountStatus::default());
        }
        let (found, title) = self
            .titles()?
            .into_iter()
            .find(|(a, _)| a.id == account)
            .ok_or(crate::Error::NotFound)?;
        let (signs_in, client_id) = self.signs_in(&found);
        Ok(words(state, &title, &found.settings.email, &signs_in, &client_id))
    }

    /// The state of `account` alone, without its words: for menus
    pub fn account_state(&self, account: AccountId) -> AccountState {
        self.status.state(account)
    }

    /// The status bar's words for every account, in place of "Done": an account that needs a sign-in ("Work needs
    /// you to sign in", "2 accounts need you to sign in"), else one that can not connect, else the latest failure of
    /// a connected account's work ("Work: ...") until it syncs without one. None when there is nothing to say. The apps
    /// read it again on `AccountStateChanged`, `Failed` and `SyncFinished`.
    pub fn accounts_status_text(&self) -> Result<Option<String>> {
        Ok(self.accounts_summary()?.text)
    }

    /// [`Core::accounts_status_text`] and how many accounts need a sign-in, in one call (the tray)
    pub fn accounts_summary(&self) -> Result<AccountsSummary> {
        if self.status.quiet() {
            return Ok(AccountsSummary::default());
        }
        let titles = self.titles()?;
        let ids: Vec<AccountId> = titles.iter().map(|(a, _)| a.id).collect();
        let accounts = self.status.summary_of(&ids);
        let title = |id: AccountId| {
            titles
                .iter()
                .find(|(a, _)| a.id == id)
                .map(|(_, title)| title.clone())
                .unwrap_or_default()
        };
        Ok(AccountsSummary {
            text: summary(&accounts, title),
            needing_sign_in: self.status.signed_out_count(),
        })
    }

    /// How many accounts need the user to sign in: the tray's and the Dock's mark (nothing read from the store)
    pub fn accounts_needing_sign_in(&self) -> usize {
        self.status.signed_out_count()
    }

    /// The account the bar over the list of `list` (with `folder` for a folder's own list) speaks for: on a list of
    /// every account (All Inboxes, All Sent, All Drafts, Flagged) the first account, in the accounts' order, that needs
    /// a sign-in, else the first that can not connect; on a folder's list its account while it is not connected.
    /// None when the bar has nothing to say.
    pub fn status_account_for(&self, list: TreeList, folder: FolderId) -> Result<Option<AccountId>> {
        if self.status.all_connected() {
            return Ok(None);
        }
        match list {
            TreeList::None => Ok(None),
            TreeList::Folder => {
                let account = self.store().folder(folder)?.account_id;
                Ok((self.status.state(account) != AccountState::Connected).then_some(account))
            }
            TreeList::AllInboxes | TreeList::AllSent | TreeList::AllDrafts | TreeList::Flagged => {
                let states: Vec<(AccountId, AccountState)> = self
                    .store()
                    .accounts()?
                    .iter()
                    .map(|a| (a.id, self.status.state(a.id)))
                    .collect();
                let first = |want: fn(&AccountState) -> bool| states.iter().find(|(_, s)| want(s)).map(|(id, _)| *id);
                Ok(first(|s| matches!(s, AccountState::SignInNeeded(_)))
                    .or_else(|| first(|s| *s == AccountState::CannotConnect)))
            }
        }
    }

    /// The marks of `accounts` in the folder list and their tooltips; nothing while all are connected
    pub(crate) fn tree_marks(&self, accounts: &[AccountId]) -> crate::tree::Marks {
        if self.status.all_connected() {
            return crate::tree::Marks::new();
        }
        accounts
            .iter()
            .filter_map(|&account| {
                let (mark, tooltip) = look(&self.status.state(account));
                tooltip.map(|tooltip| (account, (mark, tr(tooltip))))
            })
            .collect()
    }

    /// The Outbox's messages with the reason each waits now: while its account is not connected that (it waits for
    /// a sign-in or a connection), else what the server said when it was tried
    pub(crate) fn with_current_reasons(&self, mut queued: Vec<pe_store::Queued>) -> Result<Vec<pe_store::Queued>> {
        if self.status.all_connected() {
            return Ok(queued);
        }
        let titles = self.titles()?;
        for message in &mut queued {
            let title = titles
                .iter()
                .find(|(a, _)| a.id == message.account_id)
                .map(|(_, title)| title.as_str())
                .unwrap_or_default();
            if let Some(reason) = outbox_reason(&self.status.state(message.account_id), title) {
                message.problem = Some(reason);
            }
        }
        Ok(queued)
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use std::sync::atomic::{AtomicU64, Ordering};

    /// A status whose clock the test moves, and the changes it told the windows about: (account, prompt)
    /// The changes told: (account, prompt)
    type Told = Arc<Mutex<Vec<(AccountId, bool)>>>;

    fn status() -> (Status, Arc<AtomicU64>, Told) {
        let start = Instant::now();
        let offset = Arc::new(AtomicU64::new(0));
        let at = offset.clone();
        let told = Arc::new(Mutex::new(Vec::new()));
        let heard = told.clone();
        let events: EventSink = Arc::new(move |event| {
            if let Event::AccountStateChanged { account, prompt } = event {
                heard.lock().unwrap().push((account, prompt));
            }
        });
        let clock: Clock = Arc::new(move || start + Duration::from_secs(at.load(Ordering::SeqCst)));
        (Status::with_clock(events, clock), offset, told)
    }

    fn minutes(clock: &AtomicU64, minutes: u64) {
        clock.fetch_add(minutes * 60, Ordering::SeqCst);
    }

    #[test]
    fn every_change_of_state_is_told_once() {
        let (status, _, told) = status();
        assert_eq!(status.state(1), AccountState::Connected);
        status.connected(1);
        assert!(told.lock().unwrap().is_empty(), "connected already");
        assert!(status.refused(1, SignInReason::Refused));
        assert_eq!(status.state(1), AccountState::SignInNeeded(SignInReason::Refused));
        assert!(
            !status.refused(1, SignInReason::Refused),
            "the same refusal again is no change"
        );
        // another reason is
        assert!(status.refused(1, SignInReason::AdminConsent));
        assert_eq!(status.state(1), AccountState::SignInNeeded(SignInReason::AdminConsent));
        status.refused(1, SignInReason::OtherAddress("bob@example.com".into()));
        let other = AccountState::SignInNeeded(SignInReason::OtherAddress("bob@example.com".into()));
        assert_eq!(status.state(1), other);
        // the old token refused again says nothing new
        status.refused(1, SignInReason::Refused);
        assert_eq!(status.state(1), other);
        // nothing learned while the server can not be reached: still signed out
        status.unreachable(1);
        status.unreachable(1);
        assert!(status.signed_out(1));
        assert_eq!(status.signed_out_count(), 1);
        status.connected(1);
        assert_eq!(status.state(1), AccountState::Connected);
        assert!(status.all_connected());
        assert_eq!(told.lock().unwrap().len(), 4);
        // another account is its own
        status.refused(2, SignInReason::ImapOff);
        assert_eq!(status.state(1), AccountState::Connected);
        assert_eq!(status.signed_out_count(), 1);
        status.forget(2);
        assert_eq!(status.state(2), AccountState::Connected);
        assert!(status.all_connected() && status.quiet());
    }

    #[test]
    fn the_dialog_once_for_each_kind_of_refusal() {
        let (status, _, told) = status();
        status.refused(1, SignInReason::Refused);
        status.refused(1, SignInReason::AdminConsent);
        // back to a kind asked for already
        status.refused(1, SignInReason::Refused);
        status.refused(1, SignInReason::ImapOff);
        assert_eq!(*told.lock().unwrap(), [(1, true), (1, true), (1, false), (1, true)]);
        // another address is the sign-in window's own answer: no dialog
        status.refused(1, SignInReason::OtherAddress("bob@example.com".into()));
        assert_eq!(told.lock().unwrap().last(), Some(&(1, false)));
        // a new password: a refusal of it asks again
        status.refused(1, SignInReason::Refused);
        status.secret_changed(1);
        status.connected(1);
        told.lock().unwrap().clear();
        status.refused(1, SignInReason::Refused);
        assert_eq!(*told.lock().unwrap(), [(1, true)]);
        status.secret_changed(1);
        status.refused(1, SignInReason::AdminConsent);
        status.refused(1, SignInReason::Refused);
        assert_eq!(
            told.lock().unwrap().last(),
            Some(&(1, true)),
            "asked again after the new secret"
        );
        // a connection that fails asks for nothing
        status.connected(1);
        told.lock().unwrap().clear();
        status.unreachable(1);
        status.unreachable(1);
        assert_eq!(*told.lock().unwrap(), [(1, false)]);
    }

    #[test]
    fn cannot_connect_once_it_lasted_two_syncs() {
        let (status, _, told) = status();
        status.unreachable(1);
        assert_eq!(
            status.state(1),
            AccountState::Connected,
            "one failure alone shows nothing"
        );
        assert!(told.lock().unwrap().is_empty());
        status.connected(1);
        status.unreachable(1);
        assert_eq!(status.state(1), AccountState::Connected, "not two in a row");
        status.unreachable(1);
        assert_eq!(status.state(1), AccountState::CannotConnect);
        status.unreachable(1);
        assert_eq!(told.lock().unwrap().len(), 1);
        assert!(!status.all_connected());
        assert_eq!(status.signed_out_count(), 0);
        // a refused sign-in says more than a connection that failed
        status.refused(1, SignInReason::Refused);
        assert!(status.signed_out(1));
        status.synced(1);
        assert_eq!(status.state(1), AccountState::Connected);
        // scheduled syncs go on while it can not connect
        status.unreachable(1);
        status.unreachable(1);
        assert!(status.scheduled_due(1) && status.scheduled_due(1));
    }

    #[test]
    fn scheduled_syncs_back_off_after_a_refusal() {
        let (status, clock, _) = status();
        assert!(status.scheduled_due(1), "connected: every scheduled sync goes");
        status.refused(1, SignInReason::Refused);
        // the times after the refusal when a scheduled sync goes: 10 minutes, 30, an hour, then every 4 hours
        let mut went = Vec::new();
        for minute in 1..=(9 * 60 + 30) {
            minutes(&clock, 1);
            // the apps' timer: every 10 minutes
            if minute % 10 == 0 && status.scheduled_due(1) {
                went.push(minute);
            }
        }
        assert_eq!(went, [10, 30, 60, 300, 540]);
        // a refusal again (the user's own sync) keeps the back-off where it is
        status.refused(1, SignInReason::Refused);
        minutes(&clock, 10);
        assert!(!status.scheduled_due(1));
        // signed in: every scheduled sync goes again
        status.connected(1);
        assert!(status.scheduled_due(1));
        status.refused(1, SignInReason::Refused);
        assert!(!status.scheduled_due(1), "a new refusal starts its own back-off");
        minutes(&clock, 10);
        assert!(status.scheduled_due(1));
    }

    #[test]
    fn the_back_off() {
        let minutes = |tries| backoff(tries).as_secs() / 60;
        assert_eq!((0..6).map(minutes).collect::<Vec<_>>(), [10, 30, 60, 300, 540, 780]);
    }

    fn browser(provider: &str, microsoft: bool) -> SignsIn {
        SignsIn::Browser {
            provider: provider.into(),
            microsoft,
        }
    }

    #[test]
    fn the_words_of_each_state() {
        pe_i18n::set_language("en");
        let work = || -> (&str, pe_i18n::Arg<'_>) { ("account", "Work".into()) };
        let refused = AccountState::SignInNeeded(SignInReason::Refused);
        let microsoft = browser("Microsoft", true);

        let status = words(refused.clone(), "Work", "ann@contoso.example", &microsoft, "client");
        assert_eq!(
            (status.action, status.prompt, status.can_sign_in_again),
            (StatusAction::SignInAgain, Prompt::BrowserSignIn, true)
        );
        assert_eq!(status.mark, TreeMark::SignIn);
        assert_eq!(
            status.bar,
            tr_args(
                Text::AccountStateBarRefusedBrowser,
                &[work(), ("provider", "Microsoft".into())]
            )
        );
        assert_eq!(status.button, tr(Text::AccountStateButtonSignIn));
        assert_eq!(status.tooltip, tr(Text::AccountStateTooltipRefused));
        assert_eq!(status.compose_note, tr(Text::AccountStateComposeSignIn));
        assert_eq!(
            status.notification_title,
            tr_args(Text::AccountNotifyTitleSignIn, &[work()])
        );
        assert!(status.admin_link.is_empty() && status.password_hint.is_empty());
        assert_eq!(status.help_topic, "password-not-accepted");

        let password = words(refused.clone(), "Home", "ann@example.org", &SignsIn::Password, "");
        assert_eq!(
            (password.action, password.prompt),
            (StatusAction::EnterPassword, Prompt::Password)
        );
        assert_eq!(password.button, tr(Text::AccountStateButtonPassword));
        assert_eq!(
            password.bar,
            tr_args(Text::AccountStateBarRefusedPassword, &[("account", "Home".into())])
        );
        assert_eq!(password.password_hint, tr(Text::AccountStateAppPasswordHint));
        // a provider that has its own word on app passwords
        let gmail = words(refused, "Gmail", "ann@gmail.com", &SignsIn::Password, "");
        let hint = pe_autoconfig::app_password("ann@gmail.com", None).unwrap();
        assert_eq!(
            gmail.password_hint,
            hint.warning
                .map_or_else(|| tr(Text::AccountStateAppPasswordHint), str::to_string)
        );

        let admin = words(
            AccountState::SignInNeeded(SignInReason::AdminConsent),
            "Work",
            "ann@contoso.example",
            &microsoft,
            "client",
        );
        assert_eq!(
            (admin.action, admin.prompt, admin.can_sign_in_again),
            (StatusAction::CopyAdminLink, Prompt::Inform, true)
        );
        assert_eq!(
            admin.admin_link,
            pe_oauth::admin_consent_url_in("client", "contoso.example")
        );
        assert_eq!(
            admin.bar,
            tr_args(
                Text::AccountStateBarAdmin,
                &[work(), ("domain", "contoso.example".into())]
            )
        );

        let off = words(
            AccountState::SignInNeeded(SignInReason::ImapOff),
            "Gmail",
            "ann@gmail.com",
            &browser("Google", false),
            "client",
        );
        assert_eq!(
            (off.action, off.prompt, off.can_sign_in_again),
            (StatusAction::Help, Prompt::Inform, false)
        );
        assert_eq!(off.button, tr(Text::AccountStateButtonHelp));
        assert_eq!(
            off.bar,
            tr_args(
                Text::AccountStateBarImapOff,
                &[("account", "Gmail".into()), ("provider", "Google".into())]
            )
        );

        let other = words(
            AccountState::SignInNeeded(SignInReason::OtherAddress("bob@contoso.example".into())),
            "Work",
            "ann@contoso.example",
            &microsoft,
            "client",
        );
        assert_eq!(
            (other.action, other.prompt, other.can_sign_in_again),
            (StatusAction::SignInAgain, Prompt::Inform, true)
        );
        assert_eq!(other.button, tr(Text::AccountStateButtonTryAgain));
        assert_eq!(
            other.bar,
            tr_args(
                Text::AccountStateBarOtherAddress,
                &[
                    work(),
                    ("email", "bob@contoso.example".into()),
                    ("expected", "ann@contoso.example".into())
                ]
            )
        );

        let unreachable = words(
            AccountState::CannotConnect,
            "Work",
            "ann@contoso.example",
            &microsoft,
            "c",
        );
        assert_eq!(
            (
                unreachable.action,
                unreachable.mark,
                unreachable.prompt,
                unreachable.can_sign_in_again
            ),
            (StatusAction::SyncNow, TreeMark::CannotConnect, Prompt::None, false)
        );
        assert_eq!(unreachable.tooltip, tr(Text::AccountStateTooltipCannotConnect));
        assert_eq!(unreachable.help_topic, "no-connection");

        let fine = words(AccountState::Connected, "Work", "ann@contoso.example", &microsoft, "c");
        assert_eq!(fine, AccountStatus::default());
    }

    #[test]
    fn the_tree_and_the_words_agree() {
        pe_i18n::set_language("en");
        for state in [
            AccountState::SignInNeeded(SignInReason::Refused),
            AccountState::SignInNeeded(SignInReason::AdminConsent),
            AccountState::SignInNeeded(SignInReason::ImapOff),
            AccountState::SignInNeeded(SignInReason::OtherAddress("b@x".into())),
            AccountState::CannotConnect,
        ] {
            let status = words(state.clone(), "W", "a@x", &SignsIn::Password, "");
            let (mark, tooltip) = look(&state);
            assert_eq!((status.mark, status.tooltip), (mark, tr(tooltip.unwrap())));
        }
    }

    #[test]
    fn the_outbox_waits_for_the_account() {
        pe_i18n::set_language("en");
        assert_eq!(outbox_reason(&AccountState::Connected, "Work"), None);
        assert_eq!(
            outbox_reason(&AccountState::SignInNeeded(SignInReason::Refused), "Work"),
            Some(tr_args(Text::AccountStateOutboxSignIn, &[("account", "Work".into())]))
        );
        assert_eq!(
            outbox_reason(&AccountState::CannotConnect, "Work"),
            Some(tr_args(
                Text::AccountStateOutboxCannotConnect,
                &[("account", "Work".into())]
            ))
        );
    }

    #[test]
    fn the_status_bar_of_all_accounts() {
        pe_i18n::set_language("en");
        let title = |id: AccountId| ["", "Work", "Home", "Gmail"][id as usize].to_string();
        let signed_out = AccountState::SignInNeeded(SignInReason::Refused);
        let fails = |n: u64, text: &str| Some((n, text.to_string()));
        assert_eq!(summary(&[(1, AccountState::Connected, None)], title), None);
        assert_eq!(
            summary(
                &[(1, signed_out.clone(), None), (2, AccountState::CannotConnect, None)],
                title
            ),
            Some(tr_args(Text::AccountStatusSignIn, &[("account", "Work".into())]))
        );
        assert_eq!(
            summary(&[(2, AccountState::CannotConnect, fails(1, "x"))], title),
            Some(tr_args(Text::AccountStatusCannotConnect, &[("account", "Home".into())]))
        );
        assert_eq!(
            summary(&[(1, signed_out.clone(), None), (2, signed_out, None)], title),
            Some(tr_args(Text::AccountStatusSignInMany, &[("count", 2.into())]))
        );
        assert_eq!(
            summary(
                &[
                    (1, AccountState::CannotConnect, None),
                    (2, AccountState::CannotConnect, None),
                    (3, AccountState::CannotConnect, None)
                ],
                title
            ),
            Some(tr_args(Text::AccountStatusCannotConnectMany, &[("count", 3.into())]))
        );
        // every account connected: the latest failure, in its account's name
        assert_eq!(
            summary(
                &[
                    (1, AccountState::Connected, fails(2, "it broke")),
                    (2, AccountState::Connected, fails(1, "older"))
                ],
                title
            ),
            Some(tr_args(
                Text::AccountStatusFailed,
                &[("account", "Work".into()), ("reason", "it broke".into())]
            ))
        );
    }

    #[test]
    fn failures_are_told_until_a_sync_goes() {
        let (status, _, told) = status();
        assert!(status.quiet());
        status.failed(1, "the server refused it".into());
        assert!(!status.quiet() && status.all_connected());
        assert!(told.lock().unwrap().is_empty(), "a failure is no change of state");
        assert_eq!(
            status.summary_of(&[1])[0].2.as_ref().map(|(_, text)| text.as_str()),
            Some("the server refused it")
        );
        status.connected(1);
        assert!(!status.quiet(), "a connection alone does not end it");
        status.synced(1);
        assert!(status.quiet());
    }
}
