//! One sync: what the other computers changed read and applied, what changed here written as this computer's next
//! batch, and now and then the batches folded into the snapshot under the soft lock.
//!
//! The rules (docs/sync-plan.md):
//! - every field of every item has the stamp of its last change; the later stamp wins, on every computer the same
//! - a change found here gets a stamp from this computer's clock, which has seen every stamp read, so it comes after
//!   everything this computer knew of; when another computer changed the same field meanwhile, this one wins here and
//!   the other value is kept in the history (and the other computer, reading this batch, does the same the other way)
//! - a removal loses to an edit of the same item made meanwhile: the item stays and is written whole again
//! - the same thing added on two computers (the same natural key) is one item, named by the smaller of its two ids

use std::collections::{BTreeMap, BTreeSet, HashMap};

use pe_store::sync::{DELETED, LostEdit};
use serde_json::Value;

use super::backend::{PlaceError, PlaceResult};
use super::items::{Choice, Item, KINDS, TRUSTED};
use super::stamp::{Clock, Stamp, now_millis};
use super::vault::{About, Batch, Record, Snapshot, Vault};
use crate::Core;

/// Batches of one computer past which it folds them into the snapshot
const FOLD_AFTER: usize = 50;

/// Why a sync did not finish
#[derive(Debug)]
pub enum SyncError {
    Place(PlaceError),
    Core(crate::Error),
}

impl std::fmt::Display for SyncError {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        match self {
            SyncError::Place(e) => e.fmt(f),
            SyncError::Core(e) => e.fmt(f),
        }
    }
}

impl From<PlaceError> for SyncError {
    fn from(e: PlaceError) -> SyncError {
        SyncError::Place(e)
    }
}

impl From<crate::Error> for SyncError {
    fn from(e: crate::Error) -> SyncError {
        SyncError::Core(e)
    }
}

impl From<pe_store::Error> for SyncError {
    fn from(e: pe_store::Error) -> SyncError {
        SyncError::Core(e.into())
    }
}

/// What a sync did
#[derive(Debug, Default, Clone, PartialEq)]
pub struct Outcome {
    /// Fields taken from other computers
    pub applied: usize,
    /// Fields written for the others
    pub sent: usize,
    /// Edits of other computers replaced by one made here at the same time, kept in the history
    pub lost: usize,
    /// Accounts another computer removed, removed here too: their names, for the notice
    pub removed_accounts: Vec<String>,
    /// App preferences another computer changed, for the window to apply
    pub prefs: Vec<(String, String)>,
    /// Items that could not be applied (checked and refused), skipped
    pub skipped: usize,
    /// The kinds of item changed here, for the windows to show them again
    pub kinds: BTreeSet<String>,
}

/// This computer, as the vault knows it
pub struct Me<'a> {
    pub device: &'a str,
    pub name: &'a str,
    pub clock: &'a Clock,
    pub choice: Choice,
}

type FieldKey = (String, String, String);

/// The others' winning records, by item (kind, id)
type Wins = BTreeMap<(String, String), Vec<Record>>;

/// The changes made here, as this sync's records, each stamped by this computer's clock
struct Changes<'a> {
    me: &'a Me<'a>,
    now: u64,
    records: BTreeMap<FieldKey, Record>,
}

impl Changes<'_> {
    fn add(&mut self, item: &Item, id: &str, field: &str, value: Option<Value>) {
        let record = Record {
            kind: item.kind.into(),
            id: id.into(),
            natural: item.natural.clone(),
            label: item.label.clone(),
            field: field.into(),
            stamp: self.me.clock.tick(self.now).text(),
            value,
        };
        self.records.insert((item.kind.into(), id.into(), field.into()), record);
    }
}

fn hash(value: &Option<Value>) -> String {
    match value {
        None => String::new(),
        Some(value) => {
            let text = value.to_string();
            let digest = ring::digest::digest(&ring::digest::SHA256, text.as_bytes());
            digest.as_ref().iter().take(16).map(|b| format!("{b:02x}")).collect()
        }
    }
}

fn later(a: &str, b: &str) -> bool {
    match (Stamp::parse(a), Stamp::parse(b)) {
        (Some(a), Some(b)) => a > b,
        _ => a > b,
    }
}

/// The kinds whose values are secrets: they travel only sealed in the vault and are never kept anywhere else
pub(crate) fn is_secret(kind: &str) -> bool {
    matches!(kind, "secret" | "app-secret" | "own-key")
}

/// Records gathered: for each field the one with the latest stamp
#[derive(Default)]
struct Latest(BTreeMap<FieldKey, Record>);

impl Latest {
    fn add(&mut self, record: Record) {
        // only what a computer could have written: a kind sync knows, a stamp that reads
        if !(KINDS.contains(&record.kind.as_str()) || record.kind == TRUSTED) || Stamp::parse(&record.stamp).is_none() {
            return;
        }
        let key = (record.kind.clone(), record.id.clone(), record.field.clone());
        match self.0.get(&key) {
            Some(held) if !later(&record.stamp, &held.stamp) => {}
            _ => {
                self.0.insert(key, record);
            }
        }
    }
}

/// What the others wrote since this computer last read them, read off the window thread
pub struct Fetched {
    incoming: Latest,
    /// The names of the computers read from, by their id
    names: HashMap<String, String>,
    /// How far each computer's batches were read
    read_to: BTreeMap<String, u64>,
    /// This computer's last batch
    mine: u64,
}

/// What this computer writes after a merge: its next batch (perhaps empty) and its `about`
pub struct Pending {
    pub device: String,
    pub batch: Batch,
    pub seq: u64,
    pub about: About,
}

/// The batches of the others read: `read_before` how far each was read, `mine` this computer's last batch as the
/// store knows it
pub fn fetch(vault: &Vault<'_>, device: &str, read_before: &[(String, u64)], mine: u64) -> PlaceResult<Fetched> {
    if vault.place.read(&removed_name(device))?.is_some() {
        return Err(PlaceError::Refused(pe_i18n::tr(pe_i18n::Text::SyncRemovedHere)));
    }
    let before = |name: &str| read_before.iter().find(|(d, _)| d == name).map_or(0, |(_, seq)| *seq);
    let mut incoming = Latest::default();
    let mut read_to: BTreeMap<String, u64> = BTreeMap::new();
    if let Some(snapshot) = vault.read_snapshot()?
        && snapshot
            .covers
            .iter()
            .any(|(name, seq)| name != device && *seq > before(name))
    {
        for (name, seq) in &snapshot.covers {
            read_to.insert(name.clone(), *seq);
        }
        snapshot.records.into_iter().for_each(|r| incoming.add(r));
    }
    let mut names = HashMap::new();
    for name in vault.devices()?.into_iter().filter(|d| d != device) {
        let from = before(&name).max(read_to.get(&name).copied().unwrap_or(0));
        let batches: Vec<u64> = vault.batches(&name)?.into_iter().filter(|seq| *seq > from).collect();
        if !batches.is_empty()
            && let Ok(Some(about)) = vault.read_about(&name)
        {
            names.insert(name.clone(), about.name);
        }
        for seq in batches {
            if let Some(batch) = vault.read_batch(&name, seq)? {
                batch.records.into_iter().for_each(|r| incoming.add(r));
            }
            read_to.insert(name.clone(), seq);
        }
    }
    let mine = vault.batches(device)?.last().copied().unwrap_or(0).max(mine);
    Ok(Fetched {
        incoming,
        names,
        read_to,
        mine,
    })
}

/// This computer's batch and `about` written; true when its batches are many enough to fold
pub fn write(vault: &Vault<'_>, device: &str, pending: &Pending) -> PlaceResult<bool> {
    if !pending.batch.records.is_empty() {
        vault.write_batch(device, pending.seq, &pending.batch)?;
    }
    vault.write_about(device, &pending.about)?;
    Ok(vault.batches(device)?.len() > FOLD_AFTER)
}

impl Core {
    /// One sync with the vault, every step on this thread (the tests)
    #[cfg(test)]
    pub(crate) fn sync_once(
        &self,
        vault: &Vault<'_>,
        me: &Me<'_>,
        prefs: &[(String, String)],
    ) -> Result<Outcome, SyncError> {
        let (read_before, mine) = self.sync_progress(me.device)?;
        let fetched = fetch(vault, me.device, &read_before, mine)?;
        let (outcome, pending) = self.sync_merge(fetched, me, prefs)?;
        if write(vault, me.device, &pending)? {
            fold(vault, me.device, me.name)?;
        }
        self.sync_written(&pending)?;
        Ok(outcome)
    }

    /// How far this computer read each other one, and its own last batch, for [`fetch`]
    pub(crate) fn sync_progress(&self, device: &str) -> Result<(Vec<(String, u64)>, u64), SyncError> {
        let store = self.store();
        Ok((store.sync_devices()?, store.sync_device_seq(device)?))
    }

    /// What the others wrote applied here, and what changed here made into this computer's next batch: the work on
    /// the store, between [`fetch`] and [`write`]
    pub(crate) fn sync_merge(
        &self,
        fetched: Fetched,
        me: &Me<'_>,
        prefs: &[(String, String)],
    ) -> Result<(Outcome, Pending), SyncError> {
        let Fetched {
            incoming,
            names,
            read_to,
            mine,
        } = fetched;
        let known: HashMap<FieldKey, (String, String)> = self
            .store()
            .synced_fields()?
            .into_iter()
            .map(|f| ((f.kind, f.id, f.field), (f.stamp, f.hash)))
            .collect();
        let stamps = known
            .values()
            .map(|(stamp, _)| stamp)
            .chain(incoming.0.values().map(|r| &r.stamp));
        for stamp in stamps.filter_map(|s| Stamp::parse(s)) {
            me.clock.witness(&stamp);
        }
        let items = self.sync_snapshot(&me.choice, prefs)?;
        let ids = self.sync_ids_of(&items, &incoming)?;
        let mut changes = Changes {
            me,
            now: now_millis(),
            records: BTreeMap::new(),
        };
        self.local_changes(&items, &ids, &known, &mut changes)?;
        let mut outcome = Outcome::default();
        let (wins, resend) = self.resolve(&incoming, &known, &names, &mut changes, &mut outcome)?;
        // an item edited here that another computer removed: written whole again
        for (kind, id) in &resend {
            if let Some(item) = items
                .iter()
                .find(|i| i.kind == kind && ids[&(kind.clone(), i.natural.clone())] == *id)
            {
                for (field, value) in &item.fields {
                    changes.add(item, id, field, Some(value.clone()));
                }
            }
        }
        self.apply_wins(wins, &items, &incoming, prefs, &mut outcome)?;
        let store = self.store();
        for (device, seq) in &read_to {
            store.set_sync_device_seq(device, *seq)?;
        }
        drop(store);

        // this computer's changes, for its next batch
        outcome.sent = changes.records.len();
        let seq = mine + u64::from(!changes.records.is_empty());
        let pending = Pending {
            device: me.device.to_string(),
            batch: Batch {
                records: changes.records.into_values().collect(),
            },
            seq,
            about: About {
                name: me.name.to_string(),
                seen: changes.now,
                seq,
            },
        };
        Ok((outcome, pending))
    }

    /// Each item's sync id: its own, or, for the same thing added elsewhere, the smaller of the two, which then names
    /// both (written only when it changes)
    fn sync_ids_of(&self, items: &[Item], incoming: &Latest) -> Result<HashMap<(String, String), String>, SyncError> {
        let mut elsewhere: HashMap<(&str, &str), &str> = HashMap::new();
        for record in incoming.0.values() {
            let held = elsewhere
                .entry((record.kind.as_str(), record.natural.as_str()))
                .or_insert(&record.id);
            if record.id.as_str() < *held {
                *held = &record.id;
            }
        }
        let store = self.store();
        let mut ids = HashMap::new();
        for item in items {
            let local = store.sync_id(item.kind, &item.natural)?;
            let other = elsewhere
                .get(&(item.kind, item.natural.as_str()))
                .map(|id| id.to_string());
            let id = match (local.clone(), other) {
                (Some(local), Some(other)) => local.min(other),
                (Some(id), None) | (None, Some(id)) => id,
                (None, None) => {
                    super::crypt::new_id().ok_or(SyncError::Place(PlaceError::Failed("no random".into())))?
                }
            };
            if local.as_ref() != Some(&id) {
                store.set_sync_id(item.kind, &item.natural, &id)?;
            }
            ids.insert((item.kind.to_string(), item.natural.clone()), id);
        }
        Ok(ids)
    }

    /// What changed here since the last sync: fields whose value is not the one synced, fields of a set taken out,
    /// items synced before that are gone
    fn local_changes(
        &self,
        items: &[Item],
        ids: &HashMap<(String, String), String>,
        known: &HashMap<FieldKey, (String, String)>,
        changes: &mut Changes<'_>,
    ) -> Result<(), SyncError> {
        let mut fields_by_id: HashMap<(&str, &str), BTreeSet<&str>> = HashMap::new();
        for (key, _) in known.iter().filter(|(_, (_, h))| !h.is_empty()) {
            fields_by_id.entry((&key.0, &key.1)).or_default().insert(&key.2);
        }
        for item in items {
            let id = &ids[&(item.kind.to_string(), item.natural.clone())];
            for (field, value) in &item.fields {
                let value = Some(value.clone());
                let synced = known.get(&(item.kind.into(), id.clone(), field.clone()));
                if synced.is_none_or(|(_, h)| *h != hash(&value)) {
                    changes.add(item, id, field, value);
                }
            }
            let gone: Vec<&str> = fields_by_id
                .get(&(item.kind, id.as_str()))
                .into_iter()
                .flatten()
                .copied()
                .filter(|field| *field != DELETED && !item.fields.contains_key(*field))
                .collect();
            for field in gone {
                changes.add(item, id, field, None);
            }
        }
        let present: BTreeSet<(&str, &str)> = items.iter().map(|i| (i.kind, i.natural.as_str())).collect();
        let store = self.store();
        for kind in KINDS
            .iter()
            .chain([&TRUSTED])
            .filter(|kind| changes.me.choice.takes(kind))
        {
            for (natural, id) in store.sync_ids(kind)? {
                if present.contains(&(*kind, natural.as_str())) {
                    continue;
                }
                let gone = Item {
                    kind,
                    natural,
                    label: String::new(),
                    fields: BTreeMap::new(),
                };
                changes.add(&gone, &id, DELETED, Some(Value::Bool(true)));
            }
        }
        Ok(())
    }

    /// What wins of the others' records: per field the later stamp; the same value made on both is settled with
    /// nothing to do, a clash with a change made here keeps this one's and the other in the history, and a removal
    /// loses to an edit of the same item (which is sent whole again: the second set returned)
    fn resolve(
        &self,
        incoming: &Latest,
        known: &HashMap<FieldKey, (String, String)>,
        names: &HashMap<String, String>,
        changes: &mut Changes<'_>,
        outcome: &mut Outcome,
    ) -> Result<(Wins, BTreeSet<(String, String)>), SyncError> {
        let mut wins: Wins = BTreeMap::new();
        let changed_items: BTreeSet<(String, String)> =
            changes.records.keys().map(|(k, i, _)| (k.clone(), i.clone())).collect();
        let mut resend = BTreeSet::new();
        for (key, record) in &incoming.0 {
            if !changes.me.choice.takes(&record.kind)
                || known.get(key).is_some_and(|(stamp, _)| !later(&record.stamp, stamp))
            {
                continue;
            }
            let item = (record.kind.clone(), record.id.clone());
            if record.field == DELETED && changed_items.contains(&item) {
                resend.insert(item);
                continue;
            }
            match changes.records.get(key) {
                Some(mine) if mine.value == record.value => {
                    changes.records.remove(key);
                    self.store()
                        .set_synced_field(&key.0, &key.1, &key.2, &record.stamp, &hash(&record.value))?;
                }
                // a secret's other value is let go, never kept: the store holds no secrets, the history shows none
                Some(_) if is_secret(&record.kind) => {}
                Some(_) => {
                    self.store().keep_lost_edit(&LostEdit {
                        id: 0,
                        at: (changes.now / 1000) as i64,
                        kind: record.kind.clone(),
                        item: record.id.clone(),
                        field: record.field.clone(),
                        value: record.value.as_ref().map_or_else(String::new, Value::to_string),
                        label: record.label.clone(),
                        source: Stamp::parse(&record.stamp)
                            .and_then(|stamp| names.get(&stamp.device).cloned())
                            .unwrap_or_else(|| pe_i18n::tr(pe_i18n::Text::SyncAnotherComputer)),
                    })?;
                    outcome.lost += 1;
                }
                None => wins.entry(item).or_default().push(record.clone()),
            }
        }
        Ok((wins, resend))
    }

    /// The others' winning changes applied, an account before what names it; a restore point first when something
    /// here is taken away
    fn apply_wins(
        &self,
        wins: Wins,
        items: &[Item],
        incoming: &Latest,
        prefs: &[(String, String)],
        outcome: &mut Outcome,
    ) -> Result<(), SyncError> {
        let order = |kind: &str| KINDS.iter().position(|k| *k == kind).unwrap_or(KINDS.len());
        let mut groups: Vec<_> = wins.into_iter().collect();
        groups.sort_by_key(|((kind, _), _)| order(kind));
        let here: HashMap<(&str, &str), &Item> = items.iter().map(|i| ((i.kind, i.natural.as_str()), i)).collect();
        let removes = groups.iter().any(|((kind, id), records)| {
            records.iter().any(|r| r.field == DELETED) && self.store().sync_local(kind, id).ok().flatten().is_some()
        });
        if removes {
            let _ = self.sync_restore_point(prefs);
        }
        for ((kind, id), records) in groups {
            self.sync_apply_item(&kind, &id, &records, &here, incoming, outcome)?;
        }
        Ok(())
    }

    /// This computer's batch is in the vault: its fields count as synced, its removals as done
    #[cfg(test)]
    pub(crate) fn sync_written(&self, pending: &Pending) -> Result<(), SyncError> {
        record_written(&mut self.store(), pending)
    }

    /// The winning fields of one item applied: removed, changed in place, or added
    fn sync_apply_item(
        &self,
        kind: &str,
        id: &str,
        records: &[Record],
        items: &HashMap<(&str, &str), &Item>,
        incoming: &Latest,
        outcome: &mut Outcome,
    ) -> Result<(), SyncError> {
        let here = self.store().sync_local(kind, id)?;
        let natural = here
            .or_else(|| records.first().map(|r| r.natural.clone()))
            .unwrap_or_default();
        let local = items.get(&(kind, natural.as_str())).copied();
        if records.iter().any(|r| r.field == DELETED) {
            if let Some(local) = local {
                self.sync_remove(kind, &natural)?;
                if kind == "account" {
                    outcome.removed_accounts.push(local.label.clone());
                }
            }
            let store = self.store();
            store.forget_sync_local(kind, &natural)?;
            for record in records {
                store.set_synced_field(kind, id, &record.field, &record.stamp, &hash(&record.value))?;
            }
            outcome.applied += 1;
            outcome.kinds.insert(kind.to_string());
            return Ok(());
        }
        // the item as it is here, or as the others have it
        let mut fields = match local {
            Some(item) => item.fields.clone(),
            None => incoming
                .0
                .range((kind.to_string(), id.to_string(), String::new())..)
                .take_while(|((k, i, _), _)| k == kind && i == id)
                .filter(|(_, r)| r.field != DELETED)
                .filter_map(|(_, r)| Some((r.field.clone(), r.value.clone()?)))
                .collect(),
        };
        for record in records {
            match &record.value {
                Some(value) => fields.insert(record.field.clone(), value.clone()),
                None => fields.remove(&record.field),
            };
        }
        if kind == "pref" {
            for record in records {
                if let Some(Value::String(value)) = &record.value {
                    outcome.prefs.push((record.field.clone(), value.clone()));
                }
            }
        } else {
            let done = match self.sync_update(kind, &natural, &fields) {
                Ok(true) => Ok(()),
                Ok(false) => self.sync_add(kind, &fields),
                Err(e) => Err(e),
            };
            if done.is_err() {
                outcome.skipped += 1;
                return Ok(());
            }
        }
        let store = self.store();
        store.set_sync_id(kind, &natural, id)?;
        for record in records {
            store.set_synced_field(kind, id, &record.field, &record.stamp, &hash(&record.value))?;
        }
        outcome.applied += records.len();
        outcome.kinds.insert(kind.to_string());
        Ok(())
    }
}

/// This computer's batch is in the vault, recorded in `store`: its fields count as synced, its removals as done
pub(crate) fn record_written(store: &mut pe_store::Store, pending: &Pending) -> Result<(), SyncError> {
    let hashes: Vec<String> = pending.batch.records.iter().map(|r| hash(&r.value)).collect();
    let fields: Vec<_> = pending
        .batch
        .records
        .iter()
        .zip(&hashes)
        .map(|(r, h)| {
            (
                r.kind.as_str(),
                r.id.as_str(),
                r.field.as_str(),
                r.stamp.as_str(),
                h.as_str(),
            )
        })
        .collect();
    store.set_synced_fields(&fields)?;
    for record in pending.batch.records.iter().filter(|r| r.field == DELETED) {
        store.forget_sync_local(&record.kind, &record.natural)?;
    }
    if !pending.batch.records.is_empty() {
        store.set_sync_device_seq(&pending.device, pending.seq)?;
    }
    Ok(())
}

/// The file that tells a computer it was taken out of the vault
fn removed_name(device: &str) -> String {
    format!("removed/{device}")
}

/// A computer taken out of the vault, under the lock, after its batches were folded: its folder taken away and a
/// mark left that tells it, so it stops syncing rather than starting a folder again
pub fn remove_device(vault: &Vault<'_>, device: &str, name: &str, target: &str) -> PlaceResult<bool> {
    let settle = || std::thread::sleep(std::time::Duration::from_millis(SETTLE_MILLIS.load()));
    let Ok(token) = vault.lock(device, name, now_millis(), &settle)? else {
        return Ok(false);
    };
    let removed = vault
        .place
        .write(&removed_name(target), b"")
        .and_then(|()| vault.delete_device(target));
    vault.unlock(&token)?;
    removed.map(|()| true)
}

/// Every batch folded into the snapshot, under the lock: false when another computer holds it (it folds, or the next
/// sync tries again). A computer's newest batch stays, so it knows where to go on from.
pub fn fold(vault: &Vault<'_>, device: &str, name: &str) -> PlaceResult<bool> {
    let settle = || std::thread::sleep(std::time::Duration::from_millis(SETTLE_MILLIS.load()));
    let Ok(token) = vault.lock(device, name, now_millis(), &settle)? else {
        return Ok(false);
    };
    let folded = (|| -> PlaceResult<()> {
        let mut all = Latest::default();
        let mut covers: BTreeMap<String, u64> = BTreeMap::new();
        if let Some(snapshot) = vault.read_snapshot()? {
            covers.extend(snapshot.covers);
            snapshot.records.into_iter().for_each(|r| all.add(r));
        }
        let mut read: Vec<(String, u64)> = Vec::new();
        for device in vault.devices()? {
            for seq in vault.batches(&device)? {
                if let Some(batch) = vault.read_batch(&device, seq)? {
                    batch.records.into_iter().for_each(|r| all.add(r));
                }
                let held = covers.entry(device.clone()).or_insert(0);
                *held = (*held).max(seq);
                read.push((device.clone(), seq));
            }
        }
        vault.write_snapshot(&Snapshot {
            covers: covers.clone().into_iter().collect(),
            records: all.0.into_values().collect(),
        })?;
        for (device, seq) in &read {
            if covers.get(device) != Some(seq) {
                vault.delete_batch(device, *seq)?;
            }
        }
        Ok(())
    })();
    vault.unlock(&token)?;
    folded.map(|()| true)
}

/// How long a computer waits after taking the lock in a folder before reading it back, for the sync client to copy
/// another computer's lock over (tests set it to nothing)
pub(crate) static SETTLE_MILLIS: Settle = Settle(std::sync::atomic::AtomicU64::new(5_000));

pub(crate) struct Settle(std::sync::atomic::AtomicU64);

impl Settle {
    pub fn load(&self) -> u64 {
        self.0.load(std::sync::atomic::Ordering::Relaxed)
    }

    #[cfg(test)]
    pub fn set(&self, millis: u64) {
        self.0.store(millis, std::sync::atomic::Ordering::Relaxed)
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn the_latest_record_of_a_field_is_kept() {
        let record = |stamp: &str, value: &str| Record {
            kind: "card".into(),
            id: "c".into(),
            natural: "ann@x.org".into(),
            label: String::new(),
            field: "name".into(),
            stamp: stamp.into(),
            value: Some(value.into()),
        };
        let mut latest = Latest::default();
        latest.add(record("000000000000002-000000-mac", "two"));
        latest.add(record("000000000000001-000005-pc", "one"));
        latest.add(record("000000000000002-000001-pc", "three"));
        latest.add(record("not a stamp", "bad"));
        let kept: Vec<_> = latest.0.values().map(|r| r.value.clone().unwrap()).collect();
        assert_eq!(kept, ["three"]);
        let mut unknown = record("000000000000003-000000-pc", "x");
        unknown.kind = "nothing".into();
        latest.add(unknown);
        assert_eq!(latest.0.len(), 1, "a kind sync does not know is left out");
        assert!(hash(&None).is_empty() && hash(&Some("a".into())) != hash(&Some("b".into())));
    }
}
