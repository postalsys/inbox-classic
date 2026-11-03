//! OAuth 2.0 sign-in for mail accounts (RFC 8252, native apps): the browser opens the provider's sign-in page,
//! the provider sends the browser back to a listener on the loopback address with a code, and the code is exchanged for
//! tokens, with PKCE (RFC 7636) so a code caught on the way is of no use. The refresh token is the account's
//! secret; access tokens are made from it when needed.
//!
//! The client IDs are those Postal Systems registered with the providers, built in ([`GOOGLE_CLIENT_ID`],
//! [`MICROSOFT_CLIENT_ID`]); `PE_GOOGLE_CLIENT_ID`, `PE_GOOGLE_CLIENT_SECRET` and `PE_MICROSOFT_CLIENT_ID` at build
//! time replace them.
#![forbid(unsafe_code)]

mod redirect;

use std::fmt;
use std::time::Duration;

use base64::Engine;
use base64::engine::general_purpose::URL_SAFE_NO_PAD;
use pe_net::http::{self, HttpError, form_encode};
use serde_json::Value;
use tokio::net::TcpListener;

/// How long the user has to sign in
pub const SIGN_IN_TIMEOUT: Duration = Duration::from_secs(300);
const TOKEN_TIMEOUT: Duration = Duration::from_secs(30);

#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash)]
pub enum ProviderKind {
    Google,
    Microsoft,
}

impl ProviderKind {
    pub fn as_str(self) -> &'static str {
        match self {
            ProviderKind::Google => "google",
            ProviderKind::Microsoft => "microsoft",
        }
    }

    pub fn parse(value: &str) -> Option<ProviderKind> {
        match value {
            "google" => Some(ProviderKind::Google),
            "microsoft" => Some(ProviderKind::Microsoft),
            _ => None,
        }
    }

    /// The host of the loopback redirect address. Microsoft Entra matches a registered `http://localhost` with any
    /// port but takes 127.0.0.1 for another address; Google's Desktop App clients take 127.0.0.1 (RFC 8252 7.3).
    pub fn redirect_host(self) -> &'static str {
        match self {
            ProviderKind::Google => "127.0.0.1",
            ProviderKind::Microsoft => "localhost",
        }
    }

    /// The provider whose IMAP server this is
    pub fn for_imap_host(host: &str) -> Option<ProviderKind> {
        match host.to_ascii_lowercase().as_str() {
            "imap.gmail.com" | "imap.googlemail.com" => Some(ProviderKind::Google),
            "outlook.office365.com" | "imap-mail.outlook.com" => Some(ProviderKind::Microsoft),
            _ => None,
        }
    }
}

/// A server of a provider
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct Endpoint {
    pub host: String,
    pub port: u16,
    pub security: pe_net::Security,
}

/// What a provider needs to be signed in with, and its servers: an account signed in to a provider uses those,
/// so its access tokens go nowhere else
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct Provider {
    pub kind: ProviderKind,
    pub imap: Endpoint,
    pub smtp: Endpoint,
    pub authorize_url: String,
    pub token_url: String,
    pub scopes: Vec<String>,
    pub client_id: String,
    /// Google gives desktop apps a "secret" that is not one (RFC 8252 8.5); None for others
    pub client_secret: Option<String>,
}

/// The Desktop App ("installed") client of the inbox-classic project in Google Cloud: a loopback redirect to
/// 127.0.0.1 on any port, with PKCE
pub const GOOGLE_CLIENT_ID: &str = "442308651621-5je5iul1c07rg8gse9gpr12difuusmmr.apps.googleusercontent.com";
/// Google gives every Desktop App client a "secret" and wants it with each token request, but it is not one: it ships
/// in every copy of the app, where nobody can keep it (RFC 8252 8.5). PKCE, not this, keeps a caught code useless.
pub const GOOGLE_CLIENT_SECRET: &str = "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";

/// The public client ("Mobile and desktop applications", public client flows on) registered in Microsoft Entra for
/// personal Microsoft accounts and work or school ones (the `common` endpoints), with a loopback redirect: no secret
pub const MICROSOFT_CLIENT_ID: &str = "7f84440c-d933-434d-b85f-9a74085a0945";

/// Microsoft's sign-in service, for personal accounts and every organization
const MICROSOFT_LOGIN: &str = "https://login.microsoftonline.com";

/// The Microsoft client of this build: `PE_MICROSOFT_CLIENT_ID`, or the built-in one
fn microsoft_client_id() -> &'static str {
    configured(option_env!("PE_MICROSOFT_CLIENT_ID")).unwrap_or(MICROSOFT_CLIENT_ID)
}

/// A build-time override, when it is there and not empty
fn configured(value: Option<&'static str>) -> Option<&'static str> {
    value.filter(|value| !value.trim().is_empty())
}

impl Provider {
    /// The provider with the client ID this build has for it
    pub fn builtin(kind: ProviderKind) -> Provider {
        match kind {
            ProviderKind::Google => Provider {
                kind,
                imap: Endpoint {
                    host: "imap.gmail.com".into(),
                    port: 993,
                    security: pe_net::Security::Tls,
                },
                smtp: Endpoint {
                    host: "smtp.gmail.com".into(),
                    port: 465,
                    security: pe_net::Security::Tls,
                },
                authorize_url: "https://accounts.google.com/o/oauth2/v2/auth".into(),
                token_url: "https://oauth2.googleapis.com/token".into(),
                scopes: vec!["https://mail.google.com/".into()],
                client_id: configured(option_env!("PE_GOOGLE_CLIENT_ID"))
                    .unwrap_or(GOOGLE_CLIENT_ID)
                    .into(),
                client_secret: Some(
                    configured(option_env!("PE_GOOGLE_CLIENT_SECRET"))
                        .unwrap_or(GOOGLE_CLIENT_SECRET)
                        .into(),
                ),
            },
            ProviderKind::Microsoft => Provider {
                kind,
                imap: Endpoint {
                    host: "outlook.office365.com".into(),
                    port: 993,
                    security: pe_net::Security::Tls,
                },
                smtp: Endpoint {
                    host: "smtp.office365.com".into(),
                    port: 587,
                    security: pe_net::Security::StartTls,
                },
                authorize_url: format!("{MICROSOFT_LOGIN}/common/oauth2/v2.0/authorize"),
                token_url: format!("{MICROSOFT_LOGIN}/common/oauth2/v2.0/token"),
                scopes: [
                    "https://outlook.office.com/IMAP.AccessAsUser.All",
                    "https://outlook.office.com/SMTP.Send",
                    "offline_access",
                ]
                .map(String::from)
                .to_vec(),
                client_id: microsoft_client_id().into(),
                client_secret: None,
            },
        }
    }
}

#[derive(Debug, Clone, PartialEq, Eq)]
pub struct Tokens {
    pub access_token: String,
    /// What to make new access tokens with; a refresh may give a new one
    pub refresh_token: Option<String>,
    /// Seconds since the Unix epoch
    pub expires_at: i64,
}

#[derive(Debug)]
pub enum OAuthError {
    /// The provider's answer was no answer (an error page, a portal): try again later
    Unavailable(String),
    /// The user said no, or closed the page
    Denied(String),
    /// The account's organization has not approved the app (Microsoft Entra admin consent): only its administrator
    /// can, at [`admin_consent_url`]
    NeedsAdmin,
    /// The redirect did not come in time
    TimedOut,
    /// The redirect was not for this sign-in: another state, no code
    BadRedirect,
    /// The provider refused the code or the refresh token; signing in again is needed
    Refused(String),
    Http(HttpError),
    Io(std::io::Error),
}

impl OAuthError {
    /// Whether the user has to sign in again, rather than wait for the network
    pub fn needs_sign_in(&self) -> bool {
        matches!(
            self,
            OAuthError::Refused(_) | OAuthError::Denied(_) | OAuthError::NeedsAdmin
        )
    }
}

impl fmt::Display for OAuthError {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        match self {
            OAuthError::Unavailable(reason) => write!(f, "the provider did not answer properly: {reason}"),
            OAuthError::Denied(reason) => write!(f, "signing in was cancelled: {reason}"),
            OAuthError::NeedsAdmin => write!(
                f,
                "your organization's administrator has to approve Inbox Classic first; they can do it at {}",
                admin_consent_url()
            ),
            OAuthError::TimedOut => f.write_str("signing in took too long"),
            OAuthError::BadRedirect => f.write_str("the browser came back from another sign-in"),
            OAuthError::Refused(reason) => write!(f, "the provider refused the sign-in: {reason}"),
            OAuthError::Http(error) => write!(f, "{error}"),
            OAuthError::Io(error) => write!(f, "{error}"),
        }
    }
}

impl std::error::Error for OAuthError {}

fn random_token(bytes: usize) -> std::io::Result<String> {
    let mut random = vec![0u8; bytes];
    getrandom::fill(&mut random).map_err(|e| std::io::Error::other(e.to_string()))?;
    Ok(URL_SAFE_NO_PAD.encode(random))
}

/// The PKCE challenge of a verifier: base64url of its SHA-256
fn challenge(verifier: &str) -> String {
    URL_SAFE_NO_PAD.encode(ring::digest::digest(&ring::digest::SHA256, verifier.as_bytes()))
}

/// A sign-in that waits for the browser
pub struct SignIn {
    provider: Provider,
    listener: std::net::TcpListener,
    /// The same port on ::1, where a browser may go first for `localhost`
    listener_v6: Option<std::net::TcpListener>,
    redirect_uri: String,
    verifier: String,
    state: String,
    /// The page to open in the browser
    pub url: String,
}

impl SignIn {
    /// Starts listening for the redirect and makes the page to open for `email`
    pub fn begin(provider: Provider, email: &str) -> Result<SignIn, OAuthError> {
        let listener = std::net::TcpListener::bind("127.0.0.1:0").map_err(OAuthError::Io)?;
        listener.set_nonblocking(true).map_err(OAuthError::Io)?;
        let port = listener.local_addr().map_err(OAuthError::Io)?.port();
        // without IPv6, or with the port taken there, the browser falls back to 127.0.0.1
        let listener_v6 = std::net::TcpListener::bind(("::1", port))
            .and_then(|l| l.set_nonblocking(true).map(|_| l))
            .ok();
        let redirect_uri = format!("http://{}:{port}/", provider.kind.redirect_host());
        let verifier = random_token(32).map_err(OAuthError::Io)?;
        let state = random_token(16).map_err(OAuthError::Io)?;
        let mut params = vec![
            ("response_type", "code".to_string()),
            ("client_id", provider.client_id.clone()),
            ("redirect_uri", redirect_uri.clone()),
            ("scope", provider.scopes.join(" ")),
            ("state", state.clone()),
            ("code_challenge", challenge(&verifier)),
            ("code_challenge_method", "S256".into()),
            ("login_hint", email.to_string()),
        ];
        if provider.kind == ProviderKind::Google {
            // a refresh token, every time
            params.push(("access_type", "offline".into()));
            params.push(("prompt", "consent".into()));
        }
        let pairs: Vec<(&str, &str)> = params.iter().map(|(k, v)| (*k, v.as_str())).collect();
        let url = format!("{}?{}", provider.authorize_url, form_encode(&pairs));
        Ok(SignIn {
            provider,
            listener,
            listener_v6,
            redirect_uri,
            verifier,
            state,
            url,
        })
    }

    /// Waits for the browser to come back, then exchanges the code for tokens
    pub async fn finish(self, timeout: Duration) -> Result<Tokens, OAuthError> {
        let listener = TcpListener::from_std(self.listener).map_err(OAuthError::Io)?;
        let listener_v6 = self.listener_v6.and_then(|l| TcpListener::from_std(l).ok());
        let code = tokio::time::timeout(timeout, redirect::receive(&listener, listener_v6.as_ref(), &self.state))
            .await
            .map_err(|_| OAuthError::TimedOut)??;
        let mut form = vec![
            ("grant_type", "authorization_code"),
            ("code", code.as_str()),
            ("redirect_uri", self.redirect_uri.as_str()),
            ("client_id", self.provider.client_id.as_str()),
            ("code_verifier", self.verifier.as_str()),
        ];
        if let Some(secret) = &self.provider.client_secret {
            form.push(("client_secret", secret));
        }
        token_request(&self.provider, &form, None).await
    }
}

/// A new access token from a refresh token
pub async fn refresh(provider: &Provider, refresh_token: &str) -> Result<Tokens, OAuthError> {
    let mut form = vec![
        ("grant_type", "refresh_token"),
        ("refresh_token", refresh_token),
        ("client_id", provider.client_id.as_str()),
    ];
    if let Some(secret) = &provider.client_secret {
        form.push(("client_secret", secret));
    }
    token_request(provider, &form, Some(refresh_token)).await
}

/// Seconds since the Unix epoch
pub fn now() -> i64 {
    std::time::SystemTime::now()
        .duration_since(std::time::UNIX_EPOCH)
        .map_or(0, |d| d.as_secs() as i64)
}

async fn token_request(
    provider: &Provider,
    form: &[(&str, &str)],
    refreshed: Option<&str>,
) -> Result<Tokens, OAuthError> {
    let response = http::post_form(&provider.token_url, form, TOKEN_TIMEOUT)
        .await
        .map_err(OAuthError::Http)?;
    parse_tokens(response.status, &response.body, refreshed, now())
}

/// Where an administrator of a Microsoft 365 organization approves the app for everyone in it
pub fn admin_consent_url() -> String {
    format!(
        "{MICROSOFT_LOGIN}/organizations/adminconsent?client_id={}",
        microsoft_client_id()
    )
}

/// Whether Microsoft's error text says the organization's administrator has to consent first: AADSTS65001 (no one
/// consented), 90094 (the grant needs an admin) and 90095 (the same, with the admin consent workflow on)
pub(crate) fn needs_admin(description: &str) -> bool {
    ["AADSTS65001", "AADSTS90094", "AADSTS90095"]
        .iter()
        .any(|code| description.contains(code))
}

/// The tokens of a token endpoint's answer (RFC 6749 5.1), or its error (5.2)
pub fn parse_tokens(status: u16, body: &[u8], refreshed: Option<&str>, now: i64) -> Result<Tokens, OAuthError> {
    let json: Value = serde_json::from_slice(body).map_err(|_| OAuthError::Refused(format!("HTTP {status}")))?;
    let text = |key: &str| {
        json.get(key)
            .and_then(Value::as_str)
            .filter(|v| !v.is_empty())
            .map(str::to_string)
    };
    if status != 200 {
        if text("error_description").is_some_and(|d| needs_admin(&d)) {
            return Err(OAuthError::NeedsAdmin);
        }
        let reason = [text("error"), text("error_description")]
            .into_iter()
            .flatten()
            .collect::<Vec<_>>()
            .join(": ");
        return Err(OAuthError::Refused(if reason.is_empty() {
            format!("HTTP {status}")
        } else {
            reason
        }));
    }
    let access_token = text("access_token").ok_or_else(|| OAuthError::Refused("no access token".into()))?;
    let expires_in = json
        .get("expires_in")
        .and_then(Value::as_i64)
        .unwrap_or(3600)
        .clamp(60, 86_400);
    Ok(Tokens {
        access_token,
        // a refresh answer may leave the refresh token out: the one used stays good
        refresh_token: text("refresh_token").or_else(|| refreshed.map(str::to_string)),
        // a minute early, so a token is not used as it runs out
        expires_at: now + expires_in - 60,
    })
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn google_is_built_in_with_its_desktop_client() {
        let google = Provider::builtin(ProviderKind::Google);
        assert!(google.client_id.ends_with(".apps.googleusercontent.com"));
        assert!(google.client_secret.as_deref().is_some_and(|secret| !secret.is_empty()));
        let microsoft = Provider::builtin(ProviderKind::Microsoft);
        assert_eq!(microsoft.client_id, MICROSOFT_CLIENT_ID);
        // a public client: no secret, PKCE alone
        assert_eq!(microsoft.client_secret, None);
        assert_eq!(configured(Some("  ")), None);
        assert_eq!(configured(Some("x")), Some("x"));
    }

    #[test]
    fn pkce() {
        // RFC 7636 appendix B
        assert_eq!(
            challenge("dBjftJeZ4CVP-mB92K27uhbUJU1p1r_wW1gFWFOEjXk"),
            "E9Melhoa2OwvFrEMTJguCHaoeK1t8URWbuGJSstw-cM"
        );
        assert_ne!(random_token(32).unwrap(), random_token(32).unwrap());
    }

    #[test]
    fn providers() {
        assert_eq!(
            ProviderKind::for_imap_host("IMAP.gmail.com"),
            Some(ProviderKind::Google)
        );
        assert_eq!(
            ProviderKind::for_imap_host("outlook.office365.com"),
            Some(ProviderKind::Microsoft)
        );
        assert_eq!(ProviderKind::for_imap_host("imap.example.com"), None);
        for kind in [ProviderKind::Google, ProviderKind::Microsoft] {
            assert_eq!(ProviderKind::parse(kind.as_str()), Some(kind));
        }
    }

    #[test]
    fn token_answers() {
        let ok = parse_tokens(
            200,
            br#"{"access_token":"a","refresh_token":"r","expires_in":3600}"#,
            None,
            1000,
        )
        .unwrap();
        assert_eq!(
            ok,
            Tokens {
                access_token: "a".into(),
                refresh_token: Some("r".into()),
                expires_at: 1000 + 3600 - 60
            }
        );
        let refreshed = parse_tokens(200, br#"{"access_token":"b","expires_in":10}"#, Some("old"), 0).unwrap();
        assert_eq!(
            (refreshed.refresh_token.as_deref(), refreshed.expires_at),
            (Some("old"), 0)
        );
        let refused = parse_tokens(
            400,
            br#"{"error":"invalid_grant","error_description":"Token has been revoked."}"#,
            None,
            0,
        );
        assert!(matches!(refused, Err(OAuthError::Refused(ref r)) if r == "invalid_grant: Token has been revoked."));
        assert!(refused.unwrap_err().needs_sign_in());
        // an organization that has not approved the app: only its administrator can help
        let admin = parse_tokens(
            400,
            br#"{"error":"invalid_grant","error_description":"AADSTS65001: The user or administrator has not consented to use the application."}"#,
            None,
            0,
        )
        .unwrap_err();
        assert!(matches!(admin, OAuthError::NeedsAdmin) && admin.needs_sign_in());
        assert!(admin.to_string().ends_with(&admin_consent_url()));
        assert!(matches!(
            parse_tokens(200, b"<html>", None, 0),
            Err(OAuthError::Refused(_))
        ));
        assert!(matches!(
            parse_tokens(200, br#"{"token_type":"Bearer"}"#, None, 0),
            Err(OAuthError::Refused(_))
        ));
    }

    fn test_provider(token_url: &str) -> Provider {
        let endpoint = Endpoint {
            host: "mail.example.com".into(),
            port: 993,
            security: pe_net::Security::Tls,
        };
        Provider {
            kind: ProviderKind::Microsoft,
            imap: endpoint.clone(),
            smtp: endpoint,
            authorize_url: "https://login.example.com/authorize".into(),
            token_url: token_url.into(),
            scopes: vec!["mail".into(), "offline_access".into()],
            client_id: "client id".into(),
            client_secret: None,
        }
    }

    #[tokio::test]
    async fn sign_in_url() {
        let sign_in = SignIn::begin(test_provider("https://login.example.com/token"), "me@example.com").unwrap();
        let url = &sign_in.url;
        assert!(url.starts_with("https://login.example.com/authorize?response_type=code&client_id=client%20id&redirect_uri=http%3A%2F%2Flocalhost%3A"), "{url}");
        assert_eq!(ProviderKind::Google.redirect_host(), "127.0.0.1");
        assert!(url.contains("&scope=mail%20offline_access&state="));
        assert!(url.contains(&format!(
            "&code_challenge={}&code_challenge_method=S256",
            challenge(&sign_in.verifier)
        )));
        assert!(url.contains("&login_hint=me%40example.com"));
        assert!(!url.contains(&sign_in.verifier), "the verifier stays here");
    }
}
