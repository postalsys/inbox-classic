//! The words of the windows, from the core's catalogs (core/locales) in the language in use: `t!(UiFindHint)`, or
//! with what goes into the words, `t!(GtkFrom, account = &label)`. The language is chosen at the start ([`choose`]).

pub use pe_core::i18n::{Arg, Text};

/// A text of the catalogs in the language in use, its three dots the ellipsis GNOME writes ("Properties…")
pub fn tr(text: Text) -> String {
    pe_core::i18n::tr(text).replace("...", "\u{2026}")
}

/// [`tr`] with what goes into the words
pub fn tr_args(text: Text, args: &[(&str, Arg)]) -> String {
    pe_core::i18n::tr_args(text, args).replace("...", "\u{2026}")
}

/// A word or sentence of the catalogs, by its id as the `Text` enum names it, with its placeables filled
macro_rules! t {
    ($id:ident) => {
        $crate::words::tr($crate::words::Text::$id)
    };
    ($id:ident, $($name:ident = $value:expr),+ $(,)?) => {
        $crate::words::tr_args(
            $crate::words::Text::$id,
            &[$((stringify!($name), $crate::words::Arg::from($value))),+],
        )
    };
}

/// The languages of the system, most wanted first: LANGUAGE (a list), then LC_ALL, LC_MESSAGES and LANG, as gettext
/// reads them; "C" and "POSIX" say nothing
pub fn system_languages() -> Vec<String> {
    let mut found = Vec::new();
    if let Ok(list) = std::env::var("LANGUAGE") {
        found.extend(list.split(':').filter(|l| !l.is_empty()).map(str::to_string));
    }
    for name in ["LC_ALL", "LC_MESSAGES", "LANG"] {
        if let Ok(value) = std::env::var(name)
            && !value.is_empty()
        {
            found.push(value);
            break;
        }
    }
    found.retain(|l| l != "C" && l != "POSIX" && !l.starts_with("C."));
    found
}

/// The language the system would give the app: the first of its languages there is a catalog of, English otherwise
pub fn system_language() -> &'static str {
    pe_core::i18n::resolve(&system_languages())
}

/// Chooses the language of the windows before any is made: `wanted` (the --language option, or the one chosen in
/// Preferences) when there is a catalog of it, the system's otherwise
pub fn choose(wanted: Option<&str>) -> &'static str {
    match wanted.and_then(pe_core::i18n::supported) {
        Some(code) => pe_core::i18n::set_language(code),
        None => pe_core::i18n::set_language(system_language()),
    }
}

/// The name of a language in itself ("Deutsch"), for the language choice
pub fn language_name(code: &str) -> &'static str {
    pe_core::i18n::LANGUAGES
        .iter()
        .find(|(c, _)| *c == code)
        .map_or("English", |(_, name)| *name)
}

/// A menu label of the catalogs without its mnemonic mark ("&Reply to Sender" as "Reply to Sender")
pub fn plain(text: Text) -> String {
    pe_core::i18n::without_mnemonic(&tr(text))
}

/// A field's label as a row's title: without the colon the catalogs give it ("First name:", "Nom :"), as GNOME has
/// them
pub fn field_title(text: Text) -> String {
    plain(text).trim_end_matches(':').trim_end().to_string()
}

/// Command `text` as the title of the window it opens, without its trailing dots
pub fn title(text: Text) -> String {
    pe_core::i18n::title(text)
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn words_with_their_values() {
        pe_core::i18n::set_language("en");
        assert_eq!(t!(UiNewFolderIn, folder = "Archive"), "The new folder goes in Archive.");
        assert_eq!(t!(GtkUnreadMessages, count = 0u64), "No unread messages");
        assert_eq!(t!(GtkUnreadMessages, count = 3u64), "3 unread messages");
        // a blank line inside a message is kept
        assert!(t!(GtkPlainWarning).ends_with("network.\n\nContinue?"));
        assert_eq!(plain(Text::CmdOptions), "Options\u{2026}");
    }

    #[test]
    fn language_names() {
        assert_eq!(language_name("de"), "Deutsch");
        assert_eq!(language_name("xx"), "English");
    }
}
