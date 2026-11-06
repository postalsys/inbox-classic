// The main window: the folders on the left, the message list on the top right and the reading pane below it, the
// toolbar with the search field, and a status bar at the bottom (what the app is doing, the Outbox, the counts).
// This file draws the frame and hands the core's events to the panes (Mailbox.swift).
import AppKit
import CInboxClassic
@preconcurrency import UserNotifications

@MainActor
public final class MainWindow: NSObject, NSWindowDelegate, NSToolbarDelegate, NSSearchFieldDelegate, NSToolbarItemValidation {
    let core: Core
    public let window: NSWindow
    public let mailbox: Mailbox
    private let statusText = NSTextField(labelWithString: "")
    private let outboxText = NSTextField(labelWithString: "")
    private let countsText = NSTextField(labelWithString: "")
    let searchField = NSSearchField()
    private var syncTimer: Timer?
    /// accounts whose password prompt is open, so a second failure does not open another
    private var prompting: Set<Int64> = []
    /// accounts whose last sync failed: their failure stays in the status bar
    private var failing: Set<Int64> = []
    /// the last message sent, as the outgoing pane says it once the Outbox is empty
    private var lastSent = ""
    private var junkItem: NSToolbarItem?

    init(core: Core) {
        self.core = core
        window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 1100, height: 760),
                          styleMask: [.titled, .closable, .miniaturizable, .resizable], backing: .buffered, defer: false)
        mailbox = Mailbox(core: core)
        super.init()
        window.title = appName
        window.identifier = NSUserInterfaceItemIdentifier("main")
        window.isReleasedWhenClosed = false
        window.delegate = self
        window.minSize = NSSize(width: 640, height: 420)
        window.tabbingMode = .disallowed
        let toolbar = NSToolbar(identifier: "Main")
        toolbar.delegate = self
        toolbar.displayMode = .iconAndLabel
        toolbar.allowsUserCustomization = false
        window.toolbar = toolbar
        window.toolbarStyle = .expanded
        window.contentView = makeContent()
        if !TestHooks.testing {
            window.setFrameAutosaveName("Main")
        }
        if TestHooks.testing || !window.setFrameUsingName("Main") {
            window.center()
        }
        mailbox.changed = { [weak self] in self?.showCounts() }
        mailbox.selectionChanged = { [weak self] in
            self?.updateJunk()
            self?.showCounts()
            // the buttons of one message and of the selection follow it at once, not at the next event
            self?.window.toolbar?.validateVisibleItems()
        }
        mailbox.status = { [weak self] in self?.setStatus($0) }
        mailbox.openMailto = { [weak self] in self?.openMailto($0) }
        showOutbox()
        showCounts()
        syncTimer = Timer.scheduledTimer(withTimeInterval: 10 * 60, repeats: true) { [weak self] _ in
            MainActor.assumeIsolated { self?.core.syncAll() }
        }
        showUnread()
    }

    private func makeContent() -> NSView {
        let status = NSStackView(views: [statusText, outboxText, countsText])
        status.distribution = .fill
        status.spacing = 16
        status.edgeInsets = NSEdgeInsets(top: 0, left: 12, bottom: 0, right: 12)
        for (label, id) in [(statusText, "status.text"), (outboxText, "status.outbox"), (countsText, "status.counts")] {
            label.font = .systemFont(ofSize: NSFont.smallSystemFontSize)
            label.textColor = .secondaryLabelColor
            label.lineBreakMode = .byTruncatingTail
            label.setAccessibilityIdentifier(id)
            label.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        }
        statusText.setContentHuggingPriority(.defaultLow, for: .horizontal)
        countsText.alignment = .right
        let content = NSView()
        let panes = mailbox.view
        panes.translatesAutoresizingMaskIntoConstraints = false
        status.translatesAutoresizingMaskIntoConstraints = false
        content.addSubview(panes)
        content.addSubview(status)
        NSLayoutConstraint.activate([
            panes.topAnchor.constraint(equalTo: content.topAnchor),
            panes.leadingAnchor.constraint(equalTo: content.leadingAnchor),
            panes.trailingAnchor.constraint(equalTo: content.trailingAnchor),
            panes.bottomAnchor.constraint(equalTo: status.topAnchor),
            status.leadingAnchor.constraint(equalTo: content.leadingAnchor),
            status.trailingAnchor.constraint(equalTo: content.trailingAnchor),
            status.bottomAnchor.constraint(equalTo: content.bottomAnchor),
            status.heightAnchor.constraint(equalToConstant: 24),
        ])
        window.setContentBorderThickness(24, for: .minY)
        return content
    }

    public func show() {
        if window.isMiniaturized {
            window.deminiaturize(nil)
        }
        window.makeKeyAndOrderFront(nil)
        NSApp.activate()
        // started for an agent: shown now for the first time
        mailbox.selectStart()
    }

    /// the close button: the app keeps checking mail from the Dock
    public func windowShouldClose(_ sender: NSWindow) -> Bool {
        window.orderOut(nil)
        if !UserDefaults.standard.bool(forKey: "DockNoteShown") {
            UserDefaults.standard.set(true, forKey: "DockNoteShown")
            notifyUser(title: "Inbox Classic is still running",
                       text: "It keeps checking for new mail. Click its icon in the Dock to open it again.", folder: 0, uid: 0)
        }
        return false
    }

    // ---- the status bar ----

    func setStatus(_ text: String) {
        statusText.stringValue = text
    }

    /// the selected folder in the title, what it holds in the status bar
    func showCounts() {
        countsText.stringValue = mailbox.counts
        let name = mailbox.selectedName
        window.title = name.isEmpty ? appName : name
        window.subtitle = name.isEmpty ? "" : appName
    }

    /// "Subject" in quotes, or "(no subject)"
    private func quoted(_ subject: String) -> String {
        subject.isEmpty ? "(no subject)" : "\u{201C}\(subject)\u{201D}"
    }

    /// the outgoing pane: what is being sent, what waits in the Outbox and why, or the last message sent
    func showOutbox() {
        guard let outbox = pe_outbox(core.handle) else { return }
        defer { pe_outbox_free(outbox) }
        let waiting = pe_outbox_count(outbox)
        var said = lastSent
        if waiting > 0, let first = pe_outbox_get(outbox, 0) {
            let subject = text(first.pointee.subject)
            let failed = first.pointee.problem != nil && first.pointee.problem.pointee != 0
            if waiting > 1 {
                said = "\(waiting) messages in the Outbox"
            } else if failed {
                said = "\(quoted(subject)) waits in the Outbox"
            } else {
                said = "Sending \(quoted(subject))\u{2026}"
            }
        }
        outboxText.stringValue = said
        outboxText.toolTip = said
    }

    // ---- the core's events ----

    func onEvent(_ event: CoreEvent) {
        switch event.kind {
        case PE_EVENT_KIND_SYNC_STARTED:
            failing.remove(event.account)
            setStatus("Checking for new messages on \(mailbox.accountName(event.account))\u{2026}")
        case PE_EVENT_KIND_SYNC_FINISHED:
            // a failure stays in the status bar until the account syncs without one
            if failing.isEmpty {
                setStatus("Done")
            }
        case PE_EVENT_KIND_AUTOCONFIG_DONE, PE_EVENT_KIND_SIGN_IN_DONE, PE_EVENT_KIND_SIGN_IN_APP_CHECKED:
            Waiting.requestDone(event.uid)
        case PE_EVENT_KIND_NEW_MAIL:
            notifyNewMail(event)
        case PE_EVENT_KIND_UNSUBSCRIBED:
            if let said = mailbox.unsubscribed(event.uid, problem: event.message) {
                setStatus(said)
            }
        case PE_EVENT_KIND_MESSAGE_SENT:
            // shown by the OutboxChanged that follows it
            lastSent = "Sent \(quoted(event.message)) at \(timeNow())"
        case PE_EVENT_KIND_DRAFT_SAVED:
            // the window that saved it says so; one that closed after saving leaves it to the status bar
            if !ComposeWindow.draftSaved(messageId: event.detail, problem: event.message) {
                setStatus(event.message.isEmpty ? "Message saved in Drafts."
                                                : "The message was not saved in Drafts: \(event.message)")
            }
        case PE_EVENT_KIND_OUTBOX_CHANGED:
            showOutbox()
        case PE_EVENT_KIND_AGENT_ASK:
            // after this event, so the question does not hold up the others; with the window it is about in front
            let request = event.uid
            onMain {
                self.show()
                agentQuestion(core: self.core, request: request)
            }
        case PE_EVENT_KIND_AGENT_LOG_CHANGED:
            AgentsWindow.refresh()
        case PE_EVENT_KIND_TRANSFERRING:
            // messages going to another account: how far, then what was done
            setStatus(event.message)
        case PE_EVENT_KIND_FOLDER_CREATED:
            MoveWindow.shown?.folderCreated(event.folder)
        case PE_EVENT_KIND_FAILED:
            failing.insert(event.account)
            setStatus("\(mailbox.accountName(event.account)): \(event.message)")
            if event.failure == PE_FAILURE_KIND_AUTHENTICATION {
                // after this event, so the prompt does not hold up the others
                onMain { self.askPassword(event.account) }
            }
        default:
            break
        }
        mailbox.onEvent(event)
        // the Dock: what is unread in the Inboxes, when a folder changed
        if event.kind == PE_EVENT_KIND_FOLDER_CHANGED || event.kind == PE_EVENT_KIND_SYNC_FINISHED {
            showUnread()
        }
        showCounts()
    }

    private func showUnread() {
        let unread = core.inboxUnread
        NSApp.dockTile.badgeLabel = unread > 0 ? (unread > 999 ? "999+" : "\(unread)") : nil
    }

    // ---- notifications ----

    /// new mail: a notification, unless the window is in front (the list shows it) or notifications are off
    private func notifyNewMail(_ event: CoreEvent) {
        guard AppDelegate.shared.notify else { return }
        if window.isVisible && !window.isMiniaturized && NSApp.isActive && window.isKeyWindow {
            return
        }
        let subject = event.detail.isEmpty ? "(no subject)" : event.detail
        if event.count <= 1 {
            notifyUser(title: event.message, text: subject, folder: event.folder, uid: event.uid)
        } else {
            notifyUser(title: "\(event.count) new messages", text: "The newest from \(event.message): \(subject)",
                       folder: event.folder, uid: event.uid)
        }
    }

    /// a notification of the system; a click on it opens the message (`folder`, `uid`), or the window
    func notifyUser(title: String, text: String, folder: Int64, uid: UInt64) {
        guard AppDelegate.shared.isBundled else { return }
        let center = UNUserNotificationCenter.current()
        center.requestAuthorization(options: [.alert, .sound]) { granted, _ in
            guard granted else { return }
            let content = UNMutableNotificationContent()
            content.title = title
            content.body = text
            content.userInfo = ["folder": folder, "uid": uid]
            center.add(UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil))
        }
    }

    // ---- accounts ----

    /// an account that signs in through the browser signs in again
    private func signInAgain(_ account: Int64) {
        guard ask("The sign-in of \(mailbox.accountName(account)) was refused or ran out.\n\nSign in again in the browser?",
                  style: .information) else { return }
        let request = SignIn.withBrowser(core: core, with: mailbox.signIn(account), email: mailbox.accountEmail(account))
        guard request != 0 else { return }
        var why: UnsafeMutablePointer<CChar>?
        if pe_account_reauthorize(core.handle, account, request, &why) {
            core.sync(account)
            return
        }
        inform("Signing in again did not work: \(taken(why) ?? "unknown reason")", style: .warning)
    }

    private func askPassword(_ account: Int64) {
        guard prompting.insert(account).inserted else { return }
        defer { prompting.remove(account) }
        if mailbox.signIn(account).provider != PE_O_AUTH_PROVIDER_NONE {
            signInAgain(account)
            return
        }
        guard let password = passwordDialog(account: mailbox.accountName(account)) else { return }
        let strings = CStrings()
        pe_account_set_password(core.handle, account, strings.add(password))
        strings.wipe()
        core.sync(account)
    }

    func addAccount() {
        if newAccountDialog(core: core) > 0 {
            mailbox.reload()
            core.syncAll()
        }
    }

    func showAccounts() {
        if accountsDialog(core: core) {
            mailbox.reload()
            core.syncAll()
        }
    }

    func openOutbox() {
        outboxDialog(core: core)
        showOutbox()
    }

    func showAbout() {
        let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? Core.version
        NSApp.orderFrontStandardAboutPanel(options: [
            .applicationName: appName,
            .applicationVersion: version,
            .version: "Core \(Core.version)",
        ])
    }

    // ---- writing ----

    /// a new message from `account`, or from the account of the selected folder when 0
    func newMessage(_ account: Int64 = 0) {
        let account = account != 0 ? account : mailbox.currentAccount
        guard account != 0 else {
            inform("Add a mail account first.")
            return
        }
        ComposeWindow.open(core: core, account: account, draft: nil)
    }

    /// a new message from a mailto: link, from the account of what is shown (the core reads the link)
    func openMailto(_ link: String) {
        guard let draft = link.withCString({ Draft(pe_mailto_draft($0)) }) else { return }
        let account = mailbox.currentAccount
        guard account != 0 else {
            inform("Add a mail account first, then click the e-mail link again.")
            return
        }
        ComposeWindow.open(core: core, account: account, draft: draft)
    }

    func reply(_ kind: PeDraftKind) {
        // several: one new message with them attached
        if kind == PE_DRAFT_KIND_FORWARD && mailbox.selectedCount > 1 {
            mailbox.forwardSelected { [core] draft, account in
                ComposeWindow.open(core: core, account: account, draft: draft)
            }
            return
        }
        guard let draft = mailbox.draftOfShown(kind) else {
            inform("Select a message first.")
            return
        }
        ComposeWindow.open(core: core, account: mailbox.currentAccount, draft: draft)
    }

    func showMessage(folder: Int64, uid: UInt64) {
        mailbox.showMessage(folder: folder, uid: uid)
    }

    func focusFind() {
        show()
        window.makeFirstResponder(searchField)
    }

    /// Tools > Make Default Mail App: the Mac lets an app ask for it, the system asks the user to confirm
    func makeDefaultMailApp() {
        let bundle = Bundle.main.bundleURL
        guard bundle.pathExtension == "app" else {
            inform("This copy of Inbox Classic is not an app bundle, so it can not be the default mail app.")
            return
        }
        if let current = NSWorkspace.shared.urlForApplication(toOpen: URL(string: "mailto:someone@example.com")!),
           current.standardizedFileURL == bundle.standardizedFileURL {
            inform("Inbox Classic is your default mail app: e-mail links open a new message here.")
            return
        }
        NSWorkspace.shared.setDefaultApplication(at: bundle, toOpenURLsWithScheme: "mailto") { error in
            Task { @MainActor in
                if let error {
                    inform("Inbox Classic was not made the default mail app: \(error.localizedDescription)", style: .warning)
                }
            }
        }
    }

    // ---- the toolbar ----

    private enum Item: String, CaseIterable {
        case createMail, reply, replyAll, forward, print, delete, junk, sync, markRead, markUnread, search
    }

    private func command(of item: Item) -> Command? {
        switch item {
        case .createMail: return .newMail
        case .reply: return .reply
        case .replyAll: return .replyAll
        case .forward: return .forward
        case .print: return .print
        case .delete: return .delete
        case .junk: return .junk
        case .sync: return .sync
        case .markRead: return .markRead
        case .markUnread: return .markUnread
        case .search: return nil
        }
    }

    public func toolbarDefaultItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
        let id = { (item: Item) in NSToolbarItem.Identifier(item.rawValue) }
        // in groups as Outlook Express has them: writing, answering, the message, getting mail, read state
        return [id(.createMail), .space, id(.reply), id(.replyAll), id(.forward), .space, id(.print), id(.delete), id(.junk),
                .space, id(.sync), .space, id(.markRead), id(.markUnread), .flexibleSpace, id(.search)]
    }

    public func toolbarAllowedItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
        toolbarDefaultItemIdentifiers(toolbar)
    }

    public func toolbar(_ toolbar: NSToolbar, itemForItemIdentifier identifier: NSToolbarItem.Identifier,
                        willBeInsertedIntoToolbar flag: Bool) -> NSToolbarItem? {
        guard let item = Item(rawValue: identifier.rawValue) else { return nil }
        let labels: [Item: (String, String)] = [
            .createMail: ("Create Mail", "mail_add"), .reply: ("Reply", "arrow_reply"), .replyAll: ("Reply All", "arrow_reply_all"),
            .forward: ("Forward", "arrow_forward"), .print: ("Print", "print"), .delete: ("Delete", "delete"),
            .junk: ("Junk", "mail_prohibited"), .sync: ("Send/Recv", "arrow_sync"), .markRead: ("Mark Read", "mail_read"),
            .markUnread: ("Mark Unread", "mail_unread"),
        ]
        if item == .search {
            let search = NSSearchToolbarItem(itemIdentifier: identifier)
            search.searchField = searchField
            searchField.placeholderString = "Search mail"
            searchField.delegate = self
            searchField.sendsSearchStringImmediately = false
            searchField.sendsWholeSearchString = false
            searchField.target = self
            searchField.action = #selector(searchChanged)
            searchField.toolTip = findTip
            searchField.setAccessibilityIdentifier("find")
            search.preferredWidthForSearchField = 260
            return search
        }
        let (label, icon) = labels[item]!
        let toolbarItem: NSToolbarItem
        if item == .createMail || item == .sync {
            // a menu of the accounts beside it, as Outlook Express has
            let menuItem = NSMenuToolbarItem(itemIdentifier: identifier)
            menuItem.menu = NSMenu()
            menuItem.menu.delegate = self
            menuItem.menu.identifier = NSUserInterfaceItemIdentifier(item.rawValue)
            menuItem.showsIndicator = true
            toolbarItem = menuItem
        } else {
            toolbarItem = NSToolbarItem(itemIdentifier: identifier)
        }
        toolbarItem.label = label
        toolbarItem.paletteLabel = label
        toolbarItem.toolTip = label
        toolbarItem.image = Icons.toolbar(icon)
        toolbarItem.target = self
        toolbarItem.action = #selector(toolbarClicked(_:))
        toolbarItem.isBordered = true
        if item == .junk {
            junkItem = toolbarItem
        }
        return toolbarItem
    }

    @objc private func toolbarClicked(_ sender: NSToolbarItem) {
        guard let item = Item(rawValue: sender.itemIdentifier.rawValue), var command = command(of: item) else { return }
        if item == .junk && mailbox.inJunk {
            command = .notJunk
        }
        AppDelegate.shared.perform(command)
    }

    /// the buttons of one message are off for several (and for none), those of the selection for none
    public func validateToolbarItem(_ item: NSToolbarItem) -> Bool {
        guard let id = Item(rawValue: item.itemIdentifier.rawValue), let command = command(of: id) else { return true }
        switch command {
        case _ where command.needsOne: return mailbox.hasOne
        case _ where command.needsSome: return mailbox.hasSelection
        case .delete, .junk, .markRead, .markUnread: return mailbox.hasSelection
        default: return true
        }
    }

    /// Junk, or Not Junk for a message in a Junk folder
    private func updateJunk() {
        let inJunk = mailbox.inJunk
        junkItem?.label = inJunk ? "Not Junk" : "Junk"
        junkItem?.image = Icons.toolbar(inJunk ? "mail_checkmark" : "mail_prohibited")
    }

    // ---- searching ----

    /// what the search field takes, shown when the mouse rests on it
    private let findTip = """
        Finds words in the subject, the people, the file names and the text of messages.
        "exact phrase"    -leave out    this OR that
        from:ann    to:bob    subject:report    filename:pdf
        is:unread    is:read    is:starred    has:attachment
        in:inbox    in:sent    in:anywhere    in:<folder name>
        before:2025/01/31    after:2025/01/01    older_than:2d    newer_than:1m
        larger:5M    smaller:100k
        """

    private var findTimer: Timer?

    public func controlTextDidChange(_ notification: Notification) {
        // a moment after the last key, not for each
        findTimer?.invalidate()
        findTimer = Timer.scheduledTimer(withTimeInterval: 0.25, repeats: false) { [weak self] _ in
            MainActor.assumeIsolated { self?.searchChanged() }
        }
    }

    @objc private func searchChanged() {
        findTimer?.invalidate()
        mailbox.find(searchField.stringValue)
        showCounts()
    }

    public func control(_ control: NSControl, textView: NSTextView, doCommandBy selector: Selector) -> Bool {
        // Esc: the search ends
        if selector == #selector(NSResponder.cancelOperation(_:)) {
            searchField.stringValue = ""
            searchChanged()
            window.makeFirstResponder(mailbox.list)
            return true
        }
        return false
    }

    /// the search ended from the bar over the list
    func searchCleared() {
        searchField.stringValue = ""
    }
}

// the menus of Create Mail and Send/Recv: a message from one account, or all accounts or one to check
extension MainWindow: NSMenuDelegate {
    public func menuNeedsUpdate(_ menu: NSMenu) {
        let sync = menu.identifier?.rawValue == "sync"
        menu.removeAllItems()
        if sync {
            let all = NSMenuItem(title: "Send and Receive All", action: #selector(accountChosen(_:)), keyEquivalent: "")
            all.target = self
            all.tag = 0
            menu.addItem(all)
            menu.addItem(.separator())
        }
        let accounts = core.accounts()
        for account in accounts {
            let item = NSMenuItem(title: (sync ? "" : "From ") + account.label, action: #selector(accountChosen(_:)),
                                  keyEquivalent: "")
            item.target = self
            item.tag = Int(account.id)
            item.representedObject = sync
            menu.addItem(item)
        }
        if accounts.isEmpty {
            let none = NSMenuItem(title: "No accounts yet", action: nil, keyEquivalent: "")
            none.isEnabled = false
            menu.addItem(none)
        }
    }

    @objc private func accountChosen(_ sender: NSMenuItem) {
        let sync = sender.representedObject as? Bool ?? true
        if sender.tag == 0 {
            core.syncAll()
        } else if sync {
            core.sync(Int64(sender.tag))
        } else {
            newMessage(Int64(sender.tag))
        }
    }
}
