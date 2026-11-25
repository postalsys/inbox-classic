//! Emoji reactions: a Gmail reaction to a message here taken out of the Inbox (read on the server), announced as a
//! reaction, shown as a badge on the message's row and as a chip on its Reactions row, whose menu opens the reaction's
//! email or shows it as an email again

use super::steps::{date_now, folder_id, open_by_subject};
use super::*;

const ORIGINAL: &str = "Furniture";
const REPLY: &str = "Re: Furniture";
const REACTION_ID: &str = "reaction-furniture@example.com";
const KATE: &str = "\u{1F44D} Kate Kalda";
/// Bart, in Cc of Kate's message, whose ❤️ comes first; his long name is cut short on his chip
const BART: (&str, &str) = ("Bartholomew Featherstonehaugh-Vandersloot", "bart@example.com");

/// Kate's message, which she reacts to later
fn original() -> String {
    format!(
        "From: Kate Kalda <kate@example.com>\r\nTo: testuser@inboxclassic.test\r\nCc: {} <{}>\r\n\
         Subject: {ORIGINAL}\r\nDate: {}\r\nMessage-ID: <furniture@example.com>\r\nMIME-Version: 1.0\r\n\
         Content-Type: text/plain; charset=utf-8\r\n\r\nThe sofa and the two chairs are yours if you want them.\r\n",
        BART.0,
        BART.1,
        date_now(-90)
    )
}

/// A reaction of `name` <`address`> with `emoji`, as Gmail sends one: the emoji in words, Gmail's own part, and the
/// HTML; signed by their domain
fn reaction(name: &str, address: &str, id: &str, emoji: &str) -> String {
    format!(
        "Authentication-Results: mx.inboxclassic.test; dkim=pass header.d=example.com\r\n\
         From: {name} <{address}>\r\nTo: testuser@inboxclassic.test\r\nSubject: {REPLY}\r\n\
         Date: {}\r\nMessage-ID: <{id}>\r\nIn-Reply-To: <furniture@example.com>\r\n\
         References: <furniture@example.com>\r\nMIME-Version: 1.0\r\n\
         Content-Type: multipart/alternative; boundary=\"r\"\r\n\r\n\
         --r\r\nContent-Type: text/plain; charset=\"UTF-8\"\r\n\r\n{emoji}\r\n\r\n{name} reacted via Gmail\r\n\
         --r\r\nContent-Type: text/vnd.google.email-reaction+json; charset=\"UTF-8\"\r\n\r\n\
         {{\r\n  \"emoji\": \"{emoji}\",\r\n  \"version\": 1\r\n}}\r\n\
         --r\r\nContent-Type: text/html; charset=\"UTF-8\"\r\n\r\n<div>{emoji}</div><p>{name} reacted via Gmail</p>\r\n\
         --r--\r\n",
        date_now(0)
    )
}

/// Kate's reply listed in the Inbox (Bart's stays a reaction)
fn kate_listed(inbox: i64) -> bool {
    listed_in_folder(inbox, 0, 500)
        .iter()
        .any(|m| m.info.subject == REPLY && m.info.from_address == "kate@example.com")
}

/// The Inbox's message with `subject`, one row a message
fn listed(inbox: i64, subject: &str) -> Option<pe_store::Message> {
    listed_in_folder(inbox, 0, 500)
        .into_iter()
        .find(|m| m.info.subject == subject)
}

/// The badge the list draws: a label on screen in the list with exactly `badge`
fn badge_drawn(badge: &str) -> bool {
    let main = shell().main();
    let list = main.list.shown();
    descendants::<gtk::Label>(&list)
        .into_iter()
        .any(|label| label.is_mapped() && label.text() == badge)
}

/// The words of a chip of the Reactions row
fn chip_text(chip: &gtk::MenuButton) -> String {
    chip.child()
        .and_downcast::<gtk::Label>()
        .map(|label| label.text().to_string())
        .unwrap_or_default()
}

/// The badge and the chip in the dark style and in the Columns layout, for their screenshots; back as they were after
async fn other_looks(d: &Driver, badge: &str) {
    let main = shell().main();
    let styles = adw::StyleManager::default();
    styles.set_color_scheme(adw::ColorScheme::ForceDark);
    wait_until(5, || styles.is_dark()).await;
    d.shot(main.window(), "reactions-2-header-dark").await;
    styles.set_color_scheme(adw::ColorScheme::Default);
    wait_until(5, || !styles.is_dark()).await;
    command(Command::LayoutColumns);
    let columns = wait_until(10, || main.list.columns_shown()).await;
    // Furniture, selected, in sight in a list of many messages
    wait_list_settled().await;
    if let Some((at, _)) = main.list.selected() {
        main.list.scroll_to(at, gtk::ListScrollFlags::NONE);
    }
    d.check(
        columns && wait_until(10, || badge_drawn(badge)).await,
        "in the Columns layout too, the row of Furniture shows the badge after its subject",
    );
    d.shot(main.window(), "reactions-2-columns").await;
    command(Command::LayoutClassic);
    wait_until(10, || !main.list.columns_shown()).await;
    wait_list_settled().await;
}

pub async fn reactions(d: &Driver) {
    d.step("emoji reactions");
    let main = shell().main();
    let Some(inbox) = folder_id("Inbox") else {
        d.check(false, "the tree has the Inbox");
        return;
    };
    select_folder("Inbox");
    wait_until(10, || main.selected_name() == "Inbox").await;
    let added = d.add_message(&original(), &["\\Seen"]).is_ok();
    run_command(Command::Sync);
    let arrived = wait_until(30, || listed(inbox, ORIGINAL).is_some()).await;
    d.check(added && arrived, "Kate's message Furniture is in the Inbox");
    // Bart's ❤️ first, while the window is shown
    let bart = reaction(BART.0, BART.1, "reaction-bart@example.com", "\u{2764}\u{FE0F}");
    let added = d.add_message(&bart, &[]).is_ok();
    run_command(Command::Sync);
    d.check(
        added && wait_until(30, || listed(inbox, ORIGINAL).is_some_and(|m| !m.reactions.is_empty())).await,
        "Bart's reaction is taken as a reaction to Furniture",
    );

    // the reaction comes while the window is hidden, so it is announced
    let notify_was = shell().notify.get();
    shell().set_notify(true);
    let before = watch::notified().len();
    let kate = reaction("Kate Kalda", "kate@example.com", REACTION_ID, "\u{1F44D}");
    let came = watch::while_hidden(d, &kate, || {
        listed(inbox, ORIGINAL).is_some_and(|m| m.reactions.len() == 2)
    })
    .await;
    shell().set_notify(notify_was);
    d.check(came, "her Gmail reaction is taken as a reaction to Furniture");
    d.check(
        listed(inbox, REPLY).is_none(),
        "the reaction emails are not listed in the Inbox",
    );
    d.check(
        wait_until(10, || d.seen(REACTION_ID)).await,
        "the reaction email is marked read on the server",
    );
    let said: Vec<(String, String)> = watch::notified().into_iter().skip(before).collect();
    d.check(
        said.iter().any(|(title, text)| {
            title.contains("Kate Kalda") && title.contains('\u{1F44D}') && text.contains(ORIGINAL)
        }),
        &format!("the notification says Kate Kalda reacted 👍 to Furniture ({said:?})"),
    );
    let badge = listed(inbox, ORIGINAL)
        .map(|m| pe_core::reactions::badge(&m.reactions))
        .unwrap_or_default();
    d.check(
        badge.contains('\u{1F44D}') && badge.contains('\u{2764}') && badge.ends_with(" 2"),
        &format!("the core's badge has both emoji and the count ({badge})"),
    );
    d.check(
        wait_until(10, || badge_drawn(&badge)).await,
        "the row of Furniture shows the badge after its subject",
    );
    d.shot(main.window(), "reactions-1-list").await;

    // the reading pane's Reactions row
    if !open_by_subject(inbox, ORIGINAL).await {
        d.check(false, "Furniture opens in the reading pane");
        return;
    }
    let chips = wait_for(10, || {
        let chips = main.reader.reaction_chips();
        (!chips.is_empty()).then_some(chips)
    })
    .await
    .unwrap_or_default();
    let texts: Vec<String> = chips.iter().map(chip_text).collect();
    let bart = format!("\u{2764}\u{FE0F} {}", BART.0);
    d.check(
        texts == [bart.as_str(), KATE],
        &format!("the reading pane has a Reactions row with a chip a person, \"👍 Kate Kalda\" last ({texts:?})"),
    );
    let cut = chips
        .first()
        .and_then(|c| c.child())
        .and_downcast::<gtk::Label>()
        .and_then(|label| label.layout().is_ellipsized().then_some(()));
    d.check(cut.is_some(), "Bart's long name is cut short on his chip");
    d.shot(main.window(), "reactions-2-header").await;
    other_looks(d, &badge).await;
    let chips = main.reader.reaction_chips();
    let Some(index) = chips.iter().position(|c| chip_text(c) == KATE) else {
        return;
    };
    let chip = &chips[index];
    let tip = chip.tooltip_text().map(|t| t.to_string()).unwrap_or_default();
    d.check(
        tip == KATE && chip.first_child().is_some_and(|button| button.is_focusable()),
        &format!("the chip is reached with Tab and its tooltip has its words ({tip})"),
    );

    // its menu: Open Reaction Email, Show as Email, and when
    chip.popup();
    let popover = wait_for(5, || chip.popover().filter(|p| p.is_mapped())).await;
    let items: Vec<String> = popover
        .as_ref()
        .map(|p| {
            descendants::<gtk::Label>(p.upcast_ref())
                .into_iter()
                .filter(|l| l.is_mapped())
                .map(|l| l.text().to_string())
                .collect()
        })
        .unwrap_or_default();
    let when = items.iter().find(|i| i.starts_with("Reacted ")).cloned();
    d.check(
        items.contains(&t!(UiReactionOpenEmail)) && items.contains(&t!(UiReactionShowAsEmail)) && when.is_some(),
        &format!("the chip's menu has Open Reaction Email, Show as Email and when she reacted ({items:?})"),
    );
    d.shot(main.window(), "reactions-3-menu").await;
    if let Some(popover) = &popover {
        popover.popdown();
    }

    // Open Reaction Email: the hidden email in a message window
    let _ = chip.activate_action("reader.reaction-open", Some(&(index as u32).to_variant()));
    let window = wait_for(15, || {
        crate::message_window::windows()
            .into_iter()
            .find(|w| w.window.title().as_deref() == Some(REPLY))
    })
    .await;
    d.check(
        window.as_ref().is_some_and(|w| w.reader.has_view()),
        "Open Reaction Email opens the reaction's email in a message window",
    );
    if let Some(window) = window {
        window.window.close();
        wait_until(5, || !window.window.is_visible()).await;
    }

    // Show as Email: Kate's reply listed again, her chip gone, Bart's kept
    let _ = chip.activate_action("reader.reaction-show", Some(&(index as u32).to_variant()));
    d.check(
        wait_until(30, || kate_listed(inbox)).await,
        "Show as Email lists Kate's reaction email in the Inbox again",
    );
    d.check(
        wait_until(10, || {
            let texts: Vec<String> = main.reader.reaction_chips().iter().map(chip_text).collect();
            texts == [bart.as_str()]
        })
        .await,
        "and her chip is gone from the Reactions row, Bart's stays",
    );
    d.check(
        wait_until(10, || badge_drawn("\u{2764}\u{FE0F}")).await,
        "and the badge of Furniture shows only his",
    );
    d.shot(main.window(), "reactions-4-shown-as-email").await;
}
