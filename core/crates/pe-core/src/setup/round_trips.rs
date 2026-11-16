//! Setup files written from one store and imported into another, as the windows do it: every part with and without
//! a passphrase, a wrong passphrase, a changed byte, partial imports, what is here already, rules whose folders come
//! later, and the user's own keys working in the second store. Passwords live in memory only.

use pe_oauth::{Endpoint, Provider, ProviderKind};
use pe_store::{AccountId, AccountSettings, Auth, Card, FolderInfo, Group, Member, Rule, Security, SignInApp};
use pe_testkit::TempDir;

use super::*;
use crate::secrets::Key;
use crate::{Core, Options, PasswordStore};

const PASSPHRASE: &str = "correct horse battery";

/// A core of its own in `dir`, Google's client at a port of this computer that answers nothing
fn opened(dir: &TempDir) -> Core {
    let mut google = Provider::builtin(ProviderKind::Google);
    let nowhere = |security| Endpoint {
        host: "127.0.0.1".into(),
        port: 9,
        security,
    };
    google.imap = nowhere(pe_net::Security::Tls);
    google.smtp = nowhere(pe_net::Security::Tls);
    google.token_url = "http://127.0.0.1:9/token".into();
    let options = Options {
        passwords: PasswordStore::Memory,
        oauth_providers: vec![google],
        ..Default::default()
    };
    Core::open_with(dir.path().join("store.db"), options, |_| {}).unwrap()
}

fn settings(email: &str) -> AccountSettings {
    AccountSettings {
        name: "Ann Example".into(),
        email: email.into(),
        username: email.into(),
        imap_host: "127.0.0.1".into(),
        imap_port: 9,
        imap_security: Security::Tls,
        smtp_host: "127.0.0.1".into(),
        smtp_port: 9,
        smtp_security: Security::StartTls,
        auth: Auth::Password,
    }
}

fn folder(path: &str) -> FolderInfo {
    FolderInfo {
        path: path.into(),
        name: path.rsplit('/').next().unwrap().into(),
        delimiter: Some("/".into()),
        subscribed: true,
        selectable: true,
        ..Default::default()
    }
}

/// What the first store holds
struct Filled {
    ann: AccountId,
    own_key: String,
    contact_key: String,
}

/// A store with something in every part: three accounts (a password, Google, a sign-in app), settings, contacts with a
/// picture and a group, an own key and a contact's verified key, two rules and two trusted senders
fn fill(core: &Core) -> Filled {
    let ann = core.add_account(&settings("ann@example.com"), "ann-pw").unwrap();
    core.set_account_name(ann, "Work").unwrap();
    core.set_signature(ann, "<p>Ann <b>Example</b></p>").unwrap();
    core.set_account_addresses_text(ann, "Ann Two <ann2@example.com>")
        .unwrap();
    {
        let store = core.store();
        let bob = AccountSettings {
            auth: Auth::OAuth2("google".into()),
            ..settings("bob@gmail.example")
        };
        let bob = store.add_account(&bob).unwrap();
        core.secrets.set(bob, "refresh-r1").unwrap();
        let app = store
            .add_sign_in_app(&SignInApp {
                name: "Acme".into(),
                issuer: "https://login.acme.example".into(),
                client_id: "acme-client".into(),
                has_secret: true,
                scopes: "openid email".into(),
                authorize_url: "https://login.acme.example/authorize".into(),
                token_url: "https://login.acme.example/token".into(),
                response_issuer: None,
                imap_host: "127.0.0.1".into(),
                imap_port: 9,
                imap_security: Security::Tls,
                smtp_host: "127.0.0.1".into(),
                smtp_port: 9,
                smtp_security: Security::Tls,
                enabled: true,
            })
            .unwrap();
        core.secrets.set(Key::App(app), "client-secret").unwrap();
        let carol = AccountSettings {
            auth: Auth::OAuth2(pe_store::app_provider(app)),
            ..settings("carol@acme.example")
        };
        let carol = store.add_account(&carol).unwrap();
        core.secrets.set(carol, "refresh-c1").unwrap();
        store.set_builtin_sign_in_enabled("google", true).unwrap();
        store
            .set_folders(ann, &[folder("INBOX"), folder("Lists"), folder("Lists/News")])
            .unwrap();
    }
    core.set_text_size(0).unwrap();
    core.set_download_ahead(pe_store::Ahead::All).unwrap();
    core.set_download_limit_mb(500).unwrap();
    core.set_always_load_pictures(true).unwrap();
    core.set_pgp_keyserver(false).unwrap();
    core.set_send_delay(20).unwrap();
    core.set_dark_messages(false).unwrap();

    let dave = core
        .save_card(&Card {
            name: "Dave Example".into(),
            addresses: vec!["dave@example.net".into()],
            phones: vec![("cell".into(), "+1 555 0100".into())],
            ..Default::default()
        })
        .unwrap();
    let png = crate::card_pictures::normalize(&crate::card_pictures::tests::png(8, 8)).unwrap();
    core.set_card_picture_png(dave, &png).unwrap();
    core.save_card(&Card {
        name: "Eve".into(),
        addresses: vec!["eve@example.org".into()],
        ..Default::default()
    })
    .unwrap();
    core.save_group(&Group {
        id: 0,
        name: "Friends".into(),
        members: vec![
            Member {
                card: Some(dave),
                ..Default::default()
            },
            Member {
                card: None,
                name: "Frank".into(),
                address: "frank@example.org".into(),
            },
        ],
    })
    .unwrap();

    let own_key = core.pgp_generate(ann).unwrap();
    let now = crate::worker::unix_now();
    let dave_key = pe_pgp::generate("Dave", &["dave@example.net".into()], now).unwrap();
    let imported = core
        .pgp_import(dave_key.cert().armored().as_bytes(), None, crate::keys::KeySource::File)
        .unwrap();
    let contact_key = imported.keys[0].clone();
    core.pgp_set_key_verified(&contact_key, true).unwrap();

    let news = core.store().find_folder(ann, "Lists/News").unwrap().unwrap().id;
    core.save_rule(&Rule {
        enabled: true,
        name: "News".into(),
        account: Some(ann),
        query: "list:news.example".into(),
        move_to: Some(news),
        ..Default::default()
    })
    .unwrap();
    core.save_rule(&Rule {
        enabled: false,
        name: "".into(),
        query: "from:shop.example".into(),
        mark_read: true,
        flag: true,
        ..Default::default()
    })
    .unwrap();
    core.trust_sender("shop.example", true).unwrap();
    core.trust_sender("a@b.example", false).unwrap();
    Filled {
        ann,
        own_key,
        contact_key,
    }
}

fn prefs() -> Vec<(String, String)> {
    vec![
        ("layout".into(), "2".into()),
        ("hide_read".into(), "1".into()),
        ("language".into(), "de".into()),
        ("TreeWidth".into(), "300".into()),
        ("folder_list".into(), "maybe".into()),
    ]
}

fn everything(file: &SetupFile) -> ImportChoice {
    ImportChoice {
        parts: Parts::ALL,
        accounts: file.accounts.iter().map(|account| account.index).collect(),
    }
}

fn account_of(core: &Core, email: &str) -> pe_store::Account {
    core.accounts()
        .unwrap()
        .into_iter()
        .find(|account| account.settings.email == email)
        .unwrap()
}

#[test]
fn every_part_round_trips_without_a_passphrase() {
    let (dir_a, dir_b) = (TempDir::new("setup-a"), TempDir::new("setup-b"));
    let (a, b) = (opened(&dir_a), opened(&dir_b));
    let filled = fill(&a);
    let path = dir_a.path().join("Ann.inboxclassic");
    let lines = a.export_setup(&path, Parts::ALL, None, &prefs()).unwrap();
    assert_eq!(lines.len(), 8, "{lines:?}");
    let bytes = std::fs::read(&path).unwrap();
    let text = String::from_utf8(bytes).unwrap();
    for secret in ["ann-pw", "refresh-r1", "refresh-c1", "client-secret"] {
        assert!(!text.contains(secret), "{secret} in a file without a passphrase");
    }
    #[cfg(unix)]
    {
        use std::os::unix::fs::PermissionsExt;
        assert_eq!(std::fs::metadata(&path).unwrap().permissions().mode() & 0o777, 0o600);
    }

    let file = b.read_setup(&path, None).unwrap();
    assert!(!file.encrypted);
    assert_eq!(file.app_version, crate::VERSION);
    assert_eq!(file.parts, Parts::ALL);
    let counts = file.counts;
    assert_eq!(
        (counts.accounts, counts.sign_in_apps, counts.contacts, counts.groups),
        (3, 1, 2, 1)
    );
    assert_eq!(
        (
            counts.own_keys,
            counts.contact_keys,
            counts.rules,
            counts.trusted_senders
        ),
        (0, 1, 2, 2)
    );
    assert_eq!(counts.settings, 7);
    assert_eq!(
        file.prefs,
        [
            ("hide_read".to_string(), "1".to_string()),
            ("language".to_string(), "de".to_string()),
            ("layout".to_string(), "2".to_string())
        ]
    );
    let ann_row = &file.accounts[0];
    assert_eq!(
        (ann_row.email.as_str(), ann_row.title.as_str(), ann_row.imap.as_str()),
        ("ann@example.com", "Work", "127.0.0.1:9")
    );
    assert!(!ann_row.here && !ann_row.has_secret && ann_row.problem.is_none());
    assert_eq!(ann_row.note, tr(Text::SetupAccountAsksPassword));
    assert_eq!(file.accounts[1].sign_in, "Inbox Classic for Google");
    assert_eq!(file.accounts[1].note, tr(Text::SetupAccountSignsInAgain));
    assert_eq!(file.accounts[2].sign_in, "Acme");

    let summary = b.import_setup(&file, &everything(&file)).unwrap();
    assert_eq!(summary.accounts.len(), 3, "{summary:?}");
    let ann = account_of(&b, "ann@example.com");
    assert_eq!(ann.account_name, "Work");
    assert_eq!(ann.settings, settings("ann@example.com"));
    assert!(b.signature(ann.id).unwrap().contains("<b>Example</b>"));
    assert_eq!(
        b.store().account_addresses(ann.id).unwrap(),
        [("ann2@example.com".to_string(), "Ann Two".to_string())]
    );
    assert_eq!(b.secrets.get(ann.id), None, "no password without a passphrase");
    let bob = account_of(&b, "bob@gmail.example");
    assert_eq!(bob.settings.auth, Auth::OAuth2("google".into()));
    let carol = account_of(&b, "carol@acme.example");
    let apps = b.store().sign_in_apps().unwrap();
    assert_eq!(apps.len(), 1);
    assert!(!apps[0].app.has_secret);
    assert_eq!(carol.settings.auth, Auth::OAuth2(pe_store::app_provider(apps[0].id)));
    assert!(b.store().builtin_sign_in_enabled("google").unwrap());

    assert_eq!(b.text_size(), 0);
    assert_eq!(b.download_ahead().unwrap(), pe_store::Ahead::All);
    assert_eq!(b.download_limit_mb().unwrap(), 500);
    assert!(b.always_load_pictures().unwrap());
    assert!(!b.pgp_keyserver().unwrap());
    assert_eq!(b.send_delay().unwrap(), 20);
    assert!(!b.dark_messages());

    let cards = b.cards("").unwrap();
    assert_eq!(cards.len(), 2);
    let dave = cards.iter().find(|card| card.name == "Dave Example").unwrap();
    assert_eq!(dave.phones, [("cell".to_string(), "+1 555 0100".to_string())]);
    assert!(b.card_has_picture(dave.id));
    let groups = b.groups("").unwrap();
    let friends = b.group(groups[0].id).unwrap().unwrap();
    assert_eq!(friends.name, "Friends");
    assert_eq!(friends.members.len(), 2);
    assert_eq!(friends.members[0].card, Some(dave.id), "a member with a card keeps it");

    let keys = b.pgp_keys().unwrap();
    assert_eq!(keys.len(), 1, "a contact's key, no private key without a passphrase");
    assert_eq!(keys[0].fingerprint, filled.contact_key);
    assert!(keys[0].verified);
    assert_eq!(
        b.pgp_peer("dave@example.net").unwrap().in_use,
        Some(filled.contact_key.clone())
    );

    let rules = b.rules().unwrap();
    assert_eq!(rules.len(), 2);
    assert_eq!((rules[0].account, rules[0].move_to), (Some(ann.id), None));
    assert_eq!(
        b.store().rule_pending_target(rules[0].id).unwrap(),
        Some((ann.id, "Lists/News".to_string()))
    );
    assert_eq!(
        (rules[1].name.as_str(), rules[1].enabled, rules[1].account),
        ("from:shop.example", false, None)
    );
    // the account syncs its folders: the rule moves there
    b.store()
        .set_folders(ann.id, &[folder("INBOX"), folder("Lists/News")])
        .unwrap();
    let news = b.store().find_folder(ann.id, "Lists/News").unwrap().unwrap().id;
    assert_eq!(b.rule(rules[0].id).unwrap().unwrap().move_to, Some(news));

    let trusted: Vec<(String, bool)> = b
        .trusted_senders()
        .unwrap()
        .into_iter()
        .map(|sender| (sender.value, sender.domain))
        .collect();
    assert_eq!(
        trusted,
        [("a@b.example".to_string(), false), ("shop.example".to_string(), true)]
    );
    let texts: Vec<&str> = summary.lines.iter().map(|line| line.text.as_str()).collect();
    assert!(
        texts.contains(&count_text(Text::SetupAddedAccounts, 3).as_str()),
        "{texts:?}"
    );
    assert!(
        texts.contains(&count_text(Text::SetupRulesWaiting, 1).as_str()),
        "{texts:?}"
    );
    assert!(
        texts.contains(&tr(Text::SetupImportedPreferences).as_str()),
        "{texts:?}"
    );

    // a second import finds everything here
    let again = b.read_setup(&path, None).unwrap();
    assert!(again.accounts.iter().all(|account| account.here));
    assert_eq!(again.accounts[0].note, tr(Text::SetupAccountHere));
    let summary = b.import_setup(&again, &everything(&again)).unwrap();
    assert!(summary.accounts.is_empty());
    assert_eq!(b.accounts().unwrap().len(), 3);
    assert_eq!(b.cards("").unwrap().len(), 2);
    assert_eq!(b.rules().unwrap().len(), 2);
    assert_eq!(b.store().sign_in_apps().unwrap().len(), 1);
    let skipped = summary
        .lines
        .iter()
        .filter(|line| line.kind == ImportLineKind::Skipped)
        .count();
    assert!(skipped >= 5, "{summary:?}");
    let _ = filled.ann;
}

#[test]
fn secrets_and_own_keys_travel_with_a_passphrase() {
    let (dir_a, dir_b) = (TempDir::new("setup-a"), TempDir::new("setup-b"));
    let (a, b) = (opened(&dir_a), opened(&dir_b));
    let filled = fill(&a);
    let path = dir_a.path().join("Ann.inboxclassic");
    let short = a.export_setup(&path, Parts::ALL, Some("short"), &[]).unwrap_err();
    assert_eq!(short.to_string(), tr(Text::UiKeysPassphraseShort));
    assert!(!path.exists());
    a.export_setup(&path, Parts::ALL, Some(PASSPHRASE), &prefs()).unwrap();
    let text = std::fs::read_to_string(&path).unwrap();
    assert!(text.starts_with("-----BEGIN PGP MESSAGE-----"));
    for plain in [
        "ann-pw",
        "refresh-r1",
        "client-secret",
        "ann@example.com",
        "inbox-classic-setup",
    ] {
        assert!(!text.contains(plain), "{plain} readable in a sealed file");
    }

    assert_eq!(b.read_setup(&path, None).unwrap_err(), SetupError::NeedsPassphrase);
    assert_eq!(b.read_setup(&path, Some("")).unwrap_err(), SetupError::NeedsPassphrase);
    assert_eq!(
        b.read_setup(&path, Some("correct horse battery!")).unwrap_err(),
        SetupError::WrongPassphrase
    );
    let file = b.read_setup(&path, Some(PASSPHRASE)).unwrap();
    assert!(file.encrypted);
    assert!(file.accounts.iter().all(|account| account.has_secret));
    assert_eq!(file.accounts[0].note, tr(Text::SetupAccountSecretPassword));
    assert_eq!(file.accounts[1].note, tr(Text::SetupAccountSecretToken));
    assert_eq!((file.counts.own_keys, file.counts.contact_keys), (1, 1));

    b.import_setup(&file, &everything(&file)).unwrap();
    let ann = account_of(&b, "ann@example.com");
    assert_eq!(b.secrets.get(ann.id).as_deref(), Some("ann-pw"));
    let bob = account_of(&b, "bob@gmail.example");
    assert_eq!(b.secrets.get(bob.id).as_deref(), Some("refresh-r1"));
    let carol = account_of(&b, "carol@acme.example");
    assert_eq!(b.secrets.get(carol.id).as_deref(), Some("refresh-c1"));
    let app = &b.store().sign_in_apps().unwrap()[0];
    assert!(app.app.has_secret);
    assert_eq!(b.secrets.get(Key::App(app.id)).as_deref(), Some("client-secret"));

    // the own key, wrapped again under the second store's master key: it signs and decrypts there
    let info = b.pgp_key(&filled.own_key).unwrap();
    assert!(info.own && info.can_back_up, "{info:?}");
    assert_eq!(
        b.pgp_account_key(ann.id).unwrap().map(|identity| identity.fingerprint),
        Some(filled.own_key.clone())
    );
    let key = b.book(|book| book.own_key(&filled.own_key)).unwrap();
    let now = crate::worker::unix_now();
    let sealed = pe_pgp::encrypt(b"for ann".to_vec(), &[key.cert()], &[], None, now).unwrap();
    let opened = pe_pgp::decrypt(sealed.as_bytes(), std::slice::from_ref(&key), &[], now).unwrap();
    assert_eq!(opened.data, b"for ann");
    let signed = pe_pgp::sign_detached(b"signed by ann", &key, now).unwrap();
    let checks = pe_pgp::verify_detached(
        signed.signature.as_bytes(),
        b"signed by ann",
        &[key.cert().clone()],
        now,
    )
    .unwrap();
    assert_eq!(checks[0].status, pe_pgp::SigStatus::Good);
    // the wrapped bytes are the second store's own: not those of the first
    let wrapped = |core: &Core| core.store().pgp_key(&filled.own_key).unwrap().unwrap().secret.unwrap();
    assert_ne!(wrapped(&a), wrapped(&b));
}

#[test]
fn changed_damaged_and_foreign_files_are_refused_with_words() {
    let dir = TempDir::new("setup-bad");
    let core = opened(&dir);
    fill(&core);
    let sealed = dir.path().join("sealed.inboxclassic");
    core.export_setup(&sealed, Parts::SETTINGS.with(Parts::RULES), Some(PASSPHRASE), &[])
        .unwrap();
    // a byte of the encrypted data changed: refused, never opened
    let text = std::fs::read_to_string(&sealed).unwrap();
    let lines: Vec<&str> = text.lines().collect();
    let body = lines.len() - 4;
    let mut changed: Vec<String> = lines.iter().map(|line| line.to_string()).collect();
    let line = &mut changed[body];
    let replaced = if line.starts_with('A') { "B" } else { "A" };
    line.replace_range(0..1, replaced);
    let bad = dir.path().join("changed.inboxclassic");
    std::fs::write(&bad, changed.join("\n")).unwrap();
    match core.read_setup(&bad, Some(PASSPHRASE)) {
        Err(SetupError::Invalid(words)) => assert!(!words.is_empty()),
        other => panic!("a changed file read: {other:?}"),
    }

    let plain = dir.path().join("plain.inboxclassic");
    core.export_setup(&plain, Parts::RULES, None, &[]).unwrap();
    let mut bytes = std::fs::read(&plain).unwrap();
    let at = bytes.len() / 2;
    bytes[at] = b'\x01';
    std::fs::write(&bad, &bytes).unwrap();
    assert!(matches!(core.read_setup(&bad, None), Err(SetupError::Invalid(_))));

    std::fs::write(&bad, b"").unwrap();
    assert_eq!(
        core.read_setup(&bad, None).unwrap_err().text(),
        tr(Text::SetupErrorEmpty)
    );
    std::fs::write(
        &bad,
        br#"{"format":"inbox-classic-setup","version":7,"app_version":"3.1.0"}"#,
    )
    .unwrap();
    let newer = core.read_setup(&bad, None).unwrap_err().text();
    assert!(newer.contains("3.1.0"), "{newer}");
    let large = std::fs::File::create(&bad).unwrap();
    large.set_len(MAX_FILE as u64 + 1).unwrap();
    drop(large);
    assert_eq!(
        core.read_setup(&bad, None).unwrap_err().text(),
        tr(Text::SetupErrorTooLarge)
    );
    let missing = core
        .read_setup(&dir.path().join("none.inboxclassic"), None)
        .unwrap_err();
    assert!(matches!(missing, SetupError::Invalid(_)));
    assert!(core.export_setup(&plain, Parts::NONE, None, &[]).is_err());
}

#[test]
fn partial_imports_take_only_what_was_chosen() {
    let (dir_a, dir_b) = (TempDir::new("setup-a"), TempDir::new("setup-b"));
    let (a, b) = (opened(&dir_a), opened(&dir_b));
    fill(&a);
    let path = dir_a.path().join("all.inboxclassic");
    a.export_setup(&path, Parts::ALL, None, &[]).unwrap();
    let file = b.read_setup(&path, None).unwrap();
    // the second account alone, with the rules: the rule for the first account has no account here
    let choice = ImportChoice {
        parts: Parts::ACCOUNTS.with(Parts::RULES),
        accounts: vec![1],
    };
    let summary = b.import_setup(&file, &choice).unwrap();
    let accounts = b.accounts().unwrap();
    assert_eq!(accounts.len(), 1);
    assert_eq!(accounts[0].settings.email, "bob@gmail.example");
    assert_eq!(b.rules().unwrap().len(), 1, "the rule for every account");
    let texts: Vec<&str> = summary.lines.iter().map(|line| line.text.as_str()).collect();
    assert!(
        texts.contains(&count_text(Text::SetupSkippedRulesAccount, 1).as_str()),
        "{texts:?}"
    );
    assert!(b.cards("").unwrap().is_empty());
    assert!(b.trusted_senders().unwrap().is_empty());
    assert_eq!(b.text_size(), crate::TEXT_SIZE_MEDIUM);
    // the account of a sign-in app that is not here, without the sign-in apps part
    let choice = ImportChoice {
        parts: Parts::ACCOUNTS,
        accounts: vec![2],
    };
    let summary = b.import_setup(&file, &choice).unwrap();
    assert_eq!(b.accounts().unwrap().len(), 1);
    assert_eq!(summary.lines[0].kind, ImportLineKind::Skipped);
    assert!(summary.lines[0].text.contains("carol@acme.example"), "{summary:?}");
    // a part the file does not hold, or none at all
    let rules_only = dir_a.path().join("rules.inboxclassic");
    a.export_setup(&rules_only, Parts::RULES, None, &[]).unwrap();
    let rules = b.read_setup(&rules_only, None).unwrap();
    assert!(
        b.import_setup(
            &rules,
            &ImportChoice {
                parts: Parts::CONTACTS,
                accounts: vec![]
            }
        )
        .is_err()
    );
}

#[test]
fn contacts_merge_as_import_address_book_does() {
    let (dir_a, dir_b) = (TempDir::new("setup-a"), TempDir::new("setup-b"));
    let (a, b) = (opened(&dir_a), opened(&dir_b));
    fill(&a);
    let path = dir_a.path().join("contacts.inboxclassic");
    a.export_setup(&path, Parts::CONTACTS, None, &[]).unwrap();
    // the second store knows Dave by another card, and has a group of friends of its own
    let dave = b
        .save_card(&Card {
            name: "D.".into(),
            addresses: vec!["Dave@Example.net".into()],
            ..Default::default()
        })
        .unwrap();
    let gina = b
        .save_card(&Card {
            name: "Gina".into(),
            addresses: vec!["gina@example.org".into()],
            ..Default::default()
        })
        .unwrap();
    b.save_group(&Group {
        id: 0,
        name: "friends".into(),
        members: vec![Member {
            card: Some(gina),
            ..Default::default()
        }],
    })
    .unwrap();
    let file = b.read_setup(&path, None).unwrap();
    let summary = b.import_setup(&file, &everything(&file)).unwrap();
    let texts: Vec<&str> = summary.lines.iter().map(|line| line.text.as_str()).collect();
    assert!(
        texts.contains(&count_text(Text::SetupAddedContacts, 1).as_str()),
        "{texts:?}"
    );
    assert!(
        texts.contains(&count_text(Text::SetupSkippedContacts, 1).as_str()),
        "{texts:?}"
    );
    assert_eq!(b.cards("").unwrap().len(), 3);
    let groups = b.groups("").unwrap();
    assert_eq!(groups.len(), 1, "the group of the same name is completed");
    let friends = b.group(groups[0].id).unwrap().unwrap();
    let members: Vec<(Option<i64>, String)> = friends
        .members
        .iter()
        .map(|member| (member.card, member.address.to_lowercase()))
        .collect();
    assert_eq!(
        members,
        [
            (Some(gina), "gina@example.org".to_string()),
            (Some(dave), "dave@example.net".to_string()),
            (None, "frank@example.org".to_string())
        ]
    );
}

#[test]
fn a_different_key_for_an_address_waits_for_the_user() {
    let (dir_a, dir_b) = (TempDir::new("setup-a"), TempDir::new("setup-b"));
    let (a, b) = (opened(&dir_a), opened(&dir_b));
    let filled = fill(&a);
    let path = dir_a.path().join("keys.inboxclassic");
    a.export_setup(&path, Parts::KEYS, None, &[]).unwrap();
    let now = crate::worker::unix_now();
    let other = pe_pgp::generate("Dave", &["dave@example.net".into()], now).unwrap();
    b.pgp_import(other.cert().armored().as_bytes(), None, crate::keys::KeySource::File)
        .unwrap();
    let file = b.read_setup(&path, None).unwrap();
    let summary = b.import_setup(&file, &everything(&file)).unwrap();
    let peer = b.pgp_peer("dave@example.net").unwrap();
    assert_eq!(peer.in_use, Some(other.fingerprint()));
    assert_eq!(peer.pending, Some(filled.contact_key));
    assert!(
        summary
            .lines
            .iter()
            .any(|line| line.kind == ImportLineKind::Note && line.text.contains("dave@example.net")),
        "{summary:?}"
    );
}
