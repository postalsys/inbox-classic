// The language of the windows and the Settings window (Inbox Classic > Settings, Cmd+,). Every word comes from the
// core's catalogs (Generated/Texts.swift); the language is set once at start, before any window reads a word, and a
// language chosen here takes effect when the app starts again. It is kept as the app's own AppleLanguages, so the
// system's per-app language setting (System Settings > General > Language & Region > Applications) is the same choice.
import AppKit
import CInboxClassic
import Sparkle
import UniformTypeIdentifiers

@MainActor
enum Languages {
    /// The language of the windows for this run: `override` (--language), or the first of the app's preferred
    /// languages (its own AppleLanguages, the system's otherwise) there is a catalog of, English when none
    static func apply(_ override: String?) {
        let wanted = override ?? resolve(Locale.preferredLanguages)
        // the catalog the core takes (de-AT is de, a language without one English), and the core's locale of its dates:
        // its own region (pt_BR) or the system's (de_EE), English for the pseudo-language
        _ = taken(wanted.withCString { pe_set_language($0) })
        let region = Locale.current.region?.identifier
        let identifier = region.map { r in r.withCString { taken(pe_date_locale($0)) } } ?? taken(pe_date_locale(nil))
        locale = Locale(identifier: identifier ?? "en")
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

    /// `code` (nil for the system's) chosen for the windows, and the app started again when the user wants it now
    static func choose(_ code: String?) {
        guard code != chosen else { return }
        chosen = code
        offerRestart(for: code)
    }

    /// the app started again when the user wants it now, for `code` (nil for the system's), the language just chosen,
    /// to count: the language chosen is passed in, as a test run keeps nothing in the user's settings
    static func offerRestart(for code: String?) {
        // asked only when the windows would change: System default that is German, then Deutsch, needs no new start
        guard (code ?? system) != current else { return }
        if ask(Text.uiRestartAsk.text(["language": name(code ?? system)]), yes: Text.uiRestartNow.text, no: Text.uiRestartLater.text,
               style: .information) {
            AppDelegate.shared?.restart()
        }
    }

    /// A language's name in itself
    static func name(_ code: String) -> String {
        all.first { $0.code == code }?.name ?? code
    }
}

/// Inbox Classic > Settings: the panes of core/settings.toml (General, Reading, Downloading) behind a toolbar, as the
/// system's own apps have them. The window is titled by its pane and opens on the one chosen last. As Mac settings
/// windows do, a change counts at once; a language counts once the app starts again, which it offers to do.
@MainActor
final class SettingsWindow: NSObject, NSWindowDelegate, NSToolbarDelegate {
    private static var shown: SettingsWindow?
    /// the pane chosen last, by its name in settings.toml
    private static var lastPane = Preference("SettingsPane", default: SettingsPage.general.rawValue)
    /// the width of a pane, its margins included; long words wrap within it
    private static let width: CGFloat = 520
    private static let margin: CGFloat = 20
    /// the widest a pop-up's label gets before it wraps, so the controls keep their room
    private static let widestLabel: CGFloat = 220
    /// how far a check box's title starts from its box: a note or a dependent check box under it starts there
    private static let indent: CGFloat = 20
    /// between a label and its pop-up
    private static let spacing: CGFloat = 8

    let window: NSWindow
    private(set) var pane = SettingsPage.general
    private var panes: [SettingsPage: NSView] = [:]
    /// the controls of the settings, every pane's, made when the window opens
    private var controls: [Setting: NSControl] = [:]
    private let core: Core
    /// the codes of the language pop-up's items, nil for System default
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
        window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: Self.width, height: 200), styleMask: [.titled, .closable],
                          backing: .buffered, defer: false)
        super.init()
        window.identifier = NSUserInterfaceItemIdentifier("settings")
        window.isReleasedWhenClosed = false
        window.delegate = self
        window.toolbarStyle = .preference
        let toolbar = NSToolbar(identifier: "settings")
        toolbar.delegate = self
        toolbar.allowsUserCustomization = false
        window.toolbar = toolbar
        for page in SettingsPage.allCases {
            panes[page] = makePane(page)
        }
        updateDependents()
        select(SettingsPage(rawValue: Self.lastPane.value) ?? .general, animate: false)
    }

    func windowWillClose(_ notification: Notification) {
        SettingsWindow.shown = nil
    }

    // ---- the panes ----

    /// `page` shown, as its toolbar item does: the window titled by it and as tall as it, its top edge kept
    func select(_ page: SettingsPage, animate: Bool = true) {
        guard let view = panes[page] else { return }
        pane = page
        Self.lastPane.value = page.rawValue
        window.toolbar?.selectedItemIdentifier = NSToolbarItem.Identifier(page.rawValue)
        window.title = page.label.text
        let size = view.fittingSize
        var frame = window.frameRect(forContentRect: NSRect(origin: .zero, size: size))
        frame.origin = NSPoint(x: window.frame.minX, y: window.frame.maxY - frame.height)
        // the window grows or shrinks empty, then shows the pane, as the system's settings windows do
        if animate && window.isVisible && frame.size != window.frame.size {
            window.contentView = NSView()
            window.setFrame(frame, display: true, animate: true)
        } else {
            window.setFrame(frame, display: true)
        }
        window.contentView = view
        window.recalculateKeyViewLoop()
    }

    @objc private func paneClicked(_ item: NSToolbarItem) {
        SettingsPage(rawValue: item.itemIdentifier.rawValue).map { select($0) }
    }

    /// the controls the UI test reads and the actions read back
    var language: NSPopUpButton { popup(.language) }
    var notify: NSButton { box(.notifyNewMail) }
    var signInCodes: NSButton { box(.codesInNotifications) }
    /// Delay before sending (Undo Send)
    var sendDelay: NSPopUpButton { popup(.sendDelay) }
    /// Check for updates automatically: Sparkle's own setting, disabled in a build without it
    var checkUpdates: NSButton { box(.checkForUpdates) }
    /// Automatic, Classic, Columns: View > Layout's choice
    var layout: NSPopUpButton { popup(.layout) }
    var grouping: NSButton { box(.groupByConversation) }
    var wholeConversation: NSButton { box(.showWholeConversation) }
    var conversationOrder: NSPopUpButton { popup(.conversationOrder) }
    var listPictures: NSButton { box(.listPictures) }
    /// Show messages on a dark background when the system is dark
    var darkMessages: NSButton { box(.darkMessages) }
    var pictures: NSButton { box(.picturesAlways) }
    /// Show attachments in messages, and under it Show PDF files in messages
    var showPreviews: NSButton { box(.showPreviews) }
    var pdfPreviews: NSButton { box(.pdfPreviews) }
    /// Search in encrypted messages and Look up keys on keys.openpgp.org, under Encryption
    var searchEncrypted: NSButton { box(.searchEncrypted) }
    var keyserver: NSButton { box(.keyserver) }
    var downloadAhead: NSPopUpButton { popup(.downloadAhead) }
    var downloadLimit: NSPopUpButton { popup(.downloadLimit) }

    // every setting's control is made in init, so these always find theirs
    private func popup(_ setting: Setting) -> NSPopUpButton {
        controls[setting] as! NSPopUpButton
    }

    private func box(_ setting: Setting) -> NSButton {
        controls[setting] as! NSButton
    }

    /// A pane: its groups' settings in a grid, the labels right aligned before the controls, as Apple's panes have
    /// them (a pop-up's own, and a group's title on its first control's row when that is no pop-up), the groups set
    /// apart by space, and the help button in the bottom right corner
    private func makePane(_ page: SettingsPage) -> NSView {
        let settings = page.groups.flatMap(\.settings)
        for setting in settings {
            controls[setting] = control(for: setting)
        }
        let labels = labelColumn(for: page, controls: settings.compactMap { controls[$0] })
        let labelWidth = labels.values.map(\.preferredMaxLayoutWidth).max() ?? 0
        let room = Self.width - 2 * Self.margin
        let column = labelWidth > 0 ? room - labelWidth - Self.spacing : room
        let grid = NSGridView()
        grid.rowSpacing = 10
        grid.columnSpacing = Self.spacing
        for (index, group) in page.groups.enumerated() {
            let first = grid.numberOfRows
            for setting in group.settings {
                guard let control = controls[setting] else { continue }
                // a check box that depends on the one before it starts where that one's title does
                let width = column - (setting.dependsOn == nil ? 0 : Self.indent)
                (control as? WrappingCheckbox)?.preferredMaxLayoutWidth = width
                if setting.kind == .choice {
                    labels[setting].map(control.setAccessibilityTitleUIElement)
                }
                let cell = stacked(control, note: setting.note, setting: setting, width: width)
                let row = grid.addRow(with: [labels[setting] ?? NSGridCell.emptyContentView,
                                             width < column ? indented(cell, by: column - width) : cell])
                row.rowAlignment = .firstBaseline
            }
            if let note = group.note {
                grid.addRow(with: [NSGridCell.emptyContentView, noteLabel(note.text, width: column)])
                grid.row(at: grid.numberOfRows - 1).topPadding = -4
            }
            if index > 0 && grid.numberOfRows > first {
                grid.row(at: first).topPadding = 12
            }
        }
        // a pane without pop-ups has its controls start at the margin
        grid.column(at: 0).isHidden = labels.isEmpty
        grid.column(at: 0).xPlacement = .trailing
        return framed(grid)
    }

    /// The labels of `page` by their settings, as wide as the widest of them, up to a limit that leaves the widest of
    /// `controls` that does not wrap (a pop-up or push button) its room; check boxes and notes wrap in what is left
    private func labelColumn(for page: SettingsPage, controls: [NSControl]) -> [Setting: NSTextField] {
        let room = Self.width - 2 * Self.margin
        let widestFixed = controls.filter { !($0 is WrappingCheckbox) }.map(\.intrinsicContentSize.width).max() ?? 0
        let limit = max(min(Self.widestLabel, room - Self.spacing - ceil(widestFixed)), Self.widestLabel / 2)
        var labels: [Setting: NSTextField] = [:]
        for group in page.groups {
            for setting in group.settings {
                if let text = labelText(setting, in: group) {
                    labels[setting] = label(text, limit)
                }
            }
        }
        return labels
    }

    /// `grid` within the pane's margins, the help button in the bottom right corner under it
    private func framed(_ grid: NSGridView) -> NSView {
        grid.translatesAutoresizingMaskIntoConstraints = false
        let help = HelpButton("options")
        help.translatesAutoresizingMaskIntoConstraints = false
        let view = NSView()
        view.addSubview(grid)
        view.addSubview(help)
        NSLayoutConstraint.activate([
            view.widthAnchor.constraint(equalToConstant: Self.width),
            grid.topAnchor.constraint(equalTo: view.topAnchor, constant: Self.margin),
            grid.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: Self.margin),
            grid.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -Self.margin),
            help.topAnchor.constraint(equalTo: grid.bottomAnchor, constant: 16),
            help.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -Self.margin),
            help.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -Self.margin),
        ])
        return view
    }

    /// The control of `setting`, set to its value
    private func control(for setting: Setting) -> NSControl {
        let app = AppDelegate.shared
        switch setting {
        case .language:
            return fillLanguages(choice(setting, #selector(languageChosen)))
        case .notifyNewMail:
            return toggle(setting, app?.notify ?? true, #selector(notifyChanged))
        case .codesInNotifications:
            return toggle(setting, app?.codesInNotifications ?? false, #selector(signInCodesChanged))
        case .sendDelay:
            return filled(choice(setting, #selector(sendDelayChosen)), Core.sendDelays, core.sendDelayIndex)
        case .defaultMailApp:
            return button(setting, #selector(defaultAppClicked))
        case .emlDefault:
            return button(setting, #selector(emlDefaultClicked))
        case .checkForUpdates:
            let box = toggle(setting, app?.updater?.automaticallyChecksForUpdates ?? false, #selector(checkUpdatesChanged))
            box.isEnabled = app?.updater != nil
            return box
        case .layout:
            return fillLayouts(choice(setting, #selector(layoutChosen)))
        case .groupByConversation:
            return toggle(setting, app?.groupByConversation ?? true, #selector(groupingChanged))
        case .showWholeConversation:
            return toggle(setting, app?.wholeConversation ?? true, #selector(wholeConversationChanged))
        case .conversationOrder:
            return filled(choice(setting, #selector(conversationOrderChosen)),
                          [Text.uiConversationOldestFirst.text, Text.uiConversationNewestFirst.text],
                          app?.conversationNewestFirst == true ? 1 : 0)
        case .listPictures:
            return toggle(setting, app?.listPictures ?? true, #selector(listPicturesChanged))
        case .darkMessages:
            return toggle(setting, core.darkMessages, #selector(darkMessagesChanged))
        case .showPreviews:
            return toggle(setting, core.showPreviews, #selector(showPreviewsChanged))
        case .pdfPreviews:
            return toggle(setting, core.pdfPreviews, #selector(pdfPreviewsChanged))
        case .picturesAlways:
            return toggle(setting, core.alwaysLoadPictures, #selector(picturesChanged))
        case .searchEncrypted:
            return toggle(setting, core.searchEncrypted, #selector(searchEncryptedChanged))
        case .keyserver:
            return toggle(setting, core.keyserver, #selector(keyserverChanged))
        case .trustedSenders:
            return button(setting, #selector(trustedSendersClicked))
        case .downloadAhead:
            return fillDownloadAhead(choice(setting, #selector(downloadAheadChosen)))
        case .downloadLimit:
            return filled(choice(setting, #selector(downloadLimitChosen)), Core.downloadLimits, core.downloadLimitIndex)
        }
    }

    /// the accessibility id of a setting's control, as the UI test finds it
    private func id(_ setting: Setting) -> String {
        "settings.\(setting)"
    }

    private func toggle(_ setting: Setting, _ on: Bool, _ action: Selector) -> WrappingCheckbox {
        let box = WrappingCheckbox()
        box.title = hyphensKept(setting.label.text)
        box.state = on ? .on : .off
        box.target = self
        box.action = action
        box.setAccessibilityIdentifier(id(setting))
        return box
    }

    private func choice(_ setting: Setting, _ action: Selector) -> NSPopUpButton {
        let popup = NSPopUpButton()
        popup.target = self
        popup.action = action
        popup.setAccessibilityIdentifier(id(setting))
        return popup
    }

    private func button(_ setting: Setting, _ action: Selector) -> NSButton {
        let button = NSButton(title: setting.label.opens, target: self, action: action)
        button.setAccessibilityIdentifier(id(setting))
        return button
    }

    /// the words before `setting`: a pop-up's own label, its group's title with a colon on the group's first row
    private func labelText(_ setting: Setting, in group: SettingsGroup) -> String? {
        if setting.kind == .choice {
            return setting.label.text
        }
        guard setting == group.settings.first, let title = group.label else { return nil }
        return Text.uiSettingsLabel.text(["label": title.text])
    }

    /// a label of the label column, right aligned, wrapping when it is longer than the column may be
    private func label(_ words: String, _ limit: CGFloat) -> NSTextField {
        let text = hyphensKept(words)
        let width = min(ceil(NSTextField(labelWithString: text).intrinsicContentSize.width), limit)
        let label = NSTextField(wrappingLabelWithString: text)
        label.isSelectable = false
        label.alignment = .right
        label.preferredMaxLayoutWidth = width
        label.widthAnchor.constraint(equalToConstant: width).isActive = true
        return label
    }

    /// a control with its note under it, the note where a check box's title starts
    private func stacked(_ control: NSView, note: Text?, setting: Setting, width: CGFloat) -> NSView {
        guard let note else { return control }
        let inset = setting.kind == .toggle ? Self.indent : 0
        let text = noteLabel(note.text, width: width - inset)
        let stack = NSStackView(views: [control, inset > 0 ? indented(text, by: inset) : text])
        stack.orientation = .vertical
        stack.alignment = .leading
        stack.spacing = 6
        return stack
    }

    private func noteLabel(_ text: String, width: CGFloat) -> NSTextField {
        let label = NSTextField(wrappingLabelWithString: hyphensKept(text))
        label.isSelectable = false
        label.font = .systemFont(ofSize: NSFont.smallSystemFontSize)
        label.textColor = .secondaryLabelColor
        label.preferredMaxLayoutWidth = width
        return label
    }

    private func indented(_ view: NSView, by inset: CGFloat) -> NSView {
        let stack = NSStackView(views: [view])
        stack.edgeInsets = NSEdgeInsets(top: 0, left: inset, bottom: 0, right: 0)
        return stack
    }

    /// `popup` with `titles`, the one at `selected` chosen
    private func filled(_ popup: NSPopUpButton, _ titles: [String], _ selected: Int) -> NSPopUpButton {
        popup.addItems(withTitles: titles)
        popup.selectItem(at: selected)
        return popup
    }

    /// System default and the languages there is a catalog of, the one chosen selected
    private func fillLanguages(_ popup: NSPopUpButton) -> NSPopUpButton {
        let languages = Languages.all
        codes = [nil] + languages.map(\.code)
        let titles = [Text.uiOptionsSystemDefault.text(["language": Languages.name(Languages.system)])] + languages.map(\.name)
        let chosen = Languages.chosen
        return filled(popup, titles, codes.firstIndex { $0 == chosen } ?? 0)
    }

    /// View > Layout's choices, each item tagged with its mode
    private func fillLayouts(_ popup: NSPopUpButton) -> NSPopUpButton {
        for (command, mode) in AppDelegate.layoutModes.sorted(by: { $0.value.rawValue < $1.value.rawValue }) {
            popup.addItem(withTitle: command.label)
            popup.lastItem?.tag = Int(mode.rawValue)
        }
        popup.selectItem(withTag: Int(AppDelegate.shared?.layoutMode.rawValue ?? 0))
        return popup
    }

    /// Recent, All and Never, in the order of PeDownloadAhead
    private func fillDownloadAhead(_ popup: NSPopUpButton) -> NSPopUpButton {
        let items = [Text.uiDownloadAheadRecent, Text.uiDownloadAheadAll, Text.uiDownloadAheadNever]
        return filled(popup, items.map(\.text), Int(core.downloadAhead.rawValue))
    }

    /// a check box that depends on another enabled only while that one is checked, keeping its own value
    private func updateDependents() {
        for (setting, control) in controls {
            if let parent = setting.dependsOn.flatMap({ controls[$0] as? NSButton }) {
                control.isEnabled = parent.state == .on
            }
        }
    }

    // ---- the toolbar ----

    func toolbar(_ toolbar: NSToolbar, itemForItemIdentifier itemIdentifier: NSToolbarItem.Identifier,
                 willBeInsertedIntoToolbar flag: Bool) -> NSToolbarItem? {
        guard let page = SettingsPage(rawValue: itemIdentifier.rawValue) else { return nil }
        let item = NSToolbarItem(itemIdentifier: itemIdentifier)
        item.label = page.label.text
        item.image = NSImage(systemSymbolName: page.symbol, accessibilityDescription: nil)
        item.target = self
        item.action = #selector(paneClicked(_:))
        return item
    }

    func toolbarDefaultItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
        SettingsPage.allCases.map { NSToolbarItem.Identifier($0.rawValue) }
    }

    func toolbarAllowedItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
        toolbarDefaultItemIdentifiers(toolbar)
    }

    func toolbarSelectableItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
        toolbarDefaultItemIdentifiers(toolbar)
    }

    // ---- what the controls do ----

    @objc func layoutChosen() {
        AppDelegate.shared?.layoutMode = PeLayoutMode(rawValue: UInt32(max(0, layout.selectedTag())))
    }

    @objc func notifyChanged() {
        AppDelegate.shared?.notify = notify.state == .on
        updateDependents()
    }

    @objc func signInCodesChanged() {
        AppDelegate.shared?.codesInNotifications = signInCodes.state == .on
    }

    @objc func groupingChanged() {
        AppDelegate.shared?.groupByConversation = grouping.state == .on
    }

    @objc func wholeConversationChanged() {
        AppDelegate.shared?.wholeConversation = wholeConversation.state == .on
    }

    @objc func conversationOrderChosen() {
        AppDelegate.shared?.conversationNewestFirst = conversationOrder.indexOfSelectedItem == 1
    }

    @objc func listPicturesChanged() {
        AppDelegate.shared?.listPictures = listPictures.state == .on
    }

    @objc func checkUpdatesChanged() {
        AppDelegate.shared?.updater?.automaticallyChecksForUpdates = checkUpdates.state == .on
    }

    @objc func picturesChanged() {
        core.alwaysLoadPictures = pictures.state == .on
        // the message shown now as the setting has it
        AppDelegate.shared?.main?.mailbox.reader.reload()
    }

    @objc func searchEncryptedChanged() {
        // the lists reload when the core says the folders changed
        core.searchEncrypted = searchEncrypted.state == .on
    }

    @objc func keyserverChanged() {
        core.keyserver = keyserver.state == .on
    }

    @objc func showPreviewsChanged() {
        core.showPreviews = showPreviews.state == .on
        updateDependents()
        // the messages shown now made again as the setting has it
        AppDelegate.shared?.main?.reloadMessagesShown()
    }

    @objc func pdfPreviewsChanged() {
        core.pdfPreviews = pdfPreviews.state == .on
        AppDelegate.shared?.main?.reloadMessagesShown()
    }

    /// the PDF row as the core has it now (turned off after a PDF file ended the app)
    func refreshPreviews() {
        pdfPreviews.state = core.pdfPreviews ? .on : .off
    }

    @objc func darkMessagesChanged() {
        core.darkMessages = darkMessages.state == .on
        Preview.dark = core.darkMessages
        // the messages shown now made again as the setting has it
        AppDelegate.shared?.main?.reloadMessagesShown()
    }

    @objc func downloadAheadChosen() {
        // the items are in the order of PeDownloadAhead
        core.downloadAhead = PeDownloadAhead(rawValue: UInt32(max(downloadAhead.indexOfSelectedItem, 0)))
    }

    @objc func sendDelayChosen() {
        core.sendDelayIndex = sendDelay.indexOfSelectedItem
    }

    @objc func downloadLimitChosen() {
        core.downloadLimitIndex = downloadLimit.indexOfSelectedItem
    }

    @objc func trustedSendersClicked() {
        TrustedSendersSheet(core: core).run(on: window)
    }

    /// Make Default Mail App..., as Tools has it
    @objc func defaultAppClicked() {
        AppDelegate.shared?.perform(.defaultApp)
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
        Languages.choose(codes[index])
    }
}

/// A check box whose title wraps at `preferredMaxLayoutWidth`, so a long translation makes it taller, not wider
final class WrappingCheckbox: NSButton {
    var preferredMaxLayoutWidth: CGFloat = 0 {
        didSet { invalidateIntrinsicContentSize() }
    }

    override init(frame: NSRect) {
        super.init(frame: frame)
        setButtonType(.switch)
        cell?.wraps = true
        cell?.lineBreakMode = .byWordWrapping
    }

    required init?(coder: NSCoder) {
        fatalError("not from a nib")
    }

    override var intrinsicContentSize: NSSize {
        let size = super.intrinsicContentSize
        guard preferredMaxLayoutWidth > 0, size.width > preferredMaxLayoutWidth, let cell else { return size }
        let fitted = cell.cellSize(forBounds: NSRect(x: 0, y: 0, width: preferredMaxLayoutWidth, height: 10_000))
        return NSSize(width: preferredMaxLayoutWidth, height: ceil(fitted.height))
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
