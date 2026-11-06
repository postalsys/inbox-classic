// Move to Folder and Copy to Folder: the folders of every account in a tree, a field that narrows it, the folders
// used last on top, and New Folder; the button says what it does
import AppKit
import CInboxClassic

@MainActor
final class MoveWindow: NSObject, NSWindowDelegate, NSOutlineViewDataSource, NSOutlineViewDelegate, NSSearchFieldDelegate {
    /// a row of the core's (`pe_move_targets`): the Recent heading, a folder used last, an account, or a folder
    final class Node {
        enum Kind { case heading, recent, account, folder }
        let kind: Kind
        let name: String
        let icon: String
        /// 0 for a heading or an account
        let folder: Int64
        let account: Int64
        let choosable: Bool
        var children: [Node] = []

        init(_ target: PeTarget) {
            switch target.kind {
            case PE_TARGET_KIND_HEADING: kind = .heading
            case PE_TARGET_KIND_RECENT: kind = .recent
            case PE_TARGET_KIND_ACCOUNT: kind = .account
            default: kind = .folder
            }
            name = text(target.label)
            icon = MoveWindow.iconName(kind, text(target.icon))
            folder = target.folder
            account = target.account
            choosable = target.choosable
        }
    }

    /// the window shown now, which a folder made in it is chosen in once it is there
    private(set) static weak var shown: MoveWindow?

    let window: NSWindow
    private let core: Core
    /// the folder the messages are all in, 0 for messages of several
    private let current: Int64
    private let outline = NSOutlineView()
    private let filter = NSSearchField()
    private let okButton: NSButton
    private var roots: [Node] = []
    private var chosen: Int64?

    init(core: Core, title: String, prompt: String, verb: String, current: Int64) {
        self.core = core
        self.current = current
        window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 400, height: 460), styleMask: [.titled, .resizable],
                          backing: .buffered, defer: true)
        window.title = title
        window.identifier = NSUserInterfaceItemIdentifier("move")
        window.minSize = NSSize(width: 340, height: 340)
        okButton = NSButton(title: verb, target: nil, action: nil)
        super.init()
        window.delegate = self

        let intro = wrappingLabel(prompt)
        intro.setAccessibilityIdentifier("move.prompt")
        filter.placeholderString = Text.uiFindFolder.text
        filter.delegate = self
        filter.sendsSearchStringImmediately = true
        filter.setAccessibilityIdentifier("move.filter")

        let column = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("folder"))
        column.resizingMask = .autoresizingMask
        outline.addTableColumn(column)
        outline.outlineTableColumn = column
        outline.headerView = nil
        outline.rowHeight = 22
        outline.indentationPerLevel = 14
        outline.style = .inset
        outline.dataSource = self
        outline.delegate = self
        outline.target = self
        outline.doubleAction = #selector(doubleClicked)
        outline.setAccessibilityIdentifier("move.outline")
        let scroll = NSScrollView()
        scroll.documentView = outline
        scroll.hasVerticalScroller = true
        scroll.autohidesScrollers = true
        scroll.borderType = .bezelBorder

        let newFolder = NSButton(title: Text.macNewFolderButton.text, target: self, action: #selector(makeFolder))
        newFolder.setAccessibilityIdentifier("move.new")
        let cancelButton = NSButton(title: Text.uiCancel.text, target: self, action: #selector(cancel))
        cancelButton.keyEquivalent = "\u{1b}"
        cancelButton.setAccessibilityIdentifier("move.cancel")
        okButton.target = self
        okButton.action = #selector(accept)
        okButton.keyEquivalent = "\r"
        okButton.setAccessibilityIdentifier("move.ok")
        let buttons = buttonRow([cancelButton, okButton])
        buttons.insertView(newFolder, at: 0, in: .leading)

        let stack = NSStackView(views: [intro, filter, scroll, buttons])
        stack.orientation = .vertical
        stack.alignment = .leading
        stack.spacing = 10
        stack.setCustomSpacing(16, after: scroll)
        stack.edgeInsets = NSEdgeInsets(top: 20, left: 20, bottom: 20, right: 20)
        window.contentView = stack
        for view in [intro, filter, scroll, buttons] {
            view.widthAnchor.constraint(equalTo: stack.widthAnchor, constant: -40).isActive = true
        }
        scroll.heightAnchor.constraint(greaterThanOrEqualToConstant: 220).isActive = true
        scroll.setContentHuggingPriority(.defaultLow, for: .vertical)
        window.initialFirstResponder = filter
        rebuild()
        // the folder used last is where messages most likely go again
        if let recent = roots.first(where: { $0.kind == .heading })?.children.first {
            highlight(recent.folder, inRecent: true)
        }
        update()
    }

    /// the app's icon for the core's name of one
    nonisolated private static func iconName(_ kind: Node.Kind, _ name: String) -> String {
        if kind == .account { return "mailbox" }
        switch name {
        case "inbox": return "mail_inbox"
        case "sent": return "send"
        case "drafts": return "drafts"
        case "deleted": return "delete"
        case "junk": return "mail_prohibited"
        case "archive": return "archive"
        default: return "folder"
        }
    }

    // ---- the tree ----

    /// the rows the core gives for what the filter holds, nested by their depth
    private func rebuild() {
        let words = filter.stringValue
        guard let list = words.withCString({ pe_move_targets(core.handle, current, $0) }) else { return }
        defer { pe_target_list_free(list) }
        var rows: [Node] = []
        // the last row at each depth, the parent of the next deeper one
        var parents: [Node] = []
        for index in 0..<pe_target_list_count(list) {
            guard let target = pe_target_list_get(list, index)?.pointee else { continue }
            let node = Node(target)
            switch node.kind {
            case .heading, .account:
                rows.append(node)
                parents = [node]
            case .recent:
                parents.first?.children.append(node)
            case .folder:
                let depth = min(Int(target.depth), parents.count)
                if depth == 0 { rows.append(node) } else { parents[depth - 1].children.append(node) }
                parents = Array(parents.prefix(depth)) + [node]
            }
        }
        roots = rows
        let kept = chosen
        outline.reloadData()
        outline.expandItem(nil, expandChildren: true)
        if let kept { highlight(kept, inRecent: false) }
    }

    /// selects the row of `folder` (under Recent first when `inRecent`)
    func highlight(_ folder: Int64, inRecent: Bool) {
        var found: Int?
        for row in 0..<outline.numberOfRows {
            guard let node = outline.item(atRow: row) as? Node, node.folder == folder, node.folder != 0 else { continue }
            if node.kind == (inRecent ? .recent : .folder) { found = row; break }
            if found == nil { found = row }
        }
        guard let row = found else { return }
        outline.selectRowIndexes(IndexSet(integer: row), byExtendingSelection: false)
        // from the top, so a row near it leaves the Recent heading in sight
        outline.scrollRowToVisible(0)
        outline.scrollRowToVisible(row)
        update()
    }

    private func update() {
        let node = outline.item(atRow: outline.selectedRow) as? Node
        chosen = node?.choosable == true ? node?.folder : nil
        okButton.isEnabled = chosen != nil
    }

    // ---- the outline ----

    func outlineView(_ outlineView: NSOutlineView, numberOfChildrenOfItem item: Any?) -> Int {
        ((item as? Node)?.children ?? roots).count
    }

    func outlineView(_ outlineView: NSOutlineView, child index: Int, ofItem item: Any?) -> Any {
        ((item as? Node)?.children ?? roots)[index]
    }

    func outlineView(_ outlineView: NSOutlineView, isItemExpandable item: Any) -> Bool {
        !((item as? Node)?.children.isEmpty ?? true)
    }

    /// Recent is a heading over its folders, always open: no disclosure triangle
    func outlineView(_ outlineView: NSOutlineView, shouldShowOutlineCellForItem item: Any) -> Bool {
        (item as? Node)?.kind != .heading
    }

    func outlineView(_ outlineView: NSOutlineView, shouldCollapseItem item: Any) -> Bool {
        (item as? Node)?.kind != .heading
    }

    /// the folder chosen in the accent color while the filter has the keyboard, so what the button acts on is plain
    func outlineView(_ outlineView: NSOutlineView, rowViewForItem item: Any) -> NSTableRowView? {
        ChosenRow()
    }

    func outlineView(_ outlineView: NSOutlineView, shouldSelectItem item: Any) -> Bool {
        let node = item as? Node
        // an account takes no messages, but New Folder can make one at its top
        return node?.kind == .account || node?.choosable == true
    }

    func outlineView(_ outlineView: NSOutlineView, viewFor tableColumn: NSTableColumn?, item: Any) -> NSView? {
        guard let node = item as? Node else { return nil }
        if node.kind == .heading {
            let label = NSTextField(labelWithString: node.name)
            label.font = .systemFont(ofSize: NSFont.smallSystemFontSize, weight: .semibold)
            label.textColor = .secondaryLabelColor
            let cell = NSTableCellView()
            label.translatesAutoresizingMaskIntoConstraints = false
            cell.addSubview(label)
            NSLayoutConstraint.activate([
                label.leadingAnchor.constraint(equalTo: cell.leadingAnchor, constant: 2),
                label.bottomAnchor.constraint(equalTo: cell.bottomAnchor, constant: -3),
            ])
            return cell
        }
        let cell = MoveCell()
        cell.show(name: node.name, icon: Icons.folder(node.icon), dimmed: node.folder != 0 && !node.choosable)
        cell.setAccessibilityIdentifier(node.folder != 0 ? "move.\(node.kind == .recent ? "recent" : "folder").\(node.folder)"
                                                          : "move.account.\(node.account)")
        return cell
    }

    func outlineViewSelectionDidChange(_ notification: Notification) {
        update()
    }

    @objc private func doubleClicked() {
        if (outline.item(atRow: outline.clickedRow) as? Node)?.choosable == true { accept() }
    }

    // ---- the filter ----

    func controlTextDidChange(_ obj: Notification) {
        rebuild()
        // the first folder that matches, so Return takes it
        if chosen == nil, !filter.stringValue.isEmpty {
            for row in 0..<outline.numberOfRows where (outline.item(atRow: row) as? Node)?.choosable == true {
                outline.selectRowIndexes(IndexSet(integer: row), byExtendingSelection: false)
                break
            }
        }
        update()
    }

    /// the arrow keys move through the tree while typing in the filter; Return takes the folder highlighted
    func control(_ control: NSControl, textView: NSTextView, doCommandBy selector: Selector) -> Bool {
        switch selector {
        case #selector(NSResponder.moveDown(_:)), #selector(NSResponder.moveUp(_:)):
            let step = selector == #selector(NSResponder.moveDown(_:)) ? 1 : -1
            var row = outline.selectedRow
            repeat {
                row += step
            } while row >= 0 && row < outline.numberOfRows && (outline.item(atRow: row) as? Node)?.choosable != true
            if row >= 0 && row < outline.numberOfRows {
                outline.selectRowIndexes(IndexSet(integer: row), byExtendingSelection: false)
                outline.scrollRowToVisible(row)
            }
            return true
        case #selector(NSResponder.insertNewline(_:)):
            if chosen != nil { accept() }
            return true
        default:
            return false
        }
    }

    // ---- New Folder ----

    /// a folder in the highlighted folder, or at the top of the highlighted account; highlighted once it is made
    @objc private func makeFolder() {
        let node = outline.item(atRow: outline.selectedRow) as? Node
        let account = node?.account ?? core.accounts().first?.id ?? 0
        guard account != 0 else { return }
        let parent = node?.folder ?? 0
        let intro = parent != 0 ? Text.uiNewFolderIn.text(["folder": node?.name ?? ""]) : Text.uiNewFolderAtTop.text
        guard let name = askFolderName(title: Text.uiNewFolderTitle.text, intro: intro, name: ""), !name.isEmpty else { return }
        var reason: UnsafeMutablePointer<CChar>?
        if !name.withCString({ pe_folder_create(core.handle, account, parent, $0, &reason) }) {
            refused(reason, Text.uiFolderNotCreated.text)
        }
        // made in the background: FolderCreated chooses it here
    }

    /// a folder made with New Folder is there (`PE_EVENT_KIND_FOLDER_CREATED`): in the tree, highlighted
    func folderCreated(_ folder: Int64) {
        filter.stringValue = ""
        rebuild()
        highlight(folder, inRecent: false)
    }

    // ---- closing ----

    @objc func accept() {
        guard chosen != nil else { return }
        NSApp.stopModal(withCode: .OK)
    }

    @objc func cancel() {
        chosen = nil
        NSApp.stopModal(withCode: .cancel)
    }

    /// the folder chosen, nil when cancelled
    func run() -> Int64? {
        MoveWindow.shown = self
        defer { MoveWindow.shown = nil }
        window.center()
        // laid out first: the tree from its top, the Recent heading in sight, then the highlighted row if below
        window.layoutIfNeeded()
        outline.scroll(.zero)
        if outline.selectedRow >= 0 {
            outline.scrollRowToVisible(outline.selectedRow)
        }
        Modal.opened(window)
        let response = NSApp.runModal(for: window)
        Modal.closed(window)
        window.orderOut(nil)
        return response == .OK ? chosen : nil
    }
}

/// A row of the Move window drawn selected in the accent color whether or not the tree has the keyboard
final class ChosenRow: NSTableRowView {
    override func drawSelection(in dirtyRect: NSRect) {
        NSColor.selectedContentBackgroundColor.setFill()
        NSBezierPath(roundedRect: bounds.insetBy(dx: 4, dy: 1), xRadius: 5, yRadius: 5).fill()
    }

    override var interiorBackgroundStyle: NSView.BackgroundStyle {
        isSelected ? .emphasized : .normal
    }
}

/// A row of the Move window: the folder's icon and name, grey when messages can not go there
final class MoveCell: NSTableCellView {
    private let icon = NSImageView()
    private let name = NSTextField(labelWithString: "")

    init() {
        super.init(frame: .zero)
        name.lineBreakMode = .byTruncatingTail
        let stack = NSStackView(views: [icon, name])
        stack.spacing = 5
        stack.translatesAutoresizingMaskIntoConstraints = false
        name.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        addSubview(stack)
        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 2),
            stack.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor, constant: -6),
            stack.centerYAnchor.constraint(equalTo: centerYAnchor),
            icon.widthAnchor.constraint(equalToConstant: 16),
            icon.heightAnchor.constraint(equalToConstant: 16),
        ])
        textField = name
        imageView = icon
    }

    required init?(coder: NSCoder) { fatalError() }

    func show(name text: String, icon image: NSImage?, dimmed: Bool) {
        name.stringValue = text
        name.textColor = dimmed ? .tertiaryLabelColor : .labelColor
        icon.image = image
        icon.alphaValue = dimmed ? 0.4 : 1
    }
}
