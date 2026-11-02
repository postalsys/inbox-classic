//! Connections to mail servers, shared by IMAP (pe-imap) and SMTP (pe-smtp).
#![forbid(unsafe_code)]

pub mod stream;
pub mod tls;

pub use stream::{Error, Security, Stream};
pub use tls::{TlsFailure, TlsFailureKind, Trust};
