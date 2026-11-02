//! Connections to mail servers, shared by IMAP (pe-imap) and SMTP (pe-smtp).
#![forbid(unsafe_code)]

pub mod stream;
pub mod tls;

pub use stream::{ConnectError, Security, Stream};
pub use tls::{TlsFailure, Trust};
