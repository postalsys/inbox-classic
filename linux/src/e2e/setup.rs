//! Step 45a of the UI test: settings and accounts to another computer. Everything exported under a passphrase (a short
//! one and two that differ refused first), the file an OpenPGP message; a contact deleted, then the file imported
//! (a wrong passphrase refused) with Contacts alone: the contact is back, the accounts as they were. The first-run
//! link of Add Mail Account is checked in step 2 ([`first_run`]).

use pe_core::setup::Parts;

use super::*;

const PASSPHRASE: &str = "moving to a new computer";

/// The rows of the dialog `root`, each as its title and subtitle
fn rows_of(root: &gtk::Widget) -> Vec<String> {
    descendants::<adw::ActionRow>(root)
        .iter()
        .filter(|row| row.is_mapped())
        .map(|row| format!("{} {}", row.title(), row.subtitle().unwrap_or_default()))
        .collect()
}

fn check_on(root: &gtk::Widget, name: &str) -> Option<bool> {
    named_in(root, name)
        .and_downcast::<gtk::CheckButton>()
        .map(|c| c.is_active())
}

fn set_check(root: &gtk::Widget, name: &str, on: bool) {
    if let Some(check) = named_in(root, name).and_downcast::<gtk::CheckButton>() {
        check.set_active(on);
    }
}

fn sensitive(root: &gtk::Widget, name: &str) -> bool {
    named_in(root, name).is_some_and(|w| w.is_sensitive())
}

/// Step 2, before the first account: Add Mail Account offers the import, which opens the file to import (cancelled
/// here) and leaves the form open
pub(super) async fn first_run(d: &Driver, form: &gtk::Widget) {
    let link = named_in(form, "setup-first-run");
    d.check(
        link.is_some(),
        "before the first account, Add Mail Account offers to import settings and accounts from another computer",
    );
    d.shot(form, "setup-5-first-run").await;
    // the Open dialog answered with Cancel
    FILE_ANSWERS.with(|a| a.borrow_mut().push_back(Vec::new()));
    click(form, "setup-first-run");
    let asked = wait_until(5, || FILE_ANSWERS.with(|a| a.borrow().is_empty())).await;
    pause(200).await;
    d.check(
        asked && dialog_named("account-start").is_some() && alert().is_none(),
        "the link opens the file to import; cancelled, the account form stays",
    );
}

pub(super) async fn settings_and_accounts(d: &Driver) {
    d.step("settings and accounts to another computer");
    let core = &shell().core;
    command(Command::ExportSetup);
    let Some(export) = wait_dialog(10, "setup-export-dialog").await else {
        d.check(false, "File > Export Settings and Accounts opens");
        return;
    };
    let e = export.clone().upcast::<gtk::Widget>();
    let all = Parts::EACH
        .iter()
        .all(|part| check_on(&e, &format!("setup-part-{}", part.0)) == Some(true));
    let off = check_on(&e, "setup-use-passphrase") == Some(false) && named_in(&e, "setup-passphrase").is_none();
    let note = descendants::<gtk::Label>(&e)
        .iter()
        .any(|l| l.is_mapped() && l.text().contains("passwords, sign-ins and private keys"));
    d.check(
        all && off && note,
        "File > Export Settings and Accounts lists the parts, all chosen, with the passphrase off and the words of \
         what a passphrase adds",
    );
    d.check(
        named_in(&e, "dialog-ok").is_some_and(|b| b.is_sensitive() && b.is_focus()),
        "Export is the default, ready for Enter",
    );
    d.shot(&export, "setup-1-export").await;

    // the passphrase: a short one, then two that differ, refused with words and Export off
    set_check(&e, "setup-use-passphrase", true);
    pause(200).await;
    let refused = |first: &str, second: &str| {
        set_text(&e, "setup-passphrase", first);
        set_text(&e, "setup-passphrase-again", second);
        let said = label_of(&e, "setup-passphrase-problem");
        let off = !sensitive(&e, "dialog-ok");
        (said, off)
    };
    let (short, short_off) = refused("short", "short");
    d.check(
        short.contains("at least 8") && short_off,
        &format!("a passphrase shorter than 8 characters is refused with words ({short})"),
    );
    d.shot(&export, "setup-2-passphrase").await;
    let (differ, differ_off) = refused(PASSPHRASE, "moving to another computer");
    d.check(
        differ.contains("not the same") && differ_off,
        &format!("or typed differently the second time ({differ})"),
    );
    set_text(&e, "setup-passphrase", PASSPHRASE);
    set_text(&e, "setup-passphrase-again", PASSPHRASE);
    d.check(
        sensitive(&e, "dialog-ok") && label_of(&e, "setup-passphrase-problem").is_empty(),
        "the right one turns Export on",
    );
    let file = d.out.join("setup.inboxclassic");
    let _ = std::fs::remove_file(&file);
    FILE_ANSWERS.with(|a| a.borrow_mut().push_back(vec![file.clone()]));
    click(&e, "dialog-ok");
    match wait_dialog(60, "setup-summary-dialog").await {
        Some(summary) => {
            let s = summary.clone().upcast::<gtk::Widget>();
            let rows = rows_of(&s);
            d.check(
                rows.iter().any(|r| r.contains("Accounts") && r.contains("account"))
                    && rows.iter().any(|r| r.contains("Contacts"))
                    && rows.len() >= 6,
                &format!("the window says what the file holds ({rows:?})"),
            );
            click(&s, "setup-done");
            wait_gone(10, "setup-summary-dialog").await;
        }
        None => d.check(false, "the window says what the file holds"),
    }
    let written = std::fs::read(&file).unwrap_or_default();
    d.check(
        written.starts_with(b"-----BEGIN PGP MESSAGE-----"),
        "with a passphrase the file is written encrypted (an OpenPGP message)",
    );

    // a contact deleted, to come back
    let accounts_before: Vec<i64> = core.accounts().unwrap_or_default().iter().map(|a| a.id).collect();
    let cards = core.cards("").unwrap_or_default();
    let Some(gone) = cards.first().cloned() else {
        d.check(false, "there is a contact to delete before the import");
        return;
    };
    let _ = core.delete_cards(&[gone.id]);
    let is_back = || core.cards("").unwrap_or_default().iter().any(|c| c.name == gone.name);
    d.check(
        !is_back(),
        &format!("a contact is deleted before importing ({})", gone.name),
    );

    FILE_ANSWERS.with(|a| a.borrow_mut().push_back(vec![file.clone()]));
    command(Command::ImportSetup);
    let Some(ask) = wait_dialog(30, "setup-passphrase-dialog").await else {
        d.check(
            false,
            "File > Import Settings and Accounts on that file asks for the passphrase",
        );
        return;
    };
    d.check(
        true,
        "File > Import Settings and Accounts on that file asks for the passphrase",
    );
    let a = ask.clone().upcast::<gtk::Widget>();
    set_text(&a, "setup-passphrase-passphrase", "not the passphrase at all");
    click(&a, "dialog-ok");
    let wrong = wait_for(60, || {
        let said = label_of(&a, "setup-passphrase-error");
        (!said.is_empty() && a.is_sensitive()).then_some(said)
    })
    .await
    .unwrap_or_default();
    d.check(
        wrong.contains("not the passphrase"),
        &format!("a wrong one is refused with words ({wrong})"),
    );
    set_text(&a, "setup-passphrase-passphrase", PASSPHRASE);
    click(&a, "dialog-ok");
    let Some(import) = wait_dialog(60, "setup-import-dialog").await else {
        d.check(false, "the right one shows what the file holds");
        return;
    };
    let i = import.clone().upcast::<gtk::Widget>();
    let account_rows: Vec<adw::ActionRow> = descendants::<adw::ActionRow>(&i)
        .into_iter()
        .filter(|r| r.widget_name().starts_with("setup-account-row-"))
        .collect();
    let all_here = !account_rows.is_empty()
        && account_rows.len() == accounts_before.len()
        && account_rows.iter().all(|row| {
            let check = row.widget_name().replace("setup-account-row-", "setup-account-");
            !row.is_sensitive()
                && check_on(&i, &check) == Some(false)
                && row.subtitle().unwrap_or_default().contains("set up here already")
        });
    d.check(
        all_here,
        &format!(
            "the right one shows what the file holds: the accounts ({} of them, each marked as already here)",
            account_rows.len()
        ),
    );
    let accounts_part = named_in(&i, &format!("setup-part-{}", Parts::ACCOUNTS.0));
    d.check(
        accounts_part.as_ref().is_some_and(|w| !w.is_sensitive())
            && check_on(&i, &format!("setup-part-{}", Parts::ACCOUNTS.0)) == Some(false),
        "with no account to import, the Accounts part is unticked and greyed, its accounts listed with their notes",
    );
    let parts_listed = [Parts::CONTACTS, Parts::SETTINGS, Parts::KEYS]
        .iter()
        .all(|p| check_on(&i, &format!("setup-part-{}", p.0)) == Some(true));
    let empty: Vec<String> = descendants::<adw::ActionRow>(&i)
        .iter()
        .map(|row| row.subtitle().unwrap_or_default().to_string())
        .filter(|words| words.starts_with("0 "))
        .collect();
    let from = label_of(&i, "setup-from");
    d.check(
        parts_listed && empty.is_empty() && from.contains("Saved by Inbox Classic"),
        &format!("the contacts and the other parts (none with nothing in it), with when and by which version it was saved ({from})"),
    );
    d.shot(&import, "setup-3-import-choose").await;
    for part in Parts::EACH {
        set_check(&i, &format!("setup-part-{}", part.0), part == Parts::CONTACTS);
    }
    pause(100).await;
    click(&i, "dialog-ok");
    match wait_dialog(60, "setup-summary-dialog").await {
        Some(summary) => {
            let s = summary.clone().upcast::<gtk::Widget>();
            let rows = rows_of(&s);
            d.check(
                rows.iter().any(|r| r.contains("Added 1 contact")) && rows.iter().any(|r| r.contains("already")),
                &format!("the summary says what was added and skipped ({rows:?})"),
            );
            d.shot(&summary, "setup-4-imported").await;
            click(&s, "setup-done");
            wait_gone(10, "setup-summary-dialog").await;
        }
        None => d.check(false, "the summary says what was added and skipped"),
    }
    let accounts_after: Vec<i64> = core.accounts().unwrap_or_default().iter().map(|a| a.id).collect();
    d.check(
        is_back() && accounts_after == accounts_before,
        "a contact deleted before importing Contacts alone comes back; the accounts are left as they are",
    );
}
