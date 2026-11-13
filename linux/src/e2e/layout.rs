//! View > Folder List and the header bar's sidebar button: the folder list hidden, a folder chosen from the folder
//! button's popover, and the list back beside the messages

use super::*;

/// The folder list is beside the messages: shown, and in no popover
fn beside_messages() -> bool {
    named_in(&main_window(), "folder-tree").is_some_and(|tree| tree.ancestor(gtk::Popover::static_type()).is_none())
}

fn sidebar_on() -> bool {
    toggle_on("folder-list-toggle")
}

fn folder_button_shown() -> bool {
    named_in(&main_window(), "folder-list-button").is_some_and(|b| b.is_visible())
}

pub async fn folder_list(d: &Driver) {
    d.step("the folder list hidden and shown again");
    let main = shell().main();
    select_folder("Inbox");
    wait_until(10, || main.selected_name() == "Inbox").await;
    d.check(
        beside_messages() && sidebar_on(),
        "the folder list starts beside the messages",
    );

    command(Command::FolderList);
    let hidden = wait_until(10, || !beside_messages() && !sidebar_on() && folder_button_shown()).await;
    d.check(
        hidden && !shell().settings.bool(crate::settings::FOLDER_LIST, true),
        "View > Folder List hides it, the sidebar button is off, the folder button takes its place, and that is kept",
    );
    d.shot(main.window(), "layout-3-folders-hidden").await;

    // a folder chosen while the list is hidden: the folder button's popover holds the list
    if let Some(button) = named_in(&main_window(), "folder-list-button").and_downcast::<gtk::MenuButton>() {
        button.popup();
        pause(500).await;
        select_folder("Sent Items");
        d.check(
            wait_until(10, || main.selected_name() == "Sent Items").await
                && wait_until(5, || !button.popover().is_some_and(|p| p.is_visible())).await,
            "the folder button's popover chooses a folder, and closes",
        );
    }
    select_folder("Inbox");
    wait_until(10, || main.selected_name() == "Inbox").await;

    // the sidebar button brings it back, as the menu item does
    if let Some(sidebar) = named_in(&main_window(), "folder-list-toggle").and_downcast::<gtk::ToggleButton>() {
        sidebar.emit_clicked();
    }
    d.check(
        wait_until(10, || beside_messages() && sidebar_on() && !folder_button_shown()).await
            && shell().settings.bool(crate::settings::FOLDER_LIST, false),
        "the sidebar button shows it beside the messages again",
    );
}

const COLUMNS_SUBJECT: &str = "Ferry times for Saturday";
const COLUMNS_BODY: &str = "The ferry leaves at nine from the north pier.";

/// The rows of the Columns list on screen: (who, subject, snippet, indent)
fn rows_on_screen() -> Vec<(String, String, String, i32)> {
    let view: gtk::Widget = shell().main().list.rows_view.clone().upcast();
    descendants::<gtk::Widget>(&view)
        .iter()
        .filter(|w| w.is_mapped())
        .filter_map(|w| w.downcast_ref::<crate::rows::RowWidget>().and_then(crate::rows::shown))
        .collect()
}

/// The list beside the reading pane: the panes side by side, the Columns list shown
fn side_by_side() -> bool {
    let main = shell().main();
    main.layout() == pe_core::layout::Layout::Columns
        && main.list.columns_shown()
        && main.list.rows_view.is_mapped()
        && !main.list.view.is_mapped()
}

/// The text of the Columns list's Sorted by button
fn sorted_by() -> String {
    named_in(&main_window(), "sort-button")
        .and_downcast::<gtk::MenuButton>()
        .and_then(|b| b.label())
        .map(|l| l.to_string())
        .unwrap_or_default()
}

/// A message with a known text, its snippet fetched in the background
async fn add_columns_message(d: &Driver, inbox: i64) -> bool {
    let raw = format!(
        "From: Petra Holm <petra@example.com>\r\nTo: testuser@inboxclassic.test\r\nSubject: {COLUMNS_SUBJECT}\r\n\
         Date: {}\r\nMessage-ID: <columns-1@example.com>\r\n\r\n{COLUMNS_BODY}\r\n\r\nPetra\r\n",
        super::steps::date_now(-5)
    );
    let added = d.add_message(&raw, &[]).is_ok();
    run_command(Command::Sync);
    let snipped = wait_until(60, || {
        listed_in_folder(inbox, 0, 500)
            .iter()
            .any(|m| m.info.subject == COLUMNS_SUBJECT && m.snippet.as_deref().is_some_and(|s| !s.is_empty()))
    })
    .await;
    added && snipped
}

/// View > Layout > Columns, the order of the Columns list, a conversation opened in it, and Automatic following the
/// window's width; Classic again at the end
pub async fn columns(d: &Driver) {
    let main = shell().main();
    let Some(inbox) = super::steps::folder_id("Inbox") else {
        d.check(false, "the tree has the Inbox");
        return;
    };
    select_folder("Inbox");
    wait_until(10, || main.selected_name() == "Inbox").await;
    d.step("the column layout");
    d.check(
        add_columns_message(d, inbox).await,
        "a new message's first words are read in the background",
    );
    command(Command::LayoutColumns);
    d.check(
        wait_until(10, side_by_side).await,
        "View > Layout > Columns puts the list beside the reading pane, its rows of three lines",
    );
    d.check(
        shell().settings.text(crate::settings::LAYOUT).as_deref() == Some("columns"),
        "and the choice is kept",
    );
    let at = main
        .list_view()
        .rows(&shell().core, 0, 500)
        .unwrap_or_default()
        .iter()
        .position(|m| m.info.subject == COLUMNS_SUBJECT);
    if let Some(at) = at {
        main.list.select(at as u32);
    }
    let row = |subject: &str| rows_on_screen().into_iter().find(|r| r.1 == subject);
    d.check(
        wait_until(10, || {
            row(COLUMNS_SUBJECT).is_some_and(|r| r.0 == "Petra Holm" && r.2.starts_with(COLUMNS_BODY))
        })
        .await,
        &format!(
            "a row names who, the subject and the first words ({:?})",
            row(COLUMNS_SUBJECT)
        ),
    );
    // one row unread for the screenshot, its dot and bold subject; read again after
    let listed = main.list_view().rows(&shell().core, 0, 500).unwrap_or_default();
    let unread = at
        .and_then(|at| at.checked_sub(1))
        .and_then(|above| listed.get(above).cloned())
        .filter(|m| m.info.seen() && m.thread.is_none_or(|t| t.depth == 0));
    if let Some(m) = &unread {
        let _ = shell().core.set_seen(inbox, m.info.uid, false);
    }
    // its row on screen with its subject in bold
    let rows_view: gtk::Widget = main.list.rows_view.clone().upcast();
    let bold_row = || {
        unread.as_ref().is_some_and(|m| {
            descendants::<gtk::Label>(&rows_view)
                .iter()
                .any(|l| l.is_mapped() && l.text() == m.info.subject && l.has_css_class("unread"))
        })
    };
    d.check(
        wait_until(10, bold_row).await,
        "a message marked unread has its dot and bold subject",
    );
    pause(1500).await;
    d.shot(main.window(), "layout-1-columns").await;
    if let Some(m) = &unread {
        let _ = shell().core.set_seen(inbox, m.info.uid, true);
    }
    sorting(d).await;
    conversation(d).await;
    automatic(d).await;
    command(Command::LayoutClassic);
    d.check(
        wait_until(10, || {
            main.layout() == pe_core::layout::Layout::Classic && main.list.view.is_mapped()
        })
        .await,
        "View > Layout > Classic puts the list above the reading pane again",
    );
}

/// View > Sort By in the Columns list: by Subject, the Sorted by button says so; by Date again
async fn sorting(d: &Driver) {
    d.step("the order of the Columns list");
    let main = shell().main();
    let date = Command::SortDate.label();
    d.check(
        sorted_by().contains(date),
        &format!("the list says it is sorted by date ({})", sorted_by()),
    );
    command(Command::SortSubject);
    let subject = Command::SortSubject.label();
    let subjects = || -> Vec<String> {
        main.list_view()
            .rows(&shell().core, 0, 500)
            .unwrap_or_default()
            .into_iter()
            .map(|m| m.info.subject.to_lowercase())
            .collect()
    };
    let in_order = |list: &[String]| list.windows(2).all(|pair| pair[0] <= pair[1]);
    d.check(
        wait_until(10, || sorted_by().contains(subject) && in_order(&subjects())).await,
        &format!(
            "Sort By > Subject orders the rows A to Z, and the button says so ({})",
            sorted_by()
        ),
    );
    d.check(
        main.window()
            .action_state(Command::SortSubject.name())
            .and_then(|v| v.get::<bool>())
            == Some(true)
            && main
                .window()
                .action_state(Command::SortAscending.name())
                .and_then(|v| v.get::<bool>())
                == Some(true),
        "View > Sort By checks Subject and Sort Ascending",
    );
    pause(800).await;
    d.shot(main.window(), "layout-4-sort").await;
    command(Command::SortDate);
    d.check(
        wait_until(10, || sorted_by().contains(date) && !main.list.sort().ascending).await,
        "Sort By > Date orders them newest first again",
    );
}

/// A conversation opened in the Columns list: its other messages' rows indented under its first
async fn conversation(d: &Driver) {
    d.step("a conversation in the Columns list");
    let main = shell().main();
    let trip = main
        .list_view()
        .rows(&shell().core, 0, 500)
        .unwrap_or_default()
        .into_iter()
        .enumerate()
        .find(|(_, m)| m.thread.is_some_and(|t| t.opens() && t.collapsed()));
    let Some((at, head)) = trip else {
        d.check(false, "the Inbox has a closed conversation");
        return;
    };
    let thread = head.thread.map(|t| t.thread).unwrap_or_default();
    main.list.select(at as u32);
    main.toggle_thread(thread);
    d.check(
        wait_until(10, || rows_on_screen().iter().any(|r| r.3 > 0)).await,
        &format!(
            "opened, {:?} has its other messages under it, indented",
            head.info.subject
        ),
    );
    pause(800).await;
    d.shot(main.window(), "layout-5-conversation").await;
    main.toggle_thread(thread);
    wait_until(10, || rows_on_screen().iter().all(|r| r.3 == 0)).await;
}

/// View > Layout > Automatic: Columns in a wide window, Classic in a narrower one, and the status bar's note once
async fn automatic(d: &Driver) {
    d.step("the layout by the window's width");
    let main = shell().main();
    let window = main.window().clone();
    let (width, height) = (window.width(), window.height());
    command(Command::LayoutClassic);
    wait_until(10, || main.layout() == pe_core::layout::Layout::Classic).await;
    shell().settings.set_bool(crate::settings::COLUMNS_NOTE, false);
    command(Command::LayoutAutomatic);
    window.set_default_size(1500, height);
    d.check(
        wait_until(10, || window.width() >= 1400 && side_by_side()).await,
        &format!(
            "Automatic in a window 1500 wide shows Columns ({} wide)",
            window.width()
        ),
    );
    let note = t!(UiColumnsNote);
    d.check(
        descendants::<gtk::Label>(&main_window())
            .iter()
            .any(|l| l.text() == note),
        "the status bar says once where the layout is changed",
    );
    pause(800).await;
    d.shot(main.window(), "layout-2-automatic").await;
    window.set_default_size(1100, height);
    d.check(
        wait_until(10, || {
            window.width() <= 1150 && main.layout() == pe_core::layout::Layout::Classic
        })
        .await,
        &format!("and Classic in a window 1100 wide ({} wide)", window.width()),
    );
    window.set_default_size(width, height);
    wait_until(10, || window.width() == width).await;
}

const LOGO_SUBJECT: &str = "Autumn offers from the brand";
const PLAIN_SUBJECT: &str = "Notes from the meeting";

/// A brand's server for the test: every request answered with its logo
fn logo_server() -> u16 {
    let listener = std::net::TcpListener::bind("127.0.0.1:0").expect("a socket for the logo");
    let port = listener.local_addr().map(|a| a.port()).unwrap_or(0);
    std::thread::spawn(move || {
        let svg = "<svg xmlns=\"http://www.w3.org/2000/svg\" version=\"1.2\" baseProfile=\"tiny-ps\" \
                   viewBox=\"0 0 100 100\"><title>Brand</title><rect width=\"100\" height=\"100\" fill=\"#0a5bd3\"/>\
                   <circle cx=\"50\" cy=\"50\" r=\"26\" fill=\"#ffffff\"/></svg>";
        for stream in listener.incoming() {
            let Ok(mut stream) = stream else { break };
            let mut buffer = [0u8; 2048];
            let _ = stream.read(&mut buffer);
            let answer = format!(
                "HTTP/1.0 200 OK\r\nContent-Type: image/svg+xml\r\nContent-Length: {}\r\n\r\n{svg}",
                svg.len()
            );
            let _ = stream.write_all(answer.as_bytes());
        }
    });
    port
}

/// The row of the Columns list on screen whose subject is `subject`
fn row_on_screen(subject: &str) -> Option<crate::rows::RowWidget> {
    let view: gtk::Widget = shell().main().list.rows_view.clone().upcast();
    descendants::<gtk::Widget>(&view)
        .into_iter()
        .filter(|w| w.is_mapped())
        .filter_map(|w| w.downcast::<crate::rows::RowWidget>().ok())
        .find(|row| crate::rows::shown(row).is_some_and(|(_, s, _, _)| s == subject))
}

/// A message from a brand whose provider passed its logo, and a plain one, both in the Inbox with their verdicts read
async fn add_picture_messages(d: &Driver, inbox: i64) -> bool {
    let port = logo_server();
    let branded = format!(
        "Authentication-Results: mx.inboxclassic.test; dmarc=pass header.from=brand.example; bimi=pass \
         header.d=brand.example\r\nBIMI-Location: v=BIMI1; l=http://127.0.0.1:{port}/logo.svg\r\n\
         From: Brand <news@brand.example>\r\nTo: testuser@inboxclassic.test\r\nSubject: {LOGO_SUBJECT}\r\n\
         Date: {}\r\nMessage-ID: <pictures-1@brand.example>\r\n\r\nThree offers for the autumn.\r\n",
        super::steps::date_now(-2)
    );
    let plain = format!(
        "From: Ida Berg <ida@example.com>\r\nTo: testuser@inboxclassic.test\r\nSubject: {PLAIN_SUBJECT}\r\n\
         Date: {}\r\nMessage-ID: <pictures-2@example.com>\r\n\r\nThe notes are attached below.\r\n",
        super::steps::date_now(-1)
    );
    let added = d.add_message(&branded, &[]).is_ok() && d.add_message(&plain, &[]).is_ok();
    run_command(Command::Sync);
    let read = wait_until(60, || {
        let listed = listed_in_folder(inbox, 0, 500);
        listed.iter().any(|m| m.info.subject == PLAIN_SUBJECT)
            && listed
                .iter()
                .any(|m| m.info.subject == LOGO_SUBJECT && m.logo.is_some())
    })
    .await;
    added && read
}

/// The senders' pictures in the Columns list: a brand's logo the provider passed, initials for the rest, and
/// Preferences turning them off and on
pub async fn list_pictures(d: &Driver) {
    let main = shell().main();
    let Some(inbox) = super::steps::folder_id("Inbox") else {
        d.check(false, "the tree has the Inbox");
        return;
    };
    d.step("the senders' pictures in the column layout");
    select_folder("Inbox");
    wait_until(10, || main.selected_name() == "Inbox").await;
    d.check(
        add_picture_messages(d, inbox).await,
        "a message whose provider passed the brand's logo, and a plain one, are in the Inbox",
    );
    command(Command::LayoutColumns);
    wait_until(10, side_by_side).await;
    main.list.select(0);
    d.check(
        wait_until(20, || {
            row_on_screen(LOGO_SUBJECT).is_some_and(|r| crate::rows::picture_drawn(&r))
        })
        .await,
        "the brand's row shows its logo",
    );
    d.check(
        row_on_screen(PLAIN_SUBJECT).is_some_and(|r| crate::rows::picture_shown(&r) && !crate::rows::picture_drawn(&r)),
        "a sender without one has their initials",
    );
    pause(500).await;
    d.shot(main.window(), "pictures-4-list").await;
    main.set_list_pictures(false);
    d.check(
        wait_until(10, || {
            row_on_screen(LOGO_SUBJECT).is_some_and(|r| !crate::rows::picture_shown(&r))
                && row_on_screen(PLAIN_SUBJECT).is_some_and(|r| !crate::rows::picture_shown(&r))
        })
        .await
            && !shell().settings.bool(crate::settings::LIST_PICTURES, true),
        "turned off in Preferences, the rows have no pictures, and that is kept",
    );
    main.set_list_pictures(true);
    d.check(
        wait_until(10, || {
            row_on_screen(LOGO_SUBJECT).is_some_and(|r| crate::rows::picture_drawn(&r))
        })
        .await,
        "turned on again, the logo is back without asking the core again",
    );
    command(Command::LayoutClassic);
    wait_until(10, || main.layout() == pe_core::layout::Layout::Classic).await;
}

const CONTACT_CONFIRMED: &str = "Photos from the studio";
const CONTACT_FORGED: &str = "Your studio invoice";
const CONTACT_ADDRESS: &str = "rita@studio.example";

/// A picture of a person for the Address Book, as a camera's would be: a PNG of a soft gradient with a round face
fn contact_png() -> Option<std::path::PathBuf> {
    let size = 96usize;
    let mut pixels = Vec::with_capacity(size * size * 4);
    for y in 0..size {
        for x in 0..size {
            let (dx, dy) = (x as f64 - 48.0, y as f64 - 40.0);
            let face = dx * dx + dy * dy < 22.0 * 22.0;
            let shoulders = y > 68 && (x as f64 - 48.0).abs() < 36.0 - (96.0 - y as f64) * 0.4;
            let (r, g, b) = if face || shoulders {
                (236, 200, 170)
            } else {
                (40 + (y as u8) / 2, 110 + (x as u8) / 3, 160)
            };
            pixels.extend_from_slice(&[b, g, r, 255]);
        }
    }
    let texture = gtk::gdk::MemoryTexture::new(
        size as i32,
        size as i32,
        gtk::gdk::MemoryFormat::B8g8r8a8Premultiplied,
        &glib::Bytes::from_owned(pixels),
        size * 4,
    );
    let path = std::env::temp_dir().join("inbox-classic-contact.png");
    std::fs::write(&path, texture.save_to_png_bytes()).ok()?;
    Some(path)
}

/// Opens Contact Properties of `card` as the Address Book's Properties does; the dialog once shown
async fn open_contact(card: pe_store::CardId) -> Option<adw::Dialog> {
    let window = main_window();
    glib::spawn_future_local(async move {
        crate::book_dialogs::contact(&window, card).await;
    });
    wait_dialog(10, "contact-dialog").await
}

/// A message from the contact whose provider confirmed the From domain, and a forged one from the same address
async fn add_contact_messages(d: &Driver, inbox: i64) -> bool {
    let message = |subject: &str, id: &str, verdict: &str| {
        format!(
            "Authentication-Results: mx.inboxclassic.test; {verdict}\r\nFrom: Rita Lund <{CONTACT_ADDRESS}>\r\n\
             To: testuser@inboxclassic.test\r\nSubject: {subject}\r\nDate: {}\r\nMessage-ID: <{id}@studio.example>\r\n\
             \r\nThe pictures from Saturday are ready.\r\n",
            super::steps::date_now(0)
        )
    };
    let confirmed = message(
        CONTACT_CONFIRMED,
        "contact-1",
        "dkim=pass header.d=studio.example; dmarc=pass header.from=studio.example",
    );
    let forged = message(
        CONTACT_FORGED,
        "contact-2",
        "dkim=fail header.d=studio.example; dmarc=fail header.from=studio.example",
    );
    let added = d.add_message(&confirmed, &[]).is_ok() && d.add_message(&forged, &[]).is_ok();
    run_command(Command::Sync);
    let read = wait_until(60, || {
        let listed = listed_in_folder(inbox, 0, 500);
        listed.iter().any(|m| m.info.subject == CONTACT_FORGED)
            && listed.iter().any(|m| {
                m.info.subject == CONTACT_CONFIRMED
                    && pe_core::senders::picture(m).0 == pe_core::senders::PictureKind::Contact
            })
    })
    .await;
    added && read
}

/// A contact's picture: chosen in Contact Properties, shown in the Columns list and the reading pane for a message the
/// provider confirmed comes from the contact's domain, initials for a forged one, gone once removed
pub async fn contact_picture(d: &Driver) {
    d.step("a contact's picture");
    let main = shell().main();
    let core = &shell().core;
    let (Some(inbox), Some(png)) = (super::steps::folder_id("Inbox"), contact_png()) else {
        d.check(false, "the Inbox, and a picture file for the contact");
        return;
    };
    let card = pe_store::Card {
        name: "Rita Lund".into(),
        first: "Rita".into(),
        last: "Lund".into(),
        addresses: vec![CONTACT_ADDRESS.into()],
        ..Default::default()
    };
    let Ok(id) = core.save_card(&card) else {
        d.check(false, "a contact to give a picture");
        return;
    };
    let Some(form) = open_contact(id).await else {
        d.check(false, "Contact Properties opens");
        return;
    };
    let f: gtk::Widget = form.clone().upcast();
    d.check(
        !crate::book_dialogs::contact_shows_picture()
            && named_in(&f, "contact-picture-remove").is_none()
            && named_in(&f, "contact-picture-choose").is_some(),
        "Contact Properties shows the contact's initials, with Choose and no Remove",
    );
    crate::ui::FILE_ANSWERS.with(|answers| answers.borrow_mut().push_back(vec![png.clone()]));
    click(&f, "contact-picture-choose");
    d.check(
        wait_until(10, crate::book_dialogs::contact_shows_picture).await
            && named_in(&f, "contact-picture-remove").is_some()
            && core.card_has_picture(id),
        "Choose takes the picture: the well shows it, Remove is offered, and the contact has it",
    );
    // an answer the dialog did not take would be the next file dialog's
    crate::ui::FILE_ANSWERS.with(|answers| answers.borrow_mut().clear());
    pause(400).await;
    d.shot(&form, "contacts-6-picture").await;
    click(&f, "dialog-ok");
    wait_gone(10, "contact-dialog").await;

    select_folder("Inbox");
    wait_until(10, || main.selected_name() == "Inbox").await;
    d.check(
        add_contact_messages(d, inbox).await,
        "a confirmed message and a forged one from the contact are in the Inbox",
    );
    command(Command::LayoutColumns);
    wait_until(10, side_by_side).await;
    // the newest first, the list at its top: the two new messages on screen
    main.list.select(0);
    pause(500).await;
    d.check(
        wait_until(20, || {
            row_on_screen(CONTACT_CONFIRMED).is_some_and(|r| crate::rows::picture_drawn(&r))
        })
        .await,
        "the confirmed message's row shows the contact's picture",
    );
    // once the core has read its verdict, which comes in the background
    d.check(
        wait_until(20, || {
            row_on_screen(CONTACT_FORGED)
                .is_some_and(|r| crate::rows::picture_shown(&r) && !crate::rows::picture_drawn(&r))
        })
        .await,
        "the forged one from the same address shows initials",
    );
    if let Some(uid) = listed_in_folder(inbox, 0, 500)
        .iter()
        .find(|m| m.info.subject == CONTACT_CONFIRMED)
        .map(|m| m.info.uid)
    {
        main.show_message(inbox, uid);
    }
    d.check(
        wait_until(20, || main.reader.logo_shown()).await,
        "the reading pane shows the contact's picture beside the header",
    );
    pause(500).await;
    d.shot(main.window(), "pictures-5-contact").await;

    // removed: the initials again
    if let Some(form) = open_contact(id).await {
        let f: gtk::Widget = form.clone().upcast();
        click(&f, "contact-picture-remove");
        d.check(
            wait_until(10, || !crate::book_dialogs::contact_shows_picture()).await
                && named_in(&f, "contact-picture-remove").is_none()
                && !core.card_has_picture(id),
            "Remove takes the picture away, and the well shows the initials",
        );
        click(&f, "dialog-ok");
        wait_gone(10, "contact-dialog").await;
    }
    d.check(
        wait_until(20, || {
            row_on_screen(CONTACT_CONFIRMED)
                .is_some_and(|r| crate::rows::picture_shown(&r) && !crate::rows::picture_drawn(&r))
        })
        .await,
        "and the list shows the contact's initials again",
    );
    // as the steps after this one expect: the Address Book empty, the messages read, the classic layout
    let _ = core.delete_cards(&[id]);
    for message in listed_in_folder(inbox, 0, 500) {
        if [CONTACT_CONFIRMED, CONTACT_FORGED].contains(&message.info.subject.as_str()) {
            let _ = core.set_seen(inbox, message.info.uid, true);
        }
    }
    command(Command::LayoutClassic);
    wait_until(10, || main.layout() == pe_core::layout::Layout::Classic).await;
    let _ = std::fs::remove_file(png);
}
