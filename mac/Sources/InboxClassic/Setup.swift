// Settings and accounts to another computer: File > Export Settings and Accounts writes one file of the parts chosen,
// sealed with a passphrase when one is typed; File > Import Settings and Accounts reads one (its passphrase asked
// first), shows what it holds, and imports the parts and accounts chosen. The core reads, checks and writes the file
// and says everything in words; these windows hand it the choices and the app's own preferences, which they take back
// and apply after an import.
import AppKit
import CInboxClassic
import UniformTypeIdentifiers

/// A line of words the core gave: what a part holds, what was added or skipped, or a note
struct SetupLine {
    let kind: PeSetupLineKind
    /// the `PE_SETUP_*` flag of a part line, 0 for the others
    let part: UInt32
    let text: String
}

/// An account of a setup file as the import window lists it
struct SetupAccount {
    let index: Int
    let email: String
    let imap: String
    let smtp: String
    let signIn: String
    /// set up here already: skipped
    let here: Bool
    /// why it can not be imported, nil when it can
    let problem: String?
    let note: String

    /// it can be chosen
    var importable: Bool { !here && problem == nil }
}

/// The parts of a file in the order the windows list them (the core's, which the import window follows), with their
/// names
@MainActor
let setupParts: [(flag: UInt32, name: Text)] = [
    (UInt32(PE_SETUP_ACCOUNTS), .uiSetupPartAccounts), (UInt32(PE_SETUP_SIGN_IN_APPS), .uiSetupPartSignInApps),
    (UInt32(PE_SETUP_SETTINGS), .uiSetupPartSettings), (UInt32(PE_SETUP_PREFERENCES), .uiSetupPartPreferences),
    (UInt32(PE_SETUP_CONTACTS), .uiSetupPartContacts), (UInt32(PE_SETUP_KEYS), .uiSetupPartKeys),
    (UInt32(PE_SETUP_RULES), .uiSetupPartRules), (UInt32(PE_SETUP_TRUSTED_SENDERS), .uiSetupPartTrusted),
]

/// A setup file read: what it holds; the handle is freed with this
final class SetupFile {
    let handle: OpaquePointer

    init(_ handle: OpaquePointer) {
        self.handle = handle
    }

    deinit {
        pe_setup_file_free(handle)
    }

    var info: PeSetupInfo? { pe_setup_file_info(handle)?.pointee }

    var accounts: [SetupAccount] {
        (0..<pe_setup_file_account_count(handle)).compactMap { pe_setup_file_account(handle, $0)?.pointee }.map {
            SetupAccount(index: $0.index, email: text($0.email), imap: text($0.imap), smtp: text($0.smtp),
                         signIn: text($0.sign_in), here: $0.here, problem: $0.problem.map { String(cString: $0) },
                         note: text($0.note))
        }
    }

    var parts: [SetupLine] {
        (0..<pe_setup_file_part_count(handle)).compactMap { pe_setup_file_part(handle, $0)?.pointee }.map {
            SetupLine(kind: $0.kind, part: $0.part, text: text($0.text))
        }
    }

    /// the app preferences it carries, by their shared names, values checked
    var prefs: [(name: String, value: String)] {
        (0..<pe_setup_file_pref_count(handle)).compactMap { pe_setup_file_pref(handle, $0)?.pointee }.map {
            (text($0.name), text($0.value))
        }
    }

    /// what it holds that can not be used and is left out
    var notes: [String] {
        (0..<pe_setup_file_note_count(handle)).map { text(pe_setup_file_note(handle, $0)) }
    }
}

enum SetupRead {
    case file(SetupFile)
    case needsPassphrase
    case wrongPassphrase(String)
    case invalid(String)
}

/// The lines of a `PeSetupLines`, freed
private func setupLines(_ lines: OpaquePointer) -> [SetupLine] {
    (0..<pe_setup_lines_count(lines)).compactMap { pe_setup_lines_get(lines, $0)?.pointee }.map {
        SetupLine(kind: $0.kind, part: $0.part, text: text($0.text))
    }
}

extension Core {
    /// writes the `parts` to `url`, sealed with `passphrase` when there is one, with the app's preferences: what each
    /// part holds, or why not
    func exportSetup(parts: UInt32, passphrase: String?, prefs: [(name: String, value: String)],
                     to url: URL) -> Result<[SetupLine], Refusal> {
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
        guard let lines = pe_setup_export_write(handle, export, url.path, &error) else {
            return .failure(Refusal(taken(error) ?? ""))
        }
        defer { pe_setup_lines_free(lines) }
        return .success(setupLines(lines))
    }

    /// the file at `url`, opened with `passphrase` when it is sealed
    func readSetup(_ url: URL, passphrase: String?) -> SetupRead {
        var kind = PE_SETUP_ERROR_NONE
        var error: UnsafeMutablePointer<CChar>?
        let strings = CStrings()
        defer { strings.wipe() }
        let file = pe_setup_read(handle, url.path, passphrase.map { strings.add($0) }, &kind, &error)
        let reason = taken(error) ?? ""
        if let file { return .file(SetupFile(file)) }
        switch kind {
        case PE_SETUP_ERROR_NEEDS_PASSPHRASE: return .needsPassphrase
        case PE_SETUP_ERROR_WRONG_PASSPHRASE: return .wrongPassphrase(reason)
        default: return .invalid(reason)
        }
    }

    /// imports `parts` of `file` and the accounts at `accounts`: what was done and the accounts added, or why not
    func importSetup(_ file: SetupFile, parts: UInt32, accounts: [Int]) -> Result<([SetupLine], [Int64]), Refusal> {
        var error: UnsafeMutablePointer<CChar>?
        let lines = accounts.withUnsafeBufferPointer {
            pe_setup_import(handle, file.handle, parts, $0.baseAddress, $0.count, &error)
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
    /// each portable preference of this app: how to read it and how to set it
    private static func bool(_ path: ReferenceWritableKeyPath<AppDelegate, Bool>)
        -> (get: (AppDelegate) -> String, set: (AppDelegate, String) -> Void) {
        ({ $0[keyPath: path] ? "1" : "0" }, { app, value in app[keyPath: path] = value == "1" })
    }

    private static var all: [String: (get: (AppDelegate) -> String, set: (AppDelegate, String) -> Void)] {
        [
            "notify_new_mail": bool(\.notify),
            "codes_in_notifications": bool(\.codesInNotifications),
            "group_by_conversation": bool(\.groupByConversation),
            "hide_ignored": bool(\.hideIgnored),
            "hide_read": bool(\.hideRead),
            "folder_list": bool(\.folderList),
            "list_pictures": bool(\.listPictures),
            "layout": ({ String($0.layoutMode.rawValue) }, { app, value in
                if let mode = UInt32(value), mode <= 2 { app.layoutMode = PeLayoutMode(rawValue: mode) }
            }),
            // the language counts once the app starts again: set last, which asks
            "language": ({ _ in Languages.chosen ?? "" }, { _, _ in }),
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

    /// sets and applies the preferences of a file, as Settings and the View menu do; the language last
    static func apply(_ prefs: [(name: String, value: String)]) {
        guard let app = AppDelegate.shared else { return }
        for pref in prefs where pref.name != "language" {
            all[pref.name]?.set(app, pref.value)
        }
        if let language = prefs.first(where: { $0.name == "language" }) {
            Languages.choose(language.value.isEmpty ? nil : language.value)
        }
    }
}

// ---- what the menu commands do ----

@MainActor
enum SetupFiles {
    /// the type of the files, `.inboxclassic`
    static var fileType: UTType {
        UTType(filenameExtension: "inboxclassic", conformingTo: .data) ?? .data
    }

    /// File > Export Settings and Accounts
    static func export(core: Core) {
        guard let written = SetupExportWindow(core: core).run() else { return }
        SetupDoneWindow(title: Text.uiSetupExportTitle.text, heading: written.file, lines: written.lines).run()
    }

    /// File > Import Settings and Accounts: a file chosen, its passphrase asked while it needs one, what to import
    /// chosen; the accounts added
    @discardableResult
    static func importFile(core: Core) -> [Int64] {
        let title = Text.uiSetupImportTitle.text
        guard let url = openFilesPanel(title: title, types: [fileType], multiple: false).first else { return [] }
        var read = core.readSetup(url, passphrase: nil)
        var passphrase: String?
        while true {
            let problem: String?
            switch read {
            case .file: problem = nil
            case .needsPassphrase: problem = nil
            case .wrongPassphrase(let reason): problem = reason
            case .invalid(let reason):
                inform(reason.isEmpty ? Text.uiUnknownReason.text : reason, title: title, style: .warning)
                return []
            }
            if case .file = read { break }
            passphrase = PassphraseWindow(title: title, intro: Text.uiSetupAskPassphrase.text, labels: [""], problem: problem,
                                          id: "setup.passphrase", help: "setup", check: nil).run()
            guard let passphrase else { return [] }
            read = core.readSetup(url, passphrase: passphrase)
        }
        passphrase = nil
        guard case .file(let file) = read, let done = SetupImportWindow(core: core, file: file).run() else { return [] }
        SetupDoneWindow(title: title, heading: nil, lines: done.lines).run()
        applyImported(core: core, file: file, parts: done.parts)
        return done.accounts
    }

    /// what the windows show of the parts imported, made again
    private static func applyImported(core: Core, file: SetupFile, parts: UInt32) {
        let main = AppDelegate.shared?.main
        if parts & UInt32(PE_SETUP_SETTINGS) != 0 {
            Preview.dark = core.darkMessages
            TextSize.apply(pe_text_zoom(core.handle))
            main?.mailbox.reader.reload()
            for window in MessageWindow.open {
                window.reader.reload()
            }
        }
        if parts & UInt32(PE_SETUP_CONTACTS) != 0 {
            AddressBookWindow.refresh()
        }
        main?.mailbox.reload()
        if parts & UInt32(PE_SETUP_PREFERENCES) != 0 {
            SetupPrefs.apply(file.prefs)
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
private final class SetupExportWindow: NSObject, NSTextFieldDelegate {
    private let core: Core
    private let window: NSWindow
    private var parts: [(flag: UInt32, box: NSButton)] = []
    private let usePassphrase: NSButton
    private let fields = [NSSecureTextField(string: ""), NSSecureTextField(string: "")]
    private let problem = NSTextField(labelWithString: "")
    private var exportButton: NSButton!
    private var written: (file: String, lines: [SetupLine])?

    init(core: Core) {
        self.core = core
        window = keyWindow(Text.uiSetupExportTitle.text, id: "setup.export")
        usePassphrase = NSButton(checkboxWithTitle: Text.uiSetupUsePassphrase.text, target: nil, action: nil)
        super.init()
        let width: CGFloat = 440
        let partList = NSStackView()
        partList.orientation = .vertical
        partList.alignment = .leading
        partList.spacing = 6
        for part in setupParts {
            let box = checkBox(part.name.text, self, #selector(changed), id: "setup.part.\(part.flag)")
            box.state = .on
            parts.append((part.flag, box))
            partList.addArrangedSubview(box)
        }
        let line = NSBox()
        line.boxType = .separator
        usePassphrase.target = self
        usePassphrase.action = #selector(passphraseToggled)
        usePassphrase.setAccessibilityIdentifier("setup.passphrase.use")
        let note = secondaryLabel(Text.uiSetupPassphraseNote.text, small: true)
        note.setAccessibilityIdentifier("setup.passphrase.note")
        let labels = [Text.uiKeysPassphrase.text, Text.uiKeysPassphraseAgain.text]
        for (index, field) in fields.enumerated() {
            field.delegate = self
            field.isEnabled = false
            field.setAccessibilityIdentifier("setup.passphrase.\(index)")
            field.setAccessibilityLabel(labels[index])
        }
        let grid = NSGridView(views: zip(labels, fields).map { [formLabel($0.0), $0.1] })
        grid.column(at: 0).xPlacement = .trailing
        grid.column(at: 1).xPlacement = .fill
        grid.rowAlignment = .firstBaseline
        grid.rowSpacing = 8
        grid.columnSpacing = 8
        problem.textColor = .systemRed
        problem.font = .systemFont(ofSize: NSFont.smallSystemFontSize)
        problem.lineBreakMode = .byWordWrapping
        problem.maximumNumberOfLines = 0
        problem.setAccessibilityIdentifier("setup.passphrase.problem")
        let passphrase = indented([note, grid, problem], spacing: 8)
        grid.widthAnchor.constraint(equalToConstant: width - checkIndent).isActive = true
        note.widthAnchor.constraint(equalToConstant: width - checkIndent).isActive = true
        problem.widthAnchor.constraint(equalToConstant: width - checkIndent).isActive = true
        // its line is there before anything is refused, so the window does not grow as one types
        problem.heightAnchor.constraint(greaterThanOrEqualToConstant: ceil(problem.font!.boundingRectForFont.height)).isActive = true

        let cancel = keyButton(Text.uiCancel.text, self, #selector(cancelled), "setup.cancel")
        cancel.keyEquivalent = "\u{1b}"
        exportButton = keyButton(Text.uiSetupExportButton.text.replacingOccurrences(of: "...", with: "\u{2026}"), self,
                                 #selector(exportClicked), "setup.export.ok")
        exportButton.keyEquivalent = "\r"
        let buttons = buttonRow([cancel, exportButton], help: "setup")
        let views: [NSView] = [wrappingLabel(Text.uiSetupExportIntro.text), partList, line, usePassphrase, passphrase, buttons]
        let stack = windowStack(views, in: window, width: width)
        stack.setCustomSpacing(16, after: views[0])
        stack.setCustomSpacing(16, after: partList)
        stack.setCustomSpacing(6, after: usePassphrase)
        stack.setCustomSpacing(16, after: passphrase)
        window.setContentSize(NSSize(width: width + 40, height: stack.fittingSize.height))
        window.initialFirstResponder = parts.first?.box
        update()
    }

    private var chosenParts: UInt32 {
        parts.filter { $0.box.state == .on }.reduce(0) { $0 | $1.flag }
    }

    /// the problem of what is typed, nil when it is right
    private var passphraseProblem: String? {
        guard usePassphrase.state == .on else { return nil }
        return core.pgpPassphraseProblem(fields[0].stringValue, fields[1].stringValue)
    }

    /// the problem said under the fields once the second is being typed: too short at once, typed differently once
    /// the second is as long as the first; Export only when the parts and the passphrase are right
    private func update() {
        let on = usePassphrase.state == .on
        fields.forEach { $0.isEnabled = on }
        let first = fields[0].stringValue
        let again = fields[1].stringValue
        var said = ""
        if on && !again.isEmpty {
            if let short = core.pgpPassphraseProblem(first, first) {
                said = short
            } else if first != again && again.count >= first.count {
                said = passphraseProblem ?? ""
            }
        }
        problem.stringValue = said
        exportButton.isEnabled = chosenParts != 0 && passphraseProblem == nil
    }

    func controlTextDidChange(_ notification: Notification) {
        update()
    }

    @objc private func changed() {
        update()
    }

    @objc private func passphraseToggled() {
        if usePassphrase.state == .off {
            fields.forEach { $0.stringValue = "" }
        }
        update()
        if usePassphrase.state == .on {
            window.makeFirstResponder(fields[0])
        }
    }

    @objc private func exportClicked() {
        update()
        guard exportButton.isEnabled else { return }
        let title = Text.uiSetupExportTitle.text
        guard let url = saveFilePanel(name: "Inbox Classic.inboxclassic", title: title, types: [SetupFiles.fileType]) else {
            return
        }
        let passphrase = usePassphrase.state == .on ? fields[0].stringValue : nil
        switch core.exportSetup(parts: chosenParts, passphrase: passphrase, prefs: SetupPrefs.current, to: url) {
        case .success(let lines):
            written = (url.lastPathComponent, lines)
            NSApp.stopModal()
        case .failure(let refusal):
            inform(refusal.reason.isEmpty ? Text.macFileNotSaved.text : refusal.reason, title: title, style: .warning)
        }
    }

    @objc private func cancelled() {
        NSApp.stopModal()
    }

    /// the file's name and what it holds, nil when cancelled
    func run() -> (file: String, lines: [SetupLine])? {
        runKeyWindow(window)
        fields.forEach { $0.stringValue = "" }
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
    private var accounts: [(account: SetupAccount, box: NSButton)] = []
    private var importButton: NSButton!
    private var done: (lines: [SetupLine], parts: UInt32, accounts: [Int64])?

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
            guard let name = setupParts.first(where: { $0.flag == line.part })?.name else { continue }
            let box = checkBox(name.text, self, #selector(changed), id: "setup.part.\(line.part)")
            box.state = .on
            parts.append((line.part, box))
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
            if line.part == UInt32(PE_SETUP_ACCOUNTS) && !file.accounts.isEmpty {
                let list = accountList(width: width - checkIndent)
                partList.addArrangedSubview(list)
                partList.setCustomSpacing(10, after: list)
            }
        }
        views.append(partList)
        for (index, note) in file.notes.enumerated() {
            views.append(warningNote(note, id: "setup.import.note.\(index)"))
        }
        let cancel = keyButton(Text.uiCancel.text, self, #selector(cancelled), "setup.cancel")
        cancel.keyEquivalent = "\u{1b}"
        importButton = keyButton(Text.uiSetupImportButton.text, self, #selector(importClicked), "setup.import.ok")
        importButton.keyEquivalent = "\r"
        let buttons = buttonRow([cancel, importButton], help: "setup")
        views.append(buttons)
        let stack = windowStack(views, in: window, width: width)
        if views.count > 1 {
            stack.setCustomSpacing(16, after: partList)
            stack.setCustomSpacing(16, after: views[views.count - 2])
        }
        window.setContentSize(NSSize(width: width + 40, height: stack.fittingSize.height))
        window.initialFirstResponder = parts.first?.box
        update()
    }

    /// a check box for each account under Accounts: its address, its servers and how it signs in, and what the
    /// import does with it; one set up here already, or one that can not be imported, unchecked and off. Scrolls
    /// when there are many.
    private func accountList(width: CGFloat) -> NSView {
        let list = NSStackView()
        list.orientation = .vertical
        list.alignment = .leading
        list.spacing = 10
        for account in file.accounts {
            let box = checkBox(account.email, self, #selector(changed), id: "setup.account.\(account.index)")
            box.state = account.importable ? .on : .off
            let servers = secondaryLabel([account.imap, account.smtp, account.signIn].filter { !$0.isEmpty }
                .joined(separator: " \u{00b7} "), small: true)
            let said = secondaryLabel(account.problem ?? account.note, small: true)
            said.setAccessibilityIdentifier("setup.account.\(account.index).note")
            if account.problem != nil {
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
        let document = FlippedView()
        document.addSubview(holder)
        holder.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            holder.topAnchor.constraint(equalTo: document.topAnchor),
            holder.leadingAnchor.constraint(equalTo: document.leadingAnchor),
            holder.trailingAnchor.constraint(equalTo: document.trailingAnchor),
            holder.bottomAnchor.constraint(equalTo: document.bottomAnchor),
        ])
        let scroll = NSScrollView()
        scroll.hasVerticalScroller = true
        scroll.drawsBackground = false
        scroll.documentView = document
        document.translatesAutoresizingMaskIntoConstraints = false
        document.widthAnchor.constraint(equalTo: scroll.contentView.widthAnchor).isActive = true
        scroll.widthAnchor.constraint(equalToConstant: width).isActive = true
        let four = list.arrangedSubviews.prefix(4).reduce(0) { $0 + $1.fittingSize.height } + 3 * list.spacing
        scroll.heightAnchor.constraint(equalToConstant: ceil(four) + 4).isActive = true
        return scroll
    }

    private func chosen(_ flag: UInt32) -> Bool {
        parts.contains { $0.flag == flag && $0.box.state == .on }
    }

    private var chosenParts: UInt32 {
        parts.filter { $0.box.state == .on }.reduce(0) { $0 | $1.flag }
    }

    private var chosenAccounts: [Int] {
        chosen(UInt32(PE_SETUP_ACCOUNTS)) ? accounts.filter { $0.box.state == .on }.map(\.account.index) : []
    }

    /// the accounts can be chosen while Accounts is; Import while something would be imported
    private func update() {
        let withAccounts = chosen(UInt32(PE_SETUP_ACCOUNTS))
        for entry in accounts {
            entry.box.isEnabled = withAccounts && entry.account.importable
        }
        let others = chosenParts & ~UInt32(PE_SETUP_ACCOUNTS)
        importButton.isEnabled = others != 0 || !chosenAccounts.isEmpty
    }

    @objc private func changed() {
        update()
    }

    @objc private func importClicked() {
        // Accounts without any account chosen imports nothing of it
        var parts = chosenParts
        if chosenAccounts.isEmpty {
            parts &= ~UInt32(PE_SETUP_ACCOUNTS)
        }
        switch core.importSetup(file, parts: parts, accounts: chosenAccounts) {
        case .success(let (lines, added)):
            done = (lines, parts, added)
            NSApp.stopModal()
        case .failure(let refusal):
            inform(refusal.reason.isEmpty ? Text.uiUnknownReason.text : refusal.reason, title: window.title, style: .warning)
        }
    }

    @objc private func cancelled() {
        NSApp.stopModal()
    }

    /// what was done, the parts imported and the accounts added; nil when cancelled
    func run() -> (lines: [SetupLine], parts: UInt32, accounts: [Int64])? {
        runKeyWindow(window)
        return done
    }
}

/// The document view of a scroll, laid out from its top
private final class FlippedView: NSView {
    override var isFlipped: Bool { true }
}

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
        var words = line.text
        if line.kind == PE_SETUP_LINE_KIND_PART, let name = setupParts.first(where: { $0.flag == line.part })?.name {
            words = name.text + ": " + line.text
        }
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
