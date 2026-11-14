//! Message rules: the Message Rules window (Tools) with the rules in their order, each turned on or off, and the
//! editor of one: its name, the account whose new mail it is for, the search words the mail has to match (with how
//! many messages in the Inbox match them now) and what it does. The core checks the rule before saving it.

use std::cell::RefCell;
use std::rc::Rc;

use adw::prelude::*;
use gtk::{gdk, glib};
use pe_store::{Rule, RuleId};

use crate::app::shell;
use crate::ui;
use crate::words::{Text, field_title, plain};

/// How the editor ended
#[derive(PartialEq, Eq)]
pub enum Outcome {
    Saved,
    Cancelled,
    /// Show: the dialogs closed, the main window searching for what the rule matches
    Shown,
}

/// A row with a check box in front of it, the box toggled by the row
fn check_row(title: &str, name: &str, active: bool) -> (adw::ActionRow, gtk::CheckButton) {
    let check = gtk::CheckButton::builder()
        .active(active)
        .valign(gtk::Align::Center)
        .build();
    check.set_widget_name(name);
    let row = adw::ActionRow::builder().title(title).use_underline(false).build();
    row.add_prefix(&check);
    row.set_activatable_widget(Some(&check));
    (row, check)
}

struct Editor {
    name: adw::EntryRow,
    account: adw::ComboRow,
    /// The accounts of the account choice after All accounts
    accounts: Vec<i64>,
    query: adw::EntryRow,
    count: adw::ActionRow,
    show: gtk::Button,
    move_it: gtk::CheckButton,
    move_to: gtk::DropDown,
    /// Every folder a rule can move to: (folder, account, label)
    all_targets: Vec<(i64, i64, String)>,
    /// The folders the folder choice offers now, the chosen account's (all for All accounts)
    targets: RefCell<Vec<i64>>,
    /// The count waiting for typing to stop
    counting: RefCell<Option<glib::SourceId>>,
    mark_read: gtk::CheckButton,
    flag: gtk::CheckButton,
    archive: gtk::CheckButton,
    junk: gtk::CheckButton,
    remove: gtk::CheckButton,
    quiet: gtk::CheckButton,
    apply_now: gtk::CheckButton,
}

impl Editor {
    fn chosen_account(&self) -> Option<i64> {
        let index = self.account.selected() as usize;
        index.checked_sub(1).and_then(|i| self.accounts.get(i).copied())
    }

    /// How many messages in the Inbox match the words typed now, or why a rule can not have them
    fn show_count(&self) {
        let query = self.query.text().trim().to_string();
        let core = &shell().core;
        let problem = core.rule_query_problem(&query);
        let text = match &problem {
            Some(problem) => problem.clone(),
            None => {
                let count = core.rule_matches(&query, self.chosen_account()).unwrap_or(0);
                t!(UiRuleCount, count = count)
            }
        };
        self.count.set_title(&glib::markup_escape_text(&text));
        self.show.set_sensitive(!query.is_empty() && problem.is_none());
    }

    /// The count again once typing stops for a moment, not at each key
    fn count_soon(self: &Rc<Self>) {
        if let Some(waiting) = self.counting.take() {
            waiting.remove();
        }
        let this = Rc::downgrade(self);
        let id = glib::timeout_add_local_once(std::time::Duration::from_millis(300), move || {
            if let Some(this) = this.upgrade() {
                this.counting.take();
                this.show_count();
            }
        });
        self.counting.replace(Some(id));
    }

    /// The folder choice with the chosen account's folders (every account's for All accounts), `keep` chosen when
    /// it is one of them
    fn fill_targets(&self, keep: Option<i64>) {
        let account = self.chosen_account();
        let shown: Vec<&(i64, i64, String)> = self
            .all_targets
            .iter()
            .filter(|(_, owner, _)| account.is_none_or(|a| a == *owner))
            .collect();
        let labels: Vec<&str> = shown.iter().map(|(_, _, label)| label.as_str()).collect();
        self.move_to.set_model(Some(&gtk::StringList::new(&labels)));
        let at = keep.and_then(|folder| shown.iter().position(|(id, _, _)| *id == folder));
        self.move_to.set_selected(at.unwrap_or(0) as u32);
        *self.targets.borrow_mut() = shown.iter().map(|(id, _, _)| *id).collect();
        self.move_it.set_sensitive(!shown.is_empty());
        if shown.is_empty() {
            self.move_it.set_active(false);
        }
    }

    fn rule(&self, id: RuleId, enabled: bool) -> Rule {
        let move_to = self
            .move_it
            .is_active()
            .then(|| self.targets.borrow().get(self.move_to.selected() as usize).copied())
            .flatten();
        Rule {
            id,
            enabled,
            name: self.name.text().trim().to_string(),
            account: self.chosen_account(),
            query: self.query.text().trim().to_string(),
            move_to,
            mark_read: self.mark_read.is_active(),
            flag: self.flag.is_active(),
            archive: self.archive.is_active(),
            junk: self.junk.is_active(),
            remove: self.remove.is_active(),
            quiet: self.quiet.is_active(),
        }
    }
}

/// The rule editor over `parent`: `rule` as it is (id 0 for a new one)
pub async fn editor(parent: &impl IsA<gtk::Widget>, rule: Rule) -> Outcome {
    let core = &shell().core;
    let accounts = core.accounts().unwrap_or_default();
    let titles = pe_core::account_titles(&accounts);
    let mut choices = vec![t!(UiRuleAllAccounts)];
    choices.extend(titles);
    let account_ids: Vec<i64> = accounts.iter().map(|a| a.id).collect();
    let general = adw::PreferencesGroup::new();
    let name = adw::EntryRow::builder()
        .title(field_title(Text::UiRuleName))
        .text(&rule.name)
        .build();
    name.set_widget_name("rule-name");
    let choice_refs: Vec<&str> = choices.iter().map(String::as_str).collect();
    let account = adw::ComboRow::builder()
        .title(field_title(Text::UiRuleAccount))
        .model(&gtk::StringList::new(&choice_refs))
        .build();
    account.set_widget_name("rule-account");
    let chosen = rule
        .account
        .and_then(|a| account_ids.iter().position(|id| *id == a))
        .map_or(0, |i| i + 1);
    account.set_selected(chosen as u32);
    let query = adw::EntryRow::builder()
        .title(field_title(Text::UiRuleQuery))
        .text(&rule.query)
        .build();
    query.set_widget_name("rule-query");
    let count = adw::ActionRow::builder()
        .subtitle(glib::markup_escape_text(&t!(UiRuleQueryHint)))
        .build();
    count.set_widget_name("rule-count");
    let show = gtk::Button::with_label(&plain(Text::UiRuleShow));
    show.set_valign(gtk::Align::Center);
    show.set_widget_name("rule-show");
    count.add_suffix(&show);
    general.add(&name);
    general.add(&account);
    general.add(&query);
    general.add(&count);
    let actions = adw::PreferencesGroup::builder()
        .title(field_title(Text::UiRuleActions))
        .build();
    let all_targets = core.rule_targets().unwrap_or_default();
    let move_to = gtk::DropDown::from_strings(&[]);
    move_to.set_valign(gtk::Align::Center);
    move_to.set_widget_name("rule-move-to");
    let (move_row, move_it) = check_row(&field_title(Text::UiRuleMove), "rule-move", rule.move_to.is_some());
    move_row.add_suffix(&move_to);
    // the folder is chosen for Move it to alone, as on Windows and the Mac
    move_it
        .bind_property("active", &move_to, "sensitive")
        .sync_create()
        .build();
    actions.add(&move_row);
    let add = |text: Text, name: &str, active: bool| {
        let (row, check) = check_row(&plain(text), name, active);
        actions.add(&row);
        check
    };
    let mark_read = add(Text::UiRuleMarkRead, "rule-mark-read", rule.mark_read);
    let flag = add(Text::UiRuleFlag, "rule-flag", rule.flag);
    let archive = add(Text::UiRuleArchive, "rule-archive", rule.archive);
    let junk = add(Text::UiRuleJunk, "rule-junk", rule.junk);
    let remove = add(Text::UiRuleDelete, "rule-delete", rule.remove);
    let quiet = add(Text::UiRuleQuiet, "rule-quiet", rule.quiet);
    let also = adw::PreferencesGroup::new();
    let (apply_row, apply_now) = check_row(&plain(Text::UiRuleApplyNow), "rule-apply-now", false);
    also.add(&apply_row);
    let content = gtk::Box::new(gtk::Orientation::Vertical, 18);
    content.set_margin_start(18);
    content.set_margin_end(18);
    content.set_margin_bottom(18);
    content.append(&general);
    content.append(&actions);
    content.append(&also);
    let editor = Rc::new(Editor {
        name,
        account,
        accounts: account_ids,
        query,
        count,
        show,
        move_it,
        move_to,
        all_targets,
        targets: RefCell::new(Vec::new()),
        counting: RefCell::new(None),
        mark_read,
        flag,
        archive,
        junk,
        remove,
        quiet,
        apply_now,
    });
    editor.fill_targets(rule.move_to);
    editor.show_count();
    let typed = Rc::downgrade(&editor);
    editor.query.connect_changed(move |_| {
        if let Some(editor) = typed.upgrade() {
            editor.count_soon();
        }
    });
    let chosen = Rc::downgrade(&editor);
    editor.account.connect_selected_notify(move |_| {
        if let Some(editor) = chosen.upgrade() {
            let kept = editor.targets.borrow().get(editor.move_to.selected() as usize).copied();
            editor.fill_targets(kept);
            editor.show_count();
        }
    });
    // a message goes to one place: ticking one of the moves unticks the others
    let places = [&editor.move_it, &editor.archive, &editor.junk, &editor.remove].map(|check| check.downgrade());
    for (at, place) in places.iter().enumerate() {
        let Some(check) = place.upgrade() else { continue };
        let others: Vec<_> = places
            .iter()
            .enumerate()
            .filter(|(k, _)| *k != at)
            .map(|(_, o)| o.clone())
            .collect();
        check.connect_toggled(move |check| {
            if check.is_active() {
                for other in others.iter().filter_map(|o| o.upgrade()) {
                    other.set_active(false);
                }
            }
        });
    }
    let scrolled = gtk::ScrolledWindow::builder()
        .child(&content)
        .hscrollbar_policy(gtk::PolicyType::Never)
        .propagate_natural_height(true)
        .max_content_height(640)
        .build();
    let (dialog, ok) = ui::dialog_with_buttons(&t!(UiRuleTitle), &scrolled, &t!(UiOk), 560);
    dialog.set_widget_name("rule-dialog");
    let (send, clicks) = async_channel::unbounded::<&'static str>();
    let closed = send.clone();
    dialog.connect_closed(move |_| {
        let _ = closed.try_send("cancel");
    });
    let shown = send.clone();
    editor.show.connect_clicked(move |_| {
        let _ = shown.try_send("show");
    });
    ok.connect_clicked(move |_| {
        let _ = send.try_send("ok");
    });
    dialog.present(Some(parent.as_ref()));
    if rule.name.is_empty() {
        editor.name.grab_focus();
    } else {
        editor.query.grab_focus();
    }
    let mut outcome = Outcome::Cancelled;
    while let Ok(click) = clicks.recv().await {
        match click {
            "ok" => {
                let edited = editor.rule(rule.id, rule.enabled || rule.id == 0);
                match core.save_rule(&edited) {
                    Ok(id) => {
                        if editor.apply_now.is_active() {
                            let _ = core.apply_rule_now(id);
                        }
                        outcome = Outcome::Saved;
                        break;
                    }
                    Err(reason) => {
                        ui::alert(&dialog, &t!(UiRuleTitle), &pe_core::sentence(&reason.to_string())).await;
                        editor.query.grab_focus();
                    }
                }
            }
            "show" => {
                show_matches(&editor.query.text());
                outcome = Outcome::Shown;
                break;
            }
            _ => break,
        }
    }
    dialog.close();
    outcome
}

/// The main window searching the Inboxes for what `query` matches, as typed into its search box
fn show_matches(query: &str) {
    let main = shell().main();
    main.find.set_text(&shell().core.rule_search_text(query.trim()));
    main.focus_find();
}

/// A new rule of `query`, named after it, in the editor over the main window
pub async fn create(query: &str) {
    let query = query.trim();
    let rule = Rule {
        enabled: true,
        name: query.to_string(),
        query: query.to_string(),
        ..Default::default()
    };
    let window = shell().main().window().clone();
    editor(&window, rule).await;
}

/// Message > Create Rule from Message: a new rule for the sender (or the mailing list) of the message selected
pub async fn from_message() {
    let main = shell().main();
    let (folder, uid) = match main.selected_refs().as_slice() {
        [one] => (one.folder, one.uid),
        _ => (main.reader.folder(), main.reader.uid()),
    };
    if uid == 0 {
        ui::alert(main.window(), &t!(UiRuleTitle), &t!(UiSelectMessageFirst)).await;
        return;
    }
    match shell().core.rule_query_of_message(folder, uid) {
        Ok(query) => create(&query).await,
        Err(reason) => ui::alert(main.window(), &t!(UiRuleTitle), &pe_core::sentence(&reason.to_string())).await,
    }
}

// ---- the Message Rules window ----

struct RulesWindow {
    list: gtk::ListBox,
    rules: RefCell<Vec<Rule>>,
    edit: gtk::Button,
    delete: gtk::Button,
    up: gtk::Button,
    down: gtk::Button,
}

impl RulesWindow {
    fn selected_index(&self) -> Option<usize> {
        usize::try_from(self.list.selected_row()?.index()).ok()
    }

    fn selected(&self) -> Option<Rule> {
        self.rules.borrow().get(self.selected_index()?).cloned()
    }

    /// Edit and Delete for a rule selected, Move Up and Down where it can go
    fn show_selected(&self) {
        let index = self.selected_index();
        let count = self.rules.borrow().len();
        self.edit.set_sensitive(index.is_some());
        self.delete.set_sensitive(index.is_some());
        self.up.set_sensitive(index.is_some_and(|i| i > 0));
        self.down.set_sensitive(index.is_some_and(|i| i + 1 < count));
    }

    /// A row per rule in their order, its check box on when it is on; `select` stays selected
    fn fill(self: &Rc<Self>, select: usize) {
        // the rows only: the list's first child can be its placeholder, the text of an empty list
        while let Some(row) = self.list.row_at_index(0) {
            self.list.remove(&row);
        }
        let rules = shell().core.rules().unwrap_or_default();
        for (index, rule) in rules.iter().enumerate() {
            let row = adw::ActionRow::builder()
                .title(glib::markup_escape_text(&rule.name))
                .subtitle(glib::markup_escape_text(&rule.query))
                .build();
            row.set_widget_name(&format!("rules-row-{index}"));
            let check = gtk::CheckButton::builder()
                .active(rule.enabled)
                .valign(gtk::Align::Center)
                .build();
            check.set_widget_name(&format!("rule-on-{index}"));
            check.update_property(&[gtk::accessible::Property::Label(&rule.name)]);
            let this = Rc::downgrade(self);
            let stored = rule.clone();
            check.connect_toggled(move |check| {
                let Some(this) = this.upgrade() else { return };
                let turned = Rule {
                    enabled: check.is_active(),
                    ..stored.clone()
                };
                match shell().core.save_rule(&turned) {
                    Ok(_) => {
                        if let Some(kept) = this.rules.borrow_mut().get_mut(index) {
                            kept.enabled = turned.enabled;
                        }
                    }
                    // not saved: the box back as it was, and why
                    Err(reason) => {
                        this.fill(index);
                        let list = this.list.clone();
                        glib::spawn_future_local(async move {
                            let text = pe_core::sentence(&reason.to_string());
                            ui::alert(&list, &t!(UiRuleTitle), &text).await;
                        });
                    }
                }
            });
            row.add_prefix(&check);
            self.list.append(&row);
        }
        let last = rules.len().saturating_sub(1);
        *self.rules.borrow_mut() = rules;
        self.list
            .select_row(self.list.row_at_index(select.min(last) as i32).as_ref());
        self.show_selected();
    }
}

/// Tools > Message Rules: the rules that sort new mail, to add, change, turn on and off, order and delete
pub async fn rules_dialog(parent: &impl IsA<gtk::Widget>) {
    let list = gtk::ListBox::new();
    list.add_css_class("boxed-list");
    list.set_widget_name("rules-list");
    let none = ui::wrapped_label(&t!(UiRulesNone));
    none.set_widget_name("rules-none");
    none.add_css_class("dim-label");
    none.set_margin_top(18);
    none.set_margin_bottom(18);
    none.set_margin_start(12);
    none.set_margin_end(12);
    list.set_placeholder(Some(&none));
    let (send, clicks) = async_channel::unbounded::<&'static str>();
    let button = |text: Text, id: &'static str| {
        let button = gtk::Button::with_label(&plain(text));
        button.set_widget_name(&format!("rules-{id}"));
        let send = send.clone();
        button.connect_clicked(move |_| {
            let _ = send.try_send(id);
        });
        button
    };
    let new = button(Text::UiRuleNew, "new");
    let edit = button(Text::UiRuleEdit, "edit");
    let delete = button(Text::UiRuleDeleteButton, "delete");
    let up = button(Text::UiAccountMoveUp, "up");
    let down = button(Text::UiAccountMoveDown, "down");
    let buttons = gtk::Box::new(gtk::Orientation::Vertical, 6);
    for button in [&new, &edit, &delete, &up, &down] {
        buttons.append(button);
    }
    let window = Rc::new(RulesWindow {
        list: list.clone(),
        rules: RefCell::default(),
        edit,
        delete,
        up,
        down,
    });
    window.fill(0);
    let selected = Rc::downgrade(&window);
    list.connect_row_selected(move |_, _| {
        if let Some(window) = selected.upgrade() {
            window.show_selected();
        }
    });
    let activated = send.clone();
    list.connect_row_activated(move |_, _| {
        let _ = activated.try_send("edit");
    });
    let keys = gtk::EventControllerKey::new();
    let deleted = send.clone();
    keys.connect_key_pressed(move |_, key, _, _| {
        if key == gdk::Key::Delete {
            let _ = deleted.try_send("delete");
            return glib::Propagation::Stop;
        }
        glib::Propagation::Proceed
    });
    list.add_controller(keys);
    let row = gtk::Box::new(gtk::Orientation::Horizontal, 12);
    let scrolled = gtk::ScrolledWindow::builder()
        .child(&list)
        .min_content_height(220)
        .hexpand(true)
        .hscrollbar_policy(gtk::PolicyType::Never)
        .build();
    row.append(&scrolled);
    row.append(&buttons);
    let content = gtk::Box::new(gtk::Orientation::Vertical, 12);
    content.set_margin_start(18);
    content.set_margin_end(18);
    content.set_margin_bottom(18);
    content.append(&ui::wrapped_label(&t!(UiRulesIntro)));
    content.append(&row);
    let view = adw::ToolbarView::new();
    view.add_top_bar(&adw::HeaderBar::new());
    view.set_content(Some(&content));
    let dialog = adw::Dialog::builder()
        .title(t!(UiRulesTitle))
        .content_width(640)
        .child(&view)
        .build();
    dialog.set_widget_name("rules-dialog");
    dialog.connect_closed(move |_| {
        let _ = send.try_send("close");
    });
    dialog.present(Some(parent.as_ref()));
    let host = dialog.clone().upcast::<gtk::Widget>();
    while let Ok(click) = clicks.recv().await {
        let index = window.selected_index().unwrap_or(0);
        let rule = window.selected();
        match click {
            "close" => break,
            "new" => {
                let fresh = Rule {
                    enabled: true,
                    ..Default::default()
                };
                match editor(&host, fresh).await {
                    Outcome::Saved => window.fill(usize::MAX),
                    Outcome::Shown => break,
                    Outcome::Cancelled => {}
                }
            }
            "edit" => {
                let Some(rule) = rule else { continue };
                match editor(&host, rule).await {
                    Outcome::Saved => window.fill(index),
                    Outcome::Shown => break,
                    Outcome::Cancelled => {}
                }
            }
            "delete" => {
                let Some(rule) = rule else { continue };
                let question = t!(UiRuleDeleteAsk, name = &*rule.name);
                if !ui::confirm(&host, &t!(UiRulesTitle), &question, true).await {
                    continue;
                }
                if let Err(reason) = shell().core.delete_rule(rule.id) {
                    ui::alert(&host, &t!(UiRulesTitle), &pe_core::sentence(&reason.to_string())).await;
                }
                window.fill(index);
            }
            "up" | "down" => {
                let Some(rule) = rule else { continue };
                let up = click == "up";
                if shell().core.move_rule(rule.id, up).unwrap_or(false) {
                    window.fill(if up { index.saturating_sub(1) } else { index + 1 });
                }
            }
            _ => {}
        }
    }
    dialog.close();
}
