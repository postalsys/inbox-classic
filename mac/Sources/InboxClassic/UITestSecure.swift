// The UI end-to-end test's step of signed and encrypted mail (19i of scripts/ui-e2e/SCENARIO.md): the keys of
// scripts/ui-e2e/pgp imported, then each of its messages put in the Inbox over ImapKit's API, read, and taken away:
// the security bar's words, tone and pictures, the parts' frames and their heights, Details, the part labels' links,
// the pictures of an encrypted part, and the bar in dark mode.
import AppKit
import CInboxClassic
import PDFKit
import WebKit

extension UITest {
    var pgpFixtures: URL { repo.appendingPathComponent("scripts/ui-e2e/pgp") }

    var securityBar: SecurityBar { main.mailbox.reader.security }

    /// the protection of the message shown, as the core gave it
    var shownProtection: (tone: PeProtectionTone, text: String, encrypted: Bool)? {
        guard let info = main.mailbox.reader.messageView?.info?.pointee else { return nil }
        return (info.protection, text(info.protection_text), info.protection_encrypted)
    }

    /// what the page of the message shown has: each part's label, and each frame's height, the height of its
    /// document and its text, read by the app's own script (the page's scripts are off)
    struct SecurePage {
        var labels: [String] = []
        var heights: [Int] = []
        var needed: [Int] = []
        var texts: [String] = []
        /// every frame is as tall as its document: nothing cut off, no scroll bar inside a frame
        var fits: Bool { !heights.isEmpty && zip(heights, needed).allSatisfy { $0 >= $1 } }
    }

    func securePage() async -> SecurePage {
        let script = "JSON.stringify({labels:[...document.querySelectorAll('a.pe-l')].map(a=>a.textContent),"
            + "frames:[...document.querySelectorAll('iframe.pe-d')].map(f=>{const d=f.contentDocument;"
            + "return {h:f.offsetHeight,s:d&&d.documentElement?d.documentElement.scrollHeight:-1,"
            + "t:d&&d.body?d.body.innerText:''}})})"
        let answer = await main.mailbox.reader.pageAnswer(script)
        guard let object = try? JSONSerialization.jsonObject(with: Data(answer.utf8)) as? [String: Any] else {
            return SecurePage()
        }
        var page = SecurePage()
        page.labels = object["labels"] as? [String] ?? []
        for frame in object["frames"] as? [[String: Any]] ?? [] {
            page.heights.append(frame["h"] as? Int ?? 0)
            page.needed.append(frame["s"] as? Int ?? -1)
            page.texts.append(frame["t"] as? String ?? "")
        }
        return page
    }

    /// the message file `name` of the fixtures put in the Inbox; its uid there
    func addFixture(_ name: String) async throws -> UInt64 {
        let raw = try String(contentsOf: pgpFixtures.appendingPathComponent(name), encoding: .utf8)
        var request = URLRequest(url: URL(string: "\(rest)/INBOX/messages")!)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: ["raw": raw, "flags": ["\\Seen"]])
        let (data, _) = try await URLSession.shared.data(for: request)
        let answer = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        guard let uid = (answer?["uid"] as? NSNumber)?.uint64Value else {
            throw Failed(description: "ImapKit did not take \(name)")
        }
        return uid
    }

    /// the message `uid` taken out of the Inbox again, and out of the list
    func removeFixture(_ uid: UInt64) async {
        var request = URLRequest(url: URL(string: "\(rest)/INBOX/messages/\(uid)")!)
        request.httpMethod = "DELETE"
        _ = try? await URLSession.shared.data(for: request)
        command(.sync)
        _ = await waitUntil(20) { (0..<list.numberOfRows).allSatisfy { main.mailbox.row($0)?.uid != uid } }
    }

    /// the fixture `name` put in the Inbox and shown in the reading pane, its frames measured; its uid
    func showFixture(_ name: String) async throws -> UInt64 {
        let uid = try await addFixture(name)
        selectFolder(named: "Inbox")
        command(.sync)
        guard let row = await waitFor(30, { (0..<list.numberOfRows).first { main.mailbox.row($0)?.uid == uid } }) else {
            throw Failed(description: "\(name) is not in the list")
        }
        list.scrollRowToVisible(row)
        await selectRow(row)
        _ = await waitUntil(20) { main.mailbox.reader.uid == uid && shownProtection != nil && !securityBar.isHidden }
        // the first measure after the page loaded
        _ = await waitUntil(5) { (await securePage()).fits }
        return uid
    }

    /// the bar shows the tone, its picture, the lock when `encrypted`, and the core's words
    func checkBar(_ tone: PeProtectionTone, encrypted: Bool, _ what: String) {
        let bar = securityBar
        let core = shownProtection
        check(!bar.isHidden && bar.tone == tone && core?.tone == tone && bar.said == core?.text
              && bar.pictures.lock == encrypted && bar.pictures.mark == SecurityBar.symbol(tone)
              && bar.accessibilityLabel() == core?.text,
              "\(what) (\(bar.said), \(bar.pictures))")
    }

    func secureMail() async throws {
        step("signed and encrypted mail")
        let core = main.core
        await search("")
        selectFolder(named: "Inbox")
        let read = { (name: String) in (try? Data(contentsOf: self.pgpFixtures.appendingPathComponent(name))) ?? Data() }
        let passphrase = String(decoding: read("me.passphrase"), as: UTF8.self).trimmingCharacters(in: .whitespacesAndNewlines)
        let mine = core.pgpImport(read("me.asc"), passphrase: passphrase)
        check(mine.outcome == PE_IMPORT_OUTCOME_IMPORTED, "me.asc imported with its passphrase (\(mine.message))")
        for name in ["alice.asc", "mallory.asc"] {
            let imported = core.pgpImport(read(name), passphrase: nil)
            check(imported.outcome == PE_IMPORT_OUTCOME_IMPORTED, "\(name) imported (\(imported.message))")
        }
        let preferences = (views(WKWebView.self, in: main.mailbox.reader.view).first)?.configuration.defaultWebpagePreferences
        check(preferences?.allowsContentJavaScript == false, "the reading pane runs no script of a page")
        guard let alice = core.pgpKeys().first(where: { $0.addresses.contains("alice@example.org") }) else {
            throw Failed(description: "no key of Alice")
        }

        // signed by Alice, her key not verified: blue, the ribbon
        var uid = try await showFixture("secure-signed.eml")
        var page = await securePage()
        checkBar(PE_PROTECTION_TONE_GOOD, encrypted: false, "a signed message: the bar is blue with the ribbon")
        check(securityBar.said == "Signed by alice@example.org (key not verified)", "and says \"Signed by alice@example.org (key not verified)\"")
        check(page.heights.count == 1 && page.labels == [securityBar.said],
              "the part has one frame labelled the same (\(page.labels))")
        check(page.fits, "as tall as its document (\(page.heights) for \(page.needed))")
        await shot(main.window, "secure-2-signed-unverified")

        // Verify Key, They Match: green, the shield
        let (keys, table) = try await openKeys()
        selectKey(table, alice.name)
        press(find("keys.verify", in: keys))
        if let verify = await waitWindow("key.verify", 10) {
            press(find("key.verify.match", in: verify))
            _ = await waitUntil(5) { !verify.isVisible }
        } else {
            check(false, "Verify opens for Alice's key")
        }
        await closeKeys(keys)
        check(core.pgpKey(alice.fingerprint)?.verified == true, "They Match verifies Alice's key")
        main.mailbox.reader.reload()
        _ = await waitUntil(15) { shownProtection?.tone == PE_PROTECTION_TONE_VERIFIED }
        checkBar(PE_PROTECTION_TONE_VERIFIED, encrypted: false, "the same message then shows green with the shield")
        check(securityBar.said.contains(Text.pgpPartVerified.text(["signer": "alice@example.org"])), "\"key verified\" (\(securityBar.said))")
        _ = await waitUntil(5) { (await securePage()).labels.first?.contains("verified") == true }
        await shot(main.window, "secure-1-verified")
        await removeFixture(uid)

        // encrypted to the user's key and signed: the lock
        uid = try await showFixture("secure-encrypted.eml")
        page = await securePage()
        checkBar(PE_PROTECTION_TONE_VERIFIED, encrypted: true, "an encrypted message: the bar has the lock")
        check(securityBar.said.hasPrefix("Encrypted. " + Text.pgpPartVerified.text(["signer": "alice@example.org"])),
              "and says \"Encrypted. Signed by alice@example.org, key verified\" (\(securityBar.said))")
        check(page.texts.contains { $0.contains("old mill") }, "the text is shown: \"old mill\"")
        check(page.fits, "its frame as tall as its document (\(page.heights) for \(page.needed))")
        await shot(main.window, "secure-3-encrypted")
        await removeFixture(uid)

        // three parts, each its own frame and label
        uid = try await showFixture("secure-mixed.eml")
        page = await securePage()
        checkBar(PE_PROTECTION_TONE_NEUTRAL, encrypted: false, "parts signed apart: the bar is grey, with no picture")
        check(securityBar.said.contains("3 parts: 1 verified, 2 without a confirmed signature"),
              "and counts them: 3 parts, 1 verified, 2 without a confirmed signature (\(securityBar.said))")
        check(page.heights.count == 3 && page.labels.count == 3 && page.labels[0] == Text.pgpPartNotSigned.text
              && page.labels[1].contains("alice@example.org") && page.labels[2] == Text.pgpPartNotSigned.text,
              "three frames, each with its own label (\(page.labels))")
        check(page.fits, "each as tall as its document (\(page.heights) for \(page.needed))")
        await shot(main.window, "secure-4-mixed-parts")
        // a link in a part's frame goes to the browser, through the top page; the page stays
        var browsed: [URL] = []
        TestHooks.openURL = { browsed.append($0) }
        _ = await main.mailbox.reader.pageAnswer("[...document.querySelectorAll('iframe.pe-d')[0].contentDocument.links]"
            + ".find(a=>a.textContent=='The mill').click()")
        check(await waitUntil(10) { !browsed.isEmpty } && browsed.map(\.absoluteString) == ["https://example.org/mill"],
              "\"The mill\" in part 1's frame opens https://example.org/mill in the browser (\(browsed))")
        TestHooks.openURL = nil
        await pause(0.5)
        let stayed = await securePage()
        check(stayed.labels == page.labels && stayed.texts.first?.contains("The mill") == true,
              "and the page stays as it was (\(stayed.labels))")
        await checkPrinted(page)
        await removeFixture(uid)

        // what is not right: amber with the warning sign; a key not known: grey
        uid = try await showFixture("secure-bad.eml")
        checkBar(PE_PROTECTION_TONE_WARNING, encrypted: false, "a changed text: amber with the warning sign")
        check(securityBar.said.contains(Text.pgpWhyMismatch.text), "\"does not match\" (\(securityBar.said))")
        await shot(main.window, "secure-5-bad-signature")
        await removeFixture(uid)
        uid = try await showFixture("secure-wrong-signer.eml")
        checkBar(PE_PROTECTION_TONE_WARNING, encrypted: false, "signed by someone else: amber with the warning sign")
        check(securityBar.said.contains(Text.pgpPartOther.text(["signer": "mallory@example.net"])),
              "names mallory@example.net, \"who is not the sender\" (\(securityBar.said))")
        await shot(main.window, "secure-6-wrong-signer")
        await removeFixture(uid)
        uid = try await showFixture("secure-no-key.eml")
        checkBar(PE_PROTECTION_TONE_NEUTRAL, encrypted: false, "a key not known: grey, no picture")
        check(securityBar.said == Text.pgpPartUnknownKey.text, "\"Signed, but the key is not known\" (\(securityBar.said))")
        await shot(main.window, "secure-7-no-key")
        await removeFixture(uid)

        // a label painted in a part stays in its frame, under the real one
        uid = try await showFixture("secure-fake-frame.eml")
        page = await securePage()
        check(securityBar.said.contains("2 parts"), "a painted label: the bar counts 2 parts (\(securityBar.said))")
        check(page.labels.count == 2 && page.labels[0] == Text.pgpPartNotSigned.text && page.labels[1].contains("alice@example.org"),
              "the real labels are both there (\(page.labels))")
        let shown = await main.mailbox.reader.pageAnswer("[...document.querySelectorAll('a.pe-l')].every(a=>{const r=a.getBoundingClientRect();"
            + "return getComputedStyle(a).display!='none'&&r.height>0&&document.elementFromPoint(r.left+4,r.top+r.height/2)===a})")
        check(shown == "true", "each one shown where it is, nothing over it, its styles not changed by the part's")
        check(page.texts.first?.contains("Wire the money today") == true, "the painted one inside the first frame")
        check(page.heights.allSatisfy { $0 >= 48 }, "and each frame at least 48 px tall, the painted part too (\(page.heights))")
        await shot(main.window, "secure-8-fake-frame")

        // Details: from the bar, then from a part's label
        let detailsTitle = Text.uiProtectionDetailsTitle.text
        press(securityBar.detailsButton)
        if let details = await waitWindow("protection.details", 10) {
            let body = (find("protection.details.text", in: details) as NSTextView?)?.string ?? ""
            say("   details: \(body.replacingOccurrences(of: "\n", with: " | "))")
            check(details.title == detailsTitle, "Details on the bar opens \(detailsTitle)")
            check(body.contains("Part 2") && body.contains("Part 1"), "which names each part")
            check(body.contains(alice.grouped) || body.contains("with the key"), "and the key that signed Part 2 and when")
            check((find("help.protection-details", in: details) as NSButton?) != nil, "with a help button")
            let textView: NSTextView? = find("protection.details.text", in: details)
            let visible = textView?.enclosingScrollView?.contentView.bounds.height ?? 0
            check(visible >= (textView?.frame.height ?? .infinity) - 1, "all of its text shown without scrolling (\(visible) for \(textView?.frame.height ?? 0))")
            var asked: String?
            TestHooks.help = { asked = $0 }
            Help.open(for: details)
            TestHooks.help = nil
            check(asked == "encrypted-and-signed-mail", "Help in it opens the topic of signed and encrypted mail (\(asked ?? ""))")
            await shot(details, "secure-9-details")
            press(find("protection.details.close", in: details))
            _ = await waitUntil(5) { !details.isVisible }
        } else {
            check(false, "Details on the bar opens \(detailsTitle)")
        }
        _ = await main.mailbox.reader.pageAnswer("document.querySelectorAll('a.pe-l')[1].click()")
        if let details = await waitWindow("protection.details", 10) {
            check(true, "a click on a part's label opens Details too")
            press(find("protection.details.close", in: details))
            _ = await waitUntil(5) { !details.isVisible }
        } else {
            check(false, "a click on a part's label opens Details")
        }
        check(await securePage().labels.count == 2, "and the page stays")
        await removeFixture(uid)

        // inline PGP: the block a part of its own
        uid = try await showFixture("secure-inline.eml")
        page = await securePage()
        check(securityBar.said.contains("3 parts"), "inline encrypted: the bar counts 3 parts (\(securityBar.said))")
        check(page.heights.count == 3 && page.texts.contains { $0.contains("4711") },
              "the block in a frame of its own, \"4711\" shown, the text around it in frames of their own")
        await shot(main.window, "secure-10-inline")
        await removeFixture(uid)

        // pictures in an encrypted part: on a click only, never always
        uid = try await showFixture("secure-pictures.eml")
        let bar: InfoBar? = find("reader.pictures", in: main.window)
        let blocked = await securePage()
        check(bar?.isHidden == false && !picturesLoaded, "an encrypted part's pictures: the pictures bar shows")
        check(main.mailbox.reader.picturesMenu == nil && main.mailbox.reader.picturesDownload.isHidden == false,
              "with Download Pictures alone, no \"always\" choices")
        let unloaded = await main.mailbox.reader.pageAnswer("[...document.querySelectorAll('iframe.pe-d')].flatMap(f=>"
            + "[...f.contentDocument.images]).every(i=>i.naturalWidth==0)")
        check(unloaded == "true", "nothing of the internet was loaded")
        await shot(main.window, "secure-11-pictures-in-decrypted")
        press(main.mailbox.reader.picturesDownload)
        check(await waitUntil(15) { bar?.isHidden == true }, "after the click the bar goes")
        let after = await waitFor(10) { () async -> SecurePage? in
            let now = await securePage()
            return now.labels != blocked.labels && !now.labels.isEmpty ? now : nil
        }
        check(after != nil, "and the label says pictures were loaded (\(after?.labels ?? blocked.labels))")
        await removeFixture(uid)
        uid = try await showFixture("secure-pictures.eml")
        check(bar?.isHidden == false && !picturesLoaded, "opened again, it asks again")
        await removeFixture(uid)

        // a long part: as tall as it is, and it grows
        uid = try await showFixture("secure-long.eml")
        page = await securePage()
        check(page.heights.count == 1 && page.fits && page.texts.first?.contains("Line 40 of the long part") == true,
              "a long part's frame is as tall as its document, its last line shown (\(page.heights) for \(page.needed))")
        let first = page.heights.first ?? 0
        _ = await main.mailbox.reader.pageAnswer("[...document.querySelector('iframe.pe-d').contentDocument.querySelectorAll('details')]"
            + ".forEach(d=>d.open=true)")
        let unfolded = await waitFor(5) { () async -> SecurePage? in
            let now = await securePage()
            return (now.heights.first ?? 0) > first && now.fits ? now : nil
        }
        check(unfolded != nil, "it grows when \"...\" is unfolded (\(first) to \(unfolded?.heights.first ?? 0))")
        let size = main.window.contentLayoutRect.size
        main.window.setContentSize(NSSize(width: size.width - 300, height: size.height))
        // its lines are short: narrower, it stays as tall as its document, nothing cut off
        let narrower = await waitFor(5) { () async -> SecurePage? in
            let now = await securePage()
            return now.fits && now.heights.first.map({ $0 > 120 }) == true ? now : nil
        }
        check(narrower != nil, "made narrower, it is still as tall as its document (\(narrower?.heights ?? []))")
        await shot(main.window, "secure-12-resized")
        let zoom = TextSize.zoom
        TextSize.apply(zoom * 1.25)
        await pause(1)
        let larger = await securePage()
        check(larger.fits, "and with a larger text size (\(larger.heights) for \(larger.needed))")
        TextSize.apply(zoom)
        main.window.setContentSize(size)
        await removeFixture(uid)

        // dark: the bar keeps its colours readable
        let before = NSApp.appearance
        onMain { NSApp.appearance = NSAppearance(named: .darkAqua) }
        uid = try await showFixture("secure-encrypted.eml")
        await pause(0.5)
        check(contrast(securityBar) >= 4.5, "in dark mode the bar's words are readable on it (\(contrast(securityBar)))")
        await shot(main.window, "secure-13-dark")
        onMain { NSApp.appearance = before }
        await removeFixture(uid)
        try await secureInList()
    }

    /// the mark in the classic list's security column on row `index`
    func secureColumnMark(_ index: Int) -> NSImage? {
        let column = list.column(withIdentifier: NSUserInterfaceItemIdentifier("secure"))
        guard column >= 0, let cell = list.view(atColumn: column, row: index, makeIfNecessary: true) else { return nil }
        return views(NSImageView.self, in: cell).first?.image
    }

    /// the row of the list whose message is `uid`
    func listIndex(uid: UInt64) -> Int? {
        (0..<list.numberOfRows).first { main.mailbox.row($0)?.uid == uid }
    }

    /// the uids the list shows now
    var listedUids: Set<UInt64> {
        Set((0..<list.numberOfRows).compactMap { main.mailbox.row($0)?.uid })
    }

    /// encrypted and signed mail in the list and the search (19i): the lock and the rosette on their rows, in both
    /// layouts, light and dark; is:encrypted and is:signed; with Search in encrypted messages off its words are not
    /// found, on the background pass decrypts it without its being opened, and a protected Subject takes the place of
    /// the outer "..."
    func secureInList() async throws {
        step("encrypted mail in the list")
        let core = main.core
        onMain { core.searchEncrypted = false }
        await search("")
        selectFolder(named: "Inbox")
        try await addMessage("From: Alice Example <alice@example.org>\r\nTo: testuser@inboxclassic.test\r\n"
            + "Subject: Walk on Sunday\r\nMessage-ID: <plain-walk@example.org>\r\nDate: Sun, 01 Nov 2026 09:00:00 +0000\r\n\r\n"
            + "Shall we walk to the lake on Sunday?\r\n", flags: ["\\Seen"])
        let signed = try await addFixture("secure-signed.eml")
        let encrypted = try await addFixture("secure-encrypted.eml")
        command(.sync)
        guard let plainMessage = await waitFor(30, { () -> Message? in
            guard listIndex(uid: signed) != nil, listIndex(uid: encrypted) != nil else { return nil }
            return (0..<list.numberOfRows).compactMap { main.mailbox.row($0) }.first { $0.subject == "Walk on Sunday" }
        }) else {
            throw Failed(description: "the three messages are not in the list")
        }
        let plain = plainMessage.uid
        let row = { (uid: UInt64) in self.listIndex(uid: uid).flatMap { self.main.mailbox.row($0) } }
        check(row(encrypted)?.protection == PE_PROTECTION_ENCRYPTED && row(signed)?.protection == PE_PROTECTION_SIGNED
              && row(plain)?.protection == PE_PROTECTION_NONE,
              "the core knows each one's protection from its structure, before it is opened")
        let marks = { (uid: UInt64) in self.listIndex(uid: uid).flatMap { self.secureColumnMark($0) } }
        check(marks(encrypted) === Icons.encrypted && marks(signed) === Icons.signed && marks(plain) == nil,
              "the classic list's security column: the lock on the encrypted row, the rosette on the signed one, nothing on the plain one")
        let header = list.tableColumn(withIdentifier: NSUserInterfaceItemIdentifier("secure"))
        check(header?.headerToolTip == Text.headerSecurity.text && (header?.width ?? 99) <= 22,
              "a narrow column beside the flag's, its header the lock with a tooltip (\(header?.headerToolTip ?? ""))")
        let width = { (id: String) in self.list.tableColumn(withIdentifier: NSUserInterfaceItemIdentifier(id))?.width ?? 0 }
        check(width("subject") > width("from") && width("from") >= 150,
              "From and Subject keep their room (\(Int(width("from"))), \(Int(width("subject"))))")
        check(row(encrypted)?.subject == "..." && row(encrypted)?.snippet == Text.listEncrypted.text
              && row(encrypted)?.hasAttachments == false,
              "with Search in encrypted messages off, the encrypted row is the outer \"...\", \"Encrypted message\", no paper clip (\(row(encrypted)?.snippet ?? ""))")
        let tip = listIndex(uid: encrypted).flatMap { list.view(atColumn: list.column(withIdentifier: NSUserInterfaceItemIdentifier("secure")), row: $0, makeIfNecessary: true)?.toolTip }
        check(tip == Text.uiRowEncrypted.text, "its mark's tooltip says Encrypted (\(tip ?? ""))")
        // a signed row selected: its mark stays visible on the selection (the encrypted one would be opened)
        if let at = listIndex(uid: signed) {
            list.scrollRowToVisible(at)
            await selectRow(at)
        }
        await shot(main.window, "main-12-lock-in-list-classic")

        command(.layoutColumns)
        check(await waitUntil(10) { main.mailbox.layout == PE_LAYOUT_COLUMNS }, "the column layout")
        let cellOf = { (uid: UInt64) in self.listIndex(uid: uid).flatMap { self.rowCell($0) } }
        check(cellOf(encrypted)?.secureMark === Icons.encrypted && cellOf(signed)?.secureMark === Icons.signed
              && cellOf(plain)?.secureMark == nil,
              "its rows: the lock among the encrypted row's marks, the rosette among the signed one's, none on the plain one")
        let spoken = cellOf(encrypted)?.accessibilityLabel() ?? ""
        check(spoken.contains(Text.uiRowEncrypted.text) && spoken.contains(Text.listEncrypted.text)
              && (cellOf(signed)?.accessibilityLabel() ?? "").contains(Text.uiRowSigned.text),
              "a screen reader hears Encrypted and Signed (\(spoken))")
        await shot(main.window, "main-12-lock-in-list")
        let before = NSApp.appearance
        onMain { NSApp.appearance = NSAppearance(named: .darkAqua) }
        await pause(0.5)
        await shot(main.window, "main-12-lock-in-list-dark")
        command(.layoutClassic)
        _ = await waitUntil(10) { main.mailbox.layout == PE_LAYOUT_CLASSIC && list.headerView != nil }
        main.mailbox.placeDividers()
        await pause(0.5)
        await shot(main.window, "main-12-lock-in-list-classic-dark")
        onMain { NSApp.appearance = before }

        step("searching encrypted mail")
        await search("is:encrypted")
        check(listedUids == [encrypted], "is:encrypted lists the encrypted message alone (\(list.numberOfRows))")
        await search("is:signed")
        check(listedUids == [signed], "is:signed the signed one alone (\(list.numberOfRows))")
        await search("-is:encrypted")
        check(!listedUids.contains(encrypted) && listedUids.isSuperset(of: [signed, plain]),
              "-is:encrypted all but the encrypted one (\(list.numberOfRows))")
        await search("mill")
        check(!listedUids.contains(encrypted), "with the switch off, a word of its text (mill) finds nothing")
        await search("alice")
        check(listedUids.contains(encrypted), "while its envelope (alice) finds it")

        // on: the background pass decrypts what is downloaded, without its being opened
        final class Announced { var all: [(title: String, text: String)] = [] }
        let announced = Announced()
        TestHooks.notified = { title, text in announced.all.append((title, text)) }
        defer { TestHooks.notified = nil }
        onMain {
            core.searchEncrypted = true
            core.downloadAhead = PE_DOWNLOAD_AHEAD_RECENT
        }
        await search("")
        selectFolder(named: "Inbox")
        let raw = try String(contentsOf: pgpFixtures.appendingPathComponent("secure-protected-subject.eml"), encoding: .utf8)
        try await addMessage(raw)
        command(.sync)
        guard let protected = await waitFor(30, { () -> UInt64? in
            (0..<list.numberOfRows).compactMap { main.mailbox.row($0) }
                .first { $0.protection == PE_PROTECTION_ENCRYPTED && $0.uid != encrypted }?.uid
        }) else {
            throw Failed(description: "secure-protected-subject.eml is not in the list")
        }
        check(await waitUntil(30) { announced.all.contains { $0.text.contains(Text.listEncrypted.text) } }
              && announced.all.contains { "\($0.title) \($0.text)".contains("Alice Example") }
              && !announced.all.contains { $0.text.contains("mill") },
              "its new mail notification says \"Encrypted message\" (\(announced.all.map { "\($0.title): \($0.text)" }))")
        // the plain message selected while the encrypted ones change beside it
        if let at = listIndex(uid: plain) {
            await selectRow(at)
        }
        let scrolled = list.enclosingScrollView?.contentView.bounds.origin
        check(await waitUntil(60) { row(protected)?.subject == "The mill on Friday" },
              "secure-protected-subject.eml is listed by its protected Subject once decrypted, not \"...\" (\(row(protected)?.subject ?? ""))")
        check(await waitUntil(30) { row(encrypted)?.snippet != Text.listEncrypted.text && row(encrypted)?.snippet.isEmpty == false },
              "the encrypted row shows its first words, without the folder chosen again (\(row(encrypted)?.snippet ?? ""))")
        check(list.selectedRowIndexes.count == 1 && main.mailbox.row(list.selectedRow)?.uid == plain
              && list.enclosingScrollView?.contentView.bounds.origin == scrolled,
              "the selection and the scroll stay where they were as the rows change")
        check(await waitUntil(30) {
            await search("mill")
            return listedUids.contains(encrypted)
        }, "on again, the background pass decrypts it without its being opened: mill finds it")
        await shot(main.window, "search-9-encrypted")
        onMain { core.downloadAhead = PE_DOWNLOAD_AHEAD_NEVER }
        await search("")
        selectFolder(named: "Inbox")
        for uid in [encrypted, signed, protected, plain] {
            await removeFixture(uid)
        }
    }

    /// What the previews of a signed or encrypted message's page are: the page's own, and each frame's pictures
    /// (loaded or not, where they are in the reading pane) and captions
    struct PartPreviews {
        var onPage = 0
        var frames: [(captions: [String], loaded: [Bool], rects: [NSRect])] = []
        var loaded: Bool { !frames.isEmpty && frames.allSatisfy { !$0.loaded.isEmpty && !$0.loaded.contains(false) } }
    }

    func partPreviews() async -> PartPreviews {
        let script = "(()=>{const pv=d=>[...d.images].filter(i=>(i.getAttribute('src')||'').startsWith('/pv/'));"
            + "return JSON.stringify({page:pv(document).length+document.querySelectorAll('section[class^=pe-att]').length,"
            + "frames:[...document.querySelectorAll('iframe.pe-d')].map(f=>{const d=f.contentDocument;if(!d)return {c:[],l:[],r:[]};"
            + "const o=f.getBoundingClientRect();return {c:[...d.querySelectorAll('figcaption')].map(e=>e.textContent),"
            + "l:pv(d).map(i=>i.complete&&i.naturalWidth>0),r:pv(d).map(i=>{const b=i.getBoundingClientRect();"
            + "return [o.left+b.left,o.top+b.top,b.width,b.height]})}})})})()"
        let answer = await main.mailbox.reader.pageAnswer(script)
        guard let object = try? JSONSerialization.jsonObject(with: Data(answer.utf8)) as? [String: Any] else {
            return PartPreviews()
        }
        var shown = PartPreviews()
        shown.onPage = object["page"] as? Int ?? -1
        for frame in object["frames"] as? [[String: Any]] ?? [] {
            let rects = (frame["r"] as? [[NSNumber]] ?? []).filter { $0.count == 4 }.map {
                NSRect(x: $0[0].doubleValue, y: $0[1].doubleValue, width: $0[2].doubleValue, height: $0[3].doubleValue)
            }
            shown.frames.append((frame["c"] as? [String] ?? [], frame["l"] as? [Bool] ?? [], rects))
        }
        return shown
    }

    /// previews in signed and encrypted mail (after the encrypted message's attachment, whose note is shown once): a
    /// plain part's picture and an encrypted part's, each in its part's frame, which is as tall as its part; the
    /// encrypted one opens decrypted; both printed after the text, named with their parts
    func securePreviews() async throws {
        step("previews in signed and encrypted mail")
        let reader = main.mailbox.reader
        let uid = try await showFixture("secure-previews.eml")
        guard let web = readerWeb else { throw Failed(description: "no reading pane") }
        _ = await waitUntil(20) {
            let now = await self.partPreviews()
            return now.loaded && now.frames.count == 2
        }
        let shown = await partPreviews()
        check(shown.onPage == 0, "the page itself has no preview (\(shown.onPage))")
        check(shown.frames.count == 2 && shown.frames[0].loaded == [true] && shown.frames[1].loaded == [true],
              "each of the two frames shows its picture (\(shown.frames.map(\.loaded)))")
        check(shown.frames.first?.captions.first?.hasPrefix("harbour.png") == true
              && shown.frames.last?.captions.first?.hasPrefix("floor-plan.png") == true,
              "frame 1 (the plain part) harbour.png, frame 2 (the encrypted part) floor-plan.png (\(shown.frames.map(\.captions)))")
        check(reader.strip.files.map(\.name) == ["harbour.png", "floor-plan.png"], "the strip lists both (\(reader.strip.files.map(\.name)))")
        check(securityBar.said.contains("2 parts: 1 encrypted, 1 without a confirmed signature"),
              "the bar counts 2 parts: 1 encrypted, 1 without a confirmed signature (\(securityBar.said))")
        // the strip says each file's part: the floor plan of the encrypted part with the lock, the harbour without
        let tiles = reader.strip.tiles
        let partOf = { (tile: AttachmentTile) in (tile.showsLock, tile.accessibilityHelp() ?? "", tile.toolTip ?? "") }
        if tiles.count == 2 {
            let (harbourLock, harbourHelp, harbourTip) = partOf(tiles[0])
            let (floorLock, floorHelp, floorTip) = partOf(tiles[1])
            check(floorLock && floorHelp.hasSuffix("From part 2: Encrypted. Not signed")
                  && floorTip.hasSuffix("From part 2: Encrypted. Not signed"),
                  "floor-plan.png has the lock, its tooltip and accessible help end \"From part 2: Encrypted. Not signed\" (\(floorHelp))")
            check(!harbourLock && harbourHelp.hasSuffix("From part 1: Not signed") && harbourTip.hasSuffix("From part 1: Not signed"),
                  "harbour.png has no lock, \"From part 1: Not signed\" (\(harbourHelp))")
        } else {
            check(false, "two tiles in the strip (\(tiles.count))")
        }
        await shot(main.window, "secure-15-strip-parts")
        _ = await waitUntil(5) {
            let page = await self.securePage()
            return page.fits && page.heights.count == 2
        }
        let page = await securePage()
        check(page.fits && page.heights.count == 2,
              "each frame as tall as its part once the pictures are there (\(page.heights) for \(page.needed))")
        // the pictures are the parts' own: the harbour's sky in frame 1, the floor plan's shaded room in frame 2
        var colours: [NSColor?] = []
        for index in shown.frames.indices {
            await inPage(web, "document.querySelectorAll('iframe.pe-d')[\(index)].scrollIntoView({block:'center'})")
            await pause(0.3)
            let now = await partPreviews()
            guard index < now.frames.count, let at = now.frames[index].rects.first else { continue }
            // the shaded room and the sky are both at 90, 75 of 240 by 150
            colours.append(await webPixel(web, NSPoint(x: at.minX + at.width * 0.375, y: at.minY + at.height * 0.5 - (index == 0 ? at.height * 0.25 : 0))))
        }
        let sky = colours.first.flatMap { $0 }, room = colours.last.flatMap { $0 }
        check(colours.count == 2 && sky.map { $0.blueComponent > $0.redComponent + 0.2 } == true
              && room.map { $0.redComponent > 0.75 && $0.blueComponent > $0.redComponent + 0.05 } == true,
              "frame 1 draws the harbour's sky, frame 2 the floor plan's shaded room (\(colours))")
        // the encrypted part in view, its label and its picture, under the end of the plain one
        await inPage(web, "document.querySelectorAll('iframe.pe-d')[1].scrollIntoView({block:'end'})")
        await pause(0.3)
        await shot(main.window, "secure-14-attachment-previews")

        // a click on the floor plan in frame 2 opens it, decrypted; the note was shown once already (attach-4)
        var opened: [URL] = []
        TestHooks.openFile = { opened.append($0) }
        defer { TestHooks.openFile = nil }
        _ = await reader.pageAnswer("document.querySelectorAll('iframe.pe-d')[1].contentDocument.querySelector('section[class^=pe-att] a').click()")
        var noted = false
        if let note = await waitWindow("alert", 3) {
            noted = true
            answer(note, Text.uiOk.text)
        }
        check(await waitUntil(10) { opened.count == 1 }, "clicking the floor plan in frame 2 opens it")
        check(!noted, "without the decrypted-file note, shown once already (attach-4)")
        // its pixels as they are in the file (no colour matching): the shaded room at 90, 75 of 240 by 150
        let floor = opened.last.flatMap { try? Data(contentsOf: $0) }.flatMap { NSBitmapImageRep(data: $0) }
        var pixel = [Int](repeating: 0, count: 4)
        floor?.getPixel(&pixel, atX: 90, y: 75)
        check(opened.last?.lastPathComponent == "floor-plan.png" && floor?.pixelsWide == 240 && floor?.pixelsHigh == 150
              && pixel.prefix(3) == [214, 228, 247],
              "decrypted, the floor plan as it was sealed (\(opened.last?.lastPathComponent ?? "none"), \(pixel.prefix(3)))")
        checkPrivate(opened.last, "from a private folder")
        _ = await reader.pageAnswer("document.querySelectorAll('iframe.pe-d')[0].contentDocument.querySelector('section[class^=pe-att] a').click()")
        check(await waitUntil(10) { opened.count == 2 } && opened.last?.lastPathComponent == "harbour.png",
              "the harbour in frame 1 opens the harbour (\(opened.last?.lastPathComponent ?? "none"))")

        // Print: both pictures after the text, each named with its part
        let pdf = out.appendingPathComponent("secure-previews-print.pdf")
        try? FileManager.default.removeItem(at: pdf)
        var printed = false
        var document = ""
        TestHooks.printTo = pdf
        TestHooks.printed = { printed = $0 }
        TestHooks.printDocument = { document = $0 }
        reader.print()
        _ = await waitUntil(40) { printed }
        TestHooks.printTo = nil
        TestHooks.printed = nil
        TestHooks.printDocument = nil
        let paper = (PDFDocument(url: pdf)?.string ?? "").replacingOccurrences(of: "\n", with: " ")
        say("   printed: \(paper.prefix(300))")
        let order = ["as promised", "Part 1: harbour.png", "for your eyes only", "Part 2: floor-plan.png"].map {
            paper.range(of: $0)?.lowerBound
        }
        check(printed && !order.contains(nil) && zip(order, order.dropFirst()).allSatisfy { $0! < $1! },
              "Print gives each part's picture after that part's text, \"Part 1: harbour.png\" before part 2's text")
        check(document.components(separatedBy: "src=\"data:image/").count == 3 && !document.contains("/pv/"),
              "the printout carries both pictures from memory, nothing from the preview path")

        try await twoReaders()

        // dark: the frames and the bar as they are at night
        let before = NSApp.appearance
        onMain { NSApp.appearance = NSAppearance(named: .darkAqua) }
        await pause(0.8)
        await shot(main.window, "secure-14-attachment-previews-dark")
        onMain { NSApp.appearance = before }
        await removeFixture(uid)
    }

    /// the message shown in the reading pane and in a window of its own; dark messages turned off and on again make
    /// both again, and each gets its view: neither says the message could not be shown
    func twoReaders() async throws {
        let notShown = Text.uiNotShown.text
        main.window.makeFirstResponder(list)
        let enter = NSEvent.keyEvent(with: .keyDown, location: .zero, modifierFlags: [], timestamp: 0, windowNumber: main.window.windowNumber,
                                     context: nil, characters: "\r", charactersIgnoringModifiers: "\r", isARepeat: false, keyCode: 36)
        onMain { if let enter { self.list.keyDown(with: enter) } }
        guard let window = await waitWindow("message", 10), let own = MessageWindow.open.last else {
            check(false, "Enter opens the message in a window of its own")
            return
        }
        let readers = [main.mailbox.reader, own.reader]
        let headers = [main.window, window].map { find("reader.header", in: $0) as NSTextField? }
        _ = await waitUntil(15) { readers.allSatisfy { $0.messageView != nil } }
        for dark in [false, true] {
            main.core.darkMessages = dark
            Preview.dark = dark
            AppDelegate.shared?.main?.reloadMessagesShown()
            let both = await waitUntil(15) {
                readers.allSatisfy { $0.messageView != nil && !$0.waitingForView }
            }
            let said = headers.map { $0?.stringValue ?? "" }
            check(both && !said.contains { $0.contains(notShown) },
                  "dark messages \(dark ? "on" : "off"): the pane and the window each show the message (\(said.map { $0.prefix(40) }))")
        }
        onMain { window.performClose(nil) }
        _ = await waitUntil(10) { !window.isVisible }
    }

    /// Print of the message shown: every part's text on the paper
    func checkPrinted(_ page: SecurePage) async {
        let pdf = out.appendingPathComponent("secure-print.pdf")
        try? FileManager.default.removeItem(at: pdf)
        var printed = false
        TestHooks.printTo = pdf
        TestHooks.printed = { printed = $0 }
        main.mailbox.reader.print()
        _ = await waitUntil(20) { printed }
        TestHooks.printTo = nil
        TestHooks.printed = nil
        let size = (try? FileManager.default.attributesOfItem(atPath: pdf.path)[.size] as? Int) ?? 0
        check(size > 0 && size < 20_000_000, "the printed file is of a sensible size (\(size) bytes)")
        let paper = (PDFDocument(url: pdf)?.string ?? "").replacingOccurrences(of: "\n", with: " ")
        let words = page.texts.map { $0.split(whereSeparator: \.isWhitespace).prefix(3).joined(separator: " ") }
        say("   printed: \(paper.prefix(300))")
        check(printed && page.labels.allSatisfy { paper.contains($0) }, "Print puts every part's label on the paper")
        // the core's printout: every part's text, as no frame prints
        check(!words.isEmpty && words.allSatisfy { paper.contains($0) } && paper.contains("Part 2"),
              "and every part's text, the parts named (\(words))")
    }

    /// the contrast of the bar's words on its fill, as it is drawn now
    func contrast(_ bar: SecurityBar) -> Double {
        var ratio = 0.0
        bar.effectiveAppearance.performAsCurrentDrawingAppearance {
            guard let fill = bar.layer?.backgroundColor.flatMap({ NSColor(cgColor: $0) }),
                  let words = (find(bar.accessibilityIdentifier() + ".words", in: bar) as NSTextField?)?.textColor else { return }
            func luminance(_ color: NSColor) -> Double {
                guard let c = color.usingColorSpace(.sRGB) else { return 0 }
                let linear = { (v: CGFloat) -> Double in
                    let v = Double(v)
                    return v <= 0.03928 ? v / 12.92 : pow((v + 0.055) / 1.055, 2.4)
                }
                return 0.2126 * linear(c.redComponent) + 0.7152 * linear(c.greenComponent) + 0.0722 * linear(c.blueComponent)
            }
            let (a, b) = (luminance(fill), luminance(words))
            ratio = (max(a, b) + 0.05) / (min(a, b) + 0.05)
        }
        return ratio
    }
}
