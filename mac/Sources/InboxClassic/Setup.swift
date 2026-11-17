// Settings and accounts to another computer: File > Export Settings and Accounts writes one file of the parts chosen,
// sealed with a passphrase when one is typed; File > Import Settings and Accounts reads one (its passphrase asked
// first), shows what it holds, and imports the parts and accounts chosen. The core reads, checks and writes the file
// and says everything in words; these windows hand it the choices and the app's own preferences, which they take back
// and apply after an import. What else an import changes the windows hear of through the core's events. Reading a
// sealed file, writing one and importing (which reaches the sign-in apps' issuers) run off the window thread.
import AppKit
import CInboxClassic
import UniformTypeIdentifiers

/// A line of words the core gave: a part with its name and what it holds, what was added or skipped, or a note
struct SetupLine {
    let kind: PeSetupLineKind
    /// the `PE_SETUP_*` flag of a part line, 0 for the others
    let part: UInt32
    let name: String
    let text: String
}

/// An account of a setup file as the import window lists it
struct SetupAccount {
    let index: Int
    /// "Work <ann@example.com>"
    let label: String
    /// its servers and how it signs in, one line
    let servers: String
    /// an import can add it; otherwise `note` says why not
    let importable: Bool
    /// it can not be imported for a reason other than being here already
    let problem: Bool
    let note: String
}

/// The lines of a `PeSetupLines`
private func setupLines(_ lines: OpaquePointer) -> [SetupLine] {
    (0..<pe_setup_lines_count(lines)).compactMap { pe_setup_lines_get(lines, $0)?.pointee }.map {
        SetupLine(kind: $0.kind, part: $0.part, name: text($0.name), text: text($0.text))
    }
}

/// A setup file read: what it holds, read once; the handle is freed with this
final class SetupFile: @unchecked Sendable {
    let handle: OpaquePointer
    let info: PeSetupInfo?
    let accounts: [SetupAccount]
    /// the parts that hold something, with what
    let parts: [SetupLine]
    /// what it holds that can not be used and is left out
    let notes: [String]

    init(_ handle: OpaquePointer) {
        self.handle = handle
        info = pe_setup_file_info(handle)?.pointee
        accounts = (0..<pe_setup_file_account_count(handle)).compactMap { pe_setup_file_account(handle, $0)?.pointee }.map {
            SetupAccount(index: $0.index, label: text($0.label), servers: text($0.servers), importable: $0.importable,
                         problem: $0.problem != nil, note: text($0.note))
        }
        parts = (0..<pe_setup_file_part_count(handle)).compactMap { pe_setup_file_part(handle, $0)?.pointee }.map {
            SetupLine(kind: $0.kind, part: $0.part, name: text($0.name), text: text($0.text))
        }
        if let list = pe_setup_file_notes(handle) {
            notes = (0..<pe_text_list_count(list)).map { text(pe_text_list_get(list, $0)) }
            pe_text_list_free(list)
        } else {
            notes = []
        }
    }

    deinit {
        pe_setup_file_free(handle)
    }

    /// the app preferences it carries, by their shared names, ready to apply; those that count after a restart last
    var prefs: [(name: String, value: String, restart: Bool)] {
        (0..<pe_setup_file_pref_count(handle)).compactMap { pe_setup_file_pref(handle, $0)?.pointee }.map {
            (text($0.name), text($0.value), $0.restart)
        }
    }
}

enum SetupRead {
    case file(SetupFile)
    case needsPassphrase
    case wrongPassphrase(String)
    case invalid(String)
}

/// The core's calls of the setup file, on its handle, which may be used from any thread
enum SetupCalls {
    /// every part with its flag and name, in the order the windows list them
    static var parts: [SetupLine] {
        guard let lines = pe_setup_parts() else { return [] }
        defer { pe_setup_lines_free(lines) }
        return setupLines(lines)
    }

    /// writes the `parts` to `path`, sealed with `passphrase` when there is one, with the app's preferences: what
    /// each part holds, or why not
    static func export(_ core: OpaquePointer, parts: UInt32, passphrase: String?, prefs: [(name: String, value: String)],
                       to path: String) -> Result<[SetupLine], Refusal> {
        guard let export = pe_setup_export_new(parts) else { return .failure(Refusal("")) }
        defer { pe_setup_export_free(export) }
        if let passphrase {
            let strings = CStrings()
            pe_setup_export_set_passphrase(export, strings.add(passphrase))
            strings.wipe()
        }
        for pref in prefs {
            _ = pe_setup_export_set_pref(export, pref.name, pref.value)
        }
        var error: UnsafeMutablePointer<CChar>?
        guard let lines = pe_setup_export_write(core, export, path, &error) else {
            return .failure(Refusal(taken(error) ?? ""))
        }
        defer { pe_setup_lines_free(lines) }
        return .success(setupLines(lines))
    }

    /// the file at `path`, opened with `passphrase` when it is sealed (a passphrase is worked through Argon2: off
    /// the window thread; without one a sealed file is told from its first bytes)
    static func read(_ core: OpaquePointer, _ path: String, passphrase: String?) -> SetupRead {
        var kind = PE_SETUP_ERROR_NONE
        var error: UnsafeMutablePointer<CChar>?
        let strings = CStrings()
        defer { strings.wipe() }
        let file = pe_setup_read(core, path, passphrase.map { strings.add($0) }, &kind, &error)
        let reason = taken(error) ?? ""
        if let file { return .file(SetupFile(file)) }
        switch kind {
        case PE_SETUP_ERROR_NEEDS_PASSPHRASE: return .needsPassphrase
        case PE_SETUP_ERROR_WRONG_PASSPHRASE: return .wrongPassphrase(reason)
        default: return .invalid(reason)
        }
    }

    /// imports `parts` of `file` and the accounts at `accounts` (Accounts follows from them): what was done and the
    /// accounts added, or why not. Blocks while sign-in apps' issuers are read: off the window thread.
    static func importing(_ core: OpaquePointer, _ file: SetupFile, parts: UInt32,
                          accounts: [Int]) -> Result<([SetupLine], [Int64]), Refusal> {
        var error: UnsafeMutablePointer<CChar>?
        let lines = accounts.withUnsafeBufferPointer {
            pe_setup_import(core, file.handle, parts, $0.baseAddress, $0.count, &error)
        }
        guard let lines else { return .failure(Refusal(taken(error) ?? "")) }
        defer { pe_setup_lines_free(lines) }
        var count = 0
        let ids = pe_setup_lines_accounts(lines, &count).map { Array(UnsafeBufferPointer(start: $0, count: count)) } ?? []
        return .success((setupLines(lines), ids))
    }
}

// ---- the app's own preferences, by the names the three apps share ----

@MainActor
private enum SetupPrefs {
    typealias Access = (get: (AppDelegate) -> String, set: (AppDelegate, String) -> Void)

    /// each portable preference of this app: how to read it and how to set it
    private static func bool(_ path: ReferenceWritableKeyPath<AppDelegate, Bool>) -> Access {
        ({ $0[keyPath: path] ? "1" : "0" }, { app, value in app[keyPath: path] = value == "1" })
    }

    private static var all: [String: Access] {
        [
            "notify_new_mail": bool(\.notify),
            "codes_in_notifications": bool(\.codesInNotifications),
            "group_by_conversation": bool(\.groupByConversation),
            "hide_ignored": bool(\.hideIgnored),
            "hide_read": bool(\.hideRead),
            "folder_list": bool(\.folderList),
            "list_pictures": bool(\.listPictures),
            "layout": ({ String($0.layoutMode.rawValue) }, { app, value in
                app.layoutMode = PeLayoutMode(rawValue: UInt32(value) ?? 0)
            }),
            "language": ({ _ in Languages.chosen ?? "" }, { _, value in Languages.chosen = value.isEmpty ? nil : value }),
        ]
    }

    /// the preferences the core carries, as this app has them now
    static var current: [(name: String, value: String)] {
        guard let app = AppDelegate.shared, let names = pe_setup_pref_names() else { return [] }
        defer { pe_setup_pref_names_free(names) }
        return (0..<pe_setup_pref_names_count(names)).compactMap { pe_setup_pref_names_get(names, $0)?.pointee }.compactMap {
            let name = text($0.name)
            return all[name].map { (name, $0.get(app)) }
        }
    }

    /// sets and applies the preferences of a file, as Settings and the View menu do (the core checked them), then
    /// offers to start again when one that counts only then changed
    static func apply(_ prefs: [(name: String, value: String, restart: Bool)]) {
        guard let app = AppDelegate.shared else { return }
        var restart: String??
        for pref in prefs {
            guard let access = all[pref.name], access.get(app) != pref.value else { continue }
            access.set(app, pref.value)
            if pref.restart {
                // the language: empty for the system's
                restart = .some(pref.value.isEmpty ? nil : pref.value)
            }
        }
        if let code = restart {
            Languages.offerRestart(for: code)
        }
    }
}

// ---- what the menu commands do ----

@MainActor
enum SetupFiles {
    /// the type of the files, `.inboxclassic`
    static var fileType: UTType {
        UTType(filenameExtension: String(cString: pe_setup_extension()), conformingTo: .data) ?? .data
    }

    /// File > Export Settings and Accounts
    static func export(core: Core) {
        guard let written = SetupExportWindow(core: core).run() else { return }
        SetupDoneWindow(title: Text.uiSetupExportTitle.text, heading: written.file, lines: written.lines).run()
    }

    /// File > Import Settings and Accounts: a file chosen, its passphrase asked while it needs one, what to import
    /// chosen; the accounts added. The windows that show what it changed hear of it through the core's events.
    @discardableResult
    static func importFile(core: Core) -> [Int64] {
        let title = Text.uiSetupImportTitle.text
        guard let url = openFilesPanel(title: title, types: [fileType], multiple: false).first else { return [] }
        let handle = Handed(value: core.handle)
        // without a passphrase a sealed file is told from its first bytes, and one that is not has no Argon2 to work
        var read = SetupCalls.read(core.handle, url.path, passphrase: nil)
        if case .needsPassphrase = read {
            _ = PassphraseWindow(title: title, intro: Text.uiSetupAskPassphrase.text, id: "setup.passphrase", help: "setup",
                                 open: { passphrase, answer in
                inBackground({ SetupCalls.read(handle.value, url.path, passphrase: passphrase) }) { result in
                    read = result
                    if case .wrongPassphrase(let reason) = result {
                        answer(reason)
                    } else {
                        answer(nil)
                    }
                }
            }).run()
        }
        switch read {
        case .file(let file):
            guard let done = SetupImportWindow(core: core, file: file).run() else { return [] }
            SetupDoneWindow(title: title, heading: nil, lines: done.lines).run()
            if done.preferences {
                SetupPrefs.apply(file.prefs)
            }
            return done.accounts
        case .invalid(let reason):
            inform(reason.isEmpty ? Text.uiUnknownReason.text : reason, title: title, style: .warning)
            return []
        case .needsPassphrase, .wrongPassphrase:
            // cancelled
            return []
        }
    }
}

// ---- the parts of the windows ----

/// Words under or beside a choice, in the secondary look
@MainActor
private func secondaryLabel(_ words: String, small: Bool = false) -> NSTextField {
    // "sign-ins" kept whole, not broken at its hyphen
    let label = wrappingLabel(hyphensKept(words))
    label.textColor = .secondaryLabelColor
    if small {
        label.font = .systemFont(ofSize: NSFont.smallSystemFontSize)
    }
    return label
}

/// A check box with `id`
@MainActor
private func checkBox(_ title: String, _ target: AnyObject, _ action: Selector, id: String) -> NSButton {
    let box = NSButton(checkboxWithTitle: title, target: target, action: action)
    box.setAccessibilityIdentifier(id)
    return box
}

/// How far a check box's title starts from its box
private let checkIndent: CGFloat = 22

/// Views indented under the check box they belong to, as far as its title starts
@MainActor
private func indented(_ views: [NSView], spacing: CGFloat = 4) -> NSStackView {
    let stack = NSStackView(views: views)
    stack.orientation = .vertical
    stack.alignment = .leading
    stack.spacing = spacing
    stack.edgeInsets = NSEdgeInsets(top: 0, left: checkIndent, bottom: 0, right: 0)
    return stack
}

// ---- Export ----

@MainActor
private final class SetupExportWindow: NSObject {
    private let core: Core
    private let window: NSWindow
    private var parts: [(flag: UInt32, box: NSButton)] = []
    private let usePassphrase: NSButton
    private let passphrase: PassphrasePair
    private var cancelButton: NSButton!
    private var exportButton: NSButton!
    private let spinner = busySpinner()
    private var written: (file: String, lines: [SetupLine])?

    init(core: Core) {
        self.core = core
        window = keyWindow(Text.uiSetupExportTitle.text, id: "setup.export")
        usePassphrase = NSButton(checkboxWithTitle: Text.uiSetupUsePassphrase.text, target: nil, action: nil)
        let width: CGFloat = 440
        passphrase = PassphrasePair(id: "setup.passphrase", width: width - checkIndent)
        super.init()
        let partList = NSStackView()
        partList.orientation = .vertical
        partList.alignment = .leading
        partList.spacing = 6
        for part in SetupCalls.parts {
            let box = checkBox(part.name, self, #selector(changed), id: "setup.part.\(part.part)")
            box.state = .on
            parts.append((part.part, box))
            partList.addArrangedSubview(box)
        }
        let line = NSBox()
        line.boxType = .separator
        usePassphrase.target = self
        usePassphrase.action = #selector(passphraseToggled)
        usePassphrase.setAccessibilityIdentifier("setup.passphrase.use")
        let note = secondaryLabel(Text.uiSetupPassphraseNote.text, small: true)
        note.setAccessibilityIdentifier("setup.passphrase.note")
        note.widthAnchor.constraint(equalToConstant: width - checkIndent).isActive = true
        passphrase.isEnabled = false
        passphrase.changed = { [weak self] in self?.update() }
        let typed = indented([note, passphrase.view], spacing: 8)

        cancelButton = keyButton(Text.uiCancel.text, self, #selector(cancelled), "setup.cancel")
        cancelButton.keyEquivalent = "\u{1b}"
        exportButton = keyButton(Text.uiSetupExportButton.opens, self,
                                 #selector(exportClicked), "setup.export.ok")
        exportButton.keyEquivalent = "\r"
        let buttons = buttonRow([cancelButton, exportButton], help: "setup")
        buttons.insertArrangedSubview(spinner, at: buttons.arrangedSubviews.count - 2)
        let views: [NSView] = [wrappingLabel(Text.uiSetupExportIntro.text), partList, line, usePassphrase, typed, buttons]
        let stack = windowStack(views, in: window, width: width)
        stack.setCustomSpacing(16, after: views[0])
        stack.setCustomSpacing(16, after: partList)
        stack.setCustomSpacing(6, after: usePassphrase)
        stack.setCustomSpacing(16, after: typed)
        window.setContentSize(NSSize(width: width + 40, height: stack.fittingSize.height))
        window.initialFirstResponder = parts.first?.box
        update()
    }

    private var chosenParts: UInt32 {
        parts.filter { $0.box.state == .on }.reduce(0) { $0 | $1.flag }
    }

    /// Export once a part is chosen and the passphrase, when there is one, can be used
    private func update() {
        exportButton.isEnabled = chosenParts != 0 && (usePassphrase.state == .off || passphrase.acceptable)
    }

    @objc private func changed() {
        update()
    }

    @objc private func passphraseToggled() {
        let on = usePassphrase.state == .on
        if !on {
            passphrase.wipe()
        }
        passphrase.isEnabled = on
        update()
        if on {
            window.makeFirstResponder(passphrase.fields[0])
        }
    }

    /// while the file is written: nothing to change or press, the spinner turning
    private func setBusy(_ busy: Bool) {
        for control in parts.map(\.box) + [usePassphrase, cancelButton!, exportButton!] {
            control.isEnabled = !busy
        }
        passphrase.isEnabled = !busy && usePassphrase.state == .on
        busy ? spinner.startAnimation(nil) : spinner.stopAnimation(nil)
        if !busy {
            update()
        }
    }

    @objc private func exportClicked() {
        update()
        guard exportButton.isEnabled else { return }
        let title = Text.uiSetupExportTitle.text
        guard let url = saveFilePanel(name: taken(pe_setup_default_name()) ?? "", title: title,
                                      types: [SetupFiles.fileType]) else { return }
        let sealed = usePassphrase.state == .on ? passphrase.passphrase : nil
        let (handle, parts, prefs) = (Handed(value: core.handle), chosenParts, SetupPrefs.current)
        setBusy(true)
        // a sealed file's passphrase is worked through Argon2: off the window thread
        inBackground({ SetupCalls.export(handle.value, parts: parts, passphrase: sealed, prefs: prefs, to: url.path) }) {
            [self] result in
            setBusy(false)
            switch result {
            case .success(let lines):
                written = (url.lastPathComponent, lines)
                NSApp.stopModal()
            case .failure(let refusal):
                inform(refusal.reason.isEmpty ? Text.macFileNotSaved.text : refusal.reason, title: title, style: .warning)
            }
        }
    }

    @objc private func cancelled() {
        NSApp.stopModal()
    }

    /// the file's name and what it holds, nil when cancelled
    func run() -> (file: String, lines: [SetupLine])? {
        runKeyWindow(window)
        passphrase.wipe()
        return written
    }
}

// ---- Import ----

@MainActor
private final class SetupImportWindow: NSObject {
    private let core: Core
    private let file: SetupFile
    private let window: NSWindow
    private var parts: [(flag: UInt32, box: NSButton)] = []
    private var accountsBox: NSButton?
    private var accounts: [(account: SetupAccount, box: NSButton)] = []
    private var cancelButton: NSButton!
    private var importButton: NSButton!
    private let spinner = busySpinner()
    private var done: (lines: [SetupLine], preferences: Bool, accounts: [Int64])?

    init(core: Core, file: SetupFile) {
        self.core = core
        self.file = file
        window = keyWindow(Text.uiSetupImportTitle.text, id: "setup.import")
        super.init()
        let width: CGFloat = 460
        var views: [NSView] = [wrappingLabel(Text.uiSetupImportIntro.text)]
        if let info = file.info {
            let from = secondaryLabel(Text.uiSetupFrom.text(["version": text(info.app_version), "date": text(info.created_text)]),
                                      small: true)
            from.setAccessibilityIdentifier("setup.import.from")
            views.append(from)
        }
        let partList = NSStackView()
        partList.orientation = .vertical
        partList.alignment = .leading
        partList.spacing = 8
        for line in file.parts {
            let box = checkBox(line.name, self, #selector(changed), id: "setup.part.\(line.part)")
            box.state = .on
            // what it holds under its name, as an account's servers are under its address: words of any length wrap
            // in the width of the window, not beside a name as long as German makes it
            let holds = secondaryLabel(line.text, small: true)
            holds.setAccessibilityIdentifier("setup.holds.\(line.part)")
            holds.widthAnchor.constraint(equalToConstant: width - checkIndent).isActive = true
            let row = NSStackView(views: [box, indented([holds])])
            row.orientation = .vertical
            row.alignment = .leading
            row.spacing = 1
            partList.addArrangedSubview(row)
            guard line.part == UInt32(PE_SETUP_ACCOUNTS) else {
                parts.append((line.part, box))
                continue
            }
            // Accounts ticks and unticks every account that can be imported; with none, it is no choice
            accountsBox = box
            box.action = #selector(accountsBoxChanged)
            let some = file.accounts.contains { $0.importable }
            box.state = some ? .on : .off
            box.isEnabled = some
            if !file.accounts.isEmpty {
                let list = accountList(width: width - checkIndent)
                partList.addArrangedSubview(list)
                partList.setCustomSpacing(10, after: list)
            }
        }
        views.append(partList)
        for (index, note) in file.notes.enumerated() {
            views.append(warningNote(note, id: "setup.import.note.\(index)"))
        }
        cancelButton = keyButton(Text.uiCancel.text, self, #selector(cancelled), "setup.cancel")
        cancelButton.keyEquivalent = "\u{1b}"
        importButton = keyButton(Text.uiSetupImportButton.text, self, #selector(importClicked), "setup.import.ok")
        importButton.keyEquivalent = "\r"
        let buttons = buttonRow([cancelButton, importButton], help: "setup")
        buttons.insertArrangedSubview(spinner, at: buttons.arrangedSubviews.count - 2)
        views.append(buttons)
        let stack = windowStack(views, in: window, width: width)
        stack.setCustomSpacing(16, after: partList)
        stack.setCustomSpacing(16, after: views[views.count - 2])
        window.setContentSize(NSSize(width: width + 40, height: stack.fittingSize.height))
        window.initialFirstResponder = parts.first?.box
        update()
    }

    /// a check box for each account under Accounts: its title and address, its servers and how it signs in, and what
    /// the import does with it; ticked and on only when it can be imported. Scrolls when there are many.
    private func accountList(width: CGFloat) -> NSView {
        let list = NSStackView()
        list.orientation = .vertical
        list.alignment = .leading
        list.spacing = 10
        for account in file.accounts {
            let box = checkBox(account.label, self, #selector(accountChanged), id: "setup.account.\(account.index)")
            box.state = account.importable ? .on : .off
            box.isEnabled = account.importable
            let servers = secondaryLabel(account.servers, small: true)
            servers.setAccessibilityIdentifier("setup.account.\(account.index).servers")
            let said = secondaryLabel(account.note, small: true)
            said.setAccessibilityIdentifier("setup.account.\(account.index).note")
            if account.problem {
                said.textColor = .systemRed
            }
            for label in [servers, said] {
                label.widthAnchor.constraint(equalToConstant: width - 2 * checkIndent).isActive = true
            }
            let entry = NSStackView(views: [box, indented([servers, said], spacing: 2)])
            entry.orientation = .vertical
            entry.alignment = .leading
            entry.spacing = 2
            list.addArrangedSubview(entry)
            accounts.append((account, box))
        }
        let holder = indented([list])
        guard file.accounts.count > 4 else { return holder }
        // as tall as four accounts, the rest under them in the scroll
        let four = list.arrangedSubviews.prefix(4).reduce(0) { $0 + $1.fittingSize.height } + 3 * list.spacing
        let scroll = scrolledColumn(holder, width: width, height: ceil(four) + 4)
        return scroll
    }

    /// the parts other than Accounts, which follows from the accounts ticked
    private var chosenParts: UInt32 {
        parts.filter { $0.box.state == .on }.reduce(0) { $0 | $1.flag }
    }

    private var chosenAccounts: [Int] {
        accounts.filter { $0.box.state == .on }.map(\.account.index)
    }

    /// Import while something would be imported
    private func update() {
        importButton.isEnabled = chosenParts != 0 || !chosenAccounts.isEmpty
    }

    @objc private func changed() {
        update()
    }

    @objc private func accountsBoxChanged(_ sender: NSButton) {
        for entry in accounts where entry.account.importable {
            entry.box.state = sender.state
        }
        update()
    }

    /// Accounts is ticked while one of its accounts is
    @objc private func accountChanged() {
        accountsBox?.state = chosenAccounts.isEmpty ? .off : .on
        update()
    }

    /// while the import runs: nothing to change or press, the spinner turning
    private func setBusy(_ busy: Bool) {
        for control in parts.map(\.box) + [cancelButton!, importButton!] {
            control.isEnabled = !busy
        }
        accountsBox?.isEnabled = !busy && accounts.contains { $0.account.importable }
        for entry in accounts {
            entry.box.isEnabled = !busy && entry.account.importable
        }
        busy ? spinner.startAnimation(nil) : spinner.stopAnimation(nil)
        if !busy {
            update()
        }
    }

    @objc private func importClicked() {
        let (handle, file, parts, accounts) = (Handed(value: core.handle), file, chosenParts, chosenAccounts)
        setBusy(true)
        // the sign-in apps' issuers are read: off the window thread
        inBackground({ SetupCalls.importing(handle.value, file, parts: parts, accounts: accounts) }) { [self] result in
            setBusy(false)
            switch result {
            case .success(let (lines, added)):
                done = (lines, parts & UInt32(PE_SETUP_PREFERENCES) != 0, added)
                NSApp.stopModal()
            case .failure(let refusal):
                inform(refusal.reason.isEmpty ? Text.uiUnknownReason.text : refusal.reason, title: window.title,
                       style: .warning)
            }
        }
    }

    @objc private func cancelled() {
        NSApp.stopModal()
    }

    /// what was done, whether the preferences were imported, and the accounts added; nil when cancelled
    func run() -> (lines: [SetupLine], preferences: Bool, accounts: [Int64])? {
        runKeyWindow(window)
        return done
    }
}

/// The document view of a scroll, laid out from its top
// ---- what was done ----

/// The lines of what an export wrote or an import did, each with its sign, and Done
@MainActor
private final class SetupDoneWindow: NSObject {
    private let window: NSWindow

    init(title: String, heading: String?, lines: [SetupLine]) {
        window = keyWindow(title, id: "setup.done")
        super.init()
        let width: CGFloat = 420
        var views: [NSView] = []
        if let heading {
            let file = NSTextField(labelWithString: heading)
            file.font = .boldSystemFont(ofSize: NSFont.systemFontSize)
            file.lineBreakMode = .byTruncatingMiddle
            file.setAccessibilityIdentifier("setup.done.file")
            views.append(file)
        }
        let list = NSStackView()
        list.orientation = .vertical
        list.alignment = .leading
        list.spacing = 8
        for (index, line) in lines.enumerated() {
            let row = Self.row(line, width: width)
            row.setAccessibilityIdentifier("setup.done.line.\(index)")
            list.addArrangedSubview(row)
        }
        views.append(list)
        let done = keyButton(Text.uiSetupDone.text, self, #selector(doneClicked), "setup.done.ok")
        done.keyEquivalent = "\r"
        let buttons = buttonRow([done], help: "setup")
        views.append(buttons)
        let stack = windowStack(views, in: window, width: width)
        stack.setCustomSpacing(20, after: list)
        window.setContentSize(NSSize(width: width + 40, height: stack.fittingSize.height))
        window.initialFirstResponder = done
    }

    /// a line with the sign of its kind: a part with its name, added, skipped or a note
    private static func row(_ line: SetupLine, width: CGFloat) -> NSView {
        let (symbol, color): (String, NSColor) = switch line.kind {
        case PE_SETUP_LINE_KIND_ADDED, PE_SETUP_LINE_KIND_PART: ("checkmark.circle.fill", .systemGreen)
        case PE_SETUP_LINE_KIND_SKIPPED: ("minus.circle.fill", .secondaryLabelColor)
        default: ("info.circle.fill", .systemBlue)
        }
        let sign = NSImageView()
        sign.image = NSImage(systemSymbolName: symbol, accessibilityDescription: nil)
        sign.contentTintColor = color
        sign.setContentHuggingPriority(.required, for: .horizontal)
        let words = line.kind == PE_SETUP_LINE_KIND_PART && !line.name.isEmpty ? line.name + ": " + line.text : line.text
        let label = wrappingLabel(words)
        label.widthAnchor.constraint(equalToConstant: width - 26).isActive = true
        let row = NSStackView(views: [sign, label])
        row.alignment = .firstBaseline
        row.spacing = 6
        return row
    }

    @objc private func doneClicked() {
        NSApp.stopModal()
    }

    func run() {
        runKeyWindow(window)
    }
}
