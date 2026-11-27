//! Long secrets in parts, for the Credential Manager, which takes at most 2,560 bytes a credential (1,280 UTF-16
//! units), less than a refresh token of some providers. A secret that fits stays whole in its own credential. A longer
//! one is kept in parts: the first in the secret's own credential, starting with how many there are, the rest in
//! credentials named after it with `#1`, `#2`, ... added. They are read back together and removed together.

use std::collections::HashMap;
use std::sync::Mutex;

use super::{Backend, Key};

/// A store that names each part of a secret (part 0 is the secret's own credential)
pub(crate) trait PartStore: Send + Sync {
    fn load_part(&self, key: Key, part: u32) -> Result<Option<String>, String>;
    fn save_part(&self, key: Key, part: u32, text: &str) -> Result<(), String>;
    fn remove_part(&self, key: Key, part: u32);
}

/// The most UTF-16 units a credential holds: the Credential Manager's 2,560 bytes
/// (`CRED_MAX_CREDENTIAL_BLOB_SIZE`, the secret encoded as UTF-16)
pub(crate) const PART_LIMIT: usize = 1280;
/// The UTF-16 units of a part, with room for the header of the first
const PART_SIZE: usize = 1200;
/// What the first part of a secret kept in parts starts with, then the number of parts and the header's end
const PARTS_START: &str = "\u{1}inboxclassic-parts:";
const PARTS_END: char = '\u{1}';

/// `secret` as the credentials it is kept in: itself when it fits one, else the parts, the first with the header
fn split(secret: &str) -> Vec<String> {
    if secret.encode_utf16().count() <= PART_LIMIT && !secret.starts_with(PARTS_START) {
        return vec![secret.to_string()];
    }
    let mut parts = vec![String::new()];
    let mut size = 0;
    for c in secret.chars() {
        if size + c.len_utf16() > PART_SIZE {
            parts.push(String::new());
            size = 0;
        }
        size += c.len_utf16();
        parts.last_mut().expect("a part").push(c);
    }
    parts[0] = format!("{PARTS_START}{}{PARTS_END}{}", parts.len(), parts[0]);
    parts
}

/// How many parts the first credential of a secret says it has, with its own text; None for a secret kept whole
fn parts_of(first: &str) -> Option<(u32, &str)> {
    let rest = first.strip_prefix(PARTS_START)?;
    let (count, text) = rest.split_once(PARTS_END)?;
    Some((count.parse().ok().filter(|n| (1..=64).contains(n))?, text))
}

/// A [`PartStore`] as a [`Backend`] of whole secrets
pub(crate) struct Parts<S> {
    store: S,
    /// How many credentials each secret read or written this run takes, so a save or a removal knows what an earlier,
    /// longer secret left without reading it first
    counts: Mutex<HashMap<Key, u32>>,
}

impl<S: PartStore> Parts<S> {
    pub(crate) fn new(store: S) -> Parts<S> {
        Parts {
            store,
            counts: Mutex::default(),
        }
    }

    fn counts(&self) -> std::sync::MutexGuard<'_, HashMap<Key, u32>> {
        self.counts.lock().unwrap_or_else(|p| p.into_inner())
    }

    /// How many credentials the secret of `key` takes now: as remembered, else as its first credential says
    fn count(&self, key: Key) -> u32 {
        if let Some(&count) = self.counts().get(&key) {
            return count;
        }
        let first = self.store.load_part(key, 0).ok().flatten();
        let count = match first {
            Some(first) => parts_of(&first).map_or(1, |(count, _)| count),
            None => 0,
        };
        self.counts().insert(key, count);
        count
    }
}

impl<S: PartStore> Backend for Parts<S> {
    /// The secret, its parts read back together; a part missing is an error (written while this read, or lost), not a
    /// shorter secret
    fn load(&self, key: Key) -> Result<Option<String>, String> {
        let Some(first) = self.store.load_part(key, 0)? else {
            self.counts().insert(key, 0);
            return Ok(None);
        };
        let Some((count, text)) = parts_of(&first) else {
            self.counts().insert(key, 1);
            return Ok(Some(first));
        };
        let mut secret = text.to_string();
        for part in 1..count {
            match self.store.load_part(key, part)? {
                Some(text) => secret.push_str(&text),
                None => return Err(format!("part {part} of {count} of the secret is missing")),
            }
        }
        self.counts().insert(key, count);
        Ok(Some(secret))
    }

    /// The further parts first, then the first one, which says how many there are, then the parts an earlier, longer
    /// secret left
    fn save(&self, key: Key, secret: &str) -> Result<(), String> {
        let old = self.count(key);
        let parts = split(secret);
        for (part, text) in parts.iter().enumerate().skip(1) {
            self.store.save_part(key, part as u32, text)?;
        }
        self.store.save_part(key, 0, &parts[0])?;
        let count = parts.len() as u32;
        for part in count..old {
            self.store.remove_part(key, part);
        }
        self.counts().insert(key, count);
        Ok(())
    }

    fn remove(&self, key: Key) {
        let count = self.count(key).max(1);
        for part in 0..count {
            self.store.remove_part(key, part);
        }
        self.counts().insert(key, 0);
    }
}

#[cfg(test)]
mod tests {
    use std::sync::Arc;

    use super::*;
    use crate::secrets::Secrets;

    /// A store that takes at most what the Credential Manager takes, in memory, so the parts are tested on every
    /// system; it counts its reads
    #[derive(Default)]
    struct Limited {
        credentials: Mutex<HashMap<(Key, u32), String>>,
        reads: Mutex<usize>,
    }

    impl PartStore for Arc<Limited> {
        fn load_part(&self, key: Key, part: u32) -> Result<Option<String>, String> {
            *self.reads.lock().unwrap() += 1;
            Ok(self.credentials.lock().unwrap().get(&(key, part)).cloned())
        }
        fn save_part(&self, key: Key, part: u32, text: &str) -> Result<(), String> {
            if text.encode_utf16().count() > PART_LIMIT {
                return Err("the password is too long".into());
            }
            self.credentials.lock().unwrap().insert((key, part), text.into());
            Ok(())
        }
        fn remove_part(&self, key: Key, part: u32) {
            self.credentials.lock().unwrap().remove(&(key, part));
        }
    }

    impl Limited {
        fn parts(&self, key: Key) -> Vec<u32> {
            let mut parts: Vec<u32> = self
                .credentials
                .lock()
                .unwrap()
                .keys()
                .filter(|(k, _)| *k == key)
                .map(|(_, p)| *p)
                .collect();
            parts.sort_unstable();
            parts
        }

        fn reads(&self) -> usize {
            *self.reads.lock().unwrap()
        }
    }

    fn secrets(store: &Arc<Limited>) -> Secrets {
        Secrets::with_backend(Arc::new(Parts::new(store.clone())))
    }

    #[test]
    fn long_secrets_are_kept_in_parts() {
        let store = Arc::new(Limited::default());
        let secrets = secrets(&store);
        // a refresh token longer than one credential takes, with letters of two UTF-16 units too
        let long: String = (0..3000)
            .map(|i| {
                if i % 97 == 0 {
                    '\u{1F600}'
                } else {
                    char::from(b'a' + (i % 26) as u8)
                }
            })
            .collect();
        secrets.set(1, &long).unwrap();
        assert_eq!(store.parts(Key::Account(1)), [0, 1, 2]);
        // a later run reads it back whole
        assert_eq!(self::secrets(&store).get(1).as_deref(), Some(long.as_str()));
        // a short one in its place leaves no parts behind, and is kept as it is, without reading what was there
        let reads = store.reads();
        secrets.set(1, "short").unwrap();
        assert_eq!(store.reads(), reads, "the count is remembered");
        assert_eq!(store.parts(Key::Account(1)), [0]);
        assert_eq!(store.load_part(Key::Account(1), 0).unwrap().as_deref(), Some("short"));
        assert_eq!(self::secrets(&store).get(1).as_deref(), Some("short"));
        // removed with all its parts (a run that did not read it first too), another key's untouched
        secrets.set(1, &long).unwrap();
        secrets.set(Key::App(1), "app").unwrap();
        self::secrets(&store).remove(1);
        assert!(store.parts(Key::Account(1)).is_empty());
        assert_eq!(self::secrets(&store).get(1), None);
        assert_eq!(store.parts(Key::App(1)), [0]);
        // exactly what one credential takes stays whole
        let fits = "x".repeat(PART_LIMIT);
        secrets.set(2, &fits).unwrap();
        assert_eq!(store.parts(Key::Account(2)), [0]);
        assert_eq!(self::secrets(&store).get(2).as_deref(), Some(fits.as_str()));
        // a part lost is an error, not a shorter secret
        secrets.set(3, &long).unwrap();
        store.remove_part(Key::Account(3), 1);
        assert!(self::secrets(&store).lookup(3).is_err());
    }
}
