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
        case .reading: return [.messageList, .messages, .encryption]
        case .downloading: return [.downloading]
        }
    }
}

/// A group of a pane: set apart by space, its title in the label column on its first row
enum SettingsGroup {
    case language
    case newMail
    case sending
    case defaultApps
    case updates
    case messageList
    case messages
    case encryption
    case downloading

    /// Its title, nil for none
    var label: Text? {
        switch self {
        case .language: return .uiSettingsLanguage
        case .newMail: return .uiSettingsNewMail
        case .sending: return .uiSettingsSending
        case .defaultApps: return .uiSettingsDefaultApps
        case .updates: return .macSettingsUpdates
        case .messageList: return .uiSettingsMessageList
        case .messages: return .uiSettingsMessages
        case .encryption: return .uiSettingsEncryption
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
        case .encryption: return nil
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
        case .messageList: return [.layout, .groupByConversation, .showWholeConversation, .conversationOrder, .listPictures]
        case .messages: return [.darkMessages, .showPreviews, .pdfPreviews, .picturesAlways, .trustedSenders]
        case .encryption: return [.searchEncrypted, .keyserver]
        case .downloading: return [.downloadAhead, .downloadLimit]
        }
    }
}

/// What a setting is: a check box, a pop-up with its label, or a push button
enum SettingKind {
    case toggle, choice, button
}

/// A setting of the settings window
enum Setting {
    case language
    case notifyNewMail
    case codesInNotifications
    case sendDelay
    case defaultMailApp
    case emlDefault
    case checkForUpdates
    case layout
    case groupByConversation
    case showWholeConversation
    case conversationOrder
    case listPictures
    case darkMessages
    case showPreviews
    case pdfPreviews
    case picturesAlways
    case trustedSenders
    case searchEncrypted
    case keyserver
    case downloadAhead
    case downloadLimit

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
        case .showWholeConversation: return .toggle
        case .conversationOrder: return .choice
        case .listPictures: return .toggle
        case .darkMessages: return .toggle
        case .showPreviews: return .toggle
        case .pdfPreviews: return .toggle
        case .picturesAlways: return .toggle
        case .trustedSenders: return .button
        case .searchEncrypted: return .toggle
        case .keyserver: return .toggle
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
        case .showWholeConversation: return .uiShowWholeConversation
        case .conversationOrder: return .uiConversationOrder
        case .listPictures: return .uiListPictures
        case .darkMessages: return .uiDarkMessages
        case .showPreviews: return .uiPreviewShow
        case .pdfPreviews: return .uiPreviewPdfs
        case .picturesAlways: return .uiPicturesAlwaysOption
        case .trustedSenders: return .uiTrustedSendersButton
        case .searchEncrypted: return .uiSearchEncrypted
        case .keyserver: return .uiPgpKeyserver
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
        case .showWholeConversation: return .uiShowWholeConversationNote
        case .conversationOrder: return nil
        case .listPictures: return .uiListPicturesNote
        case .darkMessages: return nil
        case .showPreviews: return .uiPreviewShowNote
        case .pdfPreviews: return nil
        case .picturesAlways: return .uiPicturesAlwaysWarning
        case .trustedSenders: return nil
        case .searchEncrypted: return .uiSearchEncryptedNote
        case .keyserver: return .uiPgpKeyserverNote
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
        case .showWholeConversation: return .groupByConversation
        case .conversationOrder: return .groupByConversation
        case .listPictures: return nil
        case .darkMessages: return nil
        case .showPreviews: return nil
        case .pdfPreviews: return .showPreviews
        case .picturesAlways: return nil
        case .trustedSenders: return nil
        case .searchEncrypted: return nil
        case .keyserver: return nil
        case .downloadAhead: return nil
        case .downloadLimit: return nil
        }
    }
}
