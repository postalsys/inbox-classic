//! Export and Import Settings and Accounts (the main menu's File): one file to take what was set up here to another
//! computer. The core writes and reads the file (`pe_core::setup`), checks everything in it, names the parts and says
//! in words what each holds, what each account would do and what an import did; it tells the windows what an import
//! changed by its events (`app.rs`). These windows choose the parts, hand in the app's own preferences by their shared
//! names (settings.ini keeps them) and apply the ones that come back.

use std::path::Path;
use std::rc::Rc;

use adw::prelude::*;
use gtk::gio;
use pe_core::setup::{ImportChoice, ImportLineKind, Parts, SetupError, SetupFile};

use crate::app::{shell, spawn};
use crate::settings;
use crate::ui::{self, Attempt};
use crate::words::{Text, plain};

/// The width of the windows: their titles whole between the header's buttons in German too
const WIDTH: i32 = 640;

/// The names of the windows, by which F1 finds their help (`help.rs`)
pub const DIALOGS: [&str; 4] = [
    "setup-export-dialog",
    "setup-import-dialog",
    "setup-passphrase-dialog",
    "setup-summary-dialog",
];

/// The file type of the save and open dialogs: its name and pattern
fn file_type() -> (String, [String; 1]) {
    (
        plain(Text::UiSetupFileFilter),
        [format!("*.{}", pe_core::setup::EXTENSION)],
    )
}

fn window(parent: &impl IsA<gtk::Widget>) -> gtk::Window {
    ui::window_of(parent).unwrap_or_else(|| shell().main().window().clone().upcast())
}

fn content_box() -> gtk::Box {
    let content = gtk::Box::new(gtk::Orientation::Vertical, 12);
    content.set_margin_start(18);
    content.set_margin_end(18);
    content.set_margin_top(12);
    content.set_margin_bottom(18);
    content
}

/// The parts whose boxes are ticked
fn chosen(checks: &[(Parts, gtk::CheckButton)]) -> Parts {
    checks
        .iter()
        .filter(|(_, check)| check.is_active())
        .fold(Parts::NONE, |all, (part, _)| all.with(*part))
}

// ---- the app's preferences, by the names the three apps share ----

/// Each portable preference as settings.ini and the windows have it now, as the core takes it
fn preferences() -> Vec<(String, String)> {
    let shell = shell();
    let flag = |on: bool| if on { "1" } else { "0" }.to_string();
    pe_core::setup::PREFERENCES
        .iter()
        .filter_map(|(name, _)| {
            let value = match *name {
                "notify_new_mail" => flag(shell.notify.get()),
                "codes_in_notifications" => flag(pe_core::otp::in_notifications()),
                "group_by_conversation" => flag(crate::mailbox::grouped()),
                "hide_ignored" => flag(crate::mailbox::hide_ignored()),
                "hide_read" => flag(crate::mailbox::hide_read()),
                "folder_list" => flag(crate::mailbox::folder_list_shown()),
                "list_pictures" => flag(shell.settings.bool(settings::LIST_PICTURES, true)),
                "layout" => (shell.main().layout_mode() as u32).to_string(),
                "language" => shell.settings.text(settings::LANGUAGE).unwrap_or_default(),
                _ => return None,
            };
            Some((name.to_string(), value))
        })
        .collect()
}

/// The preferences of a file, checked by the core, kept and applied as Preferences and the View menu apply them; true
/// when one of them counts only from the next start and changed (the language)
fn apply_preferences(prefs: &[(String, String)]) -> bool {
    use pe_core::layout::LayoutMode;
    let shell = shell();
    let main = shell.main();
    let mut restart = false;
    for (name, value) in prefs {
        let on = value == "1";
        match name.as_str() {
            "notify_new_mail" if shell.notify.get() != on => shell.set_notify(on),
            "codes_in_notifications" => {
                shell.settings.set_bool(settings::CODES_IN_NOTIFICATIONS, on);
                pe_core::otp::set_in_notifications(on);
            }
            "group_by_conversation" if crate::mailbox::grouped() != on => {
                shell.settings.set_bool(settings::GROUP_BY_CONVERSATION, on);
                main.regroup();
            }
            "hide_ignored" if crate::mailbox::hide_ignored() != on => main.set_hide_ignored(on),
            "hide_read" if crate::mailbox::hide_read() != on => main.set_hide_read(on),
            "folder_list" if crate::mailbox::folder_list_shown() != on => main.set_folder_list(on),
            "list_pictures" if shell.settings.bool(settings::LIST_PICTURES, true) != on => main.set_list_pictures(on),
            "layout" => {
                let mode = match value.as_str() {
                    "1" => LayoutMode::Classic,
                    "2" => LayoutMode::Columns,
                    _ => LayoutMode::Automatic,
                };
                if mode != main.layout_mode() {
                    main.set_layout_mode(mode);
                }
            }
            "language" => {
                let chosen = (!value.is_empty()).then_some(value.as_str());
                shell.settings.set_text(settings::LANGUAGE, chosen);
                let words = chosen
                    .and_then(pe_core::i18n::supported)
                    .unwrap_or_else(crate::words::system_language);
                restart |= pe_core::setup::pref_restarts(name) && words != pe_core::i18n::language();
            }
            _ => {}
        }
    }
    restart
}

// ---- the summary ----

/// A window of what was done, a row each, and Done
async fn summary(parent: &impl IsA<gtk::Widget>, title: &str, heading: &str, rows: Vec<(&str, String, String)>) {
    let group = adw::PreferencesGroup::new();
    if !heading.is_empty() {
        group.set_title(&gtk::glib::markup_escape_text(heading));
    }
    group.set_widget_name("setup-summary");
    for (icon, title, subtitle) in rows {
        let row = adw::ActionRow::builder().title(title).use_markup(false).build();
        if !subtitle.is_empty() {
            row.set_subtitle(&subtitle);
        }
        let image = gtk::Image::from_icon_name(icon);
        image.set_valign(gtk::Align::Center);
        row.add_prefix(&image);
        group.add(&row);
    }
    let content = content_box();
    content.append(&group);
    let scrolled = gtk::ScrolledWindow::builder()
        .child(&content)
        .hscrollbar_policy(gtk::PolicyType::Never)
        .propagate_natural_height(true)
        .max_content_height(520)
        .build();
    let header = adw::HeaderBar::new();
    header.set_show_end_title_buttons(false);
    header.set_show_start_title_buttons(false);
    let done = gtk::Button::with_label(&plain(Text::UiSetupDone));
    done.set_widget_name("setup-done");
    done.add_css_class("suggested-action");
    header.pack_end(&done);
    let view = adw::ToolbarView::new();
    view.add_top_bar(&header);
    view.set_content(Some(&scrolled));
    let dialog = adw::Dialog::builder()
        .title(title)
        .content_width(520)
        .child(&view)
        .default_widget(&done)
        .build();
    dialog.set_widget_name("setup-summary-dialog");
    let clicks = ui::answers(&dialog, &done);
    dialog.present(Some(parent.as_ref()));
    done.grab_focus();
    let _ = clicks.recv().await;
    dialog.close();
}

// ---- Export ----

/// File > Export Settings and Accounts: the parts, a passphrase or none, then the file to write
pub async fn export(parent: &impl IsA<gtk::Widget>) {
    let title = plain(Text::UiSetupExportTitle);
    let content = content_box();
    let intro = ui::wrapped_label(&plain(Text::UiSetupExportIntro));
    intro.set_widget_name("setup-export-intro");
    content.append(&intro);
    // the parts in two columns, in the order the core lists them: down the first, then the second
    let grid = gtk::Grid::builder()
        .column_homogeneous(true)
        .row_spacing(4)
        .column_spacing(12)
        .build();
    grid.set_widget_name("setup-parts");
    let mut checks = Vec::new();
    let half = Parts::EACH.len().div_ceil(2);
    for (at, part) in Parts::EACH.into_iter().enumerate() {
        // its words wrapped where the window is narrow, not cut off
        let words = gtk::Label::builder().label(part.name()).wrap(true).xalign(0.0).build();
        let check = gtk::CheckButton::builder().child(&words).active(true).build();
        check.set_widget_name(&format!("setup-part-{}", part.0));
        grid.attach(&check, (at / half) as i32, (at % half) as i32, 1, 1);
        checks.push((part, check));
    }
    content.append(&grid);
    content.append(&gtk::Separator::new(gtk::Orientation::Horizontal));

    let protect_words = gtk::Label::builder()
        .label(pe_core::i18n::gtk_mnemonic(&t!(UiSetupUsePassphrase)))
        .use_underline(true)
        .wrap(true)
        .xalign(0.0)
        .build();
    let protect = gtk::CheckButton::builder().child(&protect_words).build();
    protect_words.set_mnemonic_widget(Some(&protect));
    protect.set_widget_name("setup-use-passphrase");
    let note = ui::wrapped_label(&plain(Text::UiSetupPassphraseNote));
    note.add_css_class("dim-label");
    note.set_widget_name("setup-passphrase-note");
    // under the check box's words
    note.set_margin_start(28);
    let protecting = gtk::Box::new(gtk::Orientation::Vertical, 2);
    protecting.append(&protect);
    protecting.append(&note);
    content.append(&protecting);
    let pair = Rc::new(ui::PassphrasePair::new("setup-passphrase"));
    let secret = gtk::Box::new(gtk::Orientation::Vertical, 12);
    secret.append(&pair.group);
    secret.append(&pair.feedback);
    secret.set_visible(false);
    content.append(&secret);

    // no scrolling: the window grows to show the passphrase fields when they come
    let (dialog, ok) = ui::dialog_with_buttons(&title, &content, &plain(Text::UiSetupExportButton), WIDTH);
    dialog.set_widget_name("setup-export-dialog");

    // what is chosen and typed decides whether Export is on
    let checks = Rc::new(checks);
    let update: Rc<dyn Fn()> = {
        let (checks, protect, secret, pair, ok) = (
            checks.clone(),
            protect.clone(),
            secret.clone(),
            pair.clone(),
            ok.clone(),
        );
        Rc::new(move || {
            let on = protect.is_active();
            secret.set_visible(on);
            let acceptable = !on || pair.check();
            ok.set_sensitive(!chosen(&checks).is_empty() && acceptable);
        })
    };
    for (_, check) in checks.iter() {
        let update = update.clone();
        check.connect_active_notify(move |_| update());
    }
    {
        let (update, pair) = (update.clone(), pair.clone());
        protect.connect_active_notify(move |check| {
            update();
            if check.is_active() {
                pair.first.grab_focus();
            }
        });
    }
    {
        let update = update.clone();
        pair.connect_changed(move || update());
    }
    update();

    let clicks = ui::answers(&dialog, &ok);
    dialog.present(Some(parent.as_ref()));
    ok.grab_focus();
    let (filter, patterns) = file_type();
    let patterns: Vec<&str> = patterns.iter().map(String::as_str).collect();
    while let Ok(true) = clicks.recv().await {
        if !ok.is_sensitive() {
            continue;
        }
        let name = pe_core::setup::default_name();
        let Some(path) = ui::save_file(&window(&dialog), &title, &name, Some((&filter, &patterns))).await else {
            continue;
        };
        let parts = chosen(&checks);
        let passphrase = protect.is_active().then(|| pair.take());
        let prefs = preferences();
        let written = {
            let path = path.clone();
            ui::off_thread(&dialog, &ok, move |core| {
                let done = core.export_setup(&path, parts, passphrase.as_deref(), &prefs);
                if let Some(passphrase) = passphrase {
                    ui::wipe(passphrase);
                }
                done.map_err(|e| e.to_string())
            })
            .await
        };
        match written {
            Some(Ok(lines)) => {
                dialog.close();
                let heading = pe_core::setup::with_extension(&path)
                    .file_name()
                    .map(|n| n.to_string_lossy().into_owned())
                    .unwrap_or_default();
                let rows = lines
                    .into_iter()
                    .map(|(part, words)| ("object-select-symbolic", part.name(), words))
                    .collect();
                summary(parent, &title, &heading, rows).await;
                return;
            }
            Some(Err(why)) => ui::alert(&dialog, &title, &why).await,
            None => {}
        }
    }
    pair.clear();
    dialog.close();
}

// ---- Import ----

/// File > Import Settings and Accounts: the file, its passphrase when it has one, what to take of it, then what was
/// done. The accounts added (they sync by themselves), none when nothing was imported or it was cancelled
pub async fn import(parent: &impl IsA<gtk::Widget>) -> Vec<i64> {
    let title = plain(Text::UiSetupImportTitle);
    let (filter, patterns) = file_type();
    let patterns: Vec<&str> = patterns.iter().map(String::as_str).collect();
    let Some(path) = ui::open_file(&window(parent), &title, Some((&filter, &patterns))).await else {
        return Vec::new();
    };
    let read = {
        let path = path.clone();
        let core = shell().core.clone();
        gio::spawn_blocking(move || core.read_setup(&path, None)).await
    };
    let setup = match read {
        Ok(Ok(setup)) => setup,
        Ok(Err(SetupError::NeedsPassphrase | SetupError::WrongPassphrase)) => {
            match ask_passphrase(parent, &path).await {
                Some(Ok(setup)) => setup,
                Some(Err(why)) => {
                    ui::alert(parent, &title, &why.text()).await;
                    return Vec::new();
                }
                None => return Vec::new(),
            }
        }
        Ok(Err(why)) => {
            ui::alert(parent, &title, &why.text()).await;
            return Vec::new();
        }
        Err(_) => return Vec::new(),
    };
    choose_and_import(parent, setup).await
}

/// The passphrase of a sealed file asked for until it opens it or Cancel; a file that can not be read at all is not
/// asked about again
async fn ask_passphrase(parent: &impl IsA<gtk::Widget>, path: &Path) -> Option<Result<SetupFile, SetupError>> {
    let path = path.to_path_buf();
    ui::ask_passphrase(
        parent,
        &plain(Text::UiSetupImportTitle),
        &plain(Text::UiSetupAskPassphrase),
        "setup-passphrase",
        move |core, typed| {
            let read = core.read_setup(&path, Some(&typed));
            ui::wipe(typed);
            match read {
                Err(why @ (SetupError::NeedsPassphrase | SetupError::WrongPassphrase)) => Attempt::Again(why.text()),
                done => Attempt::Done(done),
            }
        },
    )
    .await
}

/// The import window: what the file holds, each part and account to choose; Import imports them and says what it did
async fn choose_and_import(parent: &impl IsA<gtk::Widget>, setup: SetupFile) -> Vec<i64> {
    let title = plain(Text::UiSetupImportTitle);
    let content = content_box();
    let intro = ui::wrapped_label(&plain(Text::UiSetupImportIntro));
    intro.set_widget_name("setup-import-intro");
    content.append(&intro);
    let from = ui::wrapped_label(&t!(
        UiSetupFrom,
        version = &*setup.app_version,
        date = &*setup.created_text
    ));
    from.add_css_class("dim-label");
    from.set_widget_name("setup-from");
    content.append(&from);

    let group = adw::PreferencesGroup::new();
    group.set_widget_name("setup-parts");
    let mut parts = Vec::new();
    let mut accounts_part = None;
    let mut accounts: Vec<(usize, gtk::CheckButton)> = Vec::new();
    for (part, words) in setup.part_lines() {
        let (row, check) = ui::check_row(&part.name(), Some(&words), &format!("setup-part-{}", part.0), true);
        group.add(&row);
        if part != Parts::ACCOUNTS {
            parts.push((part, check));
            continue;
        }
        for account in &setup.accounts {
            let subtitle = format!("{}\n{}", account.servers, account.note);
            let name = format!("setup-account-{}", account.index);
            let (account_row, account_check) =
                ui::check_row(&account.label, Some(&subtitle), &name, account.importable);
            account_row.set_widget_name(&format!("setup-account-row-{}", account.index));
            // under Accounts, set in as its parts
            let indent = gtk::Box::new(gtk::Orientation::Horizontal, 0);
            indent.set_size_request(18, -1);
            account_row.add_prefix(&indent);
            account_row.set_sensitive(account.importable);
            group.add(&account_row);
            if account.importable {
                accounts.push((account.index, account_check));
            }
        }
        accounts_part = Some((row, check));
    }
    content.append(&group);
    for note in &setup.notes {
        let label = ui::wrapped_label(note);
        label.add_css_class("dim-label");
        label.set_widget_name("setup-note");
        content.append(&label);
    }
    let scrolled = gtk::ScrolledWindow::builder()
        .child(&content)
        .hscrollbar_policy(gtk::PolicyType::Never)
        .propagate_natural_height(true)
        .max_content_height(560)
        .build();
    let (dialog, ok) = ui::dialog_with_buttons(&title, &scrolled, &plain(Text::UiSetupImportButton), WIDTH);
    dialog.set_widget_name("setup-import-dialog");

    let parts = Rc::new(parts);
    let accounts = Rc::new(accounts);
    let update: Rc<dyn Fn()> = {
        let (parts, accounts, ok) = (parts.clone(), accounts.clone(), ok.clone());
        Rc::new(move || {
            let any_account = accounts.iter().any(|(_, check)| check.is_active());
            ok.set_sensitive(any_account || !chosen(&parts).is_empty());
        })
    };
    for check in parts.iter().map(|(_, c)| c).chain(accounts.iter().map(|(_, c)| c)) {
        let update = update.clone();
        check.connect_active_notify(move |_| update());
    }
    if let Some((row, part)) = &accounts_part {
        select_all(row, part, &accounts);
    }
    update();

    let clicks = ui::answers(&dialog, &ok);
    dialog.present(Some(parent.as_ref()));
    ok.grab_focus();
    let setup = std::sync::Arc::new(setup);
    while let Ok(true) = clicks.recv().await {
        if !ok.is_sensitive() {
            continue;
        }
        // the core takes the accounts part from the accounts named
        let choice = ImportChoice {
            parts: chosen(&parts),
            accounts: accounts
                .iter()
                .filter(|(_, check)| check.is_active())
                .map(|(index, _)| *index)
                .collect(),
        };
        let file = setup.clone();
        let wanted = choice.clone();
        // it may reach the network (the sign-in apps' issuers)
        let done = ui::off_thread(&dialog, &ok, move |core| {
            core.import_setup(&file, &wanted).map_err(|e| e.to_string())
        })
        .await;
        let imported = match done {
            Some(Ok(imported)) => imported,
            Some(Err(why)) => {
                ui::alert(&dialog, &title, &why).await;
                continue;
            }
            None => continue,
        };
        dialog.close();
        // the core's events refresh what it changed; the app's own preferences are the app's to apply
        let restart = choice.parts.has(Parts::PREFERENCES) && apply_preferences(&setup.prefs);
        let rows = imported
            .lines
            .into_iter()
            .map(|line| {
                let icon = match line.kind {
                    ImportLineKind::Added => "object-select-symbolic",
                    ImportLineKind::Skipped => "action-unavailable-symbolic",
                    ImportLineKind::Note => "dialog-information-symbolic",
                };
                (icon, line.text, String::new())
            })
            .collect();
        summary(parent, &title, "", rows).await;
        if restart {
            crate::preferences::ask_restart(parent).await;
        }
        return imported.accounts;
    }
    dialog.close();
    Vec::new()
}

/// The Accounts box as "select all" of the accounts that can be imported: ticking it ticks them, unticking it unticks
/// them, and it is ticked while one of them is; with none to import it is unticked and greyed
fn select_all(row: &adw::ActionRow, part: &gtk::CheckButton, accounts: &Rc<Vec<(usize, gtk::CheckButton)>>) {
    let any = !accounts.is_empty();
    part.set_active(any);
    row.set_sensitive(any);
    let syncing = Rc::new(std::cell::Cell::new(false));
    {
        let (accounts, syncing) = (accounts.clone(), syncing.clone());
        part.connect_active_notify(move |part| {
            if syncing.replace(true) {
                return;
            }
            for (_, check) in accounts.iter() {
                check.set_active(part.is_active());
            }
            syncing.set(false);
        });
    }
    for (_, check) in accounts.iter() {
        let (accounts, syncing, part) = (accounts.clone(), syncing.clone(), part.clone());
        check.connect_active_notify(move |_| {
            if syncing.replace(true) {
                return;
            }
            part.set_active(accounts.iter().any(|(_, c)| c.is_active()));
            syncing.set(false);
        });
    }
}

/// Command::ExportSetup
pub fn run_export() {
    let window = shell().main().window().clone();
    spawn(async move { export(&window).await });
}

/// Command::ImportSetup
pub fn run_import() {
    let window = shell().main().window().clone();
    spawn(async move {
        import(&window).await;
    });
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn every_window_has_its_help() {
        assert!(DIALOGS.iter().all(|name| name.starts_with("setup-")));
        assert_eq!(file_type().1, ["*.inboxclassic".to_string()]);
    }
}
