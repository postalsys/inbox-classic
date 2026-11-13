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
