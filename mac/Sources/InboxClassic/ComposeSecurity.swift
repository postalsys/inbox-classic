// Signing and encrypting in the compose window: what the core says of it (pe_compose_security) copied into Swift, the
// Keys row of the recipients' chips (each with its lock in the colour of its key, as Apple Mail draws the lock in the
// token) and the Recipients' Keys sheet, which Send opens when someone has no key. The core decides every state,
// colour and word; this file only shows them.
import AppKit
import CInboxClassic

/// A recipient and their key, as the core gave them
struct ComposeRecipientKey: Equatable {
    let address: String
    let label: String
    let key: PeRecipientKey
    /// it can be encrypted to now (verified, found or the user's own key)
    let hasKey: Bool
    let tone: PeProtectionTone
    let text: String
    let pending: String?
    let canFind: Bool

    /// the words of its tooltip: the key, and the new one waiting
    var tip: String { [text, pending].compactMap { $0 }.joined(separator: "\n") }

    /// its picture, telling the states apart without colour: the lock of a key it is encrypted to, the hourglass while
    /// it is looked up, the warning sign without one
    var symbol: String {
        switch key {
        case PE_RECIPIENT_KEY_MISSING, PE_RECIPIENT_KEY_UNUSABLE: "exclamationmark.triangle.fill"
        case PE_RECIPIENT_KEY_LOOKING: "hourglass"
        default: "lock.fill"
        }
    }
}

/// Everything the compose window shows of signing and encrypting, as the core gave it
struct ComposeSecurityState {
    var sign = false
    var signEnabled = true
    var encrypt = false
    var hasOwnKey = false
    /// the line's colour; NONE: no line
    var tone = PE_PROTECTION_TONE_NONE
    var text = ""
    var signTip = ""
    var encryptTip = ""
    var block = PE_COMPOSE_BLOCK_NONE
    var blockText = ""
    var looking = false
    var keysIntro = ""
    var canSendUnencrypted = false
    var unencryptedText = ""
    /// Send in Recipients' Keys can send encrypted
    var canSend = false
    /// Send, else Cancel, is Recipients' Keys' default button
    var sendDefault = false
    /// the Keys row shows
    var showKeys = false
    /// the text is looked at again when it is edited (`edited`): it answers encrypted mail and goes in the clear
    var watchText = false
    var recipients: [ComposeRecipientKey] = []

    init() {}

    /// copied out of `handle`, which is freed
    init?(_ handle: OpaquePointer?) {
        guard let handle else { return nil }
        defer { pe_compose_security_free(handle) }
        guard let info = pe_compose_security_info(handle)?.pointee else { return nil }
        sign = info.sign
        signEnabled = info.sign_enabled
        encrypt = info.encrypt
        hasOwnKey = info.has_own_key
        tone = info.tone
        text = InboxClassicKit.text(info.text)
        signTip = InboxClassicKit.text(info.sign_tip)
        encryptTip = InboxClassicKit.text(info.encrypt_tip)
        block = info.block
        blockText = InboxClassicKit.text(info.block_text)
        looking = info.looking
        keysIntro = InboxClassicKit.text(info.keys_intro)
        canSendUnencrypted = info.can_send_unencrypted
        unencryptedText = InboxClassicKit.text(info.unencrypted_text)
        canSend = info.can_send
        sendDefault = info.send_default
        showKeys = info.show_keys
        watchText = info.watch_text
        recipients = (0..<pe_compose_security_count(handle)).compactMap { pe_compose_security_recipient(handle, $0)?.pointee }
            .map { row in
                ComposeRecipientKey(address: InboxClassicKit.text(row.address), label: InboxClassicKit.text(row.label), key: row.key,
                                    hasKey: row.has_key, tone: row.tone, text: InboxClassicKit.text(row.text),
                                    pending: row.pending.map { String(cString: $0) }, canFind: row.can_find)
            }
    }
}

/// A picture of the system at the size of small text, a template for the colour of its tone
@MainActor
func toneSymbol(_ name: String, size: CGFloat = 10) -> NSImage? {
    let config = NSImage.SymbolConfiguration(pointSize: size, weight: .semibold)
    let image = NSImage(systemSymbolName: name, accessibilityDescription: nil)?.withSymbolConfiguration(config)
    image?.isTemplate = true
    return image
}

// ---- the Keys row ----

/// A recipient on the Keys row: a pill in the tone of their key with its lock (or the warning sign) and their name; a
/// click opens Recipients' Keys
@MainActor
final class KeyChip: NSView {
    let recipient: ComposeRecipientKey?
    private let colors: ToneColors
    private let clicked: () -> Void
    private let picture = NSImageView()
    let label = NSTextField(labelWithString: "")

    /// a recipient's chip, or (`recipient` nil) the one that counts those that did not fit, "+3"
    init(_ recipient: ComposeRecipientKey?, more: String = "", tip: String = "", clicked: @escaping () -> Void) {
        self.recipient = recipient
        let tone = recipient?.tone ?? PE_PROTECTION_TONE_NEUTRAL
        colors = ToneColors.of(tone)
        self.clicked = clicked
        super.init(frame: .zero)
        wantsLayer = true
        layer?.cornerRadius = 10
        layer?.borderWidth = 1
        label.stringValue = recipient?.label ?? more
        label.font = .systemFont(ofSize: NSFont.smallSystemFontSize)
        label.textColor = colors.words
        label.lineBreakMode = .byTruncatingTail
        label.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        label.widthAnchor.constraint(lessThanOrEqualToConstant: 180).isActive = true
        var views: [NSView] = [label]
        if let recipient {
            picture.image = toneSymbol(recipient.symbol)
            picture.contentTintColor = recipient.symbol == "exclamationmark.triangle.fill" ? colors.border : colors.words
            picture.setContentHuggingPriority(.required, for: .horizontal)
            picture.setAccessibilityElement(false)
            views.insert(picture, at: 0)
        }
        let row = NSStackView(views: views)
        row.spacing = 4
        row.edgeInsets = NSEdgeInsets(top: 0, left: recipient == nil ? 8 : 7, bottom: 0, right: 8)
        row.translatesAutoresizingMaskIntoConstraints = false
        addSubview(row)
        NSLayoutConstraint.activate([
            row.leadingAnchor.constraint(equalTo: leadingAnchor), row.trailingAnchor.constraint(equalTo: trailingAnchor),
            row.centerYAnchor.constraint(equalTo: centerYAnchor), heightAnchor.constraint(equalToConstant: 20),
        ])
        toolTip = recipient?.tip ?? tip
        setAccessibilityElement(true)
        setAccessibilityRole(.button)
        setAccessibilityLabel(recipient.map { "\($0.label): \($0.tip)" } ?? "\(more) \(tip)")
        setAccessibilityIdentifier(recipient.map { "compose.key.\($0.address)" } ?? "compose.key.more")
    }

    required init?(coder: NSCoder) { fatalError() }

    override var wantsUpdateLayer: Bool { true }

    override func updateLayer() {
        effectiveAppearance.performAsCurrentDrawingAppearance {
            layer?.backgroundColor = colors.fill.cgColor
            layer?.borderColor = colors.border.withAlphaComponent(0.6).cgColor
        }
    }

    override func viewDidChangeEffectiveAppearance() {
        super.viewDidChangeEffectiveAppearance()
        needsDisplay = true
    }

    override func mouseDown(with event: NSEvent) {
        clicked()
    }

    override func accessibilityPerformPress() -> Bool {
        clicked()
        return true
    }
}

/// The Keys row: a chip for each recipient, on one line; those that do not fit are counted in a last chip ("+3"),
/// so the row never makes the window taller
@MainActor
final class KeyChipsRow: NSView {
    /// a chip or the row clicked
    var clicked: () -> Void = {}
    private(set) var chips: [KeyChip] = []
    private var more: KeyChip?
    private var recipients: [ComposeRecipientKey] = []
    private var laidOut: (width: CGFloat, shown: Int) = (-1, -1)

    override init(frame: NSRect) {
        super.init(frame: frame)
        setAccessibilityElement(true)
        setAccessibilityRole(.group)
        setAccessibilityIdentifier("compose.keys")
    }

    required init?(coder: NSCoder) { fatalError() }

    override var intrinsicContentSize: NSSize { NSSize(width: NSView.noIntrinsicMetric, height: 22) }

    override var isFlipped: Bool { true }

    /// how many chips are shown (the others counted in the last one)
    var shown: Int { chips.filter { !$0.isHidden }.count }

    func show(_ recipients: [ComposeRecipientKey]) {
        guard recipients != self.recipients else { return }
        self.recipients = recipients
        chips.forEach { $0.removeFromSuperview() }
        chips = recipients.map { KeyChip($0) { [weak self] in self?.clicked() } }
        chips.forEach { addSubview($0) }
        laidOut = (-1, -1)
        needsLayout = true
    }

    override func layout() {
        super.layout()
        let width = bounds.width
        let sizes = chips.map(\.fittingSize.width)
        // as many as fit, with room for the count of the rest when some do not
        var count = chips.count
        var used = sizes.reduce(0, +) + CGFloat(max(chips.count - 1, 0)) * 6
        if used > width {
            count = 0
            used = 0
            let room = width - 52
            for size in sizes where used + size <= room {
                used += size + 6
                count += 1
            }
        }
        guard laidOut != (width, count) || chips.contains(where: { $0.frame.width == 0 && !$0.isHidden }) else { return }
        laidOut = (width, count)
        var x: CGFloat = 0
        for (index, chip) in chips.enumerated() {
            chip.isHidden = index >= count
            guard index < count else { continue }
            chip.frame = NSRect(x: x, y: 1, width: min(sizes[index], width), height: 20)
            x += sizes[index] + 6
        }
        more?.removeFromSuperview()
        more = nil
        if count < chips.count {
            let rest = recipients[count...]
            let chip = KeyChip(nil, more: "+\(rest.count)", tip: rest.map { "\($0.label): \($0.text)" }.joined(separator: "\n")) {
                [weak self] in self?.clicked()
            }
            addSubview(chip)
            chip.frame = NSRect(x: x, y: 1, width: chip.fittingSize.width, height: 20)
            more = chip
        }
    }

    override func mouseDown(with event: NSEvent) {
        clicked()
    }
}

// ---- Recipients' Keys ----

/// What the compose window does for Recipients' Keys: the core's state, and its operations on one recipient
@MainActor
protocol RecipientKeysOwner: AnyObject {
    var security: ComposeSecurityState { get }
    func findKey(_ address: String)
    func removeRecipient(_ address: String)
    func decideKey(_ address: String, useNew: Bool)
}

/// The sheet of Recipients' Keys: each recipient with their key, Find Key and Remove from Message for the one
/// selected, Use the New Key or Keep the Current One where a new one waits; Send Without Encryption, Cancel and Send.
/// It reads the core's state again after each action and when keys were found.
@MainActor
final class RecipientKeysSheet: NSObject, NSTableViewDataSource, NSTableViewDelegate {
    enum Answer {
        case cancel, send, sendUnencrypted
    }

    let window: NSWindow
    private weak var owner: RecipientKeysOwner?
    private var answer = Answer.cancel
    private let intro = wrappingLabel("")
    let table = NSTableView()
    let findButton = NSButton(title: Text.uiRecipientFindKey.opens, target: nil, action: nil)
    let removeButton = NSButton(title: Text.uiRecipientRemove.opens, target: nil, action: nil)
    let unencryptedButton = NSButton(title: Text.uiSendUnencrypted.opens, target: nil, action: nil)
    let sendButton = NSButton(title: Text.uiTbSend.text, target: nil, action: nil)
    /// Esc is the window's (`TextDialogWindow`), as Return goes to Cancel or Send as the core says
    let cancelButton = NSButton(title: Text.uiCancel.text, target: nil, action: nil)
    private let unencryptedNote = NSTextField(wrappingLabelWithString: "")
    private(set) var rows: [ComposeRecipientKey] = []

    init(owner: RecipientKeysOwner) {
        self.owner = owner
        window = TextDialogWindow(contentRect: NSRect(x: 0, y: 0, width: 600, height: 380), styleMask: [.titled],
                                  backing: .buffered, defer: true)
        window.autorecalculatesKeyViewLoop = true
        window.title = Text.uiRecipientKeysTitle.text
        window.identifier = NSUserInterfaceItemIdentifier("recipient.keys")
        super.init()
        let heading = NSTextField(labelWithString: window.title)
        heading.font = .boldSystemFont(ofSize: NSFont.systemFontSize)
        intro.setAccessibilityIdentifier("recipient.keys.intro")
        for (id, title, width) in [("recipient", Text.uiRecipientColRecipient.text, 220.0), ("key", Text.uiRecipientColKey.text, 360.0)] {
            let column = NSTableColumn(identifier: NSUserInterfaceItemIdentifier(id))
            column.title = title
            column.width = width
            column.minWidth = 120
            table.addTableColumn(column)
        }
        table.dataSource = self
        table.delegate = self
        table.usesAlternatingRowBackgroundColors = true
        table.style = .fullWidth
        table.setAccessibilityIdentifier("recipient.keys.list")
        let scroll = NSScrollView()
        scroll.documentView = table
        scroll.hasVerticalScroller = true
        scroll.borderType = .bezelBorder
        scroll.heightAnchor.constraint(equalToConstant: 200).isActive = true
        for (button, id, action) in [(findButton, "recipient.keys.find", #selector(findClicked)),
                                     (removeButton, "recipient.keys.remove", #selector(removeClicked)),
                                     (unencryptedButton, "recipient.keys.unencrypted", #selector(unencryptedClicked)),
                                     (sendButton, "recipient.keys.send", #selector(sendClicked))] {
            button.target = self
            button.action = action
            button.bezelStyle = .push
            button.setAccessibilityIdentifier(id)
        }
        let rowButtons = NSStackView(views: [findButton, removeButton])
        rowButtons.spacing = 8
        cancelButton.target = self
        cancelButton.action = #selector(cancelClicked)
        cancelButton.setAccessibilityIdentifier("recipient.keys.cancel")
        unencryptedNote.font = .systemFont(ofSize: NSFont.smallSystemFontSize)
        unencryptedNote.textColor = .secondaryLabelColor
        unencryptedNote.setAccessibilityIdentifier("recipient.keys.note")
        // Send Without Encryption apart from the two that end the sheet, as Mac sheets keep a third choice
        let buttons = buttonRow([unencryptedButton, cancelButton, sendButton], help: "recipient-keys")
        buttons.setCustomSpacing(24, after: unencryptedButton)
        let stack = NSStackView(views: [heading, intro, scroll, rowButtons, unencryptedNote, buttons])
        stack.orientation = .vertical
        stack.alignment = .leading
        stack.spacing = 10
        stack.setCustomSpacing(6, after: heading)
        stack.setCustomSpacing(14, after: intro)
        stack.setCustomSpacing(16, after: unencryptedNote)
        stack.detachesHiddenViews = true
        stack.edgeInsets = NSEdgeInsets(top: 20, left: 20, bottom: 20, right: 20)
        for view in [intro, scroll, buttons, unencryptedNote] {
            view.widthAnchor.constraint(equalTo: stack.widthAnchor, constant: -40).isActive = true
        }
        scroll.widthAnchor.constraint(greaterThanOrEqualToConstant: 600).isActive = true
        window.contentView = stack
        window.initialFirstResponder = table
        refresh()
        table.selectRowIndexes(IndexSet(integer: rows.firstIndex { !$0.hasKey } ?? 0), byExtendingSelection: false)
        selectionChanged()
    }

    /// runs as a sheet of `parent` until a button ends it
    func run(on parent: NSWindow) -> Answer {
        runSheet(window, on: parent)
        return answer
    }

    /// the core's state again: the rows (the same one selected), the intro and what each button can do
    func refresh() {
        guard let state = owner?.security else { return }
        let selected = table.selectedRow >= 0 && table.selectedRow < rows.count ? rows[table.selectedRow].address : nil
        rows = state.recipients
        table.reloadData()
        if let selected, let index = rows.firstIndex(where: { $0.address == selected }) {
            table.selectRowIndexes(IndexSet(integer: index), byExtendingSelection: false)
        }
        intro.stringValue = state.keysIntro
        sendButton.isEnabled = state.canSend
        // Return: Send once it can go, else Cancel
        sendButton.keyEquivalent = state.sendDefault ? "\r" : ""
        cancelButton.keyEquivalent = state.sendDefault ? "" : "\r"
        unencryptedButton.isEnabled = state.canSendUnencrypted
        unencryptedButton.toolTip = state.canSendUnencrypted ? nil : state.unencryptedText
        unencryptedNote.stringValue = state.unencryptedText
        unencryptedNote.isHidden = state.canSendUnencrypted || state.unencryptedText.isEmpty
        selectionChanged()
    }

    private var chosen: ComposeRecipientKey? {
        table.selectedRow >= 0 && table.selectedRow < rows.count ? rows[table.selectedRow] : nil
    }

    private func selectionChanged() {
        findButton.isEnabled = chosen?.canFind == true
        removeButton.isEnabled = chosen != nil
    }

    func tableViewSelectionDidChange(_ notification: Notification) {
        selectionChanged()
    }

    func numberOfRows(in tableView: NSTableView) -> Int { rows.count }

    func tableView(_ tableView: NSTableView, heightOfRow row: Int) -> CGFloat {
        rows[row].pending == nil ? 44 : 98
    }

    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        let recipient = rows[row]
        let cell = NSTableCellView()
        let stack: NSStackView
        if tableColumn?.identifier.rawValue == "recipient" {
            let name = NSTextField(labelWithString: recipient.label)
            name.lineBreakMode = .byTruncatingTail
            var views: [NSView] = [name]
            if recipient.label.lowercased() != recipient.address {
                let address = NSTextField(labelWithString: recipient.address)
                address.font = .systemFont(ofSize: NSFont.smallSystemFontSize)
                address.textColor = .secondaryLabelColor
                address.lineBreakMode = .byTruncatingTail
                views.append(address)
            }
            stack = NSStackView(views: views)
            stack.orientation = .vertical
            stack.alignment = .leading
            stack.spacing = 1
        } else {
            let colors = ToneColors.of(recipient.tone)
            let picture = NSImageView(image: toneSymbol(recipient.symbol, size: 12) ?? NSImage())
            picture.contentTintColor = colors.border
            picture.setContentHuggingPriority(.required, for: .horizontal)
            picture.setAccessibilityElement(false)
            // up to two lines, so a date of a long language is not cut off
            let words = NSTextField(wrappingLabelWithString: recipient.text)
            words.isSelectable = false
            words.maximumNumberOfLines = 2
            words.lineBreakMode = .byWordWrapping
            words.cell?.truncatesLastVisibleLine = true
            words.toolTip = recipient.text
            words.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
            let line = NSStackView(views: [picture, words])
            line.spacing = 6
            line.alignment = .firstBaseline
            var views: [NSView] = [line]
            if let pending = recipient.pending {
                let note = NSTextField(wrappingLabelWithString: pending)
                note.font = .systemFont(ofSize: NSFont.smallSystemFontSize)
                note.textColor = .secondaryLabelColor
                note.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
                let useNew = NSButton(title: Text.uiContactKeyUseNew.opens, target: self, action: #selector(useNewClicked(_:)))
                let keep = NSButton(title: Text.uiContactKeyKeep.opens, target: self, action: #selector(keepClicked(_:)))
                for button in [useNew, keep] {
                    button.controlSize = .small
                    button.font = .systemFont(ofSize: NSFont.smallSystemFontSize)
                    button.tag = row
                }
                useNew.setAccessibilityIdentifier("recipient.keys.use-new")
                keep.setAccessibilityIdentifier("recipient.keys.keep")
                views += [note, NSStackView(views: [useNew, keep])]
            }
            stack = NSStackView(views: views)
            stack.orientation = .vertical
            stack.alignment = .leading
            stack.spacing = 3
            cell.setAccessibilityLabel(recipient.tip)
        }
        stack.translatesAutoresizingMaskIntoConstraints = false
        cell.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: cell.leadingAnchor, constant: 4),
            stack.trailingAnchor.constraint(equalTo: cell.trailingAnchor, constant: -4),
            stack.centerYAnchor.constraint(equalTo: cell.centerYAnchor),
        ])
        return cell
    }

    @objc private func findClicked() {
        guard let chosen else { return }
        owner?.findKey(chosen.address)
    }

    @objc private func removeClicked() {
        guard let chosen else { return }
        owner?.removeRecipient(chosen.address)
    }

    @objc private func useNewClicked(_ sender: NSButton) {
        guard rows.indices.contains(sender.tag) else { return }
        owner?.decideKey(rows[sender.tag].address, useNew: true)
    }

    @objc private func keepClicked(_ sender: NSButton) {
        guard rows.indices.contains(sender.tag) else { return }
        owner?.decideKey(rows[sender.tag].address, useNew: false)
    }

    private func end(_ answer: Answer) {
        self.answer = answer
        NSApp.stopModal()
    }

    @objc private func unencryptedClicked() { end(.sendUnencrypted) }
    @objc private func sendClicked() { end(.send) }
    @objc private func cancelClicked() { end(.cancel) }
}
