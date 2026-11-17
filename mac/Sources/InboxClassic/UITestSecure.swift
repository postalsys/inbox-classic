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
        check(securityBar.said.contains("key verified"), "\"key verified\" (\(securityBar.said))")
        _ = await waitUntil(5) { (await securePage()).labels.first?.contains("verified") == true }
        await shot(main.window, "secure-1-verified")
        await removeFixture(uid)

        // encrypted to the user's key and signed: the lock
        uid = try await showFixture("secure-encrypted.eml")
        page = await securePage()
        checkBar(PE_PROTECTION_TONE_VERIFIED, encrypted: true, "an encrypted message: the bar has the lock")
        check(securityBar.said.hasPrefix("Encrypted. Signed by alice@example.org") && securityBar.said.contains("key verified"),
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
        check(page.heights.count == 3 && page.labels.count == 3 && page.labels[0] == "Not signed"
              && page.labels[1].contains("alice@example.org") && page.labels[2] == "Not signed",
              "three frames, each with its own label (\(page.labels))")
        check(page.fits, "each as tall as its document (\(page.heights) for \(page.needed))")
        await shot(main.window, "secure-4-mixed-parts")
        await checkPrinted(page)
        await removeFixture(uid)

        // what is not right: amber with the warning sign; a key not known: grey
        uid = try await showFixture("secure-bad.eml")
        checkBar(PE_PROTECTION_TONE_WARNING, encrypted: false, "a changed text: amber with the warning sign")
        check(securityBar.said.contains("does not match"), "\"does not match\" (\(securityBar.said))")
        await shot(main.window, "secure-5-bad-signature")
        await removeFixture(uid)
        uid = try await showFixture("secure-wrong-signer.eml")
        checkBar(PE_PROTECTION_TONE_WARNING, encrypted: false, "signed by someone else: amber with the warning sign")
        check(securityBar.said.contains("mallory@example.net") && securityBar.said.contains("not the sender"),
              "names mallory@example.net, \"who is not the sender\" (\(securityBar.said))")
        await shot(main.window, "secure-6-wrong-signer")
        await removeFixture(uid)
        uid = try await showFixture("secure-no-key.eml")
        checkBar(PE_PROTECTION_TONE_NEUTRAL, encrypted: false, "a key not known: grey, no picture")
        check(securityBar.said == "Signed, but the key is not known", "\"Signed, but the key is not known\" (\(securityBar.said))")
        await shot(main.window, "secure-7-no-key")
        await removeFixture(uid)

        // a label painted in a part stays in its frame, under the real one
        uid = try await showFixture("secure-fake-frame.eml")
        page = await securePage()
        check(securityBar.said.contains("2 parts"), "a painted label: the bar counts 2 parts (\(securityBar.said))")
        check(page.labels.count == 2 && page.labels[0] == "Not signed" && page.labels[1].contains("alice@example.org"),
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
                  let words = (find("reader.security.words", in: bar) as NSTextField?)?.textColor else { return }
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
