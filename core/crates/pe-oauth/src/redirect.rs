//! The browser coming back to 127.0.0.1 with the code: one request, read and answered here. Only a request with
//! this sign-in's state is taken; anything else gets a page saying so and the listener keeps waiting.

use tokio::io::{AsyncReadExt, AsyncWriteExt};
use tokio::net::{TcpListener, TcpStream};

use crate::{OAuthError, needs_admin};

/// The most of a request read: a redirect is one line
const MAX_REQUEST: usize = 16 * 1024;

/// What a redirect has to carry to be this sign-in's
#[derive(Clone, Copy)]
pub(crate) struct Expected<'a> {
    pub(crate) state: &'a str,
    /// The `iss` of a provider that sends one (RFC 9207): a redirect with another comes from a provider the
    /// browser was sent to by someone else, and is refused
    pub(crate) issuer: Option<&'a str>,
    /// The client signing in, for where an administrator approves it
    pub(crate) client_id: &'a str,
}

/// What a redirect says
#[derive(Debug, PartialEq, Eq)]
pub(crate) enum Redirect {
    Code(String),
    Denied(String),
    /// Refused because the organization's administrator has to approve the app first
    NeedsAdmin,
    /// This sign-in's state, from another issuer than the one signed in with
    WrongIssuer,
    /// Not this sign-in's, or not a redirect at all (a favicon request)
    Other,
}

/// The parameters of the request line `GET /?code=...&state=... HTTP/1.1`
pub(crate) fn parse_redirect(request: &[u8], expected: Expected) -> Redirect {
    let line = request.split(|b| *b == b'\n').next().unwrap_or_default();
    let line = String::from_utf8_lossy(line);
    let mut parts = line.split(' ');
    let (Some("GET"), Some(target)) = (parts.next(), parts.next()) else {
        return Redirect::Other;
    };
    let Some(query) = target.strip_prefix("/?") else {
        return Redirect::Other;
    };
    let mut code = None;
    let mut error = None;
    let mut description = String::new();
    let mut issuer = None;
    let mut matched = false;
    for pair in query.split('&') {
        let (key, value) = pair.split_once('=').unwrap_or((pair, ""));
        let value = pe_net::http::form_decode(value);
        match key {
            "code" => code = Some(value),
            "error" => error = Some(value),
            "error_description" => description = value,
            "iss" => issuer = Some(value),
            "state" => matched = constant_time_eq(value.as_bytes(), expected.state.as_bytes()),
            _ => {}
        }
    }
    if matched && expected.issuer.is_some() && issuer.as_deref() != expected.issuer {
        return Redirect::WrongIssuer;
    }
    match (matched, code, error) {
        (true, Some(code), None) if !code.is_empty() => Redirect::Code(code),
        (true, _, Some(_)) if needs_admin(&description) => Redirect::NeedsAdmin,
        (true, _, Some(error)) => Redirect::Denied(error),
        _ => Redirect::Other,
    }
}

fn constant_time_eq(a: &[u8], b: &[u8]) -> bool {
    a.len() == b.len() && a.iter().zip(b).fold(0u8, |acc, (x, y)| acc | (x ^ y)) == 0
}

/// What the browser shows once it came back: the app's mark, a heading and a line, in the system's light or dark
/// colors. Nothing in it comes from the request, and it runs no script and loads nothing (the CSP of `answer`).
fn page(heading: &str, text: &str, mark: Mark) -> String {
    let (symbol, color) = match mark {
        Mark::Done => ("<path d=\"M7 12.5l3.2 3.2L17 9\"/>", "#1a7f37"),
        Mark::Stopped => ("<path d=\"M8.5 8.5l7 7M15.5 8.5l-7 7\"/>", "#b42318"),
        Mark::Info => ("<path d=\"M12 11v5.5M12 7.6v.2\"/>", "#2a6fc0"),
    };
    format!(
        r##"<!doctype html><html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width, initial-scale=1"><title>{heading} - Inbox Classic</title><style>
:root{{color-scheme:light dark;--bg:#eef2f7;--card:#fff;--text:#1d2733;--muted:#5b6878;--line:#d8dee8}}
@media (prefers-color-scheme:dark){{:root{{--bg:#11161d;--card:#1b222c;--text:#e6ebf2;--muted:#9aa7b7;--line:#2c3542}}}}
*{{box-sizing:border-box}}
body{{margin:0;min-height:100vh;display:flex;align-items:center;justify-content:center;padding:24px;background:var(--bg);color:var(--text);font:15px/1.5 "Segoe UI",system-ui,-apple-system,sans-serif}}
main{{width:100%;max-width:440px;background:var(--card);border:1px solid var(--line);border-radius:14px;padding:36px 32px 30px;text-align:center;box-shadow:0 10px 30px rgba(16,32,64,.10)}}
.marks{{position:relative;width:64px;height:64px;margin:0 auto 20px}}
.app{{width:64px;height:64px;display:block}}
.state{{position:absolute;right:-8px;bottom:-8px;width:30px;height:30px;border-radius:50%;background:{color};border:3px solid var(--card)}}
.state svg{{width:100%;height:100%;display:block}}
h1{{font-size:21px;font-weight:600;margin:0 0 8px}}
p{{margin:0;color:var(--muted)}}
footer{{margin-top:22px;padding-top:16px;border-top:1px solid var(--line);font-size:13px;color:var(--muted)}}
</style></head><body><main>
<div class="marks"><svg class="app" viewBox="0 0 24 24" aria-hidden="true"><defs><linearGradient id="face" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#2a6fc0"/><stop offset="1" stop-color="#12417a"/></linearGradient></defs><rect width="24" height="24" rx="5" fill="url(#face)"/><path d="M5 8l7 5 7-5v9H5z" fill="none" stroke="#fff" stroke-width="1.6" stroke-linejoin="round"/></svg><span class="state"><svg viewBox="0 0 24 24" fill="none" stroke="#fff" stroke-width="2.6" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true">{symbol}</svg></span></div>
<h1>{heading}</h1><p>{text}</p><footer>You can close this tab.</footer>
</main></body></html>"##
    )
}

#[derive(Clone, Copy)]
enum Mark {
    Done,
    Stopped,
    Info,
}

fn done_page() -> String {
    page(
        "You are signed in",
        "Inbox Classic is adding your account. Go back to Inbox Classic to read your mail.",
        Mark::Done,
    )
}

fn denied_page() -> String {
    page(
        "Signing in was cancelled",
        "Nothing was added. You can try again from Inbox Classic.",
        Mark::Stopped,
    )
}

fn needs_admin_page() -> String {
    page(
        "Your organization has to approve Inbox Classic",
        "An administrator of your organization approves it once for everyone. Inbox Classic shows the address where they do it.",
        Mark::Info,
    )
}

fn wrong_issuer_page() -> String {
    page(
        "Signing in was stopped",
        "The answer did not come from the sign-in app's provider, so Inbox Classic did not use it. Try again from Inbox Classic.",
        Mark::Stopped,
    )
}

fn other_page() -> String {
    page(
        "This page is not part of signing in",
        "Inbox Classic is waiting for another sign-in. Start again from Inbox Classic if this was yours.",
        Mark::Info,
    )
}

async fn answer(mut socket: TcpStream, page: &str) {
    let response = format!(
        "HTTP/1.1 200 OK\r\nContent-Type: text/html; charset=utf-8\r\nContent-Length: {}\r\nConnection: close\r\nCache-Control: no-store\r\nContent-Security-Policy: default-src 'none'; style-src 'unsafe-inline'; base-uri 'none'; form-action 'none'; frame-ancestors 'none'\r\nX-Content-Type-Options: nosniff\r\nReferrer-Policy: no-referrer\r\n\r\n{page}",
        page.len()
    );
    let _ = socket.write_all(response.as_bytes()).await;
    let _ = socket.shutdown().await;
}

/// Waits for the redirect of this sign-in; other requests are answered and ignored
pub(crate) async fn receive(
    listener: &TcpListener,
    listener_v6: Option<&TcpListener>,
    expected: Expected<'_>,
) -> Result<String, OAuthError> {
    loop {
        let accepted = match listener_v6 {
            Some(v6) => tokio::select! {
                accepted = listener.accept() => accepted,
                accepted = v6.accept() => accepted,
            },
            None => listener.accept().await,
        };
        let (mut socket, _) = accepted.map_err(OAuthError::Io)?;
        let mut request = Vec::new();
        let mut chunk = [0u8; 4096];
        // up to the end of the request line is enough
        while !request.contains(&b'\n') && request.len() < MAX_REQUEST {
            match socket.read(&mut chunk).await {
                Ok(0) | Err(_) => break,
                Ok(read) => request.extend_from_slice(&chunk[..read]),
            }
        }
        match parse_redirect(&request, expected) {
            Redirect::Code(code) => {
                answer(socket, &done_page()).await;
                return Ok(code);
            }
            Redirect::Denied(reason) => {
                answer(socket, &denied_page()).await;
                return Err(OAuthError::Denied(reason));
            }
            Redirect::NeedsAdmin => {
                answer(socket, &needs_admin_page()).await;
                return Err(OAuthError::NeedsAdmin(crate::admin_consent_url(expected.client_id)));
            }
            Redirect::WrongIssuer => {
                answer(socket, &wrong_issuer_page()).await;
                return Err(OAuthError::BadRedirect);
            }
            Redirect::Other => answer(socket, &other_page()).await,
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn redirects() {
        let state = Expected {
            state: "s1",
            issuer: None,
            client_id: "client",
        };
        assert_eq!(
            parse_redirect(b"GET /?code=4%2F0Ab&state=s1&scope=x HTTP/1.1\r\nHost: x\r\n", state),
            Redirect::Code("4/0Ab".into())
        );
        assert_eq!(
            parse_redirect(b"GET /?error=access_denied&state=s1 HTTP/1.1\r\n", state),
            Redirect::Denied("access_denied".into())
        );
        // Microsoft's "Need admin approval", left with "Return to the application"
        assert_eq!(
            parse_redirect(
                b"GET /?error=access_denied&error_description=AADSTS90094%3a+The+grant+requires+admin+permission.&state=s1 HTTP/1.1\r\n",
                state
            ),
            Redirect::NeedsAdmin
        );
        assert_eq!(
            parse_redirect(
                b"GET /?error=access_denied&error_description=AADSTS65004&state=s1 HTTP/1.1\r\n",
                state
            ),
            Redirect::Denied("access_denied".into())
        );
        // another sign-in's, or none at all
        assert_eq!(
            parse_redirect(b"GET /?code=x&state=s2 HTTP/1.1\r\n", state),
            Redirect::Other
        );
        assert_eq!(parse_redirect(b"GET /?code=x HTTP/1.1\r\n", state), Redirect::Other);
        assert_eq!(parse_redirect(b"GET /favicon.ico HTTP/1.1\r\n", state), Redirect::Other);
        assert_eq!(
            parse_redirect(b"POST /?code=x&state=s1 HTTP/1.1\r\n", state),
            Redirect::Other
        );
        assert_eq!(parse_redirect(b"\xff\xfe garbage", state), Redirect::Other);
    }

    #[test]
    fn issuers_in_redirects() {
        let expected = Expected {
            state: "s1",
            issuer: Some("http://127.0.0.1:8085"),
            client_id: "client",
        };
        assert_eq!(
            parse_redirect(
                b"GET /?code=c&state=s1&iss=http%3A%2F%2F127.0.0.1%3A8085 HTTP/1.1\r\n",
                expected
            ),
            Redirect::Code("c".into())
        );
        // another provider's answer, or none named, from a provider that names itself
        for request in [
            &b"GET /?code=c&state=s1&iss=https%3A%2F%2Fwrong-issuer.invalid HTTP/1.1\r\n"[..],
            b"GET /?code=c&state=s1 HTTP/1.1\r\n",
            b"GET /?error=access_denied&state=s1&iss=https%3A%2F%2Fx HTTP/1.1\r\n",
        ] {
            assert_eq!(parse_redirect(request, expected), Redirect::WrongIssuer);
        }
        // not this sign-in's at all
        assert_eq!(
            parse_redirect(b"GET /?code=c&state=s2&iss=https%3A%2F%2Fx HTTP/1.1\r\n", expected),
            Redirect::Other
        );
    }

    #[test]
    fn pages_are_static() {
        for page in [
            done_page(),
            denied_page(),
            needs_admin_page(),
            wrong_issuer_page(),
            other_page(),
        ] {
            assert!(page.starts_with("<!doctype html>") && page.contains("You can close this tab."));
            assert!(!page.contains("<script") && !page.contains("http"), "{page}");
        }
        assert!(done_page().contains("<h1>You are signed in</h1>"));
    }
}
