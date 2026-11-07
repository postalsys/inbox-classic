// The UI end-to-end test of the Mac app, the same scenario as scripts/ui-e2e.ps1 on Windows: it starts ImapKit
// (core/e2e) with mail to read, runs the app in this process with a store of its own and --memory-passwords, and drives
// its real windows (fields typed into, buttons pressed, rows selected, menu commands run) the way a user does, checking
// the results on the server over ImapKit's REST API. Each step's window goes to a PNG under the same name as on
// Windows (scripts/feature-map.mjs builds a page from them). Driving the windows from inside the app needs none of
// the system's accessibility or screen recording permissions, so it runs on any Mac and on CI.
//
//   "build/mac/Inbox Classic.app/Contents/MacOS/InboxClassicUITest" [--out build/ui-e2e-mac]   (scripts/mac-ui-e2e.sh)
import AppKit
import CInboxClassic
import WebKit

@MainActor
public func runUITest() -> Never {
    var out = "build/ui-e2e-mac"
    var arguments = CommandLine.arguments.dropFirst().makeIterator()
    while let argument = arguments.next() {
        if argument == "--out", let value = arguments.next() {
            out = value
        }
    }
    let test = UITest(out: URL(fileURLWithPath: out, isDirectory: true))
    test.start()
    NSApp.run()
    exit(test.failures == 0 ? 0 : 1)
}

@MainActor
final class UITest {
    let out: URL
    var failures = 0
    var log = ""
    var harness: Process?
    var rest = ""
    /// the REST API of the second server, with a mailbox of its own, for the second account
    var secondRest = ""
    var ports: [String: Any] = [:]
    var delegate: AppDelegate?
    var main: MainWindow { delegate!.main }

    /// the repository, where core/e2e is: PE_REPO, or the one the bundle was built in (build/mac/...)
    var repo: URL {
        if let path = ProcessInfo.processInfo.environment["PE_REPO"] {
            return URL(fileURLWithPath: path, isDirectory: true)
        }
        var url = Bundle.main.bundleURL
        for _ in 0..<3 { url.deleteLastPathComponent() }
        return url
    }

    init(out: URL) {
        self.out = out
    }

    func start() {
        NSApplication.shared.setActivationPolicy(.regular)
        TestHooks.testing = true
        // an exception AppKit would swallow ends the test where it is thrown, not in a later layout pass
        UserDefaults.standard.set(true, forKey: "NSApplicationCrashOnExceptions")
        Task { @MainActor in
            do {
                try await scenario()
            } catch {
                check(false, "the test ran to its end (\(error))")
            }
            finish()
        }
    }

    func finish() {
        harness?.terminate()
        let result = failures == 0 ? "passed" : "failed: \(failures)"
        say(result)
        try? log.write(to: out.appendingPathComponent("log.txt"), atomically: true, encoding: .utf8)
        try? result.write(to: out.appendingPathComponent("result.txt"), atomically: true, encoding: .utf8)
        exit(failures == 0 ? 0 : 1)
    }

    // ---- what it says ----

    func say(_ text: String) {
        print(text)
        fflush(stdout)
        log += text + "\n"
    }

    func step(_ text: String) {
        say("== \(text)")
    }

    func check(_ ok: Bool, _ what: String) {
        say((ok ? "ok   " : "FAIL ") + what)
        if !ok { failures += 1 }
    }

    struct Failed: Error, CustomStringConvertible {
        let description: String
    }

    // ---- waiting ----

    func pause(_ seconds: Double) async {
        try? await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
    }

    /// waits up to `seconds` for `condition` to give something, and returns it (or nil)
    func waitFor<T>(_ seconds: Double = 20, _ condition: () async -> T?) async -> T? {
        let end = Date().addingTimeInterval(seconds)
        while Date() < end {
            if let found = await condition() { return found }
            await pause(0.1)
        }
        return await condition()
    }

    func waitUntil(_ seconds: Double = 20, _ condition: () async -> Bool) async -> Bool {
        await waitFor(seconds) { await condition() ? true : nil } ?? false
    }

    // ---- finding and using the windows ----

    /// the visible window with the identifier `id`, the frontmost first
    func window(_ id: String) -> NSWindow? {
        (Modal.windows.reversed() + NSApp.orderedWindows + NSApp.windows).first {
            $0.identifier?.rawValue == id && $0.isVisible
        }
    }

    func waitWindow(_ id: String, _ seconds: Double = 20) async -> NSWindow? {
        await waitFor(seconds) { window(id) }
    }

    /// the view with the accessibility identifier `id` under `root`
    func find<T: NSView>(_ id: String, in root: NSView?) -> T? {
        guard let root else { return nil }
        if root.accessibilityIdentifier() == id, let view = root as? T { return view }
        for child in root.subviews {
            if let found: T = find(id, in: child) { return found }
        }
        return nil
    }

    func find<T: NSView>(_ id: String, in window: NSWindow?) -> T? {
        find(id, in: window?.contentView?.superview ?? window?.contentView)
    }

    func views<T: NSView>(_ type: T.Type, in root: NSView?) -> [T] {
        guard let root else { return [] }
        return (root as? T).map { [$0] } ?? [] + root.subviews.flatMap { views(type, in: $0) }
    }

    /// what is typed into a field, as typing changes it (its delegate hears of it)
    func type(_ text: String, into field: NSTextField?) {
        guard let field else { return }
        field.stringValue = text
        NotificationCenter.default.post(name: NSControl.textDidChangeNotification, object: field)
    }

    /// a click, after this returns: what it opens may run modally, while the test goes on
    func press(_ button: NSButton?) {
        guard let button else { return }
        onMain { button.performClick(nil) }
    }

    /// a command of the menus or the toolbar, as they run it
    func command(_ command: Command) {
        onMain { AppDelegate.shared.perform(command) }
    }

    /// the button of an alert (the first is the default)
    func answer(_ window: NSWindow?, _ title: String) {
        let button: NSButton? = views(NSButton.self, in: window?.contentView).first { $0.title == title }
        check(button != nil, "the alert has \(title)")
        press(button)
    }

    /// the text of an alert
    func alertText(_ window: NSWindow?) -> String {
        views(NSTextField.self, in: window?.contentView).map(\.stringValue).joined(separator: " ")
    }

    func choose(_ popup: NSPopUpButton?, _ index: Int) {
        popup?.selectItem(at: index)
        if let popup, let action = popup.action {
            NSApp.sendAction(action, to: popup.target, from: popup)
        }
    }

    // ---- screenshots ----

    /// a picture of the window as it is on screen, title bar and the web views' content included
    func shot(_ window: NSWindow?, _ name: String) async {
        guard let window, let frame = window.contentView?.superview else {
            say("   no window for \(name)")
            return
        }
        window.displayIfNeeded()
        await pause(0.3)
        guard let rep = frame.bitmapImageRepForCachingDisplay(in: frame.bounds) else { return }
        frame.cacheDisplay(in: frame.bounds, to: rep)
        let image = NSImage(size: frame.bounds.size)
        image.addRepresentation(rep)
        // the web views draw in their own process: their pictures, put where they are
        var pictures: [(NSImage, NSRect)] = []
        for web in views(WKWebView.self, in: frame) where !web.isHiddenOrHasHiddenAncestor && web.bounds.width > 0 {
            if let picture = try? await web.takeSnapshot(configuration: nil) {
                pictures.append((picture, web.convert(web.bounds, to: frame)))
            }
        }
        let composed = NSImage(size: frame.bounds.size)
        composed.lockFocus()
        image.draw(in: frame.bounds)
        for (picture, rect) in pictures {
            picture.draw(in: rect)
        }
        // a list's header floats over its rows, its material blurring what scrolled under it, which a cached
        // drawing leaves out: the header drawn again over an opaque background, so no row shows through it
        for header in views(NSTableHeaderView.self, in: frame) where !header.isHiddenOrHasHiddenAncestor && header.bounds.width > 0 {
            guard let headerRep = header.bitmapImageRepForCachingDisplay(in: header.bounds) else { continue }
            header.cacheDisplay(in: header.bounds, to: headerRep)
            let rect = header.convert(header.bounds, to: frame)
            window.effectiveAppearance.performAsCurrentDrawingAppearance {
                NSColor.controlBackgroundColor.setFill()
                rect.fill()
            }
            headerRep.draw(in: rect)
        }
        composed.unlockFocus()
        guard let tiff = composed.tiffRepresentation, let bitmap = NSBitmapImageRep(data: tiff),
              let png = bitmap.representation(using: .png, properties: [:]) else { return }
        try? png.write(to: out.appendingPathComponent("\(name).png"))
    }

    // ---- ImapKit ----

    func startHarness() throws {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/env")
        process.arguments = ["node", "harness.mjs"]
        process.currentDirectoryURL = repo.appendingPathComponent("core/e2e")
        let input = Pipe()
        let output = Pipe()
        process.standardInput = input
        process.standardOutput = output
        try process.run()
        harness = process
        // with its OAuth 2.0 / OpenID Connect provider, and a user with an address for name to sign in as there
        let config = #"{"oauth":{},"users":{"testuser":{"password":"testpass"},"alice@example.com":{"password":"pw","displayName":"Alice Example"}},"second":{"users":{"testuser2":{"password":"testpass2"}}}}"#
        input.fileHandleForWriting.write(Data((config + "\n").utf8))
        var line = Data()
        while true {
            let byte = output.fileHandleForReading.readData(ofLength: 1)
            if byte.isEmpty || byte == Data("\n".utf8) { break }
            line.append(byte)
        }
        guard let parsed = try JSONSerialization.jsonObject(with: line) as? [String: Any] else {
            throw Failed(description: "ImapKit did not say its ports")
        }
        ports = parsed
        rest = "http://127.0.0.1:\(parsed["rest"]!)/v1/mailboxes"
        secondRest = "http://127.0.0.1:\((parsed["second"] as? [String: Any])?["rest"] ?? "")/v1/mailboxes"
    }

    func port(_ name: String) -> String {
        "\(ports[name] ?? "")"
    }

    /// a port of the second server
    func secondPort(_ name: String) -> String {
        "\((ports["second"] as? [String: Any])?[name] ?? "")"
    }

    /// the messages of a mailbox, with their sources
    func messages(_ mailbox: String, at server: String? = nil) async -> [[String: Any]] {
        let escaped = mailbox.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? mailbox
        guard let url = URL(string: "\(server ?? rest)/\(escaped)/messages?raw=true"),
              let (data, _) = try? await URLSession.shared.data(from: url),
              let list = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]] else { return [] }
        return list
    }

    /// how many messages of the Inbox of a server (the first by default) are unread
    func unreadOnServer(at server: String? = nil) async -> Int {
        await messages("INBOX", at: server).filter { !(($0["flags"] as? [String]) ?? []).contains("\\Seen") }.count
    }

    func raw(_ message: [String: Any]) -> String {
        guard let encoded = message["raw"] as? String, let data = Data(base64Encoded: encoded) else { return "" }
        return String(decoding: data, as: UTF8.self)
    }

    func findMessage(_ mailbox: String, _ pattern: String) async -> [String: Any]? {
        await messages(mailbox).first { raw($0).range(of: pattern, options: .regularExpression) != nil }
    }

    func seen(_ pattern: String) async -> Bool {
        (await findMessage("INBOX", pattern)?["flags"] as? [String])?.contains("\\Seen") ?? false
    }

    func addMessage(_ raw: String, flags: [String] = [], at server: String? = nil, to mailbox: String = "INBOX") async throws {
        var request = URLRequest(url: URL(string: "\(server ?? rest)/\(mailbox)/messages")!)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: ["raw": raw, "flags": flags])
        _ = try await URLSession.shared.data(for: request)
    }

    /// the mail the Windows test reads too: in the list newest first the newsletter, Ann's message, the minutes, and a
    /// reply with the message it answers quoted below
    func seed() async throws {
        // the newsletter's banner
        let picture = NSImage(size: NSSize(width: 560, height: 110), flipped: false) { rect in
            NSColor(calibratedRed: 31 / 255, green: 77 / 255, blue: 58 / 255, alpha: 1).setFill()
            rect.fill()
            let georgia = { (size: CGFloat, bold: Bool) in
                NSFont(name: bold ? "Georgia-Bold" : "Georgia", size: size) ?? NSFont.systemFont(ofSize: size)
            }
            ("Trail Notes" as NSString).draw(at: NSPoint(x: 24, y: 50), withAttributes: [
                .font: georgia(30, true), .foregroundColor: NSColor.white,
            ])
            ("Walks, maps and weekend ideas  |  October" as NSString).draw(at: NSPoint(x: 26, y: 24), withAttributes: [
                .font: georgia(15, false), .foregroundColor: NSColor(calibratedRed: 214 / 255, green: 232 / 255, blue: 220 / 255, alpha: 1),
            ])
            return true
        }
        let png = NSBitmapImageRep(data: picture.tiffRepresentation!)!.representation(using: .png, properties: [:])!
            .base64EncodedString(options: .lineLength76Characters).replacingOccurrences(of: "\r\n", with: "\r\n")
        let pdf = Data("%PDF-1.4\n% a small attachment from the Mac UI test\n".utf8).base64EncodedString()
        try await addMessage("From: Bob Harris <bob@example.com>\r\nTo: testuser@inboxclassic.test, Dave <dave@example.com>\r\n"
            + "Cc: Carol <carol@example.com>\r\nSubject: Minutes of the planning meeting\r\nMessage-ID: <minutes@example.com>\r\n"
            + "Date: Wed, 1 Oct 2025 09:00:00 +0000\r\n\r\nWe agreed on the dates.\r\n", flags: ["\\Seen"])
        try await addMessage("From: Carol <carol@example.com>\r\nTo: testuser@inboxclassic.test\r\nSubject: Re: Lunch on Friday\r\n"
            + "Message-ID: <lunch2@example.com>\r\nIn-Reply-To: <lunch1@example.com>\r\nDate: Mon, 29 Sep 2025 12:00:00 +0000\r\n"
            + "Content-Type: text/html; charset=utf-8\r\n\r\n"
            + "<div dir=\"ltr\">Friday is fine, see you at noon.</div><br><div class=\"gmail_quote\"><div dir=\"ltr\" class=\"gmail_attr\">"
            + "On Mon, Sep 29, 2025 at 9:00 AM Alex Morgan &lt;testuser@inboxclassic.test&gt; wrote:<br></div>"
            + "<blockquote class=\"gmail_quote\" style=\"margin:0px 0px 0px 0.8ex;border-left:1px solid rgb(204,204,204);padding-left:1ex\">"
            + "Lunch on Friday? The usual place.</blockquote></div>\r\n", flags: ["\\Seen"])
        try await addMessage("From: Ann Example <ann@example.com>\r\nTo: testuser@inboxclassic.test\r\nSubject: Photos from Saturday\r\n"
            + "Message-ID: <ui-e2e@example.com>\r\nDate: Mon, 6 Oct 2025 10:00:00 +0000\r\n\r\nHi Alex,\r\n"
            + "the photos from Saturday are in the shared album. The one from the lake came out best.\r\n\r\nAnn\r\n")
        let html = "<div style=\"font-family:Georgia,serif;max-width:560px;color:#222\">"
            + "<p><img src=\"cid:banner@example.com\" width=\"560\" height=\"110\" alt=\"Trail Notes\"></p>"
            + "<h2 style=\"color:#1f4d3a;margin:18px 0 6px\">Five autumn walks worth the drive</h2>"
            + "<p>The larches are turning gold and the summer crowds have gone home. This month we picked five routes for short "
            + "October days, each under four hours, with a warm cafe at the end.</p>"
            + "<p><a href=\"https://example.com/news\">Read the full guide</a> <script>alert(\"never runs\")</script></p>"
            + "<p style=\"color:#666;font-size:14px\">Photo of the month, sent in by a reader:</p>"
            + "<p><img src=\"https://nodemailer.com/img/nm_logo_200x136.png\" width=\"200\" height=\"136\" alt=\"Photo of the month\"></p></div>"
        try await addMessage("From: Trail Notes <news@example.com>\r\nTo: testuser@inboxclassic.test\r\nSubject: October newsletter\r\n"
            + "Message-ID: <news@example.com>\r\nDate: Wed, 8 Oct 2025 08:00:00 +0000\r\nMIME-Version: 1.0\r\n"
            + "Content-Type: multipart/mixed; boundary=\"mixed\"\r\n\r\n--mixed\r\n"
            + "Content-Type: multipart/related; boundary=\"related\"\r\n\r\n--related\r\n"
            + "Content-Type: text/html; charset=utf-8\r\n\r\n\(html)\r\n--related\r\n"
            + "Content-Type: image/png\r\nContent-ID: <banner@example.com>\r\nContent-Transfer-Encoding: base64\r\n\r\n\(png)\r\n"
            + "--related--\r\n--mixed\r\nContent-Type: application/pdf; name=\"report.pdf\"\r\n"
            + "Content-Disposition: attachment; filename=\"report.pdf\"\r\nContent-Transfer-Encoding: base64\r\n\r\n\(pdf)\r\n"
            + "--mixed--\r\n", flags: ["\\Flagged"])
    }

    // ---- the app ----

    func startApp() {
        let store = out.appendingPathComponent("store.db").path
        for suffix in ["", "-wal", "-shm"] {
            try? FileManager.default.removeItem(atPath: store + suffix)
        }
        let signInPage = out.appendingPathComponent("sign-in-page.txt").path
        try? FileManager.default.removeItem(atPath: signInPage)
        // ImapKit's certificate is self-signed: the app trusts it, and only it, for this run
        let arguments = Arguments(["InboxClassic", "--store", store, "--memory-passwords", "--pin-certificate", port("cert"),
                                   "--sign-in-page-file", signInPage])
        // the test reads English, whatever the languages of the machine it runs on
        Languages.apply("en")
        let delegate = AppDelegate(arguments)
        self.delegate = delegate
        NSApp.delegate = delegate
        delegate.applicationDidFinishLaunching(Notification(name: NSApplication.didFinishLaunchingNotification))
    }

    var tree: FolderOutline { main.mailbox.tree }
    var list: MessageTable { main.mailbox.list }

    /// the folder at `index` under the first account (Inbox first)
    func selectFolder(_ index: Int) {
        let row = 1 + index
        tree.selectRowIndexes(IndexSet(integer: row), byExtendingSelection: false)
    }

    /// the folder of the first account the tree names `name` (Inbox, Sent Items, Drafts, Archive, Junk E-mail...)
    @discardableResult
    func selectFolder(named name: String) -> Bool {
        for row in 0..<tree.numberOfRows {
            if let node = tree.item(atRow: row) as? Mailbox.FolderNode, node.folder.name == name {
                tree.selectRowIndexes(IndexSet(integer: row), byExtendingSelection: false)
                return true
            }
        }
        return false
    }

    func search(_ words: String) {
        main.searchField.stringValue = words
        main.mailbox.find(words)
        main.showCounts()
    }

    /// the mailboxes on the server
    func mailboxes() async -> [String] {
        guard let url = URL(string: rest), let (data, _) = try? await URLSession.shared.data(from: url),
              let list = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]] else { return [] }
        return list.compactMap { $0["path"] as? String }
    }

    func closeWithoutSaving(_ compose: NSWindow) async {
        await closeCompose(compose)
    }

    func send(_ compose: NSWindow) {
        guard let window = ComposeWindow.open.first(where: { $0.window === compose }) else { return }
        onMain { window.sendClicked() }
    }

    func selectRow(_ row: Int) async {
        list.window?.makeFirstResponder(list)
        list.selectRowIndexes(IndexSet(integer: row), byExtendingSelection: false)
        await pause(1.5)
    }

    // ---- the scenario ----

    func scenario() async throws {
        try? FileManager.default.createDirectory(at: out, withIntermediateDirectories: true)
        for file in (try? FileManager.default.contentsOfDirectory(at: out, includingPropertiesForKeys: nil)) ?? []
        where file.pathExtension == "png" || file.lastPathComponent.hasPrefix("report") {
            try? FileManager.default.removeItem(at: file)
        }
        step("starting ImapKit")
        try startHarness()
        try await seed()
        step("starting Inbox Classic with a store of its own")
        startApp()
        try await addAccount()
        try await reading()
        try await writing()
        try await notDownloaded()
        try await outboxAndDrafts()
        try await searching()
        try await files()
        try await organizing()
        try await listMail()
        try await folders()
        try await writingMore()
        try await signature()
        try await accountTrouble()
        try await allInboxes()
        try await betweenAccounts()
        try await accountsAndHelp()
        try await languages()
    }

    func addAccount() async throws {
        step("adding the account")
        guard let first = await waitWindow("account.start") else { throw Failed(description: "no account form") }
        check(true, "the form opens on the first start")
        let google: NSButton? = find("account.google", in: first)
        let microsoft: NSButton? = find("account.microsoft", in: first)
        check(google?.accessibilityLabel() == "Sign in with Google" && microsoft?.accessibilityLabel() == "Sign in with Microsoft",
              "it starts with the Google and Microsoft sign-in buttons")
        type("Alex Morgan", into: find("account.name", in: first))
        type("testuser@inboxclassic.test", into: find("account.email", in: first))
        await shot(first, "account-1-form")
        press(find("account.next", in: first))
        if let wait = await waitWindow("wait", 5) {
            await shot(wait, "account-2-lookup")
        }
        // the lookup finds nothing for this domain: the second form comes with the usual names to correct
        guard let second = await waitFor(40, { window("form").flatMap { $0.title == "Add Mail Account" ? $0 : nil } }) else {
            throw Failed(description: "no server settings form")
        }
        check(true, "the server settings form follows the lookup")
        let field = { (index: Int) -> NSTextField? in self.find("form.field.\(index)", in: second) }
        check(field(4)?.stringValue == "imap.inboxclassic.test", "the lookup guessed the IMAP server")
        check(field(0)?.stringValue == "Alex Morgan", "the server form keeps the name typed first")
        type("testuser", into: field(2))
        type("testpass", into: field(3))
        type("127.0.0.1", into: field(4))
        type(port("imap"), into: field(5))
        (find("form.field.6", in: second) as NSPopUpButton?)?.selectItem(at: 2)
        type("127.0.0.1", into: field(7))
        type(port("smtp"), into: field(8))
        // ImapKit's SMTP server takes a password only after STARTTLS
        (find("form.field.9", in: second) as NSPopUpButton?)?.selectItem(at: 1)
        await shot(second, "account-3-servers")
        press(find("form.ok", in: second))
        let warning = await waitWindow("alert")
        check(warning != nil, "a connection without encryption is warned about")
        await shot(warning, "account-4-warning")
        answer(warning, "Yes")
    }

    func reading() async throws {
        step("syncing")
        let folders = await waitFor { tree.numberOfRows >= 7 ? tree.numberOfRows : nil }
        check(folders != nil, "the folders of the account are in the tree (\(folders ?? 0))")
        main.window.setContentSize(NSSize(width: 1100, height: 720))
        main.window.center()
        main.mailbox.view.layoutSubtreeIfNeeded()
        main.mailbox.placeDividers()
        selectFolder(0)
        let rows = await waitFor { list.numberOfRows >= 4 ? list.numberOfRows : nil }
        check(rows == 4, "the messages are in the list")
        list.window?.makeFirstResponder(list)
        await shot(main.window, "main-1-inbox")

        step("reading an HTML message")
        await selectRow(0)
        check(await waitUntil { await seen("October newsletter") }, "showing the message marked it read on the server")
        let attachments: NSPopUpButton? = find("reader.attachments", in: main.window)
        check(attachments?.isHidden == false, "the paper clip of the attachments is there")
        let pictures: InfoBar? = find("reader.pictures", in: main.window)
        check(pictures?.isHidden == false, "the information bar says pictures are blocked")
        check(main.window.title == "Inbox", "the title names the folder (\(main.window.title))")
        await pause(1)
        await shot(main.window, "read-1-html")

        step("message properties")
        command(.properties)
        let properties = await waitWindow("text", 10)
        check(properties != nil, "File > Properties opens the headers of the message")
        if let properties {
            let box: NSTextView? = find("text.body", in: properties)
            let headers = box?.string ?? ""
            check(headers.contains("Subject: October newsletter") && !headers.contains("larches are turning"), "the headers, without the body")
            await shot(properties, "read-7-properties")
            NSApp.stopModal()
            check(await waitUntil(10) { !properties.isVisible }, "OK closes it")
        }

        step("the message list menu and the message source")
        let messageMenu = main.mailbox.messageMenu()
        let labels = messageMenu?.items.map(\.title) ?? []
        check(labels.contains("Reply to Sender") && labels.contains("Mark as Unread") && labels.contains("Move to Folder\u{2026}")
            && labels.contains("View Source") && labels.contains("Properties"), "the message list has a right-click menu with the message's actions (\(labels.joined(separator: ", ")))")
        check(!labels.contains("Mark as Read"), "a read message offers Mark as Unread, not Mark as Read")
        if let messageMenu, let index = labels.firstIndex(of: "View Source") {
            onMain { messageMenu.performActionForItem(at: index) }
        }
        let source = await waitWindow("source", 10)
        check(source != nil, "View Source opens the whole message")
        if let source {
            let box: NSTextView? = find("text.body", in: source)
            let raw = box?.string ?? ""
            check(raw.contains("Subject: October newsletter") && raw.contains("Content-Type: multipart") && raw.contains("larches are turning"),
                  "with its header and every part, as the server has it")
            check(source.title == "Message Source: October newsletter", "the window names the message (\(source.title))")
            await shot(source, "read-15-source")
            let eml = out.appendingPathComponent("source-saved.eml")
            try? FileManager.default.removeItem(at: eml)
            var suggested: String?
            TestHooks.save = { name in
                suggested = name
                return eml
            }
            let save: NSButton? = find("source.save", in: source)
            onMain { _ = save?.accessibilityPerformPress() }
            check(await waitUntil(10) { suggested != nil } && suggested?.contains("October newsletter") == true,
                  "Save As in it asks where, with the subject as the name (\(suggested ?? ""))")
            check(await waitUntil(10) { (try? String(contentsOf: eml, encoding: .utf8))?.contains("larches are turning") == true },
                  "and saves the message as it came")
            TestHooks.save = nil
            check(source.isVisible, "and the source stays open")
            NSApp.stopModal()
            check(await waitUntil(10) { !source.isVisible }, "Close closes it")
        }

        step("pictures from the internet")
        onMain { _ = pictures?.accessibilityPerformPress() }
        check(await waitUntil(10) { pictures?.isHidden == true }, "clicking the bar shows the pictures, and the bar goes away")
        await pause(3)
        await shot(main.window, "read-2-pictures")

        step("saving the attachment")
        let menu = main.mailbox.reader.attachmentMenu()
        check(menu.items.first?.title.hasPrefix("report.pdf") == true, "the paper clip offers the files to save")
        if let item = menu.items.first, let action = item.action {
            onMain { NSApp.sendAction(action, to: item.target, from: item) }
            // the system's panel runs in a process of its own: the test answers in its place, with what it was asked
            var suggested: String?
            let target = out.appendingPathComponent("report-saved.pdf")
            TestHooks.save = { name in
                suggested = name
                return target
            }
            check(await waitUntil(10) { suggested != nil }, "choosing one asks where to save it")
            TestHooks.save = nil
            if let suggested {
                check(suggested.hasPrefix("report"), "the suggested name is the file's (\(suggested))")
                let saved = await waitFor(10) { try? String(contentsOf: target, encoding: .utf8) }
                check(saved?.contains("a small attachment from the Mac UI test") == true, "the attachment is saved as it was sent")
                let quarantine = (try? target.resourceValues(forKeys: [.quarantinePropertiesKey]))?.quarantineProperties
                check(quarantine != nil, "and marked as from the internet")
            }
        }

        step("marking unread and read")
        command(.markUnread)
        check(await waitUntil { await !seen("October newsletter") }, "Mark Unread clears \\Seen on the server")
        await shot(main.window, "read-5-unread")
        command(.markRead)
        check(await waitUntil { await seen("October newsletter") }, "Mark Read sets it again")

        step("a reply with the earlier message folded")
        await selectRow(3)
        await pause(1)
        await shot(main.window, "read-6-folded")
    }

    // ---- writing ----

    func waitCompose() async -> NSWindow? {
        await waitFor { ComposeWindow.open.last.flatMap { $0.window.isVisible ? $0.window : nil } }
    }

    func closeCompose(_ compose: NSWindow) async {
        onMain { compose.performClose(nil) }
        if let ask = await waitWindow("alert", 3) {
            answer(ask, Text.macDontSave.text)
        }
        _ = await waitUntil { !compose.isVisible }
    }

    func field(_ id: String, _ compose: NSWindow) -> NSTextField? {
        find(id, in: compose)
    }

    /// types into the editor of a compose window, as typing does
    func typeInEditor(_ compose: NSWindow, _ text: String) async -> Bool {
        guard let editor: EditorView = views(EditorView.self, in: compose.contentView).first else { return false }
        _ = await waitUntil(10) { (try? await editor.evaluateJavaScript("!!window.pe")) as? Bool == true }
        let script = "document.getElementById('body').focus();document.execCommand('insertText',false,\(jsString(text)));"
            + "document.getElementById('body').innerText"
        let body = try? await editor.evaluateJavaScript(script) as? String
        return body?.contains(text) == true
    }

    func writing() async throws {
        step("forwarding")
        await selectRow(0)
        command(.forward)
        guard var compose = await waitCompose() else { throw Failed(description: "no compose window") }
        check(field("compose.subject", compose)?.stringValue == "Fw: October newsletter", "the subject is marked Fw:")
        check(field("compose.to", compose)?.stringValue == "", "the recipients are left to the user")
        await pause(1.5)
        await shot(compose, "write-1-forward")
        await closeCompose(compose)

        step("replying to all")
        await selectRow(2)
        command(.replyAll)
        guard let replyAll = await waitCompose() else { throw Failed(description: "no compose window") }
        compose = replyAll
        let to = field("compose.to", compose)?.stringValue ?? ""
        check(to.contains("bob@example.com") && to.contains("dave@example.com"), "it goes to the sender and the others (\(to))")
        check(!to.contains("testuser@"), "but not to the account itself")
        check(field("compose.cc", compose)?.stringValue.contains("carol@example.com") == true, "with the Cc kept")
        check(field("compose.cc", compose)?.isHiddenOrHasHiddenAncestor == false, "the Cc row is open, as it has someone in it")
        await pause(1.5)
        await shot(compose, "write-2-reply-all")
        await closeCompose(compose)

        step("replying")
        await selectRow(1)
        command(.reply)
        guard let reply = await waitCompose() else { throw Failed(description: "no compose window") }
        compose = reply
        check(field("compose.to", compose)?.stringValue.contains("ann@example.com") == true, "the reply goes to the sender")
        check(await typeInEditor(compose, "Thanks, Ann. The lake one is my favourite too."), "the editor takes typing")
        await pause(0.5)
        await shot(compose, "write-3-reply")
        ComposeWindow.open.last.map { window in onMain { window.perform(#selector(ComposeWindow.sendClicked)) } }
        let answered = await waitFor(30) { await findMessage("INBOX", "Subject: Re: Photos from Saturday") }
        check(answered != nil, "the reply arrived over SMTP")
        if let answered {
            let text = raw(answered)
            check(text.contains("In-Reply-To: <ui-e2e@example.com>"), "the reply refers to the message it answers")
            check(text.contains("my favourite too"), "the reply has what was typed")
            check(text.contains("Original Message") && text.contains("shared album"), "the folded quote is sent along")
        }
        check(await waitFor { await findMessage("Sent", "Subject: Re: Photos from Saturday") } != nil, "a copy of the reply is in Sent")

        step("a new message")
        command(.newMail)
        guard let new = await waitCompose() else { throw Failed(description: "no compose window") }
        compose = new
        check(field("compose.cc", compose)?.isHiddenOrHasHiddenAncestor == true
              && field("compose.bcc", compose)?.isHiddenOrHasHiddenAncestor == true, "a new message shows no empty Cc or Bcc row")
        await pause(1)
        await shot(compose, "write-0-new-empty")
        let from: NSPopUpButton? = find("compose.from", in: compose)
        check(from?.titleOfSelectedItem == "Alex Morgan <testuser@inboxclassic.test>", "From names the account it goes from")
        type("dave at example.com", into: field("compose.to", compose))
        type("Trail map for Sunday", into: field("compose.subject", compose))
        check(await typeInEditor(compose, "Hi Dave, here is the trail map for Sunday. See you at nine!"), "the editor of a new message takes typing")
        ComposeWindow.open.last.map { window in onMain { window.perform(#selector(ComposeWindow.sendClicked)) } }
        let problem = await waitWindow("alert", 10)
        check(problem != nil, "a mistyped address is pointed out before sending")
        await shot(problem, "write-4-bad-address")
        answer(problem, "OK")
        check(await waitUntil { compose.isVisible && window("alert") == nil }, "and the message stays open to fix it")
        type("Dave <dave@example.com>", into: field("compose.to", compose))
        let file = out.appendingPathComponent("trail-map.txt")
        try "the attachment that goes".write(to: file, atomically: true, encoding: .utf8)
        ComposeWindow.open.last?.attachForTest([file])
        let attached: NSTokenField? = find("compose.attached", in: compose)
        check((attached?.objectValue as? [String])?.count == 1, "Attach adds the file to the Attach row")
        await pause(0.5)
        await shot(compose, "write-5-new")
        ComposeWindow.open.last.map { window in onMain { window.perform(#selector(ComposeWindow.sendClicked)) } }
        let sent = await waitFor(30) { await findMessage("INBOX", "Subject: Trail map for Sunday") }
        check(sent != nil, "the new message was sent")
        check(sent.map { raw($0).contains("here is the trail map for Sunday") } == true, "with what was typed")
        check(sent.map { raw($0).contains("trail-map.txt") } == true, "with the file attached")
        await shot(main.window, "write-11-sent")

        step("Sent Items")
        selectFolder(1)
        _ = await waitUntil { list.numberOfRows >= 2 }
        await selectRow(0)
        let person = list.tableColumn(withIdentifier: NSUserInterfaceItemIdentifier("from"))
        let at = list.column(withIdentifier: NSUserInterfaceItemIdentifier("from"))
        let firstTo = (list.view(atColumn: at, row: 0, makeIfNecessary: true) as? NSTableCellView)?.textField?.stringValue
        check(person?.title == "To" && firstTo == "Dave",
              "Sent Items names whom each message went to, in a To column (\(person?.title ?? ""): \(firstTo ?? ""))")
        await shot(main.window, "main-3-sent-items")
        selectFolder(0)
        _ = await waitUntil { list.numberOfRows >= 5 }
    }

    // ---- searching ----

    func searching() async throws {
        step("searching")
        main.searchField.stringValue = "newsletter"
        main.mailbox.find("newsletter")
        main.showCounts()
        let found = await waitFor { list.numberOfRows >= 1 ? list.numberOfRows : nil }
        check(found == 1, "the search finds the newsletter (\(found ?? 0))")
        let bar: InfoBar? = find("search.bar", in: main.window)
        check(bar?.isHidden == false && bar?.text.contains("1 result") == true, "the bar over the list says what was found")
        await selectRow(0)
        await shot(main.window, "find-1-results")
        main.searchField.stringValue = "lunch OR minutes"
        main.mailbox.find("lunch OR minutes")
        main.showCounts()
        check(await waitUntil { list.numberOfRows == 2 }, "OR finds either")
        await selectRow(0)
        await shot(main.window, "find-2-every-folder")
        main.searchField.stringValue = "zebra"
        main.mailbox.find("zebra")
        main.showCounts()
        check(await waitUntil { list.numberOfRows == 0 }, "a word no message has finds nothing")
        await shot(main.window, "find-3-no-results")
        main.searchField.stringValue = ""
        main.mailbox.clearFind()
        main.showCounts()
        check(await waitUntil { list.numberOfRows >= 5 }, "clearing the search shows the folder again")
    }

    // ---- accounts, sign-in apps, outbox, help ----

    func accountsAndHelp() async throws {
        step("the accounts")
        command(.accounts)
        let accounts = await waitWindow("accounts", 10)
        check(accounts != nil, "File > Accounts lists the accounts")
        await shot(accounts, "accounts-1-list")
        if let accounts {
            press(find("accounts.apps", in: accounts))
            let apps = await waitWindow("signin.apps", 10)
            check(apps != nil, "Sign-in Apps lists the built-in clients")
            await shot(apps, "signin-1-apps")
            if let apps {
                press(find("signin.add", in: apps))
                let editor = await waitWindow("signin.editor", 10)
                check(editor != nil, "Add opens the editor of a sign-in app")
                if let editor {
                    // the provider's settings filled in by its preset, the redirect URI to register shown
                    press(find("signin.preset.0", in: editor))
                    await pause(0.5)
                    let issuer: NSTextField? = find("signin.issuer", in: editor)
                    let redirect: NSTextField? = find("signin.redirect", in: editor)
                    check(issuer?.stringValue.hasPrefix("https://") == true, "a preset fills in the issuer (\(issuer?.stringValue ?? ""))")
                    check(redirect?.stringValue.hasPrefix("http://127.0.0.1") == true, "and shows the redirect URI to register")
                    await shot(editor, "signin-4-editor")
                    NSApp.stopModal()
                    _ = await waitUntil { !editor.isVisible }
                }
                await pause(0.3)
                NSApp.stopModal()
                _ = await waitUntil { !apps.isVisible }
            }
            await pause(0.3)
            press(find("accounts.close", in: accounts))
            _ = await waitUntil { !accounts.isVisible }
        }

        step("printing")
        selectFolder(named: "Inbox")
        _ = await waitUntil { list.numberOfRows >= 3 }
        await selectRow(0)
        await pause(1)
        command(.print)
        let sheet = await waitFor(15) { main.window.attachedSheet }
        check(sheet != nil, "Print opens the system's Print panel over the window")
        await pause(1.5)
        await shot(sheet, "files-3-print")
        if let sheet {
            main.window.endSheet(sheet, returnCode: .cancel)
        }
        await pause(0.5)

        step("the help")
        command(.help)
        let help = await waitWindow("help", 10)
        check(help != nil, "Help opens the help")
        await pause(1.5)
        await shot(help, "help-2-contents")
        help?.close()
        command(.about)
        await pause(1)
        let about = NSApp.windows.first { $0.isVisible && $0.className.contains("About") || ($0.isVisible && $0.title.isEmpty && $0.frame.width < 400) }
        await shot(about, "help-1-about")
        about?.close()
        await shot(main.window, "main-2-end")
    }
}

extension ComposeWindow {
    /// files attached as the Attach panel would attach them (the test can not choose files in the panel)
    func attachForTest(_ urls: [URL]) {
        addFiles(urls)
    }
}
