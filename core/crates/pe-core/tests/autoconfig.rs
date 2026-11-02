//! Looking up the servers of an address through the engine, without the network: an address without a domain
//! finishes with nothing, and each lookup reports its own request

use std::sync::mpsc::channel;
use std::time::Duration;

use pe_core::{Core, Event, Options, PasswordStore};
use pe_testkit::TempDir;

#[test]
fn lookups_report_their_request() {
    let dir = TempDir::new("autoconfig");
    let (sender, events) = channel();
    let options = Options {
        passwords: PasswordStore::Memory,
        ..Default::default()
    };
    let core = Core::open_with(dir.path().join("store.db"), options, move |event| {
        let _ = sender.send(event);
    })
    .unwrap();
    let first = core.autoconfig("no domain here").unwrap();
    let second = core.autoconfig("nor@here").unwrap();
    assert_ne!(first, second);
    let mut done = Vec::new();
    while done.len() < 2 {
        match events.recv_timeout(Duration::from_secs(10)).unwrap() {
            Event::AutoconfigDone { request } => done.push(request),
            other => panic!("{other:?}"),
        }
    }
    done.sort_unstable();
    assert_eq!(done, [first, second]);
    assert_eq!(core.autoconfig_result(first), None);
    assert_eq!(core.autoconfig_result(second), None);
    // taken once
    assert_eq!(core.autoconfig_result(42), None);

    // a cancelled lookup is forgotten, its event or not
    let cancelled = core.autoconfig("someone@example.invalid").unwrap();
    core.autoconfig_cancel(cancelled);
    assert_eq!(core.autoconfig_result(cancelled), None);
}
