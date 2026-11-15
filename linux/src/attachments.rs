//! The strip of a message's files under its header, in the reading pane and in a message's own window: one item a
//! file, its icon by the kind the core gave it, its name and its size. Double-click or Enter opens a file (the reader
//! asks the core for it and opens what the core wrote with the system's program); a right-click or the menu key offers
//! Open, Save As... and Save All... through the reader's actions. A file that can run programs looks the same, says so
//! in its tooltip, and its Open is greyed. Nothing here reads mail data: the names, sizes and kinds are the core's.

use std::cell::RefCell;
use std::path::Path;
use std::rc::Rc;

use adw::prelude::*;
use gtk::{gdk, gio, glib};
use pe_core::AttachmentView;
use pe_core::opening::FileKind;

/// The pixels of a file's icon
const ICON_SIZE: i32 = 32;

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

/// A file of the strip as the core described it
struct File {
    name: String,
    can_open: bool,
}

pub struct Strip {
    /// The strip, scrolling when there are more files than [`ROWS_SHOWN`] rows hold
    pub widget: gtk::ScrolledWindow,
    pub flow: gtk::FlowBox,
    files: RefCell<Vec<File>>,
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
        let strip = Rc::new(Strip {
            widget,
            flow,
            files: RefCell::default(),
        });
        strip.connect_menu();
        strip
    }

    /// The files of a message: one item each, the strip hidden when there are none
    pub fn show(&self, attachments: &[AttachmentView]) {
        self.flow.remove_all();
        let mut files = self.files.borrow_mut();
        files.clear();
        for (index, file) in attachments.iter().enumerate() {
            self.flow.append(&item(index, file));
            files.push(File {
                name: file.filename.clone(),
                can_open: file.kind.can_open(),
            });
        }
        self.widget.set_visible(!files.is_empty());
        drop(files);
        self.fit_height();
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

    /// The name of file `index` and whether it may be opened
    pub fn file(&self, index: usize) -> Option<(String, bool)> {
        self.files.borrow().get(index).map(|f| (f.name.clone(), f.can_open))
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

    /// The menu of the file of `child`: Open (greyed for a file that can run programs), Save As..., Save All...;
    /// where the click was, or under the file
    pub fn popup_menu(&self, child: &gtk::FlowBoxChild, at: Option<(f64, f64)>) {
        let Some((index, (_, can_open))) = usize::try_from(child.index())
            .ok()
            .and_then(|index| Some((index, self.file(index)?)))
        else {
            return;
        };
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
        menu.append_section(None, &file);
        let all = gio::Menu::new();
        all.append(Some(&t!(UiAttachmentSaveAll)), Some("reader.save-all"));
        menu.append_section(None, &all);
        let popover = gtk::PopoverMenu::from_model(Some(&menu));
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
                .and_then(|image| image.gicon())
                .and_downcast::<gio::ThemedIcon>()
                .and_then(|icon| icon.names().first().map(|n| n.to_string()))
                .unwrap_or_default();
            found.push(Shown {
                name: text("attachment-name"),
                size: text("attachment-size"),
                icon,
                tooltip: child.tooltip_text().map(|t| t.to_string()).unwrap_or_default(),
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
}

/// The item of file `index`: its icon, its name (shortened in the middle, the whole of it in the tooltip) and its size
fn item(index: usize, file: &AttachmentView) -> gtk::FlowBoxChild {
    let icon = gtk::Image::from_gicon(&gio::ThemedIcon::from_names(icon_names(file.kind)));
    icon.set_pixel_size(ICON_SIZE);
    let name = gtk::Label::new(Some(&file.filename));
    name.set_widget_name("attachment-name");
    name.set_xalign(0.0);
    name.set_ellipsize(gtk::pango::EllipsizeMode::Middle);
    name.set_max_width_chars(28);
    name.set_single_line_mode(true);
    let size_text = pe_core::format_size(file.size);
    let size = gtk::Label::new(Some(&size_text));
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
    let tooltip = if file.kind.can_open() {
        file.filename.clone()
    } else {
        format!("{}\n{}", file.filename, t!(UiAttachmentProgramTip))
    };
    child.set_tooltip_text(Some(&tooltip));
    child.update_property(&[gtk::accessible::Property::Label(&format!(
        "{}, {size_text}",
        file.filename
    ))]);
    if !file.kind.can_open() {
        child.update_property(&[gtk::accessible::Property::Description(&t!(UiAttachmentProgramTip))]);
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
}
