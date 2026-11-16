//! The settings window of core/settings.toml as build.rs reads it: what the three apps are generated from
use std::collections::HashMap;

include!(concat!(env!("OUT_DIR"), "/settings_table.rs"));

const ROOT: &str = concat!(env!("CARGO_MANIFEST_DIR"), "/../../..");

/// The names of a generated file in order from `from` on: what follows each `prefix` up to the first character that
/// cannot be in a name
fn names(file: &str, from: &str, prefix: &str) -> Vec<String> {
    let text = std::fs::read_to_string(format!("{ROOT}/{file}")).unwrap();
    let at = text.find(from).unwrap_or_else(|| panic!("{file} has no {from}"));
    text[at..]
        .split(prefix)
        .skip(1)
        .map(|rest| {
            rest.chars()
                .take_while(|c| c.is_ascii_alphanumeric() || *c == '_')
                .collect()
        })
        .collect()
}

fn camel(id: &str, upper_first: bool) -> String {
    id.split('_')
        .enumerate()
        .map(|(i, word)| {
            let mut chars = word.chars();
            let first = chars.next().map(|c| {
                if i == 0 && !upper_first {
                    c.to_string()
                } else {
                    c.to_uppercase().to_string()
                }
            });
            first.unwrap_or_default() + chars.as_str()
        })
        .collect()
}

fn on(platform: &str) -> impl Iterator<Item = &'static str> + '_ {
    SETTINGS.iter().filter(move |s| s.6.contains(&platform)).map(|s| s.2)
}

/// Each platform's file lists its settings, and only those, in the order of the table
#[test]
fn every_platform_has_its_settings_in_order() {
    let windows: Vec<String> = on("windows").map(|id| id.to_uppercase()).collect();
    let mut c = names("core/include/settings.h", "enum PeSetting :", "    PE_SETTING_");
    c.truncate(c.iter().position(|n| n == "COUNT").unwrap());
    assert_eq!(c, windows);

    let mac: Vec<String> = on("mac").map(|id| camel(id, false)).collect();
    // the last enum of the file: its cases are the last at that indent
    let swift = names(
        "mac/Sources/InboxClassic/Generated/SettingsPages.swift",
        "enum Setting:",
        "\n    case ",
    );
    assert_eq!(swift, mac);

    let linux: Vec<String> = on("linux").map(|id| camel(id, true)).collect();
    let rust = names(
        "linux/src/generated/settings_pages.rs",
        "pub const ALL: &[Setting]",
        "Setting::",
    );
    assert_eq!(&rust[..linux.len()], &linux[..]);
    // the list ends there: next is the first arm of a match, a whole list again
    assert_eq!(rust[linux.len()], linux[0]);

    // Windows always light, so no dark messages there; the Mac's own updates
    assert!(!on("windows").any(|id| id == "dark_messages"));
    assert!(on("linux").any(|id| id == "dark_messages"));
    assert!(on("mac").any(|id| id == "check_for_updates"));
    assert!(!on("linux").any(|id| id == "check_for_updates"));
}

#[test]
fn the_pages_are_general_reading_downloading() {
    let pages: Vec<&str> = PAGES.iter().map(|p| p.0).collect();
    assert_eq!(pages, ["general", "reading", "downloading"]);
    assert_eq!(
        pe_i18n::message_in("en", "ui-download-heading").as_deref(),
        Some("Downloading")
    );
}

/// The access key (&) of a label, lower case; None for none
fn access_key(label: &str) -> Option<String> {
    let label = label.replace("&&", "");
    let at = label.find('&')?;
    label[at + 1..].chars().next().map(|c| c.to_lowercase().collect())
}

/// On each Windows page, the controls' access keys and Apply's are different in every language: Alt and a letter
/// reaches one control. A translation that gives two the same letter fails here.
#[test]
fn the_access_keys_of_each_windows_page_are_unique_in_every_language() {
    let mut problems = Vec::new();
    for (language, _) in pe_i18n::LANGUAGES {
        for (page, _) in PAGES {
            let labels = SETTINGS
                .iter()
                .filter(|s| s.0 == *page && s.6.contains(&"windows"))
                .map(|s| s.4)
                .chain(["ui-apply", "ui-ok", "ui-cancel"]);
            let mut keys: HashMap<String, &str> = HashMap::new();
            for id in labels {
                let text = pe_i18n::message_in(language, id).unwrap();
                let Some(key) = access_key(&text) else {
                    if !["ui-ok", "ui-cancel"].contains(&id) {
                        problems.push(format!("{language}: {id} has no access key: {text}"));
                    }
                    continue;
                };
                if let Some(other) = keys.insert(key.clone(), id) {
                    problems.push(format!(
                        "{language}: {other} and {id} both have {key} on the {page} page"
                    ));
                }
            }
        }
    }
    assert!(problems.is_empty(), "{}", problems.join("\n"));
}
