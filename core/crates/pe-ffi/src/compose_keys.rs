//! Sign and Encrypt of the compose window through C: what the window shows of them (the switches, each recipient's key,
//! the line under the fields, what Send would refuse), a click on a switch with the question to ask first, the lookups
//! Encrypt starts, Recipients' Keys' Find Key and Remove from Message, and Attach My Public Key. The decisions and the
//! words are the core's (pe-core `compose_keys.rs`); the windows show them.

use std::ffi::c_char;
use std::ptr::null_mut;

use pe_core::compose_keys::{Block, ComposeSecurity, Question, RecipientField, RecipientKey, Switch, Toggled};

use crate::core::{
    PeCore, PeOutgoing, PeProtectionTone, Rows, Strings, arg, handed, outgoing, refused, take_back, with,
};
use crate::into_c_string;

/// What a recipient has to encrypt to
#[repr(C)]
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum PeRecipientKey {
    /// A key the user verified: a green lock
    Verified = 0,
    /// A key found or imported: a blue lock
    Found = 1,
    /// One of the user's own addresses: their own key
    Own = 2,
    /// Being looked up: grey
    Looking = 3,
    /// No key: amber
    Missing = 4,
    /// A key that can not encrypt now (expired, revoked): amber
    Unusable = 5,
}

/// The field a recipient is in
#[repr(C)]
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum PeRecipientField {
    To = 0,
    Cc = 1,
    Bcc = 2,
}

/// What Send would refuse now
#[repr(C)]
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum PeComposeBlock {
    None = 0,
    /// Sign or Encrypt, and no key of one's own for the From address: ask as `pe_compose_toggle` does
    NoOwnKey = 1,
    /// Encrypt, and recipients without a key (or being looked up): open Recipients' Keys instead of sending
    MissingKeys = 2,
    /// Encrypt off, and the message still quotes or forwards encrypted mail: say `block_text`
    EncryptedQuote = 3,
}

/// A recipient and their key, a row of the Keys line and of Recipients' Keys
#[repr(C)]
pub struct PeComposeRecipient {
    /// In lower case: for `pe_compose_find_key`, `pe_compose_without_recipient` and `pe_pgp_decide`
    pub address: *const c_char,
    /// The name typed with it, else the address: what the Keys line shows
    pub label: *const c_char,
    pub field: PeRecipientField,
    pub key: PeRecipientKey,
    /// It can be encrypted to now (verified, found or one's own key)
    pub has_key: bool,
    /// The colour of its lock: green, blue, amber or grey
    pub tone: PeProtectionTone,
    /// The key in words: "Key verified", "No key: none was found on 3 May 2027"
    pub text: *const c_char,
    /// "A different key for bob@example.net was found on 3 May 2027.", NULL when none waits: Use the New Key and
    /// Keep the Current One (`pe_pgp_decide`) beside it
    pub pending: *const c_char,
    /// Find Key applies now
    pub can_find: bool,
}

/// Everything the compose window shows of signing and encrypting
#[repr(C)]
pub struct PeComposeSecurityInfo {
    /// Sign as it shows (checked): the user's own, and always while Encrypt is on
    pub sign: bool,
    /// Sign can be clicked: not while Encrypt is on, which always signs
    pub sign_enabled: bool,
    pub encrypt: bool,
    /// The From address has a key of its own (Attach My Public Key applies)
    pub has_own_key: bool,
    /// The colour of the line under the fields; NONE: no line
    pub tone: PeProtectionTone,
    /// The line under the fields, empty for none
    pub text: *const c_char,
    /// The switches' tooltips
    pub sign_tip: *const c_char,
    pub encrypt_tip: *const c_char,
    /// What Send would refuse, and why (for the alert)
    pub block: PeComposeBlock,
    pub block_text: *const c_char,
    /// How many recipients have no usable key (being looked up included)
    pub missing: usize,
    /// A lookup of their keys runs: `KeysFound` follows
    pub looking: bool,
    /// What Recipients' Keys says at its top
    pub keys_intro: *const c_char,
    /// Recipients' Keys offers Send Without Encryption; when not, `unencrypted_text` says why
    pub can_send_unencrypted: bool,
    pub unencrypted_text: *const c_char,
    /// Send in Recipients' Keys can send encrypted (every recipient has a key, and there are some)
    pub can_send: bool,
    /// Send, else Cancel, is Recipients' Keys' default button (Enter)
    pub send_default: bool,
    /// The Keys line under the fields shows (Encrypt on, and recipients)
    pub show_keys: bool,
    /// Ask again (`pe_compose_security`) on the editor's `edited` while this is set: the message answers or forwards
    /// encrypted mail and goes without encryption, so taking its quote out changes the line and what Send does
    pub watch_text: bool,
}

/// The compose window's signing and encrypting, with its recipients; free with `pe_compose_security_free`
pub struct PeComposeSecurity {
    info: PeComposeSecurityInfo,
    recipients: Rows<PeComposeRecipient>,
    _strings: Strings,
}

fn security_handle(security: &ComposeSecurity) -> *mut PeComposeSecurity {
    let mut strings = Strings::default();
    let info = PeComposeSecurityInfo {
        sign: security.sign,
        sign_enabled: security.sign_enabled,
        encrypt: security.encrypt,
        has_own_key: security.has_own_key,
        tone: security.tone.map_or(PeProtectionTone::None, Into::into),
        text: strings.add(&security.text),
        sign_tip: strings.add(&security.sign_tip),
        encrypt_tip: strings.add(&security.encrypt_tip),
        block: match security.block {
            Block::None => PeComposeBlock::None,
            Block::NoOwnKey => PeComposeBlock::NoOwnKey,
            Block::MissingKeys => PeComposeBlock::MissingKeys,
            Block::EncryptedQuote => PeComposeBlock::EncryptedQuote,
        },
        block_text: strings.add(&security.block_text),
        missing: security.missing,
        looking: security.looking,
        keys_intro: strings.add(&security.keys_intro),
        can_send_unencrypted: security.can_send_unencrypted,
        unencrypted_text: strings.add(&security.unencrypted_text),
        can_send: security.can_send,
        send_default: security.send_default,
        show_keys: security.show_keys,
        watch_text: security.watch_text,
    };
    let recipients = Rows::new(&security.recipients, |r, strings| PeComposeRecipient {
        address: strings.add(&r.address),
        label: strings.add(&r.label),
        field: match r.field {
            RecipientField::To => PeRecipientField::To,
            RecipientField::Cc => PeRecipientField::Cc,
            RecipientField::Bcc => PeRecipientField::Bcc,
        },
        key: match r.key {
            RecipientKey::Verified => PeRecipientKey::Verified,
            RecipientKey::Found => PeRecipientKey::Found,
            RecipientKey::Own => PeRecipientKey::Own,
            RecipientKey::Looking => PeRecipientKey::Looking,
            RecipientKey::Missing => PeRecipientKey::Missing,
            RecipientKey::Unusable => PeRecipientKey::Unusable,
        },
        has_key: r.has_key,
        tone: r.tone.into(),
        text: strings.add(&r.text),
        pending: r.pending.as_deref().map_or(std::ptr::null(), |p| strings.add(p)),
        can_find: r.can_find,
    });
    handed(PeComposeSecurity {
        info,
        recipients,
        _strings: strings,
    })
}

/// What the compose window shows of signing and encrypting `message` from `account` now: ask again when the
/// recipients, From or a switch change, and on `KeysFound`. NULL on failure. Free with `pe_compose_security_free`.
///
/// # Safety
/// `core` must be a live handle, `message` a valid message.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn pe_compose_security(
    core: *const PeCore,
    account: i64,
    message: *const PeOutgoing,
) -> *mut PeComposeSecurity {
    // SAFETY: as the caller guarantees
    let Some(message) = (unsafe { outgoing(message) }) else {
        return null_mut();
    };
    // SAFETY: as the caller guarantees
    unsafe {
        with(core, null_mut(), |core| {
            core.compose_security(account, &message)
                .map_or(null_mut(), |security| security_handle(&security))
        })
    }
}

/// # Safety
/// `security` must be NULL or live.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn pe_compose_security_info(security: *const PeComposeSecurity) -> *const PeComposeSecurityInfo {
    // SAFETY: as the caller guarantees
    unsafe { security.as_ref() }.map_or(std::ptr::null(), |security| &security.info)
}

/// How many recipients the message has, each once
///
/// # Safety
/// `security` must be NULL or live.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn pe_compose_security_count(security: *const PeComposeSecurity) -> usize {
    // SAFETY: as the caller guarantees
    Rows::count(unsafe { security.as_ref() }.map(|s| &s.recipients))
}

/// Recipient `index` (To first, then Cc and Bcc), NULL past the end
///
/// # Safety
/// `security` must be NULL or live.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn pe_compose_security_recipient(
    security: *const PeComposeSecurity,
    index: usize,
) -> *const PeComposeRecipient {
    // SAFETY: as the caller guarantees
    Rows::get(unsafe { security.as_ref() }.map(|s| &s.recipients), index)
}

/// # Safety
/// `security` must be NULL or from `pe_compose_security`, freed once.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn pe_compose_security_free(security: *mut PeComposeSecurity) {
    // SAFETY: as the caller guarantees
    unsafe { take_back(security) }
}

/// A switch of the compose window
#[repr(C)]
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
#[allow(dead_code)] // made by the apps, read here
pub enum PeComposeSwitch {
    Sign = 0,
    Encrypt = 1,
}

/// What the window asks before a switch changes
#[repr(C)]
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum PeComposeQuestion {
    None = 0,
    /// No key for the From address: Yes opens New Key for the account, then the switch is clicked again
    MakeKey = 1,
    /// The From address's key can not be used: Yes opens Encryption Keys
    ShowKeys = 2,
    /// Encrypt off for a message that answers or forwards encrypted mail: Yes calls `pe_compose_toggle` again with
    /// `confirmed`
    TurnOffEncrypt = 3,
}

/// What a click on a switch came to
#[repr(C)]
pub struct PeComposeToggled {
    /// The switches to keep for PeOutgoing now: the user's own Sign (apart from Encrypt), and Encrypt
    pub sign: bool,
    pub encrypt: bool,
    /// A question to ask first, which left the switches as they were
    pub question: PeComposeQuestion,
    /// The question, empty without one
    pub text: *mut c_char,
    /// Its two buttons as words of the catalog (PE_TEXT_..., core/include/texts.h), for each window to show its own
    /// way: `pe_text` with the menu letter, `pe_text_plain` without; 0 without a question
    pub yes: u32,
    pub no: u32,
    /// A lookup of the recipients' keys that Encrypt started, 0 for none: `KeysFound` follows with it in `uid`
    pub lookup: u64,
}

fn toggled_handle(toggled: Toggled) -> *mut PeComposeToggled {
    handed(PeComposeToggled {
        sign: toggled.sign,
        encrypt: toggled.encrypt,
        question: match toggled.question {
            Question::None => PeComposeQuestion::None,
            Question::MakeKey => PeComposeQuestion::MakeKey,
            Question::ShowKeys => PeComposeQuestion::ShowKeys,
            Question::TurnOffEncrypt => PeComposeQuestion::TurnOffEncrypt,
        },
        text: into_c_string(toggled.text),
        yes: toggled.yes.map_or(0, |word| word as u32),
        no: toggled.no.map_or(0, |word| word as u32),
        lookup: toggled.lookup.unwrap_or(0),
    })
}

/// A click on Sign or Encrypt of `message` (its switches as they were), `on` what the switch is to become; again
/// with `confirmed` once the question `PE_COMPOSE_QUESTION_TURN_OFF_ENCRYPT` was answered Yes. NULL on failure. Free
/// with `pe_compose_toggled_free`.
///
/// # Safety
/// `core` must be a live handle, `message` a valid message.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn pe_compose_toggle(
    core: *const PeCore,
    account: i64,
    message: *const PeOutgoing,
    switch: PeComposeSwitch,
    on: bool,
    confirmed: bool,
) -> *mut PeComposeToggled {
    // SAFETY: as the caller guarantees
    let Some(message) = (unsafe { outgoing(message) }) else {
        return null_mut();
    };
    let switch = match switch {
        PeComposeSwitch::Sign => Switch::Sign,
        PeComposeSwitch::Encrypt => Switch::Encrypt,
    };
    // SAFETY: as the caller guarantees
    unsafe {
        with(core, null_mut(), |core| {
            core.compose_toggle(account, &message, switch, on, confirmed)
                .map_or(null_mut(), toggled_handle)
        })
    }
}

/// Recipients' Keys' Send Without Encryption: Encrypt off for `message`, Sign as the user had it, without asking the
/// Turn Off question again while the message carries nothing encrypted (`can_send_unencrypted`); while it does, the
/// question comes as from `pe_compose_toggle` (Yes: that call again with `confirmed`). Keep the switches it gives and
/// send when it has no question and Encrypt is off. NULL on failure. Free with `pe_compose_toggled_free`.
///
/// # Safety
/// `core` must be a live handle, `message` a valid message.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn pe_compose_send_unencrypted(
    core: *const PeCore,
    account: i64,
    message: *const PeOutgoing,
) -> *mut PeComposeToggled {
    // SAFETY: as the caller guarantees
    let Some(message) = (unsafe { outgoing(message) }) else {
        return null_mut();
    };
    // SAFETY: as the caller guarantees
    unsafe {
        with(core, null_mut(), |core| {
            core.compose_send_unencrypted(account, &message)
                .map_or(null_mut(), toggled_handle)
        })
    }
}

/// # Safety
/// `toggled` must be NULL or from `pe_compose_toggle` or `pe_compose_send_unencrypted`, freed once.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn pe_compose_toggled_free(toggled: *mut PeComposeToggled) {
    if toggled.is_null() {
        return;
    }
    // SAFETY: as the caller guarantees
    let toggled = unsafe { Box::from_raw(toggled) };
    // SAFETY: made by into_c_string
    unsafe {
        crate::pe_string_free(toggled.text);
    }
}

/// With Encrypt on, looks up the keys of the recipients that have none: when the recipients change (a field left,
/// or a moment after typing stops). `KeysFound` follows with the request in `uid`; 0 when there is nothing to ask.
///
/// # Safety
/// `core` must be a live handle, `message` a valid message.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn pe_compose_find_keys(core: *const PeCore, account: i64, message: *const PeOutgoing) -> u64 {
    // SAFETY: as the caller guarantees
    let Some(message) = (unsafe { outgoing(message) }) else {
        return 0;
    };
    // SAFETY: as the caller guarantees
    unsafe {
        with(core, 0, |core| {
            core.compose_find_keys(account, &message).ok().flatten().unwrap_or(0)
        })
    }
}

/// Recipients' Keys' Find Key for one recipient (its row's `can_find`): `KeysFound` follows with the request in
/// `uid`; 0 when it can not be asked now
///
/// # Safety
/// `core` must be a live handle, `address` a NUL-terminated string.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn pe_compose_find_key(core: *const PeCore, address: *const c_char) -> u64 {
    // SAFETY: as the caller guarantees
    let Some(address) = (unsafe { arg(address) }) else {
        return 0;
    };
    // SAFETY: as the caller guarantees
    unsafe {
        with(core, 0, |core| {
            core.compose_find_key(address).ok().flatten().unwrap_or(0)
        })
    }
}

/// What a lookup (`pe_compose_find_keys`, `pe_compose_find_key`, `pe_pgp_find_handle`, `pe_contact_find_keys`)
/// found, after its `KeysFound`: the keys are taken into the key book now, once, by the window that started it. What
/// to tell the user (the status bar, or the window's own line), NULL for another window's request or one still
/// running. Free with `pe_string_free`.
///
/// # Safety
/// `core` must be a live handle.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn pe_pgp_find_result(core: *const PeCore, request: u64) -> *mut c_char {
    // SAFETY: as the caller guarantees
    unsafe {
        with(core, null_mut(), |core| {
            core.pgp_find_result(request)
                .map_or(null_mut(), |outcome| into_c_string(outcome.text))
        })
    }
}

/// Remove from Message: the recipient lists of `message` without `address`, in `to`, `cc` and `bcc` (each as it
/// was typed when the address is not in it), for the fields. Free them with `pe_string_free`.
///
/// # Safety
/// `message` must be a valid message, `address` a NUL-terminated string, `to`, `cc` and `bcc` valid pointers.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn pe_compose_without_recipient(
    message: *const PeOutgoing,
    address: *const c_char,
    to: *mut *mut c_char,
    cc: *mut *mut c_char,
    bcc: *mut *mut c_char,
) -> bool {
    if to.is_null() || cc.is_null() || bcc.is_null() {
        return false;
    }
    // SAFETY: as the caller guarantees
    let (Some(message), Some(address)) = (unsafe { outgoing(message) }, unsafe { arg(address) }) else {
        return false;
    };
    let Some((new_to, new_cc, new_bcc)) = crate::guard(|| pe_core::compose_keys::without_recipient(&message, address))
    else {
        return false;
    };
    // SAFETY: the caller gave valid pointers
    unsafe {
        *to = into_c_string(new_to);
        *cc = into_c_string(new_cc);
        *bcc = into_c_string(new_bcc);
    }
    true
}

/// Insert > Attach My Public Key: the public key of the address `message` goes from, written to a file to attach
/// (as the attach button adds files); NULL with the reason in `error` (no key for that address). Free both with
/// `pe_string_free`.
///
/// # Safety
/// `core` must be a live handle, `message` a valid message, `error` NULL or a valid pointer.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn pe_compose_own_key_file(
    core: *const PeCore,
    account: i64,
    message: *const PeOutgoing,
    error: *mut *mut c_char,
) -> *mut c_char {
    // SAFETY: as the caller guarantees
    let result = match unsafe { outgoing(message) } {
        // SAFETY: as the caller guarantees
        Some(message) => unsafe {
            with(core, Err(None), |core| {
                core.compose_own_key_file(account, &message).map_err(Some)
            })
        },
        None => Err(None),
    };
    // SAFETY: as the caller guarantees
    unsafe { refused(error, result, "the key could not be attached") }
        .map_or(null_mut(), |path| into_c_string(path.to_string_lossy().into_owned()))
}

/// The UI tests' `--key-server <url>`: keys are looked up on this server on this computer (the e2e harness plays
/// keys.openpgp.org and every domain's directory), never on the internet. False for anything but a loopback
/// `http://127.0.0.1:<port>`; call it right after `pe_core_open`.
///
/// # Safety
/// `core` must be a live handle, `base` a NUL-terminated string.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn pe_core_use_test_key_server(core: *const PeCore, base: *const c_char) -> bool {
    // SAFETY: as the caller guarantees
    let Some(base) = (unsafe { arg(base) }) else {
        return false;
    };
    // SAFETY: as the caller guarantees
    unsafe { with(core, false, |core| core.use_test_key_server(base)) }
}

#[cfg(test)]
mod tests {
    use super::*;
    use std::ffi::{CStr, CString};

    #[test]
    fn the_switches_cross_and_a_recipient_is_removed() {
        let to = CString::new("Bob <bob@example.org>, carol@example.org").unwrap();
        let cc = CString::new("Bob@Example.org").unwrap();
        let message = PeOutgoing {
            to: to.as_ptr(),
            cc: cc.as_ptr(),
            bcc: std::ptr::null(),
            subject: std::ptr::null(),
            text: std::ptr::null(),
            html: std::ptr::null(),
            quote: std::ptr::null(),
            in_reply_to: std::ptr::null(),
            references: std::ptr::null(),
            attachments: std::ptr::null(),
            attachment_count: 0,
            message_id: std::ptr::null(),
            draft_account: 0,
            quote_plain: false,
            quote_text: std::ptr::null(),
            from: std::ptr::null(),
            sign: true,
            encrypt: false,
            quote_encrypted: true,
        };
        let read = unsafe { outgoing(&message) }.unwrap();
        assert!(read.sign && !read.encrypt && read.quote_encrypted);
        let address = CString::new("bob@example.org").unwrap();
        let (mut new_to, mut new_cc, mut new_bcc) = (null_mut(), null_mut(), null_mut());
        assert!(unsafe {
            pe_compose_without_recipient(&message, address.as_ptr(), &mut new_to, &mut new_cc, &mut new_bcc)
        });
        let text = |p: *mut c_char| {
            let text = unsafe { CStr::from_ptr(p) }.to_str().unwrap().to_string();
            unsafe { crate::pe_string_free(p) };
            text
        };
        assert_eq!(
            (text(new_to), text(new_cc), text(new_bcc)),
            ("carol@example.org".into(), String::new(), String::new())
        );
        assert!(!unsafe {
            pe_compose_without_recipient(&message, address.as_ptr(), null_mut(), null_mut(), null_mut())
        });
        // NULL handles are refused, never read
        assert!(unsafe { pe_compose_security(std::ptr::null(), 1, &message) }.is_null());
        assert!(unsafe { pe_compose_security_info(std::ptr::null()) }.is_null());
        assert_eq!(unsafe { pe_compose_security_count(std::ptr::null()) }, 0);
        assert!(unsafe { pe_compose_send_unencrypted(std::ptr::null(), 1, &message) }.is_null());
        unsafe { pe_compose_toggled_free(null_mut()) };
    }
}
