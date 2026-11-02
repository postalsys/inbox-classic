//! Test support for the end-to-end tests: starts ImapKit, our in-memory IMAP server with an SMTP
//! server in front of its INBOX, through `core/e2e/harness.mjs`, and controls it over its REST API.
//!
//! The tests need Node.js and `npm ci` in `core/e2e`. Without them [`ImapKit::start`] returns None
//! and the test is skipped, unless `PE_E2E_REQUIRED` is set (CI sets it), then it fails.
#![forbid(unsafe_code)]

use std::io::{BufRead, BufReader, Read, Write};
use std::net::TcpStream;
use std::path::PathBuf;
use std::process::{Child, ChildStdin, Command, Stdio};

use std::sync::atomic::{AtomicUsize, Ordering};
use std::time::Duration;

use pe_imap::client::Timeouts;
use pe_imap::{Config, Credentials, Event};
use pe_net::{Security, Trust};
use serde_json::{Value, json};
use tokio::sync::mpsc::UnboundedReceiver;

/// A running ImapKit, stopped when dropped
pub struct ImapKit {
    child: Child,
    /// Closing it stops the server
    stdin: Option<ChildStdin>,
    pub imap: u16,
    pub imaps: u16,
    pub smtp: u16,
    pub rest: u16,
    /// The DER of the server's self-signed certificate, for STARTTLS and implicit TLS
    pub cert: Vec<u8>,
}

/// The default account of ImapKit
pub const USER: &str = "testuser";
pub const PASSWORD: &str = "testpass";
/// The access token of the default account for XOAUTH2 and OAUTHBEARER
pub const TOKEN: &str = "testtoken";

fn e2e_dir() -> PathBuf {
    PathBuf::from(env!("CARGO_MANIFEST_DIR")).join("../../e2e")
}

impl ImapKit {
    /// Starts ImapKit with `config` (ImapKit server options, `{}` for every plugin and the usual
    /// folders). None when Node.js or the harness dependencies are missing and the end-to-end
    /// tests are not required.
    pub fn start(config: Value) -> Option<ImapKit> {
        let dir = e2e_dir();
        let required = std::env::var_os("PE_E2E_REQUIRED").is_some();
        if !dir.join("node_modules/imapkit").exists() {
            assert!(
                !required,
                "PE_E2E_REQUIRED is set but core/e2e has no node_modules, run npm ci there"
            );
            eprintln!("skipping: run `npm ci` in core/e2e for the end-to-end tests");
            return None;
        }
        let spawned = Command::new("node")
            .arg("harness.mjs")
            .current_dir(&dir)
            .stdin(Stdio::piped())
            .stdout(Stdio::piped())
            .stderr(Stdio::inherit())
            .spawn();
        let mut child = match spawned {
            Ok(child) => child,
            Err(error) if !required => {
                eprintln!("skipping: can not run node: {error}");
                return None;
            }
            Err(error) => panic!("can not run node: {error}"),
        };
        let mut stdin = child.stdin.take().expect("stdin");
        writeln!(stdin, "{config}").expect("configure ImapKit");
        let mut line = String::new();
        BufReader::new(child.stdout.take().expect("stdout"))
            .read_line(&mut line)
            .expect("ImapKit ports");
        let ports: Value = serde_json::from_str(&line).unwrap_or_else(|_| panic!("ImapKit did not start: {line:?}"));
        let port = |name: &str| ports[name].as_u64().expect(name) as u16;
        let pem = std::fs::read_to_string(ports["cert"].as_str().expect("cert")).expect("read certificate");
        Some(ImapKit {
            imap: port("imap"),
            imaps: port("imaps"),
            smtp: port("smtp"),
            rest: port("rest"),
            cert: match pe_net::Trust::pinned_bytes(pem.as_bytes()) {
                Some(pe_net::Trust::Pinned(mut certificates)) => certificates.remove(0),
                _ => panic!("no certificate in ImapKit's PEM"),
            },
            stdin: Some(stdin),
            child,
        })
    }

    /// Adds a message to a mailbox as if another client did, returns its UID
    pub fn add_message(&self, mailbox: &str, raw: &str, flags: &[&str]) -> u64 {
        let body = json!({ "raw": raw, "flags": flags });
        let response = self.request("POST", &messages_path(mailbox, ""), Some(body));
        response["uid"]
            .as_u64()
            .unwrap_or_else(|| panic!("no UID in {response}"))
    }

    /// Changes flags as another client would, `action` is `add`, `remove` or `set`
    pub fn set_flags(&self, mailbox: &str, uids: &[u64], flags: &[&str], action: &str) {
        let body = json!({ "uids": uids, "flags": flags, "action": action });
        self.request("POST", &messages_path(mailbox, "/flags"), Some(body));
    }

    /// Expunges messages as another client would
    pub fn expunge(&self, mailbox: &str, uids: &[u64]) {
        self.request(
            "POST",
            &messages_path(mailbox, "/expunge"),
            Some(json!({ "uids": uids })),
        );
    }

    /// The messages of a mailbox as ImapKit stores them
    pub fn messages(&self, mailbox: &str) -> Vec<Value> {
        match self.request("GET", &messages_path(mailbox, "?raw=true"), None) {
            Value::Array(messages) => messages,
            other => panic!("not a message list: {other}"),
        }
    }

    /// One request to the REST API, panics on an error answer
    pub fn request(&self, method: &str, path: &str, body: Option<Value>) -> Value {
        let mut stream = TcpStream::connect(("127.0.0.1", self.rest)).expect("REST connection");
        let body = body.map(|b| b.to_string()).unwrap_or_default();
        let content_type = if method == "POST" || method == "PUT" {
            "Content-Type: application/json\r\n"
        } else {
            ""
        };
        write!(
            stream,
            "{method} {path} HTTP/1.1\r\nHost: localhost\r\n{content_type}Content-Length: {}\r\nConnection: close\r\n\r\n{body}",
            body.len()
        )
        .expect("REST request");
        let mut response = String::new();
        stream.read_to_string(&mut response).expect("REST response");
        let (head, body) = response.split_once("\r\n\r\n").unwrap_or((&response, ""));
        let status = head.split(' ').nth(1).unwrap_or("");
        assert!(status.starts_with('2'), "{method} {path}: {head}\n{body}");
        serde_json::from_str(body).unwrap_or(Value::Null)
    }
}

impl Drop for ImapKit {
    fn drop(&mut self) {
        drop(self.stdin.take());
        let _ = self.child.kill();
        let _ = self.child.wait();
    }
}

impl ImapKit {
    /// A client configuration for this server: the plain or the TLS port for `security`, its
    /// certificate pinned, and timeouts short enough for tests
    pub fn imap_config(&self, security: Security, credentials: Credentials) -> Config {
        let port = if security == Security::Tls {
            self.imaps
        } else {
            self.imap
        };
        let mut config = Config::new("127.0.0.1", port, security, credentials);
        config.trust = Trust::Pinned(vec![self.cert.clone()]);
        config.timeouts = Timeouts {
            connect: Duration::from_secs(10),
            greeting: Duration::from_secs(5),
            response: Duration::from_secs(10),
            idle: Duration::from_secs(60),
            poll: Duration::from_millis(200),
        };
        config
    }
}

impl ImapKit {
    /// Settings of the default account on this server, without encryption
    pub fn account_settings(&self) -> pe_store::AccountSettings {
        pe_store::AccountSettings {
            name: "Test".into(),
            email: "testuser@example.com".into(),
            username: USER.into(),
            imap_host: "127.0.0.1".into(),
            imap_port: self.imap,
            imap_security: pe_store::Security::Plain,
            smtp_host: "127.0.0.1".into(),
            smtp_port: self.smtp,
            smtp_security: pe_store::Security::Plain,
            auth: pe_store::Auth::Password,
        }
    }
}

/// A directory of its own for a test, removed with what is in it when dropped
pub struct TempDir(PathBuf);

impl TempDir {
    pub fn new(name: &str) -> TempDir {
        // tests run in parallel: a counter, the clock is not fine enough
        static NEXT: AtomicUsize = AtomicUsize::new(0);
        let n = NEXT.fetch_add(1, Ordering::Relaxed);
        let dir = std::env::temp_dir().join(format!("pe-{name}-{}-{n}", std::process::id()));
        std::fs::create_dir_all(&dir).expect("temporary directory");
        TempDir(dir)
    }

    pub fn path(&self) -> &std::path::Path {
        &self.0
    }
}

impl Drop for TempDir {
    fn drop(&mut self) {
        let _ = std::fs::remove_dir_all(&self.0);
    }
}

/// A mock OAuth token endpoint on 127.0.0.1: the code `the-code` and the refresh token `r1` give the access
/// token ImapKit takes (`TOKEN`); anything else is refused with `invalid_grant`. Runs until the test ends.
pub fn oauth_token_server() -> u16 {
    let listener = std::net::TcpListener::bind("127.0.0.1:0").expect("token server");
    let port = listener.local_addr().expect("token server").port();
    std::thread::spawn(move || {
        for socket in listener.incoming() {
            let Ok(mut socket) = socket else { continue };
            let mut request = Vec::new();
            let mut chunk = [0u8; 4096];
            while let Ok(read) = socket.read(&mut chunk) {
                request.extend_from_slice(&chunk[..read]);
                let text = String::from_utf8_lossy(&request);
                let complete = text.split_once("\r\n\r\n").is_some_and(|(head, body)| {
                    let length: usize = head
                        .lines()
                        .find_map(|l| l.strip_prefix("Content-Length: "))
                        .and_then(|l| l.parse().ok())
                        .unwrap_or(0);
                    body.len() >= length
                });
                if complete || read == 0 {
                    break;
                }
            }
            let text = String::from_utf8_lossy(&request).into_owned();
            let form = text.split_once("\r\n\r\n").map_or("", |(_, body)| body);
            let has = |pair: &str| form.split('&').any(|p| p == pair);
            let (status, body) =
                if has("grant_type=authorization_code") && has("code=the-code") && form.contains("code_verifier=") {
                    (
                        200,
                        format!(r#"{{"access_token":"{TOKEN}","refresh_token":"r1","expires_in":3600}}"#),
                    )
                } else if has("grant_type=refresh_token") && has("refresh_token=r1") {
                    (200, format!(r#"{{"access_token":"{TOKEN}","expires_in":3600}}"#))
                } else {
                    (400, r#"{"error":"invalid_grant"}"#.to_string())
                };
            let response = format!(
                "HTTP/1.1 {status} X\r\nContent-Type: application/json\r\nContent-Length: {}\r\n\r\n{body}",
                body.len()
            );
            let _ = socket.write_all(response.as_bytes());
        }
    });
    port
}

/// What the browser does after the user signed in at the page `url`: goes to its redirect address with
/// `code` and the page's state. Returns the page the app answered with.
pub fn oauth_browser(url: &str, code: &str) -> String {
    let query = url.split_once('?').map_or("", |(_, q)| q);
    let param = |key: &str| pe_net::http::query_param(query, key).unwrap_or_default();
    let redirect = param("redirect_uri");
    let port: u16 = redirect
        .trim_end_matches('/')
        .rsplit(':')
        .next()
        .and_then(|p| p.parse().ok())
        .expect("a loopback redirect address");
    let mut socket = TcpStream::connect(("127.0.0.1", port)).expect("the redirect listener");
    write!(
        socket,
        "GET /?code={code}&state={} HTTP/1.1\r\nHost: 127.0.0.1\r\n\r\n",
        param("state")
    )
    .expect("redirect");
    let mut page = String::new();
    let _ = socket.read_to_string(&mut page);
    page
}

/// The password login of the default account
pub fn password() -> Credentials {
    Credentials::Password {
        user: USER.into(),
        password: PASSWORD.into(),
    }
}

/// Waits up to 10 seconds for an event `accept` takes, skipping others
pub async fn wait_for(events: &mut UnboundedReceiver<Event>, mut accept: impl FnMut(&Event) -> bool) -> Event {
    let wait = async {
        loop {
            let event = events.recv().await.expect("event channel open");
            if accept(&event) {
                return event;
            }
        }
    };
    tokio::time::timeout(Duration::from_secs(10), wait)
        .await
        .expect("event within 10 seconds")
}

/// The REST path of the messages of a mailbox, with `suffix` after it
fn messages_path(mailbox: &str, suffix: &str) -> String {
    format!("/v1/mailboxes/{}/messages{suffix}", encode_path(mailbox))
}

/// A mailbox path in a REST URL: percent encoded, `/` included
fn encode_path(path: &str) -> String {
    path.bytes()
        .map(|c| match c {
            b'A'..=b'Z' | b'a'..=b'z' | b'0'..=b'9' | b'-' | b'_' | b'.' | b'~' => (c as char).to_string(),
            _ => format!("%{c:02X}"),
        })
        .collect()
}

/// A simple RFC 5322 message, as imapflow's tests build them
pub fn rfc822(subject: &str, body: &str) -> String {
    let id: String = subject.chars().filter(char::is_ascii_alphanumeric).collect();
    format!(
        "From: Sender <sender@example.com>\r\nTo: Receiver <receiver@example.com>\r\nSubject: {subject}\r\nMessage-ID: <{id}@example.com>\r\nDate: Mon, 6 Oct 2025 10:00:00 +0000\r\n\r\n{body}\r\n"
    )
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn paths_are_encoded() {
        assert_eq!(encode_path("Work/Projects &x"), "Work%2FProjects%20%26x");
    }

    #[test]
    fn starts_and_controls_imapkit() {
        let Some(server) = ImapKit::start(json!({})) else {
            return;
        };
        assert!(server.imap > 0 && server.smtp > 0);
        assert_eq!(server.cert[0], 0x30, "DER starts with a SEQUENCE");
        let uid = server.add_message("INBOX", &rfc822("Hello", "World"), &["\\Seen"]);
        assert!(uid > 0);
        let messages = server.messages("INBOX");
        assert_eq!(messages.len(), 1);
        assert_eq!(messages[0]["flags"], json!(["\\Seen"]), "{messages:?}");
    }
}
