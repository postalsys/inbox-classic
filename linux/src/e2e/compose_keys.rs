//! Step 19j of the UI test: signing and encrypting what is written. After 19i the account's key, Alice's (verified)
//! and Mallory's are imported; Dave has no key anywhere and the app looks keys up on the harness (`--key-server`).
//! Each message sent lands in the Inbox and is checked with OpenPGP.js by the harness's `POST /pgp/check`; the
//! messages of the step are taken away after it. Then the window in German and Finnish, for the review.

use pe_core::compose_keys::RecipientKey;

use super::secure::read_fixture;
use super::steps::{folder_id, in_language, open_by_subject, shown_words};
use super::*;
use crate::compose::Compose;
use crate::compose_keys::DIALOG_NAME;

const SIGNED_TEXT: &str = "A signed hello from the compose window";
const ENCRYPTED_TEXT: &str = "Meet me by the lighthouse at nine";
const KEY_TEXT: &str = "Here is my key";

/// The highest UID of `mailbox`, under which the messages of the step come
fn highest_uid(d: &Driver, mailbox: &str) -> u64 {
    d.messages(mailbox)
        .iter()
        .filter_map(|m| m["uid"].as_u64())
        .max()
        .unwrap_or(0)
}

/// The first message of the Inbox over `uid`: the one just sent (an encrypted one has no subject to find it by)
async fn arrived_after(d: &Driver, uid: u64) -> Option<Value> {
    wait_for(30, || {
        d.messages("INBOX")
            .into_iter()
            .find(|m| m["uid"].as_u64().unwrap_or(0) > uid)
    })
    .await
}

/// What OpenPGP.js makes of a message: the account's key to decrypt it, Alice's to see whether it is encrypted to her
fn pgp_check(d: &Driver, message: &Value) -> Value {
    let body = serde_json::json!({
        "raw": message["raw"].as_str().unwrap_or_default().replace(['\r', '\n'], ""),
        "key": read_fixture("me.asc"),
        "passphrase": read_fixture("me.passphrase").trim(),
        "recipients": [read_fixture("alice.asc")],
    })
    .to_string();
    http(d.ports.pgp, "POST", "/pgp/check", Some(&body))
        .ok()
        .and_then(|answer| serde_json::from_str(&answer).ok())
        .unwrap_or(Value::Null)
}

/// A new message to `to` with `subject` and `text` written
async fn new_message(to: &str, subject: &str, text: &str) -> Option<Rc<Compose>> {
    command(Command::NewMail);
    let c = wait_compose(10).await?;
    c.to.set_text(to);
    c.subject.set_text(subject);
    c.editor.type_text(text);
    pause(500).await;
    Some(c)
}

/// The state of a compose action (a check mark of the menu), and whether it can be chosen
fn action_state(c: &Compose, command: Command) -> (bool, bool) {
    let action = c
        .protection
        .actions
        .lookup_action(command.name())
        .and_downcast::<gio::SimpleAction>();
    let state = action
        .as_ref()
        .and_then(|a| a.state())
        .and_then(|s| s.get::<bool>())
        .unwrap_or(false);
    (state, action.is_some_and(|a| a.is_enabled()))
}

fn line(c: &Compose) -> (String, String, String) {
    c.protection.line.shown().unwrap_or_default()
}

/// The key of a recipient as the core said it last
fn recipient_key(c: &Compose, address: &str) -> Option<(RecipientKey, String)> {
    c.protection
        .security
        .borrow()
        .as_ref()?
        .recipients
        .iter()
        .find(|r| r.address == address)
        .map(|r| (r.key, r.text.clone()))
}

/// Sent with Send, and the message that arrived
async fn send(d: &Driver, c: &Compose) -> Option<Value> {
    let before = highest_uid(d, "INBOX");
    click(c.window.upcast_ref(), "compose-send");
    wait_until(15, || !c.window.is_visible()).await;
    arrived_after(d, before).await
}

pub(super) async fn signing_and_encrypting(d: &Driver) {
    d.step("signing and encrypting what is written");
    let (inbox_from, sent_from) = (highest_uid(d, "INBOX"), highest_uid(d, "Sent"));
    use_fixture_key(d);
    signing(d).await;
    encrypting(d).await;
    missing_key(d).await;
    // the encrypted messages sent are listed as "..." too: away before the one replied to is found by it
    take_away(d, "INBOX", inbox_from).await;
    reply_to_encrypted(d).await;
    attach_my_key(d).await;
    long_languages(d).await;
    take_away(d, "INBOX", inbox_from).await;
    take_away(d, "Sent", sent_from).await;
}

/// The messages of `mailbox` over `uid` taken away, from the server and the lists
async fn take_away(d: &Driver, mailbox: &str, uid: u64) {
    for message in d.messages(mailbox) {
        if let Some(uid) = message["uid"].as_u64().filter(|at| *at > uid) {
            let _ = http(
                d.ports.rest,
                "DELETE",
                &format!("/v1/mailboxes/{mailbox}/messages/{uid}"),
                None,
            );
        }
    }
    run_command(Command::Sync);
    pause(1500).await;
}

/// The account's key is `me.asc` (imported in 19i), whose private part the harness has: the one made in 19h was the
/// account's until now
fn use_fixture_key(d: &Driver) {
    let core = &shell().core;
    let account = core.accounts().ok().and_then(|a| a.first().map(|a| a.id));
    // the fixture's key was made before this run, the other one during it
    let fixture = core
        .pgp_keys()
        .unwrap_or_default()
        .into_iter()
        .filter(|key| key.own && key.name == "Alex Morgan")
        .min_by_key(|key| key.created);
    let used = match (account, fixture) {
        (Some(account), Some(key)) => core.pgp_set_account_key(account, &key.fingerprint, true).is_ok(),
        _ => false,
    };
    d.check(used, "the key of me.asc is the account's");
}

/// A new message starts with both off; Sign by Ctrl+Shift+D in the text: the button, the menu, the line; OpenPGP.js
/// finds the signature good
async fn signing(d: &Driver) {
    let Some(c) = new_message("alice@example.org", "Signed in the compose window", SIGNED_TEXT).await else {
        d.check(false, "Create Mail opens a compose window");
        return;
    };
    let p = &c.protection;
    d.check(
        !p.sign_button.is_active()
            && !p.encrypt_button.is_active()
            && action_state(&c, Command::ComposeSign) == (false, true)
            && !action_state(&c, Command::ComposeEncrypt).0
            && p.line.shown().is_none(),
        "a new message starts with Sign and Encrypt off, unchecked in the menu, and no line under the fields",
    );
    let labels = menu_labels(p.menu_button.popover().and_downcast::<gtk::PopoverMenu>().as_ref());
    d.check(
        labels == ["Digitally Sign", "Encrypt", "Attach My Public Key"],
        &format!("the window's menu has Digitally Sign, Encrypt and Attach My Public Key ({labels:?})"),
    );
    let accels = shell().application.accels_for_action("compose.compose-encrypt");
    let wanted = gtk::accelerator_parse("<Primary><Shift>e");
    d.check(
        accels.iter().any(|a| gtk::accelerator_parse(a) == wanted),
        &format!("Encrypt has Ctrl+Shift+E ({accels:?})"),
    );
    c.editor.focus();
    let taken = crate::compose_keys::press_in_editor(
        &c,
        gdk::Key::D,
        gdk::ModifierType::CONTROL_MASK | gdk::ModifierType::SHIFT_MASK,
    );
    let on = wait_until(10, || p.sign_button.is_active() && line(&c).1 == "good").await;
    let (text, tone, icon) = line(&c);
    d.check(
        taken && on && action_state(&c, Command::ComposeSign).0,
        "Ctrl+Shift+D in the text turns Sign on: the button pressed, the menu item checked",
    );
    d.check(
        text == "Signed: recipients can check that it comes from you and was not changed."
            && tone == "good"
            && icon == "ic-ribbon-symbolic",
        &format!("the line says it is signed, in blue with the ribbon ({tone}, {icon}: {text})"),
    );
    d.check(!c.keys_row[1].is_visible(), "there is no Keys row while Encrypt is off");
    d.shot(&c.window, "write-30-sign").await;
    let Some(message) = send(d, &c).await else {
        d.check(false, "the signed message arrived");
        return;
    };
    let checked = pgp_check(d, &message);
    d.check(
        checked["kind"] == "signed"
            && checked["valid"] == true
            && checked["text"].as_str().is_some_and(|t| t.contains(SIGNED_TEXT)),
        &format!("OpenPGP.js finds it signed, the signature good, the text the one written ({checked})"),
    );
}

/// Encrypt from the menu: Sign on and greyed, Alice's green lock, the green line; OpenPGP.js decrypts it, signed, to
/// her key, and the server holds none of its words
async fn encrypting(d: &Driver) {
    let Some(c) = new_message("Alice Example <alice@example.org>", "Encrypted", ENCRYPTED_TEXT).await else {
        d.check(false, "Create Mail opens a compose window");
        return;
    };
    let p = &c.protection;
    run_command(Command::ComposeEncrypt);
    let on = wait_until(10, || p.encrypt_button.is_active() && line(&c).1 == "verified").await;
    d.check(
        on && action_state(&c, Command::ComposeEncrypt).0,
        "Tools > Encrypt turns Encrypt on, checked in the menu",
    );
    d.check(
        p.sign_button.is_active()
            && !p.sign_button.is_sensitive()
            && action_state(&c, Command::ComposeSign) == (true, false)
            && p.sign_button.tooltip_text().as_deref() == Some("An encrypted message is always signed"),
        "Sign shows on and greyed, its tooltip \"An encrypted message is always signed\"",
    );
    let chips = p.chips();
    d.check(
        c.keys_row[1].is_visible()
            && chips
                == [(
                    "Alice Example".to_string(),
                    "verified".to_string(),
                    "ic-lock-closed-symbolic".to_string(),
                )],
        &format!("the Keys row shows Alice with a green lock ({chips:?})"),
    );
    let (text, tone, icon) = line(&c);
    d.check(
        text == "Encrypted and signed: only you and Alice Example can read it."
            && tone == "verified"
            && icon == "ic-lock-closed-symbolic",
        &format!("the line says who can read it, in green with the lock ({tone}, {icon}: {text})"),
    );
    d.shot(&c.window, "write-31-encrypt").await;
    in_dark(d, &c.window, "write-31-encrypt-dark").await;
    let Some(message) = send(d, &c).await else {
        d.check(false, "the encrypted message arrived");
        return;
    };
    let checked = pgp_check(d, &message);
    d.check(
        checked["kind"] == "encrypted"
            && checked["signed"] == true
            && checked["valid"] == true
            && checked["to"] == serde_json::json!([true])
            && checked["text"].as_str().is_some_and(|t| t.contains(ENCRYPTED_TEXT)),
        &format!("OpenPGP.js decrypts it with the account's key, signed, encrypted to Alice's key ({checked})"),
    );
    d.check(
        !raw_text(&message).contains("lighthouse"),
        "the server's copy holds none of the words written",
    );
}

/// A shot of `window` in dark mode, for the review of the tones there
async fn in_dark(d: &Driver, window: &impl IsA<gtk::Widget>, name: &str) {
    let styles = adw::StyleManager::default();
    styles.set_color_scheme(adw::ColorScheme::ForceDark);
    wait_until(5, || styles.is_dark()).await;
    d.shot(window, name).await;
    styles.set_color_scheme(adw::ColorScheme::Default);
    wait_until(5, || !styles.is_dark()).await;
}

/// The title and subtitle of a row of Recipients' Keys
fn key_row(dialog: &adw::Dialog, index: usize) -> (String, String) {
    named_in(dialog.upcast_ref(), &format!("recipient-key-{index}"))
        .and_downcast::<adw::ActionRow>()
        .map(|row| {
            (
                row.title().to_string(),
                row.subtitle().map(|s| s.to_string()).unwrap_or_default(),
            )
        })
        .unwrap_or_default()
}

fn sensitive(dialog: &adw::Dialog, name: &str) -> bool {
    named_in(dialog.upcast_ref(), name).is_some_and(|w| w.is_sensitive())
}

/// Encrypt to Alice and Dave: Dave's lock grey while looked up, then amber; Send opens Recipients' Keys; Remove from
/// Message takes him out, then Send sends it encrypted to Alice
async fn missing_key(d: &Driver) {
    let to = "Alice Example <alice@example.org>, dave@example.com";
    let Some(c) = new_message(to, "Encrypted to two", ENCRYPTED_TEXT).await else {
        d.check(false, "Create Mail opens a compose window");
        return;
    };
    let p = &c.protection;
    let _ = WidgetExt::activate_action(&c.window, "compose.compose-encrypt", None);
    wait_until(10, || p.encrypt_button.is_active()).await;
    let first = recipient_key(&c, "dave@example.com").map(|k| k.0);
    d.check(
        matches!(first, Some(RecipientKey::Looking | RecipientKey::Missing)),
        &format!("Dave's key is looked up as Encrypt goes on ({first:?})"),
    );
    let missing = wait_until(15, || {
        recipient_key(&c, "dave@example.com").is_some_and(|k| k.0 == RecipientKey::Missing)
    })
    .await;
    let dave = recipient_key(&c, "dave@example.com").map(|k| k.1).unwrap_or_default();
    let chips = p.chips();
    d.check(
        missing
            && dave.starts_with("No key: none was found on")
            && chips
                .get(1)
                .is_some_and(|chip| chip.1 == "warning" && chip.2 == "ic-warning-symbolic"),
        &format!("then his is amber with the warning sign: \"{dave}\" ({chips:?})"),
    );
    let (text, tone, _) = line(&c);
    d.check(
        tone == "warning" && text.contains("dave@example.com"),
        &format!("the line is amber and names Dave ({text})"),
    );
    click(c.window.upcast_ref(), "compose-send");
    let Some(dialog) = wait_dialog(10, DIALOG_NAME).await else {
        d.check(false, "Send opens Recipients' Keys instead of sending");
        return;
    };
    d.check(c.window.is_visible(), "Send opens Recipients' Keys instead of sending");
    let intro = label_of(dialog.upcast_ref(), "recipient-keys-intro");
    let (alice, dave) = (key_row(&dialog, 0), key_row(&dialog, 1));
    d.check(
        dialog.title() == "Recipients’ Keys"
            && intro.starts_with("One recipient has no key to encrypt to")
            && alice.0 == "Alice Example"
            && alice.1.contains("Key verified")
            && dave.0 == "dave@example.com"
            && dave.1.starts_with("No key"),
        &format!("it says why and lists Alice (key verified) and Dave (no key): {intro} {alice:?} {dave:?}"),
    );
    d.check(
        !sensitive(&dialog, "recipient-key-find-1")
            && named_in(dialog.upcast_ref(), "recipient-key-remove-1").is_some()
            && sensitive(&dialog, "recipient-keys-unencrypted")
            && !sensitive(&dialog, "recipient-keys-send"),
        "Find Key greyed for Dave (asked a moment ago), Remove from Message, Send Without Encryption; Send greyed",
    );
    d.shot(&dialog, "write-32-missing-key").await;
    in_dark(d, &dialog, "write-32-missing-key-dark").await;
    crate::help::close();
    let _ = dialog.activate_action(&format!("win.{}", Command::Help.name()), None);
    let topic = wait_for(10, || crate::help::viewer().and_then(|help| help.shown())).await;
    d.check(
        topic.as_deref() == Some("sign-and-encrypt"),
        &format!("F1 in it opens the help of signing and encrypting ({topic:?})"),
    );
    crate::help::close();
    pause(300).await;
    click(dialog.upcast_ref(), "recipient-key-remove-1");
    let removed = wait_until(10, || {
        !c.to.text().contains("dave") && named_in(dialog.upcast_ref(), "recipient-key-1").is_none()
    })
    .await;
    d.check(
        removed && c.to.text() == "Alice Example <alice@example.org>",
        &format!("Remove from Message takes Dave out of To ({})", c.to.text()),
    );
    d.check(
        sensitive(&dialog, "recipient-keys-send")
            && dialog
                .default_widget()
                .is_some_and(|w| w.widget_name() == "recipient-keys-send"),
        "the window shows only Alice, and Send is on and the default",
    );
    let before = highest_uid(d, "INBOX");
    click(dialog.upcast_ref(), "recipient-keys-send");
    wait_gone(10, DIALOG_NAME).await;
    wait_until(15, || !c.window.is_visible()).await;
    let Some(message) = arrived_after(d, before).await else {
        d.check(false, "Send there sends it");
        return;
    };
    let checked = pgp_check(d, &message);
    d.check(
        checked["kind"] == "encrypted" && checked["to"] == serde_json::json!([true]),
        &format!("Send there sends it encrypted to Alice ({checked})"),
    );
}

/// A reply to an encrypted message starts encrypted; Encrypt off asks first, then the encrypted quote keeps it from
/// going in the clear until it is deleted
async fn reply_to_encrypted(d: &Driver) {
    let Some(inbox) = folder_id("Inbox") else {
        d.check(false, "the tree has the Inbox");
        return;
    };
    let added = d
        .add_message(&read_fixture("secure-encrypted.eml"), &["\\Seen"])
        .is_ok();
    run_command(Command::Sync);
    select_folder("Inbox");
    let listed = wait_until(30, || {
        listed_in_folder(inbox, 0, 500).iter().any(|m| m.info.subject == "...")
    })
    .await;
    d.check(added && listed, "the encrypted message is in the Inbox again");
    let reader = &shell().main().reader;
    open_by_subject(inbox, "...").await;
    wait_until(15, || reader.has_view()).await;
    run_command(Command::Reply);
    let Some(c) = wait_compose(10).await else {
        d.check(false, "Reply opens a compose window");
        return;
    };
    let p = &c.protection;
    let started = wait_until(10, || line(&c).1 == "verified").await;
    let chips = p.chips();
    d.check(
        started
            && p.encrypt_button.is_active()
            && p.sign_button.is_active()
            && chips.first().is_some_and(|chip| chip.1 == "verified"),
        &format!("the reply opens with Encrypt and Sign on, Alice's lock green ({chips:?})"),
    );
    p.encrypt_button.set_active(false);
    let Some(question) = wait_alert(10).await else {
        d.check(false, "Encrypt clicked off asks first");
        return;
    };
    let text = alert_text(&question);
    d.check(
        text.contains("This message quotes or forwards an encrypted message")
            && question.response_label("yes") == "Turn Encryption Off"
            && question.response_label("no") == "Keep It Encrypted"
            && question.default_response().as_deref() == Some("no")
            && question.close_response() == "no"
            && question.response_appearance("yes") == adw::ResponseAppearance::Destructive,
        &format!("Encrypt clicked off asks, Keep It Encrypted the default and Esc ({text})"),
    );
    d.shot(&c.window, "write-33-reply-encrypted").await;
    answer(&question, "Keep It Encrypted");
    pause(800).await;
    d.check(
        p.encrypt_button.is_active() && p.encrypt.get(),
        "Keep It Encrypted leaves it on",
    );
    p.encrypt_button.set_active(false);
    match wait_alert(10).await {
        Some(question) => {
            answer(&question, "Turn Encryption Off");
        }
        None => d.check(false, "Encrypt clicked off asks again"),
    }
    let off = wait_until(10, || !p.encrypt_button.is_active() && line(&c).1 == "warning").await;
    let (text, _, icon) = line(&c);
    d.check(
        off && text.contains("can only be sent encrypted")
            && icon == "ic-warning-symbolic"
            && p.sign_button.is_active()
            && p.sign_button.is_sensitive()
            && !c.keys_row[1].is_visible(),
        &format!("Turn Encryption Off: the line is amber, it can only be sent encrypted; Sign stays on ({text})"),
    );
    d.shot(&c.window, "write-34-quote-in-clear").await;
    click(c.window.upcast_ref(), "compose-send");
    match wait_alert(10).await {
        Some(refused) => {
            let said = alert_text(&refused);
            d.check(
                said.contains("can only be sent encrypted"),
                &format!("Send is refused with the same words ({said})"),
            );
            answer(&refused, "OK");
        }
        None => d.check(false, "Send is refused"),
    }
    pause(500).await;
    d.check(c.window.is_visible(), "and the message stays open");
    c.editor.run_script(
        "document.getElementById('more').click();var q=document.querySelector('#body > div.quoted');if(q)q.remove();",
    );
    let clear = wait_until(10, || {
        line(&c).0 == "Not encrypted, although the message it answers or forwards was."
    })
    .await;
    d.check(
        clear && line(&c).1 == "warning",
        &format!(
            "the quote unfolded and deleted, the line says it is not encrypted, in amber ({})",
            line(&c).0
        ),
    );
    let Some(message) = send(d, &c).await else {
        d.check(false, "the reply without its quote is sent");
        return;
    };
    let checked = pgp_check(d, &message);
    d.check(
        checked["kind"] == "signed" && checked["valid"] == true && !raw_text(&message).contains("old mill"),
        &format!(
            "sent, it is signed (Sign stayed on) and holds no \"old mill\" ({})",
            checked["kind"]
        ),
    );
}

/// Attach My Public Key from the menu: the key in the Attach row, sent as application/pgp-keys
async fn attach_my_key(d: &Driver) {
    let Some(c) = new_message("alice@example.org", "My key", KEY_TEXT).await else {
        d.check(false, "Create Mail opens a compose window");
        return;
    };
    d.check(
        action_state(&c, Command::AttachMyKey).1,
        "Attach My Public Key can be chosen: the From address has a key",
    );
    run_command(Command::AttachMyKey);
    let attached = wait_until(10, || {
        c.file_labels()
            .iter()
            .any(|label| label.starts_with("Alex Morgan public key.asc"))
    })
    .await;
    d.check(
        attached,
        &format!("the Attach row lists the key ({:?})", c.file_labels()),
    );
    d.shot(&c.window, "write-35-attach-key").await;
    let Some(message) = send(d, &c).await else {
        d.check(false, "the message with the key arrived");
        return;
    };
    let checked = pgp_check(d, &message);
    let files = checked["attachments"].as_array().cloned().unwrap_or_default();
    d.check(
        files
            .iter()
            .any(|f| f["type"] == "application/pgp-keys" && f["name"] == "Alex Morgan public key.asc"),
        &format!("it is sent as application/pgp-keys ({files:?})"),
    );
}

/// The window in German and Finnish, ten recipients encrypted to: nothing cut off, the Keys row and the line wrapping,
/// Recipients' Keys' long buttons; Finnish in dark mode too
async fn long_languages(d: &Driver) {
    let mut to = vec![
        "Alice Example <alice@example.org>".to_string(),
        "dave@example.com".to_string(),
    ];
    to.extend((1..=8).map(|n| format!("Recipient {n} <r{n}@example.net>")));
    for language in ["de", "fi"] {
        d.step(&format!("signing and encrypting in {language}"));
        in_language(language).await;
        let Some(c) = new_message(&to.join(", "), "Lighthouse", ENCRYPTED_TEXT).await else {
            d.check(false, "Create Mail opens a compose window");
            continue;
        };
        let _ = WidgetExt::activate_action(&c.window, "compose.compose-encrypt", None);
        wait_until(20, || {
            c.protection.encrypt_button.is_active()
                && c.protection
                    .security
                    .borrow()
                    .as_ref()
                    .is_some_and(|s| !s.looking && s.recipients.len() == 10)
        })
        .await;
        let chips = c.protection.chips();
        d.check(
            chips.len() == 9 && chips[8].0 == "+2",
            &format!(
                "{language}: the Keys row shows eight recipients and \"+2\" ({} chips)",
                chips.len()
            ),
        );
        // the status bar's words end in "..." when long, as status bars do
        let status = c.status.text().to_string();
        let cut: Vec<String> = shown_words(c.window.upcast_ref())
            .into_iter()
            .filter(|(text, cut)| *cut && *text != status)
            .map(|(text, _)| text)
            .collect();
        d.check(
            cut.is_empty(),
            &format!("{language}: nothing in the compose window is cut off ({cut:?})"),
        );
        d.shot(&c.window, &format!("write-keys-{language}")).await;
        c.protection.line.details.emit_clicked();
        if let Some(dialog) = wait_dialog(10, DIALOG_NAME).await {
            d.shot(&dialog, &format!("write-keys-{language}-dialog")).await;
            if language == "fi" {
                in_dark(d, &dialog, "write-keys-fi-dialog-dark").await;
            }
            click(dialog.upcast_ref(), "recipient-keys-cancel");
            wait_gone(10, DIALOG_NAME).await;
        } else {
            d.check(false, &format!("{language}: Details opens Recipients' Keys"));
        }
        if language == "fi" {
            in_dark(d, &c.window, "write-keys-fi-dark").await;
        }
        close_compose(&c).await;
    }
    in_language("en").await;
}
