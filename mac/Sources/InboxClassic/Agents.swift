// AI agents: the questions only the user answers (a program that connects for the first time, every message an
// agent wants to send) and Tools > AI Agents, with the programs let in and what agents did. The rules, the words and
// what the answers do are the core's (pe-core agents.rs); these windows show them and pass the answers on.
import AppKit
import CInboxClassic

/// a question of an AI agent for the user (the AgentAsk event)
@MainActor
func agentQuestion(core: Core, request: UInt64) {
    switch pe_agent_ask_kind(core.handle, request) {
    case PE_AGENT_ASK_KIND_CONNECT:
        guard let info = pe_agent_connect_info(core.handle, request) else { return }
        defer { pe_agent_connect_free(info) }
        guard let connect = pe_agent_connect(info)?.pointee else { return }
        let form = AccessForm(core: core, path: text(connect.path), levels: UInt32(PE_AGENT_DEFAULT)) { _ in true }
        // the safe answer is the default: Return does not let a program in
        let question = QuestionWindow(title: Text.macAiAgent.text, heading: text(connect.title), detail: text(connect.detail),
                                      id: "agent.connect", accessory: form.view,
                                      answers: [(Text.macAllow.text, "agent.allow"), (Text.macDontAllow.text, "agent.deny")],
                                      safe: 1)
        let answer = question.run()
        let (levels, accounts) = form.chosen
        accounts.withUnsafeBufferPointer {
            _ = pe_agent_answer_connect(core.handle, request, answer == 0, levels, $0.baseAddress, accounts.count)
        }
    case PE_AGENT_ASK_KIND_SEND:
        sendQuestion(core: core, request: request)
    default:
        break
    }
}

/// A question of the app's own, as an alert reads (a heading, the words under it, what it is about, the answers on
/// the right, the default one last) but with room for the details, and no system alert around it
@MainActor
private final class QuestionWindow: NSObject {
    let window: NSWindow
    private(set) var buttons: [NSButton] = []
    private var chosen = -1

    /// `answers` from left to right; `safe` is the one Return and Escape give
    init(title: String, heading: String, detail: String, id: String, accessory: NSView, answers: [(String, String)], safe: Int) {
        window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 560, height: 200), styleMask: [.titled], backing: .buffered,
                          defer: true)
        window.title = title
        window.identifier = NSUserInterfaceItemIdentifier(id)
        super.init()
        let icon = NSImageView(image: NSApp.applicationIconImage ?? NSImage())
        icon.widthAnchor.constraint(equalToConstant: 56).isActive = true
        icon.heightAnchor.constraint(equalToConstant: 56).isActive = true
        let headingLabel = wrappingLabel(heading)
        headingLabel.font = NSFont.boldSystemFont(ofSize: NSFont.systemFontSize + 2)
        let detailLabel = wrappingLabel(detail)
        detailLabel.font = NSFont.systemFont(ofSize: NSFont.smallSystemFontSize)
        let text = NSStackView(views: [headingLabel, detailLabel, accessory])
        text.orientation = .vertical
        text.alignment = .leading
        text.spacing = 8
        text.setCustomSpacing(14, after: detailLabel)
        for view in [headingLabel, detailLabel] {
            view.preferredMaxLayoutWidth = 460
            view.widthAnchor.constraint(equalToConstant: 460).isActive = true
        }
        let top = NSStackView(views: [icon, text])
        top.alignment = .top
        top.spacing = 16
        for (index, (label, buttonID)) in answers.enumerated() {
            let button = NSButton(title: label, target: self, action: #selector(answered(_:)))
            button.tag = index
            button.setAccessibilityIdentifier(buttonID)
            if index == safe {
                button.keyEquivalent = "\r"
            }
            buttons.append(button)
        }
        let row = buttonRow(buttons)
        let content = NSStackView(views: [top, row])
        content.orientation = .vertical
        content.spacing = 18
        content.edgeInsets = NSEdgeInsets(top: 20, left: 20, bottom: 18, right: 20)
        row.widthAnchor.constraint(equalTo: content.widthAnchor, constant: -40).isActive = true
        window.contentView = content
        self.safe = safe
    }

    private var safe = 0

    @objc private func answered(_ sender: NSButton) {
        chosen = sender.tag
        NSApp.stopModal()
    }

    /// the answer by position; the safe one when it was closed otherwise
    func run() -> Int {
        window.center()
        Modal.opened(window)
        NSApp.runModal(for: window)
        Modal.closed(window)
        window.orderOut(nil)
        return chosen < 0 ? safe : chosen
    }
}

/// a line of secondary text
private func note(_ string: String, color: NSColor = .secondaryLabelColor) -> NSTextField {
    let label = NSTextField(labelWithString: string)
    label.font = NSFont.systemFont(ofSize: NSFont.smallSystemFontSize)
    label.textColor = color
    label.lineBreakMode = .byTruncatingMiddle
    return label
}

/// what a program may do: the four levels and the accounts, for the first question and for Change
@MainActor
private final class AccessForm: NSObject {
    /// the levels the core offers, with their words
    private static let levels: [(UInt32, String)] = (0..<Int(PE_AGENT_LEVEL_COUNT)).map {
        (pe_agent_level_bit($0), text(pe_agent_level_label($0)))
    }
    let view: NSView
    private var levelBoxes: [NSButton] = []
    private var accountBoxes: [(Int64, NSButton)] = []

    init(core: Core, path: String, levels: UInt32, has: (Int64) -> Bool) {
        let stack = NSStackView()
        stack.orientation = .vertical
        stack.alignment = .leading
        stack.spacing = 6
        view = stack
        super.init()
        let program = note(Text.macProgramPath.text(["path": path]))
        program.toolTip = path
        program.setAccessibilityIdentifier("agent.path")
        stack.addArrangedSubview(program)
        stack.setCustomSpacing(12, after: program)
        stack.addArrangedSubview(bold(Text.macItMay.text))
        for (index, (bit, label)) in Self.levels.enumerated() {
            let box = NSButton(checkboxWithTitle: label, target: self, action: #selector(levelChanged(_:)))
            box.state = levels & bit != 0 ? .on : .off
            box.setAccessibilityIdentifier("agent.level.\(index)")
            levelBoxes.append(box)
            stack.addArrangedSubview(box)
        }
        stack.setCustomSpacing(12, after: levelBoxes.last!)
        stack.addArrangedSubview(bold(Text.macAccountsItMayUse.text))
        for account in core.accounts() {
            let box = NSButton(checkboxWithTitle: account.label, target: nil, action: nil)
            box.state = has(account.id) ? .on : .off
            accountBoxes.append((account.id, box))
            stack.addArrangedSubview(box)
        }
    }

    private func bold(_ string: String) -> NSTextField {
        let label = NSTextField(labelWithString: string)
        label.font = NSFont.boldSystemFont(ofSize: NSFont.systemFontSize)
        return label
    }

    /// reading is what everything else builds on: without it the rest goes too
    @objc private func levelChanged(_ sender: NSButton) {
        if sender === levelBoxes.first, sender.state == .off {
            levelBoxes.forEach { $0.state = .off }
        }
    }

    /// the levels checked (the core keeps none of them without reading) and the accounts ticked
    var chosen: (UInt32, [Int64]) {
        var levels: UInt32 = 0
        for ((bit, _), box) in zip(Self.levels, levelBoxes) where box.state == .on {
            levels |= bit
        }
        return (levels, accountBoxes.filter { $0.1.state == .on }.map(\.0))
    }
}

/// a small red tag beside a recipient the user never wrote to
@MainActor
private func badge(_ string: String) -> NSView {
    let label = NSTextField(labelWithString: string)
    label.font = NSFont.boldSystemFont(ofSize: NSFont.smallSystemFontSize)
    label.textColor = .white
    let holder = NSView()
    holder.wantsLayer = true
    holder.layer?.backgroundColor = NSColor.systemRed.cgColor
    holder.layer?.cornerRadius = 4
    label.translatesAutoresizingMaskIntoConstraints = false
    holder.addSubview(label)
    NSLayoutConstraint.activate([
        label.leadingAnchor.constraint(equalTo: holder.leadingAnchor, constant: 6),
        label.trailingAnchor.constraint(equalTo: holder.trailingAnchor, constant: -6),
        label.topAnchor.constraint(equalTo: holder.topAnchor, constant: 2),
        label.bottomAnchor.constraint(equalTo: holder.bottomAnchor, constant: -2),
    ])
    return holder
}

/// the message an agent wants to send, shown in full before it goes
@MainActor
private func sendQuestion(core: Core, request: UInt64) {
    guard let info = pe_agent_send_info(core.handle, request) else { return }
    defer { pe_agent_send_free(info) }
    guard let send = pe_agent_send(info)?.pointee else { return }
    let stack = NSStackView()
    stack.orientation = .vertical
    stack.alignment = .leading
    stack.spacing = 6
    let warning = text(send.warning)
    if !warning.isEmpty {
        let line = note(warning, color: .systemRed)
        line.font = NSFont.boldSystemFont(ofSize: NSFont.smallSystemFontSize)
        line.setAccessibilityIdentifier("agent.warning")
        stack.addArrangedSubview(line)
    }
    // every recipient on a row of its own, address first, so a name can not hide where it goes
    let grid = NSGridView()
    grid.rowSpacing = 4
    grid.columnSpacing = 8
    func row(_ label: String, _ cells: [NSView]) {
        let name = NSTextField(labelWithString: label)
        name.alignment = .right
        name.textColor = .secondaryLabelColor
        grid.addRow(with: [name] + cells)
    }
    row(Text.macFieldFrom.text, [NSTextField(labelWithString: text(send.from))])
    for index in 0..<pe_agent_send_recipient_count(info) {
        guard let recipient = pe_agent_send_recipient(info, index)?.pointee else { continue }
        let address = NSTextField(labelWithString: text(recipient.address))
        address.font = NSFont.boldSystemFont(ofSize: NSFont.systemFontSize)
        address.setAccessibilityIdentifier("agent.recipient.\(index)")
        var cells: [NSView] = [address]
        let name = text(recipient.name)
        if !name.isEmpty {
            let named = NSTextField(labelWithString: name)
            named.textColor = .secondaryLabelColor
            cells.append(named)
        }
        if recipient.new_address {
            cells.append(badge(Text.macNewAddress.text))
        }
        let line = NSStackView(views: cells)
        line.spacing = 6
        row("\(text(recipient.field)):", [line])
    }
    row(Text.macFieldSubject.text, [NSTextField(labelWithString: text(send.subject))])
    let original = text(send.original)
    if !original.isEmpty {
        row("", [note(original)])
    }
    grid.column(at: 0).xPlacement = .trailing
    stack.addArrangedSubview(grid)
    let scroll = NSTextView.scrollableTextView()
    let body = scroll.documentView as! NSTextView
    body.isEditable = false
    body.string = text(send.text)
    body.font = NSFont.systemFont(ofSize: NSFont.systemFontSize)
    body.setAccessibilityIdentifier("agent.body")
    scroll.borderType = .bezelBorder
    scroll.translatesAutoresizingMaskIntoConstraints = false
    scroll.widthAnchor.constraint(equalToConstant: 460).isActive = true
    scroll.heightAnchor.constraint(equalToConstant: 180).isActive = true
    stack.addArrangedSubview(scroll)
    let files = text(send.files)
    if !files.isEmpty {
        stack.addArrangedSubview(note(files))
    }
    let question = QuestionWindow(title: Text.macSendMessageQuestion.text, heading: text(send.title), detail: text(send.detail),
                                  id: "agent.send", accessory: stack,
                                  answers: [(Text.macEditFirst.text, "agent.compose"), (Text.macDontSend.text, "agent.dontSend"),
                                            (Text.macSend.text, "agent.sendButton")],
                                  safe: 1)
    // Send comes on after a moment, so a key pressed for another window does not send
    let sendButton = question.buttons[2]
    sendButton.isEnabled = false
    // in the common modes: the window runs modally, where a timer of the default mode never fires
    let timer = Timer(timeInterval: 1.5, repeats: false) { _ in
        MainActor.assumeIsolated { sendButton.isEnabled = true }
    }
    RunLoop.main.add(timer, forMode: .common)
    let account = send.account
    let answer: PeAgentSendAnswer
    switch question.run() {
    case 2: answer = PE_AGENT_SEND_ANSWER_SEND
    case 0: answer = PE_AGENT_SEND_ANSWER_COMPOSE
    default: answer = PE_AGENT_SEND_ANSWER_DONT_SEND
    }
    if let draft = Draft(pe_agent_answer_send(core.handle, request, answer)) {
        ComposeWindow.open(core: core, account: account, draft: draft)
    }
}

// ---- Tools > AI Agents ----

@MainActor
final class AgentsWindow: NSObject, NSTableViewDataSource, NSTableViewDelegate {
    private struct Host {
        let id: Int64
        let name: String
        let path: String
        let allowed: Bool
        let levels: UInt32
        let access: String
        let lastUsed: Int64
        let changeTitle: String
        let changeDetail: String
    }

    private struct Entry {
        let id: Int64
        let at: Int64
        let host: String
        let summary: String
        let canUndo: Bool
    }

    private static var open: AgentsWindow?
    let window: NSWindow
    private let core: Core
    private let enabled = NSButton(checkboxWithTitle: Text.macLetAgentsConnect.text, target: nil, action: nil)
    private let hostTable = NSTableView()
    private let logTable = NSTableView()
    private let change = NSButton(title: Text.macChangeButton.text, target: nil, action: nil)
    private let remove = NSButton(title: Text.macRemove.text, target: nil, action: nil)
    private let undo = NSButton(title: Text.macUndoButton.text, target: nil, action: nil)
    private let clear = NSButton(title: Text.macClear.text, target: nil, action: nil)
    private var hosts: [Host] = []
    private var entries: [Entry] = []
    private var accountsOfHost: [Int64: (Int64) -> Bool] = [:]

    static func open(core: Core) {
        let agents = AgentsWindow(core: core)
        open = agents
        agents.run()
        open = nil
    }

    /// what agents did changed: the open window shows it
    static func refresh() {
        open?.fill()
    }

    private init(core: Core) {
        self.core = core
        window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 860, height: 560), styleMask: [.titled, .resizable],
                          backing: .buffered, defer: true)
        window.title = Text.macAiAgents.text
        window.identifier = NSUserInterfaceItemIdentifier("agents")
        super.init()
        enabled.target = self
        enabled.action = #selector(toggleEnabled)
        enabled.setAccessibilityIdentifier("agents.enabled")
        let hostScroll = table(hostTable, id: "agents.hosts",
                               columns: [("name", Text.macColumnProgram.text, 140), ("access", Text.macColumnMay.text, 360),
                                         ("used", Text.macColumnLastUsed.text, 170)])
        let logScroll = table(logTable, id: "agents.log",
                              columns: [("at", Text.macColumnWhen.text, 150), ("host", Text.macColumnProgram.text, 120),
                                        ("what", Text.macColumnWhat.text, 400)])
        hostTable.doubleAction = #selector(changeHost)
        for (button, action, id) in [(change, #selector(changeHost), "agents.change"), (remove, #selector(removeHost), "agents.remove"),
                                     (undo, #selector(undoEntry), "agents.undo"), (clear, #selector(clearLog), "agents.clear")] {
            button.target = self
            button.action = action
            button.setAccessibilityIdentifier(id)
            button.widthAnchor.constraint(equalToConstant: 110).isActive = true
        }
        let setup = NSButton(title: Text.macHowToConnect.text, target: self, action: #selector(showSetup))
        setup.setAccessibilityIdentifier("agents.setup")
        let close = NSButton(title: Text.macClose.text, target: NSApp,
                             action: #selector(NSApplication.stopModal as (NSApplication) -> () -> Void))
        close.keyEquivalent = "\r"
        func side(_ buttons: [NSButton]) -> NSStackView {
            let stack = NSStackView(views: buttons + [NSView()])
            stack.orientation = .vertical
            stack.alignment = .leading
            return stack
        }
        func section(_ title: String, _ scroll: NSScrollView, _ buttons: [NSButton]) -> NSStackView {
            let label = NSTextField(labelWithString: title)
            label.font = NSFont.boldSystemFont(ofSize: NSFont.systemFontSize)
            let row = NSStackView(views: [scroll, side(buttons)])
            row.alignment = .top
            let stack = NSStackView(views: [label, row])
            stack.orientation = .vertical
            stack.alignment = .leading
            row.widthAnchor.constraint(equalTo: stack.widthAnchor).isActive = true
            return stack
        }
        let programs = section(Text.macAgentPrograms.text, hostScroll, [change, remove])
        let log = section(Text.macAgentLog.text, logScroll, [undo, clear])
        hostScroll.heightAnchor.constraint(equalToConstant: 120).isActive = true
        logScroll.heightAnchor.constraint(greaterThanOrEqualToConstant: 180).isActive = true
        let bottom = NSStackView(views: [setup, NSView(), close])
        let content = NSStackView(views: [enabled, programs, log, bottom])
        content.orientation = .vertical
        content.alignment = .leading
        content.spacing = 14
        content.edgeInsets = NSEdgeInsets(top: 18, left: 20, bottom: 18, right: 20)
        for view in [programs, log, bottom] {
            view.widthAnchor.constraint(equalTo: content.widthAnchor, constant: -40).isActive = true
        }
        window.contentView = content
        fill()
    }

    private func table(_ table: NSTableView, id: String, columns: [(String, String, CGFloat)]) -> NSScrollView {
        for (column, title, width) in columns {
            let item = NSTableColumn(identifier: NSUserInterfaceItemIdentifier(column))
            item.title = title
            item.width = width
            table.addTableColumn(item)
        }
        table.dataSource = self
        table.delegate = self
        table.usesAlternatingRowBackgroundColors = true
        table.columnAutoresizingStyle = .lastColumnOnlyAutoresizingStyle
        table.setAccessibilityIdentifier(id)
        let scroll = NSScrollView()
        scroll.documentView = table
        scroll.hasVerticalScroller = true
        scroll.borderType = .bezelBorder
        return scroll
    }

    func fill() {
        let hostRow = max(0, hostTable.selectedRow)
        let logRow = max(0, logTable.selectedRow)
        enabled.state = pe_agents_enabled(core.handle) ? .on : .off
        hosts = []
        accountsOfHost = [:]
        if let list = pe_agent_hosts(core.handle) {
            defer { pe_agent_host_list_free(list) }
            let accountIds = core.accounts().map(\.id)
            for index in 0..<pe_agent_host_list_count(list) {
                guard let host = pe_agent_host_list_get(list, index)?.pointee else { continue }
                hosts.append(Host(id: host.id, name: text(host.name), path: text(host.path), allowed: host.allowed,
                                  levels: host.levels, access: text(host.access), lastUsed: host.last_used,
                                  changeTitle: text(host.change_title), changeDetail: text(host.change_detail)))
                let accounts = accountIds.filter { pe_agent_host_list_has_account(list, index, $0) }
                accountsOfHost[host.id] = { accounts.contains($0) }
            }
        }
        entries = []
        if let log = pe_agent_log(core.handle, 500) {
            defer { pe_agent_log_free(log) }
            for index in 0..<pe_agent_log_count(log) {
                guard let entry = pe_agent_log_get(log, index)?.pointee else { continue }
                entries.append(Entry(id: entry.id, at: entry.at, host: text(entry.host), summary: text(entry.summary),
                                     canUndo: entry.can_undo))
            }
        }
        hostTable.reloadData()
        logTable.reloadData()
        if !hosts.isEmpty {
            hostTable.selectRowIndexes(IndexSet(integer: min(hostRow, hosts.count - 1)), byExtendingSelection: false)
        }
        if !entries.isEmpty {
            logTable.selectRowIndexes(IndexSet(integer: min(logRow, entries.count - 1)), byExtendingSelection: false)
        }
        updateButtons()
    }

    private func updateButtons() {
        change.isEnabled = hosts.indices.contains(hostTable.selectedRow)
        remove.isEnabled = change.isEnabled
        undo.isEnabled = entries.indices.contains(logTable.selectedRow) && entries[logTable.selectedRow].canUndo
        clear.isEnabled = !entries.isEmpty
    }

    func numberOfRows(in tableView: NSTableView) -> Int {
        tableView === hostTable ? hosts.count : entries.count
    }

    func tableView(_ tableView: NSTableView, viewFor column: NSTableColumn?, row: Int) -> NSView? {
        let value: String
        if tableView === hostTable {
            let host = hosts[row]
            switch column?.identifier.rawValue {
            case "name": value = host.name
            case "access": value = host.access
            default: value = host.lastUsed == 0 ? Text.macNever.text : formatDate(host.lastUsed)
            }
        } else {
            let entry = entries[row]
            switch column?.identifier.rawValue {
            case "at": value = formatDate(entry.at)
            case "host": value = entry.host
            default: value = entry.summary
            }
        }
        let label = NSTextField(labelWithString: value)
        label.lineBreakMode = .byTruncatingTail
        label.toolTip = value
        return label
    }

    func tableViewSelectionDidChange(_ notification: Notification) {
        updateButtons()
    }

    @objc private func toggleEnabled() {
        pe_agents_set_enabled(core.handle, enabled.state == .on)
    }

    @objc private func changeHost() {
        guard hosts.indices.contains(hostTable.selectedRow) else { return }
        let host = hosts[hostTable.selectedRow]
        let form = AccessForm(core: core, path: host.path, levels: host.allowed ? host.levels : UInt32(PE_AGENT_DEFAULT),
                              has: accountsOfHost[host.id] ?? { _ in false })
        let question = QuestionWindow(title: Text.macAiAgentAccess.text, heading: host.changeTitle, detail: host.changeDetail,
                                      id: "agent.access", accessory: form.view,
                                      answers: [(Text.macTurnAway.text, "agent.turnAway"), (Text.macCancel.text, "agent.cancel"),
                                                (Text.macAllow.text, "agent.allow")], safe: 2)
        let answer = question.run()
        let (levels, accounts) = form.chosen
        if answer == 2 {
            accounts.withUnsafeBufferPointer {
                _ = pe_agent_host_update(core.handle, host.id, true, levels, $0.baseAddress, accounts.count)
            }
        } else if answer == 0 {
            pe_agent_host_update(core.handle, host.id, false, 0, nil, 0)
        }
        fill()
    }

    @objc private func removeHost() {
        guard hosts.indices.contains(hostTable.selectedRow),
              ask(Text.macForgetProgram.text + "\n\n" + Text.macForgetProgramDetail.text,
                  title: Text.macAiAgents.text, yes: Text.macRemove.text, no: Text.macCancel.text, destructive: true)
        else { return }
        pe_agent_host_remove(core.handle, hosts[hostTable.selectedRow].id)
        fill()
    }

    @objc private func undoEntry() {
        guard entries.indices.contains(logTable.selectedRow) else { return }
        if let why = taken(pe_agent_undo(core.handle, entries[logTable.selectedRow].id)) {
            inform(why, title: Text.macAiAgents.text)
        }
        fill()
    }

    @objc private func clearLog() {
        guard ask(Text.macClearLog.text + "\n\n" + Text.macClearLogDetail.text, title: Text.macAiAgents.text,
                  yes: Text.macClear.text, no: Text.macCancel.text)
        else { return }
        pe_agent_log_clear(core.handle)
        fill()
    }

    @objc private func showSetup() {
        let store = AppDelegate.shared.arguments.store
        let config = (store.map { store in store.withCString { taken(pe_mcp_config($0)) } } ?? taken(pe_mcp_config(nil))) ?? ""
        textDialog(title: Text.macConnectAgent.text,
                   intro: Text.macConnectAgentIntro.text,
                   text: config, id: "agents.setupText", size: NSSize(width: 620, height: 300))
    }

    func run() {
        window.center()
        Modal.opened(window)
        NSApp.runModal(for: window)
        Modal.closed(window)
        window.orderOut(nil)
    }
}
