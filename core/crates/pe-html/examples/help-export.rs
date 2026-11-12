//! Writes the help's pages for one platform and target in every language, `<out>/<language>/...`:
//! `cargo run -p pe-html --example help-export -- <windows|mac|linux> <helpbook|yelp|web> <out>`
//! (the Mac's build makes its Help Book of them, the Linux packages install them for Yelp, the release puts them on
//! the website)
use pe_html::{HelpTarget, Platform, help_export};

fn main() {
    let args: Vec<String> = std::env::args().skip(1).collect();
    let [platform, target, out] = args.as_slice() else {
        eprintln!("usage: help-export <windows|mac|linux> <helpbook|yelp|web> <out>");
        std::process::exit(2);
    };
    let platform = Platform::from_name(platform).expect("windows, mac or linux");
    let target = match target.as_str() {
        "helpbook" => HelpTarget::HelpBook,
        "yelp" => HelpTarget::Yelp,
        "web" => HelpTarget::Web,
        _ => panic!("helpbook, yelp or web"),
    };
    for (language, _) in pe_i18n::LANGUAGES {
        let dir = std::path::Path::new(out).join(language);
        for (path, bytes) in help_export(platform, language, target) {
            let file = dir.join(path);
            std::fs::create_dir_all(file.parent().unwrap()).unwrap();
            std::fs::write(file, bytes).unwrap();
        }
    }
}
