//! What the Sync settings show and do besides syncing: the status in words, the computers of the vault (and taking
//! one away), and the history of edits that lost to a later one, with Restore.

use std::collections::BTreeMap;

use pe_i18n::{Text, tr, tr_args};
use serde_json::Value;

use super::items::Choice;
use super::run::SyncState;
use super::run::lock;
use crate::secrets::Key;
use crate::{Core, Event, Result};

/// A computer of the vault, as the Computers window lists it
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct Computer {
    /// Its id in the vault, what Remove takes
    pub device: String,
    pub name: String,
    /// When it last synced, in words
    pub seen: String,
    /// This computer
    pub this: bool,
}

/// An edit that lost, as the History window lists it
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct HistoryRow {
    pub id: i64,
    /// When it was put aside, in words
    pub when: String,
    /// What it was an edit of: "Contact Ann Lee", "Account Work", "Settings"
    pub item: String,
    /// The value it would have set, shortened, in quotes; empty for a value that is not text
    pub value: String,
    /// The computer it came from
    pub source: String,
}

/// A restore point, as History lists it
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct RestorePoint {
    /// What [`Core::settings_sync_restore_point`] takes
    pub path: std::path::PathBuf,
    /// When it was made, in words
    pub when: String,
}

/// The restore points kept
const RESTORE_POINTS: usize = 5;

/// The longest value the history shows
const VALUE_SHOWN: usize = 80;

fn kind_words(kind: &str, label: &str) -> String {
    let text = match kind {
        "account" | "secret" => Text::SyncItemAccount,
        "card" => Text::SyncItemContact,
        "group" => Text::SyncItemGroup,
        "key" | "own-key" => Text::SyncItemKey,
        "rule" => Text::SyncItemRule,
        "trusted" => Text::SyncItemTrusted,
        "app" | "app-secret" | "builtin" => Text::SyncItemSignInApp,
        "pref" | "setting" => return tr(Text::SyncItemSettings),
        _ => return label.to_string(),
    };
    tr_args(text, &[("name", label.into())])
}

/// Where it syncs through and as what computer, one line
pub fn place_words(state: &SyncState) -> String {
    if !state.on {
        return String::new();
    }
    tr_args(
        Text::SyncPlace,
        &[("place", (&state.place).into()), ("name", (&state.name).into())],
    )
}

/// When something synced, short: "today at 11:58", else the day
fn synced_when(millis: u64) -> String {
    let at = (millis / 1000) as i64;
    let now = crate::worker::unix_now();
    if crate::calendar::local_date(at) == crate::calendar::local_date(now) {
        let time = crate::calendar::local_time(at);
        return tr_args(Text::SyncWhenToday, &[("time", (&time).into())]);
    }
    crate::calendar::local_date(at)
}

/// The sync status in words, one line: under way, the problem, or when it last synced
pub fn status_words(state: &SyncState) -> String {
    if !state.on {
        return String::new();
    }
    if state.busy {
        return tr(Text::SyncStatusBusy);
    }
    if !state.problem.is_empty() {
        let problem = crate::text::sentence(&state.problem);
        return tr_args(Text::SyncStatusProblem, &[("problem", (&problem).into())]);
    }
    if state.last == 0 {
        return tr(Text::SyncStatusNever);
    }
    let last = (state.last / 1000) as i64;
    let now = crate::worker::unix_now();
    if crate::calendar::local_date(last) == crate::calendar::local_date(now) {
        let time = crate::calendar::local_time(last);
        return tr_args(Text::SyncStatusToday, &[("time", (&time).into())]);
    }
    let when = crate::calendar::local_date_time(last);
    tr_args(Text::SyncStatusLast, &[("when", (&when).into())])
}

impl Core {
    fn restore_points_dir(&self) -> std::path::PathBuf {
        self.path.with_file_name("restore-points")
    }

    /// How things are now saved as a restore point, before a sync takes something away: a setup file of every part,
    /// sealed with a passphrase of its own kept in the system's password store. The oldest go past
    /// [`RESTORE_POINTS`].
    pub(crate) fn sync_restore_point(&self, prefs: &[(String, String)]) -> Result<()> {
        let passphrase = match self.secrets.get(Key::RestorePoints) {
            Some(kept) => zeroize::Zeroizing::new(kept),
            None => {
                let made = zeroize::Zeroizing::new(super::crypt::new_id().unwrap_or_default());
                self.secrets
                    .set(Key::RestorePoints, &made)
                    .map_err(crate::Error::Invalid)?;
                made
            }
        };
        let dir = self.restore_points_dir();
        std::fs::create_dir_all(&dir).map_err(|e| crate::Error::Invalid(e.to_string()))?;
        let path = dir.join(format!("{}.inboxclassic", super::stamp::now_millis()));
        self.export_setup(&path, crate::setup::Parts::ALL, Some(&passphrase), prefs)?;
        let mut kept = self.settings_sync_restore_points();
        while kept.len() > RESTORE_POINTS {
            if let Some(oldest) = kept.pop() {
                let _ = std::fs::remove_file(oldest.path);
            }
        }
        Ok(())
    }

    /// The restore points, newest first
    pub fn settings_sync_restore_points(&self) -> Vec<RestorePoint> {
        let Ok(read) = std::fs::read_dir(self.restore_points_dir()) else {
            return Vec::new();
        };
        let mut points: Vec<(u64, std::path::PathBuf)> = read
            .filter_map(|entry| entry.ok())
            .filter_map(|entry| {
                let path = entry.path();
                let millis = path.file_stem()?.to_str()?.parse().ok()?;
                Some((millis, path))
            })
            .collect();
        points.sort_by_key(|p| std::cmp::Reverse(p.0));
        points
            .into_iter()
            .map(|(millis, path)| RestorePoint {
                path,
                when: crate::calendar::local_date_time((millis / 1000) as i64),
            })
            .collect()
    }

    /// A restore point read, for the Import window to show and import what the user chooses of it
    pub fn settings_sync_restore_point(
        &self,
        path: &std::path::Path,
    ) -> std::result::Result<crate::setup::SetupFile, crate::setup::SetupError> {
        // only one of the points listed: their passphrase opens nothing else
        if !self
            .settings_sync_restore_points()
            .iter()
            .any(|point| point.path == path)
        {
            return Err(crate::setup::SetupError::Invalid(pe_i18n::tr(Text::SetupErrorNotSetup)));
        }
        let passphrase = self.secrets.get(Key::RestorePoints).map(zeroize::Zeroizing::new);
        self.read_setup(path, passphrase.as_deref().map(|p| p.as_str()))
    }

    /// The computers of the vault, read on the runtime: [`Event::SettingsSyncChanged`] when
    /// [`Core::settings_sync_computers`] has them
    pub fn settings_sync_computers_start(&self) -> Result<()> {
        let Some((setup, key, secret)) = self.sync_opened() else {
            return Ok(());
        };
        let found = self.sync.computers.clone();
        let events = self.events.clone();
        *lock(&found) = None;
        self.runtime()?.spawn_blocking(move || {
            let place = setup.place.opened(&secret);
            let vault = setup.vault(place.as_ref(), key);
            let mut computers = Vec::new();
            for device in vault.devices().unwrap_or_default() {
                let Ok(Some(about)) = vault.read_about(&device) else {
                    continue;
                };
                computers.push((device, about));
            }
            computers.sort_by_key(|c| std::cmp::Reverse(c.1.seen));
            let rows = computers
                .into_iter()
                .map(|(device, about)| Computer {
                    this: device == setup.device,
                    device,
                    name: about.name,
                    seen: synced_when(about.seen),
                })
                .collect();
            *lock(&found) = Some(rows);
            events(Event::SettingsSyncChanged);
        });
        Ok(())
    }

    /// The computers [`Core::settings_sync_computers_start`] read, None while it reads
    pub fn settings_sync_computers(&self) -> Option<Vec<Computer>> {
        lock(&self.sync.computers).clone()
    }

    /// A computer taken out of the vault (one that is lost or given away), under the lock: its changes stay in the
    /// snapshot, and it stops syncing the next time it tries. The list is read again after.
    pub fn settings_sync_remove_computer(&self, device: &str) -> Result<()> {
        let Some((setup, key, secret)) = self.sync_opened() else {
            return Ok(());
        };
        if device == setup.device {
            return Ok(());
        }
        let device = device.to_string();
        let events = self.events.clone();
        let found = self.sync.computers.clone();
        self.runtime()?.spawn_blocking(move || {
            let place = setup.place.opened(&secret);
            let vault = setup.vault(place.as_ref(), key);
            // what it wrote folded in first, so nothing of it is lost
            if super::engine::fold(&vault, &setup.device, &setup.name).unwrap_or(false) {
                let _ = super::engine::remove_device(&vault, &setup.device, &setup.name, &device);
            }
            if let Some(list) = lock(&found).as_mut() {
                list.retain(|c| c.device != device);
            }
            events(Event::SettingsSyncChanged);
        });
        Ok(())
    }

    /// The edits that lost to a later one, newest first
    pub fn settings_sync_history(&self) -> Result<Vec<HistoryRow>> {
        Ok(self
            .store()
            .lost_edits()?
            .into_iter()
            .map(|edit| {
                let value = match serde_json::from_str::<Value>(&edit.value) {
                    // never shown, should an older store hold one
                    _ if super::engine::is_secret(&edit.kind) => String::new(),
                    Ok(Value::String(text)) => {
                        let shown = crate::snippet::head(&text, VALUE_SHOWN);
                        let more = if shown.len() < text.len() { "…" } else { "" };
                        format!("“{shown}{more}”")
                    }
                    _ => String::new(),
                };
                HistoryRow {
                    id: edit.id,
                    when: crate::calendar::local_date_time(edit.at),
                    item: kind_words(&edit.kind, &edit.label),
                    value,
                    source: edit.source,
                }
            })
            .collect())
    }

    /// An edit of the history put back: it is made here again as a new edit, so the next sync takes it to the other
    /// computers. An app preference comes back as news for the window. False when its item is no longer here.
    pub fn settings_sync_restore(&self, id: i64, prefs: &[(String, String)]) -> Result<bool> {
        let Some(edit) = self.store().take_lost_edit(id)? else {
            return Ok(false);
        };
        let Ok(value) = serde_json::from_str::<Value>(&edit.value) else {
            return Ok(false);
        };
        if edit.kind == "pref" {
            if let Value::String(text) = value {
                let mut inner = lock(&self.sync.inner);
                inner.news.prefs.push((edit.field, text));
                drop(inner);
                (self.events)(Event::SettingsSyncChanged);
                return Ok(true);
            }
            return Ok(false);
        }
        let Some(natural) = self.store().sync_local(&edit.kind, &edit.item)? else {
            return Ok(false);
        };
        let items = self.sync_snapshot(&Choice::default(), prefs)?;
        let Some(item) = items.iter().find(|i| i.kind == edit.kind && i.natural == natural) else {
            return Ok(false);
        };
        let mut fields: BTreeMap<String, Value> = item.fields.clone();
        fields.insert(edit.field, value);
        let restored = self.sync_update(&edit.kind, &natural, &fields)?;
        self.settings_sync_now();
        Ok(restored)
    }
}
