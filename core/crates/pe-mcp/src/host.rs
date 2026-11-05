//! The program an agent runs in, found from the relay's side: the parent of `--mcp`, past the shells and runtimes
//! that agents often start their servers through (`sh -c`, `node`, `npx`, `uv`). Only informative: it tells one
//! agent from another for the user, it proves nothing (a program of the same user could pretend), which is fine, as
//! such a program could read the mail store itself.

use pe_core::agents::HostInfo;

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
];

/// A program's name from its file: `Claude` for `/Applications/Claude.app/Contents/MacOS/Claude`, `Cursor` for
/// `C:\...\Cursor.exe`
pub(crate) fn program_name(path: &str) -> String {
    if let Some(bundle) = path.split('/').find(|part| part.ends_with(".app")) {
        return bundle.trim_end_matches(".app").to_string();
    }
    let file = path.rsplit(['/', '\\']).next().unwrap_or(path);
    let name = file
        .strip_suffix(".exe")
        .or_else(|| file.strip_suffix(".EXE"))
        .unwrap_or(file);
    name.to_string()
}

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
    }
}

/// The program that started this process, past launchers: what the relay names to the app. Windows has its own,
/// in pe-ffi (it takes the system's process calls).
#[cfg(unix)]
pub fn launching_program() -> HostInfo {
    let mut parents = Vec::new();
    let mut pid = std::os::unix::process::parent_id();
    for _ in 0..6 {
        if pid <= 1 {
            break;
        }
        let Some((path, parent)) = process(pid) else { break };
        let launcher = is_launcher(&path);
        parents.push(path);
        if !launcher {
            break;
        }
        pid = parent;
    }
    pick(&parents)
}

/// The executable of process `pid` and its parent's pid
#[cfg(target_os = "linux")]
fn process(pid: u32) -> Option<(String, u32)> {
    let path = std::fs::read_link(format!("/proc/{pid}/exe")).ok()?;
    let stat = std::fs::read_to_string(format!("/proc/{pid}/stat")).ok()?;
    // the name in parentheses can hold spaces: the fields after the last ')'
    let parent = stat.rsplit_once(')')?.1.split_whitespace().nth(1)?.parse().ok()?;
    Some((path.to_string_lossy().into_owned(), parent))
}

/// The executable of process `pid` and its parent's pid, as `ps` tells them (proc_pidpath would take unsafe code)
#[cfg(all(unix, not(target_os = "linux")))]
fn process(pid: u32) -> Option<(String, u32)> {
    let output = std::process::Command::new("/bin/ps")
        .args(["-o", "ppid=,comm=", "-p", &pid.to_string()])
        .output()
        .ok()?;
    let line = String::from_utf8_lossy(&output.stdout).trim().to_string();
    let (parent, path) = line.split_once(char::is_whitespace)?;
    Some((path.trim().to_string(), parent.trim().parse().ok()?))
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn programs_are_named_from_their_files() {
        assert_eq!(program_name("/Applications/Claude.app/Contents/MacOS/Claude"), "Claude");
        assert_eq!(
            program_name(r"C:\Users\a\AppData\Local\Programs\cursor\Cursor.exe"),
            "Cursor"
        );
        assert_eq!(program_name("/usr/bin/code"), "code");
    }

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

    #[cfg(unix)]
    #[test]
    fn this_process_has_a_launcher() {
        // the test runner's parent is cargo or a shell: something is found
        assert!(!launching_program().path.is_empty());
    }
}
