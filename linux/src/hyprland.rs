//! Omarchy's title bars. On a floating workspace Omarchy's Hyprland draws a title bar with its own close, maximize
//! and minimize buttons above every window (the hyprbars plugin), which GTK can not know: Hyprland tells every window
//! it is tiled, floating or not, and draws the bar without asking. Our header bars would show a second close button
//! under it. Hyprland's socket says which windows are on such a workspace (Omarchy tags them), so those windows'
//! header bars leave the buttons to the bar, and get them back when the window is tiled again.

use adw::prelude::*;
use gtk::glib;
use std::io::{BufRead, BufReader, Read, Write};
use std::os::unix::net::UnixStream;
use std::path::{Path, PathBuf};
use std::time::Duration;

/// The tag Omarchy gives every window of a floating workspace, which its title bars follow
const BARRED_TAG: &str = "omarchy-floating-workspace";

/// The events after which a window may have gone onto or off a floating workspace
const EVENTS: [&str; 6] = [
    "openwindow",
    "changefloatingmode",
    "movewindow",
    "movewindowv2",
    "workspace",
    "windowtitle",
];

/// Starts following Hyprland's events, when the app runs on Hyprland
pub fn watch() {
    if let Some(sockets) = sockets() {
        watch_in(&sockets);
    }
}

/// Follows the Hyprland whose sockets are in `sockets`
pub fn watch_in(sockets: &Path) {
    let (sender, receiver) = async_channel::unbounded::<()>();
    let events = sockets.join(".socket2.sock");
    std::thread::spawn(move || {
        let Ok(stream) = UnixStream::connect(events) else {
            return;
        };
        for line in BufReader::new(stream).lines() {
            let Ok(line) = line else { return };
            let name = line.split(">>").next().unwrap_or_default();
            if EVENTS.contains(&name) && sender.send_blocking(()).is_err() {
                return;
            }
        }
    });
    let requests = sockets.join(".socket.sock");
    glib::spawn_future_local(async move {
        update(&requests);
        while receiver.recv().await.is_ok() {
            // Omarchy floats a window and then tags it: the events of a moment come together, then the windows are asked
            while receiver.try_recv().is_ok() {}
            glib::timeout_future(Duration::from_millis(150)).await;
            while receiver.try_recv().is_ok() {}
            update(&requests);
        }
    });
}

/// Hyprland's sockets of this session
fn sockets() -> Option<PathBuf> {
    let instance = std::env::var_os("HYPRLAND_INSTANCE_SIGNATURE")?;
    let runtime = std::env::var_os("XDG_RUNTIME_DIR")?;
    Some(PathBuf::from(runtime).join("hypr").join(instance))
}

/// Each of our windows' header bars with or without their buttons, as Hyprland's windows have a title bar or not
fn update(requests: &Path) {
    let Some(clients) = ask(requests, "j/clients") else {
        return;
    };
    let barred = barred_titles(&clients, std::process::id());
    for window in gtk::Window::list_toplevels() {
        let Ok(window) = window.downcast::<gtk::Window>() else {
            continue;
        };
        let title = window.title().map(|title| title.to_string()).unwrap_or_default();
        set_layout(window.upcast_ref(), barred.contains(&title).then_some(":"));
    }
}

/// The buttons of every header bar in `widget`: `":"` none, `None` the desktop's
fn set_layout(widget: &gtk::Widget, layout: Option<&str>) {
    if let Some(header) = widget.downcast_ref::<adw::HeaderBar>()
        && header.decoration_layout().as_deref() != layout
    {
        header.set_decoration_layout(layout);
    }
    let mut child = widget.first_child();
    while let Some(widget) = child {
        set_layout(&widget, layout);
        child = widget.next_sibling();
    }
}

/// One request on Hyprland's socket, its answer; none when it does not answer at once
fn ask(socket: &Path, request: &str) -> Option<String> {
    let mut stream = UnixStream::connect(socket).ok()?;
    stream.set_read_timeout(Some(Duration::from_millis(300))).ok()?;
    stream.set_write_timeout(Some(Duration::from_millis(300))).ok()?;
    stream.write_all(request.as_bytes()).ok()?;
    let mut answer = String::new();
    stream.read_to_string(&mut answer).ok()?;
    Some(answer)
}

/// The titles of this process's windows that have Omarchy's title bar, from the answer to `j/clients`
pub fn barred_titles(clients: &str, pid: u32) -> Vec<String> {
    let Ok(serde_json::Value::Array(clients)) = serde_json::from_str::<serde_json::Value>(clients) else {
        return Vec::new();
    };
    clients
        .iter()
        .filter(|client| client["pid"].as_u64() == Some(u64::from(pid)))
        .filter(|client| {
            client["tags"].as_array().is_some_and(|tags| {
                tags.iter()
                    .any(|tag| tag.as_str().map(|tag| tag.trim_end_matches('*')) == Some(BARRED_TAG))
            })
        })
        .filter_map(|client| client["title"].as_str().map(str::to_string))
        .collect()
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn a_window_on_a_floating_workspace_has_the_bar() {
        let clients = r#"[
            {"pid": 42, "title": "Inbox Classic", "floating": true, "tags": ["omarchy-floating-workspace*", "omarchy-mode-floated*"]},
            {"pid": 42, "title": "New Message", "floating": false, "tags": []},
            {"pid": 7, "title": "Files", "floating": true, "tags": ["omarchy-floating-workspace*"]}
        ]"#;
        assert_eq!(barred_titles(clients, 42), vec!["Inbox Classic".to_string()]);
        assert!(barred_titles(clients, 8).is_empty());
    }

    #[test]
    fn an_answer_that_is_not_the_list_bars_nothing() {
        assert!(barred_titles("unknown request", 42).is_empty());
        assert!(barred_titles(r#"[{"pid": 42, "title": "Inbox Classic"}]"#, 42).is_empty());
    }
}
