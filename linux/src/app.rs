//! The app: the core opened for the mail store, its events brought to the window thread, the commands of the menus
//! (one exhaustive match over the command table), the tray and the status bar's words. What the windows show comes
//! from the core already decoded; this file decides nothing about mail data.

use std::cell::{Cell, OnceCell, RefCell};
use std::collections::{HashMap, HashSet};
use std::path::{Path, PathBuf};
use std::rc::Rc;

use adw::prelude::*;
use gtk::{gio, glib};
use pe_core::{DraftKind, Event, FailureKind, SignInWith};

use crate::commands::Command;
use crate::mailbox::Mailbox;
use crate::settings::{self, Settings};
use crate::ui::{self, TITLE};
use crate::{Arguments, compose, notify, tray};

/// Every account is synced this often
const SYNC_INTERVAL: u32 = 10 * 60;

pub struct Shell {
    pub core: pe_core::Core,
    pub application: adw::Application,
    pub settings: Settings,
    /// Test runs (--sign-in-page-file): a browser sign-in writes its page here instead of opening the browser
    pub sign_in_page_file: Option<PathBuf>,
    main: OnceCell<Rc<Mailbox>>,
    /// The dialogs waiting for the event of a request (a lookup, a sign-in, a check), by request
    requests: RefCell<HashMap<u64, async_channel::Sender<bool>>>,
    /// Accounts whose password prompt is open, so a second failure does not open another
    prompting: RefCell<HashSet<i64>>,
    /// Accounts whose last sync failed: their failure stays in the status bar
    failing: RefCell<HashSet<i64>>,
    /// The last message sent, as the outgoing part of the status bar says once the Outbox is empty
    last_sent: RefCell<String>,
    /// Tools > Notify of New Mail
    pub notify: Cell<bool>,
    /// Quit was chosen: closing the window ends the app rather than hiding it in the tray
    exiting: Cell<bool>,
    /// The icon in the top bar, when the desktop has a place for it
    pub tray: RefCell<Option<tray::Tray>>,
    /// Keeps the app running while its window is hidden in the tray
    hold: RefCell<Option<gio::ApplicationHoldGuard>>,
    /// The windows a message is written in
    pub composes: RefCell<Vec<Rc<compose::Compose>>>,
}

thread_local! {
    static SHELL: OnceCell<Rc<Shell>> = const { OnceCell::new() };
}

/// The app, once it started
pub fn shell() -> Rc<Shell> {
    SHELL.with(|shell| shell.get().cloned()).expect("the app has started")
}

/// Runs `future` on the window thread
pub fn spawn(future: impl std::future::Future<Output = ()> + 'static) {
    glib::spawn_future_local(future);
}

/// The first start: the core opened for the store of the command line, the main window, the first account
pub fn start(application: &adw::Application, arguments: Arguments) {
    let store = arguments.store.clone().unwrap_or_else(crate::default_store);
    if let Some(dir) = store.parent() {
        let _ = std::fs::create_dir_all(dir);
    }
    let (send, events) = async_channel::unbounded::<Event>();
    let core = open_core(&store, &arguments, move |event| {
        // called on a worker thread: handed to the window thread, never waited for
        let _ = send.try_send(event);
    });
    let Some(core) = core else {
        let why = if arguments.certificate.is_none() {
            "The mail store could not be opened."
        } else {
            "The mail store or the certificate file could not be opened."
        };
        fail_to_start(application, why);
        return;
    };
    let settings = Settings::load();
    let notify = settings.bool(settings::NOTIFY, true);
    let state = Rc::new(Shell {
        core,
        application: application.clone(),
        settings,
        sign_in_page_file: arguments.sign_in_page_file.clone(),
        main: OnceCell::new(),
        requests: RefCell::default(),
        prompting: RefCell::default(),
        failing: RefCell::default(),
        last_sent: RefCell::default(),
        notify: Cell::new(notify),
        exiting: Cell::new(false),
        tray: RefCell::new(None),
        hold: RefCell::new(None),
        composes: RefCell::default(),
    });
    SHELL.with(|cell| {
        let _ = cell.set(state.clone());
    });
    install_app_actions(application);
    let main = Mailbox::new(application);
    let _ = state.main.set(main.clone());
    spawn(async move {
        while let Ok(event) = events.recv().await {
            shell().on_event(event);
        }
    });
    state.show_outbox();
    glib::timeout_add_seconds_local(SYNC_INTERVAL, || {
        shell().sync_all();
        glib::ControlFlow::Continue
    });
    *state.tray.borrow_mut() = tray::Tray::start();
    state.show_unread();
    application.connect_shutdown(|_| shell().settings.flush());
    main.window().present();
    first_run(arguments);
}

fn open_core(
    store: &Path,
    arguments: &Arguments,
    events: impl Fn(Event) + Send + Sync + 'static,
) -> Option<pe_core::Core> {
    let trust = match &arguments.certificate {
        None => pe_net::Trust::Platform,
        Some(file) => pe_net::Trust::pinned_file(file)?,
    };
    let passwords = if arguments.memory_passwords {
        pe_core::PasswordStore::Memory
    } else {
        pe_core::PasswordStore::System
    };
    let options = pe_core::Options {
        trust,
        passwords,
        oauth_providers: Vec::new(),
    };
    pe_core::Core::open_with(store, options, events).ok()
}

/// The store could not be opened: said in a window of its own, then the app ends
fn fail_to_start(application: &adw::Application, why: &'static str) {
    let window = adw::ApplicationWindow::builder()
        .application(application)
        .title(TITLE)
        .default_width(480)
        .default_height(200)
        .build();
    window.present();
    let closing = window.clone();
    spawn(async move {
        ui::alert(&closing, TITLE, why).await;
        closing.close();
    });
}

/// The first start: an account to read mail from, then what the command line asked for
fn first_run(arguments: Arguments) {
    let shell = shell();
    let none = shell.core.accounts().map(|accounts| accounts.is_empty()).unwrap_or(true);
    spawn(async move {
        if none {
            add_account().await;
        } else {
            shell.sync_all();
        }
        open_arguments(arguments).await;
    });
}

/// Another start for this store handed its command line over: the window in front, with what it was for
pub fn hand_over(arguments: Arguments) {
    let shell = shell();
    shell.show_main();
    spawn(open_arguments(arguments));
}

async fn open_arguments(arguments: Arguments) {
    let shell = shell();
    if let Some(link) = &arguments.mailto {
        shell.open_mailto(link).await;
    }
    for file in &arguments.files {
        shell.main().import_file(file).await;
    }
}

/// File > New Account; the tree built again and every account synced when one was added
pub async fn add_account() {
    let shell = shell();
    if crate::accounts::new_account(shell.main().window()).await > 0 {
        shell.main().reload();
        shell.sync_all();
    }
}

impl Shell {
    pub fn main(&self) -> Rc<Mailbox> {
        self.main.get().cloned().expect("the main window")
    }

    // ---- requests the dialogs wait for ----

    pub fn watch_request(&self, request: u64, done: async_channel::Sender<bool>) {
        self.requests.borrow_mut().insert(request, done);
    }

    pub fn forget_request(&self, request: u64) {
        self.requests.borrow_mut().remove(&request);
    }

    fn request_done(&self, request: u64) {
        if let Some(done) = self.requests.borrow_mut().remove(&request) {
            let _ = done.try_send(true);
        }
    }

    // ---- the core's events ----

    fn on_event(&self, event: Event) {
        let main = self.main();
        match &event {
            Event::SyncStarted { account } => {
                self.failing.borrow_mut().remove(account);
                main.set_status(&format!("Checking for new messages on {}...", main.account_name(*account)));
            }
            Event::SyncFinished { .. } => {
                // a failure stays in the status bar until the account syncs without one
                if self.failing.borrow().is_empty() {
                    main.set_status("Done");
                }
            }
            Event::AutoconfigDone { request }
            | Event::SignInDone { request }
            | Event::SignInAppChecked { request } => self.request_done(*request),
            Event::NewMail { .. } => self.notify_new_mail(&event),
            Event::Unsubscribed { request, problem } => {
                let said = main.unsubscribed(*request, problem.as_deref());
                if !said.is_empty() {
                    main.set_status(&said);
                }
            }
            Event::MessageSent { subject, .. } => {
                // shown by the OutboxChanged that follows it
                *self.last_sent.borrow_mut() = format!("Sent {} at {}", quoted(subject), ui::time_now());
            }
            Event::DraftSaved {
                message_id, problem, ..
            } => {
                // the window that saved it says so; one that closed after saving leaves it to the status bar
                if !compose::draft_saved(message_id, problem.as_deref()) {
                    match problem {
                        None => main.set_status("Message saved in Drafts."),
                        Some(problem) => main.set_status(&format!("The message was not saved in Drafts: {problem}")),
                    }
                }
            }
            Event::OutboxChanged { .. } => self.show_outbox(),
            Event::Failed { account, kind, message } => {
                self.failing.borrow_mut().insert(*account);
                main.set_status(&format!("{}: {message}", main.account_name(*account)));
                if *kind == FailureKind::Authentication {
                    spawn(ask_password(*account));
                }
            }
            _ => {}
        }
        main.on_event(&event);
        // the tray and the dock: what is unread in the Inboxes, when a folder changed
        if matches!(event, Event::FolderChanged { .. } | Event::SyncFinished { .. }) {
            self.show_unread();
        }
        main.show_counts();
    }

    pub fn show_unread(&self) {
        let unread = self.core.inbox_unread().unwrap_or(0);
        notify::show_unread(unread);
        if let Some(tray) = &*self.tray.borrow() {
            tray.count(unread);
        }
    }

    /// New mail: a notification, unless the window is in front (the list shows it) or notifications are off
    fn notify_new_mail(&self, event: &Event) {
        let Event::NewMail {
            folder,
            uid,
            count,
            from,
            subject,
            ..
        } = event
        else {
            return;
        };
        let window = self.main().window().clone();
        if !self.notify.get() || (window.is_visible() && window.is_active()) {
            return;
        }
        let subject = if subject.is_empty() { "(no subject)" } else { subject };
        if *count <= 1 {
            notify::new_mail(&self.application, from, subject, *folder, *uid);
        } else {
            let text = format!("The newest from {from}: {subject}");
            notify::new_mail(&self.application, &format!("{count} new messages"), &text, *folder, *uid);
        }
    }

    /// The outgoing part of the status bar, which other work does not write over: what is being sent, what waits in
    /// the Outbox and why, or the last message sent
    pub fn show_outbox(&self) {
        let waiting = self.core.outbox().unwrap_or_default();
        let text = match waiting.as_slice() {
            [] => self.last_sent.borrow().clone(),
            [first] if first.problem.is_some() => format!("{} waits in the Outbox", quoted(&first.subject)),
            [first] => format!("Sending {}...", quoted(&first.subject)),
            more => format!("{} messages in the Outbox", more.len()),
        };
        self.main().set_outgoing(&text);
    }

    pub fn sync_all(&self) {
        for account in self.core.accounts().unwrap_or_default() {
            let _ = self.core.sync(account.id);
        }
    }

    /// The window back from the tray, in front
    pub fn show_main(&self) {
        self.hold.borrow_mut().take();
        self.main().window().present();
    }

    /// The window's close button: with an icon in the top bar the app keeps checking mail there (the first time it
    /// says so); without one, the app ends as GNOME expects. False when the window should close after all
    pub fn close_main(&self) -> bool {
        if self.exiting.get() || self.tray.borrow().is_none() {
            spawn(quit());
            return false;
        }
        *self.hold.borrow_mut() = Some(self.application.hold());
        self.main().window().set_visible(false);
        if !self.settings.bool(settings::TRAY_NOTE, false) {
            self.settings.set_bool(settings::TRAY_NOTE, true);
            notify::note(
                &self.application,
                "Inbox Classic is still running",
                "It keeps checking for new mail. Its icon in the top bar opens it again, or quits it.",
            );
        }
        false
    }

    /// A new message from `account`, or from the account of the selected folder when 0
    pub fn new_message(&self, account: i64) {
        let account = if account != 0 { account } else { self.main().current_account() };
        if account == 0 {
            let window = self.main().window().clone();
            spawn(async move { ui::alert(&window, TITLE, "Add a mail account first.").await });
            return;
        }
        compose::open(account, None);
    }

    /// A new message from a mailto: link, from the account of what is shown (the core reads the link)
    pub async fn open_mailto(&self, link: &str) {
        let Some(draft) = pe_core::mailto::draft(link) else {
            return;
        };
        let account = self.main().current_account();
        if account == 0 {
            let text = "Add a mail account first, then click the e-mail link again.";
            ui::alert(self.main().window(), TITLE, text).await;
            return;
        }
        compose::open(account, Some(draft));
    }

    fn reply(&self, kind: DraftKind) {
        let main = self.main();
        match main.draft_of_shown(kind) {
            Some(draft) => compose::open(main.current_account(), Some(draft)),
            None => {
                let window = main.window().clone();
                spawn(async move { ui::alert(&window, TITLE, "Select a message first.").await });
            }
        }
    }

    pub fn set_notify(&self, on: bool) {
        self.notify.set(on);
        self.settings.set_bool(settings::NOTIFY, on);
        if let Some(action) = self.main().window().lookup_action(Command::Notify.name()) {
            action.change_state(&on.to_variant());
        }
        if let Some(tray) = &*self.tray.borrow() {
            tray.refresh();
        }
    }
}

/// "Subject" in quotes, or "(no subject)"
fn quoted(subject: &str) -> String {
    if subject.is_empty() {
        "(no subject)".into()
    } else {
        format!("\u{201C}{subject}\u{201D}")
    }
}

/// A refused password is asked for again; an account that signs in through the browser signs in again
async fn ask_password(account: i64) {
    let shell = shell();
    if !shell.prompting.borrow_mut().insert(account) {
        return;
    }
    let main = shell.main();
    if let Some(with) = main.sign_in(account) {
        sign_in_again(account, with).await;
    } else if let Some(password) = crate::accounts::password_dialog(main.window(), &main.account_name(account)).await {
        shell.core.set_password(account, &password);
        let _ = shell.core.sync(account);
    }
    shell.prompting.borrow_mut().remove(&account);
}

async fn sign_in_again(account: i64, with: SignInWith) {
    let shell = shell();
    let main = shell.main();
    let window = main.window().clone();
    let text = format!(
        "The sign-in of {} was refused or ran out.\n\nSign in again in the browser?",
        main.account_name(account)
    );
    if !ui::confirm(&window, TITLE, &text, false).await {
        return;
    }
    let Some(request) = crate::accounts::sign_in_with_browser(&window, with, &main.account_email(account)).await else {
        return;
    };
    match shell.core.reauthorize(account, request) {
        Ok(()) => {
            let _ = shell.core.sync(account);
        }
        Err(reason) => {
            ui::alert(&window, TITLE, &format!("Signing in again did not work: {reason}")).await;
        }
    }
}

/// Quit: the messages being written first, each may ask to be saved; the app stays when one is kept open
pub async fn quit() {
    let shell = shell();
    shell.exiting.set(true);
    if !compose::close_all().await {
        shell.exiting.set(false);
        return;
    }
    if let Some(tray) = shell.tray.borrow_mut().take() {
        tray.stop();
    }
    crate::help::close();
    shell.hold.borrow_mut().take();
    shell.settings.flush();
    shell.application.quit();
}

/// Tools > Make Default Mail App: the desktop file names the app for mailto: links; it is chosen as their program
async fn make_default_mail_app() {
    let shell = shell();
    let window = shell.main().window().clone();
    let desktop = format!("{}.desktop", crate::APP_ID);
    let Some(app) = gio::AppInfo::all().into_iter().find(|app| app.id().as_deref() == Some(desktop.as_str())) else {
        let text = "This copy of Inbox Classic was not installed, so the system does not list it as a mail app. \
                    Install it to choose it.";
        ui::alert(&window, TITLE, text).await;
        return;
    };
    let ours = gio::AppInfo::default_for_uri_scheme("mailto").and_then(|current| current.id()).as_deref()
        == Some(desktop.as_str());
    let said = if ours {
        "Inbox Classic is your default mail app: e-mail links open a new message here."
    } else if app.set_as_default_for_type("x-scheme-handler/mailto").is_ok() {
        "Inbox Classic is now your default mail app: e-mail links open a new message here."
    } else {
        "Inbox Classic could not be made the default mail app."
    };
    ui::alert(&window, TITLE, said).await;
}

fn show_about() {
    let window = shell().main().window().clone();
    let about = adw::AboutDialog::builder()
        .application_name(TITLE)
        .application_icon(crate::APP_ID)
        .version(crate::VERSION)
        .comments(format!("Core {}", pe_core::VERSION))
        .developer_name("Postal Systems OÜ")
        .website("https://inboxclassic.com")
        .license_type(gtk::License::MitX11)
        .build();
    about.present(Some(&window));
}

/// A command of the menus, the header bar, the keyboard or the tray. One arm for each command of the table, no
/// wildcard: a command added to core/commands.toml fails the build here until it is handled
pub fn run_command(command: Command) {
    let shell = shell();
    let main = shell.main();
    match command {
        Command::NewAccount => spawn(add_account()),
        Command::Exit => spawn(quit()),
        Command::Sync => shell.sync_all(),
        Command::MarkRead => main.mark_selected(true),
        Command::MarkUnread => main.mark_selected(false),
        Command::Pictures => main.load_pictures(),
        Command::About => show_about(),
        Command::NewMail => shell.new_message(0),
        Command::Reply => shell.reply(DraftKind::Reply),
        Command::ReplyAll => shell.reply(DraftKind::ReplyAll),
        Command::Forward => shell.reply(DraftKind::Forward),
        Command::Help => crate::help::open(),
        Command::Delete => spawn(async move { main.delete_selected().await }),
        Command::Move => spawn(async move { main.move_selected().await }),
        Command::Flag => main.flag_selected(),
        Command::NewFolder => spawn(async move { main.new_folder().await }),
        Command::RenameFolder => spawn(async move { main.rename_folder().await }),
        Command::DeleteFolder => spawn(async move { main.delete_folder().await }),
        Command::Accounts => spawn(async move {
            if crate::accounts::accounts_dialog(main.window()).await {
                main.reload();
                shell.sync_all();
            }
        }),
        Command::Find => main.focus_find(),
        Command::SaveAs => spawn(async move { main.save_shown_as().await }),
        Command::Print => main.print_shown(),
        Command::Import => spawn(async move { main.import().await }),
        Command::Outbox => spawn(async move {
            crate::outbox::outbox_dialog(main.window()).await;
            shell.show_outbox();
        }),
        Command::Properties => spawn(async move { main.show_properties().await }),
        Command::MarkAllRead => main.mark_all_read(),
        Command::Junk => spawn(async move { main.mark_junk(true).await }),
        Command::NotJunk => spawn(async move { main.mark_junk(false).await }),
        Command::Notify => shell.set_notify(!shell.notify.get()),
        Command::Open => shell.show_main(),
        Command::DefaultApp => spawn(make_default_mail_app()),
    }
}

/// The app's own actions: a click on a new-mail notification opens its message
fn install_app_actions(application: &adw::Application) {
    let show = gio::SimpleAction::new("show-message", Some(&<(i64, u64)>::static_variant_type()));
    show.connect_activate(|_, target| {
        let Some((folder, uid)) = target.and_then(|t| t.get::<(i64, u64)>()) else {
            return;
        };
        let shell = shell();
        shell.show_main();
        shell.main().show_message(folder, uid);
    });
    application.add_action(&show);
    let open = gio::SimpleAction::new("open", None);
    open.connect_activate(|_, _| shell().show_main());
    application.add_action(&open);
}
