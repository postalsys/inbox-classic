//! View > Hide Read Messages and the header bar's filter: the unread messages only, a message read staying listed
//! until the folder changes, and the empty list's words

use super::steps::{date_now, folder_id, open_by_subject};
use super::*;

const UNREAD: [&str; 2] = ["Unread only, first", "Unread only, second"];
const READ: &str = "Unread only, already read";

/// The subjects of the rows the list shows
fn listed_subjects() -> Vec<String> {
    shell()
        .main()
        .list_view()
        .rows(&shell().core, 0, 500)
        .unwrap_or_default()
        .into_iter()
        .map(|m| m.info.subject)
        .collect()
}

fn lists(subject: &str) -> bool {
    listed_subjects().iter().any(|s| s == subject)
}

/// The header bar's filter, on or off
fn filter_on() -> bool {
    named_in(&main_window(), "hide-read")
        .and_downcast::<gtk::ToggleButton>()
        .is_some_and(|b| b.is_active())
}

/// A folder of the first account whose messages are all read, for the empty list
fn folder_all_read() -> Option<(String, i64)> {
    ["Sent Items", "Drafts", "Deleted Items", "Archive"]
        .into_iter()
        .filter_map(|name| folder_id(name).map(|id| (name.to_string(), id)))
        .find(|(_, id)| listed_in_folder(*id, 0, 500).iter().all(|m| m.info.seen()))
}

/// Two unread messages and a read one in the Inbox
async fn add_messages(d: &Driver, inbox: i64) -> bool {
    let message = |subject: &str, id: &str| {
        format!(
            "From: Nora Reed <nora@example.com>\r\nTo: testuser@inboxclassic.test\r\nSubject: {subject}\r\n\
             Date: {}\r\nMessage-ID: <{id}@example.com>\r\n\r\nA note.\r\n",
            date_now(-30)
        )
    };
    let added = d.add_message(&message(UNREAD[0], "unread-only-1"), &[]).is_ok()
        && d.add_message(&message(UNREAD[1], "unread-only-2"), &[]).is_ok()
        && d.add_message(&message(READ, "unread-only-3"), &["\\Seen"]).is_ok();
    run_command(Command::Sync);
    let arrived = wait_until(30, || {
        let listed = listed_in_folder(inbox, 0, 500);
        [UNREAD[0], UNREAD[1], READ]
            .iter()
            .all(|subject| listed.iter().any(|m| m.info.subject == *subject))
    })
    .await;
    added && arrived
}

pub async fn hide_read(d: &Driver) {
    d.step("the unread messages only");
    let main = shell().main();
    let Some(inbox) = folder_id("Inbox") else {
        d.check(false, "the tree has the Inbox");
        return;
    };
    d.check(add_messages(d, inbox).await, "the Inbox has read and unread messages");
    select_folder("Inbox");
    wait_until(10, || main.selected_name() == "Inbox").await;
    wait_until(10, || lists(READ)).await;

    command(Command::HideRead);
    let only_unread = wait_until(10, || lists(UNREAD[0]) && lists(UNREAD[1]) && !lists(READ)).await;
    d.check(
        only_unread && filter_on(),
        "Hide Read Messages lists the unread messages only, and the header bar's filter is on",
    );
    d.shot(main.window(), "list-unread-only").await;

    open_by_subject(inbox, UNREAD[0]).await;
    let read = wait_until(20, || {
        listed_in_folder(inbox, 0, 500)
            .iter()
            .any(|m| m.info.subject == UNREAD[0] && m.info.seen())
    })
    .await;
    pause(1500).await;
    d.check(
        read && lists(UNREAD[0]),
        "a message opened is read, and stays in the list",
    );

    empty_folder(d).await;
    select_folder("Inbox");
    wait_until(10, || main.selected_name() == "Inbox").await;
    d.check(
        wait_until(10, || !lists(UNREAD[0]) && lists(UNREAD[1])).await,
        "after another folder, the message read is no longer listed",
    );

    command(Command::HideRead);
    d.check(
        wait_until(10, || lists(UNREAD[0]) && lists(READ)).await && !filter_on(),
        "turned off, every message is listed again",
    );
    // read, so the steps after this one find the Inbox's unread messages as they were
    for message in listed_in_folder(inbox, 0, 500) {
        if message.info.subject == UNREAD[1] {
            let _ = shell().core.set_seen(inbox, message.info.uid, true);
        }
    }
}

/// A folder with nothing unread says so in the middle of the list
async fn empty_folder(d: &Driver) {
    let Some((name, _)) = folder_all_read() else {
        return;
    };
    select_folder(&name);
    let main = shell().main();
    wait_until(10, || main.selected_name() == name).await;
    let says = t!(UiNoUnread);
    let shown = wait_until(10, || {
        rows() == 0
            && descendants::<gtk::Label>(&main_window())
                .iter()
                .any(|l| l.is_mapped() && l.text() == says)
    })
    .await;
    d.check(shown, &format!("{name} with nothing unread says: {says}"));
}
