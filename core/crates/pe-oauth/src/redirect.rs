//! The browser coming back to 127.0.0.1 with the code: one request, read and answered here. Only a request with
//! this sign-in's state is taken; anything else gets a page saying so and the listener keeps waiting.

use tokio::io::{AsyncReadExt, AsyncWriteExt};
use tokio::net::{TcpListener, TcpStream};

use crate::OAuthError;

/// The most of a request read: a redirect is one line
const MAX_REQUEST: usize = 16 * 1024;

/// What a redirect says
#[derive(Debug, PartialEq, Eq)]
pub(crate) enum Redirect {
    Code(String),
    Denied(String),
    /// Not this sign-in's, or not a redirect at all (a favicon request)
    Other,
}

/// The parameters of the request line `GET /?code=...&state=... HTTP/1.1`
pub(crate) fn parse_redirect(request: &[u8], state: &str) -> Redirect {
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
    let mut matched = false;
    for pair in query.split('&') {
        let (key, value) = pair.split_once('=').unwrap_or((pair, ""));
        let value = pe_net::http::form_decode(value);
        match key {
            "code" => code = Some(value),
            "error" => error = Some(value),
            "state" => matched = constant_time_eq(value.as_bytes(), state.as_bytes()),
            _ => {}
        }
    }
    match (matched, code, error) {
        (true, Some(code), None) if !code.is_empty() => Redirect::Code(code),
        (true, _, Some(error)) => Redirect::Denied(error),
        _ => Redirect::Other,
    }
}

fn constant_time_eq(a: &[u8], b: &[u8]) -> bool {
    a.len() == b.len() && a.iter().zip(b).fold(0u8, |acc, (x, y)| acc | (x ^ y)) == 0
}

const DONE: &str = "<!doctype html><title>Inbox Classic</title><p>You are signed in. You can close this page and go back to Inbox Classic.</p>";
const DENIED: &str =
    "<!doctype html><title>Inbox Classic</title><p>Signing in was cancelled. You can close this page.</p>";
const OTHER: &str =
    "<!doctype html><title>Inbox Classic</title><p>This page is not part of signing in to Inbox Classic.</p>";

async fn answer(mut socket: TcpStream, page: &str) {
    let response = format!(
        "HTTP/1.1 200 OK\r\nContent-Type: text/html; charset=utf-8\r\nContent-Length: {}\r\nConnection: close\r\nCache-Control: no-store\r\n\r\n{page}",
        page.len()
    );
    let _ = socket.write_all(response.as_bytes()).await;
    let _ = socket.shutdown().await;
}

/// Waits for the redirect of this sign-in; other requests are answered and ignored
pub(crate) async fn receive(listener: &TcpListener, state: &str) -> Result<String, OAuthError> {
    loop {
        let (mut socket, _) = listener.accept().await.map_err(OAuthError::Io)?;
        let mut request = Vec::new();
        let mut chunk = [0u8; 4096];
        // up to the end of the request line is enough
        while !request.contains(&b'\n') && request.len() < MAX_REQUEST {
            match socket.read(&mut chunk).await {
                Ok(0) | Err(_) => break,
                Ok(read) => request.extend_from_slice(&chunk[..read]),
            }
        }
        match parse_redirect(&request, state) {
            Redirect::Code(code) => {
                answer(socket, DONE).await;
                return Ok(code);
            }
            Redirect::Denied(reason) => {
                answer(socket, DENIED).await;
                return Err(OAuthError::Denied(reason));
            }
            Redirect::Other => answer(socket, OTHER).await,
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn redirects() {
        let state = "s1";
        assert_eq!(
            parse_redirect(b"GET /?code=4%2F0Ab&state=s1&scope=x HTTP/1.1\r\nHost: x\r\n", state),
            Redirect::Code("4/0Ab".into())
        );
        assert_eq!(
            parse_redirect(b"GET /?error=access_denied&state=s1 HTTP/1.1\r\n", state),
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
}
