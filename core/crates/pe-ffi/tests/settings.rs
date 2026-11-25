//! The settings window of core/settings.toml as build.rs reads it: what the three apps are generated from
use std::collections::HashMap;

include!(concat!(env!("OUT_DIR"), "/settings_table.rs"));

fn on(platform: &str) -> impl Iterator<Item = &'static str> + '_ {
    SETTINGS.iter().filter(move |s| s.6.contains(&platform)).map(|s| s.2)
}

/// The settings only some platforms have: Windows is always light, so no dark messages there; the Mac's own updates
#[test]
fn some_settings_are_on_some_platforms() {
    assert!(!on("windows").any(|id| id == "dark_messages"));
    assert!(on("linux").any(|id| id == "dark_messages"));
    assert!(on("mac").any(|id| id == "check_for_updates"));
    assert!(!on("linux").any(|id| id == "check_for_updates"));
}

/// A group's title is a heading of its own in every language, never a field's label: no access key, no colon, so no
/// app takes anything off it
#[test]
fn group_titles_are_headings_in_every_language() {
    let mut problems = Vec::new();
    for (language, _) in pe_i18n::LANGUAGES {
        for (group, id) in GROUPS.iter().filter(|g| !g.1.is_empty()) {
            let text = pe_i18n::message_in(language, id).unwrap();
            if text.contains('&') || text.trim_end().ends_with([':', '\u{ff1a}']) {
                problems.push(format!(
                    "{language}: the {group} group's {id} is a field's label: {text}"
                ));
            }
        }
    }
    assert!(problems.is_empty(), "{}", problems.join("\n"));
}

#[test]
fn the_pages_are_general_reading_downloading_sync() {
    let pages: Vec<&str> = PAGES.iter().map(|p| p.0).collect();
    assert_eq!(pages, ["general", "reading", "downloading", "sync"]);
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
                // a line of state is a label, not a control: no access key
                .filter(|s| s.0 == *page && s.6.contains(&"windows") && s.3 != "status")
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
