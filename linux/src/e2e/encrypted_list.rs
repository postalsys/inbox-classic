//! Encrypted and signed mail in the list and the search (SCENARIO 19i, `main-12-lock-in-list`, `search-9-encrypted`)
//! and the Reading page's Encryption group (46, `options-4-encryption`). The list step runs near the end: it downloads
//! ahead, which the steps before do not expect.

use super::secure::{message_id, read_fixture};
use super::*;

const SIGNED: &str = "Signed by Alice";
/// The Subject an encrypted message came with, shown until it is decrypted
const OUTER: &str = "...";
/// The protected Subject of secure-protected-subject.eml, shown once it is decrypted
const PROTECTED: &str = "The mill on Friday";
const FILES: [&str; 3] = [
    "secure-signed.eml",
    "secure-encrypted.eml",
    "secure-protected-subject.eml",
];

/// The icons the classic list shows now, by name
fn list_icons(name: &str) -> usize {
    let view: gtk::Widget = shell().main().list.view.clone().upcast();
    descendants::<gtk::Image>(&view)
        .iter()
        .filter(|image| image.is_mapped() && image.icon_name().as_deref() == Some(name))
        .count()
}

/// The icons the Columns list shows now, by name, with what they say on hover
fn row_icons(name: &str) -> Vec<String> {
    let view: gtk::Widget = shell().main().list.rows_view.clone().upcast();
    descendants::<gtk::Image>(&view)
        .iter()
        .filter(|image| image.is_mapped() && image.icon_name().as_deref() == Some(name))
        .map(|image| image.tooltip_text().map(|t| t.to_string()).unwrap_or_default())
        .collect()
}

/// The messages of the list as it shows them now, by their protection
fn shown(protection: u8) -> Vec<pe_store::Message> {
    shell()
        .main()
        .list
        .shown_messages(500)
        .into_iter()
        .filter(|m| m.info.protection == protection)
        .collect()
}

/// The signed row selected, which scrolls the list to the fixtures' rows
async fn select_signed() {
    let listed = shell().main().list.shown_messages(500);
    if let Some(at) = listed.iter().position(|m| m.info.subject == SIGNED) {
        select_row(u32::try_from(at).unwrap_or(0)).await;
    }
}

/// The fixtures taken away from the server and the list
async fn remove(d: &Driver) {
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
        shown(pe_store::PROTECTION_SIGNED).is_empty() && shown(pe_store::PROTECTION_ENCRYPTED).is_empty()
    })
    .await;
    d.check(gone, "the signed and encrypted messages are taken away");
}

/// The marks in the list, with Search in encrypted messages off; the search of encrypted mail, the switch on again
pub async fn in_the_list_and_the_search(d: &Driver) {
    d.step("encrypted and signed mail in the list and the search");
    let core = &shell().core;
    let main = shell().main();
    let _ = core.set_pgp_index_encrypted(false);
    let _ = core.set_download_ahead(pe_core::Ahead::Recent);
    select_folder("Inbox");
    wait_until(10, || main.selected_name() == "Inbox").await;
    let added = ["secure-signed.eml", "secure-encrypted.eml"]
        .iter()
        .all(|name| d.add_message(&read_fixture(name), &["\\Seen"]).is_ok());
    run_command(Command::Sync);
    let listed = wait_until(30, || {
        shown(pe_store::PROTECTION_SIGNED).len() == 1 && shown(pe_store::PROTECTION_ENCRYPTED).len() == 1
    })
    .await;
    d.check(added && listed, "the signed and the encrypted message are in the Inbox");

    // the new mail notification of an encrypted message names no Subject
    let notify_was = shell().notify.get();
    shell().set_notify(true);
    let before = watch::notified().len();
    let came = watch::while_hidden(d, &read_fixture("secure-protected-subject.eml"), || {
        shown(pe_store::PROTECTION_ENCRYPTED).len() == 2
    })
    .await;
    shell().set_notify(notify_was);
    let said: Vec<(String, String)> = watch::notified().into_iter().skip(before).collect();
    d.check(
        came && said.iter().any(|(title, text)| {
            title.contains("Alice Example") && text.contains("Encrypted message") && !text.contains(OUTER)
        }),
        &format!("the new mail notification of an encrypted message says \"Encrypted message\" ({said:?})"),
    );

    // the marks, the encrypted rows with the Subject they came with and no words of their text
    let encrypted = shown(pe_store::PROTECTION_ENCRYPTED);
    d.check(
        encrypted.iter().all(|m| {
            m.info.subject == OUTER && m.snippet.as_deref() == Some("Encrypted message") && !m.info.has_attachments
        }),
        "with Search in encrypted messages off, an encrypted row is \"...\", \"Encrypted message\", no paper clip",
    );
    select_signed().await;
    let marks = || (list_icons("ic-lock-closed-symbolic"), list_icons("ic-ribbon-symbolic"));
    d.check(
        wait_until(10, || marks() == (2, 1)).await,
        &format!(
            "the list has the lock on the encrypted rows, the ribbon on the signed one, nothing on the others ({:?})",
            marks()
        ),
    );
    d.shot(main.window(), "main-12-lock-in-list").await;
    let styles = adw::StyleManager::default();
    styles.set_color_scheme(adw::ColorScheme::ForceDark);
    wait_until(5, || styles.is_dark()).await;
    d.shot(main.window(), "main-12-lock-in-list-dark").await;
    styles.set_color_scheme(adw::ColorScheme::Default);
    wait_until(5, || !styles.is_dark()).await;

    command(Command::LayoutColumns);
    wait_until(10, || main.list.rows_view.is_mapped()).await;
    // the fixtures are older than the rest: their rows scrolled to
    select_signed().await;
    let locks = row_icons("ic-lock-closed-symbolic");
    let ribbons = row_icons("ic-ribbon-symbolic");
    d.check(
        locks.len() == 2 && locks.iter().all(|t| t == "Encrypted") && ribbons == ["Signed"],
        &format!("the Columns rows have the lock and the ribbon among their marks ({locks:?}, {ribbons:?})"),
    );
    let snippets: Vec<String> = layout::rows_on_screen()
        .into_iter()
        .filter(|(_, subject, _, _)| subject == OUTER)
        .map(|(_, _, snippet, _)| snippet)
        .collect();
    d.check(
        snippets.len() == 2 && snippets.iter().all(|s| s == "Encrypted message"),
        &format!("their line of first words says \"Encrypted message\" ({snippets:?})"),
    );
    d.shot(main.window(), "main-12-lock-in-list-columns").await;
    styles.set_color_scheme(adw::ColorScheme::ForceDark);
    wait_until(5, || styles.is_dark()).await;
    d.shot(main.window(), "main-12-lock-in-list-columns-dark").await;
    styles.set_color_scheme(adw::ColorScheme::Default);
    wait_until(5, || !styles.is_dark()).await;
    command(Command::LayoutClassic);
    wait_until(10, || main.list.view.is_mapped()).await;

    // is:encrypted, is:signed and -is:encrypted
    let all = messages_listed();
    search("is:encrypted").await;
    d.check(
        wait_until(10, || {
            let listed = main.list.shown_messages(500);
            listed.len() == 2
                && listed
                    .iter()
                    .all(|m| m.info.protection == pe_store::PROTECTION_ENCRYPTED)
        })
        .await,
        "is:encrypted lists the encrypted messages alone",
    );
    search("is:signed").await;
    d.check(
        wait_until(10, || {
            let listed = main.list.shown_messages(500);
            listed.len() == 1 && listed[0].info.subject == SIGNED
        })
        .await,
        "is:signed lists the signed one alone",
    );
    search("-is:encrypted in:inbox").await;
    d.check(
        wait_until(10, || {
            let listed = main.list.shown_messages(500);
            messages_listed() + 2 == all
                && listed
                    .iter()
                    .all(|m| m.info.protection != pe_store::PROTECTION_ENCRYPTED)
        })
        .await,
        &format!(
            "-is:encrypted lists all but the encrypted ones ({} of {all})",
            messages_listed()
        ),
    );

    // the switch off: a word of the text is not found, the sender is
    search("mill").await;
    d.check(
        wait_until(10, || rows() == 0).await,
        "with Search in encrypted messages off, a word of its text (\"mill\") finds nothing",
    );
    search("alice").await;
    d.check(
        wait_until(10, || shown(pe_store::PROTECTION_ENCRYPTED).len() == 2).await,
        "and its sender (\"alice\") finds it",
    );

    // on: the background pass decrypts what is downloaded, never opened, and the rows follow without a click
    search("").await;
    select_folder("Inbox");
    wait_until(10, || main.selected_name() == "Inbox").await;
    let _ = core.set_pgp_index_encrypted(true);
    let decrypted = wait_until(60, || {
        let encrypted = shown(pe_store::PROTECTION_ENCRYPTED);
        encrypted.iter().any(|m| m.info.subject == PROTECTED)
            && encrypted
                .iter()
                .all(|m| m.snippet.as_deref().is_some_and(|s| s != "Encrypted message"))
    })
    .await;
    let rows: Vec<(String, Option<String>)> = shown(pe_store::PROTECTION_ENCRYPTED)
        .into_iter()
        .map(|m| (m.info.subject, m.snippet))
        .collect();
    d.check(
        decrypted,
        &format!(
            "on, the background pass decrypts them unopened: the list shows their first words and the protected \
             Subject \"{PROTECTED}\" ({rows:?})"
        ),
    );
    search("mill").await;
    d.check(
        wait_until(30, || {
            if shown(pe_store::PROTECTION_ENCRYPTED).is_empty() {
                // the index follows the background pass: the search again once it is in
                shell().main().find.set_text("mill ");
                shell().main().find.set_text("mill");
            }
            !shown(pe_store::PROTECTION_ENCRYPTED).is_empty()
        })
        .await,
        "and \"mill\" finds the encrypted message",
    );
    d.shot(main.window(), "search-9-encrypted").await;
    search("").await;
    remove(d).await;
    let _ = core.set_download_ahead(pe_core::Ahead::Never);
}

/// The page of `row` scrolled to its end, where the Encryption group is
async fn to_the_end(row: &impl IsA<gtk::Widget>) {
    if let Some(scrolled) = row
        .ancestor(gtk::ScrolledWindow::static_type())
        .and_downcast::<gtk::ScrolledWindow>()
    {
        pause(300).await;
        let adjustment = scrolled.vadjustment();
        adjustment.set_value(adjustment.upper() - adjustment.page_size());
    }
    pause(300).await;
}

/// The Reading page's Encryption group: both switches on at first with their notes, each off and on again, kept when
/// Preferences opens again
pub async fn encryption_settings(d: &Driver) {
    d.step("Preferences: Encryption");
    let core = &shell().core;
    let open = || async {
        command(Command::Options);
        let dialog = wait_dialog(10, "preferences-dialog").await;
        if let Some(dialog) = &dialog {
            preferences_page(dialog, SettingsPage::Reading);
            pause(300).await;
        }
        dialog
    };
    let switches = |dialog: &adw::Dialog| {
        let root = dialog.clone().upcast::<gtk::Widget>();
        (
            setting_row(&root, Setting::SearchEncrypted).and_downcast::<adw::SwitchRow>(),
            setting_row(&root, Setting::Keyserver).and_downcast::<adw::SwitchRow>(),
        )
    };
    let close = |dialog: adw::Dialog| async move {
        dialog.close();
        wait_gone(10, "preferences-dialog").await;
    };

    let Some(dialog) = open().await else {
        return d.check(false, "the main menu's Preferences opens");
    };
    let (Some(search), Some(keyserver)) = switches(&dialog) else {
        return d.check(
            false,
            "the Reading page has Search in encrypted messages and Look up keys",
        );
    };
    let group = search
        .ancestor(adw::PreferencesGroup::static_type())
        .and_downcast::<adw::PreferencesGroup>();
    let titles: Vec<String> = search
        .ancestor(adw::PreferencesPage::static_type())
        .map(|page| {
            descendants::<adw::PreferencesGroup>(&page)
                .iter()
                .map(|g| g.title().to_string())
                .collect()
        })
        .unwrap_or_default();
    d.check(
        group.as_ref().is_some_and(|g| g.title() == "Encryption")
            && titles.last().is_some_and(|t| t == "Encryption")
            && keyserver.ancestor(adw::PreferencesGroup::static_type()) == group.clone().map(|g| g.upcast()),
        &format!("the Reading page ends with the Encryption group, both switches in it ({titles:?})"),
    );
    d.check(
        search.is_active() && keyserver.is_active() && core.pgp_index_encrypted().unwrap_or(false),
        "Search in encrypted messages and Look up keys on keys.openpgp.org are on at first",
    );
    d.check(
        search.subtitle().is_some_and(|s| s.contains("not encrypted"))
            && keyserver.subtitle().is_some_and(|s| s.contains("address")),
        "each has its note under it",
    );
    to_the_end(&search).await;
    d.shot(&dialog, "options-4-encryption").await;
    close(dialog).await;
    // for the review of long words and the dark look
    let styles = adw::StyleManager::default();
    for (language, dark) in [("de", false), ("fi", false), ("qps", false), ("en", true)] {
        pe_core::i18n::set_language(language);
        styles.set_color_scheme(if dark {
            adw::ColorScheme::ForceDark
        } else {
            adw::ColorScheme::Default
        });
        if let Some(dialog) = open().await {
            if let (Some(search), _) = switches(&dialog) {
                to_the_end(&search).await;
            }
            let name = if dark { "dark" } else { language };
            d.shot(&dialog, &format!("options-4-encryption-{name}")).await;
            close(dialog).await;
        }
    }
    styles.set_color_scheme(adw::ColorScheme::Default);
    pe_core::i18n::set_language("en");
    let Some(dialog) = open().await else {
        return d.check(false, "Preferences opens again");
    };
    let (Some(search), Some(keyserver)) = switches(&dialog) else {
        return d.check(false, "the Reading page has both switches again");
    };

    search.set_active(false);
    keyserver.set_active(false);
    d.check(
        core.pgp_index_encrypted().ok() == Some(false) && core.pgp_keyserver().ok() == Some(false),
        "each turned off counts at once",
    );
    close(dialog).await;
    let Some(dialog) = open().await else {
        return d.check(false, "Preferences opens again");
    };
    let (Some(search), Some(keyserver)) = switches(&dialog) else {
        return d.check(false, "the Reading page has both switches again");
    };
    d.check(
        !search.is_active() && !keyserver.is_active(),
        "both are kept off when Preferences opens again",
    );
    search.set_active(true);
    keyserver.set_active(true);
    close(dialog).await;
    let Some(dialog) = open().await else {
        return d.check(false, "Preferences opens a third time");
    };
    let (search, keyserver) = switches(&dialog);
    d.check(
        search.is_some_and(|s| s.is_active())
            && keyserver.is_some_and(|k| k.is_active())
            && core.pgp_index_encrypted().ok() == Some(true)
            && core.pgp_keyserver().ok() == Some(true),
        "on again, both stay on when Preferences opens again",
    );
    close(dialog).await;
}
