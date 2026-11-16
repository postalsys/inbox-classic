//! The message list: a column view over a list model that pages through the core, 100 rows at a time, as the virtual
//! list view of the Windows app does. The pages are read off the window thread: rows not here yet are blank lines of
//! the same height, filled when their page comes. The columns: the paper clip, the flag, From, Subject (which takes the room the
//! others leave), Received, and Folder while a search lists several folders. Unread messages in bold, ignored
//! conversations grey; the menus check Watch and Ignore Conversation. Every string comes from the core as it decoded
//! it.

use std::cell::{Cell, RefCell};
use std::collections::HashSet;
use std::rc::Rc;

use gtk::prelude::*;
use gtk::subclass::prelude::*;
use gtk::{gdk, gio, glib};
use pe_store::{Message, MessageRef, Sort, SortField};

use crate::app::shell;
use crate::ui::set_class;

/// The rows of a page, as the core's list loads read them
const PAGE: u32 = pe_core::LIST_PAGE as u32;
/// Pages kept while the list scrolls, the least recently used dropped first
const PAGES_KEPT: usize = 8;

/// The widths the Subject and Folder columns start with; the Subject column takes what the others leave, so in a
/// wide window it is wider
const SUBJECT_WIDTH: i32 = 200;
const FOLDER_WIDTH: i32 = 130;
/// The least the Folder column of a search leaves the Subject column
const MIN_SUBJECT_WIDTH: i32 = 90;

/// Asks the core for the page of the list at an offset
type AskPage = Rc<dyn Fn(u64)>;

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
        /// The pages here, the least recently used first: read rows, or blank ones while their page is asked for
        pub pages: RefCell<Vec<(u32, Vec<super::MessageRow>)>>,
        /// The offsets of the pages asked for since the list was drawn
        pub asked: RefCell<HashSet<u32>>,
        /// Pages a row drawn wants, asked for once the drawing is done
        pub wanted: RefCell<Vec<u32>>,
        pub asking: Cell<bool>,
        /// Asks the core for the page at an offset (`ListPageReady` brings it)
        pub ask: RefCell<Option<AskPage>>,
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

        /// The row at `position` from the pages here; a page not here is blank lines of the row's height, and is
        /// asked of the core with the page after it (no query here: GTK asks while it draws)
        fn item(&self, position: u32) -> Option<glib::Object> {
            let total = self.total.get();
            if position >= total {
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
                    let rows = (offset..total.min(offset + PAGE))
                        .map(|_| super::MessageRow::blank())
                        .collect();
                    pages.push((offset, rows));
                    drop(pages);
                    self.want(offset);
                    if offset + PAGE < total {
                        self.want(offset + PAGE);
                    }
                    pages = self.pages.borrow_mut();
                    pages.len() - 1
                }
            };
            pages[index]
                .1
                .get((position - offset) as usize)
                .map(|row| row.clone().upcast())
        }
    }

    impl MessageModel {
        /// The page at `offset` asked of the core once GTK is done drawing, unless asked for already
        fn want(&self, offset: u32) {
            if !self.asked.borrow_mut().insert(offset) {
                return;
            }
            self.wanted.borrow_mut().push(offset);
            if self.asking.replace(true) {
                return;
            }
            let model = self.obj().downgrade();
            glib::idle_add_local_once(move || {
                let Some(model) = model.upgrade() else { return };
                let imp = model.imp();
                imp.asking.set(false);
                let wanted = std::mem::take(&mut *imp.wanted.borrow_mut());
                let ask = imp.ask.borrow().clone();
                if let Some(ask) = ask {
                    for offset in wanted {
                        ask(u64::from(offset));
                    }
                }
            });
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

    /// A row whose page is not here yet: a blank line
    fn blank() -> MessageRow {
        glib::Object::new()
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
    /// Lists `total` rows of its view, `read` the page of them read already (its offset and rows)
    fn reset(&self, total: u64, read: Option<(u64, Vec<Message>)>) {
        let imp = self.imp();
        let before = imp.total.get();
        let mut pages = imp.pages.borrow_mut();
        pages.clear();
        imp.asked.borrow_mut().clear();
        imp.wanted.borrow_mut().clear();
        if let Some((offset, rows)) = read
            && let Ok(offset) = u32::try_from(offset)
        {
            pages.push((offset, rows.into_iter().map(MessageRow::new).collect()));
            imp.asked.borrow_mut().insert(offset);
        }
        drop(pages);
        let now = u32::try_from(total).unwrap_or(u32::MAX);
        imp.total.set(now);
        self.items_changed(0, before, now);
    }

    /// The page read at `offset` in place of its blank lines: the range of rows that changed, None when the page is
    /// past the end of the list
    fn fill(&self, offset: u64, rows: Vec<Message>) -> Option<(u32, u32)> {
        let imp = self.imp();
        let total = imp.total.get();
        let offset = u32::try_from(offset).ok().filter(|o| *o < total && o % PAGE == 0)?;
        let count = total.min(offset + PAGE) - offset;
        let mut rows: Vec<MessageRow> = rows.into_iter().take(count as usize).map(MessageRow::new).collect();
        // a page shorter than the list says (it changed since it was counted): blank to the end, until it is read again
        rows.resize_with(count as usize, MessageRow::blank);
        let mut pages = imp.pages.borrow_mut();
        pages.retain(|(at, _)| *at != offset);
        if pages.len() >= PAGES_KEPT {
            pages.remove(0);
        }
        pages.push((offset, rows));
        drop(pages);
        self.items_changed(offset, count, count);
        Some((offset, count))
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
    /// The time the rows of three lines write their dates against, read at each refresh of the list
    clock: Rc<Cell<crate::rows::Clock>>,
    /// The rows of three lines show the senders' pictures (Preferences)
    pictures: Rc<Cell<bool>>,
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
        view.append_column(&icon_column(attachment_icon, |_| None));
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
        let clock = Rc::new(Cell::new(crate::rows::Clock::now()));
        let pictures = Rc::new(Cell::new(shell().settings.bool(crate::settings::LIST_PICTURES, true)));
        let context = crate::rows::RowContext {
            recipients: recipients.clone(),
            several_folders: several_folders.clone(),
            clock: clock.clone(),
            pictures: pictures.clone(),
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
            clock,
            pictures,
        })
    }

    /// The senders' pictures shown in the rows of three lines or not (taken at the list's next refresh)
    pub fn set_pictures(&self, on: bool) {
        self.pictures.set(on);
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

    /// The view the rows are read through: `view`, or the one it has when that lists the same (it keeps what it read,
    /// and the counts while nothing changed)
    pub fn set_view(&self, view: pe_core::ListView) {
        let mut kept = self.model.imp().view.borrow_mut();
        if *kept != view {
            *kept = view;
        }
    }

    /// The view the rows are read through ([`MessageList::set_view`])
    pub fn view(&self) -> std::cell::Ref<'_, pe_core::ListView> {
        self.model.imp().view.borrow()
    }

    /// Whether the list shown might show something else read again: it is not `view`'s, or something was written
    /// since it was counted
    pub fn stale(&self, view: &pe_core::ListView) -> bool {
        let shown = self.view();
        *shown != *view || shown.stale(&shell().core).unwrap_or(true)
    }

    /// What asks the core for a page of the list, when a row of one not here is drawn
    pub fn connect_page_wanted(&self, ask: impl Fn(u64) + 'static) {
        *self.model.imp().ask.borrow_mut() = Some(Rc::new(ask));
    }

    /// A page of the list read at `offset`, drawn in place of its blank lines with the selection kept
    pub fn fill_page(&self, offset: u64, rows: Vec<Message>) {
        let selected = self.selection.selection().copy();
        if let Some((start, count)) = self.model.fill(offset, rows) {
            self.selection
                .set_selection(&selected, &gtk::Bitset::new_range(start, count));
        }
    }

    /// The list again: the rows of its view, `total` of them (`read` the page of them read already, its offset and
    /// rows), the rows `select` selected; scrolled as it was when it is the same list read again (`same`, GTK keeps
    /// the place), else from the top
    pub fn reset(self: &Rc<Self>, total: u64, read: Option<(u64, Vec<Message>)>, select: &[u64], same: bool) {
        self.clock.set(crate::rows::Clock::now());
        self.model.reset(total, read);
        self.select_positions(select);
        // another list starts at its top (GTK keeps the place it had), unless a selection is shown
        if !same && select.is_empty() && self.model.n_items() > 0 {
            self.scroll_to(0, gtk::ListScrollFlags::NONE);
        }
        self.reveal(select);
    }

    /// The scrolling of the list shown
    fn adjustment(&self) -> Option<gtk::Adjustment> {
        self.shown()
            .dynamic_cast::<gtk::Scrollable>()
            .ok()
            .and_then(|s| s.vadjustment())
    }

    /// The messages at the rows `ranges` (start included, end not), as the view the rows were read with says: from
    /// the pages it read when the rows shown are among them (a click selects what its row shows without the core
    /// grouping the whole list again)
    pub fn refs_in_ranges(&self, ranges: &[(u64, u64)]) -> Vec<MessageRef> {
        self.model
            .imp()
            .view
            .borrow()
            .refs_in_ranges(&shell().core, ranges)
            .unwrap_or_default()
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
            // nothing to do when the selection changed meanwhile (a click scrolls to its row itself)
            let selected = list.selection.selection();
            if rows == 0
                || first >= rows
                || selected.is_empty()
                || (selected.minimum(), selected.maximum()) != (first, last)
            {
                return;
            }
            let Some(adjustment) = list.adjustment() else {
                list.scroll_to(first, gtk::ListScrollFlags::NONE);
                return;
            };
            let row = adjustment.upper() / f64::from(rows);
            if row > 0.0 && f64::from(last.min(rows - 1) + 1) * row <= adjustment.page_size() {
                adjustment.set_value(0.0);
            } else {
                // GTK scrolls only as far as the row needs, not at all when it is in sight
                list.scroll_to(first, gtk::ListScrollFlags::NONE);
            }
        });
    }

    pub fn rows(&self) -> u32 {
        self.model.n_items()
    }

    /// The messages of the first `limit` rows as the list shows them now, for the e2e driver
    #[cfg(feature = "e2e")]
    pub fn shown_messages(&self, limit: u32) -> Vec<Message> {
        (0..self.model.n_items().min(limit))
            .filter_map(|at| self.model.item(at).and_downcast::<MessageRow>())
            .filter_map(|row| row.with(Message::clone))
            .collect()
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
    let button = gtk::MenuButton::builder()
        .menu_model(&crate::mailbox::submenu_model("sort_by"))
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

/// The paper clip of a message with attachments, or a bounce's own mark in its place; none for the others
pub(crate) fn attachment_icon(m: &Message) -> Option<&'static str> {
    if m.info.bounce {
        Some(UNDELIVERED_ICON)
    } else {
        m.info.has_attachments.then_some("ic-attach-symbolic")
    }
}

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
        set_class(&image, "dim-label", ignored);
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

/// A message's flag in its colour on `area`, or nothing; the colour by its name on hover and for a screen reader (and
/// for those who tell colours apart badly)
pub(crate) fn bind_flag(area: &gtk::DrawingArea, color: Option<pe_core::FlagColor>) {
    let name = color.map(pe_core::color_name);
    area.set_tooltip_text(name);
    area.update_property(&[gtk::accessible::Property::Label(name.unwrap_or_default())]);
    area.set_draw_func(move |_, cr, _, _| {
        if let Some(color) = color {
            draw_flag(cr, 0.0, 0.0, color);
        }
    });
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
        set_class(&area, "dim-label", ignored);
        bind_flag(&area, color);
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
        set_class(&label, "unread", unread);
        set_class(&label, "dim-label", ignored);
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

/// How far a reply's subject is indented under its conversation's first message in the Classic list (the Columns rows
/// have their own, rows.rs, as the other apps' Columns rows)
const REPLY_INDENT: i32 = 18;

/// A conversation's disclosure triangle (pan-end or pan-down), which opens or closes it; a click on it does not select
pub(crate) fn thread_expander(item: &gtk::ListItem) -> gtk::Image {
    let expander = gtk::Image::new();
    expander.set_pixel_size(16);
    expander.add_css_class("thread-expander");
    let click = gtk::GestureClick::new();
    let weak = item.downgrade();
    click.connect_pressed(move |gesture, _, _, _| {
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
    expander
}

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
        let expander = thread_expander(item);
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
            // its page is not here yet: a blank line
            expander.set_visible(false);
            label.set_text("");
            return;
        };
        set_class(&label, "unread", unread);
        set_class(&cell, "dim-label", ignored);
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
