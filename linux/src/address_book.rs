//! Tools > Address Book: the groups on the left (All Contacts first), the people of the one selected on the right
//! (Name, E-mail, Phone), New Contact, New Group, Properties, Delete and Write To in the header bar with a find box,
//! and the File menu's Import and Export of vCard and CSV files. The book is the core's (`pe_core::book`): this
//! window lists what it gives and hands back what the user typed.

use std::cell::{Cell, RefCell};
use std::rc::Rc;

use adw::prelude::*;
use gtk::{gdk, gio, glib};
use pe_core::book::{BookRow, group_label};
use pe_store::{CardId, GroupId};

use crate::app::{shell, spawn};
use crate::commands::Command;
use crate::ui::{self, TITLE};
use crate::words::{self, Text};

/// A menu label of the catalogs as a GTK menu shows it: no mnemonic mark, an ellipsis for the dots
pub fn menu_label(text: Text) -> String {
    words::plain(text).replace("...", "…")
}

pub struct Book {
    pub window: adw::ApplicationWindow,
    groups: gtk::ListBox,
    /// The group of each row of `groups` after All Contacts
    group_ids: RefCell<Vec<GroupId>>,
    store: gio::ListStore,
    selection: gtk::MultiSelection,
    pub view: gtk::ColumnView,
    pub find: gtk::SearchEntry,
    empty: gtk::Label,
    /// The lists are being filled: their signals are not the user's
    filling: Cell<bool>,
}

thread_local! {
    static BOOK: RefCell<Option<Rc<Book>>> = const { RefCell::new(None) };
}

/// The Address Book window when it is open
pub fn shown() -> Option<Rc<Book>> {
    BOOK.with(|book| book.borrow().clone())
}

/// Tools > Address Book: the window in front, opened when it is not
pub fn open() {
    if let Some(book) = shown() {
        book.window.present();
        return;
    }
    let book = Book::new();
    BOOK.with(|cell| *cell.borrow_mut() = Some(book.clone()));
    book.window.present();
    book.view.grab_focus();
}

/// What the window shows read again (a sender added, a file imported)
pub fn refresh() {
    if let Some(book) = shown() {
        book.reload();
    }
}

/// The window's actions, `win.<name>`: the header bar's buttons, its menu, the right-click menus and the keys
const NEW_CONTACT: &str = "book-new-contact";
const NEW_GROUP: &str = "book-new-group";
/// The name the main window's Properties has, so Alt+Return opens Properties here too
const PROPERTIES: &str = "properties";
const DELETE: &str = "book-delete";
const WRITE_TO: &str = "book-write-to";

fn text_column(title: &str, width: i32, expand: bool, text: fn(&BookRow) -> &str) -> gtk::ColumnViewColumn {
    let factory = gtk::SignalListItemFactory::new();
    factory.connect_setup(|_, item| {
        if let Some(item) = item.downcast_ref::<gtk::ListItem>() {
            let label = gtk::Label::new(None);
            label.set_xalign(0.0);
            label.set_ellipsize(gtk::pango::EllipsizeMode::End);
            add_menu(&label, item);
            item.set_child(Some(&label));
        }
    });
    factory.connect_bind(move |_, item| {
        let Some(item) = item.downcast_ref::<gtk::ListItem>() else {
            return;
        };
        let (Some(label), Some(row)) = (
            item.child().and_downcast::<gtk::Label>(),
            item.item().and_downcast::<glib::BoxedAnyObject>(),
        ) else {
            return;
        };
        label.set_text(text(&row.borrow::<BookRow>()));
    });
    let column = gtk::ColumnViewColumn::new(Some(title), Some(factory));
    column.set_fixed_width(width);
    column.set_expand(expand);
    column.set_resizable(true);
    column
}

/// A right click on a person: the row selected, unless it is one of those selected, and the menu of the selection
fn add_menu(widget: &impl IsA<gtk::Widget>, item: &gtk::ListItem) {
    let click = gtk::GestureClick::new();
    click.set_button(gdk::BUTTON_SECONDARY);
    let item = item.downgrade();
    click.connect_pressed(move |gesture, _, x, y| {
        let (Some(item), Some(widget), Some(book)) = (item.upgrade(), gesture.widget(), shown()) else {
            return;
        };
        if !book.selection.is_selected(item.position()) {
            book.selection.select_item(item.position(), true);
        }
        book.menu(&widget, x, y);
    });
    widget.add_controller(click);
}

/// A row of the group list: its icon, its name and, for a group, how many are in it
fn group_row(icon: &str, name: &str, count: Option<usize>, widget_name: &str) -> gtk::ListBoxRow {
    let image = gtk::Image::from_icon_name(icon);
    let title = gtk::Label::new(Some(name));
    title.set_xalign(0.0);
    title.set_ellipsize(gtk::pango::EllipsizeMode::End);
    let labels = gtk::Box::new(gtk::Orientation::Vertical, 0);
    labels.set_valign(gtk::Align::Center);
    labels.append(&title);
    if let Some(count) = count {
        let more = gtk::Label::new(Some(&t!(UiGroupMembersCount, count = count as u64)));
        more.set_xalign(0.0);
        more.add_css_class("dim-label");
        more.add_css_class("caption");
        labels.append(&more);
    }
    let content = gtk::Box::new(gtk::Orientation::Horizontal, 10);
    content.append(&image);
    content.append(&labels);
    let row = gtk::ListBoxRow::new();
    row.set_child(Some(&content));
    row.set_widget_name(widget_name);
    row
}

impl Book {
    fn new() -> Rc<Book> {
        let shell = shell();
        let groups = gtk::ListBox::new();
        groups.add_css_class("navigation-sidebar");
        groups.set_widget_name("book-groups");
        let store = gio::ListStore::new::<glib::BoxedAnyObject>();
        let selection = gtk::MultiSelection::new(Some(store.clone()));
        let view = gtk::ColumnView::new(Some(selection.clone()));
        view.set_widget_name("book-people");
        // Tab goes on to the next control, not through every row (the arrow keys move between them)
        view.set_tab_behavior(gtk::ListTabBehavior::Item);
        view.add_css_class("message-list");
        view.append_column(&text_column(&t!(UiColName), 220, true, |p| &p.name));
        view.append_column(&text_column(&t!(UiColEmail), 240, true, |p| &p.address));
        view.append_column(&text_column(&t!(UiColPhone), 150, false, |p| &p.phone));
        let find = gtk::SearchEntry::new();
        find.set_placeholder_text(Some(&t!(UiBookFindHint)));
        find.set_widget_name("book-find");
        find.set_width_chars(26);
        let empty = gtk::Label::new(None);
        empty.set_wrap(true);
        empty.set_justify(gtk::Justification::Center);
        empty.set_max_width_chars(48);
        empty.set_halign(gtk::Align::Center);
        empty.set_valign(gtk::Align::Start);
        empty.set_margin_top(72);
        empty.set_margin_start(24);
        empty.set_margin_end(24);
        empty.set_can_target(false);
        empty.add_css_class("dim-label");
        empty.set_widget_name("book-empty");
        let people = gtk::ScrolledWindow::builder()
            .child(&view)
            .hexpand(true)
            .vexpand(true)
            .build();
        let overlay = gtk::Overlay::new();
        overlay.set_child(Some(&people));
        overlay.add_overlay(&empty);
        let side = gtk::ScrolledWindow::builder()
            .child(&groups)
            .hscrollbar_policy(gtk::PolicyType::Never)
            .vexpand(true)
            .build();
        let paned = gtk::Paned::new(gtk::Orientation::Horizontal);
        paned.set_start_child(Some(&side));
        paned.set_end_child(Some(&overlay));
        paned.set_position(210);
        paned.set_shrink_start_child(false);
        paned.set_resize_start_child(false);
        crate::ui::tab_leaves(&groups, &find, &view);
        let header = header_bar(&find);
        let toolbar = adw::ToolbarView::new();
        toolbar.add_top_bar(&header);
        toolbar.set_content(Some(&paned));
        let window = adw::ApplicationWindow::builder()
            .application(&shell.application)
            .title(words::title(Text::CmdAddressBook))
            .default_width(920)
            .default_height(600)
            .content(&toolbar)
            .icon_name(crate::APP_ID)
            .build();
        window.set_widget_name("book-window");
        let book = Rc::new(Book {
            window,
            groups,
            group_ids: RefCell::default(),
            store,
            selection,
            view,
            find,
            empty,
            filling: Cell::new(false),
        });
        book.install_actions();
        book.connect();
        book.reload();
        book
    }

    fn install_actions(self: &Rc<Self>) {
        let add = |name: &str, run: fn(Rc<Book>)| {
            let action = gio::SimpleAction::new(name, None);
            let this = Rc::downgrade(self);
            action.connect_activate(move |_, _| {
                if let Some(this) = this.upgrade() {
                    run(this);
                }
            });
            self.window.add_action(&action);
        };
        add(NEW_CONTACT, |this| spawn(async move { this.new_contact().await }));
        add(NEW_GROUP, |this| spawn(async move { this.new_group().await }));
        add(PROPERTIES, |this| spawn(async move { this.properties().await }));
        add(DELETE, |this| spawn(async move { this.delete().await }));
        add(WRITE_TO, |this| spawn(async move { this.write_to().await }));
        add(Command::ImportAddressBook.name(), |this| {
            spawn(async move { import(this.window.upcast_ref()).await })
        });
        add(Command::ExportAddressBook.name(), |this| {
            spawn(async move { export(this.window.upcast_ref()).await })
        });
        // F1, as in every window
        add(Command::Help.name(), |_| crate::help::show("address-book"));
    }

    fn connect(self: &Rc<Self>) {
        let this = Rc::downgrade(self);
        self.groups.connect_row_selected(move |_, _| {
            if let Some(this) = this.upgrade()
                && !this.filling.get()
            {
                this.fill_people();
            }
        });
        let this = Rc::downgrade(self);
        self.find.connect_search_changed(move |_| {
            if let Some(this) = this.upgrade() {
                this.fill_people();
            }
        });
        let this = Rc::downgrade(self);
        self.selection.connect_selection_changed(move |_, _, _| {
            if let Some(this) = this.upgrade() {
                this.update_actions();
            }
        });
        let window = self.window.clone();
        self.view.connect_activate(move |_, _| {
            WidgetExt::activate_action(&window, &format!("win.{PROPERTIES}"), None).ok();
        });
        let window = self.window.clone();
        self.groups.connect_row_activated(move |_, row| {
            if row.index() > 0 {
                WidgetExt::activate_action(&window, &format!("win.{PROPERTIES}"), None).ok();
            }
        });
        self.connect_menus();
        // Delete in either list, Ctrl+F the find box, Ctrl+W closes
        let keys = |target: &gtk::Widget, group: bool| {
            let controller = gtk::EventControllerKey::new();
            let this = Rc::downgrade(self);
            controller.connect_key_pressed(move |_, key, _, modifiers| {
                if key == gdk::Key::Delete
                    && modifiers.is_empty()
                    && let Some(this) = this.upgrade()
                {
                    spawn(async move { this.delete_from(group).await });
                    return glib::Propagation::Stop;
                }
                glib::Propagation::Proceed
            });
            target.add_controller(controller);
        };
        keys(self.view.upcast_ref(), false);
        keys(self.groups.upcast_ref(), true);
        let shortcuts = gtk::ShortcutController::new();
        shortcuts.set_scope(gtk::ShortcutScope::Managed);
        let find = self.find.downgrade();
        shortcuts.add_shortcut(gtk::Shortcut::new(
            gtk::ShortcutTrigger::parse_string("<Primary>f"),
            Some(gtk::CallbackAction::new(move |_, _| {
                if let Some(find) = find.upgrade() {
                    find.grab_focus();
                }
                glib::Propagation::Stop
            })),
        ));
        let window = self.window.downgrade();
        shortcuts.add_shortcut(gtk::Shortcut::new(
            gtk::ShortcutTrigger::parse_string("<Primary>w"),
            Some(gtk::CallbackAction::new(move |_, _| {
                if let Some(window) = window.upgrade() {
                    window.close();
                }
                glib::Propagation::Stop
            })),
        ));
        self.window.add_controller(shortcuts);
        self.window.connect_close_request(|_| {
            BOOK.with(|book| book.borrow_mut().take());
            glib::Propagation::Proceed
        });
    }

    /// The right-click menu of the group list (the people's is on their cells, `add_menu`)
    fn connect_menus(self: &Rc<Self>) {
        let click = gtk::GestureClick::new();
        click.set_button(gdk::BUTTON_SECONDARY);
        let this = Rc::downgrade(self);
        click.connect_pressed(move |gesture, _, x, y| {
            let (Some(this), Some(widget)) = (this.upgrade(), gesture.widget()) else {
                return;
            };
            let Some(row) = this.groups.row_at_y(y as i32) else {
                return;
            };
            if row.index() == 0 {
                return;
            }
            this.groups.select_row(Some(&row));
            // the menu of the group, not of people selected in it
            this.selection.unselect_all();
            this.menu(&widget, x, y);
        });
        self.groups.add_controller(click);
    }

    fn menu(&self, widget: &gtk::Widget, x: f64, y: f64) {
        let menu = gio::Menu::new();
        let first = gio::Menu::new();
        first.append(Some(Command::Properties.label()), Some(&format!("win.{PROPERTIES}")));
        first.append(Some(&menu_label(Text::UiMenuWriteTo)), Some(&format!("win.{WRITE_TO}")));
        menu.append_section(None, &first);
        let second = gio::Menu::new();
        second.append(Some(&menu_label(Text::UiMenuDelete)), Some(&format!("win.{DELETE}")));
        menu.append_section(None, &second);
        let popover = gtk::PopoverMenu::from_model(Some(&menu));
        popover.set_parent(widget);
        popover.set_has_arrow(false);
        popover.set_halign(gtk::Align::Start);
        popover.set_pointing_to(Some(&gdk::Rectangle::new(x as i32, y as i32, 1, 1)));
        popover.connect_closed(|popover| {
            let popover = popover.clone();
            glib::idle_add_local_once(move || popover.unparent());
        });
        popover.popup();
    }

    // ---- what is shown ----

    /// The groups and the people read again, the group selected kept
    pub fn reload(&self) {
        let kept = self.selected_group();
        let groups = shell().core.groups("").unwrap_or_default();
        self.filling.set(true);
        while let Some(row) = self.groups.first_child() {
            self.groups.remove(&row);
        }
        self.groups.append(&group_row(
            "x-office-address-book-symbolic",
            &t!(UiBookAllContacts),
            None,
            "book-all",
        ));
        for group in &groups {
            let name = format!("book-group-{}", group.id);
            self.groups.append(&group_row(
                "system-users-symbolic",
                &group.name,
                Some(group.members.len()),
                &name,
            ));
        }
        *self.group_ids.borrow_mut() = groups.iter().map(|g| g.id).collect();
        let index = kept
            .and_then(|id| groups.iter().position(|g| g.id == id))
            .map_or(0, |i| i + 1);
        self.groups.select_row(self.groups.row_at_index(index as i32).as_ref());
        self.filling.set(false);
        self.fill_people();
    }

    /// The group selected on the left, None for All Contacts
    pub fn selected_group(&self) -> Option<GroupId> {
        let index = self.groups.selected_row()?.index();
        if index <= 0 {
            return None;
        }
        self.group_ids.borrow().get(index as usize - 1).copied()
    }

    /// Selects All Contacts (0) or the group of row `index`, for the UI test
    #[cfg(feature = "e2e")]
    pub fn select_group_row(&self, index: i32) {
        self.groups.select_row(self.groups.row_at_index(index).as_ref());
    }

    /// All Contacts selected, without filling the people for it (the caller does)
    fn select_all_contacts(&self) {
        self.filling.set(true);
        self.groups.select_row(self.groups.row_at_index(0).as_ref());
        self.filling.set(false);
    }

    /// The people of the group selected, or of the whole book, found by the find box
    fn fill_people(&self) {
        let core = &shell().core;
        let filter = self.find.text().trim().to_string();
        let people = match self.selected_group() {
            None => core.card_rows(&filter),
            Some(id) => core.group_people(id, &filter),
        }
        .unwrap_or_default();
        let objects: Vec<glib::BoxedAnyObject> = people.into_iter().map(glib::BoxedAnyObject::new).collect();
        self.store.splice(0, self.store.n_items(), &objects);
        let empty = if !objects.is_empty() {
            None
        } else if !filter.is_empty() {
            Some(t!(UiBookNoMatch, words = &filter))
        } else if self.selected_group().is_none() {
            Some(t!(UiBookEmpty))
        } else {
            None
        };
        self.empty.set_visible(empty.is_some());
        self.empty.set_text(&empty.unwrap_or_default());
        self.update_actions();
    }

    /// The people listed, for the UI test
    #[cfg(feature = "e2e")]
    pub fn people(&self) -> Vec<BookRow> {
        (0..self.store.n_items()).filter_map(|i| self.row(i)).collect()
    }

    /// The person of row `index`
    fn row(&self, index: u32) -> Option<BookRow> {
        let item = self.store.item(index).and_downcast::<glib::BoxedAnyObject>()?;
        Some(item.borrow::<BookRow>().clone())
    }

    /// Whether row `index` is a card (not an address typed into a group)
    fn is_card(&self, index: u32) -> bool {
        self.store
            .item(index)
            .and_downcast::<glib::BoxedAnyObject>()
            .is_some_and(|item| item.borrow::<BookRow>().card != 0)
    }

    /// What the empty list says, when it says something (the UI test)
    #[cfg(feature = "e2e")]
    pub fn empty_text(&self) -> Option<String> {
        self.empty.is_visible().then(|| self.empty.text().to_string())
    }

    #[cfg(feature = "e2e")]
    pub fn select_person(&self, index: u32) {
        self.selection.select_item(index, true);
    }

    fn selected_people(&self) -> Vec<BookRow> {
        (0..self.store.n_items())
            .filter(|&i| self.selection.is_selected(i))
            .filter_map(|i| self.row(i))
            .collect()
    }

    /// Properties, Delete and Write To on while there is something to act on: people selected, or a group
    fn update_actions(&self) {
        let selected = self.selection.selection();
        let any = !selected.is_empty();
        let one = selected.size() == 1 && self.is_card(selected.minimum());
        let group = self.selected_group().is_some();
        for (name, on) in [
            (PROPERTIES, one || group),
            (DELETE, any || group),
            (WRITE_TO, any || group),
        ] {
            if let Some(action) = self.window.lookup_action(name).and_downcast::<gio::SimpleAction>() {
                action.set_enabled(on);
            }
        }
    }

    // ---- the commands ----

    async fn new_contact(self: Rc<Self>) {
        if let Some(id) = crate::book_dialogs::contact(&self.window, 0).await {
            // the new one shown and selected, in the whole book
            self.find.set_text("");
            self.select_all_contacts();
            self.reload();
            self.select_card(id);
        }
    }

    async fn new_group(self: Rc<Self>) {
        if let Some(id) = crate::book_dialogs::group(&self.window, 0).await {
            self.reload();
            self.select_group(id);
        }
    }

    fn select_card(&self, id: CardId) {
        let found = (0..self.store.n_items()).find(|&i| {
            self.store
                .item(i)
                .and_downcast::<glib::BoxedAnyObject>()
                .is_some_and(|item| item.borrow::<BookRow>().card == id)
        });
        if let Some(index) = found {
            self.selection.select_item(index, true);
            self.view.scroll_to(index, None, gtk::ListScrollFlags::FOCUS, None);
        }
    }

    fn select_group(&self, id: GroupId) {
        if let Some(index) = self.group_ids.borrow().iter().position(|g| *g == id) {
            self.groups
                .select_row(self.groups.row_at_index(index as i32 + 1).as_ref());
        }
    }

    /// Properties of the one person selected, else of the group selected
    async fn properties(self: Rc<Self>) {
        let people = self.selected_people();
        if let [person] = people.as_slice()
            && person.card != 0
        {
            let id = person.card;
            if crate::book_dialogs::contact(&self.window, id).await.is_some() {
                self.reload();
                self.select_card(id);
            }
            return;
        }
        if let Some(id) = self.selected_group()
            && crate::book_dialogs::group(&self.window, id).await.is_some()
        {
            self.reload();
        }
    }

    async fn delete(self: Rc<Self>) {
        self.delete_from(false).await;
    }

    /// Delete: the people selected out of the book (an address typed into the group out of the group), or with none
    /// selected, or from the group list, the group; asked first
    async fn delete_from(self: Rc<Self>, groups: bool) {
        let core = &shell().core;
        let people = if groups { Vec::new() } else { self.selected_people() };
        if people.is_empty() {
            let Some(id) = self.selected_group() else { return };
            let Ok(Some(group)) = core.group(id) else { return };
            let ask = t!(UiGroupDeleteAsk, name = &group.name);
            if ui::confirm(&self.window, TITLE, &ask, true).await {
                let _ = core.delete_group(id);
                self.select_all_contacts();
                self.reload();
            }
            return;
        }
        let ask = t!(UiBookDeleteAsk, count = people.len() as u64);
        if !ui::confirm(&self.window, TITLE, &ask, true).await {
            return;
        }
        let first = self.selection.selection().minimum();
        let cards: Vec<CardId> = people.iter().map(|p| p.card).filter(|id| *id != 0).collect();
        // an address of no card leaves the group it was typed into
        let typed: Vec<String> = people
            .iter()
            .filter(|p| p.card == 0)
            .map(|p| p.address.clone())
            .collect();
        if let Err(error) = core.delete_from_book(self.selected_group(), &cards, &typed) {
            ui::alert(&self.window, TITLE, &pe_core::sentence(&error.to_string())).await;
        }
        self.reload();
        // the next one selected, where the first deleted was
        let count = self.store.n_items();
        if count > 0 {
            self.selection.select_item(first.min(count - 1), true);
        }
    }

    /// Write To: a new message to the people selected, or to the group's members
    async fn write_to(self: Rc<Self>) {
        let people = self.selected_people();
        let labels: Vec<String> = if people.is_empty() {
            self.selected_group()
                .and_then(|id| shell().core.group(id).ok().flatten())
                .map(|g| group_label(&g))
                .into_iter()
                .filter(|l| !l.is_empty())
                .collect()
        } else {
            people
                .iter()
                .map(|p| p.label.clone())
                .filter(|l| !l.is_empty())
                .collect()
        };
        if labels.is_empty() {
            let name = people.first().map(|p| p.name.clone()).unwrap_or_default();
            ui::alert(&self.window, TITLE, &t!(UiBookNoAddress, name = &name)).await;
            return;
        }
        let account = shell().main().current_account();
        if account == 0 {
            ui::alert(&self.window, TITLE, &t!(UiAddAccountFirst)).await;
            return;
        }
        let to = pe_core::book::add_to_field("", &labels.join(", "));
        crate::compose::open(
            account,
            Some(pe_core::Draft {
                to,
                ..Default::default()
            }),
        );
    }
}

/// The header bar: New Contact and New Group, Properties and Delete, Write To; the find box and the menu with Import
/// and Export
fn header_bar(find: &gtk::SearchEntry) -> adw::HeaderBar {
    let header = adw::HeaderBar::new();
    let button = |icon: &str, tooltip: &str, action: &str| {
        let button = ui::icon_button(icon, tooltip);
        // the focus stays in the list the button acts on
        button.set_focus_on_click(false);
        button.set_action_name(Some(&format!("win.{action}")));
        button.set_widget_name(action);
        button
    };
    let groups: [Vec<gtk::Button>; 3] = [
        vec![
            button("contact-new-symbolic", &t!(UiTbNewContact), NEW_CONTACT),
            button("system-users-symbolic", &t!(UiTbNewGroup), NEW_GROUP),
        ],
        vec![
            button("document-properties-symbolic", &t!(UiTbProperties), PROPERTIES),
            button("ic-delete-symbolic", &t!(UiTbDelete), DELETE),
        ],
        vec![button("ic-mail-add-symbolic", &t!(UiTbWriteTo), WRITE_TO)],
    ];
    for group in groups {
        let linked = gtk::Box::new(gtk::Orientation::Horizontal, 0);
        linked.set_margin_end(6);
        for button in group {
            linked.append(&button);
        }
        header.pack_start(&linked);
    }
    let menu = gio::Menu::new();
    let new = gio::Menu::new();
    new.append(
        Some(&menu_label(Text::UiMenuNewContact)),
        Some(&format!("win.{NEW_CONTACT}")),
    );
    new.append(
        Some(&menu_label(Text::UiMenuNewGroup)),
        Some(&format!("win.{NEW_GROUP}")),
    );
    menu.append_section(None, &new);
    let files = gio::Menu::new();
    for command in [Command::ImportAddressBook, Command::ExportAddressBook] {
        files.append(Some(command.label()), Some(&format!("win.{}", command.name())));
    }
    menu.append_section(None, &files);
    let menu_button = gtk::MenuButton::builder()
        .icon_name("open-menu-symbolic")
        .menu_model(&menu)
        .primary(true)
        .tooltip_text(t!(GtkMainMenu))
        .build();
    menu_button.set_widget_name("book-menu");
    header.pack_end(&menu_button);
    header.pack_end(find);
    header
}

// ---- Add Sender, Import, Export ----

/// The sender of message `uid` of `folder` into the book: the words for the status bar, or why it could not be
pub fn add_sender(folder: i64, uid: u64) -> Result<String, String> {
    let core = &shell().core;
    match core.add_sender(folder, uid) {
        Ok(done) if done.card == 0 => Err(done.status),
        Ok(done) => {
            refresh();
            Ok(done.status)
        }
        Err(pe_core::Error::NotFound) => Err(t!(UiSenderNone)),
        Err(error) => Err(error.to_string()),
    }
}

/// File > Import Address Book: vCard and CSV files into the book, with what was added and left out
pub async fn import(parent: &gtk::Window) {
    let title = words::title(Text::CmdImportAddressBook);
    let kind = t!(UiFilterAddressBooks);
    let patterns = ["*.vcf", "*.VCF", "*.vcard", "*.csv", "*.CSV"];
    let files = ui::open_files(parent, &title, Some((kind.as_str(), &patterns[..]))).await;
    if files.is_empty() {
        return;
    }
    let done = shell().core.import_cards(&files);
    // the book shows them before the words do
    refresh();
    if !done.failed.is_empty() {
        let said = t!(UiBookNotImported, reason = &done.failures());
        ui::alert(parent, &title, &said).await;
        if done.added + done.skipped == 0 {
            return;
        }
    }
    let said = t!(UiBookImported, added = done.added, skipped = done.skipped);
    ui::alert(parent, &title, &said).await;
}

/// File > Export Address Book: every contact to a vCard file
pub async fn export(parent: &gtk::Window) {
    let title = words::title(Text::CmdExportAddressBook);
    let name = format!("{}.vcf", t!(UiBookExportName));
    let kind = t!(UiFilterVcard);
    let Some(path) = ui::save_file(parent, &title, &name, Some((kind.as_str(), &["*.vcf"][..]))).await else {
        return;
    };
    let said = match shell().core.export_cards(&[], &path) {
        Ok(count) => {
            let file = path
                .file_name()
                .map(|n| n.to_string_lossy().into_owned())
                .unwrap_or_default();
            t!(UiBookExported, count = count, file = &file)
        }
        Err(error) => t!(UiBookNotExported, reason = &error.to_string()),
    };
    ui::alert(parent, &title, &said).await;
}
