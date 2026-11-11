//! The words of the windows in the language the user chose: the Fluent catalogs of `core/locales`, built in, one set of
//! files a language (`core.ftl` for what the core says, `app.ftl` for the windows of every platform), English the one
//! the others fall back to word by word. `qps` is a pseudo-language made from English, longer and bracketed, for the
//! UI tests to find words that are not in the catalog and layouts too narrow for longer languages.
#![forbid(unsafe_code)]

use std::sync::{Arc, OnceLock, RwLock};

use fluent_bundle::concurrent::FluentBundle;
use fluent_bundle::{FluentArgs, FluentResource, FluentValue};

include!(concat!(env!("OUT_DIR"), "/texts.rs"));

/// The languages there is a catalog of, by code, with their names in themselves, as the language choice lists them
pub const LANGUAGES: &[(&str, &str)] = &[
    ("en", "English"),
    ("de", "Deutsch"),
    ("et", "Eesti"),
    ("es", "Español"),
    ("fr", "Français"),
];

/// The pseudo-language for tests
pub const PSEUDO: &str = "qps";

type Bundle = FluentBundle<FluentResource>;

struct Language {
    code: &'static str,
    bundle: Arc<Bundle>,
}

fn bundle(code: &str) -> Bundle {
    let tag: unic_langid::LanguageIdentifier = code.parse().unwrap_or_default();
    let mut bundle = Bundle::new_concurrent(vec![tag]);
    // the windows show the words as they are, without the marks that keep a name's direction apart
    bundle.set_use_isolating(false);
    if let Some((_, files)) = CATALOGS.iter().find(|(c, _)| *c == code) {
        for file in *files {
            let resource = FluentResource::try_new(file.to_string()).unwrap_or_else(|(resource, _)| resource);
            // a message in two files: the first one stays (the tests make sure there is none)
            let _ = bundle.add_resource(resource);
        }
    }
    bundle
}

fn english() -> &'static Arc<Bundle> {
    static ENGLISH: OnceLock<Arc<Bundle>> = OnceLock::new();
    ENGLISH.get_or_init(|| Arc::new(bundle("en")))
}

fn current() -> &'static RwLock<Option<Language>> {
    static CURRENT: RwLock<Option<Language>> = RwLock::new(None);
    &CURRENT
}

/// The code of the catalog for a language tag (`de-AT`, `de_DE.UTF-8`, `et`), the pseudo-language included; None for
/// a language there is none of
pub fn supported(tag: &str) -> Option<&'static str> {
    let primary = tag
        .split(['-', '_', '.', '@'])
        .next()
        .unwrap_or_default()
        .to_ascii_lowercase();
    if primary == PSEUDO {
        return Some(PSEUDO);
    }
    LANGUAGES.iter().map(|(code, _)| *code).find(|code| *code == primary)
}

/// The language for the system's preferred languages, the first one there is a catalog of, English when none
pub fn resolve<S: AsRef<str>>(preferred: &[S]) -> &'static str {
    preferred
        .iter()
        .filter_map(|tag| supported(tag.as_ref()).filter(|code| *code != PSEUDO))
        .next()
        .unwrap_or("en")
}

/// Uses the catalog of `code` from now on (English for one there is none of); returns the code used
pub fn set_language(code: &str) -> &'static str {
    let code = supported(code).unwrap_or("en");
    let bundle = if code == "en" || code == PSEUDO {
        english().clone()
    } else {
        Arc::new(bundle(code))
    };
    *current().write().unwrap_or_else(|e| e.into_inner()) = Some(Language { code, bundle });
    code
}

/// The code of the language in use, `en` before one was set
pub fn language() -> &'static str {
    current()
        .read()
        .unwrap_or_else(|e| e.into_inner())
        .as_ref()
        .map_or("en", |l| l.code)
}

/// A value for a placeable of a message: a name, or a number (plurals are chosen by it)
#[derive(Debug, Clone, PartialEq)]
pub enum Arg<'a> {
    Str(&'a str),
    Num(i64),
}

impl<'a> From<&'a str> for Arg<'a> {
    fn from(value: &'a str) -> Self {
        Arg::Str(value)
    }
}

impl<'a> From<&'a String> for Arg<'a> {
    fn from(value: &'a String) -> Self {
        Arg::Str(value)
    }
}

impl From<i64> for Arg<'_> {
    fn from(value: i64) -> Self {
        Arg::Num(value)
    }
}

impl From<u64> for Arg<'_> {
    fn from(value: u64) -> Self {
        Arg::Num(i64::try_from(value).unwrap_or(i64::MAX))
    }
}

impl From<usize> for Arg<'_> {
    fn from(value: usize) -> Self {
        Arg::Num(i64::try_from(value).unwrap_or(i64::MAX))
    }
}

impl From<i32> for Arg<'_> {
    fn from(value: i32) -> Self {
        Arg::Num(i64::from(value))
    }
}

impl From<u32> for Arg<'_> {
    fn from(value: u32) -> Self {
        Arg::Num(i64::from(value))
    }
}

/// `text` in the language in use
pub fn tr(text: Text) -> String {
    tr_args(text, &[])
}

/// `text` in the language in use, its placeables filled from `args`
pub fn tr_args(text: Text, args: &[(&str, Arg)]) -> String {
    let (code, bundle) = {
        let current = current().read().unwrap_or_else(|e| e.into_inner());
        match current.as_ref() {
            Some(l) => (l.code, l.bundle.clone()),
            None => ("en", english().clone()),
        }
    };
    let formatted = format(&bundle, text.id(), args).or_else(|| format(english(), text.id(), args));
    let formatted = formatted.unwrap_or_else(|| text.id().to_string());
    if code == PSEUDO { pseudo(&formatted) } else { formatted }
}

fn format(bundle: &Bundle, id: &str, args: &[(&str, Arg)]) -> Option<String> {
    let pattern = bundle.get_message(id)?.value()?;
    let mut fluent_args = FluentArgs::new();
    for (name, value) in args {
        match value {
            Arg::Str(s) => fluent_args.set(*name, FluentValue::from(*s)),
            Arg::Num(n) => fluent_args.set(*name, FluentValue::from(*n)),
        }
    }
    let mut errors = Vec::new();
    let text = bundle.format_pattern(pattern, Some(&fluent_args), &mut errors);
    Some(text.into_owned())
}

/// English made to look foreign and 40% longer, in brackets: `[Ḿöṽé ţö Ƒöļðéŕ... ~~~~~]`. Mnemonic marks (`&`) and
/// what the code put in (names, numbers) stay readable enough to test with.
pub fn pseudo(text: &str) -> String {
    let mut out = String::with_capacity(text.len() * 2);
    out.push('[');
    for c in text.chars() {
        out.push(match c {
            'a' => 'á',
            'e' => 'é',
            'i' => 'í',
            'o' => 'ö',
            'u' => 'ü',
            'c' => 'ç',
            'n' => 'ñ',
            'y' => 'ý',
            'A' => 'Å',
            'E' => 'É',
            'I' => 'Î',
            'O' => 'Ö',
            'U' => 'Ü',
            'C' => 'Ç',
            'N' => 'Ñ',
            other => other,
        });
    }
    let letters = text.chars().filter(|c| c.is_alphabetic()).count();
    if letters > 0 {
        out.push(' ');
        out.extend(std::iter::repeat_n('~', (letters * 2).div_ceil(5)));
    }
    out.push(']');
    out
}

/// A menu label of the catalog (`&Reply to Sender`, `&&` for an ampersand) without its mnemonic mark, as the Mac
/// shows it
pub fn without_mnemonic(label: &str) -> String {
    let mut out = String::with_capacity(label.len());
    let mut chars = label.chars().peekable();
    while let Some(c) = chars.next() {
        if c == '&' {
            if chars.peek() == Some(&'&') {
                out.push('&');
                chars.next();
            }
            continue;
        }
        out.push(c);
    }
    out
}

/// A picture with words in it, in the language in use: `brands/google-sign-in.png` is `brands/google-sign-in.de.png` in
/// German (`scripts/build-sign-in-buttons.sh` makes them), the English one in English and the pseudo-language
pub fn localized_picture(name: &str) -> String {
    let language = language();
    match name.rsplit_once('.') {
        Some((stem, extension)) if language != "en" && language != PSEUDO => format!("{stem}.{language}.{extension}"),
        _ => name.to_string(),
    }
}

/// Command `text` as the title of the window it opens: without its mnemonic mark and the dots that say it asks for
/// more ("&Import Messages..." is titled "Import Messages")
pub fn title(text: Text) -> String {
    let title = without_mnemonic(&tr(text));
    // in the pseudo-language the dots come before its padding: "[Óptíöñš... ~~~~]"
    let (body, padding) = match title.rfind(" ~") {
        Some(at) if title.ends_with('~') || title.ends_with("~]") => title.split_at(at),
        _ => (title.as_str(), ""),
    };
    format!("{}{padding}", body.trim_end_matches(['.', '\u{2026}']).trim_end())
}

/// A menu label of the catalog with GTK's mnemonic mark (`_Reply to Sender`)
pub fn gtk_mnemonic(label: &str) -> String {
    let mut out = String::with_capacity(label.len() + 1);
    let mut chars = label.chars().peekable();
    while let Some(c) = chars.next() {
        match c {
            '&' if chars.peek() == Some(&'&') => {
                out.push('&');
                chars.next();
            }
            '&' => out.push('_'),
            '_' => out.push_str("__"),
            other => out.push(other),
        }
    }
    out
}

#[cfg(test)]
mod tests;
