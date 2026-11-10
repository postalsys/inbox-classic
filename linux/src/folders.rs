//! The folder tree: each account a heading over its folders, as the core lists them in tree order with their depth.
//! A heading opens and closes (a click, Enter) and is never selected, so it is not taken for a mailbox; All Inboxes,
//! above them, is a row like the folders. A folder with unread messages is bold with their count, as in Outlook
//! Express. Messages dragged from the list are dropped onto a folder here.

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
}

pub struct FolderTree {
    pub view: gtk::ListView,
    selection: gtk::SingleSelection,
    root: gio::ListStore,
    items: RefCell<HashMap<i64, FolderItem>>,
    /// The parent of each item, to open the way to one that is selected from elsewhere
    parents: RefCell<HashMap<i64, i64>>,
    /// While the tree is built again its selection changes are not the user's
    reloading: Cell<bool>,
    /// The item last selected: closing an account takes the selection off a folder it hides, which stays the one
    /// listed, and is selected again when the account opens
    last: Cell<i64>,
    handlers: Rc<RefCell<Option<Handlers>>>,
}

impl FolderTree {
    pub fn new() -> Rc<FolderTree> {
        let root = gio::ListStore::new::<FolderItem>();
        let tree = gtk::TreeListModel::new(root.clone(), false, false, |item| {
            item.downcast_ref::<FolderItem>()
                .and_then(|folder| folder.imp().children.borrow().clone())
                .map(|children| children.upcast())
        });
        // a row opened or closed changes the rows after it: each item learns whether it is expanded, and shows the
        // unread messages it hides while it is not
        // only the row before the change (the one opened or closed) and the rows it added can have changed
        tree.connect_items_changed(|model, position, _, added| {
            for index in position.saturating_sub(1)..position + added {
                let Some(row) = model.row(index) else { continue };
                if let Some(item) = row.item().and_downcast::<FolderItem>()
                    && item.imp().expanded.replace(row.is_expanded()) != row.is_expanded()
                {
                    item.show();
                }
            }
        });
        let selection = gtk::SingleSelection::new(Some(tree));
        selection.set_autoselect(false);
        selection.set_can_unselect(true);
        let handlers: Rc<RefCell<Option<Handlers>>> = Rc::default();
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
            reloading: Cell::new(false),
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

    /// The tree built again from the accounts, each with its entries in tree order, under `top` (All Inboxes) when
    /// there is one; the selection kept when its folder is still there (false when it is gone)
    pub fn rebuild(&self, top: Option<Entry>, accounts: Vec<(Entry, Vec<Entry>)>) -> bool {
        let selected = self.selected();
        self.reloading.set(true);
        self.root.remove_all();
        let mut items = HashMap::new();
        let mut parents = HashMap::new();
        if let Some(entry) = top {
            let item = FolderItem::new(&entry);
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
        // the accounts open, their folders as they come
        if let Some(model) = self.tree_model() {
            let mut position = 0;
            while let Some(row) = model.row(position) {
                if row.depth() == 0 {
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
        match self.items.borrow().get(&id) {
            Some(item) => {
                item.imp().unread.set(unread);
                item.imp().below.set(below);
                item.show();
                true
            }
            None => false,
        }
    }

    /// The label of item `id` as it shows now, for the e2e driver
    #[cfg(feature = "e2e")]
    pub fn markup_of(&self, id: i64) -> Option<String> {
        self.items.borrow().get(&id).map(|item| item.markup())
    }

    /// Opens or closes the row of item `id` as a click on its expander would, for the e2e driver
    #[cfg(feature = "e2e")]
    pub fn set_expanded(&self, id: i64, expanded: bool) {
        let Some(model) = self.tree_model() else { return };
        let mut position = 0;
        while let Some(row) = model.row(position) {
            if row
                .item()
                .and_downcast::<FolderItem>()
                .is_some_and(|item| item.id() == id)
            {
                row.set_expanded(expanded);
                return;
            }
            position += 1;
        }
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

    fn tree_model(&self) -> Option<gtk::TreeListModel> {
        self.selection.model().and_downcast::<gtk::TreeListModel>()
    }
}

/// Whether item `id` is an account's heading (an account's id negated), not a folder or All Inboxes
fn is_heading(id: i64) -> bool {
    id < 0 && id != ALL_INBOXES
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
