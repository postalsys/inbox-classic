//! Sign and Encrypt in the compose window (compose_keys.rs): the switches and their questions, each recipient's key,
//! the line under the fields, what Send refuses (the same as sending checks), the encrypted quote in clear mail, the
//! lookups Encrypt starts, Remove from Message and Attach My Public Key.

use std::io::Read;
use std::net::TcpListener;

use pe_core::compose_keys::{Block, Question, RecipientField, RecipientKey, Switch, without_recipient};
use pe_core::keys::KeySource;
use pe_core::protect::Tone;
use pe_core::{ComposeError, Core, Error, Options, Outgoing, PasswordStore};
use pe_store::{AccountSettings, Auth, Security, Store};

fn settings(email: &str) -> AccountSettings {
    AccountSettings {
        name: "Alice Example".into(),
        email: email.into(),
        username: email.into(),
        imap_host: "imap.invalid".into(),
        imap_port: 993,
        imap_security: Security::Tls,
        smtp_host: "smtp.invalid".into(),
        smtp_port: 465,
        smtp_security: Security::Tls,
        auth: Auth::Password,
    }
}

fn now() -> i64 {
    std::time::SystemTime::now()
        .duration_since(std::time::UNIX_EPOCH)
        .unwrap()
        .as_secs() as i64
}

/// A key server that takes connections and never answers: a lookup stays running while the test looks
fn silent_server() -> (TcpListener, String) {
    let listener = TcpListener::bind("127.0.0.1:0").unwrap();
    let base = format!("http://{}", listener.local_addr().unwrap());
    (listener, base)
}

/// A core with one account, alice@example.org (and a@work.example, another address of it), whose lookups go to `base`
fn open_core(dir: &pe_testkit::TempDir, base: &str) -> (Core, pe_store::AccountId) {
    let path = dir.path().join("store.db");
    let account = {
        let store = Store::open(&path).unwrap();
        let account = store.add_account(&settings("alice@example.org")).unwrap();
        store
            .set_account_addresses(account, &[("a@work.example".into(), String::new())])
            .unwrap();
        account
    };
    let options = Options {
        passwords: PasswordStore::Memory,
        pgp_servers: Some(pe_keys::Servers {
            keyserver: base.to_string(),
            wkd_base: Some(base.to_string()),
        }),
        ..Default::default()
    };
    (Core::open_with(&path, options, |_| {}).unwrap(), account)
}

/// A correspondent's public key imported, its fingerprint
fn import(core: &Core, name: &str, address: &str) -> String {
    let key = pe_pgp::generate(name, &[address.into()], now() - 60).unwrap();
    core.pgp_import(&key.cert().to_bytes(), None, KeySource::File).unwrap();
    key.cert().fingerprint()
}

fn to(list: &str) -> Outgoing {
    Outgoing {
        to: list.into(),
        subject: "Plans".into(),
        html: Some("<p>Hello</p>".into()),
        ..Default::default()
    }
}

#[test]
fn a_new_message_has_neither_and_turning_one_on_asks_for_a_key_first() {
    let (_server, base) = silent_server();
    let dir = pe_testkit::TempDir::new("compose-keys-new");
    let (core, account) = open_core(&dir, &base);
    let message = to("bob@example.org");
    let shown = core.compose_security(account, &message).unwrap();
    assert!(!shown.sign && !shown.encrypt && shown.sign_enabled);
    assert!(!shown.has_own_key);
    assert_eq!(shown.block, Block::None);
    assert!(shown.text.is_empty(), "no line for ordinary mail: {}", shown.text);
    // no own key: a question, nothing turned on
    let toggled = core
        .compose_toggle(account, &message, Switch::Sign, true, false)
        .unwrap();
    assert_eq!(toggled.question, Question::MakeKey);
    assert!(toggled.text.contains("alice@example.org"), "{}", toggled.text);
    assert_eq!(toggled.yes, "&Make a Key...");
    assert!(!toggled.sign);
    let toggled = core
        .compose_toggle(account, &message, Switch::Encrypt, true, false)
        .unwrap();
    assert_eq!(toggled.question, Question::MakeKey);
    assert!(!toggled.encrypt);
    // with a key, Sign turns on and the line says what it does
    core.pgp_generate(account).unwrap();
    let toggled = core
        .compose_toggle(account, &message, Switch::Sign, true, false)
        .unwrap();
    assert_eq!(toggled.question, Question::None);
    assert!(toggled.sign && !toggled.encrypt);
    let signed = Outgoing { sign: true, ..message };
    let shown = core.compose_security(account, &signed).unwrap();
    assert!(shown.sign && shown.sign_enabled && shown.has_own_key);
    assert_eq!(shown.tone, Tone::Good);
    assert!(shown.text.starts_with("Signed"), "{}", shown.text);
    assert!(shown.recipients.iter().all(|r| r.key == RecipientKey::Missing));
    assert_eq!(shown.block, Block::None, "signing needs no recipient's key");
}

#[test]
fn each_recipient_shows_its_key_and_encrypt_stops_on_one_without() {
    let (_server, base) = silent_server();
    let dir = pe_testkit::TempDir::new("compose-keys-recipients");
    let (core, account) = open_core(&dir, &base);
    core.pgp_generate(account).unwrap();
    import(&core, "Bob", "bob@example.org");
    let carol = import(&core, "Carol", "carol@example.org");
    core.pgp_set_key_verified(&carol, true).unwrap();
    let message = Outgoing {
        to: "Bob <bob@example.org>, Carol <carol@example.org>".into(),
        cc: "a@work.example".into(),
        bcc: "dave@example.org".into(),
        encrypt: true,
        ..to("")
    };
    let shown = core.compose_security(account, &message).unwrap();
    // Encrypt always signs: Sign shows on, and can not be clicked
    assert!(shown.sign && !shown.sign_enabled && shown.encrypt);
    assert_eq!(shown.sign_tip, "An encrypted message is always signed");
    let rows: Vec<(&str, &str, RecipientField, RecipientKey, Tone)> = shown
        .recipients
        .iter()
        .map(|r| (r.address.as_str(), r.label.as_str(), r.field, r.key, r.tone))
        .collect();
    assert_eq!(
        rows,
        [
            (
                "bob@example.org",
                "Bob",
                RecipientField::To,
                RecipientKey::Found,
                Tone::Good
            ),
            (
                "carol@example.org",
                "Carol",
                RecipientField::To,
                RecipientKey::Verified,
                Tone::Verified
            ),
            (
                "a@work.example",
                "a@work.example",
                RecipientField::Cc,
                RecipientKey::Own,
                Tone::Good
            ),
            (
                "dave@example.org",
                "dave@example.org",
                RecipientField::Bcc,
                RecipientKey::Missing,
                Tone::Warning
            ),
        ]
    );
    assert_eq!(shown.recipients[0].text, "Key not verified");
    assert_eq!(shown.recipients[1].text, "Key verified");
    assert_eq!(shown.recipients[3].text, "No key");
    assert!(shown.recipients[3].can_find);
    assert_eq!(shown.missing, 1);
    assert_eq!(shown.block, Block::MissingKeys);
    assert_eq!(shown.tone, Tone::Warning);
    assert_eq!(
        shown.text,
        "dave@example.org has no key, so the message can not be encrypted yet."
    );
    assert!(
        shown.keys_intro.starts_with("One recipient has no key"),
        "{}",
        shown.keys_intro
    );
    assert!(shown.can_send_unencrypted);
    // sending says the same, before the message goes anywhere
    match core.send(account, message.clone()) {
        Err(Error::Compose(ComposeError::MissingKeys(missing))) => assert_eq!(missing, ["dave@example.org"]),
        other => panic!("{other:?}"),
    }
    // Remove from Message takes Dave away: then it can go, all of them with a key
    let (to_list, cc, bcc) = without_recipient(&message, "Dave@Example.org");
    let without = Outgoing {
        to: to_list,
        cc,
        bcc,
        ..message
    };
    let shown = core.compose_security(account, &without).unwrap();
    assert_eq!(shown.block, Block::None);
    assert_eq!(shown.tone, Tone::Good, "Bob's key is not verified");
    assert_eq!(
        shown.text,
        "Encrypted and signed: only you and its 3 recipients can read it."
    );
    assert!(shown.keys_intro.starts_with("The message is encrypted to each"));
    // all of them verified: green
    let only_carol = Outgoing {
        to: "carol@example.org".into(),
        cc: String::new(),
        bcc: String::new(),
        ..without
    };
    let shown = core.compose_security(account, &only_carol).unwrap();
    assert_eq!(shown.tone, Tone::Verified);
    assert_eq!(
        shown.text,
        "Encrypted and signed: only you and carol@example.org can read it."
    );
}

#[test]
fn encrypt_with_no_recipients_yet_and_sign_that_encrypt_keeps() {
    let (_server, base) = silent_server();
    let dir = pe_testkit::TempDir::new("compose-keys-empty");
    let (core, account) = open_core(&dir, &base);
    core.pgp_generate(account).unwrap();
    let message = Outgoing {
        encrypt: true,
        ..to("")
    };
    let shown = core.compose_security(account, &message).unwrap();
    assert_eq!(shown.block, Block::None);
    assert!(
        shown.text.starts_with("It will be encrypted and signed"),
        "{}",
        shown.text
    );
    // Sign clicked off while Encrypt is on: the user's own Sign is off, Encrypt still signs
    let toggled = core
        .compose_toggle(account, &message, Switch::Sign, false, false)
        .unwrap();
    assert!(!toggled.sign && toggled.encrypt);
    // Encrypt off: Sign is the user's own again
    let toggled = core
        .compose_toggle(account, &message, Switch::Encrypt, false, false)
        .unwrap();
    assert_eq!(toggled.question, Question::None, "a new message is not asked about");
    assert!(!toggled.encrypt && !toggled.sign);
}

#[test]
fn a_reply_to_encrypted_mail_asks_before_encrypt_goes_off_and_its_quote_stays_encrypted() {
    let (_server, base) = silent_server();
    let dir = pe_testkit::TempDir::new("compose-keys-reply");
    let (core, account) = open_core(&dir, &base);
    core.pgp_generate(account).unwrap();
    import(&core, "Bob", "bob@example.org");
    let quote = pe_html::quote_html(&[("From", "Bob".into())], "<p>the code is 4711</p>", &[], true);
    // as a reply to encrypted mail starts (Core::draft): both on, the quote encrypted
    let reply = Outgoing {
        encrypt: true,
        sign: true,
        quote_encrypted: true,
        quote: Some(quote),
        ..to("bob@example.org")
    };
    let shown = core.compose_security(account, &reply).unwrap();
    assert_eq!(shown.block, Block::None);
    assert!(!shown.can_send_unencrypted);
    assert!(
        shown
            .unencrypted_text
            .contains("quotes or forwards an encrypted message")
    );
    // turning it off asks first, and the switches stay
    let toggled = core
        .compose_toggle(account, &reply, Switch::Encrypt, false, false)
        .unwrap();
    assert_eq!(toggled.question, Question::TurnOffEncrypt);
    assert!(toggled.encrypt);
    assert!(
        toggled.text.contains("until you remove what it quotes"),
        "{}",
        toggled.text
    );
    assert_eq!(
        (toggled.yes.as_str(), toggled.no.as_str()),
        ("&Turn Encryption Off", "&Keep It Encrypted")
    );
    let toggled = core
        .compose_toggle(account, &reply, Switch::Encrypt, false, true)
        .unwrap();
    assert!(!toggled.encrypt && toggled.sign);
    // off, with the quote still there: the finding, and Send refuses
    let clear = Outgoing {
        encrypt: false,
        ..reply.clone()
    };
    let shown = core.compose_security(account, &clear).unwrap();
    assert_eq!(shown.block, Block::EncryptedQuote);
    assert_eq!(shown.tone, Tone::Warning);
    assert!(shown.text.contains("can only be sent encrypted"), "{}", shown.text);
    match core.send(account, clear.clone()) {
        Err(Error::Compose(ComposeError::EncryptedQuote)) => {}
        other => panic!("{other:?}"),
    }
    // the quote removed: it may go unencrypted, and the line says the answer is not encrypted
    let removed = Outgoing { quote: None, ..clear };
    let shown = core.compose_security(account, &removed).unwrap();
    assert_eq!(shown.block, Block::None);
    assert!(shown.can_send_unencrypted);
    // signed or not, the line warns that the answer goes without the encryption the original had: that matters more
    // than the signature
    assert!(removed.sign, "Sign stays on after Encrypt is turned off");
    for message in [
        removed.clone(),
        Outgoing {
            sign: false,
            ..removed.clone()
        },
    ] {
        let shown = core.compose_security(account, &message).unwrap();
        assert_eq!(shown.tone, Tone::Warning);
        assert_eq!(
            shown.text,
            "Not encrypted, although the message it answers or forwards was."
        );
    }
    // a reply whose quote is gone is asked with the other words
    let encrypted_again = Outgoing {
        encrypt: true,
        ..removed
    };
    let toggled = core
        .compose_toggle(account, &encrypted_again, Switch::Encrypt, false, false)
        .unwrap();
    assert_eq!(toggled.question, Question::TurnOffEncrypt);
    assert!(
        toggled.text.contains("anyone who handles your message"),
        "{}",
        toggled.text
    );
}

#[test]
fn encrypt_looks_up_the_keys_it_lacks_and_find_key_waits_its_minute() {
    let (_server, base) = silent_server();
    let dir = pe_testkit::TempDir::new("compose-keys-lookup");
    let (core, account) = open_core(&dir, &base);
    core.pgp_generate(account).unwrap();
    import(&core, "Bob", "bob@example.org");
    let message = to("bob@example.org, dave@example.org, alice@example.org");
    let toggled = core
        .compose_toggle(account, &message, Switch::Encrypt, true, false)
        .unwrap();
    assert!(toggled.encrypt);
    assert!(toggled.lookup.is_some(), "Dave's key is looked up");
    let encrypted = Outgoing {
        encrypt: true,
        ..message
    };
    let shown = core.compose_security(account, &encrypted).unwrap();
    let dave = shown
        .recipients
        .iter()
        .find(|r| r.address == "dave@example.org")
        .unwrap();
    assert_eq!(dave.key, RecipientKey::Looking);
    assert_eq!(dave.tone, Tone::Neutral);
    assert!(!dave.can_find);
    assert!(shown.looking);
    assert_eq!(shown.block, Block::MissingKeys, "Send waits for the lookup");
    assert_eq!(shown.tone, Tone::Neutral);
    assert_eq!(shown.text, "Looking for the keys of dave@example.org...");
    let own = shown
        .recipients
        .iter()
        .find(|r| r.address == "alice@example.org")
        .unwrap();
    assert_eq!(own.key, RecipientKey::Own);
    // nothing is asked twice while it runs
    assert_eq!(core.compose_find_keys(account, &encrypted).unwrap(), None);
    assert_eq!(core.compose_find_key("dave@example.org").unwrap(), None);
}

#[test]
fn a_miss_shows_its_day_and_find_key_asks_again_after_a_minute() {
    let (_server, base) = silent_server();
    let dir = pe_testkit::TempDir::new("compose-keys-miss");
    let path = dir.path().join("store.db");
    let (core, account) = open_core(&dir, &base);
    core.pgp_generate(account).unwrap();
    let message = Outgoing {
        encrypt: true,
        ..to("dave@example.org")
    };
    // looked up in vain just now: no Find Key for a minute
    Store::open(&path)
        .unwrap()
        .set_pgp_lookup("dave@example.org", now() - 5, false)
        .unwrap();
    let shown = core.compose_security(account, &message).unwrap();
    let dave = &shown.recipients[0];
    assert_eq!(dave.key, RecipientKey::Missing);
    assert!(dave.text.starts_with("No key: none was found on"), "{}", dave.text);
    assert!(!dave.can_find);
    assert_eq!(core.compose_find_key("dave@example.org").unwrap(), None);
    // an hour ago: Encrypt does not ask again the same day, Find Key does
    Store::open(&path)
        .unwrap()
        .set_pgp_lookup("dave@example.org", now() - 3600, false)
        .unwrap();
    assert!(core.compose_security(account, &message).unwrap().recipients[0].can_find);
    assert_eq!(core.compose_find_keys(account, &message).unwrap(), None);
    assert!(core.compose_find_key("dave@example.org").unwrap().is_some());
}

#[test]
fn a_waiting_key_is_named_with_its_recipient() {
    let (_server, base) = silent_server();
    let dir = pe_testkit::TempDir::new("compose-keys-pending");
    let (core, account) = open_core(&dir, &base);
    core.pgp_generate(account).unwrap();
    import(&core, "Bob", "bob@example.org");
    import(&core, "Bob", "bob@example.org");
    let shown = core.compose_security(account, &to("bob@example.org")).unwrap();
    let bob = &shown.recipients[0];
    assert_eq!(bob.key, RecipientKey::Found, "the first key stays in use");
    assert!(
        bob.pending
            .as_deref()
            .is_some_and(|text| text.starts_with("A different key for bob@example.org")),
        "{bob:?}"
    );
}

#[test]
fn attach_my_public_key() {
    let (_server, base) = silent_server();
    let dir = pe_testkit::TempDir::new("compose-keys-attach");
    let (core, account) = open_core(&dir, &base);
    let message = to("bob@example.org");
    match core.compose_own_key_file(account, &message) {
        Err(Error::Compose(ComposeError::NoOwnKey(address))) => assert_eq!(address, "alice@example.org"),
        other => panic!("{other:?}"),
    }
    core.pgp_generate(account).unwrap();
    let path = core.compose_own_key_file(account, &message).unwrap();
    assert_eq!(
        path.file_name().unwrap().to_string_lossy(),
        "Alice Example public key.asc"
    );
    let mut text = String::new();
    std::fs::File::open(&path).unwrap().read_to_string(&mut text).unwrap();
    assert!(text.starts_with("-----BEGIN PGP PUBLIC KEY BLOCK-----"));
    assert!(!text.contains("PRIVATE"));
    // the key file is no file of an encrypted message: a reply whose quote is gone may still go without encryption
    let reply = Outgoing {
        quote_encrypted: true,
        attachments: vec![path],
        ..message
    };
    assert!(core.compose_security(account, &reply).unwrap().can_send_unencrypted);
}

#[test]
fn a_test_key_server_only_on_this_computer() {
    let (_server, base) = silent_server();
    let dir = pe_testkit::TempDir::new("compose-keys-test-server");
    let (core, _) = open_core(&dir, &base);
    assert!(core.use_test_key_server("http://127.0.0.1:4711"));
    assert!(core.use_test_key_server("http://localhost:4711/"));
    for refused in [
        "https://keys.openpgp.org",
        "http://127.0.0.1.example.com:80",
        "http://127.0.0.1:80/elsewhere",
        "http://127.0.0.1:",
        "http://10.0.0.1:80",
    ] {
        assert!(!core.use_test_key_server(refused), "{refused}");
    }
}
