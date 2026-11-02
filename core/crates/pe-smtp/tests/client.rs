//! The SMTP client against a scripted server: each test plays the server's side of a session line by line and
//! checks what the client sent, for the answers a real server gives rarely (refusals, temporary failures, odd
//! greetings, data injected before a TLS handshake), as nodemailer's smtp-connection tests do with smtp-server.

use std::time::Duration;

use pe_net::Security;
use pe_smtp::client::{Timeouts, dot_stuff};
use pe_smtp::{Client, Config, Credentials, Envelope, Error, ErrorKind};
use tokio::io::{AsyncBufReadExt, AsyncWriteExt, BufReader};
use tokio::net::TcpListener;
use tokio::task::JoinHandle;

enum Step {
    /// Send these lines (CRLF added)
    Say(&'static str),
    /// Read a line, which has to start with this
    Expect(&'static str),
    /// Read the message data up to the lone dot
    Data,
    /// Close the connection
    Close,
}
use Step::*;

/// A server that plays `script` for one connection; the handle gives what the client sent
async fn server(script: Vec<Step>) -> (u16, JoinHandle<Vec<String>>) {
    let listener = TcpListener::bind("127.0.0.1:0").await.unwrap();
    let port = listener.local_addr().unwrap().port();
    let handle = tokio::spawn(async move {
        let (socket, _) = listener.accept().await.unwrap();
        let (read, mut write) = socket.into_split();
        let mut read = BufReader::new(read);
        let mut received = Vec::new();
        for step in script {
            match step {
                Say(text) => write
                    .write_all(format!("{}\r\n", text.replace('\n', "\r\n")).as_bytes())
                    .await
                    .unwrap(),
                Expect(prefix) => {
                    let mut line = String::new();
                    read.read_line(&mut line).await.unwrap();
                    assert!(line.starts_with(prefix), "expected {prefix:?}, got {line:?}");
                    received.push(line.trim_end().to_string());
                }
                Data => loop {
                    let mut line = String::new();
                    read.read_line(&mut line).await.unwrap();
                    received.push(line.clone());
                    if line == ".\r\n" {
                        break;
                    }
                },
                Close => return received,
            }
        }
        received
    });
    (port, handle)
}

fn config(port: u16, credentials: Option<Credentials>) -> Config {
    let mut config = Config::new("127.0.0.1", port, Security::Plain, credentials);
    config.timeouts = Timeouts {
        connect: Duration::from_secs(5),
        greeting: Duration::from_secs(5),
        command: Duration::from_secs(5),
        data: Duration::from_secs(5),
    };
    config
}

fn envelope(to: &[&str]) -> Envelope {
    Envelope {
        from: "sender@example.com".into(),
        to: to.iter().map(|s| s.to_string()).collect(),
    }
}

const EHLO: &str =
    "250-mx.example.com at your service\n250-SIZE 1000\n250-8BITMIME\n250-SMTPUTF8\n250 AUTH LOGIN PLAIN XOAUTH2";

#[tokio::test]
async fn sends_to_the_recipients_the_server_takes() {
    let (port, handle) = server(vec![
        Say("220 mx.example.com ESMTP"),
        Expect("EHLO "),
        Say(EHLO),
        Expect("MAIL FROM:<sender@example.com> SIZE=25"),
        Say("250 2.1.0 Ok"),
        Expect("RCPT TO:<a@example.com>"),
        Say("250 2.1.5 Ok"),
        Expect("RCPT TO:<nobody@example.com>"),
        Say("550 5.1.1 <nobody@example.com>: no such user"),
        Expect("DATA"),
        Say("354 go ahead"),
        Data,
        Say("250 2.0.0 Ok: queued as ABC123"),
        Expect("QUIT"),
        Say("221 bye"),
    ])
    .await;
    let mut client = Client::connect(config(port, None)).await.unwrap();
    assert!(client.has_extension("8bitmime") && !client.is_secure());
    let report = client
        .send(
            &envelope(&["a@example.com", "nobody@example.com"]),
            b"Subject: x\r\n\r\n.dot line\r\n",
        )
        .await
        .unwrap();
    assert_eq!(report.accepted, ["a@example.com"]);
    assert_eq!(report.rejected.len(), 1);
    assert_eq!(report.rejected[0].1.code, 550);
    assert_eq!(report.rejected[0].1.enhanced.as_deref(), Some("5.1.1"));
    assert_eq!(report.response.text(), "Ok: queued as ABC123");
    client.quit().await;
    let received = handle.await.unwrap();
    // the dot at the start of the line is doubled
    assert!(received.contains(&"..dot line\r\n".to_string()), "{received:?}");
}

#[tokio::test]
async fn authenticates_with_what_the_server_offers() {
    let plain = format!("AUTH PLAIN {}", "AHVzZXIAc2VjcmV0");
    let plain: &'static str = Box::leak(plain.into_boxed_str());
    let (port, handle) = server(vec![
        Say("220 hi"),
        Expect("EHLO"),
        Say(EHLO),
        Expect(plain),
        Say("235 2.7.0 Authentication successful"),
    ])
    .await;
    let credentials = Credentials::Password {
        user: "user".into(),
        password: "secret".into(),
    };
    Client::connect(config(port, Some(credentials.clone()))).await.unwrap();
    handle.await.unwrap();

    // LOGIN when PLAIN is not offered
    let (port, handle) = server(vec![
        Say("220 hi"),
        Expect("EHLO"),
        Say("250-hi\n250 AUTH LOGIN"),
        Expect("AUTH LOGIN"),
        Say("334 VXNlcm5hbWU6"),
        Expect("dXNlcg=="),
        Say("334 UGFzc3dvcmQ6"),
        Expect("c2VjcmV0"),
        Say("535 5.7.8 bad credentials"),
    ])
    .await;
    let error = Client::connect(config(port, Some(credentials.clone())))
        .await
        .err()
        .unwrap();
    assert_eq!(error.kind(), ErrorKind::Authentication);
    assert!(
        matches!(error, Error::AuthenticationFailed(ref r) if r.code == 535),
        "{error}"
    );

    // encryption wanted for the password: a security setting to change, not a password to type again
    let (port, refusing) = server(vec![
        Say("220 hi"),
        Expect("EHLO"),
        Say("250-hi\n250 AUTH PLAIN"),
        Expect("AUTH PLAIN"),
        Say("538 5.7.11 Encryption required for requested authentication mechanism"),
    ])
    .await;
    let error = Client::connect(config(port, Some(credentials.clone())))
        .await
        .err()
        .unwrap();
    assert_eq!(error.kind(), ErrorKind::Security, "{error}");
    assert!(error.to_string().contains("encrypted connection"), "{error}");
    refusing.await.unwrap();
    handle.await.unwrap();

    // XOAUTH2, its error challenge answered with an empty line
    let (port, handle) = server(vec![
        Say("220 hi"),
        Expect("EHLO"),
        Say(EHLO),
        Expect("AUTH XOAUTH2 dXNlcj11c2VyAWF1dGg9QmVhcmVyIHRva2VuAQE="),
        Say("334 eyJzdGF0dXMiOiI0MDEifQ=="),
        Expect(""),
        Say("535 5.7.8 token expired"),
    ])
    .await;
    let oauth = Credentials::OAuth2 {
        user: "user".into(),
        access_token: "token".into(),
    };
    let error = Client::connect(config(port, Some(oauth))).await.err().unwrap();
    assert!(matches!(error, Error::AuthenticationFailed(_)), "{error}");
    handle.await.unwrap();
}

#[tokio::test]
async fn no_auth_method_for_the_credentials() {
    let (port, _handle) = server(vec![Say("220 hi"), Expect("EHLO"), Say("250-hi\n250 AUTH CRAM-MD5")]).await;
    let oauth = Credentials::OAuth2 {
        user: "u".into(),
        access_token: "t".into(),
    };
    let error = Client::connect(config(port, Some(oauth))).await.err().unwrap();
    assert!(matches!(error, Error::AuthenticationUnavailable), "{error}");
}

#[tokio::test]
async fn no_auth_offered_no_auth_sent() {
    // a relay that takes mail without logging in: the password is not sent at all
    let (port, handle) = server(vec![Say("220 relay"), Expect("EHLO"), Say("250-relay\n250 SIZE 100")]).await;
    let credentials = Credentials::Password {
        user: "u".into(),
        password: "secret".into(),
    };
    Client::connect(config(port, Some(credentials))).await.unwrap();
    assert!(handle.await.unwrap().iter().all(|line| !line.starts_with("AUTH")));
}

#[tokio::test]
async fn helo_for_an_old_server() {
    let (port, handle) = server(vec![
        Say("220 old"),
        Expect("EHLO"),
        Say("502 what"),
        Expect("HELO [127.0.0.1]"),
        Say("250 old.example.com"),
        Expect("MAIL FROM:<sender@example.com>"),
        Say("250 ok"),
        Expect("RCPT TO:<a@example.com>"),
        Say("250 ok"),
        Expect("DATA"),
        Say("354 go"),
        Data,
        Say("250 ok"),
    ])
    .await;
    let mut client = Client::connect(config(port, None)).await.unwrap();
    // no SIZE, no 8BITMIME parameters for a server that did not offer them
    client
        .send(&envelope(&["a@example.com"]), "Subject: ü\r\n\r\nx\r\n".as_bytes())
        .await
        .unwrap();
    let received = handle.await.unwrap();
    assert!(
        received.contains(&"MAIL FROM:<sender@example.com>".to_string()),
        "{received:?}"
    );
}

#[tokio::test]
async fn refusals_and_temporary_failures() {
    // no recipient taken: RSET, and the error lists them
    let (port, _handle) = server(vec![
        Say("220 hi"),
        Expect("EHLO"),
        Say("250 hi"),
        Expect("MAIL FROM"),
        Say("250 ok"),
        Expect("RCPT TO:<a@example.com>"),
        Say("450 4.2.0 mailbox busy, try later"),
        Expect("RSET"),
        Say("250 ok"),
    ])
    .await;
    let mut client = Client::connect(config(port, None)).await.unwrap();
    let error = client.send(&envelope(&["a@example.com"]), b"x\r\n").await.unwrap_err();
    assert!(
        matches!(error, Error::NoRecipients { ref rejected } if rejected.len() == 1),
        "{error}"
    );
    assert!(error.is_temporary());

    // a login wanted first: an authentication problem, not a refused message
    let (port, _handle) = server(vec![
        Say("220 hi"),
        Expect("EHLO"),
        Say("250 hi"),
        Expect("MAIL FROM"),
        Say("530 5.7.0 Must issue a STARTTLS command first"),
    ])
    .await;
    let mut client = Client::connect(config(port, None)).await.unwrap();
    let error = client.send(&envelope(&["a@example.com"]), b"x\r\n").await.unwrap_err();
    assert_eq!(error.kind(), ErrorKind::Authentication, "{error}");

    // the message refused after the data
    let (port, _handle) = server(vec![
        Say("220 hi"),
        Expect("EHLO"),
        Say("250 hi"),
        Expect("MAIL FROM"),
        Say("250 ok"),
        Expect("RCPT TO"),
        Say("250 ok"),
        Expect("DATA"),
        Say("354 go"),
        Data,
        Say("554 5.7.1 message looks like spam"),
        // reset, so the next message of the session (the next of an Outbox) is a transaction of its own
        Expect("RSET"),
        Say("250 ok"),
        Expect("MAIL FROM"),
        Say("250 ok"),
        Expect("RCPT TO"),
        Say("250 ok"),
        Expect("DATA"),
        Say("451 4.3.0 try again later"),
        Expect("RSET"),
        Say("250 ok"),
        Expect("MAIL FROM"),
        Say("250 ok"),
        Expect("RCPT TO"),
        Say("250 ok"),
        Expect("DATA"),
        Say("354 go"),
        Data,
        Say("250 queued"),
    ])
    .await;
    let mut client = Client::connect(config(port, None)).await.unwrap();
    let error = client.send(&envelope(&["a@example.com"]), b"x\r\n").await.unwrap_err();
    assert_eq!(error.kind(), ErrorKind::Refused);
    assert!(!error.is_temporary());
    assert!(error.to_string().contains("spam"));
    let error = client.send(&envelope(&["a@example.com"]), b"x\r\n").await.unwrap_err();
    assert!(error.is_temporary(), "{error}");
    let report = client.send(&envelope(&["a@example.com"]), b"x\r\n").await.unwrap();
    assert_eq!(report.accepted, ["a@example.com"]);

    // too large for the server's SIZE
    let (port, _handle) = server(vec![Say("220 hi"), Expect("EHLO"), Say("250-hi\n250 SIZE 10")]).await;
    let mut client = Client::connect(config(port, None)).await.unwrap();
    let error = client
        .send(&envelope(&["a@example.com"]), &[b'x'; 100])
        .await
        .unwrap_err();
    assert!(matches!(error, Error::TooLarge { limit: 10, .. }), "{error}");

    // an address that would add a command of its own
    let error = client
        .send(&envelope(&["a@example.com>\r\nRCPT TO:<b@example.com"]), b"x")
        .await
        .unwrap_err();
    assert!(matches!(error, Error::InvalidAddress(_)), "{error}");
}

#[tokio::test]
async fn greetings_and_garbage() {
    let (port, _handle) = server(vec![Say("554 no service for you")]).await;
    let error = Client::connect(config(port, None)).await.err().unwrap();
    assert!(
        matches!(error, Error::Refused { ref response, .. } if response.code == 554),
        "{error}"
    );

    let (port, _handle) = server(vec![Say("* OK this is IMAP")]).await;
    let error = Client::connect(config(port, None)).await.err().unwrap();
    assert_eq!(error.kind(), ErrorKind::Protocol);

    let (port, _handle) = server(vec![Say("220 hi"), Expect("EHLO"), Close]).await;
    let error = Client::connect(config(port, None)).await.err().unwrap();
    assert_eq!(error.kind(), ErrorKind::Network);
    assert!(error.is_temporary());

    // no answer at all: the greeting times out
    let (port, _handle) = server(vec![Expect("never")]).await;
    let mut config = config(port, None);
    config.timeouts.greeting = Duration::from_millis(200);
    let error = Client::connect(config).await.err().unwrap();
    assert!(matches!(error, Error::Net(pe_net::Error::Timeout)), "{error}");
}

#[tokio::test]
async fn starttls_is_required() {
    // not offered
    let (port, _handle) = server(vec![Say("220 hi"), Expect("EHLO"), Say("250 hi")]).await;
    let mut config = config(port, None);
    config.security = Security::StartTls;
    let error = Client::connect(config.clone()).await.err().unwrap();
    assert!(matches!(error, Error::StartTlsUnavailable), "{error}");
    assert_eq!(error.kind(), ErrorKind::Security);

    // STARTTLS answered with anything but 220
    let (port, _handle) = server(vec![
        Say("220 hi"),
        Expect("EHLO"),
        Say("250-hi\n250 STARTTLS"),
        Expect("STARTTLS"),
        Say("250 sure"),
    ])
    .await;
    config.port = port;
    let error = Client::connect(config.clone()).await.err().unwrap();
    assert!(
        matches!(error, Error::Refused { ref command, .. } if command == "STARTTLS"),
        "{error}"
    );

    // plaintext after the go-ahead, before the handshake: refused
    let (port, _handle) = server(vec![
        Say("220 hi"),
        Expect("EHLO"),
        Say("250-hi\n250 STARTTLS"),
        Expect("STARTTLS"),
        Say("220 go ahead\n250-injected\n250 AUTH PLAIN"),
    ])
    .await;
    config.port = port;
    let error = Client::connect(config).await.err().unwrap();
    assert!(matches!(error, Error::StartTlsInjection), "{error}");
}

#[test]
fn stuffing_is_reversible() {
    let raw = b"a\r\n.\r\n..\r\nb";
    let stuffed = dot_stuff(raw);
    assert_eq!(stuffed, b"a\r\n..\r\n...\r\nb\r\n.\r\n");
}
