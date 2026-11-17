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
//! | An ECDH key must wrap with AES and hash with SHA-2   | its KDF parameters pick the cipher a sender wraps in |
//! | A signature with a critical notation is refused      | RFC 9580 5.2.3.24: an unknown critical one, and none |
//! |                                                      | is known here                                        |
//! | Unknown algorithms are refused                       | nothing is trusted that is not understood            |

use pgp::crypto::{hash::HashAlgorithm, public_key::PublicKeyAlgorithm, sym::SymmetricKeyAlgorithm};
use pgp::packet::{Signature, SubpacketData};
use pgp::types::{EcdhPublicParams, PublicParams};
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
        PublicParams::ECDH(ecdh) => ecdh_kdf(ecdh),
        PublicParams::ECDSA(_)
        | PublicParams::EdDSALegacy(_)
        | PublicParams::Ed25519(_)
        | PublicParams::X25519(_)
        | PublicParams::X448(_)
        | PublicParams::Ed448(_) => Ok(()),
        _ => Err(format!("{algorithm:?}")),
    }
}

/// An ECDH key's KDF parameters name the cipher that wraps the session key for it and the hash of the KDF; a sender
/// uses them as they are, so a key naming a 64 bit block cipher would have mail to it wrapped in one.
fn ecdh_kdf(params: &EcdhPublicParams) -> Result<(), String> {
    let (hash, cipher) = match params {
        EcdhPublicParams::Curve25519Legacy { hash, alg_sym, .. }
        | EcdhPublicParams::P256 { hash, alg_sym, .. }
        | EcdhPublicParams::P384 { hash, alg_sym, .. }
        | EcdhPublicParams::P521 { hash, alg_sym, .. }
        | EcdhPublicParams::Brainpool256 { hash, alg_sym, .. }
        | EcdhPublicParams::Brainpool384 { hash, alg_sym, .. }
        | EcdhPublicParams::Brainpool512 { hash, alg_sym, .. }
        | EcdhPublicParams::Unsupported { hash, alg_sym, .. } => (*hash, *alg_sym),
    };
    let aes = matches!(
        cipher,
        SymmetricKeyAlgorithm::AES128 | SymmetricKeyAlgorithm::AES192 | SymmetricKeyAlgorithm::AES256
    );
    let sha2 = matches!(
        hash,
        HashAlgorithm::Sha256 | HashAlgorithm::Sha384 | HashAlgorithm::Sha512
    );
    if aes && sha2 {
        Ok(())
    } else {
        Err(format!("ECDH with {cipher:?} and {hash}"))
    }
}

/// Does a signature carry a notation marked critical in its hashed area? No notation is understood here, and a
/// critical one that is not understood makes the signature invalid (RFC 9580 section 5.2.3.24).
pub fn critical_notation(sig: &Signature) -> bool {
    sig.config().is_some_and(|config| {
        config
            .hashed_subpackets()
            .any(|sub| sub.is_critical && matches!(sub.data, SubpacketData::Notation(_)))
    })
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
    fn ecdh_wraps_with_aes_and_hashes_with_sha2() {
        // the interoperability suite's "ECDH Parameters": a key naming IDEA, 3DES, CAST5 or Blowfish for its key wrap
        // had mail to it wrapped in that cipher
        use pgp::types::KeyDetails;
        let key = crate::generate("Alice", &["alice@example.org".into()], Y2026).unwrap();
        let sub = &key.cert().key.public_subkeys[0].key;
        let PublicParams::ECDH(EcdhPublicParams::Curve25519Legacy { p, ecdh_kdf_type, .. }) =
            sub.public_params().clone()
        else {
            panic!("a Curve25519 encryption subkey");
        };
        let with = |hash, alg_sym| {
            PublicParams::ECDH(EcdhPublicParams::Curve25519Legacy {
                p,
                hash,
                alg_sym,
                ecdh_kdf_type,
            })
        };
        assert!(key_ok(&with(HashAlgorithm::Sha256, SymmetricKeyAlgorithm::AES128)));
        assert!(key_ok(&with(HashAlgorithm::Sha512, SymmetricKeyAlgorithm::AES256)));
        for weak in [
            SymmetricKeyAlgorithm::IDEA,
            SymmetricKeyAlgorithm::TripleDES,
            SymmetricKeyAlgorithm::CAST5,
            SymmetricKeyAlgorithm::Blowfish,
        ] {
            assert!(!key_ok(&with(HashAlgorithm::Sha256, weak)), "{weak:?}");
        }
        assert!(!key_ok(&with(HashAlgorithm::Sha1, SymmetricKeyAlgorithm::AES128)));
    }

    fn key_ok(params: &PublicParams) -> bool {
        key(PublicKeyAlgorithm::ECDH, params).is_ok()
    }

    #[test]
    fn micalg_names() {
        assert_eq!(micalg(HashAlgorithm::Sha256), "pgp-sha256");
        assert_eq!(micalg(HashAlgorithm::Sha512), "pgp-sha512");
        assert_eq!(micalg(HashAlgorithm::Sha1), "pgp-sha1");
    }
}
