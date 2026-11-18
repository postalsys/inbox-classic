// The UI end-to-end test's step of pictures and PDF files in the message (8b of scripts/ui-e2e/SCENARIO.md): the
// messages of scripts/ui-e2e/previews put in the Inbox over ImapKit's API, their previews after the text answered by
// the reading pane's document server, opened by a click and the keyboard, in a message's own window, the two
// settings, PDF files off as after one ended the app, dark mode, many pictures in a narrow pane, and the web view's
// context menu.
import AppKit
import CInboxClassic
import PDFKit
import WebKit

extension UITest {
    var previewFixtures: URL { repo.appendingPathComponent("scripts/ui-e2e/previews") }

    /// What the previews of a document are, read by a script of the app's
    struct PreviewsShown {
        /// each picture's address, whether it is loaded, its top, its width, its alt text
        var pictures: [(src: String, loaded: Bool, top: Int, width: Double, alt: String)] = []
        var captions: [String] = []
        var captionTops: [Int] = []
        /// the "Open to see all N pages" links
        var more: [String] = []
        var notice = ""
        var links = 0
        /// the document is wider than its view (a horizontal scroll bar)
        var wide = false
        var loaded: Bool { !pictures.isEmpty && pictures.allSatisfy(\.loaded) }
    }

    static let previewsScript = "(()=>{const s=document.querySelector('section[class^=pe-att]');"
        + "const all=s?[...s.querySelectorAll('*')]:[];const q=c=>all.filter(e=>e.matches(c));"
        + "const top=e=>Math.round(e.getBoundingClientRect().top+scrollY);"
        + "return JSON.stringify({p:[...document.images].filter(i=>(i.getAttribute('src')||'').startsWith('/pv/'))"
        + ".map(i=>[i.getAttribute('src'),i.complete&&i.naturalWidth>0,top(i),i.getBoundingClientRect().width,i.alt]),"
        + "c:q('figcaption').map(f=>f.textContent),ct:q('figcaption').map(top),m:q('a.m').map(a=>a.textContent),"
        + "w:q('.w').map(e=>e.textContent).join(''),l:q('a').length,"
        + "x:document.documentElement.scrollWidth>document.documentElement.clientWidth})})()"

    func previewsShown(_ web: WKWebView?) async -> PreviewsShown {
        guard let web, let answer = try? await web.evaluateJavaScript(Self.previewsScript) as? String,
              let object = try? JSONSerialization.jsonObject(with: Data(answer.utf8)) as? [String: Any] else {
            return PreviewsShown()
        }
        var shown = PreviewsShown()
        for row in object["p"] as? [[Any]] ?? [] where row.count == 5 {
            shown.pictures.append((row[0] as? String ?? "", row[1] as? Bool ?? false, row[2] as? Int ?? 0,
                                   (row[3] as? NSNumber)?.doubleValue ?? 0, row[4] as? String ?? ""))
        }
        shown.captions = object["c"] as? [String] ?? []
        shown.captionTops = object["ct"] as? [Int] ?? []
        shown.more = object["m"] as? [String] ?? []
        shown.notice = object["w"] as? String ?? ""
        shown.links = object["l"] as? Int ?? 0
        shown.wide = object["x"] as? Bool ?? false
        return shown
    }

    /// the fixture `name` put in the Inbox; its uid
    func addPreviewFixture(_ name: String) async throws -> UInt64 {
        try await postMessage(try String(contentsOf: previewFixtures.appendingPathComponent(name), encoding: .utf8))
    }

    /// the bytes of the file `name` the fixture `fixture` carries, decoded from its base64
    func fixtureFile(_ fixture: String, _ name: String) -> Data? {
        guard let raw = try? String(contentsOf: previewFixtures.appendingPathComponent(fixture), encoding: .utf8),
              let start = raw.range(of: "filename=\"\(name)\"") else { return nil }
        let rest = raw[start.upperBound...]
        guard let body = rest.range(of: "\n\n") ?? rest.range(of: "\r\n\r\n") else { return nil }
        let encoded = rest[body.upperBound...].prefix { $0 != "-" }
        return Data(base64Encoded: encoded.filter { !$0.isWhitespace })
    }

    /// waits until the document of `web` shows `count` previews, all loaded
    func previewsLoaded(_ web: WKWebView?, _ count: Int, _ seconds: Double = 30) async -> PreviewsShown {
        if let shown = await waitFor(seconds, {
            let shown = await previewsShown(web)
            return shown.pictures.count == count && shown.loaded ? shown : nil
        }) {
            return shown
        }
        return await previewsShown(web)
    }

    /// the colour of the pixel of `web` at `point` (in the view's coordinates, from its top left)
    func webPixel(_ web: WKWebView?, _ point: NSPoint) async -> NSColor? {
        guard let web, let picture = try? await web.takeSnapshot(configuration: nil),
              let data = picture.tiffRepresentation, let bitmap = NSBitmapImageRep(data: data) else { return nil }
        let scale = CGFloat(bitmap.pixelsWide) / web.bounds.width
        return bitmap.colorAt(x: Int(point.x * scale), y: Int(point.y * scale))?.usingColorSpace(.sRGB)
    }

    /// a script run in the reading pane's page (the app's own: the page's scripts are off)
    func inPage(_ web: WKWebView?, _ script: String) async {
        _ = try? await web?.evaluateJavaScript(script + ";0")
    }

    /// 4a: the newsletter's banner (a `cid:` picture, linked) drawn by the core and served from the preview path, on
    /// the paper as the core's own picture, and its link still copied from the web view's menu
    func picturesInText() async throws {
        step("pictures in the message drawn by Inbox Classic")
        guard let web = readerWeb else { throw Failed(description: "no reading pane") }
        let script = "JSON.stringify([...document.images].map(i=>[i.getAttribute('src')||'',i.complete&&i.naturalWidth>0,"
            + "Math.round(i.getBoundingClientRect().width),i.alt,Math.round(i.getBoundingClientRect().top+scrollY)]))"
        let images = { () async -> [[Any]] in
            let answer = (try? await web.evaluateJavaScript(script)) as? String ?? ""
            return (try? JSONSerialization.jsonObject(with: Data(answer.utf8)) as? [[Any]]) ?? []
        }
        let banner = { (rows: [[Any]]) in rows.first { $0.count == 5 && $0[3] as? String == "Trail Notes" } }
        _ = await waitUntil(15) { (banner(await images())?[1] as? Bool) == true }
        let rows = await images()
        let shown = banner(rows)
        let src = shown?[0] as? String ?? ""
        check(src.hasPrefix("/pv/"), "the banner sent inside the message comes from the preview path (\(src))")
        check(shown?[1] as? Bool == true && shown?[2] as? NSNumber == 560,
              "it is drawn, 560 wide (\(shown.map { "\($0[1]) \($0[2])" } ?? "none"))")
        let sources = rows.compactMap { $0.first as? String }
        check(!sources.contains { $0.hasPrefix("data:") || $0.hasPrefix("cid:") },
              "no picture of the document has a data: or cid: address (\(sources.map { String($0.prefix(24)) }))")

        // the banner's link: Copy Link stays in the menu of the picture
        var menuItems: [String]?
        TestHooks.webMenu = { menu in
            menuItems = menu.items.map { "\($0.identifier?.rawValue ?? "-") \($0.title)" }
            onMain { menu.cancelTracking() }
        }
        let top = CGFloat((shown?[4] as? NSNumber)?.doubleValue ?? 40) + 50
        let inWindow = web.convert(NSPoint(x: 120, y: top), to: nil)
        if let click = NSEvent.mouseEvent(with: .rightMouseDown, location: inWindow, modifierFlags: [], timestamp: 0,
                                          windowNumber: main.window.windowNumber, context: nil, eventNumber: 0,
                                          clickCount: 1, pressure: 1) {
            onMain { web.rightMouseDown(with: click) }
        }
        if await waitUntil(5, { menuItems != nil }), let items = menuItems {
            say("   the linked banner's menu: \(items)")
            check(items.contains { $0.contains("CopyLink") } && items.contains { $0.contains("CopyImage ") },
                  "the linked banner's menu keeps Copy Link and Copy Image")
            check(!items.contains { $0.contains("DownloadImage") || $0.contains("OpenImageInNewWindow") },
                  "and has no Download Image or Open Image in New Window")
        } else {
            check(false, "the web view's menu opens on the banner")
        }
        TestHooks.webMenu = nil
        await pause(0.5)

        // Print: the banner on the paper as the core's own picture
        let pdf = out.appendingPathComponent("newsletter-print.pdf")
        try? FileManager.default.removeItem(at: pdf)
        var printed = false
        var document = ""
        TestHooks.printTo = pdf
        TestHooks.printed = { printed = $0 }
        TestHooks.printDocument = { document = $0 }
        main.mailbox.reader.print()
        _ = await waitUntil(40) { printed }
        TestHooks.printTo = nil
        TestHooks.printed = nil
        TestHooks.printDocument = nil
        check(printed, "Print makes the printout of the newsletter")
        check(document.contains("src=\"data:image/png") && !document.contains("/pv/") && !document.contains("cid:"),
              "the print document has the banner as the core's own PNG, nothing from the preview path or cid:")
        // the banner's green on the paper
        var green = 0
        // the document kept while its page is drawn (a page without its document draws nothing)
        let paper = PDFDocument(url: pdf)
        if let page = paper?.page(at: 0) {
            let picture = page.thumbnail(of: NSSize(width: 600, height: 850), for: .mediaBox)
            if let tiff = picture.tiffRepresentation, let bitmap = NSBitmapImageRep(data: tiff) {
                for y in stride(from: 0, to: bitmap.pixelsHigh, by: 4) {
                    for x in stride(from: 0, to: bitmap.pixelsWide, by: 4) {
                        // a dark green (the paper's colour management lightens #1f4d3a a little)
                        if let c = bitmap.colorAt(x: x, y: y)?.usingColorSpace(.sRGB),
                           c.greenComponent > c.redComponent + 0.1 && c.greenComponent > c.blueComponent + 0.03
                           && c.greenComponent < 0.5 {
                            green += 1
                        }
                    }
                }
                if let png = bitmap.representation(using: .png, properties: [:]) {
                    try? png.write(to: out.appendingPathComponent("read-1b-html-print.png"))
                }
            }
        }
        check(green > 1000, "the banner is on the paper (\(green) points of its green)")

        // a dark window: the banner drawn the same, in its place
        let before = NSApp.appearance
        onMain { NSApp.appearance = NSAppearance(named: .darkAqua) }
        main.mailbox.reader.reload()
        _ = await waitUntil(10) { await self.readerBackground() == "rgb(30, 31, 34)" }
        _ = await waitUntil(15) { (banner(await images())?[1] as? Bool) == true }
        let dark = banner(await images())
        check(dark?[1] as? Bool == true && dark?[2] as? NSNumber == 560 && dark?[4] as? NSNumber == shown?[4] as? NSNumber,
              "in a dark window the banner is drawn in the same place (\(dark.map { "\($0[1]) \($0[2]) \($0[4])" } ?? "none"))")
        await shot(main.window, "read-1c-html-dark")
        onMain { NSApp.appearance = before }
        main.mailbox.reader.reload()
        _ = await waitUntil(10) { (banner(await images())?[1] as? Bool) == true }
    }

    func previewsInMessages() async throws {
        step("pictures and PDF files in the message")
        await search("")
        let reader = main.mailbox.reader
        let core = main.core
        var opened: [URL] = []
        TestHooks.openFile = { opened.append($0) }
        defer { TestHooks.openFile = nil }
        check(core.showPreviews && core.pdfPreviews, "pictures and PDF files show in messages at first")

        // the photo and the invoice: the text first, the space of the pictures kept, then the pictures
        let photoUid = try await addPreviewFixture("photo-and-pdf.eml")
        try await showInbox(photoUid)
        guard let web = readerWeb else { throw Failed(description: "no reading pane") }
        _ = await waitUntil(15) { (await readerText()).contains("photo from the lake") }
        let early = await previewsShown(web)
        let shown = await previewsLoaded(web, 4)
        check(shown.loaded && shown.pictures.count == 4,
              "the photo and the invoice's three pages show after the text (\(shown.pictures.map { "\($0.src.suffix(5)) \($0.loaded)" }))")
        check(early.captionTops == shown.captionTops && early.pictures.map(\.top) == shown.pictures.map(\.top),
              "nothing moves while the pictures arrive (\(early.captionTops) then \(shown.captionTops))")
        check(reader.strip.files.map(\.name) == ["lake.jpg", "invoice-2026-118.pdf"], "the strip still lists both files")
        check(shown.captions.count == 2 && shown.captions[0].hasPrefix("lake.jpg") && shown.captions[0].contains(where: \.isNumber)
              && shown.captions[1].hasPrefix("invoice-2026-118.pdf") && shown.captions[1].contains("3 pages, "),
              "each file's name and size above it, \"3 pages\" for the invoice (\(shown.captions))")
        check(shown.pictures.dropFirst().map(\.alt) == (1...3).map { "invoice-2026-118.pdf, page \($0) of 3" },
              "a page reads as its file and its number (\(shown.pictures.map(\.alt)))")
        check(!shown.wide && shown.pictures.allSatisfy { $0.width <= web.bounds.width }, "no wider than the pane")
        await shot(main.window, "read-30-previews")

        // a click on the photo opens it, byte for byte as sent
        await inPage(web, "document.querySelector('section[class^=pe-att] a').click()")
        check(await waitUntil(10) { opened.count == 1 }, "clicking the photo opens it")
        check(opened.last?.lastPathComponent == "lake.jpg" && opened.last.flatMap { try? Data(contentsOf: $0) } != nil
              && opened.last.flatMap { try? Data(contentsOf: $0) } == fixtureFile("photo-and-pdf.eml", "lake.jpg"),
              "the file handed over is byte for byte what was sent (\(opened.last?.lastPathComponent ?? "none"))")
        checkPrivate(opened.last, "from a private folder, as a double-click in the strip opens it")

        // Option-Tab reaches each file once (the Mac's key for the links of a page, as in Safari), Enter on the
        // invoice opens it
        main.window.makeFirstResponder(web)
        var reached: [String] = []
        for _ in 0..<4 {
            NSEvent.keyEvent(with: .keyDown, location: .zero, modifierFlags: [.option], timestamp: 0,
                             windowNumber: main.window.windowNumber, context: nil, characters: "\t",
                             charactersIgnoringModifiers: "\t", isARepeat: false, keyCode: 48).map(main.window.sendEvent)
            await pause(0.3)
            let href = (try? await web.evaluateJavaScript("document.activeElement.getAttribute('href')||''")) as? String ?? ""
            reached.append(String(href.suffix(2)))
            if href.hasSuffix("-1") { break }
        }
        check(reached.suffix(2) == ["-0", "-1"], "Option-Tab reaches the photo, then the invoice (\(reached))")
        await shot(main.window, "read-30b-previews-focus")
        onMain { self.pressKey(self.main.window, 36, "\r") }
        check(await waitUntil(10) { opened.count == 2 }, "Enter on the invoice opens it")
        check(opened.last?.lastPathComponent == "invoice-2026-118.pdf"
              && opened.last.flatMap { try? Data(contentsOf: $0) } == fixtureFile("photo-and-pdf.eml", "invoice-2026-118.pdf"),
              "the invoice as it was sent (\(opened.last?.lastPathComponent ?? "none"))")
        main.window.makeFirstResponder(list)

        // the context menu of a preview: nothing that saves or opens the picture itself
        var menuItems: [String]?
        TestHooks.webMenu = { menu in
            menuItems = menu.items.map { "\($0.identifier?.rawValue ?? "-") \($0.title)" }
            onMain { menu.cancelTracking() }
        }
        let photoTop = shown.pictures.first.map { CGFloat($0.top) + 40 } ?? 200
        let inWindow = web.convert(NSPoint(x: 60, y: photoTop), to: nil)
        if let click = NSEvent.mouseEvent(with: .rightMouseDown, location: inWindow, modifierFlags: [], timestamp: 0,
                                          windowNumber: main.window.windowNumber, context: nil, eventNumber: 0,
                                          clickCount: 1, pressure: 1) {
            onMain { web.rightMouseDown(with: click) }
        }
        if await waitUntil(5, { menuItems != nil }), let items = menuItems {
            say("   the preview's menu: \(items)")
            check(!items.contains { item in ["DownloadImage", "OpenImageInNewWindow", "CopyImageURL", "Save Image", "Open Image", "Image Address"]
                .contains { item.contains($0) } },
                  "a preview's menu has no Download Image, Open Image in New Window or Copy Image Address")
            check(items.contains { $0.contains("OpenLink ") } && items.contains { $0.contains("CopyImage ") },
                  "it keeps Open Link and Copy Image")
        } else {
            say("   (the web view's menu did not open for the test)")
        }
        TestHooks.webMenu = nil
        await pause(0.5)

        // the long manual: five pages and a link to the rest
        let manualUid = try await addPreviewFixture("long-pdf.eml")
        try await showInbox(manualUid)
        let manual = await previewsLoaded(web, 5)
        check(manual.loaded && manual.pictures.count == 5, "a long PDF file shows its first five pages (\(manual.pictures.count))")
        check(manual.more == ["Open to see all 12 pages"], "and \"Open to see all 12 pages\" (\(manual.more))")
        check(manual.links == 2, "one link for the pages and one for the rest (\(manual.links))")
        await inPage(web, "document.querySelector('section[class^=pe-att] a.m').click()")
        check(await waitUntil(10) { opened.count == 3 } && opened.last?.lastPathComponent == "kettle-manual.pdf",
              "the link opens the file (\(opened.last?.lastPathComponent ?? "none"))")
        await inPage(web, "document.querySelector('section[class^=pe-att] a.m').scrollIntoView({block:'end'})")
        await pause(0.3)
        await shot(main.window, "read-30c-previews-long")

        // a message's own window shows them too
        main.window.makeFirstResponder(list)
        let enter = NSEvent.keyEvent(with: .keyDown, location: .zero, modifierFlags: [], timestamp: 0, windowNumber: main.window.windowNumber,
                                     context: nil, characters: "\r", charactersIgnoringModifiers: "\r", isARepeat: false, keyCode: 36)
        onMain { if let enter { self.list.keyDown(with: enter) } }
        if let window = await waitWindow("message", 10), let own = MessageWindow.open.last {
            let ownWeb = views(WKWebView.self, in: own.reader.view).first
            let there = await previewsLoaded(ownWeb, 5)
            check(there.loaded && there.pictures.count == 5, "in a message's own window the previews are there too")
            await inPage(ownWeb, "document.querySelector('section[class^=pe-att] a').click()")
            let ownOpened = await waitUntil(10) { opened.count == 4 }
            check(ownOpened && opened.last?.lastPathComponent == "kettle-manual.pdf",
                  "and open the file")
            await shot(window, "read-30d-previews-window")
            onMain { window.performClose(nil) }
            _ = await waitUntil(10) { !window.isVisible }
        } else {
            check(false, "Enter opens the message in a window of its own")
        }

        // Settings: the two rows, the PDF one under the other
        try await showInbox(photoUid)
        _ = await previewsLoaded(web, 4)
        command(.options)
        guard await waitWindow("settings", 10) != nil, let options = SettingsWindow.current else {
            throw Failed(description: "Settings did not open")
        }
        await showPane(options, .reading)
        let show = options.showPreviews
        let pdf = options.pdfPreviews
        check(show.state == .on && show.title == Text.uiPreviewShow.text, "Reading has \"\(Text.uiPreviewShow.text)\", on")
        check(pdf.state == .on && pdf.isEnabled && pdf.title == Text.uiPreviewPdfs.text,
              "and \"\(Text.uiPreviewPdfs.text)\" under it, on")
        let notes = views(NSTextField.self, in: options.window.contentView).map(\.stringValue)
        check(notes.contains(Text.uiPreviewShowNote.text), "with its note")
        let showLeft = show.convert(show.bounds, to: nil).minX
        let pdfLeft = pdf.convert(pdf.bounds, to: nil).minX
        check(pdfLeft > showLeft && pdf.convert(pdf.bounds, to: nil).maxY < show.convert(show.bounds, to: nil).minY,
              "the PDF row is under it, indented (\(Int(showLeft)), \(Int(pdfLeft)))")
        await shot(options.window, "read-30e-previews-settings")

        press(show)
        check(await waitUntil(5) { !core.showPreviews && !pdf.isEnabled && pdf.state == .on },
              "turned off, the PDF row is disabled and keeps its value")
        check(await waitUntil(15) {
            let now = await self.previewsShown(web)
            let text = await self.readerText()
            return now.pictures.isEmpty && now.captions.isEmpty && text.contains("photo from the lake")
        }, "the message is made again without previews")
        check(!reader.strip.isHidden && reader.strip.files.count == 2, "the strip still lists the files")
        press(show)
        check(await waitUntil(5) { core.showPreviews && pdf.isEnabled }, "on again")
        check((await previewsLoaded(web, 4)).loaded, "the previews are back")

        // PDF files off: the photo alone, nothing said
        press(pdf)
        check(await waitUntil(5) { !core.pdfPreviews }, "\"\(Text.uiPreviewPdfs.text)\" turned off")
        let photoOnly = await previewsLoaded(web, 1)
        check(photoOnly.loaded && photoOnly.pictures.allSatisfy { $0.src.contains("-0-0") } && photoOnly.notice.isEmpty,
              "the photo shows, the invoice does not, and nothing says why (\(photoOnly.pictures.map(\.src)), \(photoOnly.notice))")
        press(pdf)
        check(await waitUntil(5) { core.pdfPreviews }, "on again")
        check((await previewsLoaded(web, 4)).loaded, "the invoice's pages are back")

        // as after a PDF file ended the app: the notice, naming the setting; Settings shows it off
        onMain { _ = pe_pdf_previews_crashed_for_tests(core.handle) }
        check(await waitUntil(10) { pdf.state == .off && !core.pdfPreviews }, "Settings shows the PDF row off at once")
        onMain { options.window.close() }
        reader.reload()
        let crashed = await previewsLoaded(web, 1)
        check(crashed.loaded && crashed.notice.contains(Text.uiPreviewPdfs.text),
              "the photo shows, and the notice names \"\(Text.uiPreviewPdfs.text)\" (\(crashed.notice))")
        await shot(main.window, "read-31-previews-pdf-off")
        command(.options)
        guard await waitWindow("settings", 10) != nil, let again = SettingsWindow.current else {
            throw Failed(description: "Settings did not open again")
        }
        await showPane(again, .reading)
        check(again.pdfPreviews.state == .off, "Settings opened again has it off")
        press(again.pdfPreviews)
        check(await waitUntil(5) { core.pdfPreviews }, "turned on")
        let back = await previewsLoaded(web, 4)
        check(back.loaded && back.notice.isEmpty, "the notice is gone and the pages are back")
        onMain { again.window.close() }
        await pause(0.5)

        // dark: the photo as it is, the pages on white, the names light
        let before = NSApp.appearance
        onMain { NSApp.appearance = NSAppearance(named: .darkAqua) }
        reader.reload()
        _ = await waitUntil(10) { await self.readerBackground() == "rgb(30, 31, 34)" }
        let dark = await previewsLoaded(web, 4)
        check(dark.loaded, "in a dark window the previews show")
        let sky = await webPixel(web, NSPoint(x: 40, y: CGFloat(dark.pictures.first?.top ?? 0) + 6))
        check(sky.map { $0.blueComponent > $0.redComponent + 0.2 } == true,
              "the photo is as it is: its sky blue, not inverted (\(sky.map { "\($0.redComponent) \($0.greenComponent) \($0.blueComponent)" } ?? "none"))")
        let pageBackground = await readerAsk("getComputedStyle(document.querySelector('section[class^=pe-att] img.p')).backgroundColor")
        let name = await readerAsk("getComputedStyle(document.querySelector('section[class^=pe-att] .n')).color")
        check(pageBackground == "rgb(255, 255, 255)", "the pages on white (\(pageBackground))")
        check(name == "rgb(227, 227, 230)", "the names light on the dark page (\(name))")
        await shot(main.window, "read-30f-previews-dark")
        await inPage(web, "document.querySelectorAll('section[class^=pe-att] img')[1].scrollIntoView()")
        await pause(0.3)
        await shot(main.window, "read-30g-previews-dark-pages")
        onMain { NSApp.appearance = before }
        await pause(0.5)

        // many pictures: twenty shown in the order of the strip, the others in the strip only; a narrow pane
        let manyUid = try await postMessage(manyPictures(24))
        try await showInbox(manyUid)
        let many = await previewsLoaded(web, 20, 60)
        check(many.loaded && many.pictures.count == 20, "of 24 pictures the first 20 show, all of them drawn (\(many.pictures.count))")
        check(many.pictures.map(\.top) == many.pictures.map(\.top).sorted(), "in the order of the strip")
        check(reader.strip.files.count == 24, "the strip lists all 24")
        await shot(main.window, "read-30h-previews-many")
        let size = main.window.frame.size
        main.window.setContentSize(NSSize(width: 760, height: main.window.contentLayoutRect.height))
        await pause(1)
        let narrow = await previewsShown(web)
        check(!narrow.wide && narrow.pictures.allSatisfy { $0.width <= web.bounds.width + 0.5 },
              "in a narrow pane every picture fits its width, nothing scrolls sideways (\(Int(web.bounds.width)))")
        await shot(main.window, "read-30i-previews-narrow")
        main.window.setContentSize(size)
        await pause(0.5)

        await removeFixture(manyUid)
        await removeFixture(manualUid)
        await removeFixture(photoUid)
    }

    /// The tiles of a document's previews: each one's type, name, size, why, width, height and file
    struct TileShown {
        var label = "", name = "", details = "", reason = "", href = ""
        var width = 0.0, height = 0.0
    }

    func tilesShown(_ web: WKWebView?) async -> [TileShown] {
        let script = "JSON.stringify([...document.querySelectorAll('section[class^=pe-att] a.t')].map(a=>{"
            + "const t=c=>(a.querySelector(c)||{}).textContent||'';const r=a.getBoundingClientRect();"
            + "return [t('.i'),t('.n'),t('.d'),t('.r'),a.getAttribute('href')||'',r.width,r.height]}))"
        guard let web, let answer = try? await web.evaluateJavaScript(script) as? String,
              let rows = try? JSONSerialization.jsonObject(with: Data(answer.utf8)) as? [[Any]] else { return [] }
        return rows.filter { $0.count == 7 }.map { row in
            TileShown(label: row[0] as? String ?? "", name: row[1] as? String ?? "", details: row[2] as? String ?? "",
                      reason: row[3] as? String ?? "", href: row[4] as? String ?? "",
                      width: (row[5] as? NSNumber)?.doubleValue ?? 0, height: (row[6] as? NSNumber)?.doubleValue ?? 0)
        }
    }

    /// the strip menu's Show in Message of file `index` of the message shown, nil when the menu has none
    func showInMessageItem(_ index: Int) -> NSMenuItem? {
        main.mailbox.reader.fileMenu(index).items.first { $0.identifier?.rawValue == "attachment.showInMessage" }
    }

    /// Show in Message of file `index` chosen, as the menu chooses it
    func chooseShowInMessage(_ index: Int) {
        let menu = main.mailbox.reader.fileMenu(index)
        guard let at = menu.items.firstIndex(where: { $0.identifier?.rawValue == "attachment.showInMessage" }) else { return }
        onMain { menu.performActionForItem(at: at) }
    }

    /// how far the reading pane is scrolled, and where the first picture's top is in the view
    func scrolled(_ web: WKWebView?) async -> (y: Int, photo: Int) {
        let answer = (try? await web?.evaluateJavaScript("JSON.stringify([Math.round(scrollY),"
            + "Math.round((document.querySelector('section[class^=pe-att] img')||document.body).getBoundingClientRect().top)])"))
            as? String ?? ""
        let numbers = (try? JSONSerialization.jsonObject(with: Data(answer.utf8)) as? [Int]) ?? []
        return numbers.count == 2 ? (numbers[0], numbers[1]) : (-1, -1)
    }

    /// 8b: the files the core does not draw as tiles, Show in Message from the strip menu, and Print with the pictures
    func previewTilesAndPrint() async throws {
        step("tiles, Show in Message and printing a message with previews")
        await search("")
        let reader = main.mailbox.reader
        let core = main.core
        var opened: [URL] = []
        TestHooks.openFile = { opened.append($0) }
        defer { TestHooks.openFile = nil }

        // the HEIC picture and the PDF file with a password: tiles of the same size that say why, the photo drawn
        let tilesUid = try await addPreviewFixture("tiles.eml")
        try await showInbox(tilesUid)
        guard let web = readerWeb else { throw Failed(description: "no reading pane") }
        _ = await waitUntil(15) { (await readerText()).contains("boat trip") }
        let photo = await previewsLoaded(web, 1)
        check(photo.loaded && photo.captions.first?.hasPrefix("shore.jpg") == true,
              "the photo from the shore is drawn (\(photo.captions))")
        let tiles = await tilesShown(web)
        say("   tiles: \(tiles.map { "\($0.label) \($0.name) \($0.details) \($0.reason) \(Int($0.width))x\(Int($0.height))" })")
        check(tiles.map(\.name) == ["boat.heic", "booking-4471.pdf"] && tiles.map(\.label) == ["HEIC", "PDF"],
              "the HEIC picture and the booking are tiles with their type (\(tiles.map(\.name)))")
        check(tiles.count == 2 && tiles.allSatisfy { !$0.reason.isEmpty && !$0.details.isEmpty }
              && tiles[0].reason != tiles[1].reason,
              "each says its size and why it is not shown (\(tiles.map(\.reason)))")
        check(tiles.count == 2 && tiles[0].height == tiles[1].height && tiles[0].width == tiles[1].width
              && tiles[0].height >= 60 && tiles[0].width <= web.bounds.width,
              "the two tiles are the same size, whatever they say")
        check(showInMessageItem(0).map { !$0.isEnabled && $0.state == .off } == true,
              "on the HEIC picture Show in Message is greyed")
        check(showInMessageItem(1).map { $0.isEnabled && $0.state == .on } == true, "on the photo it is checked")
        check(showInMessageItem(2).map { !$0.isEnabled } == true, "on the booking with a password it is greyed")
        await inPage(web, "document.querySelector('section[class^=pe-att] a.t').scrollIntoView({block:'center'})")
        await pause(0.3)
        await shot(main.window, "read-32-previews-tiles")
        await inPage(web, "window.scrollTo(0,document.documentElement.scrollHeight)")
        await pause(0.3)
        await shot(main.window, "read-32a-previews-tiles-end")

        // Option-Tab to the HEIC tile, Enter opens the file
        main.window.makeFirstResponder(web)
        await inPage(web, "window.scrollTo(0,0)")
        var reached: [String] = []
        for _ in 0..<4 {
            NSEvent.keyEvent(with: .keyDown, location: .zero, modifierFlags: [.option], timestamp: 0,
                             windowNumber: main.window.windowNumber, context: nil, characters: "\t",
                             charactersIgnoringModifiers: "\t", isARepeat: false, keyCode: 48).map(main.window.sendEvent)
            await pause(0.3)
            let href = (try? await web.evaluateJavaScript("document.activeElement.getAttribute('href')||''")) as? String ?? ""
            reached.append(String(href.suffix(2)))
            if href.hasSuffix("-0") { break }
        }
        check(reached.last == "-0", "Option-Tab reaches the HEIC tile (\(reached))")
        onMain { self.pressKey(self.main.window, 36, "\r") }
        check(await waitUntil(10) { opened.count == 1 } && opened.last?.lastPathComponent == "boat.heic"
              && opened.last.flatMap { try? Data(contentsOf: $0) } == fixtureFile("tiles.eml", "boat.heic"),
              "Enter on the tile opens the HEIC picture as it was sent (\(opened.last?.lastPathComponent ?? "none"))")
        main.window.makeFirstResponder(list)

        // Show in Message on the invoice: it goes, the text stays where it was; chosen again it is back
        let photoUid = try await addPreviewFixture("photo-and-pdf.eml")
        try await showInbox(photoUid)
        let all = await previewsLoaded(web, 4)
        check(all.loaded, "the photo and the invoice's pages show")
        check(showInMessageItem(1).map { $0.isEnabled && $0.state == .on && $0.title == Text.uiAttachmentShowInMessage.text } == true,
              "the invoice's menu has \"\(Text.uiAttachmentShowInMessage.text)\", checked")
        await menuShot(reader.strip, "read-32b-previews-menu", file: 1)
        let into = max(1, (all.captionTops.first ?? 120) / 2)
        await inPage(web, "window.scrollTo(0,\(into))")
        await pause(0.3)
        let before = await scrolled(web)
        check(before.y > 0, "the message is scrolled a little (\(before.y))")
        chooseShowInMessage(1)
        let without = await previewsLoaded(web, 1)
        check(without.loaded && without.captions.count == 1 && without.captions[0].hasPrefix("lake.jpg"),
              "choosing it takes the invoice out of the message (\(without.captions))")
        check(reader.strip.files.count == 2, "the strip still lists it")
        _ = await waitUntil(5) { await self.scrolled(web).y == before.y }
        let after = await scrolled(web)
        check(after == before, "the text stays where it was scrolled to (\(before) then \(after))")
        check(showInMessageItem(1).map { $0.isEnabled && $0.state == .off } == true, "the item is now unticked")
        await shot(main.window, "read-32c-previews-taken-out")
        chooseShowInMessage(1)
        let back = await previewsLoaded(web, 4)
        _ = await waitUntil(5) { await self.scrolled(web).y == before.y }
        check(back.loaded && back.captions.count == 2, "chosen again, the invoice is back (\(back.captions))")
        check(await scrolled(web) == before, "and the text has not moved")

        // the previews off: Show in Message draws the invoice alone. The choice lasts while a window shows the message:
        // another message shown in between forgets it
        try await showInbox(tilesUid)
        try await showInbox(photoUid)
        _ = await previewsLoaded(web, 4)
        onMain {
            core.showPreviews = false
            reader.reload()
        }
        check(await waitUntil(15) {
            let now = await self.previewsShown(web)
            return now.pictures.isEmpty && now.captions.isEmpty
        }, "with \"\(Text.uiPreviewShow.text)\" off the message shows no previews")
        check(showInMessageItem(1).map { $0.isEnabled && $0.state == .off } == true, "Show in Message is offered, unticked")
        chooseShowInMessage(1)
        let alone = await previewsLoaded(web, 3)
        check(alone.loaded && alone.captions.count == 1 && alone.captions[0].hasPrefix("invoice-2026-118.pdf"),
              "choosing it draws the invoice alone (\(alone.captions))")
        onMain {
            core.showPreviews = true
            reader.reload()
        }
        check((await previewsLoaded(web, 4)).loaded, "the setting on again: both are back")

        // Print: the photo on the paper, a line for the invoice
        let pdf = out.appendingPathComponent("previews-print.pdf")
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
        check(printed, "Print makes the printout")
        check(document.contains("src=\"data:image/") && !document.contains("/pv/"),
              "the print document has the photo as the core's own picture, nothing from the preview path")
        let paper = PDFDocument(url: pdf)
        let words = (paper?.string ?? "").replacingOccurrences(of: "\n", with: " ")
        say("   printed: \(words.prefix(300))")
        check(words.contains("photo from the lake") && words.contains("invoice-2026-118.pdf")
              && words.contains("not printed"),
              "the paper has the text and a line naming the invoice, which is not printed")
        // the photo's sky on the first page
        var sky = 0
        if let page = paper?.page(at: 0) {
            let picture = page.thumbnail(of: NSSize(width: 600, height: 850), for: .mediaBox)
            if let tiff = picture.tiffRepresentation, let bitmap = NSBitmapImageRep(data: tiff) {
                for y in stride(from: 0, to: bitmap.pixelsHigh, by: 6) {
                    for x in stride(from: 0, to: bitmap.pixelsWide, by: 6) {
                        if let c = bitmap.colorAt(x: x, y: y)?.usingColorSpace(.sRGB),
                           c.blueComponent > c.redComponent + 0.2 && c.blueComponent > 0.4 {
                            sky += 1
                        }
                    }
                }
                if let png = bitmap.representation(using: .png, properties: [:]) {
                    try? png.write(to: out.appendingPathComponent("read-33-previews-print.png"))
                }
            }
        }
        check(sky > 50, "the photo is on the paper (\(sky) points of its sky)")

        await removeFixture(photoUid)
        await removeFixture(tilesUid)
    }

    /// a message with `count` small pictures (PNGs of a colour each), one with a long name
    func manyPictures(_ count: Int) -> String {
        var raw = "From: Maria Example <maria@example.com>\r\nTo: testuser@inboxclassic.test\r\nSubject: All the photos from the trip\r\n"
            + "Message-ID: <previews-many@example.com>\r\nDate: Mon, 16 Nov 2026 11:00:00 +0000\r\nMIME-Version: 1.0\r\n"
            + "Content-Type: multipart/mixed; boundary=\"many\"\r\n\r\n--many\r\nContent-Type: text/plain; charset=utf-8\r\n\r\n"
            + "Here they all are.\r\n"
        for index in 0..<count {
            let width = 640, height = index % 3 == 0 ? 900 : 420
            let space = CGColorSpace(name: CGColorSpace.sRGB)!
            guard let context = CGContext(data: nil, width: width, height: height, bitsPerComponent: 8, bytesPerRow: 0,
                                          space: space, bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue) else { continue }
            let colour = NSColor(calibratedHue: CGFloat(index) / CGFloat(count), saturation: 0.5, brightness: 0.85, alpha: 1)
                .usingColorSpace(.sRGB) ?? .gray
            context.setFillColor(colour.cgColor)
            context.fill(CGRect(x: 0, y: 0, width: width, height: height))
            context.setFillColor(NSColor.white.cgColor)
            context.fill(CGRect(x: 40, y: 40, width: width - 80, height: 30))
            guard let image = context.makeImage() else { continue }
            let bitmap = NSBitmapImageRep(cgImage: image)
            let png = bitmap.representation(using: .png, properties: [:]) ?? Data()
            let name = index == 1
                ? "the view from the ridge just after sunrise on the second morning of the trip, uncropped.png"
                : "photo-\(index + 1).png"
            raw += "--many\r\nContent-Type: image/png; name=\"\(name)\"\r\nContent-Disposition: attachment; filename=\"\(name)\"\r\n"
                + "Content-Transfer-Encoding: base64\r\n\r\n\(png.base64EncodedString(options: .lineLength76Characters))\r\n"
        }
        return raw + "--many--\r\n"
    }
}
