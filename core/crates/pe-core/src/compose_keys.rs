//! Sign and Encrypt in the compose window: what the window shows of them and what its switches do. The window passes
//! the message as it is now ([`Outgoing`]) and shows what comes back: the switches, each recipient's key with its
//! colour and words, the line under the fields, what Send would refuse and why, and the questions to ask. The rules
//! are the ones sending keeps (protect_out.rs), so what the window shows is what Send does.
//!
//! - Sign and Encrypt start off for a new message; a reply to or a forward of encrypted mail starts with both on
//!   (the draft says so). Encrypt always signs: Sign shows on, and can not be turned off, while Encrypt is on.
//! - Turning either on without a key of one's own for the From address asks to make one.
//! - Turning Encrypt off for a message that answers or forwards encrypted mail asks first; while what it quotes (or the
//!   files it forwards) is still there, it can then not be sent until that is removed.
//! - With Encrypt on, the keys of recipients that have none are looked up (lookup.rs), and each recipient shows a
//!   lock: green for a verified key, blue for a key, amber for none.

use std::path::PathBuf;

use pe_i18n::{Text, tr, tr_args};
use pe_mime::parser::parse_addresses;
use pe_store::normal_address;

use crate::compose::{ComposeError, Outgoing};
use crate::keys::KeyState;
use crate::protect::Tone;
use crate::worker::unix_now;
use crate::{AccountId, Core, Result};

/// What a recipient has to encrypt to
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum RecipientKey {
    /// A key whose fingerprint the user compared: a green lock
    Verified,
    /// A key that was found or imported: a blue lock
    Found,
    /// One of the user's own addresses, whose own key it is encrypted to
    Own,
    /// Its key is being looked up: grey
    Looking,
    /// No key: amber
    Missing,
    /// A key that can not encrypt now (expired, revoked): amber
    Unusable,
}

impl RecipientKey {
    /// Whether it can be encrypted to now
    pub fn usable(self) -> bool {
        matches!(self, RecipientKey::Verified | RecipientKey::Found | RecipientKey::Own)
    }

    /// The colour of its lock
    pub fn tone(self) -> Tone {
        match self {
            RecipientKey::Verified => Tone::Verified,
            RecipientKey::Found | RecipientKey::Own => Tone::Good,
            RecipientKey::Looking => Tone::Neutral,
            RecipientKey::Missing | RecipientKey::Unusable => Tone::Warning,
        }
    }
}

/// The field a recipient is in
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum RecipientField {
    To,
    Cc,
    Bcc,
}

/// A recipient of the message and their key, as the compose window and Recipients' Keys show them
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct Recipient {
    /// In lower case, as keys are kept
    pub address: String,
    /// The name typed with it, else the address: what the Keys line shows
    pub label: String,
    pub field: RecipientField,
    pub key: RecipientKey,
    /// It can be encrypted to now ([`RecipientKey::usable`])
    pub has_key: bool,
    pub tone: Tone,
    /// The key in words: "Key verified", "No key: none was found on 3 May 2027"
    pub text: String,
    /// "A different key for bob@example.net was found on 3 May 2027.", when one waits for the user's decision
    /// (Use the New Key or Keep the Current One, as in the contact)
    pub pending: Option<String>,
    /// Find Key applies: no usable key, not being looked up, not asked in the last minute
    pub can_find: bool,
}

/// What Send would refuse now
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum Block {
    None,
    /// Sign or Encrypt is on, and the From address has no key of its own that can be used
    NoOwnKey,
    /// Encrypt is on, and recipients have no key (or theirs is still being looked up): Recipients' Keys
    MissingKeys,
    /// Encrypt is off, and the message still quotes or forwards encrypted mail
    EncryptedQuote,
}

/// Everything the compose window shows of signing and encrypting
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct ComposeSecurity {
    /// Sign as it shows: on when the user turned it on, and always while Encrypt is on
    pub sign: bool,
    /// Sign can be clicked: not while Encrypt is on, which always signs
    pub sign_enabled: bool,
    pub encrypt: bool,
    /// The From address has a key of its own that can sign and be encrypted to
    pub has_own_key: bool,
    /// The colour of the line under the fields; None when there is no line
    pub tone: Option<Tone>,
    /// The line under the fields
    pub text: String,
    pub sign_tip: String,
    pub encrypt_tip: String,
    pub block: Block,
    /// Why Send would refuse, for the alert (empty with [`Block::None`])
    pub block_text: String,
    /// Each recipient once, To first, then Cc and Bcc
    pub recipients: Vec<Recipient>,
    /// How many recipients have no usable key (being looked up included)
    pub missing: usize,
    /// A lookup of recipients' keys is running
    pub looking: bool,
    /// What Recipients' Keys says at its top
    pub keys_intro: String,
    /// Recipients' Keys may offer Send Without Encryption; when not, [`ComposeSecurity::unencrypted_text`] says why
    pub can_send_unencrypted: bool,
    pub unencrypted_text: String,
    /// Send in Recipients' Keys can send encrypted: there are recipients, and every one has a key
    pub can_send: bool,
    /// Send is Recipients' Keys' default button (else Cancel): once every recipient has a key, as [`Self::can_send`]
    pub send_default: bool,
    /// The Keys line under the fields shows: Encrypt is on and the message has recipients
    pub show_keys: bool,
    /// The window looks at the text again as it is edited (the editor's `edited`): the message answers or forwards
    /// encrypted mail and goes without encryption, so taking its quote out changes what Send does
    pub watch_text: bool,
}

/// A switch of the compose window
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum Switch {
    Sign,
    Encrypt,
}

/// What the window asks before a switch changes
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum Question {
    None,
    /// No key for the From address: Yes opens New Key for the account (then the switch is tried again)
    MakeKey,
    /// The From address's key can not be used: Yes opens Encryption Keys
    ShowKeys,
    /// Encrypt off for a message that answers or forwards encrypted mail: Yes turns it off (the switch again, confirmed)
    TurnOffEncrypt,
}

/// What a click on a switch came to: the switches as they are now (the user's own Sign, apart from Encrypt), and a
/// question to ask first, which leaves them as they were
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct Toggled {
    pub sign: bool,
    pub encrypt: bool,
    pub question: Question,
    /// The question, and the words of its two buttons (with their menu letter in the catalog: each window shows them
    /// its own way); None without a question
    pub text: String,
    pub yes: Option<Text>,
    pub no: Option<Text>,
    /// A lookup of the recipients' keys started with Encrypt: `KeysFound` follows with it
    pub lookup: Option<u64>,
}

/// The mailboxes of a recipient list as typed (groups opened), each as its address in lower case and its label (the
/// name typed with it, else the address); what is no address is left out. Sending encrypts to the same ones
/// (protect_out.rs).
pub(crate) fn mailboxes_in(list: &str) -> Vec<(String, String)> {
    parse_addresses(list)
        .iter()
        .flat_map(|parsed| parsed.mailboxes())
        .filter_map(|mailbox| {
            let address = normal_address(&mailbox.address);
            let name = mailbox.name.trim();
            let label = if name.is_empty() { mailbox.address.trim() } else { name };
            address.contains('@').then(|| (address, label.to_string()))
        })
        .collect()
}

/// The recipients of `outgoing` once each, in the order of their fields
fn recipients_of(outgoing: &Outgoing) -> Vec<(String, String, RecipientField)> {
    let mut found: Vec<(String, String, RecipientField)> = Vec::new();
    for (list, field) in [
        (&outgoing.to, RecipientField::To),
        (&outgoing.cc, RecipientField::Cc),
        (&outgoing.bcc, RecipientField::Bcc),
    ] {
        for (address, label) in mailboxes_in(list) {
            if !found.iter().any(|(a, ..)| *a == address) {
                found.push((address, label, field));
            }
        }
    }
    found
}

/// The address `outgoing` goes from: the other address chosen, or the account's own
pub(crate) fn sending_address(core: &Core, account: AccountId, outgoing: &Outgoing) -> Result<String> {
    Ok(match outgoing.from.as_deref() {
        Some(other) => normal_address(other),
        None => normal_address(&core.store().account(account)?.settings.email),
    })
}

/// Whether what the message quotes still holds something: text, or a picture or other media (a scan, a screenshot,
/// carried as a data: or cid: picture), which has no text but is the content all the same. A quote unfolded and
/// emptied, or taken away, has none.
fn quote_present(outgoing: &Outgoing) -> bool {
    let Some(quote) = outgoing.quote.as_deref() else {
        return false;
    };
    let (_, _, body) = pe_html::quote_parts(quote);
    !pe_mime::parser::html_to_text(body).trim().is_empty() || holds_media(body)
}

/// Whether HTML holds content that has no text: pictures and other media, or a resource it points at
fn holds_media(html: &str) -> bool {
    const MEDIA: [&str; 12] = [
        "<img", "<picture", "<svg", "<image", "<video", "<audio", "<source", "<object", "<embed", "<canvas", "data:",
        "cid:",
    ];
    let lower = html.to_ascii_lowercase();
    MEDIA.iter().any(|m| lower.contains(m)) || lower.contains("url(")
}

/// Whether what was written still holds a quoted message: a saved draft or a message taken back opens with its quote
/// in the text, a reply's in a blockquote, a forward's under its "Original Message" line. A blockquote of the user's
/// own counts too: it is never let out in the clear by mistake.
fn quoted_in_text(outgoing: &Outgoing) -> bool {
    let Some(html) = outgoing.html.as_deref() else {
        return false;
    };
    html.to_ascii_lowercase().contains("<blockquote") || html.contains(&tr(Text::QuoteOriginal))
}

/// Whether a file was written out of a message for the compose window (a forward's, a reopened draft's, a message
/// taken back), rather than chosen by the user: under the core's own folder, by those names (attachments_out)
fn written_out(path: &std::path::Path) -> bool {
    let base = crate::private_root().join("InboxClassic");
    let Ok(rest) = path.strip_prefix(&base) else {
        return false;
    };
    rest.components().next().is_some_and(|first| {
        let name = first.as_os_str().to_string_lossy();
        crate::WRITTEN_OUT.iter().any(|kind| name.starts_with(kind))
    })
}

/// What of an encrypted message `outgoing` still carries, as the reason it can only go encrypted: its quote, else
/// files written out of it; None for a message that answers or forwards no encrypted mail, or no longer carries any
pub(crate) fn encrypted_content(outgoing: &Outgoing) -> Option<ComposeError> {
    if !outgoing.quote_encrypted {
        return None;
    }
    if quote_present(outgoing) || quoted_in_text(outgoing) {
        return Some(ComposeError::EncryptedQuote);
    }
    outgoing
        .attachments
        .iter()
        .any(|path| written_out(path))
        .then_some(ComposeError::EncryptedFiles)
}

/// The recipient lists of `outgoing` without `address`, for Remove from Message: (To, Cc, Bcc), each left as typed
/// when the address is not in it
pub fn without_recipient(outgoing: &Outgoing, address: &str) -> (String, String, String) {
    let address = normal_address(address);
    let rewrite = |list: &str| -> String {
        let parsed = parse_addresses(list);
        let mailboxes: Vec<_> = parsed.iter().flat_map(|a| a.mailboxes()).collect();
        if !mailboxes.iter().any(|m| normal_address(&m.address) == address) {
            return list.to_string();
        }
        mailboxes
            .iter()
            .filter(|m| normal_address(&m.address) != address)
            .map(|m| crate::compose::address_label(&m.name, m.address.trim()))
            .collect::<Vec<_>>()
            .join(", ")
    };
    (rewrite(&outgoing.to), rewrite(&outgoing.cc), rewrite(&outgoing.bcc))
}

impl Toggled {
    /// The switches left as they were, and a question to ask first with its two buttons
    fn ask(self, question: Question, text: String, yes: Text, no: Text) -> Toggled {
        Toggled {
            question,
            text,
            yes: Some(yes),
            no: Some(no),
            ..self
        }
    }
}

impl ComposeSecurity {
    /// The line under the fields and its colour, None for no line
    fn line(&self, quote_encrypted: bool) -> Option<(Tone, String)> {
        let list =
            |of: &mut dyn Iterator<Item = &Recipient>| of.map(|r| r.label.as_str()).collect::<Vec<_>>().join(", ");
        let (tone, text) = match self.block {
            Block::EncryptedQuote | Block::NoOwnKey => (Tone::Warning, self.block_text.clone()),
            Block::MissingKeys if self.looking => {
                let asked = list(&mut self.recipients.iter().filter(|r| r.key == RecipientKey::Looking));
                (
                    Tone::Neutral,
                    tr_args(Text::PgpComposeLooking, &[("addresses", (&asked).into())]),
                )
            }
            Block::MissingKeys => {
                let lacking = list(&mut self.recipients.iter().filter(|r| !r.has_key));
                let args = [
                    ("addresses", (&lacking).into()),
                    ("count", (self.missing as i64).into()),
                ];
                (Tone::Warning, tr_args(Text::PgpComposeMissing, &args))
            }
            Block::None if self.encrypt && self.recipients.is_empty() => (Tone::Good, tr(Text::PgpComposeEncryptReady)),
            Block::None if self.encrypt => {
                let mut others = self.recipients.iter().filter(|r| r.key != RecipientKey::Own).peekable();
                let all_verified = others.peek().is_some() && others.all(|r| r.key == RecipientKey::Verified);
                let tone = if all_verified { Tone::Verified } else { Tone::Good };
                let all = list(&mut self.recipients.iter());
                let args = [
                    ("addresses", (&all).into()),
                    ("count", (self.recipients.len() as i64).into()),
                ];
                (tone, tr_args(Text::PgpComposeEncrypted, &args))
            }
            // a message that answers encrypted mail and goes without encryption says so, signed or not: that it is no
            // longer encrypted matters more than that it is signed
            Block::None if quote_encrypted => (Tone::Warning, tr(Text::PgpComposeReplyClear)),
            Block::None if self.sign => (Tone::Good, tr(Text::PgpComposeSigned)),
            Block::None => return None,
        };
        (!text.is_empty()).then_some((tone, text))
    }
}

/// What Send would refuse now, in the order sending checks it (protect_out.rs), and why in words (empty for nothing)
fn block_of(
    encrypted: Option<&ComposeError>,
    sign: bool,
    encrypt: bool,
    has_own_key: bool,
    from: &str,
    recipients: &[Recipient],
) -> (Block, String) {
    let (block, reason) = match encrypted {
        Some(reason) if !encrypt => (Block::EncryptedQuote, reason.clone()),
        _ if sign && !has_own_key => (Block::NoOwnKey, ComposeError::NoOwnKey(from.to_string())),
        _ if encrypt && recipients.iter().any(|r| !r.has_key) => {
            let lacking = recipients
                .iter()
                .filter(|r| !r.has_key)
                .map(|r| r.address.clone())
                .collect();
            (Block::MissingKeys, ComposeError::MissingKeys(lacking))
        }
        _ => return (Block::None, String::new()),
    };
    (block, reason.to_string())
}

/// The own key of an address as sending needs it
enum OwnKey {
    Ready,
    None,
    /// It has one, which can not be used now: its state in words
    Unusable(String),
}

impl Core {
    fn own_key(&self, address: &str) -> Result<OwnKey> {
        let Some(identity) = self.store().pgp_identity(address)? else {
            return Ok(OwnKey::None);
        };
        let info = match self.pgp_key(&identity.fingerprint) {
            Ok(info) => info,
            Err(crate::Error::NotFound) => return Ok(OwnKey::None),
            Err(error) => return Err(error),
        };
        Ok(match (info.own, info.state) {
            (true, KeyState::Valid) => OwnKey::Ready,
            (false, _) => OwnKey::None,
            (true, _) => OwnKey::Unusable(info.state_text),
        })
    }

    /// The key of one recipient
    fn recipient_key(&self, address: &str, from: &str, now: i64) -> Result<(RecipientKey, String, Option<String>)> {
        let store = self.store();
        // the user's own addresses: the one it goes from is always encrypted to, the others by their own key
        if address == from || store.pgp_identity(address)?.is_some() {
            return Ok((RecipientKey::Own, tr(Text::PgpRecipientOwn), None));
        }
        let peer = store.pgp_peer(address)?.unwrap_or_default();
        let pending = peer.pending.as_ref().map(|_| {
            let date = crate::calendar::local_date(peer.pending_since.unwrap_or(now));
            tr_args(
                Text::PgpPending,
                &[("address", address.into()), ("date", (&date).into())],
            )
        });
        let lookup = store.pgp_lookup(address)?;
        drop(store);
        if self.looking_for(address) {
            return Ok((RecipientKey::Looking, tr(Text::PgpRecipientLooking), pending));
        }
        let Some(fingerprint) = peer.fingerprint else {
            let text = match lookup {
                Some((at, false)) => tr_args(
                    Text::PgpRecipientNotFound,
                    &[("date", (&crate::calendar::local_date(at)).into())],
                ),
                _ => tr(Text::PgpRecipientMissing),
            };
            return Ok((RecipientKey::Missing, text, pending));
        };
        let cert = self.pgp_cert(&fingerprint)?;
        if !cert.as_ref().is_some_and(|cert| cert.can_encrypt(now).is_ok()) {
            let state = self
                .pgp_key(&fingerprint)
                .map(|info| info.state_text)
                .unwrap_or_else(|_| tr(Text::PgpKeyNotValid));
            let text = tr_args(Text::PgpRecipientUnusable, &[("state", (&state).into())]);
            return Ok((RecipientKey::Unusable, text, pending));
        }
        let verified = self
            .store()
            .pgp_key_addresses(Some(&fingerprint))?
            .iter()
            .any(|held| held.address == address && held.verified);
        Ok(match verified {
            true => (RecipientKey::Verified, tr(Text::PgpRecipientVerified), pending),
            false => (RecipientKey::Found, tr(Text::PgpRecipientFound), pending),
        })
    }

    /// A recipient of the message as the window shows it: its key, the colour of its lock, whether Find Key applies
    fn recipient_row(
        &self,
        (address, label, field): (String, String, RecipientField),
        from: &str,
        now: i64,
    ) -> Result<Recipient> {
        let (key, text, pending) = self.recipient_key(&address, from, now)?;
        let can_find = !key.usable() && key != RecipientKey::Looking && !self.asked_lately(&address, now)?;
        Ok(Recipient {
            address,
            label,
            field,
            key,
            has_key: key.usable(),
            tone: key.tone(),
            text,
            pending,
            can_find,
        })
    }

    /// Everything the compose window shows of signing and encrypting `outgoing` from `account`
    pub fn compose_security(&self, account: AccountId, outgoing: &Outgoing) -> Result<ComposeSecurity> {
        let now = unix_now();
        let from = sending_address(self, account, outgoing)?;
        let encrypt = outgoing.encrypt;
        let sign = outgoing.sign || encrypt;
        let has_own_key = matches!(self.own_key(&from)?, OwnKey::Ready);
        let recipients = recipients_of(outgoing)
            .into_iter()
            .map(|recipient| self.recipient_row(recipient, &from, now))
            .collect::<Result<Vec<_>>>()?;
        let missing = recipients.iter().filter(|r| !r.has_key).count();
        let encrypted = encrypted_content(outgoing);
        let (block, block_text) = block_of(encrypted.as_ref(), sign, encrypt, has_own_key, &from, &recipients);
        let keys_intro = if missing > 0 {
            tr_args(Text::PgpRecipientsIntroMissing, &[("count", (missing as i64).into())])
        } else {
            tr(Text::PgpRecipientsIntro)
        };
        let can_send = missing == 0 && !recipients.is_empty();
        let mut security = ComposeSecurity {
            sign,
            sign_enabled: !encrypt,
            encrypt,
            has_own_key,
            tone: None,
            text: String::new(),
            sign_tip: tr(if encrypt {
                Text::PgpComposeSignTipEncrypted
            } else {
                Text::PgpComposeSignTip
            }),
            encrypt_tip: tr(Text::PgpComposeEncryptTip),
            block,
            block_text,
            looking: recipients.iter().any(|r| r.key == RecipientKey::Looking),
            show_keys: encrypt && !recipients.is_empty(),
            recipients,
            missing,
            keys_intro,
            can_send_unencrypted: encrypted.is_none(),
            unencrypted_text: encrypted.map(|reason| reason.to_string()).unwrap_or_default(),
            can_send,
            send_default: can_send,
            watch_text: outgoing.quote_encrypted && !encrypt,
        };
        if let Some((tone, text)) = security.line(outgoing.quote_encrypted) {
            security.tone = Some(tone);
            security.text = text;
        }
        Ok(security)
    }

    /// A click on Sign or Encrypt (`on` what it is to become), or the same once its question was answered Yes
    /// (`confirmed`). Encrypt turned on looks up the keys of recipients that have none.
    pub fn compose_toggle(
        &self,
        account: AccountId,
        outgoing: &Outgoing,
        switch: Switch,
        on: bool,
        confirmed: bool,
    ) -> Result<Toggled> {
        let toggled = Toggled {
            sign: outgoing.sign,
            encrypt: outgoing.encrypt,
            question: Question::None,
            text: String::new(),
            yes: None,
            no: None,
            lookup: None,
        };
        if on {
            let from = sending_address(self, account, outgoing)?;
            match self.own_key(&from)? {
                OwnKey::Ready => {}
                OwnKey::None => {
                    let text = tr_args(Text::PgpComposeMakeKey, &[("address", (&from).into())]);
                    return Ok(toggled.ask(Question::MakeKey, text, Text::UiComposeMakeKey, Text::UiCancel));
                }
                OwnKey::Unusable(state) => {
                    let text = tr_args(
                        Text::PgpComposeKeyUnusable,
                        &[("address", (&from).into()), ("state", (&state).into())],
                    );
                    return Ok(toggled.ask(Question::ShowKeys, text, Text::UiComposeShowKeys, Text::UiCancel));
                }
            }
        }
        Ok(match (switch, on) {
            (Switch::Sign, on) => Toggled { sign: on, ..toggled },
            (Switch::Encrypt, true) => {
                let on = Outgoing {
                    encrypt: true,
                    ..outgoing.clone()
                };
                Toggled {
                    encrypt: true,
                    lookup: self.compose_find_keys(account, &on)?,
                    ..toggled
                }
            }
            (Switch::Encrypt, false) if outgoing.quote_encrypted && outgoing.encrypt && !confirmed => {
                let text = tr(match encrypted_content(outgoing) {
                    Some(_) => Text::PgpComposeEncryptOffQuote,
                    None => Text::PgpComposeEncryptOffReply,
                });
                toggled.ask(
                    Question::TurnOffEncrypt,
                    text,
                    Text::UiComposeEncryptOff,
                    Text::UiComposeKeepEncrypted,
                )
            }
            (Switch::Encrypt, false) => Toggled {
                encrypt: false,
                ..toggled
            },
        })
    }

    /// Recipients' Keys' Send Without Encryption: Encrypt off, Sign as the user had it. Choosing it answers the Turn
    /// Off question already, so it is not asked again while the message carries nothing encrypted
    /// ([`ComposeSecurity::can_send_unencrypted`]); while it does, it is asked as [`Core::compose_toggle`] asks. Send
    /// follows when the result has no question and Encrypt off.
    pub fn compose_send_unencrypted(&self, account: AccountId, outgoing: &Outgoing) -> Result<Toggled> {
        let confirmed = encrypted_content(outgoing).is_none();
        self.compose_toggle(account, outgoing, Switch::Encrypt, false, confirmed)
    }
    /// With Encrypt on, looks up the keys of the recipients that have none (not asked in vain in the last day): after
    /// Encrypt is turned on, and when the recipients change. `KeysFound` follows with the request; None when there is
    /// nothing to ask.
    pub fn compose_find_keys(&self, account: AccountId, outgoing: &Outgoing) -> Result<Option<u64>> {
        if !outgoing.encrypt {
            return Ok(None);
        }
        let from = sending_address(self, account, outgoing)?;
        let addresses: Vec<String> = recipients_of(outgoing)
            .into_iter()
            .map(|(address, ..)| address)
            .filter(|address| *address != from && !self.looking_for(address))
            .collect();
        self.pgp_find(&addresses)
    }

    /// Recipients' Keys' Find Key: one address looked up again although it was not found today, or its key can no
    /// longer be used (not within a minute of the last time, which the key server allows once). `KeysFound` follows.
    pub fn compose_find_key(&self, address: &str) -> Result<Option<u64>> {
        let address = normal_address(address);
        if self.looking_for(&address) || self.asked_lately(&address, unix_now())? {
            return Ok(None);
        }
        self.pgp_find_again(&[address])
    }

    /// Insert > Attach My Public Key: the public key of the address the message goes from, written out as a file to
    /// attach (named as Export names it); refused when that address has no key
    pub fn compose_own_key_file(&self, account: AccountId, outgoing: &Outgoing) -> Result<PathBuf> {
        let from = sending_address(self, account, outgoing)?;
        let no_key = || crate::Error::Compose(ComposeError::NoOwnKey(from.clone()));
        let identity = self.store().pgp_identity(&from)?.ok_or_else(no_key)?;
        let armored = self.pgp_export(&identity.fingerprint).map_err(|_| no_key())?;
        let name = self.pgp_file_name(&identity.fingerprint, false)?;
        let files = crate::attachments_out("my-key", vec![(name, armored.into_bytes())])?;
        files.into_iter().next().ok_or_else(no_key)
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    fn outgoing(to: &str, cc: &str, bcc: &str) -> Outgoing {
        Outgoing {
            to: to.into(),
            cc: cc.into(),
            bcc: bcc.into(),
            ..Default::default()
        }
    }

    #[test]
    fn recipients_once_each_in_field_order() {
        let found = recipients_of(&outgoing(
            "Bob <Bob@Example.org>, carol@example.org",
            "bob@example.org, Dave <dave@example.org>",
            "not an address, eve@example.org",
        ));
        let rows: Vec<(&str, &str, RecipientField)> =
            found.iter().map(|(a, l, f)| (a.as_str(), l.as_str(), *f)).collect();
        assert_eq!(
            rows,
            [
                ("bob@example.org", "Bob", RecipientField::To),
                ("carol@example.org", "carol@example.org", RecipientField::To),
                ("dave@example.org", "Dave", RecipientField::Cc),
                ("eve@example.org", "eve@example.org", RecipientField::Bcc),
            ]
        );
    }

    #[test]
    fn mailboxes_of_a_list_with_their_labels_and_no_others() {
        assert_eq!(
            mailboxes_in("Bob <Bob@Example.org>, Team: carol@example.org;, not an address"),
            [
                ("bob@example.org".to_string(), "Bob".to_string()),
                ("carol@example.org".to_string(), "carol@example.org".to_string()),
            ]
        );
    }

    #[test]
    fn a_key_usable_and_its_lock() {
        use RecipientKey::*;
        let keys = [Verified, Found, Own, Looking, Missing, Unusable];
        let usable: Vec<bool> = keys.iter().map(|k| k.usable()).collect();
        assert_eq!(usable, [true, true, true, false, false, false]);
        let tones: Vec<Tone> = keys.iter().map(|k| k.tone()).collect();
        assert_eq!(
            tones,
            [
                Tone::Verified,
                Tone::Good,
                Tone::Good,
                Tone::Neutral,
                Tone::Warning,
                Tone::Warning
            ]
        );
    }

    #[test]
    fn a_recipient_removed_from_every_field_the_others_left_as_typed() {
        let message = outgoing(
            "Bob <bob@example.org>, carol@example.org",
            "Bob@Example.org",
            "  dave@example.org;",
        );
        let (to, cc, bcc) = without_recipient(&message, "BOB@example.org");
        assert_eq!(to, "carol@example.org");
        assert_eq!(cc, "");
        assert_eq!(bcc, "  dave@example.org;", "a list without the address is left alone");
    }

    #[test]
    fn a_quote_counts_while_it_has_text() {
        let mut message = Outgoing {
            quote_encrypted: true,
            quote: Some(pe_html::quote_html(
                &[("From", "Ann".into())],
                "<p>the plan</p>",
                &[],
                true,
            )),
            ..Default::default()
        };
        assert_eq!(encrypted_content(&message), Some(ComposeError::EncryptedQuote));
        // a quote of pictures alone (a scan, a screenshot) has no text but is the content: it counts
        for body in [
            "<p><img src=\"data:image/png;base64,iVBORw0KGgo=\"></p>",
            "<p><img src=\"cid:scan@example.org\"></p>",
            "<div style=\"background: url(data:image/png;base64,AAAA)\"></div>",
        ] {
            message.quote = Some(pe_html::quote_html(&[("From", "Ann".into())], body, &[], true));
            assert_eq!(
                encrypted_content(&message),
                Some(ComposeError::EncryptedQuote),
                "{body}"
            );
        }
        // unfolded and emptied: the header block alone is no quote
        message.quote = Some(pe_html::quote_html(&[("From", "Ann".into())], "<p> </p>", &[], true));
        assert_eq!(encrypted_content(&message), None);
        message.quote = None;
        assert_eq!(encrypted_content(&message), None);
        // a message that answers no encrypted mail never counts
        message.quote_encrypted = false;
        message.quote = Some("<p>the plan</p>".into());
        assert_eq!(encrypted_content(&message), None);
    }

    #[test]
    fn a_quote_in_the_text_of_a_reopened_draft_counts() {
        let reply = pe_html::quote_html(&[("From", "Ann".into())], "<p>the plan</p>", &[], true);
        let mut message = Outgoing {
            quote_encrypted: true,
            html: Some(format!("<p>Sure.</p>{reply}")),
            ..Default::default()
        };
        assert_eq!(encrypted_content(&message), Some(ComposeError::EncryptedQuote));
        let forward = pe_html::quote_html(&[("From", "Ann".into())], "<p>the plan</p>", &[], false);
        message.html = Some(format!("<p>See below.</p>{forward}"));
        assert_eq!(encrypted_content(&message), Some(ComposeError::EncryptedQuote));
        // deleted from the text: the user's own words may go
        message.html = Some("<p>Sure.</p>".into());
        assert_eq!(encrypted_content(&message), None);
        // a draft saved with its quote and opened again has the quote in its text
        let account = pe_store::AccountSettings {
            name: "Me".into(),
            email: "me@example.org".into(),
            ..Default::default()
        };
        let saved = Outgoing {
            to: "ann@example.org".into(),
            html: Some("<p>Sure.</p>".into()),
            quote: Some(reply),
            ..Default::default()
        };
        let built = pe_smtp::build(&crate::compose::draft_message(&account, &saved, 0).unwrap());
        let (draft, _) = crate::compose::reopen(&built.raw);
        let reopened = Outgoing {
            quote_encrypted: true,
            html: Some(draft.body),
            ..Default::default()
        };
        assert_eq!(encrypted_content(&reopened), Some(ComposeError::EncryptedQuote));
    }

    #[test]
    fn files_written_out_of_the_message_count_files_chosen_do_not() {
        let base = crate::private_root().join("InboxClassic");
        let mut message = Outgoing {
            quote_encrypted: true,
            attachments: vec![PathBuf::from("/home/me/plan.pdf"), base.join("my-key-1/0/key.asc")],
            ..Default::default()
        };
        assert_eq!(encrypted_content(&message), None);
        // a forward's, a reopened draft's and an unsent message's files each came out of the message
        for kind in crate::WRITTEN_OUT {
            message.attachments = vec![base.join(format!("{kind}3-9-123/0/plan.pdf"))];
            assert_eq!(
                encrypted_content(&message),
                Some(ComposeError::EncryptedFiles),
                "{kind}"
            );
        }
        message.quote_encrypted = false;
        assert_eq!(encrypted_content(&message), None);
    }
}
