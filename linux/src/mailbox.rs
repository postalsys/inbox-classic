//! The main window: the header bar with the toolbar's buttons, the Find box and the primary menu; the folder tree,
//! the message list and the reading pane between splitters; the status bar. Every string shown was decoded by the
//! core; the message body is the sanitized document the core made, shown in the web view as it is.

use std::cell::{Cell, RefCell};
use std::collections::{HashMap, HashSet};
use std::path::{Path, PathBuf};
use std::rc::Rc;

use adw::prelude::*;
use gtk::{gdk, gio, glib};
use pe_core::{Action, DraftKind, Event, FlagColor, MessageRef, SignInWith, Summary};
use pe_imap::SpecialUse;
use pe_store::Folder;

use crate::app::{run_command, shell, spawn};
use crate::commands::Command;
use crate::folders::{ALL_INBOXES, Entry, FolderTree, Handlers, folder_of, is_under_all_inboxes, under_all_inboxes};
use crate::messages::MessageList;
use crate::reader::{Loaded, Reader};
use crate::settings;
use crate::ui::{self, TITLE};

/// What the Find box takes, shown when the mouse rests on it: the words of the catalogs, then the syntax, which is
/// the same in every language
const FIND_SYNTAX: &str = "\"exact phrase\"    -leave out    this OR that\n\
from:ann    to:bob    subject:report    filename:pdf\n\
is:unread    is:read    is:starred    has:attachment\n\
in:inbox    in:sent    in:anywhere    in:<folder name>\n\
before:2025/01/31    after:2025/01/01    older_than:2d    newer_than:1m\n\
larger:5M    smaller:100k";

/// The commands whose keys a text field has too: the field with the focus has them first
const TEXT_KEYS: [Command; 3] = [Command::Delete, Command::SelectAll, Command::Undo];

/// An account as the window knows it
#[derive(Clone)]
struct AccountInfo {
    id: i64,
    email: String,
    label: String,
    /// What the folder tree calls it
    title: String,
    sign_in: Option<SignInWith>,
}

pub struct Mailbox {
    window: adw::ApplicationWindow,
    title: adw::WindowTitle,
    pub folders: Rc<FolderTree>,
    pub list: Rc<MessageList>,
    pub reader: Rc<Reader>,
    pub find: gtk::SearchEntry,
    /// In a narrow window, the search button in place of the Find box
    find_narrow: gtk::ToggleButton,
    /// Where the folder list is: beside the messages, or in the folder button's popover
    folder_place: Rc<FolderPlace>,
    /// The folder shown was chosen by its row under All Inboxes (an account's Inbox there), not its account's
    under_all_inboxes: Cell<bool>,
    search_bar: gtk::Box,
    search_summary: gtk::Label,
    empty: gtk::Box,
    empty_title: gtk::Label,
    empty_more: gtk::Label,
    status: gtk::Label,
    outgoing: gtk::Label,
    counts: gtk::Label,
    junk: gtk::Button,
    /// The Edit submenu of the primary menu, whose Undo says what it takes back
    edit_menu: gio::Menu,
    create_mail: adw::SplitButton,
    send_receive: adw::SplitButton,
    accounts: RefCell<Vec<AccountInfo>>,
    /// The account of each folder, the name of each folder and whether it is the Inbox or a special folder
    folder_accounts: RefCell<HashMap<i64, i64>>,
    folder_names: RefCell<HashMap<i64, (String, bool)>>,
    /// The Inboxes under All Inboxes by folder, with their titles ("Inbox - Gmail")
    inbox_titles: RefCell<HashMap<i64, String>>,
    /// The folders that hold no messages (only other folders), the Drafts and the Junk folders
    unselectable: RefCell<HashSet<i64>>,
    /// The message list's right-click menu, the last one opened (the e2e driver reads it)
    pub message_popover: RefCell<Option<gtk::PopoverMenu>>,
    /// The actions of the message menu last opened, whose Watch and Ignore Conversation carry their check marks
    pub message_actions: RefCell<Option<gio::SimpleActionGroup>>,
    /// The folder tree's right-click menu, the last one opened (the e2e driver reads it)
    pub folder_popover: RefCell<Option<gtk::PopoverMenu>>,
    draft_folders: RefCell<HashSet<i64>>,
    junk_folders: RefCell<HashSet<i64>>,
    /// The account whose own item is selected in the tree, 0 when a folder is
    selected_account: Cell<i64>,
    /// The folder shown, 0 for none
    folder: Cell<i64>,
    /// All Inboxes is shown: the mail of every account's Inbox
    all_inboxes: Cell<bool>,
    /// select_start has run: later showings of the window keep what is selected
    started: Cell<bool>,
    /// What the Find box searches for, empty when the list is the folder's, and the one folder it names (in:sent)
    find_place: RefCell<String>,
    total: Cell<u64>,
    unread: Cell<u64>,
    /// The selected messages (one or many) and what they are in numbers
    refs: RefCell<Vec<MessageRef>>,
    summary: RefCell<Summary>,
    /// An Undo brought messages back: they are selected once their folder shows them, unless the user selected
    /// something else or another folder first
    undone: Cell<bool>,
    /// What Edit > Undo says now
    undo_label: RefCell<Option<String>>,
    /// The selected draft opens once its source is fetched
    open_when_ready: Cell<bool>,
    /// True while the list is reloaded: its selection changes are the reload's, not the user's
    reloading: Cell<bool>,
    mark_read: RefCell<Option<glib::SourceId>>,
    reload_later: RefCell<Option<glib::SourceId>>,
    /// What the list shows, kept by the core: the folder, the words of the Find box, the order, the grouping and the
    /// open conversations, Hide Ignored
    view: RefCell<pe_core::ListView>,
}

impl Mailbox {
    pub fn new(application: &adw::Application) -> Rc<Mailbox> {
        let folders = FolderTree::new();
        let list = MessageList::new();
        let sort = list.sort();
        let reader = Reader::new();
        let find = gtk::SearchEntry::builder()
            .placeholder_text(t!(UiFindHint))
            .tooltip_text(format!("{}\n{FIND_SYNTAX}", t!(UiFindTip)))
            .search_delay(250)
            .width_chars(26)
            .build();
        find.set_widget_name("find");
        find.update_property(&[gtk::accessible::Property::Label(&t!(UiFindHint))]);
        let title = adw::WindowTitle::new(TITLE, "");
        let parts = header_bar(&title, &find);
        let header = parts.header.clone();
        let search_summary = gtk::Label::new(None);
        search_summary.set_xalign(0.0);
        search_summary.set_hexpand(true);
        search_summary.set_ellipsize(gtk::pango::EllipsizeMode::End);
        search_summary.set_widget_name("search-summary");
        let clear = gtk::Button::with_label(&t!(UiClearSearch));
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
            // a handle that shows, as the cursor over it does not change on every desktop (Omarchy's)
            .wide_handle(true)
            .build();
        let tree = gtk::ScrolledWindow::builder()
            .child(&folders.view)
            .hscrollbar_policy(gtk::PolicyType::Never)
            .build();
        let panes = gtk::Paned::builder()
            .orientation(gtk::Orientation::Horizontal)
            .start_child(&tree)
            .end_child(&right)
            // wide enough for "Deleted Items (99)" under a second account, the longest of the special folders, and
            // for their longer names in other languages ("Gelöschte Objekte (99)")
            .position(settings.int(settings::TREE_WIDTH, 280))
            .shrink_start_child(false)
            .resize_start_child(false)
            .wide_handle(true)
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
        toolbar.add_top_bar(&parts.search_bar);
        toolbar.set_content(Some(&content));
        let window = adw::ApplicationWindow::builder()
            .application(application)
            .title(TITLE)
            // room for the folder's name in the header bar in every language ("Boîte de réception", "Bandeja de
            // entrada"), beside the sidebar button
            .default_width(1260)
            .default_height(760)
            .content(&toolbar)
            .icon_name(crate::APP_ID)
            .build();
        window.set_widget_name("main-window");
        let folder_place = Rc::new(FolderPlace {
            tree: tree.clone(),
            panes: panes.clone(),
            button: parts.folders.clone(),
            name: parts.folder_name.clone(),
            sidebar: parts.sidebar.clone(),
            narrow: Cell::new(false),
        });
        narrow_layout(&window, &parts, &folder_place, &status_bar, &list);
        folder_place.update();
        let mailbox = Rc::new(Mailbox {
            window,
            title,
            folders,
            list,
            reader,
            find,
            find_narrow: parts.search.clone(),
            folder_place,
            under_all_inboxes: Cell::new(false),
            search_bar,
            search_summary,
            empty,
            empty_title,
            empty_more,
            status,
            outgoing,
            counts,
            junk: parts.junk.clone(),
            edit_menu: parts.edit_menu.clone(),
            create_mail: parts.create_mail.clone(),
            send_receive: parts.send_receive.clone(),
            accounts: RefCell::default(),
            folder_accounts: RefCell::default(),
            folder_names: RefCell::default(),
            inbox_titles: RefCell::default(),
            unselectable: RefCell::default(),
            message_popover: RefCell::default(),
            message_actions: RefCell::default(),
            folder_popover: RefCell::default(),
            draft_folders: RefCell::default(),
            junk_folders: RefCell::default(),
            selected_account: Cell::new(0),
            folder: Cell::new(0),
            all_inboxes: Cell::new(false),
            started: Cell::new(false),
            find_place: RefCell::default(),
            total: Cell::new(0),
            unread: Cell::new(0),
            refs: RefCell::default(),
            summary: RefCell::default(),
            undone: Cell::new(false),
            undo_label: RefCell::default(),
            open_when_ready: Cell::new(false),
            reloading: Cell::new(false),
            mark_read: RefCell::new(None),
            reload_later: RefCell::new(None),
            view: RefCell::new(start_view(sort)),
        });
        mailbox.install_actions(application);
        mailbox.connect(&clear);
        mailbox.update_undo();
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
                gio::SimpleAction::new_stateful(command.name(), None, &toggled(command).to_variant())
            } else {
                gio::SimpleAction::new(command.name(), None)
            };
            action.connect_activate(move |_, _| run_command(command));
            self.window.add_action(&action);
            // Delete is the message list's own key (connect_list_keys), not the window's: in a text field it deletes
            // text; Select All and Undo are the window's after the field with the focus had them (connect)
            if let Some(accel) = command.accel().filter(|_| !TEXT_KEYS.contains(&command)) {
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
        self.install_flag_actions();
    }

    /// The Flag menu's actions: a colour for the selected messages (its state the colour they all have, 0 for none or
    /// several, so the menu marks it), and Clear Flag
    fn install_flag_actions(self: &Rc<Self>) {
        let color = gio::SimpleAction::new_stateful(FLAG_COLOR, Some(glib::VariantTy::INT32), &0i32.to_variant());
        let this = Rc::downgrade(self);
        color.connect_activate(move |_, number| {
            let color = number
                .and_then(|n| n.get::<i32>())
                .and_then(|n| u8::try_from(n).ok())
                .and_then(FlagColor::from_number);
            if let (Some(this), Some(color)) = (this.upgrade(), color) {
                this.act(Action::FlagColor(color));
            }
        });
        let clear = gio::SimpleAction::new(FLAG_CLEAR, None);
        let this = Rc::downgrade(self);
        clear.connect_activate(move |_, _| {
            if let Some(this) = this.upgrade() {
                this.act(Action::Flag(false));
            }
        });
        self.window.add_action(&color);
        self.window.add_action(&clear);
    }

    /// The Flag menu follows the selection: its colour marked, Clear Flag on while one of them is flagged
    fn update_flag_actions(&self) {
        let summary = self.summary.borrow();
        let any = !self.refs.borrow().is_empty();
        if let Some(action) = self
            .window
            .lookup_action(FLAG_COLOR)
            .and_downcast::<gio::SimpleAction>()
        {
            action.set_enabled(any);
            let marked = summary.flag_color;
            action.set_state(&i32::from(marked.map_or(0, |c| c as u8)).to_variant());
        }
        if let Some(action) = self
            .window
            .lookup_action(FLAG_CLEAR)
            .and_downcast::<gio::SimpleAction>()
        {
            action.set_enabled(any && summary.flagged > 0);
        }
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
        let changed = on(|this| {
            if !this.reloading.get() {
                this.undone.set(false);
            }
            this.on_selection_changed();
        });
        self.list.selection.connect_selection_changed(move |_, _, _| changed());
        let activated = on(|this| this.open_selected());
        self.list.view.connect_activate(move |_, _| activated());
        let sorted = on(|this| {
            this.view.borrow_mut().set_sort(this.list.sort());
            this.reload_list(true);
        });
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
        self.connect_tree();
        self.connect_menu_key();
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
        // Select All and Undo once the widget with the focus did not take them: a text field selects or undoes its
        // own text first (the application's accelerators would come before it)
        for command in [Command::SelectAll, Command::Undo] {
            let Some(accel) = command.accel() else { continue };
            shortcuts.add_shortcut(gtk::Shortcut::new(
                gtk::ShortcutTrigger::parse_string(accel),
                Some(gtk::CallbackAction::new(move |_, _| {
                    run_command(command);
                    glib::Propagation::Stop
                })),
            ));
        }
        self.window.add_controller(shortcuts);
        // Delete in the list, as on Windows
        let keys = gtk::EventControllerKey::new();
        keys.connect_key_pressed(|_, key, _, modifiers| {
            if key == gdk::Key::Delete && modifiers.is_empty() {
                run_command(Command::Delete);
                return glib::Propagation::Stop;
            }
            match list_key(key, modifiers) {
                Some(command) => {
                    run_command(command);
                    glib::Propagation::Stop
                }
                None => glib::Propagation::Proceed,
            }
        });
        self.list.view.add_controller(keys);
        self.connect_thread_keys();
        self.window.connect_close_request(|_| {
            shell().close_main();
            glib::Propagation::Stop
        });
    }

    /// Right and Left in the message list open and close a conversation, before the list moves the focus with them
    fn connect_thread_keys(self: &Rc<Self>) {
        let keys = gtk::EventControllerKey::new();
        keys.set_propagation_phase(gtk::PropagationPhase::Capture);
        let this = Rc::downgrade(self);
        keys.connect_key_pressed(move |_, key, _, modifiers| {
            let open = match key {
                gdk::Key::Right | gdk::Key::KP_Right => true,
                gdk::Key::Left | gdk::Key::KP_Left => false,
                _ => return glib::Propagation::Proceed,
            };
            match this.upgrade() {
                Some(this) if modifiers.is_empty() && this.thread_key(open) => glib::Propagation::Stop,
                _ => glib::Propagation::Proceed,
            }
        });
        self.list.view.add_controller(keys);
    }

    /// The menu key and Shift+F10 in the message list open the selected message's menu, as a right click does
    fn connect_menu_key(self: &Rc<Self>) {
        let keys = gtk::EventControllerKey::new();
        let this = Rc::downgrade(self);
        keys.connect_key_pressed(move |controller, key, _, modifiers| {
            let menu_key =
                key == gdk::Key::Menu || (key == gdk::Key::F10 && modifiers.contains(gdk::ModifierType::SHIFT_MASK));
            if let (true, Some(this), Some(widget)) = (menu_key, this.upgrade(), controller.widget()) {
                this.message_menu(&widget, 48.0, 48.0);
                return glib::Propagation::Stop;
            }
            glib::Propagation::Proceed
        });
        self.list.view.add_controller(keys);
    }

    fn connect_tree(self: &Rc<Self>) {
        let selected = Rc::downgrade(self);
        let can = Rc::downgrade(self);
        let dropped = Rc::downgrade(self);
        let imported = Rc::downgrade(self);
        let menu = Rc::downgrade(self);
        let moved = Rc::downgrade(self);
        self.folders.set_handlers(Handlers {
            selected: Box::new(move |id| {
                if let Some(this) = selected.upgrade() {
                    this.on_tree_selected(id);
                }
            }),
            // a row under All Inboxes takes what its folder takes
            can_drop: Box::new(move |refs, to| can.upgrade().is_some_and(|this| this.can_drop(refs, folder_of(to)))),
            dropped: Box::new(move |refs, to, copy| {
                if let Some(this) = dropped.upgrade() {
                    this.drop_message(refs, folder_of(to), copy);
                }
            }),
            files_dropped: Box::new(move |to, files| {
                if let Some(this) = imported.upgrade() {
                    spawn(async move { this.drop_files(Some(folder_of(to)), files).await });
                }
            }),
            opened: Box::new(remember_opened),
            moved: Box::new(move |dragged, onto, below| {
                if let Some(this) = moved.upgrade() {
                    this.move_row(dragged, onto, below);
                }
            }),
            menu: Box::new(move |widget, x, y, id| {
                if let Some(this) = menu.upgrade() {
                    if id < 0 && id != crate::folders::ALL_INBOXES {
                        this.account_menu(widget, x, y, -id);
                    } else {
                        this.folder_menu(widget, x, y);
                    }
                }
            }),
        });
    }

    // ---- the accounts and the folder tree ----

    /// The accounts changed: the tree built again, the folder shown kept when it is still there
    pub fn reload(&self) {
        let core = &shell().core;
        let accounts = core.accounts().unwrap_or_default();
        let titles = pe_core::account_titles(&accounts);
        let mut infos = Vec::new();
        let mut entries = Vec::new();
        self.folder_accounts.borrow_mut().clear();
        self.folder_names.borrow_mut().clear();
        self.unselectable.borrow_mut().clear();
        self.draft_folders.borrow_mut().clear();
        self.junk_folders.borrow_mut().clear();
        for (account, title) in accounts.iter().zip(titles) {
            let s = &account.settings;
            infos.push(AccountInfo {
                id: account.id,
                email: s.email.clone(),
                label: pe_core::account_label(&s.name, &s.email),
                title: title.clone(),
                sign_in: SignInWith::of_auth_kind(&s.auth),
            });
            let folders = core.folders(account.id).unwrap_or_default();
            let (folder_entries, unread) = self.folder_entries(account.id, &folders);
            let top = Entry {
                id: -account.id,
                name: title,
                unread: 0,
                below: unread,
                icon: "ic-mailbox-symbolic",
                depth: 0,
            };
            entries.push((top, folder_entries));
        }
        *self.accounts.borrow_mut() = infos;
        self.fill_account_menus();
        let shown = if self.all_inboxes.get() {
            ALL_INBOXES
        } else if self.under_all_inboxes.get() {
            under_all_inboxes(self.folder.get())
        } else if self.folder.get() != 0 {
            self.folder.get()
        } else {
            -self.selected_account.get()
        };
        // above the accounts, the mail of every Inbox, and each account's Inbox under it; its count the sum of theirs,
        // shown while it is closed, as a folder's with subfolders
        let top = pe_core::all_inboxes_shown(accounts.len()).then(|| {
            let inboxes = core
                .special_folders(pe_core::SpecialFolderKind::Inbox)
                .unwrap_or_default();
            *self.inbox_titles.borrow_mut() = inboxes
                .iter()
                .map(|inbox| (inbox.folder, inbox.title.clone()))
                .collect();
            let inboxes = inboxes
                .into_iter()
                .map(|inbox| Entry {
                    id: under_all_inboxes(inbox.folder),
                    name: inbox.name,
                    unread: inbox.unread,
                    below: 0,
                    icon: folder_icon(Some(SpecialUse::Inbox)),
                    depth: 1,
                })
                .collect();
            let all = Entry {
                id: ALL_INBOXES,
                name: t!(UiAllInboxes),
                unread: 0,
                below: core.inbox_unread().unwrap_or(0),
                icon: folder_icon(Some(SpecialUse::Inbox)),
                depth: 0,
            };
            (all, inboxes)
        });
        self.reloading.set(true);
        let kept = self.folders.rebuild(top, entries, &closed_rows());
        if shown != 0 && kept {
            self.folders.select(shown);
        }
        self.reloading.set(false);
        if !kept && (self.folder.get() != 0 || self.all_inboxes.get()) {
            // one account left: its Inbox in place of All Inboxes (as the window starts); else the folder is gone
            let inbox = core.start_message().ok().flatten().map(|start| start.folder);
            let replaced = self.all_inboxes.get() && inbox.is_some_and(|inbox| self.folders.select(inbox));
            if !replaced {
                self.on_folder_selected(0, false);
            }
        }
        self.show_folder_name();
    }

    /// The entries of an account's folders, and what the window keeps of each; with the account's unread messages
    fn folder_entries(&self, account: i64, folders: &[Folder]) -> (Vec<Entry>, u64) {
        let infos: Vec<&pe_store::FolderInfo> = folders.iter().map(|f| &f.info).collect();
        let depths = pe_core::tree_depths(&infos);
        let hidden = pe_core::hidden_unread(folders, &depths);
        let mut entries = Vec::new();
        for ((folder, depth), below) in folders.iter().zip(depths).zip(hidden.below) {
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
                name: pe_core::folder_name(&folder.info),
                unread: folder.unread,
                below,
                icon: folder_icon(special),
                depth,
            });
        }
        (entries, hidden.account)
    }

    /// The account of a row of the tree: an account's heading, or its Inbox's row under All Inboxes
    fn account_of_row(&self, id: i64) -> Option<i64> {
        if is_under_all_inboxes(id) {
            self.folder_accounts.borrow().get(&folder_of(id)).copied()
        } else {
            (id < 0 && id != ALL_INBOXES).then_some(-id)
        }
    }

    /// Row `dragged` dropped above or below row `onto`: its account put before or after that row's account
    fn move_row(&self, dragged: i64, onto: i64, below: bool) {
        let (Some(account), Some(beside)) = (self.account_of_row(dragged), self.account_of_row(onto)) else {
            return;
        };
        // the index among the other accounts, as the core counts it with the account taken out
        let others: Vec<i64> = self
            .accounts
            .borrow()
            .iter()
            .map(|a| a.id)
            .filter(|&id| id != account)
            .collect();
        if let Some(at) = others.iter().position(|&id| id == beside) {
            self.move_account(account, at + usize::from(below));
        }
    }

    /// Puts `account` at `index` among the accounts (0 first), the tree built again in that order, the selection kept
    pub fn move_account(&self, account: i64, index: usize) {
        if shell().core.move_account(account, index).is_ok() {
            self.reload();
        }
    }

    /// The labels and bold states of the folders of an account; a folder the tree does not have yet builds it again
    fn update_folders(&self, account: i64) {
        let folders = shell().core.folders(account).unwrap_or_default();
        let infos: Vec<&pe_store::FolderInfo> = folders.iter().map(|f| &f.info).collect();
        let hidden = pe_core::hidden_unread(&folders, &pe_core::tree_depths(&infos));
        for (folder, below) in folders.iter().zip(hidden.below) {
            if !self.folders.update(folder.id, folder.unread, below) {
                self.reload();
                return;
            }
        }
        self.folders.update(-account, 0, hidden.account);
        if pe_core::all_inboxes_shown(self.accounts.borrow().len()) {
            self.folders
                .update(ALL_INBOXES, 0, shell().core.inbox_unread().unwrap_or(0));
        }
    }

    /// The menus beside Create Mail (a message from one account) and Send/Recv (all accounts, or one)
    fn fill_account_menus(&self) {
        let accounts = self.accounts.borrow();
        let from = gio::Menu::new();
        let sync = gio::Menu::new();
        let all = gio::Menu::new();
        all.append(
            Some(&crate::words::plain(crate::words::Text::CmdSync)),
            Some(&format!("win.{}", Command::Sync.name())),
        );
        sync.append_section(None, &all);
        let each = gio::Menu::new();
        for account in accounts.iter() {
            let item = gio::MenuItem::new(Some(&t!(UiFromAccount, account = &account.label)), None);
            item.set_action_and_target_value(Some("win.new-mail-from"), Some(&account.id.to_variant()));
            from.append_item(&item);
            let item = gio::MenuItem::new(Some(&account.label), None);
            item.set_action_and_target_value(Some("win.sync-account"), Some(&account.id.to_variant()));
            each.append_item(&item);
        }
        if accounts.is_empty() {
            // an item without an action is shown turned off
            let none = crate::words::plain(crate::words::Text::TrayNoAccounts);
            from.append(Some(&none), Some("win.none"));
            each.append(Some(&none), Some("win.none"));
        }
        sync.append_section(None, &each);
        self.create_mail.set_menu_model(Some(&from));
        self.send_receive.set_menu_model(Some(&sync));
    }

    fn on_tree_selected(&self, id: i64) {
        if self.reloading.get() {
            return;
        }
        self.undone.set(false);
        let all_inboxes = id == ALL_INBOXES;
        // a row under All Inboxes shows its folder, and says whose Inbox it is
        self.under_all_inboxes.set(is_under_all_inboxes(id));
        let id = folder_of(id);
        // an account has no messages of its own
        self.selected_account.set(if id < 0 && !all_inboxes { -id } else { 0 });
        if !self.on_folder_selected(id.max(0), all_inboxes) {
            self.show_folder_name();
        }
        self.update_junk_button();
        // a folder chosen in the narrow window's popover closes it; an account's row only opens or closes the account
        if id >= 0 || all_inboxes {
            self.folder_place.button.popdown();
        }
    }

    /// Another folder (or All Inboxes) shown; false when it was already the one shown
    fn on_folder_selected(&self, folder: i64, all_inboxes: bool) -> bool {
        if folder == self.folder.get() && all_inboxes == self.all_inboxes.get() {
            return false;
        }
        // the message of the folder before is not this folder's, nor is the search
        self.folder.set(folder);
        self.all_inboxes.set(all_inboxes);
        let scope = if all_inboxes {
            Some(pe_core::Scope::AllInboxes)
        } else {
            (folder != 0).then_some(pe_core::Scope::Folder(folder))
        };
        self.view.borrow_mut().set_scope(scope);
        self.reset_find();
        self.clear_reader(false);
        self.reload_list(false);
        self.show_folder_name();
        true
    }

    pub fn account_name(&self, account: i64) -> String {
        self.account(account).map_or_else(|| t!(UiTheAccount), |a| a.title)
    }

    pub fn account_email(&self, account: i64) -> String {
        self.account(account).map(|a| a.email).unwrap_or_default()
    }

    /// What the account signs in with through the browser; None for a password
    pub fn sign_in(&self, account: i64) -> Option<SignInWith> {
        self.account(account).and_then(|a| a.sign_in)
    }

    /// The account of a folder, 0 when the window does not know the folder
    pub fn folder_account(&self, folder: i64) -> i64 {
        self.folder_accounts.borrow().get(&folder).copied().unwrap_or(0)
    }

    /// The name of a folder as the tree gives it, empty when the window does not know the folder
    pub fn folder_name(&self, folder: i64) -> String {
        self.folder_names
            .borrow()
            .get(&folder)
            .map(|(name, _)| name.clone())
            .unwrap_or_default()
    }

    fn account(&self, account: i64) -> Option<AccountInfo> {
        self.accounts.borrow().iter().find(|a| a.id == account).cloned()
    }

    /// The account of the message shown (in a search of every folder, not the selected folder's), else of the
    /// folder, else the account selected or the first one; 0 when there is none
    pub fn current_account(&self) -> i64 {
        let folder = if self.reader.folder() != 0 {
            self.reader.folder()
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

    /// The folder of a row in a list of several folders: its name, with its account's when there are several; in All
    /// Inboxes the account alone, as the tree names it
    pub fn row_folder(&self, folder: i64) -> String {
        if self.all_inboxes.get() && !self.searching() {
            let account = self.folder_accounts.borrow().get(&folder).copied();
            return self
                .accounts
                .borrow()
                .iter()
                .find(|a| Some(a.id) == account)
                .map(|a| a.title.clone())
                .unwrap_or_default();
        }
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
        self.view.borrow().searching()
    }

    /// The words searched for, as typed
    fn find_text(&self) -> String {
        self.view.borrow().text().to_string()
    }

    /// What the list shows, as it is now: a copy of its view
    pub fn list_view(&self) -> pe_core::ListView {
        self.view.borrow().clone()
    }

    fn reload_list(&self, keep_selection: bool) {
        let core = &shell().core;
        let view = self.list_view();
        let several = view.several_folders();
        // the core counts them: a folder from its indexes, a search, All Inboxes and a folder without its ignored
        // conversations what they find; an account's own item lists nothing
        let (total, unread) = view.counts(core).unwrap_or((0, 0));
        self.total.set(total);
        self.unread.set(unread);
        // grouped by conversation, a row for each conversation
        let rows = view.row_count(core).unwrap_or(0);
        let on = view.grouped() && view.active();
        self.enable(Command::ExpandAllThreads, on);
        self.enable(Command::CollapseAllThreads, on);
        // Deleted Items or Junk E-mail with messages: the folder read for the counts above says
        self.enable(Command::EmptyFolder, total > 0 && self.can_empty_folder());
        self.list
            .show_person_column(view.lists_recipients(core).unwrap_or(false));
        let (title, values) = if self.searching() {
            (t!(UiColFolder), Vec::new())
        } else {
            let names = self.accounts.borrow().iter().map(|a| a.title.clone()).collect();
            (t!(UiColAccount), names)
        };
        self.list.show_folder_column(several, &title, &values);
        // the selection follows the messages to where they are now, without a flicker of the reading pane
        let positions: Vec<u64> = if !keep_selection {
            Vec::new()
        } else if self.several() {
            view.positions(core, &self.refs.borrow()).unwrap_or_default()
        } else if self.reader.uid() != 0 {
            view.index_of(core, self.reader.folder(), self.reader.uid())
                .ok()
                .flatten()
                .into_iter()
                .collect()
        } else {
            Vec::new()
        };
        self.reloading.set(true);
        self.list.reset(view, rows, &positions);
        self.reloading.set(false);
        self.show_empty_list();
        self.show_counts();
        if !self.select_restored() {
            self.selection_reloaded();
        }
    }

    /// The list again with the selection kept: several messages stay the ones they were (only their numbers may have
    /// changed); anything else as a change of the selection
    fn selection_reloaded(&self) {
        if self.several() && self.list.selected_count() > 1 {
            *self.summary.borrow_mut() = shell().core.summary(&self.refs.borrow()).unwrap_or_default();
            self.reader.summary(&self.summary.borrow());
            self.selection_shown();
        } else {
            self.on_selection_changed();
        }
    }

    /// The messages the last Undo brought back selected, once the list has them; false when it does not (yet)
    fn select_restored(&self) -> bool {
        if !self.undone.get() {
            return false;
        }
        let core = &shell().core;
        let refs = core.restored().unwrap_or_default();
        let positions = self.view.borrow().positions(core, &refs).unwrap_or_default();
        let Some(&first) = positions.first() else {
            return false;
        };
        // first: the selection set here is no choice of the user's that would end it
        self.undone.set(false);
        self.list.select_positions(&positions);
        if let Ok(first) = u32::try_from(first) {
            self.list.view.scroll_to(first, None, gtk::ListScrollFlags::FOCUS, None);
        }
        // the focus on the first, then only as much scrolling as they need
        self.list.reveal(&positions);
        self.on_selection_changed();
        true
    }

    /// In the middle of an empty list: why there is nothing, and what to do about it
    fn show_empty_list(&self) {
        let (title, more) = if self.searching() {
            let place = self.find_place.borrow();
            let mut more = if place.is_empty() {
                t!(UiNoMatchAll)
            } else {
                t!(GtkSearchLooksIn, place = &*place)
            };
            let left = shell().core.unindexed_count().unwrap_or(0);
            if left > 0 {
                more.push_str("\n\n");
                more.push_str(&t!(GtkSearchStillIndexing, count = left));
            }
            (t!(UiNoMatch, words = &*self.find_text()), more)
        } else if self.folder.get() != 0 || self.all_inboxes.get() {
            let none = if hide_read() { t!(UiNoUnread) } else { t!(UiNoItems) };
            (none, String::new())
        } else if self.selected_account.get() != 0 {
            (t!(UiChooseFolder), String::new())
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
        let core = &shell().core;
        if self.list.selected_count() > 1 {
            let refs = self
                .view
                .borrow()
                .refs_in_ranges(core, &self.list.selected_ranges())
                .unwrap_or_default();
            *self.summary.borrow_mut() = core.summary(&refs).unwrap_or_default();
            *self.refs.borrow_mut() = refs;
            if !self.reader.shows_summary() {
                self.clear_reader(false);
            }
            self.reader.summary(&self.summary.borrow());
            self.selection_shown();
            return;
        }
        let selected = self.list.selected();
        let (folder, uid) = selected.as_ref().map_or((0, 0), |(_, m)| (m.folder_id, m.info.uid));
        // grouped, the core says what the row stands for: a collapsed conversation's row all of its messages
        let grouped = self.view.borrow().grouped();
        let refs: Vec<MessageRef> = if grouped {
            self.view
                .borrow()
                .refs_in_ranges(core, &self.list.selected_ranges())
                .unwrap_or_default()
        } else {
            selected.iter().map(|_| MessageRef { folder, uid }).collect()
        };
        *self.summary.borrow_mut() = core.summary(&refs).unwrap_or_default();
        *self.refs.borrow_mut() = refs;
        if uid == self.reader.uid() && folder == self.reader.folder() && !self.reader.shows_summary() {
            self.selection_shown();
            return;
        }
        self.clear_reader(uid != 0);
        self.selection_shown();
        if uid != 0 {
            let account = self.folder_account(folder);
            self.reader
                .open(account, folder, uid, selected.as_ref().map(|(_, m)| &m.info));
        }
    }

    /// What follows the selection: the counts in the status bar, Junk or Not Junk, the commands for one message on
    /// with exactly one selected, those for messages with any
    fn selection_shown(&self) {
        self.show_counts();
        self.update_junk_button();
        // one row: one message, or a collapsed conversation, whose row stands for its first message
        let one_row = self.list.selected_count() == 1;
        for command in Command::ALL.iter().filter(|c| c.needs_one()) {
            self.enable(*command, one_row);
        }
        let any = !self.refs.borrow().is_empty();
        for command in Command::ALL.iter().filter(|c| c.needs_some()) {
            self.enable(*command, any);
        }
        self.enable(Command::Archive, self.can_archive());
        self.update_flag_actions();
        let summary = self.summary.borrow();
        self.set_toggled(Command::WatchConversation, any && summary.watched);
        self.set_toggled(Command::IgnoreConversation, any && summary.ignored);
    }

    /// The check mark of a toggle of the menus
    pub fn set_toggled(&self, command: Command, on: bool) {
        if let Some(action) = self
            .window
            .lookup_action(command.name())
            .and_downcast::<gio::SimpleAction>()
        {
            action.set_state(&on.to_variant());
        }
    }

    fn enable(&self, command: Command, on: bool) {
        if let Some(action) = self
            .window
            .lookup_action(command.name())
            .and_downcast::<gio::SimpleAction>()
        {
            action.set_enabled(on);
        }
    }

    /// Several rows are selected: the reading pane says how many messages, none is shown (one collapsed
    /// conversation's row shows its first message, though what is done to it is done to all of its messages)
    pub fn several(&self) -> bool {
        self.list.selected_count() > 1
    }

    /// Undo on or off, saying what it takes back ("Undo Move"); after what can change it
    pub fn update_undo(&self) {
        let undo = shell().core.undo_label();
        self.enable(Command::Undo, undo.is_some());
        if *self.undo_label.borrow() == undo {
            return;
        }
        let label = undo.clone().unwrap_or_else(|| Command::Undo.label().to_string());
        *self.undo_label.borrow_mut() = undo;
        let at = Command::ALL
            .iter()
            .filter(|c| c.menu() == "edit")
            .position(|c| *c == Command::Undo);
        if let Some(at) = at.and_then(|at| i32::try_from(at).ok())
            && self.edit_menu.n_items() > at
        {
            let item = menu_item(&label, Command::Undo);
            self.edit_menu.remove(at);
            self.edit_menu.insert_item(at, &item);
        }
    }

    /// The selected messages: the one selected, or the several
    pub fn selected_refs(&self) -> Vec<MessageRef> {
        self.refs.borrow().clone()
    }

    /// The reading pane emptied; with "There is no message selected." in it unless a message is `loading`
    fn clear_reader(&self, loading: bool) {
        self.open_when_ready.set(false);
        if let Some(timer) = self.mark_read.borrow_mut().take() {
            timer.remove();
        }
        self.reader.clear(loading);
    }

    /// The reading pane's message fetched (a draft opened before opens now), or on screen (read after a moment)
    fn message_loaded(self: &Rc<Self>, loaded: Loaded) {
        if let Loaded::Fetched = loaded {
            if self.open_when_ready.replace(false) {
                self.open_selected();
            }
            return;
        }
        // read after a moment on screen, not while the user moves through the list
        if let Some(timer) = self.mark_read.borrow_mut().take() {
            timer.remove();
        }
        let this = Rc::downgrade(self);
        let timer = glib::timeout_add_local_once(std::time::Duration::from_secs(1), move || {
            let Some(this) = this.upgrade() else { return };
            this.mark_read.borrow_mut().take();
            if let Some((_, message)) = this.list.selected()
                && message.info.uid == this.reader.uid()
                && !message.info.seen()
            {
                let _ = shell().core.set_seen(message.folder_id, message.info.uid, true);
            }
        });
        *self.mark_read.borrow_mut() = Some(timer);
    }

    /// The selected message in a window of its own (double-click or Enter), Previous and Next going through the
    /// list as it is now; a draft in a compose window instead, to go on writing it, once it is fetched when it is not
    /// yet
    pub fn open_selected(&self) {
        let Some(message) = self.reader.message().filter(|_| !self.several()) else {
            return;
        };
        let (folder, uid) = (message.folder, message.uid);
        if !self.draft_folders.borrow().contains(&folder) {
            crate::message_window::open(message, self.list_view());
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
        if self.reader.uid() == 0 || !self.reader.has_view() {
            return None;
        }
        shell()
            .core
            .draft(self.reader.folder(), self.reader.uid(), kind)
            .ok()
            .flatten()
    }

    /// The message `uid` of `folder` shown: its folder chosen in the tree (which ends a search), the message
    /// selected in the list
    pub fn show_message(&self, folder: i64, uid: u64) {
        // All Inboxes stays when it has the message (of an Inbox), its list up to date with it
        if self.all_inboxes.get() && !self.searching() {
            if let Some(timer) = self.reload_later.borrow_mut().take() {
                timer.remove();
            }
            self.reload_list(true);
            if self.select_in_list(folder, uid) {
                return;
            }
        }
        // selecting another folder ends a search; the folder selected already is not selected again, its search is
        // ended here
        if self.searching() && self.folder.get() == folder && !self.all_inboxes.get() {
            self.clear_find();
        }
        if !self.select_folder_row(folder) || self.folder.get() != folder {
            return;
        }
        self.select_in_list(folder, uid);
    }

    /// Folder `folder`'s row selected from outside the tree (a notification, Next Unread): its row under All Inboxes
    /// while the user works there (All Inboxes or one of its rows selected), its account's otherwise; false when the
    /// tree does not have it
    fn select_folder_row(&self, folder: i64) -> bool {
        let there = self.all_inboxes.get() || self.under_all_inboxes.get();
        (there && self.folders.select(under_all_inboxes(folder))) || self.folders.select(folder)
    }

    /// The row of the message `uid` of `folder` selected in the list, its conversation opened when it is a reply hidden
    /// in it; false when it is not there
    fn select_in_list(&self, folder: i64, uid: u64) -> bool {
        let core = &shell().core;
        let revealed = self.view.borrow_mut().reveal(core, folder, uid).unwrap_or(false);
        if revealed {
            self.reload_list(true);
        }
        let index = self.view.borrow().index_of(core, folder, uid);
        let Ok(Some(index)) = index else {
            return false;
        };
        let Ok(index) = u32::try_from(index) else {
            return false;
        };
        self.list.select(index);
        self.list.view.grab_focus();
        true
    }

    /// The conversation `thread` opened (its other messages under its first) or closed, the selection kept on its
    /// row
    pub fn set_thread_expanded(&self, thread: i64, open: bool) {
        let changed = {
            let mut view = self.view.borrow_mut();
            if open {
                view.expand(thread)
            } else {
                view.collapse(thread)
            }
        };
        if changed {
            self.reload_list(true);
        }
    }

    /// The + or - of a conversation's row: the conversation `thread` opened or closed
    pub fn toggle_thread(&self, thread: i64) {
        self.view.borrow_mut().toggle(thread);
        self.reload_list(true);
    }

    /// View > Expand All Conversations (`open`) and Collapse All Conversations
    pub fn expand_all_threads(&self, open: bool) {
        let changed = {
            let mut view = self.view.borrow_mut();
            if open {
                view.expand_all(&shell().core).unwrap_or(false)
            } else {
                view.collapse_all()
            }
        };
        if changed {
            self.reload_list(true);
        }
    }

    /// Group messages by conversation turned on or off in Preferences: the list again, every conversation closed
    pub fn regroup(&self) {
        let changed = self.view.borrow_mut().set_grouped(grouped());
        if changed {
            self.reload_list(true);
        }
    }

    /// Right and Left in the list: Right opens the conversation of the selected row, Left closes it (from a reply
    /// too, whose conversation's row is then selected). False when the key does nothing here.
    fn thread_key(&self, open: bool) -> bool {
        let Some((_, message)) = self.list.selected() else {
            return false;
        };
        let Some(place) = message.thread else {
            return false;
        };
        if place.depth == 0 && !place.opens() {
            return false;
        }
        if open && place.depth > 0 {
            return true;
        }
        // a reply's row goes with it: the selection follows its message onto its conversation's row
        self.set_thread_expanded(place.thread, open);
        if let Some((at, _)) = self.list.selected() {
            self.list.view.scroll_to(at, None, gtk::ListScrollFlags::FOCUS, None);
        }
        true
    }

    /// The window shown the first time: All Inboxes (two or more accounts) or the first account's Inbox chosen, and
    /// its newest message selected
    pub fn select_start(&self) {
        if self.started.replace(true) || self.folder.get() != 0 || self.all_inboxes.get() {
            return;
        }
        let Ok(Some(start)) = shell().core.start_message() else {
            return;
        };
        let uid = start.uid.unwrap_or(0);
        if !start.all_inboxes {
            self.show_message(start.folder, uid);
        } else if self.folders.select(ALL_INBOXES) {
            self.select_in_list(start.folder, uid);
        }
    }

    // ---- the Find box ----

    fn on_find_changed(&self) {
        // what only has spaces finds everything, as the core reads it
        let text = self.find.text().trim().to_string();
        if text == self.view.borrow().text() {
            return;
        }
        *self.find_place.borrow_mut() = pe_core::Core::search_place(&text).unwrap_or_default();
        self.view.borrow_mut().set_text(&text);
        self.reload_list(true);
        self.show_folder_name();
    }

    pub fn focus_find(&self) {
        if !self.find.is_visible() {
            self.find_narrow.set_active(true);
            return;
        }
        self.find.grab_focus();
        self.find.select_region(0, -1);
    }

    /// The Find box emptied and the search dropped, without the list following it (the caller reloads)
    fn reset_find(&self) {
        self.view.borrow_mut().set_text("");
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
        self.list.view.grab_focus();
        true
    }

    /// The name of the selected folder (or account) for the title; while searching, where it looks: "All folders",
    /// or the one folder named (in:sent)
    pub fn selected_name(&self) -> String {
        if self.searching() {
            let place = self.find_place.borrow();
            return if place.is_empty() {
                t!(UiAllFolders)
            } else {
                place.clone()
            };
        }
        if self.all_inboxes.get() {
            return t!(UiAllInboxes);
        }
        // an account's Inbox chosen under All Inboxes: which account's ("Inbox - Gmail")
        if self.under_all_inboxes.get()
            && let Some(title) = self.inbox_titles.borrow().get(&self.folder.get())
        {
            return title.clone();
        }
        if let Some((name, _)) = self.folder_names.borrow().get(&self.folder.get()) {
            return name.clone();
        }
        self.account(self.selected_account.get())
            .map(|a| a.title)
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
        let place = self.find_place.borrow();
        let words = self.find_text();
        let mut summary = if place.is_empty() {
            t!(GtkSearchResultsEverywhere, count = total, words = &*words)
        } else {
            t!(GtkSearchResultsIn, count = total, words = &*words, place = &*place)
        };
        let left = shell().core.unindexed_count().unwrap_or(0);
        if left > 0 {
            summary.push_str("  \u{00B7}  ");
            summary.push_str(&t!(GtkSearchIndexing, count = left));
        }
        self.search_summary.set_text(&summary);
        self.search_bar.set_visible(true);
    }

    // ---- the status bar ----

    pub fn set_status(&self, text: &str) {
        self.status.set_text(text);
        // the whole text as the tip, as a long one (an error and what happens next) is cut short
        self.status.set_tooltip_text((!text.is_empty()).then_some(text));
    }

    pub fn set_outgoing(&self, text: &str) {
        self.outgoing.set_text(text);
        // the whole text as the tip, as a long subject is cut short
        self.outgoing.set_tooltip_text(Some(text));
    }

    /// "12 messages, 3 unread" for the status bar ("12 found" for a search), and how many are selected when several are
    pub fn show_counts(&self) {
        let (total, unread) = (self.total.get(), self.unread.get());
        let text = if !self.searching() && self.folder.get() == 0 && !self.all_inboxes.get() {
            String::new()
        } else {
            pe_core::list_counts(total, unread, self.list.selected_count(), self.searching())
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
            (Command::NotJunk, t!(UiTbNotJunk))
        } else {
            (Command::Junk, t!(UiTbJunk))
        };
        self.junk.set_action_name(Some(&format!("win.{}", command.name())));
        self.junk.set_icon_name(if in_junk {
            "ic-mail-checkmark-symbolic"
        } else {
            "ic-mail-prohibited-symbolic"
        });
        self.junk.set_tooltip_text(Some(&label));
    }

    /// Whether the messages selected, or else the folder, are in a Junk folder
    pub fn in_junk(&self) -> bool {
        if !self.refs.borrow().is_empty() {
            return self.summary.borrow().in_junk;
        }
        self.junk_folders.borrow().contains(&self.folder.get())
    }

    // ---- the core's events ----

    pub fn on_event(self: &Rc<Self>, event: &Event) {
        if let Some(loaded) = self.reader.on_event(event) {
            self.message_loaded(loaded);
        }
        match event {
            Event::FoldersChanged { .. } => self.reload(),
            Event::FolderChanged { account, folder } => {
                self.update_folders(*account);
                if *folder == self.folder.get() && !self.searching() {
                    self.reload_list(true);
                } else if self.view.borrow().several_folders() {
                    // a list of several folders follows their changes once a sync of many of them is done
                    self.reload_soon();
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
            }
        });
        *self.reload_later.borrow_mut() = Some(timer);
    }

    // ---- commands on the messages ----

    /// `action` done to the selected messages
    fn act(&self, action: Action) {
        self.act_on(self.selected_refs(), action);
    }

    /// `action` done to `refs`, its outcome in the status bar, the core's refusal said as it is; when they are the
    /// selection, a move or delete selects the message after them
    fn act_on(&self, refs: Vec<MessageRef>, action: Action) {
        if refs.is_empty() {
            return;
        }
        // the core says which actions take the selection out of the list: those that move it, and Ignore while
        // ignored conversations are hidden
        let leaves = self.view.borrow().leaves_list(&self.summary.borrow(), action);
        // the row that takes the place of the last one going
        let after = (refs == self.selected_refs())
            .then(|| self.list.last_selected())
            .flatten()
            .map(|last| (last + 1).saturating_sub(self.list.selected_count() as u32));
        let outcome = shell().core.act(&refs, action);
        self.update_undo();
        match outcome {
            Ok(text) => {
                self.set_status(&text);
                if leaves && let Some(after) = after {
                    self.select_after_removal(after);
                }
            }
            Err(error) => {
                let window = self.window.clone();
                spawn(async move { ui::alert(&window, TITLE, &pe_core::sentence(&error.to_string())).await });
            }
        }
    }

    pub fn mark_selected(&self, seen: bool) {
        self.act(Action::Read(seen));
    }

    /// Every message of the selected folder read, or of every Inbox from All Inboxes; nothing while searching
    pub fn mark_all_read(&self) {
        if self.searching() {
            return;
        }
        if self.all_inboxes.get() {
            let _ = shell().core.mark_all_inboxes_read();
        } else if self.folder.get() != 0 {
            let _ = shell().core.mark_all_read(self.folder.get());
        }
    }

    pub fn load_pictures(&self) {
        self.reader.load_pictures();
    }

    /// Flags the selected messages, or takes the flag away when they all have it
    pub fn flag_selected(&self) {
        self.act(Action::ToggleFlag);
    }

    /// Every selected message can be archived (from the Inbox or a folder of the user's)
    pub fn can_archive(&self) -> bool {
        self.summary.borrow().archivable
    }

    /// The selected messages out of the Inbox into the account's Archive (on Gmail every label taken off)
    pub fn archive_selected(&self) {
        if self.can_archive() {
            self.act(Action::Archive);
        }
    }

    /// Watch Conversation (`ignore` false) or Ignore Conversation on the conversations of the selected messages, or the
    /// mark taken away when they all have it
    pub fn mark_conversations(&self, ignore: bool) {
        self.act(if ignore { Action::Ignore } else { Action::Watch });
    }

    /// View > Hide Ignored Conversations turned on or off: kept, and the list again
    pub fn set_hide_ignored(&self, on: bool) {
        shell().settings.set_bool(settings::HIDE_IGNORED, on);
        self.set_toggled(Command::HideIgnored, on);
        self.view.borrow_mut().set_hide_ignored(on);
        self.reload_list(true);
    }

    /// View > Hide Read Messages turned on or off, for every folder: kept, and the list again (a message read while
    /// it is on stays listed until the folder changes, the core keeps it)
    pub fn set_hide_read(&self, on: bool) {
        shell().settings.set_bool(settings::HIDE_READ, on);
        self.set_toggled(Command::HideRead, on);
        self.view.borrow_mut().set_show(show_for(on));
        self.reload_list(true);
    }

    /// View > Folder List turned on or off: kept, and the folder list beside the messages or in the folder button's
    /// popover
    pub fn set_folder_list(&self, on: bool) {
        shell().settings.set_bool(settings::FOLDER_LIST, on);
        self.set_toggled(Command::FolderList, on);
        self.folder_place.update();
    }

    /// The selected messages junk ($Junk, into the Junk folder) or not junk ($NotJunk, into the Inbox)
    pub fn mark_junk(&self, junk: bool) {
        self.act(Action::Junk(junk));
    }

    /// After messages left the list: the one that took the place of the last of them selected, or the last one
    fn select_after_removal(&self, index: u32) {
        self.reload_list(false);
        let rows = self.list.rows();
        if rows > 0 {
            self.list.select(index.min(rows - 1));
        }
    }

    /// The selected messages into Deleted Items (for good when they are in there, asked first)
    pub async fn delete_selected(&self) {
        if self.selected_refs().is_empty() {
            return;
        }
        let question = self.summary.borrow().delete_question();
        if let Some(question) = question
            && !ui::confirm(&self.window, TITLE, &question, true).await
        {
            return;
        }
        self.act(Action::Delete);
    }

    /// Move to Folder (or Copy to Folder, `copy`): asks where, in the folder tree of every account, and sends the
    /// selected messages there; to another account they go in the background
    pub async fn move_selected(&self, copy: bool) {
        let refs = self.selected_refs();
        let Some(first) = refs.first() else {
            return;
        };
        let summary = self.summary.borrow().clone();
        let request = crate::move_dialog::Request {
            title: summary.move_title(copy),
            prompt: summary.move_prompt(copy),
            verb: if copy {
                crate::words::plain(crate::words::Text::UiButtonCopy)
            } else {
                crate::words::plain(crate::words::Text::UiButtonMove)
            },
            // the folder they are all in is no choice
            current: (summary.folders == 1).then_some(first.folder),
            new_folder: true,
        };
        if let Some(to) = crate::move_dialog::choose(&self.window, request).await {
            self.act(if copy { Action::Copy(to) } else { Action::Move(to) });
        }
    }

    /// Next Message (`forward`) or Previous Message: the row below the selection or above it selected and shown, as
    /// a click on it does; the first row when none is selected
    pub fn step_message(&self, forward: bool) {
        let ranges = self.list.selected_ranges();
        let target = match (ranges.first(), ranges.last()) {
            (Some(&(first, _)), Some(&(_, end))) if forward => (first < end).then_some(end),
            (Some(&(first, _)), Some(_)) => first.checked_sub(1),
            _ => Some(0),
        };
        if let Some(row) = target.and_then(|t| u32::try_from(t).ok())
            && row < self.list.rows()
        {
            self.list.select(row);
        }
    }

    /// Next Unread Message: the first unread message below the one shown (from the top when none is); with none
    /// left, after asking, the folder the core goes on to and its first unread message
    pub async fn next_unread(&self) {
        let core = &shell().core;
        let (mut folder, mut uid) = (self.reader.folder(), self.reader.uid());
        loop {
            let step = self.view.borrow().next_unread_step(core, folder, uid);
            match step {
                Ok(pe_core::NextUnread::Message(next)) => {
                    self.select_in_list(next.folder, next.uid);
                    return;
                }
                Ok(pe_core::NextUnread::Ask { folder: to, question }) => {
                    // the question as the heading, what happens under it, as GNOME's dialogs have it
                    let (heading, body) = question.split_once("\n\n").unwrap_or((TITLE, &question));
                    if !ui::confirm(&self.window, heading, body, false).await || !self.select_folder_row(to) {
                        return;
                    }
                    (folder, uid) = (to, 0);
                }
                _ => {
                    self.set_status(&t!(NoUnreadLeft));
                    return;
                }
            }
        }
    }

    /// Go to Folder: a folder of any account chosen as Move to Folder chooses one (typed to find it), then shown
    pub async fn go_to_folder(&self) {
        let request = crate::move_dialog::Request {
            title: crate::words::title(crate::words::Text::CmdGoToFolder),
            prompt: t!(UiGoToPrompt),
            verb: t!(UiOk),
            current: None,
            new_folder: false,
        };
        if let Some(folder) = crate::move_dialog::choose(&self.window, request).await
            && self.folders.select(folder)
        {
            self.list.view.grab_focus();
        }
    }

    /// Edit > Select All: every message of the list
    pub fn select_all(&self) {
        self.list.select_all();
        self.list.view.grab_focus();
    }

    /// Edit > Undo: the last move, delete or junk taken back
    pub async fn undo(&self) {
        let outcome = shell().core.undo();
        self.update_undo();
        match outcome {
            Ok(text) => {
                self.set_status(&text);
                self.undone.set(true);
                self.select_restored();
            }
            Err(error) => ui::alert(&self.window, TITLE, &pe_core::sentence(&error.to_string())).await,
        }
    }

    pub fn can_drop(&self, refs: &[MessageRef], to: i64) -> bool {
        if refs.is_empty() {
            return false;
        }
        // an account's own item, the folder they all are in, or one that holds no messages: not there; a folder of
        // another account takes them, in the background
        to > 0
            && self.folder_accounts.borrow().contains_key(&to)
            && !self.unselectable.borrow().contains(&to)
            && !refs.iter().all(|r| r.folder == to)
    }

    /// Messages dropped onto a folder: moved, or copied with Ctrl; a move of the selection selects the message after
    /// it, as Move to Folder does
    pub fn drop_message(&self, refs: &[MessageRef], to: i64, copy: bool) {
        self.act_on(refs.to_vec(), if copy { Action::Copy(to) } else { Action::Move(to) });
    }

    /// .eml files dropped from a file manager onto folder `to`, or onto the list (None: the folder it shows): put in
    /// it as Import does
    pub async fn drop_files(&self, to: Option<i64>, files: Vec<PathBuf>) {
        let folder = to.unwrap_or(self.folder.get());
        if folder <= 0 || !self.folder_accounts.borrow().contains_key(&folder) {
            ui::alert(&self.window, &import_title(), &t!(UiImportChooseFolder)).await;
            return;
        }
        self.import_into(folder, &files).await;
    }

    // ---- folders ----

    /// The right-click menu of a folder: Mark All Read first, as Outlook Express has it, for a folder with unread
    /// messages; New Folder, Rename and Delete for a folder that is not special
    /// The folder listed (0 for none, or All Inboxes), for the e2e driver
    #[cfg(feature = "e2e")]
    pub fn folder_id(&self) -> i64 {
        self.folder.get()
    }

    /// An account's right-click menu: Send and Receive (its server alone), Mark All Read (every folder of it), New
    /// Folder, Move Up and Move Down (turned off at the ends), Properties
    pub fn account_menu(self: &Rc<Self>, widget: &gtk::Widget, x: f64, y: f64, account: i64) {
        use crate::words::{Text, plain};
        let group = gio::SimpleActionGroup::new();
        let add = |name: &str, enabled: bool, run: Box<dyn Fn(Rc<Mailbox>)>| {
            let action = gio::SimpleAction::new(name, None);
            action.set_enabled(enabled);
            let this = Rc::downgrade(self);
            action.connect_activate(move |_, _| {
                if let Some(this) = this.upgrade() {
                    run(this);
                }
            });
            group.add_action(&action);
        };
        add(
            "sync",
            true,
            Box::new(move |_| {
                let _ = shell().core.sync(account);
            }),
        );
        // the counts its folders are drawn with: nothing unread, nothing to mark; the core's events redraw them after
        add(
            "mark-all-read",
            self.folders.unread_within(-account) > 0,
            Box::new(move |_| {
                let _ = shell().core.mark_account_read(account);
            }),
        );
        add(
            "new",
            true,
            Box::new(move |this| spawn(async move { this.new_folder_in(account, 0).await })),
        );
        let place = self.accounts.borrow().iter().position(|a| a.id == account).unwrap_or(0);
        let count = self.accounts.borrow().len();
        add(
            "move-up",
            place > 0,
            Box::new(move |this| this.move_account(account, place.saturating_sub(1))),
        );
        add(
            "move-down",
            place + 1 < count,
            Box::new(move |this| this.move_account(account, place + 1)),
        );
        add(
            "properties",
            true,
            Box::new(move |this| {
                spawn(async move {
                    if crate::accounts::account_properties(&this.window, account).await {
                        this.reload();
                    }
                })
            }),
        );
        let menu = gio::Menu::new();
        let first = gio::Menu::new();
        first.append(Some(&plain(Text::UiAccountSync)), Some("account.sync"));
        first.append(Some(&plain(Text::CmdMarkAllRead)), Some("account.mark-all-read"));
        menu.append_section(None, &first);
        let second = gio::Menu::new();
        second.append(Some(&plain(Text::CmdNewFolder)), Some("account.new"));
        menu.append_section(None, &second);
        let order = gio::Menu::new();
        order.append(Some(&plain(Text::UiAccountMoveUp)), Some("account.move-up"));
        order.append(Some(&plain(Text::UiAccountMoveDown)), Some("account.move-down"));
        menu.append_section(None, &order);
        let third = gio::Menu::new();
        third.append(Some(&plain(Text::UiAccountProperties)), Some("account.properties"));
        menu.append_section(None, &third);
        widget.insert_action_group("account", Some(&group));
        *self.folder_popover.borrow_mut() = Some(popup_menu(widget, &menu, x, y));
    }

    pub fn folder_menu(self: &Rc<Self>, widget: &gtk::Widget, x: f64, y: f64) {
        let folder = self.folder.get();
        let all_inboxes = self.all_inboxes.get();
        let some_unread = if all_inboxes {
            shell().core.inbox_unread().is_ok_and(|unread| unread > 0)
        } else {
            folder != 0 && shell().core.folder(folder).is_ok_and(|f| f.unread > 0)
        };
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
        // Deleted Items and Junk E-mail can be emptied, as in Outlook Express
        let emptiable = self.can_empty_folder();
        add("empty", emptiable && self.total.get() > 0, Command::EmptyFolder);
        let menu = gio::Menu::new();
        let first = gio::Menu::new();
        first.append(
            Some(&crate::words::plain(crate::words::Text::CmdMarkAllRead)),
            Some("folder.mark-all-read"),
        );
        menu.append_section(None, &first);
        // All Inboxes is no folder of one account: the folder commands never apply to it, so it has none
        if !all_inboxes {
            let rest = gio::Menu::new();
            rest.append(
                Some(&crate::words::plain(crate::words::Text::CmdNewFolder)),
                Some("folder.new"),
            );
            rest.append(Some(&t!(GtkMenuRename)), Some("folder.rename"));
            rest.append(Some(&t!(UiTbDelete)), Some("folder.delete"));
            menu.append_section(None, &rest);
            if emptiable {
                let empty = gio::Menu::new();
                empty.append(
                    Some(&crate::words::plain(crate::words::Text::CmdEmptyFolder)),
                    Some("folder.empty"),
                );
                menu.append_section(None, &empty);
            }
        }
        widget.insert_action_group("folder", Some(&group));
        *self.folder_popover.borrow_mut() = Some(popup_menu(widget, &menu, x, y));
    }

    /// What to ask before emptying the folder shown (Deleted Items or Junk E-mail with messages); None when Empty
    /// Folder does not apply
    fn empty_question(&self) -> Option<String> {
        shell().core.empty_folder_question(self.folder.get()).ok().flatten()
    }

    /// The folder shown is Deleted Items or Junk E-mail, not All Inboxes or a search
    fn can_empty_folder(&self) -> bool {
        !self.all_inboxes.get() && !self.searching() && shell().core.can_empty(self.folder.get()).unwrap_or(false)
    }

    /// Deleted Items or Junk E-mail emptied for good, after asking (the core words the question, with how many go)
    pub async fn empty_folder(&self) {
        let Some(question) = self.empty_question() else {
            return;
        };
        // the question as the heading, what happens under it, as GNOME's dialogs have it
        let (heading, body) = question.split_once("\n\n").unwrap_or((TITLE, &question));
        // the buttons say what they do, as GNOME's dialogs have them: Cancel, and Empty in red
        let buttons = [("cancel", t!(UiCancel)), ("empty", t!(UiEmptyButton))];
        let buttons: Vec<(&str, &str)> = buttons.iter().map(|(id, label)| (*id, label.as_str())).collect();
        if ui::ask(&self.window, heading, body, &buttons, "cancel", "cancel", Some("empty")).await != "empty" {
            return;
        }
        match shell().core.empty_folder(self.folder.get()) {
            Ok(done) => self.set_status(&done),
            Err(reason) => ui::alert(&self.window, TITLE, &reason.to_string()).await,
        }
    }

    /// A folder in the selected one, or at the top of the selected account
    pub async fn new_folder(&self) {
        if self.all_inboxes.get() {
            return;
        }
        self.new_folder_in(self.current_account(), self.folder.get()).await;
    }

    /// A new folder in `account`, under folder `folder` (0: at the top of the account)
    pub async fn new_folder_in(&self, account: i64, folder: i64) {
        if account == 0 {
            return;
        }
        let where_ = if folder != 0 {
            t!(UiNewFolderInSelected)
        } else {
            t!(UiNewFolderAtTop)
        };
        let Some(name) = ui::ask_folder_name(&self.window, &t!(UiNewFolderTitle), &where_, "").await else {
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
        let intro = t!(UiRenameFolderIntro, folder = &current);
        let Some(name) = ui::ask_folder_name(&self.window, &t!(UiRenameFolderTitle), &intro, &current).await else {
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
        let question = t!(UiDeleteFolderQuestion, folder = &name);
        if !ui::confirm(&self.window, TITLE, &question, true).await {
            return;
        }
        if let Err(reason) = shell().core.delete_folder(folder) {
            ui::alert(&self.window, TITLE, &reason.to_string()).await;
        }
    }

    // ---- files and printing ----

    /// File > Save As: the message shown, as an .eml; several selected, into a folder chosen, one file each
    pub async fn save_shown_as(&self) {
        if self.several() {
            self.save_selected_into_folder().await;
            return;
        }
        if self.reader.uid() == 0 {
            return;
        }
        let window = self.window.clone().upcast::<gtk::Window>();
        let Ok(Some((name, data))) = shell().core.message_source(self.reader.folder(), self.reader.uid()) else {
            ui::alert(&window, TITLE, &t!(UiNotDownloaded)).await;
            return;
        };
        let kind = t!(UiFilterMessages);
        let patterns = Some((kind.as_str(), &["*.eml"][..]));
        let Some(path) = ui::save_file(&window, &t!(UiSaveMessageAs), &name, patterns).await else {
            return;
        };
        if std::fs::write(&path, data).is_err() {
            ui::alert(&window, TITLE, &t!(UiNotSaved)).await;
        }
    }

    /// Save As with several selected: a folder asked for, each message saved there under its subject, never over a
    /// file there; those not downloaded yet are downloaded for it
    async fn save_selected_into_folder(&self) {
        let window = self.window.clone().upcast::<gtk::Window>();
        let Some(dir) = ui::choose_folder(&window, &t!(UiSaveMessagesIn)).await else {
            return;
        };
        let into = dir.clone();
        let saved = crate::files::with_downloads(self.selected_refs(), move |core, refs| {
            core.save_messages(refs, &into, crate::files::WAIT)
        })
        .await;
        match saved {
            Ok(written) => self.set_status(&pe_core::saved_text(written.len() as u64, &dir)),
            Err(why) => ui::alert(&window, TITLE, &why).await,
        }
    }

    /// Forward with several selected: one new message with them attached as .eml files, from the account of the first;
    /// those not downloaded yet are downloaded for it
    pub async fn forward_selected(&self) {
        let refs = self.selected_refs();
        let Some(first) = refs.first().copied() else {
            return;
        };
        let account = self.folder_accounts.borrow().get(&first.folder).copied().unwrap_or(0);
        let draft =
            crate::files::with_downloads(refs, |core, refs| core.forward_as_attachments(refs, crate::files::WAIT))
                .await;
        match draft {
            Ok(draft) => crate::compose::open(account, Some(draft)),
            Err(why) => ui::alert(&self.window, TITLE, &why).await,
        }
    }

    /// File > Properties: the Internet headers of the message shown
    pub async fn show_properties(&self) {
        if self.reader.uid() == 0 {
            ui::alert(&self.window, TITLE, &t!(UiSelectMessageFirst)).await;
            return;
        }
        let Ok(Some(headers)) = shell().core.message_headers(self.reader.folder(), self.reader.uid()) else {
            ui::alert(&self.window, TITLE, &t!(UiNotDownloaded)).await;
            return;
        };
        let subject = self.reader.subject().unwrap_or_default();
        let title = if subject.is_empty() {
            crate::words::plain(crate::words::Text::UiProperties)
        } else {
            t!(UiPropertiesOf, subject = &subject)
        };
        let dialog = ui::text_dialog(
            &self.window,
            &title,
            &t!(UiInternetHeaders),
            &headers.replace("\r\n", "\n"),
        );
        dialog.set_widget_name("properties-dialog");
    }

    /// View Source: the whole message as the server has it
    pub async fn show_source(&self) {
        if self.reader.uid() == 0 {
            ui::alert(&self.window, TITLE, &t!(UiSelectMessageFirst)).await;
            return;
        }
        let Ok(Some((title, text))) = shell()
            .core
            .message_source_text(self.reader.folder(), self.reader.uid())
        else {
            ui::alert(&self.window, TITLE, &t!(UiNotDownloaded)).await;
            return;
        };
        // Save As from here saves the message shown, as File > Save As does
        let save = gtk::Button::with_label(Command::SaveAs.label());
        save.set_widget_name("source-save");
        save.connect_clicked(|_| run_command(Command::SaveAs));
        let text = text.replace("\r\n", "\n");
        let dialog = ui::text_dialog_sized(
            &self.window,
            &title,
            "",
            &text,
            (820, 600),
            false,
            Some(save.upcast_ref()),
        );
        dialog.set_widget_name("source-dialog");
    }

    /// The right-click menu of the message list: the actions on the message, as Outlook Express has them, with the
    /// choices that fit it (Mark as Unread for a read one, Not Junk in Junk E-mail)
    /// The Flag menu on its own at `x`, `y` of `widget`, as the message menu's Flag submenu shows it: for the UI test's
    /// picture (a submenu can not be opened from outside the popover)
    #[cfg(feature = "e2e")]
    pub fn flag_menu_at(&self, widget: &gtk::Widget, x: f64, y: f64) {
        *self.message_popover.borrow_mut() = Some(popup_menu(widget, &flag_menu(), x, y));
    }

    /// A menu of the primary menu ("message", "view") at `x`, `y` of `widget`, for the UI test's picture of its check
    /// marks, as [`Mailbox::flag_menu_at`]
    #[cfg(feature = "e2e")]
    pub fn command_menu_at(&self, id: &str, widget: &gtk::Widget, x: f64, y: f64) {
        *self.message_popover.borrow_mut() = Some(popup_menu(widget, &command_menu(id), x, y));
    }

    pub fn message_menu(self: &Rc<Self>, widget: &gtk::Widget, x: f64, y: f64) {
        let refs = self.selected_refs();
        let Some(first) = refs.first().copied() else {
            return;
        };
        let several = self.several();
        let summary = self.summary.borrow().clone();
        let group = gio::SimpleActionGroup::new();
        // the command's own label, or the one that fits this message
        let add = |section: &gio::Menu, command: Command, label: Option<&str>| {
            let name = format!("{command:?}").to_lowercase();
            let action = gio::SimpleAction::new(&name, None);
            action.connect_activate(move |_, _| run_command(command));
            // off as on the primary menu: the commands of one message while several are selected
            let on = self.window.lookup_action(command.name()).is_none_or(|a| a.is_enabled());
            action.set_enabled(on);
            group.add_action(&action);
            section.append(Some(label.unwrap_or(command.label())), Some(&format!("message.{name}")));
        };
        let menu = gio::Menu::new();
        if !several && self.draft_folders.borrow().contains(&first.folder) {
            let open = gio::Menu::new();
            let action = gio::SimpleAction::new("open", None);
            let this = Rc::downgrade(self);
            action.connect_activate(move |_, _| {
                if let Some(this) = this.upgrade() {
                    this.open_selected();
                }
            });
            group.add_action(&action);
            open.append(
                Some(&crate::words::plain(crate::words::Text::UiMenuOpen)),
                Some("message.open"),
            );
            menu.append_section(None, &open);
        }
        let answer = gio::Menu::new();
        for command in [Command::Reply, Command::ReplyAll, Command::Forward] {
            add(&answer, command, None);
        }
        menu.append_section(None, &answer);
        let organize = gio::Menu::new();
        // Mark as Read while any is unread
        add(
            &organize,
            if summary.unread == 0 {
                Command::MarkUnread
            } else {
                Command::MarkRead
            },
            None,
        );
        // the colours and Clear Flag; the Flag Message toggle is the primary menu's, with its key
        organize.append_submenu(Some(&crate::words::plain(crate::words::Text::UiMenuFlag)), &flag_menu());
        // whether the conversations are watched or ignored: the check marks say it, as the list has no column for it
        for (command, on) in [
            (Command::WatchConversation, summary.watched),
            (Command::IgnoreConversation, summary.ignored),
        ] {
            let name = format!("{command:?}").to_lowercase();
            let action = gio::SimpleAction::new_stateful(&name, None, &on.to_variant());
            action.connect_activate(move |_, _| run_command(command));
            group.add_action(&action);
            organize.append(Some(command.label()), Some(&format!("message.{name}")));
        }
        add(&organize, Command::Archive, None);
        add(
            &organize,
            if summary.in_junk {
                Command::NotJunk
            } else {
                Command::Junk
            },
            None,
        );
        add(&organize, Command::Move, None);
        add(&organize, Command::Copy, None);
        add(&organize, Command::Delete, Some(&t!(UiTbDelete)));
        menu.append_section(None, &organize);
        let files = gio::Menu::new();
        add(&files, Command::SaveAs, None);
        add(&files, Command::Print, None);
        menu.append_section(None, &files);
        let details = gio::Menu::new();
        add(&details, Command::AddSenderToBook, None);
        add(
            &details,
            Command::ViewSource,
            Some(&crate::words::plain(crate::words::Text::UiMenuViewSource)),
        );
        add(&details, Command::Properties, None);
        menu.append_section(None, &details);
        widget.insert_action_group("message", Some(&group));
        *self.message_actions.borrow_mut() = Some(group);
        *self.message_popover.borrow_mut() = Some(popup_menu(widget, &menu, x, y));
    }

    /// Tools > Add Sender to Address Book: the sender of the message selected (or shown) into the book, said in the
    /// status bar
    pub async fn add_sender_to_book(&self) {
        let (folder, uid) = match self.selected_refs().as_slice() {
            [one] => (one.folder, one.uid),
            _ => (self.reader.folder(), self.reader.uid()),
        };
        if uid == 0 {
            ui::alert(&self.window, TITLE, &t!(UiSelectMessageFirst)).await;
            return;
        }
        match crate::address_book::add_sender(folder, uid) {
            Ok(said) => self.set_status(&said),
            Err(why) => ui::alert(&self.window, TITLE, &why).await,
        }
    }

    /// File > Print: the message as it is shown, with the pictures the user allowed, through the print dialog
    pub fn print_shown(&self) {
        self.reader.print(&self.window);
    }

    /// File > Import Messages: .eml files into the selected folder
    pub async fn import(&self) {
        let window = self.window.clone().upcast::<gtk::Window>();
        if self.folder.get() == 0 {
            ui::alert(&window, &import_title(), &t!(UiImportChooseFolder)).await;
            return;
        }
        let kind = t!(UiFilterMessages);
        let patterns = Some((kind.as_str(), &["*.eml"][..]));
        let files = ui::open_files(&window, &import_title(), patterns).await;
        self.import_files(&files).await;
    }

    async fn import_files(&self, files: &[std::path::PathBuf]) {
        self.import_into(self.folder.get(), files).await;
    }

    async fn import_into(&self, folder: i64, files: &[std::path::PathBuf]) {
        let report = match shell().core.import_files(folder, files) {
            Ok((said, report)) => {
                self.set_status(&said);
                report
            }
            Err(error) => Some(error.to_string()),
        };
        if let Some(report) = report {
            ui::alert(&self.window, &import_title(), &report).await;
        }
    }

    /// A message file opened with the app (from the file manager): into the selected folder, asked first
    pub async fn import_file(&self, file: &Path) {
        let folder = self.folder.get();
        let Some((folder_name, _)) = self.folder_names.borrow().get(&folder).cloned() else {
            ui::alert(&self.window, &import_title(), &t!(UiImportChooseFolder)).await;
            return;
        };
        let name = file
            .file_name()
            .map(|n| n.to_string_lossy().into_owned())
            .unwrap_or_default();
        let question = t!(GtkImportOneQuestion, file = &*name, folder = &*folder_name);
        if ui::confirm(&self.window, &import_title(), &question, false).await {
            self.import_files(&[file.to_path_buf()]).await;
        }
    }
}

/// Preferences > Group messages by conversation, on unless turned off
pub fn grouped() -> bool {
    shell().settings.bool(settings::GROUP_BY_CONVERSATION, true)
}

/// The list's view as the window starts: no folder, in the order `sort`, grouped and hiding ignored conversations as
/// the settings say
fn start_view(sort: pe_store::Sort) -> pe_core::ListView {
    let mut view = pe_core::ListView::new();
    view.set_sort(sort);
    view.set_grouped(grouped());
    view.set_hide_ignored(hide_ignored());
    view.set_show(show_for(hide_read()));
    view
}

/// View > Hide Read Messages, off unless turned on
pub fn hide_read() -> bool {
    shell().settings.bool(settings::HIDE_READ, false)
}

/// What the list shows with Hide Read Messages `on` or off
fn show_for(on: bool) -> pe_store::Show {
    if on {
        pe_store::Show::Unread
    } else {
        pe_store::Show::All
    }
}

/// The command of a letter in the message list, as in Thunderbird: A archives, N goes to the next unread message, W
/// watches and K ignores the conversation
pub fn list_key(key: gdk::Key, modifiers: gdk::ModifierType) -> Option<Command> {
    if !(modifiers - gdk::ModifierType::SHIFT_MASK).is_empty() {
        return None;
    }
    match key.to_lower() {
        gdk::Key::a => Some(Command::Archive),
        gdk::Key::n => Some(Command::NextUnread),
        gdk::Key::w => Some(Command::WatchConversation),
        gdk::Key::k => Some(Command::IgnoreConversation),
        _ => None,
    }
}

/// View > Folder List: the folder list beside the messages
pub fn folder_list_shown() -> bool {
    shell().settings.bool(settings::FOLDER_LIST, true)
}

/// View > Hide Ignored Conversations
pub fn hide_ignored() -> bool {
    shell().settings.bool(settings::HIDE_IGNORED, false)
}

/// The check mark a toggle of the menus starts with
fn toggled(command: Command) -> bool {
    match command {
        Command::Notify => shell().notify.get(),
        Command::HideIgnored => hide_ignored(),
        Command::HideRead => hide_read(),
        Command::FolderList => folder_list_shown(),
        _ => false,
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

/// A right-click menu of `menu` at (`x`, `y`) of `widget`, let go of once it closed
/// `menu` at `x`, `y` of `widget`, with the rows of the Flag menu where it has one (none is put in a menu without)
fn popup_menu(widget: &gtk::Widget, menu: &gio::Menu, x: f64, y: f64) -> gtk::PopoverMenu {
    let popover = gtk::PopoverMenu::from_model(Some(menu));
    flag_rows(&popover);
    popover.set_parent(widget);
    popover.set_has_arrow(false);
    popover.set_pointing_to(Some(&gdk::Rectangle::new(x as i32, y as i32, 1, 1)));
    let reopening = Rc::new(Cell::new(false));
    let kept = reopening.clone();
    popover.connect_closed(move |popover| {
        if kept.get() {
            return;
        }
        let popover = popover.clone();
        glib::idle_add_local_once(move || popover.unparent());
    });
    popover.popup();
    // opened again once GTK has put in the separators between the sections, which it does when idle: a popover keeps
    // the size it opened with, short by their height, which cuts off its last row
    let shown = popover.downgrade();
    glib::idle_add_local_once(move || {
        if let Some(popover) = shown.upgrade()
            && popover.is_visible()
        {
            reopening.set(true);
            popover.set_visible(false);
            popover.set_visible(true);
            reopening.set(false);
        }
    });
    popover
}

/// The header bar and the parts of it a narrow window leaves out or adds (`narrow_layout`)
struct HeaderParts {
    header: adw::HeaderBar,
    /// The folder's name in the header bar
    title: adw::WindowTitle,
    /// The Find box
    find: gtk::SearchEntry,
    junk: gtk::Button,
    create_mail: adw::SplitButton,
    send_receive: adw::SplitButton,
    edit_menu: gio::Menu,
    print: gtk::Button,
    archive: gtk::Button,
    reply_all: gtk::Button,
    forward: gtk::Button,
    /// Mark as Read and Mark as Unread
    read_state: gtk::Box,
    /// In a narrow window, in place of the folder list: the shown folder's name, the folder list in its popover
    folders: gtk::MenuButton,
    /// The folder's name on the folder button, which the title has in a wide window
    folder_name: gtk::Label,
    /// The sidebar button at the start: View > Folder List
    sidebar: gtk::ToggleButton,
    /// In a narrow window, in place of the Find box: a button for `search_bar`
    search: gtk::ToggleButton,
    /// In a narrow window, under the header bar: a Find box of its own, the same words
    search_bar: gtk::SearchBar,
}

/// The header bar: the toolbar's buttons in groups as Outlook Express has them (writing, answering, the message,
/// getting mail, read state), the folder's name, the Find box and the primary menu
fn header_bar(title: &adw::WindowTitle, find: &gtk::SearchEntry) -> HeaderParts {
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
        .tooltip_text(t!(UiTbCreateMail))
        .dropdown_tooltip(t!(GtkToolbarCreateMailMenu))
        .action_name(action(Command::NewMail))
        .build();
    let send_receive = adw::SplitButton::builder()
        .icon_name("ic-arrow-sync-symbolic")
        .tooltip_text(t!(UiTbSync))
        .dropdown_tooltip(t!(GtkToolbarSendRecvMenu))
        .action_name(action(Command::Sync))
        .build();
    let junk = button("ic-mail-prohibited-symbolic", &t!(UiTbJunk), Command::Junk);
    junk.set_widget_name("junk");
    let reply_all = button("ic-arrow-reply-all-symbolic", &t!(UiTbReplyAll), Command::ReplyAll);
    let forward = button("ic-arrow-forward-symbolic", &t!(UiTbForward), Command::Forward);
    let print = button("ic-print-symbolic", &t!(UiTbPrint), Command::Print);
    let archive = button("ic-archive-symbolic", &t!(UiTbArchive), Command::Archive);
    let (folders, folder_name) = folder_chooser(title);
    let sidebar = folder_list_button();
    let groups: Vec<Vec<gtk::Widget>> = vec![
        vec![sidebar.clone().upcast(), folders.clone().upcast()],
        vec![create_mail.clone().upcast()],
        vec![
            button("ic-arrow-reply-symbolic", &t!(UiTbReply), Command::Reply).upcast(),
            reply_all.clone().upcast(),
            forward.clone().upcast(),
        ],
        vec![
            print.clone().upcast(),
            button("ic-delete-symbolic", &t!(UiTbDelete), Command::Delete).upcast(),
            archive.clone().upcast(),
            junk.clone().upcast(),
        ],
        vec![send_receive.clone().upcast()],
        vec![
            button("ic-mail-read-symbolic", &t!(UiTbMarkRead), Command::MarkRead).upcast(),
            button("ic-mail-unread-symbolic", &t!(UiTbMarkUnread), Command::MarkUnread).upcast(),
        ],
    ];
    let mut read_state = None;
    for group in groups {
        let linked = gtk::Box::new(gtk::Orientation::Horizontal, 0);
        linked.set_margin_end(6);
        for widget in group {
            linked.append(&widget);
        }
        header.pack_start(&linked);
        read_state = Some(linked);
    }
    let read_state = read_state.expect("the toolbar's groups");
    let (primary, edit_menu) = primary_menu();
    // the submenus cascade, each a popover of its own: one sliding into the same popover would make it grow towards
    // the screen's edge after it was placed, and a window manager that does not place it again (Hyprland) cuts it off
    let popover = gtk::PopoverMenu::from_model_full(&primary, gtk::PopoverMenuFlags::NESTED);
    flag_rows(&popover);
    let menu = gtk::MenuButton::builder()
        .icon_name("open-menu-symbolic")
        .popover(&popover)
        .primary(true)
        .tooltip_text(t!(GtkMainMenu))
        .build();
    menu.set_widget_name("primary-menu");
    header.pack_end(&menu);
    header.pack_end(find);
    header.pack_end(&unread_only_button());
    let (search, search_bar) = narrow_search(find);
    header.pack_end(&search);
    HeaderParts {
        header,
        title: title.clone(),
        find: find.clone(),
        junk,
        create_mail,
        send_receive,
        edit_menu,
        print,
        archive,
        reply_all,
        forward,
        read_state,
        folders,
        folder_name,
        sidebar,
        search,
        search_bar,
    }
}

/// The header bar's sidebar button, at its start as GNOME's apps have it: View > Folder List
fn folder_list_button() -> gtk::ToggleButton {
    let icons = ["ic-panel-left-symbolic", "sidebar-show-symbolic"];
    command_toggle(
        &icons,
        Command::FolderList.label(),
        Command::FolderList,
        "folder-list-toggle",
    )
}

/// The header bar's filter beside Find: on, the list shows the unread messages only (View > Hide Read Messages, the
/// same action, so the two follow each other)
fn unread_only_button() -> gtk::ToggleButton {
    // the app's Fluent filter, else the system's
    let icons = ["ic-filter-symbolic", "funnel-symbolic", "view-filter-symbolic"];
    command_toggle(&icons, &t!(UiToolUnreadOnly), Command::HideRead, "hide-read")
}

/// A header bar button that turns a toggle of the menus on and off (the same action, so the two follow each other),
/// with the first of `icons` the theme has
fn command_toggle(icons: &[&str], label: &str, command: Command, name: &str) -> gtk::ToggleButton {
    let button = gtk::ToggleButton::builder()
        .child(&gtk::Image::from_gicon(&gio::ThemedIcon::from_names(icons)))
        .tooltip_text(label)
        .action_name(format!("win.{}", command.name()))
        .build();
    button.update_property(&[gtk::accessible::Property::Label(label)]);
    button.set_widget_name(name);
    button
}

/// The top rows of the folder tree the user closed, from the settings
fn closed_rows() -> std::collections::HashSet<i64> {
    shell()
        .settings
        .text(settings::CLOSED_ROWS)
        .unwrap_or_default()
        .split(',')
        .filter_map(|id| id.trim().parse().ok())
        .collect()
}

/// A top row opened or closed by the user, kept for the next start
fn remember_opened(id: i64, open: bool) {
    let mut closed = closed_rows();
    let changed = if open { closed.remove(&id) } else { closed.insert(id) };
    if changed {
        let mut ids: Vec<i64> = closed.into_iter().collect();
        ids.sort_unstable();
        let text = ids.iter().map(i64::to_string).collect::<Vec<_>>().join(",");
        shell()
            .settings
            .set_text(settings::CLOSED_ROWS, (!text.is_empty()).then_some(text.as_str()));
    }
}

/// A breakpoint's setter: an object, its property and the value it has at the breakpoint
pub type Setter = (glib::Object, &'static str, glib::Value);

/// What a narrower window leaves out, in three steps, so its controls fit the width a tiling window manager gives it
/// (half of a 1280 pixel wide screen and less) rather than being cut off. Each step keeps the commands the toolbar
/// loses in the primary menu and on their keys:
/// - up to 1000 points: no folder name in the title (the folder list shows it), no Print and no Mark as Read or Unread,
///   a shorter Find box, narrower From and Subject columns;
/// - up to 760: the folder list in the popover of a button that names the folder, the Find box in a bar under the
///   header bar that a search button opens, no Archive and Junk, no outgoing state in the status bar;
/// - up to 560: no Reply All and Forward either, and the dates short (today's time, older days' date).
///
/// The list's columns keep their date whole at each step; the Subject column takes what the others leave.
fn narrow_layout(
    window: &adw::ApplicationWindow,
    parts: &HeaderParts,
    folder_place: &Rc<FolderPlace>,
    status_bar: &gtk::Box,
    list: &Rc<MessageList>,
) {
    let (title, find) = (&parts.title, &parts.find);
    let hidden = false.to_value();
    let shown = true.to_value();
    // the outgoing state and the separator before it
    let outgoing: Vec<glib::Object> = status_bar
        .first_child()
        .and_then(|status| status.next_sibling())
        .into_iter()
        .flat_map(|separator| {
            let label = separator.next_sibling();
            std::iter::once(separator)
                .chain(label)
                .map(|widget| widget.upcast::<glib::Object>())
        })
        .collect();
    // a step's setters but the ones the next step sets its own way: the columns' widths and the Find box's
    let carried = |setters: &[Setter]| -> Vec<Setter> {
        setters
            .iter()
            .filter(|(object, property, _)| *property != "fixed-width" && object != find.upcast_ref::<glib::Object>())
            .cloned()
            .collect()
    };
    let mut medium: Vec<Setter> = vec![
        (title.clone().upcast(), "visible", hidden.clone()),
        (parts.print.clone().upcast(), "visible", hidden.clone()),
        (parts.read_state.clone().upcast(), "visible", hidden.clone()),
        (find.clone().upcast(), "width-chars", 14.to_value()),
    ];
    medium.extend(list.narrow_widths(1000));
    let mut narrow = carried(&medium);
    narrow.extend([
        (find.clone().upcast(), "visible", hidden.clone()),
        (parts.search.clone().upcast(), "visible", shown.clone()),
        (parts.archive.clone().upcast(), "visible", hidden.clone()),
        (parts.junk.clone().upcast(), "visible", hidden.clone()),
    ]);
    narrow.extend(outgoing.into_iter().map(|widget| (widget, "visible", hidden.clone())));
    // the counts as wide as their words, not the room kept for longer ones
    if let Some(counts) = status_bar.last_child() {
        narrow.push((counts.upcast(), "width-chars", (-1).to_value()));
    }
    narrow.extend(list.narrow_widths(760));
    let mut compact = carried(&narrow);
    compact.push((find.clone().upcast(), "visible", hidden.clone()));
    compact.extend(list.narrow_widths(560));
    compact.extend([
        (parts.reply_all.clone().upcast(), "visible", hidden.clone()),
        (parts.forward.clone().upcast(), "visible", hidden),
    ]);
    // the last of the breakpoints that hold is the one that applies
    let mut narrow_steps = Vec::new();
    for (width, setters) in [(1000, medium), (760, narrow), (560, compact)] {
        let condition = adw::BreakpointCondition::parse(&format!("max-width: {width}sp")).expect("a condition");
        let breakpoint = adw::Breakpoint::new(condition);
        for (widget, property, value) in &setters {
            breakpoint.add_setter(widget, property, Some(value));
        }
        if width <= 760 {
            narrow_steps.push(breakpoint.clone());
        }
        if width <= 560 {
            // the compact step's dates: the time of today's messages, the date of older ones
            let shown = list.clone();
            breakpoint.connect_apply(move |_| shown.set_compact_dates(true));
            let shown = list.clone();
            breakpoint.connect_unapply(move |_| shown.set_compact_dates(false));
        }
        window.add_breakpoint(breakpoint);
    }
    // the folder list in the folder button's popover at the narrow steps, beside the messages at the others (unless
    // View > Folder List put it there)
    let (place, search) = (folder_place.clone(), parts.search.clone());
    window.connect_current_breakpoint_notify(move |window| {
        let narrow = window
            .current_breakpoint()
            .is_some_and(|current| narrow_steps.contains(&current));
        if !narrow {
            search.set_active(false);
        }
        place.narrow.set(narrow);
        place.update();
    });
}

/// Where the folder list is: beside the messages, or in the popover of the folder button, in a narrow window and while
/// View > Folder List is off. The header bar's sidebar button turns the list on and off; a narrow window has the
/// folder button in its place
struct FolderPlace {
    tree: gtk::ScrolledWindow,
    panes: gtk::Paned,
    /// The folder button, its popover holding the list while it is not beside the messages
    button: gtk::MenuButton,
    /// The folder's name on it
    name: gtk::Label,
    sidebar: gtk::ToggleButton,
    /// A narrow step of `narrow_layout` holds
    narrow: Cell<bool>,
}

impl FolderPlace {
    fn update(&self) {
        let narrow = self.narrow.get();
        let in_popover = narrow || !folder_list_shown();
        self.sidebar.set_visible(!narrow);
        self.button.set_visible(in_popover);
        // the title names the folder in a wide window: the button shows the folder's name only where the title does
        // not
        self.name.set_visible(narrow);
        let Some(popover) = self.button.popover() else { return };
        if in_popover == self.tree.is_ancestor(&popover) {
            return;
        }
        if in_popover {
            self.panes.set_start_child(gtk::Widget::NONE);
            self.tree.set_propagate_natural_height(true);
            self.tree.set_max_content_height(480);
            self.tree.set_size_request(260, -1);
            popover.set_child(Some(&self.tree));
        } else {
            popover.set_child(gtk::Widget::NONE);
            self.tree.set_propagate_natural_height(false);
            self.tree.set_size_request(-1, -1);
            self.panes.set_start_child(Some(&self.tree));
        }
    }
}

/// The folder button of a narrow window: the folder's name as the title has it, the folder list in its popover
/// (`narrow_layout` moves the list there)
fn folder_chooser(title: &adw::WindowTitle) -> (gtk::MenuButton, gtk::Label) {
    let name = gtk::Label::builder()
        .ellipsize(gtk::pango::EllipsizeMode::End)
        .max_width_chars(16)
        .build();
    title.bind_property("title", &name, "label").sync_create().build();
    let content = gtk::Box::new(gtk::Orientation::Horizontal, 6);
    content.append(&gtk::Image::from_icon_name("ic-folder-symbolic"));
    content.append(&name);
    let popover = gtk::Popover::new();
    popover.set_widget_name("folder-list-popover");
    let button = gtk::MenuButton::builder()
        .child(&content)
        .always_show_arrow(true)
        .tooltip_text(t!(GtkFolderList))
        .popover(&popover)
        .visible(false)
        .build();
    button.set_widget_name("folder-list-button");
    button.update_property(&[gtk::accessible::Property::Label(&t!(GtkFolderList))]);
    (button, name)
}

/// The search of a narrow window: a button that opens a bar under the header bar, across the window, with a Find
/// box of its own that has the main one's words, both ways, so the main one (hidden) searches as before
fn narrow_search(find: &gtk::SearchEntry) -> (gtk::ToggleButton, gtk::SearchBar) {
    let entry = gtk::SearchEntry::builder()
        .placeholder_text(t!(UiFindHint))
        .hexpand(true)
        .build();
    entry.set_widget_name("find-narrow");
    entry.update_property(&[gtk::accessible::Property::Label(&t!(UiFindHint))]);
    find.bind_property("text", &entry, "text")
        .bidirectional()
        .sync_create()
        .build();
    let bar = gtk::SearchBar::builder().child(&entry).show_close_button(true).build();
    bar.connect_entry(&entry);
    bar.set_widget_name("find-narrow-bar");
    let button = gtk::ToggleButton::builder()
        .icon_name("ic-search-symbolic")
        .tooltip_text(t!(UiFindHint))
        .visible(false)
        .build();
    button.set_widget_name("find-narrow-button");
    button
        .bind_property("active", &bar, "search-mode-enabled")
        .bidirectional()
        .sync_create()
        .build();
    (button, bar)
}

/// The primary menu: the commands of the table by their menu (File, Edit, View, Tools, Message, Help), Quit last;
/// and its Edit submenu
fn primary_menu() -> (gio::Menu, gio::Menu) {
    let menu = gio::Menu::new();
    let sections = gio::Menu::new();
    let mut edit = gio::Menu::new();
    use crate::words::{Text, plain};
    for (id, name) in [
        ("file", Text::MenuFile),
        ("edit", Text::MenuEdit),
        ("view", Text::MenuView),
        ("tools", Text::MenuTools),
        ("message", Text::MenuMessage),
        ("help", Text::MenuHelp),
    ] {
        let submenu = command_menu(id);
        sections.append_submenu(Some(&plain(name)), &submenu);
        if id == "edit" {
            edit = submenu;
        }
    }
    menu.append_section(None, &sections);
    let preferences = gio::Menu::new();
    let item = gio::MenuItem::new(
        Some(&t!(GtkPreferences)),
        Some(&format!("win.{}", Command::Options.name())),
    );
    if let Some(accel) = Command::Options.accel() {
        item.set_attribute_value("accel", Some(&accel.to_variant()));
    }
    preferences.append_item(&item);
    menu.append_section(None, &preferences);
    let quit = gio::Menu::new();
    // GNOME names it Quit
    quit.append(Some(&t!(GtkQuit)), Some(&format!("win.{}", Command::Exit.name())));
    menu.append_section(None, &quit);
    (menu, edit)
}

/// A menu of the primary menu: the commands of the table that are in `id` ("message")
fn command_menu(id: &str) -> gio::Menu {
    let submenu = gio::Menu::new();
    // Quit and Preferences have the places GNOME gives them, at the end
    let elsewhere = [Command::Exit, Command::Options];
    for command in Command::ALL.iter().filter(|c| c.menu() == id && !elsewhere.contains(c)) {
        submenu.append_item(&menu_item(command.label(), *command));
        // the colours beside the flag
        if *command == Command::Flag {
            submenu.append_submenu(Some(&crate::words::plain(crate::words::Text::UiMenuFlag)), &flag_menu());
        }
    }
    submenu
}

/// The Flag menu's actions (window actions, so the primary menu and the message menu share them)
const FLAG_COLOR: &str = "flag-color";
const FLAG_CLEAR: &str = "flag-clear";

/// The Flag menu: Apple Mail's seven colours, each a row of its own (`flag_rows`) with the mark of the colour the
/// selection has, its flag and its name; then Clear Flag. (A popover menu shows no icon beside an item with a mark,
/// and no markup, so the rows are widgets.)
fn flag_menu() -> gio::Menu {
    let menu = gio::Menu::new();
    let colors = gio::Menu::new();
    for color in FlagColor::ALL {
        let item = gio::MenuItem::new(Some(pe_core::color_name(color)), None);
        item.set_attribute_value("custom", Some(&flag_row_id(color).to_variant()));
        colors.append_item(&item);
    }
    menu.append_section(None, &colors);
    let clear = gio::Menu::new();
    clear.append(
        Some(&crate::words::plain(crate::words::Text::UiClearFlag)),
        Some(&format!("win.{FLAG_CLEAR}")),
    );
    menu.append_section(None, &clear);
    menu
}

fn flag_row_id(color: FlagColor) -> String {
    format!("flag-{}", color as u8)
}

/// The rows of the Flag menu, put into a popover that shows `flag_menu`
fn flag_rows(popover: &gtk::PopoverMenu) {
    for color in FlagColor::ALL {
        popover.add_child(&flag_row(color), &flag_row_id(color));
    }
}

/// A colour of the Flag menu: the mark when the selected messages have it, its flag, its name
fn flag_row(color: FlagColor) -> gtk::Button {
    let check = gtk::Image::from_icon_name("object-select-symbolic");
    let swatch = gtk::DrawingArea::new();
    swatch.set_content_width(16);
    swatch.set_content_height(16);
    swatch.set_valign(gtk::Align::Center);
    swatch.set_draw_func(move |_, cr, _, _| crate::messages::draw_flag(cr, 0.0, 0.0, color));
    let label = gtk::Label::new(Some(pe_core::color_name(color)));
    label.set_xalign(0.0);
    label.set_hexpand(true);
    let row = gtk::Box::new(gtk::Orientation::Horizontal, 8);
    row.append(&check);
    row.append(&swatch);
    row.append(&label);
    let button = gtk::Button::builder()
        .child(&row)
        .has_frame(false)
        .action_name(format!("win.{FLAG_COLOR}"))
        .action_target(&i32::from(color as u8).to_variant())
        .build();
    button.add_css_class("flag-row");
    // the mark of the colour they have, read as the menu opens
    button.connect_map(move |button| {
        let marked = button
            .root()
            .and_downcast::<gtk::ApplicationWindow>()
            .and_then(|w| w.action_state(FLAG_COLOR))
            .and_then(|v| v.get::<i32>());
        check.set_opacity(if marked == Some(i32::from(color as u8)) {
            1.0
        } else {
            0.0
        });
    });
    // a menu closes once a row of it is chosen
    button.connect_clicked(|button| {
        let mut widget = button.parent();
        while let Some(w) = widget {
            if let Some(popover) = w.downcast_ref::<gtk::Popover>() {
                popover.popdown();
            }
            widget = w.parent();
        }
    });
    button
}

/// An item of the primary menu for `command`, under `label`; the keys of Select All and Undo shown as the others'
/// are, as they are no application accelerators (TEXT_KEYS)
fn menu_item(label: &str, command: Command) -> gio::MenuItem {
    let item = gio::MenuItem::new(Some(label), Some(&format!("win.{}", command.name())));
    if TEXT_KEYS.contains(&command)
        && let Some(accel) = command.accel()
    {
        item.set_attribute_value("accel", Some(&accel.to_variant()));
    }
    item
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
    // ready, as the status bar says when nothing is going on (and in a window made again in another language)
    status.set_text(&t!(UiDone));
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

/// The title of Import's windows: the command's name without its dots
fn import_title() -> String {
    crate::words::title(crate::words::Text::CmdImport)
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn letters_of_the_list() {
        let none = gdk::ModifierType::empty();
        assert_eq!(list_key(gdk::Key::w, none), Some(Command::WatchConversation));
        assert_eq!(
            list_key(gdk::Key::K, gdk::ModifierType::SHIFT_MASK),
            Some(Command::IgnoreConversation)
        );
        assert_eq!(list_key(gdk::Key::a, none), Some(Command::Archive));
        assert_eq!(list_key(gdk::Key::n, none), Some(Command::NextUnread));
        assert_eq!(list_key(gdk::Key::k, gdk::ModifierType::CONTROL_MASK), None);
        assert_eq!(list_key(gdk::Key::x, none), None);
    }
}
