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

use std::time::Duration;

use base64::Engine;
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
            cert: pem_to_der(&pem),
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

fn pem_to_der(pem: &str) -> Vec<u8> {
    let body: String = pem.lines().filter(|line| !line.starts_with("-----")).collect();
    base64::engine::general_purpose::STANDARD
        .decode(body)
        .expect("certificate PEM")
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
