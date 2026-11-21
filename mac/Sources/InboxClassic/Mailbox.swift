// The folder tree, the message list and the reading pane. The list is virtual: rows come from the core a page at a
// time as the table asks for them. Every string shown was decoded by the core; the message body is the sanitized
// document the core made, shown in the web view as it is.
import AppKit
import CInboxClassic
import UniformTypeIdentifiers

/// The pasteboard type of a message dragged from the list onto a folder: "<folder> <uid>"
let messagePasteboardType = NSPasteboard.PasteboardType("com.inboxclassic.message")

/// The pasteboard type of an account dragged in the folder tree to a new place in the accounts' order: "heading <id>"
/// for its heading, "inbox <id>" for its row under All Inboxes
let accountPasteboardType = NSPasteboard.PasteboardType("com.inboxclassic.account")

/// A file the Finder can drop that is a message, as the core takes them
func isMessageFile(_ url: URL) -> Bool {
    url.path.withCString { pe_is_message_file($0) }
}

/// Which rows of the folder tree the user opened or closed (those whose row `remembersOpen`: All Inboxes, All Sent,
/// All Drafts and each account), kept in the user defaults between starts; a row not kept (a new account) starts as
/// the core says. The UI test keeps them in memory, so a run never changes those of whoever runs it.
@MainActor
struct OpenRows {
    /// the name a row is kept under: its key, but All Inboxes' and the accounts' as earlier versions kept them
    static func name(_ row: TreeRow) -> String {
        if row.key == "inboxes" { return "allInboxes" }
        if row.key.hasPrefix("account:") { return "account.\(row.account)" }
        return row.key
    }
    private static let key = "FolderTreeOpen"
    private var testRows: [String: Bool] = [:]

    private var rows: [String: Bool] {
        get { TestHooks.testing ? testRows : UserDefaults.standard.dictionary(forKey: OpenRows.key) as? [String: Bool] ?? [:] }
        set {
            if TestHooks.testing {
                testRows = newValue
            } else {
                UserDefaults.standard.set(newValue, forKey: OpenRows.key)
            }
        }
    }

    func isOpen(_ row: TreeRow) -> Bool { rows[OpenRows.name(row)] ?? row.startsOpen }

    mutating func set(_ row: TreeRow, _ open: Bool) { rows[OpenRows.name(row)] = open }

    /// the rows of removed accounts dropped
    mutating func forget(except accounts: [Int64]) {
        guard !accounts.isEmpty else { return }
        let kept = Set(accounts.map { "account.\($0)" })
        let all = rows
        let left = all.filter { !$0.key.hasPrefix("account.") || kept.contains($0.key) }
        if left.count != all.count {
            rows = left
        }
    }
}

@MainActor
public final class Mailbox: NSObject {
    let core: Core
    let view: NSSplitView
    let tree = FolderOutline()
    public let list = MessageTable()
    let reader: Reader
    private let listArea = NSView()
    private let searchBar = InfoBar(icon: "search", link: Text.uiClearSearch.text)
    private let emptyTitle = NSTextField(labelWithString: "")
    private let emptyMore = NSTextField(wrappingLabelWithString: "")
    private lazy var emptyMoreWidth = emptyMore.widthAnchor.constraint(equalToConstant: Mailbox.emptyTextWidth)
    private static let emptyTextWidth: CGFloat = 420
    private let rightSplit = NSSplitView()
    /// the folder tree in its scroll view: the left pane, hidden with View > Folder List off
    private var treePane: NSScrollView!
    /// what the panes show: the list above the reader, or beside it (MainWindow.updateLayout decides)
    private(set) var layout = PE_LAYOUT_CLASSIC
    /// the senders' pictures of the column layout's rows, whether they are shown (Settings), and the screen's scale they
    /// are drawn at, both taken again when the list is
    let pictures: ListPictures
    private var showsPictures = true
    private var pictureScale: CGFloat = 2
    /// the one column of the column layout's rows, and what Classic has in its place while it is shown
    private let rowColumn = NSTableColumn(identifier: MessageRowCell.identifier)
    private var classicColumns: [NSTableColumn] = []
    private var classicHeader: NSTableHeaderView?
    /// over the column layout's list in place of the headings: how it is sorted, a pull-down of the Sort By choices
    private let sortBar = NSPopUpButton(frame: .zero, pullsDown: true)
    private let sortRow = NSView()
    private var sortRowHeight: NSLayoutConstraint!
    /// the pane sizes each layout needs: the list's height above the reader, its width beside it
    private var listHeightMin: NSLayoutConstraint!
    private var readerHeightMin: NSLayoutConstraint!
    private var listWidthMin: NSLayoutConstraint!
    private var classicListHeight = Mailbox.defaultListHeight
    /// what the column layout's dates are seen from, taken again with each reload of the list
    private var dateClock = DateClock()
    /// while the layout changes, the dividers moved are not the user's
    private var changingLayout = false

    /// the counts or the folder changed (the main window shows them)
    var changed: () -> Void = {}
    /// another message or folder is selected (Junk or Not Junk)
    var selectionChanged: () -> Void = {}
    /// a line for the status bar
    var status: (String) -> Void = { _ in }
    /// a mailto: link to write (a mailing list's unsubscribe address)
    var openMailto: (String) -> Void = { _ in }
    /// Edit > Undo when the last thing done was sending a message that still waits
    var undoSend: (() -> Void)?

    // the folder tree, as the core lays it out
    private var topNodes: [TreeNode] = []
    /// every row, in the tree's order
    private var treeNodes: [TreeNode] = []
    /// the row of each folder: one each (with several accounts an Inbox's is under All Inboxes)
    private var folderRows: [Int64: TreeNode] = [:]
    /// what each folder is (its name, its use, whether it can be renamed), by its id
    private var folderInfo: [Int64: Folder] = [:]
    private var accountInfo: [Int64: Account] = [:]
    /// the accounts in their order
    private var accountOrder: [Int64] = []
    private var openRows = OpenRows()
    /// the other rows with rows under them (folders) the user opened or closed, by their keys, kept while the app runs
    private var openedOrClosed: [String: Bool] = [:]
    private var reloading = false
    /// the rows above the row chosen are being opened to show it, which is not the user's opening
    private var revealing = false

    // the list: the folder or the search, its order and its rows
    private(set) var folder: Int64 = 0
    /// what the list shows, as the row chosen says: its folder's (`folder`), All Inboxes', All Sent's, All Drafts',
    /// Flagged's, or nothing
    private var shownList = PE_TREE_LIST_NONE
    /// All Inboxes is shown: the list has the mail of every account's Inbox
    var allInboxes: Bool { shownList == PE_TREE_LIST_ALL_INBOXES }
    /// the Flagged row is the list shown
    var flagged: Bool { shownList == PE_TREE_LIST_FLAGGED }
    /// selectStart has run: later showings of the window keep what is selected
    private var started = false
    private var sort = PE_SORT_FIELD_DATE
    private var ascending = false
    private var findText = ""
    private var findPlace = ""
    /// the messages listed and how many are unread, what the status bar counts
    private(set) var total: UInt64 = 0
    private var unread: UInt64 = 0
    /// the rows of the list: the messages, or grouped by conversation the conversations and the messages of the open
    /// ones
    private(set) var rows: UInt64 = 0
    /// what the list shows, as the core keeps it: the folder, the words, the order, grouping and the open
    /// conversations
    private let listView = ListView()
    private var pages: [(offset: UInt64, rows: [Message])] = []
    private let pageSize: UInt64 = 100
    private var folderColumn = false
    /// what Subject and From gave the Folder column, given back when it goes
    private var folderRoom: [CGFloat] = []
    /// Sent Items and Drafts: the person column is To, with the recipients
    private var recipientsColumn = false

    // the message shown, the reading pane's
    private var messageFolder: Int64 { reader.folder }
    private var uid: UInt64 { reader.uid }
    private var openWhenReady = false
    private var markReadTimer: Timer?
    /// the selected messages, one or several, as the core's actions take them
    private let selection: OpaquePointer = pe_selection_new()
    /// what the selected messages are in numbers
    private(set) var summary = PeSelectionSummary()
    /// after Undo: the messages it brings back are selected once the list has them (until the user selects otherwise)
    private var restorePending = false
    /// after a removal: the row that took the place of the messages taken out, selected by the next load (until the
    /// user or Undo selects otherwise)
    private var rowAfter: Int?
    /// another row of the tree chosen and its list not drawn yet: the core selects the message the list showed when it
    /// was left, else its newest; false once the app chose a message of its own to show in it
    private var arriving = false
    /// the message shown was in sight when the list was asked for again: the list scrolls to keep it so, and else stays
    /// where the user scrolled it
    private var keptInSight = false

    var selectedCount: Int { list.numberOfSelectedRows }
    /// the messages being dragged out of the list, as files for the Finder
    private var dragExport: DragExport?
    /// how many of them were written, for the status bar
    private var dragWritten = 0
    private let promiseWriter = PromiseWriter()
    /// the list read again a moment after its folders changed, however many changes came meanwhile
    private var reloadTimer: Timer?
    /// the folder list's counts read again a moment after folders changed
    private var countsTimer: Timer?

    // ---- paint first ----
    /// a row is being chosen with the mouse or the keyboard: its list loads after the tree is drawn with it selected
    var deferChoice = false
    /// the row chosen whose list loads on the next turn of the run loop, and what is done once it has
    private var pendingNode: TreeNode?
    private var pendingThen: (() -> Void)?
    private var pendingTimer: Timer?
    /// over the list while another one loads: the list before dimmed, taking no clicks, "Loading..." after a moment
    private let listCover = ListCover()
    private var loadingTimer: Timer?
    /// under test: a row chosen drawn selected, then its list loaded, in the order they came
    var paintOrder: [String] = []
    /// under test: the list of a row chosen waits until loadPending, for a picture of the wait
    var holdPending = false

    // ---- the list read off the window thread ----
    /// the load of the whole list on its way (0: none); a load or page asked for before it never comes
    private var listRequest: UInt64 = 0
    /// the user selected rows while the list was read: what the load selects is of before, so it is read again
    private var choseWhileLoading = false
    /// the load keeps what is selected (a reload of the same list), and dims the list before until it is here (another
    /// list, order or grouping)
    private var loadKeepsSelection = false
    private var loadCovers = false
    /// what waits for the list to be loaded (a row to select, a command chosen meanwhile)
    private var whenListed: [() -> Void] = []
    /// the pages asked for since the list was read, by request, with their first row
    private var pageRequests: [UInt64: UInt64] = [:]
    /// Select All: the whole list is selected, counted at once and summed up off the window thread, never listed here
    private var allSelected = false
    private var summaryRequest: UInt64 = 0
    /// the bar over the list that says what the server refused, taken back (`ActionUndone`)
    private let undoneBar = InfoBar(icon: "warning", link: nil, close: Text.uiClose.text)

    init(core: Core) {
        self.core = core
        view = NSSplitView()
        reader = Reader(core: core)
        pictures = ListPictures(core: core)
        super.init()
        pictures.arrived = { [weak self] picture in self?.pictureArrived(picture) }
        listView.setGrouped(AppDelegate.shared?.groupByConversation ?? true)
        listView.setHideIgnored(AppDelegate.shared?.hideIgnored ?? false)
        listView.setUnreadOnly(AppDelegate.shared?.hideRead ?? false)
        listView.setSort(sort, ascending: ascending)
        view.isVertical = true
        view.dividerStyle = .thin
        view.autosaveName = TestHooks.testing ? nil : "Panes"
        rightSplit.isVertical = false
        rightSplit.dividerStyle = .thin
        rightSplit.autosaveName = Mailbox.classicAutosave

        tree.dataSource = self
        tree.delegate = self
        tree.mailbox = self
        // a click on an account's heading opens or closes it, as in Mail
        tree.target = self
        tree.action = #selector(treeClicked)
        let treeScroll = scrolled(tree)
        treeScroll.widthAnchor.constraint(greaterThanOrEqualToConstant: Mailbox.smallestTree).isActive = true
        treePane = treeScroll

        setUpList()
        let listScroll = scrolled(list)
        listArea.addSubview(searchBar)
        listArea.addSubview(listScroll)
        searchBar.translatesAutoresizingMaskIntoConstraints = false
        listScroll.translatesAutoresizingMaskIntoConstraints = false
        searchBar.isHidden = true
        searchBar.clicked = { [weak self] in self?.clearFind() }
        searchBar.setAccessibilityIdentifier("search.bar")
        // a rule that sorts what the search finds as it arrives
        let createRule = NSButton(title: Text.uiCreateRule.opens, target: self, action: #selector(createRuleFromSearch))
        createRule.bezelStyle = .push
        createRule.controlSize = .small
        createRule.font = .systemFont(ofSize: NSFont.smallSystemFontSize)
        createRule.setAccessibilityIdentifier("search.rule")
        searchBar.setAccessories([createRule])
        let barHeight = searchBar.heightAnchor.constraint(equalToConstant: 0)
        searchBar.heightConstraint = barHeight
        setUpSortBar()
        // over the search bar: what the server refused and was taken back, until it is closed
        listArea.addSubview(undoneBar)
        undoneBar.translatesAutoresizingMaskIntoConstraints = false
        undoneBar.isHidden = true
        undoneBar.wrapText()
        undoneBar.clicked = { [weak self] in self?.showUndone(nil) }
        undoneBar.setAccessibilityIdentifier("list.undone")
        undoneBar.heightConstraint = undoneBar.heightAnchor.constraint(equalToConstant: 0)
        NSLayoutConstraint.activate([
            undoneBar.topAnchor.constraint(equalTo: listArea.topAnchor),
            undoneBar.leadingAnchor.constraint(equalTo: listArea.leadingAnchor),
            undoneBar.trailingAnchor.constraint(equalTo: listArea.trailingAnchor),
            undoneBar.heightConstraint!,
            searchBar.topAnchor.constraint(equalTo: undoneBar.bottomAnchor),
            searchBar.leadingAnchor.constraint(equalTo: listArea.leadingAnchor),
            searchBar.trailingAnchor.constraint(equalTo: listArea.trailingAnchor),
            barHeight,
            sortRow.topAnchor.constraint(equalTo: searchBar.bottomAnchor),
            sortRow.leadingAnchor.constraint(equalTo: listArea.leadingAnchor),
            sortRow.trailingAnchor.constraint(equalTo: listArea.trailingAnchor),
            sortRowHeight,
            listScroll.topAnchor.constraint(equalTo: sortRow.bottomAnchor),
            listScroll.leadingAnchor.constraint(equalTo: listArea.leadingAnchor),
            listScroll.trailingAnchor.constraint(equalTo: listArea.trailingAnchor),
            listScroll.bottomAnchor.constraint(equalTo: listArea.bottomAnchor),
        ])
        setUpEmptyText(in: listScroll)
        listArea.addSubview(listCover)
        listCover.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            listCover.topAnchor.constraint(equalTo: listArea.topAnchor),
            listCover.leadingAnchor.constraint(equalTo: listArea.leadingAnchor),
            listCover.trailingAnchor.constraint(equalTo: listArea.trailingAnchor),
            listCover.bottomAnchor.constraint(equalTo: listArea.bottomAnchor),
        ])
        listHeightMin = listArea.heightAnchor.constraint(greaterThanOrEqualToConstant: Mailbox.smallestList)
        listHeightMin.isActive = true
        listWidthMin = listArea.widthAnchor.constraint(greaterThanOrEqualToConstant: Mailbox.smallestListWidth)

        reader.status = { [weak self] in self?.status($0) }
        reader.openMailto = { [weak self] in self?.openMailto($0) }
        reader.arrivedHandler = { [weak self] in self?.messageArrived() }
        reader.shownHandler = { [weak self] in self?.messageShown() }
        reader.bouncedHandler = { [weak self] in self?.showMessage(folder: $0, uid: $1) }
        readerHeightMin = reader.view.heightAnchor.constraint(greaterThanOrEqualToConstant: 120)
        readerHeightMin.isActive = true
        rightSplit.addArrangedSubview(listArea)
        rightSplit.addArrangedSubview(reader.view)
        view.addArrangedSubview(treeScroll)
        view.addArrangedSubview(rightSplit)
        view.setHoldingPriority(.defaultLow + 10, forSubviewAt: 0)
        rightSplit.setHoldingPriority(.defaultLow + 10, forSubviewAt: 0)
        view.delegate = self
        rightSplit.delegate = self
        treePane.isHidden = !(AppDelegate.shared?.folderList ?? true)
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
            rightSplit.setPosition(Mailbox.defaultListHeight, ofDividerAt: 0)
        }
    }

    /// View > Folder List turned on or off: the folder pane shown at the width it had, or hidden (folders are then
    /// chosen with Go to Folder); the keyboard leaves the tree when it goes
    func folderListChanged() {
        let shown = AppDelegate.shared?.folderList ?? true
        guard treePane.isHidden == shown else { return }
        if !shown, let window = view.window, let responder = window.firstResponder as? NSView, responder.isDescendant(of: treePane) {
            window.makeFirstResponder(list)
        }
        treePane.isHidden = !shown
        view.adjustSubviews()
        if shown && treePane.frame.width < Mailbox.smallestTree {
            view.setPosition(210, ofDividerAt: 0)
        }
    }

    /// the smallest the folder tree and the message list can be made; the list beside the reader, its width
    private static let smallestTree: CGFloat = 160
    private static let smallestList: CGFloat = 80
    private static let smallestListWidth: CGFloat = 280
    /// the list's height above the reader until the user drags it, and a classic row's
    private static let defaultListHeight: CGFloat = 260
    private static let classicRowHeight: CGFloat = 20
    /// the classic panes' sizes are kept by the split view under this name (not by the UI test)
    private static var classicAutosave: String? { TestHooks.testing ? nil : "ListAndReader" }

    // ---- the layout ----

    /// Classic (the list above the reader, with its columns) or Columns (the list beside the reader, three lines a
    /// row); the selection, the open conversations and the keyboard stay where they were
    func setLayout(_ wanted: PeLayout) {
        guard wanted != layout else { return }
        let columns = wanted == PE_LAYOUT_COLUMNS
        let responder = view.window?.firstResponder
        changingLayout = true
        defer { changingLayout = false }
        if columns {
            let height = rightSplit.arrangedSubviews[0].frame.height
            classicListHeight = height > Mailbox.smallestList + 1 ? height : Mailbox.defaultListHeight
        }
        layout = wanted
        rightSplit.autosaveName = nil
        rightSplit.isVertical = columns
        listHeightMin.isActive = !columns
        readerHeightMin.isActive = !columns
        listWidthMin.isActive = columns
        showColumns(columns)
        rightSplit.adjustSubviews()
        view.layoutSubtreeIfNeeded()
        if columns {
            rightSplit.setPosition(CGFloat(Mailbox.listBesideReader.value), ofDividerAt: 0)
        } else {
            rightSplit.autosaveName = Mailbox.classicAutosave
            rightSplit.setPosition(classicListHeight, ofDividerAt: 0)
        }
        reloadList(keepSelection: true)
        if let responder, view.window?.firstResponder !== responder {
            view.window?.makeFirstResponder(responder)
        }
    }

    /// the list's width beside the reader, kept for the next start (in memory under test)
    private static var listBesideReader = Preference("ListBesideReader", default: 360.0)

    /// the list's columns and headings for Classic, or its one column of three line rows for Columns
    private func showColumns(_ columns: Bool) {
        if columns {
            classicColumns = list.tableColumns
            classicHeader = list.headerView
            classicColumns.forEach { list.removeTableColumn($0) }
            rowColumn.resizingMask = .autoresizingMask
            list.addTableColumn(rowColumn)
            list.headerView = nil
        } else {
            list.removeTableColumn(rowColumn)
            classicColumns.forEach { list.addTableColumn($0) }
            list.headerView = classicHeader
            showSortIndicator()
        }
        list.rowHeight = columns ? MessageRowCell.height : Mailbox.classicRowHeight
        list.gridStyleMask = columns ? .solidHorizontalGridLineMask : []
        sortRow.isHidden = !columns
        sortRowHeight.constant = columns ? 28 : 0
        list.sizeLastColumnToFit()
        updateSortBar()
    }

    // ---- the order of the list ----

    private func setUpSortBar() {
        sortBar.isBordered = false
        sortBar.controlSize = .small
        sortBar.font = .systemFont(ofSize: NSFont.smallSystemFontSize)
        sortBar.setAccessibilityIdentifier("list.sortBy")
        sortBar.translatesAutoresizingMaskIntoConstraints = false
        // the pull-down's own title, then the choices of View > Sort By
        sortBar.addItem(withTitle: "")
        // the menu's own items: they run the commands, and are checked as View > Sort By's are
        for command in Mailbox.sortCommands {
            if command == .sortAscending {
                sortBar.menu?.addItem(.separator())
            }
            if let item = AppDelegate.shared?.item(for: command) {
                item.keyEquivalent = ""
                sortBar.menu?.addItem(item)
            }
        }
        let line = NSBox()
        line.boxType = .separator
        line.translatesAutoresizingMaskIntoConstraints = false
        sortRow.addSubview(sortBar)
        sortRow.addSubview(line)
        sortRow.translatesAutoresizingMaskIntoConstraints = false
        sortRow.isHidden = true
        listArea.addSubview(sortRow)
        sortRowHeight = sortRow.heightAnchor.constraint(equalToConstant: 0)
        NSLayoutConstraint.activate([
            sortBar.leadingAnchor.constraint(equalTo: sortRow.leadingAnchor, constant: 8),
            sortBar.trailingAnchor.constraint(lessThanOrEqualTo: sortRow.trailingAnchor, constant: -8),
            sortBar.centerYAnchor.constraint(equalTo: sortRow.centerYAnchor),
            line.leadingAnchor.constraint(equalTo: sortRow.leadingAnchor),
            line.trailingAnchor.constraint(equalTo: sortRow.trailingAnchor),
            line.bottomAnchor.constraint(equalTo: sortRow.bottomAnchor),
        ])
    }

    private static let sortCommands: [Command] = [.sortDate, .sortFrom, .sortSubject, .sortSize, .sortAscending, .sortDescending]
    static let sortFields: [Command: PeSortField] = [
        .sortDate: PE_SORT_FIELD_DATE, .sortFrom: PE_SORT_FIELD_FROM, .sortSubject: PE_SORT_FIELD_SUBJECT,
        .sortSize: PE_SORT_FIELD_SIZE,
    ]

    /// whether a command of View > Sort By is checked: the field the list is sorted by, and its direction; nil for
    /// another command
    func sortState(_ command: Command) -> Bool? {
        switch command {
        case .sortAscending: return ascending
        case .sortDescending: return !ascending
        default: return Mailbox.sortFields[command].map { $0 == sort }
        }
    }

    /// "Sorted by Date" over the column layout's list (its menu's checks come from validateMenuItem)
    private func updateSortBar() {
        let field = Mailbox.sortFields.first { $0.value == sort }?.key ?? .sortDate
        sortBar.item(at: 0)?.title = Text.uiSortedBy.text(["field": field.label])
    }

    /// View > Sort By a field: the same one keeps its direction, another starts its own way (the core says which)
    func sortBy(_ field: PeSortField) {
        if field != sort {
            ascending = pe_sort_starts_ascending(field)
        }
        sort = field
        applySort()
    }

    /// View > Sort By > Sort Ascending or Sort Descending
    func setAscending(_ up: Bool) {
        ascending = up
        applySort()
    }

    private func applySort() {
        listView.setSort(sort, ascending: ascending)
        showSortIndicator()
        updateSortBar()
        reloadList(keepSelection: true, covering: true)
    }

    private func scrolled(_ document: NSView) -> NSScrollView {
        let scroll = NSScrollView()
        scroll.documentView = document
        scroll.hasVerticalScroller = true
        scroll.hasHorizontalScroller = false
        scroll.autohidesScrollers = true
        return scroll
    }

    // ---- the folder tree ----

    /// a row of the folder tree: the core's row, and the rows under it
    final class TreeNode {
        var row: TreeRow
        var children: [TreeNode] = []
        weak var parent: TreeNode?
        init(_ row: TreeRow) { self.row = row }
        var kind: PeTreeRowKind { row.kind }
    }

    /// the top row that lists `list` (All Inboxes, All Sent, All Drafts, Flagged)
    private func topNode(_ list: PeTreeList) -> TreeNode? {
        topNodes.first { $0.row.folder == 0 && $0.row.list == list }
    }
    private var firstAccount: Int64 { accountOrder.first ?? 0 }

    /// the row of what the list shows: the folder's, or the row of All Inboxes, All Sent, All Drafts or Flagged
    private var selectedNode: TreeNode? {
        if folder != 0 { return folderRows[folder] }
        return shownList == PE_TREE_LIST_NONE ? nil : topNode(shownList)
    }

    /// the core's rows as nodes, each under the nearest row above it that is less deep
    private func build(_ rows: [TreeRow]) {
        topNodes = []
        treeNodes = []
        folderRows = [:]
        var parents: [TreeNode] = []
        for row in rows {
            let node = TreeNode(row)
            parents = Array(parents.prefix(row.depth))
            if let parent = parents.last {
                node.parent = parent
                parent.children.append(node)
            } else {
                topNodes.append(node)
            }
            parents.append(node)
            treeNodes.append(node)
            if row.folder != 0 {
                folderRows[row.folder] = node
            }
        }
    }

    /// the tree built again from the core's rows, the row chosen before chosen again (or its stand-in, as the core
    /// says)
    public func reload() {
        let read = core.folderTree(chosen: selectedNode?.row.key)
        rebuild(read.rows, chosen: read.chosen)
    }

    /// the tree built from `rows`, then the row `chosen` chosen: the one chosen before chooses nothing again, another
    /// (All Inboxes gone, its account's Inbox) is listed; nil with a row chosen before: that folder is gone
    private func rebuild(_ rows: [TreeRow], chosen: Int?) {
        // the row the user chose is the one chosen before, whose node is about to go
        loadPending()
        let before = selectedNode?.row.key
        let all = core.accounts()
        accountInfo = Dictionary(all.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })
        accountOrder = all.map(\.id)
        folderInfo = [:]
        for account in all {
            core.folders(account.id).forEach { folderInfo[$0.id] = $0 }
        }
        build(rows)
        reloading = true
        tree.reloadData()
        openRows.forget(except: accountOrder)
        openAsLeft()
        let node = chosen.map { treeNodes[$0] }
        if let node {
            selectTreeNode(node)
        }
        reloading = false
        if let node, node.row.key != before {
            choose(node)
        } else if before != nil && node == nil {
            // the folder is gone
            show(PE_TREE_LIST_NONE, folder: 0)
        }
        changed()
    }

    /// the counts of the rows again from the core, once a moment after a folder changed however many changed
    private func scheduleCounts() {
        guard countsTimer == nil else { return }
        countsTimer = Timer.scheduledTimer(withTimeInterval: 0.25, repeats: false) { [weak self] _ in
            MainActor.assumeIsolated {
                self?.countsTimer = nil
                self?.updateCounts()
            }
        }
    }

    /// the words and counts of the rows again from the core; rows of another shape (a folder new or gone) build the
    /// tree again
    private func updateCounts() {
        let read = core.folderTree(chosen: selectedNode?.row.key)
        guard read.rows.map({ "\($0.depth) \($0.key)" }) == treeNodes.map({ "\($0.row.depth) \($0.row.key)" }) else {
            rebuild(read.rows, chosen: read.chosen)
            return
        }
        for (node, row) in zip(treeNodes, read.rows) where !row.drawsLike(node.row) {
            node.row = row
            tree.reloadItem(node)
        }
    }

    /// whether a row with rows under it is open: as the user left it (at the last start for a row the core says to
    /// remember, else while the app runs), or as the core says it starts
    private func isOpen(_ node: TreeNode) -> Bool {
        node.row.remembersOpen ? openRows.isOpen(node.row) : openedOrClosed[node.row.key] ?? node.row.startsOpen
    }

    /// the rows opened and closed as the user left them: every row opened from the top down, so each is shown when it
    /// is opened, then those left closed closed from the bottom up
    private func openAsLeft() {
        let parents = treeNodes.filter(\.row.parent)
        parents.forEach { tree.expandItem($0) }
        parents.reversed().filter { !isOpen($0) }.forEach { tree.collapseItem($0) }
    }

    /// the row of `node` in the tree selected, the closed rows above it opened first so the row chosen is never
    /// hidden; that opening is not the user's, so it is not kept
    private func selectTreeNode(_ node: TreeNode) {
        // a row the user chose whose list waits: this one when it is that row (selecting it again changes nothing),
        // else this row instead
        if let pending = pendingNode, !deferChoice {
            if pending === node {
                loadPending()
            } else {
                cancelPending()
            }
        }
        var above: [TreeNode] = []
        var parent = node.parent
        while let row = parent {
            above.insert(row, at: 0)
            parent = row.parent
        }
        revealing = true
        above.filter { !tree.isItemExpanded($0) }.forEach { tree.expandItem($0) }
        revealing = false
        let row = tree.row(forItem: node)
        if row >= 0 {
            tree.selectRowIndexes(IndexSet(integer: row), byExtendingSelection: false)
        }
    }

    func accountName(_ account: Int64) -> String {
        accountInfo[account]?.title ?? Text.uiTheAccount.text
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
        folderInfo[messageFolder != 0 ? messageFolder : folder]?.account ?? firstAccount
    }

    /// the list `list` of a row (with `folder`, its folder's) shown
    private func show(_ list: PeTreeList, folder id: Int64) {
        guard id != folder || list != shownList else {
            changed()
            return
        }
        restorePending = false
        rowAfter = nil
        // the message of the folder before is not this folder's, nor is the search
        folder = id
        shownList = list
        listView.setList(list, folder: id)
        resetFind()
        clearReader()
        arriving = true
        reloadList(keepSelection: false, covering: true)
        changed()
        selectionChanged()
    }

    var selectedName: String {
        // the row chosen, at once, while its list loads
        if let pendingNode { return pendingNode.row.title }
        if searching {
            // where the search looks; what it found is on the search bar
            return findPlace.isEmpty ? Text.uiAllFolders.text : findPlace
        }
        // under All Inboxes an Inbox is told apart by its account: "Inbox - Gmail"
        return selectedNode?.row.title ?? ""
    }

    var counts: String {
        guard listView.active else { return "" }
        return taken(pe_list_counts(total, unread, UInt64(selectedCount), searching)) ?? ""
    }

    var inJunk: Bool {
        if selectedCount > 1 { return summary.in_junk }
        return folderInfo[uid != 0 ? messageFolder : folder]?.specialUse == PE_SPECIAL_USE_JUNK
    }

    /// one message or more selected: the commands of the selection apply. The list of a row chosen that waits to
    /// load has nothing selected yet
    var hasSelection: Bool { !listWaiting && selectedCount > 0 }

    /// exactly one message selected, the one shown: the commands of one message apply (Reply, Print, Source)
    var hasOne: Bool { hasSelection && selectedCount == 1 && uid != 0 }

    var picturesBlocked: Bool { reader.picturesBlocked }

    /// the one message selected could not be downloaded: there is nothing to print, reply to or forward
    var shownFailed: Bool { hasOne && reader.showsFailure }

    /// Reply, Reply All, Forward and Print need the message's body
    static let needsBody: Set<Command> = [.reply, .replyAll, .forward, .print]

    // ---- the message list ----

    /// words typed search every folder of every account (in: narrows that); without, the list is the folder's, or
    /// every Inbox's
    private var searching: Bool { listView.searching }

    /// whether the list has messages of several folders: a search, or All Inboxes (with a Folder column)
    private var severalFolders: Bool { listView.severalFolders }

    /// the Subject title over the subjects, which make room for the triangles while grouped
    private func indentSubjectHeader() {
        guard let column = list.tableColumn(withIdentifier: NSUserInterfaceItemIdentifier(ColumnID.subject.rawValue)),
              let header = column.headerCell as? IndentedHeaderCell else { return }
        let indent = grouped ? SubjectCell.glyph - SubjectCell.inset : 0
        guard header.indent != indent else { return }
        header.indent = indent
        list.headerView?.needsDisplay = true
    }

    /// Settings > Group messages by conversation
    var grouped: Bool { listView.grouped }

    private enum ColumnID: String, CaseIterable {
        case attach, flag, secure, from, subject, received, folder

        /// a column of a mark alone, its icon in its header: a fixed width, and a click sorts nothing
        var isIcon: Bool { [.attach, .flag, .secure].contains(self) }

        /// the icon in the header of a mark's column, and what its tooltip says (nil: the header says it in words)
        @MainActor var header: (icon: NSImage?, tip: String?)? {
            switch self {
            case .attach: (Icons.list("attach"), Text.uiRowAttachments.text)
            case .flag: (Icons.list("flag"), Text.uiRowFlagged.text)
            case .secure: (Icons.encrypted, Text.headerSecurity.text)
            case .from, .subject, .received, .folder: nil
            }
        }
    }

    private func setUpList() {
        list.dataSource = self
        list.delegate = self
        list.mailbox = self
        list.usesAlternatingRowBackgroundColors = true
        list.allowsMultipleSelection = true
        list.allowsColumnReordering = false
        list.rowHeight = Mailbox.classicRowHeight
        list.style = .fullWidth
        list.target = self
        list.doubleAction = #selector(openSelected)
        list.setAccessibilityIdentifier("list")
        // .eml files from the Finder onto the list go into the folder shown
        list.registerForDraggedTypes([.fileURL])
        list.setDraggingSourceOperationMask([.move, .copy], forLocal: true)
        // out of the app: files where they are dropped, the messages stay
        list.setDraggingSourceOperationMask(.copy, forLocal: false)
        promiseWriter.wrote = { [weak self] dir, problem in self?.wroteFile(dir, problem) }
        let columns: [(ColumnID, String, CGFloat)] = [
            // no envelope, Watch or Size column: bold says a message is unread, the menus say a conversation is watched,
            // and the subject gets the room
            (.attach, "", 22), (.flag, "", 22), (.secure, "", 22), (.from, Text.uiColFrom.text, 200), (.subject, Text.headerSubject.text, 420),
            (.received, Text.uiColReceived.text, 130),
        ]
        for (id, title, width) in columns {
            list.addTableColumn(makeColumn(id, title: title, width: width))
        }
        // the paper clip and the flag in their headers, as Outlook Express has them (a header cell does not draw the
        // image of a column without a title on its own)
        // an icon alone in a header does not say what the column is: its tooltip does, the same word on every platform
        for id in ColumnID.allCases {
            guard let mark = id.header, let image = mark.icon,
                  let column = list.tableColumn(withIdentifier: NSUserInterfaceItemIdentifier(id.rawValue)) else { continue }
            let header = IconHeaderCell(textCell: "")
            header.icon = image
            column.headerCell = header
            column.headerToolTip = mark.tip
        }
        showSortIndicator()
    }

    private func makeColumn(_ id: ColumnID, title: String, width: CGFloat) -> NSTableColumn {
        let column = NSTableColumn(identifier: NSUserInterfaceItemIdentifier(id.rawValue))
        if id == .subject {
            column.headerCell = IndentedHeaderCell(textCell: title)
        }
        column.title = title
        column.width = width
        if id.isIcon {
            column.minWidth = width
            column.maxWidth = width
            column.resizingMask = []
        } else {
            column.minWidth = 40
            // the Subject column alone follows the width of the list, so a long subject gets the room
            column.resizingMask = id == .subject ? [.autoresizingMask, .userResizingMask] : .userResizingMask
        }
        return column
    }

    /// the Folder column while the list has messages of several folders, and not otherwise; in All Inboxes, whose rows
    /// are all in an Inbox, the Account column
    private func showFolderColumn() {
        // the column layout's rows name the folder themselves
        guard layout == PE_LAYOUT_CLASSIC else { return }
        let title = listView.gathersAccounts ? Text.uiColAccount.text : Text.uiColFolder.text
        list.tableColumn(withIdentifier: NSUserInterfaceItemIdentifier(ColumnID.folder.rawValue))?.title = title
        guard severalFolders != folderColumn else { return }
        folderColumn = severalFolders
        // Subject, then From, give the Folder column its room, and get it back: the list stays as wide as its pane, and
        // Received stays whole
        let id = NSUserInterfaceItemIdentifier(ColumnID.folder.rawValue)
        let givers = [ColumnID.subject, .from].compactMap { list.tableColumn(withIdentifier: NSUserInterfaceItemIdentifier($0.rawValue)) }
        if folderColumn {
            let column = makeColumn(.folder, title: title, width: 130)
            // its width and the gap a column adds
            var needed = column.width + list.intercellSpacing.width
            folderRoom = givers.map { giver in
                let given = min(needed, max(0, giver.width - 100))
                giver.width -= given
                needed -= given
                return given
            }
            list.addTableColumn(column)
            // after Subject, before Received, as the Windows list has it at its end
            if let at = list.tableColumns.firstIndex(of: column),
               let received = list.tableColumns.firstIndex(where: { $0.identifier.rawValue == ColumnID.received.rawValue }) {
                list.moveColumn(at, toColumn: received)
            }
        } else if let column = list.tableColumn(withIdentifier: id) {
            for (giver, given) in zip(givers, folderRoom) {
                giver.width += given
            }
            folderRoom = []
            list.removeTableColumn(column)
        }
    }

    /// From, or To in Sent Items and Drafts (the core says which, and sorts a From sort by the recipients there): its
    /// title and its values follow, and the date column is Sent there, as Outlook Express names it
    private func showPersonColumn(_ wanted: Bool) {
        guard wanted != recipientsColumn else { return }
        recipientsColumn = wanted
        for (id, title) in [(ColumnID.from, wanted ? Text.uiColTo : Text.uiColFrom),
                            (ColumnID.received, wanted ? Text.uiColSent : Text.uiColReceived)] {
            list.tableColumn(withIdentifier: NSUserInterfaceItemIdentifier(id.rawValue))?.title = title.text
        }
    }

    /// the folder of a row in a list of several folders: its name, with its account's when there are several accounts;
    /// in All Inboxes the account alone, as the tree names it
    private func rowFolder(_ id: Int64) -> String {
        guard let info = folderInfo[id] else { return "" }
        if listView.gathersAccounts {
            return accountInfo[info.account]?.title ?? ""
        }
        var text = info.name
        if accountInfo.count > 1 {
            text += " (\(accountName(info.account)))"
        }
        return text
    }

    /// the list read again off the window thread (`ListReady`), the newest reading winning, then drawn; `then` once it
    /// is. `keepSelection`: the same list, what is selected selected again where it is now (the core finds it);
    /// `covering`: another list, order or grouping, the list before dimmed (and taking no clicks) until it is drawn
    func reloadList(keepSelection: Bool, covering: Bool = false, then: (() -> Void)? = nil) {
        // a reading gathered after a change is this one
        reloadTimer?.invalidate()
        let loading = listRequest != 0
        loadKeepsSelection = keepSelection && (!loading || loadKeepsSelection)
        loadCovers = covering || (loading && loadCovers)
        if let then {
            whenListed.append(then)
        }
        pageRequests = [:]
        choseWhileLoading = false
        listRequest = startLoad()
        if listRequest == 0 {
            listFailed()
            return
        }
        updateCover()
    }

    /// the load of the list asked for with what is selected now, for the core to select it again where it is: the
    /// message shown nearest the row it had, several, Select All; the row after a removal or what Undo brought back
    /// in their place
    private func startLoad() -> UInt64 {
        let (after, restored) = (rowAfter ?? -1, restorePending)
        guard loadKeepsSelection && selectedCount > 0 else {
            return core.load(listView, selection: nil, after: after, restored: restored, arrived: arriving)
        }
        guard !allSelected && selectedCount == 1 && uid != 0 else {
            return core.load(listView, selection: selection, after: after, restored: restored)
        }
        // the message shown alone, not the rest of a closed conversation whose row it is
        keptInSight = list.rows(in: list.visibleRect).contains(list.selectedRow)
        let shown = newSelection([(messageFolder, uid)])
        defer { pe_selection_free(shown) }
        return core.load(listView, selection: shown, hint: list.selectedRow, after: after, restored: restored)
    }

    /// a list that could not be read: the one before stays, nothing waits for it any more
    private func listFailed() {
        listRequest = 0
        loadCovers = false
        whenListed = []
        updateCover()
    }

    /// `ListReady`: the newest reading of the list drawn, with what waited for it; an older one dropped, one the user
    /// selected rows during read again
    private func listReady(_ request: UInt64) {
        guard request == listRequest else {
            _ = core.loadResult(request)
            return
        }
        guard !choseWhileLoading else {
            _ = core.loadResult(request)
            reloadList(keepSelection: true)
            return
        }
        let load = core.loadResult(request, selection: selection)
        guard case .read(let rows)? = load else {
            if case .failed(let why)? = load {
                status(why)
            }
            listFailed()
            return
        }
        listRequest = 0
        loadCovers = false
        let waiting = whenListed
        whenListed = []
        drawList(rows)
        updateCover()
        changed()
        waiting.forEach { $0() }
    }

    /// the list as `load` read it: its counts, its rows from the first page, the place column, the selection
    private func drawList(_ load: ListRows) {
        dateClock = DateClock()
        showsPictures = AppDelegate.shared?.listPictures ?? true
        pictureScale = list.window?.backingScaleFactor ?? 2
        // the core counts them: a folder from its indexes, a search, All Inboxes and a folder without its ignored
        // conversations what they find; an account lists nothing. Grouped by conversation the list has fewer rows than
        // messages
        (total, unread, rows) = (load.total, load.unread, load.rows)
        pages = [(load.offset, load.messages)]
        showFolderColumn()
        showPersonColumn(load.listsRecipients)
        indentSubjectHeader()
        reloading = true
        list.reloadData()
        reloading = false
        updateEmptyText()
        updateSearchBar()
        reselect(after: load)
    }

    /// the rows `load` selects selected, the selection (copied from the load) what it says: Select All counted again,
    /// the messages kept where they are now (one shown stays shown, without a flicker of the reading pane), or a new
    /// selection (what Undo brought back, the row after a removal)
    private func reselect(after load: ListRows) {
        rowAfter = nil
        if load.reselection == PE_RESELECTION_RESTORED {
            restorePending = false
        }
        let all = load.reselection == PE_RESELECTION_ALL && rows > 0
        // the message the list showed when it was left, or its newest: not when the app chose one to show meanwhile
        let passed = load.reselection == PE_RESELECTION_ARRIVED && !arriving
        arriving = false
        reloading = true
        list.selectRowIndexes(all ? IndexSet(integersIn: 0..<numberOfRows(in: list)) : passed ? IndexSet() : load.selected,
                              byExtendingSelection: false)
        // the message kept is scrolled to only when it was in sight: else the list stays where the user scrolled it
        let stays = load.reselection == PE_RESELECTION_KEPT
        if load.focus >= 0 && !passed && (!stays || keptInSight) {
            list.scrollRowToVisible(load.focus)
        }
        reloading = false
        if all {
            // the same Select All, counted again: not a new one that would take mail stored since
            selectWholeList(again: true)
            return
        }
        allSelected = false
        // grouped, one row may stand for a closed conversation, whose messages the selection takes again
        let kept = load.reselection == PE_RESELECTION_KEPT && (selectedCount > 1 || !grouped)
        selectionDidChange(same: kept)
    }

    /// `ListPageReady`: a page of the list drawn in the rows that waited for it (one of a list before dropped)
    private func pageReady(_ request: UInt64) {
        let load = core.loadResult(request)
        guard pageRequests.removeValue(forKey: request) != nil, case .read(let page)? = load else { return }
        if pages.count >= 16 { pages.removeFirst() }
        pages.append((page.offset, page.messages))
        let end = min(Int(page.offset) + page.messages.count, numberOfRows(in: list))
        guard Int(page.offset) < end else { return }
        let rows = IndexSet(integersIn: Int(page.offset)..<end)
        list.reloadData(forRowIndexes: rows, columnIndexes: IndexSet(integersIn: 0..<list.numberOfColumns))
        // the message selected whose row was not here yet: shown now
        if list.numberOfSelectedRows == 1 && rows.contains(list.selectedRow) && selectedRow?.uid != uid {
            selectionDidChange()
        }
    }

    /// the page of the list with row `offset` asked for, and the page after it, when they are not here or asked for;
    /// nothing while the whole list is being read (its rows are drawn when it is here)
    private func askForPage(_ offset: UInt64) {
        guard listRequest == 0 else { return }
        for wanted in [offset, offset + pageSize] where wanted < rows && !pageRequests.values.contains(wanted)
            && !pages.contains(where: { $0.offset == wanted }) {
            let request = core.loadPage(listView, offset: wanted)
            if request != 0 {
                pageRequests[request] = wanted
            }
        }
    }

    /// `block` once the list being read is drawn, at once when none is; whether it waits
    @discardableResult
    func afterListed(_ block: @escaping () -> Void) -> Bool {
        guard listRequest != 0 else {
            block()
            return false
        }
        whenListed.append(block)
        return true
    }


    /// a sender's picture is drawn: the rows on screen that show it get it, the list is not loaded again
    private func pictureArrived(_ picture: UInt64) {
        guard layout == PE_LAYOUT_COLUMNS else { return }
        let shown = list.rows(in: list.visibleRect)
        let rows = IndexSet((shown.location..<shown.location + shown.length).filter { row($0)?.picture == picture })
        if !rows.isEmpty {
            list.reloadData(forRowIndexes: rows, columnIndexes: IndexSet(integer: 0))
        }
    }

    /// Settings' list pictures turned on or off: the rows drawn again
    func listPicturesChanged() {
        showsPictures = AppDelegate.shared?.listPictures ?? true
        if layout == PE_LAYOUT_COLUMNS {
            list.reloadData()
        }
    }

    /// a row as drawn: its message when its page is here, nil while it is not, asking for nothing (what a test looks
    /// at, so that looking does not fill a row the window left blank)
    func drawnRow(_ index: Int) -> Message? {
        guard index >= 0, UInt64(index) < rows else { return nil }
        let offset = UInt64(index) / pageSize * pageSize
        guard let page = pages.first(where: { $0.offset == offset }) else { return nil }
        let row = Int(UInt64(index) - offset)
        return row < page.rows.count ? page.rows[row] : nil
    }

    /// whether the rows drawn are the list as the core reads it now (the deep test's quiet): whatever is still on
    /// its way to the window leaves them other than the core reads them
    func drawnCurrent() -> Bool {
        let sight = list.rows(in: list.visibleRect)
        let end = min(sight.location + sight.length, Int(rows))
        var drawn: [PeDrawnRow] = []
        if sight.location < end {
            for row in sight.location..<end {
                let m = drawnRow(row)
                drawn.append(PeDrawnRow(row: UInt64(row), folder: m?.folder ?? 0, uid: m?.uid ?? 0))
            }
        }
        return pe_list_view_drawn_current(core.handle, listView.handle, rows, drawn, drawn.count)
    }

    func row(_ index: Int) -> Message? {
        guard index >= 0, UInt64(index) < rows else { return nil }
        let offset = UInt64(index) / pageSize * pageSize
        guard let at = pages.firstIndex(where: { $0.offset == offset }) else {
            // not here yet: a blank row until its page is read off the window thread
            askForPage(offset)
            return nil
        }
        // the most recently used page goes last, the least recently used is dropped first
        let page = pages.remove(at: at)
        pages.append(page)
        let row = Int(UInt64(index) - offset)
        return row < page.rows.count ? page.rows[row] : nil
    }

    /// whether the row `index` is here to show (its page read)
    private func rowLoaded(_ index: Int) -> Bool {
        let offset = UInt64(max(index, 0)) / pageSize * pageSize
        return pages.contains { $0.offset == offset }
    }

    /// the one selected message; nil when none or several are
    var selectedRow: Message? { list.numberOfSelectedRows == 1 ? row(list.selectedRow) : nil }

    /// the selection as the core keeps it: the row of one, the positions of several (found by the core in one go)
    private func updateSelection() {
        let rows = list.selectedRowIndexes
        pe_selection_clear(selection)
        // grouped, a row may stand for a collapsed conversation's messages, which the core finds from its range
        if rows.count == 1, !grouped, let row = row(rows.first!) {
            pe_selection_add(selection, row.folder, row.uid)
        } else if rows.count > 0 {
            core.select(Array(rows.rangeView), of: listView, into: selection)
        }
        updateSummary()
    }

    private func updateSummary() {
        // the whole list's is summed up off the window thread
        guard !allSelected else { return }
        summary = PeSelectionSummary()
        if selectedCount > 0 {
            _ = pe_selection_summary(core.handle, selection, &summary)
        }
    }

    /// Select All: every row selected and the whole list the selection, counted at once without listing it; what the
    /// menus need to know of it (unread, flagged, in Junk) comes off the window thread
    func selectAllMessages() {
        guard rows > 0 else { return }
        list.window?.makeFirstResponder(list)
        allSelected = true
        reloading = true
        list.selectRowIndexes(IndexSet(integersIn: 0..<numberOfRows(in: list)), byExtendingSelection: false)
        reloading = false
        selectWholeList()
    }

    /// the selection the whole list, its summary asked for; the reading pane says how many once it is here. `again`:
    /// the selection is Select All already (the list load counted it again), its summary asked for again
    private func selectWholeList(again: Bool = false) {
        guard again || pe_list_view_select_all(core.handle, listView.handle, selection) else { return }
        // a summary asked for before is of another list: what waited for it is dropped with it
        if summaryRequest != 0 {
            pe_read_cancel(core.handle, summaryRequest)
            whenSummed = []
        }
        let request = pe_selection_summary_start(core.handle, selection)
        summaryRequest = request
        summary = PeSelectionSummary()
        summary.count = numericCast(pe_selection_count(selection))
        if !reader.showsSummary {
            clearReader()
        }
        Pending.read(request, by: self) { [weak self] in self?.summed(request) }
        selectionChanged()
    }

    /// the summary of Select All `request` is here: the reading pane says it, what waited for it runs; dropped when it
    /// failed (never run on a later one) or another selection came since
    private func summed(_ request: UInt64) {
        guard request == summaryRequest else { return }
        summaryRequest = 0
        var numbers = PeSelectionSummary()
        guard allSelected, pe_selection_summary_result(core.handle, request, &numbers) else {
            whenSummed = []
            return
        }
        summary = numbers
        reader.showSummary(numbers)
        selectionChanged()
        let waiting = whenSummed
        whenSummed = []
        waiting.forEach { $0() }
    }

    /// the summary of the whole list not here yet: what needs it waits
    var summaryWaiting: Bool { allSelected && summaryRequest != 0 }

    /// `block` kept for when the summary of the whole list is here, while it is read; false (nothing kept) when it is
    /// here, the caller going on at once
    private func afterSummary(_ block: @escaping () -> Void) -> Bool {
        guard summaryWaiting else { return false }
        whenSummed.append(block)
        return true
    }

    private var whenSummed: [() -> Void] = []

    /// the messages of the selection, listed when it is the whole list's (the rare command that needs each one)
    private func listedSelection() -> OpaquePointer {
        if pe_selection_is_all(selection) {
            _ = pe_selection_list(core.handle, selection)
        }
        return selection
    }

    fileprivate func sortBy(_ column: NSTableColumn) {
        let field: PeSortField
        switch ColumnID(rawValue: column.identifier.rawValue) {
        // the marks' columns sort nothing, as Windows' do
        case .attach, .flag, .secure: return
        case .from: field = PE_SORT_FIELD_FROM
        case .subject: field = PE_SORT_FIELD_SUBJECT
        default: field = PE_SORT_FIELD_DATE
        }
        // the same column again turns the order around; another starts its own way
        ascending = field == sort ? !ascending : pe_sort_starts_ascending(field)
        sort = field
        applySort()
    }

    private func showSortIndicator() {
        let sorted: ColumnID?
        switch sort {
        case PE_SORT_FIELD_FROM: sorted = .from
        case PE_SORT_FIELD_SUBJECT: sorted = .subject
        // no column of sizes: no column shows the order
        case PE_SORT_FIELD_SIZE: sorted = nil
        default: sorted = .received
        }
        for column in list.tableColumns {
            let image = column.identifier.rawValue == sorted?.rawValue
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
        // the lines as long as one another, set in updateEmptyText; the scroll's width still wins when narrower
        emptyMoreWidth.priority = .defaultHigh
        emptyMoreWidth.isActive = true
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
                title = Text.uiNoMatch.text(["words": findText])
                more = findPlace.isEmpty ? Text.uiNoMatchAll.text
                                         : Text.uiNoMatchIn.text(["folder": findPlace])
                let left = core.unindexedCount
                if left > 0 {
                    more += "\n\n" + Text.macStillIndexingMore.text(["count": left])
                }
            } else if shownList != PE_TREE_LIST_NONE {
                title = AppDelegate.shared?.hideRead == true ? Text.uiNoUnread.text : Text.uiNoItems.text
            }
        }
        emptyTitle.stringValue = title
        emptyMore.stringValue = more
        emptyTitle.isHidden = title.isEmpty
        emptyMore.isHidden = more.isEmpty
        emptyMoreWidth.constant = evenWidth(more, font: emptyMore.font, widest: Mailbox.emptyTextWidth)
        // the stripes of empty rows would run through the text; the column layout's rows have lines between them instead
        list.usesAlternatingRowBackgroundColors = total != 0 && layout == PE_LAYOUT_CLASSIC
    }

    /// the narrowest width that wraps `text` into as few lines as `widest` does, so no line is left with a lone word
    private func evenWidth(_ text: String, font: NSFont?, widest: CGFloat) -> CGFloat {
        guard !text.isEmpty else { return widest }
        let attributed = NSAttributedString(string: text, attributes: [.font: font ?? NSFont.systemFont(ofSize: 13)])
        func height(_ width: CGFloat) -> CGFloat {
            attributed.boundingRect(with: NSSize(width: width, height: .greatestFiniteMagnitude),
                                    options: [.usesLineFragmentOrigin, .usesFontLeading]).height.rounded(.up)
        }
        let lines = height(widest)
        var low: CGFloat = 40
        var high = widest
        while high - low > 2 {
            let middle = (low + high) / 2
            if height(middle) > lines { low = middle } else { high = middle }
        }
        // a little room, as the field's own insets wrap a hair sooner than the measure
        return min(widest, high.rounded(.up) + 8)
    }

    // ---- searching ----

    func find(_ typed: String) {
        // what only has spaces finds everything, as the core reads it
        let text = typed.trimmingCharacters(in: CharacterSet(charactersIn: " \t"))
        guard text != findText else { return }
        findText = text
        findPlace = Core.searchPlace(text)
        listView.setText(text)
        reloadList(keepSelection: true, covering: true)
        changed()
    }

    private func resetFind() {
        findText = ""
        findPlace = ""
        listView.setText("")
        AppDelegate.shared?.main?.searchCleared()
    }

    func clearFind() {
        guard !findText.isEmpty else { return }
        resetFind()
        reloadList(keepSelection: true, covering: true)
        changed()
        list.window?.makeFirstResponder(list)
    }

    private func updateSearchBar() {
        var summary = ""
        if searching {
            // what was found, for what, where: the words stay in view while the list changes under them
            summary = findPlace.isEmpty ? Text.macResultsEverywhere.text(["count": total, "words": findText])
                                        : Text.macResultsIn.text(["count": total, "words": findText, "folder": findPlace])
            let left = core.unindexedCount
            if left > 0 {
                summary += "  \u{00B7}  " + Text.macStillIndexing.text(["count": left])
            }
        }
        searchBar.text = summary
        searchBar.isHidden = summary.isEmpty
        searchBar.heightConstraint?.constant = summary.isEmpty ? 0 : 26
    }

    // ---- the reading pane ----

    private func clearReader(loading: Bool = false) {
        openWhenReady = false
        markReadTimer?.invalidate()
        reader.clear(loading: loading)
    }

    /// `same`: the list was reloaded with the same messages selected, whose numbers alone may have changed
    fileprivate func selectionDidChange(same: Bool = false) {
        guard !reloading else { return }
        // Select All's rows still all selected: its selection and summary stand
        if allSelected && list.numberOfSelectedRows == numberOfRows(in: list) && rows > 0 {
            return
        }
        allSelected = false
        whenSummed = []
        if summaryRequest != 0 {
            pe_read_cancel(core.handle, summaryRequest)
            summaryRequest = 0
        }
        if same {
            updateSummary()
        } else {
            updateSelection()
        }
        // several: none of them is opened (or marked read); the pane says how many
        if selectedCount > 1 {
            if !reader.showsSummary {
                clearReader()
            }
            reader.showSummary(summary)
            selectionChanged()
            return
        }
        // the row's page is still being read: the message shown stays until it is here (pageReady)
        if list.numberOfSelectedRows == 1 && !rowLoaded(list.selectedRow) {
            askForPage(UInt64(list.selectedRow) / pageSize * pageSize)
            selectionChanged()
            return
        }
        let row = selectedRow
        let newUid = row?.uid ?? 0
        let newFolder = row?.folder ?? 0
        if newUid == uid && newFolder == messageFolder && !reader.showsSummary {
            selectionChanged()
            return
        }
        clearReader(loading: newUid != 0)
        if newUid != 0 {
            // for the list to open with it when it is come back to
            core.listShown(listView, folder: newFolder, uid: newUid)
            reader.open(folder: newFolder, uid: newUid, account: folderAccount(newFolder), row: row)
        }
        // after the message is the reader's: Reply and Print ask for it
        selectionChanged()
    }

    /// whether the folder `id` is an account's Inbox
    func isInbox(_ id: Int64) -> Bool {
        folderInfo[id]?.specialUse == PE_SPECIAL_USE_INBOX
    }

    /// the name of the folder `id`, with its account's when there are several accounts
    func folderName(_ id: Int64) -> String {
        guard let info = folderInfo[id] else { return "" }
        return accountInfo.count > 1 ? info.name + " (\(accountName(info.account)))" : info.name
    }

    /// what the folder `id` is: its name, its use, whether it can be renamed
    func info(ofFolder id: Int64) -> Folder? {
        folderInfo[id]
    }

    /// the account of the folder `id`, 0 when there is none
    func folderAccount(_ id: Int64) -> Int64 {
        folderInfo[id]?.account ?? 0
    }

    /// fetched now: a draft that was double-clicked before opens
    private func messageArrived() {
        if openWhenReady {
            openWhenReady = false
            openSelected()
        }
    }

    private func messageShown() {
        // read after a moment on screen, not while the user moves through the list
        markReadTimer?.invalidate()
        markReadTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: false) { [weak self] _ in
            MainActor.assumeIsolated {
                guard let self, let row = self.selectedRow, row.uid == self.uid, !row.seen else { return }
                // the message shown alone, not the rest of a closed conversation whose row it is
                let shown = newSelection([(row.folder, row.uid)])
                defer { pe_selection_free(shown) }
                self.act(PE_ACTION_READ, on: shown, quiet: true)
            }
        }
    }

    func loadPictures() {
        reader.loadPictures()
    }

    /// the message (`folder`, `uid`) in its folder, selected; the folder ends a search
    func showMessage(folder id: Int64, uid message: UInt64) {
        guard let node = folderRows[id] else { return }
        // All Inboxes (All Sent, All Drafts) stays when it has the message, its list up to date with it
        if listView.gathersAccounts {
            reloadList(keepSelection: true) { [weak self] in
                guard let self, !selectInList(folder: id, uid: message) else { return }
                showInFolder(node, folder: id, uid: message)
            }
            return
        }
        showInFolder(node, folder: id, uid: message)
    }

    /// the message (`folder`, `uid`) selected in its folder's list, once that is read
    private func showInFolder(_ node: TreeNode, folder id: Int64, uid message: UInt64) {
        // another folder selected ends a search; the folder selected already is not selected again, its search is
        // ended here
        if searching && folder == id {
            clearFind()
        }
        selectTreeNode(node)
        afterListed { [weak self] in
            guard let self, folder == id else { return }
            selectInList(folder: id, uid: message)
        }
    }

    // ---- reading with the keyboard ----

    /// Next Message and Previous Message: the row below (`step` 1) or above (-1) selected, shown as a click shows it;
    /// with none selected the first
    func selectNeighbour(_ step: Int) {
        guard list.numberOfRows > 0 else { return }
        let rows = list.selectedRowIndexes
        let at = rows.isEmpty ? 0 : (step > 0 ? rows.last! : rows.first!) + step
        guard at >= 0 && at < list.numberOfRows else { return }
        list.selectRowIndexes(IndexSet(integer: at), byExtendingSelection: false)
        list.scrollRowToVisible(at)
    }

    /// Next Unread Message (N in the list): the next unread message after the one shown, or from the top; with none
    /// left, the next folder with unread mail is offered, as Outlook Express does
    func nextUnread() {
        switch core.nextUnread(listView, folder: messageFolder, uid: uid) {
        case .message(let folder, let uid):
            selectInList(folder: folder, uid: uid)
        case .ask(let next, let question):
            guard ask(question, style: .information), let node = folderRows[next] else { return }
            clearFind()
            selectTreeNode(node)
            // from the top of that folder's list, which the core may answer with another question
            if case .message(let folder, let uid) = core.nextUnread(listView, folder: 0, uid: 0) {
                selectInList(folder: folder, uid: uid)
            }
        case .none:
            status(Text.noUnreadLeft.text)
        }
    }

    // ---- conversations ----

    /// the conversation of `row` opened (`open`) or closed; closed from a message under it, its row is selected
    func setExpanded(_ open: Bool, row index: Int) {
        guard grouped, let message = row(index), message.thread != 0, open != listView.isExpanded(message.thread) else {
            return
        }
        if open {
            guard message.opens, listView.expand(message.thread) else { return }
        } else {
            guard listView.collapse(message.thread) else { return }
        }
        // the message shown stays selected, or the conversation's row that now stands for it
        reloadList(keepSelection: true)
    }

    /// Right on the list: the selected conversation opened; Left: closed, from its row or a message under it. False
    /// when there is nothing to do, for the list to take the key
    func openOrClose(_ open: Bool) -> Bool {
        guard grouped, list.numberOfSelectedRows == 1, let message = row(list.selectedRow), message.thread != 0 else {
            return false
        }
        if open && !message.collapsed { return false }
        if !open && !(message.opens && message.threadExpanded) && message.threadDepth == 0 { return false }
        setExpanded(open, row: list.selectedRow)
        return true
    }

    /// View > Expand All Conversations
    func expandAll() {
        guard core.expandAll(listView) else { return }
        reloadList(keepSelection: true, covering: true)
    }

    /// View > Collapse All Conversations
    func collapseAll() {
        guard listView.collapseAll() else { return }
        reloadList(keepSelection: true, covering: true)
    }

    /// View > Hide Ignored Conversations turned on or off
    func hideIgnoredChanged() {
        listView.setHideIgnored(AppDelegate.shared?.hideIgnored ?? false)
        reloadList(keepSelection: true, covering: true)
        changed()
    }

    /// View > Hide Read Messages or the toolbar's Unread filter turned on or off
    func hideReadChanged() {
        listView.setUnreadOnly(AppDelegate.shared?.hideRead ?? false)
        reloadList(keepSelection: true, covering: true)
        changed()
    }

    /// grouping turned on or off in Settings: the list again, the message shown still selected
    func groupingChanged() {
        listView.setGrouped(AppDelegate.shared?.groupByConversation ?? true)
        reloadList(keepSelection: true, covering: true)
        changed()
    }

    /// the folder `id` shown, a search ended
    func goToFolder(_ id: Int64) {
        guard let node = folderRows[id] else { return }
        clearFind()
        selectTreeNode(node)
    }

    /// Go to Folder: the folders of every account to choose one of, as Move to Folder shows them
    func chooseFolder() {
        let window = MoveWindow(core: core, title: Command.goToFolder.labelText.title, prompt: Text.uiGoToPrompt.text, verb: Text.uiOk.text, current: 0,
                                canMakeFolders: false)
        if let chosen = window.run() {
            goToFolder(chosen)
            list.window?.makeFirstResponder(list)
        }
    }

    /// the row of the message `uid` of `folder` selected in the list, its conversation opened when it hides it; false
    /// when it is not there
    @discardableResult
    private func selectInList(folder id: Int64, uid message: UInt64) -> Bool {
        arriving = false
        // the list being read: selected once it is drawn
        if listRequest != 0 {
            afterListed { [weak self] in self?.selectInList(folder: id, uid: message) }
            return true
        }
        if core.reveal(listView, folder: id, uid: message) {
            reloadList(keepSelection: true) { [weak self] in self?.selectInList(folder: id, uid: message) }
            return true
        }
        let index = core.messageIndex(listView, folder: id, uid: message)
        guard index >= 0 else { return false }
        list.selectRowIndexes(IndexSet(integer: Int(index)), byExtendingSelection: false)
        list.scrollRowToVisible(Int(index))
        list.window?.makeFirstResponder(list)
        return true
    }

    /// the window shown the first time: All Inboxes (two or more accounts) or the first account's Inbox chosen, and its
    /// newest message selected
    func selectStart() {
        guard !started else { return }
        started = true
        // the row the app was closed on, its list opening with the message it showed (the core selects it)
        if shownList == PE_TREE_LIST_NONE, let key = core.treeStart(), let node = treeNodes.first(where: { $0.row.key == key }) {
            startWith(node)
            return
        }
        guard shownList == PE_TREE_LIST_NONE, let start = core.startMessage(),
              let node = start.allInboxes ? topNode(PE_TREE_LIST_ALL_INBOXES) : folderRows[start.folder] else { return }
        startWith(node) { [weak self] in self?.selectInList(folder: start.folder, uid: start.uid) }
    }

    /// the row `node` chosen at the start, the window drawn with the tree first and the list after, as a click does;
    /// `then` once the list is there
    private func startWith(_ node: TreeNode, then: (() -> Void)? = nil) {
        deferChoice = true
        selectTreeNode(node)
        deferChoice = false
        if pendingNode === node {
            pendingThen = then
        } else {
            // the row was selected already: nothing waits
            choose(node)
            then?()
        }
    }

    // ---- paint first ----

    /// the row `node` chosen by the user: selected in the tree, named in the title and the list before dimmed at once,
    /// drawn, then its list loaded on a later turn of the run loop. The window is drawn and committed to the screen
    /// first, as the load holds the main thread; a timer of the run loop runs after that (and in modal sessions, unlike
    /// the main queue), and another row chosen before it fired replaces it
    private func chooseAfterPaint(_ node: TreeNode) {
        pendingTimer?.invalidate()
        pendingNode = node
        pendingThen = nil
        coverList(true)
        changed()
        if TestHooks.testing {
            paintOrder.append("selected \(node.row.key)")
        }
        view.window?.displayIfNeeded()
        CATransaction.flush()
        guard !(TestHooks.testing && holdPending) else { return }
        pendingTimer = after(0) { [weak self] in self?.loadPending() }
    }

    /// the list of the row the user chose loaded now, when it waits (a command or a rebuilt tree does not wait for it)
    func loadPending() {
        guard let node = pendingNode else { return }
        let then = pendingThen
        // the list before stays dimmed while the chosen one is read (until its ListReady)
        dropPending()
        if TestHooks.testing {
            paintOrder.append("loading \(node.row.key)")
        }
        choose(node)
        if let then {
            // the app shows a message of its own in it
            arriving = false
            afterListed(then)
        }
        afterListed { [weak self] in
            if TestHooks.testing {
                self?.paintOrder.append("loaded \(node.row.key)")
            }
        }
        updateCover()
    }

    /// the row the user chose no longer waits for its list: another was chosen
    private func cancelPending() {
        dropPending()
        updateCover()
    }

    private func dropPending() {
        pendingTimer?.invalidate()
        pendingTimer = nil
        pendingNode = nil
        pendingThen = nil
    }

    /// the list before dimmed while a row chosen waits, and while another list (order, grouping) is read
    private func updateCover() {
        coverList(pendingNode != nil || (listRequest != 0 && loadCovers))
    }

    /// the list is being read off the window thread
    var listLoading: Bool { listRequest != 0 }

    /// whether the list is the one before, dimmed while another loads
    var listCovered: Bool { !listCover.isHidden }

    /// a row chosen whose list has not loaded yet, or another list being read: nothing is selected in it yet
    var listWaiting: Bool { pendingNode != nil || (listRequest != 0 && loadCovers) }

    /// the list before covered while another loads; "Loading..." counted from the first row chosen of the wait, so
    /// rows chosen one after another while it waits do not start it again
    private func coverList(_ on: Bool) {
        guard on != listCovered else { return }
        loadingTimer?.invalidate()
        loadingTimer = nil
        listCover.loading = false
        listCover.isHidden = !on
        guard on else { return }
        loadingTimer = after(Mailbox.loadingWait) { [weak self] in self?.listCover.loading = true }
    }

    /// the waits of the list, the same in the three apps: changes gathered before the list is read again, and how
    /// long a list chosen waits before it says "Loading..."
    static let gatherWait = TimeInterval(PE_LIST_GATHER_MS) / 1000
    static let loadingWait = TimeInterval(PE_LIST_LOADING_MS) / 1000

    // ---- the message's own actions ----

    /// a copy of the list as it is shown, one row a message: what Previous and Next of a message's window go through
    func listCopy() -> ListView? {
        guard let copy = listView.copy() else { return nil }
        copy.setGrouped(false)
        return copy
    }

    /// Enter or a double-click: the message in a window of its own, a draft in the compose window to be finished
    @objc func openSelected() {
        guard uid != 0 else { return }
        guard folderInfo[messageFolder]?.specialUse == PE_SPECIAL_USE_DRAFTS else {
            MessageWindow.open(core: core, mailbox: self, folder: messageFolder, uid: uid)
            return
        }
        // read off the window thread, the compose window opened once it is
        let (folder, message, account) = (messageFolder, uid, currentAccount)
        let request = pe_draft_open_start(core.handle, folder, message)
        let idle = Pending.busy(status)
        let waits = Pending.read(request, by: self) { [weak self] in
            idle()
            guard let self else { return }
            guard let draft = Draft(pe_draft_result(core.handle, request)) else {
                // not fetched yet: MessageReady follows, if it is still the one shown
                openWhenReady = (messageFolder, uid) == (folder, message)
                return
            }
            ComposeWindow.open(core: core, account: account, draft: draft)
        }
        if !waits {
            idle()
        }
    }

    /// `action` on `messages` (the selected ones by default), off the window thread: once the store has it, what was
    /// done in the status bar, or why not, and the list read again, the selection kept
    @discardableResult
    private func act(_ action: PeAction, to: Int64 = 0, on messages: OpaquePointer? = nil, quiet: Bool = false) -> Bool {
        apply(action, to: to, on: messages, quiet: quiet) { [weak self] in self?.listChanged(keepSelection: true) }
    }

    /// `action` started as `act` starts it, then `done` once the store has it (not when it was refused); false when it
    /// could not start
    private func apply(_ action: PeAction, to: Int64 = 0, on messages: OpaquePointer? = nil, quiet: Bool = false,
                       then done: @escaping () -> Void) -> Bool {
        let request = core.actStart(messages ?? selection, action, to: to)
        guard Pending.acted(request, by: self, { [weak self] event in self?.acted(event, quiet: quiet, then: done) }) else {
            inform(Text.uiMessagesNotChanged.text, style: .warning)
            return false
        }
        return true
    }

    /// `Acted`: what was done in the status bar (not for `quiet`, the message shown read after a moment), then
    /// `done`; why not in a window when it was refused
    private func acted(_ event: CoreEvent, quiet: Bool, then done: () -> Void) {
        if event.failure == PE_FAILURE_KIND_OTHER {
            inform(event.message.isEmpty ? Text.uiMessagesNotChanged.text : event.message, style: .warning)
            return
        }
        if !quiet {
            status(event.message)
        }
        done()
    }

    /// `ActionUndone`: the server refused what was asked and the store took it back (the rows are back through the
    /// FolderChanged before it); the bar over the list says what and why, until it is closed
    private func showUndone(_ message: String?) {
        let shown = !(message ?? "").isEmpty
        undoneBar.text = message ?? ""
        undoneBar.isHidden = !shown
        undoneBar.heightConstraint?.isActive = !shown
    }

    /// what the bar over the list says the server refused, empty when it is closed (the UI test)
    var undoneText: String { undoneBar.isHidden ? "" : undoneBar.text }

    /// the user's own command changed the list: read again at once, not a moment later when its change is reported
    /// (that reload then finds the list read)
    private func listChanged(keepSelection: Bool) {
        reloadList(keepSelection: keepSelection)
        changed()
    }

    /// `quiet`: the shown message read after a moment on screen, which the status bar does not announce
    func markSelected(seen: Bool, quiet: Bool = false) {
        guard hasSelection else { return }
        act(seen ? PE_ACTION_READ : PE_ACTION_UNREAD, quiet: quiet)
    }

    /// Mark All Read applies to the list shown (the core says): a folder's or All Inboxes'
    var marksAllRead: Bool { listView.marksAllRead }

    /// the folder's messages, or every Inbox's, marked read off the window thread
    func markAllRead() {
        guard listView.marksAllRead else { return }
        let own = listView.ownFolder
        markAllRead(own != 0 ? PE_MARK_READ_FOLDER : PE_MARK_READ_ALL_INBOXES, own)
    }

    /// Mark All Read of `what` (`id` the folder or the account): what was done in the status bar, the list read again
    private func markAllRead(_ what: PeMarkRead, _ id: Int64) {
        let request = pe_mark_read_start(core.handle, what, id)
        let waits = Pending.acted(request, by: self) { [weak self] event in
            self?.acted(event, quiet: false) { self?.listChanged(keepSelection: true) }
        }
        if !waits {
            inform(Text.uiMessagesNotChanged.text, style: .warning)
        }
    }

    /// `action` takes the selected messages out of the list: the row after the last of them is selected then
    @discardableResult
    private func actAndRemove(_ action: PeAction, to: Int64 = 0, on messages: OpaquePointer? = nil) -> Bool {
        let next = (list.selectedRowIndexes.last ?? -1) + 1 - selectedCount
        return apply(action, to: to, on: messages) { [weak self] in self?.selectAfterRemoval(next) }
    }

    /// every selected message can be archived (from the Inbox or a folder of the user's)
    var canArchive: Bool { hasSelection && summary.archivable }

    /// out of the Inbox into the account's Archive (on Gmail every label taken off)
    func archiveSelected() {
        if afterSummary({ [weak self] in self?.archiveSelected() }) { return }
        guard canArchive else { return }
        actAndRemove(PE_ACTION_ARCHIVE)
    }

    /// Watch Conversation (`PE_ACTION_WATCH`) or Ignore Conversation (`PE_ACTION_IGNORE`): the conversations of the
    /// selected messages watched, or ignored and read, or no longer when all of them are. The core says whether that
    /// takes them out of the list (Ignore while ignored conversations are hidden)
    func markConversations(_ action: PeAction) {
        guard hasSelection else { return }
        if afterSummary({ [weak self] in self?.markConversations(action) }) { return }
        if leavesList(action) {
            actAndRemove(action)
        } else {
            act(action)
        }
    }

    /// whether `action` takes the selected messages out of the list, as the core says from the selection now
    private func leavesList(_ action: PeAction, to: Int64 = 0) -> Bool {
        updateSummary()
        return listView.leavesList(summary, action, to: to)
    }

    /// the text of the rows of an ignored conversation: grey, as what is turned off is
    static let ignoredColor = NSColor.tertiaryLabelColor

    /// a row's text colour; on the accent of a selected row a grey one is white, dimmed a little, so it can be read
    static func rowColor(grey: Bool, style: NSView.BackgroundStyle) -> NSColor {
        guard grey else { return .labelColor }
        return style == .emphasized ? NSColor.alternateSelectedControlTextColor.withAlphaComponent(0.7) : ignoredColor
    }

    func markJunk(_ junk: Bool) {
        guard hasSelection else { return }
        actAndRemove(junk ? PE_ACTION_JUNK : PE_ACTION_NOT_JUNK)
    }

    /// flags them all unless all are flagged, then takes the flag off all
    func flagSelected() {
        guard hasSelection else { return }
        act(PE_ACTION_TOGGLE_FLAG)
    }


    /// flags the selected messages in a colour (1 red to 7 gray)
    func flagSelected(color: UInt8) {
        guard hasSelection else { return }
        act(PE_ACTION_FLAG_COLOR, to: Int64(color))
    }

    /// takes flag and colour off the selected messages
    func clearFlag() {
        guard hasSelection else { return }
        act(PE_ACTION_UNFLAG)
    }

    /// after messages left the list: the one that took their place selected by the load, or the last one
    private func selectAfterRemoval(_ index: Int) {
        rowAfter = index >= 0 ? index : nil
        listChanged(keepSelection: true)
    }

    func deleteSelected() {
        guard hasSelection else { return }
        // from Deleted Items it asks first, which the summary says
        if afterSummary({ [weak self] in self?.deleteSelected() }) { return }
        // from Deleted Items, or an account without one, they are gone for good: asked first
        if let question = taken(pe_selection_delete_question(&summary)),
           !ask(question, yes: Text.uiTbDelete.text, no: Text.uiCancel.text, destructive: true) {
            return
        }
        actAndRemove(PE_ACTION_DELETE)
    }

    /// Move to Folder, or Copy to Folder (`copy`): the window of every account's folders; to another account they go in
    /// the background (the status bar says how far)
    func moveSelected(copy: Bool = false) {
        guard hasSelection else { return }
        if afterSummary({ [weak self] in self?.moveSelected(copy: copy) }) { return }
        let verb = copy ? Text.uiButtonCopy.text : Text.uiButtonMove.text
        let title = taken(pe_selection_move_text(&summary, copy, false)) ?? verb
        let prompt = taken(pe_selection_move_text(&summary, copy, true)) ?? ""
        // the folder they are all in can not be chosen
        let current = summary.folders == 1 ? firstSelected?.folder ?? listView.ownFolder : 0
        let window = MoveWindow(core: core, title: title, prompt: prompt, verb: verb, current: current)
        guard let to = window.run() else { return }
        if copy {
            act(PE_ACTION_COPY, to: to)
        } else {
            actAndRemove(PE_ACTION_MOVE, to: to)
        }
    }

    /// the selection moved to the folder `to`, as Move to Folder does once a folder is chosen in its window (the deep
    /// test's driver chooses it without the window)
    func moveSelection(to: Int64) {
        guard hasSelection else { return }
        if afterSummary({ [weak self] in self?.moveSelection(to: to) }) { return }
        _ = actAndRemove(PE_ACTION_MOVE, to: to)
    }

    /// the first selected message, which tells the account of them all
    private var firstSelected: (folder: Int64, uid: UInt64)? {
        var folder: Int64 = 0
        var uid: UInt64 = 0
        return pe_selection_get(selection, 0, &folder, &uid) ? (folder, uid) : nil
    }

    func undo() {
        // the last thing done was sending a message that still waits: Undo Send
        if pe_undo_is_send(core.handle) {
            undoSend?()
            return
        }
        switch core.undo() {
        case .success(let done):
            status(done)
            restorePending = true
            rowAfter = nil
            listChanged(keepSelection: true)
        case .failure(let refusal):
            inform(refusal.reason, style: .warning)
        }
    }

    // ---- folders ----

    /// New Folder applies where the row selected says it does
    var canMakeFolder: Bool { (selectedNode?.row.newFolderAccount ?? 0) != 0 }

    /// a new folder where the row selected says: in its folder, or at the top of its account
    func newFolder() {
        guard let row = selectedNode?.row, row.newFolderAccount != 0 else { return }
        newFolder(in: row.newFolderAccount, under: row.newFolderParent)
    }

    /// a new folder in `account`, under the folder `parent` (0: at the top of the account)
    func newFolder(in account: Int64, under parent: Int64) {
        guard account != 0 else { return }
        let where_ = parent != 0 ? Text.uiNewFolderInSelected.text : Text.uiNewFolderAtTop.text
        guard let name = askFolderName(title: Text.uiNewFolderTitle.text, intro: where_, name: ""), !name.isEmpty else { return }
        var reason: UnsafeMutablePointer<CChar>?
        if !name.withCString({ pe_folder_create(core.handle, account, parent, $0, &reason) }) {
            refused(reason, Text.uiFolderNotCreated.text)
        }
    }

    /// the menu of an account's heading (a right-click on it): Send and Receive and Mark All Read of that account, New
    /// Folder at its top, Move Up and Move Down in the accounts' order, its Properties
    func accountMenu(_ account: Int64) -> NSMenu {
        let menu = NSMenu()
        menu.autoenablesItems = false
        // the count its heading is drawn with collapsed: nothing unread, nothing to mark
        let someUnread = treeNodes.first { $0.kind == PE_TREE_ROW_KIND_ACCOUNT && $0.row.account == account }
            .map { $0.row.countCollapsed > 0 } ?? false
        let items: [(String, Selector, Bool)?] = [
            (Text.uiAccountSync.text, #selector(accountMenuSync(_:)), true),
            (Command.markAllRead.label, #selector(accountMenuMarkRead(_:)), someUnread),
            nil,
            (Command.newFolder.label, #selector(accountMenuNewFolder(_:)), true),
            nil,
        ] + moveItems(account) + [
            nil,
            (Text.uiAccountProperties.opens, #selector(accountMenuProperties(_:)), true),
        ]
        addItems(items, to: menu, account: account)
        return menu
    }

    /// Move Up and Move Down of an account in the accounts' order, greyed at the ends
    private func moveItems(_ account: Int64) -> [(String, Selector, Bool)?] {
        let place = accountOrder.firstIndex(of: account) ?? 0
        return [
            (Text.uiAccountMoveUp.text, #selector(accountMenuMoveUp(_:)), place > 0),
            (Text.uiAccountMoveDown.text, #selector(accountMenuMoveDown(_:)), place < accountOrder.count - 1),
        ]
    }

    /// the items of an account's commands (nil a separator), each carrying the account
    private func addItems(_ items: [(String, Selector, Bool)?], to menu: NSMenu, account: Int64) {
        for entry in items {
            guard let (title, action, enabled) = entry else {
                menu.addItem(.separator())
                continue
            }
            let item = NSMenuItem(title: title, action: action, keyEquivalent: "")
            item.target = self
            item.isEnabled = enabled
            item.representedObject = NSNumber(value: account)
            menu.addItem(item)
        }
    }

    private func menuAccount(_ sender: NSMenuItem) -> Int64 {
        (sender.representedObject as? NSNumber)?.int64Value ?? 0
    }

    @objc private func accountMenuSync(_ sender: NSMenuItem) {
        core.sync(menuAccount(sender))
    }

    @objc private func accountMenuMarkRead(_ sender: NSMenuItem) {
        markAllRead(PE_MARK_READ_ACCOUNT, menuAccount(sender))
    }

    @objc private func accountMenuNewFolder(_ sender: NSMenuItem) {
        newFolder(in: menuAccount(sender), under: 0)
    }

    @objc private func accountMenuMoveUp(_ sender: NSMenuItem) {
        moveAccount(menuAccount(sender), by: -1)
    }

    @objc private func accountMenuMoveDown(_ sender: NSMenuItem) {
        moveAccount(menuAccount(sender), by: 1)
    }

    /// the account one place up (-1) or down (1) in the accounts' order
    private func moveAccount(_ account: Int64, by step: Int) {
        guard let place = accountOrder.firstIndex(of: account) else { return }
        moveAccount(account, to: place + step)
    }

    /// the account put at `place` in the accounts' order, which the tree and All Inboxes' rows then follow; the
    /// selection stays where it was
    func moveAccount(_ account: Int64, to place: Int) {
        guard place >= 0, place < accountOrder.count, pe_account_move(core.handle, account, UInt32(place)) else { return }
        reload()
    }

    @objc private func accountMenuProperties(_ sender: NSMenuItem) {
        let account = menuAccount(sender)
        if accountProperties(core: core, account: account) {
            reload()
            core.sync(account)
        }
    }

    func renameFolder() {
        guard folder != 0, let info = folderInfo[folder], !info.fixed else { return }
        let current = info.name
        guard let name = askFolderName(title: Text.uiRenameFolderTitle.text, intro: Text.uiRenameFolderIntro.text(["folder": current]),
                                       name: current),
              !name.isEmpty, name != current else { return }
        var reason: UnsafeMutablePointer<CChar>?
        if !name.withCString({ pe_folder_rename(core.handle, folder, $0, &reason) }) {
            refused(reason, Text.uiFolderNotRenamed.text)
        }
    }

    func deleteFolder() {
        guard folder != 0, let info = folderInfo[folder], !info.fixed else { return }
        guard ask(Text.uiDeleteFolderQuestion.text(["folder": info.name]),
                  yes: Text.uiTbDelete.text, no: Text.uiCancel.text, destructive: true) else { return }
        var reason: UnsafeMutablePointer<CChar>?
        if !pe_folder_delete(core.handle, folder, &reason) {
            refused(reason, Text.uiFolderNotDeleted.text)
        }
    }

    /// what to ask before emptying the folder shown (Deleted Items or Junk E-mail with messages), nil when Empty
    /// Folder does not apply
    var canEmptyFolder: Bool {
        folderInfo[listView.ownFolder]?.emptiable == true && total > 0
    }

    /// Deleted Items or Junk E-mail emptied for good, after asking (the core words the question, with how many go)
    func emptyFolder() {
        let folder = listView.ownFolder
        guard canEmptyFolder, let question = taken(pe_folder_empty_question(core.handle, folder)),
              ask(question, yes: Text.uiEmptyButton.text, no: Text.uiCancel.text, destructive: true) else { return }
        var reason: UnsafeMutablePointer<CChar>?
        if let done = taken(pe_folder_empty(core.handle, folder, &reason)) {
            status(done)
        } else {
            refused(reason, Text.uiMessagesNotChanged.text)
        }
    }

    /// the menu of the row selected (a right-click in the tree), as the row says: none (Flagged), Mark All Read alone
    /// (All Inboxes), or a folder's: Mark All Read, New, Rename, Delete, and Empty Folder for Deleted Items and Junk
    /// E-mail; an account's Inbox under All Inboxes adds Move Up and Move Down of its account
    func folderMenu() -> NSMenu? {
        guard let row = selectedNode?.row, row.menu == PE_TREE_MENU_MARK_READ || row.menu == PE_TREE_MENU_FOLDER else {
            return nil
        }
        let menu = NSMenu()
        let editable = !(folderInfo[row.folder]?.fixed ?? true)
        var folderCommands: [(Command, Bool)] = row.menu == PE_TREE_MENU_FOLDER
            ? [(.newFolder, row.newFolderAccount != 0), (.renameFolder, editable), (.deleteFolder, editable)] : []
        // Deleted Items and Junk E-mail can be emptied, as in Outlook Express
        if row.menu == PE_TREE_MENU_FOLDER && folderInfo[row.folder]?.emptiable == true {
            folderCommands.append((.emptyFolder, canEmptyFolder))
        }
        for (command, enabled) in [(Command.markAllRead, row.unread > 0)] + folderCommands {
            let item = NSMenuItem(title: command.label, action: #selector(folderMenuItem(_:)), keyEquivalent: "")
            item.target = self
            item.tag = command.rawValue
            item.isEnabled = enabled
            menu.addItem(item)
            // Empty Folder in a group of its own, under the folder commands
            if command == .markAllRead && !folderCommands.isEmpty || command == .deleteFolder && folderCommands.last?.0 == .emptyFolder {
                menu.addItem(.separator())
            }
        }
        if row.reordersAccounts {
            menu.addItem(.separator())
            addItems(moveItems(row.account), to: menu, account: row.account)
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
        if selectedCount > 1 {
            saveSelected()
            return
        }
        saveMessageAs(folder: messageFolder, uid: uid)
    }

    /// the message `uid` of `folder` saved as an .eml file where the user chooses
    func saveMessageAs(folder id: Int64, uid message: UInt64) {
        guard message != 0 else { return }
        var length = 0
        var name: UnsafeMutablePointer<CChar>?
        let data = takenBytes(pe_message_source(core.handle, id, message, &length, &name), length)
        let safeName = taken(name) ?? "message.eml"
        guard let data else {
            inform(Text.uiNotDownloaded.text)
            return
        }
        if let url = saveFilePanel(name: safeName, title: Text.uiSaveMessageAs.text, types: [.emailMessage]),
           !writeDownloaded(data, to: url) {
            inform(Text.uiNotSaved.text, style: .error)
        }
    }

    func showProperties() {
        showProperties(folder: messageFolder, uid: uid, subject: reader.subject)
    }

    /// the internet headers of the message `uid` of `folder`, whose subject is `subject`
    func showProperties(folder id: Int64, uid message: UInt64, subject: String) {
        guard message != 0 else {
            inform(Text.uiSelectMessageFirst.text)
            return
        }
        guard let headers = taken(pe_message_headers(core.handle, id, message)) else {
            inform(Text.uiNotDownloaded.text)
            return
        }
        textDialog(title: subject.isEmpty ? Text.uiProperties.text : Text.uiPropertiesOf.text(["subject": subject]),
                   intro: Text.uiInternetHeaders.text,
                   text: headers)
    }

    /// View Source: the whole message as the server has it
    func showSource() {
        showSource(folder: messageFolder, uid: uid)
    }

    /// View Source of the message `uid` of `folder`
    func showSource(folder id: Int64, uid message: UInt64) {
        guard message != 0 else {
            inform(Text.uiSelectMessageFirst.text)
            return
        }
        var title: UnsafeMutablePointer<CChar>?
        let source = taken(pe_message_source_text(core.handle, id, message, &title))
        let name = taken(title) ?? Text.messageSourceUntitled.text
        guard let source else {
            inform(Text.uiNotDownloaded.text)
            return
        }
        // Save As from here saves the message shown, as File > Save As does
        let save = ButtonAction(Command.saveAs.label, id: "source.save") { [weak self] in self?.saveMessageAs(folder: id, uid: message) }
        // the key of File > Save As
        save.button.keyEquivalent = "s"
        save.button.keyEquivalentModifierMask = [.command, .shift]
        textDialog(title: name, intro: nil, text: source, ok: Text.uiClose.text, id: "source", size: NSSize(width: 760, height: 560),
                   action: save)
    }

    /// the right-click menu of the message list: the actions on the message, as Outlook Express has them, with the
    /// choices that fit it (Mark as Unread for a read one, Not Junk in Junk E-mail)
    func messageMenu() -> NSMenu? {
        guard hasSelection else { return nil }
        let message = selectedRow
        let menu = NSMenu()
        func add(_ command: Command, _ title: String? = nil) {
            let item = NSMenuItem(title: title ?? command.label, action: #selector(AppDelegate.runCommand(_:)), keyEquivalent: "")
            item.tag = command.rawValue
            item.target = AppDelegate.shared
            item.setAccessibilityIdentifier("menu.\(command)")
            menu.addItem(item)
        }
        if message != nil {
            let open = NSMenuItem(title: Text.uiMenuOpen.text, action: #selector(openSelected), keyEquivalent: "")
            open.target = self
            menu.addItem(open)
            menu.addItem(.separator())
        }
        add(.reply)
        add(.replyAll)
        add(.forward)
        menu.addItem(.separator())
        // several: read if any is unread; Flag in a colour or Clear Flag (the toggle is the Message menu's, by its key)
        add(summary.unread > 0 ? .markRead : .markUnread)
        menu.addItem(AppDelegate.shared.flagMenu())
        // whether the conversations are watched or ignored: the check marks say it, as the list has no column for it
        add(.watchConversation)
        menu.items.last?.state = summary.watched ? .on : .off
        add(.ignoreConversation)
        menu.items.last?.state = summary.ignored ? .on : .off
        add(.archive)
        add(inJunk ? .notJunk : .junk)
        if message != nil {
            add(.createRuleFromMessage)
        }
        add(.move)
        add(.copy)
        add(.delete, Text.uiTbDelete.text)
        menu.addItem(.separator())
        add(.saveAs)
        add(.print)
        menu.addItem(.separator())
        add(.viewSource, Text.uiMenuViewSource.text)
        add(.properties)
        if message != nil {
            menu.addItem(.separator())
            add(.addSenderToBook)
        }
        return menu
    }

    /// Create Rule from Message: the editor with a new rule for the sender of the message shown, or its mailing list
    func createRuleFromMessage() {
        guard uid != 0 else { return }
        let query = taken(pe_rule_query_of_message(core.handle, messageFolder, uid)) ?? ""
        RuleEditor.create(core: core, query: query)
    }

    /// the search bar's Create Rule: the editor with a new rule for the words searched for
    @objc private func createRuleFromSearch() {
        RuleEditor.create(core: core, query: findText)
    }

    /// Add Sender to Address Book for the message shown, what was done in the status bar
    func addSenderToBook() {
        guard uid != 0 else { return }
        status(addSenderToAddressBook(core: core, folder: messageFolder, uid: uid))
    }

    func printShown() {
        reader.print()
    }

    /// the folder Import Messages puts messages in: the one listed, not a list of several folders
    var importFolder: Int64 { listView.ownFolder }

    func importMessages() {
        let folder = importFolder
        guard folder != 0 else {
            inform(Text.uiImportChooseFolder.text, title: Text.macImportMessages.text)
            return
        }
        importFiles(openFilesPanel(title: Text.macImportMessages.text, types: [.emailMessage, .data]), into: folder)
    }

    /// files into `folder` as Import Messages puts them: the message files, what the core says of the others shown
    func importFiles(_ files: [URL], into folder: Int64) {
        guard !files.isEmpty else { return }
        let paths = files.map { strdup($0.path) }
        defer { paths.forEach { free($0) } }
        var said: UnsafeMutablePointer<CChar>?
        var report: UnsafeMutablePointer<CChar>?
        let ok = paths.map { UnsafePointer($0) }.withUnsafeBufferPointer {
            pe_import_files(core.handle, folder, $0.baseAddress, paths.count, &said, &report)
        }
        // what went in in the status bar, what did not in a window
        if let said = taken(said) {
            status(said)
        }
        if let report = taken(report) {
            inform(report, title: Text.macImportMessages.text, style: ok ? .information : .warning)
        }
    }

    /// Save As with several selected: a folder to save them in, each as an .eml file named after its subject, never
    /// over a file there
    func saveSelected() {
        guard let dir = folderPanel(title: Text.macSaveMessages.text) else { return }
        withDownloads(title: Text.macSaveMessages.text, { core, selection, error in
            takenTexts(dir.path.withCString { pe_selection_save(core, selection, $0, exportTimeout, &error) })
        }, then: { [weak self] written in
            for path in written {
                markFromInternet(URL(fileURLWithPath: path))
            }
            self?.status(dir.path.withCString { taken(pe_saved_text(UInt64(written.count), $0)) } ?? "")
        })
    }

    /// Forward with several selected: one new message with them attached as .eml files, from the account of the first,
    /// once those not downloaded yet are here
    func forwardSelected(_ open: @escaping @MainActor (Draft, Int64) -> Void) {
        guard let first = refs(of: listedSelection()).first else { return }
        let account = folderInfo[first.0]?.account ?? currentAccount
        withDownloads(title: Text.uiTbForward.text, { core, selection, error in
            Handed(value: pe_selection_forward(core, selection, exportTimeout, &error))
        }, then: { draft in
            if let made = Draft(draft.value) {
                open(made, account)
            }
        })
    }

    /// `work` on the selected messages on a thread of its own, once those not downloaded yet are here ("Downloading 3
    /// messages..." in the status bar meanwhile), then `done` with what it made; the core's reason shown when it
    /// refused
    private func withDownloads<T>(title: String,
                                  _ work: @escaping (OpaquePointer, OpaquePointer, inout UnsafeMutablePointer<CChar>?) -> T,
                                  then done: @escaping @MainActor (T) -> Void) {
        let selection = Handed(value: newSelection(refs(of: listedSelection())))
        let handle = Handed(value: core.handle)
        if let downloading = taken(pe_selection_downloading_text(core.handle, selection.value)) {
            status(downloading)
        }
        inBackground({ () -> (T, String?) in
            defer { pe_selection_free(selection.value) }
            var error: UnsafeMutablePointer<CChar>?
            let made = work(handle.value, selection.value, &error)
            return (made, taken(error))
        }, then: { [weak self] made, problem in
            if let problem {
                self?.status("")
                inform(problem, title: title, style: .warning)
                return
            }
            done(made)
        })
    }

    /// a file of a drag out of the list was written into `dir`, or could not be
    private func wroteFile(_ dir: URL?, _ problem: String?) {
        // a drop on the Finder runs on, so what went wrong goes in the status bar rather than a window per file
        if let problem {
            status(problem)
            return
        }
        guard let dir else { return }
        dragWritten += 1
        status(dir.path.withCString { taken(pe_saved_text(UInt64(dragWritten), $0)) } ?? "")
    }

    /// the files the drag out of the list offers, one per message: the selection when the row is selected, else the row
    /// alone (the Finder asks for each row's writer as the drag starts)
    func promise(forRow index: Int) -> MessagePromise? {
        guard let message = row(index) else { return nil }
        let ref = (message.folder, message.uid)
        if dragExport == nil || !(dragExport!.refs.contains { $0 == ref }) {
            dragExport = DragExport(core: core.handle, refs: dragRefs(forRow: index))
            dragWritten = 0
        }
        guard let drag = dragExport, let at = drag.refs.firstIndex(where: { $0 == ref }) else { return nil }
        return MessagePromise(drag: drag, index: at, delegate: promiseWriter)
    }

    /// the messages a drag from the row `index` carries, in the list's order: the selection's when the row is selected,
    /// else the row's; a closed conversation's row all of its messages, as the core's selection has them
    private func dragRefs(forRow index: Int) -> [(Int64, UInt64)] {
        if list.selectedRowIndexes.contains(index) {
            return refs(of: listedSelection())
        }
        let one: OpaquePointer = pe_selection_new()
        defer { pe_selection_free(one) }
        core.select([index..<index + 1], of: listView, into: one)
        return refs(of: one)
    }

    /// the items of a drag out of the list made whole: the list gives one a row, and a closed conversation's row
    /// stands for several messages, whose others are added (one file each for the Finder, one message each for a
    /// folder of the tree)
    func completeDrag(_ items: [NSDraggingItem]) -> [NSDraggingItem] {
        let promises = items.compactMap { $0.item as? MessagePromise }
        guard let drag = promises.first?.drag, promises.allSatisfy({ $0.drag === drag }) else { return items }
        let covered = Set(promises.map(\.index))
        guard covered.count < drag.refs.count, var frame = items.first?.draggingFrame else { return items }
        // a dragging item refuses an empty frame
        if frame.isEmpty {
            frame.size = NSSize(width: 1, height: 1)
        }
        let more = (0..<drag.refs.count).filter { !covered.contains($0) }.map { at in
            let item = NSDraggingItem(pasteboardWriter: MessagePromise(drag: drag, index: at, delegate: promiseWriter))
            // under the rows dragged, without a picture of their own
            item.setDraggingFrame(frame, contents: nil)
            return item
        }
        return items + more
    }

    /// the drag out of the list ended: the next one names its own files
    func dragEnded() {
        dragExport = nil
    }

    /// the writer of the files the Finder was promised, for the UI test to write them as a drop on the Finder does
    var filePromises: PromiseWriter { promiseWriter }

    /// the answer to a one-click unsubscribe from the reading pane, in words; nil for another's
    func unsubscribed(_ request: UInt64, problem: String) -> String? {
        reader.unsubscribed(request, problem: problem)
    }

    // ---- dragging a message onto a folder ----

    /// the folder messages dragged from `folders` may go to: a folder of their account that holds messages, not the one
    /// they all are in
    func dropTarget(_ item: Any?, from folders: [Int64]) -> Int64? {
        // a folder of any account that holds messages, not the one they are all in
        guard let row = (item as? TreeNode)?.row, row.dropTarget, row.folder != 0, !folders.isEmpty,
              folders.contains(where: { $0 != row.folder }) else { return nil }
        return row.folder
    }

    /// the dragged messages into `to`: a drag of selected rows carries the selection (NSTableView drags what is selected),
    /// which then leaves the list as Move leaves it
    @discardableResult
    func drop(_ messages: [(Int64, UInt64)], to: Int64, copy: Bool) -> Bool {
        let dragged = newSelection(messages)
        defer { pe_selection_free(dragged) }
        if copy {
            return act(PE_ACTION_COPY, to: to, on: dragged)
        }
        // from this list when they are what is selected here
        if messages.count == pe_selection_count(selection), let first = messages.first, let selected = firstSelected,
           first.0 == selected.folder && first.1 == selected.uid {
            return actAndRemove(PE_ACTION_MOVE, to: to, on: dragged)
        }
        return act(PE_ACTION_MOVE, to: to, on: dragged)
    }

    // ---- the core's events ----

    /// the list read again in a moment, once for however many changes come meanwhile; not when the user's own command
    /// read it since
    private func gatherReload() {
        guard reloadTimer?.isValid != true else { return }
        reloadTimer = after(Mailbox.gatherWait) { [weak self] in
            guard let self, core.stale(listView) else { return }
            reloadList(keepSelection: true)
            changed()
        }
    }

    func onEvent(_ event: CoreEvent) {
        switch event.kind {
        case PE_EVENT_KIND_PICTURE_READY:
            pictures.ready(event.uid)
        case PE_EVENT_KIND_FOLDERS_CHANGED:
            reload()
        case PE_EVENT_KIND_FOLDER_CHANGED:
            scheduleCounts()
            // a list of several folders has messages of any of them. The changes of a sync are gathered for a moment
            // and the list read once, not after each; not at all when the user's own command read it since
            if (event.folder == folder && !searching) || severalFolders {
                gatherReload()
            }
        case PE_EVENT_KIND_LIST_READY:
            listReady(event.uid)
        case PE_EVENT_KIND_LIST_PAGE_READY:
            pageReady(event.uid)
        case PE_EVENT_KIND_ACTION_UNDONE:
            // the status bar's "Moved..." is taken back with it
            status("")
            showUndone(event.message)
            // the messages back in the list now, and selected there as what Undo brings back is
            restorePending = true
            rowAfter = nil
            listChanged(keepSelection: true)
        case PE_EVENT_KIND_SYNC_FINISHED:
            // how much text the search still has to read
            updateSearchBar()
        default:
            break
        }
        reader.onEvent(event)
    }
}

// ---- the tree's rows ----

extension Mailbox: NSOutlineViewDataSource, NSOutlineViewDelegate {
    private func children(_ item: Any?) -> [TreeNode] {
        (item as? TreeNode)?.children ?? (item == nil ? topNodes : [])
    }

    public func outlineView(_ outlineView: NSOutlineView, numberOfChildrenOfItem item: Any?) -> Int {
        children(item).count
    }

    public func outlineView(_ outlineView: NSOutlineView, child index: Int, ofItem item: Any?) -> Any {
        children(item)[index]
    }

    public func outlineView(_ outlineView: NSOutlineView, isItemExpandable item: Any) -> Bool {
        !children(item).isEmpty
    }

    /// An account is a heading over its folders, as in Mail: it opens and closes, and is never selected, so it is not
    /// taken for a mailbox. All Inboxes, above them, is a mailbox row like the folders.
    public func outlineView(_ outlineView: NSOutlineView, isGroupItem item: Any) -> Bool {
        (item as? TreeNode)?.kind == PE_TREE_ROW_KIND_ACCOUNT
    }

    public func outlineView(_ outlineView: NSOutlineView, shouldSelectItem item: Any) -> Bool {
        (item as? TreeNode)?.row.selectable == true
    }

    /// a click on an account's heading opens or closes it
    @objc private func treeClicked(_ sender: Any?) {
        headingClicked(tree.clickedRow)
    }

    /// opens or closes the account heading at `row`, when there is one there
    func headingClicked(_ row: Int) {
        guard row >= 0, let account = tree.item(atRow: row) as? TreeNode, account.kind == PE_TREE_ROW_KIND_ACCOUNT else { return }
        if tree.isItemExpanded(account) {
            tree.animator().collapseItem(account)
        } else {
            tree.animator().expandItem(account)
        }
    }

    public func outlineView(_ outlineView: NSOutlineView, viewFor tableColumn: NSTableColumn?, item: Any) -> NSView? {
        guard let node = item as? TreeNode else { return nil }
        let row = node.row
        // collapsed, a row adds the unread messages of the rows it hides
        let collapsed = row.parent && !outlineView.isItemExpanded(node)
        if row.kind == PE_TREE_ROW_KIND_ACCOUNT {
            let heading = (outlineView.makeView(withIdentifier: HeadingCell.identifier, owner: nil) as? HeadingCell) ?? HeadingCell()
            heading.show(name: row.label, count: row.count(collapsed: collapsed))
            heading.setAccessibilityIdentifier("tree.account.\(row.account)")
            return heading
        }
        let cell = (outlineView.makeView(withIdentifier: FolderCell.identifier, owner: nil) as? FolderCell) ?? FolderCell()
        cell.show(name: row.label, count: row.count(collapsed: collapsed), icon: Icons.folder(Icons.treeIcon(row.icon)),
                  bold: row.bold(collapsed: collapsed), spoken: row.title)
        cell.setAccessibilityIdentifier(treeIdentifier(row))
        return cell
    }

    private func treeIdentifier(_ row: TreeRow) -> String {
        switch row.kind {
        case PE_TREE_ROW_KIND_ALL_INBOXES: return "tree.allInboxes"
        case PE_TREE_ROW_KIND_ALL_SENT: return "tree.allSent"
        case PE_TREE_ROW_KIND_ALL_DRAFTS: return "tree.allDrafts"
        case PE_TREE_ROW_KIND_FLAGGED: return "tree.flagged"
        case PE_TREE_ROW_KIND_ACCOUNT_INBOX: return "tree.allInboxes.\(row.folder)"
        default: return "tree.folder.\(row.folder)"
        }
    }

    /// collapsed, a row shows the unread messages it hides; expanded, the rows under it show them again
    public func outlineViewItemDidCollapse(_ notification: Notification) {
        reloadExpanded(notification)
        rememberOpen(notification, false)
    }

    public func outlineViewItemDidExpand(_ notification: Notification) {
        reloadExpanded(notification)
        rememberOpen(notification, true)
        guard !reloading, let node = selectedNode else { return }
        // the folder listed while the row above it was closed is selected again where it shows
        let selectedItem = tree.item(atRow: tree.selectedRow) as? TreeNode
        if selectedItem?.row.selectable != true, tree.row(forItem: node) >= 0 {
            reloading = true
            selectTreeNode(node)
            reloading = false
        }
    }

    /// a row opened or closed by the user: kept for the next start when the core says to remember it, else while the
    /// app runs
    private func rememberOpen(_ notification: Notification, _ open: Bool) {
        guard !reloading, !revealing, let node = notification.userInfo?["NSObject"] as? TreeNode else { return }
        if node.row.remembersOpen {
            openRows.set(node.row, open)
        } else {
            openedOrClosed[node.row.key] = open
        }
    }

    private func reloadExpanded(_ notification: Notification) {
        if let item = notification.userInfo?["NSObject"] {
            tree.reloadItem(item)
        }
    }

    /// the selected row drawn by the row itself, in the system's selection color, rather than by the source list's
    /// vibrancy (which a picture of the window taken by the app, as the UI test takes them, can not show)
    public func outlineView(_ outlineView: NSOutlineView, rowViewForItem item: Any) -> NSTableRowView? {
        SelectionRow()
    }

    public func outlineViewSelectionDidChange(_ notification: Notification) {
        guard !reloading, let node = tree.item(atRow: tree.selectedRow) as? TreeNode else { return }
        // closing an account takes the selection off a folder it hides (or moves it onto the account's heading, which
        // the user can not select): the heading is left unselected, and the folder shown stays shown
        guard node.row.selectable else {
            reloading = true
            tree.deselectAll(nil)
            reloading = false
            return
        }
        if deferChoice {
            chooseAfterPaint(node)
        } else {
            cancelPending()
            choose(node)
        }
    }

    /// the list of the row `node` shown
    private func choose(_ node: TreeNode) {
        if node.row.selectable {
            core.treeChosen(node.row.key)
        }
        show(node.row.list, folder: node.row.folder)
    }

    /// an account's heading or its row under All Inboxes is dragged to a new place in the accounts' order
    public func outlineView(_ outlineView: NSOutlineView, pasteboardWriterForItem item: Any) -> NSPasteboardWriting? {
        guard let row = (item as? TreeNode)?.row, row.reordersAccounts else { return nil }
        let writer = NSPasteboardItem()
        writer.setString("\(row.kind == PE_TREE_ROW_KIND_ACCOUNT ? "heading" : "inbox") \(row.account)", forType: accountPasteboardType)
        return writer
    }

    public func outlineView(_ outlineView: NSOutlineView, validateDrop info: NSDraggingInfo, proposedItem item: Any?,
                            proposedChildIndex index: Int) -> NSDragOperation {
        if let drag = draggedAccount(info) {
            // dropped on a row of its kind: the gap above it, which the line shows
            if index == NSOutlineViewDropOnItemIndex, let target = accountDropTarget(drag, onto: item) {
                outlineView.setDropItem(target.item, dropChildIndex: target.index)
                return accountPlace(drag, item: target.item, index: target.index) != nil ? .move : []
            }
            return accountPlace(drag, item: item, index: index) != nil ? .move : []
        }
        // .eml files from the Finder go into the folder they are dropped on
        let files = droppedFiles(info)
        if !files.isEmpty {
            guard (item as? TreeNode)?.row.dropTarget == true, index == NSOutlineViewDropOnItemIndex,
                  files.contains(where: isMessageFile) else { return [] }
            return .copy
        }
        let messages = draggedMessages(info)
        guard dropTarget(item, from: messages.map { $0.0 }) != nil, index == NSOutlineViewDropOnItemIndex else { return [] }
        // Option copies, as in the Finder
        return NSEvent.modifierFlags.contains(.option) ? .copy : .move
    }

    public func outlineView(_ outlineView: NSOutlineView, acceptDrop info: NSDraggingInfo, item: Any?, childIndex index: Int) -> Bool {
        if let drag = draggedAccount(info) {
            guard let place = accountPlace(drag, item: item, index: index) else { return false }
            moveAccount(drag.id, to: place)
            return true
        }
        let files = droppedFiles(info)
        if !files.isEmpty {
            guard let row = (item as? TreeNode)?.row, row.dropTarget else { return false }
            return dropFiles(files, into: row.folder)
        }
        let messages = draggedMessages(info)
        guard let to = dropTarget(item, from: messages.map { $0.0 }) else { return false }
        return drop(messages, to: to, copy: NSEvent.modifierFlags.contains(.option))
    }

    /// files dropped from the Finder into `folder`: the messages are put in it
    @discardableResult
    func dropFiles(_ files: [URL], into folder: Int64) -> Bool {
        // taken when one of them is a message; what became of the others the core says
        guard files.contains(where: isMessageFile) else { return false }
        importFiles(files, into: folder)
        return true
    }

    /// the folder files dropped on the message list go into: the one listed, not a list of several folders
    var listDropFolder: Int64? {
        let own = listView.ownFolder
        return own != 0 ? own : nil
    }

    /// the files on a drag's pasteboard
    func droppedFiles(_ info: NSDraggingInfo) -> [URL] {
        info.draggingPasteboard.readObjects(forClasses: [NSURL.self], options: [.urlReadingFileURLsOnly: true]) as? [URL] ?? []
    }

    /// the account on the pasteboard, and whether it was dragged by its heading (or by its row under All Inboxes)
    private func draggedAccount(_ info: NSDraggingInfo) -> (heading: Bool, id: Int64)? {
        guard let parts = info.draggingPasteboard.string(forType: accountPasteboardType)?.split(separator: " "),
              parts.count == 2, let id = Int64(parts[1]) else { return nil }
        return (parts[0] == "heading", id)
    }

    /// the kind of row an account is dragged by: its heading, or its Inbox under All Inboxes
    private func draggedKind(_ drag: (heading: Bool, id: Int64)) -> PeTreeRowKind {
        drag.heading ? PE_TREE_ROW_KIND_ACCOUNT : PE_TREE_ROW_KIND_ACCOUNT_INBOX
    }

    /// the gap above `item`, when it is a row of the dragged account's kind
    private func accountDropTarget(_ drag: (heading: Bool, id: Int64), onto item: Any?) -> (item: Any?, index: Int)? {
        guard let node = item as? TreeNode, node.kind == draggedKind(drag),
              let index = children(node.parent).firstIndex(where: { $0 === node }) else { return nil }
        return (node.parent, index)
    }

    /// the place in the accounts' order of an account dropped into the gap `index` among the children of `item`: only
    /// between rows of the kind it was dragged by (headings, or the rows under All Inboxes, which end their lists);
    /// nil anywhere else or where it would not move
    private func accountPlace(_ drag: (heading: Bool, id: Int64), item: Any?, index: Int) -> Int? {
        let siblings = children(item)
        let kind = draggedKind(drag)
        guard let from = accountOrder.firstIndex(of: drag.id), let first = siblings.firstIndex(where: { $0.kind == kind }),
              index >= first, index <= siblings.count else { return nil }
        // above a row is above its account; below the last, below the last's
        let gap = index < siblings.count ? accountOrder.firstIndex(of: siblings[index].row.account)
            : accountOrder.firstIndex(of: siblings[siblings.count - 1].row.account).map { $0 + 1 }
        guard let gap else { return nil }
        let place = gap > from ? gap - 1 : gap
        return place == from ? nil : place
    }

    /// the messages on the pasteboard, one item each
    private func draggedMessages(_ info: NSDraggingInfo) -> [(Int64, UInt64)] {
        (info.draggingPasteboard.pasteboardItems ?? []).compactMap { item in
            guard let value = item.string(forType: messagePasteboardType) else { return nil }
            let parts = value.split(separator: " ")
            guard parts.count == 2, let folder = Int64(parts[0]), let uid = UInt64(parts[1]) else { return nil }
            return (folder, uid)
        }
    }
}

// ---- the list's rows ----

extension Mailbox: NSTableViewDataSource, NSTableViewDelegate {
    public func numberOfRows(in tableView: NSTableView) -> Int {
        Int(min(rows, UInt64(Int32.max)))
    }

    public func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row index: Int) -> NSView? {
        guard let column = tableColumn, let message = row(index) else { return nil }
        let id = column.identifier
        if id == MessageRowCell.identifier {
            return rowCell(tableView, message)
        }
        switch ColumnID(rawValue: id.rawValue) {
        case .attach, .flag, .secure:
            let cell = (tableView.makeView(withIdentifier: id, owner: nil) as? IconCell) ?? IconCell(id)
            switch ColumnID(rawValue: id.rawValue) {
            // a bounce's mark in the paper clip's place, whether or not it has files
            case .attach: cell.show(message.attachIcon)
            case .secure: cell.show(message.secureIcon, tip: message.protectionWords)
            default: cell.show(message.flagIcons.plain, selected: message.flagIcons.selected)
            }
            return cell
        case .subject:
            let cell = (tableView.makeView(withIdentifier: id, owner: nil) as? SubjectCell) ?? SubjectCell(id)
            wireToggle(cell, in: tableView)
            cell.show(message, grouped: grouped)
            return cell
        default:
            let cell = (tableView.makeView(withIdentifier: id, owner: nil) as? TextCell) ?? TextCell(id)
            let value: String
            switch ColumnID(rawValue: id.rawValue) {
            case .from: value = recipientsColumn ? message.recipients : message.from
            case .received: value = message.date.map(formatDate) ?? ""
            case .folder: value = rowFolder(message.folder)
            default: value = ""
            }
            // unread messages in bold, as Outlook Express shows them, and closed conversations with unread mail
            cell.show(value, bold: message.bold, grey: message.dimmed)
            return cell
        }
    }

    /// a cell's disclosure triangle opens and closes the conversation of its row
    private func wireToggle(_ cell: ConversationCell, in tableView: NSTableView) {
        cell.toggled = { [weak self, weak tableView, weak cell] open in
            guard let self, let tableView, let cell else { return }
            let at = tableView.row(for: cell)
            if at >= 0 { self.setExpanded(open, row: at) }
        }
    }

    /// a row of the column layout: who, the subject, the first words, the marks
    private func rowCell(_ tableView: NSTableView, _ message: Message) -> NSView {
        let cell = (tableView.makeView(withIdentifier: MessageRowCell.identifier, owner: nil) as? MessageRowCell) ?? MessageRowCell()
        wireToggle(cell, in: tableView)
        let who = recipientsColumn ? Text.headerTo.text + ": " + message.recipients : message.from
        cell.show(message, who: who, date: message.date.map { shortDate($0, at: dateClock) } ?? "",
                  folder: severalFolders ? rowFolder(message.folder) : "")
        cell.showPicture(pictures.image(message.picture, points: SenderPicture.size, scale: pictureScale),
                         initials: message.initials, shown: showsPictures)
        return cell
    }

    public func tableViewSelectionDidChange(_ notification: Notification) {
        // the user chose: neither what Undo brings back nor the row after a removal is selected over it, and a list
        // being read selects what was selected before, so it is read again
        if !reloading {
            restorePending = false
            rowAfter = nil
            choseWhileLoading = listRequest != 0
        }
        selectionDidChange()
    }

    public func tableView(_ tableView: NSTableView, didClick tableColumn: NSTableColumn) {
        sortBy(tableColumn)
    }

    public func tableView(_ tableView: NSTableView, pasteboardWriterForRow index: Int) -> NSPasteboardWriting? {
        promise(forRow: index)
    }

    public func tableView(_ tableView: NSTableView, draggingSession session: NSDraggingSession, endedAt screenPoint: NSPoint,
                          operation: NSDragOperation) {
        dragEnded()
    }

    public func tableView(_ tableView: NSTableView, validateDrop info: NSDraggingInfo, proposedRow row: Int,
                          proposedDropOperation dropOperation: NSTableView.DropOperation) -> NSDragOperation {
        let files = droppedFiles(info)
        guard listDropFolder != nil, files.contains(where: isMessageFile) else { return [] }
        // onto the list as a whole, not between rows
        tableView.setDropRow(-1, dropOperation: .on)
        return .copy
    }

    public func tableView(_ tableView: NSTableView, acceptDrop info: NSDraggingInfo, row: Int,
                          dropOperation: NSTableView.DropOperation) -> Bool {
        guard let folder = listDropFolder else { return false }
        return dropFiles(droppedFiles(info), into: folder)
    }
}

// ---- the views of the rows ----

/// An account's heading in the tree: its name, small and grey as Mail's sidebar headings are, and while it is closed
/// the count of the unread messages of its folders
/// an account heading's name: the source list restyles a group row's text field as it redraws, so the font is fixed
/// here to look the same always, as the section headings of Mail
final class HeadingName: NSTextField {
    override var font: NSFont? {
        get { super.font }
        set { super.font = .systemFont(ofSize: NSFont.smallSystemFontSize, weight: .semibold) }
    }
}

final class HeadingCell: NSTableCellView {
    static let identifier = NSUserInterfaceItemIdentifier("heading")
    private let name = HeadingName(labelWithString: "")
    private let count = NSTextField(labelWithString: "")

    init() {
        super.init(frame: .zero)
        identifier = HeadingCell.identifier
        name.lineBreakMode = .byTruncatingTail
        name.font = nil // the setter puts the heading's own font
        name.textColor = .secondaryLabelColor
        // the count as the folder rows have it: their font and colour, at the trailing edge
        count.font = .systemFont(ofSize: NSFont.systemFontSize)
        count.textColor = .secondaryLabelColor
        count.alignment = .right
        let stack = NSStackView(views: [name, count])
        stack.spacing = 5
        stack.distribution = .fill
        stack.translatesAutoresizingMaskIntoConstraints = false
        name.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        name.setContentHuggingPriority(.init(1), for: .horizontal)
        count.setContentHuggingPriority(.required, for: .horizontal)
        addSubview(stack)
        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 2),
            // a group row's cell reaches 14pt further than a folder's: the counts in one column
            stack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -20),
            stack.centerYAnchor.constraint(equalTo: centerYAnchor),
        ])
        textField = name
    }

    required init?(coder: NSCoder) { fatalError() }

    /// the unread count it shows, for the UI test
    private(set) var unreadShown: UInt64 = 0

    func show(name text: String, count unread: UInt64) {
        unreadShown = unread
        name.stringValue = text
        count.stringValue = unread > 0 ? "\(unread)" : ""
        count.isHidden = unread == 0
        setAccessibilityLabel(unread > 0 ? Text.macFolderUnread.text(["folder": text, "count": unread]) : text)
    }
}

/// a folder's name in the tree: the source list puts its own font on a row's text field as it redraws, which would
/// take the bold of unread mail away, so the weight is kept here
final class FolderName: NSTextField {
    var bold = false {
        didSet { font = nil }
    }

    override var font: NSFont? {
        get { super.font }
        set {
            let size = newValue?.pointSize ?? NSFont.systemFontSize
            super.font = bold ? .boldSystemFont(ofSize: size) : .systemFont(ofSize: size)
        }
    }
}

/// A folder in the tree: its icon, its name (bold while it has unread mail) and the count of unread messages
final class FolderCell: NSTableCellView {
    static let identifier = NSUserInterfaceItemIdentifier("folder")
    private let icon = NSImageView()
    private let name = FolderName(labelWithString: "")
    private let count = NSTextField(labelWithString: "")

    init() {
        super.init(frame: .zero)
        identifier = FolderCell.identifier
        name.lineBreakMode = .byTruncatingTail
        count.textColor = .secondaryLabelColor
        count.alignment = .right
        let stack = NSStackView(views: [icon, name, count])
        stack.spacing = 5
        stack.distribution = .fill
        stack.translatesAutoresizingMaskIntoConstraints = false
        name.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        name.setContentHuggingPriority(.init(1), for: .horizontal)
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

    /// the unread count it shows, and whether in bold, for the UI test
    private(set) var unreadShown: UInt64 = 0
    private(set) var isBold = false

    /// `spoken`: what a screen reader names the row
    func show(name text: String, count unread: UInt64, icon image: NSImage?, bold: Bool, spoken: String) {
        unreadShown = unread
        isBold = bold
        name.stringValue = text
        name.bold = bold
        count.stringValue = unread > 0 ? "\(unread)" : ""
        // without a count the name has the row up to its trailing edge
        count.isHidden = unread == 0
        icon.image = image
        setAccessibilityLabel(unread > 0 ? Text.macFolderUnread.text(["folder": spoken, "count": unread]) : spoken)
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

    private var plain: NSImage?
    private var onSelection: NSImage?

    /// `image`, and `selected` in its place on a selected row (a coloured flag turns white there, as Mail shows it,
    /// so a blue flag stays visible on the blue of the selection); `tip`: what the mark means, its tooltip and the
    /// words a screen reader says of it
    func show(_ image: NSImage?, selected: NSImage? = nil, tip: String? = nil) {
        plain = image
        onSelection = selected
        toolTip = tip
        icon.setAccessibilityLabel(tip)
        update()
    }

    override var backgroundStyle: NSView.BackgroundStyle {
        didSet { update() }
    }

    private func update() {
        icon.image = backgroundStyle == .emphasized ? (onSelection ?? plain) : plain
    }
}

/// The Subject header: its title moved in as far as the subjects are, over the room of the triangles
final class IndentedHeaderCell: NSTableHeaderCell {
    var indent: CGFloat = 0

    override func drawInterior(withFrame cellFrame: NSRect, in controlView: NSView) {
        var frame = cellFrame
        frame.origin.x += indent
        frame.size.width = max(0, frame.size.width - indent)
        super.drawInterior(withFrame: frame, in: controlView)
    }
}

/// A column header that shows an icon in place of a title (the paper clip, the flag), in the colour of the titles
final class IconHeaderCell: NSTableHeaderCell {
    /// the icon, tinted once in the colour of the titles
    var icon: NSImage? {
        didSet { tinted = icon.map { Icons.tinted($0, .secondaryLabelColor) } }
    }
    private var tinted: NSImage?

    override func drawInterior(withFrame cellFrame: NSRect, in controlView: NSView) {
        super.drawInterior(withFrame: cellFrame, in: controlView)
        guard let tinted else { return }
        // in a box of 14 points, or 16 wide for a wide one, its shape kept
        let scale = min(16 / max(1, tinted.size.width), 14 / max(1, tinted.size.height))
        let size = NSSize(width: tinted.size.width * scale, height: tinted.size.height * scale)
        tinted.draw(in: NSRect(x: cellFrame.midX - size.width / 2, y: cellFrame.midY - size.height / 2,
                               width: size.width, height: size.height))
    }
}

final class TextCell: NSTableCellView {
    private let label = NSTextField(labelWithString: "")
    /// the row is of an ignored conversation, whatever colour the selection gives it
    private(set) var grey = false {
        didSet { label.textColor = Mailbox.rowColor(grey: grey, style: backgroundStyle) }
    }

    override var backgroundStyle: NSView.BackgroundStyle {
        didSet { label.textColor = Mailbox.rowColor(grey: grey, style: backgroundStyle) }
    }

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

    /// `grey`: a message of an ignored conversation, in the colour of what is turned off
    func show(_ value: String, bold: Bool, grey: Bool = false) {
        label.stringValue = value
        label.font = bold ? .boldSystemFont(ofSize: NSFont.systemFontSize) : .systemFont(ofSize: NSFont.systemFontSize)
        self.grey = grey
    }
}

@MainActor
extension Message {
    /// the mark in the paper clip's place: a bounce's whether or not it has files, else the paper clip, or none
    var attachIcon: NSImage? {
        bounce ? Icons.bounce : (hasAttachments ? Icons.list("attach") : nil)
    }

    /// the lock of a message encrypted as a whole, else the rosette of a signed one, or none: encrypted says more, as an
    /// encrypted message is often signed inside too
    var secureIcon: NSImage? {
        switch protection {
        case PE_PROTECTION_ENCRYPTED: Icons.encrypted
        case PE_PROTECTION_SIGNED: Icons.signed
        default: nil
        }
    }


    /// its flag in its colour, and white for a selected row (a blue flag stays visible on the selection's blue)
    var flagIcons: (plain: NSImage?, selected: NSImage?) {
        flagged ? (Icons.coloredFlag(flagColor), Icons.selectedFlag) : (nil, nil)
    }
}

/// A cell of a row that can open and close its conversation (the classic subject, the column layout's row)
@MainActor
protocol ConversationCell: NSView {
    /// the triangle clicked: open (true) or close the conversation
    var toggled: (Bool) -> Void { get set }
}

extension ConversationCell {
    /// the disclosure triangle of a conversation's row, clicked through `action` of the cell
    func setUpDisclosure(_ disclosure: NSButton, action: Selector) {
        disclosure.bezelStyle = .disclosure
        disclosure.setButtonType(.onOff)
        disclosure.title = ""
        disclosure.controlSize = .small
        disclosure.target = self
        disclosure.action = action
        disclosure.setAccessibilityIdentifier("list.disclosure")
    }
}

/// The subject of a row; grouped by conversation, a conversation's row of several has a disclosure triangle and the
/// count of its messages, and the messages under an open one are indented
final class SubjectCell: NSTableCellView, ConversationCell {
    private let label = NSTextField(labelWithString: "")
    let disclosure = NSButton()
    private var grey = false {
        didSet { label.textColor = Mailbox.rowColor(grey: grey, style: backgroundStyle) }
    }

    override var backgroundStyle: NSView.BackgroundStyle {
        didSet { label.textColor = Mailbox.rowColor(grey: grey, style: backgroundStyle) }
    }
    private var indent: NSLayoutConstraint!
    /// the triangle clicked: open (true) or close the conversation
    var toggled: (Bool) -> Void = { _ in }

    /// the room of the triangle, and how much further the messages under it are in
    static let glyph: CGFloat = 16
    static let step: CGFloat = 14
    /// where the subject starts in a list that is not grouped
    static let inset: CGFloat = 2

    init(_ id: NSUserInterfaceItemIdentifier) {
        super.init(frame: .zero)
        identifier = id
        setUpDisclosure(disclosure, action: #selector(clicked))
        disclosure.translatesAutoresizingMaskIntoConstraints = false
        label.lineBreakMode = .byTruncatingTail
        label.translatesAutoresizingMaskIntoConstraints = false
        label.cell?.usesSingleLineMode = true
        addSubview(disclosure)
        addSubview(label)
        indent = label.leadingAnchor.constraint(equalTo: leadingAnchor, constant: SubjectCell.inset)
        NSLayoutConstraint.activate([
            disclosure.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 1),
            disclosure.centerYAnchor.constraint(equalTo: centerYAnchor),
            indent,
            label.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -2),
            label.centerYAnchor.constraint(equalTo: centerYAnchor),
        ])
        textField = label
    }

    required init?(coder: NSCoder) { fatalError() }

    func show(_ message: Message, grouped: Bool) {
        // the count is a number alone, which needs no words of a language
        label.stringValue = message.opens ? "\(message.subject) (\(message.threadCount))" : message.subject
        label.font = message.bold ? .boldSystemFont(ofSize: NSFont.systemFontSize) : .systemFont(ofSize: NSFont.systemFontSize)
        grey = message.dimmed
        disclosure.isHidden = !message.opens
        disclosure.state = message.threadExpanded ? .on : .off
        indent.constant = !grouped ? SubjectCell.inset : SubjectCell.glyph + CGFloat(message.threadDepth) * SubjectCell.step
    }

    @objc private func clicked() {
        toggled(disclosure.state == .on)
    }
}

/// A row of the list in the column layout, three lines as Mail has them: who and when; the subject with the marks of
/// the classic columns (and the folder, in a search or All Inboxes); the first words of the message, with a
/// conversation's count and its disclosure triangle. An unread row has a dot in the gutter. The text is in a stack of
/// its own, so a picture can go before it.
final class MessageRowCell: NSTableCellView, ConversationCell {
    static let identifier = NSUserInterfaceItemIdentifier("row")
    static let height: CGFloat = 62

    private let dot = NSView()
    let picture = SenderPicture()
    private var pictureShown = true
    private let who = MessageRowCell.label(13)
    private let date = MessageRowCell.label(12)
    private let subject = MessageRowCell.label(12)
    private let folder = MessageRowCell.label(11)
    private let attach = NSImageView()
    private let flag = NSImageView()
    /// the lock or the rosette, left of the paper clip
    private let secure = NSImageView()
    private let snippet = MessageRowCell.label(12)
    private let count = MessageRowCell.label(12)
    let disclosure = NSButton()
    private var indent: NSLayoutConstraint!
    /// the triangle clicked: open (true) or close the conversation
    var toggled: (Bool) -> Void = { _ in }
    private var grey = false
    private var flags: (plain: NSImage?, selected: NSImage?) = (nil, nil)

    override var backgroundStyle: NSView.BackgroundStyle {
        didSet { paint() }
    }

    private static func label(_ size: CGFloat) -> NSTextField {
        let label = NSTextField(labelWithString: "")
        label.font = .systemFont(ofSize: size)
        label.lineBreakMode = .byTruncatingTail
        label.cell?.usesSingleLineMode = true
        label.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        label.setContentHuggingPriority(.init(1), for: .horizontal)
        return label
    }

    /// a line of the row: its main text taking the room, what is at its end kept whole
    private static func line(_ main: NSView, _ end: [NSView], baseline: Bool = false) -> NSStackView {
        for view in end {
            view.setContentCompressionResistancePriority(.required, for: .horizontal)
            view.setContentHuggingPriority(.required, for: .horizontal)
        }
        let stack = NSStackView(views: [main] + end)
        stack.orientation = .horizontal
        stack.spacing = 6
        // the date on the sender's baseline; the marks and the triangle in the middle of their line
        stack.alignment = baseline ? .firstBaseline : .centerY
        stack.distribution = .fill
        return stack
    }

    init() {
        super.init(frame: .zero)
        identifier = MessageRowCell.identifier
        dot.wantsLayer = true
        dot.layer?.cornerRadius = 3.5
        dot.translatesAutoresizingMaskIntoConstraints = false
        for icon in [secure, attach, flag] {
            icon.translatesAutoresizingMaskIntoConstraints = false
            icon.widthAnchor.constraint(equalToConstant: 14).isActive = true
            icon.heightAnchor.constraint(equalToConstant: 14).isActive = true
            icon.imageScaling = .scaleProportionallyDown
        }
        date.alignment = .right
        // the sender always semibold, as Mail's: the dot and a bold subject say the row is unread
        who.font = .systemFont(ofSize: 13, weight: .semibold)
        setUpDisclosure(disclosure, action: #selector(clicked))
        let text = NSStackView(views: [
            MessageRowCell.line(who, [date], baseline: true),
            MessageRowCell.line(subject, [folder, secure, attach, flag]),
            MessageRowCell.line(snippet, [count, disclosure]),
        ])
        text.orientation = .vertical
        text.alignment = .leading
        text.spacing = 2
        text.distribution = .fill
        text.translatesAutoresizingMaskIntoConstraints = false
        for line in text.arrangedSubviews {
            line.widthAnchor.constraint(equalTo: text.widthAnchor).isActive = true
        }
        addSubview(dot)
        addSubview(picture)
        addSubview(text)
        picture.translatesAutoresizingMaskIntoConstraints = false
        indent = picture.leadingAnchor.constraint(equalTo: leadingAnchor, constant: MessageRowCell.gutter)
        textAfterPicture = text.leadingAnchor.constraint(equalTo: picture.trailingAnchor, constant: MessageRowCell.pictureGap)
        textWithoutPicture = text.leadingAnchor.constraint(equalTo: picture.leadingAnchor)
        NSLayoutConstraint.activate([
            picture.widthAnchor.constraint(equalToConstant: SenderPicture.size),
            picture.heightAnchor.constraint(equalToConstant: SenderPicture.size),
            picture.centerYAnchor.constraint(equalTo: centerYAnchor),
            textAfterPicture,
            dot.widthAnchor.constraint(equalToConstant: 7),
            dot.heightAnchor.constraint(equalToConstant: 7),
            dot.centerXAnchor.constraint(equalTo: leadingAnchor, constant: MessageRowCell.gutter / 2 + 1),
            dot.centerYAnchor.constraint(equalTo: who.centerYAnchor),
            indent,
            text.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -10),
            text.centerYAnchor.constraint(equalTo: centerYAnchor),
        ])
        textField = who
    }

    required init?(coder: NSCoder) { fatalError() }

    /// the lock or the rosette the row shows, nil for none (for the UI test)
    var secureMark: NSImage? { secure.isHidden ? nil : secure.image }

    /// the row shows itself unread: its dot, and its subject bold (for the UI test)
    var unreadShown: Bool {
        !dot.isHidden && subject.font?.fontDescriptor.symbolicTraits.contains(.bold) == true
    }

    /// the room of the unread dot before the picture (or the text), how much further the messages of an open
    /// conversation are in, and the room between the picture and the text
    static let gutter: CGFloat = 18
    static let step: CGFloat = 16
    static let pictureGap: CGFloat = 10
    private var textAfterPicture: NSLayoutConstraint!
    private var textWithoutPicture: NSLayoutConstraint!

    /// the sender's picture beside the text (`shown`: Settings' list pictures on): `image` when the core has drawn
    /// one, else the initials
    func showPicture(_ image: NSImage?, initials: String, shown: Bool) {
        picture.isHidden = !shown
        // only what changed, so a row drawn again with the same picture is not painted again
        if picture.image !== image {
            picture.image = image
        }
        if picture.initials != initials {
            picture.initials = initials
        }
        if shown != pictureShown {
            pictureShown = shown
            // one constraint off before the other on, so the two never hold at once
            (shown ? textWithoutPicture : textAfterPicture).isActive = false
            (shown ? textAfterPicture : textWithoutPicture).isActive = true
        }
    }

    /// `who`: the sender, or the recipients in Sent Items and Drafts; `folder`: the folder's name in a list of several
    func show(_ message: Message, who name: String, date when: String, folder place: String) {
        who.stringValue = name
        date.stringValue = when
        subject.stringValue = message.subject.isEmpty ? Text.uiNoSubject.text : message.subject
        subject.font = message.bold ? .boldSystemFont(ofSize: 12) : .systemFont(ofSize: 12)
        folder.stringValue = place
        folder.isHidden = place.isEmpty
        attach.image = message.attachIcon
        attach.isHidden = attach.image == nil
        secure.image = message.secureIcon
        secure.isHidden = secure.image == nil
        secure.toolTip = message.protectionWords
        flags = message.flagIcons
        flag.isHidden = !message.flagged
        snippet.stringValue = message.snippet
        // "Encrypted message" is the core's word for a state, not the sender's: in italics, so it reads as one
        snippet.font = message.snippetIsState ? NSFontManager.shared.convert(.systemFont(ofSize: 12), toHaveTrait: .italicFontMask)
            : .systemFont(ofSize: 12)
        // the count is a number alone, which needs no words of a language
        count.stringValue = "\(message.threadCount)"
        count.isHidden = !message.opens
        disclosure.isHidden = !message.opens
        disclosure.state = message.threadExpanded ? .on : .off
        indent.constant = MessageRowCell.gutter + CGFloat(message.threadDepth) * MessageRowCell.step
        dot.isHidden = !message.bold
        grey = message.dimmed
        paint()
        setAccessibilityLabel(spoken(message, who: name, date: when))
    }

    /// what a screen reader says of the row: unread, who, the subject, when, the first words
    private func spoken(_ message: Message, who name: String, date when: String) -> String {
        var parts: [String] = []
        if message.bold { parts.append(Text.uiRowUnread.text) }
        parts += [name, subject.stringValue, when]
        if message.flagged { parts.append(Text.uiRowFlagged.text) }
        if message.hasAttachments { parts.append(Text.uiRowAttachments.text) }
        if let words = message.protectionWords { parts.append(words) }
        if message.opens { parts.append(Text.uiRowMessages.text(["count": message.threadCount])) }
        if !message.snippet.isEmpty { parts.append(message.snippet) }
        return parts.joined(separator: ", ")
    }

    /// the colours of the row: white on the selection, an ignored conversation's grey, the secondary lines lighter
    private func paint() {
        let selected = backgroundStyle == .emphasized
        let main = Mailbox.rowColor(grey: grey, style: backgroundStyle)
        let secondary: NSColor = selected ? .alternateSelectedControlTextColor.withAlphaComponent(0.8) : .secondaryLabelColor
        who.textColor = main
        subject.textColor = main
        for label in [date, folder, snippet, count] {
            label.textColor = secondary
        }
        dot.layer?.backgroundColor = (selected ? NSColor.alternateSelectedControlTextColor : .controlAccentColor).cgColor
        if picture.onSelection != selected {
            picture.onSelection = selected
        }
        flag.image = selected ? (flags.selected ?? flags.plain) : flags.plain
        for icon in [secure, attach] {
            icon.contentTintColor = selected ? .alternateSelectedControlTextColor : nil
        }
    }

    @objc private func clicked() {
        toggled(disclosure.state == .on)
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
        // an account's heading scrolls with its folders, as in Mail, rather than floating over them with a rule under it
        floatsGroupRows = false
        // the column as wide as the sidebar, so a selection's rounded highlight ends inside it on every row
        autoresizesOutlineColumn = false
        columnAutoresizingStyle = .uniformColumnAutoresizingStyle
        column.resizingMask = .autoresizingMask
        registerForDraggedTypes([messagePasteboardType, accountPasteboardType, .fileURL])
        draggingDestinationFeedbackStyle = .sourceList
        setAccessibilityIdentifier("tree")
    }

    required init?(coder: NSCoder) { fatalError() }

    public override func menu(for event: NSEvent) -> NSMenu? {
        let row = self.row(at: convert(event.locationInWindow, from: nil))
        // an account's heading has its own menu, and stays unselected
        if row >= 0, let node = item(atRow: row) as? Mailbox.TreeNode {
            switch node.row.menu {
            case PE_TREE_MENU_ACCOUNT: return mailbox?.accountMenu(node.row.account)
            case PE_TREE_MENU_NONE: return nil
            default: break
            }
            // a folder the server says holds no messages can not be selected, nor has a menu
            guard node.row.selectable else { return nil }
            selectRowIndexes(IndexSet(integer: row), byExtendingSelection: false)
        }
        return mailbox?.folderMenu()
    }

    // a row chosen with the mouse or the keyboard is drawn selected before its list loads
    public override func mouseDown(with event: NSEvent) {
        deferring { super.mouseDown(with: event) }
    }

    public override func keyDown(with event: NSEvent) {
        deferring { super.keyDown(with: event) }
    }

    /// `body` run as the user's choice, whose list loads after the tree is drawn
    private func deferring(_ body: () -> Void) {
        mailbox?.deferChoice = true
        defer { mailbox?.deferChoice = false }
        body()
    }

    // Edit > Select All and Undo from the tree are the message list's: a folder is selected alone and has no undo
    public override func selectAll(_ sender: Any?) {
        mailbox?.selectAllMessages()
    }

    @objc func undo(_ sender: Any?) {
        mailbox?.undo()
    }

    public override func validateUserInterfaceItem(_ item: NSValidatedUserInterfaceItem) -> Bool {
        if item.action == #selector(undo(_:)) {
            return MessageTable.validateUndo(item, mailbox)
        }
        if item.action == #selector(selectAll(_:)) {
            return (mailbox?.total ?? 0) > 0
        }
        return super.validateUserInterfaceItem(item)
    }
}

/// The message list: Return opens a draft, Delete deletes, Right and Left open and close a conversation, as the list of
/// the Windows app does; a right click opens the message's menu
public final class MessageTable: NSTableView {
    weak var mailbox: Mailbox?

    public override func menu(for event: NSEvent) -> NSMenu? {
        let row = self.row(at: convert(event.locationInWindow, from: nil))
        guard row >= 0 else { return nil }
        if !selectedRowIndexes.contains(row) {
            selectRowIndexes(IndexSet(integer: row), byExtendingSelection: false)
        }
        return mailbox?.messageMenu()
    }

    /// Edit > Undo with the list (or the tree) in front: the core's last move, delete or junk, named in the menu
    @objc func undo(_ sender: Any?) {
        mailbox?.undo()
    }

    /// Select All: the whole list, counted without listing it
    public override func selectAll(_ sender: Any?) {
        mailbox?.selectAllMessages()
    }

    static func validateUndo(_ item: NSValidatedUserInterfaceItem, _ mailbox: Mailbox?) -> Bool {
        let label = mailbox?.core.undoLabel
        (item as? NSMenuItem)?.title = label ?? Text.cmdUndo.text
        return label != nil
    }

    public override func validateUserInterfaceItem(_ item: NSValidatedUserInterfaceItem) -> Bool {
        if item.action == #selector(undo(_:)) {
            return MessageTable.validateUndo(item, mailbox)
        }
        return super.validateUserInterfaceItem(item)
    }

    /// a drag out of the list: a closed conversation's row carries all of its messages
    public override func beginDraggingSession(with items: [NSDraggingItem], event: NSEvent,
                                              source: NSDraggingSource) -> NSDraggingSession {
        super.beginDraggingSession(with: mailbox?.completeDrag(items) ?? items, event: event, source: source)
    }

    public override func keyDown(with event: NSEvent) {
        // the list before, dimmed while another loads, takes no keys
        if mailbox?.listCovered == true { return }
        switch event.keyCode {
        case 36, 76:
            mailbox?.openSelected()
        case 51, 117:
            mailbox?.deleteSelected()
        // A archives, as in Thunderbird; with a modifier it is another command's
        case 0 where event.modifierFlags.intersection([.command, .control, .option]).isEmpty:
            mailbox?.archiveSelected()
        // N: the next unread message, as in Thunderbird
        case 45 where event.modifierFlags.intersection([.command, .control, .option]).isEmpty:
            mailbox?.nextUnread()
        // W watches the conversation, K ignores it ("kill"), as in Thunderbird
        case 13 where event.modifierFlags.intersection([.command, .control, .option]).isEmpty:
            mailbox?.markConversations(PE_ACTION_WATCH)
        case 40 where event.modifierFlags.intersection([.command, .control, .option]).isEmpty:
            mailbox?.markConversations(PE_ACTION_IGNORE)
        // Right opens the selected conversation, Left closes it (from a message under it too)
        case 124 where mailbox?.openOrClose(true) == true, 123 where mailbox?.openOrClose(false) == true:
            break
        default:
            super.keyDown(with: event)
        }
    }
}

/// The folder pane can be dragged closed, as a sidebar can: that turns View > Folder List off. The list's width beside
/// the reader is kept as the user drags it
extension Mailbox: NSSplitViewDelegate {
    private func keepListWidth() {
        guard layout == PE_LAYOUT_COLUMNS, !changingLayout else { return }
        let width = rightSplit.arrangedSubviews[0].frame.width
        if width >= Mailbox.smallestListWidth {
            Mailbox.listBesideReader.value = Double(width)
        }
    }

    public func splitView(_ splitView: NSSplitView, canCollapseSubview subview: NSView) -> Bool {
        splitView === view && subview === treePane
    }

    /// a drag that collapsed or opened the pane sets the preference, whose setter calls folderListChanged (which then
    /// finds the pane as it should be and does nothing)
    public func splitViewDidResizeSubviews(_ notification: Notification) {
        if notification.object as? NSSplitView === rightSplit {
            keepListWidth()
            return
        }
        guard let app = AppDelegate.shared, notification.object as? NSSplitView === view else { return }
        let shown = !view.isSubviewCollapsed(treePane) && !treePane.isHidden
        if shown != app.folderList {
            app.folderList = shown
        }
    }
}

/// Over the message list while the list of another row loads: the list before shows through dimmed, as a disabled
/// control looks, and clicks and scrolling stop here. A load that takes a while says so in the middle
final class ListCover: NSView {
    private let label = NSTextField(labelWithString: Text.macLoadingList.text)

    /// "Loading..." shown (after a moment of loading)
    var loading = false {
        didSet {
            label.isHidden = !loading
            needsDisplay = true
        }
    }

    init() {
        super.init(frame: .zero)
        isHidden = true
        setAccessibilityIdentifier("list.cover")
        label.textColor = .secondaryLabelColor
        label.isHidden = true
        label.setAccessibilityIdentifier("list.loading")
        label.translatesAutoresizingMaskIntoConstraints = false
        addSubview(label)
        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: centerXAnchor),
            label.centerYAnchor.constraint(equalTo: centerYAnchor),
        ])
    }

    required init?(coder: NSCoder) { fatalError() }

    /// the list's own background, covering it as much as the core says, in light and dark
    override func draw(_ dirtyRect: NSRect) {
        NSColor.controlBackgroundColor.withAlphaComponent(PE_LIST_DIM).setFill()
        dirtyRect.fill(using: .sourceOver)
        // "Loading..." on a plate of its own, never through the rows' words under it
        guard loading else { return }
        let plate = NSBezierPath(roundedRect: label.frame.insetBy(dx: -14, dy: -7), xRadius: 8, yRadius: 8)
        NSColor.controlBackgroundColor.setFill()
        plate.fill()
        NSColor.separatorColor.setStroke()
        plate.stroke()
    }

    override func mouseDown(with event: NSEvent) {}
    override func rightMouseDown(with event: NSEvent) {}
    override func otherMouseDown(with event: NSEvent) {}
    override func scrollWheel(with event: NSEvent) {}
}
