//! End-to-end sessions against ImapKit, our in-memory IMAP server (core/e2e), the way imapflow's
//! test/imapkit suites test imapflow. ImapKit answers client input that breaks the RFCs with BAD,
//! so every test also checks that the client sent nothing ImapKit refused, unless the test makes
//! the server send BAD on purpose.
//!
//! Skipped without Node.js and `npm ci` in core/e2e, unless PE_E2E_REQUIRED is set.

use std::sync::{Arc, Mutex};
use std::time::Duration;

use pe_imap::client::{Direction, Error, FetchQuery, SearchKey, StoreAction, Timeouts};
use pe_imap::{Client, Config, Credentials, Event};
use pe_net::{Security, Trust};
use pe_testkit::{ImapKit, PASSWORD, TOKEN, USER, rfc822};
use serde_json::{Value, json};
use tokio::sync::mpsc::UnboundedReceiver;

type Wire = Arc<Mutex<Vec<(Direction, String)>>>;

struct Kit {
    server: ImapKit,
    wire: Wire,
    allow_bad: bool,
}

impl Kit {
    fn start(config: Value) -> Option<Kit> {
        ImapKit::start(config).map(|server| Kit {
            server,
            wire: Arc::default(),
            allow_bad: false,
        })
    }

    fn config(&self, security: Security, credentials: Credentials) -> Config {
        let port = if security == Security::Tls {
            self.server.imaps
        } else {
            self.server.imap
        };
        let mut config = Config::new("127.0.0.1", port, security, credentials);
        config.trust = Trust::Pinned(vec![self.server.cert.clone()]);
        config.timeouts = Timeouts {
            connect: Duration::from_secs(10),
            greeting: Duration::from_secs(5),
            response: Duration::from_secs(10),
            idle: Duration::from_secs(60),
            poll: Duration::from_millis(200),
        };
        let wire = self.wire.clone();
        config.wire_log = Some(Arc::new(move |direction, line| {
            wire.lock().unwrap().push((direction, line.to_string()))
        }));
        config
    }

    async fn connect_with(&self, config: Config) -> Result<(Client, UnboundedReceiver<Event>), Error> {
        Client::connect(config).await
    }

    async fn connect(&self) -> (Client, UnboundedReceiver<Event>) {
        self.connect_with(self.config(Security::Plain, password()))
            .await
            .expect("connect")
    }

    fn sent(&self, needle: &str) -> bool {
        self.lines(Direction::Client).iter().any(|line| line.contains(needle))
    }

    fn received(&self, needle: &str) -> bool {
        self.lines(Direction::Server).iter().any(|line| line.contains(needle))
    }

    fn lines(&self, direction: Direction) -> Vec<String> {
        self.wire
            .lock()
            .unwrap()
            .iter()
            .filter(|(d, _)| *d == direction)
            .map(|(_, l)| l.clone())
            .collect()
    }
}

impl Drop for Kit {
    fn drop(&mut self) {
        if self.allow_bad || std::thread::panicking() {
            return;
        }
        let bad: Vec<String> = self
            .lines(Direction::Server)
            .into_iter()
            .filter(|line| {
                line.split(' ')
                    .nth(1)
                    .is_some_and(|status| status.eq_ignore_ascii_case("BAD"))
            })
            .collect();
        assert!(bad.is_empty(), "ImapKit answered client input with BAD: {bad:?}");
    }
}

fn password() -> Credentials {
    Credentials::Password {
        user: USER.into(),
        password: PASSWORD.into(),
    }
}

/// The client and the ImapKit for a test, or a skipped test
macro_rules! kit {
    ($config:expr) => {
        match Kit::start($config) {
            Some(kit) => kit,
            None => return,
        }
    };
}

/// Flags without \Recent, which only IMAP4rev1 sessions report, sorted (imapflow's flagList)
fn flag_list(flags: &[String]) -> Vec<&str> {
    let mut list: Vec<&str> = flags.iter().map(String::as_str).filter(|f| *f != "\\Recent").collect();
    list.sort_unstable();
    list
}

/// Waits for an event the predicate accepts, skipping others
async fn wait_for(events: &mut UnboundedReceiver<Event>, accept: impl Fn(&Event) -> bool) -> Event {
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

// ---- authentication and transport (imapflow test/imapkit/auth-transport-test.ts) ----

#[tokio::test]
async fn login_on_a_server_without_auth_mechanisms() {
    let kit = kit!(json!({ "plugins": [] }));
    let (mut client, _) = kit.connect().await;
    assert!(
        kit.sent("LOGIN \"testuser\" \"(* value hidden *)\""),
        "password hidden in the log"
    );
    assert!(!kit.sent(PASSWORD), "the password never reaches the log");
    client.logout().await.unwrap();
}

#[tokio::test]
async fn login_failure_is_an_authentication_failure() {
    let kit = kit!(json!({ "plugins": [] }));
    let config = kit.config(
        Security::Plain,
        Credentials::Password {
            user: USER.into(),
            password: "wrong".into(),
        },
    );
    let error = kit.connect_with(config).await.err().expect("refused");
    assert!(matches!(error, Error::AuthenticationFailed { .. }), "{error:?}");
}

#[tokio::test]
async fn authenticate_plain_with_and_without_sasl_ir() {
    for plugins in [json!(["AUTH-PLAIN", "SASL-IR"]), json!(["AUTH-PLAIN"])] {
        let kit = kit!(json!({ "plugins": plugins }));
        let (mut client, _) = kit.connect().await;
        assert!(kit.sent("AUTHENTICATE PLAIN"));
        assert!(!kit.sent("LOGIN"));
        client.noop().await.unwrap();
    }
}

#[tokio::test]
async fn utf8_credentials_go_through_authenticate_plain() {
    let kit =
        kit!(json!({ "plugins": ["AUTH-PLAIN", "SASL-IR"], "users": { "jõgi@näide.ee": { "password": "pässwörd" } } }));
    let credentials = Credentials::Password {
        user: "jõgi@näide.ee".into(),
        password: "pässwörd".into(),
    };
    let (mut client, _) = kit
        .connect_with(kit.config(Security::Plain, credentials))
        .await
        .unwrap();
    client.noop().await.unwrap();
}

#[tokio::test]
async fn oauth_mechanisms() {
    for (plugins, mechanism) in [
        (json!(["XOAUTH2", "SASL-IR"]), "XOAUTH2"),
        (json!(["XOAUTH2", "OAUTHBEARER", "SASL-IR"]), "OAUTHBEARER"),
        (json!(["OAUTHBEARER"]), "OAUTHBEARER"),
    ] {
        let kit = kit!(json!({ "plugins": plugins }));
        let token = Credentials::OAuth2 {
            user: USER.into(),
            access_token: TOKEN.into(),
        };
        let (mut client, _) = kit.connect_with(kit.config(Security::Plain, token)).await.unwrap();
        assert!(kit.sent(&format!("AUTHENTICATE {mechanism}")), "{mechanism}");
        assert!(!kit.sent(TOKEN));
        client.noop().await.unwrap();

        // a wrong token gets an error challenge, answered with an empty line, then NO
        let wrong = Credentials::OAuth2 {
            user: USER.into(),
            access_token: "wrong".into(),
        };
        let error = kit
            .connect_with(kit.config(Security::Plain, wrong))
            .await
            .err()
            .expect("refused");
        assert!(
            matches!(error, Error::AuthenticationFailed { .. }),
            "{mechanism}: {error:?}"
        );
    }
}

#[tokio::test]
async fn starttls_upgrade_with_a_fresh_capability() {
    let kit = kit!(json!({ "plugins": ["STARTTLS", "AUTH-PLAIN", "ID"] }));
    let (mut client, _) = kit
        .connect_with(kit.config(Security::StartTls, password()))
        .await
        .unwrap();
    assert!(client.is_secure());
    let sent = kit.lines(Direction::Client);
    let position = |needle: &str| sent.iter().position(|l| l.contains(needle)).unwrap_or(usize::MAX);
    // CAPABILITY again right after the upgrade, and ID only over TLS
    assert!(sent[position("STARTTLS") + 1].ends_with("CAPABILITY"), "{sent:?}");
    assert!(position("STARTTLS") < position("ID ("));
    client.noop().await.unwrap();
}

#[tokio::test]
async fn required_starttls_fails_without_it() {
    let kit = kit!(json!({ "plugins": [] }));
    let error = kit
        .connect_with(kit.config(Security::StartTls, password()))
        .await
        .err()
        .expect("refused");
    assert!(matches!(error, Error::StartTlsUnavailable), "{error:?}");
    assert!(!kit.sent("LOGIN"), "credentials never sent in plaintext");
}

#[tokio::test]
async fn logindisabled_before_starttls_login_after_it() {
    let kit = kit!(json!({ "plugins": ["STARTTLS", "LOGINDISABLED"] }));
    let (client, _) = kit
        .connect_with(kit.config(Security::StartTls, password()))
        .await
        .unwrap();
    assert!(client.is_secure() && !client.has_capability("LOGINDISABLED"));

    let error = kit
        .connect_with(kit.config(Security::Plain, password()))
        .await
        .err()
        .expect("refused");
    assert!(matches!(error, Error::NoAuthenticationMethod), "{error:?}");
}

#[tokio::test]
async fn implicit_tls() {
    let kit = kit!(json!({ "plugins": ["AUTH-PLAIN"] }));
    let (mut client, _) = kit.connect_with(kit.config(Security::Tls, password())).await.unwrap();
    assert!(client.is_secure());
    client.noop().await.unwrap();
}

#[tokio::test]
async fn certificates_that_are_not_trusted_are_refused_and_shown() {
    let kit = kit!(json!({}));
    for trust in [Trust::Platform, Trust::Pinned(vec![b"another certificate".to_vec()])] {
        let mut config = kit.config(Security::Tls, password());
        config.trust = trust;
        match kit.connect_with(config).await.err().expect("refused") {
            Error::Tls { certificate, .. } => assert_eq!(certificate.as_deref(), Some(kit.server.cert.as_slice())),
            other => panic!("{other:?}"),
        }
    }
}

#[tokio::test]
async fn plaintext_after_the_starttls_ok_is_refused() {
    let kit = kit!(json!({
        "plugins": ["STARTTLS", "AUTH-PLAIN"],
        "script": { "on": "command", "command": "STARTTLS", "send": "$TAG OK Begin TLS\r\n* CAPABILITY IMAP4rev1 AUTH=PLAIN\r\n" }
    }));
    let error = kit
        .connect_with(kit.config(Security::StartTls, password()))
        .await
        .err()
        .expect("refused");
    assert!(matches!(error, Error::StartTlsInjection), "{error:?}");
}

// ---- mailboxes (imapflow storage-state and extensions tests) ----

#[tokio::test]
async fn lists_special_use_folders_first() {
    let kit = kit!(json!({}));
    let (mut client, _) = kit.connect().await;
    let list = client.list().await.unwrap();
    let summary: Vec<(&str, Option<&str>)> = list.iter().map(|m| (m.path.as_str(), m.special_use)).collect();
    assert_eq!(
        summary,
        vec![
            ("INBOX", Some("\\Inbox")),
            ("Sent", Some("\\Sent")),
            ("Drafts", Some("\\Drafts")),
            ("Archive", Some("\\Archive")),
            ("Junk", Some("\\Junk")),
            ("Trash", Some("\\Trash")),
        ]
    );
    assert!(list.iter().all(|m| m.subscribed && m.delimiter.as_deref() == Some("/")));
}

#[tokio::test]
async fn special_use_by_name_without_the_extension() {
    let storage = json!({
        "INBOX": {},
        "": { "separator": "/", "folders": { "Sent Items": {}, "Deleted Items": {}, "Projects": { "folders": { "Sent": {} } } } }
    });
    let kit = kit!(json!({ "plugins": ["IDLE"], "storage": storage }));
    let (mut client, _) = kit.connect().await;
    let list = client.list().await.unwrap();
    let find = |path: &str| list.iter().find(|m| m.path == path).unwrap().special_use;
    assert_eq!(find("Sent Items"), Some("\\Sent"));
    assert_eq!(find("Deleted Items"), Some("\\Trash"));
    // the shallower folder wins
    assert_eq!(find("Projects/Sent"), None);
}

#[tokio::test]
async fn non_ascii_names_are_modified_utf7_without_utf8_accept() {
    let kit = kit!(json!({ "plugins": ["SPECIAL-USE", "UIDPLUS"] }));
    let (mut client, _) = kit.connect().await;
    assert!(client.create("Отправленные").await.unwrap());
    assert!(client.create("Tom & Jerry").await.unwrap());
    assert!(!client.create("Tom & Jerry").await.unwrap(), "exists already");
    assert!(kit.sent("CREATE \"&BB4EQgQ,BEAEMAQyBDsENQQ9BD0ESwQ1-\""));
    let paths: Vec<String> = client.list().await.unwrap().into_iter().map(|m| m.path).collect();
    assert!(
        paths.contains(&"Отправленные".to_string()) && paths.contains(&"Tom & Jerry".to_string()),
        "{paths:?}"
    );
    client.rename("Tom & Jerry", "Jerry").await.unwrap();
    client.delete("Отправленные").await.unwrap();
    let paths: Vec<String> = client.list().await.unwrap().into_iter().map(|m| m.path).collect();
    assert!(paths.contains(&"Jerry".to_string()) && !paths.contains(&"Отправленные".to_string()));
}

#[tokio::test]
async fn utf8_names_with_utf8_accept() {
    let kit = kit!(json!({}));
    let (mut client, _) = kit.connect().await;
    assert!(client.is_enabled("UTF8=ACCEPT"));
    assert!(client.create("Šegregator").await.unwrap());
    assert!(kit.sent("CREATE \"Šegregator\""));
    assert!(client.list().await.unwrap().iter().any(|m| m.path == "Šegregator"));
}

#[tokio::test]
async fn select_and_status() {
    let kit = kit!(json!({}));
    kit.server.add_message("INBOX", &rfc822("One", "1"), &["\\Seen"]);
    kit.server.add_message("INBOX", &rfc822("Two", "2"), &[]);
    let (mut client, _) = kit.connect().await;

    let status = client.status("INBOX").await.unwrap();
    assert_eq!((status.messages, status.unseen), (Some(2), Some(1)));
    assert!(status.uid_validity.is_some() && status.highest_modseq.is_some());

    let selected = client.select("INBOX").await.unwrap();
    assert_eq!(selected.exists, 2);
    assert!(!selected.read_only);
    assert_eq!(selected.uid_next, Some(3));
    assert!(selected.flags.iter().any(|f| f == "\\Seen"));
    assert!(selected.highest_modseq.is_some(), "CONDSTORE is enabled");

    let examined = client.examine("Sent").await.unwrap();
    assert!(examined.read_only);
    assert_eq!(client.selected().unwrap().path, "Sent");
    // EXAMINE refuses flag changes
    assert!(client.store("1:*", true, StoreAction::Add, &["\\Seen"]).await.is_err());
    client.unselect().await.unwrap();
    assert!(client.selected().is_none());
    assert!(matches!(
        client.fetch("1", false, &FetchQuery::default()).await,
        Err(Error::NoMailboxSelected)
    ));
}

// ---- messages ----

const MULTIPART: &str = "From: =?UTF-8?Q?J=C3=B5ul?= <joul@example.com>\r\nTo: Receiver <receiver@example.com>, group: a@b.c, d@e.f;\r\nSubject: =?UTF-8?Q?Tere_t=C3=A4na?=\r\nMessage-ID: <multi@example.com>\r\nDate: Mon, 6 Oct 2025 10:00:00 +0000\r\nMIME-Version: 1.0\r\nContent-Type: multipart/mixed; boundary=\"b1\"\r\n\r\n--b1\r\nContent-Type: text/plain; charset=utf-8\r\n\r\nHello world\r\n--b1\r\nContent-Type: application/octet-stream; name=\"=?UTF-8?Q?=C3=B5.bin?=\"\r\nContent-Disposition: attachment; filename*=utf-8''%C3%B5.bin\r\nContent-Transfer-Encoding: base64\r\n\r\nAAECAw==\r\n--b1--\r\n";

#[tokio::test]
async fn append_and_fetch_everything() {
    let kit = kit!(json!({}));
    let (mut client, _) = kit.connect().await;
    let appended = client
        .append(
            "INBOX",
            MULTIPART.as_bytes(),
            &["\\Flagged", "$Label1"],
            Some(1_759_744_800),
        )
        .await
        .unwrap();
    let (_, uid) = appended.expect("APPENDUID");
    client.select("INBOX").await.unwrap();

    let query = FetchQuery {
        flags: true,
        envelope: true,
        body_structure: true,
        internal_date: true,
        size: true,
        modseq: true,
        headers: Some(vec!["Subject".into()]),
        parts: vec!["1".into(), "2".into()],
        source: true,
        ..Default::default()
    };
    let messages = client.fetch(&uid.to_string(), true, &query).await.unwrap();
    assert_eq!(messages.len(), 1);
    let message = &messages[0];
    assert_eq!(message.uid, Some(uid));
    let flags = message.flags.clone().unwrap();
    assert!(
        flags.contains(&"\\Flagged".into()) && flags.contains(&"$Label1".into()),
        "{flags:?}"
    );
    assert_eq!(message.internal_date, Some(1_759_744_800));
    assert_eq!(message.size, Some(MULTIPART.len() as u64));
    assert!(message.modseq.is_some());

    let envelope = message.envelope.as_ref().unwrap();
    assert_eq!(envelope.subject.as_deref(), Some("Tere täna"));
    assert_eq!(envelope.from[0].name, "Jõul");
    assert_eq!(envelope.from[0].address, "joul@example.com");
    assert_eq!(envelope.message_id.as_deref(), Some("<multi@example.com>"));
    assert_eq!(envelope.timestamp(), Some(1_759_744_800));

    let structure = message.body_structure.as_ref().unwrap();
    assert_eq!(structure.content_type, "multipart/mixed");
    assert_eq!(structure.children[1].disposition_parameters["filename"], "õ.bin");
    assert_eq!(structure.children[1].parameters["name"], "õ.bin");

    assert_eq!(message.source.as_deref(), Some(MULTIPART.as_bytes()));
    assert!(String::from_utf8_lossy(message.headers.as_ref().unwrap()).starts_with("Subject: =?UTF-8?Q?Tere"));
    assert_eq!(message.parts["1"], b"Hello world");
    assert_eq!(message.parts["2"], b"AAECAw==");

    // reading with BODY.PEEK leaves the message unseen
    let flags = client
        .fetch(
            &uid.to_string(),
            true,
            &FetchQuery {
                flags: true,
                ..Default::default()
            },
        )
        .await
        .unwrap();
    assert!(!flags[0].flags.as_ref().unwrap().contains(&"\\Seen".to_string()));
}

#[tokio::test]
async fn search_keys_find_what_they_mean() {
    let kit = kit!(json!({}));
    let first = kit
        .server
        .add_message("INBOX", &rfc822("Invoice March", "pay this"), &["\\Seen"]);
    let second = kit
        .server
        .add_message("INBOX", &rfc822("Meeting", "agenda"), &["\\Flagged"]);
    let third = kit.server.add_message("INBOX", MULTIPART, &[]);
    let (mut client, _) = kit.connect().await;
    client.select("INBOX").await.unwrap();

    let search = |key: SearchKey| key;
    let cases = [
        (search(SearchKey::All), vec![first, second, third]),
        (SearchKey::Seen, vec![first]),
        (SearchKey::Unseen, vec![second, third]),
        (SearchKey::Flagged, vec![second]),
        (SearchKey::Subject("invoice".into()), vec![first]),
        (SearchKey::Body("agenda".into()), vec![second]),
        (SearchKey::Subject("täna".into()), vec![third]),
        (SearchKey::From("joul@example.com".into()), vec![third]),
        (
            SearchKey::Or(Box::new(SearchKey::Seen), Box::new(SearchKey::Flagged)),
            vec![first, second],
        ),
        (SearchKey::Not(Box::new(SearchKey::Seen)), vec![second, third]),
        (SearchKey::Uid(format!("{second}:*")), vec![second, third]),
        (SearchKey::SentSince(1_759_744_800), vec![first, second, third]),
        (SearchKey::SentBefore(1_759_744_800), vec![]),
        (SearchKey::Larger(400), vec![third]),
        (
            SearchKey::And(vec![
                SearchKey::Unseen,
                SearchKey::Not(Box::new(SearchKey::Subject("täna".into()))),
            ]),
            vec![second],
        ),
    ];
    for (key, expected) in cases {
        assert_eq!(client.search(&key, true).await.unwrap(), expected, "{key:?}");
    }
    assert_eq!(client.search(&SearchKey::All, false).await.unwrap(), vec![1, 2, 3]);
}

#[tokio::test]
async fn flag_changes_copies_and_moves_leave_the_server_as_reported() {
    for plugins in [Value::Null, json!(["UIDPLUS", "SPECIAL-USE"])] {
        let config = if plugins.is_null() {
            json!({})
        } else {
            json!({ "plugins": plugins })
        };
        let kit = kit!(config);
        let one = kit.server.add_message("INBOX", &rfc822("One", "1"), &[]);
        let two = kit.server.add_message("INBOX", &rfc822("Two", "2"), &[]);
        let (mut client, _) = kit.connect().await;
        client.select("INBOX").await.unwrap();

        client
            .store(&one.to_string(), true, StoreAction::Add, &["\\Seen", "\\Flagged"])
            .await
            .unwrap();
        client
            .store(&one.to_string(), true, StoreAction::Remove, &["\\Flagged"])
            .await
            .unwrap();
        let fetched = client
            .fetch(
                &one.to_string(),
                true,
                &FetchQuery {
                    flags: true,
                    ..Default::default()
                },
            )
            .await
            .unwrap();
        assert_eq!(flag_list(fetched[0].flags.as_ref().unwrap()), vec!["\\Seen"]);

        let copied = client.copy(&one.to_string(), true, "Archive").await.unwrap();
        assert!(copied.is_some(), "COPYUID");
        let moved = client.move_messages(&two.to_string(), true, "Trash").await.unwrap();
        assert!(moved.is_some(), "COPYUID of the move");

        let inbox = kit.server.messages("INBOX");
        let archive = kit.server.messages("Archive");
        let trash = kit.server.messages("Trash");
        let count = |v: &Value| v["messages"].as_array().or(v.as_array()).map_or(0, Vec::len);
        assert_eq!(
            (count(&inbox), count(&archive), count(&trash)),
            (1, 1, 1),
            "{inbox} {archive} {trash}"
        );
        assert_eq!(client.selected().unwrap().exists, 1);

        client
            .store("1:*", false, StoreAction::Add, &["\\Deleted"])
            .await
            .unwrap();
        client.expunge(Some(&one.to_string())).await.unwrap();
        assert_eq!(client.selected().unwrap().exists, 0);
    }
}

// ---- changes by others (imapflow server-changes-test.ts) ----

#[tokio::test(flavor = "multi_thread")]
async fn idle_reports_new_messages_flag_changes_and_expunges() {
    let kit = kit!(json!({}));
    let uid = kit.server.add_message("INBOX", &rfc822("Old", "old"), &[]);
    let (mut client, mut events) = kit.connect().await;
    client.select("INBOX").await.unwrap();

    let (stop, stopped) = tokio::sync::oneshot::channel::<()>();
    let server = &kit.server;
    let changes = async {
        tokio::task::block_in_place(|| server.add_message("INBOX", &rfc822("New", "new"), &[]));
        assert_eq!(
            wait_for(&mut events, |e| matches!(e, Event::Exists { .. })).await,
            Event::Exists { count: 2 }
        );
        tokio::task::block_in_place(|| server.set_flags("INBOX", &[uid], &["\\Flagged"], "add"));
        match wait_for(&mut events, |e| matches!(e, Event::Flags { .. })).await {
            Event::Flags { seq, flags, .. } => assert!(seq == 1 && flags.contains(&"\\Flagged".to_string())),
            other => panic!("{other:?}"),
        }
        tokio::task::block_in_place(|| server.expunge("INBOX", &[uid]));
        assert_eq!(
            wait_for(&mut events, |e| matches!(e, Event::Expunge { .. })).await,
            Event::Expunge { seq: 1 }
        );
        stop.send(()).unwrap();
    };
    let (idled, ()) = tokio::join!(client.idle(async { stopped.await.unwrap() }), changes);
    assert!(idled.unwrap(), "stopped by the caller");
    assert!(kit.sent("DONE"));
    assert_eq!(client.selected().unwrap().exists, 1);
    client.noop().await.unwrap();
}

#[tokio::test(flavor = "multi_thread")]
async fn without_idle_the_client_polls_with_noop() {
    let kit = kit!(json!({ "plugins": [] }));
    let (mut client, mut events) = kit.connect().await;
    client.select("INBOX").await.unwrap();
    let (stop, stopped) = tokio::sync::oneshot::channel::<()>();
    let server = &kit.server;
    let changes = async {
        tokio::task::block_in_place(|| server.add_message("INBOX", &rfc822("New", "new"), &[]));
        wait_for(&mut events, |e| matches!(e, Event::Exists { count: 1 })).await;
        stop.send(()).unwrap();
    };
    let (idled, ()) = tokio::join!(client.idle(async { stopped.await.unwrap() }), changes);
    assert!(idled.unwrap());
    assert!(kit.sent("NOOP") && !kit.sent("IDLE"));
}

// ---- servers that misbehave on purpose (imapflow faults-test.ts) ----

#[tokio::test]
async fn a_bye_greeting_fails_the_connection() {
    let kit = kit!(json!({ "script": { "on": "greeting", "send": "* BYE Too many connections\r\n", "close": true } }));
    let error = kit
        .connect_with(kit.config(Security::Plain, password()))
        .await
        .err()
        .expect("refused");
    assert!(
        matches!(&error, Error::Closed(Some(text)) if text.contains("Too many")),
        "{error:?}"
    );
}

#[tokio::test]
async fn a_greeting_that_never_comes_times_out() {
    let kit = kit!(json!({ "script": { "on": "greeting", "drop": true } }));
    let mut config = kit.config(Security::Plain, password());
    config.timeouts.greeting = Duration::from_millis(500);
    let error = kit.connect_with(config).await.err().expect("refused");
    assert!(matches!(error, Error::Timeout), "{error:?}");
}

#[tokio::test]
async fn a_greeting_split_into_single_octets_is_read() {
    let kit = kit!(
        json!({ "script": { "on": "greeting", "send": "* OK [CAPABILITY IMAP4rev1 IDLE] split greeting\r\n", "chunk": 1, "chunkDelay": 1 } })
    );
    let (mut client, _) = kit.connect().await;
    client.noop().await.unwrap();
}

#[tokio::test]
async fn bad_for_id_and_enable_does_not_stop_the_session() {
    let mut kit = kit!(json!({ "plugins": ["ID", "ENABLE", "CONDSTORE"], "script": [
        { "on": "command", "command": "ID", "send": "$TAG BAD ID not today\r\n" },
        { "on": "command", "command": "ENABLE", "send": "$TAG BAD ENABLE not today\r\n" }
    ] }));
    kit.allow_bad = true;
    let (mut client, _) = kit.connect().await;
    assert!(!client.is_enabled("CONDSTORE"));
    client.noop().await.unwrap();
}

#[tokio::test]
async fn a_refused_login_keeps_its_response_code_and_alerts_arrive() {
    let kit = kit!(
        json!({ "plugins": [], "script": { "on": "command", "command": "LOGIN", "send": "$TAG NO [UNAVAILABLE] Backend down\r\n" } })
    );
    match kit
        .connect_with(kit.config(Security::Plain, password()))
        .await
        .err()
        .expect("refused")
    {
        Error::AuthenticationFailed { code, text } => {
            assert_eq!((code.as_deref(), text.as_str()), (Some("UNAVAILABLE"), "Backend down"))
        }
        other => panic!("{other:?}"),
    }

    let kit = kit!(
        json!({ "script": { "on": "command", "command": "NOOP", "send": "* OK [ALERT] System shutdown in 10 minutes\r\n", "run": true } })
    );
    let (mut client, mut events) = kit.connect().await;
    client.noop().await.unwrap();
    assert_eq!(
        wait_for(&mut events, |e| matches!(e, Event::Alert(_))).await,
        Event::Alert("System shutdown in 10 minutes".into())
    );
}

#[tokio::test]
async fn a_select_refused_once_can_be_retried() {
    let kit = kit!(
        json!({ "script": { "on": "command", "command": "SELECT", "times": 1, "send": "$TAG NO [UNAVAILABLE] Try again later\r\n" } })
    );
    let (mut client, _) = kit.connect().await;
    match client.select("INBOX").await {
        Err(Error::Refused { code, .. }) => assert_eq!(code.as_deref(), Some("UNAVAILABLE")),
        other => panic!("{other:?}"),
    }
    assert!(client.selected().is_none());
    client.select("INBOX").await.unwrap();
}

#[tokio::test]
async fn an_unsolicited_bye_ends_the_session() {
    let kit = kit!(
        json!({ "script": { "on": "command", "command": "NOOP", "send": "* BYE Server shutting down\r\n", "close": true } })
    );
    let (mut client, mut events) = kit.connect().await;
    let error = client.noop().await.expect_err("closed");
    assert!(
        matches!(&error, Error::Closed(Some(text)) if text.contains("shutting down")),
        "{error:?}"
    );
    assert!(client.is_closed());
    assert_eq!(
        wait_for(&mut events, |e| matches!(e, Event::Closed(_))).await,
        Event::Closed(Some("Server shutting down".into()))
    );
    assert!(matches!(client.noop().await, Err(Error::Closed(_))));
}

#[tokio::test]
async fn a_session_with_every_extension_sends_no_bad() {
    let kit = kit!(json!({}));
    kit.server.add_message("INBOX", MULTIPART, &[]);
    let (mut client, _) = kit.connect().await;
    client.list().await.unwrap();
    client.status("INBOX").await.unwrap();
    client.select("INBOX").await.unwrap();
    let query = FetchQuery {
        flags: true,
        envelope: true,
        body_structure: true,
        internal_date: true,
        size: true,
        modseq: true,
        headers: Some(vec![]),
        parts: vec!["1".into(), "2.MIME".into()],
        source: true,
        changed_since: Some(1),
    };
    client.fetch("1:*", true, &query).await.unwrap();
    client.search(&SearchKey::Text("hello".into()), true).await.unwrap();
    client
        .store("1", false, StoreAction::Set, &["\\Answered"])
        .await
        .unwrap();
    client.logout().await.unwrap();
    assert!(kit.received("BYE"));
}
