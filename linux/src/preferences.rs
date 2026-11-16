//! Preferences (the main menu, Ctrl+,): a libadwaita preferences dialog as GNOME apps have it, with the pages, groups
//! and settings of core/settings.toml in their order (General, Reading, Downloading in the view switcher, each group
//! titled), one row for each setting built in `row_of`. Every change counts at once. A language chosen is saved in
//! settings.ini and used from the next start; the app offers to start again in it at once.

use std::ffi::OsStr;

use adw::prelude::*;
use gtk::{gio, glib};

use crate::app::{shell, spawn};
use crate::settings;
use crate::settings_pages::{Setting, SettingKind, SettingsGroup, SettingsPage};
use crate::ui::{self, TITLE};
use crate::words::{Text, field_title, plain, title};

/// The languages offered, in the order of the list: System default (None), then each by its own name
fn choices() -> Vec<Option<&'static str>> {
    std::iter::once(None)
        .chain(pe_core::i18n::LANGUAGES.iter().map(|(code, _)| Some(*code)))
        .collect()
}

/// The language a choice gives: its own, or the system's for System default
fn language_of(choice: Option<&str>) -> &'static str {
    choice
        .and_then(pe_core::i18n::supported)
        .unwrap_or_else(crate::words::system_language)
}

pub async fn open(parent: &impl IsA<gtk::Widget>) {
    let dialog = adw::PreferencesDialog::builder()
        .title(t!(GtkPreferences))
        .content_width(600)
        .build();
    dialog.set_widget_name("preferences-dialog");
    for page in SettingsPage::ALL {
        dialog.add(&page_of(*page));
    }
    dialog.present(Some(parent.as_ref()));
}

/// A page of the view switcher, its groups in the order of core/settings.toml
fn page_of(page: SettingsPage) -> adw::PreferencesPage {
    let shown = adw::PreferencesPage::builder()
        .name(page.name())
        .title(plain(page.text()))
        .icon_name(page.icon())
        .build();
    for group in page.groups() {
        shown.add(&group_of(*group));
    }
    shown
}

/// A group of a page: its title, what it is for (the notes of its choices, whose subtitle is the value chosen) and
/// its rows, a row that depends on a switch insensitive while the switch is off
fn group_of(group: SettingsGroup) -> adw::PreferencesGroup {
    let shown = adw::PreferencesGroup::new();
    if let Some(title) = group.title() {
        shown.set_title(&field_title(title));
    }
    let notes: Vec<String> = group
        .note()
        .into_iter()
        .chain(
            group
                .settings()
                .iter()
                .filter(|setting| setting.kind() == SettingKind::Choice)
                .filter_map(|setting| setting.note()),
        )
        .map(plain)
        .collect();
    if !notes.is_empty() {
        shown.set_description(Some(&notes.join("\n")));
    }
    let mut rows: Vec<(Setting, gtk::Widget)> = Vec::new();
    for &setting in group.settings() {
        let row = row_of(setting);
        if let Some((_, switch)) = rows.iter().find(|(built, _)| Some(*built) == setting.depends_on()) {
            switch.bind_property("active", &row, "sensitive").sync_create().build();
        }
        shown.add(&row);
        rows.push((setting, row));
    }
    shown
}

/// The row of `setting`: one arm for each setting of core/settings.toml, no default, so a new one fails the build
/// until it is shown
fn row_of(setting: Setting) -> gtk::Widget {
    match setting {
        Setting::Language => language_row(setting).upcast(),
        Setting::NotifyNewMail => {
            let row = switch_row(setting, "preferences-notify", shell().notify.get(), |on| {
                let shell = shell();
                if shell.notify.get() != on {
                    shell.set_notify(on);
                }
            });
            row.set_subtitle(&t!(GtkNotifySubtitle));
            row.upcast()
        }
        Setting::CodesInNotifications => {
            switch_row(setting, "preferences-codes", pe_core::otp::in_notifications(), |on| {
                shell().settings.set_bool(settings::CODES_IN_NOTIFICATIONS, on);
                pe_core::otp::set_in_notifications(on);
            })
            .upcast()
        }
        Setting::SendDelay => send_delay_row(setting).upcast(),
        Setting::DefaultMailApp => button_row(setting, "preferences-default-app", |dialog| {
            spawn(crate::app::make_default_mail_app(dialog.upcast()));
        })
        .upcast(),
        Setting::EmlDefault => button_row(setting, "preferences-eml-default", |dialog| {
            spawn(async move { make_eml_default(&dialog).await });
        })
        .upcast(),
        Setting::Layout => layout_row(setting).upcast(),
        Setting::GroupByConversation => {
            switch_row(setting, "preferences-group-threads", crate::mailbox::grouped(), |on| {
                let shell = shell();
                if crate::mailbox::grouped() != on {
                    shell.settings.set_bool(settings::GROUP_BY_CONVERSATION, on);
                    shell.main().regroup();
                }
            })
            .upcast()
        }
        Setting::ListPictures => {
            let on = shell().settings.bool(settings::LIST_PICTURES, true);
            switch_row(setting, "preferences-list-pictures", on, |on| {
                shell().main().set_list_pictures(on);
            })
            .upcast()
        }
        Setting::DarkMessages => switch_row(
            setting,
            "preferences-dark-messages",
            shell().core.dark_messages(),
            |on| {
                if shell().core.dark_messages() != on {
                    set_dark_messages(on);
                }
            },
        )
        .upcast(),
        Setting::PicturesAlways => {
            let on = shell().core.always_load_pictures().unwrap_or(false);
            switch_row(setting, "preferences-pictures-always", on, |on| {
                let _ = shell().core.set_always_load_pictures(on);
            })
            .upcast()
        }
        Setting::TrustedSenders => trusted_senders_row().upcast(),
        Setting::DownloadAhead => download_ahead_row(setting).upcast(),
        Setting::DownloadLimit => download_limit_row(setting).upcast(),
    }
}

/// A switch titled by `setting`, its note under it; `changed` is called with each new state
fn switch_row(setting: Setting, name: &str, active: bool, changed: impl Fn(bool) + 'static) -> adw::SwitchRow {
    let row = adw::SwitchRow::builder()
        .title(plain(setting.text()))
        .active(active)
        .build();
    if let Some(note) = setting.note() {
        row.set_subtitle(&plain(note));
    }
    row.set_widget_name(name);
    row.connect_active_notify(move |row| changed(row.is_active()));
    row
}

/// A button row titled by `setting` (without the dots of the menu command it repeats), `pressed` called with the
/// dialog it is in
fn button_row(setting: Setting, name: &str, pressed: impl Fn(adw::PreferencesDialog) + 'static) -> adw::ButtonRow {
    let row = adw::ButtonRow::builder().title(title(setting.text())).build();
    row.set_widget_name(name);
    row.connect_activated(move |row| {
        if let Some(dialog) = dialog_of(row) {
            pressed(dialog);
        }
    });
    row
}

/// The preferences dialog `row` is in
fn dialog_of(row: &impl IsA<gtk::Widget>) -> Option<adw::PreferencesDialog> {
    row.ancestor(adw::PreferencesDialog::static_type())
        .and_downcast::<adw::PreferencesDialog>()
}

/// Language: System default or a language by its own name, kept for the next start; the app offers to start again
/// in it at once
fn language_row(setting: Setting) -> adw::ComboRow {
    let offered = choices();
    let saved = shell().settings.text(settings::LANGUAGE);
    let saved = saved.as_deref().and_then(pe_core::i18n::supported);
    let names: Vec<String> = offered
        .iter()
        .map(|choice| match choice {
            None => t!(
                UiOptionsSystemDefault,
                language = crate::words::language_name(crate::words::system_language())
            ),
            Some(code) => crate::words::language_name(code).to_string(),
        })
        .collect();
    let at = offered.iter().position(|c| *c == saved).unwrap_or(0);
    let row = choice_row(setting, &names, "preferences-language", at, |_| {});
    row.connect_selected_notify(|row| {
        let Some(choice) = choices().get(row.selected() as usize).copied() else {
            return;
        };
        shell().settings.set_text(settings::LANGUAGE, choice);
        // the same words as now: nothing to start again for
        if language_of(choice) == pe_core::i18n::language() {
            return;
        }
        if let Some(dialog) = dialog_of(row) {
            spawn(async move { ask_restart(&dialog).await });
        }
    });
    row
}

/// Delay before sending: Off or a number of seconds
fn send_delay_row(setting: Setting) -> adw::ComboRow {
    let delays: Vec<String> = pe_core::SEND_DELAYS
        .iter()
        .map(|s| pe_core::send_delay_text(*s))
        .collect();
    choice_row(
        setting,
        &delays,
        "preferences-send-delay",
        pe_core::send_delay_index(shell().core.send_delay().unwrap_or(0)),
        |at| {
            if let Some(seconds) = pe_core::SEND_DELAYS.get(at) {
                let _ = shell().core.set_send_delay(*seconds);
            }
        },
    )
}

/// Trusted senders: the senders whose pictures are always downloaded, on a page of their own. Titled as that page
/// is, in sentence case as GNOME's rows are, not by the button of the other platforms ("Trusted Senders...")
fn trusted_senders_row() -> adw::ActionRow {
    let row = adw::ActionRow::builder()
        .title(plain(Text::UiTrustedSendersTitle))
        .activatable(true)
        .build();
    row.add_suffix(&gtk::Image::from_icon_name("go-next-symbolic"));
    row.set_widget_name("preferences-trusted-senders");
    row.connect_activated(|row| {
        if let Some(dialog) = dialog_of(row) {
            dialog.push_subpage(&trusted_senders_page());
        }
    });
    row
}

/// Messages on a dark background when the system is dark, or not: kept, and what is shown made again in that look
/// (the reading pane's message and those of the message windows; a compose window keeps its page until it closes)
pub fn set_dark_messages(on: bool) {
    let shell = shell();
    if shell.core.set_dark_messages(on).is_err() {
        return;
    }
    dark_messages_changed();
}

/// Messages on a dark background turned on or off (here or by an import): every message view shows it
pub fn dark_messages_changed() {
    crate::webview::update_backgrounds();
    shell().main().reader.reload();
    for window in crate::message_window::windows() {
        window.reader.reload();
    }
}

/// Layout: Automatic, Classic or Columns, as View > Layout chooses
fn layout_row(setting: Setting) -> adw::ComboRow {
    use crate::commands::Command;
    use pe_core::layout::LayoutMode;
    let modes = [LayoutMode::Automatic, LayoutMode::Classic, LayoutMode::Columns];
    let names: Vec<String> = [Command::LayoutAutomatic, Command::LayoutClassic, Command::LayoutColumns]
        .iter()
        .map(|command| command.label().to_string())
        .collect();
    let at = modes
        .iter()
        .position(|mode| *mode == shell().main().layout_mode())
        .unwrap_or(0);
    choice_row(setting, &names, "preferences-layout", at, move |chosen| {
        if let Some(&mode) = modes.get(chosen)
            && mode != shell().main().layout_mode()
        {
            shell().main().set_layout_mode(mode);
        }
    })
}

/// A row choosing one of `choices`, titled by `setting`, the one chosen under its title, where a long one has room in
/// every language, as in the list it opens; `chosen` is called with the place of a new choice
fn choice_row(
    setting: Setting,
    choices: &[String],
    name: &str,
    selected: usize,
    chosen: impl Fn(usize) + 'static,
) -> adw::ComboRow {
    let row = adw::ComboRow::builder()
        .title(field_title(setting.text()))
        .use_subtitle(true)
        .factory(&whole_names())
        .model(&gtk::StringList::new(
            &choices.iter().map(String::as_str).collect::<Vec<_>>(),
        ))
        .build();
    row.set_widget_name(name);
    row.set_selected(selected as u32);
    row.connect_selected_notify(move |row| chosen(row.selected() as usize));
    row
}

/// Download messages in advance: recent ones, all or none
fn download_ahead_row(setting: Setting) -> adw::ComboRow {
    // in the order of the words below
    let aheads = [pe_core::Ahead::Recent, pe_core::Ahead::All, pe_core::Ahead::Never];
    let names = [
        plain(Text::UiDownloadAheadRecent),
        plain(Text::UiDownloadAheadAll),
        plain(Text::UiDownloadAheadNever),
    ];
    let now = shell().core.download_ahead().unwrap_or_default();
    choice_row(
        setting,
        &names,
        "preferences-download-ahead",
        aheads.iter().position(|a| *a == now).unwrap_or(0),
        move |at| {
            if let Some(chosen) = aheads.get(at) {
                let _ = shell().core.set_download_ahead(*chosen);
            }
        },
    )
}

/// Storage limit per account
fn download_limit_row(setting: Setting) -> adw::ComboRow {
    let limits: Vec<String> = pe_core::DOWNLOAD_LIMITS_MB
        .iter()
        .map(|megabytes| pe_core::download_limit_text(*megabytes))
        .collect();
    let kept = shell().core.download_limit_mb().unwrap_or(pe_core::DEFAULT_LIMIT_MB);
    choice_row(
        setting,
        &limits,
        "preferences-download-limit",
        pe_core::download_limit_index(kept),
        |at| {
            if let Some(megabytes) = pe_core::DOWNLOAD_LIMITS_MB.get(at) {
                let _ = shell().core.set_download_limit_mb(*megabytes);
            }
        },
    )
}

/// The trusted senders, each with a button that removes it; what the list is for above it
fn trusted_senders_page() -> adw::NavigationPage {
    let group = adw::PreferencesGroup::builder()
        .description(plain(Text::UiTrustedSendersNote))
        .build();
    fill_trusted_senders(&group);
    let page = adw::PreferencesPage::new();
    page.add(&group);
    let toolbar = adw::ToolbarView::new();
    toolbar.add_top_bar(&adw::HeaderBar::new());
    toolbar.set_content(Some(&page));
    let title = plain(Text::UiTrustedSendersTitle);
    let subpage = adw::NavigationPage::new(&toolbar, &title);
    subpage.set_widget_name("trusted-senders");
    subpage
}

/// The row that says no sender is trusted
fn no_trusted_senders() -> adw::ActionRow {
    let none = adw::ActionRow::builder()
        .title(plain(Text::UiTrustedSendersEmpty))
        .build();
    none.add_css_class("dim-label");
    none.set_widget_name("trusted-senders-empty");
    none
}

/// The rows of the trusted senders put in `group`, or a row that says there are none
fn fill_trusted_senders(group: &adw::PreferencesGroup) {
    let senders = shell().core.trusted_senders().unwrap_or_default();
    if senders.is_empty() {
        group.add(&no_trusted_senders());
        return;
    }
    for sender in senders {
        let row = adw::ActionRow::builder()
            .title(glib::markup_escape_text(&pe_core::pictures::trusted_label(&sender)))
            .build();
        row.set_widget_name("trusted-sender");
        let remove = gtk::Button::builder()
            .icon_name("user-trash-symbolic")
            .tooltip_text(plain(Text::UiRemove))
            .valign(gtk::Align::Center)
            .build();
        remove.add_css_class("flat");
        remove.set_widget_name("trusted-sender-remove");
        let (id, group_of_row, shown) = (sender.id, group.clone(), row.clone());
        remove.connect_clicked(move |_| {
            if shell().core.untrust_sender(id).is_ok() {
                group_of_row.remove(&shown);
                if shell().core.trusted_senders().is_ok_and(|left| left.is_empty()) {
                    group_of_row.add(&no_trusted_senders());
                }
            }
        });
        row.add_suffix(&remove);
        group.add(&row);
    }
}

/// `xdg-mime default` names the app's desktop file for message/rfc822
async fn make_eml_default(dialog: &adw::PreferencesDialog) {
    let desktop = format!("{}.desktop", crate::APP_ID);
    match run_program(&["xdg-mime", "default", &desktop, "message/rfc822"]).await {
        Ok(()) => dialog.add_toast(adw::Toast::new(&plain(Text::UiEmlDefaultDone))),
        Err(reason) => ui::alert(dialog, TITLE, &t!(UiEmlDefaultFailed, reason = &*reason)).await,
    }
}

/// Runs `argv` to its end; why not when it could not start or failed (what it wrote to standard error)
async fn run_program(argv: &[&str]) -> Result<(), String> {
    let argv: Vec<&OsStr> = argv.iter().map(OsStr::new).collect();
    let process = gio::Subprocess::newv(&argv, gio::SubprocessFlags::STDERR_PIPE).map_err(|e| e.to_string())?;
    let (_, error) = process.communicate_utf8_future(None).await.map_err(|e| e.to_string())?;
    if process.is_successful() {
        return Ok(());
    }
    Err(error
        .map(|e| e.trim().to_string())
        .filter(|e| !e.is_empty())
        .unwrap_or_else(|| format!("{} {}", argv[0].to_string_lossy(), process.exit_status())))
}

/// The names of the languages in full: "System default (Deutsch)" is not cut off as the row's own labels would
fn whole_names() -> gtk::SignalListItemFactory {
    let factory = gtk::SignalListItemFactory::new();
    factory.connect_setup(|_, item| {
        if let Some(item) = item.downcast_ref::<gtk::ListItem>() {
            item.set_child(Some(&gtk::Label::builder().xalign(0.0).build()));
        }
    });
    factory.connect_bind(|_, item| {
        let Some(item) = item.downcast_ref::<gtk::ListItem>() else {
            return;
        };
        let name = item.item().and_downcast::<gtk::StringObject>().map(|s| s.string());
        if let (Some(label), Some(name)) = (item.child().and_downcast::<gtk::Label>(), name) {
            label.set_text(&name);
        }
    });
    factory
}

/// The language changes at the next start: now, or later; `parent` closes first when it is a dialog
pub async fn ask_restart(parent: &impl IsA<gtk::Widget>) {
    let chosen = language_of(shell().settings.text(settings::LANGUAGE).as_deref());
    let (later, now) = (
        crate::words::plain(crate::words::Text::UiRestartLater),
        crate::words::plain(crate::words::Text::UiRestartNow),
    );
    let answers = [("later", later.as_str()), ("restart", now.as_str())];
    let answer = ui::ask(
        parent,
        TITLE,
        &t!(UiRestartAsk, language = crate::words::language_name(chosen)),
        &answers,
        "restart",
        "later",
        None,
    )
    .await;
    if answer == "restart" {
        if let Some(dialog) = parent.as_ref().downcast_ref::<adw::Dialog>() {
            dialog.close();
        }
        spawn(crate::app::restart());
    }
}

/// Command::Options: the main menu's Preferences
pub fn run() {
    let window = shell().main().window().clone();
    spawn(async move { open(&window).await });
}
