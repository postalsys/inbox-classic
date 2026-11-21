// The UI end-to-end test's step of settings and accounts to another computer (45a of scripts/ui-e2e/SCENARIO.md, and
// its first-run part in step 1): the link of Add Mail Account before the first account, File > Export Settings and
// Accounts with a passphrase refused and then taken, and File > Import Settings and Accounts on that file, its
// passphrase refused and then taken, what it holds shown, Contacts alone imported.
import AppKit
import CInboxClassic

extension UITest {
    /// Before the first account, Add Mail Account offers the import; its push button opens the file panel, cancelled
    /// here, and the form comes back: the form shown now
    func firstRunImport(_ start: NSWindow) async throws -> NSWindow {
        let link: NSButton? = find("account.import", in: start)
        check(link?.title.hasPrefix(Text.uiSetupFirstRun.title) == true,
              "before the first account, Add Mail Account offers to import settings and accounts (\(link?.title ?? ""))")
        check(link?.isBordered == true && link?.bezelStyle == .push, "the import is a push button")
        await shot(start, "setup-5-first-run")
        var asked: String?
        TestHooks.open = { title in
            asked = title
            return []
        }
        press(link)
        _ = await waitUntil(10) { asked != nil }
        TestHooks.open = nil
        check(asked == Text.uiSetupImportTitle.text, "the button opens the import's file panel (\(asked ?? "none"))")
        guard let again = await waitFor(10, { window("account.start").flatMap { $0 === start ? nil : $0 } }) else {
            throw Failed(description: "no account form after the import was cancelled")
        }
        check(true, "cancelled, the form is back")
        return again
    }

    /// the words of a window's views with these ids
    func words(_ id: String, in window: NSWindow?) -> String {
        (find(id, in: window) as NSTextField?)?.stringValue ?? ""
    }

    func setupFile() async throws {
        step("settings and accounts to another computer")
        let core = main.core
        let accountsBefore = core.accounts().map(\.id)
        let file = out.appendingPathComponent("setup.inboxclassic")
        try? FileManager.default.removeItem(at: file)
        // someone of the address book, who is deleted after the export and comes back with the import
        let address = "setup.person@example.com"
        guard case .success(let card) = core.saveBookCard(BookCard(name: "Sam Setup", addresses: [address])) else {
            throw Failed(description: "no contact saved")
        }

        // Export: every part chosen, the passphrase off with what it adds
        var savedName: String?
        TestHooks.save = { name in
            savedName = name
            return file
        }
        command(.exportSetup)
        guard let export = await waitWindow("setup.export", 10) else { throw Failed(description: "no export window") }
        let flags = SetupCalls.parts.map(\.part)
        let boxes: [NSButton] = flags.compactMap { find("setup.part.\($0)", in: export) }
        check(boxes.count == 8 && flags.count == 8 && boxes.allSatisfy { $0.state == .on },
              "File > Export Settings and Accounts lists the parts, all chosen (\(boxes.map(\.title)))")
        let use: NSButton? = find("setup.passphrase.use", in: export)
        let field = { (index: Int) -> NSSecureTextField? in self.find("setup.passphrase.field.\(index)", in: export) }
        let ok: NSButton? = find("setup.export.ok", in: export)
        check(use?.state == .off && field(0)?.isEnabled == false && ok?.isEnabled == true,
              "the passphrase is off, its fields greyed, Export can be used")
        check(words("setup.passphrase.note", in: export).contains("passwords"),
              "the note says what a passphrase adds (\(words("setup.passphrase.note", in: export)))")
        await shot(export, "setup-1-export")

        // a short passphrase, then two that differ, are refused in the window, Export greyed
        press(use)
        _ = await waitUntil(5) { field(0)?.isEnabled == true }
        type("short", into: field(0))
        let early = words("setup.passphrase.problem", in: export)
        check(early.contains(Text.uiKeysPassphraseShort.text) && ok?.isEnabled == false, "a short one is said to be short at once (\(early))")
        type("short", into: field(1))
        let short = words("setup.passphrase.problem", in: export)
        check(short.contains(Text.uiKeysPassphraseShort.text) && ok?.isEnabled == false, "a short passphrase is refused (\(short))")
        type("correct horse battery", into: field(0))
        type("correct horse batter", into: field(1))
        check(words("setup.passphrase.problem", in: export).isEmpty && ok?.isEnabled == false,
              "the second, still being typed, is not refused yet, Export stays greyed")
        type("correct horse batteries", into: field(1))
        let differ = words("setup.passphrase.problem", in: export)
        check(differ.contains(Text.uiKeysPassphraseDiffer.text) && ok?.isEnabled == false, "two different ones are refused (\(differ))")
        await shot(export, "setup-2-passphrase")
        type("correct horse battery", into: field(1))
        check(words("setup.passphrase.problem", in: export).isEmpty && ok?.isEnabled == true,
              "the same twice is taken, Export can be used")
        checkTabs(export, ["setup.passphrase.field.0", "setup.passphrase.field.1"], "Tab goes from the passphrase to the second")
        press(ok)
        guard let written = await waitWindow("setup.done", 20) else { throw Failed(description: "no export summary") }
        let summary = views(NSTextField.self, in: written.contentView).map(\.stringValue)
        check(summary.contains { $0.hasPrefix("Accounts: \(accountsBefore.count) accounts") } && summary.contains { $0.hasPrefix("Contacts and groups:") },
              "the summary says what the file holds (\(summary))")
        press(find("setup.done.ok", in: written))
        _ = await waitUntil(5) { !written.isVisible }
        TestHooks.save = nil
        let defaultName = taken(pe_setup_default_name()) ?? ""
        check(savedName == defaultName && defaultName.hasSuffix(".inboxclassic"),
              "the save panel starts with the core's name for it (\(savedName ?? ""))")
        let head = String(decoding: (try? Data(contentsOf: file))?.prefix(40) ?? Data(), as: UTF8.self)
        check(head.hasPrefix("-----BEGIN PGP MESSAGE-----"), "the file is written encrypted, an OpenPGP message")

        // the contact deleted
        _ = [card].withUnsafeBufferPointer { pe_book_delete(core.handle, 0, $0.baseAddress, 1, nil, 0) }
        check(!core.bookCards().contains { $0.address == address }, "a contact is deleted before the import")

        // Import: the passphrase asked, a wrong one refused
        TestHooks.open = { _ in [file] }
        command(.importSetup)
        guard let ask = await waitWindow("setup.passphrase", 10) else { throw Failed(description: "no passphrase asked") }
        check(true, "File > Import Settings and Accounts asks for the file's passphrase")
        type("wrong horse battery", into: find("setup.passphrase.field.0", in: ask))
        press(find("setup.passphrase.ok", in: ask))
        // tried off the window thread, the window waiting, then saying why it stays
        _ = await waitUntil(20) { !self.words("setup.passphrase.problem", in: ask).isEmpty }
        let wrong = words("setup.passphrase.problem", in: ask)
        let askField: NSSecureTextField? = find("setup.passphrase.field.0", in: ask)
        check(wrong.contains(Text.setupErrorWrongPassphrase.text) && ask.isVisible && askField?.isEnabled == true
              && askField?.stringValue.isEmpty == true,
              "a wrong one is refused in the window, which asks again (\(wrong))")
        type("correct horse battery", into: askField)
        press(find("setup.passphrase.ok", in: ask))
        TestHooks.open = nil

        // what it holds
        guard let choose = await waitWindow("setup.import", 10) else { throw Failed(description: "no import window") }
        _ = await waitUntil(5) { choose.isKeyWindow }
        let from = words("setup.import.from", in: choose)
        check(from.hasPrefix("Saved by Inbox Classic \(Core.version) on "), "it says when and by which version it was saved (\(from))")
        let parts: [NSButton] = flags.compactMap { find("setup.part.\($0)", in: choose) }
        let accountsPart: NSButton? = find("setup.part.\(UInt32(PE_SETUP_ACCOUNTS))", in: choose)
        let others = parts.filter { $0 !== accountsPart }
        check(others.count >= 5 && others.allSatisfy { $0.state == .on && $0.isEnabled },
              "the parts it holds are listed and chosen (\(parts.map(\.title)))")
        check(find("setup.part.\(UInt32(PE_SETUP_RULES))", in: choose) as NSButton? == nil,
              "a part with nothing in it is not offered (Message rules: none)")
        check(accountsPart?.state == .off && accountsPart?.isEnabled == false,
              "with no account to import, Accounts is unticked and greyed")
        let contacts = words("setup.holds.\(UInt32(PE_SETUP_CONTACTS))", in: choose)
        let keys = words("setup.holds.\(UInt32(PE_SETUP_KEYS))", in: choose)
        check(contacts.contains("contact") && keys.contains("key"), "with what each holds (\(contacts); \(keys))")
        let accountBoxes: [NSButton] = (0..<accountsBefore.count).compactMap { find("setup.account.\($0)", in: choose) }
        let notes = (0..<accountsBefore.count).map { words("setup.account.\($0).note", in: choose) }
        let servers = (0..<accountsBefore.count).map { words("setup.account.\($0).servers", in: choose) }
        check(accountBoxes.allSatisfy { $0.title.contains("<testuser") } && servers.allSatisfy { $0.contains("127.0.0.1") },
              "each account shows its title and address and the core's line of its servers (\(servers))")
        check(accountBoxes.count == accountsBefore.count && accountBoxes.count > 1 && accountBoxes.allSatisfy { $0.state == .off && !$0.isEnabled }
              && notes.allSatisfy { $0.contains("already") },
              "the accounts are listed, unchecked and off as already here (\(accountBoxes.map(\.title)), \(notes))")
        await shot(choose, "setup-3-import-choose")

        // Contacts alone
        for part in others where part.accessibilityIdentifier() != "setup.part.\(UInt32(PE_SETUP_CONTACTS))" {
            press(part)
        }
        _ = await waitUntil(5) { parts.filter { $0.state == .on }.count == 1 }
        press(find("setup.import.ok", in: choose))
        guard let imported = await waitWindow("setup.done", 20) else { throw Failed(description: "no import summary") }
        let lines = views(NSTextField.self, in: imported.contentView).map(\.stringValue)
        check(lines.contains { $0.contains("contact") }, "the summary says what was added and skipped (\(lines))")
        await shot(imported, "setup-4-imported")
        press(find("setup.done.ok", in: imported))
        _ = await waitUntil(5) { !imported.isVisible }
        check(core.bookCards().contains { $0.address == address }, "the contact deleted before is back")
        check(core.accounts().map(\.id) == accountsBefore, "the accounts are left as they are")
    }
}
