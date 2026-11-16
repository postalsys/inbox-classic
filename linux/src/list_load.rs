//! A list chosen in the folder tree loads after the tree has drawn the row chosen: the click is answered within the
//! frame, the store is read after it. Until the new list is drawn the one before stays, dimmed and taking no clicks or
//! keys; "Loading..." shows over it only when the load has not been done in 400 ms from the first choice. A newer
//! choice replaces the load waiting, so only the newest runs, and does not start the 400 ms again.

use std::cell::RefCell;
use std::rc::{Rc, Weak};
use std::time::Duration;

use gtk::prelude::*;
use gtk::{gdk, glib};

/// How long the old list waits dimmed before it says it is loading, from the first choice of the wait
const LOADING_NOTE_AFTER: Duration = Duration::from_millis(pe_core::LIST_LOADING_MS as u64);
/// The load runs at the latest this long after the choice, should no frame be drawn (a window not on screen)
const PAINT_FALLBACK: Duration = Duration::from_millis(250);

/// What runs once the tree has drawn
type Load = Box<dyn FnOnce()>;

/// A load waiting for the paint, and the sources that run it
#[derive(Default)]
struct Waiting {
    load: Option<Load>,
    after_paint: Option<(gdk::FrameClock, glib::SignalHandlerId)>,
    idle: Option<glib::SourceId>,
    fallback: Option<glib::SourceId>,
}

impl Waiting {
    /// The sources taken away (the load itself is not run)
    fn cancel(&mut self) {
        if let Some((clock, handler)) = self.after_paint.take() {
            clock.disconnect(handler);
        }
        for source in [self.idle.take(), self.fallback.take()].into_iter().flatten() {
            source.remove();
        }
    }
}

pub struct ListLoad {
    /// The list dimmed while it waits
    list: gtk::Widget,
    /// "Loading...", over the list
    note: gtk::Label,
    waiting: RefCell<Waiting>,
    note_timer: RefCell<Option<glib::SourceId>>,
    /// What happened in order and when, for the e2e driver: "painted" when the tree drew the row chosen, "loaded" when
    /// the list was read
    #[cfg(feature = "e2e")]
    pub order: RefCell<Vec<(&'static str, std::time::Instant)>>,
    /// The e2e driver holds the load after the paint, to show the list waiting
    #[cfg(feature = "e2e")]
    held: std::cell::Cell<bool>,
}

impl ListLoad {
    pub fn new(list: &impl IsA<gtk::Widget>) -> Rc<ListLoad> {
        let note = gtk::Label::new(Some(&t!(GtkListLoading)));
        note.add_css_class("list-loading-note");
        note.set_widget_name("list-loading");
        note.set_halign(gtk::Align::Center);
        note.set_valign(gtk::Align::Start);
        note.set_margin_top(56);
        note.set_can_target(false);
        note.set_visible(false);
        Rc::new(ListLoad {
            list: list.clone().upcast(),
            note,
            waiting: RefCell::default(),
            note_timer: RefCell::default(),
            #[cfg(feature = "e2e")]
            order: RefCell::default(),
            #[cfg(feature = "e2e")]
            held: std::cell::Cell::new(false),
        })
    }

    /// The "Loading..." label, for the overlay over the list
    pub fn note(&self) -> &gtk::Label {
        &self.note
    }

    /// Whether a list chosen waits to be loaded
    pub fn waiting(&self) -> bool {
        self.waiting.borrow().load.is_some()
    }

    /// `load` run once `drawn` (the tree) has drawn the frame with the row chosen, in place of a load waiting; the
    /// list dimmed meanwhile
    pub fn after_paint(self: &Rc<Self>, drawn: &impl IsA<gtk::Widget>, load: impl FnOnce() + 'static) {
        let mut waiting = self.waiting.borrow_mut();
        waiting.cancel();
        // a choice while one waits: the list stays dimmed, "Loading..." on the first one's time
        if waiting.load.replace(Box::new(load)).is_none() {
            self.dim(true);
        }
        let weak = Rc::downgrade(self);
        let drawn = drawn.as_ref();
        match drawn.frame_clock().filter(|_| drawn.is_drawable()) {
            Some(clock) => {
                drawn.queue_draw();
                let painted = weak.clone();
                let handler = clock.connect_after_paint(move |_| {
                    if let Some(this) = painted.upgrade() {
                        this.painted();
                    }
                });
                waiting.after_paint = Some((clock, handler));
                waiting.fallback = Some(glib::timeout_add_local_once(PAINT_FALLBACK, move || {
                    if let Some(this) = weak.upgrade() {
                        this.waiting.borrow_mut().fallback.take();
                        this.run();
                    }
                }));
            }
            None => waiting.idle = Some(Self::idle(weak)),
        }
    }

    /// The tree drew its frame: the load right after it, once GTK is done with the frame
    fn painted(self: &Rc<Self>) {
        #[cfg(feature = "e2e")]
        self.order.borrow_mut().push(("painted", std::time::Instant::now()));
        let mut waiting = self.waiting.borrow_mut();
        if let Some((clock, handler)) = waiting.after_paint.take() {
            clock.disconnect(handler);
        }
        if waiting.idle.is_none() {
            waiting.idle = Some(Self::idle(Rc::downgrade(self)));
        }
    }

    fn idle(weak: Weak<ListLoad>) -> glib::SourceId {
        glib::idle_add_local_once(move || {
            if let Some(this) = weak.upgrade() {
                this.waiting.borrow_mut().idle.take();
                this.run();
            }
        })
    }

    /// The load waiting run now
    fn run(&self) {
        let load = {
            let mut waiting = self.waiting.borrow_mut();
            waiting.cancel();
            #[cfg(feature = "e2e")]
            if self.held.get() {
                return;
            }
            waiting.load.take()
        };
        if let Some(load) = load {
            load();
        }
    }

    /// The load of the next choice held after the paint (`on`), or the one held run now, for the e2e driver
    #[cfg(feature = "e2e")]
    pub fn hold(&self, on: bool) {
        self.held.set(on);
        if !on {
            self.run();
        }
    }

    /// The list is being read now (the one waiting or another reload): nothing waits for the paint any longer
    pub fn loading(&self) {
        let mut waiting = self.waiting.borrow_mut();
        waiting.cancel();
        waiting.load = None;
        #[cfg(feature = "e2e")]
        self.order.borrow_mut().push(("loaded", std::time::Instant::now()));
    }

    /// The new list drawn as it is: no longer dimmed
    pub fn loaded(self: &Rc<Self>) {
        if !self.waiting() {
            self.dim(false);
        }
    }

    /// The list dimmed and taking no clicks or keys (`on`), with "Loading..." after a moment, or as it was
    fn dim(self: &Rc<Self>, on: bool) {
        if let Some(timer) = self.note_timer.borrow_mut().take() {
            timer.remove();
        }
        self.list.set_sensitive(!on);
        self.list.set_opacity(if on { 1.0 - pe_core::LIST_DIM } else { 1.0 });
        if !on {
            self.note.set_visible(false);
            return;
        }
        let weak = Rc::downgrade(self);
        let timer = glib::timeout_add_local_once(LOADING_NOTE_AFTER, move || {
            if let Some(this) = weak.upgrade() {
                this.note_timer.borrow_mut().take();
                this.note.set_visible(true);
            }
        });
        *self.note_timer.borrow_mut() = Some(timer);
    }
}
