//! AI agents: the questions only the user answers (a program that connects for the first time, every message an
//! agent wants to send) and Tools > AI Agents, with the programs let in and what agents did. The rules, the words and
//! what the answers do are the core's (pe-core agents.rs); these windows show them and pass the answers on.

use std::cell::RefCell;
use std::rc::Rc;

use adw::prelude::*;
use gtk::glib;
use pe_core::agents::{self, AgentAnswer, AgentAsk, AgentLevels, LEVELS};

use crate::app::{shell, spawn};
use crate::ui;

/// What a program may do: the four levels and the accounts, for the first question and for Change
struct AccessForm {
    widget: gtk::Box,
    levels: Vec<gtk::CheckButton>,
    accounts: Vec<(i64, gtk::CheckButton)>,
}

impl AccessForm {
    fn new(path: &str, levels: AgentLevels, has: impl Fn(i64) -> bool) -> Rc<AccessForm> {
        let widget = gtk::Box::new(gtk::Orientation::Vertical, 6);
        let program = gtk::Label::new(Some(&format!("Program: {path}")));
        program.set_xalign(0.0);
        program.set_ellipsize(gtk::pango::EllipsizeMode::Middle);
        program.set_tooltip_text(Some(path));
        program.add_css_class("dim-label");
        program.add_css_class("caption");
        program.set_widget_name("agent-path");
        widget.append(&program);
        let heading = |text: &str| {
            let label = gtk::Label::new(Some(text));
            label.set_xalign(0.0);
            label.add_css_class("heading");
            label.set_margin_top(10);
            label
        };
        widget.append(&heading("It may"));
        let mut boxes = Vec::new();
        for (index, (bit, label)) in LEVELS.iter().enumerate() {
            let check = gtk::CheckButton::with_label(label);
            check.set_active(levels.has(*bit));
            check.set_widget_name(&format!("agent-level-{index}"));
            widget.append(&check);
            boxes.push(check);
        }
        widget.append(&heading("Accounts it may use"));
        let mut accounts = Vec::new();
        for account in shell().core.accounts().unwrap_or_default() {
            let label = pe_core::account_label(&account.settings.name, &account.settings.email);
            let check = gtk::CheckButton::with_label(&label);
            check.set_active(has(account.id));
            widget.append(&check);
            accounts.push((account.id, check));
        }
        let form = Rc::new(AccessForm {
            widget,
            levels: boxes,
            accounts,
        });
        // reading is what everything else builds on: without it the rest goes too
        let weak = Rc::downgrade(&form);
        form.levels[0].connect_toggled(move |read| {
            if let (false, Some(form)) = (read.is_active(), weak.upgrade()) {
                form.levels.iter().for_each(|level| level.set_active(false));
            }
        });
        form
    }

    /// The levels checked (none without reading) and the accounts ticked
    fn chosen(&self) -> (AgentLevels, Vec<i64>) {
        let mut levels = 0;
        for ((bit, _), check) in LEVELS.iter().zip(&self.levels) {
            if check.is_active() {
                levels |= bit;
            }
        }
        let accounts = self
            .accounts
            .iter()
            .filter(|(_, check)| check.is_active())
            .map(|(id, _)| *id)
            .collect();
        (AgentLevels(levels), accounts)
    }
}

/// An alert of a question, with `extra` under its words; the answers (id, label), the one Esc and Enter give first
fn question_dialog(
    heading: &str,
    body: &str,
    extra: &impl IsA<gtk::Widget>,
    answers: &[(&str, &str)],
    name: &str,
) -> adw::AlertDialog {
    let dialog = adw::AlertDialog::new(Some(heading), Some(body));
    for (id, label) in answers {
        dialog.add_response(id, label);
    }
    // the safe answer is the default: Enter does not let a program in or send
    dialog.set_default_response(Some(answers[0].0));
    dialog.set_close_response(answers[0].0);
    dialog.set_extra_child(Some(extra));
    dialog.set_prefer_wide_layout(true);
    dialog.set_widget_name(name);
    dialog
}

/// A question of an AI agent for the user (the AgentAsk event)
pub async fn question(request: u64) {
    let core = shell().core.clone();
    let window = shell().main().window().clone();
    match core.agent_ask(request) {
        Some(AgentAsk::Connect { host, .. }) => {
            let (heading, body) = agents::connect_text(&host);
            let form = AccessForm::new(&host.path, AgentLevels::DEFAULT, |_| true);
            let dialog = question_dialog(
                &heading,
                &body,
                &form.widget,
                &[("deny", "Don\u{2019}t Allow"), ("allow", "Allow")],
                "agent-connect",
            );
            dialog.set_response_appearance("allow", adw::ResponseAppearance::Suggested);
            let answer = dialog.choose_future(Some(&window)).await;
            let (levels, accounts) = form.chosen();
            let answer = if answer == "allow" {
                AgentAnswer::Allow { levels, accounts }
            } else {
                AgentAnswer::Deny
            };
            let _ = core.agent_answer(request, answer);
        }
        Some(AgentAsk::Send(ask)) => {
            let text = agents::send_text(&ask);
            let extra = send_details(&ask, &text);
            let dialog = question_dialog(
                &text.title,
                &text.detail,
                &extra,
                &[
                    ("dont", "Don\u{2019}t Send"),
                    ("compose", "Edit First"),
                    ("send", "Send"),
                ],
                "agent-send",
            );
            dialog.set_response_appearance("send", adw::ResponseAppearance::Suggested);
            // Send comes on after a moment, so a key pressed for another window does not send
            dialog.set_response_enabled("send", false);
            let later = dialog.downgrade();
            glib::timeout_add_local_once(std::time::Duration::from_millis(1500), move || {
                if let Some(dialog) = later.upgrade() {
                    dialog.set_response_enabled("send", true);
                }
            });
            let answer = match dialog.choose_future(Some(&window)).await.as_str() {
                "send" => AgentAnswer::Send,
                "compose" => AgentAnswer::Compose,
                _ => AgentAnswer::DontSend,
            };
            if let Ok(Some(draft)) = core.agent_answer(request, answer) {
                shell().open_draft(ask.account, draft);
            }
        }
        None => {}
    }
}

/// The message as it would go: every recipient on a row of its own, address first, so a name can not hide where it
/// goes; the subject, the text and the files
fn send_details(ask: &agents::SendAsk, text: &agents::SendText) -> gtk::Box {
    let content = gtk::Box::new(gtk::Orientation::Vertical, 8);
    if !text.warning.is_empty() {
        let warning = gtk::Label::new(Some(&text.warning));
        warning.set_xalign(0.0);
        warning.add_css_class("error");
        warning.add_css_class("heading");
        warning.set_widget_name("agent-warning");
        content.append(&warning);
    }
    let grid = gtk::Grid::builder().row_spacing(6).column_spacing(10).build();
    let mut row = 0;
    let mut line = |label: &str, cells: &[gtk::Widget]| {
        let key = gtk::Label::new(Some(label));
        key.set_xalign(1.0);
        key.add_css_class("dim-label");
        let values = gtk::Box::new(gtk::Orientation::Horizontal, 8);
        for cell in cells {
            values.append(cell);
        }
        grid.attach(&key, 0, row, 1, 1);
        grid.attach(&values, 1, row, 1, 1);
        row += 1;
    };
    let plain = |text: &str| -> gtk::Widget { ui::wrapped_label(text).upcast() };
    line("From:", &[plain(&ask.from)]);
    for (index, recipient) in ask.recipients.iter().enumerate() {
        let address = gtk::Label::new(Some(&recipient.address));
        address.add_css_class("heading");
        address.set_widget_name(&format!("agent-recipient-{index}"));
        let mut cells: Vec<gtk::Widget> = vec![address.upcast()];
        if !recipient.name.is_empty() {
            let name = gtk::Label::new(Some(&recipient.name));
            name.add_css_class("dim-label");
            cells.push(name.upcast());
        }
        if recipient.new {
            let tag = gtk::Label::new(Some("New address"));
            tag.add_css_class("new-address");
            tag.set_valign(gtk::Align::Center);
            cells.push(tag.upcast());
        }
        line(&format!("{}:", recipient.field), &cells);
    }
    line("Subject:", &[plain(&ask.subject)]);
    if !text.original.is_empty() {
        let original = gtk::Label::new(Some(&text.original));
        original.add_css_class("dim-label");
        line("", &[original.upcast()]);
    }
    content.append(&grid);
    let body = gtk::TextView::new();
    body.set_editable(false);
    body.set_wrap_mode(gtk::WrapMode::WordChar);
    body.buffer().set_text(&ask.text);
    body.set_left_margin(8);
    body.set_top_margin(8);
    body.set_widget_name("agent-body");
    let scrolled = gtk::ScrolledWindow::builder()
        .child(&body)
        .min_content_height(180)
        .min_content_width(480)
        .build();
    scrolled.add_css_class("card");
    content.append(&scrolled);
    let files = agents::files_text(ask);
    if !files.is_empty() {
        let label = gtk::Label::new(Some(&files));
        label.set_xalign(0.0);
        label.add_css_class("dim-label");
        content.append(&label);
    }
    content
}

// ---- Tools > AI Agents ----

/// What a button of the window does, given the window
type Act = fn(Rc<AgentsDialog>) -> std::pin::Pin<Box<dyn std::future::Future<Output = ()>>>;

thread_local! {
    static OPEN: RefCell<Option<Rc<AgentsDialog>>> = const { RefCell::new(None) };
}

/// What agents did changed: the open window shows it
pub fn refresh() {
    if let Some(dialog) = OPEN.with(|open| open.borrow().clone()) {
        dialog.fill();
    }
}

struct AgentsDialog {
    dialog: adw::Dialog,
    enabled: adw::SwitchRow,
    hosts: gtk::ListBox,
    log: gtk::ListBox,
    host_ids: RefCell<Vec<i64>>,
    entries: RefCell<Vec<(i64, bool)>>,
    change: gtk::Button,
    remove: gtk::Button,
    undo: gtk::Button,
    clear: gtk::Button,
}

impl AgentsDialog {
    fn fill(&self) {
        let core = &shell().core;
        self.enabled.set_active(core.agents_enabled().unwrap_or(false));
        let selected = |list: &gtk::ListBox| list.selected_row().map_or(0, |row| row.index().max(0));
        let (host_row, log_row) = (selected(&self.hosts), selected(&self.log));
        self.hosts.remove_all();
        let hosts = core.agent_hosts().unwrap_or_default();
        for host in &hosts {
            let used = host
                .last_used
                .map_or("Never used".into(), |at| format!("Last used {}", ui::format_date(at)));
            // plain text: nothing in a program's name or a subject is read as markup
            let row = adw::ActionRow::builder()
                .use_markup(false)
                .title(&host.name)
                .subtitle(format!("{}  \u{00B7}  {used}", agents::access_text(host)))
                .build();
            row.set_widget_name("agents-host");
            self.hosts.append(&row);
        }
        *self.host_ids.borrow_mut() = hosts.iter().map(|h| h.id).collect();
        self.log.remove_all();
        let log = core.agent_log(500).unwrap_or_default();
        for entry in &log {
            let summary = agents::log_text(entry);
            let row = adw::ActionRow::builder()
                .use_markup(false)
                .title(&summary)
                .subtitle(format!("{}  \u{00B7}  {}", ui::format_date(entry.at), entry.host_name))
                .build();
            row.set_widget_name("agents-entry");
            self.log.append(&row);
        }
        *self.entries.borrow_mut() = log
            .iter()
            .map(|e| (e.id, e.entry.undo.is_some() && !e.undone))
            .collect();
        if !hosts.is_empty() {
            self.hosts
                .select_row(self.hosts.row_at_index(host_row.min(hosts.len() as i32 - 1)).as_ref());
        }
        if !log.is_empty() {
            self.log
                .select_row(self.log.row_at_index(log_row.min(log.len() as i32 - 1)).as_ref());
        }
        self.update_buttons();
    }

    fn update_buttons(&self) {
        let host = self.hosts.selected_row().is_some();
        self.change.set_sensitive(host);
        self.remove.set_sensitive(host);
        let entry = self.log.selected_row().map(|row| row.index().max(0) as usize);
        self.undo
            .set_sensitive(entry.is_some_and(|index| self.entries.borrow().get(index).is_some_and(|(_, can)| *can)));
        self.clear.set_sensitive(!self.entries.borrow().is_empty());
    }

    fn selected_host(&self) -> Option<i64> {
        let index = self.hosts.selected_row()?.index().max(0) as usize;
        self.host_ids.borrow().get(index).copied()
    }

    async fn change_host(self: Rc<Self>) {
        let Some(id) = self.selected_host() else { return };
        let core = shell().core.clone();
        let Ok(Some(host)) = core.agent_host(id) else { return };
        let levels = if host.allowed {
            host.levels
        } else {
            AgentLevels::DEFAULT
        };
        let form = AccessForm::new(&host.path, levels, |account| host.accounts.contains(&account));
        let (heading, body) = agents::change_text(&host);
        let dialog = question_dialog(
            &heading,
            &body,
            &form.widget,
            &[("cancel", "Cancel"), ("away", "Turn Away"), ("allow", "Allow")],
            "agent-access",
        );
        dialog.set_response_appearance("allow", adw::ResponseAppearance::Suggested);
        dialog.set_response_appearance("away", adw::ResponseAppearance::Destructive);
        let answer = dialog.choose_future(Some(&self.dialog)).await;
        let (levels, accounts) = form.chosen();
        match answer.as_str() {
            "allow" => {
                let _ = core.update_agent_host(id, true, levels, &accounts);
            }
            "away" => {
                let _ = core.update_agent_host(id, false, AgentLevels(0), &[]);
            }
            _ => {}
        }
        self.fill();
    }

    async fn remove_host(self: Rc<Self>) {
        let Some(id) = self.selected_host() else { return };
        if ui::confirm(
            &self.dialog,
            "Forget this program?",
            "It is asked about again the next time it connects, and what its agents did is forgotten.",
            true,
        )
        .await
        {
            let _ = shell().core.remove_agent_host(id);
            self.fill();
        }
    }

    async fn undo_entry(self: Rc<Self>) {
        let Some(index) = self.log.selected_row().map(|row| row.index().max(0) as usize) else {
            return;
        };
        let Some((id, _)) = self.entries.borrow().get(index).copied() else {
            return;
        };
        if let Err(error) = shell().core.agent_undo(id) {
            ui::alert(&self.dialog, "AI Agents", &agents::undo_refusal(&error)).await;
        }
        self.fill();
    }

    async fn clear_log(self: Rc<Self>) {
        if ui::confirm(
            &self.dialog,
            "Clear the list of what agents did?",
            "What they did stays done.",
            false,
        )
        .await
        {
            let _ = shell().core.clear_agent_log();
            self.fill();
        }
    }
}

fn section(title: &str, list: &gtk::ListBox, buttons: &[&gtk::Button], height: i32) -> gtk::Box {
    let label = gtk::Label::new(Some(title));
    label.set_xalign(0.0);
    label.add_css_class("heading");
    let scrolled = gtk::ScrolledWindow::builder()
        .child(list)
        .min_content_height(height)
        .hexpand(true)
        .hscrollbar_policy(gtk::PolicyType::Never)
        .build();
    let side = gtk::Box::new(gtk::Orientation::Vertical, 6);
    for button in buttons {
        side.append(*button);
    }
    let row = gtk::Box::new(gtk::Orientation::Horizontal, 12);
    row.append(&scrolled);
    row.append(&side);
    let section = gtk::Box::new(gtk::Orientation::Vertical, 6);
    section.append(&label);
    section.append(&row);
    section
}

fn list(name: &str, empty: &str) -> gtk::ListBox {
    let list = gtk::ListBox::new();
    list.add_css_class("boxed-list");
    list.set_widget_name(name);
    let placeholder = gtk::Label::new(Some(empty));
    placeholder.set_margin_top(18);
    placeholder.set_margin_bottom(18);
    placeholder.add_css_class("dim-label");
    list.set_placeholder(Some(&placeholder));
    list
}

/// Tools > AI Agents
pub async fn agents_dialog(parent: &impl IsA<gtk::Widget>) {
    let button = |label: &str, name: &str| {
        let button = gtk::Button::with_label(label);
        button.set_widget_name(name);
        button
    };
    let enabled = adw::SwitchRow::builder()
        .title("Let AI agents connect to Inbox Classic")
        .build();
    enabled.set_widget_name("agents-enabled");
    let switch = gtk::ListBox::new();
    switch.add_css_class("boxed-list");
    switch.append(&enabled);
    let agents = Rc::new(AgentsDialog {
        dialog: adw::Dialog::builder()
            .title("AI Agents")
            .content_width(720)
            .content_height(620)
            .build(),
        enabled,
        hosts: list("agents-hosts", "No agent has asked to use your mail yet."),
        log: list("agents-log", "Nothing yet."),
        host_ids: RefCell::default(),
        entries: RefCell::default(),
        change: button("Change\u{2026}", "agents-change"),
        remove: button("Remove", "agents-remove"),
        undo: button("Undo", "agents-undo"),
        clear: button("Clear", "agents-clear"),
    });
    agents.dialog.set_widget_name("agents-dialog");
    let setup = button("How to Connect an Agent\u{2026}", "agents-setup");
    setup.add_css_class("flat");
    setup.set_halign(gtk::Align::Start);
    let content = gtk::Box::new(gtk::Orientation::Vertical, 18);
    content.set_margin_start(18);
    content.set_margin_end(18);
    content.set_margin_bottom(18);
    content.append(&switch);
    content.append(&section(
        "Programs whose agents asked to use your mail",
        &agents.hosts,
        &[&agents.change, &agents.remove],
        120,
    ));
    content.append(&section(
        "What agents did",
        &agents.log,
        &[&agents.undo, &agents.clear],
        220,
    ));
    content.append(&setup);
    let view = adw::ToolbarView::new();
    view.add_top_bar(&adw::HeaderBar::new());
    view.set_content(Some(&content));
    agents.dialog.set_child(Some(&view));
    agents.fill();

    agents.enabled.connect_active_notify(|row| {
        let _ = shell().core.set_agents_enabled(row.is_active());
    });
    let weak = Rc::downgrade(&agents);
    let update = move |_: &gtk::ListBox, _: Option<&gtk::ListBoxRow>| {
        if let Some(agents) = weak.upgrade() {
            agents.update_buttons();
        }
    };
    agents.hosts.connect_row_selected(update.clone());
    agents.log.connect_row_selected(update);
    let on = |button: &gtk::Button, act: Act| {
        let weak = Rc::downgrade(&agents);
        button.connect_clicked(move |_| {
            if let Some(agents) = weak.upgrade() {
                spawn(act(agents));
            }
        });
    };
    on(&agents.change, |a| Box::pin(a.change_host()));
    on(&agents.remove, |a| Box::pin(a.remove_host()));
    on(&agents.undo, |a| Box::pin(a.undo_entry()));
    on(&agents.clear, |a| Box::pin(a.clear_log()));
    let parent_window = agents.dialog.clone();
    setup.connect_clicked(move |_| {
        let store = shell().store_argument();
        let exe = std::env::current_exe()
            .map(|p| p.to_string_lossy().into_owned())
            .unwrap_or_default();
        let config = agents::mcp_config(&exe, store.as_deref());
        let dialog = ui::text_dialog(
            &parent_window,
            "Connect an AI Agent",
            "Add this to the MCP servers of your agent (Claude Desktop: Settings > Developer > Edit Config):",
            &config,
        );
        dialog.set_widget_name("agents-setup-dialog");
    });

    let (closed, wait) = async_channel::bounded::<()>(1);
    agents.dialog.connect_closed(move |_| {
        let _ = closed.try_send(());
    });
    OPEN.with(|open| *open.borrow_mut() = Some(agents.clone()));
    agents.dialog.present(Some(parent.as_ref()));
    let _ = wait.recv().await;
    OPEN.with(|open| open.borrow_mut().take());
}
