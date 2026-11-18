// The UI end-to-end test's step of opening attachments (8a of scripts/ui-e2e/SCENARIO.md): the strip under the header
// with each file's icon, name and size; a double-click, and the keyboard, opening a file from the private folder (the
// system's open replaced by TestHooks.openFile, so nothing launches); the menu of a file; a program refused; the strip
// of a message's own window; and an encrypted message's file, with its note the first time only.
import AppKit
import CInboxClassic

extension UITest {
    /// the bytes of the PDF the step's message carries
    var tripPdf: Data { Data("%PDF-1.4\n% the itinerary of the Mac UI test\n%%EOF\n".utf8) }

    /// `raw` put in the Inbox over ImapKit's API, read; its uid there
    func postMessage(_ raw: String) async throws -> UInt64 {
        var request = URLRequest(url: URL(string: "\(rest)/INBOX/messages")!)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: ["raw": raw, "flags": ["\\Seen"]])
        let (data, _) = try await URLSession.shared.data(for: request)
        let answer = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        guard let uid = (answer?["uid"] as? NSNumber)?.uint64Value else {
            throw Failed(description: "ImapKit did not take the message")
        }
        return uid
    }

    /// the message `uid` of the Inbox selected and shown in the reading pane
    func showInbox(_ uid: UInt64) async throws {
        selectFolder(named: "Inbox")
        command(.sync)
        guard let row = await waitFor(30, { (0..<list.numberOfRows).first { main.mailbox.row($0)?.uid == uid } }) else {
            throw Failed(description: "message \(uid) is not in the list")
        }
        list.scrollRowToVisible(row)
        await selectRow(row)
        _ = await waitUntil(20) { main.mailbox.reader.uid == uid && main.mailbox.reader.messageView != nil }
    }

    /// a double-click on a file of `strip`, after this returns: what it shows may run modally
    func doubleClick(_ strip: AttachmentStrip, _ index: Int) {
        guard index < strip.tiles.count, let window = strip.window else { return }
        let tile = strip.tiles[index]
        let point = tile.convert(NSPoint(x: tile.bounds.midX, y: tile.bounds.midY), to: nil)
        let event = NSEvent.mouseEvent(with: .leftMouseDown, location: point, modifierFlags: [], timestamp: 0,
                                       windowNumber: window.windowNumber, context: nil, eventNumber: 0, clickCount: 2, pressure: 1)
        onMain { if let event { tile.mouseDown(with: event) } }
    }

    /// a key pressed in `window`, as the keyboard sends it
    func pressKey(_ window: NSWindow, _ keyCode: UInt16, _ characters: String) {
        let event = NSEvent.keyEvent(with: .keyDown, location: .zero, modifierFlags: [], timestamp: 0, windowNumber: window.windowNumber,
                                     context: nil, characters: characters, charactersIgnoringModifiers: characters, isARepeat: false,
                                     keyCode: keyCode)
        event.map(window.sendEvent)
    }

    /// the folder the core makes private folders in (`.../InboxClassic`)
    var privateRoot: URL? {
        guard let made = taken(pe_private_folder(main.core.handle, "ui-test")) else { return nil }
        let folder = URL(fileURLWithPath: made)
        try? FileManager.default.removeItem(at: folder)
        return folder.deletingLastPathComponent().standardizedFileURL
    }

    /// `url` a file of a new private folder: the user's alone, marked as from the internet
    func checkPrivate(_ url: URL?, _ what: String) {
        guard let url else { return check(false, what) }
        let folder = url.deletingLastPathComponent()
        let mode = (try? FileManager.default.attributesOfItem(atPath: folder.path)[.posixPermissions] as? Int) ?? 0
        let quarantine = (try? url.resourceValues(forKeys: [.quarantinePropertiesKey]))?.quarantineProperties
        check(folder.deletingLastPathComponent().standardizedFileURL == privateRoot && folder.lastPathComponent.hasPrefix("open-")
              && mode & 0o077 == 0 && quarantine != nil,
              "\(what) (\(url.path), mode \(String(mode, radix: 8)), quarantined \(quarantine != nil))")
    }

    func openingAttachments() async throws {
        step("opening an attachment")
        await search("")
        let base64 = { (data: Data) in data.base64EncodedString(options: .lineLength76Characters) }
        let part = { (type: String, name: String, data: Data) in
            "--trip\r\nContent-Type: \(type); name=\"\(name)\"\r\nContent-Disposition: attachment; filename=\"\(name)\"\r\n"
                + "Content-Transfer-Encoding: base64\r\n\r\n\(base64(data))\r\n"
        }
        let longName = "Photos from the lake on Saturday 4 October, full size.jpg"
        let raw = "From: Ann Example <ann@example.com>\r\nTo: testuser@inboxclassic.test\r\nSubject: Plans for the autumn trip\r\n"
            + "Message-ID: <trip@example.com>\r\nDate: Thu, 9 Oct 2025 09:30:00 +0000\r\nMIME-Version: 1.0\r\n"
            + "Content-Type: multipart/mixed; boundary=\"trip\"\r\n\r\n"
            + "--trip\r\nContent-Type: text/plain; charset=utf-8\r\n\r\nHi Alex,\r\n\r\nthe itinerary is attached, and the installer "
            + "of the map app the guide asked us to use.\r\n\r\nAnn\r\n"
            + part("application/pdf", "Itinerary.pdf", tripPdf)
            + part("application/x-msdownload", "setup.exe", Data("MZ, a program of the Mac UI test".utf8))
            + part("image/jpeg", longName, Data(repeating: 0xd8, count: 48_000))
            + part("application/vnd.openxmlformats-officedocument.spreadsheetml.sheet", "Budget 2026.xlsx", Data(repeating: 0x50, count: 9_000))
            // pages, which a browser would run the scripts of: one by its extension, one by what it holds
            + part("application/octet-stream", "statement.xht", Data("<p>a statement</p>\n".utf8))
            + part("application/octet-stream", "statement", Data("<!DOCTYPE html><html><script>alert(1)</script></html>\n".utf8))
            + "--trip--\r\n"
        let uid = try await postMessage(raw)
        try await showInbox(uid)
        let reader = main.mailbox.reader
        let strip = reader.strip
        check(await waitUntil(10) { !strip.isHidden && strip.files.count == 6 }, "the strip under the header shows the six files")
        check(strip.files.map(\.name) == ["Itinerary.pdf", "setup.exe", longName, "Budget 2026.xlsx", "statement.xht", "statement"]
              && strip.files.map(\.kind) == [PE_FILE_KIND_PDF, PE_FILE_KIND_PROGRAM, PE_FILE_KIND_IMAGE, PE_FILE_KIND_SPREADSHEET,
                                              PE_FILE_KIND_PROGRAM, PE_FILE_KIND_PROGRAM]
              && strip.files.allSatisfy { !$0.sizeText.isEmpty } && strip.tiles.allSatisfy { $0.toolTip?.hasPrefix($0.file.name) == true },
              "each with its icon, name and size, the whole name in its tooltip (\(strip.files.map { "\($0.name) \($0.kind.rawValue) \($0.sizeText)" }))")
        let header: NSTextField? = find("reader.header", in: main.window)
        if let header, let first = strip.tiles.first {
            let headerLeft = header.convert(header.bounds, to: nil).minX
            let tileTop = first.convert(first.bounds, to: nil).maxY
            let headerBottom = header.convert(header.bounds, to: nil).minY
            check(tileTop <= headerBottom, "the strip is under the header (\(tileTop) under \(headerBottom), header at \(headerLeft))")
        }
        let long = strip.tiles[2]
        check(long.frame.width <= 220 && long.toolTip?.hasPrefix(longName) == true, "a long name is shortened, whole in its tooltip")
        await shot(main.window, "attach-1-strip")

        // a double-click opens the PDF: the file the system is handed is in a private folder, as it was sent
        var opened: [URL] = []
        TestHooks.openFile = { opened.append($0) }
        defer { TestHooks.openFile = nil }
        doubleClick(strip, 0)
        check(await waitUntil(10) { opened.count == 1 }, "double-clicking the PDF opens it")
        check(opened.first.flatMap { try? Data(contentsOf: $0) } == tripPdf && opened.first?.lastPathComponent == "Itinerary.pdf",
              "the file handed to the system is byte for byte what was sent, under its name")
        checkPrivate(opened.first, "in a new private folder of the user's, marked as from the internet")
        check(window("alert") == nil, "a message that is not encrypted opens without a note")
        // opened again: the same file, no second copy
        doubleClick(strip, 0)
        check(await waitUntil(10) { opened.count == 2 } && opened.last == opened.first, "opened again, the same file is handed over")

        // the menu: Open, Save As, Save All; a program's Open greyed
        let menu = strip.menu(for: strip.tiles[0])
        let titles = menu.items.filter { !$0.isSeparatorItem }.map(\.title)
        check(titles == ["Open", "Save As\u{2026}", "Save All\u{2026}", Text.uiAttachmentShowInMessage.text] && menu.items[0].isEnabled,
              "a right-click offers Open, Save As\u{2026} and Save All\u{2026}, and Show in Message for the PDF file (\(titles))")
        await menuShot(strip, "attach-2-menu")
        let programMenu = strip.menu(for: strip.tiles[1])
        check(programMenu.items.first?.isEnabled == false && programMenu.items.dropFirst().allSatisfy { $0.isSeparatorItem || $0.isEnabled },
              "the program's Open is greyed; it can be saved")
        check(strip.tiles[1].toolTip?.contains(Text.uiAttachmentProgramTip.text) == true, "and its tooltip says why")
        for page in [4, 5] {
            let name = strip.files[page].name
            check(strip.menu(for: strip.tiles[page]).items.first?.isEnabled == false, "a page's Open is greyed (\(name))")
            doubleClick(strip, page)
            if let refused = await waitWindow("alert", 10) {
                let words = alertText(refused)
                check(words.contains("\u{201C}\(name)\u{201D}") && words.contains("can run programs"),
                      "opening \(name) is refused, naming it (\(words))")
                answer(refused, "OK")
                _ = await waitUntil(5) { self.window("alert") == nil }
            } else {
                check(false, "opening \(name) says why")
            }
        }
        if let saveAs = programMenu.items.first(where: { $0.title.hasPrefix("Save As") }), let action = saveAs.action {
            let target = out.appendingPathComponent("setup-saved.exe")
            try? FileManager.default.removeItem(at: target)
            var suggested: String?
            TestHooks.save = { name in
                suggested = name
                return target
            }
            onMain { NSApp.sendAction(action, to: saveAs.target, from: saveAs) }
            check(await waitUntil(10) { FileManager.default.fileExists(atPath: target.path) } && suggested == "setup.exe",
                  "its Save As saves it, under its own name (\(suggested ?? "nothing asked"))")
            TestHooks.save = nil
        }

        // the program: double-clicked, it says why and nothing opens
        doubleClick(strip, 1)
        if let refused = await waitWindow("alert", 10) {
            let words = alertText(refused)
            check(words.contains("can run programs") && words.contains("setup.exe"), "trying to open the program says it can run programs (\(words))")
            await shot(refused, "attach-3-refused")
            answer(refused, "OK")
            _ = await waitUntil(5) { self.window("alert") == nil }
        } else {
            check(false, "trying to open the program says why")
        }
        check(opened.count == 2, "and nothing is opened")

        // the keyboard: Tab reaches the strip, the arrows move, Enter opens
        let window = main.window
        // as for a message just shown: no file chosen yet
        strip.select(nil)
        window.makeFirstResponder(list)
        var tabs = 0
        while window.firstResponder !== strip && tabs < 12 {
            pressTab(window)
            tabs += 1
        }
        check(window.firstResponder === strip && strip.selected == 0, "Tab reaches the strip, its first file chosen (\(tabs) presses)")
        let right = String(UnicodeScalar(NSRightArrowFunctionKey)!)
        let left = String(UnicodeScalar(NSLeftArrowFunctionKey)!)
        pressKey(window, 124, right)
        pressKey(window, 124, right)
        check(strip.selected == 2, "the right arrow moves to the next file (\(strip.selected ?? -1))")
        pressKey(window, 123, left)
        pressKey(window, 123, left)
        check(strip.selected == 0, "the left arrow back (\(strip.selected ?? -1))")
        await shot(window, "attach-5-keyboard")
        // after this returns: a file that is refused says so modally
        onMain { self.pressKey(window, 36, "\r") }
        check(await waitUntil(10) { opened.count == 3 }, "Enter opens the file chosen")
        check(opened.last.flatMap { try? Data(contentsOf: $0) } == tripPdf && opened.last == opened.first,
              "the same file as before, while it is there")

        // dark: the strip keeps its look
        let before = NSApp.appearance
        onMain { NSApp.appearance = NSAppearance(named: .darkAqua) }
        await pause(0.5)
        await shot(window, "attach-6-dark")
        onMain { NSApp.appearance = before }
        await pause(0.3)

        // a message's own window has the strip, and opens the same way
        window.makeFirstResponder(list)
        let enter = NSEvent.keyEvent(with: .keyDown, location: .zero, modifierFlags: [], timestamp: 0, windowNumber: window.windowNumber,
                                     context: nil, characters: "\r", charactersIgnoringModifiers: "\r", isARepeat: false, keyCode: 36)
        onMain { if let enter { self.list.keyDown(with: enter) } }
        if let shown = await waitWindow("message", 10), let own = MessageWindow.open.last {
            let ownStrip = own.reader.strip
            check(await waitUntil(15) { !ownStrip.isHidden && ownStrip.files.count == 6 }, "in a message's own window the strip is there")
            doubleClick(ownStrip, 0)
            check(await waitUntil(10) { opened.count == 4 }, "and opens the same way")
            check(opened.last.flatMap { try? Data(contentsOf: $0) } == tripPdf, "the same file")
            await pause(0.5)
            await shot(shown, "attach-7-window")
            let size = shown.frame.size
            shown.setContentSize(NSSize(width: 520, height: shown.contentLayoutRect.height))
            await pause(0.5)
            let rows = Set(ownStrip.tiles.map(\.frame.minY)).count
            check(rows > 1 && ownStrip.tiles.allSatisfy { $0.frame.maxX <= ownStrip.bounds.width },
                  "made narrower, the files wrap into rows (\(rows))")
            await shot(shown, "attach-8-wrapped")
            shown.setFrame(NSRect(origin: shown.frame.origin, size: size), display: true)
            onMain { shown.performClose(nil) }
            _ = await waitUntil(10) { !shown.isVisible }
        } else {
            check(false, "Enter opens the message in a window of its own")
        }
        await removeFixture(uid)
    }

    /// the menu of the file chosen, as it pops up under it, drawn into a picture of the window
    func menuShot(_ strip: AttachmentStrip, _ name: String, file index: Int = 0) async {
        let window = strip.window ?? main.window
        var shown: NSWindow?
        let opens = NotificationCenter.default.addObserver(forName: NSMenu.didBeginTrackingNotification, object: nil, queue: nil) { _ in
            MainActor.assumeIsolated {
                shown = NSApp.windows.first { $0.isVisible && $0 !== window && String(describing: Swift.type(of: $0)).contains("Menu") }
            }
        }
        defer { NotificationCenter.default.removeObserver(opens) }
        window.makeFirstResponder(strip)
        strip.select(index)
        // should the test not run while the menu tracks, the menu closes by itself
        let closing = Timer(timeInterval: 4, repeats: false) { _ in MainActor.assumeIsolated { strip.shownMenu?.cancelTracking() } }
        RunLoop.main.add(closing, forMode: .common)
        defer { closing.invalidate() }
        onMain { strip.showMenu() }
        _ = await waitUntil(3) { shown != nil }
        await pause(0.5)
        if shown == nil {
            shown = NSApp.windows.first { $0.isVisible && $0 !== window && String(describing: Swift.type(of: $0)).contains("Menu") }
        }
        await shot(window, name)
        if let menu = shown, let content = menu.contentView, let rep = content.bitmapImageRepForCachingDisplay(in: content.bounds) {
            content.cacheDisplay(in: content.bounds, to: rep)
            let file = out.appendingPathComponent("\(name).png")
            if let picture = NSImage(contentsOf: file) {
                let composed = NSImage(size: picture.size)
                composed.lockFocus()
                picture.draw(at: .zero, from: .zero, operation: .copy, fraction: 1)
                let at = NSPoint(x: menu.frame.minX - window.frame.minX, y: menu.frame.minY - window.frame.minY)
                let frame = NSRect(origin: at, size: menu.frame.size)
                // the menu's material is drawn by the window server: its fill and edge, as the system draws them
                window.effectiveAppearance.performAsCurrentDrawingAppearance {
                    let shape = NSBezierPath(roundedRect: frame.insetBy(dx: 0.5, dy: 0.5), xRadius: 8, yRadius: 8)
                    NSGraphicsContext.saveGraphicsState()
                    let shadow = NSShadow()
                    shadow.shadowBlurRadius = 12
                    shadow.shadowOffset = NSSize(width: 0, height: -4)
                    shadow.shadowColor = NSColor.black.withAlphaComponent(0.25)
                    shadow.set()
                    NSColor.windowBackgroundColor.setFill()
                    shape.fill()
                    NSGraphicsContext.restoreGraphicsState()
                    NSColor.separatorColor.setStroke()
                    shape.stroke()
                }
                rep.draw(in: frame)
                composed.unlockFocus()
                if let tiff = composed.tiffRepresentation, let png = NSBitmapImageRep(data: tiff)?.representation(using: .png, properties: [:]) {
                    try? png.write(to: file)
                }
            }
            say("   the menu drawn into \(name)")
        } else {
            say("   the menu's window was not found: \(name) shows the window alone (\(NSApp.windows.map { String(describing: Swift.type(of: $0)) }))")
        }
        strip.shownMenu?.cancelTracking()
        _ = await waitUntil(3) { strip.shownMenu == nil }
        await pause(0.3)
    }

    /// an encrypted message's file: it opens, the first time with a note that it is stored decrypted (after 19i, whose
    /// keys it is encrypted to)
    func encryptedAttachment() async throws {
        step("an encrypted message's attachment")
        let uid = try await showFixture("secure-attachment.eml")
        let strip = main.mailbox.reader.strip
        check(await waitUntil(10) { strip.files.map(\.name) == ["plan.txt"] }, "the encrypted message's file shows in the strip (\(strip.files.map(\.name)))")
        var opened: [URL] = []
        TestHooks.openFile = { opened.append($0) }
        defer { TestHooks.openFile = nil }
        doubleClick(strip, 0)
        if let note = await waitWindow("alert", 10) {
            let words = alertText(note)
            check(words.contains(Text.uiAttachmentNoteTitle.text) && words.contains(Text.attachmentDecryptedNote.text),
                  "the first time the localized attachment warning is shown (\(words))")
            check(opened.isEmpty, "shown before the file is opened")
            await shot(note, "attach-4-encrypted-note")
            answer(note, "OK")
        } else {
            check(false, "the first time a note says it is stored decrypted")
        }
        check(await waitUntil(10) { opened.count == 1 }, "then the file opens")
        let saved = opened.first.flatMap { try? String(contentsOf: $0, encoding: .utf8) } ?? ""
        check(saved.contains("the secret plan, in a file"), "decrypted, as it was written (\(saved))")
        checkPrivate(opened.first, "in a private folder of the user's")
        _ = await waitUntil(5) { self.window("alert") == nil }
        doubleClick(strip, 0)
        check(await waitUntil(10) { opened.count == 2 }, "opened again, it opens")
        check(window("alert") == nil, "the second time without the note")
        await removeFixture(uid)
    }
}
