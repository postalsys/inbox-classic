// The help built in (help.rs): the topics of help/<language>/<id>.html, their order and sections from
// help/topics.toml, the pictures of help/pictures/<platform>/<shot>.png, and the keys of core/commands.toml, which the
// topics name by command so a key is never written by hand
use std::fmt::Write as _;
use std::path::{Path, PathBuf};

fn main() {
    let manifest = PathBuf::from(std::env::var("CARGO_MANIFEST_DIR").unwrap());
    let help = manifest.join("help");
    let commands = manifest
        .join("../../commands.toml")
        .canonicalize()
        .expect("core/commands.toml");
    println!("cargo:rerun-if-changed={}", help.display());
    println!("cargo:rerun-if-changed={}", commands.display());
    let mut out = String::new();
    write_order(&mut out, &help.join("topics.toml"));
    write_topics(&mut out, &help);
    write_pictures(&mut out, &help.join("pictures"));
    write_commands(&mut out, &commands);
    let target = PathBuf::from(std::env::var("OUT_DIR").unwrap()).join("help.rs");
    std::fs::write(target, out).unwrap();
}

fn toml_file(path: &Path) -> toml::Table {
    println!("cargo:rerun-if-changed={}", path.display());
    std::fs::read_to_string(path)
        .unwrap()
        .parse()
        .unwrap_or_else(|e| panic!("{}: {e}", path.display()))
}

/// SECTIONS (each section's id and its topics' ids) and CONTEXT (a window's name and its topic)
fn write_order(out: &mut String, path: &Path) {
    let order = toml_file(path);
    out.push_str("pub(crate) static SECTIONS: &[(&str, &[&str])] = &[\n");
    for section in order["section"].as_array().unwrap() {
        let topics: Vec<String> = section["topics"]
            .as_array()
            .unwrap()
            .iter()
            .map(|t| format!("{:?}", t.as_str().unwrap()))
            .collect();
        writeln!(
            out,
            "    ({:?}, &[{}]),",
            section["id"].as_str().unwrap(),
            topics.join(", ")
        )
        .unwrap();
    }
    out.push_str("];\npub(crate) static CONTEXT: &[(&str, &str)] = &[\n");
    for (window, topic) in order["context"].as_table().unwrap() {
        writeln!(out, "    ({window:?}, {:?}),", topic.as_str().unwrap()).unwrap();
    }
    out.push_str("];\n");
}

/// TOPICS: each language's topics, by id
fn write_topics(out: &mut String, help: &Path) {
    out.push_str("pub(crate) static TOPICS: &[(&str, &str, &str)] = &[\n");
    for (language, path) in files(help, |p| p.is_dir()) {
        for (id, file) in files(&path, |p| p.extension().is_some_and(|x| x == "html")) {
            let id = id.trim_end_matches(".html");
            writeln!(
                out,
                "    ({language:?}, {id:?}, include_str!({:?})),",
                file.display().to_string()
            )
            .unwrap();
        }
    }
    out.push_str("];\n");
}

/// PICTURES: each platform's screenshots, by name
fn write_pictures(out: &mut String, pictures: &Path) {
    out.push_str("pub(crate) static PICTURES: &[(&str, &str, &[u8])] = &[\n");
    if pictures.is_dir() {
        for (platform, path) in files(pictures, |p| p.is_dir()) {
            for (name, file) in files(&path, |p| p.extension().is_some_and(|x| x == "png")) {
                let name = name.trim_end_matches(".png");
                writeln!(
                    out,
                    "    ({platform:?}, {name:?}, include_bytes!({:?})),",
                    file.display().to_string()
                )
                .unwrap();
            }
        }
    }
    out.push_str("];\n");
}

/// COMMANDS: each command's id, menu and keys (Windows', the Mac's, Linux's; empty for none)
fn write_commands(out: &mut String, path: &Path) {
    let commands = toml_file(path);
    out.push_str("pub(crate) static COMMANDS: &[(&str, &str, &str, &str, &str)] = &[\n");
    for command in commands["command"].as_array().unwrap() {
        let get = |name: &str| command.get(name).and_then(|v| v.as_str());
        let key = get("key").unwrap_or("");
        let mac = get("mac").unwrap_or(key);
        let linux = get("linux").unwrap_or(key);
        writeln!(
            out,
            "    ({:?}, {:?}, {key:?}, {mac:?}, {linux:?}),",
            get("id").unwrap(),
            get("menu").unwrap_or("")
        )
        .unwrap();
    }
    out.push_str("];\n");
}

/// The entries of `dir` that `keep` takes, by name, in order
fn files(dir: &Path, keep: impl Fn(&Path) -> bool) -> Vec<(String, PathBuf)> {
    let mut found: Vec<(String, PathBuf)> = std::fs::read_dir(dir)
        .unwrap()
        .filter_map(|e| e.ok())
        .map(|e| (e.file_name().to_string_lossy().into_owned(), e.path()))
        .filter(|(_, p)| keep(p))
        .collect();
    found.sort();
    found
}
