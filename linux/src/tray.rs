//! The icon in the top bar (a StatusNotifierItem, which Ubuntu's AppIndicator extension shows): its tooltip says how
//! many messages are unread in the Inboxes (and, first, which accounts need the user to sign in or can not connect,
//! with a warning badge on the icon while one needs a sign-in), its menu has Open Inbox Classic, Check for New
//! Mail, Notify of New Mail and Quit. Where the desktop has no place for it there is no icon, and closing the window
//! ends the app.
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
    /// The same with the warning badge, made the first time an account needs the user to sign in
    badged: Option<Vec<ksni::Icon>>,
    attention: bool,
    /// The status bar's words of the accounts that need a sign-in or can not connect, None while all are connected
    status: Option<String>,
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

    // ksni takes the pixmaps by value for each query of the host: the set shown, cloned once
    fn icon_pixmap(&self) -> Vec<ksni::Icon> {
        match &self.badged {
            Some(badged) if self.attention => badged.clone(),
            _ => self.pixmaps.clone(),
        }
    }

    fn tool_tip(&self) -> ksni::ToolTip {
        let unread = unread_text(self.unread);
        ksni::ToolTip {
            title: crate::ui::TITLE.into(),
            description: match &self.status {
                Some(status) => format!("{status}\n{unread}"),
                None => unread,
            },
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
            badged: None,
            attention: false,
            status: None,
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

    /// The warning badge on (an account needs the user to sign in) or off, and the accounts' words in the tooltip
    pub fn attention(&self, badge: bool, status: Option<String>) {
        self.handle.update(|icon| {
            if badge && icon.badged.is_none() {
                icon.badged = Some(icon.pixmaps.iter().map(badged).collect());
            }
            icon.attention = badge;
            icon.status = status;
        });
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

/// GNOME's warning yellow, and the dark mark on it
const BADGE: [u8; 3] = [0xe5, 0xa5, 0x0a];
const BADGE_MARK: [u8; 3] = [0x30, 0x22, 0x00];

/// `icon` with a warning badge in its lower right corner: a yellow disc with an exclamation mark, ringed in white so
/// it stands apart on the icon and on a dark or light bar
fn badged(icon: &ksni::Icon) -> ksni::Icon {
    let size = icon.width.min(icon.height) as f64;
    let radius = (size * 0.3).max(4.0);
    let (cx, cy) = (icon.width as f64 - radius, icon.height as f64 - radius);
    let ring = (size / 16.0).max(1.0);
    let mut data = icon.data.clone();
    for y in 0..icon.height {
        for x in 0..icon.width {
            let (px, py) = (x as f64 + 0.5, y as f64 + 0.5);
            let distance = ((px - cx).powi(2) + (py - cy).powi(2)).sqrt();
            // how much of the pixel each part covers, its edge smoothed over one pixel
            let cover = |edge: f64| (edge - distance + 0.5).clamp(0.0, 1.0);
            let (outer, disc) = (cover(radius + ring), cover(radius));
            if outer == 0.0 {
                continue;
            }
            let color = if disc > 0.0 && exclamation(px - cx, py - cy, radius) {
                BADGE_MARK
            } else {
                BADGE
            };
            let at = ((y * icon.width + x) * 4) as usize;
            let pixel = &mut data[at..at + 4];
            // the white ring over the icon, then the disc over the ring
            blend(pixel, [0xff, 0xff, 0xff], outer);
            blend(pixel, color, disc);
        }
    }
    ksni::Icon {
        width: icon.width,
        height: icon.height,
        data,
    }
}

/// Whether the point (`dx`, `dy`) from the disc's middle is on its exclamation mark: a bar and a dot under it
fn exclamation(dx: f64, dy: f64, radius: f64) -> bool {
    let half_width = (radius * 0.16).max(0.5);
    let bar = dx.abs() <= half_width && (-radius * 0.62..=radius * 0.18).contains(&dy);
    let dot = dx.abs() <= half_width && (radius * 0.36..=radius * 0.36 + half_width * 2.0).contains(&dy);
    bar || dot
}

/// `color` over an ARGB pixel, `amount` of it
fn blend(pixel: &mut [u8], color: [u8; 3], amount: f64) {
    let alpha = pixel[0] as f64 / 255.0;
    let out_alpha = amount + alpha * (1.0 - amount);
    for (channel, value) in pixel[1..4].iter_mut().zip(color) {
        let mixed = value as f64 * amount + *channel as f64 * alpha * (1.0 - amount);
        *channel = if out_alpha > 0.0 {
            (mixed / out_alpha).round() as u8
        } else {
            0
        };
    }
    pixel[0] = (out_alpha * 255.0).round() as u8;
}

#[cfg(test)]
mod tests {
    #[test]
    fn the_badge_is_in_the_corner_and_leaves_the_rest() {
        for icon in super::pixmaps() {
            let badged = super::badged(&icon);
            assert_eq!(badged.data.len(), icon.data.len());
            let pixel = |data: &[u8], x: i32, y: i32| {
                let at = ((y * icon.width + x) * 4) as usize;
                data[at..at + 4].to_vec()
            };
            // the rest as it was: all but the lower right two thirds, where the badge is
            for y in 0..icon.height {
                for x in 0..icon.width {
                    if x >= icon.width / 3 && y >= icon.height / 3 {
                        continue;
                    }
                    assert_eq!(pixel(&badged.data, x, y), pixel(&icon.data, x, y));
                }
            }
            // the disc's yellow beside its mark, opaque
            let radius = (icon.width as f64 * 0.3).max(4.0);
            let x = (icon.width as f64 - radius * 0.45) as i32;
            let y = (icon.height as f64 - radius) as i32;
            assert_eq!(pixel(&badged.data, x, y), [255, 0xe5, 0xa5, 0x0a], "{}", icon.width);
        }
    }

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
