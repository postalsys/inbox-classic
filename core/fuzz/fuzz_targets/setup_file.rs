//! A setup file someone handed the user, through the reader the import window opens it with: the JSON parsed and
//! every part checked. A sealed file stops at the passphrase (opening one runs Argon2, which the pgp targets leave
//! to rPGP's own limits), so the fuzzer explores the JSON and its checks.
#![no_main]

use libfuzzer_sys::fuzz_target;

fuzz_target!(|data: &[u8]| {
    let data = &data[..data.len().min(pe_core::setup::MAX_FILE)];
    if let Ok(file) = pe_core::setup::parse(data, None) {
        let _ = file.part_lines();
    }
});
