//! Notifications and the dock: a notification when new mail comes in (a click on it opens the message), the note
//! about the tray, and the count of unread messages in the Inboxes on the app's dock icon through the
//! `com.canonical.Unity.LauncherEntry` signal that Ubuntu's dock shows. Nothing here reads mail: the core gives the
//! count and the words.

use std::collections::HashMap;
use std::sync::mpsc;

use gtk::gio;
use gtk::prelude::*;

/// A notification that a click on opens the message `uid` of `folder`
pub fn new_mail(application: &adw::Application, title: &str, text: &str, folder: i64, uid: u64) {
    #[cfg(feature = "e2e")]
    SENT.with(|sent| sent.borrow_mut().push((title.to_string(), text.to_string())));
    let notification = gio::Notification::new(title);
    notification.set_body(Some(text));
    notification.set_default_action_and_target_value("app.show-message", Some(&(folder, uid).to_variant()));
    application.send_notification(Some("new-mail"), &notification);
}

#[cfg(feature = "e2e")]
thread_local! {
    /// The notifications of new mail sent, as (title, text), for the UI test
    pub static SENT: std::cell::RefCell<Vec<(String, String)>> = const { std::cell::RefCell::new(Vec::new()) };
}

/// A notification that a click on brings the window back
pub fn note(application: &adw::Application, title: &str, text: &str) {
    let notification = gio::Notification::new(title);
    notification.set_body(Some(text));
    notification.set_default_action("app.open");
    application.send_notification(Some("note"), &notification);
}

/// "No unread messages", "1 unread message", "3 unread messages": the tray's tooltip
pub fn unread_text(unread: u64) -> String {
    t!(GtkUnreadMessages, count = unread)
}

thread_local! {
    /// The thread that tells the dock, started with the first count
    static DOCK: std::cell::RefCell<Option<mpsc::Sender<u64>>> = const { std::cell::RefCell::new(None) };
}

/// The count on the dock icon, none for 0. Sent from a thread of its own so a slow session bus never holds up the
/// window
pub fn show_unread(unread: u64) {
    DOCK.with(|dock| {
        let mut dock = dock.borrow_mut();
        let sender = dock.get_or_insert_with(start_dock);
        if sender.send(unread).is_err() {
            *dock = None;
        }
    });
}

fn start_dock() -> mpsc::Sender<u64> {
    let (send, counts) = mpsc::channel::<u64>();
    std::thread::Builder::new()
        .name("dock".into())
        .spawn(move || {
            let Ok(connection) = zbus::blocking::Connection::session() else {
                return;
            };
            let app = format!("application://{}.desktop", crate::APP_ID);
            let mut last = None;
            while let Ok(mut unread) = counts.recv() {
                // only the newest of what queued up
                while let Ok(newer) = counts.try_recv() {
                    unread = newer;
                }
                if last == Some(unread) {
                    continue;
                }
                last = Some(unread);
                let count = i64::try_from(unread).unwrap_or(i64::MAX);
                let mut properties: HashMap<&str, zbus::zvariant::Value> = HashMap::new();
                properties.insert("count", count.into());
                properties.insert("count-visible", (unread > 0).into());
                let _ = connection.emit_signal(
                    None::<zbus::names::BusName>,
                    "/com/inboxclassic/InboxClassic/LauncherEntry",
                    "com.canonical.Unity.LauncherEntry",
                    "Update",
                    &(app.as_str(), properties),
                );
            }
        })
        .ok();
    send
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn unread_words() {
        assert_eq!(unread_text(0), "No unread messages");
        assert_eq!(unread_text(1), "1 unread message");
        assert_eq!(unread_text(12), "12 unread messages");
    }
}
