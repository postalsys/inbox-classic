//! Certificates (public keys with their user ids, subkeys and self-signatures) and private keys.
//!
//! A certificate is cleaned when it is read: every signature is checked once, and what does not verify as the key's
//! own signature (third-party certifications, broken or forged packets, signatures the policy refuses) is dropped.
//! What remains is judged at a given time by `status`, `user_ids`, `signing_keys` and `encryption_keys`, which are
//! cheap: they look only at the facts gathered while cleaning.

use std::io::Cursor;

use pgp::composed::{
    ArmorOptions, Deserializable, PublicOrSecret, SignedKeyDetails, SignedPublicKey, SignedPublicSubKey,
    SignedSecretKey,
};
use pgp::crypto::sym::SymmetricKeyAlgorithm;
use pgp::packet::{self, Signature, SignatureType, Subpacket, SubpacketData};
use pgp::ser::Serialize;
use pgp::types::{KeyDetails, KeyVersion, Password, SignedUser, Tag};
use zeroize::Zeroizing;

use crate::policy::{self, Use};
use crate::{CLOCK_SKEW, Error, MAX_CERT_BYTES, hex, malformed, short};

/// The most user ids, subkeys and signatures on one of them that are looked at. Real keys have a handful; more is
/// a flooded or hostile certificate, and checking every signature would cost too much.
const MAX_USER_IDS: usize = 64;
const MAX_SUBKEYS: usize = 64;
const MAX_SIGNATURES: usize = 32;

/// Why a certificate (or one of its keys) is not usable at a time.
#[derive(Debug, Clone, PartialEq, Eq)]
pub enum CertProblem {
    /// Revoked by its owner, with the reason they gave, if any.
    Revoked { reason: Option<String> },
    /// Expired at this time.
    Expired { at: i64 },
    /// Made after the time asked about.
    NotYetValid,
    /// No user id or direct signature of the key's own verifies.
    NoSelfSignature,
    /// The policy refuses its algorithm, by name.
    Refused(String),
    /// No key of it may sign.
    NoSigningKey,
    /// No key of it may be encrypted to.
    NoEncryptionKey,
}

/// A user id of a certificate, with the address in it.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct UserId {
    pub text: String,
    /// The mail address, lower case, if the user id holds one.
    pub address: Option<String>,
    pub primary: bool,
}

/// The address in a user id: `Name <addr>`, `<addr>` or a bare address. Lower case, as addresses are compared.
pub fn address_of(user_id: &str) -> Option<String> {
    let user_id = user_id.trim();
    let candidate = match (user_id.rfind('<'), user_id.ends_with('>')) {
        (Some(open), true) => &user_id[open + 1..user_id.len() - 1],
        _ => user_id,
    };
    let candidate = candidate.trim();
    let (local, domain) = candidate.split_once('@')?;
    let ok = !local.is_empty()
        && !domain.is_empty()
        && domain.contains('.')
        && !candidate
            .chars()
            .any(|c| c.is_whitespace() || c.is_control() || matches!(c, '<' | '>' | ',' | '"'))
        && !domain.contains('@');
    ok.then(|| candidate.to_lowercase())
}

/// What cleaning found out about one signature that verified.
#[derive(Debug, Clone)]
struct Fact {
    created: i64,
    /// When the signature itself stops counting.
    sig_expires: Option<i64>,
    /// Seconds after the key's creation when the key expires (0: never), if the signature says.
    key_expiry: Option<i64>,
    flags: Flags,
    primary: bool,
    revocation: Option<Revocation>,
    symmetric: Vec<SymmetricKeyAlgorithm>,
    seipd_v2: bool,
}

impl Fact {
    /// Made by `at` (give or take the clock skew) and not expired at it.
    fn live(&self, at: i64) -> bool {
        self.created <= at + CLOCK_SKEW && self.sig_expires.is_none_or(|end| end > at)
    }

    /// A revocation that counts at `at`: a hard one always, a soft one from its time.
    fn revokes_at(&self, at: i64) -> Option<&Revocation> {
        self.revocation
            .as_ref()
            .filter(|revocation| revocation.hard || self.created <= at)
    }

    /// When the component made at `created` expires by this binding.
    fn key_expires(&self, created: i64) -> Option<i64> {
        self.key_expiry.filter(|secs| *secs > 0).map(|secs| created + secs)
    }
}

#[derive(Debug, Clone, Copy, Default, PartialEq, Eq)]
struct Flags {
    known: bool,
    sign: bool,
    /// When the signing subkey's back signature expires: it signs only until then.
    sign_until: Option<i64>,
    encrypt: bool,
}

impl Flags {
    fn signs_at(&self, at: i64) -> bool {
        self.sign && self.sign_until.is_none_or(|end| end > at)
    }
}

#[derive(Debug, Clone, PartialEq, Eq)]
struct Revocation {
    /// Compromised or no reason given: the key is taken back for all time, signatures made before too.
    hard: bool,
    reason: Option<String>,
}

#[derive(Debug, Clone, Default)]
struct Facts {
    /// Direct key signatures.
    direct: Vec<Fact>,
    /// Key revocations.
    revocations: Vec<Fact>,
    /// For each user id of the cleaned certificate.
    users: Vec<Vec<Fact>>,
    /// The address in each user id, in the same order.
    addresses: Vec<Option<String>>,
    /// For each subkey of the cleaned certificate.
    subkeys: Vec<Vec<Fact>>,
    /// The fingerprints and key ids of every key, upper case hex.
    handles: Vec<String>,
}

/// A public certificate, cleaned when read.
#[derive(Debug, Clone)]
pub struct Cert {
    pub(crate) key: SignedPublicKey,
    facts: Facts,
}

/// The key to use for signing or encryption: the primary key or one subkey of a certificate.
#[derive(Debug, Clone, Copy)]
pub(crate) enum Component<'a> {
    Primary(&'a packet::PublicKey),
    Subkey(&'a SignedPublicSubKey),
}

impl Component<'_> {
    pub(crate) fn fingerprint(&self) -> pgp::types::Fingerprint {
        match self {
            Component::Primary(key) => key.fingerprint(),
            Component::Subkey(sub) => sub.key.fingerprint(),
        }
    }

    /// Its fingerprint and key id, upper case hex.
    pub(crate) fn handles(&self) -> [String; 2] {
        let key_id = match self {
            Component::Primary(key) => key.legacy_key_id(),
            Component::Subkey(sub) => sub.key.legacy_key_id(),
        };
        [hex(self.fingerprint().as_bytes()), hex(key_id.as_ref())]
    }
}

fn timestamp(sig: &Signature) -> Option<i64> {
    sig.created().map(|t| i64::from(t.as_secs()))
}

fn issued_by(sig: &Signature, key: &impl KeyDetails) -> bool {
    let fingerprints = sig.issuer_fingerprint();
    let ids = sig.issuer_key_id();
    if fingerprints.is_empty() && ids.is_empty() {
        // no issuer said: it can still be the key's own; the signature check decides
        return true;
    }
    let (fingerprint, key_id) = (key.fingerprint(), key.legacy_key_id());
    fingerprints.iter().any(|f| **f == fingerprint) || ids.iter().any(|id| **id == key_id)
}

fn flags_of(sig: &Signature) -> Flags {
    let known = sig.config().is_some_and(|config| {
        config
            .hashed_subpackets
            .iter()
            .any(|sub: &Subpacket| matches!(sub.data, SubpacketData::KeyFlags(_)))
    });
    let flags = sig.key_flags();
    Flags {
        known,
        sign: flags.sign(),
        sign_until: None,
        encrypt: flags.encrypt_comms() || flags.encrypt_storage(),
    }
}

fn revocation_of(sig: &Signature) -> Revocation {
    use pgp::packet::RevocationCode;
    let code = sig.revocation_reason_code();
    let hard = !matches!(
        code,
        Some(RevocationCode::KeySuperseded | RevocationCode::KeyRetired | RevocationCode::CertUserIdInvalid)
    );
    let reason = sig.revocation_reason_string().map(|text| {
        let mut text = String::from_utf8_lossy(text).into_owned();
        text.retain(|c| !c.is_control());
        short(text)
    });
    Revocation {
        hard,
        reason: reason.filter(|text| !text.is_empty()),
    }
}

/// The facts of a signature that verified, if the policy accepts it for a binding.
fn fact(sig: &Signature) -> Option<Fact> {
    let created = timestamp(sig)?;
    policy::hash(sig.hash_alg()?, Use::Binding, created).ok()?;
    if policy::critical_notation(sig) {
        return None;
    }
    let typ = sig.typ()?;
    let revocation = matches!(
        typ,
        SignatureType::KeyRevocation | SignatureType::SubkeyRevocation | SignatureType::CertRevocation
    )
    .then(|| revocation_of(sig));
    Some(Fact {
        created,
        sig_expires: sig
            .signature_expiration_time()
            .map(|d| i64::from(d.as_secs()))
            .filter(|secs| *secs > 0)
            .map(|secs| created + secs),
        key_expiry: sig.key_expiration_time().map(|d| i64::from(d.as_secs())),
        flags: flags_of(sig),
        primary: sig.is_primary(),
        revocation,
        symmetric: sig.preferred_symmetric_algs().to_vec(),
        seipd_v2: sig.features().is_some_and(|f| f.seipd_v2()),
    })
}

/// The back signature of a signing subkey's binding `sig` made at `created`: any embedded signature, in either area
/// (one that does not verify proves nothing, so a false one put first changes nothing), that verifies, uses a hash
/// the policy takes and has no critical notation. `Some` with when it expires, if it does.
fn back_signature(
    sig: &Signature,
    subkey: &packet::PublicSubkey,
    primary: &packet::PublicKey,
    created: i64,
) -> Option<Option<i64>> {
    let config = sig.config()?;
    config
        .hashed_subpackets()
        .chain(config.unhashed_subpackets())
        .filter_map(|sub| match &sub.data {
            SubpacketData::EmbeddedSignature(back) => Some(&**back),
            _ => None,
        })
        .filter(|back| {
            back.verify_primary_key_binding(subkey, primary).is_ok()
                && back
                    .hash_alg()
                    .is_some_and(|hash| policy::hash(hash, Use::Binding, created).is_ok())
                && !policy::critical_notation(back)
        })
        .map(|back| {
            let made = timestamp(back).unwrap_or(created);
            back.signature_expiration_time()
                .map(|d| i64::from(d.as_secs()))
                .filter(|secs| *secs > 0)
                .map(|secs| made + secs)
        })
        // the one that lasts longest
        .max_by_key(|until| until.unwrap_or(i64::MAX))
}

/// The signatures of a component that are the key's own: those `wanted` (the right type, issued by the key, cheap to
/// tell) are ranked newest first and the newest `MAX_SIGNATURES` checked with `verifies` and the policy. Filtering
/// before ranking keeps a flood of other people's certifications from pushing the key's own out.
fn kept(
    signatures: Vec<Signature>,
    wanted: impl Fn(&Signature) -> bool,
    verifies: impl Fn(&Signature) -> bool,
) -> (Vec<Signature>, Vec<Fact>) {
    let mut candidates: Vec<Signature> = signatures.into_iter().filter(|sig| wanted(sig)).collect();
    candidates.sort_by_key(|sig| std::cmp::Reverse(timestamp(sig).unwrap_or(0)));
    candidates.truncate(MAX_SIGNATURES);
    candidates
        .into_iter()
        .filter(|sig| verifies(sig))
        .filter_map(|sig| fact(&sig).map(|fact| (sig, fact)))
        .unzip()
}

impl Cert {
    /// Cleans a certificate: only the key's own signatures that verify and that the policy accepts are kept.
    pub(crate) fn clean(key: SignedPublicKey) -> Result<Cert, Error> {
        let SignedPublicKey {
            primary_key: primary,
            details,
            public_subkeys,
        } = key;
        policy::key(primary.algorithm(), primary.public_params())
            .map_err(|refusal| Error::Unusable(CertProblem::Refused(refusal)))?;
        let mut facts = Facts::default();
        let primary_ref = &primary;
        let own = |typ: SignatureType| move |sig: &Signature| sig.typ() == Some(typ) && issued_by(sig, primary_ref);
        let (revocations, revocation_facts) = kept(
            details.revocation_signatures,
            own(SignatureType::KeyRevocation),
            |sig| sig.verify_key(&primary).is_ok(),
        );
        let (direct, direct_facts) = kept(details.direct_signatures, own(SignatureType::Key), |sig| {
            sig.verify_key(&primary).is_ok()
        });
        facts.revocations = revocation_facts;
        facts.direct = direct_facts;

        let mut users = Vec::new();
        for user in details.users.into_iter().take(MAX_USER_IDS) {
            let Some(text) = user.id.as_str() else { continue };
            let address = address_of(text);
            let (signatures, user_facts) = kept(
                user.signatures,
                |sig| sig.is_certification() && issued_by(sig, &primary),
                |sig| sig.verify_certification(&primary, Tag::UserId, &user.id).is_ok(),
            );
            if !signatures.is_empty() {
                users.push(SignedUser::new(user.id, signatures));
                facts.users.push(user_facts);
                facts.addresses.push(address);
            }
        }

        let mut subkeys = Vec::new();
        for sub in public_subkeys.into_iter().take(MAX_SUBKEYS) {
            let (signatures, mut sub_facts) = kept(
                sub.signatures,
                |sig| issued_by(sig, &primary),
                |sig| sig.verify_subkey_binding(&primary, &sub.key).is_ok(),
            );
            for (sig, fact) in signatures.iter().zip(&mut sub_facts) {
                if fact.revocation.is_none() && fact.flags.sign {
                    // a signing subkey must sign back that it belongs to this primary key, or anyone could bind
                    // someone else's signing key to their certificate and claim its signatures
                    let back = back_signature(sig, &sub.key, &primary, fact.created);
                    fact.flags.sign = back.is_some();
                    fact.flags.sign_until = back.flatten();
                }
            }
            if !signatures.is_empty() {
                subkeys.push(SignedPublicSubKey {
                    key: sub.key,
                    signatures,
                });
                facts.subkeys.push(sub_facts);
            }
        }
        let details = SignedKeyDetails::new(revocations, direct, users, Vec::new());
        let key = SignedPublicKey::new(primary, details, subkeys);
        let mut cert = Cert { key, facts };
        cert.facts.handles = cert.components().flat_map(|component| component.handles()).collect();
        Ok(cert)
    }

    /// The primary key and every subkey.
    pub(crate) fn components(&self) -> impl Iterator<Item = Component<'_>> {
        std::iter::once(Component::Primary(&self.key.primary_key))
            .chain(self.key.public_subkeys.iter().map(Component::Subkey))
    }

    /// The fingerprint in upper case hex.
    pub fn fingerprint(&self) -> String {
        hex(self.key.primary_key.fingerprint().as_bytes())
    }

    /// The 16 hex digit key id of the primary key.
    pub fn key_id(&self) -> String {
        hex(self.key.primary_key.legacy_key_id().as_ref())
    }

    /// The fingerprints and key ids of the primary key and every subkey, upper case hex, for matching the issuer of a
    /// signature or the recipient of a message.
    pub fn handles(&self) -> &[String] {
        &self.facts.handles
    }

    pub fn created(&self) -> i64 {
        i64::from(self.key.primary_key.created_at().as_secs())
    }

    pub fn is_v6(&self) -> bool {
        self.key.primary_key.version() == KeyVersion::V6
    }

    /// The algorithm in words for the Details windows: "Ed25519", "RSA 4096".
    pub fn algorithm(&self) -> String {
        describe(self.key.primary_key.public_params(), self.key.primary_key.algorithm())
    }

    /// The certificate in binary form, as it is kept.
    pub fn to_bytes(&self) -> Vec<u8> {
        self.key.to_bytes().unwrap_or_default()
    }

    /// The certificate armored, for export and for attaching to a message.
    pub fn armored(&self) -> String {
        self.key.to_armored_string(ArmorOptions::default()).unwrap_or_default()
    }

    /// Is the certificate itself usable at `at`: made before it, not revoked, not expired, with a self-signature?
    pub fn status(&self, at: i64) -> Result<(), CertProblem> {
        if self.created() > at + CLOCK_SKEW {
            return Err(CertProblem::NotYetValid);
        }
        if let Some(revocation) = self.facts.revocations.iter().find_map(|fact| fact.revokes_at(at)) {
            return Err(CertProblem::Revoked {
                reason: revocation.reason.clone(),
            });
        }
        let binding = self.primary_binding(at).ok_or(CertProblem::NoSelfSignature)?;
        match binding.key_expires(self.created()) {
            Some(expires) if expires <= at => Err(CertProblem::Expired { at: expires }),
            _ => Ok(()),
        }
    }

    /// When the certificate expires, judged now.
    pub fn expires(&self, now: i64) -> Option<i64> {
        self.primary_binding(now)
            .and_then(|binding| binding.key_expires(self.created()))
    }

    /// The self-signature that says what the primary key is at `at`: the newest direct key signature, else the
    /// binding of the primary user id, else the newest user id binding.
    fn primary_binding(&self, at: i64) -> Option<&Fact> {
        if let Some(direct) = newest_live(&self.facts.direct, at) {
            return Some(direct);
        }
        let bindings = || {
            self.facts
                .users
                .iter()
                .filter_map(|facts| newest_live(facts, at))
                .filter(|fact| fact.revocation.is_none())
        };
        bindings()
            .filter(|fact| fact.primary)
            .max_by_key(|fact| fact.created)
            .or_else(|| bindings().max_by_key(|fact| fact.created))
    }

    /// Is user id `index` the key's own at `at`: bound, its binding not expired, not revoked?
    fn user_valid(&self, index: usize, at: i64) -> Option<&Fact> {
        let latest = self.facts.users[index]
            .iter()
            .filter(|fact| fact.created <= at + CLOCK_SKEW)
            .max_by_key(|fact| fact.created)?;
        latest
            .live(at)
            .then_some(latest)
            .filter(|fact| fact.revocation.is_none())
    }

    /// The user ids that are the key's own at `at`: bound and not revoked.
    pub fn user_ids(&self, at: i64) -> Vec<UserId> {
        let mut out = Vec::new();
        for (index, user) in self.key.details.users.iter().enumerate() {
            let (Some(latest), Some(text)) = (self.user_valid(index, at), user.id.as_str()) else {
                continue;
            };
            let text: String = text.chars().filter(|c| !c.is_control()).collect();
            out.push(UserId {
                address: self.facts.addresses[index].clone(),
                text,
                primary: latest.primary,
            });
        }
        out
    }

    /// The addresses of `user_ids(at)`.
    pub fn addresses(&self, at: i64) -> Vec<String> {
        let mut out: Vec<String> = (0..self.facts.users.len())
            .filter(|index| self.user_valid(*index, at).is_some())
            .filter_map(|index| self.facts.addresses[index].clone())
            .collect();
        out.dedup();
        out
    }

    /// Does the certificate hold `address` at `at`? Addresses are compared without regard to case.
    pub fn has_address(&self, address: &str, at: i64) -> bool {
        let wanted = address.trim().to_lowercase();
        self.facts
            .addresses
            .iter()
            .enumerate()
            .any(|(index, own)| own.as_deref() == Some(wanted.as_str()) && self.user_valid(index, at).is_some())
    }

    /// The flags of the primary key at `at`. A key without key flags (made before they existed) signs, and encrypts
    /// if its algorithm can.
    fn primary_flags(&self, at: i64) -> Flags {
        match self.primary_binding(at) {
            Some(binding) if binding.flags.known => binding.flags,
            Some(_) => Flags {
                known: false,
                sign: true,
                sign_until: None,
                encrypt: self.key.primary_key.algorithm().can_encrypt(),
            },
            None => Flags::default(),
        }
    }

    /// The keys that may sign at `at`, primary first.
    pub(crate) fn signing_keys(&self, at: i64) -> Vec<Component<'_>> {
        self.usable(at, |flags| flags.signs_at(at), |alg| alg.can_sign())
    }

    /// The keys that may be encrypted to at `at`.
    pub(crate) fn encryption_keys(&self, at: i64) -> Vec<Component<'_>> {
        self.usable(at, |flags| flags.encrypt, |alg| alg.can_encrypt())
    }

    fn usable(
        &self,
        at: i64,
        wanted: impl Fn(&Flags) -> bool,
        can: impl Fn(pgp::crypto::public_key::PublicKeyAlgorithm) -> bool,
    ) -> Vec<Component<'_>> {
        if self.status(at).is_err() {
            return Vec::new();
        }
        let mut out = Vec::new();
        let primary = &self.key.primary_key;
        if wanted(&self.primary_flags(at)) && can(primary.algorithm()) {
            out.push(Component::Primary(primary));
        }
        for (sub, facts) in self.key.public_subkeys.iter().zip(&self.facts.subkeys) {
            let created = i64::from(sub.key.created_at().as_secs());
            if created > at + CLOCK_SKEW
                || policy::key(sub.key.algorithm(), sub.key.public_params()).is_err()
                || facts.iter().any(|fact| fact.revokes_at(at).is_some())
            {
                continue;
            }
            let binding = facts
                .iter()
                .filter(|fact| fact.revocation.is_none() && fact.live(at))
                .max_by_key(|fact| fact.created);
            if let Some(binding) = binding
                && binding.key_expires(created).is_none_or(|end| end > at)
                && wanted(&binding.flags)
                && can(sub.key.algorithm())
            {
                out.push(Component::Subkey(sub));
            }
        }
        out
    }

    /// May the component with this fingerprint decrypt? Only one some binding of it ever marked for encryption (or
    /// a primary key from before key flags whose algorithm encrypts), at any time, so that old mail opens with an
    /// expired key; a signing or certifying key never decrypts, which would make it an oracle for what it signs.
    pub(crate) fn decrypts_with(&self, fingerprint: &pgp::types::Fingerprint) -> bool {
        let encrypts = |facts: &[Fact]| facts.iter().any(|fact| fact.revocation.is_none() && fact.flags.encrypt);
        if self.key.primary_key.fingerprint() == *fingerprint {
            let bindings: Vec<&Fact> = self
                .facts
                .direct
                .iter()
                .chain(self.facts.users.iter().flatten())
                .collect();
            if bindings.iter().any(|fact| fact.flags.known) {
                return bindings
                    .iter()
                    .any(|fact| fact.revocation.is_none() && fact.flags.encrypt);
            }
            return self.key.primary_key.algorithm().can_encrypt();
        }
        self.key
            .public_subkeys
            .iter()
            .zip(&self.facts.subkeys)
            .any(|(sub, facts)| sub.key.fingerprint() == *fingerprint && encrypts(facts))
    }

    /// Why no key can be encrypted to at `at`, if none can.
    pub fn can_encrypt(&self, at: i64) -> Result<(), CertProblem> {
        self.status(at)?;
        if self.encryption_keys(at).is_empty() {
            Err(CertProblem::NoEncryptionKey)
        } else {
            Ok(())
        }
    }

    /// Why no key can sign at `at`, if none can.
    pub fn can_sign(&self, at: i64) -> Result<(), CertProblem> {
        self.status(at)?;
        if self.signing_keys(at).is_empty() {
            Err(CertProblem::NoSigningKey)
        } else {
            Ok(())
        }
    }

    /// The ciphers the holder prefers, from the primary binding.
    pub(crate) fn prefers(&self, cipher: SymmetricKeyAlgorithm, at: i64) -> bool {
        self.primary_binding(at)
            .is_some_and(|fact| fact.symmetric.contains(&cipher))
    }

    /// Does the holder's software read SEIPDv2 (AEAD) messages?
    pub(crate) fn reads_seipd_v2(&self, at: i64) -> bool {
        self.primary_binding(at).is_some_and(|fact| fact.seipd_v2)
    }

    /// One certificate from two copies of the same key (a newer copy from a key server, an Autocrypt header): every
    /// user id, subkey and signature of both, cleaned again. `None` when they are not the same key. When the other
    /// copy brings nothing new (an Autocrypt header on every message), nothing is checked again.
    pub fn merge(&self, other: &Cert) -> Option<Cert> {
        if self.fingerprint() != other.fingerprint() {
            return None;
        }
        let mut key = self.key.clone();
        let theirs = &other.key;
        let mut changed = add_unique(
            &mut key.details.revocation_signatures,
            &theirs.details.revocation_signatures,
        );
        changed |= add_unique(&mut key.details.direct_signatures, &theirs.details.direct_signatures);
        for user in &theirs.details.users {
            match key.details.users.iter_mut().find(|own| own.id.id() == user.id.id()) {
                Some(own) => changed |= add_unique(&mut own.signatures, &user.signatures),
                None => {
                    key.details.users.push(user.clone());
                    changed = true;
                }
            }
        }
        for sub in &theirs.public_subkeys {
            let fingerprint = sub.key.fingerprint();
            match key
                .public_subkeys
                .iter_mut()
                .find(|own| own.key.fingerprint() == fingerprint)
            {
                Some(own) => changed |= add_unique(&mut own.signatures, &sub.signatures),
                None => {
                    key.public_subkeys.push(sub.clone());
                    changed = true;
                }
            }
        }
        if !changed {
            return Some(self.clone());
        }
        Cert::clean(key).ok()
    }

    /// The smallest certificate that lets someone write to `address` at `now`: the primary key, that one user id
    /// with its newest binding, and the encryption subkeys with theirs (and signing subkeys, so signatures verify).
    /// For the Autocrypt header, which travels in every message.
    pub fn minimal(&self, address: &str, now: i64) -> Option<Cert> {
        let wanted = address.trim().to_lowercase();
        let keep: Vec<_> = self
            .encryption_keys(now)
            .into_iter()
            .chain(self.signing_keys(now))
            .filter_map(|component| match component {
                Component::Subkey(sub) => Some(sub.key.fingerprint()),
                Component::Primary(_) => None,
            })
            .collect();
        let users = self
            .key
            .details
            .users
            .iter()
            .zip(&self.facts.addresses)
            .find(|(_, own)| own.as_deref() == Some(wanted.as_str()))
            .map(|(user, _)| SignedUser::new(user.id.clone(), newest_one(&user.signatures)))
            .into_iter()
            .collect();
        let subkeys = self
            .key
            .public_subkeys
            .iter()
            .filter(|sub| keep.contains(&sub.key.fingerprint()))
            .map(|sub| SignedPublicSubKey {
                key: sub.key.clone(),
                signatures: newest_one(&sub.signatures),
            })
            .collect();
        let details = SignedKeyDetails::new(
            Vec::new(),
            newest_one(&self.key.details.direct_signatures),
            users,
            Vec::new(),
        );
        let cert = Cert::clean(SignedPublicKey::new(self.key.primary_key.clone(), details, subkeys)).ok()?;
        (cert.has_address(&wanted, now) && cert.can_encrypt(now).is_ok()).then_some(cert)
    }
}

fn newest_live(facts: &[Fact], at: i64) -> Option<&Fact> {
    facts
        .iter()
        .filter(|fact| fact.live(at))
        .max_by_key(|fact| fact.created)
}

fn newest_one(signatures: &[Signature]) -> Vec<Signature> {
    signatures
        .iter()
        .max_by_key(|sig| timestamp(sig).unwrap_or(0))
        .cloned()
        .into_iter()
        .collect()
}

/// Adds the signatures of `theirs` that `own` does not have; whether there were any.
fn add_unique(own: &mut Vec<Signature>, theirs: &[Signature]) -> bool {
    let before = own.len();
    for sig in theirs {
        if !own.contains(sig) {
            own.push(sig.clone());
        }
    }
    own.len() > before
}

pub(crate) fn describe(
    params: &pgp::types::PublicParams,
    algorithm: pgp::crypto::public_key::PublicKeyAlgorithm,
) -> String {
    use pgp::types::PublicParams;
    use rsa::traits::PublicKeyParts;
    match params {
        PublicParams::RSA(rsa) => format!("RSA {}", rsa.key.n().bits()),
        PublicParams::EdDSALegacy(_) | PublicParams::Ed25519(_) => "Ed25519".into(),
        PublicParams::Ed448(_) => "Ed448".into(),
        PublicParams::X25519(_) => "X25519".into(),
        PublicParams::X448(_) => "X448".into(),
        PublicParams::ECDH(params) => format!("ECDH {}", params.curve()),
        PublicParams::ECDSA(params) => format!("ECDSA {}", params.curve()),
        _ => format!("{algorithm:?}"),
    }
}

/// The keys in `bytes`, public and private, armored or binary, within the size limit.
fn parse_keys(bytes: &[u8]) -> Result<Vec<PublicOrSecret>, Error> {
    if bytes.len() > MAX_CERT_BYTES {
        return Err(Error::TooLarge);
    }
    let (parsed, _) = PublicOrSecret::from_reader_many(Cursor::new(bytes)).map_err(malformed)?;
    parsed.map(|item| item.map_err(malformed)).collect()
}

/// Every certificate in `bytes`: armored or binary, one or a key ring. Private keys in the data are read as their
/// public part. Certificates the policy refuses outright (a 1024 bit RSA primary key) are left out; broken data is an
/// error.
pub fn read_certs(bytes: &[u8]) -> Result<Vec<Cert>, Error> {
    let mut out = Vec::new();
    let mut refused = None;
    for item in parse_keys(bytes)? {
        let key = match item {
            PublicOrSecret::Public(key) => key,
            PublicOrSecret::Secret(key) => key.to_public_key(),
        };
        match Cert::clean(key) {
            Ok(cert) => out.push(cert),
            Err(error) => refused = Some(error),
        }
    }
    match (out.is_empty(), refused) {
        (true, Some(error)) => Err(error),
        (true, None) => Err(Error::Malformed("no key found".into())),
        _ => Ok(out),
    }
}

/// A private key, unlocked (its secret parts not protected by a passphrase), with its certificate.
#[derive(Clone)]
pub struct SecretKey {
    pub(crate) key: SignedSecretKey,
    cert: Cert,
}

impl std::fmt::Debug for SecretKey {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        write!(f, "SecretKey({})", self.cert.fingerprint())
    }
}

impl SecretKey {
    /// A private key whose secret parts are checked against its public ones: a key file can carry someone's genuine
    /// public key with secret bytes that do not belong to it, which would sign and decrypt nothing.
    pub(crate) fn new(key: SignedSecretKey) -> Result<SecretKey, Error> {
        if !genuine(&key) {
            return Err(Error::Mismatch);
        }
        let cert = Cert::clean(key.to_public_key())?;
        Ok(SecretKey { key, cert })
    }

    pub fn cert(&self) -> &Cert {
        &self.cert
    }

    pub fn fingerprint(&self) -> String {
        self.cert.fingerprint()
    }

    /// The key in binary form without a passphrase, for the core to wrap under its master key. Wiped when dropped.
    pub fn to_bytes(&self) -> Zeroizing<Vec<u8>> {
        Zeroizing::new(self.key.to_bytes().unwrap_or_default())
    }

    /// A key from `to_bytes`.
    pub fn from_bytes(bytes: &[u8]) -> Result<SecretKey, Error> {
        if bytes.len() > MAX_CERT_BYTES {
            return Err(Error::TooLarge);
        }
        let key = SignedSecretKey::from_bytes(Cursor::new(bytes)).map_err(malformed)?;
        if is_locked(&key) {
            return Err(Error::WrongPassphrase);
        }
        SecretKey::new(key)
    }

    /// The key armored and protected by `passphrase`, for a backup (iterated and salted S2K with AES, which every
    /// OpenPGP program reads).
    pub fn backup(&self, passphrase: &str) -> Result<String, Error> {
        let mut key = self.key.clone();
        let password = Password::from(passphrase);
        let mut rng = rand::thread_rng();
        key.primary_key.set_password(&mut rng, &password).map_err(malformed)?;
        for sub in &mut key.secret_subkeys {
            sub.key.set_password(&mut rng, &password).map_err(malformed)?;
        }
        key.to_armored_string(ArmorOptions::default()).map_err(malformed)
    }
}

/// Whether every secret part of `key` belongs to its public part: each one that can sign signs a test value its public
/// key verifies, each one that can encrypt opens a test message encrypted to its public key.
fn genuine(key: &SignedSecretKey) -> bool {
    use pgp::crypto::hash::HashAlgorithm;
    use pgp::types::{SigningKey, VerifyingKey};
    let digest = [0x5au8; 32];
    let signs = |secret: &dyn SigningKey, public: &dyn VerifyingKey| {
        secret
            .sign(&Password::empty(), HashAlgorithm::Sha256, &digest)
            .is_ok_and(|sig| public.verify(HashAlgorithm::Sha256, &digest, &sig).is_ok())
    };
    let primary = &key.primary_key;
    if primary.algorithm().can_sign() && !signs(primary, primary.public_key()) {
        return false;
    }
    if primary.algorithm().can_encrypt() && !round_trip(key, primary.public_key()) {
        return false;
    }
    key.secret_subkeys.iter().all(|sub| {
        (!sub.key.algorithm().can_sign() || signs(&sub.key, sub.key.public_key()))
            && (!sub.key.algorithm().can_encrypt() || round_trip(key, sub.key.public_key()))
    })
}

/// Whether a message encrypted to `public` (a key of `key`) opens with `key`
fn round_trip(key: &SignedSecretKey, public: &impl pgp::types::EncryptionKey) -> bool {
    use pgp::composed::{Message, MessageBuilder};
    let mut rng = rand::thread_rng();
    let mut builder = MessageBuilder::from_bytes("", &b"check"[..])
        .seipd_v1(&mut rng, pgp::crypto::sym::SymmetricKeyAlgorithm::AES128);
    if builder.encrypt_to_key(&mut rng, public).is_err() {
        return false;
    }
    let Ok(message) = builder.to_vec(&mut rng) else {
        return false;
    };
    let Ok(parsed) = Message::from_bytes(&message[..]) else {
        return false;
    };
    parsed
        .decrypt(&Password::empty(), key)
        .and_then(|mut opened| opened.as_data_vec().map_err(Into::into))
        .is_ok_and(|data| data == b"check")
}

fn is_locked(key: &SignedSecretKey) -> bool {
    key.primary_key.secret_params().is_encrypted()
        || key
            .secret_subkeys
            .iter()
            .any(|sub| sub.key.secret_params().is_encrypted())
}

fn unlock(mut key: SignedSecretKey, passphrase: &str) -> Result<SignedSecretKey, Error> {
    let password = Password::from(passphrase);
    if key.primary_key.secret_params().is_encrypted() {
        key.primary_key
            .remove_password(&password)
            .map_err(|_| Error::WrongPassphrase)?;
    }
    for sub in &mut key.secret_subkeys {
        if sub.key.secret_params().is_encrypted() {
            sub.key.remove_password(&password).map_err(|_| Error::WrongPassphrase)?;
        }
    }
    Ok(key)
}

/// Does reading the private keys in `bytes` need a passphrase? An error when there is no private key in them.
pub fn needs_passphrase(bytes: &[u8]) -> Result<bool, Error> {
    Ok(parse_secret(bytes)?.iter().any(is_locked))
}

fn parse_secret(bytes: &[u8]) -> Result<Vec<SignedSecretKey>, Error> {
    let keys: Vec<SignedSecretKey> = parse_keys(bytes)?
        .into_iter()
        .filter_map(|item| match item {
            PublicOrSecret::Secret(key) => Some(key),
            PublicOrSecret::Public(_) => None,
        })
        .collect();
    if keys.is_empty() {
        Err(Error::WrongKind)
    } else {
        Ok(keys)
    }
}

/// Every private key in `bytes`, unlocked with `passphrase` when they are protected.
pub fn read_secret_keys(bytes: &[u8], passphrase: &str) -> Result<Vec<SecretKey>, Error> {
    parse_secret(bytes)?
        .into_iter()
        .map(|key| unlock(key, passphrase).and_then(SecretKey::new))
        .collect()
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn secret_parts_that_do_not_belong_are_refused() {
        // Alice's genuine public key and self-signatures, with Mallory's secret bytes in the primary key packet
        let alice = crate::generate("Alice", &["alice@example.org".into()], 1_794_700_800)
            .unwrap()
            .key;
        let mallory = crate::generate("Mallory", &["m@example.org".into()], 1_794_700_800)
            .unwrap()
            .key;
        let mut forged = alice.clone();
        forged.primary_key = packet::SecretKey::new(
            alice.primary_key.public_key().clone(),
            mallory.primary_key.secret_params().clone(),
        )
        .unwrap();
        let bytes = forged.to_bytes().unwrap();
        assert_eq!(SecretKey::from_bytes(&bytes).unwrap_err(), Error::Mismatch);
        // and in the encryption subkey
        let mut forged = alice.clone();
        forged.secret_subkeys[0].key = packet::SecretSubkey::new(
            alice.secret_subkeys[0].key.public_key().clone(),
            mallory.secret_subkeys[0].key.secret_params().clone(),
        )
        .unwrap();
        assert_eq!(
            SecretKey::from_bytes(&forged.to_bytes().unwrap()).unwrap_err(),
            Error::Mismatch
        );
        assert!(SecretKey::from_bytes(&alice.to_bytes().unwrap()).is_ok());
    }

    #[test]
    fn addresses_in_user_ids() {
        assert_eq!(
            address_of("Alice <Alice@Example.org>").as_deref(),
            Some("alice@example.org")
        );
        assert_eq!(address_of("<bob@example.net>").as_deref(), Some("bob@example.net"));
        assert_eq!(address_of("carol@example.com").as_deref(), Some("carol@example.com"));
        assert_eq!(
            address_of("Dave (work) <dave@example.com>").as_deref(),
            Some("dave@example.com")
        );
        assert_eq!(address_of("Just a name"), None);
        assert_eq!(address_of("x <a@b@c.com>"), None);
        assert_eq!(address_of("x <a b@c.com>"), None);
        assert_eq!(address_of("x <a@localhost>"), None);
        assert_eq!(
            address_of("Mallory <evil@x.com> <alice@example.org>").as_deref(),
            Some("alice@example.org")
        );
    }
}
