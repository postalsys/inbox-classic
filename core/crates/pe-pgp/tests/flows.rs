//! Keys made, mail signed and encrypted and opened again, and what must never open: changed ciphertext, the old
//! packet without integrity protection, decompression bombs, deep nesting.

mod forge;

use pe_pgp::{
    DecryptError, Error, Problem, SigStatus, autocrypt, decrypt, decrypt_within, encrypt, generate, needs_passphrase,
    read_certs, read_secret_keys, recipients, sign_detached, verify_detached,
};

/// 1 January 2027: after the fixtures of other implementations were made.
const NOW: i64 = 1_798_761_600;

/// GnuPG's Ed25519 key of the fixtures: it does not announce SEIPDv2.
fn gnupg() -> (pe_pgp::Cert, Vec<pe_pgp::SecretKey>) {
    let dir = std::path::PathBuf::from(env!("CARGO_MANIFEST_DIR")).join("tests/fixtures/interop/gnupg-ed25519");
    let cert = read_certs(&std::fs::read(dir.join("cert.asc")).unwrap())
        .unwrap()
        .remove(0);
    let keys = read_secret_keys(&std::fs::read(dir.join("secret.asc")).unwrap(), "").unwrap();
    (cert, keys)
}
const DATA: &[u8] = b"Content-Type: text/plain; charset=utf-8\r\n\r\nThe meeting moved to Thursday.\r\n";

fn person(name: &str, address: &str) -> pe_pgp::SecretKey {
    generate(name, &[address.to_string()], NOW - 86_400).unwrap()
}

#[test]
fn a_new_key() {
    let alice = generate("Alice", &["alice@example.org".into(), "a@work.example".into()], NOW).unwrap();
    let cert = alice.cert();
    assert_eq!(cert.addresses(NOW), ["alice@example.org", "a@work.example"]);
    assert_eq!(cert.user_ids(NOW)[0].text, "Alice <alice@example.org>");
    assert!(cert.user_ids(NOW)[0].primary);
    assert_eq!(cert.algorithm(), "Ed25519");
    assert!(!cert.is_v6());
    assert_eq!(cert.expires(NOW), None);
    assert!(cert.status(NOW).is_ok() && cert.can_sign(NOW).is_ok() && cert.can_encrypt(NOW).is_ok());
    assert_eq!(cert.fingerprint().len(), 40);
    // the public part has no secret in it
    let public = read_certs(cert.armored().as_bytes()).unwrap();
    assert_eq!(public[0].fingerprint(), cert.fingerprint());
    assert_eq!(
        read_secret_keys(cert.armored().as_bytes(), "").unwrap_err(),
        Error::WrongKind
    );
}

#[test]
fn names_can_not_break_the_user_id() {
    let key = generate("Eve <evil@x.com>\n", &["eve@example.org".into()], NOW).unwrap();
    assert_eq!(key.cert().user_ids(NOW)[0].text, "Eve evil@x.com <eve@example.org>");
    assert_eq!(key.cert().addresses(NOW), ["eve@example.org"]);
}

#[test]
fn sign_and_verify() {
    let alice = person("Alice", "alice@example.org");
    let signed = sign_detached(DATA, &alice, NOW).unwrap();
    assert_eq!(signed.micalg, "pgp-sha256");
    assert!(signed.signature.starts_with("-----BEGIN PGP SIGNATURE-----"));
    let checks = verify_detached(signed.signature.as_bytes(), DATA, &[alice.cert().clone()], NOW).unwrap();
    assert_eq!(checks[0].status, SigStatus::Good);
    assert_eq!(checks[0].created, Some(NOW));
    let checks = verify_detached(signed.signature.as_bytes(), b"other", &[alice.cert().clone()], NOW).unwrap();
    assert_eq!(checks[0].status, SigStatus::Bad(Problem::Mismatch));
}

#[test]
fn encrypt_sign_and_open() {
    let alice = person("Alice", "alice@example.org");
    let bob = person("Bob", "bob@example.org");
    let message = encrypt(DATA, &[bob.cert(), alice.cert()], &[], Some(&alice), NOW).unwrap();
    assert!(message.starts_with("-----BEGIN PGP MESSAGE-----"));
    assert!(!message.contains("Thursday"));
    for reader in [&bob, &alice] {
        let opened = decrypt(
            message.as_bytes(),
            std::slice::from_ref(reader),
            &[alice.cert().clone()],
            NOW,
        )
        .unwrap();
        assert_eq!(opened.data, DATA);
        assert!(opened.encrypted);
        assert!(opened.aead, "both keys announce SEIPDv2");
        assert_eq!(opened.key.as_deref(), Some(reader.fingerprint().as_str()));
        assert_eq!(opened.signatures.len(), 1);
        assert_eq!(opened.signatures[0].status, SigStatus::Good);
        assert_eq!(opened.recipients.len(), 2);
    }
    let carol = person("Carol", "carol@example.org");
    match decrypt(message.as_bytes(), &[carol], &[], NOW) {
        Err(DecryptError::NoKey { recipients }) => assert_eq!(recipients.len(), 2),
        other => panic!("{other:?}"),
    }
    assert_eq!(recipients(message.as_bytes()).unwrap().len(), 2);
}

#[test]
fn seipd_v1_for_those_who_do_not_read_v2() {
    // GnuPG's keys do not announce SEIPDv2: a message to one of them and to a key of ours is SEIPDv1
    let (gnupg, gnupg_key) = gnupg();
    let alice = person("Alice", "alice@example.org");
    let message = encrypt(DATA, &[&gnupg, alice.cert()], &[], Some(&alice), NOW).unwrap();
    let opened = decrypt(message.as_bytes(), &gnupg_key, &[], NOW).unwrap();
    assert!(!opened.aead);
    assert_eq!(opened.data, DATA);
}

#[test]
fn hidden_recipients_are_not_named() {
    let alice = person("Alice", "alice@example.org");
    let bob = person("Bob", "bob@example.org");
    let carol = person("Carol", "carol@example.org");
    let message = encrypt(DATA, &[bob.cert()], &[carol.cert()], Some(&alice), NOW).unwrap();
    let named = recipients(message.as_bytes()).unwrap();
    assert_eq!(named.len(), 2);
    assert!(named.iter().any(|r| r.chars().all(|c| c == '0')), "{named:?}");
    let carol_handles = carol.cert().handles();
    assert!(
        !named.iter().any(|r| carol_handles.contains(r)),
        "Carol is named: {named:?}"
    );
    let opened = decrypt(
        message.as_bytes(),
        std::slice::from_ref(&carol),
        &[alice.cert().clone()],
        NOW,
    )
    .unwrap();
    assert_eq!(opened.data, DATA);
    assert_eq!(opened.signatures[0].status, SigStatus::Good);
}

fn dearmor(armored: &str) -> Vec<u8> {
    use std::io::Read;
    let mut out = Vec::new();
    pgp::armor::Dearmor::new(armored.as_bytes())
        .read_to_end(&mut out)
        .unwrap();
    out
}

#[test]
fn changed_ciphertext_never_opens() {
    let alice = person("Alice", "alice@example.org");
    let bob = person("Bob", "bob@example.org");
    let (gnupg, gnupg_key) = gnupg();
    // SEIPDv2 to Bob, SEIPDv1 to GnuPG's key
    for (message, keys) in [
        (
            encrypt(DATA, &[bob.cert()], &[], Some(&alice), NOW).unwrap(),
            vec![bob.clone()],
        ),
        (encrypt(DATA, &[&gnupg], &[], None, NOW).unwrap(), gnupg_key.clone()),
    ] {
        let binary = dearmor(&message);
        // every byte of the last 60 (the encrypted data and its tag or code), changed in turn
        for at in binary.len() - 60..binary.len() {
            let mut changed = binary.clone();
            changed[at] ^= 0x01;
            assert_eq!(
                decrypt(&changed, &keys, &[], NOW),
                Err(DecryptError::Integrity),
                "byte {at} changed"
            );
        }
    }
}

#[test]
fn the_unprotected_packet_is_refused() {
    // a Symmetrically Encrypted Data packet (type 9), with no integrity protection: EFAIL's way in
    let mut packet = vec![0xC9, 32];
    packet.extend([0x5a; 32]);
    assert_eq!(decrypt(&packet, &[], &[], NOW), Err(DecryptError::Unprotected));
}

#[test]
fn a_decompression_bomb_is_refused() {
    use pgp::composed::MessageBuilder;
    use pgp::types::CompressionAlgorithm;
    let zeros = vec![0u8; 4 * 1024 * 1024];
    let mut builder = MessageBuilder::from_bytes("", zeros);
    builder.compression(CompressionAlgorithm::ZLIB);
    let message = builder.to_vec(rand::thread_rng()).unwrap();
    assert!(message.len() < 64 * 1024);
    assert_eq!(
        decrypt_within(&message, &[], &[], NOW, 1024 * 1024),
        Err(DecryptError::TooLarge)
    );
    assert_eq!(
        decrypt_within(&message, &[], &[], NOW, 8 * 1024 * 1024)
            .unwrap()
            .data
            .len(),
        4 * 1024 * 1024
    );
}

/// A packet in the new format with `body`.
fn packet(tag: u8, body: &[u8]) -> Vec<u8> {
    let mut out = vec![0xC0 | tag];
    let len = body.len();
    if len < 192 {
        out.push(len as u8);
    } else if len < 8384 {
        let len = len - 192;
        out.push((len >> 8) as u8 + 192);
        out.push((len & 0xff) as u8);
    } else {
        out.push(0xff);
        out.extend((len as u32).to_be_bytes());
    }
    out.extend(body);
    out
}

#[test]
fn deep_nesting_does_not_crash() {
    // a literal packet in 3000 compressed packets of the "uncompressed" algorithm
    let mut message = packet(11, b"b\x00\x00\x00\x00\x00hello");
    for _ in 0..3000 {
        let mut body = vec![0u8];
        body.extend(&message);
        message = packet(8, &body);
    }
    let result = std::thread::Builder::new()
        .stack_size(2 * 1024 * 1024)
        .spawn(move || decrypt(&message, &[], &[], NOW).map(|opened| opened.data))
        .unwrap()
        .join();
    assert!(result.is_ok(), "the thread panicked or overflowed its stack");
}

#[test]
fn a_backup_and_its_passphrase() {
    let alice = person("Alice", "alice@example.org");
    let backup = alice.backup("correct horse").unwrap();
    assert!(backup.starts_with("-----BEGIN PGP PRIVATE KEY BLOCK-----"));
    assert!(needs_passphrase(backup.as_bytes()).unwrap());
    assert_eq!(
        read_secret_keys(backup.as_bytes(), "wrong").unwrap_err(),
        Error::WrongPassphrase
    );
    let back = read_secret_keys(backup.as_bytes(), "correct horse").unwrap();
    assert_eq!(back[0].fingerprint(), alice.fingerprint());
    // the stored form has no passphrase and opens directly
    let stored = alice.to_bytes();
    assert!(!needs_passphrase(&stored).unwrap());
    let again = pe_pgp::SecretKey::from_bytes(&stored).unwrap();
    let message = encrypt(DATA, &[alice.cert()], &[], None, NOW).unwrap();
    assert_eq!(decrypt(message.as_bytes(), &[again], &[], NOW).unwrap().data, DATA);
    // a protected key is not taken as the stored form
    assert!(pe_pgp::SecretKey::from_bytes(&dearmor(&backup)).is_err());
}

#[test]
fn merging_two_copies_of_a_key() {
    use forge::*;
    let mut key = forge::key(Y2020, "Alice <alice@example.org>");
    let first = cert(&key);
    // the owner adds a second user id later
    let mut second = key.details.users[0].clone();
    second.id = pgp::packet::UserId::from_str(Default::default(), "Alice <alice@work.example>").unwrap();
    key.details.users.push(second);
    bind_user(
        &mut key,
        1,
        Y2022,
        pgp::crypto::hash::HashAlgorithm::Sha256,
        None,
        flags(true, true, false),
    );
    let newer = cert(&key);
    let merged = first.merge(&newer).unwrap();
    assert_eq!(merged.addresses(NOW), ["alice@example.org", "alice@work.example"]);
    let other = cert(&forge::key(Y2020, "Bob <bob@example.org>"));
    assert!(first.merge(&other).is_none());
}

#[test]
fn the_smallest_certificate_for_autocrypt() {
    let alice = generate("Alice", &["alice@example.org".into(), "a@work.example".into()], NOW).unwrap();
    let minimal = alice.cert().minimal("a@work.example", NOW).unwrap();
    assert_eq!(minimal.addresses(NOW), ["a@work.example"]);
    assert!(minimal.can_encrypt(NOW).is_ok());
    assert!(minimal.to_bytes().len() < alice.cert().to_bytes().len());
    assert!(alice.cert().minimal("someone@else.example", NOW).is_none());
    // a message encrypted to the minimal certificate opens with the full key
    let message = encrypt(DATA, &[&minimal], &[], None, NOW).unwrap();
    assert_eq!(decrypt(message.as_bytes(), &[alice], &[], NOW).unwrap().data, DATA);
}

#[test]
fn an_autocrypt_header_round_trip() {
    let alice = person("Alice", "alice@example.org");
    let minimal = alice.cert().minimal("alice@example.org", NOW).unwrap();
    let value = autocrypt::build("alice@example.org", &minimal.to_bytes(), false);
    assert!(value.lines().count() == 1 && value.split(' ').all(|part| part.len() <= 90));
    let header = autocrypt::parse(&value).unwrap();
    let read = read_certs(&header.keydata).unwrap();
    assert_eq!(read[0].fingerprint(), alice.fingerprint());
}

#[test]
fn autocrypt_example_keys_from_the_specification() {
    // rPGP's copies of the keys of Autocrypt's examples
    let alice = include_str!("fixtures/autocrypt-alice.pub.asc");
    let certs = read_certs(alice.as_bytes()).unwrap();
    let y2020 = 1_577_836_800;
    assert_eq!(certs[0].addresses(y2020), ["alice@autocrypt.example"]);
    assert!(certs[0].can_encrypt(y2020).is_ok());
    // it expired in January 2021
    assert_eq!(
        certs[0].can_encrypt(NOW),
        Err(pe_pgp::CertProblem::Expired { at: 1_611_230_185 })
    );
}
