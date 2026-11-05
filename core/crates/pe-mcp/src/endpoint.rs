//! Where the running app listens for its agents: one place for each store, so a test run with a store of its own
//! never reaches the user's app, and the relay finds it from the same store path.

use std::path::{Path, PathBuf};

/// The channel of the app that has a store open
#[derive(Debug, Clone, PartialEq, Eq)]
pub enum Endpoint {
    /// A Unix socket, in a folder only its user can open
    Socket(PathBuf),
    /// A Windows named pipe, `\\.\pipe\...`
    Pipe(String),
}

/// FNV-1a: the same in every build of the app, as the relay and the app may be different versions for a moment
fn fnv(text: &str) -> u64 {
    let mut hash: u64 = 0xcbf2_9ce4_8422_2325;
    for byte in text.bytes() {
        hash ^= u64::from(byte);
        hash = hash.wrapping_mul(0x0000_0100_0000_01b3);
    }
    hash
}

impl Endpoint {
    /// The socket's or the pipe's name
    pub fn path(&self) -> std::path::PathBuf {
        match self {
            Endpoint::Socket(path) => path.clone(),
            Endpoint::Pipe(name) => std::path::PathBuf::from(name),
        }
    }

    /// The channel of the app with the store at `store` open
    pub fn for_store(store: &Path) -> Endpoint {
        let store = std::fs::canonicalize(store).unwrap_or_else(|_| store.to_path_buf());
        let user = std::env::var("USER")
            .or_else(|_| std::env::var("USERNAME"))
            .unwrap_or_default();
        let key = format!("{:016x}", fnv(&format!("{user}\n{}", store.display())));
        if cfg!(windows) {
            Endpoint::Pipe(format!(r"\\.\pipe\InboxClassic-{key}"))
        } else {
            // the user's own runtime folder (Linux), else the temporary folder, which is the user's own on the Mac
            let base = std::env::var_os("XDG_RUNTIME_DIR")
                .map(PathBuf::from)
                .filter(|dir| dir.is_absolute())
                .unwrap_or_else(std::env::temp_dir);
            Endpoint::Socket(base.join(format!("inbox-classic-{key}")).join("mcp.sock"))
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn each_store_has_its_own() {
        let one = Endpoint::for_store(Path::new("/tmp/one/store.db"));
        assert_eq!(one, Endpoint::for_store(Path::new("/tmp/one/store.db")));
        assert_ne!(one, Endpoint::for_store(Path::new("/tmp/two/store.db")));
        assert_eq!(fnv(""), 0xcbf2_9ce4_8422_2325);
        if let Endpoint::Socket(path) = one {
            // a Unix socket path has room for about 104 bytes
            assert!(path.as_os_str().len() < 104, "{}", path.display());
        }
    }
}
