//! Whether each account is signed in and can connect, as the window shows it: the bar over the message list with the
//! account's words and one button, what that button (and the folder tree's mark, Tools > Sign In Again and the
//! account's menu) does, and the one dialog (or, in the background, the notification) the core asks for when the
//! account's state comes about. The core keeps the state and writes every word ([`pe_core::AccountStatus`]); this
//! file only shows them and does what they name.

use std::cell::Cell;
use std::rc::Rc;

use adw::prelude::*;
use gtk::glib;
use pe_core::{AccountState, AccountStatus, Prompt, StatusAction};

use crate::app::{shell, spawn};
use crate::ui::{self, TITLE};

/// The bar over the message list while the account of what is listed is not connected: its mark, the core's sentence
/// and the button its state offers
pub struct Bar {
    bar: ui::InfoBar,
    button: gtk::Button,
    /// The account it speaks for, 0 while hidden
    account: Cell<i64>,
}

impl Bar {
    pub fn new() -> Rc<Bar> {
        let bar = ui::InfoBar::new("account-bar");
        let button = gtk::Button::new();
        button.set_valign(gtk::Align::Center);
        button.set_widget_name("account-bar-button");
        bar.widget.append(&button);
        let bar = Rc::new(Bar {
            bar,
            button,
            account: Cell::new(0),
        });
        let weak = Rc::downgrade(&bar);
        bar.button.connect_clicked(move |_| {
            if let Some(bar) = weak.upgrade()
                && bar.account.get() != 0
            {
                spawn(run(bar.account.get()));
            }
        });
        bar
    }

    pub fn widget(&self) -> &gtk::Box {
        &self.bar.widget
    }

    /// The bar for `account` as the core says it is now; hidden for None or an account that is connected
    pub fn show(&self, account: Option<i64>) {
        let status = account.and_then(|account| Some((account, shell().core.account_status(account).ok()?)));
        let Some((account, status)) = status.filter(|(_, status)| status.state != AccountState::Connected) else {
            self.account.set(0);
            self.bar.widget.set_visible(false);
            return;
        };
        self.account.set(account);
        self.bar.text.set_text(&status.bar);
        self.button.set_label(&status.button);
        self.button.set_visible(!status.button.is_empty());
        crate::folders::show_mark_icon(&self.bar.icon, status.mark);
        let signing_in = matches!(status.state, AccountState::SignInNeeded(_));
        ui::set_class(&self.bar.widget, "sign-in", signing_in);
        ui::set_class(&self.bar.widget, "cannot-connect", !signing_in);
        self.bar.widget.set_visible(true);
    }

    /// The account the bar speaks for (0 while hidden), its words and its button's, for the e2e driver
    #[cfg(feature = "e2e")]
    pub fn shown(&self) -> (i64, String, String) {
        (
            self.account.get(),
            self.bar.text.text().into(),
            self.button.label().map(|l| l.to_string()).unwrap_or_default(),
        )
    }
}

/// Whether Sign In Again applies to `account` now (the menus, Tools, Properties): the cheap state first, the words
/// only for an account that is not connected
pub fn can_sign_in_again(account: i64) -> bool {
    let core = &shell().core;
    account != 0
        && core.account_state(account) != AccountState::Connected
        && core
            .account_status(account)
            .is_ok_and(|status| status.can_sign_in_again)
}

/// What the account's state offers, done: signing in again in the browser, the password asked for, the
/// administrator's link copied, the help, or a sync
pub async fn run(account: i64) {
    let shell = shell();
    let Ok(status) = shell.core.account_status(account) else {
        return;
    };
    match status.action {
        StatusAction::None => {}
        StatusAction::SignInAgain => crate::app::sign_in_again(account).await,
        StatusAction::EnterPassword => crate::app::enter_password(account, &status.password_hint).await,
        StatusAction::CopyAdminLink => copy_admin_link(&status),
        StatusAction::Help => crate::help::show_topic(&status.help_topic),
        StatusAction::SyncNow => {
            shell.main().sync_asked();
            let _ = shell.core.sync(account);
        }
    }
}

/// The link where the organization's administrator approves the app, on the clipboard; the status bar says so
fn copy_admin_link(status: &AccountStatus) {
    if status.admin_link.is_empty() {
        return;
    }
    let main = shell().main();
    main.window().clipboard().set_text(&status.admin_link);
    main.set_status(&t!(AccountStateAdminLinkCopied));
}

/// The core asks for the one dialog of `account`'s state (`AccountStateChanged` with `prompt`): shown now while the
/// window is in front, else a notification whose click brings the window back and does what the state offers
pub fn prompt(account: i64) {
    let shell = shell();
    let Ok(status) = shell.core.account_status(account) else {
        return;
    };
    if status.prompt == Prompt::None {
        return;
    }
    // in front: one of the app's windows has the focus (the main window, a message's, the help)
    let in_front = gtk::Window::list_toplevels()
        .iter()
        .filter_map(|w| w.downcast_ref::<gtk::Window>())
        .any(|w| w.is_visible() && w.is_active());
    if !in_front {
        crate::notify::sign_in_needed(
            &shell.application,
            account,
            &status.notification_title,
            &status.notification_text,
        );
        return;
    }
    shell.main().window().present();
    spawn(ask(account, status));
}

/// The dialog the state asks for: the password, whether to sign in again in the browser, or the bar's words with OK
/// and the bar's button
async fn ask(account: i64, status: AccountStatus) {
    let window = shell().main().window().clone();
    match status.prompt {
        Prompt::None => {}
        Prompt::Password => crate::app::enter_password(account, &status.password_hint).await,
        Prompt::BrowserSignIn => {
            let answers = [("cancel", t!(UiCancel)), ("sign-in", status.button.clone())];
            if answer(&window, &status.bar, &answers, "sign-in", "cancel").await == "sign-in" {
                crate::app::sign_in_again(account).await;
            }
        }
        Prompt::Inform => {
            let mut answers = vec![("ok", t!(UiOk))];
            if !status.button.is_empty() {
                answers.insert(0, ("action", status.button.clone()));
            }
            if answer(&window, &status.bar, &answers, "ok", "ok").await == "action" {
                run(account).await;
            }
        }
    }
}

/// A message box with `text` as the bar has it (not made a sentence's start: the account's name as the folder list
/// writes it), `answers` in their order, `default` for Enter and `close` for Esc; the id of the one chosen
async fn answer(
    window: &adw::ApplicationWindow,
    text: &str,
    answers: &[(&str, String)],
    default: &str,
    close: &str,
) -> String {
    let answers: Vec<(&str, &str)> = answers.iter().map(|(id, label)| (*id, label.as_str())).collect();
    ui::ask(window, TITLE, text, &answers, default, close, None).await
}

/// The app's action of the notification: the window in front, then what the account's state offers
pub fn install_action(application: &adw::Application) {
    let action = gtk::gio::SimpleAction::new("account-status", Some(glib::VariantTy::INT64));
    action.connect_activate(|_, target| {
        let Some(account) = target.and_then(|t| t.get::<i64>()) else {
            return;
        };
        shell().show_main();
        spawn(run(account));
    });
    application.add_action(&action);
}
