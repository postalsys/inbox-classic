// The language of the windows and the Settings window (Inbox Classic > Settings, Cmd+,). Every word comes from the
// core's catalogs (Generated/Texts.swift); the language is set once at start, before any window reads a word, and a
// language chosen here takes effect when the app starts again. It is kept as the app's own AppleLanguages, so the
// system's per-app language setting (System Settings > General > Language & Region > Applications) is the same choice.
import AppKit
import CInboxClassic
import UniformTypeIdentifiers

@MainActor
enum Languages {
    /// The language of the windows for this run: `override` (--language), or the first of the app's preferred
    /// languages (its own AppleLanguages, the system's otherwise) there is a catalog of, English when none
    static func apply(_ override: String?) {
        let wanted = override ?? resolve(Locale.preferredLanguages)
        // the code of the catalog the core took (de-AT is de, a language without one English), the pseudo-language's
        // dates English
        let used = taken(wanted.withCString { pe_set_language($0) }) ?? "en"
        let code = used == "qps" ? "en" : used
        locale = Locale(identifier: Locale.current.region.map { "\(code)_\($0.identifier)" } ?? code)
        instantLocale = locale
    }

    /// The code of the language the windows are in now
    static var current: String {
        taken(pe_language()) ?? "en"
    }

    /// The language of the windows with the system's region, for the dates written out in words
    private(set) static var locale = Locale.current

    /// The code of the language there is a catalog of for these preferred languages
    static func resolve(_ preferred: [String]) -> String {
        let copies = preferred.map { strdup($0) }
        defer { copies.forEach { free($0) } }
        let pointers = copies.map { UnsafePointer($0) }
        return taken(pe_resolve_language(pointers, pointers.count)) ?? "en"
    }

    /// The languages there is a catalog of, by code and their names in themselves, English first
    static var all: [(code: String, name: String)] {
        guard let list = pe_languages() else { return [] }
        defer { pe_language_list_free(list) }
        return (0..<pe_language_list_count(list)).compactMap { index in
            guard let row = pe_language_list_get(list, index)?.pointee else { return nil }
            return (String(cString: row.code), String(cString: row.name))
        }
    }

    /// The language the system's own settings give, without the app's choice: what "System default" is
    static var system: String {
        let global = UserDefaults.standard.persistentDomain(forName: UserDefaults.globalDomain)?["AppleLanguages"]
        return resolve(global as? [String] ?? Locale.preferredLanguages)
    }

    /// The language chosen for the app, nil for the system's
    static var chosen: String? {
        get {
            let own = UserDefaults.standard.persistentDomain(forName: Bundle.main.bundleIdentifier ?? "")?["AppleLanguages"]
            return (own as? [String])?.first.map { resolve([$0]) }
        }
        set {
            guard !TestHooks.testing else { return }
            if let newValue {
                UserDefaults.standard.set([newValue], forKey: "AppleLanguages")
            } else {
                UserDefaults.standard.removeObject(forKey: "AppleLanguages")
            }
        }
    }

    /// A language's name in itself
    static func name(_ code: String) -> String {
        all.first { $0.code == code }?.name ?? code
    }
}

/// Inbox Classic > Settings: the language of the windows, Notify of New Mail, Group messages by conversation, the
/// pictures of every message and the trusted senders, .eml files, and what is downloaded before it is opened. As Mac settings windows do, a change counts at
/// once; a language counts once the app starts again, which it offers to do.
@MainActor
final class SettingsWindow: NSObject, NSWindowDelegate {
    private static var shown: SettingsWindow?
    let window: NSWindow
    let language = NSPopUpButton()
    let notify: NSButton
    let grouping: NSButton
    let signInCodes: NSButton
    let pictures: NSButton
    let downloadAhead = NSPopUpButton()
    let downloadLimit = NSPopUpButton()
    /// Automatic, Classic, Columns: View > Layout's choice
    let layout = NSPopUpButton()
    private let core: Core
    /// the codes of the popup's items, nil for System default
    private var codes: [String?] = []

    static func open(core: Core) {
        if let shown {
            shown.window.makeKeyAndOrderFront(nil)
            return
        }
        let settings = SettingsWindow(core: core)
        shown = settings
        settings.window.center()
        settings.window.makeKeyAndOrderFront(nil)
    }

    /// the open window, for the UI test
    static var current: SettingsWindow? { shown }

    private init(core: Core) {
        self.core = core
        window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 440, height: 160), styleMask: [.titled, .closable],
                          backing: .buffered, defer: false)
        window.autorecalculatesKeyViewLoop = true
        notify = NSButton(checkboxWithTitle: Text.macNotifyNewMail.text, target: nil, action: nil)
        grouping = NSButton(checkboxWithTitle: Text.uiGroupByConversation.text, target: nil, action: nil)
        signInCodes = NSButton(checkboxWithTitle: Text.uiCodesInNotifications.text, target: nil, action: nil)
        pictures = NSButton(checkboxWithTitle: Text.uiPicturesAlwaysOption.text, target: nil, action: nil)
        super.init()
        window.title = Text.macSettingsTitle.text
        window.identifier = NSUserInterfaceItemIdentifier("settings")
        window.isReleasedWhenClosed = false
        window.delegate = self

        let system = Text.uiOptionsSystemDefault.text(["language": Languages.name(Languages.system)])
        language.addItem(withTitle: system)
        codes = [nil]
        for (code, name) in Languages.all {
            language.addItem(withTitle: name)
            codes.append(code)
        }
        let chosen = Languages.chosen
        language.selectItem(at: codes.firstIndex { $0 == chosen } ?? 0)
        language.target = self
        language.action = #selector(languageChosen)
        language.setAccessibilityIdentifier("settings.language")

        let hint = NSTextField(wrappingLabelWithString: Text.macRestartHint.text)
        hint.font = .systemFont(ofSize: NSFont.smallSystemFontSize)
        hint.textColor = .secondaryLabelColor

        notify.state = AppDelegate.shared?.notify ?? true ? .on : .off
        notify.target = self
        notify.action = #selector(notifyChanged)
        notify.setAccessibilityIdentifier("settings.notify")

        signInCodes.state = AppDelegate.shared?.codesInNotifications ?? false ? .on : .off
        signInCodes.target = self
        signInCodes.action = #selector(signInCodesChanged)
        signInCodes.setAccessibilityIdentifier("settings.codes")

        grouping.state = AppDelegate.shared?.groupByConversation ?? true ? .on : .off
        grouping.target = self
        grouping.action = #selector(groupingChanged)
        grouping.setAccessibilityIdentifier("settings.grouping")

        // under the notifications, as a choice of theirs
        let indented = NSStackView(views: [signInCodes])
        indented.edgeInsets = NSEdgeInsets(top: 0, left: 18, bottom: 0, right: 0)

        // reading: the pictures of every message, with what that tells senders under it, and the senders trusted
        pictures.state = core.alwaysLoadPictures ? .on : .off
        pictures.target = self
        pictures.action = #selector(picturesChanged)
        pictures.setAccessibilityIdentifier("settings.pictures")
        let warning = NSTextField(wrappingLabelWithString: Text.uiPicturesAlwaysWarning.text)
        warning.font = .systemFont(ofSize: NSFont.smallSystemFontSize)
        warning.textColor = .secondaryLabelColor
        let warned = NSStackView(views: [warning])
        warned.edgeInsets = NSEdgeInsets(top: 0, left: 18, bottom: 0, right: 0)
        let trusted = NSButton(title: Text.uiTrustedSendersButton.text.replacingOccurrences(of: "...", with: "…"), target: self,
                               action: #selector(trustedSendersClicked))
        trusted.setAccessibilityIdentifier("settings.trusted")
        let eml = NSButton(title: Text.uiEmlDefault.text, target: self, action: #selector(emlDefaultClicked))
        eml.setAccessibilityIdentifier("settings.eml")

        // downloading: what is downloaded ahead (in the order of PeDownloadAhead), how much each account keeps, and
        // what that means under them
        for item in [Text.uiDownloadAheadRecent, Text.uiDownloadAheadAll, Text.uiDownloadAheadNever] {
            downloadAhead.addItem(withTitle: item.text)
        }
        downloadAhead.selectItem(at: Int(core.downloadAhead.rawValue))
        downloadAhead.target = self
        downloadAhead.action = #selector(downloadAheadChosen)
        downloadAhead.setAccessibilityIdentifier("settings.downloadAhead")
        downloadLimit.addItems(withTitles: Core.downloadLimits)
        downloadLimit.selectItem(at: core.downloadLimitIndex)
        downloadLimit.target = self
        downloadLimit.action = #selector(downloadLimitChosen)
        downloadLimit.setAccessibilityIdentifier("settings.downloadLimit")
        let downloadNote = NSTextField(wrappingLabelWithString: Text.uiDownloadNote.text)
        downloadNote.font = .systemFont(ofSize: NSFont.smallSystemFontSize)
        downloadNote.textColor = .secondaryLabelColor
        // each label beside its pop-up, under the other settings: the language's label keeps the left column narrow
        let aheadRow = NSStackView(views: [NSTextField(labelWithString: Text.uiDownloadAhead.text), downloadAhead])
        let limitRow = NSStackView(views: [NSTextField(labelWithString: Text.uiDownloadLimit.text), downloadLimit])
        for row in [aheadRow, limitRow] {
            row.alignment = .firstBaseline
            row.spacing = 8
        }

        let label = NSTextField(labelWithString: Text.macLanguageLabel.text)
        label.alignment = .right
        // View > Layout's choices, each item tagged with its mode
        for (command, mode) in AppDelegate.layoutModes.sorted(by: { $0.value.rawValue < $1.value.rawValue }) {
            layout.addItem(withTitle: command.label)
            layout.lastItem?.tag = Int(mode.rawValue)
        }
        layout.selectItem(withTag: Int(AppDelegate.shared?.layoutMode.rawValue ?? 0))
        layout.target = self
        layout.action = #selector(layoutChosen)
        layout.setAccessibilityIdentifier("settings.layout")
        let layoutLabel = NSTextField(labelWithString: Text.uiLayoutLabel.text)
        layoutLabel.alignment = .right
        let grid = NSGridView(views: [
            [label, language],
            [NSGridCell.emptyContentView, hint],
            [layoutLabel, layout],
            [NSGridCell.emptyContentView, notify],
            [NSGridCell.emptyContentView, indented],
            [NSGridCell.emptyContentView, grouping],
            [NSGridCell.emptyContentView, pictures],
            [NSGridCell.emptyContentView, warned],
            [NSGridCell.emptyContentView, trusted],
            [NSGridCell.emptyContentView, eml],
            [NSGridCell.emptyContentView, aheadRow],
            [NSGridCell.emptyContentView, limitRow],
            [NSGridCell.emptyContentView, downloadNote],
        ])
        grid.rowSpacing = 8
        grid.columnSpacing = 8
        grid.column(at: 0).xPlacement = .trailing
        grid.row(at: 2).topPadding = 8
        grid.row(at: 3).topPadding = 8
        grid.row(at: 8).topPadding = 4
        grid.row(at: 9).topPadding = 8
        grid.row(at: 10).topPadding = 12
        // the labels on the pop-ups' text lines, as the other forms have them
        grid.row(at: 0).rowAlignment = .firstBaseline
        grid.row(at: 2).rowAlignment = .firstBaseline
        grid.translatesAutoresizingMaskIntoConstraints = false
        // the help button in the bottom right corner, as the system's settings have it
        let help = HelpButton("options")
        help.translatesAutoresizingMaskIntoConstraints = false
        let content = NSView()
        content.addSubview(grid)
        content.addSubview(help)
        NSLayoutConstraint.activate([
            grid.topAnchor.constraint(equalTo: content.topAnchor, constant: 20),
            grid.leadingAnchor.constraint(equalTo: content.leadingAnchor, constant: 20),
            grid.trailingAnchor.constraint(lessThanOrEqualTo: help.leadingAnchor, constant: -12),
            grid.bottomAnchor.constraint(equalTo: content.bottomAnchor, constant: -20),
            help.trailingAnchor.constraint(equalTo: content.trailingAnchor, constant: -20),
            help.bottomAnchor.constraint(equalTo: content.bottomAnchor, constant: -20),
            hint.widthAnchor.constraint(lessThanOrEqualToConstant: 320),
            warning.widthAnchor.constraint(lessThanOrEqualToConstant: 320),
            downloadNote.widthAnchor.constraint(lessThanOrEqualToConstant: 320),
        ])
        window.contentView = content
        window.setContentSize(content.fittingSize)
    }

    func windowWillClose(_ notification: Notification) {
        SettingsWindow.shown = nil
    }

    @objc private func layoutChosen() {
        AppDelegate.shared?.layoutMode = PeLayoutMode(rawValue: UInt32(max(0, layout.selectedTag())))
    }

    @objc func notifyChanged() {
        AppDelegate.shared?.notify = notify.state == .on
    }

    @objc func signInCodesChanged() {
        AppDelegate.shared?.codesInNotifications = signInCodes.state == .on
    }

    @objc func groupingChanged() {
        AppDelegate.shared?.groupByConversation = grouping.state == .on
    }

    @objc func picturesChanged() {
        core.alwaysLoadPictures = pictures.state == .on
        // the message shown now as the setting has it
        AppDelegate.shared?.main?.mailbox.reader.reload()
    }

    @objc func downloadAheadChosen() {
        // the items are in the order of PeDownloadAhead
        core.downloadAhead = PeDownloadAhead(rawValue: UInt32(max(downloadAhead.indexOfSelectedItem, 0)))
    }

    @objc func downloadLimitChosen() {
        core.downloadLimitIndex = downloadLimit.indexOfSelectedItem
    }

    @objc func trustedSendersClicked() {
        TrustedSendersSheet(core: core).run(on: window)
    }

    /// Open .eml Files with Inbox Classic: the app made the one for message files, as the system lets it
    @objc func emlDefaultClicked() {
        let bundle = Bundle.main.bundleURL
        guard bundle.pathExtension == "app", let type = UTType("com.apple.mail.email") else {
            inform(Text.macNotBundle.text)
            return
        }
        NSWorkspace.shared.setDefaultApplication(at: bundle, toOpen: type) { error in
            Task { @MainActor in
                if let error {
                    inform(Text.uiEmlDefaultFailed.text(["reason": error.localizedDescription]), style: .warning)
                } else {
                    inform(Text.uiEmlDefaultDone.text)
                }
            }
        }
    }

    @objc func languageChosen() {
        let index = language.indexOfSelectedItem
        guard codes.indices.contains(index) else { return }
        let code = codes[index]
        guard code != Languages.chosen else { return }
        Languages.chosen = code
        // asked only when the windows would change: System default that is German, then Deutsch, needs no new start
        guard (code ?? Languages.system) != Languages.current else { return }
        if ask(Text.macRestartQuestion.text, yes: Text.uiRestartNow.text, no: Text.uiRestartLater.text,
               style: .information) {
            AppDelegate.shared?.restart()
        }
    }
}

/// Settings > Trusted Senders: the senders whose pictures load by themselves (when their provider confirms the
/// message), in a table with the standard remove button under it
@MainActor
final class TrustedSendersSheet: NSObject, NSTableViewDataSource, NSTableViewDelegate {
    private static var shown: TrustedSendersSheet?
    let window: NSWindow
    private let core: Core
    let table = NSTableView()
    let remove = NSSegmentedControl()
    private let empty = NSTextField(labelWithString: Text.uiTrustedSendersEmpty.text)
    private(set) var senders: [(id: Int64, label: String)] = []

    /// the open sheet, for the UI test
    static var current: TrustedSendersSheet? { shown }

    init(core: Core) {
        self.core = core
        window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 420, height: 320), styleMask: [.titled], backing: .buffered,
                          defer: true)
        super.init()
        window.title = Text.uiTrustedSendersTitle.text
        window.identifier = NSUserInterfaceItemIdentifier("trusted")

        let title = NSTextField(labelWithString: Text.uiTrustedSendersTitle.text)
        title.font = .boldSystemFont(ofSize: NSFont.systemFontSize)
        let note = wrappingLabel(Text.uiTrustedSendersNote.text)
        note.font = .systemFont(ofSize: NSFont.smallSystemFontSize)
        note.textColor = .secondaryLabelColor

        let column = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("label"))
        column.resizingMask = .autoresizingMask
        table.addTableColumn(column)
        table.headerView = nil
        table.style = .fullWidth
        table.usesAlternatingRowBackgroundColors = true
        table.allowsMultipleSelection = true
        table.dataSource = self
        table.delegate = self
        table.setAccessibilityIdentifier("trusted.list")
        let scroll = NSScrollView()
        scroll.documentView = table
        scroll.hasVerticalScroller = true
        scroll.borderType = .bezelBorder
        scroll.translatesAutoresizingMaskIntoConstraints = false
        empty.textColor = .secondaryLabelColor
        empty.translatesAutoresizingMaskIntoConstraints = false
        empty.setAccessibilityIdentifier("trusted.empty")

        // the − under the table's corner, as the system's lists have it
        remove.segmentStyle = .smallSquare
        remove.trackingMode = .momentary
        remove.segmentCount = 1
        remove.setImage(NSImage(named: NSImage.removeTemplateName), forSegment: 0)
        remove.setWidth(24, forSegment: 0)
        remove.target = self
        remove.action = #selector(removeClicked)
        remove.setAccessibilityIdentifier("trusted.remove")
        remove.setToolTip(Text.uiRemove.text, forSegment: 0)
        remove.setAccessibilityLabel(Text.uiRemove.text)

        let done = NSButton(title: Text.uiDone.text, target: self, action: #selector(doneClicked))
        done.keyEquivalent = "\r"
        done.setAccessibilityIdentifier("trusted.done")

        let content = NSView()
        for view in [title, note, scroll, remove, done] as [NSView] {
            view.translatesAutoresizingMaskIntoConstraints = false
            content.addSubview(view)
        }
        content.addSubview(empty)
        NSLayoutConstraint.activate([
            title.topAnchor.constraint(equalTo: content.topAnchor, constant: 20),
            title.leadingAnchor.constraint(equalTo: content.leadingAnchor, constant: 20),
            note.topAnchor.constraint(equalTo: title.bottomAnchor, constant: 6),
            note.leadingAnchor.constraint(equalTo: content.leadingAnchor, constant: 20),
            note.trailingAnchor.constraint(equalTo: content.trailingAnchor, constant: -20),
            note.widthAnchor.constraint(equalToConstant: 380),
            scroll.topAnchor.constraint(equalTo: note.bottomAnchor, constant: 12),
            scroll.leadingAnchor.constraint(equalTo: content.leadingAnchor, constant: 20),
            scroll.trailingAnchor.constraint(equalTo: content.trailingAnchor, constant: -20),
            scroll.heightAnchor.constraint(equalToConstant: 180),
            remove.topAnchor.constraint(equalTo: scroll.bottomAnchor, constant: -1),
            remove.leadingAnchor.constraint(equalTo: scroll.leadingAnchor),
            empty.centerXAnchor.constraint(equalTo: scroll.centerXAnchor),
            empty.centerYAnchor.constraint(equalTo: scroll.centerYAnchor),
            done.topAnchor.constraint(equalTo: remove.bottomAnchor, constant: 16),
            done.trailingAnchor.constraint(equalTo: content.trailingAnchor, constant: -20),
            done.bottomAnchor.constraint(equalTo: content.bottomAnchor, constant: -20),
        ])
        window.contentView = content
        reload()
    }

    func run(on parent: NSWindow?) {
        TrustedSendersSheet.shown = self
        runSheet(window, on: parent)
        TrustedSendersSheet.shown = nil
    }

    private func reload() {
        senders = core.trustedSenders()
        table.reloadData()
        empty.isHidden = !senders.isEmpty
        updateRemove()
    }

    private func updateRemove() {
        remove.setEnabled(!table.selectedRowIndexes.isEmpty, forSegment: 0)
    }

    /// the selected senders no longer trusted
    @objc func removeClicked() {
        for row in table.selectedRowIndexes where senders.indices.contains(row) {
            pe_untrust_sender(core.handle, senders[row].id)
        }
        reload()
        // the message shown now as the list has it
        AppDelegate.shared?.main?.mailbox.reader.reload()
    }

    @objc private func doneClicked() {
        NSApp.stopModal()
    }

    func numberOfRows(in tableView: NSTableView) -> Int {
        senders.count
    }

    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        let id = NSUserInterfaceItemIdentifier("trusted.cell")
        let cell = tableView.makeView(withIdentifier: id, owner: nil) as? NSTableCellView ?? {
            let made = NSTableCellView()
            made.identifier = id
            let label = NSTextField(labelWithString: "")
            label.lineBreakMode = .byTruncatingTail
            label.translatesAutoresizingMaskIntoConstraints = false
            made.addSubview(label)
            made.textField = label
            NSLayoutConstraint.activate([
                label.leadingAnchor.constraint(equalTo: made.leadingAnchor, constant: 4),
                label.trailingAnchor.constraint(lessThanOrEqualTo: made.trailingAnchor, constant: -4),
                label.centerYAnchor.constraint(equalTo: made.centerYAnchor),
            ])
            return made
        }()
        cell.textField?.stringValue = senders.indices.contains(row) ? senders[row].label : ""
        return cell
    }

    func tableViewSelectionDidChange(_ notification: Notification) {
        updateRemove()
    }
}
