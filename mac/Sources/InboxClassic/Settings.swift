// The language of the windows and the Settings window (Inbox Classic > Settings, Cmd+,). Every word comes from the
// core's catalogs (Generated/Texts.swift); the language is set once at start, before any window reads a word, and a
// language chosen here takes effect when the app starts again. It is kept as the app's own AppleLanguages, so the
// system's per-app language setting (System Settings > General > Language & Region > Applications) is the same choice.
import AppKit
import CInboxClassic

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

/// Inbox Classic > Settings: the language of the windows, Notify of New Mail and Group messages by conversation. As Mac settings windows do, a
/// change counts at once; a language counts once the app starts again, which it offers to do.
@MainActor
final class SettingsWindow: NSObject, NSWindowDelegate {
    private static var shown: SettingsWindow?
    let window: NSWindow
    let language = NSPopUpButton()
    let notify: NSButton
    let grouping: NSButton
    let signInCodes: NSButton
    /// the codes of the popup's items, nil for System default
    private var codes: [String?] = []

    static func open(core: Core) {
        if let shown {
            shown.window.makeKeyAndOrderFront(nil)
            return
        }
        let settings = SettingsWindow()
        shown = settings
        settings.window.center()
        settings.window.makeKeyAndOrderFront(nil)
    }

    /// the open window, for the UI test
    static var current: SettingsWindow? { shown }

    private override init() {
        window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 440, height: 160), styleMask: [.titled, .closable],
                          backing: .buffered, defer: false)
        window.autorecalculatesKeyViewLoop = true
        notify = NSButton(checkboxWithTitle: Text.macNotifyNewMail.text, target: nil, action: nil)
        grouping = NSButton(checkboxWithTitle: Text.uiGroupByConversation.text, target: nil, action: nil)
        signInCodes = NSButton(checkboxWithTitle: Text.uiCodesInNotifications.text, target: nil, action: nil)
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

        let label = NSTextField(labelWithString: Text.macLanguageLabel.text)
        label.alignment = .right
        let grid = NSGridView(views: [
            [label, language],
            [NSGridCell.emptyContentView, hint],
            [NSGridCell.emptyContentView, notify],
            [NSGridCell.emptyContentView, indented],
            [NSGridCell.emptyContentView, grouping],
        ])
        grid.rowSpacing = 8
        grid.columnSpacing = 8
        grid.column(at: 0).xPlacement = .trailing
        grid.row(at: 2).topPadding = 8
        grid.translatesAutoresizingMaskIntoConstraints = false
        let content = NSView()
        content.addSubview(grid)
        NSLayoutConstraint.activate([
            grid.topAnchor.constraint(equalTo: content.topAnchor, constant: 20),
            grid.leadingAnchor.constraint(equalTo: content.leadingAnchor, constant: 20),
            grid.trailingAnchor.constraint(lessThanOrEqualTo: content.trailingAnchor, constant: -20),
            grid.bottomAnchor.constraint(equalTo: content.bottomAnchor, constant: -20),
            hint.widthAnchor.constraint(lessThanOrEqualToConstant: 320),
        ])
        window.contentView = content
        window.setContentSize(content.fittingSize)
    }

    func windowWillClose(_ notification: Notification) {
        SettingsWindow.shown = nil
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
