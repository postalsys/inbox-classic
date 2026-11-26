//! The reading pane: the header of the message while it is coming (the paper clip with the files at its right), the strip of its files under it (`attachments.rs`), the security bar of a signed or encrypted message, the bar that says pictures from the
//! internet are blocked, and the message itself (with the
//! cards of the core above it: a calendar event, a bounce, a one-time code), the sanitized document of the core in a locked down web view. The main window has one
//! under its list, and each message window one of its own: the reader keeps the message it shows, asks the core for
//! it, follows the core's events about it and answers its own buttons (the files, the pictures, Try Again, the
//! calendar, Unsubscribe) in the window it is in.

use adw::prelude::*;
use gtk::{gio, glib};
use pe_core::keys::ImportError;
use pe_core::{Event, MessageRef, MessageView};
use std::cell::{Cell, RefCell};
use std::rc::Rc;
use webkit::prelude::*;

use crate::app::{shell, spawn};
use crate::attachments::Strip;
use crate::security::SecurityBar;
use crate::stack::{Ask, Click, Stack};
use crate::ui::{self, TITLE};
use crate::webview::{DocumentView, no_message};

/// The size the logo of a brand, or a contact's picture, is drawn at
const LOGO_SIZE: i32 = 48;

/// Who is told what a frame asks ([`Reader::on_frame_ask`])
type FrameAsks = RefCell<Option<Rc<dyn Fn(FrameAsk)>>>;

/// What a frame of the stack asks of the window the reader is in, on one message
pub enum FrameAsk {
    MarkUnread(MessageRef),
    Delete(MessageRef),
    Edit(MessageRef),
    OpenWindow(MessageRef),
}

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
    subject: gtk::Label,
    /// The fields (From, To, Date) and the Reactions row under them
    fields: gtk::Box,
    from: gtk::Label,
    date: gtk::Label,
    to: gtk::Label,
    /// "Reactions:" and its chips, one a person, under the fields while the message has reactions
    reactions_row: gtk::Box,
    reactions: gtk::FlowBox,
    /// The chips shown, for their menus
    chips: RefCell<Vec<pe_core::reactions::ReactionChip>>,
    /// Why the message is not shown
    note: gtk::Label,
    /// The paper clip with the files of the message
    pub attachments: gtk::MenuButton,
    attachments_label: gtk::Label,
    /// The strip of the files under the header: double-click or Enter opens one
    pub strip: Rc<Strip>,
    /// The security bar of a signed or encrypted message, under the header
    pub security: SecurityBar,
    /// The bar that says pictures from the internet are blocked; its button shows them, its menu beside it trusts
    /// the sender, or its second line says why it cannot
    pictures: gtk::Box,
    pub download_pictures: gtk::Button,
    pictures_always: gtk::MenuButton,
    /// The bar over a message that could not be downloaded; its button tries again
    retry: gtk::Box,
    pub try_again: gtk::Button,
    /// The bar over a message of a mailing list: the core's words (the list's domain, or when it was asked) and its
    /// button, which leaves the list as Message > Unsubscribe from List does
    list_bar: gtk::Box,
    list_text: gtk::Label,
    pub list_button: gtk::Button,
    /// Told whether the bar offers its button, for the window's Unsubscribe from List
    list_offered: RefCell<Option<Offered>>,
    /// The pane's own page while no message is shown: none selected, several, downloading, why it is not there
    pub pane: DocumentView,
    /// The message shown, or its whole conversation: a native stack of rows and frames ([`Stack`])
    pub stack: Rc<Stack>,
    /// What a frame asks of the window around the reader: Mark as Unread or Delete of its message, a draft to finish,
    /// the message in a window of its own, set by the main window and a message window
    frame_asks: FrameAsks,
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
    /// A file of the strip is being opened: one at a time
    opening: Cell<bool>,
    /// Its view once the core built it, with its pictures from the internet when `remote_images` (its stack's entries
    /// handed to the stack)
    view: RefCell<Option<Rc<MessageView>>>,
    /// The view shown was made of the message's text while the rest of it was still coming: the message's arrival
    /// makes it again
    text_first: Cell<bool>,
    /// The message is opened in its conversation (Show the whole conversation): its view is the conversation's
    conversation: Cell<bool>,
    /// A line of the conversation shown took the focus: its message, once downloaded, is shown in place
    refocus: Cell<bool>,
    remote_images: Cell<bool>,
    /// The sender of the message whose pictures the bar offers: the selected one's, or another open message's
    pictures_sender: RefCell<Option<pe_core::pictures::Sender>>,
    /// The view and the logo being made for it, and the one-click unsubscribe on the way; 0 for none
    view_request: Cell<u64>,
    logo_request: Cell<u64>,
    /// Without a logo, the sender's picture from the Address Book being drawn; 0 for none
    picture_request: Cell<u64>,
    unsubscribe_request: Cell<u64>,
    /// Find Key on a part's label being looked up; 0 for none
    find_request: Cell<u64>,
    /// The printout of a message with previews being made, and the window it prints over; 0 for none
    print_request: Cell<u64>,
    print_window: RefCell<Option<gtk::Window>>,
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

/// The Reactions row of the header: its label as wide as those of From and To (`labels`), and the box of its chips.
/// A row of its own under the grid of the fields, not a row of it: a grid measures a child that wraps at its narrowest
/// and leaves a gap under the chips
fn reactions_row(labels: &gtk::SizeGroup) -> (gtk::Box, gtk::FlowBox) {
    let label = field_label(&t!(UiReactionsLabel));
    labels.add_widget(&label);
    // its words on the line of the first chips' words, which sit a little lower in their pills
    label.set_margin_top(2);
    // the chips on more lines when the pane is too narrow for them, rather than widening it
    let chips = gtk::FlowBox::new();
    chips.set_selection_mode(gtk::SelectionMode::None);
    chips.set_column_spacing(6);
    chips.set_row_spacing(4);
    chips.set_max_children_per_line(64);
    chips.set_hexpand(true);
    chips.set_valign(gtk::Align::Start);
    chips.add_css_class("reaction-chips");
    chips.set_widget_name("reader-reactions");
    chips.update_relation(&[gtk::accessible::Relation::LabelledBy(&[label.upcast_ref()])]);
    let row = gtk::Box::new(gtk::Orientation::Horizontal, FIELD_SPACING);
    row.set_margin_top(2);
    row.append(&label);
    row.append(&chips);
    row.set_visible(false);
    (row, chips)
}

/// The room between a field's label and its value
const FIELD_SPACING: i32 = 8;

/// The widest a reaction chip's words are drawn, in pixels
const CHIP_WIDTH: i32 = 240;

/// A person's reactions: a chip with their emoji and name whose menu (a click, a right-click, the Menu key or
/// Shift+F10) opens the reaction's email, shows the reactions as emails again, and says when they reacted
fn reaction_chip(index: usize, chip: &pe_core::reactions::ReactionChip) -> gtk::MenuButton {
    let label = gtk::Label::new(Some(&chip.text));
    label.set_ellipsize(gtk::pango::EllipsizeMode::End);
    // as wide as its words up to CHIP_WIDTH, a longer name cut short; its smallest and natural widths the same, so the
    // row's chips wrap the same way whichever GTK measures (a label that could shrink leaves a gap under them)
    label.set_max_width_chars(1);
    let (width, _) = label.create_pango_layout(Some(&chip.text)).pixel_size();
    label.set_size_request((width + 1).min(CHIP_WIDTH), -1);
    let button = gtk::MenuButton::new();
    button.set_child(Some(&label));
    button.add_css_class("reaction-chip");
    button.set_widget_name(&format!("reader-reaction-{index}"));
    button.set_tooltip_text(Some(&chip.text));
    let when = t!(UiReactionWhen, when = chip.when.as_str());
    button.update_property(&[
        gtk::accessible::Property::Label(&chip.text),
        gtk::accessible::Property::Description(&when),
    ]);
    let index = index as u32;
    let actions = gio::Menu::new();
    actions.append(
        Some(&t!(UiReactionOpenEmail)),
        Some(&gio::Action::print_detailed_name(
            "reader.reaction-open",
            Some(&index.to_variant()),
        )),
    );
    actions.append(
        Some(&t!(UiReactionShowAsEmail)),
        Some(&gio::Action::print_detailed_name(
            "reader.reaction-show",
            Some(&index.to_variant()),
        )),
    );
    let menu = gio::Menu::new();
    menu.append_section(None, &actions);
    let said = gio::Menu::new();
    said.append(Some(&when), Some("reader.reaction-when"));
    menu.append_section(None, &said);
    button.set_menu_model(Some(&menu));
    // the context menu's own ways: a right-click, the Menu key and Shift+F10, as on the list's rows
    let click = gtk::GestureClick::new();
    click.set_button(gtk::gdk::BUTTON_SECONDARY);
    click.connect_pressed(|gesture, _, _, _| {
        gesture.set_state(gtk::EventSequenceState::Claimed);
        if let Some(button) = gesture.widget().and_downcast::<gtk::MenuButton>() {
            button.popup();
        }
    });
    button.add_controller(click);
    let keys = gtk::ShortcutController::new();
    let popup = gtk::CallbackAction::new(|widget, _| {
        if let Some(button) = widget.downcast_ref::<gtk::MenuButton>() {
            button.popup();
        }
        glib::Propagation::Stop
    });
    keys.add_shortcut(gtk::Shortcut::new(
        gtk::ShortcutTrigger::parse_string("Menu|<Shift>F10"),
        Some(popup),
    ));
    button.add_controller(keys);
    button
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
        let grid = gtk::Grid::new();
        grid.set_column_spacing(FIELD_SPACING as u32);
        grid.set_row_spacing(2);
        let labels = gtk::SizeGroup::new(gtk::SizeGroupMode::Horizontal);
        for (row, (name, value)) in [
            (t!(UiFieldFrom), &from),
            (t!(UiFieldTo), &to),
            (t!(GtkReaderDate), &date),
        ]
        .into_iter()
        .enumerate()
        {
            let label = field_label(&name);
            labels.add_widget(&label);
            grid.attach(&label, 0, row as i32, 1, 1);
            grid.attach(&PassedByTab::new(value), 1, row as i32, 1, 1);
        }
        // the label column always as wide as "Reactions:", so From, To and Date stay where they are whether a message
        // has reactions or not: a label nobody sees, in the cell of Date's (a hidden one would not count)
        let room = gtk::Label::builder()
            .label(t!(UiReactionsLabel))
            .accessible_role(gtk::AccessibleRole::Presentation)
            .opacity(0.0)
            .can_target(false)
            .build();
        room.add_css_class("field");
        grid.attach(&room, 0, 2, 1, 1);
        let (reactions_row, reactions) = reactions_row(&labels);
        let fields = gtk::Box::new(gtk::Orientation::Vertical, 2);
        fields.append(&grid);
        fields.append(&reactions_row);
        let note = gtk::Label::new(None);
        note.set_xalign(0.0);
        note.set_widget_name("reader-note");
        let top = gtk::Box::new(gtk::Orientation::Horizontal, 8);
        top.append(&PassedByTab::new(&subject));
        let text = gtk::Box::new(gtk::Orientation::Vertical, 6);
        text.set_hexpand(true);
        text.append(&top);
        text.append(&fields);
        text.append(&note);
        let attachments_label = gtk::Label::new(Some("1 file"));
        let clip = gtk::Box::new(gtk::Orientation::Horizontal, 6);
        clip.append(&crate::icons::image("ic-attach-symbolic"));
        clip.append(&attachments_label);
        let attachments = gtk::MenuButton::new();
        attachments.set_child(Some(&clip));
        attachments.set_valign(gtk::Align::Center);
        attachments.set_tooltip_text(Some(&t!(GtkReaderFiles)));
        attachments.set_widget_name("reader-attachments");
        attachments.set_visible(false);
        let header = gtk::Box::new(gtk::Orientation::Horizontal, 12);
        header.add_css_class("reader-header");
        header.append(&text);
        header.append(&attachments);

        let strip = Strip::new();
        let security = SecurityBar::new("reader");
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
        retry.append(&crate::icons::image("ic-arrow-sync-symbolic"));
        retry.append(&note_retry);
        retry.append(&try_again);
        retry.set_visible(false);

        let list_text = gtk::Label::new(None);
        list_text.set_xalign(0.0);
        list_text.set_hexpand(true);
        list_text.set_wrap(true);
        list_text.set_wrap_mode(gtk::pango::WrapMode::WordChar);
        list_text.set_widget_name("reader-list-text");
        let list_button = gtk::Button::with_label(&t!(UiUnsubscribeAsk));
        list_button.set_widget_name("reader-list-button");
        list_button.set_valign(gtk::Align::Center);
        let list_bar = gtk::Box::new(gtk::Orientation::Horizontal, 10);
        list_bar.add_css_class("info-bar");
        list_bar.set_widget_name("reader-list");
        list_bar.append(&crate::icons::image("ic-mail-multiple-symbolic"));
        list_bar.append(&list_text);
        list_bar.append(&list_button);
        list_bar.set_visible(false);

        let preview = DocumentView::new("preview", false);
        preview.view.set_widget_name("reader-pane");
        let stack = Stack::new();
        stack.widget.set_visible(false);
        let (find_bar, find_entry) = find_bar();
        let widget = gtk::Box::new(gtk::Orientation::Vertical, 0);
        widget.append(&header);
        widget.append(&strip.widget);
        widget.append(&security.widget);
        // the bars in one order: the download that failed, the pictures, the mailing list
        widget.append(&retry);
        widget.append(&pictures);
        widget.append(&list_bar);
        widget.append(&find_bar);
        widget.append(&preview.view);
        widget.append(&stack.widget);
        let reader = Reader {
            widget,
            header,
            subject,
            fields,
            from,
            date,
            to,
            reactions_row,
            reactions,
            chips: RefCell::default(),
            note,
            attachments,
            attachments_label,
            strip,
            security,
            pictures,
            download_pictures,
            pictures_always,
            retry,
            try_again,
            list_bar,
            list_text,
            list_button,
            list_offered: RefCell::default(),
            pane: preview,
            stack,
            frame_asks: RefCell::default(),
            find_bar,
            find_entry,
            #[cfg(feature = "e2e")]
            found: Rc::default(),
            downloading: Rc::default(),
            summary: RefCell::default(),
            account: Cell::new(0),
            opening: Cell::new(false),
            folder: Cell::new(0),
            uid: Cell::new(0),
            size: Cell::default(),
            file: RefCell::default(),
            view: RefCell::default(),
            text_first: Cell::new(false),
            conversation: Cell::new(false),
            refocus: Cell::new(false),
            remote_images: Cell::new(false),
            pictures_sender: RefCell::default(),
            view_request: Cell::new(0),
            logo_request: Cell::new(0),
            picture_request: Cell::new(0),
            unsubscribe_request: Cell::new(0),
            find_request: Cell::new(0),
            print_request: Cell::new(0),
            print_window: RefCell::default(),
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
        let details = on(|this| this.show_details());
        self.security.details.connect_clicked(move |_| details());
        let calendar = on(|this| {
            let this = this.clone();
            spawn(async move { this.open_in_calendar().await });
        });
        let leave = on(|this| {
            let this = this.clone();
            spawn(async move { this.unsubscribe().await });
        });
        self.list_button.connect_clicked(move |_| leave());
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
        // a part's label of a signed or encrypted message: its Details, and nothing else
        let part = on(|this| {
            // after the view's signal, as a dialog opened inside it would be
            let this = Rc::downgrade(this);
            glib::idle_add_local_once(move || {
                if let Some(this) = this.upgrade() {
                    this.show_details();
                }
            });
        });
        // a picture or PDF page after the text: its file opened as a double-click in the strip opens it, when the core
        // says it is of the view this reader shows (its token)
        let this = Rc::downgrade(self);
        let preview = move |uri: &str| {
            let Some(this) = this.upgrade() else {
                return;
            };
            let token = this.view.borrow().as_ref().and_then(|v| v.preview_token.clone());
            let Some(index) = token.and_then(|token| shell().core.preview_link(uri, &token)) else {
                return;
            };
            spawn(async move { this.open_attachment(index).await });
        };
        // Find Key beside the label of a part signed by a key not known here: the core reads the fingerprint from the
        // link and looks it up; nothing is opened
        let this = Rc::downgrade(self);
        let find_key = move |link: &str| {
            if let Some(this) = this.upgrade() {
                this.find_key(link);
            }
        };
        let links = Rc::new(move |uri: &str| {
            if pe_html::find_key_link(uri).is_some() {
                find_key(uri);
                return true;
            }
            if pe_html::is_preview_link(uri) {
                preview(uri);
                return true;
            }
            if pe_html::part_link(uri).is_some() {
                part();
                return true;
            }
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
        let pane = links.clone();
        self.pane.set_links(move |uri| pane(uri));
        self.stack.set_links(move |uri| links(uri));
        self.connect_stack();
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
        let open = gio::SimpleAction::new("open-attachment", Some(glib::VariantTy::UINT32));
        let this = Rc::downgrade(self);
        open.connect_activate(move |_, index| {
            if let (Some(this), Some(index)) = (this.upgrade(), index.and_then(|i| i.get::<u32>())) {
                spawn(async move { this.open_attachment(index as usize).await });
            }
        });
        let import = gio::SimpleAction::new("import-key", Some(glib::VariantTy::UINT32));
        let this = Rc::downgrade(self);
        import.connect_activate(move |_, index| {
            if let (Some(this), Some(index)) = (this.upgrade(), index.and_then(|i| i.get::<u32>())) {
                spawn(async move { this.import_key(index as usize).await });
            }
        });
        group.add_action(&import);
        self.add_reaction_actions(&group);
        // the greyed Open of a file that can run programs
        let refused = gio::SimpleAction::new("open-refused", Some(glib::VariantTy::UINT32));
        refused.set_enabled(false);
        group.add_action(&save);
        group.add_action(&all);
        group.add_action(&open);
        group.add_action(&refused);
        let this = Rc::downgrade(self);
        self.strip.connect_show_in_message(move |index, state| {
            if let Some(this) = this.upgrade() {
                this.show_in_message(index, state);
            }
        });
        let this = Rc::downgrade(self);
        self.strip.connect_open(move |index| {
            if let Some(this) = this.upgrade() {
                spawn(async move { this.open_attachment(index).await });
            }
        });
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
    fn connect_find(self: &Rc<Self>) {
        self.connect_found(&self.pane.view);
        let this = Rc::downgrade(self);
        let finder = move || this.upgrade().and_then(|this| this.shown_view().find_controller());
        #[cfg(feature = "e2e")]
        let found = self.found.clone();
        let find = finder.clone();
        self.find_entry.connect_search_changed(move |entry| {
            #[cfg(feature = "e2e")]
            found.set(None);
            let Some(finder) = find() else { return };
            let text = entry.text();
            if text.is_empty() {
                entry.remove_css_class("error");
                finder.search_finish();
                return;
            }
            let options = webkit::FindOptions::CASE_INSENSITIVE | webkit::FindOptions::WRAP_AROUND;
            finder.search(&text, options.bits(), u32::MAX);
        });
        let find = finder.clone();
        self.find_entry.connect_activate(move |_| {
            if let Some(finder) = find() {
                finder.search_next();
            }
        });
        let find = finder.clone();
        self.find_entry.connect_next_match(move |_| {
            if let Some(finder) = find() {
                finder.search_next();
            }
        });
        let find = finder.clone();
        self.find_entry.connect_previous_match(move |_| {
            if let Some(finder) = find() {
                finder.search_previous();
            }
        });
        self.find_bar.connect_search_mode_enabled_notify(move |bar| {
            if !bar.is_search_mode()
                && let Some(finder) = finder()
            {
                finder.search_finish();
            }
        });
    }

    /// The find box says whether the words are in the message shown in `view`
    fn connect_found(&self, view: &webkit::WebView) {
        let Some(controller) = view.find_controller() else {
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
    }

    /// The document view of the message shown: the selected frame's body, or the pane's own page
    pub fn preview(&self) -> DocumentView {
        if self.stack.widget.is_visible()
            && let Some(body) = self.stack.selected_body()
        {
            return body;
        }
        self.pane.clone()
    }

    /// Whether the message shown has its body made: the selected frame's in the stack (or the pane's own page)
    #[cfg(feature = "e2e")]
    pub fn body_made(&self) -> bool {
        !self.stack.widget.is_visible() || self.stack.selected_body().is_some()
    }

    /// The web view of the message shown: the selected frame's, or the pane's own page
    pub fn shown_view(&self) -> webkit::WebView {
        self.preview().view
    }

    /// The pane's own page in place of the stack, whose frames are let go
    fn show_pane(&self) {
        self.stack.clear();
        self.stack.widget.set_visible(false);
        self.pane.view.set_visible(true);
    }

    /// The window around the reader is told what a frame asks of it ([`FrameAsk`])
    pub fn on_frame_ask(&self, asks: impl Fn(FrameAsk) + 'static) {
        *self.frame_asks.borrow_mut() = Some(Rc::new(asks));
    }

    /// What a click in the stack asks: the core's choice of the message selected, a command on a frame's message, its
    /// More menu
    fn connect_stack(self: &Rc<Self>) {
        let this = Rc::downgrade(self);
        self.stack.connect(move |asked| {
            let Some(this) = this.upgrade() else { return };
            // after the click's own signal: the stack is built again
            glib::idle_add_local_once(move || this.stack_asked(asked));
        });
        let this = Rc::downgrade(self);
        self.stack.on_body(move |view| {
            if let Some(this) = this.upgrade() {
                this.connect_found(view);
            }
        });
    }

    /// The window around the reader told what a frame asks
    fn tell(&self, what: FrameAsk) {
        let asks = self.frame_asks.borrow().clone();
        if let Some(asks) = asks {
            asks(what);
        }
    }

    fn stack_asked(self: &Rc<Self>, asked: Ask) {
        // a message alone is the reader's own message
        let own = |at: MessageRef| if at.uid == 0 { self.message() } else { Some(at) };
        match asked {
            Ask::Click(click, index) => self.conversation_click(click, index),
            Ask::Command(command, at) => {
                self.select(at);
                let _ = self.widget.activate_action(&format!("win.{}", command.name()), None);
            }
            Ask::More(at, button) => {
                let Some(at) = own(at) else { return };
                self.select(at);
                self.more_menu(at, &button);
            }
            Ask::Edit(at) => {
                if let Some(at) = own(at) {
                    self.tell(FrameAsk::Edit(at));
                }
            }
            Ask::OpenWindow(at) => {
                if let Some(at) = own(at) {
                    self.tell(FrameAsk::OpenWindow(at));
                }
            }
        }
    }

    /// The message `at` of the conversation shown made the selected one at once, as Reply or a frame's menu acts on
    /// the reader's message; its accent follows when the view is built again
    fn select(&self, at: MessageRef) {
        let Some(current) = self.message() else { return };
        if at == current || at.uid == 0 {
            return;
        }
        if let Some(index) = self.stack.index_of(at) {
            self.conversation_click(Click::Select, index);
        }
    }

    /// A frame's More menu: what else can be done with that one message, never with the conversation's row in the
    /// list
    fn more_menu(self: &Rc<Self>, at: MessageRef, button: &gtk::Widget) {
        let menu = gtk::gio::Menu::new();
        let section = gtk::gio::Menu::new();
        section.append(
            Some(&crate::words::plain(crate::words::Text::CmdPrint)),
            Some("win.print"),
        );
        menu.append_section(None, &section);
        let section = gtk::gio::Menu::new();
        section.append(
            Some(&crate::words::plain(crate::words::Text::CmdMarkUnread)),
            Some("frame.mark-unread"),
        );
        section.append(Some(&t!(UiTbDelete)), Some("frame.delete"));
        menu.append_section(None, &section);
        let section = gtk::gio::Menu::new();
        section.append(Some(&t!(UiMenuOpen)), Some("frame.open-window"));
        section.append(
            Some(&crate::words::plain(crate::words::Text::UiMenuViewSource)),
            Some("win.view-source"),
        );
        menu.append_section(None, &section);
        let actions = gio::SimpleActionGroup::new();
        for (name, what) in [
            ("mark-unread", FrameAsk::MarkUnread as fn(MessageRef) -> FrameAsk),
            ("delete", FrameAsk::Delete),
            ("open-window", FrameAsk::OpenWindow),
        ] {
            let action = gio::SimpleAction::new(name, None);
            let this = Rc::downgrade(self);
            action.connect_activate(move |_, _| {
                if let Some(this) = this.upgrade() {
                    this.tell(what(at));
                }
            });
            actions.add_action(&action);
        }
        let popover = gtk::PopoverMenu::from_model(Some(&menu));
        popover.insert_action_group("frame", Some(&actions));
        popover.set_parent(button);
        popover.connect_closed(|popover| {
            let popover = popover.clone();
            glib::idle_add_local_once(move || popover.unparent());
        });
        popover.popup();
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

    /// Whether the message `uid` of `folder` is what the pane shows, and its page has loaded: the message itself, or
    /// why it is not there (it could not be downloaded or shown), not the moment between (the UI test)
    #[cfg(feature = "e2e")]
    pub fn shows(&self, folder: i64, uid: u64) -> bool {
        self.folder.get() == folder
            && self.uid.get() == uid
            && self.view_request.get() == 0
            && (self.has_view() || self.shows_failure() || self.note.is_visible())
            && self.pane.loaded()
    }

    /// Whether the message is on screen, not only asked for
    pub fn has_view(&self) -> bool {
        self.view.borrow().is_some()
    }

    /// The subject of the message on screen
    pub fn subject(&self) -> Option<String> {
        self.view.borrow().as_ref().map(|v| v.subject.clone())
    }

    /// Security Details of the signed or encrypted message on screen
    pub fn show_details(&self) {
        if let Some(view) = self.view.borrow().as_ref() {
            crate::security::details_dialog(&self.widget, view);
        }
    }

    /// The one-time code of the card on screen, when there is one
    pub fn otp_code(&self) -> Option<String> {
        self.view.borrow().as_ref().and_then(|v| v.otp_code.clone())
    }

    /// The code card's Copy: the code on the clipboard, said in the status bar
    pub fn copy_code(&self) {
        let Some(code) = self.otp_code() else { return };
        self.pane.view.clipboard().set_text(&code);
        shell().main().set_status(&t!(UiCodeCopied));
    }

    /// The message the bounce on screen returns, when it is in the account
    pub fn bounced_message(&self) -> Option<MessageRef> {
        self.view.borrow().as_ref().and_then(|v| v.bounced_message)
    }

    /// Whether the next message opened ([`Reader::open`]) is shown in its conversation (a row of its own or a collapsed
    /// conversation's, with Show the whole conversation on) or alone
    pub fn set_conversation(&self, on: bool) {
        self.conversation.set(on);
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
            // another window may have asked for the same message: a view shown whole stays, as the core makes only
            // the newest view asked for, and one made here at the same time would leave the other window without its
            Event::MessageReady { folder, uid }
                if shown(*folder, *uid) && (!self.has_view() || self.text_first.get() || self.refocus.get()) =>
            {
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
            // an open message of the conversation shown is downloaded: the conversation built again, where it was
            Event::MessageReady { folder, uid } if self.waits_for(*folder, *uid) => {
                self.view_again();
                None
            }
            // a view for a message no longer shown was cancelled, its event is not this one
            Event::ViewReady { request } if self.view_request.get() != 0 && *request == self.view_request.get() => {
                self.show_view().then_some(Loaded::Shown)
            }
            // the files still "Preparing..." in the view shown are described: the view built again, where it was
            Event::PreviewsPrepared { token } if self.shows_previews(token) => {
                self.view_again();
                None
            }
            // the account is back: a message it could not give is tried again
            Event::SyncFinished { account, failure: None }
                if *account == self.account.get() && self.uid.get() != 0 && self.shows_failure() =>
            {
                self.retry();
                None
            }
            // a reaction came for the message shown, or was shown as an email
            Event::FolderChanged { folder, .. } if *folder == self.folder.get() && self.file.borrow().is_none() => {
                self.show_reactions();
                None
            }
            Event::LogoReady { request } if self.logo_request.get() != 0 && *request == self.logo_request.get() => {
                self.logo_request.set(0);
                self.show_picture(shell().core.logo_result(*request));
                None
            }
            Event::PrintReady { request } if self.print_request.get() != 0 && *request == self.print_request.get() => {
                self.print_ready(*request);
                None
            }
            Event::KeysFound { request, .. } if self.find_request.get() != 0 && *request == self.find_request.get() => {
                self.keys_found(*request);
                None
            }
            Event::PictureReady { request }
                if self.picture_request.get() != 0 && *request == self.picture_request.get() =>
            {
                self.picture_request.set(0);
                self.show_picture(shell().core.picture_result(*request));
                None
            }
            _ => None,
        }
    }

    /// Whether the view shown is the one whose previews `token` names
    fn shows_previews(&self, token: &str) -> bool {
        self.view.borrow().as_ref().and_then(|v| v.preview_token.as_deref()) == Some(token)
    }

    /// Whether the conversation shown waits for the message `uid` of `folder`, an open one still downloading
    fn waits_for(&self, folder: i64, uid: u64) -> bool {
        let at = MessageRef { folder, uid };
        self.view
            .borrow()
            .as_ref()
            .and_then(|v| v.conversation.as_ref())
            .is_some_and(|c| c.waiting.contains(&at))
    }

    /// A click in the conversation shown (a row, a frame, an arrow, the folded middle, of the message at `index`) or
    /// Next, Previous, Open All and Fold All (`index` not used): the core says which message is selected now, and the
    /// conversation is shown again where it was, the frames of the same messages kept (downloaded first when it is
    /// not here yet)
    pub fn conversation_click(&self, click: Click, index: usize) {
        let Some(current) = self.message() else { return };
        let core = &shell().core;
        let at = match click {
            Click::Select => core.conversation_select(current, index),
            Click::Toggle => core.conversation_toggle(current, index),
            Click::ShowMiddle => {
                core.conversation_show_middle(current);
                Some(current)
            }
            Click::FoldAll => core.conversation_open_all(current, false),
            Click::OpenAll => core.conversation_open_all(current, true),
            Click::Next => core.conversation_step(current, 1),
            Click::Previous => core.conversation_step(current, -1),
        };
        self.go_to(current, at);
    }

    /// The conversation shown at `at`, the message the core says is selected now
    fn go_to(&self, current: MessageRef, at: Option<MessageRef>) {
        let Some(at) = at else {
            return;
        };
        if at == current {
            self.view_again();
            return;
        }
        self.folder.set(at.folder);
        self.uid.set(at.uid);
        // the pictures asked for are another message's: never carried to this one (a signed or encrypted message loads its own only on a click of its own)
        self.remote_images.set(false);
        self.refocus.set(true);
        let _ = shell().core.open_message(at.folder, at.uid);
    }

    /// Whether the view shown is a conversation's
    pub fn shows_conversation(&self) -> bool {
        self.view.borrow().as_ref().is_some_and(|v| v.conversation.is_some())
    }

    /// The view of the message asked for, built on a worker, alone or in its conversation; [`Reader::show_view`]
    /// shows it when it comes
    fn start_view(&self) {
        let core = &shell().core;
        if self.view_request.get() != 0 {
            core.message_view_cancel(self.view_request.get());
        }
        self.refocus.set(false);
        let request = match self.conversation.get() {
            true => core.conversation_view_start(
                MessageRef {
                    folder: self.folder.get(),
                    uid: self.uid.get(),
                },
                self.remote_images.get(),
                crate::mailbox::newest_first(),
            ),
            false => core.message_view_start(self.folder.get(), self.uid.get(), self.remote_images.get()),
        }
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
        let (has_logo, picture) = (view.has_logo, view.picture);
        self.show(view, self.remote_images.get());
        self.text_first
            .set(core.message_downloading(self.folder.get(), self.uid.get()));
        if has_logo {
            let request = core
                .logo_start(self.folder.get(), self.uid.get(), LOGO_SIZE as u32)
                .unwrap_or(0);
            self.logo_request.set(request);
        } else if picture != 0 {
            // the sender's picture from the Address Book, where a brand's logo would be
            let request = core.picture_start(picture, LOGO_SIZE as u32).unwrap_or(0);
            self.picture_request.set(request);
        }
        true
    }

    /// Download Pictures: the message again, with its pictures from the internet
    pub fn load_pictures(&self) {
        if self.shows_message() && self.has_view() && !self.remote_images.get() {
            self.remote_images.set(true);
            self.view_again();
        }
    }

    /// The page shown made again, for what Preferences changed in how messages look (dark messages): the message's
    /// view built again, or the empty page. The page over several messages is made again when it is shown next
    pub fn reload(&self) {
        if self.shows_message() {
            if self.has_view() {
                self.view_again();
            }
        } else if self.summary.borrow().is_none() {
            self.pane.show(&no_message(!self.header.is_visible()), false);
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
        self.show(view, self.remote_images.get());
    }

    /// The pictures bar's Always: the sender's address, or with `domain` everyone at their domain, trusted; the
    /// message again, its pictures now loading by themselves
    async fn trust_sender(&self, domain: bool) {
        let sender = self.pictures_sender.borrow().clone();
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

    /// The message as it is shown, with the pictures the user allowed, through the print dialog over `window`. A
    /// signed or encrypted message prints the core's document of it (a printer prints no frames): every part's text,
    /// with the bar's words and the parts' labels in its header. A message with pictures or PDF files prints the
    /// document the core makes on a worker ([`Event::PrintReady`]): its pictures in it, a line for each other file;
    /// the window shows it is busy meanwhile (the core waits for the pictures 30 seconds at most)
    pub fn print(&self, window: &impl IsA<gtk::Window>) {
        if !self.shows_message() || !self.has_view() || self.print_request.get() != 0 {
            return;
        }
        let token = self.view.borrow().as_ref().and_then(|v| v.preview_token.clone());
        if let Some(request) = token.and_then(|token| shell().core.print_start(&token)) {
            let window = window.as_ref().clone();
            window.set_cursor_from_name(Some("progress"));
            self.print_request.set(request);
            self.print_window.replace(Some(window));
            return;
        }
        let printed = self.view.borrow().as_ref().and_then(|v| v.print_document.clone());
        let Some(document) = printed else {
            print_dialog(&self.shown_view(), window.as_ref());
            return;
        };
        print_document(&document, self.pictures_shown(), window.as_ref().clone());
    }

    /// File > Print Conversation: every message of the conversation shown, one after another
    pub fn print_conversation(&self, window: &impl IsA<gtk::Window>) {
        let Some(current) = self.message() else { return };
        if self.print_request.get() != 0 {
            return;
        }
        // made off the window thread, PrintReady says it is; in no conversation, the message alone, as Print does
        let Some(request) = shell()
            .core
            .conversation_print_start(current, crate::mailbox::newest_first())
        else {
            self.print(window);
            return;
        };
        let window = window.as_ref().clone();
        window.set_cursor_from_name(Some("progress"));
        self.print_request.set(request);
        self.print_window.replace(Some(window));
    }

    /// Whether the message's pictures from the internet are shown: asked for, or by themselves
    fn pictures_shown(&self) -> bool {
        self.remote_images.get() || self.view.borrow().as_ref().is_some_and(|v| v.pictures_loaded)
    }

    /// The printout of the message with its previews made: printed over the window it was asked in
    fn print_ready(&self, request: u64) {
        self.print_request.set(0);
        let Some(window) = self.print_window.take() else { return };
        window.set_cursor(None);
        if let Some(document) = shell().core.print_result(request) {
            print_document(&document, self.pictures_shown(), window);
        }
    }

    /// The printout being made no longer wanted (another message, or none): the window not busy
    fn stop_printing(&self) {
        self.print_request.set(0);
        if let Some(window) = self.print_window.take() {
            window.set_cursor(None);
        }
    }

    /// Show in Message chosen for file `index`, whose item said `state`: drawn in the message, or taken out of it; the
    /// message shown again where it was
    fn show_in_message(&self, index: usize, state: pe_core::previews::ShowInMessage) {
        let token = self.view.borrow().as_ref().and_then(|v| v.preview_token.clone());
        let Some(token) = token else { return };
        let show = state != pe_core::previews::ShowInMessage::On;
        if shell().core.preview_show(&token, index, show) {
            self.view_again();
        }
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
        self.stop_printing();
        // what was looked for is not in the next message
        self.find_bar.set_search_mode(false);
        self.summary.borrow_mut().take();
        if !loading {
            self.hide_attachments();
            self.security.hide();
            self.pictures.set_visible(false);
            self.set_list_bar(None);
        }
        self.retry.set_visible(false);
        self.stop_downloading_note();
        self.subject.set_text("");
        self.fields.set_visible(false);
        self.show_reactions();
        self.note.set_visible(false);
        self.header.set_visible(loading);
        // a message about to be shown takes the place of the one before in the stack, its web view kept for it
        if !loading || !self.stack.widget.is_visible() {
            self.show_pane();
            self.pane.show(&no_message(!loading), false);
        }
    }

    /// Several messages selected: how many, and how many of them are unread or flagged, as the page of no message
    /// says there is none. The page stays when it would say the same.
    pub fn summary(&self, summary: &pe_core::Summary) {
        let words = (summary.title(), summary.detail());
        if self.summary.borrow().as_ref() == Some(&words) {
            return;
        }
        self.header.set_visible(false);
        self.show_pane();
        self.pane.show(&summary.page(), false);
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
        self.show_reactions();
        self.stop_downloading_note();
        let (preview, retry, timer) = (self.pane.clone(), self.retry.clone(), self.downloading.clone());
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
        self.show_pane();
        show_downloading(&self.pane, &self.retry, self.size.get());
    }

    /// The message could not be downloaded: why, in the pane, and Try Again over it
    pub fn not_downloaded(&self, kind: pe_core::FailureKind, reason: &str) {
        self.stop_downloading_note();
        self.hide_attachments();
        self.security.hide();
        self.pictures.set_visible(false);
        self.retry.set_visible(true);
        self.header.set_visible(true);
        self.show_pane();
        self.pane.show(
            &pe_core::reader_page(pe_core::ReaderState::Failed { kind, reason }),
            false,
        );
    }

    pub fn shows_failure(&self) -> bool {
        self.retry.is_visible()
    }

    /// Whether it says the message could not be shown (the UI test)
    #[cfg(feature = "e2e")]
    pub fn says_not_shown(&self) -> bool {
        self.note.is_visible() && self.note.text() == t!(UiNotShown)
    }

    pub fn failed(&self) {
        self.stop_downloading_note();
        self.header.set_visible(true);
        self.fields.set_visible(false);
        self.subject.set_text("");
        self.note.set_text(&t!(UiNotShown));
        self.note.set_visible(true);
        self.hide_attachments();
        self.security.hide();
        self.pictures.set_visible(false);
    }

    /// The message: its header, the bars it needs, its document (with its pictures from the internet when
    /// `remote_images`); kept as the view on screen, its stack's entries handed to the stack
    fn show(&self, mut view: MessageView, remote_images: bool) {
        let entries = pe_core::conversation::take_entries(&mut view);
        // the frame says who and when: no header block over the stack
        self.header.set_visible(false);
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
        self.show_reactions();
        self.set_list_bar(view.list_bar.as_ref());
        self.show_attachments(&view);
        self.security.show(&view);
        self.show_pictures_bar(&view, &entries);
        // the same message or conversation again (a click in it, Show in Message, its pictures): where it was
        let view = Rc::new(view);
        let again = self.view.replace(Some(view.clone())).is_some();
        self.pane.view.set_visible(false);
        self.stack.widget.set_visible(true);
        // pictures from the internet shown when asked for, or by themselves (a trusted sender, or every message's)
        self.stack.show(
            &view,
            entries,
            remote_images || view.pictures_loaded,
            (
                self.reactions_row.upcast_ref(),
                self.strip.widget.upcast_ref(),
                self.attachments.upcast_ref(),
            ),
            !again,
        );
    }

    /// The Reactions row of the message shown (of a folder, not a file): a chip a person, the row hidden when there
    /// are none
    fn show_reactions(&self) {
        let chips = match (self.uid.get(), self.file.borrow().is_some()) {
            (0, _) | (_, true) => Vec::new(),
            (uid, false) => shell().core.reactions_of(self.folder.get(), uid).unwrap_or_default(),
        };
        if *self.chips.borrow() == chips {
            return;
        }
        self.reactions.remove_all();
        for (index, chip) in chips.iter().enumerate() {
            self.reactions.append(&reaction_chip(index, chip));
            // the chip takes the focus, not the box around it
            if let Some(child) = self.reactions.child_at_index(index as i32) {
                child.set_focusable(false);
            }
        }
        self.reactions_row.set_visible(!chips.is_empty());
        *self.chips.borrow_mut() = chips;
    }

    /// The chip of the Reactions row at `index`, if it is still there
    fn chip(&self, index: u32) -> Option<pe_core::reactions::ReactionChip> {
        self.chips.borrow().get(index as usize).cloned()
    }

    /// The actions of a reaction chip's menu, on the chip's number: Open Reaction Email, Show as Email, and the
    /// dimmed line of when (an action that is never on)
    fn add_reaction_actions(self: &Rc<Self>, group: &gio::SimpleActionGroup) {
        let open = gio::SimpleAction::new("reaction-open", Some(glib::VariantTy::UINT32));
        let this = Rc::downgrade(self);
        open.connect_activate(move |_, index| {
            let (Some(this), Some(index)) = (this.upgrade(), index.and_then(|i| i.get::<u32>())) else {
                return;
            };
            let newest = this.chip(index).and_then(|chip| chip.newest());
            let file = newest.and_then(|at| shell().core.reaction_email_file(at).ok().flatten());
            if let Some(path) = file {
                spawn(async move { crate::message_window::open_file(&path).await });
            }
        });
        let show = gio::SimpleAction::new("reaction-show", Some(glib::VariantTy::UINT32));
        let this = Rc::downgrade(self);
        show.connect_activate(move |_, index| {
            let (Some(this), Some(index)) = (this.upgrade(), index.and_then(|i| i.get::<u32>())) else {
                return;
            };
            let Some(chip) = this.chip(index) else {
                return;
            };
            if !chip.emails.is_empty() {
                let _ = shell().core.show_reactions_as_email(&chip.emails);
                this.show_reactions();
            }
        });
        let when = gio::SimpleAction::new("reaction-when", None);
        when.set_enabled(false);
        group.add_action(&open);
        group.add_action(&show);
        group.add_action(&when);
    }

    /// The chips of the Reactions row, their words (the UI test)
    #[cfg(feature = "e2e")]
    pub fn reaction_chips(&self) -> Vec<gtk::MenuButton> {
        let mut chips = Vec::new();
        if !self.reactions_row.is_visible() {
            return chips;
        }
        let mut child = self.reactions.first_child();
        while let Some(at) = child {
            if let Some(chip) = at.first_child().and_downcast::<gtk::MenuButton>() {
                chips.push(chip);
            }
            child = at.next_sibling();
        }
        chips
    }

    /// The pictures bar, offered only for a message with pictures on the internet, until they are shown. With a
    /// sender, Download Pictures has its menu: Always for a sender the provider confirmed, otherwise a dimmed item
    /// that says why not (the core's words), as the Windows app does
    fn show_pictures_bar(&self, view: &MessageView, entries: &[pe_core::conversation::Entry]) {
        // the selected message's pictures, else another open one's that is neither signed nor encrypted (theirs load
        // on a click of their own)
        let blocked = |v: &MessageView| v.remote_images && !v.pictures_loaded;
        let others = entries.iter().filter_map(|e| e.view.as_deref());
        let offered = std::iter::once(view)
            .filter(|v| blocked(v))
            .chain(others.filter(|v| blocked(v) && v.protection.is_none()))
            .next();
        self.pictures.set_visible(offered.is_some());
        *self.pictures_sender.borrow_mut() = offered.and_then(|v| v.sender.clone());
        let words = offered
            .and_then(|v| v.sender.as_ref())
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

    /// The paper clip and the strip gone, for a message without files or none shown
    fn hide_attachments(&self) {
        self.attachments.set_visible(false);
        self.strip.hide();
        self.header.remove_css_class("with-files");
    }

    /// The strip of the files under the header, and the paper clip: how many files, a menu item to save each (the
    /// name the sender gave, its size), then all of them into a folder
    fn show_attachments(&self, view: &MessageView) {
        let count = view.attachments.len();
        let parts = view
            .protection
            .as_ref()
            .map_or(&[][..], |protection| &protection.parts[..]);
        self.strip.show(&view.attachments, parts);
        ui::set_class(&self.header, "with-files", count > 0);
        self.attachments.set_visible(count > 0);
        if count == 0 {
            return;
        }
        self.attachments_label.set_text(&t!(GtkFiles, count = count));
        let files = gio::Menu::new();
        for (index, file) in view.attachments.iter().enumerate() {
            let label = format!("{} ({})", file.filename, file.size_text);
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

    /// The selected frame's picture (the brand's logo, the contact's picture), once the core drew it: [`LOGO_SIZE`]
    /// pixels square, BGRA with the alpha multiplied in
    fn show_picture(&self, pixels: Option<Vec<u8>>) {
        if let Some(texture) = pixels.and_then(|pixels| crate::ui::bgra_texture(pixels, LOGO_SIZE)) {
            self.stack.set_selected_picture(texture.upcast_ref());
        }
    }

    /// Whether the selected frame shows the picture drawn for its message
    #[cfg(feature = "e2e")]
    pub fn logo_shown(&self) -> bool {
        self.stack.widget.is_visible() && self.stack.selected_picture_drawn()
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
    /// folder's message (read off the window thread); None when it could not be read or the window closed first
    async fn attachment_read(&self, index: usize) -> Option<(String, Vec<u8>)> {
        let core = &shell().core;
        if let Some(path) = self.file.borrow().as_deref() {
            return core.file_attachment(path, index).ok().flatten();
        }
        let window = self.window()?;
        let request = core.attachment_start(self.folder.get(), self.uid.get(), index).ok()?;
        if !ui::wait_read(&window, request).await {
            return None;
        }
        core.attachment_result(request).map(|(name, _, data)| (name, data))
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

    /// Why an attachment of the message shown could not be read: a large message shows its text before the rest of
    /// it is here
    fn not_read(&self) -> String {
        let downloading =
            self.file.borrow().is_none() && shell().core.message_downloading(self.folder.get(), self.uid.get());
        if downloading {
            t!(UiAttachmentDownloading)
        } else {
            t!(UiAttachmentNotRead)
        }
    }

    async fn save_attachment(&self, index: usize) {
        let Some(window) = self.window() else { return };
        let Some((name, data)) = self.attachment_read(index).await else {
            ui::alert(&window, TITLE, &self.not_read()).await;
            return;
        };
        let Some(path) = ui::save_file(&window, &t!(UiSaveAttachmentAs), &name, None).await else {
            return;
        };
        if std::fs::write(&path, data).is_err() {
            ui::alert(&window, TITLE, &t!(UiAttachmentNotSaved)).await;
        }
    }

    /// Attachment `index` opened with the system's program for it: a file that can run programs refused from its row,
    /// in the core's words; any other written by the core into a private folder of the user's on a thread of its own
    /// (a large or encrypted message takes a while: its item dims after `LIST_LOADING_MS`), the note it gives shown first
    async fn open_attachment(&self, index: usize) {
        let Some(window) = self.window() else { return };
        let Some(file) = self.strip.file(index) else { return };
        if let Some(refusal) = &file.refusal {
            return ui::alert(&window, TITLE, refusal).await;
        }
        if self.opening.replace(true) {
            return;
        }
        let done = Rc::new(Cell::new(false));
        let strip = self.strip.clone();
        let waited = done.clone();
        let busy_after = std::time::Duration::from_millis(pe_core::LIST_LOADING_MS.into());
        glib::timeout_add_local_once(busy_after, move || {
            if !waited.get() {
                strip.busy(Some(index));
            }
        });
        let core = shell().core.clone();
        let path = self.file.borrow().clone();
        let (folder, uid) = (self.folder.get(), self.uid.get());
        let opened = match path {
            Some(path) => gio::spawn_blocking(move || core.file_open_attachment(&path, index))
                .await
                .unwrap_or(Ok(None)),
            // a folder's message: written off the window thread by the core, the window closing drops it
            None => match core.open_attachment_start(folder, uid, index) {
                Ok(request) if ui::wait_read(&window, request).await => core.open_attachment_result(request),
                // the window closed first
                Ok(_) => {
                    done.set(true);
                    self.opening.set(false);
                    return;
                }
                Err(error) => Err(error),
            },
        };
        done.set(true);
        self.strip.busy(None);
        self.opening.set(false);
        let opened = match opened {
            Ok(Some(opened)) => opened,
            Err(refused) => return ui::alert(&window, TITLE, &refused.to_string()).await,
            _ => return ui::alert(&window, TITLE, &self.not_read()).await,
        };
        if let Some(note) = &opened.note {
            ui::alert(&window, &t!(UiAttachmentNoteTitle), note).await;
        }
        if let Err(why) = crate::attachments::launch(&opened.path, &window).await {
            ui::alert(&window, TITLE, &why).await;
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
        let core = &shell().core;
        let Ok(dir) = core.private_folder("invitation") else {
            ui::alert(&window, TITLE, &t!(UiInvitationNotRead)).await;
            return;
        };
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

    /// The mailing-list bar as the core words it; none hides it
    fn set_list_bar(&self, bar: Option<&pe_core::list_bar::ListBar>) {
        self.list_bar.set_visible(bar.is_some());
        if let Some(bar) = bar {
            self.list_text.set_text(&bar.text);
            self.list_button.set_label(&bar.button);
            self.list_button.set_visible(!bar.button.is_empty());
        }
        if let Some(told) = self.list_offered.borrow().as_ref() {
            told(self.can_unsubscribe());
        }
    }

    /// `told` hears whether the bar offers its button, for the window's Unsubscribe from List
    pub fn on_list_offered(&self, told: impl Fn(bool) + 'static) {
        *self.list_offered.borrow_mut() = Some(Box::new(told));
    }

    /// Whether the mailing-list bar is shown (the UI test)
    #[cfg(feature = "e2e")]
    pub fn list_bar_shown(&self) -> bool {
        self.list_bar.is_visible()
    }

    /// The mailing-list bar's words and its button's, empty when it has none (the UI test)
    #[cfg(feature = "e2e")]
    pub fn list_bar_words(&self) -> (String, String) {
        let button = if self.list_button.is_visible() {
            self.list_button.label().map(|l| l.to_string()).unwrap_or_default()
        } else {
            String::new()
        };
        (self.list_text.text().to_string(), button)
    }

    /// Whether the pictures bar is shown (the UI test)
    #[cfg(feature = "e2e")]
    pub fn pictures_bar_shown(&self) -> bool {
        self.pictures.is_visible()
    }

    /// The pictures bar comes before the mailing-list bar in the pane (the UI test)
    #[cfg(feature = "e2e")]
    pub fn bars_in_order(&self) -> bool {
        let mut child = self.widget.first_child();
        while let Some(widget) = child {
            if widget == self.pictures {
                return true;
            }
            if widget == self.list_bar {
                return false;
            }
            child = widget.next_sibling();
        }
        false
    }

    /// The bar offers its button: Message > Unsubscribe from List is on
    pub fn can_unsubscribe(&self) -> bool {
        self.list_bar.is_visible() && self.list_button.is_visible()
    }

    /// The core's ListsChanged: a list was asked to let the user go, or a request failed, so the bar is read again
    pub fn lists_changed(&self) {
        let has_list = self.view.borrow().as_ref().is_some_and(|view| view.list.how.is_some());
        if self.file.borrow().is_some() || self.uid.get() == 0 || !has_list {
            return;
        }
        let bar = shell().core.list_bar(self.folder.get(), self.uid.get()).ok().flatten();
        self.set_list_bar(bar.as_ref());
    }

    /// The bar's button and Message > Unsubscribe from List: what will happen, asked with the verb, then done; the core
    /// remembers the list for the bars (a message to write once it is sent, a page once it is opened). What is done is
    /// said in the main window's status bar.
    pub async fn unsubscribe(&self) {
        use pe_core::unsubscribe::Unsubscribe;
        let Some(window) = self.window() else { return };
        if !self.can_unsubscribe() {
            return;
        }
        let Some(how) = self.view.borrow().as_ref().and_then(|v| v.list.how.clone()) else {
            return;
        };
        let target = how.target();
        let question = match &how {
            Unsubscribe::OneClick { .. } => t!(GtkUnsubscribeOneClick, target = &*target),
            Unsubscribe::Mail { .. } => t!(GtkUnsubscribeMail, target = &*target),
            Unsubscribe::Web { .. } => t!(GtkUnsubscribeWeb, target = &*target),
        };
        let (cancel, leave) = (t!(UiCancel), t!(UiUnsubscribe));
        let answers = [("cancel", cancel.as_str()), ("unsubscribe", leave.as_str())];
        let title = t!(UiUnsubscribe);
        if ui::ask(&window, &title, &question, &answers, "unsubscribe", "cancel", None).await != "unsubscribe" {
            return;
        }
        let (folder, uid) = (self.folder.get(), self.uid.get());
        match how {
            Unsubscribe::OneClick { .. } => {
                let request = shell().core.unsubscribe(folder, uid).unwrap_or(0);
                self.unsubscribe_request.set(request);
                shell().main().set_status(&if request != 0 {
                    t!(UiUnsubscribing, target = &*target)
                } else {
                    t!(UiCannotUnsubscribe)
                });
            }
            // from the account of the message, whatever the main window shows
            Unsubscribe::Mail { .. } => match shell().core.unsubscribe_draft(folder, uid) {
                Ok(draft) => crate::compose::open(self.account.get(), Some(draft)),
                Err(_) => shell().main().set_status(&t!(UiCannotUnsubscribe)),
            },
            Unsubscribe::Web { url } => {
                ui::open_externally(&url, Some(&window));
                let _ = shell().core.unsubscribe_opened(folder, uid);
            }
        }
    }

    /// Find Key on a part's label: the key the link names looked up on keys.openpgp.org, said in the status bar
    fn find_key(&self, link: &str) {
        match shell().core.pgp_find_handle(link) {
            Ok(request) => {
                self.find_request.set(request);
                self.say(&t!(PgpRecipientLooking));
            }
            Err(error) => self.say(&error.to_string()),
        }
    }

    /// Find Key's lookup ended (the core learned what it found): what it found said, and the message shown again, its
    /// label then naming who signed it
    fn keys_found(&self, request: u64) {
        self.find_request.set(0);
        let outcome = shell().core.pgp_find_result(request);
        if let Some(outcome) = outcome {
            self.say(&outcome.text);
        }
        if self.shows_message() && self.has_view() {
            self.view_again();
        }
    }

    /// Import Key on a key attached to the message shown: the core reads (and decrypts) it from the message (the file
    /// shown, or the folder's message) off the window thread and takes its public keys; what it did said, and the
    /// message shown again for a signature by it
    async fn import_key(&self, index: usize) {
        let Some(window) = self.window() else { return };
        let core = shell().core.clone();
        let path = self.file.borrow().clone();
        let (folder, uid) = (self.folder.get(), self.uid.get());
        let outcome = gio::spawn_blocking(move || core.pgp_import_attachment(path.as_deref(), folder, uid, index))
            .await
            .unwrap_or_else(|_| Err(ImportError::Invalid(t!(UiUnknownReason))));
        let imported = outcome.is_ok();
        crate::keys::imported_attachment(&window, outcome).await;
        if imported && self.shows_message() && self.has_view() {
            self.view_again();
        }
    }

    /// Words for the user about the message shown: the main window's status bar, or a message window's toast
    fn say(&self, text: &str) {
        if text.is_empty() {
            return;
        }
        match self
            .widget
            .ancestor(adw::ToastOverlay::static_type())
            .and_downcast::<adw::ToastOverlay>()
        {
            Some(toasts) => toasts.add_toast(adw::Toast::builder().title(text).use_markup(false).build()),
            None => shell().main().set_status(text),
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

/// What hears whether the mailing-list bar offers its button
type Offered = Box<dyn Fn(bool)>;

thread_local! {
    /// The web view of a document being printed, kept until its print dialog is done
    static PRINTING: RefCell<Option<DocumentView>> = const { RefCell::new(None) };
}

/// WebKit draws a picture on paper only when no decode of it is under way on its decoding threads: while one is, it
/// draws nothing there and the picture prints as an empty box. The print view's own paint (it is never shown) starts
/// such a decode for a picture it does not count as visible. Every picture of the page is made decoding="sync" as the
/// parser puts it in, before anything is painted, so no paint starts one: the app's own script, in a world of its own
/// (the page runs none), at the start of the document. The same fix as the Mac's (WebViews.swift `syncPictures`)
const SYNC_PICTURES: &str = "new MutationObserver(changes => { for (const change of changes) for (const node of \
    change.addedNodes) { if (node.nodeType !== 1) continue; if (node.localName === 'img') node.decoding = 'sync'; \
    for (const img of node.getElementsByTagName('img')) img.decoding = 'sync' } })\
    .observe(document, { childList: true, subtree: true })";

/// The world of the app's own scripts in the print view, apart from the page's
const PRINT_WORLD: &str = "inbox-classic-print";

/// `document` printed from a web view of its own, locked down as the reading pane's (none of the page's scripts, the
/// app's own [`SYNC_PICTURES`] in a world of its own), once it has loaded
fn print_document(document: &str, pictures: bool, window: gtk::Window) {
    let view = DocumentView::new("print", false);
    view.manager().add_script(&webkit::UserScript::for_world(
        SYNC_PICTURES,
        webkit::UserContentInjectedFrames::AllFrames,
        webkit::UserScriptInjectionTime::Start,
        PRINT_WORLD,
        &[],
        &[],
    ));
    let started = Cell::new(false);
    view.view.connect_load_changed(move |_, event| {
        if event != webkit::LoadEvent::Finished || started.replace(true) {
            return;
        }
        let window = window.clone();
        // after WebKit's signal: the dialog runs a loop of its own
        glib::idle_add_local_once(move || {
            if let Some(printing) = PRINTING.with(|p| p.borrow().clone()) {
                print_dialog(&printing.view, &window);
                printing.release();
            }
            PRINTING.with(|p| p.borrow_mut().take());
        });
    });
    view.show(document, pictures);
    if let Some(before) = PRINTING.with(|p| p.borrow_mut().replace(view)) {
        before.release();
    }
}

/// The document being printed (the UI test reads it); None when nothing is
#[cfg(feature = "e2e")]
pub fn printing() -> Option<String> {
    PRINTING.with(|p| p.borrow().as_ref().map(|view| view.shown()))
}

/// The web view of the document being printed, as it prints it (the UI test reads its pictures); None when nothing is
#[cfg(feature = "e2e")]
pub fn printing_view() -> Option<webkit::WebView> {
    PRINTING.with(|p| p.borrow().as_ref().map(|view| view.view.clone()))
}

/// The page of `view` through the print dialog over `window`
fn print_dialog(view: &webkit::WebView, window: &gtk::Window) {
    let operation = webkit::PrintOperation::new(view);
    // WebKit destroys its print dialog when run_dialog returns, holding no reference of its own; closed with its
    // close button or Escape, GTK has destroyed it already and it may be freed. Held here until then
    let toplevels = gtk::Window::toplevels();
    let held: Rc<RefCell<Vec<gtk::PrintUnixDialog>>> = Rc::default();
    let kept = held.clone();
    let added = toplevels.connect_items_changed(move |list, position, _, count| {
        let dialogs = (position..position + count).filter_map(|i| list.item(i).and_downcast::<gtk::PrintUnixDialog>());
        kept.borrow_mut().extend(dialogs);
    });
    operation.run_dialog(Some(window));
    toplevels.disconnect(added);
    drop(held);
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
    let text = wrapping(&t!(UiPicturesBlocked));
    text.set_hexpand(true);
    text.set_valign(gtk::Align::Center);
    // the words of View > Download Pictures, as on Windows and the Mac
    let download = gtk::Button::with_label(crate::commands::Command::Pictures.label());
    download.set_widget_name("reader-download-pictures");
    let always = crate::icons::kept(
        gtk::MenuButton::builder()
            .icon_name("pan-down-symbolic")
            .tooltip_text(crate::commands::Command::Pictures.label())
            .build(),
    );
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
    bar.append(&crate::icons::image("ic-image-symbolic"));
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
