//! An SVG picture of a message's text from a sender to its preview: the `use` copies counted, then drawn with resvg
//! and encoded again as a PNG. Whatever the bytes, a preview within the limits or a refusal, in time.
#![no_main]

use libfuzzer_sys::fuzz_target;
use pe_preview::limits::MAX_SIDE;
use pe_preview::svg;

fuzz_target!(|data: &[u8]| {
    let described = svg::describe(data);
    if let Ok(picture) = svg::render(data) {
        assert!(picture.width >= 1 && picture.width <= MAX_SIDE);
        assert!(picture.height >= 1 && picture.height <= MAX_SIDE);
        assert!(picture.bytes.starts_with(b"\x89PNG"));
        let size = described.expect("a picture drawn was described").sizes[0];
        assert_eq!(size, Some((picture.width, picture.height)));
    }
});
