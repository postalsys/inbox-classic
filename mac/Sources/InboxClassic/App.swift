// Inbox Classic on the Mac: the app, its menus (from core/commands.toml, Generated/Commands.swift), the command line,
// the Dock, mailto: links and quitting. All mail data comes from the Rust core (Core.swift); the main window
// (MainWindow.swift) shows it.
import AppKit
import CInboxClassic
import Sparkle
@preconcurrency import UserNotifications

/// The command line, options for test runs: --store <file> uses another mail store, --memory-passwords keeps
/// passwords for this run only, --pin-certificate <file> trusts only that server certificate, --sign-in-page-file
/// <file> writes the page of a browser sign-in there for the test to open instead of the browser
public struct Arguments {
    public var store: String?
    public var certificate: String?
    public var memoryPasswords = false
    public var signInPageFile: String?
    public var version = false
    /// a mailto: link to write a message for
    public var mailto: String?
    /// --mcp: relay an AI agent's MCP connection to the app that is running (started when it is not), no window
    public var mcp = false
    /// --background: started for an agent (by --mcp), without its window
    public var background = false

    public init(_ arguments: [String]) {
        var rest = arguments.dropFirst().makeIterator()
        while let argument = rest.next() {
            switch argument {
            case "--store": store = rest.next()
            case "--pin-certificate": certificate = rest.next()
            case "--sign-in-page-file": signInPageFile = rest.next()
            case "--memory-passwords": memoryPasswords = true
            case "--version": version = true
            case "--mcp": mcp = true
            case "--background": background = true
            default:
                if argument.lowercased().hasPrefix("mailto:") {
                    mailto = argument
                }
            }
        }
    }
}

/// The store of the app: ~/Library/Application Support/Inbox Classic/store.db
func defaultStorePath() -> String {
    let support = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
    let folder = support.appendingPathComponent("Inbox Classic", isDirectory: true)
    try? FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
    return folder.appendingPathComponent("store.db").path
}

/// Starts the app with the process's arguments; does not return
@MainActor
public func runApp(_ arguments: Arguments = Arguments(CommandLine.arguments)) -> Never {
    if arguments.version {
        print("Inbox Classic \(Core.version)")
        exit(0)
    }
    if arguments.mcp {
        // before the app starts: no Dock icon, no window, only the relay between the agent and the running app
        let store = arguments.store ?? defaultStorePath()
        exit(arguments.store.map { given in given.withCString { pe_mcp_relay(store, $0) } } ?? pe_mcp_relay(store, nil))
    }
    let app = NSApplication.shared
    let delegate = AppDelegate(arguments)
    app.delegate = delegate
    app.setActivationPolicy(.regular)
    app.run()
    exit(0)
}

@MainActor
public final class AppDelegate: NSObject, NSApplicationDelegate, NSMenuItemValidation, UNUserNotificationCenterDelegate {
    public static private(set) var shared: AppDelegate!
    let arguments: Arguments
    private(set) var core: Core!
    public private(set) var main: MainWindow!
    /// Tools > Notify of New Mail
    var notify: Bool {
        get { UserDefaults.standard.object(forKey: "NewMailNotifications") as? Bool ?? true }
        set { UserDefaults.standard.set(newValue, forKey: "NewMailNotifications") }
    }
    /// the app ends after the compose windows that are saving have closed
    var quitAfterCompose = false
    /// updates from the appcast (Info.plist SUFeedURL), checked daily and with Check for Updates; not in a test or a
    /// build without its key
    private var updater: SPUStandardUpdaterController?

    public init(_ arguments: Arguments) {
        self.arguments = arguments
        super.init()
        AppDelegate.shared = self
        SignIn.pageFile = arguments.signInPageFile
        // a mailto: link the system hands over while the app runs
        NSAppleEventManager.shared().setEventHandler(self, andSelector: #selector(openURL(_:reply:)),
                                                     forEventClass: AEEventClass(kInternetEventClass),
                                                     andEventID: AEEventID(kAEGetURL))
    }

    public func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.mainMenu = buildMenu()
        let store = arguments.store ?? defaultStorePath()
        guard let core = Core(path: store, memoryPasswords: arguments.memoryPasswords, certificate: arguments.certificate,
                              onEvent: { [weak self] in self?.main?.onEvent($0) })
        else {
            inform(arguments.certificate == nil ? "The mail store could not be opened."
                                                     : "The mail store or the certificate file could not be opened.",
                        style: .error)
            NSApp.terminate(nil)
            return
        }
        self.core = core
        // where the user's AI agents reach this app (--mcp); another app with this store open keeps them
        pe_mcp_start(core.handle)
        main = MainWindow(core: core)
        // started for an agent: running, with its window closed as it is after closing it
        if !arguments.background {
            main.window.makeKeyAndOrderFront(nil)
        }
        // once the window is laid out at its size, on the next turn of the run loop
        onMain { [weak self] in
            self?.main?.mailbox.placeDividers()
            if !(self?.arguments.background ?? true) {
                self?.main?.mailbox.selectStart()
            }
        }
        if !arguments.background {
            NSApp.activate()
        }
        if isBundled {
            UNUserNotificationCenter.current().delegate = self
        }
        if isBundled && !TestHooks.testing && !(Bundle.main.object(forInfoDictionaryKey: "SUPublicEDKey") as? String ?? "").isEmpty {
            updater = SPUStandardUpdaterController(startingUpdater: true, updaterDelegate: nil, userDriverDelegate: nil)
        }
        // the first start: an account to read mail from
        onMain { [self] in
            if core.accounts().isEmpty && !arguments.background {
                main.addAccount()
            } else {
                core.syncAll()
            }
            if let link = arguments.mailto {
                main.openMailto(link)
            }
        }
    }

    /// notifications need the app's bundle (not a bare binary started from a build folder)
    var isBundled: Bool { Bundle.main.bundleIdentifier != nil }

    // ---- the Dock ----

    /// closing the window keeps the app running in the Dock, where it goes on checking mail
    public func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        false
    }

    /// a click on the Dock icon brings the window back
    public func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows: Bool) -> Bool {
        main?.show()
        return true
    }

    public func applicationDockMenu(_ sender: NSApplication) -> NSMenu? {
        let menu = NSMenu()
        for command in Command.allCases where command.menu == "tray" || command == .sync || command == .notify {
            menu.addItem(item(for: command, title: command == .sync ? "Check for New Mail" : nil))
        }
        return menu
    }

    // ---- quitting ----

    public func applicationShouldTerminate(_ sender: NSApplication) -> NSApplication.TerminateReply {
        // the messages being written first: each may ask to be saved; the app stays while one is kept open or saving
        switch ComposeWindow.closeAll() {
        case .closed:
            return .terminateNow
        case .saving:
            quitAfterCompose = true
            return .terminateCancel
        case .kept:
            return .terminateCancel
        }
    }

    /// a compose window closed: the app ends now if it was waiting for that
    func composeClosed() {
        if quitAfterCompose && ComposeWindow.open.isEmpty {
            NSApp.terminate(nil)
        }
    }

    // ---- links and notifications ----

    @objc func openURL(_ event: NSAppleEventDescriptor, reply: NSAppleEventDescriptor) {
        guard let link = event.paramDescriptor(forKeyword: keyDirectObject)?.stringValue,
              link.lowercased().hasPrefix("mailto:") else { return }
        main?.show()
        main?.openMailto(link)
    }

    public nonisolated func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse,
                                                   withCompletionHandler done: @escaping () -> Void) {
        let info = response.notification.request.content.userInfo
        let folder = info["folder"] as? Int64 ?? 0
        let uid = info["uid"] as? UInt64 ?? 0
        Task { @MainActor in
            self.main?.show()
            self.main?.showMessage(folder: folder, uid: uid)
            done()
        }
    }

    // ---- the menus ----

    private func item(for command: Command, title: String? = nil) -> NSMenuItem {
        let item = NSMenuItem(title: title ?? command.label, action: #selector(runCommand(_:)), keyEquivalent: "")
        if let (key, modifiers) = command.key {
            item.keyEquivalent = key
            item.keyEquivalentModifierMask = modifiers
        }
        item.tag = command.rawValue
        item.target = self
        item.setAccessibilityIdentifier("command.\(command)")
        return item
    }

    private func buildMenu() -> NSMenu {
        let bar = NSMenu()
        func submenu(_ title: String, _ items: [NSMenuItem]) -> NSMenu {
            let menu = NSMenu(title: title)
            items.forEach { menu.addItem($0) }
            let holder = NSMenuItem(title: title, action: nil, keyEquivalent: "")
            holder.submenu = menu
            bar.addItem(holder)
            return menu
        }
        func commands(_ menu: String) -> [Command] {
            Command.allCases.filter { $0.menu == menu }
        }
        let separator = { NSMenuItem.separator() }

        let about = item(for: .about)
        let quit = item(for: .exit, title: "Quit Inbox Classic")
        let services = NSMenuItem(title: "Services", action: nil, keyEquivalent: "")
        services.submenu = NSMenu()
        NSApp.servicesMenu = services.submenu
        let hide = NSMenuItem(title: "Hide Inbox Classic", action: #selector(NSApplication.hide(_:)), keyEquivalent: "h")
        let hideOthers = NSMenuItem(title: "Hide Others", action: #selector(NSApplication.hideOtherApplications(_:)),
                                    keyEquivalent: "h")
        hideOthers.keyEquivalentModifierMask = [.command, .option]
        let showAll = NSMenuItem(title: "Show All", action: #selector(NSApplication.unhideAllApplications(_:)),
                                 keyEquivalent: "")
        let updates = NSMenuItem(title: "Check for Updates\u{2026}", action: #selector(checkForUpdates), keyEquivalent: "")
        updates.target = self
        _ = submenu(appName, [about, updates, separator(), services, separator(), hide, hideOthers, showAll, separator(), quit])

        // the commands of each menu in the order of the table, grouped as the Windows menus group them
        let file = commands("file").filter { $0 != .exit }
        let fileItems: [NSMenuItem] = [item(for: .newAccount), item(for: .accounts), separator(),
                                       item(for: .newFolder), item(for: .renameFolder), item(for: .deleteFolder), separator(),
                                       item(for: .saveAs), item(for: .import), item(for: .print), separator(),
                                       item(for: .properties), separator(),
                                       NSMenuItem(title: "Close Window", action: #selector(NSWindow.performClose(_:)), keyEquivalent: "w")]
        assert(file.allSatisfy { command in fileItems.contains { $0.tag == command.rawValue } })
        _ = submenu("File", fileItems)

        // Undo and Select All go to the first responder: a text field's own, or the message list's (Command.undo and
        // Command.selectAll, which the list and the tree answer)
        let edit: [NSMenuItem] = [
            NSMenuItem(title: "Undo", action: Selector(("undo:")), keyEquivalent: "z"),
            {
                let redo = NSMenuItem(title: "Redo", action: Selector(("redo:")), keyEquivalent: "z")
                redo.keyEquivalentModifierMask = [.command, .shift]
                return redo
            }(),
            separator(),
            NSMenuItem(title: "Cut", action: #selector(NSText.cut(_:)), keyEquivalent: "x"),
            NSMenuItem(title: "Copy", action: #selector(NSText.copy(_:)), keyEquivalent: "c"),
            NSMenuItem(title: "Paste", action: #selector(NSText.paste(_:)), keyEquivalent: "v"),
            NSMenuItem(title: "Select All", action: #selector(NSText.selectAll(_:)), keyEquivalent: "a"),
            separator(),
            item(for: .find), separator(),
            item(for: .markRead), item(for: .markUnread), item(for: .markAllRead), separator(),
            item(for: .move), item(for: .delete),
        ]
        _ = submenu("Edit", edit)
        _ = submenu("View", commands("view").map { item(for: $0) })
        _ = submenu("Message", [item(for: .newMail), separator(), item(for: .reply), item(for: .replyAll), item(for: .forward),
                                separator(), item(for: .flag), separator(), item(for: .junk), item(for: .notJunk)])
        _ = submenu("Tools", [item(for: .sync), item(for: .outbox), separator(), item(for: .aiAgents), separator(), item(for: .notify),
                              item(for: .defaultApp)])
        let window = submenu("Window", [
            NSMenuItem(title: "Minimize", action: #selector(NSWindow.performMiniaturize(_:)), keyEquivalent: "m"),
            NSMenuItem(title: "Zoom", action: #selector(NSWindow.performZoom(_:)), keyEquivalent: ""),
            separator(),
            NSMenuItem(title: "Inbox Classic", action: #selector(showMain), keyEquivalent: "0"),
        ])
        NSApp.windowsMenu = window
        let help = submenu("Help", [item(for: .help, title: "Inbox Classic Help")])
        NSApp.helpMenu = help
        return bar
    }

    @objc func checkForUpdates() {
        guard let updater else {
            inform("This copy of Inbox Classic does not update itself. Get the latest version from inboxclassic.com.")
            return
        }
        updater.checkForUpdates(nil)
    }

    @objc func showMain() {
        main?.show()
    }

    @objc func runCommand(_ sender: NSMenuItem) {
        guard let command = Command(rawValue: sender.tag) else { return }
        perform(command)
    }

    /// what each command does; every command of the table is here, the build fails for one that is not
    func perform(_ command: Command) {
        guard let main else { return }
        switch command {
        case .newAccount: main.addAccount()
        case .exit: NSApp.terminate(nil)
        case .sync: core.syncAll()
        case .markRead: main.mailbox.markSelected(seen: true)
        case .markUnread: main.mailbox.markSelected(seen: false)
        case .pictures: main.mailbox.loadPictures()
        case .about: main.showAbout()
        case .newMail: main.newMessage()
        case .reply: main.reply(PE_DRAFT_KIND_REPLY)
        case .replyAll: main.reply(PE_DRAFT_KIND_REPLY_ALL)
        case .forward: main.reply(PE_DRAFT_KIND_FORWARD)
        case .help: HelpWindow.open()
        case .delete: main.mailbox.deleteSelected()
        case .move: main.mailbox.moveSelected()
        case .flag: main.mailbox.flagSelected()
        case .newFolder: main.mailbox.newFolder()
        case .renameFolder: main.mailbox.renameFolder()
        case .deleteFolder: main.mailbox.deleteFolder()
        case .accounts: main.showAccounts()
        case .find: main.focusFind()
        case .saveAs: main.mailbox.saveShownAs()
        case .print: main.mailbox.printShown()
        case .import: main.mailbox.importMessages()
        case .outbox: main.openOutbox()
        case .properties: main.mailbox.showProperties()
        case .markAllRead: main.mailbox.markAllRead()
        case .junk: main.mailbox.markJunk(true)
        case .notJunk: main.mailbox.markJunk(false)
        case .notify: notify.toggle()
        case .open: main.show()
        case .defaultApp: main.makeDefaultMailApp()
        case .viewSource: main.mailbox.showSource()
        case .aiAgents: AgentsWindow.open(core: core)
        case .selectAll: main.mailbox.selectAllMessages()
        case .undo: main.mailbox.undo()
        }
    }

    public func validateMenuItem(_ item: NSMenuItem) -> Bool {
        guard let command = Command(rawValue: item.tag), item.action == #selector(runCommand(_:)) else { return true }
        if command == .notify {
            item.state = notify ? .on : .off
        }
        guard let main, core != nil else { return command == .exit || command == .about || command == .help }
        // the main window's commands work on what it shows; with the keyboard in a text field Delete is the field's
        let typing = NSApp.keyWindow?.firstResponder is NSText
        // the commands of one message are off for several
        if command.needsOne && !main.mailbox.hasOne {
            return false
        }
        switch command {
        case .delete: return !typing && main.mailbox.hasSelection
        case .markRead, .markUnread, .flag: return main.mailbox.hasSelection
        case .move: return main.mailbox.canMove
        case .undo: return main.core.undoLabel != nil
        case .junk: return main.mailbox.hasSelection && !main.mailbox.inJunk
        case .notJunk: return main.mailbox.hasSelection && main.mailbox.inJunk
        case .pictures: return main.mailbox.picturesBlocked
        // All Inboxes is no folder of one account to make a folder in or import into
        case .newFolder, .import: return !main.mailbox.allInboxes
        default: return true
        }
    }
}
