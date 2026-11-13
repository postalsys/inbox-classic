use std::fmt;

use crate::error::{CompileError, ParseError};

/// What kind of failure an error is, for what the app does about it
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum ErrorKind {
    /// The network or the server is not reachable or stopped answering: try again later
    Network,
    /// TLS failed or could not be had (a certificate to show the user, STARTTLS missing)
    Security,
    /// The credentials were refused, or no method fits them: ask the user
    Authentication,
    /// The server refused a command
    Refused,
    /// The server sent something that is not IMAP
    Protocol,
    /// The connection is closed
    Closed,
    /// The command can not be made with what the caller gave
    Usage,
}

#[derive(Debug)]
pub enum Error {
    /// Connecting, TLS, or reading and writing failed. A TLS failure carries the certificate the
    /// server presented, for the user to look at and pin.
    Net(pe_net::Error),
    /// Waiting for the server took too long
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
    /// The server lacks the extension a command needs
    Unsupported(&'static str),
    TooManyResponses,
    Unexpected(String),
}

impl fmt::Display for Error {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        match self {
            Error::Net(error) => error.fmt(f),
            Error::Timeout => f.write_str("the server did not answer in time"),
            Error::Protocol(error) => write!(f, "invalid response from the server: {error}"),
            Error::Command(error) => write!(f, "invalid command: {error}"),
            Error::Refused {
                command, status, text, ..
            } => write!(f, "{command} failed ({status}): {text}"),
            Error::AuthenticationFailed { code: Some(code), text } if is_privacy_required(code) => {
                write!(
                    f,
                    "the server takes the password only over an encrypted connection: {text}"
                )
            }
            Error::AuthenticationFailed { text, .. } => write!(f, "authentication failed: {text}"),
            Error::NoAuthenticationMethod => f.write_str("the server offers no usable authentication method"),
            Error::Closed(Some(text)) => write!(f, "the server closed the connection: {text}"),
            Error::Closed(None) => f.write_str("the connection is closed"),
            Error::StartTlsUnavailable => f.write_str("the server does not offer STARTTLS"),
            Error::StartTlsInjection => f.write_str("the server sent unencrypted data during STARTTLS"),
            Error::NoMailboxSelected => f.write_str("no mailbox is selected"),
            Error::Unsupported(extension) => write!(f, "the server does not support {extension}"),
            Error::TooManyResponses => f.write_str("the server sent too many responses"),
            Error::Unexpected(text) => write!(f, "unexpected response: {text}"),
        }
    }
}

impl std::error::Error for Error {}

impl Error {
    pub fn kind(&self) -> ErrorKind {
        match self {
            Error::Net(pe_net::Error::Tls(_)) | Error::StartTlsUnavailable | Error::StartTlsInjection => {
                ErrorKind::Security
            }
            Error::Net(_) | Error::Timeout => ErrorKind::Network,
            // PRIVACYREQUIRED (RFC 5530): the password is taken only over an encrypted connection, typing it again
            // does not help
            Error::AuthenticationFailed { code: Some(code), .. } if is_privacy_required(code) => ErrorKind::Security,
            Error::AuthenticationFailed { .. } | Error::NoAuthenticationMethod => ErrorKind::Authentication,
            Error::Refused { .. } => ErrorKind::Refused,
            Error::Protocol(_) | Error::TooManyResponses | Error::Unexpected(_) => ErrorKind::Protocol,
            Error::Closed(_) => ErrorKind::Closed,
            Error::Command(_) | Error::NoMailboxSelected | Error::Unsupported(_) => ErrorKind::Usage,
        }
    }
}

impl Error {
    /// The server refused one more connection: too many are open already (`[LIMIT]`, `[INUSE]`, `[UNAVAILABLE]` at
    /// sign-in, or words such as Gmail's "Too many simultaneous connections" and Dovecot's "Maximum number of
    /// connections", in a BYE too), at the greeting or at sign-in. An app with a connection to spare does without it.
    pub fn is_connection_limit(&self) -> bool {
        let (code, text) = match self {
            Error::Closed(Some(text)) => (None, text.as_str()),
            Error::AuthenticationFailed { code, text } | Error::Refused { code, text, .. } => {
                (code.as_deref(), text.as_str())
            }
            _ => return false,
        };
        let limit_code = code.is_some_and(|code| {
            ["LIMIT", "INUSE", "UNAVAILABLE"]
                .iter()
                .any(|known| code.eq_ignore_ascii_case(known))
        });
        let text = text.to_ascii_lowercase();
        let in_words = text.contains("connection")
            && ["too many", "maximum number", "limit", "exceeded"]
                .iter()
                .any(|words| text.contains(words));
        limit_code || in_words
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn connection_limits_are_told_from_other_refusals() {
        let closed = |text: &str| Error::Closed(Some(text.into()));
        let login = |code: Option<&str>, text: &str| Error::AuthenticationFailed {
            code: code.map(Into::into),
            text: text.into(),
        };
        assert!(closed("Too many connections").is_connection_limit());
        assert!(
            closed("Maximum number of connections from user+IP exceeded (mail_max_userip_connections=10)")
                .is_connection_limit()
        );
        assert!(login(Some("ALERT"), "Too many simultaneous connections. (Failure)").is_connection_limit());
        assert!(login(Some("LIMIT"), "Try later").is_connection_limit());
        assert!(login(Some("UNAVAILABLE"), "Backend down").is_connection_limit());
        assert!(!login(Some("AUTHENTICATIONFAILED"), "Invalid credentials").is_connection_limit());
        assert!(!login(None, "Login failed").is_connection_limit());
        assert!(!closed("Autologout; idle for too long").is_connection_limit());
        assert!(!Error::Closed(None).is_connection_limit());
        assert!(!Error::Timeout.is_connection_limit());
    }
}

fn is_privacy_required(code: &str) -> bool {
    code.eq_ignore_ascii_case("PRIVACYREQUIRED")
}

impl From<pe_net::Error> for Error {
    fn from(error: pe_net::Error) -> Self {
        Error::Net(error)
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

#[cfg(test)]
mod privacy_tests {
    use super::*;

    #[test]
    fn a_login_refused_for_lack_of_encryption_is_a_security_problem() {
        let refused = |code: Option<&str>| Error::AuthenticationFailed {
            code: code.map(str::to_string),
            text: "x".into(),
        };
        assert_eq!(refused(Some("PRIVACYREQUIRED")).kind(), ErrorKind::Security);
        assert!(
            refused(Some("privacyrequired"))
                .to_string()
                .contains("encrypted connection")
        );
        assert_eq!(refused(Some("AUTHENTICATIONFAILED")).kind(), ErrorKind::Authentication);
        assert_eq!(refused(None).kind(), ErrorKind::Authentication);
    }
}
