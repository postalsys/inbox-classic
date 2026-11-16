//! Export and Import Settings and Accounts (the main menu's File): one file to take what was set up here to another
//! computer. The core writes and reads the file (`pe_core::setup`), checks everything in it and says in words what
//! each part holds and what an import did; these windows choose the parts, hand in the app's own preferences by their
//! shared names (settings.ini keeps them) and apply the ones that come back.

use std::path::{Path, PathBuf};
use std::rc::Rc;

use adw::prelude::*;
use gtk::gio;
use pe_core::setup::{ImportChoice, ImportLineKind, Parts, SetupError, SetupFile};

use crate::app::{shell, spawn};
use crate::settings;
use crate::ui;
use crate::words::{Text, field_title, plain};

/// The file name offered by Export
const FILE_NAME: &str = "Inbox Classic.inboxclassic";

/// The pattern of the file type, before All files
const PATTERNS: [&str; 1] = ["*.inboxclassic"];

/// The width of the windows: their titles whole between the header's buttons in German too
const WIDTH: i32 = 640;

/// The names of the windows, by which F1 finds their help (`help.rs`)
pub const DIALOGS: [&str; 4] = [
    "setup-export-dialog",
    "setup-import-dialog",
    "setup-passphrase-dialog",
    "setup-summary-dialog",
];

/// A part's name as the windows list it
fn part_name(part: Parts) -> String {
    plain(match part {
        Parts::SETTINGS => Text::UiSetupPartSettings,
        Parts::PREFERENCES => Text::UiSetupPartPreferences,
        Parts::ACCOUNTS => Text::UiSetupPartAccounts,
        Parts::SIGN_IN_APPS => Text::UiSetupPartSignInApps,
        Parts::CONTACTS => Text::UiSetupPartContacts,
        Parts::KEYS => Text::UiSetupPartKeys,
        Parts::RULES => Text::UiSetupPartRules,
        _ => Text::UiSetupPartTrusted,
    })
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

/// A row with a check box before its title (the row clicks it), named `name`
fn check_row(title: &str, subtitle: &str, name: &str, active: bool) -> (adw::ActionRow, gtk::CheckButton) {
    let check = gtk::CheckButton::builder()
        .active(active)
        .valign(gtk::Align::Center)
        .build();
    check.set_widget_name(name);
    check.update_property(&[gtk::accessible::Property::Label(title)]);
    let row = adw::ActionRow::builder()
        .title(gtk::glib::markup_escape_text(title))
        .activatable_widget(&check)
        .build();
    if !subtitle.is_empty() {
        row.set_subtitle(&gtk::glib::markup_escape_text(subtitle));
    }
    row.add_prefix(&check);
    (row, check)
}

/// The text of a passphrase field, the field emptied
fn take(row: &adw::PasswordEntryRow) -> String {
    let text = row.text().to_string();
    row.set_text("");
    text
}

/// Runs `work` with the core on a thread of its own (the passphrase's key derivation takes a while), meanwhile the
/// window taking no clicks and its OK button off (the focus stays where it is)
async fn off_thread<T: Send + 'static>(
    dialog: &adw::Dialog,
    ok: &gtk::Button,
    work: impl FnOnce(&pe_core::Core) -> T + Send + 'static,
) -> Option<T> {
    let core = shell().core.clone();
    let was = ok.is_sensitive();
    dialog.set_can_target(false);
    ok.set_sensitive(false);
    let done = gio::spawn_blocking(move || work(&core)).await.ok();
    dialog.set_can_target(true);
    ok.set_sensitive(was);
    done
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

/// The preferences of a file kept and applied, as Preferences and the View menu apply them; true when the language
/// changed, which takes a new start
fn apply_preferences(prefs: &[(String, String)]) -> bool {
    use pe_core::layout::LayoutMode;
    let shell = shell();
    let main = shell.main();
    let mut language = false;
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
                let chosen = pe_core::i18n::supported(value);
                shell.settings.set_text(settings::LANGUAGE, chosen);
                let words = chosen.unwrap_or_else(crate::words::system_language);
                language = words != pe_core::i18n::language();
            }
            _ => {}
        }
    }
    language
}

/// The core's settings an import replaced, shown: messages on a dark background or not, the text size
fn apply_settings() {
    let shell = shell();
    crate::preferences::set_dark_messages(shell.core.dark_messages());
    shell.main().text_size_changed();
}

// ---- the summary ----

/// A window of what was done, a row each, and Done
async fn summary(
    parent: &impl IsA<gtk::Widget>,
    title: &str,
    heading: &str,
    rows: Vec<(Option<&str>, String, String)>,
) {
    let group = adw::PreferencesGroup::new();
    if !heading.is_empty() {
        group.set_title(&gtk::glib::markup_escape_text(heading));
    }
    group.set_widget_name("setup-summary");
    for (icon, title, subtitle) in rows {
        let row = adw::ActionRow::builder()
            .title(gtk::glib::markup_escape_text(&title))
            .build();
        if !subtitle.is_empty() {
            row.set_subtitle(&gtk::glib::markup_escape_text(&subtitle));
        }
        if let Some(icon) = icon {
            let image = gtk::Image::from_icon_name(icon);
            image.set_valign(gtk::Align::Center);
            row.add_prefix(&image);
        }
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
        let words = gtk::Label::builder()
            .label(part_name(part))
            .wrap(true)
            .xalign(0.0)
            .build();
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
    let passphrase = adw::PasswordEntryRow::builder()
        .title(field_title(Text::UiKeysPassphrase))
        .activates_default(true)
        .build();
    passphrase.set_widget_name("setup-passphrase");
    let again = adw::PasswordEntryRow::builder()
        .title(field_title(Text::UiKeysPassphraseAgain))
        .activates_default(true)
        .build();
    again.set_widget_name("setup-passphrase-again");
    let secret_group = adw::PreferencesGroup::builder().visible(false).build();
    secret_group.add(&passphrase);
    secret_group.add(&again);
    content.append(&secret_group);
    let problem = ui::wrapped_label("");
    problem.add_css_class("error");
    problem.set_widget_name("setup-passphrase-problem");
    problem.set_visible(false);
    content.append(&problem);

    // no scrolling: the window grows to show the passphrase fields when they come
    let (dialog, ok) = ui::dialog_with_buttons(&title, &content, &plain(Text::UiSetupExportButton), WIDTH);
    dialog.set_widget_name("setup-export-dialog");

    // what is chosen and typed decides whether Export is on, and the words of a passphrase that will not do
    let checks = Rc::new(checks);
    let update: Rc<dyn Fn()> = {
        let (checks, protect, secret_group, passphrase, again, problem, ok) = (
            checks.clone(),
            protect.clone(),
            secret_group.clone(),
            passphrase.clone(),
            again.clone(),
            problem.clone(),
            ok.clone(),
        );
        Rc::new(move || {
            let any = checks.iter().any(|(_, check)| check.is_active());
            let on = protect.is_active();
            secret_group.set_visible(on);
            let why = on
                .then(|| pe_core::keys::passphrase_problem(&passphrase.text(), &again.text()))
                .flatten();
            // said once the second is typed into, not while the first is
            let shown = why.as_ref().filter(|_| !again.text().is_empty());
            problem.set_text(shown.map_or("", String::as_str));
            problem.set_visible(shown.is_some());
            ok.set_sensitive(any && why.is_none());
        })
    };
    for (_, check) in checks.iter() {
        let update = update.clone();
        check.connect_active_notify(move |_| update());
    }
    {
        let (update, passphrase) = (update.clone(), passphrase.clone());
        protect.connect_active_notify(move |check| {
            update();
            if check.is_active() {
                passphrase.grab_focus();
            }
        });
    }
    for field in [&passphrase, &again] {
        let update = update.clone();
        field.connect_changed(move |_| update());
    }
    update();

    let clicks = ui::answers(&dialog, &ok);
    dialog.present(Some(parent.as_ref()));
    ok.grab_focus();
    while let Ok(true) = clicks.recv().await {
        if !ok.is_sensitive() {
            continue;
        }
        let filter = plain(Text::UiSetupFileFilter);
        let Some(path) = ui::save_file(&window(&dialog), &title, FILE_NAME, Some((&filter, &PATTERNS))).await else {
            continue;
        };
        let path = with_extension(path);
        let parts = Parts(
            checks
                .iter()
                .filter(|(_, c)| c.is_active())
                .fold(0, |all, (part, _)| all | part.0),
        );
        let secret = protect.is_active().then(|| take(&passphrase));
        again.set_text("");
        let prefs = preferences();
        let written = {
            let path = path.clone();
            off_thread(&dialog, &ok, move |core| {
                let done = core.export_setup(&path, parts, secret.as_deref(), &prefs);
                if let Some(secret) = secret {
                    wipe(secret);
                }
                done.map_err(|e| e.to_string())
            })
            .await
        };
        match written {
            Some(Ok(lines)) => {
                dialog.close();
                let heading = path
                    .file_name()
                    .map(|n| n.to_string_lossy().into_owned())
                    .unwrap_or_default();
                let rows = lines
                    .into_iter()
                    .map(|(part, words)| (Some("object-select-symbolic"), part_name(part), words))
                    .collect();
                summary(parent, &title, &heading, rows).await;
                return;
            }
            Some(Err(why)) => ui::alert(&dialog, &title, &why).await,
            None => {}
        }
    }
    passphrase.set_text("");
    again.set_text("");
    dialog.close();
}

/// The path with the file type's extension when the name typed has none
fn with_extension(path: PathBuf) -> PathBuf {
    if path.extension().is_some() {
        return path;
    }
    let mut name = path.file_name().map(|n| n.to_os_string()).unwrap_or_default();
    name.push(format!(".{}", pe_core::setup::EXTENSION));
    path.with_file_name(name)
}

/// A passphrase's bytes overwritten before they are let go
fn wipe(passphrase: String) {
    let mut bytes = passphrase.into_bytes();
    bytes.fill(0);
    std::hint::black_box(&bytes);
}

// ---- Import ----

/// File > Import Settings and Accounts: the file, its passphrase when it has one, what to take of it, then what was
/// done. The accounts added (they sync by themselves), none when nothing was imported or it was cancelled
pub async fn import(parent: &impl IsA<gtk::Widget>) -> Vec<i64> {
    let title = plain(Text::UiSetupImportTitle);
    let filter = plain(Text::UiSetupFileFilter);
    let Some(path) = ui::open_file(&window(parent), &title, Some((&filter, &PATTERNS))).await else {
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
                Some(setup) => setup,
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

/// The passphrase of a sealed file asked for until it opens it or Cancel
async fn ask_passphrase(parent: &impl IsA<gtk::Widget>, path: &Path) -> Option<SetupFile> {
    let error = ui::wrapped_label("");
    error.add_css_class("error");
    error.set_widget_name("setup-passphrase-error");
    error.set_visible(false);
    let passphrase = adw::PasswordEntryRow::builder()
        .title(field_title(Text::UiKeysPassphrase))
        .activates_default(true)
        .build();
    passphrase.set_widget_name("setup-import-passphrase");
    let group = adw::PreferencesGroup::new();
    group.add(&passphrase);
    let content = content_box();
    content.append(&ui::wrapped_label(&plain(Text::UiSetupAskPassphrase)));
    content.append(&group);
    content.append(&error);
    let (dialog, ok) = ui::dialog_with_buttons(&plain(Text::UiSetupImportTitle), &content, &t!(UiOk), 480);
    dialog.set_widget_name("setup-passphrase-dialog");
    let clicks = ui::answers(&dialog, &ok);
    dialog.present(Some(parent.as_ref()));
    passphrase.grab_focus();
    let mut opened = None;
    while let Ok(true) = clicks.recv().await {
        let typed = take(&passphrase);
        if typed.is_empty() {
            passphrase.grab_focus();
            continue;
        }
        let path = path.to_path_buf();
        let tried = off_thread(&dialog, &ok, move |core| {
            let read = core.read_setup(&path, Some(&typed));
            wipe(typed);
            read
        })
        .await;
        match tried {
            Some(Ok(setup)) => {
                opened = Some(setup);
                break;
            }
            Some(Err(why)) => {
                error.set_text(&why.text());
                error.set_visible(true);
                passphrase.grab_focus();
                // a file that can not be read at all is not asked about again
                if matches!(why, SetupError::Invalid(_)) {
                    ui::alert(&dialog, &plain(Text::UiSetupImportTitle), &why.text()).await;
                    break;
                }
            }
            None => break,
        }
    }
    dialog.close();
    opened
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
    let mut accounts: Vec<(usize, gtk::CheckButton, adw::ActionRow)> = Vec::new();
    for (part, words) in setup.part_lines() {
        let (row, check) = check_row(&part_name(part), &words, &format!("setup-part-{}", part.0), true);
        group.add(&row);
        if part == Parts::ACCOUNTS {
            for account in &setup.accounts {
                let usable = !account.here && account.problem.is_none();
                let note = account.problem.as_deref().unwrap_or(&account.note);
                let subtitle = format!("{}, {}\n{note}", account.imap, account.smtp);
                let (row, check) = check_row(
                    &account.email,
                    &subtitle,
                    &format!("setup-account-{}", account.index),
                    usable,
                );
                row.set_widget_name(&format!("setup-account-row-{}", account.index));
                // under Accounts, set in as its parts
                let indent = gtk::Box::new(gtk::Orientation::Horizontal, 0);
                indent.set_size_request(18, -1);
                row.add_prefix(&indent);
                row.set_sensitive(usable);
                group.add(&row);
                accounts.push((account.index, check, row));
            }
        }
        parts.push((part, check));
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
    let accounts_part = parts
        .iter()
        .find(|(p, _)| *p == Parts::ACCOUNTS)
        .map(|(_, c)| c.clone());
    // the Accounts part follows its accounts: none to import turns it off for good, the last one unticked unticks
    // it and one ticked ticks it; ticking it ticks every account that can be imported, unticking it unticks them
    if let Some(part) = &accounts_part {
        let usable = accounts.iter().any(|(_, _, row)| row.is_sensitive());
        part.set_active(usable);
        // greyed with its words, as its accounts are
        match part.ancestor(adw::ActionRow::static_type()) {
            Some(row) => row.set_sensitive(usable),
            None => part.set_sensitive(usable),
        }
        let syncing = Rc::new(std::cell::Cell::new(false));
        {
            let (accounts, syncing) = (accounts.clone(), syncing.clone());
            part.connect_active_notify(move |part| {
                if syncing.replace(true) {
                    return;
                }
                for (_, check, _) in accounts.iter().filter(|(_, _, row)| row.is_sensitive()) {
                    check.set_active(part.is_active());
                }
                syncing.set(false);
            });
        }
        for (_, check, _) in accounts.iter() {
            let (accounts, syncing, part) = (accounts.clone(), syncing.clone(), part.clone());
            check.connect_active_notify(move |_| {
                if syncing.replace(true) {
                    return;
                }
                part.set_active(accounts.iter().any(|(_, c, row)| c.is_active() && row.is_sensitive()));
                syncing.set(false);
            });
        }
    }
    let update: Rc<dyn Fn()> = {
        let (parts, ok) = (parts.clone(), ok.clone());
        Rc::new(move || ok.set_sensitive(parts.iter().any(|(_, c)| c.is_active())))
    };
    for (_, check) in parts.iter() {
        let update = update.clone();
        check.connect_active_notify(move |_| update());
    }
    update();

    let clicks = ui::answers(&dialog, &ok);
    dialog.present(Some(parent.as_ref()));
    ok.grab_focus();
    let setup = std::sync::Arc::new(setup);
    let mut added = Vec::new();
    while let Ok(true) = clicks.recv().await {
        if !ok.is_sensitive() {
            continue;
        }
        let choice = ImportChoice {
            parts: Parts(
                parts
                    .iter()
                    .filter(|(_, c)| c.is_active())
                    .fold(0, |all, (p, _)| all | p.0),
            ),
            accounts: accounts
                .iter()
                .filter(|(_, c, row)| c.is_active() && row.is_sensitive())
                .map(|(index, _, _)| *index)
                .collect(),
        };
        let file = setup.clone();
        let wanted = choice.clone();
        let done = off_thread(&dialog, &ok, move |core| {
            core.import_setup(&file, &wanted).map_err(|e| e.to_string())
        })
        .await;
        let summary_lines = match done {
            Some(Ok(done)) => done,
            Some(Err(why)) => {
                ui::alert(&dialog, &title, &why).await;
                continue;
            }
            None => continue,
        };
        dialog.close();
        added = summary_lines.accounts.clone();
        let restart = imported(&setup, choice.parts, !added.is_empty());
        let rows = summary_lines
            .lines
            .into_iter()
            .map(|line| {
                let icon = match line.kind {
                    ImportLineKind::Added => "object-select-symbolic",
                    ImportLineKind::Skipped => "action-unavailable-symbolic",
                    ImportLineKind::Note => "dialog-information-symbolic",
                };
                (Some(icon), line.text, String::new())
            })
            .collect();
        summary(parent, &title, "", rows).await;
        if restart {
            crate::preferences::ask_restart(parent).await;
        }
        return added;
    }
    dialog.close();
    added
}

/// What an import changed shown in the windows: the preferences kept and applied, the settings, the accounts in the
/// folder list. True when the language changed
fn imported(setup: &SetupFile, parts: Parts, accounts: bool) -> bool {
    let shell = shell();
    let restart = parts.has(Parts::PREFERENCES) && apply_preferences(&setup.prefs);
    if parts.has(Parts::SETTINGS) {
        apply_settings();
    }
    if accounts {
        shell.main().reload();
    }
    restart
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
    fn a_name_without_a_type_gets_the_setup_files() {
        assert_eq!(
            with_extension(PathBuf::from("/tmp/Moving")),
            PathBuf::from("/tmp/Moving.inboxclassic")
        );
        assert_eq!(
            with_extension(PathBuf::from("/tmp/a.inboxclassic")),
            PathBuf::from("/tmp/a.inboxclassic")
        );
    }

    #[test]
    fn every_part_has_a_name_and_every_window_its_help() {
        for part in Parts::EACH {
            assert!(!part_name(part).is_empty());
        }
        assert!(DIALOGS.iter().all(|name| name.starts_with("setup-")));
    }
}
