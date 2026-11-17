//! Crash markers: before a file is drawn, a small file naming it is written to the previews' folder, and removed when
//! the render ends (or unwinds from a panic). Running out of memory or overflowing the stack ends the process, which
//! no thread can catch: a marker left behind at the next start names the file that did it. That file is added to the
//! list of files never drawn again (`refused`), so a hostile file can end the app at most once. A file whose render
//! was abandoned (it hung) joins the list at once.
//!
//! The folder holds `rendering-<key>` markers (the key, then what the caller said the file is, such as its message
//! and part) and `refused`, one key a line, the newest [`MAX_REFUSED_KEPT`] kept.

use std::collections::HashSet;
use std::io::Write;
use std::path::{Path, PathBuf};
use std::sync::Mutex;

use crate::limits::MAX_REFUSED_KEPT;
use crate::{Key, Kind};

const PREFIX: &str = "rendering-";
const REFUSED: &str = "refused";

/// How many markers the app left in `dir` when it ended: files whose render ended it. Read only, at the start,
/// before a [`crate::Previewer`] opens the folder (which lists their files and removes them)
pub fn left_behind(dir: &Path) -> usize {
    std::fs::read_dir(dir).map_or(0, |entries| {
        entries
            .flatten()
            .filter(|entry| {
                let name = entry.file_name();
                name.to_str()
                    .and_then(|n| n.strip_prefix(PREFIX))
                    .and_then(Key::parse)
                    .is_some()
            })
            .count()
    })
}

pub struct Markers {
    dir: PathBuf,
    /// Held while the refused list is written
    writing: Mutex<()>,
}

impl Markers {
    /// The markers in `dir` (created when missing), and the files never drawn again: those already listed, and those
    /// whose markers were left behind (they are listed now, their markers removed)
    pub fn open(dir: &Path) -> std::io::Result<(Markers, HashSet<Key>)> {
        std::fs::create_dir_all(dir)?;
        let markers = Markers {
            dir: dir.to_path_buf(),
            writing: Mutex::new(()),
        };
        let mut keys = markers.read_refused();
        let mut left = Vec::new();
        for entry in std::fs::read_dir(dir)?.flatten() {
            let name = entry.file_name();
            let Some(key) = name.to_str().and_then(|n| n.strip_prefix(PREFIX)).and_then(Key::parse) else {
                continue;
            };
            left.push(entry.path());
            if !keys.contains(&key) {
                keys.push(key);
            }
        }
        markers.write_refused(&keys)?;
        // removed only once the list that names them is written
        for path in left {
            let _ = std::fs::remove_file(path);
        }
        let set = keys.into_iter().collect();
        Ok((markers, set))
    }

    /// Writes the marker of `key`, a `kind` file (`about` says what it is), and returns the guard that removes it
    /// when the render ends
    pub fn begin(&self, key: &Key, kind: Kind, about: &str) -> Marker {
        let path = self.dir.join(format!("{PREFIX}{}", key.as_str()));
        let about: String = about.chars().filter(|c| !c.is_control()).take(500).collect();
        let written = std::fs::write(&path, format!("{}\n{kind:?}\n{about}\n", key.as_str())).is_ok();
        Marker {
            path: written.then_some(path),
        }
    }

    /// Adds `key` to the files never drawn again
    pub fn refuse(&self, key: &Key) -> std::io::Result<()> {
        let mut keys = self.read_refused();
        if keys.contains(key) {
            return Ok(());
        }
        keys.push(key.clone());
        self.write_refused(&keys)
    }

    fn read_refused(&self) -> Vec<Key> {
        let text = std::fs::read_to_string(self.dir.join(REFUSED)).unwrap_or_default();
        let mut keys: Vec<Key> = Vec::new();
        for key in text.lines().filter_map(Key::parse) {
            if !keys.contains(&key) {
                keys.push(key);
            }
        }
        keys
    }

    /// The list written whole (a new file renamed over the old), the newest [`MAX_REFUSED_KEPT`] kept
    fn write_refused(&self, keys: &[Key]) -> std::io::Result<()> {
        let _held = self.writing.lock().unwrap_or_else(|p| p.into_inner());
        let kept = &keys[keys.len().saturating_sub(MAX_REFUSED_KEPT)..];
        let mut text = String::with_capacity(kept.len() * 65);
        for key in kept {
            text.push_str(key.as_str());
            text.push('\n');
        }
        let new = self.dir.join(format!("{REFUSED}.new"));
        let mut file = std::fs::File::create(&new)?;
        file.write_all(text.as_bytes())?;
        file.sync_all()?;
        drop(file);
        std::fs::rename(new, self.dir.join(REFUSED))
    }
}

/// A marker written: removed when dropped, as when the render ends or a panic unwinds through it
pub struct Marker {
    path: Option<PathBuf>,
}

impl Drop for Marker {
    fn drop(&mut self) {
        if let Some(path) = self.path.take() {
            let _ = std::fs::remove_file(path);
        }
    }
}

#[cfg(test)]
pub(crate) mod tests {
    use super::*;

    /// A new empty folder for a test
    pub(crate) fn dir(name: &str) -> PathBuf {
        let dir = std::env::temp_dir().join(format!("pe-preview-{name}-{}", std::process::id()));
        let _ = std::fs::remove_dir_all(&dir);
        dir
    }

    #[test]
    fn a_marker_is_removed_when_the_render_ends() {
        let dir = dir("marker-ends");
        let (markers, refused) = Markers::open(&dir).unwrap();
        assert!(refused.is_empty());
        let key = crate::key_of(b"file");
        let marker = markers.begin(&key, Kind::Pdf, "account 1, message 7, part 2");
        let path = dir.join(format!("rendering-{}", key.as_str()));
        let text = std::fs::read_to_string(&path).unwrap();
        assert!(text.starts_with(key.as_str()));
        assert!(text.contains("message 7, part 2"));
        drop(marker);
        assert!(!path.exists());
        let (_, refused) = Markers::open(&dir).unwrap();
        assert!(refused.is_empty());
        let _ = std::fs::remove_dir_all(dir);
    }

    #[test]
    fn a_marker_left_behind_refuses_its_file_from_then_on() {
        let dir = dir("marker-left");
        let key = crate::key_of(b"hostile");
        {
            let (markers, _) = Markers::open(&dir).unwrap();
            // the app ended while drawing it: the guard never ran
            std::mem::forget(markers.begin(&key, Kind::Pdf, "message 9"));
        }
        assert_eq!(left_behind(&dir), 1);
        let (_, refused) = Markers::open(&dir).unwrap();
        assert!(refused.contains(&key));
        assert!(!dir.join(format!("rendering-{}", key.as_str())).exists());
        assert_eq!(left_behind(&dir), 0);
        // still refused at the start after, with no marker
        let (_, refused) = Markers::open(&dir).unwrap();
        assert!(refused.contains(&key));
        let _ = std::fs::remove_dir_all(dir);
    }

    #[test]
    fn a_marker_is_removed_by_a_panic() {
        let dir = dir("marker-panic");
        let (markers, _) = Markers::open(&dir).unwrap();
        let key = crate::key_of(b"panics");
        let caught = std::panic::catch_unwind(std::panic::AssertUnwindSafe(|| {
            let _marker = markers.begin(&key, Kind::Picture, "");
            panic!("a decoder's bug");
        }));
        assert!(caught.is_err());
        let (_, refused) = Markers::open(&dir).unwrap();
        assert!(refused.is_empty());
        let _ = std::fs::remove_dir_all(dir);
    }

    #[test]
    fn the_refused_list_keeps_the_newest() {
        let dir = dir("marker-list");
        let (markers, _) = Markers::open(&dir).unwrap();
        for n in 0..MAX_REFUSED_KEPT + 10 {
            markers.refuse(&crate::key_of(&n.to_le_bytes())).unwrap();
        }
        // junk in the folder is not a key
        std::fs::write(dir.join("rendering-not-a-key"), "x").unwrap();
        let (_, refused) = Markers::open(&dir).unwrap();
        assert_eq!(refused.len(), MAX_REFUSED_KEPT);
        assert!(!refused.contains(&crate::key_of(&0usize.to_le_bytes())));
        assert!(refused.contains(&crate::key_of(&(MAX_REFUSED_KEPT + 9).to_le_bytes())));
        let _ = std::fs::remove_dir_all(dir);
    }
}
