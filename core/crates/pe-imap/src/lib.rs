//! IMAP client, a port of imapflow (../imapflow/src). The protocol layer is pure and works on
//! bytes: [`framing`] splits what the server sends into responses, [`parser`] turns a response
//! into tokens and [`compiler`] writes commands. The connection layer sits on top of it.
#![forbid(unsafe_code)]

pub mod compiler;
pub mod error;
pub mod framing;
pub mod message;
pub mod parser;
mod syntax;
pub mod types;
pub mod utf7;

pub use compiler::{Arg, Command, CompileOptions, compile, to_log_string};
pub use error::{CompileError, ParseError};
pub use framing::{FrameLimits, Framer, RawResponse};
pub use message::{Address, BodyStructure, Envelope, parse_body_structure, parse_envelope};
pub use parser::{ParserOptions, parse, parse_with};
pub use types::{Atom, Response, Token};
