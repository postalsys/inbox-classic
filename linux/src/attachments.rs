//! The strip of a message's files under its header, in the reading pane and in a message's own window: one item a file,
//! its icon by the kind the core gave it, its name and its size. Double-click or Enter opens a file (the reader asks
//! the core for it and opens what the core wrote with the system's program); a right-click or the menu key offers Open,
//! Save As..., Import Key... (a file of public keys) and Save All... through the reader's actions. A file that can run
//! programs looks the same, says so in its tooltip, and its Open is greyed. A file of an encrypted part of a message
//! whose parts differ has a small lock on its icon, in the colour of its part's label (the file came from there,
//! decrypted to be shown), and says its part in its tooltip and to screen readers. Nothing here reads mail data: the
//! names, sizes, kinds, tooltips, the words refusing a file and the part a file came from are the core's.

use std::cell::RefCell;
use std::path::Path;
use std::rc::Rc;

use adw::prelude::*;
use gtk::{gdk, gio, glib};
use pe_core::opening::FileKind;
use pe_core::previews::ShowInMessage;
use pe_core::protect::Tone;
use pe_core::{AttachmentView, PartView, Protection};

/// The pixels of a file's icon
const ICON_SIZE: i32 = 32;

/// The pixels of the lock on the icon of a file of an encrypted part
const LOCK_SIZE: i32 = 12;

/// How many rows of files the strip shows before it scrolls
const ROWS_SHOWN: i32 = 3;

/// The themed icons of a kind of file, the first the theme has drawn
fn icon_names(kind: FileKind) -> &'static [&'static str] {
    match kind {
        FileKind::Image => &["image-x-generic"],
        FileKind::Pdf => &["application-pdf", "x-office-document"],
        FileKind::Document => &["x-office-document"],
        FileKind::Spreadsheet => &["x-office-spreadsheet"],
        FileKind::Presentation => &["x-office-presentation"],
        FileKind::Archive => &["package-x-generic"],
        FileKind::Audio => &["audio-x-generic"],
        FileKind::Video => &["video-x-generic"],
        FileKind::Calendar => &["x-office-calendar"],
        FileKind::Contact => &["x-office-address-book"],
        FileKind::Key => &["application-certificate", "dialog-password"],
        FileKind::Text => &["text-x-generic"],
        FileKind::Mail => &["message-rfc822", "mail-message", "text-x-generic"],
        FileKind::Program => &["application-x-executable"],
        FileKind::Other => &["application-x-generic"],
    }
}

/// What the strip calls when a file's Show in Message is chosen: its index, and what the item said then
type ShowChosen = Rc<dyn Fn(usize, ShowInMessage)>;

pub struct Strip {
    /// The strip, scrolling when there are more files than [`ROWS_SHOWN`] rows hold
    pub widget: gtk::ScrolledWindow,
    pub flow: gtk::FlowBox,
    /// The files shown, as the core described them
    files: RefCell<Vec<AttachmentView>>,
    /// The tone of each file's lock (its part's), None for a file without one
    locks: RefCell<Vec<Option<Tone>>>,
    /// Show in Message chosen in a file's menu: its index and what the item said when chosen
    show_in_message: RefCell<Option<ShowChosen>>,
    /// The Show in Message of the menu open last, None when it had none (the UI test reads it)
    #[cfg(feature = "e2e")]
    menu_action: RefCell<Option<gio::SimpleAction>>,
}

impl Strip {
    pub fn new() -> Rc<Strip> {
        let flow = gtk::FlowBox::new();
        flow.set_selection_mode(gtk::SelectionMode::Single);
        // double-click or Enter opens, a click only chooses
        flow.set_activate_on_single_click(false);
        flow.set_homogeneous(false);
        flow.set_min_children_per_line(1);
        flow.set_max_children_per_line(30);
        flow.set_column_spacing(4);
        flow.set_row_spacing(2);
        flow.set_valign(gtk::Align::Start);
        flow.set_widget_name("reader-strip");
        flow.update_property(&[gtk::accessible::Property::Label(&t!(UiAttachmentsStrip))]);
        let widget = gtk::ScrolledWindow::new();
        widget.set_hscrollbar_policy(gtk::PolicyType::Never);
        widget.set_propagate_natural_height(true);
        widget.set_child(Some(&flow));
        widget.add_css_class("attachment-strip");
        widget.set_visible(false);
        // the locks in the dark colours of their tones while the windows are dark
        crate::security::follow_dark(&widget);
        let strip = Rc::new(Strip {
            widget,
            flow,
            files: RefCell::default(),
            locks: RefCell::default(),
            show_in_message: RefCell::default(),
            #[cfg(feature = "e2e")]
            menu_action: RefCell::default(),
        });
        strip.connect_menu();
        strip
    }

    /// The files of a message: one item each, the strip hidden when there are none; `parts` the message's parts when
    /// they differ, whose labels' tones colour the locks. The same files as shown (the message shown again, with its
    /// pictures, or a file taken out of it with Show in Message) keep their items, and the one chosen
    pub fn show(&self, attachments: &[AttachmentView], parts: &[PartView]) {
        self.widget.set_visible(!attachments.is_empty());
        let locks: Vec<Option<Tone>> = attachments.iter().map(|file| lock_tone(file, parts)).collect();
        if same_items(&self.files.borrow(), attachments) && *self.locks.borrow() == locks {
            *self.files.borrow_mut() = attachments.to_vec();
            return;
        }
        // the items only: remove_all would also take a file's menu, a child of the box while it is open (or about to
        // be unparented), which it can not remove, and so never end
        let mut child = self.flow.first_child();
        while let Some(widget) = child {
            child = widget.next_sibling();
            if widget.is::<gtk::FlowBoxChild>() {
                self.flow.remove(&widget);
            }
        }
        for (index, (file, lock)) in attachments.iter().zip(&locks).enumerate() {
            self.flow.append(&item(index, file, *lock));
        }
        *self.files.borrow_mut() = attachments.to_vec();
        *self.locks.borrow_mut() = locks;
        self.fit_height();
    }

    /// The item of the file being opened shown busy (dimmed), None for none
    pub fn busy(&self, index: Option<usize>) {
        let mut at = 0;
        while let Some(child) = self.flow.child_at_index(at) {
            let busy = usize::try_from(at).ok() == index;
            child.set_opacity(if busy { 0.45 } else { 1.0 });
            at += 1;
        }
    }

    pub fn hide(&self) {
        self.widget.set_visible(false);
    }

    /// As tall as its files, up to [`ROWS_SHOWN`] rows of them; the others scroll
    fn fit_height(&self) {
        let row = self
            .flow
            .child_at_index(0)
            .map(|child| child.measure(gtk::Orientation::Vertical, -1).1)
            .unwrap_or(0);
        self.widget
            .set_max_content_height((row + self.flow.row_spacing() as i32) * ROWS_SHOWN);
    }

    /// Calls `open` with the index of a file double-clicked or chosen with Enter
    pub fn connect_open(&self, open: impl Fn(usize) + 'static) {
        self.flow.connect_child_activated(move |_, child| {
            if let Ok(index) = usize::try_from(child.index()) {
                open(index);
            }
        });
    }

    /// Calls `show` with the index of a file whose Show in Message was chosen, and what the item said then
    pub fn connect_show_in_message(&self, show: impl Fn(usize, ShowInMessage) + 'static) {
        self.show_in_message.replace(Some(Rc::new(show)));
    }

    /// The file chosen in the strip: the one with the keyboard focus, or the one selected
    pub fn chosen(&self) -> Option<usize> {
        let focused = self
            .flow
            .root()
            .and_then(|root| root.focus())
            .and_then(|focus| {
                focus
                    .downcast_ref::<gtk::FlowBoxChild>()
                    .cloned()
                    .or_else(|| focus.ancestor(gtk::FlowBoxChild::static_type()).and_downcast())
            })
            .filter(|child| child.parent().as_ref() == Some(self.flow.upcast_ref()));
        let child = focused.or_else(|| self.flow.selected_children().into_iter().next())?;
        usize::try_from(child.index()).ok()
    }

    /// File `index` as the core described it
    pub fn file(&self, index: usize) -> Option<AttachmentView> {
        self.files.borrow().get(index).cloned()
    }

    /// A right-click on a file, or the menu key (Shift+F10) on the one chosen: its menu
    fn connect_menu(self: &Rc<Self>) {
        let click = gtk::GestureClick::new();
        click.set_button(gdk::BUTTON_SECONDARY);
        let weak = Rc::downgrade(self);
        click.connect_pressed(move |gesture, _, x, y| {
            let Some(this) = weak.upgrade() else { return };
            let Some(child) = this.flow.child_at_pos(x as i32, y as i32) else {
                return;
            };
            gesture.set_state(gtk::EventSequenceState::Claimed);
            this.flow.select_child(&child);
            child.grab_focus();
            this.popup_menu(&child, Some((x, y)));
        });
        self.flow.add_controller(click);
        let keys = gtk::EventControllerKey::new();
        let weak = Rc::downgrade(self);
        keys.connect_key_pressed(move |_, key, _, state| {
            let menu_key =
                key == gdk::Key::Menu || (key == gdk::Key::F10 && state.contains(gdk::ModifierType::SHIFT_MASK));
            let Some(this) = weak.upgrade().filter(|_| menu_key) else {
                return glib::Propagation::Proceed;
            };
            let Some(child) = this.chosen().and_then(|index| this.flow.child_at_index(index as i32)) else {
                return glib::Propagation::Proceed;
            };
            this.flow.select_child(&child);
            this.popup_menu(&child, None);
            glib::Propagation::Stop
        });
        self.flow.add_controller(keys);
    }

    /// The menu of the file of `child`: Open (greyed for a file that can run programs), Save As..., Import Key... for
    /// a file of public keys, Save All..., and for a picture or PDF file Show in Message (ticked while it is in the message, greyed when it can not be);
    /// where the click was, or under the file
    pub fn popup_menu(&self, child: &gtk::FlowBoxChild, at: Option<(f64, f64)>) {
        let Some((index, attachment)) = usize::try_from(child.index())
            .ok()
            .and_then(|index| Some((index, self.file(index)?)))
        else {
            return;
        };
        let can_open = attachment.kind.can_open();
        let target = (index as u32).to_variant();
        let menu = gio::Menu::new();
        let file = gio::Menu::new();
        let open = gio::MenuItem::new(Some(&t!(UiAttachmentOpen)), None);
        let action = if can_open {
            "reader.open-attachment"
        } else {
            "reader.open-refused"
        };
        open.set_action_and_target_value(Some(action), Some(&target));
        file.append_item(&open);
        let save = gio::MenuItem::new(Some(&t!(UiAttachmentSaveAs)), None);
        save.set_action_and_target_value(Some("reader.save-attachment"), Some(&target));
        file.append_item(&save);
        // a file the core read as public keys: into Encryption Keys
        if attachment.is_key {
            let import = gio::MenuItem::new(Some(&t!(UiAttachmentImportKey)), None);
            import.set_action_and_target_value(Some("reader.import-key"), Some(&target));
            file.append_item(&import);
        }
        menu.append_section(None, &file);
        let all = gio::Menu::new();
        all.append(Some(&t!(UiAttachmentSaveAll)), Some("reader.save-all"));
        menu.append_section(None, &all);
        let shown = self.show_in_message_action(index, attachment.show_in_message);
        if shown.is_some() {
            let section = gio::Menu::new();
            section.append(Some(&t!(UiAttachmentShowInMessage)), Some("strip.show-in-message"));
            menu.append_section(None, &section);
        }
        // its action there before its items are made, so Show in Message is made a check box from the start
        let popover = gtk::PopoverMenu::from_model(None::<&gio::MenuModel>);
        if let Some(group) = shown {
            popover.insert_action_group("strip", Some(&group));
        }
        popover.set_menu_model(Some(&menu));
        popover.set_widget_name("reader-strip-menu");
        popover.set_parent(&self.flow);
        popover.set_has_arrow(false);
        let rect = match at {
            Some((x, y)) => gdk::Rectangle::new(x as i32, y as i32, 1, 1),
            None => child
                .compute_bounds(&self.flow)
                // under the middle of the file
                .map(|b| gdk::Rectangle::new((b.x() + b.width() / 2.0) as i32, (b.y() + b.height()) as i32, 1, 1))
                .unwrap_or_else(|| gdk::Rectangle::new(0, 0, 1, 1)),
        };
        popover.set_pointing_to(Some(&rect));
        popover.set_position(gtk::PositionType::Bottom);
        let back = child.downgrade();
        popover.connect_closed(move |popover| {
            let popover = popover.clone();
            let back = back.clone();
            glib::idle_add_local_once(move || {
                popover.unparent();
                // the focus back on the file, for the keys
                if let Some(child) = back.upgrade() {
                    child.grab_focus();
                }
            });
        });
        popover.popup();
    }

    /// The action of a file's Show in Message, a check box with the state the core gave: none for a file that is not
    /// a picture or PDF file
    fn show_in_message_action(&self, index: usize, state: ShowInMessage) -> Option<gio::SimpleActionGroup> {
        #[cfg(feature = "e2e")]
        self.menu_action.replace(None);
        if state == ShowInMessage::None {
            return None;
        }
        let action =
            gio::SimpleAction::new_stateful("show-in-message", None, &(state == ShowInMessage::On).to_variant());
        action.set_enabled(state != ShowInMessage::Unavailable);
        let show = self.show_in_message.borrow().clone();
        action.connect_activate(move |_, _| {
            if let Some(show) = &show {
                // after the menu has closed: the message is shown again
                let show = show.clone();
                glib::idle_add_local_once(move || show(index, state));
            }
        });
        let group = gio::SimpleActionGroup::new();
        group.add_action(&action);
        #[cfg(feature = "e2e")]
        self.menu_action.replace(Some(action));
        Some(group)
    }

    /// The Show in Message of the menu open last: whether it is ticked, and whether it can be chosen; None when the
    /// menu had none
    #[cfg(feature = "e2e")]
    pub fn show_in_message_item(&self) -> Option<(bool, bool)> {
        let action = self.menu_action.borrow().clone()?;
        let ticked = action.state().and_then(|s| s.get::<bool>()).unwrap_or(false);
        Some((ticked, action.is_enabled()))
    }

    /// The strip's menu open now, when it is (the UI test reads and closes it)
    #[cfg(feature = "e2e")]
    pub fn open_menu(&self) -> Option<gtk::PopoverMenu> {
        let mut child = self.flow.first_child();
        while let Some(widget) = child {
            child = widget.next_sibling();
            if let Ok(popover) = widget.downcast::<gtk::PopoverMenu>()
                && popover.is_visible()
            {
                return Some(popover);
            }
        }
        None
    }

    /// Each file as the strip shows it: its name, its size, its icon and its tooltip (the UI test reads them)
    #[cfg(feature = "e2e")]
    pub fn shown(&self) -> Vec<Shown> {
        let mut found = Vec::new();
        let mut index = 0;
        while let Some(child) = self.flow.child_at_index(index) {
            index += 1;
            let labels = crate::e2e::descendants::<gtk::Label>(child.upcast_ref());
            let text = |name: &str| {
                labels
                    .iter()
                    .find(|l| l.widget_name() == name)
                    .map(|l| l.text().to_string())
                    .unwrap_or_default()
            };
            let icon = crate::e2e::descendants::<gtk::Image>(child.upcast_ref())
                .first()
                .and_then(crate::icons::name_of)
                .unwrap_or_default();
            let lock = crate::e2e::descendants::<gtk::Image>(child.upcast_ref())
                .into_iter()
                .find(|image| image.widget_name() == "attachment-lock" && image.is_visible())
                .map(|image| {
                    ["verified", "good", "warning", "neutral"]
                        .into_iter()
                        .find(|tone| image.has_css_class(&format!("security-{tone}")))
                        .unwrap_or_default()
                        .to_string()
                });
            let description = self
                .files
                .borrow()
                .get(index as usize - 1)
                .and_then(description)
                .unwrap_or_default();
            found.push(Shown {
                name: text("attachment-name"),
                size: text("attachment-size"),
                icon,
                tooltip: child.tooltip_text().map(|t| t.to_string()).unwrap_or_default(),
                lock,
                description,
            });
        }
        found
    }
}

/// A file as the strip shows it (the UI test)
#[cfg(feature = "e2e")]
#[derive(Debug)]
pub struct Shown {
    pub name: String,
    pub size: String,
    pub icon: String,
    pub tooltip: String,
    /// The tone of the lock on its icon, None without one
    pub lock: Option<String>,
    /// What it says to screen readers beyond its name and size
    pub description: String,
}

/// Whether `shown` and `files` are the same files, but for what Show in Message says of them
fn same_items(shown: &[AttachmentView], files: &[AttachmentView]) -> bool {
    shown.len() == files.len()
        && shown.iter().zip(files).all(|(a, b)| {
            let a = AttachmentView {
                show_in_message: b.show_in_message,
                ..a.clone()
            };
            a == *b
        })
}

/// The tone of the lock of `file`: its part's, when that part was encrypted; None for any other file
fn lock_tone(file: &AttachmentView, parts: &[PartView]) -> Option<Tone> {
    if file.protection != Protection::Encrypted {
        return None;
    }
    Some(
        file.part
            .and_then(|part| parts.get(part))
            .map_or(Tone::Good, |part| part.tone),
    )
}

/// What a file says to screen readers beyond its name and size: why it does not open, and the part it came from
fn description(file: &AttachmentView) -> Option<String> {
    let lines: Vec<&str> = [file.refusal.as_deref().unwrap_or_default(), file.part_text.as_str()]
        .into_iter()
        .filter(|line| !line.is_empty())
        .collect();
    (!lines.is_empty()).then(|| lines.join("\n"))
}

/// The icon of a file, with a lock in the corner in `lock`'s colour for a file of an encrypted part: on a disc of the
/// strip's background, so it reads as a mark on the file rather than a part of its picture
fn file_icon(kind: FileKind, lock: Option<Tone>) -> gtk::Widget {
    // drawn from icons kept for good, not looked up by their names (crate::icons says why)
    let icon = gtk::Image::new();
    icon.set_pixel_size(ICON_SIZE);
    crate::icons::show(&icon, icon_names(kind));
    let Some(tone) = lock else {
        return icon.upcast();
    };
    // filled, to read at its size; the outline the bar has where the theme has no filled one
    let badge = gtk::Image::new();
    badge.set_widget_name("attachment-lock");
    badge.set_pixel_size(LOCK_SIZE);
    crate::icons::show(&badge, &["ic-lock-closed-filled-symbolic", "ic-lock-closed-symbolic"]);
    badge.set_halign(gtk::Align::End);
    badge.set_valign(gtk::Align::End);
    badge.add_css_class("attachment-lock");
    crate::security::set_tone(&badge, tone);
    badge.add_css_class("security-tint");
    // the tooltip and the description say it
    badge.set_accessible_role(gtk::AccessibleRole::Presentation);
    let overlay = gtk::Overlay::new();
    overlay.set_child(Some(&icon));
    overlay.add_overlay(&badge);
    overlay.upcast()
}

/// The item of file `index`: its icon (with a lock for a file of an encrypted part, `lock` its tone), its name
/// (shortened in the middle, the whole of it in the tooltip) and its size
fn item(index: usize, file: &AttachmentView, lock: Option<Tone>) -> gtk::FlowBoxChild {
    let icon = file_icon(file.kind, lock);
    let name = gtk::Label::new(Some(&file.filename));
    name.set_widget_name("attachment-name");
    name.set_xalign(0.0);
    name.set_ellipsize(gtk::pango::EllipsizeMode::Middle);
    name.set_max_width_chars(28);
    name.set_single_line_mode(true);
    let size = gtk::Label::new(Some(&file.size_text));
    size.set_widget_name("attachment-size");
    size.set_xalign(0.0);
    size.add_css_class("dim-label");
    size.add_css_class("caption");
    let text = gtk::Box::new(gtk::Orientation::Vertical, 0);
    text.set_valign(gtk::Align::Center);
    text.append(&name);
    text.append(&size);
    let content = gtk::Box::new(gtk::Orientation::Horizontal, 6);
    content.append(&icon);
    content.append(&text);
    let child = gtk::FlowBoxChild::new();
    child.set_child(Some(&content));
    child.add_css_class("attachment-file");
    child.set_widget_name(&format!("attachment-{index}"));
    // the core's: the whole name and size, why a file that can run programs does not open, the part it came from
    child.set_tooltip_text(Some(&file.tooltip));
    child.update_property(&[gtk::accessible::Property::Label(&format!(
        "{}, {}",
        file.filename, file.size_text
    ))]);
    if let Some(description) = description(file) {
        child.update_property(&[gtk::accessible::Property::Description(&description)]);
    }
    child
}

#[cfg(feature = "e2e")]
thread_local! {
    /// The files a test run opened, in place of the system's programs
    pub static OPENED: RefCell<Vec<std::path::PathBuf>> = RefCell::default();
}

/// The file the core wrote for an attachment opened with the system's program for it; the error in words when there
/// is none. A test run records it instead, so nothing is launched
pub async fn launch(path: &Path, window: &gtk::Window) -> Result<(), String> {
    #[cfg(feature = "e2e")]
    {
        let _ = window;
        OPENED.with(|opened| opened.borrow_mut().push(path.to_path_buf()));
        Ok(())
    }
    #[cfg(not(feature = "e2e"))]
    {
        let launcher = gtk::FileLauncher::new(Some(&gio::File::for_path(path)));
        launcher
            .launch_future(Some(window))
            .await
            .map_err(|error| error.message().to_string())
    }
}

/// The files opened in a test run, taken
#[cfg(feature = "e2e")]
pub fn take_opened() -> Vec<std::path::PathBuf> {
    OPENED.with(|opened| std::mem::take(&mut *opened.borrow_mut()))
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn every_kind_has_an_icon() {
        for kind in [
            FileKind::Image,
            FileKind::Pdf,
            FileKind::Document,
            FileKind::Spreadsheet,
            FileKind::Presentation,
            FileKind::Archive,
            FileKind::Audio,
            FileKind::Video,
            FileKind::Calendar,
            FileKind::Contact,
            FileKind::Key,
            FileKind::Text,
            FileKind::Mail,
            FileKind::Program,
            FileKind::Other,
        ] {
            assert!(!icon_names(kind).is_empty(), "{kind:?}");
        }
    }

    fn file(protection: Protection, part: Option<usize>, part_text: &str) -> AttachmentView {
        AttachmentView {
            protection,
            part,
            part_text: part_text.into(),
            safe_filename: "floor-plan.png".into(),
            filename: "floor-plan.png".into(),
            mime_type: "image/png".into(),
            size: 628,
            size_text: "628 bytes".into(),
            kind: FileKind::Image,
            tooltip: String::new(),
            refusal: None,
            show_in_message: ShowInMessage::None,
            is_key: false,
        }
    }

    fn part(tone: Tone) -> PartView {
        PartView {
            tone,
            label: String::new(),
            details: Vec::new(),
            encrypted: true,
            signed: tone == Tone::Verified,
            find_key: None,
        }
    }

    /// Only a file of an encrypted part has a lock, in its part's tone
    #[test]
    fn a_lock_only_on_files_of_encrypted_parts() {
        let parts = [part(Tone::Neutral), part(Tone::Verified)];
        assert_eq!(
            lock_tone(&file(Protection::Encrypted, Some(1), "x"), &parts),
            Some(Tone::Verified)
        );
        assert_eq!(
            lock_tone(&file(Protection::Encrypted, Some(0), "x"), &parts),
            Some(Tone::Neutral)
        );
        assert_eq!(
            lock_tone(&file(Protection::Encrypted, Some(5), "x"), &parts),
            Some(Tone::Good)
        );
        assert_eq!(lock_tone(&file(Protection::Signed, Some(1), "x"), &parts), None);
        assert_eq!(lock_tone(&file(Protection::None, None, ""), &parts), None);
    }

    /// Screen readers hear why a file does not open and the part it came from
    #[test]
    fn the_description_says_the_part() {
        assert_eq!(description(&file(Protection::None, None, "")), None);
        let from = file(Protection::Encrypted, Some(1), "From part 2: Encrypted. Not signed");
        assert_eq!(
            description(&from).as_deref(),
            Some("From part 2: Encrypted. Not signed")
        );
        let refused = AttachmentView {
            refusal: Some("It can run programs".into()),
            ..from
        };
        assert_eq!(
            description(&refused).as_deref(),
            Some("It can run programs\nFrom part 2: Encrypted. Not signed")
        );
    }
}
