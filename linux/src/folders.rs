//! The folder tree: each account a heading over its folders, as the core lists them in tree order with their depth.
//! A heading opens and closes (a click, Enter) and is never selected, so it is not taken for a mailbox; All Inboxes,
//! above them, is a row like the folders, with each account's Inbox again under it (the same folder, a second row:
//! [`under_all_inboxes`]). A folder with unread messages is bold with their count, as in Outlook Express. Messages
//! dragged from the list are dropped onto a folder here. An account's heading, and its Inbox's row under All Inboxes,
//! are dragged among the rows of their kind to put the accounts in another order. Which of the top rows are open is the
//! window's to keep.

use std::cell::{Cell, RefCell};
use std::collections::HashMap;
use std::rc::Rc;

use gtk::prelude::*;
use gtk::subclass::prelude::*;
use gtk::{gio, glib};
use pe_core::MessageRef;

mod imp {
    use super::*;

    #[derive(Default, glib::Properties)]
    #[properties(wrapper_type = super::FolderItem)]
    pub struct FolderItem {
        /// The name with its unread count, as Pango markup (bold with unread messages)
        #[property(get, set)]
        pub markup: RefCell<String>,
        #[property(get, set)]
        pub icon: RefCell<String>,
        /// The folder's id, or an account's id negated for the account's own item
        pub id: Cell<i64>,
        /// The name, its own unread messages and those of the folders under it, which it shows while collapsed
        pub name: RefCell<String>,
        pub unread: Cell<u64>,
        pub below: Cell<u64>,
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
    fn new(entry: &Entry) -> FolderItem {
        let item: FolderItem = glib::Object::builder().property("icon", entry.icon).build();
        let imp = item.imp();
        imp.id.set(entry.id);
        *imp.name.borrow_mut() = entry.name.clone();
        imp.unread.set(entry.unread);
        imp.below.set(entry.below);
        item.show();
        item
    }

    /// The label: the name, with the unread count, bold, when there is one: its own while expanded, with what it
    /// hides while collapsed
    fn show(&self) {
        let imp = self.imp();
        let unread = imp.unread.get() + if imp.expanded.get() { 0 } else { imp.below.get() };
        let name = glib::markup_escape_text(&imp.name.borrow());
        let markup = if unread > 0 {
            format!("<b>{name} ({unread})</b>")
        } else {
            name.to_string()
        };
        if self.markup() != markup {
            self.set_markup(markup);
        }
    }

    pub fn id(&self) -> i64 {
        self.imp().id.get()
    }

    fn add_child(&self, child: &FolderItem) {
        self.imp()
            .children
            .borrow_mut()
            .get_or_insert_with(gio::ListStore::new::<FolderItem>)
            .append(child);
    }
}

/// The id of All Inboxes, at the top of the tree: neither a folder (positive) nor an account (a negated id)
pub const ALL_INBOXES: i64 = i64::MIN;

/// The mark of a row under All Inboxes in its id: the folder's id with this bit, positive as a folder's, never one
const UNDER_ALL_INBOXES: i64 = 1 << 62;

/// The id of folder `folder`'s row under All Inboxes
pub fn under_all_inboxes(folder: i64) -> i64 {
    folder | UNDER_ALL_INBOXES
}

/// Whether a row's id is one under All Inboxes
pub fn is_under_all_inboxes(id: i64) -> bool {
    id > 0 && id & UNDER_ALL_INBOXES != 0
}

/// The folder of a row: a folder's own id, the folder of a row under All Inboxes; other ids as they are
pub fn folder_of(id: i64) -> i64 {
    if id > 0 { id & !UNDER_ALL_INBOXES } else { id }
}

/// An item of the tree as it is built: its id, its name, its unread messages and those of the folders under it, the
/// icon and its depth under the account
pub struct Entry {
    pub id: i64,
    pub name: String,
    pub unread: u64,
    pub below: u64,
    pub icon: &'static str,
    pub depth: usize,
}

type CanDrop = Box<dyn Fn(&[MessageRef], i64) -> bool>;
type Dropped = Box<dyn Fn(&[MessageRef], i64, bool)>;
type FilesDropped = Box<dyn Fn(i64, Vec<std::path::PathBuf>)>;
type Menu = Box<dyn Fn(&gtk::Widget, f64, f64, i64)>;
type Opened = Box<dyn Fn(i64, bool)>;
type Moved = Box<dyn Fn(i64, i64, bool)>;

/// What the tree tells the window: a folder (or an account, negated) chosen, and messages dropped onto a folder
pub struct Handlers {
    pub selected: Box<dyn Fn(i64)>,
    /// Whether the messages dragged may go to folder `to`
    pub can_drop: CanDrop,
    /// The drop: the messages, the folder, and whether to copy (Ctrl held) rather than move
    pub dropped: Dropped,
    /// .eml files dropped onto folder `to` from outside the app, to put in it
    pub files_dropped: FilesDropped,
    /// The right-click menu at a point of the widget clicked, for the item clicked: the selected folder, or an
    /// account's heading (its id negated), which stays unselected
    pub menu: Menu,
    /// A top row (All Inboxes or an account's heading) opened or closed by the user, for the window to keep
    pub opened: Opened,
    /// An account's row dragged onto another of its kind: the row dragged, the row it was dropped on, and whether
    /// below it (else above)
    pub moved: Moved,
}

/// An account's row dragged inside the tree, by its id: a type of its own, so no other program or row takes it
#[derive(Clone, Copy, Debug, PartialEq, Eq, glib::Boxed)]
#[boxed_type(name = "InboxClassicAccountRow")]
pub struct DraggedRow(pub i64);

pub struct FolderTree {
    pub view: gtk::ListView,
    selection: gtk::SingleSelection,
    root: gio::ListStore,
    items: RefCell<HashMap<i64, FolderItem>>,
    /// The parent of each item, to open the way to one that is selected from elsewhere
    parents: RefCell<HashMap<i64, i64>>,
    /// While the tree is built again its selection changes (and its rows opened) are not the user's
    reloading: Rc<Cell<bool>>,
    /// The item last selected: closing an account takes the selection off a folder it hides, which stays the one
    /// listed, and is selected again when the account opens
    last: Cell<i64>,
    handlers: Rc<RefCell<Option<Handlers>>>,
}

impl FolderTree {
    pub fn new() -> Rc<FolderTree> {
        let root = gio::ListStore::new::<FolderItem>();
        let handlers: Rc<RefCell<Option<Handlers>>> = Rc::default();
        let reloading = Rc::new(Cell::new(false));
        let (told, quiet) = (handlers.clone(), reloading.clone());
        let tree = gtk::TreeListModel::new(root.clone(), false, false, |item| {
            item.downcast_ref::<FolderItem>()
                .and_then(|folder| folder.imp().children.borrow().clone())
                .map(|children| children.upcast())
        });
        // a row opened or closed changes the rows after it: each item learns whether it is expanded, and shows the
        // unread messages it hides while it is not
        // only the row before the change (the one opened or closed) and the rows it added can have changed
        tree.connect_items_changed(move |model, position, _, added| {
            for index in position.saturating_sub(1)..position + added {
                let Some(row) = model.row(index) else { continue };
                if let Some(item) = row.item().and_downcast::<FolderItem>()
                    && item.imp().expanded.replace(row.is_expanded()) != row.is_expanded()
                {
                    item.show();
                    // a top row the user opened or closed: the window keeps it
                    if row.depth() == 0
                        && !quiet.get()
                        && let Some(handlers) = &*told.borrow()
                    {
                        (handlers.opened)(item.id(), row.is_expanded());
                    }
                }
            }
        });
        let selection = gtk::SingleSelection::new(Some(tree));
        selection.set_autoselect(false);
        selection.set_can_unselect(true);
        let view = gtk::ListView::new(Some(selection.clone()), Some(factory(handlers.clone())));
        view.add_css_class("navigation-sidebar");
        view.set_widget_name("folder-tree");
        // Tab goes on to the next control, not through every row (the arrow keys move between them)
        view.set_tab_behavior(gtk::ListTabBehavior::Item);
        let this = Rc::new(FolderTree {
            view,
            selection,
            root,
            items: RefCell::default(),
            parents: RefCell::default(),
            reloading,
            last: Cell::new(0),
            handlers,
        });
        let weak = Rc::downgrade(&this);
        this.selection.connect_selection_changed(move |_, _, _| {
            if let Some(tree) = weak.upgrade()
                && !tree.reloading.get()
            {
                let id = tree.selected();
                // nothing selected: an account was closed over the folder shown, which stays shown
                if id == 0 {
                    return;
                }
                tree.last.set(id);
                if let Some(handlers) = &*tree.handlers.borrow() {
                    (handlers.selected)(id);
                }
            }
        });
        // an account opened again: the folder shown is selected again once its row is back
        let weak = Rc::downgrade(&this);
        this.selection.connect_items_changed(move |_, _, _, added| {
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
        let weak = Rc::downgrade(&this);
        this.view.connect_activate(move |_, position| {
            if let Some(tree) = weak.upgrade() {
                tree.toggle_heading(position);
            }
        });
        this
    }

    pub fn set_handlers(&self, handlers: Handlers) {
        *self.handlers.borrow_mut() = Some(handlers);
    }

    /// The tree built again from the accounts, each with its entries in tree order, under `top` (All Inboxes, with a
    /// row for each account's Inbox) when there is one; the top rows open but those in `closed`; the selection kept
    /// when its folder is still there (false when it is gone)
    pub fn rebuild(
        &self,
        top: Option<(Entry, Vec<Entry>)>,
        accounts: Vec<(Entry, Vec<Entry>)>,
        closed: &std::collections::HashSet<i64>,
    ) -> bool {
        let selected = self.selected();
        self.reloading.set(true);
        self.root.remove_all();
        let mut items = HashMap::new();
        let mut parents = HashMap::new();
        if let Some((entry, inboxes)) = top {
            let item = FolderItem::new(&entry);
            for inbox in inboxes {
                let child = FolderItem::new(&inbox);
                item.add_child(&child);
                parents.insert(inbox.id, entry.id);
                items.insert(inbox.id, child);
            }
            items.insert(entry.id, item.clone());
            self.root.append(&item);
        }
        for (account, folders) in accounts {
            let top = FolderItem::new(&account);
            items.insert(account.id, top.clone());
            // the last item at each depth, the parent of the next deeper one
            let mut chain = vec![top.clone()];
            for folder in folders {
                let depth = folder.depth.min(chain.len() - 1);
                let item = FolderItem::new(&folder);
                chain[depth].add_child(&item);
                parents.insert(folder.id, chain[depth].id());
                chain.truncate(depth + 1);
                chain.push(item.clone());
                items.insert(folder.id, item);
            }
            self.root.append(&top);
        }
        *self.items.borrow_mut() = items;
        *self.parents.borrow_mut() = parents;
        // the top rows open but those closed before, their folders as they come
        if let Some(model) = self.tree_model() {
            let mut position = 0;
            while let Some(row) = model.row(position) {
                if row.depth() == 0
                    && let Some(item) = row.item().and_downcast::<FolderItem>()
                    && !closed.contains(&item.id())
                {
                    row.set_expanded(true);
                }
                position += 1;
            }
        }
        let kept = selected != 0 && self.select(selected);
        if !kept {
            self.selection.set_selected(gtk::INVALID_LIST_POSITION);
        }
        self.reloading.set(false);
        kept || selected == 0
    }

    /// The unread messages of a folder (or an account, its id negated) changed; false when the tree does not have it
    /// (and has to be built again)
    pub fn update(&self, id: i64, unread: u64, below: u64) -> bool {
        let items = self.items.borrow();
        let Some(item) = items.get(&id) else {
            return false;
        };
        item.imp().unread.set(unread);
        item.imp().below.set(below);
        item.show();
        // an Inbox's row under All Inboxes counts the same, its subfolders being under the account only
        if let Some(again) = items.get(&under_all_inboxes(id)).filter(|_| id > 0) {
            again.imp().unread.set(unread);
            again.show();
        }
        true
    }

    /// The unread messages of row `id` and of the rows under it: an account's heading counts its folders'
    pub fn unread_within(&self, id: i64) -> u64 {
        self.items
            .borrow()
            .get(&id)
            .map_or(0, |item| item.imp().unread.get() + item.imp().below.get())
    }

    /// The label of item `id` as it shows now, for the e2e driver
    #[cfg(feature = "e2e")]
    pub fn markup_of(&self, id: i64) -> Option<String> {
        self.items.borrow().get(&id).map(|item| item.markup())
    }

    /// The id of what is selected: a folder, an account negated, [`ALL_INBOXES`], 0 for nothing
    pub fn selected(&self) -> i64 {
        self.selection
            .selected_item()
            .and_downcast::<gtk::TreeListRow>()
            .and_then(|row| row.item())
            .and_downcast::<FolderItem>()
            .map_or(0, |item| item.id())
    }

    /// Selects the item `id`, the folders around it opened to it; false when there is none (the selection unchanged)
    pub fn select(&self, id: i64) -> bool {
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
            if ancestors.contains(&item_id) {
                row.set_expanded(true);
            }
            position += 1;
        }
        false
    }

    /// Selects item `id` when its row is in view, leaving closed accounts closed
    fn select_shown(&self, id: i64) {
        let Some(model) = self.tree_model() else { return };
        let mut position = 0;
        while let Some(row) = model.row(position) {
            if row
                .item()
                .and_downcast::<FolderItem>()
                .is_some_and(|item| item.id() == id)
            {
                self.selection.set_selected(position);
                return;
            }
            position += 1;
        }
    }

    /// Opens or closes the account heading at `position`, when there is one there
    pub fn toggle_heading(&self, position: u32) {
        if let Some(row) = self.tree_model().and_then(|model| model.row(position))
            && row
                .item()
                .and_downcast::<FolderItem>()
                .is_some_and(|item| is_heading(item.id()))
        {
            row.set_expanded(!row.is_expanded());
        }
    }

    /// The position of the heading of account `id` (negated), for the e2e driver
    #[cfg(feature = "e2e")]
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

    /// Whether the row at `position` can be selected, for the e2e driver
    #[cfg(feature = "e2e")]
    pub fn selectable(&self, position: u32) -> bool {
        self.tree_model()
            .and_then(|model| model.row(position))
            .and_then(|row| row.item())
            .and_downcast::<FolderItem>()
            .is_some_and(|item| !is_heading(item.id()))
    }

    /// The id of the first row of the tree, for the e2e driver
    #[cfg(feature = "e2e")]
    pub fn top_id(&self) -> Option<i64> {
        self.root.item(0).and_downcast::<FolderItem>().map(|item| item.id())
    }

    /// The visible rows, as the e2e driver counts them
    #[cfg(feature = "e2e")]
    pub fn rows(&self) -> u32 {
        self.selection.n_items()
    }

    /// Row `dragged` dropped above or below row `onto`, as a drag with the mouse does it, for the e2e driver
    #[cfg(feature = "e2e")]
    pub fn drop_row(&self, dragged: i64, onto: i64, below: bool) -> bool {
        if !same_kind(dragged, onto) {
            return false;
        }
        moved_later(&self.handlers, dragged, onto, below);
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

/// Whether item `id` is an account's heading (an account's id negated), not a folder or All Inboxes
fn is_heading(id: i64) -> bool {
    id < 0 && id != ALL_INBOXES
}

/// Whether row `id` can be dragged to put its account elsewhere: an account's heading, an Inbox's row under All Inboxes
fn movable(id: i64) -> bool {
    is_heading(id) || is_under_all_inboxes(id)
}

/// Whether row `dragged` may be dropped beside row `onto`: headings among headings, rows under All Inboxes among
/// themselves, not onto itself
fn same_kind(dragged: i64, onto: i64) -> bool {
    dragged != onto && movable(dragged) && movable(onto) && is_heading(dragged) == is_heading(onto)
}

/// The window told of a row moved once the drop is over, as it builds the tree, and the row dropped, again
fn moved_later(handlers: &Rc<RefCell<Option<Handlers>>>, dragged: i64, onto: i64, below: bool) {
    let handlers = handlers.clone();
    glib::idle_add_local_once(move || {
        if let Some(handlers) = &*handlers.borrow() {
            (handlers.moved)(dragged, onto, below);
        }
    });
}

/// The rows: the expander, the icon and the name; a drop target for messages, the right-click menu. An account's row
/// is a heading: small and grey, without an icon, never selected; a click or Enter opens and closes it.
fn factory(handlers: Rc<RefCell<Option<Handlers>>>) -> gtk::SignalListItemFactory {
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
        expander.set_indent_for_icon(true);
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
        add_drop_target(&expander, item, handlers.clone());
        add_drag_source(&expander, item);
        add_row_drop_target(&expander, item, handlers.clone());
        let click = gtk::GestureClick::new();
        click.set_button(gtk::gdk::BUTTON_SECONDARY);
        let weak_item = item.downgrade();
        let menu_handlers = handlers.clone();
        click.connect_pressed(move |gesture, _, x, y| {
            let Some(item) = weak_item.upgrade() else { return };
            let id = item_id(&item);
            // the folder under the mouse is the one the menu is for; a heading has its own menu and stays unselected
            if !is_heading(id)
                && let Some(view) = gesture.widget().and_then(|w| w.ancestor(gtk::ListView::static_type()))
                && let Some(selection) = view.downcast_ref::<gtk::ListView>().and_then(|v| v.model())
            {
                selection.select_item(item.position(), true);
            }
            if let (Some(widget), Some(handlers)) = (gesture.widget(), &*menu_handlers.borrow()) {
                (handlers.menu)(&widget, x, y, id);
            }
        });
        expander.add_controller(click);
        // a click anywhere on a heading opens or closes it, not only on its arrow
        let open = gtk::GestureClick::new();
        open.set_button(gtk::gdk::BUTTON_PRIMARY);
        let weak_item = item.downgrade();
        open.connect_released(move |gesture, _, _, _| {
            let Some(item) = weak_item.upgrade() else { return };
            if is_heading(item_id(&item))
                && let Some(row) = item.item().and_downcast::<gtk::TreeListRow>()
            {
                row.set_expanded(!row.is_expanded());
                gesture.set_state(gtk::EventSequenceState::Claimed);
            }
        });
        expander.add_controller(open);
    });
    // a heading: not selectable, activated (Enter) to open or close, in the heading style without an icon
    factory.connect_bind(|_, item| {
        let Some(item) = item.downcast_ref::<gtk::ListItem>() else {
            return;
        };
        let heading = is_heading(item_id(item));
        item.set_selectable(!heading);
        item.set_activatable(heading);
        if let Some(expander) = item.child() {
            if heading {
                expander.add_css_class("account-heading");
            } else {
                expander.remove_css_class("account-heading");
            }
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

/// The id of the item a list item shows: a folder, an account negated, [`ALL_INBOXES`], 0 for none
fn item_id(item: &gtk::ListItem) -> i64 {
    item.item()
        .and_downcast::<gtk::TreeListRow>()
        .and_then(|row| row.item())
        .and_downcast::<FolderItem>()
        .map_or(0, |folder| folder.id())
}

/// What is dropped onto the row of a folder: messages dragged from the list (moved, copied with Ctrl), or .eml files
/// from a file manager (put in it, as Import does)
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
    let folder_of = {
        let item = item.downgrade();
        move || {
            item.upgrade()
                .and_then(|item| item.item())
                .and_downcast::<gtk::TreeListRow>()
                .and_then(|row| row.item())
                .and_downcast::<FolderItem>()
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
        (folder > 0 && crate::files::takes(&files)).then_some(gtk::gdk::DragAction::COPY)
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
        takes(handlers, &value, folder.id(), target).unwrap_or(gtk::gdk::DragAction::empty())
    });
    target.connect_drop(move |target, value, _, _| {
        if let Some(id) = opening.borrow_mut().take() {
            id.remove();
        }
        let (Some(folder), Some(handlers)) = (folder_of(), &*handlers.borrow()) else {
            return false;
        };
        if takes(handlers, value, folder.id(), target).is_none() {
            return false;
        }
        if let Ok(dragged) = value.get::<crate::files::DraggedMessages>() {
            let copy = action_for(target) == gtk::gdk::DragAction::COPY;
            (handlers.dropped)(&dragged.0, folder.id(), copy);
        } else if let Ok(list) = value.get::<gtk::gdk::FileList>() {
            (handlers.files_dropped)(folder.id(), crate::files::paths_of(&list));
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
        let id = item.upgrade().map_or(0, |item| item_id(&item));
        movable(id).then(|| gtk::gdk::ContentProvider::for_value(&DraggedRow(id).to_value()))
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
        move || item.upgrade().map_or(0, |item| item_id(&item))
    };
    let below = |target: &gtk::DropTarget, y: f64| target.widget().is_some_and(|w| y > f64::from(w.height()) / 2.0);
    let dragged = |target: &gtk::DropTarget| target.value().and_then(|v| v.get::<DraggedRow>().ok());
    let over = onto.clone();
    target.connect_motion(move |target, _, y| {
        let Some(widget) = target.widget() else {
            return gtk::gdk::DragAction::empty();
        };
        let takes = dragged(target).is_some_and(|row| same_kind(row.0, over()));
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
        let (Ok(row), id) = (value.get::<DraggedRow>(), onto()) else {
            return false;
        };
        if !same_kind(row.0, id) {
            return false;
        }
        moved_later(&handlers, row.0, id, below(target, y));
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
        if shown {
            row.add_css_class(class);
        } else {
            row.remove_css_class(class);
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn account_rows_go_among_their_kind() {
        // headings among headings, rows under All Inboxes among themselves
        assert!(same_kind(-1, -2));
        assert!(same_kind(under_all_inboxes(10), under_all_inboxes(20)));
        assert!(!same_kind(-1, under_all_inboxes(20)));
        assert!(!same_kind(under_all_inboxes(10), -2));
        // not onto itself, a folder or All Inboxes; a folder is not dragged
        assert!(!same_kind(-1, -1));
        assert!(!same_kind(-1, 20));
        assert!(!same_kind(under_all_inboxes(10), ALL_INBOXES));
        assert!(!same_kind(10, 20));
    }
}
