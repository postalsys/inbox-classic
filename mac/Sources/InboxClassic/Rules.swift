// Message rules: the Message Rules window (Tools) with the rules in their order, each turned on or off, and the editor
// of one. The core keeps and runs the rules; what is typed goes to it as it is, and it says why a rule can not be saved.
import AppKit
import CInboxClassic

/// A rule as the core gives it
struct Rule {
    var id: Int64 = 0
    var enabled = true
    var name = ""
    var account: Int64 = 0
    var query = ""
    var moveTo: Int64 = 0
    var markRead = false
    var flag = false
    var archive = false
    var junk = false
    var remove = false
    var quiet = false

    init(name: String = "", query: String = "") {
        self.name = name
        self.query = query
    }

    init(_ rule: PeRule) {
        id = rule.id
        enabled = rule.enabled
        name = text(rule.name)
        account = rule.account
        query = text(rule.query)
        moveTo = rule.move_to
        markRead = rule.mark_read
        flag = rule.flag
        archive = rule.archive
        junk = rule.junk
        remove = rule.remove
        quiet = rule.quiet
    }

    static func all(_ core: Core) -> [Rule] {
        guard let list = pe_rules(core.handle) else { return [] }
        defer { pe_rules_free(list) }
        return (0..<pe_rules_count(list)).compactMap { pe_rules_get(list, $0).map { Rule($0.pointee) } }
    }

    /// saved: its id, or 0 with why not
    func save(_ core: Core) -> (id: Int64, problem: String?) {
        let strings = CStrings()
        var rule = PeRule(id: id, enabled: enabled, name: strings.add(name), account: account, query: strings.add(query),
                          move_to: moveTo, mark_read: markRead, flag: flag, archive: archive, junk: junk, remove: remove,
                          quiet: quiet)
        var error: UnsafeMutablePointer<CChar>?
        let saved = pe_rule_save(core.handle, &rule, &error)
        let problem = taken(error)
        return (saved, saved == 0 ? problem ?? Text.uiUnknownReason.text : nil)
    }
}

/// What the editor ended with
enum RuleEditorResult {
    case cancelled
    case saved(Int64)
    /// Show: the words for the main window's search box
    case show(String)
}

// ---- the editor ----

@MainActor
enum RuleEditor {
    /// edits `rule` (id 0: a new one) in a window of its own
    static func run(core: Core, rule: Rule) -> RuleEditorResult {
        RuleEditorWindow(core: core, rule: rule).run()
    }

    /// a new rule from the main window (a message, the search typed): Show searches there
    static func create(core: Core, query: String) {
        if case .show(let words) = run(core: core, rule: Rule(name: query, query: query)) {
            AppDelegate.shared.main?.search(for: words)
        }
    }
}

@MainActor
private final class RuleEditorWindow: NSObject, NSTextFieldDelegate {
    private let window: NSWindow
    private let core: Core
    private var rule: Rule
    private var accounts: [Account] = []
    /// every folder a rule can move to, and those the folder choice offers now (the chosen account's)
    private var allTargets: [(folder: Int64, account: Int64, label: String)] = []
    private var targets: [(folder: Int64, label: String)] = []
    private let name = NSTextField(string: "")
    private let account = NSPopUpButton(frame: .zero, pullsDown: false)
    private let query = NSTextField(string: "")
    private let count = NSTextField(labelWithString: "")
    private let show = NSButton(title: Text.uiRuleShow.text, target: nil, action: nil)
    private let move = NSButton(checkboxWithTitle: Text.uiRuleMove.text, target: nil, action: nil)
    private let target = NSPopUpButton(frame: .zero, pullsDown: false)
    private let markRead = NSButton(checkboxWithTitle: Text.uiRuleMarkRead.text, target: nil, action: nil)
    private let flag = NSButton(checkboxWithTitle: Text.uiRuleFlag.text, target: nil, action: nil)
    private let archive = NSButton(checkboxWithTitle: Text.uiRuleArchive.text, target: nil, action: nil)
    private let junk = NSButton(checkboxWithTitle: Text.uiRuleJunk.text, target: nil, action: nil)
    private let remove = NSButton(checkboxWithTitle: Text.uiRuleDelete.text, target: nil, action: nil)
    private let quiet = NSButton(checkboxWithTitle: Text.uiRuleQuiet.text, target: nil, action: nil)
    private let applyNow = NSButton(checkboxWithTitle: Text.uiRuleApplyNow.text, target: nil, action: nil)
    private var result = RuleEditorResult.cancelled

    init(core: Core, rule: Rule) {
        self.core = core
        self.rule = rule
        window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 560, height: 480), styleMask: [.titled], backing: .buffered,
                          defer: true)
        window.autorecalculatesKeyViewLoop = true
        window.title = Text.uiRuleTitle.text
        window.identifier = NSUserInterfaceItemIdentifier("rule")
        super.init()
        accounts = core.accounts()
        if let list = pe_rule_targets(core.handle) {
            defer { pe_rule_targets_free(list) }
            for index in 0..<pe_rule_targets_count(list) {
                guard let item = pe_rule_targets_get(list, index)?.pointee else { continue }
                allTargets.append((item.folder, item.account, text(item.label)))
            }
        }
        fill()
        for (view, id) in [(name, "rule.name"), (account, "rule.account"), (query, "rule.query"), (count, "rule.count"),
                           (show, "rule.show"), (move, "rule.move"), (target, "rule.target"), (markRead, "rule.read"),
                           (flag, "rule.flag"), (archive, "rule.archive"), (junk, "rule.junk"), (remove, "rule.delete"),
                           (quiet, "rule.quiet"), (applyNow, "rule.apply")] as [(NSView, String)] {
            view.setAccessibilityIdentifier(id)
        }
        let content = layout()
        window.contentView = content
        // as tall as the form, no taller: extra height would open a gap in it
        window.setContentSize(NSSize(width: 560, height: content.fittingSize.height))
        window.initialFirstResponder = rule.id == 0 && !rule.query.isEmpty ? query : name
        showCount()
    }

    private func fill() {
        name.stringValue = rule.name
        query.stringValue = rule.query
        query.delegate = self
        account.addItem(withTitle: Text.uiRuleAllAccounts.text)
        account.menu?.addItem(.separator())
        for item in accounts {
            account.addItem(withTitle: item.label)
        }
        account.selectItem(at: accounts.firstIndex { $0.id == rule.account }.map { $0 + 2 } ?? 0)
        account.target = self
        account.action = #selector(accountChanged)
        fillTargets(keep: rule.moveTo)
        move.state = rule.moveTo != 0 ? .on : .off
        markRead.state = rule.markRead ? .on : .off
        flag.state = rule.flag ? .on : .off
        archive.state = rule.archive ? .on : .off
        junk.state = rule.junk ? .on : .off
        remove.state = rule.remove ? .on : .off
        quiet.state = rule.quiet ? .on : .off
        // the places a message goes to: one of them, as only one can be done
        for box in [move, archive, junk, remove] {
            box.target = self
            box.action = #selector(awayChanged(_:))
        }
        target.isEnabled = move.state == .on
        show.target = self
        show.action = #selector(showClicked)
    }

    private func layout() -> NSView {
        let hint = NSTextField(wrappingLabelWithString: Text.uiRuleQueryHint.text)
        hint.isSelectable = false
        hint.textColor = .secondaryLabelColor
        hint.font = .systemFont(ofSize: NSFont.smallSystemFontSize)
        count.textColor = .secondaryLabelColor
        count.lineBreakMode = .byTruncatingTail
        count.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        count.setContentHuggingPriority(.init(1), for: .horizontal)
        show.bezelStyle = .push
        show.controlSize = .small
        show.font = .systemFont(ofSize: NSFont.smallSystemFontSize)
        let countRow = NSStackView(views: [count, show])
        countRow.distribution = .fill
        countRow.alignment = .centerY
        target.setContentHuggingPriority(.init(1), for: .horizontal)
        // the hint and the count under the query, as wide as its column
        let below = NSStackView(views: [hint, countRow])
        below.orientation = .vertical
        below.alignment = .leading
        below.spacing = 6
        hint.preferredMaxLayoutWidth = 380
        hint.widthAnchor.constraint(equalToConstant: 380).isActive = true
        countRow.widthAnchor.constraint(equalToConstant: 380).isActive = true
        let moveRow = NSStackView(views: [move, target])
        moveRow.distribution = .fill
        moveRow.alignment = .firstBaseline
        let grid = NSGridView(views: [
            [NSTextField(labelWithString: Text.uiRuleName.text), name],
            [NSTextField(labelWithString: Text.uiRuleAccount.text), account],
            [NSTextField(labelWithString: Text.uiRuleQuery.text), query],
            [NSGridCell.emptyContentView, below],
            [NSTextField(labelWithString: Text.uiRuleActions.text), moveRow],
            [NSGridCell.emptyContentView, markRead],
            [NSGridCell.emptyContentView, flag],
            [NSGridCell.emptyContentView, archive],
            [NSGridCell.emptyContentView, junk],
            [NSGridCell.emptyContentView, remove],
            [NSGridCell.emptyContentView, quiet],
        ])
        grid.column(at: 0).xPlacement = .trailing
        grid.column(at: 1).width = 380
        grid.column(at: 1).xPlacement = .fill
        grid.rowAlignment = .firstBaseline
        grid.rowSpacing = 8
        // under the query, with no label to line up with
        grid.row(at: 3).rowAlignment = .none
        grid.row(at: 3).bottomPadding = 8
        grid.cell(for: account)?.xPlacement = .leading
        for box in [markRead, flag, archive, junk, remove, quiet] {
            grid.cell(for: box)?.xPlacement = .leading
        }
        let line = NSBox()
        line.boxType = .separator
        let cancel = NSButton(title: Text.uiCancel.text, target: self, action: #selector(cancelled))
        cancel.keyEquivalent = "\u{1b}"
        cancel.setAccessibilityIdentifier("rule.cancel")
        let ok = NSButton(title: Text.uiOk.text, target: self, action: #selector(okClicked))
        ok.keyEquivalent = "\r"
        ok.setAccessibilityIdentifier("rule.ok")
        let buttons = buttonRow([cancel, ok], help: "message-rules")
        let stack = NSStackView(views: [grid, line, applyNow, buttons])
        stack.orientation = .vertical
        stack.alignment = .leading
        stack.spacing = 12
        stack.setCustomSpacing(20, after: applyNow)
        stack.edgeInsets = NSEdgeInsets(top: 20, left: 20, bottom: 20, right: 20)
        line.widthAnchor.constraint(equalTo: stack.widthAnchor, constant: -40).isActive = true
        buttons.widthAnchor.constraint(equalTo: stack.widthAnchor, constant: -40).isActive = true
        // under the check boxes of the actions, in the form's second column
        applyNow.leadingAnchor.constraint(equalTo: name.leadingAnchor).isActive = true
        return stack
    }

    /// how many messages in the Inbox the query matches now, or why it can not be a rule's
    @objc private func showCount() {
        let typed = query.stringValue.trimmingCharacters(in: .whitespaces)
        let problem = typed.withCString { taken(pe_rule_query_problem(core.handle, $0)) }
        if typed.isEmpty {
            count.stringValue = ""
        } else if let problem {
            count.stringValue = problem
        } else {
            let matches = typed.withCString { pe_rule_matches(core.handle, $0, selectedAccount) }
            count.stringValue = Text.uiRuleCount.text(["count": matches])
        }
        count.toolTip = count.stringValue
        show.isEnabled = !typed.isEmpty && problem == nil
    }

    /// counted again once typing stops for a moment, not at each key (in the modal window's run loop mode too)
    func controlTextDidChange(_ notification: Notification) {
        NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(showCount), object: nil)
        perform(#selector(showCount), with: nil, afterDelay: 0.3, inModes: [.common])
    }

    /// the folder choice with the chosen account's folders (every account's for All accounts), `keep` chosen when it
    /// is one of them
    private func fillTargets(keep: Int64) {
        let chosen = selectedAccount
        targets = allTargets.filter { chosen == 0 || $0.account == chosen }.map { ($0.folder, $0.label) }
        target.removeAllItems()
        // a menu item's title is unique in a popup: the labels go in as items of their own
        for item in targets {
            target.menu?.addItem(NSMenuItem(title: item.label, action: nil, keyEquivalent: ""))
        }
        target.selectItem(at: targets.firstIndex { $0.folder == keep } ?? 0)
        move.isEnabled = !targets.isEmpty
        if targets.isEmpty {
            move.state = .off
            target.isEnabled = false
        }
    }

    @objc private func accountChanged() {
        let index = target.indexOfSelectedItem
        fillTargets(keep: targets.indices.contains(index) ? targets[index].folder : 0)
        showCount()
    }

    private var selectedAccount: Int64 {
        let index = account.indexOfSelectedItem - 2
        return accounts.indices.contains(index) ? accounts[index].id : 0
    }

    @objc private func awayChanged(_ sender: NSButton) {
        if sender.state == .on {
            for box in [move, archive, junk, remove] where box !== sender {
                box.state = .off
            }
        }
        target.isEnabled = move.state == .on
        if sender === move, move.state == .on {
            window.makeFirstResponder(target)
        }
    }

    /// Show: the rule windows close, the main window searches the Inboxes for it
    @objc private func showClicked() {
        let typed = query.stringValue.trimmingCharacters(in: .whitespaces)
        result = .show(typed.withCString { taken(pe_rule_search_text(core.handle, $0)) } ?? typed)
        NSApp.stopModal()
    }

    /// OK: saved, then applied to the Inbox when asked; the editor stays open with the reason when it can not be
    @objc private func okClicked() {
        rule.query = query.stringValue.trimmingCharacters(in: .whitespaces)
        // one without a name is called by what it matches (the core does that)
        rule.name = name.stringValue.trimmingCharacters(in: .whitespaces)
        rule.account = selectedAccount
        let index = target.indexOfSelectedItem
        rule.moveTo = move.state == .on && targets.indices.contains(index) ? targets[index].folder : 0
        rule.markRead = markRead.state == .on
        rule.flag = flag.state == .on
        rule.archive = archive.state == .on
        rule.junk = junk.state == .on
        rule.remove = remove.state == .on
        rule.quiet = quiet.state == .on
        let (id, problem) = rule.save(core)
        guard id != 0 else {
            inform(problem ?? Text.uiUnknownReason.text, title: Text.uiRuleTitle.text, style: .warning)
            window.makeFirstResponder(query)
            return
        }
        if applyNow.state == .on {
            pe_rule_apply_now(core.handle, id)
        }
        result = .saved(id)
        NSApp.stopModal()
    }

    @objc private func cancelled() {
        NSApp.stopModal()
    }

    func run() -> RuleEditorResult {
        window.center()
        Modal.opened(window)
        NSApp.runModal(for: window)
        Modal.closed(window)
        window.orderOut(nil)
        return result
    }
}

// ---- the Message Rules window ----

@MainActor
enum RulesWindow {
    static func open(core: Core) {
        if let words = RulesListWindow(core: core).run() {
            AppDelegate.shared.main?.search(for: words)
        }
    }
}

/// A table that hands Delete (the key) to a closure
private final class RulesTable: NSTableView {
    var deletePressed: () -> Void = {}

    override func keyDown(with event: NSEvent) {
        if event.keyCode == 51 || event.keyCode == 117 {
            deletePressed()
            return
        }
        super.keyDown(with: event)
    }
}

@MainActor
private final class RulesListWindow: NSObject, NSTableViewDataSource, NSTableViewDelegate {
    private let window: NSWindow
    private let core: Core
    private let table = RulesTable()
    private let empty = NSTextField(wrappingLabelWithString: Text.uiRulesNone.text)
    private let edit = NSButton(title: Text.uiRuleEdit.text.replacingOccurrences(of: "...", with: "…"), target: nil, action: nil)
    private let delete = NSButton(title: Text.uiRuleDeleteButton.text, target: nil, action: nil)
    private let up = NSButton(title: Text.uiAccountMoveUp.text, target: nil, action: nil)
    private let down = NSButton(title: Text.uiAccountMoveDown.text, target: nil, action: nil)
    private var rules: [Rule] = []
    /// Show in the editor: the words to search for once the window is closed
    private var show: String?

    init(core: Core) {
        self.core = core
        window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 680, height: 360), styleMask: [.titled, .resizable],
                          backing: .buffered, defer: true)
        window.autorecalculatesKeyViewLoop = true
        window.title = Text.uiRulesTitle.text
        window.identifier = NSUserInterfaceItemIdentifier("rules")
        window.contentMinSize = NSSize(width: 560, height: 300)
        super.init()
        for (id, title, width) in [("on", "", 24.0), ("name", Text.uiColName.text, 200.0),
                                   ("query", Text.uiColRuleMatches.text, 280.0)] {
            let column = NSTableColumn(identifier: NSUserInterfaceItemIdentifier(id))
            column.title = title
            column.width = width
            column.minWidth = id == "on" ? 24 : 80
            table.addTableColumn(column)
        }
        table.dataSource = self
        table.delegate = self
        table.usesAlternatingRowBackgroundColors = true
        table.columnAutoresizingStyle = .lastColumnOnlyAutoresizingStyle
        table.target = self
        table.doubleAction = #selector(editClicked)
        table.deletePressed = { [weak self] in self?.deleteClicked() }
        table.setAccessibilityIdentifier("rules.list")
        let scroll = NSScrollView()
        scroll.documentView = table
        scroll.hasVerticalScroller = true
        scroll.autohidesScrollers = true
        scroll.borderType = .bezelBorder
        // with no rules, what to do in the middle of the list
        empty.isSelectable = false
        empty.alignment = .center
        empty.textColor = .secondaryLabelColor
        empty.translatesAutoresizingMaskIntoConstraints = false
        empty.setAccessibilityIdentifier("rules.none")
        // over the list's scroll view, as a subview of it would be under its rows
        let listArea = NSView()
        scroll.translatesAutoresizingMaskIntoConstraints = false
        listArea.addSubview(scroll)
        listArea.addSubview(empty)
        NSLayoutConstraint.activate([
            scroll.leadingAnchor.constraint(equalTo: listArea.leadingAnchor),
            scroll.trailingAnchor.constraint(equalTo: listArea.trailingAnchor),
            scroll.topAnchor.constraint(equalTo: listArea.topAnchor),
            scroll.bottomAnchor.constraint(equalTo: listArea.bottomAnchor),
            empty.centerXAnchor.constraint(equalTo: scroll.centerXAnchor),
            empty.centerYAnchor.constraint(equalTo: scroll.centerYAnchor, constant: 12),
            empty.widthAnchor.constraint(lessThanOrEqualTo: scroll.widthAnchor, constant: -40),
        ])
        let new = NSButton(title: Text.uiRuleNew.text.replacingOccurrences(of: "...", with: "…"), target: self, action: #selector(newClicked))
        new.setAccessibilityIdentifier("rules.new")
        for (button, action, id) in [(edit, #selector(editClicked), "rules.edit"), (delete, #selector(deleteClicked), "rules.delete"),
                                     (up, #selector(upClicked), "rules.up"), (down, #selector(downClicked), "rules.down")] {
            button.target = self
            button.action = action
            button.setAccessibilityIdentifier(id)
        }
        let close = NSButton(title: Text.uiClose.text, target: NSApp,
                             action: #selector(NSApplication.stopModal as (NSApplication) -> () -> Void))
        close.keyEquivalent = "\r"
        close.setAccessibilityIdentifier("rules.close")
        let gap = NSView()
        gap.heightAnchor.constraint(equalToConstant: 8).isActive = true
        let side = NSStackView(views: [new, edit, delete, gap, up, down, NSView(), close])
        side.orientation = .vertical
        side.alignment = .leading
        for button in [new, edit, delete, up, down, close] {
            button.widthAnchor.constraint(equalToConstant: 110).isActive = true
        }
        let intro = wrappingLabel(Text.uiRulesIntro.text)
        let middle = NSStackView(views: [listArea, side])
        middle.alignment = .top
        let help = HelpButton("message-rules")
        let stack = NSStackView(views: [intro, middle, help])
        stack.orientation = .vertical
        stack.alignment = .leading
        stack.edgeInsets = NSEdgeInsets(top: 16, left: 16, bottom: 16, right: 16)
        intro.widthAnchor.constraint(equalTo: stack.widthAnchor, constant: -32).isActive = true
        middle.widthAnchor.constraint(equalTo: stack.widthAnchor, constant: -32).isActive = true
        scroll.heightAnchor.constraint(greaterThanOrEqualToConstant: 200).isActive = true
        side.heightAnchor.constraint(equalTo: scroll.heightAnchor).isActive = true
        window.contentView = stack
        fill()
    }

    /// a row per rule in their order, checked when it is on; `select` stays selected
    private func fill(select: Int = 0) {
        rules = Rule.all(core)
        table.reloadData()
        if !rules.isEmpty {
            table.selectRowIndexes(IndexSet(integer: min(max(select, 0), rules.count - 1)), byExtendingSelection: false)
        }
        empty.isHidden = !rules.isEmpty
        showSelected()
    }

    func numberOfRows(in tableView: NSTableView) -> Int { rules.count }

    func tableView(_ tableView: NSTableView, viewFor column: NSTableColumn?, row: Int) -> NSView? {
        let rule = rules[row]
        switch column?.identifier.rawValue {
        case "on":
            let box = NSButton(checkboxWithTitle: "", target: self, action: #selector(toggled(_:)))
            box.state = rule.enabled ? .on : .off
            box.tag = row
            box.setAccessibilityIdentifier("rules.on.\(row)")
            box.setAccessibilityLabel(rule.name)
            return box
        case "name": return listCell(tableView, rule.name)
        default: return listCell(tableView, rule.query)
        }
    }

    func tableViewSelectionDidChange(_ notification: Notification) {
        showSelected()
    }

    private var selected: Rule? {
        rules.indices.contains(table.selectedRow) ? rules[table.selectedRow] : nil
    }

    private func showSelected() {
        let row = table.selectedRow
        edit.isEnabled = selected != nil
        delete.isEnabled = selected != nil
        up.isEnabled = selected != nil && row > 0
        down.isEnabled = selected != nil && row < rules.count - 1
    }

    /// the check box saves the rule on or off at once
    @objc private func toggled(_ sender: NSButton) {
        guard rules.indices.contains(sender.tag) else { return }
        var rule = rules[sender.tag]
        rule.enabled = sender.state == .on
        let (id, problem) = rule.save(core)
        if id == 0 {
            inform(problem ?? Text.uiUnknownReason.text, title: Text.uiRulesTitle.text, style: .warning)
        }
        fill(select: sender.tag)
    }

    /// the result of the editor: Show closes this window too
    private func edited(_ result: RuleEditorResult, select: Int) {
        switch result {
        case .cancelled: break
        case .saved: fill(select: select)
        case .show(let words):
            show = words
            NSApp.stopModal()
        }
    }

    @objc private func newClicked() {
        let result = RuleEditor.run(core: core, rule: Rule())
        edited(result, select: rules.count)
    }

    @objc private func editClicked() {
        guard let rule = selected else { return }
        edited(RuleEditor.run(core: core, rule: rule), select: table.selectedRow)
    }

    @objc private func deleteClicked() {
        guard let rule = selected,
              ask(Text.uiRuleDeleteAsk.text(["name": rule.name]), title: Text.uiRulesTitle.text,
                  yes: Text.uiRuleDeleteButton.text, no: Text.uiCancel.text, destructive: true) else { return }
        pe_rule_delete(core.handle, rule.id)
        fill(select: table.selectedRow)
    }

    private func move(up: Bool) {
        guard let rule = selected, pe_rule_move(core.handle, rule.id, up) else { return }
        fill(select: table.selectedRow + (up ? -1 : 1))
    }

    @objc private func upClicked() { move(up: true) }
    @objc private func downClicked() { move(up: false) }

    /// the window until Close (or Show in the editor); the words Show asked to search for
    func run() -> String? {
        window.center()
        Modal.opened(window)
        NSApp.runModal(for: window)
        Modal.closed(window)
        window.orderOut(nil)
        return show
    }
}
