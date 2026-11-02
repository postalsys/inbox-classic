//! What IMAP and SMTP sessions share besides the connection: the credentials and the protocol log

use std::fmt;
use std::sync::Arc;

#[derive(Clone, PartialEq, Eq)]
pub enum Credentials {
    Password {
        user: String,
        password: String,
    },
    /// An OAuth 2.0 access token (Gmail, Outlook.com)
    OAuth2 {
        user: String,
        access_token: String,
    },
}

/// Never prints the secret
impl fmt::Debug for Credentials {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        match self {
            Credentials::Password { user, .. } => write!(f, "Password({user})"),
            Credentials::OAuth2 { user, .. } => write!(f, "OAuth2({user})"),
        }
    }
}

/// Which way a line of a session went
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum Direction {
    Client,
    Server,
}

/// Receives the protocol log of a session, secrets hidden
pub type WireLog = Arc<dyn Fn(Direction, &str) + Send + Sync>;

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn secrets_are_not_printed() {
        let password = Credentials::Password {
            user: "u".into(),
            password: "secret".into(),
        };
        let token = Credentials::OAuth2 {
            user: "u".into(),
            access_token: "token".into(),
        };
        assert_eq!(format!("{password:?} {token:?}"), "Password(u) OAuth2(u)");
    }
}
