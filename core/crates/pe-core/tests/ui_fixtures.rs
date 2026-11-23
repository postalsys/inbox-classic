//! The signed and encrypted messages of the UI tests (`scripts/ui-e2e/pgp/`, made by pe-pgp's `ui_fixtures` example)
//! read as the apps will show them: each one's bar, its colour and its parts. The UI tests check the same words.

use std::path::PathBuf;
use std::sync::Mutex;
use std::sync::mpsc::{self, Receiver};

use pe_core::keys::{KeySource, Learned};
use pe_core::protect::Tone;
use pe_core::{Core, Event, Options, PasswordStore, Protection};

mod support;

fn fixtures() -> PathBuf {
    PathBuf::from(env!("CARGO_MANIFEST_DIR")).join("../../../scripts/ui-e2e/pgp")
}

/// A core with the test keys, and its events
fn core(dir: &pe_testkit::TempDir) -> (Core, Receiver<Event>) {
    let options = Options {
        passwords: PasswordStore::Memory,
        ..Default::default()
    };
    let (sender, events) = mpsc::channel();
    let sender = Mutex::new(sender);
    let core = Core::open_with(dir.path().join("store.db"), options, move |event| {
        let _ = sender.lock().unwrap().send(event);
    })
    .unwrap();
    let read = |name: &str| std::fs::read(fixtures().join(name)).unwrap();
    let passphrase = String::from_utf8(read("me.passphrase")).unwrap();
    core.pgp_import(&read("me.asc"), Some(passphrase.trim()), KeySource::File)
        .unwrap();
    for name in ["alice.asc", "mallory.asc"] {
        core.pgp_import(&read(name), None, KeySource::File).unwrap();
    }
    (core, events)
}

/// All that is shown of a view: its page and every part's document
fn shown(view: &pe_core::MessageView) -> String {
    let mut all = view.document.clone();
    for document in &view.part_documents {
        all.push_str(document);
    }
    all
}

/// A message file's view, once its previews' files are all described
fn view(core: &Core, events: &Receiver<Event>, name: &str) -> pe_core::MessageView {
    support::settled(core, events, || core.file_view(&fixtures().join(name), false).unwrap())
}

#[test]
fn each_case_reads_as_the_ui_tests_expect() {
    let dir = pe_testkit::TempDir::new("ui-fixtures");
    let (core, events) = core(&dir);
    let bar = |name: &str| {
        let view = view(&core, &events, name);
        let protection = view.protection.clone().unwrap_or_else(|| panic!("{name}: no bar"));
        (protection.tone, protection.text, view)
    };
    let (tone, text, _) = bar("secure-signed.eml");
    assert_eq!(
        (tone, text.as_str()),
        (Tone::Good, "Signed by alice@example.org (key not verified)")
    );
    let (tone, text, view) = bar("secure-encrypted.eml");
    assert_eq!(tone, Tone::Good);
    assert!(text.starts_with("Encrypted. Signed by alice@example.org"), "{text}");
    assert!(shown(&view).contains("old mill"));
    assert!(view.protection.as_ref().unwrap().encrypted);
    // encrypted with a protected Subject (made once, outside ui_fixtures, with the committed me.asc): the list and
    // the reading pane name it by the Subject inside
    let (_, _, view) = bar("secure-protected-subject.eml");
    assert_eq!(view.subject, "The mill on Friday");
    assert!(shown(&view).contains("grain arrives"));
    let (tone, text, view) = bar("secure-mixed.eml");
    assert_eq!(tone, Tone::Neutral);
    assert!(text.contains("3 parts"), "{text}");
    assert_eq!(view.document.matches("<iframe").count(), 3);
    // a link clicked in a part navigates the top page (a click only), which the apps cancel and open in the browser
    assert_eq!(
        view.document
            .matches("sandbox=\"allow-same-origin allow-top-navigation-by-user-activation\"")
            .count(),
        3
    );
    assert!(!view.document.contains("<base"));
    for document in view.part_documents.iter().filter(|d| !d.is_empty()) {
        assert!(document.contains("<base target=\"_top\">"), "{document}");
    }
    // the unsigned part's link, which the UI tests click in its frame
    assert!(
        view.part_documents[0].contains("href=\"https://example.org/mill\""),
        "{}",
        view.part_documents[0]
    );
    let (tone, text, _) = bar("secure-bad.eml");
    assert_eq!(tone, Tone::Warning);
    assert!(text.contains("does not match"), "{text}");
    let (tone, text, _) = bar("secure-wrong-signer.eml");
    assert_eq!(tone, Tone::Warning);
    assert!(
        text.contains("mallory@example.net") && text.contains("not the sender"),
        "{text}"
    );
    let (tone, text, _) = bar("secure-no-key.eml");
    assert_eq!(
        (tone, text.as_str()),
        (Tone::Neutral, "Signed, but the key is not known")
    );
    let (_, text, view) = bar("secure-fake-frame.eml");
    assert!(text.contains("2 parts"), "{text}");
    assert_eq!(view.document.matches("<iframe").count(), 2);
    let (tone, text, view) = bar("secure-inline.eml");
    assert!(text.contains("3 parts"), "{text}");
    assert_eq!(tone, Tone::Neutral);
    assert!(shown(&view).contains("4711"));
    let (_, text, view) = bar("secure-pictures.eml");
    assert!(text.starts_with("Encrypted."), "{text}");
    assert!(
        view.remote_images && !view.pictures_loaded,
        "the picture waits for a click"
    );
    assert!(view.sender.is_none(), "no \"always\" for encrypted mail");
    // printed: one document of every part's text, the bar and the labels as words in its header
    let (_, text, view) = bar("secure-mixed.eml");
    let print = view.print_document.as_deref().unwrap();
    assert!(print.contains("A note added on the way") && print.contains("The signed paragraph"));
    assert!(print.contains(&text) && print.contains("Part 2") && !print.contains("<iframe"));
    let (_, _, view) = bar("secure-long.eml");
    assert!(shown(&view).contains("Line 40 of the long part"));
    // a picture in each of two parts, the second encrypted: each previewed in its own part's document
    let (_, text, view) = bar("secure-previews.eml");
    assert!(text.contains("2 parts"), "{text}");
    assert!(!view.document.contains("/pv/"));
    assert!(view.part_documents[0].contains("alt=\"harbour.png\""));
    assert!(view.part_documents[1].contains("alt=\"floor-plan.png\""));
    assert!(shown(&view).contains("for your eyes only"));
    // the bar counts the encrypted part as encrypted, not as "signed or encrypted"
    assert!(
        text.contains("2 parts: 1 encrypted, 1 without a confirmed signature"),
        "{text}"
    );
    // each file says which part it came from; the encrypted part's is marked
    let rows: Vec<_> = view
        .attachments
        .iter()
        .map(|a| (a.filename.as_str(), a.part, a.protection, a.part_text.as_str()))
        .collect();
    assert_eq!(
        rows,
        [
            ("harbour.png", Some(0), Protection::None, "From part 1: Not signed"),
            (
                "floor-plan.png",
                Some(1),
                Protection::Encrypted,
                "From part 2: Encrypted. Not signed"
            ),
        ]
    );
    assert!(
        view.attachments[1]
            .tooltip
            .ends_with("\nFrom part 2: Encrypted. Not signed"),
        "{}",
        view.attachments[1].tooltip
    );
}

/// The keys and messages of finding, publishing and passing on keys (SCENARIO.md 19k): Dave's key opens what
/// `secure-no-key.eml` says, Erin's attached key is offered and imported, Frank's Autocrypt keys are learned and the
/// second waits, and the keys the harness serves hold their addresses
#[test]
fn the_keys_of_finding_read_as_the_ui_tests_expect() {
    let dir = pe_testkit::TempDir::new("ui-fixtures-finding");
    let (core, events) = core(&dir);
    let read = |name: &str| std::fs::read(fixtures().join(name)).unwrap();
    let dave = pe_pgp::read_certs(&read("dave.asc")).unwrap().remove(0);
    // Find Key beside the label of Dave's signature asks for his key's fingerprint (or key id)
    let shown = view(&core, &events, "secure-no-key.eml");
    let parts = shown.protection.clone().unwrap().parts;
    assert_eq!(parts.len(), 1);
    let handle = parts[0].find_key.clone().expect("Find Key");
    // asked by its fingerprint, which the harness serves it by
    assert_eq!(handle, dave.fingerprint());
    assert!(shown.document.contains(&format!("inboxclassic:find-key?{handle}")));
    // once his key is there, the label and the bar name him
    core.pgp_import(&read("dave.asc"), None, KeySource::Keyserver).unwrap();
    let protection = view(&core, &events, "secure-no-key.eml").protection.unwrap();
    assert_eq!(
        (protection.tone, protection.text.as_str()),
        (Tone::Good, "Signed by dave@example.com (key not verified)")
    );
    assert_eq!(
        protection.parts[0].label,
        "Signed by dave@example.com (key not verified)"
    );
    assert_eq!(protection.parts[0].find_key, None);

    // Erin's key, attached: Import Key
    let shown = view(&core, &events, "key-attached.eml");
    let files: Vec<_> = shown
        .attachments
        .iter()
        .map(|a| (a.filename.as_str(), a.is_key))
        .collect();
    assert_eq!(files, [("Erin Example public key.asc", true)]);
    let imported = core
        .pgp_import_file_attachment(&fixtures().join("key-attached.eml"), 0)
        .unwrap();
    assert_eq!(imported.addresses, [("erin@example.org".to_string(), Learned::Used)]);
    let erin = core.pgp_key(&imported.keys[0]).unwrap();
    assert_eq!(
        (erin.name.as_str(), erin.source.as_str()),
        ("Erin Example", "From a message")
    );

    // Frank's first message: his key learned from its Autocrypt header
    view(&core, &events, "autocrypt-frank-1.eml");
    let frank = core.pgp_peer("frank@example.org").unwrap();
    let first = frank.in_use.clone().expect("Frank's key learned");
    assert_eq!(frank.pending, None);
    let key = core.pgp_key(&first).unwrap();
    assert_eq!(
        (key.name.as_str(), key.source.as_str(), key.own),
        ("Frank Example", "From a message's Autocrypt header", false)
    );
    // his second, later, with another key: it waits for the user's decision, the first stays in use
    view(&core, &events, "autocrypt-frank-2.eml");
    let frank = core.pgp_peer("frank@example.org").unwrap();
    assert_eq!(frank.in_use.as_deref(), Some(first.as_str()));
    let second = frank.pending.clone().expect("the new key waits");
    assert_ne!(second, first);
    let pending = frank.pending_text.unwrap();
    assert!(
        pending.starts_with("A different key for frank@example.org was found on "),
        "{pending}"
    );
    // Keep the Current One
    core.pgp_decide("frank@example.org", false).unwrap();
    let frank = core.pgp_peer("frank@example.org").unwrap();
    assert_eq!((frank.in_use.as_deref(), frank.pending), (Some(first.as_str()), None));

    // the keys the harness serves, and the one pasted, hold their addresses
    for (name, address) in [
        ("grace.asc", "grace@example.net"),
        ("heidi.asc", "heidi@example.net"),
        ("judy.asc", "judy@example.net"),
    ] {
        let certs = pe_pgp::read_certs(&read(name)).unwrap();
        assert_eq!(certs.len(), 1, "{name}");
        assert_eq!(certs[0].addresses(1_793_527_200), [address], "{name}");
    }
}
