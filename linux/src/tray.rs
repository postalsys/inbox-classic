//! The icon in the top bar (a StatusNotifierItem, which Ubuntu's AppIndicator extension shows): its tooltip says how
//! many messages are unread in the Inboxes, its menu has Open Inbox Classic, Check for New Mail, Notify of New Mail
//! and Quit. Where the desktop has no place for it there is no icon, and closing the window ends the app.

use ksni::blocking::TrayMethods;

use crate::app::{run_command, shell, spawn};
use crate::commands::Command;
use crate::notify::unread_text;

struct Icon {
    unread: u64,
    notify: bool,
    /// The menu's commands, to the window thread
    commands: async_channel::Sender<Command>,
}

impl Icon {
    fn send(&self, command: Command) {
        let _ = self.commands.try_send(command);
    }
}

impl ksni::Tray for Icon {
    fn id(&self) -> String {
        crate::APP_ID.into()
    }

    fn title(&self) -> String {
        crate::ui::TITLE.into()
    }

    fn icon_name(&self) -> String {
        crate::APP_ID.into()
    }

    fn tool_tip(&self) -> ksni::ToolTip {
        ksni::ToolTip {
            title: crate::ui::TITLE.into(),
            description: unread_text(self.unread),
            ..Default::default()
        }
    }

    fn activate(&mut self, _x: i32, _y: i32) {
        self.send(Command::Open);
    }

    fn menu(&self) -> Vec<ksni::MenuItem<Self>> {
        use ksni::menu::{CheckmarkItem, StandardItem};
        let item = |label: &str, command: Command| {
            StandardItem {
                label: label.into(),
                activate: Box::new(move |icon: &mut Self| icon.send(command)),
                ..Default::default()
            }
            .into()
        };
        vec![
            item(Command::Open.label(), Command::Open),
            item(&crate::words::plain(crate::words::Text::TrayCheck), Command::Sync),
            CheckmarkItem {
                label: Command::Notify.label().into(),
                checked: self.notify,
                activate: Box::new(|icon: &mut Self| icon.send(Command::Notify)),
                ..Default::default()
            }
            .into(),
            ksni::MenuItem::Separator,
            item(&t!(GtkQuit), Command::Exit),
        ]
    }
}

pub struct Tray {
    handle: ksni::blocking::Handle<Icon>,
}

impl Tray {
    /// The icon, None when no tray host answers (vanilla GNOME, a bare session)
    pub fn start() -> Option<Tray> {
        let (commands, received) = async_channel::unbounded();
        let icon = Icon {
            unread: 0,
            notify: shell().notify.get(),
            commands,
        };
        let handle = icon.spawn().ok()?;
        spawn(async move {
            while let Ok(command) = received.recv().await {
                run_command(command);
            }
        });
        Some(Tray { handle })
    }

    pub fn count(&self, unread: u64) {
        self.handle.update(|icon| icon.unread = unread);
    }

    /// The check mark of Notify of New Mail as the app has it now
    pub fn refresh(&self) {
        let notify = shell().notify.get();
        self.handle.update(|icon| icon.notify = notify);
    }

    pub fn stop(self) {
        self.handle.shutdown();
    }
}
