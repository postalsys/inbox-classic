//! Sign-in apps: the Sign-in Apps window (File > Accounts) with the built-in Google and Microsoft clients and the
//! OAuth clients the user added, each turned on or off for new accounts, and the editor of an added one. What is
//! typed goes to the core as it is; the core checks the issuer (OpenID Connect discovery) and the rest before saving.

use std::cell::RefCell;
use std::rc::Rc;

use adw::prelude::*;
use gtk::{gdk, glib};
use pe_core::{SecretChange, SignInAppEntry, SignInAppForm, SignInWith};
use pe_store::{Security, SignInApp};

use crate::app::shell;
use crate::ui;

const SECURITY: [&str; 2] = ["SSL/TLS", "STARTTLS"];

fn security_of(index: u32) -> Security {
    if index == 1 { Security::StartTls } else { Security::Tls }
}

fn security_index(security: Security) -> u32 {
    if security == Security::StartTls { 1 } else { 0 }
}

fn net_security(security: pe_net::Security) -> Security {
    match security {
        pe_net::Security::StartTls => Security::StartTls,
        pe_net::Security::Plain => Security::Plain,
        pe_net::Security::Tls => Security::Tls,
    }
}

fn entry_row(title: &str, text: &str, name: &str) -> adw::EntryRow {
    let row = adw::EntryRow::builder().title(title).text(text).build();
    row.set_widget_name(name);
    row
}

/// A server of the editor: host, port and encryption
struct ServerRows {
    host: adw::EntryRow,
    port: adw::EntryRow,
    security: adw::ComboRow,
}

impl ServerRows {
    fn new(group: &adw::PreferencesGroup, kind: &str, host: &str, port: u16, security: Security) -> ServerRows {
        let lower = kind.to_lowercase();
        let host = entry_row(&t!(GtkAppServer, kind = kind), host, &format!("app-{lower}-host"));
        let port = entry_row(
            &t!(GtkAppPort, kind = kind),
            &if port != 0 { port.to_string() } else { String::new() },
            &format!("app-{lower}-port"),
        );
        port.set_input_purpose(gtk::InputPurpose::Digits);
        let security_row = adw::ComboRow::builder()
            .title(t!(GtkAppSecurity, kind = kind))
            .model(&gtk::StringList::new(&SECURITY))
            .build();
        security_row.set_selected(security_index(security));
        group.add(&host);
        group.add(&port);
        group.add(&security_row);
        ServerRows {
            host,
            port,
            security: security_row,
        }
    }

    fn port(&self) -> u16 {
        let text = self.port.text();
        if text.len() <= 5 { text.parse().unwrap_or(0) } else { 0 }
    }
}

struct Editor {
    name: adw::EntryRow,
    issuer: adw::EntryRow,
    client_id: adw::EntryRow,
    secret: adw::PasswordEntryRow,
    remove_secret: Option<adw::SwitchRow>,
    scopes: adw::EntryRow,
    imap: ServerRows,
    smtp: ServerRows,
    register: gtk::Label,
    redirect: adw::EntryRow,
}

impl Editor {
    /// The redirect URI and how to register a client, for the issuer typed
    fn show_registration(&self) {
        let issuer = self.issuer.text();
        let issuer = issuer.trim();
        self.redirect
            .set_text(&pe_oauth::ProviderKind::of_issuer(issuer).redirect_uri());
        self.register.set_text(&pe_core::register_hint(issuer));
    }

    /// A preset fills in everything but the client; the name only when there is none yet
    fn fill(&self, preset: &pe_oauth::Preset) {
        if self.name.text().is_empty() {
            self.name.set_text(&t!(UiPresetAppName, provider = preset.name));
        }
        self.issuer.set_text(preset.issuer);
        self.scopes.set_text(&preset.scopes.join(" "));
        self.imap.host.set_text(&preset.imap.host);
        self.imap.port.set_text(&preset.imap.port.to_string());
        self.imap
            .security
            .set_selected(security_index(net_security(preset.imap.security)));
        self.smtp.host.set_text(&preset.smtp.host);
        self.smtp.port.set_text(&preset.smtp.port.to_string());
        self.smtp
            .security
            .set_selected(security_index(net_security(preset.smtp.security)));
        self.show_registration();
        self.client_id.grab_focus();
    }

    fn form(&self) -> SignInAppForm {
        SignInAppForm {
            name: self.name.text().trim().to_string(),
            issuer: self.issuer.text().trim().to_string(),
            client_id: self.client_id.text().trim().to_string(),
            scopes: self.scopes.text().trim().to_string(),
            imap_host: self.imap.host.text().trim().to_string(),
            imap_port: self.imap.port(),
            imap_security: security_of(self.imap.security.selected()),
            smtp_host: self.smtp.host.text().trim().to_string(),
            smtp_port: self.smtp.port(),
            smtp_security: security_of(self.smtp.security.selected()),
        }
    }
}

/// Checks the issuer typed (its discovery document), waiting with a dialog that can cancel it: Ok with what was found,
/// Err with why not (empty when cancelled)
async fn check_issuer(parent: &impl IsA<gtk::Widget>, issuer: &str) -> Result<String, String> {
    let core = &shell().core;
    let request = core.sign_in_app_check(issuer).map_err(|reason| reason.to_string())?;
    let cancel = |request| core.sign_in_app_check_cancel(request);
    if !ui::wait_for_request(
        parent,
        request,
        cancel,
        &t!(UiCheckingIssuer, issuer = issuer),
        &t!(UiSignInApp),
    )
    .await
    {
        return Err(String::new());
    }
    match core.sign_in_app_check_result(request) {
        Some(Ok(found)) => Ok(t!(
            GtkIssuerFound,
            page = &found.authorize_url,
            endpoint = &found.token_url
        )),
        Some(Err(reason)) => Err(reason),
        None => Err(String::new()),
    }
}

/// The editor of a sign-in app: a new one when `app` is None; the id of the app saved, 0 when cancelled
pub async fn editor(parent: &impl IsA<gtk::Widget>, app: Option<(i64, SignInApp)>) -> i64 {
    let id = app.as_ref().map_or(0, |(id, _)| *id);
    let stored = app.map(|(_, app)| app);
    let had_secret = stored.as_ref().is_some_and(|a| a.has_secret);
    let text = |f: fn(&SignInApp) -> &str| stored.as_ref().map(|a| f(a).to_string()).unwrap_or_default();
    let presets = pe_oauth::Preset::all();
    let content = gtk::Box::new(gtk::Orientation::Vertical, 12);
    content.set_margin_start(18);
    content.set_margin_end(18);
    content.set_margin_bottom(18);
    content.append(&ui::wrapped_label(&t!(UiSignInAppIntro)));
    let fill_row = gtk::Box::new(gtk::Orientation::Horizontal, 6);
    fill_row.append(&gtk::Label::new(Some(&t!(UiFillInFor))));
    let group = adw::PreferencesGroup::new();
    let name = entry_row(&t!(UiColName), &text(|a| &a.name), "app-name");
    let issuer = entry_row(&t!(UiColIssuer), &text(|a| &a.issuer), "app-issuer");
    let check = gtk::Button::with_label(&crate::words::plain(crate::words::Text::UiCheck));
    check.set_valign(gtk::Align::Center);
    check.set_widget_name("app-check");
    issuer.add_suffix(&check);
    let client_id = entry_row(&t!(GtkClientId), &text(|a| &a.client_id), "app-client-id");
    // never shown again once saved: it is in the keyring
    let secret = adw::PasswordEntryRow::builder().title(t!(GtkClientSecret)).build();
    secret.set_widget_name("app-secret");
    for row in [&name, &issuer, &client_id] {
        group.add(row);
    }
    group.add(&secret);
    let remove_secret = had_secret.then(|| {
        let row = adw::SwitchRow::builder().title(t!(UiRemoveSecret)).build();
        group.add(&row);
        row
    });
    let scopes = entry_row(&t!(GtkScopes), &text(|a| &a.scopes), "app-scopes");
    group.add(&scopes);
    let servers = adw::PreferencesGroup::new();
    let imap = ServerRows::new(
        &servers,
        "IMAP",
        &text(|a| &a.imap_host),
        stored.as_ref().map_or(993, |a| a.imap_port),
        stored.as_ref().map_or(Security::Tls, |a| a.imap_security),
    );
    let smtp = ServerRows::new(
        &servers,
        "SMTP",
        &text(|a| &a.smtp_host),
        stored.as_ref().map_or(465, |a| a.smtp_port),
        stored.as_ref().map_or(Security::Tls, |a| a.smtp_security),
    );
    let register = ui::wrapped_label("");
    register.set_widget_name("app-register");
    let registration = adw::PreferencesGroup::builder().title(t!(UiRegisterIt)).build();
    let redirect = entry_row(&t!(GtkRedirectUri), "", "app-redirect");
    redirect.set_editable(false);
    let copy = gtk::Button::with_label(&crate::words::plain(crate::words::Text::UiButtonCopy));
    copy.set_valign(gtk::Align::Center);
    redirect.add_suffix(&copy);
    registration.add(&register);
    registration.add(&redirect);
    let editor = Rc::new(Editor {
        name,
        issuer,
        client_id,
        secret,
        remove_secret,
        scopes,
        imap,
        smtp,
        register,
        redirect,
    });
    for (index, preset) in presets.iter().enumerate() {
        let button = gtk::Button::with_label(preset.name);
        button.set_widget_name(&format!("app-preset-{index}"));
        let editor = Rc::downgrade(&editor);
        let preset = preset.clone();
        button.connect_clicked(move |_| {
            if let Some(editor) = editor.upgrade() {
                editor.fill(&preset);
            }
        });
        fill_row.append(&button);
    }
    content.append(&fill_row);
    content.append(&group);
    content.append(&servers);
    content.append(&registration);
    editor.show_registration();
    let following = Rc::downgrade(&editor);
    editor.issuer.connect_changed(move |_| {
        if let Some(editor) = following.upgrade() {
            editor.show_registration();
        }
    });
    let copied = editor.redirect.clone();
    copy.connect_clicked(move |button| button.clipboard().set_text(&copied.text()));
    let scrolled = gtk::ScrolledWindow::builder()
        .child(&content)
        .hscrollbar_policy(gtk::PolicyType::Never)
        .propagate_natural_height(true)
        .max_content_height(640)
        .build();
    let (dialog, ok) = ui::dialog_with_buttons(
        &if id != 0 {
            t!(UiSignInApp)
        } else {
            t!(UiAddSignInAppTitle)
        },
        &scrolled,
        &t!(UiOk),
        560,
    );
    dialog.set_widget_name("sign-in-app-editor");
    let (send, clicks) = async_channel::unbounded::<&'static str>();
    let closed = send.clone();
    dialog.connect_closed(move |_| {
        let _ = closed.try_send("cancel");
    });
    let checked = send.clone();
    check.connect_clicked(move |_| {
        let _ = checked.try_send("check");
    });
    ok.connect_clicked(move |_| {
        let _ = send.try_send("ok");
    });
    dialog.present(Some(parent.as_ref()));
    if id != 0 {
        editor.name.grab_focus();
    }
    let mut saved = 0;
    while let Ok(click) = clicks.recv().await {
        match click {
            "check" => {
                let issuer = editor.issuer.text().trim().to_string();
                match check_issuer(&dialog, &issuer).await {
                    Ok(found) => {
                        ui::alert(
                            &dialog,
                            &crate::words::plain(crate::words::Text::UiCheck),
                            &t!(GtkIssuerUsable, found = &found),
                        )
                        .await;
                    }
                    Err(reason) if !reason.is_empty() => {
                        ui::alert(
                            &dialog,
                            &crate::words::plain(crate::words::Text::UiCheck),
                            &t!(UiIssuerUnusable, reason = &reason),
                        )
                        .await;
                    }
                    Err(_) => {}
                }
            }
            "ok" => {
                if let Some(app) = save(&dialog, &editor, id, had_secret).await {
                    saved = app;
                    break;
                }
            }
            _ => break,
        }
    }
    dialog.close();
    saved
}

/// OK: the issuer checked, then the app saved; None when the editor stays open (with the reason shown)
async fn save(dialog: &adw::Dialog, editor: &Editor, id: i64, had_secret: bool) -> Option<i64> {
    let form = editor.form();
    if form.imap_port == 0 || form.smtp_port == 0 {
        ui::alert(dialog, &t!(UiSignInApp), &t!(UiPortsInvalid)).await;
        return None;
    }
    if let Err(reason) = check_issuer(dialog, &form.issuer).await {
        if !reason.is_empty() {
            ui::alert(dialog, &t!(UiSignInApp), &t!(UiIssuerUnusable, reason = &reason)).await;
            editor.issuer.grab_focus();
        }
        return None;
    }
    let secret = editor.secret.text().to_string();
    let remove = had_secret && editor.remove_secret.as_ref().is_some_and(|row| row.is_active());
    let change = if !secret.is_empty() {
        SecretChange::Set(&secret)
    } else if remove {
        SecretChange::Remove
    } else {
        SecretChange::Keep
    };
    let saved = shell().core.save_sign_in_app((id != 0).then_some(id), &form, change);
    editor.secret.set_text("");
    match saved {
        Ok(app) => Some(app),
        Err(reason) => {
            ui::alert(
                dialog,
                &t!(UiSignInApp),
                &t!(UiSignInAppNotSaved, reason = &reason.to_string()),
            )
            .await;
            None
        }
    }
}

// ---- the Sign-in Apps window ----

struct AppsWindow {
    list: gtk::ListBox,
    apps: RefCell<Vec<SignInAppEntry>>,
    note: gtk::Label,
    edit: gtk::Button,
    remove: gtk::Button,
    /// While the rows are filled, their switches changing is not the user turning an app on or off
    filling: std::cell::Cell<bool>,
}

impl AppsWindow {
    fn selected(&self) -> Option<SignInAppEntry> {
        let index = self.list.selected_row()?.index();
        self.apps.borrow().get(usize::try_from(index).ok()?).cloned()
    }

    /// What the selected app is: why a built-in one may be off, an added one's client; Edit and Remove for added ones
    fn show_selected(&self) {
        let app = self.selected();
        let added = app.as_ref().and_then(|a| a.app.as_ref());
        self.edit.set_sensitive(added.is_some());
        self.remove.set_sensitive(added.is_some());
        let note = match (&app, added) {
            (Some(app), None) => {
                let reason = match app.with {
                    SignInWith::Builtin(kind) if !app.enabled => pe_core::builtin_off_text(kind),
                    _ => String::new(),
                };
                t!(GtkAppBuiltIn, app = &app.name, reason = &reason)
            }
            (Some(_), Some(added)) if added.has_secret => t!(UiClientWithSecret, client = &added.client_id),
            (Some(_), Some(added)) => t!(UiClientPublic, client = &added.client_id),
            _ => String::new(),
        };
        self.note.set_text(&note);
    }

    /// A row per app, the built-in ones first, its switch on when it is on; `select` stays selected
    fn fill(self: &Rc<Self>, select: usize) {
        self.filling.set(true);
        while let Some(child) = self.list.first_child() {
            self.list.remove(&child);
        }
        let apps = shell().core.sign_in_apps().unwrap_or_default();
        for (index, app) in apps.iter().enumerate() {
            let builtin = app.app.is_none();
            let used_by = if app.used_by.is_empty() {
                t!(UiNoAccounts)
            } else {
                app.used_by.join(", ")
            };
            let row = adw::ActionRow::builder()
                .title(glib::markup_escape_text(&if builtin {
                    t!(GtkBuiltIn, app = &app.name)
                } else {
                    app.name.clone()
                }))
                .subtitle(glib::markup_escape_text(&format!(
                    "{}  \u{00B7}  {used_by}",
                    app.issuer
                )))
                .build();
            let switch = gtk::Switch::builder()
                .active(app.enabled)
                .valign(gtk::Align::Center)
                .build();
            switch.set_widget_name(&format!("app-on-{index}"));
            switch.update_property(&[gtk::accessible::Property::Label(&t!(GtkOfferedForNew))]);
            let this = Rc::downgrade(self);
            let with = app.with;
            switch.connect_active_notify(move |switch| {
                let Some(this) = this.upgrade() else { return };
                if this.filling.get() {
                    return;
                }
                let _ = shell().core.set_sign_in_enabled(with, switch.is_active());
                let refill = this.clone();
                glib::idle_add_local_once(move || {
                    refill.fill(index);
                    // the list was made again under the switch: the focus to its app's row
                    if let Some(row) = refill.list.row_at_index(index as i32) {
                        row.grab_focus();
                    }
                });
            });
            row.add_suffix(&switch);
            self.list.append(&row);
        }
        let last = apps.len().saturating_sub(1);
        *self.apps.borrow_mut() = apps;
        self.list
            .select_row(self.list.row_at_index(select.min(last) as i32).as_ref());
        self.filling.set(false);
        self.show_selected();
    }
}

/// File > Accounts > Sign-in Apps: the built-in clients and the added sign-in apps, to turn on and off, add, change
/// or remove
pub async fn sign_in_apps_dialog(parent: &impl IsA<gtk::Widget>) {
    let list = gtk::ListBox::new();
    list.add_css_class("boxed-list");
    list.set_widget_name("sign-in-apps-list");
    let note = ui::wrapped_label("");
    note.set_widget_name("sign-in-apps-note");
    let (send, clicks) = async_channel::unbounded::<&'static str>();
    let button = |label: &str, id: &'static str| {
        let button = gtk::Button::with_label(label);
        button.set_widget_name(&format!("apps-{id}"));
        let send = send.clone();
        button.connect_clicked(move |_| {
            let _ = send.try_send(id);
        });
        button
    };
    let add = button(&t!(GtkAccountsAdd), "add");
    let edit = button(&t!(GtkEditButton), "edit");
    let remove = button(&crate::words::plain(crate::words::Text::UiRemove), "remove");
    let buttons = gtk::Box::new(gtk::Orientation::Vertical, 6);
    buttons.append(&add);
    buttons.append(&edit);
    buttons.append(&remove);
    let window = Rc::new(AppsWindow {
        list: list.clone(),
        apps: RefCell::default(),
        note: note.clone(),
        edit,
        remove,
        filling: std::cell::Cell::new(false),
    });
    window.fill(0);
    let selected = Rc::downgrade(&window);
    list.connect_row_selected(move |_, _| {
        if let Some(window) = selected.upgrade() {
            window.show_selected();
        }
    });
    let activated = send.clone();
    list.connect_row_activated(move |_, _| {
        let _ = activated.try_send("edit");
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
        .min_content_height(200)
        .hexpand(true)
        .hscrollbar_policy(gtk::PolicyType::Never)
        .build();
    row.append(&scrolled);
    row.append(&buttons);
    let content = gtk::Box::new(gtk::Orientation::Vertical, 12);
    content.set_margin_start(18);
    content.set_margin_end(18);
    content.set_margin_bottom(18);
    content.append(&ui::wrapped_label(&t!(GtkSignInAppsIntro)));
    content.append(&row);
    content.append(&note);
    let view = adw::ToolbarView::new();
    view.add_top_bar(&adw::HeaderBar::new());
    view.set_content(Some(&content));
    let dialog = adw::Dialog::builder()
        .title(t!(UiSignInApps))
        .content_width(680)
        .child(&view)
        .build();
    dialog.set_widget_name("sign-in-apps-dialog");
    dialog.connect_closed(move |_| {
        let _ = send.try_send("close");
    });
    dialog.present(Some(parent.as_ref()));
    let host = dialog.clone().upcast::<gtk::Widget>();
    while let Ok(click) = clicks.recv().await {
        let index = list.selected_row().map_or(0, |row| row.index().max(0) as usize);
        let app = window.selected();
        let added = app.as_ref().and_then(|a| match (a.with, &a.app) {
            (SignInWith::App(id), Some(stored)) => Some((id, stored.clone(), a.name.clone())),
            _ => None,
        });
        match click {
            "close" => break,
            "add" => {
                if editor(&host, None).await != 0 {
                    window.fill(usize::MAX);
                }
            }
            "edit" => {
                if let Some((id, stored, _)) = added
                    && editor(&host, Some((id, stored))).await != 0
                {
                    window.fill(index);
                }
            }
            "remove" => {
                let Some((id, _, name)) = added else { continue };
                let question = t!(GtkRemoveAppAsk, app = &*name);
                if !ui::confirm(&host, &t!(UiRemoveSignInApp), &question, true).await {
                    continue;
                }
                if let Err(reason) = shell().core.remove_sign_in_app(id) {
                    let text = t!(UiSignInAppNotRemoved, reason = &pe_core::sentence(&reason.to_string()));
                    ui::alert(&host, &t!(UiRemoveSignInApp), &text).await;
                    continue;
                }
                window.fill(index);
            }
            _ => {}
        }
    }
    dialog.close();
}
