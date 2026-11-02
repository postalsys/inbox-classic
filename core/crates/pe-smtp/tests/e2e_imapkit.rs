//! Sending through ImapKit's SMTP server (smtp-server, in front of the INBOX of its IMAP server, core/e2e): what
//! arrives is the message that was built, byte for byte once the dot-stuffing is undone, as nodemailer's
//! smtp-connection tests check against smtp-server.
//!
//! Skipped without Node.js and `npm ci` in core/e2e, unless PE_E2E_REQUIRED is set.

use std::sync::{Arc, Mutex};
use std::time::Duration;

use base64::Engine;
use base64::engine::general_purpose::STANDARD;
use pe_mime::Address;
use pe_mime::parser::ParsedAddress;
use pe_net::{Security, Trust};
use pe_smtp::client::{Direction, Timeouts};
use pe_smtp::{Attachment, Client, Config, Credentials, Message, build};
use pe_testkit::{ImapKit, PASSWORD, USER};
use serde_json::json;

fn config(server: &ImapKit, security: Security, credentials: Option<Credentials>) -> Config {
    let mut config = Config::new("127.0.0.1", server.smtp, security, credentials);
    config.trust = Trust::Pinned(vec![server.cert.clone()]);
    config.timeouts = Timeouts {
        connect: Duration::from_secs(10),
        greeting: Duration::from_secs(10),
        command: Duration::from_secs(10),
        data: Duration::from_secs(10),
    };
    config
}

fn message() -> Message {
    let to = |name: &str, address: &str| {
        ParsedAddress::Mailbox(Address {
            name: name.into(),
            address: address.into(),
        })
    };
    Message {
        from: Address {
            name: "Andris Reinman".into(),
            address: "andris@example.com".into(),
        },
        to: vec![to("Ülle", "ulle@example.com")],
        cc: vec![to("", "cc@example.com")],
        bcc: vec![to("", "hidden@example.com")],
        subject: "Tere õhtust 😀".into(),
        text: Some("Hello\n.line starting with a dot\n..and two\n".into()),
        html: Some("<p>Hello <b>world</b></p>".into()),
        attachments: vec![Attachment {
            filename: "aruanne.pdf".into(),
            content_type: "application/pdf".into(),
            content: b"%PDF-1.4 ".repeat(100),
            content_id: None,
        }],
        date: 1_759_744_800,
        ..Default::default()
    }
}

/// The raw messages in the INBOX of ImapKit
fn inbox(server: &ImapKit) -> Vec<Vec<u8>> {
    server
        .messages("INBOX")
        .iter()
        .map(|m| {
            let raw = m["raw"].as_str().expect("raw message");
            STANDARD.decode(raw).unwrap_or_else(|_| raw.as_bytes().to_vec())
        })
        .collect()
}

#[tokio::test]
async fn delivers_the_message_as_built() {
    let Some(server) = ImapKit::start(json!({})) else {
        return;
    };
    let built = build(&message());
    let mut client = Client::connect(config(&server, Security::Plain, None)).await.unwrap();
    let report = client.send(&built.envelope, &built.raw).await.unwrap();
    assert_eq!(
        report.accepted,
        ["ulle@example.com", "cc@example.com", "hidden@example.com"]
    );
    assert!(report.rejected.is_empty());
    client.quit().await;

    let inbox = inbox(&server);
    assert_eq!(inbox.len(), 1);
    assert_eq!(String::from_utf8_lossy(&inbox[0]), String::from_utf8_lossy(&built.raw));
    let parsed = pe_mime::parser::parse(&inbox[0]).unwrap();
    assert_eq!(parsed.subject.as_deref(), Some("Tere õhtust 😀"));
    assert_eq!(
        parsed.text.as_deref(),
        Some("Hello\n.line starting with a dot\n..and two\n")
    );
    assert_eq!(parsed.attachments[0].content, b"%PDF-1.4 ".repeat(100));
}

#[tokio::test]
async fn starttls_and_authentication() {
    let Some(server) = ImapKit::start(json!({})) else {
        return;
    };
    let wire = Arc::new(Mutex::new(Vec::<(Direction, String)>::new()));
    let credentials = Credentials::Password {
        user: USER.into(),
        password: PASSWORD.into(),
    };
    let mut config = config(&server, Security::StartTls, Some(credentials));
    let log = wire.clone();
    config.wire_log = Some(Arc::new(move |direction, line| {
        log.lock().unwrap().push((direction, line.to_string()))
    }));
    let mut client = Client::connect(config).await.unwrap();
    assert!(client.is_secure());
    let built = build(&message());
    client.send(&built.envelope, &built.raw).await.unwrap();
    client.quit().await;
    assert_eq!(inbox(&server).len(), 1);

    let wire = wire.lock().unwrap();
    assert!(wire.iter().any(|(d, l)| *d == Direction::Client && l == "STARTTLS"));
    assert!(wire.iter().any(|(_, l)| l.contains("credentials hidden")));
    // the password never reaches the log, plain or base64
    let encoded = STANDARD.encode(format!("\0{USER}\0{PASSWORD}"));
    assert!(
        wire.iter().all(|(_, l)| !l.contains(PASSWORD) && !l.contains(&encoded)),
        "{wire:?}"
    );
}

#[tokio::test]
async fn a_pinned_certificate_that_does_not_match_is_refused() {
    let Some(server) = ImapKit::start(json!({})) else {
        return;
    };
    let mut config = config(&server, Security::StartTls, None);
    config.trust = Trust::Pinned(vec![vec![0x30, 0x03, 0x02, 0x01, 0x00]]);
    let error = Client::connect(config).await.err().unwrap();
    assert_eq!(error.kind(), pe_smtp::ErrorKind::Security, "{error}");
}
