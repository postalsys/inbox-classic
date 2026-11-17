//! The security bar over a signed or encrypted message, under its header: what the core says of the whole message, in
//! the tone's colours and with pictures that say the same without them (the lock for an encrypted message; the shield
//! with a check, the ribbon or the warning sign by tone), and Details. The Security Details window shows what the
//! core says of each part. Nothing here reads mail data: the words are the core's.

use adw::prelude::*;
use pe_core::MessageView;
use pe_core::protect::Tone;

/// The CSS class of each tone (its colours are in the app's style, `ui.rs`)
pub const TONE_CLASSES: [&str; 4] = [
    "security-verified",
    "security-good",
    "security-warning",
    "security-neutral",
];

pub fn tone_class(tone: Tone) -> &'static str {
    match tone {
        Tone::Verified => TONE_CLASSES[0],
        Tone::Good => TONE_CLASSES[1],
        Tone::Warning => TONE_CLASSES[2],
        Tone::Neutral => TONE_CLASSES[3],
    }
}

/// The picture of a tone, None for neutral (not signed, or nothing known)
fn tone_icon(tone: Tone) -> Option<&'static str> {
    match tone {
        Tone::Verified => Some("ic-shield-checkmark-symbolic"),
        Tone::Good => Some("ic-ribbon-symbolic"),
        Tone::Warning => Some("ic-warning-symbolic"),
        Tone::Neutral => None,
    }
}

pub struct SecurityBar {
    pub widget: gtk::Box,
    lock: gtk::Image,
    icon: gtk::Image,
    text: gtk::Label,
    /// Opens Security Details; its click goes to the reader
    pub details: gtk::Button,
}

impl SecurityBar {
    pub fn new() -> SecurityBar {
        let picture = |name: &str| {
            let image = gtk::Image::from_icon_name("ic-lock-closed-symbolic");
            image.set_pixel_size(16);
            image.set_valign(gtk::Align::Center);
            image.set_widget_name(name);
            // the words say the same
            image.set_accessible_role(gtk::AccessibleRole::Presentation);
            image
        };
        let lock = picture("reader-security-lock");
        let icon = picture("reader-security-icon");
        let text = gtk::Label::new(None);
        text.set_xalign(0.0);
        text.set_hexpand(true);
        text.set_valign(gtk::Align::Center);
        // the whole sentence on more lines in a narrow window, never cut off
        text.set_wrap(true);
        text.set_wrap_mode(gtk::pango::WrapMode::WordChar);
        text.set_selectable(false);
        text.set_widget_name("reader-security-text");
        let details = gtk::Button::with_mnemonic(&pe_core::i18n::gtk_mnemonic(&t!(UiProtectionDetails)));
        details.set_valign(gtk::Align::Center);
        details.set_widget_name("reader-security-details");
        let widget = gtk::Box::builder()
            .orientation(gtk::Orientation::Horizontal)
            .spacing(8)
            .accessible_role(gtk::AccessibleRole::Group)
            .visible(false)
            .build();
        widget.add_css_class("security-bar");
        widget.set_widget_name("reader-security");
        widget.append(&lock);
        widget.append(&icon);
        widget.append(&text);
        widget.append(&details);
        // the dark colours while the windows are dark (the core's labels in the page follow the same style)
        follow_dark(&widget);
        SecurityBar {
            widget,
            lock,
            icon,
            text,
            details,
        }
    }

    /// The bar of `view`: shown with its tone, pictures and words for a signed or encrypted message, hidden otherwise
    pub fn show(&self, view: &MessageView) {
        let Some(protection) = &view.protection else {
            self.hide();
            return;
        };
        for class in TONE_CLASSES {
            self.widget.remove_css_class(class);
        }
        self.widget.add_css_class(tone_class(protection.tone));
        self.lock.set_visible(protection.encrypted);
        match tone_icon(protection.tone) {
            Some(name) => {
                self.icon.set_icon_name(Some(name));
                self.icon.set_visible(true);
            }
            None => self.icon.set_visible(false),
        }
        self.text.set_text(&protection.text);
        // what a screen reader says of the bar, and of its button
        self.widget
            .update_property(&[gtk::accessible::Property::Label(&protection.text)]);
        self.details
            .update_property(&[gtk::accessible::Property::Description(&protection.text)]);
        self.widget.set_visible(true);
    }

    pub fn hide(&self) {
        self.widget.set_visible(false);
    }

    /// What the bar shows: its words, its tone's class and its pictures (the UI test reads them); None when hidden
    #[cfg(feature = "e2e")]
    pub fn shown(&self) -> Option<(String, String, Vec<String>)> {
        if !self.widget.is_visible() {
            return None;
        }
        let tone = TONE_CLASSES
            .iter()
            .find(|class| self.widget.has_css_class(class))
            .map(|class| class.trim_start_matches("security-").to_string())
            .unwrap_or_default();
        let pictures = [&self.lock, &self.icon]
            .iter()
            .filter(|image| image.is_visible())
            .filter_map(|image| image.icon_name())
            .map(|name| name.to_string())
            .collect();
        Some((self.text.text().to_string(), tone, pictures))
    }
}

/// The `dark` class on `widget` while the windows are dark, which gives the tones' classes in it their dark colours
pub fn follow_dark(widget: &impl IsA<gtk::Widget>) {
    let styles = adw::StyleManager::default();
    crate::ui::set_class(widget, "dark", styles.is_dark());
    let shown = widget.as_ref().downgrade();
    styles.connect_dark_notify(move |styles| {
        if let Some(widget) = shown.upgrade() {
            crate::ui::set_class(&widget, "dark", styles.is_dark());
        }
    });
}

/// The Security Details window over `parent`: the title, what the core says of the message and each part (read only,
/// selectable), Close, and the help of encrypted and signed mail (its button, or F1)
pub fn details_dialog(parent: &impl IsA<gtk::Widget>, view: &MessageView) {
    let Some(protection) = &view.protection else {
        return;
    };
    let text = gtk::TextView::new();
    text.set_editable(false);
    // read only: no caret blinking in it, the mouse and Shift with the arrows still select, Ctrl+C copies
    text.set_cursor_visible(false);
    text.set_wrap_mode(gtk::WrapMode::WordChar);
    fill_details(&text.buffer(), &protection.details());
    text.set_widget_name("protection-details-text");
    text.set_top_margin(10);
    text.set_bottom_margin(10);
    text.set_left_margin(12);
    text.set_right_margin(12);
    text.set_pixels_below_lines(2);
    text.update_property(&[gtk::accessible::Property::Label(&t!(UiProtectionDetailsTitle))]);
    let scrolled = gtk::ScrolledWindow::builder()
        .child(&text)
        .min_content_height(260)
        .vexpand(true)
        .hscrollbar_policy(gtk::PolicyType::Never)
        .build();
    scrolled.add_css_class("card");
    let close = gtk::Button::with_mnemonic(&pe_core::i18n::gtk_mnemonic(&t!(UiClose)));
    close.set_widget_name("protection-details-close");
    close.set_halign(gtk::Align::End);
    close.add_css_class("suggested-action");
    let content = gtk::Box::new(gtk::Orientation::Vertical, 12);
    content.set_margin_start(12);
    content.set_margin_end(12);
    content.set_margin_bottom(12);
    content.append(&scrolled);
    content.append(&close);
    let help = gtk::Button::from_icon_name("help-browser-symbolic");
    help.set_tooltip_text(Some(&crate::words::plain(crate::words::Text::MenuHelp)));
    help.set_widget_name("protection-details-help");
    help.connect_clicked(|_| crate::help::show(HELP_CONTEXT));
    let header = adw::HeaderBar::new();
    header.pack_start(&help);
    let toolbar = adw::ToolbarView::new();
    toolbar.add_top_bar(&header);
    toolbar.set_content(Some(&content));
    let dialog = adw::Dialog::builder()
        .title(t!(UiProtectionDetailsTitle))
        .content_width(600)
        .content_height(420)
        .child(&toolbar)
        .default_widget(&close)
        .focus_widget(&close)
        .build();
    dialog.set_widget_name(DIALOG_NAME);
    let closing = dialog.downgrade();
    close.connect_clicked(move |_| {
        if let Some(dialog) = closing.upgrade() {
            dialog.close();
        }
    });
    dialog.present(Some(parent.as_ref()));
}

/// The Details text in `buffer`: the summary, then each part's line in bold with what is known of it under it, its
/// wrapped lines kept under it too
fn fill_details(buffer: &gtk::TextBuffer, details: &str) {
    let heading = buffer.create_tag(Some("part"), &[("weight", &700i32), ("pixels-above-lines", &6i32)]);
    let detail = buffer.create_tag(Some("detail"), &[("left-margin", &34i32)]);
    for (index, line) in details.lines().enumerate() {
        if index > 0 {
            buffer.insert(&mut buffer.end_iter(), "\n");
        }
        let trimmed = line.trim_start();
        let tag = if trimmed.len() < line.len() {
            detail.as_ref()
        } else if index > 0 && !line.is_empty() {
            heading.as_ref()
        } else {
            None
        };
        match tag {
            Some(tag) => buffer.insert_with_tags(&mut buffer.end_iter(), trimmed, &[tag]),
            None => buffer.insert(&mut buffer.end_iter(), trimmed),
        }
    }
}

/// The Details window's name, by which F1 finds its help
pub const DIALOG_NAME: &str = "protection-details-dialog";

/// Its help context (help/topics.toml)
pub const HELP_CONTEXT: &str = "protection-details";
