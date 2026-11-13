//! The message list of the Columns layout: a list of rows of three lines over the same model and selection as the
//! column view of the Classic layout. A row: a dot while it is unread; who and when; the subject with the marks the
//! classic row has; the first words of the message (the core's snippet), and on a conversation's row its count and its
//! expander. Every string comes from the core as it decoded it, shown as text.

use std::cell::{Cell, RefCell};
use std::rc::Rc;

use gtk::glib;
use gtk::prelude::*;
use gtk::subclass::prelude::*;
use pe_store::Message;

use crate::app::shell;
use crate::messages::{MessageRow, attachment_icon, bind_flag, thread_expander};
use crate::ui::set_class;

/// How far the rows of an opened conversation are indented under its first, as the other apps' Columns rows
const REPLY_INDENT: i32 = 16;

/// Now, and the local time zone's offset from UTC in seconds: what the dates of the rows are written against, read once
/// for a refresh of the list rather than for each row
#[derive(Debug, Clone, Copy, Default)]
pub struct Clock {
    now: i64,
    offset: i64,
}

impl Clock {
    pub fn now() -> Clock {
        glib::DateTime::now_local()
            .map(|now| Clock {
                now: now.to_unix(),
                offset: now.utc_offset().as_seconds(),
            })
            .unwrap_or_default()
    }
}

/// What the rows read besides the message: whether the person is the recipients (Sent Items and Drafts) and whether
/// the list has messages of several folders (a search, All Inboxes), each kept by the message list
#[derive(Clone)]
pub struct RowContext {
    pub recipients: Rc<Cell<bool>>,
    pub several_folders: Rc<Cell<bool>>,
    pub clock: Rc<Cell<Clock>>,
}

mod imp {
    use super::*;

    /// A row of the Columns list, holding its parts for the binds
    #[derive(Default)]
    pub struct RowWidget {
        pub(super) parts: RefCell<Option<super::Parts>>,
    }

    #[glib::object_subclass]
    impl ObjectSubclass for RowWidget {
        const NAME: &'static str = "IcColumnsRow";
        type Type = super::RowWidget;
        type ParentType = gtk::Box;
    }

    impl ObjectImpl for RowWidget {}
    impl WidgetImpl for RowWidget {}
    impl BoxImpl for RowWidget {}
}

glib::wrapper! {
    pub struct RowWidget(ObjectSubclass<imp::RowWidget>)
        @extends gtk::Box, gtk::Widget,
        @implements gtk::Accessible, gtk::Buildable, gtk::ConstraintTarget, gtk::Orientable;
}

/// The parts of a row a bind fills
struct Parts {
    dot: gtk::Box,
    text: gtk::Box,
    who: gtk::Label,
    date: gtk::Label,
    subject: gtk::Label,
    folder: gtk::Label,
    attachment: gtk::Image,
    flag: gtk::DrawingArea,
    snippet: gtk::Label,
    count: gtk::Label,
    expander: gtk::Image,
}

/// A label of one line, cut short with an ellipsis
fn line_label(expand: bool) -> gtk::Label {
    let label = gtk::Label::new(None);
    label.set_xalign(0.0);
    label.set_hexpand(expand);
    label.set_ellipsize(gtk::pango::EllipsizeMode::End);
    label.set_single_line_mode(true);
    label
}

/// A line of the row: the words that take the room, then what stands at its right
fn line(widgets: &[&gtk::Widget]) -> gtk::Box {
    let line = gtk::Box::new(gtk::Orientation::Horizontal, 6);
    for widget in widgets {
        line.append(*widget);
    }
    line
}

fn small_dim(label: &gtk::Label) {
    label.add_css_class("dim-label");
    label.add_css_class("row-detail");
}

impl Parts {
    fn new(item: &gtk::ListItem) -> (RowWidget, Parts) {
        let expander = thread_expander(item);
        let dot = gtk::Box::new(gtk::Orientation::Horizontal, 0);
        dot.add_css_class("unread-dot");
        dot.set_valign(gtk::Align::Center);
        dot.set_halign(gtk::Align::Center);
        // the dot in a gutter of its own width, so every row's text starts at the same place
        let gutter = gtk::Box::new(gtk::Orientation::Horizontal, 0);
        gutter.set_size_request(16, -1);
        gutter.set_hexpand(false);
        gutter.append(&dot);
        dot.set_margin_start(4);
        let (who, date) = (line_label(true), line_label(false));
        who.add_css_class("sender");
        small_dim(&date);
        let (subject, folder) = (line_label(true), line_label(false));
        small_dim(&folder);
        folder.set_max_width_chars(18);
        let attachment = gtk::Image::new();
        let flag = gtk::DrawingArea::new();
        flag.set_content_width(16);
        flag.set_content_height(16);
        let snippet = line_label(true);
        snippet.add_css_class("dim-label");
        let count = line_label(false);
        small_dim(&count);
        let text = gtk::Box::new(gtk::Orientation::Vertical, 2);
        text.set_hexpand(true);
        text.append(&line(&[who.upcast_ref(), date.upcast_ref()]));
        text.append(&line(&[
            subject.upcast_ref(),
            folder.upcast_ref(),
            attachment.upcast_ref(),
            flag.upcast_ref(),
        ]));
        text.append(&line(&[
            snippet.upcast_ref(),
            count.upcast_ref(),
            expander.upcast_ref(),
        ]));
        let row: RowWidget = glib::Object::builder()
            .property("orientation", gtk::Orientation::Horizontal)
            .property("spacing", 4)
            .build();
        row.add_css_class("message-row");
        row.set_hexpand(true);
        row.append(&gutter);
        row.append(&text);
        let parts = Parts {
            dot,
            text,
            who,
            date,
            subject,
            folder,
            attachment,
            flag,
            snippet,
            count,
            expander,
        };
        (row, parts)
    }
}

/// The factory of the Columns list's rows
pub fn factory(context: RowContext) -> gtk::SignalListItemFactory {
    let factory = gtk::SignalListItemFactory::new();
    factory.connect_setup(|_, item| {
        let Some(item) = item.downcast_ref::<gtk::ListItem>() else {
            return;
        };
        let (row, parts) = Parts::new(item);
        crate::messages::add_drag_source(&row, item);
        *row.imp().parts.borrow_mut() = Some(parts);
        item.set_child(Some(&row));
    });
    factory.connect_bind(move |_, item| {
        let Some(item) = item.downcast_ref::<gtk::ListItem>() else {
            return;
        };
        let Some(row) = item.child().and_downcast::<RowWidget>() else {
            return;
        };
        let Some(message) = item.item().and_downcast::<MessageRow>() else {
            return;
        };
        let parts = row.imp().parts.borrow();
        if let Some(parts) = parts.as_ref() {
            message.with(|m| bind(row.upcast_ref(), parts, m, &context));
        }
    });
    factory
}

/// Who the row names: the sender, or "To:" and the recipients in Sent Items and Drafts
fn who(m: &Message, recipients: bool) -> String {
    if recipients {
        format!(
            "{} {}",
            crate::words::plain(crate::words::Text::UiColTo),
            m.info.recipients
        )
    } else {
        m.info.sender().to_string()
    }
}

fn bind(row: &gtk::Widget, parts: &Parts, m: &Message, context: &RowContext) {
    let bold = m.bold();
    parts.dot.set_opacity(if bold { 1.0 } else { 0.0 });
    let who = who(m, context.recipients.get());
    parts.who.set_text(&who);
    let clock = context.clock.get();
    let date = m
        .info
        .display_date()
        .map(|seconds| short_date(seconds, clock))
        .unwrap_or_default();
    parts.date.set_text(&date);
    parts.subject.set_text(&m.info.subject);
    // the sender always a little heavier than the subject; the subject bold while the row is (the dot says unread)
    set_class(&parts.subject, "unread", bold);
    let several = context.several_folders.get();
    parts.folder.set_visible(several);
    if several {
        parts.folder.set_text(&shell().main().row_folder(m.folder_id));
    }
    bind_marks(parts, m);
    let snippet = m.snippet.as_deref().unwrap_or_default();
    parts.snippet.set_text(snippet);
    bind_thread(parts, m);
    set_class(&parts.text, "dim-label", m.dimmed());
    let unread = if m.info.seen() {
        String::new()
    } else {
        format!("{}, ", t!(UiRowUnread))
    };
    let label = format!("{unread}{who}, {}, {date}, {snippet}", m.info.subject);
    row.update_property(&[gtk::accessible::Property::Label(&label)]);
}

/// The marks at the right of the subject: the paper clip (a bounce's own mark in its place) and the flag in its colour,
/// as the classic row has them (an ignored conversation is grey, as there)
fn bind_marks(parts: &Parts, m: &Message) {
    let attachment = attachment_icon(m);
    parts.attachment.set_icon_name(attachment);
    parts.attachment.set_visible(attachment.is_some());
    let color = m.info.flag_color();
    parts.flag.set_visible(color.is_some());
    bind_flag(&parts.flag, color);
}

/// A conversation's row: its count and expander; an opened one's other rows indented under it
fn bind_thread(parts: &Parts, m: &Message) {
    let place = m.thread;
    let opens = place.is_some_and(|p| p.opens());
    parts.count.set_visible(opens);
    parts.expander.set_visible(opens);
    if let Some(place) = place.filter(|p| p.opens()) {
        parts.count.set_text(&place.count.to_string());
        parts.expander.set_icon_name(Some(if place.collapsed() {
            "pan-end-symbolic"
        } else {
            "pan-down-symbolic"
        }));
    }
    let depth = place.map_or(0, |p| p.depth);
    parts.text.set_margin_start(if depth > 0 { REPLY_INDENT } else { 0 });
}

/// What a row on screen shows, for the UI test: its three lines' first words and how far it is indented
#[cfg(feature = "e2e")]
pub fn shown(row: &RowWidget) -> Option<(String, String, String, i32)> {
    let parts = row.imp().parts.borrow();
    let parts = parts.as_ref()?;
    Some((
        parts.who.text().to_string(),
        parts.subject.text().to_string(),
        parts.snippet.text().to_string(),
        parts.text.margin_start(),
    ))
}

/// The date as the Columns list writes it, by the core's rule: the time today, the weekday this week, the day and
/// month this year, the whole date before
fn short_date(seconds: i64, clock: Clock) -> String {
    let Ok(date) = glib::DateTime::from_unix_local(seconds) else {
        return String::new();
    };
    let format = match pe_core::layout::date_style(seconds, clock.now, clock.offset) {
        pe_core::layout::DateStyle::Time => crate::ui::time_format(),
        pe_core::layout::DateStyle::Weekday => "%A",
        pe_core::layout::DateStyle::DayMonth => day_month_format(),
        pe_core::layout::DateStyle::Full => "%x",
    };
    date.format(format).map(|text| text.to_string()).unwrap_or_default()
}

/// The day and the month's short name in the order the locale's date puts them: "Nov 7" where it writes the month
/// first, "7 Nov" elsewhere
fn day_month_format() -> &'static str {
    static FORMAT: std::sync::OnceLock<&'static str> = std::sync::OnceLock::new();
    FORMAT.get_or_init(|| {
        let written = glib::DateTime::from_local(2001, 12, 28, 12, 0, 0.0)
            .and_then(|date| date.format("%x"))
            .map(|text| text.to_string())
            .unwrap_or_default();
        match (written.find("12"), written.find("28")) {
            (Some(month), Some(day)) if month < day => "%b %-e",
            _ => "%-e %b",
        }
    })
}
