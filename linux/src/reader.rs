//! The reading pane: the header of the message (the brand's logo beside it, Unsubscribe and the paper clip with the
//! files at its right), the bar that says pictures from the internet are blocked, and the message itself (with the
//! cards of the core above it: a calendar event, a bounce, a one-time code), the sanitized document of the core in a locked down web view. The main window has one
//! under its list, and each message window one of its own: the reader keeps the message it shows, asks the core for
//! it, follows the core's events about it and answers its own buttons (the files, the pictures, Try Again, the
//! calendar, Unsubscribe) in the window it is in.

use adw::prelude::*;
use gtk::{gio, glib};
use pe_core::{Event, MessageRef, MessageView};
use std::cell::{Cell, RefCell};
use std::rc::Rc;
use webkit::prelude::*;

use crate::app::{shell, spawn};
use crate::ui::{self, TITLE};
use crate::webview::{DocumentView, no_message};

/// The size the logo of a brand is drawn at
const LOGO_SIZE: i32 = 48;

/// What a core's event did to the message shown, for the window to follow
pub enum Loaded {
    /// The core has its source now (a draft can open)
    Fetched,
    /// It is on screen
    Shown,
}

pub struct Reader {
    pub widget: gtk::Box,
    header: gtk::Box,
    logo: gtk::Image,
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
    /// The bar that says pictures from the internet are blocked; its button shows them, its menu beside it trusts
    /// the sender, or its second line says why it cannot
    pictures: gtk::Box,
    pub download_pictures: gtk::Button,
    pictures_always: gtk::MenuButton,
    /// The bar over a message that could not be downloaded; its button tries again
    retry: gtk::Box,
    pub try_again: gtk::Button,
    pub preview: DocumentView,
    /// Find in This Message: the bar over the message and its box
    find_bar: gtk::SearchBar,
    pub find_entry: gtk::SearchEntry,
    /// Whether the words typed are in the message, None while nothing is looked for (the UI test reads it)
    #[cfg(feature = "e2e")]
    found: Rc<Cell<Option<bool>>>,
    /// a moment after a message is asked for, the pane says it is being downloaded (one that is cached shows first)
    downloading: Rc<RefCell<Option<glib::SourceId>>>,
    /// The words over several messages while they are shown
    summary: RefCell<Option<(String, String)>>,
    /// The message shown, its account, folder and UID; 0 for none
    account: Cell<i64>,
    folder: Cell<i64>,
    uid: Cell<u64>,
    /// The size of the message asked for, from the list, for the page shown while it is downloaded
    size: Cell<u64>,
    /// A message file shown (a message window opened for a .eml), in place of a message of a folder
    file: RefCell<Option<std::path::PathBuf>>,
    /// Its view once the core built it, with its pictures from the internet when `remote_images`
    view: RefCell<Option<MessageView>>,
    remote_images: Cell<bool>,
    /// The view and the logo being made for it, and the one-click unsubscribe on the way; 0 for none
    view_request: Cell<u64>,
    logo_request: Cell<u64>,
    /// Without a logo, the sender's picture from the Address Book being drawn; 0 for none
    picture_request: Cell<u64>,
    unsubscribe_request: Cell<u64>,
}

/// The pane says the message is being downloaded, and how large it is (0: not known), without Try Again
fn show_downloading(preview: &DocumentView, retry: &gtk::Box, size: u64) {
    retry.set_visible(false);
    let size = (size > 0).then_some(size);
    preview.show(&pe_core::reader_page(pe_core::ReaderState::Downloading { size }), false);
}

/// The find bar over the message: a box to type in, closed with its button or Esc
fn find_bar() -> (gtk::SearchBar, gtk::SearchEntry) {
    let entry = gtk::SearchEntry::new();
    entry.set_placeholder_text(Some(&t!(UiFindInMessageHint)));
    entry.update_property(&[gtk::accessible::Property::Label(&t!(UiFindInMessageHint))]);
    entry.set_width_chars(32);
    entry.set_widget_name("reader-find");
    let bar = gtk::SearchBar::new();
    bar.set_child(Some(&entry));
    bar.connect_entry(&entry);
    bar.set_show_close_button(true);
    bar.set_widget_name("reader-find-bar");
    (bar, entry)
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
    pub fn new() -> Rc<Reader> {
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
            fields.attach(&PassedByTab::new(value), 1, row as i32, 1, 1);
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
        top.append(&PassedByTab::new(&subject));
        top.append(&unsubscribe);
        let text = gtk::Box::new(gtk::Orientation::Vertical, 6);
        text.set_hexpand(true);
        text.append(&top);
        text.append(&fields);
        text.append(&note);
        // always 48 points, the drawn pixels scaled into them
        let logo = gtk::Image::builder().pixel_size(48).build();
        logo.set_widget_name("reader-logo");
        logo.set_visible(false);
        // round for a contact's picture (reader-contact), as the list draws senders; a brand's logo square
        let logo_frame = gtk::Box::builder()
            .width_request(48)
            .height_request(48)
            .halign(gtk::Align::Start)
            .valign(gtk::Align::Center)
            .hexpand(false)
            .overflow(gtk::Overflow::Hidden)
            .visible(false)
            .build();
        logo_frame.append(&logo);
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
        header.append(&logo_frame);
        header.append(&text);
        header.append(&attachments);

        let (pictures, download_pictures, pictures_always) = pictures_bar();

        let note_retry = gtk::Label::new(Some(&pe_core::retry_note()));
        note_retry.set_xalign(0.0);
        note_retry.set_hexpand(true);
        // the whole sentence on more lines in a narrow window, not cut off
        note_retry.set_wrap(true);
        note_retry.set_wrap_mode(gtk::pango::WrapMode::WordChar);
        let try_again = gtk::Button::with_label(&t!(UiTryAgain));
        try_again.set_widget_name("reader-try-again");
        try_again.set_valign(gtk::Align::Center);
        let retry = gtk::Box::new(gtk::Orientation::Horizontal, 10);
        retry.add_css_class("info-bar");
        retry.set_widget_name("reader-retry");
        retry.append(&gtk::Image::from_icon_name("ic-arrow-sync-symbolic"));
        retry.append(&note_retry);
        retry.append(&try_again);
        retry.set_visible(false);

        let preview = DocumentView::new("preview", false);
        preview.view.set_widget_name("reader-preview");
        let (find_bar, find_entry) = find_bar();
        let widget = gtk::Box::new(gtk::Orientation::Vertical, 0);
        widget.append(&header);
        widget.append(&retry);
        widget.append(&pictures);
        widget.append(&find_bar);
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
            pictures,
            download_pictures,
            pictures_always,
            retry,
            try_again,
            preview,
            find_bar,
            find_entry,
            #[cfg(feature = "e2e")]
            found: Rc::default(),
            downloading: Rc::default(),
            summary: RefCell::default(),
            account: Cell::new(0),
            folder: Cell::new(0),
            uid: Cell::new(0),
            size: Cell::default(),
            file: RefCell::default(),
            view: RefCell::default(),
            remote_images: Cell::new(false),
            view_request: Cell::new(0),
            logo_request: Cell::new(0),
            picture_request: Cell::new(0),
            unsubscribe_request: Cell::new(0),
        };
        let reader = Rc::new(reader);
        reader.clear(false);
        reader.connect();
        reader
    }

    /// The reader's own buttons, and the actions of the paper clip's menu (`reader.save-attachment`, `reader.save-all`)
    fn connect(self: &Rc<Self>) {
        let weak = Rc::downgrade(self);
        let on = move |f: fn(&Rc<Reader>)| {
            let weak = weak.clone();
            move || {
                if let Some(this) = weak.upgrade() {
                    f(&this);
                }
            }
        };
        let pictures = on(|this| this.load_pictures());
        self.download_pictures.connect_clicked(move |_| pictures());
        let again = on(|this| this.retry());
        self.try_again.connect_clicked(move |_| again());
        let calendar = on(|this| {
            let this = this.clone();
            spawn(async move { this.open_in_calendar().await });
        });
        let leave = on(|this| {
            let this = this.clone();
            spawn(async move { this.unsubscribe().await });
        });
        self.unsubscribe.connect_activate_link(move |_, _| {
            leave();
            glib::Propagation::Stop
        });
        // "Show the message that bounced" on a bounce's card: the message selected in the main window, its folder
        // shown, as Go to Folder shows one (from a message window too, which then gives way to the main window). The
        // core says which link it is, the view names the message.
        let bounced = on(|this| {
            let Some(message) = this.bounced_message() else {
                return;
            };
            shell().show_main();
            shell().main().show_message(message.folder, message.uid);
        });
        // Copy on a one-time code's card: the code the core found on the clipboard (nothing is read from the link)
        let copy = on(|this| this.copy_code());
        self.preview.set_links(move |uri| {
            if pe_html::is_copy_code_link(uri) {
                copy();
                return true;
            }
            if pe_html::is_open_calendar_link(uri) {
                calendar();
                return true;
            }
            if !pe_html::is_bounced_message_link(uri) {
                return false;
            }
            // after the view's signal, as selecting the message shows another document in this view
            glib::idle_add_local_once(bounced.clone());
            true
        });
        let group = gio::SimpleActionGroup::new();
        let save = gio::SimpleAction::new("save-attachment", Some(glib::VariantTy::UINT32));
        let this = Rc::downgrade(self);
        save.connect_activate(move |_, index| {
            if let (Some(this), Some(index)) = (this.upgrade(), index.and_then(|i| i.get::<u32>())) {
                spawn(async move { this.save_attachment(index as usize).await });
            }
        });
        let all = gio::SimpleAction::new("save-all", None);
        let this = Rc::downgrade(self);
        all.connect_activate(move |_, _| {
            if let Some(this) = this.upgrade() {
                spawn(async move { this.save_all_attachments().await });
            }
        });
        group.add_action(&save);
        group.add_action(&all);
        for (name, domain) in [("always-sender", false), ("always-domain", true)] {
            let always = gio::SimpleAction::new(name, None);
            let this = Rc::downgrade(self);
            always.connect_activate(move |_, _| {
                if let Some(this) = this.upgrade() {
                    spawn(async move { this.trust_sender(domain).await });
                }
            });
            group.add_action(&always);
        }
        self.widget.insert_action_group("reader", Some(&group));
        self.connect_find();
    }

    /// The find bar searches the message as the words are typed, Enter (and F3) goes to the next place they are,
    /// Shift+Enter to the one before; the box turns red when they are not in the message. WebKit finds them in the
    /// page it shows, with no script in it
    fn connect_find(&self) {
        let Some(controller) = self.preview.view.find_controller() else {
            return;
        };
        let entry = self.find_entry.clone();
        #[cfg(feature = "e2e")]
        let found = self.found.clone();
        controller.connect_found_text(move |_, _| {
            #[cfg(feature = "e2e")]
            found.set(Some(true));
            entry.remove_css_class("error");
        });
        let entry = self.find_entry.clone();
        #[cfg(feature = "e2e")]
        let found = self.found.clone();
        controller.connect_failed_to_find_text(move |_| {
            #[cfg(feature = "e2e")]
            found.set(Some(false));
            entry.add_css_class("error");
        });
        #[cfg(feature = "e2e")]
        let found = self.found.clone();
        let finder = controller.clone();
        self.find_entry.connect_search_changed(move |entry| {
            #[cfg(feature = "e2e")]
            found.set(None);
            let text = entry.text();
            if text.is_empty() {
                entry.remove_css_class("error");
                finder.search_finish();
                return;
            }
            let options = webkit::FindOptions::CASE_INSENSITIVE | webkit::FindOptions::WRAP_AROUND;
            finder.search(&text, options.bits(), u32::MAX);
        });
        let finder = controller.clone();
        self.find_entry.connect_activate(move |_| finder.search_next());
        let finder = controller.clone();
        self.find_entry.connect_next_match(move |_| finder.search_next());
        let finder = controller.clone();
        self.find_entry
            .connect_previous_match(move |_| finder.search_previous());
        self.find_bar.connect_search_mode_enabled_notify(move |bar| {
            if !bar.is_search_mode() {
                controller.search_finish();
            }
        });
    }

    /// Find in This Message (F3): the find bar opened with its words selected to type over; F3 again, with words in
    /// it, goes to the next place they are
    pub fn find_in_message(&self) {
        if !self.shows_message() {
            return;
        }
        if self.find_bar.is_search_mode() && !self.find_entry.text().is_empty() {
            self.find_entry.emit_next_match();
            return;
        }
        self.find_bar.set_search_mode(true);
        self.find_entry.grab_focus();
        self.find_entry.select_region(0, -1);
    }

    /// Whether the words typed in the find bar are in the message, None while nothing is looked for (the UI test)
    #[cfg(feature = "e2e")]
    pub fn find_result(&self) -> Option<bool> {
        self.find_bar.is_search_mode().then(|| self.found.get()).flatten()
    }

    /// The window the reader is in, for its dialogs
    fn window(&self) -> Option<gtk::Window> {
        self.widget.root().and_downcast::<gtk::Window>()
    }

    // ---- the message shown ----

    pub fn folder(&self) -> i64 {
        self.folder.get()
    }

    pub fn uid(&self) -> u64 {
        self.uid.get()
    }

    /// The message shown (or being downloaded), None for none
    pub fn message(&self) -> Option<MessageRef> {
        (self.uid.get() != 0).then(|| MessageRef {
            folder: self.folder.get(),
            uid: self.uid.get(),
        })
    }

    /// Whether a message (of a folder, or a file) is shown or asked for
    fn shows_message(&self) -> bool {
        self.uid.get() != 0 || self.file.borrow().is_some()
    }

    /// Whether the message is on screen, not only asked for
    pub fn has_view(&self) -> bool {
        self.view.borrow().is_some()
    }

    /// The subject of the message on screen
    pub fn subject(&self) -> Option<String> {
        self.view.borrow().as_ref().map(|v| v.subject.clone())
    }

    /// The one-time code of the card on screen, when there is one
    pub fn otp_code(&self) -> Option<String> {
        self.view.borrow().as_ref().and_then(|v| v.otp_code.clone())
    }

    /// The code card's Copy: the code on the clipboard, said in the status bar
    pub fn copy_code(&self) {
        let Some(code) = self.otp_code() else { return };
        self.preview.view.clipboard().set_text(&code);
        shell().main().set_status(&t!(UiCodeCopied));
    }

    /// The message the bounce on screen returns, when it is in the account
    pub fn bounced_message(&self) -> Option<MessageRef> {
        self.view.borrow().as_ref().and_then(|v| v.bounced_message)
    }

    /// The message `uid` of `folder` (of `account`) asked for: its header from the list at once when there is `info`,
    /// the message once the core has it ([`Reader::on_event`]); tried again when it could not be downloaded and the
    /// account syncs again
    pub fn open(&self, account: i64, folder: i64, uid: u64, info: Option<&pe_store::MessageInfo>) {
        self.account.set(account);
        self.folder.set(folder);
        self.uid.set(uid);
        if let Some(info) = info {
            self.loading(info);
        }
        // MessageReady follows, right away when the message is cached, or MessageFailed
        let _ = shell().core.open_message(folder, uid);
    }

    /// The core's events about the message shown: what they did, for the window
    pub fn on_event(self: &Rc<Self>, event: &Event) -> Option<Loaded> {
        let shown = |folder: i64, uid: u64| uid != 0 && folder == self.folder.get() && uid == self.uid.get();
        match event {
            Event::MessageReady { folder, uid } if shown(*folder, *uid) => {
                self.stop_downloading_note();
                self.start_view();
                Some(Loaded::Fetched)
            }
            Event::MessageFailed {
                folder,
                uid,
                kind,
                message,
            } if shown(*folder, *uid) => {
                self.not_downloaded(*kind, message);
                None
            }
            // a view for a message no longer shown was cancelled, its event is not this one
            Event::ViewReady { request } if self.view_request.get() != 0 && *request == self.view_request.get() => {
                self.show_view().then_some(Loaded::Shown)
            }
            // the account is back: a message it could not give is tried again
            Event::SyncFinished { account, failure: None }
                if *account == self.account.get() && self.uid.get() != 0 && self.shows_failure() =>
            {
                self.retry();
                None
            }
            Event::LogoReady { request } if self.logo_request.get() != 0 && *request == self.logo_request.get() => {
                self.logo_request.set(0);
                self.show_logo(shell().core.logo_result(*request), LOGO_SIZE);
                None
            }
            Event::PictureReady { request }
                if self.picture_request.get() != 0 && *request == self.picture_request.get() =>
            {
                self.picture_request.set(0);
                self.show_logo(shell().core.picture_result(*request), LOGO_SIZE);
                self.set_round(true);
                None
            }
            _ => None,
        }
    }

    /// The view of the message asked for, built on a worker; [`Reader::show_view`] shows it when it comes
    fn start_view(&self) {
        let core = &shell().core;
        if self.view_request.get() != 0 {
            core.message_view_cancel(self.view_request.get());
        }
        let request = core
            .message_view_start(self.folder.get(), self.uid.get(), self.remote_images.get())
            .unwrap_or(0);
        self.view_request.set(request);
        if request == 0 {
            self.failed();
        }
    }

    /// The view built: shown, its brand's logo asked for; false when there is none
    fn show_view(&self) -> bool {
        let core = &shell().core;
        let Some(view) = core.message_view_result(self.view_request.replace(0)) else {
            self.failed();
            return false;
        };
        self.show(&view, self.remote_images.get());
        self.hide_logo();
        if view.has_logo {
            let request = core
                .logo_start(self.folder.get(), self.uid.get(), LOGO_SIZE as u32)
                .unwrap_or(0);
            self.logo_request.set(request);
        } else if view.picture != 0 {
            // the sender's picture from the Address Book, where a brand's logo would be
            let request = core.picture_start(view.picture, LOGO_SIZE as u32).unwrap_or(0);
            self.picture_request.set(request);
        }
        *self.view.borrow_mut() = Some(view);
        true
    }

    /// Download Pictures: the message again, with its pictures from the internet
    pub fn load_pictures(&self) {
        if self.shows_message() && self.has_view() && !self.remote_images.get() {
            self.remote_images.set(true);
            self.view_again();
        }
    }

    /// The view of the message shown built again (its pictures allowed now): a file's at once, a folder's message's
    /// on a worker
    fn view_again(&self) {
        let file = self.file.borrow().clone();
        match file {
            Some(path) => {
                if let Ok(view) = shell().core.file_view(&path, self.remote_images.get()) {
                    self.show_file_view(view);
                }
            }
            None => self.start_view(),
        }
    }

    /// The message file `path` (a .eml) shown, its pictures blocked until asked for; why not when the core could not
    /// read it as a message
    pub fn open_file(&self, path: &std::path::Path) -> Result<(), String> {
        let view = shell().core.file_view(path, false).map_err(|e| e.to_string())?;
        self.clear(true);
        *self.file.borrow_mut() = Some(path.to_path_buf());
        self.show_file_view(view);
        Ok(())
    }

    /// A file's view on screen, its paper clip saving the file's attachments as a folder's message saves its own
    fn show_file_view(&self, view: MessageView) {
        self.show(&view, self.remote_images.get());
        *self.view.borrow_mut() = Some(view);
    }

    /// The pictures bar's Always: the sender's address, or with `domain` everyone at their domain, trusted; the
    /// message again, its pictures now loading by themselves
    async fn trust_sender(&self, domain: bool) {
        let sender = self.view.borrow().as_ref().and_then(|v| v.sender.clone());
        let Some(sender) = sender.filter(|s| s.verified) else {
            return;
        };
        let value = if domain { &sender.domain } else { &sender.address };
        if let Err(error) = shell().core.trust_sender(value, domain) {
            if let Some(window) = self.window() {
                ui::alert(&window, TITLE, &error.to_string()).await;
            }
            return;
        }
        self.view_again();
    }

    /// Try Again, or the account synced again after the message could not be downloaded
    pub fn retry(&self) {
        if self.uid.get() == 0 {
            return;
        }
        self.downloading();
        let _ = shell().core.open_message(self.folder.get(), self.uid.get());
    }

    /// The message as it is shown, with the pictures the user allowed, through the print dialog over `window`
    pub fn print(&self, window: &impl IsA<gtk::Window>) {
        if !self.shows_message() || !self.has_view() {
            return;
        }
        let operation = webkit::PrintOperation::new(&self.preview.view);
        // WebKit destroys its print dialog when run_dialog returns, holding no reference of its own; closed with its
        // close button or Escape, GTK has destroyed it already and it may be freed. Held here until then
        let toplevels = gtk::Window::toplevels();
        let held: Rc<RefCell<Vec<gtk::PrintUnixDialog>>> = Rc::default();
        let kept = held.clone();
        let added = toplevels.connect_items_changed(move |list, position, _, count| {
            let dialogs =
                (position..position + count).filter_map(|i| list.item(i).and_downcast::<gtk::PrintUnixDialog>());
            kept.borrow_mut().extend(dialogs);
        });
        operation.run_dialog(Some(window));
        toplevels.disconnect(added);
        drop(held);
    }

    /// Emptied; saying there is no message selected unless one is `loading`. The bars of the message before stay
    /// while the next one loads, and go when it is there without them: the message does not jump down and up again
    pub fn clear(&self, loading: bool) {
        if self.view_request.get() != 0 {
            shell().core.message_view_cancel(self.view_request.replace(0));
        }
        self.account.set(0);
        self.folder.set(0);
        self.uid.set(0);
        self.file.borrow_mut().take();
        self.remote_images.set(false);
        self.view.borrow_mut().take();
        self.logo_request.set(0);
        self.picture_request.set(0);
        // what was looked for is not in the next message
        self.find_bar.set_search_mode(false);
        self.summary.borrow_mut().take();
        if !loading {
            self.attachments.set_visible(false);
            self.pictures.set_visible(false);
        }
        self.unsubscribe.set_visible(false);
        self.retry.set_visible(false);
        self.stop_downloading_note();
        self.set_logo_shown(false);
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
        let size = message.size.unwrap_or(0);
        self.size.set(size);
        let id = glib::timeout_add_local_once(std::time::Duration::from_millis(250), move || {
            timer.borrow_mut().take();
            show_downloading(&preview, &retry, size);
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
        show_downloading(&self.preview, &self.retry, self.size.get());
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
        // shown when asked for, or by themselves (a trusted sender, or every message's)
        self.preview.show(&view.document, remote_images || view.pictures_loaded);
        self.show_pictures_bar(view);
    }

    /// The pictures bar, offered only for a message with pictures on the internet, until they are shown. With a
    /// sender, Download Pictures has its menu: Always for a sender the provider confirmed, otherwise a dimmed item
    /// that says why not (the core's words), as the Windows app does
    fn show_pictures_bar(&self, view: &MessageView) {
        self.pictures.set_visible(view.remote_images && !view.pictures_loaded);
        let words = view
            .sender
            .as_ref()
            .map(pe_core::pictures::bar_words)
            .unwrap_or_default();
        let menu = gio::Menu::new();
        if !words.always_sender.is_empty() {
            menu.append(Some(&words.always_sender), Some("reader.always-sender"));
            menu.append(Some(&words.always_domain), Some("reader.always-domain"));
        } else if !words.unconfirmed.is_empty() {
            let item = gio::MenuItem::new(None, None);
            item.set_attribute_value("custom", Some(&"unconfirmed".to_variant()));
            menu.append_item(&item);
        }
        self.pictures_always.set_menu_model(Some(&menu));
        self.pictures_always.set_visible(menu.n_items() > 0);
        if !words.unconfirmed.is_empty()
            && let Some(popover) = self.pictures_always.popover().and_downcast::<gtk::PopoverMenu>()
        {
            popover.add_child(&unconfirmed_note(&words.unconfirmed), "unconfirmed");
        }
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

    /// The brand's logo beside the header, once the core drew it: `size` pixels square, BGRA with the alpha
    /// multiplied in
    pub fn show_logo(&self, pixels: Option<Vec<u8>>, size: i32) {
        match pixels.and_then(|pixels| crate::ui::bgra_texture(pixels, size)) {
            Some(texture) => {
                self.logo.set_paintable(Some(&texture));
                self.set_logo_shown(true);
            }
            None => self.set_logo_shown(false),
        }
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

    /// What the pictures bar offers beside Download Pictures: its menu's items, and the dimmed note in it
    #[cfg(feature = "e2e")]
    pub fn pictures_choices(&self) -> (Vec<String>, String) {
        let mut items = Vec::new();
        if let Some(menu) = self
            .pictures_always
            .menu_model()
            .filter(|_| self.pictures_always.is_visible())
        {
            for at in 0..menu.n_items() {
                let label = menu.item_attribute_value(at, "label", Some(glib::VariantTy::STRING));
                items.extend(label.and_then(|l| l.get::<String>()));
            }
        }
        let note = self
            .pictures_always
            .popover()
            .filter(|_| self.pictures_always.is_visible())
            .and_then(|popover| {
                labels_in(popover.upcast_ref()).find(|l| l.widget_name() == "reader-pictures-unconfirmed")
            })
            .map(|l| l.text().to_string());
        (items, note.unwrap_or_default())
    }

    /// The texts of the pictures bar itself (its menu not included)
    #[cfg(feature = "e2e")]
    pub fn pictures_bar_texts(&self) -> Vec<String> {
        labels_in(self.pictures.upcast_ref())
            .filter(|l| l.is_visible())
            .map(|l| l.text().to_string())
            .collect()
    }

    /// The pictures bar's menu opened, or closed (the UI test's picture of it)
    #[cfg(feature = "e2e")]
    pub fn open_pictures_menu(&self, open: bool) {
        if open {
            self.pictures_always.popup();
        } else {
            self.pictures_always.popdown();
        }
    }

    pub fn hide_logo(&self) {
        self.set_logo_shown(false);
        self.set_round(false);
    }

    /// The picture beside the header shown or not, with the frame that sizes and rounds it
    fn set_logo_shown(&self, shown: bool) {
        self.logo.set_visible(shown);
        if let Some(frame) = self.logo.parent() {
            frame.set_visible(shown);
        }
    }

    /// The picture beside the header round (a contact's) or square (a brand's logo)
    fn set_round(&self, round: bool) {
        if let Some(frame) = self.logo.parent() {
            if round {
                frame.add_css_class("reader-contact");
            } else {
                frame.remove_css_class("reader-contact");
            }
        }
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

impl Reader {
    // ---- the files, the calendar and unsubscribing ----

    /// The attachment `index` of the message shown, its name and bytes, from the message file shown or from the
    /// folder's message; None when it could not be read
    fn attachment(&self, index: usize) -> Option<(String, Vec<u8>)> {
        let core = &shell().core;
        match self.file.borrow().as_deref() {
            Some(path) => core.file_attachment(path, index),
            None => core.attachment(self.folder.get(), self.uid.get(), index),
        }
        .ok()
        .flatten()
    }

    /// Every attachment of the message shown saved into `dir`: how many of how many, None when it could not be read
    fn save_attachments_to(&self, dir: &std::path::Path) -> Option<(usize, usize)> {
        let core = &shell().core;
        match self.file.borrow().as_deref() {
            Some(path) => core.file_save_attachments(path, dir).ok(),
            None => core
                .save_attachments(self.folder.get(), self.uid.get(), dir)
                .ok()
                .flatten(),
        }
    }

    async fn save_attachment(&self, index: usize) {
        let Some(window) = self.window() else { return };
        let Some((name, data)) = self.attachment(index) else {
            // a large message shows its text before the rest of it is here
            let downloading =
                self.file.borrow().is_none() && shell().core.message_downloading(self.folder.get(), self.uid.get());
            let why = if downloading {
                t!(UiAttachmentDownloading)
            } else {
                t!(UiAttachmentNotRead)
            };
            ui::alert(&window, TITLE, &why).await;
            return;
        };
        let Some(path) = ui::save_file(&window, &t!(UiSaveAttachmentAs), &name, None).await else {
            return;
        };
        if std::fs::write(&path, data).is_err() {
            ui::alert(&window, TITLE, &t!(UiAttachmentNotSaved)).await;
        }
    }

    /// Every file of the message into a folder; the core saves them all from one reading of the message, a file
    /// already there kept and the new one numbered
    async fn save_all_attachments(&self) {
        let Some(window) = self.window() else { return };
        let Some(dir) = ui::choose_folder(&window, &t!(UiSaveAttachments)).await else {
            return;
        };
        match self.save_attachments_to(&dir) {
            Some((saved, total)) if saved < total => {
                let text = t!(GtkFilesNotSaved, failed = total - saved, total = total);
                ui::alert(&window, TITLE, &text).await;
            }
            Some(_) => {}
            _ => ui::alert(&window, TITLE, &t!(UiNotDownloaded)).await,
        }
    }

    /// The calendar part as a file of its own (the core writes it, and only it, from the message file shown or the
    /// folder's message), for the calendar program
    async fn open_in_calendar(&self) {
        let Some(window) = self.window() else { return };
        let dir = glib::tmp_dir().join("InboxClassic").join("Invitations");
        let core = &shell().core;
        let written = match self.file.borrow().as_deref() {
            Some(file) => core.file_invitation_file(file, &dir),
            None => core.invitation_file(self.folder.get(), self.uid.get(), &dir),
        };
        let Ok(Some(path)) = written else {
            ui::alert(&window, TITLE, &t!(UiInvitationNotRead)).await;
            return;
        };
        let launcher = gtk::FileLauncher::new(Some(&gio::File::for_path(&path)));
        if launcher.launch_future(Some(&window)).await.is_err() {
            ui::alert(&window, TITLE, &t!(UiNoCalendar)).await;
        }
    }

    /// The Unsubscribe link of the message shown, after asking; what is done is said in the main window's status bar
    async fn unsubscribe(&self) {
        use pe_core::unsubscribe::Unsubscribe;
        let Some(window) = self.window() else { return };
        let Some(how) = self.view.borrow().as_ref().and_then(|v| v.unsubscribe.clone()) else {
            return;
        };
        let target = how.target();
        let (cancel, okay) = (t!(UiCancel), t!(UiOk));
        let ok = [("cancel", cancel.as_str()), ("ok", okay.as_str())];
        let title = t!(UiUnsubscribe);
        match how {
            Unsubscribe::OneClick { .. } => {
                let question = t!(GtkUnsubscribeOneClick, target = &*target);
                if !ui::confirm(&window, &title, &question, false).await {
                    return;
                }
                let request = shell().core.unsubscribe(self.folder.get(), self.uid.get()).unwrap_or(0);
                self.unsubscribe_request.set(request);
                shell().main().set_status(&if request != 0 {
                    t!(UiUnsubscribing, target = &*target)
                } else {
                    t!(UiCannotUnsubscribe)
                });
            }
            Unsubscribe::Mail { link } => {
                let question = t!(GtkUnsubscribeMail, target = &*target);
                if ui::ask(&window, &title, &question, &ok, "ok", "cancel", None).await == "ok" {
                    shell().open_mailto(&link).await;
                }
            }
            Unsubscribe::Web { url } => {
                let question = t!(GtkUnsubscribeWeb, target = &*target);
                if ui::ask(&window, &title, &question, &ok, "ok", "cancel", None).await == "ok" {
                    ui::open_externally(&url, Some(&window));
                }
            }
        }
    }

    /// The one-click unsubscribe `request` done, or not for `problem`: what the status bar says, empty for another
    pub fn unsubscribed(&self, request: u64, problem: Option<&str>) -> String {
        if request == 0 || request != self.unsubscribe_request.get() {
            return String::new();
        }
        self.unsubscribe_request.set(0);
        match problem {
            None => t!(UiUnsubscribed),
            Some(problem) => t!(GtkUnsubscribeFailed, problem = problem),
        }
    }
}

/// Every label under `root`
#[cfg(feature = "e2e")]
fn labels_in(root: &gtk::Widget) -> impl Iterator<Item = gtk::Label> {
    let mut found = Vec::new();
    let mut stack = vec![root.clone()];
    while let Some(widget) = stack.pop() {
        let mut child = widget.first_child();
        while let Some(c) = child {
            child = c.next_sibling();
            stack.push(c);
        }
        found.extend(widget.downcast::<gtk::Label>().ok());
    }
    found.into_iter()
}

/// A label that wraps: the whole sentence on more lines in a narrow window, not cut off
fn wrapping(text: &str) -> gtk::Label {
    let label = gtk::Label::new(Some(text));
    label.set_xalign(0.0);
    label.set_wrap(true);
    label.set_wrap_mode(gtk::pango::WrapMode::WordChar);
    label
}

/// The dimmed item of the pictures menu for a sender the provider did not confirm: why there is no Always
fn unconfirmed_note(text: &str) -> gtk::Label {
    let note = wrapping(text);
    note.set_widget_name("reader-pictures-unconfirmed");
    note.set_max_width_chars(40);
    note.set_sensitive(false);
    note.set_margin_top(6);
    note.set_margin_bottom(6);
    note.set_margin_start(12);
    note.set_margin_end(12);
    note
}

/// The bar over a message whose pictures on the internet are blocked: what it says, Download Pictures and beside it
/// its menu (Always, or why not)
fn pictures_bar() -> (gtk::Box, gtk::Button, gtk::MenuButton) {
    let text = wrapping(&t!(GtkPicturesBlocked));
    text.set_hexpand(true);
    text.set_valign(gtk::Align::Center);
    let download = gtk::Button::with_label(&t!(GtkDownloadPictures));
    download.set_widget_name("reader-download-pictures");
    let always = gtk::MenuButton::builder()
        .icon_name("pan-down-symbolic")
        .tooltip_text(t!(GtkDownloadPictures))
        .build();
    always.set_widget_name("reader-pictures-always");
    always.set_visible(false);
    // Download Pictures and its arrow as one button
    let buttons = gtk::Box::new(gtk::Orientation::Horizontal, 0);
    buttons.add_css_class("linked");
    buttons.set_valign(gtk::Align::Center);
    buttons.append(&download);
    buttons.append(&always);
    let bar = gtk::Box::new(gtk::Orientation::Horizontal, 10);
    bar.add_css_class("info-bar");
    bar.set_widget_name("reader-pictures");
    bar.append(&gtk::Image::from_icon_name("ic-image-symbolic"));
    bar.append(&text);
    bar.append(&buttons);
    bar.set_visible(false);
    (bar, download, always)
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

/// The days and times of the event cards of the core, as the windows write dates: the long date or the time of day, in
/// the reader's time zone, or as written (UTC) when floating
pub fn set_instant_format() {
    pe_core::calendar::set_instant_format(|seconds, floating, part| {
        let Some(time) = event_time(seconds, floating) else {
            return String::new();
        };
        match part {
            pe_core::calendar::InstantPart::Date => long_date(&time),
            pe_core::calendar::InstantPart::Time => time_of_day(&time),
        }
    });
}

glib::wrapper! {
    /// Text of the header that can be selected with the mouse (and copied), but that Tab and the arrow keys pass by:
    /// a selectable label is focusable, and Tab into it would select all of it on the way from the list to the message
    pub struct PassedByTab(ObjectSubclass<passed_by_tab::PassedByTab>)
        @extends gtk::Widget,
        @implements gtk::Accessible, gtk::Buildable, gtk::ConstraintTarget;
}

impl PassedByTab {
    fn new(child: &impl IsA<gtk::Widget>) -> PassedByTab {
        let this: PassedByTab = glib::Object::new();
        child.set_parent(&this);
        this
    }
}

mod passed_by_tab {
    use gtk::glib;
    use gtk::prelude::*;
    use gtk::subclass::prelude::*;

    #[derive(Default)]
    pub struct PassedByTab;

    #[glib::object_subclass]
    impl ObjectSubclass for PassedByTab {
        const NAME: &'static str = "InboxClassicPassedByTab";
        type Type = super::PassedByTab;
        type ParentType = gtk::Widget;

        fn class_init(class: &mut Self::Class) {
            class.set_layout_manager_type::<gtk::BinLayout>();
        }
    }

    impl ObjectImpl for PassedByTab {
        fn dispose(&self) {
            while let Some(child) = self.obj().first_child() {
                child.unparent();
            }
        }
    }

    impl WidgetImpl for PassedByTab {
        // the keys move on past it; a click still gives the text the focus (Ctrl+C copies what is selected)
        fn focus(&self, _direction: gtk::DirectionType) -> bool {
            false
        }
    }
}
