//! A vault's files and what they hold.
//!
//! ```text
//! vault.json                  plain: the format, the vault's id, its key sealed with the sync passphrase
//! lock                        plain: who holds the soft lock and until when (only for shared rewrites)
//! snapshot                    sealed: every field's latest record, and how far into each computer's changes it goes
//! devices/<device>/about      sealed: the computer's name and when it last synced
//! devices/<device>/<seq>      sealed: one batch of that computer's changes, numbered from 1, never rewritten
//! ```
//!
//! Each computer writes only its own folder, so two never write the same file; the snapshot and the removal of
//! another computer's files happen only under the lock.

use serde::{Deserialize, Serialize};
use serde_json::Value;
use zeroize::Zeroizing;

use super::backend::{Place, PlaceError, PlaceResult};
use super::crypt::{self, VaultKey};

pub const FORMAT: &str = "inboxclassic-sync";
pub const VERSION: u32 = 1;

/// The longest a lock is held without being renewed: a computer that went away lets it go by then
pub const LOCK_MILLIS: u64 = 60_000;

/// The plain file that names a vault
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct VaultFile {
    pub format: String,
    pub version: u32,
    pub vault: String,
    /// The vault key sealed with the sync passphrase (pe-pgp `sealed`), armored
    pub key: String,
}

/// One field of one item, as a computer changed it
#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
pub struct Record {
    pub kind: String,
    /// The item's sync id, the same on every computer
    pub id: String,
    /// What says it is the same thing on two computers (items.rs)
    pub natural: String,
    /// What it is called, for the history
    #[serde(default)]
    pub label: String,
    pub field: String,
    pub stamp: String,
    /// None for a field taken away (a set's element), or with [`pe_store::sync::DELETED`] the item removed
    #[serde(default)]
    pub value: Option<Value>,
}

/// A batch of one computer's changes
#[derive(Debug, Clone, Default, Serialize, Deserialize)]
pub struct Batch {
    pub records: Vec<Record>,
}

/// Every field's latest record, and the change numbers it covers
#[derive(Debug, Clone, Default, Serialize, Deserialize)]
pub struct Snapshot {
    /// (device, seq): the changes of each computer up to seq are in it
    pub covers: Vec<(String, u64)>,
    pub records: Vec<Record>,
}

/// A computer of the vault, as the Sync settings list it
#[derive(Debug, Clone, Default, PartialEq, Eq, Serialize, Deserialize)]
pub struct About {
    pub name: String,
    /// When it last synced, milliseconds since 1970
    pub seen: u64,
    /// Its last batch
    pub seq: u64,
}

/// The soft lock's file
#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct Lock {
    pub device: String,
    pub name: String,
    pub token: String,
    /// Milliseconds since 1970 after which it no longer holds
    pub until: u64,
}

/// The device name that seals the vault's own files (the snapshot)
const VAULT_WRITER: &str = "vault";

/// A vault opened with its key
pub struct Vault<'a> {
    pub place: &'a dyn Place,
    pub id: String,
    pub key: VaultKey,
}

/// The name of a batch file: numbers that sort as text
pub fn batch_name(seq: u64) -> String {
    format!("{seq:012}")
}

fn damaged(path: &str) -> PlaceError {
    PlaceError::Failed(format!("{path} could not be opened"))
}

impl Vault<'_> {
    fn read_sealed<T: for<'de> Deserialize<'de>>(
        &self,
        device: &str,
        path: &str,
        name: &str,
    ) -> PlaceResult<Option<T>> {
        let Some(bytes) = self.place.read(path)? else {
            return Ok(None);
        };
        let plain = crypt::open(&self.key, &self.id, device, name, &bytes).ok_or_else(|| damaged(path))?;
        serde_json::from_slice(&plain).map(Some).map_err(|_| damaged(path))
    }

    fn write_sealed<T: Serialize>(&self, device: &str, path: &str, name: &str, value: &T) -> PlaceResult<()> {
        let plain = Zeroizing::new(serde_json::to_vec(value).map_err(|e| PlaceError::Failed(e.to_string()))?);
        let sealed = crypt::seal(&self.key, &self.id, device, name, &plain).ok_or_else(|| damaged(path))?;
        self.place.write(path, &sealed)
    }

    /// The computers that wrote to the vault
    pub fn devices(&self) -> PlaceResult<Vec<String>> {
        self.place.folders("devices")
    }

    /// The change numbers of a computer's batches there now
    pub fn batches(&self, device: &str) -> PlaceResult<Vec<u64>> {
        Ok(self
            .place
            .list(&format!("devices/{device}"))?
            .iter()
            .filter_map(|name| name.parse().ok().filter(|_| name.len() == 12))
            .collect())
    }

    pub fn read_batch(&self, device: &str, seq: u64) -> PlaceResult<Option<Batch>> {
        let name = batch_name(seq);
        self.read_sealed(device, &format!("devices/{device}/{name}"), &name)
    }

    pub fn write_batch(&self, device: &str, seq: u64, batch: &Batch) -> PlaceResult<()> {
        let name = batch_name(seq);
        self.write_sealed(device, &format!("devices/{device}/{name}"), &name, batch)
    }

    pub fn delete_batch(&self, device: &str, seq: u64) -> PlaceResult<()> {
        self.place.delete(&format!("devices/{device}/{}", batch_name(seq)))
    }

    pub fn read_about(&self, device: &str) -> PlaceResult<Option<About>> {
        self.read_sealed(device, &format!("devices/{device}/about"), "about")
    }

    pub fn write_about(&self, device: &str, about: &About) -> PlaceResult<()> {
        self.write_sealed(device, &format!("devices/{device}/about"), "about", about)
    }

    /// A computer's folder taken away (Remove Computer), under the lock
    pub fn delete_device(&self, device: &str) -> PlaceResult<()> {
        for seq in self.batches(device)? {
            self.delete_batch(device, seq)?;
        }
        self.place.delete(&format!("devices/{device}/about"))
    }

    pub fn read_snapshot(&self) -> PlaceResult<Option<Snapshot>> {
        self.read_sealed(VAULT_WRITER, "snapshot", "snapshot")
    }

    pub fn write_snapshot(&self, snapshot: &Snapshot) -> PlaceResult<()> {
        self.write_sealed(VAULT_WRITER, "snapshot", "snapshot", snapshot)
    }

    /// The soft lock taken for `device`: Ok(None) when another computer holds it (with who), else the token to let
    /// it go with. A lock past its time is taken over. In a folder two computers could both create the file before
    /// their sync clients copy it; the one whose token is not in the file read back after `settle` gives way.
    pub fn lock(&self, device: &str, name: &str, now: u64, settle: &dyn Fn()) -> PlaceResult<Result<String, Lock>> {
        let token = crypt::new_id().ok_or_else(|| PlaceError::Failed("no random numbers".into()))?;
        let mine = Lock {
            device: device.into(),
            name: name.into(),
            token: token.clone(),
            until: now + LOCK_MILLIS,
        };
        let bytes = serde_json::to_vec(&mine).map_err(|e| PlaceError::Failed(e.to_string()))?;
        for _ in 0..2 {
            if self.place.create("lock", &bytes)? {
                settle();
                return Ok(match self.read_lock()? {
                    Some(held) if held.token == token => Ok(token),
                    Some(held) => Err(held),
                    None => Err(mine),
                });
            }
            match self.read_lock()? {
                // past its time, or unreadable: taken away and tried again
                Some(held) if held.until > now => return Ok(Err(held)),
                _ => self.place.delete("lock")?,
            }
        }
        Ok(Err(mine))
    }

    pub fn read_lock(&self) -> PlaceResult<Option<Lock>> {
        Ok(self
            .place
            .read("lock")?
            .and_then(|bytes| serde_json::from_slice(&bytes).ok()))
    }

    /// The lock let go, when it is still ours
    pub fn unlock(&self, token: &str) -> PlaceResult<()> {
        if self.read_lock()?.is_some_and(|held| held.token == token) {
            self.place.delete("lock")?;
        }
        Ok(())
    }
}

/// The vault file read, None when the place holds none
pub fn read_vault_file(place: &dyn Place) -> PlaceResult<Option<VaultFile>> {
    let Some(bytes) = place.read("vault.json")? else {
        return Ok(None);
    };
    let file: VaultFile = serde_json::from_slice(&bytes).map_err(|_| damaged("vault.json"))?;
    if file.format != FORMAT || file.version > VERSION || file.vault.len() != 32 {
        return Err(damaged("vault.json"));
    }
    Ok(Some(file))
}

/// A new vault in `place`, its key sealed with `passphrase`: (its id, its key)
pub fn create_vault(place: &dyn Place, passphrase: &str) -> PlaceResult<(String, VaultKey)> {
    let fail = || PlaceError::Failed("the vault could not be made".into());
    let key = crypt::new_key().ok_or_else(fail)?;
    let id = crypt::new_id().ok_or_else(fail)?;
    let sealed = pe_pgp::sealed::seal(key.to_vec(), passphrase).map_err(|_| fail())?;
    let file = VaultFile {
        format: FORMAT.into(),
        version: VERSION,
        vault: id.clone(),
        key: sealed,
    };
    let bytes = serde_json::to_vec_pretty(&file).map_err(|_| fail())?;
    if !place.create("vault.json", &bytes)? {
        return Err(PlaceError::Failed("a vault is there already".into()));
    }
    Ok((id, key))
}

/// The vault key opened with the passphrase, None for a wrong one
pub fn open_key(file: &VaultFile, passphrase: &str) -> Option<VaultKey> {
    let plain = Zeroizing::new(pe_pgp::sealed::open(file.key.as_bytes(), passphrase, 1024).ok()?);
    let bytes: [u8; 32] = plain.as_slice().try_into().ok()?;
    Some(Zeroizing::new(bytes))
}

#[cfg(test)]
mod tests {
    use super::super::backend::Folder;
    use super::*;

    fn place() -> (std::path::PathBuf, Folder) {
        let dir = std::env::temp_dir().join(format!("pe-vault-{}-{}", std::process::id(), crypt::new_id().unwrap()));
        (dir.clone(), Folder::new(&dir))
    }

    #[test]
    fn a_vault_opens_with_its_passphrase_and_keeps_batches() {
        let (dir, place) = place();
        let (id, key) = create_vault(&place, "correct horse").unwrap();
        assert!(create_vault(&place, "other").is_err(), "one vault in a place");
        let file = read_vault_file(&place).unwrap().unwrap();
        assert_eq!(file.vault, id);
        assert_eq!(open_key(&file, "correct horse").as_deref(), Some(&*key));
        assert!(open_key(&file, "wrong").is_none());
        let vault = Vault { place: &place, id, key };
        let batch = Batch {
            records: vec![Record {
                kind: "card".into(),
                id: "c".into(),
                natural: "ann@x.org".into(),
                label: "Ann".into(),
                field: "name".into(),
                stamp: "1".into(),
                value: Some("Ann".into()),
            }],
        };
        vault.write_batch("mac", 1, &batch).unwrap();
        vault.write_batch("mac", 2, &Batch::default()).unwrap();
        assert_eq!(vault.devices().unwrap(), ["mac"]);
        assert_eq!(vault.batches("mac").unwrap(), [1, 2]);
        assert_eq!(vault.read_batch("mac", 1).unwrap().unwrap().records, batch.records);
        // a batch moved to another name or computer does not open
        std::fs::copy(
            dir.join("devices/mac/000000000001"),
            dir.join("devices/mac/000000000003"),
        )
        .unwrap();
        assert!(vault.read_batch("mac", 3).is_err());
        std::fs::create_dir_all(dir.join("devices/pc")).unwrap();
        std::fs::copy(
            dir.join("devices/mac/000000000001"),
            dir.join("devices/pc/000000000001"),
        )
        .unwrap();
        assert!(vault.read_batch("pc", 1).is_err());
        std::fs::remove_dir_all(&dir).unwrap();
    }

    #[test]
    fn the_lock_is_held_by_one_and_taken_over_when_it_runs_out() {
        let (dir, place) = place();
        let vault = Vault {
            place: &place,
            id: crypt::new_id().unwrap(),
            key: crypt::new_key().unwrap(),
        };
        let token = vault.lock("mac", "MacBook", 1_000, &|| {}).unwrap().unwrap();
        let held = vault.lock("pc", "Desktop", 2_000, &|| {}).unwrap().unwrap_err();
        assert_eq!(held.name, "MacBook");
        // not let go by another
        vault.unlock("not-the-token").unwrap();
        assert!(vault.read_lock().unwrap().is_some());
        // past its time: taken over
        let theirs = vault
            .lock("pc", "Desktop", 1_000 + LOCK_MILLIS + 1, &|| {})
            .unwrap()
            .unwrap();
        vault.unlock(&token).unwrap();
        assert_eq!(
            vault.read_lock().unwrap().unwrap().device,
            "pc",
            "the old holder does not take it away"
        );
        vault.unlock(&theirs).unwrap();
        assert!(vault.read_lock().unwrap().is_none());
        std::fs::remove_dir_all(&dir).unwrap();
    }
}
