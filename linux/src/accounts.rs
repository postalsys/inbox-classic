//! Adding an account (the providers' sign-in buttons or a name and an address, the servers looked up, then the
//! server form with the password), the password prompt, signing in through the browser, and File > Accounts with
//! each account's Properties and Signature. The values go to the core as typed; the core checks them when it
//! connects.

use std::cell::RefCell;
use std::rc::Rc;

use adw::prelude::*;
use gtk::{gio, glib};
use pe_autoconfig::{ServerSecurity, Source};
use pe_core::SignInWith;
use pe_oauth::ProviderKind;
use pe_store::{AccountSettings, Auth, Security};

use crate::app::{shell, spawn};
use crate::ui::{self, Field, Form, TITLE};

/// The fields of the server form, in order
const ACCOUNT_NAME: usize = 0;
const NAME: usize = 1;
const EMAIL: usize = 2;
const USERNAME: usize = 3;
const PASSWORD: usize = 4;
const IMAP_HOST: usize = 5;
const IMAP_PORT: usize = 6;
const IMAP_SECURITY: usize = 7;
const SMTP_HOST: usize = 8;
const SMTP_PORT: usize = 9;
const SMTP_SECURITY: usize = 10;

fn security_of(index: Option<usize>) -> Security {
    match index {
        Some(1) => Security::StartTls,
        Some(2) => Security::Plain,
        _ => Security::Tls,
    }
}

fn security_index(security: Security) -> usize {
    match security {
        Security::Tls => 0,
        Security::StartTls => 1,
        Security::Plain => 2,
    }
}

fn valid_port(text: &str) -> bool {
    text.len() <= 5 && text.parse::<u32>().is_ok_and(|port| (1..=65535).contains(&port))
}

fn validate(fields: &[Field]) -> Result<(), String> {
    for required in [EMAIL, IMAP_HOST, SMTP_HOST] {
        if fields[required].value.is_empty() {
            let field = fields[required].label.trim_end_matches([':', ' ', '\u{a0}']);
            return Err(t!(UiFieldRequired, field = field));
        }
    }
    if !fields[EMAIL].value.contains('@') {
        return Err(t!(UiEmailInvalid));
    }
    if !valid_port(&fields[IMAP_PORT].value) || !valid_port(&fields[SMTP_PORT].value) {
        return Err(t!(UiPortsInvalid));
    }
    Ok(())
}

/// The fields of the server form, filled with `settings` and the account's own name for the folder list
fn server_fields(settings: &AccountSettings, account_name: &str) -> Vec<Field> {
    let security = || vec!["SSL/TLS".to_string(), "STARTTLS".into(), t!(UiSecurityNone)];
    vec![
        Field::text(&t!(UiFieldAccountName), account_name),
        Field::text(&t!(UiFieldName), &settings.name),
        Field::text(&t!(UiFieldEmail), &settings.email),
        Field::text(&t!(UiFieldUser), &settings.username),
        Field::password(&t!(UiFieldPassword)),
        Field::text(&t!(UiFieldImapHost), &settings.imap_host),
        Field::number(&t!(UiFieldImapPort), settings.imap_port.to_string()),
        Field::choice(
            &t!(UiFieldImapSecurity),
            security(),
            security_index(settings.imap_security),
        ),
        Field::text(&t!(UiFieldSmtpHost), &settings.smtp_host),
        Field::number(&t!(UiFieldSmtpPort), settings.smtp_port.to_string()),
        Field::choice(
            &t!(UiFieldSmtpSecurity),
            security(),
            security_index(settings.smtp_security),
        ),
    ]
}

/// The settings of the server form; the user name and the name are the address when left empty
fn settings_of(form: &Form, auth: Auth) -> AccountSettings {
    let email = form.value(EMAIL);
    let or_email = |value: String| if value.is_empty() { email.clone() } else { value };
    AccountSettings {
        name: or_email(form.value(NAME)),
        email: email.clone(),
        username: or_email(form.value(USERNAME)),
        imap_host: form.value(IMAP_HOST),
        imap_port: form.value(IMAP_PORT).parse().unwrap_or(993),
        imap_security: security_of(form.chosen(IMAP_SECURITY)),
        smtp_host: form.value(SMTP_HOST),
        smtp_port: form.value(SMTP_PORT).parse().unwrap_or(465),
        smtp_security: security_of(form.chosen(SMTP_SECURITY)),
        auth,
    }
}

/// The warning before a connection without encryption: true to go on
async fn accept_plain(parent: &impl IsA<gtk::Widget>, settings: &AccountSettings, title: &str) -> bool {
    let plain = settings.imap_security == Security::Plain || settings.smtp_security == Security::Plain;
    !plain || ui::confirm(parent, title, &t!(GtkPlainWarning), true).await
}

// ---- the first page: the providers' sign-in buttons, or the name and address of any other account ----

enum Start {
    Cancel,
    Next,
    SignIn(SignInWith),
}

/// What a page of Add Mail Account offers: the intro, a sign-in button for each of `providers` (faded and turned off
/// when its client is off; left out when all are off), More sign-in options when `more`, then when `fields` the name
/// and address of any other account, and `next` to go on with that
struct Offer {
    intro: String,
    providers: Vec<ProviderKind>,
    more: bool,
    fields: bool,
    next: String,
}

/// The sign-in apps as the core has them now
struct Apps(Vec<pe_core::SignInAppEntry>);

impl Apps {
    fn load() -> Apps {
        Apps(shell().core.sign_in_apps().unwrap_or_default())
    }

    fn on(&self, kind: ProviderKind) -> bool {
        self.0
            .iter()
            .any(|app| app.with == SignInWith::Builtin(kind) && app.enabled)
    }

    /// The added apps that are on, for new accounts
    fn added_on(&self) -> Vec<(i64, String)> {
        self.0
            .iter()
            .filter_map(|app| match app.with {
                SignInWith::App(id) if app.enabled => Some((id, app.name.clone())),
                _ => None,
            })
            .collect()
    }
}

fn provider_button(kind: ProviderKind) -> (&'static str, String, &'static str) {
    match kind {
        ProviderKind::Microsoft => (
            "sign-in-microsoft",
            t!(UiSignInWith, provider = "Microsoft"),
            "microsoft-sign-in.png",
        ),
        _ => (
            "sign-in-google",
            t!(UiSignInWith, provider = "Google"),
            "google-sign-in.png",
        ),
    }
}

fn company(kind: ProviderKind) -> String {
    match kind {
        ProviderKind::Microsoft => "Microsoft".into(),
        ProviderKind::Google => "Google".into(),
        ProviderKind::Oidc => t!(UiTheProvider),
    }
}

/// A page of Add Mail Account; the name and address typed come back in `name` and `email`
async fn start_page(parent: &gtk::Widget, apps: &Apps, offer: Offer, name: &mut String, email: &mut String) -> Start {
    let (send, choice) = async_channel::unbounded::<Start>();
    let content = gtk::Box::new(gtk::Orientation::Vertical, 12);
    content.set_margin_start(18);
    content.set_margin_end(18);
    content.set_margin_bottom(18);
    let intro = ui::wrapped_label(&offer.intro);
    intro.set_widget_name("start-intro");
    content.append(&intro);
    // the buttons side by side; none when every one of them is off
    let shown: Vec<ProviderKind> = if offer.providers.iter().any(|kind| apps.on(*kind)) {
        offer.providers.clone()
    } else {
        Vec::new()
    };
    let buttons = gtk::Box::new(gtk::Orientation::Horizontal, 12);
    buttons.set_halign(gtk::Align::Center);
    for kind in &shown {
        let button = sign_in_button(*kind, apps.on(*kind), &send);
        // their tops in line, a turned-off one's note under it
        button.set_valign(gtk::Align::Start);
        buttons.append(&button);
    }
    if !shown.is_empty() {
        content.append(&buttons);
    }
    if offer.more {
        let more = gtk::Button::with_label(&t!(UiMoreSignIn));
        more.add_css_class("flat");
        more.set_halign(gtk::Align::Start);
        more.set_widget_name("sign-in-more");
        let chosen = send.clone();
        more.connect_clicked(move |button| more_menu(button, chosen.clone()));
        content.append(&more);
    }
    let group = adw::PreferencesGroup::new();
    let name_row = adw::EntryRow::builder()
        .title(t!(GtkDisplayNameTitle))
        .text(name.as_str())
        .build();
    name_row.set_widget_name("start-name");
    let email_row = adw::EntryRow::builder()
        .title(t!(UiColEmail))
        .text(email.as_str())
        .build();
    email_row.set_widget_name("start-email");
    email_row.set_input_purpose(gtk::InputPurpose::Email);
    if offer.fields {
        content.append(&gtk::Separator::new(gtk::Orientation::Horizontal));
        content.append(&ui::wrapped_label(&t!(UiOtherAccount)));
        group.add(&name_row);
        group.add(&email_row);
        name_row.set_activates_default(true);
        email_row.set_activates_default(true);
        content.append(&group);
    }
    let (dialog, next) = ui::dialog_with_buttons(&t!(UiAddAccountTitle), &content, &offer.next, 500);
    dialog.set_widget_name("account-start");
    if !offer.fields {
        next.remove_css_class("suggested-action");
    }
    let on_close = send.clone();
    dialog.connect_closed(move |_| {
        let _ = on_close.try_send(Start::Cancel);
    });
    next.connect_clicked(move |_| {
        let _ = send.try_send(Start::Next);
    });
    dialog.present(Some(parent));
    if offer.fields {
        name_row.grab_focus();
    }
    let result = loop {
        match choice.recv().await.unwrap_or(Start::Cancel) {
            // the page of another account wants an address to look up
            Start::Next if offer.fields && !email_row.text().contains('@') => {
                ui::alert(&dialog, TITLE, &t!(UiTypeEmail)).await;
                email_row.grab_focus();
            }
            other => break other,
        }
    };
    if offer.fields {
        *name = name_row.text().trim().to_string();
        *email = email_row.text().trim().to_string();
    }
    dialog.close();
    result
}

/// A provider's sign-in button: its own picture, unchanged; when its client is turned off, faded and turned off, with
/// a line under it that says so and Why?
fn sign_in_button(kind: ProviderKind, on: bool, chosen: &async_channel::Sender<Start>) -> gtk::Widget {
    let (id, label, picture) = provider_button(kind);
    let image = gtk::Picture::for_resource(&format!("/com/inboxclassic/InboxClassic/brands/{picture}"));
    image.set_can_shrink(true);
    image.set_content_fit(gtk::ContentFit::Contain);
    // 40 pixels high, both: as wide as each picture is at that height (they are 374 x 86 and 645 x 123), at most, the
    // height following from the width; a picture's own size would make each as large as its pixels
    let width = if kind == ProviderKind::Microsoft { 210 } else { 174 };
    image.set_size_request(width, 40);
    let clamp = adw::Clamp::builder()
        .child(&image)
        .maximum_size(width)
        .tightening_threshold(width)
        .build();
    let button = gtk::Button::builder()
        .child(&clamp)
        .tooltip_text(label.as_str())
        .sensitive(on)
        .build();
    button.add_css_class("flat");
    button.set_widget_name(id);
    button.update_property(&[gtk::accessible::Property::Label(&label)]);
    let send = chosen.clone();
    button.connect_clicked(move |_| {
        let _ = send.try_send(Start::SignIn(SignInWith::Builtin(kind)));
    });
    if on {
        return button.upcast();
    }
    let reason = t!(
        GtkTurnedOffWhy,
        button = &label,
        reason = &pe_core::builtin_off_text(kind)
    );
    button.set_tooltip_text(Some(&reason));
    let off = gtk::Label::new(Some(&t!(UiOffHere)));
    off.add_css_class("dim-label");
    let why = gtk::LinkButton::with_label("about:blank", &t!(UiWhy));
    why.set_widget_name(&format!("{id}-why"));
    let text = t!(
        GtkTurnedOffWhyLong,
        button = &label,
        reason = &pe_core::builtin_off_text(kind)
    );
    why.connect_activate_link(move |link| {
        let link = link.clone().upcast::<gtk::Widget>();
        let text = text.clone();
        spawn(async move { ui::alert(&link, &t!(UiAddAccountTitle), &text).await });
        glib::Propagation::Stop
    });
    let line = gtk::Box::new(gtk::Orientation::Horizontal, 4);
    line.append(&off);
    line.append(&why);
    let column = gtk::Box::new(gtk::Orientation::Vertical, 2);
    column.append(&button);
    column.append(&line);
    column.upcast()
}

/// More sign-in options: a menu of the added sign-in apps that are on, and Add a sign-in app
fn more_menu(button: &gtk::Button, chosen: async_channel::Sender<Start>) {
    let apps = Apps::load().added_on();
    let menu = gio::Menu::new();
    let group = gio::SimpleActionGroup::new();
    let added = gio::Menu::new();
    for (id, name) in &apps {
        let item = gio::MenuItem::new(Some(name), None);
        item.set_action_and_target_value(Some("more.app"), Some(&id.to_variant()));
        added.append_item(&item);
    }
    if !apps.is_empty() {
        menu.append_section(None, &added);
    }
    let add = gio::Menu::new();
    add.append(Some(&t!(UiAddSignInApp)), Some("more.add"));
    menu.append_section(None, &add);
    let app = gio::SimpleAction::new("app", Some(glib::VariantTy::INT64));
    let send = chosen.clone();
    app.connect_activate(move |_, id| {
        if let Some(id) = id.and_then(|id| id.get::<i64>()) {
            let _ = send.try_send(Start::SignIn(SignInWith::App(id)));
        }
    });
    let new = gio::SimpleAction::new("add", None);
    let parent = button.clone();
    new.connect_activate(move |_, _| {
        let parent = parent.clone().upcast::<gtk::Widget>();
        let send = chosen.clone();
        spawn(async move {
            let id = crate::sign_in_apps::editor(&parent, None).await;
            if id != 0 {
                let _ = send.try_send(Start::SignIn(SignInWith::App(id)));
            }
        });
    });
    group.add_action(&app);
    group.add_action(&new);
    button.insert_action_group("more", Some(&group));
    let popover = gtk::PopoverMenu::from_model(Some(&menu));
    popover.set_parent(button);
    popover.set_widget_name("sign-in-more-menu");
    popover.connect_closed(|popover| {
        let popover = popover.clone();
        glib::idle_add_local_once(move || popover.unparent());
    });
    popover.popup();
}

// ---- signing in through the browser ----

/// Signs in with `with` for `email` in the browser; the finished sign-in request, None when it did not work
pub async fn sign_in_with_browser(parent: &impl IsA<gtk::Widget>, with: SignInWith, email: &str) -> Option<u64> {
    let shell = shell();
    let Ok((request, page)) = shell.core.sign_in_begin(with, email) else {
        ui::alert(parent, TITLE, &t!(UiSignInNotStarted)).await;
        return None;
    };
    // the core makes the page, and gives only an https page or one of a provider on this computer (a test server)
    match &shell.sign_in_page_file {
        Some(file) => {
            let _ = std::fs::write(file, &page);
        }
        None => gtk::UriLauncher::new(&page).launch(ui::window_of(parent).as_ref(), gio::Cancellable::NONE, |_| {}),
    }
    let text = if email.is_empty() {
        t!(UiSignInInBrowserYours)
    } else {
        t!(UiSignInInBrowser, account = email)
    };
    let cancel = |request| shell.core.sign_in_cancel(request);
    if !ui::wait_for_request(parent, request, cancel, &text, &t!(UiAddAccountTitle)).await {
        return None;
    }
    if let Err(reason) = shell.core.sign_in_result(request) {
        ui::alert(parent, TITLE, &t!(UiSignInFailed, reason = &reason.to_string())).await;
        return None;
    }
    Some(request)
}

/// Signs in with `with` and adds the account signed in to, named `name` or, without one, as at the provider
async fn add_signed_in(parent: &gtk::Widget, with: SignInWith, name: &str, email: &str) -> i64 {
    let Some(request) = sign_in_with_browser(parent, with, email).await else {
        return 0;
    };
    match shell().core.add_signed_in_account(request, name) {
        Ok(account) => account,
        Err(_) => {
            ui::alert(parent, &t!(UiAddAccountTitle), &t!(UiAccountNotSaved)).await;
            0
        }
    }
}

// ---- adding an account ----

/// Looks the servers of `email` up, waiting with a dialog that can cancel it; what was found, None for nothing or
/// a cancel
async fn look_up(parent: &gtk::Widget, email: &str) -> Option<pe_autoconfig::Settings> {
    let shell = shell();
    let request = shell.core.autoconfig(email, None).ok()?;
    let domain = email.rsplit_once('@').map_or(email, |(_, domain)| domain);
    let text = t!(UiLookingUp, domain = domain);
    let cancel = |request| shell.core.autoconfig_cancel(request);
    if !ui::wait_for_request(parent, request, cancel, &text, &t!(UiAddAccountTitle)).await {
        return None;
    }
    shell.core.autoconfig_result(request)
}

/// The first line of the server form: where the settings came from
fn found_intro(found: Option<&pe_autoconfig::Settings>) -> String {
    let found = match found.map(|f| f.source) {
        None => return t!(UiFoundNone),
        Some(Source::Guess) => return t!(UiFoundGuess),
        Some(Source::Mx) => t!(UiFoundMx),
        Some(Source::Srv) => t!(UiFoundSrv),
        Some(Source::Autodiscover) => t!(UiFoundAutodiscover),
        Some(_) => t!(UiFoundOther),
    };
    format!("{found} {}", t!(UiFoundChange))
}

/// A provider that does not take the account's password from mail programs: says so, and opens the page that tells
/// how to make an app password when the user wants it
async fn explain_app_password(parent: &gtk::Widget, found: Option<&pe_autoconfig::Settings>) {
    let Some(hint) = found.and_then(|f| f.app_password.as_ref()) else {
        return;
    };
    let provider = hint.provider;
    let mut text = match hint.warning {
        Some(warning) => warning.to_string(),
        None => t!(UiAppPasswordNeeded, provider = provider),
    };
    let page = hint.instructions;
    if page.starts_with("https://") {
        text.push_str(&format!("\n\n{}", t!(UiAppPasswordOpen, provider = provider)));
        if ui::confirm(parent, &t!(UiAddAccountTitle), &text, false).await {
            ui::open_externally(page, ui::window_of(parent).as_ref());
        }
    } else {
        ui::alert(parent, &t!(UiAddAccountTitle), &text).await;
    }
}

fn server_security(security: ServerSecurity) -> Security {
    match security {
        ServerSecurity::Tls => Security::Tls,
        ServerSecurity::StartTls => Security::StartTls,
    }
}

/// Asks for a new account and adds it to the core; its id, or 0 when cancelled
pub async fn new_account(parent: &impl IsA<gtk::Widget>) -> i64 {
    let parent = parent.as_ref().clone();
    let (mut name, mut email) = (String::new(), String::new());
    let apps = Apps::load();
    let any = apps.on(ProviderKind::Google) || apps.on(ProviderKind::Microsoft);
    let first = Offer {
        intro: if any { t!(UiStartIntro) } else { t!(UiStartIntroApps) },
        providers: vec![ProviderKind::Google, ProviderKind::Microsoft],
        more: true,
        fields: true,
        next: t!(GtkNext),
    };
    match start_page(&parent, &apps, first, &mut name, &mut email).await {
        Start::Cancel => return 0,
        Start::SignIn(with) => return add_signed_in(&parent, with, &name, &email).await,
        Start::Next => {}
    }
    let found = look_up(&parent, &email).await;
    // an address at Google or Microsoft: a browser sign-in first (the built-in client when it is on, the added
    // sign-in apps that are), an app password the other way
    let provider = found
        .as_ref()
        .and_then(|f| shell().core.oauth_provider_for(&f.imap.host));
    let more = !apps.added_on().is_empty();
    if let Some(kind) = provider.filter(|kind| apps.on(*kind) || more) {
        let intro = if apps.on(kind) {
            t!(GtkProviderSignIn, address = &email, provider = &company(kind))
        } else {
            t!(GtkProviderSignInApps, address = &email, provider = &company(kind))
        };
        let offer = Offer {
            intro,
            providers: if apps.on(kind) { vec![kind] } else { Vec::new() },
            more,
            fields: false,
            next: t!(UiUseAppPassword),
        };
        match start_page(&parent, &apps, offer, &mut name, &mut email).await {
            Start::Cancel => return 0,
            Start::SignIn(with) => return add_signed_in(&parent, with, &name, &email).await,
            Start::Next => {}
        }
    }
    explain_app_password(&parent, found.as_ref()).await;
    let start = AccountSettings {
        name,
        email,
        username: found.as_ref().map(|f| f.username.clone()).unwrap_or_default(),
        imap_host: found.as_ref().map(|f| f.imap.host.clone()).unwrap_or_default(),
        imap_port: found.as_ref().map_or(993, |f| f.imap.port),
        imap_security: found
            .as_ref()
            .map_or(Security::Tls, |f| server_security(f.imap.security)),
        smtp_host: found.as_ref().map(|f| f.smtp.host.clone()).unwrap_or_default(),
        smtp_port: found.as_ref().map_or(465, |f| f.smtp.port),
        smtp_security: found
            .as_ref()
            .map_or(Security::Tls, |f| server_security(f.smtp.security)),
        auth: Auth::Password,
    };
    // the name and address were typed already: the password is next; the account named by its provider or domain to
    // begin with
    let account_name = pe_core::default_account_name(&start.email);
    let form = Form::new(
        &parent,
        &t!(UiAddAccountTitle),
        &found_intro(found.as_ref()),
        server_fields(&start, &account_name),
        &t!(UiFinish),
        PASSWORD,
    );
    form.widget().set_widget_name("account-servers");
    form.validate_with(validate);
    while form.run().await {
        let settings = settings_of(&form, Auth::Password);
        if !accept_plain(form.widget(), &settings, &t!(UiAddAccountTitle)).await {
            continue;
        }
        match shell().core.add_account(&settings, &form.value(PASSWORD)) {
            Ok(account) => {
                let _ = shell().core.set_account_name(account, &form.value(ACCOUNT_NAME));
                form.close();
                return account;
            }
            Err(_) => ui::alert(form.widget(), &t!(UiAddAccountTitle), &t!(UiAccountNotSaved)).await,
        }
    }
    form.close();
    0
}

/// Asks for the password of an account; None when cancelled
pub async fn password_dialog(parent: &impl IsA<gtk::Widget>, account: &str) -> Option<String> {
    let intro = t!(UiEnterPassword, account = account);
    let form = Form::new(
        parent,
        &t!(UiLogon),
        &intro,
        vec![Field::password(&t!(UiFieldPassword))],
        &t!(UiOk),
        0,
    );
    form.widget().set_widget_name("logon");
    let ok = form.run().await;
    let password = form.value(0);
    form.close();
    ok.then_some(password)
}

// ---- the accounts window ----

/// The settings of an account, changed: the server form for a password account, the name for one that signs in
/// through the browser with `signs_in_with` (its servers are the sign-in's); a password typed in replaces the kept
/// one
async fn properties(parent: &gtk::Widget, account: i64, signs_in_with: Option<String>) -> bool {
    let core = &shell().core;
    let Ok(stored) = core.account(account) else {
        return false;
    };
    let account_name = stored.account_name;
    let stored = stored.settings;
    if let Some(with) = signs_in_with {
        // a browser sign-in account: the names only, the rest is the provider's
        let intro = t!(UiSignsInWith, app = &with);
        let form = Form::new(
            parent,
            &crate::words::plain(crate::words::Text::UiProperties),
            &intro,
            vec![
                Field::text(&t!(UiFieldAccountName), &account_name),
                Field::text(&t!(UiFieldName), &stored.name),
            ],
            &t!(UiOk),
            0,
        );
        form.widget().set_widget_name("account-properties");
        let ok = form.run().await;
        let (named, name) = (form.value(0), form.value(1));
        form.close();
        if !ok {
            return false;
        }
        let settings = AccountSettings { name, ..stored };
        return core.update_account(account, &settings).is_ok() && core.set_account_name(account, &named).is_ok();
    }
    let form = Form::new(
        parent,
        &crate::words::plain(crate::words::Text::UiProperties),
        &t!(UiKeepPassword),
        server_fields(&stored, &account_name),
        &t!(UiOk),
        0,
    );
    form.widget().set_widget_name("account-properties");
    form.validate_with(validate);
    let mut saved = false;
    while form.run().await {
        let settings = settings_of(&form, stored.auth.clone());
        // warned for a side without encryption, unless it was so already to the same server: not each time such an
        // account is saved, but when the password would go readable somewhere new
        let newly_plain = |security: Security, host: &str, was: Security, was_host: &str| {
            security == Security::Plain && (was != Security::Plain || host != was_host)
        };
        let warn = newly_plain(
            settings.imap_security,
            &settings.imap_host,
            stored.imap_security,
            &stored.imap_host,
        ) || newly_plain(
            settings.smtp_security,
            &settings.smtp_host,
            stored.smtp_security,
            &stored.smtp_host,
        );
        if warn
            && !accept_plain(
                form.widget(),
                &settings,
                &crate::words::plain(crate::words::Text::UiProperties),
            )
            .await
        {
            continue;
        }
        if core.update_account(account, &settings).is_err() {
            ui::alert(
                form.widget(),
                &crate::words::plain(crate::words::Text::UiProperties),
                &t!(UiAccountNotSaved),
            )
            .await;
            continue;
        }
        let _ = core.set_account_name(account, &form.value(ACCOUNT_NAME));
        let password = form.value(PASSWORD);
        if !password.is_empty() {
            core.set_password(account, &password);
        }
        saved = true;
        break;
    }
    form.close();
    saved
}

/// An account's Properties from the folder tree's menu for it; true when it changed
pub async fn account_properties(parent: &impl IsA<gtk::Widget>, account: i64) -> bool {
    let core = &shell().core;
    let Ok(stored) = core.account(account) else {
        return false;
    };
    let with = SignInWith::of_auth_kind(&stored.settings.auth)
        .is_some()
        .then(|| core.sign_in_name(&stored.settings.auth))
        .flatten();
    properties(parent.as_ref(), account, with).await
}

/// A row of the accounts list: its name, then its address and incoming server (or the provider's sign-in)
struct AccountRow {
    id: i64,
    name: String,
}

fn fill_accounts(list: &gtk::ListBox, rows: &RefCell<Vec<AccountRow>>, select: usize) {
    while let Some(child) = list.first_child() {
        list.remove(&child);
    }
    let core = &shell().core;
    let mut kept = Vec::new();
    let accounts = core.accounts().unwrap_or_default();
    let titles = pe_core::account_titles(&accounts);
    for (account, title) in accounts.iter().zip(titles) {
        let s = &account.settings;
        let oauth = SignInWith::of_auth_kind(&s.auth).is_some();
        let server = if oauth {
            t!(UiBrowserSignInServer, server = &s.imap_host)
        } else {
            s.imap_host.clone()
        };
        let row = adw::ActionRow::builder()
            .title(glib::markup_escape_text(&title))
            .subtitle(glib::markup_escape_text(&format!("{}  \u{00B7}  {server}", s.email)))
            .build();
        list.append(&row);
        kept.push(AccountRow {
            id: account.id,
            name: s.name.clone(),
        });
    }
    let last = kept.len().saturating_sub(1);
    *rows.borrow_mut() = kept;
    list.select_row(list.row_at_index(select.min(last) as i32).as_ref());
}

/// File > Accounts: the accounts listed, to add, change (Properties), write a signature for, or remove; true when
/// one changed
pub async fn accounts_dialog(parent: &impl IsA<gtk::Widget>) -> bool {
    let list = gtk::ListBox::new();
    list.add_css_class("boxed-list");
    list.set_selection_mode(gtk::SelectionMode::Single);
    list.set_widget_name("accounts-list");
    let rows: Rc<RefCell<Vec<AccountRow>>> = Rc::default();
    fill_accounts(&list, &rows, 0);
    let (send, clicks) = async_channel::unbounded::<&'static str>();
    let buttons = gtk::Box::new(gtk::Orientation::Vertical, 6);
    for (id, label) in [
        ("add", t!(GtkAccountsAdd)),
        ("properties", t!(GtkAccountsProperties)),
        ("signature", t!(GtkAccountsSignature)),
        ("remove", crate::words::plain(crate::words::Text::UiRemove)),
        ("sign-in-apps", t!(GtkAccountsSignInApps)),
    ] {
        let button = gtk::Button::with_label(&label);
        button.set_widget_name(&format!("accounts-{id}"));
        let send = send.clone();
        button.connect_clicked(move |_| {
            let _ = send.try_send(id);
        });
        buttons.append(&button);
    }
    let activate = send.clone();
    list.connect_row_activated(move |_, _| {
        let _ = activate.try_send("properties");
    });
    let scrolled = gtk::ScrolledWindow::builder()
        .child(&list)
        .min_content_height(220)
        .hexpand(true)
        .hscrollbar_policy(gtk::PolicyType::Never)
        .build();
    let content = gtk::Box::new(gtk::Orientation::Horizontal, 12);
    content.set_margin_start(18);
    content.set_margin_end(18);
    content.set_margin_bottom(18);
    content.append(&scrolled);
    content.append(&buttons);
    let view = adw::ToolbarView::new();
    view.add_top_bar(&adw::HeaderBar::new());
    view.set_content(Some(&content));
    let dialog = adw::Dialog::builder()
        .title(t!(UiAccountsTitle))
        .content_width(640)
        .child(&view)
        .build();
    dialog.set_widget_name("accounts-dialog");
    dialog.connect_closed(move |_| {
        let _ = send.try_send("close");
    });
    dialog.present(Some(parent.as_ref()));
    let mut changed = false;
    let host = dialog.clone().upcast::<gtk::Widget>();
    while let Ok(click) = clicks.recv().await {
        let index = list.selected_row().map_or(0, |row| row.index().max(0) as usize);
        let chosen = rows.borrow().get(index).map(|r| (r.id, r.name.clone()));
        match (click, chosen) {
            ("close", _) => break,
            ("add", _) => {
                if new_account(&host).await > 0 {
                    changed = true;
                    fill_accounts(&list, &rows, usize::MAX);
                }
            }
            ("properties", Some((id, _))) => {
                if account_properties(&host, id).await {
                    changed = true;
                    fill_accounts(&list, &rows, index);
                }
            }
            ("signature", Some((id, name))) => {
                crate::compose::edit_signature(&host, id, &name).await;
            }
            ("remove", Some((id, _))) => {
                if ui::confirm(&host, &t!(UiRemoveAccount), &t!(UiRemoveAccountAsk), true).await {
                    let _ = shell().core.remove_account(id);
                    changed = true;
                    fill_accounts(&list, &rows, index);
                }
            }
            ("sign-in-apps", _) => {
                crate::sign_in_apps::sign_in_apps_dialog(&host).await;
                fill_accounts(&list, &rows, index);
            }
            _ => {}
        }
    }
    dialog.close();
    changed
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn the_server_form_is_checked() {
        let mut fields = server_fields(
            &AccountSettings {
                email: "ann@example.com".into(),
                imap_host: "imap.example.com".into(),
                imap_port: 993,
                smtp_host: "smtp.example.com".into(),
                smtp_port: 465,
                ..Default::default()
            },
            "example.com",
        );
        assert_eq!(validate(&fields), Ok(()));
        fields[IMAP_PORT].value = "70000".into();
        assert_eq!(validate(&fields), Err("Ports are numbers from 1 to 65535.".into()));
        fields[IMAP_PORT].value = "993".into();
        fields[EMAIL].value = "ann".into();
        assert_eq!(validate(&fields), Err("The e-mail address is not valid.".into()));
        fields[SMTP_HOST].value.clear();
        assert_eq!(validate(&fields), Err("Outgoing (SMTP) server is required.".into()));
        assert_eq!(fields[SMTP_SECURITY].chosen(), Some(0));
    }
}
