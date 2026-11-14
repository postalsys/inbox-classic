//! The help: Yelp shows it where it is installed (the packages put the pages of `help-export -- linux yelp` in
//! /usr/share/help/<language>/inbox-classic), the app's own viewer otherwise. The viewer is one window: the contents
//! (or a search's results) in a sidebar, the topic in a web view like a message's (scripts off), its `topic:` links
//! followed in the window, others opened in the browser, with its own Back and Forward. F1 again brings it to the front
//! with the topic of the window it was pressed in.

use std::cell::{Cell, RefCell};
use std::rc::{Rc, Weak};

use adw::prelude::*;
use gtk::glib;

use crate::app::shell;
use crate::webview::DocumentView;

thread_local! {
    static HELP: RefCell<Option<Rc<Help>>> = const { RefCell::new(None) };
}

/// The name of the help as the packages install it for Yelp
const YELP_NAME: &str = "inbox-classic";

/// The help of a window's context (`main`, `compose`, `options`: help/topics.toml), in Yelp or the viewer
pub fn show(context: &str) {
    let topic = pe_html::help_context(context);
    if yelp_help() {
        let uri = format!("help:{YELP_NAME}/{topic}");
        let parent = shell().main().window().clone().upcast::<gtk::Window>();
        gtk::UriLauncher::new(&uri).launch(Some(&parent), gtk::gio::Cancellable::NONE, move |result| {
            // Yelp did not start after all: the viewer then
            if result.is_err() {
                open(topic);
            }
        });
        return;
    }
    open(topic);
}

/// The help of the main window's context: the dialog it shows (Add Mail Account, Preferences, ...), or the window's
fn context_of(window: &adw::ApplicationWindow) -> &'static str {
    let dialog = window.visible_dialog().map(|d| d.widget_name().to_string());
    match dialog.as_deref() {
        Some("account-start" | "account-servers") => "account-form",
        Some("account-properties" | "accounts-dialog") => "account-properties",
        Some("preferences-dialog") => "options",
        Some("sign-in-apps-dialog" | "sign-in-app-editor") => "sign-in-apps",
        Some("agents-dialog" | "agents-setup-dialog") => "agents",
        Some("rules-dialog" | "rule-dialog") => "message-rules",
        _ => "main",
    }
}

/// F1 in the main window: the help of what it shows
pub fn show_for_main() {
    show(context_of(shell().main().window()));
}

/// Whether Yelp shows the help: it is there and so is the help installed for it (not in the test build, whose
/// driver checks the viewer)
fn yelp_help() -> bool {
    if cfg!(feature = "e2e") {
        return false;
    }
    glib::find_program_in_path("yelp").is_some()
        && glib::system_data_dirs()
            .iter()
            .any(|dir| dir.join("help/C").join(YELP_NAME).join("index.html").is_file())
}

/// The viewer with the topic `id`
pub fn open(id: &str) {
    let help = HELP.with(|help| help.borrow().clone()).unwrap_or_else(|| {
        let help = Help::new();
        HELP.with(|slot| *slot.borrow_mut() = Some(help.clone()));
        help
    });
    help.go(id, true);
    help.split.set_show_content(true);
    help.window.present();
}

pub fn close() {
    if let Some(help) = HELP.with(|help| help.borrow().clone()) {
        help.window.close();
    }
}

/// The help window
pub struct Help {
    pub window: adw::ApplicationWindow,
    split: adw::NavigationSplitView,
    page: adw::NavigationPage,
    pub view: DocumentView,
    pub search: gtk::SearchEntry,
    /// The contents, or the results of a search
    pub list: gtk::ListBox,
    /// "list", or "none" when a search found nothing
    pub lists: gtk::Stack,
    back: gtk::Button,
    forward: gtk::Button,
    /// The rows of the list: each one's topic and the section it is in (none in a search's results)
    rows: RefCell<Vec<(gtk::ListBoxRow, String, Option<String>)>>,
    /// The topics shown, the one at `at` on screen
    history: RefCell<Vec<String>>,
    at: Cell<usize>,
}

impl Help {
    fn new() -> Rc<Help> {
        let view = DocumentView::new("help", false);
        let search = gtk::SearchEntry::builder()
            .placeholder_text(t!(HelpSearchPlaceholder))
            .hexpand(true)
            .build();
        let list = gtk::ListBox::new();
        list.add_css_class("navigation-sidebar");
        list.set_selection_mode(gtk::SelectionMode::Single);
        let none = adw::StatusPage::builder()
            .icon_name("edit-find-symbolic")
            .title(t!(HelpNoResults))
            .build();
        none.add_css_class("compact");
        let lists = gtk::Stack::new();
        lists.add_named(
            &gtk::ScrolledWindow::builder()
                .hscrollbar_policy(gtk::PolicyType::Never)
                .vexpand(true)
                .child(&list)
                .build(),
            Some("list"),
        );
        lists.add_named(&none, Some("none"));

        // the sidebar: the search over the contents
        let search_bar = gtk::Box::new(gtk::Orientation::Horizontal, 0);
        search_bar.set_margin_start(12);
        search_bar.set_margin_end(12);
        search_bar.set_margin_bottom(6);
        search_bar.append(&search);
        let sidebar = adw::ToolbarView::new();
        sidebar.add_top_bar(&adw::HeaderBar::new());
        sidebar.add_top_bar(&search_bar);
        sidebar.set_content(Some(&lists));
        let sidebar_page = adw::NavigationPage::builder()
            .title(t!(HelpTitle))
            .tag("contents")
            .child(&sidebar)
            .build();

        // the topic, with Back and Forward through the topics shown
        let back = crate::ui::icon_button("go-previous-symbolic", &t!(HelpBack));
        let forward = crate::ui::icon_button("go-next-symbolic", &t!(HelpForward));
        let history_buttons = gtk::Box::new(gtk::Orientation::Horizontal, 0);
        history_buttons.add_css_class("linked");
        history_buttons.append(&back);
        history_buttons.append(&forward);
        let header = adw::HeaderBar::new();
        header.pack_start(&history_buttons);
        let content = adw::ToolbarView::new();
        content.add_top_bar(&header);
        content.set_content(Some(&view.view));
        let page = adw::NavigationPage::builder()
            .title(t!(HelpTitle))
            .tag("topic")
            .child(&content)
            .build();

        let split = adw::NavigationSplitView::builder()
            .sidebar(&sidebar_page)
            .content(&page)
            .min_sidebar_width(240.0)
            .max_sidebar_width(320.0)
            .build();
        // not owned by the main window: the help stays usable while a dialog of the main window is open
        let window = adw::ApplicationWindow::builder()
            .application(&shell().application)
            .title(t!(HelpTitle))
            .default_width(1000)
            .default_height(720)
            .width_request(360)
            .height_request(300)
            .content(&split)
            .icon_name(crate::APP_ID)
            .build();
        window.set_widget_name("help-window");
        // one pane in a narrow window: the contents, then the topic with the way back to them in its header bar
        // (Back and Forward through the topics then only by Alt+Left and Alt+Right, not two arrows side by side)
        let breakpoint =
            adw::Breakpoint::new(adw::BreakpointCondition::parse("max-width: 640sp").expect("a condition"));
        breakpoint.add_setter(&split, "collapsed", Some(&true.to_value()));
        breakpoint.add_setter(&history_buttons, "visible", Some(&false.to_value()));
        window.add_breakpoint(breakpoint);

        let help = Rc::new(Help {
            window,
            split,
            page,
            view,
            search,
            list,
            lists,
            back,
            forward,
            rows: RefCell::default(),
            history: RefCell::default(),
            at: Cell::new(0),
        });
        help.connect();
        help.fill("");
        help
    }

    fn connect(self: &Rc<Self>) {
        let on = |act: fn(&Rc<Help>)| {
            let weak = Rc::downgrade(self);
            move || {
                if let Some(this) = weak.upgrade() {
                    act(&this);
                }
            }
        };
        let back = on(|this| this.step(false));
        self.back.connect_clicked(move |_| back());
        let forward = on(|this| this.step(true));
        self.forward.connect_clicked(move |_| forward());
        let changed = on(|this| this.fill(&this.search.text()));
        self.search.connect_search_changed(move |_| changed());
        // Enter in the search opens the first topic it found
        let list = self.list.clone();
        self.search.connect_activate(move |_| {
            if let Some(row) = list.row_at_index(0).filter(|r| r.is_activatable()) {
                row.activate();
            }
        });
        let weak = Rc::downgrade(self);
        self.list.connect_row_activated(move |_, row| {
            let Some(this) = weak.upgrade() else { return };
            let id = this
                .rows
                .borrow()
                .iter()
                .find(|(r, ..)| r == row)
                .map(|(_, id, _)| id.clone());
            if let Some(id) = id {
                this.go(&id, true);
                this.split.set_show_content(true);
            }
        });
        // a section's title over its first topic
        let weak: Weak<Help> = Rc::downgrade(self);
        self.list.set_header_func(move |row, before| {
            let Some(this) = weak.upgrade() else { return };
            let rows = this.rows.borrow();
            let section = |row: &gtk::ListBoxRow| rows.iter().find(|(r, ..)| r == row).and_then(|(.., s)| s.clone());
            let title = section(row).filter(|title| before.and_then(section).as_ref() != Some(title));
            row.set_header(title.map(|title| section_header(&title, before.is_none())).as_ref());
        });
        // a topic: link is followed here, any other opens in the browser
        let weak = Rc::downgrade(self);
        self.view
            .set_links(move |uri| weak.upgrade().is_some_and(|this| this.follow(uri)));
        self.keys();
        let weak = Rc::downgrade(self);
        self.window.connect_close_request(move |_| {
            if let Some(this) = weak.upgrade() {
                this.view.release();
            }
            HELP.with(|help| help.borrow_mut().take());
            glib::Propagation::Proceed
        });
    }

    /// Alt+Left and Alt+Right through the topics shown, Ctrl+F to the search, Ctrl+W closes
    fn keys(self: &Rc<Self>) {
        let shortcuts = gtk::ShortcutController::new();
        shortcuts.set_scope(gtk::ShortcutScope::Managed);
        let add = |keys: &str, act: fn(&Help)| {
            let weak = Rc::downgrade(self);
            shortcuts.add_shortcut(gtk::Shortcut::new(
                gtk::ShortcutTrigger::parse_string(keys),
                Some(gtk::CallbackAction::new(move |_, _| {
                    if let Some(this) = weak.upgrade() {
                        act(&this);
                    }
                    glib::Propagation::Stop
                })),
            ));
        };
        add("<Alt>Left", |this| this.step(false));
        add("<Alt>Right", |this| this.step(true));
        add("<Primary>f", |this| {
            this.split.set_show_content(false);
            this.search.grab_focus();
        });
        add("<Primary>w", |this| this.window.close());
        self.window.add_controller(shortcuts);
    }

    /// The list: the contents, or the topics a search for `query` found, the best first
    fn fill(&self, query: &str) {
        let language = pe_core::i18n::language();
        let platform = pe_html::Platform::Linux;
        let query = query.trim();
        let entries: Vec<(pe_html::HelpTopic, Option<String>)> = if query.is_empty() {
            pe_html::help_contents(platform, language)
                .into_iter()
                .flat_map(|section| {
                    let title = section.title;
                    section
                        .topics
                        .into_iter()
                        .map(move |topic| (topic, Some(title.clone())))
                })
                .collect()
        } else {
            pe_html::help_search(query, platform, language)
                .into_iter()
                .map(|topic| (topic, None))
                .collect()
        };
        self.list.remove_all();
        let mut rows = Vec::with_capacity(entries.len());
        for (topic, section) in entries {
            // a result with its summary, so the right one is found without opening each
            let summary = section.is_none().then_some(topic.summary.as_str());
            let row = topic_row(&topic.title, summary);
            self.list.append(&row);
            rows.push((row, topic.id, section));
        }
        let found = !rows.is_empty();
        *self.rows.borrow_mut() = rows;
        self.list.invalidate_headers();
        self.lists.set_visible_child_name(if found { "list" } else { "none" });
        self.select_shown();
    }

    /// The row of the topic shown selected, when the list has it
    fn select_shown(&self) {
        let shown = self.shown();
        let row = self
            .rows
            .borrow()
            .iter()
            .find(|(_, id, _)| Some(id) == shown.as_ref())
            .map(|(r, ..)| r.clone());
        match row {
            Some(row) => self.list.select_row(Some(&row)),
            None => self.list.unselect_all(),
        }
    }

    /// The topic on screen
    pub fn shown(&self) -> Option<String> {
        self.history.borrow().get(self.at.get()).cloned()
    }

    /// Shows the topic `id`; `new` when it is a step of its own in the history (not Back or Forward)
    fn go(&self, id: &str, new: bool) {
        let Some(document) = pe_html::help_topic(id, pe_html::Platform::Linux, pe_core::i18n::language()) else {
            return;
        };
        if new {
            if self.shown().as_deref() == Some(id) {
                return;
            }
            let mut history = self.history.borrow_mut();
            let keep = if history.is_empty() { 0 } else { self.at.get() + 1 };
            history.truncate(keep);
            history.push(id.to_string());
            self.at.set(history.len() - 1);
        }
        let title = pe_html::help_contents(pe_html::Platform::Linux, pe_core::i18n::language())
            .into_iter()
            .flat_map(|section| section.topics)
            .find(|topic| topic.id == id)
            .map(|topic| topic.title);
        self.page.set_title(&title.unwrap_or_else(|| t!(HelpTitle)));
        self.view.show(&document, false);
        self.back.set_sensitive(self.at.get() > 0);
        self.forward
            .set_sensitive(self.at.get() + 1 < self.history.borrow().len());
        self.select_shown();
    }

    /// Back (`forward` false) or Forward through the topics shown
    pub fn step(&self, forward: bool) {
        let at = self.at.get();
        let to = if forward { at + 1 } else { at.wrapping_sub(1) };
        let Some(id) = self.history.borrow().get(to).cloned() else {
            return;
        };
        self.at.set(to);
        self.go(&id, false);
    }

    /// A link clicked in the page: true when it is one to a topic, which is then shown here
    pub fn follow(&self, uri: &str) -> bool {
        let Some(id) = pe_html::help_link_topic(uri) else {
            return false;
        };
        self.go(id, true);
        true
    }
}

/// A section's title over its topics in the sidebar
fn section_header(title: &str, first: bool) -> gtk::Label {
    let label = gtk::Label::builder()
        .label(title)
        .xalign(0.0)
        .wrap(true)
        .margin_start(14)
        .margin_end(12)
        .margin_top(if first { 6 } else { 18 })
        .margin_bottom(6)
        .accessible_role(gtk::AccessibleRole::Heading)
        .build();
    label.add_css_class("heading");
    label.add_css_class("dim-label");
    label
}

/// A topic of the sidebar: its title, and in a search's results its summary under it
fn topic_row(title: &str, summary: Option<&str>) -> gtk::ListBoxRow {
    let lines = gtk::Box::new(gtk::Orientation::Vertical, 2);
    lines.set_valign(gtk::Align::Center);
    lines.set_margin_top(if summary.is_some() { 6 } else { 3 });
    lines.set_margin_bottom(if summary.is_some() { 6 } else { 3 });
    lines.append(&gtk::Label::builder().label(title).xalign(0.0).wrap(true).build());
    if let Some(summary) = summary.filter(|s| !s.is_empty()) {
        let label = gtk::Label::builder()
            .label(summary)
            .xalign(0.0)
            .wrap(true)
            .lines(3)
            .ellipsize(gtk::pango::EllipsizeMode::End)
            .build();
        label.add_css_class("caption");
        label.add_css_class("dim-label");
        lines.append(&label);
    }
    gtk::ListBoxRow::builder().child(&lines).build()
}

/// The viewer, for the e2e driver
#[cfg(feature = "e2e")]
pub fn viewer() -> Option<Rc<Help>> {
    HELP.with(|help| help.borrow().clone())
}

/// What the e2e driver reads of the list: the sections' titles in it, and its topics' ids
#[cfg(feature = "e2e")]
impl Help {
    pub fn sections(&self) -> Vec<String> {
        let mut sections: Vec<String> = Vec::new();
        for (.., section) in self.rows.borrow().iter() {
            if let Some(section) = section
                && sections.last() != Some(section)
            {
                sections.push(section.clone());
            }
        }
        sections
    }

    pub fn topics(&self) -> Vec<String> {
        self.rows.borrow().iter().map(|(_, id, _)| id.clone()).collect()
    }
}
