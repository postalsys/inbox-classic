//! A PDF attachment from a sender to its preview: read with hayro (a broken cross-reference table rebuilt), its page
//! count and title, then its first two pages measured and drawn. Whatever the bytes, pages within the limits or a
//! refusal. hayro has no time limit of its own (the app's watchdog abandons a render that runs over): run with
//! `-timeout` to find the files that are slow.
#![no_main]

use std::sync::Arc;

use libfuzzer_sys::fuzz_target;
use pe_preview::limits::MAX_SIDE;
use pe_preview::pdf::Document;

fuzz_target!(|data: &[u8]| {
    let Ok(document) = Document::open(Arc::new(data.to_vec())) else {
        return;
    };
    let description = document.describe();
    assert!(description.pages >= 1);
    assert!(description.title.as_ref().is_none_or(|t| t.chars().count() <= 200));
    let pages = document.pages();
    for index in 0..description.pages.min(2) {
        if let Ok(page) = pages.render(index) {
            assert!(page.width >= 1 && page.width <= MAX_SIDE);
            assert!(page.height >= 1 && page.height <= MAX_SIDE);
            assert_eq!(description.sizes[index], Some((page.width, page.height)));
        }
    }
});
