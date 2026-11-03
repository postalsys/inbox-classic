//! A whole sign-in against a mock provider on 127.0.0.1: the "browser" goes to the redirect address with a
//! code, the token endpoint checks the PKCE verifier against the challenge of the sign-in page, and a refresh
//! gives a new access token

use std::sync::{Arc, Mutex};
use std::time::Duration;

use base64::Engine;
use base64::engine::general_purpose::URL_SAFE_NO_PAD;
use pe_oauth::{Endpoint, OAuthError, Provider, ProviderKind, SignIn, refresh};
use tokio::io::{AsyncReadExt, AsyncWriteExt};
use tokio::net::{TcpListener, TcpStream};

fn param(query: &str, key: &str) -> Option<String> {
    pe_net::http::query_param(query, key)
}

/// A token endpoint that answers like a provider: the code once with the right verifier, refreshes with the
/// refresh token, `invalid_grant` for anything else
async fn token_server(challenge: Arc<Mutex<String>>) -> u16 {
    let listener = TcpListener::bind("127.0.0.1:0").await.unwrap();
    let port = listener.local_addr().unwrap().port();
    tokio::spawn(async move {
        loop {
            let (mut socket, _) = listener.accept().await.unwrap();
            let mut request = Vec::new();
            let mut chunk = [0u8; 4096];
            loop {
                let read = socket.read(&mut chunk).await.unwrap();
                request.extend_from_slice(&chunk[..read]);
                let text = String::from_utf8_lossy(&request);
                if let Some((head, body)) = text.split_once("\r\n\r\n") {
                    let length: usize = head
                        .lines()
                        .find_map(|l| l.strip_prefix("Content-Length: "))
                        .map_or(0, |l| l.parse().unwrap());
                    if body.len() >= length || read == 0 {
                        break;
                    }
                }
            }
            let text = String::from_utf8_lossy(&request).into_owned();
            let form = text.split_once("\r\n\r\n").unwrap().1;
            let verifier_ok = param(form, "code_verifier").is_some_and(|v| {
                let digest = ring::digest::digest(&ring::digest::SHA256, v.as_bytes());
                URL_SAFE_NO_PAD.encode(digest) == *challenge.lock().unwrap()
            });
            let (status, body) = match param(form, "grant_type").as_deref() {
                Some("authorization_code") if param(form, "code").as_deref() == Some("the-code") && verifier_ok => {
                    let claims = r#"{"aud":"client","email":"me@example.com","email_verified":true,"name":"Me"}"#;
                    let id_token = format!("e30.{}.c2ln", URL_SAFE_NO_PAD.encode(claims));
                    (
                        200,
                        format!(
                            r#"{{"access_token":"testtoken","refresh_token":"r1","expires_in":3600,"token_type":"Bearer","id_token":"{id_token}"}}"#
                        ),
                    )
                }
                Some("refresh_token") if param(form, "refresh_token").as_deref() == Some("r1") => {
                    (200, r#"{"access_token":"fresh","expires_in":3600}"#.to_string())
                }
                _ => (
                    400,
                    r#"{"error":"invalid_grant","error_description":"Bad Request"}"#.to_string(),
                ),
            };
            let response = format!(
                "HTTP/1.1 {status} X\r\nContent-Type: application/json\r\nContent-Length: {}\r\n\r\n{body}",
                body.len()
            );
            socket.write_all(response.as_bytes()).await.unwrap();
        }
    });
    port
}

fn provider(port: u16) -> Provider {
    let endpoint = Endpoint {
        host: "mail.example.com".into(),
        port: 993,
        security: pe_net::Security::Tls,
    };
    Provider {
        kind: ProviderKind::Google,
        imap: endpoint.clone(),
        smtp: endpoint,
        authorize_url: "https://accounts.example.com/auth".into(),
        token_url: format!("http://127.0.0.1:{port}/token"),
        scopes: vec!["mail".into()],
        client_id: "client".into(),
        client_secret: Some("not-secret".into()),
        response_issuer: None,
    }
}

/// What the browser does after the user signed in: goes to the redirect address with a code
async fn browser(url: &str, code: Option<&str>, state_override: Option<&str>) -> String {
    let query = url.split_once('?').unwrap().1;
    let redirect = param(query, "redirect_uri").unwrap();
    let state = state_override
        .map(str::to_string)
        .unwrap_or_else(|| param(query, "state").unwrap());
    browser_at(&redirect, &redirect_host(&redirect), code, &state).await
}

/// The host of the redirect address `http://host:port/`
fn redirect_host(redirect: &str) -> String {
    let address = redirect.strip_prefix("http://").unwrap().trim_end_matches('/');
    address.rsplit_once(':').unwrap().0.to_string()
}

/// The browser's request to the redirect address, made to `host` (a name or an address of it)
async fn browser_at(redirect: &str, host: &str, code: Option<&str>, state: &str) -> String {
    let port: u16 = redirect
        .trim_end_matches('/')
        .rsplit(':')
        .next()
        .unwrap()
        .parse()
        .unwrap();
    let target = match code {
        Some(code) => format!("/?code={code}&state={state}&scope=mail"),
        None => format!("/?error=access_denied&state={state}"),
    };
    let mut socket = TcpStream::connect((host, port)).await.unwrap();
    socket
        .write_all(format!("GET {target} HTTP/1.1\r\nHost: {host}\r\n\r\n").as_bytes())
        .await
        .unwrap();
    let mut page = String::new();
    socket.read_to_string(&mut page).await.unwrap();
    page
}

#[tokio::test]
async fn signs_in_and_refreshes() {
    let challenge = Arc::new(Mutex::new(String::new()));
    let port = token_server(challenge.clone()).await;
    let sign_in = SignIn::begin(provider(port), "me@example.com").unwrap();
    let url = sign_in.url.clone();
    *challenge.lock().unwrap() = param(url.split_once('?').unwrap().1, "code_challenge").unwrap();
    assert!(url.contains("access_type=offline") && url.contains("prompt=consent"));

    let waiting = tokio::spawn(sign_in.finish(Duration::from_secs(10)));
    // a request that is not the redirect, then one of another sign-in: both answered and ignored
    assert!(
        browser(&url, Some("x"), Some("wrong-state"))
            .await
            .contains("not part of signing in")
    );
    assert!(
        browser(&url, Some("the-code"), None)
            .await
            .contains("You are signed in")
    );
    let tokens = waiting.await.unwrap().unwrap();
    assert_eq!(tokens.access_token, "testtoken");
    assert_eq!(tokens.refresh_token.as_deref(), Some("r1"));
    let identity = tokens.identity.unwrap();
    assert_eq!(
        (identity.email.as_str(), identity.name.as_deref()),
        ("me@example.com", Some("Me"))
    );

    let refreshed = refresh(&provider(port), "r1").await.unwrap();
    assert_eq!(
        (refreshed.access_token.as_str(), refreshed.refresh_token.as_deref()),
        ("fresh", Some("r1"))
    );
    assert_eq!(refreshed.identity, None);
    let revoked = refresh(&provider(port), "revoked").await.unwrap_err();
    assert!(revoked.needs_sign_in(), "{revoked}");
}

#[tokio::test]
async fn cancelled_and_slow_sign_ins() {
    let challenge = Arc::new(Mutex::new(String::new()));
    let port = token_server(challenge).await;
    let sign_in = SignIn::begin(provider(port), "me@example.com").unwrap();
    let url = sign_in.url.clone();
    let waiting = tokio::spawn(sign_in.finish(Duration::from_secs(10)));
    assert!(browser(&url, None, None).await.contains("cancelled"));
    assert!(matches!(waiting.await.unwrap(), Err(OAuthError::Denied(ref r)) if r == "access_denied"));

    let slow = SignIn::begin(provider(port), "me@example.com").unwrap();
    assert!(matches!(
        slow.finish(Duration::from_millis(100)).await,
        Err(OAuthError::TimedOut)
    ));
}

/// Microsoft takes only the `localhost` it was registered with, on any port: the browser comes back to that name,
/// which it may look up as ::1 or 127.0.0.1, and the sign-in hears both
#[tokio::test]
async fn microsoft_comes_back_to_localhost() {
    let challenge = Arc::new(Mutex::new(String::new()));
    let port = token_server(challenge.clone()).await;
    let microsoft = Provider {
        kind: ProviderKind::Microsoft,
        client_secret: None,
        ..provider(port)
    };
    for host in ["::1", "127.0.0.1"] {
        let sign_in = SignIn::begin(microsoft.clone(), "me@example.com").unwrap();
        let url = sign_in.url.clone();
        let query = url.split_once('?').unwrap().1;
        let redirect = param(query, "redirect_uri").unwrap();
        assert!(redirect.starts_with("http://localhost:"), "{redirect}");
        *challenge.lock().unwrap() = param(query, "code_challenge").unwrap();
        // a machine without IPv6 has no ::1 to come back to
        if host == "::1" && std::net::TcpListener::bind(("::1", 0)).is_err() {
            continue;
        }
        let state = param(query, "state").unwrap();
        let waiting = tokio::spawn(sign_in.finish(Duration::from_secs(10)));
        let page = browser_at(&redirect, host, Some("the-code"), &state).await;
        assert!(page.contains("You are signed in"), "{host}: {page}");
        assert_eq!(waiting.await.unwrap().unwrap().access_token, "testtoken");
    }
}
