//! Making keys, signatures and encrypted messages.

use pgp::bytes::Bytes;
use pgp::composed::SignedSecretKey;
use pgp::composed::{
    ArmorOptions, DetachedSignature, EncryptionCaps, KeyType, MessageBuilder, SecretKeyParamsBuilder,
    SubkeyParamsBuilder, SubpacketConfig,
};
use pgp::crypto::aead::{AeadAlgorithm, ChunkSize};
use pgp::crypto::ecc_curve::ECCCurve;
use pgp::crypto::hash::HashAlgorithm;
use pgp::crypto::sym::SymmetricKeyAlgorithm;
use pgp::packet::{Signature, SignatureConfig, Subpacket, SubpacketData};
use pgp::types::{KeyDetails, KeyVersion, Password, SigningKey, Tag, Timestamp};

use crate::cert::{Cert, CertProblem, Component, SecretKey};
use crate::{Error, malformed, policy};

/// The hash of every signature made here.
const HASH: HashAlgorithm = HashAlgorithm::Sha256;

/// A new key for `addresses`, each a user id `name <address>` (the first the primary one), made at `now`.
///
/// Ed25519 to sign and certify, with a Curve25519 subkey to encrypt, version 4: what Autocrypt asks for and every
/// OpenPGP program reads. No expiry. AES-256 and AES-128 preferred, no compression, SEIPDv2 announced (the app reads
/// it) so that senders who can will use AEAD.
pub fn generate(name: &str, addresses: &[String], now: i64) -> Result<SecretKey, Error> {
    let name: String = name
        .chars()
        .filter(|c| !c.is_control() && !matches!(c, '<' | '>'))
        .collect();
    let user_id = |address: &String| {
        let name = name.trim();
        if name.is_empty() {
            format!("<{address}>")
        } else {
            format!("{name} <{address}>")
        }
    };
    let mut ids = addresses.iter().map(user_id);
    let primary = ids.next().ok_or_else(|| Error::Malformed("no address".into()))?;
    let created = timestamp(now)?;
    let subkey = SubkeyParamsBuilder::default()
        .key_type(KeyType::ECDH(ECCCurve::Curve25519Legacy))
        .can_encrypt(EncryptionCaps::All)
        .created_at(created)
        .build()
        .map_err(malformed)?;
    let params = SecretKeyParamsBuilder::default()
        .key_type(KeyType::Ed25519Legacy)
        .can_certify(true)
        .can_sign(true)
        .created_at(created)
        .feature_seipd_v2(true)
        .primary_user_id(primary)
        .user_ids(ids.collect())
        .preferred_symmetric_algorithms([SymmetricKeyAlgorithm::AES256, SymmetricKeyAlgorithm::AES128][..].into())
        .preferred_hash_algorithms([HashAlgorithm::Sha512, HashAlgorithm::Sha256][..].into())
        .preferred_compression_algorithms(Default::default())
        .preferred_aead_algorithms(
            [
                (SymmetricKeyAlgorithm::AES256, AeadAlgorithm::Ocb),
                (SymmetricKeyAlgorithm::AES128, AeadAlgorithm::Ocb),
            ][..]
                .into(),
        )
        .subkeys(vec![subkey])
        .build()
        .map_err(malformed)?;
    let mut key = params.generate(rand::thread_rng()).map_err(malformed)?;
    restamp_self_signatures(&mut key, created)?;
    SecretKey::new(key)
}

/// rPGP signs a new key's user ids and subkey binding at the time of the clock; they are signed again at `at`, the
/// time the key says it was made, so that the key is valid at the time the caller asked for and not only after it.
fn restamp_self_signatures(key: &mut SignedSecretKey, at: Timestamp) -> Result<(), Error> {
    let restamped = |sig: &Signature| -> Result<SignatureConfig, Error> {
        let mut config = sig
            .config()
            .ok_or_else(|| Error::Malformed("unknown signature".into()))?
            .clone();
        for sub in &mut config.hashed_subpackets {
            if let SubpacketData::SignatureCreationTime(time) = &mut sub.data {
                *time = at;
            }
        }
        Ok(config)
    };
    let public = key.primary_key.public_key().clone();
    let password = Password::empty();
    for user in &mut key.details.users {
        let mut signatures = Vec::new();
        for sig in &user.signatures {
            let config = restamped(sig)?;
            signatures.push(
                config
                    .sign_certification(&key.primary_key, &public, &password, Tag::UserId, &user.id)
                    .map_err(malformed)?,
            );
        }
        user.signatures = signatures;
    }
    for sub in &mut key.secret_subkeys {
        let mut signatures = Vec::new();
        for sig in &sub.signatures {
            let config = restamped(sig)?;
            signatures.push(
                config
                    .sign_subkey_binding(&key.primary_key, &public, &password, sub.key.public_key())
                    .map_err(malformed)?,
            );
        }
        sub.signatures = signatures;
    }
    Ok(())
}

fn timestamp(now: i64) -> Result<Timestamp, Error> {
    Ok(Timestamp::from_secs(u32::try_from(now).map_err(malformed)?))
}

/// The secret part of the first key of `key` that may sign at `now` (the primary key when it may). Boxed, as rPGP implements its signing trait for
/// `Box<&dyn SigningKey>` and not for the bare reference.
#[allow(clippy::redundant_allocation)]
fn signer(key: &SecretKey, now: i64) -> Result<Box<&dyn SigningKey>, Error> {
    let usable = key.cert().signing_keys(now);
    for component in &usable {
        let fingerprint = component.fingerprint();
        if let Component::Primary(_) = component {
            return Ok(Box::new(&key.key.primary_key));
        }
        if let Some(sub) = key
            .key
            .secret_subkeys
            .iter()
            .rev()
            .find(|sub| sub.key.fingerprint() == fingerprint)
        {
            return Ok(Box::new(&sub.key));
        }
    }
    Err(Error::Unusable(
        key.cert().can_sign(now).err().unwrap_or(CertProblem::NoSigningKey),
    ))
}

/// The subpackets of a signature made at `now` by `signer`, naming `recipients` (the fingerprints of the primary keys
/// of an encrypted message's visible recipients, so that the signed content can not be passed on to someone else as
/// if it had been written to them, RFC 9580 section 5.2.3.36).
pub(crate) fn subpackets(signer: &dyn SigningKey, now: i64, recipients: &[&Cert]) -> Result<SubpacketConfig, Error> {
    let created = timestamp(now)?;
    let mut hashed = vec![
        Subpacket::regular(SubpacketData::SignatureCreationTime(created)).map_err(malformed)?,
        Subpacket::regular(SubpacketData::IssuerFingerprint(signer.fingerprint())).map_err(malformed)?,
    ];
    for cert in recipients {
        hashed.push(
            Subpacket::regular(SubpacketData::IntendedRecipientFingerprint(
                cert.key.primary_key.fingerprint(),
            ))
            .map_err(malformed)?,
        );
    }
    let mut unhashed = Vec::new();
    if signer.version() <= KeyVersion::V4 {
        unhashed.push(Subpacket::regular(SubpacketData::IssuerKeyId(signer.legacy_key_id())).map_err(malformed)?);
    }
    Ok(SubpacketConfig::UserDefined { hashed, unhashed })
}

/// A detached signature and the `micalg` that names its hash.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct Signed {
    pub signature: String,
    pub micalg: String,
}

/// A detached, armored signature over `data` (for `multipart/signed`, the exact bytes of the signed part).
pub fn sign_detached(data: &[u8], key: &SecretKey, now: i64) -> Result<Signed, Error> {
    let signing = signer(key, now)?;
    let config = subpackets(*signing, now, &[])?;
    let sig = DetachedSignature::sign_binary_data_with_subpackets(
        rand::thread_rng(),
        &signing,
        &Password::empty(),
        HASH,
        data,
        config,
    )
    .map_err(malformed)?;
    let signature = sig.to_armored_string(ArmorOptions::default()).map_err(malformed)?;
    Ok(Signed {
        signature,
        micalg: policy::micalg(HASH),
    })
}

/// The cipher every recipient reads: AES-256 when all name it, else AES-128, which every implementation must read.
fn cipher(certs: &[&Cert], now: i64) -> SymmetricKeyAlgorithm {
    let all_aes256 = certs
        .iter()
        .all(|cert| cert.prefers(SymmetricKeyAlgorithm::AES256, now));
    if all_aes256 {
        SymmetricKeyAlgorithm::AES256
    } else {
        SymmetricKeyAlgorithm::AES128
    }
}

/// `data` encrypted to every usable encryption key of `recipients` and, without naming them, of `hidden` (Bcc), and
/// signed inside the encryption by `signer_key`. Armored. SEIPDv2 when every recipient reads it, else SEIPDv1.
pub fn encrypt(
    data: impl Into<Bytes>,
    recipients: &[&Cert],
    hidden: &[&Cert],
    signer_key: Option<&SecretKey>,
    now: i64,
) -> Result<String, Error> {
    let everyone: Vec<&Cert> = recipients.iter().chain(hidden).copied().collect();
    if everyone.is_empty() {
        return Err(Error::Unusable(CertProblem::NoEncryptionKey));
    }
    for cert in &everyone {
        cert.can_encrypt(now).map_err(Error::Unusable)?;
    }
    let signing = signer_key.map(|key| signer(key, now)).transpose()?;
    // the signature names the recipients it was written to, unless some are hidden: naming them would show them to
    // everyone, and a signature naming only the others would not verify for them
    let named: &[&Cert] = if hidden.is_empty() { recipients } else { &[] };
    let subpackets = signing
        .as_ref()
        .map(|signing| subpackets(**signing, now, named))
        .transpose()?;
    let cipher = cipher(&everyone, now);
    let mut rng = rand::thread_rng();
    let keys = recipients
        .iter()
        .map(|cert| (*cert, false))
        .chain(hidden.iter().map(|cert| (*cert, true)))
        .flat_map(|(cert, hide)| cert.encryption_keys(now).into_iter().map(move |key| (key, hide)));
    let builder = MessageBuilder::from_bytes("", data.into());

    // the two builders have the same methods on different types, so the body is written once for both
    macro_rules! finish {
        ($builder:expr) => {{
            let mut builder = $builder;
            for (key, hide) in keys {
                match (key, hide) {
                    (Component::Primary(k), false) => builder.encrypt_to_key(&mut rng, k),
                    (Component::Subkey(k), false) => builder.encrypt_to_key(&mut rng, k),
                    (Component::Primary(k), true) => builder.encrypt_to_key_anonymous(&mut rng, k),
                    (Component::Subkey(k), true) => builder.encrypt_to_key_anonymous(&mut rng, k),
                }
                .map_err(malformed)?;
            }
            if let (Some(signing), Some(subpackets)) = (&signing, subpackets) {
                builder.sign_with_subpackets(**signing, Password::empty(), HASH, subpackets);
            }
            builder
                .to_armored_string(&mut rng, ArmorOptions::default())
                .map_err(malformed)
        }};
    }
    if everyone.iter().all(|cert| cert.reads_seipd_v2(now)) {
        finish!(builder.seipd_v2(&mut rng, cipher, AeadAlgorithm::Ocb, ChunkSize::default()))
    } else {
        finish!(builder.seipd_v1(&mut rng, cipher))
    }
}
