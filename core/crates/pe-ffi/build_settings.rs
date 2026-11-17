// The settings window of core/settings.toml, for each platform (all committed, so changes show in diffs):
//   core/include/settings.h                                 the tables of the Windows app
//   mac/Sources/InboxClassic/Generated/SettingsPages.swift  the Mac's SettingsPage, SettingsGroup and Setting enums
//   linux/src/generated/settings_pages.rs                   the same for Linux
//   $OUT_DIR/settings_table.rs                              the whole table, for pe-ffi's tests/settings.rs
// Each platform gets only its own settings, and the groups and pages that have one of them, and only what its app
// reads.
use std::collections::HashSet;
use std::fmt::Write as _;
use std::path::Path;

use super::camel;

#[derive(serde::Deserialize)]
struct Table {
    page: Vec<Page>,
}

#[derive(serde::Deserialize)]
#[serde(deny_unknown_fields)]
struct Page {
    id: String,
    label: String,
    mac_symbol: String,
    linux_icon: String,
    group: Vec<Group>,
}

#[derive(serde::Deserialize)]
#[serde(deny_unknown_fields)]
struct Group {
    id: String,
    label: Option<String>,
    note: Option<String>,
    setting: Vec<Setting>,
}

#[derive(serde::Deserialize)]
#[serde(deny_unknown_fields)]
struct Setting {
    id: String,
    kind: String,
    label: String,
    note: Option<String>,
    platforms: Option<Vec<String>>,
    depends_on: Option<String>,
}

const PLATFORMS: [&str; 3] = ["windows", "mac", "linux"];
const KINDS: [&str; 3] = ["switch", "choice", "button"];

impl Setting {
    fn on(&self, platform: &str) -> bool {
        self.platforms.as_ref().is_none_or(|p| p.iter().any(|p| p == platform))
    }
}

impl Group {
    fn settings<'a>(&'a self, platform: &'a str) -> impl Iterator<Item = &'a Setting> {
        self.setting.iter().filter(move |s| s.on(platform))
    }
}

impl Page {
    fn groups<'a>(&'a self, platform: &'a str) -> impl Iterator<Item = &'a Group> {
        self.group.iter().filter(move |g| g.settings(platform).next().is_some())
    }
}

/// The table as one platform has it: every page, the groups with one of its settings, and its settings, in order,
/// each with what it is in
struct View<'a> {
    platform: &'a str,
    pages: Vec<&'a Page>,
    groups: Vec<(&'a Page, &'a Group)>,
    settings: Vec<(&'a Page, &'a Group, &'a Setting)>,
}

fn view<'a>(table: &'a Table, platform: &'a str) -> View<'a> {
    let pages: Vec<&Page> = table.page.iter().collect();
    let groups: Vec<(&Page, &Group)> = pages
        .iter()
        .flat_map(|p| p.groups(platform).map(move |g| (*p, g)))
        .collect();
    let settings = groups
        .iter()
        .flat_map(|(p, g)| g.settings(platform).map(move |s| (*p, *g, s)))
        .collect();
    View {
        platform,
        pages,
        groups,
        settings,
    }
}

pub fn write_all(root: &Path, out_dir: &Path, ids: &[String], write: fn(&Path, &str)) {
    let path = root.join("core/settings.toml");
    println!("cargo:rerun-if-changed={}", path.display());
    let table: Table = toml::from_str(&std::fs::read_to_string(&path).unwrap()).expect("reading core/settings.toml");
    check(&table, ids);
    write(
        &root.join("core/include/settings.h"),
        &c_header(&view(&table, "windows")),
    );
    write(
        &root.join("mac/Sources/InboxClassic/Generated/SettingsPages.swift"),
        &swift(&view(&table, "mac")),
    );
    write(
        &root.join("linux/src/generated/settings_pages.rs"),
        &rust(&view(&table, "linux")),
    );
    write(&out_dir.join("settings_table.rs"), &test_table(&table));
}

/// Panics with `what` when the English catalog has no message `id`
fn known(ids: &[String], id: &str, what: &str) {
    assert!(
        ids.iter().any(|i| i == id),
        "core/settings.toml: {what}: core/locales/en has no {id}"
    );
}

fn check(table: &Table, ids: &[String]) {
    let mut pages = HashSet::new();
    let mut groups = HashSet::new();
    let mut settings = HashSet::new();
    for page in &table.page {
        assert!(pages.insert(&page.id), "the page {} is there twice", page.id);
        known(ids, &page.label, &page.id);
        assert!(!page.group.is_empty(), "the page {} has no groups", page.id);
        for group in &page.group {
            assert!(groups.insert(&group.id), "the group {} is there twice", group.id);
            for id in group.label.iter().chain(&group.note) {
                known(ids, id, &group.id);
            }
            assert!(!group.setting.is_empty(), "the group {} has no settings", group.id);
            for (at, setting) in group.setting.iter().enumerate() {
                assert!(
                    settings.insert(&setting.id),
                    "the setting {} is there twice",
                    setting.id
                );
                check_setting(setting, ids);
                if let Some(parent) = &setting.depends_on {
                    check_depends_on(setting, parent, &group.setting[..at]);
                }
            }
        }
        for platform in PLATFORMS {
            if page.groups(platform).next().is_none() {
                panic!("the page {} has no settings on {platform}", page.id);
            }
        }
    }
}

/// A setting's kind, words and platforms are known
fn check_setting(setting: &Setting, ids: &[String]) {
    assert!(
        KINDS.contains(&setting.kind.as_str()),
        "{}: no kind {}",
        setting.id,
        setting.kind
    );
    known(ids, &setting.label, &setting.id);
    if let Some(note) = &setting.note {
        known(ids, note, &setting.id);
    }
    for platform in setting.platforms.iter().flatten() {
        assert!(
            PLATFORMS.contains(&platform.as_str()),
            "{}: no platform {platform}",
            setting.id
        );
    }
}

/// `parent`, which `setting` depends on, is a switch among the settings `before` it in its group, on every platform
/// that has `setting`
fn check_depends_on(setting: &Setting, parent: &str, before: &[Setting]) {
    let parent_setting = before.iter().find(|s| s.id == parent).unwrap_or_else(|| {
        panic!(
            "{}: depends on {parent}, which is not before it in its group",
            setting.id
        )
    });
    assert_eq!(
        parent_setting.kind, "switch",
        "{}: depends on {parent}, not a switch",
        setting.id
    );
    for platform in PLATFORMS {
        assert!(
            !setting.on(platform) || parent_setting.on(platform),
            "{}: depends on {parent}, which {platform} does not have",
            setting.id
        );
    }
}

const NOTE: &str = "Generated from core/settings.toml by core/crates/pe-ffi/build.rs, do not edit";

/// A catalog id as C names it: PE_TEXT_UI_SEND_DELAY
fn c_text(id: &str) -> String {
    format!("PE_TEXT_{}", id.replace('-', "_").to_uppercase())
}

/// A catalog id as the Mac's Text enum and Linux's pe_core::i18n::Text name it
fn text_case(id: &str, upper_first: bool) -> String {
    camel(&id.replace('-', "_"), upper_first)
}

fn c_header(view: &View) -> String {
    let mut out = format!(
        "// {NOTE}\n#pragma once\n\n#include \"texts.h\"\n\n\
         // the pages of Tools > Options (its tabs), their groups (group boxes) and their settings, in order\n"
    );
    let enumeration = |out: &mut String, name: &str, prefix: &str, ids: &[&str]| {
        writeln!(out, "enum {name} : unsigned char {{").unwrap();
        for id in ids {
            writeln!(out, "    {prefix}_{},", id.to_uppercase()).unwrap();
        }
        writeln!(out, "    {prefix}_COUNT\n}};\n").unwrap();
    };
    let page_ids: Vec<&str> = view.pages.iter().map(|p| p.id.as_str()).collect();
    let group_ids: Vec<&str> = view.groups.iter().map(|(_, g)| g.id.as_str()).collect();
    let setting_ids: Vec<&str> = view.settings.iter().map(|(_, _, s)| s.id.as_str()).collect();
    enumeration(&mut out, "PeSettingsPage", "PE_SETTINGS_PAGE", &page_ids);
    enumeration(&mut out, "PeSettingsGroup", "PE_SETTINGS_GROUP", &group_ids);
    enumeration(&mut out, "PeSetting", "PE_SETTING", &setting_ids);
    out.push_str(
        "// a check box, a list with its label, or a button that opens a window or acts at once\n\
         enum PeSettingKind : unsigned char {\n    PE_SETTING_KIND_SWITCH,\n    PE_SETTING_KIND_CHOICE,\n    \
         PE_SETTING_KIND_BUTTON,\n};\n\n\
         struct PeSettingsPageInfo {\n    PeSettingsPage page;\n    PeText label;\n};\n\n\
         // titled false: no title of its own (the page's one group), label is then the page's\n\
         struct PeSettingsGroupInfo {\n    PeSettingsGroup group;\n    PeSettingsPage page;\n    bool titled;\n    \
         PeText label;\n    bool hasNote;\n    PeText note;\n};\n\n\
         // label: & marks the access key, unique within its page with OK, Cancel and Apply. dependsOn: a check box \
         this one is\n// disabled while it is clear, when hasParent\n\
         struct PeSettingInfo {\n    PeSetting setting;\n    PeSettingsGroup group;\n    PeSettingsPage page;\n    \
         PeSettingKind kind;\n    PeText label;\n    bool hasNote;\n    PeText note;\n    bool hasParent;\n    \
         PeSetting dependsOn;\n};\n\n",
    );
    out.push_str("inline constexpr PeSettingsPageInfo kSettingsPages[PE_SETTINGS_PAGE_COUNT] = {\n");
    for page in &view.pages {
        writeln!(
            out,
            "    {{PE_SETTINGS_PAGE_{}, {}}},",
            page.id.to_uppercase(),
            c_text(&page.label)
        )
        .unwrap();
    }
    out.push_str("};\n\ninline constexpr PeSettingsGroupInfo kSettingsGroups[PE_SETTINGS_GROUP_COUNT] = {\n");
    for (page, group) in &view.groups {
        let label = group.label.as_ref().unwrap_or(&page.label);
        let note = group.note.as_ref().unwrap_or(label);
        writeln!(
            out,
            "    {{PE_SETTINGS_GROUP_{}, PE_SETTINGS_PAGE_{}, {}, {}, {}, {}}},",
            group.id.to_uppercase(),
            page.id.to_uppercase(),
            group.label.is_some(),
            c_text(label),
            group.note.is_some(),
            c_text(note)
        )
        .unwrap();
    }
    out.push_str("};\n\ninline constexpr PeSettingInfo kSettings[PE_SETTING_COUNT] = {\n");
    for (page, group, setting) in &view.settings {
        let note = setting.note.as_ref().unwrap_or(&setting.label);
        let parent = setting.depends_on.as_ref().unwrap_or(&setting.id);
        writeln!(
            out,
            "    {{PE_SETTING_{}, PE_SETTINGS_GROUP_{}, PE_SETTINGS_PAGE_{}, PE_SETTING_KIND_{}, {}, {}, {}, {}, \
             PE_SETTING_{}}},",
            setting.id.to_uppercase(),
            group.id.to_uppercase(),
            page.id.to_uppercase(),
            setting.kind.to_uppercase(),
            c_text(&setting.label),
            setting.note.is_some(),
            c_text(note),
            setting.depends_on.is_some(),
            parent.to_uppercase()
        )
        .unwrap();
    }
    out.push_str("};\n");
    out
}

/// A Swift switch over `items`: `case .<name>: return <value>`
fn swift_switch<T>(out: &mut String, items: &[T], name: impl Fn(&T) -> String, value: impl Fn(&T) -> String) {
    out.push_str("        switch self {\n");
    for item in items {
        writeln!(out, "        case .{}: return {}", name(item), value(item)).unwrap();
    }
    out.push_str("        }\n    }\n");
}

fn swift_text(id: Option<&String>) -> String {
    id.map_or("nil".to_string(), |id| format!(".{}", text_case(id, false)))
}

/// A Swift array of cases: `[.a, .b]`
fn swift_list(ids: impl Iterator<Item = String>) -> String {
    format!(
        "[{}]",
        ids.map(|id| format!(".{}", camel(&id, false)))
            .collect::<Vec<_>>()
            .join(", ")
    )
}

fn swift(view: &View) -> String {
    let mut out = format!("// {NOTE}\n\n");
    swift_pages(&mut out, view);
    swift_groups(&mut out, view);
    swift_settings(&mut out, view);
    out
}

fn swift_pages(out: &mut String, view: &View) {
    let case = |p: &&Page| camel(&p.id, false);
    out.push_str(
        "/// A pane of the settings window, in the order of its toolbar\nenum SettingsPage: String, CaseIterable {\n",
    );
    for page in &view.pages {
        writeln!(out, "    case {} = \"{}\"", case(page), page.id).unwrap();
    }
    out.push_str(
        "\n    /// Its toolbar item's label and the window's title while it is shown\n    var label: Text {\n",
    );
    swift_switch(out, &view.pages, case, |p| swift_text(Some(&p.label)));
    out.push_str("\n    /// The SF Symbol of its toolbar item\n    var symbol: String {\n");
    swift_switch(out, &view.pages, case, |p| format!("\"{}\"", p.mac_symbol));
    out.push_str("\n    /// Its groups in order\n    var groups: [SettingsGroup] {\n");
    swift_switch(out, &view.pages, case, |p| {
        swift_list(p.groups(view.platform).map(|g| g.id.clone()))
    });
    out.push_str("}\n\n");
}

fn swift_groups(out: &mut String, view: &View) {
    let case = |g: &(&Page, &Group)| camel(&g.1.id, false);
    out.push_str("/// A group of a pane: set apart by space, its title in the label column on its first row\nenum SettingsGroup {\n");
    for group in &view.groups {
        writeln!(out, "    case {}", case(group)).unwrap();
    }
    out.push_str("\n    /// Its title, nil for none\n    var label: Text? {\n");
    swift_switch(out, &view.groups, case, |g| swift_text(g.1.label.as_ref()));
    out.push_str("\n    /// A note under the group, nil for none\n    var note: Text? {\n");
    swift_switch(out, &view.groups, case, |g| swift_text(g.1.note.as_ref()));
    out.push_str("\n    /// Its settings in order\n    var settings: [Setting] {\n");
    swift_switch(out, &view.groups, case, |g| {
        swift_list(g.1.settings(view.platform).map(|s| s.id.clone()))
    });
    out.push_str("}\n\n");
}

fn swift_settings(out: &mut String, view: &View) {
    let case = |s: &(&Page, &Group, &Setting)| camel(&s.2.id, false);
    out.push_str(
        "/// What a setting is: a check box, a pop-up with its label, or a push button\nenum SettingKind {\n    \
         case toggle, choice, button\n}\n\n/// A setting of the settings window\nenum Setting {\n",
    );
    for setting in &view.settings {
        writeln!(out, "    case {}", case(setting)).unwrap();
    }
    out.push_str("\n    var kind: SettingKind {\n");
    swift_switch(out, &view.settings, case, |s| {
        match s.2.kind.as_str() {
            "switch" => ".toggle",
            "choice" => ".choice",
            _ => ".button",
        }
        .to_string()
    });
    out.push_str("\n    /// Its label (a pop-up's ends with a colon)\n    var label: Text {\n");
    swift_switch(out, &view.settings, case, |s| swift_text(Some(&s.2.label)));
    out.push_str("\n    /// A note under it, nil for none\n    var note: Text? {\n");
    swift_switch(out, &view.settings, case, |s| swift_text(s.2.note.as_ref()));
    out.push_str(
        "\n    /// The check box it is disabled while it is clear, nil for none\n    var dependsOn: Setting? {\n",
    );
    swift_switch(out, &view.settings, case, |s| {
        s.2.depends_on
            .as_ref()
            .map_or("nil".to_string(), |p| format!(".{}", camel(p, false)))
    });
    out.push_str("}\n");
}

/// A Rust match over `items`: `Type::<name> => <value>,`
fn rust_match<T>(out: &mut String, ty: &str, items: &[T], name: impl Fn(&T) -> String, value: impl Fn(&T) -> String) {
    out.push_str("        match self {\n");
    for item in items {
        writeln!(out, "            {ty}::{} => {},", name(item), value(item)).unwrap();
    }
    out.push_str("        }\n    }\n");
}

fn rust_text(id: Option<&String>) -> String {
    id.map_or("None".to_string(), |id| format!("Some(Text::{})", text_case(id, true)))
}

/// A Rust slice of `ty`'s variants: `&[Ty::A, Ty::B]`
fn rust_list(ty: &str, ids: impl Iterator<Item = String>) -> String {
    format!(
        "&[{}]",
        ids.map(|id| format!("{ty}::{}", camel(&id, true)))
            .collect::<Vec<_>>()
            .join(", ")
    )
}

const RUST_DERIVE: &str = "#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash)]";

fn rust(view: &View) -> String {
    let mut out = format!("// {NOTE}\n\nuse pe_core::i18n::Text;\n\n");
    rust_pages(&mut out, view);
    rust_groups(&mut out, view);
    rust_settings(&mut out, view);
    out
}

fn rust_pages(out: &mut String, view: &View) {
    let ty = "SettingsPage";
    let case = |p: &&Page| camel(&p.id, true);
    writeln!(
        out,
        "/// A page of Preferences, in the order of its view switcher\n{RUST_DERIVE}\npub enum {ty} {{"
    )
    .unwrap();
    for page in &view.pages {
        writeln!(out, "    {},", case(page)).unwrap();
    }
    writeln!(out, "}}\n\nimpl {ty} {{").unwrap();
    writeln!(
        out,
        "    pub const ALL: &[{ty}] = {};\n",
        rust_list(ty, view.pages.iter().map(|p| p.id.clone()))
    )
    .unwrap();
    out.push_str(
        "    /// Its name as the dialog knows it (`set_visible_page_name`)\n    pub fn name(self) -> &'static str {\n",
    );
    rust_match(out, ty, &view.pages, case, |p| format!("\"{}\"", p.id));
    out.push_str("\n    /// Its title in the view switcher\n    pub fn text(self) -> Text {\n");
    rust_match(out, ty, &view.pages, case, |p| {
        format!("Text::{}", text_case(&p.label, true))
    });
    out.push_str("\n    /// The icon of its view switcher button\n    pub fn icon(self) -> &'static str {\n");
    rust_match(out, ty, &view.pages, case, |p| format!("\"{}\"", p.linux_icon));
    out.push_str("\n    /// Its groups in order\n    pub fn groups(self) -> &'static [SettingsGroup] {\n");
    rust_match(out, ty, &view.pages, case, |p| {
        rust_list("SettingsGroup", p.groups(view.platform).map(|g| g.id.clone()))
    });
    out.push_str("}\n\n");
}

fn rust_groups(out: &mut String, view: &View) {
    let ty = "SettingsGroup";
    let case = |g: &(&Page, &Group)| camel(&g.1.id, true);
    writeln!(
        out,
        "/// A group of a page (AdwPreferencesGroup)\n{RUST_DERIVE}\npub enum {ty} {{"
    )
    .unwrap();
    for group in &view.groups {
        writeln!(out, "    {},", case(group)).unwrap();
    }
    writeln!(out, "}}\n\nimpl {ty} {{").unwrap();
    out.push_str(
        "    /// Its title, None for the one group of a page, which the page titles\n    pub fn title(self) -> Option<Text> {\n",
    );
    rust_match(out, ty, &view.groups, case, |g| rust_text(g.1.label.as_ref()));
    out.push_str("\n    /// Its description, None for none\n    pub fn note(self) -> Option<Text> {\n");
    rust_match(out, ty, &view.groups, case, |g| rust_text(g.1.note.as_ref()));
    out.push_str("\n    /// Its settings in order\n    pub fn settings(self) -> &'static [Setting] {\n");
    rust_match(out, ty, &view.groups, case, |g| {
        rust_list("Setting", g.1.settings(view.platform).map(|s| s.id.clone()))
    });
    out.push_str("}\n\n");
}

fn rust_settings(out: &mut String, view: &View) {
    let ty = "Setting";
    let case = |s: &(&Page, &Group, &Setting)| camel(&s.2.id, true);
    writeln!(
        out,
        "/// What a setting is: a switch row, a choice row with its value as subtitle, or a button row\n{RUST_DERIVE}\n\
         pub enum SettingKind {{\n    Switch,\n    Choice,\n    Button,\n}}\n\n/// A setting of Preferences\n\
         {RUST_DERIVE}\npub enum {ty} {{"
    )
    .unwrap();
    for setting in &view.settings {
        writeln!(out, "    {},", case(setting)).unwrap();
    }
    writeln!(out, "}}\n\nimpl {ty} {{").unwrap();
    // not read yet: the Linux app names its widgets by it next
    out.push_str(
        "    /// Its name in code and the UI test (`codes_in_notifications`)\n    #[allow(dead_code)]\n    \
         pub fn name(self) -> &'static str {\n",
    );
    rust_match(out, ty, &view.settings, case, |s| format!("\"{}\"", s.2.id));
    out.push_str("\n    pub fn kind(self) -> SettingKind {\n");
    rust_match(out, ty, &view.settings, case, |s| {
        format!("SettingKind::{}", camel(&s.2.kind, true))
    });
    out.push_str(
        "\n    /// Its label: & marks Windows' access key, a list's ends with a colon (`field_title` takes both off)\n    \
         pub fn text(self) -> Text {\n",
    );
    rust_match(out, ty, &view.settings, case, |s| {
        format!("Text::{}", text_case(&s.2.label, true))
    });
    out.push_str(
        "\n    /// A note under it (the row's subtitle), None for none\n    pub fn note(self) -> Option<Text> {\n",
    );
    rust_match(out, ty, &view.settings, case, |s| rust_text(s.2.note.as_ref()));
    out.push_str(
        "\n    /// The switch it is insensitive while that is off, None for none\n    \
         pub fn depends_on(self) -> Option<Setting> {\n",
    );
    rust_match(out, ty, &view.settings, case, |s| {
        s.2.depends_on
            .as_ref()
            .map_or("None".to_string(), |p| format!("Some(Setting::{})", camel(p, true)))
    });
    out.push_str("}\n");
}

/// The whole table for pe-ffi's tests: PAGES (id, label), GROUPS (id, label or "") and SETTINGS (page, group, id,
/// kind, label, note or "", platforms), in order
fn test_table(table: &Table) -> String {
    let mut out = String::from("const PAGES: &[(&str, &str)] = &[\n");
    for page in &table.page {
        writeln!(out, "    ({:?}, {:?}),", page.id, page.label).unwrap();
    }
    out.push_str("];\n\nconst GROUPS: &[(&str, &str)] = &[\n");
    for group in table.page.iter().flat_map(|p| &p.group) {
        writeln!(out, "    ({:?}, {:?}),", group.id, group.label.as_deref().unwrap_or("")).unwrap();
    }
    out.push_str("];\n\n#[allow(clippy::type_complexity)]\nconst SETTINGS: &[(&str, &str, &str, &str, &str, &str, &[&str])] = &[\n");
    for page in &table.page {
        for group in &page.group {
            for setting in &group.setting {
                let platforms: Vec<&str> = PLATFORMS.iter().copied().filter(|p| setting.on(p)).collect();
                writeln!(
                    out,
                    "    ({:?}, {:?}, {:?}, {:?}, {:?}, {:?}, &{platforms:?}),",
                    page.id,
                    group.id,
                    setting.id,
                    setting.kind,
                    setting.label,
                    setting.note.as_deref().unwrap_or("")
                )
                .unwrap();
            }
        }
    }
    out.push_str("];\n");
    out
}
