//! The mail engine through C: a `PeCore` handle, lists of rows, the message view, and events
//! delivered to a callback.
//!
//! Rows are `repr(C)` structs whose strings belong to the list or view they came from: they stay
//! valid until that is freed. Functions that fail return NULL, 0 or false.

use std::ffi::{CStr, CString, c_char, c_void};
use std::ptr::{null, null_mut};

use pe_core::unsubscribe::Unsubscribe;
use pe_core::{Core, DraftKind, Event, FailureKind, Outgoing, SignInWith};
use pe_imap::SpecialUse;
use pe_store::{AccountSettings, Security, Sort, SortField};

use crate::{c_string, guard, ids, into_c_string};

/// Owns the strings of rows handed to C
#[derive(Default)]
pub(crate) struct Strings(Vec<CString>);

impl Strings {
    /// A C string that lives as long as `self`; NUL inside is replaced
    pub(crate) fn add(&mut self, text: &str) -> *const c_char {
        let text = c_string(text.to_string());
        // the bytes are on the heap, moving the CString into the Vec does not move them
        let pointer = text.as_ptr();
        self.0.push(text);
        pointer
    }
}

/// The rows of a list handed to C, with the strings they point to
pub(crate) struct Rows<T> {
    rows: Vec<T>,
    _strings: Strings,
}

impl<T> Rows<T> {
    pub(crate) fn new<S>(items: &[S], mut row: impl FnMut(&S, &mut Strings) -> T) -> Self {
        let mut strings = Strings::default();
        let rows = items.iter().map(|item| row(item, &mut strings)).collect();
        Rows {
            rows,
            _strings: strings,
        }
    }

    pub(crate) fn count(list: Option<&Self>) -> usize {
        list.map_or(0, |list| list.rows.len())
    }

    pub(crate) fn get(list: Option<&Self>, index: usize) -> *const T {
        list.and_then(|list| list.rows.get(index)).map_or(null(), |row| row)
    }
}

/// Moves a value to C
pub(crate) fn handed<T>(value: T) -> *mut T {
    Box::into_raw(Box::new(value))
}

/// Frees what [`handed`] gave C
///
/// # Safety
/// `value` must be NULL or from [`handed`], freed once.
pub(crate) unsafe fn take_back<T>(value: *mut T) {
    if !value.is_null() {
        // SAFETY: as the caller guarantees
        drop(unsafe { Box::from_raw(value) });
    }
}

/// Reads a C string argument; None for NULL or invalid UTF-8
///
/// # Safety
/// `text` must be NULL or a NUL-terminated string.
pub(crate) unsafe fn arg<'a>(text: *const c_char) -> Option<&'a str> {
    if text.is_null() {
        return None;
    }
    // SAFETY: the caller guarantees a NUL-terminated string
    unsafe { CStr::from_ptr(text) }.to_str().ok()
}

// ---- events ----

#[repr(C)]
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum PeEventKind {
    SyncStarted = 1,
    /// Comes after everything the sync found, failures included; `failure` is what kept it from finishing, `None`
    /// when it did (the account is online)
    SyncFinished = 2,
    /// The folder list of `account` changed
    FoldersChanged = 3,
    /// The messages of `folder` or their flags changed
    FolderChanged = 4,
    /// `pe_message_view` can show `folder`/`uid` now
    MessageReady = 5,
    /// Work for `account` failed: `failure` and `message` say what
    Failed = 6,
    /// A message from `account` was sent; `message` is its subject
    MessageSent = 7,
    /// The lookup `uid` of `pe_autoconfig_start` is done: `pe_autoconfig_result`
    AutoconfigDone = 8,
    /// The sign-in `uid` of `pe_sign_in_begin` finished: `pe_sign_in_result`
    SignInDone = 9,
    /// The view `uid` of `pe_message_view_start` is built: `pe_message_view_result`
    ViewReady = 10,
    /// The Outbox of `account` changed: a message went in or out, or did not go: `pe_outbox`
    OutboxChanged = 11,
    /// The draft whose Message-ID is `detail` is in the Drafts of `account` on the server; when `message` is not
    /// NULL it was not saved, and that says why
    DraftSaved = 12,
    /// The check `uid` of `pe_sign_in_app_check` is done: `pe_sign_in_app_check_result`
    SignInAppChecked = 13,
    /// New unread mail in the Inbox `folder` of `account`: `count` messages, `uid` the newest, `message` who it is
    /// from and `detail` its subject
    NewMail = 14,
    /// The unsubscribe `uid` of `pe_unsubscribe` is done; `message` says why not when it is not NULL
    Unsubscribed = 15,
    /// The logo `uid` of `pe_logo_start` is drawn, or there was none: `pe_logo_result`
    LogoReady = 16,
    /// `folder`/`uid` (opened with `pe_message_open`) could not be downloaded: `failure` and `message` say why, for
    /// `pe_reader_page`. Opening it again tries again
    MessageFailed = 17,
    /// An AI agent needs the user to answer question `uid`: `pe_agent_ask_kind`
    AgentAsk = 18,
    /// What AI agents did changed: `pe_agent_log`
    AgentLogChanged = 19,
    /// Messages are going to another account: `message` says how far ("Moving 3 of 12 messages to Archive..."), and at
    /// the end what was done ("Moved 12 messages to Archive")
    Transferring = 20,
    /// The folder `folder` of `account` made with `pe_folder_create` is there (to choose it in the window that made it)
    FolderCreated = 21,
}

#[repr(C)]
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum PeFailureKind {
    None = 0,
    /// Not reachable now, try again later
    Network = 1,
    /// TLS failed
    Security = 2,
    /// The password was refused, or there is none
    Authentication = 3,
    Other = 4,
}

impl From<PeFailureKind> for FailureKind {
    fn from(kind: PeFailureKind) -> Self {
        match kind {
            PeFailureKind::Network => FailureKind::Network,
            PeFailureKind::Security => FailureKind::Security,
            PeFailureKind::Authentication => FailureKind::Authentication,
            PeFailureKind::None | PeFailureKind::Other => FailureKind::Other,
        }
    }
}

impl From<FailureKind> for PeFailureKind {
    fn from(kind: FailureKind) -> Self {
        match kind {
            FailureKind::Network => PeFailureKind::Network,
            FailureKind::Security => PeFailureKind::Security,
            FailureKind::Authentication => PeFailureKind::Authentication,
            FailureKind::Other => PeFailureKind::Other,
        }
    }
}

/// An event; valid only during the callback
#[repr(C)]
pub struct PeEvent {
    pub kind: PeEventKind,
    pub account: i64,
    pub folder: i64,
    pub uid: u64,
    pub failure: PeFailureKind,
    /// UTF-8: why, for `Failed`; the subject, for `MessageSent`; why not, for a `DraftSaved` that did not save; who
    /// it is from, for `NewMail`; how far it is or what was done, for `Transferring`. NULL otherwise
    pub message: *const c_char,
    /// UTF-8: the Message-ID of the draft, for `DraftSaved`; the subject, for `NewMail`. NULL otherwise
    pub detail: *const c_char,
    /// How many messages, for `NewMail`; 0 otherwise
    pub count: u64,
}

/// Called on a worker thread, never on the thread that called into the core: copy what is
/// needed and post it to the window thread. It must not throw (make it `noexcept`), wait for
/// the window thread, or call `pe_core_close`.
pub type PeEventCallback = Option<unsafe extern "C" fn(context: *mut c_void, event: *const PeEvent)>;

struct Callback {
    function: unsafe extern "C" fn(*mut c_void, *const PeEvent),
    context: *mut c_void,
}

// SAFETY: the C side promises a callback and context that may be used from any thread
unsafe impl Send for Callback {}
// SAFETY: as above
unsafe impl Sync for Callback {}

impl Callback {
    fn deliver(&self, event: Event) {
        let (kind, account, folder, uid) = match &event {
            Event::SyncStarted { account } => (PeEventKind::SyncStarted, *account, 0, 0),
            Event::SyncFinished { account, .. } => (PeEventKind::SyncFinished, *account, 0, 0),
            Event::FoldersChanged { account } => (PeEventKind::FoldersChanged, *account, 0, 0),
            Event::FolderChanged { account, folder } => (PeEventKind::FolderChanged, *account, *folder, 0),
            Event::MessageReady { folder, uid } => (PeEventKind::MessageReady, 0, *folder, *uid),
            Event::Failed { account, .. } => (PeEventKind::Failed, *account, 0, 0),
            Event::MessageSent { account, .. } => (PeEventKind::MessageSent, *account, 0, 0),
            Event::DraftSaved { account, .. } => (PeEventKind::DraftSaved, *account, 0, 0),
            Event::AutoconfigDone { request } => (PeEventKind::AutoconfigDone, 0, 0, *request),
            Event::SignInDone { request } => (PeEventKind::SignInDone, 0, 0, *request),
            Event::SignInAppChecked { request } => (PeEventKind::SignInAppChecked, 0, 0, *request),
            Event::ViewReady { request } => (PeEventKind::ViewReady, 0, 0, *request),
            Event::OutboxChanged { account } => (PeEventKind::OutboxChanged, *account, 0, 0),
            Event::NewMail {
                account, folder, uid, ..
            } => (PeEventKind::NewMail, *account, *folder, *uid),
            Event::Unsubscribed { request, .. } => (PeEventKind::Unsubscribed, 0, 0, *request),
            Event::LogoReady { request } => (PeEventKind::LogoReady, 0, 0, *request),
            Event::MessageFailed { folder, uid, .. } => (PeEventKind::MessageFailed, 0, *folder, *uid),
            Event::AgentAsk { request } => (PeEventKind::AgentAsk, 0, 0, *request),
            Event::AgentLogChanged => (PeEventKind::AgentLogChanged, 0, 0, 0),
            Event::Transferring { .. } => (PeEventKind::Transferring, 0, 0, 0),
            Event::FolderCreated { account, folder } => (PeEventKind::FolderCreated, *account, *folder, 0),
        };
        let count = if let Event::NewMail { count, .. } = &event {
            *count as u64
        } else {
            0
        };
        let (failure, message, detail) = match event {
            Event::Failed { kind, message, .. } => (kind.into(), Some(c_string(message)), None),
            Event::MessageSent { subject, .. } => (PeFailureKind::None, Some(c_string(subject)), None),
            Event::DraftSaved {
                message_id, problem, ..
            } => (PeFailureKind::None, problem.map(c_string), Some(c_string(message_id))),
            Event::NewMail { from, subject, .. } => {
                (PeFailureKind::None, Some(c_string(from)), Some(c_string(subject)))
            }
            Event::Unsubscribed { problem, .. } => (PeFailureKind::None, problem.map(c_string), None),
            Event::MessageFailed { kind, message, .. } => (kind.into(), Some(c_string(message)), None),
            Event::SyncFinished { failure, .. } => (failure.map_or(PeFailureKind::None, Into::into), None, None),
            Event::Transferring { text } => (PeFailureKind::None, Some(c_string(text)), None),
            _ => (PeFailureKind::None, None, None),
        };
        let event = PeEvent {
            kind,
            account,
            folder,
            uid,
            failure,
            message: message.as_ref().map_or(null(), |m| m.as_ptr()),
            detail: detail.as_ref().map_or(null(), |d| d.as_ptr()),
            count,
        };
        // a panic must not unwind into C; the callback must not throw (see PeEventCallback)
        let _ = guard(|| {
            // SAFETY: the C side gave a valid callback; the event and its message live for the call
            unsafe { (self.function)(self.context, &event) }
        });
    }
}

// ---- the engine ----

/// The mail engine
pub struct PeCore {
    pub(crate) core: std::sync::Arc<Core>,
    /// The store's file, which names where agents reach this app
    pub(crate) store: std::path::PathBuf,
    /// The MCP server, once `pe_mcp_start` started it
    pub(crate) mcp: std::sync::Mutex<Option<pe_mcp::McpServer>>,
}

impl Drop for PeCore {
    fn drop(&mut self) {
        // the server lets go of the engine first, so the engine stops here, on this thread
        if let Some(mut mcp) = self.mcp.lock().unwrap_or_else(|p| p.into_inner()).take() {
            mcp.stop();
        }
    }
}

/// Opens the store at `path` (UTF-8, created when missing) and starts the engine. `callback` gets
/// the events, on worker threads, with `context`. NULL on failure. Close with `pe_core_close`.
///
/// # Safety
/// `path` must be a NUL-terminated string. `callback` and `context` must be usable from any
/// thread until `pe_core_close` returns.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn pe_core_open(
    path: *const c_char,
    callback: PeEventCallback,
    context: *mut c_void,
) -> *mut PeCore {
    // SAFETY: as the caller guarantees
    unsafe { pe_core_open_with(path, 0, null(), callback, context) }
}

/// For `pe_core_open_with`: passwords and sign-ins are kept for this run only, not in the Credential Manager
/// (test runs, a shared computer)
pub const PE_OPEN_MEMORY_PASSWORDS: u32 = 1;

/// Like `pe_core_open`, with `PE_OPEN_*` flags. When `certificate_file` is not NULL, every server is checked
/// against the certificates in that file (PEM or DER) instead of the ones Windows trusts: for test servers. NULL when that file has no certificate.
///
/// # Safety
/// As `pe_core_open`; `certificate_file` is NULL or a NUL-terminated string.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn pe_core_open_with(
    path: *const c_char,
    flags: u32,
    certificate_file: *const c_char,
    callback: PeEventCallback,
    context: *mut c_void,
) -> *mut PeCore {
    // SAFETY: as the caller guarantees
    let Some(path) = (unsafe { arg(path) }) else {
        return null_mut();
    };
    let trust = if certificate_file.is_null() {
        pe_net::Trust::Platform
    } else {
        // SAFETY: as the caller guarantees
        match unsafe { arg(certificate_file) }.and_then(|file| pe_net::Trust::pinned_file(file.as_ref())) {
            Some(pinned) => pinned,
            None => return null_mut(),
        }
    };
    let passwords = if flags & PE_OPEN_MEMORY_PASSWORDS != 0 {
        pe_core::PasswordStore::Memory
    } else {
        pe_core::PasswordStore::System
    };
    open(path, trust, passwords, callback, context)
}

fn open(
    path: &str,
    trust: pe_net::Trust,
    passwords: pe_core::PasswordStore,
    callback: PeEventCallback,
    context: *mut c_void,
) -> *mut PeCore {
    guard(|| {
        let callback = callback.map(|function| Callback { function, context });
        let options = pe_core::Options {
            trust,
            passwords,
            oauth_providers: Vec::new(),
        };
        let core = Core::open_with(path, options, move |event| {
            if let Some(callback) = &callback {
                callback.deliver(event);
            }
        });
        core.map_or(null_mut(), |core| {
            handed(PeCore {
                core: std::sync::Arc::new(core),
                store: std::path::PathBuf::from(path),
                mcp: std::sync::Mutex::new(None),
            })
        })
    })
    .unwrap_or(null_mut())
}

/// Stops the engine: work that waits for the network is cancelled, after at most two seconds.
/// NULL is ignored. No event starts after it returns.
///
/// # Safety
/// `core` must be NULL or from `pe_core_open`, and not used after.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn pe_core_close(core: *mut PeCore) {
    let _ = guard(|| {
        // SAFETY: as the caller guarantees
        unsafe { take_back(core) }
    });
}

/// Runs `f` on the core, `fallback` when it is NULL or `f` panics
///
/// # Safety
/// `core` must be NULL or a live handle from `pe_core_open`.
pub(crate) unsafe fn with<T>(core: *const PeCore, fallback: T, f: impl FnOnce(&Core) -> T) -> T {
    // SAFETY: the caller guarantees a live handle
    let Some(core) = (unsafe { core.as_ref() }) else {
        return fallback;
    };
    guard(|| f(&core.core)).unwrap_or(fallback)
}

// ---- accounts ----

#[repr(C)]
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum PeSecurity {
    /// TLS from the start (993, 465)
    Tls = 0,
    /// STARTTLS, required
    StartTls = 1,
    /// No encryption: test servers only
    Plain = 2,
}

impl From<Security> for PeSecurity {
    fn from(value: Security) -> Self {
        match value {
            Security::Tls => PeSecurity::Tls,
            Security::StartTls => PeSecurity::StartTls,
            Security::Plain => PeSecurity::Plain,
        }
    }
}

impl From<PeSecurity> for Security {
    fn from(value: PeSecurity) -> Self {
        match value {
            PeSecurity::Tls => Security::Tls,
            PeSecurity::StartTls => Security::StartTls,
            PeSecurity::Plain => Security::Plain,
        }
    }
}

/// Account settings; strings are UTF-8
#[repr(C)]
pub struct PeAccountSettings {
    pub name: *const c_char,
    pub email: *const c_char,
    pub username: *const c_char,
    pub imap_host: *const c_char,
    pub imap_port: u16,
    pub imap_security: PeSecurity,
    pub smtp_host: *const c_char,
    pub smtp_port: u16,
    pub smtp_security: PeSecurity,
}

/// # Safety
/// `settings` must be NULL or point to settings whose strings are NUL-terminated.
unsafe fn settings(settings: *const PeAccountSettings) -> Option<AccountSettings> {
    // SAFETY: as the caller guarantees
    let s = unsafe { settings.as_ref() }?;
    // SAFETY: as the caller guarantees
    let text = |p| unsafe { arg(p) }.map(str::to_string);
    Some(AccountSettings {
        name: text(s.name)?,
        email: text(s.email)?,
        username: text(s.username)?,
        imap_host: text(s.imap_host)?,
        imap_port: s.imap_port,
        imap_security: s.imap_security.into(),
        smtp_host: text(s.smtp_host)?,
        smtp_port: s.smtp_port,
        smtp_security: s.smtp_security.into(),
        auth: pe_store::Auth::Password,
    })
}

/// Adds an account; its id, or 0 on failure. The password is kept in memory for this run.
///
/// # Safety
/// `core` must be a live handle, `settings` valid settings, `password` a NUL-terminated string.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn pe_account_add(
    core: *const PeCore,
    settings: *const PeAccountSettings,
    password: *const c_char,
) -> i64 {
    // SAFETY: as the caller guarantees
    let (Some(settings), Some(password)) = (unsafe { self::settings(settings) }, unsafe { arg(password) }) else {
        return 0;
    };
    // SAFETY: as the caller guarantees
    unsafe { with(core, 0, |core| core.add_account(&settings, password).unwrap_or(0)) }
}

/// The signature of an account as sanitized HTML, for the signature editor; an empty string for none, NULL for no such
/// account. Free with `pe_string_free`.
///
/// # Safety
/// `core` must be a live handle.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn pe_account_signature(core: *const PeCore, account: i64) -> *mut c_char {
    // SAFETY: as the caller guarantees
    unsafe {
        with(core, null_mut(), |core| {
            core.signature(account).map_or(null_mut(), into_c_string)
        })
    }
}

/// Keeps `html` (sanitized again) as the signature of an account; empty for none
///
/// # Safety
/// `core` must be a live handle, `html` NULL or a NUL-terminated string.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn pe_account_set_signature(core: *const PeCore, account: i64, html: *const c_char) -> bool {
    // SAFETY: as the caller guarantees
    let html = unsafe { arg(html) }.unwrap_or_default().to_string();
    // SAFETY: as the caller guarantees
    unsafe { with(core, false, |core| core.set_signature(account, &html).is_ok()) }
}

/// What a new message, reply or forward from an account starts with in the editor: an empty line, then the signature
/// in a block the editor can swap for another account's; an empty string without a signature. Free with
/// `pe_string_free`.
///
/// # Safety
/// `core` must be a live handle.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn pe_signature_block(core: *const PeCore, account: i64) -> *mut c_char {
    // SAFETY: as the caller guarantees
    unsafe {
        with(core, null_mut(), |core| {
            core.signature_block(account).map_or(null_mut(), into_c_string)
        })
    }
}

/// Changes the settings of an account
///
/// # Safety
/// `core` must be a live handle, `settings` valid settings.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn pe_account_update(
    core: *const PeCore,
    account: i64,
    settings: *const PeAccountSettings,
) -> bool {
    // SAFETY: as the caller guarantees
    let Some(settings) = (unsafe { self::settings(settings) }) else {
        return false;
    };
    // SAFETY: as the caller guarantees
    unsafe { with(core, false, |core| core.update_account(account, &settings).is_ok()) }
}

/// The settings of an account, for its Properties: a handle whose `PeAccountSettings` (strings owned by it) comes
/// from `pe_account_settings_info`; free with `pe_account_settings_free`. NULL for an unknown account.
pub struct PeAccountSettingsView {
    info: PeAccountSettings,
    _strings: Strings,
}

/// # Safety
/// `core` must be a live handle.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn pe_account_settings(core: *const PeCore, account: i64) -> *mut PeAccountSettingsView {
    let security = PeSecurity::from;
    // SAFETY: as the caller guarantees
    unsafe {
        with(core, null_mut(), |core| {
            let Some(account) = core
                .accounts()
                .ok()
                .and_then(|all| all.into_iter().find(|a| a.id == account))
            else {
                return null_mut();
            };
            let s = &account.settings;
            let mut strings = Strings::default();
            let info = PeAccountSettings {
                name: strings.add(&s.name),
                email: strings.add(&s.email),
                username: strings.add(&s.username),
                imap_host: strings.add(&s.imap_host),
                imap_port: s.imap_port,
                imap_security: security(s.imap_security),
                smtp_host: strings.add(&s.smtp_host),
                smtp_port: s.smtp_port,
                smtp_security: security(s.smtp_security),
            };
            handed(PeAccountSettingsView {
                info,
                _strings: strings,
            })
        })
    }
}

/// The settings of a `pe_account_settings` handle
///
/// # Safety
/// `view` must be NULL or a handle that was not freed yet.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn pe_account_settings_info(view: *const PeAccountSettingsView) -> *const PeAccountSettings {
    // SAFETY: as the caller guarantees
    unsafe { view.as_ref() }.map_or(null(), |view| &view.info)
}

/// # Safety
/// `view` must be NULL or a handle that was not freed yet.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn pe_account_settings_free(view: *mut PeAccountSettingsView) {
    if !view.is_null() {
        // SAFETY: as the caller guarantees
        drop(unsafe { Box::from_raw(view) });
    }
}

/// Removes an account with its folders and messages
///
/// # Safety
/// `core` must be a live handle.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn pe_account_remove(core: *const PeCore, account: i64) -> bool {
    // SAFETY: as the caller guarantees
    unsafe { with(core, false, |core| core.remove_account(account).is_ok()) }
}

/// Sets the password of an account for this run
///
/// # Safety
/// `core` must be a live handle, `password` a NUL-terminated string.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn pe_account_set_password(core: *const PeCore, account: i64, password: *const c_char) -> bool {
    // SAFETY: as the caller guarantees
    let Some(password) = (unsafe { arg(password) }) else {
        return false;
    };
    // SAFETY: as the caller guarantees
    unsafe {
        with(core, false, |core| {
            core.set_password(account, password);
            true
        })
    }
}

/// An account as the folder tree shows it
#[repr(C)]
pub struct PeAccount {
    pub id: i64,
    pub name: *const c_char,
    pub email: *const c_char,
    /// The provider it signs in to through the browser, NONE for a password: a refused sign-in asks for
    /// `pe_sign_in_begin` and `pe_account_reauthorize`, not for a password. APP: with the sign-in app `app`
    pub oauth: PeOAuthProvider,
    /// The sign-in app of an `oauth` APP account, 0 otherwise
    pub app: i64,
    /// The name of what it signs in with ("Inbox Classic for Google", a sign-in app's name), empty for a password
    pub signs_in_with: *const c_char,
    /// The incoming (IMAP) server, for the Accounts list
    pub imap_host: *const c_char,
    /// "Name <address>", or the address alone when the name is empty or the same: how From and the account menus
    /// show the account
    pub label: *const c_char,
    /// What the folder tree calls it: its name, with its address too when another account has the same name
    pub title: *const c_char,
}

/// The accounts; free with `pe_account_list_free`
pub struct PeAccountList(Rows<PeAccount>);

/// The accounts, NULL on failure
///
/// # Safety
/// `core` must be a live handle.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn pe_accounts(core: *const PeCore) -> *mut PeAccountList {
    // SAFETY: as the caller guarantees
    unsafe {
        with(core, null_mut(), |core| {
            let Ok(accounts) = core.accounts() else {
                return null_mut();
            };
            let names: Vec<&str> = accounts.iter().map(|a| a.settings.name.as_str()).collect();
            handed(PeAccountList(Rows::new(&accounts, |a, strings| {
                let with = SignInWith::of_auth_kind(&a.settings.auth);
                let (oauth, app) = with.map_or((PeOAuthProvider::None, 0), sign_in_pair);
                let signs_in_with = core.sign_in_name(&a.settings.auth).unwrap_or_default();
                PeAccount {
                    id: a.id,
                    name: strings.add(&a.settings.name),
                    email: strings.add(&a.settings.email),
                    imap_host: strings.add(&a.settings.imap_host),
                    label: strings.add(&pe_core::account_label(&a.settings.name, &a.settings.email)),
                    title: strings.add(&pe_core::account_title(&a.settings.name, &a.settings.email, &names)),
                    oauth,
                    app,
                    signs_in_with: strings.add(&signs_in_with),
                }
            })))
        })
    }
}

/// # Safety
/// `list` must be NULL or live.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn pe_account_list_count(list: *const PeAccountList) -> usize {
    // SAFETY: as the caller guarantees
    Rows::count(unsafe { list.as_ref() }.map(|list| &list.0))
}

/// Row `index`, NULL past the end
///
/// # Safety
/// `list` must be NULL or live.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn pe_account_list_get(list: *const PeAccountList, index: usize) -> *const PeAccount {
    // SAFETY: as the caller guarantees
    Rows::get(unsafe { list.as_ref() }.map(|list| &list.0), index)
}

/// # Safety
/// `list` must be NULL or a list that was not freed yet.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn pe_account_list_free(list: *mut PeAccountList) {
    // SAFETY: as the caller guarantees
    unsafe { take_back(list) }
}

/// The calendar part of a message written to the folder `dir` as invitation.ics (numbered when that is taken), for the
/// calendar program to open: its path, NULL when the message has none or is not downloaded. Free with
/// `pe_string_free`.
///
/// # Safety
/// `core` must be a live handle, `dir` a NUL-terminated string.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn pe_invitation_file(
    core: *const PeCore,
    folder: i64,
    uid: u64,
    dir: *const c_char,
) -> *mut c_char {
    // SAFETY: as the caller guarantees
    let Some(dir) = (unsafe { arg(dir) }).map(std::path::PathBuf::from) else {
        return null_mut();
    };
    // SAFETY: as the caller guarantees
    unsafe {
        with(core, null_mut(), |core| match core.invitation_file(folder, uid, &dir) {
            Ok(Some(path)) => into_c_string(path.to_string_lossy().into_owned()),
            _ => null_mut(),
        })
    }
}

/// Draws the BIMI logo of a message (`has_logo`) `size` pixels square in the background: `LogoReady` follows with
/// the request this returns; 0 for a message without one
///
/// # Safety
/// `core` must be a live handle.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn pe_logo_start(core: *const PeCore, folder: i64, uid: u64, size: u32) -> u64 {
    // SAFETY: as the caller guarantees
    unsafe { with(core, 0, |core| core.logo_start(folder, uid, size).unwrap_or(0)) }
}

/// The pixels of a drawn logo: `size` x `size` BGRA with the alpha multiplied in, `len` bytes; NULL when there was
/// none. Taken once; free with `pe_bytes_free`.
///
/// # Safety
/// `core` must be a live handle, `len` a valid pointer.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn pe_logo_result(core: *const PeCore, request: u64, len: *mut usize) -> *mut u8 {
    // SAFETY: as the caller guarantees
    let Some(len) = (unsafe { len.as_mut() }) else {
        return null_mut();
    };
    *len = 0;
    // SAFETY: as the caller guarantees
    unsafe {
        with(core, null_mut(), |core| match core.logo_result(request) {
            Some(pixels) => {
                let pixels = pixels.into_boxed_slice();
                *len = pixels.len();
                Box::into_raw(pixels).cast()
            }
            None => null_mut(),
        })
    }
}

/// Unsubscribes from the mailing list of a message the one-click way (`PeUnsubscribe` OneClick): in the background,
/// `Unsubscribed` follows with the request this returns; 0 for a message that offers no such way
///
/// # Safety
/// `core` must be a live handle.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn pe_unsubscribe(core: *const PeCore, folder: i64, uid: u64) -> u64 {
    // SAFETY: as the caller guarantees
    unsafe { with(core, 0, |core| core.unsubscribe(folder, uid).unwrap_or(0)) }
}

/// How many messages are unread in the Inboxes of all accounts (the tray and the taskbar show it); 0 also when the
/// core can not say
///
/// # Safety
/// `core` must be a live handle.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn pe_inbox_unread(core: *const PeCore) -> u64 {
    // SAFETY: as the caller guarantees
    unsafe { with(core, 0, |core| core.inbox_unread().unwrap_or(0)) }
}

// ---- completing addresses ----

/// Someone (or a group of the address book) to complete an address with
#[repr(C)]
pub struct PeContact {
    /// The person's name, or the group's
    pub name: *const c_char,
    /// Empty for a group
    pub address: *const c_char,
    /// As it goes in an address field: `Name <address>`, the name quoted where it needs it, or the address alone; for
    /// a group its members so, separated by commas
    pub label: *const c_char,
    /// A group of the address book: shown by its `name`, it puts its members (`label`) in the field, and is not
    /// forgotten with `pe_contact_forget`
    pub group: bool,
}

pub struct PeContactList(Rows<PeContact>);

/// What completes an address field from `typed`: the people of the address book (each of their addresses) and its
/// groups whose name, nickname or address (a word of the name) starts with it, then those written to or heard from,
/// best first, at most `limit`, no address twice; NULL on failure
///
/// # Safety
/// `core` must be a live handle, `typed` NULL or a NUL-terminated string.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn pe_contacts(core: *const PeCore, typed: *const c_char, limit: usize) -> *mut PeContactList {
    // SAFETY: as the caller guarantees
    let typed = unsafe { arg(typed) }.unwrap_or_default().to_string();
    // SAFETY: as the caller guarantees
    unsafe {
        with(core, null_mut(), |core| {
            let Ok(found) = core.completions(&typed, limit) else {
                return null_mut();
            };
            handed(PeContactList(Rows::new(&found, |c, strings| PeContact {
                name: strings.add(&c.name),
                address: strings.add(&c.address),
                label: strings.add(&c.label),
                group: c.group,
            })))
        })
    }
}

/// # Safety
/// `list` must be NULL or live.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn pe_contact_list_count(list: *const PeContactList) -> usize {
    // SAFETY: as the caller guarantees
    Rows::count(unsafe { list.as_ref() }.map(|list| &list.0))
}

/// Row `index`, NULL past the end
///
/// # Safety
/// `list` must be NULL or live.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn pe_contact_list_get(list: *const PeContactList, index: usize) -> *const PeContact {
    // SAFETY: as the caller guarantees
    Rows::get(unsafe { list.as_ref() }.map(|list| &list.0), index)
}

/// # Safety
/// `list` must be NULL or a list that was not freed yet.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn pe_contact_list_free(list: *mut PeContactList) {
    // SAFETY: as the caller guarantees
    unsafe { take_back(list) }
}

/// Takes someone out of the people written to or heard from for good (a person of the address book stays there)
///
/// # Safety
/// `core` must be a live handle, `address` NULL or a NUL-terminated string.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn pe_contact_forget(core: *const PeCore, address: *const c_char) -> bool {
    // SAFETY: as the caller guarantees
    let address = unsafe { arg(address) }.unwrap_or_default().to_string();
    // SAFETY: as the caller guarantees
    unsafe { with(core, false, |core| core.forget_contact(&address).is_ok()) }
}

// ---- folders ----

#[repr(C)]
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum PeSpecialUse {
    None = 0,
    Inbox = 1,
    Flagged = 2,
    Sent = 3,
    Drafts = 4,
    All = 5,
    Archive = 6,
    Junk = 7,
    Trash = 8,
}

fn special_use(flag: Option<&str>) -> PeSpecialUse {
    match flag.and_then(SpecialUse::from_flag) {
        None => PeSpecialUse::None,
        Some(SpecialUse::Inbox) => PeSpecialUse::Inbox,
        Some(SpecialUse::Flagged) => PeSpecialUse::Flagged,
        Some(SpecialUse::Sent) => PeSpecialUse::Sent,
        Some(SpecialUse::Drafts) => PeSpecialUse::Drafts,
        Some(SpecialUse::All) => PeSpecialUse::All,
        Some(SpecialUse::Archive) => PeSpecialUse::Archive,
        Some(SpecialUse::Junk) => PeSpecialUse::Junk,
        Some(SpecialUse::Trash) => PeSpecialUse::Trash,
    }
}

/// A folder as the folder tree shows it, in tree order
#[repr(C)]
pub struct PeFolder {
    pub id: i64,
    pub account: i64,
    /// The full name on the server
    pub path: *const c_char,
    /// The name to show, in the language for a special folder (Sent Items, Deleted Items)
    pub name: *const c_char,
    /// 0 for a top level folder
    pub depth: u32,
    /// The Inbox or a special folder: not renamed or deleted
    pub fixed: bool,
    /// Deleted Items or Junk E-mail: Empty Folder applies when it has messages (`total`)
    pub emptiable: bool,
    pub special_use: PeSpecialUse,
    /// False for a folder that only holds other folders
    pub selectable: bool,
    pub total: u64,
    pub unread: u64,
    /// The unread messages of the folders under it (not Junk E-mail or Deleted Items): a collapsed folder shows
    /// `unread + unread_below`, an expanded one `unread`
    pub unread_below: u64,
}

/// The folders of an account; free with `pe_folder_list_free`
pub struct PeFolderList(Rows<PeFolder>, u64);

/// The folders of an account, NULL on failure
///
/// # Safety
/// `core` must be a live handle.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn pe_folders(core: *const PeCore, account: i64) -> *mut PeFolderList {
    // SAFETY: as the caller guarantees
    unsafe {
        with(core, null_mut(), |core| {
            let Ok(folders) = core.folders(account) else {
                return null_mut();
            };
            // the depth in the tree: listed ancestors only, so a folder whose parent is not listed is at the top
            let infos: Vec<_> = folders.iter().map(|f| &f.info).collect();
            let tree_depths = pe_core::tree_depths(&infos);
            let hidden = pe_core::hidden_unread(&folders, &tree_depths);
            let rows: Vec<_> = folders.iter().zip(tree_depths).zip(hidden.below).collect();
            let rows = Rows::new(&rows, |((f, depth), below), strings| PeFolder {
                id: f.id,
                account: f.account_id,
                path: strings.add(&f.info.path),
                name: strings.add(&pe_core::folder_name(&f.info)),
                depth: u32::try_from(*depth).unwrap_or(u32::MAX),
                fixed: pe_core::is_fixed_folder(&f.info),
                emptiable: pe_core::emptiable(&f.info),
                special_use: special_use(f.info.special_use.as_deref()),
                selectable: f.info.selectable,
                total: f.total,
                unread: f.unread,
                unread_below: *below,
            });
            handed(PeFolderList(rows, hidden.account))
        })
    }
}

/// The unread messages of the account of `list` (not Junk E-mail or Deleted Items): what its row shows collapsed
///
/// # Safety
/// `list` must be NULL or live.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn pe_folder_list_unread(list: *const PeFolderList) -> u64 {
    // SAFETY: as the caller guarantees
    unsafe { list.as_ref() }.map_or(0, |list| list.1)
}

/// # Safety
/// `list` must be NULL or live.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn pe_folder_list_count(list: *const PeFolderList) -> usize {
    // SAFETY: as the caller guarantees
    Rows::count(unsafe { list.as_ref() }.map(|list| &list.0))
}

/// Row `index`, NULL past the end
///
/// # Safety
/// `list` must be NULL or live.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn pe_folder_list_get(list: *const PeFolderList, index: usize) -> *const PeFolder {
    // SAFETY: as the caller guarantees
    Rows::get(unsafe { list.as_ref() }.map(|list| &list.0), index)
}

/// # Safety
/// `list` must be NULL or a list that was not freed yet.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn pe_folder_list_free(list: *mut PeFolderList) {
    // SAFETY: as the caller guarantees
    unsafe { take_back(list) }
}

/// The message counts of a folder; false when there is no such folder
///
/// # Safety
/// `core` must be a live handle; `total` and `unread` must be valid pointers.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn pe_folder_counts(core: *const PeCore, folder: i64, total: *mut u64, unread: *mut u64) -> bool {
    if total.is_null() || unread.is_null() {
        return false;
    }
    // SAFETY: as the caller guarantees
    let counts = unsafe { with(core, None, |core| core.folder(folder).ok().map(|f| (f.total, f.unread))) };
    let Some(counts) = counts else { return false };
    // SAFETY: the caller gave valid pointers
    unsafe { (*total, *unread) = counts };
    true
}

/// What the main window selects when it opens: with two or more accounts All Inboxes (`all_inboxes` true) and the
/// newest message of every Inbox, with one its Inbox and its newest message; `folder` the folder of the message (the
/// first account's Inbox when there is none), `uid` 0 when there is none; false when there is no account or its
/// Inbox is not known yet
///
/// # Safety
/// `core` must be a live handle; `all_inboxes`, `folder` and `uid` must be valid pointers.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn pe_start_message(
    core: *const PeCore,
    all_inboxes: *mut bool,
    folder: *mut i64,
    uid: *mut u64,
) -> bool {
    if all_inboxes.is_null() || folder.is_null() || uid.is_null() {
        return false;
    }
    // SAFETY: as the caller guarantees
    let start = unsafe { with(core, None, |core| core.start_message().ok().flatten()) };
    let Some(start) = start else { return false };
    // SAFETY: the caller gave valid pointers
    unsafe { (*all_inboxes, *folder, *uid) = (start.all_inboxes, start.folder, start.uid.unwrap_or(0)) };
    true
}

/// Whether the folder tree has All Inboxes above the accounts, for this many accounts
#[unsafe(no_mangle)]
pub extern "C" fn pe_all_inboxes_shown(accounts: usize) -> bool {
    pe_core::all_inboxes_shown(accounts)
}

/// What the message list shows: the messages of one folder, or of every folder, by state, and those that what was typed
/// in the Find box finds (Gmail's syntax: words, "phrases", -word, OR, from: to: subject: filename: is:unread
/// is:starred has:attachment in: before: after: older_than: newer_than: larger: smaller:)
#[repr(C)]
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum PeShow {
    All = 0,
    Unread = 1,
    Flagged = 2,
    WithAttachments = 3,
}

#[repr(C)]
pub struct PeSearch {
    /// The folder, 0 for every folder of every account (or of the Inboxes, with `all_inboxes`)
    pub folder: i64,
    /// With `folder` 0: the Inbox of every account rather than every folder
    pub all_inboxes: bool,
    pub show: PeShow,
    /// UTF-8, NULL or empty for no words
    pub text: *const c_char,
    /// One row a conversation (`PeMessage.thread` says each row's place), with the conversations `expanded` open
    /// (`expanded_count` of them); false for one row a message
    pub threads: bool,
    pub expanded: *const i64,
    pub expanded_count: usize,
}

/// # Safety
/// `search` must be NULL or point to a search whose text is NULL or NUL-terminated, and whose `expanded` is NULL or
/// points to `expanded_count` conversation ids.
pub(crate) unsafe fn search_of(search: *const PeSearch) -> Option<pe_core::Search> {
    // SAFETY: as the caller guarantees
    let s = unsafe { search.as_ref() }?;
    Some(pe_core::Search {
        scope: match (s.folder, s.all_inboxes) {
            (0, true) => pe_core::Scope::AllInboxes,
            (0, false) => pe_core::Scope::Everywhere,
            (folder, _) => pe_core::Scope::Folder(folder),
        },
        show: match s.show {
            PeShow::All => pe_core::Show::All,
            PeShow::Unread => pe_core::Show::Unread,
            PeShow::Flagged => pe_core::Show::Flagged,
            PeShow::WithAttachments => pe_core::Show::WithAttachments,
        },
        // SAFETY: as the caller guarantees
        text: unsafe { arg(s.text) }.unwrap_or_default().to_string(),
        // SAFETY: as the caller guarantees
        threads: s.threads.then(|| unsafe { ids(s.expanded, s.expanded_count) }),
    })
}

/// How many messages `search` finds, and how many of them are unread: grouped by conversation (`threads`) too, all of
/// their messages (the list's rows are `pe_list_rows`)
///
/// # Safety
/// `core` must be a live handle, `search` a valid search, `total` and `unread` valid pointers.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn pe_message_count(
    core: *const PeCore,
    search: *const PeSearch,
    total: *mut u64,
    unread: *mut u64,
) -> bool {
    if total.is_null() || unread.is_null() {
        return false;
    }
    // SAFETY: as the caller guarantees
    let Some(search) = (unsafe { search_of(search) }) else {
        return false;
    };
    // SAFETY: as the caller guarantees
    let Some(counts) = (unsafe { with(core, None, |core| core.count_search(&search).ok()) }) else {
        return false;
    };
    // SAFETY: the caller gave valid pointers
    unsafe { (*total, *unread) = counts };
    true
}

/// How many rows `pe_messages` lists for `search`: what the list's size is. Grouped by conversation (`threads`) one a
/// conversation, and under each expanded one its other messages; otherwise one a message, as `pe_message_count`
/// counts. 0 on failure.
///
/// # Safety
/// `core` must be a live handle, `search` a valid search.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn pe_list_rows(core: *const PeCore, search: *const PeSearch) -> u64 {
    // SAFETY: as the caller guarantees
    let Some(search) = (unsafe { search_of(search) }) else {
        return 0;
    };
    // SAFETY: as the caller guarantees
    unsafe { with(core, 0, |core| core.count_rows(&search).unwrap_or(0)) }
}

/// The messages before and after the message `uid` of `folder` in the list `search`, `sort` and `ascending` make, with
/// one pass over the list: what Previous and Next open, into `previous_*` and `next_*` (a folder of 0 at an end).
/// False when the message is not in that list (any more), or on failure: a window keeps the pair it had then.
///
/// # Safety
/// `core` must be a live handle, `search` a valid search, the four out pointers valid.
#[unsafe(no_mangle)]
#[allow(clippy::too_many_arguments)]
pub unsafe extern "C" fn pe_message_neighbours(
    core: *const PeCore,
    search: *const PeSearch,
    sort: PeSortField,
    ascending: bool,
    folder: i64,
    uid: u64,
    previous_folder: *mut i64,
    previous_uid: *mut u64,
    next_folder: *mut i64,
    next_uid: *mut u64,
) -> bool {
    if previous_folder.is_null() || previous_uid.is_null() || next_folder.is_null() || next_uid.is_null() {
        return false;
    }
    // SAFETY: as the caller guarantees
    let Some(search) = (unsafe { search_of(search) }) else {
        return false;
    };
    let sort = sort_of(sort, ascending);
    // SAFETY: as the caller guarantees
    let found = unsafe {
        with(core, None, |core| {
            core.neighbours(&search, sort, folder, uid).ok().flatten()
        })
    };
    let Some((previous, next)) = found else {
        return false;
    };
    let parts = |r: Option<pe_store::MessageRef>| r.map_or((0, 0), |r| (r.folder, r.uid));
    // SAFETY: the caller gave valid pointers
    unsafe {
        (*previous_folder, *previous_uid) = parts(previous);
        (*next_folder, *next_uid) = parts(next);
    }
    true
}

/// What Next Unread does next, see `pe_next_unread_step`
#[repr(C)]
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum PeNextUnread {
    /// Nothing unread anywhere else (or a failure)
    None = 0,
    /// Select the message `next_folder`, `next_uid` of the list
    Message = 1,
    /// Ask `question`; on yes show the folder `next_folder` and take the step again from its top (uid 0)
    Ask = 2,
}

/// One step of Next Unread from the message `uid` of `folder` (0 for none) in the list `search`, `sort` and `ascending`
/// make: the next unread message of the list, or the next folder with unread mail and the question to ask before going
/// there (a heading, a blank line, the question; free it with `pe_string_free`), or nothing.
///
/// # Safety
/// `core` must be a live handle, `search` a valid search, the three out pointers valid.
#[unsafe(no_mangle)]
#[allow(clippy::too_many_arguments)]
pub unsafe extern "C" fn pe_next_unread_step(
    core: *const PeCore,
    search: *const PeSearch,
    sort: PeSortField,
    ascending: bool,
    folder: i64,
    uid: u64,
    next_folder: *mut i64,
    next_uid: *mut u64,
    question: *mut *mut c_char,
) -> PeNextUnread {
    if next_folder.is_null() || next_uid.is_null() || question.is_null() {
        return PeNextUnread::None;
    }
    // SAFETY: as the caller guarantees
    let Some(search) = (unsafe { search_of(search) }) else {
        return PeNextUnread::None;
    };
    let sort = sort_of(sort, ascending);
    // SAFETY: as the caller guarantees
    let step = unsafe {
        with(core, None, |core| {
            core.next_unread_step(&search, sort, folder, uid).ok()
        })
    };
    // SAFETY: the caller gave valid pointers
    unsafe {
        *question = null_mut();
        match step {
            Some(pe_core::NextUnread::Message(found)) => {
                (*next_folder, *next_uid) = (found.folder, found.uid);
                PeNextUnread::Message
            }
            Some(pe_core::NextUnread::Ask {
                folder,
                question: asked,
            }) => {
                (*next_folder, *next_uid) = (folder, 0);
                *question = into_c_string(asked);
                PeNextUnread::Ask
            }
            _ => PeNextUnread::None,
        }
    }
}

/// Whether the message `uid` is (still) in `folder`: a single row looked up. False on failure.
///
/// # Safety
/// `core` must be a live handle.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn pe_message_exists(core: *const PeCore, folder: i64, uid: u64) -> bool {
    // SAFETY: as the caller guarantees
    unsafe { with(core, false, |core| core.has_message(folder, uid).unwrap_or(false)) }
}

/// Whether the list of `search` names whom its messages went to (Sent Items, Drafts): its person column is then To
/// and shows `recipients`, its date column is Sent, and `PE_SORT_FIELD_FROM` sorts it by the recipients. False on
/// failure.
///
/// # Safety
/// `core` must be a live handle, `search` a valid search.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn pe_lists_recipients(core: *const PeCore, search: *const PeSearch) -> bool {
    // SAFETY: as the caller guarantees
    let Some(search) = (unsafe { search_of(search) }) else {
        return false;
    };
    // SAFETY: as the caller guarantees
    unsafe { with(core, false, |core| core.lists_recipients(&search).unwrap_or(false)) }
}

/// The one folder the text of a search narrows it to (`in:sent`), by the name the app gives it ("Sent Items"); NULL for
/// every folder. Free with `pe_string_free`.
///
/// # Safety
/// `text` must be NULL or a NUL-terminated string.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn pe_search_place(text: *const c_char) -> *mut c_char {
    // SAFETY: as the caller guarantees
    let text = unsafe { arg(text) }.unwrap_or_default().to_string();
    guard(move || Core::search_place(&text).map(into_c_string))
        .flatten()
        .unwrap_or(null_mut())
}

/// How many messages the search does not know the text of yet (their text is fetched in the background, newest
/// first, after each sync); 0 also when the core can not say
///
/// # Safety
/// `core` must be a live handle.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn pe_search_unindexed_count(core: *const PeCore) -> u64 {
    // SAFETY: as the caller guarantees
    unsafe { with(core, 0, |core| core.unindexed_count().unwrap_or(0)) }
}

// ---- messages ----

#[repr(C)]
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum PeSortField {
    /// The Date header, the received date without one
    Date = 0,
    Received = 1,
    From = 2,
    Subject = 3,
    Size = 4,
}

/// The order a list is in, from C
pub(crate) fn sort_of(field: PeSortField, ascending: bool) -> Sort {
    Sort {
        field: field.into(),
        ascending,
    }
}

impl From<PeSortField> for SortField {
    fn from(value: PeSortField) -> Self {
        match value {
            PeSortField::Date => SortField::Date,
            PeSortField::Received => SortField::Received,
            PeSortField::From => SortField::From,
            PeSortField::Subject => SortField::Subject,
            PeSortField::Size => SortField::Size,
        }
    }
}

/// A row of the message list
#[repr(C)]
pub struct PeMessage {
    /// The folder it is in (the list of a search in every folder has messages of many)
    pub folder: i64,
    pub uid: u64,
    /// Seconds since the Unix epoch, valid when `has_date`
    pub date: i64,
    pub has_date: bool,
    pub size: u64,
    pub subject: *const c_char,
    /// The name of the sender, the address when there is no name
    pub from: *const c_char,
    pub from_address: *const c_char,
    pub recipients: *const c_char,
    pub seen: bool,
    pub flagged: bool,
    /// The colour of its flag (Apple Mail's): 0 when not flagged, 1 red, 2 orange, 3 yellow, 4 green, 5 blue, 6
    /// purple, 7 gray
    pub flag_color: u8,
    pub answered: bool,
    pub has_attachments: bool,
    /// Whether the row is bold: the message is unread, or the row is a collapsed conversation's with an unread message.
    /// The apps read this rather than decide from `seen` and the thread numbers.
    pub bold: bool,
    /// Its row's place in a list grouped by conversation (`PeSearch.threads`), all 0 and false otherwise: the
    /// conversation; 0 for its first message's row, 1 for the others under it when expanded; how many messages it has
    /// in the list and how many are unread; whether it is expanded
    pub thread: i64,
    pub thread_depth: u32,
    pub thread_count: u32,
    pub thread_unread: u32,
    pub thread_expanded: bool,
    /// The row opens and closes its conversation (the first row of one of several messages: a + or a -). The apps
    /// read this rather than decide from the numbers above.
    pub thread_opens: bool,
    /// The row stands for all of its conversation's messages, which are not shown under it (it shows a +, and an action
    /// on it acts on them all). The apps read this rather than decide from the numbers above.
    pub thread_collapsed: bool,
    /// A notice that a message was not delivered, or not yet (a bounce): the list shows its icon in the attachment
    /// column's place
    pub bounce: bool,
}

/// A page of the message list; free with `pe_message_list_free`
pub struct PeMessageList(Rows<PeMessage>);

/// `limit` messages of what `search` finds from `offset` on, in the order asked for. NULL on failure.
///
/// # Safety
/// `core` must be a live handle, `search` a valid search.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn pe_messages(
    core: *const PeCore,
    search: *const PeSearch,
    sort: PeSortField,
    ascending: bool,
    offset: u64,
    limit: u64,
) -> *mut PeMessageList {
    // SAFETY: as the caller guarantees
    let Some(search) = (unsafe { search_of(search) }) else {
        return null_mut();
    };
    let sort = sort_of(sort, ascending);
    // SAFETY: as the caller guarantees
    unsafe {
        with(core, null_mut(), |core| {
            let Ok(messages) = core.search(&search, sort, offset, limit) else {
                return null_mut();
            };
            handed(PeMessageList(Rows::new(&messages, |m, strings| {
                let info = &m.info;
                PeMessage {
                    folder: m.folder_id,
                    uid: info.uid,
                    date: info.display_date().unwrap_or(0),
                    has_date: info.display_date().is_some(),
                    size: info.size.unwrap_or(0),
                    subject: strings.add(&info.subject),
                    from: strings.add(info.sender()),
                    from_address: strings.add(&info.from_address),
                    recipients: strings.add(&info.recipients),
                    seen: info.seen(),
                    flagged: info.flagged(),
                    flag_color: info.flag_color().map_or(0, |c| c as u8),
                    answered: info.answered(),
                    has_attachments: info.has_attachments,
                    bold: m.bold(),
                    thread: m.thread.map_or(0, |t| t.thread),
                    thread_depth: m.thread.map_or(0, |t| t.depth),
                    thread_count: m.thread.map_or(0, |t| t.count),
                    thread_unread: m.thread.map_or(0, |t| t.unread),
                    thread_expanded: m.thread.is_some_and(|t| t.expanded),
                    thread_opens: m.thread.is_some_and(|t| t.opens()),
                    thread_collapsed: m.thread.is_some_and(|t| t.collapsed()),
                    bounce: info.bounce,
                }
            })))
        })
    }
}

/// Conversation ids; free with `pe_thread_list_free`
pub struct PeThreadList(Vec<i64>);

/// The conversations of the list `search` makes that have more than one message there: what View > Expand All
/// Conversations opens (as `PeSearch.expanded`). NULL on failure.
///
/// # Safety
/// `core` must be a live handle, `search` a valid search.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn pe_threads_with_replies(core: *const PeCore, search: *const PeSearch) -> *mut PeThreadList {
    // SAFETY: as the caller guarantees
    let Some(search) = (unsafe { search_of(search) }) else {
        return null_mut();
    };
    // SAFETY: as the caller guarantees
    unsafe {
        with(core, null_mut(), |core| {
            core.threads_with_replies(&search)
                .map_or(null_mut(), |found| handed(PeThreadList(found)))
        })
    }
}

/// # Safety
/// `list` must be NULL or from `pe_threads_with_replies`, not freed yet.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn pe_thread_list_count(list: *const PeThreadList) -> usize {
    // SAFETY: as the caller guarantees
    unsafe { list.as_ref() }.map_or(0, |l| l.0.len())
}

/// Conversation `index`; 0 past the end
///
/// # Safety
/// `list` must be NULL or from `pe_threads_with_replies`, not freed yet.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn pe_thread_list_get(list: *const PeThreadList, index: usize) -> i64 {
    // SAFETY: as the caller guarantees
    unsafe { list.as_ref() }
        .and_then(|l| l.0.get(index).copied())
        .unwrap_or(0)
}

/// # Safety
/// `list` must be NULL or from `pe_threads_with_replies`, freed once.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn pe_thread_list_free(list: *mut PeThreadList) {
    // SAFETY: as the caller guarantees
    unsafe { take_back(list) }
}

/// The conversation the message `uid` of `folder` is hidden in, in the list `search` makes: grouped by conversation,
/// that conversation collapsed and the message not its first there (whose row stands for it). The list opens it (adds
/// it to `PeSearch.expanded`) to show or select the message. 0 when the message has its own row, is not in the list,
/// or on failure.
///
/// # Safety
/// `core` must be a live handle, `search` a valid search.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn pe_message_hidden_thread(
    core: *const PeCore,
    search: *const PeSearch,
    folder: i64,
    uid: u64,
) -> i64 {
    // SAFETY: as the caller guarantees
    let Some(search) = (unsafe { search_of(search) }) else {
        return 0;
    };
    // SAFETY: as the caller guarantees
    unsafe {
        with(core, 0, |core| {
            core.hidden_in(&search, folder, uid).ok().flatten().unwrap_or(0)
        })
    }
}

/// Where message `uid` of `folder` is in what `search` finds in this order, -1 when it is not there
///
/// # Safety
/// `core` must be a live handle, `search` a valid search.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn pe_message_index(
    core: *const PeCore,
    search: *const PeSearch,
    sort: PeSortField,
    ascending: bool,
    folder: i64,
    uid: u64,
) -> i64 {
    // SAFETY: as the caller guarantees
    let Some(search) = (unsafe { search_of(search) }) else {
        return -1;
    };
    let sort = sort_of(sort, ascending);
    // SAFETY: as the caller guarantees
    unsafe {
        with(core, -1, |core| match core.search_index(&search, sort, folder, uid) {
            Ok(Some(index)) => i64::try_from(index).unwrap_or(-1),
            _ => -1,
        })
    }
}

/// # Safety
/// `list` must be NULL or live.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn pe_message_list_count(list: *const PeMessageList) -> usize {
    // SAFETY: as the caller guarantees
    Rows::count(unsafe { list.as_ref() }.map(|list| &list.0))
}

/// Row `index`, NULL past the end
///
/// # Safety
/// `list` must be NULL or live.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn pe_message_list_get(list: *const PeMessageList, index: usize) -> *const PeMessage {
    // SAFETY: as the caller guarantees
    Rows::get(unsafe { list.as_ref() }.map(|list| &list.0), index)
}

/// # Safety
/// `list` must be NULL or a list that was not freed yet.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn pe_message_list_free(list: *mut PeMessageList) {
    // SAFETY: as the caller guarantees
    unsafe { take_back(list) }
}

// ---- background work ----

/// Syncs an account in the background: `SyncStarted`, what changed, `SyncFinished`
///
/// # Safety
/// `core` must be a live handle.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn pe_sync(core: *const PeCore, account: i64) -> bool {
    // SAFETY: as the caller guarantees
    unsafe { with(core, false, |core| core.sync(account).is_ok()) }
}

/// Gets a message ready to show, in the background: `MessageReady` follows
///
/// # Safety
/// `core` must be a live handle.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn pe_message_open(core: *const PeCore, folder: i64, uid: u64) -> bool {
    // SAFETY: as the caller guarantees
    unsafe { with(core, false, |core| core.open_message(folder, uid).is_ok()) }
}

/// Marks a message read or unread: in the store now (`FolderChanged` follows), on the server in
/// the background
///
/// # Safety
/// `core` must be a live handle.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn pe_message_set_seen(core: *const PeCore, folder: i64, uid: u64, seen: bool) -> bool {
    // SAFETY: as the caller guarantees
    unsafe { with(core, false, |core| core.set_seen(folder, uid, seen).is_ok()) }
}

/// Marks every message of a folder read: in the store now (`FolderChanged` follows), on the server in the background
///
/// # Safety
/// `core` must be a live handle.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn pe_folder_mark_all_read(core: *const PeCore, folder: i64) -> bool {
    // SAFETY: as the caller guarantees
    unsafe { with(core, false, |core| core.mark_all_read(folder).is_ok()) }
}

/// Marks every message of every account's Inbox read, as `pe_folder_mark_all_read` marks one folder
///
/// # Safety
/// `core` must be a live handle.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn pe_mark_all_inboxes_read(core: *const PeCore) -> bool {
    // SAFETY: as the caller guarantees
    unsafe { with(core, false, |core| core.mark_all_inboxes_read().is_ok()) }
}

// ---- folders ----

/// Runs a folder change, handing its refusal (a name that can not be one, a special folder) to `error`
///
/// # Safety
/// `error` must be NULL or a valid pointer.
unsafe fn folder_change(
    core: *const PeCore,
    error: *mut *mut c_char,
    change: impl FnOnce(&Core) -> pe_core::Result<()>,
) -> bool {
    // SAFETY: as the caller guarantees
    let outcome = unsafe { with(core, Err(None), |core| change(core).map_err(Some)) };
    // SAFETY: as the caller guarantees
    unsafe { refused(error, outcome, "the folder could not be changed") }.is_some()
}

/// The value of `outcome`, or None with the reason in `error` when it is not NULL: the core's, or `fallback` when
/// there is none (a NULL handle, an argument that is not UTF-8)
///
/// # Safety
/// `error` must be NULL or a valid pointer.
pub(crate) unsafe fn refused<T>(
    error: *mut *mut c_char,
    outcome: Result<T, Option<pe_core::Error>>,
    fallback: &str,
) -> Option<T> {
    match outcome {
        Ok(value) => Some(value),
        Err(reason) => {
            if !error.is_null() {
                let text = reason.map_or_else(|| fallback.to_string(), |e| e.to_string());
                // SAFETY: the caller gave a valid pointer
                unsafe { *error = into_c_string(text) };
            }
            None
        }
    }
}

/// Creates the folder `name` (UTF-8) in `parent`, or at the top of the account when `parent` is 0:
/// `FoldersChanged` follows once the server has it. False with the reason in `error` (NULL or a pointer to a
/// string to free with `pe_string_free`) for a name that can not be one.
///
/// # Safety
/// `core` must be a live handle, `name` a NUL-terminated string, `error` NULL or a valid pointer.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn pe_folder_create(
    core: *const PeCore,
    account: i64,
    parent: i64,
    name: *const c_char,
    error: *mut *mut c_char,
) -> bool {
    // SAFETY: as the caller guarantees
    let name = unsafe { arg(name) }.unwrap_or_default().to_string();
    let parent = (parent != 0).then_some(parent);
    // SAFETY: as the caller guarantees
    unsafe { folder_change(core, error, |core| core.create_folder(account, parent, &name)) }
}

/// Renames a folder to `name` (its subfolders go along): `FoldersChanged` follows. False with the reason for the
/// Inbox, a special folder or a name that can not be one.
///
/// # Safety
/// As `pe_folder_create`.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn pe_folder_rename(
    core: *const PeCore,
    folder: i64,
    name: *const c_char,
    error: *mut *mut c_char,
) -> bool {
    // SAFETY: as the caller guarantees
    let name = unsafe { arg(name) }.unwrap_or_default().to_string();
    // SAFETY: as the caller guarantees
    unsafe { folder_change(core, error, |core| core.rename_folder(folder, &name)) }
}

/// Deletes a folder and the messages in it: `FoldersChanged` follows. False with the reason for the Inbox and the
/// special folders.
///
/// # Safety
/// `core` must be a live handle, `error` NULL or a valid pointer.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn pe_folder_delete(core: *const PeCore, folder: i64, error: *mut *mut c_char) -> bool {
    // SAFETY: as the caller guarantees
    unsafe { folder_change(core, error, |core| core.delete_folder(folder)) }
}

/// What to ask before emptying `folder` ("Delete the 12 messages in Deleted Items for good?"), NULL when it can not be
/// emptied or has nothing in it (Empty Folder is off then). Free with `pe_string_free`.
///
/// # Safety
/// `core` must be a live handle.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn pe_folder_empty_question(core: *const PeCore, folder: i64) -> *mut c_char {
    // SAFETY: as the caller guarantees
    unsafe {
        with(core, null_mut(), |core| {
            core.empty_folder_question(folder)
                .ok()
                .flatten()
                .map_or(null_mut(), into_c_string)
        })
    }
}

/// Empties Deleted Items or Junk E-mail, after the window asked `pe_folder_empty_question`: every message of it
/// deleted for good (`FolderChanged` now, the server in the background). Returns what the status bar says, or NULL
/// with the reason in `error` (NULL or a pointer to a string to free with `pe_string_free`). Free the text with
/// `pe_string_free`.
///
/// # Safety
/// `core` must be a live handle, `error` NULL or a valid pointer.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn pe_folder_empty(core: *const PeCore, folder: i64, error: *mut *mut c_char) -> *mut c_char {
    // SAFETY: as the caller guarantees
    let outcome = unsafe { with(core, Err(None), |core| core.empty_folder(folder).map_err(Some)) };
    // SAFETY: as the caller guarantees
    unsafe { refused(error, outcome, "the folder could not be emptied") }.map_or(null_mut(), into_c_string)
}

// ---- the message view ----

#[repr(C)]
pub struct PeAttachment {
    /// The name the sender gave, for display, without control or direction characters
    pub filename: *const c_char,
    /// The name to save it under: no path, no reserved or unsafe characters
    pub safe_filename: *const c_char,
    pub mime_type: *const c_char,
    pub size: u64,
}

/// What the calendar part of a message asks
#[repr(C)]
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum PeInvitationKind {
    Request = 0,
    Update = 1,
    Cancel = 2,
    Reply = 3,
}

/// The event of a message's calendar part, as the reading pane shows it
#[repr(C)]
pub struct PeInvitation {
    pub kind: PeInvitationKind,
    pub summary: *const c_char,
    /// Seconds since the Unix epoch, valid when `has_start` / `has_end`; with `floating`, the time as written (shown
    /// as UTC, not converted)
    pub start: i64,
    pub end: i64,
    pub has_start: bool,
    pub has_end: bool,
    /// Dates without times; `end` is the day after the last
    pub all_day: bool,
    pub floating: bool,
    pub location: *const c_char,
    pub organizer: *const c_char,
    pub attendees: usize,
    /// How it repeats, in words; empty for once
    pub repeats: *const c_char,
}

/// How a message lets its reader leave its mailing list
#[repr(C)]
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum PeUnsubscribe {
    /// It does not say
    None = 0,
    /// `pe_unsubscribe` does it (RFC 8058)
    OneClick = 1,
    /// A message to `unsubscribe_link` (a mailto: link, for `pe_mailto_draft`), written for the user to send
    Mail = 2,
    /// The page `unsubscribe_link` (https), opened in the browser
    Web = 3,
}

/// The header fields and the document of a message
#[repr(C)]
pub struct PeMessageInfo {
    pub subject: *const c_char,
    pub from: *const c_char,
    pub to: *const c_char,
    pub cc: *const c_char,
    /// Seconds since the Unix epoch, valid when `has_date`
    pub date: i64,
    pub has_date: bool,
    /// The sanitized document for the preview, with its CSP
    pub document: *const c_char,
    pub attachment_count: usize,
    /// The message has pictures on the internet, blocked until it is shown again with remote images allowed
    pub remote_images: bool,
    pub unsubscribe: PeUnsubscribe,
    /// The mailto: link or page of `unsubscribe` (Mail, Web), empty otherwise
    pub unsubscribe_link: *const c_char,
    /// Where it goes, for the window to say: the host, or the address of the message
    pub unsubscribe_target: *const c_char,
    /// The event of its calendar part, NULL without one; owned by the view
    pub invitation: *const PeInvitation,
    /// The sender's brand has a BIMI logo the receiving server passed: `pe_logo_start` draws it
    pub has_logo: bool,
    /// A notice that a message was not delivered, or not yet: `document` starts with a card that explains it
    pub bounce: bool,
    /// The message the bounce returns is in the account (Sent Items first), at `bounced_folder` and `bounced_uid`:
    /// the card links to it, and a click on that link (`pe_reader_link` says `PE_READER_LINK_BOUNCED_MESSAGE`)
    /// selects it
    pub has_bounced_message: bool,
    pub bounced_folder: i64,
    pub bounced_uid: u64,
}

/// A message as the preview shows it; free with `pe_message_view_free`
pub struct PeMessageView {
    info: PeMessageInfo,
    attachments: Vec<PeAttachment>,
    _invitation: Option<Box<PeInvitation>>,
    _strings: Strings,
}

/// A view for C++: its strings and attachments owned by the handle
fn view_handle(view: pe_core::MessageView) -> *mut PeMessageView {
    let mut strings = Strings::default();
    let attachments: Vec<PeAttachment> = view
        .attachments
        .iter()
        .map(|a| PeAttachment {
            filename: strings.add(&a.filename),
            safe_filename: strings.add(&a.safe_filename),
            mime_type: strings.add(&a.mime_type),
            size: a.size,
        })
        .collect();
    let invitation = view.invitation.as_ref().map(|event| {
        Box::new(PeInvitation {
            kind: match event.method {
                pe_core::calendar::Method::Request => PeInvitationKind::Request,
                pe_core::calendar::Method::Update => PeInvitationKind::Update,
                pe_core::calendar::Method::Cancel => PeInvitationKind::Cancel,
                pe_core::calendar::Method::Reply => PeInvitationKind::Reply,
            },
            summary: strings.add(&event.summary),
            start: event.start.unwrap_or(0),
            end: event.end.unwrap_or(0),
            has_start: event.start.is_some(),
            has_end: event.end.is_some(),
            all_day: event.all_day,
            floating: event.floating,
            location: strings.add(&event.location),
            organizer: strings.add(&event.organizer),
            attendees: event.attendees,
            repeats: strings.add(&event.repeats),
        })
    });
    let (unsubscribe, unsubscribe_link) = match &view.unsubscribe {
        None => (PeUnsubscribe::None, ""),
        Some(Unsubscribe::OneClick { .. }) => (PeUnsubscribe::OneClick, ""),
        Some(Unsubscribe::Mail { link }) => (PeUnsubscribe::Mail, link.as_str()),
        Some(Unsubscribe::Web { url }) => (PeUnsubscribe::Web, url.as_str()),
    };
    let info = PeMessageInfo {
        subject: strings.add(&view.subject),
        from: strings.add(&view.from),
        to: strings.add(&view.to),
        cc: strings.add(&view.cc),
        date: view.date.unwrap_or(0),
        has_date: view.date.is_some(),
        document: strings.add(&view.document),
        attachment_count: attachments.len(),
        remote_images: view.remote_images,
        unsubscribe,
        unsubscribe_link: strings.add(unsubscribe_link),
        unsubscribe_target: strings.add(&view.unsubscribe.as_ref().map(Unsubscribe::target).unwrap_or_default()),
        invitation: invitation.as_deref().map_or(null(), |i| i as *const PeInvitation),
        has_logo: view.has_logo,
        bounce: view.bounce,
        has_bounced_message: view.bounced_message.is_some(),
        bounced_folder: view.bounced_message.map_or(0, |m| m.folder),
        bounced_uid: view.bounced_message.map_or(0, |m| m.uid),
    };
    handed(PeMessageView {
        info,
        attachments,
        _invitation: invitation,
        _strings: strings,
    })
}

/// What a link clicked in the reading pane is to the app
#[repr(C)]
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum PeReaderLink {
    /// A link of the message: the browser opens it, as before
    Other = 0,
    /// "Show the message that bounced" on a bounce's card: select the message at `bounced_folder` and
    /// `bounced_uid` of the view's `PeMessageInfo`
    BouncedMessage = 1,
}

/// What `uri`, a link clicked in the reading pane (the URI the web view's navigation names), is: one of the
/// document's own, which the app handles itself, or one to open in the browser. The web views cancel every navigation
/// as before; the app asks this first.
///
/// # Safety
/// `uri` must be NULL or a NUL-terminated string.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn pe_reader_link(uri: *const c_char) -> PeReaderLink {
    // SAFETY: as the caller guarantees
    let Some(uri) = (unsafe { arg(uri) }) else {
        return PeReaderLink::Other;
    };
    guard(|| {
        if pe_html::is_bounced_message_link(uri) {
            PeReaderLink::BouncedMessage
        } else {
            PeReaderLink::Other
        }
    })
    .unwrap_or(PeReaderLink::Other)
}

/// The view of a message whose source is in the store (after `MessageReady`), NULL otherwise. Built on the
/// calling thread; the app's windows use `pe_message_view_start`, which builds it on a worker.
///
/// # Safety
/// `core` must be a live handle.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn pe_message_view(
    core: *const PeCore,
    folder: i64,
    uid: u64,
    allow_remote_images: bool,
) -> *mut PeMessageView {
    // SAFETY: as the caller guarantees
    unsafe {
        with(core, null_mut(), |core| {
            match core.message_view(folder, uid, allow_remote_images) {
                Ok(Some(view)) => view_handle(view),
                _ => null_mut(),
            }
        })
    }
}

/// Builds the view of a message whose source is in the store (after `MessageReady`) on a worker thread:
/// `ViewReady` with this request in `uid` follows. 0 on failure.
///
/// # Safety
/// `core` must be a live handle.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn pe_message_view_start(
    core: *const PeCore,
    folder: i64,
    uid: u64,
    allow_remote_images: bool,
) -> u64 {
    // SAFETY: as the caller guarantees
    unsafe {
        with(core, 0, |core| {
            core.message_view_start(folder, uid, allow_remote_images).unwrap_or(0)
        })
    }
}

/// The view a request built, after its `ViewReady`, once; NULL when the message was not in the store. Free with
/// `pe_message_view_free`.
///
/// # Safety
/// `core` must be a live handle.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn pe_message_view_result(core: *const PeCore, request: u64) -> *mut PeMessageView {
    // SAFETY: as the caller guarantees
    unsafe {
        with(core, null_mut(), |core| {
            core.message_view_result(request).map_or(null_mut(), view_handle)
        })
    }
}

/// Drops a view request no longer waited for
///
/// # Safety
/// `core` must be a live handle.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn pe_message_view_cancel(core: *const PeCore, request: u64) {
    // SAFETY: as the caller guarantees
    unsafe { with(core, (), |core| core.message_view_cancel(request)) }
}

/// # Safety
/// `view` must be NULL or live.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn pe_message_view_info(view: *const PeMessageView) -> *const PeMessageInfo {
    // SAFETY: as the caller guarantees
    unsafe { view.as_ref() }.map_or(null(), |view| &view.info)
}

/// Attachment `index`, NULL past the end
///
/// # Safety
/// `view` must be NULL or live.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn pe_message_view_attachment(view: *const PeMessageView, index: usize) -> *const PeAttachment {
    // SAFETY: as the caller guarantees
    unsafe { view.as_ref() }
        .and_then(|view| view.attachments.get(index))
        .map_or(null(), |row| row)
}

/// # Safety
/// `view` must be NULL or a view that was not freed yet.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn pe_message_view_free(view: *mut PeMessageView) {
    // SAFETY: as the caller guarantees
    unsafe { take_back(view) }
}

/// Saves every attachment of a message into the folder `dir` (UTF-8, one the user chose), each under the name the core
/// made safe; a file of that name already there is kept and the new one numbered ("name (2).ext"). True when the
/// message is here, with how many were saved in `saved` and how many there are in `total` (either may be NULL).
///
/// # Safety
/// `core` must be a live handle, `dir` NULL or a NUL-terminated string, `saved` and `total` NULL or valid pointers.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn pe_save_attachments(
    core: *const PeCore,
    folder: i64,
    uid: u64,
    dir: *const c_char,
    saved: *mut usize,
    total: *mut usize,
) -> bool {
    // SAFETY: as the caller guarantees
    let Some(dir) = (unsafe { arg(dir) }) else {
        return false;
    };
    // SAFETY: as the caller guarantees
    let counts = unsafe {
        with(core, None, |core| {
            core.save_attachments(folder, uid, std::path::Path::new(dir))
                .ok()
                .flatten()
        })
    };
    let Some((done, all)) = counts else {
        return false;
    };
    // SAFETY: the caller gave NULL or valid pointers
    unsafe {
        if let Some(saved) = saved.as_mut() {
            *saved = done;
        }
        if let Some(total) = total.as_mut() {
            *total = all;
        }
    }
    true
}

/// The content of attachment `index` of a message, NULL on failure. `len` gets its length and
/// `filename` the name to save it under (free it with `pe_string_free`). Free the bytes with
/// `pe_bytes_free`.
///
/// # Safety
/// `core` must be a live handle; `len` and `filename` must be valid pointers.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn pe_attachment_data(
    core: *const PeCore,
    folder: i64,
    uid: u64,
    index: usize,
    len: *mut usize,
    filename: *mut *mut c_char,
) -> *mut u8 {
    if len.is_null() || filename.is_null() {
        return null_mut();
    }
    // SAFETY: as the caller guarantees
    let found = unsafe { with(core, None, |core| core.attachment(folder, uid, index).ok().flatten()) };
    let Some((name, data)) = found else {
        return null_mut();
    };
    let data = data.into_boxed_slice();
    // SAFETY: the caller gave valid pointers
    unsafe {
        *len = data.len();
        *filename = into_c_string(name);
    }
    Box::into_raw(data).cast()
}

/// The header block of a message for File > Properties, as text to show (line breaks `\r\n`, no control characters);
/// NULL when it is not in the store yet. Free with `pe_string_free`.
///
/// # Safety
/// `core` must be a live handle.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn pe_message_headers(core: *const PeCore, folder: i64, uid: u64) -> *mut c_char {
    // SAFETY: as the caller guarantees
    unsafe {
        with(core, null_mut(), |core| match core.message_headers(folder, uid) {
            Ok(Some(text)) => into_c_string(text),
            _ => null_mut(),
        })
    }
}

/// The whole source of a message for View Source, as text safe to show (line breaks `\r\n`, no control
/// characters, cut short past 4 MB with a line that says so), and in `title` the title of its window; NULL when it is
/// not in the store yet (`pe_message_open` fetches it, `MessageReady` follows). Free both with `pe_string_free`.
///
/// # Safety
/// `core` must be a live handle; `title` a valid pointer.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn pe_message_source_text(
    core: *const PeCore,
    folder: i64,
    uid: u64,
    title: *mut *mut c_char,
) -> *mut c_char {
    if title.is_null() {
        return null_mut();
    }
    // SAFETY: as the caller guarantees
    let found = unsafe { with(core, None, |core| core.message_source_text(folder, uid).ok().flatten()) };
    let Some((name, text)) = found else {
        return null_mut();
    };
    // SAFETY: the caller gave a valid pointer
    unsafe { *title = into_c_string(name) };
    into_c_string(text)
}

/// The source of a message for File > Save As, NULL when it is not in the store yet (after `MessageReady` it is).
/// `len` gets its length and `filename` a name to save it under made from its subject (`.eml`; free it with
/// `pe_string_free`). Free the bytes with `pe_bytes_free`.
///
/// # Safety
/// `core` must be a live handle; `len` and `filename` must be valid pointers.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn pe_message_source(
    core: *const PeCore,
    folder: i64,
    uid: u64,
    len: *mut usize,
    filename: *mut *mut c_char,
) -> *mut u8 {
    if len.is_null() || filename.is_null() {
        return null_mut();
    }
    // SAFETY: as the caller guarantees
    let found = unsafe { with(core, None, |core| core.message_source(folder, uid).ok().flatten()) };
    let Some((name, data)) = found else {
        return null_mut();
    };
    let data = data.into_boxed_slice();
    // SAFETY: the caller gave valid pointers
    unsafe {
        *len = data.len();
        *filename = into_c_string(name);
    }
    Box::into_raw(data).cast()
}

/// Puts the message saved in the file at `path` (UTF-8, an `.eml`) into a folder: `FolderChanged` follows once the
/// server has it. False with the reason in `error` (NULL or a pointer to a string to free with `pe_string_free`)
/// for a file that can not be read, is not a message or is too large.
///
/// # Safety
/// `core` must be a live handle, `path` a NUL-terminated string, `error` NULL or a valid pointer.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn pe_message_import(
    core: *const PeCore,
    folder: i64,
    path: *const c_char,
    error: *mut *mut c_char,
) -> bool {
    // SAFETY: as the caller guarantees
    let path = unsafe { arg(path) }.unwrap_or_default().to_string();
    // SAFETY: as the caller guarantees
    unsafe {
        folder_change(core, error, |core| {
            core.import_message(folder, std::path::Path::new(&path))
        })
    }
}

/// Frees bytes from `pe_attachment_data` and `pe_message_source`
///
/// # Safety
/// `data` must be NULL or bytes from this library of `len` bytes, not freed yet.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn pe_bytes_free(data: *mut u8, len: usize) {
    if !data.is_null() {
        // SAFETY: a boxed slice of `len` bytes made by pe_attachment_data
        drop(unsafe { Box::from_raw(std::ptr::slice_from_raw_parts_mut(data, len)) });
    }
}

// ---- writing ----

/// A message to send; strings are UTF-8, address lists as the user typed them
#[repr(C)]
pub struct PeOutgoing {
    pub to: *const c_char,
    pub cc: *const c_char,
    pub bcc: *const c_char,
    pub subject: *const c_char,
    /// The plain text, for a message without `html`
    pub text: *const c_char,
    /// What was written in the editor, as HTML, or NULL for a plain text message
    pub html: *const c_char,
    /// The `quote` of the draft, added after `html`, or NULL
    pub quote: *const c_char,
    /// From the draft of a reply, or NULL
    pub in_reply_to: *const c_char,
    /// From the draft of a reply, space separated, or NULL
    pub references: *const c_char,
    /// Paths of files to attach
    pub attachments: *const *const c_char,
    pub attachment_count: usize,
    /// The Message-ID of the draft it was saved as (from `pe_draft_save` or PeDraftInfo), or NULL
    pub message_id: *const c_char,
    /// The account whose Drafts has that copy when From changed to another account since, 0 otherwise: the copy
    /// there goes once the message is saved or queued in the account it goes from now
    pub draft_account: i64,
    /// The quoted message was plain text (PeDraftInfo.quote_text was there): with nothing formatted written, the
    /// message then goes as plain text
    pub quote_plain: bool,
    /// PeDraftInfo.quote_text while `quote` is the draft's own (not edited), NULL otherwise
    pub quote_text: *const c_char,
}

/// # Safety
/// `outgoing` must be NULL or valid, its strings NULL or NUL-terminated, `attachments` pointing to
/// `attachment_count` of them.
unsafe fn outgoing(outgoing: *const PeOutgoing) -> Option<Outgoing> {
    // SAFETY: as the caller guarantees
    let o = unsafe { outgoing.as_ref() }?;
    // NULL is empty, text that is not UTF-8 is refused rather than sent as nothing
    let text = |p: *const c_char| -> Option<String> {
        // SAFETY: as the caller guarantees
        if p.is_null() {
            Some(String::new())
        } else {
            unsafe { arg(p) }.map(str::to_string)
        }
    };
    let attachments = if o.attachments.is_null() || o.attachment_count == 0 {
        Vec::new()
    } else {
        // SAFETY: as the caller guarantees
        let paths = unsafe { std::slice::from_raw_parts(o.attachments, o.attachment_count) };
        // SAFETY: as the caller guarantees
        paths
            .iter()
            .map(|p| unsafe { arg(*p) }.map(std::path::PathBuf::from))
            .collect::<Option<Vec<_>>>()?
    };
    Some(Outgoing {
        to: text(o.to)?,
        cc: text(o.cc)?,
        bcc: text(o.bcc)?,
        subject: text(o.subject)?,
        text: text(o.text)?,
        // NULL is a plain text message, not an empty HTML one
        html: if o.html.is_null() { None } else { Some(text(o.html)?) },
        quote: Some(text(o.quote)?).filter(|q| !q.is_empty()),
        attachments,
        in_reply_to: Some(text(o.in_reply_to)?).filter(|r| !r.is_empty()),
        references: text(o.references)?.split_whitespace().map(str::to_string).collect(),
        message_id: Some(text(o.message_id)?).filter(|id| !id.is_empty()),
        draft_account: (o.draft_account != 0).then_some(o.draft_account),
        quote_plain: o.quote_plain,
        quote_text: Some(text(o.quote_text)?).filter(|t| !t.is_empty()),
    })
}

/// Sends a message from an account: it goes into the Outbox (`OutboxChanged`), and from there to the server now.
/// `MessageSent` when the server took it; `Failed` with the server's answer
/// when it did not, the message waiting in the Outbox. A recipient that is no address or a file that is not there
/// fails right away: false, with the reason in `error` when it is not NULL (free it with `pe_string_free`).
///
/// # Safety
/// `core` must be a live handle, `message` a valid message, `error` NULL or a valid pointer.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn pe_message_send(
    core: *const PeCore,
    account: i64,
    message: *const PeOutgoing,
    error: *mut *mut c_char,
) -> bool {
    // SAFETY: as the caller guarantees
    let result = match unsafe { outgoing(message) } {
        // SAFETY: as the caller guarantees
        Some(message) => unsafe { with(core, Err(None), |core| core.send(account, message).map_err(Some)) },
        None => Err(None),
    };
    // SAFETY: as the caller guarantees
    unsafe { refused(error, result, "the message could not be sent") }.is_some()
}

// ---- the Outbox ----

/// A message waiting in the Outbox
#[repr(C)]
pub struct PeQueued {
    pub id: i64,
    pub account: i64,
    pub subject: *const c_char,
    pub recipients: *const c_char,
    /// Seconds since the Unix epoch
    pub created: i64,
    /// Why the last try did not work, NULL before the first
    pub problem: *const c_char,
    /// It waits until then before it goes (one an AI agent sent), seconds since the Unix epoch; 0 when it does not
    pub not_before: i64,
}

/// The Outbox; free with `pe_outbox_free`
pub struct PeOutbox(Rows<PeQueued>);

/// What waits in the Outbox, of every account, oldest first; NULL on failure
///
/// # Safety
/// `core` must be a live handle.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn pe_outbox(core: *const PeCore) -> *mut PeOutbox {
    // SAFETY: as the caller guarantees
    unsafe {
        with(core, null_mut(), |core| {
            let Ok(queued) = core.outbox() else {
                return null_mut();
            };
            handed(PeOutbox(Rows::new(&queued, |q, strings| PeQueued {
                id: q.id,
                account: q.account_id,
                subject: strings.add(&q.subject),
                recipients: strings.add(&q.recipients),
                created: q.created,
                problem: q.problem.as_deref().map_or(null(), |p| strings.add(p)),
                not_before: q.not_before.unwrap_or(0),
            })))
        })
    }
}

/// # Safety
/// `list` must be NULL or live.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn pe_outbox_count(list: *const PeOutbox) -> usize {
    // SAFETY: as the caller guarantees
    Rows::count(unsafe { list.as_ref() }.map(|list| &list.0))
}

/// Row `index`, NULL past the end
///
/// # Safety
/// `list` must be NULL or live.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn pe_outbox_get(list: *const PeOutbox, index: usize) -> *const PeQueued {
    // SAFETY: as the caller guarantees
    Rows::get(unsafe { list.as_ref() }.map(|list| &list.0), index)
}

/// # Safety
/// `list` must be NULL or a list that was not freed yet.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn pe_outbox_free(list: *mut PeOutbox) {
    // SAFETY: as the caller guarantees
    unsafe { take_back(list) }
}

/// Takes a message out of the Outbox without sending it: `OutboxChanged`
///
/// # Safety
/// `core` must be a live handle.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn pe_outbox_delete(core: *const PeCore, id: i64) -> bool {
    // SAFETY: as the caller guarantees
    unsafe { with(core, false, |core| core.outbox_delete(id).is_ok()) }
}

/// Sends what waits in the Outbox now
///
/// # Safety
/// `core` must be a live handle.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn pe_outbox_send(core: *const PeCore) -> bool {
    // SAFETY: as the caller guarantees
    unsafe { with(core, false, |core| core.outbox_send().is_ok()) }
}

#[repr(C)]
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum PeDraftKind {
    Reply = 0,
    ReplyAll = 1,
    Forward = 2,
}

/// The fields a compose window starts with
#[repr(C)]
pub struct PeDraftInfo {
    pub to: *const c_char,
    pub cc: *const c_char,
    pub subject: *const c_char,
    /// The quoted message, for `pe_editor_document` and PeOutgoing; empty for a new message
    pub quote: *const c_char,
    /// The quote starts folded behind "..." (a reply) or open (a forward)
    pub quote_folded: bool,
    /// The quote as plain text (the original's own lines) when the message replied to or forwarded was plain text,
    /// NULL otherwise: for PeOutgoing (`quote_plain` and, while the quote is not edited, `quote_text`)
    pub quote_text: *const c_char,
    /// For PeOutgoing, NULL when there is none
    pub in_reply_to: *const c_char,
    /// For PeOutgoing, space separated
    pub references: *const c_char,
    pub bcc: *const c_char,
    /// What was written, for `pe_editor_document`: a saved draft opened again; empty otherwise
    pub body: *const c_char,
    /// The files of a saved draft opened again, written out to the temporary folder, to attach again
    pub attachments: *const *const c_char,
    pub attachment_count: usize,
    /// For PeOutgoing: a saved draft opened again; NULL otherwise
    pub message_id: *const c_char,
}

/// A draft; free with `pe_draft_free`
pub struct PeDraft {
    info: PeDraftInfo,
    _strings: Strings,
    _attachments: Vec<*const c_char>,
}

/// A draft handed to C
pub(crate) fn draft_handle(draft: &pe_core::Draft) -> *mut PeDraft {
    let mut strings = Strings::default();
    let attachments: Vec<*const c_char> = draft
        .attachments
        .iter()
        .map(|path| strings.add(&path.to_string_lossy()))
        .collect();
    let info = PeDraftInfo {
        to: strings.add(&draft.to),
        cc: strings.add(&draft.cc),
        subject: strings.add(&draft.subject),
        quote: strings.add(&draft.quote),
        quote_folded: draft.quote_folded,
        quote_text: draft.quote_text.as_deref().map_or(null(), |text| strings.add(text)),
        in_reply_to: draft.in_reply_to.as_deref().map_or(null(), |r| strings.add(r)),
        references: strings.add(&draft.references.join(" ")),
        bcc: strings.add(&draft.bcc),
        body: strings.add(&draft.body),
        // the pointers are into the Vec's buffer on the heap, which moving the Vec does not move
        attachments: attachments.as_ptr(),
        attachment_count: attachments.len(),
        message_id: draft.message_id.as_deref().map_or(null(), |id| strings.add(id)),
    };
    handed(PeDraft {
        info,
        _strings: strings,
        _attachments: attachments,
    })
}

/// A reply, a reply to all or a forward of a message whose source is in the store (after
/// `MessageReady`), NULL otherwise
///
/// # Safety
/// `core` must be a live handle.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn pe_message_draft(
    core: *const PeCore,
    folder: i64,
    uid: u64,
    kind: PeDraftKind,
) -> *mut PeDraft {
    let kind = match kind {
        PeDraftKind::Reply => DraftKind::Reply,
        PeDraftKind::ReplyAll => DraftKind::ReplyAll,
        PeDraftKind::Forward => DraftKind::Forward,
    };
    // SAFETY: as the caller guarantees
    unsafe {
        with(core, null_mut(), |core| match core.draft(folder, uid, kind) {
            Ok(Some(draft)) => draft_handle(&draft),
            _ => null_mut(),
        })
    }
}

/// A new message from a `mailto:` link (RFC 6068): its addresses, subject and body; NULL for what is no such link.
/// Free with `pe_draft_free`.
///
/// # Safety
/// `link` must be NULL or a NUL-terminated string.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn pe_mailto_draft(link: *const c_char) -> *mut PeDraft {
    // SAFETY: as the caller guarantees
    let Some(link) = (unsafe { arg(link) }).map(str::to_string) else {
        return null_mut();
    };
    guard(move || pe_core::mailto::draft(&link).map_or(null_mut(), |draft| draft_handle(&draft))).unwrap_or(null_mut())
}

/// A saved draft of the Drafts folder (its source in the store, after `MessageReady`) to go on writing, NULL
/// otherwise
///
/// # Safety
/// `core` must be a live handle.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn pe_draft_open(core: *const PeCore, folder: i64, uid: u64) -> *mut PeDraft {
    // SAFETY: as the caller guarantees
    unsafe {
        with(core, null_mut(), |core| match core.reopen_draft(folder, uid) {
            Ok(Some(draft)) => draft_handle(&draft),
            _ => null_mut(),
        })
    }
}

/// Saves a message being written in the Drafts folder of `account`, in place of the copy saved before (the one with
/// `message->message_id`), in the background: `Failed` when that does not work. True with the draft's Message-ID in
/// `message_id`, to pass in PeOutgoing from then on; false with the reason in `error` (an account without a Drafts
/// folder). Free both with `pe_string_free`; either may be NULL when not wanted.
///
/// # Safety
/// `core` must be a live handle, `message` a valid message, `message_id` and `error` NULL or valid pointers.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn pe_draft_save(
    core: *const PeCore,
    account: i64,
    message: *const PeOutgoing,
    message_id: *mut *mut c_char,
    error: *mut *mut c_char,
) -> bool {
    // SAFETY: as the caller guarantees
    let result = match unsafe { outgoing(message) } {
        // SAFETY: as the caller guarantees
        Some(message) => unsafe { with(core, Err(None), |core| core.save_draft(account, message).map_err(Some)) },
        None => Err(None),
    };
    // SAFETY: as the caller guarantees
    let Some(id) = (unsafe { refused(error, result, "the message could not be saved") }) else {
        return false;
    };
    if !message_id.is_null() {
        // SAFETY: the caller gave a valid pointer
        unsafe { *message_id = into_c_string(id) };
    }
    true
}

/// # Safety
/// `draft` must be NULL or live.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn pe_draft_info(draft: *const PeDraft) -> *const PeDraftInfo {
    // SAFETY: as the caller guarantees
    unsafe { draft.as_ref() }.map_or(null(), |draft| &draft.info)
}

/// # Safety
/// `draft` must be NULL or a draft that was not freed yet.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn pe_draft_free(draft: *mut PeDraft) {
    // SAFETY: as the caller guarantees
    unsafe { take_back(draft) }
}

// ---- finding the servers of an address ----

#[repr(C)]
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum PeAutoconfigSource {
    /// The provider's own configuration file
    Provider = 0,
    /// Thunderbird's database of providers
    Ispdb = 1,
    /// Nothing was found: `imap.` and `smtp.` the domain
    Guess = 2,
    /// The provider that receives the domain's mail (its MX), a provider Inbox Classic knows
    Mx = 3,
    /// The domain's SRV records (RFC 6186)
    Srv = 4,
    /// Microsoft Autodiscover (Exchange)
    Autodiscover = 5,
}

/// The servers found for an address
#[repr(C)]
pub struct PeAutoconfigInfo {
    pub imap_host: *const c_char,
    pub imap_port: u16,
    pub imap_security: PeSecurity,
    pub smtp_host: *const c_char,
    pub smtp_port: u16,
    pub smtp_security: PeSecurity,
    pub username: *const c_char,
    /// The provider takes OAuth 2.0
    pub oauth2: bool,
    pub source: PeAutoconfigSource,
    /// The provider wants an app password rather than the account's password: its name, or NULL when not
    pub app_password_provider: *const c_char,
    /// The https page that tells how to make one, NULL with the provider
    pub app_password_instructions: *const c_char,
    /// A note about the provider's sign-in, or NULL
    pub app_password_warning: *const c_char,
}

/// A lookup's result; free with `pe_autoconfig_free`
pub struct PeAutoconfig {
    info: PeAutoconfigInfo,
    _strings: Strings,
}

/// Looks up the servers of `email` (UTF-8) in the background; `AutoconfigDone` with this request in `uid`
/// follows. 0 on failure. `password` (NULL for none) answers a Microsoft Autodiscover server that asks for it,
/// over https and to that server only.
///
/// # Safety
/// `core` must be a live handle, `email` a NUL-terminated string, `password` NULL or one.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn pe_autoconfig_start(
    core: *const PeCore,
    email: *const c_char,
    password: *const c_char,
) -> u64 {
    // SAFETY: as the caller guarantees
    let Some(email) = (unsafe { arg(email) }) else {
        return 0;
    };
    // SAFETY: as the caller guarantees
    let password = unsafe { arg(password) };
    // SAFETY: as the caller guarantees
    unsafe { with(core, 0, |core| core.autoconfig(email, password).unwrap_or(0)) }
}

/// The result of a lookup after its `AutoconfigDone`, once; NULL for an address without a domain
///
/// # Safety
/// `core` must be a live handle.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn pe_autoconfig_result(core: *const PeCore, request: u64) -> *mut PeAutoconfig {
    let security = |s: pe_autoconfig::ServerSecurity| match s {
        pe_autoconfig::ServerSecurity::Tls => PeSecurity::Tls,
        pe_autoconfig::ServerSecurity::StartTls => PeSecurity::StartTls,
    };
    // SAFETY: as the caller guarantees
    unsafe {
        with(core, null_mut(), |core| {
            let Some(found) = core.autoconfig_result(request) else {
                return null_mut();
            };
            let mut strings = Strings::default();
            let hint = found.app_password.as_ref();
            let info = PeAutoconfigInfo {
                imap_host: strings.add(&found.imap.host),
                imap_port: found.imap.port,
                imap_security: security(found.imap.security),
                smtp_host: strings.add(&found.smtp.host),
                smtp_port: found.smtp.port,
                smtp_security: security(found.smtp.security),
                username: strings.add(&found.username),
                oauth2: found.oauth2,
                source: match found.source {
                    pe_autoconfig::Source::Provider => PeAutoconfigSource::Provider,
                    pe_autoconfig::Source::Ispdb => PeAutoconfigSource::Ispdb,
                    pe_autoconfig::Source::Guess => PeAutoconfigSource::Guess,
                    pe_autoconfig::Source::Mx => PeAutoconfigSource::Mx,
                    pe_autoconfig::Source::Srv => PeAutoconfigSource::Srv,
                    pe_autoconfig::Source::Autodiscover => PeAutoconfigSource::Autodiscover,
                },
                app_password_provider: hint.map_or(null(), |h| strings.add(h.provider)),
                app_password_instructions: hint.map_or(null(), |h| strings.add(h.instructions)),
                app_password_warning: hint.and_then(|h| h.warning).map_or(null(), |w| strings.add(w)),
            };
            handed(PeAutoconfig {
                info,
                _strings: strings,
            })
        })
    }
}

/// Stops a lookup the user no longer waits for
///
/// # Safety
/// `core` must be a live handle.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn pe_autoconfig_cancel(core: *const PeCore, request: u64) {
    // SAFETY: as the caller guarantees
    unsafe { with(core, (), |core| core.autoconfig_cancel(request)) }
}

/// # Safety
/// `result` must be NULL or live.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn pe_autoconfig_info(result: *const PeAutoconfig) -> *const PeAutoconfigInfo {
    // SAFETY: as the caller guarantees
    unsafe { result.as_ref() }.map_or(null(), |result| &result.info)
}

/// # Safety
/// `result` must be NULL or a result that was not freed yet.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn pe_autoconfig_free(result: *mut PeAutoconfig) {
    // SAFETY: as the caller guarantees
    unsafe { take_back(result) }
}

// ---- signing in through the browser ----

#[repr(C)]
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum PeOAuthProvider {
    None = 0,
    /// The built-in Google client
    Google = 1,
    /// The built-in Microsoft client
    Microsoft = 2,
    /// A sign-in app the user added, named by its id next to this
    App = 3,
}

/// What `provider` and `app` (for APP) name, None for NONE
fn sign_in_with(provider: PeOAuthProvider, app: i64) -> Option<SignInWith> {
    match provider {
        PeOAuthProvider::Google => Some(SignInWith::Builtin(pe_oauth::ProviderKind::Google)),
        PeOAuthProvider::Microsoft => Some(SignInWith::Builtin(pe_oauth::ProviderKind::Microsoft)),
        PeOAuthProvider::App => Some(SignInWith::App(app)),
        PeOAuthProvider::None => None,
    }
}

/// The provider and app id of the C API for `with`
fn sign_in_pair(with: SignInWith) -> (PeOAuthProvider, i64) {
    match with {
        SignInWith::Builtin(pe_oauth::ProviderKind::Google) => (PeOAuthProvider::Google, 0),
        SignInWith::Builtin(pe_oauth::ProviderKind::Microsoft) => (PeOAuthProvider::Microsoft, 0),
        SignInWith::Builtin(pe_oauth::ProviderKind::Oidc) => (PeOAuthProvider::None, 0),
        SignInWith::App(id) => (PeOAuthProvider::App, id),
    }
}

/// The provider of an IMAP server that this build can sign in to through the browser; None when there is
/// none or this build has no client ID for it
///
/// # Safety
/// `core` must be a live handle, `imap_host` a NUL-terminated string.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn pe_oauth_provider_for(core: *const PeCore, imap_host: *const c_char) -> PeOAuthProvider {
    // SAFETY: as the caller guarantees
    let Some(host) = (unsafe { arg(imap_host) }) else {
        return PeOAuthProvider::None;
    };
    // SAFETY: as the caller guarantees
    unsafe {
        with(core, PeOAuthProvider::None, |core| {
            core.oauth_provider_for(host)
                .map_or(PeOAuthProvider::None, |kind| sign_in_pair(SignInWith::Builtin(kind)).0)
        })
    }
}

/// Starts signing in with `provider` (and for APP, the sign-in app `app`) for `email`. `url` gets the page to open
/// in the browser (free it with `pe_string_free`); `SignInDone` with the returned request in `uid` follows. 0 on
/// failure.
///
/// # Safety
/// `core` must be a live handle, `email` a NUL-terminated string, `url` a valid pointer.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn pe_sign_in_begin(
    core: *const PeCore,
    provider: PeOAuthProvider,
    app: i64,
    email: *const c_char,
    url: *mut *mut c_char,
) -> u64 {
    let Some(with) = sign_in_with(provider, app) else {
        return 0;
    };
    // SAFETY: as the caller guarantees
    let Some(email) = (unsafe { arg(email) }) else {
        return 0;
    };
    if url.is_null() {
        return 0;
    }
    // SAFETY: as the caller guarantees
    let started = unsafe { self::with(core, None, |core| core.sign_in_begin(with, email).ok()) };
    let Some((request, page)) = started else {
        return 0;
    };
    // SAFETY: the caller gave a valid pointer
    unsafe { *url = into_c_string(page) };
    request
}

/// Whether a sign-in after its `SignInDone` got what an account needs; when not, `reason` gets why (free
/// it with `pe_string_free`) when it is not NULL
///
/// # Safety
/// `core` must be a live handle, `reason` NULL or a valid pointer.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn pe_sign_in_result(core: *const PeCore, request: u64, reason: *mut *mut c_char) -> bool {
    // SAFETY: as the caller guarantees
    let result = unsafe {
        with(core, Err("the engine is closed".to_string()), |core| {
            core.sign_in_result(request)
        })
    };
    match result {
        Ok(()) => true,
        Err(why) => {
            if !reason.is_null() {
                // SAFETY: the caller gave a valid pointer
                unsafe { *reason = into_c_string(why) };
            }
            false
        }
    }
}

/// Stops a sign-in the user no longer waits for
///
/// # Safety
/// `core` must be a live handle.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn pe_sign_in_cancel(core: *const PeCore, request: u64) {
    // SAFETY: as the caller guarantees
    unsafe { with(core, (), |core| core.sign_in_cancel(request)) }
}

/// Adds the account the finished sign-in `request` was for, at the provider's servers, named `name` (NULL or empty:
/// as its owner is named at the provider); its id, or 0
///
/// # Safety
/// `core` must be a live handle, `name` NULL or a NUL-terminated string.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn pe_account_add_signed_in(core: *const PeCore, request: u64, name: *const c_char) -> i64 {
    // SAFETY: as the caller guarantees
    let name = unsafe { arg(name) }.unwrap_or_default().to_string();
    // SAFETY: as the caller guarantees
    unsafe { with(core, 0, |core| core.add_signed_in_account(request, &name).unwrap_or(0)) }
}

/// Gives an account signed in through the browser the result of a new sign-in, after the old one was refused.
/// False with the reason in `error` (NULL or a pointer to a string to free with `pe_string_free`), as when the
/// browser signed in to another account.
///
/// # Safety
/// `core` must be a live handle, `error` NULL or a valid pointer.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn pe_account_reauthorize(
    core: *const PeCore,
    account: i64,
    request: u64,
    error: *mut *mut c_char,
) -> bool {
    // SAFETY: as the caller guarantees
    let outcome = unsafe { with(core, Err(None), |core| core.reauthorize(account, request).map_err(Some)) };
    // SAFETY: as the caller guarantees
    unsafe { refused(error, outcome, "the sign-in could not be used") }.is_some()
}

// ---- sign-in apps ----

/// A sign-in app as the Sign-in Apps manager lists it: a built-in client (`provider` GOOGLE or MICROSOFT, `id` 0),
/// or one the user added (`provider` APP)
#[repr(C)]
pub struct PeSignInApp {
    pub provider: PeOAuthProvider,
    pub id: i64,
    pub name: *const c_char,
    /// The issuer, or for a built-in client the host of its sign-in page
    pub issuer: *const c_char,
    /// Offered for new accounts
    pub enabled: bool,
    /// The addresses of the accounts that sign in with it, separated by ", "; empty when none
    pub used_by: *const c_char,
    /// For a built-in client: why it may be off, and what to do instead. Empty for an added app
    pub off_reason: *const c_char,
    /// What an added app was saved with (empty and 0 for a built-in client); never its secret
    pub client_id: *const c_char,
    pub has_secret: bool,
    pub scopes: *const c_char,
    pub imap_host: *const c_char,
    pub imap_port: u16,
    pub imap_security: PeSecurity,
    pub smtp_host: *const c_char,
    pub smtp_port: u16,
    pub smtp_security: PeSecurity,
}

/// The sign-in apps; free with `pe_sign_in_app_list_free`
pub struct PeSignInAppList(Rows<PeSignInApp>);

/// The sign-in apps, the built-in Microsoft and Google clients first; NULL on failure
///
/// # Safety
/// `core` must be a live handle.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn pe_sign_in_apps(core: *const PeCore) -> *mut PeSignInAppList {
    // SAFETY: as the caller guarantees
    unsafe {
        with(core, null_mut(), |core| {
            let Ok(entries) = core.sign_in_apps() else {
                return null_mut();
            };
            handed(PeSignInAppList(Rows::new(&entries, |e, strings| {
                let (provider, id) = sign_in_pair(e.with);
                let app = e.app.clone().unwrap_or_default();
                let off_reason = match e.with {
                    SignInWith::Builtin(kind) => pe_core::builtin_off_text(kind),
                    SignInWith::App(_) => String::new(),
                };
                PeSignInApp {
                    provider,
                    id,
                    name: strings.add(&e.name),
                    issuer: strings.add(&e.issuer),
                    enabled: e.enabled,
                    used_by: strings.add(&e.used_by.join(", ")),
                    off_reason: strings.add(&off_reason),
                    client_id: strings.add(&app.client_id),
                    has_secret: app.has_secret,
                    scopes: strings.add(&app.scopes),
                    imap_host: strings.add(&app.imap_host),
                    imap_port: app.imap_port,
                    imap_security: app.imap_security.into(),
                    smtp_host: strings.add(&app.smtp_host),
                    smtp_port: app.smtp_port,
                    smtp_security: app.smtp_security.into(),
                }
            })))
        })
    }
}

/// # Safety
/// `list` must be NULL or live.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn pe_sign_in_app_list_count(list: *const PeSignInAppList) -> usize {
    // SAFETY: as the caller guarantees
    Rows::count(unsafe { list.as_ref() }.map(|list| &list.0))
}

/// Row `index`, NULL past the end
///
/// # Safety
/// `list` must be NULL or live.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn pe_sign_in_app_list_get(list: *const PeSignInAppList, index: usize) -> *const PeSignInApp {
    // SAFETY: as the caller guarantees
    Rows::get(unsafe { list.as_ref() }.map(|list| &list.0), index)
}

/// # Safety
/// `list` must be NULL or a list that was not freed yet.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn pe_sign_in_app_list_free(list: *mut PeSignInAppList) {
    // SAFETY: as the caller guarantees
    unsafe { take_back(list) }
}

/// Turns a sign-in app on or off for new accounts (accounts that use it keep working); false when there is no such
/// app
///
/// # Safety
/// `core` must be a live handle.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn pe_sign_in_app_set_enabled(
    core: *const PeCore,
    provider: PeOAuthProvider,
    app: i64,
    enabled: bool,
) -> bool {
    let Some(with) = sign_in_with(provider, app) else {
        return false;
    };
    // SAFETY: as the caller guarantees
    unsafe { self::with(core, false, |core| core.set_sign_in_enabled(with, enabled).is_ok()) }
}

/// Reads the discovery document of `issuer` in the background: `SignInAppChecked` with the returned request in
/// `uid` follows. 0 with the reason in `error` (NULL or a pointer to a string to free with `pe_string_free`) when the
/// issuer is no address to read it from.
///
/// # Safety
/// `core` must be a live handle, `issuer` a NUL-terminated string, `error` NULL or a valid pointer.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn pe_sign_in_app_check(
    core: *const PeCore,
    issuer: *const c_char,
    error: *mut *mut c_char,
) -> u64 {
    // SAFETY: as the caller guarantees
    let issuer = unsafe { arg(issuer) };
    // SAFETY: as the caller guarantees
    let outcome = unsafe {
        with(core, Err(None), |core| {
            issuer.map_or(Err(None), |issuer| core.sign_in_app_check(issuer).map_err(Some))
        })
    };
    // SAFETY: as the caller guarantees
    unsafe { refused(error, outcome, "the issuer could not be checked") }.unwrap_or(0)
}

/// What the check `request` found, taken: true with what it found in `text`, or false with why the issuer can not be
/// used (free `text` with `pe_string_free`; it stays NULL while the check runs or when there is no such check)
///
/// # Safety
/// `core` must be a live handle, `text` a valid pointer.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn pe_sign_in_app_check_result(
    core: *const PeCore,
    request: u64,
    text: *mut *mut c_char,
) -> bool {
    if text.is_null() {
        return false;
    }
    // SAFETY: as the caller guarantees
    let result = unsafe { with(core, None, |core| core.sign_in_app_check_result(request)) };
    let (ok, said) = match result {
        Some(Ok(found)) => (
            true,
            format!(
                "Sign-in page: {}\r\nToken endpoint: {}",
                found.authorize_url, found.token_url
            ),
        ),
        Some(Err(reason)) => (false, reason),
        None => return false,
    };
    // SAFETY: the caller gave a valid pointer
    unsafe { *text = into_c_string(said) };
    ok
}

/// Stops a check the editor no longer waits for
///
/// # Safety
/// `core` must be a live handle.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn pe_sign_in_app_check_cancel(core: *const PeCore, request: u64) {
    // SAFETY: as the caller guarantees
    unsafe { with(core, (), |core| core.sign_in_app_check_cancel(request)) }
}

/// A sign-in app as the editor saves it (UTF-8)
#[repr(C)]
pub struct PeSignInAppForm {
    pub name: *const c_char,
    pub issuer: *const c_char,
    pub client_id: *const c_char,
    /// Separated by spaces
    pub scopes: *const c_char,
    pub imap_host: *const c_char,
    pub imap_port: u16,
    pub imap_security: PeSecurity,
    pub smtp_host: *const c_char,
    pub smtp_port: u16,
    pub smtp_security: PeSecurity,
}

#[repr(C)]
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum PeSecretChange {
    Keep = 0,
    Set = 1,
    Remove = 2,
}

/// Saves a sign-in app: a new one when `id` is 0 (turned on), else app `id`, whose accounts move to its servers.
/// Its issuer has to be checked first (`pe_sign_in_app_check`). `secret` is the client secret for SET. The app's id,
/// or 0 with the reason in `error` (NULL or a pointer to a string to free with `pe_string_free`).
///
/// # Safety
/// `core` must be a live handle, `form` a valid form with NUL-terminated strings, `secret` NULL or a NUL-terminated
/// string, `error` NULL or a valid pointer.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn pe_sign_in_app_save(
    core: *const PeCore,
    id: i64,
    form: *const PeSignInAppForm,
    change: PeSecretChange,
    secret: *const c_char,
    error: *mut *mut c_char,
) -> i64 {
    // SAFETY: as the caller guarantees
    let form = unsafe { sign_in_app_form(form) };
    // SAFETY: as the caller guarantees
    let secret = unsafe { arg(secret) };
    let change = match (change, secret) {
        (PeSecretChange::Set, Some(secret)) => Some(pe_core::SecretChange::Set(secret)),
        (PeSecretChange::Set, None) => None,
        (PeSecretChange::Keep, _) => Some(pe_core::SecretChange::Keep),
        (PeSecretChange::Remove, _) => Some(pe_core::SecretChange::Remove),
    };
    // SAFETY: as the caller guarantees
    let outcome = unsafe {
        with(core, Err(None), |core| match (form, change) {
            (Some(form), Some(change)) => core
                .save_sign_in_app((id != 0).then_some(id), &form, change)
                .map_err(Some),
            _ => Err(None),
        })
    };
    // SAFETY: as the caller guarantees
    unsafe { refused(error, outcome, "the sign-in app could not be saved") }.unwrap_or(0)
}

/// # Safety
/// `form` must be NULL or point to a form whose strings are NUL-terminated.
unsafe fn sign_in_app_form(form: *const PeSignInAppForm) -> Option<pe_core::SignInAppForm> {
    // SAFETY: as the caller guarantees
    let f = unsafe { form.as_ref() }?;
    // SAFETY: as the caller guarantees
    let text = |p| unsafe { arg(p) }.map(str::to_string);
    Some(pe_core::SignInAppForm {
        name: text(f.name)?,
        issuer: text(f.issuer)?,
        client_id: text(f.client_id)?,
        scopes: text(f.scopes)?,
        imap_host: text(f.imap_host)?,
        imap_port: f.imap_port,
        imap_security: f.imap_security.into(),
        smtp_host: text(f.smtp_host)?,
        smtp_port: f.smtp_port,
        smtp_security: f.smtp_security.into(),
    })
}

/// Removes a sign-in app and its secret; false with the reason in `error` (NULL or a pointer to a string to free
/// with `pe_string_free`), as while accounts sign in with it
///
/// # Safety
/// `core` must be a live handle, `error` NULL or a valid pointer.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn pe_sign_in_app_remove(core: *const PeCore, id: i64, error: *mut *mut c_char) -> bool {
    // SAFETY: as the caller guarantees
    let outcome = unsafe { with(core, Err(None), |core| core.remove_sign_in_app(id).map_err(Some)) };
    // SAFETY: as the caller guarantees
    unsafe { refused(error, outcome, "the sign-in app could not be removed") }.is_some()
}

/// What the editor fills a sign-in app in with for a provider, everything but the client
#[repr(C)]
pub struct PeSignInPreset {
    /// `Google`, `Microsoft`
    pub name: *const c_char,
    pub issuer: *const c_char,
    pub scopes: *const c_char,
    pub imap_host: *const c_char,
    pub imap_port: u16,
    pub imap_security: PeSecurity,
    pub smtp_host: *const c_char,
    pub smtp_port: u16,
    pub smtp_security: PeSecurity,
}

/// The presets; free with `pe_sign_in_preset_list_free`
pub struct PeSignInPresetList(Rows<PeSignInPreset>);

fn preset_security(security: pe_net::Security) -> PeSecurity {
    match security {
        pe_net::Security::Tls => PeSecurity::Tls,
        pe_net::Security::StartTls => PeSecurity::StartTls,
        pe_net::Security::Plain => PeSecurity::Plain,
    }
}

/// The providers the editor can fill a sign-in app in for
#[unsafe(no_mangle)]
pub extern "C" fn pe_sign_in_presets() -> *mut PeSignInPresetList {
    guard(|| {
        let presets = pe_oauth::Preset::all();
        handed(PeSignInPresetList(Rows::new(&presets, |p, strings| PeSignInPreset {
            name: strings.add(p.name),
            issuer: strings.add(p.issuer),
            scopes: strings.add(&p.scopes.join(" ")),
            imap_host: strings.add(&p.imap.host),
            imap_port: p.imap.port,
            imap_security: preset_security(p.imap.security),
            smtp_host: strings.add(&p.smtp.host),
            smtp_port: p.smtp.port,
            smtp_security: preset_security(p.smtp.security),
        })))
    })
    .unwrap_or(null_mut())
}

/// # Safety
/// `list` must be NULL or live.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn pe_sign_in_preset_list_count(list: *const PeSignInPresetList) -> usize {
    // SAFETY: as the caller guarantees
    Rows::count(unsafe { list.as_ref() }.map(|list| &list.0))
}

/// Row `index`, NULL past the end
///
/// # Safety
/// `list` must be NULL or live.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn pe_sign_in_preset_list_get(
    list: *const PeSignInPresetList,
    index: usize,
) -> *const PeSignInPreset {
    // SAFETY: as the caller guarantees
    Rows::get(unsafe { list.as_ref() }.map(|list| &list.0), index)
}

/// # Safety
/// `list` must be NULL or a list that was not freed yet.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn pe_sign_in_preset_list_free(list: *mut PeSignInPresetList) {
    // SAFETY: as the caller guarantees
    unsafe { take_back(list) }
}

/// The redirect URI to register a client of `issuer` with (`http://localhost`, `http://127.0.0.1` for Google); free
/// with `pe_string_free`
///
/// # Safety
/// `issuer` must be NULL or a NUL-terminated string.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn pe_sign_in_redirect_uri(issuer: *const c_char) -> *mut c_char {
    // SAFETY: as the caller guarantees
    let issuer = unsafe { arg(issuer) }.unwrap_or_default().to_string();
    guard(move || into_c_string(pe_oauth::ProviderKind::of_issuer(issuer.trim()).redirect_uri())).unwrap_or(null_mut())
}

/// How to register a client with the provider of `issuer`, for the editor; free with `pe_string_free`
///
/// # Safety
/// `issuer` must be NULL or a NUL-terminated string.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn pe_sign_in_register_hint(issuer: *const c_char) -> *mut c_char {
    // SAFETY: as the caller guarantees
    let issuer = unsafe { arg(issuer) }.unwrap_or_default().to_string();
    guard(move || into_c_string(pe_core::register_hint(issuer.trim()))).unwrap_or(null_mut())
}
