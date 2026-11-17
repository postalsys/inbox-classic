//! A picture attachment from a sender to its preview: the header read for its size, then decoded under the limits,
//! turned upright, scaled and encoded again. Whatever the bytes, a preview within the limits or a refusal.
#![no_main]

use libfuzzer_sys::fuzz_target;
use pe_preview::limits::MAX_SIDE;
use pe_preview::picture;

fuzz_target!(|data: &[u8]| {
    let described = picture::describe(data);
    if let Ok(picture) = picture::render(data) {
        assert!(picture.width >= 1 && picture.width <= MAX_SIDE);
        assert!(picture.height >= 1 && picture.height <= MAX_SIDE);
        assert!(!picture.bytes.is_empty());
        let size = described.expect("a picture drawn was described").sizes[0];
        assert_eq!(size, Some((picture.width, picture.height)));
    }
});
