//! The reading pane's message, or its whole conversation, as a native stack (docs/conversation-view-plan.md): the
//! conversation's subject and who is in it, then a row for each folded message (one boxed list for the rows next to
//! each other) and a frame for each open one, its body a web view of the message's own document as tall as the
//! document, the stack scrolling as one. The words and the choices are the core's ([`pe_core::conversation::Entry`]);
//! a click is handed to the reader, which asks the core and builds the view again, the frames of the same messages
//! kept with their web views.

use adw::prelude::*;
use gtk::{gdk, glib};
use pe_core::conversation::Entry;
use pe_core::{MessageRef, MessageView};
use std::cell::{Cell, RefCell};
use std::collections::HashMap;
use std::rc::Rc;
use webkit::prelude::*;

use crate::commands::Command;
use crate::row_pictures::RowPicture;
use crate::ui;
use crate::webview::DocumentView;

/// A body's height is measured until it stayed the same this many times in a row (400 ms apart)
const SETTLED: u32 = 5;

/// What a click in the stack asks of the core, on the message at an entry's index
#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub enum Click {
    /// A row or a frame: a folded message opens; either way it is selected
    Select,
    /// The arrow: a folded message opens and is selected, an open one folds
    Toggle,
    /// The folded middle's row: every message gets its row
    ShowMiddle,
    /// Left with the stack in front: every message folded but the selected one
    FoldAll,
    /// Right: every message open
    OpenAll,
    /// Next Message in Conversation: the message after the selected one opened and selected
    Next,
    /// Previous Message in Conversation
    Previous,
}

/// What the stack asks of the reader
pub enum Ask {
    Click(Click, usize),
    /// A frame's Reply, Reply All or Forward: its message selected, then the command
    Command(Command, MessageRef),
    /// A frame's More menu, at its button: its message selected first
    More(MessageRef, gtk::Widget),
    /// A draft's Edit
    Edit(MessageRef),
    /// A double-click on a row or a frame: the message in a window of its own
    OpenWindow(MessageRef),
}

type Asked = Rc<RefCell<Option<Rc<dyn Fn(Ask)>>>>;
type Bodies = Rc<RefCell<Option<Rc<dyn Fn(&webkit::WebView)>>>>;
type Links = Rc<RefCell<Option<Rc<dyn Fn(&str) -> bool>>>>;

/// The stack: a scrolled column of the conversation's title, its rows and frames
pub struct Stack {
    pub widget: gtk::ScrolledWindow,
    subject: gtk::Label,
    summary: gtk::Label,
    items: gtk::Box,
    frames: RefCell<HashMap<MessageRef, Rc<Frame>>>,
    rows: RefCell<Vec<(Entry, gtk::ListBoxRow)>>,
    gaps: RefCell<Vec<gtk::Button>>,
    asked: Asked,
    links: Links,
    bodies: Bodies,
}

impl Stack {
    pub fn new() -> Rc<Stack> {
        let subject = gtk::Label::builder()
            .xalign(0.0)
            .wrap(true)
            .wrap_mode(gtk::pango::WrapMode::WordChar)
            .selectable(true)
            .build();
        subject.add_css_class("title-3");
        subject.set_widget_name("stack-subject");
        let summary = gtk::Label::builder()
            .xalign(0.0)
            .ellipsize(gtk::pango::EllipsizeMode::End)
            .build();
        summary.add_css_class("dim-label");
        summary.set_widget_name("stack-summary");
        let items = gtk::Box::new(gtk::Orientation::Vertical, 8);
        let column = gtk::Box::new(gtk::Orientation::Vertical, 4);
        column.set_margin_top(10);
        column.set_margin_bottom(16);
        column.set_margin_start(12);
        column.set_margin_end(12);
        column.append(&subject);
        column.append(&summary);
        items.set_margin_top(8);
        column.append(&items);
        let widget = gtk::ScrolledWindow::builder()
            .hscrollbar_policy(gtk::PolicyType::Never)
            .vexpand(true)
            .hexpand(true)
            .child(&column)
            .build();
        widget.set_widget_name("reader-stack");
        widget.add_css_class("view");
        let stack = Rc::new(Stack {
            widget,
            subject,
            summary,
            items,
            frames: RefCell::default(),
            rows: RefCell::default(),
            gaps: RefCell::default(),
            asked: Rc::default(),
            links: Rc::default(),
            bodies: Rc::default(),
        });
        // Left and Right with the stack in front: every message folded but the selected one, or every one open, as
        // Left and Right close and open a conversation's row in the list
        let keys = gtk::EventControllerKey::new();
        let asked = stack.asked.clone();
        keys.connect_key_pressed(move |_, key, _, modifiers| {
            if !modifiers.is_empty() {
                return glib::Propagation::Proceed;
            }
            let click = match key {
                gdk::Key::Left => Click::FoldAll,
                gdk::Key::Right => Click::OpenAll,
                _ => return glib::Propagation::Proceed,
            };
            ask(&asked, Ask::Click(click, 0));
            glib::Propagation::Stop
        });
        stack.widget.add_controller(keys);
        let weak = Rc::downgrade(&stack);
        stack.widget.vadjustment().connect_value_changed(move |_| {
            if let Some(stack) = weak.upgrade() {
                stack.scrolled();
            }
        });
        // the pane resized, or the stack laid out again (frames opened, bodies measured): its height changes
        for adjustment in ["page-size", "upper"] {
            let weak = Rc::downgrade(&stack);
            stack
                .widget
                .vadjustment()
                .connect_notify_local(Some(adjustment), move |_, _| {
                    if let Some(stack) = weak.upgrade() {
                        stack.scrolled();
                    }
                });
        }
        // another width: the documents flow again, their heights measured again
        let weak = Rc::downgrade(&stack);
        stack
            .widget
            .hadjustment()
            .connect_notify_local(Some("page-size"), move |_, _| {
                if let Some(stack) = weak.upgrade() {
                    let frames: Vec<Rc<Frame>> = stack.frames.borrow().values().cloned().collect();
                    for frame in frames {
                        frame.measure();
                    }
                }
            });
        stack
    }

    /// `ask` is told what a click in the stack asks for
    pub fn connect(&self, ask: impl Fn(Ask) + 'static) {
        *self.asked.borrow_mut() = Some(Rc::new(ask));
    }

    /// `made` is told of each frame's body as it is made (Find connects to it)
    pub fn on_body(&self, made: impl Fn(&webkit::WebView) + 'static) {
        *self.bodies.borrow_mut() = Some(Rc::new(made));
    }

    /// `links` is asked of a link clicked in a frame's document before the browser opens it
    pub fn set_links(&self, links: impl Fn(&str) -> bool + 'static) {
        *self.links.borrow_mut() = Some(Rc::new(links));
    }

    /// `view` shown (its selected message's) with its stack's `entries` ([`pe_core::conversation::take_entries`]): its
    /// title and its stack, the frames of the messages already shown kept. `extras` are the reader's own widgets the
    /// selected frame takes: the reactions row under its header, the files under its body. `start` scrolls to the
    /// selected message (a conversation shown anew).
    pub fn show(
        &self,
        view: &Rc<MessageView>,
        entries: Vec<Entry>,
        pictures: bool,
        extras: (&gtk::Widget, &gtk::Widget, &gtk::Widget),
        start: bool,
    ) {
        match &view.conversation {
            Some(conversation) => {
                self.subject.set_text(&conversation.subject);
                self.summary.set_text(&conversation.line);
                self.summary.set_visible(!conversation.line.is_empty());
            }
            None => {
                self.subject.set_text(&view.subject);
                self.summary.set_visible(false);
            }
        }
        let conversation = view.conversation.is_some();
        // a conversation's messages are cards on the window's gray, as GNOME's lists of cards; a message alone is on
        // the page itself
        ui::set_class(&self.widget, "view", !conversation);
        self.reset();
        // a message alone is always the same frame (its key 0, 0, as the core's alone() makes it), so the next one
        // loads into its web view
        let open: Vec<MessageRef> = entries.iter().filter(|e| e.open).map(|e| e.at).collect();
        self.frames.borrow_mut().retain(|at, frame| {
            let keep = open.contains(at);
            if !keep {
                frame.release();
            }
            keep
        });
        let mut group: Option<gtk::ListBox> = None;
        for mut entry in entries {
            if entry.hidden_before > 0 {
                group = None;
                let gap = gtk::Button::with_label(&entry.hidden_text);
                gap.add_css_class("flat");
                gap.add_css_class("stack-middle");
                gap.set_widget_name("stack-middle");
                let (asked, index) = (self.asked.clone(), entry.index);
                gap.connect_clicked(move |_| ask(&asked, Ask::Click(Click::ShowMiddle, index)));
                self.items.append(&gap);
                self.gaps.borrow_mut().push(gap);
            }
            if entry.open {
                group = None;
                // the selected message's document is the view's own, another open one's its entry's view
                let own = if entry.selected {
                    Some(view.clone())
                } else {
                    entry.view.take().map(|v| Rc::new(*v))
                };
                let frame = self
                    .frames
                    .borrow_mut()
                    .entry(entry.at)
                    .or_insert_with(|| {
                        Frame::new(
                            self.asked.clone(),
                            self.links.clone(),
                            self.bodies.clone(),
                            self.widget.clone(),
                        )
                    })
                    .clone();
                let selected = entry.selected;
                frame.show(entry, own, conversation, pictures && selected);
                if selected {
                    frame.take(extras);
                }
                self.items.append(&frame.widget);
                continue;
            }
            let list = group.get_or_insert_with(|| {
                let list = gtk::ListBox::new();
                list.add_css_class("boxed-list");
                list.set_selection_mode(gtk::SelectionMode::None);
                list.set_widget_name("stack-rows");
                let asked = self.asked.clone();
                list.connect_row_activated(move |_, row| {
                    if let Some(index) = row_index(row) {
                        ask(&asked, Ask::Click(Click::Select, index));
                    }
                });
                self.items.append(&list);
                list
            });
            let row = folded_row(&entry, &self.asked);
            list.append(&row);
            self.rows.borrow_mut().push((entry, row));
        }
        if start && let Some(frame) = self.selected_frame() {
            // once laid out: the selected frame's top at the top
            let widget = self.widget.clone();
            let column = self.items.parent();
            glib::idle_add_local_once(move || {
                if let Some(bounds) = column.and_then(|column| frame.widget.compute_bounds(&column)) {
                    let adjustment = widget.vadjustment();
                    // the title kept in view when the frame starts on the first screen
                    let place = f64::from(bounds.y());
                    let top = if place < adjustment.page_size() {
                        0.0
                    } else {
                        place - 8.0
                    };
                    adjustment.set_value(top.clamp(0.0, (adjustment.upper() - adjustment.page_size()).max(0.0)));
                }
            });
        }
        self.scrolled();
        // and again once laid out (after the layout, at the idle priority), for frames that had no place yet: the
        // stack's height may not change, so nothing else asks
        let adjustment = self.widget.vadjustment();
        glib::idle_add_local_once(move || adjustment.emit_by_name::<()>("value-changed", &[]));
    }

    /// Nothing shown: the frames and their web views let go
    pub fn clear(&self) {
        for (_, frame) in self.frames.borrow_mut().drain() {
            frame.release();
        }
        self.reset();
    }

    /// The rows, the folded middles and the frames out of the stack (the frames themselves kept)
    fn reset(&self) {
        while let Some(child) = self.items.first_child() {
            self.items.remove(&child);
        }
        self.rows.borrow_mut().clear();
        self.gaps.borrow_mut().clear();
    }

    /// The frame of the selected message
    fn selected_frame(&self) -> Option<Rc<Frame>> {
        self.frames.borrow().values().find(|f| f.selected()).cloned()
    }

    /// The place in its conversation of the open message `at`, what a click on it hands the core
    pub fn index_of(&self, at: MessageRef) -> Option<usize> {
        self.frames
            .borrow()
            .get(&at)
            .and_then(|f| f.entry.borrow().as_ref().map(|e| e.index))
    }

    /// The stack scrolled or laid out: the bodies near what is seen made, those far from it let go (their heights
    /// kept), so a long conversation with many open messages holds only a few web views
    fn scrolled(&self) {
        let adjustment = self.widget.vadjustment();
        let reach = adjustment.page_size().max(400.0) * 2.0;
        let (top, bottom) = (
            adjustment.value() - reach,
            adjustment.value() + adjustment.page_size() + reach,
        );
        let frames: Vec<Rc<Frame>> = self.frames.borrow().values().cloned().collect();
        for frame in frames {
            // a frame not laid out yet waits for the layout (the stack's height changes then, and this runs again)
            let near = frame.selected()
                || frame.widget.compute_bounds(&self.items).is_some_and(|b| {
                    b.height() > 0.0 && f64::from(b.y() + b.height()) >= top && f64::from(b.y()) <= bottom
                });
            frame.live(near);
        }
    }

    /// The selected message's own picture, drawn for its view (a message alone: its brand's logo, its contact's picture)
    pub fn set_selected_picture(&self, texture: &gdk::Texture) {
        if let Some(frame) = self.selected_frame() {
            frame.picture.show_texture(texture);
        }
    }

    /// The selected frame's body: its height in pixels, the text size's zoom, and whether its document is taller than a
    /// body is made, so it scrolls by itself (the UI test)
    #[cfg(feature = "e2e")]
    pub fn selected_tall(&self) -> Option<(i32, f64, bool)> {
        let frame = self.selected_frame()?;
        let zoom = frame.body.borrow().as_ref()?.view.zoom_level();
        Some((frame.height.get(), zoom, frame.scrolls_itself.get()))
    }

    /// Whether the selected frame shows a drawn picture (the UI test)
    #[cfg(feature = "e2e")]
    pub fn selected_picture_drawn(&self) -> bool {
        self.selected_frame().is_some_and(|f| f.picture.has_picture())
    }

    /// The selected frame's body: Find, Print and the UI test act on it
    pub fn selected_body(&self) -> Option<DocumentView> {
        self.selected_frame().and_then(|f| f.body.borrow().clone())
    }

    // ---- for the UI test ----

    /// The stack's messages in order: who sent each, open, selected
    #[cfg(feature = "e2e")]
    pub fn shown(&self) -> Vec<(String, bool, bool)> {
        let frames = self.frames.borrow();
        let rows = self.rows.borrow();
        let mut shown: Vec<(usize, String, bool, bool)> = frames
            .values()
            .filter_map(|f| {
                f.entry
                    .borrow()
                    .as_ref()
                    .map(|e| (e.index, e.from.clone(), true, e.selected))
            })
            .chain(rows.iter().map(|(e, _)| (e.index, e.from.clone(), false, false)))
            .collect();
        shown.sort_by_key(|s| s.0);
        shown
            .into_iter()
            .map(|(_, from, open, selected)| (from, open, selected))
            .collect()
    }

    /// The frames in order: their entries and bodies
    #[cfg(feature = "e2e")]
    pub fn frames(&self) -> Vec<(Entry, Option<DocumentView>, gtk::Box)> {
        let mut frames: Vec<(Entry, Option<DocumentView>, gtk::Box)> = self
            .frames
            .borrow()
            .values()
            .filter_map(|f| {
                let entry = f.entry.borrow().clone()?;
                Some((entry, f.body.borrow().clone(), f.widget.clone()))
            })
            .collect();
        frames.sort_by_key(|f| f.0.index);
        frames
    }

    /// The rows of the folded middle shown
    #[cfg(feature = "e2e")]
    pub fn gaps(&self) -> Vec<gtk::Button> {
        self.gaps.borrow().clone()
    }

    /// The folded rows in order
    #[cfg(feature = "e2e")]
    pub fn rows(&self) -> Vec<gtk::ListBoxRow> {
        self.rows.borrow().iter().map(|(_, row)| row.clone()).collect()
    }

    /// A click on open frame `n` (in the stack's order), as the user's selects its message
    #[cfg(feature = "e2e")]
    pub fn select_frame(&self, n: usize) {
        if let Some(frame) = self.frame_at(n) {
            frame.click(Click::Select);
        }
    }

    /// Frame `n`'s arrow pressed
    #[cfg(feature = "e2e")]
    pub fn press_arrow(&self, n: usize) {
        if let Some(frame) = self.frame_at(n) {
            frame.arrow.emit_clicked();
        }
    }

    /// Frame `n`'s own button named `name` ("frame-reply", "frame-more", "frame-edit") pressed
    #[cfg(feature = "e2e")]
    pub fn press_button(&self, n: usize, name: &str) {
        let Some(frame) = self.frame_at(n) else { return };
        let mut child = frame.buttons.first_child();
        while let Some(widget) = child {
            if widget.widget_name() == name
                && let Some(button) = widget.downcast_ref::<gtk::Button>()
            {
                button.emit_clicked();
                return;
            }
            child = widget.next_sibling();
        }
    }

    #[cfg(feature = "e2e")]
    fn frame_at(&self, n: usize) -> Option<Rc<Frame>> {
        let mut frames: Vec<Rc<Frame>> = self.frames.borrow().values().cloned().collect();
        frames.sort_by_key(|f| f.entry.borrow().as_ref().map_or(0, |e| e.index));
        frames.get(n).cloned()
    }

    /// The words over the stack: its subject and summary
    #[cfg(feature = "e2e")]
    pub fn title(&self) -> (String, String) {
        (self.subject.text().to_string(), self.summary.text().to_string())
    }
}

/// `what` asked of the reader, when it listens
fn ask(asked: &Asked, what: Ask) {
    let asked = asked.borrow().clone();
    if let Some(asked) = asked {
        asked(what);
    }
}

/// The index of the message a folded row is
fn row_index(row: &gtk::ListBoxRow) -> Option<usize> {
    row.widget_name().strip_prefix("stack-row-")?.parse().ok()
}

/// A folded message: the arrow, the sender's picture and name, where it is filed, its first words, a paperclip, its
/// reactions and its date; activating it opens it, a double-click opens it in a window of its own
fn folded_row(entry: &Entry, asked: &Asked) -> gtk::ListBoxRow {
    let line = gtk::Box::new(gtk::Orientation::Horizontal, 8);
    line.set_margin_start(4);
    line.set_margin_end(10);
    let arrow = crate::icons::kept(gtk::Button::from_icon_name("pan-end-symbolic"));
    arrow.add_css_class("flat");
    arrow.set_valign(gtk::Align::Center);
    arrow.set_tooltip_text(Some(&t!(UiConversationOpenMessage)));
    arrow.update_property(&[gtk::accessible::Property::Label(&t!(UiConversationOpenMessage))]);
    arrow.set_widget_name("row-arrow");
    let (asked_arrow, index) = (asked.clone(), entry.index);
    arrow.connect_clicked(move |_| ask(&asked_arrow, Ask::Click(Click::Toggle, index)));
    line.append(&arrow);
    let picture = RowPicture::new();
    picture.show(entry.picture, &entry.initials);
    line.append(&picture.widget);
    let name = gtk::Label::builder().label(&entry.from).xalign(0.0).build();
    name.add_css_class(if entry.unread { "heading" } else { "row-name" });
    name.set_widget_name("row-name");
    line.append(&name);
    for chip in [&entry.folder, &entry.note] {
        if !chip.is_empty() {
            let label = gtk::Label::new(Some(chip));
            label.add_css_class("caption");
            label.add_css_class("stack-chip");
            line.append(&label);
        }
    }
    let words = gtk::Label::builder()
        .label(&entry.words)
        .xalign(0.0)
        .hexpand(true)
        .ellipsize(gtk::pango::EllipsizeMode::End)
        .build();
    words.add_css_class("dim-label");
    line.append(&words);
    if entry.attachments {
        line.append(&crate::icons::image("ic-attach-symbolic"));
    }
    if !entry.reactions.is_empty() {
        line.append(&gtk::Label::new(Some(&entry.reactions)));
    }
    let date = gtk::Label::new(Some(&if entry.date > 0 {
        crate::rows::short_date(entry.date, crate::rows::Clock::now())
    } else {
        String::new()
    }));
    date.add_css_class("dim-label");
    date.add_css_class("numeric");
    line.append(&date);
    let row = gtk::ListBoxRow::builder()
        .child(&line)
        .activatable(true)
        .height_request(40)
        .tooltip_text(&entry.when)
        .build();
    row.set_widget_name(&format!("stack-row-{}", entry.index));
    let label = [&entry.from, &entry.folder, &entry.note, &entry.words, &entry.when]
        .into_iter()
        .filter(|s| !s.is_empty())
        .cloned()
        .collect::<Vec<_>>()
        .join(", ");
    row.update_property(&[gtk::accessible::Property::Label(&label)]);
    let double = gtk::GestureClick::new();
    let (asked, at) = (asked.clone(), entry.at);
    double.connect_pressed(move |_, presses, _, _| {
        if presses == 2 {
            ask(&asked, Ask::OpenWindow(at));
        }
    });
    row.add_controller(double);
    row
}

// ---- an open message ----

/// An open message: a strip saying where it is filed (when not here), its header (the arrow, the sender's picture and
/// name, to whom and when, its buttons), the reactions row and the files when it is the selected one, its body as tall
/// as its document
struct Frame {
    widget: gtk::Box,
    found_in: gtk::Label,
    header: gtk::Box,
    rule: gtk::Separator,
    arrow: gtk::Button,
    picture: RowPicture,
    name: gtk::Label,
    detail: gtk::Label,
    buttons: gtk::Box,
    body_box: gtk::Box,
    body: RefCell<Option<DocumentView>>,
    files: gtk::Button,
    /// Its entry's words (without its view, which is `view`)
    entry: RefCell<Option<Entry>>,
    /// The view whose document the body shows
    view: RefCell<Option<Rc<MessageView>>>,
    pictures: Cell<bool>,
    /// The document's height last measured, in pixels: kept while the body is let go
    height: Rc<Cell<i32>>,
    /// Its document is taller than a body is made ([`pe_html::STACK_BODY_MAX`]): the body scrolls by itself, the wheel
    /// over it its own
    scrolls_itself: Rc<Cell<bool>>,
    measure_timer: Rc<RefCell<Option<glib::SourceId>>>,
    asked: Asked,
    links: Links,
    bodies: Bodies,
    scroller: gtk::ScrolledWindow,
}

impl Frame {
    fn new(asked: Asked, links: Links, bodies: Bodies, scroller: gtk::ScrolledWindow) -> Rc<Frame> {
        let widget = gtk::Box::new(gtk::Orientation::Vertical, 0);
        widget.add_css_class("stack-frame");
        widget.set_widget_name("stack-frame");
        widget.set_overflow(gtk::Overflow::Hidden);
        widget.set_accessible_role(gtk::AccessibleRole::Group);
        let found_in = gtk::Label::builder().xalign(0.0).build();
        found_in.add_css_class("caption");
        found_in.add_css_class("dim-label");
        found_in.add_css_class("found-in");
        found_in.set_widget_name("frame-found-in");
        let arrow = crate::icons::kept(gtk::Button::from_icon_name("pan-down-symbolic"));
        arrow.add_css_class("flat");
        arrow.set_valign(gtk::Align::Center);
        arrow.set_tooltip_text(Some(&t!(UiConversationFoldMessage)));
        arrow.update_property(&[gtk::accessible::Property::Label(&t!(UiConversationFoldMessage))]);
        arrow.set_widget_name("frame-arrow");
        let picture = RowPicture::new();
        picture.widget.set_widget_name("frame-picture");
        let name = gtk::Label::builder()
            .xalign(0.0)
            .ellipsize(gtk::pango::EllipsizeMode::End)
            .build();
        name.add_css_class("heading");
        name.set_widget_name("frame-name");
        let detail = gtk::Label::builder()
            .xalign(0.0)
            .ellipsize(gtk::pango::EllipsizeMode::End)
            .build();
        detail.add_css_class("dim-label");
        detail.add_css_class("caption");
        detail.set_widget_name("frame-detail");
        let who = gtk::Box::new(gtk::Orientation::Vertical, 1);
        who.set_hexpand(true);
        who.set_valign(gtk::Align::Center);
        who.append(&name);
        who.append(&detail);
        let buttons = gtk::Box::new(gtk::Orientation::Horizontal, 2);
        buttons.set_valign(gtk::Align::Center);
        let header = gtk::Box::new(gtk::Orientation::Horizontal, 8);
        header.set_margin_start(4);
        header.set_margin_end(8);
        header.set_margin_top(6);
        header.set_margin_bottom(6);
        header.append(&arrow);
        header.append(&picture.widget);
        header.append(&who);
        header.append(&buttons);
        // the line between the header and what the message holds
        let rule = gtk::Separator::new(gtk::Orientation::Horizontal);
        rule.set_margin_start(12);
        rule.set_margin_end(12);
        rule.set_margin_bottom(6);
        let body_box = gtk::Box::new(gtk::Orientation::Vertical, 0);
        body_box.set_margin_start(4);
        body_box.set_margin_end(4);
        let files = gtk::Button::new();
        files.add_css_class("flat");
        files.set_halign(gtk::Align::Start);
        files.set_widget_name("frame-files");
        let frame = Rc::new(Frame {
            widget,
            found_in,
            header,
            rule,
            arrow,
            picture,
            name,
            detail,
            buttons,
            body_box,
            body: RefCell::default(),
            files,
            entry: RefCell::default(),
            view: RefCell::default(),
            pictures: Cell::new(false),
            height: Rc::new(Cell::new(120)),
            scrolls_itself: Rc::default(),
            measure_timer: Rc::default(),
            asked,
            links,
            bodies,
            scroller,
        });
        let weak = Rc::downgrade(&frame);
        frame.arrow.connect_clicked(move |_| {
            if let Some(frame) = weak.upgrade() {
                frame.click(Click::Toggle);
            }
        });
        let weak = Rc::downgrade(&frame);
        frame.files.connect_clicked(move |_| {
            if let Some(frame) = weak.upgrade() {
                frame.click(Click::Select);
            }
        });
        // a click anywhere in the frame, its body too, selects its message (the click still reaches what it is on)
        let press = gtk::GestureClick::new();
        press.set_propagation_phase(gtk::PropagationPhase::Capture);
        let weak = Rc::downgrade(&frame);
        press.connect_pressed(move |_, presses, _, _| {
            let Some(frame) = weak.upgrade() else { return };
            let at = frame.entry.borrow().as_ref().map(|e| e.at);
            if presses == 2
                && let Some(at) = at.filter(|at| at.uid != 0)
            {
                ask(&frame.asked, Ask::OpenWindow(at));
                return;
            }
            if !frame.selected() {
                // after the press: the frame may be rebuilt
                let frame = frame.clone();
                glib::idle_add_local_once(move || frame.click(Click::Select));
            }
        });
        frame.header.add_controller(press);
        frame
    }

    fn selected(&self) -> bool {
        self.entry.borrow().as_ref().is_some_and(|e| e.selected)
    }

    fn click(&self, click: Click) {
        let index = self.entry.borrow().as_ref().map(|e| e.index);
        if let Some(index) = index {
            ask(&self.asked, Ask::Click(click, index));
        }
    }

    /// `entry` shown, its body `view`'s document (made now when the frame is near what is seen)
    fn show(self: &Rc<Self>, entry: Entry, view: Option<Rc<MessageView>>, conversation: bool, pictures: bool) {
        // another document, or the same built again: its previews under the new view's token
        fn shown(view: Option<&MessageView>) -> Option<(&String, &Option<String>)> {
            view.map(|v| (&v.document, &v.preview_token))
        }
        let changed = shown(self.view.borrow().as_deref()) != shown(view.as_deref()) || self.pictures.get() != pictures;
        self.pictures.set(pictures);
        self.found_in.set_text(&entry.found_in);
        self.name.set_text(&entry.from);
        self.name
            .set_tooltip_text((!entry.address.is_empty()).then_some(entry.address.as_str()));
        let detail: Vec<&str> = [entry.to.as_str(), entry.when.as_str()]
            .into_iter()
            .filter(|w| !w.is_empty())
            .collect();
        self.detail.set_text(&detail.join(" · "));
        self.picture.show(entry.picture, &entry.initials);
        self.arrow.set_visible(conversation);
        self.widget.update_property(&[gtk::accessible::Property::Label(&format!(
            "{}, {}",
            entry.from, entry.when
        ))]);
        while let Some(child) = self.buttons.first_child() {
            self.buttons.remove(&child);
        }
        let at = entry.at;
        if entry.draft {
            let edit = self.button("ic-mail-edit-symbolic", &t!(UiConversationEdit), "frame-edit");
            let asked = self.asked.clone();
            edit.connect_clicked(move |_| ask(&asked, Ask::Edit(at)));
            self.buttons.append(&edit);
        } else {
            for (command, icon, tooltip) in [
                (Command::Reply, "ic-arrow-reply-symbolic", t!(UiTbReply).to_string()),
                (
                    Command::ReplyAll,
                    "ic-arrow-reply-all-symbolic",
                    t!(UiTbReplyAll).to_string(),
                ),
                (
                    Command::Forward,
                    "ic-arrow-forward-symbolic",
                    t!(UiTbForward).to_string(),
                ),
            ] {
                let button = self.button(icon, &tooltip, &format!("frame-{}", command.name()));
                let asked = self.asked.clone();
                button.connect_clicked(move |_| ask(&asked, Ask::Command(command, at)));
                self.buttons.append(&button);
            }
        }
        let more = self.button("view-more-symbolic", &t!(UiConversationMore), "frame-more");
        let asked = self.asked.clone();
        more.connect_clicked(move |button| ask(&asked, Ask::More(at, button.clone().upcast())));
        self.buttons.append(&more);
        while let Some(child) = self.widget.first_child() {
            self.widget.remove(&child);
        }
        if !entry.found_in.is_empty() {
            self.found_in.set_margin_start(12);
            self.found_in.set_margin_top(6);
            self.widget.append(&self.found_in);
        }
        self.widget.append(&self.header);
        self.widget.append(&self.rule);
        self.widget.append(&self.body_box);
        if !entry.selected
            && let Some(view) = view.as_deref().filter(|v| !v.attachments.is_empty())
        {
            let names: Vec<&str> = view.attachments.iter().map(|a| a.filename.as_str()).collect();
            self.files.set_label(&format!("📎 {}", names.join(", ")));
            self.widget.append(&self.files);
        }
        // a card in a conversation, the selected one faintly ringed in the accent; a message alone none
        ui::set_class(&self.widget, "card", conversation);
        ui::set_class(&self.widget, "selected", entry.selected && conversation);
        *self.entry.borrow_mut() = Some(entry);
        *self.view.borrow_mut() = view;
        // another document (the next message alone, its pictures now, built again): loaded into the web view there
        let body = self.body.borrow().clone();
        if changed && let Some(body) = body {
            self.load(&body);
            self.measure();
        }
    }

    /// The document of the frame's view loaded into `body`
    fn load(&self, body: &DocumentView) {
        let view = self.view.borrow();
        let Some(view) = view.as_deref() else { return };
        body.show_parts(
            &view.document,
            &view.part_documents,
            view.preview_token.as_deref(),
            self.pictures.get() || view.pictures_loaded,
        );
    }

    fn button(&self, icon: &str, tooltip: &str, name: &str) -> gtk::Button {
        let button = ui::icon_button(icon, tooltip);
        button.add_css_class("flat");
        button.update_property(&[gtk::accessible::Property::Label(tooltip)]);
        button.set_widget_name(name);
        button
    }

    /// The selected frame takes the reader's reactions row and files strip (under its header) and its paper clip with
    /// the files' menu (among its buttons)
    fn take(&self, (reactions, files, clip): (&gtk::Widget, &gtk::Widget, &gtk::Widget)) {
        for part in [reactions, files, clip] {
            if let Some(parent) = part.parent().and_downcast::<gtk::Box>() {
                parent.remove(part);
            }
        }
        self.buttons.prepend(clip);
        reactions.set_margin_start(50);
        self.widget.insert_child_after(reactions, Some(&self.header));
        // its files under its header and the line under it, before its body, as Tab reaches them
        self.widget.insert_child_after(files, Some(&self.rule));
    }

    /// The body made (near what is seen, or selected) or let go (far from it), its height kept
    fn live(self: &Rc<Self>, near: bool) {
        if near && self.body.borrow().is_none() {
            if self.view.borrow().is_none() {
                return;
            }
            let body = DocumentView::new("preview", false);
            body.view.set_vexpand(false);
            body.view.set_widget_name(if self.selected() {
                "reader-preview"
            } else {
                "frame-body"
            });
            body.view.set_size_request(-1, self.height.get());
            let links = self.links.clone();
            body.set_links(move |uri| links.borrow().clone().is_some_and(|links| links(uri)));
            self.pass_scroll(&body.view);
            self.measure_on_change(&body.view);
            let made = self.bodies.borrow().clone();
            if let Some(made) = made {
                made(&body.view);
            }
            self.load(&body);
            self.body_box.append(&body.view);
            *self.body.borrow_mut() = Some(body);
            self.measure();
        } else if !near
            && !self.selected()
            && let Some(body) = self.body.borrow_mut().take()
        {
            self.stop_measuring();
            self.body_box.remove(&body.view);
            body.release();
        }
    }

    /// The vertical turns of the wheel over the body scroll the stack, not the body, which is as tall as its document
    /// (but for one taller than a body is made, which scrolls by itself)
    fn pass_scroll(&self, view: &webkit::WebView) {
        let scroll = gtk::EventControllerScroll::new(gtk::EventControllerScrollFlags::BOTH_AXES);
        scroll.set_propagation_phase(gtk::PropagationPhase::Capture);
        let scroller = self.scroller.clone();
        let scrolls_itself = self.scrolls_itself.clone();
        scroll.connect_scroll(move |controller, dx, dy| {
            if dy.abs() < dx.abs() || scrolls_itself.get() {
                return glib::Propagation::Proceed;
            }
            let adjustment = scroller.vadjustment();
            let delta = if controller.unit() == gdk::ScrollUnit::Wheel {
                dy * adjustment.page_size().powf(2.0 / 3.0)
            } else {
                dy
            };
            adjustment.set_value(adjustment.value() + delta);
            glib::Propagation::Stop
        });
        view.add_controller(scroll);
    }

    /// The body measured again when what it shows may have changed height without loading another document: the text
    /// size changed, or a click or a key in it (a "..." unfolded)
    fn measure_on_change(self: &Rc<Self>, view: &webkit::WebView) {
        let weak = Rc::downgrade(self);
        view.connect_zoom_level_notify(move |_| {
            if let Some(frame) = weak.upgrade() {
                frame.measure();
            }
        });
        let click = gtk::GestureClick::new();
        click.set_propagation_phase(gtk::PropagationPhase::Capture);
        let weak = Rc::downgrade(self);
        click.connect_released(move |_, _, _, _| {
            if let Some(frame) = weak.upgrade() {
                frame.measure();
            }
        });
        view.add_controller(click);
        let keys = gtk::EventControllerKey::new();
        let weak = Rc::downgrade(self);
        keys.connect_key_released(move |_, _, _, _| {
            if let Some(frame) = weak.upgrade() {
                frame.measure();
            }
        });
        view.add_controller(keys);
    }

    /// The body's height from its document, every 400 ms until the document has loaded (its pictures too) and its
    /// height stayed the same [`SETTLED`] times in a row; measured again when the width or the text size changes or
    /// another document loads
    fn measure(&self) {
        self.stop_measuring();
        let Some(body) = self.body.borrow().clone() else { return };
        let height = self.height.clone();
        let scrolls_itself = self.scrolls_itself.clone();
        let steady = Rc::new(Cell::new(0u32));
        let timer_slot = self.measure_timer.clone();
        let weak = body.view.downgrade();
        let timer = glib::timeout_add_local(std::time::Duration::from_millis(400), move || {
            let view = weak.upgrade().filter(|_| steady.get() < SETTLED);
            let Some(view) = view else {
                // the source ends with this: nothing to remove later
                timer_slot.borrow_mut().take();
                return glib::ControlFlow::Break;
            };
            let (height, steady, sized, scrolls_itself) =
                (height.clone(), steady.clone(), view.clone(), scrolls_itself.clone());
            let loading = view.is_loading();
            view.evaluate_javascript(
                pe_html::HEIGHT_SCRIPT,
                None,
                None,
                gtk::gio::Cancellable::NONE,
                move |value| {
                    let Some(css) = value.ok().map(|v| v.to_double()).filter(|h| *h > 0.0) else {
                        steady.set(0);
                        return;
                    };
                    scrolls_itself.set(css >= f64::from(pe_html::STACK_BODY_MAX));
                    let pixels = ((css * sized.zoom_level()).ceil() as i32).max(48);
                    if pixels != height.get() {
                        height.set(pixels);
                        sized.set_size_request(-1, pixels);
                        steady.set(0);
                    } else if !loading {
                        steady.set(steady.get() + 1);
                    }
                },
            );
            glib::ControlFlow::Continue
        });
        self.measure_timer.replace(Some(timer));
    }

    fn stop_measuring(&self) {
        if let Some(timer) = self.measure_timer.borrow_mut().take() {
            timer.remove();
        }
    }

    /// The frame no longer shown: its body let go
    fn release(&self) {
        self.stop_measuring();
        if let Some(body) = self.body.borrow_mut().take() {
            self.body_box.remove(&body.view);
            body.release();
        }
        self.view.borrow_mut().take();
    }
}
