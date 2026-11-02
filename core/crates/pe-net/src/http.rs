//! A minimal HTTP client for configuration files and OAuth token endpoints: HTTPS with the platform's
//! certificates (plain HTTP only to the loopback address, for test servers), HTTP/1.0 so there is no chunked
//! encoding, no redirects, a size limit and a time limit. Responses are parsed here, in Rust.

use std::time::Duration;

use crate::{Security, Stream, Trust};

/// A configuration file or a token response is a few kilobytes
const MAX_RESPONSE: usize = 1024 * 1024;

/// A URL this client goes to
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct Url {
    pub https: bool,
    pub host: String,
    pub port: u16,
    /// With the query
    pub path: String,
}

/// `https://host[:port]/path?query`, or `http://` to 127.0.0.1 or localhost; None for anything else
pub fn parse_url(url: &str) -> Option<Url> {
    let (https, rest) = match url.split_once("://")? {
        (scheme, rest) if scheme.eq_ignore_ascii_case("https") => (true, rest),
        (scheme, rest) if scheme.eq_ignore_ascii_case("http") => (false, rest),
        _ => return None,
    };
    let (authority, path) = match rest.find(['/', '?']) {
        Some(at) => (&rest[..at], &rest[at..]),
        None => (rest, "/"),
    };
    let path = if path.starts_with('?') {
        format!("/{path}")
    } else {
        path.to_string()
    };
    let (host, port) = match authority.rsplit_once(':') {
        Some((host, port)) => (host, port.parse().ok()?),
        None => (authority, if https { 443 } else { 80 }),
    };
    let host = host.to_ascii_lowercase();
    let valid_host = !host.is_empty()
        && host
            .bytes()
            .all(|b| b.is_ascii_alphanumeric() || b == b'-' || b == b'.');
    let valid_path = path.bytes().all(|b| b.is_ascii_graphic());
    let loopback = host == "127.0.0.1" || host == "localhost";
    (valid_host && valid_path && port > 0 && (https || loopback)).then_some(Url {
        https,
        host,
        port,
        path,
    })
}

/// The value of a form or query string: `+` is a space, `%XX` a byte; a `%` that starts no escape stays
pub fn form_decode(text: &str) -> String {
    let bytes = text.as_bytes();
    let mut out = Vec::with_capacity(bytes.len());
    let mut i = 0;
    while i < bytes.len() {
        let hex = |at: usize| bytes.get(at).and_then(|b| (*b as char).to_digit(16));
        match (bytes[i], hex(i + 1), hex(i + 2)) {
            (b'+', _, _) => out.push(b' '),
            (b'%', Some(high), Some(low)) => {
                out.push((high * 16 + low) as u8);
                i += 2;
            }
            (byte, _, _) => out.push(byte),
        }
        i += 1;
    }
    String::from_utf8_lossy(&out).into_owned()
}

/// The value of `key` in a query or form string, decoded
pub fn query_param(query: &str, key: &str) -> Option<String> {
    query.split('&').find_map(|pair| {
        let (k, v) = pair.split_once('=').unwrap_or((pair, ""));
        (k == key).then(|| form_decode(v))
    })
}

/// `application/x-www-form-urlencoded`
pub fn form_encode(pairs: &[(&str, &str)]) -> String {
    let encode = |text: &str| -> String {
        text.bytes()
            .map(|b| match b {
                b'A'..=b'Z' | b'a'..=b'z' | b'0'..=b'9' | b'-' | b'_' | b'.' | b'~' => (b as char).to_string(),
                _ => format!("%{b:02X}"),
            })
            .collect()
    };
    let parts: Vec<String> = pairs
        .iter()
        .map(|(k, v)| format!("{}={}", encode(k), encode(v)))
        .collect();
    parts.join("&")
}

#[derive(Debug, Clone, PartialEq, Eq)]
pub struct Response {
    pub status: u16,
    pub body: Vec<u8>,
}

#[derive(Debug)]
pub enum HttpError {
    Net(crate::Error),
    /// A URL this client does not go to: not HTTPS, or not a host name
    BadUrl,
    /// Not an HTTP response
    Malformed,
    TooLarge,
}

impl std::fmt::Display for HttpError {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        match self {
            HttpError::Net(error) => write!(f, "{error}"),
            HttpError::BadUrl => f.write_str("not an HTTPS address"),
            HttpError::Malformed => f.write_str("not an HTTP response"),
            HttpError::TooLarge => f.write_str("the response is too large"),
        }
    }
}

impl std::error::Error for HttpError {}

/// The status and the body of a response read to its end
pub fn parse_response(raw: &[u8]) -> Result<Response, HttpError> {
    let head_end = raw
        .windows(4)
        .position(|w| w == b"\r\n\r\n")
        .ok_or(HttpError::Malformed)?;
    let head = std::str::from_utf8(&raw[..head_end]).map_err(|_| HttpError::Malformed)?;
    let status_line = head.lines().next().ok_or(HttpError::Malformed)?;
    let mut parts = status_line.split(' ');
    let version = parts.next().unwrap_or_default();
    if !version.starts_with("HTTP/1.") {
        return Err(HttpError::Malformed);
    }
    let status: u16 = parts
        .next()
        .and_then(|s| s.parse().ok())
        .filter(|s| (100..600).contains(s))
        .ok_or(HttpError::Malformed)?;
    let mut body = raw[head_end + 4..].to_vec();
    let length = head
        .lines()
        .skip(1)
        .filter_map(|line| line.split_once(':'))
        .find(|(name, _)| name.trim().eq_ignore_ascii_case("content-length"));
    if let Some((_, value)) = length {
        // a length that is no number is no HTTP
        let length: usize = value.trim().parse().map_err(|_| HttpError::Malformed)?;
        if body.len() < length {
            return Err(HttpError::Malformed);
        }
        body.truncate(length);
    }
    Ok(Response { status, body })
}

/// GET a URL
pub async fn get(url: &str, timeout: Duration) -> Result<Response, HttpError> {
    request(url, None, timeout).await
}

/// POST a form to a URL
pub async fn post_form(url: &str, form: &[(&str, &str)], timeout: Duration) -> Result<Response, HttpError> {
    request(url, Some(form_encode(form)), timeout).await
}

/// The request line, the headers and the body of a request
fn request_bytes(url: &Url, form: Option<&str>) -> String {
    let method = if form.is_some() { "POST" } else { "GET" };
    let mut request = format!(
        "{method} {} HTTP/1.0\r\nHost: {}\r\nUser-Agent: PostalExpress\r\nAccept: */*\r\nConnection: close\r\n",
        url.path, url.host
    );
    if let Some(form) = form {
        request.push_str(&format!(
            "Content-Type: application/x-www-form-urlencoded\r\nContent-Length: {}\r\n\r\n{form}",
            form.len()
        ));
    } else {
        request.push_str("\r\n");
    }
    request
}

async fn request(url: &str, form: Option<String>, timeout: Duration) -> Result<Response, HttpError> {
    let url = parse_url(url).ok_or(HttpError::BadUrl)?;
    let work = async {
        let security = if url.https { Security::Tls } else { Security::Plain };
        let mut stream = Stream::connect(&url.host, url.port, security, &Trust::Platform, timeout)
            .await
            .map_err(HttpError::Net)?;
        stream
            .write_all(request_bytes(&url, form.as_deref()).as_bytes())
            .await
            .map_err(|e| HttpError::Net(crate::Error::Io(e)))?;
        let mut raw = Vec::new();
        let mut chunk = [0u8; 16 * 1024];
        loop {
            let read = stream
                .read(&mut chunk)
                .await
                .map_err(|e| HttpError::Net(crate::Error::Io(e)))?;
            if read == 0 {
                break;
            }
            raw.extend_from_slice(&chunk[..read]);
            if raw.len() > MAX_RESPONSE {
                return Err(HttpError::TooLarge);
            }
        }
        stream.shutdown().await;
        parse_response(&raw)
    };
    tokio::time::timeout(timeout, work)
        .await
        .map_err(|_| HttpError::Net(crate::Error::Timeout))?
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn urls() {
        let url = parse_url("https://Accounts.Google.com/o/oauth2/token?x=1").unwrap();
        assert_eq!(
            (url.https, url.host.as_str(), url.port, url.path.as_str()),
            (true, "accounts.google.com", 443, "/o/oauth2/token?x=1")
        );
        assert_eq!(parse_url("https://example.com").unwrap().path, "/");
        assert_eq!(parse_url("http://127.0.0.1:8080/token").unwrap().port, 8080);
        // no plain HTTP but to this machine, no other schemes, nothing that could split a request line
        assert_eq!(parse_url("http://example.com/token"), None);
        assert_eq!(parse_url("ftp://example.com/"), None);
        assert_eq!(parse_url("https://exa mple.com/"), None);
        assert_eq!(parse_url("https://example.com/a b"), None);
        assert_eq!(parse_url("https://example.com/\r\nHost: evil"), None);
        assert_eq!(parse_url("https://user@example.com/"), None);
    }

    #[test]
    fn requests() {
        let url = parse_url("https://example.com/token").unwrap();
        assert_eq!(
            request_bytes(&url, Some("a=1")),
            "POST /token HTTP/1.0\r\nHost: example.com\r\nUser-Agent: PostalExpress\r\nAccept: */*\r\nConnection: close\r\nContent-Type: application/x-www-form-urlencoded\r\nContent-Length: 3\r\n\r\na=1"
        );
        assert!(request_bytes(&url, None).starts_with("GET /token HTTP/1.0\r\n"));
    }

    #[test]
    fn forms() {
        let encoded = form_encode(&[("a b", "c&d=e"), ("x", "ü")]);
        assert_eq!(encoded, "a%20b=c%26d%3De&x=%C3%BC");
        assert_eq!(query_param(&encoded, "a%20b").as_deref(), Some("c&d=e"));
        assert_eq!(query_param(&encoded, "x").as_deref(), Some("ü"));
        assert_eq!(query_param("a=1", "b"), None);
        assert_eq!(form_decode("a%20b+c%zz%"), "a b c%zz%");
    }

    #[test]
    fn responses() {
        let ok = parse_response(b"HTTP/1.1 200 OK\r\nContent-Type: text/xml\r\nContent-Length: 5\r\n\r\n<x/>\nextra")
            .unwrap();
        assert_eq!((ok.status, ok.body.as_slice()), (200, &b"<x/>\n"[..]));
        let to_end = parse_response(b"HTTP/1.0 404 Not Found\r\n\r\nnope").unwrap();
        assert_eq!((to_end.status, to_end.body.as_slice()), (404, &b"nope"[..]));
        assert!(parse_response(b"SSH-2.0-OpenSSH\r\n\r\n").is_err());
        assert!(parse_response(b"HTTP/1.1 200 OK\r\nContent-Length: 50\r\n\r\nshort").is_err());
        assert!(parse_response(b"HTTP/1.1 999 What\r\n\r\n").is_err());
        assert!(parse_response(b"no head end").is_err());
        assert!(parse_response(b"HTTP/1.1 200 OK\r\nContent-Length: x\r\nContent-Length: 2\r\n\r\nab").is_err());
    }
}
