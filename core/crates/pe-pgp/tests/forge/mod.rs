//! Keys and signatures made by hand at chosen times, with chosen algorithms and flags, for the rows of the policy:
//! what a normal program would refuse to make (a key that expired before it signed, SHA-1 in 2020) is made here.
#![allow(dead_code)]

use std::io::Cursor;

use pgp::composed::{
    ArmorOptions, DetachedSignature, EncryptionCaps, KeyType, SecretKeyParamsBuilder, SignedSecretKey,
    SubkeyParamsBuilder,
};
use pgp::crypto::ecc_curve::ECCCurve;
use pgp::crypto::hash::HashAlgorithm;
use pgp::packet::{KeyFlags, RevocationCode, SecretSubkey, SignatureConfig, SignatureType, Subpacket, SubpacketData};
use pgp::ser::Serialize;
use pgp::types::{Duration, KeyDetails, Password, Tag, Timestamp};

pub const Y2010: u32 = 1_262_304_000;
pub const Y2012: u32 = 1_325_376_000;
pub const Y2020: u32 = 1_577_836_800;
pub const Y2021: u32 = 1_609_459_200;
pub const Y2022: u32 = 1_640_995_200;
pub const Y2023: u32 = 1_672_531_200;
pub const Y2024: u32 = 1_704_067_200;
/// "Now" in these tests: 15 November 2026.
pub const NOW: i64 = 1_794_700_800;
pub const MONTH: u32 = 30 * 86_400;
pub const YEAR: u32 = 365 * 86_400;

/// A v4 key made at `created`, Ed25519 to certify and sign, with `subkeys`, and one user id, its binding made again
/// by `bind` (SHA-256, no expiry, made when the key was).
fn generate(created: u32, user_id: &str, subkeys: Vec<pgp::composed::SubkeyParams>) -> SignedSecretKey {
    let params = SecretKeyParamsBuilder::default()
        .key_type(KeyType::Ed25519Legacy)
        .can_certify(true)
        .can_sign(true)
        .created_at(Timestamp::from_secs(created))
        .primary_user_id(user_id.into())
        .subkeys(subkeys)
        .build()
        .unwrap();
    let mut key = params.generate(rand::thread_rng()).unwrap();
    bind(&mut key, created, HashAlgorithm::Sha256, None);
    key
}

fn subkey(created: u32, key_type: KeyType, sign: bool) -> pgp::composed::SubkeyParams {
    let mut params = SubkeyParamsBuilder::default();
    params.key_type(key_type).created_at(Timestamp::from_secs(created));
    if sign {
        params.can_sign(true);
    } else {
        params.can_encrypt(EncryptionCaps::All);
    }
    params.build().unwrap()
}

/// A key made at `created` with a Curve25519 encryption subkey.
pub fn key(created: u32, user_id: &str) -> SignedSecretKey {
    let mut key = generate(
        created,
        user_id,
        vec![subkey(created, KeyType::ECDH(ECCCurve::Curve25519Legacy), false)],
    );
    bind_subkey(&mut key, 0, created, None, encrypt_flags());
    key
}

fn subpackets(at: u32, fingerprint: pgp::types::Fingerprint) -> Vec<Subpacket> {
    vec![
        Subpacket::regular(SubpacketData::SignatureCreationTime(Timestamp::from_secs(at))).unwrap(),
        Subpacket::regular(SubpacketData::IssuerFingerprint(fingerprint)).unwrap(),
    ]
}

pub fn flags(sign: bool, certify: bool, encrypt: bool) -> KeyFlags {
    let mut flags = KeyFlags::default();
    flags.set_sign(sign);
    flags.set_certify(certify);
    flags.set_encrypt_comms(encrypt);
    flags.set_encrypt_storage(encrypt);
    flags
}

pub fn encrypt_flags() -> KeyFlags {
    flags(false, false, true)
}

/// Replaces the first user id's binding with one made at `at` with `hash`, the key expiring `expires` seconds after
/// its creation.
pub fn bind(key: &mut SignedSecretKey, at: u32, hash: HashAlgorithm, expires: Option<u32>) {
    bind_user(key, 0, at, hash, expires, flags(true, true, false));
}

/// Replaces user id `index`'s binding with one made at `at` with `hash` and `flags`.
pub fn bind_user(
    key: &mut SignedSecretKey,
    index: usize,
    at: u32,
    hash: HashAlgorithm,
    expires: Option<u32>,
    flags: KeyFlags,
) {
    let mut config = SignatureConfig::v4(SignatureType::CertPositive, key.primary_key.algorithm(), hash);
    config.hashed_subpackets = subpackets(at, key.primary_key.fingerprint());
    config
        .hashed_subpackets
        .push(Subpacket::regular(SubpacketData::KeyFlags(flags)).unwrap());
    if let Some(expires) = expires {
        config
            .hashed_subpackets
            .push(Subpacket::regular(SubpacketData::KeyExpirationTime(Duration::from_secs(expires))).unwrap());
    }
    let user = key.details.users[index].id.clone();
    let public = key.primary_key.public_key().clone();
    let sig = config
        .sign_certification(&key.primary_key, &public, &Password::empty(), Tag::UserId, &user)
        .unwrap();
    key.details.users[index].signatures = vec![sig];
}

/// Replaces subkey `index`'s binding with one made at `at`.
pub fn bind_subkey(key: &mut SignedSecretKey, index: usize, at: u32, expires: Option<u32>, flags: KeyFlags) {
    let sig = subkey_binding(key, &key.secret_subkeys[index].key, at, expires, flags, true);
    key.secret_subkeys[index].signatures = vec![sig];
}

fn subkey_binding(
    key: &SignedSecretKey,
    sub: &SecretSubkey,
    at: u32,
    expires: Option<u32>,
    flags: KeyFlags,
    backsig: bool,
) -> pgp::packet::Signature {
    let mut config = SignatureConfig::v4(
        SignatureType::SubkeyBinding,
        key.primary_key.algorithm(),
        HashAlgorithm::Sha256,
    );
    config.hashed_subpackets = subpackets(at, key.primary_key.fingerprint());
    let signs = flags.sign();
    config
        .hashed_subpackets
        .push(Subpacket::regular(SubpacketData::KeyFlags(flags)).unwrap());
    if let Some(expires) = expires {
        config
            .hashed_subpackets
            .push(Subpacket::regular(SubpacketData::KeyExpirationTime(Duration::from_secs(expires))).unwrap());
    }
    if signs && backsig {
        let mut back = SignatureConfig::v4(SignatureType::KeyBinding, sub.algorithm(), HashAlgorithm::Sha256);
        back.hashed_subpackets = subpackets(at, sub.fingerprint());
        let back = back
            .sign_primary_key_binding(sub, sub.public_key(), &Password::empty(), key.primary_key.public_key())
            .unwrap();
        config
            .unhashed_subpackets
            .push(Subpacket::regular(SubpacketData::EmbeddedSignature(Box::new(back))).unwrap());
    }
    let public = key.primary_key.public_key().clone();
    config
        .sign_subkey_binding(&key.primary_key, &public, &Password::empty(), sub.public_key())
        .unwrap()
}

/// A key like `key` with a second subkey, Ed25519, bound with `flags`; signing ones get the back signature if
/// `backsig`. Returns the key and the subkey's index.
pub fn with_subkey(created: u32, user_id: &str, flags: KeyFlags, backsig: bool) -> (SignedSecretKey, usize) {
    let mut key = generate(
        created,
        user_id,
        vec![
            subkey(created, KeyType::ECDH(ECCCurve::Curve25519Legacy), false),
            subkey(created, KeyType::Ed25519Legacy, true),
        ],
    );
    bind_subkey(&mut key, 0, created, None, encrypt_flags());
    let sig = subkey_binding(&key, &key.secret_subkeys[1].key, created, None, flags, backsig);
    key.secret_subkeys[1].signatures = vec![sig];
    (key, 1)
}

/// Adds a key revocation made at `at`.
pub fn revoke(key: &mut SignedSecretKey, at: u32, code: Option<RevocationCode>) {
    let mut config = SignatureConfig::v4(
        SignatureType::KeyRevocation,
        key.primary_key.algorithm(),
        HashAlgorithm::Sha256,
    );
    config.hashed_subpackets = subpackets(at, key.primary_key.fingerprint());
    if let Some(code) = code {
        config
            .hashed_subpackets
            .push(Subpacket::regular(SubpacketData::RevocationReason(code, "reason".into())).unwrap());
    }
    let public = key.primary_key.public_key().clone();
    let sig = config.sign_key(&key.primary_key, &Password::empty(), &public).unwrap();
    key.details.revocation_signatures.push(sig);
}

/// An RSA 2048 key made by GnuPG on 1 January 2010 (`fixtures/rsa2010.sec.asc`), for the old hashes, which Ed25519
/// can not be used with. Its user id binding is made again by `bind`.
pub fn rsa_key() -> SignedSecretKey {
    use pgp::composed::Deserializable;
    let armored = include_str!("../fixtures/rsa2010.sec.asc");
    let (mut key, _) = SignedSecretKey::from_string(armored).unwrap();
    key.secret_subkeys.clear();
    key.public_subkeys.clear();
    bind(&mut key, Y2010, HashAlgorithm::Sha256, None);
    key
}

/// The options of a hand-made data signature.
pub struct Sig {
    pub at: u32,
    pub hash: HashAlgorithm,
    pub typ: SignatureType,
    pub expires: Option<u32>,
    /// Sign with this subkey rather than the primary key.
    pub subkey: Option<usize>,
    /// A notation in the hashed area marked critical.
    pub critical_notation: bool,
}

impl Sig {
    pub fn at(at: u32) -> Sig {
        Sig {
            at,
            hash: HashAlgorithm::Sha256,
            typ: SignatureType::Binary,
            expires: None,
            subkey: None,
            critical_notation: false,
        }
    }
}

/// An armored detached signature over `data`.
pub fn sign(key: &SignedSecretKey, data: &[u8], options: Sig) -> Vec<u8> {
    let sig = match options.subkey {
        None => make(&key.primary_key, data, &options),
        Some(i) => make(&key.secret_subkeys[i].key, data, &options),
    };
    DetachedSignature::new(sig)
        .to_armored_bytes(ArmorOptions::default())
        .unwrap()
}

fn make(signer: &impl pgp::types::SigningKey, data: &[u8], options: &Sig) -> pgp::packet::Signature {
    let mut config = SignatureConfig::v4(options.typ, signer.algorithm(), options.hash);
    config.hashed_subpackets = subpackets(options.at, signer.fingerprint());
    if let Some(expires) = options.expires {
        config
            .hashed_subpackets
            .push(Subpacket::regular(SubpacketData::SignatureExpirationTime(Duration::from_secs(expires))).unwrap());
    }
    if options.critical_notation {
        config.hashed_subpackets.push(notation(true));
    }
    config.unhashed_subpackets = vec![Subpacket::regular(SubpacketData::IssuerKeyId(signer.legacy_key_id())).unwrap()];
    config.sign(signer, &Password::empty(), Cursor::new(data)).unwrap()
}

/// The certificate of `key`, read the way the app reads one.
pub fn cert(key: &SignedSecretKey) -> pe_pgp::Cert {
    let bytes = key.to_public_key().to_bytes().unwrap();
    pe_pgp::read_certs(&bytes).unwrap().remove(0)
}

/// `key` as the app's private key.
pub fn secret(key: &SignedSecretKey) -> pe_pgp::SecretKey {
    pe_pgp::SecretKey::from_bytes(&key.to_bytes().unwrap()).unwrap()
}

/// A notation subpacket nobody understands, critical or not.
pub fn notation(critical: bool) -> Subpacket {
    let data = SubpacketData::Notation(pgp::packet::Notation {
        readable: true,
        name: "unknown@example.org".into(),
        value: "x".into(),
    });
    if critical {
        Subpacket::critical(data).unwrap()
    } else {
        Subpacket::regular(data).unwrap()
    }
}

/// How a signing subkey's binding is made, for the rows about back signatures and notations.
#[derive(Default)]
pub struct Binding {
    /// The embedded signatures, in this order: a real back signature (expiring after the seconds given), or a false
    /// one (made by another key).
    pub backs: Vec<Back>,
    /// A critical notation in the binding itself.
    pub critical_notation: bool,
}

pub enum Back {
    Real {
        expires: Option<u32>,
        critical_notation: bool,
    },
    Fake,
}

/// A key like `with_subkey`'s, its signing subkey bound as `binding` says. Returns the key and the subkey's index.
pub fn with_signing_subkey(created: u32, user_id: &str, binding: Binding) -> (SignedSecretKey, usize) {
    let (mut key, index) = with_subkey(created, user_id, flags(true, false, false), false);
    let other = generate(
        created,
        "Other <other@example.org>",
        vec![subkey(created, KeyType::Ed25519Legacy, true)],
    );
    let sub = key.secret_subkeys[index].key.clone();
    let mut config = SignatureConfig::v4(
        SignatureType::SubkeyBinding,
        key.primary_key.algorithm(),
        HashAlgorithm::Sha256,
    );
    config.hashed_subpackets = subpackets(created, key.primary_key.fingerprint());
    config
        .hashed_subpackets
        .push(Subpacket::regular(SubpacketData::KeyFlags(flags(true, false, false))).unwrap());
    if binding.critical_notation {
        config.hashed_subpackets.push(notation(true));
    }
    for back in binding.backs {
        let (signer, critical, expires) = match back {
            Back::Real {
                expires,
                critical_notation,
            } => (&sub, critical_notation, expires),
            Back::Fake => (&other.secret_subkeys[0].key, false, None),
        };
        let mut back = SignatureConfig::v4(SignatureType::KeyBinding, signer.algorithm(), HashAlgorithm::Sha256);
        back.hashed_subpackets = subpackets(created, signer.fingerprint());
        if let Some(expires) = expires {
            back.hashed_subpackets.push(
                Subpacket::regular(SubpacketData::SignatureExpirationTime(Duration::from_secs(expires))).unwrap(),
            );
        }
        if critical {
            back.hashed_subpackets.push(notation(true));
        }
        let back = back
            .sign_primary_key_binding(
                signer,
                signer.public_key(),
                &Password::empty(),
                key.primary_key.public_key(),
            )
            .unwrap();
        config
            .unhashed_subpackets
            .push(Subpacket::regular(SubpacketData::EmbeddedSignature(Box::new(back))).unwrap());
    }
    let public = key.primary_key.public_key().clone();
    let sig = config
        .sign_subkey_binding(&key.primary_key, &public, &Password::empty(), sub.public_key())
        .unwrap();
    key.secret_subkeys[index].signatures = vec![sig];
    (key, index)
}
