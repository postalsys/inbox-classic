//! A minimal HTTP client for configuration files and OAuth token endpoints: HTTPS with the platform's
//! certificates (plain HTTP only to the loopback address, for test servers, or where a [`Request`] asks for it),
//! HTTP/1.0 so there is no chunked encoding, no redirects (the caller reads `Location` itself), a size limit and a
//! time limit. Responses are parsed here, in Rust. A request carrying an `Authorization` header only goes over
//! HTTPS. A TLS connection closed without close_notify after a complete head ends the response, as browsers take
//! it; a Content-Length is then still checked.

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
    parse_url_with(url, false)
}

/// [`parse_url`], and with `plain_http` also `http://` to any host
pub fn parse_url_with(url: &str, plain_http: bool) -> Option<Url> {
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
    (valid_host && valid_path && port > 0 && (https || loopback || plain_http)).then_some(Url {
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

impl Url {
    /// `https://host[:port]`, the port left out when it is the scheme's default
    pub fn origin(&self) -> String {
        let scheme = if self.https { "https" } else { "http" };
        let default = if self.https { 443 } else { 80 };
        if self.port == default {
            format!("{scheme}://{}", self.host)
        } else {
            format!("{scheme}://{}:{}", self.host, self.port)
        }
    }
}

#[derive(Debug, Clone, PartialEq, Eq, Default)]
pub struct Response {
    pub status: u16,
    /// The header fields in the order they came, names as sent
    pub headers: Vec<(String, String)>,
    pub body: Vec<u8>,
}

impl Response {
    /// A response with a status and a body and no header fields, for tests
    pub fn new(status: u16, body: impl Into<Vec<u8>>) -> Response {
        Response {
            status,
            headers: Vec::new(),
            body: body.into(),
        }
    }

    /// The value of the first header field `name`, compared without case
    pub fn header(&self, name: &str) -> Option<&str> {
        self.headers
            .iter()
            .find(|(n, _)| n.eq_ignore_ascii_case(name))
            .map(|(_, v)| v.as_str())
    }

    /// The values of every header field `name`, compared without case
    pub fn header_values<'a>(&'a self, name: &'a str) -> impl Iterator<Item = &'a str> + 'a {
        self.headers
            .iter()
            .filter(move |(n, _)| n.eq_ignore_ascii_case(name))
            .map(|(_, v)| v.as_str())
    }
}

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum Method {
    Get,
    Post,
}

/// A request for [`send`]
#[derive(Debug, Clone)]
pub struct Request<'a> {
    pub method: Method,
    pub url: &'a str,
    /// Header fields besides `Host`, `User-Agent`, `Connection` and `Content-Length`; an `Accept` here replaces the
    /// default `*/*`
    pub headers: &'a [(&'a str, &'a str)],
    /// Sent with a POST
    pub body: &'a [u8],
    pub timeout: Duration,
    /// The largest response read; a longer one is [`HttpError::TooLarge`]
    pub max_response: usize,
    /// `http://` to any host. Never with an `Authorization` header: credentials only go over HTTPS.
    pub plain_http: bool,
}

impl<'a> Request<'a> {
    /// A GET of `url`, HTTPS only, with the default limit
    pub fn get(url: &'a str, timeout: Duration) -> Request<'a> {
        Request {
            method: Method::Get,
            url,
            headers: &[],
            body: &[],
            timeout,
            max_response: MAX_RESPONSE,
            plain_http: false,
        }
    }
}

#[derive(Debug)]
pub enum HttpError {
    Net(crate::Error),
    /// A URL this client does not go to: not HTTPS, or not a host name
    BadUrl,
    /// Not an HTTP response
    Malformed,
    TooLarge,
    /// A request this client does not send: a header field that is not one, or credentials over plain HTTP
    BadRequest,
}

impl std::fmt::Display for HttpError {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        match self {
            HttpError::Net(error) => write!(f, "{error}"),
            HttpError::BadUrl => f.write_str("not an HTTPS address"),
            HttpError::Malformed => f.write_str("not an HTTP response"),
            HttpError::TooLarge => f.write_str("the response is too large"),
            HttpError::BadRequest => f.write_str("not a request this client sends"),
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
    let headers: Vec<(String, String)> = head
        .lines()
        .skip(1)
        .filter_map(|line| line.split_once(':'))
        .map(|(name, value)| (name.trim().to_string(), value.trim().to_string()))
        .collect();
    let length = headers
        .iter()
        .find(|(name, _)| name.eq_ignore_ascii_case("content-length"));
    if let Some((_, value)) = length {
        // a length that is no number is no HTTP
        let length: usize = value.trim().parse().map_err(|_| HttpError::Malformed)?;
        if body.len() < length {
            return Err(HttpError::Malformed);
        }
        body.truncate(length);
    }
    Ok(Response { status, headers, body })
}

/// GET a URL
pub async fn get(url: &str, timeout: Duration) -> Result<Response, HttpError> {
    send(Request::get(url, timeout)).await
}

/// POST a form to a URL
pub async fn post_form(url: &str, form: &[(&str, &str)], timeout: Duration) -> Result<Response, HttpError> {
    let form = form_encode(form);
    send(Request {
        method: Method::Post,
        headers: &[("Content-Type", "application/x-www-form-urlencoded")],
        body: form.as_bytes(),
        ..Request::get(url, timeout)
    })
    .await
}

/// A header field name is a token, a value has no line breaks or other control characters
fn valid_header(name: &str, value: &str) -> bool {
    !name.is_empty()
        && name
            .bytes()
            .all(|b| b.is_ascii_alphanumeric() || b"!#$%&'*+-.^_`|~".contains(&b))
        && value.bytes().all(|b| b == b'\t' || (b >= 0x20 && b != 0x7f))
}

/// The request line, the headers and the body of a request
fn request_bytes(url: &Url, method: Method, headers: &[(&str, &str)], body: &[u8]) -> Vec<u8> {
    let method_name = match method {
        Method::Get => "GET",
        Method::Post => "POST",
    };
    let default_port = if url.https { 443 } else { 80 };
    let host = if url.port == default_port {
        url.host.clone()
    } else {
        format!("{}:{}", url.host, url.port)
    };
    let mut head = format!(
        "{method_name} {} HTTP/1.0\r\nHost: {host}\r\nUser-Agent: PostalExpress\r\n",
        url.path
    );
    if !headers.iter().any(|(name, _)| name.eq_ignore_ascii_case("accept")) {
        head.push_str("Accept: */*\r\n");
    }
    head.push_str("Connection: close\r\n");
    for (name, value) in headers {
        head.push_str(&format!("{name}: {value}\r\n"));
    }
    if method == Method::Post {
        head.push_str(&format!("Content-Length: {}\r\n", body.len()));
    }
    head.push_str("\r\n");
    let mut bytes = head.into_bytes();
    if method == Method::Post {
        bytes.extend_from_slice(body);
    }
    bytes
}

fn head_complete(raw: &[u8]) -> bool {
    raw.windows(4).any(|w| w == b"\r\n\r\n")
}

/// Sends a request and reads the response to its end
pub async fn send(request: Request<'_>) -> Result<Response, HttpError> {
    let url = parse_url_with(request.url, request.plain_http).ok_or(HttpError::BadUrl)?;
    if request.headers.iter().any(|(name, value)| !valid_header(name, value)) {
        return Err(HttpError::BadRequest);
    }
    let credentials = request
        .headers
        .iter()
        .any(|(name, _)| name.eq_ignore_ascii_case("authorization"));
    if credentials && !url.https {
        return Err(HttpError::BadRequest);
    }
    let bytes = request_bytes(&url, request.method, request.headers, request.body);
    let timeout = request.timeout;
    let max_response = request.max_response;
    let work = async {
        let security = if url.https { Security::Tls } else { Security::Plain };
        let mut stream = Stream::connect(&url.host, url.port, security, &Trust::Platform, timeout)
            .await
            .map_err(HttpError::Net)?;
        stream
            .write_all(&bytes)
            .await
            .map_err(|e| HttpError::Net(crate::Error::Io(e)))?;
        let mut raw = Vec::new();
        let mut chunk = [0u8; 16 * 1024];
        loop {
            let read = match stream.read(&mut chunk).await {
                Ok(read) => read,
                // Some servers (dns.google) close without a TLS close_notify. Once the head is complete that is
                // the end of the response: a body with a Content-Length is still checked against it, and one
                // without has to be a format that shows when it was cut short (JSON, XML read to its last tag).
                Err(e) if e.kind() == std::io::ErrorKind::UnexpectedEof && head_complete(&raw) => 0,
                Err(e) => return Err(HttpError::Net(crate::Error::Io(e))),
            };
            if read == 0 {
                break;
            }
            raw.extend_from_slice(&chunk[..read]);
            if raw.len() > max_response {
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
        let form = [("Content-Type", "application/x-www-form-urlencoded")];
        assert_eq!(
            request_bytes(&url, Method::Post, &form, b"a=1"),
            b"POST /token HTTP/1.0\r\nHost: example.com\r\nUser-Agent: PostalExpress\r\nAccept: */*\r\nConnection: close\r\nContent-Type: application/x-www-form-urlencoded\r\nContent-Length: 3\r\n\r\na=1"
        );
        assert_eq!(
            request_bytes(&url, Method::Get, &[], b"ignored"),
            b"GET /token HTTP/1.0\r\nHost: example.com\r\nUser-Agent: PostalExpress\r\nAccept: */*\r\nConnection: close\r\n\r\n"
        );
        // another Accept replaces the default, a port that is not the default is part of Host
        let other = parse_url("https://example.com:8443/q").unwrap();
        let doh = request_bytes(&other, Method::Get, &[("accept", "application/dns-json")], b"");
        assert_eq!(
            doh,
            b"GET /q HTTP/1.0\r\nHost: example.com:8443\r\nUser-Agent: PostalExpress\r\nConnection: close\r\naccept: application/dns-json\r\n\r\n"
        );
    }

    #[test]
    fn plain_http_only_when_asked() {
        assert_eq!(parse_url("http://example.com/x"), None);
        let url = parse_url_with("http://Example.com/x", true).unwrap();
        assert_eq!(
            (url.https, url.port, url.origin()),
            (false, 80, "http://example.com".to_string())
        );
        assert_eq!(
            parse_url("https://a.example.com:8443/x").unwrap().origin(),
            "https://a.example.com:8443"
        );
        assert_eq!(
            parse_url("https://a.example.com/x").unwrap().origin(),
            "https://a.example.com"
        );
    }

    /// A local server that answers one request with `head` and then `chunk` until the client goes away; what
    /// the client sent comes back through the handle
    async fn serve(head: &'static str, chunk: &'static [u8]) -> (String, tokio::task::JoinHandle<Vec<u8>>) {
        use tokio::io::{AsyncReadExt, AsyncWriteExt};
        let listener = tokio::net::TcpListener::bind("127.0.0.1:0").await.unwrap();
        let address = listener.local_addr().unwrap();
        let task = tokio::spawn(async move {
            let (mut socket, _) = listener.accept().await.unwrap();
            let mut request = vec![0u8; 4096];
            let read = socket.read(&mut request).await.unwrap();
            request.truncate(read);
            if socket.write_all(head.as_bytes()).await.is_ok() {
                for _ in 0..10_000 {
                    if chunk.is_empty() || socket.write_all(chunk).await.is_err() {
                        break;
                    }
                }
            }
            request
        });
        (format!("http://{address}"), task)
    }

    #[tokio::test]
    async fn a_response_without_end_stops_at_the_limit() {
        let (base, server) = serve("HTTP/1.0 200 OK\r\n\r\n", &[b'x'; 4096]).await;
        let url = format!("{base}/big");
        let request = Request {
            max_response: 64 * 1024,
            ..Request::get(&url, Duration::from_secs(5))
        };
        assert!(matches!(send(request).await, Err(HttpError::TooLarge)));
        drop(server);
    }

    #[tokio::test]
    async fn redirects_are_the_callers_to_follow() {
        let (base, server) = serve(
            "HTTP/1.1 302 Found\r\nLocation: https://elsewhere.example/x\r\nContent-Length: 0\r\n\r\n",
            b"",
        )
        .await;
        let url = format!("{base}/autodiscover/autodiscover.xml");
        let request = Request {
            method: Method::Post,
            headers: &[("Content-Type", "text/xml; charset=utf-8")],
            body: b"<x/>",
            ..Request::get(&url, Duration::from_secs(5))
        };
        let response = send(request).await.unwrap();
        assert_eq!(response.status, 302);
        assert_eq!(response.header("location"), Some("https://elsewhere.example/x"));
        let sent = String::from_utf8(server.await.unwrap()).unwrap();
        assert!(
            sent.starts_with("POST /autodiscover/autodiscover.xml HTTP/1.0\r\n"),
            "{sent}"
        );
        assert!(sent.contains("\r\nContent-Type: text/xml; charset=utf-8\r\nContent-Length: 4\r\n\r\n<x/>"));
    }

    #[test]
    fn header_fields_are_checked() {
        assert!(valid_header("Authorization", "Basic dXNlcjpwYXNz"));
        assert!(!valid_header("X-A", "a\r\nHost: evil"));
        assert!(!valid_header("X A", "b"));
        assert!(!valid_header("", "b"));
    }

    #[tokio::test]
    async fn no_credentials_over_plain_http() {
        // refused before anything is sent: there is nothing listening at this address
        let request = Request {
            headers: &[("Authorization", "Basic dXNlcjpwYXNz")],
            plain_http: true,
            ..Request::get("http://127.0.0.1:9/autodiscover", Duration::from_secs(1))
        };
        assert!(matches!(send(request).await, Err(HttpError::BadRequest)));
        let injected = Request {
            headers: &[("X-A", "a\r\nb")],
            ..Request::get("https://127.0.0.1:9/", Duration::from_secs(1))
        };
        assert!(matches!(send(injected).await, Err(HttpError::BadRequest)));
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
        assert_eq!(ok.header("content-type"), Some("text/xml"));
        let challenge = parse_response(
            b"HTTP/1.1 401 No\r\nWWW-Authenticate: Negotiate\r\nwww-authenticate: Basic realm=\"x\"\r\n\r\n",
        )
        .unwrap();
        assert_eq!(
            challenge.header_values("WWW-Authenticate").collect::<Vec<_>>(),
            ["Negotiate", "Basic realm=\"x\""]
        );
        assert_eq!(challenge.header("location"), None);
        let to_end = parse_response(b"HTTP/1.0 404 Not Found\r\n\r\nnope").unwrap();
        assert_eq!((to_end.status, to_end.body.as_slice()), (404, &b"nope"[..]));
        assert!(parse_response(b"SSH-2.0-OpenSSH\r\n\r\n").is_err());
        assert!(parse_response(b"HTTP/1.1 200 OK\r\nContent-Length: 50\r\n\r\nshort").is_err());
        assert!(parse_response(b"HTTP/1.1 999 What\r\n\r\n").is_err());
        assert!(parse_response(b"no head end").is_err());
        assert!(parse_response(b"HTTP/1.1 200 OK\r\nContent-Length: x\r\nContent-Length: 2\r\n\r\nab").is_err());
    }
}
