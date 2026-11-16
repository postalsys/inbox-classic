//! The setup file's JSON, and reading it: parsed, every value checked as the window that makes it checks it, and what
//! it holds summed up for the import window. Pure: no store, no file system, no network (the fuzz target reads here).

use std::collections::{BTreeMap, HashSet};

use base64::Engine;
use base64::engine::general_purpose::STANDARD;
use pe_i18n::{Text, tr, tr_args};
use pe_oauth::ProviderKind;
use pe_pgp::sealed::{self, OpenError};
use pe_pgp::{Cert, SecretKey};
use pe_store::{AccountSettings, Ahead, Card, Rule, Security};
use serde::{Deserialize, Serialize};
use zeroize::Zeroizing;

use super::{FORMAT, MAX_FILE, Parts, SetupError, VERSION, count_text, pref_value};
use crate::SignInAppForm;

/// The most of each list a setup file may hold; more is refused as damaged
const MAX_ACCOUNTS: usize = 500;
const MAX_APPS: usize = 200;
const MAX_GROUPS: usize = 10_000;
const MAX_KEYS: usize = 20_000;
const MAX_RULES: usize = 5_000;
const MAX_TRUSTED: usize = 50_000;
const MAX_ADDRESSES: usize = 100;

/// The longest name, address or host kept from a file
const MAX_TEXT: usize = 1024;
/// The longest signature: a signature with a picture or two
const MAX_SIGNATURE: usize = 1024 * 1024;

// ---- the JSON ----

#[derive(Debug, Clone, Default, Serialize, Deserialize)]
pub(crate) struct Document {
    pub format: String,
    pub version: u32,
    #[serde(default)]
    pub app_version: String,
    /// When it was saved, seconds since 1970
    #[serde(default)]
    pub created: i64,
    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub settings: Option<SettingsPart>,
    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub preferences: Option<BTreeMap<String, String>>,
    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub accounts: Option<Vec<AccountEntry>>,
    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub sign_in_apps: Option<AppsPart>,
    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub contacts: Option<ContactsPart>,
    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub keys: Option<KeysPart>,
    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub rules: Option<Vec<RuleEntry>>,
    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub trusted_senders: Option<Vec<TrustedEntry>>,
}

/// The store's settings that are not per computer. Left out: the store's profile id (it names this store's secrets),
/// whether AI agents are on (each computer decides), and the built-in sign-in apps' switches (in `sign_in_apps`).
#[derive(Debug, Clone, Default, PartialEq, Eq, Serialize, Deserialize)]
pub(crate) struct SettingsPart {
    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub dark_messages: Option<bool>,
    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub text_size: Option<usize>,
    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub download_ahead: Option<String>,
    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub download_limit_mb: Option<u64>,
    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub always_load_pictures: Option<bool>,
    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub pgp_keyserver: Option<bool>,
    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub send_delay: Option<u64>,
}

impl SettingsPart {
    /// Only the values the windows offer
    fn checked(&self) -> SettingsPart {
        SettingsPart {
            dark_messages: self.dark_messages,
            text_size: self.text_size.filter(|&size| size < crate::TEXT_ZOOMS.len()),
            download_ahead: self
                .download_ahead
                .as_deref()
                .and_then(Ahead::of_key)
                .map(|ahead| ahead.key().to_string()),
            download_limit_mb: self
                .download_limit_mb
                .filter(|mb| crate::DOWNLOAD_LIMITS_MB.contains(mb)),
            always_load_pictures: self.always_load_pictures,
            pgp_keyserver: self.pgp_keyserver,
            send_delay: self.send_delay.filter(|delay| crate::SEND_DELAYS.contains(delay)),
        }
    }

    pub(crate) fn count(&self) -> usize {
        [
            self.dark_messages.is_some(),
            self.text_size.is_some(),
            self.download_ahead.is_some(),
            self.download_limit_mb.is_some(),
            self.always_load_pictures.is_some(),
            self.pgp_keyserver.is_some(),
            self.send_delay.is_some(),
        ]
        .iter()
        .filter(|set| **set)
        .count()
    }
}

#[derive(Debug, Clone, Default, PartialEq, Eq, Serialize, Deserialize)]
pub(crate) struct Server {
    pub host: String,
    pub port: u16,
    /// `tls`, `starttls` or `plain`
    pub security: String,
}

impl Server {
    pub fn of(host: &str, port: u16, security: Security) -> Server {
        Server {
            host: host.to_string(),
            port,
            security: security.as_str().to_string(),
        }
    }

    /// The server checked as the account form checks it: (host, port, security)
    fn checked(&self) -> Option<(String, u16, Security)> {
        let host = self.host.trim();
        let security = match self.security.as_str() {
            "tls" => Security::Tls,
            "starttls" => Security::StartTls,
            "plain" => Security::Plain,
            _ => return None,
        };
        (host.len() <= 253 && crate::sign_in_apps::valid_host(host) && self.port != 0)
            .then(|| (host.to_ascii_lowercase(), self.port, security))
    }
}

/// How an account signs in
#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
#[serde(tag = "kind", rename_all = "lowercase")]
pub(crate) enum SignInEntry {
    Password,
    Google,
    Microsoft,
    /// A sign-in app, found by its issuer and client id (in the file's sign-in apps, or here)
    App {
        issuer: String,
        client_id: String,
    },
}

#[derive(Debug, Clone, Default, PartialEq, Eq, Serialize, Deserialize)]
pub(crate) struct AddressEntry {
    pub email: String,
    #[serde(default)]
    pub name: String,
}

#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub(crate) struct AccountEntry {
    pub email: String,
    /// The name on its mail
    pub name: String,
    /// Its own name in the folder list, empty for the name on its mail
    #[serde(default)]
    pub account_name: String,
    pub username: String,
    pub imap: Server,
    pub smtp: Server,
    pub sign_in: SignInEntry,
    #[serde(default)]
    pub signature: String,
    #[serde(default)]
    pub addresses: Vec<AddressEntry>,
    /// The password or the refresh token: only in a file sealed with a passphrase
    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub secret: Option<String>,
}

#[derive(Debug, Clone, Default, PartialEq, Eq, Serialize, Deserialize)]
pub(crate) struct AppsPart {
    /// Whether the built-in Google client is offered for new accounts
    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub google: Option<bool>,
    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub microsoft: Option<bool>,
    #[serde(default)]
    pub apps: Vec<AppEntry>,
}

#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub(crate) struct AppEntry {
    pub name: String,
    pub issuer: String,
    pub client_id: String,
    pub scopes: String,
    // no endpoints: an import reads them from the issuer's discovery document, as the sign-in apps window does (a
    // file written before this carries authorize_url, token_url and response_issuer, which are not read)
    pub imap: Server,
    pub smtp: Server,
    #[serde(default = "yes")]
    pub enabled: bool,
    /// The client secret: only in a file sealed with a passphrase
    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub secret: Option<String>,
}

fn yes() -> bool {
    true
}

#[derive(Debug, Clone, Default, PartialEq, Eq, Serialize, Deserialize)]
pub(crate) struct ContactsPart {
    /// The people of the address book as vCard 3.0, with their pictures (their keys are in `keys`)
    #[serde(default)]
    pub vcards: String,
    #[serde(default)]
    pub groups: Vec<GroupEntry>,
}

#[derive(Debug, Clone, Default, PartialEq, Eq, Serialize, Deserialize)]
pub(crate) struct GroupEntry {
    pub name: String,
    #[serde(default)]
    pub members: Vec<AddressEntry>,
}

#[derive(Debug, Clone, Default, PartialEq, Eq, Serialize, Deserialize)]
pub(crate) struct KeysPart {
    /// Contacts' public keys in use for one of their addresses
    #[serde(default)]
    pub contacts: Vec<ContactKeyEntry>,
    /// The user's own private keys: only in a file sealed with a passphrase
    #[serde(default)]
    pub own: Vec<OwnKeyEntry>,
}

#[derive(Debug, Clone, Default, PartialEq, Eq, Serialize, Deserialize)]
pub(crate) struct ContactKeyEntry {
    /// The certificate, binary in base64
    pub cert: String,
    /// The addresses whose fingerprint the user compared
    #[serde(default)]
    pub verified: Vec<String>,
}

#[derive(Debug, Clone, Default, PartialEq, Eq, Serialize, Deserialize)]
pub(crate) struct OwnKeyEntry {
    /// The private key without a passphrase (the file's is the protection), binary in base64
    pub key: String,
    /// The own addresses that use it, and whether their mail carries it in the Autocrypt header
    #[serde(default)]
    pub identities: Vec<IdentityEntry>,
}

#[derive(Debug, Clone, Default, PartialEq, Eq, Serialize, Deserialize)]
pub(crate) struct IdentityEntry {
    pub address: String,
    #[serde(default)]
    pub autocrypt: bool,
}

/// An account as a rule names it: by its address and IMAP server, as an account already here is found
#[derive(Debug, Clone, Default, PartialEq, Eq, Serialize, Deserialize)]
pub(crate) struct AccountRef {
    pub email: String,
    pub imap_host: String,
}

impl AccountRef {
    fn checked(&self) -> Option<AccountRef> {
        let host = self.imap_host.trim();
        (crate::book::is_mailbox(&self.email) && crate::sign_in_apps::valid_host(host)).then(|| AccountRef {
            email: self.email.trim().to_string(),
            imap_host: host.to_ascii_lowercase(),
        })
    }

    pub fn of(settings: &AccountSettings) -> AccountRef {
        AccountRef {
            email: settings.email.clone(),
            imap_host: settings.imap_host.clone(),
        }
    }

    pub fn is(&self, settings: &AccountSettings) -> bool {
        self.email.eq_ignore_ascii_case(settings.email.trim())
            && self.imap_host.eq_ignore_ascii_case(&settings.imap_host)
    }
}

#[derive(Debug, Clone, Default, PartialEq, Eq, Serialize, Deserialize)]
pub(crate) struct FolderRef {
    pub account: AccountRef,
    pub path: String,
}

#[derive(Debug, Clone, Default, PartialEq, Eq, Serialize, Deserialize)]
pub(crate) struct RuleEntry {
    pub name: String,
    #[serde(default = "yes")]
    pub enabled: bool,
    /// The account whose Inbox it is for, none for every account's
    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub account: Option<AccountRef>,
    pub query: String,
    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub move_to: Option<FolderRef>,
    #[serde(default)]
    pub mark_read: bool,
    #[serde(default)]
    pub flag: bool,
    #[serde(default)]
    pub archive: bool,
    #[serde(default)]
    pub junk: bool,
    #[serde(default)]
    pub remove: bool,
    #[serde(default)]
    pub quiet: bool,
}

#[derive(Debug, Clone, Default, PartialEq, Eq, Serialize, Deserialize)]
pub(crate) struct TrustedEntry {
    pub value: String,
    #[serde(default)]
    pub domain: bool,
}

// ---- what a file holds, checked ----

/// How an account in a file signs in, checked
#[derive(Debug, Clone, PartialEq, Eq)]
pub(crate) enum SignInRef {
    Password,
    Builtin(ProviderKind),
    App { issuer: String, client_id: String },
}

/// An account of a file, checked, ready to add
pub(crate) struct FileAccount {
    /// Its settings; `auth` is set when it is added, from `sign_in`
    pub settings: AccountSettings,
    pub sign_in: SignInRef,
    pub account_name: String,
    pub signature: String,
    pub addresses: Vec<(String, String)>,
    pub secret: Option<Zeroizing<String>>,
}

/// A rule of a file, checked: the rule without its account and folder, which are found here when it is imported
pub(crate) struct FileRule {
    pub rule: Rule,
    pub account: Option<AccountRef>,
    pub move_to: Option<FolderRef>,
}

/// A sign-in app of a file, checked
pub(crate) struct FileApp {
    /// What the sign-in apps window would save, checked as it checks it
    pub form: SignInAppForm,
    pub enabled: bool,
    pub secret: Option<Zeroizing<String>>,
}

impl FileApp {
    pub fn is(&self, issuer: &str, client_id: &str) -> bool {
        self.form.issuer == issuer && self.form.client_id == client_id
    }
}

/// A group of a file: its name and its members (name, address)
pub(crate) struct FileGroup {
    pub name: String,
    pub members: Vec<(String, String)>,
}

/// What a setup file holds, checked, for the import
#[derive(Default)]
pub(crate) struct Data {
    pub settings: Option<SettingsPart>,
    /// Each account of the file beside its row of [`SetupFile::accounts`], None for one that can not be imported
    pub accounts: Vec<Option<FileAccount>>,
    pub builtin: Vec<(ProviderKind, bool)>,
    pub apps: Vec<FileApp>,
    pub cards: Vec<Card>,
    pub groups: Vec<FileGroup>,
    pub contact_keys: Vec<(Cert, Vec<String>)>,
    pub own_keys: Vec<(SecretKey, Vec<(String, bool)>)>,
    pub rules: Vec<FileRule>,
    pub trusted: Vec<(String, bool)>,
}

impl Data {
    /// How much of each part there is, the preferences but
    fn counts(&self) -> SetupCounts {
        SetupCounts {
            settings: self.settings.as_ref().map_or(0, SettingsPart::count),
            preferences: 0,
            accounts: self.accounts.iter().flatten().count(),
            sign_in_apps: self.apps.len(),
            builtin: self.builtin.len(),
            contacts: self.cards.len(),
            groups: self.groups.len(),
            own_keys: self.own_keys.len(),
            contact_keys: self.contact_keys.len(),
            rules: self.rules.len(),
            trusted_senders: self.trusted.len(),
        }
    }
}

/// An account of a setup file as the import window lists it
#[derive(Debug, Clone, PartialEq, Eq, Default)]
pub struct SetupAccount {
    /// Its place in the file, what an import names it by
    pub index: usize,
    pub email: String,
    /// What the folder list will call it
    pub title: String,
    /// The title with the address, as the import window lists it: "Work <ann@example.com>"
    pub label: String,
    /// Its servers and how it signs in, one line: "imap.example.com and smtp.example.com (Password)"
    pub servers: String,
    /// How it signs in, in words: "Password", or the sign-in app's name
    pub sign_in: String,
    /// One like it (the same address and IMAP server) is set up here already: an import skips it
    pub here: bool,
    /// An import can add it: it is not here, nothing is wrong with it, and what it signs in with is usable
    pub importable: bool,
    /// Why it can not be imported, in words; None when it can (or when it is only here already)
    pub problem: Option<String>,
    /// What an import does with it, in words: skipped as it is here, its password in the file, asks for it, ...
    pub note: String,
    /// Its password or sign-in is in the file
    pub(crate) has_secret: bool,
}

/// How much of each part a setup file holds
#[derive(Debug, Clone, Copy, PartialEq, Eq, Default)]
pub struct SetupCounts {
    pub settings: usize,
    pub preferences: usize,
    pub accounts: usize,
    pub sign_in_apps: usize,
    /// The switches of the built-in sign-in apps
    pub builtin: usize,
    pub contacts: usize,
    pub groups: usize,
    pub own_keys: usize,
    pub contact_keys: usize,
    pub rules: usize,
    pub trusted_senders: usize,
}

/// A setup file read and checked: what it holds, for the import window, and what an import writes
pub struct SetupFile {
    /// It was sealed with a passphrase (and only then carries secrets)
    pub encrypted: bool,
    /// The version of Inbox Classic that saved it
    pub app_version: String,
    /// When, seconds since 1970, and as the user's locale writes a day (empty for no day a calendar writes)
    pub created: i64,
    pub created_text: String,
    /// The parts it holds
    pub parts: Parts,
    pub accounts: Vec<SetupAccount>,
    /// The app preferences it holds, by name, each value checked and ready to apply, the language last
    pub prefs: Vec<(String, String)>,
    /// What it holds that can not be used and is left out, a line each in words
    pub notes: Vec<String>,
    pub(crate) data: Data,
}

impl std::fmt::Debug for SetupFile {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        f.debug_struct("SetupFile")
            .field("encrypted", &self.encrypted)
            .field("app_version", &self.app_version)
            .field("parts", &self.parts)
            .field("accounts", &self.accounts)
            .field("prefs", &self.prefs)
            .field("notes", &self.notes)
            .finish_non_exhaustive()
    }
}

impl SetupFile {
    /// How much of each part it holds
    pub fn counts(&self) -> SetupCounts {
        SetupCounts {
            preferences: self.prefs.len(),
            ..self.data.counts()
        }
    }

    /// Each part it holds something in, with its name and what it holds in words, in the order the windows list
    /// them: (part, "2 accounts"); a part with nothing in it (no rules, no trusted senders) is not offered for import
    pub fn part_lines(&self) -> Vec<(Parts, String)> {
        part_lines(self.parts, &self.counts(), true)
    }
}

/// What `part` holds in words, and whether it holds nothing
fn holds(part: Parts, c: &SetupCounts) -> (String, bool) {
    let both =
        |first: Text, n: usize, second: Text, m: usize| format!("{}, {}", count_text(first, n), count_text(second, m));
    match part {
        Parts::SETTINGS => (count_text(Text::SetupHoldsSettings, c.settings), c.settings == 0),
        Parts::PREFERENCES => (
            count_text(Text::SetupHoldsPreferences, c.preferences),
            c.preferences == 0,
        ),
        Parts::ACCOUNTS => (count_text(Text::SetupHoldsAccounts, c.accounts), c.accounts == 0),
        Parts::SIGN_IN_APPS if c.sign_in_apps == 0 => (tr(Text::SetupHoldsBuiltIn), c.builtin == 0),
        Parts::SIGN_IN_APPS => (count_text(Text::SetupHoldsSignInApps, c.sign_in_apps), false),
        Parts::CONTACTS => (
            both(Text::SetupHoldsContacts, c.contacts, Text::SetupHoldsGroups, c.groups),
            c.contacts == 0 && c.groups == 0,
        ),
        Parts::KEYS if c.own_keys == 0 => (
            count_text(Text::SetupHoldsContactKeys, c.contact_keys),
            c.contact_keys == 0,
        ),
        Parts::KEYS => (
            both(
                Text::SetupHoldsOwnKeys,
                c.own_keys,
                Text::SetupHoldsContactKeys,
                c.contact_keys,
            ),
            false,
        ),
        Parts::RULES => (count_text(Text::SetupHoldsRules, c.rules), c.rules == 0),
        _ => (
            count_text(Text::SetupHoldsTrustedSenders, c.trusted_senders),
            c.trusted_senders == 0,
        ),
    }
}

/// What each part of `parts` holds in words, in the order the windows list them; with `offered`, only the parts that
/// hold something (what an import offers)
pub(crate) fn part_lines(parts: Parts, counts: &SetupCounts, offered: bool) -> Vec<(Parts, String)> {
    Parts::EACH
        .into_iter()
        .filter(|part| parts.has(*part))
        .filter_map(|part| {
            let (words, empty) = holds(part, counts);
            (!offered || !empty).then_some((part, words))
        })
        .collect()
}

// ---- reading ----

/// The JSON of `bytes`, opened with `passphrase` when it is sealed: (JSON, sealed)
fn opened(bytes: &[u8], passphrase: Option<&str>) -> Result<(Zeroizing<Vec<u8>>, bool), SetupError> {
    if bytes.trim_ascii().is_empty() {
        return Err(SetupError::invalid(Text::SetupErrorEmpty));
    }
    if bytes.len() > MAX_FILE {
        return Err(SetupError::invalid(Text::SetupErrorTooLarge));
    }
    // a byte order mark an editor put before the JSON
    let bytes = bytes.strip_prefix("\u{feff}".as_bytes()).unwrap_or(bytes);
    if sealed::looks_sealed(bytes) {
        let passphrase = passphrase
            .filter(|p| !p.is_empty())
            .ok_or(SetupError::NeedsPassphrase)?;
        return match sealed::open(bytes, passphrase, MAX_FILE) {
            Ok(json) => Ok((Zeroizing::new(json), true)),
            Err(OpenError::WrongPassphrase) => Err(SetupError::WrongPassphrase),
            Err(OpenError::Integrity) => Err(SetupError::invalid(Text::SetupErrorChanged)),
            Err(OpenError::TooLarge) => Err(SetupError::invalid(Text::SetupErrorTooLarge)),
            Err(OpenError::Malformed(_)) => Err(SetupError::invalid(Text::SetupErrorNotSetup)),
        };
    }
    if bytes.trim_ascii_start().first() != Some(&b'{') {
        return Err(SetupError::invalid(Text::SetupErrorNotSetup));
    }
    Ok((Zeroizing::new(bytes.to_vec()), false))
}

/// Reads a setup file's bytes, opened with `passphrase` when it is sealed with one, and checks everything in it. What
/// is already set up here is not known here: `Core::read_setup` marks it.
pub fn parse(bytes: &[u8], passphrase: Option<&str>) -> Result<SetupFile, SetupError> {
    let (json, encrypted) = opened(bytes, passphrase)?;
    let value: serde_json::Value =
        serde_json::from_slice(&json).map_err(|_| SetupError::invalid(Text::SetupErrorNotSetup))?;
    if value.get("format").and_then(|f| f.as_str()) != Some(FORMAT) {
        return Err(SetupError::invalid(Text::SetupErrorNotSetup));
    }
    let version = value.get("version").and_then(|v| v.as_u64()).unwrap_or(0);
    if version > VERSION as u64 {
        let app = value.get("app_version").and_then(|v| v.as_str()).unwrap_or("?");
        let app: String = app.chars().filter(|c| !c.is_control()).take(40).collect();
        return Err(SetupError::Invalid(tr_args(
            Text::SetupErrorNewer,
            &[("version", (&app).into())],
        )));
    }
    let damaged = || SetupError::invalid(Text::SetupErrorDamaged);
    if version == 0 {
        return Err(damaged());
    }
    let document: Document = serde_json::from_value(value).map_err(|_| damaged())?;
    drop(json);
    checked(document, encrypted)
}

/// A name or other short text from a file: no control characters, trimmed, at most [`MAX_TEXT`] bytes
fn text(value: &str) -> String {
    let clean: String = value.chars().filter(|c| !c.is_control()).collect();
    crate::snippet::head(clean.trim(), MAX_TEXT).to_string()
}

fn too_many<T>(list: &[T], max: usize) -> Result<(), SetupError> {
    if list.len() > max {
        return Err(SetupError::invalid(Text::SetupErrorDamaged));
    }
    Ok(())
}

/// What `document` holds, checked; `encrypted` says whether its secrets count (a file that is not sealed has none)
fn checked(document: Document, encrypted: bool) -> Result<SetupFile, SetupError> {
    let created = Some(document.created)
        .filter(|at| (0..=253_402_300_799).contains(at))
        .unwrap_or(0);
    let mut file = SetupFile {
        encrypted,
        app_version: text(&document.app_version),
        created,
        // a day the platform's calendar can write: from 1970 to the year 9999
        created_text: if created > 0 {
            crate::calendar::local_date(created)
        } else {
            String::new()
        },
        parts: Parts::NONE,
        accounts: Vec::new(),
        prefs: Vec::new(),
        notes: Vec::new(),
        data: Data::default(),
    };
    if let Some(settings) = &document.settings {
        let settings = settings.checked();
        file.parts = file.parts.with(Parts::SETTINGS);
        file.data.settings = Some(settings);
    }
    if let Some(prefs) = &document.preferences {
        file.parts = file.parts.with(Parts::PREFERENCES);
        // in the order of the list, the language last
        file.prefs = super::PREFERENCES
            .iter()
            .filter_map(|(name, _)| Some((name.to_string(), pref_value(name, prefs.get(*name)?)?)))
            .collect();
    }
    if let Some(apps) = &document.sign_in_apps {
        too_many(&apps.apps, MAX_APPS)?;
        file.parts = file.parts.with(Parts::SIGN_IN_APPS);
        read_apps(&mut file, apps, encrypted);
    }
    if let Some(accounts) = &document.accounts {
        too_many(accounts, MAX_ACCOUNTS)?;
        file.parts = file.parts.with(Parts::ACCOUNTS);
        read_accounts(&mut file, accounts, encrypted);
    }
    if let Some(contacts) = &document.contacts {
        too_many(&contacts.groups, MAX_GROUPS)?;
        file.parts = file.parts.with(Parts::CONTACTS);
        read_contacts(&mut file, contacts);
    }
    if let Some(keys) = &document.keys {
        too_many(&keys.contacts, MAX_KEYS)?;
        too_many(&keys.own, MAX_KEYS)?;
        file.parts = file.parts.with(Parts::KEYS);
        read_keys(&mut file, keys, encrypted);
    }
    if let Some(rules) = &document.rules {
        too_many(rules, MAX_RULES)?;
        file.parts = file.parts.with(Parts::RULES);
        read_rules(&mut file, rules);
    }
    if let Some(trusted) = &document.trusted_senders {
        too_many(trusted, MAX_TRUSTED)?;
        file.parts = file.parts.with(Parts::TRUSTED_SENDERS);
        read_trusted(&mut file, trusted);
    }
    Ok(file)
}

/// Says how many entries of `part` were left out, when some were
fn left_out(file: &mut SetupFile, part: Parts, count: usize) {
    if count > 0 {
        file.notes.push(tr_args(
            Text::SetupLeftOut,
            &[("count", count.into()), ("part", (&part.name()).into())],
        ));
    }
}

/// A secret of a file that is sealed; a file that is not has none
fn secret(value: &Option<String>, encrypted: bool) -> Option<Zeroizing<String>> {
    value
        .as_deref()
        .filter(|secret| encrypted && !secret.is_empty() && secret.len() <= 64 * 1024)
        .map(|secret| Zeroizing::new(secret.to_string()))
}

/// A sign-in app of a file as the sign-in apps window would save it, checked as it checks it
fn checked_app(entry: &AppEntry) -> Option<SignInAppForm> {
    let (imap_host, imap_port, imap_security) = entry.imap.checked()?;
    let (smtp_host, smtp_port, smtp_security) = entry.smtp.checked()?;
    let form = SignInAppForm {
        name: text(&entry.name),
        issuer: entry.issuer.clone(),
        client_id: entry.client_id.clone(),
        scopes: entry.scopes.clone(),
        imap_host,
        imap_port,
        imap_security,
        smtp_host,
        smtp_port,
        smtp_security,
    };
    crate::sign_in_apps::checked_form(&form).ok()
}

fn read_apps(file: &mut SetupFile, part: &AppsPart, encrypted: bool) {
    for (kind, on) in [
        (ProviderKind::Google, part.google),
        (ProviderKind::Microsoft, part.microsoft),
    ] {
        if let Some(on) = on {
            file.data.builtin.push((kind, on));
        }
    }
    let mut refused = 0;
    for entry in &part.apps {
        match checked_app(entry) {
            Some(form) => file.data.apps.push(FileApp {
                form,
                enabled: entry.enabled,
                secret: secret(&entry.secret, encrypted),
            }),
            None => refused += 1,
        }
    }
    left_out(file, Parts::SIGN_IN_APPS, refused);
}

/// An account of a file checked as the account form checks it: the account, or why it can not be one
fn checked_account(entry: &AccountEntry, encrypted: bool) -> Result<FileAccount, String> {
    let email = entry.email.trim();
    if !crate::book::is_mailbox(email) || email.len() > 320 {
        return Err(tr_args(
            Text::SetupInvalidAddress,
            &[("address", (&text(email)).into())],
        ));
    }
    let server = |what: &str, server: &Server| {
        server
            .checked()
            .ok_or_else(|| tr_args(Text::SetupInvalidServer, &[("server", what.into())]))
    };
    let (imap_host, imap_port, imap_security) = server("IMAP", &entry.imap)?;
    let (smtp_host, smtp_port, smtp_security) = server("SMTP", &entry.smtp)?;
    let username = text(&entry.username);
    if username.is_empty() {
        return Err(tr(Text::SetupInvalidUser));
    }
    let sign_in = match &entry.sign_in {
        SignInEntry::Password => SignInRef::Password,
        SignInEntry::Google => SignInRef::Builtin(ProviderKind::Google),
        SignInEntry::Microsoft => SignInRef::Builtin(ProviderKind::Microsoft),
        SignInEntry::App { issuer, client_id } => SignInRef::App {
            issuer: pe_oauth::issuer(issuer).map_err(|_| tr(Text::SetupInvalidSignIn))?,
            client_id: text(client_id),
        },
    };
    let mut addresses: Vec<(String, String)> = Vec::new();
    for address in entry.addresses.iter().take(MAX_ADDRESSES) {
        let other = address.email.trim();
        if crate::book::is_mailbox(other)
            && !other.eq_ignore_ascii_case(email)
            && !addresses.iter().any(|(known, _)| known.eq_ignore_ascii_case(other))
        {
            addresses.push((other.to_string(), text(&address.name)));
        }
    }
    let signature = if entry.signature.len() <= MAX_SIGNATURE {
        pe_html::signature_html(&entry.signature)
    } else {
        String::new()
    };
    Ok(FileAccount {
        settings: AccountSettings {
            name: text(&entry.name),
            email: email.to_string(),
            username,
            imap_host,
            imap_port,
            imap_security,
            smtp_host,
            smtp_port,
            smtp_security,
            auth: pe_store::Auth::Password,
        },
        sign_in,
        account_name: text(&entry.account_name),
        signature,
        addresses,
        secret: secret(&entry.secret, encrypted),
    })
}

/// How an account signs in, in words: "Password", a built-in client's name, or the sign-in app's in the file
fn sign_in_words(sign_in: &SignInRef, apps: &[FileApp]) -> String {
    match sign_in {
        SignInRef::Password => tr(Text::SetupSignInPassword),
        SignInRef::Builtin(kind) => crate::builtin_name(*kind).to_string(),
        SignInRef::App { issuer, client_id } => apps
            .iter()
            .find(|app| app.is(issuer, client_id))
            .map_or_else(|| issuer.clone(), |app| app.form.name.clone()),
    }
}

fn read_accounts(file: &mut SetupFile, entries: &[AccountEntry], encrypted: bool) {
    for (index, entry) in entries.iter().enumerate() {
        let (row, account) = match checked_account(entry, encrypted) {
            Ok(account) => (account_row(index, &account, &file.data.apps), Some(account)),
            // kept in the list with the reason, so the import window shows what will not come
            Err(problem) => {
                let email = text(&entry.email);
                let row = SetupAccount {
                    index,
                    title: email.clone(),
                    label: email.clone(),
                    email,
                    problem: Some(problem),
                    ..SetupAccount::default()
                };
                (row, None)
            }
        };
        file.accounts.push(row);
        file.data.accounts.push(account);
    }
}

/// An account as the import window lists it, before what is here is known
fn account_row(index: usize, account: &FileAccount, apps: &[FileApp]) -> SetupAccount {
    let settings = &account.settings;
    let title = match account.account_name.as_str() {
        "" => crate::default_account_name(&settings.email),
        name => name.to_string(),
    };
    let sign_in = sign_in_words(&account.sign_in, apps);
    SetupAccount {
        index,
        email: settings.email.clone(),
        label: crate::account_label(&title, &settings.email),
        title,
        servers: tr_args(
            Text::SetupAccountServers,
            &[
                ("imap", (&settings.imap_host).into()),
                ("smtp", (&settings.smtp_host).into()),
                ("signin", (&sign_in).into()),
            ],
        ),
        sign_in,
        importable: true,
        has_secret: account.secret.is_some(),
        ..SetupAccount::default()
    }
}

fn read_contacts(file: &mut SetupFile, part: &ContactsPart) {
    let cards: Vec<Card> = crate::vcard::read_vcards(&part.vcards)
        .into_iter()
        .map(crate::book::checked)
        .collect();
    let mut refused = 0;
    for group in &part.groups {
        let name = text(&group.name);
        if name.is_empty() {
            refused += 1;
            continue;
        }
        let members = group
            .members
            .iter()
            .filter(|member| crate::book::is_mailbox(&member.email))
            .map(|member| (text(&member.name), member.email.trim().to_string()))
            .take(10_000)
            .collect();
        file.data.groups.push(FileGroup { name, members });
    }
    file.data.cards = cards;
    left_out(file, Parts::CONTACTS, refused);
}

fn decoded(base64: &str) -> Option<Zeroizing<Vec<u8>>> {
    if base64.len() > pe_pgp::MAX_CERT_BYTES * 2 {
        return None;
    }
    STANDARD.decode(base64.trim()).ok().map(Zeroizing::new)
}

fn read_keys(file: &mut SetupFile, part: &KeysPart, encrypted: bool) {
    let mut refused = 0;
    for entry in &part.contacts {
        let cert = decoded(&entry.cert)
            .and_then(|bytes| pe_pgp::read_certs(&bytes).ok())
            .filter(|certs| certs.len() == 1)
            .and_then(|mut certs| certs.pop());
        match cert {
            Some(cert) => {
                let verified = entry
                    .verified
                    .iter()
                    .map(|address| pe_store::normal_address(address))
                    .take(MAX_ADDRESSES)
                    .collect();
                file.data.contact_keys.push((cert, verified));
            }
            None => refused += 1,
        }
    }
    if encrypted {
        for entry in &part.own {
            match decoded(&entry.key).and_then(|bytes| SecretKey::from_bytes(&bytes).ok()) {
                Some(key) => {
                    let identities = entry
                        .identities
                        .iter()
                        .filter(|identity| crate::book::is_mailbox(&identity.address))
                        .map(|identity| (pe_store::normal_address(&identity.address), identity.autocrypt))
                        .take(MAX_ADDRESSES)
                        .collect();
                    file.data.own_keys.push((key, identities));
                }
                None => refused += 1,
            }
        }
    }
    left_out(file, Parts::KEYS, refused);
}

/// A rule of a file checked as the rule editor checks it
fn checked_rule(entry: &RuleEntry) -> Option<FileRule> {
    let account = match &entry.account {
        Some(account) => Some(account.checked()?),
        None => None,
    };
    let move_to = match &entry.move_to {
        Some(folder) => {
            let path: String = folder.path.chars().filter(|c| !c.is_control()).collect();
            if path.is_empty() || path.len() > MAX_TEXT {
                return None;
            }
            Some(FolderRef {
                account: folder.account.checked()?,
                path,
            })
        }
        None => None,
    };
    let rule = Rule {
        id: 0,
        enabled: entry.enabled,
        name: text(&entry.name),
        account: None,
        query: text(&entry.query),
        move_to: None,
        mark_read: entry.mark_read,
        flag: entry.flag,
        archive: entry.archive,
        junk: entry.junk,
        remove: entry.remove,
        quiet: entry.quiet,
    };
    let rule = crate::rules::checked_rule(&rule, move_to.is_some()).ok()?;
    Some(FileRule { rule, account, move_to })
}

fn read_rules(file: &mut SetupFile, entries: &[RuleEntry]) {
    let mut refused = 0;
    for entry in entries {
        match checked_rule(entry) {
            Some(rule) => file.data.rules.push(rule),
            None => refused += 1,
        }
    }
    left_out(file, Parts::RULES, refused);
}

fn read_trusted(file: &mut SetupFile, entries: &[TrustedEntry]) {
    let mut refused = 0;
    let mut seen = HashSet::new();
    for entry in entries {
        let value = entry.value.trim().to_lowercase();
        let usable = !value.is_empty()
            && value.len() <= 320
            && entry.domain != value.contains('@')
            && !value
                .chars()
                .any(|c| c.is_control() || c.is_whitespace() || "<>,;\"".contains(c));
        if !usable {
            refused += 1;
        } else if seen.insert(value.clone()) {
            file.data.trusted.push((value, entry.domain));
        }
    }
    left_out(file, Parts::TRUSTED_SENDERS, refused);
}

#[cfg(test)]
mod tests {
    use super::*;

    fn document(extra: serde_json::Value) -> Vec<u8> {
        let mut value =
            serde_json::json!({"format": FORMAT, "version": 1, "app_version": "0.18.0", "created": 1_790_000_000});
        for (key, part) in extra.as_object().unwrap() {
            value[key] = part.clone();
        }
        serde_json::to_vec(&value).unwrap()
    }

    fn error(bytes: &[u8]) -> String {
        parse(bytes, None).unwrap_err().text()
    }

    #[test]
    fn what_is_not_a_setup_is_refused_with_words() {
        assert_eq!(error(b""), tr(Text::SetupErrorEmpty));
        assert_eq!(error(b"  \n"), tr(Text::SetupErrorEmpty));
        assert_eq!(error(b"hello"), tr(Text::SetupErrorNotSetup));
        assert_eq!(error(b"{not json"), tr(Text::SetupErrorNotSetup));
        assert_eq!(
            error(br#"{"format":"other","version":1}"#),
            tr(Text::SetupErrorNotSetup)
        );
        assert_eq!(
            error(br#"{"format":"inbox-classic-setup"}"#),
            tr(Text::SetupErrorDamaged)
        );
        let newer = error(br#"{"format":"inbox-classic-setup","version":2,"app_version":"9.0.0"}"#);
        assert!(newer.contains("9.0.0"), "{newer}");
        assert_eq!(
            error(&vec![b' '; MAX_FILE + 1]),
            tr(Text::SetupErrorEmpty),
            "blank is empty whatever its size"
        );
        let mut big = br#"{"format":"inbox-classic-setup","version":1,"x":""#.to_vec();
        big.resize(MAX_FILE + 1, b'a');
        assert_eq!(error(&big), tr(Text::SetupErrorTooLarge));
    }

    #[test]
    fn wrong_types_are_damaged() {
        for part in [
            serde_json::json!({"accounts": {"a": 1}}),
            serde_json::json!({"accounts": [{"email": 5}]}),
            serde_json::json!({"rules": [{"name": "x", "query": ["from:a"]}]}),
            serde_json::json!({"settings": {"text_size": "big"}}),
            serde_json::json!({"keys": {"own": "x"}}),
            serde_json::json!({"trusted_senders": [{"value": null}]}),
            serde_json::json!({"accounts": [{"email": "a@b.c", "name": "A", "username": "a", "imap": {"host": "h", "port": 70000, "security": "tls"}, "smtp": {"host": "h", "port": 1, "security": "tls"}, "sign_in": {"kind": "password"}}]}),
            serde_json::json!({"accounts": [{"email": "a@b.c", "name": "A", "username": "a", "imap": {"host": "h", "port": 1, "security": "tls"}, "smtp": {"host": "h", "port": 1, "security": "tls"}, "sign_in": {"kind": "telepathy"}}]}),
        ] {
            assert_eq!(error(&document(part.clone())), tr(Text::SetupErrorDamaged), "{part}");
        }
    }

    #[test]
    fn a_minimal_file_and_its_parts() {
        let file = parse(&document(serde_json::json!({})), None).unwrap();
        assert!(!file.encrypted);
        assert_eq!(file.parts, Parts::NONE);
        assert_eq!(file.app_version, "0.18.0");
        assert!(!file.created_text.is_empty());
        // a date no calendar writes is no date
        for created in [-1, i64::MAX] {
            let file = parse(&document(serde_json::json!({"created": created})), None).unwrap();
            assert_eq!((file.created, file.created_text.as_str()), (0, ""));
        }
        // a byte order mark and spaces before it
        let mut marked = "\u{feff}  ".as_bytes().to_vec();
        marked.extend(document(
            serde_json::json!({"preferences": {"layout": "1", "hide_read": "maybe", "x": "1"}}),
        ));
        let file = parse(&marked, None).unwrap();
        assert_eq!(file.prefs, [("layout".to_string(), "1".to_string())]);
        assert_eq!(
            file.part_lines(),
            [(Parts::PREFERENCES, count_text(Text::SetupHoldsPreferences, 1))]
        );
    }

    #[test]
    fn accounts_are_checked_as_the_form_checks_them() {
        let account = |email: &str, host: &str| {
            serde_json::json!({
                "email": email, "name": "Ann", "username": "ann", "account_name": "Work\u{7}",
                "imap": {"host": host, "port": 993, "security": "tls"},
                "smtp": {"host": "smtp.example.com", "port": 587, "security": "plain"},
                "sign_in": {"kind": "password"},
                "signature": "<p>Ann<script>x()</script></p>",
                "addresses": [{"email": "ann@other.example", "name": "Ann"}, {"email": "not an address"}, {"email": email}],
                "secret": "hunter2"
            })
        };
        let bytes = document(serde_json::json!({"accounts": [
            account("ann@example.com", "imap.example.com"),
            account("not an address", "imap.example.com"),
            account("bob@example.com", "imap example com"),
        ]}));
        let file = parse(&bytes, None).unwrap();
        assert_eq!(file.counts().accounts, 1);
        let ann = &file.accounts[0];
        assert_eq!(
            (ann.title.as_str(), ann.label.as_str()),
            ("Work", "Work <ann@example.com>")
        );
        assert_eq!(ann.servers, "imap.example.com and smtp.example.com (Password)");
        assert!(!ann.has_secret, "a file that is not sealed carries no secret");
        assert!(file.accounts[1].problem.as_deref().unwrap().contains("not an address"));
        assert!(file.accounts[2].problem.as_deref().unwrap().contains("IMAP"));
        assert!(file.data.accounts[1].is_none() && !file.accounts[1].importable);
        let data = file.data.accounts[0].as_ref().unwrap();
        assert!(!data.signature.contains("script"), "{}", data.signature);
        assert_eq!(data.addresses, [("ann@other.example".to_string(), "Ann".to_string())]);
        assert!(data.secret.is_none());
    }

    #[test]
    fn sign_in_apps_rules_and_senders_are_checked() {
        let app = |issuer: &str, token: &str| {
            serde_json::json!({"name": "Acme", "issuer": issuer, "client_id": "c", "scopes": "openid mail",
                "authorize_url": format!("{issuer}/authorize"), "token_url": token,
                "imap": {"host": "imap.acme.example", "port": 993, "security": "tls"},
                "smtp": {"host": "smtp.acme.example", "port": 465, "security": "tls"}, "secret": "s"})
        };
        let bytes = document(serde_json::json!({
            "sign_in_apps": {"google": true, "apps": [
                app("https://login.acme.example", "https://login.acme.example/token"),
                app("https://login.acme.example", "http://evil.example/token"),
                app("http://login.acme.example", "http://login.acme.example/token"),
                app("http://127.0.0.1:8080", "http://127.0.0.1:8080/token"),
            ]},
            "rules": [
                {"name": "", "query": "list:news", "mark_read": true},
                {"name": "folder", "query": "in:inbox from:a", "mark_read": true},
                {"name": "nothing", "query": "from:a"},
                {"name": "moves", "query": "from:b", "move_to": {"account": {"email": "a@x.example", "imap_host": "IMAP.x.example"}, "path": "News"}}
            ],
            "trusted_senders": [{"value": "Shop.Example", "domain": true}, {"value": "a@shop.example"}, {"value": "a@shop.example", "domain": true}, {"value": "x y"}]
        }));
        let file = parse(&bytes, None).unwrap();
        // the endpoints a file names are not read: the issuer's are, at the import
        assert_eq!(file.counts().sign_in_apps, 3);
        assert_eq!(file.data.builtin, [(ProviderKind::Google, true)]);
        assert!(file.data.apps.iter().all(|app| app.secret.is_none()));
        assert_eq!(file.counts().rules, 2);
        assert_eq!(file.data.rules[0].rule.name, "list:news");
        assert_eq!(
            file.data.rules[1].move_to.as_ref().unwrap().account.imap_host,
            "imap.x.example"
        );
        assert_eq!(
            file.data.trusted,
            [
                ("shop.example".to_string(), true),
                ("a@shop.example".to_string(), false)
            ]
        );
        assert_eq!(file.notes.len(), 3, "{:?}", file.notes);
    }
}
