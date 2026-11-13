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
