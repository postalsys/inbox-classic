//! The senders' pictures of the Columns list: a brand's logo the mail provider confirmed (the core draws it, its
//! pixels kept here for the run, one drawing for every row of that sender), else the sender's initials on a quiet round
//! fill, one tone for everyone. Decorative: the row's own label says who it is.

use std::cell::RefCell;
use std::collections::HashMap;
use std::rc::Rc;

use gtk::prelude::*;
use gtk::{cairo, glib};

use crate::app::shell;

/// The picture's size, square, in points
pub const SIZE: i32 = 32;

/// A picture asked of the core: still being drawn, or drawn (None when there was nothing to draw)
enum Slot {
    Pending,
    Drawn(Option<cairo::ImageSurface>),
}

/// The pictures of the run, by key and size in pixels; the requests under way; the areas showing each key
#[derive(Default)]
struct Pictures {
    slots: HashMap<(u64, i32), Slot>,
    requests: HashMap<u64, (u64, i32)>,
    areas: HashMap<u64, Vec<glib::WeakRef<gtk::DrawingArea>>>,
}

thread_local! {
    static PICTURES: RefCell<Pictures> = RefCell::default();
}

/// What a row's picture shows: the key of its picture (0 for none)
#[derive(Default)]
struct Shown {
    key: u64,
}

/// The picture of one row: the circle (the drawn picture, or the quiet fill) and the initials over it
pub struct RowPicture {
    pub widget: gtk::Overlay,
    area: gtk::DrawingArea,
    initials: gtk::Label,
    shown: Rc<RefCell<Shown>>,
}

impl RowPicture {
    pub fn new() -> RowPicture {
        let area = gtk::DrawingArea::new();
        area.set_content_width(SIZE);
        area.set_content_height(SIZE);
        let shown = Rc::new(RefCell::new(Shown::default()));
        let drawn = shown.clone();
        area.set_draw_func(move |area, cr, _, _| draw(area, cr, &drawn.borrow()));
        let initials = gtk::Label::new(None);
        initials.add_css_class("row-initials");
        initials.set_halign(gtk::Align::Center);
        initials.set_valign(gtk::Align::Center);
        // decorative: the row's own label says who it is
        let widget = gtk::Overlay::builder()
            .accessible_role(gtk::AccessibleRole::Presentation)
            .build();
        widget.set_child(Some(&area));
        widget.add_overlay(&initials);
        widget.set_valign(gtk::Align::Center);
        widget.set_hexpand(false);
        widget.add_css_class("row-picture");
        RowPicture {
            widget,
            area,
            initials,
            shown,
        }
    }

    /// The picture of a row: `key`'s pixels once the core has drawn them, `initials` meanwhile and without one
    pub fn show(&self, key: u64, initials: &str) {
        self.shown.borrow_mut().key = key;
        self.initials.set_text(initials);
        if key != 0 {
            request(key, pixels(&self.area), &self.area);
        }
        self.refresh();
    }

    /// The initials hidden while a drawn picture stands in their place
    fn refresh(&self) {
        let key = self.shown.borrow().key;
        self.initials
            .set_visible(key == 0 || surface(key, pixels(&self.area)).is_none());
        self.area.queue_draw();
    }

    /// Whether it shows a drawn picture, not the initials (for the UI test)
    #[cfg(feature = "e2e")]
    pub fn drawn(&self) -> bool {
        let key = self.shown.borrow().key;
        key != 0 && surface(key, pixels(&self.area)).is_some()
    }
}

/// The picture's size in pixels at the area's scale
fn pixels(area: &gtk::DrawingArea) -> i32 {
    SIZE * area.scale_factor().max(1)
}

/// Asks the core for `key` drawn `size` pixels square, once a run, and notes `area` as one that shows it
fn request(key: u64, size: i32, area: &gtk::DrawingArea) {
    PICTURES.with(|pictures| {
        let mut pictures = pictures.borrow_mut();
        let areas = pictures.areas.entry(key).or_default();
        areas.retain(|weak| weak.upgrade().is_some());
        if !areas.iter().any(|weak| weak.upgrade().as_ref() == Some(area)) {
            areas.push(area.downgrade());
        }
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

/// The core drew picture `request` (Event::PictureReady): kept, and the rows showing it drawn again in place
pub fn ready(request: u64) {
    let Some((key, size)) = PICTURES.with(|p| p.borrow_mut().requests.remove(&request)) else {
        return;
    };
    let pixels = shell().core.picture_result(request);
    let drawn = pixels.and_then(|pixels| image(pixels, size));
    let areas: Vec<gtk::DrawingArea> = PICTURES.with(|pictures| {
        let mut pictures = pictures.borrow_mut();
        pictures.slots.insert((key, size), Slot::Drawn(drawn));
        pictures
            .areas
            .get(&key)
            .map(|areas| areas.iter().filter_map(|weak| weak.upgrade()).collect())
            .unwrap_or_default()
    });
    for area in areas {
        // the initials over it give way to the drawn picture
        if let Some(label) = area.next_sibling().and_downcast::<gtk::Label>() {
            label.set_visible(surface(key, size).is_none());
        }
        area.queue_draw();
    }
}

/// BGRA pixels with the alpha multiplied in (cairo's own ARGB32 on a little-endian machine) as a surface
fn image(pixels: Vec<u8>, size: i32) -> Option<cairo::ImageSurface> {
    let stride = size as usize * 4;
    if pixels.len() != stride * size as usize {
        return None;
    }
    cairo::ImageSurface::create_for_data(pixels, cairo::Format::ARgb32, size, size, stride as i32).ok()
}

/// The drawn picture of `key` at `size` pixels, when the core has drawn one
fn surface(key: u64, size: i32) -> Option<cairo::ImageSurface> {
    PICTURES.with(|pictures| match pictures.borrow().slots.get(&(key, size)) {
        Some(Slot::Drawn(Some(surface))) => Some(surface.clone()),
        _ => None,
    })
}

/// A round picture: the drawn one clipped to a circle, else a faint fill of the text's own color (the initials are a
/// label over it)
fn draw(area: &gtk::DrawingArea, cr: &cairo::Context, shown: &Shown) {
    let radius = f64::from(SIZE) / 2.0;
    cr.arc(radius, radius, radius, 0.0, std::f64::consts::TAU);
    cr.clip();
    let color = area.color();
    cr.set_source_rgba(
        f64::from(color.red()),
        f64::from(color.green()),
        f64::from(color.blue()),
        0.09,
    );
    let _ = cr.paint();
    let drawn = (shown.key != 0).then(|| surface(shown.key, pixels(area))).flatten();
    if let Some(surface) = drawn {
        let scale = f64::from(SIZE) / f64::from(surface.width());
        cr.scale(scale, scale);
        if cr.set_source_surface(&surface, 0.0, 0.0).is_ok() {
            cr.source().set_filter(cairo::Filter::Good);
            let _ = cr.paint();
        }
    }
}
