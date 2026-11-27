//! The message list: a column view over a list model that pages through the core, 100 rows at a time, as the virtual
//! list view of the Windows app does. The pages are read off the window thread: rows not here yet are blank lines of
//! the same height, filled when their page comes. The columns: the paper clip, the flag, From, Subject (which takes the room the
//! others leave), Received, and Folder while a search lists several folders. Unread messages in bold, ignored
//! conversations grey; the menus check Watch and Ignore Conversation. Every string comes from the core as it decoded
//! it.

use std::cell::{Cell, RefCell};
use std::collections::{BTreeSet, HashSet};
use std::rc::Rc;

use gtk::prelude::*;
use gtk::subclass::prelude::*;
use gtk::{gdk, gio, glib};
use pe_store::{Message, MessageRef, Sort, SortField};

use crate::app::shell;
use crate::list_selection::{MessageSelection, Ranges};
use crate::ui::set_class;

/// The rows of a page, as the core's list loads read them
const PAGE: u32 = pe_core::LIST_PAGE as u32;
/// Pages kept while the list scrolls, the least recently used dropped first
const PAGES_KEPT: usize = 8;
/// The pages of rows GTK keeps out of sight remembered ([`MessageModel::hold`]): its focus and its anchor, with room
const HELD: usize = 4;

/// The widths the Subject and Folder columns start with; the Subject column takes what the others leave, so in a
/// wide window it is wider
const SUBJECT_WIDTH: i32 = 200;
const FOLDER_WIDTH: i32 = 130;
/// The least the Folder column of a search leaves the Subject column
const MIN_SUBJECT_WIDTH: i32 = 90;

/// Asks the core for the page of the list at an offset; false when the window can not ask now (another list is being
/// read, which takes the place of this one)
type AskPage = Rc<dyn Fn(u64) -> bool>;
/// Whether the page at an offset is on screen or next to it
type InSight = Rc<dyn Fn(u32) -> bool>;

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
        /// The pages read, the least recently used first (a row of a page not here is a blank line until it comes)
        pub pages: RefCell<Vec<(u32, Vec<super::MessageRow>)>>,
        /// The offsets of the pages asked of the core and not here yet: a page here again, or dropped from the pages
        /// kept, is asked for again when a row of it is drawn
        pub asked: RefCell<HashSet<u32>>,
        /// Pages a row drawn wants, asked for once the drawing is done
        pub wanted: RefCell<Vec<u32>>,
        pub asking: Cell<bool>,
        /// Asks the core for the page at an offset (`ListPageReady` brings it)
        pub ask: RefCell<Option<AskPage>>,
        /// Whether the page at an offset is on screen or next to it; None: every page wanted is asked for
        pub in_sight: RefCell<Option<InSight>>,
        /// The offsets of the pages whose rows GTK was given since the list was last read (blank ones too): of
        /// those, the ones it can still hold are told as changed when the list is read again
        pub served: RefCell<BTreeSet<u32>>,
        /// The offsets of the pages of the rows GTK keeps whether they are in sight or not: those last clicked or
        /// given the focus (its selection's anchor and its focus), the newest last
        pub held: RefCell<Vec<u32>>,
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

        /// The row at `position` from the pages here. A row of a page not here is a blank line of the row's height,
        /// not kept, and its page is wanted with the page after it (no query here: GTK asks while it draws, and on a
        /// change of the whole list it reads every row, so a row read must neither push a page read out of those
        /// kept nor ask for a page nobody sees)
        fn item(&self, position: u32) -> Option<glib::Object> {
            let total = self.total.get();
            if position >= total {
                return None;
            }
            let offset = position / PAGE * PAGE;
            self.served.borrow_mut().insert(offset);
            {
                let mut pages = self.pages.borrow_mut();
                if let Some(index) = pages.iter().position(|(at, _)| *at == offset) {
                    // the most recently used page goes last
                    let page = pages.remove(index);
                    pages.push(page);
                    let row = pages
                        .last()
                        .and_then(|(_, rows)| rows.get((position - offset) as usize).cloned());
                    // a page shorter than the list said has blank lines at its end
                    return Some(row.unwrap_or_else(super::MessageRow::blank).upcast());
                }
            }
            self.want(offset);
            if offset + PAGE < total {
                self.want(offset + PAGE);
            }
            Some(super::MessageRow::blank().upcast())
        }
    }

    impl MessageModel {
        /// The page at `offset` asked of the core once GTK is done drawing, unless asked for already
        pub(super) fn want(&self, offset: u32) {
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
                let in_sight = imp.in_sight.borrow().clone();
                for offset in wanted {
                    // only the pages on screen or next to it; one not asked is asked for when its rows are drawn
                    let needed = in_sight.as_ref().is_none_or(|in_sight| in_sight(offset));
                    let asked = needed && ask.as_ref().is_some_and(|ask| ask(u64::from(offset)));
                    if !asked {
                        imp.asked.borrow_mut().remove(&offset);
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
    /// Lists `total` rows of its view, `read` the page of them read already (its offset and rows). Never told as a
    /// change of the whole list, for which GTK reads every row on the window thread (a second for a folder of 200,000
    /// messages, once for each list view): the same list read again (`same_list`) tells only the rows GTK was given
    /// and the change in length at its end; another list is every row removed, then the new ones added, of which GTK
    /// reads only those it draws.
    fn reset(&self, total: u64, read: Option<(u64, Vec<Message>)>, same_list: bool) {
        let imp = self.imp();
        let before = imp.total.get();
        let mut pages = imp.pages.borrow_mut();
        let cached: Vec<u32> = pages.iter().map(|(at, _)| *at).collect();
        pages.clear();
        imp.asked.borrow_mut().clear();
        imp.wanted.borrow_mut().clear();
        if let Some((offset, rows)) = read
            && let Ok(offset) = u32::try_from(offset)
        {
            pages.push((offset, rows.into_iter().map(MessageRow::new).collect()));
        }
        drop(pages);
        let now = u32::try_from(total).unwrap_or(u32::MAX);
        // the rows GTK reads while it is told fill the pages served anew
        let served = std::mem::take(&mut *imp.served.borrow_mut());
        // after each change told, the list is as long as that change leaves it: GTK reads it then
        if !same_list {
            // another list's rows: none of them is GTK's focus yet
            imp.held.borrow_mut().clear();
            if before > 0 {
                imp.total.set(0);
                self.items_changed(0, before, 0);
            }
            imp.total.set(now);
            if now > 0 {
                self.items_changed(0, 0, now);
            }
            return;
        }
        // of the rows GTK was given, those it can still hold: on screen or next to it, its focus and anchor, and the
        // pages kept (a long scroll gave it far more, long dropped); a few spans whatever the scroll
        let in_sight = imp.in_sight.borrow().clone();
        let held = imp.held.borrow().clone();
        let holds = |offset: &u32| {
            held.contains(offset)
                || cached.contains(offset)
                || in_sight.as_ref().is_none_or(|in_sight| in_sight(*offset))
        };
        let served: BTreeSet<u32> = served.into_iter().filter(holds).collect();
        for (start, count) in served_spans(&served, before.min(now)) {
            self.items_changed(start, count, count);
        }
        imp.total.set(now);
        if now > before {
            self.items_changed(before, 0, now - before);
        } else if now < before {
            self.items_changed(now, before - now, 0);
        }
    }

    /// The row `position` kept by GTK out of sight too (clicked, or given the focus)
    pub fn hold(&self, position: u32) {
        let offset = position / PAGE * PAGE;
        let mut held = self.imp().held.borrow_mut();
        held.retain(|at| *at != offset);
        if held.len() >= HELD {
            held.remove(0);
        }
        held.push(offset);
    }

    /// The pages of the rows `first` to `last` (those on screen) asked for when they are neither here nor asked for:
    /// a row drawn while the list's scrolling still described the list before (a list read again, grouped or not)
    /// was taken for one off screen and its page not asked for, and GTK, which keeps the row it drew, does not draw
    /// it again, so it stayed blank once the list was scrolled to it
    fn ask_on_screen(&self, first: u32, last: u32) {
        let imp = self.imp();
        let total = imp.total.get();
        if total == 0 {
            return;
        }
        let last = last.min(total - 1);
        let mut offset = first.min(last) / PAGE * PAGE;
        while offset <= last {
            if !imp.pages.borrow().iter().any(|(at, _)| *at == offset) {
                imp.want(offset);
            }
            offset += PAGE;
        }
    }

    /// The page read at `offset` in place of its blank lines: the range of rows that changed, None when the page is
    /// past the end of the list
    fn fill(&self, offset: u64, rows: Vec<Message>) -> Option<(u32, u32)> {
        let imp = self.imp();
        let total = imp.total.get();
        let offset = u32::try_from(offset).ok()?;
        imp.asked.borrow_mut().remove(&offset);
        let offset = Some(offset).filter(|o| *o < total && o % PAGE == 0)?;
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
    pub selection: MessageSelection,
    model: MessageModel,
    /// The view of the list drawn: a reset of another list ([`pe_core::ListView::same_rows`]) starts it anew
    listed: RefCell<Option<pe_core::ListView>>,
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
    /// A page is being drawn: a change of the selection told meanwhile is the list's, not the user's
    filling: Cell<bool>,
}

impl MessageList {
    pub fn new() -> Rc<MessageList> {
        let model: MessageModel = glib::Object::new();
        let selection = MessageSelection::new(&model);
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
        // the security bar's own marks, so the list and the bar say the same thing
        view.append_column(&icon_column(security_icon, security_tip));
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
        // the hidden one has no rows, so it reads none (set_columns gives them to the one shown)
        let rows_view = gtk::ListView::new(None::<gtk::SelectionModel>, Some(crate::rows::factory(context)));
        rows_view.add_css_class("message-list");
        rows_view.add_css_class("message-rows");
        rows_view.set_widget_name("message-rows");
        rows_view.set_tab_behavior(gtk::ListTabBehavior::Item);
        rows_view.add_controller(file_drop_target());
        let sort_button = sort_button();
        let widget = list_stack(&view, &rows_view, &sort_button);
        *model.imp().in_sight.borrow_mut() = Some(in_sight(&model, &widget, &view, &rows_view));
        ask_on_screen_when_scrolled(&model, &widget, &view, &rows_view);
        Rc::new(MessageList {
            view,
            rows_view,
            widget,
            sort_button,
            selection,
            model,
            listed: RefCell::new(None),
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
            filling: Cell::new(false),
        })
    }

    /// The senders' pictures shown in the rows of three lines or not (taken at the list's next refresh)
    pub fn set_pictures(&self, on: bool) {
        self.pictures.set(on);
    }

    /// The Columns layout's list (`on`), or the Classic one: the rows and the selection the one shown's, the other
    /// without them
    pub fn set_columns(&self, on: bool) {
        let none = None::<gtk::SelectionModel>;
        if on {
            self.view.set_model(none.as_ref());
            self.rows_view.set_model(Some(&self.selection));
        } else {
            self.rows_view.set_model(none.as_ref());
            self.view.set_model(Some(&self.selection));
        }
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
        // a row past the end (a place asked for before the list became shorter) is no place: GTK would refuse it
        if index >= self.model.n_items() {
            return;
        }
        if flags.contains(gtk::ListScrollFlags::FOCUS) {
            self.model.hold(index);
        }
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
    pub fn connect_page_wanted(&self, ask: impl Fn(u64) -> bool + 'static) {
        *self.model.imp().ask.borrow_mut() = Some(Rc::new(ask));
    }

    /// The message of row `position` as the list has it now: None while its page is not here (the e2e driver)
    #[cfg(feature = "e2e")]
    pub fn message_at(&self, position: u32) -> Option<Message> {
        self.model
            .item(position)
            .and_downcast::<MessageRow>()?
            .with(Message::clone)
    }

    /// The page at `offset` was asked for and not read: asked for again when its rows are drawn
    pub fn page_not_read(&self, offset: u64) {
        if let Ok(offset) = u32::try_from(offset) {
            self.model.imp().asked.borrow_mut().remove(&offset);
        }
    }

    /// A page of the list read at `offset`, drawn in place of its blank lines with the selection kept
    pub fn fill_page(&self, offset: u64, rows: Vec<Message>) {
        self.filling.set(true);
        fill_keeping_selection(&self.selection, &self.model, offset, rows);
        self.filling.set(false);
    }

    /// Whether a change of the selection told now is a page drawn ([`MessageList::fill_page`]), not the user's pick
    pub fn filling(&self) -> bool {
        self.filling.get()
    }

    /// The list again: the rows of its view, `total` of them (`read` the page of them read already, its offset and
    /// rows), the rows `select` selected; scrolled as it was when it is the same list read again (`same`, GTK keeps
    /// the place), else from the top. `reveal`: the rows selected scrolled to when they are not in sight; not for the
    /// message shown kept when it was out of sight, so the list stays where the user scrolled it
    pub fn reset(
        self: &Rc<Self>,
        total: u64,
        read: Option<(u64, Vec<Message>)>,
        select: &[u64],
        same: bool,
        reveal: bool,
    ) {
        self.clock.set(crate::rows::Clock::now());
        let view = self.view().clone();
        let same_list = self
            .listed
            .borrow()
            .as_ref()
            .is_some_and(|drawn| drawn.same_rows(&view));
        *self.listed.borrow_mut() = Some(view);
        self.model.reset(total, read, same_list);
        self.select_positions(select);
        // another list starts at its top (GTK keeps the place it had), unless a selection is shown
        if !same && select.is_empty() && self.model.n_items() > 0 {
            self.scroll_to(0, gtk::ListScrollFlags::NONE);
        }
        if reveal {
            self.reveal(select);
        }
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
            let ends = {
                let selected = list.selection.ranges();
                (selected.first(), selected.last())
            };
            if rows == 0 || first >= rows || ends != (Some(first), Some(last)) {
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

    /// The first and the last row on screen; None before the list has a size
    #[cfg(feature = "e2e")]
    pub fn rows_in_sight(&self) -> Option<(u32, u32)> {
        sight(&self.widget, &self.view, &self.rows_view, self.model.n_items())
    }

    /// The message drawn at `position`: its page's when it is here, None while it is not, asking for nothing (what a
    /// test looks at, so that looking does not fill a row the window left blank)
    #[cfg(feature = "e2e")]
    pub fn drawn_at(&self, position: u32) -> Option<Message> {
        let offset = position / PAGE * PAGE;
        let pages = self.model.imp().pages.borrow();
        let (_, rows) = pages.iter().find(|(at, _)| *at == offset)?;
        rows.get((position - offset) as usize)?.with(Message::clone)
    }

    /// Whether the rows drawn are the list as the core reads it now (the deep test's quiet): the rows strictly inside
    /// the estimate of those on screen, which can be a row off at either edge
    #[cfg(feature = "e2e")]
    pub fn drawn_current(&self) -> bool {
        let rows = self.rows();
        let drawn: Vec<(u64, Option<pe_store::MessageRef>)> = self
            .rows_in_sight()
            .map(|(first, last)| {
                (first + 1..last.min(rows.saturating_sub(1)))
                    .map(|row| {
                        let at = self.drawn_at(row).map(|m| pe_store::MessageRef {
                            folder: m.folder_id,
                            uid: m.info.uid,
                        });
                        (u64::from(row), at)
                    })
                    .collect()
            })
            .unwrap_or_default();
        self.view()
            .drawn_current(&shell().core, u64::from(rows), &drawn)
            .unwrap_or(false)
    }

    /// Whether every selected row is in sight
    pub fn selection_in_sight(&self) -> bool {
        let rows = self.model.n_items();
        // nothing selected also when the list is empty
        let (Some(first), Some(last)) = ({
            let selected = self.selection.ranges();
            (selected.first(), selected.last())
        }) else {
            return false;
        };
        let Some(adjustment) = self.adjustment() else {
            return true;
        };
        let row = adjustment.upper() / f64::from(rows);
        let top = adjustment.value();
        f64::from(first) * row >= top - 0.5 && f64::from(last + 1) * row <= top + adjustment.page_size() + 0.5
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
        self.selection.ranges().size()
    }

    /// The one selected row and its position; None when none or several are
    pub fn selected(&self) -> Option<(u32, Message)> {
        let position = {
            let selected = self.selection.ranges();
            selected.first().filter(|_| selected.size() == 1)?
        };
        let row = self.model.item(position).and_downcast::<MessageRow>()?;
        Some((position, row.with(Message::clone)?))
    }

    /// The selected positions as ranges, start included and end not, ascending
    pub fn selected_ranges(&self) -> Vec<(u64, u64)> {
        self.selection
            .ranges()
            .spans()
            .iter()
            .map(|&(start, end)| (u64::from(start), u64::from(end)))
            .collect()
    }

    /// The last selected position
    pub fn last_selected(&self) -> Option<u32> {
        self.selection.ranges().last()
    }

    /// Whether the row at `position` is selected
    pub fn is_selected(&self, position: u32) -> bool {
        self.selection.is_selected(position)
    }

    /// Selects only the rows at `positions`
    pub fn select_positions(&self, positions: &[u64]) {
        let rows = self.model.n_items();
        let mut wanted = Ranges::default();
        for position in positions {
            if let Ok(position) = u32::try_from(*position)
                && position < rows
            {
                wanted.add(position, position + 1);
            }
        }
        self.selection.set_ranges(wanted);
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

/// Whether the page at an offset is among the rows of the list shown on screen, or a page next to them: those asked
/// of the core. Every page while the list has no size yet.
fn in_sight(model: &MessageModel, stack: &gtk::Stack, view: &gtk::ColumnView, rows: &gtk::ListView) -> InSight {
    let model = model.downgrade();
    let (stack, view, rows) = (stack.clone(), view.clone(), rows.clone());
    Rc::new(move |offset| {
        let Some(model) = model.upgrade() else {
            return false;
        };
        let Some((first, last)) = sight(&stack, &view, &rows, model.n_items()) else {
            return true;
        };
        let from = (first / PAGE * PAGE).saturating_sub(PAGE);
        let to = last / PAGE * PAGE + PAGE;
        (from..=to).contains(&offset)
    })
}

/// A page of `model` read at `offset` drawn with the selection kept (its rows change in place, which the selection
/// keeps). The one row selected, when it was blank (clicked before its page came), is told as changed once it has
/// its message: the selection itself did not change, and the window would never open the message it shows selected.
/// Several selected are not told: they name no message to open, and the window would list and count them all again
/// for each page scrolled to (after Select All, every message of the list).
fn fill_keeping_selection(selection: &MessageSelection, model: &MessageModel, offset: u64, rows: Vec<Message>) {
    let Some((start, count)) = model.fill(offset, rows) else {
        return;
    };
    // the selection let go of before it is told: what hears it may select
    let told = told_on_fill(&selection.ranges(), start, count);
    if let Some(row) = told {
        selection.selection_changed(row, 1);
    }
}

/// The row a page of `count` rows from `start` tells as changed when it is drawn: the one row selected, when it is
/// among them
fn told_on_fill(selected: &Ranges, start: u32, count: u32) -> Option<u32> {
    (selected.size() == 1)
        .then(|| selected.first())
        .flatten()
        .filter(|row| (start..start + count).contains(row))
}

/// The rows of the pages at `offsets` (ascending) before row `rows`, as spans (position, how many), pages next to each
/// other in one span
fn served_spans(offsets: &BTreeSet<u32>, rows: u32) -> Vec<(u32, u32)> {
    let mut spans: Vec<(u32, u32)> = Vec::new();
    for &offset in offsets.iter().take_while(|&&offset| offset < rows) {
        let count = PAGE.min(rows - offset);
        match spans.last_mut() {
            Some((start, n)) if *start + *n == offset => *n += count,
            _ => spans.push((offset, count)),
        }
    }
    spans
}

/// Whenever either list's scrolling changes (scrolled, or its length changed with the rows), the pages on screen not
/// here are asked for (`MessageModel::ask_on_screen`)
fn ask_on_screen_when_scrolled(model: &MessageModel, stack: &gtk::Stack, view: &gtk::ColumnView, rows: &gtk::ListView) {
    let adjustments = [view.vadjustment(), rows.vadjustment()];
    for adjustment in adjustments.into_iter().flatten() {
        let ask = {
            let model = model.downgrade();
            let (stack, view, rows) = (stack.clone(), view.clone(), rows.clone());
            move || {
                let Some(model) = model.upgrade() else { return };
                if let Some((first, last)) = sight(&stack, &view, &rows, model.n_items()) {
                    model.ask_on_screen(first, last);
                }
            }
        };
        let again = ask.clone();
        adjustment.connect_value_changed(move |_| ask());
        adjustment.connect_changed(move |_| again());
    }
}

/// The first and the last row of `total` on screen, from the shown list's scrolling; None before it has a size
fn sight(stack: &gtk::Stack, view: &gtk::ColumnView, rows: &gtk::ListView, total: u32) -> Option<(u32, u32)> {
    let adjustment = if stack.visible_child_name().as_deref() == Some("columns") {
        rows.vadjustment()
    } else {
        view.vadjustment()
    };
    let adjustment = adjustment.filter(|a| a.upper() > 0.0 && total > 0)?;
    let row = adjustment.upper() / f64::from(total);
    let first = (adjustment.value() / row) as u32;
    let last = ((adjustment.value() + adjustment.page_size()) / row) as u32;
    Some((first, last.min(total - 1)))
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

/// The lock of an encrypted message or the ribbon of a signed one, from its structure before it is opened (encrypted
/// wins: such a message is often signed inside too); none for the others
pub(crate) fn security_icon(m: &Message) -> Option<&'static str> {
    match m.info.protection {
        pe_store::Protection::Encrypted => Some("ic-lock-closed-symbolic"),
        pe_store::Protection::Signed => Some("ic-ribbon-symbolic"),
        pe_store::Protection::None => None,
    }
}

/// What the security mark says on hover and to a screen reader, the core's words: Encrypted or Signed
pub(crate) fn security_tip(m: &Message) -> Option<String> {
    pe_core::protection_words(m.info.protection)
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
        crate::icons::set(&image, name);
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
        // the subject as wide as its words, the reactions right after it taking the rest of the cell: a long subject
        // is cut short, never the reactions
        let label = gtk::Label::new(None);
        label.set_xalign(0.0);
        label.set_ellipsize(gtk::pango::EllipsizeMode::End);
        let reactions = reactions_label();
        cell.append(&expander);
        cell.append(&label);
        cell.append(&reactions);
        add_drag_source(&label, item);
        add_drag_source(&reactions, item);
        item.set_child(Some(&cell));
    });
    factory.connect_bind(|_, item| {
        let Some(item) = item.downcast_ref::<gtk::ListItem>() else {
            return;
        };
        let Some(cell) = item.child().and_downcast::<gtk::Box>() else {
            return;
        };
        let expander = cell.first_child().and_downcast::<gtk::Image>();
        let label = expander
            .as_ref()
            .and_then(|e| e.next_sibling())
            .and_downcast::<gtk::Label>();
        let reactions = cell.last_child().and_downcast::<gtk::Label>();
        let (Some(expander), Some(label), Some(reactions)) = (expander, label, reactions) else {
            return;
        };
        let Some(row) = item.item().and_downcast::<MessageRow>() else {
            return;
        };
        let Some((subject, thread, unread, ignored, badge)) = row.with(|m| {
            (
                m.info.subject.clone(),
                m.thread,
                m.bold(),
                m.dimmed(),
                pe_core::reactions::badge(&m.reactions),
            )
        }) else {
            // its page is not here yet: a blank line
            expander.set_visible(false);
            label.set_text("");
            reactions.set_text("");
            return;
        };
        reactions.set_text(&badge);
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
        crate::icons::set(
            &expander,
            match (place.opens(), place.collapsed()) {
                (false, _) => None,
                (true, true) => Some("pan-end-symbolic"),
                (true, false) => Some("pan-down-symbolic"),
            },
        );
        if place.opens() {
            label.set_text(&format!(
                "{subject} {}",
                pe_core::thread_count(place.count, place.unread)
            ));
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

/// The label of a row's reactions after its subject: the core's badge ("👍❤️ 3"), its count in the list's secondary
/// colour (the emoji keep their own colours), never cut short; it takes the rest of the line, so the marks after it
/// stay at the line's end
pub(crate) fn reactions_label() -> gtk::Label {
    let label = gtk::Label::new(None);
    label.set_xalign(0.0);
    label.set_hexpand(true);
    label.set_single_line_mode(true);
    let attributes = gtk::pango::AttrList::new();
    // 55%, as libadwaita's dim-label, which on the label itself would dim the emoji too
    attributes.insert(gtk::pango::AttrInt::new_foreground_alpha(36000));
    label.set_attributes(Some(&attributes));
    label
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

#[cfg(test)]
mod tests {
    use super::*;

    fn message(uid: u64) -> Message {
        Message {
            id: uid as i64,
            folder_id: 1,
            info: pe_store::MessageInfo {
                uid,
                ..Default::default()
            },
            cached: false,
            thread: None,
            mark: Default::default(),
            snippet: None,
            sender_auth: 0,
            logo: None,
            contact: None,
            snippet_is_state: false,
            reactions: Vec::new(),
        }
    }

    fn page(offset: u32) -> Vec<Message> {
        (offset..offset + PAGE).map(|at| message(u64::from(at) + 1)).collect()
    }

    /// The model of a list of `total` rows with its first page, and the offsets it asks for (`refuse`: the window
    /// can not ask now)
    fn model(total: u64, refuse: Rc<Cell<bool>>) -> (MessageModel, Rc<RefCell<Vec<u64>>>) {
        let model: MessageModel = glib::Object::new();
        let asked: Rc<RefCell<Vec<u64>>> = Rc::default();
        let into = asked.clone();
        *model.imp().ask.borrow_mut() = Some(Rc::new(move |offset| {
            if refuse.get() {
                return false;
            }
            into.borrow_mut().push(offset);
            true
        }));
        model.reset(total, Some((0, page(0))), false);
        (model, asked)
    }

    /// The idle callbacks run: the pages wanted are asked for
    fn idle() {
        let context = glib::MainContext::default();
        while context.iteration(false) {}
    }

    /// `test` owning GLib's default context, where the model's idle callbacks go, one test at a time
    fn with_context(test: impl FnOnce()) {
        static ONE_AT_A_TIME: std::sync::Mutex<()> = std::sync::Mutex::new(());
        let _turn = ONE_AT_A_TIME.lock().unwrap_or_else(|e| e.into_inner());
        let context = glib::MainContext::default();
        let _owner = context.acquire().expect("the default context");
        test();
    }

    fn uid(model: &MessageModel, position: u32) -> Option<u64> {
        model.item(position).and_downcast::<MessageRow>()?.with(|m| m.info.uid)
    }

    /// The pages asked for come, as the core answers them
    fn answer(model: &MessageModel, asked: &RefCell<Vec<u64>>) {
        for offset in asked.take() {
            model.fill(offset, page(offset as u32));
        }
    }

    /// Rows read far down the list (an accessibility client, a long scroll) drop the first page from the pages kept:
    /// its rows read again are blank at first, then asked for and filled, never blank for good, which left the Inbox
    /// blank on Omarchy with rows a click could not open
    #[test]
    fn a_page_dropped_from_those_kept_is_asked_for_again() {
        with_context(|| {
            let (model, asked) = model(3065, Rc::default());
            assert_eq!(uid(&model, 0), Some(1));
            for at in 1..=PAGES_KEPT as u32 + 1 {
                let _ = model.item(at * PAGE);
                idle();
                answer(&model, &asked);
            }
            assert_eq!(
                uid(&model, 0),
                None,
                "the first page was dropped: its rows are blank for now"
            );
            idle();
            assert!(
                asked.borrow().contains(&0),
                "and asked for again ({:?})",
                asked.borrow()
            );
            answer(&model, &asked);
            assert_eq!(uid(&model, 0), Some(1));
            assert_eq!(uid(&model, 99), Some(100));
        });
    }

    /// A row drawn while the scrolling still says the list before is taken for one off screen and its page not asked
    /// for; once the list is scrolled there, the page is asked for and the row filled, never blank for good (the deep
    /// test's row 1625 of a search turned from conversations to messages)
    #[test]
    fn a_row_drawn_before_the_scrolling_caught_up_is_filled() {
        with_context(|| {
            let (model, asked) = model(1902, Rc::default());
            *model.imp().in_sight.borrow_mut() = Some(Rc::new(|offset| offset < 200));
            let _ = model.item(1625);
            idle();
            assert!(asked.borrow().is_empty(), "taken for a row off screen");
            assert_eq!(uid(&model, 1625), None);
            // the scrolling catches up: rows 1610 to 1640 on screen
            *model.imp().in_sight.borrow_mut() = Some(Rc::new(|offset| (1500..=1700).contains(&offset)));
            model.ask_on_screen(1610, 1640);
            model.ask_on_screen(1610, 1640);
            idle();
            // (with the page after it, which a blank row read asks for too)
            let once = asked.borrow().iter().filter(|&&offset| offset == 1600).count();
            assert_eq!(once, 1, "asked for once ({:?})", asked.borrow());
            answer(&model, &asked);
            assert_eq!(uid(&model, 1625), Some(1626));
            // pages here are not asked for again
            model.ask_on_screen(0, 40);
            idle();
            assert!(asked.borrow().is_empty());
        });
    }

    /// A row clicked while it was blank opens once its page comes: the one row selected is told as changed then;
    /// several selected (Select All) are not, so a page scrolled to never lists and counts them all again
    #[test]
    fn a_row_selected_blank_is_told_when_its_page_comes() {
        let mut one = Ranges::default();
        one.select(1625, 1, true);
        assert_eq!(told_on_fill(&one, 1600, 100), Some(1625));
        assert_eq!(told_on_fill(&one, 0, 100), None);
        let mut all = Ranges::default();
        all.select(0, 200_000, true);
        assert_eq!(told_on_fill(&all, 1600, 100), None);
    }

    /// GTK reads every row when the whole list changes: the first page stays, and only the pages on screen or next to
    /// it are asked of the core, not every page of the list
    #[test]
    fn reading_every_row_asks_only_for_the_pages_in_sight() {
        with_context(|| {
            let (model, asked) = model(3065, Rc::default());
            *model.imp().in_sight.borrow_mut() = Some(Rc::new(|offset| offset < 200));
            for position in 0..3065 {
                let _ = model.item(position);
            }
            idle();
            assert_eq!(
                *asked.borrow(),
                vec![100],
                "the page after the first, nothing further down"
            );
            assert_eq!(uid(&model, 0), Some(1), "the first page is still here");
            assert_eq!(uid(&model, 99), Some(100));
        });
    }

    /// A page the window did not ask for (another list was being read) is asked for when its rows are drawn again
    #[test]
    fn a_page_not_asked_for_is_asked_for_later() {
        with_context(|| {
            let refuse = Rc::new(Cell::new(true));
            let (model, asked) = model(3065, refuse.clone());
            assert_eq!(uid(&model, 250), None);
            idle();
            assert!(asked.borrow().is_empty());
            refuse.set(false);
            assert_eq!(uid(&model, 250), None, "blank until its page comes");
            idle();
            assert!(asked.borrow().contains(&200), "asked for now ({:?})", asked.borrow());
            answer(&model, &asked);
            assert_eq!(uid(&model, 250), Some(251));
        });
    }

    /// The changes `model` tells, as (position, removed, added), each with the list as long as it leaves it (GTK
    /// reads the length then, and crashes on a list longer or shorter than its changes say)
    fn changes(model: &MessageModel) -> Rc<RefCell<Vec<(u32, u32, u32)>>> {
        let told: Rc<RefCell<Vec<(u32, u32, u32)>>> = Rc::default();
        let into = told.clone();
        let length = Rc::new(Cell::new(model.n_items()));
        model.connect_items_changed(move |model, position, removed, added| {
            let expected = length.get() - removed + added;
            assert_eq!(
                model.n_items(),
                expected,
                "the length after ({position}, {removed}, {added})"
            );
            length.set(expected);
            into.borrow_mut().push((position, removed, added));
        });
        told
    }

    /// A folder of 200,000 messages read again (a message read, a sync) is never told as a change of the whole list,
    /// for which GTK reads every row: only the pages GTK was given and the rows that came at the end; another list is
    /// every row removed and the new ones added, of which GTK reads only those it draws
    #[test]
    fn a_list_read_again_tells_only_the_rows_drawn() {
        with_context(|| {
            let (model, _) = model(200_000, Rc::default());
            for position in (0..30).chain(5_020..5_050).chain(5_090..5_110) {
                let _ = model.item(position);
            }
            idle();
            let told = changes(&model);
            model.reset(200_003, Some((0, page(0))), true);
            assert_eq!(
                *told.take(),
                vec![(0, 100, 100), (5_000, 200, 200), (200_000, 0, 3)],
                "the pages drawn, then three new rows"
            );
            assert_eq!(uid(&model, 5), Some(6));
            model.reset(150_000, None, true);
            assert_eq!(
                *told.take(),
                vec![(0, 100, 100), (150_000, 50_003, 0)],
                "the page drawn since, then the rows that went"
            );
            model.reset(9_000, Some((0, page(0))), false);
            assert_eq!(*told.take(), vec![(0, 150_000, 0), (0, 0, 9_000)], "another list");
            assert_eq!(model.n_items(), 9_000);
        });
    }

    /// After a long scroll (or a drag of the scroll bar over the whole list) GTK was given rows of hundreds of pages
    /// and holds only those on screen, its focus and anchor: a reload tells those, a few spans, never most of the
    /// list
    #[test]
    fn a_reload_after_a_long_scroll_tells_only_what_gtk_holds() {
        with_context(|| {
            let (model, _) = model(200_000, Rc::default());
            for position in (0..120_000).step_by(37) {
                let _ = model.item(position);
            }
            // the pages wanted asked for on this thread, not left to the next test's
            idle();
            model.hold(30_005);
            // scrolled to rows 119,950 to 119,990
            *model.imp().in_sight.borrow_mut() = Some(Rc::new(|offset| (119_800..=120_000).contains(&offset)));
            let told = changes(&model);
            model.reset(200_000, Some((119_900, page(119_900))), true);
            assert_eq!(
                *told.take(),
                vec![(0, 100, 100), (30_000, 100, 100), (119_800, 200, 200)]
            );
        });
    }

    /// The selection is row numbers, never the rows' objects, and follows the model's changes as the list's
    /// selection does (MessageSelection, which needs GTK running): Select All of 200,000 rows reads none of them and
    /// keeps through the list read again, the rows that came at its end not selected; a page drawn keeps the rows
    /// selected on it; another list has none selected
    #[test]
    fn the_selection_follows_the_list_read_again() {
        with_context(|| {
            let (model, _) = model(200_000, Rc::default());
            let selected = Rc::new(RefCell::new(Ranges::default()));
            let follows = selected.clone();
            model.connect_items_changed(move |_, position, removed, added| {
                follows.borrow_mut().splice(position, removed, added);
            });
            selected.borrow_mut().select(0, model.n_items(), true);
            assert!(model.imp().served.borrow().is_empty(), "no row read");
            for position in 0..40 {
                let _ = model.item(position);
            }
            idle();
            model.reset(200_002, Some((0, page(0))), true);
            assert_eq!(selected.borrow().spans(), [(0, 200_000)]);
            selected.borrow_mut().select(150, 10, true);
            model.fill(100, page(100));
            assert_eq!(selected.borrow().spans(), [(150, 160)], "a page drawn");
            assert_eq!(uid(&model, 150), Some(151));
            model.reset(10, None, false);
            assert!(selected.borrow().is_empty(), "another list: nothing selected");
        });
    }
}
