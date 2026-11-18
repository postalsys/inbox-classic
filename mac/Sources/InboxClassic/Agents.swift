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
        let question = QuestionWindow(title: Text.uiAiAgent.text, heading: text(connect.title), detail: text(connect.detail),
                                      id: "agent.connect", accessory: form.view,
                                      answers: [(Text.uiAllow.text, "agent.allow"), (Text.uiDontAllow.text, "agent.deny")],
                                      safe: 1)
        let answer = question.run()
        let (levels, accounts) = form.chosen
        accounts.withUnsafeBufferPointer {
            _ = pe_agent_answer_connect(core.handle, request, answer == 0, levels, $0.baseAddress, accounts.count)
        }
    case PE_AGENT_ASK_KIND_SEND:
        sendQuestion(core: core, request: request)
    case PE_AGENT_ASK_KIND_UNSUBSCRIBE:
        unsubscribeQuestion(core: core, request: request)
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

    /// `answers` from left to right; `safe` is the one Return and Escape give; the first `apart` stand at the far left,
    /// as a third answer of an alert does
    init(title: String, heading: String, detail: String, id: String, accessory: NSView, answers: [(String, String)], safe: Int,
         apart: Int = 0) {
        window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 560, height: 200), styleMask: [.titled], backing: .buffered,
                          defer: true)
        window.autorecalculatesKeyViewLoop = true
        window.title = title
        window.identifier = NSUserInterfaceItemIdentifier(id)
        super.init()
        let icon = NSImageView(image: NSApp.applicationIconImage ?? NSImage())
        icon.widthAnchor.constraint(equalToConstant: 56).isActive = true
        icon.heightAnchor.constraint(equalToConstant: 56).isActive = true
        let headingLabel = wrappingLabel(heading)
        headingLabel.font = NSFont.boldSystemFont(ofSize: NSFont.systemFontSize + 2)
        headingLabel.setAccessibilityIdentifier("agent.heading")
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
        let row = buttonRow(Array(buttons[apart...]))
        for button in buttons[..<apart].reversed() {
            row.insertArrangedSubview(button, at: 0)
        }
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
        // the safe answer keeps Return after layout, which on some macOS versions takes it from the buttons, and Return,
        // Enter and Esc give it whatever AppKit does with the keys (as `ask` does for its alerts)
        let safeButton = buttons[safe]
        window.contentView?.layoutSubtreeIfNeeded()
        let keepDefault = { [buttons, window] in
            for button in buttons {
                button.keyEquivalent = button === safeButton ? "\r" : ""
            }
            window.defaultButtonCell = safeButton.cell as? NSButtonCell
        }
        keepDefault()
        // a question raised while the app is in the background loses its default button by the time the user comes to
        // it on some macOS versions: it gets it back as the window becomes key
        let becameKey = NotificationCenter.default.addObserver(forName: NSWindow.didBecomeKeyNotification, object: window,
                                                               queue: nil) { _ in
            MainActor.assumeIsolated { keepDefault() }
        }
        defer { NotificationCenter.default.removeObserver(becameKey) }
        let keys = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [window] event in
            let answering: Set<UInt16> = [53, 36, 76]  // Esc, Return, keypad Enter
            guard answering.contains(event.keyCode), event.window === window,
                  event.modifierFlags.intersection(.deviceIndependentFlagsMask).isEmpty else { return event }
            safeButton.performClick(nil)
            return nil
        }
        defer { keys.map(NSEvent.removeMonitor) }
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
    /// the levels the core offers, with their words in the language in use
    private static var levels: [(UInt32, String)] {
        (0..<Int(PE_AGENT_LEVEL_COUNT)).map { (pe_agent_level_bit($0), text(pe_agent_level_label($0))) }
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
        let program = note(Text.uiProgramPath.text(["path": path]))
        program.toolTip = path
        program.setAccessibilityIdentifier("agent.path")
        stack.addArrangedSubview(program)
        stack.setCustomSpacing(12, after: program)
        stack.addArrangedSubview(bold(Text.uiItMay.text))
        for (index, (bit, label)) in Self.levels.enumerated() {
            let box = NSButton(checkboxWithTitle: label, target: self, action: #selector(levelChanged(_:)))
            box.state = levels & bit != 0 ? .on : .off
            box.setAccessibilityIdentifier("agent.level.\(index)")
            levelBoxes.append(box)
            stack.addArrangedSubview(wrapping(box, label))
        }
        stack.setCustomSpacing(12, after: stack.arrangedSubviews.last!)
        stack.addArrangedSubview(bold(Text.uiAccountsItMayUse.text))
        for account in core.accounts() {
            let box = NSButton(checkboxWithTitle: account.label, target: nil, action: nil)
            box.state = has(account.id) ? .on : .off
            accountBoxes.append((account.id, box))
            stack.addArrangedSubview(box)
        }
    }

    /// a level's checkbox with its words wrapped beside it, as the longer ones do not fit the question's width on one
    /// line; clicking the words checks the box, as clicking a checkbox's title does
    private func wrapping(_ box: NSButton, _ label: String) -> NSView {
        box.title = ""
        box.setAccessibilityLabel(label)
        let words = wrappingLabel(label)
        words.preferredMaxLayoutWidth = 436
        words.widthAnchor.constraint(lessThanOrEqualToConstant: 436).isActive = true
        words.addGestureRecognizer(NSClickGestureRecognizer(target: box, action: #selector(NSButton.performClick(_:))))
        let row = NSStackView(views: [box, words])
        row.alignment = .firstBaseline
        row.spacing = 5
        return row
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
    row(Text.uiFieldFrom.text, [NSTextField(labelWithString: text(send.from))])
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
            cells.append(badge(Text.uiNewAddress.text))
        }
        let line = NSStackView(views: cells)
        line.spacing = 6
        row("\(text(recipient.field)):", [line])
    }
    row(Text.uiFieldSubject.text, [NSTextField(labelWithString: text(send.subject))])
    let original = text(send.original)
    if !original.isEmpty {
        row("", [note(original)])
    }
    grid.column(at: 0).xPlacement = .trailing
    stack.addArrangedSubview(grid)
    // an answer to a calendar invitation: what it answers and when, above the text the core wrote
    let invitation = text(send.invitation)
    if !invitation.isEmpty {
        let line = wrappingLabel(invitation)
        line.font = NSFont.systemFont(ofSize: NSFont.smallSystemFontSize)
        line.preferredMaxLayoutWidth = 460
        line.widthAnchor.constraint(equalToConstant: 460).isActive = true
        line.setAccessibilityIdentifier("agent.invitation")
        stack.addArrangedSubview(line)
    }
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
    // Edit First, at the far left, only for a message the user may change: an answer to an invitation is the core's
    var answers: [(String, String, PeAgentSendAnswer)] = [(Text.uiTbSend.text, "agent.sendButton", PE_AGENT_SEND_ANSWER_SEND),
                                                          (Text.uiDontSend.text, "agent.dontSend", PE_AGENT_SEND_ANSWER_DONT_SEND)]
    if send.can_edit {
        answers.insert((Text.uiEditFirst.text, "agent.compose", PE_AGENT_SEND_ANSWER_COMPOSE), at: 0)
    }
    let apart = send.can_edit ? 1 : 0
    let question = QuestionWindow(title: Text.uiSendMessageAsk.text, heading: text(send.title), detail: text(send.detail),
                                  id: "agent.send", accessory: stack, answers: answers.map { ($0.0, $0.1) },
                                  safe: answers.count - 1, apart: apart)
    // Send comes on after a moment, so a key pressed for another window does not send
    holdBack(question.buttons[apart])
    let account = send.account
    let answer = answers[question.run()].2
    if let draft = Draft(pe_agent_answer_send(core.handle, request, answer)) {
        ComposeWindow.open(core: core, account: account, draft: draft)
    }
}

/// An answer that can not be taken back comes on only after a moment, so a click or a key meant for another window
/// does not give it
@MainActor
private func holdBack(_ button: NSButton) {
    button.isEnabled = false
    // in the common modes: the window runs modally, where a timer of the default mode never fires
    let timer = Timer(timeInterval: 1.5, repeats: false) { _ in
        MainActor.assumeIsolated { button.isEnabled = true }
    }
    RunLoop.main.add(timer, forMode: .common)
}

/// The mailing lists an agent wants to leave, one row each: the sender's address first and whole (wrapped, never cut,
/// so a name can not hide who it is), then the name, the subject it came with and where the request goes
@MainActor
private func unsubscribeQuestion(core: Core, request: UInt64) {
    guard let info = pe_agent_unsubscribe_info(core.handle, request) else { return }
    defer { pe_agent_unsubscribe_free(info) }
    guard let ask = pe_agent_unsubscribe(info)?.pointee else { return }
    let width: CGFloat = 460
    let stack = NSStackView()
    stack.orientation = .vertical
    stack.alignment = .leading
    stack.spacing = 0
    let count = pe_agent_unsubscribe_list_count(info)
    for index in 0..<count {
        guard let list = pe_agent_unsubscribe_list(info, index)?.pointee else { continue }
        stack.addArrangedSubview(listRow(list, index: index, width: width))
        if index + 1 < count {
            let line = NSBox()
            line.boxType = .separator
            stack.addArrangedSubview(line)
            line.widthAnchor.constraint(equalTo: stack.widthAnchor, constant: -20).isActive = true
            line.leadingAnchor.constraint(equalTo: stack.leadingAnchor, constant: 10).isActive = true
        }
    }
    // as tall as the lists, up to about as tall as the send question's message, then it scrolls
    let tall = stack.fittingSize.height + 4
    let scroll = scrolledColumn(stack, width: width, height: min(tall, 280))
    scroll.borderType = .bezelBorder
    scroll.autohidesScrollers = true
    scroll.drawsBackground = true
    scroll.backgroundColor = .textBackgroundColor
    scroll.setAccessibilityIdentifier("agent.lists")
    let question = QuestionWindow(title: Text.uiAiAgent.text, heading: text(ask.title), detail: text(ask.detail),
                                  id: "agent.unsubscribe", accessory: scroll,
                                  answers: [(Text.uiUnsubscribe.text, "agent.unsubscribe"),
                                            (Text.uiDontUnsubscribe.text, "agent.dontUnsubscribe")],
                                  safe: 1)
    holdBack(question.buttons[0])
    // a longer list shows its scroller once, so the rows below the edge are not taken for the end
    if tall > 280 {
        let flash = Timer(timeInterval: 0.5, repeats: false) { _ in
            MainActor.assumeIsolated { scroll.flashScrollers() }
        }
        RunLoop.main.add(flash, forMode: .common)
    }
    _ = pe_agent_answer_unsubscribe(core.handle, request, question.run() == 0)
}

/// One list of the unsubscribe question: the sender's address bold and whole, the name under it, the subject it came
/// with and where the request goes
@MainActor
private func listRow(_ list: PeAgentList, index: Int, width: CGFloat) -> NSStackView {
    let address = wrappingLabel(text(list.address))
    address.font = NSFont.boldSystemFont(ofSize: NSFont.systemFontSize)
    address.setAccessibilityIdentifier("agent.list.\(index)")
    let name = text(list.name)
    let named = name.isEmpty ? nil : note(name, color: .labelColor)
    named?.lineBreakMode = .byTruncatingTail
    named?.toolTip = name
    named?.setAccessibilityIdentifier("agent.list.\(index).name")
    let subject = note(text(list.subject))
    subject.lineBreakMode = .byTruncatingTail
    subject.toolTip = subject.stringValue
    let target = note(text(list.target_label), color: .tertiaryLabelColor)
    target.lineBreakMode = .byTruncatingTail
    target.setAccessibilityIdentifier("agent.list.\(index).target")
    let labels = [address, named, subject, target].compactMap { $0 }
    let row = NSStackView(views: labels)
    row.orientation = .vertical
    row.alignment = .leading
    row.spacing = 2
    row.edgeInsets = NSEdgeInsets(top: 7, left: 10, bottom: 7, right: 10)
    for label in labels {
        label.preferredMaxLayoutWidth = width - 36
        label.widthAnchor.constraint(equalToConstant: width - 36).isActive = true
    }
    return row
}

// ---- Tools > AI Agents ----

@MainActor
final class AgentsWindow: NSObject, NSTableViewDataSource, NSTableViewDelegate, NSOutlineViewDataSource,
    NSOutlineViewDelegate {
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

    /// A row of the log: something an agent did, a summary of what a program read in an hour (which opens to each
    /// read, fetched as it opens), or one of those reads
    private final class Entry: NSObject {
        let id: Int64
        let at: Int64
        let host: String
        let summary: String
        let canUndo: Bool
        /// a summary's program and hour, for `pe_agent_reads`
        let reads: (host: Int64, hour: Int64)?
        let isRead: Bool
        private var opened: [Entry]?

        init(_ entry: PeAgentLogEntry) {
            id = entry.id
            at = entry.at
            host = text(entry.host)
            summary = text(entry.summary)
            canUndo = entry.can_undo
            reads = entry.reads ? (entry.host_id, entry.reads_hour) : nil
            isRead = false
        }

        init(read: PeAgentRead) {
            id = 0
            at = read.at
            host = ""
            summary = text(read.text)
            canUndo = false
            reads = nil
            isRead = true
        }

        /// the summary's program and hour, which keeps it open across a refresh
        var key: String? {
            reads.map { "\($0.host):\($0.hour)" }
        }

        /// the reads under a summary, in the order they were made
        func children(_ core: Core) -> [Entry] {
            if let opened { return opened }
            var rows: [Entry] = []
            if let reads, let list = pe_agent_reads(core.handle, reads.host, reads.hour) {
                defer { pe_agent_reads_free(list) }
                for index in 0..<pe_agent_reads_count(list) {
                    if let read = pe_agent_reads_get(list, index)?.pointee {
                        rows.append(Entry(read: read))
                    }
                }
            }
            opened = rows
            return rows
        }
    }

    private static var open: AgentsWindow?
    let window: NSWindow
    private let core: Core
    private let enabled = NSButton(checkboxWithTitle: Text.uiLetAgentsConnect.text, target: nil, action: nil)
    private let hostTable = NSTableView()
    /// what agents did, newest first; a summary of reads opens to them
    private let logTable = NSOutlineView()
    private let change = NSButton(title: Text.uiChangeButton.text, target: nil, action: nil)
    private let remove = NSButton(title: Text.uiRemove.text, target: nil, action: nil)
    private let undoSince = NSButton(title: Text.uiUndoSinceButton.text, target: nil, action: nil)
    private let undo = NSButton(title: Text.uiUndoButton.text, target: nil, action: nil)
    private let clear = NSButton(title: Text.uiClearButton.text, target: nil, action: nil)
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
        window.autorecalculatesKeyViewLoop = true
        window.title = Text.uiAiAgents.text
        window.identifier = NSUserInterfaceItemIdentifier("agents")
        super.init()
        enabled.target = self
        enabled.action = #selector(toggleEnabled)
        enabled.setAccessibilityIdentifier("agents.enabled")
        let hostScroll = table(hostTable, id: "agents.hosts",
                               columns: [("name", Text.uiColProgram.text, 140), ("access", Text.uiColMay.text, 360),
                                         ("used", Text.uiColLastUsed.text, 170)])
        let logScroll = table(logTable, id: "agents.log",
                              columns: [("at", Text.uiColWhen.text, 150), ("host", Text.uiColProgram.text, 120),
                                        ("what", Text.uiColWhat.text, 400)])
        hostTable.doubleAction = #selector(changeHost)
        // the triangle in the first column, as Finder's lists have it; double-clicking a summary opens it too
        logTable.outlineTableColumn = logTable.tableColumns.first
        logTable.autoresizesOutlineColumn = false
        logTable.target = self
        logTable.doubleAction = #selector(toggleReads)
        for (button, action, id) in [(change, #selector(changeHost), "agents.change"), (remove, #selector(removeHost), "agents.remove"),
                                     (undoSince, #selector(undoSinceHost), "agents.undoSince"), (undo, #selector(undoEntry), "agents.undo"), (clear, #selector(clearLog), "agents.clear")] {
            button.target = self
            button.action = action
            button.setAccessibilityIdentifier(id)
            // as wide as the longest word needs, 110 at least
            button.widthAnchor.constraint(greaterThanOrEqualToConstant: 110).isActive = true
        }
        let setup = NSButton(title: Text.uiHowToConnect.text, target: self, action: #selector(showSetup))
        setup.setAccessibilityIdentifier("agents.setup")
        let close = NSButton(title: Text.uiClose.text, target: NSApp,
                             action: #selector(NSApplication.stopModal as (NSApplication) -> () -> Void))
        close.keyEquivalent = "\r"
        func side(_ buttons: [NSButton]) -> NSStackView {
            let stack = NSStackView(views: buttons + [NSView()])
            stack.orientation = .vertical
            // the buttons of a column one width
            stack.alignment = .width
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
        let programs = section(Text.uiAgentPrograms.text, hostScroll, [change, remove, undoSince])
        let log = section(Text.uiWhatAgentsDid.text, logScroll, [undo, clear])
        hostScroll.heightAnchor.constraint(equalToConstant: 120).isActive = true
        logScroll.heightAnchor.constraint(greaterThanOrEqualToConstant: 180).isActive = true
        let bottom = NSStackView(views: [HelpButton("agents"), setup, NSView(), close])
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
        if let outline = table as? NSOutlineView {
            outline.dataSource = self
            outline.delegate = self
        } else {
            table.dataSource = self
            table.delegate = self
        }
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
        // the summaries open now stay open, with what was read since
        let open = Set(entries.filter { logTable.isItemExpanded($0) }.compactMap(\.key))
        entries = []
        if let log = pe_agent_log(core.handle, 500) {
            defer { pe_agent_log_free(log) }
            for index in 0..<pe_agent_log_count(log) {
                if let entry = pe_agent_log_get(log, index)?.pointee {
                    entries.append(Entry(entry))
                }
            }
        }
        hostTable.reloadData()
        logTable.reloadData()
        for entry in entries where entry.key.map(open.contains) == true {
            logTable.expandItem(entry)
        }
        if !hosts.isEmpty {
            hostTable.selectRowIndexes(IndexSet(integer: min(hostRow, hosts.count - 1)), byExtendingSelection: false)
        }
        if logTable.numberOfRows > 0 {
            logTable.selectRowIndexes(IndexSet(integer: min(logRow, logTable.numberOfRows - 1)), byExtendingSelection: false)
        }
        updateButtons()
    }

    private func updateButtons() {
        change.isEnabled = hosts.indices.contains(hostTable.selectedRow)
        remove.isEnabled = change.isEnabled
        undoSince.isEnabled = change.isEnabled
        undo.isEnabled = selectedEntry?.canUndo == true
        clear.isEnabled = !entries.isEmpty
    }

    private var selectedEntry: Entry? {
        logTable.item(atRow: logTable.selectedRow) as? Entry
    }

    func numberOfRows(in tableView: NSTableView) -> Int {
        hosts.count
    }

    func tableView(_ tableView: NSTableView, viewFor column: NSTableColumn?, row: Int) -> NSView? {
        let host = hosts[row]
        let value: String
        switch column?.identifier.rawValue {
        case "name": value = host.name
        case "access": value = host.access
        default: value = host.lastUsed == 0 ? Text.uiNever.text : formatDate(host.lastUsed)
        }
        let cell = listCell(tableView, value)
        cell.toolTip = value
        return cell
    }

    func tableViewSelectionDidChange(_ notification: Notification) {
        updateButtons()
    }

    func outlineView(_ outlineView: NSOutlineView, numberOfChildrenOfItem item: Any?) -> Int {
        (item as? Entry)?.children(core).count ?? entries.count
    }

    func outlineView(_ outlineView: NSOutlineView, child index: Int, ofItem item: Any?) -> Any {
        (item as? Entry)?.children(core)[index] ?? entries[index]
    }

    func outlineView(_ outlineView: NSOutlineView, isItemExpandable item: Any) -> Bool {
        (item as? Entry)?.reads != nil
    }

    func outlineView(_ outlineView: NSOutlineView, viewFor column: NSTableColumn?, item: Any) -> NSView? {
        guard let entry = item as? Entry else { return nil }
        let value: String
        switch column?.identifier.rawValue {
        // a read under its summary: the time, the day and the program being the summary's
        case "at": value = entry.isRead ? timeOfDay(entry.at) : formatDate(entry.at)
        case "host": value = entry.host
        default: value = entry.summary
        }
        let cell = listCell(outlineView, value, secondary: entry.isRead)
        cell.toolTip = value.isEmpty ? nil : value
        return cell
    }

    func outlineViewSelectionDidChange(_ notification: Notification) {
        updateButtons()
    }

    /// a summary of reads opened or closed by a double click, as its triangle does
    @objc private func toggleReads() {
        guard let entry = logTable.item(atRow: logTable.clickedRow) as? Entry, entry.reads != nil else { return }
        if logTable.isItemExpanded(entry) {
            logTable.collapseItem(entry)
        } else {
            logTable.expandItem(entry)
        }
    }

    @objc private func toggleEnabled() {
        pe_agents_set_enabled(core.handle, enabled.state == .on)
    }

    @objc private func changeHost() {
        guard hosts.indices.contains(hostTable.selectedRow) else { return }
        let host = hosts[hostTable.selectedRow]
        let form = AccessForm(core: core, path: host.path, levels: host.allowed ? host.levels : UInt32(PE_AGENT_DEFAULT),
                              has: accountsOfHost[host.id] ?? { _ in false })
        let question = QuestionWindow(title: Text.uiAiAgentAccess.text, heading: host.changeTitle, detail: host.changeDetail,
                                      id: "agent.access", accessory: form.view,
                                      answers: [(Text.uiTurnAway.text, "agent.turnAway"), (Text.uiCancel.text, "agent.cancel"),
                                                (Text.uiAllow.text, "agent.allow")], safe: 2)
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
                  title: Text.uiAiAgents.text, yes: Text.uiRemove.text, no: Text.uiCancel.text, destructive: true)
        else { return }
        pe_agent_host_remove(core.handle, hosts[hostTable.selectedRow].id)
        fill()
    }

    @objc private func undoEntry() {
        guard let entry = selectedEntry, entry.canUndo else { return }
        if let why = taken(pe_agent_undo(core.handle, entry.id)) {
            inform(reportAlert(why), title: Text.uiAiAgents.text)
        }
        fill()
    }

    /// everything the selected program did in a span the user picks, taken back after a question that counts it
    @objc private func undoSinceHost() {
        guard hosts.indices.contains(hostTable.selectedRow) else { return }
        let host = hosts[hostTable.selectedRow]
        guard let since = UndoSinceWindow(core: core, host: host.id).run() else { return }
        if let report = taken(pe_agent_undo_since(core.handle, host.id, since)) {
            inform(reportAlert(report), title: Text.uiAiAgents.text)
        }
        fill()
    }

    /// what taking back did as an alert has it: the first line its heading, what was left under it
    private func reportAlert(_ report: String) -> String {
        guard let end = report.firstIndex(of: "\n") else { return report }
        return report[..<end] + "\n\n" + report[report.index(after: end)...]
    }

    @objc private func clearLog() {
        guard ask(Text.uiClearAgentLog.text + "\n\n" + Text.uiClearAgentLogDetail.text, title: Text.uiAiAgents.text,
                  yes: Text.uiClearButton.text, no: Text.uiCancel.text)
        else { return }
        pe_agent_log_clear(core.handle)
        fill()
    }

    @objc private func showSetup() {
        let store = AppDelegate.shared.arguments.store
        let config = (store.map { store in store.withCString { taken(pe_mcp_config($0)) } } ?? taken(pe_mcp_config(nil))) ?? ""
        textDialog(title: Text.uiConnectAgent.text,
                   intro: Text.uiConnectAgentIntro.text,
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

/// Undo Since: the span to reach back over, and the core's question for it (how many changes, what taking back does);
/// Cancel is the default, Take Back marked destructive, and with nothing to take back only Close is left
@MainActor
private final class UndoSinceWindow: NSObject {
    let window: NSWindow
    private let core: Core
    private let host: Int64
    private let span = NSPopUpButton(frame: .zero, pullsDown: false)
    private let heading = wrappingLabel("")
    private let detail = wrappingLabel("")
    private let takeBack = NSButton(title: Text.uiTakeBack.text, target: nil, action: nil)
    private let cancel = NSButton(title: Text.uiCancel.text, target: nil, action: nil)
    /// the moment the question shown reaches back to, what Take Back takes back since
    private var since: Int64?
    private var accepted = false

    init(core: Core, host: Int64) {
        self.core = core
        self.host = host
        window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 520, height: 200), styleMask: [.titled], backing: .buffered,
                          defer: true)
        window.autorecalculatesKeyViewLoop = true
        window.title = Text.uiAiAgents.text
        window.identifier = NSUserInterfaceItemIdentifier("agents.undoSinceWindow")
        super.init()
        let icon = NSImageView(image: NSApp.applicationIconImage ?? NSImage())
        icon.widthAnchor.constraint(equalToConstant: 56).isActive = true
        icon.heightAnchor.constraint(equalToConstant: 56).isActive = true
        let label = NSTextField(labelWithString: Text.uiUndoSinceSpan.text)
        label.font = NSFont.boldSystemFont(ofSize: NSFont.systemFontSize)
        for index in 0..<Int(PE_AGENT_UNDO_SPAN_COUNT) {
            span.addItem(withTitle: taken(pe_agent_undo_span_label(index)) ?? "")
        }
        span.target = self
        span.action = #selector(spanChanged)
        span.setAccessibilityIdentifier("undoSince.span")
        span.setAccessibilityLabel(Text.uiUndoSinceSpan.text)
        heading.font = NSFont.boldSystemFont(ofSize: NSFont.systemFontSize)
        heading.setAccessibilityIdentifier("undoSince.heading")
        detail.font = NSFont.systemFont(ofSize: NSFont.smallSystemFontSize)
        detail.textColor = .secondaryLabelColor
        detail.setAccessibilityIdentifier("undoSince.detail")
        for view in [heading, detail] {
            view.preferredMaxLayoutWidth = 400
            view.widthAnchor.constraint(equalToConstant: 400).isActive = true
        }
        let text = NSStackView(views: [label, span, heading, detail])
        text.orientation = .vertical
        text.alignment = .leading
        text.spacing = 8
        text.setCustomSpacing(16, after: span)
        let top = NSStackView(views: [icon, text])
        top.alignment = .top
        top.spacing = 16
        takeBack.target = self
        takeBack.action = #selector(accept)
        takeBack.hasDestructiveAction = true
        takeBack.setAccessibilityIdentifier("undoSince.takeBack")
        cancel.target = self
        cancel.action = #selector(close)
        cancel.setAccessibilityIdentifier("undoSince.cancel")
        let row = buttonRow([takeBack, cancel], help: "agents")
        let content = NSStackView(views: [top, row])
        content.orientation = .vertical
        content.spacing = 20
        content.edgeInsets = NSEdgeInsets(top: 20, left: 20, bottom: 18, right: 20)
        row.widthAnchor.constraint(equalTo: content.widthAnchor, constant: -40).isActive = true
        window.contentView = content
        // the shortest span first, the least to take back; the question names the program
        spanChanged()
    }

    /// the question for the span picked, counted from now
    @objc private func spanChanged() {
        since = nil
        var count: UInt64 = 0
        if let info = pe_agent_undo_question(core.handle, host, span.indexOfSelectedItem) {
            defer { pe_agent_undo_question_free(info) }
            if let question = pe_agent_undo_question_get(info)?.pointee {
                heading.stringValue = text(question.title)
                detail.stringValue = text(question.detail)
                count = question.count
                since = question.since
            }
        }
        // nothing to take back: Close alone
        takeBack.isHidden = count == 0
        detail.isHidden = count == 0
        cancel.title = count == 0 ? Text.uiClose.text : Text.uiCancel.text
        keepDefault()
        window.contentView?.layoutSubtreeIfNeeded()
        window.setContentSize(NSSize(width: 520, height: window.contentView?.fittingSize.height ?? 200))
    }

    /// Cancel (or Close) answers Return and Esc, never Take Back
    private func keepDefault() {
        takeBack.keyEquivalent = ""
        cancel.keyEquivalent = "\r"
        window.defaultButtonCell = cancel.cell as? NSButtonCell
    }

    @objc private func accept() {
        accepted = since != nil
        NSApp.stopModal()
    }

    @objc private func close() {
        NSApp.stopModal()
    }

    /// the moment to take back since, nil when cancelled
    func run() -> Int64? {
        window.center()
        let keys = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [cancel, window] event in
            let answering: Set<UInt16> = [53, 36, 76]  // Esc, Return, keypad Enter
            guard answering.contains(event.keyCode), event.window === window,
                  event.modifierFlags.intersection(.deviceIndependentFlagsMask).isEmpty else { return event }
            cancel.performClick(nil)
            return nil
        }
        defer { keys.map(NSEvent.removeMonitor) }
        Modal.opened(window)
        NSApp.runModal(for: window)
        Modal.closed(window)
        window.orderOut(nil)
        return accepted ? since : nil
    }
}
