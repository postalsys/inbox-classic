//! String helpers with JavaScript semantics.
//!
//! email-content measures lengths in UTF-16 code units, and several thresholds (line length caps,
//! stub detection, position features) depend on those lengths. The port keeps byte offsets for
//! everything it reports and uses these helpers wherever a length is compared with a threshold.

pub(crate) use pe_jsre::{
    advance_utf16 as advance_units, is_blank, trim as js_trim, utf16_len as js_len, words as js_words,
};
