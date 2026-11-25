// Generated from core/settings.toml by core/crates/pe-ffi/build.rs, do not edit

use pe_core::i18n::Text;

/// A page of Preferences, in the order of its view switcher
#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash)]
pub enum SettingsPage {
    General,
    Reading,
    Downloading,
    Sync,
}

impl SettingsPage {
    pub const ALL: &[SettingsPage] = &[SettingsPage::General, SettingsPage::Reading, SettingsPage::Downloading, SettingsPage::Sync];

    /// Its name as the dialog knows it (`set_visible_page_name`)
    pub fn name(self) -> &'static str {
        match self {
            SettingsPage::General => "general",
            SettingsPage::Reading => "reading",
            SettingsPage::Downloading => "downloading",
            SettingsPage::Sync => "sync",
        }
    }

    /// Its title in the view switcher
    pub fn text(self) -> Text {
        match self {
            SettingsPage::General => Text::UiSettingsGeneral,
            SettingsPage::Reading => Text::UiSettingsReading,
            SettingsPage::Downloading => Text::UiDownloadHeading,
            SettingsPage::Sync => Text::UiSettingsSync,
        }
    }

    /// The icon of its view switcher button
    pub fn icon(self) -> &'static str {
        match self {
            SettingsPage::General => "emblem-system-symbolic",
            SettingsPage::Reading => "mail-read-symbolic",
            SettingsPage::Downloading => "folder-download-symbolic",
            SettingsPage::Sync => "emblem-synchronizing-symbolic",
        }
    }

    /// Its groups in order
    pub fn groups(self) -> &'static [SettingsGroup] {
        match self {
            SettingsPage::General => &[SettingsGroup::Language, SettingsGroup::NewMail, SettingsGroup::Sending, SettingsGroup::DefaultApps],
            SettingsPage::Reading => &[SettingsGroup::MessageList, SettingsGroup::Messages, SettingsGroup::Encryption],
            SettingsPage::Downloading => &[SettingsGroup::Downloading],
            SettingsPage::Sync => &[SettingsGroup::Sync, SettingsGroup::SyncWhat],
        }
    }
}

/// A group of a page (AdwPreferencesGroup)
#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash)]
pub enum SettingsGroup {
    Language,
    NewMail,
    Sending,
    DefaultApps,
    MessageList,
    Messages,
    Encryption,
    Downloading,
    Sync,
    SyncWhat,
}

impl SettingsGroup {
    /// Its title, None for the one group of a page, which the page titles
    pub fn title(self) -> Option<Text> {
        match self {
            SettingsGroup::Language => Some(Text::UiSettingsLanguage),
            SettingsGroup::NewMail => Some(Text::UiSettingsNewMail),
            SettingsGroup::Sending => Some(Text::UiSettingsSending),
            SettingsGroup::DefaultApps => Some(Text::UiSettingsDefaultApps),
            SettingsGroup::MessageList => Some(Text::UiSettingsMessageList),
            SettingsGroup::Messages => Some(Text::UiSettingsMessages),
            SettingsGroup::Encryption => Some(Text::UiSettingsEncryption),
            SettingsGroup::Downloading => None,
            SettingsGroup::Sync => None,
            SettingsGroup::SyncWhat => Some(Text::UiSyncWhat),
        }
    }

    /// Its description, None for none
    pub fn note(self) -> Option<Text> {
        match self {
            SettingsGroup::Language => None,
            SettingsGroup::NewMail => None,
            SettingsGroup::Sending => None,
            SettingsGroup::DefaultApps => None,
            SettingsGroup::MessageList => None,
            SettingsGroup::Messages => None,
            SettingsGroup::Encryption => None,
            SettingsGroup::Downloading => Some(Text::UiDownloadNote),
            SettingsGroup::Sync => Some(Text::UiSyncNote),
            SettingsGroup::SyncWhat => Some(Text::UiSyncWhatNote),
        }
    }

    /// Its settings in order
    pub fn settings(self) -> &'static [Setting] {
        match self {
            SettingsGroup::Language => &[Setting::Language],
            SettingsGroup::NewMail => &[Setting::NotifyNewMail, Setting::CodesInNotifications],
            SettingsGroup::Sending => &[Setting::SendDelay],
            SettingsGroup::DefaultApps => &[Setting::DefaultMailApp, Setting::EmlDefault],
            SettingsGroup::MessageList => &[Setting::Layout, Setting::GroupByConversation, Setting::ShowWholeConversation, Setting::ConversationOrder, Setting::ListPictures],
            SettingsGroup::Messages => &[Setting::DarkMessages, Setting::ShowPreviews, Setting::PdfPreviews, Setting::PicturesAlways, Setting::TrustedSenders],
            SettingsGroup::Encryption => &[Setting::SearchEncrypted, Setting::Keyserver],
            SettingsGroup::Downloading => &[Setting::DownloadAhead, Setting::DownloadLimit],
            SettingsGroup::Sync => &[Setting::SyncPlace, Setting::SyncStatus, Setting::SyncSetUp, Setting::SyncNow, Setting::SyncComputers, Setting::SyncHistory, Setting::SyncTurnOff],
            SettingsGroup::SyncWhat => &[Setting::SyncAccounts, Setting::SyncPasswords, Setting::SyncSignIns, Setting::SyncSignInApps, Setting::SyncAppSecrets, Setting::SyncContacts, Setting::SyncKeys, Setting::SyncPrivateKeys, Setting::SyncRules, Setting::SyncTrusted, Setting::SyncSettings, Setting::SyncPreferences],
        }
    }
}

/// What a setting is: a switch row, a choice row with its value as subtitle, or a button row
#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash)]
pub enum SettingKind {
    Switch,
    Choice,
    Button,
    Status,
}

/// A setting of Preferences
#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash)]
pub enum Setting {
    Language,
    NotifyNewMail,
    CodesInNotifications,
    SendDelay,
    DefaultMailApp,
    EmlDefault,
    Layout,
    GroupByConversation,
    ShowWholeConversation,
    ConversationOrder,
    ListPictures,
    DarkMessages,
    ShowPreviews,
    PdfPreviews,
    PicturesAlways,
    TrustedSenders,
    SearchEncrypted,
    Keyserver,
    DownloadAhead,
    DownloadLimit,
    SyncPlace,
    SyncStatus,
    SyncSetUp,
    SyncNow,
    SyncComputers,
    SyncHistory,
    SyncTurnOff,
    SyncAccounts,
    SyncPasswords,
    SyncSignIns,
    SyncSignInApps,
    SyncAppSecrets,
    SyncContacts,
    SyncKeys,
    SyncPrivateKeys,
    SyncRules,
    SyncTrusted,
    SyncSettings,
    SyncPreferences,
}

impl Setting {
    /// Its name in code and the UI test (`codes_in_notifications`)
    pub fn name(self) -> &'static str {
        match self {
            Setting::Language => "language",
            Setting::NotifyNewMail => "notify_new_mail",
            Setting::CodesInNotifications => "codes_in_notifications",
            Setting::SendDelay => "send_delay",
            Setting::DefaultMailApp => "default_mail_app",
            Setting::EmlDefault => "eml_default",
            Setting::Layout => "layout",
            Setting::GroupByConversation => "group_by_conversation",
            Setting::ShowWholeConversation => "show_whole_conversation",
            Setting::ConversationOrder => "conversation_order",
            Setting::ListPictures => "list_pictures",
            Setting::DarkMessages => "dark_messages",
            Setting::ShowPreviews => "show_previews",
            Setting::PdfPreviews => "pdf_previews",
            Setting::PicturesAlways => "pictures_always",
            Setting::TrustedSenders => "trusted_senders",
            Setting::SearchEncrypted => "search_encrypted",
            Setting::Keyserver => "keyserver",
            Setting::DownloadAhead => "download_ahead",
            Setting::DownloadLimit => "download_limit",
            Setting::SyncPlace => "sync_place",
            Setting::SyncStatus => "sync_status",
            Setting::SyncSetUp => "sync_set_up",
            Setting::SyncNow => "sync_now",
            Setting::SyncComputers => "sync_computers",
            Setting::SyncHistory => "sync_history",
            Setting::SyncTurnOff => "sync_turn_off",
            Setting::SyncAccounts => "sync_accounts",
            Setting::SyncPasswords => "sync_passwords",
            Setting::SyncSignIns => "sync_sign_ins",
            Setting::SyncSignInApps => "sync_sign_in_apps",
            Setting::SyncAppSecrets => "sync_app_secrets",
            Setting::SyncContacts => "sync_contacts",
            Setting::SyncKeys => "sync_keys",
            Setting::SyncPrivateKeys => "sync_private_keys",
            Setting::SyncRules => "sync_rules",
            Setting::SyncTrusted => "sync_trusted",
            Setting::SyncSettings => "sync_settings",
            Setting::SyncPreferences => "sync_preferences",
        }
    }

    pub fn kind(self) -> SettingKind {
        match self {
            Setting::Language => SettingKind::Choice,
            Setting::NotifyNewMail => SettingKind::Switch,
            Setting::CodesInNotifications => SettingKind::Switch,
            Setting::SendDelay => SettingKind::Choice,
            Setting::DefaultMailApp => SettingKind::Button,
            Setting::EmlDefault => SettingKind::Button,
            Setting::Layout => SettingKind::Choice,
            Setting::GroupByConversation => SettingKind::Switch,
            Setting::ShowWholeConversation => SettingKind::Switch,
            Setting::ConversationOrder => SettingKind::Choice,
            Setting::ListPictures => SettingKind::Switch,
            Setting::DarkMessages => SettingKind::Switch,
            Setting::ShowPreviews => SettingKind::Switch,
            Setting::PdfPreviews => SettingKind::Switch,
            Setting::PicturesAlways => SettingKind::Switch,
            Setting::TrustedSenders => SettingKind::Button,
            Setting::SearchEncrypted => SettingKind::Switch,
            Setting::Keyserver => SettingKind::Switch,
            Setting::DownloadAhead => SettingKind::Choice,
            Setting::DownloadLimit => SettingKind::Choice,
            Setting::SyncPlace => SettingKind::Status,
            Setting::SyncStatus => SettingKind::Status,
            Setting::SyncSetUp => SettingKind::Button,
            Setting::SyncNow => SettingKind::Button,
            Setting::SyncComputers => SettingKind::Button,
            Setting::SyncHistory => SettingKind::Button,
            Setting::SyncTurnOff => SettingKind::Button,
            Setting::SyncAccounts => SettingKind::Switch,
            Setting::SyncPasswords => SettingKind::Switch,
            Setting::SyncSignIns => SettingKind::Switch,
            Setting::SyncSignInApps => SettingKind::Switch,
            Setting::SyncAppSecrets => SettingKind::Switch,
            Setting::SyncContacts => SettingKind::Switch,
            Setting::SyncKeys => SettingKind::Switch,
            Setting::SyncPrivateKeys => SettingKind::Switch,
            Setting::SyncRules => SettingKind::Switch,
            Setting::SyncTrusted => SettingKind::Switch,
            Setting::SyncSettings => SettingKind::Switch,
            Setting::SyncPreferences => SettingKind::Switch,
        }
    }

    /// Its label: & marks Windows' access key, a list's ends with a colon (`field_title` takes both off)
    pub fn text(self) -> Text {
        match self {
            Setting::Language => Text::UiLanguageLabel,
            Setting::NotifyNewMail => Text::UiNotifyNewMail,
            Setting::CodesInNotifications => Text::UiCodesInNotifications,
            Setting::SendDelay => Text::UiSendDelay,
            Setting::DefaultMailApp => Text::CmdDefaultApp,
            Setting::EmlDefault => Text::UiEmlDefault,
            Setting::Layout => Text::UiLayoutLabel,
            Setting::GroupByConversation => Text::UiGroupByConversation,
            Setting::ShowWholeConversation => Text::UiShowWholeConversation,
            Setting::ConversationOrder => Text::UiConversationOrder,
            Setting::ListPictures => Text::UiListPictures,
            Setting::DarkMessages => Text::UiDarkMessages,
            Setting::ShowPreviews => Text::UiPreviewShow,
            Setting::PdfPreviews => Text::UiPreviewPdfs,
            Setting::PicturesAlways => Text::UiPicturesAlwaysOption,
            Setting::TrustedSenders => Text::UiTrustedSendersButton,
            Setting::SearchEncrypted => Text::UiSearchEncrypted,
            Setting::Keyserver => Text::UiPgpKeyserver,
            Setting::DownloadAhead => Text::UiDownloadAhead,
            Setting::DownloadLimit => Text::UiDownloadLimit,
            Setting::SyncPlace => Text::UiSyncPlace,
            Setting::SyncStatus => Text::UiSyncStatus,
            Setting::SyncSetUp => Text::UiSyncSetUp,
            Setting::SyncNow => Text::UiSyncNow,
            Setting::SyncComputers => Text::UiSyncComputers,
            Setting::SyncHistory => Text::UiSyncHistory,
            Setting::SyncTurnOff => Text::UiSyncTurnOff,
            Setting::SyncAccounts => Text::UiSyncAccounts,
            Setting::SyncPasswords => Text::UiSyncPasswords,
            Setting::SyncSignIns => Text::UiSyncSignIns,
            Setting::SyncSignInApps => Text::UiSyncSignInApps,
            Setting::SyncAppSecrets => Text::UiSyncAppSecrets,
            Setting::SyncContacts => Text::UiSyncContacts,
            Setting::SyncKeys => Text::UiSyncKeys,
            Setting::SyncPrivateKeys => Text::UiSyncPrivateKeys,
            Setting::SyncRules => Text::UiSyncRules,
            Setting::SyncTrusted => Text::UiSyncTrusted,
            Setting::SyncSettings => Text::UiSyncSettings,
            Setting::SyncPreferences => Text::UiSyncPreferences,
        }
    }

    /// A note under it (the row's subtitle), None for none
    pub fn note(self) -> Option<Text> {
        match self {
            Setting::Language => Some(Text::UiRestartNote),
            Setting::NotifyNewMail => None,
            Setting::CodesInNotifications => None,
            Setting::SendDelay => Some(Text::UiSendDelayNote),
            Setting::DefaultMailApp => None,
            Setting::EmlDefault => None,
            Setting::Layout => None,
            Setting::GroupByConversation => None,
            Setting::ShowWholeConversation => Some(Text::UiShowWholeConversationNote),
            Setting::ConversationOrder => None,
            Setting::ListPictures => Some(Text::UiListPicturesNote),
            Setting::DarkMessages => None,
            Setting::ShowPreviews => Some(Text::UiPreviewShowNote),
            Setting::PdfPreviews => None,
            Setting::PicturesAlways => Some(Text::UiPicturesAlwaysWarning),
            Setting::TrustedSenders => None,
            Setting::SearchEncrypted => Some(Text::UiSearchEncryptedNote),
            Setting::Keyserver => Some(Text::UiPgpKeyserverNote),
            Setting::DownloadAhead => None,
            Setting::DownloadLimit => None,
            Setting::SyncPlace => None,
            Setting::SyncStatus => None,
            Setting::SyncSetUp => None,
            Setting::SyncNow => None,
            Setting::SyncComputers => None,
            Setting::SyncHistory => None,
            Setting::SyncTurnOff => None,
            Setting::SyncAccounts => None,
            Setting::SyncPasswords => None,
            Setting::SyncSignIns => None,
            Setting::SyncSignInApps => None,
            Setting::SyncAppSecrets => None,
            Setting::SyncContacts => None,
            Setting::SyncKeys => None,
            Setting::SyncPrivateKeys => None,
            Setting::SyncRules => None,
            Setting::SyncTrusted => None,
            Setting::SyncSettings => None,
            Setting::SyncPreferences => None,
        }
    }

    /// The switch it is insensitive while that is off, None for none
    pub fn depends_on(self) -> Option<Setting> {
        match self {
            Setting::Language => None,
            Setting::NotifyNewMail => None,
            Setting::CodesInNotifications => Some(Setting::NotifyNewMail),
            Setting::SendDelay => None,
            Setting::DefaultMailApp => None,
            Setting::EmlDefault => None,
            Setting::Layout => None,
            Setting::GroupByConversation => None,
            Setting::ShowWholeConversation => Some(Setting::GroupByConversation),
            Setting::ConversationOrder => Some(Setting::GroupByConversation),
            Setting::ListPictures => None,
            Setting::DarkMessages => None,
            Setting::ShowPreviews => None,
            Setting::PdfPreviews => Some(Setting::ShowPreviews),
            Setting::PicturesAlways => None,
            Setting::TrustedSenders => None,
            Setting::SearchEncrypted => None,
            Setting::Keyserver => None,
            Setting::DownloadAhead => None,
            Setting::DownloadLimit => None,
            Setting::SyncPlace => None,
            Setting::SyncStatus => None,
            Setting::SyncSetUp => None,
            Setting::SyncNow => None,
            Setting::SyncComputers => None,
            Setting::SyncHistory => None,
            Setting::SyncTurnOff => None,
            Setting::SyncAccounts => None,
            Setting::SyncPasswords => Some(Setting::SyncAccounts),
            Setting::SyncSignIns => Some(Setting::SyncAccounts),
            Setting::SyncSignInApps => None,
            Setting::SyncAppSecrets => Some(Setting::SyncSignInApps),
            Setting::SyncContacts => None,
            Setting::SyncKeys => None,
            Setting::SyncPrivateKeys => Some(Setting::SyncKeys),
            Setting::SyncRules => None,
            Setting::SyncTrusted => None,
            Setting::SyncSettings => None,
            Setting::SyncPreferences => None,
        }
    }
}
