//! Data sealed with a passphrase: an OpenPGP message encrypted to a passphrase alone (SKESK), for files the user
//! carries to another computer (a setup file). Written as SEIPDv2 (AES-256 with OCB) behind a version 6 SKESK whose
//! key comes from the passphrase through Argon2id (RFC 9580, the second parameter choice of RFC 9106: 64 MiB, three
//! passes, four lanes). Read back only as it was written: one passphrase packet, integrity protected data, an S2K
//! that is Argon2 or iterated and salted, and an Argon2 that asks for no more than `MAX_ARGON2_*` (a hostile file
//! could ask for gigabytes of memory and minutes of work before the passphrase is even checked).

use std::io::Cursor;

use pgp::bytes::Bytes;
use pgp::composed::{ArmorOptions, Edata, Esk, Message, MessageBuilder, TheRing};
use pgp::crypto::aead::{AeadAlgorithm, ChunkSize};
use pgp::crypto::sym::SymmetricKeyAlgorithm;
use pgp::errors::Error as PgpError;
use pgp::types::{Password, StringToKey};

use crate::DecryptError;
use crate::decrypt::{classify, read_through};

/// Argon2 as written: RFC 9106's second recommended choice, 2^16 KiB (64 MiB), three passes, four lanes
const ARGON2_PASSES: u8 = 3;
const ARGON2_LANES: u8 = 4;
const ARGON2_MEMORY: u8 = 16;

/// The most an Argon2 S2K read may ask for: 2^20 KiB (1 GiB), 10 passes, 16 lanes
const MAX_ARGON2_MEMORY: u8 = 20;
const MAX_ARGON2_PASSES: u8 = 10;
const MAX_ARGON2_LANES: u8 = 16;

/// Why sealed data could not be opened
#[derive(Debug, Clone, PartialEq, Eq)]
pub enum OpenError {
    /// The passphrase does not open it
    WrongPassphrase,
    /// It opened, but what is inside was changed (the AEAD tag or the modification detection code does not match)
    Integrity,
    /// Not data sealed with a passphrase, or sealed in a way this app does not read; why, in English
    Malformed(String),
    /// Larger than the limit once opened
    TooLarge,
}

impl std::fmt::Display for OpenError {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        match self {
            OpenError::WrongPassphrase => write!(f, "wrong passphrase"),
            OpenError::Integrity => write!(f, "the data was changed"),
            OpenError::Malformed(why) => write!(f, "not sealed data: {why}"),
            OpenError::TooLarge => write!(f, "too large"),
        }
    }
}

impl std::error::Error for OpenError {}

impl From<DecryptError> for OpenError {
    fn from(error: DecryptError) -> Self {
        match error {
            DecryptError::Integrity => OpenError::Integrity,
            DecryptError::TooLarge => OpenError::TooLarge,
            DecryptError::NoKey { .. } => OpenError::WrongPassphrase,
            DecryptError::Unprotected => OpenError::Malformed("not integrity protected".into()),
            DecryptError::Malformed(why) => OpenError::Malformed(why),
        }
    }
}

/// `data` sealed with `passphrase`, armored
pub fn seal(data: impl Into<Bytes>, passphrase: &str) -> Result<String, crate::Error> {
    let mut rng = rand::thread_rng();
    let s2k = StringToKey::new_argon2(&mut rng, ARGON2_PASSES, ARGON2_LANES, ARGON2_MEMORY);
    let mut builder = MessageBuilder::from_bytes("", data.into()).seipd_v2(
        &mut rng,
        SymmetricKeyAlgorithm::AES256,
        AeadAlgorithm::Ocb,
        ChunkSize::default(),
    );
    builder
        .encrypt_with_password(&mut rng, s2k, &Password::from(passphrase))
        .map_err(crate::malformed)?;
    builder
        .to_armored_string(&mut rng, ArmorOptions::default())
        .map_err(crate::malformed)
}

/// Whether the S2K of a passphrase packet is one this app reads, at a cost it accepts
fn s2k_accepted(s2k: Option<&StringToKey>) -> Result<(), OpenError> {
    match s2k {
        Some(StringToKey::Argon2 { t, p, m_enc, .. }) => {
            if *t > MAX_ARGON2_PASSES || *p > MAX_ARGON2_LANES || *m_enc > MAX_ARGON2_MEMORY {
                return Err(OpenError::Malformed("the passphrase asks for too much work".into()));
            }
            Ok(())
        }
        Some(StringToKey::IteratedAndSalted { .. }) => Ok(()),
        _ => Err(OpenError::Malformed("an S2K this app does not read".into())),
    }
}

/// Whether `bytes` start as OpenPGP data does: armored, or a binary packet header (the high bit set)
pub fn looks_sealed(bytes: &[u8]) -> bool {
    let start = bytes.trim_ascii_start();
    start.starts_with(b"-----BEGIN PGP MESSAGE-----") || start.first().is_some_and(|b| b & 0x80 != 0)
}

/// What `bytes` (armored or binary) sealed with `passphrase` hold, refused past `limit` bytes
pub fn open(bytes: &[u8], passphrase: &str, limit: usize) -> Result<Vec<u8>, OpenError> {
    let (message, _) = Message::from_reader(Cursor::new(bytes)).map_err(|error| OpenError::from(classify(error)))?;
    let Message::Encrypted { esk, edata, .. } = &message else {
        return Err(OpenError::Malformed("not encrypted".into()));
    };
    let [Esk::SymKeyEncryptedSessionKey(skesk)] = esk.as_slice() else {
        return Err(OpenError::Malformed("not sealed with a passphrase alone".into()));
    };
    s2k_accepted(skesk.s2k())?;
    if !matches!(edata, Edata::SymEncryptedProtectedData { .. }) {
        return Err(OpenError::Malformed("not integrity protected".into()));
    }
    let password = Password::from(passphrase);
    let ring = TheRing {
        message_password: vec![&password],
        ..Default::default()
    };
    let message = match message.decrypt_the_ring(ring, true) {
        Ok((message, _)) => message,
        Err(PgpError::MissingKey) => return Err(OpenError::WrongPassphrase),
        Err(error) => return Err(classify(error).into()),
    };
    if message.is_encrypted() {
        return Err(OpenError::Malformed("encrypted twice".into()));
    }
    let (_, data) = read_through(message, limit)?;
    Ok(data)
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn opens_what_it_sealed() {
        let sealed = seal(b"{\"a\":1}".to_vec(), "correct horse").unwrap();
        assert!(sealed.starts_with("-----BEGIN PGP MESSAGE-----"));
        assert!(looks_sealed(sealed.as_bytes()));
        assert!(!looks_sealed(b"  {\"format\":1}"));
        assert_eq!(open(sealed.as_bytes(), "correct horse", 100).unwrap(), b"{\"a\":1}");
        assert_eq!(
            open(sealed.as_bytes(), "wrong horse", 100),
            Err(OpenError::WrongPassphrase)
        );
        assert_eq!(open(sealed.as_bytes(), "correct horse", 3), Err(OpenError::TooLarge));
        // not twice the same
        assert_ne!(seal(b"x".to_vec(), "p").unwrap(), seal(b"x".to_vec(), "p").unwrap());
    }

    #[test]
    fn a_changed_byte_is_refused() {
        let sealed = seal(vec![b'x'; 2000], "passphrase").unwrap();
        // the binary form, a byte of the encrypted data changed near its end
        let binary = dearmor(&sealed);
        let mut changed = binary.clone();
        let at = changed.len() - 40;
        changed[at] ^= 1;
        assert_eq!(open(&changed, "passphrase", 10_000), Err(OpenError::Integrity));
        assert_eq!(open(&binary, "passphrase", 10_000).unwrap().len(), 2000);
        // cut short
        assert!(open(&binary[..binary.len() - 10], "passphrase", 10_000).is_err());
    }

    #[test]
    fn only_passphrase_messages_open() {
        let now = 1_798_761_600;
        let key = crate::generate("Alice", &["alice@example.org".into()], now).unwrap();
        let encrypted = crate::encrypt(b"hi".to_vec(), &[key.cert()], &[], None, now).unwrap();
        assert!(matches!(
            open(encrypted.as_bytes(), "x", 100),
            Err(OpenError::Malformed(_))
        ));
        assert!(matches!(open(b"{}", "x", 100), Err(OpenError::Malformed(_))));
        assert!(matches!(open(b"", "x", 100), Err(OpenError::Malformed(_))));
    }

    #[test]
    fn costly_argon2_is_refused_before_it_runs() {
        // a passphrase packet whose Argon2 asks for 2 GiB: refused without deriving
        let mut rng = rand::thread_rng();
        let s2k = StringToKey::new_argon2(&mut rng, 3, 4, 21);
        assert!(s2k_accepted(Some(&s2k)).is_err());
        let s2k = StringToKey::new_argon2(&mut rng, 11, 4, 16);
        assert!(s2k_accepted(Some(&s2k)).is_err());
        let s2k = StringToKey::new_argon2(&mut rng, 3, 4, 16);
        assert!(s2k_accepted(Some(&s2k)).is_ok());
        assert!(s2k_accepted(Some(&StringToKey::new_default(&mut rng))).is_ok());
        assert!(s2k_accepted(None).is_err());
    }

    fn dearmor(armored: &str) -> Vec<u8> {
        use base64::Engine;
        let body: String = armored
            .lines()
            .skip_while(|line| !line.is_empty())
            .skip(1)
            .take_while(|line| !line.starts_with('=') && !line.starts_with("-----"))
            .collect();
        base64::engine::general_purpose::STANDARD.decode(body).unwrap()
    }
}
