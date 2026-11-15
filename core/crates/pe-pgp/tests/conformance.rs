//! What GnuPG, Sequoia and OpenPGP.js make, read here: their keys, detached signatures, encrypted and signed and
//! encrypted messages (`fixtures/interop`, made by `fixtures/generate.sh`). And what is made here, read back with
//! their keys. That the other implementations read what this one makes is checked by CI against Sequoia's sqop.

use std::fs;
use std::path::PathBuf;

use pe_pgp::{SigStatus, decrypt, encrypt, read_certs, read_secret_keys, sign_detached, verify_detached};

/// 1 January 2027: after the fixtures were made.
const NOW: i64 = 1_798_761_600;

/// A file of a case.
fn read(dir: &std::path::Path, name: &str) -> Vec<u8> {
    fs::read(dir.join(name)).unwrap()
}

fn cases() -> Vec<(String, PathBuf)> {
    let root = PathBuf::from(env!("CARGO_MANIFEST_DIR")).join("tests/fixtures/interop");
    let mut out: Vec<(String, PathBuf)> = fs::read_dir(&root)
        .unwrap()
        .map(|entry| entry.unwrap().path())
        .filter(|path| path.is_dir())
        .map(|path| (path.file_name().unwrap().to_string_lossy().into_owned(), path))
        .collect();
    out.sort();
    assert!(
        out.len() >= 7,
        "the interop fixtures are missing: run tests/fixtures/generate.sh"
    );
    out
}

#[test]
fn their_signatures_verify() {
    for (name, dir) in cases() {
        let certs = read_certs(&read(&dir, "cert.asc")).unwrap();
        let data = read(&dir, "data.txt");
        let checks = verify_detached(&read(&dir, "data.sig"), &data, &certs, NOW).unwrap();
        assert_eq!(checks.len(), 1, "{name}");
        assert_eq!(checks[0].status, SigStatus::Good, "{name}");
        assert_eq!(
            checks[0].cert.as_deref(),
            Some(certs[0].fingerprint().as_str()),
            "{name}"
        );
        let mut changed = data.clone();
        changed[60] ^= 1;
        let checks = verify_detached(&read(&dir, "data.sig"), &changed, &certs, NOW).unwrap();
        assert!(!checks[0].is_good(), "{name}");
    }
}

#[test]
fn their_keys_have_their_addresses() {
    for (name, dir) in cases() {
        let certs = read_certs(&read(&dir, "cert.asc")).unwrap();
        let addresses = certs[0].addresses(NOW);
        assert_eq!(addresses.len(), 1, "{name}: {addresses:?}");
        assert!(addresses[0].ends_with("@example.org"), "{name}");
        assert!(certs[0].can_encrypt(NOW).is_ok(), "{name}");
        assert!(certs[0].can_sign(NOW).is_ok(), "{name}");
    }
}

#[test]
fn their_messages_decrypt() {
    for (name, dir) in cases() {
        let keys = read_secret_keys(&read(&dir, "secret.asc"), "").unwrap();
        let data = read(&dir, "data.txt");
        let opened = decrypt(&read(&dir, "encrypted.asc"), &keys, &[], NOW).unwrap();
        assert!(opened.encrypted, "{name}");
        assert_eq!(opened.data, data, "{name}");
        assert!(opened.signatures.is_empty(), "{name}");
        assert_eq!(opened.key.as_deref(), Some(keys[0].fingerprint().as_str()), "{name}");
        if name.ends_with("v6") {
            assert!(opened.aead, "{name}");
        }
    }
}

#[test]
fn their_signed_messages_decrypt_and_verify() {
    for (name, dir) in cases() {
        let keys = read_secret_keys(&read(&dir, "secret.asc"), "").unwrap();
        let certs = read_certs(&read(&dir, "cert.asc")).unwrap();
        let data = read(&dir, "data.txt");
        let opened = decrypt(&read(&dir, "signed.asc"), &keys, &certs, NOW).unwrap();
        assert_eq!(opened.data, data, "{name}");
        assert_eq!(opened.signatures.len(), 1, "{name}");
        assert_eq!(opened.signatures[0].status, SigStatus::Good, "{name}");
        // without the certificate the signature is there, its key unknown
        let opened = decrypt(&read(&dir, "signed.asc"), &keys, &[], NOW).unwrap();
        assert_eq!(opened.signatures[0].status, SigStatus::UnknownKey, "{name}");
    }
}

#[test]
fn what_is_made_here_opens_with_their_keys() {
    let me = pe_pgp::generate("Me", &["me@example.net".to_string()], NOW - 86_400).unwrap();
    for (name, dir) in cases() {
        let keys = read_secret_keys(&read(&dir, "secret.asc"), "").unwrap();
        let certs = read_certs(&read(&dir, "cert.asc")).unwrap();
        let data = b"Content-Type: text/plain\r\n\r\nHi\r\n";
        let message = encrypt(&data[..], &[&certs[0]], &[], Some(&me), NOW).unwrap();
        let opened = decrypt(message.as_bytes(), &keys, &[me.cert().clone()], NOW).unwrap();
        assert_eq!(opened.data, data, "{name}");
        assert_eq!(opened.signatures[0].status, SigStatus::Good, "{name}");
        // their signing keys sign here too
        let signed = sign_detached(data, &keys[0], NOW).unwrap();
        let checks = verify_detached(signed.signature.as_bytes(), data, &certs, NOW).unwrap();
        assert_eq!(checks[0].status, SigStatus::Good, "{name}");
    }
}
