//! A minimal HTTPS GET for configuration files: HTTP/1.0 so there is no chunked encoding, the platform's
//! certificates, no redirects, a size limit and a time limit. The response is parsed here, in Rust.

use std::time::Duration;

use pe_net::{Security, Stream, Trust};

/// A configuration file is a few kilobytes
const MAX_RESPONSE: usize = 1024 * 1024;

#[derive(Debug, Clone, PartialEq, Eq)]
pub struct Response {
    pub status: u16,
    pub body: Vec<u8>,
}

#[derive(Debug)]
pub enum HttpError {
    Net(pe_net::Error),
    /// Not an HTTP response
    Malformed,
    TooLarge,
}

impl std::fmt::Display for HttpError {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        match self {
            HttpError::Net(error) => write!(f, "{error}"),
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

/// GET `https://host/path`
pub async fn get(host: &str, path: &str, timeout: Duration) -> Result<Response, HttpError> {
    let work = async {
        let mut stream = Stream::connect(host, 443, Security::Tls, &Trust::Platform, timeout)
            .await
            .map_err(HttpError::Net)?;
        let request = format!(
            "GET {path} HTTP/1.0\r\nHost: {host}\r\nUser-Agent: PostalExpress\r\nAccept: application/xml, text/xml\r\nConnection: close\r\n\r\n"
        );
        stream
            .write_all(request.as_bytes())
            .await
            .map_err(|e| HttpError::Net(pe_net::Error::Io(e)))?;
        let mut raw = Vec::new();
        let mut chunk = [0u8; 16 * 1024];
        loop {
            let read = stream
                .read(&mut chunk)
                .await
                .map_err(|e| HttpError::Net(pe_net::Error::Io(e)))?;
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
        .map_err(|_| HttpError::Net(pe_net::Error::Timeout))?
}

#[cfg(test)]
mod tests {
    use super::*;

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
