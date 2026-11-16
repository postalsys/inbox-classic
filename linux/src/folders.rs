//! The folder list, drawn from the core's rows ([`TreeRow`]) in their order and depth: with one account its Inbox,
//! Flagged and its other folders; with several, All Inboxes (each account's Inbox under it), All Sent and All Drafts
//! (each account's folder under them), Flagged, and a heading for each account over its folders. A heading opens and closes (a click, Enter) and is never selected, so it is not taken
//! for a mailbox. A row with unread messages is bold with their count, as in Outlook Express; a collapsed one counts
//! what it hides. Messages dragged from the list are dropped onto the rows that take them. An account's heading, and
//! its Inbox's row under All Inboxes, are dragged among the rows of their kind to put the accounts in another order.
//! Which rows start open, and whose opening and closing the window keeps, the core says (All Inboxes, All Sent, All
//! Drafts and the headings).

use std::cell::{Cell, RefCell};
use std::collections::HashMap;
use std::rc::Rc;

use gtk::prelude::*;
use gtk::subclass::prelude::*;
use gtk::{gio, glib};
use pe_core::MessageRef;
use pe_core::tree::{TreeList, TreeRow, TreeRowKind};

mod imp {
    use super::*;

    #[derive(Default, glib::Properties)]
    #[properties(wrapper_type = super::FolderItem)]
    pub struct FolderItem {
        /// The label with its unread count, as Pango markup (bold with unread messages)
        #[property(get, set)]
        pub markup: RefCell<String>,
        #[property(get, set)]
        pub icon: RefCell<String>,
        /// What a screen reader says for it: the core's title ("Inbox - Work" under All Inboxes)
        #[property(get, set)]
        pub title: RefCell<String>,
        /// The core's row it shows
        pub row: RefCell<Option<TreeRow>>,
        pub expanded: Cell<bool>,
        pub children: RefCell<Option<gio::ListStore>>,
    }

    #[glib::object_subclass]
    impl ObjectSubclass for FolderItem {
        const NAME: &'static str = "IcFolderItem";
        type Type = super::FolderItem;
    }

    #[glib::derived_properties]
    impl ObjectImpl for FolderItem {}
}

glib::wrapper! {
    pub struct FolderItem(ObjectSubclass<imp::FolderItem>);
}

impl FolderItem {
    fn new(row: &TreeRow) -> FolderItem {
        let item: FolderItem = glib::Object::new();
        item.set_row(row);
        item
    }

    /// The row shown, again (its counts changed), and its label and icon with it
    fn set_row(&self, row: &TreeRow) {
        *self.imp().row.borrow_mut() = Some(row.clone());
        let icon = crate::move_dialog::kind_icon(row.icon);
        if self.icon() != icon {
            self.set_icon(icon);
        }
        if self.title() != row.title {
            self.set_title(row.title.as_str());
        }
        self.show();
    }

    /// The label: the name, with the unread count, bold, when there is one: its own while expanded, with what it
    /// hides while collapsed
    fn show(&self) {
        let Some(row) = self.row() else { return };
        let markup = label_markup(&row, row.parent && !self.imp().expanded.get());
        if self.markup() != markup {
            self.set_markup(markup);
        }
    }

    /// The core's row it shows
    pub fn row(&self) -> Option<TreeRow> {
        self.imp().row.borrow().clone()
    }

    pub fn id(&self) -> i64 {
        self.imp().row.borrow().as_ref().map_or(0, row_id)
    }

    fn add_child(&self, child: &FolderItem) {
        self.imp()
            .children
            .borrow_mut()
            .get_or_insert_with(gio::ListStore::new::<FolderItem>)
            .append(child);
    }
}

/// The id of All Inboxes: neither a folder (positive) nor an account (a negated id)
pub const ALL_INBOXES: i64 = i64::MIN;
/// The id of Flagged: the flagged messages of every account
pub const FLAGGED: i64 = i64::MIN + 1;
/// The id of All Sent: every account's Sent Items
pub const ALL_SENT: i64 = i64::MIN + 2;
/// The id of All Drafts: every account's Drafts
pub const ALL_DRAFTS: i64 = i64::MIN + 3;

/// The id the window knows a row by, kept in the settings for the rows opened or closed: a folder's id (a folder has
/// one row, under All Inboxes, All Sent or All Drafts or not), an account's negated, [`ALL_INBOXES`], [`ALL_SENT`],
/// [`ALL_DRAFTS`], [`FLAGGED`]; one for each of the core's keys
pub fn row_id(row: &TreeRow) -> i64 {
    list_id(row.list, row.folder, row.account)
}

/// The id of the row that lists `list`: of `folder` for a folder's own, an account's heading (`account`) for none
pub fn list_id(list: TreeList, folder: i64, account: i64) -> i64 {
    match list {
        TreeList::AllInboxes => ALL_INBOXES,
        TreeList::AllSent => ALL_SENT,
        TreeList::AllDrafts => ALL_DRAFTS,
        TreeList::Flagged => FLAGGED,
        TreeList::Folder => folder,
        TreeList::None => -account,
    }
}

/// The label of a row as Pango markup: its name, with the count when there is one (bold but for Flagged, which
/// counts flagged messages, not unread ones)
fn label_markup(row: &TreeRow, collapsed: bool) -> String {
    let count = row.shown(collapsed);
    let name = glib::markup_escape_text(&row.label);
    match (count, row.bold(collapsed)) {
        (0, _) => name.to_string(),
        // a heading is small and grey: the unread mail it hides is told in the text's full color, so it is not missed
        (count, true) if row.kind == TreeRowKind::Account => {
            format!("<b>{name} <span alpha=\"100%\">({count})</span></b>")
        }
        (count, true) => format!("<b>{name} ({count})</b>"),
        (count, false) => format!("{name} ({count})"),
    }
}

/// Whether a click (or Enter) opens and closes the row rather than selecting it: a heading, or a folder that can not
/// be selected with folders in it
fn toggles(row: &TreeRow) -> bool {
    !row.selectable && row.parent
}

type CanDrop = Box<dyn Fn(&[MessageRef], i64) -> bool>;
type Dropped = Box<dyn Fn(&[MessageRef], i64, bool)>;
type FilesDropped = Box<dyn Fn(i64, Vec<std::path::PathBuf>)>;
type Menu = Box<dyn Fn(&gtk::Widget, f64, f64, &TreeRow)>;
type Opened = Box<dyn Fn(&TreeRow, bool)>;
type Moved = Box<dyn Fn(i64, i64, bool)>;
type Selected = Box<dyn Fn(&TreeRow, bool)>;

/// What the tree tells the window: a row chosen, messages dropped onto a folder, and the accounts reordered
pub struct Handlers {
    /// A row selected: by the user (true; a click or a key, whose list loads after the tree has drawn the row), or
    /// from the app ([`FolderTree::select`] not `by_user`, listed at once)
    pub selected: Selected,
    /// Whether the messages dragged may go to folder `to`
    pub can_drop: CanDrop,
    /// The drop: the messages, the folder, and whether to copy (Ctrl held) rather than move
    pub dropped: Dropped,
    /// .eml files dropped onto folder `to` from outside the app, to put in it
    pub files_dropped: FilesDropped,
    /// The right-click menu at a point of the widget clicked, for the row clicked: selected first when it can be, a
    /// heading stays unselected
    pub menu: Menu,
    /// A row whose opening the core says is kept (All Inboxes, All Sent, All Drafts, a heading) opened or closed by
    /// the user, for the window to keep
    pub opened: Opened,
    /// An account's row dragged onto another of its kind: the account dragged, the account of the row it was dropped
    /// on, and whether below it (else above)
    pub moved: Moved,
}

/// An account's row dragged inside the tree: a type of its own, so no other program or row takes it
#[derive(Clone, Copy, Debug, PartialEq, Eq, glib::Boxed)]
#[boxed_type(name = "InboxClassicAccountRow")]
pub struct DraggedRow {
    pub id: i64,
    pub kind: TreeRowKind,
    pub account: i64,
}

impl DraggedRow {
    fn of(row: &TreeRow) -> Option<DraggedRow> {
        row.reorders_accounts.then(|| DraggedRow {
            id: row_id(row),
            kind: row.kind,
            account: row.account,
        })
    }
}

pub struct FolderTree {
    pub view: gtk::ListView,
    selection: gtk::SingleSelection,
    root: gio::ListStore,
    items: RefCell<HashMap<i64, FolderItem>>,
    /// The keys and depths of the rows in their order, to tell new counts from a list of other rows
    order: RefCell<Vec<(String, usize)>>,
    /// The parent of each item, to open the way to one that is selected from elsewhere
    parents: RefCell<HashMap<i64, i64>>,
    /// While the tree is built again its selection changes (and its rows opened) are not the user's
    reloading: Rc<Cell<bool>>,
    /// The item last selected: closing an account takes the selection off a folder it hides, which stays the one
    /// listed, and is selected again when the account opens
    last: Cell<i64>,
    /// While the app selects a row ([`FolderTree::select`] not `by_user`): not the user's choice
    selecting: Cell<bool>,
    handlers: Rc<RefCell<Option<Handlers>>>,
    /// A row at the top has rows under it: every row keeps the room of an arrow, so the icons line up; else the top
    /// rows start at the edge (one account's list, with no heading)
    arrows: Rc<Cell<bool>>,
}

impl FolderTree {
    pub fn new() -> Rc<FolderTree> {
        let root = gio::ListStore::new::<FolderItem>();
        let handlers: Rc<RefCell<Option<Handlers>>> = Rc::default();
        let reloading = Rc::new(Cell::new(false));
        let arrows = Rc::new(Cell::new(true));
        let tree = gtk::TreeListModel::new(root.clone(), false, false, |item| {
            item.downcast_ref::<FolderItem>()
                .and_then(|folder| folder.imp().children.borrow().clone())
                .map(|children| children.upcast())
        });
        connect_expanded(&tree, handlers.clone(), reloading.clone());
        let selection = gtk::SingleSelection::new(Some(tree));
        selection.set_autoselect(false);
        selection.set_can_unselect(true);
        let view = gtk::ListView::new(Some(selection.clone()), Some(factory(handlers.clone(), arrows.clone())));
        view.add_css_class("navigation-sidebar");
        view.set_widget_name("folder-tree");
        // Tab goes on to the next control, not through every row (the arrow keys move between them)
        view.set_tab_behavior(gtk::ListTabBehavior::Item);
        let this = Rc::new(FolderTree {
            view,
            selection,
            root,
            items: RefCell::default(),
            order: RefCell::default(),
            parents: RefCell::default(),
            reloading,
            last: Cell::new(0),
            selecting: Cell::new(false),
            handlers,
            arrows,
        });
        this.connect_selection();
        let weak = Rc::downgrade(&this);
        this.view.connect_activate(move |_, position| {
            if let Some(tree) = weak.upgrade() {
                tree.toggle_heading(position);
            }
        });
        this
    }

    /// The window told of the row the user selects; an account closed over the row selected and opened again selects
    /// it again
    fn connect_selection(self: &Rc<Self>) {
        let weak = Rc::downgrade(self);
        self.selection.connect_selection_changed(move |_, _, _| {
            let Some(tree) = weak.upgrade() else { return };
            if tree.reloading.get() {
                return;
            }
            // nothing selected: an account was closed over the folder shown, which stays shown
            let Some(row) = tree.selected_row() else { return };
            tree.last.set(row_id(&row));
            if let Some(handlers) = &*tree.handlers.borrow() {
                (handlers.selected)(&row, !tree.selecting.get());
            }
        });
        let weak = Rc::downgrade(self);
        self.selection.connect_items_changed(move |_, _, _, added| {
            let Some(tree) = weak.upgrade() else { return };
            if added == 0 || tree.reloading.get() || tree.selected() != 0 || tree.last.get() == 0 {
                return;
            }
            let weak = Rc::downgrade(&tree);
            glib::idle_add_local_once(move || {
                if let Some(tree) = weak.upgrade()
                    && tree.selected() == 0
                {
                    tree.reloading.set(true);
                    tree.select_shown(tree.last.get());
                    tree.reloading.set(false);
                }
            });
        });
    }

    pub fn set_handlers(&self, handlers: Handlers) {
        *self.handlers.borrow_mut() = Some(handlers);
    }

    /// The tree built again from the core's rows, nothing selected; each row with rows under it open or closed as
    /// `open` says (the user's choice kept, else as the core says it starts)
    pub fn rebuild(&self, rows: &[TreeRow], open: impl Fn(&TreeRow) -> bool) {
        self.reloading.set(true);
        let mut items = HashMap::new();
        let mut parents = HashMap::new();
        let mut top = Vec::new();
        // the last item at each depth, the parent of the next deeper one
        let mut chain: Vec<FolderItem> = Vec::new();
        for row in rows {
            let item = FolderItem::new(row);
            chain.truncate(row.depth.min(chain.len()));
            match chain.last() {
                Some(parent) => {
                    parent.add_child(&item);
                    parents.insert(item.id(), parent.id());
                }
                None => top.push(item.clone()),
            }
            chain.push(item.clone());
            items.insert(item.id(), item);
        }
        *self.order.borrow_mut() = rows.iter().map(|row| (row.key.clone(), row.depth)).collect();
        *self.items.borrow_mut() = items;
        *self.parents.borrow_mut() = parents;
        self.arrows.set(rows.iter().any(|row| row.depth == 0 && row.parent));
        self.root.splice(0, self.root.n_items(), &top);
        self.open_rows(open);
        self.selection.set_selected(gtk::INVALID_LIST_POSITION);
        self.reloading.set(false);
    }

    /// The rows with rows under them opened as `open` says; the rows inside a closed one are opened once it opens
    fn open_rows(&self, open: impl Fn(&TreeRow) -> bool) {
        let Some(model) = self.tree_model() else { return };
        let mut position = 0;
        while let Some(row) = model.row(position) {
            if let Some(item) = row.item().and_downcast::<FolderItem>()
                && item.row().is_some_and(|r| r.parent && open(&r))
            {
                row.set_expanded(true);
            }
            position += 1;
        }
    }

    /// The labels, titles, counts and bold of the core's rows shown again; false when they are other rows (other keys
    /// or depths, or in another order: the tree has to be built again)
    pub fn update(&self, rows: &[TreeRow]) -> bool {
        let same = rows.iter().map(|row| (row.key.as_str(), row.depth)).eq(self
            .order
            .borrow()
            .iter()
            .map(|(key, depth)| (key.as_str(), *depth)));
        if !same {
            return false;
        }
        let items = self.items.borrow();
        for row in rows {
            if let Some(item) = items.get(&row_id(row)) {
                item.set_row(row);
            }
        }
        true
    }

    /// The core's row of `id`
    pub fn row(&self, id: i64) -> Option<TreeRow> {
        self.items.borrow().get(&id).and_then(FolderItem::row)
    }

    /// The label of item `id` as it shows now, for the e2e driver
    #[cfg(feature = "e2e")]
    pub fn markup_of(&self, id: i64) -> Option<String> {
        self.items.borrow().get(&id).map(|item| item.markup())
    }

    /// The id of what is selected ([`row_id`]), 0 for nothing
    pub fn selected(&self) -> i64 {
        self.selected_row().as_ref().map_or(0, row_id)
    }

    /// The core's row selected
    pub fn selected_row(&self) -> Option<TreeRow> {
        self.selection
            .selected_item()
            .and_downcast::<gtk::TreeListRow>()
            .and_then(|row| row.item())
            .and_downcast::<FolderItem>()
            .and_then(|item| item.row())
    }

    /// Selects row `id`, the rows around it opened to it: listed at once, or as a click on it does (`by_user`), its
    /// list loaded after the tree has drawn it; false when there is none (the selection unchanged)
    pub fn select(&self, id: i64, by_user: bool) -> bool {
        let before = self.selecting.replace(!by_user);
        let selected = self.select_row(id);
        self.selecting.set(before);
        selected
    }

    fn select_row(&self, id: i64) -> bool {
        let Some(model) = self.tree_model() else { return false };
        if !self.items.borrow().contains_key(&id) {
            return false;
        }
        let mut ancestors = Vec::new();
        let mut at = id;
        while let Some(parent) = self.parents.borrow().get(&at).copied() {
            ancestors.push(parent);
            at = parent;
        }
        let mut position = 0;
        while let Some(row) = model.row(position) {
            let item_id = row.item().and_downcast::<FolderItem>().map_or(0, |item| item.id());
            if item_id == id {
                self.selection.set_selected(position);
                self.view.scroll_to(position, gtk::ListScrollFlags::NONE, None);
                return true;
            }
            // opened to show the row chosen from elsewhere, not by the user: not kept for the next start
            if ancestors.contains(&item_id) && !row.is_expanded() {
                let quiet = self.reloading.replace(true);
                row.set_expanded(true);
                self.reloading.set(quiet);
            }
            position += 1;
        }
        false
    }

    /// Selects item `id` when its row is in view, leaving closed accounts closed
    fn select_shown(&self, id: i64) {
        if let Some(position) = self.position_of(id) {
            self.selection.set_selected(position);
        }
    }

    /// The position of row `id` among the rows in view
    pub fn position_of(&self, id: i64) -> Option<u32> {
        let model = self.tree_model()?;
        let mut position = 0;
        while let Some(row) = model.row(position) {
            if row
                .item()
                .and_downcast::<FolderItem>()
                .is_some_and(|item| item.id() == id)
            {
                return Some(position);
            }
            position += 1;
        }
        None
    }

    /// Opens or closes the heading at `position`, when there is one there
    pub fn toggle_heading(&self, position: u32) {
        if let Some(row) = self.tree_model().and_then(|model| model.row(position))
            && row
                .item()
                .and_downcast::<FolderItem>()
                .and_then(|item| item.row())
                .is_some_and(|r| toggles(&r))
        {
            row.set_expanded(!row.is_expanded());
        }
    }

    /// The right-click menu of row `id` at (`x`, `y`) of `widget`, as a right-click opens it, for the e2e driver
    #[cfg(feature = "e2e")]
    pub fn open_menu(&self, widget: &gtk::Widget, x: f64, y: f64, id: i64) {
        if let (Some(row), Some(handlers)) = (self.row(id), &*self.handlers.borrow()) {
            (handlers.menu)(widget, x, y, &row);
        }
    }

    /// Row `id` opened or closed, as its arrow does it, for the e2e driver; false when it is not in view
    #[cfg(feature = "e2e")]
    pub fn set_open(&self, id: i64, open: bool) -> bool {
        let row = self
            .position_of(id)
            .and_then(|position| self.tree_model().and_then(|model| model.row(position)));
        row.is_some_and(|row| {
            row.set_expanded(open);
            true
        })
    }

    /// Whether row `id` is open, for the e2e driver
    #[cfg(feature = "e2e")]
    pub fn is_open(&self, id: i64) -> bool {
        self.position_of(id)
            .and_then(|position| self.tree_model().and_then(|model| model.row(position)))
            .is_some_and(|row| row.is_expanded())
    }

    /// Whether the row at `position` can be selected, for the e2e driver
    #[cfg(feature = "e2e")]
    pub fn selectable(&self, position: u32) -> bool {
        self.tree_model()
            .and_then(|model| model.row(position))
            .and_then(|row| row.item())
            .and_downcast::<FolderItem>()
            .and_then(|item| item.row())
            .is_some_and(|row| row.selectable)
    }

    /// The visible rows, as the e2e driver counts them
    #[cfg(feature = "e2e")]
    pub fn rows(&self) -> u32 {
        self.selection.n_items()
    }

    /// The rows in view, in their order: each one's id and how far in it is, for the e2e driver
    #[cfg(feature = "e2e")]
    pub fn shown(&self) -> Vec<(i64, u32)> {
        let Some(model) = self.tree_model() else {
            return Vec::new();
        };
        (0..model.n_items())
            .filter_map(|position| model.row(position))
            .map(|row| {
                let id = row.item().and_downcast::<FolderItem>().map_or(0, |item| item.id());
                (id, row.depth())
            })
            .collect()
    }

    /// Row `dragged` dropped above or below row `onto`, as a drag with the mouse does it, for the e2e driver
    #[cfg(feature = "e2e")]
    pub fn drop_row(&self, dragged: i64, onto: i64, below: bool) -> bool {
        let (Some(dragged), Some(onto)) = (self.row(dragged), self.row(onto)) else {
            return false;
        };
        let Some(dragged) = DraggedRow::of(&dragged).filter(|d| same_kind(d, &onto)) else {
            return false;
        };
        moved_later(&self.handlers, dragged.account, onto.account, below);
        true
    }

    /// The line a drag shows above or below row `id` (None: no line), for the e2e driver; false without the row
    #[cfg(feature = "e2e")]
    pub fn show_drop_line(&self, id: i64, below: Option<bool>) -> bool {
        let expander = crate::e2e::descendants::<gtk::TreeExpander>(self.view.upcast_ref())
            .into_iter()
            .find(|expander| {
                expander
                    .list_row()
                    .and_then(|row| row.item())
                    .and_downcast::<FolderItem>()
                    .is_some_and(|item| item.id() == id)
            });
        expander.is_some_and(|expander| {
            mark_drop(expander.upcast_ref(), below);
            true
        })
    }

    fn tree_model(&self) -> Option<gtk::TreeListModel> {
        self.selection.model().and_downcast::<gtk::TreeListModel>()
    }
}

/// A row opened or closed changes the rows after it: each item learns whether it is expanded, and shows the unread
/// messages it hides while it is not; the rows the core says keep their opening are told to the window when the user
/// opens or closes them
fn connect_expanded(tree: &gtk::TreeListModel, told: Rc<RefCell<Option<Handlers>>>, quiet: Rc<Cell<bool>>) {
    // only the row before the change (the one opened or closed) and the rows it added can have changed
    tree.connect_items_changed(move |model, position, _, added| {
        for index in position.saturating_sub(1)..position + added {
            let Some(row) = model.row(index) else { continue };
            let Some(item) = row.item().and_downcast::<FolderItem>() else {
                continue;
            };
            if item.imp().expanded.replace(row.is_expanded()) == row.is_expanded() {
                continue;
            }
            item.show();
            if !quiet.get()
                && let Some(r) = item.row().filter(|r| r.remembers_open)
                && let Some(handlers) = &*told.borrow()
            {
                (handlers.opened)(&r, row.is_expanded());
            }
        }
    });
}

/// Whether row `dragged` may be dropped beside row `onto`: headings among headings, rows under All Inboxes among
/// themselves, not onto itself
fn same_kind(dragged: &DraggedRow, onto: &TreeRow) -> bool {
    onto.reorders_accounts && dragged.kind == onto.kind && dragged.id != row_id(onto)
}

/// The window told of an account moved once the drop is over, as it builds the tree, and the row dropped, again
fn moved_later(handlers: &Rc<RefCell<Option<Handlers>>>, account: i64, beside: i64, below: bool) {
    let handlers = handlers.clone();
    glib::idle_add_local_once(move || {
        if let Some(handlers) = &*handlers.borrow() {
            (handlers.moved)(account, beside, below);
        }
    });
}

/// The rows: the expander, the icon and the name; a drop target for messages, the right-click menu. An account's row
/// is a heading: small and grey, without an icon, never selected; a click or Enter opens and closes it.
fn factory(handlers: Rc<RefCell<Option<Handlers>>>, arrows: Rc<Cell<bool>>) -> gtk::SignalListItemFactory {
    let factory = gtk::SignalListItemFactory::new();
    factory.connect_setup(move |_, item| {
        let Some(item) = item.downcast_ref::<gtk::ListItem>() else {
            return;
        };
        let icon = gtk::Image::new();
        let label = gtk::Label::new(None);
        label.set_use_markup(true);
        label.set_xalign(0.0);
        label.set_ellipsize(gtk::pango::EllipsizeMode::End);
        let row = gtk::Box::new(gtk::Orientation::Horizontal, 6);
        row.append(&icon);
        row.append(&label);
        let expander = gtk::TreeExpander::new();
        expander.set_child(Some(&row));
        item.set_child(Some(&expander));
        // the row, its folder's icon and label follow the item the list item shows, and later changes of the label
        // (the unread count) while it shows it
        let row_expression = item.property_expression("item");
        row_expression.bind(&expander, "list-row", gtk::Widget::NONE);
        let folder = row_expression.chain_property::<gtk::TreeListRow>("item");
        folder
            .chain_property::<FolderItem>("markup")
            .bind(&label, "label", gtk::Widget::NONE);
        folder
            .chain_property::<FolderItem>("icon")
            .bind(&icon, "icon-name", gtk::Widget::NONE);
        // a screen reader says the row's title, which names the account where the label alone does not
        folder
            .chain_property::<FolderItem>("title")
            .bind(item, "accessible-label", gtk::Widget::NONE);
        add_drop_target(&expander, item, handlers.clone());
        add_drag_source(&expander, item);
        add_row_drop_target(&expander, item, handlers.clone());
        add_clicks(&expander, item, handlers.clone());
    });
    // a heading: not selectable, activated (Enter) to open or close, in the heading style without an icon
    factory.connect_bind(move |_, item| {
        let Some(item) = item.downcast_ref::<gtk::ListItem>() else {
            return;
        };
        let Some(row) = row_of(item) else { return };
        let heading = row.kind == TreeRowKind::Account;
        item.set_selectable(row.selectable);
        item.set_activatable(toggles(&row));
        if let Some(expander) = item.child() {
            if let Some(expander) = expander.downcast_ref::<gtk::TreeExpander>() {
                expander.set_indent_for_icon(arrows.get());
            }
            crate::ui::set_class(&expander, "account-heading", heading);
            if let Some(icon) = expander
                .downcast_ref::<gtk::TreeExpander>()
                .and_then(|e| e.child())
                .and_then(|row| row.first_child())
            {
                icon.set_visible(!heading);
            }
        }
    });
    factory
}

/// The right-click menu of a row (the row selected first when it can be), and a click anywhere on a heading opening or
/// closing it, not only on its arrow
fn add_clicks(expander: &gtk::TreeExpander, item: &gtk::ListItem, handlers: Rc<RefCell<Option<Handlers>>>) {
    let click = gtk::GestureClick::new();
    click.set_button(gtk::gdk::BUTTON_SECONDARY);
    let weak_item = item.downgrade();
    click.connect_pressed(move |gesture, _, x, y| {
        let Some(item) = weak_item.upgrade() else { return };
        let Some(row) = row_of(&item) else { return };
        // the row under the mouse is the one the menu is for; a heading has its own menu and stays unselected
        if row.selectable
            && let Some(view) = gesture.widget().and_then(|w| w.ancestor(gtk::ListView::static_type()))
            && let Some(selection) = view.downcast_ref::<gtk::ListView>().and_then(|v| v.model())
        {
            selection.select_item(item.position(), true);
        }
        if let (Some(widget), Some(handlers)) = (gesture.widget(), &*handlers.borrow()) {
            (handlers.menu)(&widget, x, y, &row);
        }
    });
    expander.add_controller(click);
    let open = gtk::GestureClick::new();
    open.set_button(gtk::gdk::BUTTON_PRIMARY);
    let weak_item = item.downgrade();
    open.connect_released(move |gesture, _, _, _| {
        let Some(item) = weak_item.upgrade() else { return };
        if row_of(&item).is_some_and(|row| toggles(&row))
            && let Some(row) = item.item().and_downcast::<gtk::TreeListRow>()
        {
            row.set_expanded(!row.is_expanded());
            gesture.set_state(gtk::EventSequenceState::Claimed);
        }
    });
    expander.add_controller(open);
}

/// The core's row a list item shows
fn row_of(item: &gtk::ListItem) -> Option<TreeRow> {
    item.item()
        .and_downcast::<gtk::TreeListRow>()
        .and_then(|row| row.item())
        .and_downcast::<FolderItem>()
        .and_then(|folder| folder.row())
}

/// What is dropped onto a row that takes messages: messages dragged from the list (moved, copied with Ctrl), or .eml
/// files from a file manager (put in it, as Import does)
fn add_drop_target(widget: &gtk::TreeExpander, item: &gtk::ListItem, handlers: Rc<RefCell<Option<Handlers>>>) {
    let target = gtk::DropTarget::new(
        glib::Type::INVALID,
        gtk::gdk::DragAction::MOVE | gtk::gdk::DragAction::COPY,
    );
    // the app's own messages first: a drag from the list also offers them as files, for other programs
    target.set_types(&[
        crate::files::DraggedMessages::static_type(),
        gtk::gdk::FileList::static_type(),
    ]);
    target.set_preload(true);
    // the folder dropped on, when the row takes messages
    let folder_of = {
        let item = item.downgrade();
        move || {
            item.upgrade()
                .and_then(|item| row_of(&item))
                .filter(|row| row.drop_target)
                .map(|row| row.folder)
        }
    };
    let action_for = |target: &gtk::DropTarget| {
        if target
            .current_event_state()
            .contains(gtk::gdk::ModifierType::CONTROL_MASK)
        {
            gtk::gdk::DragAction::COPY
        } else {
            gtk::gdk::DragAction::MOVE
        }
    };
    // what a drop of `value` onto `folder` does: messages moved or copied, files put in it; None when it takes nothing
    let takes = move |handlers: &Handlers, value: &glib::Value, folder: i64, target: &gtk::DropTarget| {
        if let Ok(dragged) = value.get::<crate::files::DraggedMessages>() {
            return (handlers.can_drop)(&dragged.0, folder).then(|| action_for(target));
        }
        let files = crate::files::paths_of(&value.get::<gtk::gdk::FileList>().ok()?);
        crate::files::takes(&files).then_some(gtk::gdk::DragAction::COPY)
    };
    let can = handlers.clone();
    let folder = folder_of.clone();
    // a folder held over for a moment opens, to the folders in it
    let opening: Rc<RefCell<Option<glib::SourceId>>> = Rc::default();
    let open_later = opening.clone();
    let row_item = item.downgrade();
    target.connect_enter(move |_, _, _| {
        let row_item = row_item.clone();
        let done = open_later.clone();
        let id = glib::timeout_add_local_once(std::time::Duration::from_millis(800), move || {
            done.borrow_mut().take();
            if let Some(row) = row_item
                .upgrade()
                .and_then(|i| i.item())
                .and_downcast::<gtk::TreeListRow>()
            {
                row.set_expanded(true);
            }
        });
        if let Some(old) = open_later.borrow_mut().replace(id) {
            old.remove();
        }
        gtk::gdk::DragAction::empty()
    });
    let left = opening.clone();
    target.connect_leave(move |_| {
        if let Some(id) = left.borrow_mut().take() {
            id.remove();
        }
    });
    target.connect_motion(move |target, _, _| {
        let (Some(value), Some(folder), Some(handlers)) = (target.value(), folder(), &*can.borrow()) else {
            return gtk::gdk::DragAction::empty();
        };
        takes(handlers, &value, folder, target).unwrap_or(gtk::gdk::DragAction::empty())
    });
    target.connect_drop(move |target, value, _, _| {
        if let Some(id) = opening.borrow_mut().take() {
            id.remove();
        }
        let (Some(folder), Some(handlers)) = (folder_of(), &*handlers.borrow()) else {
            return false;
        };
        if takes(handlers, value, folder, target).is_none() {
            return false;
        }
        if let Ok(dragged) = value.get::<crate::files::DraggedMessages>() {
            let copy = action_for(target) == gtk::gdk::DragAction::COPY;
            (handlers.dropped)(&dragged.0, folder, copy);
        } else if let Ok(list) = value.get::<gtk::gdk::FileList>() {
            (handlers.files_dropped)(folder, crate::files::paths_of(&list));
        }
        true
    });
    widget.add_controller(target);
}

/// An account's heading or its Inbox's row under All Inboxes, dragged to put the account elsewhere; the row itself is
/// the picture that follows the mouse
fn add_drag_source(widget: &gtk::TreeExpander, item: &gtk::ListItem) {
    let source = gtk::DragSource::new();
    source.set_actions(gtk::gdk::DragAction::MOVE);
    let item = item.downgrade();
    source.connect_prepare(move |_, _, _| {
        let dragged = item
            .upgrade()
            .and_then(|item| row_of(&item))
            .and_then(|row| DraggedRow::of(&row))?;
        Some(gtk::gdk::ContentProvider::for_value(&dragged.to_value()))
    });
    let row = widget.downgrade();
    source.connect_drag_begin(move |source, _| {
        if let Some(row) = row.upgrade() {
            source.set_icon(Some(&gtk::WidgetPaintable::new(Some(&row))), 0, row.height() / 2);
        }
    });
    widget.add_controller(source);
}

/// What is dropped onto an account's row: another account's row of its kind, put above or below it by the half of
/// the row the mouse is over, with a line there while it is held over it
fn add_row_drop_target(widget: &gtk::TreeExpander, item: &gtk::ListItem, handlers: Rc<RefCell<Option<Handlers>>>) {
    let target = gtk::DropTarget::new(DraggedRow::static_type(), gtk::gdk::DragAction::MOVE);
    target.set_preload(true);
    let onto = {
        let item = item.downgrade();
        move || item.upgrade().and_then(|item| row_of(&item))
    };
    let below = |target: &gtk::DropTarget, y: f64| target.widget().is_some_and(|w| y > f64::from(w.height()) / 2.0);
    let dragged = |target: &gtk::DropTarget| target.value().and_then(|v| v.get::<DraggedRow>().ok());
    let over = onto.clone();
    target.connect_motion(move |target, _, y| {
        let Some(widget) = target.widget() else {
            return gtk::gdk::DragAction::empty();
        };
        let takes = dragged(target)
            .zip(over())
            .is_some_and(|(row, onto)| same_kind(&row, &onto));
        mark_drop(&widget, takes.then(|| below(target, y)));
        if takes {
            gtk::gdk::DragAction::MOVE
        } else {
            gtk::gdk::DragAction::empty()
        }
    });
    target.connect_leave(|target| {
        if let Some(widget) = target.widget() {
            mark_drop(&widget, None);
        }
    });
    target.connect_drop(move |target, value, _, y| {
        if let Some(widget) = target.widget() {
            mark_drop(&widget, None);
        }
        let (Ok(row), Some(onto)) = (value.get::<DraggedRow>(), onto()) else {
            return false;
        };
        if !same_kind(&row, &onto) {
            return false;
        }
        moved_later(&handlers, row.account, onto.account, below(target, y));
        true
    });
    widget.add_controller(target);
}

/// The line where a dragged row would go, above or below the row of `widget` (its list row, whose full width it
/// takes), or none
fn mark_drop(widget: &gtk::Widget, below: Option<bool>) {
    let Some(row) = widget.parent() else { return };
    for (class, shown) in [
        ("drop-above", below == Some(false)),
        ("drop-below", below == Some(true)),
    ] {
        crate::ui::set_class(&row, class, shown);
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    fn row(kind: TreeRowKind, account: i64, folder: i64) -> TreeRow {
        TreeRow {
            kind,
            key: String::new(),
            account,
            folder,
            depth: 0,
            label: "Inbox & more".into(),
            title: String::new(),
            unread: 0,
            hidden: 0,
            parent: false,
            selectable: kind != TreeRowKind::Account,
            drop_target: false,
            reorders_accounts: matches!(kind, TreeRowKind::Account | TreeRowKind::AccountInbox),
            menu: pe_core::tree::TreeMenu::Folder,
            list: match kind {
                TreeRowKind::AllInboxes => TreeList::AllInboxes,
                TreeRowKind::AllSent => TreeList::AllSent,
                TreeRowKind::AllDrafts => TreeList::AllDrafts,
                TreeRowKind::Flagged => TreeList::Flagged,
                TreeRowKind::Account => TreeList::None,
                TreeRowKind::AccountInbox | TreeRowKind::Folder => TreeList::Folder,
            },
            starts_open: true,
            remembers_open: false,
            new_folder_account: account,
            new_folder_parent: folder,
            icon: "",
        }
    }

    #[test]
    fn account_rows_go_among_their_kind() {
        let heading = |account| row(TreeRowKind::Account, account, 0);
        let inbox = |account, folder| row(TreeRowKind::AccountInbox, account, folder);
        let dragged = |r: &TreeRow| DraggedRow::of(r).expect("a row that moves");
        // headings among headings, rows under All Inboxes among themselves
        assert!(same_kind(&dragged(&heading(1)), &heading(2)));
        assert!(same_kind(&dragged(&inbox(1, 10)), &inbox(2, 20)));
        assert!(!same_kind(&dragged(&heading(1)), &inbox(2, 20)));
        assert!(!same_kind(&dragged(&inbox(1, 10)), &heading(2)));
        // not onto itself, a folder or All Inboxes; a folder is not dragged
        assert!(!same_kind(&dragged(&heading(1)), &heading(1)));
        assert!(!same_kind(&dragged(&heading(1)), &row(TreeRowKind::Folder, 2, 20)));
        assert!(!same_kind(&dragged(&inbox(1, 10)), &row(TreeRowKind::AllInboxes, 0, 0)));
        assert!(DraggedRow::of(&row(TreeRowKind::Folder, 1, 10)).is_none());
    }

    #[test]
    fn rows_keep_their_ids() {
        assert_eq!(row_id(&row(TreeRowKind::AllInboxes, 0, 0)), ALL_INBOXES);
        assert_eq!(row_id(&row(TreeRowKind::Flagged, 0, 0)), FLAGGED);
        assert_eq!(row_id(&row(TreeRowKind::AllSent, 0, 0)), ALL_SENT);
        assert_eq!(row_id(&row(TreeRowKind::AllDrafts, 0, 0)), ALL_DRAFTS);
        assert_eq!(row_id(&row(TreeRowKind::Account, 3, 0)), -3);
        assert_eq!(row_id(&row(TreeRowKind::Folder, 3, 7)), 7);
        // an Inbox has one row, under All Inboxes or not
        assert_eq!(row_id(&row(TreeRowKind::AccountInbox, 3, 7)), 7);
        // the ids of the rows of no folder are all different
        let fixed = [ALL_INBOXES, ALL_SENT, ALL_DRAFTS, FLAGGED];
        assert!(
            fixed
                .iter()
                .enumerate()
                .all(|(i, a)| fixed[i + 1..].iter().all(|b| a != b))
        );
    }

    #[test]
    fn labels_count_and_bold_as_the_core_says() {
        let mut folder = row(TreeRowKind::Folder, 1, 5);
        assert_eq!(label_markup(&folder, false), "Inbox &amp; more");
        folder.unread = 2;
        folder.hidden = 3;
        assert_eq!(label_markup(&folder, false), "<b>Inbox &amp; more (2)</b>");
        assert_eq!(label_markup(&folder, true), "<b>Inbox &amp; more (5)</b>");
        // Flagged counts flagged messages: never bold
        let mut flagged = row(TreeRowKind::Flagged, 0, 0);
        flagged.unread = 4;
        assert_eq!(label_markup(&flagged, false), "Inbox &amp; more (4)");
        // a heading counts what it hides only while closed
        let mut heading = row(TreeRowKind::Account, 1, 0);
        heading.hidden = 3;
        assert_eq!(label_markup(&heading, false), "Inbox &amp; more");
        // in the text's full color, not the heading's grey
        assert_eq!(
            label_markup(&heading, true),
            "<b>Inbox &amp; more <span alpha=\"100%\">(3)</span></b>"
        );
    }
}
