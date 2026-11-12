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

    // its attachments: one by one and all at once, as a message of a folder's
    let with_file = dir.path().join("with-file.eml");
    std::fs::write(
        &with_file,
        "From: Ann <ann@example.com>\r\nTo: you@example.com\r\nSubject: A file\r\nMIME-Version: 1.0\r\n\
         Content-Type: multipart/mixed; boundary=b\r\n\r\n--b\r\nContent-Type: text/plain\r\n\r\nSee the map.\r\n\
         --b\r\nContent-Type: text/plain; name=map.txt\r\nContent-Disposition: attachment; filename=map.txt\r\n\r\n\
         the trail\r\n--b--\r\n",
    )
    .unwrap();
    assert_eq!(core.file_view(&with_file, false).unwrap().attachments.len(), 1);
    let (name, content) = core.file_attachment(&with_file, 0).unwrap().unwrap();
    assert_eq!(
        (name.as_str(), content.as_slice()),
        ("map.txt", b"the trail".as_slice())
    );
    assert!(core.file_attachment(&with_file, 1).unwrap().is_none());
    let out = dir.path().join("saved");
    std::fs::create_dir(&out).unwrap();
    assert_eq!(core.file_save_attachments(&with_file, &out).unwrap(), (1, 1));
    assert_eq!(std::fs::read(out.join("map.txt")).unwrap(), b"the trail");

    // an invitation in a file opens in the calendar as one in a folder does
    let invite = dir.path().join("invite.eml");
    std::fs::write(
        &invite,
        "From: Ann <ann@example.com>\r\nTo: you@example.com\r\nSubject: Lunch\r\nMIME-Version: 1.0\r\n\
         Content-Type: text/calendar; method=REQUEST\r\n\r\nBEGIN:VCALENDAR\r\nMETHOD:REQUEST\r\nBEGIN:VEVENT\r\n\
         SUMMARY:Lunch\r\nDTSTART:20261201T120000Z\r\nEND:VEVENT\r\nEND:VCALENDAR\r\n",
    )
    .unwrap();
    let ics = core
        .file_invitation_file(&invite, &dir.path().join("calendar"))
        .unwrap()
        .unwrap();
    assert!(std::fs::read_to_string(ics).unwrap().contains("SUMMARY:Lunch"));
    assert!(
        core.file_invitation_file(&file, &dir.path().join("calendar"))
            .unwrap()
            .is_none()
    );

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
