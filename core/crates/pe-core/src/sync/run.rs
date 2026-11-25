//! Settings sync as the windows use it: turned on with a place and the passphrase (a new vault, or one another
//! computer made), run every few minutes and on Sync Now, turned off. The network work runs on the core's runtime;
//! the store work runs when the window answers [`Event::SettingsSyncReady`] with [`Core::settings_sync_continue`],
//! on the window's thread like every other change of the store.

use std::path::PathBuf;
use std::sync::{Arc, Mutex};
use std::time::Duration;

use serde::{Deserialize, Serialize};
use zeroize::Zeroizing;

use super::backend::{Folder, Place};
use super::crypt::VaultKey;
use super::engine::{self, Fetched, Me, Outcome};
use super::items::{Choice, KINDS, TRUSTED};
use super::s3::S3;
use super::stamp::Clock;
use super::vault::{self, Vault};
use crate::secrets::Key;
use crate::{Core, Event, Result};

/// How often a computer syncs by itself
const EVERY: Duration = Duration::from_secs(5 * 60);

/// Where the vault is
#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
#[serde(tag = "kind", rename_all = "lowercase")]
pub enum PlaceSetup {
    /// A folder a sync client copies
    Folder { path: String },
    /// An S3-compatible bucket; its secret access key is in the system's password store
    Bucket {
        endpoint: String,
        region: String,
        bucket: String,
        #[serde(default)]
        prefix: String,
        access_key: String,
    },
}

impl PlaceSetup {
    /// The place opened with the bucket's secret as the password store keeps it
    pub(super) fn opened(&self, secret: &Option<Zeroizing<String>>) -> Box<dyn Place> {
        self.open(secret.as_deref().map(|s| s.as_str()))
    }

    pub(super) fn open(&self, secret: Option<&str>) -> Box<dyn Place> {
        match self {
            PlaceSetup::Folder { path } => Box::new(Folder::new(&PathBuf::from(path))),
            PlaceSetup::Bucket {
                endpoint,
                region,
                bucket,
                prefix,
                access_key,
            } => Box::new(S3 {
                endpoint: endpoint.clone(),
                region: region.clone(),
                bucket: bucket.clone(),
                prefix: prefix.clone(),
                access_key: access_key.clone(),
                secret_key: secret.unwrap_or_default().to_string(),
                path_style: true,
            }),
        }
    }

    /// In words, for the Sync settings: the folder's path, or the bucket and its host
    pub fn label(&self) -> String {
        match self {
            PlaceSetup::Folder { path } => path.clone(),
            PlaceSetup::Bucket {
                endpoint,
                bucket,
                prefix,
                ..
            } => {
                let host = endpoint.trim_start_matches("https://").trim_start_matches("http://");
                let folder = if prefix.is_empty() {
                    String::new()
                } else {
                    format!("/{prefix}")
                };
                format!("{bucket}{folder} ({host})")
            }
        }
    }
}

/// How sync is set up on this computer, kept in the store
#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct Setup {
    pub place: PlaceSetup,
    pub vault: String,
    /// This computer's id in the vault, and its name there
    pub device: String,
    pub name: String,
    pub choice: Choice,
}

impl Setup {
    /// The vault in `place`, opened with `key`
    pub(super) fn vault<'a>(&self, place: &'a dyn Place, key: VaultKey) -> Vault<'a> {
        Vault {
            place,
            id: self.vault.clone(),
            key,
        }
    }
}

/// What the Sync settings show
#[derive(Debug, Clone, PartialEq, Eq, Default)]
pub struct SyncState {
    pub on: bool,
    pub place: String,
    pub name: String,
    pub choice: Option<Choice>,
    /// A sync is under way
    pub busy: bool,
    /// When the last sync finished, milliseconds since 1970, 0 for never
    pub last: u64,
    /// Why the last sync failed, empty when it did not
    pub problem: String,
}

/// What a sync brought that the window acts on: the app preferences to apply, the accounts removed (for the notice)
#[derive(Debug, Clone, PartialEq, Eq, Default)]
pub struct SyncNews {
    pub prefs: Vec<(String, String)>,
    pub removed_accounts: Vec<String>,
    pub lost: usize,
}

impl SyncNews {
    /// What to tell the user, empty for nothing: accounts another computer removed, edits of this one that lost
    pub fn notice(&self) -> String {
        let mut lines = Vec::new();
        if !self.removed_accounts.is_empty() {
            let names = crate::text::word_list(&self.removed_accounts);
            lines.push(pe_i18n::tr_args(
                pe_i18n::Text::SyncNewsRemoved,
                &[
                    ("accounts", (&names).into()),
                    ("count", self.removed_accounts.len().into()),
                ],
            ));
        }
        if self.lost > 0 {
            lines.push(pe_i18n::tr_args(
                pe_i18n::Text::SyncNewsLost,
                &[("count", self.lost.into())],
            ));
        }
        lines.join(" ")
    }
}

/// What a place holds, for the setup window: a vault to join, nothing yet, or a problem in words
#[derive(Debug, Clone, PartialEq, Eq)]
pub enum Probe {
    Empty,
    Vault,
    Problem(String),
}

/// The state of settings sync while the core is open
#[derive(Default)]
pub(crate) struct Runner {
    pub(super) inner: Arc<Mutex<Inner>>,
    clock: Mutex<Option<Arc<Clock>>>,
    wake: Arc<tokio::sync::Notify>,
    /// What the Computers window lists, None while it is read
    pub(super) computers: Arc<Mutex<Option<Vec<super::manage::Computer>>>>,
}

#[derive(Default)]
pub(super) struct Inner {
    busy: bool,
    last: u64,
    problem: String,
    fetched: Option<Fetched>,
    pub(super) news: SyncNews,
    probe: Option<Probe>,
    /// Bumped when sync is turned off or on again, so a loop of an earlier setup ends
    generation: u64,
}

/// A lock of the runner's state, taken even when a thread that held it panicked
pub(super) fn lock<T>(held: &Mutex<T>) -> std::sync::MutexGuard<'_, T> {
    held.lock().unwrap_or_else(|e| e.into_inner())
}

impl Core {
    fn sync_setup_now(&self) -> Option<Setup> {
        let text = self.store().sync_setup().ok()??;
        serde_json::from_str(&text).ok()
    }

    /// The setup, the vault key and the bucket's secret, for work on the runtime; None while sync is off
    pub(super) fn sync_opened(&self) -> Option<(Setup, VaultKey, Option<Zeroizing<String>>)> {
        let setup = self.sync_setup_now()?;
        let key = self.vault_key()?;
        Some((setup, key, self.secrets.get(Key::SyncBucket).map(Zeroizing::new)))
    }

    fn vault_key(&self) -> Option<VaultKey> {
        use base64::Engine;
        let text = Zeroizing::new(self.secrets.get(Key::Vault)?);
        let bytes = Zeroizing::new(base64::engine::general_purpose::STANDARD.decode(text.as_bytes()).ok()?);
        Some(Zeroizing::new(bytes.as_slice().try_into().ok()?))
    }

    fn sync_clock(&self, device: &str) -> Arc<Clock> {
        let mut clock = lock(&self.sync.clock);
        clock.get_or_insert_with(|| Arc::new(Clock::new(device))).clone()
    }

    /// What the Sync settings show now
    pub fn settings_sync_state(&self) -> SyncState {
        let inner = lock(&self.sync.inner);
        match self.sync_setup_now() {
            None => SyncState::default(),
            Some(setup) => SyncState {
                on: true,
                place: setup.place.label(),
                name: setup.name,
                choice: Some(setup.choice),
                busy: inner.busy,
                last: inner.last,
                problem: inner.problem.clone(),
            },
        }
    }

    /// What a place holds, looked at on the runtime; [`Event::SettingsSyncChanged`] when [`Core::settings_sync_probe`]
    /// has the answer
    pub fn settings_sync_probe_start(&self, place: PlaceSetup, secret: Option<String>) -> Result<()> {
        let inner = self.sync.inner.clone();
        let events = self.events.clone();
        lock(&inner).probe = None;
        self.runtime()?.spawn_blocking(move || {
            let opened = place.open(secret.as_deref());
            let probe = match vault::read_vault_file(opened.as_ref()) {
                Ok(Some(_)) => Probe::Vault,
                Ok(None) => match opened.list("") {
                    Ok(_) => Probe::Empty,
                    Err(e) => Probe::Problem(e.to_string()),
                },
                Err(e) => Probe::Problem(e.to_string()),
            };
            lock(&inner).probe = Some(probe);
            events(Event::SettingsSyncChanged);
        });
        Ok(())
    }

    /// The answer of the last probe, None while it runs
    pub fn settings_sync_probe(&self) -> Option<Probe> {
        lock(&self.sync.inner).probe.clone()
    }

    /// Sync turned on: a new vault in an empty place, or the vault there opened with `passphrase`. Runs on this
    /// thread (it reads one small file, or writes one), the first sync then starts by itself. Err in words: a wrong
    /// passphrase, a place that can not be reached.
    pub fn settings_sync_turn_on(
        &self,
        place: PlaceSetup,
        secret: Option<&str>,
        passphrase: &str,
        name: &str,
        choice: Choice,
    ) -> std::result::Result<(), String> {
        let opened = place.open(secret);
        let (vault_id, key) = match vault::read_vault_file(opened.as_ref()).map_err(|e| e.to_string())? {
            Some(file) => {
                let key = vault::open_key(&file, passphrase)
                    .ok_or_else(|| pe_i18n::tr(pe_i18n::Text::SyncWrongPassphrase))?;
                (file.vault, key)
            }
            None => vault::create_vault(opened.as_ref(), passphrase).map_err(|e| e.to_string())?,
        };
        use base64::Engine;
        let encoded = Zeroizing::new(base64::engine::general_purpose::STANDARD.encode(key.as_ref()));
        self.secrets.set(Key::Vault, &encoded)?;
        if let (PlaceSetup::Bucket { .. }, Some(secret)) = (&place, secret) {
            self.secrets.set(Key::SyncBucket, secret)?;
        }
        let device = super::crypt::new_id().ok_or("no random numbers")?;
        let setup = Setup {
            place,
            vault: vault_id,
            device,
            name: name.trim().to_string(),
            choice,
        };
        let text = serde_json::to_string(&setup).map_err(|e| e.to_string())?;
        let store = self.store();
        store.forget_sync().map_err(|e| e.to_string())?;
        store.set_sync_setup(Some(&text)).map_err(|e| e.to_string())?;
        drop(store);
        *lock(&self.sync.clock) = None;
        self.settings_sync_start().map_err(|e| e.to_string())?;
        Ok(())
    }

    /// Sync turned off here: the vault and the other computers stay as they are, this one forgets the vault
    pub fn settings_sync_turn_off(&self) -> Result<()> {
        let store = self.store();
        store.set_sync_setup(None)?;
        store.forget_sync()?;
        drop(store);
        self.secrets.remove(Key::Vault);
        self.secrets.remove(Key::SyncBucket);
        let mut inner = lock(&self.sync.inner);
        inner.generation += 1;
        inner.fetched = None;
        inner.problem.clear();
        inner.last = 0;
        drop(inner);
        (self.events)(Event::SettingsSyncChanged);
        Ok(())
    }

    /// What each computer syncs changed
    pub fn settings_sync_set_choice(&self, choice: Choice) -> Result<()> {
        let Some(mut setup) = self.sync_setup_now() else {
            return Ok(());
        };
        let more = KINDS
            .iter()
            .chain(&[TRUSTED])
            .any(|kind| !setup.choice.takes(kind) && choice.takes(kind));
        setup.choice = choice;
        let text = serde_json::to_string(&setup).unwrap_or_default();
        let store = self.store();
        store.set_sync_setup(Some(&text))?;
        // a kind taken again: everything read again, so what came meanwhile is applied
        if more {
            for (device, _) in store.sync_devices()? {
                store.reset_sync_device_seq(&device)?;
            }
        }
        drop(store);
        self.settings_sync_now();
        Ok(())
    }

    /// The loop that syncs every few minutes and on [`Core::settings_sync_now`], started when the core opens with
    /// sync on and when it is turned on
    pub fn settings_sync_start(&self) -> Result<()> {
        let Some(setup) = self.sync_setup_now() else {
            return Ok(());
        };
        let Some(key) = self.vault_key() else {
            lock(&self.sync.inner).problem = pe_i18n::tr(pe_i18n::Text::SyncNoKey);
            return Ok(());
        };
        let secret = self.secrets.get(Key::SyncBucket).map(Zeroizing::new);
        let (read_before, mine) = self.sync_progress(&setup.device).map_err(|_| crate::Error::Closed)?;
        let inner = self.sync.inner.clone();
        let wake = self.sync.wake.clone();
        let events = self.events.clone();
        let path = self.path.clone();
        let generation = {
            let mut held = lock(&inner);
            held.generation += 1;
            held.generation
        };
        self.runtime()?.spawn(async move {
            let mut progress = (read_before, mine);
            loop {
                if lock(&inner).generation != generation {
                    return;
                }
                let this = setup.clone();
                let key = key.clone();
                let secret = secret.clone();
                let before = progress.clone();
                let fetched = tokio::task::spawn_blocking(move || {
                    let place = this.place.opened(&secret);
                    let vault = this.vault(place.as_ref(), key);
                    engine::fetch(&vault, &this.device, &before.0, before.1)
                })
                .await;
                {
                    let mut held = lock(&inner);
                    if held.generation != generation {
                        return;
                    }
                    match fetched {
                        Ok(Ok(fetched)) => {
                            held.busy = true;
                            held.fetched = Some(fetched);
                            drop(held);
                            events(Event::SettingsSyncReady);
                        }
                        Ok(Err(e)) => {
                            held.problem = e.to_string();
                            drop(held);
                            events(Event::SettingsSyncChanged);
                        }
                        Err(_) => return,
                    }
                }
                let _ = tokio::time::timeout(EVERY, wake.notified()).await;
                // how far the last run read, from the store as the window left it
                if let Ok(store) = pe_store::Store::open(&path)
                    && let (Ok(devices), Ok(seq)) = (store.sync_devices(), store.sync_device_seq(&setup.device))
                {
                    progress = (devices, seq);
                }
            }
        });
        Ok(())
    }

    /// Sync now (Sync Now, a change of what is synced): the loop wakes
    pub fn settings_sync_now(&self) {
        self.sync.wake.notify_one();
    }

    /// The window's answer to [`Event::SettingsSyncReady`]: what the others wrote applied here, and what changed here
    /// written to the vault on the runtime. `prefs` are the app preferences now.
    pub fn settings_sync_continue(&self, prefs: &[(String, String)]) -> Result<()> {
        let Some(fetched) = lock(&self.sync.inner).fetched.take() else {
            return Ok(());
        };
        let Some(setup) = self.sync_setup_now() else {
            return Ok(());
        };
        let Some(key) = self.vault_key() else { return Ok(()) };
        let clock = self.sync_clock(&setup.device);
        let me = Me {
            device: &setup.device,
            name: &setup.name,
            clock: &clock,
            choice: setup.choice,
        };
        let merged = self.sync_merge(fetched, &me, prefs);
        let (outcome, pending) = match merged {
            Ok(merged) => merged,
            Err(e) => {
                let mut inner = lock(&self.sync.inner);
                inner.busy = false;
                inner.problem = e.to_string();
                drop(inner);
                (self.events)(Event::SettingsSyncChanged);
                return Ok(());
            }
        };
        self.sync_news(&outcome);
        self.sync_announce(&outcome);
        let inner = self.sync.inner.clone();
        let events = self.events.clone();
        let path = self.path.clone();
        let secret = self.secrets.get(Key::SyncBucket).map(Zeroizing::new);
        self.runtime()?.spawn_blocking(move || {
            let place = setup.place.opened(&secret);
            let vault = setup.vault(place.as_ref(), key);
            let written = engine::write(&vault, &setup.device, &pending).and_then(|fold| {
                if fold {
                    engine::fold(&vault, &setup.device, &setup.name)?;
                }
                Ok(())
            });
            let mut held = lock(&inner);
            held.busy = false;
            match written {
                Ok(()) => {
                    // the batch is there: its fields synced, on a store connection of this thread
                    if let Ok(mut store) = pe_store::Store::open(&path) {
                        let _ = engine::record_written(&mut store, &pending);
                    }
                    held.problem.clear();
                    held.last = super::stamp::now_millis();
                }
                Err(e) => held.problem = e.to_string(),
            }
            drop(held);
            events(Event::SettingsSyncChanged);
        });
        Ok(())
    }

    /// The windows told what the others changed here
    fn sync_announce(&self, outcome: &Outcome) {
        let has = |kinds: &[&str]| kinds.iter().any(|kind| outcome.kinds.contains(*kind));
        if has(&["account", "secret", "app", "app-secret", "builtin"]) {
            (self.events)(Event::AccountsChanged);
            (self.events)(Event::ListsChanged);
        }
        if has(&["setting", "rule", TRUSTED]) {
            (self.events)(Event::SettingsChanged);
        }
        if has(&["card", "group"]) {
            (self.events)(Event::AddressBookChanged);
        }
        if has(&["key", "own-key"]) {
            (self.events)(Event::KeysChanged);
        }
    }

    fn sync_news(&self, outcome: &Outcome) {
        if outcome.prefs.is_empty() && outcome.removed_accounts.is_empty() && outcome.lost == 0 {
            return;
        }
        let mut inner = lock(&self.sync.inner);
        inner.news.prefs.extend(outcome.prefs.iter().cloned());
        inner
            .news
            .removed_accounts
            .extend(outcome.removed_accounts.iter().cloned());
        inner.news.lost += outcome.lost;
    }

    /// What the last syncs brought for the window, taken (each once)
    pub fn settings_sync_news(&self) -> SyncNews {
        std::mem::take(&mut lock(&self.sync.inner).news)
    }
}
