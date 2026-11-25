//! Settings sync (Preferences > Sync): the rows of the Sync page, which show what fits sync's state (off: what it is
//! for and Set Up Sync; on: where it syncs through, how it went, its buttons and what it syncs), the Set Up Sync
//! dialog (where the vault is, then the passphrase that starts or joins it), the Computers and History pages, and the
//! core's sync events: what the others wrote applied when the core has read it, what a sync brought shown.

use std::cell::{Cell, RefCell};
use std::rc::Rc;
use std::time::Duration;

use adw::prelude::*;
use gtk::glib;
use pe_core::sync::items::Choice;
use pe_core::sync::run::{PlaceSetup, Probe};

use crate::app::{shell, spawn};
use crate::settings_pages::Setting;
use crate::ui::{self, TITLE};
use crate::words::{Text, field_title, plain, title};

thread_local! {
    /// The rows of the Sync page open, to show sync's state as it changes
    static ROWS: RefCell<Vec<(Setting, glib::WeakRef<gtk::Widget>)>> = const { RefCell::new(Vec::new()) };
    /// The What to sync group of the page open, hidden while sync is off
    static WHAT: glib::WeakRef<adw::PreferencesGroup> = glib::WeakRef::new();
    /// The group of the Computers page open, filled when the core has read them
    static COMPUTERS: glib::WeakRef<adw::PreferencesGroup> = glib::WeakRef::new();
    /// Set while the rows are being set from the state, so their switches do not write it back
    static SHOWING: Cell<bool> = const { Cell::new(false) };
}

/// The flag of `choice` a switch of the page stands for
fn flag(choice: &mut Choice, setting: Setting) -> Option<&mut bool> {
    Some(match setting {
        Setting::SyncAccounts => &mut choice.accounts,
        Setting::SyncPasswords => &mut choice.passwords,
        Setting::SyncSignIns => &mut choice.sign_ins,
        Setting::SyncSignInApps => &mut choice.sign_in_apps,
        Setting::SyncAppSecrets => &mut choice.app_secrets,
        Setting::SyncContacts => &mut choice.contacts,
        Setting::SyncKeys => &mut choice.keys,
        Setting::SyncPrivateKeys => &mut choice.private_keys,
        Setting::SyncRules => &mut choice.rules,
        Setting::SyncTrusted => &mut choice.trusted,
        Setting::SyncSettings => &mut choice.settings,
        Setting::SyncPreferences => &mut choice.preferences,
        _ => return None,
    })
}

/// The switches of what to sync, in the page's order
const SWITCHES: [Setting; 12] = [
    Setting::SyncAccounts,
    Setting::SyncPasswords,
    Setting::SyncSignIns,
    Setting::SyncSignInApps,
    Setting::SyncAppSecrets,
    Setting::SyncContacts,
    Setting::SyncKeys,
    Setting::SyncPrivateKeys,
    Setting::SyncRules,
    Setting::SyncTrusted,
    Setting::SyncSettings,
    Setting::SyncPreferences,
];

/// The row of a setting of the Sync page
pub fn row(setting: Setting) -> gtk::Widget {
    let row: gtk::Widget = match setting {
        Setting::SyncPlace | Setting::SyncStatus => {
            let row = adw::ActionRow::builder()
                .title(field_title(setting.text()))
                .subtitle_selectable(true)
                .build();
            row.add_css_class("property");
            row.upcast()
        }
        Setting::SyncSetUp => {
            let row = button(setting, |dialog| {
                spawn(async move {
                    set_up(&dialog).await;
                });
            });
            row.add_css_class("suggested-action");
            row
        }
        Setting::SyncNow => button(setting, |_| shell().core.settings_sync_now()),
        Setting::SyncTurnOff => {
            let row = button(setting, |dialog| {
                spawn(async move { turn_off(&dialog).await });
            });
            row.add_css_class("destructive-action");
            row
        }
        Setting::SyncComputers => page_row(setting, computers_page),
        Setting::SyncHistory => page_row(setting, history_page),
        _ => switch(setting),
    };
    crate::preferences::name_row(&row, setting);
    ROWS.with(|rows| {
        let mut rows = rows.borrow_mut();
        rows.retain(|(_, weak)| weak.upgrade().is_some());
        rows.push((setting, row.downgrade()));
    });
    // shown as sync is once the page is built
    glib::idle_add_local_once(refresh);
    row
}

/// The What to sync group of the page, hidden while sync is off
pub fn group_built(group: &adw::PreferencesGroup) {
    WHAT.with(|weak| weak.set(Some(group)));
}

fn button(setting: Setting, pressed: impl Fn(adw::PreferencesDialog) + 'static) -> gtk::Widget {
    crate::preferences::button_row(setting, pressed).upcast()
}

/// A row that opens a page of the dialog
fn page_row(setting: Setting, page: fn() -> adw::NavigationPage) -> gtk::Widget {
    let row = adw::ActionRow::builder()
        .title(title(setting.text()))
        .activatable(true)
        .build();
    row.add_suffix(&crate::icons::image("go-next-symbolic"));
    row.connect_activated(move |row| {
        if let Some(dialog) = crate::preferences::dialog_of(row) {
            dialog.push_subpage(&page());
        }
    });
    row.upcast()
}

/// A switch of what to sync: the choice changed at once, a sync follows
fn switch(setting: Setting) -> gtk::Widget {
    crate::preferences::switch_row(setting, false, move |active| {
        if SHOWING.with(Cell::get) {
            return;
        }
        let mut choice = shell().core.settings_sync_state().choice.unwrap_or_default();
        if let Some(on) = flag(&mut choice, setting) {
            *on = active;
            let _ = shell().core.settings_sync_set_choice(choice);
        }
    })
    .upcast()
}

/// The rows of the page open show sync as it is now
pub fn refresh() {
    let state = shell().core.settings_sync_state();
    let place = pe_core::sync::manage::place_words(&state);
    let status = pe_core::sync::manage::status_words(&state);
    let mut choice = state.choice.unwrap_or_default();
    SHOWING.with(|showing| showing.set(true));
    ROWS.with(|rows| {
        for (setting, weak) in rows.borrow().iter() {
            let Some(row) = weak.upgrade() else { continue };
            row.set_visible(state.on != (*setting == Setting::SyncSetUp));
            let line = match setting {
                Setting::SyncPlace => Some(&place),
                Setting::SyncStatus => Some(&status),
                _ => None,
            };
            if let (Some(line), Some(shown)) = (line, row.downcast_ref::<adw::ActionRow>()) {
                shown.set_subtitle(line);
            }
            if *setting == Setting::SyncNow {
                row.set_sensitive(!state.busy);
            }
            if let (Some(on), Some(switch)) = (flag(&mut choice, *setting), row.downcast_ref::<adw::SwitchRow>()) {
                switch.set_active(*on);
            }
        }
    });
    SHOWING.with(|showing| showing.set(false));
    if let Some(group) = WHAT.with(|weak| weak.upgrade()) {
        group.set_visible(state.on);
    }
}

// ---- the core's events ----

/// `SettingsSyncReady`: what the others wrote applied, this computer's changes sent, with the preferences now
pub fn ready() {
    let _ = shell().core.settings_sync_continue(&crate::setup::preferences());
}

/// `SettingsSyncChanged`: the page and its pages show the state, the preferences another computer changed are
/// applied, and what the user should know is said in the status bar
pub fn changed() {
    refresh();
    fill_computers();
    let news = shell().core.settings_sync_news();
    if !news.prefs.is_empty() {
        crate::setup::apply_preferences(&news.prefs);
    }
    let notice = news.notice();
    if !notice.is_empty() {
        shell().main().set_status(&notice);
    }
}

// ---- Set Up Sync ----

/// What the first page of Set Up Sync holds
struct Where {
    folder: gtk::CheckButton,
    path: Rc<RefCell<Option<std::path::PathBuf>>>,
    endpoint: adw::EntryRow,
    region: adw::EntryRow,
    bucket: adw::EntryRow,
    prefix: adw::EntryRow,
    access: adw::EntryRow,
    secret: adw::PasswordEntryRow,
}

impl Where {
    /// The place typed, None while something it needs is missing
    fn place(&self) -> Option<(PlaceSetup, Option<String>)> {
        if self.folder.is_active() {
            let path = self.path.borrow().clone()?;
            return Some((
                PlaceSetup::Folder {
                    path: path.to_string_lossy().into_owned(),
                },
                None,
            ));
        }
        let text = |entry: &adw::EntryRow| entry.text().trim().to_string();
        let (endpoint, bucket, access, secret) = (
            text(&self.endpoint),
            text(&self.bucket),
            text(&self.access),
            self.secret.text().to_string(),
        );
        if endpoint.is_empty() || bucket.is_empty() || access.is_empty() || secret.is_empty() {
            return None;
        }
        Some((
            PlaceSetup::Bucket {
                endpoint,
                region: text(&self.region),
                bucket,
                prefix: text(&self.prefix).trim_matches('/').to_string(),
                access_key: access,
            },
            Some(secret),
        ))
    }
}

fn entry(label: Text, name: &str) -> adw::EntryRow {
    let row = adw::EntryRow::builder().title(field_title(label)).build();
    row.set_widget_name(name);
    row
}

/// A page of the dialog: a header with `action` at its end, `content` under it
fn nav_page(heading: &str, name: &str, content: &adw::PreferencesPage, action: &gtk::Button) -> adw::NavigationPage {
    let header = adw::HeaderBar::new();
    action.add_css_class("suggested-action");
    header.pack_end(action);
    let view = adw::ToolbarView::new();
    view.add_top_bar(&header);
    view.set_content(Some(content));
    let page = adw::NavigationPage::new(&view, heading);
    page.set_tag(Some(name));
    page.set_widget_name(name);
    page
}

/// A problem said on a page, red, under its groups
fn problem_label() -> gtk::Label {
    let label = gtk::Label::builder().wrap(true).xalign(0.0).visible(false).build();
    label.add_css_class("error");
    label.set_widget_name("sync-problem");
    label
}

/// Set Up Sync: where the vault is, looked at; then the passphrase that starts a new one or joins the one there.
/// True once sync is on, false when the dialog was closed without it.
pub async fn set_up(parent: &impl IsA<gtk::Widget>) -> bool {
    let (done, finished) = async_channel::bounded::<bool>(1);
    let content = adw::PreferencesPage::new();
    let kinds = adw::PreferencesGroup::builder().title(plain(Text::UiSyncWhere)).build();
    let folder = gtk::CheckButton::new();
    folder.set_widget_name("sync-kind-folder");
    let bucket = gtk::CheckButton::new();
    bucket.set_group(Some(&folder));
    bucket.set_widget_name("sync-kind-bucket");
    folder.set_active(true);
    for (check, heading, note) in [
        (&folder, Text::UiSyncFolder, Text::UiSyncFolderNote),
        (&bucket, Text::UiSyncBucket, Text::UiSyncBucketNote),
    ] {
        let row = adw::ActionRow::builder()
            .title(plain(heading))
            .subtitle(plain(note))
            .activatable_widget(check)
            .build();
        row.add_prefix(check);
        kinds.add(&row);
    }
    content.add(&kinds);

    let folder_group = adw::PreferencesGroup::new();
    let chosen = adw::ActionRow::builder()
        .title(field_title(Text::UiSyncFolderLabel))
        .subtitle(plain(Text::UiSyncFolderNone))
        .build();
    chosen.add_css_class("property");
    let choose = gtk::Button::builder()
        .label(title(Text::UiSyncChooseFolder))
        .valign(gtk::Align::Center)
        .build();
    choose.set_widget_name("sync-choose-folder");
    chosen.add_suffix(&choose);
    folder_group.add(&chosen);
    content.add(&folder_group);

    let bucket_group = adw::PreferencesGroup::builder().visible(false).build();
    let place = Rc::new(Where {
        folder: folder.clone(),
        path: Rc::new(RefCell::new(None)),
        endpoint: entry(Text::UiSyncEndpoint, "sync-endpoint"),
        region: entry(Text::UiSyncRegion, "sync-region"),
        bucket: entry(Text::UiSyncBucketName, "sync-bucket"),
        prefix: entry(Text::UiSyncPrefix, "sync-prefix"),
        access: entry(Text::UiSyncAccessKey, "sync-access-key"),
        secret: adw::PasswordEntryRow::builder()
            .title(field_title(Text::UiSyncSecretKey))
            .build(),
    });
    place.secret.set_widget_name("sync-secret-key");
    place.endpoint.set_text("https://");
    for row in [
        &place.endpoint,
        &place.region,
        &place.bucket,
        &place.prefix,
        &place.access,
    ] {
        bucket_group.add(row);
    }
    bucket_group.add(&place.secret);
    content.add(&bucket_group);
    let problem = problem_label();
    let problems = adw::PreferencesGroup::new();
    problems.add(&problem);
    content.add(&problems);

    let next = gtk::Button::with_label(&title(Text::UiSyncNext));
    next.set_widget_name("sync-next");
    let first = nav_page(&title(Text::UiSyncSetUp), "sync-where", &content, &next);
    let navigation = adw::NavigationView::new();
    navigation.add(&first);
    let dialog = adw::Dialog::builder()
        .title(title(Text::UiSyncSetUp))
        .content_width(560)
        .content_height(640)
        .child(&navigation)
        .build();
    dialog.set_widget_name("sync-dialog");
    dialog.connect_closed({
        let done = done.clone();
        move |_| {
            let _ = done.try_send(false);
        }
    });

    let update: Rc<dyn Fn()> = {
        let (place, next, folder_group, bucket_group) =
            (place.clone(), next.clone(), folder_group.clone(), bucket_group.clone());
        Rc::new(move || {
            let on_folder = place.folder.is_active();
            folder_group.set_visible(on_folder);
            bucket_group.set_visible(!on_folder);
            next.set_sensitive(place.place().is_some());
        })
    };
    folder.connect_active_notify({
        let update = update.clone();
        move |_| update()
    });
    for row in [
        &place.endpoint,
        &place.region,
        &place.bucket,
        &place.prefix,
        &place.access,
    ] {
        let update = update.clone();
        row.connect_changed(move |_| update());
    }
    place.secret.connect_changed({
        let update = update.clone();
        move |_| update()
    });
    choose.connect_clicked({
        let (place, chosen, update, dialog) = (place.clone(), chosen.clone(), update.clone(), dialog.clone());
        move |_| {
            let (place, chosen, update, dialog) = (place.clone(), chosen.clone(), update.clone(), dialog.clone());
            spawn(async move {
                let Some(window) = dialog.root().and_downcast::<gtk::Window>() else {
                    return;
                };
                if let Some(path) = ui::choose_folder(&window, &plain(Text::UiSyncChooseFolderTitle)).await {
                    chosen.set_subtitle(&glib::markup_escape_text(&path.to_string_lossy()));
                    *place.path.borrow_mut() = Some(path);
                    update();
                }
            });
        }
    });
    update();

    next.connect_clicked({
        let (place, navigation, problem, dialog) = (place.clone(), navigation.clone(), problem.clone(), dialog.clone());
        let done = done.clone();
        move |next| {
            let Some((setup, secret)) = place.place() else { return };
            let (navigation, problem, dialog, next, done) = (
                navigation.clone(),
                problem.clone(),
                dialog.clone(),
                next.clone(),
                done.clone(),
            );
            spawn(async move {
                next.set_sensitive(false);
                problem.set_visible(false);
                let found = probe(setup.clone(), secret.clone()).await;
                next.set_sensitive(true);
                match found {
                    Probe::Problem(why) => {
                        problem.set_label(&pe_core::sentence(&why));
                        problem.set_visible(true);
                    }
                    found => navigation.push(&passphrase_page(&dialog, setup, secret, found == Probe::Vault, &done)),
                }
            });
        }
    });
    dialog.present(Some(parent.as_ref()));
    finished.recv().await.unwrap_or(false)
}

/// The first account a sync brings, waited for up to a minute (on the first run, joining sync)
pub async fn first_account() -> Option<i64> {
    for _ in 0..600 {
        if let Some(account) = shell().core.accounts().ok().and_then(|a| a.first().map(|a| a.id)) {
            return Some(account);
        }
        glib::timeout_future(Duration::from_millis(100)).await;
    }
    None
}

/// The place looked at on the core's runtime
async fn probe(place: PlaceSetup, secret: Option<String>) -> Probe {
    let core = &shell().core;
    if core.settings_sync_probe_start(place, secret).is_err() {
        return Probe::Problem(String::new());
    }
    loop {
        if let Some(found) = core.settings_sync_probe() {
            return found;
        }
        glib::timeout_future(Duration::from_millis(100)).await;
    }
}

/// The second page: the passphrase that joins the vault there (`join`), or a new one with its repeat that starts it;
/// the name of this computer; what to sync. Turn On Sync turns it on and closes the dialog.
fn passphrase_page(
    dialog: &adw::Dialog,
    place: PlaceSetup,
    secret: Option<String>,
    join: bool,
    done: &async_channel::Sender<bool>,
) -> adw::NavigationPage {
    let content = adw::PreferencesPage::new();
    let (heading, note) = if join {
        (Text::UiSyncJoinTitle, Text::UiSyncJoinNote)
    } else {
        (Text::UiSyncStartTitle, Text::UiSyncStartNote)
    };
    let pair = Rc::new(ui::PassphrasePair::new("sync-passphrase"));
    pair.group.set_description(Some(&plain(note)));
    // joining: one field, the passphrase chosen on the first computer
    pair.again.set_visible(!join);
    pair.feedback.set_visible(!join);
    if !join {
        pair.group.add(&pair.feedback);
    }
    content.add(&pair.group);
    let about = adw::PreferencesGroup::new();
    let name = entry(Text::UiSyncName, "sync-name");
    name.set_text(&glib::host_name());
    about.add(&name);
    if join {
        about.set_description(Some(&plain(Text::UiSyncMergeNote)));
    }
    content.add(&about);

    // what to sync, folded: everything unless the user opens it and leaves something out; the switches as the page's,
    // those that depend on another insensitive while it is off
    let what = adw::PreferencesGroup::builder()
        .description(plain(Text::UiSyncWhatNote))
        .build();
    let folded = adw::ExpanderRow::builder()
        .title(plain(Text::UiSyncWhat))
        .subtitle(plain(Text::UiSyncEverything))
        .build();
    folded.set_widget_name("sync-what");
    what.add(&folded);
    let mut switches: Vec<(Setting, adw::SwitchRow)> = Vec::new();
    for setting in SWITCHES {
        let row = adw::SwitchRow::builder()
            .title(plain(setting.text()))
            .active(true)
            .build();
        crate::preferences::name_row(&row, setting);
        if let Some((_, parent)) = switches.iter().find(|(built, _)| Some(*built) == setting.depends_on()) {
            parent.bind_property("active", &row, "sensitive").sync_create().build();
        }
        folded.add_row(&row);
        switches.push((setting, row));
    }
    let switches = Rc::new(switches);
    // the folded row says whether everything is synced
    for (_, row) in switches.iter() {
        let (switches, folded) = (switches.clone(), folded.clone());
        row.connect_active_notify(move |_| {
            let all = switches.iter().all(|(_, row)| row.is_active());
            folded.set_subtitle(&plain(if all {
                Text::UiSyncEverything
            } else {
                Text::UiSyncSomeLeftOut
            }));
        });
    }
    content.add(&what);
    let problem = problem_label();
    let problems = adw::PreferencesGroup::new();
    problems.add(&problem);
    content.add(&problems);

    let turn_on = gtk::Button::with_label(&title(Text::UiSyncTurnOn));
    turn_on.set_widget_name("sync-turn-on");
    let page = nav_page(&plain(heading), "sync-passphrase-page", &content, &turn_on);
    let check = {
        let (pair, name, turn_on) = (pair.clone(), name.clone(), turn_on.clone());
        move || {
            let typed = if join {
                !pair.first.text().is_empty()
            } else {
                pair.check()
            };
            turn_on.set_sensitive(typed && !name.text().trim().is_empty());
        }
    };
    {
        let check = check.clone();
        pair.connect_changed(check);
    }
    {
        let check = check.clone();
        name.connect_changed(move |_| check());
    }
    check();
    let first = pair.first.clone();
    page.connect_shown(move |_| {
        first.grab_focus();
    });
    turn_on.connect_clicked({
        let (dialog, done) = (dialog.clone(), done.clone());
        move |_| {
            let mut choice = Choice::default();
            for (setting, row) in switches.iter() {
                if let Some(on) = flag(&mut choice, *setting) {
                    *on = row.is_active();
                }
            }
            let passphrase = pair.take();
            let turned = shell().core.settings_sync_turn_on(
                place.clone(),
                secret.as_deref(),
                &passphrase,
                name.text().trim(),
                choice,
            );
            match turned {
                Ok(()) => {
                    let _ = done.try_send(true);
                    dialog.close();
                    refresh();
                    shell().main().set_status(&plain(Text::UiSyncOn));
                }
                Err(why) => {
                    problem.set_label(&pe_core::sentence(&why));
                    problem.set_visible(true);
                    pair.first.grab_focus();
                }
            }
        }
    });
    page
}

/// Turn Off Sync, asked first
async fn turn_off(parent: &adw::PreferencesDialog) {
    let off = plain(Text::UiSyncTurnOffButton);
    let cancel = plain(Text::UiCancel);
    let answer = ui::ask(
        parent,
        TITLE,
        &plain(Text::UiSyncTurnOffAsk),
        &[("cancel", cancel.as_str()), ("off", off.as_str())],
        "cancel",
        "cancel",
        Some("off"),
    )
    .await;
    if answer == "off" {
        let _ = shell().core.settings_sync_turn_off();
        refresh();
    }
}

// ---- Computers and History ----

/// A page of the Preferences dialog with `group` on it
fn subpage(heading: Text, name: &str, group: &adw::PreferencesGroup) -> adw::NavigationPage {
    let page = adw::PreferencesPage::new();
    page.add(group);
    let view = adw::ToolbarView::new();
    view.add_top_bar(&adw::HeaderBar::new());
    view.set_content(Some(&page));
    let shown = adw::NavigationPage::new(&view, &plain(heading));
    shown.set_widget_name(name);
    shown
}

/// The computers of the vault, read by the core; Remove on each but this one
fn computers_page() -> adw::NavigationPage {
    let group = adw::PreferencesGroup::builder()
        .description(plain(Text::UiSyncComputersNote))
        .build();
    COMPUTERS.with(|weak| weak.set(Some(&group)));
    let _ = shell().core.settings_sync_computers_start();
    fill_computers();
    subpage(Text::UiSyncComputersTitle, "sync-computers", &group)
}

/// The Computers page open shows the computers read, or that they are being read
fn fill_computers() {
    let Some(group) = COMPUTERS.with(|weak| weak.upgrade()) else {
        return;
    };
    clear(&group);
    let Some(computers) = shell().core.settings_sync_computers() else {
        let row = adw::ActionRow::builder().title(plain(Text::UiSyncLoading)).build();
        row.add_css_class("dim-label");
        group.add(&row);
        return;
    };
    for computer in computers {
        let seen = if computer.this {
            plain(Text::UiSyncThisComputer)
        } else {
            t!(UiSyncSeen, when = &*computer.seen)
        };
        let row = adw::ActionRow::builder()
            .title(glib::markup_escape_text(&computer.name))
            .subtitle(glib::markup_escape_text(&seen))
            .build();
        row.set_widget_name("sync-computer");
        if !computer.this {
            let remove = crate::icons::kept(
                gtk::Button::builder()
                    .icon_name("user-trash-symbolic")
                    .tooltip_text(plain(Text::UiRemove))
                    .valign(gtk::Align::Center)
                    .build(),
            );
            remove.add_css_class("flat");
            remove.set_widget_name("sync-computer-remove");
            let (device, name) = (computer.device.clone(), computer.name.clone());
            remove.connect_clicked(move |button| {
                let (device, name, button) = (device.clone(), name.clone(), button.clone());
                spawn(async move {
                    let asked = t!(UiSyncRemoveAsk, name = &*name);
                    if ui::confirm(&button, TITLE, &asked, true).await {
                        let _ = shell().core.settings_sync_remove_computer(&device);
                    }
                });
            });
            row.add_suffix(&remove);
        }
        group.add(&row);
    }
}

/// The edits other computers made at the same time as this one, which this one's replaced: Restore puts one back;
/// then the restore points, each opened in the Import window
fn history_page() -> adw::NavigationPage {
    let group = adw::PreferencesGroup::builder()
        .description(plain(Text::UiSyncHistoryNote))
        .build();
    fill_history(&group);
    let page = subpage(Text::UiSyncHistoryTitle, "sync-history", &group);
    if let Some(preferences) = group
        .ancestor(adw::PreferencesPage::static_type())
        .and_downcast::<adw::PreferencesPage>()
    {
        preferences.add(&restore_points());
    }
    page
}

/// How things were before a sync took something away, newest first: Open shows one in the Import window
fn restore_points() -> adw::PreferencesGroup {
    let group = adw::PreferencesGroup::builder()
        .title(plain(Text::UiSyncRestorePoints))
        .description(plain(Text::UiSyncRestorePointsNote))
        .build();
    let points = shell().core.settings_sync_restore_points();
    if points.is_empty() {
        let none = adw::ActionRow::builder()
            .title(plain(Text::UiSyncRestorePointsEmpty))
            .build();
        none.add_css_class("dim-label");
        none.set_widget_name("sync-restore-points-empty");
        group.add(&none);
    }
    for point in points {
        let row = adw::ActionRow::builder()
            .title(glib::markup_escape_text(&point.when))
            .build();
        row.set_widget_name("sync-restore-point");
        let open = gtk::Button::builder()
            .label(title(Text::UiSyncOpenPoint))
            .valign(gtk::Align::Center)
            .build();
        let path = point.path.clone();
        open.connect_clicked(move |button| {
            let (path, button) = (path.clone(), button.clone());
            spawn(async move {
                match shell().core.settings_sync_restore_point(&path) {
                    Ok(setup) => {
                        crate::setup::choose_and_import(&button, setup).await;
                    }
                    Err(why) => ui::alert(&button, TITLE, &why.to_string()).await,
                }
            });
        });
        row.add_suffix(&open);
        group.add(&row);
    }
    group
}

fn fill_history(group: &adw::PreferencesGroup) {
    clear(group);
    let rows = shell().core.settings_sync_history().unwrap_or_default();
    if rows.is_empty() {
        let none = adw::ActionRow::builder().title(plain(Text::UiSyncHistoryEmpty)).build();
        none.add_css_class("dim-label");
        none.set_widget_name("sync-history-empty");
        group.add(&none);
        return;
    }
    for edit in rows {
        let heading = if edit.value.is_empty() {
            edit.item.clone()
        } else {
            format!("{}: {}", edit.item, edit.value)
        };
        let row = adw::ActionRow::builder()
            .title(glib::markup_escape_text(&heading))
            .subtitle(glib::markup_escape_text(&t!(
                UiSyncHistoryRow,
                source = &*edit.source,
                when = &*edit.when
            )))
            .build();
        row.set_widget_name("sync-history-row");
        let restore = gtk::Button::builder()
            .label(title(Text::UiSyncRestore))
            .valign(gtk::Align::Center)
            .build();
        restore.set_widget_name("sync-history-restore");
        let (id, list) = (edit.id, group.clone());
        restore.connect_clicked(move |_| {
            let _ = shell().core.settings_sync_restore(id, &crate::setup::preferences());
            fill_history(&list);
        });
        row.add_suffix(&restore);
        group.add(&row);
    }
}

/// Every row of a group taken out
fn clear(group: &adw::PreferencesGroup) {
    let mut rows = Vec::new();
    let mut child = group.first_child();
    while let Some(widget) = child {
        collect_rows(&widget, &mut rows);
        child = widget.next_sibling();
    }
    for row in rows {
        group.remove(&row);
    }
}

fn collect_rows(widget: &gtk::Widget, rows: &mut Vec<gtk::Widget>) {
    if widget.is::<adw::PreferencesRow>() {
        rows.push(widget.clone());
        return;
    }
    let mut child = widget.first_child();
    while let Some(inner) = child {
        collect_rows(&inner, rows);
        child = inner.next_sibling();
    }
}
