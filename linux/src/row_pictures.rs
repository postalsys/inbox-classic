//! The senders' pictures of the Columns list: a brand's logo the mail provider confirmed (the core draws it, its
//! texture kept here for the run, one drawing for every row of that sender), else the sender's initials on a quiet
//! round fill, one tone for everyone. Decorative: the row's own label says who it is.

use std::cell::{Cell, RefCell};
use std::collections::HashMap;
use std::rc::{Rc, Weak};

use gtk::gdk;
use gtk::prelude::*;

use crate::app::shell;

/// The picture's size, square, in points
pub const SIZE: i32 = 32;

/// A picture asked of the core: still being drawn, or drawn (None when there was nothing to draw)
enum Slot {
    Pending,
    Drawn(Option<gdk::Texture>),
}

/// The pictures of the run, by key and size in pixels; the requests under way; the rows showing each key now
#[derive(Default)]
struct Pictures {
    slots: HashMap<(u64, i32), Slot>,
    requests: HashMap<u64, (u64, i32)>,
    showing: HashMap<u64, Vec<Weak<Parts>>>,
}

thread_local! {
    static PICTURES: RefCell<Pictures> = RefCell::default();
}

/// What a row's picture is made of, and the key it shows (0 for none)
struct Parts {
    picture: gtk::Image,
    initials: gtk::Label,
    key: Cell<u64>,
}

impl Parts {
    /// The texture of its key at its size, when the core has drawn one
    fn texture(&self) -> Option<gdk::Texture> {
        let key = self.key.get();
        (key != 0).then(|| texture(key, pixels(&self.picture))).flatten()
    }

    /// The drawn picture, or the initials when there is none (yet)
    fn refresh(&self) {
        let texture = self.texture();
        self.initials.set_visible(texture.is_none());
        self.picture.set_paintable(texture.as_ref());
        self.picture.set_visible(texture.is_some());
    }
}

/// The picture of one row: a round box (the drawn picture in it, or the quiet fill) and the initials over it
pub struct RowPicture {
    pub widget: gtk::Overlay,
    parts: Rc<Parts>,
}

impl RowPicture {
    pub fn new() -> RowPicture {
        // always SIZE points, the texture's pixels (SIZE times the scale) drawn into them
        let picture = gtk::Image::builder().pixel_size(SIZE).build();
        // round: the box is the circle (its style rounds it and gives the quiet fill) and clips the picture to it
        let round = gtk::Box::builder()
            .width_request(SIZE)
            .height_request(SIZE)
            .halign(gtk::Align::Start)
            .valign(gtk::Align::Center)
            .hexpand(false)
            .overflow(gtk::Overflow::Hidden)
            .build();
        round.add_css_class("row-picture");
        round.append(&picture);
        let initials = gtk::Label::new(None);
        initials.add_css_class("row-initials");
        initials.set_halign(gtk::Align::Center);
        initials.set_valign(gtk::Align::Center);
        // decorative: the row's own label says who it is
        let widget = gtk::Overlay::builder()
            .accessible_role(gtk::AccessibleRole::Presentation)
            .valign(gtk::Align::Center)
            .hexpand(false)
            .build();
        widget.set_child(Some(&round));
        widget.add_overlay(&initials);
        let parts = Rc::new(Parts {
            picture,
            initials,
            key: Cell::new(0),
        });
        RowPicture { widget, parts }
    }

    /// The picture of a row: `key`'s pixels once the core has drawn them, `initials` meanwhile and without one
    pub fn show(&self, key: u64, initials: &str) {
        let before = self.parts.key.replace(key);
        if before != key {
            follow(&self.parts, before, key);
        }
        self.parts.initials.set_text(initials);
        if key != 0 {
            request(key, pixels(&self.parts.picture));
        }
        self.parts.refresh();
    }

    /// Whether it shows a drawn picture, not the initials
    #[cfg(feature = "e2e")]
    pub fn has_picture(&self) -> bool {
        self.parts.texture().is_some()
    }
}

/// The picture's size in pixels at the widget's scale
fn pixels(widget: &impl IsA<gtk::Widget>) -> i32 {
    SIZE * widget.scale_factor().max(1)
}

/// A row now shows `key` rather than `before`: kept among the rows of the one it shows, so a picture that arrives
/// for its old key leaves it as it is
fn follow(parts: &Rc<Parts>, before: u64, key: u64) {
    PICTURES.with(|pictures| {
        let showing = &mut pictures.borrow_mut().showing;
        if let Some(rows) = showing.get_mut(&before) {
            rows.retain(|row| !std::ptr::eq(row.as_ptr(), Rc::as_ptr(parts)));
        }
        if key != 0 {
            showing.entry(key).or_default().push(Rc::downgrade(parts));
        }
    });
}

/// Asks the core for `key` drawn `size` pixels square, once a run
fn request(key: u64, size: i32) {
    PICTURES.with(|pictures| {
        let mut pictures = pictures.borrow_mut();
        if pictures.slots.contains_key(&(key, size)) {
            return;
        }
        let request = shell().core.picture_start(key, size as u32).unwrap_or(0);
        if request == 0 {
            pictures.slots.insert((key, size), Slot::Drawn(None));
        } else {
            pictures.slots.insert((key, size), Slot::Pending);
            pictures.requests.insert(request, (key, size));
        }
    });
}

/// The core drew picture `request` (Event::PictureReady): kept, and the rows showing it now show it in place
pub fn ready(request: u64) {
    let Some((key, size)) = PICTURES.with(|p| p.borrow_mut().requests.remove(&request)) else {
        return;
    };
    let texture = shell()
        .core
        .picture_result(request)
        .and_then(|pixels| crate::ui::bgra_texture(pixels, size))
        .map(|texture| texture.upcast::<gdk::Texture>());
    let rows: Vec<Rc<Parts>> = PICTURES.with(|pictures| {
        let mut pictures = pictures.borrow_mut();
        pictures.slots.insert((key, size), Slot::Drawn(texture));
        let rows = pictures.showing.entry(key).or_default();
        rows.retain(|row| row.strong_count() > 0);
        rows.iter().filter_map(Weak::upgrade).collect()
    });
    for row in rows {
        row.refresh();
    }
}

/// The drawn picture of `key` at `size` pixels, when the core has drawn one
fn texture(key: u64, size: i32) -> Option<gdk::Texture> {
    PICTURES.with(|pictures| match pictures.borrow().slots.get(&(key, size)) {
        Some(Slot::Drawn(Some(texture))) => Some(texture.clone()),
        _ => None,
    })
}
