//! Messages in dark mode: the windows forced dark, as the system's dark style makes them. A plain text message and
//! one written without backgrounds go dark (its too dark text marked to be lightened), a newsletter with backgrounds
//! of its own stays light, a card goes dark, the compose window too (and nothing dark goes into what is sent);
//! Preferences' switch turned off shows the written message light in the dark window. The style and the switch are
//! set back for the steps after.

use super::steps::{date_now, document_text, folder_id, open_by_subject};
use super::*;

const PLAIN: &str = "Dark mode: plain text";
const WRITTEN: &str = "Dark mode: written mail";
const NEWSLETTER: &str = "Dark mode: the autumn sale";
const CODE: &str = "Dark mode: your sign-in code";
const SENT: &str = "Dark mode: written in the dark";

/// The colors pe-html adds for a dark window, none of which may be in mail sent from one
const DARK_MARKS: [&str; 5] = [
    "data-pe-dark",
    "prefers-color-scheme",
    "color-scheme",
    "#1e1f22",
    "#e3e3e6",
];

fn message(subject: &str, id: &str, extra: &str, content_type: &str, body: &str) -> String {
    format!(
        "{extra}From: Sam Rivera <sam@example.com>\r\nTo: testuser@inboxclassic.test\r\nSubject: {subject}\r\n\
         Date: {}\r\nMessage-ID: <{id}@example.com>\r\nMIME-Version: 1.0\r\n\
         Content-Type: {content_type}; charset=utf-8\r\n\r\n{body}\r\n",
        date_now(-30)
    )
}

/// The four messages of the step in the Inbox, read
fn add_messages(d: &Driver) -> bool {
    let plain = message(
        PLAIN,
        "dark-plain",
        "",
        "text/plain",
        "Hi Alex,\r\n\r\nThe tent is packed and the car is full. We leave at seven.\r\n\r\nSam",
    );
    // as Gmail writes it: no backgrounds, one text color of its own that is too dark for a dark window
    let written = message(
        WRITTEN,
        "dark-written",
        "",
        "text/html",
        "<div dir=\"ltr\"><div>Hi Alex,</div><div><br></div><div><span style=\"color:#222222\">Here are the notes \
         from Tuesday. The <b>budget</b> is on the second page.</span></div><div><br></div>\
         <div><a href=\"https://example.com/notes\">Open the notes</a></div><div><br></div><div>Sam</div></div>",
    );
    let newsletter = message(
        NEWSLETTER,
        "dark-newsletter",
        "",
        "text/html",
        "<table width=\"100%\" bgcolor=\"#f1efe9\" cellpadding=\"0\" cellspacing=\"0\"><tr><td align=\"center\">\
         <table width=\"480\" style=\"background-color:#ffffff\" cellpadding=\"24\"><tr><td>\
         <h1 style=\"color:#7a3b12;font-family:Georgia,serif\">The autumn sale</h1>\
         <p style=\"color:#333333\">Everything for the trail, a third off until Sunday.</p>\
         <p><a href=\"https://example.com/sale\" style=\"background-color:#7a3b12;color:#ffffff;padding:8px 16px;\
         text-decoration:none\">Shop the sale</a></p></td></tr></table></td></tr></table>",
    );
    let code = message(
        CODE,
        "dark-code",
        "Authentication-Results: mx.inboxclassic.test; dkim=pass header.d=example.com\r\n",
        "text/plain",
        "Hello,\r\n\r\nYour verification code is 582914.\r\n\r\nIt expires in 10 minutes. If you did not ask for \
         it, ignore this email.",
    )
    .replace(
        "Sam Rivera <sam@example.com>",
        "Example Accounts <no-reply@accounts.example.com>",
    );
    [plain, written, newsletter, code]
        .iter()
        .all(|raw| d.add_message(raw, &["\\Seen"]).is_ok())
}

/// The document of the reading pane once it shows the message `subject` (opened from the Inbox)
async fn open_shown(inbox: i64, subject: &str) -> String {
    if !open_by_subject(inbox, subject).await {
        return String::new();
    }
    shell().main().reader.preview.shown()
}

/// Whether the background painted before a document is the dark one
fn dark_background(view: &webkit::WebView) -> bool {
    let color = view.background_color();
    color == crate::webview::background() && color.red() < 0.5
}

pub(super) async fn dark_messages(d: &Driver) {
    d.step("messages in dark mode");
    let main = shell().main();
    let Some(inbox) = folder_id("Inbox") else {
        d.check(false, "the tree has the Inbox");
        return;
    };
    d.check(
        shell().core.dark_messages() && pe_html::dark(),
        "messages may be dark: the setting is on out of the box, and the app lets documents follow a dark window",
    );
    let added = add_messages(d);
    run_command(Command::Sync);
    let arrived = wait_until(30, || {
        let listed = listed_in_folder(inbox, 0, 500);
        [PLAIN, WRITTEN, NEWSLETTER, CODE]
            .iter()
            .all(|subject| listed.iter().any(|m| m.info.subject == *subject))
    })
    .await;
    d.check(
        added && arrived,
        "a plain, a written, a designed and a code message are in the Inbox",
    );
    select_folder("Inbox");
    wait_until(10, || main.selected_name() == "Inbox").await;

    let styles = adw::StyleManager::default();
    styles.set_color_scheme(adw::ColorScheme::ForceDark);
    d.check(
        wait_until(5, || styles.is_dark()).await,
        "the windows are dark, as the system's dark style makes them",
    );
    d.check(
        gtk::Settings::default().is_some_and(|s| s.property::<bool>("gtk-application-prefer-dark-theme")),
        "GTK says dark to WebKit, whose prefers-color-scheme follows it",
    );
    d.check(
        dark_background(&main.reader.preview.view),
        "the reading pane paints a dark background before its document, nothing flashes white",
    );

    let plain = open_shown(inbox, PLAIN).await;
    d.check(
        plain.contains("content=\"light dark\"") && document_text(&plain).contains("The tent is packed"),
        "a plain text message is shown dark",
    );
    d.shot(main.window(), "dark-1-plain").await;

    let written = open_shown(inbox, WRITTEN).await;
    d.check(
        written.contains("content=\"light dark\"") && written.contains("data-pe-dark"),
        "a message written without backgrounds is shown dark, its too dark text marked to be lightened",
    );
    d.shot(main.window(), "dark-2-written").await;

    let newsletter = open_shown(inbox, NEWSLETTER).await;
    d.check(
        newsletter.contains("content=\"light\"") && !newsletter.contains("data-pe-dark"),
        "a newsletter with backgrounds of its own stays light, as it was designed",
    );
    d.shot(main.window(), "dark-3-newsletter").await;

    let code = open_shown(inbox, CODE).await;
    let card = wait_for(15, || {
        let shown = main.reader.preview.shown();
        document_text(&shown).contains("582914").then_some(shown)
    })
    .await
    .unwrap_or(code);
    d.check(
        document_text(&card).contains("Code from accounts.example.com") && card.contains("prefers-color-scheme"),
        "the card of a one-time code has its dark look",
    );
    d.shot(main.window(), "dark-4-cards").await;

    compose_in_the_dark(d).await;
    switch_off(d, inbox).await;

    // as before for the steps after
    crate::preferences::set_dark_messages(true);
    styles.set_color_scheme(adw::ColorScheme::Default);
    d.check(
        shell().core.dark_messages() && wait_until(5, || !styles.is_dark()).await,
        "the setting and the style are as they were",
    );
    d.check(
        !dark_background(&main.reader.preview.view),
        "and the reading pane paints white again",
    );
}

/// A message written in the dark window: the editor dark, nothing of that in what is sent
async fn compose_in_the_dark(d: &Driver) {
    run_command(Command::NewMail);
    let Some(c) = wait_compose(10).await else {
        d.check(false, "Create Mail opens a compose window in the dark");
        return;
    };
    d.check(
        c.editor.document.shown().contains("light dark") && dark_background(&c.editor.document.view),
        "the editor is dark too, with a dark background before its page",
    );
    c.to.set_text("Dave <dave@example.com>");
    c.subject.set_text(SENT);
    // in bold, so it goes as HTML, where colors could be
    c.editor.focus();
    pause(300).await;
    if let Some(bold) = named_in(c.window.upcast_ref(), "Bold").and_downcast::<gtk::Button>() {
        bold.emit_clicked();
    }
    c.editor
        .type_text("Hi Dave, the photos from the lake are in the shared folder now.");
    pause(500).await;
    d.shot(&c.window, "dark-5-compose").await;
    click(c.window.upcast_ref(), "compose-send");
    let sent = wait_for(30, || d.find("INBOX", &format!("Subject: {SENT}"))).await;
    let raw = sent.as_ref().map(raw_text).unwrap_or_default();
    d.check(
        raw.contains("photos from the lake")
            && raw.contains("Content-Type: text/html")
            && DARK_MARKS.iter().all(|mark| !raw.contains(mark)),
        "what is sent from the dark window carries none of its colors",
    );
}

/// Preferences' switch off: the written message light in the dark window, the background white
async fn switch_off(d: &Driver, inbox: i64) {
    let main = shell().main();
    open_shown(inbox, WRITTEN).await;
    command(Command::Options);
    let Some(dialog) = wait_dialog(10, "preferences-dialog").await else {
        d.check(false, "Preferences opens");
        return;
    };
    let row = named_in(dialog.upcast_ref(), "preferences-dark-messages").and_downcast::<adw::SwitchRow>();
    d.check(
        row.as_ref().is_some_and(|r| r.is_active()),
        "Preferences has the switch for dark messages, on",
    );
    if let Some(row) = row {
        row.set_active(false);
    }
    dialog.close();
    wait_gone(10, "preferences-dialog").await;
    d.check(
        !shell().core.dark_messages() && !pe_html::dark(),
        "turning it off is kept, and documents are light from then on",
    );
    let light = wait_until(15, || {
        let shown = main.reader.preview.shown();
        main.reader.subject().as_deref() == Some(WRITTEN)
            && shown.contains("content=\"light\"")
            && !shown.contains("data-pe-dark")
    })
    .await;
    d.check(
        light && !dark_background(&main.reader.preview.view),
        "the message shown is made again light in the dark window, its background white",
    );
    d.shot(main.window(), "dark-6-switch-off").await;
}
