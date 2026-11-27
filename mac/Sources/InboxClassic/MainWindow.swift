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
    private let statusText = NSTextField(labelWithString: Text.uiDone.text)  // as on Windows and Linux, until something happens
    private let outboxText = NSTextField(labelWithString: "")
    private let countsText = NSTextField(labelWithString: "")
    /// takes back the message that waits to be sent (Undo Send), shown while one does
    private let undoSendButton = NSButton(title: Text.uiUndoButton.text, target: nil, action: nil)
    /// counts down the message that waits to be sent, in the core's words, while one does
    private var sendTimer: Timer?
    let searchField = NSSearchField()
    private var syncTimer: Timer?
    /// accounts whose password prompt is open, so a second failure does not open another
    private var prompting: Set<Int64> = []
    /// how many accounts need a sign-in, as last read: the Dock's "!"
    private var needingSignIn: UInt32 = 0
    /// the syncs of each account that came to their end, and (under test) the requests whose event came: what the UI
    /// test waits on
    private(set) var syncsFinished: [Int64: Int] = [:]
    private(set) var requestsDone: Set<UInt64> = []
    /// what the message rules did during a sync, kept in the status bar when the sync finishes
    private var rulesSaid: String?
    /// the last message sent, as the outgoing pane says it once the Outbox is empty
    private var lastSent = ""
    private var junkItem: NSToolbarItem?
    private var unreadOnlyItem: NSToolbarItem?

    init(core: Core) {
        self.core = core
        window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 1100, height: 760),
                          styleMask: [.titled, .closable, .miniaturizable, .resizable], backing: .buffered, defer: false)
        window.autorecalculatesKeyViewLoop = true
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
        mailbox.openDraft = { [weak self] in self?.openDraft($0, account: $1) }
        mailbox.undoSend = { [weak self] in self?.undoSend() }
        mailbox.statusAction = { [weak self] in self?.runStatusAction($0) }
        showOutbox()
        showCounts()
        updateLayout()
        // the timer's syncs leave an account whose sign-in was refused alone for a while; the user's Send/Recv does not
        syncTimer = Timer.scheduledTimer(withTimeInterval: 10 * 60, repeats: true) { [weak self] _ in
            MainActor.assumeIsolated { self?.core.syncScheduled() }
        }
        showUnread()
    }

    private func makeContent() -> NSView {
        undoSendButton.bezelStyle = .inline
        undoSendButton.controlSize = .small
        undoSendButton.font = .systemFont(ofSize: NSFont.smallSystemFontSize)
        undoSendButton.target = self
        undoSendButton.action = #selector(undoSend)
        undoSendButton.setAccessibilityIdentifier("status.undoSend")
        undoSendButton.isHidden = true
        let status = NSStackView(views: [statusText, outboxText, undoSendButton, countsText])
        status.setCustomSpacing(6, after: outboxText)
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
            notifyUser(title: Text.uiStillRunning.text, text: Text.macStillRunningDetail.text, folder: 0, uid: 0)
        }
        return false
    }

    // ---- the layout ----

    /// the window's width tells Automatic which layout; Classic and Columns hold
    public func windowDidResize(_ notification: Notification) {
        updateLayout()
    }

    /// the panes as View > Layout and the window's width say: the core decides, the same way on every platform. The
    /// first time Automatic turns to Columns the status bar says where to change it
    func updateLayout() {
        guard let mode = AppDelegate.shared?.layoutMode else { return }
        let width = UInt32(max(0, window.contentLayoutRect.width))
        let wanted = pe_layout_for(mode, width, mailbox.layout)
        guard wanted != mailbox.layout else { return }
        mailbox.setLayout(wanted)
        if wanted == PE_LAYOUT_COLUMNS && mode == PE_LAYOUT_MODE_AUTOMATIC && !MainWindow.columnsNoteShown {
            MainWindow.columnsNoteShown = true
            setStatus(Text.uiColumnsNote.text)
        }
    }

    /// whether the note of Automatic's columns was shown; kept in memory under test
    private static var noteShown = Preference("ColumnsNoteShown", default: false)
    static var columnsNoteShown: Bool {
        get { noteShown.value }
        set { noteShown.value = newValue }
    }

    // ---- the status bar ----

    /// whether the status bar holds a sync's words ("Checking", "Done", a failure) rather than the answer to something
    /// the user did ("Copied the code", "3 contacts saved to ...", "not in this message"): a sync in the background
    /// replaces only its own words, so the user's answer stays until the user does something else
    private var statusIsSync = true

    /// the answer to something the user did
    func setStatus(_ text: String) {
        statusText.stringValue = text
        statusIsSync = text.isEmpty || text == Text.uiDone.text
    }

    /// a sync's words: shown unless the user's answer is there, or always (`over`: a failure, what the rules did)
    func setSyncStatus(_ text: String, over: Bool = false) {
        guard over || statusIsSync else { return }
        statusText.stringValue = text
        statusIsSync = true
    }

    /// a sync the user asked for: its words replace whatever the status bar said
    func syncAsked() {
        statusIsSync = true
    }

    /// the accounts that need a sign-in or can not connect, in the core's words for the status bar (nil while all are
    /// connected), read again with the Dock's "!"
    @discardableResult
    private func readAccountsStatus() -> String? {
        let summary = core.accountsSummary
        if summary.needing != needingSignIn {
            needingSignIn = summary.needing
            showUnread()
        }
        return summary.text
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
        subject.isEmpty ? Text.uiNoSubject.text : Text.uiQuoted.text(["subject": subject])
    }

    /// the outgoing pane: what is being sent, what waits in the Outbox and why, or the last message sent
    func showOutbox() {
        // a message waiting to be sent says how long, with its Undo
        if showSendWaiting() { return }
        guard let outbox = pe_outbox(core.handle) else { return }
        defer { pe_outbox_free(outbox) }
        let waiting = pe_outbox_count(outbox)
        var said = lastSent
        if waiting > 0, let first = pe_outbox_get(outbox, 0) {
            let subject = text(first.pointee.subject)
            let failed = first.pointee.problem != nil && first.pointee.problem.pointee != 0
            if waiting > 1 {
                said = Text.macOutboxWaiting.text(["count": waiting])
            } else if failed {
                said = Text.uiOutboxWaits.text(["subject": quoted(subject)])
            } else {
                said = Text.macSending.text(["subject": quoted(subject)])
            }
        }
        outboxText.stringValue = said
        outboxText.toolTip = said
    }

    /// the countdown of the message waiting to be sent, with its Undo; false once none waits
    private func showSendWaiting() -> Bool {
        guard sendTimer != nil else { return false }
        guard let said = taken(pe_send_waiting_text(core.handle)) else {
            endSendWaiting()
            return false
        }
        outboxText.stringValue = said
        outboxText.toolTip = said
        undoSendButton.isHidden = false
        return true
    }

    private func endSendWaiting() {
        sendTimer?.invalidate()
        sendTimer = nil
        undoSendButton.isHidden = true
    }

    /// takes back the message that waits to be sent: it opens again as it was, or the status bar says it went
    @objc func undoSend() {
        endSendWaiting()
        var account: Int64 = 0
        var status: UnsafeMutablePointer<CChar>?
        if let draft = Draft(pe_undo_send(core.handle, &account, &status)) {
            ComposeWindow.open(core: core, account: account, draft: draft)
        }
        setStatus(taken(status) ?? "")
        showOutbox()
    }

    // ---- the core's events ----

    func onEvent(_ event: CoreEvent) {
        // a preview's picture drawn: for the web view waiting for it, and nothing else of the windows changed
        if event.kind == PE_EVENT_KIND_PREVIEW_ANSWERED {
            DocumentServer.answered(event.uid, core: core)
            return
        }
        switch event.kind {
        case PE_EVENT_KIND_SYNC_STARTED:
            setSyncStatus(Text.macChecking.text(["account": mailbox.accountName(event.account)]))
        case PE_EVENT_KIND_SYNC_FINISHED:
            syncsFinished[event.account, default: 0] += 1
            // what the rules did; else the accounts that need a sign-in or can not connect, else Done. A failure the
            // sync told stays (it came before this)
            let accounts = readAccountsStatus()
            if let said = rulesSaid ?? accounts {
                setSyncStatus(said, over: true)
            } else if event.failure == PE_FAILURE_KIND_NONE {
                setSyncStatus(Text.uiDone.text)
            }
            rulesSaid = nil
        case PE_EVENT_KIND_ACCOUNT_STATE_CHANGED:
            accountStateChanged(event.account, prompt: event.count == 1)
        case PE_EVENT_KIND_RULES_APPLIED:
            let said = Text.uiRulesApplied.text(["count": event.count])
            setSyncStatus(said, over: true)
            rulesSaid = event.count > 0 ? said : nil
        case PE_EVENT_KIND_AUTOCONFIG_DONE, PE_EVENT_KIND_SIGN_IN_DONE, PE_EVENT_KIND_SIGN_IN_APP_CHECKED:
            if TestHooks.testing {
                requestsDone.insert(event.uid)
            }
            Waiting.requestDone(event.uid)
        case PE_EVENT_KIND_READ_DONE, PE_EVENT_KIND_ACTED:
            Pending.finish(event)
        case PE_EVENT_KIND_NEW_MAIL:
            notifyNewMail(event)
        case PE_EVENT_KIND_LISTS_CHANGED:
            mailbox.reader.listsChanged()
            MessageWindow.listsChanged()
        case PE_EVENT_KIND_UNSUBSCRIBED:
            if let said = mailbox.unsubscribed(event.uid, problem: event.message)
                ?? MessageWindow.unsubscribed(event.uid, problem: event.message) {
                setStatus(said)
            }
        case PE_EVENT_KIND_SEND_WAITING:
            sendTimer?.invalidate()
            sendTimer = Timer(timeInterval: 1, repeats: true) { [weak self] _ in
                MainActor.assumeIsolated { self?.showOutbox() }
            }
            RunLoop.main.add(sendTimer!, forMode: .common)
            showOutbox()
        case PE_EVENT_KIND_MESSAGE_SENT:
            // shown by the OutboxChanged that follows it
            lastSent = Text.uiSentAt.text(["subject": quoted(event.message), "time": timeNow()])
        case PE_EVENT_KIND_DRAFT_SAVED:
            // the window that saved it says so; one that closed after saving leaves it to the status bar
            if !ComposeWindow.draftSaved(messageId: event.detail, problem: event.message) {
                setStatus(event.message.isEmpty ? Text.uiDraftSaved.text
                                                : Text.uiDraftNotSaved.text(["reason": event.message]))
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
            // messages going to another account: how far, then what was done; how far a large message opened is
            setStatus(event.message)
        case PE_EVENT_KIND_FOLDER_CREATED:
            MoveWindow.shown?.folderCreated(event.folder)
        // changed other than through their windows (an import): what shows them read again; the windows of keys,
        // rules, trusted senders and sign-in apps are modal and read theirs when they open
        case PE_EVENT_KIND_ACCOUNTS_CHANGED:
            mailbox.reload()
        case PE_EVENT_KIND_PDF_PREVIEWS_OFF:
            // a PDF file ended the app: the setting shows it off (the documents say why)
            SettingsWindow.current?.refreshPreviews()
        case PE_EVENT_KIND_SETTINGS_CHANGED:
            Preview.dark = core.darkMessages
            TextSize.apply(pe_text_zoom(core.handle))
            reloadMessagesShown()
        case PE_EVENT_KIND_ADDRESS_BOOK_CHANGED:
            AddressBookWindow.refresh()
        case PE_EVENT_KIND_KEYS_CHANGED:
            // what a message shown says of its signature and encryption, a contact's keys, the book's key marks
            reloadMessagesShown()
            ContactKeys.refreshAll()
            AddressBookWindow.refresh()
        case PE_EVENT_KIND_SETTINGS_SYNC_READY:
            SyncEvents.ready(core)
        case PE_EVENT_KIND_SETTINGS_SYNC_CHANGED:
            SyncEvents.changed(core, main: self)
        case PE_EVENT_KIND_KEY_PUBLISHED:
            KeyActions.published(core: core, event.uid)
        case PE_EVENT_KIND_FAILED:
            // the accounts that need a sign-in or can not connect in the core's words; another failure in the server's
            // (the dialog of a refused sign-in comes with AccountStateChanged)
            let said = readAccountsStatus()
                ?? Text.macAccountSaid.text(["account": mailbox.accountName(event.account), "message": event.message])
            setSyncStatus(said, over: true)
        default:
            break
        }
        mailbox.onEvent(event)
        // the messages open in windows of their own
        MessageWindow.onEvent(event)
        // the compose windows: the recipients' keys looked up, or changed
        ComposeWindow.onEvent(event)
        // keys looked up, and learned by the core: a contact window's Find Key says what it found; when keys were
        // learned (`count`), the contact windows and the book's key marks show them
        if event.kind == PE_EVENT_KIND_KEYS_FOUND {
            ContactKeys.keysFound(event.uid, learned: event.count > 0)
            if event.count > 0 {
                AddressBookWindow.refresh()
            }
        }
        // the Dock: what is unread in the Inboxes, when a folder changed
        if event.kind == PE_EVENT_KIND_FOLDER_CHANGED || event.kind == PE_EVENT_KIND_SYNC_FINISHED {
            showUnread()
        }
        showCounts()
    }

    /// the messages shown, in the reading pane and their own windows, made again as the settings and keys have them
    func reloadMessagesShown() {
        mailbox.reader.reload()
        for window in MessageWindow.open {
            window.reader.reload()
        }
    }

    private func showUnread() {
        // an account that needs the user to sign in says so over the count, as the tray's mark does on Windows
        if needingSignIn > 0 {
            NSApp.dockTile.badgeLabel = "!"
            return
        }
        let unread = core.inboxUnread
        NSApp.dockTile.badgeLabel = unread > 0 ? (unread > 999 ? "999+" : "\(unread)") : nil
    }

    /// the badge on the Dock icon now, for the UI test
    var dockBadge: String? { NSApp.dockTile.badgeLabel }

    // ---- whether each account is signed in and can connect ----

    /// what an account shows of its sign-in changed: the status bar, the Dock and the compose windows from it (the
    /// folder list and the bar are the mailbox's); with `prompt` the state's one dialog, or a notification while the
    /// app is in the background
    private func accountStateChanged(_ account: Int64, prompt: Bool) {
        if let said = readAccountsStatus() {
            setSyncStatus(said)
        }
        ComposeWindow.accountStateChanged(account)
        guard prompt else { return }
        let status = core.accountStatus(account)
        // the UI test drives a window that may not be in front: it hears of the notification and gets the dialog
        let inFront = window.isVisible && !window.isMiniaturized && NSApp.isActive && window.isKeyWindow
        if inFront || TestHooks.testing {
            TestHooks.notified?(status.notificationTitle, status.notificationText)
            // after this event, so the dialog does not hold up the others
            onMain { self.ask(account) }
        } else {
            notifyUser(title: status.notificationTitle, text: status.notificationText, info: ["signIn": account])
        }
    }

    /// what the bar's button, the folder list's mark, Sign In Again and the notification do for `account`, as its state
    /// says: sign in again in the browser, the password, the administrator's link, the help, or a sync now
    func runStatusAction(_ account: Int64) {
        let status = core.accountStatus(account)
        switch status.action {
        case PE_STATUS_ACTION_SIGN_IN_AGAIN:
            signInAgain(core: core, account: account, email: mailbox.accountEmail(account))
        case PE_STATUS_ACTION_ENTER_PASSWORD:
            enterPassword(account, hint: status.passwordHint)
        case PE_STATUS_ACTION_COPY_ADMIN_LINK:
            NSPasteboard.general.clearContents()
            NSPasteboard.general.setString(status.adminLink, forType: .string)
            setStatus(Text.accountStateAdminLinkCopied.text)
        case PE_STATUS_ACTION_HELP:
            Help.open(topic: status.helpTopic)
        case PE_STATUS_ACTION_SYNC_NOW:
            syncAsked()
            core.sync(account)
        default:
            break
        }
    }

    /// Tools > Sign In Again: the account the bar over the list speaks for, while it needs a sign-in the user can give
    var signInAgainAccount: Int64? {
        let account = mailbox.barAccount
        guard account != 0, core.accountState(account) != PE_ACCOUNT_STATE_CONNECTED else { return nil }
        return core.accountStatus(account).canSignInAgain ? account : nil
    }

    // ---- notifications ----

    /// new mail: a notification, unless the window is in front (the list shows it) or notifications are off
    private func notifyNewMail(_ event: CoreEvent) {
        guard AppDelegate.shared.notify else { return }
        // the UI test hears of every one, its window in front or not
        if TestHooks.notified == nil && window.isVisible && !window.isMiniaturized && NSApp.isActive && window.isKeyWindow {
            return
        }
        // the core's words: who it is from over its subject, or how many over the newest, a watched conversation's
        // saying so in the title
        notifyUser(title: event.message, text: event.detail, folder: event.folder, uid: event.uid)
    }

    /// a notification of the system; a click on it opens the message (`folder`, `uid`), or the window
    func notifyUser(title: String, text: String, folder: Int64, uid: UInt64) {
        notifyUser(title: title, text: text, info: ["folder": folder, "uid": uid])
    }

    /// `info` tells the click what to open (AppDelegate's userNotificationCenter)
    private func notifyUser(title: String, text: String, info: [String: Any]) {
        TestHooks.notified?(title, text)
        guard AppDelegate.shared.isBundled else { return }
        let center = UNUserNotificationCenter.current()
        nonisolated(unsafe) let info = info
        center.requestAuthorization(options: [.alert, .sound]) { granted, _ in
            guard granted else { return }
            let content = UNMutableNotificationContent()
            content.title = title
            content.body = text
            content.userInfo = info
            center.add(UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil))
        }
    }

    // ---- accounts ----

    /// the one dialog of an account's state (the core asks for it once, when the state comes about): the password,
    /// whether to sign in again in the browser, or what happened with the button that helps. Cancel leaves the folder
    /// list's mark, the bar over the list and the status bar to say it
    private func ask(_ account: Int64) {
        guard prompting.insert(account).inserted else { return }
        defer { prompting.remove(account) }
        let status = core.accountStatus(account)
        switch status.prompt {
        case PE_PROMPT_PASSWORD:
            enterPassword(account, hint: status.passwordHint)
        case PE_PROMPT_BROWSER_SIGN_IN:
            if InboxClassicKit.ask(status.bar, yes: status.button, no: Text.uiCancel.text, style: .information) {
                signInAgain(core: core, account: account, email: mailbox.accountEmail(account))
            }
        case PE_PROMPT_INFORM where !status.button.isEmpty:
            if InboxClassicKit.ask(status.bar, yes: status.button, no: Text.uiOk.text, style: .information) {
                runStatusAction(account)
            }
        case PE_PROMPT_INFORM:
            inform(status.bar)
        default:
            break
        }
    }

    /// the password of `account` asked for with `hint` under it, kept, and the account synced with it
    private func enterPassword(_ account: Int64, hint: String) {
        guard let password = passwordDialog(account: mailbox.accountName(account), hint: hint) else { return }
        let strings = CStrings()
        pe_account_set_password(core.handle, account, strings.add(password))
        strings.wipe()
        syncAsked()
        core.sync(account)
    }

    func addAccount() {
        if newAccountDialog(core: core) > 0 {
            mailbox.reload()
            syncAsked()
            core.syncAll()
        }
    }

    func showAccounts() {
        if accountsDialog(core: core) {
            mailbox.reload()
            syncAsked()
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
            .version: Text.uiAboutCore.text(["version": Core.version]),
        ])
    }

    // ---- writing ----

    /// a new message from `account`, or from the account of the selected folder when 0
    @discardableResult
    func newMessage(_ account: Int64 = 0) -> ComposeWindow? {
        let account = account != 0 ? account : mailbox.currentAccount
        guard account != 0 else {
            inform(Text.uiAddAccountFirst.text)
            return nil
        }
        return ComposeWindow.open(core: core, account: account, draft: nil)
    }

    /// a new message from a mailto: link (the core reads the link), from `account`: the account of the message it came
    /// from, so a message window's Unsubscribe writes from that message's account whatever the main window shows; 0 for
    /// a link from elsewhere, written from the account of what is shown
    func openMailto(_ link: String, account from: Int64 = 0) {
        guard let draft = link.withCString({ Draft(pe_mailto_draft($0)) }) else { return }
        openDraft(draft, account: from)
    }

    /// a new message from `draft`, from `account`: the account of the message it is about (a message window's
    /// Unsubscribe writes from that message's account whatever the main window shows); 0 for the account shown
    func openDraft(_ draft: Draft, account from: Int64) {
        let account = from != 0 ? from : mailbox.currentAccount
        guard account != 0 else {
            inform(Text.uiAddAccountFirstLink.text)
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
        let account = mailbox.currentAccount
        // read and quoted off the window thread: the window opens once the draft is made
        mailbox.reader.startDraft(kind) { [core] draft in
            guard let draft else {
                inform(Text.uiSelectMessageFirst.text)
                return
            }
            ComposeWindow.open(core: core, account: account, draft: draft)
        }
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
            inform(Text.macNotBundle.text)
            return
        }
        if let current = NSWorkspace.shared.urlForApplication(toOpen: URL(string: "mailto:someone@example.com")!),
           current.standardizedFileURL == bundle.standardizedFileURL {
            inform(Text.uiDefaultAppIs.text)
            return
        }
        NSWorkspace.shared.setDefaultApplication(at: bundle, toOpenURLsWithScheme: "mailto") { error in
            Task { @MainActor in
                if let error {
                    inform(Text.macNotMadeDefault.text(["reason": error.localizedDescription]), style: .warning)
                }
            }
        }
    }

    // ---- the toolbar ----

    private enum Item: String, CaseIterable {
        case folderList, createMail, reply, replyAll, forward, print, delete, archive, junk, sync, markRead, markUnread, unreadOnly, search
    }

    private func command(of item: Item) -> Command? {
        switch item {
        case .folderList: return .folderList
        case .createMail: return .newMail
        case .reply: return .reply
        case .replyAll: return .replyAll
        case .forward: return .forward
        case .print: return .print
        case .delete: return .delete
        case .archive: return .archive
        case .junk: return .junk
        case .sync: return .sync
        case .markRead: return .markRead
        case .markUnread: return .markUnread
        case .unreadOnly: return .hideRead
        case .search: return nil
        }
    }

    public func toolbarDefaultItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
        let id = { (item: Item) in NSToolbarItem.Identifier(item.rawValue) }
        // in groups as Outlook Express has them: writing, answering, the message, getting mail, read state
        return [id(.folderList), id(.createMail), .space, id(.reply), id(.replyAll), id(.forward), .space, id(.print), id(.delete), id(.archive), id(.junk),
                .space, id(.sync), .space, id(.markRead), id(.markUnread), .flexibleSpace, id(.unreadOnly), id(.search)]
    }

    public func toolbarAllowedItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
        toolbarDefaultItemIdentifiers(toolbar)
    }

    public func toolbar(_ toolbar: NSToolbar, itemForItemIdentifier identifier: NSToolbarItem.Identifier,
                        willBeInsertedIntoToolbar flag: Bool) -> NSToolbarItem? {
        guard let item = Item(rawValue: identifier.rawValue) else { return nil }
        let labels: [Item: (String, String)] = [
            .createMail: (Text.uiTbCreateMail.text, "mail_add"), .reply: (Text.uiTbReply.text, "arrow_reply"),
            .replyAll: (Text.uiTbReplyAll.text, "arrow_reply_all"), .forward: (Text.uiTbForward.text, "arrow_forward"),
            .print: (Text.uiTbPrint.text, "print"), .delete: (Text.uiTbDelete.text, "delete"),
            .archive: (Text.uiTbArchive.text, "archive"),
            .junk: (Text.uiTbJunk.text, "mail_prohibited"), .sync: (Text.uiTbSync.text, "arrow_sync"),
            .markRead: (Text.uiTbMarkRead.text, "mail_read"), .markUnread: (Text.uiTbMarkUnread.text, "mail_unread"),
        ]
        if item == .search {
            let search = NSSearchToolbarItem(itemIdentifier: identifier)
            search.searchField = searchField
            search.label = Text.macToolSearch.text
            searchField.placeholderString = Text.uiFindHint.text
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
        if item == .folderList {
            // the sidebar button at the toolbar's leading edge, as Mail and Finder have it
            let sidebar = NSToolbarItem(itemIdentifier: identifier)
            sidebar.label = Text.uiFolders.text
            sidebar.paletteLabel = sidebar.label
            sidebar.toolTip = Command.folderList.label
            sidebar.image = NSImage(systemSymbolName: "sidebar.leading", accessibilityDescription: Command.folderList.label)
            sidebar.target = self
            sidebar.action = #selector(toolbarClicked(_:))
            sidebar.isBordered = true
            return sidebar
        }
        if item == .unreadOnly {
            // the list's filter, as Mail has it beside its search: filled while on
            let filter = NSToolbarItem(itemIdentifier: identifier)
            filter.label = Text.uiToolUnreadOnly.text
            filter.paletteLabel = filter.label
            filter.toolTip = Command.hideRead.label
            filter.target = self
            filter.action = #selector(toolbarClicked(_:))
            filter.isBordered = true
            unreadOnlyItem = filter
            unreadOnlyChanged()
            return filter
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
        case .archive: return mailbox.canArchive
        case _ where Mailbox.needsBody.contains(command) && mailbox.shownFailed: return false
        case _ where command.needsOne: return mailbox.hasOne
        case _ where command.needsSome: return mailbox.hasSelection
        default: return true
        }
    }

    /// the Unread filter drawn on or off, as View > Hide Read Messages is
    func unreadOnlyChanged() {
        let on = AppDelegate.shared?.hideRead ?? false
        let name = on ? "line.3.horizontal.decrease.circle.fill" : "line.3.horizontal.decrease.circle"
        var image = NSImage(systemSymbolName: name, accessibilityDescription: Text.uiToolUnreadOnly.text)
        if on {
            // in the accent colour while on, as Mail's filter button: the lines white in the filled circle
            image = image?.withSymbolConfiguration(.init(paletteColors: [.white, .controlAccentColor]))
        }
        unreadOnlyItem?.image = image
    }

    /// Junk, or Not Junk for a message in a Junk folder
    private func updateJunk() {
        let inJunk = mailbox.inJunk
        junkItem?.label = inJunk ? Text.uiTbNotJunk.text : Text.uiTbJunk.text
        junkItem?.image = Icons.toolbar(inJunk ? "mail_checkmark" : "mail_prohibited")
    }

    // ---- searching ----

    /// what the search field takes, shown when the mouse rests on it
    private let findTip = Text.uiFindTip.text + "\n" + """
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
            MainActor.assumeIsolated {
                // not while an input method composes (Japanese, Chinese, Korean): its confirmed text changes the
                // field again, and that is searched
                if let editor = self?.searchField.currentEditor() as? NSTextView, editor.hasMarkedText() { return }
                self?.searchChanged()
            }
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

    /// `words` in the search box, searched for (a rule's Show)
    func search(for words: String) {
        show()
        searchField.stringValue = words
        searchChanged()
        window.makeFirstResponder(searchField)
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
            let all = NSMenuItem(title: Text.cmdSync.text, action: #selector(accountChosen(_:)), keyEquivalent: "")
            all.target = self
            all.tag = 0
            menu.addItem(all)
            menu.addItem(.separator())
        }
        let accounts = core.accounts()
        for account in accounts {
            let item = NSMenuItem(title: sync ? account.label : Text.uiFromAccount.text(["account": account.label]),
                                  action: #selector(accountChosen(_:)),
                                  keyEquivalent: "")
            item.target = self
            item.tag = Int(account.id)
            item.representedObject = sync
            menu.addItem(item)
        }
        if accounts.isEmpty {
            let none = NSMenuItem(title: Text.trayNoAccounts.text, action: nil, keyEquivalent: "")
            none.isEnabled = false
            menu.addItem(none)
        }
    }

    @objc private func accountChosen(_ sender: NSMenuItem) {
        let sync = sender.representedObject as? Bool ?? true
        if sender.tag == 0 {
            syncAsked()
            core.syncAll()
        } else if sync {
            syncAsked()
            core.sync(Int64(sender.tag))
        } else {
            newMessage(Int64(sender.tag))
        }
    }
}
