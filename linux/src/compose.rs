//! The window a message is written in: the address fields, a format bar and the HTML editor (editor.rs). The fields
//! go to the core as typed and the editor's HTML as it comes: the core parses and checks the recipients, sanitizes
//! the HTML, adds the quoted message, reads the attached files and builds the message, so this file only edits. Also
//! the signature editor, which writes with the same bar and editor.

use std::cell::{Cell, RefCell};
use std::path::{Path, PathBuf};
use std::rc::Rc;

use adw::prelude::*;
use gtk::{gdk, gio, glib};
use pe_core::{Draft, Outgoing};

use crate::app::{shell, spawn};
use crate::commands::Command;
use crate::editor::{Editor, Handlers, Quote, picture_uri};
use crate::ui::{self, Field, Form, TITLE};

const FONTS: &[&str] = &[
    "Arial",
    "Arial Black",
    "Comic Sans MS",
    "Courier New",
    "Georgia",
    "Segoe UI",
    "Tahoma",
    "Times New Roman",
    "Trebuchet MS",
    "Verdana",
];
/// The sizes of <font size>, 1 to 7, in points
const SIZES: &[&str] = &["8", "10", "12", "14", "18", "24", "36"];

/// A button of the format bar: its icon, its tooltip, the page's command (None for the ones with a dialog), and its
/// place in the page's state flags when it shows one (keep in step with STATE in core/crates/pe-html/src/editor.js)
struct FormatButton {
    icon: &'static str,
    tooltip: &'static str,
    command: Option<&'static str>,
    state: Option<usize>,
}

const FORMAT_BUTTONS: &[&[FormatButton]] = &[
    &[
        FormatButton { icon: "ic-text-bold-symbolic", tooltip: "Bold (Ctrl+B)", command: Some("bold"), state: Some(0) },
        FormatButton { icon: "ic-text-italic-symbolic", tooltip: "Italic (Ctrl+I)", command: Some("italic"), state: Some(1) },
        FormatButton { icon: "ic-text-underline-symbolic", tooltip: "Underline (Ctrl+U)", command: Some("underline"), state: Some(2) },
        FormatButton { icon: "ic-text-color-symbolic", tooltip: "Font Color", command: None, state: None },
    ],
    &[
        FormatButton { icon: "ic-text-number-list-ltr-symbolic", tooltip: "Numbered List", command: Some("insertOrderedList"), state: Some(3) },
        FormatButton { icon: "ic-text-bullet-list-ltr-symbolic", tooltip: "Bulleted List", command: Some("insertUnorderedList"), state: Some(4) },
        FormatButton { icon: "ic-text-indent-decrease-ltr-symbolic", tooltip: "Decrease Indent", command: Some("outdent"), state: None },
        FormatButton { icon: "ic-text-indent-increase-ltr-symbolic", tooltip: "Increase Indent", command: Some("indent"), state: None },
    ],
    &[
        FormatButton { icon: "ic-text-align-left-symbolic", tooltip: "Align Left", command: Some("justifyLeft"), state: Some(5) },
        FormatButton { icon: "ic-text-align-center-symbolic", tooltip: "Center", command: Some("justifyCenter"), state: Some(6) },
        FormatButton { icon: "ic-text-align-right-symbolic", tooltip: "Align Right", command: Some("justifyRight"), state: Some(7) },
    ],
    &[
        FormatButton { icon: "ic-link-symbolic", tooltip: "Hyperlink (Ctrl+K)", command: None, state: None },
        FormatButton { icon: "ic-line-horizontal-1-symbolic", tooltip: "Insert Horizontal Line", command: Some("insertHorizontalRule"), state: None },
        FormatButton { icon: "ic-image-symbolic", tooltip: "Insert Picture", command: None, state: None },
    ],
];

/// The format bar over an editor: font, size, then the buttons; the buttons with a state pressed as the page says
pub struct FormatBar {
    pub widget: gtk::Box,
    toggles: Vec<(usize, gtk::ToggleButton)>,
    /// While the bar follows the page, a button's change is not the user's
    following: Cell<bool>,
}

impl FormatBar {
    fn new(editor: &Rc<Editor>, attach_pictures: bool) -> Rc<FormatBar> {
        let widget = gtk::Box::new(gtk::Orientation::Horizontal, 6);
        widget.add_css_class("format-bar");
        let font = gtk::DropDown::from_strings(FONTS);
        font.set_tooltip_text(Some("Font"));
        let size = gtk::DropDown::from_strings(SIZES);
        size.set_selected(1);
        size.set_tooltip_text(Some("Size"));
        widget.append(&font);
        widget.append(&size);
        let mut toggles = Vec::new();
        let mut buttons = Vec::new();
        for group in FORMAT_BUTTONS {
            let linked = gtk::Box::new(gtk::Orientation::Horizontal, 0);
            linked.set_margin_start(6);
            for spec in *group {
                let button: gtk::Button = if let Some(index) = spec.state {
                    let toggle = gtk::ToggleButton::new();
                    toggles.push((index, toggle.clone()));
                    toggle.upcast()
                } else {
                    gtk::Button::new()
                };
                button.set_icon_name(spec.icon);
                button.set_tooltip_text(Some(spec.tooltip));
                button.add_css_class("flat");
                button.set_widget_name(spec.tooltip.split(" (").next().unwrap_or(spec.tooltip));
                linked.append(&button);
                buttons.push((spec, button));
            }
            widget.append(&linked);
        }
        let bar = Rc::new(FormatBar {
            widget,
            toggles,
            following: Cell::new(false),
        });
        for (spec, button) in buttons {
            let editor = Rc::downgrade(editor);
            let following = Rc::downgrade(&bar);
            button.connect_clicked(move |button| {
                let (Some(editor), Some(bar)) = (editor.upgrade(), following.upgrade()) else { return };
                if bar.following.get() {
                    return;
                }
                match spec.command {
                    Some(command) => editor.exec(command, ""),
                    None => format_dialog(button, &editor, spec.tooltip, attach_pictures),
                }
            });
        }
        let picked = Rc::downgrade(editor);
        font.connect_selected_notify(move |font| {
            if let (Some(editor), Some(name)) = (picked.upgrade(), FONTS.get(font.selected() as usize)) {
                editor.exec("fontName", name);
            }
        });
        let picked = Rc::downgrade(editor);
        size.connect_selected_notify(move |size| {
            if let Some(editor) = picked.upgrade() {
                editor.exec("fontSize", &(size.selected() + 1).to_string());
            }
        });
        bar
    }

    /// The pressed state of the bar's buttons, from the page's flags
    fn show_state(&self, flags: &str) {
        self.following.set(true);
        for (index, toggle) in &self.toggles {
            toggle.set_active(flags.as_bytes().get(*index) == Some(&b'1'));
        }
        self.following.set(false);
    }
}

/// The buttons of the bar that open a dialog: Font Color, Hyperlink, Insert Picture
fn format_dialog(button: &gtk::Button, editor: &Rc<Editor>, which: &str, _attach_pictures: bool) {
    let Some(window) = ui::window_of(button) else { return };
    let editor = editor.clone();
    let which = which.to_string();
    spawn(async move {
        if which.starts_with("Font Color") {
            choose_color(&window, &editor).await;
        } else if which.starts_with("Hyperlink") {
            insert_link(&window, &editor).await;
        } else {
            insert_picture(&window, &editor).await;
        }
    });
}

thread_local! {
    static LAST_COLOR: RefCell<gdk::RGBA> = RefCell::new(gdk::RGBA::new(0.0, 0.2, 0.4, 1.0));
}

async fn choose_color(window: &gtk::Window, editor: &Editor) {
    let dialog = gtk::ColorDialog::builder().title("Font Color").with_alpha(false).build();
    let initial = LAST_COLOR.with(|c| *c.borrow());
    let Ok(color) = dialog.choose_rgba_future(Some(window), Some(&initial)).await else { return };
    LAST_COLOR.with(|c| *c.borrow_mut() = color);
    let channel = |v: f32| (v.clamp(0.0, 1.0) * 255.0).round() as u8;
    let hex = format!("#{:02x}{:02x}{:02x}", channel(color.red()), channel(color.green()), channel(color.blue()));
    editor.exec("foreColor", &hex);
}

/// A link address the dialog takes: a web address or an e-mail link, with more than the scheme
fn valid_link(url: &str) -> Result<(), String> {
    let rest = url.split_once(':').map_or("", |(_, rest)| rest);
    if ui::is_link(url) && !rest.trim_start_matches('/').is_empty() {
        Ok(())
    } else {
        Err("Type a web address (https://...) or an e-mail link (mailto:...).".into())
    }
}

/// The Link button and Ctrl+K: a new link on the selection, or with the cursor in a link its address to change, or
/// to empty to take the link off
async fn insert_link(window: &gtk::Window, editor: &Editor) {
    let current = editor.caret_link();
    let editing = !current.is_empty();
    let (title, intro) = if editing {
        ("Edit Hyperlink", "Where the link goes. Empty the address to remove the link and keep its text.")
    } else {
        ("Hyperlink", "The address the selected text links to.")
    };
    let value = if editing { current } else { "https://".into() };
    let form = Form::new(window, title, intro, vec![Field::text("Address:", value)], "OK", 0);
    form.widget().set_widget_name("link-dialog");
    // an emptied address takes the link off
    form.validate_with(move |fields| {
        if editing && fields[0].value.is_empty() {
            Ok(())
        } else {
            valid_link(&fields[0].value)
        }
    });
    let ok = form.run().await;
    let url = form.value(0);
    form.close();
    if ok {
        editor.link(&url);
    }
}

async fn insert_picture(window: &gtk::Window, editor: &Editor) {
    let patterns = Some(("Pictures", &["*.png", "*.jpg", "*.jpeg", "*.gif"][..]));
    let Some(path) = ui::open_files(window, "Insert Picture", patterns).await.into_iter().next() else { return };
    if !insert_picture_file(editor, &path) {
        let text = "This file is not a PNG, JPEG or GIF picture, or it is larger than 10 MB.";
        ui::alert(window, "Insert Picture", text).await;
    }
}

/// The picture file at `path` put in the text at the cursor; false when it is no picture the core takes
fn insert_picture_file(editor: &Editor, path: &Path) -> bool {
    match picture_uri(path) {
        Some(uri) => {
            editor.exec("insertImage", &uri);
            true
        }
        None => false,
    }
}

/// What to do with the editor's HTML once it comes
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
enum Pending {
    None,
    Send,
    Save,
    SaveAndClose,
}

/// How closing a message window went
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum Closing {
    Closed,
    /// It closes once its draft is saved
    Saving,
    /// The user kept it open
    Kept,
}

struct File {
    path: PathBuf,
    label: String,
}

pub struct Compose {
    pub window: adw::ApplicationWindow,
    account: Cell<i64>,
    accounts: Vec<i64>,
    from: gtk::DropDown,
    pub to: gtk::Entry,
    pub cc: gtk::Entry,
    pub bcc: gtk::Entry,
    pub subject: gtk::Entry,
    cc_row: [gtk::Widget; 2],
    bcc_row: [gtk::Widget; 2],
    pub cc_button: gtk::Button,
    pub bcc_button: gtk::Button,
    /// The Cc and Bcc rows are shown once they have something in them or were opened
    show_cc: Cell<bool>,
    show_bcc: Cell<bool>,
    files: RefCell<Vec<File>>,
    pub attached: gtk::FlowBox,
    attach_row: [gtk::Widget; 2],
    pub editor: Rc<Editor>,
    pub format: Rc<FormatBar>,
    /// The status bar: whether the draft is saved, or the address of the link at the cursor or under the mouse
    pub status: gtk::Label,
    status_text: RefCell<String>,
    in_reply_to: RefCell<Option<String>>,
    references: RefCell<Vec<String>>,
    quote: RefCell<String>,
    /// The quoted message was plain text: with nothing formatted written, the message goes as plain text (the core
    /// decides), with this as its quote while the user left the quote folded
    quote_plain: Cell<bool>,
    quote_text: RefCell<Option<String>>,
    /// The Message-ID of the draft saved in Drafts, and the account whose Drafts has it
    message_id: RefCell<Option<String>>,
    draft_account: Cell<i64>,
    pending: Cell<Pending>,
    /// Something was typed: closing asks first
    dirty: Cell<bool>,
    filling: Cell<bool>,
    /// Told when the window is gone
    gone: (async_channel::Sender<()>, async_channel::Receiver<()>),
}

/// Opens a window to write a message from `account`, with the fields of `draft` (None for a new message); a window of
/// its own, which the main window can come in front of
pub fn open(account: i64, draft: Option<Draft>) {
    let compose = Compose::new(account, draft.as_ref());
    shell().composes.borrow_mut().push(compose.clone());
    compose.window.present();
    // the cursor where the user writes: the top of the reply, or the To field of a new message
    if draft.is_some_and(|d| !d.to.is_empty()) {
        compose.editor.focus();
    } else {
        compose.to.grab_focus();
    }
}

fn row_label(text: &str) -> gtk::Label {
    let label = gtk::Label::new(Some(text));
    label.add_css_class("field");
    label.set_xalign(1.0);
    label
}

fn field_entry(name: &str) -> gtk::Entry {
    let entry = gtk::Entry::new();
    entry.set_hexpand(true);
    entry.set_widget_name(name);
    entry
}

impl Compose {
    fn new(account: i64, draft: Option<&Draft>) -> Rc<Compose> {
        let shell = shell();
        let accounts = shell.core.accounts().unwrap_or_default();
        let labels: Vec<String> =
            accounts.iter().map(|a| pe_core::account_label(&a.settings.name, &a.settings.email)).collect();
        let from = gtk::DropDown::from_strings(&labels.iter().map(String::as_str).collect::<Vec<_>>());
        from.set_hexpand(true);
        from.set_widget_name("compose-from");
        let ids: Vec<i64> = accounts.iter().map(|a| a.id).collect();
        if let Some(index) = ids.iter().position(|id| *id == account) {
            from.set_selected(index as u32);
        }
        let to = field_entry("compose-to");
        let cc = field_entry("compose-cc");
        let bcc = field_entry("compose-bcc");
        let subject = field_entry("compose-subject");
        for field in [&to, &cc, &bcc] {
            crate::complete::attach(field);
        }
        // Cc and Bcc wait behind these until needed (Alt+C, Alt+B), as most mail programs have it now
        let cc_button = gtk::Button::with_mnemonic("_Cc");
        cc_button.set_widget_name("compose-show-cc");
        let bcc_button = gtk::Button::with_mnemonic("_Bcc");
        bcc_button.set_widget_name("compose-show-bcc");
        let to_row = gtk::Box::new(gtk::Orientation::Horizontal, 4);
        to_row.append(&to);
        to_row.append(&cc_button);
        to_row.append(&bcc_button);
        let attached = gtk::FlowBox::new();
        attached.set_selection_mode(gtk::SelectionMode::Single);
        attached.set_hexpand(true);
        attached.set_max_children_per_line(4);
        attached.set_widget_name("compose-files");
        let grid = gtk::Grid::new();
        grid.add_css_class("compose-fields");
        grid.set_column_spacing(8);
        grid.set_row_spacing(4);
        let rows: [(&str, gtk::Widget); 6] = [
            ("From:", from.clone().upcast()),
            ("To:", to_row.upcast()),
            ("Cc:", cc.clone().upcast()),
            ("Bcc:", bcc.clone().upcast()),
            ("Subject:", subject.clone().upcast()),
            ("Attach:", attached.clone().upcast()),
        ];
        let mut placed: Vec<[gtk::Widget; 2]> = Vec::new();
        for (index, (label, field)) in rows.into_iter().enumerate() {
            let label = row_label(label);
            grid.attach(&label, 0, index as i32, 1, 1);
            grid.attach(&field, 1, index as i32, 1, 1);
            placed.push([label.upcast(), field]);
        }
        let saved = draft.is_some_and(|d| d.message_id.is_some());
        let mut body = draft.map(|d| d.body.clone()).unwrap_or_default();
        // a saved draft opened again goes on with what was written; anything new starts with the signature
        if !saved {
            body.push_str(&shell.core.signature_block(account).unwrap_or_default());
        }
        let quote = draft.map(|d| d.quote.clone()).unwrap_or_default();
        let page = pe_html::editor_document(
            (!quote.is_empty()).then_some(quote.as_str()),
            draft.is_some_and(|d| d.quote_folded),
            &body,
        );
        let editor = Editor::new(&page);
        let format = FormatBar::new(&editor, true);
        let status = gtk::Label::new(None);
        status.set_xalign(0.0);
        status.set_ellipsize(gtk::pango::EllipsizeMode::End);
        status.set_widget_name("compose-status");
        let status_bar = gtk::Box::new(gtk::Orientation::Horizontal, 0);
        status_bar.add_css_class("status-bar");
        status_bar.append(&status);
        let frame = gtk::Box::new(gtk::Orientation::Vertical, 0);
        frame.add_css_class("editor-frame");
        frame.append(&editor.document.view);
        let content = gtk::Box::new(gtk::Orientation::Vertical, 0);
        content.append(&grid);
        content.append(&format.widget);
        content.append(&frame);
        content.append(&status_bar);
        let header = adw::HeaderBar::new();
        let send = gtk::Button::with_label("Send");
        send.add_css_class("suggested-action");
        send.set_widget_name("compose-send");
        let save = ui::icon_button("ic-save-symbolic", "Save (Ctrl+S)");
        save.set_widget_name("compose-save");
        let attach = ui::icon_button("ic-attach-symbolic", "Attach");
        attach.set_widget_name("compose-attach");
        header.pack_start(&send);
        header.pack_start(&save);
        header.pack_start(&attach);
        let title = draft.map(|d| d.subject.clone()).filter(|s| !s.is_empty()).unwrap_or("New Message".into());
        let toolbar = adw::ToolbarView::new();
        toolbar.add_top_bar(&header);
        toolbar.set_content(Some(&content));
        let window = adw::ApplicationWindow::builder()
            .application(&shell.application)
            .title(&title)
            .default_width(760)
            .default_height(620)
            .content(&toolbar)
            .icon_name(crate::APP_ID)
            .build();
        window.set_widget_name("compose-window");
        let mut placed = placed.into_iter();
        let mut next = || placed.next().expect("six rows");
        let (_from_row, _to_row, cc_row, bcc_row, _subject_row, attach_row) =
            (next(), next(), next(), next(), next(), next());
        let compose = Rc::new(Compose {
            window,
            account: Cell::new(account),
            accounts: ids,
            from,
            to,
            cc,
            bcc,
            subject,
            cc_row,
            bcc_row,
            cc_button,
            bcc_button,
            show_cc: Cell::new(false),
            show_bcc: Cell::new(false),
            files: RefCell::default(),
            attached,
            attach_row,
            editor,
            format,
            status,
            status_text: RefCell::default(),
            in_reply_to: RefCell::new(None),
            references: RefCell::default(),
            quote: RefCell::new(quote),
            quote_plain: Cell::new(false),
            quote_text: RefCell::new(None),
            message_id: RefCell::new(None),
            draft_account: Cell::new(0),
            pending: Cell::new(Pending::None),
            dirty: Cell::new(false),
            filling: Cell::new(true),
            gone: async_channel::bounded(1),
        });
        if let Some(draft) = draft {
            compose.fill(account, draft);
        }
        compose.show_rows();
        compose.connect(&send, &save, &attach);
        compose.filling.set(false);
        compose
    }

    fn fill(&self, account: i64, draft: &Draft) {
        self.to.set_text(&draft.to);
        self.cc.set_text(&draft.cc);
        self.bcc.set_text(&draft.bcc);
        self.subject.set_text(&draft.subject);
        *self.in_reply_to.borrow_mut() = draft.in_reply_to.clone();
        *self.references.borrow_mut() = draft.references.clone();
        *self.quote_text.borrow_mut() = draft.quote_text.clone();
        self.quote_plain.set(draft.quote_text.is_some());
        // a saved draft opened again: its files, and its Message-ID so the next save replaces it
        *self.message_id.borrow_mut() = draft.message_id.clone();
        self.draft_account.set(account);
        for path in &draft.attachments {
            self.add_file(path);
        }
    }

    /// From, To and Subject always; Cc and Bcc when they have something or were opened; Attach once there are
    /// files; the Cc and Bcc buttons at the end of the To row for the rows not shown yet
    fn show_rows(&self) {
        if !self.cc.text().is_empty() {
            self.show_cc.set(true);
        }
        if !self.bcc.text().is_empty() {
            self.show_bcc.set(true);
        }
        let (cc, bcc) = (self.show_cc.get(), self.show_bcc.get());
        for widget in &self.cc_row {
            widget.set_visible(cc);
        }
        for widget in &self.bcc_row {
            widget.set_visible(bcc);
        }
        self.cc_button.set_visible(!cc);
        self.bcc_button.set_visible(!bcc);
        let files = !self.files.borrow().is_empty();
        for widget in &self.attach_row {
            widget.set_visible(files);
        }
    }

    fn open_row(&self, cc: bool) {
        if cc {
            self.show_cc.set(true);
        } else {
            self.show_bcc.set(true);
        }
        self.show_rows();
        if cc {
            self.cc.grab_focus();
        } else {
            self.bcc.grab_focus();
        }
    }

    fn connect(self: &Rc<Self>, send: &gtk::Button, save: &gtk::Button, attach: &gtk::Button) {
        let weak = Rc::downgrade(self);
        let on = move |f: fn(&Rc<Compose>)| {
            let weak = weak.clone();
            move || {
                if let Some(this) = weak.upgrade() {
                    f(&this);
                }
            }
        };
        let sending = on(|this| this.request(Pending::Send));
        send.connect_clicked(move |_| sending());
        let saving = on(|this| this.request(Pending::Save));
        save.connect_clicked(move |_| saving());
        let attaching = on(|this| {
            let this = this.clone();
            spawn(async move { this.attach().await });
        });
        attach.connect_clicked(move |_| attaching());
        let cc = on(|this| this.open_row(true));
        self.cc_button.connect_clicked(move |_| cc());
        let bcc = on(|this| this.open_row(false));
        self.bcc_button.connect_clicked(move |_| bcc());
        for field in [&self.to, &self.cc, &self.bcc, &self.subject] {
            let changed = on(|this| this.changed());
            field.connect_changed(move |_| changed());
        }
        let subject = on(|this| {
            let text = this.subject.text();
            this.window.set_title(Some(if text.is_empty() { "New Message" } else { &text }));
        });
        self.subject.connect_changed(move |_| subject());
        let from = on(|this| this.choose_from());
        self.from.connect_selected_notify(move |_| from());
        self.editor_handlers();
        self.files_keys();
        self.window_drops();
        // Ctrl+S in the fields too; F1 the help, as from every window
        let save_key = on(|this| this.request(Pending::Save));
        let shortcuts = gtk::ShortcutController::new();
        shortcuts.set_scope(gtk::ShortcutScope::Managed);
        shortcuts.add_shortcut(gtk::Shortcut::new(
            gtk::ShortcutTrigger::parse_string("<Primary>s"),
            Some(gtk::CallbackAction::new(move |_, _| {
                save_key();
                glib::Propagation::Stop
            })),
        ));
        self.window.add_controller(shortcuts);
        let help = gio::SimpleAction::new(Command::Help.name(), None);
        help.connect_activate(|_, _| crate::help::open());
        self.window.add_action(&help);
        let weak = Rc::downgrade(self);
        self.window.connect_close_request(move |_| {
            if let Some(this) = weak.upgrade() {
                spawn(async move {
                    this.ask_close().await;
                });
            }
            glib::Propagation::Stop
        });
    }

    fn editor_handlers(self: &Rc<Self>) {
        let w = || Rc::downgrade(self);
        let (html, state, dirty, send, save, link, edit_link, dropped) = (w(), w(), w(), w(), w(), w(), w(), w());
        self.editor.set_handlers(Handlers {
            html: Some(Box::new(move |body, quote| {
                if let Some(this) = html.upgrade() {
                    // outside the web view's message that brought it
                    glib::idle_add_local_once(move || this.got_html(body, quote));
                }
            })),
            state: Some(Box::new(move |flags| {
                if let Some(this) = state.upgrade() {
                    this.format.show_state(flags);
                }
            })),
            dirty: Some(Box::new(move || {
                if let Some(this) = dirty.upgrade() {
                    this.changed();
                }
            })),
            send: Some(Box::new(move || {
                if let Some(this) = send.upgrade() {
                    this.request(Pending::Send);
                }
            })),
            save: Some(Box::new(move || {
                if let Some(this) = save.upgrade() {
                    this.request(Pending::Save);
                }
            })),
            link: Some(Box::new(move |address| {
                if let Some(this) = link.upgrade() {
                    this.show_link(address);
                }
            })),
            edit_link: Some(Box::new(move || {
                if let Some(this) = edit_link.upgrade() {
                    let window = this.window.clone().upcast::<gtk::Window>();
                    spawn(async move { insert_link(&window, &this.editor).await });
                }
            })),
            dropped: Some(Box::new(move |paths| {
                if let Some(this) = dropped.upgrade() {
                    this.drop_on_text(paths);
                }
            })),
        });
    }

    /// Delete in the Attach row takes the file off, and so does Remove in its right-click menu
    fn files_keys(self: &Rc<Self>) {
        let keys = gtk::EventControllerKey::new();
        let weak = Rc::downgrade(self);
        keys.connect_key_pressed(move |_, key, _, _| {
            if key == gdk::Key::Delete
                && let Some(this) = weak.upgrade()
            {
                this.remove_selected_file();
                return glib::Propagation::Stop;
            }
            glib::Propagation::Proceed
        });
        self.attached.add_controller(keys);
        let click = gtk::GestureClick::new();
        click.set_button(gdk::BUTTON_SECONDARY);
        let weak = Rc::downgrade(self);
        click.connect_pressed(move |_, _, x, y| {
            let Some(this) = weak.upgrade() else { return };
            let Some(child) = this.attached.child_at_pos(x as i32, y as i32) else { return };
            this.attached.select_child(&child);
            let menu = gio::Menu::new();
            menu.append(Some("Remove"), Some("files.remove"));
            let group = gio::SimpleActionGroup::new();
            let remove = gio::SimpleAction::new("remove", None);
            let removing = Rc::downgrade(&this);
            remove.connect_activate(move |_, _| {
                if let Some(this) = removing.upgrade() {
                    this.remove_selected_file();
                }
            });
            group.add_action(&remove);
            this.attached.insert_action_group("files", Some(&group));
            let popover = gtk::PopoverMenu::from_model(Some(&menu));
            popover.set_parent(&this.attached);
            popover.set_has_arrow(false);
            popover.set_pointing_to(Some(&gdk::Rectangle::new(x as i32, y as i32, 1, 1)));
            popover.connect_closed(|popover| {
                let popover = popover.clone();
                glib::idle_add_local_once(move || popover.unparent());
            });
            popover.popup();
        });
        self.attached.add_controller(click);
    }

    /// Files dragged from the file manager onto the window are attached
    fn window_drops(self: &Rc<Self>) {
        let target = gtk::DropTarget::new(gdk::FileList::static_type(), gdk::DragAction::COPY);
        let weak = Rc::downgrade(self);
        target.connect_drop(move |_, value, _, _| {
            let (Some(this), Ok(files)) = (weak.upgrade(), value.get::<gdk::FileList>()) else { return false };
            let paths: Vec<PathBuf> = files.files().iter().filter_map(|f| f.path()).collect();
            this.add_files(&paths);
            true
        });
        self.window.add_controller(target);
    }

    /// The message changed since it was saved or opened: a "saved" status no longer holds
    fn changed(&self) {
        if self.filling.get() {
            return;
        }
        if !self.dirty.get() {
            self.set_status("");
        }
        self.dirty.set(true);
    }

    fn set_status(&self, text: &str) {
        *self.status_text.borrow_mut() = text.to_string();
        self.status.set_text(text);
    }

    /// Where the link under the mouse, or else the one the cursor is in, goes; the status as it was without either
    fn show_link(&self, link: &str) {
        if link.is_empty() {
            self.status.set_text(&self.status_text.borrow());
        } else {
            self.status.set_text(&format!("{link}    (Ctrl+click to open)"));
        }
    }

    /// Another account chosen in From: the message goes from it, with its servers, Sent Items, Drafts and signature
    fn choose_from(&self) {
        let Some(&account) = self.accounts.get(self.from.selected() as usize) else { return };
        if account == self.account.get() || self.filling.get() {
            return;
        }
        self.account.set(account);
        self.editor.signature(&shell().core.signature_block(account).unwrap_or_default());
        self.changed();
    }

    // ---- files ----

    /// Adds a file that is there (not a folder); false otherwise
    fn add_file(&self, path: &Path) -> bool {
        let Ok(metadata) = std::fs::metadata(path) else { return false };
        if metadata.is_dir() {
            return false;
        }
        let name = path.file_name().map(|n| n.to_string_lossy().into_owned()).unwrap_or_default();
        let file = File {
            path: path.to_path_buf(),
            label: format!("{name} ({})", pe_core::format_size(metadata.len())),
        };
        let chip = gtk::Label::new(Some(&file.label));
        chip.add_css_class("attachment");
        self.attached.append(&chip);
        self.files.borrow_mut().push(file);
        self.show_rows();
        true
    }

    fn add_files(&self, paths: &[PathBuf]) {
        for path in paths {
            if self.add_file(path) {
                self.changed();
            }
        }
    }

    async fn attach(&self) {
        let window = self.window.clone().upcast::<gtk::Window>();
        let files = ui::open_files(&window, "Insert Attachment", None).await;
        self.add_files(&files);
    }

    /// The selected file of the Attach row taken off the message
    pub fn remove_selected_file(&self) {
        let Some(child) = self.attached.selected_children().into_iter().next() else { return };
        let index = child.index();
        if index < 0 || index as usize >= self.files.borrow().len() {
            return;
        }
        self.files.borrow_mut().remove(index as usize);
        self.attached.remove(&child);
        self.changed();
        self.show_rows();
        let left = self.files.borrow().len() as i32;
        if left > 0
            && let Some(next) = self.attached.child_at_index(index.min(left - 1))
        {
            self.attached.select_child(&next);
        }
    }

    /// Files dropped on the text: each picture goes in where the cursor is, as Insert Picture puts one; other files
    /// (and pictures too large to go inline) are attached
    fn drop_on_text(&self, paths: Vec<PathBuf>) {
        let attach: Vec<PathBuf> = paths.into_iter().filter(|path| !insert_picture_file(&self.editor, path)).collect();
        self.add_files(&attach);
    }

    #[cfg(feature = "e2e")]
    pub fn file_labels(&self) -> Vec<String> {
        self.files.borrow().iter().map(|f| f.label.clone()).collect()
    }

    // ---- sending and saving ----

    /// The editor's HTML is asked for first, the action follows when it comes
    fn request(&self, action: Pending) {
        if self.pending.get() == Pending::None {
            self.pending.set(action);
            self.editor.html();
        }
    }

    fn got_html(self: &Rc<Self>, html: String, quote: Quote) {
        let pending = self.pending.replace(Pending::None);
        let outgoing = self.outgoing(html, &quote);
        let this = self.clone();
        match pending {
            Pending::Send => spawn(async move { this.send(outgoing).await }),
            Pending::Save | Pending::SaveAndClose => {
                spawn(async move { this.save(outgoing, pending == Pending::SaveAndClose).await })
            }
            Pending::None => {}
        }
    }

    /// The message as the core takes it, from the fields and the editor's HTML
    fn outgoing(&self, html: String, quote: &Quote) -> Outgoing {
        let account = self.account.get();
        let draft_account = self.draft_account.get();
        // the draft's quote while folded, the user's once unfolded, none once deleted; its plain text (from a plain
        // text original) only for the draft's own
        let (quote, quote_text) = match quote {
            Quote::Folded => {
                let own = self.quote.borrow().clone();
                ((!own.is_empty()).then_some(own), self.quote_text.borrow().clone().filter(|t| !t.is_empty()))
            }
            Quote::Edited(edited) => ((!edited.is_empty()).then(|| edited.clone()), None),
            Quote::Removed => (None, None),
        };
        Outgoing {
            to: self.to.text().to_string(),
            cc: self.cc.text().to_string(),
            bcc: self.bcc.text().to_string(),
            subject: self.subject.text().to_string(),
            text: String::new(),
            html: Some(html),
            quote,
            quote_plain: self.quote_plain.get(),
            quote_text,
            attachments: self.files.borrow().iter().map(|f| f.path.clone()).collect(),
            in_reply_to: self.in_reply_to.borrow().clone(),
            references: self.references.borrow().clone(),
            message_id: self.message_id.borrow().clone(),
            // saved in another account's Drafts before From changed: the core moves it once this account has it
            draft_account: (draft_account != 0 && draft_account != account).then_some(draft_account),
        }
    }

    /// Sends now, or with the next Send/Recv; a typo in an address or a file that is gone keeps the window open
    async fn send(&self, outgoing: Outgoing) {
        match shell().core.send(self.account.get(), outgoing) {
            Ok(()) => {
                // the main window shows whether the server took it
                self.dirty.set(false);
                self.destroy();
            }
            Err(reason) => ui::alert(&self.window, TITLE, &reason.to_string()).await,
        }
    }

    /// Saves in Drafts in place of the copy saved before; closes the window after when `close`
    async fn save(&self, outgoing: Outgoing, close: bool) {
        match shell().core.save_draft(self.account.get(), outgoing) {
            Ok(message_id) => {
                *self.message_id.borrow_mut() = Some(message_id);
                self.draft_account.set(self.account.get());
                self.dirty.set(false);
                self.editor.clean();
                // the server's answer follows (draft_saved)
                self.set_status("Saving to Drafts...");
                if close {
                    self.destroy();
                }
            }
            Err(reason) => ui::alert(&self.window, TITLE, &reason.to_string()).await,
        }
    }

    /// Whether the window may close now: when nothing changed since it was sent or saved, or the user does not want it
    /// saved. Yes saves it in Drafts and closes the window after.
    pub async fn ask_close(&self) -> Closing {
        if !self.dirty.get() {
            self.destroy();
            return Closing::Closed;
        }
        let answers = [("cancel", "Cancel"), ("no", "No"), ("yes", "Yes")];
        let question = "Do you want to save changes to this message in Drafts?";
        match ui::ask(&self.window, TITLE, question, &answers, "yes", "cancel", None).await.as_str() {
            "yes" => {
                self.request(Pending::SaveAndClose);
                Closing::Saving
            }
            "no" => {
                self.destroy();
                Closing::Closed
            }
            _ => Closing::Kept,
        }
    }

    fn destroy(&self) {
        shell().composes.borrow_mut().retain(|c| c.window != self.window);
        self.editor.release();
        self.window.destroy();
        let _ = self.gone.0.try_send(());
        // back to the main window, as when it was the owner
        let main = shell().main();
        if main.window().is_visible() {
            main.window().present();
        }
    }
}

/// The save of the draft `message_id` finished, `problem` None when it worked: the window that saved it says so;
/// false when that window is no longer open
pub fn draft_saved(message_id: &str, problem: Option<&str>) -> bool {
    let composes = shell().composes.borrow().clone();
    let Some(compose) = composes.iter().find(|c| c.message_id.borrow().as_deref() == Some(message_id)) else {
        return false;
    };
    match problem {
        Some(problem) => compose.set_status(&format!("Not saved in Drafts: {problem}")),
        None => compose.set_status(&format!("Saved in Drafts at {}", ui::time_now())),
    }
    true
}

/// The app closing: each compose window is asked to close, a message with changes asks whether to save it; true once
/// they all went (those saving on closing included), false when the user kept one open
pub async fn close_all() -> bool {
    let composes = shell().composes.borrow().clone();
    for compose in composes {
        compose.window.present();
        match compose.ask_close().await {
            Closing::Closed => {}
            Closing::Saving => {
                let _ = compose.gone.1.recv().await;
            }
            Closing::Kept => return false,
        }
    }
    true
}

// ---- the signature editor ----

/// The signature of an account in an editor of its own (Accounts > Signature); whether it was saved
pub async fn edit_signature(parent: &impl IsA<gtk::Widget>, account: i64, name: &str) -> bool {
    let Ok(current) = shell().core.signature(account) else { return false };
    let editor = Editor::new(&pe_html::editor_document(None, false, &current));
    let format = FormatBar::new(&editor, false);
    let hint = gtk::Label::new(Some("Added to new messages, replies and forwards from this account."));
    hint.set_xalign(0.0);
    hint.set_wrap(true);
    hint.set_margin_start(10);
    hint.set_margin_top(6);
    hint.set_margin_bottom(6);
    let frame = gtk::Box::new(gtk::Orientation::Vertical, 0);
    frame.add_css_class("editor-frame");
    frame.set_size_request(-1, 220);
    frame.append(&editor.document.view);
    let content = gtk::Box::new(gtk::Orientation::Vertical, 0);
    content.append(&format.widget);
    content.append(&frame);
    content.append(&hint);
    let (dialog, ok) = ui::dialog_with_buttons(&format!("Signature - {name}"), &content, "OK", 640);
    dialog.set_content_height(360);
    dialog.set_widget_name("signature-dialog");
    let (send, answer) = async_channel::bounded::<Option<String>>(1);
    let on_close = send.clone();
    dialog.connect_closed(move |_| {
        let _ = on_close.try_send(None);
    });
    let asking = editor.clone();
    ok.connect_clicked(move |_| asking.html());
    let followed = format.clone();
    let html = send.clone();
    let dropped = Rc::downgrade(&editor);
    editor.set_handlers(Handlers {
        html: Some(Box::new(move |body, _| {
            let _ = html.try_send(Some(body));
        })),
        state: Some(Box::new(move |flags| followed.show_state(flags))),
        // pictures go in where they were dropped; a signature has no attachments
        dropped: Some(Box::new(move |paths| {
            if let Some(editor) = dropped.upgrade() {
                for path in paths {
                    insert_picture_file(&editor, &path);
                }
            }
        })),
        ..Default::default()
    });
    dialog.present(Some(parent.as_ref()));
    editor.focus();
    let mut saved = false;
    while let Ok(Some(body)) = answer.recv().await {
        if shell().core.set_signature(account, &body).is_ok() {
            saved = true;
            break;
        }
        ui::alert(&dialog, "Signature", "The signature could not be saved.").await;
    }
    editor.release();
    dialog.close();
    saved
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn link_addresses() {
        assert!(valid_link("https://example.com").is_ok());
        assert!(valid_link("mailto:ann@example.com").is_ok());
        assert!(valid_link("https://").is_err());
        assert!(valid_link("javascript:alert(1)").is_err());
        assert!(valid_link("example.com").is_err());
    }
}
