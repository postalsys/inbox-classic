//! Writes the help for Yelp as the packages install it, `<out>/<language>/inbox-classic/...` (the language as a
//! gettext locale, `pt_BR`, `sr@latin`, English as `C`, the language Yelp falls back to), to go to /usr/share/help/: `cargo run --release --example yelp-help -- <out>`
//! (scripts/linux-package.sh and linux/arch/PKGBUILD). The app opens it with `help:inbox-classic/<topic>`.
use pe_html::{HelpTarget, Platform, help_export};

fn main() {
    let Some(out) = std::env::args().nth(1) else {
        eprintln!("usage: yelp-help <out>");
        std::process::exit(2);
    };
    for (language, _) in pe_core::i18n::LANGUAGES {
        let folder = match *language {
            "en" => "C".to_string(),
            other => pe_core::i18n::gettext_locale(other),
        };
        let dir = std::path::Path::new(&out).join(folder).join("inbox-classic");
        for (path, bytes) in help_export(Platform::Linux, language, HelpTarget::Yelp) {
            let file = dir.join(path);
            std::fs::create_dir_all(file.parent().expect("a folder")).expect("the folder made");
            std::fs::write(&file, bytes).expect("the page written");
        }
    }
}
