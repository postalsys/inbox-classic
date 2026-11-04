// Generated from core/commands.toml by core/crates/pe-ffi/build.rs, do not edit
import AppKit

/// A command of the menus, the toolbar and the Dock menu
enum Command: Int, CaseIterable {
    case newAccount = 100
    case exit = 101
    case sync = 102
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
    case flag = 114
    case newFolder = 115
    case renameFolder = 116
    case deleteFolder = 117
    case accounts = 118
    case find = 120
    case saveAs = 121
    case print = 122
    case import = 123
    case outbox = 124
    case properties = 125
    case markAllRead = 126
    case junk = 127
    case notJunk = 128
    case notify = 129
    case open = 130
    case defaultApp = 131

    /// The menu it is in: file, edit, view, tools, message, help, or tray (the Dock menu)
    var menu: String {
        switch self {
        case .newAccount: return "file"
        case .exit: return "file"
        case .sync: return "tools"
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
        case .notify: return "tools"
        case .open: return "tray"
        case .defaultApp: return "tools"
        }
    }

    var label: String {
        switch self {
        case .newAccount: return "New Account…"
        case .exit: return "Exit"
        case .sync: return "Send and Receive All"
        case .markRead: return "Mark as Read"
        case .markUnread: return "Mark as Unread"
        case .pictures: return "Download Pictures"
        case .about: return "About Inbox Classic"
        case .newMail: return "New Message"
        case .reply: return "Reply to Sender"
        case .replyAll: return "Reply to All"
        case .forward: return "Forward"
        case .help: return "Contents"
        case .delete: return "Delete Message"
        case .move: return "Move to Folder…"
        case .flag: return "Flag Message"
        case .newFolder: return "New Folder…"
        case .renameFolder: return "Rename Folder…"
        case .deleteFolder: return "Delete Folder"
        case .accounts: return "Accounts…"
        case .find: return "Find Message"
        case .saveAs: return "Save As…"
        case .print: return "Print…"
        case .import: return "Import Messages…"
        case .outbox: return "Outbox…"
        case .properties: return "Properties"
        case .markAllRead: return "Mark All Read"
        case .junk: return "Mark as Junk"
        case .notJunk: return "Mark as Not Junk"
        case .notify: return "Notify of New Mail"
        case .open: return "Open Inbox Classic"
        case .defaultApp: return "Make Default Mail App…"
        }
    }

    /// The key equivalent and its modifiers, or nil
    var key: (String, NSEvent.ModifierFlags)? {
        switch self {
        case .newAccount: return nil
        case .exit: return ("q", [.command])
        case .sync: return ("n", [.command, .shift])
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
        case .notify: return nil
        case .open: return nil
        case .defaultApp: return nil
        }
    }

    /// A menu item with a check mark
    var isToggle: Bool {
        switch self {
        case .newAccount: return false
        case .exit: return false
        case .sync: return false
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
        case .notify: return true
        case .open: return false
        case .defaultApp: return false
        }
    }
}
