// The Mac UI test of Settings and the language (step 46 of scripts/ui-e2e/SCENARIO.md): the Language popup and the
// question to start again, then the windows in German and in the pseudo-language (qps, English made longer and
// bracketed), where every word the app shows has to come from the catalogs and fit its control. The app can not start
// again inside the test, so the language is set and the menus and the main window are made again, as a start does.
import AppKit
import CInboxClassic

extension UITest {
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
        check(Array(titles.dropFirst()) == ["English", "Deutsch", "Eesti", "Español", "Français"],
              "then the languages by their own names (\(titles.dropFirst().joined(separator: ", ")))")
        check(shown.notify.title == "Notify me when new mail arrives", "Notify of New Mail is there too")
        onMain { self.choose(popup, 2) }
        let question = await waitWindow("alert", 10)
        check(alertText(question).contains("Restart Inbox Classic now to change the language?"),
              "choosing Deutsch asks to start again (\(alertText(question)))")
        let buttons = views(NSButton.self, in: question?.contentView).map(\.title)
        check(buttons.contains("Restart Now") && buttons.contains("Later"), "with Restart Now and Later")
        answer(question, "Later")
        _ = await waitUntil { !(question?.isVisible ?? false) }
        await pause(0.3)
        await shot(settings, "options-1-language")
        settings.close()

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

        step("back in English")
        await startIn("en")
        check(main.window.toolbar?.items.contains { $0.label == "Reply" } == true, "the windows are in English again")
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
