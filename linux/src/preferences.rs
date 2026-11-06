//! Preferences (the main menu, Ctrl+,): the language of the windows and Notify of New Mail, in a libadwaita
//! preferences dialog as GNOME apps have it. A language chosen is saved in settings.ini and used from the next start;
//! the app offers to start again in it at once.

use adw::prelude::*;

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
                GtkSystemDefault,
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
        .title(plain(Text::CmdNotify))
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
    let mail = adw::PreferencesGroup::builder().title(t!(GtkNewMailGroup)).build();
    mail.add(&notify);

    let page = adw::PreferencesPage::new();
    page.add(&words);
    page.add(&mail);
    let dialog = adw::PreferencesDialog::builder()
        .title(t!(GtkPreferences))
        .content_width(600)
        .content_height(360)
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
    let (later, now) = (t!(GtkRestartLater), t!(GtkRestartNow));
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
