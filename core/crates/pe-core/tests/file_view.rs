//! A message file opened from Finder or File Explorer: its view, and a reply to it, without a folder

use pe_core::{Core, DraftKind, Options, PasswordStore};

#[test]
fn a_message_file_opens_and_can_be_answered() {
    let dir = pe_testkit::TempDir::new("core-file-view");
    let options = Options {
        passwords: PasswordStore::Memory,
        ..Default::default()
    };
    let core = Core::open_with(dir.path().join("store.db"), options, |_| {}).unwrap();
    let file = dir.path().join("saved.eml");
    std::fs::write(
        &file,
        "From: Ann <ann@example.com>\r\nTo: you@example.com\r\nSubject: Saved message\r\n\
         Message-ID: <saved@example.com>\r\nDate: Tue, 7 Oct 2025 10:00:00 +0000\r\nContent-Type: text/html\r\n\r\n\
         <p>Hello</p><img src=\"https://example.com/p.png\">\r\n",
    )
    .unwrap();
    let view = core.file_view(&file, false).unwrap();
    assert_eq!(view.subject, "Saved message");
    assert!(
        view.remote_images && !view.pictures_loaded,
        "pictures wait for the click"
    );
    assert!(core.file_view(&file, true).unwrap().pictures_loaded);

    let text = dir.path().join("notes.txt");
    std::fs::write(&text, "just some notes\n").unwrap();
    assert!(
        core.file_view(&text, false).is_err(),
        "a file that is no mail is refused"
    );

    let account = core
        .add_account(
            &pe_store::AccountSettings {
                email: "you@example.com".into(),
                username: "you@example.com".into(),
                imap_host: "imap.example.com".into(),
                smtp_host: "smtp.example.com".into(),
                ..Default::default()
            },
            "secret",
        )
        .unwrap();
    let draft = core.file_draft(&file, account, DraftKind::Reply).unwrap();
    assert_eq!(draft.subject, "Re: Saved message");
    assert!(draft.to.contains("ann@example.com"));
}
