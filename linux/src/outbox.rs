//! Tools > Outbox: the messages that wait to be sent, with why the last try did not work; Send All Now, Delete. What
//! is in the Outbox comes from the core as it stores it; this window only lists it.

use std::cell::RefCell;

use adw::prelude::*;
use gtk::{gdk, glib};

use crate::app::shell;
use crate::ui;

/// A row per message: subject, recipients, when it was queued, and whether it waits or why it did not go; the ids by
/// row
fn fill(list: &gtk::ListBox, ids: &RefCell<Vec<i64>>, select: usize, buttons: &[&gtk::Button]) {
    // the rows only: the list's first child can be its placeholder, the text of an empty Outbox
    while let Some(row) = list.row_at_index(0) {
        list.remove(&row);
    }
    let queued = shell().core.outbox().unwrap_or_default();
    let no_subject = t!(UiNoSubject);
    for message in &queued {
        let subject = if message.subject.is_empty() {
            &no_subject
        } else {
            &message.subject
        };
        // one an AI agent sent waits a moment, while it can still be deleted; the user's while Undo takes it back
        let status = match (&message.problem, message.not_before) {
            (Some(problem), _) => t!(UiOutboxStatusNotSent, reason = problem),
            (None, Some(at)) if message.undoable => t!(UiOutboxStatusUndo, time = &ui::format_time(at)),
            (None, Some(at)) => t!(UiOutboxStatusAgent, time = &ui::format_time(at)),
            (None, None) => t!(UiOutboxStatusWaiting),
        };
        let row = adw::ActionRow::builder()
            .title(glib::markup_escape_text(subject))
            .subtitle(glib::markup_escape_text(&t!(
                GtkOutboxRow,
                to = &message.recipients,
                queued = &ui::format_date(message.created),
                status = &status
            )))
            .subtitle_lines(2)
            .build();
        list.append(&row);
    }
    *ids.borrow_mut() = queued.iter().map(|q| q.id).collect();
    let last = queued.len().saturating_sub(1);
    list.select_row(list.row_at_index(select.min(last) as i32).as_ref());
    // nothing to send or delete in an empty Outbox
    for button in buttons {
        button.set_sensitive(!queued.is_empty());
    }
}

pub async fn outbox_dialog(parent: &impl IsA<gtk::Widget>) {
    let list = gtk::ListBox::new();
    list.add_css_class("boxed-list");
    list.set_widget_name("outbox-list");
    let placeholder = gtk::Label::new(Some(&t!(GtkOutboxEmpty)));
    placeholder.set_margin_top(24);
    placeholder.set_margin_bottom(24);
    placeholder.add_css_class("dim-label");
    list.set_placeholder(Some(&placeholder));
    let ids = RefCell::new(Vec::new());
    let (send, clicks) = async_channel::unbounded::<&'static str>();
    let button = |label: &str, id: &'static str| {
        let button = gtk::Button::with_label(label);
        button.set_widget_name(&format!("outbox-{id}"));
        let send = send.clone();
        button.connect_clicked(move |_| {
            let _ = send.try_send(id);
        });
        button
    };
    let send_now = button(&crate::words::plain(crate::words::Text::UiOutboxSendAll), "send");
    let delete = button(&t!(UiTbDelete), "delete");
    fill(&list, &ids, 0, &[&send_now, &delete]);
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
    let buttons = gtk::Box::new(gtk::Orientation::Vertical, 6);
    buttons.append(&send_now);
    buttons.append(&delete);
    let scrolled = gtk::ScrolledWindow::builder()
        .child(&list)
        .min_content_height(220)
        .hexpand(true)
        .hscrollbar_policy(gtk::PolicyType::Never)
        .build();
    let content = gtk::Box::new(gtk::Orientation::Horizontal, 12);
    content.set_margin_start(18);
    content.set_margin_end(18);
    content.set_margin_bottom(18);
    content.append(&scrolled);
    content.append(&buttons);
    let view = adw::ToolbarView::new();
    view.add_top_bar(&adw::HeaderBar::new());
    view.set_content(Some(&content));
    let dialog = adw::Dialog::builder()
        .title(t!(UiOutboxTitle))
        .content_width(680)
        .child(&view)
        .build();
    dialog.set_widget_name("outbox-dialog");
    dialog.connect_closed(move |_| {
        let _ = send.try_send("close");
    });
    dialog.present(Some(parent.as_ref()));
    while let Ok(click) = clicks.recv().await {
        match click {
            "send" => {
                let _ = shell().core.outbox_send();
                break;
            }
            "delete" => {
                let index = list.selected_row().map_or(0, |row| row.index().max(0) as usize);
                let Some(id) = ids.borrow().get(index).copied() else {
                    continue;
                };
                if ui::confirm(&dialog, &t!(UiOutboxTitle), &t!(UiOutboxDeleteAsk), true).await {
                    let _ = shell().core.outbox_delete(id);
                    // the next one selected, where the deleted one was
                    fill(&list, &ids, index, &[&send_now, &delete]);
                }
            }
            _ => break,
        }
    }
    dialog.close();
}
