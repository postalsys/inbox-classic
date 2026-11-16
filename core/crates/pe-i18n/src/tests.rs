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
#[ignore = "translation status, not a bug: scripts/release.sh runs it before a release"]
fn every_catalog_has_every_english_message() {
    // a message a language lacks is shown in English: a feature's words added in English must reach every catalog
    // (as drafts marked for review) before a release, or the windows mix languages
    let english: BTreeSet<String> = catalog("en").into_iter().map(|(id, _)| id).collect();
    for (code, _) in LANGUAGES {
        let has: BTreeSet<String> = catalog(code).into_iter().map(|(id, _)| id).collect();
        let missing: Vec<&String> = english.difference(&has).collect();
        assert!(
            missing.is_empty(),
            "{code} lacks {} English messages: {missing:?}",
            missing.len()
        );
    }
}

#[test]
fn a_message_a_catalog_lacks_is_in_english() {
    // a feature's words not translated yet: the window shows them in English, not their id
    let mut partial = Bundle::new_concurrent(vec![locale("de").parse().unwrap_or_default()]);
    partial.set_use_isolating(false);
    let _ = partial.add_resource(FluentResource::try_new("menu-file = &Datei\n".to_string()).expect("parses"));
    assert_eq!(or_english(&partial, "menu-file", &[]).as_deref(), Some("&Datei"));
    assert_eq!(
        or_english(&partial, "cmd-mark-read", &[]).as_deref(),
        Some("Mark as &Read")
    );
    assert_eq!(
        or_english(&partial, "messages", &[("count", 2u64.into())]).as_deref(),
        Some("2 messages")
    );
    assert_eq!(or_english(&partial, "no-such-message", &[]), None);
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
fn chooses_by_region_and_script() {
    // Brazil's Portuguese for Brazil, Portugal's for every other Portuguese
    for tag in ["pt-BR", "pt_BR", "pt_BR.UTF-8", "PT-br", "pt-Latn-BR", "pt_BR@euro"] {
        assert_eq!(supported(tag), Some("pt-BR"), "{tag}");
    }
    for tag in ["pt", "pt-PT", "pt_PT.UTF-8", "pt-AO", "pt-MZ", "PT"] {
        assert_eq!(supported(tag), Some("pt"), "{tag}");
    }
    // Serbian in Latin script, whichever script the system writes
    for tag in [
        "sr",
        "sr-RS",
        "sr-Cyrl",
        "sr-Cyrl-RS",
        "sr-Latn",
        "sr-Latn-RS",
        "sr_RS.UTF-8",
        "sr_RS@latin",
        "SR-LATN-ME",
    ] {
        assert_eq!(supported(tag), Some("sr-Latn"), "{tag}");
    }
    // Norwegian is Bokmål; Nynorsk is a language of its own there is no catalog of
    for tag in ["no", "nb", "nb-NO", "nb_NO.UTF-8", "no_NO", "NB"] {
        assert_eq!(supported(tag), Some("nb"), "{tag}");
    }
    assert_eq!(supported("nn-NO"), None);
    assert_eq!(supported("tr-TR"), Some("tr"));
    assert_eq!(supported("ca-ES-valencia"), Some("ca"));
    assert_eq!(supported("ca_AD.UTF-8"), Some("ca"));
    // the codes of the list are themselves
    for (code, _) in LANGUAGES {
        assert_eq!(supported(code), Some(*code));
    }
    assert_eq!(resolve(&["ja-JP", "pt-BR", "pt-PT"]), "pt-BR");
    assert_eq!(resolve(&["pt-PT", "pt-BR"]), "pt");
    assert_eq!(resolve(&["sr-Cyrl-RS", "en"]), "sr-Latn");
    assert_eq!(resolve(&["nn", "no", "en"]), "nb");
}

#[test]
fn tags_as_gettext_writes_them() {
    assert_eq!(gettext_locale("pt-BR"), "pt_BR");
    assert_eq!(gettext_locale("sr-Latn"), "sr@latin");
    assert_eq!(gettext_locale("sr-Latn-RS"), "sr_RS@latin");
    assert_eq!(gettext_locale("sr-Cyrl"), "sr@cyrillic");
    assert_eq!(gettext_locale("nb"), "nb");
    assert_eq!(gettext_locale("de"), "de");
}

/// The CLDR plural category of `n` in the catalog of `code`, as its bundle picks it
fn category(code: &str, n: i64) -> String {
    let tag: unic_langid::LanguageIdentifier = locale(code).parse().unwrap();
    let mut bundle = Bundle::new_concurrent(vec![tag]);
    let resource = FluentResource::try_new(
        "c = { $n ->\n [zero] zero\n [one] one\n [two] two\n [few] few\n [many] many\n *[other] other\n}\n".into(),
    )
    .unwrap();
    bundle.add_resource(resource).unwrap();
    format(&bundle, "c", &[("n", Arg::Num(n))]).unwrap()
}

#[test]
fn plurals_follow_cldr() {
    let categories = |code: &str, numbers: &[i64]| numbers.iter().map(|n| category(code, *n)).collect::<Vec<_>>();
    // Brazil's `one` takes 0 and 1 (CLDR's pt), Portugal's only 1 (pt-PT)
    assert_eq!(categories("pt-BR", &[0, 1, 2]), ["one", "one", "other"]);
    assert_eq!(categories("pt", &[0, 1, 2]), ["other", "one", "other"]);
    for code in ["tr", "nb", "ca"] {
        assert_eq!(
            categories(code, &[0, 1, 2, 5]),
            ["other", "one", "other", "other"],
            "{code}"
        );
    }
    // Serbian by the last digits, as Croatian
    assert_eq!(
        categories("sr-Latn", &[1, 2, 5, 11, 21, 22, 25]),
        ["one", "few", "other", "other", "one", "few", "other"]
    );
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
fn the_list_of_languages() {
    assert_eq!(LANGUAGES[0].0, "en", "English first");
    for (code, _) in LANGUAGES {
        // the language's two letters, then a script or a region, nothing else
        let tag = Tag::parse(code);
        assert!(
            tag.language.len() == 2 && tag.language.bytes().all(|b| b.is_ascii_lowercase()),
            "{code}: the language's two letters"
        );
        let rebuilt: Vec<&str> = [Some(tag.language), tag.script, tag.region]
            .into_iter()
            .flatten()
            .collect();
        assert_eq!(
            rebuilt.join("-"),
            *code,
            "{code}: a script or a region after the language"
        );
        assert!(
            CATALOGS.iter().any(|(c, _)| c == code),
            "{code}: a catalog in core/locales/{code}"
        );
    }
}

#[test]
fn tags_in_their_parts() {
    let tag = Tag::parse("sr-Latn-RS");
    assert_eq!((tag.language, tag.script, tag.region), ("sr", Some("Latn"), Some("RS")));
    let tag = Tag::parse("es_419");
    assert_eq!((tag.language, tag.script, tag.region), ("es", None, Some("419")));
    let tag = Tag::parse("ca-ES-valencia");
    assert_eq!((tag.language, tag.script, tag.region), ("ca", None, Some("ES")));
    assert_eq!(date_locale("de", Some("EE")), "de_EE");
    assert_eq!(date_locale("de", None), "de");
    assert_eq!(date_locale("pt-BR", Some("US")), "pt_BR");
    assert_eq!(date_locale("sr-Latn", Some("RS")), "sr_Latn_RS");
    assert_eq!(date_locale(PSEUDO, Some("EE")), "en_EE");
    assert_eq!(
        picture_resource("brands/google-sign-in.pt-BR.png"),
        "GOOGLE_SIGN_IN_PT_BR"
    );
    assert_eq!(picture_resource("brands/microsoft-sign-in.png"), "MICROSOFT_SIGN_IN");
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

#[test]
fn portuguese_plurals_follow_portugal() {
    // pt-PT: only 1 is `one`, so no catalog needs a `[0]` branch to say "0 mensagens"
    let selected = |count: u64| translated("pt", "selection-title", &[("count", count.into())]);
    assert_eq!(selected(0).as_deref(), Some("0 mensagens selecionadas"));
    assert_eq!(selected(1).as_deref(), Some("1 mensagem selecionada"));
    assert_eq!(selected(2).as_deref(), Some("2 mensagens selecionadas"));
}
