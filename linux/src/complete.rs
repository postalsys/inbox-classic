//! Address completion in the To, Cc and Bcc fields: the address being typed (the text between the commas around the
//! cursor) is looked up in the core's address book, and the people found are listed under the field. The list never
//! takes the focus: the keys stay with the field, which moves the choice, takes it or closes the list.

use std::cell::{Cell, RefCell};
use std::rc::Rc;

use gtk::prelude::*;
use gtk::{gdk, glib};

use crate::app::shell;

/// How many people the list shows at most
const SHOWN: usize = 8;

struct Completion {
    entry: gtk::Entry,
    popover: gtk::Popover,
    list: gtk::ListBox,
    /// What goes in the field for each row, and the address to forget
    rows: RefCell<Vec<(String, String)>>,
    /// The field's text is being set from here: not typing
    taking: Cell<bool>,
}

fn is_separator(c: char) -> bool {
    c == ',' || c == ';'
}

/// The address the cursor is in, as byte offsets: from after the separator before it (without the spaces after
/// that) to the separator after it
fn token_at(text: &str, caret: usize) -> (usize, usize) {
    let caret = caret.min(text.len());
    let mut start = text[..caret].rfind(is_separator).map_or(0, |at| at + 1);
    while start < caret && text[start..].starts_with(' ') {
        start += 1;
    }
    let end = text[caret..].find(is_separator).map_or(text.len(), |at| caret + at);
    (start, end)
}

/// The text with `label` in place of the address the cursor is in, a comma and a space after it at the end; and where
/// the cursor goes
fn take(text: &str, caret: usize, label: &str) -> (String, usize) {
    let (start, end) = token_at(text, caret);
    let after = &text[end..];
    let inserted = if after.is_empty() {
        format!("{label}, ")
    } else {
        label.to_string()
    };
    (format!("{}{inserted}{after}", &text[..start]), start + inserted.len())
}

/// The cursor of the field as a byte offset into its text
fn caret_bytes(entry: &gtk::Entry) -> usize {
    let text = entry.text();
    let chars = entry.position().max(0) as usize;
    text.char_indices().nth(chars).map_or(text.len(), |(at, _)| at)
}

impl Completion {
    fn shown(&self) -> bool {
        self.popover.is_visible()
    }

    fn hide(&self) {
        self.popover.popdown();
    }

    /// Whether the keys go to the field: its text has the focus of its window
    fn typing(&self) -> bool {
        let focus = self.entry.root().and_then(|root| root.focus());
        focus.is_some_and(|focus| focus == self.entry.clone().upcast::<gtk::Widget>() || focus.is_ancestor(&self.entry))
    }

    /// The people for what is typed now; the list gone when there are none
    fn update(&self) {
        if self.taking.get() {
            return;
        }
        let text = self.entry.text().to_string();
        let caret = caret_bytes(&self.entry);
        let (start, _) = token_at(&text, caret);
        let typed = &text[start..caret.max(start)];
        // a whole address typed with its brackets is not looked up again
        if typed.is_empty() || typed.contains('<') || !self.typing() {
            self.hide();
            return;
        }
        let found = shell().core.contacts(typed, SHOWN).unwrap_or_default();
        if found.is_empty() {
            self.hide();
            return;
        }
        while let Some(row) = self.list.first_child() {
            self.list.remove(&row);
        }
        let mut rows = Vec::new();
        for contact in found {
            let label = pe_core::address_label(&contact.name, &contact.address);
            let row = gtk::Label::new(Some(&label));
            row.set_xalign(0.0);
            self.list.append(&row);
            rows.push((label, contact.address));
        }
        *self.rows.borrow_mut() = rows;
        // the best one chosen: Enter or Tab takes it
        self.list.select_row(self.list.row_at_index(0).as_ref());
        self.popover.set_width_request(self.entry.width());
        if !self.shown() {
            self.popover.popup();
        }
    }

    fn chosen(&self) -> Option<usize> {
        self.list.selected_row().map(|row| row.index() as usize)
    }

    /// The person chosen in the list in place of what was typed, a comma after it for the next one
    fn take(&self, index: Option<usize>) {
        let Some(label) = index.and_then(|i| self.rows.borrow().get(i).map(|r| r.0.clone())) else {
            return;
        };
        let (text, caret) = take(&self.entry.text(), caret_bytes(&self.entry), &label);
        self.taking.set(true);
        self.entry.set_text(&text);
        self.entry.set_position(text[..caret].chars().count() as i32);
        self.taking.set(false);
        self.hide();
    }

    fn move_by(&self, by: i32) {
        let count = self.rows.borrow().len() as i32;
        let current = self.chosen().map_or(0, |i| i as i32);
        let next = (current + by).clamp(0, (count - 1).max(0));
        self.list.select_row(self.list.row_at_index(next).as_ref());
    }

    /// Shift+Delete on a person in the list: out of the address book for good
    fn forget(&self) {
        if let Some(address) = self
            .chosen()
            .and_then(|i| self.rows.borrow().get(i).map(|r| r.1.clone()))
        {
            let _ = shell().core.forget_contact(&address);
            self.update();
        }
    }

    fn on_key(&self, key: gdk::Key, modifiers: gdk::ModifierType) -> glib::Propagation {
        if !self.shown() {
            return glib::Propagation::Proceed;
        }
        match key {
            gdk::Key::Down => self.move_by(1),
            gdk::Key::Up => self.move_by(-1),
            gdk::Key::Return | gdk::Key::KP_Enter | gdk::Key::Tab => self.take(self.chosen()),
            gdk::Key::Escape => self.hide(),
            gdk::Key::Delete if modifiers.contains(gdk::ModifierType::SHIFT_MASK) => self.forget(),
            _ => return glib::Propagation::Proceed,
        }
        glib::Propagation::Stop
    }
}

/// Completes the addresses typed in `entry` from the people written to and heard from
pub fn attach(entry: &gtk::Entry) {
    let list = gtk::ListBox::new();
    list.set_selection_mode(gtk::SelectionMode::Single);
    list.add_css_class("completion");
    list.set_can_focus(false);
    let popover = gtk::Popover::builder()
        .child(&list)
        .autohide(false)
        .has_arrow(false)
        .position(gtk::PositionType::Bottom)
        .can_focus(false)
        .halign(gtk::Align::Start)
        .build();
    popover.set_widget_name("completion");
    popover.set_parent(entry);
    let completion = Rc::new(Completion {
        entry: entry.clone(),
        popover,
        list: list.clone(),
        rows: RefCell::default(),
        taking: Cell::new(false),
    });
    let typed = Rc::downgrade(&completion);
    entry.connect_changed(move |_| {
        if typed.upgrade().is_some_and(|c| c.taking.get()) {
            return;
        }
        // once the cursor moved past what was typed
        let typed = typed.clone();
        glib::idle_add_local_once(move || {
            if let Some(completion) = typed.upgrade() {
                completion.update();
            }
        });
    });
    let clicked = Rc::downgrade(&completion);
    list.connect_row_activated(move |_, row| {
        if let Some(completion) = clicked.upgrade() {
            completion.take(Some(row.index() as usize));
        }
    });
    let keys = gtk::EventControllerKey::new();
    keys.set_propagation_phase(gtk::PropagationPhase::Capture);
    let pressed = Rc::downgrade(&completion);
    keys.connect_key_pressed(move |_, key, _, modifiers| {
        pressed.upgrade().map_or(glib::Propagation::Proceed, |completion| {
            completion.on_key(key, modifiers)
        })
    });
    entry.add_controller(keys);
    let focus = gtk::EventControllerFocus::new();
    let left = Rc::downgrade(&completion);
    focus.connect_leave(move |_| {
        if let Some(completion) = left.upgrade() {
            completion.hide();
        }
    });
    entry.add_controller(focus);
    let gone = completion.clone();
    entry.connect_destroy(move |_| gone.popover.unparent());
}

/// The list of an address field, for the e2e driver: its rows as they read, when it is shown
#[cfg(feature = "e2e")]
pub fn shown_rows(entry: &gtk::Entry) -> Option<Vec<String>> {
    let mut child = entry.first_child();
    while let Some(widget) = child {
        if let Some(popover) = widget.downcast_ref::<gtk::Popover>()
            && popover.is_visible()
        {
            let list = popover.child().and_downcast::<gtk::ListBox>()?;
            let mut rows = Vec::new();
            let mut row = list.first_child();
            while let Some(r) = row {
                if let Some(label) = r.first_child().and_downcast::<gtk::Label>() {
                    rows.push(label.text().to_string());
                }
                row = r.next_sibling();
            }
            return Some(rows);
        }
        child = widget.next_sibling();
    }
    None
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn the_address_the_cursor_is_in() {
        assert_eq!(token_at("ann", 3), (0, 3));
        assert_eq!(token_at("Ann <a@b>, bo", 13), (11, 13));
        assert_eq!(token_at("a, b, c", 4), (3, 4));
        assert_eq!(token_at("a, bob, c", 4), (3, 6));
    }

    #[test]
    fn taking_a_person() {
        assert_eq!(
            take("an", 2, "Ann <ann@example.com>"),
            ("Ann <ann@example.com>, ".into(), 23)
        );
        let (text, caret) = take("x@y, bo, z@w", 7, "Bob <bob@b.c>");
        assert_eq!(text, "x@y, Bob <bob@b.c>, z@w");
        assert_eq!(&text[..caret], "x@y, Bob <bob@b.c>");
    }
}
