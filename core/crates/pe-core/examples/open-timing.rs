//! How long opening a message takes, against ImapKit behind a proxy that adds latency:
//!
//! ```text
//! cargo run -p pe-core --example open-timing -- [latency in ms, 100] [--dead]
//! ```
//!
//! Opens messages of a few sizes, first over a new connection, then over the one open, then from the store, and
//! prints the core's timing record of each. With `--dead`, the proxy then stops answering on the connections it has
//! (as a NAT that forgot them, or a computer that slept) and one more message is opened.

use std::io::{Read, Write};
use std::net::{Shutdown, TcpListener, TcpStream};
use std::sync::atomic::{AtomicBool, AtomicU64, Ordering};
use std::sync::mpsc::{Receiver, channel};
use std::sync::{Arc, Mutex};
use std::thread;
use std::time::{Duration, Instant};

use pe_core::{Core, Event, Options, PasswordStore};
use pe_store::Sort;
use pe_testkit::{ImapKit, PASSWORD, TempDir, rfc822};
use serde_json::json;

/// A TCP proxy that delays everything by `latency` in each direction. Connections made before [`Proxy::kill`] stop
/// carrying anything; later ones work.
struct Proxy {
    port: u16,
    generation: Arc<AtomicU64>,
}

impl Proxy {
    fn start(upstream: u16, latency: Duration) -> Proxy {
        let listener = TcpListener::bind("127.0.0.1:0").unwrap();
        let port = listener.local_addr().unwrap().port();
        let generation = Arc::new(AtomicU64::new(0));
        let current = generation.clone();
        thread::spawn(move || {
            for client in listener.incoming().flatten() {
                let Ok(server) = TcpStream::connect(("127.0.0.1", upstream)) else {
                    continue;
                };
                let alive = Arc::new(AtomicBool::new(true));
                let born = current.load(Ordering::SeqCst);
                let watch = (current.clone(), born, alive.clone());
                pipe(
                    client.try_clone().unwrap(),
                    server.try_clone().unwrap(),
                    latency,
                    watch.clone(),
                );
                pipe(server, client, latency, watch);
            }
        });
        Proxy { port, generation }
    }

    /// The connections open now go silent: no data either way, nothing closed
    fn kill(&self) {
        self.generation.fetch_add(1, Ordering::SeqCst);
    }
}

type Watch = (Arc<AtomicU64>, u64, Arc<AtomicBool>);

fn pipe(mut from: TcpStream, to: TcpStream, latency: Duration, watch: Watch) {
    let (sender, receiver) = channel::<(Instant, Vec<u8>)>();
    let (generation, born, alive) = watch;
    let reading = alive.clone();
    thread::spawn(move || {
        let mut buffer = vec![0; 64 * 1024];
        while let Ok(count) = from.read(&mut buffer) {
            if count == 0 || !reading.load(Ordering::SeqCst) {
                break;
            }
            let _ = sender.send((Instant::now() + latency, buffer[..count].to_vec()));
        }
    });
    thread::spawn(move || {
        let mut to = to;
        for (due, data) in receiver {
            thread::sleep(due.saturating_duration_since(Instant::now()));
            if generation.load(Ordering::SeqCst) != born {
                // silent from now on, without closing: what a dead connection looks like to the client
                alive.store(false, Ordering::SeqCst);
                continue;
            }
            if to.write_all(&data).is_err() {
                break;
            }
        }
        if alive.load(Ordering::SeqCst) {
            let _ = to.shutdown(Shutdown::Write);
        }
    });
}

fn wait(events: &Receiver<Event>, limit: Duration, accept: impl Fn(&Event) -> bool) -> Option<Event> {
    let until = Instant::now() + limit;
    while let Some(left) = until.checked_duration_since(Instant::now()) {
        match events.recv_timeout(left) {
            Ok(event) if accept(&event) => return Some(event),
            Ok(_) => {}
            Err(_) => return None,
        }
    }
    None
}

fn main() {
    let mut args = std::env::args().skip(1);
    let mut latency = 100;
    let mut dead = false;
    for arg in args.by_ref() {
        match arg.as_str() {
            "--dead" => dead = true,
            number => latency = number.parse().expect("the latency in milliseconds"),
        }
    }
    let Some(server) = ImapKit::start(json!({})) else {
        eprintln!("ImapKit did not start: run npm ci in core/e2e");
        std::process::exit(1);
    };
    let sizes = [
        ("5 KB", 5 * 1024),
        ("200 KB", 200 * 1024),
        ("2 MB", 2 * 1024 * 1024),
        ("small", 1024),
    ];
    let mut uids = Vec::new();
    for (name, size) in sizes {
        uids.push((name, server.add_message("INBOX", &rfc822(name, &"x".repeat(size)), &[])));
    }
    let proxy = Proxy::start(server.account_settings().imap_port, Duration::from_millis(latency));
    let dir = TempDir::new("open-timing");
    let (sender, events) = channel();
    let sender = Mutex::new(sender);
    let options = Options {
        trust: pe_net::Trust::Pinned(vec![server.cert.clone()]),
        passwords: PasswordStore::Memory,
        ..Default::default()
    };
    let core = Core::open_with(dir.path().join("store.db"), options, move |event| {
        let _ = sender.lock().unwrap().send(event);
    })
    .unwrap();
    let mut settings = server.account_settings();
    settings.imap_port = proxy.port;
    let account = core.add_account(&settings, PASSWORD).unwrap();
    core.sync(account).unwrap();
    wait(&events, Duration::from_secs(60), |e| {
        matches!(e, Event::SyncFinished { .. })
    })
    .expect("synced");
    let inbox = core
        .folders(account)
        .unwrap()
        .into_iter()
        .find(|f| f.info.path == "INBOX")
        .unwrap();
    assert_eq!(
        core.messages(inbox.id, Sort::default(), 0, 10).unwrap().len(),
        sizes.len()
    );

    let open = |uid: u64, limit: Duration| {
        core.open_message(inbox.id, uid).unwrap();
        wait(&events, limit, |e| match e {
            Event::MessageReady { uid: ready, .. } | Event::MessageFailed { uid: ready, .. } => *ready == uid,
            _ => false,
        })
        .is_some()
    };
    println!("latency {latency} ms each way");
    for (_, uid) in &uids[..3] {
        open(*uid, Duration::from_secs(120));
    }
    for (_, uid) in &uids[..3] {
        open(*uid, Duration::from_secs(10));
    }
    if dead {
        proxy.kill();
        let started = Instant::now();
        let answered = open(uids[3].1, Duration::from_secs(400));
        println!(
            "after the connection died: {:?} ({})",
            started.elapsed(),
            if answered { "opened" } else { "no answer" }
        );
    }
    let names: std::collections::HashMap<u64, &str> = uids.iter().map(|(name, uid)| (*uid, *name)).collect();
    let ms = |d: Option<Duration>| d.map_or_else(|| "-".to_string(), |d| d.as_millis().to_string());
    println!(
        "{:<8} {:>9} {:<7} {:<8} {:>8} {:>9} {:>8} {:>10} {:>9} {:>6} {:>5}",
        "message",
        "bytes",
        "served",
        "link",
        "started",
        "connected",
        "selected",
        "first byte",
        "last byte",
        "ready",
        "view"
    );
    for t in core.open_timings() {
        println!(
            "{:<8} {:>9} {:<7} {:<8} {:>8} {:>9} {:>8} {:>10} {:>9} {:>6} {:>5}{}",
            names.get(&t.uid).copied().unwrap_or("?"),
            t.size,
            format!("{:?}", t.served),
            format!("{:?}", t.link),
            t.started.as_millis(),
            ms(t.connected),
            ms(t.selected),
            ms(t.first_byte),
            ms(t.last_byte),
            ms(t.ready),
            ms(t.view_built),
            if t.failed { " failed" } else { "" }
        );
    }
    let timings = core.open_timings();
    let from_store = timings
        .iter()
        .filter(|t| t.served == pe_core::timing::Served::Store)
        .count();
    println!("served from the store: {from_store} of {}", timings.len());
}
