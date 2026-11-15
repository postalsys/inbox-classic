//! Certificates and private keys from anyone (a key server, an Autocrypt header, an attached file): parsed, cleaned
//! and judged. Nothing may panic, and what a certificate says about itself must hold together.
#![no_main]

use libfuzzer_sys::fuzz_target;

const NOW: i64 = 1_794_700_800;

fuzz_target!(|data: &[u8]| {
    if let Ok(certs) = pe_pgp::read_certs(data) {
        for cert in &certs {
            let _ = cert.status(NOW);
            let _ = cert.can_encrypt(NOW);
            let _ = cert.can_sign(NOW);
            for user in cert.user_ids(NOW) {
                assert!(!user.text.chars().any(char::is_control));
            }
            for address in cert.addresses(NOW) {
                let _ = cert.minimal(&address, NOW);
            }
            assert_eq!(cert.fingerprint().len() % 2, 0);
            let again = pe_pgp::read_certs(&cert.to_bytes());
            if let Ok(again) = again {
                assert_eq!(again[0].fingerprint(), cert.fingerprint());
                let _ = cert.merge(&again[0]);
            }
        }
    }
    let _ = pe_pgp::needs_passphrase(data);
    let _ = pe_pgp::read_secret_keys(data, "");
    let _ = pe_pgp::armored_kind(data);
});
