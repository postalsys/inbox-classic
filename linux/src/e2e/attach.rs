//! Step 8a of the UI test: opening attachments from the strip under the header. A message with a PDF, a program and
//! two more files, and `scripts/ui-e2e/pgp/secure-attachment.eml` (encrypted to the account's key, imported in step
//! 19i), put in the Inbox over ImapKit's API. Opening goes to the test's hook in place of the system's program
//! (`attachments::launch`), so nothing is launched: the test checks the files the core wrote. The messages are taken
//! away at the end.

use super::steps::{folder_id, open_by_subject};
use super::*;
use crate::attachments::{Strip, take_opened};

const FILES: &str = "Files for the trip";
const ENCRYPTED_ID: &str = "<attachment@ui-test.example>";
const FILES_ID: &str = "<files@ui-test.example>";
const PDF: &str = "%PDF-1.4\n% the route of the trip, from the Linux UI test\n";
const LONG_NAME: &str = "Budget for the autumn trip to the northern lakes, final version with every receipt.xlsx";

fn encrypted_raw() -> String {
    let path = Path::new(env!("CARGO_MANIFEST_DIR")).join("../scripts/ui-e2e/pgp/secure-attachment.eml");
    std::fs::read_to_string(path).unwrap_or_default()
}

/// The message with files: a PDF, a program, a spreadsheet with a long name, a picture, and two pages (a browser
/// would run their scripts): one known by its extension, one by what it holds
fn files_raw() -> String {
    let b64 = |bytes: &[u8]| base64::engine::general_purpose::STANDARD.encode(bytes);
    let part = |kind: &str, name: &str, bytes: &[u8]| {
        format!(
            "--files\r\nContent-Type: {kind}; name=\"{name}\"\r\nContent-Disposition: attachment; filename=\"{name}\"\r\n\
             Content-Transfer-Encoding: base64\r\n\r\n{}\r\n",
            b64(bytes)
        )
    };
    format!(
        "From: Ann Example <ann@example.com>\r\nTo: testuser@inboxclassic.test\r\nSubject: {FILES}\r\n\
         Message-ID: {FILES_ID}\r\nDate: {}\r\nMIME-Version: 1.0\r\n\
         Content-Type: multipart/mixed; boundary=\"files\"\r\n\r\n--files\r\nContent-Type: text/plain; charset=utf-8\r\n\r\n\
         Here is everything for the trip: the route, the budget and a photo of the cabin.\r\n{}{}{}{}{}{}--files--\r\n",
        steps::date_now(-5),
        part("application/pdf", "route.pdf", PDF.as_bytes()),
        part("application/octet-stream", "setup.exe", b"MZ not a real program"),
        part(
            "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
            LONG_NAME,
            b"PK a spreadsheet"
        ),
        part("image/jpeg", "cabin.jpg", b"\xff\xd8\xff a picture"),
        part("application/octet-stream", "statement.xht", b"<p>a statement</p>"),
        part(
            "application/octet-stream",
            "statement",
            b"<!DOCTYPE html><html><script>alert(1)</script></html>"
        ),
    )
}

/// The opened files the hook recorded within `seconds`
async fn opened(seconds: u64) -> Vec<PathBuf> {
    let mut found = Vec::new();
    wait_until(seconds, || {
        found.extend(take_opened());
        !found.is_empty()
    })
    .await;
    found
}

/// The file at `path` was written into a private folder of the core's for opening
fn in_private_folder(path: &Path) -> bool {
    let Ok(probe) = shell().core.private_folder("check") else {
        return false;
    };
    let _ = std::fs::remove_dir(&probe);
    let folder = path.parent();
    folder.and_then(|f| f.parent()) == probe.parent()
        && folder
            .and_then(|f| f.file_name())
            .is_some_and(|name| name.to_string_lossy().starts_with("open-"))
}

/// The item of file `index` activated, as a double-click or Enter does
fn activate(strip: &Strip, index: i32) {
    if let Some(child) = strip.flow.child_at_index(index) {
        child.emit_by_name::<()>("activate", &[]);
    }
}

/// A key pressed in the strip as its own key handlers take it
fn press(strip: &Strip, key: gdk::Key, state: gdk::ModifierType) -> bool {
    let controllers = strip.flow.observe_controllers();
    (0..controllers.n_items())
        .filter_map(|i| controllers.item(i).and_downcast::<gtk::EventControllerKey>())
        .any(|keys| {
            keys.emit_by_name::<bool>(
                "key-pressed",
                &[&glib::translate::IntoGlib::into_glib(key), &0u32, &state],
            )
        })
}

/// The item of the menu labelled `label`, and whether it can be chosen
pub(super) fn menu_item_sensitive(popover: &gtk::PopoverMenu, label: &str) -> Option<bool> {
    descendants::<gtk::Widget>(popover.upcast_ref())
        .into_iter()
        .find(|w| w.css_name() == "modelbutton" && descendants::<gtk::Label>(w).iter().any(|l| l.text() == label))
        .map(|w| w.is_sensitive())
}

pub(super) async fn close_menu(strip: &Strip) {
    if let Some(menu) = strip.open_menu() {
        menu.popdown();
    }
    wait_until(5, || strip.open_menu().is_none()).await;
    pause(300).await;
}

pub(super) async fn opening_attachments(d: &Driver) {
    d.step("opening attachments");
    let main = shell().main();
    let Some(inbox) = folder_id("Inbox") else {
        d.check(false, "the tree has the Inbox");
        return;
    };
    let added =
        d.add_message(&files_raw(), &["\\Seen"]).is_ok() && d.add_message(&encrypted_raw(), &["\\Seen"]).is_ok();
    run_command(Command::Sync);
    select_folder("Inbox");
    let arrived = wait_until(30, || {
        listed_in_folder(inbox, 0, 500).iter().any(|m| m.info.subject == FILES)
    })
    .await;
    d.check(added && arrived, "the messages with files are in the Inbox");
    take_opened();

    let strip = &main.reader.strip;
    open_by_subject(inbox, FILES).await;
    let shown = wait_for(10, || Some(strip.shown()).filter(|s| s.len() == 6))
        .await
        .unwrap_or_default();
    d.check(
        strip.widget.is_visible()
            && shown
                .iter()
                .all(|f| !f.name.is_empty() && !f.size.is_empty() && !f.icon.is_empty()),
        &format!("the strip under the header shows each file with its icon, name and size ({shown:?})"),
    );
    d.check(
        shown
            .first()
            .is_some_and(|f| f.name == "route.pdf" && f.icon == "application-pdf")
            && shown.get(1).is_some_and(|f| f.icon == "application-x-executable"),
        "the PDF and the program have their own icons",
    );
    d.check(
        shown
            .get(2)
            .is_some_and(|f| f.tooltip.starts_with(&format!("{LONG_NAME} ("))),
        "a long name is shortened in the strip, the whole of it in the tooltip",
    );
    d.check(
        shown
            .get(1)
            .is_some_and(|f| f.tooltip.contains("setup.exe") && f.tooltip.contains("run programs")),
        "the program's tooltip says Open is off for it",
    );
    d.shot(main.window(), "attach-1-strip").await;

    // double-click: the file the core wrote, in the private folder, byte for byte what was sent
    activate(strip, 0);
    let files = opened(10).await;
    let pdf = files.first().cloned().unwrap_or_default();
    d.check(
        files.len() == 1 && pdf.file_name().is_some_and(|n| n == "route.pdf") && in_private_folder(&pdf),
        &format!("double-clicking the PDF opens it from the private folder ({files:?})"),
    );
    d.check(
        std::fs::read(&pdf).is_ok_and(|bytes| bytes == PDF.as_bytes()),
        "the file opened is byte for byte what was sent",
    );
    // opened again: the same file, no second copy
    activate(strip, 0);
    let again = opened(10).await;
    d.check(
        again == [pdf.clone()],
        &format!("opened again, the same file ({again:?})"),
    );

    // the keyboard: Tab from the paper clip reaches the strip, the arrows move, Enter opens
    let pane: gtk::Widget = main.reader.widget.clone().upcast();
    d.check(
        tab_moves(&pane, "reader-attachments", "reader-strip"),
        "Tab reaches the strip",
    );
    if let Some(first) = strip.flow.child_at_index(0) {
        first.grab_focus();
    }
    for _ in 0..2 {
        strip.flow.emit_by_name::<bool>(
            "move-cursor",
            &[&gtk::MovementStep::VisualPositions, &1i32, &false, &false],
        );
    }
    d.check(
        strip.chosen() == Some(2),
        &format!("the arrow keys move between the files ({:?})", strip.chosen()),
    );
    strip.flow.emit_by_name::<()>("activate-cursor-child", &[]);
    let files = opened(10).await;
    d.check(
        files.len() == 1 && files[0].file_name().is_some_and(|n| n.to_string_lossy() == LONG_NAME),
        &format!("Enter opens the file chosen ({files:?})"),
    );

    // the menu key: Open, Save As..., Save All...
    if let Some(first) = strip.flow.child_at_index(0) {
        first.grab_focus();
    }
    let pressed = press(strip, gdk::Key::Menu, gdk::ModifierType::empty());
    let menu = wait_for(5, || strip.open_menu()).await;
    let labels = menu_labels(menu.as_ref());
    d.check(
        pressed && labels == ["Open", "Save As\u{2026}", "Save All\u{2026}", "Show in Message"],
        &format!("the menu key offers Open, Save As..., Save All... and, for a PDF file, Show in Message ({labels:?})"),
    );
    d.shot(main.window(), "attach-2-menu").await;
    // Save As... from it: the file saved where the dialog said
    let saved = d.out.join("route-saved.pdf");
    let _ = std::fs::remove_file(&saved);
    FILE_ANSWERS.with(|a| a.borrow_mut().push_back(vec![saved.clone()]));
    if let Some(menu) = &menu {
        let _ = WidgetExt::activate_action(menu, "reader.save-attachment", Some(&0u32.to_variant()));
    }
    close_menu(strip).await;
    let content = wait_for(10, || std::fs::read(&saved).ok()).await.unwrap_or_default();
    d.check(content == PDF.as_bytes(), "Save As... in the menu saves the file");

    // the program: Open greyed in its menu (Shift+F10), and opening it says why, with nothing opened
    if let Some(program) = strip.flow.child_at_index(1) {
        program.grab_focus();
    }
    press(strip, gdk::Key::F10, gdk::ModifierType::SHIFT_MASK);
    let menu = wait_for(5, || strip.open_menu()).await;
    let open = menu.as_ref().and_then(|m| menu_item_sensitive(m, "Open"));
    d.check(open == Some(false), &format!("the program's Open is greyed ({open:?})"));
    close_menu(strip).await;
    activate(strip, 1);
    match wait_alert(10).await {
        Some(refused) => {
            let text = alert_text(&refused);
            d.check(
                text.contains("can run programs"),
                &format!("opening the program says it can run programs ({text})"),
            );
            d.shot(main.window(), "attach-3-refused").await;
            answer(&refused, "OK");
        }
        None => d.check(false, "opening the program says why not"),
    }
    pause(500).await;
    d.check(take_opened().is_empty(), "and nothing is opened");

    // pages: Open greyed, and opening one refused naming it, for the one known by its extension and the one known
    // by what it holds
    for (index, name) in [(4, "statement.xht"), (5, "statement")] {
        if let Some(page) = strip.flow.child_at_index(index) {
            page.grab_focus();
        }
        press(strip, gdk::Key::Menu, gdk::ModifierType::empty());
        let menu = wait_for(5, || strip.open_menu()).await;
        let open = menu.as_ref().and_then(|m| menu_item_sensitive(m, "Open"));
        d.check(
            open == Some(false),
            &format!("a page's Open is greyed ({name}: {open:?})"),
        );
        close_menu(strip).await;
        activate(strip, index);
        match wait_alert(10).await {
            Some(refused) => {
                let text = alert_text(&refused);
                d.check(
                    text.contains(&format!("\u{201c}{name}\u{201d}")) && text.contains("can run programs"),
                    &format!("opening {name} is refused, naming it ({text})"),
                );
                answer(&refused, "OK");
            }
            None => d.check(false, &format!("opening {name} says why not")),
        }
    }
    pause(500).await;
    d.check(take_opened().is_empty(), "and no page is opened");

    in_window(d, inbox).await;
    encrypted(d, inbox).await;
    remove_messages(d, inbox).await;
}

/// The message opened in a window of its own: the strip there too, opening the same way
async fn in_window(d: &Driver, inbox: i64) {
    let main = shell().main();
    let row = main
        .list_view()
        .rows(&shell().core, 0, 500)
        .unwrap_or_default()
        .iter()
        .position(|m| m.folder_id == inbox && m.info.subject == FILES);
    let Some(row) = row.and_then(|at| u32::try_from(at).ok()) else {
        d.check(false, "the message with files is listed");
        return;
    };
    main.list.view.emit_by_name::<()>("activate", &[&row]);
    let Some(window) = wait_for(10, || crate::message_window::windows().into_iter().next()).await else {
        d.check(false, "the message with files opens in a window of its own");
        return;
    };
    let strip = &window.reader.strip;
    let shown = wait_for(15, || Some(strip.shown()).filter(|s| s.len() == 6)).await;
    d.check(
        shown.is_some() && strip.widget.is_visible(),
        "a message window has the strip",
    );
    activate(strip, 0);
    let files = opened(10).await;
    d.check(
        files.len() == 1 && std::fs::read(&files[0]).is_ok_and(|bytes| bytes == PDF.as_bytes()),
        &format!("and opens the file the same way ({files:?})"),
    );
    d.shot(&window.window, "attach-5-window").await;
    // many files in a narrow window wrap onto more lines, in dark mode too (for the review of the look)
    let styles = adw::StyleManager::default();
    styles.set_color_scheme(adw::ColorScheme::ForceDark);
    window.window.set_default_size(480, window.window.height());
    wait_until(10, || styles.is_dark() && window.window.width() <= 520).await;
    if let Some(cabin) = strip.flow.child_at_index(3) {
        strip.flow.select_child(&cabin);
    }
    pause(800).await;
    d.check(
        strip
            .flow
            .child_at_index(3)
            .is_some_and(|last| last.compute_bounds(&strip.flow).is_some_and(|b| b.y() > 10.0)),
        "in a narrow window the files wrap onto more lines",
    );
    d.shot(&window.window, "attach-6-narrow-dark").await;
    styles.set_color_scheme(adw::ColorScheme::Default);
    wait_until(5, || !styles.is_dark()).await;
    let _ = WidgetExt::activate_action(&window.window, "window.close", None);
    wait_until(10, || crate::message_window::windows().is_empty()).await;
}

/// The encrypted message's file: the note the first time, the decrypted file opened; no note the second time
async fn encrypted(d: &Driver, inbox: i64) {
    let main = shell().main();
    let strip = &main.reader.strip;
    let row = main
        .list_view()
        .rows(&shell().core, 0, 500)
        .unwrap_or_default()
        .iter()
        .position(|m| m.folder_id == inbox && (m.info.subject == "..." || m.info.subject == "An encrypted file"));
    let Some(row) = row.and_then(|at| u32::try_from(at).ok()) else {
        d.check(false, "the encrypted message with a file is listed");
        return;
    };
    select_row(row).await;
    let shown = wait_for(15, || {
        Some(strip.shown()).filter(|s| s.first().is_some_and(|f| f.name == "plan.txt"))
    })
    .await;
    d.check(shown.is_some(), "the encrypted message's file is in the strip");
    activate(strip, 0);
    match wait_alert(10).await {
        Some(note) => {
            let text = alert_text(&note);
            let expected_note = pe_core::i18n::tr(pe_core::i18n::Text::AttachmentDecryptedNote);
            d.check(
                note.heading().is_some_and(|h| h == "Opening this file") && text.contains(&expected_note),
                &format!("the first time the localized attachment warning is shown ({text})"),
            );
            d.shot(main.window(), "attach-4-encrypted-note").await;
            d.check(
                take_opened().is_empty(),
                "nothing is opened before the note is answered",
            );
            answer(&note, "OK");
        }
        None => d.check(false, "the first time a note says the file is stored decrypted"),
    }
    let files = opened(10).await;
    d.check(
        files.len() == 1
            && in_private_folder(&files[0])
            && std::fs::read_to_string(&files[0]).is_ok_and(|text| text.contains("the secret plan, in a file")),
        &format!("then the decrypted file opens ({files:?})"),
    );
    activate(strip, 0);
    let files = opened(10).await;
    d.check(
        files.len() == 1 && alert().is_none(),
        "the second time it opens without the note",
    );
}

/// The messages of the step taken away from the server and the list
async fn remove_messages(d: &Driver, inbox: i64) {
    for message in d.messages("INBOX") {
        let raw = raw_text(&message);
        if (raw.contains(FILES_ID) || raw.contains(ENCRYPTED_ID))
            && let Some(uid) = message["uid"].as_u64()
        {
            let _ = http(
                d.ports.rest,
                "DELETE",
                &format!("/v1/mailboxes/INBOX/messages/{uid}"),
                None,
            );
        }
    }
    run_command(Command::Sync);
    let gone = wait_until(30, || {
        !listed_in_folder(inbox, 0, 500).iter().any(|m| m.info.subject == FILES)
    })
    .await;
    d.check(gone, "the messages with files are taken away");
}
