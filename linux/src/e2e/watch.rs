//! Step 34g of the UI test: Watch and Ignore Conversation. The conversation of 34e watched (its glasses, the menu's
//! check mark, a new reply announced as in a watched conversation) and no longer; another conversation ignored (grey,
//! the muted sign, read on the server, a new reply arriving read without a notification) and hidden by View > Hide
//! Ignored Conversations.

use super::steps::date_now;
use super::*;
use crate::messages::{IGNORED_ICON, WATCHED_ICON};

const TRIP: &str = "Plans for the trip";
const FOOTBALL: &str = "Fantasy football picks";

/// The row of the conversation whose first message has `subject`, and that message
fn head_of(subject: &str) -> Option<(u32, pe_store::Message)> {
    let main = shell().main();
    main.list_view()
        .rows(&shell().core, 0, 500)
        .ok()?
        .into_iter()
        .enumerate()
        .find(|(_, m)| m.info.subject == subject && m.thread.is_some_and(|t| t.depth == 0))
        .map(|(at, m)| (at as u32, m))
}

/// How many rows on screen show the mark `icon` in the Watch column
fn marks(icon: &str) -> usize {
    let view: gtk::Widget = shell().main().list.view.clone().upcast();
    descendants::<gtk::Image>(&view)
        .iter()
        .filter(|i| i.is_mapped() && i.icon_name().as_deref() == Some(icon))
        .count()
}

/// Whether the menu item of `command` has its check mark
fn checked(command: Command) -> bool {
    shell()
        .main()
        .window()
        .action_state(command.name())
        .and_then(|v| v.get::<bool>())
        == Some(true)
}

/// The notifications of new mail sent so far, as (title, text)
fn notified() -> Vec<(String, String)> {
    crate::notify::SENT.with(|sent| sent.borrow().clone())
}

/// The grey of the subject cells of `subject` on screen (an ignored conversation's)
fn grey(subject: &str) -> bool {
    let view: gtk::Widget = shell().main().list.view.clone().upcast();
    let labels: Vec<gtk::Label> = descendants::<gtk::Label>(&view)
        .into_iter()
        .filter(|l| l.is_mapped() && l.text().starts_with(subject))
        .collect();
    !labels.is_empty()
        && labels
            .iter()
            .all(|l| l.parent().is_some_and(|cell| cell.has_css_class("dim-label")))
}

fn reply(id: &str, from: &str, subject: &str, refs: &[&str], minutes: i32, text: &str) -> String {
    let threading = match refs.last() {
        Some(parent) => format!("In-Reply-To: {parent}\r\nReferences: {}\r\n", refs.join(" ")),
        None => String::new(),
    };
    format!(
        "From: {from}\r\nTo: testuser@inboxclassic.test\r\nSubject: {subject}\r\nMessage-ID: {id}\r\n{threading}\
         Date: {}\r\n\r\n{text}\r\n",
        date_now(minutes)
    )
}

/// New mail put into the Inbox on the server while the window is hidden (a notification is only sent then), synced
/// until `arrived`; the window back in front
async fn while_hidden(d: &Driver, raw: &str, arrived: impl FnMut() -> bool) -> bool {
    let main = shell().main();
    main.window().set_visible(false);
    let added = d.add_message_to("INBOX", raw).is_ok();
    run_command(Command::Sync);
    let came = wait_until(30, arrived).await;
    // a moment for a notification that would follow it
    pause(1000).await;
    shell().show_main();
    pause(500).await;
    added && came
}

pub async fn watch_and_ignore(d: &Driver) {
    d.step("watch and ignore conversation");
    let main = shell().main();
    let notify_was = shell().notify.get();
    shell().set_notify(true);
    select_folder("Inbox");
    wait_until(10, || main.selected_name() == "Inbox").await;
    let list_view: gtk::Widget = main.list.view.clone().upcast();

    // Watch Conversation on the conversation of 34e
    let Some((at, _)) = wait_for(20, || head_of(TRIP)).await else {
        d.check(false, "the Inbox lists the conversation of 34e");
        return;
    };
    select_row(at).await;
    run_command(Command::WatchConversation);
    let watched = wait_until(10, || {
        checked(Command::WatchConversation)
            && marks(WATCHED_ICON) == 1
            && head_of(TRIP).is_some_and(|(_, m)| m.mark == pe_core::ThreadMark::Watch)
    })
    .await;
    d.check(
        watched && !checked(Command::IgnoreConversation),
        "Watch Conversation shows the glasses in the Watch column and checks the menu item",
    );
    let width = f64::from(list_view.width());
    main.command_menu_at("message", &list_view, width - 160.0, 24.0);
    pause(400).await;
    d.shot(main.window(), "threads-4-watch").await;
    if let Some(popover) = main.message_popover.borrow().as_ref() {
        popover.popdown();
    }

    // a new reply to it, announced as in a watched conversation
    let before = notified().len();
    let refs = ["<trip1@example.com>", "<trip2@example.com>", "<trip3@example.com>"];
    let raw = reply(
        "<trip4@example.com>",
        "Ann Example <ann@example.com>",
        &format!("Re: {TRIP}"),
        &refs,
        3,
        "Window seats, please.",
    );
    let came = while_hidden(d, &raw, || {
        head_of(TRIP).is_some_and(|(_, m)| m.thread.is_some_and(|t| t.count == 4))
    })
    .await;
    let said = notified().into_iter().skip(before).collect::<Vec<_>>();
    d.check(
        came && said
            .iter()
            .any(|(title, text)| *title == t!(UiWatchedConversation) && text.contains(&format!("Re: {TRIP}"))),
        &format!("a new reply to the watched conversation is announced, saying so ({said:?})"),
    );

    // Watch Conversation again: the glasses go
    select_folder("Inbox");
    if let Some((at, _)) = head_of(TRIP) {
        select_row(at).await;
    }
    run_command(Command::WatchConversation);
    d.check(
        wait_until(10, || {
            !checked(Command::WatchConversation)
                && marks(WATCHED_ICON) == 0
                && head_of(TRIP).is_some_and(|(_, m)| m.mark == pe_core::ThreadMark::None)
        })
        .await,
        "Watch Conversation again takes the glasses away",
    );

    // another conversation, unread, ignored with K in the list
    let first = reply(
        "<football1@example.com>",
        "Chris Lane <chris@example.com>",
        FOOTBALL,
        &[],
        4,
        "My team for this week is in.",
    );
    let second = reply(
        "<football2@example.com>",
        "Dana Fox <dana@example.com>",
        &format!("Re: {FOOTBALL}"),
        &["<football1@example.com>"],
        5,
        "Bold choices.",
    );
    let added = d.add_message_to("INBOX", &first).is_ok() && d.add_message_to("INBOX", &second).is_ok();
    run_command(Command::Sync);
    let listed = wait_for(30, || {
        head_of(FOOTBALL).filter(|(_, m)| m.thread.is_some_and(|t| t.count == 2))
    })
    .await;
    d.check(
        added && listed.is_some(),
        "another conversation of two unread messages is put into the Inbox",
    );
    let Some((at, _)) = listed else { return };
    select_row(at).await;
    let key = crate::mailbox::list_key(gdk::Key::k, gdk::ModifierType::empty());
    d.check(
        key == Some(Command::IgnoreConversation),
        "K in the list is Ignore Conversation",
    );
    run_command(Command::IgnoreConversation);
    let ignored = wait_until(10, || {
        checked(Command::IgnoreConversation) && marks(IGNORED_ICON) == 1 && grey(FOOTBALL)
    })
    .await;
    d.check(
        ignored,
        "Ignore Conversation turns its row grey, with the ignored sign in the Watch column, and checks the menu item",
    );
    let read = wait_until(20, || {
        d.seen("Message-ID: <football1@example.com>") && d.seen("Message-ID: <football2@example.com>")
    })
    .await;
    d.check(read, "and marks its messages read on the server");

    // a new reply to it: read on the server, no notification
    let before = notified().len();
    let raw = reply(
        "<football3@example.com>",
        "Chris Lane <chris@example.com>",
        &format!("Re: {FOOTBALL}"),
        &["<football1@example.com>", "<football2@example.com>"],
        6,
        "Bench the goalkeeper.",
    );
    let came = while_hidden(d, &raw, || {
        head_of(FOOTBALL).is_some_and(|(_, m)| m.thread.is_some_and(|t| t.count == 3))
            && d.seen("Message-ID: <football3@example.com>")
    })
    .await;
    let said = notified().into_iter().skip(before).collect::<Vec<_>>();
    d.check(
        came && said.is_empty(),
        &format!(
            "a new reply to the ignored conversation arrives read on the server, without a notification ({said:?})"
        ),
    );

    // the picture: the grey row beside the others, the View menu with Hide Ignored Conversations
    select_folder("Inbox");
    if let Some((at, _)) = head_of(TRIP) {
        select_row(at).await;
    }
    wait_until(5, || grey(FOOTBALL)).await;
    main.command_menu_at("view", &list_view, width - 160.0, 24.0);
    pause(400).await;
    d.shot(main.window(), "threads-5-ignore").await;
    if let Some(popover) = main.message_popover.borrow().as_ref() {
        popover.popdown();
    }

    // View > Hide Ignored Conversations
    let shown = rows();
    run_command(Command::HideIgnored);
    let hidden = wait_until(10, || {
        checked(Command::HideIgnored) && head_of(FOOTBALL).is_none() && rows() + 1 == shown
    })
    .await;
    d.check(
        hidden && main.list_view().hide_ignored(),
        "Hide Ignored Conversations leaves the ignored conversation out of the list",
    );
    run_command(Command::HideIgnored);
    d.check(
        wait_until(10, || {
            !checked(Command::HideIgnored) && head_of(FOOTBALL).is_some() && rows() == shown
        })
        .await,
        "turned off again, it is back",
    );
    shell().set_notify(notify_was);
}
