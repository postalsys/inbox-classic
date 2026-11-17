//! Signed and encrypted mail sent through ImapKit, checked on the other side by OpenPGP.js (core/e2e/pgp-check.mjs),
//! an implementation that shares nothing with rPGP: what goes out verifies and opens there, the copy in Sent and the
//! draft open with the sender's own key, a Bcc recipient opens it without being named, nothing of the text or the
//! files is readable on the server, and the rules that stop a send.
//!
//! Skipped without Node.js and `npm ci` in core/e2e, unless PE_E2E_REQUIRED is set.

use std::path::Path;
use std::sync::mpsc::{Receiver, channel};
use std::time::Duration;

use pe_core::keys::KeySource;
use pe_core::{ComposeError, Core, Error, Event, Outgoing};
use pe_testkit::{ImapKit, PASSWORD, TempDir};
use serde_json::{Value, json};

struct Setup {
    server: ImapKit,
    core: Core,
    events: Receiver<Event>,
    dir: TempDir,
}

fn setup() -> Option<Setup> {
    let server = ImapKit::start(json!({}))?;
    let dir = TempDir::new("core-pgp");
    let (sender, events) = channel();
    let options = pe_core::Options {
        trust: pe_net::Trust::Pinned(vec![server.cert.clone()]),
        passwords: pe_core::PasswordStore::Memory,
        ..Default::default()
    };
    let core = Core::open_with(dir.path().join("store.db"), options, move |event| {
        let _ = sender.send(event);
    })
    .unwrap();
    core.set_send_delay(0).unwrap();
    Some(Setup {
        server,
        core,
        events,
        dir,
    })
}

impl Setup {
    fn wait(&self, accept: impl Fn(&Event) -> bool) -> Event {
        loop {
            let event = self
                .events
                .recv_timeout(Duration::from_secs(20))
                .expect("an event within 20 seconds");
            if accept(&event) {
                return event;
            }
            assert!(!matches!(event, Event::Failed { .. }), "{event:?}");
        }
    }

    /// The raw messages of an ImapKit mailbox
    fn raw(&self, mailbox: &str) -> Vec<String> {
        self.server
            .messages(mailbox)
            .iter()
            .map(|message| {
                let raw = message["raw"].as_str().unwrap();
                let bytes = base64::Engine::decode(&base64::engine::general_purpose::STANDARD, raw).unwrap();
                String::from_utf8_lossy(&bytes).into_owned()
            })
            .collect()
    }

    fn file(&self, name: &str, content: &str) -> String {
        let path = self.dir.path().join(name);
        std::fs::write(&path, content).unwrap();
        path.display().to_string()
    }

    /// pgp-check.mjs's answer
    fn check(&self, args: &[&str]) -> Value {
        let script = Path::new(env!("CARGO_MANIFEST_DIR")).join("../../e2e/pgp-check.mjs");
        let out = std::process::Command::new("node")
            .arg(script)
            .args(args)
            .output()
            .unwrap();
        assert!(out.status.success(), "{}", String::from_utf8_lossy(&out.stderr));
        serde_json::from_slice(&out.stdout).unwrap()
    }
}

fn now() -> i64 {
    std::time::SystemTime::now()
        .duration_since(std::time::UNIX_EPOCH)
        .unwrap()
        .as_secs() as i64
}

#[test]
fn signed_and_encrypted_mail_through_a_server() {
    let Some(s) = setup() else { return };
    let mut settings = s.server.account_settings();
    settings.smtp_security = pe_store::Security::StartTls;
    let me = settings.email.clone();
    let account = s.core.add_account(&settings, PASSWORD).unwrap();
    s.core.sync(account).unwrap();
    s.wait(|e| *e == Event::SyncFinished { account, failure: None });

    // my key, and Bob's and Carol's (theirs made here, checked there with OpenPGP.js)
    let mine = s.core.pgp_generate(account).unwrap();
    let my_cert = s.file("me.pub.asc", &s.core.pgp_export(&mine).unwrap());
    let my_key = s.file("me.sec.asc", &s.core.pgp_backup(&mine, "own passphrase").unwrap());
    let bob = pe_pgp::generate("Bob", &["bob@example.net".into()], now() - 60).unwrap();
    let carol = pe_pgp::generate("Carol", &["carol@example.net".into()], now() - 60).unwrap();
    for key in [&bob, &carol] {
        s.core
            .pgp_import(key.cert().armored().as_bytes(), None, KeySource::Paste)
            .unwrap();
    }
    let bob_key = s.file("bob.sec.asc", &bob.backup("bob passphrase").unwrap());
    let carol_key = s.file("carol.sec.asc", &carol.backup("carol passphrase").unwrap());

    // signed: it verifies with OpenPGP.js; a line ending in a space survives as quoted-printable
    let signed = Outgoing {
        to: "bob@example.net".into(),
        subject: "Signed".into(),
        text: "The contract, as agreed.\n-- \nMe\n".into(),
        sign: true,
        ..Default::default()
    };
    s.core.send(account, signed).unwrap();
    s.wait(|e| matches!(e, Event::MessageSent { .. }));
    let raw = s.raw("INBOX").pop().unwrap();
    assert!(raw.contains("multipart/signed"), "{raw}");
    assert!(raw.contains("protocol=\"application/pgp-signature\""));
    let checked = s.check(&["verify", &my_cert, &s.file("signed.eml", &raw)]);
    assert_eq!(checked["valid"], true, "{checked}");

    // encrypted, with a file, to Bob and (hidden) Carol
    let attachment = s.dir.path().join("plan-of-the-heist.txt");
    std::fs::write(&attachment, "the plan").unwrap();
    let secret = Outgoing {
        to: "bob@example.net".into(),
        bcc: "carol@example.net".into(),
        subject: "Encrypted".into(),
        text: "Meet at the old mill at nine.".into(),
        attachments: vec![attachment],
        encrypt: true,
        sign: true,
        ..Default::default()
    };
    s.core.send(account, secret).unwrap();
    s.wait(|e| matches!(e, Event::MessageSent { .. }));
    let raw = s.raw("INBOX").pop().unwrap();
    assert!(raw.contains("multipart/encrypted"), "{raw}");
    assert!(
        !raw.contains("old mill") && !raw.contains("plan-of-the-heist"),
        "nothing readable on the server"
    );
    let file = s.file("encrypted.eml", &raw);
    let opened = s.check(&["decrypt", &bob_key, "bob passphrase", &my_cert, &file]);
    assert!(
        opened["data"]
            .as_str()
            .unwrap()
            .contains("Meet at the old mill at nine."),
        "{opened}"
    );
    assert!(opened["data"].as_str().unwrap().contains("plan-of-the-heist.txt"));
    assert_eq!(
        (opened["signed"].clone(), opened["valid"].clone()),
        (json!(true), json!(true)),
        "{opened}"
    );
    // Carol opens it too, without being named in it
    let opened = s.check(&["decrypt", &carol_key, "carol passphrase", &my_cert, &file]);
    assert!(opened["data"].as_str().unwrap().contains("old mill"));
    let named = s.check(&["recipients", &file]);
    let carol_ids = carol.cert().handles();
    assert!(
        named["recipients"]
            .as_array()
            .unwrap()
            .iter()
            .all(|id| !carol_ids.contains(&id.as_str().unwrap().to_string())),
        "{named}"
    );
    // the copy in Sent opens with my own key
    s.wait(|e| matches!(e, Event::FolderChanged { .. }));
    let sent = s.raw("Sent").pop().unwrap();
    let opened = s.check(&[
        "decrypt",
        &my_key,
        "own passphrase",
        &my_cert,
        &s.file("sent.eml", &sent),
    ]);
    assert!(opened["data"].as_str().unwrap().contains("old mill"));

    // a draft with Encrypt on: encrypted to my key alone, not signed
    let draft = Outgoing {
        to: "bob@example.net".into(),
        subject: "Draft".into(),
        text: "Unfinished thoughts".into(),
        encrypt: true,
        sign: true,
        ..Default::default()
    };
    s.core.save_draft(account, draft).unwrap();
    s.wait(|e| matches!(e, Event::DraftSaved { problem: None, .. }));
    let saved = loop {
        if let Some(raw) = s.raw("Drafts").pop() {
            break raw;
        }
        std::thread::sleep(Duration::from_millis(100));
    };
    assert!(saved.contains("multipart/encrypted") && !saved.contains("Unfinished"));
    let opened = s.check(&[
        "decrypt",
        &my_key,
        "own passphrase",
        &my_cert,
        &s.file("draft.eml", &saved),
    ]);
    assert!(opened["data"].as_str().unwrap().contains("Unfinished thoughts"));
    assert_eq!(opened["signed"], false);

    // a draft quoting encrypted mail with Encrypt turned off: still saved encrypted, what was encrypted never reaches
    // the server in the clear
    let quoting = Outgoing {
        to: "bob@example.net".into(),
        subject: "Re: the plan".into(),
        text: "Quoting the plan".into(),
        quote: Some("<blockquote>The secret plan</blockquote>".into()),
        quote_encrypted: true,
        ..Default::default()
    };
    s.core.save_draft(account, quoting).unwrap();
    s.wait(|e| matches!(e, Event::DraftSaved { problem: None, .. }));
    let drafts = loop {
        let drafts = s.raw("Drafts");
        if drafts.iter().any(|raw| raw != &saved) {
            break drafts;
        }
        std::thread::sleep(Duration::from_millis(100));
    };
    for raw in &drafts {
        assert!(
            raw.contains("multipart/encrypted") && !raw.contains("secret plan") && !raw.contains("Quoting the plan")
        );
    }

    // a recipient without a key stops the send, by name
    let nobody = Outgoing {
        to: "bob@example.net, nokey@example.org".into(),
        subject: "x".into(),
        text: "x".into(),
        encrypt: true,
        sign: true,
        ..Default::default()
    };
    match s.core.send(account, nobody) {
        Err(Error::Compose(ComposeError::MissingKeys(missing))) => assert_eq!(missing, ["nokey@example.org"]),
        other => panic!("{other:?}"),
    }

    // the reply to the encrypted message (delivered to this account's INBOX) starts encrypted and may not go without
    s.core.sync(account).unwrap();
    s.wait(|e| *e == Event::SyncFinished { account, failure: None });
    let inbox = s
        .core
        .folders(account)
        .unwrap()
        .into_iter()
        .find(|f| f.info.path == "INBOX")
        .unwrap()
        .id;
    let uid = s
        .core
        .messages(inbox, pe_store::Sort::default(), 0, 10)
        .unwrap()
        .into_iter()
        .find(|m| m.info.subject == "Encrypted")
        .unwrap()
        .info
        .uid;
    s.core.open_message(inbox, uid).unwrap();
    s.wait(|e| *e == Event::MessageReady { folder: inbox, uid });
    let reply = s.core.draft(inbox, uid, pe_core::DraftKind::Reply).unwrap().unwrap();
    assert!(reply.encrypt && reply.sign && reply.quote_encrypted);
    assert!(reply.quote.contains("old mill"), "the quote is the decrypted text");
    let in_clear = Outgoing {
        to: me.clone(),
        subject: reply.subject.clone(),
        html: Some("<p>Sure.</p>".into()),
        quote: Some(reply.quote.clone()),
        quote_encrypted: true,
        ..Default::default()
    };
    match s.core.send(account, in_clear) {
        Err(Error::Compose(ComposeError::EncryptedQuote)) => {}
        other => panic!("{other:?}"),
    }
}

#[test]
fn an_encrypted_message_taken_back_opens_decrypted() {
    let Some(s) = setup() else { return };
    let mut settings = s.server.account_settings();
    settings.smtp_security = pe_store::Security::StartTls;
    let account = s.core.add_account(&settings, PASSWORD).unwrap();
    s.core.sync(account).unwrap();
    s.wait(|e| *e == Event::SyncFinished { account, failure: None });
    s.core.pgp_generate(account).unwrap();
    let bob = pe_pgp::generate("Bob", &["bob@example.net".into()], now() - 60).unwrap();
    s.core
        .pgp_import(bob.cert().armored().as_bytes(), None, KeySource::Paste)
        .unwrap();
    s.core.set_send_delay(30).unwrap();
    let secret = Outgoing {
        to: "bob@example.net".into(),
        subject: "Take me back".into(),
        text: "Second thoughts".into(),
        encrypt: true,
        sign: true,
        ..Default::default()
    };
    s.core.send(account, secret).unwrap();
    // in the Outbox, waiting
    s.wait(|e| matches!(e, Event::OutboxChanged { .. }));
    let (draft, _) = s.core.undo_send().unwrap();
    let (_, draft) = draft.expect("taken back");
    assert!(draft.encrypt && draft.sign);
    // what was encrypted may go only encrypted
    assert!(draft.quote_encrypted);
    assert!(draft.body.contains("Second thoughts"), "{}", draft.body);
    assert_eq!(draft.subject, "Take me back");
}

#[test]
fn autocrypt_goes_with_the_mail() {
    let Some(s) = setup() else { return };
    let mut settings = s.server.account_settings();
    settings.smtp_security = pe_store::Security::StartTls;
    let me = settings.email.clone();
    let account = s.core.add_account(&settings, PASSWORD).unwrap();
    s.core.sync(account).unwrap();
    s.wait(|e| *e == Event::SyncFinished { account, failure: None });
    let mine = s.core.pgp_generate(account).unwrap();
    let bob = pe_pgp::generate("Bob", &["bob@example.net".into()], now() - 60).unwrap();
    let carol = pe_pgp::generate("Carol", &["carol@example.net".into()], now() - 60).unwrap();
    for key in [&bob, &carol] {
        s.core
            .pgp_import(key.cert().armored().as_bytes(), None, KeySource::Paste)
            .unwrap();
    }

    // a plain message carries my key
    let plain = Outgoing {
        to: "bob@example.net".into(),
        subject: "Plain".into(),
        text: "Hi".into(),
        ..Default::default()
    };
    s.core.send(account, plain).unwrap();
    s.wait(|e| matches!(e, Event::MessageSent { .. }));
    let raw = s.raw("INBOX").pop().unwrap();
    let message = pe_mime::parser::parse(raw.as_bytes()).unwrap();
    let header = message
        .headers
        .iter()
        .find(|h| h.key == "autocrypt")
        .expect("an Autocrypt header");
    let parsed = pe_pgp::autocrypt::parse(&header.value).unwrap();
    assert_eq!(parsed.addr, me.to_lowercase());
    assert!(!parsed.mutual);
    assert_eq!(pe_pgp::read_certs(&parsed.keydata).unwrap()[0].fingerprint(), mine);
    assert!(raw.contains("Hi"), "the message itself as before");

    // encrypted to Bob and Carol: each gets the other's key inside, gossip is never outside
    let both = Outgoing {
        to: "bob@example.net, carol@example.net".into(),
        subject: "Both".into(),
        text: "To you both".into(),
        encrypt: true,
        sign: true,
        ..Default::default()
    };
    s.core.send(account, both).unwrap();
    s.wait(|e| matches!(e, Event::MessageSent { .. }));
    let raw = s.raw("INBOX").pop().unwrap();
    assert!(raw.contains("Autocrypt: ") && !raw.contains("Autocrypt-Gossip"));
    let opened = pe_pgp::decrypt(pe_core_part(&raw).as_bytes(), std::slice::from_ref(&bob), &[], now()).unwrap();
    let inner = String::from_utf8(opened.data).unwrap();
    assert_eq!(inner.matches("Autocrypt-Gossip:").count(), 2, "{inner}");

    // the switch off: no header
    s.core.pgp_set_identity(&me, &mine, false).unwrap();
    let quiet = Outgoing {
        to: "bob@example.net".into(),
        subject: "Quiet".into(),
        text: "Hi".into(),
        ..Default::default()
    };
    s.core.send(account, quiet).unwrap();
    s.wait(|e| matches!(e, Event::MessageSent { .. }));
    assert!(!s.raw("INBOX").pop().unwrap().contains("Autocrypt:"));
}

/// The armored OpenPGP message of a multipart/encrypted message
fn pe_core_part(raw: &str) -> String {
    let start = raw.find("-----BEGIN PGP MESSAGE-----").unwrap();
    let end = raw.find("-----END PGP MESSAGE-----").unwrap() + "-----END PGP MESSAGE-----".len();
    raw[start..end].to_string()
}

/// An encrypted message downloaded ahead is decrypted by the background pass with the user's key, asking nothing:
/// found by a word of its text and listed by its protected Subject, until the switch in Settings is turned off, and
/// again once it is on
#[test]
fn the_background_pass_decrypts_for_the_search() {
    let Some(s) = setup() else { return };
    let fixtures = Path::new(env!("CARGO_MANIFEST_DIR")).join("../../../scripts/ui-e2e/pgp");
    let read = |name: &str| std::fs::read(fixtures.join(name)).unwrap();
    let passphrase = String::from_utf8(read("me.passphrase")).unwrap();
    s.core
        .pgp_import(&read("me.asc"), Some(passphrase.trim()), KeySource::File)
        .unwrap();
    let me = pe_pgp::read_certs(&read("me.asc")).unwrap().remove(0);
    let inner = "Content-Type: text/plain; charset=utf-8; protected-headers=\"v1\"\r\nSubject: The zebrafish plan\r\n\r\n\
                 Meet me at the old windmill.\r\n";
    let armored = pe_pgp::encrypt(inner.as_bytes().to_vec(), &[&me], &[], None, now()).unwrap();
    let raw = format!(
        "From: Alice Example <alice@example.org>\r\nTo: testuser@example.com\r\nSubject: ...\r\n\
         Message-ID: <background@example.org>\r\nMIME-Version: 1.0\r\n\
         Content-Type: multipart/encrypted; protocol=\"application/pgp-encrypted\"; boundary=\"e\"\r\n\r\n\
         --e\r\nContent-Type: application/pgp-encrypted\r\n\r\nVersion: 1\r\n--e\r\n\
         Content-Type: application/octet-stream\r\n\r\n{armored}\r\n--e--\r\n"
    );
    s.server.add_message("INBOX", &raw, &[]);
    let account = s.core.add_account(&s.server.account_settings(), PASSWORD).unwrap();
    s.core.sync(account).unwrap();
    s.wait(|e| *e == Event::SyncFinished { account, failure: None });

    let find = |text: &str| {
        let search = pe_core::Search {
            scope: pe_core::Scope::Everywhere,
            show: pe_core::Show::All,
            text: text.into(),
            ..Default::default()
        };
        s.core.search(&search, pe_store::Sort::default(), 0, 10).unwrap()
    };
    let eventually = |done: &dyn Fn() -> bool, what: &str| {
        let until = std::time::Instant::now() + Duration::from_secs(30);
        while !done() {
            assert!(std::time::Instant::now() < until, "{what}");
            std::thread::sleep(Duration::from_millis(200));
        }
    };
    // downloaded ahead and decrypted in the background, never opened
    eventually(
        &|| find("windmill").len() == 1,
        "found by a word of its text after the background pass",
    );
    let row = find("is:encrypted").remove(0);
    assert_eq!(row.info.subject, "The zebrafish plan");
    assert!(
        row.snippet.as_deref().is_some_and(|s| s.contains("windmill")),
        "{row:?}"
    );
    assert_eq!(row.info.outer_subject.as_deref(), Some("..."));

    // turned off: neither its words nor its protected Subject
    s.core.set_pgp_index_encrypted(false).unwrap();
    assert!(find("windmill").is_empty(), "not after the switch is off");
    let row = find("is:encrypted").remove(0);
    assert_eq!(row.info.subject, "...");
    assert_eq!(row.snippet.as_deref(), Some("Encrypted message"));

    // on again: the background pass decrypts it again
    s.core.set_pgp_index_encrypted(true).unwrap();
    eventually(&|| find("windmill").len() == 1, "found again once it is on");
    assert_eq!(find("is:encrypted").remove(0).info.subject, "The zebrafish plan");

    // a move the server refuses (Archive deleted by another client): the row comes back as it came, nothing decrypted
    // in it for an agent to see or find
    let folders = s.core.folders(account).unwrap();
    let id = |path: &str| folders.iter().find(|f| f.info.path == path).unwrap().id;
    let (inbox, archive) = (id("INBOX"), id("Archive"));
    s.server.delete_folder("Archive");
    let uid = find("is:encrypted").remove(0).info.uid;
    s.core.move_messages(inbox, &[uid], archive).unwrap();
    s.wait(|e| matches!(e, Event::ActionUndone { .. }));
    let agent_finds = |text: &str| {
        let search = pe_core::Search {
            scope: pe_core::Scope::Everywhere,
            show: pe_core::Show::All,
            text: text.into(),
            no_decrypted: true,
            ..Default::default()
        };
        s.core.search(&search, pe_store::Sort::default(), 0, 10).unwrap()
    };
    let back = find("is:encrypted").remove(0);
    assert_eq!(back.agent_subject(), "...");
    for word in ["windmill", "zebrafish"] {
        assert!(agent_finds(word).is_empty(), "{word}");
    }
    // decrypted again by the background pass, its outer Subject kept for agents; the switch off puts it back
    s.core.set_pgp_index_encrypted(true).unwrap();
    eventually(
        &|| find("windmill").len() == 1,
        "decrypted again after the refused move",
    );
    let again = find("is:encrypted").remove(0);
    assert_eq!(
        (again.info.subject.as_str(), again.agent_subject()),
        ("The zebrafish plan", "...")
    );
    assert!(agent_finds("windmill").is_empty());
    s.core.set_pgp_index_encrypted(false).unwrap();
    assert_eq!(find("is:encrypted").remove(0).info.subject, "...");
}
