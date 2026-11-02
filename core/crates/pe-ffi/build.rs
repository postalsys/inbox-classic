// Writes the C header of the exports to core/include/inbox_classic.h. The header is committed, so changes to the
// API show up in diffs; cbindgen only rewrites it when its content changes.
use std::path::PathBuf;

fn main() {
    let crate_dir = PathBuf::from(std::env::var("CARGO_MANIFEST_DIR").unwrap());
    let config = cbindgen::Config::from_file(crate_dir.join("cbindgen.toml")).expect("reading cbindgen.toml");
    cbindgen::Builder::new()
        .with_crate(&crate_dir)
        .with_config(config)
        .generate()
        .expect("generating the C header")
        .write_to_file(crate_dir.join("../../include/inbox_classic.h"));
    println!("cargo:rerun-if-changed=src");
    println!("cargo:rerun-if-changed=cbindgen.toml");
}
