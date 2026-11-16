// Generated from core/settings.toml by core/crates/pe-ffi/build.rs, do not edit

/// A pane of the settings window, in the order of its toolbar
enum SettingsPage: String, CaseIterable {
    case general = "general"
    case reading = "reading"
    case downloading = "downloading"

    /// Its toolbar item's label and the window's title while it is shown
    var label: Text {
        switch self {
        case .general: return .uiSettingsGeneral
        case .reading: return .uiSettingsReading
        case .downloading: return .uiDownloadHeading
        }
    }

    /// The SF Symbol of its toolbar item
    var symbol: String {
        switch self {
        case .general: return "gearshape"
        case .reading: return "eyeglasses"
        case .downloading: return "arrow.down.circle"
        }
    }

    /// Its groups in order
    var groups: [SettingsGroup] {
        switch self {
        case .general: return [.language, .newMail, .sending, .defaultApps, .updates]
        case .reading: return [.messageList, .messages]
        case .downloading: return [.downloading]
        }
    }
}

/// A group of a pane: set apart by space, without a heading
enum SettingsGroup: CaseIterable {
    case language
    case newMail
    case sending
    case defaultApps
    case updates
    case messageList
    case messages
    case downloading

    var page: SettingsPage {
        switch self {
        case .language: return .general
        case .newMail: return .general
        case .sending: return .general
        case .defaultApps: return .general
        case .updates: return .general
        case .messageList: return .reading
        case .messages: return .reading
        case .downloading: return .downloading
        }
    }

    /// Its title as the other platforms show it, nil for none
    var label: Text? {
        switch self {
        case .language: return .uiLanguageLabel
        case .newMail: return .uiSettingsNewMail
        case .sending: return .uiSettingsSending
        case .defaultApps: return .uiSettingsDefaultApps
        case .updates: return nil
        case .messageList: return .uiSettingsMessageList
        case .messages: return .uiSettingsMessages
        case .downloading: return nil
        }
    }

    /// A note under the group, nil for none
    var note: Text? {
        switch self {
        case .language: return nil
        case .newMail: return nil
        case .sending: return nil
        case .defaultApps: return nil
        case .updates: return nil
        case .messageList: return nil
        case .messages: return nil
        case .downloading: return .uiDownloadNote
        }
    }

    /// Its settings in order
    var settings: [Setting] {
        switch self {
        case .language: return [.language]
        case .newMail: return [.notifyNewMail, .codesInNotifications]
        case .sending: return [.sendDelay]
        case .defaultApps: return [.defaultMailApp, .emlDefault]
        case .updates: return [.checkForUpdates]
        case .messageList: return [.layout, .groupByConversation, .listPictures]
        case .messages: return [.darkMessages, .picturesAlways, .trustedSenders]
        case .downloading: return [.downloadAhead, .downloadLimit]
        }
    }
}

/// What a setting is: a check box, a pop-up with its label, or a push button
enum SettingKind {
    case toggle, choice, button
}

/// A setting of the settings window
enum Setting: CaseIterable {
    case language
    case notifyNewMail
    case codesInNotifications
    case sendDelay
    case defaultMailApp
    case emlDefault
    case checkForUpdates
    case layout
    case groupByConversation
    case listPictures
    case darkMessages
    case picturesAlways
    case trustedSenders
    case downloadAhead
    case downloadLimit

    var group: SettingsGroup {
        switch self {
        case .language: return .language
        case .notifyNewMail: return .newMail
        case .codesInNotifications: return .newMail
        case .sendDelay: return .sending
        case .defaultMailApp: return .defaultApps
        case .emlDefault: return .defaultApps
        case .checkForUpdates: return .updates
        case .layout: return .messageList
        case .groupByConversation: return .messageList
        case .listPictures: return .messageList
        case .darkMessages: return .messages
        case .picturesAlways: return .messages
        case .trustedSenders: return .messages
        case .downloadAhead: return .downloading
        case .downloadLimit: return .downloading
        }
    }

    var kind: SettingKind {
        switch self {
        case .language: return .choice
        case .notifyNewMail: return .toggle
        case .codesInNotifications: return .toggle
        case .sendDelay: return .choice
        case .defaultMailApp: return .button
        case .emlDefault: return .button
        case .checkForUpdates: return .toggle
        case .layout: return .choice
        case .groupByConversation: return .toggle
        case .listPictures: return .toggle
        case .darkMessages: return .toggle
        case .picturesAlways: return .toggle
        case .trustedSenders: return .button
        case .downloadAhead: return .choice
        case .downloadLimit: return .choice
        }
    }

    /// Its label (a pop-up's ends with a colon)
    var label: Text {
        switch self {
        case .language: return .uiLanguageLabel
        case .notifyNewMail: return .uiNotifyNewMail
        case .codesInNotifications: return .uiCodesInNotifications
        case .sendDelay: return .uiSendDelay
        case .defaultMailApp: return .cmdDefaultApp
        case .emlDefault: return .uiEmlDefault
        case .checkForUpdates: return .macCheckUpdatesAutomatically
        case .layout: return .uiLayoutLabel
        case .groupByConversation: return .uiGroupByConversation
        case .listPictures: return .uiListPictures
        case .darkMessages: return .uiDarkMessages
        case .picturesAlways: return .uiPicturesAlwaysOption
        case .trustedSenders: return .uiTrustedSendersButton
        case .downloadAhead: return .uiDownloadAhead
        case .downloadLimit: return .uiDownloadLimit
        }
    }

    /// A note under it, nil for none
    var note: Text? {
        switch self {
        case .language: return .uiRestartNote
        case .notifyNewMail: return nil
        case .codesInNotifications: return nil
        case .sendDelay: return .uiSendDelayNote
        case .defaultMailApp: return nil
        case .emlDefault: return nil
        case .checkForUpdates: return nil
        case .layout: return nil
        case .groupByConversation: return nil
        case .listPictures: return .uiListPicturesNote
        case .darkMessages: return nil
        case .picturesAlways: return .uiPicturesAlwaysWarning
        case .trustedSenders: return nil
        case .downloadAhead: return nil
        case .downloadLimit: return nil
        }
    }

    /// The check box it is disabled while it is clear, nil for none
    var dependsOn: Setting? {
        switch self {
        case .language: return nil
        case .notifyNewMail: return nil
        case .codesInNotifications: return .notifyNewMail
        case .sendDelay: return nil
        case .defaultMailApp: return nil
        case .emlDefault: return nil
        case .checkForUpdates: return nil
        case .layout: return nil
        case .groupByConversation: return nil
        case .listPictures: return nil
        case .darkMessages: return nil
        case .picturesAlways: return nil
        case .trustedSenders: return nil
        case .downloadAhead: return nil
        case .downloadLimit: return nil
        }
    }
}
