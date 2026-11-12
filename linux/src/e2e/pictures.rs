//! Pictures from trusted senders: the pictures bar's Always for a sender the provider confirmed, the line for one it
//! did not, and Preferences' trusted senders and Download pictures in all messages

use super::steps::{date_now, folder_id, open_by_subject};
use super::*;

const CONFIRMED: &str = "Spring sale at the shop";
const FORGED: &str = "Spring sale at the shop, forged";

/// An HTML message from news@shop.example with a picture on the internet, the provider's verdict on it `verdict`
fn sale(subject: &str, id: &str, verdict: &str) -> String {
    format!(
        "Authentication-Results: mx.inboxclassic.test; {verdict}\r\nFrom: Shop <news@shop.example>\r\n\
         To: testuser@inboxclassic.test\r\nSubject: {subject}\r\nDate: {}\r\nMessage-ID: <{id}@shop.example>\r\n\
         MIME-Version: 1.0\r\nContent-Type: text/html; charset=utf-8\r\n\r\n\
         <p>Everything half price this week.</p><img src=\"https://shop.example/banner.png\" alt=\"Sale\">\r\n",
        date_now(-20)
    )
}

async fn add_messages(d: &Driver, inbox: i64) -> bool {
    let confirmed = sale(
        CONFIRMED,
        "sale-confirmed",
        "dkim=pass header.d=shop.example; dmarc=pass header.from=shop.example",
    );
    let forged = sale(
        FORGED,
        "sale-forged",
        "dkim=fail header.d=shop.example; dmarc=fail header.from=shop.example",
    );
    let added = d.add_message(&confirmed, &["\\Seen"]).is_ok() && d.add_message(&forged, &["\\Seen"]).is_ok();
    run_command(Command::Sync);
    let arrived = wait_until(30, || {
        let listed = listed_in_folder(inbox, 0, 500);
        [CONFIRMED, FORGED]
            .iter()
            .all(|subject| listed.iter().any(|m| m.info.subject == *subject))
    })
    .await;
    added && arrived
}

/// The message `subject` shown in the reading pane, another one first so it is shown again
async fn show(inbox: i64, subject: &str) -> bool {
    let other = if subject == CONFIRMED { FORGED } else { CONFIRMED };
    open_by_subject(inbox, other).await;
    open_by_subject(inbox, subject).await
}

pub async fn trusted(d: &Driver) {
    d.step("pictures from a trusted sender");
    let main = shell().main();
    let reader = &main.reader;
    let Some(inbox) = folder_id("Inbox") else {
        d.check(false, "the tree has the Inbox");
        return;
    };
    d.check(
        add_messages(d, inbox).await,
        "two messages from news@shop.example are in the Inbox",
    );
    select_folder("Inbox");
    wait_until(10, || main.selected_name() == "Inbox").await;
    show(inbox, CONFIRMED).await;
    let sender = pe_core::pictures::Sender {
        address: "news@shop.example".into(),
        domain: "shop.example".into(),
        verified: true,
    };
    let words = pe_core::pictures::bar_words(&sender);
    let (choices, line) = reader.pictures_choices();
    d.check(
        reader.pictures_blocked() && choices == [words.always_sender.clone(), words.always_domain.clone()],
        &format!("the bar offers Always for the sender the provider confirmed ({choices:?})"),
    );
    d.check(line.is_empty(), "and says nothing against them");
    reader.open_pictures_menu(true);
    d.shot(main.window(), "pictures-2-trusted").await;
    reader.open_pictures_menu(false);

    show(inbox, FORGED).await;
    let unconfirmed = pe_core::pictures::bar_words(&pe_core::pictures::Sender {
        verified: false,
        ..sender.clone()
    })
    .unconfirmed;
    let (choices, line) = reader.pictures_choices();
    d.check(
        reader.pictures_blocked() && choices.is_empty() && line == unconfirmed,
        &format!("a forged message has Download Pictures only, and says why ({line})"),
    );

    show(inbox, CONFIRMED).await;
    let _ = reader.widget.activate_action("reader.always-domain", None);
    let trusted = wait_until(15, || {
        !reader.pictures_blocked() && reader.has_view() && reader.subject().as_deref() == Some(CONFIRMED)
    })
    .await;
    let listed = shell().core.trusted_senders().unwrap_or_default();
    d.check(
        trusted && listed.iter().any(|s| s.domain && s.value == "shop.example"),
        "Always from everyone at shop.example trusts the domain, and the pictures show without the bar",
    );
    show(inbox, FORGED).await;
    d.check(
        reader.pictures_blocked(),
        "the forged message from the same domain still asks",
    );
    show(inbox, CONFIRMED).await;
    d.check(
        !reader.pictures_blocked(),
        "the confirmed one shows its pictures when opened again",
    );
}

/// Preferences' pictures: the trusted sender listed and removed, then every message's pictures for a while
pub async fn options(d: &Driver) {
    d.step("pictures in Preferences");
    let main = shell().main();
    let Some(inbox) = folder_id("Inbox") else {
        return;
    };
    command(Command::Options);
    let Some(dialog) = wait_dialog(10, "preferences-dialog").await else {
        d.check(false, "Preferences opens");
        return;
    };
    let root: gtk::Widget = dialog.clone().upcast();
    trusted_senders(d, &dialog, &root).await;
    set_always(&root, true);
    d.check(
        shell().core.always_load_pictures().unwrap_or(false),
        "Download pictures in all messages turns the setting on",
    );
    dialog.close();
    wait_gone(10, "preferences-dialog").await;
    show(inbox, FORGED).await;
    d.check(
        !main.reader.pictures_blocked(),
        "with it on, the forged message's pictures show too",
    );

    command(Command::Options);
    if let Some(dialog) = wait_dialog(10, "preferences-dialog").await {
        set_always(dialog.upcast_ref(), false);
        dialog.close();
        wait_gone(10, "preferences-dialog").await;
    }
    show(inbox, FORGED).await;
    d.check(
        !shell().core.always_load_pictures().unwrap_or(true) && main.reader.pictures_blocked(),
        "turned off, the forged message asks again",
    );
}

/// The Trusted senders page: the domain listed, removed with its button, then the page says none is
async fn trusted_senders(d: &Driver, dialog: &adw::Dialog, root: &gtk::Widget) {
    let Some(row) = named_in(root, "preferences-trusted-senders").and_downcast::<adw::ActionRow>() else {
        d.check(false, "Preferences has Trusted senders");
        return;
    };
    row.emit_by_name::<()>("activated", &[]);
    let label = wait_for(10, || {
        named_in(root, "trusted-sender")
            .and_downcast::<adw::ActionRow>()
            .map(|r| r.title().to_string())
    })
    .await
    .unwrap_or_default();
    d.check(
        label == t!(UiTrustedEveryoneAt, domain = "shop.example"),
        &format!("Trusted senders lists the domain ({label})"),
    );
    d.shot(dialog, "pictures-3-options").await;
    click(root, "trusted-sender-remove");
    d.check(
        wait_until(10, || named_in(root, "trusted-senders-empty").is_some()).await
            && shell().core.trusted_senders().is_ok_and(|s| s.is_empty()),
        "its button removes it, and the page says no sender is trusted",
    );
    if let Some(preferences) = dialog.downcast_ref::<adw::PreferencesDialog>() {
        preferences.pop_subpage();
    }
}

fn set_always(root: &gtk::Widget, on: bool) {
    if let Some(row) = named_in(root, "preferences-pictures-always").and_downcast::<adw::SwitchRow>() {
        row.set_active(on);
    }
}
