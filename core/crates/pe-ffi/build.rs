// Writes what the windows of the three platforms are built from, all committed so changes show up in diffs, and only
// rewritten when their content changes:
//   core/include/inbox_classic.h            the C header of the exports (cbindgen)
//   core/include/commands.h                 the command ids of core/commands.toml for the Windows app
//   mac/Sources/InboxClassic/Generated/Commands.swift   the same commands for the Mac
//   linux/src/generated/commands.rs         and for Linux
//   core/include/texts.h                    the ids of the words of core/locales/en/*.ftl for C (PeText)
//   mac/Sources/InboxClassic/Generated/Texts.swift      the same for the Mac
// A command's label is the catalog's `cmd-<id>` (core/locales/en/app.ftl), which every command must have.
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
    #[serde(default)]
    key: String,
    mac: Option<String>,
    linux: Option<String>,
    #[serde(default)]
    toggle: bool,
    #[serde(default)]
    one: bool,
    #[serde(default)]
    some: bool,
    /// The submenu of its menu it is in (View > Layout), labelled by the catalog's `menu-<submenu>`
    submenu: Option<String>,
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
    let ids = text_ids(&root.join("core/locales/en"));
    for command in &table.command {
        let id = format!("cmd-{}", command.id.replace('_', "-"));
        assert!(
            ids.contains(&id),
            "{}: core/locales/en/app.ftl has no {id}, its label",
            command.id
        );
        if let Some(submenu) = &command.submenu {
            let id = format!("menu-{}", submenu.replace('_', "-"));
            assert!(
                ids.contains(&id),
                "{}: the catalog has no {id}, its submenu's label",
                command.id
            );
        }
    }
    write(&root.join("core/include/texts.h"), &texts_c(&ids));
    write(
        &root.join("mac/Sources/InboxClassic/Generated/Texts.swift"),
        &texts_swift(&ids),
    );
    let out = PathBuf::from(std::env::var("OUT_DIR").unwrap());
    write(
        &out.join("text_ids.rs"),
        &format!("const TEXT_IDS: &[&str] = &{ids:?};\n"),
    );
    write(&root.join("core/include/commands.h"), &c_header(&table));
    write(
        &root.join("mac/Sources/InboxClassic/Generated/Commands.swift"),
        &swift(&table),
    );
    write(&root.join("linux/src/generated/commands.rs"), &rust(&table));

    println!("cargo:rerun-if-changed=src");
    println!("cargo:rerun-if-changed=cbindgen.toml");
    println!("cargo:rerun-if-changed=../../commands.toml");
    println!("cargo:rerun-if-changed=../../locales/en");
}

/// The ids of the English catalog, in the order pe-i18n numbers them: its files sorted by name, each message as it
/// comes (pe-i18n's build.rs reads them the same way; a test checks the two agree)
fn text_ids(dir: &Path) -> Vec<String> {
    let mut files: Vec<PathBuf> = std::fs::read_dir(dir)
        .expect("core/locales/en")
        .filter_map(|e| e.ok())
        .map(|e| e.path())
        .filter(|p| p.extension().is_some_and(|x| x == "ftl"))
        .collect();
    files.sort();
    let mut ids = Vec::new();
    for file in files {
        println!("cargo:rerun-if-changed={}", file.display());
        for line in std::fs::read_to_string(&file).unwrap().lines() {
            if let Some((id, _)) = line.split_once(" =")
                && !id.is_empty()
                && id
                    .bytes()
                    .all(|b| b.is_ascii_lowercase() || b.is_ascii_digit() || b == b'-')
            {
                ids.push(id.to_string());
            }
        }
    }
    ids
}

const TEXT_NOTE: &str = "Generated from core/locales/en/*.ftl by core/crates/pe-ffi/build.rs, do not edit";

fn texts_c(ids: &[String]) -> String {
    let mut out = format!(
        "// {TEXT_NOTE}\n#pragma once\n\n// the words of the windows: pe_text(PE_TEXT_...) gives one in the language in use\nenum PeText {{\n"
    );
    for (index, id) in ids.iter().enumerate() {
        writeln!(out, "    PE_TEXT_{} = {index},", id.replace('-', "_").to_uppercase()).unwrap();
    }
    out.push_str("};\n");
    out
}

fn texts_swift(ids: &[String]) -> String {
    let mut out = format!(
        "// {TEXT_NOTE}\nimport CInboxClassic\n\n/// The words of the windows, in the language in use (`Text.reply.text`)\nenum Text: UInt32 {{\n"
    );
    for (index, id) in ids.iter().enumerate() {
        let name = camel(&id.replace('-', "_"), false);
        let name = if ["import", "default", "case", "in", "is", "as", "repeat", "repeats"].contains(&name.as_str()) {
            format!("`{name}`")
        } else {
            name
        };
        writeln!(out, "    case {name} = {index}").unwrap();
    }
    out.push_str(
        "\n    /// In the language in use, menu marks (&) left out\n    var text: String {\n        \
         guard let text = pe_text_plain(rawValue) else { return \"\" }\n        \
         defer { pe_string_free(text) }\n        return String(cString: text)\n    }\n\n    \
         /// With its placeables filled: numbers as numbers (they choose plurals), the rest as text, as given (a\n    \
         /// text with values is never a menu label, so nothing in it is a menu mark)\n    \
         func text(_ args: [String: CustomStringConvertible]) -> String {\n        \
         let names = args.keys.map { strdup($0) }\n        let values = args.values.map { strdup($0.description) }\n        \
         defer {\n            names.forEach { free($0) }\n            values.forEach { free($0) }\n        }\n        \
         let namePointers = names.map { UnsafePointer($0) }\n        let valuePointers = values.map { UnsafePointer($0) }\n        \
         guard let text = pe_text_args(rawValue, namePointers, valuePointers, names.count) else { return \"\" }\n        \
         defer { pe_string_free(text) }\n        return String(cString: text)\n    }\n}\n",
    );
    out
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
        for (key, mac) in [
            (Some(&command.key), false),
            (command.mac.as_ref(), true),
            (command.linux.as_ref(), false),
        ] {
            let Some(key) = key.filter(|key| !key.is_empty()) else {
                continue;
            };
            let parsed = Key::parse(key).unwrap_or_else(|| panic!("{}: can not read the key {key}", command.id));
            // Mod already is Control on Windows and Linux
            assert!(
                mac || !parsed.control,
                "{}: Ctrl is for a mac key only ({key})",
                command.id
            );
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
        "// {NOTE}\n#pragma once\n\n#include \"texts.h\"\n\n// the commands of the menus, toolbar and tray, posted as WM_COMMAND\nenum PeCommandId : unsigned short {{\n"
    );
    for command in &table.command {
        writeln!(out, "    IDM_{} = {},", command.id.to_uppercase(), command.windows).unwrap();
    }
    out.push_str("};\n\n// whether a command acts on one message only, off while several are selected\n");
    out.push_str("inline bool CommandNeedsOne(unsigned id) {\n    switch (id) {\n");
    for command in table.command.iter().filter(|c| c.one) {
        writeln!(out, "    case IDM_{}:", command.id.to_uppercase()).unwrap();
    }
    out.push_str("        return true;\n    default:\n        return false;\n    }\n}\n");
    out.push_str("\n// whether a command acts on one or several messages: off with none selected\n");
    out.push_str("inline bool CommandNeedsSome(unsigned id) {\n    switch (id) {\n");
    for command in table.command.iter().filter(|c| c.some) {
        writeln!(out, "    case IDM_{}:", command.id.to_uppercase()).unwrap();
    }
    out.push_str("        return true;\n    default:\n        return false;\n    }\n}\n");
    out.push_str(
        "\n// the label of a command in the catalog (& marks the menu letter): pe_text(CommandText(IDM_...))\n\
         inline PeText CommandText(PeCommandId id) {\n    switch (id) {\n",
    );
    for command in &table.command {
        writeln!(
            out,
            "    case IDM_{}: return PE_TEXT_CMD_{};",
            command.id.to_uppercase(),
            command.id.to_uppercase()
        )
        .unwrap();
    }
    out.push_str("    }\n    return PE_TEXT_CMD_NEW_ACCOUNT;\n}\n");
    out
}

/// A shortcut: modifiers and one key
struct Key {
    command: bool,
    /// Control on the Mac (Ctrl+Mod+S is Control-Command-S); on Windows and Linux Mod already is Control
    control: bool,
    shift: bool,
    alt: bool,
    key: String,
}

impl Key {
    fn parse(text: &str) -> Option<Key> {
        let mut key = Key {
            command: false,
            control: false,
            shift: false,
            alt: false,
            key: String::new(),
        };
        for part in text.split('+') {
            match part {
                "Mod" => key.command = true,
                "Ctrl" => key.control = true,
                "Shift" => key.shift = true,
                "Alt" => key.alt = true,
                "" => return None,
                other => {
                    if !key.key.is_empty() {
                        return None;
                    }
                    let known = matches!(other, "Enter" | "Delete" | "/" | "," | "." | "[" | "]")
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
        if self.control {
            flags.push(".control");
        }
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
        if self.control {
            out.push_str("<Control>");
        }
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
            "," => out.push_str("comma"),
            "." => out.push_str("period"),
            "[" => out.push_str("bracketleft"),
            "]" => out.push_str("bracketright"),
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
        // a name that is a Swift keyword (import) in backticks; `.import` needs none
        let name = camel(&command.id, false);
        let name = if ["import", "default", "case", "in", "is", "as", "repeat"].contains(&name.as_str()) {
            format!("`{name}`")
        } else {
            name
        };
        writeln!(out, "    case {name} = {}", command.windows).unwrap();
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
    out.push_str(
        "        }\n    }\n\n    /// In the language in use, from the catalog (cmd-<id>)\n    var label: String {\n        \
         labelText.text.replacingOccurrences(of: \"...\", with: \"\u{2026}\")\n    }\n\n    \
         /// Its label in the catalog\n    var labelText: Text {\n        switch self {\n",
    );
    for command in &table.command {
        let text = camel(&format!("cmd_{}", command.id), false);
        writeln!(out, "        case .{}: return .{text}", camel(&command.id, false)).unwrap();
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
    out.push_str("        }\n    }\n\n    /// Acts on one or several messages: off with none selected\n    var needsSome: Bool {\n        switch self {\n");
    for command in &table.command {
        writeln!(
            out,
            "        case .{}: return {}",
            camel(&command.id, false),
            command.some
        )
        .unwrap();
    }
    out.push_str("        }\n    }\n\n    /// Acts on one message only: off while several are selected\n    var needsOne: Bool {\n        switch self {\n");
    for command in &table.command {
        writeln!(
            out,
            "        case .{}: return {}",
            camel(&command.id, false),
            command.one
        )
        .unwrap();
    }
    out.push_str(
        "        }\n    }\n\n    /// The submenu of its menu it is in (\"layout\"), labelled by the catalog's menu-<submenu>; nil for none\n    \
         var submenu: String? {\n        switch self {\n",
    );
    for command in &table.command {
        let submenu = command
            .submenu
            .as_ref()
            .map_or("nil".to_string(), |s| format!("\"{s}\""));
        writeln!(out, "        case .{}: return {submenu}", camel(&command.id, false)).unwrap();
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
    out.push_str(
        "        }\n    }\n\n    /// Its label in the catalog (cmd-<id>), its menu letter marked with &\n    \
         pub fn text(self) -> pe_core::i18n::Text {\n        match self {\n",
    );
    for command in &table.command {
        writeln!(
            out,
            "            Command::{} => pe_core::i18n::Text::Cmd{},",
            camel(&command.id, true),
            camel(&command.id, true)
        )
        .unwrap();
    }
    out.push_str(
        "        }\n    }\n\n    /// In the language in use, without its menu letter; kept for the run (one string a command and \
         language)\n    pub fn label(self) -> &'static str {\n        \
         type Labels = std::collections::HashMap<(&'static str, Command), &'static str>;\n        \
         static LABELS: std::sync::Mutex<Option<Labels>> = std::sync::Mutex::new(None);\n        \
         let mut labels = LABELS.lock().unwrap_or_else(|e| e.into_inner());\n        \
         let labels = labels.get_or_insert_with(Labels::new);\n        \
         labels.entry((pe_core::i18n::language(), self)).or_insert_with(|| {\n            \
         let text = pe_core::i18n::without_mnemonic(&pe_core::i18n::tr(self.text())).replace(\"...\", \"\u{2026}\");\n            \
         Box::leak(text.into_boxed_str())\n        })\n    }\n\n    \
         /// In the language in use with its menu letter as GTK marks it (`_Reply to Sender`)\n    \
         #[allow(dead_code)]\n    \
         pub fn mnemonic_label(self) -> String {\n        \
         pe_core::i18n::gtk_mnemonic(&pe_core::i18n::tr(self.text())).replace(\"...\", \"\u{2026}\")\n    }\n",
    );
    out.push_str("\n    /// Its GTK accelerator, or None\n    pub fn accel(self) -> Option<&'static str> {\n        match self {\n");
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
    out.push_str("        }\n    }\n\n    /// Acts on one or several messages: off with none selected\n    pub fn needs_some(self) -> bool {\n        match self {\n");
    for command in &table.command {
        writeln!(
            out,
            "            Command::{} => {},",
            camel(&command.id, true),
            command.some
        )
        .unwrap();
    }
    out.push_str("        }\n    }\n\n    /// Acts on one message only: off while several are selected\n    pub fn needs_one(self) -> bool {\n        match self {\n");
    for command in &table.command {
        writeln!(
            out,
            "            Command::{} => {},",
            camel(&command.id, true),
            command.one
        )
        .unwrap();
    }
    out.push_str(
        "        }\n    }\n\n    /// The submenu of its menu it is in (\"layout\"), labelled by the catalog's menu-<submenu>\n    \
         pub fn submenu(self) -> Option<&'static str> {\n        match self {\n",
    );
    for command in &table.command {
        let submenu = command
            .submenu
            .as_ref()
            .map_or("None".to_string(), |s| format!("Some(\"{s}\")"));
        writeln!(out, "            Command::{} => {submenu},", camel(&command.id, true)).unwrap();
    }
    out.push_str("        }\n    }\n}\n");
    out
}
