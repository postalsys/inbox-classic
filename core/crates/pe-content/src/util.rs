//! String helpers with JavaScript semantics.
//!
//! email-content measures lengths in UTF-16 code units, and several thresholds (line length caps,
//! stub detection, position features) depend on those lengths. The port keeps byte offsets for
//! everything it reports and uses these helpers wherever a length is compared with a threshold.

use crate::jsre::is_js_ws;

/// `String.prototype.length`.
pub(crate) fn js_len(s: &str) -> usize {
    if s.is_ascii() {
        s.len()
    } else {
        s.chars().map(char::len_utf16).sum()
    }
}

/// `String.prototype.trim`.
pub(crate) fn js_trim(s: &str) -> &str {
    s.trim_matches(is_js_ws)
}

/// True when `s` has nothing but JavaScript whitespace.
pub(crate) fn is_blank(s: &str) -> bool {
    s.chars().all(is_js_ws)
}

/// `str.split(/\s+/).filter(Boolean)`.
pub(crate) fn js_words(s: &str) -> impl Iterator<Item = &str> {
    s.split(is_js_ws).filter(|word| !word.is_empty())
}

/// Byte index of the position `units` UTF-16 code units after `from`, or the end of `s`.
pub(crate) fn advance_units(s: &str, from: usize, units: usize) -> usize {
    let mut taken = 0;
    for (at, c) in s[from..].char_indices() {
        if taken >= units {
            return from + at;
        }
        taken += c.len_utf16();
    }
    s.len()
}
