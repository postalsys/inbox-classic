//! The app's own plain preferences (not mail data): whether new mail is notified, the sizes of the panes, whether the
//! note about the tray was shown. In $XDG_CONFIG_HOME/inbox-classic/settings.ini, no GSettings schema to install.

use std::cell::RefCell;
use std::path::PathBuf;

use gtk::glib;

const GROUP: &str = "Inbox Classic";

pub struct Settings {
    file: glib::KeyFile,
    path: PathBuf,
    /// Written when the app ends, not on every change of a pane
    changed: RefCell<bool>,
}

impl Settings {
    pub fn load() -> Settings {
        let path = glib::user_config_dir().join("inbox-classic").join("settings.ini");
        let file = glib::KeyFile::new();
        // a missing or broken file is the defaults
        let _ = file.load_from_file(&path, glib::KeyFileFlags::NONE);
        Settings {
            file,
            path,
            changed: RefCell::new(false),
        }
    }

    pub fn bool(&self, key: &str, fallback: bool) -> bool {
        self.file.boolean(GROUP, key).unwrap_or(fallback)
    }

    pub fn int(&self, key: &str, fallback: i32) -> i32 {
        self.file.integer(GROUP, key).unwrap_or(fallback)
    }

    /// A text value, None when it is not set or empty
    pub fn text(&self, key: &str) -> Option<String> {
        self.file
            .string(GROUP, key)
            .ok()
            .map(|s| s.to_string())
            .filter(|s| !s.is_empty())
    }

    /// Sets a text value, or removes it for None, and saves
    pub fn set_text(&self, key: &str, value: Option<&str>) {
        match value {
            Some(value) => self.file.set_string(GROUP, key, value),
            None => {
                let _ = self.file.remove_key(GROUP, key);
            }
        }
        self.save();
    }

    pub fn set_bool(&self, key: &str, value: bool) {
        self.file.set_boolean(GROUP, key, value);
        self.save();
    }

    /// For values that change often (a pane dragged): kept until [`Settings::flush`]
    pub fn set_int(&self, key: &str, value: i32) {
        if self.file.integer(GROUP, key).ok() != Some(value) {
            self.file.set_integer(GROUP, key, value);
            *self.changed.borrow_mut() = true;
        }
    }

    pub fn flush(&self) {
        if self.changed.replace(false) {
            self.save();
        }
    }

    fn save(&self) {
        if let Some(dir) = self.path.parent() {
            let _ = std::fs::create_dir_all(dir);
        }
        let _ = self.file.save_to_file(&self.path);
    }
}

/// Tools > Notify of New Mail
pub const NOTIFY: &str = "NewMailNotifications";
/// The first close of the window into the tray says so once
pub const TRAY_NOTE: &str = "TrayNoteShown";
pub const TREE_WIDTH: &str = "TreeWidth";
pub const LIST_HEIGHT: &str = "ListHeight";
/// The language of the windows chosen in Preferences ("de"); not set for the system's
pub const LANGUAGE: &str = "Language";
/// Preferences > Group messages by conversation (on when not set)
pub const GROUP_BY_CONVERSATION: &str = "GroupByConversation";
/// View > Hide Ignored Conversations (off when not set)
pub const HIDE_IGNORED: &str = "HideIgnoredConversations";
/// Whether a new message's notification names its sign-in code (the core does it), off unless chosen
pub const CODES_IN_NOTIFICATIONS: &str = "CodesInNotifications";
