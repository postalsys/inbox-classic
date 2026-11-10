//! MIME: decoding of header values and parameters, and parsing of messages for display (a port of
//! postal-mime, ../postal-mime/src).
#![forbid(unsafe_code)]

pub mod charset;
pub mod date;
pub mod envelope;
pub mod otp;
pub mod params;
pub mod parser;
pub mod words;

pub use envelope::{Address, Envelope};
pub use otp::{OtpToken, otp_token};
pub use params::decode_params;
pub use words::decode_words;
