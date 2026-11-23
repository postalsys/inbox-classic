// Encryption keys: the Encryption Keys window (Tools) with the user's keys and their contacts', New Key, Back Up Key,
// Import, Export, Key Properties and Verify Key, and the Security window of an account. The core keeps the keys and
// says what they are; these windows show its words and hand it what was chosen or typed, a key file's bytes unread.
import AppKit
import CInboxClassic
import UniformTypeIdentifiers

/// The rounded panel the fingerprint of Verify Key is shown on, in the fill of the light or dark look
private final class FingerprintPanel: NSView {
    override func draw(_ dirtyRect: NSRect) {
        NSColor.quaternarySystemFill.setFill()
        NSBezierPath(roundedRect: bounds, xRadius: 8, yRadius: 8).fill()
    }
}

/// A window of these, centred and run modally until one of its buttons stops it
@MainActor
func runKeyWindow(_ window: NSWindow) {
    window.center()
    Modal.opened(window)
    NSApp.runModal(for: window)
    Modal.closed(window)
    window.orderOut(nil)
}

/// A window of the size its content asks for, `id` for the UI test and the help; Esc closes it as Cancel or Close does
@MainActor
func keyWindow(_ title: String, id: String, resizable: Bool = false) -> NSWindow {
    let window = TextDialogWindow(contentRect: NSRect(x: 0, y: 0, width: 480, height: 200),
                          styleMask: resizable ? [.titled, .resizable] : [.titled], backing: .buffered, defer: true)
    window.autorecalculatesKeyViewLoop = true
    window.title = title
    window.identifier = NSUserInterfaceItemIdentifier(id)
    return window
}

/// The stack a window's parts go in, top to bottom, each `width` wide, 20pt from its edges, as tall as they are
@MainActor
func windowStack(_ views: [NSView], in window: NSWindow, width: CGFloat) -> NSStackView {
    let stack = NSStackView(views: views)
    stack.orientation = .vertical
    stack.alignment = .leading
    stack.spacing = 12
    stack.edgeInsets = NSEdgeInsets(top: 20, left: 20, bottom: 20, right: 20)
    for view in views {
        view.widthAnchor.constraint(equalToConstant: width).isActive = true
    }
    window.contentView = stack
    window.setContentSize(NSSize(width: width + 40, height: stack.fittingSize.height))
    return stack
}

/// A button with the accessibility identifier `id`
@MainActor
func keyButton(_ title: String, _ target: AnyObject, _ action: Selector, _ id: String) -> NSButton {
    let button = NSButton(title: title, target: target, action: action)
    button.setAccessibilityIdentifier(id)
    return button
}

/// A note in the warning look: the triangle beside words that wrap
@MainActor
func warningNote(_ words: String, id: String) -> NSStackView {
    let label = wrappingLabel(words)
    label.textColor = .secondaryLabelColor
    label.setAccessibilityIdentifier(id)
    let sign = NSImageView()
    sign.image = NSImage(systemSymbolName: "exclamationmark.triangle.fill", accessibilityDescription: nil)
    sign.contentTintColor = .systemOrange
    sign.setContentHuggingPriority(.required, for: .horizontal)
    let row = NSStackView(views: [sign, label])
    row.alignment = .top
    row.spacing = 6
    return row
}

// ---- what the windows do with a key ----

@MainActor
enum KeyActions {
    /// New Key for one of `accounts` (all of them when nil), then the backup offered; the new key's fingerprint
    @discardableResult
    static func makeKey(core: Core, accounts: [Account]? = nil) -> String? {
        guard let fingerprint = NewKeyWindow(core: core, accounts: accounts ?? core.accounts()).run() else { return nil }
        if ask(Text.uiKeysBackupOffer.text, title: Text.uiKeysNewTitle.text, yes: Text.uiKeysBackupNow.opens,
               no: Text.uiKeysLater.text, style: .information) {
            backup(core: core, fingerprint: fingerprint)
        }
        return fingerprint
    }

    /// Back Up: a passphrase typed twice, then where to save the key protected by it
    static func backup(core: Core, fingerprint: String) {
        guard let passphrase = PassphraseWindow(title: Text.uiKeysBackupTitle.text, intro: Text.uiKeysBackupIntro.text,
                                                id: "key.backup", twice: true).run() else { return }
        guard let url = saveFilePanel(name: core.pgpFileName(fingerprint, private: true), title: Text.uiKeysBackupTitle.text,
                                      types: armoredTypes) else { return }
        switch core.pgpBackup(fingerprint, passphrase: passphrase) {
        case .success(let armored):
            guard write(armored, to: url, title: Text.uiKeysBackupTitle.text) else { return }
            inform(Text.uiKeysBackupSaved.text, title: Text.uiKeysBackupTitle.text)
        case .failure(let refusal):
            inform(refusal.reason, title: Text.uiKeysBackupTitle.text, style: .warning)
        }
    }

    /// Import: a key file chosen, its passphrase asked while it needs one, then whether to use a private key for the
    /// own addresses it holds; true when something was imported
    static func importFile(core: Core) -> Bool {
        let title = Text.uiKeysImportTitle.text
        // the Mac's open panel has no choice of filters: every file can be chosen, the core says what is no key
        guard let url = openFilesPanel(title: title, multiple: false).first else { return false }
        guard let data = try? Data(contentsOf: url) else {
            inform(Text.uiUnknownReason.text, title: title, style: .warning)
            return false
        }
        return importKeys(core: core, data, source: PE_KEY_SOURCE_FILE, title: title)
    }

    /// Import from Clipboard: the clipboard's text imported as a file's keys are; a clipboard without a key says so
    static func importPasted(core: Core) -> Bool {
        let title = Text.uiKeysImportTitle.text
        let pasted = NSPasteboard.general.string(forType: .string) ?? ""
        guard !pasted.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            inform(Text.uiKeysPasteNone.text, title: title, style: .warning)
            return false
        }
        return importKeys(core: core, Data(pasted.utf8), source: PE_KEY_SOURCE_PASTE, title: title)
    }

    /// the keys of `data` imported, the passphrase of a private key asked while it needs one; the summary, then whether
    /// to use a private key for the own addresses it holds
    private static func importKeys(core: Core, _ data: Data, source: PeKeySource, title: String) -> Bool {
        var (outcome, message) = core.pgpImport(data, passphrase: nil, source: source)
        while outcome == PE_IMPORT_OUTCOME_NEEDS_PASSPHRASE || outcome == PE_IMPORT_OUTCOME_WRONG_PASSPHRASE {
            let problem = outcome == PE_IMPORT_OUTCOME_WRONG_PASSPHRASE ? message : nil
            guard let passphrase = PassphraseWindow(title: title, intro: Text.uiKeysImportPassphrase.text, problem: problem,
                                                    id: "key.import").run() else { return false }
            (outcome, message) = core.pgpImport(data, passphrase: passphrase, source: source)
        }
        guard outcome == PE_IMPORT_OUTCOME_IMPORTED else {
            // text that holds no key, as the clipboard words it
            let none = source == PE_KEY_SOURCE_PASTE && message == Text.pgpErrorNotAKey.text
            inform(none ? Text.uiKeysPasteNone.text : message, title: title, style: .warning)
            return false
        }
        imported(core: core, message, title: title)
        return true
    }

    /// what an import took in, then "Use this key for ...?" when own addresses an own key holds use none yet
    static func imported(core: Core, _ summary: String, title: String) {
        inform(summary, title: title)
        if let question = core.pgpUnclaimedQuestion(),
           ask(question, title: title, yes: Text.uiKeysUse.text, no: Text.uiKeysNotNow.text, style: .information) {
            core.pgpClaimUnclaimed()
        }
    }

    /// the publishes running, each with what its window does once it is done
    private static var publishing: [UInt64: () -> Void] = [:]

    /// Publish: asked first, naming the key's addresses, then uploaded; `done` runs when the server answered (or it
    /// could not start). False when it was not started.
    static func publish(core: Core, key: PgpKey, done: @escaping () -> Void) -> Bool {
        let title = Text.uiKeysPublish.title
        // the command's word as the alert's heading, the question under it, as Mac alerts have them
        let question = title + "\n\n" + Text.uiKeysPublishAsk.text(["addresses": key.addresses.joined(separator: ", ")])
        guard ask(question, title: title,
                  yes: Text.uiKeysPublishNow.text, no: Text.uiCancel.text, style: .information) else { return false }
        let request = core.pgpPublish(key.fingerprint)
        guard request != 0 else {
            inform(Text.uiUnknownReason.text, title: title, style: .warning)
            return false
        }
        publishing[request] = done
        return true
    }

    /// KeyPublished: what the server did, in the core's words; the window that asked shows it is done
    static func published(core: Core, _ request: UInt64) {
        guard let done = publishing.removeValue(forKey: request), let result = core.pgpPublishResult(request) else { return }
        done()
        // after this event, so the message does not hold up the others
        onMain { inform(result.text, title: Text.uiKeysPublish.title, style: result.ok ? .information : .warning) }
    }

    /// Export: where to save the public key
    static func export(core: Core, key: PgpKey) {
        let title = Text.uiKeysExport.title
        guard let armored = core.pgpExport(key.fingerprint),
              let url = saveFilePanel(name: core.pgpFileName(key.fingerprint, private: false), title: title,
                                      types: armoredTypes) else { return }
        write(armored, to: url, title: title)
    }

    /// .asc, the type key files are saved as
    private static var armoredTypes: [UTType] {
        UTType(filenameExtension: "asc").map { [$0] } ?? []
    }

    @discardableResult
    private static func write(_ text: String, to url: URL, title: String) -> Bool {
        do {
            try Data(text.utf8).write(to: url, options: .atomic)
            return true
        } catch {
            inform(Text.macFileNotSaved.text, title: title, style: .warning)
            return false
        }
    }
}

// ---- a passphrase typed ----

/// A small spinner beside a window's buttons while the core works for it, taking its room when still
@MainActor
func busySpinner() -> NSProgressIndicator {
    let spinner = NSProgressIndicator()
    spinner.style = .spinning
    spinner.controlSize = .small
    spinner.isDisplayedWhenStopped = false
    return spinner
}

/// A passphrase typed twice (a key backup's, a setup file's): two hidden fields with their labels, and under them
/// what the core says of what is typed (too short, not the same) while it is typed
@MainActor
final class PassphrasePair: NSObject, NSTextFieldDelegate {
    let fields = [NSSecureTextField(string: ""), NSSecureTextField(string: "")]
    let view: NSStackView
    private let feedback = NSTextField(wrappingLabelWithString: "")
    /// 8 characters or more, the same twice
    private(set) var acceptable = false
    /// what is typed changed
    var changed: (() -> Void)?

    init(id: String, width: CGFloat) {
        let labels = [Text.uiKeysPassphrase.text, Text.uiKeysPassphraseAgain.text]
        let grid = NSGridView(views: zip(labels, fields).map { [formLabel($0.0), $0.1] })
        grid.column(at: 0).xPlacement = .trailing
        grid.column(at: 1).xPlacement = .fill
        grid.rowAlignment = .firstBaseline
        grid.rowSpacing = 8
        grid.columnSpacing = 8
        let font = NSFont.systemFont(ofSize: NSFont.smallSystemFontSize)
        feedback.isSelectable = false
        feedback.textColor = .systemRed
        feedback.font = font
        feedback.setAccessibilityIdentifier("\(id).problem")
        // room for the longest it says, so the window does not grow while one types
        let longest = NSTextField(wrappingLabelWithString: taken(pe_passphrase_feedback_longest()) ?? "")
        longest.font = font
        longest.preferredMaxLayoutWidth = width
        view = NSStackView(views: [grid, feedback])
        view.orientation = .vertical
        view.alignment = .leading
        view.spacing = 8
        grid.widthAnchor.constraint(equalToConstant: width).isActive = true
        feedback.widthAnchor.constraint(equalToConstant: width).isActive = true
        feedback.heightAnchor.constraint(greaterThanOrEqualToConstant: ceil(longest.fittingSize.height)).isActive = true
        super.init()
        for (index, field) in fields.enumerated() {
            field.delegate = self
            field.setAccessibilityIdentifier("\(id).field.\(index)")
            field.setAccessibilityLabel(labels[index])
        }
        update()
    }

    var passphrase: String { fields[0].stringValue }

    var isEnabled: Bool {
        get { fields[0].isEnabled }
        set { fields.forEach { $0.isEnabled = newValue } }
    }

    private func update() {
        var ok = false
        let said = fields[0].stringValue.withCString { first in
            fields[1].stringValue.withCString { again in taken(pe_passphrase_feedback(first, again, &ok)) }
        }
        feedback.stringValue = said ?? ""
        acceptable = ok
    }

    func controlTextDidChange(_ notification: Notification) {
        update()
        changed?()
    }

    /// what was typed taken out of the fields
    func wipe() {
        fields.forEach { $0.stringValue = "" }
        update()
    }
}

/// A small window asking for a passphrase. Twice (`twice`): with the core's words of what is typed, OK once it can be
/// used. Once: `problem` (why the last was refused) over the field, and when `open` is given, OK tries the passphrase
/// with it off the window thread, the window waiting, and stays open saying why when it does not open. The fields are
/// emptied once it is closed.
@MainActor
final class PassphraseWindow: NSObject {
    private let window: NSWindow
    private var field: NSSecureTextField?
    private var pair: PassphrasePair?
    private let problem = NSTextField(wrappingLabelWithString: "")
    private let open: ((String, @escaping @MainActor (String?) -> Void) -> Void)?
    private var ok: NSButton!
    private var cancel: NSButton!
    private let spinner = busySpinner()
    private var typed: String?

    init(title: String, intro: String, problem refused: String? = nil, id: String, help: String = "encryption-keys",
         twice: Bool = false, open: ((String, @escaping @MainActor (String?) -> Void) -> Void)? = nil) {
        self.open = open
        window = keyWindow(title, id: id)
        super.init()
        let width: CGFloat = 380
        var parts: [NSView] = [wrappingLabel(intro)]
        // why the last one was refused (a wrong passphrase), over the field
        problem.isSelectable = false
        problem.textColor = .systemRed
        problem.stringValue = refused ?? ""
        problem.setAccessibilityIdentifier("\(id).problem")
        if twice {
            let pair = PassphrasePair(id: id, width: width)
            pair.changed = { [weak self] in self?.ok.isEnabled = pair.acceptable }
            self.pair = pair
            parts.append(pair.view)
        } else {
            if refused != nil || open != nil {
                parts.append(problem)
            }
            let field = NSSecureTextField(string: "")
            field.setAccessibilityIdentifier("\(id).field.0")
            field.setAccessibilityLabel(intro)
            self.field = field
            parts.append(field)
        }
        cancel = keyButton(Text.uiCancel.text, self, #selector(cancelled), "\(id).cancel")
        cancel.keyEquivalent = "\u{1b}"
        ok = keyButton(Text.uiOk.text, self, #selector(okClicked), "\(id).ok")
        ok.keyEquivalent = "\r"
        ok.isEnabled = pair?.acceptable ?? true
        let buttons = buttonRow([cancel, ok], help: help)
        buttons.insertArrangedSubview(spinner, at: buttons.arrangedSubviews.count - 2)
        parts.append(buttons)
        let stack = windowStack(parts, in: window, width: width)
        stack.setCustomSpacing(20, after: parts[parts.count - 2])
        window.initialFirstResponder = pair?.fields[0] ?? field
    }

    @objc private func okClicked() {
        let passphrase = pair?.passphrase ?? field?.stringValue ?? ""
        guard pair?.acceptable ?? true else { return }
        guard let open else {
            typed = passphrase
            NSApp.stopModal()
            return
        }
        setBusy(true)
        open(passphrase) { [self] refused in
            setBusy(false)
            guard let refused else {
                typed = passphrase
                NSApp.stopModal()
                return
            }
            // typed again
            problem.stringValue = refused
            field?.stringValue = ""
            window.makeFirstResponder(field)
        }
    }

    /// while the passphrase is tried: nothing to type or press, the spinner turning
    private func setBusy(_ busy: Bool) {
        field?.isEnabled = !busy
        ok.isEnabled = !busy
        cancel.isEnabled = !busy
        busy ? spinner.startAnimation(nil) : spinner.stopAnimation(nil)
    }

    @objc private func cancelled() {
        NSApp.stopModal()
    }

    /// what was typed (in the first field), nil when cancelled
    func run() -> String? {
        runKeyWindow(window)
        field?.stringValue = ""
        pair?.wipe()
        return typed
    }
}

// ---- New Key ----

@MainActor
private final class NewKeyWindow: NSObject {
    private let window: NSWindow
    private let core: Core
    private let accounts: [Account]
    private let account = NSPopUpButton(frame: .zero, pullsDown: false)
    private var made: String?

    init(core: Core, accounts: [Account]) {
        self.core = core
        self.accounts = accounts
        window = keyWindow(Text.uiKeysNewTitle.text, id: "key.new")
        super.init()
        // a menu item's title is unique in a popup: the labels go in as items of their own
        for item in accounts {
            account.menu?.addItem(NSMenuItem(title: item.label, action: nil, keyEquivalent: ""))
        }
        account.setAccessibilityIdentifier("key.new.account")
        let cancel = keyButton(Text.uiCancel.text, self, #selector(cancelled), "key.new.cancel")
        cancel.keyEquivalent = "\u{1b}"
        let make = keyButton(Text.uiKeysNewMake.text, self, #selector(makeClicked), "key.new.make")
        make.keyEquivalent = "\r"
        make.isEnabled = !accounts.isEmpty
        var parts: [NSView] = []
        if accounts.isEmpty {
            let none = wrappingLabel(Text.uiKeysNoAccount.text)
            none.setAccessibilityIdentifier("key.new.none")
            parts.append(none)
        } else {
            let label = NSTextField(labelWithString: Text.uiKeysNewFor.text)
            account.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
            let row = NSStackView(views: [label, account])
            row.alignment = .firstBaseline
            row.spacing = 8
            parts.append(row)
        }
        if !core.privateKeysKept {
            parts.append(warningNote(Text.uiKeysMemoryOnly.text, id: "key.new.memory"))
        }
        let buttons = buttonRow([cancel, make], help: "encryption-keys")
        parts.append(buttons)
        let stack = windowStack(parts, in: window, width: 400)
        stack.setCustomSpacing(16, after: parts[0])
        stack.setCustomSpacing(20, after: parts[parts.count - 2])
        window.initialFirstResponder = accounts.isEmpty ? cancel : account
    }

    @objc private func makeClicked() {
        let index = account.indexOfSelectedItem
        guard accounts.indices.contains(index) else { return }
        switch core.pgpGenerate(accounts[index].id) {
        case .success(let fingerprint):
            made = fingerprint
            NSApp.stopModal()
        case .failure(let refusal):
            inform(refusal.reason, title: window.title, style: .warning)
        }
    }

    @objc private func cancelled() {
        NSApp.stopModal()
    }

    /// the fingerprint of the key made, nil when cancelled
    func run() -> String? {
        runKeyWindow(window)
        return made
    }
}

// ---- Key Properties ----

@MainActor
enum KeyPropertiesWindow {
    /// the key's names, fingerprint, state, dates, algorithm, source and addresses; Verify for a contact's key
    static func open(core: Core, fingerprint: String) {
        guard let key = core.pgpKey(fingerprint) else { return }
        KeyPropertiesView(core: core, key: key).run()
    }
}

@MainActor
private final class KeyPropertiesView: NSObject {
    private let window: NSWindow
    private let core: Core
    private var key: PgpKey
    private let status = NSTextField(labelWithString: "")
    private let addresses = NSTextField(labelWithString: "")

    init(core: Core, key: PgpKey) {
        self.core = core
        self.key = key
        window = keyWindow(Text.uiKeyPropertiesTitle.text, id: "key.properties")
        super.init()
        let value = { (words: String, id: String) -> NSTextField in
            let field = NSTextField(wrappingLabelWithString: words)
            field.setAccessibilityIdentifier(id)
            return field
        }
        let fingerprint = value(key.fingerprintLines, "key.properties.fingerprint")
        fingerprint.font = .monospacedSystemFont(ofSize: NSFont.systemFontSize, weight: .regular)
        fingerprint.isSelectable = true
        for (field, id) in [(status, "key.properties.status"), (addresses, "key.properties.addresses")] {
            field.setAccessibilityIdentifier(id)
            field.lineBreakMode = .byWordWrapping
            field.maximumNumberOfLines = 0
            field.isSelectable = true
        }
        let grid = NSGridView(views: [
            [formLabel(Text.uiKeyNames.text), value(key.userIds.joined(separator: "\n"), "key.properties.names")],
            [formLabel(Text.uiKeyFingerprint.text), fingerprint],
            [formLabel(Text.uiKeyStatus.text), status],
            [formLabel(Text.uiKeyCreated.text), value(key.createdText, "key.properties.created")],
            [formLabel(Text.uiKeyExpires.text),
             value(key.expiresText, "key.properties.expires")],
            [formLabel(Text.uiKeyAlgorithm.text), value(key.algorithm, "key.properties.algorithm")],
            [formLabel(Text.uiKeySource.text), value(key.source, "key.properties.source")],
            [formLabel(Text.uiKeyAddresses.text), addresses],
        ])
        grid.column(at: 0).xPlacement = .trailing
        grid.column(at: 1).width = 340
        grid.rowAlignment = .firstBaseline
        grid.rowSpacing = 8
        grid.columnSpacing = 8
        let close = keyButton(Text.uiClose.text, NSApp, #selector(NSApplication.stopModal as (NSApplication) -> () -> Void),
                              "key.properties.close")
        close.keyEquivalent = "\r"
        let buttons = buttonRow([close], help: "encryption-keys")
        // Verify does not close the window: at the left, after the help button
        if key.canVerify {
            let verify = keyButton(Text.uiKeysVerify.opens, self, #selector(verifyClicked), "key.properties.verify")
            buttons.insertArrangedSubview(verify, at: 1)
        }
        let stack = NSStackView(views: [grid, buttons])
        stack.orientation = .vertical
        stack.alignment = .leading
        stack.spacing = 20
        stack.edgeInsets = NSEdgeInsets(top: 20, left: 20, bottom: 20, right: 20)
        buttons.widthAnchor.constraint(equalTo: stack.widthAnchor, constant: -40).isActive = true
        window.contentView = stack
        show()
        window.initialFirstResponder = close
    }

    /// what verifying changes: the status and each address's mark
    private func show() {
        status.stringValue = key.status
        addresses.stringValue = key.addressLines
        window.contentView?.layoutSubtreeIfNeeded()
        window.setContentSize(window.contentView?.fittingSize ?? window.frame.size)
    }

    @objc private func verifyClicked() {
        if VerifyKeyWindow.run(core: core, key: key), let again = core.pgpKey(key.fingerprint) {
            key = again
            show()
        }
    }

    func run() {
        runKeyWindow(window)
    }
}

// ---- Verify Key ----

@MainActor
enum VerifyKeyWindow {
    /// the fingerprint large, to read out with the owner; true when the key was marked or unmarked
    @discardableResult
    static func run(core: Core, key: PgpKey) -> Bool {
        VerifyKeyView(core: core, key: key).run()
    }
}

@MainActor
private final class VerifyKeyView: NSObject {
    private let window: NSWindow
    private let core: Core
    private let key: PgpKey
    private var changed = false

    init(core: Core, key: PgpKey) {
        self.core = core
        self.key = key
        window = keyWindow(Text.uiVerifyTitle.text, id: "key.verify")
        super.init()
        let intro = wrappingLabel(Text.uiVerifyIntro.text(["name": key.name]))
        intro.setAccessibilityIdentifier("key.verify.intro")
        let label = NSTextField(labelWithString: Text.uiVerifyFingerprint.text)
        // two lines of groups, twice the size of the words
        let fingerprint = NSTextField(wrappingLabelWithString: key.fingerprintLines)
        fingerprint.font = .monospacedSystemFont(ofSize: NSFont.systemFontSize * 2, weight: .medium)
        fingerprint.alignment = .center
        fingerprint.isSelectable = true
        fingerprint.setAccessibilityIdentifier("key.verify.fingerprint")
        fingerprint.setAccessibilityLabel(key.grouped)
        let panel = FingerprintPanel()
        fingerprint.translatesAutoresizingMaskIntoConstraints = false
        panel.addSubview(fingerprint)
        NSLayoutConstraint.activate([
            fingerprint.leadingAnchor.constraint(equalTo: panel.leadingAnchor, constant: 16),
            fingerprint.trailingAnchor.constraint(equalTo: panel.trailingAnchor, constant: -16),
            fingerprint.topAnchor.constraint(equalTo: panel.topAnchor, constant: 14),
            fingerprint.bottomAnchor.constraint(equalTo: panel.bottomAnchor, constant: -14),
        ])
        let buttons: NSStackView
        if key.verified {
            let unmark = keyButton(Text.uiVerifyUnmark.text, self, #selector(unmarkClicked), "key.verify.unmark")
            let close = keyButton(Text.uiClose.text, self, #selector(cancelled), "key.verify.close")
            close.keyEquivalent = "\r"
            buttons = buttonRow([close], help: "verify-key")
            buttons.insertArrangedSubview(unmark, at: 1)
        } else {
            // no default button: the user compares and says which, Return answers neither
            let cancel = keyButton(Text.uiCancel.text, self, #selector(cancelled), "key.verify.cancel")
            cancel.keyEquivalent = "\u{1b}"
            let differ = keyButton(Text.uiVerifyDiffer.text, self, #selector(differClicked), "key.verify.differ")
            let match = keyButton(Text.uiVerifyMatch.text, self, #selector(matchClicked), "key.verify.match")
            buttons = buttonRow([cancel, differ, match], help: "verify-key")
        }
        // not verified yet: every address They Match marks, so one that is not theirs is seen
        var views: [NSView] = [intro, label, panel]
        if !key.verified {
            let marks = wrappingLabel(key.verifyMarks)
            marks.setAccessibilityIdentifier("key.verify.marks")
            views.append(marks)
        }
        let stack = windowStack(views + [buttons], in: window, width: 460)
        stack.setCustomSpacing(6, after: label)
        stack.setCustomSpacing(key.verified ? 20 : 10, after: panel)
        if let marks = views.last, !key.verified {
            stack.setCustomSpacing(20, after: marks)
        }
        window.setContentSize(NSSize(width: 500, height: stack.fittingSize.height))
    }

    @objc private func matchClicked() {
        core.pgpSetKeyVerified(key.fingerprint, true)
        changed = true
        NSApp.stopModal()
    }

    /// They Differ: said what to do, nothing marked
    @objc private func differClicked() {
        inform(Text.uiVerifyDiffers.text(["name": key.name]), title: window.title, style: .warning)
        NSApp.stopModal()
    }

    @objc private func unmarkClicked() {
        core.pgpSetKeyVerified(key.fingerprint, false)
        changed = true
        NSApp.stopModal()
    }

    @objc private func cancelled() {
        NSApp.stopModal()
    }

    func run() -> Bool {
        runKeyWindow(window)
        return changed
    }
}

// ---- the Encryption Keys window ----

@MainActor
enum KeysWindow {
    static func open(core: Core) {
        KeysListWindow(core: core).run()
    }
}

/// A table that hands Delete and Return (the keys) to closures
private final class KeysTable: NSTableView {
    var deletePressed: () -> Void = {}
    var returnPressed: () -> Void = {}

    override func keyDown(with event: NSEvent) {
        if event.keyCode == 51 || event.keyCode == 117 {
            deletePressed()
            return
        }
        super.keyDown(with: event)
    }

    /// Return in the list opens the key's Properties, before the window's default button takes it
    override func performKeyEquivalent(with event: NSEvent) -> Bool {
        if window?.firstResponder === self, event.keyCode == 36 || event.keyCode == 76,
           event.modifierFlags.intersection(.deviceIndependentFlagsMask).isEmpty {
            returnPressed()
            return true
        }
        return super.performKeyEquivalent(with: event)
    }
}

@MainActor
private final class KeysListWindow: NSObject, NSTableViewDataSource, NSTableViewDelegate {
    private let window: NSWindow
    private let core: Core
    private let table = KeysTable()
    private let empty = NSTextField(wrappingLabelWithString: Text.uiKeysEmpty.text)
    private let export = NSButton(title: Text.uiKeysExport.opens, target: nil, action: nil)
    private let backup = NSButton(title: Text.uiKeysBackup.opens, target: nil, action: nil)
    private let verify = NSButton(title: Text.uiKeysVerify.opens, target: nil, action: nil)
    private let properties = NSButton(title: Text.macPropertiesButton.text, target: nil, action: nil)
    private let remove = NSButton(title: Text.uiRemove.text, target: nil, action: nil)
    private let publish = NSButton(title: Text.uiKeysPublish.opens, target: nil, action: nil)
    /// turning beside Help while a key is published
    private let spinner = busySpinner()
    /// the key being published: Publish is greyed until the server answered
    private var publishing: String?
    private var keys: [PgpKey] = []

    init(core: Core) {
        self.core = core
        window = keyWindow(Text.uiKeysTitle.text, id: "keys", resizable: true)
        window.setContentSize(NSSize(width: 760, height: 380))
        window.contentMinSize = NSSize(width: 620, height: 320)
        super.init()
        for (id, title, width) in [("name", Text.uiKeysColName.text, 140.0), ("address", Text.uiKeysColAddress.text, 170.0),
                                   ("kind", Text.uiKeysColKind.text, 100.0), ("status", Text.uiKeysColStatus.text, 170.0)] {
            let column = NSTableColumn(identifier: NSUserInterfaceItemIdentifier(id))
            column.title = title
            column.width = width
            column.minWidth = 60
            table.addTableColumn(column)
        }
        table.dataSource = self
        table.delegate = self
        table.usesAlternatingRowBackgroundColors = true
        table.columnAutoresizingStyle = .lastColumnOnlyAutoresizingStyle
        table.target = self
        table.doubleAction = #selector(propertiesClicked)
        table.deletePressed = { [weak self] in self?.removeClicked() }
        table.returnPressed = { [weak self] in self?.propertiesClicked() }
        table.setAccessibilityIdentifier("keys.list")
        let scroll = NSScrollView()
        scroll.documentView = table
        scroll.hasVerticalScroller = true
        scroll.autohidesScrollers = true
        scroll.borderType = .bezelBorder
        // with no keys, what to do in the middle of the list
        empty.isSelectable = false
        empty.alignment = .center
        empty.textColor = .secondaryLabelColor
        empty.translatesAutoresizingMaskIntoConstraints = false
        empty.setAccessibilityIdentifier("keys.none")
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
        let new = keyButton(Text.uiKeysNew.opens, self, #selector(newClicked), "keys.new")
        let importButton = keyButton(Text.uiKeysImport.opens, self, #selector(importClicked), "keys.import")
        let paste = keyButton(Text.uiKeysPaste.text, self, #selector(pasteClicked), "keys.paste")
        for (button, action, id) in [(export, #selector(exportClicked), "keys.export"), (backup, #selector(backupClicked), "keys.backup"),
                                     (publish, #selector(publishClicked), "keys.publish"),
                                     (verify, #selector(verifyClicked), "keys.verify"),
                                     (properties, #selector(propertiesClicked), "keys.properties"),
                                     (remove, #selector(removeClicked), "keys.remove")] {
            button.target = self
            button.action = action
            button.setAccessibilityIdentifier(id)
        }
        let close = keyButton(Text.uiClose.text, NSApp, #selector(NSApplication.stopModal as (NSApplication) -> () -> Void),
                              "keys.close")
        close.keyEquivalent = "\r"
        let gap = NSView()
        gap.heightAnchor.constraint(equalToConstant: 8).isActive = true
        // the buttons as wide as the widest of them, at least 120
        let side = NSStackView(views: [new, importButton, paste, gap, export, backup, publish, verify, properties, remove, NSView(), close])
        side.orientation = .vertical
        side.alignment = .leading
        side.widthAnchor.constraint(greaterThanOrEqualToConstant: 120).isActive = true
        for button in [new, importButton, paste, export, backup, publish, verify, properties, remove, close] {
            button.widthAnchor.constraint(equalTo: side.widthAnchor).isActive = true
        }
        // the list takes the width the buttons leave
        side.setHuggingPriority(.init(700), for: .horizontal)
        let intro = wrappingLabel(Text.uiKeysIntro.text)
        let middle = NSStackView(views: [listArea, side])
        middle.alignment = .top
        let help = NSStackView(views: [HelpButton("encryption-keys"), spinner])
        let stack = NSStackView(views: [intro, middle, help])
        stack.orientation = .vertical
        stack.alignment = .leading
        stack.edgeInsets = NSEdgeInsets(top: 16, left: 16, bottom: 16, right: 16)
        intro.widthAnchor.constraint(equalTo: stack.widthAnchor, constant: -32).isActive = true
        middle.widthAnchor.constraint(equalTo: stack.widthAnchor, constant: -32).isActive = true
        scroll.heightAnchor.constraint(greaterThanOrEqualToConstant: 220).isActive = true
        side.heightAnchor.constraint(equalTo: scroll.heightAnchor).isActive = true
        window.contentView = stack
        window.initialFirstResponder = table
        fill()
    }

    /// a row per key, own keys first; the key `select` stays selected (or the row where it was)
    private func fill(select: String? = nil) {
        let row = table.selectedRow
        keys = core.pgpKeys()
        table.reloadData()
        if !keys.isEmpty {
            let index = select.flatMap { fingerprint in keys.firstIndex { $0.fingerprint == fingerprint } } ?? min(max(row, 0), keys.count - 1)
            table.selectRowIndexes(IndexSet(integer: index), byExtendingSelection: false)
        }
        empty.isHidden = !keys.isEmpty
        showSelected()
    }

    func numberOfRows(in tableView: NSTableView) -> Int { keys.count }

    func tableView(_ tableView: NSTableView, viewFor column: NSTableColumn?, row: Int) -> NSView? {
        let key = keys[row]
        switch column?.identifier.rawValue {
        case "name": return listCell(tableView, key.name)
        case "address": return listCell(tableView, key.addresses.first ?? "")
        case "kind": return listCell(tableView, key.own ? Text.uiKeysKindOwn.text : Text.uiKeysKindContact.text)
        default: return listCell(tableView, key.status)
        }
    }

    func tableViewSelectionDidChange(_ notification: Notification) {
        showSelected()
    }

    private var selected: PgpKey? {
        keys.indices.contains(table.selectedRow) ? keys[table.selectedRow] : nil
    }

    private func showSelected() {
        let key = selected
        export.isEnabled = key != nil
        backup.isEnabled = key?.canBackUp ?? false
        verify.isEnabled = key?.canVerify ?? false
        // a contact's key is theirs to publish
        publish.isEnabled = key?.own == true && publishing == nil
        properties.isEnabled = key != nil
        remove.isEnabled = key != nil
    }

    @objc private func newClicked() {
        if let made = KeyActions.makeKey(core: core) {
            fill(select: made)
        }
    }

    @objc private func importClicked() {
        if KeyActions.importFile(core: core) {
            fill()
        }
    }

    @objc private func pasteClicked() {
        if KeyActions.importPasted(core: core) {
            fill()
        }
    }

    @objc private func publishClicked() {
        guard let key = selected, key.own, publishing == nil else { return }
        let started = KeyActions.publish(core: core, key: key) { [weak self] in
            self?.publishing = nil
            self?.spinner.stopAnimation(nil)
            self?.showSelected()
        }
        guard started else { return }
        publishing = key.fingerprint
        spinner.startAnimation(nil)
        showSelected()
    }

    @objc private func exportClicked() {
        guard let key = selected else { return }
        KeyActions.export(core: core, key: key)
    }

    @objc private func backupClicked() {
        guard let key = selected, backup.isEnabled else { return }
        KeyActions.backup(core: core, fingerprint: key.fingerprint)
    }

    @objc private func verifyClicked() {
        guard let key = selected, key.canVerify else { return }
        if VerifyKeyWindow.run(core: core, key: key) {
            fill(select: key.fingerprint)
        }
    }

    @objc private func propertiesClicked() {
        guard let key = selected else { return }
        KeyPropertiesWindow.open(core: core, fingerprint: key.fingerprint)
        fill(select: key.fingerprint)
    }

    @objc private func removeClicked() {
        guard let key = selected else { return }
        let question = key.removeQuestion
        guard ask(question, title: Text.uiKeysTitle.text, yes: Text.uiRemove.text, no: Text.uiCancel.text,
                  destructive: true) else { return }
        core.pgpRemove(key.fingerprint)
        fill()
    }

    func run() {
        window.center()
        Modal.opened(window)
        NSApp.runModal(for: window)
        Modal.closed(window)
        window.orderOut(nil)
        // the Address Book's key marks follow what was imported, verified or removed here
        AddressBookWindow.refresh()
    }
}

// ---- an account's key (File > Accounts > Security) ----

/// The key of an account's addresses, chosen among the own keys or made, and whether its messages carry it
@MainActor
final class AccountSecurityWindow: NSObject {
    private let window: NSWindow
    private let core: Core
    private let account: Account
    private let key = NSPopUpButton(frame: .zero, pullsDown: false)
    private let autocrypt = NSButton(checkboxWithTitle: Text.uiAccountAutocrypt.text, target: nil, action: nil)
    private var keys: [PgpKey] = []

    static func run(core: Core, account: Account) {
        AccountSecurityWindow(core: core, account: account).run()
    }

    private init(core: Core, account: Account) {
        self.core = core
        self.account = account
        window = keyWindow(Text.uiAccountSecurity.text, id: "account.security")
        super.init()
        let current = core.pgpAccountKey(account.id)
        fillKeys(choose: current.fingerprint)
        autocrypt.state = current.autocrypt ? .on : .off
        key.setAccessibilityIdentifier("account.security.key")
        key.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        autocrypt.setAccessibilityIdentifier("account.security.autocrypt")
        let new = keyButton(Text.uiAccountKeyNew.opens, self, #selector(newClicked), "account.security.new")
        let choice = NSStackView(views: [key, new])
        choice.alignment = .firstBaseline
        let grid = NSGridView(views: [
            [NSTextField(labelWithString: Text.uiAccountKey.text), choice],
            [NSGridCell.emptyContentView, autocrypt],
        ])
        grid.column(at: 0).xPlacement = .trailing
        grid.rowAlignment = .firstBaseline
        grid.rowSpacing = 12
        grid.columnSpacing = 8
        grid.cell(for: autocrypt)?.xPlacement = .leading
        let intro = wrappingLabel(Text.uiAccountSecurityIntro.text)
        // which account, under the intro
        let which = NSTextField(labelWithString: account.label)
        which.textColor = .secondaryLabelColor
        which.lineBreakMode = .byTruncatingMiddle
        let cancel = keyButton(Text.uiCancel.text, self, #selector(cancelled), "account.security.cancel")
        cancel.keyEquivalent = "\u{1b}"
        let ok = keyButton(Text.uiOk.text, self, #selector(okClicked), "account.security.ok")
        ok.keyEquivalent = "\r"
        let buttons = buttonRow([cancel, ok], help: "encryption-keys")
        let stack = NSStackView(views: [which, intro, grid, buttons])
        stack.orientation = .vertical
        stack.alignment = .leading
        stack.spacing = 12
        stack.setCustomSpacing(6, after: which)
        stack.setCustomSpacing(16, after: intro)
        stack.setCustomSpacing(20, after: grid)
        stack.edgeInsets = NSEdgeInsets(top: 20, left: 20, bottom: 20, right: 20)
        for view in [which, intro, buttons] {
            view.widthAnchor.constraint(equalToConstant: 580).isActive = true
        }
        // a long key name is cut short in the choice rather than widening the window
        grid.widthAnchor.constraint(lessThanOrEqualToConstant: 580).isActive = true
        grid.setContentHuggingPriority(.required, for: .horizontal)
        window.contentView = stack
        window.setContentSize(stack.fittingSize)
        window.initialFirstResponder = key
    }

    /// None, then the own keys by name and the end of their fingerprint; `choose` chosen
    private func fillKeys(choose: String?) {
        keys = core.pgpKeys().filter(\.own)
        key.removeAllItems()
        key.addItem(withTitle: Text.uiAccountKeyNone.text)
        for item in keys {
            key.menu?.addItem(NSMenuItem(title: item.choice, action: nil, keyEquivalent: ""))
        }
        key.selectItem(at: choose.flatMap { fingerprint in keys.firstIndex { $0.fingerprint == fingerprint } }.map { $0 + 1 } ?? 0)
    }

    /// New Key: one made for this account and chosen
    @objc private func newClicked() {
        if let made = KeyActions.makeKey(core: core, accounts: [account]) {
            fillKeys(choose: made)
        }
    }

    /// OK: the key chosen made the account's; None takes it away (the core changes nothing when neither it nor
    /// Autocrypt changed, and leaves other addresses with a key of their own alone)
    @objc private func okClicked() {
        let index = key.indexOfSelectedItem - 1
        let fingerprint = keys.indices.contains(index) ? keys[index].fingerprint : ""
        core.pgpSetAccountKey(account.id, fingerprint: fingerprint, autocrypt: autocrypt.state == .on)
        NSApp.stopModal()
    }

    @objc private func cancelled() {
        NSApp.stopModal()
    }

    private func run() {
        runKeyWindow(window)
    }
}

// ---- a contact's keys (Contact Properties) ----

/// The key in use for each of a card's addresses, with Verify, and a newer key waiting for the user's decision; Find
/// Key while an address of a saved card has no key that can encrypt
@MainActor
final class ContactKeys: NSObject {
    let view = NSStackView()
    private let core: Core
    private var addresses: [String] = []
    /// the card as it is stored, 0 for one not saved yet (Find Key looks up the stored card's addresses)
    var card: Int64 = 0
    /// the window's size follows what is shown
    var resized: () -> Void = {}
    /// Find Key's lookup running, 0 for none
    private var lookup: UInt64 = 0
    /// what the last lookup found, under the keys
    private var found = ""

    /// the key sections of the contact windows open
    private static var shown: [ContactKeys] = []

    init(core: Core) {
        self.core = core
        super.init()
        view.orientation = .vertical
        view.alignment = .leading
        view.spacing = 6
        view.setAccessibilityIdentifier("contact.keys")
        Self.shown.append(self)
    }

    /// its window closed: no more events
    func closed() {
        Self.shown.removeAll { $0 === self }
    }

    /// KeysFound: a lookup a contact window started is taken in and its words shown; the keys read again (another
    /// window's lookup may have found a key of this card's addresses too)
    static func keysFound(_ request: UInt64) {
        for keys in shown {
            if request != 0, request == keys.lookup {
                keys.lookup = 0
                keys.found = keys.core.pgpFindResult(request) ?? ""
            }
            keys.show(keys.addresses)
        }
    }

    /// the keys of `addresses`, one entry each that has one
    func show(_ addresses: [String]) {
        self.addresses = addresses
        view.arrangedSubviews.forEach { $0.removeFromSuperview() }
        var any = false
        var missing = false
        for (index, address) in addresses.enumerated() {
            let peer = core.pgpPeer(address)
            let inUse = peer.inUse.flatMap { core.pgpKey($0) }
            if inUse?.state != PE_KEY_STATE_VALID {
                missing = true
            }
            if let key = inUse {
                any = true
                let words = wrappingLabel("\(address): \(key.grouped) (\(key.status))")
                words.isSelectable = true
                words.setAccessibilityIdentifier("contact.key.\(index)")
                let verify = keyButton(Text.uiKeysVerify.opens, self, #selector(verifyClicked(_:)), "contact.key.verify.\(index)")
                verify.tag = index
                verify.controlSize = .small
                verify.font = .systemFont(ofSize: NSFont.smallSystemFontSize)
                view.addArrangedSubview(entry(words, buttons: [verify]))
            }
            if peer.pending != nil {
                any = true
                let words = wrappingLabel(peer.pendingText)
                words.setAccessibilityIdentifier("contact.key.pending.\(index)")
                let useNew = keyButton(Text.uiContactKeyUseNew.text, self, #selector(useNewClicked(_:)), "contact.key.new.\(index)")
                let keep = keyButton(Text.uiContactKeyKeep.text, self, #selector(keepClicked(_:)), "contact.key.keep.\(index)")
                for button in [useNew, keep] {
                    button.tag = index
                    button.controlSize = .small
                    button.font = .systemFont(ofSize: NSFont.smallSystemFontSize)
                }
                view.addArrangedSubview(entry(words, buttons: [useNew, keep]))
            }
        }
        if !any {
            let none = NSTextField(labelWithString: Text.uiContactKeyNone.text)
            none.textColor = .secondaryLabelColor
            none.setAccessibilityIdentifier("contact.key.none")
            view.addArrangedSubview(none)
        }
        // Find Key for a saved card with an address that has no key to encrypt with; its words under it once done
        if card != 0 && (missing || lookup != 0) {
            view.addArrangedSubview(findRow())
        }
        if !found.isEmpty {
            let words = wrappingLabel(found)
            words.textColor = .secondaryLabelColor
            words.setAccessibilityIdentifier("contact.key.found")
            words.preferredMaxLayoutWidth = 400
            words.widthAnchor.constraint(equalToConstant: 400).isActive = true
            view.addArrangedSubview(words)
        }
        resized()
    }

    /// Find Key, greyed with the spinner beside it while it looks
    private func findRow() -> NSView {
        let find = keyButton(Text.uiContactFindKey.text, self, #selector(findClicked), "contact.key.find")
        find.controlSize = .small
        find.font = .systemFont(ofSize: NSFont.smallSystemFontSize)
        find.isEnabled = lookup == 0
        let spinner = busySpinner()
        if lookup != 0 {
            spinner.startAnimation(nil)
        }
        let row = NSStackView(views: [find, spinner])
        row.spacing = 6
        return row
    }

    @objc private func findClicked() {
        guard card != 0, lookup == 0 else { return }
        lookup = core.contactFindKeys(card)
        if lookup == 0 {
            // nothing to ask: every address was looked up a moment ago
            NSSound.beep()
        }
        found = lookup == 0 ? "" : Text.pgpRecipientLooking.text
        show(addresses)
    }

    /// the words of an entry, its buttons under them
    private func entry(_ words: NSTextField, buttons: [NSButton]) -> NSView {
        let row = NSStackView(views: buttons)
        row.spacing = 8
        let stack = NSStackView(views: [words, row])
        stack.orientation = .vertical
        stack.alignment = .leading
        stack.spacing = 4
        words.preferredMaxLayoutWidth = 400
        words.widthAnchor.constraint(equalToConstant: 400).isActive = true
        return stack
    }

    @objc private func verifyClicked(_ sender: NSButton) {
        guard addresses.indices.contains(sender.tag), let inUse = core.pgpPeer(addresses[sender.tag]).inUse,
              let key = core.pgpKey(inUse) else { return }
        if VerifyKeyWindow.run(core: core, key: key) {
            show(addresses)
        }
    }

    @objc private func useNewClicked(_ sender: NSButton) {
        decide(sender.tag, useNew: true)
    }

    @objc private func keepClicked(_ sender: NSButton) {
        decide(sender.tag, useNew: false)
    }

    private func decide(_ index: Int, useNew: Bool) {
        guard addresses.indices.contains(index) else { return }
        core.pgpDecide(addresses[index], useNew: useNew)
        show(addresses)
    }
}
