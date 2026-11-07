//! Select Recipients, Outlook Express's picker behind the To, Cc and Bcc buttons of a message: the Address Book's
//! groups and people on the left with a find box, To, Cc and Bcc buttons that put the ones selected into the lists
//! beside them, and OK that hands those back for the fields (`pe_core::book::add_to_field` puts them in). Group
//! Properties uses it as Select Group Members, with the people alone and one list.

use std::cell::RefCell;
use std::rc::Rc;

use adw::prelude::*;
use gtk::{gdk, glib};
use pe_store::{CardId, GroupId, Member};

use crate::address_book::{Person, group_label};
use crate::app::shell;
use crate::ui::{self, TITLE};
use crate::words::Text;

/// A person or a group of the book as the picker lists it
#[derive(Clone, Debug, PartialEq, Eq)]
struct Item {
    card: CardId,
    group: Option<GroupId>,
    name: String,
    address: String,
    /// As it goes in an address field (a group's members), empty for someone without an address
    label: String,
}

impl Item {
    fn icon(&self) -> &'static str {
        if self.group.is_some() {
            "system-users-symbolic"
        } else {
            "avatar-default-symbolic"
        }
    }
}

/// Whether a word of `name` starts with `typed`, ignoring case: how the core finds people by name
fn name_matches(name: &str, typed: &str) -> bool {
    let typed = typed.trim().to_lowercase();
    typed.is_empty()
        || name.to_lowercase().starts_with(&typed)
        || name
            .split_whitespace()
            .any(|word| word.to_lowercase().starts_with(&typed))
}

/// The groups (when they are offered) and then the people of the book found by `typed`
fn items(typed: &str, with_groups: bool) -> Vec<Item> {
    let core = &shell().core;
    let mut found = Vec::new();
    if with_groups {
        for group in core.groups().unwrap_or_default() {
            if name_matches(&group.name, typed) {
                found.push(Item {
                    card: 0,
                    group: Some(group.id),
                    label: group_label(&group),
                    name: group.name,
                    address: String::new(),
                });
            }
        }
    }
    for card in core.cards(typed.trim()).unwrap_or_default() {
        let person = Person::of_card(&card);
        found.push(Item {
            card: card.id,
            group: None,
            label: person.label(),
            name: person.shown().to_string(),
            address: person.address,
        });
    }
    found
}

/// A row of a list: the icon, the name and the address after it, dimmed
fn item_row(item: &Item, name: &str) -> gtk::ListBoxRow {
    let content = gtk::Box::new(gtk::Orientation::Horizontal, 8);
    content.set_margin_top(4);
    content.set_margin_bottom(4);
    content.append(&gtk::Image::from_icon_name(item.icon()));
    let title = gtk::Label::new(Some(&item.name));
    title.set_xalign(0.0);
    title.set_ellipsize(gtk::pango::EllipsizeMode::End);
    content.append(&title);
    if !item.address.is_empty() && item.address != item.name {
        let address = gtk::Label::new(Some(&item.address));
        address.set_xalign(0.0);
        address.set_hexpand(true);
        address.set_ellipsize(gtk::pango::EllipsizeMode::End);
        address.add_css_class("dim-label");
        content.append(&address);
    }
    let row = gtk::ListBoxRow::new();
    row.set_child(Some(&content));
    row.set_widget_name(name);
    row.set_tooltip_text(Some(if item.label.is_empty() { &item.name } else { &item.label }));
    row
}

/// One of the lists on the right: the ones chosen for To, Cc, Bcc or the group
struct Target {
    list: gtk::ListBox,
    chosen: RefCell<Vec<Item>>,
}

impl Target {
    fn fill(&self) {
        while let Some(row) = self.list.first_child() {
            self.list.remove(&row);
        }
        for (index, item) in self.chosen.borrow().iter().enumerate() {
            let name = format!("{}-{index}", self.list.widget_name());
            self.list.append(&item_row(item, &name));
        }
    }

    fn remove_selected(&self) {
        let Some(index) = self.list.selected_row().map(|row| row.index()) else {
            return;
        };
        if index >= 0 && (index as usize) < self.chosen.borrow().len() {
            self.chosen.borrow_mut().remove(index as usize);
            self.fill();
            let next = (index - 1).max(0);
            self.list.select_row(self.list.row_at_index(next).as_ref());
        }
    }
}

struct Picker {
    dialog: adw::Dialog,
    list: gtk::ListBox,
    shown: RefCell<Vec<Item>>,
    targets: Vec<Target>,
    with_groups: bool,
}

impl Picker {
    fn fill(&self, typed: &str) {
        while let Some(row) = self.list.first_child() {
            self.list.remove(&row);
        }
        let found = items(typed, self.with_groups);
        for (index, item) in found.iter().enumerate() {
            self.list.append(&item_row(item, &format!("pick-item-{index}")));
        }
        *self.shown.borrow_mut() = found;
    }

    /// The ones selected on the left into list `target`, each once; someone without an address can not be written to
    fn choose(&self, target: usize) {
        let shown = self.shown.borrow();
        let picked: Vec<Item> = self
            .list
            .selected_rows()
            .iter()
            .filter_map(|row| shown.get(row.index().max(0) as usize).cloned())
            .collect();
        let Some(target) = self.targets.get(target) else {
            return;
        };
        let mut nameless = None;
        {
            let mut chosen = target.chosen.borrow_mut();
            for item in picked {
                if self.with_groups && item.label.is_empty() {
                    nameless.get_or_insert(item.name.clone());
                    continue;
                }
                if !chosen.contains(&item) {
                    chosen.push(item);
                }
            }
        }
        target.fill();
        if let Some(name) = nameless {
            let dialog = self.dialog.clone();
            glib::spawn_future_local(async move {
                ui::alert(&dialog, TITLE, &t!(UiBookNoAddress, name = &name)).await;
            });
        }
    }
}

/// The picker with a button and a list for each of `targets` (its words and name); what was chosen for each once OK
/// was clicked, None for Cancel
async fn pick(
    parent: &impl IsA<gtk::Widget>,
    title: &str,
    heading: Text,
    targets: &[(Text, &str)],
    with_groups: bool,
    start: usize,
) -> Option<Vec<Vec<Item>>> {
    let intro = gtk::Label::new(Some(&t!(UiPickIntro)));
    intro.set_xalign(0.0);
    intro.set_wrap(true);
    let find = gtk::SearchEntry::new();
    find.set_widget_name("pick-find");
    let list = gtk::ListBox::new();
    list.set_selection_mode(gtk::SelectionMode::Multiple);
    list.set_widget_name("pick-list");
    list.add_css_class("navigation-sidebar");
    let left = gtk::ScrolledWindow::builder()
        .child(&list)
        .hscrollbar_policy(gtk::PolicyType::Never)
        .vexpand(true)
        .width_request(300)
        .build();
    left.add_css_class("card");
    let right_heading = gtk::Label::new(Some(&crate::words::plain(heading)));
    right_heading.set_xalign(0.0);
    right_heading.set_valign(gtk::Align::Start);
    let grid = gtk::Grid::new();
    grid.set_column_spacing(12);
    grid.set_row_spacing(8);
    grid.set_margin_start(18);
    grid.set_margin_end(18);
    grid.set_margin_top(6);
    grid.set_margin_bottom(18);
    // the find box and the book on the left, the heading over the lists on the right level with its words
    let column = gtk::Box::new(gtk::Orientation::Vertical, 8);
    column.append(&intro);
    column.append(&find);
    column.append(&left);
    grid.attach(&column, 0, 0, 1, 1 + targets.len().max(1) as i32);
    grid.attach(&right_heading, 1, 0, 2, 1);
    let mut buttons = Vec::new();
    let mut lists = Vec::new();
    for (index, (words, name)) in targets.iter().enumerate() {
        let label = pe_core::i18n::gtk_mnemonic(&crate::words::tr(*words));
        let button = gtk::Button::with_mnemonic(&label);
        button.set_widget_name(name);
        button.set_valign(gtk::Align::Start);
        button.set_width_request(92);
        let chosen = gtk::ListBox::new();
        chosen.set_widget_name(&format!("{name}-list"));
        chosen.add_css_class("navigation-sidebar");
        let scrolled = gtk::ScrolledWindow::builder()
            .child(&chosen)
            .hscrollbar_policy(gtk::PolicyType::Never)
            .hexpand(true)
            .vexpand(true)
            .min_content_height(if targets.len() == 1 { 280 } else { 84 })
            .build();
        scrolled.add_css_class("card");
        grid.attach(&button, 1, 1 + index as i32, 1, 1);
        grid.attach(&scrolled, 2, 1 + index as i32, 1, 1);
        buttons.push(button);
        lists.push(chosen);
    }
    let (dialog, ok) = ui::dialog_with_buttons(title, &grid, &t!(UiOk), 800);
    dialog.set_content_height(if targets.len() == 1 { 520 } else { 540 });
    dialog.set_widget_name("pick-dialog");
    let picker = Rc::new(Picker {
        dialog: dialog.clone(),
        list: list.clone(),
        shown: RefCell::default(),
        targets: lists
            .into_iter()
            .map(|list| Target {
                list,
                chosen: RefCell::default(),
            })
            .collect(),
        with_groups,
    });
    picker.fill("");
    for (index, button) in buttons.iter().enumerate() {
        let picker = Rc::downgrade(&picker);
        button.connect_clicked(move |_| {
            if let Some(picker) = picker.upgrade() {
                picker.choose(index);
            }
        });
    }
    // a double click, or Enter, puts the row into the list of the button the picker was opened with
    let chosen_by_click = Rc::downgrade(&picker);
    list.connect_row_activated(move |list, row| {
        if let Some(picker) = chosen_by_click.upgrade() {
            if !row.is_selected() {
                list.select_row(Some(row));
            }
            picker.choose(start);
        }
    });
    let found = Rc::downgrade(&picker);
    find.connect_search_changed(move |find| {
        if let Some(picker) = found.upgrade() {
            picker.fill(&find.text());
        }
    });
    // Delete takes the one selected out of a list on the right
    for index in 0..picker.targets.len() {
        let keys = gtk::EventControllerKey::new();
        let this = Rc::downgrade(&picker);
        keys.connect_key_pressed(move |_, key, _, _| {
            if matches!(key, gdk::Key::Delete | gdk::Key::BackSpace)
                && let Some(this) = this.upgrade()
            {
                this.targets[index].remove_selected();
                return glib::Propagation::Stop;
            }
            glib::Propagation::Proceed
        });
        picker.targets[index].list.add_controller(keys);
    }
    let (send, clicks) = async_channel::unbounded();
    let closed = send.clone();
    dialog.connect_closed(move |_| {
        let _ = closed.try_send(false);
    });
    ok.connect_clicked(move |_| {
        let _ = send.try_send(true);
    });
    dialog.present(Some(parent.as_ref()));
    find.grab_focus();
    let answer = clicks.recv().await.unwrap_or(false);
    dialog.close();
    answer.then(|| picker.targets.iter().map(|t| t.chosen.borrow().clone()).collect())
}

/// Select Recipients for a message, opened by the To (0), Cc (1) or Bcc (2) button: what goes in each of the three
/// fields, as an address field takes it, once OK was clicked
pub async fn pick_recipients(parent: &impl IsA<gtk::Widget>, start: usize) -> Option<[String; 3]> {
    let targets = [
        (Text::UiPickTo, "pick-to"),
        (Text::UiPickCc, "pick-cc"),
        (Text::UiPickBcc, "pick-bcc"),
    ];
    let chosen = pick(
        parent,
        &t!(UiSelectRecipients),
        Text::UiPickRecipients,
        &targets,
        true,
        start.min(2),
    )
    .await?;
    let mut fields: [String; 3] = Default::default();
    for (field, items) in fields.iter_mut().zip(chosen) {
        let labels: Vec<String> = items.into_iter().map(|item| item.label).collect();
        *field = labels.join(", ");
    }
    Some(fields)
}

/// Select Group Members: the people chosen, as members that follow their card
pub async fn pick_members(parent: &impl IsA<gtk::Widget>) -> Option<Vec<Member>> {
    let chosen = pick(
        parent,
        &t!(UiSelectMembers),
        Text::UiPickMembers,
        &[(Text::UiPickAdd, "pick-add")],
        false,
        0,
    )
    .await?;
    Some(
        chosen
            .into_iter()
            .flatten()
            .map(|item| Member {
                card: Some(item.card),
                name: item.name,
                address: item.address,
            })
            .collect(),
    )
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn names_found_by_a_word() {
        assert!(name_matches("Team", "tea"));
        assert!(name_matches("The Team", "TEA"));
        assert!(name_matches("Anything", ""));
        assert!(!name_matches("Team", "eam"));
    }
}
