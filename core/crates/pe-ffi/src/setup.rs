//! The setup file through C: an export built up and written, a file read into a handle the import window lists from
//! (its accounts, what each part holds, the app preferences it carries), and the import of the parts and accounts
//! chosen, which answers with lines of words. No JSON crosses: the core reads and writes the file, the apps hand their
//! preferences in by name and take them back by name. The rules are the core's (pe-core `setup`).

use std::ffi::c_char;
use std::ptr::{null, null_mut};

use pe_core::setup::{self, ImportChoice, ImportLineKind, ImportSummary, Parts, PrefKind, SetupError, SetupFile};
use zeroize::Zeroizing;

use crate::core::{PeCore, Rows, Strings, arg, handed, refused, take_back, with};
use crate::guard;
use crate::selection::PeTextList;

/// The parts of a setup file, as flags
pub const PE_SETUP_SETTINGS: u32 = 1;
/// The window preferences the app hands in (`pe_setup_export_set_pref`) and takes back (`pe_setup_file_pref`)
pub const PE_SETUP_PREFERENCES: u32 = 2;
pub const PE_SETUP_ACCOUNTS: u32 = 4;
pub const PE_SETUP_SIGN_IN_APPS: u32 = 8;
pub const PE_SETUP_CONTACTS: u32 = 16;
pub const PE_SETUP_KEYS: u32 = 32;
pub const PE_SETUP_RULES: u32 = 64;
pub const PE_SETUP_TRUSTED_SENDERS: u32 = 128;
pub const PE_SETUP_ALL: u32 = 255;

/// What kind of value an app preference takes, written as text: `1` or `0`; a number from 0 to its `max`; a
/// language code (`de`), or empty for the system's language
#[repr(C)]
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum PeSetupPrefKind {
    Bool = 0,
    Number = 1,
    Language = 2,
}

/// An app preference a setup file carries, by the name the three apps share
#[repr(C)]
pub struct PeSetupPrefName {
    /// `layout`, `hide_read`, `language`, ...
    pub name: *const c_char,
    pub kind: PeSetupPrefKind,
    /// The largest number of a `Number`, 0 for the others
    pub max: u32,
}

/// The app preferences a setup file carries; free with `pe_setup_pref_names_free`
pub struct PeSetupPrefNames(Rows<PeSetupPrefName>);

/// The app preferences a setup file carries, by name and kind: what an app hands to `pe_setup_export_set_pref`
#[unsafe(no_mangle)]
pub extern "C" fn pe_setup_pref_names() -> *mut PeSetupPrefNames {
    guard(|| {
        handed(PeSetupPrefNames(Rows::new(
            &setup::PREFERENCES,
            |(name, kind), strings| {
                let (kind, max) = match kind {
                    PrefKind::Bool => (PeSetupPrefKind::Bool, 0),
                    PrefKind::Number(max) => (PeSetupPrefKind::Number, *max),
                    PrefKind::Language => (PeSetupPrefKind::Language, 0),
                };
                PeSetupPrefName {
                    name: strings.add(name),
                    kind,
                    max,
                }
            },
        )))
    })
    .unwrap_or(null_mut())
}

/// # Safety
/// `list` must be NULL or live.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn pe_setup_pref_names_count(list: *const PeSetupPrefNames) -> usize {
    // SAFETY: as the caller guarantees
    Rows::count(unsafe { list.as_ref() }.map(|list| &list.0))
}

/// # Safety
/// `list` must be NULL or live.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn pe_setup_pref_names_get(
    list: *const PeSetupPrefNames,
    index: usize,
) -> *const PeSetupPrefName {
    // SAFETY: as the caller guarantees
    Rows::get(unsafe { list.as_ref() }.map(|list| &list.0), index)
}

/// # Safety
/// `list` must be NULL or a list that was not freed yet.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn pe_setup_pref_names_free(list: *mut PeSetupPrefNames) {
    // SAFETY: as the caller guarantees
    unsafe { take_back(list) }
}

// ---- lines of words ----

/// What a line of words tells
#[repr(C)]
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum PeSetupLineKind {
    /// What a part holds ("2 accounts"), its `part` set
    Part = 0,
    Added = 1,
    Skipped = 2,
    /// Something to know or to do: an account that asks for its password, a key that waits for a decision
    Note = 3,
}

#[repr(C)]
pub struct PeSetupLine {
    pub kind: PeSetupLineKind,
    /// The part (`PE_SETUP_*`) of a `Part` line, 0 for the others
    pub part: u32,
    /// The part's name ("Contacts and groups") of a `Part` line, empty for the others
    pub name: *const c_char,
    /// What the part holds ("2 accounts"; empty in `pe_setup_parts`), or what was done
    pub text: *const c_char,
}

/// Lines of words, what an export wrote or an import did, and the accounts an import added; free with
/// `pe_setup_lines_free`
pub struct PeSetupLines {
    rows: Rows<PeSetupLine>,
    accounts: Vec<i64>,
}

fn part_lines(parts: &[(Parts, String)]) -> Rows<PeSetupLine> {
    Rows::new(parts, |(part, text), strings| PeSetupLine {
        kind: PeSetupLineKind::Part,
        part: part.0,
        name: strings.add(&part.name()),
        text: strings.add(text),
    })
}

/// Every part of a setup file with its flag and its name, in the order the windows list them (`text` empty): what
/// the export window offers. Free with `pe_setup_lines_free`.
#[unsafe(no_mangle)]
pub extern "C" fn pe_setup_parts() -> *mut PeSetupLines {
    guard(|| {
        let parts: Vec<(Parts, String)> = Parts::EACH.iter().map(|part| (*part, String::new())).collect();
        handed(PeSetupLines {
            rows: part_lines(&parts),
            accounts: Vec::new(),
        })
    })
    .unwrap_or(null_mut())
}

/// The setup file's extension without its dot (`inboxclassic`), a static string that is not freed
#[unsafe(no_mangle)]
pub extern "C" fn pe_setup_extension() -> *const c_char {
    c"inboxclassic".as_ptr()
}

/// The name an export offers to save as, in the language in use ("Inbox Classic settings and accounts.inboxclassic");
/// free with `pe_string_free`
#[unsafe(no_mangle)]
pub extern "C" fn pe_setup_default_name() -> *mut c_char {
    guard(|| crate::into_c_string(setup::default_name())).unwrap_or(null_mut())
}

fn summary_lines(summary: &ImportSummary) -> PeSetupLines {
    PeSetupLines {
        rows: Rows::new(&summary.lines, |line, strings| PeSetupLine {
            kind: match line.kind {
                ImportLineKind::Added => PeSetupLineKind::Added,
                ImportLineKind::Skipped => PeSetupLineKind::Skipped,
                ImportLineKind::Note => PeSetupLineKind::Note,
            },
            part: 0,
            name: strings.add(""),
            text: strings.add(&line.text),
        }),
        accounts: summary.accounts.clone(),
    }
}

/// # Safety
/// `lines` must be NULL or live.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn pe_setup_lines_count(lines: *const PeSetupLines) -> usize {
    // SAFETY: as the caller guarantees
    Rows::count(unsafe { lines.as_ref() }.map(|lines| &lines.rows))
}

/// Line `index`, NULL past the end
///
/// # Safety
/// `lines` must be NULL or live.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn pe_setup_lines_get(lines: *const PeSetupLines, index: usize) -> *const PeSetupLine {
    // SAFETY: as the caller guarantees
    Rows::get(unsafe { lines.as_ref() }.map(|lines| &lines.rows), index)
}

/// The accounts an import added, which are syncing: their ids, `count` of them; NULL for none
///
/// # Safety
/// `lines` must be NULL or live, `count` a valid pointer.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn pe_setup_lines_accounts(lines: *const PeSetupLines, count: *mut usize) -> *const i64 {
    // SAFETY: as the caller guarantees
    let accounts = unsafe { lines.as_ref() }.map_or(&[][..], |lines| &lines.accounts[..]);
    if !count.is_null() {
        // SAFETY: as the caller guarantees
        unsafe { *count = accounts.len() };
    }
    if accounts.is_empty() { null() } else { accounts.as_ptr() }
}

/// # Safety
/// `lines` must be NULL or lines that were not freed yet.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn pe_setup_lines_free(lines: *mut PeSetupLines) {
    // SAFETY: as the caller guarantees
    unsafe { take_back(lines) }
}

// ---- export ----

/// An export being set up: its parts, its passphrase, the app's preferences; free with `pe_setup_export_free`
pub struct PeSetupExport {
    parts: u32,
    passphrase: Option<Zeroizing<String>>,
    prefs: Vec<(String, String)>,
}

impl PeSetupExport {
    /// The app preferences handed in
    pub(crate) fn prefs(&self) -> &[(String, String)] {
        &self.prefs
    }
}

/// A new export of `parts` (`PE_SETUP_*` flags), without a passphrase
#[unsafe(no_mangle)]
pub extern "C" fn pe_setup_export_new(parts: u32) -> *mut PeSetupExport {
    guard(|| {
        handed(PeSetupExport {
            parts,
            passphrase: None,
            prefs: Vec::new(),
        })
    })
    .unwrap_or(null_mut())
}

/// Seals the file with `passphrase` (NULL or empty for none), so that it carries the secrets too. The rule of key
/// backups applies (`pe_pgp_passphrase_problem`); `pe_setup_export_write` refuses a shorter one.
///
/// # Safety
/// `export` must be live, `passphrase` NULL or a NUL-terminated string.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn pe_setup_export_set_passphrase(export: *mut PeSetupExport, passphrase: *const c_char) {
    // SAFETY: as the caller guarantees
    let (Some(export), passphrase) = (unsafe { export.as_mut() }, unsafe { arg(passphrase) }) else {
        return;
    };
    export.passphrase = passphrase
        .filter(|p| !p.is_empty())
        .map(|p| Zeroizing::new(p.to_string()));
}

/// Hands in an app preference by its name (`pe_setup_pref_names`) and its value as text; false when there is no
/// such preference or the value is not one of it (it is left out)
///
/// # Safety
/// `export` must be live, `name` and `value` NUL-terminated strings.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn pe_setup_export_set_pref(
    export: *mut PeSetupExport,
    name: *const c_char,
    value: *const c_char,
) -> bool {
    // SAFETY: as the caller guarantees
    let (Some(export), Some(name), Some(value)) =
        (unsafe { export.as_mut() }, unsafe { arg(name) }, unsafe { arg(value) })
    else {
        return false;
    };
    guard(|| {
        let Some(value) = setup::pref_value(name, value) else {
            return false;
        };
        export.prefs.retain(|(known, _)| known != name);
        export.prefs.push((name.to_string(), value));
        true
    })
    .unwrap_or(false)
}

/// Writes the setup file at `path` (UTF-8; `.inboxclassic` added when it has no extension): each part written with what it holds, as `Part` lines; NULL with the
/// reason in `error` (free it with `pe_string_free`) when it could not be written
///
/// # Safety
/// `core` and `export` must be live, `path` a NUL-terminated string, `error` NULL or a valid pointer.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn pe_setup_export_write(
    core: *const PeCore,
    export: *const PeSetupExport,
    path: *const c_char,
    error: *mut *mut c_char,
) -> *mut PeSetupLines {
    // SAFETY: as the caller guarantees
    let (Some(export), Some(path)) = (unsafe { export.as_ref() }, unsafe { arg(path) }) else {
        return null_mut();
    };
    // SAFETY: as the caller guarantees
    let written = unsafe {
        with(core, Err(None), |core| {
            core.export_setup(
                path.as_ref(),
                Parts(export.parts),
                export.passphrase.as_ref().map(|p| p.as_str()),
                &export.prefs,
            )
            .map_err(Some)
        })
    };
    // SAFETY: as the caller guarantees
    match unsafe { refused(error, written, "the setup could not be saved") } {
        Some(parts) => handed(PeSetupLines {
            rows: part_lines(&parts),
            accounts: Vec::new(),
        }),
        None => null_mut(),
    }
}

/// # Safety
/// `export` must be NULL or an export that was not freed yet.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn pe_setup_export_free(export: *mut PeSetupExport) {
    // SAFETY: as the caller guarantees
    unsafe { take_back(export) }
}

// ---- reading ----

/// Why a setup file could not be read
#[repr(C)]
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum PeSetupError {
    None = 0,
    /// It is sealed with a passphrase: ask for it and read again
    NeedsPassphrase = 1,
    /// The passphrase does not open it: ask again
    WrongPassphrase = 2,
    /// Anything else, said in `error`
    Invalid = 3,
}

/// What a setup file is and holds
#[repr(C)]
pub struct PeSetupInfo {
    /// Sealed with a passphrase (and only then does it carry passwords, sign-ins and private keys)
    pub encrypted: bool,
    /// The version of Inbox Classic that saved it
    pub app_version: *const c_char,
    /// When, seconds since 1970, and as the user's locale writes a day (empty when the file names no such day)
    pub created: i64,
    pub created_text: *const c_char,
    /// The parts it holds, `PE_SETUP_*` flags; `pe_setup_file_part` lists those it holds something in, with words
    pub parts: u32,
}

/// An account of a setup file as the import window lists it
#[repr(C)]
pub struct PeSetupAccount {
    /// Its place in the file: what `pe_setup_import` takes
    pub index: usize,
    pub email: *const c_char,
    /// What the folder list will call it
    pub title: *const c_char,
    /// The title with the address, as the list shows it: "Work <ann@example.com>"
    pub label: *const c_char,
    /// Its servers and how it signs in, one line: "imap.example.com and smtp.example.com (Password)"
    pub servers: *const c_char,
    /// How it signs in, in words: "Password", or the sign-in app's name
    pub sign_in: *const c_char,
    /// One like it (the same address and IMAP server) is set up here: an import skips it
    pub here: bool,
    /// An import can add it: offer its check box ticked; otherwise unticked and greyed, `note` saying why
    pub importable: bool,
    /// Why it can not be imported, NULL when it can (or when it is only here already)
    pub problem: *const c_char,
    /// What an import does with it, in words
    pub note: *const c_char,
}

/// An app preference a setup file carries, its value checked
#[repr(C)]
pub struct PeSetupPref {
    pub name: *const c_char,
    /// Checked: one of the values `pe_setup_pref_names` says, ready to apply
    pub value: *const c_char,
    /// It counts once the app starts again (the language, listed last): the window may offer to restart
    pub restart: bool,
}

/// A setup file read: what it holds, for the import window, and what `pe_setup_import` writes; free with
/// `pe_setup_file_free`
pub struct PeSetupFile {
    file: SetupFile,
    info: PeSetupInfo,
    accounts: Rows<PeSetupAccount>,
    parts: Rows<PeSetupLine>,
    prefs: Rows<PeSetupPref>,
    _strings: Strings,
}

pub(crate) fn file_handle(file: SetupFile) -> PeSetupFile {
    let mut strings = Strings::default();
    let info = PeSetupInfo {
        encrypted: file.encrypted,
        app_version: strings.add(&file.app_version),
        created: file.created,
        created_text: strings.add(&file.created_text),
        parts: file.parts.0,
    };
    let accounts = Rows::new(&file.accounts, |a, strings| PeSetupAccount {
        index: a.index,
        email: strings.add(&a.email),
        title: strings.add(&a.title),
        label: strings.add(&a.label),
        servers: strings.add(&a.servers),
        sign_in: strings.add(&a.sign_in),
        here: a.here,
        importable: a.importable,
        problem: a.problem.as_deref().map_or(null(), |problem| strings.add(problem)),
        note: strings.add(&a.note),
    });
    let parts = part_lines(&file.part_lines());
    let prefs = Rows::new(&file.prefs, |(name, value), strings| PeSetupPref {
        name: strings.add(name),
        value: strings.add(value),
        restart: setup::pref_restarts(name),
    });
    PeSetupFile {
        file,
        info,
        accounts,
        parts,
        prefs,
        _strings: strings,
    }
}

/// Reads the setup file at `path` (UTF-8), opened with `passphrase` (NULL for none) when it is sealed. NULL when it
/// can not be read: `kind` says whether a passphrase is needed or wrong, `error` (NULL or a pointer to a string to
/// free with `pe_string_free`) says why in words. Nothing changes until `pe_setup_import`.
///
/// # Safety
/// `core` must be live, `path` a NUL-terminated string, `passphrase` NULL or one, `kind` and `error` NULL or valid
/// pointers.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn pe_setup_read(
    core: *const PeCore,
    path: *const c_char,
    passphrase: *const c_char,
    kind: *mut PeSetupError,
    error: *mut *mut c_char,
) -> *mut PeSetupFile {
    // SAFETY: as the caller guarantees
    let (path, passphrase) = unsafe { (arg(path), arg(passphrase)) };
    let read = match path {
        // SAFETY: as the caller guarantees
        Some(path) => unsafe {
            with(core, None, |core| {
                Some(core.read_setup(path.as_ref(), passphrase).map(file_handle))
            })
        },
        None => None,
    };
    let (handle, why, words) = match read {
        Some(Ok(handle)) => (handed(handle), PeSetupError::None, None),
        Some(Err(failure)) => {
            let why = match failure {
                SetupError::NeedsPassphrase => PeSetupError::NeedsPassphrase,
                SetupError::WrongPassphrase => PeSetupError::WrongPassphrase,
                SetupError::Invalid(_) => PeSetupError::Invalid,
            };
            (null_mut(), why, Some(failure.text()))
        }
        None => (
            null_mut(),
            PeSetupError::Invalid,
            Some("the setup file could not be read".into()),
        ),
    };
    if !kind.is_null() {
        // SAFETY: as the caller guarantees
        unsafe { *kind = why };
    }
    if let (Some(words), false) = (words, error.is_null()) {
        // SAFETY: as the caller guarantees
        unsafe { *error = crate::into_c_string(words) };
    }
    handle
}

/// What the file is and holds; NULL for a NULL handle. Lives as long as the handle.
///
/// # Safety
/// `file` must be NULL or live.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn pe_setup_file_info(file: *const PeSetupFile) -> *const PeSetupInfo {
    // SAFETY: as the caller guarantees
    unsafe { file.as_ref() }.map_or(null(), |file| &file.info)
}

/// # Safety
/// `file` must be NULL or live.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn pe_setup_file_account_count(file: *const PeSetupFile) -> usize {
    // SAFETY: as the caller guarantees
    Rows::count(unsafe { file.as_ref() }.map(|file| &file.accounts))
}

/// Account `index` of the file (in its order), NULL past the end
///
/// # Safety
/// `file` must be NULL or live.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn pe_setup_file_account(file: *const PeSetupFile, index: usize) -> *const PeSetupAccount {
    // SAFETY: as the caller guarantees
    Rows::get(unsafe { file.as_ref() }.map(|file| &file.accounts), index)
}

/// # Safety
/// `file` must be NULL or live.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn pe_setup_file_part_count(file: *const PeSetupFile) -> usize {
    // SAFETY: as the caller guarantees
    Rows::count(unsafe { file.as_ref() }.map(|file| &file.parts))
}

/// Part `index` the file holds, with what it holds in words, in the order the windows list them; NULL past the end
///
/// # Safety
/// `file` must be NULL or live.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn pe_setup_file_part(file: *const PeSetupFile, index: usize) -> *const PeSetupLine {
    // SAFETY: as the caller guarantees
    Rows::get(unsafe { file.as_ref() }.map(|file| &file.parts), index)
}

/// # Safety
/// `file` must be NULL or live.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn pe_setup_file_pref_count(file: *const PeSetupFile) -> usize {
    // SAFETY: as the caller guarantees
    Rows::count(unsafe { file.as_ref() }.map(|file| &file.prefs))
}

/// App preference `index` the file carries, its value checked: what the app sets after an import of
/// `PE_SETUP_PREFERENCES`; NULL past the end
///
/// # Safety
/// `file` must be NULL or live.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn pe_setup_file_pref(file: *const PeSetupFile, index: usize) -> *const PeSetupPref {
    // SAFETY: as the caller guarantees
    Rows::get(unsafe { file.as_ref() }.map(|file| &file.prefs), index)
}

/// What the file holds that can not be used and is left out, a line each in words; free with `pe_text_list_free`
///
/// # Safety
/// `file` must be NULL or live.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn pe_setup_file_notes(file: *const PeSetupFile) -> *mut PeTextList {
    // SAFETY: as the caller guarantees
    let notes = unsafe { file.as_ref() }.map_or_else(Vec::new, |file| file.file.notes.clone());
    guard(|| crate::selection::text_list(notes)).unwrap_or(null_mut())
}

/// # Safety
/// `file` must be NULL or a handle that was not freed yet.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn pe_setup_file_free(file: *mut PeSetupFile) {
    // SAFETY: as the caller guarantees
    unsafe { take_back(file) }
}

/// Imports the `parts` (`PE_SETUP_*`) of `file` and its accounts at the places `accounts` names (`count` of them,
/// `PeSetupAccount.index`; `PE_SETUP_ACCOUNTS` follows from them: taken when any are named, never when none are):
/// lines of what was added and skipped, and the accounts added (`pe_setup_lines_accounts`),
/// which start syncing. The app sets the preferences itself (`pe_setup_file_pref`). NULL with the reason in `error`
/// (free it with `pe_string_free`) when nothing could be imported. BLOCKS while the issuers of the sign-in apps it
/// adds are read (20 seconds at most each): call it from a thread of its own, never the window thread. The core posts
/// `ACCOUNTS_CHANGED`, `SETTINGS_CHANGED`, `ADDRESS_BOOK_CHANGED` and `KEYS_CHANGED` for what it changed.
///
/// # Safety
/// `core` and `file` must be live, `accounts` NULL or `count` values, `error` NULL or a valid pointer.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn pe_setup_import(
    core: *const PeCore,
    file: *const PeSetupFile,
    parts: u32,
    accounts: *const usize,
    count: usize,
    error: *mut *mut c_char,
) -> *mut PeSetupLines {
    // SAFETY: as the caller guarantees
    let Some(file) = (unsafe { file.as_ref() }) else {
        return null_mut();
    };
    let accounts = if accounts.is_null() || count == 0 {
        Vec::new()
    } else {
        // SAFETY: as the caller guarantees
        unsafe { std::slice::from_raw_parts(accounts, count) }.to_vec()
    };
    let choice = ImportChoice {
        parts: Parts(parts),
        accounts,
    };
    // SAFETY: as the caller guarantees
    let imported = unsafe {
        with(core, Err(None), |core| {
            core.import_setup(&file.file, &choice).map_err(Some)
        })
    };
    // SAFETY: as the caller guarantees
    match unsafe { refused(error, imported, "the setup could not be imported") } {
        Some(summary) => handed(summary_lines(&summary)),
        None => null_mut(),
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn the_flags_are_the_cores() {
        let flags = [
            (PE_SETUP_SETTINGS, Parts::SETTINGS),
            (PE_SETUP_PREFERENCES, Parts::PREFERENCES),
            (PE_SETUP_ACCOUNTS, Parts::ACCOUNTS),
            (PE_SETUP_SIGN_IN_APPS, Parts::SIGN_IN_APPS),
            (PE_SETUP_CONTACTS, Parts::CONTACTS),
            (PE_SETUP_KEYS, Parts::KEYS),
            (PE_SETUP_RULES, Parts::RULES),
            (PE_SETUP_TRUSTED_SENDERS, Parts::TRUSTED_SENDERS),
            (PE_SETUP_ALL, Parts::ALL),
        ];
        for (flag, part) in flags {
            assert_eq!(flag, part.0);
        }
        let extension = unsafe { std::ffi::CStr::from_ptr(pe_setup_extension()) };
        assert_eq!(extension.to_str().unwrap(), setup::EXTENSION);
    }
}
