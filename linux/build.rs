//! Compiles the app's resources into one gresource the binary carries: the Fluent icons of app/res/icons as symbolic
//! icons (`ic-<name>-symbolic`, Fluent's own 16 pixel design where there is one), the provider sign-in buttons of
//! app/res/brands and the app icon. The command table (src/generated/commands.rs) comes from pe-ffi's build, not
//! from here.

use std::fmt::Write as _;
use std::path::{Path, PathBuf};

fn main() {
    let root = Path::new(env!("CARGO_MANIFEST_DIR")).join("..");
    let icons = root.join("app/res/icons");
    let out = PathBuf::from(std::env::var("OUT_DIR").expect("OUT_DIR"));
    println!("cargo:rerun-if-changed={}", icons.display());
    println!("cargo:rerun-if-changed={}", root.join("app/res/brands").display());
    println!("cargo:rerun-if-changed={}", root.join("app/res/app-icon.svg").display());

    let mut xml = String::from("<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<gresources>\n");
    xml.push_str("  <gresource prefix=\"/com/inboxclassic/InboxClassic\">\n");
    for name in icon_names(&icons) {
        let file = ["_16", "_20", ""]
            .iter()
            .map(|suffix| format!("app/res/icons/{name}{suffix}.svg"))
            .find(|path| root.join(path).exists())
            .expect("an SVG of the icon");
        let alias = format!("icons/scalable/actions/ic-{}-symbolic.svg", name.replace('_', "-"));
        writeln!(
            xml,
            "    <file alias=\"{alias}\" preprocess=\"xml-stripblanks\">{file}</file>"
        )
        .unwrap();
    }
    for (alias, file) in [
        ("brands/google-sign-in.png", "app/res/brands/google-sign-in.png"),
        ("brands/microsoft-sign-in.png", "app/res/brands/microsoft-sign-in.png"),
        (
            "icons/scalable/apps/com.inboxclassic.InboxClassic.svg",
            "app/res/app-icon.svg",
        ),
    ] {
        writeln!(xml, "    <file alias=\"{alias}\">{file}</file>").unwrap();
    }
    xml.push_str("  </gresource>\n</gresources>\n");
    let manifest = out.join("inbox-classic.gresource.xml");
    std::fs::write(&manifest, xml).expect("the resource list");
    glib_build_tools::compile_resources(&[root.as_path()], manifest.to_str().unwrap(), "inbox-classic.gresource");
}

/// Each icon once, without the size of its file name: `mail_read` for mail_read.svg, mail_read_16.svg, mail_read_20.svg
fn icon_names(dir: &Path) -> Vec<String> {
    let mut names: Vec<String> = std::fs::read_dir(dir)
        .expect("app/res/icons")
        .filter_map(|entry| {
            let name = entry.ok()?.file_name().into_string().ok()?;
            let stem = name.strip_suffix(".svg")?;
            Some(
                stem.strip_suffix("_16")
                    .or_else(|| stem.strip_suffix("_20"))
                    .unwrap_or(stem)
                    .to_string(),
            )
        })
        .collect();
    names.sort();
    names.dedup();
    names
}
