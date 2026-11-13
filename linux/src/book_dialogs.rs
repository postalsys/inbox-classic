//! Contact Properties and Group Properties of the Address Book: the forms of a person (names, e-mail addresses with
//! the default first, phone numbers by kind, notes) and of a group (its name and members from the book or typed). The
//! core keeps and checks what they hand it (`pe_core::book`); a card is saved from the one read, so what a vCard
//! brought that the form does not show stays.

use std::cell::{Cell, RefCell};
use std::path::PathBuf;
use std::rc::Rc;

use adw::prelude::*;
use gtk::{gdk, gio, glib};
use pe_store::{Card, CardId, Group, GroupId, Member};

use crate::app::shell;
use crate::ui::{self, TITLE};
use crate::words::{self, Text};
use pe_core::book::{add_members, display_name, is_mailbox};

/// The kinds of phone numbers as the core names them, in the order of the list
const PHONE_KINDS: [&str; 4] = ["home", "work", "cell", ""];

fn phone_kind_names() -> Vec<String> {
    vec![t!(UiPhoneHome), t!(UiPhoneWork), t!(UiPhoneMobile), t!(UiPhoneOther)]
}

fn entry_row(text: Text, value: &str, name: &str) -> adw::EntryRow {
    let row = adw::EntryRow::builder()
        .title(words::field_title(text))
        .text(value)
        .build();
    row.set_widget_name(name);
    row
}

/// A small flat icon button of a row
fn row_button(icon: &str, tooltip: &str, name: &str) -> gtk::Button {
    let button = ui::icon_button(icon, tooltip);
    button.add_css_class("flat");
    button.set_valign(gtk::Align::Center);
    button.set_widget_name(name);
    button
}

/// The "+" button of a row or a group's header that adds what was typed (or a row)
fn add_button(name: &str) -> gtk::Button {
    let button = row_button("list-add-symbolic", &words::field_title(Text::UiContactAdd), name);
    button.set_valign(gtk::Align::Center);
    button
}

/// What a click on "+" or Enter did wrong said over the dialog
fn say_later(dialog: &glib::WeakRef<adw::Dialog>, why: String) {
    if let Some(dialog) = dialog.upgrade() {
        glib::spawn_future_local(async move { ui::alert(&dialog, TITLE, &why).await });
    }
}

/// The page of a properties dialog: its groups one under the other, scrolled when they do not fit
fn page(groups: &[&adw::PreferencesGroup]) -> gtk::ScrolledWindow {
    let content = gtk::Box::new(gtk::Orientation::Vertical, 18);
    content.set_margin_start(18);
    content.set_margin_end(18);
    content.set_margin_top(6);
    content.set_margin_bottom(18);
    for group in groups {
        content.append(*group);
    }
    gtk::ScrolledWindow::builder()
        .child(&content)
        .hscrollbar_policy(gtk::PolicyType::Never)
        .propagate_natural_height(true)
        .vexpand(true)
        .build()
}

/// The dialog of `content` with Cancel and OK, presented; the answers come down the channel: true for OK, false once
/// it closed
fn present(
    parent: &impl IsA<gtk::Widget>,
    title: &str,
    content: &gtk::ScrolledWindow,
    name: &str,
    height: i32,
) -> (adw::Dialog, async_channel::Receiver<bool>) {
    let (dialog, ok) = ui::dialog_with_buttons(title, content, &t!(UiOk), 540);
    dialog.set_content_height(height);
    dialog.set_widget_name(name);
    let clicks = ui::answers(&dialog, &ok);
    dialog.present(Some(parent.as_ref()));
    (dialog, clicks)
}

// ---- Contact Properties ----

/// The e-mail addresses of the form, the default first, each a row with Set as Default and Remove; the row to type a
/// new one last
struct Addresses {
    group: adw::PreferencesGroup,
    rows: RefCell<Vec<adw::ActionRow>>,
    new: adw::EntryRow,
    list: RefCell<Vec<String>>,
}

impl Addresses {
    fn fill(self: &Rc<Self>) {
        for row in self.rows.borrow_mut().drain(..) {
            self.group.remove(&row);
        }
        if self.new.parent().is_some() {
            self.group.remove(&self.new);
        }
        let list = self.list.borrow().clone();
        for (index, address) in list.iter().enumerate() {
            let title = if index == 0 {
                t!(UiContactDefault, address = address)
            } else {
                address.clone()
            };
            let row = adw::ActionRow::builder().title(&title).use_markup(false).build();
            row.set_widget_name(&format!("contact-address-{index}"));
            if index == 0 {
                // the same place and size as the others' Set as Default, not a button to click
                let star = row_button("starred-symbolic", &title, "contact-default-0");
                star.set_can_target(false);
                star.set_can_focus(false);
                star.add_css_class("accent");
                row.add_prefix(&star);
            } else {
                let star = row_button(
                    "non-starred-symbolic",
                    &words::field_title(Text::UiContactSetDefault),
                    &format!("contact-default-{index}"),
                );
                let this = Rc::downgrade(self);
                star.connect_clicked(move |_| {
                    if let Some(this) = this.upgrade() {
                        let address = this.list.borrow_mut().remove(index);
                        this.list.borrow_mut().insert(0, address);
                        this.fill();
                        this.focus_row(0);
                    }
                });
                row.add_prefix(&star);
            }
            let remove = row_button(
                "ic-dismiss-symbolic",
                &words::field_title(Text::UiRemove),
                &format!("contact-remove-{index}"),
            );
            let this = Rc::downgrade(self);
            remove.connect_clicked(move |_| {
                if let Some(this) = this.upgrade() {
                    this.list.borrow_mut().remove(index);
                    this.fill();
                    this.focus_row(index);
                }
            });
            row.add_suffix(&remove);
            self.group.add(&row);
            self.rows.borrow_mut().push(row);
        }
        self.group.add(&self.new);
    }

    /// The focus, which was on a button of a row taken away, to the row now at `index` (the one before at the end, the
    /// new address row when none is left)
    fn focus_row(&self, index: usize) {
        let rows = self.rows.borrow();
        match rows.get(index).or(rows.last()) {
            Some(row) => row.grab_focus(),
            None => self.new.grab_focus(),
        };
    }

    /// The address typed in the last row into the list: Ok(false) for nothing typed, Err with the words for one that
    /// is not an address
    fn take_typed(self: &Rc<Self>) -> Result<bool, String> {
        let typed = self.new.text().trim().to_string();
        if typed.is_empty() {
            return Ok(false);
        }
        if !is_mailbox(&typed) {
            return Err(t!(UiContactAddressInvalid, address = &typed));
        }
        let known = self.list.borrow().iter().any(|a| a.eq_ignore_ascii_case(&typed));
        if !known {
            self.list.borrow_mut().push(typed);
        }
        self.new.set_text("");
        self.fill();
        Ok(true)
    }
}

/// The phone numbers of the form: a row for each with its kind and Remove
struct Phones {
    group: adw::PreferencesGroup,
    rows: RefCell<Vec<(adw::EntryRow, gtk::DropDown)>>,
}

impl Phones {
    fn add(self: &Rc<Self>, kind: &str, number: &str) -> adw::EntryRow {
        let index = self.rows.borrow().len();
        let names = phone_kind_names();
        let kinds = gtk::DropDown::from_strings(&names.iter().map(String::as_str).collect::<Vec<_>>());
        kinds.set_selected(PHONE_KINDS.iter().position(|k| *k == kind).unwrap_or(3) as u32);
        kinds.set_valign(gtk::Align::Center);
        kinds.add_css_class("flat");
        kinds.set_widget_name(&format!("contact-phone-kind-{index}"));
        let row = adw::EntryRow::builder()
            .title(words::field_title(Text::UiColPhone))
            .text(number)
            .build();
        row.set_input_purpose(gtk::InputPurpose::Phone);
        row.set_widget_name(&format!("contact-phone-{index}"));
        row.add_suffix(&kinds);
        let remove = row_button(
            "ic-dismiss-symbolic",
            &words::field_title(Text::UiRemove),
            &format!("contact-phone-remove-{index}"),
        );
        let this = Rc::downgrade(self);
        let removed = row.downgrade();
        remove.connect_clicked(move |_| {
            if let (Some(this), Some(row)) = (this.upgrade(), removed.upgrade()) {
                let at = this.rows.borrow().iter().position(|(r, _)| *r == row).unwrap_or(0);
                this.group.remove(&row);
                this.rows.borrow_mut().retain(|(r, _)| *r != row);
                // the focus was on its Remove: to the number now in its place
                let rows = this.rows.borrow();
                if let Some((next, _)) = rows.get(at).or(rows.last()) {
                    next.grab_focus();
                }
            }
        });
        row.add_suffix(&remove);
        self.group.add(&row);
        self.rows.borrow_mut().push((row.clone(), kinds));
        row
    }

    fn values(&self) -> Vec<(String, String)> {
        self.rows
            .borrow()
            .iter()
            .map(|(row, kinds)| {
                let kind = PHONE_KINDS.get(kinds.selected() as usize).copied().unwrap_or("");
                (kind.to_string(), row.text().trim().to_string())
            })
            .filter(|(_, number)| !number.is_empty())
            .collect()
    }
}

/// The fields of a contact's names
struct Names {
    group: adw::PreferencesGroup,
    first: adw::EntryRow,
    last: adw::EntryRow,
    display: adw::EntryRow,
    nickname: adw::EntryRow,
    company: adw::EntryRow,
}

fn names_section(card: &Card) -> Names {
    let names = Names {
        group: adw::PreferencesGroup::new(),
        first: entry_row(Text::UiContactFirst, &card.first, "contact-first"),
        last: entry_row(Text::UiContactLast, &card.last, "contact-last"),
        display: entry_row(Text::UiContactDisplay, &card.name, "contact-display"),
        nickname: entry_row(Text::UiContactNickname, &card.nickname, "contact-nickname"),
        company: entry_row(Text::UiContactCompany, &card.company, "contact-company"),
    };
    for row in [
        &names.first,
        &names.last,
        &names.display,
        &names.nickname,
        &names.company,
    ] {
        row.set_activates_default(true);
        names.group.add(row);
    }
    follow_names(&names, card);
    names
}

/// The name shown follows the first and last name until it is typed over
fn follow_names(names: &Names, card: &Card) {
    let following = Rc::new(Cell::new(
        card.name.trim().is_empty() || card.name == display_name(&card.first, &card.last),
    ));
    let setting = Rc::new(Cell::new(false));
    let (first, last, display) = (
        names.first.downgrade(),
        names.last.downgrade(),
        names.display.downgrade(),
    );
    for field in [&names.first, &names.last] {
        let (first, last, display) = (first.clone(), last.clone(), display.clone());
        let (following, setting) = (following.clone(), setting.clone());
        field.connect_changed(move |_| {
            let (Some(first), Some(last), Some(display)) = (first.upgrade(), last.upgrade(), display.upgrade()) else {
                return;
            };
            if following.get() {
                setting.set(true);
                display.set_text(&display_name(&first.text(), &last.text()));
                setting.set(false);
            }
        });
    }
    names.display.connect_changed(move |display| {
        if setting.get() {
            return;
        }
        let (Some(first), Some(last)) = (first.upgrade(), last.upgrade()) else {
            return;
        };
        let text = display.text();
        following.set(text.trim().is_empty() || text == display_name(&first.text(), &last.text()));
    });
}

fn addresses_section(card: &Card, dialog: &glib::WeakRef<adw::Dialog>) -> Rc<Addresses> {
    let new = adw::EntryRow::builder()
        .title(words::field_title(Text::UiContactAddressHint))
        .input_purpose(gtk::InputPurpose::Email)
        .build();
    new.set_widget_name("contact-new-address");
    let add = add_button("contact-add-address");
    new.add_suffix(&add);
    let addresses = Rc::new(Addresses {
        group: adw::PreferencesGroup::builder()
            .title(words::field_title(Text::UiContactAddresses))
            .build(),
        rows: RefCell::default(),
        new: new.clone(),
        list: RefCell::new(card.addresses.clone()),
    });
    addresses.fill();
    let typed = {
        let (addresses, dialog) = (Rc::downgrade(&addresses), dialog.clone());
        move || {
            let Some(addresses) = addresses.upgrade() else {
                return;
            };
            match addresses.take_typed() {
                // the row was put back under the new address: the next one is typed there
                Ok(true) => {
                    addresses.new.grab_focus();
                }
                Ok(false) => {}
                Err(why) => say_later(&dialog, why),
            }
        }
    };
    let on_add = typed.clone();
    add.connect_clicked(move |_| on_add());
    new.connect_entry_activated(move |_| typed());
    addresses
}

fn phones_section(card: &Card) -> Rc<Phones> {
    let group = adw::PreferencesGroup::builder()
        .title(words::field_title(Text::UiContactPhones))
        .build();
    let add = add_button("contact-add-phone");
    group.set_header_suffix(Some(&add));
    let phones = Rc::new(Phones {
        group,
        rows: RefCell::default(),
    });
    for (kind, number) in &card.phones {
        phones.add(kind, number);
    }
    if card.phones.is_empty() {
        phones.add("", "");
    }
    let adding = Rc::downgrade(&phones);
    add.connect_clicked(move |_| {
        if let Some(phones) = adding.upgrade() {
            phones.add("", "").grab_focus();
        }
    });
    phones
}

fn notes_section(card: &Card) -> (adw::PreferencesGroup, gtk::TextView) {
    let group = adw::PreferencesGroup::builder()
        .title(words::field_title(Text::UiContactNotes))
        .build();
    let notes = gtk::TextView::new();
    notes.set_wrap_mode(gtk::WrapMode::WordChar);
    // Tab goes on to the next control, as in the other fields
    notes.set_accepts_tab(false);
    notes.buffer().set_text(&card.notes);
    notes.set_top_margin(8);
    notes.set_bottom_margin(8);
    notes.set_left_margin(10);
    notes.set_right_margin(10);
    notes.set_widget_name("contact-notes");
    let frame = gtk::ScrolledWindow::builder()
        .child(&notes)
        .min_content_height(90)
        .hscrollbar_policy(gtk::PolicyType::Never)
        .build();
    frame.add_css_class("card");
    group.add(&frame);
    (group, notes)
}

/// The card of what the form says, on the one read so what it does not show stays
fn card_from_form(card: &Card, names: &Names, addresses: &Addresses, phones: &Phones, notes: &gtk::TextView) -> Card {
    let buffer = notes.buffer();
    Card {
        name: names.display.text().trim().to_string(),
        first: names.first.text().trim().to_string(),
        last: names.last.text().trim().to_string(),
        nickname: names.nickname.text().trim().to_string(),
        company: names.company.text().trim().to_string(),
        notes: buffer
            .text(&buffer.start_iter(), &buffer.end_iter(), false)
            .trim()
            .to_string(),
        addresses: addresses.list.borrow().clone(),
        phones: phones.values(),
        ..card.clone()
    }
}

// ---- the contact's picture ----

/// The picture's size in the form, in points
const PICTURE_SIZE: i32 = 64;

/// The picture file kinds Choose offers
const PICTURE_PATTERNS: [&str; 6] = ["*.png", "*.jpg", "*.jpeg", "*.PNG", "*.JPG", "*.JPEG"];

/// What the form will do to the card's picture once OK saves it: nothing, set the PNG the core prepared from the file
/// chosen, or take it away
enum Choice {
    Kept,
    Set(Vec<u8>),
    Removed,
}

/// The picture well at the top of Contact Properties: the card's picture (the core reads, keeps and draws it), else
/// its initials on the quiet fill, round as the list draws senders; Choose... and Remove under it, and a picture file
/// dropped on it. What is chosen is prepared by the core off the window's thread and shown, and written only once OK
/// saves the card; Cancel leaves the card's picture as it was.
struct PictureWell {
    group: adw::PreferencesGroup,
    frame: gtk::Box,
    image: gtk::Image,
    initials: gtk::Label,
    remove: gtk::Button,
    card: CardId,
    choice: RefCell<Choice>,
}

impl PictureWell {
    fn new(card: &Card) -> Rc<PictureWell> {
        let image = gtk::Image::builder().pixel_size(PICTURE_SIZE).build();
        let frame = gtk::Box::builder()
            .width_request(PICTURE_SIZE)
            .height_request(PICTURE_SIZE)
            .overflow(gtk::Overflow::Hidden)
            .build();
        frame.add_css_class("card-picture");
        frame.append(&image);
        let address = card.addresses.first().map(String::as_str).unwrap_or_default();
        let initials = gtk::Label::new(Some(&pe_core::initials(&card.name, address)));
        initials.add_css_class("card-initials");
        let well = gtk::Overlay::builder().halign(gtk::Align::Center).build();
        well.set_child(Some(&frame));
        well.add_overlay(&initials);
        well.set_widget_name("contact-picture");
        well.update_property(&[gtk::accessible::Property::Label(&words::field_title(
            Text::UiCardPicture,
        ))]);
        let choose =
            gtk::Button::with_mnemonic(&pe_core::i18n::gtk_mnemonic(&t!(UiCardPictureChoose)).replace("...", "…"));
        choose.set_widget_name("contact-picture-choose");
        let remove = gtk::Button::with_mnemonic(&pe_core::i18n::gtk_mnemonic(&t!(UiRemove)));
        remove.set_widget_name("contact-picture-remove");
        let buttons = gtk::Box::new(gtk::Orientation::Horizontal, 6);
        buttons.set_halign(gtk::Align::Center);
        buttons.append(&choose);
        buttons.append(&remove);
        let column = gtk::Box::new(gtk::Orientation::Vertical, 10);
        column.set_margin_top(6);
        column.append(&well);
        column.append(&buttons);
        let group = adw::PreferencesGroup::new();
        group.add(&column);
        let this = Rc::new(PictureWell {
            group,
            frame,
            image,
            initials,
            remove,
            card: card.id,
            choice: RefCell::new(Choice::Kept),
        });
        this.connect(&choose, &well);
        this.refresh();
        this
    }

    fn connect(self: &Rc<Self>, choose: &gtk::Button, well: &gtk::Overlay) {
        let this = Rc::downgrade(self);
        choose.connect_clicked(move |_| {
            if let Some(this) = this.upgrade() {
                glib::spawn_future_local(async move { this.choose().await });
            }
        });
        let this = Rc::downgrade(self);
        self.remove.connect_clicked(move |_| {
            if let Some(this) = this.upgrade() {
                *this.choice.borrow_mut() = Choice::Removed;
                this.refresh();
            }
        });
        // a picture file dragged onto the well, as Choose takes one
        let drop = gtk::DropTarget::new(gdk::FileList::static_type(), gdk::DragAction::COPY);
        let this = Rc::downgrade(self);
        drop.connect_drop(move |_, value, _, _| {
            let path = value
                .get::<gdk::FileList>()
                .ok()
                .and_then(|files| files.files().into_iter().next())
                .and_then(|file| file.path());
            match (this.upgrade(), path) {
                (Some(this), Some(path)) => {
                    glib::spawn_future_local(async move { this.take(path).await });
                    true
                }
                _ => false,
            }
        });
        let frame = self.frame.clone();
        drop.connect_enter(move |_, _, _| {
            frame.add_css_class("drop-target");
            gdk::DragAction::COPY
        });
        let frame = self.frame.clone();
        drop.connect_leave(move |_| frame.remove_css_class("drop-target"));
        well.add_controller(drop);
    }

    /// Choose...: a PNG or JPEG file
    async fn choose(self: Rc<Self>) {
        // the dialog is presented after the well is made: found from the well itself
        let Some(window) = self.group.root().and_downcast::<gtk::Window>() else {
            return;
        };
        let title = words::field_title(Text::UiCardPicture);
        let pictures = t!(UiFilterPictures);
        if let Some(path) = ui::open_file(&window, &title, Some((&pictures, &PICTURE_PATTERNS))).await {
            self.take(path).await;
        }
    }

    /// The picture of the file at `path`, prepared by the core off the window's thread and shown; a file the core
    /// refuses is said over the dialog
    async fn take(&self, path: PathBuf) {
        let prepared = gio::spawn_blocking(move || pe_core::card_pictures::prepare(&path)).await;
        match prepared {
            Ok(Ok(png)) => {
                *self.choice.borrow_mut() = Choice::Set(png);
                self.refresh();
            }
            Ok(Err(refused)) => self.say(refused.text()),
            Err(_) => self.say(pe_core::card_pictures::Refused::NotPicture.text()),
        }
    }

    /// `why` said over the dialog the well is in
    fn say(&self, why: String) {
        let dialog = glib::WeakRef::new();
        let ancestor = self.group.ancestor(adw::Dialog::static_type());
        dialog.set(ancestor.and_downcast::<adw::Dialog>().as_ref());
        say_later(&dialog, why);
    }

    /// The picture as it would be after OK, else the initials; Remove only with a picture
    fn refresh(&self) {
        let size = PICTURE_SIZE * self.image.scale_factor().max(1);
        let pixels = match &*self.choice.borrow() {
            Choice::Set(png) => pe_core::card_pictures::bgra(png, size as u32),
            Choice::Removed => None,
            Choice::Kept if self.card != 0 => shell().core.card_picture(self.card, size as u32),
            Choice::Kept => None,
        };
        let texture = pixels.and_then(|pixels| ui::bgra_texture(pixels, size));
        self.image.set_paintable(texture.as_ref());
        self.image.set_visible(texture.is_some());
        self.initials.set_visible(texture.is_none());
        self.remove.set_visible(texture.is_some());
    }

    /// OK saved the card as `id`: what was chosen is its picture now; whether that changed it
    fn saved(&self, id: CardId) -> bool {
        let core = &shell().core;
        match std::mem::replace(&mut *self.choice.borrow_mut(), Choice::Kept) {
            Choice::Set(png) => core.set_card_picture_png(id, &png).is_ok(),
            Choice::Removed if self.card != 0 => core.remove_card_picture(id).is_ok(),
            _ => false,
        }
    }

    #[cfg(feature = "e2e")]
    fn shows_picture(&self) -> bool {
        self.image.is_visible()
    }
}

/// Contact Properties of card `id`, or New Contact for 0; the card's id once OK saved it, None for Cancel
pub async fn contact(parent: &impl IsA<gtk::Widget>, id: CardId) -> Option<CardId> {
    let core = &shell().core;
    let card = if id == 0 {
        Card::default()
    } else {
        core.card(id).ok().flatten()?
    };
    let title = if id == 0 {
        t!(UiNewContactTitle)
    } else {
        t!(UiContactTitle, name = &card.name)
    };
    let names = names_section(&card);
    let dialog_ref = glib::WeakRef::<adw::Dialog>::new();
    let picture = PictureWell::new(&card);
    let addresses = addresses_section(&card, &dialog_ref);
    let phones = phones_section(&card);
    let (notes_group, notes) = notes_section(&card);
    let content = page(&[
        &picture.group,
        &names.group,
        &addresses.group,
        &phones.group,
        &notes_group,
    ]);
    let (dialog, clicks) = present(parent, &title, &content, "contact-dialog", 680);
    dialog_ref.set(Some(&dialog));
    names.first.grab_focus();
    #[cfg(feature = "e2e")]
    CONTACT_PICTURE.with(|open| *open.borrow_mut() = Some(picture.clone()));
    contact_answers(&card, &dialog, &clicks, &names, &addresses, &phones, &notes, &picture).await
}

#[cfg(feature = "e2e")]
thread_local! {
    /// The picture well of the Contact Properties open last, for the UI test
    static CONTACT_PICTURE: RefCell<Option<Rc<PictureWell>>> = RefCell::default();
}

/// Whether the Contact Properties open last shows a picture (not the initials)
#[cfg(feature = "e2e")]
pub fn contact_shows_picture() -> bool {
    CONTACT_PICTURE.with(|open| open.borrow().as_ref().is_some_and(|well| well.shows_picture()))
}

/// OK and Cancel of Contact Properties until one of them ends it: the card's id once OK saved it
#[allow(clippy::too_many_arguments)]
async fn contact_answers(
    card: &Card,
    dialog: &adw::Dialog,
    clicks: &async_channel::Receiver<bool>,
    names: &Names,
    addresses: &Rc<Addresses>,
    phones: &Phones,
    notes: &gtk::TextView,
    picture: &PictureWell,
) -> Option<CardId> {
    let core = &shell().core;
    while let Ok(ok) = clicks.recv().await {
        if !ok {
            return None;
        }
        // an address typed and not added yet goes with the rest
        if let Err(why) = addresses.take_typed() {
            ui::alert(dialog, TITLE, &why).await;
            continue;
        }
        // the core refuses a contact without a name or an address, and says why
        match core.save_card(&card_from_form(card, names, addresses, phones, notes)) {
            Ok(id) => {
                // a picture set or taken away: the list draws its senders again (their keys change with it)
                if picture.saved(id) {
                    shell().main().senders_changed();
                }
                dialog.close();
                return Some(id);
            }
            Err(error) => {
                let said = t!(UiContactNotSaved, reason = &error.to_string());
                ui::alert(dialog, TITLE, &said).await;
            }
        }
    }
    None
}

// ---- Group Properties ----

/// The members of the group form, each a row with Remove
struct Members {
    group: adw::PreferencesGroup,
    rows: RefCell<Vec<adw::ActionRow>>,
    list: RefCell<Vec<Member>>,
}

impl Members {
    fn fill(self: &Rc<Self>) {
        for row in self.rows.borrow_mut().drain(..) {
            self.group.remove(&row);
        }
        let list = self.list.borrow().clone();
        self.group
            .set_description(Some(&t!(UiGroupMembersCount, count = list.len() as u64)));
        for (index, member) in list.iter().enumerate() {
            let named = !member.name.trim().is_empty();
            let row = adw::ActionRow::builder()
                .title(if named { &member.name } else { &member.address })
                .use_markup(false)
                .build();
            if named {
                row.set_subtitle(&member.address);
            }
            row.set_widget_name(&format!("group-member-{index}"));
            let icon = if member.card.is_some() {
                "avatar-default-symbolic"
            } else {
                "mail-unread-symbolic"
            };
            row.add_prefix(&gtk::Image::from_icon_name(icon));
            let remove = row_button(
                "ic-dismiss-symbolic",
                &words::field_title(Text::UiRemove),
                &format!("group-member-remove-{index}"),
            );
            let this = Rc::downgrade(self);
            remove.connect_clicked(move |_| {
                if let Some(this) = this.upgrade() {
                    this.list.borrow_mut().remove(index);
                    this.fill();
                    // the focus was on its Remove: to the member now in its place
                    let rows = this.rows.borrow();
                    if let Some(next) = rows.get(index).or(rows.last()) {
                        next.grab_focus();
                    }
                }
            });
            row.add_suffix(&remove);
            self.group.add(&row);
            self.rows.borrow_mut().push(row);
        }
    }

    /// Adds those not in the group yet, as the core keeps a group: a card once, an address once
    fn add(self: &Rc<Self>, members: Vec<Member>) {
        let merged = add_members(&self.list.borrow(), &members);
        *self.list.borrow_mut() = merged;
        self.fill();
    }

    /// The address typed in `new` into the group; Err with the words for one that is not an address
    fn take_typed(self: &Rc<Self>, new: &adw::EntryRow) -> Result<(), String> {
        let typed = new.text().trim().to_string();
        if typed.is_empty() {
            return Ok(());
        }
        if !is_mailbox(&typed) {
            return Err(t!(UiContactAddressInvalid, address = &typed));
        }
        self.add(vec![Member {
            card: None,
            name: String::new(),
            address: typed,
        }]);
        new.set_text("");
        Ok(())
    }
}

/// Group Properties of group `id`, or New Group for 0; the group's id once OK saved it, None for Cancel
pub async fn group(parent: &impl IsA<gtk::Widget>, id: GroupId) -> Option<GroupId> {
    let core = &shell().core;
    let group = if id == 0 {
        Group::default()
    } else {
        core.group(id).ok().flatten()?
    };
    let title = if id == 0 {
        t!(UiNewGroupTitle)
    } else {
        t!(UiGroupTitle, name = &group.name)
    };
    let name = entry_row(Text::UiGroupName, &group.name, "group-name");
    name.set_activates_default(true);
    let names = adw::PreferencesGroup::new();
    names.add(&name);

    let member_group = adw::PreferencesGroup::builder()
        .title(words::field_title(Text::UiGroupMembers))
        .build();
    let select =
        gtk::Button::with_mnemonic(&pe_core::i18n::gtk_mnemonic(&t!(UiGroupSelectMembers)).replace("...", "…"));
    select.set_widget_name("group-select-members");
    select.set_valign(gtk::Align::Center);
    member_group.set_header_suffix(Some(&select));
    let members = Rc::new(Members {
        group: member_group.clone(),
        rows: RefCell::default(),
        list: RefCell::new(group.members.clone()),
    });
    members.fill();

    let typed_group = adw::PreferencesGroup::new();
    let new = adw::EntryRow::builder()
        .title(words::field_title(Text::UiGroupNewMember))
        .input_purpose(gtk::InputPurpose::Email)
        .build();
    new.set_widget_name("group-new-member");
    let add = add_button("group-add-member");
    new.add_suffix(&add);
    typed_group.add(&new);

    let content = page(&[&names, &member_group, &typed_group]);
    let (dialog, clicks) = present(parent, &title, &content, "group-dialog", 600);
    {
        let (members, new_row, dialog) = (Rc::downgrade(&members), new.downgrade(), dialog.downgrade());
        let added = move || {
            if let (Some(members), Some(new)) = (members.upgrade(), new_row.upgrade())
                && let Err(why) = members.take_typed(&new)
            {
                say_later(&dialog, why);
            }
        };
        let on_add = added.clone();
        add.connect_clicked(move |_| on_add());
        new.connect_entry_activated(move |_| added());
    }
    {
        let members = members.clone();
        let dialog = dialog.downgrade();
        select.connect_clicked(move |_| {
            let (members, Some(dialog)) = (members.clone(), dialog.upgrade()) else {
                return;
            };
            glib::spawn_future_local(async move {
                if let Some(picked) = crate::recipients::pick_members(&dialog).await {
                    members.add(picked);
                }
            });
        });
    }
    name.grab_focus();
    while let Ok(ok) = clicks.recv().await {
        if !ok {
            return None;
        }
        if let Err(why) = members.take_typed(&new) {
            ui::alert(&dialog, TITLE, &why).await;
            continue;
        }
        let saved = Group {
            id: group.id,
            name: name.text().trim().to_string(),
            members: members.list.borrow().clone(),
        };
        if saved.name.is_empty() {
            ui::alert(&dialog, TITLE, &t!(UiGroupNameNeeded)).await;
            continue;
        }
        match core.save_group(&saved) {
            Ok(id) => {
                dialog.close();
                return Some(id);
            }
            Err(error) => {
                let said = t!(UiGroupNotSaved, reason = &error.to_string());
                ui::alert(&dialog, TITLE, &said).await;
            }
        }
    }
    None
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn a_kind_for_each_name() {
        pe_core::i18n::set_language("en");
        assert_eq!(phone_kind_names().len(), PHONE_KINDS.len());
        assert_eq!(phone_kind_names()[2], "Mobile");
    }
}
