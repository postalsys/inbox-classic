//! The program an agent runs in: the parent of `--mcp`, past the shells and runtimes that agents often start their
//! servers through (`sh -c`, `node`, `npx`, `uv`).
//!
//! The relay names it in its hello, and the app finds it again itself: from the process at the other end of the
//! connection, which the system tells (the peer of the Unix socket, the client of the named pipe), and that process's
//! parents. What the app found is what counts, so a relay's hello can no longer claim the access the user gave
//! another program; the hello only adds the name `--name` gives. The program is known by the executable of the first
//! ancestor that is not a launcher, so a program of the same user can still run a granted program's executable with
//! its own code (`ELECTRON_RUN_AS_NODE` on an Electron host, `LD_PRELOAD` on Linux, a spoofed parent on Windows) or
//! start the relay through a program it can drive (a terminal, so those share one access, decision 9 of the MCP
//! plan), and such a program could read the mail store itself anyway. Access keeps cooperating programs apart; it is
//! no wall against hostile ones running as the same user.

use std::sync::OnceLock;

use pe_core::agents::{HostInfo, program_name};

/// Programs that start other programs on an agent's behalf: the one that started them is the agent
const LAUNCHERS: &[&str] = &[
    "sh",
    "bash",
    "zsh",
    "dash",
    "fish",
    "env",
    "node",
    "npx",
    "npm",
    "bun",
    "deno",
    "uv",
    "uvx",
    "python",
    "python3",
    "cmd",
    "cmd.exe",
    "powershell",
    "powershell.exe",
    "pwsh",
    "pwsh.exe",
    "conhost.exe",
    // a terminal's session on the Mac: its shell runs under login, which the Terminal started
    "login",
];

/// How far up the line of parents the program is looked for
const MAX_DEPTH: usize = 6;

fn is_launcher(path: &str) -> bool {
    let file = path.rsplit(['/', '\\']).next().unwrap_or(path).to_ascii_lowercase();
    LAUNCHERS.contains(&file.as_str()) || file.starts_with("python3.")
}

/// The first program up the line of `parents` (their files, from the relay's parent on) that is not a launcher;
/// the nearest one when they all are
pub fn pick(parents: &[String]) -> HostInfo {
    let path = parents
        .iter()
        .find(|path| !is_launcher(path))
        .or_else(|| parents.first())
        .cloned()
        .unwrap_or_default();
    HostInfo {
        name: if path.is_empty() {
            "An unknown program".into()
        } else {
            program_name(&path)
        },
        path,
        ..Default::default()
    }
}

/// A process, as the system tells it
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct Process {
    /// Its executable, as the system has it (not what it says of itself)
    pub path: String,
    /// The process that started it
    pub parent: u32,
    /// When it started, in the system's own units (only compared with another process's); 0 when not known
    pub started: u64,
}

/// How a process is looked up by its id
pub type Lookup = fn(u32) -> Option<Process>;

static LOOKUP: OnceLock<Lookup> = OnceLock::new();

/// Sets how processes are looked up, before any relay connects or starts: pe-ffi's on Windows and the Mac, where it
/// takes the system's calls (unsafe code). Linux reads `/proc` without one.
pub fn set_process_lookup(lookup: Lookup) {
    let _ = LOOKUP.set(lookup);
}

/// The lookup in use: the one set, else this platform's own (Linux's `/proc`; on the Mac `ps`, which tests use, as
/// the app sets pe-ffi's); none on Windows without pe-ffi's, where nobody connects then
fn lookup() -> Option<Lookup> {
    LOOKUP.get().copied().or(OWN_LOOKUP)
}

#[cfg(target_os = "linux")]
const OWN_LOOKUP: Option<Lookup> = Some(linux::process);
#[cfg(all(unix, not(target_os = "linux")))]
const OWN_LOOKUP: Option<Lookup> = Some(ps::process);
#[cfg(not(unix))]
const OWN_LOOKUP: Option<Lookup> = None;

/// The files of the processes from `pid` up, as far as the first that is not a launcher. A parent that started after
/// its child is another process that took the number of a parent gone meanwhile: the line stops there.
fn line_from(lookup: Lookup, mut pid: u32, mut child_started: u64) -> Vec<String> {
    let mut line = Vec::new();
    for _ in 0..MAX_DEPTH {
        // 0 is nobody; 1 is the system's first process (init, launchd), which starts no agent itself
        if pid <= 1 {
            break;
        }
        let Some(process) = lookup(pid) else { break };
        if child_started != 0 && process.started != 0 && process.started > child_started {
            break;
        }
        let launcher = is_launcher(&process.path);
        line.push(process.path);
        if !launcher || process.parent == pid {
            break;
        }
        child_started = process.started;
        pid = process.parent;
    }
    line
}

/// The program that started this process, past launchers: what the relay names to the app
pub fn launching_program() -> HostInfo {
    let parents = lookup()
        .and_then(|lookup| {
            let own = lookup(std::process::id())?;
            Some(line_from(lookup, own.parent, own.started))
        })
        .unwrap_or_default();
    pick(&parents)
}

/// A path the way two runs of one program are told alike: Linux names a file replaced while it runs
/// "... (deleted)", and Windows does not mind case
fn normal(path: &str) -> String {
    let path = path.strip_suffix(" (deleted)").unwrap_or(path);
    if cfg!(windows) {
        path.to_lowercase()
    } else {
        path.to_string()
    }
}

/// A file's name, as [`normal`] tells them alike
fn file_name(path: &str) -> String {
    let path = normal(path);
    path.rsplit(['/', '\\']).next().unwrap_or_default().to_string()
}

/// Whether two programs' files are one, as [`normal`] tells them alike
pub(crate) fn same_file(one: &str, other: &str) -> bool {
    normal(one) == normal(other)
}

/// The program at the other end of a connection, the process `pid` as the system told it: past the relay (this
/// app's own executable, `--mcp`) and the launchers it was started through. None when the system does not tell (the
/// process is gone, or nothing looks processes up here): such a connection is refused.
pub fn verified_program(pid: u32) -> Option<HostInfo> {
    verified_with(lookup()?, pid, std::process::id())
}

/// [`verified_program`] with `lookup`, `own` this process
fn verified_with(lookup: Lookup, pid: u32, own: u32) -> Option<HostInfo> {
    let peer = lookup(pid)?;
    let ours = lookup(own)?;
    let line = if file_name(&peer.path) == file_name(&ours.path) {
        // the relay: the program is what started it
        line_from(lookup, peer.parent, peer.started)
    } else {
        // something that connects by itself is the program, or a launcher of it
        line_from(lookup, pid, 0)
    };
    (!line.is_empty()).then(|| pick(&line))
}

/// Processes as Linux tells them in `/proc`: no unsafe code needed
#[cfg(target_os = "linux")]
mod linux {
    use super::Process;

    /// The process `pid`: its executable and parent from `/proc`
    pub(super) fn process(pid: u32) -> Option<Process> {
        let path = std::fs::read_link(format!("/proc/{pid}/exe")).ok()?;
        let stat = std::fs::read_to_string(format!("/proc/{pid}/stat")).ok()?;
        let (parent, started) = stat_fields(&stat)?;
        Some(Process {
            path: path.to_string_lossy().into_owned(),
            parent,
            started,
        })
    }

    /// The parent and the start time of a `/proc/<pid>/stat` line
    pub(super) fn stat_fields(stat: &str) -> Option<(u32, u64)> {
        // the name in parentheses can hold spaces and parentheses: the fields after the last ')', the state first
        let fields: Vec<&str> = stat.rsplit_once(')')?.1.split_whitespace().collect();
        // field 4 is the parent, field 22 the start time (in clock ticks since boot)
        Some((fields.get(1)?.parse().ok()?, fields.get(19)?.parse().ok()?))
    }
}

/// Processes as `ps` tells them, on the Mac where nothing else is set (tests): the name it gives is what the
/// process says of itself, so the app sets pe-ffi's lookup, which asks the system
#[cfg(all(unix, not(target_os = "linux")))]
mod ps {
    use super::Process;

    pub(super) fn process(pid: u32) -> Option<Process> {
        let output = std::process::Command::new("/bin/ps")
            .args(["-o", "ppid=,comm=", "-p", &pid.to_string()])
            .output()
            .ok()?;
        let line = String::from_utf8_lossy(&output.stdout).trim().to_string();
        let (parent, path) = line.split_once(char::is_whitespace)?;
        Some(Process {
            path: path.trim().to_string(),
            parent: parent.trim().parse().ok()?,
            started: 0,
        })
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn launchers_are_passed() {
        let parents = [
            "/bin/sh".to_string(),
            "/usr/local/bin/node".into(),
            "/Applications/Claude.app/Contents/MacOS/Claude".into(),
        ];
        let host = pick(&parents);
        assert_eq!(host.name, "Claude");
        assert_eq!(host.path, parents[2]);
        // all launchers: the nearest
        assert_eq!(pick(&parents[..2]).path, "/bin/sh");
        assert_eq!(pick(&[]).name, "An unknown program");
    }

    /// A made-up table of processes: 10 the app, 20 its relay started by `sh` (30) in Claude (40); 50 a program that
    /// connects by itself, started by Terminal (60); 70 a relay whose parent (80) took the number of one gone
    fn table(pid: u32) -> Option<Process> {
        let (path, parent, started) = match pid {
            10 => ("/opt/Inbox Classic/inbox-classic", 1, 5),
            20 => ("/opt/Inbox Classic/inbox-classic (deleted)", 30, 300),
            30 => ("/bin/sh", 40, 200),
            40 => ("/Applications/Claude.app/Contents/MacOS/Claude", 1, 100),
            50 => ("/usr/bin/python3", 60, 500),
            60 => ("/usr/bin/gnome-terminal-server", 1, 400),
            70 => ("/opt/Inbox Classic/inbox-classic", 80, 600),
            80 => ("/usr/bin/evil", 1, 700),
            _ => return None,
        };
        Some(Process {
            path: path.into(),
            parent,
            started,
        })
    }

    #[test]
    fn the_program_is_found_from_the_connection() {
        // a relay: what started it, past the shell
        let host = verified_with(table, 20, 10).unwrap();
        assert_eq!(
            (host.name.as_str(), host.path.as_str()),
            ("Claude", "/Applications/Claude.app/Contents/MacOS/Claude")
        );
        // something that connects by itself: past its runtime, the terminal it runs in
        assert_eq!(verified_with(table, 50, 10).unwrap().name, "gnome-terminal-server");
        // a parent younger than its child is not its parent: nothing is found, so the connection is refused
        assert_eq!(verified_with(table, 70, 10), None);
        // a process gone, or this one unknown
        assert_eq!(verified_with(table, 99, 10), None);
        assert_eq!(verified_with(table, 20, 99), None);
    }

    #[test]
    fn one_program_is_told_alike() {
        assert!(same_file("/usr/bin/inbox-classic (deleted)", "/usr/bin/inbox-classic"));
        assert!(!same_file("/usr/bin/a", "/usr/bin/b"));
        assert_eq!(file_name("/usr/bin/inbox-classic (deleted)"), "inbox-classic");
    }

    #[cfg(target_os = "linux")]
    #[test]
    fn linux_tells_a_process_from_proc() {
        // a name with spaces and parentheses is passed
        assert_eq!(
            linux::stat_fields("42 (a (b) c) S 7 42 42 0 -1 4194560 0 0 0 0 0 0 0 0 20 0 1 0 12345 0 0"),
            Some((7, 12345))
        );
        let own = linux::process(std::process::id()).unwrap();
        assert_eq!(std::path::Path::new(&own.path), std::env::current_exe().unwrap());
        assert_eq!(own.parent, std::os::unix::process::parent_id());
        let parent = linux::process(own.parent).unwrap();
        assert!(parent.started <= own.started);
    }

    #[cfg(unix)]
    #[test]
    fn this_process_has_a_launcher() {
        // the test runner's parent is cargo or a shell: something is found
        assert!(!launching_program().path.is_empty());
        // this process connecting to itself is a relay: what started it, as the relay finds it
        assert_eq!(verified_program(std::process::id()), Some(launching_program()));
    }
}
