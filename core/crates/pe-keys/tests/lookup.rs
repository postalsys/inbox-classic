//! Lookups against a loopback server that plays a Web Key Directory and keys.openpgp.org: found, not found, too many
//! requests, down, too large, a redirect, a key without the address asked for, a key with other user ids, publishing.

use std::collections::HashMap;
use std::sync::{Arc, Mutex};

use pe_keys::{Found, Servers, Source, by_fingerprint, find, publish, wkd};
use tokio::io::{AsyncReadExt, AsyncWriteExt};
use tokio::net::TcpListener;

fn now() -> i64 {
    std::time::SystemTime::now()
        .duration_since(std::time::UNIX_EPOCH)
        .unwrap()
        .as_secs() as i64
}

/// A server answering each path (without its query) with a status and a body; what it was asked, kept
struct Server {
    base: String,
    asked: Arc<Mutex<Vec<String>>>,
}

async fn serve(routes: HashMap<String, (u16, Vec<u8>)>) -> Server {
    let listener = TcpListener::bind("127.0.0.1:0").await.unwrap();
    let base = format!("http://{}", listener.local_addr().unwrap());
    let asked = Arc::new(Mutex::new(Vec::new()));
    let log = asked.clone();
    tokio::spawn(async move {
        loop {
            let Ok((mut stream, _)) = listener.accept().await else {
                return;
            };
            let mut request = vec![0u8; 65536];
            let n = stream.read(&mut request).await.unwrap_or(0);
            let text = String::from_utf8_lossy(&request[..n]).into_owned();
            let line = text.lines().next().unwrap_or("").to_string();
            let path = line.split(' ').nth(1).unwrap_or("").to_string();
            log.lock()
                .unwrap()
                .push(format!("{} {}", line.split(' ').next().unwrap_or(""), path));
            let bare = path.split('?').next().unwrap_or("").to_string();
            let (status, body) = routes.get(&bare).cloned().unwrap_or((404, b"not found".to_vec()));
            let location = if status == 302 {
                "Location: https://elsewhere.example/\r\n"
            } else {
                ""
            };
            let head = format!(
                "HTTP/1.1 {status} X\r\n{location}Content-Length: {}\r\nConnection: close\r\n\r\n",
                body.len()
            );
            let _ = stream.write_all(head.as_bytes()).await;
            let _ = stream.write_all(&body).await;
        }
    });
    Server { base, asked }
}

fn key(address: &str) -> pe_pgp::SecretKey {
    pe_pgp::generate("Someone", &[address.to_string()], now() - 60).unwrap()
}

fn wkd_path(kind: &str, address: &str) -> String {
    let (local, domain) = address.split_once('@').unwrap();
    let hash = pe_keys::wkd_hash(local);
    match kind {
        "advanced" => format!("/advanced/.well-known/openpgpkey/{domain}/hu/{hash}"),
        _ => format!("/direct/.well-known/openpgpkey/hu/{hash}"),
    }
}

fn servers(base: &str) -> Servers {
    Servers {
        keyserver: base.to_string(),
        wkd_base: Some(base.to_string()),
    }
}

#[tokio::test]
async fn found_in_the_web_key_directory_first() {
    let bob = key("bob@example.org");
    let mut routes = HashMap::new();
    routes.insert(wkd_path("advanced", "bob@example.org"), (200, bob.cert().to_bytes()));
    routes.insert(
        "/vks/v1/by-email/bob%40example.org".into(),
        (200, bob.cert().to_bytes()),
    );
    let server = serve(routes).await;
    match find("bob@example.org", &servers(&server.base), true, now()).await {
        Found::Key(bytes, Source::Wkd) => {
            let cert = pe_pgp::read_certs(&bytes).unwrap().remove(0);
            assert_eq!(cert.fingerprint(), bob.fingerprint());
        }
        other => panic!("{other:?}"),
    }
    // the key server was not asked: the domain's own directory answered
    assert!(
        server
            .asked
            .lock()
            .unwrap()
            .iter()
            .all(|asked| !asked.contains("/vks/"))
    );
}

#[tokio::test]
async fn then_the_key_server() {
    let bob = key("bob@example.org");
    let mut routes = HashMap::new();
    routes.insert(
        "/vks/v1/by-email/bob%40example.org".into(),
        (200, bob.cert().armored().into_bytes()),
    );
    let server = serve(routes).await;
    assert!(matches!(
        find("bob@example.org", &servers(&server.base), true, now()).await,
        Found::Key(_, Source::Keyserver)
    ));
    // with the key server turned off, not found
    assert_eq!(
        find("bob@example.org", &servers(&server.base), false, now()).await,
        Found::NotFound
    );
    assert!(
        server
            .asked
            .lock()
            .unwrap()
            .iter()
            .filter(|asked| asked.contains("/vks/"))
            .count()
            == 1
    );
}

#[tokio::test]
async fn a_key_without_the_address_is_none() {
    let other = key("someone-else@example.org");
    let mut routes = HashMap::new();
    routes.insert(wkd_path("advanced", "bob@example.org"), (200, other.cert().to_bytes()));
    routes.insert(
        "/vks/v1/by-email/bob%40example.org".into(),
        (200, other.cert().to_bytes()),
    );
    let server = serve(routes).await;
    assert_eq!(
        find("bob@example.org", &servers(&server.base), true, now()).await,
        Found::NotFound
    );
}

#[tokio::test]
async fn other_user_ids_are_dropped() {
    let bob = pe_pgp::generate(
        "Bob",
        &["bob@example.org".into(), "bob@private.example".into()],
        now() - 60,
    )
    .unwrap();
    let mut routes = HashMap::new();
    routes.insert(wkd_path("advanced", "bob@example.org"), (200, bob.cert().to_bytes()));
    let server = serve(routes).await;
    let Found::Key(bytes, _) = wkd("bob@example.org", &servers(&server.base), now()).await else {
        panic!()
    };
    let cert = pe_pgp::read_certs(&bytes).unwrap().remove(0);
    assert_eq!(cert.addresses(now()), ["bob@example.org"]);
}

#[tokio::test]
async fn busy_down_and_odd_answers() {
    let mut routes = HashMap::new();
    routes.insert(
        "/vks/v1/by-email/busy%40example.org".into(),
        (429, b"slow down".to_vec()),
    );
    routes.insert(
        "/vks/v1/by-email/down%40example.org".into(),
        (503, b"maintenance".to_vec()),
    );
    routes.insert("/vks/v1/by-email/moved%40example.org".into(), (302, Vec::new()));
    routes.insert(
        "/vks/v1/by-email/big%40example.org".into(),
        (200, vec![b'x'; 2 * 1024 * 1024]),
    );
    routes.insert(
        "/vks/v1/by-email/junk%40example.org".into(),
        (200, b"<html>not a key</html>".to_vec()),
    );
    let server = serve(routes).await;
    let s = servers(&server.base);
    assert!(matches!(
        find("busy@example.org", &s, true, now()).await,
        Found::Unavailable(_)
    ));
    assert!(matches!(
        find("down@example.org", &s, true, now()).await,
        Found::Unavailable(_)
    ));
    // a redirect is not followed
    assert_eq!(find("moved@example.org", &s, true, now()).await, Found::NotFound);
    assert!(
        server
            .asked
            .lock()
            .unwrap()
            .iter()
            .all(|asked| !asked.contains("elsewhere"))
    );
    assert!(matches!(
        find("big@example.org", &s, true, now()).await,
        Found::Unavailable(_)
    ));
    assert_eq!(find("junk@example.org", &s, true, now()).await, Found::NotFound);
}

#[tokio::test]
async fn the_direct_method_only_when_the_advanced_host_is_not_there() {
    let bob = key("bob@example.org");
    let mut routes = HashMap::new();
    routes.insert(wkd_path("direct", "bob@example.org"), (200, bob.cert().to_bytes()));
    let server = serve(routes).await;
    // the advanced host answers (404): the direct method is not asked
    assert_eq!(
        wkd("bob@example.org", &servers(&server.base), now()).await,
        Found::NotFound
    );
    assert!(
        server
            .asked
            .lock()
            .unwrap()
            .iter()
            .all(|asked| !asked.contains("/direct/"))
    );
}

#[tokio::test]
async fn by_fingerprint_and_key_id() {
    let bob = key("bob@example.org");
    let fingerprint = bob.fingerprint();
    let key_id = bob.cert().key_id();
    let mut routes = HashMap::new();
    routes.insert(
        format!("/vks/v1/by-fingerprint/{fingerprint}"),
        (200, bob.cert().to_bytes()),
    );
    routes.insert(format!("/vks/v1/by-keyid/{key_id}"), (200, bob.cert().to_bytes()));
    let server = serve(routes).await;
    let s = servers(&server.base);
    assert!(matches!(by_fingerprint(&fingerprint, &s).await, Found::Key(..)));
    assert!(matches!(by_fingerprint(&key_id, &s).await, Found::Key(..)));
    assert_eq!(by_fingerprint("12", &s).await, Found::NotFound);
}

#[tokio::test]
async fn publishing_asks_for_the_confirmation_mail() {
    let mut routes = HashMap::new();
    routes.insert(
        "/vks/v1/upload".into(),
        (
            200,
            br#"{"key_fpr":"AB","token":"tok","status":{"me@example.org":"unpublished"}}"#.to_vec(),
        ),
    );
    routes.insert(
        "/vks/v1/request-verify".into(),
        (
            200,
            br#"{"key_fpr":"AB","token":"tok","status":{"me@example.org":"pending"}}"#.to_vec(),
        ),
    );
    let server = serve(routes).await;
    let me = key("me@example.org");
    let done = publish(&me.cert().armored(), &["me@example.org".into()], &servers(&server.base))
        .await
        .unwrap();
    assert_eq!(done.addresses, [("me@example.org".to_string(), "pending".to_string())]);
    let asked = server.asked.lock().unwrap().clone();
    assert_eq!(asked, ["POST /vks/v1/upload", "POST /vks/v1/request-verify"]);
}

/// The real keys.openpgp.org, with PE_NETWORK_TESTS=1: a key by fingerprint (which tells the server no address)
#[tokio::test]
async fn the_real_key_server() {
    if std::env::var_os("PE_NETWORK_TESTS").is_none() {
        return;
    }
    // the key of keys.openpgp.org's own announcements address, published there
    match by_fingerprint("A63CB4E6B6B8BD7D0B4F2ECA6EE17B2A7A2D9BD0", &Servers::default()).await {
        Found::Key(..) | Found::NotFound => {}
        Found::Unavailable(why) => panic!("keys.openpgp.org: {why}"),
    }
}
