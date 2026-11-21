//! The words of the windows in the language the user chose: the Fluent catalogs of `core/locales`, built in, one set of
//! files a language (`core.ftl` for what the core says, `app.ftl` for the windows of every platform), English the one
//! the others fall back to word by word. `qps` is a pseudo-language made from English, longer and bracketed, for the
//! UI tests to find words that are not in the catalog and layouts too narrow for longer languages.
#![forbid(unsafe_code)]

use std::sync::{Arc, OnceLock, RwLock};

use fluent_bundle::concurrent::FluentBundle;
use fluent_bundle::{FluentArgs, FluentResource, FluentValue};

include!(concat!(env!("OUT_DIR"), "/texts.rs"));

/// The languages there is a catalog of, by tag, with their names in themselves, as the language choice lists them: the
/// language's two letters, with a region (`pt-BR`) or a script (`sr-Latn`) for one written differently there.
/// Everything made per language follows this list: the installer's languages and words, the sign-in buttons, the
/// Linux desktop entry and metainfo, the Mac's localizations and Help Book, the homepage's help, the UI tests (the
/// scripts read it from `core/include/languages.tsv`, which pe-ffi's build writes).
pub const LANGUAGES: &[(&str, &str)] = &[
    ("en", "English"),
    ("id", "Bahasa Indonesia"),
    ("ca", "Català"),
    ("cs", "Čeština"),
    ("da", "Dansk"),
    ("de", "Deutsch"),
    ("et", "Eesti"),
    ("es", "Español"),
    ("fr", "Français"),
    ("hr", "Hrvatski"),
    ("it", "Italiano"),
    ("lv", "Latviešu"),
    ("lt", "Lietuvių"),
    ("hu", "Magyar"),
    ("nl", "Nederlands"),
    ("nb", "Norsk bokmål"),
    ("pl", "Polski"),
    ("pt-BR", "Português (Brasil)"),
    ("pt", "Português (Portugal)"),
    ("ro", "Română"),
    ("sk", "Slovenčina"),
    ("sl", "Slovenščina"),
    ("sr-Latn", "Srpski"),
    ("fi", "Suomi"),
    ("sv", "Svenska"),
    ("vi", "Tiếng Việt"),
    ("tr", "Türkçe"),
    ("el", "Ελληνικά"),
    ("bg", "Български"),
    ("ru", "Русский"),
    ("uk", "Українська"),
    ("ja", "日本語"),
    // Simplified first: a system that says only `zh` gets it
    ("zh-Hans", "简体中文"),
    ("zh-Hant", "繁體中文"),
    ("ko", "한국어"),
];

/// The pseudo-language for tests
pub const PSEUDO: &str = "qps";

type Bundle = FluentBundle<FluentResource>;

struct Language {
    code: &'static str,
    bundle: Arc<Bundle>,
}

/// The locale a catalog's plurals follow: `pt` is the Portuguese of Portugal, where only 1 is `one`, `pt-BR` Brazil's,
/// CLDR's `pt`, where 0 is `one` too; the others are their own tags
fn locale(code: &str) -> &str {
    match code {
        "pt" => "pt-PT",
        "pt-BR" => "pt",
        other => other,
    }
}

fn bundle(code: &str) -> Bundle {
    let tag: unic_langid::LanguageIdentifier = locale(code).parse().unwrap_or_default();
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

/// The code of the catalog for a language tag (`de-AT`, `de_DE.UTF-8`, `pt-BR`, `sr-Latn-RS`, `sr_RS@latin`, `et`),
/// the pseudo-language included; None for a language there is none of. The language first (`no` is Norwegian
/// Bokmål's `nb`), then of its catalogs the one of the tag's region or script, then the language's own (`pt`, for
/// Portugal, Angola and the rest), then its first: every Serbian gets `sr-Latn`, whichever script the system writes.
pub fn supported(tag: &str) -> Option<&'static str> {
    // the encoding (`.UTF-8`) and the modifier (`@latin`) say nothing of the language
    let tag = tag.split(['.', '@']).next().unwrap_or_default();
    let mut parts = tag.split(['-', '_']);
    let primary = parts.next().unwrap_or_default().to_ascii_lowercase();
    if primary == PSEUDO {
        return Some(PSEUDO);
    }
    let primary = ALIASES
        .iter()
        .find(|(alias, _)| *alias == primary)
        .map_or(primary.as_str(), |(_, language)| language);
    let same = || {
        LANGUAGES
            .iter()
            .map(|(code, _)| *code)
            .filter(move |code| code.split('-').next() == Some(primary))
    };
    let mut subtags: Vec<&str> = parts.collect();
    // Chinese is told by its script, which a system names by its region more often (`zh-TW`, `zh_HK.UTF-8`)
    if let Some((_, _, script)) = REGION_SCRIPTS
        .iter()
        .find(|(language, region, _)| *language == primary && subtags.iter().any(|s| s.eq_ignore_ascii_case(region)))
    {
        subtags.push(script);
    }
    same()
        .find(|code| {
            code.split_once('-')
                .is_some_and(|(_, own)| subtags.iter().any(|s| s.eq_ignore_ascii_case(own)))
        })
        .or_else(|| same().find(|code| !code.contains('-')))
        .or_else(|| same().next())
}

/// Languages a system may name by another code: Norwegian (`no`) is Bokmål's `nb`, Indonesian's old code `in` is `id`
pub const ALIASES: &[(&str, &str)] = &[("no", "nb"), ("in", "id")];

/// The script a language is written in by region, where a system's tag names the region and not the script:
/// Traditional Chinese in Taiwan, Hong Kong and Macau (Simplified elsewhere, the first of Chinese's catalogs)
const REGION_SCRIPTS: &[(&str, &str, &str)] = &[("zh", "TW", "Hant"), ("zh", "HK", "Hant"), ("zh", "MO", "Hant")];

/// The face the Windows app draws its windows' words in for language `code`, None for the system's default: for
/// Chinese, Japanese and Korean the one Windows itself uses in that language, so an English Windows shows them in their
/// own font rather than one font linking happens to find
pub fn windows_font(code: &str) -> Option<&'static str> {
    match code {
        "ja" => Some("Yu Gothic UI"),
        "zh-Hans" => Some("Microsoft YaHei UI"),
        "zh-Hant" => Some("Microsoft JhengHei UI"),
        "ko" => Some("Malgun Gothic"),
        _ => None,
    }
}

/// A tag's parts, by BCP 47: the language, and after it a script (four letters, `Latn`) and a region (two letters or
/// three digits, `BR`)
#[derive(Debug, Clone, Copy, PartialEq, Eq, Default)]
pub struct Tag<'a> {
    pub language: &'a str,
    pub script: Option<&'a str>,
    pub region: Option<&'a str>,
}

impl<'a> Tag<'a> {
    /// The parts of `tag` (`sr-Latn-RS`, `pt_BR`); a subtag that is neither a script nor a region is left out
    pub fn parse(tag: &'a str) -> Tag<'a> {
        let mut parts = tag.split(['-', '_']);
        let mut parsed = Tag {
            language: parts.next().unwrap_or_default(),
            ..Default::default()
        };
        for part in parts {
            let letters = part.bytes().all(|b| b.is_ascii_alphabetic());
            match part.len() {
                4 if letters && parsed.script.is_none() => parsed.script = Some(part),
                2 if letters => parsed.region = Some(part),
                3 if part.bytes().all(|b| b.is_ascii_digit()) => parsed.region = Some(part),
                _ => {}
            }
        }
        parsed
    }
}

/// A tag of [`LANGUAGES`] as gettext and the freedesktop files write a locale (Linux's desktop entry, its metainfo, the
/// help folders of Yelp): the region after an underscore, the script as a modifier, `pt_BR`, `sr@latin`
pub fn gettext_locale(code: &str) -> String {
    // Chinese by the region of its script, as the desktops name it
    match code {
        "zh-Hans" => return "zh_CN".to_string(),
        "zh-Hant" => return "zh_TW".to_string(),
        _ => {}
    }
    let tag = Tag::parse(code);
    let mut locale = tag.language.to_string();
    if let Some(region) = tag.region {
        locale.push('_');
        locale.push_str(region);
    }
    if let Some(script) = tag.script {
        locale.push('@');
        match script {
            "Latn" => locale.push_str("latin"),
            "Cyrl" => locale.push_str("cyrillic"),
            other => locale.push_str(&other.to_ascii_lowercase()),
        }
    }
    locale
}

/// The locale of the dates of the windows in language `code` (an ICU identifier: `de_EE`, `pt_BR`, `sr_Latn_RS`): the
/// language and its script, and its own region or else the system's `region`; the pseudo-language's English
pub fn date_locale(code: &str, region: Option<&str>) -> String {
    let code = if code == PSEUDO { "en" } else { code };
    let tag = Tag::parse(code);
    [Some(tag.language), tag.script, tag.region.or(region)]
        .into_iter()
        .flatten()
        .filter(|part| !part.is_empty())
        .collect::<Vec<_>>()
        .join("_")
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

/// A language's catalog, made once for [`message_in`] and [`translated`]
type Loaded = (&'static str, Arc<Bundle>);

/// The catalog of `code` (a code of [`LANGUAGES`]), made the first time it is asked for
fn loaded(code: &'static str) -> Arc<Bundle> {
    static BUNDLES: OnceLock<std::sync::Mutex<Vec<Loaded>>> = OnceLock::new();
    let mut bundles = BUNDLES
        .get_or_init(Default::default)
        .lock()
        .unwrap_or_else(|e| e.into_inner());
    if let Some((_, bundle)) = bundles.iter().find(|(c, _)| *c == code) {
        return bundle.clone();
    }
    let made = if code == "en" {
        english().clone()
    } else {
        Arc::new(bundle(code))
    };
    bundles.push((code, made.clone()));
    made
}

/// The message `id` of the catalog of `language` (English for a message or language it has not), without its
/// placeables filled: what the help names a control by. None for an id no catalog has.
pub fn message_in(language: &str, id: &str) -> Option<String> {
    let code = supported(language).filter(|code| *code != PSEUDO).unwrap_or("en");
    or_english(&loaded(code), id, &[])
}

/// The message `id` of `bundle`, or English's when the bundle lacks it: a message not translated yet shows in English
fn or_english(bundle: &Bundle, id: &str, args: &[(&str, Arg)]) -> Option<String> {
    format(bundle, id, args).or_else(|| format(english(), id, args))
}

/// The message `id` of the catalog of `language` itself, its placeables filled from `args`: None when that catalog
/// does not have it (no English in its place) or the language is not one of [`LANGUAGES`]. For the files made per
/// language at build time, which leave out a language's line rather than repeat the English one.
pub fn translated(language: &str, id: &str, args: &[(&str, Arg)]) -> Option<String> {
    let code = supported(language).filter(|code| *code != PSEUDO)?;
    format(&loaded(code), id, args)
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
    if code == PSEUDO {
        return pseudo_args(&bundle, text, args);
    }
    or_english(&bundle, text.id(), args).unwrap_or_else(|| text.id().to_string())
}

/// `text` in the pseudo-language: its own words accented and padded, what goes into them (a name, an address, a
/// subject) as it is, so the windows show the user's data unchanged. Each string value is a marker while the words are
/// made over, then put back.
fn pseudo_args(bundle: &Bundle, text: Text, args: &[(&str, Arg)]) -> String {
    let markers: Vec<String> = (0..args.len())
        .map(|index| format!("\u{E000}{index}\u{E001}"))
        .collect();
    // a value that chooses the words (`{ $color -> [red] ...}`) goes in as it is, or every choice would be the default
    let selectors = selectors(bundle, text.id());
    let stand_ins: Vec<(&str, Arg)> = args
        .iter()
        .zip(&markers)
        .map(|((name, value), marker)| match value {
            Arg::Str(_) if selectors.iter().any(|s| s == name) => (*name, value.clone()),
            Arg::Str(_) => (*name, Arg::Str(marker)),
            Arg::Num(n) => (*name, Arg::Num(*n)),
        })
        .collect();
    let formatted = format(bundle, text.id(), &stand_ins)
        .or_else(|| format(english(), text.id(), &stand_ins))
        .unwrap_or_else(|| text.id().to_string());
    let mut out = pseudo(&formatted);
    for ((_, value), marker) in args.iter().zip(&markers) {
        if let Arg::Str(value) = value {
            out = out.replace(marker.as_str(), value);
        }
    }
    out
}

/// The variables a message chooses its words by (`{ $color -> ...}`), in the language's catalog or else English
fn selectors(bundle: &Bundle, id: &str) -> Vec<String> {
    use fluent_syntax::ast::{Expression, InlineExpression, Pattern, PatternElement};
    fn walk(pattern: &Pattern<&str>, out: &mut Vec<String>) {
        for element in &pattern.elements {
            if let PatternElement::Placeable {
                expression: Expression::Select { selector, variants },
            } = element
            {
                if let InlineExpression::VariableReference { id } = selector {
                    out.push(id.name.to_string());
                }
                for variant in variants {
                    walk(&variant.value, out);
                }
            }
        }
    }
    let mut out = Vec::new();
    let message = bundle.get_message(id).or_else(|| english().get_message(id));
    if let Some(pattern) = message.and_then(|m| m.value()) {
        walk(pattern, &mut out);
    }
    out
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
    // a command line option (`--name`) is typed as it is, so it stays as it is
    let mut option = false;
    let mut previous = ' ';
    let mut chars = text.chars().peekable();
    while let Some(c) = chars.next() {
        if c.is_whitespace() {
            option = false;
        } else if c == '-' && previous.is_whitespace() && chars.peek() == Some(&'-') {
            option = true;
        }
        previous = c;
        if option {
            out.push(c);
            continue;
        }
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
/// shows it. Japanese, Chinese and Korean write the letter in brackets after the words (`ファイル(&F)`, as their
/// Windows does): the bracket goes as a whole, with a space before it, as Apple's own menus in those languages have it
pub fn without_mnemonic(label: &str) -> String {
    let label = without_bracketed_mnemonic(label);
    let label = label.as_str();
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

/// `label` without a bracketed mnemonic (`(&F)`, a space before it or not) where its words end or before their
/// trailing dots and colon (`開く(&O)...`); unchanged without one
fn without_bracketed_mnemonic(label: &str) -> String {
    let Some(open) = label.find("(&") else {
        return label.to_string();
    };
    let rest = &label[open + 2..];
    let mut chars = rest.chars();
    let (Some(letter), Some(')')) = (chars.next(), chars.next()) else {
        return label.to_string();
    };
    if !letter.is_ascii_alphanumeric() {
        return label.to_string();
    }
    let after = &rest[letter.len_utf8() + 1..];
    format!("{}{after}", label[..open].trim_end())
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

/// The Windows resource of a picture's file as `app/res/sign-in-buttons.rc` names it: its name without the folder and
/// the extension, in capitals, its hyphens and dots as underscores (`brands/google-sign-in.pt-BR.png` is
/// `GOOGLE_SIGN_IN_PT_BR`)
pub fn picture_resource(file: &str) -> String {
    let name = file.rsplit('/').next().unwrap_or(file);
    let name = name.strip_suffix(".png").unwrap_or(name);
    name.chars()
        .map(|c| match c {
            '-' | '.' => '_',
            c => c.to_ascii_uppercase(),
        })
        .collect()
}

/// Command `text` as the title of the window it opens: without its mnemonic mark and the dots that say it asks for
/// more ("&Import Messages..." is titled "Import Messages")
pub fn title(text: Text) -> String {
    trimmed_end(&without_mnemonic(&tr(text)), &['.', '\u{2026}'])
}

/// A field's label (`&Language:`, `Nom :`, `名前：`) as a title or as a word in a sentence: without its mnemonic mark
/// and its trailing colon, of any width, and the spaces before it
pub fn field_title(label: &str) -> String {
    trimmed_end(&without_mnemonic(label), &[':', '\u{ff1a}'])
}

/// `text` without the `marks` and spaces at its end; in the pseudo-language they come before its padding:
/// "[Óptíöñš... ~~~~]"
fn trimmed_end(text: &str, marks: &[char]) -> String {
    let (body, padding) = match text.rfind(" ~") {
        Some(at) if text.ends_with('~') || text.ends_with("~]") => text.split_at(at),
        _ => (text, ""),
    };
    format!("{}{padding}", body.trim_end().trim_end_matches(marks).trim_end())
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
