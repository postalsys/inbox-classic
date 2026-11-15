//! Keys looked up for recipients, against a loopback server playing keys.openpgp.org and the domains' directories:
//! found and used, a miss not asked again for a day, the key server turned off, a changed key waiting, publishing.

use std::collections::HashMap;
use std::io::{Read, Write};
use std::net::TcpListener;
use std::sync::mpsc::{Receiver, channel};
use std::sync::{Arc, Mutex};
use std::time::Duration;

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
            let event = self.events.recv_timeout(Duration::from_secs(10)).expect("KeysFound");
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
    assert!(w.core.pgp_find_handle(&bob.fingerprint()).is_err());
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
        let event = w.events.recv_timeout(Duration::from_secs(10)).unwrap();
        if event == (Event::KeyPublished { request }) {
            break;
        }
    }
    let outcome = w.core.pgp_publish_result(request).unwrap();
    assert!(outcome.ok && outcome.text.contains("me@example.org"), "{outcome:?}");
}
