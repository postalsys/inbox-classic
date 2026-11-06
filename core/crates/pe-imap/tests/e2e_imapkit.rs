//! End-to-end sessions against ImapKit, our in-memory IMAP server (core/e2e), the way imapflow's
//! test/imapkit suites test imapflow. ImapKit answers client input that breaks the RFCs with BAD,
//! so every test also checks that the client sent nothing ImapKit refused, unless the test makes
//! the server send BAD on purpose.
//!
//! Skipped without Node.js and `npm ci` in core/e2e, unless PE_E2E_REQUIRED is set.

use std::sync::{Arc, Mutex};
use std::time::Duration;

use pe_imap::client::{Direction, Error, FetchQuery, SearchKey, StoreAction};
use pe_imap::{Client, Config, Credentials, ErrorKind, Event, Messages, SequenceSet, SpecialUse};
use pe_net::{Security, TlsFailureKind, Trust};
use pe_testkit::{ImapKit, PASSWORD, TOKEN, USER, password, rfc822, wait_for};
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
        let mut config = self.server.imap_config(security, credentials);
        let wire = self.wire.clone();
        config.wire_log = Some(Arc::new(move |direction, line| {
            wire.lock().unwrap().push((direction, line.to_string()))
        }));
        config
    }

    async fn connect(&self) -> (Client, UnboundedReceiver<Event>) {
        Client::connect(self.config(Security::Plain, password()))
            .await
            .expect("connect")
    }

    /// A connection that the server or the client refuses, with its error
    async fn refused(&self, config: Config) -> Error {
        match Client::connect(config).await {
            Ok(_) => panic!("connected"),
            Err(error) => error,
        }
    }

    fn sent(&self, needle: &str) -> bool {
        self.any(Direction::Client, needle)
    }

    fn received(&self, needle: &str) -> bool {
        self.any(Direction::Server, needle)
    }

    fn any(&self, direction: Direction, needle: &str) -> bool {
        self.wire
            .lock()
            .unwrap()
            .iter()
            .any(|(d, line)| *d == direction && line.contains(needle))
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

fn uids(set: &str) -> Messages {
    Messages::Uids(SequenceSet::parse(set).unwrap())
}

fn seqs(set: &str) -> Messages {
    Messages::Seqs(SequenceSet::parse(set).unwrap())
}

/// The ImapKit for a test, or a skipped test
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
    let wrong = Credentials::Password {
        user: USER.into(),
        password: "wrong".into(),
    };
    let error = kit.refused(kit.config(Security::Plain, wrong)).await;
    assert!(matches!(error, Error::AuthenticationFailed { .. }), "{error:?}");
    assert_eq!(error.kind(), ErrorKind::Authentication);
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
    let (mut client, _) = Client::connect(kit.config(Security::Plain, credentials)).await.unwrap();
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
        let (mut client, _) = Client::connect(kit.config(Security::Plain, token)).await.unwrap();
        assert!(kit.sent(&format!("AUTHENTICATE {mechanism}")), "{mechanism}");
        assert!(!kit.sent(TOKEN));
        client.noop().await.unwrap();

        // a wrong token gets an error challenge, answered as the mechanism wants, then NO
        let wrong = Credentials::OAuth2 {
            user: USER.into(),
            access_token: "wrong".into(),
        };
        let error = kit.refused(kit.config(Security::Plain, wrong)).await;
        assert!(
            matches!(error, Error::AuthenticationFailed { .. }),
            "{mechanism}: {error:?}"
        );
    }
}

#[tokio::test]
async fn starttls_upgrade_with_a_fresh_capability() {
    let kit = kit!(json!({ "plugins": ["STARTTLS", "AUTH-PLAIN", "ID"] }));
    let (mut client, _) = Client::connect(kit.config(Security::StartTls, password()))
        .await
        .unwrap();
    assert!(client.is_secure());
    let sent = kit.lines(Direction::Client);
    let starttls = sent.iter().position(|l| l.ends_with("STARTTLS")).unwrap();
    // CAPABILITY again right after the upgrade, and ID only over TLS
    assert!(sent[starttls + 1].ends_with("CAPABILITY"), "{sent:?}");
    assert!(sent.iter().position(|l| l.contains("ID (")).unwrap() > starttls);
    client.noop().await.unwrap();
}

#[tokio::test]
async fn required_starttls_fails_without_it() {
    let kit = kit!(json!({ "plugins": [] }));
    let error = kit.refused(kit.config(Security::StartTls, password())).await;
    assert!(matches!(error, Error::StartTlsUnavailable), "{error:?}");
    assert_eq!(error.kind(), ErrorKind::Security);
    assert!(!kit.sent("LOGIN"), "credentials never sent in plaintext");
}

#[tokio::test]
async fn logindisabled_before_starttls_login_after_it() {
    let kit = kit!(json!({ "plugins": ["STARTTLS", "LOGINDISABLED"] }));
    let (client, _) = Client::connect(kit.config(Security::StartTls, password()))
        .await
        .unwrap();
    assert!(client.is_secure() && !client.has_capability("LOGINDISABLED"));

    let error = kit.refused(kit.config(Security::Plain, password())).await;
    assert!(matches!(error, Error::NoAuthenticationMethod), "{error:?}");
}

#[tokio::test]
async fn implicit_tls() {
    let kit = kit!(json!({ "plugins": ["AUTH-PLAIN"] }));
    let (mut client, _) = Client::connect(kit.config(Security::Tls, password())).await.unwrap();
    assert!(client.is_secure());
    client.noop().await.unwrap();
}

#[tokio::test]
async fn certificates_that_are_not_trusted_are_refused_and_shown() {
    let kit = kit!(json!({}));
    for trust in [Trust::Platform, Trust::Pinned(vec![b"another certificate".to_vec()])] {
        let mut config = kit.config(Security::Tls, password());
        config.trust = trust;
        match kit.refused(config).await {
            Error::Net(pe_net::Error::Tls(failure)) => {
                assert_eq!(failure.kind, TlsFailureKind::Untrusted, "{}", failure.message);
                assert_eq!(failure.certificate.as_deref(), Some(kit.server.cert.as_slice()));
            }
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
    let error = kit.refused(kit.config(Security::StartTls, password())).await;
    assert!(matches!(error, Error::StartTlsInjection), "{error:?}");
}

// ---- mailboxes (imapflow storage-state and extensions tests) ----

#[tokio::test]
async fn lists_special_use_folders_first() {
    let kit = kit!(json!({}));
    let (mut client, _) = kit.connect().await;
    let list = client.list().await.unwrap();
    let summary: Vec<(&str, Option<SpecialUse>)> = list
        .iter()
        .map(|m| (m.path.as_str(), m.special_use.map(|(u, _)| u)))
        .collect();
    assert_eq!(
        summary,
        vec![
            ("INBOX", Some(SpecialUse::Inbox)),
            ("Sent", Some(SpecialUse::Sent)),
            ("Drafts", Some(SpecialUse::Drafts)),
            ("Archive", Some(SpecialUse::Archive)),
            ("Junk", Some(SpecialUse::Junk)),
            ("Trash", Some(SpecialUse::Trash)),
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
    let find = |path: &str| {
        list.iter()
            .find(|m| m.path == path)
            .unwrap()
            .special_use
            .map(|(u, _)| u)
    };
    assert_eq!(find("Sent Items"), Some(SpecialUse::Sent));
    assert_eq!(find("Deleted Items"), Some(SpecialUse::Trash));
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

    // INBOX in any case is INBOX
    let selected = client.select("inbox").await.unwrap();
    assert_eq!(selected.path, "INBOX");
    assert_eq!(selected.exists, 2);
    assert!(!selected.read_only);
    assert_eq!(selected.uid_next, Some(3));
    assert!(selected.flags.iter().any(|f| f == "\\Seen"));
    assert!(selected.highest_modseq.is_some(), "CONDSTORE is enabled");

    let examined = client.examine("Sent").await.unwrap();
    assert!(examined.read_only);
    assert_eq!(client.selected().unwrap().path, "Sent");
    // EXAMINE refuses flag changes
    assert!(
        client
            .store(&Messages::Uids(SequenceSet::all()), StoreAction::Add, &["\\Seen"])
            .await
            .is_err()
    );
    client.unselect().await.unwrap();
    assert!(client.selected().is_none());
    assert!(matches!(
        client.fetch(&seqs("1"), &FetchQuery::default()).await,
        Err(Error::NoMailboxSelected)
    ));
}

// ---- messages ----

const MULTIPART: &str = "From: =?UTF-8?Q?J=C3=B5ul?= <joul@example.com>\r\nTo: Receiver <receiver@example.com>, group: a@b.c, d@e.f;\r\nSubject: =?UTF-8?Q?Tere_t=C3=A4na?=\r\nMessage-ID: <multi@example.com>\r\nDate: Mon, 6 Oct 2025 10:00:00 +0000\r\nMIME-Version: 1.0\r\nContent-Type: multipart/mixed; boundary=\"b1\"\r\n\r\n--b1\r\nContent-Type: text/plain; charset=utf-8\r\n\r\nHello world\r\n--b1\r\nContent-Type: application/octet-stream; name=\"=?UTF-8?Q?=C3=B5.bin?=\"\r\nContent-Disposition: attachment; filename*=utf-8''%C3%B5.bin\r\nContent-Transfer-Encoding: base64\r\n\r\nAAECAw==\r\n--b1--\r\n";

fn everything() -> FetchQuery {
    FetchQuery {
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
    }
}

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

    let messages = client.fetch(&Messages::uid(uid), &everything()).await.unwrap();
    assert_eq!(messages.len(), 1);
    let message = &messages[0];
    assert_eq!(message.uid, Some(uid));
    assert_eq!(flag_list(message.flags.as_ref().unwrap()), vec!["$Label1", "\\Flagged"]);
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
            &Messages::uid(uid),
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

    let not = |key| SearchKey::Not(Box::new(key));
    let cases = [
        (SearchKey::All, vec![first, second, third]),
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
        (not(SearchKey::Seen), vec![second, third]),
        (
            SearchKey::Uid(SequenceSet::parse(&format!("{second}:*")).unwrap()),
            vec![second, third],
        ),
        (SearchKey::SentSince(1_759_744_800), vec![first, second, third]),
        (SearchKey::SentBefore(1_759_744_800), vec![]),
        (SearchKey::Larger(400), vec![third]),
        (
            SearchKey::And(vec![SearchKey::Unseen, not(SearchKey::Subject("täna".into()))]),
            vec![second],
        ),
    ];
    for (key, expected) in cases {
        assert_eq!(client.search(&key).await.unwrap(), expected, "{key:?}");
    }
}

#[tokio::test]
async fn flag_changes_copies_and_moves_leave_the_server_as_reported() {
    // every extension, then a server without MOVE: COPY, STORE and UID EXPUNGE instead
    for config in [json!({}), json!({ "plugins": ["UIDPLUS", "SPECIAL-USE"] })] {
        let kit = kit!(config);
        let one = kit.server.add_message("INBOX", &rfc822("One", "1"), &[]);
        let two = kit.server.add_message("INBOX", &rfc822("Two", "2"), &[]);
        let (mut client, _) = kit.connect().await;
        client.select("INBOX").await.unwrap();

        client
            .store(&Messages::uid(one), StoreAction::Add, &["\\Seen", "\\Flagged"])
            .await
            .unwrap();
        client
            .store(&Messages::uid(one), StoreAction::Remove, &["\\Flagged"])
            .await
            .unwrap();
        let fetched = client
            .fetch(
                &Messages::uid(one),
                &FetchQuery {
                    flags: true,
                    ..Default::default()
                },
            )
            .await
            .unwrap();
        assert_eq!(flag_list(fetched[0].flags.as_ref().unwrap()), vec!["\\Seen"]);
        // silently: the change is made, the server tells nothing back for it
        client
            .store_silent(&Messages::uid(one), StoreAction::Add, &["$Junk"])
            .await
            .unwrap();
        assert!(kit.server.flags("INBOX", one).iter().any(|f| f == "$Junk"));

        let copied = client
            .copy(&Messages::uid(one), "Archive")
            .await
            .unwrap()
            .expect("COPYUID");
        assert_eq!(copied.source.as_str(), one.to_string());
        let moved = client.move_messages(&Messages::uid(two), "Trash").await.unwrap();
        assert!(moved.is_some(), "COPYUID of the move");

        let counts = ["INBOX", "Archive", "Trash"].map(|mailbox| kit.server.messages(mailbox).len());
        assert_eq!(counts, [1, 1, 1]);
        assert_eq!(client.selected().unwrap().exists, 1);

        client
            .store(&seqs("1:*"), StoreAction::Add, &["\\Deleted"])
            .await
            .unwrap();
        client
            .expunge(Some(&SequenceSet::parse(&one.to_string()).unwrap()))
            .await
            .unwrap();
        assert_eq!(client.selected().unwrap().exists, 0);
    }
}

#[tokio::test]
async fn expunging_by_uid_needs_uidplus() {
    let kit = kit!(json!({ "plugins": [] }));
    let (mut client, _) = kit.connect().await;
    client.select("INBOX").await.unwrap();
    let error = client.expunge(Some(&SequenceSet::all())).await.expect_err("refused");
    assert!(matches!(error, Error::Unsupported("UIDPLUS")), "{error:?}");
    assert!(!kit.sent("EXPUNGE"));
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
    let inbox = || "INBOX".to_string();
    let changes = async {
        tokio::task::block_in_place(|| server.add_message("INBOX", &rfc822("New", "new"), &[]));
        let exists = wait_for(&mut events, |e| matches!(e, Event::Exists { .. })).await;
        assert_eq!(
            exists,
            Event::Exists {
                mailbox: inbox(),
                count: 2
            }
        );
        tokio::task::block_in_place(|| server.set_flags("INBOX", &[uid], &["\\Flagged"], "add"));
        match wait_for(&mut events, |e| matches!(e, Event::Flags { .. })).await {
            Event::Flags {
                mailbox, seq, flags, ..
            } => {
                assert_eq!((mailbox.as_str(), seq), ("INBOX", 1));
                assert!(flags.contains(&"\\Flagged".to_string()));
            }
            other => panic!("{other:?}"),
        }
        tokio::task::block_in_place(|| server.expunge("INBOX", &[uid]));
        let expunge = wait_for(&mut events, |e| matches!(e, Event::Expunge { .. })).await;
        assert_eq!(
            expunge,
            Event::Expunge {
                mailbox: inbox(),
                seq: 1
            }
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
        wait_for(&mut events, |e| matches!(e, Event::Exists { count: 1, .. })).await;
        stop.send(()).unwrap();
    };
    let (idled, ()) = tokio::join!(client.idle(async { stopped.await.unwrap() }), changes);
    assert!(idled.unwrap());
    assert!(kit.sent("NOOP") && !kit.sent("IDLE"));
}

#[tokio::test]
async fn a_flag_change_of_another_message_during_fetch_is_an_event() {
    // the server reports a flag change of message 2 inside the answer to a FETCH of message 1
    let kit = kit!(json!({ "script": {
        "on": "command", "command": "UID FETCH", "send": "* 2 FETCH (UID 2 FLAGS (\\Seen))\r\n", "run": true
    } }));
    kit.server.add_message("INBOX", &rfc822("One", "1"), &[]);
    kit.server.add_message("INBOX", &rfc822("Two", "2"), &[]);
    let (mut client, mut events) = kit.connect().await;
    client.select("INBOX").await.unwrap();
    let fetched = client
        .fetch(
            &Messages::uid(1),
            &FetchQuery {
                flags: true,
                ..Default::default()
            },
        )
        .await
        .unwrap();
    assert_eq!(fetched.iter().map(|m| m.uid).collect::<Vec<_>>(), vec![Some(1)]);
    match wait_for(&mut events, |e| matches!(e, Event::Flags { .. })).await {
        Event::Flags { uid, flags, .. } => assert_eq!((uid, flags), (Some(2), vec!["\\Seen".to_string()])),
        other => panic!("{other:?}"),
    }
}

// ---- servers that misbehave on purpose (imapflow faults-test.ts) ----

#[tokio::test]
async fn a_bye_greeting_fails_the_connection() {
    let kit = kit!(json!({ "script": { "on": "greeting", "send": "* BYE Too many connections\r\n", "close": true } }));
    let error = kit.refused(kit.config(Security::Plain, password())).await;
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
    let error = kit.refused(config).await;
    assert!(matches!(error, Error::Timeout), "{error:?}");
    assert_eq!(error.kind(), ErrorKind::Network);
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
    match kit.refused(kit.config(Security::Plain, password())).await {
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
    let alert = wait_for(&mut events, |e| matches!(e, Event::Alert(_))).await;
    assert_eq!(alert, Event::Alert("System shutdown in 10 minutes".into()));
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
    let closed = wait_for(&mut events, |e| matches!(e, Event::Closed(_))).await;
    assert_eq!(closed, Event::Closed(Some("Server shutting down".into())));
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
        headers: Some(vec![]),
        parts: vec!["1".into(), "2.MIME".into()],
        changed_since: Some(1),
        ..everything()
    };
    client.fetch(&uids("1:*"), &query).await.unwrap();
    client.search(&SearchKey::Text("hello".into())).await.unwrap();
    client
        .store(&seqs("1"), StoreAction::Set, &["\\Answered"])
        .await
        .unwrap();
    client.logout().await.unwrap();
    assert!(kit.received("BYE"));
}

// RFC 9738: a server with MESSAGELIMIT works on the highest UIDs only, the client asks again for
// the rest
#[tokio::test]
async fn message_limit_is_followed() {
    let kit = kit!(json!({ "messageLimit": 5 }));
    let added: Vec<u64> = (0..12)
        .map(|i| kit.server.add_message("INBOX", &rfc822(&format!("M{i}"), "x"), &[]))
        .collect();
    let (mut client, _) = kit.connect().await;
    assert!(client.has_capability("MESSAGELIMIT=5"));
    client.select("INBOX").await.unwrap();
    let query = FetchQuery {
        flags: true,
        ..Default::default()
    };
    let mut fetched: Vec<u64> = client
        .fetch(&Messages::Uids(SequenceSet::all()), &query)
        .await
        .unwrap()
        .iter()
        .filter_map(|m| m.uid)
        .collect();
    fetched.sort_unstable();
    assert_eq!(fetched, added);
    assert_eq!(client.search(&SearchKey::All).await.unwrap(), added);
    assert_eq!(client.search(&SearchKey::Unseen).await.unwrap(), added);
    // the server said so: the commands were cut, and asked again
    assert!(kit.received("[MESSAGELIMIT 5 "));
}
