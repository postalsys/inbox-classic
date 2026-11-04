//! The message list: a column view over a list model that pages through the core, 100 rows at a time, as the virtual
//! list view of the Windows app does. The columns as Outlook Express has them: the envelope (read or not), the paper
//! clip, the flag, From, Subject, Received, Size, and Folder while a search lists several folders. Unread messages in
//! bold. Every string comes from the core as it decoded it.

use std::cell::{Cell, RefCell};
use std::rc::Rc;

use gtk::prelude::*;
use gtk::subclass::prelude::*;
use gtk::{gdk, gio, glib};
use pe_store::{Message, Sort, SortField};

use crate::app::shell;

const PAGE: u32 = 100;
/// Pages kept while the list scrolls, the least recently used dropped first
const PAGES_KEPT: usize = 8;

mod imp {
    use super::*;

    #[derive(Default)]
    pub struct MessageRow {
        pub message: RefCell<Option<Message>>,
    }

    #[glib::object_subclass]
    impl ObjectSubclass for MessageRow {
        const NAME: &'static str = "IcMessageRow";
        type Type = super::MessageRow;
    }

    impl ObjectImpl for MessageRow {}

    #[derive(Default)]
    pub struct MessageModel {
        pub search: RefCell<pe_core::Search>,
        pub sort: Cell<Sort>,
        pub total: Cell<u32>,
        /// Whether the list lists anything (an account's own item lists nothing)
        pub active: Cell<bool>,
        pub pages: RefCell<Vec<(u32, Vec<super::MessageRow>)>>,
    }

    #[glib::object_subclass]
    impl ObjectSubclass for MessageModel {
        const NAME: &'static str = "IcMessageModel";
        type Type = super::MessageModel;
        type Interfaces = (gio::ListModel,);
    }

    impl ObjectImpl for MessageModel {}

    impl ListModelImpl for MessageModel {
        fn item_type(&self) -> glib::Type {
            super::MessageRow::static_type()
        }

        fn n_items(&self) -> u32 {
            self.total.get()
        }

        fn item(&self, position: u32) -> Option<glib::Object> {
            if position >= self.total.get() {
                return None;
            }
            let offset = position / PAGE * PAGE;
            let mut pages = self.pages.borrow_mut();
            let found = pages.iter().position(|(at, _)| *at == offset);
            let index = match found {
                Some(index) => {
                    // the most recently used page goes last
                    let page = pages.remove(index);
                    pages.push(page);
                    pages.len() - 1
                }
                None => {
                    if pages.len() >= PAGES_KEPT {
                        pages.remove(0);
                    }
                    let rows = shell()
                        .core
                        .search(&self.search.borrow(), self.sort.get(), u64::from(offset), u64::from(PAGE))
                        .unwrap_or_default()
                        .into_iter()
                        .map(super::MessageRow::new)
                        .collect();
                    pages.push((offset, rows));
                    pages.len() - 1
                }
            };
            pages[index].1.get((position - offset) as usize).map(|row| row.clone().upcast())
        }
    }
}

glib::wrapper! {
    pub struct MessageRow(ObjectSubclass<imp::MessageRow>);
}

impl MessageRow {
    fn new(message: Message) -> MessageRow {
        let row: MessageRow = glib::Object::new();
        *row.imp().message.borrow_mut() = Some(message);
        row
    }

    /// What `f` reads of the message
    pub fn with<T>(&self, f: impl FnOnce(&Message) -> T) -> Option<T> {
        self.imp().message.borrow().as_ref().map(f)
    }
}

glib::wrapper! {
    pub struct MessageModel(ObjectSubclass<imp::MessageModel>) @implements gio::ListModel;
}

impl MessageModel {
    /// Lists what `search` finds in the order `sort`, `total` messages (none when not `active`)
    fn reset(&self, search: pe_core::Search, sort: Sort, total: u64, active: bool) {
        let imp = self.imp();
        let before = imp.total.get();
        *imp.search.borrow_mut() = search;
        imp.sort.set(sort);
        imp.active.set(active);
        imp.pages.borrow_mut().clear();
        let now = if active { u32::try_from(total).unwrap_or(u32::MAX) } else { 0 };
        imp.total.set(now);
        self.items_changed(0, before, now);
    }
}

/// The columns, in the order of the view
pub struct Columns {
    pub folder: gtk::ColumnViewColumn,
    from: gtk::ColumnViewColumn,
    subject: gtk::ColumnViewColumn,
    received: gtk::ColumnViewColumn,
    size: gtk::ColumnViewColumn,
}

pub struct MessageList {
    pub view: gtk::ColumnView,
    pub selection: gtk::SingleSelection,
    model: MessageModel,
    pub columns: Columns,
    /// The sort being set from here (not by a click on a header)
    sorting: Cell<bool>,
    sort: Cell<Sort>,
}

impl MessageList {
    pub fn new() -> Rc<MessageList> {
        let model: MessageModel = glib::Object::new();
        let selection = gtk::SingleSelection::new(Some(model.clone()));
        selection.set_autoselect(false);
        selection.set_can_unselect(true);
        let view = gtk::ColumnView::new(Some(selection.clone()));
        view.add_css_class("message-list");
        view.set_widget_name("message-list");
        view.set_reorderable(false);
        view.append_column(&icon_column(|m| Some(if m.info.seen() { "ic-mail-read-symbolic" } else { "ic-mail-symbolic" })));
        view.append_column(&icon_column(|m| m.info.has_attachments.then_some("ic-attach-symbolic")));
        view.append_column(&icon_column(|m| m.info.flagged().then_some("ic-flag-symbolic")));
        let from = text_column("From", 180, false, 0.0, |m| m.info.sender().to_string());
        let subject = text_column("Subject", 320, true, 0.0, |m| m.info.subject.clone());
        let received = text_column("Received", 130, false, 0.0, |m| {
            m.info.display_date().map(crate::ui::format_date).unwrap_or_default()
        });
        let size = text_column("Size", 84, false, 1.0, |m| pe_core::format_size(m.info.size.unwrap_or(0)));
        let folder = text_column("Folder", 130, false, 0.0, |m| shell().main().row_folder(m.folder_id));
        folder.set_visible(false);
        for column in [&from, &subject, &received, &size, &folder] {
            view.append_column(column);
        }
        for column in [&from, &subject, &received, &size] {
            column.set_sorter(Some(&gtk::CustomSorter::new(|_, _| gtk::Ordering::Equal)));
        }
        view.sort_by_column(Some(&received), gtk::SortType::Descending);
        Rc::new(MessageList {
            view,
            selection,
            model,
            columns: Columns {
                folder,
                from,
                subject,
                received,
                size,
            },
            sorting: Cell::new(false),
            sort: Cell::new(Sort::default()),
        })
    }

    /// `changed` once the user clicked a column header: the order is the one now
    pub fn connect_sort(self: &Rc<Self>, changed: impl Fn() + 'static) {
        let Some(sorter) = self.view.sorter() else { return };
        let list = Rc::downgrade(self);
        sorter.connect_changed(move |_, _| {
            let Some(list) = list.upgrade() else { return };
            if list.sorting.get() {
                return;
            }
            let before = list.sort.get();
            let now = list.sort_now();
            // another column: dates and sizes start with the largest, words with A
            if now.field != before.field && matches!(now.field, SortField::Date | SortField::Size) && now.ascending {
                list.sorting.set(true);
                let column = list.column_of(now.field);
                list.view.sort_by_column(Some(&column), gtk::SortType::Descending);
                list.sorting.set(false);
            }
            list.sort.set(list.sort_now());
            changed();
        });
    }

    /// The order the headers show
    fn sort_now(&self) -> Sort {
        let Some(sorter) = self.view.sorter().and_downcast::<gtk::ColumnViewSorter>() else {
            return Sort::default();
        };
        let column = sorter.primary_sort_column();
        let field = match column {
            Some(c) if c == self.columns.from => SortField::From,
            Some(c) if c == self.columns.subject => SortField::Subject,
            Some(c) if c == self.columns.size => SortField::Size,
            _ => SortField::Date,
        };
        Sort {
            field,
            ascending: sorter.primary_sort_order() == gtk::SortType::Ascending,
        }
    }

    fn column_of(&self, field: SortField) -> gtk::ColumnViewColumn {
        match field {
            SortField::From => self.columns.from.clone(),
            SortField::Subject => self.columns.subject.clone(),
            SortField::Size => self.columns.size.clone(),
            SortField::Date | SortField::Received => self.columns.received.clone(),
        }
    }

    pub fn sort(&self) -> Sort {
        self.sort.get()
    }

    /// The list again: what `search` finds, `total` of them (nothing when not `active`), the row `select` selected
    pub fn reset(&self, search: pe_core::Search, total: u64, active: bool, select: Option<u64>) {
        self.model.reset(search, self.sort.get(), total, active);
        match select.and_then(|index| u32::try_from(index).ok()) {
            Some(index) if index < self.model.n_items() => {
                self.selection.set_selected(index);
                self.view.scroll_to(index, None, gtk::ListScrollFlags::NONE, None);
            }
            _ => self.selection.set_selected(gtk::INVALID_LIST_POSITION),
        }
    }

    pub fn rows(&self) -> u32 {
        self.model.n_items()
    }

    /// The selected row and its position
    pub fn selected(&self) -> Option<(u32, Message)> {
        let position = self.selection.selected();
        let row = self.selection.selected_item().and_downcast::<MessageRow>()?;
        Some((position, row.with(Message::clone)?))
    }

    pub fn select(&self, index: u32) {
        if index < self.model.n_items() {
            self.selection.set_selected(index);
            self.view.scroll_to(index, None, gtk::ListScrollFlags::FOCUS, None);
        }
    }
}

/// A column of the envelope, the paper clip or the flag: an icon, or none, for each row
fn icon_column(icon: fn(&Message) -> Option<&'static str>) -> gtk::ColumnViewColumn {
    let factory = gtk::SignalListItemFactory::new();
    factory.connect_setup(|_, item| {
        if let Some(item) = item.downcast_ref::<gtk::ListItem>() {
            let image = gtk::Image::new();
            add_drag_source(&image, item);
            item.set_child(Some(&image));
        }
    });
    factory.connect_bind(move |_, item| {
        let Some(item) = item.downcast_ref::<gtk::ListItem>() else { return };
        let Some(image) = item.child().and_downcast::<gtk::Image>() else { return };
        let name = item.item().and_downcast::<MessageRow>().and_then(|row| row.with(icon)).flatten();
        image.set_icon_name(name);
    });
    let column = gtk::ColumnViewColumn::new(None, Some(factory));
    column.set_fixed_width(30);
    column.set_resizable(false);
    column
}

/// A column of words, bold for an unread message
fn text_column(
    title: &str,
    width: i32,
    expand: bool,
    xalign: f32,
    text: fn(&Message) -> String,
) -> gtk::ColumnViewColumn {
    let factory = gtk::SignalListItemFactory::new();
    factory.connect_setup(move |_, item| {
        if let Some(item) = item.downcast_ref::<gtk::ListItem>() {
            let label = gtk::Label::new(None);
            label.set_xalign(xalign);
            label.set_ellipsize(gtk::pango::EllipsizeMode::End);
            add_drag_source(&label, item);
            item.set_child(Some(&label));
        }
    });
    factory.connect_bind(move |_, item| {
        let Some(item) = item.downcast_ref::<gtk::ListItem>() else { return };
        let Some(label) = item.child().and_downcast::<gtk::Label>() else { return };
        let Some(row) = item.item().and_downcast::<MessageRow>() else { return };
        let (words, unread) = row.with(|m| (text(m), !m.info.seen())).unwrap_or_default();
        label.set_text(&words);
        if unread {
            label.add_css_class("unread");
        } else {
            label.remove_css_class("unread");
        }
    });
    let column = gtk::ColumnViewColumn::new(Some(title), Some(factory));
    column.set_fixed_width(width);
    column.set_expand(expand);
    column.set_resizable(true);
    column
}

/// A row dragged onto a folder of the tree: its folder and uid, as text
fn add_drag_source(widget: &impl IsA<gtk::Widget>, item: &gtk::ListItem) {
    let source = gtk::DragSource::new();
    source.set_actions(gdk::DragAction::MOVE | gdk::DragAction::COPY);
    let item = item.downgrade();
    source.connect_prepare(move |_, _, _| {
        let row = item.upgrade()?.item().and_downcast::<MessageRow>()?;
        let payload = row.with(|m| drag_payload(m.folder_id, m.info.uid))?;
        Some(gdk::ContentProvider::for_value(&payload.to_value()))
    });
    widget.add_controller(source);
}

pub fn drag_payload(folder: i64, uid: u64) -> String {
    format!("{folder} {uid}")
}

/// The folder and uid of a dragged row
pub fn parse_payload(payload: &str) -> Option<(i64, u64)> {
    let (folder, uid) = payload.split_once(' ')?;
    Some((folder.parse().ok()?, uid.parse().ok()?))
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn dragged_rows_name_their_message() {
        assert_eq!(parse_payload(&drag_payload(12, 345)), Some((12, 345)));
        assert_eq!(parse_payload("12"), None);
        assert_eq!(parse_payload("x 1"), None);
    }
}
