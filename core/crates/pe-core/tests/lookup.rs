//! Keys looked up for recipients, against a loopback server playing keys.openpgp.org and the domains' directories:
//! found and used, a miss not asked again for a day, the key server turned off, a changed key waiting, publishing.

use std::collections::HashMap;
use std::io::{Read, Write};
use std::net::TcpListener;
use std::sync::mpsc::{Receiver, channel};
use std::sync::{Arc, Mutex};

use pe_core::keys::KeySource;
use pe_core::{Core, Event, Options, PasswordStore};

fn now() -> i64 {
    std::time::SystemTime::now()
        .duration_since(std::time::UNIX_EPOCH)
        .unwrap()
        .as_secs() as i64
}

/// What the server answers each path with: a status and a body
type Routes = Arc<Mutex<HashMap<String, (u16, Vec<u8>)>>>;

/// A plain HTTP server on a thread: each path (without its query) answered with a status and a body
fn serve(routes: Routes, asked: Arc<Mutex<Vec<String>>>) -> String {
    let listener = TcpListener::bind("127.0.0.1:0").unwrap();
    let base = format!("http://{}", listener.local_addr().unwrap());
    std::thread::spawn(move || {
        for stream in listener.incoming() {
            let Ok(mut stream) = stream else { continue };
            let mut request = vec![0u8; 65536];
            let n = stream.read(&mut request).unwrap_or(0);
            let text = String::from_utf8_lossy(&request[..n]).into_owned();
            let path = text
                .lines()
                .next()
                .unwrap_or("")
                .split(' ')
                .nth(1)
                .unwrap_or("")
                .to_string();
            asked.lock().unwrap().push(path.clone());
            let bare = path.split('?').next().unwrap_or("").to_string();
            let (status, body) = routes
                .lock()
                .unwrap()
                .get(&bare)
                .cloned()
                .unwrap_or((404, b"no".to_vec()));
            let head = format!(
                "HTTP/1.1 {status} X\r\nContent-Length: {}\r\nConnection: close\r\n\r\n",
                body.len()
            );
            let _ = stream.write_all(head.as_bytes());
            let _ = stream.write_all(&body);
        }
    });
    base
}

struct World {
    core: Core,
    events: Receiver<Event>,
    routes: Routes,
    asked: Arc<Mutex<Vec<String>>>,
    _dir: pe_testkit::TempDir,
}

fn world(name: &str) -> World {
    let routes = Arc::new(Mutex::new(HashMap::new()));
    let asked = Arc::new(Mutex::new(Vec::new()));
    let base = serve(routes.clone(), asked.clone());
    let dir = pe_testkit::TempDir::new(name);
    let (sender, events) = channel();
    let options = Options {
        passwords: PasswordStore::Memory,
        pgp_servers: Some(pe_keys::Servers {
            keyserver: base.clone(),
            wkd_base: Some(base),
        }),
        ..Default::default()
    };
    let core = Core::open_with(dir.path().join("store.db"), options, move |event| {
        let _ = sender.send(event);
    })
    .unwrap();
    World {
        core,
        events,
        routes,
        asked,
        _dir: dir,
    }
}

impl World {
    fn result(&self, request: u64) -> pe_core::FindOutcome {
        loop {
            let event = self.events.recv_timeout(pe_testkit::patience()).expect("KeysFound");
            if event == (Event::KeysFound { request }) {
                return self.core.pgp_find_result(request).unwrap();
            }
        }
    }
}

#[test]
fn found_used_and_a_miss_remembered() {
    let w = world("lookup-found");
    let bob = pe_pgp::generate("Bob", &["bob@example.org".into()], now() - 60).unwrap();
    w.routes.lock().unwrap().insert(
        "/vks/v1/by-email/bob%40example.org".into(),
        (200, bob.cert().to_bytes()),
    );
    let request = w
        .core
        .pgp_find(&["Bob@Example.org".into(), "nobody@example.org".into()])
        .unwrap()
        .unwrap();
    let outcome = w.result(request);
    assert_eq!(
        outcome.addresses,
        [
            ("bob@example.org".to_string(), true),
            ("nobody@example.org".to_string(), false)
        ]
    );
    assert!(
        outcome.text.contains("bob@example.org") && outcome.text.contains("nobody@example.org"),
        "{}",
        outcome.text
    );
    assert_eq!(
        w.core.pgp_peer("bob@example.org").unwrap().in_use.unwrap(),
        bob.fingerprint()
    );
    // asked again: Bob has a key, the miss is remembered for a day, so nothing is asked
    let before = w.asked.lock().unwrap().len();
    assert_eq!(
        w.core
            .pgp_find(&["bob@example.org".into(), "nobody@example.org".into()])
            .unwrap(),
        None
    );
    assert_eq!(w.asked.lock().unwrap().len(), before);
}

#[test]
fn own_addresses_are_never_asked_about() {
    let w = world("lookup-own");
    let store = pe_store::Store::open(w._dir.path().join("store.db")).unwrap();
    let settings = pe_store::AccountSettings {
        email: "me@example.org".into(),
        ..Default::default()
    };
    store.add_account(&settings).unwrap();
    drop(store);
    assert_eq!(w.core.pgp_find(&["Me@Example.org".into()]).unwrap(), None);
    assert!(w.asked.lock().unwrap().is_empty());
}

#[test]
fn the_key_server_turned_off() {
    let w = world("lookup-off");
    let bob = pe_pgp::generate("Bob", &["bob@example.org".into()], now() - 60).unwrap();
    w.routes.lock().unwrap().insert(
        "/vks/v1/by-email/bob%40example.org".into(),
        (200, bob.cert().to_bytes()),
    );
    w.core.set_pgp_keyserver(false).unwrap();
    assert!(!w.core.pgp_keyserver().unwrap());
    let request = w.core.pgp_find(&["bob@example.org".into()]).unwrap().unwrap();
    assert_eq!(w.result(request).addresses, [("bob@example.org".to_string(), false)]);
    assert!(w.asked.lock().unwrap().iter().all(|path| !path.contains("/vks/")));
    // nor by fingerprint, for a signature's unknown key
    // refused, naming where the switch is as the window names it
    match w.core.pgp_find_handle(&bob.fingerprint()) {
        Err(pe_core::Error::Unavailable(why)) => {
            assert!(why.contains("keys.openpgp.org") && why.contains("Reading"), "{why}");
            assert!(!why.contains("{"), "{why}");
        }
        other => panic!("{other:?}"),
    }
    assert!(w.asked.lock().unwrap().iter().all(|path| !path.contains("/vks/")));
}

#[test]
fn a_different_key_found_waits() {
    let w = world("lookup-changed");
    let bob = pe_pgp::generate("Bob", &["bob@example.org".into()], now() - 60).unwrap();
    let other = pe_pgp::generate("Bob", &["bob@example.org".into()], now() - 60).unwrap();
    w.core
        .pgp_import(bob.cert().armored().as_bytes(), None, KeySource::Paste)
        .unwrap();
    w.routes.lock().unwrap().insert(
        format!("/vks/v1/by-fingerprint/{}", other.fingerprint()),
        (200, other.cert().to_bytes()),
    );
    let request = w.core.pgp_find_handle(&other.fingerprint()).unwrap();
    let outcome = w.result(request);
    assert!(outcome.text.contains("waits"), "{}", outcome.text);
    let peer = w.core.pgp_peer("bob@example.org").unwrap();
    assert_eq!(
        (peer.in_use.unwrap(), peer.pending.unwrap()),
        (bob.fingerprint(), other.fingerprint())
    );
}

#[test]
fn publishing() {
    let w = world("lookup-publish");
    let store_dir = pe_testkit::TempDir::new("lookup-publish-own");
    let _ = store_dir;
    let me = pe_pgp::generate("Me", &["me@example.org".into()], now() - 60).unwrap();
    let backup = me.backup("passphrase!").unwrap();
    w.core
        .pgp_import(backup.as_bytes(), Some("passphrase!"), KeySource::File)
        .unwrap();
    w.routes.lock().unwrap().insert(
        "/vks/v1/upload".into(),
        (
            200,
            br#"{"key_fpr":"X","token":"t","status":{"me@example.org":"unpublished"}}"#.to_vec(),
        ),
    );
    w.routes.lock().unwrap().insert(
        "/vks/v1/request-verify".into(),
        (
            200,
            br#"{"key_fpr":"X","token":"t","status":{"me@example.org":"pending"}}"#.to_vec(),
        ),
    );
    let request = w.core.pgp_publish(&me.fingerprint()).unwrap();
    loop {
        let event = w.events.recv_timeout(pe_testkit::patience()).unwrap();
        if event == (Event::KeyPublished { request }) {
            break;
        }
    }
    let outcome = w.core.pgp_publish_result(request).unwrap();
    assert!(outcome.ok && outcome.text.contains("me@example.org"), "{outcome:?}");
    // taken once
    assert_eq!(w.core.pgp_publish_result(request), None);
    let asked = w.asked.lock().unwrap().clone();
    assert_eq!(asked, ["/vks/v1/upload", "/vks/v1/request-verify"]);

    // the server refuses: said, not published
    w.routes
        .lock()
        .unwrap()
        .insert("/vks/v1/upload".into(), (500, b"broken".to_vec()));
    let request = w.core.pgp_publish(&me.fingerprint()).unwrap();
    loop {
        let event = w.events.recv_timeout(pe_testkit::patience()).unwrap();
        if event == (Event::KeyPublished { request }) {
            break;
        }
    }
    let outcome = w.core.pgp_publish_result(request).unwrap();
    assert!(!outcome.ok && !outcome.text.is_empty(), "{outcome:?}");
    // only an own key is published
    let bob = pe_pgp::generate("Bob", &["bob@example.org".into()], now() - 60).unwrap();
    w.core
        .pgp_import(bob.cert().armored().as_bytes(), None, KeySource::Paste)
        .unwrap();
    assert!(w.core.pgp_publish(&bob.fingerprint()).is_err());
    assert!(w.core.pgp_publish("0123456789ABCDEF0123456789ABCDEF01234567").is_err());
}

/// A message from `from` signed by `key`, written where `file_view` reads it
fn signed_file(w: &World, from: &str, key: &pe_pgp::SecretKey) -> std::path::PathBuf {
    let content = "Content-Type: text/plain; charset=utf-8\r\n\r\nHello";
    let signature = pe_pgp::sign_detached(content.as_bytes(), key, now()).unwrap();
    let raw = format!(
        "From: {from}\r\nTo: me@example.org\r\nSubject: Signed\r\nDate: Sun, 15 Nov 2026 10:00:00 +0000\r\n\
         MIME-Version: 1.0\r\nContent-Type: multipart/signed; micalg={}; \
         protocol=\"application/pgp-signature\"; boundary=\"s\"\r\n\r\n--s\r\n{content}\r\n--s\r\n\
         Content-Type: application/pgp-signature\r\n\r\n{}\r\n--s--\r\n",
        signature.micalg, signature.signature
    );
    let path = w._dir.path().join("signed.eml");
    std::fs::write(&path, raw).unwrap();
    path
}

/// The handle Find Key beside the only part's label asks for, from the page's own link
fn find_key_of(view: &pe_core::MessageView) -> Option<String> {
    let part = view.protection.as_ref().unwrap().parts[0].find_key.clone();
    let start = view.document.find(pe_html::FIND_KEY_LINK);
    assert_eq!(part.is_some(), start.is_some(), "{}", view.document);
    let link = &view.document[start?..];
    let link = &link[..link.find('"').unwrap()];
    assert_eq!(pe_html::find_key_link(link), part);
    part
}

#[test]
fn find_key_on_a_signature_by_an_unknown_key() {
    let w = world("lookup-find-key");
    let bob = pe_pgp::generate("Bob", &["bob@example.org".into()], now() - 60).unwrap();
    for handle in [bob.fingerprint(), bob.cert().key_id()] {
        let kind = if handle.len() == 16 {
            "by-keyid"
        } else {
            "by-fingerprint"
        };
        w.routes
            .lock()
            .unwrap()
            .insert(format!("/vks/v1/{kind}/{handle}"), (200, bob.cert().to_bytes()));
    }
    let path = signed_file(&w, "bob@example.org", &bob);
    let view = w.core.file_view(&path, false).unwrap();
    let protection = view.protection.as_ref().unwrap();
    assert_eq!(protection.tone, pe_core::protect::Tone::Neutral);
    let handle = find_key_of(&view).expect("Find Key");
    assert!(bob.cert().handles().contains(&handle), "{handle}");

    // with lookups on keys.openpgp.org off, no Find Key
    w.core.set_pgp_keyserver(false).unwrap();
    assert_eq!(find_key_of(&w.core.file_view(&path, false).unwrap()), None);
    w.core.set_pgp_keyserver(true).unwrap();

    let request = w.core.pgp_find_handle(&handle).unwrap();
    let outcome = w.result(request);
    assert!(outcome.text.contains("bob@example.org"), "{}", outcome.text);
    // the view built again: the signature is Bob's now, and Find Key is gone
    let view = w.core.file_view(&path, false).unwrap();
    let part = &view.protection.as_ref().unwrap().parts[0];
    assert_eq!(part.tone, pe_core::protect::Tone::Good, "{}", part.label);
    assert!(part.label.contains("bob@example.org"), "{}", part.label);
    assert_eq!(find_key_of(&view), None);
}

#[test]
fn find_key_takes_only_a_fingerprint_or_key_id() {
    let w = world("lookup-find-key-strict");
    for bad in [
        "",
        "../../upload",
        "0123456789ABCDE",
        "0123456789ABCDEFG",
        "0123456789ABCDEF?x",
        "ZZ23456789ABCDEF",
    ] {
        assert!(w.core.pgp_find_handle(bad).is_err(), "{bad}");
    }
    assert!(w.asked.lock().unwrap().is_empty());
    // a key id in lower case is asked in upper case
    let request = w.core.pgp_find_handle("0123456789abcdef").unwrap();
    w.result(request);
    assert_eq!(*w.asked.lock().unwrap(), ["/vks/v1/by-keyid/0123456789ABCDEF"]);
}

#[test]
fn find_key_for_a_contact_and_the_book_marks() {
    let w = world("lookup-contact");
    let bob = pe_pgp::generate("Bob", &["bob@example.org".into()], now() - 60).unwrap();
    w.routes.lock().unwrap().insert(
        "/vks/v1/by-email/bob%40example.org".into(),
        (200, bob.cert().to_bytes()),
    );
    let card = w
        .core
        .save_card(&pe_store::Card {
            name: "Bob".into(),
            addresses: vec!["Bob@Example.org".into(), "bob@work.example".into()],
            ..Default::default()
        })
        .unwrap();
    let other = w
        .core
        .save_card(&pe_store::Card {
            name: "Carol".into(),
            addresses: vec!["carol@example.org".into()],
            ..Default::default()
        })
        .unwrap();
    let marks = |w: &World| -> Vec<(i64, bool, bool)> {
        let mut rows: Vec<_> = w
            .core
            .card_rows("")
            .unwrap()
            .iter()
            .map(|row| (row.card, row.has_key, row.key_verified))
            .collect();
        rows.sort();
        rows
    };
    assert_eq!(marks(&w), [(card, false, false), (other, false, false)]);

    let request = w.core.contact_find_keys(card).unwrap().unwrap();
    let outcome = w.result(request);
    assert_eq!(
        outcome.addresses,
        [
            ("bob@example.org".to_string(), true),
            ("bob@work.example".to_string(), false)
        ]
    );
    // each domain's directory was asked first, then the key server
    let asked = w.asked.lock().unwrap().clone();
    assert!(
        asked.iter().any(|path| path.contains("/.well-known/openpgpkey/")),
        "{asked:?}"
    );
    assert_eq!(
        w.core.pgp_peer("bob@example.org").unwrap().in_use.unwrap(),
        bob.fingerprint()
    );
    // asked again at once: the key server allows one lookup a minute, Bob's key is there
    assert_eq!(w.core.contact_find_keys(card).unwrap(), None);
    assert!(w.core.contact_find_keys(0).is_err());

    assert_eq!(marks(&w), [(card, true, false), (other, false, false)]);
    w.core.pgp_set_key_verified(&bob.fingerprint(), true).unwrap();
    assert_eq!(marks(&w), [(card, true, true), (other, false, false)]);
}
