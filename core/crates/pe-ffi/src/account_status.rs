//! Whether each account is signed in and can connect, with the words the apps show for it (`pe_core::status`): the
//! bar over the list and its button, the dialog and the notification, the status bar, the folder tree's marks
//! (`PeTreeRow` `mark`), Compose's note. The Outbox's rows (`pe_outbox`) carry the reason a message waits for its
//! account themselves.
//!
//! `AccountStateChanged` comes with every change, `count` 1 when the app shows its one dialog for it
//! (`PeAccountStatus` `prompt`) and, while in the background, a notification. The status bar
//! (`pe_accounts_status_text`) is read again on `AccountStateChanged`, `Failed` and `SyncFinished`.
//!
//! The syncs of the apps' timer go through `pe_sync_scheduled`, which leaves an account whose sign-in was refused
//! alone for a while; `pe_sync` is the user's and always goes.

use std::ffi::c_char;
use std::ptr::null_mut;

use pe_core::{AccountState, Prompt, Reauthorized, SignInReason, StatusAction, TreeMark};

use crate::core::{PeCore, PeTreeList, with};
use crate::{free_strings, into_c_string};

/// What an account is now
#[repr(C)]
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum PeAccountState {
    /// Signed in (or nothing failed yet): nothing to show
    Connected = 0,
    /// The user has to sign in: `reason` says why, `prompt` and `action` what to offer
    SignInNeeded = 1,
    /// The server could not be reached in two syncs in a row; the timer's syncs go on trying
    CannotConnect = 2,
}

impl From<&AccountState> for PeAccountState {
    fn from(state: &AccountState) -> Self {
        match state {
            AccountState::Connected => PeAccountState::Connected,
            AccountState::SignInNeeded(_) => PeAccountState::SignInNeeded,
            AccountState::CannotConnect => PeAccountState::CannotConnect,
        }
    }
}

/// Why an account needs a sign-in (`PeAccountState` SIGN_IN_NEEDED)
#[repr(C)]
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum PeSignInReason {
    None = 0,
    /// The password or the sign-in was refused, or there is none
    Refused = 1,
    /// The organization's administrator has to approve Inbox Classic (`admin_link`)
    AdminConsent = 2,
    /// The provider says IMAP is turned off for the mailbox
    ImapOff = 3,
    /// Signing in again came back signed in to another address (the bar names it)
    OtherAddress = 4,
}

/// What the bar's button does
#[repr(C)]
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum PeStatusAction {
    /// No button
    None = 0,
    /// The browser sign-in: `pe_sign_in_again_begin`, then on `SignInDone` `pe_account_reauthorize` (which syncs);
    /// after another address the provider shows its account picker by itself
    SignInAgain = 1,
    /// The password dialog with `password_hint`, then `pe_account_set_password` and `pe_sync`
    EnterPassword = 2,
    /// `admin_link` to the clipboard, for the organization's administrator
    CopyAdminLink = 3,
    /// The help topic `help_topic`
    Help = 4,
    /// A sync now: `pe_sync`
    SyncNow = 5,
}

/// The dialog an app shows when `AccountStateChanged` comes with `count` 1
#[repr(C)]
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum PePrompt {
    None = 0,
    /// The password dialog (with `password_hint`), then `pe_account_set_password` and `pe_sync`
    Password = 1,
    /// Asks with `bar`'s words whether to sign in again in the browser, then as `PE_STATUS_ACTION_SIGN_IN_AGAIN`
    BrowserSignIn = 2,
    /// `bar`'s words with OK, and `button` where it has one (doing `action`)
    Inform = 3,
}

/// The mark of an account's rows in the folder tree
#[repr(C)]
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum PeAccountMark {
    None = 0,
    /// A warning: the account needs a sign-in
    SignIn = 1,
    /// The account can not connect
    CannotConnect = 2,
}

impl From<TreeMark> for PeAccountMark {
    fn from(mark: TreeMark) -> Self {
        match mark {
            TreeMark::None => PeAccountMark::None,
            TreeMark::SignIn => PeAccountMark::SignIn,
            TreeMark::CannotConnect => PeAccountMark::CannotConnect,
        }
    }
}

/// An account's state and what the apps show for it, in the language in use (`pe_account_status`). Every string is
/// owned by it, never NULL (empty where the state has nothing to show, all of them while connected); free it with
/// `pe_account_status_free`.
#[repr(C)]
pub struct PeAccountStatus {
    pub state: PeAccountState,
    pub reason: PeSignInReason,
    pub action: PeStatusAction,
    /// The dialog to show when `AccountStateChanged` comes with `count` 1
    pub prompt: PePrompt,
    /// Sign In Again applies (the Tools and account menus' `IDM_SIGN_IN_AGAIN`, Properties): it needs a sign-in the
    /// user can give. It does `action`.
    pub can_sign_in_again: bool,
    /// The mark of its rows in the folder tree (as `PeTreeRow` has it) and its tooltip
    pub mark: PeAccountMark,
    pub tooltip: *mut c_char,
    /// The bar over the message list (`pe_status_account_for`), and the bar's button (empty: no button); `bar` is the
    /// text of the BROWSER_SIGN_IN and INFORM dialogs too
    pub bar: *mut c_char,
    pub button: *mut c_char,
    /// A desktop notification, when `AccountStateChanged` asks for the dialog while the app is in the background
    pub notification_title: *mut c_char,
    pub notification_text: *mut c_char,
    /// Under Compose's From while this account is chosen
    pub compose_note: *mut c_char,
    /// For COPY_ADMIN_LINK: where the organization's administrator approves Inbox Classic
    pub admin_link: *mut c_char,
    /// The help topic of this state (`pe_help_topic`), for HELP and a help link
    pub help_topic: *mut c_char,
    /// Under the password field of the PASSWORD dialog
    pub password_hint: *mut c_char,
}

/// The state of `account` and what to show for it; while it is connected (or for an unknown account, or a closed
/// core) every value is the empty default, made without reading the store. Free with `pe_account_status_free`.
///
/// # Safety
/// `core` must be a live handle.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn pe_account_status(core: *const PeCore, account: i64) -> PeAccountStatus {
    // SAFETY: as the caller guarantees
    let status = unsafe { with(core, None, |core| core.account_status(account).ok()) }.unwrap_or_default();
    let reason = match &status.state {
        AccountState::SignInNeeded(SignInReason::Refused) => PeSignInReason::Refused,
        AccountState::SignInNeeded(SignInReason::AdminConsent) => PeSignInReason::AdminConsent,
        AccountState::SignInNeeded(SignInReason::ImapOff) => PeSignInReason::ImapOff,
        AccountState::SignInNeeded(SignInReason::OtherAddress(_)) => PeSignInReason::OtherAddress,
        AccountState::Connected | AccountState::CannotConnect => PeSignInReason::None,
    };
    PeAccountStatus {
        state: (&status.state).into(),
        reason,
        action: match status.action {
            StatusAction::None => PeStatusAction::None,
            StatusAction::SignInAgain => PeStatusAction::SignInAgain,
            StatusAction::EnterPassword => PeStatusAction::EnterPassword,
            StatusAction::CopyAdminLink => PeStatusAction::CopyAdminLink,
            StatusAction::Help => PeStatusAction::Help,
            StatusAction::SyncNow => PeStatusAction::SyncNow,
        },
        prompt: match status.prompt {
            Prompt::None => PePrompt::None,
            Prompt::Password => PePrompt::Password,
            Prompt::BrowserSignIn => PePrompt::BrowserSignIn,
            Prompt::Inform => PePrompt::Inform,
        },
        can_sign_in_again: status.can_sign_in_again,
        mark: status.mark.into(),
        tooltip: into_c_string(status.tooltip),
        bar: into_c_string(status.bar),
        button: into_c_string(status.button),
        notification_title: into_c_string(status.notification_title),
        notification_text: into_c_string(status.notification_text),
        compose_note: into_c_string(status.compose_note),
        admin_link: into_c_string(status.admin_link),
        help_topic: into_c_string(status.help_topic),
        password_hint: into_c_string(status.password_hint),
    }
}

/// Frees the strings of a [`PeAccountStatus`]
///
/// # Safety
/// `status` must come from `pe_account_status`, freed once.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn pe_account_status_free(status: PeAccountStatus) {
    // SAFETY: as the caller guarantees
    unsafe {
        free_strings(&[
            status.tooltip,
            status.bar,
            status.button,
            status.notification_title,
            status.notification_text,
            status.compose_note,
            status.admin_link,
            status.help_topic,
            status.password_hint,
        ])
    }
}

/// The state of `account` alone, with no strings and nothing read from the store: for menus
///
/// # Safety
/// `core` must be a live handle.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn pe_account_state(core: *const PeCore, account: i64) -> PeAccountState {
    // SAFETY: as the caller guarantees
    unsafe {
        with(core, PeAccountState::Connected, |core| {
            (&core.account_state(account)).into()
        })
    }
}

/// The status bar's words for every account, in place of "Done": an account that needs a sign-in ("Work needs you
/// to sign in", "2 accounts need you to sign in"), else one that can not connect, else the latest failure of a
/// connected account's work ("Work: ...") until it syncs without one. NULL when there is nothing to say. Read it
/// again on `AccountStateChanged`, `Failed` and `SyncFinished`. Free with `pe_string_free`.
///
/// # Safety
/// `core` must be a live handle.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn pe_accounts_status_text(core: *const PeCore) -> *mut c_char {
    // SAFETY: as the caller guarantees
    let text = unsafe { with(core, None, |core| core.accounts_status_text().ok().flatten()) };
    text.map_or(null_mut(), into_c_string)
}

/// `pe_accounts_status_text` and how many accounts need a sign-in (into `needing_sign_in` when it is not NULL), in
/// one call: the tray's tooltip and mark
///
/// # Safety
/// `core` must be a live handle, `needing_sign_in` NULL or a valid pointer.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn pe_accounts_summary(core: *const PeCore, needing_sign_in: *mut u32) -> *mut c_char {
    // SAFETY: as the caller guarantees
    let summary = unsafe { with(core, None, |core| core.accounts_summary().ok()) }.unwrap_or_default();
    if !needing_sign_in.is_null() {
        // SAFETY: the caller gave a valid pointer
        unsafe { *needing_sign_in = summary.needing_sign_in as u32 };
    }
    summary.text.map_or(null_mut(), into_c_string)
}

/// How many accounts need the user to sign in: a mark on the tray icon or the Dock while above 0
///
/// # Safety
/// `core` must be a live handle.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn pe_accounts_needing_sign_in(core: *const PeCore) -> u32 {
    // SAFETY: as the caller guarantees
    unsafe { with(core, 0, |core| core.accounts_needing_sign_in() as u32) }
}

/// The account the bar over the message list speaks for (its `pe_account_status` `bar` and `button`), the list being
/// a tree row's (`PeTreeRow` `list` and `folder`): on a list of every account (All Inboxes, All Sent, All Drafts,
/// Flagged) the first account that needs a sign-in, else the first that can not connect; on a folder's list its own
/// account while it is not connected. 0 when there is no bar. Read it again on `AccountStateChanged` and when the
/// list changes.
///
/// # Safety
/// `core` must be a live handle.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn pe_status_account_for(core: *const PeCore, list: PeTreeList, folder: i64) -> i64 {
    // SAFETY: as the caller guarantees
    unsafe {
        with(core, 0, |core| {
            core.status_account_for(list.into(), folder).ok().flatten().unwrap_or(0)
        })
    }
}

/// The sync of the apps' timer (every 10 minutes): as `pe_sync`, but an account whose sign-in was refused is synced
/// only once the back-off since the refusal is over (10 minutes, 30, an hour, then every 4 hours). True when the sync
/// was started, false when it was skipped for that, or failed.
///
/// # Safety
/// `core` must be a live handle.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn pe_sync_scheduled(core: *const PeCore, account: i64) -> bool {
    // SAFETY: as the caller guarantees
    unsafe { with(core, false, |core| core.sync_scheduled(account).unwrap_or(false)) }
}

/// Starts signing in again for `account`, which signs in through the browser, with its own provider and address
/// (Sign In Again, Try Again): `url` gets the page to open in the browser (free it with `pe_string_free`), and
/// `SignInDone` with the returned request in `uid` follows; answer it with `pe_account_reauthorize`. After the browser
/// signed in to another address the provider is asked for its account picker. 0 on failure, and for an account with
/// a password.
///
/// # Safety
/// `core` must be a live handle, `url` a valid pointer.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn pe_sign_in_again_begin(core: *const PeCore, account: i64, url: *mut *mut c_char) -> u64 {
    if url.is_null() {
        return 0;
    }
    // SAFETY: as the caller guarantees
    let started = unsafe { with(core, None, |core| core.sign_in_again_begin(account).ok()) };
    let Some((request, page)) = started else {
        return 0;
    };
    // SAFETY: the caller gave a valid pointer
    unsafe { *url = into_c_string(page) };
    request
}

/// How `pe_account_reauthorize` ended
#[repr(C)]
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum PeReauthorized {
    /// It did not: `error` says why
    Failed = 0,
    /// The account has the new sign-in and syncs with it (the core started the sync)
    SignedIn = 1,
    /// The browser signed in to another address: the account's state says so (its bar, `AccountStateChanged`), so
    /// the app says nothing more
    OtherAddress = 2,
}

/// Gives an account signed in through the browser the result of the finished sign-in `request` (Sign In Again), and
/// syncs it. FAILED with the reason in `error` (NULL or a pointer to a string to free with `pe_string_free`).
///
/// # Safety
/// `core` must be a live handle, `error` NULL or a valid pointer.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn pe_account_reauthorize(
    core: *const PeCore,
    account: i64,
    request: u64,
    error: *mut *mut c_char,
) -> PeReauthorized {
    // SAFETY: as the caller guarantees
    let outcome = unsafe { with(core, None, |core| Some(core.reauthorize(account, request))) };
    let why = match outcome {
        Some(Ok(Reauthorized::SignedIn)) => return PeReauthorized::SignedIn,
        Some(Ok(Reauthorized::OtherAddress)) => return PeReauthorized::OtherAddress,
        Some(Err(why)) => why.to_string(),
        None => "the sign-in could not be used".to_string(),
    };
    if !error.is_null() {
        // SAFETY: the caller gave a valid pointer
        unsafe { *error = into_c_string(why) };
    }
    PeReauthorized::Failed
}
