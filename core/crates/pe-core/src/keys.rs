//! OpenPGP keys: the user's own, with their private parts, and their correspondents'.
//!
//! **Private keys at rest.** A random 32 byte master key is kept in the system's password store (`Secrets`, beside the
//! mail passwords, `<profile>/pgp`). Each private key is kept in the local store wrapped under it with
//! ChaCha20-Poly1305, its fingerprint and the store's profile as the associated data, so a wrapped key opens only in
//! its own row of its own store. A passphrase is asked once, when a protected key is imported, and never kept; the
//! only passphrase the user chooses is the one of a backup. Where the system has no password store, there are no
//! private keys (public keys still work).
//!
//! **Correspondents' keys.** The key in use for an address is chosen once and never changed silently: another key
//! for the same address, from wherever it came, waits until the user picks it (`decide`). A key and the rule for
//! its addresses are written in one transaction, so two connections learning keys at once can not lose a decision.

use std::collections::{HashMap, HashSet};
use std::sync::Mutex;

use base64::Engine;
use base64::engine::general_purpose::STANDARD;
use pe_i18n::{Text, tr, tr_args};
use pe_pgp::{Cert, SecretKey};
use pe_store::{AccountId, PgpIdentity, PgpPeer, Store, StoredKey, normal_address};
use ring::aead::{Aad, CHACHA20_POLY1305, LessSafeKey, Nonce, UnboundKey};
use ring::rand::{SecureRandom, SystemRandom};
use zeroize::Zeroizing;

use crate::secrets::{Key, Secrets, store_name};
use crate::worker::unix_now;
use crate::{Core, Error, Result};

/// The version byte of a wrapped key, ahead of its nonce and ciphertext
const WRAP_VERSION: u8 = 1;

/// Where a key came from, as the store keeps it
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum KeySource {
    Own,
    File,
    Paste,
    Attachment,
    Vcard,
    Wkd,
    Keyserver,
    Autocrypt,
}

const SOURCES: [(KeySource, &str, Text); 8] = [
    (KeySource::Own, "own", Text::PgpSourceOwn),
    (KeySource::File, "file", Text::PgpSourceFile),
    (KeySource::Paste, "paste", Text::PgpSourcePaste),
    (KeySource::Attachment, "attachment", Text::PgpSourceAttachment),
    (KeySource::Vcard, "vcard", Text::PgpSourceVcard),
    (KeySource::Wkd, "wkd", Text::PgpSourceWkd),
    (KeySource::Keyserver, "keyserver", Text::PgpSourceKeyserver),
    (KeySource::Autocrypt, "autocrypt", Text::PgpSourceAutocrypt),
];

impl KeySource {
    pub fn code(self) -> &'static str {
        SOURCES
            .iter()
            .find(|(source, _, _)| *source == self)
            .map_or("file", |(_, code, _)| code)
    }

    /// Where a stored key came from, in words
    fn words(code: &str) -> String {
        tr(SOURCES
            .iter()
            .find(|(_, c, _)| *c == code)
            .map_or(Text::PgpSourceFile, |(_, _, text)| *text))
    }
}

/// What a key is now
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum KeyState {
    Valid,
    Expired,
    Revoked,
    /// No valid self-signature, or the policy refuses it
    NotValid,
    /// An own key whose private part can not be opened: the master key is gone
    Locked,
}

/// A key as the windows show it
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct KeyInfo {
    /// Upper case hex
    pub fingerprint: String,
    /// In groups of four, for comparing
    pub grouped: String,
    /// The user ids valid now
    pub user_ids: Vec<String>,
    /// The addresses it holds, each with whether the user compared its fingerprint
    pub addresses: Vec<(String, bool)>,
    /// Every address it holds is verified (and it holds one)
    pub verified: bool,
    /// The user's own: it has its private part
    pub own: bool,
    pub state: KeyState,
    /// The state in words: "Valid", "Valid until 3 May 2027", "Revoked: key compromised"
    pub state_text: String,
    pub created: i64,
    pub expires: Option<i64>,
    /// "Ed25519", "RSA 4096"
    pub algorithm: String,
    /// Where it came from, in words
    pub source: String,
}

/// A correspondent's keys: the fingerprints of the one in use and of a newer one waiting for the user's decision
#[derive(Debug, Clone, Default, PartialEq, Eq)]
pub struct PeerKeys {
    pub address: String,
    pub in_use: Option<String>,
    pub pending: Option<String>,
    pub pending_since: Option<i64>,
}

/// What became of an address when a key was imported or found
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum Learned {
    /// The address had no key; this one is used now
    Used,
    /// The address already uses this key (it may have been updated)
    Same,
    /// The address uses another key; this one waits for the user's decision
    Pending,
    /// One of the user's own addresses: its key is the user's choice in My Keys
    Own,
}

/// The result of an import
#[derive(Debug, Clone, Default, PartialEq, Eq)]
pub struct Imported {
    /// The fingerprints of the keys imported, private ones first
    pub keys: Vec<String>,
    /// How many of them are private keys
    pub private: usize,
    /// Each address of a public key and what became of it
    pub addresses: Vec<(String, Learned)>,
    /// The user's own addresses an imported private key holds: an import never makes it their key by itself (a key
    /// file can come from anyone), the windows ask "Use this key for ...?" and call `pgp_set_identity`
    pub own: Vec<(String, String)>,
}

impl Imported {
    /// What the import did, in words, to show the user
    pub fn summary(&self) -> String {
        let mut out = Vec::new();
        if self.private > 0 {
            out.push(tr_args(
                Text::PgpImportedPrivate,
                &[("count", (self.private as i64).into())],
            ));
        }
        let public = self.keys.len() - self.private;
        if public > 0 {
            out.push(tr_args(Text::PgpImportedPublic, &[("count", (public as i64).into())]));
        }
        let waiting: Vec<&str> = self
            .addresses
            .iter()
            .filter(|(_, learned)| *learned == Learned::Pending)
            .map(|(address, _)| address.as_str())
            .collect();
        if !waiting.is_empty() {
            out.push(tr_args(
                Text::PgpImportedPending,
                &[("addresses", (&waiting.join(", ")).into())],
            ));
        }
        out.join(" ")
    }
}

/// Why an import failed
#[derive(Debug, Clone, PartialEq, Eq)]
pub enum ImportError {
    /// Private keys protected by a passphrase: ask for it and import again
    NeedsPassphrase,
    WrongPassphrase,
    /// Not usable, in words
    Invalid(String),
}

impl ImportError {
    /// In words, to show the user
    pub fn text(&self) -> String {
        match self {
            ImportError::NeedsPassphrase => tr(Text::PgpErrorNeedsPassphrase),
            ImportError::WrongPassphrase => tr(Text::PgpErrorWrongPassphrase),
            ImportError::Invalid(words) => words.clone(),
        }
    }
}

impl From<Error> for ImportError {
    fn from(error: Error) -> Self {
        ImportError::Invalid(error.to_string())
    }
}

fn locked_text() -> String {
    tr_args(Text::PgpKeyLocked, &[("store", (&store_name()).into())])
}

/// The master key: the one in the system's store, or a new one kept there. None when there is none and `create`
/// is false.
fn master(secrets: &Secrets, create: bool) -> Result<Option<Zeroizing<[u8; 32]>>> {
    if let Some(encoded) = secrets.get(Key::Pgp) {
        let bytes = Zeroizing::new(STANDARD.decode(encoded.trim()).unwrap_or_default());
        let mut key = Zeroizing::new([0u8; 32]);
        if bytes.len() == 32 {
            key.copy_from_slice(&bytes);
            return Ok(Some(key));
        }
    }
    if !create {
        return Ok(None);
    }
    let mut key = Zeroizing::new([0u8; 32]);
    SystemRandom::new()
        .fill(&mut key[..])
        .map_err(|_| Error::Unavailable("random".into()))?;
    let encoded = Zeroizing::new(STANDARD.encode(&key[..]));
    secrets.set(Key::Pgp, &encoded).map_err(|why| {
        Error::Unavailable(tr_args(
            Text::PgpErrorNoStore,
            &[("store", (&store_name()).into()), ("error", (&why).into())],
        ))
    })?;
    Ok(Some(key))
}

fn aead_key(master: &[u8; 32]) -> Result<LessSafeKey> {
    let key = UnboundKey::new(&CHACHA20_POLY1305, master).map_err(|_| Error::Unavailable("key".into()))?;
    Ok(LessSafeKey::new(key))
}

/// The associated data that binds a wrapped key to its row and its store
fn aad(profile: &str, fingerprint: &str) -> Vec<u8> {
    format!("inboxclassic pgp 1\0{profile}\0{fingerprint}").into_bytes()
}

/// `plain` (a private key without passphrase) wrapped under `master`: version, nonce, ciphertext and tag
pub(crate) fn wrap(master: &[u8; 32], profile: &str, fingerprint: &str, plain: &[u8]) -> Result<Vec<u8>> {
    let mut nonce = [0u8; 12];
    SystemRandom::new()
        .fill(&mut nonce)
        .map_err(|_| Error::Unavailable("random".into()))?;
    let mut sealed = plain.to_vec();
    aead_key(master)?
        .seal_in_place_append_tag(
            Nonce::assume_unique_for_key(nonce),
            Aad::from(aad(profile, fingerprint)),
            &mut sealed,
        )
        .map_err(|_| Error::Unavailable("seal".into()))?;
    let mut out = Vec::with_capacity(1 + 12 + sealed.len());
    out.push(WRAP_VERSION);
    out.extend_from_slice(&nonce);
    out.extend_from_slice(&sealed);
    Ok(out)
}

/// The private key in `wrapped`, if it opens under `master` for this row of this store
pub(crate) fn unwrap(
    master: &[u8; 32],
    profile: &str,
    fingerprint: &str,
    wrapped: &[u8],
) -> Option<Zeroizing<Vec<u8>>> {
    let (&version, rest) = wrapped.split_first()?;
    if version != WRAP_VERSION || rest.len() < 12 + 16 {
        return None;
    }
    let (nonce, sealed) = rest.split_at(12);
    let mut buffer = Zeroizing::new(sealed.to_vec());
    let nonce = Nonce::try_assume_unique_for_key(nonce).ok()?;
    let plain = aead_key(master)
        .ok()?
        .open_in_place(nonce, Aad::from(aad(profile, fingerprint)), &mut buffer)
        .ok()?;
    Some(Zeroizing::new(plain.to_vec()))
}

/// Certificates as read from the store, kept once read: reading one checks every signature it carries, which the
/// key list would otherwise do for every key each time it is shown. Keyed by the fingerprint, valid while the stored
/// bytes are the same.
#[derive(Default)]
pub(crate) struct CertCache(Mutex<HashMap<String, (Vec<u8>, Cert)>>);

impl CertCache {
    fn get(&self, key: &StoredKey) -> Option<Cert> {
        let mut cache = self.0.lock().unwrap_or_else(|poisoned| poisoned.into_inner());
        if let Some((bytes, cert)) = cache.get(&key.fingerprint)
            && *bytes == key.cert
        {
            return Some(cert.clone());
        }
        let cert = pe_pgp::read_certs(&key.cert).ok()?.into_iter().next()?;
        cache.insert(key.fingerprint.clone(), (key.cert.clone(), cert.clone()));
        Some(cert)
    }
}

/// The key book of one store: what keys.rs does, on the store and the password store given
pub(crate) struct Book<'a> {
    store: &'a Store,
    secrets: &'a Secrets,
    certs: &'a CertCache,
    profile: String,
    /// The user's own addresses, looked up once
    own: std::cell::OnceCell<HashSet<String>>,
}

impl<'a> Book<'a> {
    pub fn new(store: &'a Store, secrets: &'a Secrets, certs: &'a CertCache) -> Result<Book<'a>> {
        Ok(Book {
            store,
            secrets,
            certs,
            profile: store.profile_id()?,
            own: Default::default(),
        })
    }

    /// Whether the private part of a stored key opens under the master key (without unwrapping it for use)
    fn opens(&self, key: &StoredKey, master: Option<&[u8; 32]>) -> bool {
        match (master, key.secret.as_deref()) {
            (Some(master), Some(wrapped)) => unwrap(master, &self.profile, &key.fingerprint, wrapped).is_some(),
            _ => false,
        }
    }

    /// Every key as the windows show it, own keys first
    pub fn list(&self) -> Result<Vec<KeyInfo>> {
        let master = master(self.secrets, false)?;
        let mut addresses: HashMap<String, Vec<(String, bool)>> = HashMap::new();
        for held in self.store.pgp_key_addresses(None)? {
            addresses
                .entry(held.fingerprint)
                .or_default()
                .push((held.address, held.verified));
        }
        Ok(self
            .store
            .pgp_keys()?
            .iter()
            .filter_map(|key| {
                let held = addresses.remove(&key.fingerprint).unwrap_or_default();
                self.info(key, master.as_deref(), held)
            })
            .collect())
    }

    pub fn get(&self, fingerprint: &str) -> Result<KeyInfo> {
        let key = self.store.pgp_key(fingerprint)?.ok_or(Error::NotFound)?;
        let master = master(self.secrets, false)?;
        let held = self.store.pgp_key_addresses(Some(fingerprint))?;
        let held = held.into_iter().map(|held| (held.address, held.verified)).collect();
        self.info(&key, master.as_deref(), held).ok_or(Error::NotFound)
    }

    fn info(&self, key: &StoredKey, master: Option<&[u8; 32]>, addresses: Vec<(String, bool)>) -> Option<KeyInfo> {
        let cert = self.certs.get(key)?;
        let now = unix_now();
        let own = key.secret.is_some();
        let date = crate::calendar::local_date;
        let (state, state_text) = match cert.status(now) {
            _ if own && !self.opens(key, master) => (KeyState::Locked, locked_text()),
            Ok(()) => match cert.expires(now) {
                Some(at) => (
                    KeyState::Valid,
                    tr_args(Text::PgpKeyExpires, &[("date", (&date(at)).into())]),
                ),
                None => (KeyState::Valid, tr(Text::PgpKeyValid)),
            },
            Err(pe_pgp::CertProblem::Expired { at }) => (
                KeyState::Expired,
                tr_args(Text::PgpKeyExpired, &[("date", (&date(at)).into())]),
            ),
            Err(pe_pgp::CertProblem::Revoked { reason: Some(reason) }) => (
                KeyState::Revoked,
                tr_args(Text::PgpKeyRevokedWhy, &[("reason", (&reason).into())]),
            ),
            Err(pe_pgp::CertProblem::Revoked { reason: None }) => (KeyState::Revoked, tr(Text::PgpKeyRevoked)),
            Err(_) => (KeyState::NotValid, tr(Text::PgpKeyNotValid)),
        };
        Some(KeyInfo {
            grouped: pe_pgp::grouped(&key.fingerprint),
            fingerprint: key.fingerprint.clone(),
            user_ids: cert.user_ids(now).into_iter().map(|user| user.text).collect(),
            verified: !addresses.is_empty() && addresses.iter().all(|(_, verified)| *verified),
            addresses,
            own,
            state,
            state_text,
            created: cert.created(),
            expires: cert.expires(now),
            algorithm: cert.algorithm(),
            source: KeySource::words(&key.source),
        })
    }

    /// The user's own addresses: every account's and its other addresses
    fn own_addresses(&self) -> Result<&HashSet<String>> {
        if let Some(own) = self.own.get() {
            return Ok(own);
        }
        let mut own = HashSet::new();
        for account in self.store.accounts()? {
            own.extend(
                crate::own_addresses(self.store, account.id)?
                    .iter()
                    .map(|address| normal_address(address)),
            );
        }
        Ok(self.own.get_or_init(|| own))
    }

    /// Saves a certificate (merged with the copy kept) and, for an own key, its private part wrapped; its addresses.
    /// Nothing is written when the certificate brings nothing new.
    fn save(&self, cert: &Cert, secret: Option<Vec<u8>>, source: KeySource) -> pe_store::Result<Vec<String>> {
        let now = unix_now();
        let fingerprint = cert.fingerprint();
        let stored = self.store.pgp_key(&fingerprint)?;
        let cert = match stored.as_ref().and_then(|stored| self.certs.get(stored)) {
            Some(old) => old.merge(cert).unwrap_or(old),
            None => cert.clone(),
        };
        let addresses = cert.addresses(now);
        let bytes = cert.to_bytes();
        if secret.is_none() && stored.as_ref().is_some_and(|stored| stored.cert == bytes) {
            return Ok(addresses);
        }
        let key = StoredKey {
            fingerprint,
            cert: bytes,
            secret,
            source: source.code().into(),
            added: now,
            changed: now,
        };
        self.store.save_pgp_key(&key, &addresses)?;
        Ok(addresses)
    }

    /// Keeps a private key wrapped under the master key (made now if there is none) with its addresses; the user's own
    /// addresses it holds, which only a key made here takes by itself (`claim`)
    fn keep_secret(&self, key: &SecretKey, source: KeySource, claim: bool) -> Result<Vec<String>> {
        let master = master(self.secrets, true)?.ok_or(Error::NotFound)?;
        let fingerprint = key.fingerprint();
        let wrapped = wrap(&master, &self.profile, &fingerprint, &key.to_bytes())?;
        let own = self.own_addresses()?.clone();
        Ok(self.store.pgp_transaction(|| {
            let addresses = self.save(key.cert(), Some(wrapped), source)?;
            let held: Vec<String> = addresses.into_iter().filter(|address| own.contains(address)).collect();
            if claim {
                for address in &held {
                    self.store.set_pgp_identity(&PgpIdentity {
                        address: address.clone(),
                        fingerprint: fingerprint.clone(),
                        autocrypt: true,
                    })?;
                }
            }
            Ok(held)
        })?)
    }

    /// A new key for the account's address and its other addresses, which then use it
    pub fn generate(&self, account: AccountId) -> Result<String> {
        let name = self.store.account(account)?.settings.name;
        let mut addresses: Vec<String> = Vec::new();
        for address in crate::own_addresses(self.store, account)? {
            let address = normal_address(&address);
            if !addresses.contains(&address) {
                addresses.push(address);
            }
        }
        let key = pe_pgp::generate(&name, &addresses, unix_now()).map_err(|error| Error::Invalid(error.to_string()))?;
        self.keep_secret(&key, KeySource::Own, true)?;
        Ok(key.fingerprint())
    }

    /// Learns a correspondent's certificate: merged with the copy kept, stored, and for each of its addresses the
    /// changed key rule, at once
    pub fn learn(&self, cert: &Cert, source: KeySource) -> Result<Vec<(String, Learned)>> {
        let own = self.own_addresses()?.clone();
        let fingerprint = cert.fingerprint();
        let now = unix_now();
        Ok(self.store.pgp_transaction(|| {
            let addresses = self.save(cert, None, source)?;
            addresses
                .into_iter()
                .map(|address| {
                    let learned = if own.contains(&address) {
                        Learned::Own
                    } else {
                        self.peer_learns(&address, &fingerprint, now)?
                    };
                    Ok((address, learned))
                })
                .collect()
        })?)
    }

    /// The changed key rule for one address: a key is used when the address has none; another waits
    fn peer_learns(&self, address: &str, fingerprint: &str, now: i64) -> pe_store::Result<Learned> {
        let mut peer = self.store.pgp_peer(address)?.unwrap_or_else(|| PgpPeer {
            address: address.to_string(),
            ..PgpPeer::default()
        });
        let learned = match peer.fingerprint.as_deref() {
            None => {
                peer.fingerprint = Some(fingerprint.to_string());
                Learned::Used
            }
            Some(used) if used == fingerprint => return Ok(Learned::Same),
            Some(_) if peer.pending.as_deref() == Some(fingerprint) => return Ok(Learned::Pending),
            Some(_) => {
                peer.pending = Some(fingerprint.to_string());
                peer.pending_since = Some(now);
                Learned::Pending
            }
        };
        self.store.set_pgp_peer(&peer)?;
        Ok(learned)
    }

    /// Imports keys from `bytes` (a file, pasted text, an attachment): private ones unlocked with `passphrase` and
    /// kept wrapped, or else public ones learned
    pub fn import(
        &self,
        bytes: &[u8],
        passphrase: Option<&str>,
        source: KeySource,
    ) -> std::result::Result<Imported, ImportError> {
        let locked = match pe_pgp::needs_passphrase(bytes) {
            Ok(locked) => Some(locked),
            Err(pe_pgp::Error::WrongKind) => None,
            Err(error) => return Err(ImportError::Invalid(words(&error))),
        };
        match locked {
            Some(true) if passphrase.is_none() => Err(ImportError::NeedsPassphrase),
            Some(_) => self.import_secret(bytes, passphrase.unwrap_or(""), source),
            None => self.import_public(bytes, source),
        }
    }

    fn import_secret(
        &self,
        bytes: &[u8],
        passphrase: &str,
        source: KeySource,
    ) -> std::result::Result<Imported, ImportError> {
        let keys = pe_pgp::read_secret_keys(bytes, passphrase).map_err(|error| match error {
            pe_pgp::Error::WrongPassphrase => ImportError::WrongPassphrase,
            other => ImportError::Invalid(words(&other)),
        })?;
        let mut imported = Imported {
            private: keys.len(),
            ..Imported::default()
        };
        for key in &keys {
            let fingerprint = key.fingerprint();
            for address in self.keep_secret(key, source, false)? {
                imported.own.push((address, fingerprint.clone()));
            }
            imported.keys.push(fingerprint);
        }
        Ok(imported)
    }

    fn import_public(&self, bytes: &[u8], source: KeySource) -> std::result::Result<Imported, ImportError> {
        let certs = pe_pgp::read_certs(bytes).map_err(|error| ImportError::Invalid(words(&error)))?;
        let mut imported = Imported::default();
        for cert in &certs {
            imported.addresses.extend(self.learn(cert, source)?);
            imported.keys.push(cert.fingerprint());
        }
        Ok(imported)
    }

    /// The keys a vCard file carries, learned (a different key for an address that has one waits)
    pub fn learn_vcard_keys(&self, text: &str) -> Result<()> {
        for bytes in crate::vcard::read_keys(text) {
            for cert in pe_pgp::read_certs(&bytes).unwrap_or_default() {
                self.learn(&cert, KeySource::Vcard)?;
            }
        }
        Ok(())
    }

    /// The smallest copy of the key in use for `address`, for a vCard or an Autocrypt header
    pub fn minimal_cert_for(&self, address: &str) -> Result<Option<Vec<u8>>> {
        let Some(fingerprint) = self.store.pgp_peer(address)?.and_then(|peer| peer.fingerprint) else {
            return Ok(None);
        };
        let Some(key) = self.store.pgp_key(&fingerprint)? else {
            return Ok(None);
        };
        let Some(cert) = self.certs.get(&key) else {
            return Ok(None);
        };
        Ok(Some(cert.minimal(address, unix_now()).unwrap_or(cert).to_bytes()))
    }

    pub fn export(&self, fingerprint: &str) -> Result<String> {
        let key = self.store.pgp_key(fingerprint)?.ok_or(Error::NotFound)?;
        Ok(self.certs.get(&key).ok_or(Error::NotFound)?.armored())
    }

    /// The private key protected by `passphrase`, armored, for a backup
    pub fn backup(&self, fingerprint: &str, passphrase: &str) -> Result<String> {
        if passphrase.is_empty() {
            return Err(Error::Invalid(tr(Text::PgpErrorEmptyPassphrase)));
        }
        self.own_key(fingerprint)?
            .backup(passphrase)
            .map_err(|error| Error::Invalid(words(&error)))
    }

    /// An own key, unwrapped for one use
    pub fn own_key(&self, fingerprint: &str) -> Result<SecretKey> {
        let key = self.store.pgp_key(fingerprint)?.ok_or(Error::NotFound)?;
        let wrapped = key.secret.as_deref().ok_or(Error::NotFound)?;
        let master = master(self.secrets, false)?.ok_or_else(|| Error::Unavailable(locked_text()))?;
        let plain =
            unwrap(&master, &self.profile, fingerprint, wrapped).ok_or_else(|| Error::Unavailable(locked_text()))?;
        SecretKey::from_bytes(&plain).map_err(|error| Error::Invalid(words(&error)))
    }

    pub fn peer(&self, address: &str) -> Result<PeerKeys> {
        let address = normal_address(address);
        let peer = self.store.pgp_peer(&address)?.unwrap_or_default();
        Ok(PeerKeys {
            address,
            in_use: peer.fingerprint,
            pending: peer.pending,
            pending_since: peer.pending_since,
        })
    }

    /// The user's decision about a correspondent's waiting key: use it, or keep the one in use
    pub fn decide(&self, address: &str, use_new: bool) -> Result<()> {
        let Some(mut peer) = self.store.pgp_peer(address)? else {
            return Ok(());
        };
        if use_new && peer.pending.is_some() {
            peer.fingerprint = peer.pending.take();
        }
        peer.pending = None;
        peer.pending_since = None;
        Ok(self.store.set_pgp_peer(&peer)?)
    }
}

/// What went wrong reading keys, in words
fn words(error: &pe_pgp::Error) -> String {
    match error {
        pe_pgp::Error::WrongPassphrase => tr(Text::PgpErrorWrongPassphrase),
        pe_pgp::Error::TooLarge => tr(Text::PgpErrorTooLarge),
        pe_pgp::Error::Unusable(_) => tr(Text::PgpErrorUnusable),
        pe_pgp::Error::Mismatch => tr(Text::PgpErrorMismatch),
        _ => tr(Text::PgpErrorNotAKey),
    }
}

impl Core {
    pub(crate) fn book<T, E: From<Error>>(
        &self,
        work: impl FnOnce(&Book<'_>) -> std::result::Result<T, E>,
    ) -> std::result::Result<T, E> {
        let store = self.store();
        let book = Book::new(&store, &self.secrets, &self.pgp_certs)?;
        work(&book)
    }

    /// Every key, own keys first
    pub fn pgp_keys(&self) -> Result<Vec<KeyInfo>> {
        self.book(|book| book.list())
    }

    pub fn pgp_key(&self, fingerprint: &str) -> Result<KeyInfo> {
        self.book(|book| book.get(fingerprint))
    }

    /// Whether a private key kept now can still be opened after a restart: false with memory passwords, where the
    /// windows say so before making or importing one
    pub fn pgp_private_keys_kept(&self) -> bool {
        self.secrets.persistent()
    }

    /// Makes a new key for an account and its other addresses; its fingerprint
    pub fn pgp_generate(&self, account: AccountId) -> Result<String> {
        self.book(|book| book.generate(account))
    }

    /// Imports keys from a file, pasted text or an attachment
    pub fn pgp_import(
        &self,
        bytes: &[u8],
        passphrase: Option<&str>,
        source: KeySource,
    ) -> std::result::Result<Imported, ImportError> {
        self.book(|book| book.import(bytes, passphrase, source))
    }

    /// The public key, armored
    pub fn pgp_export(&self, fingerprint: &str) -> Result<String> {
        self.book(|book| book.export(fingerprint))
    }

    /// The private key protected by `passphrase`, armored
    pub fn pgp_backup(&self, fingerprint: &str, passphrase: &str) -> Result<String> {
        self.book(|book| book.backup(fingerprint, passphrase))
    }

    pub fn pgp_remove(&self, fingerprint: &str) -> Result<()> {
        Ok(self.store().remove_pgp_key(fingerprint)?)
    }

    pub fn pgp_set_verified(&self, fingerprint: &str, address: &str, verified: bool) -> Result<()> {
        Ok(self.store().set_pgp_verified(fingerprint, address, verified)?)
    }

    /// A correspondent's key in use and the one waiting for a decision
    pub fn pgp_peer(&self, address: &str) -> Result<PeerKeys> {
        self.book(|book| book.peer(address))
    }

    pub fn pgp_decide(&self, address: &str, use_new: bool) -> Result<()> {
        self.book(|book| book.decide(address, use_new))
    }

    /// The key own addresses use, and whether their mail carries it in the Autocrypt header
    pub fn pgp_identities(&self) -> Result<Vec<PgpIdentity>> {
        Ok(self.store().pgp_identities()?)
    }

    pub fn pgp_set_identity(&self, address: &str, fingerprint: &str, autocrypt: bool) -> Result<()> {
        let identity = PgpIdentity {
            address: address.into(),
            fingerprint: fingerprint.into(),
            autocrypt,
        };
        Ok(self.store().set_pgp_identity(&identity)?)
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::secrets::PasswordStore;

    #[test]
    fn a_wrapped_key_opens_only_where_it_was_wrapped() {
        let master = [7u8; 32];
        let wrapped = wrap(&master, "profile", "AA", b"secret key").unwrap();
        assert!(!wrapped.windows(10).any(|w| w == b"secret key"));
        assert_eq!(
            unwrap(&master, "profile", "AA", &wrapped).unwrap().as_slice(),
            b"secret key"
        );
        assert!(
            unwrap(&[8u8; 32], "profile", "AA", &wrapped).is_none(),
            "another master key"
        );
        assert!(unwrap(&master, "other", "AA", &wrapped).is_none(), "another store");
        assert!(unwrap(&master, "profile", "BB", &wrapped).is_none(), "another row");
        let mut changed = wrapped.clone();
        *changed.last_mut().unwrap() ^= 1;
        assert!(unwrap(&master, "profile", "AA", &changed).is_none(), "a changed byte");
        assert!(unwrap(&master, "profile", "AA", &wrapped[..20]).is_none(), "cut short");
        assert_ne!(
            wrap(&master, "profile", "AA", b"secret key").unwrap(),
            wrapped,
            "a nonce of its own"
        );
    }

    #[test]
    fn the_master_key_is_made_once() {
        let secrets = Secrets::new(PasswordStore::Memory, "t");
        assert!(master(&secrets, false).unwrap().is_none());
        let first = master(&secrets, true).unwrap().unwrap();
        let again = master(&secrets, false).unwrap().unwrap();
        assert_eq!(*first, *again);
    }

    #[test]
    fn sources_have_codes_and_words() {
        for (source, code, _) in SOURCES {
            assert_eq!(source.code(), code);
            assert!(!KeySource::words(code).is_empty());
        }
    }
}
