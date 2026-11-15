//! Messages and signatures from a sender: decrypted with a fixed key (GnuPG's of the fixtures, so that messages
//! encrypted to it make good seeds), verified with its certificate. Nothing may panic.
#![no_main]

use std::sync::OnceLock;

use libfuzzer_sys::fuzz_target;

const NOW: i64 = 1_798_761_600;

fn keys() -> &'static (Vec<pe_pgp::SecretKey>, Vec<pe_pgp::Cert>) {
    static KEYS: OnceLock<(Vec<pe_pgp::SecretKey>, Vec<pe_pgp::Cert>)> = OnceLock::new();
    KEYS.get_or_init(|| {
        let secret = include_bytes!("../../crates/pe-pgp/tests/fixtures/interop/gnupg-ed25519/secret.asc");
        let keys = pe_pgp::read_secret_keys(secret, "").unwrap();
        let certs = keys.iter().map(|key| key.cert().clone()).collect();
        (keys, certs)
    })
}

fuzz_target!(|data: &[u8]| {
    let (keys, certs) = keys();
    if let Ok(opened) = pe_pgp::decrypt_within(data, keys, certs, NOW, 1 << 20) {
        assert!(opened.data.len() <= 1 << 20);
    }
    let _ = pe_pgp::recipients(data);
    // the first half a signature, the second the data it signs
    let (signature, signed) = data.split_at(data.len() / 2);
    let _ = pe_pgp::verify_detached(signature, signed, certs, NOW);
    let text = String::from_utf8_lossy(data);
    for block in pe_pgp::inline::blocks(&text) {
        let _ = pe_pgp::inline::cleartext(&text[block.start..block.end]);
    }
});
