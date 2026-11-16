use std::collections::BTreeSet;

use super::*;

/// The ids and the variables each message uses, of one language's files
fn catalog(code: &str) -> Vec<(String, BTreeSet<String>)> {
    let (_, files) = CATALOGS.iter().find(|(c, _)| *c == code).expect("a catalog");
    let mut messages = Vec::new();
    for file in *files {
        let resource = match FluentResource::try_new(file.to_string()) {
            Ok(resource) => resource,
            Err((_, errors)) => panic!("{code}: the catalog does not parse: {errors:?}"),
        };
        for entry in resource.entries() {
            if let fluent_syntax::ast::Entry::Message(message) = entry {
                let id = message.id.name.to_string();
                messages.push((id, variables(file, message.id.name)));
            }
        }
    }
    messages
}

/// The `$variables` of message `id` in the file `text`, read from its lines
fn variables(text: &str, id: &str) -> BTreeSet<String> {
    let mut found = BTreeSet::new();
    let mut inside = false;
    for line in text.lines() {
        if line.starts_with(&format!("{id} =")) {
            inside = true;
        } else if inside && !line.starts_with([' ', '}']) && !line.is_empty() {
            break;
        }
        if inside {
            let mut rest = line;
            while let Some(at) = rest.find('$') {
                let name: String = rest[at + 1..]
                    .chars()
                    .take_while(|c| c.is_ascii_alphanumeric() || *c == '_' || *c == '-')
                    .collect();
                found.insert(name);
                rest = &rest[at + 1..];
            }
        }
    }
    found
}

#[test]
fn every_catalog_matches_english() {
    let english = catalog("en");
    assert_eq!(english.len(), IDS.len());
    for (code, _) in LANGUAGES {
        let messages = catalog(code);
        let mut seen = BTreeSet::new();
        for (id, vars) in &messages {
            assert!(seen.insert(id.clone()), "{code}: {id} is there twice");
            let Some((_, english_vars)) = english.iter().find(|(e, _)| e == id) else {
                panic!("{code}: {id} is not in the English catalog");
            };
            assert_eq!(vars, english_vars, "{code}: {id} uses other variables than in English");
        }
    }
}

#[test]
fn no_dashes_in_any_catalog() {
    // the house style: commas and sentences, never an en or em dash
    for (code, files) in CATALOGS {
        for file in *files {
            assert!(
                !file.contains(['\u{2013}', '\u{2014}']),
                "{code}: a dash in the catalog"
            );
        }
    }
}

#[test]
fn chooses_the_language() {
    assert_eq!(supported("de-AT"), Some("de"));
    assert_eq!(supported("et_EE.UTF-8"), Some("et"));
    assert_eq!(supported("FR"), Some("fr"));
    assert_eq!(supported("ja-JP"), None);
    assert_eq!(supported("qps"), Some(PSEUDO));
    assert_eq!(resolve(&["ja-JP", "es-419", "en"]), "es");
    assert_eq!(resolve::<&str>(&[]), "en");
    assert_eq!(resolve(&["qps", "ja"]), "en");
}

#[test]
fn mnemonics() {
    assert_eq!(without_mnemonic("&Reply to Sender"), "Reply to Sender");
    assert_eq!(without_mnemonic("Q&&A"), "Q&A");
    assert_eq!(gtk_mnemonic("&Reply to_all"), "_Reply to__all");
    assert_eq!(gtk_mnemonic("Q&&A"), "Q&A");
}

#[test]
fn pseudo_is_longer_and_bracketed() {
    let text = pseudo("Move to Folder");
    assert!(text.starts_with("[Mövé") && text.ends_with(']'), "{text}");
    assert!(text.chars().count() as f64 >= "Move to Folder".len() as f64 * 1.3);
    assert_eq!(pseudo(""), "[]");
}

#[test]
fn words_in_the_language_set() {
    // one test changes the language, so they run in one go
    set_language("en");
    assert_eq!(tr_args(Text::Messages, &[("count", 1u64.into())]), "1 message");
    assert_eq!(tr_args(Text::Messages, &[("count", 3u64.into())]), "3 messages");
    // a command as the title of the window it opens
    assert_eq!(title(Text::CmdImport), "Import Messages");
    assert_eq!(title(Text::CmdReply), "Reply to Sender");
    assert_eq!(set_language("de-CH"), "de");
    assert_eq!(
        localized_picture("brands/google-sign-in.png"),
        "brands/google-sign-in.de.png"
    );
    assert_eq!(language(), "de");
    assert_eq!(tr_args(Text::Messages, &[("count", 3u64.into())]), "3 Nachrichten");
    set_language("fr");
    // French's singular branch includes zero: it must show the supplied count, not a literal 1.
    for count in [0u64, 1, 2] {
        for text in [Text::UiRuleCount, Text::UiRulesApplied, Text::SendDelaySeconds] {
            let rendered = tr_args(text, &[("count", count.into())]);
            assert!(rendered.starts_with(&format!("{count} ")), "{rendered}");
        }
        let countdown = tr_args(
            Text::UiSendingIn,
            &[("subject", "Test".into()), ("count", count.into())],
        );
        assert!(countdown.contains(&format!("dans {count} seconde")), "{countdown}");
    }
    set_language("qps");
    assert!(tr_args(Text::Messages, &[("count", 3u64.into())]).starts_with("[3 "));
    // the words made over, not what goes into them: an account's name stays as the user wrote it
    let asked = tr_args(Text::UiEnterPassword, &[("account", "inboxclassic.test".into())]);
    assert!(
        asked.contains("inboxclassic.test") && asked.starts_with("[Éñ"),
        "{asked}"
    );
    assert_eq!(
        localized_picture("brands/google-sign-in.png"),
        "brands/google-sign-in.png"
    );
    // the dots off a title before the pseudo-language's padding too
    let options = title(Text::CmdOptions);
    assert!(
        options.starts_with("[Ö") && options.ends_with("~]") && !options.contains("..."),
        "{options}"
    );
    assert_eq!(set_language("xx"), "en");
    assert_eq!(tr_args(Text::Messages, &[("count", 2u64.into())]), "2 messages");
}

#[test]
fn a_message_by_its_id_in_a_language() {
    assert_eq!(
        message_in("de", "cmd-mark-read").as_deref(),
        Some("Als &gelesen markieren")
    );
    assert_eq!(message_in("xx", "cmd-mark-read").as_deref(), Some("Mark as &Read"));
    assert_eq!(message_in("en", "no-such-message"), None);
}

#[test]
fn the_scripts_read_the_list_of_languages() {
    // scripts/languages.sh (and ui-e2e.ps1) read LANGUAGES from this file, one `    ("code", "Name"),` a line
    let source = include_str!("lib.rs");
    let start = source.find("pub const LANGUAGES").expect("the list");
    let end = start + source[start..].find("\n];").expect("its end");
    let read: Vec<(String, String)> = source[start..end]
        .lines()
        .filter_map(|line| {
            let rest = line.strip_prefix("    (\"")?.strip_suffix("\"),")?;
            let (code, name) = rest.split_once("\", \"")?;
            Some((code.to_string(), name.to_string()))
        })
        .collect();
    let listed: Vec<(String, String)> = LANGUAGES
        .iter()
        .map(|(code, name)| (code.to_string(), name.to_string()))
        .collect();
    assert_eq!(read, listed, "one language a line, as scripts/languages.sh reads them");
    assert_eq!(LANGUAGES[0].0, "en", "English first");
    for (code, _) in LANGUAGES {
        assert!(
            code.len() == 2 && code.bytes().all(|b| b.is_ascii_lowercase()),
            "{code}: a two-letter code, as the pictures and scripts take it"
        );
        assert!(
            CATALOGS.iter().any(|(c, _)| c == code),
            "{code}: a catalog in core/locales/{code}"
        );
    }
}

#[test]
fn translated_only_from_the_language_itself() {
    assert_eq!(translated("de", "menu-file", &[]).as_deref(), Some("&Datei"));
    assert_eq!(translated("en", "menu-file", &[]).as_deref(), Some("&File"));
    assert_eq!(translated("de", "no-such-message", &[]), None);
    assert_eq!(translated("ja", "menu-file", &[]), None);
    assert_eq!(translated(PSEUDO, "menu-file", &[]), None);
    assert_eq!(
        translated("en", "messages", &[("count", 2u64.into())]).as_deref(),
        Some("2 messages")
    );
}
