// Generated from core/settings.toml by core/crates/pe-ffi/build.rs, do not edit

use pe_core::i18n::Text;

/// A page of Preferences, in the order of its view switcher
#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash)]
pub enum SettingsPage {
    General,
    Reading,
    Downloading,
}

impl SettingsPage {
    pub const ALL: &[SettingsPage] = &[SettingsPage::General, SettingsPage::Reading, SettingsPage::Downloading];

    /// Its name as the dialog knows it (`set_visible_page_name`)
    pub fn name(self) -> &'static str {
        match self {
            SettingsPage::General => "general",
            SettingsPage::Reading => "reading",
            SettingsPage::Downloading => "downloading",
        }
    }

    /// Its title in the view switcher
    pub fn text(self) -> Text {
        match self {
            SettingsPage::General => Text::UiSettingsGeneral,
            SettingsPage::Reading => Text::UiSettingsReading,
            SettingsPage::Downloading => Text::UiDownloadHeading,
        }
    }

    /// The icon of its view switcher button
    pub fn icon(self) -> &'static str {
        match self {
            SettingsPage::General => "emblem-system-symbolic",
            SettingsPage::Reading => "mail-read-symbolic",
            SettingsPage::Downloading => "folder-download-symbolic",
        }
    }

    /// Its groups in order
    pub fn groups(self) -> &'static [SettingsGroup] {
        match self {
            SettingsPage::General => &[SettingsGroup::Language, SettingsGroup::NewMail, SettingsGroup::Sending, SettingsGroup::DefaultApps],
            SettingsPage::Reading => &[SettingsGroup::MessageList, SettingsGroup::Messages],
            SettingsPage::Downloading => &[SettingsGroup::Downloading],
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
    Downloading,
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
            SettingsGroup::Downloading => None,
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
            SettingsGroup::Downloading => Some(Text::UiDownloadNote),
        }
    }

    /// Its settings in order
    pub fn settings(self) -> &'static [Setting] {
        match self {
            SettingsGroup::Language => &[Setting::Language],
            SettingsGroup::NewMail => &[Setting::NotifyNewMail, Setting::CodesInNotifications],
            SettingsGroup::Sending => &[Setting::SendDelay],
            SettingsGroup::DefaultApps => &[Setting::DefaultMailApp, Setting::EmlDefault],
            SettingsGroup::MessageList => &[Setting::Layout, Setting::GroupByConversation, Setting::ListPictures],
            SettingsGroup::Messages => &[Setting::DarkMessages, Setting::PicturesAlways, Setting::TrustedSenders],
            SettingsGroup::Downloading => &[Setting::DownloadAhead, Setting::DownloadLimit],
        }
    }
}

/// What a setting is: a switch row, a choice row with its value as subtitle, or a button row
#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash)]
pub enum SettingKind {
    Switch,
    Choice,
    Button,
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
    ListPictures,
    DarkMessages,
    PicturesAlways,
    TrustedSenders,
    DownloadAhead,
    DownloadLimit,
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
            Setting::ListPictures => "list_pictures",
            Setting::DarkMessages => "dark_messages",
            Setting::PicturesAlways => "pictures_always",
            Setting::TrustedSenders => "trusted_senders",
            Setting::DownloadAhead => "download_ahead",
            Setting::DownloadLimit => "download_limit",
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
            Setting::ListPictures => SettingKind::Switch,
            Setting::DarkMessages => SettingKind::Switch,
            Setting::PicturesAlways => SettingKind::Switch,
            Setting::TrustedSenders => SettingKind::Button,
            Setting::DownloadAhead => SettingKind::Choice,
            Setting::DownloadLimit => SettingKind::Choice,
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
            Setting::ListPictures => Text::UiListPictures,
            Setting::DarkMessages => Text::UiDarkMessages,
            Setting::PicturesAlways => Text::UiPicturesAlwaysOption,
            Setting::TrustedSenders => Text::UiTrustedSendersButton,
            Setting::DownloadAhead => Text::UiDownloadAhead,
            Setting::DownloadLimit => Text::UiDownloadLimit,
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
            Setting::ListPictures => Some(Text::UiListPicturesNote),
            Setting::DarkMessages => None,
            Setting::PicturesAlways => Some(Text::UiPicturesAlwaysWarning),
            Setting::TrustedSenders => None,
            Setting::DownloadAhead => None,
            Setting::DownloadLimit => None,
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
            Setting::ListPictures => None,
            Setting::DarkMessages => None,
            Setting::PicturesAlways => None,
            Setting::TrustedSenders => None,
            Setting::DownloadAhead => None,
            Setting::DownloadLimit => None,
        }
    }
}
