//! The signed and encrypted messages of the UI tests (`scripts/ui-e2e/pgp/`, made by pe-pgp's `ui_fixtures` example)
//! read as the apps will show them: each one's bar, its colour and its parts. The UI tests check the same words.

use std::path::PathBuf;

use pe_core::keys::KeySource;
use pe_core::protect::Tone;
use pe_core::{Core, Options, PasswordStore};

fn fixtures() -> PathBuf {
    PathBuf::from(env!("CARGO_MANIFEST_DIR")).join("../../../scripts/ui-e2e/pgp")
}

fn core(dir: &pe_testkit::TempDir) -> Core {
    let options = Options {
        passwords: PasswordStore::Memory,
        ..Default::default()
    };
    let core = Core::open_with(dir.path().join("store.db"), options, |_| {}).unwrap();
    let read = |name: &str| std::fs::read(fixtures().join(name)).unwrap();
    let passphrase = String::from_utf8(read("me.passphrase")).unwrap();
    core.pgp_import(&read("me.asc"), Some(passphrase.trim()), KeySource::File)
        .unwrap();
    for name in ["alice.asc", "mallory.asc"] {
        core.pgp_import(&read(name), None, KeySource::File).unwrap();
    }
    core
}

/// All that is shown of a view: its page and every part's document
fn shown(view: &pe_core::MessageView) -> String {
    let mut all = view.document.clone();
    for document in &view.part_documents {
        all.push_str(document);
    }
    all
}

fn view(core: &Core, name: &str) -> pe_core::MessageView {
    core.file_view(&fixtures().join(name), false).unwrap()
}

#[test]
fn each_case_reads_as_the_ui_tests_expect() {
    let dir = pe_testkit::TempDir::new("ui-fixtures");
    let core = core(&dir);
    let bar = |name: &str| {
        let view = view(&core, name);
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
}
