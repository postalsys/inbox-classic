// The Address Book (Tools > Address Book): its groups on the left, its people on the right, Contact and Group
// Properties, Select Recipients (behind the To, Cc and Bcc buttons of a message) and Select Group Members, Add Sender
// to Address Book, and vCard and CSV files in and out. The book is the core's (pe_cards, pe_groups, pe_card_save...):
// these windows list what it gives and hand back what is typed, the core checks and keeps it.
import AppKit
import CInboxClassic
import UniformTypeIdentifiers

// ---- the book as the core gives it ----

/// Someone of the address book, a group of it, or an address typed in a group
struct BookEntry {
    /// the card, 0 for an address of no card (or a group)
    var card: Int64 = 0
    /// the group, 0 for a person
    var group: Int64 = 0
    var name: String
    var address: String
    var phone: String = ""
    /// as it goes in an address field; for a group its members
    var label: String
    /// how many members, for a group
    var count = 0
    var isGroup: Bool { group != 0 }
    /// what a list shows for it
    var title: String { name.isEmpty ? address : name }
}

/// A group of the address book as its list shows it
struct BookGroup {
    let id: Int64
    let name: String
    let count: Int
    let label: String
}

/// A card with every field Contact Properties edits
struct BookCard {
    var id: Int64 = 0
    var name = ""
    var first = ""
    var last = ""
    var nickname = ""
    var company = ""
    var notes = ""
    /// the default first
    var addresses: [String] = []
    var phones: [(kind: PePhoneKind, number: String)] = []
}

extension Core {
    /// the people of the book, by name; with `filter`, those whose name, nickname, company or address starts with it
    func bookCards(_ filter: String = "") -> [BookEntry] {
        guard let list = filter.withCString({ pe_cards(handle, $0) }) else { return [] }
        defer { pe_card_list_free(list) }
        return (0..<pe_card_list_count(list)).compactMap { pe_card_list_get(list, $0)?.pointee }.map {
            BookEntry(card: $0.id, name: text($0.name), address: text($0.address), phone: text($0.phone), label: text($0.label))
        }
    }

    func bookGroups() -> [BookGroup] {
        guard let list = pe_groups(handle) else { return [] }
        defer { pe_group_list_free(list) }
        return (0..<pe_group_list_count(list)).compactMap { pe_group_list_get(list, $0)?.pointee }.map {
            BookGroup(id: $0.id, name: text($0.name), count: $0.member_count, label: text($0.label))
        }
    }

    /// group `id`: its name and members
    func bookGroup(_ id: Int64) -> (name: String, members: [BookEntry])? {
        guard let view = pe_group(handle, id) else { return nil }
        defer { pe_group_free(view) }
        guard let group = pe_group_info(view)?.pointee else { return nil }
        let members = (0..<group.member_count).map { index -> BookEntry in
            let member = group.members[index]
            return BookEntry(card: member.card, name: text(member.name), address: text(member.address), label: text(member.label))
        }
        return (text(group.name), members)
    }

    func bookCard(_ id: Int64) -> BookCard? {
        guard let view = pe_card(handle, id) else { return nil }
        defer { pe_card_free(view) }
        guard let card = pe_card_info(view)?.pointee else { return nil }
        return BookCard(id: card.id, name: text(card.name), first: text(card.first), last: text(card.last),
                        nickname: text(card.nickname), company: text(card.company), notes: text(card.notes),
                        addresses: (0..<card.address_count).map { text(card.addresses[$0]) },
                        phones: (0..<card.phone_count).map { (card.phones[$0].kind, text(card.phones[$0].number)) })
    }

    /// saves `card` (a new one for id 0): its id, or why not
    func saveBookCard(_ card: BookCard) -> Result<Int64, Refusal> {
        let strings = CStrings()
        let phones = card.phones.map { PePhone(kind: $0.kind, number: strings.add($0.number)) }
        var error: UnsafeMutablePointer<CChar>?
        let id = phones.withUnsafeBufferPointer { phoneBuffer in
            var info = PeCard(id: card.id, name: strings.add(card.name), first: strings.add(card.first), last: strings.add(card.last),
                              nickname: strings.add(card.nickname), company: strings.add(card.company), notes: strings.add(card.notes),
                              addresses: strings.array(card.addresses), address_count: card.addresses.count,
                              phones: phoneBuffer.baseAddress, phone_count: phones.count)
            return pe_card_save(handle, &info, &error)
        }
        let reason = taken(error)
        return id != 0 ? .success(id) : .failure(Refusal(reason ?? ""))
    }

    /// saves a group (a new one for id 0): its id, or why not
    func saveBookGroup(id: Int64, name: String, members: [BookEntry]) -> Result<Int64, Refusal> {
        let strings = CStrings()
        let list = members.map { PeMember(card: $0.card, name: strings.add($0.name), address: strings.add($0.address), label: nil) }
        var error: UnsafeMutablePointer<CChar>?
        let saved = list.withUnsafeBufferPointer { buffer in
            var group = PeGroup(id: id, name: strings.add(name), members: buffer.baseAddress, member_count: list.count)
            return pe_group_save(handle, &group, &error)
        }
        let reason = taken(error)
        return saved != 0 ? .success(saved) : .failure(Refusal(reason ?? ""))
    }
}

/// `added` (labels of people and groups, separated by commas) put at the end of an address field's text, each address
/// once, as the core does it
func addressFieldAdding(_ field: String, _ added: String) -> String {
    field.withCString { field in added.withCString { taken(pe_address_field_add(field, $0)) } } ?? field
}

/// Whether what was typed is one e-mail address alone, as the core keeps them on a card
func isMailbox(_ typed: String) -> Bool {
    typed.withCString { pe_address_is_mailbox($0) }
}

// ---- the small parts the windows share ----

/// a symbol of the system, for the Address Book's toolbar and lists (the first of `names` there is)
@MainActor
func bookSymbol(_ names: String...) -> NSImage? {
    for name in names {
        if let image = NSImage(systemSymbolName: name, accessibilityDescription: nil) {
            return image
        }
    }
    return nil
}

@MainActor
enum BookIcons {
    static var person: NSImage? { bookSymbol("person.crop.circle") }
    static var group: NSImage? { bookSymbol("person.2.fill", "person.2") }
    static var all: NSImage? { bookSymbol("person.crop.rectangle.stack", "book.closed") }
    /// an address typed in a group, of no card
    static var typed: NSImage? { bookSymbol("envelope") }
}

/// A table that hands Delete (the key) and a double-click to closures
final class BookTable: NSTableView {
    var deletePressed: () -> Void = {}

    override func keyDown(with event: NSEvent) {
        // Delete and Forward Delete
        if event.keyCode == 51 || event.keyCode == 117 {
            deletePressed()
            return
        }
        super.keyDown(with: event)
    }
}

/// A table in a scroll view with a border, its columns (id, title, width) or one column without a header
@MainActor
func bookTable(_ table: NSTableView, id: String, columns: [(String, String, CGFloat)], header: Bool = true) -> NSScrollView {
    for (columnId, title, width) in columns {
        let column = NSTableColumn(identifier: NSUserInterfaceItemIdentifier(columnId))
        column.title = title
        column.width = width
        column.minWidth = 40
        table.addTableColumn(column)
    }
    if !header {
        table.headerView = nil
    }
    table.columnAutoresizingStyle = .lastColumnOnlyAutoresizingStyle
    table.usesAlternatingRowBackgroundColors = header
    table.style = header ? .fullWidth : .plain
    table.setAccessibilityIdentifier(id)
    let scroll = NSScrollView()
    scroll.documentView = table
    scroll.hasVerticalScroller = true
    scroll.autohidesScrollers = true
    scroll.borderType = .bezelBorder
    return scroll
}

/// A cell of a table: a text, with a picture before it when given, and a count after it when given
@MainActor
func bookCell(_ table: NSTableView, _ value: String, image: NSImage? = nil, count: String? = nil, secondary: Bool = false) -> NSView {
    let id = NSUserInterfaceItemIdentifier(image == nil ? (count == nil ? "book.text" : "book.count") : (count == nil ? "book.icon" : "book.icon.count"))
    let cell = table.makeView(withIdentifier: id, owner: nil) as? NSTableCellView ?? {
        let made = NSTableCellView()
        made.identifier = id
        let label = NSTextField(labelWithString: "")
        label.lineBreakMode = .byTruncatingTail
        label.translatesAutoresizingMaskIntoConstraints = false
        label.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        made.addSubview(label)
        made.textField = label
        var leading = made.leadingAnchor
        var leadingGap: CGFloat = 2
        if image != nil {
            let picture = NSImageView()
            picture.translatesAutoresizingMaskIntoConstraints = false
            picture.symbolConfiguration = .init(pointSize: 12, weight: .regular)
            picture.contentTintColor = .secondaryLabelColor
            made.addSubview(picture)
            made.imageView = picture
            NSLayoutConstraint.activate([
                picture.leadingAnchor.constraint(equalTo: made.leadingAnchor, constant: 2),
                picture.centerYAnchor.constraint(equalTo: made.centerYAnchor),
                picture.widthAnchor.constraint(equalToConstant: 18),
            ])
            leading = picture.trailingAnchor
            leadingGap = 5
        }
        var trailing = made.trailingAnchor
        if count != nil {
            let number = NSTextField(labelWithString: "")
            number.translatesAutoresizingMaskIntoConstraints = false
            number.textColor = .secondaryLabelColor
            number.font = .monospacedDigitSystemFont(ofSize: NSFont.smallSystemFontSize, weight: .regular)
            number.alignment = .right
            number.identifier = NSUserInterfaceItemIdentifier("count")
            number.setContentHuggingPriority(.required, for: .horizontal)
            made.addSubview(number)
            NSLayoutConstraint.activate([
                number.trailingAnchor.constraint(equalTo: made.trailingAnchor, constant: -4),
                number.centerYAnchor.constraint(equalTo: made.centerYAnchor),
            ])
            trailing = number.leadingAnchor
        }
        NSLayoutConstraint.activate([
            label.leadingAnchor.constraint(equalTo: leading, constant: leadingGap),
            label.trailingAnchor.constraint(lessThanOrEqualTo: trailing, constant: -4),
            label.centerYAnchor.constraint(equalTo: made.centerYAnchor),
        ])
        return made
    }()
    cell.textField?.stringValue = value
    cell.textField?.textColor = secondary ? .secondaryLabelColor : .labelColor
    cell.imageView?.image = image
    if let count, let number = cell.subviews.first(where: { $0.identifier?.rawValue == "count" }) as? NSTextField {
        number.stringValue = count
    }
    return cell
}

/// A label for a form, at the right of its column
@MainActor
func formLabel(_ value: String) -> NSTextField {
    let label = NSTextField(labelWithString: value)
    label.alignment = .right
    return label
}

/// Runs `sheet` as a sheet of `parent` (or on its own, centred, without one) until it calls NSApp.stopModal(), so the
/// code that opens it reads on with its answer
@MainActor
func runSheet(_ sheet: NSWindow, on parent: NSWindow?) {
    Modal.opened(sheet)
    // as big as what it holds
    if let content = sheet.contentView {
        content.layoutSubtreeIfNeeded()
        sheet.setContentSize(content.fittingSize)
    }
    if let parent, parent.isVisible {
        parent.beginSheet(sheet)
    } else {
        sheet.center()
    }
    NSApp.runModal(for: sheet)
    Modal.closed(sheet)
    if let parent = sheet.sheetParent {
        parent.endSheet(sheet)
    }
    sheet.orderOut(nil)
}

// ---- the Address Book window ----

@MainActor
final class AddressBookWindow: NSObject, NSWindowDelegate, NSToolbarDelegate, NSToolbarItemValidation, NSTableViewDataSource,
    NSTableViewDelegate, NSMenuDelegate {
    /// the window, once opened (closing it only hides it)
    static private(set) var shown: AddressBookWindow?
    /// the Address Book in front: the menu commands it answers are about it
    static var key: AddressBookWindow? {
        guard let shown, shown.window.isKeyWindow else { return nil }
        return shown
    }

    let window: NSWindow
    private let core: Core
    let groupList = BookTable()
    let people = BookTable()
    let searchField = NSSearchField()
    private let emptyLabel = NSTextField(wrappingLabelWithString: "")
    private(set) var groups: [BookGroup] = []
    private(set) var rows: [BookEntry] = []
    private var filling = false

    static func show(core: Core) {
        let book = shown ?? AddressBookWindow(core: core)
        shown = book
        book.fill()
        let first = !book.window.isVisible && !book.placed
        book.window.makeKeyAndOrderFront(nil)
        if first {
            onMain { book.placeDivider() }
        }
    }

    private let split = NSSplitView()
    private var placed = false

    /// the groups a column of their own width, once the window is laid out
    private func placeDivider() {
        placed = true
        window.contentView?.layoutSubtreeIfNeeded()
        guard split.bounds.width > 400 else {
            // not laid out yet: once it is
            after(0.1) { [weak self] in self?.placeDivider() }
            return
        }
        split.setPosition(200, ofDividerAt: 0)
    }

    /// what the book holds changed (a sender added, a file imported): the window shows it
    static func refresh() {
        shown?.fill()
    }

    private init(core: Core) {
        self.core = core
        window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 760, height: 480),
                          styleMask: [.titled, .closable, .miniaturizable, .resizable], backing: .buffered, defer: false)
        super.init()
        window.title = Text.cmdAddressBook.title
        window.identifier = NSUserInterfaceItemIdentifier("addressbook")
        window.isReleasedWhenClosed = false
        window.tabbingMode = .disallowed
        window.minSize = NSSize(width: 560, height: 320)
        window.delegate = self
        let toolbar = NSToolbar(identifier: "AddressBook")
        toolbar.delegate = self
        toolbar.displayMode = .iconAndLabel
        toolbar.allowsUserCustomization = false
        window.toolbar = toolbar
        window.toolbarStyle = .expanded
        window.contentView = layout()
        if !TestHooks.testing {
            window.setFrameAutosaveName("AddressBook")
        }
        if TestHooks.testing || !window.setFrameUsingName("AddressBook") {
            window.center()
        }
        window.initialFirstResponder = people
    }

    private func layout() -> NSView {
        let groupColumn = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("group"))
        groupList.addTableColumn(groupColumn)
        groupList.headerView = nil
        groupList.style = .sourceList
        groupList.selectionHighlightStyle = .regular
        groupList.rowSizeStyle = .default
        groupList.dataSource = self
        groupList.delegate = self
        groupList.doubleAction = #selector(groupDoubleClicked)
        groupList.target = self
        groupList.deletePressed = { [weak self] in self?.deleteSelected() }
        groupList.setAccessibilityIdentifier("book.groups")
        let groupScroll = NSScrollView()
        groupScroll.documentView = groupList
        groupScroll.hasVerticalScroller = true
        groupScroll.autohidesScrollers = true
        groupScroll.drawsBackground = false

        let peopleScroll = bookTable(people, id: "book.people", columns: [
            ("name", Text.uiColName.text, 190), ("email", Text.uiColEmail.text, 220), ("phone", Text.uiColPhone.text, 110),
        ])
        people.allowsMultipleSelection = true
        people.dataSource = self
        people.delegate = self
        people.target = self
        people.doubleAction = #selector(personDoubleClicked)
        people.deletePressed = { [weak self] in self?.deleteSelected() }
        people.menu = NSMenu()
        people.menu?.delegate = self
        peopleScroll.borderType = .noBorder

        emptyLabel.alignment = .center
        emptyLabel.textColor = .secondaryLabelColor
        emptyLabel.isSelectable = false
        emptyLabel.setAccessibilityIdentifier("book.empty")
        emptyLabel.translatesAutoresizingMaskIntoConstraints = false
        let right = NSView()
        peopleScroll.translatesAutoresizingMaskIntoConstraints = false
        right.addSubview(peopleScroll)
        right.addSubview(emptyLabel)
        NSLayoutConstraint.activate([
            peopleScroll.topAnchor.constraint(equalTo: right.topAnchor),
            peopleScroll.bottomAnchor.constraint(equalTo: right.bottomAnchor),
            peopleScroll.leadingAnchor.constraint(equalTo: right.leadingAnchor),
            peopleScroll.trailingAnchor.constraint(equalTo: right.trailingAnchor),
            emptyLabel.centerXAnchor.constraint(equalTo: right.centerXAnchor),
            emptyLabel.centerYAnchor.constraint(equalTo: right.centerYAnchor, constant: -20),
            emptyLabel.widthAnchor.constraint(lessThanOrEqualTo: right.widthAnchor, constant: -60),
            emptyLabel.widthAnchor.constraint(lessThanOrEqualToConstant: 360),
        ])

        split.isVertical = true
        split.dividerStyle = .thin
        split.addArrangedSubview(groupScroll)
        split.addArrangedSubview(right)
        split.setHoldingPriority(.defaultLow + 10, forSubviewAt: 0)
        groupScroll.widthAnchor.constraint(greaterThanOrEqualToConstant: 150).isActive = true
        right.widthAnchor.constraint(greaterThanOrEqualToConstant: 320).isActive = true
        return split
    }

    // ---- what it lists ----

    /// the group selected on the left, nil for All Contacts
    var selectedGroup: BookGroup? {
        let row = groupList.selectedRow
        return row >= 1 && row - 1 < groups.count ? groups[row - 1] : nil
    }

    /// the people selected on the right
    var selectedPeople: [BookEntry] {
        people.selectedRowIndexes.compactMap { rows.indices.contains($0) ? rows[$0] : nil }
    }

    /// the groups and the people again, the group and the people selected kept where they still are
    func fill(selectGroup: Int64? = nil, selectCard: Int64? = nil) {
        filling = true
        let groupId = selectGroup ?? selectedGroup?.id ?? 0
        let cards = Set(selectCard.map { [$0] } ?? selectedPeople.map(\.card))
        groups = core.bookGroups()
        groupList.reloadData()
        let groupRow = groups.firstIndex { $0.id == groupId }.map { $0 + 1 } ?? 0
        groupList.selectRowIndexes(IndexSet(integer: groupRow), byExtendingSelection: false)
        filling = false
        fillPeople(select: cards)
    }

    /// the people of the group selected (or all), those the find box finds
    private func fillPeople(select cards: Set<Int64> = []) {
        let words = searchField.stringValue.trimmingCharacters(in: .whitespaces)
        if let group = selectedGroup {
            let all = core.bookCards()
            let phones = Dictionary(all.map { ($0.card, $0.phone) }, uniquingKeysWith: { first, _ in first })
            let found = words.isEmpty ? nil : Set(core.bookCards(words).map(\.card))
            let lower = words.lowercased()
            rows = (core.bookGroup(group.id)?.members ?? []).map { member in
                var member = member
                member.phone = phones[member.card] ?? ""
                return member
            }.filter { member in
                guard let found else { return true }
                if member.card != 0 { return found.contains(member.card) }
                return member.address.lowercased().hasPrefix(lower)
                    || member.name.lowercased().split(separator: " ").contains { $0.hasPrefix(lower) }
            }
        } else {
            rows = core.bookCards(words)
        }
        people.reloadData()
        let selected = IndexSet(rows.indices.filter { rows[$0].card != 0 && cards.contains(rows[$0].card) })
        people.selectRowIndexes(selected, byExtendingSelection: false)
        if let first = selected.first {
            people.scrollRowToVisible(first)
        }
        if !rows.isEmpty || selectedGroup != nil {
            emptyLabel.stringValue = ""
        } else if !words.isEmpty {
            emptyLabel.stringValue = Text.uiBookNoMatch.text(["words": words])
        } else {
            emptyLabel.stringValue = Text.uiBookEmpty.text
        }
        emptyLabel.isHidden = emptyLabel.stringValue.isEmpty
        window.toolbar?.validateVisibleItems()
    }

    @objc private func findChanged() {
        fillPeople()
    }

    func find(_ words: String) {
        searchField.stringValue = words
        fillPeople()
    }

    // ---- the tables ----

    func numberOfRows(in tableView: NSTableView) -> Int {
        tableView === groupList ? groups.count + 1 : rows.count
    }

    func tableView(_ tableView: NSTableView, viewFor column: NSTableColumn?, row: Int) -> NSView? {
        if tableView === groupList {
            if row == 0 {
                return bookCell(tableView, Text.uiBookAllContacts.text, image: BookIcons.all, count: "")
            }
            let group = groups[row - 1]
            let cell = bookCell(tableView, group.name, image: BookIcons.group, count: "\(group.count)")
            cell.toolTip = Text.uiGroupMembersCount.text(["count": group.count])
            return cell
        }
        let entry = rows[row]
        switch column?.identifier.rawValue {
        case "name": return bookCell(tableView, entry.title, secondary: entry.name.isEmpty)
        case "email": return bookCell(tableView, entry.address)
        default: return bookCell(tableView, entry.phone)
        }
    }

    /// the selected group drawn by its row, as the folder tree has it
    func tableView(_ tableView: NSTableView, rowViewForRow row: Int) -> NSTableRowView? {
        tableView === groupList ? SelectionRow() : nil
    }

    func tableViewSelectionDidChange(_ notification: Notification) {
        guard !filling else { return }
        if notification.object as? NSTableView === groupList {
            fillPeople()
        }
        window.toolbar?.validateVisibleItems()
    }

    @objc private func groupDoubleClicked() {
        if groupList.clickedRow >= 1 {
            properties(groupFirst: true)
        }
    }

    @objc private func personDoubleClicked() {
        guard people.clickedRow >= 0 else { return }
        properties(groupFirst: false)
    }

    /// the right-click menu of the people: what the toolbar does
    func menuNeedsUpdate(_ menu: NSMenu) {
        menu.removeAllItems()
        let clicked = people.clickedRow
        if clicked >= 0 && !people.selectedRowIndexes.contains(clicked) {
            people.selectRowIndexes(IndexSet(integer: clicked), byExtendingSelection: false)
        }
        let some = !selectedPeople.isEmpty
        for (title, action, on) in [(Text.uiMenuNewContact.text, #selector(newContact), true),
                                    (Text.uiMenuNewGroup.text, #selector(newGroup), true),
                                    ("-", nil, true),
                                    (Command.properties.label, #selector(propertiesClicked), some && selectedPeople.count == 1),
                                    (Text.uiMenuDelete.text, #selector(deleteClicked), some && selectedPeople.contains { $0.card != 0 }),
                                    ("-", nil, true),
                                    (Text.uiMenuWriteTo.text, #selector(writeTo), some)] as [(String, Selector?, Bool)] {
            if title == "-" {
                menu.addItem(.separator())
                continue
            }
            let item = NSMenuItem(title: title, action: action, keyEquivalent: "")
            item.target = self
            item.isEnabled = on
            menu.addItem(item)
        }
        menu.autoenablesItems = false
    }

    // ---- the toolbar ----

    private enum Item: String, CaseIterable {
        case newContact, newGroup, properties, delete, writeTo, search
    }

    func toolbarDefaultItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
        let id = { (item: Item) in NSToolbarItem.Identifier("book." + item.rawValue) }
        return [id(.newContact), id(.newGroup), .space, id(.properties), id(.delete), .space, id(.writeTo), .flexibleSpace, id(.search)]
    }

    func toolbarAllowedItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
        toolbarDefaultItemIdentifiers(toolbar)
    }

    func toolbar(_ toolbar: NSToolbar, itemForItemIdentifier identifier: NSToolbarItem.Identifier,
                 willBeInsertedIntoToolbar flag: Bool) -> NSToolbarItem? {
        guard let item = Item(rawValue: String(identifier.rawValue.dropFirst("book.".count))) else { return nil }
        if item == .search {
            let search = NSSearchToolbarItem(itemIdentifier: identifier)
            search.searchField = searchField
            search.label = Text.macToolSearch.text
            searchField.placeholderString = Text.uiBookFindHint.text
            searchField.sendsSearchStringImmediately = true
            searchField.target = self
            searchField.action = #selector(findChanged)
            searchField.setAccessibilityIdentifier("book.find")
            search.preferredWidthForSearchField = 240
            return search
        }
        let (label, image, action): (String, NSImage?, Selector) = switch item {
        case .newContact: (Text.uiTbNewContact.text, bookSymbol("person.crop.circle.badge.plus", "person.badge.plus"), #selector(newContact))
        case .newGroup: (Text.uiTbNewGroup.text, bookSymbol("person.2.badge.plus", "person.2"), #selector(newGroup))
        case .properties: (Text.uiTbProperties.text, bookSymbol("info.circle"), #selector(propertiesClicked))
        case .delete: (Text.uiTbDelete.text, bookSymbol("trash"), #selector(deleteClicked))
        case .writeTo: (Text.uiTbWriteTo.text, bookSymbol("square.and.pencil", "envelope"), #selector(writeTo))
        case .search: ("", nil, #selector(findChanged))
        }
        let toolbarItem = NSToolbarItem(itemIdentifier: identifier)
        toolbarItem.label = label
        toolbarItem.paletteLabel = label
        toolbarItem.toolTip = label
        toolbarItem.image = image
        toolbarItem.target = self
        toolbarItem.action = action
        toolbarItem.isBordered = true
        return toolbarItem
    }

    func validateToolbarItem(_ item: NSToolbarItem) -> Bool {
        switch item.itemIdentifier.rawValue {
        case "book.properties": return canShowProperties
        case "book.delete": return canDelete
        case "book.writeTo": return !selectedPeople.isEmpty || selectedGroup != nil
        default: return true
        }
    }

    /// the groups list in front with a group selected: Properties and Delete are the group's
    private var groupInFront: Bool {
        window.firstResponder === groupList && selectedGroup != nil
    }

    var canShowProperties: Bool {
        groupInFront || selectedPeople.count == 1 && selectedPeople[0].card != 0 || selectedPeople.isEmpty && selectedGroup != nil
    }

    var canDelete: Bool {
        groupInFront || selectedPeople.contains { $0.card != 0 } || selectedPeople.isEmpty && selectedGroup != nil
    }

    // ---- what it does ----

    @objc func newContact() {
        let saved = ContactSheet(core: core, card: nil).run(on: window)
        if saved != 0 {
            fill(selectCard: saved)
        }
    }

    @objc func newGroup() {
        let saved = GroupSheet(core: core, id: 0).run(on: window)
        if saved != 0 {
            fill(selectGroup: saved)
        }
    }

    @objc func propertiesClicked() {
        properties(groupFirst: window.firstResponder === groupList)
    }

    /// Properties of the group (the groups list in front, or no one selected in it) or of the person selected
    func properties(groupFirst: Bool) {
        if let group = selectedGroup, groupFirst || selectedPeople.isEmpty {
            if GroupSheet(core: core, id: group.id).run(on: window) != 0 {
                fill()
            }
            return
        }
        guard selectedPeople.count == 1, let person = selectedPeople.first, person.card != 0,
              let card = core.bookCard(person.card) else { return }
        if ContactSheet(core: core, card: card).run(on: window) != 0 {
            fill(selectCard: person.card)
        }
    }

    @objc func deleteClicked() {
        deleteSelected()
    }

    /// deletes the group (the groups list in front, or no one selected in it) or the people selected, asking first
    func deleteSelected() {
        if let group = selectedGroup, groupInFront || selectedPeople.isEmpty {
            guard ask(Text.uiGroupDeleteAsk.text(["name": group.name]), title: window.title, yes: Text.uiTbDelete.text,
                      no: Text.uiCancel.text, destructive: true) else { return }
            pe_group_delete(core.handle, group.id)
            fill(selectGroup: 0)
            return
        }
        let ids = selectedPeople.map(\.card).filter { $0 != 0 }
        guard !ids.isEmpty,
              ask(Text.uiBookDeleteAsk.text(["count": ids.count]), title: window.title, yes: Text.uiTbDelete.text,
                  no: Text.uiCancel.text, destructive: true) else { return }
        let next = people.selectedRowIndexes.first ?? 0
        _ = ids.withUnsafeBufferPointer { pe_cards_delete(core.handle, $0.baseAddress, ids.count) }
        fill(selectCard: 0)
        // the one after the deleted ones selected, where they were
        if !rows.isEmpty {
            people.selectRowIndexes(IndexSet(integer: min(next, rows.count - 1)), byExtendingSelection: false)
        }
    }

    /// a new message to the people selected, or to the group selected when no one is
    @objc func writeTo() {
        let chosen = selectedPeople.isEmpty ? selectedGroup.map { [BookEntry(group: $0.id, name: $0.name, address: "", label: $0.label)] } ?? []
            : selectedPeople
        guard !chosen.isEmpty else { return }
        let labels = chosen.map(\.label).filter { !$0.isEmpty }
        guard !labels.isEmpty else {
            inform(Text.uiBookNoAddress.text(["name": chosen[0].title]), title: window.title)
            return
        }
        guard let compose = AppDelegate.shared.main?.newMessage() else { return }
        compose.addRecipients(labels.joined(separator: ", "), field: 0)
        compose.window.makeFirstResponder(compose.subject)
    }

    // ---- the menu commands with the window in front ----

    /// what a command of the menus does with the Address Book in front; false for one that is not its
    func perform(_ command: Command) -> Bool {
        switch command {
        case .delete: deleteSelected()
        case .properties: propertiesClicked()
        case .selectAll: people.selectAll(nil)
        case .find: window.makeFirstResponder(searchField)
        default: return false
        }
        return true
    }

    /// whether a command of the menus is on with the Address Book in front; nil for one of the app
    func validate(_ command: Command) -> Bool? {
        let typing = window.firstResponder is NSText
        switch command {
        case .delete: return !typing && canDelete
        case .properties: return canShowProperties
        case .selectAll, .find: return true
        // the commands of the messages of the main window
        case .reply, .replyAll, .forward, .markRead, .markUnread, .markAllRead, .flag, .move, .copy, .junk, .notJunk, .archive,
             .print, .saveAs, .viewSource, .pictures, .nextMessage, .previousMessage, .nextUnread, .findInMessage, .undo:
            return false
        default: return nil
        }
    }
}

// ---- Add Sender, import and export ----

/// Adds the sender of message `uid` of `folder` to the book: what the status bar says
@MainActor
func addSenderToAddressBook(core: Core, folder: Int64, uid: UInt64) -> String {
    var added = false
    let id = pe_book_add_sender(core.handle, folder, uid, &added)
    guard id != 0 else { return Text.uiSenderNone.text }
    let name = core.bookCard(id).map { $0.name.isEmpty ? $0.addresses.first ?? "" : $0.name } ?? ""
    AddressBookWindow.refresh()
    return (added ? Text.uiSenderAdded : Text.uiSenderKnown).text(["name": name])
}

@MainActor
enum AddressBookFiles {
    /// File > Import Address Book: a vCard or CSV file into the book, how many were added and skipped said
    static func importFile(core: Core) {
        let title = Text.cmdImportAddressBook.title
        let types = [UTType.vCard, .commaSeparatedText, UTType(filenameExtension: "vcf"), UTType(filenameExtension: "csv")]
        guard let file = openFilesPanel(title: title, types: types.compactMap { $0 }, multiple: false).first else { return }
        var added: UInt64 = 0
        var skipped: UInt64 = 0
        var error: UnsafeMutablePointer<CChar>?
        let ok = file.path.withCString { pe_book_import(core.handle, $0, &added, &skipped, &error) }
        let reason = taken(error) ?? ""
        AddressBookWindow.refresh()
        if ok {
            inform(Text.uiBookImported.text(["added": added, "skipped": skipped]), title: title)
        } else {
            inform(Text.uiBookNotImported.text(["reason": reason]), title: title, style: .warning)
        }
    }

    /// File > Export Address Book: every card to a vCard file
    static func exportFile(core: Core) {
        let title = Text.cmdExportAddressBook.title
        guard let file = saveFilePanel(name: Text.uiBookExportName.text + ".vcf", title: title, types: [.vCard]) else { return }
        var written: UInt64 = 0
        var error: UnsafeMutablePointer<CChar>?
        let ok = file.path.withCString { pe_book_export(core.handle, nil, 0, $0, &written, &error) }
        let reason = taken(error) ?? ""
        if ok {
            inform(Text.uiBookExported.text(["count": written, "file": file.lastPathComponent]), title: title)
        } else {
            inform(Text.uiBookNotExported.text(["reason": reason]), title: title, style: .warning)
        }
    }
}

// ---- Contact Properties ----

@MainActor
final class ContactSheet: NSObject, NSTableViewDataSource, NSTableViewDelegate, NSTextFieldDelegate {
    let window: NSWindow
    private let core: Core
    private var card: BookCard
    let first = NSTextField(string: "")
    let last = NSTextField(string: "")
    let display = NSTextField(string: "")
    let nickname = NSTextField(string: "")
    let company = NSTextField(string: "")
    let addressField = NSTextField(string: "")
    let addressList = BookTable()
    private let setDefault = NSButton(title: Text.uiContactSetDefault.text, target: nil, action: nil)
    private let removeAddress = NSButton(title: Text.uiRemove.text, target: nil, action: nil)
    private let phoneKind = NSPopUpButton(frame: .zero, pullsDown: false)
    let phoneField = NSTextField(string: "")
    let phoneList = BookTable()
    private let removePhone = NSButton(title: Text.uiRemove.text, target: nil, action: nil)
    private let notes = NSTextView()
    /// the name shown follows the first and last name until it is typed in
    private var displayFollows: Bool
    private var saved: Int64 = 0

    private static let kinds: [(PePhoneKind, Text)] = [(PE_PHONE_KIND_MOBILE, .uiPhoneMobile), (PE_PHONE_KIND_HOME, .uiPhoneHome),
                                                       (PE_PHONE_KIND_WORK, .uiPhoneWork), (PE_PHONE_KIND_OTHER, .uiPhoneOther)]

    init(core: Core, card: BookCard?) {
        self.core = core
        let editing = card ?? BookCard()
        self.card = editing
        let made = "\(editing.first) \(editing.last)".trimmingCharacters(in: .whitespaces)
        displayFollows = card == nil || editing.name.isEmpty || editing.name == made
        window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 540, height: 600), styleMask: [.titled], backing: .buffered,
                          defer: true)
        super.init()
        window.title = card.map { Text.uiContactTitle.text(["name": $0.name]) } ?? Text.uiNewContactTitle.text
        window.identifier = NSUserInterfaceItemIdentifier("contact")
        first.stringValue = self.card.first
        last.stringValue = self.card.last
        display.stringValue = self.card.name
        nickname.stringValue = self.card.nickname
        company.stringValue = self.card.company
        notes.string = self.card.notes
        for (field, id) in [(first, "contact.first"), (last, "contact.last"), (display, "contact.display"), (nickname, "contact.nickname"),
                            (company, "contact.company"), (addressField, "contact.address"), (phoneField, "contact.phone")] {
            field.setAccessibilityIdentifier(id)
            field.delegate = self
            field.lineBreakMode = .byTruncatingTail
            field.cell?.isScrollable = true
        }
        addressField.placeholderString = Text.uiContactAddressHint.text
        phoneKind.addItems(withTitles: Self.kinds.map { $0.1.text })
        phoneKind.setAccessibilityIdentifier("contact.phone.kind")
        window.contentView = layout()
        window.initialFirstResponder = first
        updateButtons()
    }

    private func layout() -> NSView {
        let addressScroll = bookTable(addressList, id: "contact.addresses", columns: [("address", "", 300)], header: false)
        addressList.dataSource = self
        addressList.delegate = self
        addressList.deletePressed = { [weak self] in self?.removeAddressClicked() }
        let phoneScroll = bookTable(phoneList, id: "contact.phones", columns: [("kind", "", 80), ("number", "", 220)], header: false)
        phoneList.dataSource = self
        phoneList.delegate = self
        phoneList.deletePressed = { [weak self] in self?.removePhoneClicked() }
        let addAddress = NSButton(title: Text.uiContactAdd.text, target: self, action: #selector(addAddressClicked))
        addAddress.setAccessibilityIdentifier("contact.add")
        let addPhone = NSButton(title: Text.uiContactAdd.text, target: self, action: #selector(addPhoneClicked))
        addPhone.setAccessibilityIdentifier("contact.phone.add")
        setDefault.target = self
        setDefault.action = #selector(setDefaultClicked)
        setDefault.setAccessibilityIdentifier("contact.default")
        removeAddress.target = self
        removeAddress.action = #selector(removeAddressClicked)
        removeAddress.setAccessibilityIdentifier("contact.remove")
        removePhone.target = self
        removePhone.action = #selector(removePhoneClicked)
        removePhone.setAccessibilityIdentifier("contact.phone.remove")
        let buttonWidth: CGFloat = 124
        for button in [addAddress, addPhone, setDefault, removeAddress, removePhone] {
            button.widthAnchor.constraint(equalToConstant: buttonWidth).isActive = true
        }
        let addressSide = NSStackView(views: [setDefault, removeAddress, NSView()])
        addressSide.orientation = .vertical
        addressSide.spacing = 6
        let phoneSide = NSStackView(views: [removePhone, NSView()])
        phoneSide.orientation = .vertical
        let addressRow = NSStackView(views: [addressField, addAddress])
        let addressBox = NSStackView(views: [addressScroll, addressSide])
        addressBox.alignment = .top
        let phoneRow = NSStackView(views: [phoneKind, phoneField, addPhone])
        let phoneBox = NSStackView(views: [phoneScroll, phoneSide])
        phoneBox.alignment = .top
        for scroll in [addressScroll, phoneScroll] {
            scroll.heightAnchor.constraint(equalToConstant: 76).isActive = true
        }
        addressSide.heightAnchor.constraint(equalTo: addressScroll.heightAnchor).isActive = true
        phoneSide.heightAnchor.constraint(equalTo: phoneScroll.heightAnchor).isActive = true

        let notesScroll = NSScrollView()
        notesScroll.documentView = notes
        notesScroll.hasVerticalScroller = true
        notesScroll.borderType = .bezelBorder
        notes.isRichText = false
        notes.font = .systemFont(ofSize: NSFont.systemFontSize)
        notes.autoresizingMask = [.width]
        notes.isVerticallyResizable = true
        notes.textContainerInset = NSSize(width: 2, height: 4)
        notes.setAccessibilityIdentifier("contact.notes")
        notesScroll.heightAnchor.constraint(equalToConstant: 64).isActive = true

        let names = NSGridView(views: [
            [formLabel(Text.uiContactFirst.text), first],
            [formLabel(Text.uiContactLast.text), last],
            [formLabel(Text.uiContactDisplay.text), display],
            [formLabel(Text.uiContactNickname.text), nickname],
            [formLabel(Text.uiContactCompany.text), company],
        ])
        let more = NSGridView(views: [
            [formLabel(Text.uiContactAddresses.text), addressRow],
            [NSGridCell.emptyContentView, addressBox],
            [formLabel(Text.uiContactPhones.text), phoneRow],
            [NSGridCell.emptyContentView, phoneBox],
            [formLabel(Text.uiContactNotes.text), notesScroll],
        ])
        let labelWidth: CGFloat = 130
        let fieldWidth: CGFloat = 400
        for grid in [names, more] {
            grid.column(at: 0).xPlacement = .trailing
            grid.column(at: 0).width = labelWidth
            grid.column(at: 1).width = fieldWidth
            grid.rowAlignment = .firstBaseline
            grid.rowSpacing = 8
            grid.columnSpacing = 8
            for row in 0..<grid.numberOfRows {
                grid.cell(atColumnIndex: 1, rowIndex: row).xPlacement = .fill
            }
        }
        for boxRow in [1, 3] {
            more.row(at: boxRow).rowAlignment = .none
            more.row(at: boxRow).yPlacement = .top
        }
        more.row(at: 4).rowAlignment = .none
        more.cell(atColumnIndex: 0, rowIndex: 4).yPlacement = .top
        more.row(at: 2).topPadding = 10
        more.row(at: 4).topPadding = 10
        let line = NSBox()
        line.boxType = .separator

        let cancel = NSButton(title: Text.uiCancel.text, target: self, action: #selector(cancelled))
        cancel.keyEquivalent = "\u{1b}"
        cancel.setAccessibilityIdentifier("contact.cancel")
        let ok = NSButton(title: Text.uiOk.text, target: self, action: #selector(okClicked))
        ok.keyEquivalent = "\r"
        ok.setAccessibilityIdentifier("contact.ok")
        let buttons = buttonRow([cancel, ok])
        let stack = NSStackView(views: [names, line, more, buttons])
        stack.orientation = .vertical
        stack.alignment = .leading
        stack.spacing = 14
        stack.edgeInsets = NSEdgeInsets(top: 20, left: 20, bottom: 20, right: 20)
        stack.setCustomSpacing(20, after: more)
        line.widthAnchor.constraint(equalTo: stack.widthAnchor, constant: -40).isActive = true
        buttons.widthAnchor.constraint(equalTo: stack.widthAnchor, constant: -40).isActive = true
        return stack
    }

    // ---- the lists ----

    func numberOfRows(in tableView: NSTableView) -> Int {
        tableView === addressList ? card.addresses.count : card.phones.count
    }

    func tableView(_ tableView: NSTableView, viewFor column: NSTableColumn?, row: Int) -> NSView? {
        if tableView === addressList {
            let address = card.addresses[row]
            return bookCell(tableView, row == 0 ? Text.uiContactDefault.text(["address": address]) : address)
        }
        let phone = card.phones[row]
        if column?.identifier.rawValue == "kind" {
            return bookCell(tableView, Self.kinds.first { $0.0 == phone.kind }?.1.text ?? "", secondary: true)
        }
        return bookCell(tableView, phone.number)
    }

    func tableViewSelectionDidChange(_ notification: Notification) {
        updateButtons()
    }

    private func updateButtons() {
        setDefault.isEnabled = addressList.selectedRow > 0
        removeAddress.isEnabled = addressList.selectedRow >= 0
        removePhone.isEnabled = phoneList.selectedRow >= 0
    }

    func controlTextDidChange(_ notification: Notification) {
        guard let field = notification.object as? NSTextField else { return }
        if field === display {
            displayFollows = display.stringValue.isEmpty
        } else if (field === first || field === last) && displayFollows {
            display.stringValue = "\(first.stringValue) \(last.stringValue)".trimmingCharacters(in: .whitespaces)
        }
    }

    /// Return in the address or phone field adds it, rather than closing the window
    func control(_ control: NSControl, textView: NSTextView, doCommandBy selector: Selector) -> Bool {
        guard selector == #selector(NSResponder.insertNewline(_:)) else { return false }
        if control === addressField && !addressField.stringValue.isEmpty {
            addAddressClicked()
            return true
        }
        if control === phoneField && !phoneField.stringValue.isEmpty {
            addPhoneClicked()
            return true
        }
        return false
    }

    /// the address typed into the list; false when it is not one
    @discardableResult
    private func addTypedAddress() -> Bool {
        let typed = addressField.stringValue.trimmingCharacters(in: .whitespaces)
        guard !typed.isEmpty else { return true }
        guard isMailbox(typed) else {
            inform(Text.uiContactAddressInvalid.text(["address": typed]), title: window.title, style: .warning)
            window.makeFirstResponder(addressField)
            return false
        }
        if !card.addresses.contains(where: { $0.caseInsensitiveCompare(typed) == .orderedSame }) {
            card.addresses.append(typed)
        }
        addressField.stringValue = ""
        addressList.reloadData()
        updateButtons()
        return true
    }

    private func addTypedPhone() {
        let typed = phoneField.stringValue.trimmingCharacters(in: .whitespaces)
        guard !typed.isEmpty else { return }
        card.phones.append((Self.kinds[max(phoneKind.indexOfSelectedItem, 0)].0, typed))
        phoneField.stringValue = ""
        phoneList.reloadData()
        updateButtons()
    }

    @objc func addAddressClicked() {
        addTypedAddress()
        window.makeFirstResponder(addressField)
    }

    @objc func setDefaultClicked() {
        let row = addressList.selectedRow
        guard row > 0 else { return }
        card.addresses.insert(card.addresses.remove(at: row), at: 0)
        addressList.reloadData()
        addressList.selectRowIndexes(IndexSet(integer: 0), byExtendingSelection: false)
    }

    @objc func removeAddressClicked() {
        let row = addressList.selectedRow
        guard card.addresses.indices.contains(row) else { return }
        card.addresses.remove(at: row)
        addressList.reloadData()
        updateButtons()
    }

    @objc func addPhoneClicked() {
        addTypedPhone()
        window.makeFirstResponder(phoneField)
    }

    @objc func removePhoneClicked() {
        let row = phoneList.selectedRow
        guard card.phones.indices.contains(row) else { return }
        card.phones.remove(at: row)
        phoneList.reloadData()
        updateButtons()
    }

    @objc func okClicked() {
        // what is typed and not added yet counts too
        guard addTypedAddress() else { return }
        addTypedPhone()
        let trim = { (field: NSTextField) in field.stringValue.trimmingCharacters(in: .whitespaces) }
        card.first = trim(first)
        card.last = trim(last)
        card.name = trim(display)
        card.nickname = trim(nickname)
        card.company = trim(company)
        card.notes = notes.string
        if card.first.isEmpty && card.last.isEmpty && card.name.isEmpty && card.addresses.isEmpty {
            inform(Text.uiContactNameNeeded.text, title: window.title, style: .warning)
            window.makeFirstResponder(first)
            return
        }
        // no name at all: the default address is the name shown
        if card.first.isEmpty && card.last.isEmpty && card.name.isEmpty {
            card.name = card.addresses[0]
        }
        switch core.saveBookCard(card) {
        case .success(let id):
            saved = id
            NSApp.stopModal()
        case .failure(let refusal):
            inform(Text.uiContactNotSaved.text(["reason": refusal.reason]), title: window.title, style: .warning)
        }
    }

    @objc private func cancelled() {
        NSApp.stopModal()
    }

    /// the id saved, 0 when cancelled
    func run(on parent: NSWindow?) -> Int64 {
        runSheet(window, on: parent)
        return saved
    }
}

// ---- Group Properties ----

@MainActor
final class GroupSheet: NSObject, NSTableViewDataSource, NSTableViewDelegate, NSTextFieldDelegate {
    let window: NSWindow
    private let core: Core
    private let id: Int64
    let name = NSTextField(string: "")
    let memberList = BookTable()
    private(set) var members: [BookEntry] = []
    private let count = NSTextField(labelWithString: "")
    private let remove = NSButton(title: Text.uiRemove.text, target: nil, action: nil)
    let addressField = NSTextField(string: "")
    private var saved: Int64 = 0

    init(core: Core, id: Int64) {
        self.core = core
        self.id = id
        window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 520, height: 460), styleMask: [.titled], backing: .buffered,
                          defer: true)
        super.init()
        if id != 0, let group = core.bookGroup(id) {
            name.stringValue = group.name
            members = group.members
            window.title = Text.uiGroupTitle.text(["name": group.name])
        } else {
            window.title = Text.uiNewGroupTitle.text
        }
        window.identifier = NSUserInterfaceItemIdentifier("group")
        name.setAccessibilityIdentifier("group.name")
        addressField.setAccessibilityIdentifier("group.address")
        addressField.placeholderString = Text.uiContactAddressHint.text
        addressField.delegate = self
        window.contentView = layout()
        window.initialFirstResponder = name
        showCount()
    }

    private func layout() -> NSView {
        let scroll = bookTable(memberList, id: "group.members", columns: [("name", Text.uiColName.text, 170), ("email", Text.uiColEmail.text, 190)])
        memberList.dataSource = self
        memberList.delegate = self
        memberList.allowsMultipleSelection = true
        memberList.deletePressed = { [weak self] in self?.removeClicked() }
        scroll.heightAnchor.constraint(equalToConstant: 180).isActive = true
        let select = NSButton(title: Text.uiGroupSelectMembers.text, target: self, action: #selector(selectMembers))
        select.setAccessibilityIdentifier("group.select")
        remove.target = self
        remove.action = #selector(removeClicked)
        remove.setAccessibilityIdentifier("group.remove")
        let add = NSButton(title: Text.uiContactAdd.text, target: self, action: #selector(addClicked))
        add.setAccessibilityIdentifier("group.add")
        for button in [select, remove, add] {
            button.widthAnchor.constraint(equalToConstant: 150).isActive = true
        }
        let side = NSStackView(views: [select, remove, NSView()])
        side.orientation = .vertical
        side.spacing = 6
        count.textColor = .secondaryLabelColor
        count.font = .systemFont(ofSize: NSFont.smallSystemFontSize)
        count.setAccessibilityIdentifier("group.count")
        let membersTitle = NSTextField(labelWithString: Text.uiGroupMembers.text)
        let membersHead = NSStackView(views: [membersTitle, NSView(), count])
        let membersBox = NSStackView(views: [scroll, side])
        membersBox.alignment = .top
        side.heightAnchor.constraint(equalTo: scroll.heightAnchor).isActive = true
        let newMember = NSTextField(labelWithString: Text.uiGroupNewMember.text)
        let addRow = NSStackView(views: [addressField, add])
        let nameRow = NSStackView(views: [NSTextField(labelWithString: Text.uiGroupName.text), name])

        let cancel = NSButton(title: Text.uiCancel.text, target: self, action: #selector(cancelled))
        cancel.keyEquivalent = "\u{1b}"
        let ok = NSButton(title: Text.uiOk.text, target: self, action: #selector(okClicked))
        ok.keyEquivalent = "\r"
        ok.setAccessibilityIdentifier("group.ok")
        let buttons = buttonRow([cancel, ok])
        let stack = NSStackView(views: [nameRow, membersHead, membersBox, newMember, addRow, buttons])
        stack.orientation = .vertical
        stack.alignment = .leading
        stack.spacing = 8
        stack.edgeInsets = NSEdgeInsets(top: 20, left: 20, bottom: 20, right: 20)
        stack.setCustomSpacing(18, after: nameRow)
        stack.setCustomSpacing(18, after: membersBox)
        stack.setCustomSpacing(20, after: addRow)
        let width: CGFloat = 540
        for row in [nameRow, membersHead, membersBox, addRow, buttons] {
            row.widthAnchor.constraint(equalToConstant: width).isActive = true
        }
        return stack
    }

    private func showCount() {
        count.stringValue = Text.uiGroupMembersCount.text(["count": members.count])
        remove.isEnabled = memberList.selectedRow >= 0
    }

    func numberOfRows(in tableView: NSTableView) -> Int { members.count }

    func tableView(_ tableView: NSTableView, viewFor column: NSTableColumn?, row: Int) -> NSView? {
        let member = members[row]
        if column?.identifier.rawValue == "name" {
            return bookCell(tableView, member.title, image: member.card != 0 ? BookIcons.person : BookIcons.typed,
                            secondary: member.name.isEmpty)
        }
        return bookCell(tableView, member.address)
    }

    func tableViewSelectionDidChange(_ notification: Notification) {
        showCount()
    }

    func control(_ control: NSControl, textView: NSTextView, doCommandBy selector: Selector) -> Bool {
        guard selector == #selector(NSResponder.insertNewline(_:)), control === addressField, !addressField.stringValue.isEmpty else { return false }
        addClicked()
        return true
    }

    /// whether the group has this one already: the same card, or the same address
    private func has(_ entry: BookEntry) -> Bool {
        members.contains { member in
            entry.card != 0 && member.card == entry.card
                || !entry.address.isEmpty && member.address.caseInsensitiveCompare(entry.address) == .orderedSame
        }
    }

    private func add(_ entries: [BookEntry]) {
        for entry in entries where !has(entry) {
            members.append(entry)
        }
        memberList.reloadData()
        showCount()
    }

    @objc func selectMembers() {
        guard let chosen = PeoplePicker(core: core, kind: .members).run(on: window) else { return }
        add(chosen[0])
    }

    @objc func addClicked() {
        _ = addTypedAddress()
        window.makeFirstResponder(addressField)
    }

    private func addTypedAddress() -> Bool {
        let typed = addressField.stringValue.trimmingCharacters(in: .whitespaces)
        guard !typed.isEmpty else { return true }
        guard isMailbox(typed) else {
            inform(Text.uiContactAddressInvalid.text(["address": typed]), title: window.title, style: .warning)
            return false
        }
        add([BookEntry(name: "", address: typed, label: typed)])
        addressField.stringValue = ""
        return true
    }

    @objc func removeClicked() {
        let rows = memberList.selectedRowIndexes
        guard !rows.isEmpty else { return }
        members = members.enumerated().filter { !rows.contains($0.offset) }.map(\.element)
        memberList.reloadData()
        showCount()
    }

    @objc func okClicked() {
        guard addTypedAddress() else { return }
        let groupName = name.stringValue.trimmingCharacters(in: .whitespaces)
        guard !groupName.isEmpty else {
            inform(Text.uiGroupNameNeeded.text, title: window.title, style: .warning)
            window.makeFirstResponder(name)
            return
        }
        switch core.saveBookGroup(id: id, name: groupName, members: members) {
        case .success(let saved):
            self.saved = saved
            NSApp.stopModal()
        case .failure(let refusal):
            inform(Text.uiGroupNotSaved.text(["reason": refusal.reason]), title: window.title, style: .warning)
        }
    }

    @objc private func cancelled() {
        NSApp.stopModal()
    }

    /// the id saved, 0 when cancelled
    func run(on parent: NSWindow?) -> Int64 {
        runSheet(window, on: parent)
        return saved
    }
}

// ---- Select Recipients and Select Group Members ----

/// Outlook Express's picker: the book's groups and people on the left, the buttons that put the selected ones in a list
/// on the right (To, Cc and Bcc, or the group's members)
@MainActor
final class PeoplePicker: NSObject, NSTableViewDataSource, NSTableViewDelegate, NSMenuDelegate {
    enum Kind {
        case recipients, members
    }

    let window: NSWindow
    private let core: Core
    private let kind: Kind
    let searchField = NSSearchField()
    let source = BookTable()
    private(set) var found: [BookEntry] = []
    /// the lists on the right, each with what was put in it
    private(set) var lists: [BookTable] = []
    private(set) var chosen: [[BookEntry]] = []
    private var accepted = false

    init(core: Core, kind: Kind) {
        self.core = core
        self.kind = kind
        window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 700, height: 440), styleMask: [.titled], backing: .buffered,
                          defer: true)
        super.init()
        window.title = kind == .recipients ? Text.uiSelectRecipients.text : Text.uiSelectMembers.text
        window.identifier = NSUserInterfaceItemIdentifier("pick")
        window.contentView = layout()
        window.initialFirstResponder = searchField
        fill()
    }

    private func layout() -> NSView {
        let intro = NSTextField(labelWithString: Text.uiPickIntro.text)
        searchField.placeholderString = Text.uiBookFindHint.text
        searchField.sendsSearchStringImmediately = true
        searchField.target = self
        searchField.action = #selector(findChanged)
        searchField.setAccessibilityIdentifier("pick.find")
        let sourceScroll = bookTable(source, id: "pick.list", columns: [("name", Text.uiColName.text, 150), ("email", Text.uiColEmail.text, 160)])
        source.allowsMultipleSelection = true
        source.dataSource = self
        source.delegate = self
        source.target = self
        source.doubleAction = #selector(sourceDoubleClicked)
        let left = NSStackView(views: [intro, searchField, sourceScroll])
        left.orientation = .vertical
        left.alignment = .leading
        left.spacing = 8
        searchField.widthAnchor.constraint(equalTo: sourceScroll.widthAnchor).isActive = true
        sourceScroll.widthAnchor.constraint(equalToConstant: 330).isActive = true
        sourceScroll.heightAnchor.constraint(equalToConstant: 300).isActive = true

        let targets: [(Text, String)] = kind == .recipients ? [(.uiPickTo, "to"), (.uiPickCc, "cc"), (.uiPickBcc, "bcc")] : [(.uiPickAdd, "add")]
        let heading = NSTextField(labelWithString: kind == .recipients ? Text.uiPickRecipients.text : Text.uiPickMembers.text)
        var rows: [NSView] = [heading]
        // the lists as tall together as the find box and the list at the left
        let listHeight: CGFloat = kind == .recipients ? 100 : 330
        for (index, (title, id)) in targets.enumerated() {
            let button = NSButton(title: title.text, target: self, action: #selector(putSelected(_:)))
            button.tag = index
            button.setAccessibilityIdentifier("pick.\(id)")
            button.widthAnchor.constraint(equalToConstant: 76).isActive = true
            let list = BookTable()
            let scroll = bookTable(list, id: "pick.chosen.\(id)", columns: [("name", "", 200)], header: false)
            list.dataSource = self
            list.delegate = self
            list.allowsMultipleSelection = true
            list.deletePressed = { [weak self, weak list] in
                if let list { self?.removeSelected(from: list) }
            }
            list.menu = NSMenu()
            list.menu?.delegate = self
            scroll.widthAnchor.constraint(equalToConstant: 220).isActive = true
            scroll.heightAnchor.constraint(equalToConstant: listHeight).isActive = true
            lists.append(list)
            chosen.append([])
            let row = NSStackView(views: [button, scroll])
            row.alignment = .top
            rows.append(row)
        }
        let right = NSStackView(views: rows)
        right.orientation = .vertical
        right.alignment = .leading
        right.spacing = 8
        // the heading over the lists, not over the buttons, as the intro is over the find box
        heading.leadingAnchor.constraint(equalTo: right.leadingAnchor, constant: 84).isActive = true

        let columns = NSStackView(views: [left, right])
        columns.alignment = .top
        columns.spacing = 16
        let cancel = NSButton(title: Text.uiCancel.text, target: self, action: #selector(cancelled))
        cancel.keyEquivalent = "\u{1b}"
        let ok = NSButton(title: Text.uiOk.text, target: self, action: #selector(okClicked))
        ok.keyEquivalent = "\r"
        ok.setAccessibilityIdentifier("pick.ok")
        let buttons = buttonRow([cancel, ok])
        let stack = NSStackView(views: [columns, buttons])
        stack.orientation = .vertical
        stack.alignment = .leading
        stack.spacing = 20
        stack.edgeInsets = NSEdgeInsets(top: 20, left: 20, bottom: 20, right: 20)
        buttons.widthAnchor.constraint(equalTo: stack.widthAnchor, constant: -40).isActive = true
        return stack
    }

    /// the groups (for recipients) and the people the find box finds
    private func fill() {
        let words = searchField.stringValue.trimmingCharacters(in: .whitespaces)
        let lower = words.lowercased()
        var entries: [BookEntry] = []
        if kind == .recipients {
            entries = core.bookGroups().filter { group in
                words.isEmpty || group.name.lowercased().split(separator: " ").contains { $0.hasPrefix(lower) }
            }.map { BookEntry(group: $0.id, name: $0.name, address: "", label: $0.label, count: $0.count) }
        }
        entries += core.bookCards(words)
        found = entries
        source.reloadData()
    }

    @objc private func findChanged() {
        fill()
    }

    func find(_ words: String) {
        searchField.stringValue = words
        fill()
    }

    func numberOfRows(in tableView: NSTableView) -> Int {
        if tableView === source { return found.count }
        return lists.firstIndex { $0 === tableView }.map { chosen[$0].count } ?? 0
    }

    func tableView(_ tableView: NSTableView, viewFor column: NSTableColumn?, row: Int) -> NSView? {
        let entry: BookEntry
        if tableView === source {
            entry = found[row]
        } else if let index = lists.firstIndex(where: { $0 === tableView }) {
            entry = chosen[index][row]
        } else {
            return nil
        }
        if column?.identifier.rawValue == "email" {
            return bookCell(tableView, entry.isGroup ? Text.uiGroupMembersCount.text(["count": entry.count]) : entry.address,
                            secondary: entry.isGroup)
        }
        let cell = bookCell(tableView, entry.title, image: entry.isGroup ? BookIcons.group : BookIcons.person)
        cell.toolTip = entry.label
        return cell
    }

    /// the people selected on the left into list `index`, each once
    func put(into index: Int) {
        let selected = source.selectedRowIndexes.compactMap { found.indices.contains($0) ? found[$0] : nil }
        for entry in selected where !chosen[index].contains(where: { $0.card == entry.card && $0.group == entry.group }) {
            chosen[index].append(entry)
        }
        lists[index].reloadData()
    }

    @objc private func putSelected(_ sender: NSButton) {
        put(into: sender.tag)
    }

    @objc private func sourceDoubleClicked() {
        guard source.clickedRow >= 0 else { return }
        put(into: 0)
    }

    private func removeSelected(from list: BookTable) {
        guard let index = lists.firstIndex(where: { $0 === list }) else { return }
        let rows = list.selectedRowIndexes
        chosen[index] = chosen[index].enumerated().filter { !rows.contains($0.offset) }.map(\.element)
        list.reloadData()
    }

    /// the right-click menu of a list on the right: Remove
    func menuNeedsUpdate(_ menu: NSMenu) {
        menu.removeAllItems()
        guard let list = lists.first(where: { $0.menu === menu }), list.clickedRow >= 0 else { return }
        if !list.selectedRowIndexes.contains(list.clickedRow) {
            list.selectRowIndexes(IndexSet(integer: list.clickedRow), byExtendingSelection: false)
        }
        let item = NSMenuItem(title: Text.uiRemove.text, action: #selector(removeFromMenu(_:)), keyEquivalent: "")
        item.target = self
        item.representedObject = list
        menu.addItem(item)
    }

    @objc private func removeFromMenu(_ sender: NSMenuItem) {
        if let list = sender.representedObject as? BookTable {
            removeSelected(from: list)
        }
    }

    @objc func okClicked() {
        accepted = true
        NSApp.stopModal()
    }

    @objc private func cancelled() {
        NSApp.stopModal()
    }

    /// what was put in each list, nil when cancelled
    func run(on parent: NSWindow?) -> [[BookEntry]]? {
        runSheet(window, on: parent)
        return accepted ? chosen : nil
    }
}
