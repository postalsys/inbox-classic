// The UI end-to-end test's steps of the list's Unread filter, the pictures of trusted senders (and of every message)
// and a message file opened from the Finder: the same scenario as the other platforms' (scripts/ui-e2e/SCENARIO.md).
import AppKit
import CInboxClassic

extension UITest {
    /// the subjects of the list's rows
    func listedSubjects() -> [String] {
        (0..<list.numberOfRows).compactMap { main.mailbox.row($0)?.subject }
    }

    /// the row of the message with `subject`, -1 when it is not listed
    func listedRow(_ subject: String) -> Int {
        listedSubjects().firstIndex(of: subject) ?? -1
    }

    /// the main window's toolbar button `id`, pressed as a click does
    func pressToolbar(_ id: String) {
        guard let item = main.window.toolbar?.items.first(where: { $0.itemIdentifier.rawValue == id }), let action = item.action
        else {
            check(false, "the toolbar has \(id)")
            return
        }
        onMain { NSApp.sendAction(action, to: item.target, from: item) }
    }

    // ---- unread only ----

    func unreadOnly() async throws {
        step("unread messages only")
        selectFolder(named: "Inbox")
        _ = await waitUntil { list.numberOfRows >= 3 }
        for (subject, id) in [("Unread filter check", "filter-one"), ("Another unread one", "filter-two")] {
            try await addMessage("From: Ann Example <ann@example.com>\r\nTo: testuser@inboxclassic.test\r\nSubject: \(subject)\r\n"
                + "Date: \(rfc2822(Date()))\r\nMessage-ID: <\(id)@example.com>\r\n\r\nStill unread.\r\n")
        }
        command(.sync)
        check(await waitUntil(30) { listedRow("Unread filter check") >= 0 && listedRow("Another unread one") >= 0 },
              "two unread messages are in the Inbox")
        let all = list.numberOfRows
        check(listedSubjects().contains { subject in main.mailbox.row(listedRow(subject))?.seen == true },
              "with messages already read")

        pressToolbar("unreadOnly")
        check(await waitUntil(10) { AppDelegate.shared.hideRead && menuItem(.hideRead)?.state == .on },
              "the toolbar's Unread filter turns on View > Hide Read Messages")
        check(await waitUntil(10) {
            let rows = (0..<list.numberOfRows).compactMap { main.mailbox.row($0) }
            return !rows.isEmpty && rows.allSatisfy { !$0.seen } && rows.count < all
        }, "the list shows only the unread messages (\(list.numberOfRows) of \(all))")
        let item = main.window.toolbar?.items.first { $0.itemIdentifier.rawValue == "unreadOnly" }
        check(item?.label == "Unread", "the filter button is labelled Unread (\(item?.label ?? ""))")

        let read = listedRow("Unread filter check")
        await selectRow(read)
        check(await waitUntil(20) { await seen("Subject: Unread filter check") }, "a message shown is marked read")
        check(listedRow("Unread filter check") >= 0, "and stays in the list while the folder is shown")
        await shot(main.window, "list-unread-only")

        selectFolder(named: "Sent Items")
        let empty: NSStackView? = find("list.empty", in: main.window)
        let emptyTitle = { (empty?.arrangedSubviews.first as? NSTextField)?.stringValue ?? "" }
        check(await waitUntil(10) { list.numberOfRows == 0 && emptyTitle() == Text.uiNoUnread.text },
              "a folder without unread messages says so (\(emptyTitle()))")
        selectFolder(named: "Inbox")
        check(await waitUntil(10) { listedRow("Unread filter check") < 0 && listedRow("Another unread one") >= 0 },
              "back in the Inbox, the message read is gone and the unread one is still there")

        command(.hideRead)
        check(await waitUntil(10) { !AppDelegate.shared.hideRead && list.numberOfRows == all },
              "turned off, the list shows every message again (\(list.numberOfRows) of \(all))")
    }

    // ---- the folder list ----

    func folderList() async throws {
        step("the folder list hidden and shown again")
        let pane = { self.tree.enclosingScrollView }
        check(AppDelegate.shared.folderList && pane()?.isHidden == false && menuItem(.folderList)?.state == .on,
              "the folder list starts beside the messages, View > Folder List checked")
        command(.folderList)
        check(await waitUntil(10) { pane()?.isHidden == true && !AppDelegate.shared.folderList },
              "View > Folder List hides it")
        check(menuItem(.folderList)?.state == .off, "and the menu item is no longer checked")
        check(await waitUntil(5) { list.convert(list.bounds, to: nil).minX < 40 },
              "the messages and the reading pane take the width")
        await shot(main.window, "layout-3-folders-hidden")
        selectFolder(named: "Sent Items")
        check(await waitUntil(10) { main.mailbox.selectedName == "Sent Items" }, "a folder is still chosen while it is hidden")
        selectFolder(named: "Inbox")
        pressToolbar("folderList")
        check(await waitUntil(10) { pane()?.isHidden == false && AppDelegate.shared.folderList && (pane()?.frame.width ?? 0) >= 160 },
              "the toolbar's sidebar button shows it again, at its width")
    }

    // ---- the column layout ----

    /// the cell of the column layout's row `index`
    func rowCell(_ index: Int) -> MessageRowCell? {
        list.view(atColumn: 0, row: index, makeIfNecessary: true) as? MessageRowCell
    }

    /// the words of the "Sorted by" pull-down over the column layout's list
    func sortedBy() -> String {
        (find("list.sortBy", in: main.window) as NSPopUpButton?)?.item(at: 0)?.title ?? ""
    }

    func columnLayout() async throws {
        step("the column layout")
        selectFolder(named: "Inbox")
        _ = await waitUntil { list.numberOfRows > 0 }
        await selectRow(0)
        command(.layoutColumns)
        check(await waitUntil(10) { main.mailbox.layout == PE_LAYOUT_COLUMNS }, "View > Layout > Columns shows the column layout")
        check(menuItem(.layoutColumns)?.state == .on && menuItem(.layoutAutomatic)?.state == .off,
              "and Columns is checked in View > Layout")
        let readerLeft = main.mailbox.reader.view.convert(main.mailbox.reader.view.bounds, to: nil).minX
        let listRight = list.convert(list.bounds, to: nil).maxX
        check(readerLeft >= listRight - 1, "the list is beside the reading pane (\(listRight), \(readerLeft))")
        check(list.headerView == nil && list.rowHeight >= 50 && list.numberOfColumns == 1,
              "the list has one column of rows three lines high, without headings")
        check(list.selectedRow == 0, "the message selected stays selected")
        // the first words of a message, read by the core when its text was fetched for the search
        let withWords = await waitFor(20) {
            (0..<list.numberOfRows).first { main.mailbox.row($0)?.snippet.isEmpty == false }
        }
        if let withWords, let message = main.mailbox.row(withWords) {
            let said = rowCell(withWords)?.accessibilityLabel() ?? ""
            check(said.contains(message.snippet) && said.contains(message.subject),
                  "a row shows its sender, subject and first words (\(said))")
        } else {
            check(false, "a row has the first words of its message")
        }
        check(sortedBy() == "Sorted by Date", "over the list: \(sortedBy())")
        // one unread, so the screenshot shows the dot and the bold subject; read again after
        command(.markUnread)
        check(await waitUntil(10) {
            main.mailbox.row(0)?.bold == true && rowCell(0)?.unreadShown == true
                && rowCell(0)?.accessibilityLabel()?.hasPrefix(Text.uiRowUnread.text) == true
        }, "an unread row has its dot and its subject in bold, and says Unread first")
        await shot(main.window, "layout-1-columns")
        command(.markRead)
        check(await waitUntil(10) { main.mailbox.row(0)?.bold == false && rowCell(0)?.unreadShown == false },
              "read again, the dot goes and the subject is regular")

        step("sorting the column layout")
        command(.sortSubject)
        let subjects = { (0..<min(4, self.list.numberOfRows)).compactMap { self.main.mailbox.row($0)?.subject.lowercased() } }
        check(await waitUntil(10) { sortedBy() == "Sorted by Subject" }, "View > Sort By > Subject: \(sortedBy())")
        check(subjects() == subjects().sorted() && menuItem(.sortAscending)?.state == .on,
              "the list is in the order of its subjects, A to Z (\(subjects()))")
        await shot(main.window, "layout-4-sort")
        command(.sortDate)
        check(await waitUntil(10) { sortedBy() == "Sorted by Date" } && menuItem(.sortDescending)?.state == .on,
              "back to Date, the newest first")

        step("a conversation in the column layout")
        let opener = await waitFor(10) { (0..<list.numberOfRows).first { main.mailbox.row($0)?.opens == true } }
        if let opener, let cell = rowCell(opener) {
            onMain { cell.disclosure.performClick(nil) }
            check(await waitUntil(10) { main.mailbox.row(opener + 1)?.threadDepth == 1 },
                  "its triangle opens the conversation, the messages under it")
            await selectRow(opener + 1)
            await shot(main.window, "layout-5-conversation")
            if let cell = rowCell(opener) {
                onMain { cell.disclosure.performClick(nil) }
            }
            check(await waitUntil(10) { main.mailbox.row(opener + 1)?.threadDepth != 1 }, "and closes it again")
        } else {
            check(false, "the Inbox has a conversation")
        }

        step("the layout by the window's width")
        command(.layoutAutomatic)
        let status: NSTextField? = find("status.text", in: main.window)
        onMain { self.main.window.setContentSize(NSSize(width: 1100, height: 720)) }
        check(await waitUntil(10) { main.mailbox.layout == PE_LAYOUT_CLASSIC }, "Automatic in a window 1100 wide: Classic")
        onMain { self.main.window.setContentSize(NSSize(width: 1500, height: 720)) }
        check(await waitUntil(10) { main.mailbox.layout == PE_LAYOUT_COLUMNS }, "1500 wide: Columns")
        check(status?.stringValue == Text.uiColumnsNote.text, "the status bar says where to change it (\(status?.stringValue ?? ""))")
        await shot(main.window, "layout-2-automatic")
        onMain { self.main.window.setContentSize(NSSize(width: 1250, height: 720)) }
        await pause(0.5)
        check(main.mailbox.layout == PE_LAYOUT_COLUMNS, "1250 wide, between the two widths: still Columns")
        onMain { self.main.window.setContentSize(NSSize(width: 1100, height: 720)) }
        check(await waitUntil(10) { main.mailbox.layout == PE_LAYOUT_CLASSIC }, "1100 wide again: Classic")
        main.setStatus("")
        onMain { self.main.window.setContentSize(NSSize(width: 1500, height: 720)) }
        check(await waitUntil(10) { main.mailbox.layout == PE_LAYOUT_COLUMNS } && status?.stringValue == "",
              "Columns again, the note said only once")

        command(.layoutClassic)
        onMain { self.main.window.setContentSize(NSSize(width: 1100, height: 720)) }
        check(await waitUntil(10) { main.mailbox.layout == PE_LAYOUT_CLASSIC && list.headerView != nil },
              "View > Layout > Classic: the list above the message again, with its columns")
        main.window.center()
        main.mailbox.placeDividers()
    }

    // ---- the senders' pictures of the column layout ----

    /// An HTTP server on this Mac that answers every GET with one SVG, until the test ends: a brand's BIMI-Location
    final class LogoServer: @unchecked Sendable {
        let port: UInt16
        private let socket: Int32

        init?(svg: String) {
            guard let (fd, port) = UITest.loopbackListener(backlog: 4) else { return nil }
            socket = fd
            self.port = port
            let answer = "HTTP/1.0 200 OK\r\nContent-Type: image/svg+xml\r\nContent-Length: \(svg.utf8.count)\r\n\r\n\(svg)"
            Thread.detachNewThread {
                while true {
                    let client = accept(fd, nil, nil)
                    if client < 0 { return }
                    var buffer = [UInt8](repeating: 0, count: 4096)
                    _ = Darwin.read(client, &buffer, buffer.count)
                    _ = answer.withCString { Darwin.write(client, $0, strlen($0)) }
                    close(client)
                }
            }
        }

        deinit {
            shutdown(socket, SHUT_RDWR)
            close(socket)
        }
    }

    /// a brand whose logo the provider passed (its BIMI-Location on a server of the test) and a person without one
    func listPictures() async throws {
        step("the senders' pictures in the column layout")
        let svg = "<svg xmlns=\"http://www.w3.org/2000/svg\" version=\"1.2\" baseProfile=\"tiny-ps\" viewBox=\"0 0 100 100\"><title>Brand News</title>"
            + "<rect width=\"100\" height=\"100\" fill=\"#d4380d\"/><path d=\"M30 28h26c12 0 20 6 20 16 0 6-4 10-9 12 7 2 11 7 11 14 0 11-8 17-22 17H30z"
            + "M44 40v12h10c5 0 8-2 8-6s-3-6-8-6zm0 23v13h12c5 0 8-2 8-7s-3-6-8-6z\" fill=\"#ffffff\"/></svg>"
        guard let server = LogoServer(svg: svg) else { throw Failed(description: "no logo server") }
        let now = rfc2822(Date())
        try await addMessage("Authentication-Results: mx.inboxclassic.test; dmarc=pass header.from=brand.example; bimi=pass header.d=brand.example\r\n"
            + "BIMI-Location: v=BIMI1; l=http://127.0.0.1:\(server.port)/logo.svg\r\nFrom: Brand News <news@brand.example>\r\n"
            + "To: testuser@inboxclassic.test\r\nSubject: Autumn collection\r\nDate: \(now)\r\nMessage-ID: <list-logo@brand.example>\r\n\r\nNew in this week.\r\n",
            flags: ["\\Seen"])
        try await addMessage("From: Nora Reed <nora@example.com>\r\nTo: testuser@inboxclassic.test\r\nSubject: Book club\r\n"
            + "Date: \(now)\r\nMessage-ID: <list-initials@example.com>\r\n\r\nThursday at seven.\r\n", flags: ["\\Seen"])
        selectFolder(named: "Inbox")
        command(.sync)
        command(.layoutColumns)
        let brand = { self.listedRow("Autumn collection") }
        let person = { self.listedRow("Book club") }
        check(await waitUntil(40) {
            brand() >= 0 && person() >= 0 && main.mailbox.row(brand())?.pictureKind == PE_PICTURE_KIND_LOGO
        }, "the provider passed the brand's logo: its row has a logo to draw")
        check(main.mailbox.row(brand())?.picture != 0, "and the key the core draws it by")
        check(main.mailbox.row(person())?.pictureKind == PE_PICTURE_KIND_NONE, "a sender without a logo has none")
        list.scrollRowToVisible(max(brand(), person()))
        check(await waitUntil(10) {
            let cell = rowCell(person())
            return cell?.picture.isHidden == false && cell?.picture.initials == "NR" && cell?.picture.image == nil
        }, "its row shows the sender's initials in a quiet circle")
        check(await waitUntil(20) {
            list.scrollRowToVisible(brand())
            return rowCell(brand())?.picture.image != nil
        }, "the brand's row shows the logo the core drew from its BIMI-Location")
        check(rowCell(person())?.picture.isAccessibilityElement() == false, "the picture is no element of its own for VoiceOver")
        await shot(main.window, "pictures-4-list")

        withExtendedLifetime(server) {}
        AppDelegate.shared.listPictures = false
        check(await waitUntil(10) { rowCell(person())?.picture.isHidden == true }, "the setting off: no pictures in the rows")
        AppDelegate.shared.listPictures = true
        check(await waitUntil(10) { rowCell(person())?.picture.isHidden == false }, "on again: the pictures are back")
        command(.layoutClassic)
        check(await waitUntil(10) { main.mailbox.layout == PE_LAYOUT_CLASSIC }, "Classic again")
    }

    // ---- pictures from trusted senders ----

    /// a newsletter from the shop with a picture on the internet; `verified`: the provider's Authentication-Results
    /// confirm the shop sent it, otherwise they say DKIM and DMARC failed (a forged From)
    func shopMessage(_ subject: String, id: String, verified: Bool) -> String {
        let result = verified ? "dkim=pass header.d=shop.example; dmarc=pass header.from=shop.example"
                              : "dkim=fail header.d=shop.example; dmarc=fail header.from=shop.example"
        return "Authentication-Results: inboxclassic.test; \(result)\r\n"
            + "From: Shop News <news@shop.example>\r\nTo: testuser@inboxclassic.test\r\nSubject: \(subject)\r\n"
            + "Date: \(rfc2822(Date()))\r\nMessage-ID: <\(id)@shop.example>\r\nMIME-Version: 1.0\r\n"
            + "Content-Type: text/html; charset=utf-8\r\n\r\n"
            + "<p>New in the shop this week.</p>"
            + "<p><img src=\"https://nodemailer.com/img/nm_logo_200x136.png\" width=\"200\" height=\"136\" alt=\"This week\"></p>\r\n"
    }

    /// the message with `subject` of the Inbox shown in the reading pane
    func showShopMessage(_ subject: String) async {
        search("subject:\"\(subject)\"")
        _ = await waitUntil(20) { list.numberOfRows == 1 }
        await selectRow(0)
        _ = await waitUntil(15) { main.mailbox.reader.subject == subject }
    }

    var picturesLoaded: Bool { main.mailbox.reader.messageView?.info?.pointee.pictures_loaded == true }

    func trustedPictures() async throws {
        step("pictures from trusted senders")
        try await addMessage(shopMessage("Autumn sale at the shop", id: "sale", verified: true))
        try await addMessage(shopMessage("Your shop account", id: "forged", verified: false))
        command(.sync)
        _ = await waitFor(20) { await findMessage("INBOX", "Subject: Your shop account") }
        let bar: InfoBar? = find("reader.pictures", in: main.window)
        // the combo button's own accessibility element does not carry the identifier: the reader's buttons
        let choices: NSComboButton? = main.mailbox.reader.picturesChoices
        let download: NSButton? = main.mailbox.reader.picturesDownload

        await showShopMessage("Autumn sale at the shop")
        check(await waitUntil(15) { bar?.isHidden == false && !picturesLoaded }, "a sender not trusted yet: the pictures bar asks")
        let menu = main.mailbox.reader.picturesMenu
        let titles = menu?.items.map(\.title) ?? []
        check(choices?.isHidden == false && download?.isHidden == true && titles.count == 2
              && titles[0].contains("news@shop.example") && titles[1].contains("everyone at shop.example"),
              "the provider confirmed the sender: Download Pictures offers Always from them and from everyone at their domain (\(titles))")
        await shot(main.window, "pictures-2-trusted")

        await showShopMessage("Your shop account")
        check(await waitUntil(15) { bar?.isHidden == false }, "the forged message has the bar too")
        let forged = main.mailbox.reader.picturesMenu?.items ?? []
        let note = forged.first { $0.accessibilityIdentifier() == "pictures.unconfirmed" }
        // the bar's own words: Some pictures have been blocked, no second line
        func labels(_ view: NSView) -> [String] {
            ((view as? NSTextField).map { [$0.stringValue] } ?? []) + view.subviews.flatMap(labels)
        }
        let barWords = bar.map(labels) ?? []
        check(choices?.isHidden == false && download?.isHidden == true
              && forged.first?.title == Command.pictures.label && forged.first?.isEnabled == true
              && note?.isEnabled == false && note?.title.contains("shop.example") == true && note?.toolTip == note?.title
              && !forged.contains { $0.tag == 1 } && !barWords.contains { $0.contains("shop.example") },
              "but its menu has only Download Pictures and the greyed line that says the sender could not be confirmed, "
                  + "not in the bar (\(forged.map(\.title)))")
        await shot(main.window, "pictures-2-unconfirmed")

        await showShopMessage("Autumn sale at the shop")
        _ = await waitUntil(15) { bar?.isHidden == false }
        if let menu = main.mailbox.reader.picturesMenu, let domain = menu.items.firstIndex(where: { $0.tag == 1 }) {
            onMain { menu.performActionForItem(at: domain) }
        }
        check(await waitUntil(15) { bar?.isHidden == true && picturesLoaded },
              "Always from everyone at shop.example shows the pictures, and the bar goes")
        check(main.core.trustedSenders().map(\.label) == ["Everyone at shop.example"], "the domain is trusted")
        await showShopMessage("Your shop account")
        check(await waitUntil(15) { bar?.isHidden == false && !picturesLoaded }, "the forged message still asks")
        await showShopMessage("Autumn sale at the shop")
        check(await waitUntil(15) { bar?.isHidden == true && picturesLoaded }, "the confirmed one shows its pictures by itself")

        step("the pictures in Settings")
        command(.options)
        guard await waitWindow("settings", 10) != nil, let options = SettingsWindow.current else {
            throw Failed(description: "Settings did not open")
        }
        check(options.pictures.state == .off && !main.core.alwaysLoadPictures, "Download pictures in all messages is there, off at first")
        await shot(options.window, "pictures-3-options")
        press(find("settings.trusted", in: options.window))
        guard await waitWindow("trusted", 10) != nil, let sheet = TrustedSendersSheet.current else {
            throw Failed(description: "Trusted Senders did not open")
        }
        check(sheet.senders.map(\.label) == ["Everyone at shop.example"] && sheet.table.numberOfRows == 1,
              "Trusted Senders lists the domain (\(sheet.senders.map(\.label)))")
        check(sheet.window.sheetParent === options.window, "as a sheet of Settings")
        sheet.table.selectRowIndexes(IndexSet(integer: 0), byExtendingSelection: false)
        await pause(0.3)
        await shot(sheet.window, "pictures-4-trusted-senders")
        onMain { sheet.removeClicked() }
        check(await waitUntil(5) { sheet.senders.isEmpty && main.core.trustedSenders().isEmpty }, "the − button removes it")
        let empty: NSTextField? = find("trusted.empty", in: sheet.window)
        check(empty?.isHidden == false, "and the list says no senders are trusted")
        NSApp.stopModal()
        _ = await waitUntil(5) { !sheet.window.isVisible }

        await showShopMessage("Your shop account")
        _ = await waitUntil(15) { bar?.isHidden == false }
        onMain { options.pictures.state = .on; options.picturesChanged() }
        check(await waitUntil(15) { main.core.alwaysLoadPictures && bar?.isHidden == true && picturesLoaded },
              "Download pictures in all messages on: even the forged message shows its pictures")
        onMain { options.pictures.state = .off; options.picturesChanged() }
        check(await waitUntil(15) { !main.core.alwaysLoadPictures && bar?.isHidden == false && !picturesLoaded },
              "off again, it asks again")

        step("what is downloaded ahead")
        // the test turned it off at its start, before the first account
        check(options.downloadAhead.indexOfSelectedItem == 2 && options.downloadLimit.indexOfSelectedItem == 2
                  && options.downloadLimit.titleOfSelectedItem == "1 GB",
              "Settings shows what is downloaded ahead (Only when opened) and 1 GB kept for each account")
        onMain { options.downloadAhead.selectItem(at: 0); options.downloadAheadChosen() }
        check(await waitUntil(5) { main.core.downloadAhead == PE_DOWNLOAD_AHEAD_RECENT },
              "Recent messages up to 1 MB is kept when chosen")
        await shot(options.window, "download-1-options")
        onMain { options.downloadAhead.selectItem(at: 2); options.downloadAheadChosen() }
        check(await waitUntil(5) { main.core.downloadAhead == PE_DOWNLOAD_AHEAD_NEVER }, "and Only when opened again")
        onMain { options.window.close() }
        search("")
    }

    // ---- a message file from the Finder ----

    func openEml() async throws {
        step("opening a message file")
        let types = Bundle.main.object(forInfoDictionaryKey: "CFBundleDocumentTypes") as? [[String: Any]] ?? []
        check(types.contains { ($0["LSItemContentTypes"] as? [String])?.contains("com.apple.mail.email") == true
                  && $0["CFBundleTypeRole"] as? String == "Viewer" && $0["LSHandlerRank"] as? String == "Alternate" },
              "the app says it opens .eml files (Open With), without taking them over")
        let eml = out.appendingPathComponent("open-me.eml")
        let notes = "notes that came in a message file\n"
        try ("From: Ann Example <ann@example.com>\r\nTo: testuser@inboxclassic.test\r\nSubject: A message from a file\r\n"
            + "Date: Tue, 3 Nov 2026 10:00:00 +0000\r\nMessage-ID: <from-a-file@example.com>\r\nMIME-Version: 1.0\r\n"
            + "Content-Type: multipart/mixed; boundary=\"file\"\r\n\r\n"
            + "--file\r\nContent-Type: text/plain; charset=utf-8\r\n\r\nThis message was opened from a file.\r\n"
            + "--file\r\nContent-Type: text/plain; name=\"notes.txt\"\r\n"
            + "Content-Disposition: attachment; filename=\"notes.txt\"\r\nContent-Transfer-Encoding: base64\r\n\r\n"
            + Data(notes.utf8).base64EncodedString() + "\r\n--file--\r\n").write(to: eml, atomically: true, encoding: .utf8)
        // as the Finder hands one over
        onMain { AppDelegate.shared.application(NSApp, open: [eml]) }
        guard let shown = await waitFor(10, { window("message").flatMap { $0.title == "A message from a file" ? $0 : nil } }),
              let opened = MessageWindow.open.last, opened.file != nil else {
            throw Failed(description: "the file did not open in a message window")
        }
        check(true, "the file opens in a message window, titled with its subject")
        check(shown.subtitle == "open-me.eml", "with the file's name under it (\(shown.subtitle))")
        check(opened.validate(.reply) == true && opened.validate(.print) == true && opened.validate(.saveAs) == true,
              "it can be answered, printed and saved")
        check([Command.delete, .move, .flag, .junk, .markUnread, .nextMessage, .previousMessage].allSatisfy { opened.validate($0) == false },
              "but not moved, flagged, deleted or marked: it is in no folder")
        let clip: NSPopUpButton? = find("reader.attachments", in: shown)
        check(clip?.isHidden == false, "its paper clip is there, as for a folder's message")
        let menu = opened.reader.attachmentMenu()
        check(menu.items.first?.title.hasPrefix("notes.txt") == true,
              "and lists the file's attachment (\(menu.items.first?.title ?? "none"))")
        await pause(1)
        await shot(shown, "files-4-open-eml")
        if let all = menu.items.last, let action = all.action {
            let into = emptyFolder("saved-from-file")
            TestHooks.folder = { into }
            onMain { NSApp.sendAction(action, to: all.target, from: all) }
            let saved = await waitFor(10) { try? String(contentsOf: into.appendingPathComponent("notes.txt"), encoding: .utf8) }
            TestHooks.folder = nil
            check(saved == notes, "Save All writes it into the folder chosen, as it was sent (\(saved ?? "nothing"))")
        } else {
            check(false, "the attachment menu ends with Save All")
        }
        opened.press("reply")
        guard let compose = await waitCompose() else { throw Failed(description: "Reply to the file opened nothing") }
        check(field("compose.subject", compose)?.stringValue == "Re: A message from a file"
              && field("compose.to", compose)?.stringValue.contains("ann@example.com") == true,
              "Reply opens a reply to its sender")
        await closeCompose(compose)
        onMain { shown.performClose(nil) }
        check(await waitUntil(10) { !shown.isVisible }, "the window closes")

        let missing = out.appendingPathComponent("not-there.eml")
        try? FileManager.default.removeItem(at: missing)
        onMain { AppDelegate.shared.application(NSApp, open: [missing]) }
        let alert = await waitWindow("alert", 10)
        check(alert != nil, "a file that can not be read is said so")
        answer(alert, "OK")
        _ = await waitUntil(5) { window("alert") == nil }
    }
}
