//! The reading pane: the header of the message (the brand's logo beside it, Unsubscribe and the paper clip with the
//! files at its right), the bar of a calendar invitation, the bar that says pictures from the internet are blocked,
//! and the message itself, the sanitized document of the core in a locked down web view.

use adw::prelude::*;
use gtk::{gdk, gio, glib};
use pe_core::MessageView;
use pe_core::calendar::{Invitation, Method};

use crate::webview::{DocumentView, no_message};

pub struct Reader {
    pub widget: gtk::Box,
    header: gtk::Box,
    logo: gtk::Picture,
    subject: gtk::Label,
    fields: gtk::Grid,
    from: gtk::Label,
    date: gtk::Label,
    to: gtk::Label,
    /// "Loading the message...", or why it is not shown
    note: gtk::Label,
    /// Leaving the message's mailing list: its click goes to the window
    pub unsubscribe: gtk::Label,
    /// The paper clip with the files of the message
    pub attachments: gtk::MenuButton,
    attachments_label: gtk::Label,
    invitation: gtk::Box,
    invitation_title: gtk::Label,
    invitation_details: gtk::Label,
    pub open_calendar: gtk::Button,
    /// The bar that says pictures from the internet are blocked; its button shows them
    pictures: gtk::Box,
    pub download_pictures: gtk::Button,
    pub preview: DocumentView,
}

fn field_label(text: &str) -> gtk::Label {
    let label = gtk::Label::new(Some(text));
    label.add_css_class("field");
    label.set_xalign(1.0);
    label.set_yalign(0.0);
    label
}

fn value_label(name: &str) -> gtk::Label {
    let label = gtk::Label::new(None);
    label.set_xalign(0.0);
    label.set_selectable(true);
    label.set_ellipsize(gtk::pango::EllipsizeMode::End);
    label.set_hexpand(true);
    label.set_widget_name(name);
    label
}

impl Reader {
    pub fn new() -> Reader {
        let subject = value_label("reader-subject");
        subject.add_css_class("subject");
        let from = value_label("reader-from");
        let date = value_label("reader-date");
        let to = value_label("reader-to");
        let fields = gtk::Grid::new();
        fields.set_column_spacing(8);
        fields.set_row_spacing(2);
        for (row, (name, value)) in [("From:", &from), ("To:", &to), ("Date:", &date)]
            .into_iter()
            .enumerate()
        {
            fields.attach(&field_label(name), 0, row as i32, 1, 1);
            fields.attach(value, 1, row as i32, 1, 1);
        }
        let note = gtk::Label::new(None);
        note.set_xalign(0.0);
        note.set_widget_name("reader-note");
        let unsubscribe = gtk::Label::new(None);
        unsubscribe.set_markup("<a href=\"unsubscribe\">Unsubscribe</a>");
        unsubscribe.set_widget_name("reader-unsubscribe");
        unsubscribe.set_valign(gtk::Align::Start);
        unsubscribe.set_visible(false);
        let top = gtk::Box::new(gtk::Orientation::Horizontal, 8);
        top.append(&subject);
        top.append(&unsubscribe);
        let text = gtk::Box::new(gtk::Orientation::Vertical, 6);
        text.set_hexpand(true);
        text.append(&top);
        text.append(&fields);
        text.append(&note);
        let logo = gtk::Picture::new();
        logo.set_size_request(48, 48);
        logo.set_valign(gtk::Align::Center);
        logo.set_widget_name("reader-logo");
        logo.set_visible(false);
        let attachments_label = gtk::Label::new(Some("1 file"));
        let clip = gtk::Box::new(gtk::Orientation::Horizontal, 6);
        clip.append(&gtk::Image::from_icon_name("ic-attach-symbolic"));
        clip.append(&attachments_label);
        let attachments = gtk::MenuButton::new();
        attachments.set_child(Some(&clip));
        attachments.set_valign(gtk::Align::Center);
        attachments.set_tooltip_text(Some("The files of the message"));
        attachments.set_widget_name("reader-attachments");
        attachments.set_visible(false);
        let header = gtk::Box::new(gtk::Orientation::Horizontal, 12);
        header.add_css_class("reader-header");
        header.append(&logo);
        header.append(&text);
        header.append(&attachments);

        let invitation_title = gtk::Label::new(None);
        invitation_title.add_css_class("title");
        invitation_title.set_xalign(0.0);
        invitation_title.set_ellipsize(gtk::pango::EllipsizeMode::End);
        let invitation_details = gtk::Label::new(None);
        invitation_details.set_xalign(0.0);
        invitation_details.set_ellipsize(gtk::pango::EllipsizeMode::End);
        let lines = gtk::Box::new(gtk::Orientation::Vertical, 2);
        lines.set_hexpand(true);
        lines.append(&invitation_title);
        lines.append(&invitation_details);
        let open_calendar = gtk::Button::with_label("Open in Calendar");
        open_calendar.set_valign(gtk::Align::Center);
        open_calendar.set_widget_name("reader-open-calendar");
        let invitation = gtk::Box::new(gtk::Orientation::Horizontal, 10);
        invitation.add_css_class("info-bar");
        invitation.set_widget_name("reader-invitation");
        invitation.append(&gtk::Image::from_icon_name("ic-calendar-ltr-symbolic"));
        invitation.append(&lines);
        invitation.append(&open_calendar);
        invitation.set_visible(false);

        let blocked = gtk::Label::new(Some(
            "Some pictures have been blocked to help prevent the sender from identifying your computer.",
        ));
        blocked.set_xalign(0.0);
        blocked.set_hexpand(true);
        blocked.set_ellipsize(gtk::pango::EllipsizeMode::End);
        let download_pictures = gtk::Button::with_label("Download Pictures");
        download_pictures.set_widget_name("reader-download-pictures");
        let pictures = gtk::Box::new(gtk::Orientation::Horizontal, 10);
        pictures.add_css_class("info-bar");
        pictures.set_widget_name("reader-pictures");
        pictures.append(&gtk::Image::from_icon_name("ic-image-symbolic"));
        pictures.append(&blocked);
        pictures.append(&download_pictures);
        pictures.set_visible(false);

        let preview = DocumentView::new("preview", false);
        preview.view.set_widget_name("reader-preview");
        let widget = gtk::Box::new(gtk::Orientation::Vertical, 0);
        widget.append(&header);
        widget.append(&invitation);
        widget.append(&pictures);
        widget.append(&preview.view);
        let reader = Reader {
            widget,
            header,
            logo,
            subject,
            fields,
            from,
            date,
            to,
            note,
            unsubscribe,
            attachments,
            attachments_label,
            invitation,
            invitation_title,
            invitation_details,
            open_calendar,
            pictures,
            download_pictures,
            preview,
        };
        reader.clear(false);
        reader
    }

    /// Emptied; saying there is no message selected unless one is `loading`. The bars of the message before stay
    /// while the next one loads, and go when it is there without them: the message does not jump down and up again
    pub fn clear(&self, loading: bool) {
        if !loading {
            self.attachments.set_visible(false);
            self.pictures.set_visible(false);
            self.invitation.set_visible(false);
        }
        self.unsubscribe.set_visible(false);
        self.logo.set_visible(false);
        self.subject.set_text("");
        self.fields.set_visible(false);
        self.note.set_visible(false);
        self.header.set_visible(loading);
        self.preview.show(&no_message(!loading), false);
    }

    pub fn loading(&self) {
        self.header.set_visible(true);
        self.note.set_text("Loading the message...");
        self.note.set_visible(true);
    }

    pub fn failed(&self) {
        self.header.set_visible(true);
        self.fields.set_visible(false);
        self.subject.set_text("");
        self.note.set_text("The message could not be shown.");
        self.note.set_visible(true);
        self.attachments.set_visible(false);
        self.pictures.set_visible(false);
    }

    /// The message: its header, the bars it needs, its document (with its pictures from the internet when
    /// `remote_images`)
    pub fn show(&self, view: &MessageView, remote_images: bool) {
        self.header.set_visible(true);
        self.note.set_visible(false);
        self.fields.set_visible(true);
        self.subject.set_text(&view.subject);
        self.from.set_text(&view.from);
        self.date
            .set_text(&view.date.map(crate::ui::format_date).unwrap_or_default());
        let to = if view.cc.is_empty() {
            view.to.clone()
        } else {
            format!("{}    Cc:  {}", view.to, view.cc)
        };
        self.to.set_text(&to);
        self.unsubscribe.set_visible(view.unsubscribe.is_some());
        self.show_attachments(view);
        self.show_invitation(view.invitation.as_ref());
        self.preview.show(&view.document, remote_images);
        // offered only for a message with pictures on the internet, until they are shown
        self.pictures.set_visible(view.remote_images && !remote_images);
    }

    /// The paper clip: how many files, a menu item to save each (the name the sender gave, its size), then all of
    /// them into a folder; files are saved, never opened from here
    fn show_attachments(&self, view: &MessageView) {
        let count = view.attachments.len();
        self.attachments.set_visible(count > 0);
        if count == 0 {
            return;
        }
        self.attachments_label.set_text(&if count == 1 {
            "1 file".into()
        } else {
            format!("{count} files")
        });
        let files = gio::Menu::new();
        for (index, file) in view.attachments.iter().enumerate() {
            let label = format!("{} ({})", file.filename, pe_core::format_size(file.size));
            let item = gio::MenuItem::new(Some(&label), None);
            item.set_action_and_target_value(Some("reader.save-attachment"), Some(&(index as u32).to_variant()));
            files.append_item(&item);
        }
        let menu = gio::Menu::new();
        menu.append_section(None, &files);
        let all = gio::Menu::new();
        all.append(Some("Save Attachments..."), Some("reader.save-all"));
        menu.append_section(None, &all);
        self.attachments.set_menu_model(Some(&menu));
    }

    /// The event of the message's calendar part, its two lines as the bar shows them
    fn show_invitation(&self, event: Option<&Invitation>) {
        let Some(event) = event else {
            self.invitation.set_visible(false);
            return;
        };
        let kind = match event.method {
            Method::Request => "Invitation: ",
            Method::Update => "Updated invitation: ",
            Method::Cancel => "Canceled: ",
            Method::Reply => "Answer to an invitation: ",
        };
        let summary = if event.summary.is_empty() {
            "(no title)"
        } else {
            &event.summary
        };
        self.invitation_title.set_text(&format!("{kind}{summary}"));
        let mut parts = vec![when(event), event.location.clone()];
        if !event.organizer.is_empty() {
            parts.push(format!("Organizer: {}", event.organizer));
        }
        parts.push(event.repeats.clone());
        if event.attendees > 0 {
            parts.push(match event.attendees {
                1 => "1 attendee".into(),
                n => format!("{n} attendees"),
            });
        }
        parts.retain(|part| !part.is_empty());
        self.invitation_details.set_text(&parts.join("   \u{00B7}   "));
        self.invitation.set_visible(true);
    }

    /// The brand's logo beside the header, once the core drew it: `size` pixels square, BGRA with the alpha
    /// multiplied in
    pub fn show_logo(&self, pixels: Option<Vec<u8>>, size: i32) {
        let expected = (size * size * 4) as usize;
        match pixels {
            Some(pixels) if pixels.len() == expected => {
                let bytes = glib::Bytes::from_owned(pixels);
                let texture = gdk::MemoryTexture::new(
                    size,
                    size,
                    gdk::MemoryFormat::B8g8r8a8Premultiplied,
                    &bytes,
                    (size * 4) as usize,
                );
                self.logo.set_paintable(Some(&texture));
                self.logo.set_visible(true);
            }
            _ => self.logo.set_visible(false),
        }
    }

    #[cfg(feature = "e2e")]
    pub fn invitation_shown(&self) -> bool {
        self.invitation.is_visible()
    }

    #[cfg(feature = "e2e")]
    pub fn logo_shown(&self) -> bool {
        self.logo.is_visible()
    }

    /// Whether the bar of blocked pictures is shown
    pub fn pictures_blocked(&self) -> bool {
        self.pictures.is_visible()
    }

    pub fn hide_logo(&self) {
        self.logo.set_visible(false);
    }

    /// What the e2e driver checks: the header's words
    #[cfg(feature = "e2e")]
    pub fn header_text(&self) -> String {
        format!(
            "{} | {} | {} | {} | {}",
            self.subject.text(),
            self.from.text(),
            self.to.text(),
            self.date.text(),
            self.note.text()
        )
    }
}

/// An instant as the reader's local time, or as written (floating: in no zone the invitation defines)
fn event_time(seconds: i64, floating: bool) -> Option<glib::DateTime> {
    if floating {
        glib::DateTime::from_unix_utc(seconds).ok()
    } else {
        glib::DateTime::from_unix_local(seconds).ok()
    }
}

fn long_date(time: &glib::DateTime) -> String {
    time.format("%A %x").map(|t| t.to_string()).unwrap_or_default()
}

fn time_of_day(time: &glib::DateTime) -> String {
    time.format("%H:%M").map(|t| t.to_string()).unwrap_or_default()
}

fn same_day(a: &glib::DateTime, b: &glib::DateTime) -> bool {
    a.ymd() == b.ymd()
}

/// When an event is, in words: its day (or days) and times
fn when(event: &Invitation) -> String {
    let Some(start) = event.start.and_then(|s| event_time(s, event.floating)) else {
        return String::new();
    };
    let end = event
        .end
        .and_then(|e| event_time(e - if event.all_day { 86400 } else { 0 }, event.floating));
    if event.all_day {
        return match end {
            Some(end) if !same_day(&start, &end) => format!("{} to {}", long_date(&start), long_date(&end)),
            _ => long_date(&start),
        };
    }
    let mut text = format!("{}, {}", long_date(&start), time_of_day(&start));
    if let Some(end) = end {
        if same_day(&start, &end) {
            text.push_str(&format!(" to {}", time_of_day(&end)));
        } else {
            text.push_str(&format!(" to {}, {}", long_date(&end), time_of_day(&end)));
        }
    }
    if event.floating {
        text.push_str(" (the sender's time)");
    }
    text
}
