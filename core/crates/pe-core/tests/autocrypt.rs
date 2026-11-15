//! Autocrypt read from messages opened: a sender's key learned, an older message changing nothing, a different key
//! in a newer one waiting for the user, a header for someone else ignored, gossip read inside an encrypted message.

use pe_core::keys::KeySource;
use pe_core::{Core, Options, PasswordStore};
use pe_store::{AccountSettings, Auth, Security, Store};

fn now() -> i64 {
    std::time::SystemTime::now()
        .duration_since(std::time::UNIX_EPOCH)
        .unwrap()
        .as_secs() as i64
}

struct World {
    core: Core,
    dir: pe_testkit::TempDir,
    me: pe_pgp::Cert,
}

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
    World { core, dir, me }
}

fn header(address: &str, key: &pe_pgp::SecretKey) -> String {
    let minimal = key.cert().minimal(address, now()).unwrap();
    pe_pgp::autocrypt::build(address, &minimal.to_bytes(), false).replace(' ', "\r\n ")
}

fn message(from: &str, date: &str, autocrypt: &str) -> String {
    format!(
        "From: {from}\r\nTo: me@example.org\r\nSubject: Hi\r\nDate: {date}\r\nMessage-ID: <{}@example.org>\r\n\
         Autocrypt: {autocrypt}\r\nContent-Type: text/plain\r\n\r\nHello\r\n",
        date.len()
    )
}

impl World {
    fn open(&self, raw: &str) {
        let file = self.dir.path().join("m.eml");
        std::fs::write(&file, raw).unwrap();
        self.core.file_view(&file, false).unwrap();
    }
}

#[test]
fn a_senders_key_learned_and_kept() {
    let w = world("autocrypt-learn");
    let ann = pe_pgp::generate("Ann", &["ann@example.org".into()], now() - 600).unwrap();
    w.open(&message(
        "Ann <ann@example.org>",
        "Sun, 15 Nov 2026 10:00:00 +0000",
        &header("ann@example.org", &ann),
    ));
    let peer = w.core.pgp_peer("ann@example.org").unwrap();
    assert_eq!(peer.in_use.as_deref(), Some(ann.fingerprint().as_str()));
    let key = w.core.pgp_key(&ann.fingerprint()).unwrap();
    assert!(key.source.contains("Autocrypt"), "{}", key.source);

    // an older message with another key changes nothing
    let old = pe_pgp::generate("Ann", &["ann@example.org".into()], now() - 600).unwrap();
    w.open(&message(
        "ann@example.org",
        "Sun, 1 Nov 2026 10:00:00 +0000",
        &header("ann@example.org", &old),
    ));
    let peer = w.core.pgp_peer("ann@example.org").unwrap();
    assert_eq!(
        (peer.in_use.as_deref(), peer.pending),
        (Some(ann.fingerprint().as_str()), None)
    );

    // a newer one with another key: it waits for the user
    let new = pe_pgp::generate("Ann", &["ann@example.org".into()], now() - 600).unwrap();
    w.open(&message(
        "ann@example.org",
        "Mon, 16 Nov 2026 10:00:00 +0000",
        &header("ann@example.org", &new),
    ));
    let peer = w.core.pgp_peer("ann@example.org").unwrap();
    assert_eq!(peer.in_use.as_deref(), Some(ann.fingerprint().as_str()));
    assert_eq!(peer.pending.as_deref(), Some(new.fingerprint().as_str()));
}

#[test]
fn a_header_for_someone_else_is_ignored() {
    let w = world("autocrypt-other");
    let mallory = pe_pgp::generate("Mallory", &["ann@example.org".into()], now() - 600).unwrap();
    w.open(&message(
        "mallory@example.net",
        "Sun, 15 Nov 2026 10:00:00 +0000",
        &header("ann@example.org", &mallory),
    ));
    assert!(w.core.pgp_peer("ann@example.org").unwrap().in_use.is_none());
}

#[test]
fn gossip_inside_an_encrypted_message() {
    let w = world("autocrypt-gossip");
    let ann = pe_pgp::generate("Ann", &["ann@example.org".into()], now() - 600).unwrap();
    let bob = pe_pgp::generate("Bob", &["bob@example.org".into()], now() - 600).unwrap();
    w.core
        .pgp_import(ann.cert().armored().as_bytes(), None, KeySource::Paste)
        .unwrap();
    let gossip = format!("Autocrypt-Gossip: {}\r\n", header("bob@example.org", &bob));
    let inner = format!("{gossip}Content-Type: text/plain\r\n\r\nFor both of you");
    let armored = pe_pgp::encrypt(inner.into_bytes(), &[&w.me], &[], Some(&ann), now()).unwrap();
    let raw = format!(
        "From: ann@example.org\r\nTo: me@example.org, bob@example.org\r\nSubject: Hi\r\nDate: Sun, 15 Nov 2026 10:00:00 +0000\r\n\
         MIME-Version: 1.0\r\nContent-Type: multipart/encrypted; protocol=\"application/pgp-encrypted\"; boundary=e\r\n\r\n\
         --e\r\nContent-Type: application/pgp-encrypted\r\n\r\nVersion: 1\r\n--e\r\nContent-Type: application/octet-stream\r\n\r\n\
         {armored}\r\n--e--\r\n"
    );
    w.open(&raw);
    assert_eq!(
        w.core.pgp_peer("bob@example.org").unwrap().in_use.as_deref(),
        Some(bob.fingerprint().as_str())
    );

    // the same gossip in a message that is not encrypted is not read
    let carol = pe_pgp::generate("Carol", &["carol@example.org".into()], now() - 600).unwrap();
    let plain = format!(
        "From: ann@example.org\r\nTo: me@example.org, carol@example.org\r\nSubject: Hi\r\nDate: Mon, 16 Nov 2026 10:00:00 +0000\r\n\
         Autocrypt-Gossip: {}\r\nContent-Type: text/plain\r\n\r\nx\r\n",
        header("carol@example.org", &carol)
    );
    w.open(&plain);
    assert!(w.core.pgp_peer("carol@example.org").unwrap().in_use.is_none());
}

/// A key in a header that also names someone else (a user id anyone can add to their own key) is learned for the
/// sender alone: the other address gets no key from it
#[test]
fn a_header_key_plants_nothing_for_other_addresses() {
    let w = world("autocrypt-extra-ids");
    let mallory = pe_pgp::generate(
        "Mallory",
        &["mallory@evil.example".into(), "cfo@victim.example".into()],
        now() - 600,
    )
    .unwrap();
    let all = pe_pgp::autocrypt::build("mallory@evil.example", &mallory.cert().to_bytes(), false).replace(' ', "\r\n ");
    w.open(&message(
        "mallory@evil.example",
        "Sun, 15 Nov 2026 10:00:00 +0000",
        &all,
    ));
    assert_eq!(
        w.core.pgp_peer("mallory@evil.example").unwrap().in_use.as_deref(),
        Some(mallory.fingerprint().as_str())
    );
    assert!(w.core.pgp_peer("cfo@victim.example").unwrap().in_use.is_none());
}
