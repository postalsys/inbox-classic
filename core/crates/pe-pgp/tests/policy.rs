//! The policy, one test a row: what a signature is worth when its key expired, was revoked, used an old hash, was
//! not allowed to sign, or came from the future. Keys and signatures are made by hand at chosen times (`forge`).

mod forge;

use forge::*;
use pe_pgp::{Problem, SigStatus, verify_detached};
use pgp::crypto::hash::HashAlgorithm;
use pgp::packet::{RevocationCode, SignatureType};

const DATA: &[u8] = b"Content-Type: text/plain\r\n\r\nPay Bob 10 euros.\r\n";

fn status(key: &pgp::composed::SignedSecretKey, sig: Sig) -> SigStatus {
    let signature = sign(key, DATA, sig);
    let checks = verify_detached(&signature, DATA, &[cert(key)], NOW).unwrap();
    assert_eq!(checks.len(), 1);
    checks[0].status.clone()
}

#[test]
fn a_good_signature() {
    let alice = key(Y2020, "Alice <alice@example.org>");
    assert_eq!(status(&alice, Sig::at(Y2021)), SigStatus::Good);
    let checks = verify_detached(&sign(&alice, DATA, Sig::at(Y2021)), DATA, &[cert(&alice)], NOW).unwrap();
    assert_eq!(checks[0].cert.as_deref(), Some(cert(&alice).fingerprint().as_str()));
    assert_eq!(checks[0].created, Some(i64::from(Y2021)));
}

#[test]
fn changed_data_does_not_match() {
    let alice = key(Y2020, "Alice <alice@example.org>");
    let signature = sign(&alice, DATA, Sig::at(Y2021));
    let checks = verify_detached(&signature, b"Pay Mallory 1000 euros.", &[cert(&alice)], NOW).unwrap();
    assert_eq!(checks[0].status, SigStatus::Bad(Problem::Mismatch));
}

#[test]
fn an_unknown_key() {
    let alice = key(Y2020, "Alice <alice@example.org>");
    let bob = key(Y2020, "Bob <bob@example.org>");
    let signature = sign(&alice, DATA, Sig::at(Y2021));
    let checks = verify_detached(&signature, DATA, &[cert(&bob)], NOW).unwrap();
    assert_eq!(checks[0].status, SigStatus::UnknownKey);
    assert!(checks[0].issuers.contains(&cert(&alice).fingerprint()));
}

#[test]
fn sha1_data_signatures_until_2013() {
    let alice = rsa_key();
    assert_eq!(
        status(
            &alice,
            Sig {
                hash: HashAlgorithm::Sha1,
                ..Sig::at(Y2012)
            }
        ),
        SigStatus::Good
    );
    assert_eq!(
        status(
            &alice,
            Sig {
                hash: HashAlgorithm::Sha1,
                ..Sig::at(Y2020)
            }
        ),
        SigStatus::Bad(Problem::WeakHash("SHA1".into()))
    );
}

#[test]
fn md5_never() {
    let alice = rsa_key();
    assert_eq!(
        status(
            &alice,
            Sig {
                hash: HashAlgorithm::Md5,
                ..Sig::at(Y2012)
            }
        ),
        SigStatus::Bad(Problem::WeakHash("MD5".into()))
    );
}

#[test]
fn sha1_bindings_until_2023() {
    let mut old = rsa_key();
    bind(&mut old, Y2020, HashAlgorithm::Sha1, None);
    assert_eq!(status(&old, Sig::at(Y2021)), SigStatus::Good);
    let mut new = rsa_key();
    bind(&mut new, Y2024, HashAlgorithm::Sha1, None);
    assert_eq!(cert(&new).user_ids(NOW), vec![]);
    assert_eq!(
        status(&new, Sig::at(Y2024 + MONTH)),
        SigStatus::Bad(Problem::KeyNotValid)
    );
}

#[test]
fn an_expired_key_signed_before_it_expired() {
    let mut alice = key(Y2020, "Alice <alice@example.org>");
    bind(&mut alice, Y2020, HashAlgorithm::Sha256, Some(YEAR));
    assert_eq!(status(&alice, Sig::at(Y2020 + 6 * MONTH)), SigStatus::Good);
    assert!(cert(&alice).status(NOW).is_err());
}

#[test]
fn an_expired_key_signed_after_it_expired() {
    let mut alice = key(Y2020, "Alice <alice@example.org>");
    bind(&mut alice, Y2020, HashAlgorithm::Sha256, Some(YEAR));
    let at = i64::from(Y2020 + YEAR);
    assert_eq!(
        status(&alice, Sig::at(Y2021 + 6 * MONTH)),
        SigStatus::Bad(Problem::KeyExpired { at })
    );
}

#[test]
fn an_extended_key_counts_from_the_new_binding() {
    let mut alice = key(Y2020, "Alice <alice@example.org>");
    bind(&mut alice, Y2020, HashAlgorithm::Sha256, Some(YEAR));
    // a year later the owner extends the key by three years; the old binding stays for the time before
    let first = alice.details.users[0].signatures.clone();
    bind(&mut alice, Y2021 - MONTH, HashAlgorithm::Sha256, Some(3 * YEAR));
    alice.details.users[0].signatures.extend(first);
    assert_eq!(status(&alice, Sig::at(Y2022)), SigStatus::Good);
}

#[test]
fn a_soft_revocation_counts_from_its_time() {
    let mut alice = key(Y2020, "Alice <alice@example.org>");
    revoke(&mut alice, Y2022, Some(RevocationCode::KeySuperseded));
    assert_eq!(status(&alice, Sig::at(Y2021)), SigStatus::Good);
    assert!(matches!(
        status(&alice, Sig::at(Y2023)),
        SigStatus::Bad(Problem::KeyRevoked { .. })
    ));
}

#[test]
fn a_hard_revocation_counts_backwards() {
    for code in [
        Some(RevocationCode::KeyCompromised),
        Some(RevocationCode::NoReason),
        None,
    ] {
        let mut alice = key(Y2020, "Alice <alice@example.org>");
        revoke(&mut alice, Y2022, code);
        assert!(
            matches!(
                status(&alice, Sig::at(Y2021)),
                SigStatus::Bad(Problem::KeyRevoked { .. })
            ),
            "{code:?}"
        );
    }
}

#[test]
fn a_revocation_by_someone_else_is_ignored() {
    let mut alice = key(Y2020, "Alice <alice@example.org>");
    let mut mallory = key(Y2020, "Mallory <m@example.org>");
    revoke(&mut mallory, Y2022, Some(RevocationCode::KeyCompromised));
    alice
        .details
        .revocation_signatures
        .push(mallory.details.revocation_signatures[0].clone());
    assert_eq!(status(&alice, Sig::at(Y2023)), SigStatus::Good);
}

#[test]
fn a_signature_from_the_future() {
    let alice = key(Y2020, "Alice <alice@example.org>");
    let tomorrow = u32::try_from(NOW).unwrap() + 86_400;
    assert_eq!(status(&alice, Sig::at(tomorrow)), SigStatus::Bad(Problem::FromFuture));
}

#[test]
fn a_signature_before_its_key_existed() {
    let alice = key(Y2022, "Alice <alice@example.org>");
    assert_eq!(status(&alice, Sig::at(Y2020)), SigStatus::Bad(Problem::FromFuture));
}

#[test]
fn an_expired_signature() {
    let alice = key(Y2020, "Alice <alice@example.org>");
    assert_eq!(
        status(
            &alice,
            Sig {
                expires: Some(MONTH),
                ..Sig::at(Y2021)
            }
        ),
        SigStatus::Bad(Problem::SignatureExpired)
    );
    assert_eq!(
        status(
            &alice,
            Sig {
                expires: Some(20 * YEAR),
                ..Sig::at(Y2021)
            }
        ),
        SigStatus::Good
    );
}

#[test]
fn a_signing_subkey() {
    let (alice, sub) = with_subkey(Y2020, "Alice <alice@example.org>", flags(true, false, false), true);
    assert_eq!(
        status(
            &alice,
            Sig {
                subkey: Some(sub),
                ..Sig::at(Y2021)
            }
        ),
        SigStatus::Good
    );
}

#[test]
fn a_signing_subkey_without_its_back_signature() {
    // anyone can bind someone else's signing key to their own certificate; the back signature proves the subkey's
    // owner agreed
    let (mallory, sub) = with_subkey(Y2020, "Mallory <m@example.org>", flags(true, false, false), false);
    assert_eq!(
        status(
            &mallory,
            Sig {
                subkey: Some(sub),
                ..Sig::at(Y2021)
            }
        ),
        SigStatus::Bad(Problem::NotSigningKey)
    );
}

#[test]
fn a_subkey_not_allowed_to_sign() {
    let (alice, sub) = with_subkey(Y2020, "Alice <alice@example.org>", flags(false, false, false), true);
    assert_eq!(
        status(
            &alice,
            Sig {
                subkey: Some(sub),
                ..Sig::at(Y2021)
            }
        ),
        SigStatus::Bad(Problem::NotSigningKey)
    );
}

#[test]
fn a_primary_key_not_allowed_to_sign() {
    let mut alice = key(Y2020, "Alice <alice@example.org>");
    bind_user(
        &mut alice,
        0,
        Y2020,
        HashAlgorithm::Sha256,
        None,
        flags(false, true, false),
    );
    assert_eq!(status(&alice, Sig::at(Y2021)), SigStatus::Bad(Problem::NotSigningKey));
}

#[test]
fn only_document_signatures() {
    // a signature of another type is not a signature of the document, whatever it covers (GHSA-h834-358q-rx97):
    // the key's own certification and subkey binding, presented as detached signatures
    use pgp::composed::{ArmorOptions, DetachedSignature};
    let alice = key(Y2020, "Alice <alice@example.org>");
    let others = [
        alice.details.users[0].signatures[0].clone(),
        alice.secret_subkeys[0].signatures[0].clone(),
    ];
    for other in others {
        let typ = other.typ();
        let armored = DetachedSignature::new(other)
            .to_armored_bytes(ArmorOptions::default())
            .unwrap();
        let checks = verify_detached(&armored, DATA, &[cert(&alice)], NOW).unwrap();
        assert_eq!(checks[0].status, SigStatus::Bad(Problem::WrongType), "{typ:?}");
    }
    assert_eq!(
        status(
            &alice,
            Sig {
                typ: SignatureType::Text,
                ..Sig::at(Y2021)
            }
        ),
        SigStatus::Good
    );
}

#[test]
fn a_third_party_user_id_is_dropped() {
    // Mallory adds "alice@example.org" to his certificate with a signature by Alice's key made for something else:
    // it does not verify as Mallory's own, so the user id is gone when the certificate is read
    let mut mallory = key(Y2020, "Mallory <m@example.org>");
    let alice = key(Y2020, "Alice <alice@example.org>");
    let mut stolen = alice.details.users[0].clone();
    stolen.signatures = alice.details.users[0].signatures.clone();
    mallory.details.users.push(stolen);
    let read = cert(&mallory);
    assert_eq!(read.addresses(NOW), ["m@example.org"]);
}

#[test]
fn rsa_under_2048_is_refused() {
    use pgp::composed::{KeyType, SecretKeyParamsBuilder};
    let Ok(params) = SecretKeyParamsBuilder::default()
        .key_type(KeyType::Rsa(1024))
        .can_certify(true)
        .can_sign(true)
        .primary_user_id("Old <old@example.org>".into())
        .build()
    else {
        return;
    };
    let Ok(key) = params.generate(rand::thread_rng()) else {
        return;
    };
    let bytes = pgp::ser::Serialize::to_bytes(&key.to_public_key()).unwrap();
    assert!(matches!(pe_pgp::read_certs(&bytes), Err(pe_pgp::Error::Unusable(_))));
}
