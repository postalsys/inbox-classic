//! Where a vault's files are kept: a folder a sync client copies between computers (Dropbox, OneDrive, iCloud Drive,
//! Google Drive, Nextcloud, Syncthing), or an S3-compatible bucket ([`super::s3`]). The engine needs only these few
//! operations on names relative to the vault's place, so every kind of place behaves the same.

use std::io::Write;
use std::path::{Path, PathBuf};

/// Why a place could not be read or written, in words for the Sync settings
#[derive(Debug, Clone, PartialEq, Eq)]
pub enum PlaceError {
    /// It is not there (yet): a folder not made, a bucket not reachable
    Missing(String),
    /// It is there but refused (permissions, credentials)
    Refused(String),
    /// Anything else
    Failed(String),
}

impl std::fmt::Display for PlaceError {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        match self {
            PlaceError::Missing(why) | PlaceError::Refused(why) | PlaceError::Failed(why) => f.write_str(why),
        }
    }
}

pub type PlaceResult<T> = std::result::Result<T, PlaceError>;

/// The largest file the engine reads: a snapshot of a large Address Book with pictures stays well under it
pub const MAX_FILE: usize = 64 * 1024 * 1024;

/// A place that holds a vault's files, named by paths of `/`-separated parts under the vault's root
pub trait Place: Send + Sync {
    /// The names of the files under `prefix` (a folder of the vault: `devices/7f3c`), not recursing, sorted
    fn list(&self, prefix: &str) -> PlaceResult<Vec<String>>;
    /// The names of the folders under `prefix`, sorted
    fn folders(&self, prefix: &str) -> PlaceResult<Vec<String>>;
    /// A file's bytes, None when it is not there
    fn read(&self, path: &str) -> PlaceResult<Option<Vec<u8>>>;
    /// A file written whole, in place of what was there (readers never see half of it)
    fn write(&self, path: &str, bytes: &[u8]) -> PlaceResult<()>;
    /// A file written only when none is there: false when one was (the lock's write; atomic on S3, as good as the
    /// sync client allows in a folder, which the lock reads back)
    fn create(&self, path: &str, bytes: &[u8]) -> PlaceResult<bool>;
    /// A file taken away; nothing when it is not there
    fn delete(&self, path: &str) -> PlaceResult<()>;
}

/// A folder on this computer, which a sync client copies to the others
pub struct Folder {
    root: PathBuf,
}

impl Folder {
    pub fn new(root: &Path) -> Folder {
        Folder {
            root: root.to_path_buf(),
        }
    }

    /// A vault name as a path under the root: only plain parts, never `..` or an absolute path
    fn at(&self, path: &str) -> PlaceResult<PathBuf> {
        let mut full = self.root.clone();
        for part in path.split('/').filter(|p| !p.is_empty()) {
            if part == "." || part == ".." || part.contains(['\\', ':', '\0']) {
                return Err(PlaceError::Failed(format!("not a name of the vault: {path}")));
            }
            full.push(part);
        }
        Ok(full)
    }

    fn entries(&self, prefix: &str, dirs: bool) -> PlaceResult<Vec<String>> {
        let dir = self.at(prefix)?;
        let read = match std::fs::read_dir(&dir) {
            Ok(read) => read,
            Err(e) if e.kind() == std::io::ErrorKind::NotFound => return Ok(Vec::new()),
            Err(e) => return Err(failed(&e)),
        };
        let mut names: Vec<String> = read
            .filter_map(|entry| entry.ok())
            .filter(|entry| entry.file_type().is_ok_and(|t| t.is_dir() == dirs))
            .filter_map(|entry| entry.file_name().into_string().ok())
            // the copies and temporary files of sync clients and of this writer
            .filter(|name| !name.starts_with('.') && !name.ends_with(".tmp"))
            .collect();
        names.sort();
        Ok(names)
    }
}

fn failed(e: &std::io::Error) -> PlaceError {
    match e.kind() {
        std::io::ErrorKind::NotFound => PlaceError::Missing(e.to_string()),
        std::io::ErrorKind::PermissionDenied => PlaceError::Refused(e.to_string()),
        _ => PlaceError::Failed(e.to_string()),
    }
}

impl Place for Folder {
    fn list(&self, prefix: &str) -> PlaceResult<Vec<String>> {
        self.entries(prefix, false)
    }

    fn folders(&self, prefix: &str) -> PlaceResult<Vec<String>> {
        self.entries(prefix, true)
    }

    fn read(&self, path: &str) -> PlaceResult<Option<Vec<u8>>> {
        let file = self.at(path)?;
        match std::fs::metadata(&file) {
            Ok(meta) if meta.len() > MAX_FILE as u64 => {
                return Err(PlaceError::Failed(format!("{path} is too large")));
            }
            Err(e) if e.kind() == std::io::ErrorKind::NotFound => return Ok(None),
            _ => {}
        }
        match std::fs::read(&file) {
            Ok(bytes) => Ok(Some(bytes)),
            Err(e) if e.kind() == std::io::ErrorKind::NotFound => Ok(None),
            Err(e) => Err(failed(&e)),
        }
    }

    fn write(&self, path: &str, bytes: &[u8]) -> PlaceResult<()> {
        let file = self.at(path)?;
        if let Some(dir) = file.parent() {
            std::fs::create_dir_all(dir).map_err(|e| failed(&e))?;
        }
        // written beside it and renamed over it, so a sync client never copies half a file
        let temporary = file.with_extension("tmp");
        let mut out = std::fs::File::create(&temporary).map_err(|e| failed(&e))?;
        out.write_all(bytes)
            .and_then(|()| out.sync_all())
            .map_err(|e| failed(&e))?;
        drop(out);
        std::fs::rename(&temporary, &file).map_err(|e| failed(&e))
    }

    fn create(&self, path: &str, bytes: &[u8]) -> PlaceResult<bool> {
        let file = self.at(path)?;
        if let Some(dir) = file.parent() {
            std::fs::create_dir_all(dir).map_err(|e| failed(&e))?;
        }
        match std::fs::OpenOptions::new().write(true).create_new(true).open(&file) {
            Ok(mut out) => {
                out.write_all(bytes)
                    .and_then(|()| out.sync_all())
                    .map_err(|e| failed(&e))?;
                Ok(true)
            }
            Err(e) if e.kind() == std::io::ErrorKind::AlreadyExists => Ok(false),
            Err(e) => Err(failed(&e)),
        }
    }

    fn delete(&self, path: &str) -> PlaceResult<()> {
        let file = self.at(path)?;
        match std::fs::remove_file(&file) {
            Ok(()) => {
                // a folder left empty goes too, as it does in a bucket (never the vault's own)
                if let Some(dir) = file.parent().filter(|dir| *dir != self.root) {
                    let _ = std::fs::remove_dir(dir);
                }
                Ok(())
            }
            Err(e) if e.kind() == std::io::ErrorKind::NotFound => Ok(()),
            Err(e) => Err(failed(&e)),
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn a_folder_keeps_files_by_their_names_and_only_there() {
        let dir = std::env::temp_dir().join(format!("pe-sync-folder-{}", std::process::id()));
        let _ = std::fs::remove_dir_all(&dir);
        let place = Folder::new(&dir);
        assert!(place.list("devices/a").unwrap().is_empty(), "nothing yet, no error");
        place.write("devices/a/000001", b"one").unwrap();
        place.write("devices/a/000002", b"two").unwrap();
        place.write("devices/b/head", b"b").unwrap();
        assert_eq!(place.list("devices/a").unwrap(), ["000001", "000002"]);
        assert_eq!(place.folders("devices").unwrap(), ["a", "b"]);
        assert_eq!(place.read("devices/a/000002").unwrap().as_deref(), Some(&b"two"[..]));
        assert_eq!(place.read("devices/a/000003").unwrap(), None);
        place.write("devices/a/000002", b"again").unwrap();
        assert_eq!(place.read("devices/a/000002").unwrap().as_deref(), Some(&b"again"[..]));
        // created only once
        assert!(place.create("lock.json", b"mine").unwrap());
        assert!(!place.create("lock.json", b"theirs").unwrap());
        assert_eq!(place.read("lock.json").unwrap().as_deref(), Some(&b"mine"[..]));
        place.delete("lock.json").unwrap();
        place.delete("lock.json").unwrap();
        assert!(place.create("lock.json", b"theirs").unwrap());
        // never outside the vault
        for bad in ["../x", "devices/../../x", "a\\b", "c:x"] {
            assert!(place.write(bad, b"x").is_err(), "{bad}");
        }
        std::fs::remove_dir_all(&dir).unwrap();
    }
}
