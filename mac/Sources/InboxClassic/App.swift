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
    /// --language <code>: the language of the windows for this run (tests: de, qps), over the one chosen
    public var language: String?

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
            case "--language": language = rest.next()
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
    // every word of the windows in the language of this run, before the first window reads one
    Languages.apply(arguments.language)
    let app = NSApplication.shared
    let delegate = AppDelegate(arguments)
    app.delegate = delegate
    app.setActivationPolicy(.regular)
    app.run()
    exit(0)
}

/// A setting of the app in the user defaults; the UI test keeps it in memory, so a run never changes the setting of
/// whoever runs it
@MainActor
struct Preference<Value> {
    let key: String
    private var testValue: Value
    private let fallback: Value

    init(_ key: String, default fallback: Value) {
        self.key = key
        self.fallback = fallback
        testValue = fallback
    }

    /// a Bool, Int or Double, as the user defaults keep them
    var value: Value {
        get { TestHooks.testing ? testValue : UserDefaults.standard.object(forKey: key) as? Value ?? fallback }
        set {
            if TestHooks.testing {
                testValue = newValue
            } else {
                UserDefaults.standard.set(newValue, forKey: key)
            }
        }
    }
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
    /// Settings > Group messages by conversation, on unless turned off
    var groupByConversation: Bool {
        get { grouping.value }
        set {
            grouping.value = newValue
            main?.mailbox.groupingChanged()
        }
    }
    private var grouping = Preference("GroupByConversation", default: true)
    /// Settings > Show sign-in codes in new mail notifications, off unless turned on: the core names the code
    var codesInNotifications: Bool {
        get { codes.value }
        set {
            codes.value = newValue
            pe_set_codes_in_notifications(newValue)
        }
    }
    private var codes = Preference("CodesInNotifications", default: false)
    /// View > Hide Ignored Conversations, off unless turned on
    var hideIgnored: Bool {
        get { hidingIgnored.value }
        set {
            hidingIgnored.value = newValue
            main?.mailbox.hideIgnoredChanged()
        }
    }
    private var hidingIgnored = Preference("HideIgnored", default: false)
    /// View > Hide Read Messages and the toolbar's Unread filter, for every folder, off unless turned on
    var hideRead: Bool {
        get { hidingRead.value }
        set {
            hidingRead.value = newValue
            main?.mailbox.hideReadChanged()
            main?.unreadOnlyChanged()
        }
    }
    private var hidingRead = Preference("HideRead", default: false)
    /// View > Folder List and the toolbar's sidebar button: the folder list beside the messages, on unless turned off
    var folderList: Bool {
        get { showingFolders.value }
        set {
            showingFolders.value = newValue
            main?.mailbox.folderListChanged()
        }
    }
    private var showingFolders = Preference("FolderList", default: true)
    /// View > Layout and Settings: Automatic (the window's width decides), Classic or Columns; in memory under test
    var layoutMode: PeLayoutMode {
        get { PeLayoutMode(rawValue: UInt32(clamping: max(0, min(2, layoutChoice.value)))) }
        set {
            layoutChoice.value = Int(newValue.rawValue)
            main?.updateLayout()
        }
    }
    private var layoutChoice = Preference("Layout", default: 0)
    /// Settings > Show senders' pictures in the message list, on unless turned off
    var listPictures: Bool {
        get { showingPictures.value }
        set {
            showingPictures.value = newValue
            main?.mailbox.listPicturesChanged()
        }
    }
    private var showingPictures = Preference("ListPictures", default: true)
    /// the View > Layout command of each choice
    static let layoutModes: [Command: PeLayoutMode] = [
        .layoutAutomatic: PE_LAYOUT_MODE_AUTOMATIC, .layoutClassic: PE_LAYOUT_MODE_CLASSIC, .layoutColumns: PE_LAYOUT_MODE_COLUMNS,
    ]
    /// View > Text Size's commands, in the order the core counts the sizes (Largest first)
    static let textSizes: [Command] = [.textSizeLargest, .textSizeLarger, .textSizeMedium, .textSizeSmaller, .textSizeSmallest]
    /// message files (and links) the system asked to open before the window was there
    private var pending: [URL] = []
    /// the app ends after the compose windows that are saving have closed
    var quitAfterCompose = false
    /// Restart Now was chosen: a new copy starts once this one has ended
    private var restarting = false
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
            inform(arguments.certificate == nil ? Text.uiStoreNotOpened.text : Text.uiStoreOrCertNotOpened.text,
                        style: .error)
            NSApp.terminate(nil)
            return
        }
        self.core = core
        TextSize.zoom = pe_text_zoom(core.handle)
        pe_set_codes_in_notifications(codesInNotifications)
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
            // what was being written when the app last ended without closing it
            if !arguments.background {
                ComposeWindow.openRecovered(core: core)
            }
            if let link = arguments.mailto {
                main.openMailto(link)
            }
            let waiting = pending
            pending = []
            application(NSApp, open: waiting)
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
            menu.addItem(item(for: command, title: command == .sync ? Text.trayCheck.text : nil))
        }
        return menu
    }

    // ---- quitting ----

    public func applicationShouldTerminate(_ sender: NSApplication) -> NSApplication.TerminateReply {
        // the messages being written first: each may ask to be saved; the app stays while one is kept open or saving
        switch ComposeWindow.closeAll() {
        case .closed:
            // what waits to be taken back goes now, not at the next start
            if let core { pe_send_waiting_now(core.handle) }
            return .terminateNow
        case .saving:
            quitAfterCompose = true
            return .terminateCancel
        case .kept:
            // a message kept open: no quitting, and no starting again when the user quits later
            restarting = false
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

    /// message files (.eml) opened from the Finder, each in a message window of its own; a mailto: link as openURL
    /// takes one
    public func application(_ application: NSApplication, open urls: [URL]) {
        guard let core, let main else {
            // before the app has started: once it has
            pending += urls
            return
        }
        for url in urls {
            if url.isFileURL {
                if let reason = MessageWindow.open(core: core, mailbox: main.mailbox, file: url) {
                    inform(reason, style: .warning)
                }
            } else if url.scheme?.lowercased() == "mailto" {
                main.show()
                main.openMailto(url.absoluteString)
            }
        }
    }

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

    /// a menu item that runs `command`, checked and turned off by validateMenuItem as the menus open
    func item(for command: Command, title: String? = nil) -> NSMenuItem {
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

    /// the View menu's items, those of a submenu (Layout, Sort By) together in it where the first of them is
    private func viewItems(_ commands: [Command]) -> [NSMenuItem] {
        var items: [NSMenuItem] = []
        var submenus: [String: NSMenu] = [:]
        for command in commands {
            guard let name = command.submenu else {
                items.append(item(for: command))
                continue
            }
            if submenus[name] == nil {
                let title = name == "layout" ? Text.menuLayout.text : Text.menuSortBy.text
                let menu = NSMenu(title: title)
                let holder = NSMenuItem(title: title, action: nil, keyEquivalent: "")
                holder.submenu = menu
                holder.setAccessibilityIdentifier("menu.\(name)")
                submenus[name] = menu
                items.append(holder)
            }
            // the direction after the fields, apart from them
            if command == .sortAscending {
                submenus[name]?.addItem(.separator())
            }
            submenus[name]?.addItem(item(for: command))
        }
        return items
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
        let quit = item(for: .exit, title: Text.macQuit.text)
        let settings = item(for: .options, title: Text.macSettings.text)
        let services = NSMenuItem(title: Text.macServices.text, action: nil, keyEquivalent: "")
        services.submenu = NSMenu()
        NSApp.servicesMenu = services.submenu
        let hide = NSMenuItem(title: Text.macHide.text, action: #selector(NSApplication.hide(_:)), keyEquivalent: "h")
        let hideOthers = NSMenuItem(title: Text.macHideOthers.text, action: #selector(NSApplication.hideOtherApplications(_:)),
                                    keyEquivalent: "h")
        hideOthers.keyEquivalentModifierMask = [.command, .option]
        let showAll = NSMenuItem(title: Text.macShowAll.text, action: #selector(NSApplication.unhideAllApplications(_:)),
                                 keyEquivalent: "")
        let updates = NSMenuItem(title: Text.macCheckUpdates.text, action: #selector(checkForUpdates), keyEquivalent: "")
        updates.target = self
        _ = submenu(appName, [about, updates, separator(), settings, separator(), services, separator(), hide, hideOthers,
                              showAll, separator(), quit])

        // the commands of each menu in the order of the table, grouped as the Windows menus group them
        let file = commands("file").filter { $0 != .exit }
        let fileItems: [NSMenuItem] = [item(for: .newAccount), item(for: .accounts), separator(),
                                       item(for: .newFolder), item(for: .renameFolder), item(for: .deleteFolder), item(for: .emptyFolder), separator(),
                                       item(for: .saveAs), item(for: .import), item(for: .print), separator(),
                                       item(for: .importAddressBook), item(for: .exportAddressBook), separator(),
                                       item(for: .properties), separator(),
                                       NSMenuItem(title: Text.macCloseWindow.text, action: #selector(NSWindow.performClose(_:)),
                                                  keyEquivalent: "w")]
        assert(file.allSatisfy { command in fileItems.contains { $0.tag == command.rawValue } })
        _ = submenu(Text.menuFile.text, fileItems)

        // Undo and Select All go to the first responder: a text field's own, or the message list's (Command.undo and
        // Command.selectAll, which the list and the tree answer)
        let edit: [NSMenuItem] = [
            NSMenuItem(title: Text.cmdUndo.text, action: Selector(("undo:")), keyEquivalent: "z"),
            {
                let redo = NSMenuItem(title: Text.macRedo.text, action: Selector(("redo:")), keyEquivalent: "z")
                redo.keyEquivalentModifierMask = [.command, .shift]
                return redo
            }(),
            separator(),
            NSMenuItem(title: Text.macCut.text, action: #selector(NSText.cut(_:)), keyEquivalent: "x"),
            NSMenuItem(title: Text.uiButtonCopy.text, action: #selector(NSText.copy(_:)), keyEquivalent: "c"),
            NSMenuItem(title: Text.macPaste.text, action: #selector(NSText.paste(_:)), keyEquivalent: "v"),
            NSMenuItem(title: Text.cmdSelectAll.text, action: #selector(NSText.selectAll(_:)), keyEquivalent: "a"),
            separator(),
            item(for: .find), item(for: .findInMessage), separator(),
            item(for: .markRead), item(for: .markUnread), item(for: .markAllRead), separator(),
            item(for: .move), item(for: .delete),
        ]
        _ = submenu(Text.menuEdit.text, edit)
        _ = submenu(Text.menuView.text, viewItems(commands("view")))
        _ = submenu(Text.menuMessage.text, [item(for: .newMail), separator(), item(for: .reply), item(for: .replyAll), item(for: .forward),
                                separator(), item(for: .flag), flagMenu(), separator(), item(for: .watchConversation),
                                item(for: .ignoreConversation), separator(), item(for: .archive), item(for: .junk),
                                item(for: .notJunk)])
        _ = submenu(Text.menuTools.text, [item(for: .sync), item(for: .outbox), separator(), item(for: .addressBook),
                                                  item(for: .addSenderToBook), separator(), item(for: .aiAgents), separator(), item(for: .notify),
                              item(for: .defaultApp)])
        let window = submenu(Text.macMenuWindow.text, [
            NSMenuItem(title: Text.macMinimize.text, action: #selector(NSWindow.performMiniaturize(_:)), keyEquivalent: "m"),
            NSMenuItem(title: Text.macZoom.text, action: #selector(NSWindow.performZoom(_:)), keyEquivalent: ""),
            separator(),
            NSMenuItem(title: "Inbox Classic", action: #selector(showMain), keyEquivalent: "0"),
        ])
        NSApp.windowsMenu = window
        let help = submenu(Text.menuHelp.text, [item(for: .help, title: Text.uiHelpTitle.text)])
        NSApp.helpMenu = help
        return bar
    }

    @objc func checkForUpdates() {
        guard let updater else {
            inform(Text.macNoUpdates.text)
            return
        }
        updater.checkForUpdates(nil)
    }

    @objc func showMain() {
        main?.show()
    }

    /// The menus and the main window made again in the language set now, as starting in it makes them: the UI test's
    /// start again, which it can not do in its own process
    func remakeWindows() {
        guard let core else { return }
        NSApp.mainMenu = buildMenu()
        let old = main
        main = MainWindow(core: core)
        old?.window.orderOut(nil)
        main.window.makeKeyAndOrderFront(nil)
        onMain { [weak self] in
            self?.main?.mailbox.placeDividers()
            self?.main?.mailbox.selectStart()
        }
    }

    /// Starts the app again (a language chosen in Settings counts from the start): it quits as Quit does, and only once
    /// it really ends (no message kept open) a new copy starts, a moment after, so the two never hold the store at once
    func restart() {
        restarting = true
        NSApp.terminate(nil)
    }

    public func applicationWillTerminate(_ notification: Notification) {
        guard restarting else { return }
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/sh")
        process.arguments = ["-c", "while kill -0 \"$1\" 2>/dev/null; do sleep 0.2; done; /usr/bin/open \"$2\"", "restart",
                             String(ProcessInfo.processInfo.processIdentifier), Bundle.main.bundlePath]
        try? process.run()
    }

    @objc func runCommand(_ sender: NSMenuItem) {
        guard let command = Command(rawValue: sender.tag) else { return }
        perform(command)
    }

    /// what each command does; every command of the table is here, the build fails for one that is not
    func perform(_ command: Command) {
        guard let main else { return }
        // a message's own window in front: the commands about a message are about that one
        if let message = MessageWindow.key, message.perform(command) {
            return
        }
        // the Address Book in front: Delete, Properties, Select All and Find are its own
        if let book = AddressBookWindow.key, book.perform(command) {
            return
        }
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
        case .help: Help.open(for: NSApp.keyWindow)
        case .delete: main.mailbox.deleteSelected()
        case .move: main.mailbox.moveSelected()
        case .copy: main.mailbox.moveSelected(copy: true)
        case .flag: main.mailbox.flagSelected()
        case .newFolder: main.mailbox.newFolder()
        case .renameFolder: main.mailbox.renameFolder()
        case .deleteFolder: main.mailbox.deleteFolder()
        case .emptyFolder: main.mailbox.emptyFolder()
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
        case .archive: main.mailbox.archiveSelected()
        case .watchConversation: main.mailbox.markConversations(PE_ACTION_WATCH)
        case .ignoreConversation: main.mailbox.markConversations(PE_ACTION_IGNORE)
        case .hideIgnored: hideIgnored.toggle()
        case .hideRead: hideRead.toggle()
        case .folderList: folderList.toggle()
        case .layoutAutomatic, .layoutClassic, .layoutColumns: layoutMode = Self.layoutModes[command] ?? layoutMode
        case .textSizeLargest, .textSizeLarger, .textSizeMedium, .textSizeSmaller, .textSizeSmallest:
            if let size = Self.textSizes.firstIndex(of: command), pe_set_text_size(main.core.handle, size) {
                TextSize.apply(pe_text_zoom(main.core.handle))
            }
        case .sortDate, .sortFrom, .sortSubject, .sortSize:
            if let field = Mailbox.sortFields[command] { main.mailbox.sortBy(field) }
        case .sortAscending: main.mailbox.setAscending(true)
        case .sortDescending: main.mailbox.setAscending(false)
        case .notify: notify.toggle()
        case .open: main.show()
        case .defaultApp: main.makeDefaultMailApp()
        case .viewSource: main.mailbox.showSource()
        case .aiAgents: AgentsWindow.open(core: core)
        case .selectAll: main.mailbox.selectAllMessages()
        case .undo: main.mailbox.undo()
        case .options: SettingsWindow.open(core: core)
        case .nextMessage: main.mailbox.selectNeighbour(1)
        case .previousMessage: main.mailbox.selectNeighbour(-1)
        case .nextUnread: main.mailbox.nextUnread()
        case .goToFolder:
            main.show()
            main.mailbox.chooseFolder()
        case .findInMessage: main.mailbox.reader.findCommand()
        case .expandAllThreads: main.mailbox.expandAll()
        case .collapseAllThreads: main.mailbox.collapseAll()
        case .addressBook: AddressBookWindow.show(core: core)
        case .addSenderToBook: main.mailbox.addSenderToBook()
        case .importAddressBook: AddressBookFiles.importFile(core: core)
        case .exportAddressBook: AddressBookFiles.exportFile(core: core)
        case .messageRules: RulesWindow.open(core: core)
        case .createRuleFromMessage: main.mailbox.createRuleFromMessage()
        }
    }

    /// Flag, a submenu of the seven colours Apple Mail flags in (by name, with their colour), then Clear Flag
    func flagMenu() -> NSMenuItem {
        let menu = NSMenu(title: Text.uiMenuFlag.text)
        for color in UInt8(1)...7 {
            let name = taken(pe_flag_color_name(color)) ?? ""
            let item = NSMenuItem(title: name, action: #selector(flagColor(_:)), keyEquivalent: "")
            item.tag = Int(color)
            item.target = self
            item.image = Icons.coloredFlag(color)
            item.setAccessibilityIdentifier("flag.\(color)")
            menu.addItem(item)
        }
        menu.addItem(.separator())
        let clear = NSMenuItem(title: Text.uiClearFlag.text, action: #selector(clearFlag(_:)), keyEquivalent: "")
        clear.target = self
        clear.setAccessibilityIdentifier("flag.clear")
        menu.addItem(clear)
        let flag = NSMenuItem(title: Text.uiMenuFlag.text, action: nil, keyEquivalent: "")
        flag.submenu = menu
        return flag
    }

    @objc func flagColor(_ sender: NSMenuItem) {
        if let message = MessageWindow.key {
            message.flag(color: UInt8(clamping: sender.tag))
            return
        }
        main?.mailbox.flagSelected(color: UInt8(clamping: sender.tag))
    }

    @objc func clearFlag(_ sender: NSMenuItem) {
        if let message = MessageWindow.key {
            message.flag(color: 0)
            return
        }
        main?.mailbox.clearFlag()
    }

    public func validateMenuItem(_ item: NSMenuItem) -> Bool {
        if item.action == #selector(flagColor(_:)) || item.action == #selector(clearFlag(_:)) {
            item.state = .off
            if let message = MessageWindow.key {
                item.state = item.action == #selector(flagColor(_:)) && Int(message.flagColor) == item.tag ? .on : .off
                return message.file == nil && (item.action == #selector(flagColor(_:)) || message.flagged)
            }
            guard let main, core != nil, main.mailbox.hasSelection else { return false }
            let summary = main.mailbox.summary
            if item.action == #selector(clearFlag(_:)) {
                return summary.flagged > 0
            }
            // the colour every selected message is flagged in is checked
            item.state = Int(summary.flag_color) == item.tag ? .on : .off
            return true
        }
        guard let command = Command(rawValue: item.tag), item.action == #selector(runCommand(_:)) else { return true }
        if command == .notify {
            item.state = notify ? .on : .off
        }
        if command == .hideIgnored {
            item.state = hideIgnored ? .on : .off
        }
        if command == .hideRead {
            item.state = hideRead ? .on : .off
        }
        if command == .folderList {
            item.state = folderList ? .on : .off
        }
        if let mode = Self.layoutModes[command] {
            item.state = layoutMode == mode ? .on : .off
        }
        if let size = Self.textSizes.firstIndex(of: command), let core {
            item.state = pe_text_size(core.handle) == size ? .on : .off
        }
        if let main, let state = main.mailbox.sortState(command) {
            item.state = state ? .on : .off
        }
        guard let main, core != nil else { return command == .exit || command == .about || command == .help }
        // checked while the conversation of every message they are about has the mark, which choosing it again takes away
        if command == .watchConversation || command == .ignoreConversation {
            let summary = MessageWindow.key?.selectionSummary ?? main.mailbox.summary
            item.state = (command == .watchConversation ? summary.watched : summary.ignored) ? .on : .off
        }
        if let message = MessageWindow.key, let on = message.validate(command) {
            return on
        }
        if let book = AddressBookWindow.key, let on = book.validate(command) {
            return on
        }
        // the main window's commands work on what it shows; with the keyboard in a text field Delete is the field's
        let typing = NSApp.keyWindow?.firstResponder is NSText
        // the commands of one message are off for several
        if command.needsOne && !main.mailbox.hasOne || command.needsSome && !main.mailbox.hasSelection {
            return false
        }
        if Mailbox.needsBody.contains(command) && main.mailbox.shownFailed {
            return false
        }
        switch command {
        case .delete: return !typing && main.mailbox.hasSelection
        case .markRead, .markUnread, .flag: return main.mailbox.hasSelection
        case .move, .copy: return main.mailbox.hasSelection
        case .undo: return main.core.undoLabel != nil
        case .junk: return main.mailbox.hasSelection && !main.mailbox.inJunk
        case .archive: return !typing && main.mailbox.canArchive
        case .notJunk: return main.mailbox.hasSelection && main.mailbox.inJunk
        case .pictures: return main.mailbox.picturesBlocked
        // All Inboxes is no folder of one account to make a folder in or import into
        case .newFolder, .import: return !main.mailbox.allInboxes
        case .emptyFolder: return main.mailbox.canEmptyFolder
        case .nextMessage, .previousMessage: return main.mailbox.list.numberOfRows > 0
        case .findInMessage: return main.mailbox.hasOne && main.mailbox.reader.messageView != nil
        case .expandAllThreads, .collapseAllThreads: return main.mailbox.grouped && main.mailbox.list.numberOfRows > 0
        default: return true
        }
    }
}
