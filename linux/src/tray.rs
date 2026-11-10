//! The icon in the top bar (a StatusNotifierItem, which Ubuntu's AppIndicator extension shows): its tooltip says how
//! many messages are unread in the Inboxes, its menu has Open Inbox Classic, Check for New Mail, Notify of New Mail
//! and Quit. Where the desktop has no place for it there is no icon, and closing the window ends the app.
//!
//! The icon goes as pixmaps, not as the name of the installed icon: a tray host looks a name up in the icon themes it
//! read when it started (Omarchy's bar does), so right after the package is installed the name would show as missing
//! until the next login.

use gtk::gdk;
use gtk::gdk::prelude::TextureExt;
use gtk::glib;
use ksni::blocking::TrayMethods;

use crate::app::{run_command, shell, spawn};
use crate::commands::Command;
use crate::notify::unread_text;

struct Icon {
    /// The app icon at the sizes of linux/data/tray (scripts/build-icons.sh), as the hosts want it
    pixmaps: Vec<ksni::Icon>,
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

    fn icon_pixmap(&self) -> Vec<ksni::Icon> {
        self.pixmaps.clone()
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
            pixmaps: pixmaps(),
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

/// The PNGs of linux/data/tray as StatusNotifierItem pixmaps: ARGB32 in network byte order, not premultiplied
fn pixmaps() -> Vec<ksni::Icon> {
    const PNGS: [&[u8]; 6] = [
        include_bytes!("../data/tray/16.png"),
        include_bytes!("../data/tray/22.png"),
        include_bytes!("../data/tray/24.png"),
        include_bytes!("../data/tray/32.png"),
        include_bytes!("../data/tray/48.png"),
        include_bytes!("../data/tray/64.png"),
    ];
    PNGS.into_iter().filter_map(argb).collect()
}

fn argb(png: &'static [u8]) -> Option<ksni::Icon> {
    let texture = gdk::Texture::from_bytes(&glib::Bytes::from_static(png)).ok()?;
    let (width, height) = (texture.width(), texture.height());
    let mut downloader = gdk::TextureDownloader::new(&texture);
    downloader.set_format(gdk::MemoryFormat::A8r8g8b8);
    let (bytes, stride) = downloader.download_bytes();
    let row = width as usize * 4;
    let data = bytes.chunks(stride).flat_map(|line| &line[..row]).copied().collect();
    Some(ksni::Icon { width, height, data })
}

#[cfg(test)]
mod tests {
    #[test]
    fn pixmaps_are_argb_at_each_size() {
        let pixmaps = super::pixmaps();
        let sizes: Vec<i32> = pixmaps.iter().map(|icon| icon.width).collect();
        assert_eq!(sizes, [16, 22, 24, 32, 48, 64]);
        for icon in &pixmaps {
            assert_eq!(icon.width, icon.height);
            assert_eq!(icon.data.len(), (icon.width * icon.height * 4) as usize);
            // the corners are transparent and the middle is drawn
            assert_eq!(icon.data[0], 0);
            let middle = ((icon.height / 2 * icon.width + icon.width / 2) * 4) as usize;
            assert_eq!(icon.data[middle], 255);
        }
    }
}
