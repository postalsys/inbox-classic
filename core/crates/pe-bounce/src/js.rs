//! What the ported code needs to read text the way JavaScript does: its regular expressions, its
//! whitespace, and lengths counted in UTF-16 code units, all from pe-jsre.
//!
//! The patterns are kept as the JavaScript source writes them and translated by pe-jsre, so they
//! can be compared with the original line by line. Rust's engine runs in linear time, so none of
//! the care the JavaScript patterns take against backtracking is needed here; the caps on input
//! length are kept so the results stay the same.

pub(crate) use pe_jsre::{collapse, is_space, regex, trim, truncate_utf16};
