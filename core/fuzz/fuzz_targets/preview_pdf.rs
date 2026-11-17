//! A PDF attachment from a sender to its preview: read with hayro (a broken cross-reference table rebuilt), its page
//! count and title, then its first two pages measured and drawn, at a quarter of their size so a run spends its time on
//! more files rather than on pixels. Whatever the bytes, pages within the limits or a refusal. hayro has no time limit
//! of its own (the app's watchdog abandons a render that runs over): run with `-timeout` to find the files that are
//! slow.
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
        if let Ok(page) = pages.render_scaled(index, 4) {
            assert!(page.width >= 1 && page.width <= MAX_SIDE / 4);
            assert!(page.height >= 1 && page.height <= MAX_SIDE / 4);
            let (width, height) = description.sizes[index].expect("a page drawn has a size");
            assert_eq!((page.width, page.height), ((width / 4).max(1), (height / 4).max(1)));
        }
    }
});
