//! Step 19k of the UI test: finding, publishing and passing on keys. After 19j the account's key is `me.asc`, Alice's
//! is verified and Dave's is not imported; the app looks keys up on the harness (`--key-server`), which plays
//! keys.openpgp.org and every domain's Web Key Directory and lists what it was asked. Publish in My Keys, Import from
//! Clipboard, Find Key on a part signed by a key not known here and in a contact's Properties, Import Key on an attached
//! key, the Address Book's key marks, a key learned from an Autocrypt header and another one waiting; the messages and
//! the cards of the step are taken away after it (the Address Book step wants an empty book).

use pe_core::i18n::{Text, tr, tr_args};

use super::keys::{close_keys, keys_listed, open_keys, scroll_to};
use super::secure::{message_id, read_fixture};
use super::steps::open_by_subject;
use super::*;

const NO_KEY: &str = "A key you do not have";
const KEY_ATTACHED: &str = "My public key";
const PREVIEWS: &str = "Two pictures, one sealed";
const FRANK_1: &str = "Hello from Frank";
const FRANK_2: &str = "Frank's new computer";

/// The account's address, whose key is `me.asc`
const ME: &str = "testuser@inboxclassic.test";

/// A key of `scripts/ui-e2e/pgp/` put on the harness: by its fingerprints and key ids, by `address` when there is
/// one, and in its domain's Web Key Directory with `wkd`; the fingerprint the harness read
fn serve_key(d: &Driver, file: &str, address: Option<&str>, wkd: bool) -> String {
    let mut body = serde_json::json!({ "key": read_fixture(file) });
    if let Some(address) = address {
        body["address"] = address.into();
        body["wkd"] = wkd.into();
    }
    http(d.ports.pgp, "POST", "/pgp/keys", Some(&body.to_string()))
        .ok()
        .and_then(|answer| serde_json::from_str::<Value>(&answer).ok())
        .and_then(|answer| answer["fingerprint"].as_str().map(str::to_string))
        .unwrap_or_default()
}

/// The harness's list of what it was asked for (`GET /pgp/lookups`, or `/pgp/uploads`)
fn harness_list(d: &Driver, path: &str) -> Vec<Value> {
    http(d.ports.pgp, "GET", path, None)
        .ok()
        .and_then(|answer| serde_json::from_str::<Value>(&answer).ok())
        .and_then(|list| list.as_array().cloned())
        .unwrap_or_default()
}

/// The lookups asked after the first `before`
fn lookups_after(d: &Driver, before: usize) -> Vec<Value> {
    harness_list(d, "/pgp/lookups").into_iter().skip(before).collect()
}

/// A lookup as the harness lists it
fn lookup(kind: &str, value: &str, found: bool) -> Value {
    serde_json::json!({ "kind": kind, "value": value, "found": found })
}

/// The key whose name is `name`
fn key_named(name: &str) -> Option<pe_core::keys::KeyInfo> {
    shell()
        .core
        .pgp_keys()
        .unwrap_or_default()
        .into_iter()
        .find(|key| key.name == name)
}

/// A contact's key in My Keys: listed as a contact's, Valid, and its Properties' source `source`
async fn listed_as(d: &Driver, name: &str, address: &str, source: Text) {
    let Some(keys) = open_keys(d).await else { return };
    let listed = wait_until(5, || {
        keys_listed(&keys)
            .iter()
            .any(|row| row.contains(name) && row.contains(address) && row.contains("Contact") && row.contains("Valid"))
    })
    .await;
    d.check(
        listed,
        &format!(
            "My Keys lists {name}, {address}, Contact, Valid ({:?})",
            keys_listed(&keys)
        ),
    );
    let said = key_named(name).map(|key| key.source).unwrap_or_default();
    d.check(
        said == tr(source),
        &format!("{name}'s Properties say \"{}\" ({said})", tr(source)),
    );
    close_keys(&keys).await;
}

/// The row of the key list with the key `fingerprint` selected
fn select_fingerprint(keys: &gtk::Widget, fingerprint: &str) -> bool {
    let at = shell()
        .core
        .pgp_keys()
        .unwrap_or_default()
        .iter()
        .position(|key| key.fingerprint == fingerprint);
    let Some(list) = named_in(keys, "keys-list").and_downcast::<gtk::ListBox>() else {
        return false;
    };
    match at.and_then(|at| list.row_at_index(at as i32)) {
        Some(row) => {
            list.select_row(Some(&row));
            true
        }
        None => false,
    }
}

fn sensitive(root: &gtk::Widget, name: &str) -> bool {
    named_in(root, name).is_some_and(|w| w.is_sensitive())
}

/// The message box open answered with OK, and gone
async fn dismiss(said: &adw::AlertDialog) {
    answer(said, "OK");
    wait_until(5, || !said.is_mapped()).await;
}

/// The fixture `file` put in the Inbox and listed under `subject`
async fn add_fixture(d: &Driver, inbox: i64, file: &str, subject: &str) -> bool {
    let added = d.add_message(&read_fixture(file), &["\\Seen"]).is_ok();
    run_command(Command::Sync);
    let listed = wait_until(30, || {
        listed_in_folder(inbox, 0, 500)
            .iter()
            .any(|m| m.info.subject == subject)
    })
    .await;
    d.check(added && listed, &format!("{file} is in the Inbox"));
    added && listed
}

/// The fixtures `files` taken away from the server and the list
async fn remove_fixtures(d: &Driver, inbox: i64, files: &[&str], subjects: &[&str]) {
    let ids: Vec<String> = files.iter().map(|name| message_id(&read_fixture(name))).collect();
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
            .any(|m| subjects.contains(&m.info.subject.as_str()))
    })
    .await;
    d.check(gone, "the messages of the step are taken away");
}

/// The message `subject` of the Inbox shown in the reading pane
async fn show(d: &Driver, inbox: i64, subject: &str) -> bool {
    let shown = open_by_subject(inbox, subject).await && wait_until(15, || shell().main().reader.has_view()).await;
    d.check(shown, &format!("\"{subject}\" is shown"));
    shown
}

pub(super) async fn finding_and_publishing(d: &Driver) {
    d.step("finding, publishing and passing on keys");
    let Some(inbox) = super::steps::folder_id("Inbox") else {
        d.check(false, "the tree has the Inbox");
        return;
    };
    select_folder("Inbox");
    publishing(d).await;
    pasting(d).await;
    find_signer(d, inbox).await;
    let cards = cards(d);
    contact_find(d, cards.grace).await;
    attached_key(d, inbox).await;
    book_marks(d).await;
    let frank = learned(d, inbox).await;
    remove_fixtures(
        d,
        inbox,
        &[
            "secure-no-key.eml",
            "key-attached.eml",
            "secure-previews.eml",
            "autocrypt-frank-1.eml",
            "autocrypt-frank-2.eml",
        ],
        &[NO_KEY, KEY_ATTACHED, PREVIEWS, FRANK_1, FRANK_2],
    )
    .await;
    let _ = shell().core.delete_cards(&[cards.alice, cards.bob, cards.grace, frank]);
    crate::address_book::refresh();
}

/// My Keys > Publish: greyed for a contact's key; for the account's key it asks first, naming its address, then the
/// harness (as keys.openpgp.org) has the key and was asked to confirm the address
async fn publishing(d: &Driver) {
    let core = &shell().core;
    let own = core
        .pgp_identities()
        .unwrap_or_default()
        .into_iter()
        .find(|identity| identity.address == ME)
        .map(|identity| identity.fingerprint)
        .unwrap_or_default();
    let alice = key_named("Alice Example")
        .map(|key| key.fingerprint)
        .unwrap_or_default();
    let Some(keys) = open_keys(d).await else { return };
    d.check(
        select_fingerprint(&keys, &alice) && !sensitive(&keys, "keys-publish") && sensitive(&keys, "keys-export"),
        "with Alice's key selected Publish is greyed: a contact's key is not the user's to publish",
    );
    d.check(
        select_fingerprint(&keys, &own) && sensitive(&keys, "keys-publish"),
        "with the account's key selected Publish is offered",
    );
    let uploads = harness_list(d, "/pgp/uploads").len();
    click(&keys, "keys-publish");
    let Some(ask) = wait_alert(10).await else {
        d.check(false, "Publish asks first");
        close_keys(&keys).await;
        return;
    };
    let question = tr_args(Text::UiKeysPublishAsk, &[("addresses", ME.into())]);
    let labels: Vec<String> = ["cancel", "publish"]
        .iter()
        .filter(|id| ask.has_response(id))
        .map(|id| ask.response_label(id).to_string())
        .collect();
    d.check(
        alert_text(&ask).contains(&question)
            && labels == [tr(Text::UiCancel), crate::words::plain(Text::UiKeysPublishNow)],
        &format!(
            "Publish asks first, naming the address, with Cancel and Publish ({}: {labels:?})",
            alert_text(&ask)
        ),
    );
    d.shot(&ask, "keys-12-publish").await;
    answer(&ask, "Publish");
    let said = wait_alert(20).await;
    let text = said.as_ref().map(alert_text).unwrap_or_default();
    let pending = tr_args(Text::PgpPublishPending, &[("addresses", ME.into())]);
    d.check(
        text.contains(&pending),
        &format!("Publish says the server sent a confirmation link to the address ({text})"),
    );
    if let Some(said) = &said {
        d.shot(said, "keys-12b-published").await;
        dismiss(said).await;
    }
    let sent: Vec<Value> = harness_list(d, "/pgp/uploads").into_iter().skip(uploads).collect();
    let addresses = serde_json::json!([ME]);
    d.check(
        sent.len() == 1
            && sent[0]["fingerprint"]
                .as_str()
                .is_some_and(|f| f.eq_ignore_ascii_case(&own))
            && sent[0]["addresses"] == addresses
            && sent[0]["asked"] == addresses,
        &format!("the server got the account's key and was asked to confirm {ME} ({sent:?})"),
    );
    close_keys(&keys).await;
}

/// Import from Clipboard: plain text says the clipboard holds no key and imports nothing; Judy's key copied as text is
/// imported, "Pasted"
async fn pasting(d: &Driver) {
    let Some(keys) = open_keys(d).await else { return };
    let clipboard = keys.clipboard();
    let before = shell().core.pgp_keys().unwrap_or_default().len();
    clipboard.set_text("not a key");
    click(&keys, "keys-paste");
    let said = wait_alert(10).await;
    let text = said.as_ref().map(alert_text).unwrap_or_default();
    d.check(
        text.contains(&tr(Text::UiKeysPasteNone)) && shell().core.pgp_keys().unwrap_or_default().len() == before,
        &format!("Import from Clipboard with plain text on it says it holds no key, and imports nothing ({text})"),
    );
    if let Some(said) = &said {
        dismiss(said).await;
    }
    clipboard.set_text(&read_fixture("judy.asc"));
    click(&keys, "keys-paste");
    let said = wait_alert(10).await;
    let text = said.as_ref().map(alert_text).unwrap_or_default();
    d.check(
        text.contains("One key was imported"),
        &format!("with Judy's key copied it says one key was imported ({text})"),
    );
    if let Some(said) = &said {
        dismiss(said).await;
    }
    let listed = wait_until(5, || {
        keys_listed(&keys).iter().any(|row| {
            row.contains("Judy Example")
                && row.contains("judy@example.net")
                && row.contains("Contact")
                && row.contains("Valid")
        })
    })
    .await;
    d.check(
        listed,
        &format!(
            "the list shows Judy Example, judy@example.net, Contact, Valid ({:?})",
            keys_listed(&keys)
        ),
    );
    d.shot(&keys, "keys-13-paste").await;
    let source = key_named("Judy Example").map(|key| key.source).unwrap_or_default();
    d.check(
        source == tr(Text::PgpSourcePaste),
        &format!("her Properties say \"{}\" ({source})", tr(Text::PgpSourcePaste)),
    );
    clipboard.set_text("");
    close_keys(&keys).await;
}

/// The words, tone and pictures of the reading pane's security bar
fn bar() -> (String, String, Vec<String>) {
    shell().main().reader.security.shown().unwrap_or_default()
}

/// Find Key beside the label of a part signed by Dave's key, which the harness has without his address: the lookup by
/// the fingerprint alone, then the message shown again naming him
async fn find_signer(d: &Driver, inbox: i64) {
    let dave = serve_key(d, "dave.asc", None, false);
    d.check(!dave.is_empty(), "the harness serves Dave's key by its fingerprint");
    if !add_fixture(d, inbox, "secure-no-key.eml", NO_KEY).await || !show(d, inbox, NO_KEY).await {
        return;
    }
    let main = shell().main();
    let link = format!("{}{dave}", pe_html::FIND_KEY_LINK);
    let (text, tone, _) = wait_for(10, || main.reader.security.shown()).await.unwrap_or_default();
    d.check(
        text.contains(&tr(Text::PgpPartUnknownKey)) && tone == "neutral" && main.reader.preview().shown().contains(&link),
        &format!("the bar is grey, \"Signed, but the key is not known\", and the label has Find Key for {dave} ({tone}: {text})"),
    );
    d.shot(main.window(), "keys-14a-find-key-button").await;
    let before = harness_list(d, "/pgp/lookups").len();
    let view = main.reader.preview().view.clone();
    let clicked = super::previews::run_script(
        &view,
        "(function(){var a=document.querySelector('a.pe-f');if(!a)return 'no';a.click();return 'yes'})()",
    )
    .await
        == "yes";
    let signed = tr_args(Text::PgpPartSigned, &[("signer", "dave@example.com".into())]);
    let shown_again = wait_until(20, || {
        bar().0.contains(&signed) && main.reader.has_view() && !main.reader.preview().shown().contains(&link)
    })
    .await;
    let (text, tone, pictures) = bar();
    d.check(
        clicked && shown_again && tone == "good" && pictures == ["ic-ribbon-symbolic"],
        &format!("Find Key clicked, the message is shown again: blue with the ribbon, \"{signed}\", no Find Key ({tone}, {pictures:?}: {text})"),
    );
    let page = super::steps::document_text(&main.reader.preview().shown_with_parts());
    d.check(page.contains(&signed), "the part's label says the same");
    let asked = lookups_after(d, before);
    d.check(
        asked == [lookup("fingerprint", &dave, true)],
        &format!("the key was asked for by its fingerprint only, no address ({asked:?})"),
    );
    let status = main.status_texts().0;
    let found = tr_args(Text::PgpFoundKeys, &[("addresses", "dave@example.com".into())]);
    d.check(
        status == found,
        &format!("the status bar says what was found ({status})"),
    );
    d.shot(main.window(), "keys-14-find-signer").await;
    listed_as(d, "Dave", "dave@example.com", Text::PgpSourceKeyserver).await;
}

/// The cards of the step for the book's marks: Alice, Bob (his key removed in 19h) and Grace
struct Cards {
    alice: pe_store::CardId,
    bob: pe_store::CardId,
    grace: pe_store::CardId,
}

fn card(name: &str, address: &str) -> pe_store::CardId {
    let (first, last) = name.split_once(' ').unwrap_or((name, ""));
    let card = pe_store::Card {
        name: name.into(),
        first: first.into(),
        last: last.into(),
        addresses: vec![address.into()],
        ..Default::default()
    };
    shell().core.save_card(&card).unwrap_or(0)
}

fn cards(d: &Driver) -> Cards {
    let cards = Cards {
        alice: card("Alice Example", "alice@example.org"),
        bob: card("Bob Example", "bob@example.net"),
        grace: card("Grace Example", "grace@example.net"),
    };
    d.check(
        cards.alice != 0 && cards.bob != 0 && cards.grace != 0,
        "cards for Alice, Bob and Grace are in the Address Book",
    );
    crate::address_book::refresh();
    cards
}

/// The Address Book open, in front
async fn open_book(d: &Driver) -> Option<Rc<crate::address_book::Book>> {
    command(Command::AddressBook);
    let book = wait_for(10, crate::address_book::shown).await;
    d.check(book.is_some(), "Tools > Address Book opens");
    let book = book?;
    book.reload();
    wait_until(5, || !book.people().is_empty()).await;
    Some(book)
}

async fn close_book(book: &crate::address_book::Book) {
    book.window.close();
    wait_until(10, || crate::address_book::shown().is_none()).await;
}

/// Contact Properties of the card `id`, from the Address Book's Properties
async fn contact_properties(book: &crate::address_book::Book, id: pe_store::CardId) -> Option<adw::Dialog> {
    let at = book.people().iter().position(|p| p.card == id)?;
    book.select_person(at as u32);
    WidgetExt::activate_action(&book.window, "win.properties", None).ok()?;
    wait_dialog(10, "contact-dialog").await
}

async fn close_contact(contact: &adw::Dialog) {
    click(contact.upcast_ref(), "dialog-cancel");
    wait_gone(10, "contact-dialog").await;
}

/// The title and subtitle of a contact's key row
fn key_row(root: &gtk::Widget, name: &str) -> Option<(String, String)> {
    named_in(root, name).and_downcast::<adw::ActionRow>().map(|row| {
        (
            row.title().to_string(),
            row.subtitle().map(|s| s.to_string()).unwrap_or_default(),
        )
    })
}

/// Find Key in Grace's Properties: her provider's directory answers, the key server is not asked, and her key is
/// shown there
async fn contact_find(d: &Driver, grace: pe_store::CardId) {
    serve_key(d, "grace.asc", Some("grace@example.net"), true);
    let Some(book) = open_book(d).await else { return };
    let Some(contact) = contact_properties(&book, grace).await else {
        d.check(false, "Properties opens Grace's card");
        close_book(&book).await;
        return;
    };
    let c: gtk::Widget = contact.clone().upcast();
    let none = named_in(&c, "contact-key-none").and_downcast::<adw::ActionRow>();
    d.check(
        none.is_some_and(|row| row.title() == tr(Text::UiContactKeyNone)) && sensitive(&c, "contact-find-key"),
        "her Properties say \"No key\" under \"Encryption key\", with Find Key",
    );
    let find = named_in(&c, "contact-find-key").and_downcast::<gtk::Button>();
    d.check(
        find.as_ref().and_then(|b| b.label()).is_some_and(|l| l == "_Find Key")
            && find.is_some_and(|b| b.uses_underline()),
        "Find Key has its access key, Alt+F",
    );
    if let Some(group) = named_in(&c, "contact-keys") {
        scroll_to(&group);
    }
    let before = harness_list(d, "/pgp/lookups").len();
    click(&c, "contact-find-key");
    let grouped = || key_named("Grace Example").map(|key| key.grouped).unwrap_or_default();
    let shown = wait_until(20, || {
        key_row(&c, "contact-key-0")
            .is_some_and(|(title, subtitle)| title.contains("Valid") && !grouped().is_empty() && subtitle == grouped())
    })
    .await;
    let row = key_row(&c, "contact-key-0").unwrap_or_default();
    d.check(
        shown && named_in(&c, "contact-key-verify-0").is_some(),
        &format!("her key is shown: its fingerprint in groups of four, Valid, with Verify ({row:?})"),
    );
    let said = named_in(&c, "contact-keys")
        .and_downcast::<adw::PreferencesGroup>()
        .and_then(|g| g.description())
        .map(|t| t.to_string())
        .unwrap_or_default();
    d.check(
        said == tr_args(Text::PgpFoundKeys, &[("addresses", "grace@example.net".into())])
            && !sensitive(&c, "contact-find-key"),
        &format!("the section says what was found, and Find Key is greyed now that she has a key ({said})"),
    );
    let asked = lookups_after(d, before);
    d.check(
        asked == [lookup("wkd", "grace@example.net", true)],
        &format!("her provider's directory answered first, the key server was not asked ({asked:?})"),
    );
    // the key found in sight, once the rows are laid out again
    in_sight(&c, "contact-key-0").await;
    d.shot(&contact, "keys-15-contact-find").await;
    close_contact(&contact).await;
    close_book(&book).await;
    listed_as(d, "Grace Example", "grace@example.net", Text::PgpSourceWkd).await;
}

/// The form scrolled until the widget `name` is in sight: the rows just made are laid out a moment later
async fn in_sight(root: &gtk::Widget, name: &str) -> bool {
    wait_until(5, || {
        let Some(widget) = named_in(root, name) else {
            return false;
        };
        let Some(scrolled) = widget.ancestor(gtk::ScrolledWindow::static_type()) else {
            return false;
        };
        let seen = widget
            .compute_bounds(&scrolled)
            .is_some_and(|b| b.y() >= 0.0 && b.y() + b.height() <= scrolled.height() as f32);
        if !seen {
            scroll_to(&widget);
        }
        seen
    })
    .await
}

/// The strip's menu of file `index` opened, as the menu key opens it, and its words
async fn strip_menu(index: usize) -> Vec<String> {
    let strip = &shell().main().reader.strip;
    let Some(child) = strip.flow.child_at_index(index as i32) else {
        return Vec::new();
    };
    strip.flow.select_child(&child);
    child.grab_focus();
    strip.popup_menu(&child, None);
    let menu = wait_for(5, || strip.open_menu()).await;
    menu_labels(menu.as_ref())
}

async fn close_strip_menu() {
    let strip = &shell().main().reader.strip;
    if let Some(menu) = strip.open_menu() {
        menu.popdown();
    }
    wait_until(5, || strip.open_menu().is_none()).await;
}

/// Import Key on the key Erin attached: offered for it, not for a picture; imported, "From a message"
async fn attached_key(d: &Driver, inbox: i64) {
    let import = tr(Text::UiAttachmentImportKey).replace("...", "\u{2026}");
    if add_fixture(d, inbox, "secure-previews.eml", PREVIEWS).await && show(d, inbox, PREVIEWS).await {
        let strip = &shell().main().reader.strip;
        let harbour = wait_for(10, || strip.shown().iter().position(|f| f.name == "harbour.png")).await;
        let labels = match harbour {
            Some(at) => strip_menu(at).await,
            None => Vec::new(),
        };
        d.check(
            !labels.is_empty() && !labels.contains(&import),
            &format!("a picture's menu has no Import Key ({labels:?})"),
        );
        close_strip_menu().await;
    }
    if !add_fixture(d, inbox, "key-attached.eml", KEY_ATTACHED).await || !show(d, inbox, KEY_ATTACHED).await {
        return;
    }
    let main = shell().main();
    let strip = &main.reader.strip;
    let files = wait_for(10, || Some(strip.shown()).filter(|f| !f.is_empty()))
        .await
        .unwrap_or_default();
    d.check(
        files.len() == 1 && files[0].name == "Erin Example public key.asc",
        &format!("the strip shows \"Erin Example public key.asc\" ({files:?})"),
    );
    let labels = strip_menu(0).await;
    d.check(
        labels.contains(&import),
        &format!("its menu has Import Key\u{2026} ({labels:?})"),
    );
    d.shot(main.window(), "keys-16-attached-key").await;
    let chosen = strip
        .open_menu()
        .is_some_and(|menu| WidgetExt::activate_action(&menu, "reader.import-key", Some(&0u32.to_variant())).is_ok());
    close_strip_menu().await;
    let said = wait_alert(10).await;
    let text = said.as_ref().map(alert_text).unwrap_or_default();
    d.check(
        chosen && text.contains("One key was imported"),
        &format!("Import Key says one key was imported ({text})"),
    );
    if let Some(said) = &said {
        dismiss(said).await;
    }
    listed_as(d, "Erin Example", "erin@example.org", Text::PgpSourceAttachment).await;
}

/// The key mark of each person the Address Book lists, by their name: its tooltip, and its accessible name the same
fn marks(book: &crate::address_book::Book) -> Vec<(String, String)> {
    let root: gtk::Widget = book.view.clone().upcast();
    descendants::<gtk::Image>(&root)
        .into_iter()
        .filter(|image| image.widget_name() == "book-key-mark" && image.is_mapped())
        .filter_map(|image| {
            let mut row = image.parent();
            while let Some(widget) = row.clone().filter(|w| w.css_name() != "row") {
                row = widget.parent();
            }
            let name = descendants::<gtk::Label>(&row?).first()?.text().to_string();
            Some((name, image.tooltip_text().map(|t| t.to_string()).unwrap_or_default()))
        })
        .collect()
}

/// The Address Book's marks: Alice's verified key, Grace's key, none for Bob, drawn differently
async fn book_marks(d: &Driver) {
    let Some(book) = open_book(d).await else { return };
    let (known, verified) = (tr(Text::UiBookKeyKnown), tr(Text::UiBookKeyVerified));
    let wanted = vec![
        ("Alice Example".to_string(), verified.clone()),
        ("Bob Example".to_string(), String::new()),
        ("Grace Example".to_string(), known.clone()),
    ];
    let shown = wait_until(10, || {
        let mut marks = marks(&book);
        marks.sort();
        marks == wanted
    })
    .await;
    d.check(
        shown,
        &format!(
            "Alice has the verified key mark, Grace the key mark, Bob none ({:?})",
            marks(&book)
        ),
    );
    let icons: Vec<String> = descendants::<gtk::Image>(book.view.upcast_ref())
        .into_iter()
        .filter(|image| image.widget_name() == "book-key-mark" && image.is_mapped())
        .filter_map(|image| crate::icons::name_of(&image))
        .collect();
    d.check(
        icons.len() == 2 && icons[0] != icons[1],
        &format!("the two marks are drawn differently ({icons:?})"),
    );
    d.shot(&book.window, "keys-17-book-marks").await;
    super::compose_keys::in_dark(d, &book.window, "keys-17-book-marks-dark").await;
    close_book(&book).await;
}

/// Frank's key learned from the Autocrypt header of his first message, without a question; his second one with
/// another key leaves it waiting in his Properties, and Keep the Current One keeps the first. His card, made here
async fn learned(d: &Driver, inbox: i64) -> pe_store::CardId {
    if add_fixture(d, inbox, "autocrypt-frank-1.eml", FRANK_1).await && show(d, inbox, FRANK_1).await {
        d.check(alert().is_none(), "opening Frank's message asks nothing");
        listed_as(d, "Frank Example", "frank@example.org", Text::PgpSourceAutocrypt).await;
    }
    let noted = key_named("Frank Example").map(|key| key.grouped).unwrap_or_default();
    let frank = card("Frank Example", "frank@example.org");
    crate::address_book::refresh();
    let frank_row = async |d: &Driver, shot: Option<&str>| -> Option<(String, String)> {
        let book = open_book(d).await?;
        let Some(contact) = contact_properties(&book, frank).await else {
            d.check(false, "Properties opens Frank's card");
            close_book(&book).await;
            return None;
        };
        let c: gtk::Widget = contact.clone().upcast();
        let row = key_row(&c, "contact-key-0");
        if let Some(name) = shot {
            if let Some(group) = named_in(&c, "contact-keys") {
                scroll_to(&group);
            }
            d.shot(&contact, name).await;
        }
        close_contact(&contact).await;
        close_book(&book).await;
        row
    };
    let row = frank_row(d, Some("keys-18-learned")).await.unwrap_or_default();
    d.check(
        !noted.is_empty() && row.1 == noted && row.0.contains("Valid"),
        &format!("his card shows the key's fingerprint and Valid ({row:?})"),
    );

    if add_fixture(d, inbox, "autocrypt-frank-2.eml", FRANK_2).await && show(d, inbox, FRANK_2).await {
        d.check(
            alert().is_none(),
            "opening his second message asks nothing in the reading pane",
        );
    }
    let Some(book) = open_book(d).await else {
        return frank;
    };
    match contact_properties(&book, frank).await {
        Some(contact) => {
            let c: gtk::Widget = contact.clone().upcast();
            let row = key_row(&c, "contact-key-0").unwrap_or_default();
            let pending = key_row(&c, "contact-key-pending-0").unwrap_or_default();
            let note = "A different key for frank@example.org was found on";
            d.check(
                row.1 == noted && pending.0.starts_with(note),
                &format!("his Properties show the key noted still in use, and the note of a different key ({row:?}, {pending:?})"),
            );
            let words = |name: &str| {
                named_in(&c, name)
                    .and_downcast::<gtk::Button>()
                    .and_then(|b| b.label())
                    .map(|l| l.to_string())
                    .unwrap_or_default()
            };
            d.check(
                words("contact-key-use-new-0") == crate::words::plain(Text::UiContactKeyUseNew)
                    && words("contact-key-keep-0") == crate::words::plain(Text::UiContactKeyKeep),
                "with Use the New Key and Keep the Current One",
            );
            if let Some(group) = named_in(&c, "contact-keys") {
                scroll_to(&group);
            }
            d.shot(&contact, "keys-19-changed-key").await;
            click(&c, "contact-key-keep-0");
            let kept = wait_until(10, || {
                named_in(&c, "contact-key-pending-0").is_none()
                    && named_in(&c, "contact-key-keep-0").is_none()
                    && key_row(&c, "contact-key-0").is_some_and(|r| r.1 == noted)
            })
            .await;
            d.check(
                kept,
                "Keep the Current One takes the note and its buttons away, his key still the one noted",
            );
            close_contact(&contact).await;
        }
        None => d.check(false, "Properties opens Frank's card"),
    }
    close_book(&book).await;
    let again = frank_row(d, None).await.unwrap_or_default();
    d.check(
        again.1 == noted,
        &format!("opened again, his Properties show the same key ({again:?})"),
    );
    frank
}
