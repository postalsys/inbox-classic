//! The previews kept in memory, by the file they are of (its [`Key`]) and the page, the least recently used dropped
//! first past [`crate::limits::CACHE_BYTES`]. Never written to disk: arrowing back to a message shows its previews at
//! once, quitting forgets them.

use std::collections::{BTreeMap, HashMap};
use std::sync::Arc;

use crate::{Description, Key, Picture};

/// What is kept of a file
#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash)]
pub enum Slot {
    Description,
    Page(usize),
}

#[derive(Debug, Clone)]
pub enum Entry {
    Description(Arc<Description>),
    Page(Arc<Picture>),
}

impl Entry {
    /// What it counts for against the size of the cache: a description counts as a little, a page as its bytes
    fn weight(&self) -> usize {
        match self {
            Entry::Description(_) => 256,
            Entry::Page(picture) => picture.bytes.len() + 64,
        }
    }
}

pub struct Cache {
    limit: usize,
    used: usize,
    tick: u64,
    entries: HashMap<(Key, Slot), (Entry, u64)>,
    /// The entries by when they were used last, oldest first
    order: BTreeMap<u64, (Key, Slot)>,
}

impl Cache {
    pub fn new(limit: usize) -> Cache {
        Cache {
            limit,
            used: 0,
            tick: 0,
            entries: HashMap::new(),
            order: BTreeMap::new(),
        }
    }

    /// The bytes it holds
    pub fn used(&self) -> usize {
        self.used
    }

    /// The entry, now the most recently used
    pub fn get(&mut self, key: &Key, slot: Slot) -> Option<Entry> {
        self.tick += 1;
        let tick = self.tick;
        let (entry, used) = self.entries.get_mut(&(key.clone(), slot))?;
        self.order.remove(used);
        *used = tick;
        self.order.insert(tick, (key.clone(), slot));
        Some(entry.clone())
    }

    /// Keeps `entry`, dropping the least recently used until it fits; one larger than the whole cache is not kept
    pub fn put(&mut self, key: Key, slot: Slot, entry: Entry) {
        let weight = entry.weight();
        self.remove(&key, slot);
        if weight > self.limit {
            return;
        }
        while self.used + weight > self.limit {
            let Some((_, oldest)) = self.order.pop_first() else {
                break;
            };
            if let Some((dropped, _)) = self.entries.remove(&oldest) {
                self.used -= dropped.weight();
            }
        }
        self.tick += 1;
        self.order.insert(self.tick, (key.clone(), slot));
        self.entries.insert((key, slot), (entry, self.tick));
        self.used += weight;
    }

    fn remove(&mut self, key: &Key, slot: Slot) {
        if let Some((entry, used)) = self.entries.remove(&(key.clone(), slot)) {
            self.order.remove(&used);
            self.used -= entry.weight();
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::Mime;

    fn page(bytes: usize) -> Entry {
        Entry::Page(Arc::new(Picture {
            mime: Mime::Png,
            bytes: vec![0; bytes],
            width: 1,
            height: 1,
        }))
    }

    fn key(n: u8) -> Key {
        crate::key_of(&[n])
    }

    #[test]
    fn the_least_recently_used_goes_first() {
        let mut cache = Cache::new(3 * (1000 + 64));
        cache.put(key(1), Slot::Page(0), page(1000));
        cache.put(key(2), Slot::Page(0), page(1000));
        cache.put(key(3), Slot::Page(0), page(1000));
        // 1 used again: 2 is now the oldest
        assert!(cache.get(&key(1), Slot::Page(0)).is_some());
        cache.put(key(4), Slot::Page(0), page(1000));
        assert!(cache.get(&key(2), Slot::Page(0)).is_none());
        assert!(cache.get(&key(1), Slot::Page(0)).is_some());
        assert!(cache.get(&key(3), Slot::Page(0)).is_some());
        assert!(cache.get(&key(4), Slot::Page(0)).is_some());
        assert_eq!(cache.used(), 3 * (1000 + 64));
    }

    #[test]
    fn stays_within_its_size() {
        let mut cache = Cache::new(crate::limits::CACHE_BYTES);
        for n in 0..200u8 {
            cache.put(key(n), Slot::Page(0), page(1024 * 1024));
            assert!(cache.used() <= crate::limits::CACHE_BYTES);
        }
        // a preview larger than the whole cache is not kept, and drops nothing
        let before = cache.used();
        cache.put(key(255), Slot::Page(1), page(crate::limits::CACHE_BYTES + 1));
        assert!(cache.get(&key(255), Slot::Page(1)).is_none());
        assert_eq!(cache.used(), before);
    }

    #[test]
    fn put_again_replaces() {
        let mut cache = Cache::new(10_000);
        cache.put(key(1), Slot::Page(0), page(100));
        cache.put(key(1), Slot::Page(0), page(200));
        assert_eq!(cache.used(), 264);
        cache.put(
            key(1),
            Slot::Description,
            Entry::Description(Arc::new(Description {
                kind: crate::Kind::Pdf,
                pages: 3,
                title: None,
                sizes: vec![],
            })),
        );
        assert_eq!(cache.used(), 264 + 256);
    }
}
