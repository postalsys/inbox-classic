// Tools > Outbox: the messages that wait to be sent, with why the last try did not work; Send All Now, Delete. What is
// in the Outbox comes from the core as it stores it; this window only lists it.
import AppKit
import CInboxClassic

@MainActor
func outboxDialog(core: Core) {
    OutboxWindow(core: core).run()
}

@MainActor
private final class OutboxWindow: NSObject, NSTableViewDataSource, NSTableViewDelegate {
    private struct Queued {
        let id: Int64
        let subject: String
        let recipients: String
        let created: Int64
        let problem: String?
        /// an AI agent's message waits until then, while it can still be deleted
        let notBefore: Int64
    }

    private let window: NSWindow
    private let core: Core
    private let table = NSTableView()
    private let send = NSButton(title: "Send All Now", target: nil, action: nil)
    private let delete = NSButton(title: "Delete", target: nil, action: nil)
    private var rows: [Queued] = []

    init(core: Core) {
        self.core = core
        window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 680, height: 280), styleMask: [.titled, .resizable],
                          backing: .buffered, defer: true)
        window.title = "Outbox"
        window.identifier = NSUserInterfaceItemIdentifier("outbox")
        super.init()
        for (id, title, width) in [("subject", "Subject", 170.0), ("to", "To", 130.0), ("queued", "Queued", 120.0), ("status", "Status", 120.0)] {
            let column = NSTableColumn(identifier: NSUserInterfaceItemIdentifier(id))
            column.title = title
            column.width = width
            table.addTableColumn(column)
        }
        table.dataSource = self
        table.delegate = self
        table.usesAlternatingRowBackgroundColors = true
        // the last column takes the rest of the width, no wider
        table.columnAutoresizingStyle = .lastColumnOnlyAutoresizingStyle
        table.setAccessibilityIdentifier("outbox.list")
        let scroll = NSScrollView()
        scroll.documentView = table
        scroll.hasVerticalScroller = true
        scroll.borderType = .bezelBorder
        send.target = self
        send.action = #selector(sendAll)
        send.setAccessibilityIdentifier("outbox.send")
        delete.target = self
        delete.action = #selector(deleteSelected)
        let close = NSButton(title: "Close", target: NSApp, action: #selector(NSApplication.stopModal as (NSApplication) -> () -> Void))
        close.keyEquivalent = "\r"
        let side = NSStackView(views: [send, delete, NSView(), close])
        side.orientation = .vertical
        side.alignment = .leading
        for button in [send, delete, close] {
            button.widthAnchor.constraint(equalToConstant: 120).isActive = true
        }
        let stack = NSStackView(views: [scroll, side])
        stack.alignment = .top
        stack.edgeInsets = NSEdgeInsets(top: 16, left: 16, bottom: 16, right: 16)
        scroll.heightAnchor.constraint(equalTo: stack.heightAnchor, constant: -32).isActive = true
        side.heightAnchor.constraint(equalTo: scroll.heightAnchor).isActive = true
        window.contentView = stack
        fill()
    }

    /// a row per message: subject, recipients, when it was queued, and whether it waits or why it did not go
    private func fill(select: Int = 0) {
        rows = []
        if let outbox = pe_outbox(core.handle) {
            defer { pe_outbox_free(outbox) }
            for index in 0..<pe_outbox_count(outbox) {
                guard let queued = pe_outbox_get(outbox, index)?.pointee else { continue }
                rows.append(Queued(id: queued.id, subject: text(queued.subject), recipients: text(queued.recipients),
                                   created: queued.created, problem: queued.problem.map { String(cString: $0) },
                                   notBefore: queued.not_before))
            }
        }
        table.reloadData()
        if !rows.isEmpty {
            table.selectRowIndexes(IndexSet(integer: min(select, rows.count - 1)), byExtendingSelection: false)
        }
        // nothing to send or delete in an empty Outbox
        send.isEnabled = !rows.isEmpty
        delete.isEnabled = !rows.isEmpty
    }

    func numberOfRows(in tableView: NSTableView) -> Int { rows.count }

    func tableView(_ tableView: NSTableView, viewFor column: NSTableColumn?, row: Int) -> NSView? {
        let queued = rows[row]
        let value: String
        switch column?.identifier.rawValue {
        case "subject": value = queued.subject.isEmpty ? "(no subject)" : queued.subject
        case "to": value = queued.recipients
        case "queued": value = formatDate(queued.created)
        default:
            if let problem = queued.problem {
                value = "Not sent: \(problem)"
            } else if queued.notBefore != 0 {
                value = "Sent by an AI agent; goes at \(timeOfDay(queued.notBefore))"
            } else {
                value = "Waiting"
            }
        }
        let label = NSTextField(labelWithString: value)
        label.lineBreakMode = .byTruncatingTail
        return label
    }

    @objc private func sendAll() {
        pe_outbox_send(core.handle)
        NSApp.stopModal()
    }

    @objc private func deleteSelected() {
        let index = table.selectedRow
        guard rows.indices.contains(index),
              ask("Delete this message without sending it?", title: "Outbox", yes: "Delete", no: "Cancel", destructive: true)
        else { return }
        pe_outbox_delete(core.handle, rows[index].id)
        // the next one selected, where the deleted one was
        fill(select: index)
    }

    func run() {
        window.center()
        Modal.opened(window)
        NSApp.runModal(for: window)
        Modal.closed(window)
        window.orderOut(nil)
    }
}
