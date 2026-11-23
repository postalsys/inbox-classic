//! Sign and Encrypt in the compose window: the two switches of its header bar and its menu, the line under the fields,
//! the Keys row of the recipients' locks, Recipients' Keys, and the questions a switch asks. What each shows and what a
//! click does is the core's (pe-core compose_keys.rs): the window passes the message as it is and shows what comes back.

use std::cell::{Cell, RefCell};
use std::rc::Rc;

use adw::prelude::*;
use gtk::{gio, glib};
use pe_core::compose_keys::{Block, ComposeSecurity, Question, Recipient, RecipientKey, Switch, Toggled};
use pe_core::i18n::{gtk_mnemonic, without_mnemonic};
use pe_core::protect::Tone;

use crate::app::{shell, spawn};
use crate::commands::Command;
use crate::compose::Compose;
#[cfg(feature = "e2e")]
use crate::security::TONE_CLASSES;
use crate::security::{SecurityBar, follow_dark, set_tone};
use crate::ui::{self, TITLE};

/// How long the address fields wait after the last key before the locks follow them
const RECIPIENTS_WAIT_MS: u64 = 400;
/// How many recipients the Keys row shows before "+3"
const CHIPS_SHOWN: usize = 8;

/// Recipients' Keys' name, by which F1 finds its help (help/topics.toml `[context]` recipient-keys)
pub const DIALOG_NAME: &str = "recipient-keys-dialog";
pub const HELP_CONTEXT: &str = "recipient-keys";

/// The picture of a recipient's key: a lock for a key, the warning sign for none (a spinner while it is looked up)
fn key_icon(key: RecipientKey) -> Option<&'static str> {
    match key {
        RecipientKey::Verified | RecipientKey::Found | RecipientKey::Own => Some("ic-lock-closed-symbolic"),
        RecipientKey::Missing | RecipientKey::Unusable => Some("ic-warning-symbolic"),
        RecipientKey::Looking => None,
    }
}

/// The picture of a key, or a small spinner while it is looked up
fn key_picture(key: RecipientKey) -> gtk::Widget {
    match key_icon(key) {
        Some(name) => {
            let image = crate::icons::image(name);
            image.set_pixel_size(16);
            image.set_accessible_role(gtk::AccessibleRole::Presentation);
            image.upcast()
        }
        None => {
            let spinner = adw::Spinner::new();
            spinner.set_size_request(16, 16);
            spinner.upcast()
        }
    }
}

/// The words of the labels in `root`
#[cfg(feature = "e2e")]
fn label_texts(root: Option<&gtk::Widget>) -> Vec<String> {
    let mut texts = Vec::new();
    let Some(root) = root else { return texts };
    if let Some(label) = root.downcast_ref::<gtk::Label>() {
        texts.push(label.text().to_string());
    }
    let mut child = root.first_child();
    while let Some(at) = child {
        texts.extend(label_texts(Some(&at)));
        child = at.next_sibling();
    }
    texts
}

/// A recipient's tooltip: their key in words, and a newer key waiting
fn recipient_tip(recipient: &Recipient) -> String {
    match &recipient.pending {
        Some(pending) => format!("{}\n{pending}", recipient.text),
        None => recipient.text.clone(),
    }
}

// ---- the switches, the line, the locks: what a compose window has of them ----

/// What a compose window has of signing and encrypting: the switches as the user set them (Sign apart from Encrypt),
/// what the core said last, the lookups it started, and its widgets
pub struct Protection {
    pub sign: Cell<bool>,
    pub encrypt: Cell<bool>,
    /// It answers or forwards encrypted mail (the draft says so)
    pub quote_encrypted: Cell<bool>,
    pub security: RefCell<Option<ComposeSecurity>>,
    /// The lookups of keys this window started: their result is learned here, the status bar says what they found
    lookups: RefCell<Vec<u64>>,
    /// The editor's HTML as it came last, and where its quote was: what the line judges the quote by between sends
    pub written: RefCell<(String, crate::editor::Quote)>,
    pub sign_button: gtk::ToggleButton,
    pub encrypt_button: gtk::ToggleButton,
    pub menu_button: gtk::MenuButton,
    pub actions: gio::SimpleActionGroup,
    /// The line under the fields: what will happen to the message, Details while Encrypt is on
    pub line: SecurityBar,
    /// The Keys row: one chip per recipient
    pub keys: gtk::FlowBox,
    pub keys_dialog: RefCell<Option<Rc<RecipientKeys>>>,
    /// While the window shows what the core said, a switch's change is not the user's
    updating: Cell<bool>,
    recipients_timer: RefCell<Option<glib::SourceId>>,
    /// Each state the window showed, in order: every recipient's key and its words, and the line (the UI test reads
    /// a state that lasts only as long as a lookup)
    #[cfg(feature = "e2e")]
    pub shown_states: RefCell<Vec<ShownState>>,
}

/// A state the window showed: each recipient's address, key and words, and the line's words, tone and pictures
#[cfg(feature = "e2e")]
pub type ShownState = (
    Vec<(String, pe_core::compose_keys::RecipientKey, String)>,
    (String, String, Vec<String>),
);

/// The name of a compose command's action in the window's `compose` group
fn action_name(command: Command) -> String {
    format!("compose.{}", command.name())
}

impl Protection {
    pub fn new() -> Protection {
        let toggle = |icon: &str, label: &str, name: &str| {
            let button = crate::icons::kept(gtk::ToggleButton::builder().icon_name(icon).build());
            button.set_widget_name(name);
            button.update_property(&[gtk::accessible::Property::Label(label)]);
            button
        };
        let sign_button = toggle("ic-ribbon-symbolic", &t!(UiTbSign), "compose-sign");
        let encrypt_button = toggle("ic-lock-closed-symbolic", &t!(UiTbEncrypt), "compose-encrypt");
        let actions = gio::SimpleActionGroup::new();
        for command in [Command::ComposeSign, Command::ComposeEncrypt] {
            actions.add_action(&gio::SimpleAction::new_stateful(
                command.name(),
                None,
                &false.to_variant(),
            ));
        }
        actions.add_action(&gio::SimpleAction::new(Command::AttachMyKey.name(), None));
        // GNOME's primary menu: the commands of Tools and Insert that are used now and then
        let menu = gio::Menu::new();
        let switches = gio::Menu::new();
        for command in [Command::ComposeSign, Command::ComposeEncrypt] {
            let item = gio::MenuItem::new(Some(command.label()), Some(&action_name(command)));
            if let Some(accel) = command.accel() {
                item.set_attribute_value("accel", Some(&accel.to_variant()));
            }
            switches.append_item(&item);
        }
        menu.append_section(None, &switches);
        let insert = gio::Menu::new();
        insert.append(
            Some(Command::AttachMyKey.label()),
            Some(&action_name(Command::AttachMyKey)),
        );
        menu.append_section(None, &insert);
        let menu_button = crate::icons::kept(
            gtk::MenuButton::builder()
                .icon_name("open-menu-symbolic")
                .menu_model(&menu)
                .primary(true)
                .tooltip_text(t!(GtkMainMenu))
                .build(),
        );
        menu_button.set_widget_name("compose-menu");
        let keys = gtk::FlowBox::new();
        keys.set_selection_mode(gtk::SelectionMode::None);
        keys.set_hexpand(true);
        keys.set_row_spacing(4);
        keys.set_column_spacing(4);
        keys.set_max_children_per_line(CHIPS_SHOWN as u32 + 1);
        keys.add_css_class("compose-keys");
        keys.set_widget_name("compose-keys");
        keys.update_property(&[gtk::accessible::Property::Label(&crate::words::field_title(
            crate::words::Text::UiFieldKeys,
        ))]);
        let line = SecurityBar::new("compose");
        // the dark colours of the tones while the windows are dark (the line follows them by itself)
        follow_dark(&keys);
        Protection {
            sign: Cell::new(false),
            encrypt: Cell::new(false),
            quote_encrypted: Cell::new(false),
            security: RefCell::default(),
            lookups: RefCell::default(),
            written: RefCell::new((String::new(), crate::editor::Quote::Folded)),
            sign_button,
            encrypt_button,
            menu_button,
            actions,
            line,
            keys,
            keys_dialog: RefCell::default(),
            updating: Cell::new(false),
            recipients_timer: RefCell::default(),
            #[cfg(feature = "e2e")]
            shown_states: RefCell::default(),
        }
    }

    fn action(&self, command: Command) -> Option<gio::SimpleAction> {
        self.actions.lookup_action(command.name()).and_downcast()
    }

    /// The timer stopped: the window is going
    pub fn stop(&self) {
        if let Some(timer) = self.recipients_timer.take() {
            timer.remove();
        }
    }

    /// The switches, the line, the locks and Recipients' Keys as the core says them now
    fn show(&self, security: &ComposeSecurity, open_keys: &Rc<dyn Fn()>) {
        self.updating.set(true);
        self.sign_button.set_active(security.sign);
        self.sign_button.set_sensitive(security.sign_enabled);
        self.sign_button.set_tooltip_text(Some(&security.sign_tip));
        self.encrypt_button.set_active(security.encrypt);
        self.encrypt_button.set_tooltip_text(Some(&security.encrypt_tip));
        if let Some(sign) = self.action(Command::ComposeSign) {
            sign.set_state(&security.sign.to_variant());
            sign.set_enabled(security.sign_enabled);
        }
        if let Some(encrypt) = self.action(Command::ComposeEncrypt) {
            encrypt.set_state(&security.encrypt.to_variant());
        }
        if let Some(attach) = self.action(Command::AttachMyKey) {
            attach.set_enabled(security.has_own_key);
        }
        self.updating.set(false);
        self.line.show_tone(security.tone, security.encrypt, &security.text);
        self.line.details.set_visible(security.encrypt);
        // the chips made again only when the recipients or their keys changed
        let same = self.security.borrow().as_ref().map(|s| &s.recipients) == Some(&security.recipients);
        if !same {
            self.fill_keys(security, open_keys);
        }
        if let Some(dialog) = self.keys_dialog.borrow().as_ref() {
            dialog.fill(security);
        }
        #[cfg(feature = "e2e")]
        self.shown_states.borrow_mut().push((
            security
                .recipients
                .iter()
                .map(|r| (r.address.clone(), r.key, r.text.clone()))
                .collect(),
            self.line.shown().unwrap_or_default(),
        ));
    }

    /// The Keys row: a chip per recipient with their lock, the last ones as "+3"
    fn fill_keys(&self, security: &ComposeSecurity, open_keys: &Rc<dyn Fn()>) {
        while let Some(child) = self.keys.first_child() {
            self.keys.remove(&child);
        }
        let shown = if security.recipients.len() > CHIPS_SHOWN + 1 {
            CHIPS_SHOWN
        } else {
            security.recipients.len()
        };
        for (index, recipient) in security.recipients.iter().take(shown).enumerate() {
            let content = gtk::Box::new(gtk::Orientation::Horizontal, 5);
            content.append(&key_picture(recipient.key));
            let label = gtk::Label::new(Some(&recipient.label));
            label.set_ellipsize(gtk::pango::EllipsizeMode::End);
            label.set_max_width_chars(28);
            content.append(&label);
            let chip = self.chip(&content, &format!("compose-key-{index}"), open_keys);
            set_tone(&chip, recipient.tone);
            chip.set_tooltip_text(Some(&recipient_tip(recipient)));
            chip.update_property(&[gtk::accessible::Property::Label(&format!(
                "{}: {}",
                recipient.label, recipient.text
            ))]);
        }
        let rest = &security.recipients[shown..];
        if !rest.is_empty() {
            let more = gtk::Label::new(Some(&format!("+{}", rest.len())));
            let chip = self.chip(&more, "compose-key-more", open_keys);
            chip.add_css_class("more");
            set_tone(&chip, Tone::Neutral);
            let names: Vec<String> = rest.iter().map(|r| format!("{}: {}", r.label, r.text)).collect();
            chip.set_tooltip_text(Some(&names.join("\n")));
            chip.update_property(&[gtk::accessible::Property::Label(&names.join(", "))]);
        }
    }

    fn chip(&self, content: &impl IsA<gtk::Widget>, name: &str, open_keys: &Rc<dyn Fn()>) -> gtk::Button {
        let chip = gtk::Button::builder().child(content).build();
        chip.add_css_class("key-chip");
        // as wide as its words, not spread over the line
        chip.set_halign(gtk::Align::Start);
        chip.set_widget_name(name);
        let open = open_keys.clone();
        chip.connect_clicked(move |_| open());
        self.keys.append(&chip);
        // the chip takes the focus, not the box around it
        if let Some(child) = chip.parent() {
            child.set_focusable(false);
        }
        chip
    }

    /// What the Keys row shows, chip by chip: the label, the tone and the picture (the UI test reads them)
    #[cfg(feature = "e2e")]
    pub fn chips(&self) -> Vec<(String, String, String)> {
        let mut chips = Vec::new();
        let mut child = self.keys.first_child();
        while let Some(at) = child {
            if let Some(chip) = at.first_child().and_downcast::<gtk::Button>() {
                let tone = TONE_CLASSES
                    .iter()
                    .find(|class| chip.has_css_class(class))
                    .map(|class| class.trim_start_matches("security-").to_string())
                    .unwrap_or_default();
                let content = chip.child();
                let label = label_texts(content.as_ref()).join(" ");
                let picture = content
                    .and_then(|c| c.first_child())
                    .map(|first| match first.downcast::<gtk::Image>() {
                        Ok(image) => crate::icons::name_of(&image).unwrap_or_default(),
                        Err(other) if other.is::<adw::Spinner>() => "spinner".into(),
                        Err(_) => String::new(),
                    })
                    .unwrap_or_default();
                chips.push((label, tone, picture));
            }
            child = at.next_sibling();
        }
        chips
    }
}

// ---- wiring ----

/// The switches' clicks, the menu's actions and their keys (in the fields and in the editor, which takes keys first),
/// Details and the address fields' changes
pub fn connect(compose: &Rc<Compose>) {
    let p = &compose.protection;
    for (button, switch) in [(&p.sign_button, Switch::Sign), (&p.encrypt_button, Switch::Encrypt)] {
        let weak = Rc::downgrade(compose);
        button.connect_toggled(move |button| {
            let Some(this) = weak.upgrade() else { return };
            if this.protection.updating.get() {
                return;
            }
            let on = button.is_active();
            spawn(async move { toggle(&this, switch, on).await });
        });
    }
    for (command, switch) in [
        (Command::ComposeSign, Switch::Sign),
        (Command::ComposeEncrypt, Switch::Encrypt),
    ] {
        let Some(action) = p.action(command) else { continue };
        let weak = Rc::downgrade(compose);
        action.connect_activate(move |action, _| {
            let Some(this) = weak.upgrade() else { return };
            let on = !action.state().and_then(|s| s.get::<bool>()).unwrap_or(false);
            spawn(async move { toggle(&this, switch, on).await });
        });
    }
    if let Some(attach) = p.action(Command::AttachMyKey) {
        let weak = Rc::downgrade(compose);
        attach.connect_activate(move |_, _| {
            if let Some(this) = weak.upgrade() {
                spawn(async move { attach_my_key(&this).await });
            }
        });
    }
    compose.window.insert_action_group("compose", Some(&p.actions));
    let application = &shell().application;
    for command in [Command::ComposeSign, Command::ComposeEncrypt, Command::AttachMyKey] {
        if let Some(accel) = command.accel() {
            application.set_accels_for_action(&action_name(command), &[accel]);
        }
    }
    editor_keys(compose);
    let weak = Rc::downgrade(compose);
    p.line.details.connect_clicked(move |_| {
        if let Some(this) = weak.upgrade() {
            spawn(async move { recipient_keys(&this).await });
        }
    });
    // the locks follow the address fields once typing stops, and at once when the field is left
    for field in [&compose.to, &compose.cc, &compose.bcc] {
        let weak = Rc::downgrade(compose);
        let focus = gtk::EventControllerFocus::new();
        focus.connect_leave(move |_| {
            if let Some(this) = weak.upgrade()
                && let Some(timer) = this.protection.recipients_timer.take()
            {
                timer.remove();
                recipients_changed(&this);
            }
        });
        field.add_controller(focus);
    }
}

/// Ctrl+Shift+D and Ctrl+Shift+E with the cursor in the text: the editor's page would take them first
fn editor_keys(compose: &Rc<Compose>) {
    let keys = gtk::EventControllerKey::new();
    keys.set_propagation_phase(gtk::PropagationPhase::Capture);
    let weak = Rc::downgrade(compose);
    keys.connect_key_pressed(move |_, key, _, modifiers| {
        let Some(this) = weak.upgrade() else {
            return glib::Propagation::Proceed;
        };
        let modifiers = modifiers & gtk::accelerator_get_default_mod_mask();
        for command in [Command::ComposeSign, Command::ComposeEncrypt] {
            let Some((accel_key, accel_modifiers)) = command.accel().and_then(gtk::accelerator_parse) else {
                continue;
            };
            if key.to_lower() == accel_key.to_lower() && modifiers == accel_modifiers {
                let _ = WidgetExt::activate_action(&this.window, &action_name(command), None);
                return glib::Propagation::Stop;
            }
        }
        glib::Propagation::Proceed
    });
    compose.editor.document.view.add_controller(keys);
}

/// The address fields changed: the locks follow once typing stops
pub fn schedule(compose: &Rc<Compose>) {
    let p = &compose.protection;
    if let Some(timer) = p.recipients_timer.take() {
        timer.remove();
    }
    let weak = Rc::downgrade(compose);
    let timer = glib::timeout_add_local_once(std::time::Duration::from_millis(RECIPIENTS_WAIT_MS), move || {
        if let Some(this) = weak.upgrade() {
            this.protection.recipients_timer.take();
            recipients_changed(&this);
        }
    });
    *p.recipients_timer.borrow_mut() = Some(timer);
}

/// The window opened: what it shows of signing and encrypting, and with Encrypt on the keys of its recipients looked up
pub fn opened(compose: &Rc<Compose>) {
    recipients_changed(compose);
}

/// The recipients as they are now: with Encrypt on the keys of new ones looked up (the core skips those being looked
/// up or asked in vain lately), and the locks shown
fn recipients_changed(compose: &Rc<Compose>) {
    let p = &compose.protection;
    if p.encrypt.get()
        && let Ok(Some(request)) = shell()
            .core
            .compose_find_keys(compose.account.get(), &compose.outgoing_now())
    {
        p.lookups.borrow_mut().push(request);
    }
    refresh(compose);
}

/// Everything shown of signing and encrypting, as the core says it for the message as it is now
pub fn refresh(compose: &Rc<Compose>) {
    let Ok(security) = shell()
        .core
        .compose_security(compose.account.get(), &compose.outgoing_now())
    else {
        return;
    };
    let p = &compose.protection;
    let weak = Rc::downgrade(compose);
    let open_keys: Rc<dyn Fn()> = Rc::new(move || {
        if let Some(this) = weak.upgrade() {
            spawn(async move { recipient_keys(&this).await });
        }
    });
    p.show(&security, &open_keys);
    for widget in &compose.keys_row {
        widget.set_visible(security.show_keys);
    }
    // the text as it is now once it starts to matter: it may have changed while it was not watched
    let watched = p.security.borrow().as_ref().is_some_and(|s| s.watch_text);
    let look = security.watch_text && !watched;
    *p.security.borrow_mut() = Some(security);
    if look {
        compose.look_at_html();
    }
}

/// The editor's text changed: while it decides what Send does (a quote of encrypted mail in a message going without
/// encryption), the line looks at it again
pub fn edited(compose: &Rc<Compose>) {
    if compose
        .protection
        .security
        .borrow()
        .as_ref()
        .is_some_and(|s| s.watch_text)
    {
        compose.look_at_html();
    }
}

/// The switches as a click left them: the window's, a lookup it started remembered, the message changed
fn apply(compose: &Rc<Compose>, toggled: &Toggled) {
    let p = &compose.protection;
    let changed = p.sign.replace(toggled.sign) != toggled.sign;
    let changed = (p.encrypt.replace(toggled.encrypt) != toggled.encrypt) || changed;
    if let Some(request) = toggled.lookup {
        p.lookups.borrow_mut().push(request);
    }
    if changed {
        compose.changed();
    }
}

/// The question of a switch: `no` (Cancel, Keep It Encrypted) the default and Esc; Turn Encryption Off in red, the
/// other answers suggested
async fn ask(compose: &Compose, toggled: &Toggled) -> bool {
    let word = |text: Option<pe_core::i18n::Text>| text.map(crate::words::plain).unwrap_or_default();
    let (yes, no) = (word(toggled.yes), word(toggled.no));
    let destructive = (toggled.question == Question::TurnOffEncrypt).then_some("yes");
    ui::ask(
        &compose.window,
        TITLE,
        &toggled.text,
        &[("no", no.as_str()), ("yes", yes.as_str())],
        "no",
        "no",
        destructive,
    )
    .await
        == "yes"
}

/// A click on Sign or Encrypt (`on` what it is to become): through the core, which may ask first; a key made, or the
/// question answered Yes, tries again
pub async fn toggle(compose: &Rc<Compose>, switch: Switch, on: bool) {
    let core = &shell().core;
    let mut confirmed = false;
    loop {
        let outgoing = compose.outgoing_now();
        let Ok(toggled) = core.compose_toggle(compose.account.get(), &outgoing, switch, on, confirmed) else {
            break;
        };
        apply(compose, &toggled);
        // the switch shows what it is while the question is asked
        refresh(compose);
        match toggled.question {
            Question::None => break,
            Question::MakeKey => {
                if !ask(compose, &toggled).await
                    || crate::keys::make_key(&compose.window, compose.account.get())
                        .await
                        .is_none()
                {
                    break;
                }
            }
            Question::ShowKeys => {
                if ask(compose, &toggled).await {
                    crate::keys::keys_dialog(&compose.window).await;
                }
                break;
            }
            Question::TurnOffEncrypt => {
                if !ask(compose, &toggled).await {
                    break;
                }
                confirmed = true;
            }
        }
    }
    refresh(compose);
}

/// Insert > Attach My Public Key: the From address's public key as a file in the Attach row
async fn attach_my_key(compose: &Rc<Compose>) {
    let outgoing = compose.outgoing_now();
    match shell().core.compose_own_key_file(compose.account.get(), &outgoing) {
        Ok(path) => compose.add_files(&[path]),
        Err(error) => ui::alert(&compose.window, TITLE, &error.to_string()).await,
    }
}

/// Before Send: true when the message may go as it is. A recipient without a key opens Recipients' Keys, no key of
/// one's own asks to make one, an encrypted quote in clear mail says why it can not go
pub async fn may_send(compose: &Rc<Compose>, outgoing: &pe_core::Outgoing) -> bool {
    let Ok(security) = shell().core.compose_security(compose.account.get(), outgoing) else {
        return true;
    };
    match security.block {
        Block::None => true,
        Block::MissingKeys => {
            recipient_keys(compose).await;
            false
        }
        Block::NoOwnKey => {
            let switch = if outgoing.encrypt {
                Switch::Encrypt
            } else {
                Switch::Sign
            };
            toggle(compose, switch, true).await;
            false
        }
        Block::EncryptedQuote => {
            ui::alert(&compose.window, TITLE, &security.block_text).await;
            false
        }
    }
}

/// A lookup ended: the window that started it learns what it found and says so in its status bar; every window shows
/// its locks again (a key learned is everyone's)
pub fn keys_found(request: u64) {
    let composes = shell().composes.borrow().clone();
    for compose in &composes {
        let ours = {
            let mut lookups = compose.protection.lookups.borrow_mut();
            let at = lookups.iter().position(|r| *r == request);
            at.map(|at| lookups.remove(at)).is_some()
        };
        if ours
            && let Some(outcome) = shell().core.pgp_find_result(request)
            && !outcome.text.is_empty()
        {
            compose.set_status(&outcome.text);
        }
    }
    refresh_all();
}

/// Every compose window shows its switches and locks again: the keys changed
pub fn refresh_all() {
    let composes = shell().composes.borrow().clone();
    for compose in &composes {
        refresh(compose);
    }
}

// ---- Recipients' Keys ----

/// What Recipients' Keys was closed with
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
enum KeysAnswer {
    Cancel,
    SendUnencrypted,
    Send,
}

/// What a recipient's row asks of the window
enum RowAction {
    Find(String),
    Remove(String),
    Decide(String, bool),
}

/// The window of the recipients and their keys: why some can not be encrypted to, Find Key and Remove from Message for
/// each, Send Without Encryption, Send
pub struct RecipientKeys {
    pub dialog: adw::Dialog,
    intro: gtk::Label,
    pub list: gtk::ListBox,
    pub send: gtk::Button,
    pub cancel: gtk::Button,
    pub unencrypted: gtk::Button,
    note: gtk::Label,
    act: Rc<dyn Fn(RowAction)>,
    /// The recipients its rows show
    shown: RefCell<Vec<Recipient>>,
}

impl RecipientKeys {
    fn new(act: Rc<dyn Fn(RowAction)>, answer: async_channel::Sender<KeysAnswer>) -> RecipientKeys {
        let intro = ui::wrapped_label("");
        intro.set_widget_name("recipient-keys-intro");
        let list = gtk::ListBox::new();
        list.add_css_class("boxed-list");
        list.set_selection_mode(gtk::SelectionMode::None);
        list.set_widget_name("recipient-keys-list");
        list.update_property(&[gtk::accessible::Property::Label(&t!(UiRecipientColRecipient))]);
        let scrolled = gtk::ScrolledWindow::builder()
            .child(&list)
            .hscrollbar_policy(gtk::PolicyType::Never)
            .propagate_natural_height(true)
            .max_content_height(360)
            .vexpand(true)
            .build();
        let button = |text: &str, name: &str| {
            let button = gtk::Button::with_mnemonic(&gtk_mnemonic(text));
            button.set_widget_name(name);
            button
        };
        let unencrypted = button(&t!(UiSendUnencrypted), "recipient-keys-unencrypted");
        unencrypted.set_halign(gtk::Align::Start);
        let note = gtk::Label::new(None);
        note.set_xalign(0.0);
        note.set_wrap(true);
        note.add_css_class("dim-label");
        note.add_css_class("caption");
        note.set_widget_name("recipient-keys-note");
        let content = gtk::Box::new(gtk::Orientation::Vertical, 12);
        content.set_margin_start(12);
        content.set_margin_end(12);
        content.set_margin_top(6);
        content.set_margin_bottom(12);
        content.append(&intro);
        content.append(&scrolled);
        content.append(&unencrypted);
        content.append(&note);
        let cancel = button(&t!(UiCancel), "recipient-keys-cancel");
        let send = button(&t!(UiTbSend), "recipient-keys-send");
        send.add_css_class("suggested-action");
        let header = adw::HeaderBar::new();
        header.set_show_end_title_buttons(false);
        header.set_show_start_title_buttons(false);
        header.pack_start(&cancel);
        header.pack_end(&send);
        let view = adw::ToolbarView::new();
        view.add_top_bar(&header);
        view.set_content(Some(&content));
        let dialog = adw::Dialog::builder()
            .title(t!(UiRecipientKeysTitle))
            .content_width(560)
            .child(&view)
            .build();
        dialog.set_widget_name(DIALOG_NAME);
        for (button, said) in [
            (&cancel, KeysAnswer::Cancel),
            (&unencrypted, KeysAnswer::SendUnencrypted),
            (&send, KeysAnswer::Send),
        ] {
            let answer = answer.clone();
            button.connect_clicked(move |_| {
                let _ = answer.try_send(said);
            });
        }
        dialog.connect_closed(move |_| {
            let _ = answer.try_send(KeysAnswer::Cancel);
        });
        RecipientKeys {
            dialog,
            intro,
            list,
            send,
            cancel,
            unencrypted,
            note,
            act,
            shown: RefCell::default(),
        }
    }

    /// The window as the core says it now; its rows made again only when the recipients or their keys changed
    fn fill(&self, security: &ComposeSecurity) {
        self.intro.set_text(&security.keys_intro);
        if *self.shown.borrow() != security.recipients {
            self.list.remove_all();
            for (index, recipient) in security.recipients.iter().enumerate() {
                self.list.append(&self.row(index, recipient));
                if let Some(pending) = &recipient.pending {
                    self.list.append(&self.pending_row(index, recipient, pending));
                }
            }
            *self.shown.borrow_mut() = security.recipients.clone();
        }
        self.send.set_sensitive(security.can_send);
        self.unencrypted.set_sensitive(security.can_send_unencrypted);
        // why it can not go without encryption, under its button
        self.note.set_text(&security.unencrypted_text);
        self.note.set_visible(!security.can_send_unencrypted);
        self.unencrypted
            .set_tooltip_text((!security.can_send_unencrypted).then_some(security.unencrypted_text.as_str()));
        let default = if security.send_default {
            &self.send
        } else {
            &self.cancel
        };
        self.dialog.set_default_widget(Some(default));
    }

    fn row(&self, index: usize, recipient: &Recipient) -> adw::ActionRow {
        let subtitle = if recipient.label == recipient.address {
            recipient.text.clone()
        } else {
            format!("{} · {}", recipient.address, recipient.text)
        };
        let row = adw::ActionRow::builder()
            .title(glib::markup_escape_text(&recipient.label))
            .subtitle(glib::markup_escape_text(&subtitle))
            .subtitle_lines(0)
            .build();
        row.set_widget_name(&format!("recipient-key-{index}"));
        let picture = key_picture(recipient.key);
        let badge = gtk::Box::new(gtk::Orientation::Horizontal, 0);
        badge.add_css_class("key-chip-picture");
        badge.append(&picture);
        set_tone(&badge, recipient.tone);
        // the lock in the tone's colour, as on the Keys row
        badge.add_css_class("security-tint");
        row.add_prefix(&badge);
        if !recipient.has_key {
            let find = gtk::Button::with_mnemonic(&gtk_mnemonic(&t!(UiRecipientFindKey)));
            find.set_valign(gtk::Align::Center);
            find.set_sensitive(recipient.can_find);
            find.set_widget_name(&format!("recipient-key-find-{index}"));
            let (act, address) = (self.act.clone(), recipient.address.clone());
            find.connect_clicked(move |_| act(RowAction::Find(address.clone())));
            row.add_suffix(&find);
        }
        let remove = crate::icons::kept(gtk::Button::from_icon_name("ic-dismiss-symbolic"));
        remove.add_css_class("flat");
        remove.set_valign(gtk::Align::Center);
        let remove_label = without_mnemonic(&t!(UiRecipientRemove));
        remove.set_tooltip_text(Some(&remove_label));
        remove.update_property(&[gtk::accessible::Property::Label(&format!(
            "{remove_label}: {}",
            recipient.label
        ))]);
        remove.set_widget_name(&format!("recipient-key-remove-{index}"));
        let (act, address) = (self.act.clone(), recipient.address.clone());
        remove.connect_clicked(move |_| act(RowAction::Remove(address.clone())));
        row.add_suffix(&remove);
        row
    }

    /// A newer key waiting: what the core says of it, Use the New Key and Keep the Current One
    fn pending_row(&self, index: usize, recipient: &Recipient, pending: &str) -> adw::ActionRow {
        let row = adw::ActionRow::builder()
            .title(glib::markup_escape_text(pending))
            .title_lines(0)
            .build();
        row.set_widget_name(&format!("recipient-key-pending-{index}"));
        let icon = crate::icons::image("ic-warning-symbolic");
        icon.add_css_class("warning");
        row.add_prefix(&icon);
        let buttons = gtk::Box::new(gtk::Orientation::Vertical, 6);
        buttons.set_valign(gtk::Align::Center);
        buttons.set_margin_top(6);
        buttons.set_margin_bottom(6);
        for (text, use_new, name) in [
            (t!(UiContactKeyUseNew), true, "use-new"),
            (t!(UiContactKeyKeep), false, "keep"),
        ] {
            let button = gtk::Button::with_mnemonic(&gtk_mnemonic(&text));
            button.set_widget_name(&format!("recipient-key-{name}-{index}"));
            let (act, address) = (self.act.clone(), recipient.address.clone());
            button.connect_clicked(move |_| act(RowAction::Decide(address.clone(), use_new)));
            buttons.append(&button);
        }
        row.add_suffix(&buttons);
        row
    }
}

/// Recipients' Keys over the compose window (once). Send there sends, Send Without Encryption turns Encrypt off (asking
/// first as the switch does while the message carries something encrypted) and sends with the user's own Sign
pub async fn recipient_keys(compose: &Rc<Compose>) {
    let p = &compose.protection;
    if p.keys_dialog.borrow().is_some() {
        return;
    }
    let weak = Rc::downgrade(compose);
    let act: Rc<dyn Fn(RowAction)> = Rc::new(move |action| {
        let Some(this) = weak.upgrade() else { return };
        // after the click's own handler is done with the row it is in, which the window then makes again
        glib::idle_add_local_once(move || row_action(&this, action));
    });
    let (send, answers) = async_channel::unbounded();
    let window = Rc::new(RecipientKeys::new(act, send));
    *p.keys_dialog.borrow_mut() = Some(window.clone());
    refresh(compose);
    window.dialog.present(Some(&compose.window));
    let answer = answers.recv().await.unwrap_or(KeysAnswer::Cancel);
    p.keys_dialog.borrow_mut().take();
    window.dialog.close();
    match answer {
        KeysAnswer::Cancel => {}
        KeysAnswer::Send => compose.send_now(),
        KeysAnswer::SendUnencrypted => {
            if send_unencrypted(compose).await {
                compose.send_now();
            }
        }
    }
}

/// Send Without Encryption: Encrypt off through the core, its question asked first when it has one; true when the
/// message may go now
async fn send_unencrypted(compose: &Rc<Compose>) -> bool {
    let core = &shell().core;
    let account = compose.account.get();
    let Ok(mut toggled) = core.compose_send_unencrypted(account, &compose.outgoing_now()) else {
        return false;
    };
    apply(compose, &toggled);
    refresh(compose);
    if toggled.question != Question::None {
        if !ask(compose, &toggled).await {
            return false;
        }
        let Ok(confirmed) = core.compose_toggle(account, &compose.outgoing_now(), Switch::Encrypt, false, true) else {
            return false;
        };
        apply(compose, &confirmed);
        refresh(compose);
        toggled = confirmed;
    }
    toggled.question == Question::None && !toggled.encrypt
}

fn row_action(compose: &Rc<Compose>, action: RowAction) {
    let core = &shell().core;
    match action {
        RowAction::Find(address) => {
            if let Ok(Some(request)) = core.compose_find_key(&address) {
                compose.protection.lookups.borrow_mut().push(request);
            }
        }
        RowAction::Remove(address) => {
            let (to, cc, bcc) = pe_core::compose_keys::without_recipient(&compose.outgoing_now(), &address);
            compose.set_recipients(&to, &cc, &bcc);
        }
        RowAction::Decide(address, use_new) => {
            let _ = core.pgp_decide(&address, use_new);
        }
    }
    refresh(compose);
}

/// The key of `key` pressed with `modifiers`, as the window's keys take it (the UI test's Ctrl+Shift+E in the text)
#[cfg(feature = "e2e")]
pub fn press_in_editor(compose: &Compose, key: gtk::gdk::Key, modifiers: gtk::gdk::ModifierType) -> bool {
    let controllers = compose.editor.document.view.observe_controllers();
    (0..controllers.n_items())
        .filter_map(|i| controllers.item(i).and_downcast::<gtk::EventControllerKey>())
        .any(|keys| {
            keys.emit_by_name::<bool>(
                "key-pressed",
                &[&glib::translate::IntoGlib::into_glib(key), &0u32, &modifiers],
            )
        })
}
