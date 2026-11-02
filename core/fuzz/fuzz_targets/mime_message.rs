//! A message from a sender through the MIME parser, with low limits so deep or wide input is
//! cut short rather than slow
#![no_main]

use libfuzzer_sys::fuzz_target;
use pe_mime::parser::{Limits, parse_with};

fuzz_target!(|data: &[u8]| {
    let limits = Limits {
        max_nesting_depth: 32,
        max_headers_size: 64 * 1024,
        max_part_count: 256,
        max_rfc822_nesting_depth: 4,
        max_forwarded_addresses: 256,
    };
    let _ = parse_with(data, limits);
});
