//! Settings sync (SCENARIO 38): the Sync page while off, Set Up Sync through a folder with a new passphrase, the page
//! while on, a second computer (another core in this process, as a computer that shares the folder) joining with
//! the passphrase and getting the account, a contact it adds reaching this one on Sync Now, the Computers and History
//! pages, and Turn Off Sync

use std::path::{Path, PathBuf};
use std::sync::Arc;
use std::sync::atomic::{AtomicBool, Ordering};

use pe_core::sync::items::Choice;
use pe_core::sync::run::PlaceSetup;

use super::*;
use crate::words::{Text, plain};

const PASSPHRASE: &str = "correct horse battery staple";

/// Another computer that syncs through the same folder: a core of its own, its passwords in memory
struct Second {
    core: pe_core::Core,
    ready: Arc<AtomicBool>,
    _dir: PathBuf,
}

impl Second {
    fn open() -> Option<Second> {
        let dir = std::env::temp_dir().join(format!("inbox-classic-second-{}", std::process::id()));
        let _ = std::fs::remove_dir_all(&dir);
        std::fs::create_dir_all(&dir).ok()?;
        let ready = Arc::new(AtomicBool::new(false));
        let heard = ready.clone();
        let options = pe_core::Options {
            passwords: pe_core::PasswordStore::Memory,
            ..Default::default()
        };
        let core = pe_core::Core::open_with(dir.join("store.db"), options, move |event| {
            if event == pe_core::Event::SettingsSyncReady {
                heard.store(true, Ordering::SeqCst);
            }
        })
        .ok()?;
        Some(Second { core, ready, _dir: dir })
    }

    /// One whole sync, as the window would answer it
    async fn sync(&self) -> bool {
        self.ready.store(false, Ordering::SeqCst);
        let last = self.core.settings_sync_state().last;
        self.core.settings_sync_now();
        if !wait_until(30, || self.ready.load(Ordering::SeqCst)).await {
            return false;
        }
        let _ = self.core.settings_sync_continue(&[]);
        wait_until(30, || self.core.settings_sync_state().last > last).await
    }
}

fn vault_dir() -> PathBuf {
    std::env::temp_dir().join(format!("inbox-classic-vault-{}", std::process::id()))
}

/// The computers' folders in the vault
fn devices(vault: &Path) -> usize {
    std::fs::read_dir(vault.join("devices")).map_or(0, |dir| dir.count())
}

fn activate(root: &gtk::Widget, setting: Setting) -> bool {
    match setting_row(root, setting) {
        Some(row) => {
            row.emit_by_name::<()>("activated", &[]);
            true
        }
        None => false,
    }
}

fn shown(root: &gtk::Widget, setting: Setting) -> bool {
    setting_row(root, setting).is_some_and(|row| row.is_visible())
}

pub async fn settings_sync(d: &Driver) {
    d.step("settings sync");
    let vault = vault_dir();
    let _ = std::fs::remove_dir_all(&vault);
    let _ = std::fs::create_dir_all(&vault);
    command(Command::Options);
    let Some(dialog) = wait_dialog(10, "preferences-dialog").await else {
        d.check(false, "Preferences opens");
        return;
    };
    preferences_page(&dialog, SettingsPage::Sync);
    pause(300).await;
    let root: gtk::Widget = dialog.clone().upcast();
    d.check(
        shown(&root, Setting::SyncSetUp) && !shown(&root, Setting::SyncNow) && !shown(&root, Setting::SyncAccounts),
        "while sync is off, the Sync page says what it is for and offers Set Up Sync, nothing else",
    );
    d.shot(&dialog, "sync-1-off").await;

    // Set Up Sync: a folder, then a new passphrase
    crate::ui::FILE_ANSWERS.with(|answers| answers.borrow_mut().push_back(vec![vault.clone()]));
    activate(&root, Setting::SyncSetUp);
    let Some(setup) = wait_dialog(10, "sync-dialog").await else {
        d.check(false, "Set Up Sync opens");
        return;
    };
    let setup_root: gtk::Widget = setup.clone().upcast();
    d.check(
        named_in(&setup_root, "sync-next").is_some_and(|next| !next.is_sensitive()),
        "it asks where to keep it, Next off until a folder is chosen",
    );
    d.shot(&setup, "sync-2-where").await;
    click(&setup_root, "sync-choose-folder");
    let chosen = wait_until(10, || {
        named_in(&setup_root, "sync-next").is_some_and(|next| next.is_sensitive())
    })
    .await;
    d.check(chosen, "a folder chosen, Next is on");
    click(&setup_root, "sync-next");
    let asked = wait_until(15, || named_in(&setup_root, "sync-passphrase-again").is_some()).await;
    d.check(asked, "the folder is empty: it asks for a new sync passphrase, twice");
    pause(300).await;
    d.shot(&setup, "sync-3-start").await;
    set_text(&setup_root, "sync-passphrase", PASSPHRASE);
    set_text(&setup_root, "sync-passphrase-again", PASSPHRASE);
    set_text(&setup_root, "sync-name", "Desktop");
    click(&setup_root, "sync-turn-on");
    d.check(wait_gone(10, "sync-dialog").await, "Turn On Sync closes the dialog");
    let synced = wait_until(30, || shell().core.settings_sync_state().last > 0).await;
    d.check(
        synced && vault.join("vault.json").exists() && devices(&vault) == 1,
        "the first sync writes the vault into the folder",
    );
    pause(300).await;
    d.check(
        shown(&root, Setting::SyncNow) && shown(&root, Setting::SyncAccounts) && !shown(&root, Setting::SyncSetUp),
        "while on, the page shows where it syncs, how it went, its buttons and what it syncs",
    );
    d.shot(&dialog, "sync-4-on").await;

    // a second computer joins with the passphrase and gets the account
    let Some(second) = Second::open() else {
        d.check(false, "a second computer opens");
        return;
    };
    let place = PlaceSetup::Folder {
        path: vault.to_string_lossy().into_owned(),
    };
    let joined = second
        .core
        .settings_sync_turn_on(place.clone(), None, "not it", "Laptop", Choice::default());
    d.check(joined.is_err(), "a wrong passphrase does not join");
    let joined = second
        .core
        .settings_sync_turn_on(place, None, PASSPHRASE, "Laptop", Choice::default())
        .is_ok()
        && second.sync().await;
    let accounts = second.core.accounts().unwrap_or_default();
    d.check(
        joined
            && accounts
                .iter()
                .any(|a| a.settings.email == "testuser@inboxclassic.test"),
        &format!(
            "the second computer joins and gets the account ({} accounts)",
            accounts.len()
        ),
    );
    // a contact it adds reaches this one on Sync Now
    let card = pe_store::Card {
        name: "Sync Friend".into(),
        addresses: vec!["friend@sync.example".into()],
        ..Default::default()
    };
    let added = second.core.save_card(&card).is_ok() && second.sync().await;
    activate(&root, Setting::SyncNow);
    let arrived = wait_until(30, || {
        shell()
            .core
            .cards("friend@sync.example")
            .is_ok_and(|cards| !cards.is_empty())
    })
    .await;
    d.check(
        added && arrived,
        "a contact added on the second computer arrives on Sync Now",
    );

    // the computers of the vault
    activate(&root, Setting::SyncComputers);
    let listed = wait_until(15, || descendants_named(&root, "sync-computer") == 2).await;
    d.check(listed, "Computers lists both, this one first marked as this computer");
    pause(300).await;
    d.shot(&dialog, "sync-5-computers").await;
    if let Some(preferences) = dialog.downcast_ref::<adw::PreferencesDialog>() {
        preferences.pop_subpage();
    }
    pause(300).await;
    activate(&root, Setting::SyncHistory);
    let empty = wait_until(10, || named_in(&root, "sync-history-empty").is_some()).await;
    d.check(empty, "History says no change was replaced");
    d.shot(&dialog, "sync-6-history").await;
    if let Some(preferences) = dialog.downcast_ref::<adw::PreferencesDialog>() {
        preferences.pop_subpage();
    }
    pause(300).await;

    // Turn Off Sync, asked first
    activate(&root, Setting::SyncTurnOff);
    if let Some(asked) = wait_for(10, alert).await {
        answer(&asked, &plain(Text::UiSyncTurnOffButton));
    }
    let off = wait_until(10, || !shell().core.settings_sync_state().on).await;
    d.check(
        off && shown(&root, Setting::SyncSetUp),
        "Turn Off Sync turns it off here, the page offers Set Up Sync again",
    );
    drop(second);
    dialog.close();
    wait_gone(10, "preferences-dialog").await;
    let _ = std::fs::remove_dir_all(&vault);
}

/// How many mapped widgets under `root` are named `name`
fn descendants_named(root: &gtk::Widget, name: &str) -> usize {
    descendants::<gtk::Widget>(root)
        .into_iter()
        .filter(|w| w.widget_name() == name && w.is_mapped())
        .count()
}
