//! An SMTP client session, the parts of nodemailer's smtp-connection a mail client uses: implicit TLS or required
//! STARTTLS (with a check for plaintext injected before the handshake) or plain, EHLO with a HELO fallback, AUTH
//! PLAIN, LOGIN and XOAUTH2, SIZE, SMTPUTF8 and 8BITMIME, recipients accepted one by one, and dot-stuffed DATA.

use std::collections::HashSet;
use std::fmt;
use std::time::Duration;

use base64::Engine;
use base64::engine::general_purpose::STANDARD;
use pe_net::{Security, Stream, Trust};

use crate::message::Envelope;

/// The longest response line read, and the most lines one response may have
const MAX_LINE: usize = 64 * 1024;
const MAX_LINES: usize = 1000;

pub use pe_net::{Credentials, Direction, WireLog};

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub struct Timeouts {
    pub connect: Duration,
    pub greeting: Duration,
    /// For each response but the one after the message data
    pub command: Duration,
    /// For the response after the message data, when the server may be scanning it
    pub data: Duration,
}

impl Default for Timeouts {
    fn default() -> Self {
        Timeouts {
            connect: Duration::from_secs(30),
            greeting: Duration::from_secs(30),
            command: Duration::from_secs(60),
            data: Duration::from_secs(600),
        }
    }
}

#[derive(Clone)]
pub struct Config {
    pub host: String,
    pub port: u16,
    pub security: Security,
    pub trust: Trust,
    pub credentials: Option<Credentials>,
    /// The name sent with EHLO
    pub name: String,
    pub timeouts: Timeouts,
    pub wire_log: Option<WireLog>,
}

impl Config {
    pub fn new(host: impl Into<String>, port: u16, security: Security, credentials: Option<Credentials>) -> Self {
        Config {
            host: host.into(),
            port,
            security,
            trust: Trust::Platform,
            credentials,
            // what nodemailer sends without a fully qualified host name
            name: "[127.0.0.1]".into(),
            timeouts: Timeouts::default(),
            wire_log: None,
        }
    }
}

/// A response of the server: its code, the enhanced status code when there is one, and the text of its lines
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct Response {
    pub code: u16,
    pub enhanced: Option<String>,
    pub lines: Vec<String>,
}

impl Response {
    pub fn text(&self) -> String {
        self.lines.join(" ")
    }

    fn is_positive(&self) -> bool {
        (200..400).contains(&self.code)
    }
}

impl fmt::Display for Response {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        write!(f, "{} {}", self.code, self.text())
    }
}

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum ErrorKind {
    /// Not reachable or stopped answering: try again later
    Network,
    /// TLS failed or could not be had
    Security,
    /// The credentials were refused, or no method fits them
    Authentication,
    /// The server refused the message or its recipients; a 4xx code is temporary
    Refused,
    /// The server does not speak SMTP
    Protocol,
}

#[derive(Debug)]
pub enum Error {
    Net(pe_net::Error),
    /// A command the server refused
    Refused {
        command: String,
        response: Response,
    },
    /// No recipient was accepted
    NoRecipients {
        rejected: Vec<(String, Response)>,
    },
    AuthenticationFailed(Response),
    /// The server offers no authentication method the credentials can use
    AuthenticationUnavailable,
    StartTlsUnavailable,
    /// The server sent data after its answer to STARTTLS and before the handshake
    StartTlsInjection,
    /// The message is larger than the server takes
    TooLarge {
        size: usize,
        limit: u64,
    },
    /// An address that can not be put in an SMTP command
    InvalidAddress(String),
    Unexpected(String),
}

impl Error {
    pub fn kind(&self) -> ErrorKind {
        match self {
            Error::Net(pe_net::Error::Tls(_)) | Error::StartTlsUnavailable | Error::StartTlsInjection => {
                ErrorKind::Security
            }
            Error::Net(_) => ErrorKind::Network,
            // 538 (RFC 4954): the password is taken only over an encrypted connection, typing it again does not help
            Error::AuthenticationFailed(response) if response.code == 538 => ErrorKind::Security,
            Error::AuthenticationFailed(_) | Error::AuthenticationUnavailable => ErrorKind::Authentication,
            // 530 (RFC 4954): the server wants a login first, it may only offer AUTH after STARTTLS
            Error::Refused { response, .. } if response.code == 530 => ErrorKind::Authentication,
            Error::Refused { .. } | Error::NoRecipients { .. } | Error::TooLarge { .. } | Error::InvalidAddress(_) => {
                ErrorKind::Refused
            }
            Error::Unexpected(_) => ErrorKind::Protocol,
        }
    }

    /// Whether trying again later can work: the network, or a 4xx answer
    pub fn is_temporary(&self) -> bool {
        match self {
            Error::Net(pe_net::Error::Tls(_)) => false,
            Error::Net(_) => true,
            Error::Refused { response, .. } => (400..500).contains(&response.code),
            Error::NoRecipients { rejected } => rejected.iter().all(|(_, r)| (400..500).contains(&r.code)),
            _ => false,
        }
    }
}

impl fmt::Display for Error {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        match self {
            Error::Net(error) => write!(f, "{error}"),
            Error::Refused { command, response } => write!(f, "the server refused {command}: {response}"),
            Error::NoRecipients { rejected } => {
                let list: Vec<String> = rejected.iter().map(|(a, r)| format!("{a} ({r})")).collect();
                write!(f, "the server accepted none of the recipients: {}", list.join(", "))
            }
            Error::AuthenticationFailed(response) if response.code == 538 => {
                write!(
                    f,
                    "the server takes the password only over an encrypted connection: {response}"
                )
            }
            Error::AuthenticationFailed(response) => write!(f, "authentication failed: {response}"),
            Error::AuthenticationUnavailable => {
                f.write_str("the server offers no authentication method for these credentials")
            }
            Error::StartTlsUnavailable => f.write_str("the server does not offer STARTTLS"),
            Error::StartTlsInjection => f.write_str("the server sent data before the TLS handshake"),
            Error::TooLarge { size, limit } => write!(f, "the message is {size} bytes, the server takes {limit}"),
            Error::InvalidAddress(address) => write!(f, "{address:?} can not be sent to"),
            Error::Unexpected(text) => write!(f, "unexpected answer from the server: {text}"),
        }
    }
}

impl std::error::Error for Error {}

impl From<pe_net::Error> for Error {
    fn from(error: pe_net::Error) -> Self {
        Error::Net(error)
    }
}

/// What the server did with a message
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct SendReport {
    pub accepted: Vec<String>,
    pub rejected: Vec<(String, Response)>,
    /// The answer to the message data, usually with the queue ID
    pub response: Response,
}

pub struct Client {
    config: Config,
    stream: Stream,
    /// Read but not yet taken
    buffer: Vec<u8>,
    extensions: HashSet<String>,
    auth_methods: HashSet<String>,
    max_size: Option<u64>,
}

/// Lines starting with a dot get another one, every line ends with CRLF, and the data ends with `.`
pub fn dot_stuff(raw: &[u8]) -> Vec<u8> {
    let mut out = Vec::with_capacity(raw.len() + raw.len() / 50 + 5);
    let mut line_start = true;
    let mut i = 0;
    while i < raw.len() {
        let byte = raw[i];
        if line_start && byte == b'.' {
            out.push(b'.');
        }
        match byte {
            b'\r' => {
                out.extend_from_slice(b"\r\n");
                if raw.get(i + 1) == Some(&b'\n') {
                    i += 1;
                }
                line_start = true;
            }
            b'\n' => {
                out.extend_from_slice(b"\r\n");
                line_start = true;
            }
            _ => {
                out.push(byte);
                line_start = false;
            }
        }
        i += 1;
    }
    if !line_start {
        out.extend_from_slice(b"\r\n");
    }
    out.extend_from_slice(b".\r\n");
    out
}

/// An address for MAIL FROM or RCPT TO: no control characters, angle brackets or line breaks
fn check_address(address: &str) -> Result<(), Error> {
    if address.chars().any(|c| c.is_control() || c == '<' || c == '>') {
        return Err(Error::InvalidAddress(address.to_string()));
    }
    Ok(())
}

impl Client {
    /// Connects, says EHLO, starts TLS when asked to, and authenticates when there are credentials and the server
    /// offers AUTH
    pub async fn connect(config: Config) -> Result<Client, Error> {
        let stream = Stream::connect(
            &config.host,
            config.port,
            config.security,
            &config.trust,
            config.timeouts.connect,
        )
        .await?;
        let mut client = Client {
            config,
            stream,
            buffer: Vec::new(),
            extensions: HashSet::new(),
            auth_methods: HashSet::new(),
            max_size: None,
        };
        let greeting = client.read_response(client.config.timeouts.greeting).await?;
        if greeting.code != 220 {
            return Err(Error::Refused {
                command: "the connection".into(),
                response: greeting,
            });
        }
        client.ehlo().await?;
        if client.config.security == Security::StartTls {
            client.start_tls().await?;
        }
        // a server that offers no AUTH at all takes mail without it (a relay on the same network), as
        // nodemailer does; one that offers methods but none that fits is an error
        if let Some(credentials) = client.config.credentials.clone()
            && !client.auth_methods.is_empty()
        {
            client.authenticate(&credentials).await?;
        }
        Ok(client)
    }

    pub fn has_extension(&self, name: &str) -> bool {
        self.extensions.contains(&name.to_ascii_uppercase())
    }

    pub fn is_secure(&self) -> bool {
        self.stream.is_tls()
    }

    fn log(&self, direction: Direction, line: &str) {
        if let Some(log) = &self.config.wire_log {
            log(direction, line);
        }
    }

    async fn write(&mut self, data: &[u8]) -> Result<(), Error> {
        self.stream
            .write_all(data)
            .await
            .map_err(|e| Error::Net(pe_net::Error::Io(e)))
    }

    /// Sends a command line; `logged` is what the log shows of it
    async fn send_line(&mut self, line: &str, logged: Option<&str>) -> Result<(), Error> {
        self.log(Direction::Client, logged.unwrap_or(line));
        self.write(format!("{line}\r\n").as_bytes()).await
    }

    async fn command(&mut self, line: &str) -> Result<Response, Error> {
        self.send_line(line, None).await?;
        self.read_response(self.config.timeouts.command).await
    }

    /// A command that has to succeed
    async fn expect(&mut self, line: &str) -> Result<Response, Error> {
        let response = self.command(line).await?;
        if !response.is_positive() {
            let command = line.split(' ').next().unwrap_or(line).to_string();
            return Err(Error::Refused { command, response });
        }
        Ok(response)
    }

    async fn read_line(&mut self, timeout: Duration) -> Result<String, Error> {
        loop {
            if let Some(at) = self.buffer.iter().position(|b| *b == b'\n') {
                let mut line: Vec<u8> = self.buffer.drain(..=at).collect();
                line.pop();
                if line.last() == Some(&b'\r') {
                    line.pop();
                }
                let line = String::from_utf8_lossy(&line).into_owned();
                self.log(Direction::Server, &line);
                return Ok(line);
            }
            if self.buffer.len() > MAX_LINE {
                return Err(Error::Unexpected("a response line too long".into()));
            }
            let mut chunk = [0u8; 8192];
            let read = tokio::time::timeout(timeout, self.stream.read(&mut chunk))
                .await
                .map_err(|_| Error::Net(pe_net::Error::Timeout))?
                .map_err(|e| Error::Net(pe_net::Error::Io(e)))?;
            if read == 0 {
                return Err(Error::Net(pe_net::Error::Io(std::io::Error::new(
                    std::io::ErrorKind::UnexpectedEof,
                    "the server closed the connection",
                ))));
            }
            self.buffer.extend_from_slice(&chunk[..read]);
        }
    }

    /// One response: `250-...` lines up to the `250 ...` one
    async fn read_response(&mut self, timeout: Duration) -> Result<Response, Error> {
        let mut lines = Vec::new();
        loop {
            let line = self.read_line(timeout).await?;
            let bytes = line.as_bytes();
            let code = line
                .get(..3)
                .filter(|c| c.bytes().all(|b| b.is_ascii_digit()))
                .and_then(|c| c.parse::<u16>().ok())
                .filter(|c| (200..600).contains(c))
                .ok_or_else(|| Error::Unexpected(line.clone()))?;
            let last = bytes.get(3) != Some(&b'-');
            let text = line.get(4..).unwrap_or_default().to_string();
            lines.push((code, text));
            if lines.len() > MAX_LINES {
                return Err(Error::Unexpected("a response of too many lines".into()));
            }
            if last {
                break;
            }
        }
        let code = lines.last().map_or(0, |(code, _)| *code);
        let mut texts: Vec<String> = lines.into_iter().map(|(_, text)| text).collect();
        // `2.1.0 Ok`: the enhanced status code (RFC 3463) of the last line
        let enhanced = texts.last().and_then(|text| {
            let first = text.split(' ').next()?;
            let parts: Vec<&str> = first.split('.').collect();
            (parts.len() == 3
                && parts
                    .iter()
                    .all(|p| !p.is_empty() && p.bytes().all(|b| b.is_ascii_digit())))
            .then(|| first.to_string())
        });
        if let (Some(enhanced), Some(last)) = (&enhanced, texts.last_mut()) {
            *last = last[enhanced.len()..].trim_start().to_string();
        }
        Ok(Response {
            code,
            enhanced,
            lines: texts,
        })
    }

    async fn ehlo(&mut self) -> Result<(), Error> {
        let name = self.config.name.clone();
        self.extensions.clear();
        self.auth_methods.clear();
        self.max_size = None;
        let response = self.command(&format!("EHLO {name}")).await?;
        if response.code != 250 {
            // an old server: HELO, no extensions
            self.expect(&format!("HELO {name}")).await?;
            return Ok(());
        }
        for line in response.lines.iter().skip(1) {
            let mut words = line.split_whitespace();
            let Some(keyword) = words.next().map(str::to_ascii_uppercase) else {
                continue;
            };
            match keyword.as_str() {
                "AUTH" => self.auth_methods.extend(words.map(str::to_ascii_uppercase)),
                "SIZE" => self.max_size = words.next().and_then(|s| s.parse().ok()).filter(|s| *s > 0),
                _ => {}
            }
            self.extensions.insert(keyword);
        }
        Ok(())
    }

    async fn start_tls(&mut self) -> Result<(), Error> {
        if !self.has_extension("STARTTLS") {
            return Err(Error::StartTlsUnavailable);
        }
        let response = self.command("STARTTLS").await?;
        if response.code != 220 {
            return Err(Error::Refused {
                command: "STARTTLS".into(),
                response,
            });
        }
        // what came after the answer and before the handshake came in plaintext and would pass for
        // something said over TLS (CVE-2011-0411 class)
        if !self.buffer.is_empty() {
            return Err(Error::StartTlsInjection);
        }
        self.stream.upgrade(&self.config.host, &self.config.trust).await?;
        // what the server said it can do before the handshake could have been changed on the way
        self.ehlo().await
    }

    async fn authenticate(&mut self, credentials: &Credentials) -> Result<(), Error> {
        let response = match credentials {
            Credentials::OAuth2 { user, access_token } => {
                if !self.auth_methods.contains("XOAUTH2") {
                    return Err(Error::AuthenticationUnavailable);
                }
                let token = STANDARD.encode(format!("user={user}\x01auth=Bearer {access_token}\x01\x01"));
                self.send_line(
                    &format!("AUTH XOAUTH2 {token}"),
                    Some("AUTH XOAUTH2 (credentials hidden)"),
                )
                .await?;
                let mut response = self.read_response(self.config.timeouts.command).await?;
                if response.code == 334 {
                    // the error details as a challenge: an empty line ends the exchange
                    self.send_line("", None).await?;
                    response = self.read_response(self.config.timeouts.command).await?;
                }
                response
            }
            Credentials::Password { user, password } => {
                if self.auth_methods.contains("PLAIN") {
                    let token = STANDARD.encode(format!("\0{user}\0{password}"));
                    self.send_line(&format!("AUTH PLAIN {token}"), Some("AUTH PLAIN (credentials hidden)"))
                        .await?;
                    self.read_response(self.config.timeouts.command).await?
                } else if self.auth_methods.contains("LOGIN") {
                    self.login(user, password).await?
                } else {
                    return Err(Error::AuthenticationUnavailable);
                }
            }
        };
        if response.code != 235 {
            return Err(Error::AuthenticationFailed(response));
        }
        Ok(())
    }

    async fn login(&mut self, user: &str, password: &str) -> Result<Response, Error> {
        let response = self.command("AUTH LOGIN").await?;
        if response.code != 334 {
            return Ok(response);
        }
        self.send_line(&STANDARD.encode(user), Some("(credentials hidden)"))
            .await?;
        let response = self.read_response(self.config.timeouts.command).await?;
        if response.code != 334 {
            return Ok(response);
        }
        self.send_line(&STANDARD.encode(password), Some("(credentials hidden)"))
            .await?;
        self.read_response(self.config.timeouts.command).await
    }

    /// `MAIL FROM` with the parameters the server takes: SIZE, SMTPUTF8 for non-ASCII addresses, BODY=8BITMIME
    /// for non-ASCII content
    fn mail_from(&self, envelope: &Envelope, raw: &[u8]) -> String {
        let mut mail = format!("MAIL FROM:<{}>", envelope.from);
        if self.max_size.is_some() {
            mail.push_str(&format!(" SIZE={}", raw.len()));
        }
        let utf8 = !envelope.from.is_ascii() || envelope.to.iter().any(|a| !a.is_ascii());
        if utf8 && self.has_extension("SMTPUTF8") {
            mail.push_str(" SMTPUTF8");
        }
        if !raw.is_ascii() && self.has_extension("8BITMIME") {
            mail.push_str(" BODY=8BITMIME");
        }
        mail
    }

    /// Sends a message to the recipients of `envelope` the server accepts. Fails when it accepts none or refuses
    /// the message; recipients it refused are in the report.
    pub async fn send(&mut self, envelope: &Envelope, raw: &[u8]) -> Result<SendReport, Error> {
        check_address(&envelope.from)?;
        for to in &envelope.to {
            check_address(to)?;
        }
        if let Some(limit) = self.max_size
            && raw.len() as u64 > limit
        {
            return Err(Error::TooLarge { size: raw.len(), limit });
        }
        let mail = self.mail_from(envelope, raw);
        self.expect(&mail).await?;

        let mut accepted = Vec::new();
        let mut rejected = Vec::new();
        for to in &envelope.to {
            let response = self.command(&format!("RCPT TO:<{to}>")).await?;
            if response.is_positive() {
                accepted.push(to.clone());
            } else {
                rejected.push((to.clone(), response));
            }
        }
        if accepted.is_empty() {
            // the transaction is not going anywhere
            let _ = self.command("RSET").await;
            return Err(Error::NoRecipients { rejected });
        }

        let response = self.command("DATA").await?;
        if response.code != 354 {
            // close the transaction so the next message of the session starts clean
            let _ = self.command("RSET").await;
            return Err(Error::Refused {
                command: "DATA".into(),
                response,
            });
        }
        self.log(Direction::Client, &format!("(message, {} bytes)", raw.len()));
        let data = dot_stuff(raw);
        self.write(&data).await?;
        let response = self.read_response(self.config.timeouts.data).await?;
        if response.code != 250 {
            let _ = self.command("RSET").await;
            return Err(Error::Refused {
                command: "the message".into(),
                response,
            });
        }
        Ok(SendReport {
            accepted,
            rejected,
            response,
        })
    }

    /// Ends the session
    pub async fn quit(mut self) {
        if self.send_line("QUIT", None).await.is_ok() {
            let _ = self.read_response(self.config.timeouts.command).await;
        }
        self.stream.shutdown().await;
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn stuffing() {
        assert_eq!(dot_stuff(b"a\r\n.b\r\n..c\r\n"), b"a\r\n..b\r\n...c\r\n.\r\n");
        assert_eq!(dot_stuff(b".\nx"), b"..\r\nx\r\n.\r\n");
        assert_eq!(dot_stuff(b"a\rb"), b"a\r\nb\r\n.\r\n");
        assert_eq!(dot_stuff(b""), b".\r\n");
    }

    #[test]
    fn addresses_in_commands() {
        assert!(check_address("a@b.c").is_ok());
        assert!(check_address("a@b.c>\r\nRCPT TO:<evil@x").is_err());
        assert!(check_address("a<b@c").is_err());
    }
}
