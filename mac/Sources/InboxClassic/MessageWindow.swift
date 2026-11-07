// A message in a window of its own, as Outlook Express opens one with a double-click or Enter: a Reader (Reader.swift),
// the same as the main window's reading pane, under a toolbar of the message's actions, with Previous and Next through
// the list it was opened from. Several can be open at once; the core's events reach each of them.
import AppKit
import CInboxClassic

/// The window of a message: Esc closes it, as Cmd+W does
final class MessageFrame: NSWindow {
    override func cancelOperation(_ sender: Any?) {
        performClose(sender)
    }

    // the web view of the message takes the keys it is given, Esc among them: the window has it first, after the
    // find bar, whose Esc closes the bar
    override func performKeyEquivalent(with event: NSEvent) -> Bool {
        if super.performKeyEquivalent(with: event) {
            return true
        }
        if event.keyCode == 53 && event.modifierFlags.intersection([.command, .control, .option, .shift]).isEmpty {
            performClose(nil)
            return true
        }
        return false
    }
}

@MainActor
final class MessageWindow: NSObject, NSWindowDelegate, NSToolbarDelegate, NSToolbarItemValidation {
    /// the message windows open now
    private(set) static var open: [MessageWindow] = []
    let core: Core
    let window: MessageFrame
    let reader: Reader
    private weak var mailbox: Mailbox?
    /// the list it was opened from, as it was then, one row a message: what Previous and Next go through
    private let listView: ListView?
    /// the folder that list showed (0 for All Inboxes)
    private let listFolder: Int64
    /// the message shown
    private(set) var folder: Int64 = 0
    private(set) var uid: UInt64 = 0
    /// the messages before and after it in that list, found when it is shown (before it is marked read, which may take
    /// it out of a list of unread messages)
    private var previous: (folder: Int64, uid: UInt64)?
    private var next: (folder: Int64, uid: UInt64)?
    /// the message in numbers, as the core's actions see it (in Junk, can be archived, deleted for good)
    private var summary = PeSelectionSummary()
    private var junkItem: NSToolbarItem?

    /// opens the message `uid` of `folder` of the list of `mailbox` in a window, or brings its window to the front
    @discardableResult
    static func open(core: Core, mailbox: Mailbox, folder: Int64, uid: UInt64) -> MessageWindow {
        if let shown = open.first(where: { $0.folder == folder && $0.uid == uid }) {
            shown.window.makeKeyAndOrderFront(nil)
            return shown
        }
        let made = MessageWindow(core: core, mailbox: mailbox)
        // each a little below and to the right of the one opened before
        if let last = open.last?.window {
            made.window.setFrameTopLeftPoint(made.window.cascadeTopLeft(from: NSPoint(x: last.frame.minX, y: last.frame.maxY)))
        } else if TestHooks.testing || !made.window.setFrameUsingName("Message") {
            made.window.center()
        }
        open.append(made)
        made.show(folder: folder, uid: uid)
        made.window.makeKeyAndOrderFront(nil)
        return made
    }

    /// the message window in front, which the menu commands act on
    static var key: MessageWindow? { open.first { $0.window.isKeyWindow } }

    /// the core's events: for the message each window shows
    static func onEvent(_ event: CoreEvent) {
        for shown in open {
            shown.onEvent(event)
        }
    }

    /// the answer to a one-click unsubscribe one of the windows asked for, in words
    static func unsubscribed(_ request: UInt64, problem: String) -> String? {
        open.lazy.compactMap { $0.reader.unsubscribed(request, problem: problem) }.first
    }

    private init(core: Core, mailbox: Mailbox) {
        self.core = core
        self.mailbox = mailbox
        listView = mailbox.listCopy()
        listFolder = mailbox.folder
        reader = Reader(core: core)
        window = MessageFrame(contentRect: NSRect(x: 0, y: 0, width: 820, height: 680),
                              styleMask: [.titled, .closable, .miniaturizable, .resizable], backing: .buffered, defer: false)
        super.init()
        window.identifier = NSUserInterfaceItemIdentifier("message")
        window.isReleasedWhenClosed = false
        window.tabbingMode = .disallowed
        window.minSize = NSSize(width: 520, height: 360)
        window.delegate = self
        if !TestHooks.testing {
            window.setFrameAutosaveName("Message")
        }
        let toolbar = NSToolbar(identifier: "Message")
        toolbar.delegate = self
        toolbar.displayMode = .iconAndLabel
        toolbar.allowsUserCustomization = false
        window.toolbar = toolbar
        window.toolbarStyle = .expanded
        window.contentView = reader.view
        reader.status = { [weak mailbox] in mailbox?.status($0) }
        reader.openMailto = { [weak mailbox] in mailbox?.openMailto($0) }
        // the message that bounced, in the main window
        reader.bouncedHandler = { [weak mailbox] folder, uid in
            AppDelegate.shared?.main?.show()
            mailbox?.showMessage(folder: folder, uid: uid)
        }
        reader.shownHandler = { [weak self] in
            guard let self else { return }
            showTitle(reader.subject)
            window.toolbar?.validateVisibleItems()
        }
    }

    // ---- the message shown ----

    /// shows the message `uid` of `folder`, marked read, as opening it in Outlook Express does
    private func show(folder id: Int64, uid message: UInt64) {
        folder = id
        uid = message
        let row = self.row(folder: id, uid: message)
        showTitle(row?.subject ?? "")
        // under the subject the folder it is in, as the main window has its folder over the app's name
        window.subtitle = mailbox?.folderName(id) ?? ""
        // the pair of the message before is not this one's
        previous = nil
        next = nil
        findNeighbours()
        updateSummary()
        reader.open(folder: id, uid: message, account: mailbox?.folderAccount(id) ?? 0, row: row)
        if row?.seen != true {
            pe_message_set_seen(core.handle, id, message, true)
        }
        window.toolbar?.validateVisibleItems()
    }

    private func showTitle(_ subject: String) {
        window.title = subject.isEmpty ? Text.uiNoSubject.text : subject
    }

    /// the row of the message in the list it was opened from, for its header before the message is here
    private func row(folder id: Int64, uid message: UInt64) -> Message? {
        guard let listView else { return nil }
        let index = core.messageIndex(listView, folder: id, uid: message)
        guard index >= 0 else { return nil }
        return core.messages(listView, offset: UInt64(index), limit: 1)
            .first { $0.folder == id && $0.uid == message }
    }

    /// a message no longer in the list (read out of a list of unread ones) keeps the neighbours it had
    private func findNeighbours() {
        guard let listView, let found = core.neighbours(listView, folder: folder, uid: uid) else { return }
        (previous, next) = found
    }

    /// whether the list the window came from can have messages of the folder `id`: its own folder, any Inbox for All
    /// Inboxes, any folder for a search
    private func listHas(_ id: Int64) -> Bool {
        guard let listView else { return id == folder }
        if listView.searching { return true }
        if listView.severalFolders { return mailbox?.isInbox(id) ?? true }
        return id == listFolder || id == folder
    }

    /// the message as a selection of one, for the core's actions; freed by the caller
    private func selection() -> OpaquePointer {
        newSelection([(folder, uid)])
    }

    private func updateSummary() {
        let one = selection()
        defer { pe_selection_free(one) }
        summary = PeSelectionSummary()
        _ = pe_selection_summary(core.handle, one, &summary)
        junkItem?.label = summary.in_junk ? Text.uiTbNotJunk.text : Text.uiTbJunk.text
        junkItem?.toolTip = junkItem?.label
        junkItem?.image = Icons.toolbar(summary.in_junk ? "mail_checkmark" : "mail_prohibited")
    }

    private func onEvent(_ event: CoreEvent) {
        reader.onEvent(event)
        let changed = event.kind == PE_EVENT_KIND_FOLDER_CHANGED && listHas(event.folder)
            || event.kind == PE_EVENT_KIND_FOLDERS_CHANGED
        guard changed, uid != 0 else { return }
        // gone from its folder some other way (another window, the server): the window goes with it
        if !core.messageExists(folder: folder, uid: uid) {
            window.close()
            return
        }
        // the list changed around it
        findNeighbours()
        updateSummary()
        window.toolbar?.validateVisibleItems()
    }

    // ---- what it does ----

    /// what the menus do with this window in front; false for a command that is not about the message
    func perform(_ command: Command) -> Bool {
        switch command {
        case .reply: reply(PE_DRAFT_KIND_REPLY)
        case .replyAll: reply(PE_DRAFT_KIND_REPLY_ALL)
        case .forward: reply(PE_DRAFT_KIND_FORWARD)
        case .print: reader.print()
        case .delete: delete()
        case .archive: if summary.archivable { remove(PE_ACTION_ARCHIVE) }
        case .junk: remove(PE_ACTION_JUNK)
        case .notJunk: remove(PE_ACTION_NOT_JUNK)
        case .markRead: act(PE_ACTION_READ)
        case .markUnread: act(PE_ACTION_UNREAD)
        case .flag: act(PE_ACTION_TOGGLE_FLAG)
        case .watchConversation: act(PE_ACTION_WATCH)
        case .ignoreConversation: act(PE_ACTION_IGNORE)
        case .pictures: reader.loadPictures()
        case .nextMessage: goNext()
        case .previousMessage: goPrevious()
        case .nextUnread: nextUnread()
        case .findInMessage: reader.findCommand()
        case .saveAs: mailbox?.saveMessageAs(folder: folder, uid: uid)
        case .properties: mailbox?.showProperties(folder: folder, uid: uid, subject: reader.subject)
        case .viewSource: mailbox?.showSource(folder: folder, uid: uid)
        case .addSenderToBook: mailbox?.status(addSenderToAddressBook(core: core, folder: folder, uid: uid))
        default: return false
        }
        return true
    }

    /// whether a command of the menus is on with this window in front; nil for one that is not about the message
    func validate(_ command: Command) -> Bool? {
        let shown = reader.messageView != nil
        switch command {
        case .reply, .replyAll, .forward, .print: return shown
        case .delete, .markRead, .markUnread, .flag, .saveAs, .properties, .viewSource, .addSenderToBook,
             .watchConversation, .ignoreConversation: return true
        case .archive: return summary.archivable
        case .junk: return !summary.in_junk
        case .notJunk: return summary.in_junk
        case .pictures: return reader.picturesBlocked
        case .nextMessage: return next != nil
        case .previousMessage: return previous != nil
        case .nextUnread: return true
        case .findInMessage: return shown
        // the commands of the main window's selection are not this window's
        case .move, .copy, .selectAll: return false
        default: return nil
        }
    }

    /// a flag in a colour (1 red to 7 gray), or none (0)
    func flag(color: UInt8) {
        act(color == 0 ? PE_ACTION_UNFLAG : PE_ACTION_FLAG_COLOR, to: Int64(color))
    }

    var flagColor: UInt8 { summary.flag_color }
    /// what the menus know of the message: its conversation watched or ignored, for their check marks
    var selectionSummary: PeSelectionSummary { summary }
    var flagged: Bool { summary.flagged > 0 }

    private func reply(_ kind: PeDraftKind) {
        guard let draft = reader.draft(kind) else { return }
        ComposeWindow.open(core: core, account: mailbox?.folderAccount(folder) ?? 0, draft: draft)
    }

    /// `action` on the message, what was done in the main window's status bar, or why not
    @discardableResult
    private func act(_ action: PeAction, to: Int64 = 0) -> Bool {
        let one = selection()
        defer { pe_selection_free(one) }
        switch core.act(one, action, to: to) {
        case .success(let done):
            mailbox?.status(done)
            updateSummary()
            return true
        case .failure(let refusal):
            inform(refusal.reason, style: .warning)
            return false
        }
    }

    private func delete() {
        // from Deleted Items, or an account without one, it is gone for good: asked first
        if let question = taken(pe_selection_delete_question(&summary)),
           !ask(question, yes: Text.uiTbDelete.text, no: Text.uiCancel.text, destructive: true) {
            return
        }
        remove(PE_ACTION_DELETE)
    }

    /// `action` takes the message out of its folder: the next one of the list shown then (the one before at the end),
    /// or the window closes when none is left
    private func remove(_ action: PeAction) {
        let after = next ?? previous
        guard act(action) else { return }
        guard let after else {
            window.close()
            return
        }
        show(folder: after.folder, uid: after.uid)
    }

    /// the next unread message of the list it came from; none left is said in the status bar
    private func nextUnread() {
        guard let listView, case .message(let next, let message) = core.nextUnread(listView, folder: folder, uid: uid) else {
            mailbox?.status(Text.noUnreadLeft.text)
            return
        }
        show(folder: next, uid: message)
    }

    @objc private func goPrevious() {
        if let previous {
            show(folder: previous.folder, uid: previous.uid)
        }
    }

    @objc private func goNext() {
        if let next {
            show(folder: next.folder, uid: next.uid)
        }
    }

    // ---- closing ----

    func windowWillClose(_ notification: Notification) {
        reader.clear(loading: false)
        MessageWindow.open.removeAll { $0 === self }
        // back to the main window when no other window takes the keys
        if NSApp.keyWindow == nil || NSApp.keyWindow === window {
            AppDelegate.shared?.main?.window.makeKeyAndOrderFront(nil)
        }
    }

    // ---- the toolbar ----

    private enum Item: String, CaseIterable {
        case reply, replyAll, forward, print, delete, archive, junk, previous, next
    }

    func toolbarDefaultItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
        let id = { (item: Item) in NSToolbarItem.Identifier(item.rawValue) }
        // as the main window groups them: answering, the message, then moving through the list
        return [id(.reply), id(.replyAll), id(.forward), .space, id(.print), id(.delete), id(.archive), id(.junk), .space,
                id(.previous), id(.next)]
    }

    func toolbarAllowedItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
        toolbarDefaultItemIdentifiers(toolbar)
    }

    func toolbar(_ toolbar: NSToolbar, itemForItemIdentifier identifier: NSToolbarItem.Identifier,
                 willBeInsertedIntoToolbar flag: Bool) -> NSToolbarItem? {
        guard let item = Item(rawValue: identifier.rawValue) else { return nil }
        let labels: [Item: (String, String, String)] = [
            .reply: (Text.uiTbReply.text, "arrow_reply", Text.uiTbReply.text),
            .replyAll: (Text.uiTbReplyAll.text, "arrow_reply_all", Text.uiTbReplyAll.text),
            .forward: (Text.uiTbForward.text, "arrow_forward", Text.uiTbForward.text),
            .print: (Text.uiTbPrint.text, "print", Text.uiTbPrint.text),
            .delete: (Text.uiTbDelete.text, "delete", Text.uiTbDelete.text),
            .archive: (Text.uiTbArchive.text, "archive", Text.uiTbArchive.text),
            .junk: (Text.uiTbJunk.text, "mail_prohibited", Text.uiTbJunk.text),
            .previous: (Text.uiTbPrevious.text, "arrow_up", Text.uiPreviousTip.text),
            .next: (Text.uiTbNext.text, "arrow_down", Text.uiNextTip.text),
        ]
        let (label, icon, tip) = labels[item]!
        let toolbarItem = NSToolbarItem(itemIdentifier: identifier)
        toolbarItem.label = label
        toolbarItem.paletteLabel = label
        toolbarItem.toolTip = tip
        toolbarItem.image = Icons.toolbar(icon)
        toolbarItem.target = self
        toolbarItem.action = #selector(toolbarClicked(_:))
        toolbarItem.isBordered = true
        if item == .junk {
            junkItem = toolbarItem
            updateSummary()
        }
        return toolbarItem
    }

    @objc private func toolbarClicked(_ sender: NSToolbarItem) {
        guard let item = Item(rawValue: sender.itemIdentifier.rawValue) else { return }
        switch item {
        case .reply: _ = perform(.reply)
        case .replyAll: _ = perform(.replyAll)
        case .forward: _ = perform(.forward)
        case .print: _ = perform(.print)
        case .delete: _ = perform(.delete)
        case .archive: _ = perform(.archive)
        case .junk: _ = perform(summary.in_junk ? .notJunk : .junk)
        case .previous: goPrevious()
        case .next: goNext()
        }
    }

    func validateToolbarItem(_ item: NSToolbarItem) -> Bool {
        switch Item(rawValue: item.itemIdentifier.rawValue) {
        case .reply: return validate(.reply) ?? true
        case .replyAll: return validate(.replyAll) ?? true
        case .forward: return validate(.forward) ?? true
        case .print: return validate(.print) ?? true
        case .archive: return summary.archivable
        case .previous: return previous != nil
        case .next: return next != nil
        default: return uid != 0
        }
    }

    /// the UI test presses the buttons as a click does
    func press(_ name: String) {
        guard let item = window.toolbar?.items.first(where: { $0.itemIdentifier.rawValue == name }) else { return }
        toolbarClicked(item)
    }
}
