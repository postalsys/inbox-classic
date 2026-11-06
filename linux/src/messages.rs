//! The message list: a column view over a list model that pages through the core, 100 rows at a time, as the virtual
//! list view of the Windows app does. The columns as Outlook Express has them: the envelope (read or not), the paper
//! clip, the flag, From, Subject, Received, Size, and Folder while a search lists several folders. Unread messages in
//! bold. Every string comes from the core as it decoded it.

use std::cell::{Cell, RefCell};
use std::rc::Rc;

use gtk::prelude::*;
use gtk::subclass::prelude::*;
use gtk::{gdk, gio, glib};
use pe_store::{Message, MessageRef, Sort, SortField};

use crate::app::shell;

const PAGE: u32 = 100;
/// Pages kept while the list scrolls, the least recently used dropped first
const PAGES_KEPT: usize = 8;
/// The widths the Subject and Folder columns start with
const SUBJECT_WIDTH: i32 = 320;
const FOLDER_WIDTH: i32 = 130;

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
                        .search(
                            &self.search.borrow(),
                            self.sort.get(),
                            u64::from(offset),
                            u64::from(PAGE),
                        )
                        .unwrap_or_default()
                        .into_iter()
                        .map(super::MessageRow::new)
                        .collect();
                    pages.push((offset, rows));
                    pages.len() - 1
                }
            };
            pages[index]
                .1
                .get((position - offset) as usize)
                .map(|row| row.clone().upcast())
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
        let now = if active {
            u32::try_from(total).unwrap_or(u32::MAX)
        } else {
            0
        };
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
    pub selection: gtk::MultiSelection,
    model: MessageModel,
    pub columns: Columns,
    /// The sort being set from here (not by a click on a header)
    sorting: Cell<bool>,
    sort: Cell<Sort>,
}

impl MessageList {
    pub fn new() -> Rc<MessageList> {
        let model: MessageModel = glib::Object::new();
        let selection = gtk::MultiSelection::new(Some(model.clone()));
        let view = gtk::ColumnView::new(Some(selection.clone()));
        view.add_css_class("message-list");
        view.set_widget_name("message-list");
        view.set_reorderable(false);
        // no read/unread column: an unread message is bold, which says it; its space is the sender's and the subject's
        view.append_column(&icon_column(|m| m.info.has_attachments.then_some("ic-attach-symbolic")));
        view.append_column(&icon_column(|m| m.info.flagged().then_some("ic-flag-symbolic")));
        let from = text_column("From", 200, false, 0.0, |m| m.info.sender().to_string());
        let subject = text_column("Subject", SUBJECT_WIDTH, true, 0.0, |m| m.info.subject.clone());
        let received = text_column("Received", 130, false, 0.0, |m| {
            m.info.display_date().map(crate::ui::format_date).unwrap_or_default()
        });
        let size = text_column("Size", 92, false, 1.0, |m| {
            pe_core::format_size(m.info.size.unwrap_or(0))
        });
        let folder = text_column("Folder", FOLDER_WIDTH, false, 0.0, |m| {
            shell().main().row_folder(m.folder_id)
        });
        folder.set_visible(false);
        for column in [&from, &subject, &received, &size, &folder] {
            view.append_column(column);
        }
        for column in [&from, &subject, &received, &size] {
            column.set_sorter(Some(&gtk::CustomSorter::new(|_, _| gtk::Ordering::Equal)));
        }
        view.sort_by_column(Some(&received), gtk::SortType::Descending);
        view.add_controller(file_drop_target());
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

    /// The Folder column while the list has messages of several folders, under `title` (Account in All Inboxes): the
    /// Subject column gives it its room, and gets it back, so the list stays as wide as its pane
    pub fn show_folder_column(&self, shown: bool, title: &str) {
        self.columns.folder.set_title(Some(title));
        if self.columns.folder.is_visible() == shown {
            return;
        }
        self.columns.folder.set_visible(shown);
        self.columns.subject.set_fixed_width(if shown {
            SUBJECT_WIDTH - FOLDER_WIDTH
        } else {
            SUBJECT_WIDTH
        });
    }

    /// The list again: what `search` finds, `total` of them (nothing when not `active`), the rows `select` selected
    pub fn reset(self: &Rc<Self>, search: pe_core::Search, total: u64, active: bool, select: &[u64]) {
        self.model.reset(search, self.sort.get(), total, active);
        self.select_positions(select);
        self.reveal(select);
    }

    /// Scrolls only as far as the rows at `positions` (ascending) need to be seen: to the top when they fit under the
    /// rows above them, so the newest messages stay in sight; not at all when the first is in sight; else to it.
    /// Once the list is laid out with its new rows.
    pub fn reveal(self: &Rc<Self>, positions: &[u64]) {
        let (Some(&first), Some(&last)) = (positions.first(), positions.last()) else {
            return;
        };
        let list = Rc::downgrade(self);
        glib::idle_add_local_once(move || {
            let Some(list) = list.upgrade() else { return };
            let rows = list.model.n_items();
            let (Ok(first), Ok(last)) = (u32::try_from(first), u32::try_from(last)) else {
                return;
            };
            if rows == 0 || first >= rows {
                return;
            }
            let Some(adjustment) = list.view.vadjustment() else {
                list.view.scroll_to(first, None, gtk::ListScrollFlags::NONE, None);
                return;
            };
            let row = adjustment.upper() / f64::from(rows);
            let (top, page) = (adjustment.value(), adjustment.page_size());
            if row <= 0.0 || f64::from(last.min(rows - 1) + 1) * row <= page {
                adjustment.set_value(0.0);
            } else if f64::from(first) * row < top || f64::from(first + 1) * row > top + page {
                list.view.scroll_to(first, None, gtk::ListScrollFlags::NONE, None);
            }
        });
    }

    pub fn rows(&self) -> u32 {
        self.model.n_items()
    }

    /// How many rows are selected
    pub fn selected_count(&self) -> u64 {
        self.selection.selection().size()
    }

    /// The one selected row and its position; None when none or several are
    pub fn selected(&self) -> Option<(u32, Message)> {
        let selected = self.selection.selection();
        if selected.size() != 1 {
            return None;
        }
        let position = selected.minimum();
        let row = self.model.item(position).and_downcast::<MessageRow>()?;
        Some((position, row.with(Message::clone)?))
    }

    /// The selected positions as ranges, start included and end not, ascending
    pub fn selected_ranges(&self) -> Vec<(u64, u64)> {
        let selected = self.selection.selection();
        let mut ranges: Vec<(u64, u64)> = Vec::new();
        let Some((mut iter, first)) = gtk::BitsetIter::init_first(&selected) else {
            return ranges;
        };
        let mut at = Some(first);
        while let Some(position) = at {
            let position = u64::from(position);
            match ranges.last_mut() {
                Some((_, end)) if *end == position => *end += 1,
                _ => ranges.push((position, position + 1)),
            }
            at = iter.next();
        }
        ranges
    }

    /// The last selected position
    pub fn last_selected(&self) -> Option<u32> {
        let selected = self.selection.selection();
        (!selected.is_empty()).then(|| selected.maximum())
    }

    /// Whether the row at `position` is selected
    pub fn is_selected(&self, position: u32) -> bool {
        self.selection.is_selected(position)
    }

    /// Selects only the rows at `positions`
    pub fn select_positions(&self, positions: &[u64]) {
        let rows = self.model.n_items();
        let wanted = gtk::Bitset::new_empty();
        for position in positions {
            if let Ok(position) = u32::try_from(*position)
                && position < rows
            {
                wanted.add(position);
            }
        }
        let all = gtk::Bitset::new_range(0, rows);
        self.selection.set_selection(&wanted, &all);
    }

    /// Selects only the row `index`, scrolled to and with the focus
    pub fn select(&self, index: u32) {
        if index < self.model.n_items() {
            self.selection.select_item(index, true);
            self.view.scroll_to(index, None, gtk::ListScrollFlags::FOCUS, None);
        }
    }

    pub fn select_all(&self) {
        self.selection.select_all();
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
        let Some(item) = item.downcast_ref::<gtk::ListItem>() else {
            return;
        };
        let Some(image) = item.child().and_downcast::<gtk::Image>() else {
            return;
        };
        let name = item
            .item()
            .and_downcast::<MessageRow>()
            .and_then(|row| row.with(icon))
            .flatten();
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
        let Some(item) = item.downcast_ref::<gtk::ListItem>() else {
            return;
        };
        let Some(label) = item.child().and_downcast::<gtk::Label>() else {
            return;
        };
        let Some(row) = item.item().and_downcast::<MessageRow>() else {
            return;
        };
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

/// Rows dragged out of the list: a selected row brings the whole selection, another row itself alone. Onto a folder of
/// the tree they move (Ctrl copies); onto a file manager or another program they become .eml files there. Several
/// show how many on the drag icon.
fn add_drag_source(widget: &impl IsA<gtk::Widget>, item: &gtk::ListItem) {
    add_menu(widget, item);
    let source = gtk::DragSource::new();
    source.set_actions(gdk::DragAction::MOVE | gdk::DragAction::COPY);
    let item = item.downgrade();
    let count = std::rc::Rc::new(std::cell::Cell::new(0usize));
    let counted = count.clone();
    source.connect_prepare(move |_, _, _| {
        let item = item.upgrade()?;
        let main = shell().main();
        let refs = if main.list.is_selected(item.position()) {
            main.selected_refs()
        } else {
            let row = item.item().and_downcast::<MessageRow>()?;
            vec![row.with(|m| MessageRef {
                folder: m.folder_id,
                uid: m.info.uid,
            })?]
        };
        if refs.is_empty() {
            return None;
        }
        counted.set(refs.len());
        Some(crate::files::drag_content(refs))
    });
    source.connect_drag_begin(move |_, drag| {
        if count.get() > 1 {
            let label = gtk::Label::new(Some(&pe_core::messages(count.get() as u64)));
            label.add_css_class("drag-count");
            label.set_margin_top(4);
            label.set_margin_bottom(4);
            label.set_margin_start(10);
            label.set_margin_end(10);
            let frame = gtk::Frame::new(None);
            frame.set_child(Some(&label));
            frame.add_css_class("view");
            gtk::DragIcon::for_drag(drag).set_child(Some(&frame));
        }
    });
    widget.add_controller(source);
}

/// The right-click menu of the messages a cell shows: a row outside the selection selected alone first, as a click
/// would; one inside it keeps the selection
fn add_menu(widget: &impl IsA<gtk::Widget>, item: &gtk::ListItem) {
    let click = gtk::GestureClick::new();
    click.set_button(gdk::BUTTON_SECONDARY);
    let item = item.downgrade();
    click.connect_pressed(move |gesture, _, x, y| {
        let (Some(item), Some(widget)) = (item.upgrade(), gesture.widget()) else {
            return;
        };
        let main = shell().main();
        if !main.list.is_selected(item.position()) {
            main.list.select(item.position());
        }
        main.message_menu(&widget, x, y);
    });
    widget.add_controller(click);
}

/// .eml files dropped onto the list from a file manager: into the folder it shows, as Import does. The list's own rows
/// dragged back onto it are not files to put anywhere.
fn file_drop_target() -> gtk::DropTarget {
    let target = gtk::DropTarget::new(gdk::FileList::static_type(), gdk::DragAction::COPY);
    target.connect_accept(|_, drop| {
        !drop
            .formats()
            .contains_type(crate::files::DraggedMessages::static_type())
    });
    target.connect_drop(|_, value, _, _| {
        let Ok(list) = value.get::<gdk::FileList>() else {
            return false;
        };
        let paths = crate::files::paths_of(&list);
        if !crate::files::all_messages(&paths) {
            return false;
        }
        let main = shell().main();
        crate::app::spawn(async move { main.drop_files(None, paths).await });
        true
    });
    target
}
