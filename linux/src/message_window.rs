//! A message in a window of its own, as Outlook Express opens one with a double-click: a reading pane of its own (the
//! Reader the main window has under its list) under a header bar with what can be done to that one message, and
//! Previous and Next through the list it was opened from. Several can be open; opening a message whose window is
//! open brings that window to the front. What it shows and what it does come from the core.

use std::cell::{Cell, RefCell};
use std::rc::Rc;

use adw::prelude::*;
use gtk::{gio, glib};
use pe_core::{Action, DraftKind, Event, ListView, MessageRef, Scope, Summary};

use crate::app::{shell, spawn};
use crate::commands::Command;
use crate::reader::Reader;
use crate::ui::{self, TITLE};

pub struct MessageWindow {
    pub window: adw::ApplicationWindow,
    pub reader: Rc<Reader>,
    title: adw::WindowTitle,
    /// Where the window says what it can not do (no unread message left)
    toasts: adw::ToastOverlay,
    /// Junk, or Not Junk for a message in a Junk folder
    junk: gtk::Button,
    /// The message shown
    message: Cell<MessageRef>,
    /// The list it was opened from, as it was then but a row a message: what Previous and Next go through
    view: ListView,
    /// The messages before and after it in that list. Kept when the message leaves the list (it is moved or deleted
    /// meanwhile), so Next still goes on from where it was
    neighbours: Cell<(Option<MessageRef>, Option<MessageRef>)>,
    /// The message in numbers: whether it can be archived, is in a Junk folder, goes for good when deleted
    summary: RefCell<Summary>,
}

thread_local! {
    static WINDOWS: RefCell<Vec<Rc<MessageWindow>>> = const { RefCell::new(Vec::new()) };
}

/// The message windows open now
pub fn windows() -> Vec<Rc<MessageWindow>> {
    WINDOWS.with(|windows| windows.borrow().clone())
}

/// `message` in a window of its own, Previous and Next going through the list `view` shows, message by message (its
/// grouping turned off); the window that shows it already brought to the front
pub fn open(message: MessageRef, mut view: ListView) {
    view.set_grouped(false);
    if let Some(open) = windows().into_iter().find(|w| w.message.get() == message) {
        open.window.present();
        return;
    }
    let window = MessageWindow::new(message, view);
    WINDOWS.with(|windows| windows.borrow_mut().push(window.clone()));
    window.window.present();
    window.show(message);
}

/// The core's events, for every message window
pub fn on_event(event: &Event) {
    for window in windows() {
        window.on_event(event);
    }
}

/// The one-click unsubscribe `request` of a message window done: what the status bar says, empty when it was none
/// of theirs
pub fn unsubscribed(request: u64, problem: Option<&str>) -> String {
    windows()
        .iter()
        .map(|w| w.reader.unsubscribed(request, problem))
        .find(|said| !said.is_empty())
        .unwrap_or_default()
}

impl MessageWindow {
    fn new(message: MessageRef, view: ListView) -> Rc<MessageWindow> {
        let reader = Reader::new();
        let title = adw::WindowTitle::new("", "");
        let (header, junk) = header_bar(&title);
        let toolbar = adw::ToolbarView::new();
        toolbar.add_top_bar(&header);
        let toasts = adw::ToastOverlay::new();
        toasts.set_child(Some(&reader.widget));
        toolbar.set_content(Some(&toasts));
        let window = adw::ApplicationWindow::builder()
            .application(&shell().application)
            .default_width(860)
            .default_height(700)
            .content(&toolbar)
            .icon_name(crate::APP_ID)
            .build();
        window.set_widget_name("message-window");
        let this = Rc::new(MessageWindow {
            window,
            reader,
            title,
            toasts,
            junk,
            message: Cell::new(message),
            view,
            neighbours: Cell::new((None, None)),
            summary: RefCell::default(),
        });
        this.install_actions();
        this.connect();
        this
    }

    /// The actions of the header bar's buttons. Those of the commands have the commands' names, so the keys the main
    /// window gives them (Ctrl+R, Ctrl+Shift+R, Ctrl+F, Ctrl+P, Ctrl+J, Ctrl+. and Ctrl+Shift+comma, F3) act on this message
    /// here
    fn install_actions(self: &Rc<Self>) {
        let add = |name: &str, run: fn(&Rc<MessageWindow>)| {
            let action = gio::SimpleAction::new(name, None);
            let weak = Rc::downgrade(self);
            action.connect_activate(move |_, _| {
                if let Some(this) = weak.upgrade() {
                    run(&this);
                }
            });
            self.window.add_action(&action);
        };
        add(Command::Reply.name(), |this| this.reply(DraftKind::Reply));
        add(Command::ReplyAll.name(), |this| this.reply(DraftKind::ReplyAll));
        add(Command::Forward.name(), |this| this.reply(DraftKind::Forward));
        add(Command::Print.name(), |this| this.reader.print(&this.window));
        add(Command::Delete.name(), |this| {
            let this = this.clone();
            spawn(async move { this.delete().await });
        });
        add(Command::Archive.name(), |this| this.act(Action::Archive));
        add(Command::Junk.name(), |this| this.act(Action::Junk(true)));
        add(Command::NotJunk.name(), |this| this.act(Action::Junk(false)));
        add(Command::PreviousMessage.name(), |this| this.step(false));
        add(Command::NextMessage.name(), |this| this.step(true));
        add(Command::NextUnread.name(), |this| this.next_unread());
        add(Command::FindInMessage.name(), |this| this.reader.find_in_message());
        add(Command::Help.name(), |_| crate::help::show("main"));
    }

    /// Esc and Ctrl+W close the window, Delete deletes the message; closing lets go of the window
    fn connect(self: &Rc<Self>) {
        let shortcuts = gtk::ShortcutController::new();
        shortcuts.set_scope(gtk::ShortcutScope::Managed);
        for (keys, action) in [
            ("Escape", "window.close"),
            ("<Primary>w", "window.close"),
            ("Delete", "win.delete"),
            // N goes to the next unread message, as in the main window's list
            ("n", "win.next-unread"),
        ] {
            shortcuts.add_shortcut(gtk::Shortcut::new(
                gtk::ShortcutTrigger::parse_string(keys),
                Some(gtk::NamedAction::new(action)),
            ));
        }
        self.window.add_controller(shortcuts);
        let weak = Rc::downgrade(self);
        self.window.connect_close_request(move |window| {
            if let Some(this) = weak.upgrade() {
                this.reader.clear(false);
                this.reader.preview.release();
            }
            WINDOWS.with(|windows| windows.borrow_mut().retain(|w| &w.window != window));
            glib::Propagation::Proceed
        });
    }

    /// `message` in the window: its header from the store at once, the message once the core has it; marked read
    fn show(&self, message: MessageRef) {
        let core = &shell().core;
        self.message.set(message);
        let stored = core.message(message.folder, message.uid).ok().flatten();
        self.reader.clear(true);
        let account = shell().main().folder_account(message.folder);
        self.reader
            .open(account, message.folder, message.uid, stored.as_ref().map(|m| &m.info));
        let subject = stored
            .as_ref()
            .map(|m| m.info.subject.clone())
            .filter(|s| !s.is_empty())
            .unwrap_or_else(|| t!(UiNoSubject));
        self.window.set_title(Some(&subject));
        self.title.set_title(&subject);
        self.title.set_subtitle(&shell().main().folder_name(message.folder));
        if stored.is_some_and(|m| !m.info.seen()) {
            let _ = core.set_seen(message.folder, message.uid, true);
        }
        self.neighbours.set((None, None));
        self.update_actions();
    }

    /// The message's neighbours in the list and its summary read again; the buttons follow them: Previous and Next
    /// off at the ends of the list, Archive where the message can be archived, Not Junk in place of Junk in a Junk
    /// folder
    fn update_actions(&self) {
        let core = &shell().core;
        let message = self.message.get();
        // not in the list any more: the neighbours it had stay
        if let Ok(Some(pair)) = self.view.neighbours(core, message.folder, message.uid) {
            self.neighbours.set(pair);
        }
        let summary = core.summary(&[message]).unwrap_or_default();
        let (previous, next) = self.neighbours.get();
        self.enable(Command::PreviousMessage.name(), previous.is_some());
        self.enable(Command::NextMessage.name(), next.is_some());
        self.enable(Command::Archive.name(), summary.archivable);
        let (command, icon, tooltip) = if summary.in_junk {
            (Command::NotJunk, "ic-mail-checkmark-symbolic", t!(UiTbNotJunk))
        } else {
            (Command::Junk, "ic-mail-prohibited-symbolic", t!(UiTbJunk))
        };
        self.junk.set_action_name(Some(&format!("win.{}", command.name())));
        self.junk.set_icon_name(icon);
        self.junk.set_tooltip_text(Some(&tooltip));
        *self.summary.borrow_mut() = summary;
    }

    fn enable(&self, name: &str, on: bool) {
        if let Some(action) = self.window.lookup_action(name).and_downcast::<gio::SimpleAction>() {
            action.set_enabled(on);
        }
    }

    /// Previous (`forward` false) or Next
    fn step(&self, forward: bool) {
        let (previous, next) = self.neighbours.get();
        if let Some(message) = if forward { next } else { previous } {
            self.show(message);
        }
    }

    /// Next Unread Message: the next unread message of the list the window came from; it does not go on to other
    /// folders (the main window does), so with none left it says so
    fn next_unread(&self) {
        let message = self.message.get();
        match self.view.next_unread_step(&shell().core, message.folder, message.uid) {
            Ok(pe_core::NextUnread::Message(next)) => self.show(next),
            _ => self.toasts.add_toast(adw::Toast::new(&t!(NoUnreadLeft))),
        }
    }

    /// Whether the list the window came from could have messages of `folder`: its own folder, an Inbox for All
    /// Inboxes, any folder for a search
    fn lists(&self, folder: i64) -> bool {
        match self.view.search().map(|search| search.scope) {
            Some(Scope::Folder(own)) => own == folder,
            Some(Scope::AllInboxes) => shell()
                .core
                .folder(folder)
                .is_ok_and(|f| f.info.path.eq_ignore_ascii_case("INBOX")),
            Some(Scope::Everywhere) => true,
            None => false,
        }
    }

    fn on_event(self: &Rc<Self>, event: &Event) {
        self.reader.on_event(event);
        let Event::FolderChanged { folder, .. } = event else {
            return;
        };
        let message = self.message.get();
        // moved or deleted from elsewhere: the window has nothing left to show
        if *folder == message.folder && !shell().core.has_message(message.folder, message.uid).unwrap_or(true) {
            self.window.close();
            return;
        }
        if *folder == message.folder || self.lists(*folder) {
            self.update_actions();
        }
    }

    /// A reply, a reply to all or a forward of the message, from its account
    fn reply(&self, kind: DraftKind) {
        let message = self.message.get();
        match shell().core.draft(message.folder, message.uid, kind) {
            Ok(Some(draft)) => crate::compose::open(shell().main().folder_account(message.folder), Some(draft)),
            _ => {
                let window = self.window.clone();
                spawn(async move { ui::alert(&window, TITLE, &t!(UiNotDownloaded)).await });
            }
        }
    }

    /// Delete: into Deleted Items, or for good there, asked first
    async fn delete(self: Rc<Self>) {
        let question = self.summary.borrow().delete_question();
        if let Some(question) = question
            && !ui::confirm(&self.window, TITLE, &question, true).await
        {
            return;
        }
        self.act(Action::Delete);
    }

    /// `action` done to the message, its outcome in the main window's status bar (Undo there takes it back); then
    /// the message after it in the list, or the one before at its end, or the window closes when none is left
    fn act(&self, action: Action) {
        if matches!(action, Action::Archive) && !self.summary.borrow().archivable {
            return;
        }
        let (previous, next) = self.neighbours.get();
        let outcome = shell().core.act(&[self.message.get()], action);
        let main = shell().main();
        main.update_undo();
        match outcome {
            Ok(text) => {
                main.set_status(&text);
                match next.or(previous) {
                    Some(next) => self.show(next),
                    None => self.window.close(),
                }
            }
            Err(error) => {
                let window = self.window.clone();
                spawn(async move { ui::alert(&window, TITLE, &pe_core::sentence(&error.to_string())).await });
            }
        }
    }
}

/// The header bar: answering (Reply, Reply All, Forward) and the message (Print, Delete, Archive, Junk) at the start,
/// as the main window has them; Previous and Next at the end
fn header_bar(title: &adw::WindowTitle) -> (adw::HeaderBar, gtk::Button) {
    let header = adw::HeaderBar::new();
    header.set_title_widget(Some(title));
    let button = |icon: &str, tooltip: &str, action: &str| {
        let button = ui::icon_button(icon, tooltip);
        button.set_action_name(Some(&format!("win.{action}")));
        button.set_widget_name(&format!("message-{action}"));
        button
    };
    let junk = button("ic-mail-prohibited-symbolic", &t!(UiTbJunk), Command::Junk.name());
    // one button for both, named as the main window's
    junk.set_widget_name("message-junk");
    let groups = [
        vec![
            button("ic-arrow-reply-symbolic", &t!(UiTbReply), Command::Reply.name()),
            button(
                "ic-arrow-reply-all-symbolic",
                &t!(UiTbReplyAll),
                Command::ReplyAll.name(),
            ),
            button("ic-arrow-forward-symbolic", &t!(UiTbForward), Command::Forward.name()),
        ],
        vec![
            button("ic-print-symbolic", &t!(UiTbPrint), Command::Print.name()),
            button("ic-delete-symbolic", &t!(UiTbDelete), Command::Delete.name()),
            button("ic-archive-symbolic", &t!(UiTbArchive), Command::Archive.name()),
            junk.clone(),
        ],
    ];
    for group in groups {
        let linked = gtk::Box::new(gtk::Orientation::Horizontal, 0);
        linked.set_margin_end(6);
        for widget in group {
            linked.append(&widget);
        }
        header.pack_start(&linked);
    }
    // flat as the other buttons of the bar, not a linked pair, which GNOME draws raised
    let steps = gtk::Box::new(gtk::Orientation::Horizontal, 0);
    steps.append(&button(
        "ic-arrow-up-symbolic",
        &t!(UiPreviousTip),
        Command::PreviousMessage.name(),
    ));
    steps.append(&button(
        "ic-arrow-down-symbolic",
        &t!(UiNextTip),
        Command::NextMessage.name(),
    ));
    header.pack_end(&steps);
    (header, junk)
}
