//! The main window: the header bar with the toolbar's buttons, the Find box and the primary menu; the folder tree,
//! the message list and the reading pane between splitters; the status bar. Every string shown was decoded by the
//! core; the message body is the sanitized document the core made, shown in the web view as it is.

use std::cell::{Cell, RefCell};
use std::collections::{HashMap, HashSet};
use std::path::Path;
use std::rc::Rc;

use adw::prelude::*;
use gtk::{gdk, gio, glib};
use pe_core::{DraftKind, Event, MessageView, SignInWith};
use pe_imap::SpecialUse;
use pe_store::Folder;

use crate::app::{run_command, shell, spawn};
use crate::commands::Command;
use crate::folders::{Entry, FolderTree, Handlers};
use crate::messages::{MessageList, parse_payload};
use crate::reader::Reader;
use crate::settings;
use crate::ui::{self, Field, Form, TITLE};

/// What the Find box takes, shown when the mouse rests on it
const FIND_TIP: &str = "Finds words in the subject, the people, the file names and the text of messages.\n\
\"exact phrase\"    -leave out    this OR that\n\
from:ann    to:bob    subject:report    filename:pdf\n\
is:unread    is:read    is:starred    has:attachment\n\
in:inbox    in:sent    in:anywhere    in:<folder name>\n\
before:2025/01/31    after:2025/01/01    older_than:2d    newer_than:1m\n\
larger:5M    smaller:100k";

/// The size the logo of a brand is drawn at
const LOGO_SIZE: i32 = 48;

/// An account as the window knows it
#[derive(Clone)]
struct AccountInfo {
    id: i64,
    name: String,
    email: String,
    label: String,
    sign_in: Option<SignInWith>,
}

pub struct Mailbox {
    window: adw::ApplicationWindow,
    title: adw::WindowTitle,
    pub folders: Rc<FolderTree>,
    pub list: Rc<MessageList>,
    pub reader: Reader,
    pub find: gtk::SearchEntry,
    search_bar: gtk::Box,
    search_summary: gtk::Label,
    empty: gtk::Box,
    empty_title: gtk::Label,
    empty_more: gtk::Label,
    status: gtk::Label,
    outgoing: gtk::Label,
    counts: gtk::Label,
    junk: gtk::Button,
    create_mail: adw::SplitButton,
    send_receive: adw::SplitButton,
    accounts: RefCell<Vec<AccountInfo>>,
    /// The account of each folder, the name of each folder and whether it is the Inbox or a special folder
    folder_accounts: RefCell<HashMap<i64, i64>>,
    folder_names: RefCell<HashMap<i64, (String, bool)>>,
    /// The folders that hold no messages (only other folders), the Drafts and the Junk folders
    unselectable: RefCell<HashSet<i64>>,
    draft_folders: RefCell<HashSet<i64>>,
    junk_folders: RefCell<HashSet<i64>>,
    /// The account whose own item is selected in the tree, 0 when a folder is
    selected_account: Cell<i64>,
    /// The folder shown, 0 for none
    folder: Cell<i64>,
    /// What the Find box searches for, empty when the list is the folder's, and the one folder it names (in:sent)
    find_text: RefCell<String>,
    find_place: RefCell<String>,
    total: Cell<u64>,
    unread: Cell<u64>,
    /// The message shown and its folder (its row's: in a search of every folder not the selected one), 0 for none
    uid: Cell<u64>,
    message_folder: Cell<i64>,
    remote_images: Cell<bool>,
    view: RefCell<Option<MessageView>>,
    /// The view being built for the reading pane, 0 for none
    view_request: Cell<u64>,
    /// The selected draft opens once its source is fetched
    open_when_ready: Cell<bool>,
    /// True while the list is reloaded: its selection changes are the reload's, not the user's
    reloading: Cell<bool>,
    mark_read: RefCell<Option<glib::SourceId>>,
    reload_later: RefCell<Option<glib::SourceId>>,
    unsubscribe_request: Cell<u64>,
    logo_request: Cell<u64>,
}

impl Mailbox {
    pub fn new(application: &adw::Application) -> Rc<Mailbox> {
        let folders = FolderTree::new();
        let list = MessageList::new();
        let reader = Reader::new();
        let find = gtk::SearchEntry::builder()
            .placeholder_text("Search mail")
            .tooltip_text(FIND_TIP)
            .search_delay(250)
            .width_chars(26)
            .build();
        find.set_widget_name("find");
        find.update_property(&[gtk::accessible::Property::Label("Search mail")]);
        let title = adw::WindowTitle::new(TITLE, "");
        let (header, junk, create_mail, send_receive) = header_bar(&title, &find);
        let search_summary = gtk::Label::new(None);
        search_summary.set_xalign(0.0);
        search_summary.set_hexpand(true);
        search_summary.set_ellipsize(gtk::pango::EllipsizeMode::End);
        search_summary.set_widget_name("search-summary");
        let clear = gtk::Button::with_label("Clear search");
        clear.add_css_class("flat");
        clear.set_widget_name("search-clear");
        let search_bar = gtk::Box::new(gtk::Orientation::Horizontal, 8);
        search_bar.add_css_class("info-bar");
        search_bar.append(&gtk::Image::from_icon_name("ic-search-symbolic"));
        search_bar.append(&search_summary);
        search_bar.append(&clear);
        search_bar.set_visible(false);
        let (empty, empty_title, empty_more) = empty_list();
        let scrolled = gtk::ScrolledWindow::builder().child(&list.view).vexpand(true).build();
        let overlay = gtk::Overlay::new();
        overlay.set_child(Some(&scrolled));
        overlay.add_overlay(&empty);
        let list_pane = gtk::Box::new(gtk::Orientation::Vertical, 0);
        list_pane.append(&search_bar);
        list_pane.append(&overlay);
        let settings = &shell().settings;
        let right = gtk::Paned::builder()
            .orientation(gtk::Orientation::Vertical)
            .start_child(&list_pane)
            .end_child(&reader.widget)
            .position(settings.int(settings::LIST_HEIGHT, 260))
            .shrink_start_child(false)
            .shrink_end_child(false)
            .build();
        let tree = gtk::ScrolledWindow::builder()
            .child(&folders.view)
            .hscrollbar_policy(gtk::PolicyType::Never)
            .build();
        let panes = gtk::Paned::builder()
            .orientation(gtk::Orientation::Horizontal)
            .start_child(&tree)
            .end_child(&right)
            .position(settings.int(settings::TREE_WIDTH, 220))
            .shrink_start_child(false)
            .resize_start_child(false)
            .vexpand(true)
            .build();
        right.connect_position_notify(|paned| shell().settings.set_int(settings::LIST_HEIGHT, paned.position()));
        panes.connect_position_notify(|paned| shell().settings.set_int(settings::TREE_WIDTH, paned.position()));
        let (status_bar, status, outgoing, counts) = status_bar();
        let content = gtk::Box::new(gtk::Orientation::Vertical, 0);
        content.append(&panes);
        content.append(&status_bar);
        let toolbar = adw::ToolbarView::new();
        toolbar.add_top_bar(&header);
        toolbar.set_content(Some(&content));
        let window = adw::ApplicationWindow::builder()
            .application(application)
            .title(TITLE)
            .default_width(1100)
            .default_height(760)
            .content(&toolbar)
            .icon_name(crate::APP_ID)
            .build();
        window.set_widget_name("main-window");
        let mailbox = Rc::new(Mailbox {
            window,
            title,
            folders,
            list,
            reader,
            find,
            search_bar,
            search_summary,
            empty,
            empty_title,
            empty_more,
            status,
            outgoing,
            counts,
            junk,
            create_mail,
            send_receive,
            accounts: RefCell::default(),
            folder_accounts: RefCell::default(),
            folder_names: RefCell::default(),
            unselectable: RefCell::default(),
            draft_folders: RefCell::default(),
            junk_folders: RefCell::default(),
            selected_account: Cell::new(0),
            folder: Cell::new(0),
            find_text: RefCell::default(),
            find_place: RefCell::default(),
            total: Cell::new(0),
            unread: Cell::new(0),
            uid: Cell::new(0),
            message_folder: Cell::new(0),
            remote_images: Cell::new(false),
            view: RefCell::new(None),
            view_request: Cell::new(0),
            open_when_ready: Cell::new(false),
            reloading: Cell::new(false),
            mark_read: RefCell::new(None),
            reload_later: RefCell::new(None),
            unsubscribe_request: Cell::new(0),
            logo_request: Cell::new(0),
        });
        mailbox.install_actions(application);
        mailbox.connect(&clear);
        mailbox.reload();
        mailbox.reload_list(false);
        mailbox
    }

    pub fn window(&self) -> &adw::ApplicationWindow {
        &self.window
    }

    // ---- wiring ----

    fn install_actions(self: &Rc<Self>, application: &adw::Application) {
        for &command in Command::ALL {
            let action = if command.is_toggle() {
                gio::SimpleAction::new_stateful(command.name(), None, &shell().notify.get().to_variant())
            } else {
                gio::SimpleAction::new(command.name(), None)
            };
            action.connect_activate(move |_, _| run_command(command));
            self.window.add_action(&action);
            // Delete is the message list's own key (connect_list_keys), not the window's: in a text field it deletes
            // text
            if let Some(accel) = command.accel().filter(|_| command != Command::Delete) {
                application.set_accels_for_action(&format!("win.{}", command.name()), &[accel]);
            }
        }
        // the account menus beside Create Mail and Send/Recv
        let from = gio::SimpleAction::new("new-mail-from", Some(glib::VariantTy::INT64));
        from.connect_activate(|_, account| {
            if let Some(account) = account.and_then(|a| a.get::<i64>()) {
                shell().new_message(account);
            }
        });
        let sync = gio::SimpleAction::new("sync-account", Some(glib::VariantTy::INT64));
        sync.connect_activate(|_, account| {
            if let Some(account) = account.and_then(|a| a.get::<i64>()) {
                let _ = shell().core.sync(account);
            }
        });
        self.window.add_action(&from);
        self.window.add_action(&sync);
        self.install_reader_actions();
    }

    fn install_reader_actions(self: &Rc<Self>) {
        let group = gio::SimpleActionGroup::new();
        let save = gio::SimpleAction::new("save-attachment", Some(glib::VariantTy::UINT32));
        let this = Rc::downgrade(self);
        save.connect_activate(move |_, index| {
            if let (Some(this), Some(index)) = (this.upgrade(), index.and_then(|i| i.get::<u32>())) {
                spawn(async move { this.save_attachment(index as usize).await });
            }
        });
        let all = gio::SimpleAction::new("save-all", None);
        let this = Rc::downgrade(self);
        all.connect_activate(move |_, _| {
            if let Some(this) = this.upgrade() {
                spawn(async move { this.save_all_attachments().await });
            }
        });
        group.add_action(&save);
        group.add_action(&all);
        self.window.insert_action_group("reader", Some(&group));
    }

    fn connect(self: &Rc<Self>, clear: &gtk::Button) {
        let weak = Rc::downgrade(self);
        let on = move |f: fn(&Rc<Mailbox>)| {
            let weak = weak.clone();
            move || {
                if let Some(this) = weak.upgrade() {
                    f(&this);
                }
            }
        };
        let changed = on(|this| this.on_selection_changed());
        self.list.selection.connect_selection_changed(move |_, _, _| changed());
        let activated = on(|this| this.open_selected());
        self.list.view.connect_activate(move |_, _| activated());
        let sorted = on(|this| this.reload_list(true));
        self.list.connect_sort(sorted);
        let searched = on(|this| this.on_find_changed());
        self.find.connect_search_changed(move |_| searched());
        let stopped = on(|this| {
            this.clear_find();
        });
        self.find.connect_stop_search(move |_| stopped());
        let cleared = on(|this| {
            this.clear_find();
        });
        clear.connect_clicked(move |_| cleared());
        let pictures = on(|this| this.load_pictures());
        self.reader.download_pictures.connect_clicked(move |_| pictures());
        let calendar = on(|this| {
            let this = this.clone();
            spawn(async move { this.open_in_calendar().await });
        });
        self.reader.open_calendar.connect_clicked(move |_| calendar());
        let leave = on(|this| {
            let this = this.clone();
            spawn(async move { this.unsubscribe().await });
        });
        self.reader.unsubscribe.connect_activate_link(move |_, _| {
            leave();
            glib::Propagation::Stop
        });
        self.connect_tree();
        // Esc: the search goes first
        let weak = Rc::downgrade(self);
        let shortcuts = gtk::ShortcutController::new();
        shortcuts.add_shortcut(gtk::Shortcut::new(
            gtk::ShortcutTrigger::parse_string("Escape"),
            Some(gtk::CallbackAction::new(move |_, _| {
                if weak.upgrade().is_some_and(|this| this.clear_find()) {
                    glib::Propagation::Stop
                } else {
                    glib::Propagation::Proceed
                }
            })),
        ));
        self.window.add_controller(shortcuts);
        // Delete in the list, as on Windows
        let keys = gtk::EventControllerKey::new();
        keys.connect_key_pressed(|_, key, _, modifiers| {
            if key == gdk::Key::Delete && modifiers.is_empty() {
                run_command(Command::Delete);
                return glib::Propagation::Stop;
            }
            glib::Propagation::Proceed
        });
        self.list.view.add_controller(keys);
        self.window.connect_close_request(|_| {
            shell().close_main();
            glib::Propagation::Stop
        });
    }

    fn connect_tree(self: &Rc<Self>) {
        let selected = Rc::downgrade(self);
        let can = Rc::downgrade(self);
        let dropped = Rc::downgrade(self);
        let menu = Rc::downgrade(self);
        self.folders.set_handlers(Handlers {
            selected: Box::new(move |id| {
                if let Some(this) = selected.upgrade() {
                    this.on_tree_selected(id);
                }
            }),
            can_drop: Box::new(move |payload, to| can.upgrade().is_some_and(|this| this.can_drop(payload, to))),
            dropped: Box::new(move |payload, to, copy| {
                if let Some(this) = dropped.upgrade() {
                    this.drop_message(payload, to, copy);
                }
            }),
            menu: Box::new(move |widget, x, y| {
                if let Some(this) = menu.upgrade() {
                    this.folder_menu(widget, x, y);
                }
            }),
        });
    }

    // ---- the accounts and the folder tree ----

    /// The accounts changed: the tree built again, the folder shown kept when it is still there
    pub fn reload(&self) {
        let core = &shell().core;
        let accounts = core.accounts().unwrap_or_default();
        let names: Vec<&str> = accounts.iter().map(|a| a.settings.name.as_str()).collect();
        let mut infos = Vec::new();
        let mut entries = Vec::new();
        self.folder_accounts.borrow_mut().clear();
        self.folder_names.borrow_mut().clear();
        self.unselectable.borrow_mut().clear();
        self.draft_folders.borrow_mut().clear();
        self.junk_folders.borrow_mut().clear();
        for account in &accounts {
            let s = &account.settings;
            infos.push(AccountInfo {
                id: account.id,
                name: s.name.clone(),
                email: s.email.clone(),
                label: pe_core::account_label(&s.name, &s.email),
                sign_in: SignInWith::of_auth_kind(&s.auth),
            });
            let title = pe_core::account_title(&s.name, &s.email, &names);
            let top = Entry {
                id: -account.id,
                markup: glib::markup_escape_text(&title).to_string(),
                icon: "ic-mailbox-symbolic",
                depth: 0,
            };
            let folders = core.folders(account.id).unwrap_or_default();
            entries.push((top, self.folder_entries(account.id, &folders)));
        }
        *self.accounts.borrow_mut() = infos;
        self.fill_account_menus();
        let shown = if self.folder.get() != 0 {
            self.folder.get()
        } else {
            -self.selected_account.get()
        };
        self.reloading.set(true);
        let kept = self.folders.rebuild(entries);
        if shown != 0 && kept {
            self.folders.select(shown);
        }
        self.reloading.set(false);
        if !kept && self.folder.get() != 0 {
            // the folder is gone
            self.on_folder_selected(0);
        }
        self.show_folder_name();
    }

    /// The entries of an account's folders, and what the window keeps of each
    fn folder_entries(&self, account: i64, folders: &[Folder]) -> Vec<Entry> {
        let infos: Vec<&pe_store::FolderInfo> = folders.iter().map(|f| &f.info).collect();
        let depths = pe_core::tree_depths(&infos);
        let mut entries = Vec::new();
        for (folder, depth) in folders.iter().zip(depths) {
            let special = special_use(folder);
            self.folder_accounts.borrow_mut().insert(folder.id, account);
            self.folder_names.borrow_mut().insert(
                folder.id,
                (
                    pe_core::folder_name(&folder.info),
                    pe_core::is_fixed_folder(&folder.info),
                ),
            );
            if !folder.info.selectable {
                self.unselectable.borrow_mut().insert(folder.id);
            }
            match special {
                Some(SpecialUse::Drafts) => self.draft_folders.borrow_mut().insert(folder.id),
                Some(SpecialUse::Junk) => self.junk_folders.borrow_mut().insert(folder.id),
                _ => false,
            };
            entries.push(Entry {
                id: folder.id,
                markup: folder_markup(folder),
                icon: folder_icon(special),
                depth,
            });
        }
        entries
    }

    /// The labels and bold states of the folders of an account; a folder the tree does not have yet builds it again
    fn update_folders(&self, account: i64) {
        for folder in shell().core.folders(account).unwrap_or_default() {
            if !self.folders.update(folder.id, &folder_markup(&folder)) {
                self.reload();
                return;
            }
        }
    }

    /// The menus beside Create Mail (a message from one account) and Send/Recv (all accounts, or one)
    fn fill_account_menus(&self) {
        let accounts = self.accounts.borrow();
        let from = gio::Menu::new();
        let sync = gio::Menu::new();
        let all = gio::Menu::new();
        all.append(
            Some("Send and Receive All"),
            Some(&format!("win.{}", Command::Sync.name())),
        );
        sync.append_section(None, &all);
        let each = gio::Menu::new();
        for account in accounts.iter() {
            let item = gio::MenuItem::new(Some(&format!("From {}", account.label)), None);
            item.set_action_and_target_value(Some("win.new-mail-from"), Some(&account.id.to_variant()));
            from.append_item(&item);
            let item = gio::MenuItem::new(Some(&account.label), None);
            item.set_action_and_target_value(Some("win.sync-account"), Some(&account.id.to_variant()));
            each.append_item(&item);
        }
        if accounts.is_empty() {
            // an item without an action is shown turned off
            from.append(Some("No accounts yet"), Some("win.none"));
            each.append(Some("No accounts yet"), Some("win.none"));
        }
        sync.append_section(None, &each);
        self.create_mail.set_menu_model(Some(&from));
        self.send_receive.set_menu_model(Some(&sync));
    }

    fn on_tree_selected(&self, id: i64) {
        if self.reloading.get() {
            return;
        }
        // an account has no messages of its own
        self.selected_account.set(if id < 0 { -id } else { 0 });
        if !self.on_folder_selected(id.max(0)) {
            self.show_folder_name();
        }
        self.update_junk_button();
    }

    /// Another folder shown; false when it was already the one shown
    fn on_folder_selected(&self, folder: i64) -> bool {
        if folder == self.folder.get() {
            return false;
        }
        // the message of the folder before is not this folder's, nor is the search
        self.folder.set(folder);
        self.reset_find();
        self.clear_reader(false);
        self.reload_list(false);
        self.show_folder_name();
        true
    }

    pub fn account_name(&self, account: i64) -> String {
        self.account(account).map_or_else(|| "the account".into(), |a| a.name)
    }

    pub fn account_email(&self, account: i64) -> String {
        self.account(account).map(|a| a.email).unwrap_or_default()
    }

    /// What the account signs in with through the browser; None for a password
    pub fn sign_in(&self, account: i64) -> Option<SignInWith> {
        self.account(account).and_then(|a| a.sign_in)
    }

    fn account(&self, account: i64) -> Option<AccountInfo> {
        self.accounts.borrow().iter().find(|a| a.id == account).cloned()
    }

    /// The account of the message shown (in a search of every folder, not the selected folder's), else of the
    /// folder, else the account selected or the first one; 0 when there is none
    pub fn current_account(&self) -> i64 {
        let folder = if self.message_folder.get() != 0 {
            self.message_folder.get()
        } else {
            self.folder.get()
        };
        if let Some(account) = self.folder_accounts.borrow().get(&folder) {
            return *account;
        }
        if self.selected_account.get() != 0 {
            return self.selected_account.get();
        }
        self.accounts.borrow().first().map_or(0, |a| a.id)
    }

    /// The folder of a row in a list of several folders: its name, with its account's when there are several
    pub fn row_folder(&self, folder: i64) -> String {
        let mut text = self
            .folder_names
            .borrow()
            .get(&folder)
            .map(|(name, _)| name.clone())
            .unwrap_or_default();
        if self.accounts.borrow().len() > 1
            && let Some(account) = self.folder_accounts.borrow().get(&folder)
        {
            text.push_str(&format!(" ({})", self.account_name(*account)));
        }
        text
    }

    // ---- the message list ----

    fn searching(&self) -> bool {
        !self.find_text.borrow().is_empty()
    }

    /// What the list shows: words typed search every folder of every account (in: narrows that); without, the
    /// folder
    fn search(&self) -> pe_core::Search {
        let searching = self.searching();
        pe_core::Search {
            folder: (!searching).then_some(self.folder.get()),
            show: pe_core::Show::All,
            text: self.find_text.borrow().clone(),
        }
    }

    fn reload_list(&self, keep_selection: bool) {
        let core = &shell().core;
        let search = self.search();
        let searching = self.searching();
        let active = searching || self.folder.get() != 0;
        // the counts of the folder come from its indexes; a search counts what it finds
        let (total, unread) = if searching {
            core.count_search(&search).unwrap_or((0, 0))
        } else if self.folder.get() != 0 {
            core.folder(self.folder.get())
                .map(|f| (f.total, f.unread))
                .unwrap_or((0, 0))
        } else {
            (0, 0)
        };
        self.total.set(total);
        self.unread.set(unread);
        self.list.show_folder_column(searching);
        // the selection follows the message to where it is now, without a flicker of the reading pane
        let index = if keep_selection && self.uid.get() != 0 {
            core.search_index(&search, self.list.sort(), self.message_folder.get(), self.uid.get())
                .ok()
                .flatten()
        } else {
            None
        };
        self.reloading.set(true);
        self.list.reset(search, total, active, index);
        self.reloading.set(false);
        self.show_empty_list();
        self.on_selection_changed();
    }

    /// In the middle of an empty list: why there is nothing, and what to do about it
    fn show_empty_list(&self) {
        let (title, more) = if self.searching() {
            let place = self.find_place.borrow();
            let mut more = format!(
                "The search looks at the subject, the people, the file names and the text of the messages {}. Check \
                 the spelling, or try fewer words.",
                if place.is_empty() {
                    "in every folder".into()
                } else {
                    format!("in {place}")
                }
            );
            let left = shell().core.unindexed_count().unwrap_or(0);
            if left > 0 {
                let verb = if left == 1 { "message is" } else { "messages are" };
                more.push_str(&format!(
                    "\n\nThe text of {left} {verb} still being indexed, so more may be found soon."
                ));
            }
            (
                format!("No messages match \u{201C}{}\u{201D}.", self.find_text.borrow()),
                more,
            )
        } else if self.folder.get() != 0 {
            ("There are no items in this view.".into(), String::new())
        } else if self.selected_account.get() != 0 {
            ("Choose a folder to see its messages.".into(), String::new())
        } else {
            (String::new(), String::new())
        };
        self.empty_title.set_text(&title);
        self.empty_more.set_text(&more);
        self.empty_more.set_visible(!more.is_empty());
        self.empty.set_visible(self.total.get() == 0 && !title.is_empty());
    }

    fn on_selection_changed(&self) {
        if self.reloading.get() {
            return;
        }
        let selected = self.list.selected();
        let (folder, uid) = selected.as_ref().map_or((0, 0), |(_, m)| (m.folder_id, m.info.uid));
        if uid == self.uid.get() && folder == self.message_folder.get() {
            return;
        }
        self.clear_reader(uid != 0);
        self.update_junk_button();
        if uid == 0 {
            return;
        }
        self.uid.set(uid);
        self.message_folder.set(folder);
        self.reader.loading();
        // MessageReady follows, right away when the message is cached
        let _ = shell().core.open_message(folder, uid);
    }

    /// The reading pane emptied; with "There is no message selected." in it unless a message is `loading`
    fn clear_reader(&self, loading: bool) {
        let core = &shell().core;
        if self.view_request.get() != 0 {
            core.message_view_cancel(self.view_request.replace(0));
        }
        self.uid.set(0);
        self.message_folder.set(0);
        self.open_when_ready.set(false);
        self.remote_images.set(false);
        self.view.borrow_mut().take();
        if let Some(timer) = self.mark_read.borrow_mut().take() {
            timer.remove();
        }
        self.logo_request.set(0);
        self.reader.clear(loading);
    }

    /// The view of the selected message asked for, built on a worker; [`Mailbox::show_view`] shows it when it comes
    fn show_message_view(&self) {
        // fetched now: a draft that was opened before opens
        if self.open_when_ready.replace(false) {
            self.open_selected();
        }
        let core = &shell().core;
        if self.view_request.get() != 0 {
            core.message_view_cancel(self.view_request.get());
        }
        let request = core
            .message_view_start(self.message_folder.get(), self.uid.get(), self.remote_images.get())
            .unwrap_or(0);
        self.view_request.set(request);
        if request == 0 {
            self.reader.failed();
        }
    }

    fn show_view(self: &Rc<Self>) {
        let core = &shell().core;
        let view = core.message_view_result(self.view_request.replace(0));
        let Some(view) = view else {
            self.reader.failed();
            return;
        };
        self.reader.show(&view, self.remote_images.get());
        self.reader.hide_logo();
        if view.has_logo {
            let request = core
                .logo_start(self.message_folder.get(), self.uid.get(), LOGO_SIZE as u32)
                .unwrap_or(0);
            self.logo_request.set(request);
        }
        *self.view.borrow_mut() = Some(view);
        // read after a moment on screen, not while the user moves through the list
        if let Some(timer) = self.mark_read.borrow_mut().take() {
            timer.remove();
        }
        let this = Rc::downgrade(self);
        let timer = glib::timeout_add_local_once(std::time::Duration::from_secs(1), move || {
            let Some(this) = this.upgrade() else { return };
            this.mark_read.borrow_mut().take();
            if let Some((_, message)) = this.list.selected()
                && message.info.uid == this.uid.get()
                && !message.info.seen()
            {
                this.mark_selected(true);
            }
        });
        *self.mark_read.borrow_mut() = Some(timer);
    }

    /// The selected message of a Drafts folder in a compose window, to go on writing it (double-click or Enter);
    /// once it is fetched when it is not yet
    pub fn open_selected(&self) {
        let (folder, uid) = (self.message_folder.get(), self.uid.get());
        if uid == 0 || !self.draft_folders.borrow().contains(&folder) {
            return;
        }
        match shell().core.reopen_draft(folder, uid) {
            Ok(Some(draft)) => crate::compose::open(self.current_account(), Some(draft)),
            // not fetched yet: MessageReady follows
            _ => self.open_when_ready.set(true),
        }
    }

    /// A reply, a reply to all or a forward of the message shown, None when no message is shown
    pub fn draft_of_shown(&self, kind: DraftKind) -> Option<pe_core::Draft> {
        if self.uid.get() == 0 || self.view.borrow().is_none() {
            return None;
        }
        shell()
            .core
            .draft(self.message_folder.get(), self.uid.get(), kind)
            .ok()
            .flatten()
    }

    /// The message `uid` of `folder` shown: its folder chosen in the tree (which ends a search), the message
    /// selected in the list
    pub fn show_message(&self, folder: i64, uid: u64) {
        if !self.folders.select(folder) || self.folder.get() != folder {
            return;
        }
        let core = &shell().core;
        if let Ok(Some(index)) = core.search_index(&self.search(), self.list.sort(), folder, uid)
            && let Ok(index) = u32::try_from(index)
        {
            self.list.select(index);
            self.list.view.grab_focus();
        }
    }

    // ---- the Find box ----

    fn on_find_changed(&self) {
        // what only has spaces finds everything, as the core reads it
        let text = self.find.text().trim().to_string();
        if text == *self.find_text.borrow() {
            return;
        }
        *self.find_place.borrow_mut() = pe_core::Core::search_place(&text).unwrap_or_default();
        *self.find_text.borrow_mut() = text;
        self.reload_list(true);
        self.show_folder_name();
    }

    pub fn focus_find(&self) {
        self.find.grab_focus();
        self.find.select_region(0, -1);
    }

    /// The Find box emptied and the search dropped, without the list following it (the caller reloads)
    fn reset_find(&self) {
        self.find_text.borrow_mut().clear();
        self.find_place.borrow_mut().clear();
        if !self.find.text().is_empty() {
            self.find.set_text("");
        }
    }

    /// Esc, Clear search: the folder again; false when there was no search
    pub fn clear_find(&self) -> bool {
        if !self.searching() && self.find.text().is_empty() {
            return false;
        }
        self.reset_find();
        self.reload_list(true);
        self.show_folder_name();
        self.show_counts();
        self.list.view.grab_focus();
        true
    }

    /// The name of the selected folder (or account) for the title; while searching, where it looks: "All folders",
    /// or the one folder named (in:sent)
    pub fn selected_name(&self) -> String {
        if self.searching() {
            let place = self.find_place.borrow();
            return if place.is_empty() {
                "All folders".into()
            } else {
                place.clone()
            };
        }
        if let Some((name, _)) = self.folder_names.borrow().get(&self.folder.get()) {
            return name.clone();
        }
        self.account(self.selected_account.get())
            .map(|a| a.name)
            .unwrap_or_default()
    }

    /// The selected folder in the header bar and the title: "Inbox - Inbox Classic"; the search bar
    pub fn show_folder_name(&self) {
        let name = self.selected_name();
        self.title.set_title(if name.is_empty() { TITLE } else { &name });
        self.window.set_title(Some(&if name.is_empty() {
            TITLE.to_string()
        } else {
            format!("{name} - {TITLE}")
        }));
        self.update_search_bar();
    }

    /// The bar over the list while searching: what was found for which words (and how many messages the search does
    /// not know the text of yet)
    fn update_search_bar(&self) {
        if !self.searching() {
            self.search_bar.set_visible(false);
            return;
        }
        let total = self.total.get();
        let mut summary = match total {
            0 => "No results".to_string(),
            1 => "1 result".to_string(),
            n => format!("{n} results"),
        };
        let place = self.find_place.borrow();
        summary.push_str(&format!(
            " for \u{201C}{}\u{201D} {}",
            self.find_text.borrow(),
            if place.is_empty() {
                "in all folders".into()
            } else {
                format!("in {place}")
            }
        ));
        let left = shell().core.unindexed_count().unwrap_or(0);
        if left > 0 {
            summary.push_str(&format!(
                "  \u{00B7}  still indexing the text of {left} {}",
                if left == 1 { "message" } else { "messages" }
            ));
        }
        self.search_summary.set_text(&summary);
        self.search_bar.set_visible(true);
    }

    // ---- the status bar ----

    pub fn set_status(&self, text: &str) {
        self.status.set_text(text);
    }

    pub fn set_outgoing(&self, text: &str) {
        self.outgoing.set_text(text);
        // the whole text as the tip, as a long subject is cut short
        self.outgoing.set_tooltip_text(Some(text));
    }

    /// "12 message(s), 3 unread" for the status bar; the search bar says how many a search found
    pub fn show_counts(&self) {
        let (total, unread) = (self.total.get(), self.unread.get());
        let text = if self.searching() && total == 0 {
            "No messages found".to_string()
        } else if self.searching() {
            format!("{total} found, {unread} unread")
        } else if self.folder.get() == 0 {
            String::new()
        } else {
            format!("{total} message(s), {unread} unread")
        };
        self.counts.set_text(&text);
        self.update_search_bar();
    }

    #[cfg(feature = "e2e")]
    pub fn status_texts(&self) -> (String, String, String) {
        (
            self.status.text().into(),
            self.outgoing.text().into(),
            self.counts.text().into(),
        )
    }

    #[cfg(feature = "e2e")]
    pub fn search_summary(&self) -> Option<String> {
        self.search_bar.is_visible().then(|| self.search_summary.text().into())
    }

    /// The header bar's Junk button, Not Junk for a message in a Junk folder
    fn update_junk_button(&self) {
        let in_junk = self.in_junk();
        let (command, label) = if in_junk {
            (Command::NotJunk, "Not Junk")
        } else {
            (Command::Junk, "Junk")
        };
        self.junk.set_action_name(Some(&format!("win.{}", command.name())));
        self.junk.set_icon_name(if in_junk {
            "ic-mail-checkmark-symbolic"
        } else {
            "ic-mail-prohibited-symbolic"
        });
        self.junk.set_tooltip_text(Some(label));
    }

    /// Whether the message shown, or else the folder, is in a Junk folder
    pub fn in_junk(&self) -> bool {
        let folder = if self.uid.get() != 0 {
            self.message_folder.get()
        } else {
            self.folder.get()
        };
        self.junk_folders.borrow().contains(&folder)
    }

    // ---- the core's events ----

    pub fn on_event(self: &Rc<Self>, event: &Event) {
        match event {
            Event::FoldersChanged { .. } => self.reload(),
            Event::FolderChanged { account, folder } => {
                self.update_folders(*account);
                if *folder == self.folder.get() && !self.searching() {
                    self.reload_list(true);
                } else if self.searching() {
                    // a list of several folders follows their changes once a sync of many of them is done
                    self.reload_soon();
                }
            }
            Event::MessageReady { folder, uid } => {
                if *folder == self.message_folder.get() && *uid == self.uid.get() {
                    self.show_message_view();
                }
            }
            Event::ViewReady { request } => {
                // a view for a message that is no longer selected was cancelled, its event is not this one
                if self.view_request.get() != 0 && *request == self.view_request.get() {
                    self.show_view();
                }
            }
            Event::LogoReady { request } => {
                if self.logo_request.get() != 0 && *request == self.logo_request.get() {
                    self.logo_request.set(0);
                    self.reader.show_logo(shell().core.logo_result(*request), LOGO_SIZE);
                }
            }
            Event::SyncFinished { .. } => self.show_folder_name(),
            _ => {}
        }
    }

    fn reload_soon(self: &Rc<Self>) {
        if let Some(timer) = self.reload_later.borrow_mut().take() {
            timer.remove();
        }
        let this = Rc::downgrade(self);
        let timer = glib::timeout_add_local_once(std::time::Duration::from_millis(300), move || {
            if let Some(this) = this.upgrade() {
                this.reload_later.borrow_mut().take();
                this.reload_list(true);
                this.show_folder_name();
                this.show_counts();
            }
        });
        *self.reload_later.borrow_mut() = Some(timer);
    }

    // ---- commands on the message ----

    pub fn mark_selected(&self, seen: bool) {
        if self.uid.get() != 0 {
            let _ = shell().core.set_seen(self.message_folder.get(), self.uid.get(), seen);
        }
    }

    /// Every message of the selected folder read; nothing while searching
    pub fn mark_all_read(&self) {
        if self.folder.get() != 0 && !self.searching() {
            let _ = shell().core.mark_all_read(self.folder.get());
        }
    }

    pub fn load_pictures(&self) {
        if self.uid.get() != 0 && self.view.borrow().is_some() && !self.remote_images.get() {
            self.remote_images.set(true);
            self.show_message_view();
        }
    }

    pub fn flag_selected(&self) {
        if let Some((_, message)) = self.list.selected() {
            let _ = shell()
                .core
                .set_flagged(message.folder_id, message.info.uid, !message.info.flagged());
        }
    }

    /// The selected message junk ($Junk, into the Junk folder) or not junk ($NotJunk, into the Inbox)
    pub async fn mark_junk(&self, junk: bool) {
        let Some((_, message)) = self.list.selected() else {
            return;
        };
        if shell()
            .core
            .mark_junk(message.folder_id, message.info.uid, junk)
            .is_err()
        {
            let text = if junk {
                "This account has no Junk E-mail folder to move the message to."
            } else {
                "The message could not be moved to the Inbox."
            };
            ui::alert(&self.window, TITLE, text).await;
        }
    }

    /// After a message left the list: the one that took its place selected, or the last one
    fn select_after_removal(&self, index: u32) {
        self.reload_list(false);
        let rows = self.list.rows();
        if rows > 0 {
            self.list.select(index.min(rows - 1));
        }
    }

    /// The selected message into Deleted Items (for good when it is in there, asked first)
    pub async fn delete_selected(&self) {
        let Some((index, message)) = self.list.selected() else {
            return;
        };
        let core = &shell().core;
        let (folder, uid) = (message.folder_id, message.info.uid);
        if core.deletes_for_good(folder).unwrap_or(false)
            && !ui::confirm(
                &self.window,
                TITLE,
                "This message will be deleted for good. Delete it?",
                true,
            )
            .await
        {
            return;
        }
        if core.delete_message(folder, uid).is_ok() {
            self.select_after_removal(index);
        }
    }

    /// Asks for another folder of the message's account and moves it there
    pub async fn move_selected(&self) {
        let Some((index, message)) = self.list.selected() else {
            return;
        };
        let from = message.folder_id;
        let account = self
            .folder_accounts
            .borrow()
            .get(&from)
            .copied()
            .unwrap_or_else(|| self.current_account());
        let mut ids = Vec::new();
        let mut choices = Vec::new();
        for folder in shell().core.folders(account).unwrap_or_default() {
            if folder.info.selectable && folder.id != from {
                ids.push(folder.id);
                // a special folder by its usual name, the others by their whole path: two folders 2024 in Work and
                // in Personal are not the same
                choices.push(if folder.info.special_use.is_some() {
                    pe_core::folder_name(&folder.info)
                } else {
                    folder.info.path.clone()
                });
            }
        }
        if ids.is_empty() {
            return;
        }
        let form = Form::new(
            &self.window,
            "Move",
            "Move the selected message to the folder:",
            vec![Field::choice("Folder:", choices, 0)],
            "OK",
            0,
        );
        form.widget().set_widget_name("move-dialog");
        if !form.run().await {
            return;
        }
        let chosen = form.chosen(0);
        form.close();
        if let Some(to) = chosen.and_then(|i| ids.get(i))
            && shell().core.move_message(from, message.info.uid, *to).is_ok()
        {
            self.select_after_removal(index);
        }
    }

    pub fn can_drop(&self, payload: &str, to: i64) -> bool {
        let Some((from, _)) = parse_payload(payload) else {
            return false;
        };
        let accounts = self.folder_accounts.borrow();
        // an account's own item, the folder the message is in, one of another account, or one that holds no
        // messages: not there
        to > 0
            && to != from
            && !self.unselectable.borrow().contains(&to)
            && accounts.get(&from).is_some()
            && accounts.get(&from) == accounts.get(&to)
    }

    /// A message dropped onto a folder: moved, or copied with Ctrl; a move selects the message after it, as Move to
    /// Folder does
    pub fn drop_message(&self, payload: &str, to: i64, copy: bool) {
        let Some((folder, uid)) = parse_payload(payload) else {
            return;
        };
        let core = &shell().core;
        if copy {
            let _ = core.copy_message(folder, uid, to);
            return;
        }
        let shown = folder == self.message_folder.get() && uid == self.uid.get();
        let index = self.list.selected().map(|(index, _)| index);
        if core.move_message(folder, uid, to).is_ok()
            && shown
            && let Some(index) = index
        {
            self.select_after_removal(index);
        }
    }

    // ---- folders ----

    /// The right-click menu of a folder: Mark All Read first, as Outlook Express has it, for a folder with unread
    /// messages; New Folder, Rename and Delete for a folder that is not special
    fn folder_menu(self: &Rc<Self>, widget: &gtk::Widget, x: f64, y: f64) {
        let folder = self.folder.get();
        let some_unread = folder != 0 && shell().core.folder(folder).is_ok_and(|f| f.unread > 0);
        let changeable = folder != 0 && self.folder_names.borrow().get(&folder).is_some_and(|(_, fixed)| !fixed);
        let group = gio::SimpleActionGroup::new();
        let add = |name: &str, enabled: bool, command: Command| {
            let action = gio::SimpleAction::new(name, None);
            action.set_enabled(enabled);
            action.connect_activate(move |_, _| run_command(command));
            group.add_action(&action);
        };
        add("mark-all-read", some_unread, Command::MarkAllRead);
        add("new", true, Command::NewFolder);
        add("rename", changeable, Command::RenameFolder);
        add("delete", changeable, Command::DeleteFolder);
        let menu = gio::Menu::new();
        let first = gio::Menu::new();
        first.append(Some("Mark All Read"), Some("folder.mark-all-read"));
        menu.append_section(None, &first);
        let rest = gio::Menu::new();
        rest.append(Some("New Folder..."), Some("folder.new"));
        rest.append(Some("Rename..."), Some("folder.rename"));
        rest.append(Some("Delete"), Some("folder.delete"));
        menu.append_section(None, &rest);
        widget.insert_action_group("folder", Some(&group));
        let popover = gtk::PopoverMenu::from_model(Some(&menu));
        popover.set_parent(widget);
        popover.set_has_arrow(false);
        popover.set_pointing_to(Some(&gdk::Rectangle::new(x as i32, y as i32, 1, 1)));
        popover.connect_closed(|popover| {
            let popover = popover.clone();
            glib::idle_add_local_once(move || popover.unparent());
        });
        popover.popup();
    }

    async fn ask_folder_name(&self, title: &str, intro: &str, name: &str) -> Option<String> {
        let form = Form::new(
            &self.window,
            title,
            intro,
            vec![Field::text("Folder name:", name)],
            "OK",
            0,
        );
        form.widget().set_widget_name("folder-name-dialog");
        let ok = form.run().await;
        let value = form.value(0);
        form.close();
        (ok && !value.is_empty()).then_some(value)
    }

    /// A folder in the selected one, or at the top of the selected account
    pub async fn new_folder(&self) {
        let account = self.current_account();
        if account == 0 {
            return;
        }
        let folder = self.folder.get();
        let where_ = if folder != 0 {
            "The new folder goes in the selected folder."
        } else {
            "The new folder goes at the top of the account."
        };
        let Some(name) = self.ask_folder_name("New Folder", where_, "").await else {
            return;
        };
        if let Err(reason) = shell()
            .core
            .create_folder(account, (folder != 0).then_some(folder), &name)
        {
            ui::alert(&self.window, TITLE, &reason.to_string()).await;
        }
    }

    pub async fn rename_folder(&self) {
        let folder = self.folder.get();
        if folder == 0 {
            return;
        }
        let current = self
            .folder_names
            .borrow()
            .get(&folder)
            .map(|(n, _)| n.clone())
            .unwrap_or_default();
        let intro = format!("The new name of the folder {current}.");
        let Some(name) = self.ask_folder_name("Rename Folder", &intro, &current).await else {
            return;
        };
        if name == current {
            return;
        }
        if let Err(reason) = shell().core.rename_folder(folder, &name) {
            ui::alert(&self.window, TITLE, &reason.to_string()).await;
        }
    }

    pub async fn delete_folder(&self) {
        let folder = self.folder.get();
        let Some((name, _)) = self.folder_names.borrow().get(&folder).cloned() else {
            return;
        };
        let question = format!(
            "Delete the folder \u{201C}{name}\u{201D} with its messages and the folders in it? It is deleted on the \
             server too."
        );
        if !ui::confirm(&self.window, TITLE, &question, true).await {
            return;
        }
        if let Err(reason) = shell().core.delete_folder(folder) {
            ui::alert(&self.window, TITLE, &reason.to_string()).await;
        }
    }

    // ---- files and printing ----

    /// File > Save As: the message shown, as an .eml
    pub async fn save_shown_as(&self) {
        if self.uid.get() == 0 {
            return;
        }
        let window = self.window.clone().upcast::<gtk::Window>();
        let Ok(Some((name, data))) = shell().core.message_source(self.message_folder.get(), self.uid.get()) else {
            ui::alert(&window, TITLE, "The message is not downloaded yet.").await;
            return;
        };
        let patterns = Some(("Mail messages", &["*.eml"][..]));
        let Some(path) = ui::save_file(&window, "Save Message As", &name, patterns).await else {
            return;
        };
        if std::fs::write(&path, data).is_err() {
            ui::alert(&window, TITLE, "The message could not be saved.").await;
        }
    }

    /// File > Properties: the Internet headers of the message shown
    pub async fn show_properties(&self) {
        if self.uid.get() == 0 {
            ui::alert(&self.window, TITLE, "Select a message first.").await;
            return;
        }
        let Ok(Some(headers)) = shell().core.message_headers(self.message_folder.get(), self.uid.get()) else {
            ui::alert(&self.window, TITLE, "The message is not downloaded yet.").await;
            return;
        };
        let subject = self
            .view
            .borrow()
            .as_ref()
            .map(|v| v.subject.clone())
            .unwrap_or_default();
        let title = if subject.is_empty() {
            "Properties".into()
        } else {
            format!("{subject} Properties")
        };
        let dialog = ui::text_dialog(
            &self.window,
            &title,
            "Internet headers for this message:",
            &headers.replace("\r\n", "\n"),
        );
        dialog.set_widget_name("properties-dialog");
    }

    /// File > Print: the message as it is shown, with the pictures the user allowed, through the print dialog
    pub fn print_shown(&self) {
        if self.uid.get() == 0 || self.view.borrow().is_none() {
            return;
        }
        let operation = webkit::PrintOperation::new(&self.reader.preview.view);
        operation.run_dialog(Some(&self.window));
    }

    /// File > Import Messages: .eml files into the selected folder
    pub async fn import(&self) {
        let window = self.window.clone().upcast::<gtk::Window>();
        if self.folder.get() == 0 {
            ui::alert(
                &window,
                "Import Messages",
                "Choose the folder to put the messages in first.",
            )
            .await;
            return;
        }
        let patterns = Some(("Mail messages", &["*.eml"][..]));
        let files = ui::open_files(&window, "Import Messages", patterns).await;
        self.import_files(&files).await;
    }

    async fn import_files(&self, files: &[std::path::PathBuf]) {
        let mut problems = String::new();
        for file in files {
            if let Err(reason) = shell().core.import_message(self.folder.get(), file) {
                problems.push_str(&format!("{}: {reason}\n", file.display()));
            }
        }
        if !problems.is_empty() {
            ui::alert(
                &self.window,
                "Import Messages",
                &format!("These were not imported:\n\n{problems}"),
            )
            .await;
        }
    }

    /// A message file opened with the app (from the file manager): into the selected folder, asked first
    pub async fn import_file(&self, file: &Path) {
        let folder = self.folder.get();
        let Some((folder_name, _)) = self.folder_names.borrow().get(&folder).cloned() else {
            ui::alert(
                &self.window,
                "Import Messages",
                "Choose the folder to put the messages in first.",
            )
            .await;
            return;
        };
        let name = file
            .file_name()
            .map(|n| n.to_string_lossy().into_owned())
            .unwrap_or_default();
        let question = format!("Put the message {name} into the folder {folder_name}?");
        if ui::confirm(&self.window, "Import Messages", &question, false).await {
            self.import_files(&[file.to_path_buf()]).await;
        }
    }

    async fn save_attachment(&self, index: usize) {
        let window = self.window.clone().upcast::<gtk::Window>();
        let Ok(Some((name, data))) = shell()
            .core
            .attachment(self.message_folder.get(), self.uid.get(), index)
        else {
            ui::alert(&window, TITLE, "The attachment could not be read.").await;
            return;
        };
        let Some(path) = ui::save_file(&window, "Save Attachment As", &name, None).await else {
            return;
        };
        if std::fs::write(&path, data).is_err() {
            ui::alert(&window, TITLE, "The attachment could not be saved.").await;
        }
    }

    /// Every file of the message into a folder; the core saves them all from one reading of the message, a file
    /// already there kept and the new one numbered
    async fn save_all_attachments(&self) {
        let window = self.window.clone().upcast::<gtk::Window>();
        let Some(dir) = ui::choose_folder(&window, "Save Attachments").await else {
            return;
        };
        match shell()
            .core
            .save_attachments(self.message_folder.get(), self.uid.get(), &dir)
        {
            Ok(Some((saved, total))) if saved < total => {
                let text = format!("{} of the {total} files could not be saved.", total - saved);
                ui::alert(&window, TITLE, &text).await;
            }
            Ok(Some(_)) => {}
            _ => ui::alert(&window, TITLE, "The message is not downloaded yet.").await,
        }
    }

    /// The calendar part as a file of its own (the core writes it, and only it), for the calendar program
    async fn open_in_calendar(&self) {
        let dir = glib::tmp_dir().join("InboxClassic").join("Invitations");
        let Ok(Some(path)) = shell()
            .core
            .invitation_file(self.message_folder.get(), self.uid.get(), &dir)
        else {
            ui::alert(&self.window, TITLE, "The invitation could not be read.").await;
            return;
        };
        let launcher = gtk::FileLauncher::new(Some(&gio::File::for_path(&path)));
        if launcher.launch_future(Some(&self.window)).await.is_err() {
            let text = "No calendar program on this computer opens invitations (.ics files).";
            ui::alert(&self.window, TITLE, text).await;
        }
    }

    // ---- unsubscribing ----

    /// The Unsubscribe link of the message shown, after asking
    async fn unsubscribe(&self) {
        use pe_core::unsubscribe::Unsubscribe;
        let Some(how) = self.view.borrow().as_ref().and_then(|v| v.unsubscribe.clone()) else {
            return;
        };
        let target = how.target();
        let ok = [("cancel", "Cancel"), ("ok", "OK")];
        match how {
            Unsubscribe::OneClick { .. } => {
                let question = format!(
                    "Leave this mailing list?\n\nInbox Classic asks {target} to stop sending it to you. No page opens \
                     and no message is sent."
                );
                if !ui::confirm(&self.window, "Unsubscribe", &question, false).await {
                    return;
                }
                let request = shell()
                    .core
                    .unsubscribe(self.message_folder.get(), self.uid.get())
                    .unwrap_or(0);
                self.unsubscribe_request.set(request);
                self.set_status(&if request != 0 {
                    format!("Unsubscribing from {target}...")
                } else {
                    "This message can not unsubscribe you.".into()
                });
            }
            Unsubscribe::Mail { link } => {
                let question = format!(
                    "Leave this mailing list?\n\nThe list wants a message to {target}. Inbox Classic writes it for you; \
                     send it to unsubscribe."
                );
                if ui::ask(&self.window, "Unsubscribe", &question, &ok, "ok", "cancel", None).await == "ok" {
                    shell().open_mailto(&link).await;
                }
            }
            Unsubscribe::Web { url } => {
                let question =
                    format!("Leave this mailing list?\n\nThe list's page for it opens in your browser ({target}).");
                if ui::ask(&self.window, "Unsubscribe", &question, &ok, "ok", "cancel", None).await == "ok" {
                    ui::open_externally(&url, Some(self.window.upcast_ref()));
                }
            }
        }
    }

    /// The one-click unsubscribe `request` done, or not for `problem`: what the status bar says, empty for another
    pub fn unsubscribed(&self, request: u64, problem: Option<&str>) -> String {
        if request != self.unsubscribe_request.get() {
            return String::new();
        }
        self.unsubscribe_request.set(0);
        match problem {
            None => "Unsubscribed. The list says it will stop sending this mail.".into(),
            Some(problem) => format!("Could not unsubscribe: {problem}"),
        }
    }
}

fn special_use(folder: &Folder) -> Option<SpecialUse> {
    folder.info.special_use.as_deref().and_then(SpecialUse::from_flag)
}

/// The icon of a folder in the tree, by what it is for
fn folder_icon(special: Option<SpecialUse>) -> &'static str {
    match special {
        Some(SpecialUse::Inbox) => "ic-mail-inbox-symbolic",
        Some(SpecialUse::Sent) => "ic-send-symbolic",
        Some(SpecialUse::Drafts) => "ic-drafts-symbolic",
        Some(SpecialUse::Trash) => "ic-delete-symbolic",
        Some(SpecialUse::Junk) => "ic-mail-prohibited-symbolic",
        Some(SpecialUse::Archive) => "ic-archive-symbolic",
        Some(SpecialUse::Flagged) => "ic-flag-symbolic",
        Some(SpecialUse::All) => "ic-mail-multiple-symbolic",
        None => "ic-folder-symbolic",
    }
}

/// A folder's label: its name, with the unread count, bold, when it has unread messages
fn folder_markup(folder: &Folder) -> String {
    let name = glib::markup_escape_text(&pe_core::folder_name(&folder.info));
    if folder.unread > 0 {
        format!("<b>{name} ({})</b>", folder.unread)
    } else {
        name.to_string()
    }
}

/// The header bar: the toolbar's buttons in groups as Outlook Express has them (writing, answering, the message,
/// getting mail, read state), the folder's name, the Find box and the primary menu
fn header_bar(
    title: &adw::WindowTitle,
    find: &gtk::SearchEntry,
) -> (adw::HeaderBar, gtk::Button, adw::SplitButton, adw::SplitButton) {
    let header = adw::HeaderBar::new();
    header.set_title_widget(Some(title));
    let action = |command: Command| format!("win.{}", command.name());
    let button = |icon: &str, tooltip: &str, command: Command| {
        let button = ui::icon_button(icon, tooltip);
        button.set_action_name(Some(&action(command)));
        button.set_widget_name(command.name());
        button
    };
    let create_mail = adw::SplitButton::builder()
        .icon_name("ic-mail-add-symbolic")
        .tooltip_text("Create Mail")
        .dropdown_tooltip("A message from one account")
        .action_name(action(Command::NewMail))
        .build();
    let send_receive = adw::SplitButton::builder()
        .icon_name("ic-arrow-sync-symbolic")
        .tooltip_text("Send/Recv")
        .dropdown_tooltip("Send and receive one account")
        .action_name(action(Command::Sync))
        .build();
    let junk = button("ic-mail-prohibited-symbolic", "Junk", Command::Junk);
    junk.set_widget_name("junk");
    let groups: Vec<Vec<gtk::Widget>> = vec![
        vec![create_mail.clone().upcast()],
        vec![
            button("ic-arrow-reply-symbolic", "Reply", Command::Reply).upcast(),
            button("ic-arrow-reply-all-symbolic", "Reply All", Command::ReplyAll).upcast(),
            button("ic-arrow-forward-symbolic", "Forward", Command::Forward).upcast(),
        ],
        vec![
            button("ic-print-symbolic", "Print", Command::Print).upcast(),
            button("ic-delete-symbolic", "Delete", Command::Delete).upcast(),
            junk.clone().upcast(),
        ],
        vec![send_receive.clone().upcast()],
        vec![
            button("ic-mail-read-symbolic", "Mark Read", Command::MarkRead).upcast(),
            button("ic-mail-unread-symbolic", "Mark Unread", Command::MarkUnread).upcast(),
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
    let menu = gtk::MenuButton::builder()
        .icon_name("open-menu-symbolic")
        .menu_model(&primary_menu())
        .primary(true)
        .tooltip_text("Main Menu")
        .build();
    menu.set_widget_name("primary-menu");
    header.pack_end(&menu);
    header.pack_end(find);
    (header, junk, create_mail, send_receive)
}

/// The primary menu: the commands of the table by their menu (File, Edit, View, Tools, Message, Help), Quit last
fn primary_menu() -> gio::Menu {
    let menu = gio::Menu::new();
    let sections = gio::Menu::new();
    for (id, name) in [
        ("file", "File"),
        ("edit", "Edit"),
        ("view", "View"),
        ("tools", "Tools"),
        ("message", "Message"),
        ("help", "Help"),
    ] {
        let submenu = gio::Menu::new();
        for command in Command::ALL.iter().filter(|c| c.menu() == id && **c != Command::Exit) {
            submenu.append(Some(command.label()), Some(&format!("win.{}", command.name())));
        }
        sections.append_submenu(Some(name), &submenu);
    }
    menu.append_section(None, &sections);
    let quit = gio::Menu::new();
    // GNOME names it Quit
    quit.append(Some("Quit"), Some(&format!("win.{}", Command::Exit.name())));
    menu.append_section(None, &quit);
    menu
}

/// What an empty list says in its middle
fn empty_list() -> (gtk::Box, gtk::Label, gtk::Label) {
    let title = gtk::Label::new(None);
    title.add_css_class("title");
    title.set_wrap(true);
    title.set_justify(gtk::Justification::Center);
    title.set_widget_name("empty-title");
    let more = gtk::Label::new(None);
    more.add_css_class("more");
    more.set_wrap(true);
    more.set_justify(gtk::Justification::Center);
    more.set_max_width_chars(60);
    let empty = gtk::Box::new(gtk::Orientation::Vertical, 8);
    empty.add_css_class("empty-list");
    empty.set_halign(gtk::Align::Center);
    empty.set_valign(gtk::Align::Start);
    empty.set_margin_top(56);
    empty.set_can_target(false);
    empty.append(&title);
    empty.append(&more);
    empty.set_visible(false);
    (empty, title, more)
}

/// The status bar: what the app is doing, the outgoing mail, the counts of the folder
fn status_bar() -> (gtk::Box, gtk::Label, gtk::Label, gtk::Label) {
    let label = |name: &str| {
        let label = gtk::Label::new(None);
        label.set_xalign(0.0);
        label.set_ellipsize(gtk::pango::EllipsizeMode::End);
        label.set_widget_name(name);
        label
    };
    let status = label("status");
    status.set_hexpand(true);
    let outgoing = label("outgoing");
    outgoing.set_width_chars(34);
    outgoing.set_max_width_chars(48);
    let counts = label("counts");
    counts.set_width_chars(24);
    counts.set_xalign(1.0);
    let bar = gtk::Box::new(gtk::Orientation::Horizontal, 16);
    bar.add_css_class("status-bar");
    bar.append(&status);
    bar.append(&gtk::Separator::new(gtk::Orientation::Vertical));
    bar.append(&outgoing);
    bar.append(&gtk::Separator::new(gtk::Orientation::Vertical));
    bar.append(&counts);
    (bar, status, outgoing, counts)
}
