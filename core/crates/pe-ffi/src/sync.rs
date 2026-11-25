//! Settings sync through C: its state and what it syncs for the Sync settings, the place looked at and sync turned
//! on, the answer to `SettingsSyncReady`, the news a sync brought, the computers of the vault and the history of
//! edits that lost. Every word is the core's (pe-core `sync`).

use std::ffi::c_char;
use std::ptr::null_mut;

use pe_core::sync::items::Choice;
use pe_core::sync::manage::{self, Computer, HistoryRow};
use pe_core::sync::run::{PlaceSetup, Probe};

use crate::core::{PeCore, Rows, Strings, arg, handed, take_back, with};
use crate::guard;
use crate::setup::PeSetupExport;

/// What a computer syncs: each kind of data, and each kind of secret under the data it goes with
#[repr(C)]
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub struct PeSyncChoice {
    pub accounts: bool,
    /// Passwords of the accounts that sign in with one
    pub passwords: bool,
    /// Google and Microsoft sign-ins (and those of other sign-in apps)
    pub sign_ins: bool,
    pub sign_in_apps: bool,
    /// The sign-in apps' client secrets
    pub app_secrets: bool,
    pub contacts: bool,
    pub keys: bool,
    /// The user's own private keys
    pub private_keys: bool,
    pub rules: bool,
    pub trusted: bool,
    pub settings: bool,
    pub preferences: bool,
}

impl From<Choice> for PeSyncChoice {
    fn from(c: Choice) -> PeSyncChoice {
        PeSyncChoice {
            accounts: c.accounts,
            passwords: c.passwords,
            sign_ins: c.sign_ins,
            sign_in_apps: c.sign_in_apps,
            app_secrets: c.app_secrets,
            contacts: c.contacts,
            keys: c.keys,
            private_keys: c.private_keys,
            rules: c.rules,
            trusted: c.trusted,
            settings: c.settings,
            preferences: c.preferences,
        }
    }
}

impl From<PeSyncChoice> for Choice {
    fn from(c: PeSyncChoice) -> Choice {
        Choice {
            accounts: c.accounts,
            passwords: c.passwords,
            sign_ins: c.sign_ins,
            sign_in_apps: c.sign_in_apps,
            app_secrets: c.app_secrets,
            contacts: c.contacts,
            keys: c.keys,
            private_keys: c.private_keys,
            rules: c.rules,
            trusted: c.trusted,
            settings: c.settings,
            preferences: c.preferences,
        }
    }
}

/// Everything, as sync is set up
#[unsafe(no_mangle)]
pub extern "C" fn pe_sync_choice_default() -> PeSyncChoice {
    Choice::default().into()
}

/// Settings sync as the Sync settings show it
#[repr(C)]
pub struct PeSyncState {
    pub on: bool,
    pub busy: bool,
    /// Where it syncs through and as what computer, one line ("/Users/ann/Dropbox/Inbox Classic, as “MacBook”");
    /// empty while off
    pub place: *const c_char,
    /// How it went, one line: under way, the problem, or when it last synced; empty while off
    pub status: *const c_char,
    pub choice: PeSyncChoice,
}

/// [`PeSyncState`] with its strings; free with `pe_settings_sync_state_free`
pub struct PeSyncStateHandle {
    state: PeSyncState,
    _strings: Strings,
}

/// The state of settings sync now
///
/// # Safety
/// `core` must be live.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn pe_settings_sync_state(core: *const PeCore) -> *mut PeSyncStateHandle {
    // SAFETY: as the caller guarantees
    unsafe {
        with(core, null_mut(), |core| {
            let state = core.settings_sync_state();
            let mut strings = Strings::default();
            let place = manage::place_words(&state);
            let status = manage::status_words(&state);
            handed(PeSyncStateHandle {
                state: PeSyncState {
                    on: state.on,
                    busy: state.busy,
                    place: strings.add(&place),
                    status: strings.add(&status),
                    choice: state.choice.unwrap_or_default().into(),
                },
                _strings: strings,
            })
        })
    }
}

/// # Safety
/// `state` must be NULL or a live handle.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn pe_settings_sync_state_get(state: *const PeSyncStateHandle) -> *const PeSyncState {
    // SAFETY: as the caller guarantees
    unsafe { state.as_ref() }.map_or(std::ptr::null(), |s| &s.state)
}

/// # Safety
/// `state` must be NULL or a handle not freed yet.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn pe_settings_sync_state_free(state: *mut PeSyncStateHandle) {
    // SAFETY: as the caller guarantees
    unsafe { take_back(state) }
}

/// What a computer syncs changed (a switch of the Sync settings): a sync follows
///
/// # Safety
/// `core` must be live.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn pe_settings_sync_set_choice(core: *const PeCore, choice: PeSyncChoice) {
    // SAFETY: as the caller guarantees
    unsafe {
        with(core, (), |core| {
            let _ = core.settings_sync_set_choice(choice.into());
        })
    }
}

/// Where the vault is: a folder (`path`), or an S3-compatible bucket (the others)
#[repr(C)]
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
#[allow(dead_code)] // made by the apps, read here
pub enum PeSyncPlaceKind {
    Folder = 0,
    Bucket = 1,
}

/// A place as the setup window takes it; strings UTF-8, NULL for empty
#[repr(C)]
pub struct PeSyncPlace {
    pub kind: PeSyncPlaceKind,
    pub path: *const c_char,
    /// `https://s3.eu-central-1.amazonaws.com`, `https://<account>.r2.cloudflarestorage.com`
    pub endpoint: *const c_char,
    /// Empty for `us-east-1`; `auto` for R2
    pub region: *const c_char,
    pub bucket: *const c_char,
    /// A folder in the bucket, empty for its root
    pub prefix: *const c_char,
    pub access_key: *const c_char,
}

/// # Safety
/// `place` must be NULL or valid, its strings NULL or NUL-terminated.
unsafe fn place_of(place: *const PeSyncPlace) -> Option<PlaceSetup> {
    // SAFETY: as the caller guarantees
    let place = unsafe { place.as_ref() }?;
    // SAFETY: as the caller guarantees
    let text = |s: *const c_char| unsafe { arg(s) }.unwrap_or_default().trim().to_string();
    Some(match place.kind {
        PeSyncPlaceKind::Folder => PlaceSetup::Folder { path: text(place.path) },
        PeSyncPlaceKind::Bucket => PlaceSetup::Bucket {
            endpoint: text(place.endpoint),
            region: text(place.region),
            bucket: text(place.bucket),
            prefix: text(place.prefix).trim_matches('/').to_string(),
            access_key: text(place.access_key),
        },
    })
}

/// What a probe found
#[repr(C)]
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum PeSyncProbe {
    /// It is still looking
    Waiting = 0,
    /// Nothing there yet: this computer starts the vault
    Empty = 1,
    /// A vault: this computer joins it
    Vault = 2,
    /// It could not be reached: `pe_settings_sync_probe` says why
    Problem = 3,
}

/// Looks at a place on the core's runtime: `SettingsSyncChanged` when `pe_settings_sync_probe` has the answer.
/// `secret` is the bucket's secret access key (NULL for a folder).
///
/// # Safety
/// `core` must be live, `place` valid, `secret` NULL or NUL-terminated.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn pe_settings_sync_probe_start(
    core: *const PeCore,
    place: *const PeSyncPlace,
    secret: *const c_char,
) {
    // SAFETY: as the caller guarantees
    let (Some(place), secret) = (unsafe { place_of(place) }, unsafe { arg(secret) }) else {
        return;
    };
    // SAFETY: as the caller guarantees
    unsafe {
        with(core, (), |core| {
            let _ = core.settings_sync_probe_start(place, secret.map(str::to_string));
        })
    }
}

/// The answer of the last probe; for `Problem`, the reason in `error` (NULL or a pointer to a string to free with
/// `pe_string_free`)
///
/// # Safety
/// `core` must be live, `error` NULL or a valid pointer.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn pe_settings_sync_probe(core: *const PeCore, error: *mut *mut c_char) -> PeSyncProbe {
    // SAFETY: as the caller guarantees
    let probe = unsafe { with(core, None, |core| core.settings_sync_probe()) };
    match probe {
        None => PeSyncProbe::Waiting,
        Some(Probe::Empty) => PeSyncProbe::Empty,
        Some(Probe::Vault) => PeSyncProbe::Vault,
        Some(Probe::Problem(why)) => {
            if !error.is_null() {
                // SAFETY: the caller gave a valid pointer
                unsafe { *error = crate::into_c_string(pe_core::sentence(&why)) };
            }
            PeSyncProbe::Problem
        }
    }
}

/// Turns sync on: a new vault in an empty place sealed with `passphrase`, or the vault there opened with it; the
/// first sync starts by itself. False with the reason in `error` (a wrong passphrase, a place that can not be
/// reached).
///
/// # Safety
/// `core` must be live, `place` valid, the strings NULL or NUL-terminated, `error` NULL or a valid pointer.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn pe_settings_sync_turn_on(
    core: *const PeCore,
    place: *const PeSyncPlace,
    secret: *const c_char,
    passphrase: *const c_char,
    name: *const c_char,
    choice: PeSyncChoice,
    error: *mut *mut c_char,
) -> bool {
    // SAFETY: as the caller guarantees
    let (place, secret, passphrase, name) = unsafe {
        (
            place_of(place),
            arg(secret),
            arg(passphrase),
            arg(name).unwrap_or_default(),
        )
    };
    let (Some(place), Some(passphrase)) = (place, passphrase) else {
        return false;
    };
    // SAFETY: as the caller guarantees
    let done = unsafe {
        with(core, Err(String::new()), |core| {
            guard(|| core.settings_sync_turn_on(place, secret, passphrase, name, choice.into()))
                .unwrap_or_else(|| Err(String::new()))
        })
    };
    match done {
        Ok(()) => true,
        Err(why) => {
            if !error.is_null() {
                // SAFETY: the caller gave a valid pointer
                unsafe { *error = crate::into_c_string(pe_core::sentence(&why)) };
            }
            false
        }
    }
}

/// Turns sync off on this computer: the vault and the other computers stay as they are
///
/// # Safety
/// `core` must be live.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn pe_settings_sync_turn_off(core: *const PeCore) {
    // SAFETY: as the caller guarantees
    unsafe {
        with(core, (), |core| {
            let _ = core.settings_sync_turn_off();
        })
    }
}

/// Sync Now
///
/// # Safety
/// `core` must be live.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn pe_settings_sync_now(core: *const PeCore) {
    // SAFETY: as the caller guarantees
    unsafe { with(core, (), |core| core.settings_sync_now()) }
}

/// The answer to `SettingsSyncReady`, on the window's thread: what the others wrote applied here and what changed
/// here sent. `prefs` carries the app preferences now (`pe_setup_export_set_pref`; the parts are not read), NULL
/// for none.
///
/// # Safety
/// `core` must be live, `prefs` NULL or a live export.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn pe_settings_sync_continue(core: *const PeCore, prefs: *const PeSetupExport) {
    // SAFETY: as the caller guarantees
    let prefs = unsafe { prefs.as_ref() }
        .map(|p| p.prefs().to_vec())
        .unwrap_or_default();
    // SAFETY: as the caller guarantees
    unsafe {
        with(core, (), |core| {
            let _ = core.settings_sync_continue(&prefs);
        })
    }
}

/// An app preference another computer changed
#[repr(C)]
pub struct PeSyncPref {
    pub name: *const c_char,
    pub value: *const c_char,
}

/// What the last syncs brought: app preferences to apply, and a notice in words (empty for none); free with
/// `pe_settings_sync_news_free`
pub struct PeSyncNews {
    prefs: Rows<PeSyncPref>,
    notice: *const c_char,
    _strings: Strings,
}

/// The news of the syncs since it was last taken, taken (each once)
///
/// # Safety
/// `core` must be live.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn pe_settings_sync_news(core: *const PeCore) -> *mut PeSyncNews {
    // SAFETY: as the caller guarantees
    unsafe {
        with(core, null_mut(), |core| {
            let news = core.settings_sync_news();
            let mut strings = Strings::default();
            let notice = strings.add(&news.notice());
            let prefs = Rows::new(&news.prefs, |(name, value), strings| PeSyncPref {
                name: strings.add(name),
                value: strings.add(value),
            });
            handed(PeSyncNews {
                prefs,
                notice,
                _strings: strings,
            })
        })
    }
}

/// # Safety
/// `news` must be NULL or a live handle.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn pe_settings_sync_news_prefs_count(news: *const PeSyncNews) -> usize {
    // SAFETY: as the caller guarantees
    Rows::count(unsafe { news.as_ref() }.map(|n| &n.prefs))
}

/// # Safety
/// `news` must be NULL or a live handle.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn pe_settings_sync_news_pref(news: *const PeSyncNews, index: usize) -> *const PeSyncPref {
    // SAFETY: as the caller guarantees
    Rows::get(unsafe { news.as_ref() }.map(|n| &n.prefs), index)
}

/// The notice, empty when there is nothing to say
///
/// # Safety
/// `news` must be NULL or a live handle.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn pe_settings_sync_news_notice(news: *const PeSyncNews) -> *const c_char {
    // SAFETY: as the caller guarantees
    unsafe { news.as_ref() }.map_or(c"".as_ptr(), |n| n.notice)
}

/// # Safety
/// `news` must be NULL or a handle not freed yet.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn pe_settings_sync_news_free(news: *mut PeSyncNews) {
    // SAFETY: as the caller guarantees
    unsafe { take_back(news) }
}

/// A computer of the vault
#[repr(C)]
pub struct PeSyncComputer {
    /// What `pe_settings_sync_remove_computer` takes
    pub device: *const c_char,
    pub name: *const c_char,
    /// When it last synced, in words
    pub seen: *const c_char,
    pub this: bool,
}

/// The computers of the vault; free with `pe_settings_sync_computers_free`
pub struct PeSyncComputers(Rows<PeSyncComputer>);

/// Reads the computers of the vault on the runtime: `SettingsSyncChanged` when `pe_settings_sync_computers` has them
///
/// # Safety
/// `core` must be live.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn pe_settings_sync_computers_start(core: *const PeCore) {
    // SAFETY: as the caller guarantees
    unsafe {
        with(core, (), |core| {
            let _ = core.settings_sync_computers_start();
        })
    }
}

/// The computers read, NULL while they are read
///
/// # Safety
/// `core` must be live.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn pe_settings_sync_computers(core: *const PeCore) -> *mut PeSyncComputers {
    // SAFETY: as the caller guarantees
    let found: Option<Vec<Computer>> = unsafe { with(core, None, |core| core.settings_sync_computers()) };
    found.map_or(null_mut(), |found| {
        handed(PeSyncComputers(Rows::new(&found, |c, strings| PeSyncComputer {
            device: strings.add(&c.device),
            name: strings.add(&c.name),
            seen: strings.add(&c.seen),
            this: c.this,
        })))
    })
}

/// # Safety
/// `list` must be NULL or a live handle.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn pe_settings_sync_computers_count(list: *const PeSyncComputers) -> usize {
    // SAFETY: as the caller guarantees
    Rows::count(unsafe { list.as_ref() }.map(|l| &l.0))
}

/// # Safety
/// `list` must be NULL or a live handle.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn pe_settings_sync_computers_get(
    list: *const PeSyncComputers,
    index: usize,
) -> *const PeSyncComputer {
    // SAFETY: as the caller guarantees
    Rows::get(unsafe { list.as_ref() }.map(|l| &l.0), index)
}

/// # Safety
/// `list` must be NULL or a handle not freed yet.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn pe_settings_sync_computers_free(list: *mut PeSyncComputers) {
    // SAFETY: as the caller guarantees
    unsafe { take_back(list) }
}

/// Takes a computer out of the vault (lost or given away): it stops syncing the next time it tries, what it wrote
/// stays; `SettingsSyncChanged` when it is done
///
/// # Safety
/// `core` must be live, `device` NUL-terminated.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn pe_settings_sync_remove_computer(core: *const PeCore, device: *const c_char) {
    // SAFETY: as the caller guarantees
    let Some(device) = (unsafe { arg(device) }) else { return };
    // SAFETY: as the caller guarantees
    unsafe {
        with(core, (), |core| {
            let _ = core.settings_sync_remove_computer(device);
        })
    }
}

/// An edit from another computer that one made here at the same time replaced
#[repr(C)]
pub struct PeSyncHistoryRow {
    /// What `pe_settings_sync_restore` takes
    pub id: i64,
    pub when: *const c_char,
    /// What it was an edit of: "Contact Ann Lee"
    pub item: *const c_char,
    /// The value it set, quoted and shortened; empty when it is not text
    pub value: *const c_char,
    /// The computer it came from
    pub source: *const c_char,
}

/// The history; free with `pe_settings_sync_history_free`
pub struct PeSyncHistory(Rows<PeSyncHistoryRow>);

/// The edits that lost to a later one, newest first
///
/// # Safety
/// `core` must be live.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn pe_settings_sync_history(core: *const PeCore) -> *mut PeSyncHistory {
    // SAFETY: as the caller guarantees
    let rows: Vec<HistoryRow> = unsafe {
        with(core, Vec::new(), |core| {
            core.settings_sync_history().unwrap_or_default()
        })
    };
    handed(PeSyncHistory(Rows::new(&rows, |row, strings| PeSyncHistoryRow {
        id: row.id,
        when: strings.add(&row.when),
        item: strings.add(&row.item),
        value: strings.add(&row.value),
        source: strings.add(&row.source),
    })))
}

/// # Safety
/// `list` must be NULL or a live handle.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn pe_settings_sync_history_count(list: *const PeSyncHistory) -> usize {
    // SAFETY: as the caller guarantees
    Rows::count(unsafe { list.as_ref() }.map(|l| &l.0))
}

/// # Safety
/// `list` must be NULL or a live handle.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn pe_settings_sync_history_get(
    list: *const PeSyncHistory,
    index: usize,
) -> *const PeSyncHistoryRow {
    // SAFETY: as the caller guarantees
    Rows::get(unsafe { list.as_ref() }.map(|l| &l.0), index)
}

/// # Safety
/// `list` must be NULL or a handle not freed yet.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn pe_settings_sync_history_free(list: *mut PeSyncHistory) {
    // SAFETY: as the caller guarantees
    unsafe { take_back(list) }
}

/// An edit of the history put back, made here again so the next sync takes it to the others (an app preference
/// comes back in `pe_settings_sync_news`). `prefs` as for `pe_settings_sync_continue`. False when its item is gone.
///
/// # Safety
/// `core` must be live, `prefs` NULL or a live export.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn pe_settings_sync_restore(core: *const PeCore, id: i64, prefs: *const PeSetupExport) -> bool {
    // SAFETY: as the caller guarantees
    let prefs = unsafe { prefs.as_ref() }
        .map(|p| p.prefs().to_vec())
        .unwrap_or_default();
    // SAFETY: as the caller guarantees
    unsafe {
        with(core, false, |core| {
            core.settings_sync_restore(id, &prefs).unwrap_or(false)
        })
    }
}

/// A restore point: how things were before a sync took something away
#[repr(C)]
pub struct PeSyncRestorePoint {
    /// What `pe_settings_sync_restore_point_read` takes
    pub path: *const c_char,
    pub when: *const c_char,
}

/// The restore points, newest first; free with `pe_settings_sync_restore_points_free`
pub struct PeSyncRestorePoints(Rows<PeSyncRestorePoint>);

/// The restore points kept
///
/// # Safety
/// `core` must be live.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn pe_settings_sync_restore_points(core: *const PeCore) -> *mut PeSyncRestorePoints {
    // SAFETY: as the caller guarantees
    let points = unsafe { with(core, Vec::new(), |core| core.settings_sync_restore_points()) };
    handed(PeSyncRestorePoints(Rows::new(&points, |point, strings| {
        PeSyncRestorePoint {
            path: strings.add(&point.path.to_string_lossy()),
            when: strings.add(&point.when),
        }
    })))
}

/// # Safety
/// `list` must be NULL or a live handle.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn pe_settings_sync_restore_points_count(list: *const PeSyncRestorePoints) -> usize {
    // SAFETY: as the caller guarantees
    Rows::count(unsafe { list.as_ref() }.map(|l| &l.0))
}

/// # Safety
/// `list` must be NULL or a live handle.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn pe_settings_sync_restore_points_get(
    list: *const PeSyncRestorePoints,
    index: usize,
) -> *const PeSyncRestorePoint {
    // SAFETY: as the caller guarantees
    Rows::get(unsafe { list.as_ref() }.map(|l| &l.0), index)
}

/// # Safety
/// `list` must be NULL or a handle not freed yet.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn pe_settings_sync_restore_points_free(list: *mut PeSyncRestorePoints) {
    // SAFETY: as the caller guarantees
    unsafe { take_back(list) }
}

/// A restore point read as a setup file, for the Import window (`pe_setup_import` brings back what the user
/// chooses of it); NULL with the reason in `error` (NULL or a pointer to a string to free with `pe_string_free`)
///
/// # Safety
/// `core` must be live, `path` NUL-terminated, `error` NULL or a valid pointer.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn pe_settings_sync_restore_point_read(
    core: *const PeCore,
    path: *const c_char,
    error: *mut *mut c_char,
) -> *mut crate::setup::PeSetupFile {
    // SAFETY: as the caller guarantees
    let Some(path) = (unsafe { arg(path) }) else {
        return null_mut();
    };
    // SAFETY: as the caller guarantees
    let read = unsafe { with(core, None, |core| Some(core.settings_sync_restore_point(path.as_ref()))) };
    match read {
        Some(Ok(file)) => handed(crate::setup::file_handle(file)),
        Some(Err(why)) => {
            if !error.is_null() {
                // SAFETY: the caller gave a valid pointer
                unsafe { *error = crate::into_c_string(pe_core::sentence(&why.to_string())) };
            }
            null_mut()
        }
        None => null_mut(),
    }
}
