// Generated from core/commands.toml by core/crates/pe-ffi/build.rs, do not edit
import AppKit

/// A command of the menus, the toolbar and the Dock menu
enum Command: Int, CaseIterable {
    case newAccount = 100
    case exit = 101
    case sync = 102
    case undo = 135
    case selectAll = 134
    case markRead = 103
    case markUnread = 104
    case pictures = 105
    case about = 106
    case newMail = 107
    case reply = 108
    case replyAll = 109
    case forward = 110
    case help = 111
    case delete = 112
    case move = 113
    case copy = 136
    case flag = 114
    case newFolder = 115
    case renameFolder = 116
    case deleteFolder = 117
    case accounts = 118
    case find = 120
    case saveAs = 121
    case print = 122
    case `import` = 123
    case outbox = 124
    case properties = 125
    case markAllRead = 126
    case junk = 127
    case notJunk = 128
    case archive = 138
    case notify = 129
    case open = 130
    case defaultApp = 131
    case viewSource = 132
    case aiAgents = 133
    case options = 137

    /// The menu it is in: file, edit, view, tools, message, help, or tray (the Dock menu)
    var menu: String {
        switch self {
        case .newAccount: return "file"
        case .exit: return "file"
        case .sync: return "tools"
        case .undo: return "edit"
        case .selectAll: return "edit"
        case .markRead: return "edit"
        case .markUnread: return "edit"
        case .pictures: return "view"
        case .about: return "help"
        case .newMail: return "message"
        case .reply: return "message"
        case .replyAll: return "message"
        case .forward: return "message"
        case .help: return "help"
        case .delete: return "edit"
        case .move: return "edit"
        case .copy: return "edit"
        case .flag: return "message"
        case .newFolder: return "file"
        case .renameFolder: return "file"
        case .deleteFolder: return "file"
        case .accounts: return "file"
        case .find: return "edit"
        case .saveAs: return "file"
        case .print: return "file"
        case .import: return "file"
        case .outbox: return "tools"
        case .properties: return "file"
        case .markAllRead: return "edit"
        case .junk: return "message"
        case .notJunk: return "message"
        case .archive: return "message"
        case .notify: return "tools"
        case .open: return "tray"
        case .defaultApp: return "tools"
        case .viewSource: return "view"
        case .aiAgents: return "tools"
        case .options: return "tools"
        }
    }

    /// In the language in use, from the catalog (cmd-<id>)
    var label: String {
        labelText.text.replacingOccurrences(of: "...", with: "…")
    }

    /// Its label in the catalog
    var labelText: Text {
        switch self {
        case .newAccount: return .cmdNewAccount
        case .exit: return .cmdExit
        case .sync: return .cmdSync
        case .undo: return .cmdUndo
        case .selectAll: return .cmdSelectAll
        case .markRead: return .cmdMarkRead
        case .markUnread: return .cmdMarkUnread
        case .pictures: return .cmdPictures
        case .about: return .cmdAbout
        case .newMail: return .cmdNewMail
        case .reply: return .cmdReply
        case .replyAll: return .cmdReplyAll
        case .forward: return .cmdForward
        case .help: return .cmdHelp
        case .delete: return .cmdDelete
        case .move: return .cmdMove
        case .copy: return .cmdCopy
        case .flag: return .cmdFlag
        case .newFolder: return .cmdNewFolder
        case .renameFolder: return .cmdRenameFolder
        case .deleteFolder: return .cmdDeleteFolder
        case .accounts: return .cmdAccounts
        case .find: return .cmdFind
        case .saveAs: return .cmdSaveAs
        case .print: return .cmdPrint
        case .import: return .cmdImport
        case .outbox: return .cmdOutbox
        case .properties: return .cmdProperties
        case .markAllRead: return .cmdMarkAllRead
        case .junk: return .cmdJunk
        case .notJunk: return .cmdNotJunk
        case .archive: return .cmdArchive
        case .notify: return .cmdNotify
        case .open: return .cmdOpen
        case .defaultApp: return .cmdDefaultApp
        case .viewSource: return .cmdViewSource
        case .aiAgents: return .cmdAiAgents
        case .options: return .cmdOptions
        }
    }

    /// The key equivalent and its modifiers, or nil
    var key: (String, NSEvent.ModifierFlags)? {
        switch self {
        case .newAccount: return nil
        case .exit: return ("q", [.command])
        case .sync: return ("n", [.command, .shift])
        case .undo: return ("z", [.command])
        case .selectAll: return ("a", [.command])
        case .markRead: return ("u", [.command, .shift])
        case .markUnread: return nil
        case .pictures: return nil
        case .about: return nil
        case .newMail: return ("n", [.command])
        case .reply: return ("r", [.command])
        case .replyAll: return ("r", [.command, .shift])
        case .forward: return ("f", [.command, .shift])
        case .help: return ("?", [.command])
        case .delete: return ("\u{8}", [.command])
        case .move: return ("v", [.command, .shift])
        case .copy: return nil
        case .flag: return ("l", [.command, .shift])
        case .newFolder: return nil
        case .renameFolder: return nil
        case .deleteFolder: return nil
        case .accounts: return nil
        case .find: return ("f", [.command])
        case .saveAs: return ("s", [.command, .shift])
        case .print: return ("p", [.command])
        case .import: return nil
        case .outbox: return nil
        case .properties: return ("u", [.command, .option])
        case .markAllRead: return ("a", [.command, .shift, .option])
        case .junk: return ("j", [.command, .shift])
        case .notJunk: return nil
        case .archive: return nil
        case .notify: return nil
        case .open: return nil
        case .defaultApp: return nil
        case .viewSource: return nil
        case .aiAgents: return nil
        case .options: return (",", [.command])
        }
    }

    /// A menu item with a check mark
    var isToggle: Bool {
        switch self {
        case .newAccount: return false
        case .exit: return false
        case .sync: return false
        case .undo: return false
        case .selectAll: return false
        case .markRead: return false
        case .markUnread: return false
        case .pictures: return false
        case .about: return false
        case .newMail: return false
        case .reply: return false
        case .replyAll: return false
        case .forward: return false
        case .help: return false
        case .delete: return false
        case .move: return false
        case .copy: return false
        case .flag: return false
        case .newFolder: return false
        case .renameFolder: return false
        case .deleteFolder: return false
        case .accounts: return false
        case .find: return false
        case .saveAs: return false
        case .print: return false
        case .import: return false
        case .outbox: return false
        case .properties: return false
        case .markAllRead: return false
        case .junk: return false
        case .notJunk: return false
        case .archive: return false
        case .notify: return true
        case .open: return false
        case .defaultApp: return false
        case .viewSource: return false
        case .aiAgents: return false
        case .options: return false
        }
    }

    /// Acts on one or several messages: off with none selected
    var needsSome: Bool {
        switch self {
        case .newAccount: return false
        case .exit: return false
        case .sync: return false
        case .undo: return false
        case .selectAll: return false
        case .markRead: return false
        case .markUnread: return false
        case .pictures: return false
        case .about: return false
        case .newMail: return false
        case .reply: return false
        case .replyAll: return false
        case .forward: return true
        case .help: return false
        case .delete: return false
        case .move: return false
        case .copy: return false
        case .flag: return false
        case .newFolder: return false
        case .renameFolder: return false
        case .deleteFolder: return false
        case .accounts: return false
        case .find: return false
        case .saveAs: return true
        case .print: return false
        case .import: return false
        case .outbox: return false
        case .properties: return false
        case .markAllRead: return false
        case .junk: return false
        case .notJunk: return false
        case .archive: return false
        case .notify: return false
        case .open: return false
        case .defaultApp: return false
        case .viewSource: return false
        case .aiAgents: return false
        case .options: return false
        }
    }

    /// Acts on one message only: off while several are selected
    var needsOne: Bool {
        switch self {
        case .newAccount: return false
        case .exit: return false
        case .sync: return false
        case .undo: return false
        case .selectAll: return false
        case .markRead: return false
        case .markUnread: return false
        case .pictures: return true
        case .about: return false
        case .newMail: return false
        case .reply: return true
        case .replyAll: return true
        case .forward: return false
        case .help: return false
        case .delete: return false
        case .move: return false
        case .copy: return false
        case .flag: return false
        case .newFolder: return false
        case .renameFolder: return false
        case .deleteFolder: return false
        case .accounts: return false
        case .find: return false
        case .saveAs: return false
        case .print: return true
        case .import: return false
        case .outbox: return false
        case .properties: return true
        case .markAllRead: return false
        case .junk: return false
        case .notJunk: return false
        case .archive: return false
        case .notify: return false
        case .open: return false
        case .defaultApp: return false
        case .viewSource: return true
        case .aiAgents: return false
        case .options: return false
        }
    }
}
