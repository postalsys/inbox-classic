//! The passwords of the accounts: kept in memory while the app runs, and on Windows in the Credential Manager
//! between runs, so the user gives a password once. The credentials are named after the store's profile ID and
//! the account, so two stores on one machine (the app's, a test's) never share one.

use std::collections::{HashMap, HashSet};
use std::sync::{Arc, Mutex, MutexGuard};

use pe_store::AccountId;

/// Where passwords are kept between runs
#[derive(Debug, Clone, Copy, PartialEq, Eq, Default)]
pub enum PasswordStore {
    /// The Windows Credential Manager; memory only on other systems
    #[default]
    System,
    /// Memory only: the user gives them again on the next run (tests, a shared computer)
    Memory,
}

/// A place passwords outlive the process in
trait Backend: Send + Sync {
    fn load(&self, account: AccountId) -> Option<String>;
    fn save(&self, account: AccountId, password: &str) -> Result<(), String>;
    fn remove(&self, account: AccountId);
}

#[cfg(windows)]
mod windows {
    use std::sync::Arc;

    use keyring_core::api::CredentialStoreApi;
    use pe_store::AccountId;

    /// The Credential Manager, generic credentials named `PostalExpress` / `<profile>/<account>`
    pub(super) struct CredentialManager {
        store: Arc<windows_native_keyring_store::Store>,
        profile: String,
    }

    impl CredentialManager {
        pub(super) fn new(profile: String) -> Result<CredentialManager, String> {
            Ok(CredentialManager {
                store: windows_native_keyring_store::Store::new().map_err(|e| e.to_string())?,
                profile,
            })
        }

        fn entry(&self, account: AccountId) -> Option<keyring_core::Entry> {
            self.store
                .build("PostalExpress", &format!("{}/{account}", self.profile), None)
                .ok()
        }
    }

    impl super::Backend for CredentialManager {
        fn load(&self, account: AccountId) -> Option<String> {
            self.entry(account)?.get_password().ok()
        }

        fn save(&self, account: AccountId, password: &str) -> Result<(), String> {
            let entry = self.entry(account).ok_or("the Credential Manager is not available")?;
            entry.set_password(password).map_err(|e| e.to_string())
        }

        fn remove(&self, account: AccountId) {
            if let Some(entry) = self.entry(account) {
                let _ = entry.delete_credential();
            }
        }
    }
}

#[derive(Default)]
struct SecretMap {
    passwords: HashMap<AccountId, String>,
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
        #[cfg(windows)]
        let (backend, unavailable): (Option<Arc<dyn Backend>>, _) = match kind {
            PasswordStore::System => match windows::CredentialManager::new(profile.to_string()) {
                Ok(backend) => (Some(Arc::new(backend)), None),
                Err(error) => (None, Some(error)),
            },
            PasswordStore::Memory => (None, None),
        };
        #[cfg(not(windows))]
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

    pub(crate) fn get(&self, account: AccountId) -> Option<String> {
        if let Some(password) = self.map().passwords.get(&account) {
            return Some(password.clone());
        }
        let password = self.backend.as_ref()?.load(account)?;
        // a password set while this one was loaded is the newer one
        Some(self.map().passwords.entry(account).or_insert(password).clone())
    }

    /// Keeps the password for this run, and between runs where the system has a place for it; the error says
    /// why it could not be kept between runs
    pub(crate) fn set(&self, account: AccountId, password: &str) -> Result<(), String> {
        {
            let mut map = self.map();
            map.passwords.insert(account, password.to_string());
            map.refused.remove(&account);
        }
        match (&self.backend, &self.unavailable) {
            (Some(backend), _) => backend.save(account, password),
            (None, Some(reason)) => Err(reason.clone()),
            (None, None) => Ok(()),
        }
    }

    pub(crate) fn remove(&self, account: AccountId) {
        {
            let mut map = self.map();
            map.passwords.remove(&account);
            map.refused.remove(&account);
        }
        if let Some(backend) = &self.backend {
            backend.remove(account);
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
    }

    /// The Credential Manager keeps a password between runs, under the profile of the store
    #[cfg(windows)]
    #[test]
    fn credential_manager() {
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
        second.remove(7);
        assert_eq!(Secrets::new(PasswordStore::System, &profile).get(7), None);
    }
}
