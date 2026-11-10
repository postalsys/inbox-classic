//! Contact Properties and Group Properties of the Address Book: the forms of a person (names, e-mail addresses with
//! the default first, phone numbers by kind, notes) and of a group (its name and members from the book or typed). The
//! core keeps and checks what they hand it (`pe_core::book`); a card is saved from the one read, so what a vCard
//! brought that the form does not show stays.

use std::cell::{Cell, RefCell};
use std::rc::Rc;

use adw::prelude::*;
use gtk::glib;
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

/// A field's title without the colon the catalogs give it ("First name:")
fn title_of(text: Text) -> String {
    words::plain(text).trim_end_matches(':').to_string()
}

fn entry_row(text: Text, value: &str, name: &str) -> adw::EntryRow {
    let row = adw::EntryRow::builder().title(title_of(text)).text(value).build();
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
    let button = row_button("list-add-symbolic", &title_of(Text::UiContactAdd), name);
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
                    &title_of(Text::UiContactSetDefault),
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
                &title_of(Text::UiRemove),
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
            .title(title_of(Text::UiColPhone))
            .text(number)
            .build();
        row.set_input_purpose(gtk::InputPurpose::Phone);
        row.set_widget_name(&format!("contact-phone-{index}"));
        row.add_suffix(&kinds);
        let remove = row_button(
            "ic-dismiss-symbolic",
            &title_of(Text::UiRemove),
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
        .title(title_of(Text::UiContactAddressHint))
        .input_purpose(gtk::InputPurpose::Email)
        .build();
    new.set_widget_name("contact-new-address");
    let add = add_button("contact-add-address");
    new.add_suffix(&add);
    let addresses = Rc::new(Addresses {
        group: adw::PreferencesGroup::builder()
            .title(title_of(Text::UiContactAddresses))
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
        .title(title_of(Text::UiContactPhones))
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
        .title(title_of(Text::UiContactNotes))
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
    let addresses = addresses_section(&card, &dialog_ref);
    let phones = phones_section(&card);
    let (notes_group, notes) = notes_section(&card);
    let content = page(&[&names.group, &addresses.group, &phones.group, &notes_group]);
    let (dialog, clicks) = present(parent, &title, &content, "contact-dialog", 680);
    dialog_ref.set(Some(&dialog));
    names.first.grab_focus();
    while let Ok(ok) = clicks.recv().await {
        if !ok {
            return None;
        }
        // an address typed and not added yet goes with the rest
        if let Err(why) = addresses.take_typed() {
            ui::alert(&dialog, TITLE, &why).await;
            continue;
        }
        // the core refuses a contact without a name or an address, and says why
        match core.save_card(&card_from_form(&card, &names, &addresses, &phones, &notes)) {
            Ok(id) => {
                dialog.close();
                return Some(id);
            }
            Err(error) => {
                let said = t!(UiContactNotSaved, reason = &error.to_string());
                ui::alert(&dialog, TITLE, &said).await;
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
                &title_of(Text::UiRemove),
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
        .title(title_of(Text::UiGroupMembers))
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
        .title(title_of(Text::UiGroupNewMember))
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
