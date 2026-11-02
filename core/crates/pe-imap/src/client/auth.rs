//! Authentication: AUTHENTICATE PLAIN or LOGIN for passwords, XOAUTH2 or OAUTHBEARER for access
//! tokens. Secrets go into commands marked sensitive, so the wire log never shows them.

use std::fmt;

use base64::Engine;
use base64::engine::general_purpose::STANDARD;

use super::{Client, Completion, Error};
use crate::compiler::Arg;

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

impl fmt::Debug for Credentials {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        match self {
            Credentials::Password { user, .. } => write!(f, "Password({user})"),
            Credentials::OAuth2 { user, .. } => write!(f, "OAuth2({user})"),
        }
    }
}

impl Client {
    pub(super) async fn authenticate(&mut self) -> Result<(), Error> {
        let result = match self.config.credentials.clone() {
            Credentials::Password { user, password } => self.password_login(&user, &password).await,
            Credentials::OAuth2 { user, access_token } => self.oauth_login(&user, &access_token).await,
        };
        let completion = match result {
            Err(Error::Refused { code, text, .. }) => return Err(Error::AuthenticationFailed { code, text }),
            other => other?,
        };
        // the capabilities change once authenticated, unless the OK of the login listed them
        if completion.tagged.code_args("CAPABILITY").is_some() {
            return Ok(());
        }
        self.capability().await
    }

    async fn password_login(&mut self, user: &str, password: &str) -> Result<Completion, Error> {
        if self.has_capability("AUTH=PLAIN") {
            // PLAIN carries UTF-8 user names and passwords as they are; NUL separates its fields
            if user.contains('\0') || password.contains('\0') {
                return Err(Error::NoAuthenticationMethod);
            }
            let token = STANDARD.encode(format!("\0{user}\0{password}"));
            return self.sasl("PLAIN", token).await;
        }
        if self.has_capability("LOGINDISABLED") {
            return Err(Error::NoAuthenticationMethod);
        }
        let args = vec![Arg::string(user), Arg::sensitive(Arg::string(password))];
        self.run("LOGIN", args).await
    }

    async fn oauth_login(&mut self, user: &str, token: &str) -> Result<Completion, Error> {
        if self.has_capability("AUTH=OAUTHBEARER") {
            let payload = format!("n,a={},\x01auth=Bearer {token}\x01\x01", escape_sasl_name(user));
            return self.sasl("OAUTHBEARER", STANDARD.encode(payload)).await;
        }
        if self.has_capability("AUTH=XOAUTH2") {
            let payload = format!("user={user}\x01auth=Bearer {token}\x01\x01");
            return self.sasl("XOAUTH2", STANDARD.encode(payload)).await;
        }
        Err(Error::NoAuthenticationMethod)
    }

    /// AUTHENTICATE with one message: inline with SASL-IR, otherwise after the first `+`. A `+`
    /// after that carries an error (the OAuth mechanisms), answered so that the server sends its
    /// NO: with %x01 for OAUTHBEARER (RFC 7628 section 3.2.3), an empty line for XOAUTH2.
    async fn sasl(&mut self, mechanism: &str, token: String) -> Result<Completion, Error> {
        let inline = self.has_capability("SASL-IR");
        let mut args = vec![Arg::atom(mechanism)];
        let mut pending = None;
        if inline {
            args.push(Arg::sensitive(Arg::atom(token)));
        } else {
            pending = Some(token);
        }
        let error_answer: &[u8] = if mechanism == "OAUTHBEARER" {
            b"AQ==\r\n"
        } else {
            b"\r\n"
        };
        let mut continuation = |_: &crate::types::Response| -> Result<Vec<u8>, Error> {
            Ok(match pending.take() {
                Some(token) => format!("{token}\r\n").into_bytes(),
                None => error_answer.to_vec(),
            })
        };
        self.run_with("AUTHENTICATE", args, &mut super::keep, Some(&mut continuation))
            .await
    }
}

/// `=` and `,` in an OAUTHBEARER authorization identity (RFC 5801)
fn escape_sasl_name(name: &str) -> String {
    name.replace('=', "=3D").replace(',', "=2C")
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn hides_secrets_in_debug_output() {
        let credentials = Credentials::Password {
            user: "u".into(),
            password: "secret".into(),
        };
        assert_eq!(format!("{credentials:?}"), "Password(u)");
        assert_eq!(escape_sasl_name("a=b,c"), "a=3Db=2Cc");
    }
}
