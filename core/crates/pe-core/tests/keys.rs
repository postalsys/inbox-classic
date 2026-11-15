//! The key book: own keys made and imported, kept wrapped under the master key, backed up; correspondents' keys
//! learned with the changed key rule; keys in vCards.

use pe_core::keys::{ImportError, KeySource, KeyState, Learned};
use pe_core::{Core, Options, PasswordStore};
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

/// A core over a new store with one account, `alice@example.org` (and `a@work.example`, another address of it)
fn open_core(dir: &pe_testkit::TempDir) -> (Core, pe_store::AccountId) {
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
        ..Default::default()
    };
    (Core::open_with(&path, options, |_| {}).unwrap(), account)
}

fn now() -> i64 {
    std::time::SystemTime::now()
        .duration_since(std::time::UNIX_EPOCH)
        .unwrap()
        .as_secs() as i64
}

#[test]
fn a_new_key_for_an_account() {
    let dir = pe_testkit::TempDir::new("core-keys-new");
    let (core, account) = open_core(&dir);
    let fingerprint = core.pgp_generate(account).unwrap();
    let keys = core.pgp_keys().unwrap();
    assert_eq!(keys.len(), 1);
    let key = &keys[0];
    assert_eq!(key.fingerprint, fingerprint);
    assert!(key.own);
    assert_eq!(key.state, KeyState::Valid);
    assert_eq!(
        key.user_ids,
        ["Alice Example <alice@example.org>", "Alice Example <a@work.example>"]
    );
    assert_eq!(key.algorithm, "Ed25519");
    assert_eq!(key.grouped.len(), 49, "ten groups of four with spaces");
    let identities = core.pgp_identities().unwrap();
    assert_eq!(identities.len(), 2, "both addresses use it: {identities:?}");
    assert!(identities.iter().all(|i| i.fingerprint == fingerprint && i.autocrypt));
    // the public key goes out, armored
    let exported = core.pgp_export(&fingerprint).unwrap();
    assert!(exported.starts_with("-----BEGIN PGP PUBLIC KEY BLOCK-----"));
    assert!(!exported.contains("PRIVATE"));
}

#[test]
fn the_store_never_holds_a_private_key_in_the_clear() {
    let dir = pe_testkit::TempDir::new("core-keys-clear");
    let (core, account) = open_core(&dir);
    let fingerprint = core.pgp_generate(account).unwrap();
    let backup = core.pgp_backup(&fingerprint, "a long passphrase").unwrap();
    let key = pe_pgp::read_secret_keys(backup.as_bytes(), "a long passphrase")
        .unwrap()
        .remove(0);
    let plain = key.to_bytes();
    drop(core);
    let mut file = std::fs::read(dir.path().join("store.db")).unwrap();
    for name in ["store.db-wal", "store.db-journal"] {
        if let Ok(more) = std::fs::read(dir.path().join(name)) {
            file.extend(more);
        }
    }
    // every 16 byte stretch of the private key that is not in its public certificate (the store keeps that one in
    // the clear): the secret scalars and their checksums
    let public = key.cert().to_bytes();
    let secret: Vec<&[u8]> = plain
        .windows(16)
        .filter(|window| !public.windows(16).any(|w| w == *window))
        .collect();
    assert!(secret.len() > 32, "the secret material was found in the key");
    for window in secret {
        assert!(
            !file.windows(16).any(|w| w == window),
            "a piece of the private key is in the store file"
        );
    }
}

#[test]
fn a_backup_and_its_import() {
    let dir = pe_testkit::TempDir::new("core-keys-backup");
    let (core, account) = open_core(&dir);
    let fingerprint = core.pgp_generate(account).unwrap();
    assert!(
        core.pgp_backup(&fingerprint, "").is_err(),
        "a backup needs a passphrase"
    );
    let backup = core.pgp_backup(&fingerprint, "correct horse").unwrap();
    assert!(backup.starts_with("-----BEGIN PGP PRIVATE KEY BLOCK-----"));

    // on another computer: the backup asks for its passphrase once
    let other_dir = pe_testkit::TempDir::new("core-keys-backup-other");
    let (other, _) = open_core(&other_dir);
    assert_eq!(
        other.pgp_import(backup.as_bytes(), None, KeySource::File),
        Err(ImportError::NeedsPassphrase)
    );
    assert_eq!(
        other.pgp_import(backup.as_bytes(), Some("wrong"), KeySource::File),
        Err(ImportError::WrongPassphrase)
    );
    let imported = other
        .pgp_import(backup.as_bytes(), Some("correct horse"), KeySource::File)
        .unwrap();
    assert_eq!(
        (imported.keys.as_slice(), imported.private),
        (&[fingerprint.clone()][..], 1)
    );
    let keys = other.pgp_keys().unwrap();
    assert!(keys[0].own && keys[0].state == KeyState::Valid);
    // an imported key does not take the own addresses by itself: a key file can come from anyone; the windows ask
    assert!(other.pgp_identities().unwrap().is_empty());
    assert_eq!(
        imported.own,
        [
            ("alice@example.org".to_string(), fingerprint.clone()),
            ("a@work.example".to_string(), fingerprint.clone())
        ]
    );
    let mut unclaimed = other.pgp_unclaimed().unwrap();
    unclaimed.sort();
    let mut own = imported.own.clone();
    own.sort();
    assert_eq!(unclaimed, own);
    other.pgp_set_identity("alice@example.org", &fingerprint, true).unwrap();
    assert_eq!(
        other.pgp_unclaimed().unwrap(),
        [("a@work.example".to_string(), fingerprint.clone())]
    );
    assert_eq!(
        other.pgp_file_name(&fingerprint, true).unwrap(),
        "Alice Example private key backup.asc"
    );
    assert_eq!(
        other.pgp_file_name(&fingerprint, false).unwrap(),
        "Alice Example public key.asc"
    );
    assert_eq!(other.pgp_identities().unwrap()[0].fingerprint, fingerprint);
}

#[test]
fn a_correspondent_key_and_a_changed_one() {
    let dir = pe_testkit::TempDir::new("core-keys-peer");
    let (core, _) = open_core(&dir);
    let bob = pe_pgp::generate("Bob", &["bob@example.net".into()], now()).unwrap();
    let imported = core
        .pgp_import(bob.cert().armored().as_bytes(), None, KeySource::Paste)
        .unwrap();
    assert_eq!(imported.private, 0);
    assert_eq!(imported.addresses, [("bob@example.net".to_string(), Learned::Used)]);
    let peer = core.pgp_peer("Bob@Example.net").unwrap();
    assert_eq!(peer.in_use.as_deref().unwrap(), bob.fingerprint());
    assert!(peer.pending.is_none());
    assert!(!core.pgp_key(peer.in_use.as_deref().unwrap()).unwrap().own);

    // the same key again changes nothing
    let again = core
        .pgp_import(bob.cert().armored().as_bytes(), None, KeySource::Autocrypt)
        .unwrap();
    assert_eq!(again.addresses, [("bob@example.net".to_string(), Learned::Same)]);

    // another key for Bob's address waits: the one in use stays until the user picks
    let other = pe_pgp::generate("Bob", &["bob@example.net".into()], now()).unwrap();
    let changed = core
        .pgp_import(other.cert().armored().as_bytes(), None, KeySource::Keyserver)
        .unwrap();
    assert_eq!(changed.addresses, [("bob@example.net".to_string(), Learned::Pending)]);
    let peer = core.pgp_peer("bob@example.net").unwrap();
    assert_eq!(peer.in_use.unwrap(), bob.fingerprint());
    assert_eq!(peer.pending.unwrap(), other.fingerprint());
    assert!(peer.pending_since.is_some());
    assert!(peer.pending_text.unwrap().contains("bob@example.net"));

    core.pgp_decide("bob@example.net", false).unwrap();
    let peer = core.pgp_peer("bob@example.net").unwrap();
    assert_eq!((peer.in_use.unwrap(), peer.pending), (bob.fingerprint(), None));

    core.pgp_import(other.cert().armored().as_bytes(), None, KeySource::Keyserver)
        .unwrap();
    core.pgp_decide("bob@example.net", true).unwrap();
    assert_eq!(
        core.pgp_peer("bob@example.net").unwrap().in_use.unwrap(),
        other.fingerprint()
    );

    // verified, per address
    core.pgp_set_verified(&other.fingerprint(), "bob@example.net", true)
        .unwrap();
    let key = core.pgp_key(&other.fingerprint()).unwrap();
    assert_eq!(key.addresses, [("bob@example.net".to_string(), true)]);
    assert!(key.verified);

    // removed: Bob has no key in use
    core.pgp_remove(&other.fingerprint()).unwrap();
    assert!(core.pgp_peer("bob@example.net").unwrap().in_use.is_none());
}

#[test]
fn a_public_key_for_an_own_address_does_not_take_it() {
    let dir = pe_testkit::TempDir::new("core-keys-own-public");
    let (core, account) = open_core(&dir);
    let mine = core.pgp_generate(account).unwrap();
    let stranger = pe_pgp::generate("Mallory", &["alice@example.org".into()], now()).unwrap();
    let imported = core
        .pgp_import(stranger.cert().armored().as_bytes(), None, KeySource::Autocrypt)
        .unwrap();
    assert_eq!(imported.addresses, [("alice@example.org".to_string(), Learned::Own)]);
    let identities = core.pgp_identities().unwrap();
    assert!(identities.iter().all(|identity| identity.fingerprint == mine));
}

#[test]
fn not_keys_are_refused_in_words() {
    let dir = pe_testkit::TempDir::new("core-keys-junk");
    let (core, _) = open_core(&dir);
    match core.pgp_import(b"hello, not a key", None, KeySource::Paste) {
        Err(ImportError::Invalid(words)) => assert!(!words.is_empty()),
        other => panic!("{other:?}"),
    }
}

#[test]
fn keys_travel_in_vcards() {
    let dir = pe_testkit::TempDir::new("core-keys-vcard");
    let (core, _) = open_core(&dir);
    let bob = pe_pgp::generate("Bob", &["bob@example.net".into()], now()).unwrap();
    let line = format!(
        "KEY;TYPE=PGP;ENCODING=b:{}",
        base64::Engine::encode(&base64::engine::general_purpose::STANDARD, bob.cert().to_bytes())
    );
    let file = dir.path().join("bob.vcf");
    std::fs::write(
        &file,
        format!("BEGIN:VCARD\r\nVERSION:3.0\r\nFN:Bob\r\nEMAIL:bob@example.net\r\n{line}\r\nEND:VCARD\r\n"),
    )
    .unwrap();
    let imported = core.import_cards(&[&file]);
    assert_eq!(imported.added, 1, "{imported:?}");
    assert_eq!(
        core.pgp_peer("bob@example.net").unwrap().in_use.unwrap(),
        bob.fingerprint()
    );

    // a card without a key goes out with the key in use for its address
    let carol = pe_pgp::generate("Carol", &["carol@example.net".into()], now()).unwrap();
    core.pgp_import(carol.cert().armored().as_bytes(), None, KeySource::Paste)
        .unwrap();
    let file = dir.path().join("carol.vcf");
    std::fs::write(
        &file,
        "BEGIN:VCARD\r\nVERSION:3.0\r\nFN:Carol\r\nEMAIL:carol@example.net\r\nEND:VCARD\r\n",
    )
    .unwrap();
    core.import_cards(&[&file]);
    let out = dir.path().join("out.vcf");
    core.export_cards(&[], &out).unwrap();
    let written = std::fs::read_to_string(&out).unwrap();
    let unfolded = written.replace("\r\n ", "");
    assert_eq!(unfolded.matches("KEY;TYPE=PGP;ENCODING=b:").count(), 2, "{written}");
    assert_eq!(pe_core::vcard::read_vcards(&written).len(), 2);
    // the keys written are the ones in use, and read back as them
    let keys = pe_core::vcard::read_keys(&written);
    let fingerprints: Vec<String> = keys
        .iter()
        .map(|key| pe_pgp::read_certs(key).unwrap()[0].fingerprint())
        .collect();
    assert!(fingerprints.contains(&bob.fingerprint()) && fingerprints.contains(&carol.fingerprint()));
}

#[test]
fn without_the_master_key_an_own_key_is_locked() {
    let dir = pe_testkit::TempDir::new("core-keys-locked");
    let path = {
        let (core, account) = open_core(&dir);
        core.pgp_generate(account).unwrap();
        dir.path().join("store.db")
    };
    // a new run with memory passwords: the master key of the first run is gone, as after a keychain reset
    let options = Options {
        passwords: PasswordStore::Memory,
        ..Default::default()
    };
    let core = Core::open_with(&path, options, |_| {}).unwrap();
    let keys = core.pgp_keys().unwrap();
    assert_eq!(keys[0].state, KeyState::Locked);
    assert!(keys[0].state_text.contains("backup"), "{}", keys[0].state_text);
    assert!(core.pgp_backup(&keys[0].fingerprint, "pw").is_err());
}
