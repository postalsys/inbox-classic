//! Reading signed and encrypted mail (PGP/MIME, RFC 3156, and inline PGP): which parts of a message are protected,
//! how, and what each part's verdict is.
//!
//! The rules (RFC 9787):
//! - The **envelope** is the run of cryptographic layers that starts at the top of the message. Only it says what the
//!   whole message is.
//! - A layer anywhere else is **errant**: the part it covers is a section of its own with its own verdict, and the
//!   rest of the message is not protected by it.
//! - The message is cut into **sections** in their order: each protected subtree one, the unprotected runs between
//!   them others. Each is rendered as a document of its own, so one can not reach into another.
//! - A signature counts for the sender only when the key that made it has the address of the message's one From.
//! - Inline PGP signatures are not checked (what they cover can not be bound to what is shown); inline encrypted
//!   blocks are decrypted into a section of their own.
//! - Nothing is shown of encrypted data whose integrity does not check.

use std::collections::HashSet;

use pe_i18n::{Text, tr, tr_args};
use pe_mime::outline::{Outline, outline};
use pe_pgp::{Cert, DecryptError, Problem, SecretKey, SigCheck, SigStatus};

/// The keys a message is read with: the user's private keys (to decrypt) and every certificate kept (to verify)
#[derive(Default)]
pub struct KeyRing {
    pub keys: Vec<SecretKey>,
    pub certs: Vec<Cert>,
    /// (fingerprint, address) pairs the user verified
    pub verified: HashSet<(String, String)>,
}

/// How a part's colour and words read: from the strongest to none
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum Tone {
    /// Signed by the sender, with a key the user verified: green
    Verified,
    /// Signed by the sender with a key found, not verified; or encrypted and not signed: blue
    Good,
    /// Something is not right (a signature that does not match, another signer): amber
    Warning,
    /// Not signed, or the key is not known: grey
    Neutral,
}

/// What a part's signature is worth
#[derive(Debug, Clone, PartialEq, Eq)]
pub enum Signature {
    /// Not signed
    None,
    /// By the sender, the key verified by the user
    Verified { signer: String, at: i64 },
    /// By the sender, the key not verified
    Signed { signer: String, at: i64 },
    /// A good signature by someone who is not the sender
    OtherPerson { signer: String, at: i64 },
    /// Signed with a key that is not known here (its id, to look it up)
    UnknownKey { key: String },
    /// A signature that does not count, and why, in words
    Bad { why: String },
    /// Inline PGP: not checked
    NotChecked,
}

/// Why encrypted data is not shown
#[derive(Debug, Clone, PartialEq, Eq)]
pub enum Sealed {
    /// None of the user's keys opens it; the key ids it is for
    NoKey(Vec<String>),
    /// Changed on the way: its integrity does not check
    Changed,
    /// The old format without integrity protection
    Unprotected,
    /// Not readable
    Broken,
}

/// The protection of one section
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct Verdict {
    pub encrypted: bool,
    pub signature: Signature,
    /// Encrypted data that could not be opened: the section has nothing to show but this
    pub sealed: Option<Sealed>,
}

impl Verdict {
    fn unsigned(encrypted: bool) -> Verdict {
        Verdict {
            encrypted,
            signature: Signature::None,
            sealed: None,
        }
    }

    pub fn tone(&self) -> Tone {
        if self.sealed.is_some() {
            return Tone::Warning;
        }
        match &self.signature {
            Signature::Verified { .. } => Tone::Verified,
            Signature::Signed { .. } => Tone::Good,
            Signature::OtherPerson { .. } | Signature::Bad { .. } => Tone::Warning,
            Signature::None | Signature::NotChecked if self.encrypted => Tone::Good,
            Signature::None | Signature::UnknownKey { .. } | Signature::NotChecked => Tone::Neutral,
        }
    }

    /// The label of the section, in words
    pub fn label(&self) -> String {
        if let Some(sealed) = &self.sealed {
            return tr(match sealed {
                Sealed::NoKey(_) => Text::PgpPartNoKey,
                Sealed::Changed => Text::PgpPartChanged,
                Sealed::Unprotected => Text::PgpPartUnprotected,
                Sealed::Broken => Text::PgpPartBroken,
            });
        }
        let signature = match &self.signature {
            Signature::None => tr(Text::PgpPartNotSigned),
            Signature::Verified { signer, .. } => tr_args(Text::PgpPartVerified, &[("signer", signer.into())]),
            Signature::Signed { signer, .. } => tr_args(Text::PgpPartSigned, &[("signer", signer.into())]),
            Signature::OtherPerson { signer, .. } => tr_args(Text::PgpPartOther, &[("signer", signer.into())]),
            Signature::UnknownKey { .. } => tr(Text::PgpPartUnknownKey),
            Signature::Bad { why } => why.clone(),
            Signature::NotChecked => tr(Text::PgpPartNotChecked),
        };
        if self.encrypted {
            tr_args(Text::PgpPartEncrypted, &[("signature", (&signature).into())])
        } else {
            signature
        }
    }
}

/// A part of the message as it is shown: a MIME entity of its own (None when there is nothing to show of it), and
/// its protection (None for an unprotected part of a message that has protected ones)
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct Section {
    pub entity: Option<Vec<u8>>,
    pub verdict: Option<Verdict>,
}

/// A message with protection somewhere in it
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct Protected {
    /// What the whole message is (its envelope); None when no layer starts at its top
    pub envelope: Option<Verdict>,
    pub sections: Vec<Section>,
    /// The Subject inside the protection (RFC 9788, or protected-headers="v1"), when the envelope is good
    pub subject: Option<String>,
}

/// Whether a message may be protected at all: the cheap look before the real one
pub(crate) fn may_be_protected(raw: &[u8]) -> bool {
    let needle = |n: &[u8]| raw.windows(n.len()).any(|w| w.eq_ignore_ascii_case(n));
    needle(b"application/pgp-") || needle(b"-----BEGIN PGP ")
}

fn is_signed(part: &pe_mime::outline::Part) -> bool {
    part.content_type == "multipart/signed"
        && part
            .param("protocol")
            .is_some_and(|p| p.eq_ignore_ascii_case("application/pgp-signature"))
        && part.children.len() >= 2
}

fn is_encrypted(part: &pe_mime::outline::Part) -> bool {
    part.content_type == "multipart/encrypted"
        && part
            .param("protocol")
            .is_some_and(|p| p.eq_ignore_ascii_case("application/pgp-encrypted"))
        && part.children.len() >= 2
}

/// How deep layers may nest (an encrypted part holding a signed part holding...)
const MAX_LAYERS: usize = 4;

/// Reads a message: None when it has no protection anywhere (it is shown as any message is)
pub fn read(raw: &[u8], ring: &KeyRing, from: &[String], now: i64) -> Option<Protected> {
    if !may_be_protected(raw) {
        return None;
    }
    let reader = Reader { ring, from, now };
    // the envelope: the layers from the top
    let (envelope, payload) = reader.unwrap_layers(raw.to_vec(), 0);
    let mut sections = Vec::new();
    match &payload {
        Some(payload) => reader.sections(payload, envelope.as_ref(), 0, &mut sections),
        None => sections.push(Section {
            entity: None,
            verdict: envelope.clone(),
        }),
    }
    // armor that is only a key, or a layer type this does not read, is no protection; a layer anywhere (even one
    // that is not shown) frames every part, so a frame a sender paints is never alone
    if envelope.is_none() && sections.iter().all(|section| section.verdict.is_none()) && !has_layer(raw) {
        return None;
    }
    let subject = match (&envelope, &payload) {
        (Some(verdict), Some(payload)) if envelope_good(verdict) => inner_subject(payload),
        _ => None,
    };
    Some(Protected {
        envelope,
        sections: merge_plain(sections),
        subject,
    })
}

/// Whether a signed or encrypted layer is anywhere in the message
fn has_layer(raw: &[u8]) -> bool {
    outline(raw)
        .parts
        .iter()
        .any(|part| is_signed(part) || is_encrypted(part))
}

/// The message as it is shown: its own header fields (the protected Subject in place of the outer one) over the
/// sections that have something to show, joined. What replies quote, forwards carry and attachments are saved from,
/// so nothing that was not shown (a part not decrypted, a hidden one) ever is. None for a message without
/// protection.
pub(crate) fn shown(raw: &[u8], ring: &KeyRing, from: &[String], now: i64) -> Option<Vec<u8>> {
    let protected = read(raw, ring, from, now)?;
    let entities: Vec<&[u8]> = protected
        .sections
        .iter()
        .filter_map(|section| section.entity.as_deref())
        .collect();
    let body = mixed(&entities);
    let outline = outline(raw);
    let root = outline.root()?;
    let mut out = Vec::new();
    for line in header_lines(&raw[..root.body]) {
        let name = line.split(|&b| b == b':').next().unwrap_or_default();
        let name = String::from_utf8_lossy(name).trim().to_ascii_lowercase();
        if matches!(
            name.as_str(),
            "content-type" | "content-transfer-encoding" | "mime-version"
        ) {
            continue;
        }
        if name == "subject"
            && let Some(subject) = &protected.subject
        {
            out.extend_from_slice(format!("Subject: {}\r\n", subject.replace(['\r', '\n'], " ")).as_bytes());
            continue;
        }
        out.extend_from_slice(line);
    }
    out.extend_from_slice(b"MIME-Version: 1.0\r\n");
    out.extend_from_slice(&body);
    Some(out)
}

/// The header fields of a header block, each with its folded lines and its line break
fn header_lines(block: &[u8]) -> Vec<&[u8]> {
    let mut fields: Vec<&[u8]> = Vec::new();
    let mut start = 0;
    let mut at = 0;
    while at < block.len() {
        let end = block[at..]
            .iter()
            .position(|&b| b == b'\n')
            .map_or(block.len(), |i| at + i + 1);
        let line = &block[at..end];
        if line.trim_ascii().is_empty() {
            break;
        }
        // a line that starts with white space continues the field before it
        if at > start && !line.starts_with(b" ") && !line.starts_with(b"\t") {
            fields.push(&block[start..at]);
            start = at;
        }
        at = end;
    }
    if at > start {
        fields.push(&block[start..at]);
    }
    fields
}

fn envelope_good(verdict: &Verdict) -> bool {
    verdict.sealed.is_none()
        && (verdict.encrypted || matches!(verdict.signature, Signature::Verified { .. } | Signature::Signed { .. }))
}

/// The protected Subject of a payload: in its own header block, when the payload says its headers are protected
fn inner_subject(payload: &[u8]) -> Option<String> {
    let outline = outline(payload);
    let root = outline.root()?;
    let protected = root.param("protected-headers").is_some() || root.param("hp").is_some();
    if !protected {
        return None;
    }
    let headers = pe_mime::parser::parse(&payload[..root.body]).ok()?;
    headers.subject.filter(|subject| !subject.trim().is_empty())
}

struct Reader<'a> {
    ring: &'a KeyRing,
    from: &'a [String],
    now: i64,
}

impl Reader<'_> {
    /// The layers at the top of `entity`: what they are, and the entity inside them (None when nothing could be
    /// opened). No layer: (None, the entity).
    fn unwrap_layers(&self, entity: Vec<u8>, depth: usize) -> (Option<Verdict>, Option<Vec<u8>>) {
        if depth >= MAX_LAYERS {
            return (None, Some(entity));
        }
        let outline = outline(&entity);
        let Some(root) = outline.root() else {
            return (None, Some(entity));
        };
        if is_encrypted(root) {
            let ciphertext = transfer_decoded(&outline, &entity, root.children[1]);
            let opened = pe_pgp::decrypt(&ciphertext, &self.ring.keys, &self.ring.certs, self.now);
            return match opened {
                Err(error) => {
                    let mut verdict = Verdict::unsigned(true);
                    verdict.sealed = Some(sealed(error));
                    (Some(verdict), None)
                }
                Ok(opened) => {
                    let mut verdict = Verdict::unsigned(true);
                    verdict.signature = self.signature(&opened.signatures);
                    // a signed layer inside the encryption (RFC 3156 6.1)
                    let (inner, payload) = self.unwrap_layers(opened.data, depth + 1);
                    if let Some(inner) = inner {
                        if verdict.signature == Signature::None {
                            verdict.signature = inner.signature;
                        }
                        verdict.sealed = inner.sealed;
                    }
                    (Some(verdict), payload)
                }
            };
        }
        if is_signed(root) {
            let (content, signature) = (root.children[0], root.children[1]);
            let signed = canonical(outline.bytes(&entity, content));
            let signature_bytes = transfer_decoded(&outline, &entity, signature);
            let checks = pe_pgp::verify_detached(&signature_bytes, &signed, &self.ring.certs, self.now);
            let verdict = Verdict {
                encrypted: false,
                signature: match checks {
                    Ok(checks) => self.signature(&checks),
                    Err(_) => Signature::Bad {
                        why: tr(Text::PgpWhyMismatch),
                    },
                },
                sealed: None,
            };
            return (Some(verdict), Some(outline.bytes(&entity, content).to_vec()));
        }
        (None, Some(entity))
    }

    /// The sections of `entity` (a payload, or a whole message without an envelope), each protected subtree one,
    /// `inherited` the protection of the envelope around them
    fn sections(&self, entity: &[u8], inherited: Option<&Verdict>, depth: usize, out: &mut Vec<Section>) {
        let outline = outline(entity);
        let has_layer = outline
            .parts
            .iter()
            .skip(1)
            .any(|part| is_signed(part) || is_encrypted(part));
        let has_armor =
            inline_texts(&outline).any(|index| !pe_pgp::inline::blocks(&text_of(&outline, entity, index)).is_empty());
        if depth >= MAX_LAYERS || (!has_layer && !has_armor) {
            out.push(Section {
                entity: Some(entity.to_vec()),
                verdict: inherited.cloned(),
            });
            return;
        }
        self.walk(&outline, entity, 0, inherited, depth, out);
    }

    fn walk(
        &self,
        outline: &Outline,
        entity: &[u8],
        index: usize,
        inherited: Option<&Verdict>,
        depth: usize,
        out: &mut Vec<Section>,
    ) {
        let part = &outline.parts[index];
        if is_signed(part) || is_encrypted(part) {
            // an errant layer: its part is a section with its own verdict, combined with the envelope's
            let (verdict, payload) = self.unwrap_layers(outline.bytes(entity, index).to_vec(), 0);
            let verdict = verdict.map(|own| combine(inherited, own));
            match payload {
                Some(payload) => self.sections(&payload, verdict.as_ref(), depth + 1, out),
                None => out.push(Section { entity: None, verdict }),
            }
            return;
        }
        let splits = matches!(part.content_type.as_str(), "multipart/mixed" | "multipart/related")
            || (part.is_multipart() && part.content_type != "multipart/alternative");
        if splits && !part.children.is_empty() {
            for &child in &part.children {
                self.walk(outline, entity, child, inherited, depth, out);
            }
            return;
        }
        if part.content_type == "text/plain" && part.disposition != "attachment" {
            let text = text_of(outline, entity, index);
            if !pe_pgp::inline::blocks(&text).is_empty() {
                self.inline(&text, inherited, out);
                return;
            }
        }
        out.push(Section {
            entity: Some(outline.bytes(entity, index).to_vec()),
            verdict: inherited.cloned(),
        });
    }

    /// Text with inline PGP blocks: the text between them as it is, each encrypted or signed block a section
    fn inline(&self, text: &str, inherited: Option<&Verdict>, out: &mut Vec<Section>) {
        let mut at = 0;
        for block in pe_pgp::inline::blocks(text) {
            plain_text(&text[at..block.start], inherited, out);
            at = block.end;
            let armored = &text[block.start..block.end];
            match block.kind {
                pe_pgp::inline::Kind::Message => {
                    let opened = pe_pgp::decrypt(armored.as_bytes(), &self.ring.keys, &self.ring.certs, self.now);
                    let section = match opened {
                        Ok(opened) => Section {
                            entity: Some(text_entity(&String::from_utf8_lossy(&opened.data))),
                            verdict: Some(combine(
                                inherited,
                                Verdict {
                                    encrypted: opened.encrypted,
                                    signature: Signature::NotChecked,
                                    sealed: None,
                                },
                            )),
                        },
                        Err(error) => Section {
                            entity: None,
                            verdict: Some(Verdict {
                                encrypted: true,
                                signature: Signature::None,
                                sealed: Some(sealed(error)),
                            }),
                        },
                    };
                    out.push(section);
                }
                pe_pgp::inline::Kind::Signed => {
                    let shown = pe_pgp::inline::cleartext(armored).unwrap_or_else(|| armored.to_string());
                    out.push(Section {
                        entity: Some(text_entity(&shown)),
                        verdict: Some(combine(
                            inherited,
                            Verdict {
                                encrypted: false,
                                signature: Signature::NotChecked,
                                sealed: None,
                            },
                        )),
                    });
                }
                // keys and loose signatures stay text
                _ => plain_text(armored, inherited, out),
            }
        }
        plain_text(&text[at..], inherited, out);
    }

    /// What the checks of a part's signatures make of it: the best one counts
    fn signature(&self, checks: &[SigCheck]) -> Signature {
        let mut best = Signature::None;
        for check in checks {
            let candidate = self.one_signature(check);
            if rank(&candidate) > rank(&best) {
                best = candidate;
            }
        }
        best
    }

    fn one_signature(&self, check: &SigCheck) -> Signature {
        let at = check.created.unwrap_or(0);
        match &check.status {
            SigStatus::UnknownKey => Signature::UnknownKey {
                key: check.issuers.first().cloned().unwrap_or_default(),
            },
            SigStatus::Bad(problem) => Signature::Bad { why: why(problem) },
            SigStatus::Good => {
                let Some(cert) = check
                    .cert
                    .as_ref()
                    .and_then(|f| self.ring.certs.iter().find(|c| c.fingerprint() == *f))
                else {
                    return Signature::UnknownKey {
                        key: check.issuers.first().cloned().unwrap_or_default(),
                    };
                };
                let addresses = cert.addresses(at.max(cert.created()));
                // the From rule: one From, and the key holds its address
                let sender = match self.from {
                    [one] => Some(one.trim().to_lowercase()),
                    _ => None,
                };
                let name = signer_name(cert, sender.as_deref(), at);
                match sender {
                    Some(sender) if addresses.contains(&sender) => {
                        if self.ring.verified.contains(&(cert.fingerprint(), sender)) {
                            Signature::Verified { signer: name, at }
                        } else {
                            Signature::Signed { signer: name, at }
                        }
                    }
                    _ => Signature::OtherPerson { signer: name, at },
                }
            }
        }
    }
}

/// The order signatures are preferred in when a part has several
fn rank(signature: &Signature) -> u8 {
    match signature {
        Signature::Verified { .. } => 6,
        Signature::Signed { .. } => 5,
        Signature::OtherPerson { .. } => 4,
        Signature::Bad { .. } => 3,
        Signature::UnknownKey { .. } => 2,
        Signature::NotChecked => 1,
        Signature::None => 0,
    }
}

/// The name a signer is shown by: the user id with the sender's address, else the first one
fn signer_name(cert: &Cert, sender: Option<&str>, at: i64) -> String {
    let users = cert.user_ids(at.max(cert.created()));
    let user = users
        .iter()
        .find(|user| user.address.as_deref() == sender && sender.is_some())
        .or(users.first());
    user.map(|user| user.text.clone())
        .unwrap_or_else(|| pe_pgp::grouped(&cert.fingerprint()))
}

/// An errant layer inside an envelope: encrypted if either is, and its own signature if it has one, else the
/// envelope's
fn combine(inherited: Option<&Verdict>, own: Verdict) -> Verdict {
    let Some(outer) = inherited else { return own };
    Verdict {
        encrypted: outer.encrypted || own.encrypted,
        signature: if own.signature == Signature::None {
            outer.signature.clone()
        } else {
            own.signature
        },
        sealed: own.sealed,
    }
}

fn sealed(error: DecryptError) -> Sealed {
    match error {
        DecryptError::NoKey { recipients } => Sealed::NoKey(recipients),
        DecryptError::Integrity => Sealed::Changed,
        DecryptError::Unprotected => Sealed::Unprotected,
        DecryptError::Malformed(_) | DecryptError::TooLarge => Sealed::Broken,
    }
}

/// Why a signature does not count, in words
fn why(problem: &Problem) -> String {
    match problem {
        Problem::Mismatch => tr(Text::PgpWhyMismatch),
        Problem::WeakHash(hash) => tr_args(Text::PgpWhyWeakHash, &[("hash", hash.into())]),
        Problem::KeyExpired { at } => tr_args(
            Text::PgpWhyKeyExpired,
            &[("date", (&crate::calendar::local_date(*at)).into())],
        ),
        Problem::KeyRevoked { .. } => tr(Text::PgpWhyKeyRevoked),
        Problem::NotSigningKey => tr(Text::PgpWhyNotSigningKey),
        Problem::FromFuture => tr(Text::PgpWhyFromFuture),
        Problem::SignatureExpired => tr(Text::PgpWhySignatureExpired),
        Problem::WrongType | Problem::KeyNotValid => tr(Text::PgpWhyKeyNotValid),
        Problem::NotForYou => tr(Text::PgpWhyNotForYou),
    }
}

/// Signed text as it was signed: every line break CRLF (RFC 3156 section 5); stored mail may have bare LFs
fn canonical(bytes: &[u8]) -> Vec<u8> {
    let mut out = Vec::with_capacity(bytes.len() + bytes.len() / 40);
    for (index, &byte) in bytes.iter().enumerate() {
        if byte == b'\n' && (index == 0 || bytes[index - 1] != b'\r') {
            out.push(b'\r');
        }
        out.push(byte);
    }
    out
}

/// A part's body with its Content-Transfer-Encoding undone (armored OpenPGP data is 7bit, but a few clients base64
/// or quoted-printable it)
fn transfer_decoded(outline: &Outline, raw: &[u8], index: usize) -> Vec<u8> {
    let body = outline.body(raw, index);
    match outline.parts[index].transfer_encoding.as_str() {
        // the parser undoes the encoding of a part read alone, as it would of the part in its message
        "base64" | "quoted-printable" => pe_mime::parser::parse(outline.bytes(raw, index))
            .ok()
            .and_then(|part| match part.attachments.into_iter().next() {
                Some(attachment) => Some(attachment.content),
                None => part.text.map(String::into_bytes),
            })
            .unwrap_or_default(),
        _ => body.to_vec(),
    }
}

/// The text/plain parts that may hold inline PGP
fn inline_texts(outline: &Outline) -> impl Iterator<Item = usize> + '_ {
    outline
        .parts
        .iter()
        .enumerate()
        .filter(|(_, part)| part.content_type == "text/plain" && part.disposition != "attachment")
        .map(|(index, _)| index)
}

/// A text/plain part's text, decoded
fn text_of(outline: &Outline, raw: &[u8], index: usize) -> String {
    pe_mime::parser::parse(outline.bytes(raw, index))
        .ok()
        .and_then(|message| message.text)
        .unwrap_or_default()
}

/// A MIME entity of plain text, UTF-8, quoted-printable so that any line length passes
fn text_entity(text: &str) -> Vec<u8> {
    let mut out = b"Content-Type: text/plain; charset=utf-8\r\nContent-Transfer-Encoding: base64\r\n\r\n".to_vec();
    let encoded = base64::Engine::encode(&base64::engine::general_purpose::STANDARD, text.as_bytes());
    for line in encoded.as_bytes().chunks(76) {
        out.extend_from_slice(line);
        out.extend_from_slice(b"\r\n");
    }
    out
}

fn plain_text(text: &str, inherited: Option<&Verdict>, out: &mut Vec<Section>) {
    if !text.trim().is_empty() {
        out.push(Section {
            entity: Some(text_entity(text)),
            verdict: inherited.cloned(),
        });
    }
}

/// Neighbouring sections of the same protection made one: a run of unprotected parts is one section, as is a run of
/// parts under one envelope
fn merge_plain(sections: Vec<Section>) -> Vec<Section> {
    let mut out: Vec<Section> = Vec::new();
    for section in sections {
        if let Some(last) = out.last_mut()
            && last.verdict == section.verdict
            && let (Some(a), Some(b)) = (&last.entity, &section.entity)
        {
            last.entity = Some(mixed(&[a.as_slice(), b.as_slice()]));
            continue;
        }
        out.push(section);
    }
    out
}

/// Entities joined into one multipart/mixed, with a boundary none of them holds
fn mixed(entities: &[&[u8]]) -> Vec<u8> {
    let mut boundary = String::from("pe-section");
    let mut n = 0u32;
    while entities
        .iter()
        .any(|e| e.windows(boundary.len()).any(|w| w == boundary.as_bytes()))
    {
        n += 1;
        boundary = format!("pe-section-{n}");
    }
    let mut out = format!("Content-Type: multipart/mixed; boundary=\"{boundary}\"\r\n\r\n").into_bytes();
    for entity in entities {
        // an entity that is itself a joined multipart is opened up, so the joined one stays flat
        out.extend_from_slice(format!("--{boundary}\r\n").as_bytes());
        out.extend_from_slice(entity);
        out.extend_from_slice(b"\r\n");
    }
    out.extend_from_slice(format!("--{boundary}--\r\n").as_bytes());
    out
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn canonical_line_ends() {
        assert_eq!(canonical(b"a\nb\r\nc\n"), b"a\r\nb\r\nc\r\n");
    }

    #[test]
    fn mixed_boundaries_are_not_in_the_parts() {
        let joined = mixed(&[
            b"Content-Type: text/plain\r\n\r\npe-section",
            b"Content-Type: text/plain\r\n\r\nx",
        ]);
        let outline = outline(&joined);
        assert_eq!(outline.parts.len(), 3);
        assert_eq!(outline.body(&joined, 1), b"pe-section");
    }

    #[test]
    fn plain_mail_is_not_looked_at() {
        let ring = KeyRing::default();
        assert!(read(b"Subject: hi\r\n\r\nhello\r\n", &ring, &[], 0).is_none());
        // a key in the text is no protection
        let key = b"Subject: my key\r\n\r\n-----BEGIN PGP PUBLIC KEY BLOCK-----\r\nabc\r\n-----END PGP PUBLIC KEY BLOCK-----\r\n";
        assert!(read(key, &ring, &[], 0).is_none());
    }
}
