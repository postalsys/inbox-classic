//! The Autocrypt header of a message from anyone.
#![no_main]

use libfuzzer_sys::fuzz_target;

fuzz_target!(|data: &[u8]| {
    let value = String::from_utf8_lossy(data);
    if let Some(header) = pe_pgp::autocrypt::parse(&value) {
        assert!(!header.keydata.is_empty());
        assert_eq!(pe_pgp::address_of(&header.addr).as_deref(), Some(header.addr.as_str()));
        let _ = pe_pgp::read_certs(&header.keydata);
    }
});
