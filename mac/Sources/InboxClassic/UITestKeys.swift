// The UI end-to-end test's step of encryption keys (19h of scripts/ui-e2e/SCENARIO.md): Tools > Encryption Keys empty,
// a key made with its backup, keys imported (a public one, a private one behind a passphrase), Key Properties, Verify
// Key, Export, Account Properties > Security, the key in a contact's Properties, and Remove.
import AppKit
import CInboxClassic

extension UITest {
    /// the words of a cell of the Encryption Keys list
    func keyCell(_ table: NSTableView?, _ row: Int, _ column: Int) -> String {
        guard let table, row < table.numberOfRows else { return "" }
        let cell = table.view(atColumn: column, row: row, makeIfNecessary: true) as? NSTableCellView
        return cell?.textField?.stringValue ?? ""
    }

    /// the row of the list whose name is `name`
    func keyRow(_ table: NSTableView?, _ name: String) -> Int? {
        guard let table else { return nil }
        return (0..<table.numberOfRows).first { keyCell(table, $0, 0) == name }
    }

    func selectKey(_ table: NSTableView?, _ name: String) {
        guard let table, let row = keyRow(table, name) else { return }
        table.selectRowIndexes(IndexSet(integer: row), byExtendingSelection: false)
    }

    func openKeys() async throws -> (NSWindow, NSTableView?) {
        command(.encryptionKeys)
        guard let keys = await waitWindow("keys", 10) else { throw Failed(description: "no Encryption Keys window") }
        return (keys, find("keys.list", in: keys))
    }

    func closeKeys(_ keys: NSWindow) async {
        press(find("keys.close", in: keys))
        _ = await waitUntil(10) { !keys.isVisible }
    }

    /// two passphrases typed into Back Up Key and OK pressed
    func typeBackup(_ backup: NSWindow, _ first: String, _ second: String) {
        type(first, into: find("key.backup.field.0", in: backup))
        type(second, into: find("key.backup.field.1", in: backup))
    }

    func encryptionKeys() async throws {
        step("encryption keys")
        let core = main.core
        guard let account = await waitFor(20, { core.accounts().first }) else { throw Failed(description: "no account") }
        let bobFile = repo.appendingPathComponent("scripts/ui-e2e/keys/bob.pub.asc")
        let carolFile = repo.appendingPathComponent("scripts/ui-e2e/keys/carol.sec.asc")

        // empty, the buttons of a key greyed
        var (keys, table) = try await openKeys()
        let none: NSTextField? = find("keys.none", in: keys)
        check(table?.numberOfRows == 0 && none?.isHidden == false && none?.stringValue.hasPrefix("No keys yet") == true,
              "Tools > Encryption Keys opens with no keys, saying what to do")
        let greyed = ["keys.export", "keys.backup", "keys.verify", "keys.properties", "keys.remove"].filter {
            (find($0, in: keys) as NSButton?)?.isEnabled != false
        }
        check(greyed.isEmpty && (find("keys.new", in: keys) as NSButton?)?.isEnabled == true
              && (find("keys.import", in: keys) as NSButton?)?.isEnabled == true,
              "New Key and Import can be used, Export, Back Up, Verify, Properties and Remove are greyed (\(greyed))")
        await shot(keys, "keys-1-empty")

        // New Key: the account named, the memory only note; then the backup offered
        press(find("keys.new", in: keys))
        guard let newKey = await waitWindow("key.new", 10) else { throw Failed(description: "no New Key window") }
        let chosen: NSPopUpButton? = find("key.new.account", in: newKey)
        check(chosen?.titleOfSelectedItem == account.label, "New Key names the account it is for (\(chosen?.titleOfSelectedItem ?? ""))")
        let memory: NSTextField? = find("key.new.memory", in: newKey)
        check(memory?.stringValue.contains("memory only") == true, "and says that passwords are kept in memory only")
        await shot(newKey, "keys-2-new-key")
        press(find("key.new.make", in: newKey))
        guard let offer = await waitWindow("alert", 20) else { throw Failed(description: "no backup offer") }
        check(alertText(offer).contains("Save a backup") && views(NSButton.self, in: offer.contentView).map(\.title) == ["Save a Backup…", "Later"],
              "Make Key makes it and offers a backup at once, Save a Backup or Later (\(alertText(offer)))")
        await shot(offer, "keys-3-backup-offer")
        let backupFile = out.appendingPathComponent("keys-backup.asc")
        try? FileManager.default.removeItem(at: backupFile)
        var backupName: String?
        TestHooks.save = { name in
            backupName = name
            return backupFile
        }
        answer(offer, "Save a Backup…")

        // Back Up Key: two passphrases that differ, a short one, then a good one
        guard let backup = await waitWindow("key.backup", 10) else { throw Failed(description: "no Back Up Key window") }
        // refused in the window as they are typed, the core's words under the fields, OK greyed
        let said = { self.words("key.backup.problem", in: backup) }
        let backupOk: NSButton? = find("key.backup.ok", in: backup)
        typeBackup(backup, "correct horse battery", "correct horse batteries")
        check(said().contains("not the same") && backupOk?.isEnabled == false,
              "two different passphrases are refused (\(said()))")
        typeBackup(backup, "short", "short")
        check(said().contains("at least 8") && backupOk?.isEnabled == false, "a short one is refused (\(said()))")
        typeBackup(backup, "correct horse battery", "correct horse battery")
        check(said().isEmpty && backupOk?.isEnabled == true, "the same good one twice can be used")
        await shot(backup, "keys-4-backup")
        press(find("key.backup.ok", in: backup))
        if let saved = await waitWindow("alert", 20) {
            check(alertText(saved).contains("The backup was saved"), "a good one saves the backup (\(alertText(saved)))")
            answer(saved, "OK")
            _ = await waitUntil(5) { !saved.isVisible }
        } else {
            check(false, "the backup is saved")
        }
        TestHooks.save = nil
        check(backupName?.hasSuffix(".asc") == true, "the save panel starts with the core's name for it (\(backupName ?? ""))")
        let backupData = (try? Data(contentsOf: backupFile)) ?? Data()
        check(String(decoding: backupData, as: UTF8.self).contains("BEGIN PGP PRIVATE KEY BLOCK"), "the file is an armored private key")
        check(core.pgpImport(backupData, passphrase: nil).outcome == PE_IMPORT_OUTCOME_NEEDS_PASSPHRASE,
              "which asks for the passphrase")

        // the new key listed: the account's name and address, Your key, Valid
        _ = await waitUntil(5) { table?.numberOfRows == 1 }
        check(table?.numberOfRows == 1 && keyCell(table, 0, 0) == account.name && keyCell(table, 0, 1) == account.email
              && keyCell(table, 0, 2) == "Your key" && keyCell(table, 0, 3) == "Valid",
              "the list shows the new key: \(account.name), \(account.email), Your key, Valid (\((0..<4).map { keyCell(table, 0, $0) }))")
        check((find("keys.backup", in: keys) as NSButton?)?.isEnabled == true && (find("keys.verify", in: keys) as NSButton?)?.isEnabled == false,
              "Back Up applies to it, Verify does not")
        await shot(keys, "keys-5-list")
        let own = core.pgpKeys().first { $0.own }
        check(own != nil && core.pgpIdentities().contains { $0.address == account.email && $0.fingerprint == own?.fingerprint },
              "the account's address uses the new key")

        // Bob's public key: a contact's, Valid, the core's summary shown
        TestHooks.open = { _ in [bobFile] }
        press(find("keys.import", in: keys))
        if let said = await waitWindow("alert", 10) {
            check(!alertText(said).isEmpty, "importing bob.pub.asc says what was imported (\(alertText(said)))")
            answer(said, "OK")
            _ = await waitUntil(5) { !said.isVisible }
        } else {
            check(false, "importing bob.pub.asc says what was imported")
        }
        let bob = await waitFor(5) { keyRow(table, "Bob Example") }
        check(bob.map { keyCell(table, $0, 2) == "Contact" && keyCell(table, $0, 3) == "Valid" } == true,
              "Bob's key is listed as Contact, Valid")

        // Carol's private key: its passphrase asked, a wrong one said, then the address offered
        let addresses = taken(pe_account_addresses(core.handle, account.id)) ?? ""
        _ = "Carol Example <carol@example.org>".withCString { pe_set_account_addresses(core.handle, account.id, $0, nil) }
        TestHooks.open = { _ in [carolFile] }
        press(find("keys.import", in: keys))
        guard let asked = await waitWindow("key.import", 10) else { throw Failed(description: "no passphrase asked") }
        check(alertText(asked).contains("protected by a passphrase"), "importing carol.sec.asc asks for its passphrase")
        await shot(asked, "keys-6-import-passphrase")
        type("wrong horse", into: find("key.import.field.0", in: asked))
        press(find("key.import.ok", in: asked))
        _ = await waitUntil(10) { !asked.isVisible }
        if let again = await waitWindow("key.import", 10) {
            let problem: NSTextField? = find("key.import.problem", in: again)
            check(problem?.isHidden == false && problem?.stringValue.isEmpty == false,
                  "a wrong one says so and asks again (\(problem?.stringValue ?? ""))")
            type("correct horse battery", into: find("key.import.field.0", in: again))
            press(find("key.import.ok", in: again))
        } else {
            check(false, "a wrong passphrase asks again")
        }
        if let said = await waitWindow("alert", 10) {
            check(!alertText(said).isEmpty, "the right one imports it (\(alertText(said)))")
            answer(said, "OK")
            _ = await waitUntil(5) { !said.isVisible }
        }
        if let useFor = await waitWindow("alert", 10), alertText(useFor).contains("Use this key for") {
            check(alertText(useFor).contains("carol@example.org"), "then asks to use it for carol@example.org (\(alertText(useFor)))")
            await shot(useFor, "keys-7-use-for")
            answer(useFor, "Use It")
            _ = await waitUntil(5) { !useFor.isVisible }
        } else {
            check(false, "the import asks to use the key for carol@example.org")
        }
        let carol = core.pgpKeys().first { $0.addresses.contains("carol@example.org") }
        check(carol?.own == true && core.pgpIdentities().contains { $0.address == "carol@example.org" && $0.fingerprint == carol?.fingerprint },
              "Use It makes it the key of carol@example.org")
        _ = addresses.withCString { pe_set_account_addresses(core.handle, account.id, $0, nil) }
        TestHooks.open = nil

        // Bob's Properties
        selectKey(table, "Bob Example")
        guard let bobKey = core.pgpKeys().first(where: { $0.name == "Bob Example" }) else { throw Failed(description: "no key of Bob") }
        press(find("keys.properties", in: keys))
        if let properties = await waitWindow("key.properties", 10) {
            let value = { (id: String) in (self.find("key.properties.\(id)", in: properties) as NSTextField?)?.stringValue ?? "" }
            check(value("names").contains("Bob Example <bob@example.net>") && value("fingerprint").replacingOccurrences(of: "\n", with: " ") == bobKey.grouped
                  && value("fingerprint").split(whereSeparator: \.isWhitespace).allSatisfy { $0.count == 4 }, "Properties names Bob, the fingerprint in groups of four")
            check(value("status") == "Valid" && !value("created").isEmpty && value("expires") == "Never" && value("algorithm") == "Ed25519"
                  && value("source") == "Imported from a file" && value("addresses") == "bob@example.net (not verified)",
                  "Valid, created, expires Never, Ed25519, Imported from a file, bob@example.net (not verified) "
                  + "(\(["status", "created", "expires", "algorithm", "source", "addresses"].map(value)))")
            check((find("key.properties.verify", in: properties) as NSButton?) != nil, "with Verify for a contact's key")
            await shot(properties, "keys-8-properties")
            press(find("key.properties.close", in: properties))
            _ = await waitUntil(5) { !properties.isVisible }
        } else {
            check(false, "Properties opens for Bob's key")
        }

        // Verify Key: They Match marks it
        press(find("keys.verify", in: keys))
        if let verify = await waitWindow("key.verify", 10) {
            let intro: NSTextField? = find("key.verify.intro", in: verify)
            let large: NSTextField? = find("key.verify.fingerprint", in: verify)
            check(intro?.stringValue.contains("Bob Example") == true, "Verify names Bob")
            let marks: NSTextField? = find("key.verify.marks", in: verify)
            check(marks?.stringValue.contains("bob@example.net") == true, "and the addresses They Match marks (\(marks?.stringValue ?? "none"))")
            check(large?.stringValue.replacingOccurrences(of: "\n", with: " ") == bobKey.grouped
                  && (large?.font?.pointSize ?? 0) >= NSFont.systemFontSize * 2, "the fingerprint large, in two lines of groups")
            check(views(NSButton.self, in: verify.contentView).map(\.title).suffix(3) == ["Cancel", "They Differ", "They Match"],
                  "with They Match and They Differ")
            await shot(verify, "keys-9-verify")
            press(find("key.verify.match", in: verify))
            _ = await waitUntil(5) { !verify.isVisible }
        } else {
            check(false, "Verify opens for Bob's key")
        }
        check(await waitUntil(5) { keyRow(table, "Bob Example").map { keyCell(table, $0, 3) } == "Valid, verified" },
              "They Match marks it: the list says Valid, verified")

        // Export: an armored public key under Bob's name
        let exported = out.appendingPathComponent("keys-export.asc")
        try? FileManager.default.removeItem(at: exported)
        var exportName: String?
        TestHooks.save = { name in
            exportName = name
            return exported
        }
        selectKey(table, "Bob Example")
        press(find("keys.export", in: keys))
        check(await waitUntil(10) { (try? String(contentsOf: exported, encoding: .utf8))?.contains("BEGIN PGP PUBLIC KEY BLOCK") == true },
              "Export saves an armored public key")
        check(exportName == "Bob Example public key.asc", "named \"Bob Example public key.asc\" (\(exportName ?? ""))")
        TestHooks.save = nil
        await closeKeys(keys)

        // File > Accounts > Security: the account's key chosen, None and the other own keys offered
        command(.accounts)
        if let accounts = await waitWindow("accounts", 10) {
            press(find("accounts.security", in: accounts))
            if let security = await waitWindow("account.security", 10) {
                let key: NSPopUpButton? = find("account.security.key", in: security)
                let autocrypt: NSButton? = find("account.security.autocrypt", in: security)
                check(key?.titleOfSelectedItem == own?.choice, "Security names the account's key (\(key?.titleOfSelectedItem ?? ""))")
                check(key?.itemTitles.first == "None" && key?.itemTitles.contains(carol?.choice ?? "-") == true,
                      "and offers None and the other own keys (\(key?.itemTitles ?? []))")
                check((find("account.security.new", in: security) as NSButton?) != nil && autocrypt?.state == .on,
                      "New Key, and Send my public key with my messages on")
                await shot(security, "keys-10-account-security")
                press(find("account.security.cancel", in: security))
                _ = await waitUntil(5) { !security.isVisible }
            } else {
                check(false, "Security opens from the Accounts window")
            }
            press(find("accounts.close", in: accounts))
            _ = await waitUntil(10) { !accounts.isVisible }
        }

        // the Address Book's Bob: his key's fingerprint and Valid, verified
        var card = BookCard()
        card.name = "Bob Example"
        card.first = "Bob"
        card.last = "Example"
        card.addresses = ["bob@example.net"]
        let cardId = (try? core.saveBookCard(card).get()) ?? 0
        command(.addressBook)
        if let bookWindow = await waitWindow("addressbook", 10), let book = AddressBookWindow.shown {
            _ = await waitUntil(5) { book.rows.contains { $0.card == cardId } }
            if let row = book.rows.firstIndex(where: { $0.card == cardId }) {
                book.people.selectRowIndexes(IndexSet(integer: row), byExtendingSelection: false)
            }
            onMain { book.properties(groupFirst: false) }
            if let person = await waitWindow("contact", 10) {
                let entry: NSTextField? = find("contact.key.0", in: person)
                check(entry?.stringValue == "bob@example.net: \(bobKey.grouped) (Valid, verified)",
                      "Bob's Properties show his key's fingerprint and Valid, verified (\(entry?.stringValue ?? ""))")
                check((find("contact.key.verify.0", in: person) as NSButton?) != nil, "with Verify beside it")
                await shot(person, "keys-11-contact")
                press(find("contact.cancel", in: person))
                _ = await waitUntil(5) { !person.isVisible }
            } else {
                check(false, "Bob's Properties open")
            }
            onMain { bookWindow.performClose(nil) }
            _ = await waitUntil(5) { !bookWindow.isVisible }
        } else {
            check(false, "the Address Book opens")
        }
        // the card out again: the Address Book's step starts empty
        _ = [cardId].withUnsafeBufferPointer { pe_book_delete(core.handle, 0, $0.baseAddress, 1, nil, 0) }

        // Remove asks first; Carol's key and the account's stay
        (keys, table) = try await openKeys()
        selectKey(table, "Bob Example")
        press(find("keys.remove", in: keys))
        if let sure = await waitWindow("alert", 10) {
            check(alertText(sure).contains("Remove the key of Bob Example?"), "Remove asks first (\(alertText(sure)))")
            answer(sure, "Remove")
        } else {
            check(false, "Remove asks first")
        }
        check(await waitUntil(5) { table?.numberOfRows == 2 && keyRow(table, "Bob Example") == nil },
              "then removes Bob's key, Carol's and the account's stay")
        await closeKeys(keys)
    }
}
