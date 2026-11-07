//! What the windows share: the style, message boxes, the form dialog with a label and an input for each field, the
//! small window that waits for a request of the core, dates as the user's locale writes them, the file dialogs, and
//! links opened in the browser. Nothing here reads mail data; it shows what the core decoded.

use std::cell::{Cell, RefCell};
use std::path::PathBuf;
use std::rc::Rc;

use adw::prelude::*;
use gtk::{gdk, gio, glib};

use crate::app::shell;

/// The title of the app's own message boxes, as on Windows
pub const TITLE: &str = "Inbox Classic";

const STYLE: &str = "
.unread { font-weight: bold; }
.message-list { font-feature-settings: 'tnum'; }
.info-bar { background-color: alpha(@accent_bg_color, 0.14); padding: 6px 10px; }
.info-bar .title { font-weight: bold; }
.reader-header { padding: 8px 10px; background-color: @headerbar_bg_color; border-bottom: 1px solid alpha(@borders, 0.6); }
.reader-header .field { opacity: 0.7; }
.reader-header .subject { font-weight: bold; font-size: 1.1em; }
.status-bar { padding: 3px 10px; font-size: 0.9em; border-top: 1px solid alpha(@borders, 0.6); }
.empty-list .title { font-weight: bold; opacity: 0.6; }
.empty-list .more { opacity: 0.6; }
.compose-fields { padding: 6px 10px; }
.compose-fields label.field { opacity: 0.8; }
.compose-fields button.field-button { padding: 2px 6px; min-height: 0; margin-right: -6px; }
.compose-fields button.field-button label { font-weight: normal; }
.format-bar { padding: 2px 8px; border-bottom: 1px solid alpha(@borders, 0.6); }
.editor-frame { border-top: 1px solid alpha(@borders, 0.6); }
.attachment { padding: 2px 8px; border-radius: 6px; background-color: alpha(@view_fg_color, 0.06); }
.completion row { padding: 4px 8px; }
.flag-row { padding: 0 6px; min-height: 30px; border-radius: 6px; }
.flag-row label { font-weight: normal; }
.flag-row:hover { background-color: alpha(@view_fg_color, 0.08); }
.new-address { font-size: 0.8em; font-weight: bold; color: white; background-color: @error_bg_color; border-radius: 4px; padding: 1px 6px; }
";

pub fn load_style() {
    let provider = gtk::CssProvider::new();
    provider.load_from_string(STYLE);
    if let Some(display) = gdk::Display::default() {
        gtk::style_context_add_provider_for_display(&display, &provider, gtk::STYLE_PROVIDER_PRIORITY_APPLICATION);
        // the icons of the gresource (ic-*-symbolic) beside the theme's
        gtk::IconTheme::for_display(&display).add_resource_path("/com/inboxclassic/InboxClassic/icons");
    }
}

// ---- message boxes ----

/// A message box with OK. `heading` is the caption, left out when it is only the app's name
pub async fn alert(parent: &impl IsA<gtk::Widget>, heading: &str, body: &str) {
    ask(parent, heading, body, &[("ok", t!(UiOk).as_str())], "ok", "ok", None).await;
}

/// A message box with the given answers (id, label); the id of the one chosen, `close` for Esc. `destructive`
/// colors that answer red
pub async fn ask(
    parent: &impl IsA<gtk::Widget>,
    heading: &str,
    body: &str,
    answers: &[(&str, &str)],
    default: &str,
    close: &str,
    destructive: Option<&str>,
) -> String {
    let dialog = adw::AlertDialog::new((heading != TITLE).then_some(heading), Some(body));
    for (id, label) in answers {
        dialog.add_response(id, label);
    }
    dialog.set_default_response(Some(default));
    dialog.set_close_response(close);
    if let Some(id) = destructive {
        dialog.set_response_appearance(id, adw::ResponseAppearance::Destructive);
    } else if answers.len() > 1 {
        dialog.set_response_appearance(answers[answers.len() - 1].0, adw::ResponseAppearance::Suggested);
    }
    dialog.choose_future(Some(parent.as_ref())).await.to_string()
}

/// Yes or No, No the default for a question that throws something away (`destructive`)
pub async fn confirm(parent: &impl IsA<gtk::Widget>, heading: &str, body: &str, destructive: bool) -> bool {
    let (default, red) = if destructive {
        ("no", Some("yes"))
    } else {
        ("yes", None)
    };
    ask(
        parent,
        heading,
        body,
        &[("no", t!(UiNo).as_str()), ("yes", t!(UiYes).as_str())],
        default,
        "no",
        red,
    )
    .await
        == "yes"
}

// ---- the form dialog ----

pub enum Kind {
    Text,
    Password,
    Number,
    /// The options; the value is the one chosen
    Choice(Vec<String>),
}

pub struct Field {
    pub label: String,
    pub value: String,
    pub kind: Kind,
}

impl Field {
    pub fn text(label: &str, value: impl Into<String>) -> Field {
        Field {
            label: label.into(),
            value: value.into(),
            kind: Kind::Text,
        }
    }

    pub fn password(label: &str) -> Field {
        Field {
            label: label.into(),
            value: String::new(),
            kind: Kind::Password,
        }
    }

    pub fn number(label: &str, value: impl Into<String>) -> Field {
        Field {
            label: label.into(),
            value: value.into(),
            kind: Kind::Number,
        }
    }

    pub fn choice(label: &str, choices: Vec<String>, chosen: usize) -> Field {
        let value = choices.get(chosen).cloned().unwrap_or_default();
        Field {
            label: label.into(),
            value,
            kind: Kind::Choice(choices),
        }
    }

    /// The position of the option chosen; options that read the same are told apart
    pub fn chosen(&self) -> Option<usize> {
        match &self.kind {
            Kind::Choice(choices) => choices.iter().position(|c| *c == self.value),
            _ => None,
        }
    }
}

type Validate = Box<dyn Fn(&[Field]) -> Result<(), String>>;

/// A modal form: an intro, a row with a label and an input for each field, OK and Cancel. [`Form::run`] waits for OK
/// (with the values checked by the validator, its error shown and the form kept open) or Cancel
pub struct Form {
    dialog: adw::Dialog,
    rows: Vec<gtk::Widget>,
    fields: RefCell<Vec<Field>>,
    clicks: async_channel::Receiver<bool>,
    validate: RefCell<Option<Validate>>,
    parent: gtk::Widget,
    presented: Cell<bool>,
    focus: usize,
}

impl Form {
    /// `focus`: the field to start in. The widget of field `i` is named `form-<i>` (the e2e driver finds it so)
    pub fn new(
        parent: &impl IsA<gtk::Widget>,
        title: &str,
        intro: &str,
        fields: Vec<Field>,
        ok_label: &str,
        focus: usize,
    ) -> Rc<Form> {
        let (send, clicks) = async_channel::unbounded();
        let group = adw::PreferencesGroup::new();
        let rows: Vec<gtk::Widget> = fields.iter().enumerate().map(|(i, field)| form_row(i, field)).collect();
        for row in &rows {
            group.add(row);
        }
        let content = gtk::Box::new(gtk::Orientation::Vertical, 12);
        content.set_margin_start(18);
        content.set_margin_end(18);
        content.set_margin_top(6);
        content.set_margin_bottom(18);
        if !intro.is_empty() {
            let label = wrapped_label(intro);
            label.set_widget_name("form-intro");
            content.append(&label);
        }
        content.append(&group);
        let (dialog, ok) = dialog_with_buttons(title, &content, ok_label, 520);
        let cancel_send = send.clone();
        dialog.connect_closed(move |_| {
            let _ = cancel_send.try_send(false);
        });
        ok.connect_clicked(move |_| {
            let _ = send.try_send(true);
        });
        Rc::new(Form {
            dialog,
            rows,
            fields: RefCell::new(fields),
            clicks,
            validate: RefCell::new(None),
            parent: parent.as_ref().clone(),
            presented: Cell::new(false),
            focus,
        })
    }

    pub fn validate_with(&self, validate: impl Fn(&[Field]) -> Result<(), String> + 'static) {
        *self.validate.borrow_mut() = Some(Box::new(validate));
    }

    /// Shows the form and waits: true once OK was clicked with values the validator takes, false for Cancel
    pub async fn run(&self) -> bool {
        if !self.presented.replace(true) {
            self.dialog.present(Some(&self.parent));
            if let Some(row) = self.rows.get(self.focus) {
                row.grab_focus();
            }
        }
        while let Ok(ok) = self.clicks.recv().await {
            if !ok {
                return false;
            }
            self.read();
            let error = match &*self.validate.borrow() {
                Some(validate) => validate(&self.fields.borrow()).err(),
                None => None,
            };
            match error {
                Some(error) => alert(&self.dialog, TITLE, &error).await,
                None => return true,
            }
        }
        false
    }

    pub fn value(&self, index: usize) -> String {
        self.fields.borrow()[index].value.clone()
    }

    pub fn chosen(&self, index: usize) -> Option<usize> {
        self.fields.borrow()[index].chosen()
    }

    pub fn widget(&self) -> &adw::Dialog {
        &self.dialog
    }

    /// The password fields emptied, the dialog gone
    pub fn close(&self) {
        for (row, field) in self.rows.iter().zip(self.fields.borrow_mut().iter_mut()) {
            if matches!(field.kind, Kind::Password) {
                field.value.clear();
                if let Some(entry) = row.downcast_ref::<adw::EntryRow>() {
                    entry.set_text("");
                }
            }
        }
        self.dialog.close();
    }

    fn read(&self) {
        for (row, field) in self.rows.iter().zip(self.fields.borrow_mut().iter_mut()) {
            match &field.kind {
                Kind::Choice(choices) => {
                    if let Some(combo) = row.downcast_ref::<adw::ComboRow>() {
                        field.value = choices.get(combo.selected() as usize).cloned().unwrap_or_default();
                    }
                }
                _ => {
                    if let Some(entry) = row.downcast_ref::<adw::EntryRow>() {
                        field.value = entry.text().trim().to_string();
                    }
                }
            }
        }
    }
}

impl Drop for Form {
    fn drop(&mut self) {
        self.dialog.close();
    }
}

fn form_row(index: usize, field: &Field) -> gtk::Widget {
    let title = field.label.trim_end_matches(':');
    let row: gtk::Widget = match &field.kind {
        Kind::Choice(choices) => {
            let model = gtk::StringList::new(&choices.iter().map(String::as_str).collect::<Vec<_>>());
            let combo = adw::ComboRow::builder().title(title).model(&model).build();
            combo.set_selected(field.chosen().unwrap_or(0) as u32);
            combo.upcast()
        }
        Kind::Password => {
            let entry = adw::PasswordEntryRow::builder().title(title).build();
            entry.set_activates_default(true);
            entry.upcast()
        }
        Kind::Text | Kind::Number => {
            let entry = adw::EntryRow::builder().title(title).text(&field.value).build();
            entry.set_activates_default(true);
            if matches!(field.kind, Kind::Number) {
                entry.set_input_purpose(gtk::InputPurpose::Digits);
            }
            entry.upcast()
        }
    };
    row.set_widget_name(&format!("form-{index}"));
    row
}

/// Asks for a folder's name (New Folder, Rename Folder): the name typed, None for Cancel or nothing typed
pub async fn ask_folder_name(parent: &impl IsA<gtk::Widget>, title: &str, intro: &str, name: &str) -> Option<String> {
    let form = Form::new(
        parent,
        title,
        intro,
        vec![Field::text(&t!(UiFolderName), name)],
        &t!(UiOk),
        0,
    );
    form.widget().set_widget_name("folder-name-dialog");
    let ok = form.run().await;
    let value = form.value(0);
    form.close();
    (ok && !value.is_empty()).then_some(value)
}

/// A dialog with a header bar of Cancel and `ok_label` around its title, over `content`; the OK button (named
/// `dialog-ok`) is its default
pub fn dialog_with_buttons(
    title: &str,
    content: &impl IsA<gtk::Widget>,
    ok_label: &str,
    width: i32,
) -> (adw::Dialog, gtk::Button) {
    let header = adw::HeaderBar::new();
    header.set_show_end_title_buttons(false);
    header.set_show_start_title_buttons(false);
    let cancel = gtk::Button::with_label(&t!(UiCancel));
    cancel.set_widget_name("dialog-cancel");
    let ok = gtk::Button::with_label(ok_label);
    ok.set_widget_name("dialog-ok");
    ok.add_css_class("suggested-action");
    header.pack_start(&cancel);
    header.pack_end(&ok);
    let view = adw::ToolbarView::new();
    view.add_top_bar(&header);
    view.set_content(Some(content));
    let dialog = adw::Dialog::builder()
        .title(title)
        .content_width(width)
        .child(&view)
        .default_widget(&ok)
        .build();
    let closing = dialog.downgrade();
    cancel.connect_clicked(move |_| {
        if let Some(dialog) = closing.upgrade() {
            dialog.close();
        }
    });
    (dialog, ok)
}

pub fn wrapped_label(text: &str) -> gtk::Label {
    let label = gtk::Label::new(Some(text));
    label.set_wrap(true);
    label.set_xalign(0.0);
    label.set_max_width_chars(60);
    label
}

/// A dialog with `text` to read and copy that can not be edited, and OK (Message Properties); no intro when it is empty
pub fn text_dialog(parent: &impl IsA<gtk::Widget>, title: &str, intro: &str, text: &str) -> adw::Dialog {
    text_dialog_sized(parent, title, intro, text, (640, 520), true, None)
}

/// [`text_dialog`] of `size`; lines that do not fit wrapped, or (`wrap` false) scrolled to, as source code is; `action`
/// at the start of its header bar
pub fn text_dialog_sized(
    parent: &impl IsA<gtk::Widget>,
    title: &str,
    intro: &str,
    text: &str,
    size: (i32, i32),
    wrap: bool,
    action: Option<&gtk::Widget>,
) -> adw::Dialog {
    let view = gtk::TextView::new();
    view.set_editable(false);
    view.set_monospace(true);
    view.set_wrap_mode(if wrap {
        gtk::WrapMode::WordChar
    } else {
        gtk::WrapMode::None
    });
    view.buffer().set_text(text);
    view.set_widget_name("properties-text");
    // the text off the edges of its card
    view.set_top_margin(8);
    view.set_bottom_margin(8);
    view.set_left_margin(10);
    view.set_right_margin(10);
    let scrolled = gtk::ScrolledWindow::builder()
        .child(&view)
        .min_content_height(360)
        .vexpand(true)
        .build();
    scrolled.add_css_class("card");
    let content = gtk::Box::new(gtk::Orientation::Vertical, 8);
    content.set_margin_start(12);
    content.set_margin_end(12);
    content.set_margin_bottom(12);
    if !intro.is_empty() {
        content.append(&wrapped_label(intro));
    }
    content.append(&scrolled);
    let header = adw::HeaderBar::new();
    if let Some(action) = action {
        header.pack_start(action);
    }
    let view_ = adw::ToolbarView::new();
    view_.add_top_bar(&header);
    view_.set_content(Some(&content));
    let dialog = adw::Dialog::builder()
        .title(title)
        .content_width(size.0)
        .content_height(size.1)
        .child(&view_)
        .build();
    dialog.present(Some(parent.as_ref()));
    dialog
}

// ---- waiting for the core ----

/// Waits for the event of `request` with a small dialog titled `title` that says `text` and can cancel it (`cancel`
/// is called then); false when it was cancelled
pub async fn wait_for_request(
    parent: &impl IsA<gtk::Widget>,
    request: u64,
    cancel: impl FnOnce(u64),
    text: &str,
    title: &str,
) -> bool {
    if request == 0 {
        return false;
    }
    // the request's event sends true (the main window hands it on), Cancel and closing false
    let (send, answers) = async_channel::bounded::<bool>(2);
    shell().watch_request(request, send.clone());
    let label = wrapped_label(text);
    label.set_widget_name("wait-text");
    let spinner = adw::Spinner::new();
    spinner.set_size_request(32, 32);
    let cancel_button = gtk::Button::with_label(&t!(UiCancel));
    cancel_button.set_widget_name("wait-cancel");
    cancel_button.set_halign(gtk::Align::End);
    let row = gtk::Box::new(gtk::Orientation::Horizontal, 12);
    row.append(&spinner);
    row.append(&label);
    let content = gtk::Box::new(gtk::Orientation::Vertical, 12);
    content.set_margin_start(18);
    content.set_margin_end(18);
    content.set_margin_bottom(18);
    content.append(&row);
    content.append(&cancel_button);
    let view = adw::ToolbarView::new();
    view.add_top_bar(&adw::HeaderBar::new());
    view.set_content(Some(&content));
    let dialog = adw::Dialog::builder()
        .title(title)
        .content_width(380)
        .child(&view)
        .build();
    dialog.set_widget_name("wait-dialog");
    let on_close = send.clone();
    dialog.connect_closed(move |_| {
        let _ = on_close.try_send(false);
    });
    cancel_button.connect_clicked(move |_| {
        let _ = send.try_send(false);
    });
    dialog.present(Some(parent.as_ref()));
    let finished = answers.recv().await.unwrap_or(false);
    shell().forget_request(request);
    if !finished {
        cancel(request);
    }
    dialog.close();
    finished
}

// ---- dates ----

/// Seconds since the Unix epoch in the user's short date and the time without seconds, local time
pub fn format_date(seconds: i64) -> String {
    glib::DateTime::from_unix_local(seconds)
        .and_then(|date| date.format(&format!("%x {}", time_format())))
        .map(|text| text.to_string())
        .unwrap_or_default()
}

/// The time of day of `seconds` since the Unix epoch, local time, without seconds
pub fn format_time(seconds: i64) -> String {
    glib::DateTime::from_unix_local(seconds)
        .and_then(|date| date.format(time_format()))
        .map(|text| text.to_string())
        .unwrap_or_default()
}

/// The locale's time of day (its %X) without the seconds, as a glib format: "%H:%M", "%l:%M %p", "%H.%M"
pub fn time_format() -> &'static str {
    static FORMAT: std::sync::OnceLock<String> = std::sync::OnceLock::new();
    FORMAT.get_or_init(|| {
        // 13:45:56 says where the locale puts each part
        let Ok(reference) = glib::DateTime::from_local(2001, 2, 3, 13, 45, 56.0) else {
            return "%H:%M".into();
        };
        let text = |format: &str| reference.format(format).map(|t| t.to_string()).unwrap_or_default();
        time_pattern(&text("%X"), &text("%p"))
    })
}

/// The format of a time written like `reference` (13:45:56 in the locale), without its seconds; "%H:%M" when it is
/// not understood
fn time_pattern(reference: &str, pm: &str) -> String {
    let fallback = || "%H:%M".to_string();
    let Some(at) = reference.find("56") else {
        return fallback();
    };
    // the seconds with the separator before them
    let start = reference[..at]
        .char_indices()
        .next_back()
        .map_or(at, |(i, c)| if c.is_ascii_digit() { at } else { i });
    let mut pattern = format!("{}{}", &reference[..start], &reference[at + 2..]);
    if !pm.is_empty() && pattern.contains(pm) {
        pattern = pattern.replacen(pm, "\u{1}", 1);
    }
    let Some(minutes) = pattern.find("45") else {
        return fallback();
    };
    pattern.replace_range(minutes..minutes + 2, "\u{2}");
    let hours = if pattern.contains("13") {
        ("13", "%H")
    } else if pattern.contains("01") {
        ("01", "%I")
    } else if pattern.contains('1') {
        ("1", "%l")
    } else {
        return fallback();
    };
    pattern = pattern.replacen(hours.0, hours.1, 1);
    if pattern.chars().any(|c| c.is_ascii_digit()) {
        return fallback();
    }
    pattern.replace('\u{1}', "%p").replace('\u{2}', "%M").trim().to_string()
}

/// The time of day now, without seconds
pub fn time_now() -> String {
    glib::DateTime::now_local()
        .and_then(|now| now.format(time_format()))
        .map(|text| text.to_string())
        .unwrap_or_default()
}

// ---- files ----

#[cfg(feature = "e2e")]
thread_local! {
    /// What the next file dialogs answer in a test run, instead of being shown: the files chosen, empty to cancel
    pub static FILE_ANSWERS: RefCell<std::collections::VecDeque<Vec<PathBuf>>> = RefCell::default();
}

/// The test's answer to the next file dialog, when it gave one
fn test_answer() -> Option<Vec<PathBuf>> {
    #[cfg(feature = "e2e")]
    {
        FILE_ANSWERS.with(|answers| answers.borrow_mut().pop_front())
    }
    #[cfg(not(feature = "e2e"))]
    {
        None
    }
}

fn filter(name: &str, patterns: &[&str]) -> gio::ListStore {
    let filter = gtk::FileFilter::new();
    filter.set_name(Some(name));
    for pattern in patterns {
        filter.add_pattern(pattern);
    }
    let all = gtk::FileFilter::new();
    all.set_name(Some(&t!(UiFilterAll)));
    all.add_pattern("*");
    let filters = gio::ListStore::new::<gtk::FileFilter>();
    filters.append(&filter);
    filters.append(&all);
    filters
}

fn downloads() -> Option<gio::File> {
    glib::user_special_dir(glib::UserDirectory::Downloads).map(gio::File::for_path)
}

/// The path to save a file to, starting from the safe name the core made, in Downloads; None when cancelled
pub async fn save_file(
    parent: &gtk::Window,
    title: &str,
    name: &str,
    patterns: Option<(&str, &[&str])>,
) -> Option<PathBuf> {
    if let Some(answer) = test_answer() {
        return answer.into_iter().next();
    }
    let dialog = gtk::FileDialog::builder()
        .title(title)
        .initial_name(name)
        .modal(true)
        .build();
    if let Some(folder) = downloads() {
        dialog.set_initial_folder(Some(&folder));
    }
    if let Some((label, patterns)) = patterns {
        dialog.set_filters(Some(&filter(label, patterns)));
    }
    dialog.save_future(Some(parent)).await.ok()?.path()
}

/// The files chosen in an Open dialog that takes several, none when cancelled
pub async fn open_files(parent: &gtk::Window, title: &str, patterns: Option<(&str, &[&str])>) -> Vec<PathBuf> {
    if let Some(answer) = test_answer() {
        return answer;
    }
    let dialog = gtk::FileDialog::builder().title(title).modal(true).build();
    if let Some((label, patterns)) = patterns {
        dialog.set_filters(Some(&filter(label, patterns)));
    }
    let Ok(files) = dialog.open_multiple_future(Some(parent)).await else {
        return Vec::new();
    };
    (0..files.n_items())
        .filter_map(|i| files.item(i).and_downcast::<gio::File>())
        .filter_map(|file| file.path())
        .collect()
}

/// A folder chosen, None when cancelled
pub async fn choose_folder(parent: &gtk::Window, title: &str) -> Option<PathBuf> {
    if let Some(answer) = test_answer() {
        return answer.into_iter().next();
    }
    let dialog = gtk::FileDialog::builder().title(title).modal(true).build();
    if let Some(folder) = downloads() {
        dialog.set_initial_folder(Some(&folder));
    }
    dialog.select_folder_future(Some(parent)).await.ok()?.path()
}

// ---- links ----

/// Whether a link is one the browser (or the mail program) opens: a web address or an e-mail link
pub fn is_link(uri: &str) -> bool {
    let lower = uri.to_ascii_lowercase();
    lower.starts_with("http://") || lower.starts_with("https://") || lower.starts_with("mailto:")
}

/// Opens a link of a message or of the help in the default browser (or mail program); anything else is ignored
pub fn open_externally(uri: &str, parent: Option<&gtk::Window>) {
    if !is_link(uri) {
        return;
    }
    gtk::UriLauncher::new(uri).launch(parent, gio::Cancellable::NONE, |_| {});
}

/// The window a widget is in
pub fn window_of(widget: &impl IsA<gtk::Widget>) -> Option<gtk::Window> {
    widget.as_ref().root().and_downcast::<gtk::Window>()
}

/// A flat button with a symbolic icon and a tooltip
pub fn icon_button(icon: &str, tooltip: &str) -> gtk::Button {
    let button = gtk::Button::from_icon_name(icon);
    button.set_tooltip_text(Some(tooltip));
    button
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn time_without_seconds() {
        assert_eq!(time_pattern("13:45:56", ""), "%H:%M");
        assert_eq!(time_pattern("01:45:56 PM", "PM"), "%I:%M %p");
        assert_eq!(time_pattern("1:45:56 PM", "PM"), "%l:%M %p");
        assert_eq!(time_pattern("13.45.56", ""), "%H.%M");
        assert_eq!(time_pattern("PM 01:45:56", "PM"), "%p %I:%M");
        assert_eq!(time_pattern("nonsense", ""), "%H:%M");
    }

    #[test]
    fn links_that_open() {
        assert!(is_link("https://example.com") && is_link("HTTP://x") && is_link("mailto:a@b"));
        assert!(!is_link("javascript:alert(1)") && !is_link("file:///etc/passwd") && !is_link("inboxclassic://x"));
    }

    #[test]
    fn choices_are_told_apart_by_position() {
        let field = Field::choice("Folder:", vec!["A".into(), "B".into()], 1);
        assert_eq!(field.value, "B");
        assert_eq!(field.chosen(), Some(1));
    }
}
