//! Encryption keys: the Encryption Keys window (Tools) with the user's own keys and their contacts' keys, New Key,
//! Import, Export, Back Up, Key Properties and Verify Key; the Security part of an account's Properties (the key of
//! its addresses and whether its mail carries it); and a contact's key in Contact Properties. The core makes, reads,
//! keeps and checks the keys (`pe_core::keys`): these windows show what it gives, hand it the bytes of a file chosen
//! without reading them, and write out the text it makes.

use std::cell::RefCell;
use std::path::Path;
use std::rc::Rc;

use adw::prelude::*;
use gtk::{gdk, glib};
use pe_core::keys::{ImportError, Imported, KeyInfo, KeySource, KeyState};

use crate::app::shell;
use crate::ui;
use crate::words::{self, Text, field_title, plain};

/// The file kinds of a key file, before All files
const KEY_FILES: [&str; 4] = ["*.asc", "*.gpg", "*.pgp", "*.key"];

/// `text` written to `path`; false, with the reason said, when it could not be
async fn write_out(parent: &impl IsA<gtk::Widget>, title: &str, path: &Path, text: &str) -> bool {
    match std::fs::write(path, text) {
        Ok(()) => true,
        Err(error) => {
            ui::alert(parent, title, &error.to_string()).await;
            false
        }
    }
}

fn window(parent: &impl IsA<gtk::Widget>) -> gtk::Window {
    ui::window_of(parent).unwrap_or_else(|| shell().main().window().clone().upcast())
}

// ---- New Key and the backup ----

/// Makes a key for `account` and offers to back it up at once; its fingerprint, None when it could not be made
pub async fn make_key(parent: &impl IsA<gtk::Widget>, account: i64) -> Option<String> {
    match shell().core.pgp_generate(account) {
        Ok(fingerprint) => {
            offer_backup(parent, &fingerprint).await;
            Some(fingerprint)
        }
        Err(error) => {
            ui::alert(parent, &t!(UiKeysNewTitle), &error.to_string()).await;
            None
        }
    }
}

/// "Your new key is ready": Save a Backup opens Back Up for it, Later goes on
async fn offer_backup(parent: &impl IsA<gtk::Widget>, fingerprint: &str) {
    let (later, now) = (plain(Text::UiKeysLater), plain(Text::UiKeysBackupNow));
    let answer = ui::ask(
        parent,
        &t!(UiKeysNewTitle),
        &t!(UiKeysBackupOffer),
        &[("later", later.as_str()), ("backup", now.as_str())],
        "backup",
        "later",
        None,
    )
    .await;
    if answer == "backup" {
        backup(parent, fingerprint).await;
    }
}

/// New Key: the account it is for (the only one chosen), a word when private keys are not kept after the app closes,
/// Make Key; the new key's fingerprint, None for Cancel. The backup is offered by the caller, once its list shows the key
async fn new_key(parent: &impl IsA<gtk::Widget>) -> Option<String> {
    let core = &shell().core;
    let accounts = core.accounts().unwrap_or_default();
    let titles = pe_core::account_titles(&accounts);
    let content = gtk::Box::new(gtk::Orientation::Vertical, 12);
    content.set_margin_start(18);
    content.set_margin_end(18);
    content.set_margin_top(12);
    content.set_margin_bottom(18);
    let choice = adw::ComboRow::builder()
        .title(field_title(Text::UiKeysNewFor))
        .model(&gtk::StringList::new(
            &titles.iter().map(String::as_str).collect::<Vec<_>>(),
        ))
        .build();
    choice.set_widget_name("key-new-account");
    if accounts.is_empty() {
        let none = ui::wrapped_label(&t!(UiKeysNoAccount));
        none.set_widget_name("key-new-none");
        content.append(&none);
    } else {
        let group = adw::PreferencesGroup::new();
        group.add(&choice);
        content.append(&group);
    }
    if !core.pgp_private_keys_kept() {
        content.append(&memory_only());
    }
    let (dialog, make) = ui::dialog_with_buttons(&t!(UiKeysNewTitle), &content, &plain(Text::UiKeysNewMake), 480);
    dialog.set_widget_name("key-new-dialog");
    make.set_sensitive(!accounts.is_empty());
    let clicks = ui::answers(&dialog, &make);
    dialog.present(Some(parent.as_ref()));
    choice.grab_focus();
    let mut made = None;
    while let Ok(true) = clicks.recv().await {
        let Some(account) = accounts.get(choice.selected() as usize) else {
            continue;
        };
        match core.pgp_generate(account.id) {
            Ok(fingerprint) => {
                made = Some(fingerprint);
                break;
            }
            Err(error) => ui::alert(&dialog, &t!(UiKeysNewTitle), &error.to_string()).await,
        }
    }
    dialog.close();
    made
}

/// The word that private keys made or imported now are gone once the app closes, with a warning sign
fn memory_only() -> gtk::Box {
    let icon = crate::icons::image("dialog-warning-symbolic");
    icon.set_valign(gtk::Align::Start);
    icon.add_css_class("warning");
    let label = ui::wrapped_label(&t!(UiKeysMemoryOnly));
    label.set_hexpand(true);
    let warning = gtk::Box::new(gtk::Orientation::Horizontal, 10);
    warning.add_css_class("key-warning");
    warning.set_widget_name("key-memory-only");
    warning.append(&icon);
    warning.append(&label);
    warning
}

/// Back Up Key: a passphrase typed twice, what the core says of it under the fields and OK only once it can be used,
/// then the file to save the key under it to
pub async fn backup(parent: &impl IsA<gtk::Widget>, fingerprint: &str) {
    let title = t!(UiKeysBackupTitle);
    let pair = Rc::new(ui::PassphrasePair::new("key-passphrase"));
    let content = gtk::Box::new(gtk::Orientation::Vertical, 12);
    content.set_margin_start(18);
    content.set_margin_end(18);
    content.set_margin_top(12);
    content.set_margin_bottom(18);
    content.append(&ui::wrapped_label(&t!(UiKeysBackupIntro)));
    content.append(&pair.group);
    content.append(&pair.feedback);
    // scrolled when the window is too low for it (a small screen, a tiled window), so OK and the fields stay in reach
    let scrolled = gtk::ScrolledWindow::builder()
        .child(&content)
        .hscrollbar_policy(gtk::PolicyType::Never)
        .propagate_natural_height(true)
        .build();
    let (dialog, ok) = ui::dialog_with_buttons(&title, &scrolled, &t!(UiOk), 480);
    dialog.set_widget_name("key-backup-dialog");
    {
        let (checked, ok) = (pair.clone(), ok.clone());
        pair.connect_changed(move || ok.set_sensitive(checked.check()));
    }
    ok.set_sensitive(pair.check());
    let clicks = ui::answers(&dialog, &ok);
    dialog.present(Some(parent.as_ref()));
    pair.first.grab_focus();
    let file_name = shell().core.pgp_file_name(fingerprint, true).unwrap_or_default();
    while let Ok(true) = clicks.recv().await {
        if !pair.check() {
            continue;
        }
        let filter = t!(UiKeysFileFilter);
        let Some(path) = ui::save_file(&window(&dialog), &title, &file_name, Some((&filter, &KEY_FILES))).await else {
            continue;
        };
        let chosen = pair.take();
        let made = shell().core.pgp_backup(fingerprint, &chosen);
        ui::wipe(chosen);
        match made {
            Ok(text) => {
                if write_out(&dialog, &title, &path, &text).await {
                    ui::alert(&dialog, &title, &t!(UiKeysBackupSaved)).await;
                }
            }
            Err(error) => ui::alert(&dialog, &title, &error.to_string()).await,
        }
        break;
    }
    pair.clear();
    dialog.close();
}

// ---- Import ----

/// Import: a key file chosen and its bytes handed to the core, a passphrase asked for when it wants one, what it did
/// said, and a private key offered for the user's addresses it holds; the first key imported
async fn import(parent: &impl IsA<gtk::Widget>) -> Option<String> {
    let title = t!(UiKeysImportTitle);
    let filter = t!(UiKeysFileFilter);
    let path = ui::open_file(&window(parent), &title, Some((&filter, &KEY_FILES))).await?;
    let bytes = match std::fs::read(&path) {
        Ok(bytes) => bytes,
        Err(error) => {
            ui::alert(parent, &title, &error.to_string()).await;
            return None;
        }
    };
    import_bytes(parent, &title, &bytes, KeySource::File).await
}

/// Import from Clipboard: the clipboard's text (empty without any) handed to the core as a file's bytes are, the same
/// questions asked; the core says when it holds no key. The first key imported
async fn paste(parent: &impl IsA<gtk::Widget>) -> Option<String> {
    let title = words::title(Text::UiKeysPaste);
    let text = parent
        .as_ref()
        .clipboard()
        .read_text_future()
        .await
        .ok()
        .flatten()
        .map(|text| text.to_string())
        .unwrap_or_default();
    import_bytes(parent, &title, text.as_bytes(), KeySource::Paste).await
}

/// The keys in `bytes` imported: a passphrase asked for when the core wants one, what it did said under `title`, and
/// a private key offered for the user's addresses it holds; the first key imported
async fn import_bytes(parent: &impl IsA<gtk::Widget>, title: &str, bytes: &[u8], source: KeySource) -> Option<String> {
    let outcome = match shell().core.pgp_import(bytes, None, source) {
        Err(ImportError::NeedsPassphrase | ImportError::WrongPassphrase) => {
            match import_with_passphrase(parent, bytes, source).await {
                Some(outcome) => outcome,
                None => return None,
            }
        }
        outcome => outcome,
    };
    match outcome {
        Ok(imported) => {
            learned();
            ui::alert(parent, title, &imported.summary()).await;
            offer_unclaimed(parent).await;
            imported.keys.into_iter().next()
        }
        Err(error) => {
            ui::alert(parent, title, &error.text()).await;
            None
        }
    }
}

/// The passphrase of a protected key asked for until it opens it or Cancel; what the import with it did
async fn import_with_passphrase(
    parent: &impl IsA<gtk::Widget>,
    bytes: &[u8],
    source: KeySource,
) -> Option<Result<Imported, ImportError>> {
    let bytes = bytes.to_vec();
    ui::ask_passphrase(
        parent,
        &t!(UiKeysImportTitle),
        &t!(UiKeysImportPassphrase),
        "key-import",
        move |core, typed| {
            let tried = core.pgp_import(&bytes, Some(&typed), source);
            ui::wipe(typed);
            match tried {
                Err(wrong @ (ImportError::WrongPassphrase | ImportError::NeedsPassphrase)) => {
                    ui::Attempt::Again(wrong.text())
                }
                done => ui::Attempt::Done(done),
            }
        },
    )
    .await
}

/// Keys were taken into the key book here (an import, a lookup): the windows that show them read them again, the
/// Address Book its key marks and every compose window its locks
pub fn learned() {
    crate::address_book::refresh();
    crate::compose_keys::refresh_all();
}

/// Import Key on a key attached to a message: what the core did said, and a private key offered as after any import
/// (none comes from mail, but the question is the same)
pub async fn imported_attachment(parent: &impl IsA<gtk::Widget>, outcome: Result<Imported, ImportError>) {
    let title = words::title(Text::UiAttachmentImportKey);
    match outcome {
        Ok(imported) => {
            learned();
            ui::alert(parent, &title, &imported.summary()).await;
            offer_unclaimed(parent).await;
        }
        Err(error) => ui::alert(parent, &title, &error.text()).await,
    }
}

/// "Use this key for ...?" for the user's addresses an own key holds that use no key yet
async fn offer_unclaimed(parent: &impl IsA<gtk::Widget>) {
    let core = &shell().core;
    let Some(question) = core.pgp_unclaimed_question().ok().flatten() else {
        return;
    };
    let (not_now, use_it) = (plain(Text::UiKeysNotNow), plain(Text::UiKeysUse));
    let answer = ui::ask(
        parent,
        &t!(UiKeysImportTitle),
        &question,
        &[("not-now", not_now.as_str()), ("use", use_it.as_str())],
        "use",
        "not-now",
        None,
    )
    .await;
    if answer == "use" {
        let _ = core.pgp_claim_unclaimed();
    }
}

// ---- Export ----

/// Export: the public key saved to a file chosen, under the name the core gives it
async fn export(parent: &impl IsA<gtk::Widget>, key: &KeyInfo) {
    let core = &shell().core;
    let title = words::title(Text::UiKeysExport);
    let name = core.pgp_file_name(&key.fingerprint, false).unwrap_or_default();
    let filter = t!(UiKeysFileFilter);
    let Some(path) = ui::save_file(&window(parent), &title, &name, Some((&filter, &KEY_FILES))).await else {
        return;
    };
    match core.pgp_export(&key.fingerprint) {
        Ok(text) => {
            write_out(parent, &title, &path, &text).await;
        }
        Err(error) => ui::alert(parent, &title, &error.to_string()).await,
    }
}

// ---- Publish ----

/// Publish: what it does asked first (the key's addresses named), then the public key sent to keys.openpgp.org, and
/// what the server did said once it answered (over the main window when Encryption Keys closed meanwhile)
async fn publish(parent: &gtk::Widget, key: &KeyInfo, button: &gtk::Button, closed: &std::cell::Cell<bool>) {
    let title = words::title(Text::UiKeysPublish);
    let question = &key.publish_question;
    let (cancel, now) = (t!(UiCancel), plain(Text::UiKeysPublishNow));
    let answers = [("cancel", cancel.as_str()), ("publish", now.as_str())];
    if ui::ask(parent, &title, question, &answers, "publish", "cancel", None).await != "publish" {
        return;
    }
    let core = &shell().core;
    // greyed while the server is asked
    button.set_sensitive(false);
    let request = match core.pgp_publish(&key.fingerprint) {
        Ok(request) => request,
        Err(error) => {
            ui::alert(parent, &title, &error.to_string()).await;
            return;
        }
    };
    if !ui::wait_read(parent, request).await {
        return;
    }
    let Some(outcome) = core.pgp_publish_result(request) else {
        return;
    };
    let main: gtk::Widget = shell().main().window().clone().upcast();
    let over = if closed.get() { &main } else { parent };
    // as the core wrote it: it starts with the server's name, in lower case
    let ok = t!(UiOk);
    ui::ask(over, &title, &outcome.text, &[("ok", ok.as_str())], "ok", "ok", None).await;
}

// ---- Key Properties and Verify Key ----

/// A row of Key Properties: the field's name and its value, which can be selected and copied
fn property_row(label: Text, value: &str, name: &str) -> adw::ActionRow {
    let row = adw::ActionRow::builder()
        .title(field_title(label))
        .subtitle(glib::markup_escape_text(value))
        .subtitle_selectable(true)
        .build();
    row.add_css_class("property");
    row.set_widget_name(name);
    row
}

/// Key Properties: its names, fingerprint, state, dates, kind, where it came from and its addresses; Verify for a
/// contact's key. True when the key was verified (or no longer) from here
async fn properties(parent: &impl IsA<gtk::Widget>, key: &KeyInfo) -> bool {
    let group = adw::PreferencesGroup::new();
    group.add(&property_row(Text::UiKeyNames, &key.user_ids.join("\n"), "key-names"));
    let fingerprint = property_row(Text::UiKeyFingerprint, &key.grouped, "key-fingerprint");
    fingerprint.add_css_class("fingerprint");
    group.add(&fingerprint);
    group.add(&property_row(Text::UiKeyStatus, &key.status, "key-status"));
    group.add(&property_row(Text::UiKeyCreated, &key.created_text, "key-created"));
    group.add(&property_row(Text::UiKeyExpires, &key.expires_text, "key-expires"));
    group.add(&property_row(Text::UiKeyAlgorithm, &key.algorithm, "key-algorithm"));
    group.add(&property_row(Text::UiKeySource, &key.source, "key-source"));
    group.add(&property_row(
        Text::UiKeyAddresses,
        &key.address_lines.join("\n"),
        "key-addresses",
    ));
    let content = gtk::Box::new(gtk::Orientation::Vertical, 12);
    content.set_margin_start(18);
    content.set_margin_end(18);
    content.set_margin_top(6);
    content.set_margin_bottom(18);
    content.append(&group);
    let scrolled = gtk::ScrolledWindow::builder()
        .child(&content)
        .hscrollbar_policy(gtk::PolicyType::Never)
        .propagate_natural_height(true)
        .build();
    let header = adw::HeaderBar::new();
    let (send, clicks) = async_channel::unbounded::<&'static str>();
    if key.can_verify {
        let verify = gtk::Button::with_label(&plain(Text::UiKeysVerify));
        verify.set_widget_name("key-properties-verify");
        let send = send.clone();
        verify.connect_clicked(move |_| {
            let _ = send.try_send("verify");
        });
        header.pack_start(&verify);
    }
    let view = adw::ToolbarView::new();
    view.add_top_bar(&header);
    view.set_content(Some(&scrolled));
    let dialog = adw::Dialog::builder()
        .title(t!(UiKeyPropertiesTitle))
        .content_width(520)
        .child(&view)
        .build();
    dialog.set_widget_name("key-properties-dialog");
    dialog.connect_closed(move |_| {
        let _ = send.try_send("close");
    });
    dialog.present(Some(parent.as_ref()));
    let mut changed = false;
    if let Ok("verify") = clicks.recv().await {
        dialog.close();
        changed = verify(parent, key).await;
    }
    dialog.close();
    changed
}

/// Verify Key: the fingerprint to compare with the one its owner reads out, They Match marking each of its addresses
/// verified; for a key verified already, Mark as Not Verified. True when the mark changed
pub async fn verify(parent: &impl IsA<gtk::Widget>, key: &KeyInfo) -> bool {
    let name = key.name.clone();
    let fingerprint = gtk::Label::new(Some(&key.fingerprint_lines));
    fingerprint.add_css_class("fingerprint-large");
    fingerprint.set_justify(gtk::Justification::Center);
    fingerprint.set_widget_name("key-verify-fingerprint");
    let said = gtk::Label::new(Some(&t!(UiVerifyFingerprint)));
    said.add_css_class("dim-label");
    let extra = gtk::Box::new(gtk::Orientation::Vertical, 8);
    extra.append(&said);
    extra.append(&fingerprint);
    // not verified yet: every address They Match marks, so one that is not theirs is seen
    if !key.verified {
        let marks = ui::wrapped_label(&key.verify_marks);
        // centred, as the rest of the dialog is
        marks.set_justify(gtk::Justification::Center);
        marks.set_xalign(0.5);
        marks.set_widget_name("key-verify-marks");
        extra.append(&marks);
    }
    let dialog = adw::AlertDialog::new(
        Some(&t!(UiVerifyTitle)),
        Some(&ui::no_lone_word(&t!(UiVerifyIntro, name = &*name))),
    );
    dialog.set_widget_name("key-verify-dialog");
    dialog.set_extra_child(Some(&extra));
    if key.verified {
        dialog.add_response("close", &t!(UiClose));
        dialog.add_response("unmark", &plain(Text::UiVerifyUnmark));
        dialog.set_default_response(Some("close"));
        dialog.set_close_response("close");
    } else {
        dialog.add_response("cancel", &t!(UiCancel));
        dialog.add_response("differ", &plain(Text::UiVerifyDiffer));
        dialog.add_response("match", &plain(Text::UiVerifyMatch));
        dialog.set_response_appearance("match", adw::ResponseAppearance::Suggested);
        // Enter does not mark a key verified: the user clicks They Match
        dialog.set_default_response(Some("cancel"));
        dialog.set_close_response("cancel");
    }
    let answer = dialog.choose_future(Some(parent.as_ref())).await;
    let mark = |verified: bool| {
        let _ = shell().core.pgp_set_key_verified(&key.fingerprint, verified);
    };
    match answer.as_str() {
        "match" => {
            mark(true);
            true
        }
        "unmark" => {
            mark(false);
            true
        }
        "differ" => {
            ui::alert(parent, &t!(UiVerifyTitle), &t!(UiVerifyDiffers, name = &*name)).await;
            false
        }
        _ => false,
    }
}

// ---- the Encryption Keys window ----

struct KeysWindow {
    list: gtk::ListBox,
    keys: RefCell<Vec<KeyInfo>>,
    export: gtk::Button,
    publish: gtk::Button,
    backup: gtk::Button,
    verify: gtk::Button,
    properties: gtk::Button,
    remove: gtk::Button,
}

impl KeysWindow {
    fn selected(&self) -> Option<KeyInfo> {
        let index = usize::try_from(self.list.selected_row()?.index()).ok()?;
        self.keys.borrow().get(index).cloned()
    }

    /// The buttons of the key selected, greyed where they do not apply to it
    fn show_selected(&self) {
        let key = self.selected();
        self.export.set_sensitive(key.is_some());
        // only the user's own key: a contact's is theirs to publish
        self.publish.set_sensitive(key.as_ref().is_some_and(|k| k.own));
        self.backup.set_sensitive(key.as_ref().is_some_and(|k| k.can_back_up));
        self.verify.set_sensitive(key.as_ref().is_some_and(|k| k.can_verify));
        self.properties.set_sensitive(key.is_some());
        self.remove.set_sensitive(key.is_some());
    }

    /// A row per key, own keys first as the core orders them; the key `select` (or the one at `at`) stays selected
    fn fill(&self, select: Option<&str>, at: usize) {
        // the rows only: the list's first child can be its placeholder, the text of an empty list
        while let Some(row) = self.list.row_at_index(0) {
            self.list.remove(&row);
        }
        let keys = shell().core.pgp_keys().unwrap_or_default();
        for (index, key) in keys.iter().enumerate() {
            self.list.append(&key_row(key, index));
        }
        let chosen = select
            .and_then(|fingerprint| keys.iter().position(|k| k.fingerprint == fingerprint))
            .unwrap_or_else(|| at.min(keys.len().saturating_sub(1)));
        *self.keys.borrow_mut() = keys;
        self.list.select_row(self.list.row_at_index(chosen as i32).as_ref());
        self.show_selected();
    }
}

/// A key's row: its name over its address, what it is and its state at the end
fn key_row(key: &KeyInfo, index: usize) -> adw::ActionRow {
    let address = key.addresses.first().map(|(a, _)| a.as_str()).unwrap_or_default();
    let row = adw::ActionRow::builder()
        .title(glib::markup_escape_text(&key.name))
        .subtitle(glib::markup_escape_text(address))
        .build();
    row.set_widget_name(&format!("keys-row-{index}"));
    let status = gtk::Label::new(Some(&key.status));
    status.set_xalign(1.0);
    status.set_widget_name("keys-row-status");
    if key.state != KeyState::Valid {
        status.add_css_class("warning");
    }
    let kind = gtk::Label::new(Some(&if key.own {
        t!(UiKeysKindOwn)
    } else {
        t!(UiKeysKindContact)
    }));
    kind.set_xalign(1.0);
    kind.add_css_class("dim-label");
    kind.add_css_class("caption");
    kind.set_widget_name("keys-row-kind");
    let end = gtk::Box::new(gtk::Orientation::Vertical, 2);
    end.set_valign(gtk::Align::Center);
    end.append(&status);
    end.append(&kind);
    row.add_suffix(&end);
    row
}

thread_local! {
    /// The Encryption Keys window while it is open: one at a time
    static OPEN: RefCell<Option<glib::WeakRef<adw::Dialog>>> = const { RefCell::new(None) };
}

/// Tools > Encryption Keys: the user's keys and their contacts', to make, import, export, back up, verify, look at
/// and remove
pub async fn keys_dialog(parent: &impl IsA<gtk::Widget>) {
    if OPEN.with(|open| open.borrow().as_ref().and_then(|d| d.upgrade()).is_some()) {
        return;
    }
    let list = gtk::ListBox::new();
    list.add_css_class("boxed-list");
    list.set_widget_name("keys-list");
    let none = ui::wrapped_label(&t!(UiKeysEmpty));
    none.set_widget_name("keys-none");
    // in the middle of the empty list, as the Message Rules' words
    none.set_xalign(0.5);
    none.set_justify(gtk::Justification::Center);
    none.add_css_class("dim-label");
    none.set_margin_top(18);
    none.set_margin_bottom(18);
    none.set_margin_start(12);
    none.set_margin_end(12);
    list.set_placeholder(Some(&none));
    let (send, clicks) = async_channel::unbounded::<&'static str>();
    let button = |text: Text, id: &'static str| {
        let button = gtk::Button::with_label(&plain(text));
        button.set_widget_name(&format!("keys-{id}"));
        let send = send.clone();
        button.connect_clicked(move |_| {
            let _ = send.try_send(id);
        });
        button
    };
    let new = button(Text::UiKeysNew, "new");
    let import_button = button(Text::UiKeysImport, "import");
    let paste_button = button(Text::UiKeysPaste, "paste");
    let export_button = button(Text::UiKeysExport, "export");
    let publish_button = button(Text::UiKeysPublish, "publish");
    let backup_button = button(Text::UiKeysBackup, "backup");
    let verify_button = button(Text::UiKeysVerify, "verify");
    let properties_button = button(Text::UiProperties, "properties");
    let remove = button(Text::UiRemove, "remove");
    let buttons = gtk::Box::new(gtk::Orientation::Vertical, 6);
    buttons.append(&new);
    buttons.append(&import_button);
    buttons.append(&paste_button);
    // the buttons of the key selected apart from the two that add one
    let apart = gtk::Separator::new(gtk::Orientation::Horizontal);
    apart.add_css_class("spacer");
    apart.set_margin_top(6);
    apart.set_margin_bottom(6);
    buttons.append(&apart);
    for button in [
        &export_button,
        &publish_button,
        &backup_button,
        &verify_button,
        &properties_button,
        &remove,
    ] {
        buttons.append(button);
    }
    let window = Rc::new(KeysWindow {
        list: list.clone(),
        keys: RefCell::default(),
        export: export_button,
        publish: publish_button,
        backup: backup_button,
        verify: verify_button,
        properties: properties_button,
        remove,
    });
    window.fill(None, 0);
    let selected = Rc::downgrade(&window);
    list.connect_row_selected(move |_, _| {
        if let Some(window) = selected.upgrade() {
            window.show_selected();
        }
    });
    let activated = send.clone();
    list.connect_row_activated(move |_, _| {
        let _ = activated.try_send("properties");
    });
    let keys = gtk::EventControllerKey::new();
    let deleted = send.clone();
    keys.connect_key_pressed(move |_, key, _, _| {
        if key == gdk::Key::Delete {
            let _ = deleted.try_send("remove");
            return glib::Propagation::Stop;
        }
        glib::Propagation::Proceed
    });
    list.add_controller(keys);
    let row = gtk::Box::new(gtk::Orientation::Horizontal, 12);
    let scrolled = gtk::ScrolledWindow::builder()
        .child(&list)
        .min_content_height(260)
        .hexpand(true)
        .hscrollbar_policy(gtk::PolicyType::Never)
        .build();
    row.append(&scrolled);
    row.append(&buttons);
    let content = gtk::Box::new(gtk::Orientation::Vertical, 12);
    content.set_margin_start(18);
    content.set_margin_end(18);
    content.set_margin_bottom(18);
    content.append(&ui::wrapped_label(&t!(UiKeysIntro)));
    content.append(&row);
    let view = adw::ToolbarView::new();
    view.add_top_bar(&adw::HeaderBar::new());
    view.set_content(Some(&content));
    let dialog = adw::Dialog::builder()
        .title(t!(UiKeysTitle))
        .content_width(680)
        .child(&view)
        .build();
    dialog.set_widget_name("keys-dialog");
    // closed with its close button or Esc, or by another part of the app while a question of the loop below waited
    let closed: Rc<std::cell::Cell<bool>> = Rc::default();
    let shut = closed.clone();
    dialog.connect_closed(move |_| {
        shut.set(true);
        let _ = send.try_send("close");
    });
    OPEN.with(|open| *open.borrow_mut() = Some(dialog.downgrade()));
    dialog.present(Some(parent.as_ref()));
    let host = dialog.clone().upcast::<gtk::Widget>();
    while let Ok(click) = clicks.recv().await {
        let at = list.selected_row().map_or(0, |row| row.index().max(0) as usize);
        let key = window.selected();
        let fingerprint = key.as_ref().map(|k| k.fingerprint.clone());
        match (click, key) {
            ("close", _) => break,
            ("new", _) => {
                let made = new_key(&host).await;
                window.fill(made.as_deref().or(fingerprint.as_deref()), at);
                if let Some(made) = made {
                    offer_backup(&host, &made).await;
                }
            }
            // the key imported selected, so the user sees it in the list
            ("import", _) => {
                let imported = import(&host).await;
                window.fill(imported.as_deref().or(fingerprint.as_deref()), at);
            }
            ("paste", _) => {
                let imported = paste(&host).await;
                window.fill(imported.as_deref().or(fingerprint.as_deref()), at);
            }
            ("export", Some(key)) => export(&host, &key).await,
            ("publish", Some(key)) if key.own => {
                publish(&host, &key, &window.publish, &closed).await;
                window.show_selected();
            }
            ("backup", Some(key)) if key.can_back_up => {
                backup(&host, &key.fingerprint).await;
            }
            ("verify", Some(key)) if key.can_verify => {
                if verify(&host, &key).await {
                    window.fill(fingerprint.as_deref(), at);
                }
            }
            ("properties", Some(key)) => {
                if properties(&host, &key).await {
                    window.fill(fingerprint.as_deref(), at);
                }
            }
            ("remove", Some(key)) => {
                if !ui::confirm(&host, &t!(UiKeysTitle), &key.remove_question, true).await {
                    continue;
                }
                if let Err(error) = shell().core.pgp_remove(&key.fingerprint) {
                    ui::alert(&host, &t!(UiKeysTitle), &error.to_string()).await;
                }
                window.fill(None, at);
            }
            _ => {}
        }
    }
    OPEN.with(|open| open.borrow_mut().take());
    if !closed.get() {
        dialog.close();
    }
}

// ---- Account Properties: Security ----

/// The Security part of an account's Properties: the key of its addresses (None, or one of the user's own keys),
/// New Key for it, and whether its mail carries the public key
pub struct AccountSecurity {
    pub group: adw::PreferencesGroup,
    key: adw::ComboRow,
    autocrypt: adw::SwitchRow,
    /// The fingerprints of the key choice after None
    choices: RefCell<Vec<String>>,
}

impl AccountSecurity {
    pub fn new(account: i64) -> Rc<AccountSecurity> {
        let core = &shell().core;
        let identity = core.pgp_account_key(account).ok().flatten();
        let group = adw::PreferencesGroup::builder()
            .title(t!(UiAccountSecurity))
            .description(glib::markup_escape_text(&t!(UiAccountSecurityIntro)))
            .build();
        group.set_widget_name("account-security");
        let new = gtk::Button::with_label(&plain(Text::UiAccountKeyNew));
        new.set_valign(gtk::Align::Center);
        new.set_widget_name("account-key-new");
        group.set_header_suffix(Some(&new));
        // the key chosen under the words, where its name and fingerprint fit
        let key = adw::ComboRow::builder()
            .title(field_title(Text::UiAccountKey))
            .use_subtitle(true)
            .build();
        key.set_widget_name("account-key");
        let autocrypt = adw::SwitchRow::builder()
            .title(plain(Text::UiAccountAutocrypt))
            .active(identity.as_ref().is_none_or(|identity| identity.autocrypt))
            .build();
        autocrypt.set_widget_name("account-autocrypt");
        group.add(&key);
        group.add(&autocrypt);
        let security = Rc::new(AccountSecurity {
            group,
            key,
            autocrypt,
            choices: RefCell::default(),
        });
        security.fill(identity.map(|identity| identity.fingerprint).as_deref());
        let this = Rc::downgrade(&security);
        new.connect_clicked(move |button| {
            let (Some(this), button) = (this.upgrade(), button.clone()) else {
                return;
            };
            glib::spawn_future_local(async move {
                if let Some(fingerprint) = make_key(&button, account).await {
                    this.fill(Some(&fingerprint));
                }
            });
        });
        security
    }

    /// The choice of None and the user's own keys, `chosen` chosen
    fn fill(&self, chosen: Option<&str>) {
        let own: Vec<KeyInfo> = shell()
            .core
            .pgp_keys()
            .unwrap_or_default()
            .into_iter()
            .filter(|key| key.own)
            .collect();
        let mut labels = vec![t!(UiAccountKeyNone)];
        labels.extend(own.iter().map(|key| key.choice.clone()));
        self.key.set_model(Some(&gtk::StringList::new(
            &labels.iter().map(String::as_str).collect::<Vec<_>>(),
        )));
        let at = chosen
            .and_then(|fingerprint| own.iter().position(|key| key.fingerprint == fingerprint))
            .map_or(0, |i| i + 1);
        self.key.set_selected(at as u32);
        *self.choices.borrow_mut() = own.into_iter().map(|key| key.fingerprint).collect();
    }

    /// The key chosen made the account's (Autocrypt as set); None takes it away (the core changes nothing when
    /// neither changed, and leaves other addresses with a key of their own alone)
    pub fn apply(&self, account: i64) {
        let index = self.key.selected() as usize;
        let fingerprint = index
            .checked_sub(1)
            .and_then(|i| self.choices.borrow().get(i).cloned())
            .unwrap_or_default();
        let _ = shell()
            .core
            .pgp_set_account_key(account, &fingerprint, self.autocrypt.is_active());
    }
}

// ---- a contact's key ----

/// The keys section of Contact Properties: its rows, the addresses they are of, and Find Key (a saved card's only).
/// The group keeps it (its `destroy` handler), it holds the group and the button weakly
struct ContactKeys {
    group: glib::WeakRef<adw::PreferencesGroup>,
    rows: RefCell<Vec<gtk::Widget>>,
    card: pe_store::CardId,
    addresses: Vec<String>,
    find: glib::WeakRef<gtk::Button>,
    /// A lookup of Find Key is under way
    looking: std::cell::Cell<bool>,
}

/// The keys of a contact's addresses in Contact Properties: each address with a key in use, its fingerprint and
/// state, Verify; a newer key waiting with Use the New Key and Keep the Current One; Find Key in the section's header
/// for a saved card (`card` not 0), what it found said under the title. None for a card without an address
pub fn contact_keys(card: pe_store::CardId, addresses: &[String]) -> Option<adw::PreferencesGroup> {
    if addresses.is_empty() {
        return None;
    }
    let group = adw::PreferencesGroup::builder()
        .title(field_title(Text::UiContactKey))
        .build();
    group.set_widget_name("contact-keys");
    let find = (card != 0).then(|| {
        let button = gtk::Button::with_mnemonic(&pe_core::i18n::gtk_mnemonic(&t!(UiContactFindKey)));
        button.set_valign(gtk::Align::Center);
        button.set_widget_name("contact-find-key");
        group.set_header_suffix(Some(&button));
        button
    });
    let keys = Rc::new(ContactKeys {
        group: group.downgrade(),
        rows: RefCell::default(),
        card,
        addresses: addresses.to_vec(),
        find: glib::WeakRef::new(),
        looking: std::cell::Cell::new(false),
    });
    if let Some(find) = &find {
        keys.find.set(Some(find));
        let weak = Rc::downgrade(&keys);
        find.connect_clicked(move |_| {
            if let Some(keys) = weak.upgrade() {
                keys.find_keys();
            }
        });
    }
    keys.fill();
    // kept for as long as its group is
    let kept = RefCell::new(Some(keys));
    group.connect_destroy(move |_| drop(kept.take()));
    Some(group)
}

impl ContactKeys {
    /// The rows made again from what the core has now
    fn fill(self: &Rc<Self>) {
        let Some(group) = self.group.upgrade() else {
            return;
        };
        for row in self.rows.borrow_mut().drain(..) {
            group.remove(&row);
        }
        let core = &shell().core;
        let mut added: Vec<gtk::Widget> = Vec::new();
        let mut first_verify: Option<gtk::Button> = None;
        for (index, address) in self.addresses.iter().enumerate() {
            let peer = core.pgp_peer(address).unwrap_or_default();
            let Some(key) = peer.in_use.as_deref().and_then(|fp| core.pgp_key(fp).ok()) else {
                continue;
            };
            let row = adw::ActionRow::builder()
                .title(glib::markup_escape_text(&format!("{address} ({})", key.status)))
                .subtitle(glib::markup_escape_text(&key.grouped))
                .subtitle_selectable(true)
                .build();
            row.add_css_class("fingerprint");
            row.set_widget_name(&format!("contact-key-{index}"));
            let verify_button = gtk::Button::with_label(&plain(Text::UiKeysVerify));
            verify_button.set_valign(gtk::Align::Center);
            verify_button.set_widget_name(&format!("contact-key-verify-{index}"));
            row.add_suffix(&verify_button);
            first_verify.get_or_insert_with(|| verify_button.clone());
            let redo = self.refill();
            verify_button.connect_clicked(move |button| {
                let (button, key, redo) = (button.clone(), key.clone(), redo.clone());
                glib::spawn_future_local(async move {
                    if verify(&button, &key).await {
                        redo();
                    }
                });
            });
            added.push(row.clone().upcast());
            if let Some(text) = &peer.pending_text {
                added.push(pending_row(index, address, text, self.refill()).upcast());
            }
        }
        if added.is_empty() {
            let none = adw::ActionRow::builder().title(t!(UiContactKeyNone)).build();
            none.add_css_class("dim-label");
            none.set_widget_name("contact-key-none");
            added.push(none.upcast());
        }
        for row in &added {
            group.add(row);
        }
        *self.rows.borrow_mut() = added;
        if let Some(find) = self.find.upgrade() {
            // greyed with nothing to ask (the core's rule): the keyboard focus, when it was on it, goes to the key found
            // rather than to the top of the window
            let can_find = core.contact_can_find_keys(self.card);
            if !can_find
                && find.has_focus()
                && let Some(verify) = &first_verify
            {
                verify.grab_focus();
            }
            find.set_sensitive(can_find);
        }
    }

    /// Words under the section's title (what a lookup is doing or found); none for empty
    fn say(&self, text: &str) {
        if let Some(group) = self.group.upgrade() {
            group.set_description((!text.is_empty()).then(|| glib::markup_escape_text(text)).as_deref());
        }
    }

    /// The rows made again, as a closure for the buttons in them
    fn refill(self: &Rc<Self>) -> Rc<dyn Fn()> {
        let weak = Rc::downgrade(self);
        Rc::new(move || {
            let weak = weak.clone();
            // after the click's own handler is done with the row it is in
            glib::idle_add_local_once(move || {
                if let Some(keys) = weak.upgrade() {
                    keys.fill();
                }
            });
        })
    }

    /// Find Key: the keys of the card's addresses looked up, "Looking for a key..." under the title meanwhile, then
    /// what was found said there and the rows read again. The core learns the keys found whether the window is still
    /// open or not
    fn find_keys(self: &Rc<Self>) {
        if self.looking.get() {
            return;
        }
        let core = shell().core.clone();
        let request = match core.contact_find_keys(self.card) {
            Ok(Some(request)) => request,
            Ok(None) => return,
            Err(error) => {
                self.say(&error.to_string());
                return;
            }
        };
        // the button stays where the focus is while it looks; another click meanwhile asks nothing
        self.looking.set(true);
        self.say(&t!(PgpRecipientLooking));
        let (send, done) = async_channel::bounded::<bool>(2);
        shell().watch_request(request, send);
        let weak = Rc::downgrade(self);
        glib::spawn_future_local(async move {
            let _ = done.recv().await;
            let outcome = core.pgp_find_result(request);
            let Some(keys) = weak.upgrade() else { return };
            keys.looking.set(false);
            keys.say(&outcome.map(|o| o.text).unwrap_or_default());
            keys.fill();
        });
    }
}

/// A newer key waiting for `address`: what the core says of it, Use the New Key and Keep the Current One
fn pending_row(index: usize, address: &str, text: &str, redo: Rc<dyn Fn()>) -> adw::ActionRow {
    let row = adw::ActionRow::builder()
        .title(glib::markup_escape_text(text))
        .title_lines(0)
        .build();
    row.set_widget_name(&format!("contact-key-pending-{index}"));
    let icon = crate::icons::image("dialog-warning-symbolic");
    icon.add_css_class("warning");
    row.add_prefix(&icon);
    let buttons = gtk::Box::new(gtk::Orientation::Vertical, 6);
    buttons.set_valign(gtk::Align::Center);
    buttons.set_margin_top(6);
    buttons.set_margin_bottom(6);
    for (text, use_new, name) in [
        (Text::UiContactKeyUseNew, true, "use-new"),
        (Text::UiContactKeyKeep, false, "keep"),
    ] {
        let button = gtk::Button::with_label(&plain(text));
        button.set_widget_name(&format!("contact-key-{name}-{index}"));
        let (address, redo) = (address.to_string(), redo.clone());
        button.connect_clicked(move |_| {
            let _ = shell().core.pgp_decide(&address, use_new);
            redo();
        });
        buttons.append(&button);
    }
    row.add_suffix(&buttons);
    row
}
