//! Step 19h of the UI test: Encryption Keys. A key made for the account and backed up under a passphrase (two that
//! differ and a short one refused first), Bob's public key and Carol's private key imported (her passphrase asked
//! for, a wrong one refused, then "Use this key" for her address, which the account has as another address for the
//! while), Bob's key looked at, verified and exported, the account's key in Account Properties' Security, Bob's key in
//! his Address Book card, and Bob's key removed. Carol's key and the account's stay for the steps after.

use super::*;

const PASSPHRASE: &str = "a backup passphrase";
const CAROL_PASSPHRASE: &str = "correct horse battery";

fn key_file(name: &str) -> PathBuf {
    Path::new(env!("CARGO_MANIFEST_DIR"))
        .join("../scripts/ui-e2e/keys")
        .join(name)
}

/// The rows of the Encryption Keys window, each as its words
pub(super) fn keys_listed(dialog: &gtk::Widget) -> Vec<String> {
    named_in(dialog, "keys-list")
        .map(|list| descendants::<adw::ActionRow>(&list))
        .unwrap_or_default()
        .iter()
        .map(|row| {
            let mut words = vec![row.title().to_string(), row.subtitle().unwrap_or_default().to_string()];
            words.extend(
                descendants::<gtk::Label>(row.upcast_ref())
                    .iter()
                    .filter(|l| l.widget_name().starts_with("keys-row-"))
                    .map(|l| l.text().to_string()),
            );
            words.join(" | ")
        })
        .collect()
}

fn sensitive(root: &gtk::Widget, name: &str) -> bool {
    named_in(root, name).is_some_and(|w| w.is_sensitive())
}

/// Selects the row of the key list whose words have `needle`
pub(super) fn select_key(dialog: &gtk::Widget, needle: &str) -> bool {
    let Some(list) = named_in(dialog, "keys-list").and_downcast::<gtk::ListBox>() else {
        return false;
    };
    let Some(at) = keys_listed(dialog).iter().position(|row| row.contains(needle)) else {
        return false;
    };
    list.select_row(list.row_at_index(at as i32).as_ref());
    true
}

pub(super) async fn open_keys(d: &Driver) -> Option<gtk::Widget> {
    command(Command::EncryptionKeys);
    let dialog = wait_dialog(10, "keys-dialog").await;
    d.check(dialog.is_some(), "Tools > Encryption Keys opens the window");
    dialog.map(|dialog| dialog.upcast())
}

pub(super) async fn close_keys(dialog: &gtk::Widget) {
    if let Some(dialog) = dialog.downcast_ref::<adw::Dialog>() {
        dialog.close();
    }
    wait_gone(10, "keys-dialog").await;
}

/// The fingerprint of the key whose name is `name`
fn fingerprint_of(name: &str) -> Option<pe_core::keys::KeyInfo> {
    shell()
        .core
        .pgp_keys()
        .unwrap_or_default()
        .into_iter()
        .find(|key| key.name == name)
}

/// The scrolled window of a form or a page scrolled to show `widget`
fn scroll_to(widget: &gtk::Widget) {
    let Some(scrolled) = widget
        .ancestor(gtk::ScrolledWindow::static_type())
        .and_downcast::<gtk::ScrolledWindow>()
    else {
        return;
    };
    let Some(child) = scrolled.child() else { return };
    if let Some(bounds) = widget.compute_bounds(&child) {
        let adjustment = scrolled.vadjustment();
        // its bottom in sight, with the margin under it when it is the last
        let bottom = bounds.y() as f64 + bounds.height() as f64 + 18.0 - adjustment.page_size();
        adjustment.set_value(bottom.max(0.0).min(adjustment.upper() - adjustment.page_size()));
    }
}

pub(super) async fn encryption_keys(d: &Driver) {
    d.step("encryption keys");
    select_folder("Inbox");
    let Some(keys) = open_keys(d).await else { return };
    let empty = wait_until(5, || {
        keys_listed(&keys).is_empty() && named_in(&keys, "keys-none").is_some()
    })
    .await;
    d.check(empty, "there are no keys yet, and the window says so");
    d.check(
        sensitive(&keys, "keys-new")
            && sensitive(&keys, "keys-import")
            && [
                "keys-export",
                "keys-backup",
                "keys-verify",
                "keys-properties",
                "keys-remove",
            ]
            .iter()
            .all(|name| named_in(&keys, name).is_some_and(|w| !w.is_sensitive())),
        "New Key and Import offered; Export, Back Up, Verify, Properties and Remove greyed",
    );
    d.shot(&keys, "keys-1-empty").await;

    // a key for the account, backed up at once
    click(&keys, "keys-new");
    let Some(new) = wait_dialog(10, "key-new-dialog").await else {
        d.check(false, "New Key opens its window");
        return;
    };
    let new_widget: gtk::Widget = new.clone().upcast();
    let account = named_in(&new_widget, "key-new-account")
        .and_downcast::<adw::ComboRow>()
        .and_then(|combo| combo.selected_item())
        .and_downcast::<gtk::StringObject>()
        .map(|s| s.string().to_string())
        .unwrap_or_default();
    d.check(
        account.contains("inboxclassic.test") || account.contains("Alex"),
        &format!("New Key names the account it is for, chosen ({account})"),
    );
    d.check(
        named_in(&new_widget, "key-memory-only").is_some(),
        "and says that passwords are kept in memory only",
    );
    d.shot(&new, "keys-2-new-key").await;
    click(&new_widget, "dialog-ok");
    let Some(offer) = wait_alert(10).await else {
        d.check(false, "Make Key makes it and offers a backup");
        return;
    };
    d.check(
        alert_text(&offer).contains("Save a backup"),
        &format!("Make Key makes it and offers a backup ({})", alert_text(&offer)),
    );
    d.shot(&offer, "keys-3-backup-offer").await;
    answer(&offer, "Backup");
    let Some(backup) = wait_dialog(10, "key-backup-dialog").await else {
        d.check(false, "Save a Backup asks for a passphrase");
        return;
    };
    let b: gtk::Widget = backup.clone().upcast();
    let refused = async |first: &str, again: &str, words: &str, what: &str| {
        set_text(&b, "key-passphrase", first);
        set_text(&b, "key-passphrase-again", again);
        click(&b, "dialog-ok");
        let said = wait_alert(10).await;
        let text = said.as_ref().map(alert_text).unwrap_or_default();
        d.check(text.contains(words), &format!("{what} ({text})"));
        if let Some(said) = said {
            answer(&said, "OK");
        }
        pause(300).await;
    };
    refused(
        PASSPHRASE,
        "another passphrase",
        "not the same",
        "two different passphrases are refused",
    )
    .await;
    refused("short", "short", "at least 8", "a short passphrase is refused").await;
    d.check(
        dialog_named("key-backup-dialog").is_some(),
        "the backup window stays open after each",
    );
    set_text(&b, "key-passphrase", PASSPHRASE);
    set_text(&b, "key-passphrase-again", PASSPHRASE);
    d.shot(&backup, "keys-4-backup").await;
    let saved = d.out.join("backup.asc");
    let _ = std::fs::remove_file(&saved);
    FILE_ANSWERS.with(|a| a.borrow_mut().push_back(vec![saved.clone()]));
    click(&b, "dialog-ok");
    let done = wait_alert(10).await;
    d.check(
        done.as_ref()
            .is_some_and(|a| alert_text(a).contains("The backup was saved")),
        "a good passphrase saves the backup, and says so",
    );
    if let Some(done) = done {
        answer(&done, "OK");
    }
    wait_gone(10, "key-backup-dialog").await;
    let backup_bytes = std::fs::read(&saved).unwrap_or_default();
    let core = &shell().core;
    d.check(
        String::from_utf8_lossy(&backup_bytes).starts_with("-----BEGIN PGP PRIVATE KEY BLOCK-----")
            && matches!(
                core.pgp_import(&backup_bytes, None, pe_core::keys::KeySource::File),
                Err(pe_core::keys::ImportError::NeedsPassphrase)
            )
            && matches!(
                core.pgp_import(&backup_bytes, Some("not it at all"), pe_core::keys::KeySource::File),
                Err(pe_core::keys::ImportError::WrongPassphrase)
            ),
        "the file is an armored private key that asks for that passphrase",
    );

    // the list with the new key
    let listed = keys_listed(&keys);
    d.check(
        listed.len() == 1
            && listed[0].contains("Alex Morgan")
            && listed[0].contains("testuser@inboxclassic.test")
            && listed[0].contains("Your key")
            && listed[0].contains("Valid"),
        &format!("the list shows the new key: name, address, Your key, Valid ({listed:?})"),
    );
    d.check(
        sensitive(&keys, "keys-backup") && !sensitive(&keys, "keys-verify"),
        "Back Up offered for it, Verify not (an own key)",
    );
    d.shot(&keys, "keys-5-list").await;
    let own = fingerprint_of("Alex Morgan")
        .map(|key| key.fingerprint)
        .unwrap_or_default();
    d.check(
        core.pgp_identities()
            .unwrap_or_default()
            .iter()
            .any(|i| i.address == "testuser@inboxclassic.test" && i.fingerprint == own),
        "it is the account's key",
    );

    // Bob's public key
    FILE_ANSWERS.with(|a| a.borrow_mut().push_back(vec![key_file("bob.pub.asc")]));
    click(&keys, "keys-import");
    let said = wait_alert(10).await;
    let text = said.as_ref().map(alert_text).unwrap_or_default();
    d.check(
        text.contains("was imported"),
        &format!("Import of Bob's key says what it did ({text})"),
    );
    if let Some(said) = said {
        answer(&said, "OK");
    }
    let bob_listed = wait_until(5, || {
        keys_listed(&keys)
            .iter()
            .any(|row| row.contains("Bob Example") && row.contains("Contact") && row.contains("Valid"))
    })
    .await;
    d.check(
        bob_listed,
        &format!("Bob is listed: Contact, Valid ({:?})", keys_listed(&keys)),
    );

    // Carol's private key, for an address the account has for the while
    let account_id = shell().main().current_account();
    let _ = core.set_account_addresses_text(account_id, "carol@example.org");
    FILE_ANSWERS.with(|a| a.borrow_mut().push_back(vec![key_file("carol.sec.asc")]));
    click(&keys, "keys-import");
    match wait_dialog(10, "key-import-dialog").await {
        Some(ask) => {
            let a: gtk::Widget = ask.clone().upcast();
            d.shot(&ask, "keys-6-import-passphrase").await;
            set_text(&a, "key-import-passphrase", "the wrong one");
            click(&a, "dialog-ok");
            let wrong = wait_until(10, || named_in(&a, "key-import-error").is_some()).await;
            d.check(
                wrong && dialog_named("key-import-dialog").is_some(),
                &format!(
                    "a wrong passphrase says so and asks again ({})",
                    label_of(&a, "key-import-error")
                ),
            );
            set_text(&a, "key-import-passphrase", CAROL_PASSPHRASE);
            click(&a, "dialog-ok");
            let summary = wait_alert(10).await;
            let text = summary.as_ref().map(alert_text).unwrap_or_default();
            d.check(
                text.contains("private key"),
                &format!("the right one imports it ({text})"),
            );
            if let Some(summary) = summary {
                answer(&summary, "OK");
            }
            let use_for = wait_alert(10).await;
            let text = use_for.as_ref().map(alert_text).unwrap_or_default();
            d.check(
                text.contains("Use this key for carol@example.org?"),
                &format!("and asks to use it for carol@example.org ({text})"),
            );
            if let Some(use_for) = use_for {
                d.shot(&use_for, "keys-7-use-for").await;
                answer(&use_for, "Use");
            }
        }
        None => d.check(false, "Import of Carol's key asks for its passphrase"),
    }
    pause(500).await;
    let carol = fingerprint_of("Carol Example")
        .map(|key| key.fingerprint)
        .unwrap_or_default();
    d.check(
        !carol.is_empty()
            && core
                .pgp_identities()
                .unwrap_or_default()
                .iter()
                .any(|i| i.address == "carol@example.org" && i.fingerprint == carol),
        "Use It makes it the key of carol@example.org",
    );
    let _ = core.set_account_addresses_text(account_id, "");

    // Bob's key: Properties, Verify, Export
    d.check(select_key(&keys, "Bob Example"), "Bob's key selected");
    click(&keys, "keys-properties");
    match wait_dialog(10, "key-properties-dialog").await {
        Some(properties) => {
            let p: gtk::Widget = properties.clone().upcast();
            let value = |name: &str| {
                named_in(&p, name)
                    .and_downcast::<adw::ActionRow>()
                    .and_then(|row| row.subtitle())
                    .map(|s| s.to_string())
                    .unwrap_or_default()
            };
            let bob = fingerprint_of("Bob Example").map(|key| key.grouped).unwrap_or_default();
            let checks = [
                ("names", value("key-names").contains("Bob Example")),
                (
                    "fingerprint in groups of four",
                    !bob.is_empty() && value("key-fingerprint") == bob,
                ),
                ("Valid", value("key-status") == "Valid"),
                ("created", !value("key-created").is_empty()),
                ("expires Never", value("key-expires") == "Never"),
                ("Ed25519", value("key-algorithm").contains("Ed25519")),
                (
                    "imported from a file",
                    value("key-source").to_lowercase().contains("file"),
                ),
                (
                    "bob@example.net (not verified)",
                    value("key-addresses") == "bob@example.net (not verified)",
                ),
            ];
            let failed: Vec<&str> = checks.iter().filter(|(_, ok)| !ok).map(|(what, _)| *what).collect();
            d.check(
                failed.is_empty(),
                &format!("Properties of Bob's key: names, fingerprint, state, dates, kind, source, addresses (wrong: {failed:?})"),
            );
            d.shot(&properties, "keys-8-properties").await;
            properties.close();
            wait_gone(10, "key-properties-dialog").await;
        }
        None => d.check(false, "Properties opens Key Properties"),
    }
    click(&keys, "keys-verify");
    match wait_alert(10).await {
        Some(verify) if verify.widget_name() == "key-verify-dialog" => {
            let fingerprint = label_of(verify.upcast_ref(), "key-verify-fingerprint");
            d.check(
                fingerprint.lines().count() == 2 && fingerprint.split_whitespace().count() == 10,
                &format!("Verify shows the fingerprint in two lines of five groups ({fingerprint})"),
            );
            d.check(alert_text(&verify).contains("Bob Example"), "the intro names Bob");
            let marks = label_of(verify.upcast_ref(), "key-verify-marks");
            d.check(
                marks.contains("bob@example.net"),
                &format!("and the addresses They Match marks ({marks})"),
            );
            d.shot(&verify, "keys-9-verify").await;
            answer(&verify, "Match");
        }
        _ => d.check(false, "Verify opens Verify Key"),
    }
    let verified = wait_until(5, || {
        keys_listed(&keys)
            .iter()
            .any(|row| row.contains("Bob Example") && row.contains("Valid, verified"))
    })
    .await;
    d.check(verified, "They Match marks it: the list says Valid, verified");
    select_key(&keys, "Bob Example");
    let exported = d.out.join("bob-exported.asc");
    let _ = std::fs::remove_file(&exported);
    FILE_ANSWERS.with(|a| a.borrow_mut().push_back(vec![exported.clone()]));
    click(&keys, "keys-export");
    let bob = fingerprint_of("Bob Example")
        .map(|key| key.fingerprint)
        .unwrap_or_default();
    let written = wait_for(5, || std::fs::read_to_string(&exported).ok())
        .await
        .unwrap_or_default();
    d.check(
        written.starts_with("-----BEGIN PGP PUBLIC KEY BLOCK-----")
            && core.pgp_file_name(&bob, false).unwrap_or_default() == "Bob Example public key.asc",
        "Export saves an armored public key named \"Bob Example public key.asc\"",
    );
    close_keys(&keys).await;

    // Account Properties > Security
    command(Command::Accounts);
    if let Some(accounts) = wait_dialog(10, "accounts-dialog").await {
        let accounts_widget: gtk::Widget = accounts.clone().upcast();
        click(&accounts_widget, "accounts-properties");
        match wait_dialog(10, "account-properties").await {
            Some(form) => {
                let f: gtk::Widget = form.clone().upcast();
                let choice = named_in(&f, "account-key").and_downcast::<adw::ComboRow>();
                let offered: Vec<String> = choice
                    .as_ref()
                    .and_then(|c| c.model())
                    .map(|model| {
                        (0..model.n_items())
                            .filter_map(|i| model.item(i).and_downcast::<gtk::StringObject>())
                            .map(|s| s.string().to_string())
                            .collect()
                    })
                    .unwrap_or_default();
                let chosen = choice.as_ref().map_or(0, |c| c.selected()) as usize;
                d.check(
                    offered.first().is_some_and(|none| none == "None")
                        && offered.get(chosen).is_some_and(|c| c.starts_with("Alex Morgan ("))
                        && offered.iter().any(|c| c.starts_with("Carol Example (")),
                    &format!("Security: the account's key chosen, None and the other own keys offered ({offered:?})"),
                );
                d.check(
                    named_in(&f, "account-key-new").is_some()
                        && named_in(&f, "account-autocrypt")
                            .and_downcast::<adw::SwitchRow>()
                            .is_some_and(|s| s.is_active()),
                    "New Key, and Send my public key with my messages on",
                );
                if let Some(group) = named_in(&f, "account-security") {
                    scroll_to(&group);
                }
                d.shot(&form, "keys-10-account-security").await;
                click(&f, "dialog-cancel");
                wait_gone(10, "account-properties").await;
            }
            None => d.check(false, "Account Properties opens"),
        }
        accounts.close();
        wait_gone(10, "accounts-dialog").await;
    }

    // Bob's card in the Address Book
    let card = pe_store::Card {
        name: "Bob Example".into(),
        first: "Bob".into(),
        last: "Example".into(),
        addresses: vec!["bob@example.net".into()],
        ..Default::default()
    };
    let card_id = core.save_card(&card).unwrap_or(0);
    command(Command::AddressBook);
    if let Some(book) = wait_for(10, crate::address_book::shown).await {
        book.reload();
        pause(400).await;
        book.select_person(0);
        WidgetExt::activate_action(&book.window, "win.properties", None).ok();
        match wait_dialog(10, "contact-dialog").await {
            Some(contact) => {
                let c: gtk::Widget = contact.clone().upcast();
                let row = named_in(&c, "contact-key-0").and_downcast::<adw::ActionRow>();
                let shown = row
                    .as_ref()
                    .map(|r| format!("{} {}", r.title(), r.subtitle().unwrap_or_default()))
                    .unwrap_or_default();
                let grouped = fingerprint_of("Bob Example").map(|key| key.grouped).unwrap_or_default();
                d.check(
                    !grouped.is_empty() && shown.contains(&grouped) && shown.contains("Valid, verified"),
                    &format!("Bob's card shows his key's fingerprint and Valid, verified ({shown})"),
                );
                if let Some(row) = &row {
                    scroll_to(row.upcast_ref());
                }
                d.shot(&contact, "keys-11-contact").await;
                click(&c, "dialog-cancel");
                wait_gone(10, "contact-dialog").await;
            }
            None => d.check(false, "Properties opens Bob's card"),
        }
        book.window.close();
        wait_until(10, || crate::address_book::shown().is_none()).await;
    } else {
        d.check(false, "Tools > Address Book opens");
    }
    let _ = core.delete_cards(&[card_id]);

    // Bob's key removed
    if let Some(keys) = open_keys(d).await {
        select_key(&keys, "Bob Example");
        click(&keys, "keys-remove");
        match wait_alert(10).await {
            Some(sure) => {
                d.check(
                    alert_text(&sure).contains("Remove the key of Bob Example?"),
                    "Remove asks first",
                );
                answer(&sure, "Yes");
            }
            None => d.check(false, "Remove asks first"),
        }
        let left = wait_until(5, || keys_listed(&keys).len() == 2).await;
        d.check(
            left && fingerprint_of("Bob Example").is_none() && fingerprint_of("Carol Example").is_some(),
            "and removes it; Carol's key and the account's stay",
        );
        close_keys(&keys).await;
    }
}
