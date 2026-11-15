//! OpenPGP keys through C: the key book as lists of rows, a key made, imported, exported, backed up, removed and
//! verified, a correspondent's key in use and the one waiting for a decision, and the key of each own address.
//! The decisions are the core's (pe-core `keys.rs`); C++ and Swift show what comes back.

use std::ffi::c_char;
use std::ptr::null_mut;

use pe_core::keys::{ImportError, KeyInfo, KeySource, KeyState};
use pe_store::PgpIdentity;

use crate::core::{PeCore, Rows, arg, handed, refused, take_back, with};
use crate::into_c_string;

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
    /// The addresses it holds, one a line (each with whether it is verified: `pe_pgp_key_addresses`)
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

/// An address a key holds
#[repr(C)]
pub struct PeKeyAddress {
    pub address: *const c_char,
    /// The user compared the key's fingerprint with its owner
    pub verified: bool,
}

pub struct PeKeyAddressList(Rows<PeKeyAddress>);

/// The addresses of a key; NULL when there is no such key. Free with `pe_pgp_key_address_list_free`.
///
/// # Safety
/// `core` must be a live handle, `fingerprint` a NUL-terminated string.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn pe_pgp_key_addresses(
    core: *const PeCore,
    fingerprint: *const c_char,
) -> *mut PeKeyAddressList {
    // SAFETY: as the caller guarantees
    let fingerprint = unsafe { arg(fingerprint) }.unwrap_or_default();
    // SAFETY: as the caller guarantees
    unsafe {
        with(core, null_mut(), |core| {
            let Ok(key) = core.pgp_key(fingerprint) else {
                return null_mut();
            };
            handed(PeKeyAddressList(Rows::new(
                &key.addresses,
                |(address, verified), strings| PeKeyAddress {
                    address: strings.add(address),
                    verified: *verified,
                },
            )))
        })
    }
}

/// # Safety
/// `list` must be NULL or a list that was not freed yet.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn pe_pgp_key_address_list_count(list: *const PeKeyAddressList) -> usize {
    // SAFETY: as the caller guarantees
    Rows::count(unsafe { list.as_ref() }.map(|list| &list.0))
}

/// # Safety
/// `list` must be NULL or a list that was not freed yet.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn pe_pgp_key_address_list_get(
    list: *const PeKeyAddressList,
    index: usize,
) -> *const PeKeyAddress {
    // SAFETY: as the caller guarantees
    Rows::get(unsafe { list.as_ref() }.map(|list| &list.0), index)
}

/// # Safety
/// `list` must be NULL or a list that was not freed yet.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn pe_pgp_key_address_list_free(list: *mut PeKeyAddressList) {
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

/// Marks whether the user compared the key's fingerprint with the owner of `address`
///
/// # Safety
/// `core` must be a live handle, `fingerprint` and `address` NUL-terminated strings.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn pe_pgp_set_verified(
    core: *const PeCore,
    fingerprint: *const c_char,
    address: *const c_char,
    verified: bool,
) -> bool {
    // SAFETY: as the caller guarantees
    let (fingerprint, address) = unsafe { (arg(fingerprint).unwrap_or_default(), arg(address).unwrap_or_default()) };
    // SAFETY: as the caller guarantees
    unsafe {
        with(core, false, |core| {
            core.pgp_set_verified(fingerprint, address, verified).is_ok()
        })
    }
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

/// Sets the key of an own address, and whether its mail carries the key in the Autocrypt header
///
/// # Safety
/// `core` must be a live handle, `address` and `fingerprint` NUL-terminated strings.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn pe_pgp_set_identity(
    core: *const PeCore,
    address: *const c_char,
    fingerprint: *const c_char,
    autocrypt: bool,
) -> bool {
    // SAFETY: as the caller guarantees
    let (address, fingerprint) = unsafe { (arg(address).unwrap_or_default(), arg(fingerprint).unwrap_or_default()) };
    // SAFETY: as the caller guarantees
    unsafe {
        with(core, false, |core| {
            core.pgp_set_identity(address, fingerprint, autocrypt).is_ok()
        })
    }
}
