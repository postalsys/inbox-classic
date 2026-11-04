// The folder tree, the message list and the reading pane. The list is virtual: rows come from the core a page at a
// time as the table asks for them. Every string shown was decoded by the core; the message body is the sanitized
// document the core made, shown in the web view as it is.
import AppKit
import CInboxClassic

/// The pasteboard type of a message dragged from the list onto a folder: "<folder> <uid>"
let messagePasteboardType = NSPasteboard.PasteboardType("com.inboxclassic.message")

@MainActor
public final class Mailbox: NSObject {
    let core: Core
    let view: NSSplitView
    let tree = FolderOutline()
    public let list = MessageTable()
    let reader: Reader
    private let listArea = NSView()
    private let searchBar = InfoBar(icon: "search", link: "Clear search")
    private let emptyTitle = NSTextField(labelWithString: "")
    private let emptyMore = NSTextField(wrappingLabelWithString: "")
    private let rightSplit = NSSplitView()

    /// the counts or the folder changed (the main window shows them)
    var changed: () -> Void = {}
    /// another message or folder is selected (Junk or Not Junk)
    var selectionChanged: () -> Void = {}
    /// a line for the status bar
    var status: (String) -> Void = { _ in }
    /// a mailto: link to write (a mailing list's unsubscribe address)
    var openMailto: (String) -> Void = { _ in }

    // the folder tree
    private var accounts: [AccountNode] = []
    private var folderNodes: [Int64: FolderNode] = [:]
    private var accountInfo: [Int64: Account] = [:]
    private var firstAccount: Int64 = 0
    private var reloading = false

    // the list: the folder or the search, its order and its rows
    private(set) var folder: Int64 = 0
    private var selectedAccount: Int64 = 0
    private var sort = PE_SORT_FIELD_DATE
    private var ascending = false
    private var findText = ""
    private var findPlace = ""
    private(set) var total: UInt64 = 0
    private var unread: UInt64 = 0
    private var pages: [(offset: UInt64, rows: [Message])] = []
    private let pageSize: UInt64 = 100
    private var folderColumn = false

    // the message shown
    private var messageFolder: Int64 = 0
    private var uid: UInt64 = 0
    private var messageView: MessageView?
    private var viewRequest: UInt64 = 0
    private var remoteImages = false
    private var openWhenReady = false
    private var markReadTimer: Timer?
    private var reloadTimer: Timer?
    private var logoRequest: UInt64 = 0
    private var unsubscribeRequest: UInt64 = 0

    init(core: Core) {
        self.core = core
        view = NSSplitView()
        reader = Reader()
        super.init()
        view.isVertical = true
        view.dividerStyle = .thin
        view.autosaveName = TestHooks.testing ? nil : "Panes"
        rightSplit.isVertical = false
        rightSplit.dividerStyle = .thin
        rightSplit.autosaveName = TestHooks.testing ? nil : "ListAndReader"

        tree.dataSource = self
        tree.delegate = self
        tree.mailbox = self
        let treeScroll = scrolled(tree)
        treeScroll.widthAnchor.constraint(greaterThanOrEqualToConstant: Mailbox.smallestTree).isActive = true

        setUpList()
        let listScroll = scrolled(list)
        listArea.addSubview(searchBar)
        listArea.addSubview(listScroll)
        searchBar.translatesAutoresizingMaskIntoConstraints = false
        listScroll.translatesAutoresizingMaskIntoConstraints = false
        searchBar.isHidden = true
        searchBar.clicked = { [weak self] in self?.clearFind() }
        searchBar.setAccessibilityIdentifier("search.bar")
        let barHeight = searchBar.heightAnchor.constraint(equalToConstant: 0)
        searchBar.heightConstraint = barHeight
        NSLayoutConstraint.activate([
            searchBar.topAnchor.constraint(equalTo: listArea.topAnchor),
            searchBar.leadingAnchor.constraint(equalTo: listArea.leadingAnchor),
            searchBar.trailingAnchor.constraint(equalTo: listArea.trailingAnchor),
            barHeight,
            listScroll.topAnchor.constraint(equalTo: searchBar.bottomAnchor),
            listScroll.leadingAnchor.constraint(equalTo: listArea.leadingAnchor),
            listScroll.trailingAnchor.constraint(equalTo: listArea.trailingAnchor),
            listScroll.bottomAnchor.constraint(equalTo: listArea.bottomAnchor),
        ])
        setUpEmptyText(in: listScroll)
        listArea.heightAnchor.constraint(greaterThanOrEqualToConstant: Mailbox.smallestList).isActive = true

        reader.mailbox = self
        reader.view.heightAnchor.constraint(greaterThanOrEqualToConstant: 120).isActive = true
        rightSplit.addArrangedSubview(listArea)
        rightSplit.addArrangedSubview(reader.view)
        view.addArrangedSubview(treeScroll)
        view.addArrangedSubview(rightSplit)
        view.setHoldingPriority(.defaultLow + 10, forSubviewAt: 0)
        rightSplit.setHoldingPriority(.defaultLow + 10, forSubviewAt: 0)
        clearReader()
        reload()
    }

    /// the sizes the Windows app starts with (the tree 210 wide, the list 260 high), unless the user moved the dividers
    /// there before. A pane at its smallest is taken as not chosen: the split views put the panes there when they are
    /// laid out before the window has its size, and remember it. Only once the window is laid out, or the positions
    /// would not hold
    func placeDividers() {
        view.layoutSubtreeIfNeeded()
        guard view.bounds.width > 400, rightSplit.bounds.height > 300 else {
            // not laid out yet: once it is
            after(0.1) { [weak self] in self?.placeDividers() }
            return
        }
        let tree = view.arrangedSubviews[0].frame.width
        if TestHooks.testing || tree <= Mailbox.smallestTree + 1 {
            view.setPosition(210, ofDividerAt: 0)
        }
        let list = rightSplit.arrangedSubviews[0].frame.height
        if TestHooks.testing || list <= Mailbox.smallestList + 1 {
            rightSplit.setPosition(260, ofDividerAt: 0)
        }
    }

    /// the smallest the folder tree and the message list can be made
    private static let smallestTree: CGFloat = 160
    private static let smallestList: CGFloat = 80

    private func scrolled(_ document: NSView) -> NSScrollView {
        let scroll = NSScrollView()
        scroll.documentView = document
        scroll.hasVerticalScroller = true
        scroll.hasHorizontalScroller = false
        scroll.autohidesScrollers = true
        return scroll
    }

    // ---- the folder tree ----

    final class AccountNode {
        let account: Account
        var children: [FolderNode] = []
        init(_ account: Account) { self.account = account }
    }

    final class FolderNode {
        var folder: Folder
        var children: [FolderNode] = []
        init(_ folder: Folder) { self.folder = folder }
    }

    public func reload() {
        let selected = folder
        accounts = []
        folderNodes = [:]
        accountInfo = [:]
        firstAccount = 0
        for account in core.accounts() {
            accountInfo[account.id] = account
            if firstAccount == 0 { firstAccount = account.id }
            let node = AccountNode(account)
            // the last folder at each depth, the parent of the next deeper one
            var parents: [FolderNode] = []
            for folder in core.folders(account.id) {
                let item = FolderNode(folder)
                folderNodes[folder.id] = item
                let depth = min(folder.depth, parents.count)
                if depth == 0 {
                    node.children.append(item)
                } else {
                    parents[depth - 1].children.append(item)
                }
                parents = Array(parents.prefix(depth)) + [item]
            }
            accounts.append(node)
        }
        reloading = true
        tree.reloadData()
        accounts.forEach { tree.expandItem($0, expandChildren: true) }
        if let node = folderNodes[selected] {
            let row = tree.row(forItem: node)
            if row >= 0 { tree.selectRowIndexes(IndexSet(integer: row), byExtendingSelection: false) }
        }
        reloading = false
        if selected != 0 && folderNodes[selected] == nil {
            // the folder is gone
            folderSelected(0)
        }
        changed()
    }

    /// the labels of the folders of an account; a folder the tree does not have yet builds it again
    private func updateFolders(_ account: Int64) {
        for folder in core.folders(account) {
            guard let node = folderNodes[folder.id] else {
                reload()
                return
            }
            node.folder = folder
            tree.reloadItem(node)
        }
    }

    func accountName(_ account: Int64) -> String {
        accountInfo[account]?.name ?? "the account"
    }

    func accountEmail(_ account: Int64) -> String {
        accountInfo[account]?.email ?? ""
    }

    func signIn(_ account: Int64) -> SignInChoice {
        guard let info = accountInfo[account] else { return SignInChoice() }
        return SignInChoice(provider: info.oauth, app: info.app)
    }

    /// the account of the message shown (in a search of every folder, not the selected folder's), else of the folder
    var currentAccount: Int64 {
        if let node = folderNodes[messageFolder != 0 ? messageFolder : folder] {
            return node.folder.account
        }
        return selectedAccount != 0 ? selectedAccount : firstAccount
    }

    fileprivate func folderSelected(_ id: Int64) {
        guard id != folder else {
            changed()
            return
        }
        // the message of the folder before is not this folder's, nor is the search
        folder = id
        resetFind()
        clearReader()
        reloadList(keepSelection: false)
        changed()
        selectionChanged()
    }

    var selectedName: String {
        if searching {
            // where the search looks; what it found is on the search bar
            return findPlace.isEmpty ? "All folders" : findPlace
        }
        if let node = folderNodes[folder] {
            return node.folder.displayName
        }
        return accountInfo[selectedAccount]?.name ?? ""
    }

    var counts: String {
        if searching && total == 0 { return "No messages found" }
        if searching { return "\(total) found, \(unread) unread" }
        if folder == 0 { return "" }
        return "\(total) message(s), \(unread) unread"
    }

    var inJunk: Bool {
        folderNodes[uid != 0 ? messageFolder : folder]?.folder.specialUse == PE_SPECIAL_USE_JUNK
    }

    var hasSelection: Bool { uid != 0 }

    var picturesBlocked: Bool { uid != 0 && messageView != nil && !remoteImages && reader.picturesOffered }

    // ---- the message list ----

    private var searching: Bool { !findText.isEmpty }

    /// words typed search every folder of every account (in: narrows that); without, the list is the folder's
    private var search: Search {
        Search(folder: searching ? 0 : folder, text: findText)
    }

    private enum ColumnID: String, CaseIterable {
        case read, attach, flag, from, subject, received, size, folder
    }

    private func setUpList() {
        list.dataSource = self
        list.delegate = self
        list.mailbox = self
        list.usesAlternatingRowBackgroundColors = true
        list.allowsMultipleSelection = false
        list.allowsColumnReordering = false
        list.rowHeight = 20
        list.style = .fullWidth
        list.target = self
        list.doubleAction = #selector(openSelected)
        list.setAccessibilityIdentifier("list")
        list.registerForDraggedTypes([])
        list.setDraggingSourceOperationMask([.move, .copy], forLocal: true)
        let columns: [(ColumnID, String, CGFloat)] = [
            (.read, "", 22), (.attach, "", 22), (.flag, "", 22), (.from, "From", 180), (.subject, "Subject", 320),
            (.received, "Received", 130), (.size, "Size", 84),
        ]
        for (id, title, width) in columns {
            list.addTableColumn(makeColumn(id, title: title, width: width))
        }
        // the paper clip and the flag in their headers, as Outlook Express has them
        list.tableColumn(withIdentifier: NSUserInterfaceItemIdentifier("attach"))?.headerCell.image = Icons.list("attach")
        list.tableColumn(withIdentifier: NSUserInterfaceItemIdentifier("flag"))?.headerCell.image = Icons.list("flag")
        showSortIndicator()
    }

    private func makeColumn(_ id: ColumnID, title: String, width: CGFloat) -> NSTableColumn {
        let column = NSTableColumn(identifier: NSUserInterfaceItemIdentifier(id.rawValue))
        column.title = title
        column.width = width
        if [.read, .attach, .flag].contains(id) {
            column.minWidth = width
            column.maxWidth = width
            column.resizingMask = []
        } else {
            column.minWidth = 40
        }
        if id == .size {
            column.headerCell.alignment = .right
        }
        return column
    }

    /// the Folder column while the list has messages of several folders, and not otherwise
    private func showFolderColumn() {
        guard searching != folderColumn else { return }
        folderColumn = searching
        // the Subject column gives the Folder column its room, and gets it back: the list stays as wide as its pane
        let id = NSUserInterfaceItemIdentifier(ColumnID.folder.rawValue)
        let subject = list.tableColumn(withIdentifier: NSUserInterfaceItemIdentifier(ColumnID.subject.rawValue))
        if folderColumn {
            let column = makeColumn(.folder, title: "Folder", width: 130)
            subject.map { $0.width = max(120, $0.width - column.width) }
            list.addTableColumn(column)
            // after Subject, before Received, as the Windows list has it at its end
            if let at = list.tableColumns.firstIndex(of: column),
               let received = list.tableColumns.firstIndex(where: { $0.identifier.rawValue == ColumnID.received.rawValue }) {
                list.moveColumn(at, toColumn: received)
            }
        } else if let column = list.tableColumn(withIdentifier: id) {
            subject.map { $0.width += column.width }
            list.removeTableColumn(column)
        }
    }

    /// the folder of a row in a list of several folders: its name, with its account's when there are several accounts
    private func rowFolder(_ id: Int64) -> String {
        guard let node = folderNodes[id] else { return "" }
        var text = node.folder.displayName
        if accountInfo.count > 1 {
            text += " (\(accountName(node.folder.account)))"
        }
        return text
    }

    func reloadList(keepSelection: Bool) {
        pages = []
        total = 0
        unread = 0
        showFolderColumn()
        // the counts of the folder come from its indexes; a search counts what it finds; an account lists nothing
        if searching {
            (total, unread) = core.messageCount(search)
        } else if folder != 0 {
            (total, unread) = core.folderCounts(folder)
        }
        // the selection follows the message to where it is now, without a flicker of the reading pane
        let index = keepSelection && uid != 0
            ? core.messageIndex(search, sort: sort, ascending: ascending, folder: messageFolder, uid: uid) : -1
        reloading = true
        list.reloadData()
        if index >= 0 {
            list.selectRowIndexes(IndexSet(integer: Int(index)), byExtendingSelection: false)
            list.scrollRowToVisible(Int(index))
        } else {
            list.deselectAll(nil)
        }
        reloading = false
        updateEmptyText()
        updateSearchBar()
        selectionDidChange()
    }

    func row(_ index: Int) -> Message? {
        guard index >= 0, UInt64(index) < total else { return nil }
        let offset = UInt64(index) / pageSize * pageSize
        if let at = pages.firstIndex(where: { $0.offset == offset }) {
            // the most recently used page goes last, the least recently used is dropped first
            let page = pages.remove(at: at)
            pages.append(page)
        } else {
            if pages.count >= 8 { pages.removeFirst() }
            pages.append((offset, core.messages(search, sort: sort, ascending: ascending, offset: offset, limit: pageSize)))
        }
        let rows = pages.last!.rows
        let at = Int(UInt64(index) - offset)
        return at < rows.count ? rows[at] : nil
    }

    var selectedRow: Message? { row(list.selectedRow) }

    fileprivate func sortBy(_ column: NSTableColumn) {
        let field: PeSortField
        switch ColumnID(rawValue: column.identifier.rawValue) {
        case .from: field = PE_SORT_FIELD_FROM
        case .subject: field = PE_SORT_FIELD_SUBJECT
        case .size: field = PE_SORT_FIELD_SIZE
        default: field = PE_SORT_FIELD_DATE
        }
        // the same column again turns the order around; dates and sizes start with the largest
        ascending = field == sort ? !ascending : field != PE_SORT_FIELD_DATE && field != PE_SORT_FIELD_SIZE
        sort = field
        showSortIndicator()
        reloadList(keepSelection: true)
    }

    private func showSortIndicator() {
        let sorted: ColumnID
        switch sort {
        case PE_SORT_FIELD_FROM: sorted = .from
        case PE_SORT_FIELD_SUBJECT: sorted = .subject
        case PE_SORT_FIELD_SIZE: sorted = .size
        default: sorted = .received
        }
        for column in list.tableColumns {
            let image = column.identifier.rawValue == sorted.rawValue
                ? NSImage(named: ascending ? "NSAscendingSortIndicator" : "NSDescendingSortIndicator") : nil
            list.setIndicatorImage(image, in: column)
        }
    }

    // ---- what an empty list says ----

    private func setUpEmptyText(in scroll: NSScrollView) {
        emptyTitle.font = .boldSystemFont(ofSize: 13)
        emptyTitle.textColor = .secondaryLabelColor
        emptyTitle.alignment = .center
        emptyMore.textColor = .secondaryLabelColor
        emptyMore.alignment = .center
        emptyMore.isSelectable = false
        let stack = NSStackView(views: [emptyTitle, emptyMore])
        stack.orientation = .vertical
        stack.spacing = 8
        stack.translatesAutoresizingMaskIntoConstraints = false
        listArea.addSubview(stack, positioned: .above, relativeTo: scroll)
        NSLayoutConstraint.activate([
            stack.centerXAnchor.constraint(equalTo: scroll.centerXAnchor),
            stack.topAnchor.constraint(equalTo: scroll.topAnchor, constant: 52),
            stack.widthAnchor.constraint(lessThanOrEqualToConstant: 420),
            stack.widthAnchor.constraint(lessThanOrEqualTo: scroll.widthAnchor, constant: -48),
        ])
        stack.setAccessibilityIdentifier("list.empty")
    }

    /// why there is nothing, and what to do about it
    private func updateEmptyText() {
        var title = ""
        var more = ""
        if total == 0 {
            if searching {
                title = "No messages match \u{201C}\(findText)\u{201D}."
                more = "The search looks at the subject, the people, the file names and the text of the messages "
                    + (findPlace.isEmpty ? "in every folder" : "in \(findPlace)") + ". Check the spelling, or try fewer words."
                let left = core.unindexedCount
                if left > 0 {
                    more += "\n\nThe text of \(left) " + (left == 1 ? "message is" : "messages are")
                        + " still being indexed, so more may be found soon."
                }
            } else if folder != 0 {
                title = "There are no items in this view."
            } else if selectedAccount != 0 {
                title = "Choose a folder to see its messages."
            }
        }
        emptyTitle.stringValue = title
        emptyMore.stringValue = more
        emptyTitle.isHidden = title.isEmpty
        emptyMore.isHidden = more.isEmpty
    }

    // ---- searching ----

    func find(_ typed: String) {
        // what only has spaces finds everything, as the core reads it
        let text = typed.trimmingCharacters(in: CharacterSet(charactersIn: " \t"))
        guard text != findText else { return }
        findText = text
        findPlace = Core.searchPlace(text)
        reloadList(keepSelection: true)
        changed()
    }

    private func resetFind() {
        findText = ""
        findPlace = ""
        AppDelegate.shared?.main?.searchCleared()
    }

    func clearFind() {
        guard !findText.isEmpty else { return }
        resetFind()
        reloadList(keepSelection: true)
        changed()
        list.window?.makeFirstResponder(list)
    }

    private func updateSearchBar() {
        var summary = ""
        if searching {
            // what was found, for what, where: the words stay in view while the list changes under them
            summary = total == 0 ? "No results" : "\(total) " + (total == 1 ? "result" : "results")
            summary += " for \u{201C}\(findText)\u{201D} " + (findPlace.isEmpty ? "in all folders" : "in \(findPlace)")
            let left = core.unindexedCount
            if left > 0 {
                summary += "  \u{00B7}  still indexing the text of \(left) " + (left == 1 ? "message" : "messages")
            }
        }
        searchBar.text = summary
        searchBar.isHidden = summary.isEmpty
        searchBar.heightConstraint?.constant = summary.isEmpty ? 0 : 26
    }

    // ---- the reading pane ----

    private func clearReader(loading: Bool = false) {
        if viewRequest != 0 {
            pe_message_view_cancel(core.handle, viewRequest)
            viewRequest = 0
        }
        uid = 0
        messageFolder = 0
        openWhenReady = false
        remoteImages = false
        messageView = nil
        markReadTimer?.invalidate()
        logoRequest = 0
        reader.clear(loading: loading)
    }

    fileprivate func selectionDidChange() {
        guard !reloading else { return }
        let row = selectedRow
        let newUid = row?.uid ?? 0
        let newFolder = row?.folder ?? 0
        if newUid == uid && newFolder == messageFolder {
            return
        }
        clearReader(loading: newUid != 0)
        selectionChanged()
        guard newUid != 0 else { return }
        uid = newUid
        messageFolder = newFolder
        reader.showLoading()
        // MessageReady follows, right away when the message is cached
        pe_message_open(core.handle, newFolder, newUid)
    }

    private func showMessage() {
        // fetched now: a draft that was double-clicked before opens
        if openWhenReady {
            openWhenReady = false
            openSelected()
        }
        // parsing, folding and sanitizing a large message takes a while: on a worker, ViewReady follows
        if viewRequest != 0 {
            pe_message_view_cancel(core.handle, viewRequest)
        }
        viewRequest = pe_message_view_start(core.handle, messageFolder, uid, remoteImages)
        if viewRequest == 0 {
            reader.showProblem("The message could not be shown.")
        }
    }

    private func showView() {
        messageView = MessageView(pe_message_view_result(core.handle, viewRequest))
        viewRequest = 0
        guard let messageView, let info = messageView.info else {
            reader.showProblem("The message could not be shown.")
            return
        }
        reader.show(info.pointee, view: messageView, pictures: remoteImages)
        if info.pointee.has_logo {
            logoRequest = pe_logo_start(core.handle, messageFolder, uid, UInt32(reader.logoPixels))
        }
        // read after a moment on screen, not while the user moves through the list
        markReadTimer?.invalidate()
        markReadTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: false) { [weak self] _ in
            MainActor.assumeIsolated {
                guard let self, let row = self.selectedRow, row.uid == self.uid, !row.seen else { return }
                self.markSelected(seen: true)
            }
        }
    }

    func loadPictures() {
        if uid != 0 && messageView != nil && !remoteImages {
            remoteImages = true
            showMessage()
        }
    }

    /// the message (`folder`, `uid`) in its folder, selected; the folder ends a search
    func showMessage(folder id: Int64, uid message: UInt64) {
        guard let node = folderNodes[id] else { return }
        let treeRow = tree.row(forItem: node)
        if treeRow >= 0 {
            tree.selectRowIndexes(IndexSet(integer: treeRow), byExtendingSelection: false)
        }
        guard folder == id else { return }
        let index = core.messageIndex(search, sort: sort, ascending: ascending, folder: id, uid: message)
        if index >= 0 {
            list.selectRowIndexes(IndexSet(integer: Int(index)), byExtendingSelection: false)
            list.scrollRowToVisible(Int(index))
            list.window?.makeFirstResponder(list)
        }
    }

    // ---- the message's own actions ----

    @objc func openSelected() {
        guard uid != 0, folderNodes[messageFolder]?.folder.specialUse == PE_SPECIAL_USE_DRAFTS else { return }
        guard let draft = Draft(pe_draft_open(core.handle, messageFolder, uid)) else {
            // not fetched yet: MessageReady follows
            openWhenReady = true
            return
        }
        ComposeWindow.open(core: core, account: currentAccount, draft: draft)
    }

    func draftOfShown(_ kind: PeDraftKind) -> Draft? {
        guard uid != 0, messageView != nil else { return nil }
        return Draft(pe_message_draft(core.handle, messageFolder, uid, kind))
    }

    func markSelected(seen: Bool) {
        if uid != 0 {
            pe_message_set_seen(core.handle, messageFolder, uid, seen)
        }
    }

    func markAllRead() {
        if folder != 0 && !searching {
            pe_folder_mark_all_read(core.handle, folder)
        }
    }

    func markJunk(_ junk: Bool) {
        guard let row = selectedRow else { return }
        if !pe_message_mark_junk(core.handle, row.folder, row.uid, junk) {
            inform(junk ? "This account has no Junk E-mail folder to move the message to."
                             : "The message could not be moved to the Inbox.")
        }
    }

    func flagSelected() {
        if let row = selectedRow {
            pe_message_set_flagged(core.handle, row.folder, row.uid, !row.flagged)
        }
    }

    /// after a message left the list: the one that took its place selected, or the last one
    private func selectAfterRemoval(_ index: Int) {
        reloadList(keepSelection: false)
        if index >= 0 && total > 0 {
            let next = min(index, Int(total) - 1)
            list.selectRowIndexes(IndexSet(integer: next), byExtendingSelection: false)
            list.scrollRowToVisible(next)
        }
    }

    func deleteSelected() {
        let index = list.selectedRow
        guard let row = row(index) else { return }
        // from Deleted Items, or an account without one, it is gone for good: asked first
        if pe_folder_deletes_for_good(core.handle, row.folder)
            && !ask("This message will be deleted for good. Delete it?", yes: "Delete", no: "Cancel", destructive: true) {
            return
        }
        if pe_message_delete(core.handle, row.folder, row.uid) {
            selectAfterRemoval(index)
        }
    }

    func moveSelected() {
        let index = list.selectedRow
        guard let row = row(index) else { return }
        // the other folders of its account that hold messages
        let account = folderNodes[row.folder]?.folder.account ?? currentAccount
        let targets = core.folders(account).filter { $0.selectable && $0.id != row.folder }
        guard !targets.isEmpty else { return }
        // a special folder by its usual name, the others by their whole path
        let names = targets.map { $0.specialUse != PE_SPECIAL_USE_NONE ? $0.displayName : $0.path }
        guard let fields = formDialog(title: "Move", intro: "Move the selected message to the folder:",
                                      fields: [FormField(label: "Folder:", value: names[0], kind: .choice(names))])
        else { return }
        let chosen = fields[0].chosen
        if targets.indices.contains(chosen) && pe_message_move(core.handle, row.folder, row.uid, targets[chosen].id) {
            selectAfterRemoval(index)
        }
    }

    // ---- folders ----

    private func askFolderName(title: String, intro: String, name: String) -> String? {
        formDialog(title: title, intro: intro, fields: [FormField(label: "Folder name:", value: name)])?[0].value
    }

    private func refused(_ reason: UnsafeMutablePointer<CChar>?, _ fallback: String) {
        inform(taken(reason) ?? fallback, style: .warning)
    }

    func newFolder() {
        let account = currentAccount
        guard account != 0 else { return }
        let where_ = folder != 0 ? "The new folder goes in the selected folder." : "The new folder goes at the top of the account."
        guard let name = askFolderName(title: "New Folder", intro: where_, name: ""), !name.isEmpty else { return }
        var reason: UnsafeMutablePointer<CChar>?
        if !name.withCString({ pe_folder_create(core.handle, account, folder, $0, &reason) }) {
            refused(reason, "The folder could not be created.")
        }
    }

    func renameFolder() {
        guard folder != 0, let node = folderNodes[folder], !node.folder.fixed else { return }
        let current = node.folder.displayName
        guard let name = askFolderName(title: "Rename Folder", intro: "The new name of the folder \(current).", name: current),
              !name.isEmpty, name != current else { return }
        var reason: UnsafeMutablePointer<CChar>?
        if !name.withCString({ pe_folder_rename(core.handle, folder, $0, &reason) }) {
            refused(reason, "The folder could not be renamed.")
        }
    }

    func deleteFolder() {
        guard folder != 0, let node = folderNodes[folder], !node.folder.fixed else { return }
        guard ask("Delete the folder \"\(node.folder.displayName)\" with its messages and the folders in it? It is deleted on the server too.",
                  yes: "Delete", no: "Cancel", destructive: true) else { return }
        var reason: UnsafeMutablePointer<CChar>?
        if !pe_folder_delete(core.handle, folder, &reason) {
            refused(reason, "The folder could not be deleted.")
        }
    }

    /// the folder menu (a right-click in the tree): Mark All Read, New, Rename, Delete
    fileprivate func folderMenu() -> NSMenu {
        let menu = NSMenu()
        let someUnread = folder != 0 && core.folderCounts(folder).unread > 0
        let editable = folder != 0 && !(folderNodes[folder]?.folder.fixed ?? true)
        for (command, enabled) in [(Command.markAllRead, someUnread), (.newFolder, true), (.renameFolder, editable),
                                   (.deleteFolder, editable)] {
            let item = NSMenuItem(title: command.label, action: #selector(folderMenuItem(_:)), keyEquivalent: "")
            item.target = self
            item.tag = command.rawValue
            item.isEnabled = enabled
            menu.addItem(item)
            if command == .markAllRead {
                menu.addItem(.separator())
            }
        }
        menu.autoenablesItems = false
        return menu
    }

    @objc private func folderMenuItem(_ sender: NSMenuItem) {
        if let command = Command(rawValue: sender.tag) {
            AppDelegate.shared.perform(command)
        }
    }

    // ---- files and printing ----

    func saveShownAs() {
        guard uid != 0 else { return }
        var length = 0
        var name: UnsafeMutablePointer<CChar>?
        let data = takenBytes(pe_message_source(core.handle, messageFolder, uid, &length, &name), length)
        let safeName = taken(name) ?? "message.eml"
        guard let data else {
            inform("The message is not downloaded yet.")
            return
        }
        if let url = saveFilePanel(name: safeName, title: "Save Message As", types: [.emailMessage]), !writeDownloaded(data, to: url) {
            inform("The message could not be saved.", style: .error)
        }
    }

    func showProperties() {
        guard uid != 0 else {
            inform("Select a message first.")
            return
        }
        guard let headers = taken(pe_message_headers(core.handle, messageFolder, uid)) else {
            inform("The message is not downloaded yet.")
            return
        }
        let subject = messageView?.info.map { text($0.pointee.subject) } ?? ""
        textDialog(title: subject.isEmpty ? "Properties" : "\(subject) Properties", intro: "Internet headers for this message:",
                   text: headers)
    }

    func printShown() {
        guard uid != 0, let info = messageView?.info else { return }
        // the message as it is shown, with the pictures the user allowed
        Printer.print(text(info.pointee.document), pictures: remoteImages, title: text(info.pointee.subject),
                      owner: list.window)
    }

    func importMessages() {
        guard folder != 0 else {
            inform("Choose the folder to put the messages in first.", title: "Import Messages")
            return
        }
        var problems = ""
        for file in openFilesPanel(title: "Import Messages", types: [.emailMessage, .data]) {
            var reason: UnsafeMutablePointer<CChar>?
            if !file.path.withCString({ pe_message_import(core.handle, folder, $0, &reason) }) {
                problems += (taken(reason) ?? file.path) + "\n"
            }
        }
        if !problems.isEmpty {
            inform("These were not imported:\n\n" + problems, title: "Import Messages", style: .warning)
        }
    }

    // ---- attachments ----

    /// the files of the message to save, then all of them into a folder; files are saved, never opened from here
    func attachmentMenu() -> NSMenu {
        let menu = NSMenu()
        guard let view = messageView, let info = view.info else { return menu }
        for index in 0..<info.pointee.attachment_count {
            guard let attachment = view.attachment(index) else { continue }
            let item = NSMenuItem(title: "\(attachment.name) (\(formatSize(attachment.size)))",
                                  action: #selector(saveAttachment(_:)), keyEquivalent: "")
            item.target = self
            item.tag = index
            menu.addItem(item)
        }
        menu.addItem(.separator())
        let all = NSMenuItem(title: "Save Attachments\u{2026}", action: #selector(saveAllAttachments), keyEquivalent: "")
        all.target = self
        menu.addItem(all)
        return menu
    }

    @objc private func saveAttachment(_ sender: NSMenuItem) {
        var length = 0
        var name: UnsafeMutablePointer<CChar>?
        let data = takenBytes(pe_attachment_data(core.handle, messageFolder, uid, sender.tag, &length, &name), length)
        let safeName = taken(name) ?? "attachment"
        guard let data else {
            inform("The attachment could not be read.", style: .error)
            return
        }
        if let url = saveFilePanel(name: safeName), !writeDownloaded(data, to: url) {
            inform("The attachment could not be saved.", style: .error)
        }
    }

    @objc private func saveAllAttachments() {
        guard let folder = folderPanel(title: "Save Attachments") else { return }
        // the core saves them all from one reading of the message, a file already there kept and the new one numbered
        var saved = 0
        var total = 0
        if !folder.path.withCString({ pe_save_attachments(core.handle, messageFolder, uid, $0, &saved, &total) }) {
            inform("The message is not downloaded yet.")
        } else if saved < total {
            inform("\(total - saved) of the \(total) files could not be saved.", style: .error)
        }
    }

    /// the calendar part as a file of its own (the core writes it, and only it), for the calendar app
    func openInCalendar() {
        let dir = FileManager.default.temporaryDirectory.appendingPathComponent("InboxClassic/Invitations").path
        guard let path = dir.withCString({ taken(pe_invitation_file(core.handle, messageFolder, uid, $0)) }) else {
            inform("The invitation could not be read.", style: .error)
            return
        }
        if !NSWorkspace.shared.open(URL(fileURLWithPath: path)) {
            inform("No calendar app on this Mac opens invitations (.ics files).")
        }
    }

    // ---- leaving a mailing list ----

    func unsubscribe() {
        guard let info = messageView?.info?.pointee else { return }
        let target = text(info.unsubscribe_target)
        let link = text(info.unsubscribe_link)
        switch info.unsubscribe {
        case PE_UNSUBSCRIBE_ONE_CLICK:
            guard ask("Leave this mailing list?\n\nInbox Classic asks \(target) to stop sending it to you. No page opens and no message is sent.",
                      title: "Unsubscribe", style: .information) else { return }
            unsubscribeRequest = pe_unsubscribe(core.handle, messageFolder, uid)
            status(unsubscribeRequest != 0 ? "Unsubscribing from \(target)\u{2026}" : "This message can not unsubscribe you.")
        case PE_UNSUBSCRIBE_MAIL:
            if ask("Leave this mailing list?\n\nThe list wants a message to \(target). Inbox Classic writes it for you; send it to unsubscribe.",
                   title: "Unsubscribe", yes: "OK", no: "Cancel", style: .information) {
                openMailto(link)
            }
        case PE_UNSUBSCRIBE_WEB:
            if ask("Leave this mailing list?\n\nThe list's page for it opens in your browser (\(target)).", title: "Unsubscribe",
                   yes: "OK", no: "Cancel", style: .information) {
                openExternally(URL(string: link))
            }
        default:
            break
        }
    }

    func unsubscribed(_ request: UInt64, problem: String) -> String? {
        guard request == unsubscribeRequest else { return nil }
        unsubscribeRequest = 0
        return problem.isEmpty ? "Unsubscribed. The list says it will stop sending this mail." : "Could not unsubscribe: \(problem)"
    }

    // ---- dragging a message onto a folder ----

    /// the folder a message dragged from `from` may go to: another folder of its account that holds messages
    fileprivate func dropTarget(_ item: Any?, from: Int64) -> Int64? {
        guard let node = item as? FolderNode, node.folder.selectable, node.folder.id != from,
              let source = folderNodes[from], source.folder.account == node.folder.account else { return nil }
        return node.folder.id
    }

    fileprivate func drop(folder from: Int64, uid message: UInt64, to: Int64, copy: Bool) -> Bool {
        if copy {
            return pe_message_copy(core.handle, from, message, to)
        }
        let index = from == messageFolder && message == uid ? list.selectedRow : -1
        guard pe_message_move(core.handle, from, message, to) else { return false }
        if index >= 0 {
            selectAfterRemoval(index)
        }
        return true
    }

    // ---- the core's events ----

    func onEvent(_ event: CoreEvent) {
        switch event.kind {
        case PE_EVENT_KIND_FOLDERS_CHANGED:
            reload()
        case PE_EVENT_KIND_FOLDER_CHANGED:
            updateFolders(event.account)
            if event.folder == folder && !searching {
                reloadList(keepSelection: true)
            } else if searching {
                // a list of several folders has messages of any of them; once a sync of many is done, not after each
                reloadTimer?.invalidate()
                reloadTimer = Timer.scheduledTimer(withTimeInterval: 0.3, repeats: false) { [weak self] _ in
                    MainActor.assumeIsolated {
                        self?.reloadList(keepSelection: true)
                        self?.changed()
                    }
                }
            }
        case PE_EVENT_KIND_MESSAGE_READY:
            if event.folder == messageFolder && event.uid == uid {
                showMessage()
            }
        case PE_EVENT_KIND_VIEW_READY:
            // a view for a message that is no longer selected was cancelled, its event is not this one
            if viewRequest != 0 && event.uid == viewRequest {
                showView()
            }
        case PE_EVENT_KIND_LOGO_READY:
            if logoRequest != 0 && event.uid == logoRequest {
                logoRequest = 0
                var length = 0
                let pixels = takenBytes(pe_logo_result(core.handle, event.uid, &length), length)
                reader.showLogo(pixels)
            }
        case PE_EVENT_KIND_SYNC_FINISHED:
            // how much text the search still has to read
            updateSearchBar()
        default:
            break
        }
    }
}

// ---- the tree's rows ----

extension Mailbox: NSOutlineViewDataSource, NSOutlineViewDelegate {
    public func outlineView(_ outlineView: NSOutlineView, numberOfChildrenOfItem item: Any?) -> Int {
        switch item {
        case nil: return accounts.count
        case let account as AccountNode: return account.children.count
        case let folder as FolderNode: return folder.children.count
        default: return 0
        }
    }

    public func outlineView(_ outlineView: NSOutlineView, child index: Int, ofItem item: Any?) -> Any {
        switch item {
        case let account as AccountNode: return account.children[index]
        case let folder as FolderNode: return folder.children[index]
        default: return accounts[index]
        }
    }

    public func outlineView(_ outlineView: NSOutlineView, isItemExpandable item: Any) -> Bool {
        self.outlineView(outlineView, numberOfChildrenOfItem: item) > 0
    }

    public func outlineView(_ outlineView: NSOutlineView, viewFor tableColumn: NSTableColumn?, item: Any) -> NSView? {
        let cell = (outlineView.makeView(withIdentifier: FolderCell.identifier, owner: nil) as? FolderCell) ?? FolderCell()
        switch item {
        case let account as AccountNode:
            cell.show(name: account.account.title, count: 0, icon: Icons.folder("mailbox"), bold: false)
            cell.setAccessibilityIdentifier("tree.account.\(account.account.id)")
        case let node as FolderNode:
            cell.show(name: node.folder.displayName, count: node.folder.unread, icon: Icons.folder(Icons.folderIcon(node.folder.specialUse)),
                      bold: node.folder.unread > 0)
            cell.setAccessibilityIdentifier("tree.folder.\(node.folder.id)")
        default:
            break
        }
        return cell
    }

    /// the selected row drawn by the row itself, in the system's selection color, rather than by the source list's
    /// vibrancy (which a picture of the window taken by the app, as the UI test takes them, can not show)
    public func outlineView(_ outlineView: NSOutlineView, rowViewForItem item: Any) -> NSTableRowView? {
        SelectionRow()
    }

    public func outlineViewSelectionDidChange(_ notification: Notification) {
        guard !reloading else { return }
        let item = tree.item(atRow: tree.selectedRow)
        // an account has no messages of its own
        if let account = item as? AccountNode {
            selectedAccount = account.account.id
            folderSelected(0)
        } else if let node = item as? FolderNode {
            selectedAccount = 0
            folderSelected(node.folder.id)
        } else {
            selectedAccount = 0
            folderSelected(0)
        }
    }

    public func outlineView(_ outlineView: NSOutlineView, validateDrop info: NSDraggingInfo, proposedItem item: Any?,
                            proposedChildIndex index: Int) -> NSDragOperation {
        guard let (from, _) = draggedMessage(info), dropTarget(item, from: from) != nil, index == NSOutlineViewDropOnItemIndex
        else { return [] }
        // Option copies, as in the Finder
        return NSEvent.modifierFlags.contains(.option) ? .copy : .move
    }

    public func outlineView(_ outlineView: NSOutlineView, acceptDrop info: NSDraggingInfo, item: Any?, childIndex index: Int) -> Bool {
        guard let (from, message) = draggedMessage(info), let to = dropTarget(item, from: from) else { return false }
        return drop(folder: from, uid: message, to: to, copy: NSEvent.modifierFlags.contains(.option))
    }

    private func draggedMessage(_ info: NSDraggingInfo) -> (Int64, UInt64)? {
        guard let value = info.draggingPasteboard.string(forType: messagePasteboardType) else { return nil }
        let parts = value.split(separator: " ")
        guard parts.count == 2, let folder = Int64(parts[0]), let uid = UInt64(parts[1]) else { return nil }
        return (folder, uid)
    }
}

// ---- the list's rows ----

extension Mailbox: NSTableViewDataSource, NSTableViewDelegate {
    public func numberOfRows(in tableView: NSTableView) -> Int {
        Int(min(total, UInt64(Int32.max)))
    }

    public func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row index: Int) -> NSView? {
        guard let column = tableColumn, let message = row(index) else { return nil }
        let id = column.identifier
        switch ColumnID(rawValue: id.rawValue) {
        case .read, .attach, .flag:
            let cell = (tableView.makeView(withIdentifier: id, owner: nil) as? IconCell) ?? IconCell(id)
            switch ColumnID(rawValue: id.rawValue) {
            case .read: cell.show(Icons.list(message.seen ? "mail_read" : "mail"))
            case .attach: cell.show(message.hasAttachments ? Icons.list("attach") : nil)
            default: cell.show(message.flagged ? Icons.list("flag") : nil)
            }
            return cell
        default:
            let cell = (tableView.makeView(withIdentifier: id, owner: nil) as? TextCell) ?? TextCell(id)
            let value: String
            switch ColumnID(rawValue: id.rawValue) {
            case .from: value = message.from
            case .subject: value = message.subject
            case .received: value = message.date.map(formatDate) ?? ""
            case .size: value = formatSize(message.size)
            case .folder: value = rowFolder(message.folder)
            default: value = ""
            }
            // unread messages in bold, as Outlook Express shows them
            cell.show(value, bold: !message.seen, right: id.rawValue == ColumnID.size.rawValue)
            return cell
        }
    }

    public func tableViewSelectionDidChange(_ notification: Notification) {
        selectionDidChange()
    }

    public func tableView(_ tableView: NSTableView, didClick tableColumn: NSTableColumn) {
        sortBy(tableColumn)
    }

    public func tableView(_ tableView: NSTableView, pasteboardWriterForRow index: Int) -> NSPasteboardWriting? {
        guard let message = row(index) else { return nil }
        let item = NSPasteboardItem()
        item.setString("\(message.folder) \(message.uid)", forType: messagePasteboardType)
        return item
    }
}

// ---- the views of the rows ----

/// A folder in the tree: its icon, its name (bold while it has unread mail) and the count of unread messages
final class FolderCell: NSTableCellView {
    static let identifier = NSUserInterfaceItemIdentifier("folder")
    private let icon = NSImageView()
    private let name = NSTextField(labelWithString: "")
    private let count = NSTextField(labelWithString: "")

    init() {
        super.init(frame: .zero)
        identifier = FolderCell.identifier
        name.lineBreakMode = .byTruncatingTail
        count.textColor = .secondaryLabelColor
        count.alignment = .right
        let stack = NSStackView(views: [icon, name, count])
        stack.spacing = 5
        stack.translatesAutoresizingMaskIntoConstraints = false
        name.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        count.setContentHuggingPriority(.required, for: .horizontal)
        addSubview(stack)
        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 2),
            stack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -6),
            stack.centerYAnchor.constraint(equalTo: centerYAnchor),
            icon.widthAnchor.constraint(equalToConstant: 16),
            icon.heightAnchor.constraint(equalToConstant: 16),
        ])
        textField = name
        imageView = icon
    }

    required init?(coder: NSCoder) { fatalError() }

    func show(name text: String, count unread: UInt64, icon image: NSImage?, bold: Bool) {
        name.stringValue = text
        name.font = bold ? .boldSystemFont(ofSize: NSFont.systemFontSize) : .systemFont(ofSize: NSFont.systemFontSize)
        count.stringValue = unread > 0 ? "\(unread)" : ""
        icon.image = image
        setAccessibilityLabel(unread > 0 ? "\(text), \(unread) unread" : text)
    }
}

final class IconCell: NSTableCellView {
    private let icon = NSImageView()

    init(_ id: NSUserInterfaceItemIdentifier) {
        super.init(frame: .zero)
        identifier = id
        icon.translatesAutoresizingMaskIntoConstraints = false
        addSubview(icon)
        NSLayoutConstraint.activate([
            icon.centerXAnchor.constraint(equalTo: centerXAnchor),
            icon.centerYAnchor.constraint(equalTo: centerYAnchor),
            icon.widthAnchor.constraint(equalToConstant: 16),
            icon.heightAnchor.constraint(equalToConstant: 16),
        ])
    }

    required init?(coder: NSCoder) { fatalError() }

    func show(_ image: NSImage?) {
        icon.image = image
    }
}

final class TextCell: NSTableCellView {
    private let label = NSTextField(labelWithString: "")

    init(_ id: NSUserInterfaceItemIdentifier) {
        super.init(frame: .zero)
        identifier = id
        label.lineBreakMode = .byTruncatingTail
        label.translatesAutoresizingMaskIntoConstraints = false
        label.cell?.usesSingleLineMode = true
        addSubview(label)
        NSLayoutConstraint.activate([
            label.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 2),
            label.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -2),
            label.centerYAnchor.constraint(equalTo: centerYAnchor),
        ])
        textField = label
    }

    required init?(coder: NSCoder) { fatalError() }

    func show(_ value: String, bold: Bool, right: Bool) {
        label.stringValue = value
        label.font = bold ? .boldSystemFont(ofSize: NSFont.systemFontSize) : .systemFont(ofSize: NSFont.systemFontSize)
        label.alignment = right ? .right : .left
    }
}

/// A row of the folder tree with its selection in the system's colors: the accent while the tree has the keyboard, grey
/// otherwise
final class SelectionRow: NSTableRowView {
    override func drawSelection(in dirtyRect: NSRect) {
        let color: NSColor = isEmphasized ? .selectedContentBackgroundColor : .unemphasizedSelectedContentBackgroundColor
        color.setFill()
        NSBezierPath(roundedRect: bounds.insetBy(dx: 10, dy: 1), xRadius: 6, yRadius: 6).fill()
    }

    override var interiorBackgroundStyle: NSView.BackgroundStyle {
        isSelected && isEmphasized ? .emphasized : .normal
    }
}

/// The folder tree: a right-click selects the folder under the mouse and shows its menu
public final class FolderOutline: NSOutlineView {
    weak var mailbox: Mailbox?

    init() {
        super.init(frame: .zero)
        let column = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("name"))
        addTableColumn(column)
        outlineTableColumn = column
        headerView = nil
        style = .sourceList
        selectionHighlightStyle = .regular
        rowSizeStyle = .default
        indentationPerLevel = 14
        autoresizesOutlineColumn = true
        registerForDraggedTypes([messagePasteboardType])
        draggingDestinationFeedbackStyle = .sourceList
        setAccessibilityIdentifier("tree")
    }

    required init?(coder: NSCoder) { fatalError() }

    public override func menu(for event: NSEvent) -> NSMenu? {
        let row = self.row(at: convert(event.locationInWindow, from: nil))
        if row >= 0 {
            selectRowIndexes(IndexSet(integer: row), byExtendingSelection: false)
        }
        return mailbox?.folderMenu()
    }
}

/// The message list: Return opens a draft, Delete deletes, as the list of the Windows app does
public final class MessageTable: NSTableView {
    weak var mailbox: Mailbox?

    public override func keyDown(with event: NSEvent) {
        switch event.keyCode {
        case 36, 76:
            mailbox?.openSelected()
        case 51, 117:
            mailbox?.deleteSelected()
        default:
            super.keyDown(with: event)
        }
    }
}
