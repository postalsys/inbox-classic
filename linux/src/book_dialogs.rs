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
use pe_core::book::is_mailbox;

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
    let (send, clicks) = async_channel::unbounded();
    let closed = send.clone();
    dialog.connect_closed(move |_| {
        let _ = closed.try_send(false);
    });
    ok.connect_clicked(move |_| {
        let _ = send.try_send(true);
    });
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
                }
            });
            row.add_suffix(&remove);
            self.group.add(&row);
            self.rows.borrow_mut().push(row);
        }
        self.group.add(&self.new);
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
                this.group.remove(&row);
                this.rows.borrow_mut().retain(|(r, _)| *r != row);
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

/// The name made of the first and last name, as the core makes it when none is given
fn full_name(first: &str, last: &str) -> String {
    format!("{} {}", first.trim(), last.trim()).trim().to_string()
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
    let first = entry_row(Text::UiContactFirst, &card.first, "contact-first");
    let last = entry_row(Text::UiContactLast, &card.last, "contact-last");
    let display = entry_row(Text::UiContactDisplay, &card.name, "contact-display");
    let nickname = entry_row(Text::UiContactNickname, &card.nickname, "contact-nickname");
    let company = entry_row(Text::UiContactCompany, &card.company, "contact-company");
    let names = adw::PreferencesGroup::new();
    for row in [&first, &last, &display, &nickname, &company] {
        row.set_activates_default(true);
        names.add(row);
    }
    // the name shown follows the first and last name until it is typed over
    let following = Rc::new(Cell::new(
        card.name.trim().is_empty() || card.name == full_name(&card.first, &card.last),
    ));
    let setting = Rc::new(Cell::new(false));
    for field in [&first, &last] {
        let (first, last, display) = (first.downgrade(), last.downgrade(), display.downgrade());
        let (following, setting) = (following.clone(), setting.clone());
        field.connect_changed(move |_| {
            let (Some(first), Some(last), Some(display)) = (first.upgrade(), last.upgrade(), display.upgrade()) else {
                return;
            };
            if following.get() {
                setting.set(true);
                display.set_text(&full_name(&first.text(), &last.text()));
                setting.set(false);
            }
        });
    }
    {
        let (first, last) = (first.downgrade(), last.downgrade());
        let (following, setting) = (following.clone(), setting.clone());
        display.connect_changed(move |display| {
            if setting.get() {
                return;
            }
            let (Some(first), Some(last)) = (first.upgrade(), last.upgrade()) else {
                return;
            };
            let text = display.text();
            following.set(text.trim().is_empty() || text == full_name(&first.text(), &last.text()));
        });
    }

    let address_group = adw::PreferencesGroup::builder()
        .title(title_of(Text::UiContactAddresses))
        .build();
    let new = adw::EntryRow::builder()
        .title(title_of(Text::UiContactAddressHint))
        .input_purpose(gtk::InputPurpose::Email)
        .build();
    new.set_widget_name("contact-new-address");
    let add = gtk::Button::from_icon_name("list-add-symbolic");
    add.set_tooltip_text(Some(&title_of(Text::UiContactAdd)));
    add.add_css_class("flat");
    add.set_valign(gtk::Align::Center);
    add.set_widget_name("contact-add-address");
    new.add_suffix(&add);
    let addresses = Rc::new(Addresses {
        group: address_group.clone(),
        rows: RefCell::default(),
        new: new.clone(),
        list: RefCell::new(card.addresses.clone()),
    });
    addresses.fill();
    let dialog_cell: Rc<RefCell<Option<adw::Dialog>>> = Rc::default();
    let typed = {
        let addresses = addresses.clone();
        let dialog_cell = dialog_cell.clone();
        move || {
            if let Err(why) = addresses.take_typed() {
                let dialog = dialog_cell.borrow().clone();
                if let Some(dialog) = dialog {
                    glib::spawn_future_local(async move { ui::alert(&dialog, TITLE, &why).await });
                }
            }
        }
    };
    let on_add = typed.clone();
    add.connect_clicked(move |_| on_add());
    new.connect_entry_activated(move |_| typed());

    let phone_group = adw::PreferencesGroup::builder()
        .title(title_of(Text::UiContactPhones))
        .build();
    let add_phone = gtk::Button::from_icon_name("list-add-symbolic");
    add_phone.set_tooltip_text(Some(&title_of(Text::UiContactAdd)));
    add_phone.add_css_class("flat");
    add_phone.set_widget_name("contact-add-phone");
    phone_group.set_header_suffix(Some(&add_phone));
    let phones = Rc::new(Phones {
        group: phone_group.clone(),
        rows: RefCell::default(),
    });
    for (kind, number) in &card.phones {
        phones.add(kind, number);
    }
    if card.phones.is_empty() {
        phones.add("", "");
    }
    let adding = phones.clone();
    add_phone.connect_clicked(move |_| {
        adding.add("", "").grab_focus();
    });

    let notes_group = adw::PreferencesGroup::builder()
        .title(title_of(Text::UiContactNotes))
        .build();
    let notes = gtk::TextView::new();
    notes.set_wrap_mode(gtk::WrapMode::WordChar);
    notes.buffer().set_text(&card.notes);
    notes.set_top_margin(8);
    notes.set_bottom_margin(8);
    notes.set_left_margin(10);
    notes.set_right_margin(10);
    notes.set_widget_name("contact-notes");
    let notes_frame = gtk::ScrolledWindow::builder()
        .child(&notes)
        .min_content_height(90)
        .hscrollbar_policy(gtk::PolicyType::Never)
        .build();
    notes_frame.add_css_class("card");
    notes_group.add(&notes_frame);

    let content = page(&[&names, &address_group, &phone_group, &notes_group]);
    let (dialog, clicks) = present(parent, &title, &content, "contact-dialog", 680);
    *dialog_cell.borrow_mut() = Some(dialog.clone());
    first.grab_focus();
    while let Ok(ok) = clicks.recv().await {
        if !ok {
            return None;
        }
        // an address typed and not added yet goes with the rest
        if let Err(why) = addresses.take_typed() {
            ui::alert(&dialog, TITLE, &why).await;
            continue;
        }
        let buffer = notes.buffer();
        let card = Card {
            name: display.text().trim().to_string(),
            first: first.text().trim().to_string(),
            last: last.text().trim().to_string(),
            nickname: nickname.text().trim().to_string(),
            company: company.text().trim().to_string(),
            notes: buffer
                .text(&buffer.start_iter(), &buffer.end_iter(), false)
                .trim()
                .to_string(),
            addresses: addresses.list.borrow().clone(),
            phones: phones.values(),
            ..card.clone()
        };
        if card.name.is_empty() && full_name(&card.first, &card.last).is_empty() && card.addresses.is_empty() {
            ui::alert(&dialog, TITLE, &t!(UiContactNameNeeded)).await;
            continue;
        }
        // nameless: known by the default address
        let card = if card.name.is_empty() && full_name(&card.first, &card.last).is_empty() {
            Card {
                name: card.addresses[0].clone(),
                ..card
            }
        } else {
            card
        };
        match core.save_card(&card) {
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
                }
            });
            row.add_suffix(&remove);
            self.group.add(&row);
            self.rows.borrow_mut().push(row);
        }
    }

    /// Adds those not in the group yet: a card once, an address of no card once
    fn add(self: &Rc<Self>, members: Vec<Member>) {
        {
            let mut list = self.list.borrow_mut();
            for member in members {
                let known = list.iter().any(|m| match (m.card, member.card) {
                    (Some(a), Some(b)) => a == b,
                    (None, None) => m.address.eq_ignore_ascii_case(&member.address),
                    _ => false,
                });
                if !known {
                    list.push(member);
                }
            }
        }
        self.fill();
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
    let add = gtk::Button::from_icon_name("list-add-symbolic");
    add.set_tooltip_text(Some(&title_of(Text::UiContactAdd)));
    add.add_css_class("flat");
    add.set_valign(gtk::Align::Center);
    add.set_widget_name("group-add-member");
    new.add_suffix(&add);
    typed_group.add(&new);

    let content = page(&[&names, &member_group, &typed_group]);
    let (dialog, clicks) = present(parent, &title, &content, "group-dialog", 600);
    let take_typed = {
        let (members, new) = (members.clone(), new.clone());
        move || -> Result<(), String> {
            let typed = new.text().trim().to_string();
            if typed.is_empty() {
                return Ok(());
            }
            if !is_mailbox(&typed) {
                return Err(t!(UiContactAddressInvalid, address = &typed));
            }
            members.add(vec![Member {
                card: None,
                name: String::new(),
                address: typed,
            }]);
            new.set_text("");
            Ok(())
        }
    };
    {
        let take_typed = take_typed.clone();
        let dialog = dialog.downgrade();
        let added = move || {
            if let Err(why) = take_typed()
                && let Some(dialog) = dialog.upgrade()
            {
                glib::spawn_future_local(async move { ui::alert(&dialog, TITLE, &why).await });
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
        if let Err(why) = take_typed() {
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
    fn the_name_of_first_and_last() {
        assert_eq!(full_name(" Mary ", "Smith"), "Mary Smith");
        assert_eq!(full_name("", "Smith"), "Smith");
        assert_eq!(full_name("", ""), "");
    }

    #[test]
    fn a_kind_for_each_name() {
        pe_core::i18n::set_language("en");
        assert_eq!(phone_kind_names().len(), PHONE_KINDS.len());
        assert_eq!(phone_kind_names()[2], "Mobile");
    }
}
