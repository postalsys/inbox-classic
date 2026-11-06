// The catalogs of core/locales, built in: every language's Fluent files, and the ids of the English ones as the
// `Text` enum, so a word the code asks for that the catalog does not have fails the build
use std::fmt::Write as _;
use std::path::PathBuf;

fn main() {
    let dir = PathBuf::from(std::env::var("CARGO_MANIFEST_DIR").unwrap()).join("../../locales");
    let dir = dir.canonicalize().expect("core/locales");
    println!("cargo:rerun-if-changed={}", dir.display());
    let mut languages: Vec<String> = std::fs::read_dir(&dir)
        .unwrap()
        .filter_map(|e| e.ok())
        .filter(|e| e.path().is_dir())
        .map(|e| e.file_name().to_string_lossy().into_owned())
        .collect();
    languages.sort();
    let mut out = String::new();
    out.push_str(
        "/// The catalogs: each language's Fluent files\npub(crate) const CATALOGS: &[(&str, &[&str])] = &[\n",
    );
    let mut ids = Vec::new();
    for language in &languages {
        let mut files: Vec<PathBuf> = std::fs::read_dir(dir.join(language))
            .unwrap()
            .filter_map(|e| e.ok())
            .map(|e| e.path())
            .filter(|p| p.extension().is_some_and(|x| x == "ftl"))
            .collect();
        files.sort();
        write!(out, "    (\"{language}\", &[").unwrap();
        for file in &files {
            println!("cargo:rerun-if-changed={}", file.display());
            write!(out, "include_str!({:?}), ", file.display().to_string()).unwrap();
            if language == "en" {
                for line in std::fs::read_to_string(file).unwrap().lines() {
                    if let Some((id, _)) = line.split_once(" =")
                        && !id.is_empty()
                        && id
                            .bytes()
                            .all(|b| b.is_ascii_lowercase() || b.is_ascii_digit() || b == b'-')
                    {
                        assert!(!ids.contains(&id.to_string()), "{id} is in the English catalog twice");
                        ids.push(id.to_string());
                    }
                }
            }
        }
        out.push_str("]),\n");
    }
    out.push_str("];\n\n");
    out.push_str(
        "/// A word or sentence of the catalog, by its id in the English files\n\
         #[derive(Debug, Clone, Copy, PartialEq, Eq, Hash)]\n#[repr(u32)]\npub enum Text {\n",
    );
    for (index, id) in ids.iter().enumerate() {
        writeln!(out, "    {} = {index},", camel(id)).unwrap();
    }
    out.push_str("}\n\n");
    writeln!(out, "pub(crate) static IDS: [&str; {}] = [", ids.len()).unwrap();
    for id in &ids {
        writeln!(out, "    {id:?},").unwrap();
    }
    out.push_str(
        "];\n\nimpl Text {\n    /// Every one, in the order of the English files\n    pub const ALL: &[Text] = &[\n",
    );
    for id in &ids {
        writeln!(out, "        Text::{},", camel(id)).unwrap();
    }
    out.push_str(
        "    ];\n\n    /// Its id in the catalogs\n    pub fn id(self) -> &'static str {\n        IDS[self as usize]\n    }\n\n    \
         /// The one numbered `index`, as C and Swift name them\n    pub fn from_index(index: u32) -> Option<Text> {\n        \
         Text::ALL.get(index as usize).copied()\n    }\n}\n",
    );
    let target = PathBuf::from(std::env::var("OUT_DIR").unwrap()).join("texts.rs");
    std::fs::write(target, out).unwrap();
}

/// `cmd-new-account` as `CmdNewAccount`
fn camel(id: &str) -> String {
    id.split('-')
        .map(|part| {
            let mut chars = part.chars();
            chars
                .next()
                .map(|c| c.to_ascii_uppercase().to_string() + chars.as_str())
                .unwrap_or_default()
        })
        .collect()
}
