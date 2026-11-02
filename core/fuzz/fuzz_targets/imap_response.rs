//! Bytes from a server, split at an arbitrary point, through the framer and the parser
#![no_main]

use libfuzzer_sys::fuzz_target;
use pe_imap::{FrameLimits, Framer, ParserOptions};

fuzz_target!(|data: &[u8]| {
    let Some((&split, wire)) = data.split_first() else { return };
    let split = (split as usize).min(wire.len());
    let limits = FrameLimits {
        max_line: 1 << 20,
        max_literal: 1 << 20,
        max_response: 1 << 21,
    };
    let options = ParserOptions { max_tokens: 100_000 };
    let mut framer = Framer::new(limits);
    let mut responses = Vec::new();
    if framer.push(&wire[..split], &mut responses).is_ok() {
        let _ = framer.push(&wire[split..], &mut responses);
    }
    for response in responses {
        let _ = response.parse_with(&options);
    }
});
