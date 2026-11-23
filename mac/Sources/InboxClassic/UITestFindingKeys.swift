// The UI end-to-end test's step of finding, publishing and passing on keys (19k of scripts/ui-e2e/SCENARIO.md), after
// 19j: Publish in Encryption Keys, Import from Clipboard, Find Key on the label of a part signed by an unknown key and
// in a contact's Properties, Import Key on an attached key, the Address Book's key marks, a key learned from an
// Autocrypt header and a changed one waiting, and a recipient's key found as Encrypt is turned on. The harness plays
// keys.openpgp.org and every domain's Web Key Directory (--key-server), and lists what was asked and published.
import AppKit
import CInboxClassic

extension UITest {
    /// the armored text of a key file of the fixtures
    func pgpFixture(_ name: String) -> String {
        (try? String(contentsOf: pgpFixtures.appendingPathComponent(name), encoding: .utf8)) ?? ""
    }

    /// a key put on the harness: by its fingerprints and key ids, with `address` by that address too, with `wkd` also
    /// in the address's Web Key Directory; the key's fingerprint
    @discardableResult
    func serveKey(_ name: String, address: String? = nil, wkd: Bool = false) async -> String {
        var body: [String: Any] = ["key": pgpFixture(name)]
        if let address {
            body["address"] = address
            body["wkd"] = wkd
        }
        let answer = await harness("POST", "/pgp/keys", body) as? [String: Any]
        return answer?["fingerprint"] as? String ?? ""
    }

    /// the key lookups the harness was asked, in order: kind, value, found
    func keyLookups() async -> [(kind: String, value: String, found: Bool)] {
        let list = await harness("GET", "/pgp/lookups") as? [[String: Any]] ?? []
        return list.map { ($0["kind"] as? String ?? "", $0["value"] as? String ?? "", $0["found"] as? Bool ?? false) }
    }

    /// a request to the harness's key server, its JSON answer
    func harness(_ method: String, _ path: String, _ body: [String: Any]? = nil) async -> Any? {
        var request = URLRequest(url: URL(string: "http://127.0.0.1:\(port("pgp"))\(path)")!)
        request.httpMethod = method
        if let body {
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        }
        guard let (data, _) = try? await URLSession.shared.data(for: request) else { return nil }
        return try? JSONSerialization.jsonObject(with: data)
    }

    /// the fixture `name` put in the Inbox and shown in the reading pane (a message that need not be signed); its uid
    func showPlainFixture(_ name: String) async throws -> UInt64 {
        let uid = try await addFixture(name)
        selectFolder(named: "Inbox")
        command(.sync)
        guard let row = await waitFor(30, { (0..<list.numberOfRows).first { main.mailbox.row($0)?.uid == uid } }) else {
            throw Failed(description: "\(name) is not in the list")
        }
        list.scrollRowToVisible(row)
        await selectRow(row)
        check(await waitUntil(30) { main.mailbox.reader.uid == uid && main.mailbox.reader.messageView?.info != nil },
              "\(name) is shown in the reading pane")
        return uid
    }

    /// a card of the Address Book saved; its id
    func addCard(_ name: String, _ address: String) -> Int64 {
        var card = BookCard()
        card.name = name
        let parts = name.split(separator: " ")
        card.first = parts.first.map(String.init) ?? ""
        card.last = parts.dropFirst().joined(separator: " ")
        card.addresses = [address]
        return (try? main.core.saveBookCard(card).get()) ?? 0
    }

    /// the Address Book open with the card `id` selected
    func openBook(selecting id: Int64) async -> (NSWindow, AddressBookWindow)? {
        command(.addressBook)
        guard let window = await waitWindow("addressbook", 10), let book = AddressBookWindow.shown else { return nil }
        AddressBookWindow.refresh()
        _ = await waitUntil(5) { book.rows.contains { $0.card == id } }
        if let row = book.rows.firstIndex(where: { $0.card == id }) {
            book.people.selectRowIndexes(IndexSet(integer: row), byExtendingSelection: false)
        }
        return (window, book)
    }

    /// a contact's Properties, from the Address Book with its card selected
    func openContact(_ book: AddressBookWindow) async -> NSWindow? {
        onMain { book.properties(groupFirst: false) }
        return await waitWindow("contact", 10)
    }

    func closeContact(_ person: NSWindow) async {
        press(find("contact.cancel", in: person))
        _ = await waitUntil(5) { !person.isVisible }
    }

    /// the row of the Encryption Keys list of the key `fingerprint` selected
    func selectKey(_ table: NSTableView?, fingerprint: String) {
        guard let row = main.core.pgpKeys().firstIndex(where: { $0.fingerprint == fingerprint }) else { return }
        table?.selectRowIndexes(IndexSet(integer: row), byExtendingSelection: false)
    }

    /// what an alert says once it opened (`what` failed when none does), answered with `button`
    func answered(_ what: String, by button: String = Text.uiOk.text) async -> String? {
        guard let alert = await waitWindow("alert", 60) else {
            check(false, what)
            return nil
        }
        let words = alertText(alert)
        answer(alert, button)
        _ = await waitUntil(5) { !alert.isVisible }
        return words
    }

    func findingKeys() async throws {
        step("finding, publishing and passing on keys")
        let core = main.core
        await search("")
        selectFolder(named: "Inbox")
        guard let account = core.accounts().first,
              let mine = core.pgpIdentities().first(where: { $0.address == account.email })?.fingerprint else {
            throw Failed(description: "no key of the account")
        }

        // Publish: greyed for a contact's key, asked first for the account's, then the server asked to confirm
        let (keys, table) = try await openKeys()
        let publish: NSButton? = find("keys.publish", in: keys)
        selectKey(table, "Alice Example")
        check(publish?.title == Text.uiKeysPublish.opens && publish?.isEnabled == false,
              "Publish is greyed with Alice's key selected, a contact's key is not the user's to publish")
        selectKey(table, fingerprint: mine)
        check(publish?.isEnabled == true, "and enabled with the account's key")
        press(publish)
        if let asked = await waitWindow("alert", 10) {
            let question = Text.uiKeysPublishAsk.text(["addresses": account.email])
            check(alertText(asked).contains(question), "it asks \"\(question)\" (\(alertText(asked)))")
            let buttons = views(NSButton.self, in: asked.contentView).map(\.title)
            check(Set(buttons) == [Text.uiKeysPublishNow.text, Text.uiCancel.text], "with Publish and Cancel (\(buttons))")
            await shot(asked, "keys-12-publish")
            answer(asked, Text.uiKeysPublishNow.text)
            _ = await waitUntil(5) { !asked.isVisible }
            let said = await answered("Publish says what the server did") ?? ""
            check(said.contains(lead(.pgpPublishPending)) && said.contains(account.email),
                  "Publish says the server sent a confirmation link to \(account.email) (\(said))")
        } else {
            check(false, "Publish asks first")
        }
        let uploads = await harness("GET", "/pgp/uploads") as? [[String: Any]] ?? []
        check(uploads.count == 1 && (uploads.first?["fingerprint"] as? String)?.uppercased() == mine.uppercased()
              && uploads.first?["addresses"] as? [String] == [account.email] && uploads.first?["asked"] as? [String] == [account.email],
              "the server got the account's key and was asked to confirm \(account.email) (\(uploads))")
        check(await waitUntil(5) { publish?.isEnabled == true }, "Publish can be used again once it is done")

        // Import from Clipboard: plain text holds no key, Judy's key is imported as "Pasted"
        let paste: NSButton? = find("keys.paste", in: keys)
        check(paste?.title == Text.uiKeysPaste.text, "Import from Clipboard is beside Import (\(paste?.title ?? ""))")
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString("not a key", forType: .string)
        let before = core.pgpKeys().count
        press(paste)
        let none = await answered("plain text on the clipboard says so") ?? ""
        check(none.contains(Text.uiKeysPasteNone.text) && core.pgpKeys().count == before,
              "plain text: \"\(Text.uiKeysPasteNone.text)\", nothing imported (\(none))")
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(pgpFixture("judy.asc"), forType: .string)
        press(paste)
        let pasted = await answered("Judy's key from the clipboard is imported") ?? ""
        check(pasted.contains(Text.pgpImportedPublic.text(["count": 1])), "Judy's key: \"One key was imported.\" (\(pasted))")
        let judy = await waitFor(5) { keyRow(table, "Judy Example") }
        check(judy.map { keyCell(table, $0, 1) == "judy@example.net" && keyCell(table, $0, 2) == Text.uiKeysKindContact.text
                  && keyCell(table, $0, 3) == Text.pgpKeyValid.text } == true,
              "the list shows Judy Example, judy@example.net, Contact, Valid")
        check(core.pgpKeys().first { $0.addresses.contains("judy@example.net") }?.source == Text.pgpSourcePaste.text,
              "her Properties say \"\(Text.pgpSourcePaste.text)\"")
        selectKey(table, "Judy Example")
        await shot(keys, "keys-13-paste")
        await darkShot(keys, "keys-13-paste-dark")
        NSPasteboard.general.clearContents()
        await closeKeys(keys)

        // Find Key on the label of a part signed by Dave's key, which the harness has by its fingerprint only
        let dave = await serveKey("dave.asc")
        var asked = await keyLookups().count
        var uid = try await showFixture("secure-no-key.eml")
        checkBar(PE_PROTECTION_TONE_NEUTRAL, encrypted: false, "a key not known: grey, no picture")
        check(securityBar.said == Text.pgpPartUnknownKey.text, "\"\(Text.pgpPartUnknownKey.text)\" (\(securityBar.said))")
        let reader = main.mailbox.reader
        let button = await reader.pageAnswer("(a=>a?a.getAttribute('href')+'|'+a.textContent:'')(document.querySelector('a.pe-f'))")
        check(button == "inboxclassic:find-key?\(dave)|\(Text.pgpPartFindKey.text)",
              "the label has Find Key beside it, its link Dave's fingerprint (\(button))")
        await shot(main.window, "keys-14-find-signer-before")
        var external: [URL] = []
        TestHooks.openURL = { external.append($0) }
        _ = await reader.pageAnswer("document.querySelector('a.pe-f').click()")
        let signed = Text.pgpPartSigned.text(["signer": "dave@example.com"])
        check(await waitUntil(60) { securityBar.said == signed && securityBar.tone == PE_PROTECTION_TONE_GOOD },
              "Find Key finds his key, the message is shown again: \"\(signed)\" (\(securityBar.said))")
        TestHooks.openURL = nil
        checkBar(PE_PROTECTION_TONE_GOOD, encrypted: false, "the bar blue with the ribbon")
        check(external.isEmpty, "the link is not opened in the browser")
        let lookups = await keyLookups().dropFirst(asked)
        check(lookups.count == 1 && lookups.first?.kind == "fingerprint" && lookups.first?.value == dave && lookups.first?.found == true,
              "the key server was asked by the fingerprint alone, no address (\(lookups))")
        let page = await securePage()
        let gone = await reader.pageAnswer("String(document.querySelector('a.pe-f')===null)")
        check(page.labels == [signed] && gone == "true", "the label says the same, without Find Key (\(page.labels))")
        let status: NSTextField? = find("status.text", in: main.window)
        check(status?.stringValue.isEmpty == false && status?.stringValue != Text.pgpRecipientLooking.text,
              "the status bar says what was found (\(status?.stringValue ?? ""))")
        await shot(main.window, "keys-14-find-signer")
        let daveKey = core.pgpKey(dave)
        check(daveKey?.addresses == ["dave@example.com"] && daveKey?.own == false && daveKey?.state == PE_KEY_STATE_VALID
              && daveKey?.source == Text.pgpSourceKeyserver.text,
              "My Keys lists Dave, dave@example.com, Contact, Valid, \"\(Text.pgpSourceKeyserver.text)\" (\(daveKey?.source ?? "none"))")
        await removeFixture(uid)

        // Find Key in Grace's Properties: her provider's directory answers, the key server is not asked
        let grace = await serveKey("grace.asc", address: "grace@example.net", wkd: true)
        let graceCard = addCard("Grace Example", "grace@example.net")
        var cards = [graceCard]
        guard let (bookWindow, book) = await openBook(selecting: graceCard) else { throw Failed(description: "the Address Book did not open") }
        if let person = await openContact(book) {
            let noKey: NSTextField? = find("contact.key.none", in: person)
            let findButton: NSButton? = find("contact.key.find", in: person)
            check(noKey?.stringValue == Text.uiContactKeyNone.text && findButton?.title == Text.uiContactFindKey.text
                  && findButton?.isEnabled == true, "Grace's Properties: \"No key\" and Find Key")
            await shot(person, "keys-15-contact-find-before")
            asked = await keyLookups().count
            press(findButton)
            let entry = { (self.find("contact.key.0", in: person) as NSTextField?)?.stringValue ?? "" }
            let shown = { "grace@example.net: \(core.pgpKey(grace)?.grouped ?? "-") (\(Text.pgpKeyValid.text))" }
            check(await waitUntil(60) { entry() == shown() },
                  "Find Key shows her key's fingerprint and Valid (\(entry()))")
            let found = await keyLookups().dropFirst(asked)
            check(found.count == 1 && found.first?.kind == "wkd" && found.first?.value == "grace@example.net" && found.first?.found == true,
                  "her provider's directory answered first, the key server was not asked (\(found))")
            check((find("contact.key.verify.0", in: person) as NSButton?) != nil, "with Verify")
            let said: NSTextField? = find("contact.key.found", in: person)
            check(said?.stringValue.isEmpty == false, "and the words of what was found (\(said?.stringValue ?? ""))")
            check((find("contact.key.find", in: person) as NSButton?) == nil, "Find Key goes once her address has a key")
            await shot(person, "keys-15-contact-find")
            await darkShot(person, "keys-15-contact-find-dark")
            await closeContact(person)
        } else {
            check(false, "Grace's Properties open")
        }
        let graceKey = core.pgpKey(grace)
        check(graceKey?.name == "Grace Example" && graceKey?.own == false && graceKey?.state == PE_KEY_STATE_VALID
              && graceKey?.source == Text.pgpSourceWkd.text,
              "My Keys lists Grace Example, Contact, Valid, \"\(Text.pgpSourceWkd.text)\" (\(graceKey?.source ?? "none"))")

        // Import Key on Erin's attached key; a picture has none
        uid = try await showPlainFixture("key-attached.eml")
        let strip = reader.strip
        check(strip.files.map(\.name) == ["Erin Example public key.asc"], "the strip shows \"Erin Example public key.asc\" (\(strip.files.map(\.name)))")
        let menu = strip.menu(for: strip.tiles[0])
        let importItem = menu.items.first { $0.identifier?.rawValue == "attachment.importKey" }
        check(importItem?.title == Text.uiAttachmentImportKey.opens, "its menu has Import Key\u{2026} (\(menu.items.map(\.title)))")
        // the Address Book stays open for the marks: the main window in front, as the user clicks it
        bringToFront(main.window)
        await menuShot(strip, "keys-16-attached-key")
        if let importItem, let index = menu.items.firstIndex(of: importItem) {
            onMain { menu.performActionForItem(at: index) }
            let said = await answered("Import Key says what was imported") ?? ""
            check(said.contains(Text.pgpImportedPublic.text(["count": 1])), "Import Key: \"One key was imported.\" (\(said))")
        }
        let erin = core.pgpKeys().first { $0.addresses.contains("erin@example.org") }
        check(erin?.name == "Erin Example" && erin?.own == false && erin?.state == PE_KEY_STATE_VALID
              && erin?.source == Text.pgpSourceAttachment.text,
              "My Keys lists Erin Example, erin@example.org, Contact, Valid, \"\(Text.pgpSourceAttachment.text)\" (\(erin?.source ?? "none"))")
        await removeFixture(uid)
        uid = try await showFixture("secure-previews.eml")
        if let harbour = strip.files.firstIndex(where: { $0.name == "harbour.png" }) {
            check(!strip.menu(for: strip.tiles[harbour]).items.contains { $0.identifier?.rawValue == "attachment.importKey" },
                  "a file that is not a key (harbour.png) has no Import Key")
        } else {
            check(false, "secure-previews.eml shows harbour.png")
        }
        await removeFixture(uid)

        // the Address Book's marks: Alice's key verified, Grace's found, Bob's removed in 19h
        cards.append(addCard("Alice Example", "alice@example.org"))
        cards.append(addCard("Bob Example", "bob@example.net"))
        AddressBookWindow.refresh()
        bringToFront(bookWindow)
        let mark = { (address: String) -> (tip: String?, name: String?, image: NSImage?) in
            guard let row = book.rows.firstIndex(where: { $0.address == address }),
                  let column = book.people.tableColumns.firstIndex(where: { $0.identifier.rawValue == "key" }),
                  let cell = book.people.view(atColumn: column, row: row, makeIfNecessary: true) as? NSTableCellView else { return (nil, nil, nil) }
            return (cell.toolTip, cell.isAccessibilityElement() ? cell.accessibilityLabel() : nil, cell.imageView?.image)
        }
        _ = await waitUntil(5) { book.rows.count >= 3 }
        let (alice, graceMark, bob) = (mark("alice@example.org"), mark("grace@example.net"), mark("bob@example.net"))
        check(alice.tip == Text.uiBookKeyVerified.text && alice.name == Text.uiBookKeyVerified.text,
              "Alice's row has the verified key mark, \"\(Text.uiBookKeyVerified.text)\" (\(alice.tip ?? "none"))")
        check(graceMark.tip == Text.uiBookKeyKnown.text && graceMark.name == Text.uiBookKeyKnown.text,
              "Grace's the key mark, \"\(Text.uiBookKeyKnown.text)\" (\(graceMark.tip ?? "none"))")
        check(alice.image != nil && graceMark.image != nil && alice.image?.accessibilityDescription != graceMark.image?.accessibilityDescription
              && alice.image?.tiffRepresentation != graceMark.image?.tiffRepresentation, "drawn differently")
        check(bob.tip == nil && bob.image == nil, "Bob's row has none")
        await shot(bookWindow, "keys-17-book-marks")
        await darkShot(bookWindow, "keys-17-book-marks-dark")

        // Frank's key learned from the Autocrypt header of a message opened, without a question
        uid = try await showPlainFixture("autocrypt-frank-1.eml")
        let frankKey = { core.pgpKeys().first { $0.addresses.contains("frank@example.org") } }
        check(await waitUntil(30) { frankKey() != nil }, "opening Frank's message learns his key")
        check(window("alert") == nil && Modal.windows.isEmpty, "without a question")
        let learned = frankKey()
        check(learned?.name == "Frank Example" && learned?.own == false && learned?.state == PE_KEY_STATE_VALID
              && learned?.source == Text.pgpSourceAutocrypt.text,
              "My Keys lists Frank Example, frank@example.org, Contact, Valid, \"\(Text.pgpSourceAutocrypt.text)\" (\(learned?.source ?? "none"))")
        let noted = learned?.fingerprint ?? ""
        let frankCard = addCard("Frank Example", "frank@example.org")
        cards.append(frankCard)
        AddressBookWindow.refresh()
        _ = await waitUntil(5) { book.rows.contains { $0.card == frankCard } }
        if let row = book.rows.firstIndex(where: { $0.card == frankCard }) {
            book.people.selectRowIndexes(IndexSet(integer: row), byExtendingSelection: false)
        }
        bringToFront(bookWindow)
        if let person = await openContact(book) {
            let entry: NSTextField? = find("contact.key.0", in: person)
            check(entry?.stringValue == "frank@example.org: \(learned?.grouped ?? "-") (\(Text.pgpKeyValid.text))",
                  "his Properties show the key's fingerprint and Valid (\(entry?.stringValue ?? ""))")
            await shot(person, "keys-18-learned")
            await closeContact(person)
        } else {
            check(false, "Frank's Properties open")
        }
        await removeFixture(uid)

        // another key of his: nothing asked in the reading pane, it waits in his Properties
        uid = try await showPlainFixture("autocrypt-frank-2.eml")
        check(await waitUntil(30) { core.pgpPeer("frank@example.org").pending != nil }, "his second message's key waits")
        check(window("alert") == nil && Modal.windows.isEmpty, "nothing is asked in the reading pane")
        if let person = await openContact(book) {
            let entry: NSTextField? = find("contact.key.0", in: person)
            let waiting: NSTextField? = find("contact.key.pending.0", in: person)
            check(entry?.stringValue.contains(learned?.grouped ?? "-") == true, "the key noted is still in use (\(entry?.stringValue ?? ""))")
            let words = "A different key for frank@example.org was found on"
            check(waiting?.stringValue.hasPrefix(words) == true && waiting?.stringValue == core.pgpPeer("frank@example.org").pendingText,
                  "under it \"\(words) ...\" (\(waiting?.stringValue ?? ""))")
            let useNew: NSButton? = find("contact.key.new.0", in: person)
            let keep: NSButton? = find("contact.key.keep.0", in: person)
            check(useNew?.title == Text.uiContactKeyUseNew.text && keep?.title == Text.uiContactKeyKeep.text,
                  "with Use the New Key and Keep the Current One")
            await shot(person, "keys-19-changed-key")
            press(keep)
            check(await waitUntil(5) { (self.find("contact.key.pending.0", in: person) as NSTextField?) == nil },
                  "Keep the Current One takes the note and its buttons away")
            await closeContact(person)
        } else {
            check(false, "Frank's Properties open again")
        }
        check(core.pgpPeer("frank@example.org").inUse == noted, "his key is still the one noted")
        if let person = await openContact(book) {
            let entry: NSTextField? = find("contact.key.0", in: person)
            check(entry?.stringValue.contains(learned?.grouped ?? "-") == true
                  && (find("contact.key.pending.0", in: person) as NSTextField?) == nil,
                  "opened again, his Properties show the same (\(entry?.stringValue ?? ""))")
            await closeContact(person)
        }
        await removeFixture(uid)
        onMain { bookWindow.performClose(nil) }
        _ = await waitUntil(5) { !bookWindow.isVisible }
        // the cards out again: the Address Book's step starts empty
        _ = cards.withUnsafeBufferPointer { pe_book_delete(core.handle, 0, $0.baseAddress, cards.count, nil, 0) }

        try await foundOnEncrypt()
    }

    /// a recipient without a key looked up as Encrypt is turned on: grey while it is, blue once found, sent encrypted
    /// to the key found without a question
    func foundOnEncrypt() async throws {
        let heidi = await serveKey("heidi.asc", address: "heidi@example.net")
        let asked = await keyLookups().count
        let (compose, writing) = try await newMessage(to: "Heidi Example <heidi@example.net>", subject: "Found as I wrote",
                                                     words: "For Heidi, encrypted.")
        press(writing.encryptButton)
        check(await waitUntil(5) { writing.security.encrypt }, "Encrypt turns encryption on")
        let chip = { writing.security.recipients.first { $0.address == "heidi@example.net" } }
        let first = chip()
        check(first?.key == PE_RECIPIENT_KEY_LOOKING || first?.key == PE_RECIPIENT_KEY_FOUND,
              "Heidi's lock is grey while her key is looked up, or already found (\(first?.text ?? ""))")
        if first?.key == PE_RECIPIENT_KEY_LOOKING {
            check(first?.text == Text.pgpRecipientLooking.text && writing.securityLine.tone == PE_PROTECTION_TONE_NEUTRAL,
                  "\"\(Text.pgpRecipientLooking.text)\", the line grey (\(writing.securityLine.said))")
        }
        check(await waitUntil(60) { chip()?.key == PE_RECIPIENT_KEY_FOUND }, "then her key is found (\(chip()?.text ?? ""))")
        check(chip()?.text == Text.pgpRecipientFound.text && chip()?.tone == PE_PROTECTION_TONE_GOOD,
              "her lock blue, \"\(Text.pgpRecipientFound.text)\" (\(chip()?.text ?? ""))")
        let line = "Will be encrypted and signed for you and Heidi Example."
        check(await waitUntil(10) { writing.securityLine.said == line }, "the line says \"\(line)\" (\(writing.securityLine.said))")
        check(writing.securityLine.tone == PE_PROTECTION_TONE_GOOD && writing.securityLine.pictures.lock, "in blue with the lock")
        await shot(compose, "write-36-found-on-encrypt")
        let lookups = Array(await keyLookups().dropFirst(asked))
        check(lookups.count == 2 && lookups[0].kind == "wkd" && lookups[0].value == "heidi@example.net" && !lookups[0].found
              && lookups[1].kind == "email" && lookups[1].value == "heidi@example.net" && lookups[1].found,
              "her provider's directory was asked first, then the key server by her address (\(lookups))")
        send(compose)
        if let (message, uid) = await arrived("Found as I wrote") {
            check(window("recipient.keys") == nil, "Send sends it at once, no Recipients' Keys")
            let answer = await pgpCheck(message, recipients: ["heidi.asc"])
            check(answer["kind"] as? String == "encrypted" && answer["signed"] as? Bool == true && answer["valid"] as? Bool == true
                  && (answer["to"] as? [Bool]) == [true], "sent encrypted and signed to the key found")
            await removeFixture(uid)
        } else {
            check(false, "the message to Heidi was sent")
            if let sheet = window("recipient.keys") {
                press(find("recipient.keys.cancel", in: sheet))
            }
            await closeCompose(compose)
        }
        let key = main.core.pgpKey(heidi)
        check(key?.name == "Heidi Example" && key?.own == false && key?.state == PE_KEY_STATE_VALID
              && key?.source == Text.pgpSourceKeyserver.text,
              "My Keys lists Heidi Example, Contact, Valid, \"\(Text.pgpSourceKeyserver.text)\" (\(key?.source ?? "none"))")
    }
}
