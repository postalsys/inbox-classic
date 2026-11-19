//! Step 19i of the UI test: signed and encrypted mail. The keys of `scripts/ui-e2e/pgp/` imported in Encryption Keys,
//! each `secure-*.eml` put in the Inbox over ImapKit's API: the security bar's words, tone and pictures, the frames of
//! the parts each as tall as its document (read back with the app's own script, page scripts off), Details from the
//! bar and from a part's label, the pictures bar of an encrypted message, a long part growing, the dark look; then the
//! messages taken away.

use super::steps::{document_text, folder_id, open_by_subject};
use super::*;
use super::{attach, previews};

/// The subjects of the fixtures, as the list shows them (an encrypted subject is "...")
const SIGNED: &str = "Signed by Alice";
const ENCRYPTED: &str = "...";
const MIXED: &str = "Parts signed apart";
const BAD: &str = "A changed text";
const WRONG_SIGNER: &str = "Signed by someone else";
const NO_KEY: &str = "A key you do not have";
const FAKE: &str = "A painted frame";
const INLINE: &str = "Inline encrypted";
const PICTURES: &str = "Encrypted with a picture";
const LONG: &str = "A long encrypted message";

const FILES: [&str; 10] = [
    "secure-signed.eml",
    "secure-encrypted.eml",
    "secure-mixed.eml",
    "secure-bad.eml",
    "secure-wrong-signer.eml",
    "secure-no-key.eml",
    "secure-fake-frame.eml",
    "secure-inline.eml",
    "secure-pictures.eml",
    "secure-long.eml",
];

pub(super) fn fixture(name: &str) -> PathBuf {
    Path::new(env!("CARGO_MANIFEST_DIR"))
        .join("../scripts/ui-e2e/pgp")
        .join(name)
}

pub(super) fn read_fixture(name: &str) -> String {
    std::fs::read_to_string(fixture(name)).unwrap_or_default()
}

/// The Message-ID of a fixture, by which it is found on the server to be taken away
pub(super) fn message_id(raw: &str) -> String {
    raw.lines()
        .find_map(|line| line.strip_prefix("Message-ID:"))
        .map(|id| id.trim().to_string())
        .unwrap_or_default()
}

/// The words, tone and pictures of the bar of the message shown; None when there is no bar
fn bar() -> Option<(String, String, Vec<String>)> {
    shell().main().reader.security.shown()
}

/// The message `subject` shown, another one first so it is shown again; its bar once it is there
async fn show(inbox: i64, subject: &str, other: &str) -> Option<(String, String, Vec<String>)> {
    let reader = &shell().main().reader;
    open_by_subject(inbox, other).await;
    wait_until(15, || reader.has_view()).await;
    open_by_subject(inbox, subject).await;
    wait_until(15, || reader.has_view()).await;
    wait_for(10, bar).await
}

/// The frames of the page shown, each as its height, its document's and the length of its text, read with the app's
/// own script
async fn frames() -> Vec<(i64, i64, i64)> {
    let script = "(function(){return Array.from(document.querySelectorAll('iframe.pe-d')).map(function(f){\
        var d=f.contentDocument;return f.offsetHeight+'/'+(d&&d.documentElement?d.documentElement.scrollHeight:-1)+'/'+(d&&d.body?d.body.textContent.length:0)})\
        .join(',')})()";
    let view = shell().main().reader.preview.view.clone();
    let Ok(value) = view.evaluate_javascript_future(script, None, None).await else {
        return Vec::new();
    };
    value
        .to_str()
        .split(',')
        .filter_map(|pair| {
            let mut values = pair.split('/').map(|v| v.parse::<i64>().ok());
            Some((values.next()??, values.next()??, values.next()??))
        })
        .collect()
}

/// Waits for `count` frames, each with its document's text and as tall as it; what they are at the end
async fn measured(count: usize) -> (bool, Vec<(i64, i64, i64)>) {
    let deadline = Instant::now() + Duration::from_secs(10);
    loop {
        let found = frames().await;
        let fits = found.len() == count
            && found
                .iter()
                .all(|(shown, document, text)| shown >= document && *text > 0);
        if fits || Instant::now() > deadline {
            return (fits, found);
        }
        pause(250).await;
    }
}

/// The document's words: the labels and the text of each part
fn shown_text() -> String {
    document_text(&shell().main().reader.preview.shown_with_parts())
}

/// The bar of the message shown says `words`, in `tone`, with `pictures`; its frames number `count`, each as tall as
/// its document
async fn check_bar(d: &Driver, what: &str, words: &str, tone: &str, pictures: &[&str], count: usize) {
    let (text, shown_tone, shown_pictures) = bar().unwrap_or_default();
    let names: Vec<String> = pictures.iter().map(|p| format!("ic-{p}-symbolic")).collect();
    d.check(
        text.contains(words) && shown_tone == tone && shown_pictures == names,
        &format!("{what}: the bar is {tone} with {pictures:?} and says \"{words}\" ({shown_tone}, {shown_pictures:?}: {text})"),
    );
    let (fits, found) = measured(count).await;
    d.check(
        fits,
        &format!("{count} frame(s), each as tall as its document ({found:?})"),
    );
}

/// The keys of the fixtures in Encryption Keys: the account's (with its passphrase), Alice's and Mallory's
async fn import_keys(d: &Driver) {
    let Some(keys) = keys::open_keys(d).await else { return };
    FILE_ANSWERS.with(|a| a.borrow_mut().push_back(vec![fixture("me.asc")]));
    click(&keys, "keys-import");
    match wait_dialog(10, "key-import-dialog").await {
        Some(ask) => {
            let passphrase = read_fixture("me.passphrase");
            set_text(ask.upcast_ref(), "key-import-passphrase", passphrase.trim());
            click(ask.upcast_ref(), "dialog-ok");
        }
        None => d.check(false, "the account's key asks for its passphrase"),
    }
    // what Import says, and whether to use the key for the account's address
    while let Some(said) = wait_alert(5).await {
        let text = alert_text(&said);
        answer(&said, if text.contains("Use this key") { "Use" } else { "OK" });
    }
    for name in ["alice.asc", "mallory.asc"] {
        FILE_ANSWERS.with(|a| a.borrow_mut().push_back(vec![fixture(name)]));
        click(&keys, "keys-import");
        if let Some(said) = wait_alert(10).await {
            answer(&said, "OK");
        }
    }
    let imported = || {
        let listed = keys::keys_listed(&keys);
        ["Alice Example", "Mallory"]
            .iter()
            .all(|name| listed.iter().any(|row| row.contains(name)))
            && listed.len() >= 3
    };
    let all = wait_until(10, imported).await;
    let listed = keys::keys_listed(&keys);
    d.check(
        all,
        &format!("the account's key, Alice's and Mallory's are imported ({listed:?})"),
    );
    keys::close_keys(&keys).await;
}

/// Alice's key verified (They Match), as in Encryption Keys
async fn verify_alice(d: &Driver) {
    let Some(keys) = keys::open_keys(d).await else { return };
    keys::select_key(&keys, "Alice Example");
    click(&keys, "keys-verify");
    match wait_alert(10).await {
        Some(verify) => {
            answer(&verify, "Match");
        }
        None => d.check(false, "Verify opens for Alice's key"),
    }
    let verified = wait_until(5, || {
        keys::keys_listed(&keys)
            .iter()
            .any(|row| row.contains("Alice Example") && row.contains("verified"))
    })
    .await;
    d.check(verified, "Alice's key is verified");
    keys::close_keys(&keys).await;
}

/// The fixtures put in the Inbox, and listed there
async fn add_messages(d: &Driver, inbox: i64) -> bool {
    let added = FILES
        .iter()
        .all(|name| d.add_message(&read_fixture(name), &["\\Seen"]).is_ok());
    run_command(Command::Sync);
    let arrived = wait_until(30, || {
        let listed = listed_in_folder(inbox, 0, 500);
        [SIGNED, MIXED, BAD, WRONG_SIGNER, NO_KEY, FAKE, INLINE, PICTURES, LONG]
            .iter()
            .all(|subject| listed.iter().any(|m| m.info.subject == *subject))
    })
    .await;
    added && arrived
}

/// The fixtures taken away from the server and the list
async fn remove_messages(d: &Driver, inbox: i64) {
    let ids: Vec<String> = FILES.iter().map(|name| message_id(&read_fixture(name))).collect();
    for message in d.messages("INBOX") {
        let raw = raw_text(&message);
        if ids.iter().any(|id| !id.is_empty() && raw.contains(id.as_str()))
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
        !listed_in_folder(inbox, 0, 500)
            .iter()
            .any(|m| m.info.subject == SIGNED || m.info.subject == LONG)
    })
    .await;
    d.check(gone, "the signed and encrypted messages are taken away");
}

pub(super) async fn signed_and_encrypted(d: &Driver) {
    d.step("signed and encrypted mail");
    let main = shell().main();
    let Some(inbox) = folder_id("Inbox") else {
        d.check(false, "the tree has the Inbox");
        return;
    };
    import_keys(d).await;
    d.check(
        add_messages(d, inbox).await,
        "the signed and encrypted messages are in the Inbox",
    );
    select_folder("Inbox");
    wait_until(10, || main.selected_name() == "Inbox").await;

    show(inbox, SIGNED, LONG).await;
    check_bar(
        d,
        "signed, the key not verified",
        "Signed by alice@example.org (key not verified)",
        "good",
        &["ribbon"],
        1,
    )
    .await;
    d.check(
        shown_text().contains("Signed by alice@example.org (key not verified)"),
        "the part is labelled the same",
    );
    keyboard(d);
    d.shot(main.window(), "secure-2-signed-unverified").await;

    verify_alice(d).await;
    show(inbox, SIGNED, LONG).await;
    check_bar(
        d,
        "signed, the key verified",
        "Signed by alice@example.org, key verified",
        "verified",
        &["shield-checkmark"],
        1,
    )
    .await;
    d.shot(main.window(), "secure-1-verified").await;

    show(inbox, ENCRYPTED, SIGNED).await;
    check_bar(
        d,
        "encrypted",
        "Encrypted. Signed by alice@example.org, key verified",
        "verified",
        &["lock-closed", "shield-checkmark"],
        1,
    )
    .await;
    d.check(shown_text().contains("old mill"), "the decrypted text is shown");
    d.shot(main.window(), "secure-3-encrypted").await;
    in_window(d, inbox).await;

    show(inbox, MIXED, SIGNED).await;
    check_bar(
        d,
        "three parts",
        "This message has 3 parts: 1 verified, 2 without a confirmed signature",
        "neutral",
        &[],
        3,
    )
    .await;
    let text = shown_text();
    d.check(
        text.matches("Not signed").count() == 2 && text.contains("Signed by alice@example.org, key verified"),
        "each part has its own label: Not signed, Signed by..., Not signed",
    );
    d.shot(main.window(), "secure-4-mixed-parts").await;
    link_in_part(d).await;
    details(d).await;
    printing(d).await;

    show(inbox, BAD, SIGNED).await;
    check_bar(d, "a changed text", "does not match", "warning", &["warning"], 1).await;
    d.shot(main.window(), "secure-5-bad-signature").await;
    show(inbox, WRONG_SIGNER, SIGNED).await;
    check_bar(
        d,
        "another signer",
        "Signed by mallory@example.net, who is not the sender",
        "warning",
        &["warning"],
        1,
    )
    .await;
    d.shot(main.window(), "secure-6-wrong-signer").await;
    show(inbox, NO_KEY, SIGNED).await;
    check_bar(
        d,
        "a key not known",
        "Signed, but the key is not known",
        "neutral",
        &[],
        1,
    )
    .await;
    d.shot(main.window(), "secure-7-no-key").await;

    show(inbox, FAKE, SIGNED).await;
    check_bar(d, "a painted frame", "This message has 2 parts", "neutral", &[], 2).await;
    let page = main.reader.preview.shown();
    let labels: Vec<String> = page
        .split("class=\"pe-l\"")
        .skip(1)
        .map(|rest| {
            document_text(&format!("<{rest}"))
                .split_whitespace()
                .collect::<Vec<_>>()
                .join(" ")
        })
        .collect();
    d.check(
        labels.len() == 2
            && labels[0].starts_with("Not signed")
            && labels[1].starts_with("Signed by alice@example.org"),
        &format!("the real labels are both there, \"Not signed\" over the painted part ({labels:?})"),
    );
    let painted = frames().await.first().map_or(0, |f| f.0);
    d.check(
        painted >= 48,
        &format!("the painted part's frame is at least 48 pixels, what it paints shown inside it ({painted})"),
    );
    d.shot(main.window(), "secure-8-fake-frame").await;

    show(inbox, INLINE, SIGNED).await;
    check_bar(d, "inline encrypted", "This message has 3 parts", "neutral", &[], 3).await;
    d.check(
        shown_text().contains("4711"),
        "the inline encrypted block is decrypted in a part of its own",
    );
    d.shot(main.window(), "secure-10-inline").await;

    pictures(d, inbox).await;
    long(d, inbox).await;
    page_scripts_off(d, inbox).await;
    dark(d, inbox).await;
    remove_messages(d, inbox).await;
}

/// The message shown opened in a window of its own: the same bar there, and its Details with F1 there too
async fn in_window(d: &Driver, inbox: i64) {
    let main = shell().main();
    let row = main
        .list_view()
        .rows(&shell().core, 0, 500)
        .unwrap_or_default()
        .iter()
        .position(|m| m.folder_id == inbox && m.info.subject == ENCRYPTED);
    let Some(row) = row.and_then(|at| u32::try_from(at).ok()) else {
        d.check(false, "the encrypted message is listed");
        return;
    };
    main.list.view.emit_by_name::<()>("activate", &[&row]);
    let Some(window) = wait_for(10, || crate::message_window::windows().into_iter().next()).await else {
        d.check(false, "Enter opens the encrypted message in a window of its own");
        return;
    };
    let shown = wait_for(15, || window.reader.security.shown())
        .await
        .unwrap_or_default();
    d.check(
        shown.0.starts_with("Encrypted. Signed by alice@example.org") && shown.2.len() == 2,
        &format!("a message window shows the same bar, with the lock ({shown:?})"),
    );
    window.reader.security.details.emit_clicked();
    match wait_dialog(10, crate::security::DIALOG_NAME).await {
        Some(dialog) => {
            d.check(
                dialog
                    .root()
                    .is_some_and(|root| root == window.window.clone().upcast::<gtk::Root>()),
                "its Details opens over the message window",
            );
            crate::help::close();
            let _ = dialog.activate_action(&format!("win.{}", Command::Help.name()), None);
            let topic = wait_for(10, || crate::help::viewer().and_then(|help| help.shown())).await;
            d.check(
                topic.as_deref() == Some("encrypted-and-signed-mail"),
                &format!("and F1 there opens its help ({topic:?})"),
            );
            crate::help::close();
            dialog.close();
            wait_gone(10, crate::security::DIALOG_NAME).await;
        }
        None => d.check(false, "Details in the message window opens Security Details"),
    }
    d.shot(&window.window, "secure-14-window").await;
    let _ = WidgetExt::activate_action(&window.window, "window.close", None);
    wait_until(10, || crate::message_window::windows().is_empty()).await;
}

/// "The mill" clicked in part 1's frame of the message of three parts: the link goes to the browser, the page stays
async fn link_in_part(d: &Driver) {
    let view = shell().main().reader.preview.view.clone();
    let before = shell().main().reader.preview.shown();
    crate::ui::take_opened_links();
    let script = "(function(){var f=document.querySelectorAll('iframe.pe-d')[0];var d=f&&f.contentDocument;\
        var a=d&&d.querySelector('a[href=\"https://example.org/mill\"]');if(!a)return 'no';a.click();return 'yes'})()";
    let clicked = previews::run_script(&view, script).await == "yes";
    let opened = wait_for(10, || {
        Some(crate::ui::take_opened_links()).filter(|links| !links.is_empty())
    })
    .await
    .unwrap_or_default();
    let (fits, frames) = measured(3).await;
    d.check(
        clicked && opened == ["https://example.org/mill"],
        &format!("\"The mill\" clicked in part 1's frame opens https://example.org/mill in the browser ({opened:?})"),
    );
    d.check(
        shell().main().reader.preview.shown() == before && fits && shown_text().contains("The mill"),
        &format!("and the page stays, its three frames showing their parts ({frames:?})"),
    );
}

/// Details is reached by Tab and by its access key
fn keyboard(d: &Driver) {
    let button = &shell().main().reader.security.details;
    let key = button
        .child()
        .and_downcast::<gtk::Label>()
        .map(|label| label.mnemonic_keyval());
    d.check(
        button.is_focusable() && button.can_focus() && key.map(|k| k.to_lower()) == Some(gdk::Key::d),
        &format!("Details is reached by Tab and by Alt+D ({key:?})"),
    );
}

/// Details from the bar and from a part's label: the window names Part 2 and the key that signed it; F1 opens the
/// help of encrypted and signed mail
async fn details(d: &Driver) {
    let main = shell().main();
    main.reader.security.details.emit_clicked();
    let Some(dialog) = wait_dialog(10, crate::security::DIALOG_NAME).await else {
        d.check(false, "Details on the bar opens Security Details");
        return;
    };
    let text = named_in(dialog.upcast_ref(), "protection-details-text")
        .and_downcast::<gtk::TextView>()
        .map(|view| {
            let buffer = view.buffer();
            buffer.text(&buffer.start_iter(), &buffer.end_iter(), false).to_string()
        })
        .unwrap_or_default();
    d.check(
        dialog.title() == "Security Details"
            && text.contains("Part 2")
            && text.contains("with the key")
            && text.contains("Signed "),
        &format!("Details on the bar opens Security Details, which names Part 2 and the key that signed it ({text})"),
    );
    d.shot(&dialog, "secure-9-details").await;
    crate::help::close();
    let _ = dialog.activate_action(&format!("win.{}", Command::Help.name()), None);
    let topic = wait_for(10, || crate::help::viewer().and_then(|help| help.shown())).await;
    d.check(
        topic.as_deref() == Some("encrypted-and-signed-mail"),
        &format!("F1 in it opens the help of encrypted and signed mail ({topic:?})"),
    );
    crate::help::close();
    pause(300).await;
    click(dialog.upcast_ref(), "protection-details-close");
    d.check(wait_gone(10, crate::security::DIALOG_NAME).await, "Close closes it");
    // a click on a part's label: the page's navigation to its link
    main.reader.preview.view.load_uri(&format!("{}1", pe_html::PART_LINK));
    let opened = wait_dialog(10, crate::security::DIALOG_NAME).await;
    d.check(opened.is_some(), "a part's label opens Details too");
    if let Some(dialog) = opened {
        dialog.close();
        wait_gone(10, crate::security::DIALOG_NAME).await;
    }
    d.check(main.reader.has_view() && bar().is_some(), "and the message stays shown");
}

/// Printing the message of three parts: the print dialog over the app, the core's document of every part printed
async fn printing(d: &Driver) {
    let main = shell().main().window().clone().upcast::<gtk::Window>();
    command(Command::Print);
    let dialog = wait_for(20, || {
        windows()
            .into_iter()
            .find(|w| w != &main && w.is::<gtk::PrintUnixDialog>())
    })
    .await;
    d.check(
        dialog.is_some(),
        "Print of a message of parts opens the print dialog over the app",
    );
    let printed = document_text(&crate::reader::printing().unwrap_or_default());
    d.check(
        [
            "Part 2",
            "A note added on the way",
            "The signed paragraph",
            "Sent through the example list",
        ]
        .iter()
        .all(|words| printed.contains(words)),
        "and prints one document with every part's text and the parts' labels",
    );
    if let Some(dialog) = dialog {
        pause(1500).await;
        d.shot(&dialog, "secure-15-print").await;
        let closed = dialog.downgrade();
        dialog.close();
        drop(dialog);
        wait_until(10, || closed.upgrade().is_none_or(|w| !w.is_visible())).await;
    }
    d.check(
        wait_until(10, || crate::reader::printing().is_none()).await,
        "and lets go of the printed document when the dialog is done",
    );
}

/// An encrypted message's pictures: the bar without "always", the label changed after the click
async fn pictures(d: &Driver, inbox: i64) {
    let main = shell().main();
    let reader = &main.reader;
    show(inbox, PICTURES, SIGNED).await;
    let (choices, note) = reader.pictures_choices();
    d.check(
        reader.pictures_blocked() && choices.is_empty() && note.is_empty(),
        &format!("the pictures bar shows, without the \"always\" choices ({choices:?} {note})"),
    );
    d.check(
        !shown_text().contains("Pictures were loaded"),
        "nothing is loaded before the click",
    );
    let before = bar().map(|b| b.0).unwrap_or_default();
    reader.download_pictures.emit_clicked();
    let loaded = wait_until(15, || {
        !reader.pictures_blocked() && shown_text().contains("Pictures were loaded from the internet")
    })
    .await;
    d.check(
        loaded,
        "after Download Pictures the part's label says pictures were loaded",
    );
    let after = bar().map(|b| b.0).unwrap_or_default();
    d.check(
        !after.is_empty() && measured(1).await.0,
        &format!("the bar stays ({before} / {after}), the frame as tall as its document"),
    );
    d.shot(main.window(), "secure-11-pictures-in-decrypted").await;
}

/// A long part: as tall as its document, taller when "..." is unfolded and when the window is narrower
async fn long(d: &Driver, inbox: i64) {
    let main = shell().main();
    show(inbox, LONG, SIGNED).await;
    let (fits, found) = measured(1).await;
    d.check(
        fits && shown_text().contains("Line 40 of the long part"),
        &format!("the long part's frame is as tall as its document, its last line shown ({found:?})"),
    );
    let first = found.first().map_or(0, |f| f.0);
    let unfold = "(function(){var f=document.querySelector('iframe.pe-d');var s=f&&f.contentDocument.querySelector('details');\
        if(!s)return 'none';s.open=true;return 'open'})()";
    let opened = main
        .reader
        .preview
        .view
        .evaluate_javascript_future(unfold, None, None)
        .await
        .map(|v| v.to_str().to_string())
        .unwrap_or_default();
    let (fits, found) = measured(1).await;
    let unfolded = found.first().map_or(0, |f| f.0);
    d.check(
        opened == "open" && fits && unfolded > first,
        &format!("it grows when \"...\" is unfolded ({first} to {unfolded})"),
    );
    let window = main.window().clone();
    let (width, height) = (window.width(), window.height());
    window.set_default_size(760, height);
    wait_until(10, || window.width() <= 800).await;
    // the frame is measured again every 400 ms: until it has grown to its part, 10 seconds at most
    let deadline = Instant::now() + Duration::from_secs(10);
    let (fits, narrow) = loop {
        let (fits, found) = measured(1).await;
        let narrow = found.first().map_or(0, |f| f.0);
        if (fits && narrow >= unfolded) || Instant::now() > deadline {
            break (fits, narrow);
        }
        pause(250).await;
    };
    d.check(
        fits && narrow >= unfolded,
        &format!("and stays as tall as its part when the window is narrower ({unfolded} to {narrow}), nothing cut off"),
    );
    d.shot(main.window(), "secure-12-resized").await;
    window.set_default_size(width, height);
    wait_until(10, || window.width() == width).await;
}

/// The reading pane runs the app's script while the page's own stay off, and loads stay blocked: a document with a
/// script, an event attribute and a picture on a server of the test (no CSP of its own, so the settings decide)
async fn page_scripts_off(d: &Driver, inbox: i64) {
    let main = shell().main();
    let listener = std::net::TcpListener::bind("127.0.0.1:0").ok();
    let port = listener
        .as_ref()
        .and_then(|l| l.local_addr().ok())
        .map_or(0, |a| a.port());
    if let Some(listener) = &listener {
        let _ = listener.set_nonblocking(true);
    }
    let document = format!(
        "<!doctype html><html><head><title>quiet</title></head><body onload=\"document.title='onload ran'\">\
         <script>document.title='script ran'</script><p>Scripts</p>\
         <img src=\"http://127.0.0.1:{port}/picture.png\"></body></html>"
    );
    let view = &main.reader.preview;
    view.show(&document, false);
    wait_until(10, || !view.view.is_loading()).await;
    pause(1500).await;
    let title = view
        .view
        .evaluate_javascript_future("document.title", None, None)
        .await
        .map(|v| v.to_str().to_string())
        .unwrap_or_else(|e| format!("error: {e}"));
    let asked = listener.as_ref().is_some_and(|l| l.accept().is_ok());
    d.check(
        title == "quiet",
        &format!("the app's script runs in the reading pane, a page's script and event attribute do not ({title})"),
    );
    d.check(
        port != 0 && !asked,
        "and a picture of a page is not loaded: the content rules still block it",
    );
    show(inbox, SIGNED, LONG).await;
}

/// The bar and the labels in dark mode
async fn dark(d: &Driver, inbox: i64) {
    let main = shell().main();
    let styles = adw::StyleManager::default();
    styles.set_color_scheme(adw::ColorScheme::ForceDark);
    wait_until(5, || styles.is_dark()).await;
    show(inbox, MIXED, SIGNED).await;
    let (fits, _) = measured(3).await;
    d.check(
        styles.is_dark() && bar().is_some() && fits && main.reader.security.widget.has_css_class("dark"),
        "in dark mode the bar and the labels take their dark colours",
    );
    d.shot(main.window(), "secure-13-dark").await;
    // a bar in colour too, for the review of the dark look
    show(inbox, ENCRYPTED, SIGNED).await;
    d.shot(main.window(), "secure-13-dark-encrypted").await;
    styles.set_color_scheme(adw::ColorScheme::Default);
    wait_until(5, || !styles.is_dark()).await;
}

/// The message with a picture in each of two parts, the second encrypted (`secure-previews.eml`)
const PREVIEWS: &str = "Two pictures, one sealed";

/// Each frame's previews: how many pictures, how many have come, and their names, read with the app's own script
const FRAME_PREVIEWS: &str = "(function(){return Array.from(document.querySelectorAll('iframe.pe-d')).map(function(f){\
    var d=f.contentDocument;var s=d&&d.querySelector('section[class^=\"pe-att-\"]');if(!s)return '0/0/';\
    var i=Array.from(s.querySelectorAll('img'));return i.length+'/'+i.filter(function(x){return x.complete&&x.naturalWidth>0}).length\
    +'/'+i.map(function(x){return x.alt}).join('+')}).join(',')})()";

/// The page scrolled to where the second part starts, a little of the first above it
const BOUNDARY: &str =
    "(function(){var s=document.querySelectorAll('section.pe-p')[1];if(s)window.scrollTo(0,s.offsetTop-70)})()";

/// The message in a window of its own, tall enough for both parts, for the review of the look
async fn previews_window(d: &Driver, inbox: i64) {
    let main = shell().main();
    let row = main
        .list
        .shown_messages(500)
        .iter()
        .position(|m| m.folder_id == inbox && m.info.subject == PREVIEWS);
    let Some(row) = row.and_then(|at| u32::try_from(at).ok()) else {
        d.check(false, "the message with a picture in each part is listed");
        return;
    };
    main.list.view.emit_by_name::<()>("activate", &[&row]);
    let Some(window) = wait_for(10, || crate::message_window::windows().into_iter().next()).await else {
        d.check(false, "the message opens in a window of its own");
        return;
    };
    window.window.set_default_size(900, 1060);
    wait_until(15, || window.reader.has_view()).await;
    pause(1500).await;
    d.shot(&window.window, "secure-14d-attachment-previews-window").await;
    // dark messages off and on: the pane and the window each ask for the message again at once
    for on in [false, true] {
        crate::preferences::set_dark_messages(on);
        pause(1500).await;
        wait_until(15, || main.reader.has_view() && window.reader.has_view()).await;
    }
    let readers = [&main.reader, &window.reader];
    d.check(
        shell().core.dark_messages()
            && readers
                .iter()
                .all(|reader| reader.has_view() && !reader.says_not_shown() && reader.security.shown().is_some()),
        "dark messages turned off and on with the message in a window too: neither the pane nor the window says \
         the message could not be shown",
    );
    let _ = WidgetExt::activate_action(&window.window, "window.close", None);
    wait_until(10, || crate::message_window::windows().is_empty()).await;
    // the window's view asked for at the same time as nothing here: the reading pane still shows the message
    let shown = wait_until(5, || main.reader.has_view() && bar().is_some()).await;
    d.check(
        shown && measured(2).await.0,
        "the reading pane still shows the message the window opened, its bar and its frames",
    );
}

/// The strip of the message with a picture in each part: the encrypted part's file with a lock, in the blue of its
/// part's label, and each file saying its part in its tooltip and to screen readers
async fn strip_parts(d: &Driver) {
    let main = shell().main();
    let shown = wait_for(10, || Some(main.reader.strip.shown()).filter(|s| s.len() == 2))
        .await
        .unwrap_or_default();
    let file = |name: &str| shown.iter().find(|f| f.name == name);
    let plan = file("floor-plan.png");
    let harbour = file("harbour.png");
    d.check(
        plan.is_some_and(|f| {
            f.lock.as_deref() == Some("good")
                && f.tooltip.ends_with("From part 2: Encrypted. Not signed")
                && f.description == "From part 2: Encrypted. Not signed"
        }),
        &format!("floor-plan.png has the lock, in its part's blue, and says \"From part 2: Encrypted. Not signed\" ({plan:?})"),
    );
    d.check(
        harbour.is_some_and(|f| {
            f.lock.is_none()
                && f.tooltip.ends_with("From part 1: Not signed")
                && f.description == "From part 1: Not signed"
        }),
        &format!("harbour.png has no lock and says \"From part 1: Not signed\" ({harbour:?})"),
    );
    d.shot(main.window(), "secure-15-strip-parts").await;
}

/// The printout in a print view of its own, its end shown: both pictures, each named with its part
async fn printout(d: &Driver, printed: &str) {
    let view = crate::webview::DocumentView::new("print", false);
    let window = gtk::Window::builder()
        .title("Print")
        .default_width(760)
        .default_height(1000)
        .child(&view.view)
        .build();
    window.present();
    view.show(printed, false);
    wait_until(10, || !view.view.is_loading()).await;
    pause(800).await;
    previews::run_script(&view.view, "window.scrollTo(0, document.body.scrollHeight)").await;
    pause(300).await;
    d.shot(&window, "secure-14b-attachment-previews-print").await;
    window.close();
}

/// Each frame's previews as (pictures, come, names)
async fn frame_previews() -> Vec<(usize, usize, String)> {
    let view = shell().main().reader.preview.view.clone();
    previews::run_script(&view, FRAME_PREVIEWS)
        .await
        .split(',')
        .filter_map(|frame| {
            let mut values = frame.splitn(3, '/');
            Some((
                values.next()?.parse().ok()?,
                values.next()?.parse().ok()?,
                values.next()?.to_string(),
            ))
        })
        .collect()
}

/// The preview in frame `frame` (0 the first) clicked as the user clicks it
async fn click_in_frame(frame: usize) -> bool {
    let script = format!(
        "(function(){{var f=document.querySelectorAll('iframe.pe-d')[{frame}];var d=f&&f.contentDocument;\
         var a=d&&d.querySelector('section[class^=\"pe-att-\"] figure > a');if(!a)return 'no';a.click();return 'yes'}})()"
    );
    let view = shell().main().reader.preview.view.clone();
    previews::run_script(&view, &script).await == "yes"
}

/// The colour of the picture at `path` at 90, 75: the floor plan's shaded room, the harbour's sky
fn colour_at(path: &Path) -> Option<[u8; 3]> {
    let texture = gdk::Texture::from_filename(path).ok()?;
    let mut downloader = gdk::TextureDownloader::new(&texture);
    downloader.set_format(gdk::MemoryFormat::R8g8b8);
    let (bytes, stride) = downloader.download_bytes();
    let at = 75 * stride + 90 * 3;
    let rgb = bytes.get(at..at + 3)?;
    Some([rgb[0], rgb[1], rgb[2]])
}

/// The file opened after a click in a frame, a note (should one come) answered first; the note's words if any
async fn opened_from_frame(frame: usize) -> (bool, Option<String>, Vec<PathBuf>) {
    crate::attachments::take_opened();
    let clicked = click_in_frame(frame).await;
    let mut note = None;
    let deadline = Instant::now() + Duration::from_secs(10);
    let mut files = Vec::new();
    while Instant::now() < deadline && files.is_empty() {
        if let Some(said) = alert() {
            note = Some(alert_text(&said));
            answer(&said, "OK");
        }
        files.extend(crate::attachments::take_opened());
        pause(200).await;
    }
    (clicked, note, files)
}

/// Previews in signed and encrypted mail: each part's picture in its own frame, as tall as its part; the floor plan
/// opened from the encrypted part's frame; both printed after the text, named with their parts. Run after the
/// attachment step, so the note about decrypted files has been answered there (on its own encrypted file).
pub(super) async fn attachment_previews(d: &Driver) {
    d.step("attachment previews in signed and encrypted mail");
    let main = shell().main();
    let Some(inbox) = folder_id("Inbox") else {
        d.check(false, "the tree has the Inbox");
        return;
    };
    let raw = read_fixture("secure-previews.eml");
    let added = d.add_message(&raw, &["\\Seen"]).is_ok();
    run_command(Command::Sync);
    select_folder("Inbox");
    let arrived = wait_until(30, || {
        listed_in_folder(inbox, 0, 500)
            .iter()
            .any(|m| m.info.subject == PREVIEWS)
    })
    .await;
    d.check(
        added && arrived,
        "the message with a picture in each part is in the Inbox",
    );
    open_by_subject(inbox, PREVIEWS).await;
    wait_until(15, || main.reader.has_view()).await;
    let bar = wait_for(10, bar).await.unwrap_or_default();
    d.check(
        bar.0
            .contains("This message has 2 parts: 1 encrypted, 1 without a confirmed signature"),
        &format!("the bar counts the encrypted part and the plain one ({})", bar.0),
    );
    strip_parts(d).await;
    let page = main.reader.preview.shown();
    d.check(
        !page.contains("/pv/") && !page.contains("pe-att-"),
        "the page itself has no preview, only its frames",
    );
    let deadline = Instant::now() + Duration::from_secs(20);
    let mut found = frame_previews().await;
    while Instant::now() < deadline
        && !(found.len() == 2
            && found
                .iter()
                .all(|(pictures, come, _)| *pictures == 1 && come == pictures))
    {
        pause(250).await;
        found = frame_previews().await;
    }
    d.check(
        found.len() == 2
            && found[0] == (1, 1, "harbour.png".to_string())
            && found[1] == (1, 1, "floor-plan.png".to_string()),
        &format!("frame 1 (the plain part) shows harbour.png, frame 2 (the encrypted part) floor-plan.png ({found:?})"),
    );
    let (fits, sizes) = measured(2).await;
    d.check(
        fits && sizes.iter().all(|(shown, _, _)| *shown > 150),
        &format!("each frame is as tall as its part with its picture, no scroll bar inside ({sizes:?})"),
    );
    // where the plain part ends and the encrypted one starts: the harbour's end, the encrypted part's label over the
    // floor plan
    let view = main.reader.preview.view.clone();
    previews::run_script(&view, BOUNDARY).await;
    pause(300).await;
    d.shot(main.window(), "secure-14-attachment-previews").await;
    previews_window(d, inbox).await;

    let (clicked, note, files) = opened_from_frame(1).await;
    d.check(
        clicked
            && files.len() == 1
            && files[0].file_name().is_some_and(|n| n == "floor-plan.png")
            && attach::in_private_folder(&files[0])
            && colour_at(&files[0]) == Some([214, 228, 247])
            && note.is_none(),
        &format!(
            "clicking the floor plan in frame 2 opens the decrypted floor plan, its shaded room, without the note \
             about decrypted files (shown once ever, in the attachment step) ({files:?}, note: {note:?})"
        ),
    );
    let (clicked, _, files) = opened_from_frame(0).await;
    d.check(
        clicked
            && files.len() == 1
            && files[0].file_name().is_some_and(|n| n == "harbour.png")
            && colour_at(&files[0]) == Some([157, 195, 230]),
        &format!("and the harbour in frame 1 opens the harbour, its sky ({files:?})"),
    );

    let main_window = main.window().clone().upcast::<gtk::Window>();
    command(Command::Print);
    let dialog = wait_for(40, || {
        windows()
            .into_iter()
            .find(|w| w != &main_window && w.is::<gtk::PrintUnixDialog>())
    })
    .await;
    let printed = crate::reader::printing().unwrap_or_default();
    let text = document_text(&printed);
    let order = [
        "as promised",
        "Part 1: harbour.png",
        "for your eyes only",
        "Part 2: floor-plan.png",
    ]
    .iter()
    .map(|words| text.find(words))
    .collect::<Option<Vec<usize>>>();
    d.check(
        dialog.is_some()
            && order.as_ref().is_some_and(|at| at.is_sorted())
            && printed.matches("<img src=\"data:image/").count() == 2
            && !printed.contains("/pv/"),
        &format!(
            "Print gives each part's picture after that part's text, captioned \"Part 1: harbour.png\" and \
             \"Part 2: floor-plan.png\" ({order:?})"
        ),
    );
    if let Some(dialog) = dialog {
        pause(1000).await;
        let closed = dialog.downgrade();
        dialog.close();
        drop(dialog);
        wait_until(10, || closed.upgrade().is_none_or(|w| !w.is_visible())).await;
    }
    wait_until(10, || crate::reader::printing().is_none()).await;
    printout(d, &printed).await;

    // the dark look, for the review
    let styles = adw::StyleManager::default();
    styles.set_color_scheme(adw::ColorScheme::ForceDark);
    wait_until(5, || styles.is_dark()).await;
    pause(1000).await;
    measured(2).await;
    previews::run_script(&view, BOUNDARY).await;
    pause(300).await;
    d.shot(main.window(), "secure-14c-attachment-previews-dark").await;
    d.check(
        wait_until(5, || main.reader.strip.widget.has_css_class("dark")).await,
        "in dark mode the strip's lock takes the dark colour of its tone",
    );
    d.shot(main.window(), "secure-15b-strip-parts-dark").await;
    styles.set_color_scheme(adw::ColorScheme::Default);
    wait_until(5, || !styles.is_dark()).await;

    let id = message_id(&raw);
    for message in d.messages("INBOX") {
        if raw_text(&message).contains(id.as_str())
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
        !listed_in_folder(inbox, 0, 500)
            .iter()
            .any(|m| m.info.subject == PREVIEWS)
    })
    .await;
    d.check(gone, "the message is taken away");
}
