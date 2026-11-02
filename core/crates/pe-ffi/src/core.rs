//! The mail engine through C: a `PeCore` handle, lists of rows, the message view, and events
//! delivered to a callback.
//!
//! Rows are `repr(C)` structs whose strings belong to the list or view they came from: they stay
//! valid until that is freed. Functions that fail return NULL, 0 or false.

use std::ffi::{CStr, CString, c_char, c_void};
use std::ptr::{null, null_mut};

use pe_core::{Core, DraftKind, Event, FailureKind, Outgoing};
use pe_imap::SpecialUse;
use pe_store::{AccountSettings, Security, Sort, SortField};

use crate::{c_string, guard, into_c_string};

/// Owns the strings of rows handed to C
#[derive(Default)]
struct Strings(Vec<CString>);

impl Strings {
    /// A C string that lives as long as `self`; NUL inside is replaced
    fn add(&mut self, text: &str) -> *const c_char {
        let text = c_string(text.to_string());
        // the bytes are on the heap, moving the CString into the Vec does not move them
        let pointer = text.as_ptr();
        self.0.push(text);
        pointer
    }
}

/// The rows of a list handed to C, with the strings they point to
struct Rows<T> {
    rows: Vec<T>,
    _strings: Strings,
}

impl<T> Rows<T> {
    fn new<S>(items: &[S], mut row: impl FnMut(&S, &mut Strings) -> T) -> Self {
        let mut strings = Strings::default();
        let rows = items.iter().map(|item| row(item, &mut strings)).collect();
        Rows {
            rows,
            _strings: strings,
        }
    }

    fn count(list: Option<&Self>) -> usize {
        list.map_or(0, |list| list.rows.len())
    }

    fn get(list: Option<&Self>, index: usize) -> *const T {
        list.and_then(|list| list.rows.get(index)).map_or(null(), |row| row)
    }
}

/// Moves a value to C
fn handed<T>(value: T) -> *mut T {
    Box::into_raw(Box::new(value))
}

/// Frees what [`handed`] gave C
///
/// # Safety
/// `value` must be NULL or from [`handed`], freed once.
unsafe fn take_back<T>(value: *mut T) {
    if !value.is_null() {
        // SAFETY: as the caller guarantees
        drop(unsafe { Box::from_raw(value) });
    }
}

/// Reads a C string argument; None for NULL or invalid UTF-8
///
/// # Safety
/// `text` must be NULL or a NUL-terminated string.
unsafe fn arg<'a>(text: *const c_char) -> Option<&'a str> {
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
    /// Comes after everything the sync found, failures included
    SyncFinished = 2,
    /// The folder list of `account` changed
    FoldersChanged = 3,
    /// The messages of `folder` or their flags changed
    FolderChanged = 4,
    /// `pe_message_view` can show `folder`/`uid` now
    MessageReady = 5,
    /// Work for `account` failed: `failure` and `message` say what
    Failed = 6,
    /// A message from `account` was sent
    MessageSent = 7,
    /// The lookup `uid` of `pe_autoconfig_start` is done: `pe_autoconfig_result`
    AutoconfigDone = 8,
    /// The sign-in `uid` of `pe_sign_in_begin` finished: `pe_sign_in_result`
    SignInDone = 9,
    /// The view `uid` of `pe_message_view_start` is built: `pe_message_view_result`
    ViewReady = 10,
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
    /// For `Failed`, UTF-8; NULL otherwise
    pub message: *const c_char,
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
            Event::SyncFinished { account } => (PeEventKind::SyncFinished, *account, 0, 0),
            Event::FoldersChanged { account } => (PeEventKind::FoldersChanged, *account, 0, 0),
            Event::FolderChanged { account, folder } => (PeEventKind::FolderChanged, *account, *folder, 0),
            Event::MessageReady { folder, uid } => (PeEventKind::MessageReady, 0, *folder, *uid),
            Event::Failed { account, .. } => (PeEventKind::Failed, *account, 0, 0),
            Event::MessageSent { account } => (PeEventKind::MessageSent, *account, 0, 0),
            Event::AutoconfigDone { request } => (PeEventKind::AutoconfigDone, 0, 0, *request),
            Event::SignInDone { request } => (PeEventKind::SignInDone, 0, 0, *request),
            Event::ViewReady { request } => (PeEventKind::ViewReady, 0, 0, *request),
        };
        let (failure, message) = match event {
            Event::Failed { kind, message, .. } => (kind.into(), Some(c_string(message))),
            _ => (PeFailureKind::None, None),
        };
        let event = PeEvent {
            kind,
            account,
            folder,
            uid,
            failure,
            message: message.as_ref().map_or(null(), |m| m.as_ptr()),
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
pub struct PeCore(Core);

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
        core.map_or(null_mut(), |core| handed(PeCore(core)))
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
unsafe fn with<T>(core: *const PeCore, fallback: T, f: impl FnOnce(&Core) -> T) -> T {
    // SAFETY: the caller guarantees a live handle
    let Some(core) = (unsafe { core.as_ref() }) else {
        return fallback;
    };
    guard(|| f(&core.0)).unwrap_or(fallback)
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
    let security = |s: pe_store::Security| match s {
        pe_store::Security::Tls => PeSecurity::Tls,
        pe_store::Security::StartTls => PeSecurity::StartTls,
        pe_store::Security::Plain => PeSecurity::Plain,
    };
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
    /// `pe_sign_in_begin` and `pe_account_reauthorize`, not for a password
    pub oauth: PeOAuthProvider,
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
            handed(PeAccountList(Rows::new(&accounts, |a, strings| PeAccount {
                id: a.id,
                name: strings.add(&a.settings.name),
                email: strings.add(&a.settings.email),
                oauth: match &a.settings.auth {
                    pe_store::Auth::OAuth2(name) => match pe_oauth::ProviderKind::parse(name) {
                        Some(pe_oauth::ProviderKind::Google) => PeOAuthProvider::Google,
                        Some(pe_oauth::ProviderKind::Microsoft) => PeOAuthProvider::Microsoft,
                        None => PeOAuthProvider::None,
                    },
                    pe_store::Auth::Password => PeOAuthProvider::None,
                },
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
    /// The name to show
    pub name: *const c_char,
    /// 0 for a top level folder
    pub depth: u32,
    /// The Inbox or a special folder: not renamed or deleted
    pub fixed: bool,
    pub special_use: PeSpecialUse,
    /// False for a folder that only holds other folders
    pub selectable: bool,
    pub total: u64,
    pub unread: u64,
}

/// The folders of an account; free with `pe_folder_list_free`
pub struct PeFolderList(Rows<PeFolder>);

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
            let depths: std::collections::HashMap<i64, usize> =
                folders.iter().map(|f| f.id).zip(pe_core::tree_depths(&infos)).collect();
            handed(PeFolderList(Rows::new(&folders, |f, strings| PeFolder {
                id: f.id,
                account: f.account_id,
                path: strings.add(&f.info.path),
                name: strings.add(&f.info.name),
                depth: u32::try_from(depths.get(&f.id).copied().unwrap_or(0)).unwrap_or(u32::MAX),
                fixed: pe_core::is_fixed_folder(&f.info),
                special_use: special_use(f.info.special_use.as_deref()),
                selectable: f.info.selectable,
                total: f.total,
                unread: f.unread,
            })))
        })
    }
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

/// How many messages of a folder `pe_messages` lists with `find` (UTF-8, NULL for all), and how many of them are
/// unread
///
/// # Safety
/// `core` must be a live handle, `find` NULL or a NUL-terminated string, `total` and `unread` valid pointers.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn pe_message_count(
    core: *const PeCore,
    folder: i64,
    find: *const c_char,
    total: *mut u64,
    unread: *mut u64,
) -> bool {
    if total.is_null() || unread.is_null() {
        return false;
    }
    // SAFETY: as the caller guarantees
    let find = unsafe { arg(find) }.unwrap_or_default();
    // SAFETY: as the caller guarantees
    let Some(counts) = (unsafe { with(core, None, |core| core.count_matching(folder, find).ok()) }) else {
        return false;
    };
    // SAFETY: the caller gave valid pointers
    unsafe { (*total, *unread) = counts };
    true
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
    pub answered: bool,
    pub has_attachments: bool,
}

/// A page of the message list; free with `pe_message_list_free`
pub struct PeMessageList(Rows<PeMessage>);

/// `limit` messages of a folder from `offset` on, in the order asked for; with `find` (UTF-8) only those with it
/// in their subject, sender or recipients, NULL or empty for all. NULL on failure.
///
/// # Safety
/// `core` must be a live handle, `find` NULL or a NUL-terminated string.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn pe_messages(
    core: *const PeCore,
    folder: i64,
    sort: PeSortField,
    ascending: bool,
    find: *const c_char,
    offset: u64,
    limit: u64,
) -> *mut PeMessageList {
    // SAFETY: as the caller guarantees
    let find = unsafe { arg(find) }.unwrap_or_default();
    let sort = Sort {
        field: sort.into(),
        ascending,
    };
    // SAFETY: as the caller guarantees
    unsafe {
        with(core, null_mut(), |core| {
            let Ok(messages) = core.messages_matching(folder, sort, find, offset, limit) else {
                return null_mut();
            };
            handed(PeMessageList(Rows::new(&messages, |m, strings| {
                let info = &m.info;
                PeMessage {
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
                    answered: info.answered(),
                    has_attachments: info.has_attachments,
                }
            })))
        })
    }
}

/// Where message `uid` is in the message list of a folder in this order, -1 when it is not there
///
/// # Safety
/// `core` must be a live handle.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn pe_message_index(
    core: *const PeCore,
    folder: i64,
    sort: PeSortField,
    ascending: bool,
    find: *const c_char,
    uid: u64,
) -> i64 {
    // SAFETY: as the caller guarantees
    let find = unsafe { arg(find) }.unwrap_or_default();
    let sort = Sort {
        field: sort.into(),
        ascending,
    };
    // SAFETY: as the caller guarantees
    unsafe {
        with(core, -1, |core| {
            match core.message_index_matching(folder, sort, find, uid) {
                Ok(Some(index)) => i64::try_from(index).unwrap_or(-1),
                _ => -1,
            }
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

/// Flags a message or takes its flag away: in the store now (`FolderChanged` follows), on the server in the
/// background
///
/// # Safety
/// `core` must be a live handle.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn pe_message_set_flagged(core: *const PeCore, folder: i64, uid: u64, flagged: bool) -> bool {
    // SAFETY: as the caller guarantees
    unsafe { with(core, false, |core| core.set_flagged(folder, uid, flagged).is_ok()) }
}

/// Moves a message to another folder of its account: out of the list now (`FolderChanged`), into the other
/// folder once the server has it (`FolderChanged` of that folder). False for a folder of another account, the
/// folder it is in, or one that holds no messages.
///
/// # Safety
/// `core` must be a live handle.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn pe_message_move(core: *const PeCore, folder: i64, uid: u64, to: i64) -> bool {
    // SAFETY: as the caller guarantees
    unsafe { with(core, false, |core| core.move_message(folder, uid, to).is_ok()) }
}

/// Whether deleting a message of `folder` removes it for good (it is Deleted Items, or the account has none), so the
/// window can ask first
///
/// # Safety
/// `core` must be a live handle.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn pe_folder_deletes_for_good(core: *const PeCore, folder: i64) -> bool {
    // SAFETY: as the caller guarantees
    unsafe { with(core, false, |core| core.deletes_for_good(folder).unwrap_or(false)) }
}

/// Deletes a message: into Deleted Items, or for good when it is in there or the account has none. Out of the list
/// now (`FolderChanged`), on the server in the background.
///
/// # Safety
/// `core` must be a live handle.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn pe_message_delete(core: *const PeCore, folder: i64, uid: u64) -> bool {
    // SAFETY: as the caller guarantees
    unsafe { with(core, false, |core| core.delete_message(folder, uid).is_ok()) }
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
    match outcome {
        Ok(()) => true,
        Err(reason) => {
            if !error.is_null() {
                let text = reason.map_or_else(|| "the folder could not be changed".to_string(), |e| e.to_string());
                // SAFETY: the caller gave a valid pointer
                unsafe { *error = into_c_string(text) };
            }
            false
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
}

/// A message as the preview shows it; free with `pe_message_view_free`
pub struct PeMessageView {
    info: PeMessageInfo,
    attachments: Vec<PeAttachment>,
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
    let info = PeMessageInfo {
        subject: strings.add(&view.subject),
        from: strings.add(&view.from),
        to: strings.add(&view.to),
        cc: strings.add(&view.cc),
        date: view.date.unwrap_or(0),
        has_date: view.date.is_some(),
        document: strings.add(&view.document),
        attachment_count: attachments.len(),
    };
    handed(PeMessageView {
        info,
        attachments,
        _strings: strings,
    })
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

/// Frees bytes from `pe_attachment_data`
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
    })
}

/// Sends a message from an account in the background: `MessageSent`, or `Failed` with the server's
/// answer. A recipient that is no address or a file that is not there fails right away: false,
/// with the reason in `error` when it is not NULL (free it with `pe_string_free`).
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
    match result {
        Ok(()) => true,
        Err(reason) => {
            if !error.is_null() {
                let text = reason.map_or_else(|| "the message could not be sent".to_string(), |e| e.to_string());
                // SAFETY: the caller gave a valid pointer
                unsafe { *error = into_c_string(text) };
            }
            false
        }
    }
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
    /// For PeOutgoing, NULL when there is none
    pub in_reply_to: *const c_char,
    /// For PeOutgoing, space separated
    pub references: *const c_char,
}

/// A draft; free with `pe_draft_free`
pub struct PeDraft {
    info: PeDraftInfo,
    _strings: Strings,
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
        with(core, null_mut(), |core| {
            let Ok(Some(draft)) = core.draft(folder, uid, kind) else {
                return null_mut();
            };
            let mut strings = Strings::default();
            let info = PeDraftInfo {
                to: strings.add(&draft.to),
                cc: strings.add(&draft.cc),
                subject: strings.add(&draft.subject),
                quote: strings.add(&draft.quote),
                quote_folded: draft.quote_folded,
                in_reply_to: draft.in_reply_to.as_deref().map_or(null(), |r| strings.add(r)),
                references: strings.add(&draft.references.join(" ")),
            };
            handed(PeDraft {
                info,
                _strings: strings,
            })
        })
    }
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
    /// The provider that receives the domain's mail (its MX), a provider PostalExpress knows
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
    Google = 1,
    Microsoft = 2,
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
            match core.oauth_provider_for(host) {
                Some(pe_oauth::ProviderKind::Google) => PeOAuthProvider::Google,
                Some(pe_oauth::ProviderKind::Microsoft) => PeOAuthProvider::Microsoft,
                None => PeOAuthProvider::None,
            }
        })
    }
}

/// Starts signing in to `provider` for `email`. `url` gets the https:// page to open in the browser (free
/// it with `pe_string_free`); `SignInDone` with the returned request in `uid` follows. 0 on failure.
///
/// # Safety
/// `core` must be a live handle, `email` a NUL-terminated string, `url` a valid pointer.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn pe_sign_in_begin(
    core: *const PeCore,
    provider: PeOAuthProvider,
    email: *const c_char,
    url: *mut *mut c_char,
) -> u64 {
    let kind = match provider {
        PeOAuthProvider::Google => pe_oauth::ProviderKind::Google,
        PeOAuthProvider::Microsoft => pe_oauth::ProviderKind::Microsoft,
        PeOAuthProvider::None => return 0,
    };
    // SAFETY: as the caller guarantees
    let Some(email) = (unsafe { arg(email) }) else {
        return 0;
    };
    if url.is_null() {
        return 0;
    }
    // SAFETY: as the caller guarantees
    let started = unsafe { with(core, None, |core| core.sign_in_begin(kind, email).ok()) };
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

/// Adds an account that signs in with what the finished sign-in `request` got; its id, or 0
///
/// # Safety
/// `core` must be a live handle, `settings` valid settings.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn pe_account_add_oauth(
    core: *const PeCore,
    settings: *const PeAccountSettings,
    request: u64,
) -> i64 {
    // SAFETY: as the caller guarantees
    let Some(settings) = (unsafe { self::settings(settings) }) else {
        return 0;
    };
    // SAFETY: as the caller guarantees
    unsafe { with(core, 0, |core| core.add_account_oauth(&settings, request).unwrap_or(0)) }
}

/// Gives an account signed in through the browser the result of a new sign-in, after the old one was refused
///
/// # Safety
/// `core` must be a live handle.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn pe_account_reauthorize(core: *const PeCore, account: i64, request: u64) -> bool {
    // SAFETY: as the caller guarantees
    unsafe { with(core, false, |core| core.reauthorize(account, request).is_ok()) }
}
