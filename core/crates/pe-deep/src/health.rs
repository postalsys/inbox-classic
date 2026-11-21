//! Health over the run: the process's memory and open files, the IMAP sessions on the servers and the store's size,
//! sampled through the walk. Judged as growth from the first third of the run to the last, with wide margins, so a
//! slow or busy runner fails nothing while a leak that grows with every step does.

use std::path::Path;

/// One sample
#[derive(Debug, Clone, Copy, Default, PartialEq, Eq)]
pub struct Sample {
    pub step: u64,
    /// Resident memory in KiB, 0 when not known
    pub memory_kib: u64,
    pub open_files: u64,
    pub sessions: u64,
    pub store_bytes: u64,
}

/// The resident memory of process `pid` in KiB (ps, on the Mac and Linux)
pub fn memory_kib(pid: u32) -> u64 {
    std::process::Command::new("ps")
        .args(["-o", "rss=", "-p", &pid.to_string()])
        .output()
        .ok()
        .and_then(|o| String::from_utf8_lossy(&o.stdout).trim().parse().ok())
        .unwrap_or(0)
}

/// The files this process has open
pub fn own_open_files() -> u64 {
    ["/proc/self/fd", "/dev/fd"]
        .iter()
        .find_map(|dir| std::fs::read_dir(dir).ok())
        .map_or(0, |entries| entries.count() as u64)
}

/// The size of a SQLite store with its write-ahead log
pub fn store_bytes(path: &Path) -> u64 {
    let size = |p: &Path| std::fs::metadata(p).map_or(0, |m| m.len());
    let mut wal = path.as_os_str().to_owned();
    wal.push("-wal");
    size(path) + size(Path::new(&wal))
}

/// What grew too much from the first third of the run to the last: a sentence each
pub fn judge(samples: &[Sample]) -> Vec<String> {
    if samples.len() < 6 {
        return Vec::new();
    }
    let third = samples.len() / 3;
    let mean = |part: &[Sample], f: fn(&Sample) -> u64| part.iter().map(f).sum::<u64>() / part.len().max(1) as u64;
    let (first, last) = (&samples[..third], &samples[samples.len() - third..]);
    let mut said = Vec::new();
    let mut grew = |what: &str, f: fn(&Sample) -> u64, factor: f64, slack: u64| {
        let (a, b) = (mean(first, f), mean(last, f));
        if a > 0 && b as f64 > a as f64 * factor + slack as f64 {
            said.push(format!("{what} grew from {a} to {b} over the run"));
        }
    };
    // memory: twice and 200 MiB more; files and sessions: a few more than double; the store: three times
    grew("memory (KiB)", |s| s.memory_kib, 2.0, 200 * 1024);
    grew("open files", |s| s.open_files, 2.0, 20);
    grew("IMAP sessions", |s| s.sessions, 2.0, 6);
    grew("the store (bytes)", |s| s.store_bytes, 3.0, 50 << 20);
    said
}

#[cfg(test)]
mod tests {
    use super::*;

    fn run(memory: impl Fn(u64) -> u64) -> Vec<Sample> {
        (0..30)
            .map(|step| Sample {
                step,
                memory_kib: memory(step),
                open_files: 40,
                sessions: 6,
                store_bytes: 100 << 20,
            })
            .collect()
    }

    #[test]
    fn steady_use_passes_and_a_leak_does_not() {
        assert!(judge(&run(|step| 300_000 + (step % 3) * 20_000)).is_empty());
        let leak = judge(&run(|step| 300_000 + step * 40_000));
        assert_eq!(leak.len(), 1, "{leak:?}");
        assert!(leak[0].starts_with("memory"));
    }
}
