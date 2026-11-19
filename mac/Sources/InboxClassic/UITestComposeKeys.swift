// The UI end-to-end test's step of signing and encrypting what is written (19j of scripts/ui-e2e/SCENARIO.md), after
// the keys of 19i: Sign, Encrypt with the recipients' locks, a recipient without a key and Recipients' Keys, a reply
// to encrypted mail and its question, the encrypted quote in clear mail, and Attach My Public Key. Each message sent
// lands in the Inbox and is checked by the harness with OpenPGP.js (POST /pgp/check), then taken away. The app runs
// with --key-server on the harness, so no lookup leaves the computer.
import AppKit
import CInboxClassic

extension UITest {
    /// the compose window object of `compose`
    func composer(_ compose: NSWindow) -> ComposeWindow? {
        ComposeWindow.open.first { $0.window === compose }
    }

    /// what the harness's OpenPGP.js says of a message sent: signed, valid, encrypted (kind), its text, whom it was
    /// encrypted to, its attachments
    func pgpCheck(_ message: [String: Any]) async -> [String: Any] {
        let read = { (name: String) in (try? String(contentsOf: self.pgpFixtures.appendingPathComponent(name), encoding: .utf8)) ?? "" }
        var request = URLRequest(url: URL(string: "http://127.0.0.1:\(port("pgp"))/pgp/check")!)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try? JSONSerialization.data(withJSONObject: [
            "raw": message["raw"] as? String ?? "", "key": read("me.asc"),
            "passphrase": read("me.passphrase").trimmingCharacters(in: .whitespacesAndNewlines), "recipients": [read("alice.asc")],
        ])
        guard let (data, _) = try? await URLSession.shared.data(for: request),
              let answer = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else { return [:] }
        say("   pgp/check: \(String(decoding: data, as: UTF8.self).prefix(300))")
        return answer
    }

    /// the message with `subject` once it is in the Inbox, and its uid
    func arrived(_ subject: String) async -> (message: [String: Any], uid: UInt64)? {
        guard let message = await waitFor(30, { await findMessage("INBOX", "Subject: \(subject)") }),
              let uid = (message["uid"] as? NSNumber)?.uint64Value else { return nil }
        return (message, uid)
    }

    /// a new message to `to` about `subject` with `words` written
    func newMessage(to: String, subject: String, words: String) async throws -> (NSWindow, ComposeWindow) {
        command(.newMail)
        guard let compose = await waitCompose(), let window = composer(compose) else { throw Failed(description: "no compose window") }
        // the window in front, as one being written in is: the menus' Sign and Encrypt are those of the key window
        onMain { self.bringToFront(compose) }
        let inFront = await waitUntil(5) { ComposeWindow.key === window }
        check(inFront, "the new message's window is the one in front" + (inFront ? "" : " (active \(NSApp.isActive), in front "
            + "\(NSApp.orderedWindows.prefix(3).map { $0.identifier?.rawValue ?? $0.className }))"))
        type(to, into: field("compose.to", compose))
        window.recipientsChanged()
        type(subject, into: field("compose.subject", compose))
        check(await typeInEditor(compose, words), "the text is typed (\(subject))")
        return (compose, window)
    }

    /// whether the menu bar's item of `command` can be chosen, as AppKit asks when its menu opens
    func menuEnabled(_ command: Command) -> Bool {
        menuItem(command).map { AppDelegate.shared.validateMenuItem($0) } ?? false
    }

    /// the key of `command` pressed in `compose` with the cursor in the text, as the keyboard sends it
    func pressKey(_ command: Command, in compose: NSWindow) async {
        guard let (key, modifiers) = command.key, let editor: EditorView = views(EditorView.self, in: compose.contentView).first else { return }
        bringToFront(compose)
        compose.makeFirstResponder(editor)
        await pause(0.3)
        let event = NSEvent.keyEvent(with: .keyDown, location: .zero, modifierFlags: modifiers, timestamp: ProcessInfo.processInfo.systemUptime,
                                     windowNumber: compose.windowNumber, context: nil, characters: key, charactersIgnoringModifiers: key,
                                     isARepeat: false, keyCode: key == "y" ? 16 : 7)
        guard let event else { return }
        onMain {
            if NSApp.keyWindow === compose {
                NSApp.sendEvent(event)
            } else if !compose.performKeyEquivalent(with: event) {
                // the app in the background (another app holds the front): the key goes the way AppKit sends a key
                // equivalent, the window with the cursor in the text first, then the menu bar
                _ = NSApp.mainMenu?.performKeyEquivalent(with: event)
            }
        }
        await pause(0.5)
    }

    /// in dark mode for a picture, then back
    func darkShot(_ window: NSWindow?, _ name: String) async {
        let before = NSApp.appearance
        NSApp.appearance = NSAppearance(named: .darkAqua)
        await pause(0.6)
        await shot(window, name)
        NSApp.appearance = before
        await pause(0.3)
    }

    func composeKeys() async throws {
        step("signing and encrypting what is written")
        await search("")
        selectFolder(named: "Inbox")
        // the account's key is me.asc (imported in 19i), whose private part the harness has: the key made in 19h was
        // the account's until now, the fixture's was made before this run
        let core = main.core
        if let account = core.accounts().first,
           let fixture = core.pgpKeys().filter({ $0.own && $0.name == "Alex Morgan" }).min(by: { $0.created < $1.created }) {
            core.pgpSetAccountKey(account.id, fingerprint: fixture.fingerprint, autocrypt: true)
            check(core.pgpIdentities().contains { $0.address == account.email && $0.fingerprint == fixture.fingerprint },
                  "the key of me.asc is the account's")
        } else {
            check(false, "the key of me.asc is the account's")
        }

        // a new message: Sign and Encrypt off, no line
        var (compose, window) = try await newMessage(to: "alice@example.org", subject: "Signed from the Mac",
                                                      words: "A signed hello from the Mac.")
        check(window.signButton?.state == .off && window.encryptButton?.state == .off,
              "a new message starts with Sign and Encrypt off on the toolbar")
        check(menuItem(.composeSign)?.state == .off && menuItem(.composeEncrypt)?.state == .off
              && menuEnabled(.composeSign), "and unchecked in Tools")
        check(window.securityLine.isHidden, "with no line under the fields")
        check(window.signButton?.superview?.toolTip?.isEmpty == false, "Sign has a tooltip (\(window.signButton?.superview?.toolTip ?? ""))")

        // Sign, with Option-Command-Y in the text
        await pressKey(.composeSign, in: compose)
        check(window.signButton?.state == .on && menuItem(.composeSign)?.state == .on,
              "Option-Command-Y in the text turns Sign on: the button pressed, the menu item checked")
        let signedLine = "Will be signed: recipients can check that the signed content has not changed. They must also verify who owns your key."
        check(!window.securityLine.isHidden && window.securityLine.said == signedLine && window.securityLine.tone == PE_PROTECTION_TONE_GOOD,
              "the line says \"\(signedLine)\" in blue (\(window.securityLine.said))")
        check(window.securityLine.pictures.mark == SecurityBar.symbol(PE_PROTECTION_TONE_GOOD) && !window.securityLine.pictures.lock,
              "with the ribbon, no lock")
        check(window.securityLine.detailsButton.isHidden, "and no Details while it is not encrypted")
        await shot(compose, "write-30-sign")
        send(compose)
        if let (message, uid) = await arrived("Signed from the Mac") {
            let answer = await pgpCheck(message)
            check(answer["signed"] as? Bool == true && answer["valid"] as? Bool == true, "sent, the harness finds it signed and valid")
            check((answer["text"] as? String)?.contains("A signed hello from the Mac.") == true, "with the text written")
            await removeFixture(uid)
        } else {
            check(false, "the signed message arrived")
        }

        // Encrypt, with the toolbar's button: Sign on and greyed, Alice's lock green
        (compose, window) = try await newMessage(to: "Alice Example <alice@example.org>", subject: "Encrypted from the Mac",
                                                 words: "The secret plan of the Mac.")
        press(window.encryptButton)
        check(await waitUntil(5) { window.security.encrypt }, "Encrypt on the toolbar turns encryption on")
        check(window.signButton?.state == .on && window.signButton?.isEnabled == false, "Sign shows on and greyed")
        check(window.signButton?.superview?.toolTip == Text.pgpComposeSignTipEncrypted.text,
              "its tooltip, on the item: \"An encrypted message is always signed\" (\(window.signButton?.superview?.toolTip ?? ""))")
        check(!menuEnabled(.composeSign) && menuItem(.composeSign)?.state == .on
              && menuItem(.composeEncrypt)?.state == .on, "Tools: Digitally Sign checked and greyed, Encrypt checked")
        let alice = window.keysRow.chips.first
        check(!window.keysRow.isHiddenOrHasHiddenAncestor && window.keysRow.chips.count == 1 && alice?.recipient?.label == "Alice Example"
              && alice?.recipient?.tone == PE_PROTECTION_TONE_VERIFIED,
              "the Keys row shows Alice with a green lock (\(alice?.recipient?.text ?? ""))")
        let encryptedLine = "Will be encrypted and signed for you and Alice Example."
        check(window.securityLine.said == encryptedLine && window.securityLine.tone == PE_PROTECTION_TONE_VERIFIED
              && window.securityLine.pictures.lock, "the line says \"\(encryptedLine)\" in green with the lock (\(window.securityLine.said))")
        check(!window.securityLine.detailsButton.isHidden, "with Details")
        await shot(compose, "write-31-encrypt")
        await darkShot(compose, "write-31-encrypt-dark")
        check(contrast(window.securityLine) >= 4.5, "the line's words are readable on it (\(contrast(window.securityLine)))")
        send(compose)
        if let (message, uid) = await arrived("Encrypted from the Mac") {
            let answer = await pgpCheck(message)
            check(answer["kind"] as? String == "encrypted" && answer["signed"] as? Bool == true && answer["valid"] as? Bool == true,
                  "sent, the harness finds it encrypted, signed and valid")
            check((answer["to"] as? [Bool]) == [true], "encrypted to Alice's key")
            check((answer["text"] as? String)?.contains("The secret plan of the Mac.") == true, "and decrypts the text written")
            check(!raw(message).contains("secret plan"), "the server's copy holds none of the words written")
            await removeFixture(uid)
        } else {
            check(false, "the encrypted message arrived")
        }

        // Alice and Dave, Encrypt from the menu: Dave has no key, Send opens Recipients' Keys
        (compose, window) = try await newMessage(to: "Alice Example <alice@example.org>, Dave <dave@example.com>",
                                                 subject: "Encrypted to two from the Mac", words: "For Alice and Dave.")
        command(.composeEncrypt)
        check(await waitUntil(5) { window.security.encrypt }, "Tools > Encrypt turns encryption on")
        let dave = { window.security.recipients.first { $0.address == "dave@example.com" } }
        check(dave()?.key == PE_RECIPIENT_KEY_LOOKING || dave()?.key == PE_RECIPIENT_KEY_MISSING,
              "Dave's lock is grey while his key is looked up (\(dave()?.text ?? ""))")
        check(await waitUntil(15) { dave()?.key == PE_RECIPIENT_KEY_MISSING }, "then amber: no key (\(dave()?.text ?? ""))")
        check(dave()?.text.hasPrefix(lead(.pgpRecipientNotFound)) == true && dave()?.tone == PE_PROTECTION_TONE_WARNING,
              "\"No key: none was found on\" today (\(dave()?.text ?? ""))")
        check(window.keysRow.chips.last?.recipient?.symbol == "exclamationmark.triangle.fill", "his chip has the warning sign")
        check(window.securityLine.tone == PE_PROTECTION_TONE_WARNING && window.securityLine.said.contains("Dave"),
              "the line is amber and names Dave (\(window.securityLine.said))")
        send(compose)
        guard let sheetWindow = await waitWindow("recipient.keys", 10), let sheet = window.keysSheet else {
            throw Failed(description: "Send did not open Recipients' Keys")
        }
        check(true, "Send opens Recipients' Keys instead of sending")
        let intro: NSTextField? = find("recipient.keys.intro", in: sheetWindow)
        check(intro?.stringValue.hasPrefix("One recipient has no usable encryption key") == true, "it says \"One recipient has no usable encryption key...\" (\(intro?.stringValue ?? ""))")
        check(sheet.rows.map(\.text).first == Text.pgpRecipientVerified.text && sheet.rows.last?.text.hasPrefix(Text.pgpRecipientMissing.text) == true,
              "Alice (Key verified) and Dave (No key) with their locks (\(sheet.rows.map(\.text)))")
        if let row = sheet.rows.firstIndex(where: { $0.address == "dave@example.com" }) {
            sheet.table.selectRowIndexes(IndexSet(integer: row), byExtendingSelection: false)
        }
        check(!sheet.findButton.isEnabled, "Find Key greyed for Dave, asked a moment ago")
        check(sheet.removeButton.isEnabled && sheet.unencryptedButton.isEnabled && !sheet.sendButton.isEnabled,
              "Remove from Message and Send Without Encryption, Send greyed")
        var asked: String?
        TestHooks.help = { asked = $0 }
        Help.open(for: sheetWindow)
        TestHooks.help = nil
        check(asked == "sign-and-encrypt", "Help in it opens Sign and encrypt a message (\(asked ?? ""))")
        await shot(sheetWindow, "write-32-missing-key")
        await darkShot(sheetWindow, "write-32-missing-key-dark")
        press(sheet.removeButton)
        check(await waitUntil(5) { sheet.rows.count == 1 }, "Remove from Message leaves Alice alone")
        check(field("compose.to", compose)?.stringValue == "Alice Example <alice@example.org>",
              "and takes Dave out of To (\(field("compose.to", compose)?.stringValue ?? ""))")
        check(sheet.sendButton.isEnabled, "Send can go now")
        press(sheet.sendButton)
        if let (message, uid) = await arrived("Encrypted to two from the Mac") {
            let answer = await pgpCheck(message)
            check(answer["kind"] as? String == "encrypted" && (answer["to"] as? [Bool]) == [true], "Send sends it encrypted to Alice")
            await removeFixture(uid)
        } else {
            check(false, "the message to Alice arrived")
        }

        // a reply to encrypted mail: Encrypt and Sign on, turning it off asks
        let fixture = try await showFixture("secure-encrypted.eml")
        command(.reply)
        guard let reply = await waitCompose(), let replying = composer(reply) else { throw Failed(description: "no reply") }
        (compose, window) = (reply, replying)
        _ = await waitUntil(10) { window.security.recipients.first?.tone == PE_PROTECTION_TONE_VERIFIED }
        check(window.security.encrypt && window.security.sign && window.encryptButton?.state == .on,
              "a reply to encrypted mail opens with Encrypt and Sign on")
        check(window.keysRow.chips.first?.recipient?.tone == PE_PROTECTION_TONE_VERIFIED, "Alice's lock green")
        press(window.encryptButton)
        if let question = await waitWindow("alert", 10) {
            check(alertText(question).contains(Text.pgpComposeEncryptOffQuote.text),
                  "Encrypt clicked off asks first (\(alertText(question)))")
            let buttons = views(NSButton.self, in: question.contentView)
            let off = buttons.first { $0.title == Text.uiComposeEncryptOff.text }
            let keep = buttons.first { $0.title == Text.uiComposeKeepEncrypted.text }
            check(off?.hasDestructiveAction == true && keep != nil && keep?.hasDestructiveAction == false,
                  "with Turn Encryption Off, marked destructive, and Keep It Encrypted")
            await shot(question, "write-33-reply-encrypted")
            // Return answers with the default: Keep It Encrypted
            pressKey(question, 36)
            let answered = await waitUntil(5) { !question.isVisible }
            check(answered && window.security.encrypt, "Return, the default Keep It Encrypted, answers and leaves it on")
            if !answered {
                answer(question, Text.uiComposeKeepEncrypted.text)
                _ = await waitUntil(5) { !question.isVisible }
            }
        } else {
            check(false, "Encrypt clicked off asks first")
        }
        press(window.encryptButton)
        if let question = await waitWindow("alert", 10) {
            answer(question, Text.uiComposeEncryptOff.text)
            _ = await waitUntil(5) { !question.isVisible }
        }
        check(await waitUntil(5) { !window.security.encrypt }, "Turn Encryption Off turns it off")
        check(window.securityLine.tone == PE_PROTECTION_TONE_WARNING
              && window.securityLine.said == Text.pgpErrorEncryptedQuote.text,
              "the line is amber: it can only be sent encrypted (\(window.securityLine.said))")
        check(window.keysRow.isHiddenOrHasHiddenAncestor, "and the Keys row is gone")
        await shot(compose, "write-34-quote-in-clear")
        send(compose)
        if let refusal = await waitWindow("alert", 10) {
            check(alertText(refusal).contains(Text.pgpErrorEncryptedQuote.text), "Send is refused with the same words (\(alertText(refusal)))")
            answer(refusal, Text.uiOk.text)
            _ = await waitUntil(5) { !refusal.isVisible }
        } else {
            check(false, "Send is refused")
        }
        check(compose.isVisible, "and the message stays open")
        // the quote unfolded and deleted
        if let editor: EditorView = views(EditorView.self, in: compose.contentView).first {
            _ = try? await editor.evaluateJavaScript("document.getElementById('more').click();"
                + "document.querySelector('#body > div.quoted').remove();document.getElementById('body').dispatchEvent(new Event('input'));true")
        }
        check(await waitUntil(15) { window.security.block == PE_COMPOSE_BLOCK_NONE
                  && window.securityLine.said == Text.pgpComposeReplyClear.text },
              "the quote unfolded and deleted, the line says it is not encrypted (\(window.securityLine.said))")
        check(window.securityLine.tone == PE_PROTECTION_TONE_WARNING && window.securityLine.pictures.mark == SecurityBar.symbol(PE_PROTECTION_TONE_WARNING),
              "in amber with the warning sign")
        await shot(compose, "write-34b-reply-clear")
        let replySubject = NSRegularExpression.escapedPattern(for: field("compose.subject", compose)?.stringValue ?? "")
        send(compose)
        if let (message, uid) = await arrived(replySubject) {
            let answer = await pgpCheck(message)
            check(answer["signed"] as? Bool == true && answer["kind"] as? String != "encrypted",
                  "sent, the harness finds it signed, not encrypted")
            check((answer["text"] as? String)?.contains("old mill") == false && !raw(message).contains("old mill"),
                  "and without the words of the encrypted message")
            await removeFixture(uid)
        } else {
            check(false, "the reply arrived")
        }
        await removeFixture(fixture)

        // Attach My Public Key, in File
        (compose, window) = try await newMessage(to: "alice@example.org", subject: "My key from the Mac", words: "Here is my key.")
        check(menuEnabled(.attachMyKey) && menuItem(.attachMyKey)?.menu?.title == Text.menuFile.text,
              "File > Attach My Public Key is there for the account's key")
        command(.attachMyKey)
        check(await waitUntil(5) { window.attachedNames == ["Alex Morgan public key.asc"] },
              "it puts \"Alex Morgan public key.asc\" in the Attach line (\(window.attachedNames))")
        await shot(compose, "write-35-attach-key")
        send(compose)
        if let (message, uid) = await arrived("My key from the Mac") {
            let answer = await pgpCheck(message)
            let files = answer["attachments"] as? [[String: Any]] ?? []
            check(files.contains { $0["type"] as? String == "application/pgp-keys" && $0["name"] as? String == "Alex Morgan public key.asc" },
                  "sent as application/pgp-keys with that name (\(files))")
            await removeFixture(uid)
        } else {
            check(false, "the message with the key arrived")
        }

        try await composeKeysInLanguages()
    }

    /// for the review: the compose window encrypting to ten recipients, one without a key, and Recipients' Keys, in
    /// German and in the pseudo-language (the longest words)
    func composeKeysInLanguages() async throws {
        let many = (["Alice Example <alice@example.org>", "Dave <dave@example.com>"] + (1...8).map { "Person \($0) <person\($0)@example.net>" })
            .joined(separator: ", ")
        for language in ["de", "qps"] {
            Languages.apply(language)
            let (compose, window) = try await newMessage(to: many, subject: "Review \(language)", words: "Review.")
            command(.composeEncrypt)
            _ = await waitUntil(15) { window.security.encrypt && !window.security.looking }
            check(await waitUntil(5) {
                compose.contentView?.layoutSubtreeIfNeeded()
                return window.keysRow.shown < 10 && window.keysRow.shown > 0
            }, "\(language): ten recipients fit the Keys row, the rest counted (\(window.keysRow.shown))")
            let line: NSTextField? = find("compose.security.words", in: compose)
            check((line?.intrinsicContentSize.height ?? 0) <= (line?.bounds.height ?? 0) + 1,
                  "\(language): the line's words are not cut off")
            await shot(compose, "review-\(language)-encrypt")
            await darkShot(compose, "review-\(language)-encrypt-dark")
            send(compose)
            if let sheet = await waitWindow("recipient.keys", 10) {
                await shot(sheet, "review-\(language)-keys")
                press(find("recipient.keys.cancel", in: sheet))
                _ = await waitUntil(5) { !sheet.isVisible }
            }
            await closeCompose(compose)
        }
        Languages.apply("en")
    }
}
