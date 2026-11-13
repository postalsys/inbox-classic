//! Preferences (the main menu, Ctrl+,): the language of the windows, Group messages by conversation, the pictures of
//! messages (every message's, the trusted senders), Notify of New Mail, the app for .eml files and what is downloaded
//! before it is opened, in a libadwaita
//! preferences dialog as GNOME apps have it. A language chosen is saved in settings.ini and used
//! from the next start; the app offers to start again in it at once.

use std::ffi::OsStr;

use adw::prelude::*;
use gtk::{gio, glib};

use crate::app::{shell, spawn};
use crate::settings;
use crate::ui::{self, TITLE};
use crate::words::{Text, plain};

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
    let app = shell();
    let offered = choices();
    let saved = app.settings.text(settings::LANGUAGE);
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
    let model = gtk::StringList::new(&names.iter().map(String::as_str).collect::<Vec<_>>());
    let language = adw::ComboRow::builder()
        .title(t!(GtkLanguage))
        .subtitle(t!(GtkLanguageSubtitle))
        .model(&model)
        .factory(&whole_names())
        .build();
    language.set_widget_name("preferences-language");
    let at = offered.iter().position(|c| *c == saved).unwrap_or(0);
    language.set_selected(at as u32);
    let words = adw::PreferencesGroup::new();
    words.add(&language);

    let notify = adw::SwitchRow::builder()
        .title(t!(GtkNotifyNewMail))
        .subtitle(t!(GtkNotifySubtitle))
        .active(app.notify.get())
        .build();
    notify.set_widget_name("preferences-notify");
    notify.connect_active_notify(|row| {
        let shell = shell();
        if shell.notify.get() != row.is_active() {
            shell.set_notify(row.is_active());
        }
    });
    let codes = adw::SwitchRow::builder()
        .title(plain(Text::UiCodesInNotifications))
        .active(pe_core::otp::in_notifications())
        .build();
    codes.set_widget_name("preferences-codes");
    codes.connect_active_notify(|row| {
        shell()
            .settings
            .set_bool(settings::CODES_IN_NOTIFICATIONS, row.is_active());
        pe_core::otp::set_in_notifications(row.is_active());
    });
    let mail = adw::PreferencesGroup::builder().title(t!(GtkNewMailGroup)).build();
    mail.add(&notify);
    mail.add(&codes);

    let grouped = adw::SwitchRow::builder()
        .title(plain(Text::UiGroupByConversation))
        .active(crate::mailbox::grouped())
        .build();
    grouped.set_widget_name("preferences-group-threads");
    grouped.connect_active_notify(|row| {
        let shell = shell();
        if crate::mailbox::grouped() != row.is_active() {
            shell
                .settings
                .set_bool(settings::GROUP_BY_CONVERSATION, row.is_active());
            shell.main().regroup();
        }
    });
    let list = adw::PreferencesGroup::new();
    list.add(&layout_row());
    list.add(&grouped);

    let page = adw::PreferencesPage::new();
    page.add(&words);
    page.add(&list);
    page.add(&pictures_group());
    page.add(&mail);
    page.add(&files_group());
    page.add(&download_group());
    let dialog = adw::PreferencesDialog::builder()
        .title(t!(GtkPreferences))
        .content_width(600)
        // every row in view, none cut off at the bottom
        .content_height(700)
        .build();
    dialog.set_widget_name("preferences-dialog");
    dialog.add(&page);

    let asking = dialog.clone();
    language.connect_selected_notify(move |row| {
        let Some(choice) = choices().get(row.selected() as usize).copied() else {
            return;
        };
        let shell = shell();
        shell.settings.set_text(settings::LANGUAGE, choice);
        // the same words as now: nothing to start again for
        if language_of(choice) == pe_core::i18n::language() {
            return;
        }
        let dialog = asking.clone();
        spawn(async move { ask_restart(&dialog).await });
    });
    dialog.present(Some(parent.as_ref()));
}

/// Reading: Download pictures in all messages (with what it tells senders), and the trusted senders on a page of their
/// own
fn pictures_group() -> adw::PreferencesGroup {
    let core = &shell().core;
    let always = adw::SwitchRow::builder()
        .title(plain(Text::UiPicturesAlwaysOption))
        .subtitle(plain(Text::UiPicturesAlwaysWarning))
        .active(core.always_load_pictures().unwrap_or(false))
        .build();
    always.set_widget_name("preferences-pictures-always");
    always.connect_active_notify(|row| {
        let _ = shell().core.set_always_load_pictures(row.is_active());
    });
    let trusted = adw::ActionRow::builder()
        .title(plain(Text::UiTrustedSendersTitle))
        .activatable(true)
        .build();
    trusted.add_suffix(&gtk::Image::from_icon_name("go-next-symbolic"));
    trusted.set_widget_name("preferences-trusted-senders");
    trusted.connect_activated(|row| {
        if let Some(dialog) = row
            .ancestor(adw::PreferencesDialog::static_type())
            .and_downcast::<adw::PreferencesDialog>()
        {
            dialog.push_subpage(&trusted_senders_page());
        }
    });
    let group = adw::PreferencesGroup::new();
    group.add(&always);
    group.add(&trusted);
    group
}

/// Layout: Automatic, Classic or Columns, as View > Layout chooses
fn layout_row() -> adw::ComboRow {
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
    choice_row(Text::UiLayoutLabel, &names, "preferences-layout", at, move |chosen| {
        if let Some(&mode) = modes.get(chosen)
            && mode != shell().main().layout_mode()
        {
            shell().main().set_layout_mode(mode);
        }
    })
}

/// A row choosing one of `choices`, the one chosen under its title, where a long one has room in every language;
/// `chosen` is called with the place of a new choice
fn choice_row(
    title: Text,
    choices: &[String],
    name: &str,
    selected: usize,
    chosen: impl Fn(usize) + 'static,
) -> adw::ComboRow {
    let row = adw::ComboRow::builder()
        .title(crate::words::field_title(title))
        .use_subtitle(true)
        .model(&gtk::StringList::new(
            &choices.iter().map(String::as_str).collect::<Vec<_>>(),
        ))
        .build();
    row.set_widget_name(name);
    row.set_selected(selected as u32);
    row.connect_selected_notify(move |row| chosen(row.selected() as usize));
    row
}

/// Downloading: what is downloaded before it is opened, how much each account keeps, and what that means
fn download_group() -> adw::PreferencesGroup {
    let core = &shell().core;
    // in the order of the words below
    let aheads = [pe_core::Ahead::Recent, pe_core::Ahead::All, pe_core::Ahead::Never];
    let names = [
        plain(Text::UiDownloadAheadRecent),
        plain(Text::UiDownloadAheadAll),
        plain(Text::UiDownloadAheadNever),
    ];
    let now = core.download_ahead().unwrap_or_default();
    let ahead = choice_row(
        Text::UiDownloadAhead,
        &names,
        "preferences-download-ahead",
        aheads.iter().position(|a| *a == now).unwrap_or(0),
        move |at| {
            if let Some(chosen) = aheads.get(at) {
                let _ = shell().core.set_download_ahead(*chosen);
            }
        },
    );
    let limits: Vec<String> = pe_core::DOWNLOAD_LIMITS_MB
        .iter()
        .map(|megabytes| pe_core::download_limit_text(*megabytes))
        .collect();
    let kept = core.download_limit_mb().unwrap_or(pe_core::DEFAULT_LIMIT_MB);
    let limit = choice_row(
        Text::UiDownloadLimit,
        &limits,
        "preferences-download-limit",
        pe_core::download_limit_index(kept),
        |at| {
            if let Some(megabytes) = pe_core::DOWNLOAD_LIMITS_MB.get(at) {
                let _ = shell().core.set_download_limit_mb(*megabytes);
            }
        },
    );
    let group = adw::PreferencesGroup::builder()
        .title(plain(Text::UiDownloadHeading))
        .description(plain(Text::UiDownloadNote))
        .build();
    group.add(&ahead);
    group.add(&limit);
    group
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

/// Files: make the app the one that opens .eml files (xdg-mime), said in a toast or, when it could not, an alert
fn files_group() -> adw::PreferencesGroup {
    let eml = adw::ButtonRow::builder().title(plain(Text::UiEmlDefault)).build();
    eml.set_widget_name("preferences-eml-default");
    eml.connect_activated(|row| {
        let Some(dialog) = row
            .ancestor(adw::PreferencesDialog::static_type())
            .and_downcast::<adw::PreferencesDialog>()
        else {
            return;
        };
        spawn(async move { make_eml_default(&dialog).await });
    });
    let group = adw::PreferencesGroup::new();
    group.add(&eml);
    group
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

/// The language changes at the next start: now, or later
async fn ask_restart(parent: &adw::PreferencesDialog) {
    let (later, now) = (
        crate::words::plain(crate::words::Text::UiRestartLater),
        crate::words::plain(crate::words::Text::UiRestartNow),
    );
    let answers = [("later", later.as_str()), ("restart", now.as_str())];
    let answer = ui::ask(
        parent,
        TITLE,
        &t!(GtkRestartToChange),
        &answers,
        "restart",
        "later",
        None,
    )
    .await;
    if answer == "restart" {
        parent.close();
        spawn(crate::app::restart());
    }
}

/// Command::Options: the main menu's Preferences
pub fn run() {
    let window = shell().main().window().clone();
    spawn(async move { open(&window).await });
}
