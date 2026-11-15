//! A signed or encrypted message from a sender, read the way the reading pane reads it: layers found, decrypted with
//! a fixed key, verified with its certificate, cut into sections. Nothing may panic.
#![no_main]

use std::sync::OnceLock;

use libfuzzer_sys::fuzz_target;
use pe_core::protect::{KeyRing, read};

const NOW: i64 = 1_798_761_600;

fn ring() -> &'static KeyRing {
    static RING: OnceLock<KeyRing> = OnceLock::new();
    RING.get_or_init(|| {
        let secret = include_bytes!("../../crates/pe-pgp/tests/fixtures/interop/gnupg-ed25519/secret.asc");
        let keys = pe_pgp::read_secret_keys(secret, "").unwrap();
        let certs = keys.iter().map(|key| key.cert().clone()).collect();
        KeyRing { keys, certs, verified: Default::default() }
    })
}

fuzz_target!(|data: &[u8]| {
    if let Some(protected) = read(data, ring(), &["gnupg-ed25519@example.org".into()], NOW) {
        for section in &protected.sections {
            let _ = section.verdict.as_ref().map(|verdict| verdict.label());
        }
    }
});
