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

use std::cell::Cell;
use std::collections::{HashMap, HashSet};

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
    /// The Address Book's name of an address a key holds: the words a label names a signer by (never the key's own
    /// free text, which anyone writes)
    pub names: HashMap<String, String>,
    /// The key in use for each address that has one (a correspondent's, an own address's): a signature by another
    /// key that holds the address (one waiting for the user's decision, one the user kept away) is not the sender's
    pub in_use: HashMap<String, String>,
}

/// How a part's colour and words read (green, blue, amber, grey): the page's own tones
pub use pe_html::PartTone as Tone;

/// What a part's signature is worth
#[derive(Debug, Clone, PartialEq, Eq)]
pub enum Signature {
    /// Not signed
    None,
    /// By the sender, the key verified by the user (`key`, its fingerprint)
    Verified { signer: String, at: i64, key: String },
    /// By the sender, the key not verified
    Signed { signer: String, at: i64, key: String },
    /// A good signature by someone who is not the sender
    OtherPerson { signer: String, at: i64, key: String },
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
    /// The fingerprint of the user's key that opened the encryption, when it was opened
    pub opened_by: Option<String>,
}

impl Verdict {
    /// Its signature was confirmed (signed by the sender's key, verified or not) and it was not left sealed
    pub(crate) fn signature_confirmed(&self) -> bool {
        self.sealed.is_none() && matches!(self.signature, Signature::Verified { .. } | Signature::Signed { .. })
    }

    /// It was encrypted and opened to be shown
    pub(crate) fn opened(&self) -> bool {
        self.encrypted && self.sealed.is_none()
    }

    /// Opened, its signature not checked here (inline blocks: their signatures are not read)
    fn not_checked(encrypted: bool) -> Verdict {
        Verdict {
            encrypted,
            signature: Signature::NotChecked,
            sealed: None,
            opened_by: None,
        }
    }

    /// Encrypted, and not shown: why
    fn sealed(why: Sealed) -> Verdict {
        Verdict {
            encrypted: true,
            signature: Signature::None,
            sealed: Some(why),
            opened_by: None,
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

    /// What Details says of it beyond its label: who signed it with which key and when, which key of the user's
    /// opened it, or for whom it was encrypted
    pub fn details(&self) -> Vec<String> {
        let mut lines = Vec::new();
        match &self.signature {
            Signature::Verified { at, key, .. }
            | Signature::Signed { at, key, .. }
            | Signature::OtherPerson { at, key, .. } => {
                lines.push(tr_args(
                    Text::PgpDetailsSigned,
                    &[
                        ("when", (&crate::calendar::local_date_time(*at)).into()),
                        ("key", (&pe_pgp::grouped(key)).into()),
                    ],
                ));
            }
            Signature::UnknownKey { key } => {
                lines.push(tr_args(
                    Text::PgpDetailsUnknownKey,
                    &[("key", (&pe_pgp::grouped(key)).into())],
                ));
            }
            _ => {}
        }
        if let Some(key) = &self.opened_by {
            lines.push(tr_args(
                Text::PgpDetailsOpened,
                &[("key", (&pe_pgp::grouped(key)).into())],
            ));
        }
        if let Some(Sealed::NoKey(keys)) = &self.sealed {
            let keys: Vec<String> = keys.iter().map(|key| pe_pgp::grouped(key)).collect();
            lines.push(tr_args(Text::PgpDetailsFor, &[("keys", (&keys.join(", ")).into())]));
        }
        lines
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
    /// The layer it came from (0 for none): only sections of one layer are ever drawn in one document, so a part
    /// someone else encrypted can not wrap another's plaintext
    pub(crate) layer: u32,
}

/// A message with protection somewhere in it
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct Protected {
    /// What the whole message is (its envelope); None when no layer starts at its top
    pub envelope: Option<Verdict>,
    pub sections: Vec<Section>,
    /// The Subject inside the protection (RFC 9788, or protected-headers="v1"), when the envelope is good
    pub subject: Option<String>,
    /// The other recipients' keys the sender gossiped inside the encryption (Autocrypt)
    pub gossip: Vec<(String, Vec<u8>)>,
}

impl Protected {
    /// Whether something of it was decrypted to be shown: its previews and what is opened from it are then kept
    /// nowhere but under the view
    pub(crate) fn decrypted(&self) -> bool {
        self.sections
            .iter()
            .any(|section| section.entity.is_some() && section.verdict.as_ref().is_some_and(|v| v.encrypted))
    }
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
    let reader = Reader {
        ring,
        from,
        now,
        layers: Cell::new(0),
    };
    // the envelope: the layers from the top
    let Unwrapped {
        verdict: envelope,
        payload,
        key,
    } = reader.unwrap_layers(raw.to_vec(), 0, None);
    let within = Within {
        verdict: envelope.as_ref(),
        layer: if envelope.is_some() { reader.new_layer() } else { 0 },
        key: key.as_deref(),
    };
    let mut sections = Vec::new();
    match &payload {
        Some(payload) => reader.sections(payload, within, 0, &mut sections),
        None => sections.push(within.section(None)),
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
    // gossip counts only inside an encryption that opened
    let gossip = match (&envelope, &payload) {
        (Some(verdict), Some(payload)) if verdict.encrypted && verdict.sealed.is_none() => {
            // the top header block only, not the ciphertext under it
            let head = outline(raw).root().map_or(raw, |root| &raw[..root.body]);
            let outer = pe_mime::parser::parse(head)
                .map(|m| crate::autocrypt::recipients(&m))
                .unwrap_or_default();
            crate::autocrypt::gossip(payload, &outer)
        }
        _ => Vec::new(),
    };
    Some(Protected {
        envelope,
        sections: merge_plain(sections),
        subject,
        gossip,
    })
}

/// Whether a message has an encrypted part: a reply to it or a forward of it may go only encrypted, and a draft
/// saved encrypted opens with Encrypt on
pub(crate) fn has_encrypted(raw: &[u8]) -> bool {
    if !may_be_protected(raw) {
        return false;
    }
    let outline = outline(raw);
    outline.parts.iter().any(is_encrypted)
        || inline_texts(&outline).any(|index| {
            pe_pgp::inline::blocks(&text_of(&outline, raw, index))
                .iter()
                .any(|block| block.kind == pe_pgp::inline::Kind::Message)
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
/// so nothing that was not shown (a part not decrypted, a hidden one) ever is; with whether a section of it was
/// decrypted (an attachment opened from it is then stored decrypted). None for a message without protection.
pub(crate) fn shown_decrypted(raw: &[u8], ring: &KeyRing, from: &[String], now: i64) -> Option<(Vec<u8>, bool)> {
    shown_of(raw, &read(raw, ring, from, now)?)
}

/// What the search index keeps of a message something of which was decrypted: the message as it is shown, and its
/// protected Subject when its layer is good (RFC 9788, or protected-headers="v1"). None when nothing was decrypted.
pub(crate) fn decrypted_for_index(raw: &[u8], protected: &Protected) -> Option<(Vec<u8>, Option<String>)> {
    match shown_of(raw, protected)? {
        (shown, true) => Some((shown, protected.subject.clone())),
        _ => None,
    }
}

/// [`shown_decrypted`] of a message already read
fn shown_of(raw: &[u8], protected: &Protected) -> Option<(Vec<u8>, bool)> {
    let decrypted = protected.decrypted();
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
    Some((out, decrypted))
}

/// The header fields of a header block, each with its folded lines and its line break
pub(crate) fn header_lines(block: &[u8]) -> Vec<&[u8]> {
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

/// The Subject in a message's own top headers, as it travelled: under a protected Subject, the placeholder
pub(crate) fn outer_subject(raw: &[u8]) -> Option<String> {
    let head = outline(raw).root().map_or(raw, |root| &raw[..root.body]);
    pe_mime::parser::parse(head).ok()?.subject
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

/// What the layers at the top of an entity were, what is inside them, and the user's key that opened them
struct Unwrapped {
    verdict: Option<Verdict>,
    /// None when nothing could be opened
    payload: Option<Vec<u8>>,
    key: Option<String>,
}

/// The layer a part is inside: its verdict (None outside any), its number, and the user's key that opened it
#[derive(Clone, Copy)]
struct Within<'a> {
    verdict: Option<&'a Verdict>,
    layer: u32,
    key: Option<&'a str>,
}

impl Within<'_> {
    fn section(&self, entity: Option<Vec<u8>>) -> Section {
        Section {
            entity,
            verdict: self.verdict.cloned(),
            layer: self.layer,
        }
    }
}

struct Reader<'a> {
    ring: &'a KeyRing,
    from: &'a [String],
    now: i64,
    /// The layers numbered so far
    layers: Cell<u32>,
}

impl Reader<'_> {
    fn new_layer(&self) -> u32 {
        self.layers.set(self.layers.get() + 1);
        self.layers.get()
    }

    /// The layers at the top of `entity`. No layer: no verdict, the entity itself. `recipient` is the user's key
    /// that opened an encryption around it: a signature made for other recipients is not for the user (a signed
    /// message forwarded inside someone else's encryption).
    fn unwrap_layers(&self, entity: Vec<u8>, depth: usize, recipient: Option<&str>) -> Unwrapped {
        let none = |payload| Unwrapped {
            verdict: None,
            payload,
            key: recipient.map(str::to_string),
        };
        if depth >= MAX_LAYERS {
            return none(Some(entity));
        }
        let outline = outline(&entity);
        let Some(root) = outline.root() else {
            return none(Some(entity));
        };
        if is_encrypted(root) {
            let ciphertext = transfer_decoded(&outline, &entity, root.children[1]);
            let opened = pe_pgp::decrypt(&ciphertext, &self.ring.keys, &self.ring.certs, self.now);
            let sealed_with = |why| Unwrapped {
                verdict: Some(Verdict::sealed(why)),
                payload: None,
                key: None,
            };
            return match opened {
                Err(error) => sealed_with(sealed(error)),
                // a "multipart/encrypted" with nothing encrypted in it is no encryption, whatever it holds
                Ok(opened) if !opened.encrypted => sealed_with(Sealed::Broken),
                Ok(opened) => {
                    let mut verdict = Verdict::not_checked(true);
                    verdict.signature = self.signature(&opened.signatures);
                    verdict.opened_by = opened.key.clone();
                    // a signed layer inside the encryption (RFC 3156 6.1), its signature judged for the key that
                    // opened this
                    let inner = self.unwrap_layers(opened.data, depth + 1, opened.key.as_deref());
                    if let Some(inner) = inner.verdict {
                        if verdict.signature == Signature::None {
                            verdict.signature = inner.signature;
                        }
                        verdict.sealed = inner.sealed;
                    }
                    Unwrapped {
                        verdict: Some(verdict),
                        payload: inner.payload,
                        key: opened.key,
                    }
                }
            };
        }
        if is_signed(root) {
            let (content, signature) = (root.children[0], root.children[1]);
            let signed = canonical(outline.bytes(&entity, content));
            let signature_bytes = transfer_decoded(&outline, &entity, signature);
            let checks = pe_pgp::verify_detached_for(&signature_bytes, &signed, &self.ring.certs, self.now, recipient);
            let verdict = Verdict {
                encrypted: false,
                signature: match checks {
                    Ok(checks) => self.signature(&checks),
                    Err(_) => Signature::Bad {
                        why: tr(Text::PgpWhyMismatch),
                    },
                },
                sealed: None,
                opened_by: None,
            };
            return Unwrapped {
                verdict: Some(verdict),
                payload: Some(outline.bytes(&entity, content).to_vec()),
                key: recipient.map(str::to_string),
            };
        }
        none(Some(entity))
    }

    /// The sections of `entity` (a payload, or a whole message without an envelope), each protected subtree one,
    /// `within` the layer around them
    fn sections(&self, entity: &[u8], within: Within<'_>, depth: usize, out: &mut Vec<Section>) {
        let outline = outline(entity);
        let has_layer = outline
            .parts
            .iter()
            .skip(1)
            .any(|part| is_signed(part) || is_encrypted(part));
        let has_armor =
            inline_texts(&outline).any(|index| !pe_pgp::inline::blocks(&text_of(&outline, entity, index)).is_empty());
        if depth >= MAX_LAYERS || (!has_layer && !has_armor) {
            out.push(within.section(Some(entity.to_vec())));
            return;
        }
        self.walk(&outline, entity, 0, within, depth, out);
    }

    fn walk(
        &self,
        outline: &Outline,
        entity: &[u8],
        index: usize,
        within: Within<'_>,
        depth: usize,
        out: &mut Vec<Section>,
    ) {
        let part = &outline.parts[index];
        if is_signed(part) || is_encrypted(part) {
            // an errant layer: a layer of its own, its verdict combined with the envelope's
            let unwrapped = self.unwrap_layers(outline.bytes(entity, index).to_vec(), 0, within.key);
            let verdict = unwrapped.verdict.map(|own| combine(within.verdict, own));
            let inner = Within {
                verdict: verdict.as_ref(),
                layer: self.new_layer(),
                key: unwrapped.key.as_deref(),
            };
            match unwrapped.payload {
                Some(payload) => self.sections(&payload, inner, depth + 1, out),
                None => out.push(inner.section(None)),
            }
            return;
        }
        if part.is_multipart() && part.content_type != "multipart/alternative" && !part.children.is_empty() {
            for &child in &part.children {
                self.walk(outline, entity, child, within, depth, out);
            }
            return;
        }
        if part.content_type == "text/plain" && part.disposition != "attachment" {
            let text = text_of(outline, entity, index);
            if !pe_pgp::inline::blocks(&text).is_empty() {
                self.inline(&text, within, out);
                return;
            }
        }
        out.push(within.section(Some(outline.bytes(entity, index).to_vec())));
    }

    /// Text with inline PGP blocks: the text between them as it is, each encrypted or signed block a section of a
    /// layer of its own
    fn inline(&self, text: &str, within: Within<'_>, out: &mut Vec<Section>) {
        let mut at = 0;
        for block in pe_pgp::inline::blocks(text) {
            plain_text(&text[at..block.start], within, out);
            at = block.end;
            let armored = &text[block.start..block.end];
            let (entity, own) = match block.kind {
                pe_pgp::inline::Kind::Message => {
                    match pe_pgp::decrypt(armored.as_bytes(), &self.ring.keys, &self.ring.certs, self.now) {
                        Ok(opened) => (
                            Some(text_entity(&String::from_utf8_lossy(&opened.data))),
                            combine(within.verdict, Verdict::not_checked(opened.encrypted)),
                        ),
                        Err(error) => (None, Verdict::sealed(sealed(error))),
                    }
                }
                pe_pgp::inline::Kind::Signed => {
                    let shown = pe_pgp::inline::cleartext(armored).unwrap_or_else(|| armored.to_string());
                    (
                        Some(text_entity(&shown)),
                        combine(within.verdict, Verdict::not_checked(false)),
                    )
                }
                // keys and loose signatures stay text
                _ => {
                    plain_text(armored, within, out);
                    continue;
                }
            };
            out.push(Section {
                entity,
                verdict: Some(own),
                layer: self.new_layer(),
            });
        }
        plain_text(&text[at..], within, out);
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
                let key = cert.fingerprint();
                // the From rule: one From, and the key holds its address
                let sender = match self.from {
                    [one] => Some(one.trim().to_lowercase()),
                    _ => None,
                };
                let signer = signer_name(self.ring, &addresses, &key, sender.as_deref());
                match sender {
                    Some(sender)
                        if addresses.contains(&sender)
                            && self.ring.in_use.get(&sender).is_some_and(|in_use| *in_use != key) =>
                    {
                        Signature::Bad {
                            why: tr_args(Text::PgpWhyNotKeyInUse, &[("address", (&sender).into())]),
                        }
                    }
                    Some(sender) if addresses.contains(&sender) => {
                        if self.ring.verified.contains(&(key.clone(), sender)) {
                            Signature::Verified { signer, at, key }
                        } else {
                            Signature::Signed { signer, at, key }
                        }
                    }
                    _ => Signature::OtherPerson { signer, at, key },
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

/// The name a signer is shown by: the Address Book's name of the address checked (the sender's, or the key's first
/// address for someone else), else that address; never the key's own free text, which anyone writes ("Alice (key
/// verified)" gains nothing)
fn signer_name(ring: &KeyRing, addresses: &[String], fingerprint: &str, sender: Option<&str>) -> String {
    let address = sender
        .filter(|sender| addresses.iter().any(|address| address == sender))
        .map(str::to_string)
        .or_else(|| addresses.first().cloned());
    match address {
        Some(address) => ring.names.get(&address).cloned().unwrap_or(address),
        None => pe_pgp::grouped(fingerprint),
    }
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
        opened_by: own.opened_by.or_else(|| outer.opened_by.clone()),
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

/// A MIME entity of plain text, UTF-8, base64 so that any line length passes
fn text_entity(text: &str) -> Vec<u8> {
    let mut out = b"Content-Type: text/plain; charset=utf-8\r\nContent-Transfer-Encoding: base64\r\n\r\n".to_vec();
    let encoded = base64::Engine::encode(&base64::engine::general_purpose::STANDARD, text.as_bytes());
    for line in encoded.as_bytes().chunks(76) {
        out.extend_from_slice(line);
        out.extend_from_slice(b"\r\n");
    }
    out
}

fn plain_text(text: &str, within: Within<'_>, out: &mut Vec<Section>) {
    if !text.trim().is_empty() {
        out.push(within.section(Some(text_entity(text))));
    }
}

/// Neighbouring sections of one layer, with one verdict, made one document: the parts under one envelope, a run of
/// unprotected parts. Sections of different layers are never joined, even with equal verdicts: anyone can encrypt a
/// part to the user, and one drawn with another's plaintext could carry it away (EFAIL).
fn merge_plain(sections: Vec<Section>) -> Vec<Section> {
    let mut out: Vec<Section> = Vec::new();
    let mut run: Vec<Section> = Vec::new();
    for section in sections {
        let joins = section.entity.is_some()
            && run
                .last()
                .is_some_and(|last| last.layer == section.layer && last.verdict == section.verdict);
        if !joins {
            flush(&mut run, &mut out);
        }
        if section.entity.is_some() {
            run.push(section);
        } else {
            out.push(section);
        }
    }
    flush(&mut run, &mut out);
    out
}

/// A run of sections to join, one entity for all of them
fn flush(run: &mut Vec<Section>, out: &mut Vec<Section>) {
    if run.len() < 2 {
        out.append(run);
        return;
    }
    let entities: Vec<&[u8]> = run.iter().filter_map(|section| section.entity.as_deref()).collect();
    let entity = mixed(&entities);
    let first = run.swap_remove(0);
    run.clear();
    out.push(Section {
        entity: Some(entity),
        ..first
    });
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
