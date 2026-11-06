//! The passwords of the accounts (and the client secrets of sign-in apps): kept in memory while the app runs, and in
//! the system's password store between runs (the Credential Manager, the keychain, the Secret Service), so the user gives a password once. The credentials are named
//! after the store's profile ID and the account or app, so two stores on one machine (the app's, a test's) never
//! share one.

use std::collections::{HashMap, HashSet};
use std::sync::{Arc, Mutex, MutexGuard};

use pe_store::{AccountId, SignInAppId};

/// Whose secret: an account's password or refresh token, or a sign-in app's client secret
#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash)]
pub(crate) enum Key {
    Account(AccountId),
    App(SignInAppId),
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
trait Backend: Send + Sync {
    fn load(&self, key: Key) -> Option<String>;
    fn save(&self, key: Key, password: &str) -> Result<(), String>;
    fn remove(&self, key: Key);
}

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

    /// What the store is called in messages to the user
    fn name() -> String {
        use pe_i18n::{Text, tr};
        if cfg!(windows) {
            tr(Text::SecretsWindows)
        } else if cfg!(target_os = "macos") {
            tr(Text::SecretsMac)
        } else {
            tr(Text::SecretsLinux)
        }
    }

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

        fn entry(&self, key: Key) -> Option<keyring_core::Entry> {
            let name = match key {
                Key::Account(account) => format!("{}/{account}", self.profile),
                Key::App(app) => format!("{}/app/{app}", self.profile),
            };
            self.store.build("InboxClassic", &name, None).ok()
        }
    }

    impl super::Backend for NativeStore {
        fn load(&self, key: Key) -> Option<String> {
            self.entry(key)?.get_password().ok()
        }

        fn save(&self, key: Key, password: &str) -> Result<(), String> {
            let entry = self
                .entry(key)
                .ok_or_else(|| pe_i18n::tr_args(pe_i18n::Text::SecretsUnavailable, &[("store", (&name()).into())]))?;
            entry.set_password(password).map_err(|e| e.to_string())
        }

        fn remove(&self, key: Key) {
            if let Some(entry) = self.entry(key) {
                let _ = entry.delete_credential();
            }
        }
    }
}

#[derive(Default)]
struct SecretMap {
    passwords: HashMap<Key, String>,
    /// Accounts whose password was refused and reported: reported once until a new one is set
    refused: HashSet<AccountId>,
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
        let key = key.into();
        if let Some(password) = self.map().passwords.get(&key) {
            return Some(password.clone());
        }
        let password = self.backend.as_ref()?.load(key)?;
        // a password set while this one was loaded is the newer one
        Some(self.map().passwords.entry(key).or_insert(password).clone())
    }

    /// Keeps the password for this run, and between runs where the system has a place for it; the error says
    /// why it could not be kept between runs
    pub(crate) fn set(&self, key: impl Into<Key>, password: &str) -> Result<(), String> {
        let key = key.into();
        {
            let mut map = self.map();
            map.passwords.insert(key, password.to_string());
            if let Key::Account(account) = key {
                map.refused.remove(&account);
            }
        }
        match (&self.backend, &self.unavailable) {
            (Some(backend), _) => backend.save(key, password),
            (None, Some(reason)) => Err(reason.clone()),
            (None, None) => Ok(()),
        }
    }

    pub(crate) fn remove(&self, key: impl Into<Key>) {
        let key = key.into();
        {
            let mut map = self.map();
            map.passwords.remove(&key);
            if let Key::Account(account) = key {
                map.refused.remove(&account);
            }
        }
        if let Some(backend) = &self.backend {
            backend.remove(key);
        }
    }

    /// Whether a refused password is news: true the first time after it was set
    pub(crate) fn first_refusal(&self, account: AccountId) -> bool {
        self.map().refused.insert(account)
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
        assert!(secrets.first_refusal(1));
        assert!(!secrets.first_refusal(1));
        secrets.set(1, "new").unwrap();
        assert!(secrets.first_refusal(1), "a new password can be refused again");
        secrets.remove(1);
        assert_eq!(secrets.get(1), None);
        // an app's secret is kept apart from the account of the same number
        secrets.set(Key::App(1), "client secret").unwrap();
        assert_eq!(secrets.get(1), None);
        assert_eq!(secrets.get(Key::App(1)).as_deref(), Some("client secret"));
        secrets.remove(Key::App(1));
        assert_eq!(secrets.get(Key::App(1)), None);
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
        second.remove(7);
        second.remove(Key::App(7));
        assert_eq!(Secrets::new(PasswordStore::System, &profile).get(7), None);
        assert_eq!(Secrets::new(PasswordStore::System, &profile).get(Key::App(7)), None);
    }
}
