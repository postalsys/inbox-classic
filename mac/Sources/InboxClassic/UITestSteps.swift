// The later steps of the Mac UI end-to-end test (UITest.swift), in the order of scripts/ui-e2e.ps1: the Outbox and
// Drafts, new mail, files, organizing, mailing lists, invitations and logos, folders, closing and links, completion, the
// signature, a Gmail address and a wrong password.
import AppKit
import CInboxClassic
import Darwin
import UniformTypeIdentifiers
import WebKit

extension UITest {
    // ---- the Outbox and Drafts ----

    /// the outgoing server's port, changed in Accounts > Properties (to one nothing listens on, and back)
    func setSmtpPort(_ port: String) async throws {
        try await setPort(field: 8, port)
    }

    /// a port of the account's servers (the field of the Properties form: 5 IMAP, 8 SMTP), changed there
    func setPort(field index: Int, _ port: String) async throws {
        command(.accounts)
        guard let accounts = await waitWindow("accounts", 10) else { throw Failed(description: "no Accounts window") }
        press(find("accounts.properties", in: accounts))
        guard let form = await waitFor(10, { window("form").flatMap { $0.title == "Properties" ? $0 : nil } }) else {
            throw Failed(description: "no Properties form")
        }
        type(port, into: find("form.field.\(index)", in: form))
        press(find("form.ok", in: form))
        // a question about a connection without encryption: Yes
        if let ask = await waitWindow("alert", 5) {
            answer(ask, "Yes")
        }
        _ = await waitUntil(10) { !form.isVisible }
        press(find("accounts.close", in: accounts))
        _ = await waitUntil(10) { !accounts.isVisible }
    }

    /// the text the reading pane shows now (its own document's, which the test can read with scripts off for the page)
    func readerText() async -> String {
        guard let web = views(WKWebView.self, in: main.mailbox.reader.view).first else { return "" }
        return (try? await web.evaluateJavaScript("document.body ? document.body.innerText : ''")) as? String ?? ""
    }

    /// a message the server does not give yet, and then can not: the pane says it is downloading, then why it is not
    /// there with Try Again, and once the account is back it shows the message by itself
    func notDownloaded() async throws {
        step("a message that is not downloaded yet")
        try await addMessage("From: Hal Example <hal@example.com>\r\nTo: testuser@inboxclassic.test\r\nSubject: Waiting on the server\r\n"
            + "Message-ID: <waiting@example.com>\r\nDate: \(rfc2822(Date()))\r\n\r\nHere at last.\r\n")
        command(.sync)
        _ = await waitFor(20) { await findMessage("INBOX", "Subject: Waiting on the server") }
        selectFolder(named: "Inbox")
        _ = await waitUntil(20) { list.numberOfRows >= 9 }
        // a server that takes the connection and says nothing: the download waits
        guard let silent = SilentServer() else { throw Failed(description: "no silent server") }
        try await setPort(field: 5, "\(silent.port)")
        search("subject:\"Waiting on the server\"")
        _ = await waitUntil(20) { list.numberOfRows == 1 }
        await selectRow(0)
        let header: NSTextField? = find("reader.header", in: main.window)
        check(header?.stringValue.contains("Waiting on the server") == true && header?.stringValue.contains("Hal Example") == true,
              "the header shows the message's sender and subject at once (\(header?.stringValue ?? ""))")
        check(await waitUntil(10) { await readerText().contains("Downloading the message") }, "the pane says the message is being downloaded")
        await shot(main.window, "read-13-downloading")
        // the server gone: why, and Try Again
        silent.stop()
        let retry: InfoBar? = find("reader.retry", in: main.window)
        check(await waitUntil(20) { retry?.isHidden == false }, "a message that can not be downloaded has Try Again")
        check(await waitUntil(5) { await readerText().contains("could not be downloaded") }, "and the pane says why")
        await shot(main.window, "read-12-not-downloaded")
        // the server back: the account syncs, and the message is tried again by itself
        try await setPort(field: 5, port("imap"))
        check(await waitUntil(30) { await readerText().contains("Here at last") }, "once the account is back the message shows by itself")
        check(retry?.isHidden == true, "and Try Again goes")
        search("")
        selectFolder(named: "Inbox")
    }

    func outboxAndDrafts() async throws {
        step("the Outbox: a send that can not go")
        try await setSmtpPort("1")
        command(.newMail)
        guard var compose = await waitCompose() else { throw Failed(description: "no compose window") }
        type("Erin <erin@example.com>", into: field("compose.to", compose))
        type("Waited in the Outbox in the UI test", into: field("compose.subject", compose))
        _ = await typeInEditor(compose, "This waited in the Outbox.")
        send(compose)
        check(await waitUntil { !compose.isVisible }, "Send closes the message")
        let status: NSTextField? = find("status.outbox", in: main.window)
        check(await waitUntil(40) { status?.stringValue.contains("Outbox") == true }, "a send that can not go says it waits in the Outbox")
        check(await findMessage("INBOX", "Subject: Waited in the Outbox") == nil, "and it was not sent")
        command(.outbox)
        if let outbox = await waitWindow("outbox", 10) {
            let list: NSTableView? = find("outbox.list", in: outbox)
            check(list?.numberOfRows == 1, "Tools > Outbox lists the message that waits")
            await shot(outbox, "write-7-outbox")
            NSApp.stopModal()
            _ = await waitUntil { !outbox.isVisible }
        } else {
            check(false, "Tools > Outbox opens")
        }
        // the server back: the settings change syncs the account, and a sync sends the Outbox first
        try await setSmtpPort(port("smtp"))
        check(await waitFor(30) { await findMessage("INBOX", "Subject: Waited in the Outbox") } != nil, "once the server is back it goes by itself")

        step("Drafts")
        command(.newMail)
        guard let draft = await waitCompose() else { throw Failed(description: "no compose window") }
        compose = draft
        type("Fay <fay@example.com>", into: field("compose.to", compose))
        type("Draft from the UI test", into: field("compose.subject", compose))
        _ = await typeInEditor(compose, "Half written.")
        // closing what was written asks whether to keep it; Save saves it in Drafts
        onMain { compose.performClose(nil) }
        let ask = await waitWindow("alert", 10)
        check(ask != nil, "closing a written message asks to save it")
        await shot(ask, "write-8-save-draft")
        answer(ask, "Save")
        check(await waitUntil { !compose.isVisible }, "Save saves it and closes the window")
        let saved = await waitFor(30) { await findMessage("Drafts", "Subject: Draft from the UI test") }
        check(saved != nil, "the draft is in Drafts on the server")
        check((saved?["flags"] as? [String])?.contains("\\Draft") == true, "marked as a draft")
        selectFolder(named: "Drafts")
        check(await waitUntil { list.numberOfRows >= 1 }, "Drafts lists it")
        await selectRow(0)
        main.mailbox.openSelected()
        guard let reopened = await waitFor(20, { ComposeWindow.open.last.flatMap { $0.window.title == "Draft from the UI test" ? $0.window : nil } })
        else { throw Failed(description: "the draft did not open") }
        compose = reopened
        check(field("compose.to", compose)?.stringValue.contains("fay@example.com") == true, "opening the draft has its recipient")
        _ = await typeInEditor(compose, " Now finished.")
        await shot(compose, "write-9-draft-reopened")
        // saved again: one draft, the new one
        onMain { _ = ComposeWindow.open.last?.window.toolbar?.items.first { $0.itemIdentifier.rawValue == "save" }.map { item in
            NSApp.sendAction(item.action!, to: item.target, from: item)
        } }
        check(await waitUntil(30) {
            let drafts = await messages("Drafts")
            return drafts.count == 1 && raw(drafts[0]).contains("Now finished")
        }, "Save replaces the draft")
        let composeStatus: NSTextField? = find("compose.status", in: compose)
        check(await waitUntil(30) { composeStatus?.stringValue.hasPrefix("Saved in Drafts at") == true }, "the window says when the draft is saved")
        await shot(compose, "write-10-draft-saved")
        send(compose)
        let finished = await waitFor(30) { await findMessage("INBOX", "Subject: Draft from the UI test") }
        check(finished.map { raw($0).contains("Half written") && raw($0).contains("Now finished") } == true, "the finished draft is sent with all that was written")
        check(await waitUntil(30) { await messages("Drafts").isEmpty }, "and its draft is gone")
        selectFolder(named: "Inbox")

        step("Send/Recv")
        try await addMessage("From: Ann Example <ann@example.com>\r\nTo: testuser@inboxclassic.test\r\nSubject: One more thing\r\n"
            + "Message-ID: <later@example.com>\r\nDate: \(rfc2822(Date()))\r\n\r\nArrived later.\r\n")
        command(.sync)
        let arrived = await waitFor(30) { await findMessage("INBOX", "Subject: One more thing") } != nil
        let listed = await waitUntil(30) { list.numberOfRows >= 8 }
        check(arrived && listed, "the new mail is in the list")
        await shot(main.window, "main-2-new-mail")
    }

    func rfc2822(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = "EEE, d MMM yyyy HH:mm:ss '+0000'"
        return formatter.string(from: date)
    }

    // ---- files ----

    func files() async throws {
        step("saving and importing a message as a file")
        selectFolder(named: "Inbox")
        _ = await waitUntil { list.numberOfRows >= 8 }
        // Carol's reply, the last row (the oldest)
        await selectRow(list.numberOfRows - 1)
        let eml = out.appendingPathComponent("saved-message.eml")
        try? FileManager.default.removeItem(at: eml)
        var suggested: String?
        TestHooks.save = { name in
            suggested = name
            return eml
        }
        command(.saveAs)
        check(await waitUntil(10) { suggested != nil }, "Save As asks where")
        check(suggested?.contains("Lunch on Friday") == true, "with the subject as the name (\(suggested ?? ""))")
        check(await waitUntil(10) { (try? String(contentsOf: eml, encoding: .utf8))?.contains("Subject: Re: Lunch on Friday") == true },
              "and saves the message as it came")
        TestHooks.save = nil
        selectFolder(named: "Archive")
        TestHooks.open = { _ in [eml] }
        command(.import)
        check(await waitFor(20) { await findMessage("Archive", "Subject: Re: Lunch on Friday") } != nil,
              "Import Messages puts it in the folder, on the server")
        TestHooks.open = nil
        selectFolder(named: "Inbox")
    }

    // ---- organizing ----

    func organizing() async throws {
        step("flagging, deleting and moving")
        selectFolder(named: "Inbox")
        _ = await waitUntil { list.numberOfRows >= 8 }
        // the newest message, "One more thing"
        await selectRow(0)
        let pictures: InfoBar? = find("reader.pictures", in: main.window)
        check(pictures?.isHidden == true, "a plain text message does not offer Download pictures")
        command(.flag)
        check(await waitUntil { (await findMessage("INBOX", "Subject: One more thing")?["flags"] as? [String])?.contains("\\Flagged") == true },
              "Flag Message flags it on the server")
        await pause(0.5)
        await shot(main.window, "organize-1-flagged")
        let listed = list.numberOfRows
        command(.delete)
        check(await waitFor(20) { await findMessage("Trash", "Subject: One more thing") } != nil, "Delete puts it in Deleted Items")
        check(await waitUntil { list.numberOfRows == listed - 1 }, "the list has one less")
        // the next one is selected: move it to Archive through the dialog
        command(.move)
        let move = await waitWindow("move", 10)
        check(move != nil, "Move to Folder asks where")
        if let move {
            choose(folder(ofAccount: 0, named: "Archive"), in: move)
            await shot(move, "organize-2-move")
            press(find("move.ok", in: move))
            check(await waitUntil { list.numberOfRows == listed - 2 }, "the selected message is out of the list")
        }
        await shot(main.window, "organize-3-after")
        // from Deleted Items it is gone for good, after asking
        selectFolder(named: "Deleted Items")
        _ = await waitUntil { list.numberOfRows >= 1 }
        await selectRow(0)
        command(.delete)
        let sure = await waitWindow("alert", 10)
        check(sure != nil, "deleting for good asks first")
        await shot(sure, "organize-4-for-good")
        answer(sure, "Delete")
        check(await waitUntil(20) { await findMessage("Trash", "Subject: One more thing") == nil }, "and then it is gone from the server")
        selectFolder(named: "Inbox")
    }

    // ---- what mailing lists, invitations and brands send ----

    /// A server on this Mac that takes connections and says nothing, until it is stopped: a mail server that does not
    /// answer
    final class SilentServer: @unchecked Sendable {
        let port: UInt16
        private let socket: Int32
        private var clients: [Int32] = []
        private let lock = NSLock()

        init?() {
            guard let (fd, port) = UITest.loopbackListener(backlog: 8) else { return nil }
            socket = fd
            self.port = port
            Thread.detachNewThread { [self] in
                while true {
                    let client = accept(fd, nil, nil)
                    if client < 0 { return }
                    lock.lock()
                    clients.append(client)
                    lock.unlock()
                }
            }
        }

        /// every connection closed, and no more taken
        func stop() {
            lock.lock()
            clients.forEach { close($0) }
            clients.removeAll()
            lock.unlock()
            shutdown(socket, SHUT_RDWR)
            close(socket)
        }
    }

    /// a one-shot HTTP server on this Mac: the request it got, once one came
    /// a socket listening on a port of 127.0.0.1 the system picked, and that port
    nonisolated static func loopbackListener(backlog: Int32) -> (Int32, UInt16)? {
        let fd = Darwin.socket(AF_INET, SOCK_STREAM, 0)
        var address = sockaddr_in()
        address.sin_family = sa_family_t(AF_INET)
        address.sin_addr.s_addr = inet_addr("127.0.0.1")
        var length = socklen_t(MemoryLayout<sockaddr_in>.size)
        let bound = withUnsafePointer(to: &address) {
            $0.withMemoryRebound(to: sockaddr.self, capacity: 1) { bind(fd, $0, length) }
        }
        guard bound == 0, listen(fd, backlog) == 0 else {
            close(fd)
            return nil
        }
        withUnsafeMutablePointer(to: &address) {
            $0.withMemoryRebound(to: sockaddr.self, capacity: 1) { _ = getsockname(fd, $0, &length) }
        }
        return (fd, UInt16(bigEndian: address.sin_port))
    }

    final class ListServer: @unchecked Sendable {
        let port: UInt16
        private let socket: Int32
        private(set) var request = ""
        private let lock = NSLock()

        init?() {
            guard let (fd, port) = UITest.loopbackListener(backlog: 1) else { return nil }
            socket = fd
            self.port = port
            Thread.detachNewThread { [self] in serve(fd) }
        }

        /// one request, answered 200
        private func serve(_ fd: Int32) {
            let client = accept(fd, nil, nil)
            guard client >= 0 else { return }
            var buffer = [UInt8](repeating: 0, count: 4096)
            var got = ""
            while !got.contains("One-Click") {
                let read = Darwin.read(client, &buffer, buffer.count)
                if read <= 0 { break }
                got += String(decoding: buffer[0..<read], as: UTF8.self)
            }
            let answer = "HTTP/1.0 200 OK\r\nContent-Length: 2\r\n\r\nok"
            _ = answer.withCString { Darwin.write(client, $0, strlen($0)) }
            close(client)
            lock.lock()
            request = got
            lock.unlock()
        }

        var received: String {
            lock.lock()
            defer { lock.unlock() }
            return request
        }

        deinit { close(socket) }
    }

    func listMail() async throws {
        step("unsubscribing")
        guard let server = ListServer() else { throw Failed(description: "no list server") }
        try await addMessage("Authentication-Results: mx.inboxclassic.test; dkim=pass header.d=list.example.com\r\n"
            + "DKIM-Signature: v=1; d=list.example.com; s=s1; h=from:subject:list-unsubscribe:list-unsubscribe-post; bh=x; b=y\r\n"
            + "From: Weekly List <news@list.example.com>\r\nTo: testuser@inboxclassic.test\r\nSubject: Weekly list news\r\n"
            + "Date: \(rfc2822(Date()))\r\nMessage-ID: <weekly-list@list.example.com>\r\n"
            + "List-Unsubscribe: <mailto:leave@list.example.com>, <http://127.0.0.1:\(server.port)/u/42>\r\n"
            + "List-Unsubscribe-Post: List-Unsubscribe=One-Click\r\n\r\nThis week on the list.\r\n")
        command(.sync)
        _ = await waitFor(20) { await findMessage("INBOX", "Subject: Weekly list news") }
        search("subject:\"Weekly list news\"")
        _ = await waitUntil(20) { list.numberOfRows == 1 }
        await selectRow(0)
        let unsubscribe: NSButton? = find("reader.unsubscribe", in: main.window)
        check(await waitUntil(15) { unsubscribe?.isHidden == false }, "a message of a mailing list has Unsubscribe in its header")
        await shot(main.window, "read-8-unsubscribe")
        press(unsubscribe)
        let sure = await waitWindow("alert", 10)
        check(alertText(sure).contains("127.0.0.1"), "it asks first, naming where it goes")
        await shot(sure, "read-9-unsubscribe-ask")
        answer(sure, "Yes")
        check(await waitUntil(15) { server.received.hasPrefix("POST /u/42 ") && server.received.contains("List-Unsubscribe=One-Click") },
              "Yes posts List-Unsubscribe=One-Click to the list")
        let status: NSTextField? = find("status.text", in: main.window)
        check(await waitUntil(10) { status?.stringValue.contains("Unsubscribe request accepted") == true }, "and the status bar says it is done")
        search("")

        step("a calendar invitation")
        try await addMessage("From: Ann Example <ann@example.com>\r\nTo: testuser@inboxclassic.test\r\nSubject: Invitation: Quarterly planning\r\n"
            + "Date: \(rfc2822(Date()))\r\nMessage-ID: <planning-invite@example.com>\r\n"
            + "Content-Type: multipart/mixed; boundary=inv\r\n\r\n--inv\r\nContent-Type: text/plain\r\n\r\nLet us plan the quarter.\r\n"
            + "--inv\r\nContent-Type: text/calendar; method=REQUEST; charset=utf-8\r\n\r\n"
            + "BEGIN:VCALENDAR\r\nMETHOD:REQUEST\r\nBEGIN:VEVENT\r\nUID:planning@example.com\r\nSUMMARY:Quarterly planning\r\n"
            + "DTSTART:20261201T100000Z\r\nDTEND:20261201T113000Z\r\nLOCATION:Room 2\r\nORGANIZER;CN=Ann Example:mailto:ann@example.com\r\n"
            + "ATTENDEE;CN=Test:mailto:testuser@inboxclassic.test\r\nRRULE:FREQ=WEEKLY;BYDAY=TU;COUNT=4\r\nEND:VEVENT\r\nEND:VCALENDAR\r\n--inv--\r\n")
        command(.sync)
        _ = await waitFor(20) { await findMessage("INBOX", "Subject: Invitation: Quarterly planning") }
        search("subject:\"Quarterly planning\"")
        _ = await waitUntil(20) { list.numberOfRows == 1 }
        await selectRow(0)
        let invitation: InfoBar? = find("reader.invitation", in: main.window)
        check(await waitUntil(15) { invitation?.isHidden == false && invitation?.title.contains("Quarterly planning") == true },
              "a message with an invitation shows the event over the text, with Open in Calendar")
        await shot(main.window, "read-10-invitation")
        search("")

        step("a brand logo (BIMI)")
        let svg = "<svg xmlns=\"http://www.w3.org/2000/svg\" version=\"1.2\" baseProfile=\"tiny-ps\" viewBox=\"0 0 100 100\"><title>Brand</title>"
            + "<rect width=\"100\" height=\"100\" rx=\"22\" fill=\"#0a5bd3\"/><circle cx=\"50\" cy=\"50\" r=\"26\" fill=\"#ffffff\"/><circle cx=\"50\" cy=\"50\" r=\"13\" fill=\"#0a5bd3\"/></svg>"
        try await addMessage("Authentication-Results: mx.inboxclassic.test; dmarc=pass header.from=brand.example; bimi=pass header.d=brand.example\r\n"
            + "BIMI-Indicator: \(Data(svg.utf8).base64EncodedString())\r\nFrom: Brand <hello@brand.example>\r\nTo: testuser@inboxclassic.test\r\n"
            + "Subject: News from the brand\r\nDate: \(rfc2822(Date()))\r\nMessage-ID: <brand-news@brand.example>\r\n\r\nOur news.\r\n")
        command(.sync)
        _ = await waitFor(20) { await findMessage("INBOX", "Subject: News from the brand") }
        search("subject:\"News from the brand\"")
        _ = await waitUntil(20) { list.numberOfRows == 1 }
        await selectRow(0)
        let logo = views(NSImageView.self, in: main.mailbox.reader.view).first { $0.frame.width == 48 }
        check(await waitUntil(15) { logo?.isHidden == false && logo?.image != nil }, "a sender whose logo the server passed has it beside the header")
        await shot(main.window, "read-11-logo")
        search("")

        step("a collapsed account")
        let rowLabel = { (row: Int) -> String in
            (self.tree.view(atColumn: 0, row: row, makeIfNecessary: true) as? FolderCell)?.accessibilityLabel() ?? ""
        }
        let inboxRow = (0..<tree.numberOfRows).first { (tree.item(atRow: $0) as? Mailbox.FolderNode)?.folder.name == "Inbox" } ?? 1
        let inboxUnread = (tree.item(atRow: inboxRow) as? Mailbox.FolderNode)?.folder.unread ?? 0
        check(inboxUnread >= 1, "the Inbox has unread messages (\(rowLabel(inboxRow)))")
        tree.collapseItem(tree.item(atRow: 0))
        check(await waitUntil(5) { rowLabel(0).hasSuffix("unread") && (tree.view(atColumn: 0, row: 0, makeIfNecessary: true) as? FolderCell)?.unreadShown ?? 0 >= inboxUnread },
              "collapsed, the account shows the unread messages of its folders (\(rowLabel(0)))")
        check((tree.view(atColumn: 0, row: 0, makeIfNecessary: true) as? FolderCell)?.isBold == true, "and is bold")
        await shot(main.window, "folders-5-collapsed")
        tree.expandItem(tree.item(atRow: 0))
        check(await waitUntil(5) { !rowLabel(0).hasSuffix("unread") && rowLabel(inboxRow).hasSuffix("unread") },
              "expanded, the count is back on the Inbox alone")

        try await agent()

        step("marking all read")
        selectFolder(named: "Inbox")
        _ = await waitUntil { list.numberOfRows >= 5 }
        check(await unreadOnServer() >= 1, "the Inbox has unread messages")
        command(.markAllRead)
        let counts: NSTextField? = find("status.counts", in: main.window)
        check(await waitUntil(10) { counts?.stringValue.contains(", 0 unread") == true }, "Mark All Read: none unread in the folder")
        check(await waitUntil(20) { await unreadOnServer() == 0 }, "and none on the server")
        await shot(main.window, "organize-5-all-read")

        try await severalMessages()
        try await messagesAsFiles()
        try await flagColors()

        step("junk and not junk")
        await selectRow(0)
        let first = list.selectedRow >= 0 ? main.mailbox.selectedRow?.subject ?? "" : ""
        command(.junk)
        let junked = await waitFor(20) { await findMessage("Junk", "Subject: \(NSRegularExpression.escapedPattern(for: first))") }
        check(junked != nil, "Junk moves the message to Junk E-mail")
        check((junked?["flags"] as? [String])?.contains("$Junk") == true, "with the $Junk keyword")
        selectFolder(named: "Junk E-mail")
        _ = await waitUntil(20) { list.numberOfRows >= 1 }
        await selectRow(0)
        check(main.mailbox.inJunk, "in Junk E-mail the toolbar has Not Junk in place of Junk")
        await shot(main.window, "organize-7-junk")
        command(.notJunk)
        let back = await waitFor(20) { await findMessage("INBOX", "Subject: \(NSRegularExpression.escapedPattern(for: first))") }
        check((back?["flags"] as? [String])?.contains("$NotJunk") == true, "Not Junk moves it back to the Inbox, with $NotJunk")
        selectFolder(named: "Inbox")

        step("archive")
        _ = await waitUntil(20) { list.numberOfRows >= 3 }
        await selectRow(0)
        let archived = main.mailbox.selectedRow?.subject ?? ""
        check(main.mailbox.canArchive, "Archive is on for a message of the Inbox")
        command(.archive)
        let pattern = "Subject: \(NSRegularExpression.escapedPattern(for: archived))"
        check(await waitFor(20) { await findMessage("Archive", pattern) } != nil, "Archive moves the message to Archive on the server")
        check(await findMessage("INBOX", pattern) == nil, "and out of the Inbox")
        let said: NSTextField? = find("status.text", in: main.window)
        check(await waitUntil(10) { said?.stringValue.hasPrefix("Archived 1 message") == true },
              "the status bar says it was archived (\(said?.stringValue ?? ""))")
        await shot(main.window, "organize-8-archive")
        command(.undo)
        check(await waitFor(20) { await findMessage("INBOX", pattern) } != nil, "Undo puts it back in the Inbox")

        step("empty folder")
        try await addMessage("From: Spammer <spam@example.net>\r\nTo: testuser@inboxclassic.test\r\nSubject: Win a prize\r\n\r\nClick.\r\n",
                             to: "Junk")
        selectFolder(named: "Junk E-mail")
        command(.sync)
        _ = await waitUntil(20) { list.numberOfRows >= 1 }
        check(main.mailbox.canEmptyFolder, "Empty Folder is on in Junk E-mail")
        command(.emptyFolder)
        let emptying = await waitWindow("alert", 10)
        check(emptying != nil, "Empty Folder asks first, saying how many go")
        await shot(emptying, "organize-9-empty")
        answer(emptying, Text.uiEmptyButton.text)
        check(await waitUntil(20) { await findMessage("Junk", "Subject: Win a prize") == nil }, "Junk E-mail is empty on the server")
        check(await waitUntil(10) { list.numberOfRows == 0 }, "and in the list")
        selectFolder(named: "Inbox")

        try await messageWindow()
        try await keyboardReading()
        try await conversations()
        try await bounces()
        try await oneTimeCodes()
        try await watchAndIgnore()
    }

    // ---- reading with the keyboard ----

    /// the selection of the reading pane's document: what Find in This Message found
    func readerSelection() async -> String {
        guard let web = views(WKWebView.self, in: main.mailbox.reader.view).first else { return "" }
        return (try? await web.evaluateJavaScript("String(window.getSelection())")) as? String ?? ""
    }

    func keyboardReading() async throws {
        step("keyboard reading")
        selectFolder(named: "Inbox")
        _ = await waitUntil(20) { list.numberOfRows >= 4 }
        await selectRow(1)
        command(.nextMessage)
        check(await waitUntil(5) { list.selectedRow == 2 && main.mailbox.selectedRow?.uid != nil },
              "Next Message selects the message below in the list")
        command(.previousMessage)
        check(await waitUntil(5) { list.selectedRow == 1 }, "Previous Message the one above")

        // one unread message below, and unread mail in Archive
        try await addMessage("From: Ann Example <ann@example.com>\r\nTo: testuser@inboxclassic.test\r\nSubject: Unread in the archive\r\n"
            + "Message-ID: <unread-archive@example.com>\r\nDate: \(rfc2822(Date()))\r\n\r\nStill unread.\r\n", to: "Archive")
        command(.sync)
        _ = await waitUntil(20) { (folderNode("Archive")?.folder.unread ?? 0) >= 1 }
        await selectRow(3)
        command(.markUnread)
        _ = await waitUntil(10) { main.mailbox.row(3)?.seen == false }
        let unread = main.mailbox.row(3)?.uid
        await selectRow(0)
        command(.nextUnread)
        check(await waitUntil(5) { list.selectedRow == 3 && main.mailbox.selectedRow?.uid == unread },
              "Next Unread Message selects the next unread message")
        // read once shown; none after it in the Inbox
        _ = await waitUntil(10) { main.mailbox.row(3)?.seen == true }
        command(.nextUnread)
        let goOn = await waitWindow("alert", 10)
        check(alertText(goOn).contains("no more unread messages in Inbox"),
              "with none left in the folder it asks to go on to the next folder with unread mail (\(alertText(goOn)))")
        answer(goOn, "Yes")
        check(await waitUntil(10) { main.mailbox.selectedName == "Archive" && main.mailbox.selectedRow?.subject == "Unread in the archive" },
              "and Yes goes there, its unread message selected (\(main.mailbox.selectedName): \(main.mailbox.selectedRow?.subject ?? "none"))")

        command(.goToFolder)
        guard let goTo = await waitWindow("move", 10) else { throw Failed(description: "Go to Folder opened nothing") }
        // the folders fill in after the window opens
        let everyAccount = await waitUntil(10) {
            moveRows(goTo).contains { $0.kind == .account } && moveRows(goTo).contains { $0.name == "Sent Items" }
        }
        check(goTo.title == "Go to Folder" && everyAccount, "Go to Folder shows the folders of every account (\(goTo.title))")
        if let filter: NSSearchField = find("move.filter", in: goTo) {
            filter.stringValue = "sent"
            (goTo.delegate as? MoveWindow)?.controlTextDidChange(Notification(name: NSControl.textDidChangeNotification))
        }
        let narrowed = moveRows(goTo).filter { $0.kind == .folder }
        check(!narrowed.isEmpty && narrowed.allSatisfy { $0.name.localizedCaseInsensitiveContains("sent") }, "and typing narrows them")
        if let sent = narrowed.first(where: { $0.name == "Sent Items" }) {
            choose(sent.folder, in: goTo)
        }
        await shot(goTo, "read-18-go-to")
        press(find("move.ok", in: goTo))
        if !(await waitUntil(5) { !goTo.isVisible }) {
            press(find("move.cancel", in: goTo))
        }
        check(await waitUntil(10) { main.mailbox.selectedName == "Sent Items" }, "choosing Sent Items there shows Sent Items")

        step("find in this message")
        selectFolder(named: "Inbox")
        _ = await waitUntil(20) { list.numberOfRows >= 2 }
        await selectRow(0)
        _ = await waitUntil(15) {
            guard main.mailbox.reader.messageView != nil else { return false }
            return await !readerText().isEmpty
        }
        let words = (await readerText()).split(whereSeparator: { !$0.isLetter }).map(String.init)
        guard let word = words.first(where: { $0.count >= 4 }) else { throw Failed(description: "no word in the message") }
        command(.findInMessage)
        guard let bar: FindBar = find("find.bar", in: main.window) else { throw Failed(description: "no find bar") }
        check(await waitUntil(5) { !bar.isHidden && (main.window.firstResponder as? NSText)?.delegate === bar.field },
              "Find in This Message opens a find bar over the message, the keyboard in it")
        check(bar.field.placeholderString == Text.uiFindInMessageHint.text, "which asks for the words")
        type(word, into: bar.field)
        check(await waitUntil(5) { (await readerSelection()).caseInsensitiveCompare(word) == .orderedSame },
              "it finds a word of the message shown as it is typed (\(word))")
        await shot(main.window, "read-17-find")
        onMain { bar.next() }
        let note: NSTextField? = find("find.note", in: main.window)
        check(await waitUntil(3) { (await readerSelection()).caseInsensitiveCompare(word) == .orderedSame } && note?.stringValue.isEmpty == true,
              "Return finds the next place")
        type("zqxjvbnotthere", into: bar.field)
        check(await waitUntil(5) { note?.stringValue == Text.uiFindNotFound.text(["words": "zqxjvbnotthere"]) },
              "and the bar says when it is not there (\(note?.stringValue ?? ""))")
        let escape = NSEvent.keyEvent(with: .keyDown, location: .zero, modifierFlags: [], timestamp: 0,
                                      windowNumber: main.window.windowNumber, context: nil, characters: "\u{1b}",
                                      charactersIgnoringModifiers: "\u{1b}", isARepeat: false, keyCode: 53)
        onMain { if let escape { _ = self.main.window.performKeyEquivalent(with: escape) } }
        check(await waitUntil(3) { bar.isHidden }, "Esc closes the bar")
    }

    // ---- conversations ----

    /// the files of a drag out written into `folder`, as the Finder asks for them where they are dropped: off the main
    /// thread, as the promises' queue runs them; false when not all were written in time
    func writePromises(_ promises: [MessagePromise], into folder: URL) async -> Bool {
        let writer = main.mailbox.filePromises
        var finished = 0
        for promise in promises {
            guard let drag = promise.drag else { continue }
            let name = writer.filePromiseProvider(promise, fileNameForType: emlType.identifier)
            let job = Handed(value: (writer, drag, promise.index, folder.appendingPathComponent(name)))
            Thread.detachNewThread {
                let (writer, drag, index, url) = job.value
                writer.write(drag, index, to: url)
                onMain { finished += 1 }
            }
        }
        let done = await waitUntil(60) { finished == promises.count }
        main.mailbox.dragEnded()
        return done
    }

    /// the rows of the list whose subject is the conversation's
    func tripRows() -> [(index: Int, message: Message)] {
        (0..<list.numberOfRows).compactMap { at in
            guard let message = main.mailbox.row(at), message.subject.hasSuffix("Plans for the trip") else { return nil }
            return (at, message)
        }
    }

    /// the Subject cell of a row as the list draws it
    func subjectCell(_ index: Int) -> SubjectCell? {
        guard let column = list.tableColumns.firstIndex(where: { $0.identifier.rawValue == "subject" }) else { return nil }
        return list.view(atColumn: column, row: index, makeIfNecessary: true) as? SubjectCell
    }

    /// an arrow key on the list, as the keyboard sends it
    func arrowKey(_ code: UInt16) {
        let character = String(UnicodeScalar(code == 124 ? 0xF703 : 0xF702)!)
        let event = NSEvent.keyEvent(with: .keyDown, location: .zero, modifierFlags: [.numericPad, .function], timestamp: 0,
                                     windowNumber: main.window.windowNumber, context: nil, characters: character,
                                     charactersIgnoringModifiers: character, isARepeat: false, keyCode: code)
        onMain { if let event { self.list.keyDown(with: event) } }
    }

    func conversations() async throws {
        step("conversations")
        selectFolder(named: "Inbox")
        // the first read, its two replies not; the newest of them puts the conversation at the top
        let tripStart = Date()
        try await addMessage("From: Dave <dave@example.com>\r\nTo: testuser@inboxclassic.test\r\nSubject: Plans for the trip\r\n"
            + "Message-ID: <trip1@example.com>\r\nDate: \(rfc2822(tripStart.addingTimeInterval(-7200)))\r\n\r\nWhere do we go?\r\n",
            flags: ["\\Seen"])
        try await addMessage("From: Carol <carol@example.com>\r\nTo: testuser@inboxclassic.test\r\nSubject: Re: Plans for the trip\r\n"
            + "Message-ID: <trip2@example.com>\r\nIn-Reply-To: <trip1@example.com>\r\nReferences: <trip1@example.com>\r\n"
            + "Date: \(rfc2822(tripStart.addingTimeInterval(-3600)))\r\n\r\nThe lake.\r\n")
        try await addMessage("From: Bob Harris <bob@example.com>\r\nTo: testuser@inboxclassic.test\r\nSubject: Re: Plans for the trip\r\n"
            + "Message-ID: <trip3@example.com>\r\nIn-Reply-To: <trip2@example.com>\r\n"
            + "References: <trip1@example.com> <trip2@example.com>\r\nDate: \(rfc2822(tripStart))\r\n\r\nThe lake it is.\r\n")
        command(.sync)
        check(await waitUntil(30) { tripRows().count == 1 && tripRows().first?.message.threadCount == 3 },
              "the Inbox lists the conversation once (\(tripRows().count) rows)")
        guard let tripHead = tripRows().first else { throw Failed(description: "the conversation is not in the list") }
        check(tripHead.message.subject == "Plans for the trip" && tripHead.message.seen,
              "on its first message (\(tripHead.message.subject))")
        let headCell = subjectCell(tripHead.index)
        check(headCell?.textField?.stringValue == "Plans for the trip (3)" && headCell?.disclosure.isHidden == false,
              "with the count of its messages and a triangle to open it (\(headCell?.textField?.stringValue ?? ""))")
        check(headCell?.textField?.font?.fontDescriptor.symbolicTraits.contains(.bold) == true,
              "bold while one is unread, though the first is read")
        await selectRow(tripHead.index)
        await shot(main.window, "threads-1-collapsed")

        press(subjectCell(tripHead.index)?.disclosure)
        check(await waitUntil(5) { tripRows().count == 3 }, "the triangle opens it: its replies under it")
        let opened = tripRows()
        check(opened.map(\.index) == [tripHead.index, tripHead.index + 1, tripHead.index + 2]
              && opened.dropFirst().allSatisfy { $0.message.threadDepth == 1 && $0.message.subject == "Re: Plans for the trip" },
              "right under it, oldest first")
        let headLeft = subjectCell(tripHead.index)?.textField?.frame.minX ?? 0
        let replyLeft = subjectCell(tripHead.index + 1)?.textField?.frame.minX ?? 0
        check(replyLeft > headLeft, "indented (\(headLeft) and \(replyLeft))")
        check(subjectCell(tripHead.index)?.textField?.font?.fontDescriptor.symbolicTraits.contains(.bold) == false,
              "the open conversation's first row in bold only when it is unread itself")
        await selectRow(tripHead.index + 1)
        await shot(main.window, "threads-2-expanded")

        arrowKey(123)
        check(await waitUntil(5) { tripRows().count == 1 && list.selectedRow == tripHead.index },
              "Left on a reply closes it, its row selected")
        arrowKey(124)
        check(await waitUntil(5) { tripRows().count == 3 }, "Right opens it again")
        command(.collapseAllThreads)
        check(await waitUntil(5) { tripRows().count == 1 }, "Collapse All Conversations closes it")
        command(.expandAllThreads)
        check(await waitUntil(5) { tripRows().count == 3 }, "Expand All Conversations opens it")
        command(.collapseAllThreads)
        _ = await waitUntil(5) { tripRows().count == 1 }

        await selectRow(tripRows().first?.index ?? 0)
        command(.markRead)
        check(await waitUntil(20) {
            let all = await messages("INBOX").filter { raw($0).contains("@example.com>") && raw($0).contains("Plans for the trip") }
            return all.count == 3 && all.allSatisfy { ($0["flags"] as? [String])?.contains("\\Seen") == true }
        }, "Mark Read on the closed conversation marks all three read on the server")

        // dragged out: the closed row carries the three messages, to the Finder as to a folder
        let tripRow = tripRows().first?.index ?? 0
        // the item the list makes for the row, over the row
        let tripItems: [NSDraggingItem] = main.mailbox.promise(forRow: tripRow).map { promise -> [NSDraggingItem] in
            let item = NSDraggingItem(pasteboardWriter: promise)
            item.setDraggingFrame(list.rect(ofRow: tripRow), contents: nil)
            return main.mailbox.completeDrag([item])
        } ?? []
        let tripPromises = tripItems.compactMap { $0.item as? MessagePromise }
        let tripDropped = emptyFolder("dragged-conversation")
        _ = await writePromises(tripPromises, into: tripDropped)
        let tripFiles = (try? FileManager.default.contentsOfDirectory(atPath: tripDropped.path)) ?? []
        check(tripPromises.count == 3 && tripFiles.count == 3,
              "the closed conversation dragged to the Finder becomes its three .eml files (\(tripFiles.sorted().joined(separator: ", ")))")
        let tripRefs = tripPromises.compactMap { promise in promise.drag.map { $0.refs[promise.index] } }
        if let archiveId = folderNode("Archive")?.folder.id {
            check(main.mailbox.drop(tripRefs, to: archiveId, copy: false), "dropped onto Archive, it is taken")
            check(await waitUntil(30) {
                let moved = await messages("Archive").filter { raw($0).contains("Plans for the trip") }
                let left = await messages("INBOX").filter { raw($0).contains("Plans for the trip") }
                return moved.count == 3 && left.isEmpty
            }, "and all three are moved there on the server")
            command(.undo)
            check(await waitUntil(30) { await messages("INBOX").filter { raw($0).contains("Plans for the trip") }.count == 3 },
                  "Undo puts the three back in the Inbox")
            _ = await waitUntil(20) { tripRows().count == 1 }
        }

        command(.options)
        guard await waitWindow("settings", 10) != nil, let options = SettingsWindow.current else {
            throw Failed(description: "Settings did not open")
        }
        check(options.grouping.state == .on, "Group messages by conversation is on in Settings")
        onMain { options.grouping.state = .off; options.groupingChanged() }
        check(await waitUntil(5) { tripRows().count == 3 && tripRows().allSatisfy { $0.message.thread == 0 } },
              "turned off, the three messages are each a row of their own")
        // the list from its top, the main window in front
        onMain {
            self.list.scrollRowToVisible(0)
            self.main.window.makeKeyAndOrderFront(nil)
        }
        await shot(main.window, "threads-3-options-off")
        onMain { options.grouping.state = .on; options.groupingChanged() }
        check(await waitUntil(5) { tripRows().count == 1 }, "turned on again, the conversation is one row again")
        onMain { options.window.close() }
    }

    // ---- watching and ignoring a conversation ----

    /// the item of `command` in the menu bar, its check mark set as when its menu opens
    func menuItem(_ command: Command) -> NSMenuItem? {
        func search(_ menu: NSMenu?) -> NSMenuItem? {
            for item in menu?.items ?? [] {
                if item.action == #selector(AppDelegate.runCommand(_:)) && item.tag == command.rawValue { return item }
                if let found = search(item.submenu) { return found }
            }
            return nil
        }
        guard let item = search(NSApp.mainMenu) else { return nil }
        _ = AppDelegate.shared.validateMenuItem(item)
        return item
    }

    /// a letter typed on the list, as the keyboard sends it
    func letterKey(_ letter: String, _ code: UInt16) {
        let event = NSEvent.keyEvent(with: .keyDown, location: .zero, modifierFlags: [], timestamp: 0,
                                     windowNumber: main.window.windowNumber, context: nil, characters: letter,
                                     charactersIgnoringModifiers: letter, isARepeat: false, keyCode: code)
        onMain { if let event { self.list.keyDown(with: event) } }
    }

    /// the glasses or the ignored sign the Watch column shows on row `index`
    func watchMark(_ index: Int) -> NSImage? {
        let column = list.column(withIdentifier: NSUserInterfaceItemIdentifier("watch"))
        guard column >= 0, let cell = list.view(atColumn: column, row: index, makeIfNecessary: true) else { return nil }
        return views(NSImageView.self, in: cell).first?.image
    }

    /// the colour of the sender on row `index`
    func fromColor(_ index: Int) -> NSColor? {
        let column = list.column(withIdentifier: NSUserInterfaceItemIdentifier("from"))
        guard column >= 0 else { return nil }
        return (list.view(atColumn: column, row: index, makeIfNecessary: true) as? NSTableCellView)?.textField?.textColor
    }

    func watchAndIgnore() async throws {
        step("watch and ignore a conversation")
        selectFolder(named: "Inbox")
        final class Announced { var all: [(title: String, text: String)] = [] }
        let announced = Announced()
        TestHooks.notified = { title, text in announced.all.append((title, text)) }
        defer { TestHooks.notified = nil }
        let watchStatus: NSTextField? = find("status.text", in: main.window)

        // Watch Conversation on the conversation of 34e
        _ = await waitUntil(20) { tripRows().count == 1 }
        guard let watchedHead = tripRows().first else { throw Failed(description: "the conversation is not in the list") }
        await selectRow(watchedHead.index)
        check(menuItem(.watchConversation)?.state == .off && menuItem(.ignoreConversation)?.state == .off,
              "Message > Watch Conversation and Ignore Conversation are not checked at first")
        command(.watchConversation)
        check(await waitUntil(10) {
            guard let head = tripRows().first else { return false }
            return head.message.mark == PE_THREAD_MARK_WATCH && watchMark(head.index) != nil
                && menuItem(.watchConversation)?.state == .on
        }, "Watch Conversation shows the glasses and checks the menu item")
        check(watchStatus?.stringValue == "Watching the conversation", "the status bar says so (\(watchStatus?.stringValue ?? ""))")

        // a new reply to it is announced, saying the conversation is watched
        try await addMessage("From: Carol <carol@example.com>\r\nTo: testuser@inboxclassic.test\r\nSubject: Re: Plans for the trip\r\n"
            + "Message-ID: <trip4@example.com>\r\nIn-Reply-To: <trip3@example.com>\r\n"
            + "References: <trip1@example.com> <trip2@example.com> <trip3@example.com>\r\nDate: \(rfc2822(Date()))\r\n\r\n"
            + "Shall I book the cabin?\r\n")
        command(.sync)
        check(await waitUntil(30) {
            announced.all.contains { $0.title == Text.uiWatchedConversation.text && $0.text.contains("Re: Plans for the trip") }
        }, "A new reply to the watched conversation is announced (\(announced.all.map { "\($0.title): \($0.text)" }))")
        check(announced.all.first { $0.title == Text.uiWatchedConversation.text }?.text == "Carol\nRe: Plans for the trip",
              "the notification says who wrote and the subject under its title")
        _ = await waitUntil(20) { tripRows().first?.message.threadCount == 4 }
        // opened, every message of it has the glasses; the new reply selected
        command(.expandAllThreads)
        check(await waitUntil(5) {
            let rows = tripRows()
            return rows.count == 4 && rows.allSatisfy { $0.message.mark == PE_THREAD_MARK_WATCH && watchMark($0.index) != nil }
        }, "every message of the watched conversation has the glasses")
        if let newest = tripRows().last { await selectRow(newest.index) }
        await shot(main.window, "threads-4-watch")
        command(.collapseAllThreads)
        _ = await waitUntil(5) { tripRows().count == 1 }
        await selectRow(tripRows().first?.index ?? 0)
        // read as the others are, for the steps after
        command(.markRead)
        letterKey("w", 13)
        check(await waitUntil(10) {
            guard let head = tripRows().first else { return false }
            return head.message.mark == PE_THREAD_MARK_NONE && watchMark(head.index) == nil
                && menuItem(.watchConversation)?.state == .off
        }, "Watch Conversation again takes the glasses away (W in the list)")
        check(watchStatus?.stringValue == "Stopped watching the conversation",
              "the status bar says so (\(watchStatus?.stringValue ?? ""))")

        // another conversation, older than the rest of the Inbox, its reply unread
        let partySubject = "Office party"
        try await addMessage("From: Erin <erin@example.com>\r\nTo: testuser@inboxclassic.test\r\nSubject: \(partySubject)\r\n"
            + "Message-ID: <party1@example.com>\r\nDate: Sun, 7 Sep 2025 10:00:00 +0000\r\n\r\nWho brings the cake?\r\n",
            flags: ["\\Seen"])
        try await addMessage("From: Frank <frank@example.com>\r\nTo: testuser@inboxclassic.test\r\nSubject: Re: \(partySubject)\r\n"
            + "Message-ID: <party2@example.com>\r\nIn-Reply-To: <party1@example.com>\r\nReferences: <party1@example.com>\r\n"
            + "Date: Sun, 7 Sep 2025 11:00:00 +0000\r\n\r\nI do, and the candles.\r\n")
        command(.sync)
        func partyRow() -> (index: Int, message: Message)? {
            (0..<list.numberOfRows).lazy.compactMap { at in
                self.main.mailbox.row(at).flatMap { $0.subject.hasSuffix(partySubject) ? (at, $0) : nil }
            }.first
        }
        check(await waitUntil(30) { partyRow()?.message.threadCount == 2 }, "the other conversation is in the Inbox")
        guard let party = partyRow() else { throw Failed(description: "the other conversation is not in the list") }
        await selectRow(party.index)
        letterKey("k", 40)
        func partyServerSeen() async -> Bool {
            let all = await messages("INBOX").filter { raw($0).contains("@example.com>") && raw($0).contains(partySubject) }
            return !all.isEmpty && all.allSatisfy { ($0["flags"] as? [String])?.contains("\\Seen") == true }
        }
        check(await waitUntil(20) {
            guard let row = partyRow(), row.message.mark == PE_THREAD_MARK_IGNORE, watchMark(row.index) != nil,
                  fromColor(row.index) == Mailbox.ignoredColor else { return false }
            return await partyServerSeen()
        }, "Ignore Conversation greys the row and marks its messages read on the server (K in the list)")
        check(menuItem(.ignoreConversation)?.state == .on, "and checks Message > Ignore Conversation")
        check(watchStatus?.stringValue == "Ignoring the conversation", "the status bar says so (\(watchStatus?.stringValue ?? ""))")

        // a new reply to it arrives read, and nobody hears of it
        announced.all.removeAll()
        try await addMessage("From: Erin <erin@example.com>\r\nTo: testuser@inboxclassic.test\r\nSubject: Re: \(partySubject)\r\n"
            + "Message-ID: <party3@example.com>\r\nIn-Reply-To: <party2@example.com>\r\n"
            + "References: <party1@example.com> <party2@example.com>\r\nDate: Sun, 7 Sep 2025 12:00:00 +0000\r\n\r\n"
            + "Lovely, thank you.\r\n")
        command(.sync)
        let partyArrived = await waitUntil(30) {
            guard partyRow()?.message.threadCount == 3 else { return false }
            return await partyServerSeen()
        }
        await pause(1)
        check(partyArrived && announced.all.isEmpty,
              "A new reply to the ignored conversation arrives read, without a notification (\(announced.all.map(\.text)))")
        // opened, its messages grey with the sign; the newest selected, the others' grey showing
        command(.expandAllThreads)
        _ = await waitUntil(5) {
            (0..<self.list.numberOfRows).filter { self.main.mailbox.row($0)?.subject.hasSuffix(partySubject) == true }.count == 3
        }
        let partyRows = (0..<list.numberOfRows).filter { main.mailbox.row($0)?.subject.hasSuffix(partySubject) == true }
        check(partyRows.count == 3 && partyRows.allSatisfy { watchMark($0) != nil && fromColor($0) == Mailbox.ignoredColor },
              "every message of the ignored conversation is grey, with the sign")
        if let newest = partyRows.last {
            await selectRow(newest)
            onMain { self.list.scrollRowToVisible(newest) }
        }
        await shot(main.window, "threads-5-ignore")
        command(.collapseAllThreads)
        _ = await waitUntil(5) { partyRow()?.message.opens == true && tripRows().count == 1 }

        // View > Hide Ignored Conversations leaves it out, and back when turned off
        check(menuItem(.hideIgnored)?.state == .off, "View > Hide Ignored Conversations is off at first")
        command(.hideIgnored)
        let hidden = await waitUntil(10) { partyRow() == nil && tripRows().count == 1 }
        check(hidden && menuItem(.hideIgnored)?.state == .on, "it hides the ignored conversation, the others stay")
        command(.hideIgnored)
        check(await waitUntil(10) { partyRow() != nil } && menuItem(.hideIgnored)?.state == .off,
              "Hide Ignored Conversations hides it, and shows it again when turned off")

        // Ignore Conversation again takes the mark away
        if let row = partyRow() { await selectRow(row.index) }
        command(.ignoreConversation)
        check(await waitUntil(10) {
            guard let row = partyRow() else { return false }
            return row.message.mark == PE_THREAD_MARK_NONE && watchMark(row.index) == nil && fromColor(row.index) == .labelColor
        }, "Ignore Conversation again makes it an ordinary conversation")
        check(watchStatus?.stringValue == "Stopped ignoring the conversation",
              "the status bar says so (\(watchStatus?.stringValue ?? ""))")
    }

    // ---- a message that bounced ----

    /// the bounce mark (or the paper clip) the list shows on row `index`
    func listMark(_ index: Int) -> NSImage? {
        let column = list.column(withIdentifier: NSUserInterfaceItemIdentifier("attach"))
        guard column >= 0, let cell = list.view(atColumn: column, row: index, makeIfNecessary: true) else { return nil }
        return views(NSImageView.self, in: cell).first?.image
    }

    /// the row of the list whose subject is `subject`
    func listIndex(subject: String) -> Int? {
        (0..<list.numberOfRows).first { main.mailbox.row($0)?.subject == subject }
    }

    /// a message with a one-time code: one whose code is in its text, from a domain the provider says signed it; one
    /// with an OTP-Token header; one unsigned. Dated before the other messages and read, as the bounces are.
    func oneTimeCodes() async throws {
        step("a one-time code")
        let signed = "Your sign-in code"
        let byHeader = "Sign in to Example"
        let unsigned = "Your code, unsigned"
        let message = { (verdict: Bool, extra: String, subject: String, id: String, body: String) in
            (verdict ? "Authentication-Results: mx.inboxclassic.test; dkim=pass header.d=example.com\r\n" : "") + extra
                + "From: Example Accounts <no-reply@accounts.example.com>\r\nTo: testuser@inboxclassic.test\r\n"
                + "Subject: \(subject)\r\nDate: Mon, 8 Sep 2025 08:00:00 +0000\r\nMessage-ID: <\(id)@example.com>\r\n"
                + "MIME-Version: 1.0\r\nContent-Type: text/plain; charset=utf-8\r\n\r\n\(body)\r\n"
        }
        let code = { (digits: String) in
            "Hello,\r\n\r\nYour verification code is \(digits).\r\n\r\nIt expires in 10 minutes. If you did not ask for it, "
                + "ignore this email."
        }
        try await addMessage(message(true, "", signed, "code-body", code("482913")), flags: ["\\Seen"])
        try await addMessage(message(true, "OTP-Token: \"917355\"; origin=\"https://login.example.com\"\r\n", byHeader,
                                     "code-header", "Use the code at the top of this message to sign in."), flags: ["\\Seen"])
        try await addMessage(message(false, "", unsigned, "code-unsigned", code("771204")), flags: ["\\Seen"])
        command(.sync)
        selectFolder(named: "Inbox")
        guard let row = await waitFor(30, { listIndex(subject: signed) }) else {
            throw Failed(description: "the message with a code did not arrive")
        }
        list.scrollRowToVisible(row)
        await selectRow(row)
        check(await waitUntil(15) { (await readerText()).contains("Code from accounts.example.com") },
              "a code in the text of a message the domain signed is shown in a card above it")
        let card = await readerText()
        check(card.contains("482913") && card.contains("Enter it only on a page of example.com"),
              "with the code, and the domain to enter it on")
        check(card.contains("probably expired"), "a message older than an hour says the code has probably expired")
        await shot(main.window, "otp-1-card")
        NSPasteboard.general.clearContents()
        let preview = views(WKWebView.self, in: main.mailbox.reader.view).first
        _ = try? await preview?.evaluateJavaScript("document.querySelector('a[href=\"inboxclassic:copy-code\"]').click()")
        let status: NSTextField? = find("status.text", in: main.window)
        check(await waitUntil(5) { NSPasteboard.general.string(forType: .string) == "482913" },
              "Copy puts the code on the clipboard (\(NSPasteboard.general.string(forType: .string) ?? "nothing"))")
        check(status?.stringValue == "Copied the code", "and the status bar says so (\(status?.stringValue ?? ""))")

        if let header = listIndex(subject: byHeader) {
            await selectRow(header)
        }
        check(await waitUntil(15) {
            let text = await readerText()
            return text.contains("Code from login.example.com") && text.contains("917355")
        }, "an OTP-Token header gives the code and the domain it is for")
        if let plain = listIndex(subject: unsigned) {
            await selectRow(plain)
        }
        check(await waitUntil(15) { (await readerText()).contains("771204") }, "the unsigned message is shown")
        check(!(await readerText()).contains("Code from"), "without a card: the provider did not say the domain signed it")
    }

    /// the delivery report of a message sent to an address that does not exist, as Postfix writes one, and a notice
    /// that another is delayed; dated before the other messages, so the later steps find their lists as they were
    func bounces() async throws {
        step("a message that bounced")
        let bouncedSubject = "Tickets for the concert"
        let bouncedId = "<concert-tickets@inboxclassic.test>"
        let failedSubject = "Undelivered Mail Returned to Sender"
        let delayedSubject = "Delayed Mail (still being retried)"
        try await addMessage("From: Test User <testuser@inboxclassic.test>\r\nTo: Robin <robin.nobody@example.org>\r\n"
            + "Subject: \(bouncedSubject)\r\nDate: Mon, 8 Sep 2025 09:30:00 +0000\r\nMessage-ID: \(bouncedId)\r\n"
            + "MIME-Version: 1.0\r\nContent-Type: text/plain; charset=utf-8\r\n\r\nHi Robin,\r\n\r\nI got us two tickets for Friday.\r\n",
            flags: ["\\Seen"], to: "Sent")
        let reportBoundary = "5FC8B823C7.1757324000/mx.inboxclassic.test"
        try await addMessage("Return-Path: <>\r\nDate: Mon, 8 Sep 2025 09:30:05 +0000\r\n"
            + "From: MAILER-DAEMON@mx.inboxclassic.test (Mail Delivery System)\r\nSubject: \(failedSubject)\r\n"
            + "To: testuser@inboxclassic.test\r\nAuto-Submitted: auto-replied\r\nMIME-Version: 1.0\r\n"
            + "Content-Type: multipart/report; report-type=delivery-status;\r\n\tboundary=\"\(reportBoundary)\"\r\n"
            + "Message-Id: <20250908093005.5FC8B823C7@mx.inboxclassic.test>\r\n\r\nThis is a MIME-encapsulated message.\r\n\r\n"
            + "--\(reportBoundary)\r\nContent-Description: Notification\r\nContent-Type: text/plain; charset=us-ascii\r\n\r\n"
            + "This is the mail system at host mx.inboxclassic.test.\r\n\r\n"
            + "I'm sorry to have to inform you that your message could not\r\nbe delivered to one or more recipients. It's attached below.\r\n\r\n"
            + "                   The mail system\r\n\r\n"
            + "<robin.nobody@example.org>: host mx.example.org[192.0.2.25] said: 550 5.1.1\r\n"
            + "    The email account that you tried to reach does not exist. (in reply to RCPT\r\n    TO command)\r\n\r\n"
            + "--\(reportBoundary)\r\nContent-Description: Delivery report\r\nContent-Type: message/delivery-status\r\n\r\n"
            + "Reporting-MTA: dns; mx.inboxclassic.test\r\nArrival-Date: Mon, 8 Sep 2025 09:30:00 +0000\r\n\r\n"
            + "Final-Recipient: rfc822; robin.nobody@example.org\r\nOriginal-Recipient: rfc822;robin.nobody@example.org\r\n"
            + "Action: failed\r\nStatus: 5.1.1\r\nRemote-MTA: dns; mx.example.org\r\n"
            + "Diagnostic-Code: smtp; 550 5.1.1 The email account that you tried to reach does not exist\r\n\r\n"
            + "--\(reportBoundary)\r\nContent-Description: Undelivered Message Headers\r\nContent-Type: text/rfc822-headers\r\n\r\n"
            + "From: Test User <testuser@inboxclassic.test>\r\nTo: Robin <robin.nobody@example.org>\r\n"
            + "Subject: \(bouncedSubject)\r\nDate: Mon, 8 Sep 2025 09:30:00 +0000\r\nMessage-ID: \(bouncedId)\r\n\r\n"
            + "--\(reportBoundary)--\r\n", flags: ["\\Seen"])
        try await addMessage("From: Mail Delivery System <MAILER-DAEMON@mx.inboxclassic.test>\r\nTo: testuser@inboxclassic.test\r\n"
            + "Subject: \(delayedSubject)\r\nMessage-ID: <delayed-notice@mx.inboxclassic.test>\r\n"
            + "Date: Sun, 7 Sep 2025 18:00:00 +0000\r\nMIME-Version: 1.0\r\n"
            + "Content-Type: multipart/report; report-type=delivery-status; boundary=\"delay\"\r\n\r\n"
            + "--delay\r\nContent-Type: text/plain\r\n\r\nThis is a warning message only. Delivery is still being retried.\r\n"
            + "--delay\r\nContent-Type: message/delivery-status\r\n\r\nReporting-MTA: dns; mx.inboxclassic.test\r\n\r\n"
            + "Final-Recipient: rfc822; sam@slow.example.net\r\nAction: delayed\r\nStatus: 4.4.1\r\n"
            + "Diagnostic-Code: smtp; 421 4.4.1 Connection timed out\r\nWill-Retry-Until: Mon, 8 Sep 2025 18:00:00 +0000\r\n"
            + "--delay\r\nContent-Type: text/rfc822-headers\r\n\r\nMessage-ID: <slow-reply@inboxclassic.test>\r\n"
            + "From: testuser@inboxclassic.test\r\nTo: sam@slow.example.net\r\nSubject: Re: The garden plan\r\n--delay--\r\n",
            flags: ["\\Seen"])
        command(.sync)
        // the sent message in the store, for the card to link to
        selectFolder(named: "Sent Items")
        check(await waitUntil(30) { listIndex(subject: bouncedSubject) != nil }, "the message that bounces is in Sent Items")

        selectFolder(named: "Inbox")
        guard let failedRow = await waitFor(30, { listIndex(subject: failedSubject) }) else {
            throw Failed(description: "the delivery report did not arrive")
        }
        check(main.mailbox.row(failedRow)?.bounce == true && listMark(failedRow) === Icons.bounce,
              "the report's row has the undelivered mark in the attachment column's place")
        list.scrollRowToVisible(failedRow)
        await selectRow(failedRow)
        check(await waitUntil(15) { (await readerText()).contains("Your message was not delivered") },
              "opening it shows the card above the message: not delivered")
        let failedCard = await readerText()
        check(failedCard.contains("robin.nobody@example.org") && failedCard.contains("The address does not exist")
              && failedCard.contains("What you can do"),
              "the card names the recipient, why and what to do")
        let preview = views(WKWebView.self, in: main.mailbox.reader.view).first
        _ = try? await preview?.evaluateJavaScript("document.querySelector('details').open = true")
        check(await waitUntil(5) { (await readerText()).contains("550 5.1.1 The email account that you tried to reach does not exist") },
              "the card's Details show the server's own words")
        await shot(main.window, "bounce-1-failed")

        // the link, clicked as the user clicks it: the web view's navigation, which the app takes
        _ = try? await preview?.evaluateJavaScript("document.querySelector('a[href=\"inboxclassic:bounced-message\"]').click()")
        check(await waitUntil(10) { main.mailbox.selectedName == "Sent Items" && main.mailbox.selectedRow?.subject == bouncedSubject },
              "Show the message that bounced selects the message in Sent Items (\(main.mailbox.selectedName): \(main.mailbox.selectedRow?.subject ?? "none"))")

        selectFolder(named: "Inbox")
        guard let delayedRow = await waitFor(20, { listIndex(subject: delayedSubject) }) else {
            throw Failed(description: "the delay notice did not arrive")
        }
        list.scrollRowToVisible(delayedRow)
        await selectRow(delayedRow)
        check(await waitUntil(15) { (await readerText()).contains("Your message has not been delivered yet") },
              "a delay notice shows the amber card")
        check((await readerText()).contains("still trying"), "saying it is still being tried")
        await shot(main.window, "bounce-2-delayed")

        search("is:bounce")
        check(await waitUntil(20) { list.numberOfRows == 2 }, "is:bounce finds the two notices and nothing else (\(list.numberOfRows))")
        let foundSubjects = Set((0..<list.numberOfRows).compactMap { main.mailbox.row($0)?.subject })
        check(foundSubjects == [failedSubject, delayedSubject], "the report and the delay notice")
        if let shownRow = listIndex(subject: failedSubject) {
            await selectRow(shownRow)
        }
        await shot(main.window, "bounce-3-list")
        search("")
        selectFolder(named: "Inbox")
        _ = await waitUntil(20) { list.numberOfRows >= 4 }
    }

    // ---- a message in a window of its own ----

    func messageWindow() async throws {
        step("a message in a window of its own")
        _ = await waitUntil(20) { list.numberOfRows >= 3 }
        // a message with one after it, whose reply is "Re: " and its subject
        guard let index = (0..<(list.numberOfRows - 1)).first(where: { row in
            let subject = main.mailbox.row(row)?.subject ?? ""
            return !subject.isEmpty && !subject.hasPrefix("Re:") && !subject.hasPrefix("Fw:")
        }), let first = main.mailbox.row(index), let after = main.mailbox.row(index + 1) else {
            throw Failed(description: "no message to open")
        }
        await selectRow(index)
        // unread first, so that opening it is what marks it read
        command(.markUnread)
        let pattern = "Subject: \(NSRegularExpression.escapedPattern(for: first.subject))"
        check(await waitUntil(20) { await !seen(pattern) }, "the message is unread on the server before it is opened")
        // Enter on the list, as the keyboard sends it
        let enter = NSEvent.keyEvent(with: .keyDown, location: .zero, modifierFlags: [], timestamp: 0,
                                     windowNumber: main.window.windowNumber, context: nil, characters: "\r",
                                     charactersIgnoringModifiers: "\r", isARepeat: false, keyCode: 36)
        onMain { if let enter { self.list.keyDown(with: enter) } }
        guard let shown = await waitWindow("message", 10), let opened = MessageWindow.open.last else {
            throw Failed(description: "Enter did not open the message in a window")
        }
        check(shown.title == first.subject, "Enter opens it in a window of its own, titled with its subject (\(shown.title))")
        check(shown.subtitle == "Inbox", "with the folder it is in under it (\(shown.subtitle))")
        let header: NSTextField? = find("reader.header", in: shown)
        check(await waitUntil(15) { opened.reader.messageView != nil && header?.stringValue.contains(first.from) == true },
              "the window shows the message with its header")
        check(await waitUntil(20) { await seen(pattern) }, "opening it marks it read on the server")
        opened.press("next")
        check(await waitUntil(10) { shown.title == after.subject }, "Next shows the message after it, and the title follows (\(shown.title))")
        opened.press("previous")
        check(await waitUntil(10) { shown.title == first.subject }, "Previous goes back")
        _ = await waitUntil(15) { opened.reader.messageView != nil && opened.uid == first.uid }
        await pause(1)
        await shot(shown, "read-16-window")
        opened.press("reply")
        guard let compose = await waitCompose() else { throw Failed(description: "Reply in the window opened nothing") }
        check(field("compose.subject", compose)?.stringValue == "Re: \(first.subject)", "Reply in the window opens a reply to that message")
        await closeCompose(compose)
        onMain { shown.performClose(nil) }
        check(await waitUntil(10) { !shown.isVisible && MessageWindow.open.isEmpty }, "the window closes")
        check(main.mailbox.selectedRow?.uid == first.uid, "and the main window is as it was, the message still selected")
    }

    // ---- several messages ----

    func severalMessages() async throws {
        step("several messages")
        selectFolder(named: "Inbox")
        _ = await waitUntil { list.numberOfRows >= 5 }
        let listed = list.numberOfRows
        await selectRow(0)
        // Command+click adds two more
        list.selectRowIndexes(IndexSet([1, 2]), byExtendingSelection: true)
        await pause(1)
        check(main.mailbox.selectedCount == 3, "Command+click adds two more messages: three are selected")
        let subjects = (0..<3).compactMap { main.mailbox.row($0)?.subject }
        let patterns = subjects.map { "Subject: \(NSRegularExpression.escapedPattern(for: $0))" }
        // unread, so the pane has something to count
        command(.markUnread)
        check(await waitUntil(10) {
            let summary = main.mailbox.summary
            return main.mailbox.reader.showsSummary && summary.count == 3 && summary.unread == 3
        }, "the reading pane says 3 messages are selected, and how many of them are unread (\(main.mailbox.summary.unread))")
        let counts: NSTextField? = find("status.counts", in: main.window)
        check(counts?.stringValue.hasSuffix(", 3 selected") == true, "the status bar says 3 selected (\(counts?.stringValue ?? ""))")
        let enabled = { (command: Command) -> Bool in
            let item = NSMenuItem(title: command.label, action: #selector(AppDelegate.runCommand(_:)), keyEquivalent: "")
            item.tag = command.rawValue
            return AppDelegate.shared.validateMenuItem(item)
        }
        check(!enabled(.reply) && !enabled(.print) && enabled(.forward) && enabled(.markRead) && enabled(.move),
              "Reply is off for several, Mark as Read is on")
        await shot(main.window, "select-1-several")
        command(.markRead)
        check(await waitUntil(20) {
            var all = true
            for pattern in patterns where !(await seen(pattern)) { all = false }
            return all
        }, "Mark as Read marks the three read on the server")

        command(.move)
        let move = await waitWindow("move", 10)
        let prompt: NSTextField? = find("move.prompt", in: move)
        check(prompt?.stringValue == "Move the 3 selected messages to:", "Move to Folder asks where the three go")
        if let move {
            choose(folder(ofAccount: 0, named: "Archive"), in: move)
            press(find("move.ok", in: move))
        }
        check(await waitUntil(20) {
            var all = true
            for pattern in patterns where await findMessage("Archive", pattern) == nil { all = false }
            return all
        }, "Move to Folder moves the three to Archive")
        check(await waitUntil(10) { list.numberOfRows == listed - 3 }, "and out of the list")
        let status: NSTextField? = find("status.text", in: main.window)
        check(status?.stringValue == "Moved 3 messages to Archive", "the status bar says they were moved to Archive (\(status?.stringValue ?? ""))")
        check(main.core.undoLabel == "Undo Move", "Edit names Undo Move (\(main.core.undoLabel ?? "nothing"))")
        command(.undo)
        check(await waitUntil(10) { list.numberOfRows == listed }, "Edit > Undo Move brings them back to the Inbox")
        check(await waitUntil(20) {
            var all = true
            for pattern in patterns {
                let inInbox = await findMessage("INBOX", pattern) != nil
                let inArchive = await findMessage("Archive", pattern) != nil
                if !inInbox || inArchive { all = false }
            }
            return all
        }, "and on the server")
        // what came back is selected, in sight
        let restored = { () -> Bool in
            let rows = self.list.selectedRowIndexes
            let visible = self.list.rows(in: self.list.visibleRect)
            return rows.count == 3 && rows.allSatisfy { visible.contains($0) }
                && Set(rows.compactMap { self.main.mailbox.row($0)?.subject }) == Set(subjects)
        }
        check(await waitUntil(20) { restored() }, "the three that came back are selected, in sight")
        await pause(0.5)
        await shot(main.window, "select-2-undo")

        command(.selectAll)
        await pause(0.5)
        check(main.mailbox.selectedCount == list.numberOfRows && list.numberOfRows > 0, "Select All selects every message of the list")
        await selectRow(0)
        let header: NSTextField? = find("reader.header", in: main.window)
        check(!main.mailbox.reader.showsSummary && header?.stringValue.isEmpty == false,
              "one message selected again is shown in the reading pane")
    }

    // ---- messages as files ----

    /// a folder of its own under the test's output, empty
    func emptyFolder(_ name: String) -> URL {
        let dir = out.appendingPathComponent(name)
        try? FileManager.default.removeItem(at: dir)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }

    /// Flag colours as Apple Mail keeps them: \\Flagged with $MailFlagBit0 to $MailFlagBit2
    func flagColors() async throws {
        step("flag colours")
        let status: NSTextField? = find("status.text", in: main.window)
        selectFolder(named: "Inbox")
        let before = list.numberOfRows
        // flagged purple by Apple Mail
        try await addMessage(
            "From: Mira Lind <mira@example.com>\r\nTo: testuser@inboxclassic.test\r\nSubject: Flagged in Apple Mail\r\n"
                + "Message-ID: <purple@example.com>\r\nDate: \(rfc2822(Date()))\r\n\r\nPurple, from the other program.\r\n",
            flags: ["\\Flagged", "$MailFlagBit0", "$MailFlagBit2"])
        command(.sync)
        _ = await waitUntil { list.numberOfRows > before }
        let menu = AppDelegate.shared.flagMenu().submenu
        let colors = menu?.items.filter { $0.action == #selector(AppDelegate.flagColor(_:)) }.map(\.title) ?? []
        check(colors == ["Red", "Orange", "Yellow", "Green", "Blue", "Purple", "Gray"]
              && menu?.items.last?.title == "Clear Flag",
              "Message > Flag has the seven colours of Apple Mail and Clear Flag (\(colors))")
        func index(_ subject: String) -> Int? {
            (0..<list.numberOfRows).first { main.mailbox.row($0)?.subject == subject }
        }
        func choose(_ color: Int) {
            let action = color == 0 ? #selector(AppDelegate.clearFlag(_:)) : #selector(AppDelegate.flagColor(_:))
            guard let item = menu?.items.first(where: { $0.action == action && (color == 0 || $0.tag == color) })
            else { return check(false, "the Flag menu has colour \(color)") }
            check(AppDelegate.shared.validateMenuItem(item), "\(item.title) can be chosen")
            onMain { _ = NSApp.sendAction(action, to: AppDelegate.shared, from: item) }
        }
        func serverFlags(_ subject: String) async -> [String] {
            (await findMessage("INBOX", "Subject: \(NSRegularExpression.escapedPattern(for: subject))")?["flags"] as? [String]) ?? []
        }
        check(await waitUntil(10) { index("Flagged in Apple Mail").flatMap { main.mailbox.row($0)?.flagColor } == 6 },
              "a message flagged purple by another program (Apple Mail) shows a purple flag")

        // orange on one (of those not flagged, so they can be left as they were)
        let subjects = (0..<min(list.numberOfRows, 8)).compactMap { main.mailbox.row($0) }
            .filter { !$0.flagged }.map(\.subject)
        guard subjects.count >= 3 else { return check(false, "three other messages to flag") }
        if let row = index(subjects[0]) { await selectRow(row) }
        let rightClick = main.mailbox.messageMenu()?.items ?? []
        check(rightClick.contains { $0.title == "Flag" && $0.submenu != nil }
              && !rightClick.contains { $0.title == "Flag Message" || $0.title == "Clear Flag" },
              "the right-click menu has the Flag submenu, and Clear Flag only in it")
        choose(2)
        check(await waitUntil(20) { let f = await serverFlags(subjects[0]); return f.contains("\\Flagged") && f.contains("$MailFlagBit0") },
              "Orange flags the message orange: \\Flagged and $MailFlagBit0 on the server")
        check(await waitUntil(10) { index(subjects[0]).flatMap { main.mailbox.row($0)?.flagColor } == 2 },
              "the flag column shows it in orange")
        check(status?.stringValue == "Flagged 1 message orange", "the status bar says so (\(status?.stringValue ?? ""))")

        // blue on two selected
        let two = [subjects[1], subjects[2]].compactMap(index)
        list.selectRowIndexes(IndexSet(two), byExtendingSelection: false)
        await pause(0.5)
        choose(5)
        check(await waitUntil(20) {
            for subject in subjects[1...2] {
                let f = await serverFlags(subject)
                if !(f.contains("\\Flagged") && f.contains("$MailFlagBit2") && !f.contains("$MailFlagBit0")) { return false }
            }
            return true
        }, "Blue on two selected messages flags both blue: $MailFlagBit2")
        check(menu?.items.first { $0.tag == 5 }.map { item in _ = AppDelegate.shared.validateMenuItem(item); return item.state == .on } == true,
              "the Flag menu checks Blue for them")
        // one of the blue ones selected: its flag white on the selection, the others in their colours
        await selectRow(index(subjects[1]) ?? 0)
        await shot(main.window, "flags-1-colors")

        // Clear Flag takes flag and colour away
        if let row = index("Flagged in Apple Mail") { await selectRow(row) }
        choose(0)
        check(await waitUntil(20) {
            let f = await serverFlags("Flagged in Apple Mail")
            return !f.contains("\\Flagged") && !f.contains("$MailFlagBit0") && !f.contains("$MailFlagBit2")
        }, "Clear Flag takes the flag and its colour away on the server")
        // the others back as they were, for the steps after
        list.selectRowIndexes(IndexSet(subjects[0...2].compactMap(index)), byExtendingSelection: false)
        await pause(0.5)
        choose(0)
        _ = await waitUntil(20) { await serverFlags(subjects[0]).contains("\\Flagged") == false }
    }

    func messagesAsFiles() async throws {
        step("messages as files")
        selectFolder(named: "Inbox")
        let before = list.numberOfRows
        // a new one, never opened: downloaded for the files
        try await addMessage(
            "From: Petra Holm <petra@example.com>\r\nTo: testuser@inboxclassic.test\r\nSubject: Ferry times\r\n"
                + "Message-ID: <ferry@example.com>\r\nDate: \(rfc2822(Date()))\r\n\r\nThe ferry leaves at nine.\r\n")
        command(.sync)
        _ = await waitUntil { list.numberOfRows > before }
        await selectRow(0)
        list.selectRowIndexes(IndexSet([0, 1, 2]), byExtendingSelection: false)
        await pause(0.5)
        let picked = (0..<3).compactMap { main.mailbox.row($0) }
        let subjects = picked.map(\.subject)
        let selection = newSelection(picked.map { ($0.folder, $0.uid) })
        check(!pe_selection_all_downloaded(main.core.handle, selection), "one of the three is not downloaded yet")
        pe_selection_free(selection)

        // the drag out: the Finder asks each file promise to be written in the folder it is dropped on
        let dropped = emptyFolder("dragged-out")
        let promises = (0..<3).compactMap { main.mailbox.promise(forRow: $0) }
        check(await writePromises(promises, into: dropped) && promises.count == 3,
              "three messages dragged out become three .eml files where they are dropped")
        let files = ((try? FileManager.default.contentsOfDirectory(atPath: dropped.path)) ?? []).sorted()
        check(Set(files) == Set(subjects.map { "\($0).eml" }), "named after their subjects (\(files.joined(separator: ", ")))")
        var differ: [String] = []
        for subject in subjects {
            let file = (try? Data(contentsOf: dropped.appendingPathComponent("\(subject).eml"))) ?? Data()
            let pattern = "Subject: \(NSRegularExpression.escapedPattern(for: subject))"
            guard let message = await findMessage("INBOX", pattern),
                  let encoded = message["raw"] as? String, let server = Data(base64Encoded: encoded) else {
                differ.append("\(subject): not on the server")
                continue
            }
            if file != server { differ.append("\(subject): \(file.count) bytes, the server's \(server.count)") }
        }
        check(differ.isEmpty, "with what each message is, byte for byte \(differ.joined(separator: "; "))")
        check(main.mailbox.reader.showsSummary, "one not downloaded yet is downloaded for it, the three still selected")
        let status: NSTextField? = find("status.text", in: main.window)
        check(await waitUntil(10) { status?.stringValue == "Saved 3 messages to dragged-out" },
              "the status bar says where they were saved (\(status?.stringValue ?? ""))")
        await shot(main.window, "files-4-drag-out")

        // Save As with three: into a folder, never over a file there
        let saved = emptyFolder("saved-several")
        try "mine".write(to: saved.appendingPathComponent("\(subjects[0]).eml"), atomically: true, encoding: .utf8)
        TestHooks.folder = { saved }
        command(.saveAs)
        check(await waitUntil(30) { status?.stringValue == "Saved 3 messages to saved-several" },
              "Save As with three selected asks for a folder and saves the three there (\(status?.stringValue ?? ""))")
        TestHooks.folder = nil
        let savedFiles = (try? FileManager.default.contentsOfDirectory(atPath: saved.path)) ?? []
        check(savedFiles.count == 4 && savedFiles.contains("\(subjects[0]) (2).eml")
              && (try? String(contentsOf: saved.appendingPathComponent("\(subjects[0]).eml"), encoding: .utf8)) == "mine",
              "never over a file that is there (\(savedFiles.sorted().joined(separator: ", ")))")

        // Forward with three: one new message, the three attached
        command(.forward)
        let compose = await waitCompose()
        let window = ComposeWindow.open.last
        check(await waitUntil(20) { window?.attachedNames.count == 3 },
              "Forward with three selected writes one new message with the three attached as .eml files")
        check(window?.attachedNames.allSatisfy { $0.hasSuffix(".eml") } == true, "as .eml files (\(window?.attachedNames ?? []))")
        let subject: NSTextField? = find("compose.subject", in: compose)
        check(subject?.stringValue == "Fw: \(subjects[0])", "its subject is the first one's, with Fw: (\(subject?.stringValue ?? ""))")
        await pause(0.5)
        await shot(compose, "files-5-forward")
        if let compose { await closeCompose(compose) }

        // .eml files from the Finder onto Archive; a file that is not a message is turned away
        let incoming = emptyFolder("drop-in")
        var urls: [URL] = []
        for (n, name) in ["Harbour plan", "Boat repairs", "Winter berths"].enumerated() {
            let url = incoming.appendingPathComponent("\(name).eml")
            try ("From: Harbour Office <office@example.com>\r\nTo: testuser@inboxclassic.test\r\nSubject: \(name)\r\n"
                + "Message-ID: <drop\(n)@example.com>\r\nDate: \(rfc2822(Date()))\r\n\r\nDropped in.\r\n")
                .write(to: url, atomically: true, encoding: .utf8)
            urls.append(url)
        }
        let note = incoming.appendingPathComponent("notes.txt")
        try "not a message".write(to: note, atomically: true, encoding: .utf8)
        let archive = folder(ofAccount: 0, named: "Archive")
        let drop = urls + [note]
        onMain { [main] in main.mailbox.dropFiles(drop, into: archive) }
        let turnedAway = await waitWindow("alert", 10)
        check(alertText(turnedAway).contains("notes.txt"), "a file that is not a message is turned away")
        answer(turnedAway, "OK")
        check(await waitUntil(30) {
            for name in ["Harbour plan", "Boat repairs", "Winter berths"] where await findMessage("Archive", "Subject: \(name)") == nil {
                return false
            }
            return true
        }, ".eml files dropped onto Archive in the folder tree are put in it, on the server")
        check(await findMessage("Archive", "not a message") == nil, "and the other file is not")
        let put: NSTextField? = find("status.text", in: main.window)
        check(put?.stringValue == "Put 3 messages in Archive", "the status bar says what was put where (\(put?.stringValue ?? ""))")
        selectFolder(named: "Archive")
        _ = await waitUntil(20) { (0..<self.list.numberOfRows).compactMap { self.main.mailbox.row($0)?.subject }.contains("Winter berths") }
        await selectRow(0)
        await pause(0.5)
        await shot(main.window, "files-6-drop-in")
        selectFolder(named: "Inbox")
    }

    // ---- folders ----

    func answerName(_ title: String, _ name: String, shot: String?) async {
        let form = await waitFor { window("form").flatMap { $0.title == title ? $0 : nil } }
        check(form != nil, "\(title) asks for a name")
        guard let form else { return }
        type(name, into: find("form.field.0", in: form))
        if let shot { await self.shot(form, shot) }
        press(find("form.ok", in: form))
        _ = await waitUntil(5) { !form.isVisible }
    }

    func folders() async throws {
        step("folders")
        selectFolder(named: "Archive")
        command(.newFolder)
        await answerName("New Folder", "Projects", shot: "folders-1-new")
        check(await waitUntil(20) { await mailboxes().contains("Archive/Projects") }, "New Folder makes Archive/Projects on the server")
        check(await waitUntil(10) { selectFolder(named: "Projects") }, "and it is in the tree")
        await pause(0.5)
        await shot(main.window, "folders-2-tree")
        command(.renameFolder)
        await answerName("Rename Folder", "Plans", shot: nil)
        check(await waitUntil(20) { let all = await mailboxes(); return all.contains("Archive/Plans") && !all.contains("Archive/Projects") },
              "Rename renames it on the server")
        _ = await waitUntil(10) { selectFolder(named: "Plans") }
        command(.deleteFolder)
        let sure = await waitWindow("alert", 10)
        check(sure != nil, "deleting a folder asks first")
        await shot(sure, "folders-3-delete")
        answer(sure, "Delete")
        check(await waitUntil(20) { await !mailboxes().contains("Archive/Plans") }, "and Delete deletes it on the server")
        // the Inbox is fixed: no Rename for it
        selectFolder(named: "Inbox")
        let menu = AppDelegate.shared.main.mailbox.list.window.map { _ in true } ?? false
        check(menu && !(folderNode("Inbox")?.folder.fixed == false), "the Inbox can not be renamed or deleted")
    }

    func folderNode(_ name: String) -> Mailbox.FolderNode? {
        (0..<tree.numberOfRows).compactMap { tree.item(atRow: $0) as? Mailbox.FolderNode }.first { $0.folder.name == name }
    }

    // ---- closing, links and completion ----

    func writingMore() async throws {
        step("closing a message that was written")
        command(.newMail)
        guard let compose = await waitCompose() else { throw Failed(description: "no compose window") }
        _ = await typeInEditor(compose, "Never mind.")
        onMain { compose.performClose(nil) }
        let ask = await waitWindow("alert", 10)
        check(ask != nil, "closing asks before throwing the text away")
        await shot(ask, "write-6-close")
        answer(ask, Text.macDontSave.text)
        check(await waitUntil { !compose.isVisible }, "Don't Save closes it")
        await pause(1)
        check(await findMessage("Drafts", "Never mind") == nil, "without saving it")

        step("an e-mail link")
        main.openMailto("mailto:gina@example.com?subject=From%20a%20link&body=Hello%20Gina%2C")
        let linked = await waitFor(15) { ComposeWindow.open.last.flatMap { $0.subject.stringValue == "From a link" ? $0.window : nil } }
        check(linked != nil, "a mailto: link opens a new message")
        if let linked {
            check(field("compose.to", linked)?.stringValue == "gina@example.com", "to the link's address")
            await pause(1)
            await shot(linked, "write-18-mailto")
            await closeCompose(linked)
        }

        step("completing an address")
        command(.newMail)
        guard let completing = await waitCompose() else { throw Failed(description: "no compose window") }
        let to = field("compose.to", completing) as? AddressField
        let people = to?.people("ann") ?? []
        check(people.contains { $0.contains("ann@example.com") }, "typing in To finds the people it may be (\(people.joined(separator: ", ")))")
        completing.makeFirstResponder(to)
        if let editor = to?.currentEditor() as? NSTextView {
            editor.insertText("ann", replacementRange: editor.selectedRange())
            onMain { editor.complete(nil) }
            await pause(1)
            await shot(completing, "write-17-complete")
        }
        check(to?.stringValue.hasPrefix("Ann Example <ann@example.com>") == true, "the list takes the first (\(to?.stringValue ?? ""))")
        // Return in the field after the person: a comma and a space for the next one
        completing.makeFirstResponder(to)
        if let editor = to?.currentEditor() as? NSTextView {
            editor.setSelectedRange(NSRange(location: (editor.string as NSString).length, length: 0))
            onMain { editor.doCommand(by: #selector(NSResponder.insertNewline(_:))) }
            await pause(0.5)
        }
        check(to?.stringValue == "Ann Example <ann@example.com>, ", "Return after it leaves a comma for the next (\(to?.stringValue ?? ""))")
        await closeCompose(completing)
    }

    // ---- the signature ----

    func signature() async throws {
        step("a signature")
        command(.accounts)
        guard let accounts = await waitWindow("accounts", 10) else { throw Failed(description: "no Accounts window") }
        press(find("accounts.signature", in: accounts))
        let editor = await waitWindow("signature", 20)
        check(editor != nil, "Signature opens the signature editor of the account")
        if let editor {
            check(editor.title.hasPrefix("Signature - "), "titled with the account (\(editor.title))")
            check(await typeInEditor(editor, "Ann, signed by the UI test"), "the signature editor takes typing")
            await shot(editor, "signature-1-editor")
            press(find("signature.ok", in: editor))
            check(await waitUntil(10) { !editor.isVisible }, "OK saves it and closes the editor")
        }
        await pause(0.3)
        press(find("accounts.close", in: accounts))
        _ = await waitUntil(10) { !accounts.isVisible }
        // a new message starts with it, under the line to write on
        command(.newMail)
        guard let compose = await waitCompose() else { throw Failed(description: "no compose window") }
        type("Fay <fay@example.com>", into: field("compose.to", compose))
        type("Signed in the UI test", into: field("compose.subject", compose))
        check(await typeInEditor(compose, "Hello Fay."), "a new message takes typing above the signature")
        await shot(compose, "signature-2-new")
        send(compose)
        let signed = await waitFor(30) { await findMessage("INBOX", "Subject: Signed in the UI test") }
        let text = signed.map(raw) ?? ""
        check(text.contains("Ann, signed by the UI test"), "the message went with the signature")
        if let hello = text.range(of: "Hello Fay"), let line = text.range(of: "-- "), let name = text.range(of: "Ann, signed by the UI test") {
            check(hello.lowerBound < line.lowerBound && line.lowerBound < name.lowerBound, "after what was written and the \"-- \" line")
        } else {
            check(false, "after what was written and the \"-- \" line")
        }
    }

    // ---- a Gmail address and a wrong password ----

    func accountTrouble() async throws {
        step("a Gmail address")
        command(.newAccount)
        guard let first = await waitWindow("account.start") else { throw Failed(description: "no account form") }
        type("Gmail Test", into: find("account.name", in: first))
        type("inboxclassic.test@gmail.com", into: find("account.email", in: first))
        press(find("account.next", in: first))
        // the built-in Google client is off out of the box: the app password way follows at once
        let hint = await waitWindow("alert", 40)
        check(hint != nil, "without it, Gmail wants an app password, and that is said")
        check(window("account.start") == nil, "with Google turned off, a Gmail address goes to the app password way")
        await shot(hint, "account-5-app-password")
        answer(hint, "No")
        let servers = await waitFor(20) { window("form").flatMap { $0.title == "Add Mail Account" ? $0 : nil } }
        let imap = servers.flatMap { (find("form.field.4", in: $0) as NSTextField?)?.stringValue }
        let smtp = servers.flatMap { (find("form.field.7", in: $0) as NSTextField?)?.stringValue }
        check(imap == "imap.gmail.com" && smtp == "smtp.gmail.com", "its servers were found")
        await shot(servers, "account-6-gmail")
        press(servers.flatMap { find("form.cancel", in: $0) })
        _ = await waitUntil { servers?.isVisible != true }

        step("a wrong password")
        // the second account's mail, on a server of its own, newer than the first account's
        try await seedSecond()
        command(.newAccount)
        guard let start = await waitWindow("account.start") else { throw Failed(description: "no account form") }
        type("Work", into: find("account.name", in: start))
        type("testuser2@inboxclassic.test", into: find("account.email", in: start))
        press(find("account.next", in: start))
        guard let second = await waitFor(40, { window("form").flatMap { $0.title == "Add Mail Account" ? $0 : nil } }) else {
            throw Failed(description: "no server settings form")
        }
        let field = { (index: Int) -> NSTextField? in self.find("form.field.\(index)", in: second) }
        type("testuser2", into: field(2))
        type("not-the-password", into: field(3))
        type("127.0.0.1", into: field(4))
        type(secondPort("imap"), into: field(5))
        (find("form.field.6", in: second) as NSPopUpButton?)?.selectItem(at: 2)
        type("127.0.0.1", into: field(7))
        type(secondPort("smtp"), into: field(8))
        (find("form.field.9", in: second) as NSPopUpButton?)?.selectItem(at: 1)
        press(find("form.ok", in: second))
        if let warning = await waitWindow("alert", 10) {
            answer(warning, "Yes")
        }
        let logon = await waitFor(30) { window("form").flatMap { $0.title == "Logon" ? $0 : nil } }
        check(logon != nil, "a refused password is asked for again")
        let status: NSTextField? = find("status.text", in: main.window)
        check(status?.stringValue.lowercased().contains("authentication") == true, "the status bar says why (\(status?.stringValue ?? ""))")
        await shot(main.window, "trouble-1-password")
        // the right password, and the account syncs
        type("testpass2", into: logon.flatMap { find("form.field.0", in: $0) })
        press(logon.flatMap { find("form.ok", in: $0) })
        _ = await waitUntil { logon?.isVisible != true }
        check(await waitUntil(30) { inbox(ofAccount: 1).map { $0.total >= 2 } ?? false },
              "with the right password typed, the account syncs")
    }

    /// the second account's mail on its own server, for All Inboxes: unread, dated a little ahead so it is the newest in
    /// the list (over what the steps before added), around the first account's message of the step
    func seedSecond() async throws {
        for (from, subject, body, minutes) in [
            ("Priya Shah <priya@work.example>", "Contract renewal for next year",
             "The renewal is ready to sign. Could you look it over before Friday?", 10.0),
            ("Tom Becker <tom@work.example>", "Offsite agenda",
             "Here is the agenda for the offsite. Add anything you want to talk about.", 8.0),
        ] {
            try await addMessage("From: \(from)\r\nTo: testuser2@inboxclassic.test\r\nSubject: \(subject)\r\n"
                + "Date: \(rfc2822(Date(timeIntervalSinceNow: minutes * 60)))\r\n"
                + "Message-ID: <\(subject.replacingOccurrences(of: " ", with: "-"))@work.example>\r\n\r\n\(body)\r\n",
                at: secondRest)
        }
    }

    /// the Inbox of the account at `index` (0 the first)
    func inbox(ofAccount index: Int) -> Folder? {
        let accounts = main.mailbox.core.accounts()
        guard index < accounts.count else { return nil }
        return main.mailbox.core.folderTree(accounts[index].id).folders.first { $0.specialUse == PE_SPECIAL_USE_INBOX }
    }

    // ---- All Inboxes ----

    /// the mail of both accounts' Inboxes in one list, a reply from the account of a message, Mark All Read of both
    func allInboxes() async throws {
        step("All Inboxes")
        // a new message for the first account too, so both have unread mail
        try await addMessage("From: Maria Lopez <maria@example.org>\r\nTo: testuser@inboxclassic.test\r\n"
            + "Subject: Photos from the trip\r\nDate: \(rfc2822(Date(timeIntervalSinceNow: 540)))\r\n"
            + "Message-ID: <trip-photos@example.org>\r\n\r\nThe photos from the trip are in the shared album.\r\n")
        command(.sync)
        _ = await waitUntil(20) { (inbox(ofAccount: 0)?.unread ?? 0) >= 1 }
        guard let first = inbox(ofAccount: 0)?.id, let second = inbox(ofAccount: 1)?.id else {
            check(false, "both accounts have an Inbox")
            return
        }
        check(tree.item(atRow: 0) is Mailbox.AllInboxesNode, "All Inboxes is at the top of the tree, above the accounts")
        tree.selectRowIndexes(IndexSet(integer: 0), byExtendingSelection: false)
        let expected = (inbox(ofAccount: 0)?.total ?? 0) + (inbox(ofAccount: 1)?.total ?? 0)
        // grouped by conversation the rows are fewer: the messages they list are counted
        check(await waitUntil(10) { main.mailbox.total == expected },
              "it lists the mail of both accounts' Inboxes (\(main.mailbox.total) of \(expected))")
        let folders = (0..<min(4, list.numberOfRows)).compactMap { main.mailbox.row($0)?.folder }
        check(folders.contains(first) && folders.contains(second), "newest first, the two accounts' messages among each other")
        let column = list.tableColumn(withIdentifier: NSUserInterfaceItemIdentifier("folder"))
        let cell = column.flatMap { list.column(withIdentifier: $0.identifier) }
            .flatMap { list.view(atColumn: $0, row: folders.firstIndex(of: second) ?? 0, makeIfNecessary: true) as? NSTableCellView }
        check(column?.title == "Account" && cell?.textField?.stringValue == "Work",
              "the Account column names the account of each (\(column?.title ?? ""): \(cell?.textField?.stringValue ?? ""))")
        let counts: NSTextField? = find("status.counts", in: main.window)
        check(counts?.stringValue.hasPrefix("\(expected) messages") == true,
              "the status bar counts both Inboxes (\(counts?.stringValue ?? ""))")
        let menu = main.mailbox.folderMenu().items.filter { !$0.isSeparatorItem }.map(\.title)
        check(menu == [Command.markAllRead.label], "its right-click menu has Mark All Read alone (\(menu))")
        await selectRow(0)
        await shot(main.window, "all-inboxes-1-list")
        if let index = folders.firstIndex(of: second) {
            await selectRow(index)
        }
        command(.reply)
        if let compose = await waitCompose() {
            await pause(1)
            let from: NSPopUpButton? = find("compose.from", in: compose)
            check(from?.titleOfSelectedItem == "Work <testuser2@inboxclassic.test>",
                  "a reply goes from the account of the message (\(from?.titleOfSelectedItem ?? ""))")
            await closeCompose(compose)
        } else {
            check(false, "Reply opens a compose window")
        }
        command(.markAllRead)
        check(await waitUntil(20) {
            let first = await unreadOnServer()
            let other = await unreadOnServer(at: secondRest)
            return first == 0 && other == 0
        },
              "Mark All Read marks both Inboxes read on the servers")
    }

    // ---- moving between accounts ----

    /// the folder of an account (by its place in the tree) the tree names `name`
    func folder(ofAccount index: Int, named name: String) -> Int64 {
        let accounts = main.mailbox.core.accounts()
        guard accounts.indices.contains(index) else { return 0 }
        return main.mailbox.core.folders(accounts[index].id).first { $0.name == name }?.id ?? 0
    }

    /// highlights `folder` in the Move window, as a click on its row would
    func choose(_ folder: Int64, in window: NSWindow) {
        (window.delegate as? MoveWindow)?.highlight(folder, inRecent: false)
    }

    /// the rows of the Move window
    func moveRows(_ window: NSWindow?) -> [MoveWindow.Node] {
        guard let outline: NSOutlineView = find("move.outline", in: window) else { return [] }
        return (0..<outline.numberOfRows).compactMap { outline.item(atRow: $0) as? MoveWindow.Node }
    }

    func findMessage(_ mailbox: String, _ pattern: String, at server: String) async -> [String: Any]? {
        await messages(mailbox, at: server).first { raw($0).range(of: pattern, options: .regularExpression) != nil }
    }

    /// Move to Folder and Copy to Folder with the folders of both accounts, a move to the other account and back with
    /// Undo, a copy, Recent, and a drag onto the other account's folder
    func betweenAccounts() async throws {
        step("moving between accounts")
        let archive = folder(ofAccount: 0, named: "Archive")
        let otherArchive = folder(ofAccount: 1, named: "Archive")
        let inbox = folder(ofAccount: 0, named: "Inbox")
        selectFolder(named: "Inbox")
        _ = await waitUntil { list.numberOfRows >= 3 }
        await selectRow(0)
        guard let message = main.mailbox.row(0) else {
            check(false, "the Inbox has a message to move")
            return
        }
        let subject = NSRegularExpression.escapedPattern(for: message.subject)
        if !message.flagged {
            command(.flag)
            _ = await waitUntil { main.mailbox.row(0)?.flagged == true }
        }

        command(.move)
        let move = await waitWindow("move", 10)
        let rows = moveRows(move)
        check(rows.filter { $0.kind == .account }.count == 2
              && rows.contains { $0.folder == otherArchive } && find("move.filter", in: move) as NSSearchField? != nil,
              "Move to Folder shows the folders of both accounts in a tree, with a filter box")
        let current = rows.first { $0.kind == .folder && $0.folder == inbox }
        check(current?.choosable == false && current?.name == "Inbox (current)",
              "the folder the message is in is shown but can not be chosen (\(current?.name ?? ""))")
        let ok: NSButton? = find("move.ok", in: move)
        check(ok?.title == "Move", "the button says Move (\(ok?.title ?? ""))")
        check(rows.contains { $0.kind == .recent && $0.folder == archive }, "the folder used last is under Recent")
        move?.makeKeyAndOrderFront(nil)
        _ = await waitUntil(2) { move?.isKeyWindow == true }
        await shot(move, "move-1-dialog")
        if let move, let filter: NSSearchField = find("move.filter", in: move) {
            filter.stringValue = "arch"
            (move.delegate as? MoveWindow)?.controlTextDidChange(Notification(name: NSControl.textDidChangeNotification))
            let narrowed = moveRows(move).filter { $0.kind == .folder }
            check(!narrowed.isEmpty && narrowed.allSatisfy { $0.name.localizedCaseInsensitiveContains("arch") },
                  "typing in the filter narrows the tree to the folders that match")
            choose(otherArchive, in: move)
            let listed = list.numberOfRows
            press(find("move.ok", in: move))
            check(await waitUntil(5) { list.numberOfRows == listed - 1 }, "a message moved to the other account's Archive leaves the list at once")
        }
        let status: NSTextField? = find("status.text", in: main.window)
        check(await waitUntil(30) { status?.stringValue == "Moved 1 message to Archive" },
              "the status bar says how the move went (\(status?.stringValue ?? ""))")
        let there = await waitFor(30) { await self.findMessage("Archive", "Subject: \(subject)", at: self.secondRest) }
        check((there?["flags"] as? [String])?.contains("\\Flagged") == true,
              "it is in the second account's Archive on its server, with its flags")
        check(await waitUntil(20) { await findMessage("INBOX", "Subject: \(subject)") == nil },
              "and gone from the first account's server")
        if let node = (0..<tree.numberOfRows).compactMap({ tree.item(atRow: $0) as? Mailbox.FolderNode })
            .first(where: { $0.folder.id == otherArchive }) {
            tree.selectRowIndexes(IndexSet(integer: tree.row(forItem: node)), byExtendingSelection: false)
            _ = await waitUntil(10) { list.numberOfRows >= 1 }
            await selectRow(0)
            _ = await waitUntil(5) { main.mailbox.hasOne }
            await shot(main.window, "move-2-accounts")
        }

        command(.undo)
        let back = await waitUntil(30) { await findMessage("INBOX", "Subject: \(subject)") != nil }
        let left = await waitUntil(20) { await findMessage("Archive", "Subject: \(subject)", at: secondRest) == nil }
        check(back && left, "Edit > Undo Move brings it back to the first account")

        selectFolder(named: "Inbox")
        _ = await waitUntil { list.numberOfRows >= 2 }
        await selectRow(0)
        let copied = NSRegularExpression.escapedPattern(for: main.mailbox.row(0)?.subject ?? "")
        command(.copy)
        let copy = await waitWindow("move", 10)
        let copyButton: NSButton? = find("move.ok", in: copy)
        if let copy {
            choose(otherArchive, in: copy)
            press(copyButton)
        }
        check(copyButton?.title == "Copy" && copy?.title.hasPrefix("Copy") == true, "Copy to Folder says Copy")
        let copiedThere = await waitFor(30) { await self.findMessage("Archive", "Subject: \(copied)", at: self.secondRest) }
        let kept = await findMessage("INBOX", "Subject: \(copied)")
        check(copiedThere != nil && kept != nil,
              "Copy to Folder copies a message to the second account's Archive and keeps it in the Inbox")

        command(.move)
        if let again = await waitWindow("move", 10) {
            check(moveRows(again).contains { $0.kind == .recent && $0.folder == otherArchive },
                  "the next Move to Folder offers Archive of the second account under Recent")
            press(find("move.cancel", in: again))
        }

        // dropped onto a folder of the other account (the drag itself runs outside the app's reach)
        await selectRow(1)
        if let dragged = main.mailbox.row(1) {
            let pattern = NSRegularExpression.escapedPattern(for: dragged.subject)
            let node = (0..<tree.numberOfRows).compactMap { tree.item(atRow: $0) as? Mailbox.FolderNode }
                .first { $0.folder.id == otherArchive }
            check(main.mailbox.dropTarget(node, from: [dragged.folder]) == otherArchive
                  && main.mailbox.drop([(dragged.folder, dragged.uid)], to: otherArchive, copy: false),
                  "a folder of the second account takes a dragged message")
            let moved = await waitFor(30) { await self.findMessage("Archive", "Subject: \(pattern)", at: self.secondRest) }
            let gone = await waitUntil(20) { await findMessage("INBOX", "Subject: \(pattern)") == nil }
            check(moved != nil && gone, "a message dragged onto a folder of the second account is moved there")
        }
    }

    /// the lines the test's agent (scripts/ui-e2e/agent.mjs) wrote, by step
    private func agentSaid(_ file: URL, _ step: String) -> Any? {
        guard let text = try? String(contentsOf: file, encoding: .utf8) else { return nil }
        for line in text.split(separator: "\n") {
            if let entry = try? JSONSerialization.jsonObject(with: Data(line.utf8)) as? [String: Any], entry["step"] as? String == step {
                return entry["result"] ?? NSNull()
            }
        }
        return nil
    }

    /// an AI agent through --mcp: let in, reading and marking messages read as the window shows, sending only after a yes
    func agent() async throws {
        step("an AI agent")
        selectFolder(named: "Inbox")
        // two new messages for the agent to read, whatever the steps before left unread
        let rowsBefore = list.numberOfRows
        for (from, subject, body) in [("Maria Lopez <maria@example.org>", "Quarterly report draft", "Here is the draft of the quarterly report. Comments by Thursday?"),
                                      ("Sam Lee <sam@example.org>", "Team lunch on Friday", "Who is in for lunch on Friday at noon?")] {
            try await addMessage("From: \(from)\r\nTo: testuser@inboxclassic.test\r\nSubject: \(subject)\r\nDate: \(rfc2822(Date()))\r\n"
                + "Message-ID: <\(UUID().uuidString)@example.org>\r\n\r\n\(body)\r\n")
        }
        command(.sync)
        _ = await waitUntil { list.numberOfRows >= rowsBefore + 2 }
        let unreadBefore = await unreadOnServer()
        await pause(1)
        await shot(main.window, "agents-1-before")
        // the agent: Node.js under a name of its own, as an agent host would be, starting the relay (--mcp)
        let agentOut = out.appendingPathComponent("agent.jsonl")
        let host = out.appendingPathComponent("My AI agent")
        let which = Process()
        which.executableURL = URL(fileURLWithPath: "/usr/bin/env")
        which.arguments = ["which", "node"]
        let found = Pipe()
        which.standardOutput = found
        try which.run()
        which.waitUntilExit()
        let node = String(decoding: found.fileHandleForReading.readDataToEndOfFile(), as: UTF8.self).trimmingCharacters(in: .whitespacesAndNewlines)
        try? FileManager.default.removeItem(at: host)
        try FileManager.default.copyItem(at: URL(fileURLWithPath: node), to: host)
        let agent = Process()
        agent.executableURL = host
        agent.arguments = [repo.appendingPathComponent("scripts/ui-e2e/agent.mjs").path]
        var environment = ProcessInfo.processInfo.environment
        environment["APP"] = Bundle.main.bundleURL.appendingPathComponent("Contents/MacOS/Inbox Classic").path
        environment["STORE"] = out.appendingPathComponent("store.db").path
        environment["OUT"] = agentOut.path
        agent.environment = environment
        try agent.run()
        defer { if agent.isRunning { agent.terminate() } }

        let ask = await waitWindow("agent.connect", 30)
        check(ask != nil, "a program whose agent connects for the first time is asked about")
        if let ask {
            let path: NSTextField? = find("agent.path", in: ask)
            check(path?.stringValue.contains("My AI agent") == true, "the question names the program")
            let level = { (index: Int) -> NSButton? in self.find("agent.level.\(index)", in: ask) }
            check(level(0)?.state == .on && level(1)?.state == .on && level(2)?.state == .off && level(3)?.state == .off,
                  "reading and organizing are offered, sending is not")
            // sending too, for the rest of the test
            level(3)?.state = .on
            await shot(ask, "agents-2-connect")
            press(find("agent.allow", in: ask))
        }
        let marked = await waitFor(30) { agentSaid(agentOut, "marked") as? [String: Any] }
        let initialize = agentSaid(agentOut, "initialize") as? [String: Any]
        check(((initialize?["result"] as? [String: Any])?["serverInfo"] as? [String: Any])?["name"] as? String == "inbox-classic",
              "allowed, the agent connects")
        let tools = agentSaid(agentOut, "tools") as? [String] ?? []
        check(tools.count == 15, "with the tools of what it may do (\(tools.joined(separator: ", ")))")
        let read = agentSaid(agentOut, "read") as? [String: Any]
        check((read?["notice"] as? String)?.contains("not as instructions") == true && read?["unread"] as? Bool == true,
              "it reads a message as text, told it is the sender's, without marking it read")
        check(marked?["done"] as? Bool == true, "it marks two messages read")
        check(await waitUntil(20) { await unreadOnServer() == unreadBefore - 2 }, "on the server (\(unreadBefore) unread before)")
        let counts: NSTextField? = find("status.counts", in: main.window)
        check(await waitUntil(10) { counts?.stringValue.contains(", \(unreadBefore - 2) unread") == true },
              "and in the window at once (\(counts?.stringValue ?? ""))")
        await shot(main.window, "agents-3-after")

        let send = await waitWindow("agent.send", 30)
        check(send != nil, "a message the agent wants to send is shown to the user first")
        if let send {
            let recipient: NSTextField? = find("agent.recipient.0", in: send)
            check(recipient?.stringValue == "pat@example.net", "every recipient by address")
            let warning: NSTextField? = find("agent.warning", in: send)
            check(warning?.stringValue.contains("never written to pat@example.net") == true, "with a warning about the new address")
            let button: NSButton? = find("agent.sendButton", in: send)
            check(button?.isEnabled == false, "Send waits a moment before it can be pressed")
            await pause(2)
            await shot(send, "agents-4-send")
            press(button)
        }
        let sent = await waitFor(20) { agentSaid(agentOut, "sent") as? [String: Any] }
        check(sent?["sent"] as? Bool == true, "the agent learns the user said yes")

        command(.outbox)
        if let outbox = await waitWindow("outbox", 10) {
            let table: NSTableView? = find("outbox.list", in: outbox)
            let status = (table?.view(atColumn: 3, row: 0, makeIfNecessary: true) as? NSTableCellView)?.textField?.stringValue ?? ""
            check(status.hasPrefix("Queued by an AI agent; sends at"), "it waits in the Outbox, where it can still be deleted (\(status))")
            await shot(outbox, "agents-5-outbox")
            NSApp.stopModal()
            _ = await waitUntil { !outbox.isVisible }
        }
        command(.aiAgents)
        if let agents = await waitWindow("agents", 10) {
            let hosts: NSTableView? = find("agents.hosts", in: agents)
            let log: NSTableView? = find("agents.log", in: agents)
            let cell = { (table: NSTableView?, column: Int, row: Int) -> String in
                (table?.view(atColumn: column, row: row, makeIfNecessary: true) as? NSTableCellView)?.textField?.stringValue ?? ""
            }
            check(cell(hosts, 0, 0) == "My AI agent" && cell(hosts, 1, 0).hasPrefix("Read, organize and send with your yes"),
                  "it lists the program and what it may do (\(cell(hosts, 1, 0)))")
            check(cell(log, 2, 0).hasPrefix("Sent \"Lunch on Friday?\" to pat@example.net") && cell(log, 2, 1).hasPrefix("Marked read"),
                  "and what its agent did, newest first")
            await shot(agents, "agents-6-window")
            press(find("agents.undo", in: agents))
            check(await waitUntil(10) { cell(log, 2, 0).contains("taken back") }, "Undo takes the message back")
            NSApp.stopModal()
            _ = await waitUntil { !agents.isVisible }
        } else {
            check(false, "Tools > AI Agents opens")
        }
        command(.outbox)
        if let outbox = await waitWindow("outbox", 10) {
            let table: NSTableView? = find("outbox.list", in: outbox)
            check(table?.numberOfRows == 0, "and the Outbox is empty")
            NSApp.stopModal()
            _ = await waitUntil { !outbox.isVisible }
        }
    }

    // ---- the Address Book ----

    /// the people the Address Book lists, by name
    func bookNames(_ book: AddressBookWindow) -> [String] {
        book.rows.map(\.title)
    }

    func addressBook() async throws {
        step("the Address Book")
        command(.addressBook)
        guard let bookWindow = await waitWindow("addressbook", 10), let book = AddressBookWindow.shown else {
            throw Failed(description: "no Address Book")
        }
        await pause(0.5)
        let groupsWidth = book.groupList.enclosingScrollView?.frame.width ?? 0
        check(groupsWidth > 150 && groupsWidth < 260, "the groups take a narrow column at the left (\(groupsWidth) of \(bookWindow.frame.width))")
        let bookToolbar = bookWindow.toolbar?.items.map(\.itemIdentifier.rawValue) ?? []
        check(book.rows.isEmpty && (find("book.empty", in: bookWindow) as NSTextField?)?.isHidden == false,
              "Tools > Address Book opens the Address Book, empty")
        check(["book.newContact", "book.newGroup", "book.properties", "book.delete", "book.writeTo", "book.search"]
            .allSatisfy(bookToolbar.contains), "with New Contact, New Group, Properties, Delete, Write To and the find box")
        check(Command.addressBook.key?.0 == "b" && Command.addressBook.key?.1 == [.command, .shift], "Shift-Command-B opens it")

        // a contact with two addresses
        onMain { book.newContact() }
        guard let person = await waitWindow("contact", 10) else { throw Failed(description: "no Contact Properties") }
        check(person.title == "New Contact", "New Contact opens Contact Properties (\(person.title))")
        type("Mary", into: find("contact.first", in: person))
        type("Smith", into: find("contact.last", in: person))
        check((find("contact.display", in: person) as NSTextField?)?.stringValue == "Mary Smith", "the name shown follows the first and last name")
        type("mary@example.com", into: find("contact.address", in: person))
        press(find("contact.add", in: person))
        await pause(0.3)
        type("mary.smith@work.example", into: find("contact.address", in: person))
        press(find("contact.add", in: person))
        await pause(0.3)
        type("+1 555 0100", into: find("contact.phone", in: person))
        press(find("contact.phone.add", in: person))
        await pause(0.3)
        let personAddresses: NSTableView? = find("contact.addresses", in: person)
        check(personAddresses?.numberOfRows == 2, "with two addresses, mary@example.com the default")
        await shot(person, "contacts-2-person")
        press(find("contact.ok", in: person))
        check(await waitUntil(10) { !person.isVisible }, "OK saves the contact")
        check(book.rows.count == 1 && book.rows.first?.title == "Mary Smith" && book.rows.first?.address == "mary@example.com"
              && book.rows.first?.phone == "+1 555 0100", "and the book lists it: Mary Smith, mary@example.com")
        let mary = book.rows.first?.card ?? 0
        check(core().bookCard(mary)?.addresses == ["mary@example.com", "mary.smith@work.example"], "both addresses kept, the first the default")
        book.find("smi")
        check(bookNames(book) == ["Mary Smith"], "the find box finds her by \"smi\"")
        book.find("zed")
        check(book.rows.isEmpty && (find("book.empty", in: bookWindow) as NSTextField?)?.stringValue.contains("zed") == true,
              "and lists no one for \"zed\"")
        book.find("")

        // a group of her and a typed address
        onMain { book.newGroup() }
        guard let groupSheet = await waitWindow("group", 10) else { throw Failed(description: "no Group Properties") }
        check(groupSheet.title == "New Group", "New Group opens Group Properties")
        type("Team", into: find("group.name", in: groupSheet))
        press(find("group.select", in: groupSheet))
        guard let members = await waitWindow("pick", 10) else { throw Failed(description: "no Select Group Members") }
        check(members.title == "Select Group Members", "Select Members opens the book's people")
        let memberSource: NSTableView? = find("pick.list", in: members)
        memberSource?.selectRowIndexes(IndexSet(integer: 0), byExtendingSelection: false)
        press(find("pick.add", in: members))
        await pause(0.3)
        press(find("pick.ok", in: members))
        _ = await waitUntil(10) { !members.isVisible }
        type("dave@example.com", into: find("group.address", in: groupSheet))
        press(find("group.add", in: groupSheet))
        await pause(0.3)
        let groupMembers: NSTableView? = find("group.members", in: groupSheet)
        check(groupMembers?.numberOfRows == 2, "with Mary Smith from Select Members and dave@example.com typed")
        await shot(groupSheet, "contacts-3-group")
        press(find("group.ok", in: groupSheet))
        check(await waitUntil(10) { !groupSheet.isVisible }, "OK saves the group")
        check(book.groups.count == 1 && book.groups.first?.name == "Team" && book.groups.first?.count == 2,
              "and it is listed on the left with its two members")
        check(book.selectedGroup?.name == "Team" && Set(bookNames(book)) == ["Mary Smith", "dave@example.com"],
              "selected, it lists its members")
        onMain { book.groupList.selectRowIndexes(IndexSet(integer: 0), byExtendingSelection: false) }
        await pause(0.3)
        book.people.selectRowIndexes(IndexSet(integer: 0), byExtendingSelection: false)
        bookWindow.makeFirstResponder(book.people)
        await shot(bookWindow, "contacts-1-book")

        // Select Recipients in a new message
        command(.newMail)
        guard let picking = await waitCompose() else { throw Failed(description: "no compose window") }
        let pickTo: NSButton? = find("compose.pick.to", in: picking)
        check(pickTo != nil, "the To label of a message is a button")
        press(pickTo)
        guard let picker = await waitWindow("pick", 10) else { throw Failed(description: "no Select Recipients") }
        check(picker.title == "Select Recipients", "To opens Select Recipients")
        let pickSource: NSTableView? = find("pick.list", in: picker)
        let pickerNames = (0..<(pickSource?.numberOfRows ?? 0)).compactMap {
            ((pickSource?.view(atColumn: 0, row: $0, makeIfNecessary: true) as? NSTableCellView)?.textField?.stringValue)
        }
        check(pickerNames == ["Team", "Mary Smith"], "it lists the group and the contact (\(pickerNames))")
        pickSource?.selectRowIndexes(IndexSet([0, 1]), byExtendingSelection: false)
        press(find("pick.to", in: picker))
        await pause(0.3)
        let pickedTo: NSTableView? = find("pick.chosen.to", in: picker)
        check(pickedTo?.numberOfRows == 2, "To -> puts them in the message's recipients")
        await shot(picker, "contacts-4-pick")
        press(find("pick.ok", in: picker))
        _ = await waitUntil(10) { !picker.isVisible }
        let pickedField = field("compose.to", picking)?.stringValue ?? ""
        check(pickedField == "Mary Smith <mary@example.com>, dave@example.com",
              "OK puts them in To, each address once (\(pickedField))")
        // a group completes by its name
        let ccField = field("compose.cc", picking) as? AddressField
        let offered = ccField?.people("tea") ?? []
        check(offered.first?.hasSuffix("Team") == true, "typing \"tea\" offers the group by its name (\(offered))")
        press(find("compose.show-cc", in: picking))
        await pause(0.3)
        if let editor = ccField?.currentEditor() as? NSTextView {
            editor.insertText("tea", replacementRange: editor.selectedRange())
            onMain { editor.complete(nil) }
            await pause(1)
        }
        let ccText = ccField?.stringValue ?? ""
        check(ccText.hasPrefix("Mary Smith <mary@example.com>, dave@example.com"), "taking it puts its members in Cc (\(ccText))")
        await closeWithoutSaving(picking)

        // Add Sender to Address Book
        bookWindow.orderOut(nil)
        main.window.makeKeyAndOrderFront(nil)
        selectFolder(named: "Inbox")
        _ = await waitUntil { list.numberOfRows > 0 }
        let senderRow = (0..<list.numberOfRows).first { main.mailbox.row($0)?.subject == "October newsletter" }
            ?? (0..<list.numberOfRows).first { !(main.mailbox.row($0)?.fromAddress ?? "").isEmpty } ?? 0
        await selectRow(senderRow)
        let sender = main.mailbox.row(senderRow)
        let senderName = sender?.from ?? ""
        let senderAddress = sender?.fromAddress ?? ""
        let rightClick = main.mailbox.messageMenu()?.items.map(\.title) ?? []
        check(rightClick.contains("Add Sender to Address Book"), "the message list's right-click menu has Add Sender to Address Book")
        command(.addSenderToBook)
        let statusLabel: NSTextField? = find("status.text", in: main.window)
        check(await waitUntil(5) { statusLabel?.stringValue.hasSuffix("was added to the Address Book.") == true },
              "Add Sender adds \(senderName) (\(statusLabel?.stringValue ?? ""))")
        check(core().bookCards().contains { $0.address == senderAddress }, "with the address \(senderAddress)")
        command(.addSenderToBook)
        check(await waitUntil(5) { statusLabel?.stringValue.hasSuffix("is already in the Address Book.") == true },
              "and again says the sender is in the Address Book already (\(statusLabel?.stringValue ?? ""))")
        check(core().bookCards().filter { $0.address == senderAddress }.count == 1, "without a second card")

        // import and export
        let vcf = out.appendingPathComponent("contacts.vcf")
        try "BEGIN:VCARD\r\nVERSION:3.0\r\nFN:Mary Smith\r\nN:Smith;Mary;;;\r\nEMAIL:mary@example.com\r\nEND:VCARD\r\n"
            .appending("BEGIN:VCARD\r\nVERSION:3.0\r\nFN:John Doe\r\nN:Doe;John;;;\r\nEMAIL:john@example.org\r\nEND:VCARD\r\n")
            .write(to: vcf, atomically: true, encoding: .utf8)
        TestHooks.open = { _ in [vcf] }
        command(.importAddressBook)
        let imported = await waitWindow("alert", 10)
        let importedText = alertText(imported)
        check(importedText.contains("Added 1 contact, skipped 1 already in the Address Book."),
              "File > Import Address Book adds 1 and skips 1 (\(importedText))")
        answer(imported, "OK")
        TestHooks.open = nil
        _ = await waitUntil(5) { window("alert") == nil }
        command(.addressBook)
        _ = await waitUntil(5) { bookWindow.isVisible }
        onMain { book.groupList.selectRowIndexes(IndexSet(integer: 0), byExtendingSelection: false) }
        await pause(0.5)
        let afterImport = bookNames(book)
        check(afterImport.contains("John Doe") && afterImport.contains("Mary Smith") && afterImport.contains(senderName),
              "and the book lists John Doe beside Mary Smith and \(senderName) (\(afterImport))")
        if let john = book.rows.firstIndex(where: { $0.title == "John Doe" }) {
            book.people.selectRowIndexes(IndexSet(integer: john), byExtendingSelection: false)
        }
        await shot(bookWindow, "contacts-5-import")
        let exported = out.appendingPathComponent("exported.vcf")
        try? FileManager.default.removeItem(at: exported)
        var exportName: String?
        TestHooks.save = { name in
            exportName = name
            return exported
        }
        command(.exportAddressBook)
        let exportSaid = await waitWindow("alert", 10)
        let exportText = alertText(exportSaid)
        check(exportName == "Address Book.vcf" && exportText.contains("3 contacts saved to exported.vcf"),
              "File > Export Address Book writes a vCard file (\(exportText))")
        answer(exportSaid, "OK")
        TestHooks.save = nil
        let card = (try? String(contentsOf: exported, encoding: .utf8)) ?? ""
        check(card.contains("Mary Smith") && card.contains("John Doe") && card.contains(senderAddress),
              "with Mary Smith, John Doe and \(senderName) in it")
        _ = await waitUntil(5) { window("alert") == nil }

        // Delete asks first
        bookWindow.makeKeyAndOrderFront(nil)
        if let john = book.rows.firstIndex(where: { $0.title == "John Doe" }) {
            book.people.selectRowIndexes(IndexSet(integer: john), byExtendingSelection: false)
        }
        bookWindow.makeFirstResponder(book.people)
        onMain { book.deleteSelected() }
        let sure = await waitWindow("alert", 10)
        check(alertText(sure).contains("Delete this contact from the Address Book?"), "Delete asks first")
        answer(sure, "Delete")
        check(await waitUntil(5) { !bookNames(book).contains("John Doe") && bookNames(book).contains("Mary Smith") },
              "then removes the selected contact")
        onMain { bookWindow.performClose(nil) }
        _ = await waitUntil(5) { !bookWindow.isVisible }
    }

    func core() -> Core { main.core }
}
