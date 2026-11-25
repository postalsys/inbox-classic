//! The setup file (`Name.inboxclassic`): what a user set up on one computer, to set up another with. Inside it is
//! UTF-8 JSON (`file.rs` has its shape): settings, window preferences, accounts, sign-in apps, contacts, OpenPGP keys,
//! message rules and trusted senders, each part there only when it was chosen. With a passphrase the whole JSON is
//! sealed with it (pe-pgp `sealed`, Argon2id and SEIPDv2), and only then does the file carry secrets: the accounts'
//! passwords and refresh tokens, the sign-in apps' client secrets, and the user's own private keys.
//!
//! Everything read from a setup file is untrusted: the file is refused over [`MAX_FILE`] before it is parsed, a newer
//! format version is refused with words that say to update, and every value is checked as the windows that make it
//! check it (the account form, the sign-in apps window, the vCard reader, the key import) before it is shown or
//! written. Nothing in it names a place on disk: the core writes only to its store and the system's password store.
//!
//! **Never in the file**: messages and every cache, window positions and sizes, the rows of the folder list turned
//! open or closed (they name this store's accounts by id), notes shown once, the AI agents' permissions and whether
//! agents are on (decided on each computer), the store's profile id, and any secret without a passphrase.

mod export;
pub(crate) mod file;
pub(crate) mod import;
#[cfg(test)]
mod round_trips;

use pe_i18n::{Text, tr, tr_args};

pub use file::{SetupAccount, SetupCounts, SetupFile, parse};
pub use import::{ImportChoice, ImportLine, ImportLineKind, ImportSummary};

/// The most a setup file may hold, read or written: a setup with its contacts' pictures is a few megabytes
pub const MAX_FILE: usize = 50 * 1024 * 1024;

/// The version of the format this core writes and reads; a file of a newer one is refused
pub const VERSION: u32 = 1;

/// What the JSON says it is
pub(crate) const FORMAT: &str = "inbox-classic-setup";

/// The file name extension, without its dot
pub const EXTENSION: &str = "inboxclassic";

/// The name an export offers to save as, in the language in use: "Inbox Classic settings and accounts.inboxclassic"
pub fn default_name() -> String {
    format!("{}.{EXTENSION}", tr(Text::SetupFileName))
}

/// `path` with the setup file's extension when it has none
pub fn with_extension(path: &std::path::Path) -> std::path::PathBuf {
    match path.extension() {
        Some(_) => path.to_path_buf(),
        None => path.with_extension(EXTENSION),
    }
}

/// The parts of a setup file, as flags
#[derive(Debug, Clone, Copy, PartialEq, Eq, Default, Hash)]
pub struct Parts(pub u32);

impl Parts {
    pub const NONE: Parts = Parts(0);
    pub const SETTINGS: Parts = Parts(1);
    pub const PREFERENCES: Parts = Parts(2);
    pub const ACCOUNTS: Parts = Parts(4);
    pub const SIGN_IN_APPS: Parts = Parts(8);
    pub const CONTACTS: Parts = Parts(16);
    pub const KEYS: Parts = Parts(32);
    pub const RULES: Parts = Parts(64);
    pub const TRUSTED_SENDERS: Parts = Parts(128);
    pub const ALL: Parts = Parts(255);

    /// Each part, in the order the windows list them
    pub const EACH: [Parts; 8] = [
        Parts::ACCOUNTS,
        Parts::SIGN_IN_APPS,
        Parts::SETTINGS,
        Parts::PREFERENCES,
        Parts::CONTACTS,
        Parts::KEYS,
        Parts::RULES,
        Parts::TRUSTED_SENDERS,
    ];

    pub fn has(self, part: Parts) -> bool {
        self.0 & part.0 == part.0 && part.0 != 0
    }

    pub fn with(self, part: Parts) -> Parts {
        Parts(self.0 | part.0)
    }

    /// Only the parts this core knows
    pub fn known(self) -> Parts {
        Parts(self.0 & Parts::ALL.0)
    }

    pub fn is_empty(self) -> bool {
        self.known().0 == 0
    }

    /// A single part's name, as the windows list it ("Accounts")
    pub fn name(self) -> String {
        tr(match self {
            Parts::SETTINGS => Text::SetupPartSettings,
            Parts::PREFERENCES => Text::SetupPartPreferences,
            Parts::ACCOUNTS => Text::SetupPartAccounts,
            Parts::SIGN_IN_APPS => Text::SetupPartSignInApps,
            Parts::CONTACTS => Text::SetupPartContacts,
            Parts::KEYS => Text::SetupPartKeys,
            Parts::RULES => Text::SetupPartRules,
            _ => Text::SetupPartTrustedSenders,
        })
    }
}

/// What kind of value an app preference takes, and how it is written as text
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum PrefKind {
    /// `1` or `0`
    Bool,
    /// A number from 0 to the one given (`2` for the layout: automatic, classic, columns as `PeLayoutMode`)
    Number(u32),
    /// The code of a language there is a catalog of (`de`), or empty for the system's language
    Language,
}

/// The app preferences a setup file carries, by the names the three apps share; each app keeps them in its own place
/// (the registry, the user defaults, settings.ini) and hands them in and takes them back by these names; the values a
/// file gives back are checked, ready to apply, in this order, the language last. Left out:
/// the widths and heights of the panes and the window (each screen differs), the rows of the folder list turned open
/// or closed (they name this store's accounts), and the notes shown once (the tray, the dock, the column layout).
pub const PREFERENCES: [(&str, PrefKind); 11] = [
    ("notify_new_mail", PrefKind::Bool),
    ("codes_in_notifications", PrefKind::Bool),
    ("group_by_conversation", PrefKind::Bool),
    ("show_whole_conversation", PrefKind::Bool),
    // 0 oldest first, 1 newest first
    ("conversation_order", PrefKind::Number(1)),
    ("hide_ignored", PrefKind::Bool),
    ("hide_read", PrefKind::Bool),
    ("folder_list", PrefKind::Bool),
    ("list_pictures", PrefKind::Bool),
    ("layout", PrefKind::Number(2)),
    ("language", PrefKind::Language),
];

/// Whether a preference counts only once the app starts again (the language), which the import window says
pub fn pref_restarts(name: &str) -> bool {
    PREFERENCES
        .iter()
        .any(|(known, kind)| *known == name && *kind == PrefKind::Language)
}

/// `value` as preference `name` keeps it, None when there is no such preference or the value is not one of it
pub fn pref_value(name: &str, value: &str) -> Option<String> {
    let (_, kind) = PREFERENCES.iter().find(|(known, _)| *known == name)?;
    let value = value.trim();
    match kind {
        PrefKind::Bool => matches!(value, "0" | "1").then(|| value.to_string()),
        PrefKind::Number(max) => value.parse::<u32>().ok().filter(|n| n <= max).map(|n| n.to_string()),
        PrefKind::Language if value.is_empty() => Some(String::new()),
        PrefKind::Language => pe_i18n::supported(value)
            .filter(|code| *code != "qps")
            .map(str::to_string),
    }
}

/// Why a setup file could not be read
#[derive(Debug, Clone, PartialEq, Eq)]
pub enum SetupError {
    /// It is sealed with a passphrase, and none was given
    NeedsPassphrase,
    /// The passphrase given does not open it
    WrongPassphrase,
    /// Anything else, in words: not a setup file, damaged, changed, too large, from a newer version
    Invalid(String),
}

impl SetupError {
    /// In words, to show the user
    pub fn text(&self) -> String {
        match self {
            SetupError::NeedsPassphrase => tr(Text::SetupErrorNeedsPassphrase),
            SetupError::WrongPassphrase => tr(Text::SetupErrorWrongPassphrase),
            SetupError::Invalid(words) => words.clone(),
        }
    }

    pub(crate) fn invalid(text: Text) -> SetupError {
        SetupError::Invalid(tr(text))
    }
}

impl std::fmt::Display for SetupError {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        f.write_str(&self.text())
    }
}

impl std::error::Error for SetupError {}

/// "3 accounts", a count of a part in words
pub(crate) fn count_text(text: Text, count: usize) -> String {
    tr_args(text, &[("count", count.into())])
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn preferences_are_checked() {
        assert_eq!(pref_value("hide_read", "1").as_deref(), Some("1"));
        assert_eq!(pref_value("hide_read", "yes"), None);
        assert_eq!(pref_value("layout", "2").as_deref(), Some("2"));
        assert_eq!(pref_value("layout", "3"), None);
        assert_eq!(pref_value("language", "de").as_deref(), Some("de"));
        assert_eq!(pref_value("language", "").as_deref(), Some(""));
        assert_eq!(pref_value("language", "xx"), None);
        assert_eq!(pref_value("language", "qps"), None);
        assert_eq!(pref_value("TreeWidth", "200"), None);
    }

    #[test]
    fn file_names() {
        assert!(default_name().ends_with(".inboxclassic"));
        let path = std::path::Path::new("/tmp/Ann");
        assert_eq!(with_extension(path), std::path::Path::new("/tmp/Ann.inboxclassic"));
        let named = std::path::Path::new("/tmp/Ann.setup");
        assert_eq!(with_extension(named), named);
        assert!(pref_restarts("language") && !pref_restarts("layout"));
        assert_eq!(PREFERENCES.last().unwrap().0, "language");
    }

    #[test]
    fn parts_have_names() {
        for part in Parts::EACH {
            assert!(!part.name().is_empty());
            assert!(Parts::ALL.has(part));
        }
        assert!(!Parts::NONE.has(Parts::NONE));
        assert!(Parts(1024).is_empty());
        assert_eq!(Parts::ACCOUNTS.with(Parts::RULES), Parts(68));
    }
}
