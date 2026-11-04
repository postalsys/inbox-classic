// The later steps of the Mac UI end-to-end test (UITest.swift), in the order of scripts/ui-e2e.ps1: the Outbox and
// Drafts, new mail, files, organizing, mailing lists, invitations and logos, folders, closing and links, completion, the
// signature, a Gmail address and a wrong password.
import AppKit
import CInboxClassic
import Darwin

extension UITest {
    // ---- the Outbox and Drafts ----

    /// the outgoing server's port, changed in Accounts > Properties (to one nothing listens on, and back)
    func setSmtpPort(_ port: String) async throws {
        command(.accounts)
        guard let accounts = await waitWindow("accounts", 10) else { throw Failed(description: "no Accounts window") }
        press(find("accounts.properties", in: accounts))
        guard let form = await waitFor(10, { window("form").flatMap { $0.title == "Properties" ? $0 : nil } }) else {
            throw Failed(description: "no Properties form")
        }
        type(port, into: find("form.field.8", in: form))
        press(find("form.ok", in: form))
        // a question about a connection without encryption: Yes
        if let ask = await waitWindow("alert", 5) {
            answer(ask, "Yes")
        }
        _ = await waitUntil(10) { !form.isVisible }
        press(find("accounts.close", in: accounts))
        _ = await waitUntil(10) { !accounts.isVisible }
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
        try await addMessage("From: Ann Example <ann@example.com>\r\nTo: testuser@postalexpress.test\r\nSubject: One more thing\r\n"
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

    /// a one-shot HTTP server on this Mac: the request it got, once one came
    final class ListServer: @unchecked Sendable {
        let port: UInt16
        private let socket: Int32
        private(set) var request = ""
        private let lock = NSLock()

        init?() {
            let fd = Darwin.socket(AF_INET, SOCK_STREAM, 0)
            var address = sockaddr_in()
            address.sin_family = sa_family_t(AF_INET)
            address.sin_addr.s_addr = inet_addr("127.0.0.1")
            address.sin_port = 0
            var length = socklen_t(MemoryLayout<sockaddr_in>.size)
            let bound = withUnsafePointer(to: &address) {
                $0.withMemoryRebound(to: sockaddr.self, capacity: 1) { bind(fd, $0, length) }
            }
            guard bound == 0, listen(fd, 1) == 0 else {
                close(fd)
                return nil
            }
            withUnsafeMutablePointer(to: &address) {
                $0.withMemoryRebound(to: sockaddr.self, capacity: 1) { _ = getsockname(fd, $0, &length) }
            }
            socket = fd
            port = UInt16(bigEndian: address.sin_port)
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
        try await addMessage("Authentication-Results: mx.postalexpress.test; dkim=pass header.d=list.example.com\r\n"
            + "DKIM-Signature: v=1; d=list.example.com; s=s1; h=from:subject:list-unsubscribe:list-unsubscribe-post; bh=x; b=y\r\n"
            + "From: Weekly List <news@list.example.com>\r\nTo: testuser@postalexpress.test\r\nSubject: Weekly list news\r\n"
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
        try await addMessage("From: Ann Example <ann@example.com>\r\nTo: testuser@postalexpress.test\r\nSubject: Invitation: Quarterly planning\r\n"
            + "Date: \(rfc2822(Date()))\r\nMessage-ID: <planning-invite@example.com>\r\n"
            + "Content-Type: multipart/mixed; boundary=inv\r\n\r\n--inv\r\nContent-Type: text/plain\r\n\r\nLet us plan the quarter.\r\n"
            + "--inv\r\nContent-Type: text/calendar; method=REQUEST; charset=utf-8\r\n\r\n"
            + "BEGIN:VCALENDAR\r\nMETHOD:REQUEST\r\nBEGIN:VEVENT\r\nUID:planning@example.com\r\nSUMMARY:Quarterly planning\r\n"
            + "DTSTART:20261201T100000Z\r\nDTEND:20261201T113000Z\r\nLOCATION:Room 2\r\nORGANIZER;CN=Ann Example:mailto:ann@example.com\r\n"
            + "ATTENDEE;CN=Test:mailto:testuser@postalexpress.test\r\nRRULE:FREQ=WEEKLY;BYDAY=TU;COUNT=4\r\nEND:VEVENT\r\nEND:VCALENDAR\r\n--inv--\r\n")
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
        try await addMessage("Authentication-Results: mx.postalexpress.test; dmarc=pass header.from=brand.example; bimi=pass header.d=brand.example\r\n"
            + "BIMI-Indicator: \(Data(svg.utf8).base64EncodedString())\r\nFrom: Brand <hello@brand.example>\r\nTo: testuser@postalexpress.test\r\n"
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

        step("marking all read")
        selectFolder(named: "Inbox")
        _ = await waitUntil { list.numberOfRows >= 5 }
        let unreadOnServer = { await self.messages("INBOX").filter { !(($0["flags"] as? [String]) ?? []).contains("\\Seen") }.count }
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
        type("postalexpress.test@gmail.com", into: find("account.email", in: first))
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
        command(.newAccount)
        guard let start = await waitWindow("account.start") else { throw Failed(description: "no account form") }
        type("Wrong Password", into: find("account.name", in: start))
        type("testuser2@postalexpress.test", into: find("account.email", in: start))
        press(find("account.next", in: start))
        guard let second = await waitFor(40, { window("form").flatMap { $0.title == "Add Mail Account" ? $0 : nil } }) else {
            throw Failed(description: "no server settings form")
        }
        let field = { (index: Int) -> NSTextField? in self.find("form.field.\(index)", in: second) }
        type("testuser2", into: field(2))
        type("not-the-password", into: field(3))
        type("127.0.0.1", into: field(4))
        type(port("imap"), into: field(5))
        (find("form.field.6", in: second) as NSPopUpButton?)?.selectItem(at: 2)
        type("127.0.0.1", into: field(7))
        type(port("smtp"), into: field(8))
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
        press(logon.flatMap { find("form.cancel", in: $0) })
        _ = await waitUntil { logon?.isVisible != true }
    }
}
