use std::fmt;

use pe_net::{ConnectError, TlsFailure};

use crate::error::{CompileError, ParseError};

#[derive(Debug)]
pub enum Error {
    Io(std::io::Error),
    /// The TLS handshake failed; `certificate` is what the server presented, for the user to
    /// look at and pin
    Tls {
        message: String,
        certificate: Option<Vec<u8>>,
    },
    /// Connecting or waiting for the server took too long
    Timeout,
    /// The server sent something that is not IMAP
    Protocol(ParseError),
    /// A value that can not be written into a command
    Command(CompileError),
    /// The server answered NO or BAD
    Refused {
        command: String,
        status: String,
        /// The response code, `TRYCREATE`, `NONEXISTENT`, ...
        code: Option<String>,
        text: String,
    },
    AuthenticationFailed {
        code: Option<String>,
        text: String,
    },
    /// The server offers no authentication method that fits the credentials
    NoAuthenticationMethod,
    /// The connection is closed, with the server's BYE text if it sent one
    Closed(Option<String>),
    /// STARTTLS was required but the server does not offer it
    StartTlsUnavailable,
    /// The server sent plaintext after agreeing to STARTTLS and before the handshake
    StartTlsInjection,
    /// A command needs a selected mailbox
    NoMailboxSelected,
    TooManyResponses,
    Unexpected(String),
}

impl fmt::Display for Error {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        match self {
            Error::Io(error) => write!(f, "connection error: {error}"),
            Error::Tls { message, .. } => write!(f, "TLS error: {message}"),
            Error::Timeout => f.write_str("the server did not answer in time"),
            Error::Protocol(error) => write!(f, "invalid response from the server: {error}"),
            Error::Command(error) => write!(f, "invalid command: {error}"),
            Error::Refused {
                command, status, text, ..
            } => write!(f, "{command} failed ({status}): {text}"),
            Error::AuthenticationFailed { text, .. } => write!(f, "authentication failed: {text}"),
            Error::NoAuthenticationMethod => f.write_str("the server offers no usable authentication method"),
            Error::Closed(Some(text)) => write!(f, "the server closed the connection: {text}"),
            Error::Closed(None) => f.write_str("the connection is closed"),
            Error::StartTlsUnavailable => f.write_str("the server does not offer STARTTLS"),
            Error::StartTlsInjection => f.write_str("the server sent unencrypted data during STARTTLS"),
            Error::NoMailboxSelected => f.write_str("no mailbox is selected"),
            Error::TooManyResponses => f.write_str("the server sent too many responses"),
            Error::Unexpected(text) => write!(f, "unexpected response: {text}"),
        }
    }
}

impl std::error::Error for Error {}

impl From<std::io::Error> for Error {
    fn from(error: std::io::Error) -> Self {
        Error::Io(error)
    }
}

impl From<TlsFailure> for Error {
    fn from(failure: TlsFailure) -> Self {
        Error::Tls {
            message: failure.message,
            certificate: failure.certificate,
        }
    }
}

impl From<ConnectError> for Error {
    fn from(error: ConnectError) -> Self {
        match error {
            ConnectError::Io(error) => Error::Io(error),
            ConnectError::Timeout => Error::Timeout,
            ConnectError::Tls(failure) => failure.into(),
        }
    }
}

impl From<ParseError> for Error {
    fn from(error: ParseError) -> Self {
        Error::Protocol(error)
    }
}

impl From<CompileError> for Error {
    fn from(error: CompileError) -> Self {
        Error::Command(error)
    }
}
