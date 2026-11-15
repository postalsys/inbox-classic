//! The outline of a message from a sender: the tree of its parts with their byte ranges. Every range must lie in the
//! message, every part inside its parent, its parts in order.
#![no_main]

use libfuzzer_sys::fuzz_target;

fuzz_target!(|data: &[u8]| {
    let outline = pe_mime::outline::outline(data);
    for part in &outline.parts {
        assert!(part.start <= part.body && part.body <= part.end && part.end <= data.len());
        let mut previous = part.body;
        for &child in &part.children {
            let child = &outline.parts[child];
            assert!(child.start >= previous && child.end <= part.end);
            previous = child.end;
        }
    }
});
