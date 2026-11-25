// Generated from core/settings.toml by core/crates/pe-ffi/build.rs, do not edit

/// A pane of the settings window, in the order of its toolbar
enum SettingsPage: String, CaseIterable {
    case general = "general"
    case reading = "reading"
    case downloading = "downloading"
    case sync = "sync"

    /// Its toolbar item's label and the window's title while it is shown
    var label: Text {
        switch self {
        case .general: return .uiSettingsGeneral
        case .reading: return .uiSettingsReading
        case .downloading: return .uiDownloadHeading
        case .sync: return .uiSettingsSync
        }
    }

    /// The SF Symbol of its toolbar item
    var symbol: String {
        switch self {
        case .general: return "gearshape"
        case .reading: return "eyeglasses"
        case .downloading: return "arrow.down.circle"
        case .sync: return "arrow.triangle.2.circlepath"
        }
    }

    /// Its groups in order
    var groups: [SettingsGroup] {
        switch self {
        case .general: return [.language, .newMail, .sending, .defaultApps, .updates]
        case .reading: return [.messageList, .messages, .encryption]
        case .downloading: return [.downloading]
        case .sync: return [.sync, .syncWhat]
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
    case sync
    case syncWhat

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
        case .sync: return nil
        case .syncWhat: return .uiSyncWhat
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
        case .sync: return .uiSyncNote
        case .syncWhat: return .uiSyncWhatNote
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
        case .sync: return [.syncPlace, .syncStatus, .syncSetUp, .syncNow, .syncComputers, .syncHistory, .syncTurnOff]
        case .syncWhat: return [.syncAccounts, .syncPasswords, .syncSignIns, .syncSignInApps, .syncAppSecrets, .syncContacts, .syncKeys, .syncPrivateKeys, .syncRules, .syncTrusted, .syncSettings, .syncPreferences]
        }
    }
}

/// What a setting is: a check box, a pop-up with its label, a push button, or a line of state with its label
enum SettingKind {
    case toggle, choice, button, status
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
    case syncPlace
    case syncStatus
    case syncSetUp
    case syncNow
    case syncComputers
    case syncHistory
    case syncTurnOff
    case syncAccounts
    case syncPasswords
    case syncSignIns
    case syncSignInApps
    case syncAppSecrets
    case syncContacts
    case syncKeys
    case syncPrivateKeys
    case syncRules
    case syncTrusted
    case syncSettings
    case syncPreferences

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
        case .syncPlace: return .status
        case .syncStatus: return .status
        case .syncSetUp: return .button
        case .syncNow: return .button
        case .syncComputers: return .button
        case .syncHistory: return .button
        case .syncTurnOff: return .button
        case .syncAccounts: return .toggle
        case .syncPasswords: return .toggle
        case .syncSignIns: return .toggle
        case .syncSignInApps: return .toggle
        case .syncAppSecrets: return .toggle
        case .syncContacts: return .toggle
        case .syncKeys: return .toggle
        case .syncPrivateKeys: return .toggle
        case .syncRules: return .toggle
        case .syncTrusted: return .toggle
        case .syncSettings: return .toggle
        case .syncPreferences: return .toggle
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
        case .syncPlace: return .uiSyncPlace
        case .syncStatus: return .uiSyncStatus
        case .syncSetUp: return .uiSyncSetUp
        case .syncNow: return .uiSyncNow
        case .syncComputers: return .uiSyncComputers
        case .syncHistory: return .uiSyncHistory
        case .syncTurnOff: return .uiSyncTurnOff
        case .syncAccounts: return .uiSyncAccounts
        case .syncPasswords: return .uiSyncPasswords
        case .syncSignIns: return .uiSyncSignIns
        case .syncSignInApps: return .uiSyncSignInApps
        case .syncAppSecrets: return .uiSyncAppSecrets
        case .syncContacts: return .uiSyncContacts
        case .syncKeys: return .uiSyncKeys
        case .syncPrivateKeys: return .uiSyncPrivateKeys
        case .syncRules: return .uiSyncRules
        case .syncTrusted: return .uiSyncTrusted
        case .syncSettings: return .uiSyncSettings
        case .syncPreferences: return .uiSyncPreferences
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
        case .syncPlace: return nil
        case .syncStatus: return nil
        case .syncSetUp: return nil
        case .syncNow: return nil
        case .syncComputers: return nil
        case .syncHistory: return nil
        case .syncTurnOff: return nil
        case .syncAccounts: return nil
        case .syncPasswords: return nil
        case .syncSignIns: return nil
        case .syncSignInApps: return nil
        case .syncAppSecrets: return nil
        case .syncContacts: return nil
        case .syncKeys: return nil
        case .syncPrivateKeys: return nil
        case .syncRules: return nil
        case .syncTrusted: return nil
        case .syncSettings: return nil
        case .syncPreferences: return nil
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
        case .syncPlace: return nil
        case .syncStatus: return nil
        case .syncSetUp: return nil
        case .syncNow: return nil
        case .syncComputers: return nil
        case .syncHistory: return nil
        case .syncTurnOff: return nil
        case .syncAccounts: return nil
        case .syncPasswords: return .syncAccounts
        case .syncSignIns: return .syncAccounts
        case .syncSignInApps: return nil
        case .syncAppSecrets: return .syncSignInApps
        case .syncContacts: return nil
        case .syncKeys: return nil
        case .syncPrivateKeys: return .syncKeys
        case .syncRules: return nil
        case .syncTrusted: return nil
        case .syncSettings: return nil
        case .syncPreferences: return nil
        }
    }
}
