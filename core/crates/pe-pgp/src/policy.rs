//! What is acceptable, and since when. rPGP checks that a signature is mathematically right; whether its algorithms
//! may still be trusted is decided here. Times are the signature's own creation time, so mail signed in 2012 with
//! SHA-1 still verifies while a SHA-1 signature made today does not.
//!
//! | Rule                                                 | Why                                                  |
//! | ---------------------------------------------------- | ---------------------------------------------------- |
//! | MD5 is never accepted                                | collisions since 2004                                 |
//! | SHA-1 and RIPEMD-160 data signatures before 2013-02 | collisions became practical; Sequoia's cutoff        |
//! | SHA-1 and RIPEMD-160 key bindings before 2023-02    | a binding needs second pre-image resistance only     |
//! | RSA under 2048 bits is refused                       | factoring 1024 bit moduli is within reach            |
//! | DSA and ElGamal are refused                          | deprecated by RFC 9580, 1024 bit in practice         |
//! | Encryption is never to IDEA, 3DES, CAST5, Blowfish   | only AES is written; the old ones are read           |
//! | Unknown algorithms are refused                       | nothing is trusted that is not understood            |

use pgp::crypto::{hash::HashAlgorithm, public_key::PublicKeyAlgorithm};
use pgp::types::PublicParams;
use rsa::traits::PublicKeyParts;

/// 2013-02-01: the end of SHA-1 for signatures that need collision resistance (data signatures, certifications).
pub const SHA1_DATA_CUTOFF: i64 = 1_359_676_800;
/// 2023-02-01: the end of SHA-1 for key bindings (self-signatures), which need second pre-image resistance only.
pub const SHA1_BINDING_CUTOFF: i64 = 1_675_209_600;

/// What a signature is used for, which decides how strong its hash must be.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum Use {
    /// A signature over a document (a message, a MIME part).
    Data,
    /// A key's own signature over its user ids and subkeys, or a revocation.
    Binding,
}

/// May a signature of `use_` made at `created` with `hash` be trusted? If not, the hash's name.
pub fn hash(hash: HashAlgorithm, use_: Use, created: i64) -> Result<(), String> {
    let cutoff = match use_ {
        Use::Data => SHA1_DATA_CUTOFF,
        Use::Binding => SHA1_BINDING_CUTOFF,
    };
    match hash {
        HashAlgorithm::Sha256
        | HashAlgorithm::Sha384
        | HashAlgorithm::Sha512
        | HashAlgorithm::Sha224
        | HashAlgorithm::Sha3_256
        | HashAlgorithm::Sha3_512 => Ok(()),
        HashAlgorithm::Sha1 | HashAlgorithm::Ripemd160 if created < cutoff => Ok(()),
        other => Err(other.to_string()),
    }
}

/// May a key with these parameters sign or be encrypted to? If not, the algorithm in words.
pub fn key(algorithm: PublicKeyAlgorithm, params: &PublicParams) -> Result<(), String> {
    match params {
        PublicParams::RSA(rsa) => {
            let bits = rsa.key.n().bits();
            if bits < 2048 {
                Err(format!("RSA {bits}"))
            } else {
                Ok(())
            }
        }
        PublicParams::ECDSA(_)
        | PublicParams::ECDH(_)
        | PublicParams::EdDSALegacy(_)
        | PublicParams::Ed25519(_)
        | PublicParams::X25519(_)
        | PublicParams::X448(_)
        | PublicParams::Ed448(_) => Ok(()),
        _ => Err(format!("{algorithm:?}")),
    }
}

/// The `micalg` parameter of `multipart/signed` for a hash (RFC 3156 section 5).
pub fn micalg(hash: HashAlgorithm) -> String {
    format!("pgp-{}", hash.to_string().to_ascii_lowercase().replace("-", ""))
}

#[cfg(test)]
mod tests {
    use super::*;

    const Y2012: i64 = 1_325_376_000;
    const Y2020: i64 = 1_577_836_800;
    const Y2026: i64 = 1_767_225_600;

    #[test]
    fn md5_never() {
        assert!(hash(HashAlgorithm::Md5, Use::Data, Y2012 - 400_000_000).is_err());
        assert!(hash(HashAlgorithm::Md5, Use::Binding, Y2012 - 400_000_000).is_err());
    }

    #[test]
    fn sha1_data_until_2013() {
        assert!(hash(HashAlgorithm::Sha1, Use::Data, Y2012).is_ok());
        assert!(hash(HashAlgorithm::Sha1, Use::Data, SHA1_DATA_CUTOFF).is_err());
        assert!(hash(HashAlgorithm::Sha1, Use::Data, Y2020).is_err());
        assert!(hash(HashAlgorithm::Ripemd160, Use::Data, Y2020).is_err());
    }

    #[test]
    fn sha1_bindings_until_2023() {
        assert!(hash(HashAlgorithm::Sha1, Use::Binding, Y2020).is_ok());
        assert!(hash(HashAlgorithm::Sha1, Use::Binding, SHA1_BINDING_CUTOFF).is_err());
        assert!(hash(HashAlgorithm::Sha1, Use::Binding, Y2026).is_err());
    }

    #[test]
    fn modern_hashes_always() {
        for good in [HashAlgorithm::Sha256, HashAlgorithm::Sha512, HashAlgorithm::Sha3_256] {
            assert!(hash(good, Use::Data, Y2026).is_ok());
        }
        assert!(hash(HashAlgorithm::None, Use::Data, Y2026).is_err());
    }

    #[test]
    fn micalg_names() {
        assert_eq!(micalg(HashAlgorithm::Sha256), "pgp-sha256");
        assert_eq!(micalg(HashAlgorithm::Sha512), "pgp-sha512");
        assert_eq!(micalg(HashAlgorithm::Sha1), "pgp-sha1");
    }
}
