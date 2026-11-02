//! Which folder is Sent, Drafts, Trash and so on. The SPECIAL-USE flags of the server decide when
//! it has them (RFC 6154); otherwise the folder name is matched against the localized names other
//! clients create, from imapflow's tables (special_use_names.rs). A port of imapflow's
//! `special-use.ts` and of the way its LIST picks one folder per flag.

use std::collections::HashMap;
use std::sync::LazyLock;

use unicode_normalization::UnicodeNormalization;

use crate::special_use_names::{GENERIC_TOKENS, NAMES};

/// A special-use folder. The order is the display order, Inbox first.
#[derive(Debug, Clone, Copy, PartialEq, Eq, PartialOrd, Ord, Hash)]
pub enum SpecialUse {
    Inbox,
    Flagged,
    Sent,
    Drafts,
    All,
    Archive,
    Junk,
    Trash,
}

impl SpecialUse {
    pub const ALL: [SpecialUse; 8] = [
        SpecialUse::Inbox,
        SpecialUse::Flagged,
        SpecialUse::Sent,
        SpecialUse::Drafts,
        SpecialUse::All,
        SpecialUse::Archive,
        SpecialUse::Junk,
        SpecialUse::Trash,
    ];

    /// The flag of RFC 6154, `\Sent`
    pub fn flag(self) -> &'static str {
        match self {
            SpecialUse::Inbox => "\\Inbox",
            SpecialUse::Flagged => "\\Flagged",
            SpecialUse::Sent => "\\Sent",
            SpecialUse::Drafts => "\\Drafts",
            SpecialUse::All => "\\All",
            SpecialUse::Archive => "\\Archive",
            SpecialUse::Junk => "\\Junk",
            SpecialUse::Trash => "\\Trash",
        }
    }

    pub fn from_flag(flag: &str) -> Option<Self> {
        Self::ALL
            .into_iter()
            .find(|use_| use_.flag().eq_ignore_ascii_case(flag))
    }
}

/// How a special-use flag was found, the better sources first
#[derive(Debug, Clone, Copy, PartialEq, Eq, PartialOrd, Ord)]
pub enum Source {
    /// The server's SPECIAL-USE (or XLIST) flag
    Extension,
    /// The folder name is a known name
    Name,
    /// A known name decorated with generic words, "Sent Mail"
    NameGuess,
}

static NAME_INDEX: LazyLock<HashMap<&'static str, SpecialUse>> = LazyLock::new(|| {
    NAMES
        .iter()
        .filter_map(|(flag, names)| Some((SpecialUse::from_flag(flag)?, names)))
        .flat_map(|(use_, names)| names.iter().map(move |name| (*name, use_)))
        .collect()
});

/// Lowercase, without direction marks, NFKC: the form the tables are in
fn fold(name: &str) -> String {
    name.to_lowercase()
        .replace(['\u{200e}', '\u{200f}'], "")
        .trim()
        .nfkc()
        .collect()
}

fn is_separator(c: char) -> bool {
    c.is_whitespace() || matches!(c, '-' | '_' | '/' | '.' | ',' | '(' | ')' | '[' | ']')
}

/// The special-use flag of a folder, from its LIST flags or its name (the last path component)
pub fn detect(has_extension: bool, flags: &[String], name: &str) -> Option<(SpecialUse, Source)> {
    if has_extension {
        // \Inbox is not a LIST flag, INBOX is found by its name
        let found = SpecialUse::ALL[1..]
            .iter()
            .find(|use_| flags.iter().any(|listed| listed.eq_ignore_ascii_case(use_.flag())));
        if let Some(use_) = found {
            return Some((*use_, Source::Extension));
        }
    }
    let name = fold(name);
    if let Some(use_) = NAME_INDEX.get(name.as_str()) {
        return Some((*use_, Source::Name));
    }
    // a known name decorated with generic words: stripping them has to leave exactly one word,
    // and that word has to be a known name
    let core: Vec<&str> = name
        .split(is_separator)
        .filter(|t| !t.is_empty() && !GENERIC_TOKENS.contains(t))
        .collect();
    if let [word] = core.as_slice()
        && *word != name
    {
        return NAME_INDEX.get(word).map(|use_| (*use_, Source::NameGuess));
    }
    None
}

#[cfg(test)]
mod tests {
    use super::*;

    fn flags(list: &[&str]) -> Vec<String> {
        list.iter().map(|f| f.to_string()).collect()
    }

    #[test]
    fn extension_flags_win() {
        assert_eq!(
            detect(true, &flags(&["\\HasNoChildren", "\\sent"]), "Whatever"),
            Some((SpecialUse::Sent, Source::Extension))
        );
        // without the extension the flags are not trusted
        assert_eq!(detect(false, &flags(&["\\Sent"]), "Whatever"), None);
    }

    #[test]
    fn localized_names() {
        assert_eq!(
            detect(false, &[], "Gesendete Elemente"),
            Some((SpecialUse::Sent, Source::Name))
        );
        assert_eq!(
            detect(false, &[], "Отправленные"),
            Some((SpecialUse::Sent, Source::Name))
        );
        assert_eq!(
            detect(false, &[], "Sent Mail"),
            Some((SpecialUse::Sent, Source::NameGuess))
        );
        assert_eq!(
            detect(false, &[], "\u{200e}Trash"),
            Some((SpecialUse::Trash, Source::Name))
        );
        assert_eq!(detect(false, &[], "Sent to clients"), None);
        assert_eq!(detect(false, &[], "Projects"), None);
    }
}
