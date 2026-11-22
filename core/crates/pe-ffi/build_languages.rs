// What is made per language from pe_i18n::LANGUAGES and the catalogs, for the files of the platforms that can not ask
// the core at run time (all committed, so changes show in diffs):
//   installer/languages.nsh                               the installer's languages and its words (windows.ftl)
//   app/res/sign-in-buttons.rc                            the Windows resources of the sign-in button pictures
//   linux/data/com.inboxclassic.InboxClassic.desktop      the desktop entry with its translations (linux.ftl)
//   linux/data/com.inboxclassic.InboxClassic.metainfo.xml the software stores' page with its translations (linux.ftl)
//   core/include/languages.tsv                            the list for the scripts (languages.sh, ui-e2e.ps1, the
//                                                         homepage's help)
// Each writes a language's tag the way its platform does: NSIS by its language file's name (PortugueseBR), Windows'
// resources in capitals with an underscore (PT_BR), Linux's files as gettext locales (pt_BR, sr@latin).
// A language a catalog has no message of is left out of the Linux files (they show English then); the installer
// takes the English words for it.
use std::fmt::Write as _;
use std::path::Path;

use pe_i18n::{ALIASES, Arg, LANGUAGES, Tag, gettext_locale, picture_resource, supported, translated};

/// The languages but English, which the files have as their default
fn others() -> impl Iterator<Item = &'static str> {
    LANGUAGES.iter().map(|(code, _)| *code).filter(|code| *code != "en")
}

pub fn write_all(root: &Path, write: fn(&Path, &str)) {
    write(&root.join("core/include/languages.tsv"), &table());
    write(&root.join("installer/languages.nsh"), &nsis());
    write(&root.join("app/res/sign-in-buttons.rc"), &sign_in_buttons());
    write(
        &root.join("linux/data/com.inboxclassic.InboxClassic.desktop"),
        &desktop(),
    );
    write(
        &root.join("linux/data/com.inboxclassic.InboxClassic.metainfo.xml"),
        &metainfo(),
    );
}

/// NSIS's language files (Contrib/Language files/<name>.nsh) by the tags of pe_i18n::LANGUAGES. A language NSIS has
/// none of installs in English.
const NSIS_LANGUAGES: &[(&str, &str)] = &[
    ("af", "Afrikaans"),
    ("ar", "Arabic"),
    ("be", "Belarusian"),
    ("bg", "Bulgarian"),
    ("br", "Breton"),
    ("bs", "Bosnian"),
    ("ca", "Catalan"),
    ("co", "Corsican"),
    ("cs", "Czech"),
    ("cy", "Welsh"),
    ("da", "Danish"),
    ("de", "German"),
    ("el", "Greek"),
    ("en", "English"),
    ("eo", "Esperanto"),
    ("es", "Spanish"),
    ("et", "Estonian"),
    ("eu", "Basque"),
    ("fa", "Farsi"),
    ("fi", "Finnish"),
    ("fr", "French"),
    ("ga", "Irish"),
    ("gd", "ScotsGaelic"),
    ("gl", "Galician"),
    ("he", "Hebrew"),
    ("hi", "Hindi"),
    ("hr", "Croatian"),
    ("hu", "Hungarian"),
    ("hy", "Armenian"),
    ("id", "Indonesian"),
    ("is", "Icelandic"),
    ("it", "Italian"),
    ("ja", "Japanese"),
    ("ka", "Georgian"),
    ("ko", "Korean"),
    ("ku", "Kurdish"),
    ("lb", "Luxembourgish"),
    ("lt", "Lithuanian"),
    ("lv", "Latvian"),
    ("mk", "Macedonian"),
    ("mn", "Mongolian"),
    ("ms", "Malay"),
    ("nb", "Norwegian"),
    ("nl", "Dutch"),
    ("nn", "NorwegianNynorsk"),
    ("pl", "Polish"),
    ("ps", "Pashto"),
    // Portuguese as written in Portugal, and in Brazil
    ("pt", "Portuguese"),
    ("pt-BR", "PortugueseBR"),
    ("ro", "Romanian"),
    ("ru", "Russian"),
    ("sk", "Slovak"),
    ("sl", "Slovenian"),
    ("sq", "Albanian"),
    // Serbian in Cyrillic, and in Latin script
    ("sr", "Serbian"),
    ("sr-Latn", "SerbianLatin"),
    ("sv", "Swedish"),
    ("th", "Thai"),
    ("tr", "Turkish"),
    ("tt", "Tatar"),
    ("uk", "Ukrainian"),
    ("uz", "Uzbek"),
    ("vi", "Vietnamese"),
    // Chinese in Simplified, and in Traditional characters
    ("zh-Hans", "SimpChinese"),
    ("zh-Hant", "TradChinese"),
];

/// The installer's words: its LangString names and their messages in windows.ftl
const INSTALLER_WORDS: &[(&str, &str)] = &[
    ("StartApp", "win-installer-start"),
    ("WelcomeNew", "win-installer-welcome-new"),
    ("WelcomeSame", "win-installer-welcome-same"),
    ("WelcomeUpdate", "win-installer-welcome-update"),
    ("OlderAsk", "win-installer-older-ask"),
    ("StillRunning", "win-installer-still-running"),
    ("RemoveMailAsk", "win-installer-remove-mail-ask"),
];

const NOTE: &str = "Generated from pe_i18n::LANGUAGES and core/locales by core/crates/pe-ffi/build.rs, do not edit";

fn nsis() -> String {
    // the versions are the installer's own: markers while the words are escaped, then its variables
    const VERSION: &str = "\u{E000}";
    const INSTALLED: &str = "\u{E001}";
    let languages: Vec<(&str, &str)> = LANGUAGES
        .iter()
        .filter_map(|(code, _)| {
            NSIS_LANGUAGES
                .iter()
                .find(|(c, _)| c == code)
                .map(|(_, name)| (*code, *name))
        })
        .collect();
    let mut out = format!(
        "; {NOTE}\n\n; the languages there are catalogs of, English first; one NSIS has no language file of installs in English\n"
    );
    for (_, name) in &languages {
        writeln!(out, "!insertmacro MUI_LANGUAGE \"{name}\"").unwrap();
    }
    out.push_str(
        "\n; the code of the language chosen for the installer, the app's language on a first install (app/src/options.cpp)\n",
    );
    for (code, name) in &languages {
        writeln!(
            out,
            "LangString LanguageCode ${{LANG_{}}} \"{code}\"",
            name.to_uppercase()
        )
        .unwrap();
    }
    for (string, id) in INSTALLER_WORDS {
        out.push('\n');
        for (code, name) in &languages {
            let args = [("version", Arg::Str(VERSION)), ("installed", Arg::Str(INSTALLED))];
            let words = translated(code, id, &args)
                .or_else(|| translated("en", id, &args))
                .unwrap_or_else(|| panic!("core/locales/en/windows.ftl has no {id}"));
            let words = words
                .replace('$', "$$")
                .replace('"', "$\\\"")
                .replace('\n', "$\\r$\\n")
                .replace(VERSION, "${VERSION}")
                .replace(INSTALLED, "$InstalledVersion");
            writeln!(out, "LangString {string} ${{LANG_{}}} \"{words}\"", name.to_uppercase()).unwrap();
        }
    }
    out
}

/// The list for the scripts, a language a line: its tag, its name in itself, its gettext locale, its NSIS language
/// (empty for none), and the lowercase tags a system may give that it answers to by themselves (`pt-br`; `pt` for the
/// language's own catalog, `sr` for the first of the language's, `no` for an alias), which a script looks up a tag's
/// `language-subtag` in, then its language, without matching anything itself
fn table() -> String {
    let mut out = format!("# {NOTE}\n# tag\tname\tgettext\tnsis\tlookup (comma separated)\n");
    for (code, name) in LANGUAGES {
        let nsis = NSIS_LANGUAGES.iter().find(|(c, _)| c == code).map_or("", |(_, n)| *n);
        let language = Tag::parse(code).language;
        let mut keys = vec![code.to_ascii_lowercase()];
        let candidates = std::iter::once(language).chain(
            ALIASES
                .iter()
                .filter(|(_, target)| *target == language)
                .map(|(alias, _)| *alias),
        );
        // and the regions a system names a script by (`zh-tw` for Traditional Chinese)
        let regions = pe_i18n::TRADITIONAL_REGIONS
            .iter()
            .map(|region| format!("{language}-{}", region.to_ascii_lowercase()));
        for key in candidates.map(str::to_string).chain(regions) {
            if supported(&key) == Some(*code) && !keys.contains(&key) {
                keys.push(key);
            }
        }
        writeln!(
            out,
            "{code}\t{name}\t{}\t{nsis}\t{}",
            gettext_locale(code),
            keys.join(",")
        )
        .unwrap();
    }
    out
}

fn sign_in_buttons() -> String {
    let mut out = format!(
        "// {NOTE}\n// the sign-in buttons of Add Mail Account, Google's and Microsoft's own, and with the words of each language\n// (scripts/build-sign-in-buttons.sh), named after their files (PictureResource in accounts.cpp)\n"
    );
    for provider in ["google", "microsoft"] {
        let file = format!("brands/{provider}-sign-in.png");
        writeln!(out, "{} RCDATA \"{file}\"", picture_resource(&file)).unwrap();
        for code in others() {
            let file = format!("brands/{provider}-sign-in.{code}.png");
            writeln!(out, "{} RCDATA \"{file}\"", picture_resource(&file)).unwrap();
        }
    }
    out
}

/// A message of the language's own catalog on one line, None when it has none
fn line(code: &str, id: &str) -> Option<String> {
    translated(code, id, &[]).map(|words| words.split_whitespace().collect::<Vec<_>>().join(" "))
}

fn english(id: &str) -> String {
    line("en", id).unwrap_or_else(|| panic!("core/locales/en/linux.ftl has no {id}"))
}

fn desktop() -> String {
    let mut out = format!("# {NOTE}\n[Desktop Entry]\nType=Application\nName=Inbox Classic\n");
    for (key, id) in [
        ("GenericName", "gtk-desktop-generic-name"),
        ("Comment", "gtk-desktop-comment"),
    ] {
        writeln!(out, "{key}={}", english(id)).unwrap();
        for code in others() {
            if let Some(words) = line(code, id) {
                writeln!(out, "{key}[{}]={words}", gettext_locale(code)).unwrap();
            }
        }
    }
    // the English keywords in every language, the language's own after them
    let keywords = english("gtk-desktop-keywords");
    writeln!(out, "Keywords={keywords}").unwrap();
    for code in others() {
        if let Some(words) = line(code, "gtk-desktop-keywords") {
            writeln!(out, "Keywords[{}]={keywords}{words}", gettext_locale(code)).unwrap();
        }
    }
    out.push_str(
        "Exec=inbox-classic %u\nIcon=com.inboxclassic.InboxClassic\nTerminal=false\nCategories=Network;Email;GTK;\n\
         MimeType=x-scheme-handler/mailto;message/rfc822;\nStartupNotify=true\nStartupWMClass=com.inboxclassic.InboxClassic\n",
    );
    out
}

fn xml(text: &str) -> String {
    text.replace('&', "&amp;")
        .replace('<', "&lt;")
        .replace('>', "&gt;")
        .replace('"', "&quot;")
}

/// `text` in lines of at most `width` characters after `indent` spaces
fn wrap(text: &str, indent: usize, width: usize) -> String {
    let mut out = String::new();
    let mut current = String::new();
    for word in text.split_whitespace() {
        if !current.is_empty() && indent + current.chars().count() + 1 + word.chars().count() > width {
            writeln!(out, "{}{current}", " ".repeat(indent)).unwrap();
            current.clear();
        }
        if !current.is_empty() {
            current.push(' ');
        }
        current.push_str(word);
    }
    if !current.is_empty() {
        writeln!(out, "{}{current}", " ".repeat(indent)).unwrap();
    }
    out
}

const FEATURES: [&str; 4] = [
    "gtk-metainfo-feature-sanitized",
    "gtk-metainfo-feature-search",
    "gtk-metainfo-feature-replies",
    "gtk-metainfo-feature-offline",
];

fn metainfo() -> String {
    let mut out = format!(
        "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<!-- What the App Center and other software stores show of Inbox Classic -->\n<!-- {NOTE} -->\n\
         <component type=\"desktop-application\">\n  <id>com.inboxclassic.InboxClassic</id>\n  <name>Inbox Classic</name>\n"
    );
    writeln!(out, "  <summary>{}</summary>", xml(&english("gtk-metainfo-summary"))).unwrap();
    for code in others() {
        if let Some(words) = line(code, "gtk-metainfo-summary") {
            writeln!(
                out,
                "  <summary xml:lang=\"{}\">{}</summary>",
                gettext_locale(code),
                xml(&words)
            )
            .unwrap();
        }
    }
    out.push_str(
        "  <metadata_license>CC0-1.0</metadata_license>\n  <project_license>MIT</project_license>\n  \
         <developer id=\"com.postalsys\">\n    <name>Postal Systems OÜ</name>\n  </developer>\n  <description>\n",
    );
    let paragraph = |out: &mut String, attribute: &str, words: &str| {
        writeln!(out, "    <p{attribute}>").unwrap();
        out.push_str(&wrap(&xml(words), 6, 120));
        out.push_str("    </p>\n");
    };
    paragraph(&mut out, "", &english("gtk-metainfo-description"));
    for code in others() {
        if let Some(words) = line(code, "gtk-metainfo-description") {
            paragraph(&mut out, &format!(" xml:lang=\"{}\"", gettext_locale(code)), &words);
        }
    }
    out.push_str("    <ul>\n");
    for id in FEATURES {
        writeln!(out, "      <li>{}</li>", xml(&english(id))).unwrap();
    }
    for code in others() {
        for id in FEATURES {
            if let Some(words) = line(code, id) {
                writeln!(
                    out,
                    "      <li xml:lang=\"{}\">{}</li>",
                    gettext_locale(code),
                    xml(&words)
                )
                .unwrap();
            }
        }
    }
    out.push_str(
        "    </ul>\n  </description>\n  <launchable type=\"desktop-id\">com.inboxclassic.InboxClassic.desktop</launchable>\n  \
         <url type=\"homepage\">https://inboxclassic.com</url>\n  \
         <url type=\"bugtracker\">https://github.com/postalsys/inbox-classic/issues</url>\n  <categories>\n    \
         <category>Network</category>\n    <category>Email</category>\n  </categories>\n  <provides>\n    \
         <binary>inbox-classic</binary>\n    <mediatype>x-scheme-handler/mailto</mediatype>\n    \
         <mediatype>message/rfc822</mediatype>\n  </provides>\n  <content_rating type=\"oars-1.1\"/>\n</component>\n",
    );
    out
}
