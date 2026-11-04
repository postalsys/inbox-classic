// Writes what the windows of the three platforms are built from, all committed so changes show up in diffs, and only
// rewritten when their content changes:
//   core/include/inbox_classic.h            the C header of the exports (cbindgen)
//   core/include/commands.h                 the command ids of core/commands.toml for the Windows app
//   mac/Sources/InboxClassic/Generated/Commands.swift   the same commands for the Mac
//   linux/src/generated/commands.rs         and for Linux
use std::fmt::Write as _;
use std::path::{Path, PathBuf};

#[derive(serde::Deserialize)]
struct Table {
    command: Vec<Command>,
}

#[derive(serde::Deserialize)]
struct Command {
    id: String,
    windows: u16,
    menu: String,
    label: String,
    #[serde(default)]
    key: String,
    mac: Option<String>,
    linux: Option<String>,
    #[serde(default)]
    toggle: bool,
}

const MENUS: [&str; 7] = ["file", "edit", "view", "tools", "message", "help", "tray"];

fn main() {
    let crate_dir = PathBuf::from(std::env::var("CARGO_MANIFEST_DIR").unwrap());
    let config = cbindgen::Config::from_file(crate_dir.join("cbindgen.toml")).expect("reading cbindgen.toml");
    cbindgen::Builder::new()
        .with_crate(&crate_dir)
        .with_config(config)
        .generate()
        .expect("generating the C header")
        .write_to_file(crate_dir.join("../../include/inbox_classic.h"));

    let root = crate_dir.join("../../..");
    let table: Table = toml::from_str(&std::fs::read_to_string(root.join("core/commands.toml")).unwrap())
        .expect("reading core/commands.toml");
    check(&table);
    write(&root.join("core/include/commands.h"), &c_header(&table));
    write(
        &root.join("mac/Sources/InboxClassic/Generated/Commands.swift"),
        &swift(&table),
    );
    write(&root.join("linux/src/generated/commands.rs"), &rust(&table));

    println!("cargo:rerun-if-changed=src");
    println!("cargo:rerun-if-changed=cbindgen.toml");
    println!("cargo:rerun-if-changed=../../commands.toml");
}

fn check(table: &Table) {
    let mut ids = std::collections::HashSet::new();
    let mut numbers = std::collections::HashSet::new();
    for command in &table.command {
        assert!(ids.insert(&command.id), "{} is in core/commands.toml twice", command.id);
        assert!(
            numbers.insert(command.windows),
            "{}: its Windows id is taken",
            command.id
        );
        assert!(
            MENUS.contains(&command.menu.as_str()),
            "{}: no menu {}",
            command.id,
            command.menu
        );
        for key in [Some(&command.key), command.mac.as_ref(), command.linux.as_ref()]
            .into_iter()
            .flatten()
        {
            if !key.is_empty() {
                Key::parse(key).unwrap_or_else(|| panic!("{}: can not read the key {key}", command.id));
            }
        }
    }
}

/// Writes `text` to `path` when it differs from what is there
fn write(path: &Path, text: &str) {
    if std::fs::read_to_string(path).ok().as_deref() == Some(text) {
        return;
    }
    if let Some(dir) = path.parent() {
        std::fs::create_dir_all(dir).unwrap();
    }
    std::fs::write(path, text).unwrap();
}

const NOTE: &str = "Generated from core/commands.toml by core/crates/pe-ffi/build.rs, do not edit";

fn camel(id: &str, upper_first: bool) -> String {
    let mut out = String::new();
    for (i, word) in id.split('_').enumerate() {
        let mut chars = word.chars();
        if let Some(first) = chars.next() {
            if i == 0 && !upper_first {
                out.push(first);
            } else {
                out.extend(first.to_uppercase());
            }
            out.extend(chars);
        }
    }
    out
}

fn c_header(table: &Table) -> String {
    let mut out = format!(
        "// {NOTE}\n#pragma once\n\n// the commands of the menus, toolbar and tray, posted as WM_COMMAND\nenum PeCommandId : unsigned short {{\n"
    );
    for command in &table.command {
        writeln!(out, "    IDM_{} = {},", command.id.to_uppercase(), command.windows).unwrap();
    }
    out.push_str("};\n");
    out
}

/// A shortcut: modifiers and one key
struct Key {
    command: bool,
    shift: bool,
    alt: bool,
    key: String,
}

impl Key {
    fn parse(text: &str) -> Option<Key> {
        let mut key = Key {
            command: false,
            shift: false,
            alt: false,
            key: String::new(),
        };
        for part in text.split('+') {
            match part {
                "Mod" => key.command = true,
                "Shift" => key.shift = true,
                "Alt" => key.alt = true,
                "" => return None,
                other => {
                    if !key.key.is_empty() {
                        return None;
                    }
                    let known = matches!(other, "Enter" | "Delete" | "/")
                        || (other.len() == 1 && other.chars().all(|c| c.is_ascii_uppercase() || c.is_ascii_digit()))
                        || other
                            .strip_prefix('F')
                            .and_then(|n| n.parse::<u8>().ok())
                            .is_some_and(|n| (1..=12).contains(&n));
                    if !known {
                        return None;
                    }
                    key.key = other.to_string();
                }
            }
        }
        (!key.key.is_empty()).then_some(key)
    }

    /// The NSMenuItem key equivalent (a Swift string literal) and its modifier mask
    fn swift(&self) -> (String, String) {
        let mut shift = self.shift;
        let equivalent = match self.key.as_str() {
            "Enter" => "\\r".to_string(),
            "Delete" => "\\u{8}".to_string(),
            // Command-? is typed as Command-Shift-/; the menu names it by the character
            "/" if shift => {
                shift = false;
                "?".to_string()
            }
            f if f.starts_with('F') && f.len() > 1 => {
                let n: u32 = f[1..].parse().unwrap();
                format!("\\u{{{:X}}}", 0xF703 + n)
            }
            other => other.to_lowercase(),
        };
        let mut flags = Vec::new();
        if self.command {
            flags.push(".command");
        }
        if shift {
            flags.push(".shift");
        }
        if self.alt {
            flags.push(".option");
        }
        (equivalent, format!("[{}]", flags.join(", ")))
    }

    /// The GTK accelerator (`<Primary><Shift>r`)
    fn gtk(&self) -> String {
        let mut out = String::new();
        if self.command {
            out.push_str("<Primary>");
        }
        if self.shift {
            out.push_str("<Shift>");
        }
        if self.alt {
            out.push_str("<Alt>");
        }
        match self.key.as_str() {
            "Enter" => out.push_str("Return"),
            "/" => out.push_str("slash"),
            other if other.len() == 1 => out.push_str(&other.to_lowercase()),
            other => out.push_str(other),
        }
        out
    }
}

fn key_for<'a>(command: &'a Command, platform: Option<&'a String>) -> Option<Key> {
    let text = platform.unwrap_or(&command.key);
    (!text.is_empty()).then(|| Key::parse(text).unwrap())
}

fn swift(table: &Table) -> String {
    let mut out = format!(
        "// {NOTE}\nimport AppKit\n\n/// A command of the menus, the toolbar and the Dock menu\nenum Command: Int, CaseIterable {{\n"
    );
    for command in &table.command {
        writeln!(out, "    case {} = {}", camel(&command.id, false), command.windows).unwrap();
    }
    out.push_str("\n    /// The menu it is in: file, edit, view, tools, message, help, or tray (the Dock menu)\n    var menu: String {\n        switch self {\n");
    for command in &table.command {
        writeln!(
            out,
            "        case .{}: return \"{}\"",
            camel(&command.id, false),
            command.menu
        )
        .unwrap();
    }
    out.push_str("        }\n    }\n\n    var label: String {\n        switch self {\n");
    for command in &table.command {
        writeln!(
            out,
            "        case .{}: return \"{}\"",
            camel(&command.id, false),
            command.label.replace("...", "\u{2026}")
        )
        .unwrap();
    }
    out.push_str("        }\n    }\n\n    /// The key equivalent and its modifiers, or nil\n    var key: (String, NSEvent.ModifierFlags)? {\n        switch self {\n");
    for command in &table.command {
        match key_for(command, command.mac.as_ref()) {
            Some(key) => {
                let (equivalent, flags) = key.swift();
                writeln!(
                    out,
                    "        case .{}: return (\"{equivalent}\", {flags})",
                    camel(&command.id, false)
                )
                .unwrap();
            }
            None => writeln!(out, "        case .{}: return nil", camel(&command.id, false)).unwrap(),
        }
    }
    out.push_str(
        "        }\n    }\n\n    /// A menu item with a check mark\n    var isToggle: Bool {\n        switch self {\n",
    );
    for command in &table.command {
        writeln!(
            out,
            "        case .{}: return {}",
            camel(&command.id, false),
            command.toggle
        )
        .unwrap();
    }
    out.push_str("        }\n    }\n}\n");
    out
}

fn rust(table: &Table) -> String {
    let mut out = format!(
        "// {NOTE}\n\n/// A command of the menus, the header bar and the tray menu\n#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash)]\npub enum Command {{\n"
    );
    for command in &table.command {
        writeln!(out, "    {},", camel(&command.id, true)).unwrap();
    }
    out.push_str("}\n\nimpl Command {\n    pub const ALL: &[Command] = &[\n");
    for command in &table.command {
        writeln!(out, "        Command::{},", camel(&command.id, true)).unwrap();
    }
    out.push_str("    ];\n\n    /// The name of its action (`win.<name>`)\n    pub fn name(self) -> &'static str {\n        match self {\n");
    for command in &table.command {
        writeln!(
            out,
            "            Command::{} => \"{}\",",
            camel(&command.id, true),
            command.id.replace('_', "-")
        )
        .unwrap();
    }
    out.push_str("        }\n    }\n\n    /// file, edit, view, tools, message, help, or tray (the tray icon's menu only)\n    pub fn menu(self) -> &'static str {\n        match self {\n");
    for command in &table.command {
        writeln!(
            out,
            "            Command::{} => \"{}\",",
            camel(&command.id, true),
            command.menu
        )
        .unwrap();
    }
    out.push_str("        }\n    }\n\n    pub fn label(self) -> &'static str {\n        match self {\n");
    for command in &table.command {
        writeln!(
            out,
            "            Command::{} => \"{}\",",
            camel(&command.id, true),
            command.label.replace("...", "\u{2026}")
        )
        .unwrap();
    }
    out.push_str("        }\n    }\n\n    /// Its GTK accelerator, or None\n    pub fn accel(self) -> Option<&'static str> {\n        match self {\n");
    for command in &table.command {
        match key_for(command, command.linux.as_ref()) {
            Some(key) => writeln!(
                out,
                "            Command::{} => Some(\"{}\"),",
                camel(&command.id, true),
                key.gtk()
            )
            .unwrap(),
            None => writeln!(out, "            Command::{} => None,", camel(&command.id, true)).unwrap(),
        }
    }
    out.push_str("        }\n    }\n\n    /// A menu item with a check mark\n    pub fn is_toggle(self) -> bool {\n        match self {\n");
    for command in &table.command {
        writeln!(
            out,
            "            Command::{} => {},",
            camel(&command.id, true),
            command.toggle
        )
        .unwrap();
    }
    out.push_str("        }\n    }\n}\n");
    out
}
