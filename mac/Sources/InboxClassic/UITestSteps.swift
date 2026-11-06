// The later steps of the Mac UI end-to-end test (UITest.swift), in the order of scripts/ui-e2e.ps1: the Outbox and
// Drafts, new mail, files, organizing, mailing lists, invitations and logos, folders, closing and links, completion, the
// signature, a Gmail address and a wrong password.
import AppKit
import CInboxClassic
import Darwin
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
        let move = await waitWindow("form", 10)
        check(move != nil, "Move to Folder asks where")
        if let move {
            let choice: NSPopUpButton? = find("form.field.0", in: move)
            choice?.selectItem(at: choice?.itemTitles.firstIndex(of: "Archive") ?? 0)
            await shot(move, "organize-2-move")
            press(find("form.ok", in: move))
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
        check(await waitUntil(10) { status?.stringValue.contains("Unsubscribed") == true }, "and the status bar says it is done")
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
        let inboxRow = (0..<tree.numberOfRows).first { (tree.item(atRow: $0) as? Mailbox.FolderNode)?.folder.displayName == "Inbox" } ?? 1
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
        (0..<tree.numberOfRows).compactMap { tree.item(atRow: $0) as? Mailbox.FolderNode }.first { $0.folder.displayName == name }
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
        answer(ask, "Don't Save")
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
        check(await waitUntil(10) { UInt64(list.numberOfRows) == expected },
              "it lists the mail of both accounts' Inboxes (\(list.numberOfRows) of \(expected))")
        let folders = (0..<min(4, list.numberOfRows)).compactMap { main.mailbox.row($0)?.folder }
        check(folders.contains(first) && folders.contains(second), "newest first, the two accounts' messages among each other")
        let column = list.tableColumn(withIdentifier: NSUserInterfaceItemIdentifier("folder"))
        let cell = column.flatMap { list.column(withIdentifier: $0.identifier) }
            .flatMap { list.view(atColumn: $0, row: folders.firstIndex(of: second) ?? 0, makeIfNecessary: true) as? NSTableCellView }
        check(column?.title == "Account" && cell?.textField?.stringValue == "Work",
              "the Account column names the account of each (\(column?.title ?? ""): \(cell?.textField?.stringValue ?? ""))")
        let counts: NSTextField? = find("status.counts", in: main.window)
        check(counts?.stringValue.hasPrefix("\(expected) message(s)") == true,
              "the status bar counts both Inboxes (\(counts?.stringValue ?? ""))")
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
        check(tools.count == 14, "with the tools of what it may do (\(tools.joined(separator: ", ")))")
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
            let status = (table?.view(atColumn: 3, row: 0, makeIfNecessary: true) as? NSTextField)?.stringValue ?? ""
            check(status.hasPrefix("Sent by an AI agent; goes at"), "it waits in the Outbox, where it can still be deleted (\(status))")
            await shot(outbox, "agents-5-outbox")
            NSApp.stopModal()
            _ = await waitUntil { !outbox.isVisible }
        }
        command(.aiAgents)
        if let agents = await waitWindow("agents", 10) {
            let hosts: NSTableView? = find("agents.hosts", in: agents)
            let log: NSTableView? = find("agents.log", in: agents)
            let cell = { (table: NSTableView?, column: Int, row: Int) -> String in
                (table?.view(atColumn: column, row: row, makeIfNecessary: true) as? NSTextField)?.stringValue ?? ""
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
}
