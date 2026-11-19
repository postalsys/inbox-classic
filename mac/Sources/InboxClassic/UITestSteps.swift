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
        try await setPort(field: 9, port)
    }

    /// a port of the account's servers (the field of the Properties form: 6 IMAP, 9 SMTP), changed there
    func setPort(field index: Int, _ port: String) async throws {
        command(.accounts)
        guard let accounts = await waitWindow("accounts", 10) else { throw Failed(description: "no Accounts window") }
        press(find("accounts.properties", in: accounts))
        guard let form = await waitFor(10, { window("form").flatMap { $0.title == Text.uiProperties.text ? $0 : nil } }) else {
            throw Failed(description: "no Properties form")
        }
        type(port, into: find("form.field.\(index)", in: form))
        press(find("form.ok", in: form))
        // a question about a connection without encryption: Yes
        if let ask = await waitWindow("alert", 5) {
            answer(ask, Text.uiYes.text)
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
        try await setPort(field: 6, "\(silent.port)")
        await search("subject:\"Waiting on the server\"")
        _ = await waitUntil(20) { list.numberOfRows == 1 }
        await selectRow(0)
        let header: NSTextField? = find("reader.header", in: main.window)
        check(header?.stringValue.contains("Waiting on the server") == true && header?.stringValue.contains("Hal Example") == true,
              "the header shows the message's sender and subject at once (\(header?.stringValue ?? ""))")
        check(await waitUntil(10) { await readerText().contains(Text.readerDownloading.text) }, "the pane says the message is being downloaded")
        check(await readerText().contains("The message is"), "and how large it is")
        await shot(main.window, "read-13-downloading")
        // the server gone: why, and Try Again
        silent.stop()
        let retry: InfoBar? = find("reader.retry", in: main.window)
        check(await waitUntil(20) { retry?.isHidden == false }, "a message that can not be downloaded has Try Again")
        check(await waitUntil(5) { await readerText().contains(Text.readerFailed.text) }, "and the pane says why")
        await shot(main.window, "read-12-not-downloaded")
        // the server back: the account syncs, and the message is tried again by itself
        try await setPort(field: 6, port("imap"))
        check(await waitUntil(30) { await readerText().contains("Here at last") }, "once the account is back the message shows by itself")
        check(retry?.isHidden == true, "and Try Again goes")
        await search("")
        selectFolder(named: "Inbox")
    }

    /// a large message shows its text first, its attachment after, and the status bar says how far it is (SCENARIO 17a)
    func largeMessage() async throws {
        step("a large message shows its text first")
        // the whole message comes slowly: in pieces of 256 KB, 300 ms apart
        var rule = URLRequest(url: URL(string: rest.replacingOccurrences(of: "/mailboxes", with: "/script/rules"))!)
        rule.httpMethod = "POST"
        rule.setValue("application/json", forHTTPHeaderField: "Content-Type")
        rule.httpBody = try JSONSerialization.data(withJSONObject: [
            "on": "response", "command": "UID FETCH", "untagged": true, "match": "BODY\\[\\] ",
            "chunk": 262144, "chunkDelay": 300,
        ])
        _ = try await URLSession.shared.data(for: rule)
        let line = String(repeating: "A", count: 76)
        let pdf = Array(repeating: line, count: 3 * 1024 * 1024 / 57).joined(separator: "\r\n")
        try await addMessage("From: Ann Example <ann@example.com>\r\nTo: testuser@inboxclassic.test\r\nSubject: The quarterly report\r\n"
            + "Date: \(rfc2822(Date()))\r\nMessage-ID: <quarterly@example.com>\r\nMIME-Version: 1.0\r\n"
            + "Content-Type: multipart/mixed; boundary=\"q\"\r\n\r\n"
            + "--q\r\nContent-Type: text/plain; charset=utf-8\r\n\r\nThe figures are attached.\r\n"
            + "--q\r\nContent-Type: application/pdf; name=\"report.pdf\"\r\n"
            + "Content-Disposition: attachment; filename=\"report.pdf\"\r\nContent-Transfer-Encoding: base64\r\n\r\n"
            + pdf + "\r\n--q--\r\n", to: "Archive")
        command(.sync)
        // in Archive: the steps after read the Inbox from the server whole, sources and all
        selectFolder(named: "Archive")
        _ = await waitFor(20) { await findMessage("Archive", "Subject: The quarterly report") }
        await pause(1)
        await search("subject:\"The quarterly report\"")
        _ = await waitUntil(20) { list.numberOfRows == 1 }
        await selectRow(0)
        check(await waitUntil(15) { await readerText().contains("The figures are attached") },
              "a large message shows its text before the rest of it is here")
        let said: NSTextField? = find("status.text", in: main.window)
        check(await waitUntil(10) { said?.stringValue.hasPrefix("Downloading") == true },
              "the status bar says how far the rest is (\(said?.stringValue ?? ""))")
        check(await readerText().contains("Downloading"), "its PDF file is a tile that says it is on its way")
        await shot(main.window, "large-1-text-first")
        check(await waitUntil(30) { said?.stringValue.hasPrefix("Downloaded") == true },
              "then that it is all here (\(said?.stringValue ?? ""))")
        check(await waitUntil(15) {
            let text = await readerText()
            return text.contains("The figures are attached") && !text.contains("Downloading")
        }, "and the message is made again: the tile no longer says it is on its way")
        await search("")
        selectFolder(named: "Inbox")
    }

    /// a new message downloaded ahead opens from the store, no connection used (SCENARIO 49b). Near the end: everything
    /// recent is downloaded from now on, which the steps before do not expect.
    func openedFromStore() async throws {
        step("a message downloaded ahead opens at once")
        onMain { self.main.core.downloadAhead = PE_DOWNLOAD_AHEAD_RECENT }
        try await addMessage("From: Kim Example <kim@example.com>\r\nTo: testuser@inboxclassic.test\r\nSubject: Here before you\r\n"
            + "Date: \(rfc2822(Date()))\r\nMessage-ID: <here-before@example.com>\r\n\r\nDownloaded before it was opened.\r\n",
            to: "Archive")
        command(.sync)
        selectFolder(named: "Archive")
        _ = await waitFor(20) { await findMessage("Archive", "Subject: Here before you") }
        // time for the background to download it: nothing on the screen says when
        await pause(10)
        await search("subject:\"Here before you\"")
        _ = await waitUntil(20) { list.numberOfRows == 1 }
        await selectRow(0)
        check(await waitUntil(10) { await readerText().contains("Downloaded before it was opened") }
                  && pe_last_open_from_store(main.core.handle),
              "a new message downloaded ahead opens from the store, without a download")
        await shot(main.window, "open-1-from-store")
        onMain { self.main.core.downloadAhead = PE_DOWNLOAD_AHEAD_NEVER }
        await search("")
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
        check(compose.title == "Draft from the UI test", "a new message's window is named by the subject typed")
        _ = await typeInEditor(compose, "Half written.")
        // closing what was written asks whether to keep it; Save saves it in Drafts
        onMain { compose.performClose(nil) }
        let ask = await waitWindow("alert", 10)
        check(ask != nil, "closing a written message asks to save it")
        await shot(ask, "write-8-save-draft")
        answer(ask, Text.uiTbSave.text)
        check(await waitUntil { !compose.isVisible }, "Save saves it and closes the window")
        let saved = await waitFor(30) { await findMessage("Drafts", "Subject: Draft from the UI test") }
        check(saved != nil, "the draft is in Drafts on the server")
        check((saved?["flags"] as? [String])?.contains("\\Draft") == true, "marked as a draft")
        selectFolder(named: "Drafts")
        check(await waitUntil { !main.mailbox.listLoading && list.numberOfRows >= 1 }, "Drafts lists it")
        await selectRow(0)
        main.mailbox.openSelected()
        guard let reopened = await waitFor(20, { ComposeWindow.open.last.flatMap { $0.window.title == "Draft from the UI test" ? $0.window : nil } })
        else { throw Failed(description: "the draft did not open") }
        compose = reopened
        check(field("compose.to", compose)?.stringValue.contains("fay@example.com") == true, "opening the draft has its recipient")
        _ = await typeInEditor(compose, " Now finished.", atEnd: true)
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
        check(await waitUntil(30) { composeStatus?.stringValue.hasPrefix(lead(.uiComposeSavedAt)) == true }, "the window says when the draft is saved")
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

    func draftsSavedAutomatically() async throws {
        step("drafts saved automatically")
        command(.newMail)
        guard var compose = await waitCompose() else { throw Failed(description: "no compose window") }
        type("Gus <gus@example.com>", into: field("compose.to", compose))
        type("Saved by itself in the UI test", into: field("compose.subject", compose))
        _ = await typeInEditor(compose, "Not saved by hand.")
        let status: NSTextField? = find("compose.status", in: compose)
        check(await waitUntil(30) { status?.stringValue.hasPrefix(lead(.uiComposeSavedAt)) == true },
              "a message being written is saved in Drafts once typing stops")
        let saved = await waitFor(30) { await findMessage("Drafts", "Subject: Saved by itself") }
        check(saved.map { raw($0).contains("Not saved by hand") } == true, "the draft is in Drafts on the server")
        await shot(compose, "write-20-autosave")
        // closed without saving: the copy only the automatic saving made goes
        onMain { compose.performClose(nil) }
        let ask = await waitWindow("alert", 10)
        check(ask != nil, "closing a message saved only automatically asks whether to keep it")
        answer(ask, Text.macDontSave.text)
        check(await waitUntil { !compose.isVisible }, "Don't Save closes the window")
        check(await waitUntil(30) { await findMessage("Drafts", "Subject: Saved by itself") == nil },
              "and removes the copy saved automatically from Drafts")

        step("a message being written opened again after a crash")
        command(.newMail)
        guard let written = await waitCompose() else { throw Failed(description: "no compose window") }
        compose = written
        type("Hal <hal@example.com>", into: field("compose.to", compose))
        type("Written when it crashed", into: field("compose.subject", compose))
        _ = await typeInEditor(compose, "Kept for a crash.")
        let writtenStatus: NSTextField? = find("compose.status", in: compose)
        check(await waitUntil(30) { writtenStatus?.stringValue.hasPrefix(lead(.uiComposeSavedAt)) == true }, "saved by itself")
        // the window gone as a crash takes it, without closing
        onMain { ComposeWindow.open.first { $0.window === compose }?.abandon() }
        _ = await waitUntil { !compose.isVisible }
        onMain { ComposeWindow.openRecovered(core: self.main.core) }
        guard let restored = await waitFor(10, { ComposeWindow.open.last.flatMap { $0.window.title == "Written when it crashed" ? $0.window : nil } })
        else { throw Failed(description: "the message was not opened again") }
        check(field("compose.to", restored)?.stringValue.contains("hal@example.com") == true, "it opens again with its recipient")
        let restoredStatus: NSTextField? = find("compose.status", in: restored)
        check(restoredStatus?.stringValue.hasPrefix(Text.uiComposeRestored.text) == true, "and says it was restored")
        await shot(restored, "write-21-restored")
        onMain { restored.performClose(nil) }
        let again = await waitWindow("alert", 10)
        check(again != nil, "closing it asks whether to keep it")
        answer(again, Text.macDontSave.text)
        check(await waitUntil { !restored.isVisible }, "Don't Save closes it")
        check(await findMessage("Drafts", "Subject: Written when it crashed") != nil,
              "and leaves its draft in Drafts, as it may be one the user kept")
        onMain { ComposeWindow.openRecovered(core: self.main.core) }
        _ = await waitUntil(2) { false }
        check(ComposeWindow.open.isEmpty, "closed, it is not opened again at the next start")
    }

    func undoSend() async throws {
        step("Undo Send")
        command(.options)
        guard await waitWindow("settings", 10) != nil, let options = SettingsWindow.current else {
            throw Failed(description: "Settings did not open")
        }
        await showPane(options, .general)
        check(options.sendDelay.titleOfSelectedItem == Text.sendDelayOff.text, "Delay before sending is in Settings, General (\(options.sendDelay.titleOfSelectedItem ?? ""))")
        check(options.sendDelay.itemTitles == [Text.sendDelayOff.text, "5 seconds", "10 seconds", "20 seconds", "30 seconds"],
              "with the waits it offers (\(options.sendDelay.itemTitles))")
        onMain { options.sendDelay.selectItem(at: 2); options.sendDelayChosen() }
        check(await waitUntil(5) { pe_send_delay_index(self.main.core.handle) == 2 }, "10 seconds chosen")
        await shot(options.window, "write-24-send-delay")
        onMain { options.window.close() }

        command(.newMail)
        guard let compose = await waitCompose() else { throw Failed(description: "no compose window") }
        type("Ida <ida@example.com>", into: field("compose.to", compose))
        type("Taken back in the UI test", into: field("compose.subject", compose))
        _ = await typeInEditor(compose, "On second thought.")
        send(compose)
        check(await waitUntil { !compose.isVisible }, "Send closes the message")
        let outgoing: NSTextField? = find("status.outbox", in: main.window)
        let undoButton: NSButton? = find("status.undoSend", in: main.window)
        check(await waitUntil(5) { outgoing?.stringValue.hasPrefix("Sending “Taken back in the UI test” in") == true },
              "the status bar counts down to sending (\(outgoing?.stringValue ?? ""))")
        check(undoButton?.isHidden == false, "with an Undo button")
        check(main.core.undoLabel == Text.undoSend.text, "Edit names Undo Send (\(main.core.undoLabel ?? "nothing"))")
        await shot(main.window, "write-22-undo-send")
        press(undoButton)
        guard let undone = await waitFor(10, { ComposeWindow.open.last.flatMap { $0.window.title == "Taken back in the UI test" ? $0.window : nil } })
        else { throw Failed(description: "the message did not open again") }
        check(field("compose.to", undone)?.stringValue.contains("ida@example.com") == true, "Undo opens the message again, as it was")
        check(undoButton?.isHidden == true, "and the Undo button goes")
        let mainStatus: NSTextField? = find("status.text", in: main.window)
        check(mainStatus?.stringValue.contains("was not sent") == true, "the status bar says it was not sent (\(mainStatus?.stringValue ?? ""))")
        await shot(undone, "write-23-undone")
        _ = await waitUntil(12) { false }
        check(await findMessage("INBOX", "Subject: Taken back in the UI test") == nil, "taken back, it never goes")

        // sent again and left alone: it goes once its time came
        _ = await typeInEditor(undone, " Sent after all.", atEnd: true)
        send(undone)
        check(await waitFor(40) { await findMessage("INBOX", "Subject: Taken back in the UI test") } != nil,
              "left alone, it goes once its time came")
        check(await waitUntil(10) { undoButton?.isHidden == true }, "and the Undo button goes with it")
        onMain { pe_set_send_delay_index(self.main.core.handle, 0) }
    }

    func attachmentReminder() async throws {
        step("a reminder when an attachment is missing")
        command(.newMail)
        guard let compose = await waitCompose() else { throw Failed(description: "no compose window") }
        type("Jo <jo@example.com>", into: field("compose.to", compose))
        type("Forgot the file in the UI test", into: field("compose.subject", compose))
        _ = await typeInEditor(compose, "Here is the attached plan.")
        send(compose)
        let ask = await waitWindow("alert", 10)
        check(ask != nil, "a message that says a file is attached, with none, asks first")
        check(alertText(ask).contains("You wrote “attached”"), "naming the word (\(alertText(ask)))")
        await shot(ask, "write-25-attachment-reminder")
        answer(ask, Text.uiGoBack.text)
        _ = await waitUntil(2) { false }
        check(compose.isVisible, "Go Back keeps the message open")
        send(compose)
        let again = await waitWindow("alert", 10)
        answer(again, Text.uiSendAnyway.text)
        check(await waitFor(30) { await findMessage("INBOX", "Subject: Forgot the file in the UI test") } != nil,
              "Send Anyway sends it")
    }

    func textSize() async throws {
        step("Text Size")
        selectFolder(named: "Inbox")
        _ = await waitUntil(10) { !self.main.mailbox.listLoading && self.list.numberOfRows > 0 }
        await selectRow(0)
        let pane: WKWebView? = find("preview", in: main.window)
        check(menuItem(.textSizeMedium)?.state == .on, "View > Text Size is Medium at first")
        check(menuItem(.textSizeLarger)?.keyEquivalent.isEmpty == true, "with no key, so it never changes by accident")
        check(pane?.allowsMagnification == false, "and the reading pane's own zoom is off")
        AppDelegate.shared.perform(.textSizeLarger)
        check(await waitUntil(5) { abs((pane?.pageZoom ?? 0) - 1.2) < 0.01 }, "Larger shows the message larger (\(pane?.pageZoom ?? 0))")
        check(menuItem(.textSizeLarger)?.state == .on && menuItem(.textSizeMedium)?.state == .off, "and is checked in the menu")
        check(pe_text_size(main.core.handle) == 1, "it is kept for the next start")
        await pause(1)
        await shot(main.window, "read-30-text-size")
        // a new message's editor writes at that size too
        command(.newMail)
        if let compose = await waitCompose() {
            let editor = views(WKWebView.self, in: compose.contentView).first
            check(abs((editor?.pageZoom ?? 0) - 1.2) < 0.01, "the text being written is that size too")
            onMain { compose.performClose(nil) }
            _ = await waitUntil(5) { !compose.isVisible }
        }
        AppDelegate.shared.perform(.textSizeMedium)
        check(await waitUntil(5) { abs((pane?.pageZoom ?? 0) - 1) < 0.01 }, "Medium is the usual size again")
    }

    func flaggedFolder() async throws {
        step("the Flagged folder")
        guard let row = treeRow(PE_TREE_ROW_KIND_FLAGGED) else {
            check(false, "Flagged is in the folder list")
            return
        }
        check(row == 1 && folderRow("Inbox") == 0, "Flagged is in the folder list right under the Inbox (row \(row))")
        let before = main.core.flaggedCount
        // a message of another folder flagged: it is listed too
        selectFolder(named: "Archive")
        _ = await waitUntil(10) { !self.main.mailbox.listLoading && self.list.numberOfRows > 0 }
        await selectRow(0)
        let subject = main.mailbox.selectedRow?.subject ?? ""
        AppDelegate.shared.perform(.flag)
        // the app's own command reads the list again once the store has it (Acted), not when the change is reported
        // a moment later
        check(await waitUntil(2) { main.mailbox.selectedRow?.flagged == true && main.mailbox.selectedRow?.subject == subject },
              "the row is flagged as soon as the command is done, still selected")
        check(await waitUntil(10) { self.main.core.flaggedCount == before + 1 }, "flagging a message counts it under Flagged")
        onMain { _ = self.tree.selectRowIndexes(IndexSet(integer: row), byExtendingSelection: false) }
        check(await waitUntil(10) { self.list.numberOfRows == Int(before + 1) },
              "Flagged lists the flagged messages of every folder (\(self.list.numberOfRows))")
        check((0..<list.numberOfRows).contains { main.mailbox.row($0)?.subject == subject }, "the one from Archive among them")
        let folderColumn = list.tableColumns.first { $0.identifier.rawValue == "folder" }
        check(folderColumn?.title == Text.uiColFolder.text, "with the Folder each is in (\(folderColumn?.title ?? "none"))")
        check(main.window.title.hasPrefix("Flagged"), "the window is named Flagged (\(main.window.title))")
        await shot(main.window, "main-10-flagged")
        // unflagged in its own folder: it goes from Flagged
        if let index = (0..<list.numberOfRows).first(where: { main.mailbox.row($0)?.subject == subject }) {
            await selectRow(index)
            command(.flag)
            check(await waitUntil(10) { self.main.core.flaggedCount == before }, "unflagged, it is no longer counted")
        }
        selectFolder(named: "Inbox")
    }

    /// the other addresses of the account set in Properties (field 11), empty to have none
    func setOtherAddresses(_ text: String, shot: String? = nil) async throws {
        command(.accounts)
        guard let accounts = await waitWindow("accounts", 10) else { throw Failed(description: "no Accounts window") }
        press(find("accounts.properties", in: accounts))
        guard let form = await waitFor(10, { window("form").flatMap { $0.title == Text.uiProperties.text ? $0 : nil } }) else {
            throw Failed(description: "no Properties form")
        }
        type(text, into: find("form.field.11", in: form))
        if let shot { await self.shot(form, shot) }
        press(find("form.ok", in: form))
        if let ask = await waitWindow("alert", 3) { answer(ask, Text.uiYes.text) }
        _ = await waitUntil(10) { !form.isVisible }
        press(find("accounts.close", in: accounts))
        _ = await waitUntil(10) { !accounts.isVisible }
    }

    func otherAddresses() async throws {
        step("sending from another address")
        try await setOtherAddresses("Sales Desk <sales@inboxclassic.test>", shot: "account-12-other-addresses")
        check(taken(pe_account_addresses(main.core.handle, main.mailbox.currentAccount)) == "Sales Desk <sales@inboxclassic.test>",
              "Properties keeps the other addresses the account sends from")
        command(.newMail)
        guard let compose = await waitCompose() else { throw Failed(description: "no compose window") }
        let from: NSPopUpButton? = find("compose.from", in: compose)
        check(from?.itemTitles.contains { $0.hasPrefix("Sales Desk <sales@inboxclassic.test>") } == true,
              "From offers the other address (\(from?.itemTitles ?? []))")
        if let from, let index = from.itemTitles.firstIndex(where: { $0.hasPrefix("Sales Desk") }) {
            onMain { from.selectItem(at: index); _ = from.sendAction(from.action, to: from.target) }
        }
        type("Kim <kim@example.com>", into: field("compose.to", compose))
        type("From the sales desk in the UI test", into: field("compose.subject", compose))
        _ = await typeInEditor(compose, "Prices on request.")
        await shot(compose, "write-26-from-alias")
        send(compose)
        let sent = await waitFor(30) { await findMessage("INBOX", "Subject: From the sales desk in the UI test") }
        check(sent.map { raw($0).contains("From: Sales Desk <sales@inboxclassic.test>") } == true, "it goes from that address, with its name")
        // a message sent to the other address: its reply goes from it
        try await addMessage("From: Lee <lee@example.com>\r\nTo: sales@inboxclassic.test\r\nSubject: Price list please\r\n"
            + "Message-ID: <prices@example.com>\r\nDate: Mon, 06 Oct 2025 09:00:00 +0000\r\n\r\nCould you send it?\r\n", to: "Archive")
        command(.sync)
        selectFolder(named: "Archive")
        let row = await waitFor(20) { (0..<self.list.numberOfRows).first { self.main.mailbox.row($0)?.subject == "Price list please" } }
        if let row { await selectRow(row) }
        command(.reply)
        guard let reply = await waitFor(10, { ComposeWindow.open.last.flatMap { $0.window.title.contains("Price list") ? $0.window : nil } })
        else { throw Failed(description: "no reply window") }
        let replyFrom: NSPopUpButton? = find("compose.from", in: reply)
        check(replyFrom?.titleOfSelectedItem?.hasPrefix("Sales Desk <sales@inboxclassic.test>") == true,
              "a reply to a message sent to it goes from it (\(replyFrom?.titleOfSelectedItem ?? ""))")
        await shot(reply, "write-27-reply-from-alias")
        onMain { reply.performClose(nil) }
        if let ask = await waitWindow("alert", 5) { answer(ask, Text.macDontSave.text) }
        _ = await waitUntil(5) { !reply.isVisible }
        selectFolder(named: "Inbox")
        try await setOtherAddresses("")
    }

    // ---- message rules ----

    /// the rule editor opened by something done just now, its query as typed there
    func waitRuleEditor() async -> (NSWindow, String)? {
        guard let editor = await waitWindow("rule", 10) else { return nil }
        let query: NSTextField? = find("rule.query", in: editor)
        return (editor, query?.stringValue ?? "")
    }

    func cancelRuleEditor(_ editor: NSWindow) async {
        press(find("rule.cancel", in: editor))
        _ = await waitUntil(10) { !editor.isVisible }
    }

    func messageRules() async throws {
        step("message rules")
        selectFolder(named: "Inbox")
        _ = await waitUntil(20) { self.list.numberOfRows >= 4 && self.main.core.folders(self.main.mailbox.currentAccount).count > 1 }
        command(.messageRules)
        guard let rules = await waitWindow("rules", 10) else { throw Failed(description: "no Message Rules window") }
        let table: NSTableView? = find("rules.list", in: rules)
        let none: NSTextField? = find("rules.none", in: rules)
        check(table?.numberOfRows == 0 && none?.isHidden == false, "Message Rules opens empty, saying how to make one")
        await shot(rules, "rules-1-list")
        press(find("rules.new", in: rules))
        guard let editor = await waitWindow("rule", 10) else { throw Failed(description: "no rule editor") }
        type("Newsletters", into: find("rule.name", in: editor))
        type("from:news@example.com", into: find("rule.query", in: editor))
        let count: NSTextField? = find("rule.count", in: editor)
        // counted once typing stops
        _ = await waitUntil(5) { count?.stringValue.contains("Inbox message") == true }
        check(count?.stringValue.contains("Inbox message") == true, "the editor counts what the query matches in the Inbox (\(count?.stringValue ?? ""))")
        let move: NSButton? = find("rule.move", in: editor)
        let target: NSPopUpButton? = find("rule.target", in: editor)
        onMain { move?.performClick(nil) }
        _ = await waitUntil(5) { target?.isEnabled == true }
        check(target?.isEnabled == true, "Move it to chooses its folder once checked")
        if let target, let index = target.itemTitles.firstIndex(where: { $0.trimmingCharacters(in: .whitespaces) == "Archive" }) {
            target.selectItem(at: index)
        } else {
            check(false, "Archive is among the folders a rule moves to (\(target?.itemTitles ?? []))")
        }
        let read: NSButton? = find("rule.read", in: editor)
        onMain { read?.performClick(nil) }
        _ = await waitUntil(5) { read?.state == .on }
        await shot(editor, "rules-2-editor")
        press(find("rule.ok", in: editor))
        check(await waitUntil(10) { !editor.isVisible }, "OK saves the rule")
        check(await waitUntil(5) { table?.numberOfRows == 1 && none?.isHidden == true }, "the list has the rule")
        press(find("rules.close", in: rules))
        _ = await waitUntil(10) { !rules.isVisible }

        // new mail from the newsletter: sorted into Archive, read, and said in the status bar
        try await addMessage("From: News <news@example.com>\r\nTo: testuser@inboxclassic.test\r\nSubject: Weekly news in the UI test\r\n"
            + "Message-ID: <weekly@example.com>\r\nDate: \(rfc2822(Date()))\r\n\r\nThe news.\r\n")
        let status: NSTextField? = find("status.text", in: main.window)
        var said = ""
        command(.sync)
        let sorted = await waitUntil(30) {
            if let text = status?.stringValue, text.contains("sorted by your rules") { said = text }
            return await findMessage("Archive", "Subject: Weekly news in the UI test") != nil
        }
        check(sorted, "a rule moves new mail from news@example.com to Archive")
        check(await findMessage("INBOX", "Subject: Weekly news in the UI test") == nil, "and it is not in the Inbox")
        check(((await findMessage("Archive", "Subject: Weekly news in the UI test"))?["flags"] as? [String])?.contains("\\Seen") == true,
              "and it is marked as read")
        _ = await waitUntil(10) {
            if let text = status?.stringValue, text.contains("sorted by your rules") { said = text }
            return !said.isEmpty
        }
        check(said.contains("1 message sorted by your rules"), "the status bar says what the rules did (\(said))")
        // Archive, with the message the rule put there, the status bar still saying so
        selectFolder(named: "Archive")
        if let row = await waitFor(10, { (0..<self.list.numberOfRows).first { self.main.mailbox.row($0)?.subject == "Weekly news in the UI test" } }) {
            await selectRow(row)
        }
        main.setStatus(said)
        await shot(main.window, "rules-5-applied")
        selectFolder(named: "Inbox")

        // a query with a folder in it is no rule's
        command(.messageRules)
        guard let rules2 = await waitWindow("rules", 10) else { throw Failed(description: "no Message Rules window") }
        press(find("rules.new", in: rules2))
        guard let bad = await waitWindow("rule", 10) else { throw Failed(description: "no rule editor") }
        type("in:sent from:x", into: find("rule.query", in: bad))
        let flag: NSButton? = find("rule.flag", in: bad)
        onMain { flag?.performClick(nil) }
        _ = await waitUntil(5) { flag?.state == .on }
        press(find("rule.ok", in: bad))
        if let alert = await waitWindow("alert", 10) {
            let text = alertText(alert)
            check(text.contains("folder") || text.contains("date"), "a query naming a folder is refused, saying why (\(text))")
            await shot(alert, "rules-6-bad-query")
            answer(alert, Text.uiOk.text)
            _ = await waitUntil(5) { !alert.isVisible }
        } else {
            check(false, "a query naming a folder is refused")
        }
        check(bad.isVisible, "the editor stays open after a refusal")
        await cancelRuleEditor(bad)
        press(find("rules.close", in: rules2))
        _ = await waitUntil(10) { !rules2.isVisible }

        // Create Rule on the search bar: the words searched for
        await search("lunch")
        let createRule: NSButton? = find("search.rule", in: main.window)
        // the bar comes with what the search found, read off the window thread
        check(await waitUntil(10) { self.list.numberOfRows > 0 && createRule?.isHiddenOrHasHiddenAncestor == false },
              "the search bar offers Create Rule")
        press(createRule)
        if let (editor, query) = await waitRuleEditor() {
            check(query == "lunch", "Create Rule makes one of the words searched for (\(query))")
            await shot(editor, "rules-3-from-search")
            await cancelRuleEditor(editor)
        } else {
            check(false, "Create Rule opens the rule editor")
        }
        await search("")
        // Create Rule from Message: its sender
        selectFolder(named: "Inbox")
        _ = await waitUntil(10) { !self.main.mailbox.listLoading && self.list.numberOfRows > 0 }
        let row = (0..<list.numberOfRows).first { main.mailbox.row($0)?.subject == "Photos from Saturday" } ?? 0
        await selectRow(row)
        command(.createRuleFromMessage)
        if let (editor, query) = await waitRuleEditor() {
            check(query.hasPrefix("from:"), "Create Rule from Message makes one of its sender (\(query))")
            await shot(editor, "rules-4-from-message")
            await cancelRuleEditor(editor)
        } else {
            check(false, "Create Rule from Message opens the rule editor")
        }

        // the rule deleted, so the later steps see new mail in the Inbox
        command(.messageRules)
        guard let rules3 = await waitWindow("rules", 10) else { throw Failed(description: "no Message Rules window") }
        let table3: NSTableView? = find("rules.list", in: rules3)
        onMain { table3?.selectRowIndexes(IndexSet(integer: 0), byExtendingSelection: false) }
        press(find("rules.delete", in: rules3))
        if let ask = await waitWindow("alert", 10) { answer(ask, "Delete") }
        check(await waitUntil(10) { table3?.numberOfRows == 0 }, "Delete takes the rule away")
        press(find("rules.close", in: rules3))
        _ = await waitUntil(10) { !rules3.isVisible }
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
        _ = await waitUntil { !main.mailbox.listLoading && list.numberOfRows >= 1 }
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
        await search("subject:\"Weekly list news\"")
        _ = await waitUntil(20) { list.numberOfRows == 1 }
        await selectRow(0)
        let unsubscribe: NSButton? = find("reader.unsubscribe", in: main.window)
        check(await waitUntil(15) { unsubscribe?.isHidden == false }, "a message of a mailing list has Unsubscribe in its header")
        await shot(main.window, "read-8-unsubscribe")
        press(unsubscribe)
        let sure = await waitWindow("alert", 10)
        check(alertText(sure).contains("127.0.0.1"), "it asks first, naming where it goes")
        check(!alertText(sure).contains("e-mail") && hyphensKept("no e-mail") == "no e\u{2011}mail",
              "a word with a hyphen is not wrapped at it")
        await shot(sure, "read-9-unsubscribe-ask")
        answer(sure, Text.uiYes.text)
        check(await waitUntil(15) { server.received.hasPrefix("POST /u/42 ") && server.received.contains("List-Unsubscribe=One-Click") },
              "Yes posts List-Unsubscribe=One-Click to the list")
        let status: NSTextField? = find("status.text", in: main.window)
        check(await waitUntil(10) { status?.stringValue.contains(Text.uiUnsubscribed.text) == true }, "and the status bar says it is done")
        await search("")
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
        await search("subject:\"Quarterly planning\"")
        _ = await waitUntil(20) { list.numberOfRows == 1 }
        await selectRow(0)
        check(await waitUntil(15) {
            let text = await readerText()
            return text.contains("Invitation: Quarterly planning") && text.contains(Text.uiOpenInCalendar.text) && text.contains("Room 2")
        }, "a message with an invitation shows the event in a card above the text, with Open in Calendar")
        let preview = views(WKWebView.self, in: main.mailbox.reader.view).first
        let link = try? await preview?.evaluateJavaScript("document.querySelector('a[href=\"inboxclassic:open-calendar\"]') !== null")
        check(link as? Bool == true, "its Open in Calendar is the card's own link")
        await shot(main.window, "read-10-invitation")
        await search("")
        step("a brand logo (BIMI)")
        let svg = "<svg xmlns=\"http://www.w3.org/2000/svg\" version=\"1.2\" baseProfile=\"tiny-ps\" viewBox=\"0 0 100 100\"><title>Brand</title>"
            + "<rect width=\"100\" height=\"100\" rx=\"22\" fill=\"#0a5bd3\"/><circle cx=\"50\" cy=\"50\" r=\"26\" fill=\"#ffffff\"/><circle cx=\"50\" cy=\"50\" r=\"13\" fill=\"#0a5bd3\"/></svg>"
        try await addMessage("Authentication-Results: mx.inboxclassic.test; dmarc=pass header.from=brand.example; bimi=pass header.d=brand.example\r\n"
            + "BIMI-Indicator: \(Data(svg.utf8).base64EncodedString())\r\nFrom: Brand <hello@brand.example>\r\nTo: testuser@inboxclassic.test\r\n"
            + "Subject: News from the brand\r\nDate: \(rfc2822(Date()))\r\nMessage-ID: <brand-news@brand.example>\r\n\r\nOur news.\r\n")
        command(.sync)
        _ = await waitFor(20) { await findMessage("INBOX", "Subject: News from the brand") }
        await search("subject:\"News from the brand\"")
        _ = await waitUntil(20) { list.numberOfRows == 1 }
        await selectRow(0)
        let logo = views(NSImageView.self, in: main.mailbox.reader.view).first { $0.frame.width == 48 }
        check(await waitUntil(15) { logo?.isHidden == false && logo?.image != nil }, "a sender whose logo the server passed has it beside the header")
        await shot(main.window, "read-11-logo")
        await search("")
        try await oneAccountTree()

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
        _ = await waitUntil(20) { !main.mailbox.listLoading && list.numberOfRows >= 1 }
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
        _ = await waitUntil(20) { !main.mailbox.listLoading && main.mailbox.row(0)?.subject == "Win a prize" }
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
        _ = await waitUntil(20) { (folderNode("Archive")?.row.unread ?? 0) >= 1 }
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
        answer(goOn, Text.uiYes.text)
        check(await waitUntil(10) { main.mailbox.selectedName == "Archive" && main.mailbox.selectedRow?.subject == "Unread in the archive" },
              "and Yes goes there, its unread message selected (\(main.mailbox.selectedName): \(main.mailbox.selectedRow?.subject ?? "none"))")

        command(.goToFolder)
        guard let goTo = await waitWindow("move", 10) else { throw Failed(description: "Go to Folder opened nothing") }
        // the folders fill in after the window opens
        // with one account there is no row for the account, as in the folder list
        let everyFolder = await waitUntil(10) {
            !moveRows(goTo).contains { $0.kind == .account } && moveRows(goTo).contains { $0.name == "Sent Items" }
        }
        check(goTo.title == Text.cmdGoToFolder.title && everyFolder, "Go to Folder shows the account's folders, with no row for the account (\(goTo.title))")
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
        // where the subjects start, as the cells lay them out now (a cell made for the check has had no pass yet)
        let left = { (row: Int) -> CGFloat in
            guard let cell = self.subjectCell(row) else { return 0 }
            cell.layoutSubtreeIfNeeded()
            return cell.textField?.frame.minX ?? 0
        }
        check(left(tripHead.index + 1) > left(tripHead.index), "indented (\(left(tripHead.index)) and \(left(tripHead.index + 1)))")
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
        if let archiveId = folderNode("Archive")?.row.folder {
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
        await showPane(options, .general)
        check(options.signInCodes.state == .off && !pe_codes_in_notifications() && options.signInCodes.isEnabled,
              "Show sign-in codes in new mail notifications is there, off at first")
        press(options.notify)
        check(await waitUntil(5) { !options.signInCodes.isEnabled && !AppDelegate.shared.notify },
              "with Notify me when new mail arrives turned off, the codes check box is disabled")
        press(options.notify)
        check(await waitUntil(5) { options.signInCodes.isEnabled && AppDelegate.shared.notify }, "and enabled again when it is on")
        onMain { options.signInCodes.state = .on; options.signInCodesChanged() }
        check(await waitUntil(5) { pe_codes_in_notifications() }, "turned on, the core names the codes in the notifications")
        onMain { options.signInCodes.state = .off; options.signInCodesChanged() }
        _ = await waitUntil(5) { !pe_codes_in_notifications() }
        await showPane(options, .reading)
        check(options.grouping.state == .on, "Group messages by conversation is on in Settings, Reading")
        onMain { options.grouping.state = .off; options.groupingChanged() }
        check(await waitUntil(5) { tripRows().count == 3 && tripRows().allSatisfy { $0.message.thread == 0 } },
              "turned off, the three messages are each a row of their own")
        check(main.mailbox.selectedRow?.uid == main.mailbox.reader.uid && main.mailbox.reader.uid != 0,
              "and the message the pane shows is still selected (\(main.mailbox.selectedRow?.subject ?? "none"))")
        // the list at that row, the main window in front
        onMain {
            self.list.scrollRowToVisible(self.list.selectedRow)
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

    /// whether the right-click menu of the selected rows checks `command`: the list has no Watch column, the menu says
    /// whether a conversation is watched or ignored
    func contextChecked(_ command: Command) -> Bool {
        main.mailbox.messageMenu()?.items.first { $0.tag == command.rawValue }?.state == .on
    }

    /// the colour of the sender on row `index`
    func fromColor(_ index: Int) -> NSColor? {
        let column = list.column(withIdentifier: NSUserInterfaceItemIdentifier("from"))
        guard column >= 0 else { return nil }
        return (list.view(atColumn: column, row: index, makeIfNecessary: true) as? NSTableCellView)?.textField?.textColor
    }

    /// the From of a row is drawn as an ignored conversation's (grey, or dimmed white on the selection)
    func fromGrey(_ index: Int) -> Bool {
        let column = list.column(withIdentifier: NSUserInterfaceItemIdentifier("from"))
        guard column >= 0 else { return false }
        return (list.view(atColumn: column, row: index, makeIfNecessary: true) as? TextCell)?.grey == true
    }

    func watchAndIgnore() async throws {
        step("watch and ignore a conversation")
        selectFolder(named: "Inbox")
        let ids = list.tableColumns.map(\.identifier.rawValue)
        let width = { (id: String) in self.list.tableColumn(withIdentifier: NSUserInterfaceItemIdentifier(id))?.width ?? 0 }
        check(!ids.contains("watch") && !ids.contains("size") && width("subject") > width("from") && width("subject") > width("received"),
              "the list has no Watch or Size column, and Subject takes the room (\(ids), \(Int(width("subject"))) wide)")
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
            return head.message.mark == PE_THREAD_MARK_WATCH && contextChecked(.watchConversation)
                && !contextChecked(.ignoreConversation) && menuItem(.watchConversation)?.state == .on
        }, "Watch Conversation checks the menu item, in the Message menu and the right-click menu")
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
        // opened, every message of it is watched; the new reply selected
        command(.expandAllThreads)
        check(await waitUntil(5) {
            let rows = tripRows()
            return rows.count == 4 && rows.allSatisfy { $0.message.mark == PE_THREAD_MARK_WATCH }
        }, "every message of the watched conversation is watched")
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
            return head.message.mark == PE_THREAD_MARK_NONE && !contextChecked(.watchConversation)
                && menuItem(.watchConversation)?.state == .off
        }, "Watch Conversation again takes the check marks away (W in the list)")
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
            guard let row = partyRow(), row.message.mark == PE_THREAD_MARK_IGNORE, contextChecked(.ignoreConversation),
                  fromGrey(row.index) else { return false }
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
        check(partyRows.count == 3 && partyRows.allSatisfy { fromGrey($0) },
              "every message of the ignored conversation is grey")
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
            return row.message.mark == PE_THREAD_MARK_NONE && !contextChecked(.ignoreConversation) && fromColor(row.index) == .labelColor
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
        // all three listed first: one arriving after the row was found would move the selection to another message
        _ = await waitUntil(30) { [signed, byHeader, unsigned].allSatisfy { self.listIndex(subject: $0) != nil } }
        guard let row = listIndex(subject: signed) else {
            throw Failed(description: "the message with a code did not arrive")
        }
        list.scrollRowToVisible(row)
        await selectRow(row)
        check(await waitUntil(15) { (await readerText()).contains("Code from accounts.example.com") },
              "a code in the text of a message the domain signed is shown in a card above it")
        let card = await readerText()
        check(card.contains("482913") && card.contains("Enter it only on a page of example.com"),
              "with the code, and the domain to enter it on")
        check(card.contains(Text.otpOld.text), "a message older than an hour says the code has probably expired")
        await shot(main.window, "otp-1-card")
        NSPasteboard.general.clearContents()
        let preview = views(WKWebView.self, in: main.mailbox.reader.view).first
        _ = try? await preview?.evaluateJavaScript("document.querySelector('a[href=\"inboxclassic:copy-code\"]').click()")
        let status: NSTextField? = find("status.text", in: main.window)
        check(await waitUntil(5) { NSPasteboard.general.string(forType: .string) == "482913" },
              "Copy puts the code on the clipboard (\(NSPasteboard.general.string(forType: .string) ?? "nothing"))")
        check(status?.stringValue == Text.uiCodeCopied.text, "and the status bar says so (\(status?.stringValue ?? ""))")
        // a sync in the background (the timer's) replaces only its own words, never the answer to what the user did
        main.core.syncAll()
        await pause(3)
        check(status?.stringValue == Text.uiCodeCopied.text,
              "a sync in the background leaves those words (\(status?.stringValue ?? ""))")

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
        check(!(await readerText()).contains(lead(.otpHeading)), "without a card: the provider did not say the domain signed it")
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
        check(await waitUntil(15) { (await readerText()).contains(Text.bounceFailed.text) },
              "opening it shows the card above the message: not delivered")
        let failedCard = await readerText()
        check(failedCard.contains("robin.nobody@example.org") && failedCard.contains(Text.bounceUserUnknown.text)
              && failedCard.contains(Text.bounceWhatToDo.text),
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
        check(await waitUntil(15) { (await readerText()).contains(Text.bounceDelayed.text) },
              "a delay notice shows the amber card")
        check((await readerText()).contains(Text.bounceDelayedNote.text), "saying it is still being tried")
        await shot(main.window, "bounce-2-delayed")

        await search("is:bounce")
        check(await waitUntil(20) { list.numberOfRows == 2 }, "is:bounce finds the two notices and nothing else (\(list.numberOfRows))")
        let foundSubjects = Set((0..<list.numberOfRows).compactMap { main.mailbox.row($0)?.subject })
        check(foundSubjects == [failedSubject, delayedSubject], "the report and the delay notice")
        if let shownRow = listIndex(subject: failedSubject) {
            await selectRow(shownRow)
        }
        await shot(main.window, "bounce-3-list")
        await search("")
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
        check(await waitUntil(5) { main.mailbox.selectedCount == 3 }, "Command+click adds two more messages: three are selected")
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
        check(main.core.undoLabel == Text.undoMove.text, "Edit names Undo Move (\(main.core.undoLabel ?? "nothing"))")
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
        check(await waitUntil(5) { main.mailbox.selectedCount == list.numberOfRows && list.numberOfRows > 0 },
              "Select All selects every message of the list")
        await selectRow(0)
        let header: NSTextField? = find("reader.header", in: main.window)
        check(!main.mailbox.reader.showsSummary && header?.stringValue.isEmpty == false,
              "one message selected again is shown in the reading pane")
    }

    // ---- big actions, off the window thread ----

    /// a mailbox made (`create`) or deleted on the server, as another client would
    func serverMailbox(_ path: String, create: Bool) async {
        let escaped = path.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? path
        var request = URLRequest(url: URL(string: create ? rest : "\(rest)/\(escaped)")!)
        request.httpMethod = create ? "POST" : "DELETE"
        if create {
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = try? JSONSerialization.data(withJSONObject: ["path": path, "subscribed": true])
        }
        _ = try? await URLSession.shared.data(for: request)
    }

    /// Select All, Move and Delete of a whole folder done off the window thread: the status bar says what was done at
    /// once, and a move the server refuses comes back, a bar over the list saying so in the core's words until closed
    func bigActions() async throws {
        step("big actions")
        let mailbox = main.mailbox
        // a folder with three messages, and one another client deletes behind the app's back
        await serverMailbox("Bulk", create: true)
        await serverMailbox("Gone", create: true)
        for n in 1...3 {
            try await addMessage("From: Bulk <bulk@example.com>\r\nTo: testuser@inboxclassic.test\r\nSubject: Bulk \(n)\r\n"
                + "Message-ID: <bulk\(n)@example.com>\r\nDate: Thu, \(n) Oct 2025 08:00:00 +0000\r\n\r\nBulk mail \(n).\r\n",
                to: "Bulk")
        }
        command(.sync)
        guard await waitUntil(30, { folderRow("Gone") != nil && selectFolder(named: "Bulk") }) else {
            throw Failed(description: "no folder Bulk")
        }
        check(await waitUntil(30) { list.numberOfRows == 3 && !mailbox.listCovered }, "the folder lists its three messages")
        await serverMailbox("Gone", create: false)

        command(.selectAll)
        check(await waitUntil(10) { mailbox.selectedCount == 3 && !mailbox.summaryWaiting && mailbox.summary.count == 3 },
              "Select All selects the three, their summary read off the window thread (\(mailbox.summary.count))")
        await selectRow(0)
        // Move chosen before Select All's summary is here: it waits for it, then asks where once
        var waitedForMove = false
        onMain {
            AppDelegate.shared.perform(.selectAll)
            waitedForMove = mailbox.summaryWaiting
            AppDelegate.shared.perform(.move)
        }
        let move = await waitWindow("move", 10)
        check(waitedForMove && move != nil, "Move chosen before Select All's summary is here opens its window once it is")
        if let move {
            choose(folder(ofAccount: 0, named: "Gone"), in: move)
            press(find("move.ok", in: move))
            _ = await waitUntil(5) { !move.isVisible }
        }
        await pause(1)
        check(window("move") == nil, "and only once")
        let status: NSTextField? = find("status.text", in: main.window)
        // the status bar says they were moved, until the server refuses
        check(await waitUntil(10) { status?.stringValue == "Moved 3 messages to Gone" || !mailbox.undoneText.isEmpty },
              "the status bar says they were moved at once (\(status?.stringValue ?? ""))")
        let refused = "The server did not move 3 messages to Gone, so they are back in Bulk: "
        check(await waitUntil(30) { mailbox.undoneText.hasPrefix(refused) },
              "the server refuses the move: a bar over the list says so in the core's words (\(mailbox.undoneText))")
        check(status?.stringValue.isEmpty == true, "and the status bar no longer says they were moved")
        check(await waitUntil(20) { list.numberOfRows == 3 }, "and the three are back in the list")
        // and selected again, in sight, as what Undo brings back is
        let back = { () -> Bool in
            let rows = self.list.selectedRowIndexes
            let visible = self.list.rows(in: self.list.visibleRect)
            return rows.count == 3 && rows.allSatisfy { visible.contains($0) }
                && Set(rows.compactMap { mailbox.row($0)?.subject }) == ["Bulk 1", "Bulk 2", "Bulk 3"]
        }
        check(await waitUntil(20) { back() }, "the three that came back are selected, in sight")
        await pause(0.5)
        await shot(main.window, "many-1-refused")
        main.window.appearance = NSAppearance(named: .darkAqua)
        await pause(0.5)
        await shot(main.window, "many-2-refused-dark")
        main.window.appearance = nil
        let bar: InfoBar? = find("list.undone", in: main.window)
        bar?.press()
        check(mailbox.undoneText.isEmpty && bar?.isHidden == true, "the bar's cross closes it")

        await selectRow(0)
        // Delete pressed before Select All's summary is here: it waits for it, then deletes once
        AppDelegate.shared.perform(.selectAll)
        let waitedForDelete = mailbox.summaryWaiting
        AppDelegate.shared.perform(.delete)
        check(waitedForDelete && list.numberOfRows == 3, "Delete pressed before Select All's summary is here waits for it")
        check(await waitUntil(10) { status?.stringValue == "Moved 3 messages to Deleted Items" },
              "Select All then Delete: the status bar says the three went to Deleted Items (\(status?.stringValue ?? ""))")
        check(await waitUntil(20) { list.numberOfRows == 0 }, "and out of the list")
        check(await waitUntil(20) {
            let left = await messages("Bulk")
            let trashed = await findMessage("Trash", "Subject: Bulk 3")
            return left.isEmpty && trashed != nil
        },
              "and into Deleted Items on the server")
        await pause(1)
        let bulk = await messages("Trash").filter { raw($0).contains("Subject: Bulk ") }.count
        check(bulk == 3, "deleted once: each of the three is in Deleted Items once (\(bulk))")
        // the folder gone again, for the steps after
        await serverMailbox("Bulk", create: false)
        selectFolder(named: "Inbox")
        command(.sync)
        _ = await waitUntil(30) { folderRow("Bulk") == nil && folderRow("Gone") == nil }
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
              && menu?.items.last?.title == Text.uiClearFlag.text,
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
        check(rightClick.contains { $0.title == Text.uiMenuFlag.text && $0.submenu != nil }
              && !rightClick.contains { $0.title == Command.flag.label || $0.title == Text.uiClearFlag.text },
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
        // the list read again once the sync's changes are gathered
        check(await waitUntil(5) {
            menu?.items.first { $0.tag == 5 }.map { item in _ = AppDelegate.shared.validateMenuItem(item); return item.state == .on } == true
        }, "the Flag menu checks Blue for them")
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
        _ = await waitUntil { list.numberOfRows > before && !main.mailbox.listLoading }
        // the three newest selected as they are, none of them opened by the test: the new one is not downloaded
        let ferry = await waitFor(10) { (0..<self.list.numberOfRows).first { self.main.mailbox.row($0)?.subject == "Ferry times" } }
        check(ferry == 0, "the new message is the newest (\(ferry.map(String.init) ?? "not listed"))")
        list.window?.makeFirstResponder(list)
        list.selectRowIndexes(IndexSet([0, 1, 2]), byExtendingSelection: false)
        _ = await waitUntil(5) { list.selectedRowIndexes == IndexSet([0, 1, 2]) }
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
        answer(turnedAway, Text.uiOk.text)
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
        check(menu && main.mailbox.info(ofFolder: folderNode("Inbox")?.row.folder ?? 0)?.fixed == true,
              "the Inbox can not be renamed or deleted")
    }

    /// the tree's row `row` (All Inboxes) chosen by the user, with Up from the row below it (the same handler as a
    /// click): the row is selected and the title says it at once, the list before dimmed and taking no keys, and the
    /// list loads on a later turn of the run loop, after the tree is drawn
    func clickPaintsFirst(_ row: Int) async {
        guard let node = treeNode(row), row + 1 < tree.numberOfRows else {
            check(false, "the tree has the row to choose and one below it")
            return
        }
        let mailbox = main.mailbox
        // held while it loads, for its pictures: the list before dimmed at once, and "Loading..." after a moment, in
        // light and dark. A sync that changes the folders loads it at once (the tree is built again): then again
        let loading: NSTextField? = find("list.loading", in: main.window)
        var held = false
        for _ in 0..<5 where !held {
            tree.selectRowIndexes(IndexSet(integer: row + 1), byExtendingSelection: false)
            _ = await waitUntil(5) { tree.selectedRow == row + 1 && !mailbox.listCovered }
            mailbox.holdPending = true
            pressUp(in: tree)
            await shot(main.window, "all-inboxes-0a-dimmed")
            _ = await waitUntil(Mailbox.loadingWait + 2) { loading?.isHidden == false }
            main.window.appearance = NSAppearance(named: .darkAqua)
            await shot(main.window, "all-inboxes-0b-loading-dark")
            main.window.appearance = nil
            held = mailbox.listCovered && loading?.isHidden == false
            mailbox.holdPending = false
            mailbox.loadPending()
        }
        check(held, "a list that takes a while to load says Loading... over the list before")
        // read off the window thread: still dimmed when the load is asked for, until it is drawn
        check(mailbox.listCovered, "the list before stays dimmed while the list chosen is read off the window thread")
        check(await waitUntil(10) { mailbox.allInboxes && !mailbox.listCovered && loading?.isHidden == true },
              "and goes once the list is loaded")
        // from the list of the row below
        tree.selectRowIndexes(IndexSet(integer: row + 1), byExtendingSelection: false)
        _ = await waitUntil(5) { !mailbox.listCovered && tree.selectedRow == row + 1 }
        let before = mailbox.allInboxes
        mailbox.paintOrder = []
        let started = Date()
        pressUp(in: tree)
        let selectedIn = Date().timeIntervalSince(started)
        check(tree.selectedRow == row && main.window.title == node.row.title && !before && !mailbox.allInboxes
              && mailbox.listCovered,
              "choosing \(node.row.label) selects its row and names it in the title at once, the list before dimmed while it loads (row \(tree.selectedRow), \(main.window.title), covered \(mailbox.listCovered))")
        // generous: a busy runner; the list is not read in the key press
        check(selectedIn < 0.5, "the row is selected within the key press, its list not read in it (\(Int(selectedIn * 1000)) ms)")
        check(await waitUntil(10) { mailbox.allInboxes && !mailbox.listCovered },
              "then its list loads and the list is no longer dimmed")
        check(mailbox.paintOrder == ["selected \(node.row.key)", "loading \(node.row.key)", "loaded \(node.row.key)"],
              "the row was drawn selected before its list was asked for and drawn (\(mailbox.paintOrder))")
    }

    /// the tree's row of the first account's folder named `name`
    func folderNode(_ name: String) -> Mailbox.TreeNode? {
        folderRow(name).flatMap(treeNode)
    }

    /// Up pressed in the folder tree
    func pressUp(in view: NSView) {
        guard let up = NSEvent.keyEvent(with: .keyDown, location: .zero, modifierFlags: [], timestamp: 0,
                                        windowNumber: main.window.windowNumber, context: nil,
                                        characters: String(UnicodeScalar(NSUpArrowFunctionKey)!),
                                        charactersIgnoringModifiers: String(UnicodeScalar(NSUpArrowFunctionKey)!),
                                        isARepeat: false, keyCode: 126) else { return }
        view.window?.makeFirstResponder(view)
        view.keyDown(with: up)
    }

    /// an arrow key (`key`, an NS...ArrowFunctionKey, with its `keyCode`) pressed in `view`
    func pressArrow(_ key: Int, _ keyCode: UInt16, in view: NSView) {
        let character = String(UnicodeScalar(key)!)
        guard let event = NSEvent.keyEvent(with: .keyDown, location: .zero, modifierFlags: [.numericPad, .function], timestamp: 0,
                                           windowNumber: main.window.windowNumber, context: nil, characters: character,
                                           charactersIgnoringModifiers: character, isARepeat: false, keyCode: keyCode) else { return }
        view.window?.makeFirstResponder(view)
        view.keyDown(with: event)
    }

    /// the menu a right-click on the tree's row `row` opens
    func treeMenu(_ row: Int) -> NSMenu? {
        let rect = tree.rect(ofRow: row)
        let point = tree.convert(NSPoint(x: rect.midX, y: rect.midY), to: nil)
        guard let click = NSEvent.mouseEvent(with: .rightMouseDown, location: point, modifierFlags: [], timestamp: 0,
                                             windowNumber: main.window.windowNumber, context: nil, eventNumber: 0,
                                             clickCount: 1, pressure: 1) else { return nil }
        return tree.menu(for: click)
    }

    /// a folder made or deleted through the core, as the windows do; false when the core refused
    func makeFolder(_ name: String, under parent: Int64) -> Bool {
        var reason: UnsafeMutablePointer<CChar>?
        let made = name.withCString { pe_folder_create(main.core.handle, main.mailbox.currentAccount, parent, $0, &reason) }
        _ = taken(reason)
        return made
    }

    func deleteFolder(_ id: Int64) {
        var reason: UnsafeMutablePointer<CChar>?
        _ = pe_folder_delete(main.core.handle, id, &reason)
        _ = taken(reason)
    }

    /// one account: the Inbox first, Flagged second, then the other folders, with no heading; a folder the server keeps
    /// in the Inbox listed a level up; the Inbox's menu a folder's; New Folder from Flagged at the top
    func oneAccountTree() async throws {
        step("the folder list of one account")
        selectFolder(named: "Inbox")
        let labels = { (0..<self.tree.numberOfRows).compactMap { self.treeNode($0)?.row.label } }
        let kinds = (0..<tree.numberOfRows).compactMap { treeNode($0)?.kind }
        check(folderRow("Inbox") == 0 && treeRow(PE_TREE_ROW_KIND_FLAGGED) == 1
              && ["Sent Items", "Drafts", "Archive"].allSatisfy { (folderRow($0) ?? 0) > 1 },
              "the Inbox is the first row, Flagged the second, then the other folders (\(labels()))")
        check(!kinds.contains(PE_TREE_ROW_KIND_ACCOUNT) && !kinds.contains(PE_TREE_ROW_KIND_ALL_INBOXES) && tree.level(forRow: 0) == 0,
              "there is no row for the account: no heading, nothing to collapse at the top")
        check(!kinds.contains(PE_TREE_ROW_KIND_ALL_SENT) && !kinds.contains(PE_TREE_ROW_KIND_ALL_DRAFTS),
              "with one account there is no All Sent or All Drafts: Sent Items and Drafts are the account's own folders")

        // a folder kept in the Inbox on the server
        let inbox = folderNode("Inbox")?.row.folder ?? 0
        check(makeFolder("Receipts", under: inbox), "a folder is made inside the Inbox")
        check(await waitUntil(20) { await mailboxes().contains { $0.hasPrefix("INBOX") && $0.hasSuffix("Receipts") } },
              "on the server, inside the Inbox")
        check(await waitUntil(10) { self.folderRow("Receipts") == 2 && self.tree.level(forRow: 2) == 0 }
              && treeNode(0)?.row.parent == false,
              "the Inbox holds no folders of its own: the folder in it is listed a level up, after Flagged (\(labels()))")
        selectFolder(named: "Inbox")
        _ = await waitUntil(5) { self.main.mailbox.folder == inbox }
        await pause(0.5)
        await shot(main.window, "folders-6-one-account")

        let titles = treeMenu(0)?.items.filter { !$0.isSeparatorItem }.map(\.title) ?? []
        check(titles.contains(Command.newFolder.label) && !titles.contains(Text.uiAccountSync.text) && !titles.contains { $0.hasPrefix(Text.uiAccountProperties.text.replacingOccurrences(of: "...", with: "")) },
              "right-clicking the Inbox gives the folder's menu, without the account's commands (\(titles))")

        tree.selectRowIndexes(IndexSet(integer: 1), byExtendingSelection: false)
        _ = await waitUntil(5) { self.main.mailbox.flagged }
        check(treeMenu(1) == nil, "Flagged has no right-click menu: its messages are of every folder")
        command(.newFolder)
        await answerName("New Folder", "Top level", shot: nil)
        check(await waitUntil(20) { await mailboxes().contains("Top level") }, "New Folder with Flagged selected makes the folder at the top")
        check(await waitUntil(10) { self.folderRow("Top level").map { self.tree.level(forRow: $0) == 0 } ?? false },
              "and the tree lists it at the top (\(labels()))")

        for name in ["Receipts", "Top level"] {
            if let id = folderNode(name)?.row.folder {
                deleteFolder(id)
            }
        }
        let gone = await waitUntil(20) {
            let all = await mailboxes()
            return !all.isEmpty && !all.contains { $0.hasSuffix("Receipts") || $0 == "Top level" }
        }
        check(gone, "the two folders are deleted again on the server (\(await mailboxes()))")
        check(await waitUntil(10) { self.folderRow("Receipts") == nil && self.folderRow("Top level") == nil },
              "and leave the tree (\(labels()))")
        selectFolder(named: "Inbox")
    }

    /// with two accounts an account is a heading over its folders that can not be selected (the arrow keys pass it
    /// by); closed, it shows the unread messages of the folders it hides, and the folder listed stays listed
    func collapsedAccount(_ account: Int64, folder: Int64) async {
        step("a collapsed account")
        let rowLabel = { (row: Int) -> String in
            (self.tree.view(atColumn: 0, row: row, makeIfNecessary: true) as? NSTableCellView)?.accessibilityLabel() ?? ""
        }
        guard let head = treeRow(PE_TREE_ROW_KIND_ACCOUNT, account: account), let row = treeRow({ $0.folder == folder }) else {
            check(false, "the first account's heading and its folder are in the tree")
            return
        }
        let heading = { self.tree.view(atColumn: 0, row: head, makeIfNecessary: true) as? HeadingCell }
        let unread = treeNode(row)?.row.unread ?? 0
        check(unread >= 1, "a folder of the account has unread messages (\(rowLabel(row)))")
        check(heading() != nil && tree.delegate?.outlineView?(tree, shouldSelectItem: tree.item(atRow: head) as Any) == false,
              "the account is a heading over its folders, which can not be selected")
        tree.selectRowIndexes(IndexSet(integer: head + 1), byExtendingSelection: false)
        pressUp(in: tree)
        check(tree.selectedRow != head, "Up from its first folder does not select the heading (row \(tree.selectedRow))")
        tree.selectRowIndexes(IndexSet(integer: row), byExtendingSelection: false)
        _ = await waitUntil(5) { self.main.mailbox.folder == folder }
        let listed = main.mailbox.total
        main.mailbox.headingClicked(head)
        check(await waitUntil(5) {
            !self.tree.isItemExpanded(self.tree.item(atRow: head)) && rowLabel(head).hasSuffix("unread")
                && (heading()?.unreadShown ?? 0) >= unread
        }, "a click on the heading closes the account, which shows the unread messages of its folders (\(rowLabel(head)))")
        check(main.mailbox.folder == folder && main.mailbox.total == listed && tree.selectedRow < 0,
              "the folder it hides stays listed, and nothing is selected in the tree (\(main.mailbox.total) of \(listed), row \(tree.selectedRow))")
        await shot(main.window, "folders-5-collapsed")
        main.mailbox.headingClicked(head)
        check(await waitUntil(5) { !rowLabel(head).hasSuffix("unread") && rowLabel(row).hasSuffix("unread") && self.tree.selectedRow == row },
              "a second click opens it again: the count is back on the folder, which is selected again (row \(tree.selectedRow) of \(row))")
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
            check(editor.title.hasPrefix(lead(.uiSignatureOf)), "titled with the account (\(editor.title))")
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
        answer(hint, Text.uiNo.text)
        let servers = await waitFor(20) { window("form").flatMap { $0.title == Text.uiAddAccountTitle.text ? $0 : nil } }
        let imap = servers.flatMap { (find("form.field.5", in: $0) as NSTextField?)?.stringValue }
        let smtp = servers.flatMap { (find("form.field.8", in: $0) as NSTextField?)?.stringValue }
        let gmailName = servers.flatMap { (find("form.field.0", in: $0) as NSTextField?)?.stringValue }
        check(gmailName == "Gmail", "a Gmail address's Account name starts as Gmail (\(gmailName ?? ""))")
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
        guard let second = await waitFor(40, { window("form").flatMap { $0.title == Text.uiAddAccountTitle.text ? $0 : nil } }) else {
            throw Failed(description: "no server settings form")
        }
        let field = { (index: Int) -> NSTextField? in self.find("form.field.\(index)", in: second) }
        // the folder list names it Work too
        type("Work", into: field(0))
        type("testuser2", into: field(3))
        type("not-the-password", into: field(4))
        type("127.0.0.1", into: field(5))
        type(secondPort("imap"), into: field(6))
        (find("form.field.7", in: second) as NSPopUpButton?)?.selectItem(at: 2)
        type("127.0.0.1", into: field(8))
        type(secondPort("smtp"), into: field(9))
        (find("form.field.10", in: second) as NSPopUpButton?)?.selectItem(at: 1)
        press(find("form.ok", in: second))
        if let warning = await waitWindow("alert", 10) {
            answer(warning, Text.uiYes.text)
        }
        let logon = await waitFor(30) { window("form").flatMap { $0.title == Text.uiLogon.text ? $0 : nil } }
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

    /// the second account's mail on its own server, for All Inboxes: unread, dated now and a minute before, so it is the
    /// newest in the list (over what the steps before added); a date ahead would be listed at its arrival anyway
    func seedSecond() async throws {
        for (from, subject, body, minutes) in [
            ("Priya Shah <priya@work.example>", "Contract renewal for next year",
             "The renewal is ready to sign. Could you look it over before Friday?", 0.0),
            ("Tom Becker <tom@work.example>", "Offsite agenda",
             "Here is the agenda for the offsite. Add anything you want to talk about.", -1.0),
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
        return main.mailbox.core.folders(accounts[index].id).first { $0.specialUse == PE_SPECIAL_USE_INBOX }
    }

    // ---- All Inboxes ----

    /// the mail of both accounts' Inboxes in one list, a reply from the account of a message, Mark All Read of both
    func allInboxes() async throws {
        step("All Inboxes")
        // a new message for the first account too, so both have unread mail
        try await addMessage("From: Maria Lopez <maria@example.org>\r\nTo: testuser@inboxclassic.test\r\n"
            + "Subject: Photos from the trip\r\nDate: \(rfc2822(Date()))\r\n"
            + "Message-ID: <trip-photos@example.org>\r\n\r\nThe photos from the trip are in the shared album.\r\n")
        command(.sync)
        _ = await waitUntil(20) { (inbox(ofAccount: 0)?.unread ?? 0) >= 1 }
        guard let first = inbox(ofAccount: 0)?.id, let second = inbox(ofAccount: 1)?.id else {
            check(false, "both accounts have an Inbox")
            return
        }
        let kinds = (0..<tree.numberOfRows).compactMap { treeNode($0)?.kind }
        let headings = (0..<tree.numberOfRows).filter { treeNode($0)?.kind == PE_TREE_ROW_KIND_ACCOUNT }
        check(kinds.first == PE_TREE_ROW_KIND_ALL_INBOXES && (treeRow(PE_TREE_ROW_KIND_FLAGGED) ?? .max) < (headings.first ?? 0)
              && headings.count == 2,
              "All Inboxes is at the top of the tree, then Flagged, then each account's heading")
        // the headings list the accounts' other folders, without the Inbox, Sent Items and Drafts (step 42d)
        let under = headings.compactMap(treeNode).map { $0.children.map(\.row.label) }
        check(under.allSatisfy { !$0.isEmpty && !$0.contains("Inbox") && !$0.contains("Sent Items") && !$0.contains("Drafts") }
              && treeRow({ ($0.folder == first || $0.folder == second) && $0.kind != PE_TREE_ROW_KIND_ACCOUNT_INBOX }) == nil,
              "the Inbox of each account is under All Inboxes only: an account's heading lists its other folders, without Sent Items and Drafts (\(under))")
        await clickPaintsFirst(treeRow(PE_TREE_ROW_KIND_ALL_INBOXES) ?? 0)
        var expected: UInt64 = 0
        // grouped by conversation the rows are fewer: the messages they list are counted
        check(await waitUntil(10) {
            expected = (inbox(ofAccount: 0)?.total ?? 0) + (inbox(ofAccount: 1)?.total ?? 0)
            return main.mailbox.total == expected
        },
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
        let menu = (main.mailbox.folderMenu()?.items ?? []).filter { !$0.isSeparatorItem }.map(\.title)
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

    // ---- All Inboxes by account ----

    /// the cell of the folder tree's row `row`
    func folderCell(_ row: Int) -> FolderCell? {
        tree.view(atColumn: 0, row: row, makeIfNecessary: true) as? FolderCell
    }

    /// each account's Inbox under All Inboxes, named as the account is; an account's name set in its Properties; the
    /// account's right-click menu
    func allInboxesByAccount() async throws {
        step("All Inboxes by account")
        // unread mail in both Inboxes and in a folder of the first account besides its Inbox
        try await addMessage("From: Sam Lee <sam@example.org>\r\nTo: testuser@inboxclassic.test\r\n"
            + "Subject: Lunch on Thursday\r\nDate: \(rfc2822(Date()))\r\n"
            + "Message-ID: <lunch-thursday@example.org>\r\n\r\nAre we still on for lunch on Thursday?\r\n")
        try await addMessage("From: Sam Lee <sam@example.org>\r\nTo: testuser@inboxclassic.test\r\n"
            + "Subject: Old receipts\r\nDate: \(rfc2822(Date(timeIntervalSinceNow: -3600)))\r\n"
            + "Message-ID: <old-receipts@example.org>\r\n\r\nThe receipts from last year.\r\n", to: "Archive")
        try await addMessage("From: Priya Shah <priya@work.example>\r\nTo: testuser2@inboxclassic.test\r\n"
            + "Subject: Budget review\r\nDate: \(rfc2822(Date()))\r\n"
            + "Message-ID: <budget-review@work.example>\r\n\r\nThe budget review moved to Monday.\r\n", at: secondRest)
        command(.sync)
        let archive = folder(ofAccount: 0, named: "Archive")
        _ = await waitUntil(30) {
            (inbox(ofAccount: 0)?.unread ?? 0) >= 1 && (inbox(ofAccount: 1)?.unread ?? 0) >= 1
                && main.mailbox.core.folderCounts(archive).unread >= 1
        }
        guard let first = inbox(ofAccount: 0), let second = inbox(ofAccount: 1), let allRow = treeRow(PE_TREE_ROW_KIND_ALL_INBOXES),
              let all = treeNode(allRow) else {
            check(false, "both accounts have an Inbox, and All Inboxes is at the top")
            return
        }
        let accounts = main.mailbox.core.accounts()
        if !tree.isItemExpanded(all) {
            tree.expandItem(all)
        }
        let firstRow = tree.row(forItem: all.children.first)
        let secondRow = tree.row(forItem: all.children.last)
        let rows = all.children.map(\.row)
        check(rows.map(\.folder) == [first.id, second.id] && rows.map(\.label) == accounts.map(\.title)
              && rows.allSatisfy { $0.kind == PE_TREE_ROW_KIND_ACCOUNT_INBOX }
              && tree.level(forRow: firstRow) == 1 && tree.level(forRow: secondRow) == 1,
              "All Inboxes has a row for each account under it, in the accounts' order, named as the account is (\(rows.map(\.label)))")
        let inboxesUnread = first.unread + second.unread
        check(await waitUntil(10) {
            self.folderCell(firstRow)?.unreadShown == first.unread && self.folderCell(secondRow)?.unreadShown == second.unread
                && self.folderCell(firstRow)?.isBold == true && self.folderCell(allRow)?.unreadShown == inboxesUnread
        }, "each row shows its Inbox's unread count, All Inboxes the count of all of them (\(folderCell(firstRow)?.unreadShown ?? 0) of \(first.unread), \(folderCell(secondRow)?.unreadShown ?? 0) of \(second.unread), \(folderCell(allRow)?.unreadShown ?? 0) of \(inboxesUnread))")
        let spoken = folderCell(secondRow)?.accessibilityLabel() ?? ""
        check(spoken.hasPrefix("Inbox - Work"), "a screen reader hears the folder and the account (\(spoken))")
        tree.collapseItem(all)
        check(await waitUntil(5) { self.folderCell(allRow)?.unreadShown == main.mailbox.core.inboxUnread && self.folderCell(allRow)?.isBold == true },
              "closed, All Inboxes shows the unread messages of every Inbox, in bold (\(folderCell(allRow)?.unreadShown ?? 0))")
        tree.expandItem(all)

        tree.selectRowIndexes(IndexSet(integer: secondRow), byExtendingSelection: false)
        check(await waitUntil(10) { main.mailbox.folder == second.id && main.mailbox.total == second.total },
              "the second account's row lists its Inbox (\(main.mailbox.total) of \(second.total))")
        let folders = Set((0..<list.numberOfRows).compactMap { main.mailbox.row($0)?.folder })
        check(folders == [second.id], "the first account's mail is not in it")
        check(main.mailbox.selectedName == "Inbox - Work" && main.window.title == "Inbox - Work",
              "the title names the Inbox and the account (\(main.window.title))")
        // a message read already, so the account's unread mail stays unread for the account's menu below
        let readRow = (0..<list.numberOfRows).first { main.mailbox.row($0)?.seen == true } ?? 0
        await selectRow(readRow)
        await shot(main.window, "all-inboxes-3-accounts")

        // a message of the first account's Inbox shown from outside the tree (a notification) keeps the selection
        // under All Inboxes
        tree.selectRowIndexes(IndexSet(integer: allRow), byExtendingSelection: false)
        let both = first.total + second.total
        check(await waitUntil(10) { main.mailbox.total == both }, "All Inboxes again lists both accounts' Inboxes (\(main.mailbox.total) of \(both))")
        let firstMessage = (0..<list.numberOfRows).compactMap { main.mailbox.row($0) }.first { $0.folder == first.id }
        tree.selectRowIndexes(IndexSet(integer: secondRow), byExtendingSelection: false)
        _ = await waitUntil(10) { main.mailbox.folder == second.id }
        if let firstMessage {
            // All Inboxes closed first: the row is shown to be selected
            tree.collapseItem(all)
            main.showMessage(folder: first.id, uid: firstMessage.uid)
            check(await waitUntil(10) { main.mailbox.folder == first.id && tree.selectedRow == firstRow && tree.isItemExpanded(all) },
                  "a message of the first Inbox opened from outside the tree selects its row under All Inboxes, opened (row \(tree.selectedRow))")
            // that opening only showed the row, it is not kept: the user opens All Inboxes again for the steps after
            tree.collapseItem(all)
            tree.expandItem(all)
        }
        tree.selectRowIndexes(IndexSet(integer: allRow), byExtendingSelection: false)

        await collapsedAccount(accounts[0].id, folder: archive)
        tree.selectRowIndexes(IndexSet(integer: allRow), byExtendingSelection: false)

        step("the account name")
        command(.accounts)
        guard let window = await waitWindow("accounts", 10) else { throw Failed(description: "no Accounts window") }
        let table: NSTableView? = find("accounts.list", in: window)
        table?.selectRowIndexes(IndexSet(integer: 1), byExtendingSelection: false)
        press(find("accounts.properties", in: window))
        guard let form = await waitFor(10, { self.window("form").flatMap { $0.title == Text.uiProperties.text ? $0 : nil } }) else {
            throw Failed(description: "no Properties form")
        }
        let name: NSTextField? = find("form.field.0", in: form)
        check(name?.stringValue == "Work", "the second account's Properties has its Account name first (\(name?.stringValue ?? ""))")
        type("Second", into: name)
        press(find("form.ok", in: form))
        if let ask = await waitWindow("alert", 3) {
            answer(ask, Text.uiYes.text)
        }
        _ = await waitUntil(10) { !form.isVisible }
        press(find("accounts.close", in: window))
        _ = await waitUntil(10) { !window.isVisible }
        let secondLabels = { [PE_TREE_ROW_KIND_ACCOUNT, PE_TREE_ROW_KIND_ACCOUNT_INBOX].map {
            self.treeRow($0, account: accounts[1].id).flatMap(self.treeNode)?.row.label ?? "" } }
        check(await waitUntil(10) { secondLabels() == ["Second", "Second"] },
              "set to Second, the account's heading and its row under All Inboxes say Second (\(secondLabels()))")

        step("the account's menu")
        let menu = main.mailbox.accountMenu(accounts[0].id)
        let titles = menu.items.filter { !$0.isSeparatorItem }.map(\.title)
        check(titles == [Text.uiAccountSync.text, Command.markAllRead.label, Command.newFolder.label, Text.uiAccountMoveUp.text, Text.uiAccountMoveDown.text, Text.uiAccountProperties.opens]
              && menu.items.filter(\.isSeparatorItem).count == 3,
              "the first account's right-click menu has Send and Receive, Mark All Read, New Folder, Move Up, Move Down and Properties (\(titles))")
        check(menu.items.first { $0.title == Command.markAllRead.label }?.isEnabled == true, "Mark All Read is on, with unread mail in the account")
        let markRead = menu.indexOfItem(withTitle: "Mark All Read")
        if markRead >= 0 {
            onMain { menu.performActionForItem(at: markRead) }
        }
        check(await waitUntil(30) {
            let inbox = await unreadOnServer()
            let archived = await messages("Archive").filter { !(($0["flags"] as? [String]) ?? []).contains("\\Seen") }.count
            return inbox == 0 && archived == 0
        }, "its Mark All Read marks every folder of the first account read on the server")
        check(await unreadOnServer(at: secondRest) >= 1, "the second account's mail stays unread")
        check(await waitUntil(10) { !main.mailbox.accountMenu(accounts[0].id).items.contains { $0.title == Command.markAllRead.label && $0.isEnabled } },
              "with nothing unread, the account's Mark All Read is off")
        await shot(main.window, "account-menu")
        let properties = main.mailbox.accountMenu(accounts[0].id)
        onMain { properties.performActionForItem(at: properties.indexOfItem(withTitle: Text.uiAccountProperties.opens)) }
        let own = await waitFor(10) { self.window("form").flatMap { $0.title == Text.uiProperties.text ? $0 : nil } }
        let ownName = own.flatMap { (find("form.field.0", in: $0) as NSTextField?)?.stringValue }
        check(own != nil && ownName == accounts[0].accountName,
              "its Properties opens that account's Properties (\(ownName ?? ""))")
        press(own.flatMap { find("form.cancel", in: $0) })
        _ = await waitUntil(10) { own?.isVisible != true }
    }

    // ---- the accounts' order ----

    /// the accounts of the tree's headings and of the rows under All Inboxes, top to bottom
    func treeOrder() -> (headings: [Int64], inboxes: [Int64]) {
        let rows = (0..<tree.numberOfRows).compactMap { treeNode($0)?.row }
        return (rows.filter { $0.kind == PE_TREE_ROW_KIND_ACCOUNT }.map(\.account),
                rows.filter { $0.kind == PE_TREE_ROW_KIND_ACCOUNT_INBOX }.map(\.account))
    }

    /// the second account's row under All Inboxes dragged above the first's: both lists follow and the row stays
    /// selected; Move Down on its menu puts it back, Move Up and Move Down off at the ends
    func accountOrder() async throws {
        step("the accounts' order")
        let ids = main.mailbox.core.accounts().map(\.id)
        guard ids.count == 2, let all = treeRow(PE_TREE_ROW_KIND_ALL_INBOXES).flatMap(treeNode), let second = inbox(ofAccount: 1) else {
            check(false, "two accounts and All Inboxes")
            return
        }
        if !tree.isItemExpanded(all) {
            tree.expandItem(all)
        }
        func accountItem(_ account: Int64, _ title: String) -> NSMenuItem? {
            main.mailbox.accountMenu(account).items.first { $0.title == title }
        }
        check(accountItem(ids[0], Text.uiAccountMoveUp.text)?.isEnabled == false && accountItem(ids[0], Text.uiAccountMoveDown.text)?.isEnabled == true
              && accountItem(ids[1], Text.uiAccountMoveDown.text)?.isEnabled == false,
              "Move Up is off for the first account, Move Down for the last")
        let secondRow = treeRow(PE_TREE_ROW_KIND_ACCOUNT_INBOX, account: ids[1]) ?? -1
        tree.selectRowIndexes(IndexSet(integer: secondRow), byExtendingSelection: false)
        _ = await waitUntil(10) { main.mailbox.folder == second.id }

        let heading = treeRow(PE_TREE_ROW_KIND_ACCOUNT).flatMap(treeNode)
        let headingDrag = TestDrag(heading.flatMap { main.mailbox.outlineView(tree, pasteboardWriterForItem: $0) }, in: tree)
        // the top rows: All Inboxes, Flagged and the two headings; below the last heading is a move for the first
        let top = main.mailbox.outlineView(tree, numberOfChildrenOfItem: nil)
        check(main.mailbox.outlineView(tree, validateDrop: headingDrag, proposedItem: all, proposedChildIndex: 2) == []
              && main.mailbox.outlineView(tree, validateDrop: headingDrag, proposedItem: nil, proposedChildIndex: top - 1) == []
              && main.mailbox.outlineView(tree, validateDrop: headingDrag, proposedItem: nil, proposedChildIndex: top) == .move,
              "an account's heading drops between the headings, not among All Inboxes' rows, and only where it moves")
        guard let row = treeNode(secondRow), row.kind == PE_TREE_ROW_KIND_ACCOUNT_INBOX else {
            check(false, "the second account's row under All Inboxes")
            return
        }
        let drag = TestDrag(main.mailbox.outlineView(tree, pasteboardWriterForItem: row), in: tree)
        check(main.mailbox.outlineView(tree, validateDrop: drag, proposedItem: nil, proposedChildIndex: 1) == []
              && main.mailbox.outlineView(tree, validateDrop: drag, proposedItem: all, proposedChildIndex: 2) == []
              && main.mailbox.outlineView(tree, validateDrop: drag, proposedItem: all, proposedChildIndex: 0) == .move,
              "a row under All Inboxes drops between those rows only, and only where it moves")
        let dropped = main.mailbox.outlineView(tree, acceptDrop: drag, item: all, childIndex: 0)
        check(dropped && treeOrder().headings == [ids[1], ids[0]] && treeOrder().inboxes == [ids[1], ids[0]]
              && main.mailbox.core.accounts().map(\.id) == [ids[1], ids[0]],
              "dropped above the first, the second account is first under All Inboxes and in the tree (\(treeOrder()))")
        check(tree.selectedRow == treeRow(PE_TREE_ROW_KIND_ACCOUNT_INBOX) && main.mailbox.folder == second.id,
              "the moved row stays selected (row \(tree.selectedRow))")
        await selectRow(0)
        await shot(main.window, "all-inboxes-4-reorder")

        let menu = main.mailbox.accountMenu(ids[1])
        check(accountItem(ids[1], Text.uiAccountMoveUp.text)?.isEnabled == false, "first now, its Move Up is off")
        let down = menu.indexOfItem(withTitle: "Move Down")
        if down >= 0 {
            onMain { menu.performActionForItem(at: down) }
        }
        check(await waitUntil(10) { self.treeOrder().headings == ids && self.treeOrder().inboxes == ids },
              "Move Down on its menu puts it back below the first (\(treeOrder()))")
    }

    // ---- All Sent and All Drafts ----

    /// the editor's text in a compose window
    func editorText(_ compose: NSWindow) async -> String {
        guard let editor: EditorView = views(EditorView.self, in: compose.contentView).first else { return "" }
        _ = await waitUntil(10) { (try? await editor.evaluateJavaScript("!!window.pe")) as? Bool == true }
        return (try? await editor.evaluateJavaScript("document.getElementById('body').innerText") as? String) ?? ""
    }

    /// what every account sent, and every account's drafts, in one list each with a row per account under it; a
    /// draft from All Drafts opened in the compose window of its account
    func allSentAndDrafts() async throws {
        step("All Sent and All Drafts")
        let accounts = main.mailbox.core.accounts()
        let sent = [folder(ofAccount: 0, named: "Sent Items"), folder(ofAccount: 1, named: "Sent Items")]
        let drafts = [folder(ofAccount: 0, named: "Drafts"), folder(ofAccount: 1, named: "Drafts")]
        guard accounts.count == 2, !sent.contains(0), !drafts.contains(0) else {
            check(false, "two accounts, each with Sent Items and Drafts")
            return
        }
        let sentBefore = sent.map { main.mailbox.core.folderCounts($0).total }
        let draftsBefore = main.mailbox.core.folderCounts(drafts[0]).total
        try await addMessage("From: Alex Morgan <testuser@inboxclassic.test>\r\nTo: Nina Park <nina@example.org>\r\n"
            + "Subject: Slides for Tuesday\r\nDate: \(rfc2822(Date(timeIntervalSinceNow: -60)))\r\n"
            + "Message-ID: <slides-tuesday@inboxclassic.test>\r\n\r\nThe slides for Tuesday are attached to the invite.\r\n",
            flags: ["\\Seen"], to: "Sent")
        try await addMessage("From: Work <testuser2@inboxclassic.test>\r\nTo: Priya Shah <priya@work.example>\r\n"
            + "Subject: Signed contract\r\nDate: \(rfc2822(Date()))\r\n"
            + "Message-ID: <signed-contract@inboxclassic.test>\r\n\r\nThe signed contract is back with you.\r\n",
            flags: ["\\Seen"], at: secondRest, to: "Sent")
        try await addMessage("From: Alex Morgan <testuser@inboxclassic.test>\r\nTo: Leo Grant <leo@example.org>\r\n"
            + "Subject: Trip plans\r\nDate: \(rfc2822(Date()))\r\nMessage-ID: <trip-plans-draft@inboxclassic.test>\r\n"
            + "MIME-Version: 1.0\r\nContent-Type: text/plain; charset=utf-8\r\n\r\nThe train leaves at nine on Saturday.\r\n",
            flags: ["\\Seen", "\\Draft"], to: "Drafts")
        command(.sync)
        let counts = { sent.map { self.main.mailbox.core.folderCounts($0).total } }
        let synced = await waitUntil(30) {
            zip(counts(), sentBefore).allSatisfy { $0 > $1 } && self.main.mailbox.core.folderCounts(drafts[0]).total > draftsBefore
        }
        check(synced, "the sent messages and the draft are in the app (\(counts()) of \(sentBefore))")

        let top = (0..<main.mailbox.outlineView(tree, numberOfChildrenOfItem: nil)).compactMap {
            main.mailbox.outlineView(tree, child: $0, ofItem: nil) as? Mailbox.TreeNode
        }
        guard let shownSent = top.first(where: { $0.kind == PE_TREE_ROW_KIND_ALL_SENT }),
              let shownDrafts = top.first(where: { $0.kind == PE_TREE_ROW_KIND_ALL_DRAFTS }) else {
            check(false, "All Sent and All Drafts are in the tree (\(top.map(\.row.label)))")
            return
        }
        check(top.map(\.kind) == [PE_TREE_ROW_KIND_ALL_INBOXES, PE_TREE_ROW_KIND_ALL_SENT, PE_TREE_ROW_KIND_ALL_DRAFTS,
                                  PE_TREE_ROW_KIND_FLAGGED, PE_TREE_ROW_KIND_ACCOUNT, PE_TREE_ROW_KIND_ACCOUNT]
              && shownSent.row.label == Text.uiAllSent.text && shownDrafts.row.label == Text.uiAllDrafts.text,
              "All Sent and All Drafts follow All Inboxes, before Flagged (\(top.map(\.row.label)))")
        check(!tree.isItemExpanded(shownSent) && !tree.isItemExpanded(shownDrafts), "both start closed")
        await shot(main.window, "all-sent-0-closed")
        // a folder chosen from outside the tree is never hidden: Go to Folder opens the rows above it, without keeping
        // that as the user's opening
        main.mailbox.goToFolder(sent[0])
        check(await waitUntil(5) {
            self.tree.isItemExpanded(shownSent) && self.tree.selectedRow >= 0
                && self.tree.selectedRow == self.tree.row(forItem: shownSent.children.first) && self.main.mailbox.folder == sent[0]
        }, "Go to Folder to the first account's Sent Items opens All Sent and highlights its row (row \(tree.selectedRow))")
        // closed by the user while it is chosen, then the tree built again (as a new account builds it): opened again
        tree.collapseItem(shownSent)
        main.mailbox.reload()
        let firstSentRow = { self.treeRow { $0.folder == sent[0] } }
        check(await waitUntil(5) { firstSentRow() != nil && self.tree.selectedRow == firstSentRow() },
              "the tree built again with Sent Items chosen opens All Sent to show it highlighted (row \(tree.selectedRow))")
        if let inboxes = treeRow(PE_TREE_ROW_KIND_ALL_INBOXES) {
            tree.selectRowIndexes(IndexSet(integer: inboxes), byExtendingSelection: false)
        }
        _ = await waitUntil(5) { self.main.mailbox.allInboxes }
        main.mailbox.reload()
        let sentNode = { self.treeRow(PE_TREE_ROW_KIND_ALL_SENT).flatMap(self.treeNode) }
        check(sentNode().map { !tree.isItemExpanded($0) } == true,
              "with another folder chosen, the tree built again has All Sent closed as the user left it")
        // the tree's rows are new ones
        guard let allSent = sentNode(), let allDrafts = treeRow(PE_TREE_ROW_KIND_ALL_DRAFTS).flatMap(treeNode) else { return }
        // with the keyboard: Right opens All Sent, Down goes into its rows, Left back up to it
        tree.selectRowIndexes(IndexSet(integer: tree.row(forItem: allSent)), byExtendingSelection: false)
        pressArrow(NSRightArrowFunctionKey, 124, in: tree)
        check(tree.isItemExpanded(allSent), "Right opens All Sent")
        pressArrow(NSDownArrowFunctionKey, 125, in: tree)
        check(await waitUntil(5) { self.tree.selectedRow == self.tree.row(forItem: allSent.children.first) && self.main.mailbox.folder == sent[0] },
              "Down goes to its first account's row, which lists that Sent Items (row \(tree.selectedRow))")
        pressArrow(NSLeftArrowFunctionKey, 123, in: tree)
        check(tree.selectedRow == tree.row(forItem: allSent), "Left goes back up to All Sent (row \(tree.selectedRow))")
        tree.expandItem(allDrafts)
        for (node, folders) in [(allSent, sent), (allDrafts, drafts)] {
            let rows = node.children.map(\.row)
            let levels = node.children.map { tree.level(forRow: tree.row(forItem: $0)) }
            check(rows.map(\.folder) == folders && rows.map(\.label) == accounts.map(\.title)
                  && rows.allSatisfy { $0.kind == PE_TREE_ROW_KIND_FOLDER } && levels == [1, 1],
                  "opened, \(node.row.label) has a row per account named as the account is (\(rows.map(\.label)))")
        }
        let headings = top.filter { $0.kind == PE_TREE_ROW_KIND_ACCOUNT }
        func below(_ node: Mailbox.TreeNode) -> [Int64] { node.children.flatMap { [$0.row.folder] + below($0) } }
        check(headings.allSatisfy { Set(below($0)).isDisjoint(with: sent + drafts) },
              "the account headings list neither Sent Items nor Drafts (\(headings.map { $0.children.map(\.row.label) }))")

        step("All Sent's list")
        tree.selectRowIndexes(IndexSet(integer: tree.row(forItem: allSent)), byExtendingSelection: false)
        let both = counts().reduce(0, +)
        check(await waitUntil(10) { main.mailbox.total == both },
              "All Sent lists both accounts' sent messages (\(main.mailbox.total) of \(both))")
        let newest = (0..<list.numberOfRows).compactMap { main.mailbox.row($0) }
        let dates = newest.map { $0.date ?? 0 }
        check(dates == dates.sorted(by: >) && Set(newest.prefix(3).map(\.folder)) == Set(sent)
              && newest.first?.subject == "Signed contract",
              "newest first, the two accounts' messages among each other (\(newest.prefix(3).map(\.subject)))")
        let column = { (id: String) in self.list.tableColumn(withIdentifier: NSUserInterfaceItemIdentifier(id)) }
        let cell = column("folder").flatMap { list.column(withIdentifier: $0.identifier) }
            .flatMap { list.view(atColumn: $0, row: 0, makeIfNecessary: true) as? NSTableCellView }
        check(column("from")?.title == "To" && newest.first?.recipients.contains("Priya Shah") == true,
              "it names whom each message went to, in the To column (\(column("from")?.title ?? ""): \(newest.first?.recipients ?? ""))")
        check(column("folder")?.title == "Account" && cell?.textField?.stringValue == accounts[1].title,
              "the Account column names the account of each (\(column("folder")?.title ?? ""): \(cell?.textField?.stringValue ?? ""))")
        check(main.mailbox.selectedName == Text.uiAllSent.text && main.window.title == Text.uiAllSent.text,
              "the title says All Sent (\(main.window.title))")
        check(treeMenu(tree.row(forItem: allSent)) == nil && treeMenu(tree.row(forItem: allDrafts)) == nil,
              "All Sent and All Drafts have no right-click menu")
        await selectRow(0)
        await shot(main.window, "all-sent-1-list")

        if let secondRow = allSent.children.last.map({ tree.row(forItem: $0) }) {
            tree.selectRowIndexes(IndexSet(integer: secondRow), byExtendingSelection: false)
            let own = counts()[1]
            check(await waitUntil(10) { main.mailbox.folder == sent[1] && main.mailbox.total == own },
                  "the second account's row under All Sent lists its Sent Items (\(main.mailbox.total) of \(own))")
            check(Set((0..<list.numberOfRows).compactMap { main.mailbox.row($0)?.folder }) == [sent[1]],
                  "and that account's alone")
            check(main.mailbox.selectedName == "Sent Items - \(accounts[1].title)",
                  "the folder bar says Sent Items and the account's name (\(main.mailbox.selectedName))")
            let titles = treeMenu(secondRow)?.items.filter { !$0.isSeparatorItem }.map(\.title) ?? []
            check(titles.contains(Command.markAllRead.label) && titles.contains(Command.newFolder.label),
                  "a row under All Sent has the folder's menu (\(titles))")
        }

        step("All Drafts")
        tree.selectRowIndexes(IndexSet(integer: tree.row(forItem: allDrafts)), byExtendingSelection: false)
        let draftRow = { (0..<self.list.numberOfRows).first { self.main.mailbox.row($0)?.subject == "Trip plans" } }
        check(await waitUntil(10) { draftRow() != nil && main.mailbox.selectedName == Text.uiAllDrafts.text },
              "All Drafts lists the draft (\(main.mailbox.total) messages)")
        guard let row = draftRow() else { return }
        await selectRow(row)
        await shot(main.window, "all-drafts-1-list")
        main.mailbox.openSelected()
        guard let compose = await waitCompose() else {
            check(false, "opening the draft opens the compose window")
            return
        }
        await pause(1)
        let from: NSPopUpButton? = find("compose.from", in: compose)
        let text = await editorText(compose)
        check(from?.titleOfSelectedItem?.contains("testuser@inboxclassic.test") == true
              && field("compose.subject", compose)?.stringValue == "Trip plans" && text.contains("The train leaves at nine"),
              "opening it opens the compose window from the first account, with the draft's text (\(from?.titleOfSelectedItem ?? ""): \(text))")
        await shot(compose, "all-drafts-2-open")
        await closeCompose(compose)
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
        check(ok?.title == Text.uiButtonMove.text, "the button says Move (\(ok?.title ?? ""))")
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
        if let node = treeRow({ $0.folder == otherArchive }) {
            tree.selectRowIndexes(IndexSet(integer: node), byExtendingSelection: false)
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
            let node = treeRow { $0.folder == otherArchive }.flatMap(treeNode)
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
        // and two mailing lists for it to leave, read already: one-click, signed by the list, verified by the provider
        for (index, (from, subject)) in [("Weekly Digest <digest@list.example.com>", "Weekly digest"),
                                         ("Monthly Offers <offers@list.example.com>", "Monthly offers")].enumerated() {
            try await addMessage("Authentication-Results: mx.inboxclassic.test; dkim=pass header.d=list.example.com\r\n"
                + "DKIM-Signature: v=1; d=list.example.com; s=s1; h=from:list-unsubscribe:list-unsubscribe-post; bh=x; b=y\r\n"
                + "From: \(from)\r\nTo: testuser@inboxclassic.test\r\nSubject: \(subject)\r\nDate: \(rfc2822(Date()))\r\n"
                + "Message-ID: <\(UUID().uuidString)@list.example.com>\r\n"
                + "List-Unsubscribe: <https://list.example.com/u/\(index + 1)>\r\nList-Unsubscribe-Post: List-Unsubscribe=One-Click\r\n"
                + "\r\nThis month's news.\r\n", flags: ["\\Seen"])
        }
        for (from, subject, body) in [("Maria Lopez <maria@example.org>", "Quarterly report draft", "Here is the draft of the quarterly report. Comments by Thursday?"),
                                      ("Sam Lee <sam@example.org>", "Team lunch on Friday", "Who is in for lunch on Friday at noon?")] {
            try await addMessage("From: \(from)\r\nTo: testuser@inboxclassic.test\r\nSubject: \(subject)\r\nDate: \(rfc2822(Date()))\r\n"
                + "Message-ID: <\(UUID().uuidString)@example.org>\r\n\r\n\(body)\r\n")
        }
        command(.sync)
        _ = await waitUntil { list.numberOfRows >= rowsBefore + 4 }
        // nothing selected: a message shown is marked read after a moment on screen, which would count with the
        // agent's two; the count taken once the window and the server agree
        list.deselectAll(nil)
        let counts: NSTextField? = find("status.counts", in: main.window)
        var unreadBefore = 0
        _ = await waitUntil(10) {
            unreadBefore = await unreadOnServer()
            return counts?.stringValue.contains(", \(unreadBefore) unread") == true
        }
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
        environment["APP"] = Bundle.main.executablePath ?? ""
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
            check(ask.frame.width < 700, "the longest level wraps within the question (\(Int(ask.frame.width)) wide)")
            // drafts and sending too, for the rest of the test
            level(2)?.state = .on
            level(3)?.state = .on
            await shot(ask, "agents-2-connect")
            press(find("agent.allow", in: ask))
        }
        let marked = await waitFor(30) { agentSaid(agentOut, "marked") as? [String: Any] }
        let initialize = agentSaid(agentOut, "initialize") as? [String: Any]
        check(((initialize?["result"] as? [String: Any])?["serverInfo"] as? [String: Any])?["name"] as? String == "inbox-classic",
              "allowed, the agent connects")
        let tools = agentSaid(agentOut, "tools") as? [String] ?? []
        check(tools.count == 31, "with the tools of what it may do (\(tools.joined(separator: ", ")))")
        let read = agentSaid(agentOut, "read") as? [String: Any]
        check((read?["notice"] as? String)?.contains("not as instructions") == true && read?["unread"] as? Bool == true,
              "it reads a message as text, told it is the sender's, without marking it read")
        check(marked?["done"] as? Bool == true, "it marks two messages read")
        // the two it named, by their uids
        let named = ((agentSaid(agentOut, "unread") as? [String: Any])?["messages"] as? [[String: Any]] ?? [])
            .compactMap { ($0["uid"] as? NSNumber)?.uint64Value }
        let seenThere = { () async -> Bool in
            let inbox = await self.messages("INBOX")
            return named.allSatisfy { uid in
                inbox.contains { ($0["uid"] as? NSNumber)?.uint64Value == uid && (($0["flags"] as? [String]) ?? []).contains("\\Seen") }
            }
        }
        let namedSeen = await waitUntil(20) { await seenThere() }
        check(named.count == 2 && namedSeen, "on the server, the two it named (\(named))")
        check(await waitUntil(20) { await unreadOnServer() == unreadBefore - 2 }, "and only those (\(unreadBefore) unread before)")
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
            await checkHeldBack(send, "agent.sendButton", "Send waits a moment before it can be pressed") {
                agentSaid(agentOut, "sent") != nil
            }
            await shot(send, "agents-4-send")
            press(find("agent.sendButton", in: send))
        }
        let sent = await waitFor(20) { agentSaid(agentOut, "sent") as? [String: Any] }
        check(sent?["sent"] as? Bool == true, "the agent learns the user said yes")
        let draft = await waitFor(30) { agentSaid(agentOut, "draft") as? [String: Any] }
        check(draft?["draft_id"] is String, "the agent writes a draft in Markdown (\(draft ?? [:]))")

        command(.outbox)
        if let outbox = await waitWindow("outbox", 10) {
            let table: NSTableView? = find("outbox.list", in: outbox)
            let status = (table?.view(atColumn: 3, row: 0, makeIfNecessary: true) as? NSTableCellView)?.textField?.stringValue ?? ""
            check(status.hasPrefix(lead(.uiOutboxStatusAgent)), "it waits in the Outbox, where it can still be deleted (\(status))")
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
            check(cell(hosts, 0, 0) == "My AI agent" && cell(hosts, 1, 0).hasPrefix("Read, organize, write drafts and send with your yes"),
                  "it lists the program and what it may do (\(cell(hosts, 1, 0)))")
            check(cell(log, 2, 0).hasPrefix("Saved the draft “Agenda for Friday”")
                  && cell(log, 2, 1).hasPrefix("Put “Lunch on Friday?” in the Outbox for pat@example.net")
                  && cell(log, 2, 2) == "Watched the conversation “Team lunch on Friday”"
                  && cell(log, 2, 3) == "Flagged “Quarterly report draft” blue" && cell(log, 2, 4).hasPrefix(lead(.agentLogRead)),
                  "and what its agent did, newest first, a flag's colour and a watched conversation among it "
                  + "(\((0..<5).map { cell(log, 2, $0) }.joined(separator: " | ")))")
            await shot(agents, "agents-6-window")
            if let log = log as? NSOutlineView {
                try await agentReads(agents, log)
            } else {
                check(false, "the log is an outline")
            }
            // Change opens the same form for a program let in, with what it may do now
            hosts?.selectRowIndexes([0], byExtendingSelection: false)
            press(find("agents.change", in: agents))
            if let access = await waitWindow("agent.access", 10) {
                let level = { (index: Int) -> NSButton? in self.find("agent.level.\(index)", in: access) }
                check(level(0)?.state == .on && level(1)?.state == .on && level(2)?.state == .on && level(3)?.state == .on
                      && access.frame.width < 700,
                      "Change shows what the program may do, the levels wrapped (\(Int(access.frame.width)) wide)")
                press(find("agent.cancel", in: access))
                _ = await waitUntil { !access.isVisible }
            } else {
                check(false, "Change opens the access form")
            }
            // the send, under the draft
            log?.selectRowIndexes([1], byExtendingSelection: false)
            press(find("agents.undo", in: agents))
            check(await waitUntil(10) { cell(log, 2, 1).contains("taken back") }, "Undo takes the message back")
            try await clearAgentLog(agents, log)
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
        try await agentDraft()
        try await agentUnsubscribes(agentOut)
        try await terminalAgent()
        try await agentBulk(agentOut)
    }

    /// what the agent read: one row for the program's hour, which opens to each subject and list it read, no Undo
    private func agentReads(_ agents: NSWindow, _ log: NSOutlineView) async throws {
        let cell = { (column: Int, row: Int) -> String in
            (log.view(atColumn: column, row: row, makeIfNecessary: true) as? NSTableCellView)?.textField?.stringValue ?? ""
        }
        let row = (0..<log.numberOfRows).first { cell(2, $0).hasPrefix("Read 1 message") }
        check(row != nil && cell(1, row ?? 0) == "My AI agent",
              "what the agent read is one row of its program: \(row.map { cell(2, $0) } ?? "none")")
        guard let row, let summary = log.item(atRow: row) else { return }
        check(log.isExpandable(summary) && !log.isItemExpanded(summary), "closed, with a triangle that opens it")
        log.selectRowIndexes([row], byExtendingSelection: false)
        let undo: NSButton? = find("agents.undo", in: agents)
        check(undo?.isEnabled == false, "it has no Undo")
        log.expandItem(summary)
        let reads = (row + 1..<log.numberOfRows).prefix { log.parent(forItem: log.item(atRow: $0)) as AnyObject? === summary as AnyObject }
        let said = reads.map { cell(2, $0) }
        check(said.contains("Read “Quarterly report draft”") || said.contains("Read “Team lunch on Friday”"),
              "opened, it lists each message it read by its subject (\(said.joined(separator: " | ")))")
        check(said.contains { $0.hasPrefix("Looked at") } && !said.contains { $0.contains("Comments by Thursday") || $0.contains("noon") },
              "and the lists it looked at, never what the messages say")
        check(reads.allSatisfy { cell(1, $0).isEmpty && !cell(0, $0).isEmpty }, "each read with its time, the program the summary's")
        await pause(0.5)
        await shot(agents, "agents-9-reads")
        await darkShot(agents, "agents-9-reads-dark")
        log.collapseItem(summary)
    }

    /// a picture of `window` with the app dark, then as it was
    private func darkShot(_ window: NSWindow, _ name: String) async {
        let before = NSApp.appearance
        onMain { NSApp.appearance = NSAppearance(named: .darkAqua) }
        await pause(0.5)
        await shot(window, name)
        onMain { NSApp.appearance = before }
        await pause(0.3)
    }

    /// Clear empties the log, but what the agent sent still counts against what it may send
    private func clearAgentLog(_ agents: NSWindow, _ log: NSTableView?) async throws {
        press(find("agents.clear", in: agents))
        let question = await waitWindow("alert", 10)
        check(alertText(question).contains(Text.uiClearAgentLog.text), "Clear asks first (\(alertText(question)))")
        answer(question, Text.uiClearButton.text)
        check(await waitUntil(10) { log?.numberOfRows == 0 }, "and empties the log")
        // the limit counts the agent's sends in the store's log, the cleared ones with them
        let sqlite = Process()
        sqlite.executableURL = URL(fileURLWithPath: "/usr/bin/sqlite3")
        sqlite.arguments = ["-readonly", out.appendingPathComponent("store.db").path,
                            "SELECT COUNT(*) FROM agent_log WHERE what = 'send' AND hidden = 1"]
        let found = Pipe()
        sqlite.standardOutput = found
        try sqlite.run()
        sqlite.waitUntilExit()
        let sends = String(decoding: found.fileHandleForReading.readDataToEndOfFile(), as: UTF8.self)
            .trimmingCharacters(in: .whitespacesAndNewlines)
        check(sends == "1", "the send cleared still counts against the agent's limit (\(sends))")
    }

    /// starts an agent's relay from a program called Terminal, as an agent started by hand in a terminal is; the
    /// question it raises when its program is not known yet
    func terminalAgentAsks() async throws -> NSWindow? {
        let terminal = out.appendingPathComponent("Terminal")
        if !FileManager.default.fileExists(atPath: terminal.path) {
            try FileManager.default.copyItem(at: out.appendingPathComponent("My AI agent"), to: terminal)
        }
        // only as far as the hello: the question comes as it connects
        let script = """
            const relay = require('node:child_process').spawn(process.env.APP, ['--mcp', '--store', process.env.STORE], { stdio: ['pipe', 'inherit', 'inherit'] });
            relay.stdin.write(JSON.stringify({ jsonrpc: '2.0', id: 1, method: 'initialize', params: { protocolVersion: '2025-06-18', capabilities: {}, clientInfo: { name: 'terminal', version: '1' } } }) + '\\n');
            setTimeout(() => relay.kill(), 60000);
            """
        let agent = Process()
        agent.executableURL = terminal
        agent.arguments = ["-e", script]
        var environment = ProcessInfo.processInfo.environment
        environment["APP"] = Bundle.main.executablePath ?? ""
        environment["STORE"] = out.appendingPathComponent("store.db").path
        agent.environment = environment
        agent.standardOutput = FileHandle.nullDevice
        try agent.run()
        terminalAgents.append(agent)
        return await waitWindow("agent.connect", 30)
    }

    /// the program called Terminal turned away and forgotten, so it is asked about again
    func forgetTerminal() {
        for agent in terminalAgents where agent.isRunning {
            agent.terminate()
        }
        terminalAgents = []
        if let list = pe_agent_hosts(main.core.handle) {
            defer { pe_agent_host_list_free(list) }
            for index in 0..<pe_agent_host_list_count(list) {
                if let host = pe_agent_host_list_get(list, index)?.pointee, text(host.path).hasSuffix("/Terminal") {
                    pe_agent_host_remove(main.core.handle, host.id)
                }
            }
        }
    }

    /// every label of a question in full: one line wide enough, a wrapped one tall enough, and the window on the screen
    func checkQuestionFits(_ ask: NSWindow, _ what: String) {
        ask.contentView?.layoutSubtreeIfNeeded()
        var cut: [String] = []
        // a path is shortened in the middle on purpose, whole in its tooltip
        for label in views(NSTextField.self, in: ask.contentView)
        where !label.stringValue.isEmpty && !label.isHiddenOrHasHiddenAncestor && label.lineBreakMode != .byTruncatingMiddle {
            let wraps = label.cell?.wraps == true || label.maximumNumberOfLines != 1
            let needed = wraps ? label.cell?.cellSize(forBounds: NSRect(x: 0, y: 0, width: label.bounds.width, height: .greatestFiniteMagnitude))
                .height ?? 0 : label.intrinsicContentSize.width
            if needed > (wraps ? label.bounds.height : label.bounds.width) + 1 {
                cut.append(label.stringValue)
            }
        }
        let screen = ask.screen?.visibleFrame ?? .infinite
        check(cut.isEmpty && screen.contains(ask.frame), "\(what): nothing is cut off and it fits the screen \(cut)")
    }

    /// an agent started from a terminal: the question names the programs started from Terminal, which share what is
    /// allowed, and how one gets an access of its own (--name)
    private func terminalAgent() async throws {
        step("an AI agent started from a terminal")
        _ = await waitUntil(10) { NSApp.modalWindow == nil }
        let ask = try await terminalAgentAsks()
        check(ask != nil, "an agent started from a terminal is asked about")
        guard let ask else { return }
        let label = { (id: String) -> String in (self.find(id, in: ask) as NSTextField?)?.stringValue ?? "" }
        let heading = label("agent.heading")
        check(heading == "Programs started from Terminal want to use your mail", "as the programs started from Terminal (\(heading))")
        let words = views(NSTextField.self, in: ask.contentView).map(\.stringValue)
        check(words.contains { $0.hasPrefix(lead(.agentConnectTerminalDetail)) && $0.contains("--name") },
              "which share what is allowed, and --name gives one an access of its own")
        checkQuestionFits(ask, "the question")
        onMain {
            NSApp.activate()
            ask.makeKeyAndOrderFront(nil)
        }
        await pause(1)
        await shot(ask, "agents-10-terminal")
        await darkShot(ask, "agents-10-terminal-dark")
        press(find("agent.deny", in: ask))
        _ = await waitUntil(10) { !ask.isVisible }
        command(.aiAgents)
        if let agents = await waitWindow("agents", 10) {
            let hosts: NSTableView? = find("agents.hosts", in: agents)
            let names = (0..<(hosts?.numberOfRows ?? 0)).map {
                (hosts?.view(atColumn: 0, row: $0, makeIfNecessary: true) as? NSTableCellView)?.textField?.stringValue ?? ""
            }
            check(names.contains("Programs started from Terminal"), "the list of programs names them so (\(names))")
            NSApp.stopModal()
            _ = await waitUntil { !agents.isVisible }
        } else {
            check(false, "Tools > AI Agents opens")
        }
        forgetTerminal()
    }

    /// an invitation answered through the Send question, without Edit First; a change of many messages, one row of
    /// the log, taken back by the agent and then, made again, by Undo Since
    private func agentBulk(_ agentOut: URL) async throws {
        step("an AI agent changes many messages and answers an invitation")
        _ = await waitUntil(10) { NSApp.modalWindow == nil }
        selectFolder(named: "Inbox")
        // older than what the steps after this pick from the top of the Inbox
        let twoDaysAgo = Date().addingTimeInterval(-2 * 86400)
        for index in 1...2 {
            try await addMessage("From: Club News <news@club.example.com>\r\nTo: testuser@inboxclassic.test\r\n"
                + "Subject: Club newsletter \(index)\r\nDate: \(rfc2822(twoDaysAgo))\r\nMessage-ID: <\(UUID().uuidString)@club.example.com>\r\n"
                + "\r\nThis week at the club.\r\n")
        }
        try await addMessage("From: Ann Example <ann@example.com>\r\nTo: testuser@inboxclassic.test\r\nSubject: Invitation: Roadmap review\r\n"
            + "Date: \(rfc2822(twoDaysAgo))\r\nMessage-ID: <roadmap-review@example.com>\r\n"
            + "Content-Type: multipart/mixed; boundary=inv\r\n\r\n--inv\r\nContent-Type: text/plain\r\n\r\nLet us plan.\r\n"
            + "--inv\r\nContent-Type: text/calendar; method=REQUEST; charset=utf-8\r\n\r\n"
            + "BEGIN:VCALENDAR\r\nMETHOD:REQUEST\r\nBEGIN:VEVENT\r\nUID:roadmap-review@example.com\r\nSUMMARY:Roadmap review\r\n"
            + "DTSTART:20261210T100000Z\r\nDTEND:20261210T110000Z\r\nORGANIZER;CN=Ann Example:mailto:ann@example.com\r\n"
            + "ATTENDEE;CN=Test;RSVP=TRUE;PARTSTAT=NEEDS-ACTION:mailto:testuser@inboxclassic.test\r\nEND:VEVENT\r\nEND:VCALENDAR\r\n--inv--\r\n",
            flags: ["\\Seen"])
        command(.sync)
        _ = await waitFor(30) { await findMessage("INBOX", "Subject: Invitation: Roadmap review") }
        check(await waitUntil(30) {
            (0..<self.list.numberOfRows).filter { self.main.mailbox.row($0)?.subject.hasPrefix("Club newsletter") == true }.count == 2
                && (0..<self.list.numberOfRows).contains { self.main.mailbox.row($0)?.subject == "Invitation: Roadmap review" }
        }, "the two newsletters and the invitation are in the Inbox")
        // asked twice: the first answered with Return, the second with Send
        try Data().write(to: URL(fileURLWithPath: agentOut.path + ".invitation-twice"))
        try Data().write(to: URL(fileURLWithPath: agentOut.path + ".bulk"))

        // the invitation's answer: what it answers above the text, Send and Don't Send only
        let send = await waitWindow("agent.send", 30)
        check(send != nil, "the agent's answer to the invitation is shown to the user first")
        if let send {
            await checkHeldBack(send, "agent.sendButton", "Send waits a moment before it can be pressed") {
                agentSaid(agentOut, "invitation-first") != nil
            }
            let line: NSTextField? = find("agent.invitation", in: send)
            check(line?.stringValue.hasPrefix("This message accepts the invitation “Roadmap review”") == true
                  && line?.stringValue.contains("changes only once the message has been sent") == true,
                  "the Send question says what it answers, above the text (\(line?.stringValue ?? "none"))")
            let compose: NSButton? = find("agent.compose", in: send)
            let dont: NSButton? = find("agent.dontSend", in: send)
            check(compose == nil && dont != nil, "it has no Edit First")
            checkQuestionFits(send, "the invitation's Send question")
            onMain { self.bringToFront(send) }
            await shot(send, "agents-13-invitation")
            await darkShot(send, "agents-13-invitation-dark")
            // Return, with Send on: the safe answer, Don't Send, is what it gives
            pressKey(send, 36)
            let first = await waitFor(20) { agentSaid(agentOut, "invitation-first") as? [String: Any] }
            check(first?["status"] as? String == "not_sent" && !send.isVisible,
                  "Don't Send is the default: Return answers it, and the agent learns it was not sent (\(first ?? [:]))")
        }
        // asked again, answered Send
        let secondAsk = await waitFor(30) { self.window("agent.send").flatMap { $0 === send ? nil : $0 } }
        check(secondAsk != nil, "the agent asks again")
        if let secondAsk {
            let button: NSButton? = find("agent.sendButton", in: secondAsk)
            _ = await waitUntil(10) { button?.isEnabled == true }
            press(button)
        }
        let answered = await waitFor(30) { agentSaid(agentOut, "invitation") as? [String: Any] }
        check(answered?["status"] as? String == "sent", "the agent learns it was sent (\(answered ?? [:]))")
        let status = await waitFor(10) { agentSaid(agentOut, "invitation-status") as? [String: Any] }
        check(status?["your_status"] as? String != "accepted" && (status?["summary"] as? String)?.contains("Roadmap review") == true,
              "the invitation's status is unchanged while its answer waits (\(status ?? [:]))")

        // the change of many messages: counted first, done with the token, taken back, done again
        let preview = await waitFor(30) { agentSaid(agentOut, "bulk-preview") as? [String: Any] }
        check(preview?["matches"] as? Int == 2 && preview?["token"] is String, "the dry run counts the two newsletters (\(preview ?? [:]))")
        let undone = await waitFor(30) { agentSaid(agentOut, "bulk-undone") as? [String: Any] }
        check(undone?["messages_taken_back"] as? Int == 2, "the agent takes its change of both back (\(undone ?? [:]))")
        let again = await waitFor(30) { agentSaid(agentOut, "bulk-again") as? [String: Any] }
        check(again?["change_id"] is Int, "and makes it again (\(again ?? [:]))")
        check(await waitUntil(20) {
            let first = await self.seen("Subject: Club newsletter 1")
            let second = await self.seen("Subject: Club newsletter 2")
            return first && second
        },
              "both newsletters are read on the server")
        check(agentSaid(agentOut, "error") == nil, "the agent ran without an error (\(agentSaid(agentOut, "error") ?? ""))")
        // one of them marked unread by the user since: Undo Since leaves it as it is, and says so
        let first = (0..<list.numberOfRows).first { self.main.mailbox.row($0)?.subject == "Club newsletter 1" }
        check(first != nil, "the newsletter is listed")
        await selectRow(first ?? 0)
        command(.markUnread)
        check(await waitUntil(20) { !(await self.seen("Subject: Club newsletter 1")) }, "the user marks one of them unread")

        command(.aiAgents)
        guard let agents = await waitWindow("agents", 10) else {
            check(false, "Tools > AI Agents opens")
            return
        }
        let hosts: NSTableView? = find("agents.hosts", in: agents)
        let log: NSTableView? = find("agents.log", in: agents)
        let cell = { (table: NSTableView?, column: Int, row: Int) -> String in
            (table?.view(atColumn: column, row: row, makeIfNecessary: true) as? NSTableCellView)?.textField?.stringValue ?? ""
        }
        let bulkRow = "Marked 2 messages read (search: subject:\"Club newsletter\")"
        let rows = (0..<(log?.numberOfRows ?? 0)).map { cell(log, 2, $0) }
        check(rows.first == bulkRow && rows.filter { $0.hasPrefix("Marked 2 messages read") }.count == 2,
              "each change of the newsletters is one row of the log (\(rows.prefix(4).joined(separator: " | ")))")
        log?.selectRowIndexes([0], byExtendingSelection: false)
        let undo: NSButton? = find("agents.undo", in: agents)
        check(undo?.isEnabled == true, "with one Undo")
        await pause(0.5)
        await shot(agents, "agents-11-bulk")

        let program = (0..<(hosts?.numberOfRows ?? 0)).first { cell(hosts, 0, $0) == "My AI agent" }
        check(program != nil, "the program is listed")
        hosts?.deselectAll(nil)
        let undoSince: NSButton? = find("agents.undoSince", in: agents)
        check(undoSince?.isEnabled == false, "Undo Since is off with no program selected")
        hosts?.selectRowIndexes([program ?? 0], byExtendingSelection: false)
        check(undoSince?.isEnabled == true, "and on with one")
        press(undoSince)
        guard let ask = await waitWindow("agents.undoSinceWindow", 10) else {
            check(false, "Undo Since asks first")
            NSApp.stopModal()
            return
        }
        let span: NSPopUpButton? = find("undoSince.span", in: ask)
        let heading = { (self.find("undoSince.heading", in: ask) as NSTextField?)?.stringValue ?? "" }
        let takeBack: NSButton? = find("undoSince.takeBack", in: ask)
        let cancel: NSButton? = find("undoSince.cancel", in: ask)
        let words = views(NSTextField.self, in: ask.contentView).map(\.stringValue)
        check(words.contains("Take back what this program did:") && span?.numberOfItems == 6
              && span?.itemTitles.first == "In the last 15 minutes" && span?.indexOfSelectedItem == 0,
              "it asks what to take back over six spans, the last 15 minutes first (\(span?.itemTitles ?? []))")
        choose(span, 1)
        let asked = heading()
        check(asked.range(of: "^Take back the \\d+ changes My AI agent made in this time\\?$", options: .regularExpression) != nil,
              "a span picked, it asks with the count of the changes (\(asked))")
        check(takeBack?.isHidden == false && takeBack?.hasDestructiveAction == true && cancel?.title == Text.uiCancel.text,
              "Take Back is marked destructive, beside Cancel")
        checkQuestionFits(ask, "Undo Since")
        await shot(ask, "agents-12-undo-since")
        await darkShot(ask, "agents-12-undo-since-dark")
        // Esc and Return answer Cancel: nothing is taken back
        for key: UInt16 in [53, 36] {
            let name = key == 53 ? "Esc" : "Return"
            if key == 36 {
                press(undoSince)
                guard let reopened = await waitWindow("agents.undoSinceWindow", 10) else {
                    check(false, "Undo Since asks again")
                    break
                }
                choose(find("undoSince.span", in: reopened), 1)
                pressKey(reopened, key)
                _ = await waitUntil(5) { !reopened.isVisible }
            } else {
                pressKey(ask, key)
                _ = await waitUntil(5) { !ask.isVisible }
            }
            let takenBack = await waitUntil(2) { cell(log, 2, 0).contains("taken back") }
            let stillRead = await self.seen("Subject: Club newsletter 2")
            check(window("agents.undoSinceWindow") == nil && !takenBack && stillRead,
                  "\(name) answers Cancel: the question closes and nothing is taken back (\(cell(log, 2, 0)))")
        }
        // asked again, and Take Back pressed
        press(undoSince)
        guard let confirm = await waitWindow("agents.undoSinceWindow", 10) else {
            check(false, "Undo Since asks again")
            NSApp.stopModal()
            return
        }
        choose(find("undoSince.span", in: confirm), 1)
        press(find("undoSince.takeBack", in: confirm))
        let report = await waitWindow("alert", 10)
        let said = alertText(report)
        check(said.range(of: "Took back \\d+ changes", options: .regularExpression) != nil
              && said.contains("1 message was changed since, by you or on the server, and was left as it is."),
              "Take Back says what it took back and what it left (\(said))")
        answer(report, Text.uiOk.text)
        check(await waitUntil(20) {
            let first = await self.seen("Subject: Club newsletter 1")
            let second = await self.seen("Subject: Club newsletter 2")
            return !first && !second
        },
              "the newsletters are unread again on the server")
        check(await waitUntil(10) { cell(log, 2, 0).hasPrefix(bulkRow) && cell(log, 2, 0).contains("taken back") && undo?.isEnabled == false },
              "the log shows the change taken back (\(cell(log, 2, 0)))")
        // nothing left in the span: Close alone
        press(undoSince)
        if let empty = await waitWindow("agents.undoSinceWindow", 10) {
            let nothing = (find("undoSince.heading", in: empty) as NSTextField?)?.stringValue ?? ""
            let takeBack: NSButton? = find("undoSince.takeBack", in: empty)
            let close: NSButton? = find("undoSince.cancel", in: empty)
            check(nothing == "My AI agent made no changes in this time that can be taken back." && takeBack?.isHidden == true
                  && close?.title == "Close", "with nothing left to take back it says so and offers only Close (\(nothing))")
            press(close)
            _ = await waitUntil { !empty.isVisible }
        }
        NSApp.stopModal()
        _ = await waitUntil { !agents.isVisible }
    }

    /// the draft the agent wrote, opened from Drafts: the window names the agent, its Markdown made into formatting
    private func agentDraft() async throws {
        step("an AI agent's draft")
        _ = await waitUntil(10) { NSApp.modalWindow == nil }
        selectFolder(named: "Drafts")
        command(.sync)
        let row = await waitFor(30) {
            (0..<self.list.numberOfRows).first { self.main.mailbox.row($0)?.subject == "Agenda for Friday" }
        }
        check(row != nil, "the agent's draft is in Drafts")
        guard let row else { return }
        await selectRow(row)
        main.mailbox.openSelected()
        guard let compose = await waitFor(20, { ComposeWindow.open.last.flatMap { $0.window.title == "Agenda for Friday" ? $0.window : nil } })
        else { throw Failed(description: "the agent's draft did not open") }
        let note: NSTextField? = find("compose.agentNote", in: compose)
        let said = note?.stringValue ?? ""
        check(said == Text.agentDraftNote.text(["program": "My AI agent"])
              && note?.isHiddenOrHasHiddenAncestor == false,
              "opened, it says which agent wrote it and asks to check the recipients and the text (\(said))")
        // window coordinates, which grow upwards
        let noteBox = note.map { $0.convert($0.bounds, to: nil) }
        let subjectBox = field("compose.subject", compose).map { $0.convert($0.bounds, to: nil) }
        check(noteBox != nil && subjectBox != nil && noteBox!.maxY <= subjectBox!.minY, "between the fields and the message")
        let editor: EditorView? = views(EditorView.self, in: compose.contentView).first
        var body = ""
        _ = await waitUntil(10) {
            body = (try? await editor?.evaluateJavaScript("document.getElementById('body').innerHTML")) as? String ?? ""
            return body.contains("Agenda")
        }
        check(body.range(of: "<(strong|b)>Agenda</(strong|b)>", options: .regularExpression) != nil
              && body.contains("<li>lunch</li>") && body.contains("<ul>"),
              "its Markdown is formatted (\(body))")
        await pause(1)
        await shot(compose, "agents-8-draft")
        // closed without saving: the draft stays the agent's
        await closeCompose(compose)
        check(await findMessage("Drafts", "Subject: Agenda for Friday") != nil, "closed without saving, the draft stays in Drafts")
        selectFolder(named: "Inbox")
    }

    /// the agent asks to leave two mailing lists, in one question, and hears the user's no
    private func agentUnsubscribes(_ agentOut: URL) async throws {
        _ = await waitUntil(10) { NSApp.modalWindow == nil }
        try Data().write(to: URL(fileURLWithPath: agentOut.path + ".unsubscribe"))
        let ask = await waitWindow("agent.unsubscribe", 30)
        check(ask != nil, "the agent asks to unsubscribe from two mailing lists")
        guard let ask else { return }
        let label = { (id: String) -> String in (self.find(id, in: ask) as NSTextField?)?.stringValue ?? "" }
        let heading = label("agent.heading")
        check(heading.contains("My AI agent") && heading.contains("2"), "the question names the program and the number of lists (\(heading))")
        let senders = [0, 1].map { "\(label("agent.list.\($0)")) | \(label("agent.list.\($0).name"))" }
        check(Set(senders) == ["digest@list.example.com | Weekly Digest", "offers@list.example.com | Monthly Offers"]
              && label("agent.list.0.target") == "→ list.example.com" && label("agent.list.1.target") == "→ list.example.com",
              "one question lists both senders and where the requests go, each address first and whole, the name apart (\(senders))")
        await checkHeldBack(ask, "agent.unsubscribe", "Unsubscribe waits a moment before it can be pressed") {
            agentSaid(agentOut, "unsubscribe") != nil
        }
        // as the user comes to it: the app in front, the question key
        onMain {
            NSApp.activate()
            ask.makeKeyAndOrderFront(nil)
        }
        _ = await waitUntil(5) { ask.isKeyWindow }
        await shot(ask, "agents-7-unsubscribe")
        // Return, with Unsubscribe on: the safe answer, Don't Unsubscribe, is what it gives
        pressKey(ask, 36)
        let said = await waitFor(20) { agentSaid(agentOut, "unsubscribe") as? [String: Any] }
        check(said?["unsubscribed"] as? Bool == false && !ask.isVisible,
              "Don’t Unsubscribe is the default: Return answers no, and the agent learns the user said no")
        command(.aiAgents)
        if let agents = await waitWindow("agents", 10) {
            let log: NSTableView? = find("agents.log", in: agents)
            let cell = { (log?.view(atColumn: 2, row: 0, makeIfNecessary: true) as? NSTableCellView)?.textField?.stringValue ?? "" }
            _ = await waitUntil(10) { cell().hasPrefix(lead(.agentLogUnsubscribeRefused)) }
            let first = cell()
            check(first.hasPrefix(lead(.agentLogUnsubscribeRefused)) && first.contains("digest@list.example.com"),
                  "and the AI Agents window says no list was asked (\(first))")
            NSApp.stopModal()
            _ = await waitUntil { !agents.isVisible }
        } else {
            check(false, "Tools > AI Agents opens")
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
        check(person.title == Text.uiNewContactTitle.text, "New Contact opens Contact Properties (\(person.title))")
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
        // typed: the book is searched once the typing pauses, not at each key
        book.searchField.stringValue = "zed"
        _ = book.searchField.sendAction(book.searchField.action, to: book.searchField.target)
        check(book.rows.count == 1, "a key typed into the find box does not search at once")
        check(await waitUntil(5) { book.rows.isEmpty } && (find("book.empty", in: bookWindow) as NSTextField?)?.stringValue.contains("zed") == true,
              "and lists no one for \"zed\" a moment after the typing")
        book.find("")

        // a group of her and a typed address
        onMain { book.newGroup() }
        guard let groupSheet = await waitWindow("group", 10) else { throw Failed(description: "no Group Properties") }
        check(groupSheet.title == Text.uiNewGroupTitle.text, "New Group opens Group Properties")
        type("Team", into: find("group.name", in: groupSheet))
        press(find("group.select", in: groupSheet))
        guard let members = await waitWindow("pick", 10) else { throw Failed(description: "no Select Group Members") }
        check(members.title == Text.uiSelectMembers.text, "Select Members opens the book's people")
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
        check(picker.title == Text.uiSelectRecipients.text, "To opens Select Recipients")
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
        _ = await waitUntil { !main.mailbox.listLoading && list.numberOfRows > 0 }
        let senderRow = (0..<list.numberOfRows).first { main.mailbox.row($0)?.subject == "October newsletter" }
            ?? (0..<list.numberOfRows).first { !(main.mailbox.row($0)?.fromAddress ?? "").isEmpty } ?? 0
        await selectRow(senderRow)
        let sender = main.mailbox.row(senderRow)
        let senderName = sender?.from ?? ""
        let senderAddress = sender?.fromAddress ?? ""
        let rightClick = main.mailbox.messageMenu()?.items.map(\.title) ?? []
        check(rightClick.contains(Command.addSenderToBook.label), "the message list's right-click menu has Add Sender to Address Book")
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
        answer(imported, Text.uiOk.text)
        TestHooks.open = nil
        _ = await waitUntil(5) { window("alert") == nil }
        command(.addressBook)
        _ = await waitUntil(5) { bookWindow.isVisible }
        onMain { book.groupList.selectRowIndexes(IndexSet(integer: 0), byExtendingSelection: false) }
        _ = await waitUntil(5) { self.bookNames(book).contains("John Doe") }
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
        answer(exportSaid, Text.uiOk.text)
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

extension UITest {
    // ---- the help ----

    /// The help, a Help Book Help Viewer shows: the test can not drive Help Viewer, so it checks what the app asks it
    /// for (the topic of the main window for Help, a dialog's own for its help button), that the bundle has the book in
    /// each language with the pages of those topics and a search index, and takes pictures of two of its pages
    func helpBook() async throws {
        step("the help")
        var asked: [String] = []
        TestHooks.help = { asked.append($0) }
        defer { TestHooks.help = nil }
        onMain { self.main.window.makeKeyAndOrderFront(nil) }
        await pause(0.3)
        command(.help)
        check(await waitUntil(5) { asked == ["main-window"] }, "Help asks Help Viewer for the main window's topic (\(asked))")
        command(.options)
        if let settings = await waitWindow("settings", 10) {
            let button: HelpButton? = find("help.options", in: settings)
            check(button?.bezelStyle == .helpButton, "Settings has the round help button")
            press(button)
            check(await waitUntil(5) { asked.last == "options-language" }, "which opens the topic of Settings (\(asked))")
            onMain { settings.close() }
        } else {
            check(false, "Settings opens")
        }

        let info = Bundle.main.infoDictionary ?? [:]
        let folder = info["CFBundleHelpBookFolder"] as? String ?? ""
        let book = Bundle.main.resourceURL?.appendingPathComponent(folder)
        let bookInfo = book.flatMap { NSDictionary(contentsOf: $0.appendingPathComponent("Contents/Info.plist")) }
        check(folder == "InboxClassic.help" && bookInfo?["CFBundleIdentifier"] as? String == info["CFBundleHelpBookName"] as? String
              && bookInfo?["HPDBookAccessPath"] as? String == "index.html",
              "Info.plist names the Help Book in the bundle (\(folder))")
        // the topics the app opens: the main window's and each window's own
        let anchors = Set((["main"] + Help.contexts.values).compactMap { taken(pe_help_context($0)) })
        for (code, _) in Languages.all {
            guard let pages = book?.appendingPathComponent("Contents/Resources/\(code).lproj") else { continue }
            let missing = (["index", "find-messages"] + anchors).filter {
                !FileManager.default.fileExists(atPath: pages.appendingPathComponent("\($0).html").path)
            }
            let index = (try? pages.appendingPathComponent("InboxClassic.cshelpindex").resourceValues(forKeys: [.fileSizeKey]))?.fileSize ?? 0
            check(missing.isEmpty && index > 0, "the help in \(code): its contents, the topics the app opens and a search index"
                  + (missing.isEmpty ? "" : " (missing \(missing.joined(separator: ", ")))"))
        }

        // two of its pages as Help Viewer shows them, in a web view of the test's own
        guard let pages = book?.appendingPathComponent("Contents/Resources/en.lproj") else { return }
        let window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 720, height: 640), styleMask: [.titled, .closable],
                              backing: .buffered, defer: false)
        window.isReleasedWhenClosed = false
        let web = WKWebView(frame: .zero)
        window.contentView = web
        window.center()
        window.makeKeyAndOrderFront(nil)
        for (page, name) in [("index", "help-2-contents"), ("find-messages", "help-4-topic")] {
            window.title = page + ".html"
            web.loadFileURL(pages.appendingPathComponent(page + ".html"), allowingReadAccessTo: pages)
            check(await waitUntil(10) { !web.isLoading && web.url?.lastPathComponent == page + ".html" }, "the help's \(page).html loads")
            await pause(0.5)
            await shot(window, name)
        }
        window.close()
    }
}
