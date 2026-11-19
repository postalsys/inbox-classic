// The Mac UI test of Settings and the language (step 46 of scripts/ui-e2e/SCENARIO.md): the Language popup and the
// question to start again, then the windows in German and in the pseudo-language (qps, English made longer and
// bracketed), where every word the app shows has to come from the catalogs and fit its control. The app can not start
// again inside the test, so the language is set and the menus and the main window are made again, as a start does.
import AppKit
import CInboxClassic

extension UITest {
    /// Settings > Reading > Encryption: its two switches, on at first, each with its note; each turned off counts at once
    /// (the window is then closed and opened again, where they are still off)
    func encryptionSettings(_ shown: SettingsWindow) async throws {
        let labelled = views(NSTextField.self, in: shown.window.contentView).map(\.stringValue)
        check(labelled.contains("Encryption:"), "Reading has the Encryption group, its title in the label column")
        check(shown.searchEncrypted.title == "Search in encrypted messages" && shown.keyserver.title == "Look up keys on keys.openpgp.org",
              "with Search in encrypted messages and Look up keys on keys.openpgp.org (\(shown.searchEncrypted.title), \(shown.keyserver.title))")
        check(shown.searchEncrypted.state == .on && shown.keyserver.state == .on, "both on at first")
        check(labelled.contains { $0.contains("The index is not encrypted, and AI agents never search it") }
              && labelled.contains { $0.contains("the address looked up is sent to keys.openpgp.org") },
              "each with its note: the index is not encrypted and agents never search it; only the address is sent")
        let below = { (view: NSView) in view.convert(view.bounds, to: nil).minY }
        check(below(shown.keyserver) < below(shown.searchEncrypted) && below(shown.searchEncrypted) < below(shown.pictures),
              "after Messages, in the order of settings.toml")
        await shot(shown.window, "options-4-encryption")
        onMain {
            shown.searchEncrypted.performClick(nil)
            shown.keyserver.performClick(nil)
        }
        check(await waitUntil(5) { !main.core.searchEncrypted && !main.core.keyserver }, "each turned off counts at once")
    }

    func languages() async throws {
        step("Settings and the language")
        command(.options)
        guard let settings = await waitWindow("settings", 10), let shown = SettingsWindow.current else {
            check(false, "Inbox Classic > Settings opens")
            return
        }
        let popup = shown.language
        let titles = popup.itemTitles
        let system = Text.uiOptionsSystemDefault.text(["language": Languages.name(Languages.system)])
        check(titles.first == system, "Language starts with System default and the language it is now (\(titles.first ?? ""))")
        // every language of pe_i18n::LANGUAGES, English first
        let names = Languages.all.map(\.name)
        check(Array(titles.dropFirst()) == names && names.first == "English" && names.contains("Deutsch"),
              "then the languages by their own names (\(titles.dropFirst().joined(separator: ", ")))")
        check(shown.notify.title == "Notify me when new mail arrives", "Notify of New Mail is there too")
        let panes = settings.toolbar?.items.map(\.label) ?? []
        check(panes == ["General", "Reading", "Downloading"], "the toolbar has the panes General, Reading and Downloading (\(panes))")
        // the pane chosen last is the dark messages step's Reading
        check(shown.pane == .reading && settings.title == "Reading", "it opens on the pane chosen last, titled by it (\(settings.title))")
        await showPane(shown, .general)
        check(settings.title == "General", "General titles the window General (\(settings.title))")
        check(shown.checkUpdates.title == "Check for updates automatically" && !shown.checkUpdates.isEnabled,
              "General has Check for updates automatically, disabled in a build without updates")
        let deutsch = titles.firstIndex(of: "Deutsch") ?? 2
        onMain { self.choose(popup, deutsch) }
        let question = await waitWindow("alert", 10)
        check(alertText(question).contains("Inbox Classic shows Deutsch once it restarts. Restart now?"),
              "choosing Deutsch asks to start again (\(alertText(question)))")
        let buttons = views(NSButton.self, in: question?.contentView).map(\.title)
        check(buttons.contains("Restart Now") && buttons.contains("Later"), "with Restart Now and Later")
        answer(question, "Later")
        _ = await waitUntil { !(question?.isVisible ?? false) }
        await pause(0.3)
        await shot(settings, "options-1-language")
        await showPane(shown, .reading)
        check(settings.title == "Reading", "the Reading pane titles the window Reading (\(settings.title))")
        await shot(settings, "options-2-reading")
        try await encryptionSettings(shown)
        settings.close()
        _ = await waitUntil { SettingsWindow.current == nil }
        command(.options)
        if let again = await waitFor(10, { SettingsWindow.current }) {
            check(again.pane == .reading && again.window.title == "Reading", "closed on Reading and opened again, it opens on Reading")
            check(again.searchEncrypted.state == .off && again.keyserver.state == .off && !main.core.searchEncrypted
                  && !main.core.keyserver, "Search in encrypted messages and Look up keys turned off stay off")
            onMain {
                again.searchEncrypted.performClick(nil)
                again.keyserver.performClick(nil)
            }
            check(await waitUntil(5) { main.core.searchEncrypted && main.core.keyserver }, "and on again")
            await showPane(again, .general)
            again.window.close()
        } else {
            check(false, "Settings opens again")
        }

        step("the windows in German")
        await startIn("de")
        let menus = NSApp.mainMenu?.items.map(\.title) ?? []
        check(menus.contains("Datei") && menus.contains("Bearbeiten") && menus.contains("Nachricht"),
              "the menus are in German (\(menus.joined(separator: ", ")))")
        let labels = main.window.toolbar?.items.map(\.label) ?? []
        check(labels.contains("Antworten") && labels.contains("Weiterleiten"),
              "the toolbar is in German (\(labels.joined(separator: ", ")))")
        let counts: NSTextField? = find("status.counts", in: main.window)
        check(counts?.stringValue.contains("ungelesen") == true, "the status bar is in German (\(counts?.stringValue ?? ""))")
        let said: NSTextField? = find("status.text", in: main.window)
        check(said?.stringValue.isEmpty == false, "the status bar says something from the start (\(said?.stringValue ?? ""))")
        check(folder(ofAccount: 0, named: "Posteingang") != 0 && folder(ofAccount: 0, named: "Archiv") != 0,
              "the special folders are in German, Archive among them")
        await shot(main.window, "lang-1-german")
        try await agentsInLanguage("de")
        // the sign-in buttons say it in the language, French's words the longest
        for (language, name) in [("de", "lang-1b-german-form"), ("fr", "lang-1c-french-form")] {
            if language != "de" { await startIn(language) }
            command(.newAccount)
            if let form = await waitWindow("account.start", 10) {
                await pause(0.5)
                await shot(form, name)
                NSApp.stopModal()
                _ = await waitUntil { !form.isVisible }
            } else {
                check(false, "File > New Account opens the form in \(language)")
            }
        }

        step("the windows in the pseudo-language")
        await startIn("qps")
        await shot(main.window, "lang-2-pseudo-main")
        checkCatalogWords(in: main.window, "the main window")
        checkMenus()
        command(.newMail)
        if let compose = await waitFor(10, { ComposeWindow.open.last?.window }) {
            await pause(1)
            checkCatalogWords(in: compose, "the compose window")
            await closeCompose(compose)
        } else {
            check(false, "a new message opens")
        }
        command(.newAccount)
        if let form = await waitWindow("account.start", 10) {
            await shot(form, "lang-3-pseudo-form")
            checkCatalogWords(in: form, "the account form")
            NSApp.stopModal()
            _ = await waitUntil { !form.isVisible }
        } else {
            check(false, "File > New Account opens the form")
        }
        command(.options)
        if let options = await waitFor(10, { SettingsWindow.current }) {
            for (page, name) in [(SettingsPage.general, "lang-4-pseudo-options"), (.reading, "lang-4b-pseudo-options-reading"),
                                 (.downloading, "lang-4c-pseudo-options-downloading")] {
                await showPane(options, page)
                await shot(options.window, name)
                checkCatalogWords(in: options.window, "Settings, \(page.rawValue)")
                let width = options.window.contentView?.frame.width ?? 0
                check(width == 520, "and its long words wrap, the \(page.rawValue) pane no wider than 520 points (\(Int(width)))")
            }
            await showPane(options, .general)
            options.window.close()
        } else {
            check(false, "Settings opens")
        }
        try await agentsInLanguage("qps")
        command(.exportSetup)
        if let export = await waitWindow("setup.export", 10) {
            checkCatalogWords(in: export, "the Export Settings and Accounts window")
            press(find("setup.cancel", in: export))
            _ = await waitUntil { !export.isVisible }
        } else {
            check(false, "File > Export Settings and Accounts opens")
        }
        command(.encryptionKeys)
        if let keys = await waitWindow("keys", 10) {
            checkCatalogWords(in: keys, "the Encryption Keys window")
            press(find("keys.close", in: keys))
            _ = await waitUntil { !keys.isVisible }
        } else {
            check(false, "Tools > Encryption Keys opens")
        }

        step("back in English")
        await startIn("en")
        check(main.window.toolbar?.items.contains { $0.label == "Reply" } == true, "the windows are in English again")
    }

    /// the AI Agents window and the question for programs started from a terminal in `language`: the log's rows,
    /// written in English, in the language now; the question's words in full
    private func agentsInLanguage(_ language: String) async throws {
        command(.aiAgents)
        if let agents = await waitWindow("agents", 10) {
            let log: NSTableView? = find("agents.log", in: agents)
            let rows = (0..<(log?.numberOfRows ?? 0)).map {
                (log?.view(atColumn: 2, row: $0, makeIfNecessary: true) as? NSTableCellView)?.textField?.stringValue ?? ""
            }
            if language == "de" {
                check(rows.contains { $0.hasPrefix("Sie haben folgende Mailinglisten nicht abbestellt:") }
                      && rows.contains { $0.contains("gelesen") },
                      "the AI Agents log shows what agents did and read in German, the rows written before too (\(rows))")
            } else {
                check(!rows.isEmpty && rows.allSatisfy { $0.contains("[") }, "the AI Agents log is in the pseudo-language (\(rows))")
                checkCatalogWords(in: agents, "the AI Agents window")
            }
            try await undoSinceInLanguage(agents, language)
            NSApp.stopModal()
            _ = await waitUntil { !agents.isVisible }
        } else {
            check(false, "Tools > AI Agents opens")
        }
        let ask = try await terminalAgentAsks()
        check(ask != nil, "an agent started from a terminal is asked about")
        guard let ask else { return }
        let heading = (find("agent.heading", in: ask) as NSTextField?)?.stringValue ?? ""
        if language == "de" {
            check(heading == "Aus Terminal gestartete Programme möchten auf Ihre E-Mails zugreifen", "the question in German (\(heading))")
        } else {
            checkCatalogWords(in: ask, "the question for programs started from a terminal")
        }
        checkQuestionFits(ask, "the question for programs started from a terminal in \(language)")
        await pause(0.5)
        await shot(ask, language == "de" ? "agents-10b-terminal-german" : "agents-10c-terminal-pseudo")
        press(find("agent.deny", in: ask))
        _ = await waitUntil(10) { !ask.isVisible }
        forgetTerminal()
    }

    /// Undo Since's question in `language`, its words in full
    private func undoSinceInLanguage(_ agents: NSWindow, _ language: String) async throws {
        let hosts: NSTableView? = find("agents.hosts", in: agents)
        let program = (0..<(hosts?.numberOfRows ?? 0)).first {
            (hosts?.view(atColumn: 0, row: $0, makeIfNecessary: true) as? NSTableCellView)?.textField?.stringValue == "My AI agent"
        }
        hosts?.selectRowIndexes([program ?? 0], byExtendingSelection: false)
        press(find("agents.undoSince", in: agents))
        guard let ask = await waitWindow("agents.undoSinceWindow", 10) else {
            check(false, "Undo Since asks first in \(language)")
            return
        }
        // the longest span, whose question may count changes
        choose(find("undoSince.span", in: ask), 5)
        if language == "de" {
            let words = views(NSTextField.self, in: ask.contentView).map(\.stringValue)
            check(words.contains("Rückgängig machen, was dieses Programm getan hat:"), "Undo Since in German (\(words))")
        } else {
            checkCatalogWords(in: ask, "Undo Since")
        }
        checkQuestionFits(ask, "Undo Since in \(language)")
        await pause(0.5)
        await shot(ask, language == "de" ? "agents-12b-undo-since-german" : "agents-12c-undo-since-pseudo")
        press(find("undoSince.cancel", in: ask))
        _ = await waitUntil { !ask.isVisible }
    }

    /// `page` of Settings shown, as its toolbar item shows it
    func showPane(_ settings: SettingsWindow, _ page: SettingsPage) async {
        onMain { settings.select(page) }
        _ = await waitUntil(5) { settings.pane == page && settings.window.title == page.label.text }
        await pause(0.5)
    }

    /// the language set and the windows made again in it, the Inbox and its first message shown
    private func startIn(_ language: String) async {
        Languages.apply(language)
        delegate?.remakeWindows()
        main.window.setContentSize(NSSize(width: 1100, height: 720))
        main.window.center()
        _ = await waitUntil { tree.numberOfRows >= 7 }
        main.mailbox.view.layoutSubtreeIfNeeded()
        main.mailbox.placeDividers()
        selectFolder(named: Text.folderInbox.text)
        _ = await waitUntil { list.numberOfRows >= 3 }
        await selectRow(0)
        await pause(1)
    }

    /// what a window shows of its own: the words of its labels, buttons, placeholders, column headers and toolbar, not
    /// the mail in its lists, fields and reading pane
    private func ownWords(in root: NSView?) -> [(String, NSView?)] {
        guard let root, !root.isHidden else { return [] }
        if root is NSTableView || root is NSOutlineView {
            let table = root as! NSTableView
            // the column headers, when the table shows them
            return table.headerView == nil ? [] : table.tableColumns.filter { !$0.isHidden }.map { ($0.title, nil) }
        }
        var words: [(String, NSView?)] = []
        if let field = root as? NSTextField {
            if field.isEditable {
                words.append((field.placeholderString ?? "", nil))
            } else {
                words.append((field.stringValue, field))
            }
        } else if let popup = root as? NSPopUpButton {
            // what is chosen in a popup is the user's (an account, a font), its pull-down title the app's
            if popup.pullsDown {
                words.append((popup.itemTitles.first ?? "", nil))
            }
        } else if let button = root as? NSButton {
            words.append((button.title, button))
            // a picture's button says what it does to VoiceOver
            if button.title.isEmpty {
                words.append(((button.accessibilityLabel() ?? "") + " <\(button.className) \(button.accessibilityIdentifier())>", nil))
            }
        } else if root is NSSearchField {
            words.append(((root as! NSSearchField).placeholderString ?? "", nil))
        }
        if root is NSSearchField {
            return words
        }
        for child in root.subviews {
            words += ownWords(in: child)
        }
        return words
    }

    /// the kind and the id of a view, after a word of it that is left in English
    private func diagnose(_ view: NSView) -> String {
        " <\(view.className) \(view.accessibilityIdentifier())>"
    }

    /// a word left in English: letters, but not from the pseudo-language's brackets
    private func english(_ text: String) -> Bool {
        text.range(of: "[A-Za-z]", options: .regularExpression) != nil && !text.contains("[")
    }

    /// every word of the window from the catalogs, and every label and button wide enough for its words
    private func checkCatalogWords(in window: NSWindow, _ name: String) {
        var words = ownWords(in: window.contentView)
        words.append((window.title, nil))
        for item in window.toolbar?.items ?? [] {
            words.append((item.label, nil))
            words.append((item.toolTip ?? "", nil))
            if let search = item.view as? NSSearchField {
                words.append((search.placeholderString ?? "", nil))
            }
        }
        // e-mail addresses and the like are examples, not words
        let left = Set(words.filter { english($0.0) && !$0.0.contains("@") }.map { $0.0 + ($0.1.map(diagnose) ?? "") })
        check(left.isEmpty, "nothing in \(name) is left in English\(left.isEmpty ? "" : ": " + left.sorted().joined(separator: " | "))")
        var cut: [String] = []
        for case let (text, view?) in words where !text.isEmpty {
            guard !view.isHiddenOrHasHiddenAncestor, view.bounds.width > 0 else { continue }
            if let field = view as? NSTextField, field.cell?.wraps == true || field.maximumNumberOfLines != 1 { continue }
            if let button = view as? NSButton, button.imagePosition == .imageOnly { continue }
            if view.intrinsicContentSize.width > view.bounds.width + 1 {
                cut.append("\(text) (\(Int(view.intrinsicContentSize.width)) > \(Int(view.bounds.width)))")
            }
        }
        check(cut.isEmpty, "and nothing in \(name) is cut off\(cut.isEmpty ? "" : ": " + cut.joined(separator: " | "))")
    }

    /// every item of the menus the app makes from the catalogs; the ones AppKit adds are in the system's language
    private func checkMenus() {
        let system: Set<String> = ["toggleFullScreen:", "startDictation:", "orderFrontCharacterPalette:", "arrangeInFront:",
                                   "makeKeyAndOrderFront:", "showWritingTools:"]
        var left: [String] = []
        func walk(_ menu: NSMenu?) {
            for item in menu?.items ?? [] where !item.isSeparatorItem && !item.isHidden {
                let action = item.action.map(NSStringFromSelector) ?? ""
                // AppKit's own: an Option alternate (Close All), Writing Tools and AutoFill
                if item.submenu === NSApp.servicesMenu || system.contains(action) || item.isAlternate || action.hasPrefix("_")
                    || item.identifier?.rawValue.hasPrefix("_") == true {
                    continue
                }
                if english(item.title) && item.title != appName {
                    left.append("\(item.title) <\(item.action.map(NSStringFromSelector) ?? "") \(item.identifier?.rawValue ?? "") \(item.isAlternate)>")
                }
                walk(item.submenu)
            }
        }
        walk(NSApp.mainMenu)
        check(left.isEmpty, "nothing in the menus is left in English\(left.isEmpty ? "" : ": " + left.joined(separator: " | "))")
    }
}
