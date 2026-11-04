//! The editor of the compose window and the signature editor: a web view with the page of pe_html::editor_document,
//! whose own script (allowed by a nonce, nothing else can run) makes the message editable. The page talks back with
//! plain strings through the "host" message handler: "html:", "split:" and "full:" after pe.send(), "state:" for the
//! format bar, "dirty" on the first change, "caret:" and "hover:" with the link at the cursor and under the mouse,
//! "open:" for a Ctrl+clicked link (see the top of core/crates/pe-html/src/editor.js). The host drives it with the six
//! functions every platform's window calls. Files dropped on it never reach the page: the window takes them.

use std::cell::{Cell, RefCell};
use std::path::PathBuf;
use std::rc::Rc;

use gtk::prelude::*;
use gtk::{gdk, gio, glib};
use webkit::prelude::*;

use crate::webview::{DocumentView, js_string};

/// Where the quoted message is when the page gives its HTML: still folded (the draft's goes with the message),
/// unfolded and maybe edited (apart from what was written), or unfolded and deleted
#[derive(Debug, Clone, PartialEq, Eq)]
pub enum Quote {
    Folded,
    Edited(String),
    Removed,
}

/// A handler that gets a string of the page
type OnText = Option<Box<dyn Fn(&str)>>;

/// What the editor tells its window; each does nothing unless the window gives it something to do
#[derive(Default)]
pub struct Handlers {
    /// The body as HTML, after [`Editor::html`]: what was written, and the quote as the page has it
    pub html: Option<Box<dyn Fn(String, Quote)>>,
    /// One '0' or '1' per format of the bar: bold, italic, underline, numbers, bullets, left, center, right
    pub state: OnText,
    pub dirty: Option<Box<dyn Fn()>>,
    /// Ctrl+Enter
    pub send: Option<Box<dyn Fn()>>,
    /// Ctrl+S
    pub save: Option<Box<dyn Fn()>>,
    /// The address of the link under the mouse, or else of the one the cursor is in; empty for none
    pub link: OnText,
    /// Ctrl+K, or Edit Link in the menu of a link
    pub edit_link: Option<Box<dyn Fn()>>,
    /// Files dragged from the file manager onto the text
    pub dropped: Option<Box<dyn Fn(Vec<PathBuf>)>>,
}

pub struct Editor {
    pub document: DocumentView,
    handlers: RefCell<Handlers>,
    caret_link: RefCell<String>,
    hover_link: RefCell<String>,
    /// Whether the page has loaded, and the last formatting flags it reported
    loaded: Cell<bool>,
    focus_when_loaded: Cell<bool>,
    state: RefCell<String>,
}

impl Editor {
    pub fn new(page: &str) -> Rc<Editor> {
        let document = DocumentView::new("compose", true);
        document.view.set_widget_name("editor");
        let editor = Rc::new(Editor {
            document,
            handlers: RefCell::default(),
            caret_link: RefCell::default(),
            hover_link: RefCell::default(),
            loaded: Cell::new(false),
            focus_when_loaded: Cell::new(false),
            state: RefCell::default(),
        });
        let manager = editor.document.manager();
        manager.register_script_message_handler("host", None);
        let weak = Rc::downgrade(&editor);
        manager.connect_script_message_received(Some("host"), move |_, value| {
            if let Some(editor) = weak.upgrade() {
                editor.on_message(&value.to_str());
            }
        });
        let weak = Rc::downgrade(&editor);
        editor.document.view.connect_load_changed(move |_, event| {
            if event == webkit::LoadEvent::Finished
                && let Some(editor) = weak.upgrade()
            {
                editor.loaded.set(true);
                if editor.focus_when_loaded.replace(false) {
                    editor.focus();
                }
            }
        });
        editor.keys();
        editor.drops();
        editor.link_menu();
        editor.document.show(page, false);
        editor
    }

    pub fn set_handlers(&self, handlers: Handlers) {
        *self.handlers.borrow_mut() = handlers;
    }

    fn on_message(&self, message: &str) {
        let handlers = self.handlers.borrow();
        if let Some(body) = message.strip_prefix("html:") {
            if let Some(html) = &handlers.html {
                html(body.to_string(), Quote::Folded);
            }
        } else if let Some(rest) = message.strip_prefix("split:") {
            // what was written, the separator, the quote: the first separator, as the quote may hold one
            let quote = match rest.split_once('\u{1f}') {
                Some((written, quote)) => (written.to_string(), Quote::Edited(quote.to_string())),
                None => (rest.to_string(), Quote::Removed),
            };
            if let Some(html) = &handlers.html {
                html(quote.0, quote.1);
            }
        } else if let Some(body) = message.strip_prefix("full:") {
            if let Some(html) = &handlers.html {
                html(body.to_string(), Quote::Removed);
            }
        } else if let Some(flags) = message.strip_prefix("state:") {
            *self.state.borrow_mut() = flags.to_string();
            if let Some(state) = &handlers.state {
                state(flags);
            }
        } else if message == "dirty" {
            if let Some(dirty) = &handlers.dirty {
                dirty();
            }
        } else if let Some(link) = message.strip_prefix("caret:") {
            *self.caret_link.borrow_mut() = link.to_string();
            self.report_link(&handlers);
        } else if let Some(link) = message.strip_prefix("hover:") {
            *self.hover_link.borrow_mut() = link.to_string();
            self.report_link(&handlers);
        } else if let Some(link) = message.strip_prefix("open:") {
            crate::ui::open_externally(link, crate::ui::window_of(&self.document.view).as_ref());
        }
    }

    fn report_link(&self, handlers: &Handlers) {
        let hover = self.hover_link.borrow();
        let shown = if hover.is_empty() {
            self.caret_link.borrow().clone()
        } else {
            hover.clone()
        };
        if let Some(link) = &handlers.link {
            link(&shown);
        }
    }

    /// Ctrl+Enter sends, Ctrl+S saves, Ctrl+K edits the link: taken before the page sees them
    fn keys(self: &Rc<Self>) {
        let keys = gtk::EventControllerKey::new();
        keys.set_propagation_phase(gtk::PropagationPhase::Capture);
        let weak = Rc::downgrade(self);
        keys.connect_key_pressed(move |_, key, _, modifiers| {
            let Some(editor) = weak.upgrade() else {
                return glib::Propagation::Proceed;
            };
            if !modifiers.contains(gdk::ModifierType::CONTROL_MASK) {
                return glib::Propagation::Proceed;
            }
            let handlers = editor.handlers.borrow();
            let handler = match key {
                gdk::Key::Return | gdk::Key::KP_Enter => &handlers.send,
                gdk::Key::s | gdk::Key::S => &handlers.save,
                gdk::Key::k | gdk::Key::K => &handlers.edit_link,
                _ => return glib::Propagation::Proceed,
            };
            if let Some(handler) = handler {
                handler();
            }
            glib::Propagation::Stop
        });
        self.document.view.add_controller(keys);
    }

    /// Files dropped on the text: their paths to the window, before the web view could see them
    fn drops(self: &Rc<Self>) {
        let target = gtk::DropTarget::new(gdk::FileList::static_type(), gdk::DragAction::COPY);
        target.set_propagation_phase(gtk::PropagationPhase::Capture);
        let weak = Rc::downgrade(self);
        target.connect_drop(move |_, value, _, _| {
            let Some(editor) = weak.upgrade() else { return false };
            let Ok(files) = value.get::<gdk::FileList>() else {
                return false;
            };
            let paths: Vec<PathBuf> = files.files().iter().filter_map(|file| file.path()).collect();
            if let Some(dropped) = &editor.handlers.borrow().dropped {
                dropped(paths);
            }
            true
        });
        self.document.view.add_controller(target);
    }

    /// On a link, the right-click menu starts with Open Link, Edit Link and Remove Link
    fn link_menu(self: &Rc<Self>) {
        let weak = Rc::downgrade(self);
        self.document.view.connect_context_menu(move |view, menu, hit| {
            let Some(editor) = weak.upgrade() else { return false };
            if !hit.context_is_link() {
                return false;
            }
            let link = hit.link_uri().map(|uri| uri.to_string()).unwrap_or_default();
            let open = gio::SimpleAction::new("open-link", None);
            let window = crate::ui::window_of(view);
            open.connect_activate(move |_, _| crate::ui::open_externally(&link, window.as_ref()));
            let edit = gio::SimpleAction::new("edit-link", None);
            let editing = Rc::downgrade(&editor);
            edit.connect_activate(move |_, _| {
                if let Some(editor) = editing.upgrade()
                    && let Some(edit) = &editor.handlers.borrow().edit_link
                {
                    edit();
                }
            });
            let remove = gio::SimpleAction::new("remove-link", None);
            let removing = Rc::downgrade(&editor);
            remove.connect_activate(move |_, _| {
                if let Some(editor) = removing.upgrade() {
                    editor.link("");
                }
            });
            menu.insert(&webkit::ContextMenuItem::new_separator(), 0);
            menu.insert(&webkit::ContextMenuItem::from_gaction(&remove, "Remove Link", None), 0);
            menu.insert(&webkit::ContextMenuItem::from_gaction(&edit, "Edit Link...", None), 0);
            menu.insert(&webkit::ContextMenuItem::from_gaction(&open, "Open Link", None), 0);
            false
        });
    }

    fn script(&self, code: &str) {
        self.document
            .view
            .evaluate_javascript(code, None, None, gio::Cancellable::NONE, |_| {});
    }

    /// A formatting command of the page (bold, fontName, foreColor, insertImage...); `value` goes as a string
    pub fn exec(&self, command: &str, value: &str) {
        self.script(&format!("pe.exec({},{})", js_string(command), js_string(value)));
    }

    pub fn link(&self, url: &str) {
        self.script(&format!("pe.link({})", js_string(url)));
    }

    /// The signature block of another account in place of the one in the text
    pub fn signature(&self, block: &str) {
        self.script(&format!("pe.signature({})", js_string(block)));
    }

    /// Asks the page for the body; it comes to [`Handlers::html`]
    pub fn html(&self) {
        self.script("pe.send()");
    }

    /// The body was saved: the next change is reported as "dirty" again
    pub fn clean(&self) {
        self.script("pe.clean()");
    }

    pub fn focus(&self) {
        if !self.loaded.get() {
            self.focus_when_loaded.set(true);
            return;
        }
        self.document.view.grab_focus();
        self.script("window.pe && pe.focus()");
    }

    /// The address of the link the cursor is in, empty when none
    pub fn caret_link(&self) -> String {
        self.caret_link.borrow().clone()
    }

    #[cfg(feature = "e2e")]
    pub fn is_loaded(&self) -> bool {
        self.loaded.get()
    }

    /// Typed text, as the test types it: inserted at the cursor as typing does
    #[cfg(feature = "e2e")]
    pub fn type_text(&self, text: &str) {
        self.focus();
        self.exec("insertText", text);
    }

    #[cfg(feature = "e2e")]
    pub fn run_script(&self, code: &str) {
        self.script(code);
    }

    pub fn release(&self) {
        self.document.release();
    }
}

/// The picture file at `path` as a `data:` URI for Insert Picture, None when it can not be read or is not a PNG, JPEG
/// or GIF picture (by its content, not its name). A file dropped on the text may be anything: its size and first
/// bytes are looked at before it is read
pub fn picture_uri(path: &std::path::Path) -> Option<String> {
    use std::io::Read;
    let mut file = std::fs::File::open(path).ok()?;
    if file.metadata().ok()?.len() > pe_html::PICTURE_FILE_LIMIT as u64 {
        return None;
    }
    let mut head = Vec::with_capacity(pe_html::PICTURE_HEAD);
    (&mut file)
        .take(pe_html::PICTURE_HEAD as u64)
        .read_to_end(&mut head)
        .ok()?;
    pe_html::picture_type(&head)?;
    let data = std::fs::read(path).ok()?;
    pe_html::picture_uri(&data)
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn only_pictures_go_inline() {
        let dir = std::env::temp_dir().join(format!("ic-picture-{}", std::process::id()));
        std::fs::create_dir_all(&dir).unwrap();
        let gif = dir.join("x.txt");
        std::fs::write(&gif, b"GIF89a").unwrap();
        assert_eq!(picture_uri(&gif).as_deref(), Some("data:image/gif;base64,R0lGODlh"));
        std::fs::write(&gif, b"<svg>").unwrap();
        assert_eq!(picture_uri(&gif), None);
        let big = dir.join("big.png");
        let file = std::fs::File::create(&big).unwrap();
        file.set_len(pe_html::PICTURE_FILE_LIMIT as u64 + 1).unwrap();
        assert_eq!(picture_uri(&big), None);
        assert_eq!(picture_uri(&dir.join("missing")), None);
        std::fs::remove_dir_all(&dir).unwrap();
    }
}
