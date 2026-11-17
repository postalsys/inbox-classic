//! OpenPGP keys through C: the key book as lists of rows, a key made, imported, exported, backed up, removed and
//! verified, a correspondent's key in use and the one waiting for a decision, and the key of each own address.
//! The decisions are the core's (pe-core `keys.rs`); C++ and Swift show what comes back.

use std::ffi::c_char;
use std::ptr::null_mut;

use pe_core::keys::{ImportError, KeyInfo, KeySource, KeyState};
use pe_store::PgpIdentity;

use crate::core::{PeCore, Rows, arg, handed, refused, take_back, with};
use crate::{guard, into_c_string};

/// What a key is now
#[repr(C)]
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum PeKeyState {
    Valid = 0,
    Expired = 1,
    Revoked = 2,
    NotValid = 3,
    /// An own key whose private part can not be opened: its backup must be imported again
    Locked = 4,
}

impl From<KeyState> for PeKeyState {
    fn from(state: KeyState) -> Self {
        match state {
            KeyState::Valid => PeKeyState::Valid,
            KeyState::Expired => PeKeyState::Expired,
            KeyState::Revoked => PeKeyState::Revoked,
            KeyState::NotValid => PeKeyState::NotValid,
            KeyState::Locked => PeKeyState::Locked,
        }
    }
}

/// A key as the windows show it
#[repr(C)]
pub struct PeKey {
    /// Upper case hex
    pub fingerprint: *const c_char,
    /// In groups of four, for comparing
    pub grouped: *const c_char,
    /// The user ids valid now, one a line
    pub user_ids: *const c_char,
    /// The addresses it holds, one a line (each with whether it is verified: `address_lines`)
    pub addresses: *const c_char,
    /// Whether every address it holds is verified (and it holds one)
    pub verified: bool,
    /// The user's own: it has its private part
    pub own: bool,
    pub state: PeKeyState,
    /// The state in words: "Valid", "Valid until 3 May 2027", "Revoked: key compromised"
    pub state_text: *const c_char,
    /// Seconds since the Unix epoch
    pub created: i64,
    /// Seconds since the Unix epoch, 0 when it does not expire
    pub expires: i64,
    /// "Ed25519", "RSA 4096"
    pub algorithm: *const c_char,
    /// Where it came from, in words
    pub source: *const c_char,
    /// What it is called: the name of its first user id, else its first address, else its fingerprint
    pub name: *const c_char,
    /// What the Status column says: the state, ", verified" after it for a contact's key the user compared
    pub status: *const c_char,
    /// The name and the last four groups of the fingerprint, as a choice of keys shows it
    pub choice: *const c_char,
    /// The grouped fingerprint on two lines (split by "\n"), what Verify shows to read out
    pub fingerprint_lines: *const c_char,
    /// Back Up applies: an own key whose private part opens
    pub can_back_up: bool,
    /// Verify applies: a contact's key
    pub can_verify: bool,
    /// Each address it holds, one a line; a contact's with whether it is verified
    pub address_lines: *const c_char,
    /// What Remove asks first
    pub remove_question: *const c_char,
    /// What Verify Key says They Match marks: every address the key holds
    pub verify_marks: *const c_char,
    /// When it was made and until when it is valid ("Never"), in the user's way of writing a day
    pub created_text: *const c_char,
    pub expires_text: *const c_char,
}

/// A list of keys
pub struct PeKeyList(Rows<PeKey>);

fn key_list(keys: &[KeyInfo]) -> *mut PeKeyList {
    handed(PeKeyList(Rows::new(keys, |key, strings| PeKey {
        fingerprint: strings.add(&key.fingerprint),
        grouped: strings.add(&key.grouped),
        user_ids: strings.add(&key.user_ids.join("\n")),
        addresses: strings.add(
            &key.addresses
                .iter()
                .map(|(address, _)| address.as_str())
                .collect::<Vec<_>>()
                .join("\n"),
        ),
        verified: key.verified,
        own: key.own,
        state: key.state.into(),
        state_text: strings.add(&key.state_text),
        created: key.created,
        expires: key.expires.unwrap_or(0),
        algorithm: strings.add(&key.algorithm),
        source: strings.add(&key.source),
        name: strings.add(&key.name),
        status: strings.add(&key.status),
        choice: strings.add(&key.choice),
        fingerprint_lines: strings.add(&key.fingerprint_lines),
        can_back_up: key.can_back_up,
        can_verify: key.can_verify,
        address_lines: strings.add(&key.address_lines.join("\n")),
        remove_question: strings.add(&key.remove_question),
        verify_marks: strings.add(&key.verify_marks),
        created_text: strings.add(&key.created_text),
        expires_text: strings.add(&key.expires_text),
    })))
}

/// Every key, own keys first; NULL on failure. Free with `pe_pgp_key_list_free`.
///
/// # Safety
/// `core` must be a live handle.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn pe_pgp_keys(core: *const PeCore) -> *mut PeKeyList {
    // SAFETY: as the caller guarantees
    unsafe {
        with(core, null_mut(), |core| {
            core.pgp_keys().map_or(null_mut(), |keys| key_list(&keys))
        })
    }
}

/// One key, as a list of one row; NULL when there is no such key. Free with `pe_pgp_key_list_free`.
///
/// # Safety
/// `core` must be a live handle, `fingerprint` a NUL-terminated string.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn pe_pgp_key(core: *const PeCore, fingerprint: *const c_char) -> *mut PeKeyList {
    // SAFETY: as the caller guarantees
    let fingerprint = unsafe { arg(fingerprint) }.unwrap_or_default();
    // SAFETY: as the caller guarantees
    unsafe {
        with(core, null_mut(), |core| {
            core.pgp_key(fingerprint).map_or(null_mut(), |key| key_list(&[key]))
        })
    }
}

/// # Safety
/// `list` must be NULL or a list that was not freed yet.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn pe_pgp_key_list_count(list: *const PeKeyList) -> usize {
    // SAFETY: as the caller guarantees
    Rows::count(unsafe { list.as_ref() }.map(|list| &list.0))
}

/// The row at `index`, NULL past the end; it lives as long as the list
///
/// # Safety
/// `list` must be NULL or a list that was not freed yet.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn pe_pgp_key_list_get(list: *const PeKeyList, index: usize) -> *const PeKey {
    // SAFETY: as the caller guarantees
    Rows::get(unsafe { list.as_ref() }.map(|list| &list.0), index)
}

/// # Safety
/// `list` must be NULL or a list that was not freed yet.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn pe_pgp_key_list_free(list: *mut PeKeyList) {
    // SAFETY: as the caller guarantees
    unsafe { take_back(list) }
}

/// Whether a private key made or imported now can still be used after a restart: false when passwords are kept in
/// memory only, where the windows say so first
///
/// # Safety
/// `core` must be a live handle.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn pe_pgp_private_keys_kept(core: *const PeCore) -> bool {
    // SAFETY: as the caller guarantees
    unsafe { with(core, false, |core| core.pgp_private_keys_kept()) }
}

/// Makes a new key for an account and its other addresses, which then use it (a few seconds); its fingerprint, or
/// NULL with the reason in `error` (free both with `pe_string_free`).
///
/// # Safety
/// `core` must be a live handle, `error` NULL or a valid pointer.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn pe_pgp_generate(core: *const PeCore, account: i64, error: *mut *mut c_char) -> *mut c_char {
    // SAFETY: as the caller guarantees
    let result = unsafe { with(core, Err(None), |core| core.pgp_generate(account).map_err(Some)) };
    // SAFETY: as the caller guarantees
    unsafe { refused(error, result, "the key could not be made") }.map_or(null_mut(), into_c_string)
}

/// Where imported keys came from
#[allow(dead_code)] // made by the apps, read here
#[repr(C)]
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum PeKeySource {
    File = 0,
    Paste = 1,
    Attachment = 2,
}

/// How an import ended
#[repr(C)]
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum PeImportOutcome {
    Imported = 0,
    /// Private keys protected by a passphrase: ask for it and import again with it
    NeedsPassphrase = 1,
    WrongPassphrase = 2,
    Invalid = 3,
}

/// Imports the keys in `data` (`len` bytes, armored or binary): private ones unlocked with `passphrase` (NULL when
/// none was asked yet) and kept protected, public ones used for their addresses unless another key is (that one
/// waits for the user's decision). `message` gets what happened or why not, in words (free it with `pe_string_free`).
///
/// # Safety
/// `core` must be a live handle, `data` `len` readable bytes, `passphrase` NULL or a NUL-terminated string, `message`
/// NULL or a valid pointer.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn pe_pgp_import(
    core: *const PeCore,
    data: *const u8,
    len: usize,
    passphrase: *const c_char,
    source: PeKeySource,
    message: *mut *mut c_char,
) -> PeImportOutcome {
    if data.is_null() {
        return PeImportOutcome::Invalid;
    }
    // SAFETY: as the caller guarantees
    let bytes = unsafe { std::slice::from_raw_parts(data, len) };
    // SAFETY: as the caller guarantees
    let passphrase = unsafe { arg(passphrase) };
    let source = match source {
        PeKeySource::File => KeySource::File,
        PeKeySource::Paste => KeySource::Paste,
        PeKeySource::Attachment => KeySource::Attachment,
    };
    // SAFETY: as the caller guarantees
    let result = unsafe {
        with(core, Err(ImportError::Invalid(String::new())), |core| {
            core.pgp_import(bytes, passphrase, source)
        })
    };
    let (outcome, text) = match result {
        Ok(imported) => (PeImportOutcome::Imported, imported.summary()),
        Err(error) => (
            match error {
                ImportError::NeedsPassphrase => PeImportOutcome::NeedsPassphrase,
                ImportError::WrongPassphrase => PeImportOutcome::WrongPassphrase,
                ImportError::Invalid(_) => PeImportOutcome::Invalid,
            },
            error.text(),
        ),
    };
    if !message.is_null() {
        // SAFETY: the caller gave a valid pointer
        unsafe { *message = into_c_string(text) };
    }
    outcome
}

/// The public key, armored, to save or attach; NULL when there is no such key. Free with `pe_string_free`.
///
/// # Safety
/// `core` must be a live handle, `fingerprint` a NUL-terminated string.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn pe_pgp_export(core: *const PeCore, fingerprint: *const c_char) -> *mut c_char {
    // SAFETY: as the caller guarantees
    let fingerprint = unsafe { arg(fingerprint) }.unwrap_or_default();
    // SAFETY: as the caller guarantees
    unsafe {
        with(core, null_mut(), |core| {
            core.pgp_export(fingerprint).map_or(null_mut(), into_c_string)
        })
    }
}

/// An own key protected by `passphrase`, armored, for a backup; NULL with the reason in `error` (free both with
/// `pe_string_free`).
///
/// # Safety
/// `core` must be a live handle, `fingerprint` and `passphrase` NUL-terminated strings, `error` NULL or a valid
/// pointer.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn pe_pgp_backup(
    core: *const PeCore,
    fingerprint: *const c_char,
    passphrase: *const c_char,
    error: *mut *mut c_char,
) -> *mut c_char {
    // SAFETY: as the caller guarantees
    let fingerprint = unsafe { arg(fingerprint) }.unwrap_or_default();
    // SAFETY: as the caller guarantees
    // borrowed from the caller, never copied here
    let passphrase = unsafe { arg(passphrase) }.unwrap_or_default();
    // SAFETY: as the caller guarantees
    let result = unsafe {
        with(core, Err(None), |core| {
            core.pgp_backup(fingerprint, passphrase).map_err(Some)
        })
    };
    // SAFETY: as the caller guarantees
    unsafe { refused(error, result, "the backup could not be made") }.map_or(null_mut(), into_c_string)
}

/// Removes a key: correspondents who used it have none, own addresses lose theirs
///
/// # Safety
/// `core` must be a live handle, `fingerprint` a NUL-terminated string.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn pe_pgp_remove(core: *const PeCore, fingerprint: *const c_char) -> bool {
    // SAFETY: as the caller guarantees
    let fingerprint = unsafe { arg(fingerprint) }.unwrap_or_default();
    // SAFETY: as the caller guarantees
    unsafe { with(core, false, |core| core.pgp_remove(fingerprint).is_ok()) }
}

/// Marks whether the user compared the key's fingerprint with its owner's (Verify Key), for every address it holds
///
/// # Safety
/// `core` must be a live handle, `fingerprint` a NUL-terminated string.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn pe_pgp_set_key_verified(
    core: *const PeCore,
    fingerprint: *const c_char,
    verified: bool,
) -> bool {
    // SAFETY: as the caller guarantees
    let fingerprint = unsafe { arg(fingerprint).unwrap_or_default() };
    // SAFETY: as the caller guarantees
    unsafe {
        with(core, false, |core| {
            core.pgp_set_key_verified(fingerprint, verified).is_ok()
        })
    }
}

/// Why a backup's passphrase, typed twice, is refused (they differ, or it is too short); NULL when it is good. Free
/// with `pe_string_free`.
///
/// # Safety
/// `first` and `again` must be NULL or NUL-terminated strings.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn pe_pgp_passphrase_problem(first: *const c_char, again: *const c_char) -> *mut c_char {
    // SAFETY: as the caller guarantees
    let (first, again) = unsafe { (arg(first).unwrap_or_default(), arg(again).unwrap_or_default()) };
    guard(|| pe_core::keys::passphrase_problem(first, again).map_or(null_mut(), into_c_string)).unwrap_or(null_mut())
}

/// What to say under a passphrase typed twice while it is typed (a key backup's, a setup file's), NULL for nothing;
/// `acceptable` (NULL or a valid pointer) says whether it can be used: 8 characters or more, the same twice. "Too
/// short" shows once the first field has something shorter; "not the same" only once the second is as long as the
/// first. Free with `pe_string_free`.
///
/// # Safety
/// `first` and `again` must be NULL or NUL-terminated strings, `acceptable` NULL or a valid pointer.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn pe_passphrase_feedback(
    first: *const c_char,
    again: *const c_char,
    acceptable: *mut bool,
) -> *mut c_char {
    // SAFETY: as the caller guarantees
    let (first, again) = unsafe { (arg(first).unwrap_or_default(), arg(again).unwrap_or_default()) };
    let (said, usable) = guard(|| pe_core::keys::passphrase_feedback(first, again)).unwrap_or((None, false));
    if !acceptable.is_null() {
        // SAFETY: as the caller guarantees
        unsafe { *acceptable = usable };
    }
    said.map_or(null_mut(), into_c_string)
}

/// The longest of what `pe_passphrase_feedback` says, for a window to keep room for it; free with `pe_string_free`
#[unsafe(no_mangle)]
pub extern "C" fn pe_passphrase_feedback_longest() -> *mut c_char {
    guard(|| into_c_string(pe_core::keys::passphrase_feedback_longest())).unwrap_or(null_mut())
}

/// A correspondent's keys: the one in use and a newer one waiting for the user's decision
#[repr(C)]
pub struct PePeerKeys {
    /// NULL when the address has no key
    pub in_use: *mut c_char,
    /// NULL when none waits
    pub pending: *mut c_char,
    /// When the waiting key was found, seconds since the Unix epoch; 0 when none waits
    pub pending_since: i64,
    /// "A different key for bob@example.net was found on 3 May 2027.", NULL when none waits
    pub pending_text: *mut c_char,
}

/// The keys of `address`; free with `pe_pgp_peer_free`.
///
/// # Safety
/// `core` must be a live handle, `address` a NUL-terminated string.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn pe_pgp_peer(core: *const PeCore, address: *const c_char) -> *mut PePeerKeys {
    // SAFETY: as the caller guarantees
    let address = unsafe { arg(address) }.unwrap_or_default();
    // SAFETY: as the caller guarantees
    unsafe {
        with(core, null_mut(), |core| {
            let Ok(peer) = core.pgp_peer(address) else {
                return null_mut();
            };
            let text = |fingerprint: Option<String>| fingerprint.map_or(null_mut(), into_c_string);
            handed(PePeerKeys {
                in_use: text(peer.in_use),
                pending: text(peer.pending),
                pending_since: peer.pending_since.unwrap_or(0),
                pending_text: text(peer.pending_text),
            })
        })
    }
}

/// # Safety
/// `peer` must be NULL or from `pe_pgp_peer`, freed once.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn pe_pgp_peer_free(peer: *mut PePeerKeys) {
    if peer.is_null() {
        return;
    }
    // SAFETY: as the caller guarantees
    let peer = unsafe { Box::from_raw(peer) };
    // SAFETY: both were made by into_c_string, or are NULL
    unsafe {
        crate::pe_string_free(peer.in_use);
        crate::pe_string_free(peer.pending);
        crate::pe_string_free(peer.pending_text);
    }
}

/// The user's decision about the key waiting for `address`: use it (`use_new`), or keep the one in use
///
/// # Safety
/// `core` must be a live handle, `address` a NUL-terminated string.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn pe_pgp_decide(core: *const PeCore, address: *const c_char, use_new: bool) -> bool {
    // SAFETY: as the caller guarantees
    let address = unsafe { arg(address) }.unwrap_or_default();
    // SAFETY: as the caller guarantees
    unsafe { with(core, false, |core| core.pgp_decide(address, use_new).is_ok()) }
}

/// One of the user's own addresses and its key
#[repr(C)]
pub struct PeIdentity {
    pub address: *const c_char,
    pub fingerprint: *const c_char,
    /// Its mail carries the key in the Autocrypt header
    pub autocrypt: bool,
}

pub struct PeIdentityList(Rows<PeIdentity>);

/// The key of each own address that has one; NULL on failure. Free with `pe_pgp_identity_list_free`.
///
/// # Safety
/// `core` must be a live handle.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn pe_pgp_identities(core: *const PeCore) -> *mut PeIdentityList {
    // SAFETY: as the caller guarantees
    unsafe {
        with(core, null_mut(), |core| {
            let Ok(identities) = core.pgp_identities() else {
                return null_mut();
            };
            handed(PeIdentityList(Rows::new(
                &identities,
                |identity: &PgpIdentity, strings| PeIdentity {
                    address: strings.add(&identity.address),
                    fingerprint: strings.add(&identity.fingerprint),
                    autocrypt: identity.autocrypt,
                },
            )))
        })
    }
}

/// # Safety
/// `list` must be NULL or a list that was not freed yet.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn pe_pgp_identity_list_count(list: *const PeIdentityList) -> usize {
    // SAFETY: as the caller guarantees
    Rows::count(unsafe { list.as_ref() }.map(|list| &list.0))
}

/// # Safety
/// `list` must be NULL or a list that was not freed yet.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn pe_pgp_identity_list_get(list: *const PeIdentityList, index: usize) -> *const PeIdentity {
    // SAFETY: as the caller guarantees
    Rows::get(unsafe { list.as_ref() }.map(|list| &list.0), index)
}

/// # Safety
/// `list` must be NULL or a list that was not freed yet.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn pe_pgp_identity_list_free(list: *mut PeIdentityList) {
    // SAFETY: as the caller guarantees
    unsafe { take_back(list) }
}

/// What to ask after an import when own addresses one of the user's keys holds use no key yet ("Use this key for
/// ...?"), NULL when there are none: the answer Use It is `pe_pgp_claim_unclaimed`. Free with `pe_string_free`.
///
/// # Safety
/// `core` must be a live handle.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn pe_pgp_unclaimed_question(core: *const PeCore) -> *mut c_char {
    // SAFETY: as the caller guarantees
    unsafe {
        with(core, null_mut(), |core| {
            core.pgp_unclaimed_question()
                .ok()
                .flatten()
                .map_or(null_mut(), into_c_string)
        })
    }
}

/// Each of those addresses uses its key, with Autocrypt
///
/// # Safety
/// `core` must be a live handle.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn pe_pgp_claim_unclaimed(core: *const PeCore) -> bool {
    // SAFETY: as the caller guarantees
    unsafe { with(core, false, |core| core.pgp_claim_unclaimed().is_ok()) }
}

/// The fingerprint of an account's key, NULL without one; `autocrypt` (when not NULL) set to whether its mail
/// carries it (true without a key, as a new key starts). Free with `pe_string_free`.
///
/// # Safety
/// `core` must be a live handle, `autocrypt` NULL or writable.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn pe_pgp_account_key(core: *const PeCore, account: i64, autocrypt: *mut bool) -> *mut c_char {
    // SAFETY: as the caller guarantees
    unsafe {
        with(core, null_mut(), |core| {
            let identity = core.pgp_account_key(account).ok().flatten();
            if !autocrypt.is_null() {
                *autocrypt = identity.as_ref().is_none_or(|identity| identity.autocrypt);
            }
            identity.map_or(null_mut(), |identity| into_c_string(identity.fingerprint))
        })
    }
}

/// The file name a key is saved under: public, or a backup of the private key; NULL for no such key. Free with
/// `pe_string_free`.
///
/// # Safety
/// `core` must be a live handle, `fingerprint` a NUL-terminated string.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn pe_pgp_file_name(
    core: *const PeCore,
    fingerprint: *const c_char,
    private: bool,
) -> *mut c_char {
    // SAFETY: as the caller guarantees
    let fingerprint = unsafe { arg(fingerprint) }.unwrap_or_default();
    // SAFETY: as the caller guarantees
    unsafe {
        with(core, null_mut(), |core| {
            core.pgp_file_name(fingerprint, private)
                .map_or(null_mut(), into_c_string)
        })
    }
}

/// Sets the key of an account (Account Properties): of its address and of its other addresses that used the
/// account's key or none; an empty `fingerprint` (None) takes the key away from them. Nothing changes when neither the
/// key nor `autocrypt` did.
///
/// # Safety
/// `core` must be a live handle, `fingerprint` a NUL-terminated string.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn pe_pgp_set_account_key(
    core: *const PeCore,
    account: i64,
    fingerprint: *const c_char,
    autocrypt: bool,
) -> bool {
    // SAFETY: as the caller guarantees
    let fingerprint = unsafe { arg(fingerprint).unwrap_or_default() };
    // SAFETY: as the caller guarantees
    unsafe {
        with(core, false, |core| {
            core.pgp_set_account_key(account, fingerprint, autocrypt).is_ok()
        })
    }
}

/// Options > Security: whether the search index keeps the text of encrypted messages once they are opened
///
/// # Safety
/// `core` must be a live handle.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn pe_pgp_index_encrypted(core: *const PeCore) -> bool {
    // SAFETY: as the caller guarantees
    unsafe { with(core, false, |core| core.pgp_index_encrypted().unwrap_or(false)) }
}

/// Turns it on or off; off, the text decrypted so far leaves the index
///
/// # Safety
/// `core` must be a live handle.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn pe_pgp_set_index_encrypted(core: *const PeCore, on: bool) -> bool {
    // SAFETY: as the caller guarantees
    unsafe { with(core, false, |core| core.set_pgp_index_encrypted(on).is_ok()) }
}

/// Settings > Reading > Encryption: whether keys are looked up on keys.openpgp.org (Encrypt and Find Key)
///
/// # Safety
/// `core` must be a live handle.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn pe_pgp_keyserver(core: *const PeCore) -> bool {
    // SAFETY: as the caller guarantees
    unsafe { with(core, true, |core| core.pgp_keyserver().unwrap_or(true)) }
}

/// Turns it on or off
///
/// # Safety
/// `core` must be a live handle.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn pe_pgp_set_keyserver(core: *const PeCore, on: bool) -> bool {
    // SAFETY: as the caller guarantees
    unsafe { with(core, false, |core| core.set_pgp_keyserver(on).is_ok()) }
}
