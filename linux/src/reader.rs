//! The reading pane: the header of the message (the brand's logo beside it, Unsubscribe and the paper clip with the
//! files at its right), the bar of a calendar invitation, the bar that says pictures from the internet are blocked,
//! and the message itself, the sanitized document of the core in a locked down web view.

use adw::prelude::*;
use gtk::{gdk, gio, glib};
use pe_core::MessageView;
use pe_core::calendar::{Invitation, Method};
use std::cell::RefCell;
use std::rc::Rc;

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
    /// Why the message is not shown
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
    /// The bar over a message that could not be downloaded; its button tries again
    retry: gtk::Box,
    pub try_again: gtk::Button,
    pub preview: DocumentView,
    /// a moment after a message is asked for, the pane says it is being downloaded (one that is cached shows first)
    downloading: Rc<RefCell<Option<glib::SourceId>>>,
    /// The words over several messages while they are shown
    summary: RefCell<Option<(String, String)>>,
}

/// The pane says the message is being downloaded, without Try Again
fn show_downloading(preview: &DocumentView, retry: &gtk::Box) {
    retry.set_visible(false);
    preview.show(&pe_core::reader_page(pe_core::ReaderState::Downloading), false);
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
        for (row, (name, value)) in [
            (t!(UiFieldFrom), &from),
            (t!(UiFieldTo), &to),
            (t!(GtkReaderDate), &date),
        ]
        .into_iter()
        .enumerate()
        {
            fields.attach(&field_label(&name), 0, row as i32, 1, 1);
            fields.attach(value, 1, row as i32, 1, 1);
        }
        let note = gtk::Label::new(None);
        note.set_xalign(0.0);
        note.set_widget_name("reader-note");
        let unsubscribe = gtk::Label::new(None);
        unsubscribe.set_markup(&format!(
            "<a href=\"unsubscribe\">{}</a>",
            gtk::glib::markup_escape_text(&t!(UiUnsubscribe))
        ));
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
        attachments.set_tooltip_text(Some(&t!(GtkReaderFiles)));
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
        let open_calendar = gtk::Button::with_label(&t!(UiOpenInCalendar));
        open_calendar.set_valign(gtk::Align::Center);
        open_calendar.set_widget_name("reader-open-calendar");
        let invitation = gtk::Box::new(gtk::Orientation::Horizontal, 10);
        invitation.add_css_class("info-bar");
        invitation.set_widget_name("reader-invitation");
        invitation.append(&gtk::Image::from_icon_name("ic-calendar-ltr-symbolic"));
        invitation.append(&lines);
        invitation.append(&open_calendar);
        invitation.set_visible(false);

        let blocked = gtk::Label::new(Some(&t!(GtkPicturesBlocked)));
        blocked.set_xalign(0.0);
        blocked.set_hexpand(true);
        blocked.set_ellipsize(gtk::pango::EllipsizeMode::End);
        let download_pictures = gtk::Button::with_label(&t!(GtkDownloadPictures));
        download_pictures.set_widget_name("reader-download-pictures");
        let pictures = gtk::Box::new(gtk::Orientation::Horizontal, 10);
        pictures.add_css_class("info-bar");
        pictures.set_widget_name("reader-pictures");
        pictures.append(&gtk::Image::from_icon_name("ic-image-symbolic"));
        pictures.append(&blocked);
        pictures.append(&download_pictures);
        pictures.set_visible(false);

        let note_retry = gtk::Label::new(Some(&pe_core::retry_note()));
        note_retry.set_xalign(0.0);
        note_retry.set_hexpand(true);
        note_retry.set_ellipsize(gtk::pango::EllipsizeMode::End);
        let try_again = gtk::Button::with_label(&t!(UiTryAgain));
        try_again.set_widget_name("reader-try-again");
        let retry = gtk::Box::new(gtk::Orientation::Horizontal, 10);
        retry.add_css_class("info-bar");
        retry.set_widget_name("reader-retry");
        retry.append(&gtk::Image::from_icon_name("ic-arrow-sync-symbolic"));
        retry.append(&note_retry);
        retry.append(&try_again);
        retry.set_visible(false);

        let preview = DocumentView::new("preview", false);
        preview.view.set_widget_name("reader-preview");
        let widget = gtk::Box::new(gtk::Orientation::Vertical, 0);
        widget.append(&header);
        widget.append(&retry);
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
            retry,
            try_again,
            preview,
            downloading: Rc::default(),
            summary: RefCell::default(),
        };
        reader.clear(false);
        reader
    }

    /// Emptied; saying there is no message selected unless one is `loading`. The bars of the message before stay
    /// while the next one loads, and go when it is there without them: the message does not jump down and up again
    pub fn clear(&self, loading: bool) {
        self.summary.borrow_mut().take();
        if !loading {
            self.attachments.set_visible(false);
            self.pictures.set_visible(false);
            self.invitation.set_visible(false);
        }
        self.unsubscribe.set_visible(false);
        self.retry.set_visible(false);
        self.stop_downloading_note();
        self.logo.set_visible(false);
        self.subject.set_text("");
        self.fields.set_visible(false);
        self.note.set_visible(false);
        self.header.set_visible(loading);
        self.preview.show(&no_message(!loading), false);
    }

    /// Several messages selected: how many, and how many of them are unread or flagged, as the page of no message
    /// says there is none. The page stays when it would say the same.
    pub fn summary(&self, summary: &pe_core::Summary) {
        let words = (summary.title(), summary.detail());
        if self.summary.borrow().as_ref() == Some(&words) {
            return;
        }
        self.header.set_visible(false);
        self.preview.show(&summary.page(), false);
        *self.summary.borrow_mut() = Some(words);
    }

    /// Whether the pane shows the page over several messages
    pub fn shows_summary(&self) -> bool {
        self.summary.borrow().is_some()
    }

    /// What the pane says over several messages, the title and the line under it; None when it does not
    #[cfg(feature = "e2e")]
    pub fn summary_shown(&self) -> Option<(String, String)> {
        self.summary.borrow().clone()
    }

    /// A message asked for: its header from the list at once (the window says it is downloading a moment later, should
    /// it not be here yet)
    pub fn loading(&self, message: &pe_store::MessageInfo) {
        self.header.set_visible(true);
        self.note.set_visible(false);
        self.retry.set_visible(false);
        self.fields.set_visible(true);
        self.subject.set_text(&message.subject);
        self.from.set_text(message.sender());
        self.date
            .set_text(&message.display_date().map(crate::ui::format_date).unwrap_or_default());
        self.to.set_text(&message.recipients);
        self.stop_downloading_note();
        let (preview, retry, timer) = (self.preview.clone(), self.retry.clone(), self.downloading.clone());
        let id = glib::timeout_add_local_once(std::time::Duration::from_millis(250), move || {
            timer.borrow_mut().take();
            show_downloading(&preview, &retry);
        });
        self.downloading.replace(Some(id));
    }

    /// The "downloading" page no longer due: the message came (it is parsed now), failed, or another is selected
    pub fn stop_downloading_note(&self) {
        if let Some(timer) = self.downloading.borrow_mut().take() {
            timer.remove();
        }
    }

    /// The message is being downloaded
    pub fn downloading(&self) {
        self.stop_downloading_note();
        show_downloading(&self.preview, &self.retry);
    }

    /// The message could not be downloaded: why, in the pane, and Try Again over it
    pub fn not_downloaded(&self, kind: pe_core::FailureKind, reason: &str) {
        self.stop_downloading_note();
        self.attachments.set_visible(false);
        self.pictures.set_visible(false);
        self.retry.set_visible(true);
        self.preview.show(
            &pe_core::reader_page(pe_core::ReaderState::Failed { kind, reason }),
            false,
        );
    }

    pub fn shows_failure(&self) -> bool {
        self.retry.is_visible()
    }

    pub fn failed(&self) {
        self.stop_downloading_note();
        self.header.set_visible(true);
        self.fields.set_visible(false);
        self.subject.set_text("");
        self.note.set_text(&t!(UiNotShown));
        self.note.set_visible(true);
        self.attachments.set_visible(false);
        self.pictures.set_visible(false);
    }

    /// The message: its header, the bars it needs, its document (with its pictures from the internet when
    /// `remote_images`)
    pub fn show(&self, view: &MessageView, remote_images: bool) {
        self.header.set_visible(true);
        self.note.set_visible(false);
        self.retry.set_visible(false);
        self.stop_downloading_note();
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
        all.append(Some(&t!(GtkSaveAttachmentsMenu)), Some("reader.save-all"));
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
            Method::Request => "request",
            Method::Update => "update",
            Method::Cancel => "cancel",
            Method::Reply => "reply",
        };
        let untitled = t!(UiNoTitle);
        let summary = if event.summary.is_empty() {
            &untitled
        } else {
            &event.summary
        };
        self.invitation_title
            .set_text(&t!(GtkInvitation, kind = kind, summary = summary));
        let mut parts = vec![when(event), event.location.clone()];
        if !event.organizer.is_empty() {
            parts.push(t!(GtkOrganizer, organizer = &event.organizer));
        }
        parts.push(event.repeats.clone());
        if event.attendees > 0 {
            parts.push(t!(GtkAttendees, count = event.attendees));
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
    #[cfg(feature = "e2e")]
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
    time.format(crate::ui::time_format())
        .map(|t| t.to_string())
        .unwrap_or_default()
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
            Some(end) if !same_day(&start, &end) => t!(UiEventSpan, start = &long_date(&start), end = &long_date(&end)),
            _ => long_date(&start),
        };
    }
    let at = |time: &glib::DateTime| t!(GtkDayAndTime, day = &long_date(time), time = &time_of_day(time));
    let text = match end {
        Some(end) if same_day(&start, &end) => t!(UiEventSpan, start = &at(&start), end = &time_of_day(&end)),
        Some(end) => t!(UiEventSpan, start = &at(&start), end = &at(&end)),
        None => at(&start),
    };
    if event.floating {
        t!(UiEventFloating, when = &text)
    } else {
        text
    }
}
