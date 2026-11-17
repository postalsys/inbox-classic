//! Opening OpenPGP messages: decrypting with the user's keys, checking the signatures inside.
//!
//! Integrity is not optional. The old encrypted packet without a modification detection code is refused outright,
//! and a SEIPDv1 message is read to its end and its code checked before a byte of it is returned (rPGP's default
//! since 0.20), so changed ciphertext can never put attacker-shaped text in front of the user (EFAIL).

use std::io::{Cursor, Read};

use pgp::composed::{DecryptionOptions, Edata, Esk, Message, SignedSecretKey, TheRing};
use pgp::crypto::aead;
use pgp::errors::Error as PgpError;
use pgp::packet::{ProtectedDataConfig, SymEncryptedProtectedDataConfig};
use pgp::types::{KeyDetails, Password};

use crate::cert::{Cert, Component, SecretKey};
use crate::verify::{SigCheck, judge};
use crate::{MAX_PLAINTEXT, hex, short};

/// A message opened.
#[derive(Debug, Clone, Default, PartialEq, Eq)]
pub struct Decrypted {
    /// What was inside: for PGP/MIME, a MIME entity.
    pub data: Vec<u8>,
    /// Whether it was encrypted (a message that is only signed opens too).
    pub encrypted: bool,
    /// The signatures inside, each checked.
    pub signatures: Vec<SigCheck>,
    /// Who it was encrypted to: key ids or fingerprints, upper case hex; `0000000000000000` for a hidden recipient.
    pub recipients: Vec<String>,
    /// The fingerprint of the user's key that opened it.
    pub key: Option<String>,
    /// SEIPDv2 (AEAD) rather than SEIPDv1.
    pub aead: bool,
}

/// Why a message could not be opened.
#[derive(Debug, Clone, PartialEq, Eq)]
pub enum DecryptError {
    /// None of the user's keys is among the recipients; who they are, as in `Decrypted::recipients`.
    NoKey { recipients: Vec<String> },
    /// The ciphertext was changed: the modification detection code or the AEAD tag does not match.
    Integrity,
    /// Encrypted without integrity protection (the old packet type 9, or GnuPG's own AEAD packet). Never opened.
    Unprotected,
    /// Not an OpenPGP message, or broken.
    Malformed(String),
    /// Larger than `MAX_PLAINTEXT` once decrypted or decompressed.
    TooLarge,
}

impl std::fmt::Display for DecryptError {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        write!(f, "{self:?}")
    }
}

impl std::error::Error for DecryptError {}

/// Is this error, or one it wraps, a failed integrity check? rPGP reports one as its own `MdcError`, as an AEAD
/// `Decrypt` error, or either of those inside an I/O error, depending on where in the reading it was found.
fn integrity_failed(error: &(dyn std::error::Error + 'static)) -> bool {
    if let Some(pgp) = error.downcast_ref::<PgpError>() {
        return match pgp {
            PgpError::MdcError
            | PgpError::Aead {
                source: aead::Error::Decrypt { .. },
            } => true,
            PgpError::IO { source, .. } => source.get_ref().is_some_and(|inner| integrity_failed(inner)),
            _ => false,
        };
    }
    if let Some(aead) = error.downcast_ref::<aead::Error>() {
        return matches!(aead, aead::Error::Decrypt { .. });
    }
    if let Some(io) = error.downcast_ref::<std::io::Error>() {
        return io.get_ref().is_some_and(|inner| integrity_failed(inner));
    }
    false
}

pub(crate) fn classify(error: PgpError) -> DecryptError {
    if integrity_failed(&error) {
        return DecryptError::Integrity;
    }
    DecryptError::Malformed(short(error.to_string()))
}

pub(crate) fn read_error(error: std::io::Error) -> DecryptError {
    if integrity_failed(&error) {
        return DecryptError::Integrity;
    }
    DecryptError::Malformed(short(error.to_string()))
}

fn parse(message: &[u8]) -> Result<Message<'_>, DecryptError> {
    let (message, _) = Message::from_reader(Cursor::new(message)).map_err(classify)?;
    Ok(message)
}

fn recipients_of(esk: &[Esk]) -> Vec<String> {
    esk.iter()
        .filter_map(|esk| match esk {
            Esk::PublicKeyEncryptedSessionKey(pkesk) => match pkesk.id() {
                Ok(id) => Some(hex(id.as_ref())),
                Err(_) => Some(match pkesk.fingerprint() {
                    Ok(Some(fingerprint)) => hex(fingerprint.as_bytes()),
                    _ => "0000000000000000".to_string(),
                }),
            },
            Esk::SymKeyEncryptedSessionKey(_) => None,
        })
        .collect()
}

/// Who a message is encrypted to, without opening it: for "encrypted to a key you do not have".
pub fn recipients(message: &[u8]) -> Result<Vec<String>, DecryptError> {
    match parse(message)? {
        Message::Encrypted { esk, .. } => Ok(recipients_of(&esk)),
        _ => Ok(Vec::new()),
    }
}

/// Opens `message` (armored or binary) with `keys` and checks its signatures against `certs` at `now`.
pub fn decrypt(message: &[u8], keys: &[SecretKey], certs: &[Cert], now: i64) -> Result<Decrypted, DecryptError> {
    decrypt_within(message, keys, certs, now, MAX_PLAINTEXT)
}

/// `decrypt`, refusing what holds more than `limit` bytes once decrypted and decompressed.
pub fn decrypt_within(
    bytes: &[u8],
    keys: &[SecretKey],
    certs: &[Cert],
    now: i64,
    limit: usize,
) -> Result<Decrypted, DecryptError> {
    let mut opened = Decrypted::default();
    let mut message = parse(bytes)?;
    if let Message::Encrypted { esk, edata, .. } = &message {
        opened.encrypted = true;
        opened.recipients = recipients_of(esk);
        opened.aead = match edata {
            Edata::SymEncryptedData { .. } | Edata::GnupgAeadData { .. } => return Err(DecryptError::Unprotected),
            Edata::SymEncryptedProtectedData { reader } => {
                matches!(
                    reader.config(),
                    ProtectedDataConfig::Seipd(SymEncryptedProtectedDataConfig::V2 { .. })
                )
            }
        };
        let (decrypted, key) = open_with(bytes, keys).map_err(|error| match error {
            DecryptError::NoKey { .. } => DecryptError::NoKey {
                recipients: opened.recipients.clone(),
            },
            other => other,
        })?;
        opened.key = Some(key.fingerprint());
        message = decrypted;
        if message.is_encrypted() {
            return Err(DecryptError::Malformed("encrypted twice".into()));
        }
    }
    let mut layers = 0;
    while compressed(&message, 0) {
        if layers == MAX_COMPRESSION {
            return Err(DecryptError::Malformed("compressed too many times".into()));
        }
        message = message.decompress().map_err(classify)?;
        layers += 1;
    }
    (&mut message)
        .take(limit as u64 + 1)
        .read_to_end(&mut opened.data)
        .map_err(read_error)?;
    if opened.data.len() > limit {
        return Err(DecryptError::TooLarge);
    }
    opened.signatures = signatures(&message, certs, now, opened.key.as_deref());
    Ok(opened)
}

/// Compression layers read through. GnuPG and Sequoia write one; a message compressed again and again is no mail
/// anyone sends, and each layer left unread would be handed on as if it were the text.
const MAX_COMPRESSION: usize = 4;

/// Is the message, or the message a signature is over, still compressed? (Signatures nest; 16 levels are looked
/// into, deeper counts as compressed and so is refused.)
fn compressed(message: &Message<'_>, depth: usize) -> bool {
    match message {
        Message::Compressed { .. } => true,
        Message::Signed { reader, .. } => depth >= 16 || compressed(reader.get_ref(), depth + 1),
        _ => false,
    }
}

/// `key` with only the subkeys that may decrypt (`Cert::decrypts_with`), and whether its primary key may.
fn decryption_key(key: &SecretKey) -> (SignedSecretKey, bool) {
    let mut only = key.key.clone();
    only.secret_subkeys
        .retain(|sub| key.cert().decrypts_with(&sub.key.fingerprint()));
    let primary = key.cert().decrypts_with(&key.key.primary_key.fingerprint());
    (only, primary)
}

/// Does a session key of the message name this key (by key id or fingerprint), rather than no one (hidden)?
fn names(esk: &[Esk], key: &impl KeyDetails) -> bool {
    esk.iter().any(|esk| match esk {
        Esk::PublicKeyEncryptedSessionKey(pkesk) => match pkesk.id() {
            Ok(id) => !id.is_wildcard() && *id == key.legacy_key_id(),
            Err(_) => matches!(pkesk.fingerprint(), Ok(Some(fingerprint)) if *fingerprint == key.fingerprint()),
        },
        Esk::SymKeyEncryptedSessionKey(_) => false,
    })
}

/// A session key for a hidden recipient (no key id, or the wildcard).
fn hidden(esk: &Esk) -> bool {
    match esk {
        Esk::PublicKeyEncryptedSessionKey(pkesk) => match pkesk.id() {
            Ok(id) => id.is_wildcard(),
            Err(_) => !matches!(pkesk.fingerprint(), Ok(Some(_))),
        },
        Esk::SymKeyEncryptedSessionKey(_) => false,
    }
}

/// The message decrypted with the first of `keys` that opens it, and that key. Each key is tried on a fresh parse
/// of its own, as rPGP's result of trying several at once does not say reliably which one worked; a key that is not
/// a recipient fails before any of the data is decrypted, so the tries cost little.
fn open_with<'a>(bytes: &'a [u8], keys: &'a [SecretKey]) -> Result<(Message<'a>, &'a SecretKey), DecryptError> {
    let empty = Password::empty();
    let esk = match parse(bytes)? {
        Message::Encrypted { esk, .. } => esk,
        _ => Vec::new(),
    };
    for key in keys {
        let (only, primary) = decryption_key(key);
        // rPGP tries the primary key for a session key that names it; one that may not decrypt is not tried. (A
        // hidden recipient is tried with every key, as there is no telling which it is.)
        let named_primary = names(&esk, &only.primary_key);
        let named_subkey = only.secret_subkeys.iter().any(|sub| names(&esk, &sub.key));
        if !primary && named_primary && !named_subkey && !esk.iter().any(hidden) {
            continue;
        }
        let ring = TheRing {
            secret_keys: vec![&only],
            key_passwords: vec![&empty],
            decrypt_options: DecryptionOptions::new(),
            ..Default::default()
        };
        match parse(bytes)?.decrypt_the_ring(ring, true) {
            Ok((message, _)) => return Ok((message, key)),
            Err(PgpError::MissingKey) => continue,
            Err(error) => return Err(classify(error)),
        }
    }
    Err(DecryptError::NoKey { recipients: Vec::new() })
}

/// The signatures of a signed message read to its end, each checked (at most 8); `recipient`, the key that
/// decrypted it.
fn signatures(message: &Message<'_>, certs: &[Cert], now: i64, recipient: Option<&str>) -> Vec<SigCheck> {
    let Message::Signed { reader, .. } = message else {
        return Vec::new();
    };
    (0..reader.num_signatures().min(8))
        .filter_map(|index| {
            let sig = reader.signature(index)?;
            Some(judge(sig, certs, now, recipient, |component| match component {
                Component::Primary(key) => message.verify_nested_explicit(index, *key).is_ok(),
                Component::Subkey(key) => message.verify_nested_explicit(index, *key).is_ok(),
            }))
        })
        .collect()
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn content_signed_for_someone_else_is_not_for_you() {
        // Alice writes to Bob, signed and encrypted; Bob encrypts the same signed content again to Carol
        use pgp::composed::{ArmorOptions, MessageBuilder};
        let now = 1_798_761_600;
        let alice = crate::generate("Alice", &["alice@example.org".into()], now).unwrap();
        let bob = crate::generate("Bob", &["bob@example.org".into()], now).unwrap();
        let carol = crate::generate("Carol", &["carol@example.org".into()], now).unwrap();
        let mut rng = rand::thread_rng();
        let mut builder = MessageBuilder::from_bytes("", b"I approve.".to_vec())
            .seipd_v1(&mut rng, pgp::crypto::sym::SymmetricKeyAlgorithm::AES256);
        let carol_cert = carol.cert();
        for key in carol_cert.encryption_keys(now) {
            if let Component::Subkey(sub) = key {
                builder.encrypt_to_key(&mut rng, sub).unwrap();
            }
        }
        let subpackets = crate::produce::subpackets(&alice.key.primary_key, now, &[bob.cert()]).unwrap();
        builder.sign_with_subpackets(
            &alice.key.primary_key,
            Password::empty(),
            pgp::crypto::hash::HashAlgorithm::Sha256,
            subpackets,
        );
        let forwarded = builder.to_armored_string(&mut rng, ArmorOptions::default()).unwrap();
        let opened = decrypt(forwarded.as_bytes(), &[carol], &[alice.cert().clone()], now).unwrap();
        assert_eq!(opened.signatures[0].intended, [bob.fingerprint()]);
        assert_eq!(
            opened.signatures[0].status,
            crate::SigStatus::Bad(crate::Problem::NotForYou)
        );
        // written to Bob, it is good for Bob
        let direct = crate::encrypt(&b"I approve."[..], &[bob.cert()], &[], Some(&alice), now).unwrap();
        let opened = decrypt(
            direct.as_bytes(),
            std::slice::from_ref(&bob),
            &[alice.cert().clone()],
            now,
        )
        .unwrap();
        assert_eq!(opened.signatures[0].status, crate::SigStatus::Good);
        assert_eq!(opened.signatures[0].intended, [bob.fingerprint()]);
    }

    /// A literal data packet of `text` compressed `depth` times (with the "uncompressed" algorithm, so the packets
    /// can be written by hand), in new format packets.
    fn compressed_times(text: &[u8], depth: usize) -> Vec<u8> {
        let packet = |tag: u8, body: Vec<u8>| {
            let len = body.len();
            let mut out = match len {
                0..192 => vec![0xC0 | tag, len as u8],
                _ => vec![0xC0 | tag, ((len - 192) >> 8) as u8 + 192, (len - 192) as u8],
            };
            out.extend(body);
            out
        };
        let mut literal = vec![b'b', 0, 0, 0, 0, 0];
        literal.extend_from_slice(text);
        let mut message = packet(11, literal);
        for _ in 0..depth {
            let mut body = vec![0];
            body.extend(message);
            message = packet(8, body);
        }
        message
    }

    #[test]
    fn compression_is_read_through_a_few_times_only() {
        // the interoperability suite's "Maximum recursion depth": past the first layer the compressed bytes came out
        // as if they were the text, and nothing limited the depth
        for depth in 0..=MAX_COMPRESSION {
            let opened = decrypt(&compressed_times(b"Hello", depth), &[], &[], 0).unwrap();
            assert_eq!(opened.data, b"Hello", "{depth}");
        }
        for depth in [MAX_COMPRESSION + 1, 32, 64] {
            assert!(matches!(
                decrypt(&compressed_times(b"Hello", depth), &[], &[], 0),
                Err(DecryptError::Malformed(_))
            ));
        }
    }

    #[test]
    fn garbage_is_malformed() {
        assert!(matches!(
            decrypt(b"hello there", &[], &[], 0),
            Err(DecryptError::Malformed(_))
        ));
        assert!(matches!(recipients(b"\x00\x01"), Err(DecryptError::Malformed(_))));
    }
}
