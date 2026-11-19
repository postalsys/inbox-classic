//! Who a program that connects is, in words (decision 9 of the MCP plan). Agents started from a terminal all reach the
//! app through the terminal's own program, so they share one access: the windows say so, "Programs started from
//! Terminal", and an agent started with `--name` in its arguments gets an access of its own under that name. Only
//! informative, as the rest of a program's identity: a program of the same user could say anything.

use pe_i18n::{Text, tr_args};

use super::{AgentHost, HostInfo};

/// Between a program's file and the name `--name` gave it, in the path that tells programs apart
const NAMED: &str = " --name ";
/// The longest name `--name` gives
const MAX_NAME: usize = 64;

/// The programs that are terminals, and the shells and services a terminal session runs in: an agent found to be
/// one of them was started by hand from a terminal (lowercase, without `.exe`)
const TERMINALS: &[&str] = &[
    "terminal",
    "iterm",
    "iterm2",
    "ghostty",
    "alacritty",
    "kitty",
    "wezterm",
    "wezterm-gui",
    "warp",
    "hyper",
    "tabby",
    "windowsterminal",
    "openconsole",
    "conhost",
    "cmd",
    "powershell",
    "pwsh",
    "gnome-terminal-server",
    "gnome-terminal",
    "ptyxis",
    "konsole",
    "xterm",
    "foot",
    "tilix",
    "terminator",
    "xfce4-terminal",
    "sshd",
    "tmux",
    "screen",
    "sh",
    "bash",
    "zsh",
    "fish",
    "dash",
];

/// A program's name from its file: `Claude` for `/Applications/Claude.app/Contents/MacOS/Claude`, `Cursor` for
/// `C:\...\Cursor.exe`
pub fn program_name(path: &str) -> String {
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

/// The terminal a program at `path` is, by its name, when an agent found there was started from one and has no name
/// of its own (`--name`)
fn terminal_of(path: &str) -> Option<String> {
    if path.contains(NAMED) || path.is_empty() {
        return None;
    }
    let name = program_name(path);
    TERMINALS.contains(&name.to_ascii_lowercase().as_str()).then_some(name)
}

/// The program `host` as `--name <name>` in its agent's settings gives it: an access of its own, named so
pub fn named(host: HostInfo, name: &str) -> HostInfo {
    let name: String = name.chars().filter(|c| !c.is_control()).take(MAX_NAME).collect();
    let name = name.trim();
    if name.is_empty() {
        return host;
    }
    HostInfo {
        path: format!("{}{NAMED}{name}", host.path),
        name: name.to_string(),
        ..host
    }
}

/// A program's path apart: its file, and the name `--name` gave it ([`named`]) when it has one
pub fn split_named(path: &str) -> (&str, Option<&str>) {
    match path.split_once(NAMED) {
        Some((file, name)) => (file, Some(name)),
        None => (path, None),
    }
}

/// The catalog's words for the programs started from `terminal` on this platform: all of them, or one
fn terminal_words(many: bool) -> Text {
    match (cfg!(target_os = "macos"), cfg!(windows), many) {
        (true, _, true) => Text::AgentTerminalProgramsMac,
        (true, _, false) => Text::AgentTerminalProgramMac,
        (_, true, true) => Text::AgentTerminalProgramsWindows,
        (_, true, false) => Text::AgentTerminalProgramWindows,
        (_, _, true) => Text::AgentTerminalProgramsLinux,
        (_, _, false) => Text::AgentTerminalProgramLinux,
    }
}

/// The program `name` at `path` in words: a terminal's as all its programs (`many`) or one of them, its name otherwise
fn label(name: &str, path: &str, many: bool) -> String {
    match terminal_of(path) {
        Some(terminal) => tr_args(terminal_words(many), &[("terminal", (&terminal).into())]),
        None => name.to_string(),
    }
}

/// A program as the list of programs names it: "Programs started from Terminal" for a terminal's, its name otherwise
pub fn host_label(name: &str, path: &str) -> String {
    label(name, path, true)
}

/// A program as a question names it when it asks for something: "A program started from Terminal" for a terminal's
pub fn host_one(host: &AgentHost) -> String {
    label(&host.name, &host.path, false)
}

/// The question and the words under it when `host` connects for the first time; when the relay said the program
/// was another one, the words start by saying so
pub fn connect_text(host: &HostInfo) -> (String, String) {
    let (title, detail) = asked(host);
    if host.claimed.is_empty() {
        return (title, detail);
    }
    let found = program_name(split_named(&host.path).0);
    let claimed = tr_args(
        Text::AgentConnectClaimed,
        &[("claimed", (&host.claimed).into()), ("program", (&found).into())],
    );
    (title, format!("{claimed}\n\n{detail}"))
}

fn asked(host: &HostInfo) -> (String, String) {
    let detail = pe_i18n::tr(Text::AgentConnectDetail);
    let Some(terminal) = terminal_of(&host.path) else {
        return (
            tr_args(Text::AgentConnectTitle, &[("program", (&host.name).into())]),
            detail,
        );
    };
    let programs = tr_args(terminal_words(true), &[("terminal", (&terminal).into())]);
    (
        tr_args(Text::AgentConnectTitleTerminal, &[("programs", (&programs).into())]),
        format!("{}\n\n{detail}", pe_i18n::tr(Text::AgentConnectTerminalDetail)),
    )
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
    fn a_program_that_said_it_was_another_is_named_so() {
        let found = HostInfo {
            path: "/usr/bin/python3".into(),
            name: "python3".into(),
            claimed: "Claude".into(),
        };
        let (title, detail) = connect_text(&found);
        assert_eq!(title, "python3 wants to use your mail");
        assert!(
            detail.starts_with("It said it was Claude. Inbox Classic checked which program started it: python3.\n\n"),
            "{detail}"
        );
        // named, the name its own and the program found told
        let named = named(found, "Helper");
        assert_eq!(named.claimed, "Claude");
        let (title, detail) = connect_text(&named);
        assert_eq!(title, "Helper wants to use your mail");
        assert!(detail.contains("started it: python3."), "{detail}");
    }

    #[test]
    fn a_terminals_programs_share_one_access_unless_named() {
        let terminal = HostInfo {
            path: "/System/Applications/Utilities/Terminal.app/Contents/MacOS/Terminal".into(),
            name: "Terminal".into(),
            ..Default::default()
        };
        let (title, detail) = connect_text(&terminal);
        assert!(
            title.starts_with("Programs started from") && title.ends_with("want to use your mail"),
            "{title}"
        );
        assert!(title.contains("Terminal"), "{title}");
        assert!(
            detail.contains("--name") && detail.contains("Agents read mail"),
            "{detail}"
        );
        assert!(host_label(&terminal.name, &terminal.path).starts_with("Programs started from"));
        // a shell is a terminal's too, and Windows' console
        assert!(terminal_of("/bin/zsh").is_some() && terminal_of(r"C:\Windows\System32\WindowsTerminal.exe").is_some());
        assert_eq!(terminal_of("/Applications/Claude.app/Contents/MacOS/Claude"), None);

        // named: an access of its own, by that name
        let named = named(terminal.clone(), " Claude Code\n");
        assert_eq!(named.name, "Claude Code");
        assert_ne!(named.path, terminal.path);
        assert_eq!(connect_text(&named).0, "Claude Code wants to use your mail");
        assert_eq!(host_label(&named.name, &named.path), "Claude Code");
        // nothing given changes nothing
        assert_eq!(super::named(terminal.clone(), " "), terminal);
        assert_eq!(split_named(&named.path), (terminal.path.as_str(), Some("Claude Code")));
        assert_eq!(split_named(&terminal.path), (terminal.path.as_str(), None));
        let host = AgentHost {
            id: 1,
            path: terminal.path.clone(),
            name: "Terminal".into(),
            allowed: true,
            levels: Default::default(),
            accounts: vec![],
            created: 0,
            last_used: None,
        };
        assert!(
            host_one(&host).starts_with("A program started from"),
            "{}",
            host_one(&host)
        );
    }
}
