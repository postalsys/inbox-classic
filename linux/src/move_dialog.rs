//! The Move and Copy window: the folders used last under "Recent", every account's folders as a tree, a box that
//! narrows it to the folders whose names match, and New Folder. The rows, their words, what can be chosen and what a
//! filter leaves all come from the core (`Core::move_targets`); this only shows them.

use std::cell::RefCell;
use std::rc::Rc;

use adw::prelude::*;
use gtk::glib;
use pe_core::{TargetKind, TargetRow};

use crate::app::shell;
use crate::ui;

/// What the window shows: its words, and the folder the messages are all in (None for several)
pub struct Request {
    pub title: String,
    pub prompt: String,
    /// "Move" or "Copy", the button that does it
    pub verb: String,
    pub current: Option<i64>,
}

thread_local! {
    /// The New Folder waiting for its folder ([`folder_created`])
    static CREATED: RefCell<Option<async_channel::Sender<Option<i64>>>> = const { RefCell::new(None) };
}

/// The core says a folder made is there: the window waiting for it highlights it
pub fn folder_created(folder: i64) {
    CREATED.with(|waiting| {
        if let Some(sender) = waiting.borrow_mut().take() {
            let _ = sender.try_send(Some(folder));
        }
    });
}

/// The list and the core's rows it shows, by index
struct Rows {
    list: gtk::ListBox,
    current: Option<i64>,
    shown: RefCell<Vec<TargetRow>>,
}

/// Shows the window over `parent` and waits: the folder chosen, None for Cancel
pub async fn choose(parent: &impl IsA<gtk::Widget>, request: Request) -> Option<i64> {
    let content = gtk::Box::new(gtk::Orientation::Vertical, 10);
    content.set_margin_start(18);
    content.set_margin_end(18);
    content.set_margin_top(6);
    content.set_margin_bottom(18);
    let prompt = ui::wrapped_label(&request.prompt);
    prompt.set_widget_name("move-prompt");
    content.append(&prompt);
    let filter = gtk::SearchEntry::new();
    filter.set_placeholder_text(Some(&t!(UiFindFolder)));
    filter.set_widget_name("move-filter");
    content.append(&filter);
    let list = gtk::ListBox::new();
    list.set_widget_name("move-folders");
    list.set_selection_mode(gtk::SelectionMode::Single);
    list.add_css_class("navigation-sidebar");
    let scrolled = gtk::ScrolledWindow::builder()
        .child(&list)
        .hscrollbar_policy(gtk::PolicyType::Never)
        .min_content_height(260)
        .max_content_height(380)
        .propagate_natural_height(true)
        .build();
    let frame = gtk::Frame::new(None);
    frame.set_child(Some(&scrolled));
    content.append(&frame);
    let new_folder = gtk::Button::with_label(&crate::words::plain(crate::words::Text::CmdNewFolder));
    new_folder.set_widget_name("move-new-folder");
    new_folder.set_halign(gtk::Align::Start);
    content.append(&new_folder);

    let (dialog, ok) = ui::dialog_with_buttons(&request.title, &content, &request.verb, 460);
    dialog.set_widget_name("move-dialog");
    let rows = Rc::new(Rows {
        list: list.clone(),
        current: request.current,
        shown: RefCell::default(),
    });
    rows.fill("", None);
    ok.set_sensitive(rows.chosen().is_some());

    let (send, answers) = async_channel::unbounded::<Option<i64>>();
    let answer = {
        let rows = rows.clone();
        let send = send.clone();
        move || {
            if let Some(id) = rows.chosen() {
                let _ = send.try_send(Some(id));
            }
        }
    };
    {
        let rows = rows.clone();
        let ok = ok.clone();
        list.connect_row_selected(move |_, _| ok.set_sensitive(rows.chosen().is_some()));
    }
    {
        let answer = answer.clone();
        list.connect_row_activated(move |_, _| answer());
    }
    {
        let answer = answer.clone();
        filter.connect_activate(move |_| answer());
    }
    ok.connect_clicked(move |_| answer());
    {
        let rows = rows.clone();
        filter.connect_search_changed(move |entry| rows.fill(&entry.text(), None));
    }
    {
        // Down goes from the box to the folders
        let list = list.clone();
        let keys = gtk::EventControllerKey::new();
        keys.connect_key_pressed(move |_, key, _, _| {
            if key == gtk::gdk::Key::Down
                && let Some(row) = list.selected_row()
            {
                row.grab_focus();
            }
            glib::Propagation::Proceed
        });
        filter.add_controller(keys);
    }
    dialog.connect_closed(move |_| {
        let _ = send.try_send(None);
    });
    {
        let rows = rows.clone();
        let dialog = dialog.clone();
        let filter = filter.clone();
        new_folder.connect_clicked(move |_| {
            let rows = rows.clone();
            let dialog = dialog.clone();
            let filter = filter.clone();
            crate::app::spawn(async move {
                if let Some(created) = make_folder(&dialog, &rows).await {
                    filter.set_text("");
                    rows.fill("", Some(created));
                }
            });
        });
    }
    dialog.present(Some(parent));
    filter.grab_focus();
    let chosen = answers.recv().await.ok().flatten();
    dialog.close();
    chosen
}

/// New Folder in the folder highlighted (or at the top of its account): asks the name, has the core make it, and waits
/// for the core to say it is there. Its id, None when cancelled, refused or it did not come.
async fn make_folder(dialog: &adw::Dialog, rows: &Rows) -> Option<i64> {
    let (account, parent, name) = rows.highlighted()?;
    let intro = if parent.is_some() {
        t!(UiNewFolderIn, folder = &*name)
    } else {
        t!(GtkNewFolderAtTopOf, account = &*name)
    };
    let folder = ui::ask_folder_name(dialog, &t!(UiNewFolderTitle), &intro, "").await?;
    let (sender, created) = async_channel::bounded(1);
    CREATED.with(|waiting| *waiting.borrow_mut() = Some(sender.clone()));
    if let Err(reason) = shell().core.create_folder(account, parent, &folder) {
        CREATED.with(|waiting| waiting.borrow_mut().take());
        ui::alert(dialog, ui::TITLE, &reason.to_string()).await;
        return None;
    }
    // a server that does not make it says why on its own (Failed): not waited for long
    glib::timeout_add_local_once(std::time::Duration::from_secs(20), move || {
        let _ = sender.try_send(None);
    });
    let made = created.recv().await.ok().flatten();
    CREATED.with(|waiting| waiting.borrow_mut().take());
    made
}

impl Rows {
    /// The list built again from the core's rows for `filter`; `prefer` highlighted (a folder made), or the first of
    /// Recent, or the first folder that can be chosen
    fn fill(&self, filter: &str, prefer: Option<i64>) {
        while let Some(row) = self.list.row_at_index(0) {
            self.list.remove(&row);
        }
        let shown = shell().core.move_targets(self.current, filter).unwrap_or_default();
        for target in &shown {
            self.list.append(&target_row(target, self.current));
        }
        let index = prefer
            .and_then(|id| shown.iter().position(|t| t.folder == id && t.choosable))
            .or_else(|| shown.iter().position(|t| t.choosable));
        *self.shown.borrow_mut() = shown;
        match index.and_then(|i| self.list.row_at_index(i as i32)) {
            Some(row) => self.list.select_row(Some(&row)),
            None => self.list.unselect_all(),
        }
    }

    fn highlighted_row(&self) -> Option<TargetRow> {
        let index = self.list.selected_row()?.index();
        self.shown.borrow().get(usize::try_from(index).ok()?).cloned()
    }

    /// Where New Folder makes it: the account, the folder highlighted (None for the account's top), and its name
    fn highlighted(&self) -> Option<(i64, Option<i64>, String)> {
        let row = self.highlighted_row()?;
        match row.kind {
            TargetKind::Heading => None,
            TargetKind::Account => Some((row.account, None, row.label)),
            TargetKind::Folder | TargetKind::Recent => Some((row.account, Some(row.folder), row.label)),
        }
    }

    /// The folder highlighted, when messages can go there
    fn chosen(&self) -> Option<i64> {
        self.highlighted_row().filter(|r| r.choosable).map(|r| r.folder)
    }
}

/// A row of the list: a heading, or an account or folder with its icon, set in by its depth; one messages can not go
/// to dimmed, an account in bold (it can be highlighted, for New Folder at its top)
fn target_row(target: &TargetRow, current: Option<i64>) -> gtk::ListBoxRow {
    let row = gtk::ListBoxRow::new();
    if target.kind == TargetKind::Heading {
        let label = gtk::Label::new(Some(&target.label));
        label.set_halign(gtk::Align::Start);
        label.add_css_class("dim-label");
        label.add_css_class("caption-heading");
        label.set_margin_top(6);
        label.set_margin_start(6);
        row.set_child(Some(&label));
        row.set_selectable(false);
        row.set_activatable(false);
        row.set_can_focus(false);
        return row;
    }
    let line = gtk::Box::new(gtk::Orientation::Horizontal, 8);
    line.set_margin_start(6 + 18 * target.depth as i32);
    let icon = if target.kind == TargetKind::Account {
        "ic-mailbox-symbolic"
    } else {
        kind_icon(target.icon)
    };
    let text = gtk::Label::new(Some(&target.label));
    text.set_halign(gtk::Align::Start);
    text.set_ellipsize(gtk::pango::EllipsizeMode::End);
    if target.kind == TargetKind::Account {
        text.add_css_class("heading");
    } else if !target.choosable {
        line.add_css_class("dim-label");
    }
    line.append(&gtk::Image::from_icon_name(icon));
    line.append(&text);
    row.set_child(Some(&line));
    row.set_widget_name(&match target.kind {
        TargetKind::Account => format!("move-account-{}", target.account),
        TargetKind::Recent => format!("move-recent-{}", target.folder),
        _ => format!("move-folder-{}", target.folder),
    });
    // a folder that holds no messages can not even be highlighted; the one they are in can, for New Folder in it
    let is_current = target.kind == TargetKind::Folder && Some(target.folder) == current;
    row.set_selectable(target.kind == TargetKind::Account || target.choosable || is_current);
    row.set_activatable(target.choosable);
    row
}

/// The icon of a folder by what the core says it is for (`folder_kind`)
fn kind_icon(kind: &str) -> &'static str {
    match kind {
        "inbox" => "ic-mail-inbox-symbolic",
        "sent" => "ic-send-symbolic",
        "drafts" => "ic-drafts-symbolic",
        "deleted" => "ic-delete-symbolic",
        "junk" => "ic-mail-prohibited-symbolic",
        "archive" => "ic-archive-symbolic",
        _ => "ic-folder-symbolic",
    }
}
