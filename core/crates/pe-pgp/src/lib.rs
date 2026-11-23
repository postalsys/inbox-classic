//! OpenPGP for Inbox Classic: pure functions over bytes on top of rPGP.
//!
//! Nothing here reads files, talks to the network or keeps state. Certificates are parsed, judged at a given time by
//! the policy of `policy.rs` (rPGP has none of its own), and used to verify, decrypt, sign and encrypt. What the
//! user sees about a signature is decided from what these functions return, so every decision about validity lives
//! here, in one place, with a test for each rule.
#![forbid(unsafe_code)]

pub mod autocrypt;
mod cert;
mod decrypt;
pub mod inline;
pub mod policy;
mod produce;
pub mod sealed;
mod verify;

pub use cert::{
    Cert, CertProblem, SecretKey, UserId, address_of, needs_passphrase, read_certs, read_public_certs, read_secret_keys,
};
pub use decrypt::{DecryptError, Decrypted, decrypt, decrypt_within, recipients};
pub use inline::armored_kind;
pub use produce::{Signed, encrypt, generate, sign_detached};
pub use verify::{Problem, SigCheck, SigStatus, verify_detached, verify_detached_for};

/// The most a certificate, a key file or an Autocrypt header may hold. Real certificates are a few kilobytes; ones
/// with thousands of third-party signatures (flooded on the old key servers) are refused rather than parsed.
pub const MAX_CERT_BYTES: usize = 1024 * 1024;

/// The most a decrypted message may hold: the largest message the app downloads.
pub const MAX_PLAINTEXT: usize = 64 * 1024 * 1024;

/// A signature or key made more than this many seconds after "now" is from the future (clocks differ a little).
pub const CLOCK_SKEW: i64 = 15 * 60;

/// A fingerprint in upper case hex, as people compare them.
pub fn hex(bytes: &[u8]) -> String {
    ::hex::encode_upper(bytes)
}

/// A fingerprint in groups of four, the way the windows show it for comparing.
pub fn grouped(fingerprint: &str) -> String {
    let chars: Vec<char> = fingerprint.chars().collect();
    chars
        .chunks(4)
        .map(|group| group.iter().collect::<String>())
        .collect::<Vec<_>>()
        .join(" ")
}

/// What went wrong reading OpenPGP data that is not a message (keys, signatures, headers).
#[derive(Debug, Clone, PartialEq, Eq)]
pub enum Error {
    /// Not OpenPGP data, or broken.
    Malformed(String),
    /// Larger than the limits above.
    TooLarge,
    /// A private key's passphrase was wrong.
    WrongPassphrase,
    /// A private key was needed and this is a public one (or the reverse).
    WrongKind,
    /// The key can not be used as asked (no usable signing or encryption key, refused by the policy).
    Unusable(CertProblem),
    /// A private key's secret parts do not belong to its public key: forged, or broken.
    Mismatch,
}

impl std::fmt::Display for Error {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        match self {
            Error::Malformed(why) => write!(f, "not readable OpenPGP data: {why}"),
            Error::TooLarge => write!(f, "too large"),
            Error::WrongPassphrase => write!(f, "wrong passphrase"),
            Error::WrongKind => write!(f, "not the kind of key expected"),
            Error::Unusable(problem) => write!(f, "the key can not be used: {problem:?}"),
            Error::Mismatch => write!(f, "the private key does not belong to its public key"),
        }
    }
}

impl std::error::Error for Error {}

/// `text` cut to 200 bytes at a character boundary: error messages and revocation reasons come from data a sender
/// controls.
pub(crate) fn short(mut text: String) -> String {
    if text.len() > 200 {
        let end = (0..=200).rev().find(|at| text.is_char_boundary(*at)).unwrap_or(0);
        text.truncate(end);
    }
    text
}

pub(crate) fn malformed(error: impl std::fmt::Display) -> Error {
    Error::Malformed(short(error.to_string()))
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn fingerprints_print_in_groups() {
        assert_eq!(hex(&[0x0a, 0xff, 0x10]), "0AFF10");
        assert_eq!(grouped("0AFF10B2C3"), "0AFF 10B2 C3");
    }

    #[test]
    fn short_cuts_at_characters() {
        assert_eq!(short("é".repeat(150)).len(), 200);
        assert_eq!(short(format!("x{}", "é".repeat(150))).len(), 199);
        assert_eq!(short("abc".into()), "abc");
    }
}
