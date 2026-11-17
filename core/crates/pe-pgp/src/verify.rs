//! Checking signatures over exact bytes (the signed part of a `multipart/signed`, the data of a signed and encrypted
//! message). Every signature is judged on its own: it verifies, its key is known and was valid when it signed, and
//! the policy accepts its algorithms at that time.

use std::io::Cursor;

use pgp::composed::{Deserializable, DetachedSignature};
use pgp::packet::{Signature, SignatureType, SubpacketData};

use crate::cert::{Cert, CertProblem, Component};
use crate::policy::{self, Use};
use crate::{CLOCK_SKEW, Error, hex, malformed};

/// Why a signature does not count.
#[derive(Debug, Clone, PartialEq, Eq)]
pub enum Problem {
    /// The signature does not match the bytes: they were changed, or it is not over them.
    Mismatch,
    /// The policy refuses its hash at the time it was made, by name.
    WeakHash(String),
    /// The key had expired when it signed.
    KeyExpired { at: i64 },
    /// The key was revoked (for all time, or before it signed).
    KeyRevoked { reason: Option<String> },
    /// The key that signed may not sign (an encryption-only subkey, a signing subkey without its back signature).
    NotSigningKey,
    /// Made in the future, or by a key made after the signature.
    FromFuture,
    /// The signature's own expiry has passed.
    SignatureExpired,
    /// Not a signature over a document (a key signature, a timestamp), unreadable, or with a critical notation,
    /// which nothing here understands.
    WrongType,
    /// The certificate has no valid self-signature at the time it signed, so it says nothing about who it is.
    KeyNotValid,
    /// Signed for other recipients and encrypted again to this one: content passed on as if it had been written
    /// to them (RFC 9580 section 5.2.3.36).
    NotForYou,
}

/// What became of one signature.
#[derive(Debug, Clone, PartialEq, Eq)]
pub enum SigStatus {
    /// It verifies by every rule.
    Good,
    /// No certificate given has the key that made it.
    UnknownKey,
    /// The key is known and the signature does not count, for this reason.
    Bad(Problem),
}

/// One signature, checked.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct SigCheck {
    /// The fingerprints and key ids the signature names as its issuer, upper case hex.
    pub issuers: Vec<String>,
    /// The fingerprint of the certificate whose key made it, when known.
    pub cert: Option<String>,
    /// When it says it was made.
    pub created: Option<i64>,
    /// The fingerprints of the recipients the signer says they wrote to (Intended Recipient Fingerprint), upper
    /// case hex; empty when the signature does not say.
    pub intended: Vec<String>,
    pub status: SigStatus,
}

impl SigCheck {
    pub fn is_good(&self) -> bool {
        self.status == SigStatus::Good
    }
}

fn issuers(sig: &Signature) -> Vec<String> {
    let mut out: Vec<String> = sig.issuer_fingerprint().iter().map(|f| hex(f.as_bytes())).collect();
    out.extend(sig.issuer_key_id().iter().map(|id| hex(id.as_ref())));
    out
}

/// The certificate and key that made a signature: among the keys its issuer names (by fingerprint or key id, in
/// every certificate that has one, as two certificates can share a 64 bit key id), the one it verifies with. The
/// first certificate named when none verifies; nothing when none is named.
fn maker<'a>(
    issuers: &[String],
    certs: &'a [Cert],
    verify: impl Fn(&Component<'_>) -> bool,
) -> Option<(&'a Cert, Option<Component<'a>>)> {
    let named = |handles: &[String]| issuers.iter().any(|issuer| handles.contains(issuer));
    let mut first = None;
    for cert in certs.iter().filter(|cert| named(cert.handles())) {
        first.get_or_insert(cert);
        let found = cert
            .components()
            .find(|component| named(&component.handles()) && verify(component));
        if found.is_some() {
            return Some((cert, found));
        }
    }
    first.map(|cert| (cert, None))
}

/// Why a signature made at `created` by `component` of `cert` does not count by the policy and the key's validity.
fn invalid(sig: &Signature, cert: &Cert, component: &Component<'_>, created: i64) -> Option<Problem> {
    if let Some(Err(name)) = sig.hash_alg().map(|hash| policy::hash(hash, Use::Data, created)) {
        return Some(Problem::WeakHash(name));
    }
    match cert.status(created) {
        Err(CertProblem::Expired { at }) => return Some(Problem::KeyExpired { at }),
        Err(CertProblem::Revoked { reason }) => return Some(Problem::KeyRevoked { reason }),
        Err(CertProblem::NotYetValid) => return Some(Problem::FromFuture),
        Err(_) => return Some(Problem::KeyNotValid),
        Ok(()) => {}
    }
    let fingerprint = component.fingerprint();
    let may_sign = cert
        .signing_keys(created)
        .iter()
        .any(|key| key.fingerprint() == fingerprint);
    (!may_sign).then_some(Problem::NotSigningKey)
}

/// The Intended Recipient Fingerprints of the hashed area, upper case hex.
fn intended(sig: &Signature) -> Vec<String> {
    let Some(config) = sig.config() else { return Vec::new() };
    config
        .hashed_subpackets
        .iter()
        .filter_map(|sub| match &sub.data {
            SubpacketData::IntendedRecipientFingerprint(fingerprint) => Some(hex(fingerprint.as_bytes())),
            _ => None,
        })
        .collect()
}

/// Checks one data signature, `verify` doing the mathematics against a component. `recipient` is the fingerprint
/// of the primary key that decrypted the message the signature was in: a signature that names its intended
/// recipients must name it.
pub(crate) fn judge(
    sig: &Signature,
    certs: &[Cert],
    now: i64,
    recipient: Option<&str>,
    verify: impl Fn(&Component<'_>) -> bool,
) -> SigCheck {
    let issuers = issuers(sig);
    let intended = intended(sig);
    let created = sig.created().map(|t| i64::from(t.as_secs()));
    let check = |cert: Option<&Cert>, status| SigCheck {
        issuers: issuers.clone(),
        intended: intended.clone(),
        cert: cert.map(Cert::fingerprint),
        created,
        status,
    };
    let Some((cert, component)) = maker(&issuers, certs, verify) else {
        return check(None, SigStatus::UnknownKey);
    };
    let bad = |problem| check(Some(cert), SigStatus::Bad(problem));
    let document = matches!(sig.typ(), Some(SignatureType::Binary | SignatureType::Text));
    let Some(created) = created.filter(|_| document && !policy::critical_notation(sig)) else {
        return bad(Problem::WrongType);
    };
    if created > now + CLOCK_SKEW {
        return bad(Problem::FromFuture);
    }
    let expiry = sig
        .signature_expiration_time()
        .map(|d| i64::from(d.as_secs()))
        .filter(|secs| *secs > 0);
    if expiry.is_some_and(|secs| created + secs <= now) {
        return bad(Problem::SignatureExpired);
    }
    if let Some(recipient) = recipient
        && !intended.is_empty()
        && !intended.iter().any(|fingerprint| fingerprint == recipient)
    {
        return bad(Problem::NotForYou);
    }
    let Some(component) = component else {
        return bad(Problem::Mismatch);
    };
    match invalid(sig, cert, &component, created) {
        Some(problem) => bad(problem),
        None => check(Some(cert), SigStatus::Good),
    }
}

/// Checks the detached signatures in `signature` (armored or binary, one or several) over `data`.
pub fn verify_detached(signature: &[u8], data: &[u8], certs: &[Cert], now: i64) -> Result<Vec<SigCheck>, Error> {
    verify_detached_for(signature, data, certs, now, None)
}

/// `verify_detached` of a signature found inside an encryption that `recipient` (the fingerprint of the user's
/// primary key that opened it) decrypted: a signature naming other recipients is not for the user.
pub fn verify_detached_for(
    signature: &[u8],
    data: &[u8],
    certs: &[Cert],
    now: i64,
    recipient: Option<&str>,
) -> Result<Vec<SigCheck>, Error> {
    if signature.len() > crate::MAX_CERT_BYTES {
        return Err(Error::TooLarge);
    }
    let (parsed, _) = DetachedSignature::from_reader_many(Cursor::new(signature)).map_err(malformed)?;
    let mut out = Vec::new();
    for sig in parsed {
        let sig = sig.map_err(malformed)?;
        out.push(judge(
            &sig.signature,
            certs,
            now,
            recipient,
            |component| match component {
                Component::Primary(key) => sig.signature.verify(*key, Cursor::new(data)).is_ok(),
                Component::Subkey(key) => sig.signature.verify(*key, Cursor::new(data)).is_ok(),
            },
        ));
        if out.len() >= 8 {
            break;
        }
    }
    if out.is_empty() {
        return Err(Error::Malformed("no signature".into()));
    }
    Ok(out)
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn garbage_is_no_signature() {
        assert!(verify_detached(b"hello", b"data", &[], 0).is_err());
        assert!(
            verify_detached(
                b"-----BEGIN PGP SIGNATURE-----\n\n-----END PGP SIGNATURE-----\n",
                b"x",
                &[],
                0
            )
            .is_err()
        );
    }
}
