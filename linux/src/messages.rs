//! The message list: a column view over a list model that pages through the core, 100 rows at a time, as the virtual
//! list view of the Windows app does. The columns: the paper clip, the flag, From, Subject (which takes the room the
//! others leave), Received, and Folder while a search lists several folders. Unread messages in bold, ignored
//! conversations grey; the menus check Watch and Ignore Conversation. Every string comes from the core as it decoded
//! it.

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
/// The widths the Subject and Folder columns start with; the Subject column takes what the others leave, so in a
/// wide window it is wider
const SUBJECT_WIDTH: i32 = 200;
const FOLDER_WIDTH: i32 = 130;
/// The least the Folder column of a search leaves the Subject column
const MIN_SUBJECT_WIDTH: i32 = 90;

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
        /// The view the rows are read through
        pub view: RefCell<pe_core::ListView>,
        pub total: Cell<u32>,
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
                    let rows = self
                        .view
                        .borrow()
                        .rows(&shell().core, u64::from(offset), u64::from(PAGE))
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
    /// Lists the rows of `view`, `total` of them
    fn reset(&self, view: pe_core::ListView, total: u64) {
        let imp = self.imp();
        let before = imp.total.get();
        *imp.view.borrow_mut() = view;
        imp.pages.borrow_mut().clear();
        let now = u32::try_from(total).unwrap_or(u32::MAX);
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
}

pub struct MessageList {
    /// The Classic layout's list: one line a row, in columns
    pub view: gtk::ColumnView,
    /// The Columns layout's list: rows of three lines over the same model and selection (rows.rs)
    pub rows_view: gtk::ListView,
    /// The two, one of them shown, the Columns one under its Sorted by button
    pub widget: gtk::Stack,
    sort_button: gtk::MenuButton,
    pub selection: gtk::MultiSelection,
    model: MessageModel,
    pub columns: Columns,
    /// The sort being set from here (not by a click on a header)
    sorting: Cell<bool>,
    sort: Cell<Sort>,
    /// Sent Items and Drafts: the person column is To, with the recipients (the core says when)
    recipients: Rc<Cell<bool>>,
    /// What the shown Folder column took of the Subject column's width, given back when it goes
    folder_room: Cell<i32>,
    /// A compact window's dates: the time of today's messages, the date of older ones
    compact_dates: Rc<Cell<bool>>,
    /// The list has messages of several folders (its rows of three lines name the folder)
    several_folders: Rc<Cell<bool>>,
}

impl MessageList {
    pub fn new() -> Rc<MessageList> {
        let model: MessageModel = glib::Object::new();
        let selection = gtk::MultiSelection::new(Some(model.clone()));
        let view = gtk::ColumnView::new(Some(selection.clone()));
        view.add_css_class("message-list");
        view.set_widget_name("message-list");
        // Tab goes on to the next control, not through every row (the arrow keys move between them)
        view.set_tab_behavior(gtk::ListTabBehavior::Item);
        view.set_reorderable(false);
        // no read/unread column: an unread message is bold, which says it; its space is the sender's and the subject's
        // a bounce's mark in the paper clip's place: what matters about a delivery notice is that it is one
        view.append_column(&icon_column(
            |m| {
                if m.info.bounce {
                    Some(UNDELIVERED_ICON)
                } else {
                    m.info.has_attachments.then_some("ic-attach-symbolic")
                }
            },
            |_| None,
        ));
        view.append_column(&flag_column());
        // no Watch column: the menus check Watch and Ignore Conversation, and an ignored conversation is grey
        let recipients = Rc::new(Cell::new(false));
        let shows = recipients.clone();
        let from = text_column(&t!(UiColFrom), 200, false, 0.0, move |m| {
            if shows.get() {
                m.info.recipients.clone()
            } else {
                m.info.sender().to_string()
            }
        });
        let subject = subject_column();
        let compact_dates = Rc::new(Cell::new(false));
        let compact = compact_dates.clone();
        let received = text_column(&t!(UiColReceived), date_width(false), false, 0.0, move |m| {
            let format = if compact.get() {
                crate::ui::format_date_compact
            } else {
                crate::ui::format_date
            };
            m.info.display_date().map(format).unwrap_or_default()
        });
        let folder = text_column(&t!(UiColFolder), FOLDER_WIDTH, false, 0.0, |m| {
            shell().main().row_folder(m.folder_id)
        });
        folder.set_visible(false);
        for column in [&from, &subject, &received, &folder] {
            view.append_column(column);
        }
        for column in [&from, &subject, &received] {
            column.set_sorter(Some(&gtk::CustomSorter::new(|_, _| gtk::Ordering::Equal)));
        }
        view.sort_by_column(Some(&received), gtk::SortType::Descending);
        view.add_controller(file_drop_target());
        let several_folders = Rc::new(Cell::new(false));
        let context = crate::rows::RowContext {
            recipients: recipients.clone(),
            several_folders: several_folders.clone(),
        };
        let rows_view = gtk::ListView::new(Some(selection.clone()), Some(crate::rows::factory(context)));
        rows_view.add_css_class("message-list");
        rows_view.add_css_class("message-rows");
        rows_view.set_widget_name("message-rows");
        rows_view.set_tab_behavior(gtk::ListTabBehavior::Item);
        rows_view.add_controller(file_drop_target());
        let sort_button = sort_button();
        let widget = list_stack(&view, &rows_view, &sort_button);
        Rc::new(MessageList {
            view,
            rows_view,
            widget,
            sort_button,
            selection,
            model,
            columns: Columns {
                folder,
                from,
                subject,
                received,
            },
            sorting: Cell::new(false),
            sort: Cell::new(Sort::default()),
            recipients,
            folder_room: Cell::new(0),
            compact_dates,
            several_folders,
        })
    }

    /// The Columns layout's list (`on`), or the Classic one
    pub fn set_columns(&self, on: bool) {
        self.widget
            .set_visible_child_name(if on { "columns" } else { "classic" });
    }

    /// Whether the Columns layout's list is the one shown
    pub fn columns_shown(&self) -> bool {
        self.widget.visible_child_name().as_deref() == Some("columns")
    }

    /// The list shown
    pub fn shown(&self) -> gtk::Widget {
        if self.columns_shown() {
            self.rows_view.clone().upcast()
        } else {
            self.view.clone().upcast()
        }
    }

    /// Both lists, for what each of them does alike (keys, activation)
    pub fn views(&self) -> [gtk::Widget; 2] {
        [self.view.clone().upcast(), self.rows_view.clone().upcast()]
    }

    /// The keyboard to the list shown
    pub fn focus(&self) {
        self.shown().grab_focus();
    }

    /// The list shown scrolled to the row `index`, with `flags` (the focus on it)
    pub fn scroll_to(&self, index: u32, flags: gtk::ListScrollFlags) {
        if self.columns_shown() {
            self.rows_view.scroll_to(index, flags, None);
        } else {
            self.view.scroll_to(index, None, flags, None);
        }
    }

    /// The order shown: the headers of the Classic list (without telling `connect_sort`), and the Sorted by button
    pub fn show_sort(&self, sort: Sort) {
        self.sorting.set(true);
        let order = if sort.ascending {
            gtk::SortType::Ascending
        } else {
            gtk::SortType::Descending
        };
        self.view.sort_by_column(Some(&self.column_of(sort.field)), order);
        self.sorting.set(false);
        self.sort.set(sort);
        self.show_sort_button(sort.field);
    }

    /// "Sorted by Date" on the Columns list's button
    fn show_sort_button(&self, field: SortField) {
        let name = sort_command(field).label();
        let words = t!(UiSortedBy, field = name);
        self.sort_button.set_label(&words);
        self.sort_button
            .update_property(&[gtk::accessible::Property::Label(&words)]);
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
            // another column: dates start with the newest, words with A
            if now.field != before.field && now.field == SortField::Date && now.ascending {
                list.sorting.set(true);
                let column = list.column_of(now.field);
                list.view.sort_by_column(Some(&column), gtk::SortType::Descending);
                list.sorting.set(false);
            }
            list.sort.set(list.sort_now());
            list.show_sort_button(list.sort.get().field);
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
            _ => SortField::Date,
        };
        Sort {
            field,
            ascending: sorter.primary_sort_order() == gtk::SortType::Ascending,
        }
    }

    fn column_of(&self, field: SortField) -> gtk::ColumnViewColumn {
        match field {
            SortField::From | SortField::To => self.columns.from.clone(),
            SortField::Subject => self.columns.subject.clone(),
            SortField::Date | SortField::Received | SortField::Size => self.columns.received.clone(),
        }
    }

    pub fn sort(&self) -> Sort {
        self.sort.get()
    }

    /// The From and Subject columns of a narrow window (`mailbox::narrow_layout`): as wide as the list's pane leaves
    /// them at `width` points of window, the date as wide as ever, the Subject column taking what is left
    pub fn narrow_widths(&self, width: i32) -> Vec<crate::mailbox::Setter> {
        // the Subject column's least, it takes the rest; the Folder column of a search fits beside it
        let (from, subject, folder) = if width <= 560 {
            (100, 90, 80)
        } else if width <= 760 {
            (120, 100, 90)
        } else {
            (160, 160, 110)
        };
        vec![
            (self.columns.from.clone().upcast(), "fixed-width", from.to_value()),
            (self.columns.subject.clone().upcast(), "fixed-width", subject.to_value()),
            (self.columns.folder.clone().upcast(), "fixed-width", folder.to_value()),
        ]
    }

    /// The dates of a compact window (`mailbox::narrow_layout`), or the full ones: the Received column as wide as they
    /// need, its cells written again
    pub fn set_compact_dates(&self, compact: bool) {
        if self.compact_dates.replace(compact) == compact {
            return;
        }
        let column = &self.columns.received;
        column.set_fixed_width(date_width(compact));
        let factory = column.factory();
        column.set_factory(gtk::ListItemFactory::NONE);
        column.set_factory(factory.as_ref());
    }

    /// The Folder column while the list has messages of several folders, under `title` (Account in All Inboxes): the
    /// Subject column gives it its room, and gets it back, so the list stays as wide as its pane. As wide as the
    /// longest of `values` in bold, as an unread row draws it, when they are known (the accounts' names)
    pub fn show_folder_column(&self, shown: bool, title: &str, values: &[String]) {
        self.several_folders.set(shown);
        self.columns.folder.set_title(Some(title));
        let widest = values
            .iter()
            .map(|value| bold_width(self.view.upcast_ref(), value) + 24)
            .max()
            .unwrap_or(0);
        let width = FOLDER_WIDTH.max(widest);
        if self.columns.folder.is_visible() == shown {
            // shown already, under another title: the width of what it shows now, from Subject's room
            if shown && self.columns.folder.fixed_width() != width {
                let more = width - self.columns.folder.fixed_width();
                let subject = self.columns.subject.fixed_width();
                let more = more.min(subject - MIN_SUBJECT_WIDTH);
                self.columns.subject.set_fixed_width(subject - more);
                self.folder_room.set(self.folder_room.get() + more);
                self.columns
                    .folder
                    .set_fixed_width(self.columns.folder.fixed_width() + more);
            }
            return;
        }
        self.columns.folder.set_fixed_width(width);
        self.columns.folder.set_visible(shown);
        // the room taken from Subject's width as it is now (a narrow window's is smaller), and given back
        let subject = self.columns.subject.fixed_width();
        if shown {
            let taken = self
                .columns
                .folder
                .fixed_width()
                .min(subject - MIN_SUBJECT_WIDTH)
                .max(0);
            self.folder_room.set(taken);
            self.columns.subject.set_fixed_width(subject - taken);
        } else {
            self.columns
                .subject
                .set_fixed_width(subject + self.folder_room.replace(0));
        }
    }

    /// From, or To with the recipients when `recipients` (Sent Items and Drafts; the core sorts a From sort by the
    /// recipients there): its title follows, and the date column is Sent there, as Outlook Express names it
    pub fn show_person_column(&self, recipients: bool) {
        if self.recipients.replace(recipients) == recipients {
            return;
        }
        let (person, date) = if recipients {
            (t!(UiColTo), t!(UiColSent))
        } else {
            (t!(UiColFrom), t!(UiColReceived))
        };
        self.columns.from.set_title(Some(&person));
        self.columns.received.set_title(Some(&date));
    }

    /// The person column's title, and whether it lists the recipients (for the UI test)
    #[cfg(feature = "e2e")]
    pub fn person_column(&self) -> (String, bool) {
        (
            self.columns.from.title().map(|t| t.to_string()).unwrap_or_default(),
            self.recipients.get(),
        )
    }

    /// The list again: the rows of `view`, `total` of them, the rows `select` selected
    pub fn reset(self: &Rc<Self>, view: pe_core::ListView, total: u64, select: &[u64]) {
        self.model.reset(view, total);
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
            let adjustment = list
                .shown()
                .dynamic_cast::<gtk::Scrollable>()
                .ok()
                .and_then(|s| s.vadjustment());
            let Some(adjustment) = adjustment else {
                list.scroll_to(first, gtk::ListScrollFlags::NONE);
                return;
            };
            let row = adjustment.upper() / f64::from(rows);
            let (top, page) = (adjustment.value(), adjustment.page_size());
            if row <= 0.0 || f64::from(last.min(rows - 1) + 1) * row <= page {
                adjustment.set_value(0.0);
            } else if f64::from(first) * row < top || f64::from(first + 1) * row > top + page {
                list.scroll_to(first, gtk::ListScrollFlags::NONE);
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
            self.scroll_to(index, gtk::ListScrollFlags::FOCUS);
        }
    }

    pub fn select_all(&self) {
        self.selection.select_all();
    }
}

/// The command of View > Sort By that sorts by `field`
pub fn sort_command(field: SortField) -> crate::commands::Command {
    use crate::commands::Command;
    match field {
        SortField::From | SortField::To => Command::SortFrom,
        SortField::Subject => Command::SortSubject,
        SortField::Size => Command::SortSize,
        SortField::Date | SortField::Received => Command::SortDate,
    }
}

/// The Columns list's "Sorted by" button, its menu the items of View > Sort By, in place of the column headers
fn sort_button() -> gtk::MenuButton {
    let menu = gio::Menu::new();
    let mut fields = gio::Menu::new();
    for &command in crate::commands::Command::ALL
        .iter()
        .filter(|c| c.submenu() == Some("sort_by"))
    {
        // the fields, then the directions, each a section
        if command == crate::commands::Command::SortAscending {
            menu.append_section(None, &fields);
            fields = gio::Menu::new();
        }
        fields.append(Some(command.label()), Some(&format!("win.{}", command.name())));
    }
    menu.append_section(None, &fields);
    let button = gtk::MenuButton::builder()
        .menu_model(&menu)
        .always_show_arrow(true)
        .halign(gtk::Align::Start)
        .build();
    button.add_css_class("flat");
    button.add_css_class("sort-button");
    button.set_widget_name("sort-button");
    button
}

/// The two lists in a stack: the Classic one, and the Columns one under its Sorted by button
fn list_stack(view: &gtk::ColumnView, rows: &gtk::ListView, sort: &gtk::MenuButton) -> gtk::Stack {
    let scrolled = |child: &gtk::Widget| {
        gtk::ScrolledWindow::builder()
            .child(child)
            .vexpand(true)
            .hscrollbar_policy(gtk::PolicyType::Never)
            .build()
    };
    let columns = gtk::Box::new(gtk::Orientation::Vertical, 0);
    columns.append(sort);
    columns.append(&gtk::Separator::new(gtk::Orientation::Horizontal));
    columns.append(&scrolled(rows.upcast_ref()));
    let classic = gtk::ScrolledWindow::builder().child(view).vexpand(true).build();
    let stack = gtk::Stack::new();
    stack.add_named(&classic, Some("classic"));
    stack.add_named(&columns, Some("columns"));
    stack.set_visible_child_name("classic");
    stack.set_vexpand(true);
    stack
}

/// The mark of a notice that a message was not delivered (or not yet): Fluent's envelope with an exclamation mark, as
/// the Windows app has it, in the paper clip's colour; the card in the reading pane says how bad it is
pub const UNDELIVERED_ICON: &str = "ic-mail-error-symbolic";

/// The column of the paper clip: an icon, or none, for each row, and what it says on hover and to a screen reader
fn icon_column(
    icon: fn(&Message) -> Option<&'static str>,
    tip: fn(&Message) -> Option<String>,
) -> gtk::ColumnViewColumn {
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
        let (name, tip, ignored) = item
            .item()
            .and_downcast::<MessageRow>()
            .and_then(|row| row.with(|m| (icon(m), tip(m), m.dimmed())))
            .unwrap_or_default();
        image.set_icon_name(name);
        image.set_tooltip_text(tip.as_deref());
        image.update_property(&[gtk::accessible::Property::Label(tip.as_deref().unwrap_or_default())]);
        set_grey(&image, ignored);
    });
    let column = gtk::ColumnViewColumn::new(None, Some(factory));
    column.set_fixed_width(30);
    column.set_resizable(false);
    column
}

/// The colour a flag is drawn in: the GNOME palette's, as Apple Mail's seven
pub fn flag_rgb(color: pe_core::FlagColor) -> (f64, f64, f64) {
    use pe_core::FlagColor;
    let hex: u32 = match color {
        FlagColor::Red => 0xe01b24,
        FlagColor::Orange => 0xff7800,
        FlagColor::Yellow => 0xe5a50a,
        FlagColor::Green => 0x2ec27e,
        FlagColor::Blue => 0x3584e4,
        FlagColor::Purple => 0x9141ac,
        FlagColor::Gray => 0x77767b,
    };
    let channel = |shift: u32| f64::from((hex >> shift) & 0xff) / 255.0;
    (channel(16), channel(8), channel(0))
}

/// A flag in `color`, 16 pixels, as the flag column and the Flag menu draw it: the pole, and the pennant filled with a
/// darker edge so it reads on a selected row too
pub fn draw_flag(cr: &gtk::cairo::Context, x: f64, y: f64, color: pe_core::FlagColor) {
    let (r, g, b) = flag_rgb(color);
    cr.set_line_width(1.0);
    cr.move_to(x + 4.0, y + 2.5);
    cr.line_to(x + 12.5, y + 2.5);
    cr.line_to(x + 10.5, y + 6.0);
    cr.line_to(x + 12.5, y + 9.5);
    cr.line_to(x + 4.0, y + 9.5);
    cr.close_path();
    cr.set_source_rgb(r, g, b);
    let _ = cr.fill_preserve();
    cr.set_source_rgba(r * 0.6, g * 0.6, b * 0.6, 1.0);
    let _ = cr.stroke();
    cr.set_line_width(1.5);
    cr.move_to(x + 3.75, y + 2.0);
    cr.line_to(x + 3.75, y + 14.0);
    let _ = cr.stroke();
}

/// The flag column: each flagged message's flag in its colour (Apple Mail's), nothing for the others
fn flag_column() -> gtk::ColumnViewColumn {
    let factory = gtk::SignalListItemFactory::new();
    factory.connect_setup(|_, item| {
        if let Some(item) = item.downcast_ref::<gtk::ListItem>() {
            let area = gtk::DrawingArea::new();
            area.set_content_width(16);
            area.set_content_height(16);
            area.set_halign(gtk::Align::Center);
            add_drag_source(&area, item);
            item.set_child(Some(&area));
        }
    });
    factory.connect_bind(|_, item| {
        let Some(item) = item.downcast_ref::<gtk::ListItem>() else {
            return;
        };
        let Some(area) = item.child().and_downcast::<gtk::DrawingArea>() else {
            return;
        };
        let (color, ignored) = item
            .item()
            .and_downcast::<MessageRow>()
            .and_then(|row| row.with(|m| (m.info.flag_color(), m.dimmed())))
            .unwrap_or_default();
        set_grey(&area, ignored);
        // the colour by its name: on hover, and for a screen reader (and for those who tell colours apart badly)
        let name = color.map(pe_core::color_name);
        area.set_tooltip_text(name);
        area.update_property(&[gtk::accessible::Property::Label(name.unwrap_or_default())]);
        area.set_draw_func(move |_, cr, _, _| {
            if let Some(color) = color {
                draw_flag(cr, 0.0, 0.0, color);
            }
        });
    });
    let column = gtk::ColumnViewColumn::new(None, Some(factory));
    column.set_fixed_width(30);
    column.set_resizable(false);
    column
}

/// A column of words, bold for an unread message
/// The width `text` takes in bold in `widget`'s font
fn bold_width(widget: &gtk::Widget, text: &str) -> i32 {
    let layout = widget.create_pango_layout(Some(text));
    let attributes = gtk::pango::AttrList::new();
    attributes.insert(gtk::pango::AttrInt::new_weight(gtk::pango::Weight::Bold));
    layout.set_attributes(Some(&attributes));
    layout.pixel_size().0
}

fn text_column(
    title: &str,
    width: i32,
    expand: bool,
    xalign: f32,
    text: impl Fn(&Message) -> String + 'static,
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
        let (words, unread, ignored) = row.with(|m| (text(m), m.bold(), m.dimmed())).unwrap_or_default();
        label.set_text(&words);
        set_bold(&label, unread);
        set_grey(&label, ignored);
    });
    let column = gtk::ColumnViewColumn::new(Some(title), Some(factory));
    column.set_fixed_width(width);
    column.set_expand(expand);
    column.set_resizable(true);
    column
}

/// The Received column as wide as the longest date the locale writes ("12/28/2026 10:58 PM" in English, US; with
/// `compact`, the longer of "12/28/2026" and "10:58 PM"), in bold as an unread message has it, so no date is cut short
fn date_width(compact: bool) -> i32 {
    let longest = glib::DateTime::from_local(2026, 12, 28, 22, 58, 0.0)
        .map(|date| date.to_unix())
        .unwrap_or_default();
    let texts = if compact {
        vec![
            crate::ui::format_time(longest),
            glib::DateTime::from_unix_local(longest)
                .and_then(|date| date.format("%x"))
                .map(|text| text.to_string())
                .unwrap_or_default(),
        ]
    } else {
        vec![crate::ui::format_date(longest)]
    };
    let widest = texts
        .iter()
        .map(|text| {
            let label = gtk::Label::new(Some(text));
            label.add_css_class("unread");
            label.measure(gtk::Orientation::Horizontal, -1).1
        })
        .max()
        .unwrap_or_default();
    // the cell's padding and the header's sort arrow
    (widest + 28).max(if compact { 90 } else { 130 })
}

/// An ignored conversation's cells grey
fn set_grey(widget: &impl IsA<gtk::Widget>, grey: bool) {
    if grey {
        widget.add_css_class("dim-label");
    } else {
        widget.remove_css_class("dim-label");
    }
}

fn set_bold(label: &gtk::Label, bold: bool) {
    if bold {
        label.add_css_class("unread");
    } else {
        label.remove_css_class("unread");
    }
}

/// How far a reply's subject is indented under its conversation's first message
const REPLY_INDENT: i32 = 18;

/// The Subject column. In a list grouped by conversation each subject has the room of the disclosure triangle in front
/// of it (the tree's own, pan-end or pan-down, shown on a conversation of more than one message, a click on it opens or
/// closes the conversation), the conversation's count after it, and a reply indented under the first message.
fn subject_column() -> gtk::ColumnViewColumn {
    let factory = gtk::SignalListItemFactory::new();
    factory.connect_setup(|_, item| {
        let Some(item) = item.downcast_ref::<gtk::ListItem>() else {
            return;
        };
        let cell = gtk::Box::new(gtk::Orientation::Horizontal, 4);
        let expander = gtk::Image::new();
        expander.set_pixel_size(16);
        expander.add_css_class("thread-expander");
        let click = gtk::GestureClick::new();
        let weak = item.downgrade();
        click.connect_pressed(move |gesture, _, _, _| {
            // the click opens or closes, it does not select
            gesture.set_state(gtk::EventSequenceState::Claimed);
            let thread = weak
                .upgrade()
                .and_then(|item| item.item().and_downcast::<MessageRow>())
                .and_then(|row| row.with(|m| m.thread))
                .flatten();
            if let Some(place) = thread.filter(|t| t.opens()) {
                shell().main().toggle_thread(place.thread);
            }
        });
        expander.add_controller(click);
        let label = gtk::Label::new(None);
        label.set_xalign(0.0);
        label.set_hexpand(true);
        label.set_ellipsize(gtk::pango::EllipsizeMode::End);
        cell.append(&expander);
        cell.append(&label);
        add_drag_source(&label, item);
        item.set_child(Some(&cell));
    });
    factory.connect_bind(|_, item| {
        let Some(item) = item.downcast_ref::<gtk::ListItem>() else {
            return;
        };
        let Some(cell) = item.child().and_downcast::<gtk::Box>() else {
            return;
        };
        let (Some(expander), Some(label)) = (
            cell.first_child().and_downcast::<gtk::Image>(),
            cell.last_child().and_downcast::<gtk::Label>(),
        ) else {
            return;
        };
        let Some(row) = item.item().and_downcast::<MessageRow>() else {
            return;
        };
        let Some((subject, thread, unread, ignored)) =
            row.with(|m| (m.info.subject.clone(), m.thread, m.bold(), m.dimmed()))
        else {
            return;
        };
        set_bold(&label, unread);
        set_grey(&cell, ignored);
        // one row a message: the subject alone
        let Some(place) = thread else {
            expander.set_visible(false);
            cell.set_margin_start(0);
            label.set_text(&subject);
            return;
        };
        expander.set_visible(true);
        cell.set_margin_start(if place.depth > 0 { REPLY_INDENT } else { 0 });
        expander.set_icon_name(match (place.opens(), place.collapsed()) {
            (false, _) => None,
            (true, true) => Some("pan-end-symbolic"),
            (true, false) => Some("pan-down-symbolic"),
        });
        if place.opens() {
            label.set_text(&format!("{subject} ({})", place.count));
        } else {
            label.set_text(&subject);
        }
    });
    let column = gtk::ColumnViewColumn::new(Some(&t!(UiColSubject)), Some(factory));
    column.set_fixed_width(SUBJECT_WIDTH);
    column.set_expand(true);
    column.set_resizable(true);
    column
}

/// Rows dragged out of the list: a selected row brings the whole selection, another row itself alone. Onto a folder of
/// the tree they move (Ctrl copies); onto a file manager or another program they become .eml files there. Several
/// show how many on the drag icon.
pub(crate) fn add_drag_source(widget: &impl IsA<gtk::Widget>, item: &gtk::ListItem) {
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
        if !crate::files::takes(&paths) {
            return false;
        }
        let main = shell().main();
        crate::app::spawn(async move { main.drop_files(None, paths).await });
        true
    });
    target
}
