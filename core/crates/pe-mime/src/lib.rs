//! MIME: decoding of header values and parameters, and parsing of messages for display (a port of
//! postal-mime, ../postal-mime/src).
#![forbid(unsafe_code)]

pub mod charset;
pub mod date;
pub mod params;
pub mod words;

pub use params::decode_params;
pub use words::decode_words;
