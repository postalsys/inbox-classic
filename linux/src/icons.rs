//! The icons of the rows that lists make and drop by the hundred (the folder tree's, the message list's, the files of
//! a message): each looked up once, kept for as long as the app runs, and drawn from that paintable.
//!
//! An image given an icon's name looks it up again whenever its style changes, asking GTK to load it ahead on a
//! worker thread. GTK's cache of icons drops an icon only once it is finalized, so when the last reference to an
//! icon goes on that thread while the window thread finds the same icon in the cache, the window thread takes a
//! reference to an icon being finalized (GLib's "object_ref: assertion '!object_already_finalized' failed") and the
//! app crashes later (GTK 4.22 and 4.24 alike; the UI test met it on Arch Linux as the folder tree was built again).
//! An icon kept here is never finalized, and an image drawing a paintable looks nothing up.
//!
//! So no image of the app is given an icon's name: [`image`] makes one, and [`keep`] turns the image a button made
//! for its icon name (`set_icon_name`, `icon-name` on a button, menu button or split button) into one drawing the
//! kept icon, before it is drawn. What the toolkit draws inside its own widgets (the arrows, the Find box's
//! magnifier, the password eye, the window buttons, a preferences page's icon in its view switcher) it looks up itself.

use std::cell::RefCell;
use std::collections::HashMap;

use gtk::gdk;
#[cfg(feature = "e2e")]
use gtk::gio;
use gtk::prelude::*;

/// The pixels of an icon whose image has no size of its own, as GTK draws it
pub const NORMAL_SIZE: i32 = 16;

thread_local! {
    /// Every icon looked up, by its names and size
    static KEPT: RefCell<HashMap<(Vec<String>, i32), gtk::IconPaintable>> = RefCell::default();
}

/// The first of `names` the theme has, `size` pixels: looked up once, kept for as long as the app runs; None for no
/// names
pub fn paintable(names: &[&str], size: i32) -> Option<gtk::IconPaintable> {
    let (first, fallbacks) = names.split_first()?;
    let display = gdk::Display::default()?;
    let key = (names.iter().map(|name| name.to_string()).collect(), size);
    KEPT.with(|kept| {
        let mut kept = kept.borrow_mut();
        let icon = kept.entry(key).or_insert_with(|| {
            // no preload: the icon is loaded when it is first drawn, on the window thread
            gtk::IconTheme::for_display(&display).lookup_icon(
                first,
                fallbacks,
                size,
                1,
                gtk::TextDirection::None,
                gtk::IconLookupFlags::empty(),
            )
        });
        Some(icon.clone())
    })
}

/// `image` shows the first of `names` the theme has (nothing for none), at its pixel size
pub fn show(image: &gtk::Image, names: &[&str]) {
    let size = if image.pixel_size() > 0 {
        image.pixel_size()
    } else {
        NORMAL_SIZE
    };
    match paintable(names, size) {
        Some(icon) => image.set_paintable(Some(&icon)),
        None => image.clear(),
    }
}

/// `image` shows icon `name`, nothing for None
pub fn set(image: &gtk::Image, name: Option<&str>) {
    show(image, name.as_slice());
}

/// A new image showing icon `name`
pub fn image(name: &str) -> gtk::Image {
    let image = gtk::Image::new();
    set(&image, Some(name));
    image
}

/// Every image in `widget` (itself and all inside it) that shows an icon by its name draws the kept icon instead: for
/// the image a button makes of an icon name, called right after the name is set, before the image is drawn
pub fn keep(widget: &impl IsA<gtk::Widget>) {
    let widget = widget.as_ref();
    if let Some(image) = widget.downcast_ref::<gtk::Image>()
        && let Some(name) = image.icon_name()
    {
        show(image, &[&name]);
    }
    let mut child = widget.first_child();
    while let Some(at) = child {
        keep(&at);
        child = at.next_sibling();
    }
}

/// `widget`, after [`keep`]: for a button built with an icon name
pub fn kept<W: IsA<gtk::Widget>>(widget: W) -> W {
    keep(&widget);
    widget
}

/// The name of the icon `image` shows, as it was asked for: the first of the names of an icon kept here, the name of
/// an icon set by its name (the UI test reads them)
#[cfg(feature = "e2e")]
pub fn name_of(image: &gtk::Image) -> Option<String> {
    if let Some(name) = image.icon_name() {
        return Some(name.to_string());
    }
    if let Some(icon) = image.gicon().and_downcast::<gio::ThemedIcon>() {
        return icon.names().first().map(|n| n.to_string());
    }
    let shown = image.paintable().and_downcast::<gtk::IconPaintable>()?;
    KEPT.with(|kept| {
        kept.borrow()
            .iter()
            .find(|(_, icon)| **icon == shown)
            .and_then(|((names, _), _)| names.first().cloned())
    })
}
