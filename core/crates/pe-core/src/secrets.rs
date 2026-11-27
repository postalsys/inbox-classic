//! The passwords of the accounts (and the client secrets of sign-in apps): kept in memory while the app runs, and in
//! the system's password store between runs (the Credential Manager, the keychain, the Secret Service), so the user gives a password once. The credentials are named
//! after the store's profile ID and the account or app, so two stores on one machine (the app's, a test's) never
//! share one.
//!
//! The Credential Manager takes at most 2,560 bytes a credential (1,280 UTF-16 units), less than a refresh token of
//! some providers, so on Windows the store is wrapped in [`parts::Parts`], which keeps a longer secret in parts.

use std::collections::HashMap;
use std::sync::{Arc, Mutex, MutexGuard};

use pe_store::{AccountId, SignInAppId};

/// Whose secret: an account's password or refresh token, or a sign-in app's client secret
#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash)]
pub(crate) enum Key {
    Account(AccountId),
    App(SignInAppId),
    /// The master key that wraps the private OpenPGP keys (keys.rs)
    Pgp,
    /// Settings sync's vault key, base64 (sync)
    Vault,
    /// The secret access key of the S3 bucket settings sync uses
    SyncBucket,
    /// The passphrase settings sync's restore points are sealed with
    RestorePoints,
}

impl From<AccountId> for Key {
    fn from(account: AccountId) -> Key {
        Key::Account(account)
    }
}

/// Where passwords are kept between runs
#[derive(Debug, Clone, Copy, PartialEq, Eq, Default)]
pub enum PasswordStore {
    /// The Credential Manager on Windows, the login keychain on the Mac, the Secret Service on Linux
    #[default]
    System,
    /// Memory only: the user gives them again on the next run (tests, a shared computer)
    Memory,
}

/// A place passwords outlive the process in
pub(crate) trait Backend: Send + Sync {
    /// The secret kept for `key`: None when there is none, an error when the store could not be read (locked,
    /// refused, not answering), which is not the same
    fn load(&self, key: Key) -> Result<Option<String>, String>;
    fn save(&self, key: Key, password: &str) -> Result<(), String>;
    fn remove(&self, key: Key);
}

#[cfg(any(windows, test))]
mod parts;

/// The system's own password store: the Credential Manager on Windows, the login keychain on the Mac, the Secret
/// Service (GNOME Keyring) on Linux, all through keyring-core
#[cfg(any(windows, target_os = "macos", target_os = "linux"))]
mod native {
    use std::sync::Arc;

    use keyring_core::api::CredentialStoreApi;

    use super::Key;

    /// Credentials named `InboxClassic` / `<profile>/<account>` (or `<profile>/app/<app>`)
    pub(super) struct NativeStore {
        store: Arc<dyn CredentialStoreApi + Send + Sync>,
        profile: String,
    }

    use super::store_name as name;

    #[cfg(windows)]
    fn open() -> keyring_core::Result<Arc<dyn CredentialStoreApi + Send + Sync>> {
        Ok(windows_native_keyring_store::Store::new()?)
    }

    #[cfg(target_os = "macos")]
    fn open() -> keyring_core::Result<Arc<dyn CredentialStoreApi + Send + Sync>> {
        Ok(apple_native_keyring_store::keychain::Store::new()?)
    }

    #[cfg(target_os = "linux")]
    fn open() -> keyring_core::Result<Arc<dyn CredentialStoreApi + Send + Sync>> {
        Ok(zbus_secret_service_keyring_store::Store::new()?)
    }

    impl NativeStore {
        pub(super) fn new(profile: String) -> Result<NativeStore, String> {
            let store = open().map_err(|e| {
                pe_i18n::tr_args(
                    pe_i18n::Text::SecretsUnavailableWhy,
                    &[("store", (&name()).into()), ("error", (&e.to_string()).into())],
                )
            })?;
            Ok(NativeStore { store, profile })
        }

        fn entry(&self, key: Key, part: u32) -> Option<keyring_core::Entry> {
            let name = match key {
                Key::Account(account) => format!("{}/{account}", self.profile),
                Key::App(app) => format!("{}/app/{app}", self.profile),
                Key::Pgp => format!("{}/pgp", self.profile),
                Key::Vault => format!("{}/sync", self.profile),
                Key::SyncBucket => format!("{}/sync-bucket", self.profile),
                Key::RestorePoints => format!("{}/restore-points", self.profile),
            };
            // the further parts of a long secret (parts.rs)
            let name = if part == 0 { name } else { format!("{name}#{part}") };
            self.store.build("InboxClassic", &name, None).ok()
        }
    }

    impl NativeStore {
        fn unavailable() -> String {
            pe_i18n::tr_args(pe_i18n::Text::SecretsUnavailable, &[("store", (&name()).into())])
        }

        fn load_at(&self, key: Key, part: u32) -> Result<Option<String>, String> {
            let entry = self.entry(key, part).ok_or_else(Self::unavailable)?;
            match entry.get_password() {
                Ok(password) => Ok(Some(password)),
                Err(keyring_core::Error::NoEntry) => Ok(None),
                Err(error) => Err(error.to_string()),
            }
        }

        fn save_at(&self, key: Key, part: u32, password: &str) -> Result<(), String> {
            let entry = self.entry(key, part).ok_or_else(Self::unavailable)?;
            entry.set_password(password).map_err(|e| e.to_string())
        }

        fn remove_at(&self, key: Key, part: u32) {
            if let Some(entry) = self.entry(key, part) {
                let _ = entry.delete_credential();
            }
        }
    }

    /// The keychain and the Secret Service take a secret of any length whole
    #[cfg(not(windows))]
    impl super::Backend for NativeStore {
        fn load(&self, key: Key) -> Result<Option<String>, String> {
            self.load_at(key, 0)
        }

        fn save(&self, key: Key, password: &str) -> Result<(), String> {
            self.save_at(key, 0, password)
        }

        fn remove(&self, key: Key) {
            self.remove_at(key, 0)
        }
    }

    /// The Credential Manager, its parts named `#1`, `#2`, ... after the secret's own credential
    #[cfg(windows)]
    impl super::parts::PartStore for NativeStore {
        fn load_part(&self, key: Key, part: u32) -> Result<Option<String>, String> {
            self.load_at(key, part)
        }

        fn save_part(&self, key: Key, part: u32, text: &str) -> Result<(), String> {
            self.save_at(key, part, text)
        }

        fn remove_part(&self, key: Key, part: u32) {
            self.remove_at(key, part)
        }
    }
}

/// What the system's password store is called in messages to the user
pub(crate) fn store_name() -> String {
    use pe_i18n::{Text, tr};
    if cfg!(windows) {
        tr(Text::SecretsWindows)
    } else if cfg!(target_os = "macos") {
        tr(Text::SecretsMac)
    } else {
        tr(Text::SecretsLinux)
    }
}

#[derive(Default)]
struct SecretMap {
    passwords: HashMap<Key, String>,
    /// How many times each account's secret was set or removed: a refresh that started before a new sign-in does
    /// not write the refresh token it got over the new one ([`Secrets::set_unless_changed`])
    generations: HashMap<AccountId, u64>,
}

impl SecretMap {
    /// A new secret of `key`: a refresh under way keeps its token to itself
    fn changed(&mut self, key: Key) {
        if let Key::Account(account) = key {
            *self.generations.entry(account).or_default() += 1;
        }
    }
}

#[derive(Clone)]
pub(crate) struct Secrets {
    map: Arc<Mutex<SecretMap>>,
    backend: Option<Arc<dyn Backend>>,
    /// Why passwords are not kept between runs when they should be
    unavailable: Option<String>,
}

impl Secrets {
    /// Passwords kept as `kind` says, for the store with this profile ID
    pub(crate) fn new(kind: PasswordStore, profile: &str) -> Secrets {
        #[cfg(any(windows, target_os = "macos", target_os = "linux"))]
        let (backend, unavailable): (Option<Arc<dyn Backend>>, _) = match kind {
            PasswordStore::System => match native::NativeStore::new(profile.to_string()) {
                #[cfg(windows)]
                Ok(backend) => (Some(Arc::new(parts::Parts::new(backend))), None),
                #[cfg(not(windows))]
                Ok(backend) => (Some(Arc::new(backend)), None),
                Err(error) => (None, Some(error)),
            },
            PasswordStore::Memory => (None, None),
        };
        #[cfg(not(any(windows, target_os = "macos", target_os = "linux")))]
        let (backend, unavailable): (Option<Arc<dyn Backend>>, Option<String>) = {
            let _ = (kind, profile);
            (None, None)
        };
        Secrets {
            map: Arc::default(),
            backend,
            unavailable,
        }
    }

    fn map(&self) -> MutexGuard<'_, SecretMap> {
        self.map.lock().unwrap_or_else(|poisoned| poisoned.into_inner())
    }

    pub(crate) fn get(&self, key: impl Into<Key>) -> Option<String> {
        self.lookup(key).ok().flatten()
    }

    /// [`Secrets::get`], telling a store that could not be read from one with nothing kept
    pub(crate) fn lookup(&self, key: impl Into<Key>) -> Result<Option<String>, String> {
        let key = key.into();
        if let Some(password) = self.map().passwords.get(&key) {
            return Ok(Some(password.clone()));
        }
        let Some(backend) = self.backend.as_ref() else {
            return Ok(None);
        };
        let Some(password) = backend.load(key)? else {
            return Ok(None);
        };
        // a password set while this one was loaded is the newer one
        Ok(Some(self.map().passwords.entry(key).or_insert(password).clone()))
    }

    /// Secrets kept in `backend`, for the tests of a store that fails
    #[cfg(test)]
    pub(crate) fn with_backend(backend: Arc<dyn Backend>) -> Secrets {
        Secrets {
            map: Arc::default(),
            backend: Some(backend),
            unavailable: None,
        }
    }

    /// Keeps the password for this run, and between runs where the system has a place for it; the error says
    /// why it could not be kept between runs
    pub(crate) fn set(&self, key: impl Into<Key>, password: &str) -> Result<(), String> {
        let key = key.into();
        {
            let mut map = self.map();
            map.passwords.insert(key, password.to_string());
            map.changed(key);
        }
        self.save(key, password)
    }

    /// Keeps the password between runs, where the system has a place for it
    fn save(&self, key: Key, password: &str) -> Result<(), String> {
        match (&self.backend, &self.unavailable) {
            (Some(backend), _) => backend.save(key, password),
            (None, Some(reason)) => Err(reason.clone()),
            (None, None) => Ok(()),
        }
    }

    /// How many times the secret of `account` was set or removed: what [`Secrets::set_unless_changed`] compares
    pub(crate) fn generation(&self, account: AccountId) -> u64 {
        self.map().generations.get(&account).copied().unwrap_or(0)
    }

    /// Keeps `password` for `account` as [`Secrets::set`] does, unless the secret changed since it was
    /// `generation` (a new sign-in while a refresh with the old one was under way): Ok(false) then, and the newer one
    /// stays. A token a provider rotated keeps the refusals told, as nothing was signed in again.
    pub(crate) fn set_unless_changed(
        &self,
        account: AccountId,
        password: &str,
        generation: u64,
    ) -> Result<bool, String> {
        {
            let mut map = self.map();
            if map.generations.get(&account).copied().unwrap_or(0) != generation {
                return Ok(false);
            }
            map.passwords.insert(Key::Account(account), password.to_string());
        }
        self.save(Key::Account(account), password).map(|()| true)
    }

    pub(crate) fn remove(&self, key: impl Into<Key>) {
        let key = key.into();
        {
            let mut map = self.map();
            map.passwords.remove(&key);
            map.changed(key);
        }
        if let Some(backend) = &self.backend {
            backend.remove(key);
        }
    }

    /// Whether what is set here outlives the process: false with memory passwords (tests, a shared computer), where
    /// a private OpenPGP key kept today can not be opened after a restart
    pub(crate) fn persistent(&self) -> bool {
        self.backend.is_some()
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn memory_only() {
        let secrets = Secrets::new(PasswordStore::Memory, "test");
        assert_eq!(secrets.get(1), None);
        secrets.set(1, "pw").unwrap();
        assert_eq!(secrets.get(1).as_deref(), Some("pw"));
        secrets.set(1, "new").unwrap();
        assert_eq!(secrets.get(1).as_deref(), Some("new"));
        secrets.remove(1);
        assert_eq!(secrets.get(1), None);
        // an app's secret is kept apart from the account of the same number
        secrets.set(Key::App(1), "client secret").unwrap();
        assert_eq!(secrets.get(1), None);
        assert_eq!(secrets.get(Key::App(1)).as_deref(), Some("client secret"));
        secrets.remove(Key::App(1));
        assert_eq!(secrets.get(Key::App(1)), None);
    }

    #[test]
    fn a_refresh_does_not_write_over_a_new_sign_in() {
        let secrets = Secrets::new(PasswordStore::Memory, "test");
        secrets.set(1, "old").unwrap();
        let before = secrets.generation(1);
        // the provider rotated the token while nothing else changed: kept
        assert!(secrets.set_unless_changed(1, "rotated", before).unwrap());
        assert_eq!(secrets.get(1).as_deref(), Some("rotated"));
        assert_eq!(secrets.generation(1), before, "a rotation is no new sign-in");
        // a new sign-in meanwhile: the refresh's token is dropped
        secrets.set(1, "signed in again").unwrap();
        assert!(!secrets.set_unless_changed(1, "rotated from old", before).unwrap());
        assert_eq!(secrets.get(1).as_deref(), Some("signed in again"));
    }

    /// The system's store keeps a password between runs, under the profile of the store. On Windows always (the
    /// Credential Manager of the test user); on the Mac and Linux only with PE_KEYRING_TESTS=1, as it writes to the
    /// keychain or the keyring of whoever runs it, which may ask them first
    #[cfg(any(windows, target_os = "macos", target_os = "linux"))]
    #[test]
    fn system_store() {
        if !cfg!(windows) && std::env::var_os("PE_KEYRING_TESTS").is_none() {
            eprintln!("skipping: set PE_KEYRING_TESTS=1 to use the keychain or the keyring");
            return;
        }
        let profile = format!("test-{}", std::process::id());
        let first = Secrets::new(PasswordStore::System, &profile);
        if let Err(error) = first.set(7, "kept between runs") {
            // a session without a credential vault (SSH, a service): nothing to test here
            assert!(error.contains("NO_SUCH_LOGON_SESSION"), "{error}");
            eprintln!("skipping: {error}");
            return;
        }
        // a later run of the same store
        let second = Secrets::new(PasswordStore::System, &profile);
        assert_eq!(second.get(7).as_deref(), Some("kept between runs"));
        // another store does not see it
        assert_eq!(Secrets::new(PasswordStore::System, "another-profile").get(7), None);
        second.set(Key::App(7), "app secret").unwrap();
        assert_eq!(
            Secrets::new(PasswordStore::System, &profile).get(7).as_deref(),
            Some("kept between runs")
        );
        assert_eq!(
            Secrets::new(PasswordStore::System, &profile)
                .get(Key::App(7))
                .as_deref(),
            Some("app secret")
        );
        // the master key of the OpenPGP keys is a credential of its own
        second.set(Key::Pgp, "master").unwrap();
        assert_eq!(
            Secrets::new(PasswordStore::System, &profile).get(Key::Pgp).as_deref(),
            Some("master")
        );
        assert_eq!(
            Secrets::new(PasswordStore::System, &profile).get(7).as_deref(),
            Some("kept between runs")
        );
        second.remove(Key::Pgp);
        assert_eq!(Secrets::new(PasswordStore::System, &profile).get(Key::Pgp), None);
        second.remove(7);
        second.remove(Key::App(7));
        assert_eq!(Secrets::new(PasswordStore::System, &profile).get(7), None);
        assert_eq!(Secrets::new(PasswordStore::System, &profile).get(Key::App(7)), None);
    }
}
