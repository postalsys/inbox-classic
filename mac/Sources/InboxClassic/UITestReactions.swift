// The UI end-to-end test's step of emoji reactions: the same scenario as the other platforms'
// (scripts/ui-e2e/SCENARIO.md, "Emoji reactions").
import AppKit
import CInboxClassic

extension UITest {
    /// a message from Kate, then her Gmail reaction to it: the reaction leaves the list, its message shows it in its row
    /// and its header, and the chip's menu lists the email again. Dated before the other messages, as the bounces and
    /// the codes are, so the later steps find their lists as they were.
    func reactions() async throws {
        step("emoji reactions")
        let subject = "Furniture"
        let reply = "Re: Furniture"
        try await addMessage("From: Kate Kalda <kate@example.com>\r\nTo: testuser@inboxclassic.test\r\nSubject: \(subject)\r\n"
            + "Date: Mon, 8 Sep 2025 10:00:00 +0000\r\nMessage-ID: <furniture@example.com>\r\n"
            + "MIME-Version: 1.0\r\nContent-Type: text/plain; charset=utf-8\r\n\r\nThe prices are in.\r\n", flags: ["\\Seen"])
        selectFolder(named: "Inbox")
        command(.sync)
        _ = await waitUntil(30) { self.listIndex(subject: subject) != nil }
        check(listIndex(subject: subject) != nil, "the message Kate wrote is listed")

        // Gmail's reaction, from Kate, whose domain the provider says signed it
        try await addMessage("Authentication-Results: mx.inboxclassic.test; dkim=pass header.d=example.com\r\n"
            + "From: Kate Kalda <kate@example.com>\r\nTo: testuser@inboxclassic.test\r\nSubject: \(reply)\r\n"
            + "Date: Mon, 8 Sep 2025 10:05:00 +0000\r\nMessage-ID: <furniture-reaction@example.com>\r\n"
            + "In-Reply-To: <furniture@example.com>\r\nReferences: <furniture@example.com>\r\nMIME-Version: 1.0\r\n"
            + "Content-Type: multipart/alternative; boundary=\"reaction\"\r\n\r\n"
            + "--reaction\r\nContent-Type: text/plain; charset=UTF-8\r\n\r\n\u{1F44D}\r\n\r\nKate Kalda reacted via Gmail\r\n"
            + "--reaction\r\nContent-Type: text/vnd.google.email-reaction+json; charset=UTF-8\r\n\r\n"
            + "{\"emoji\": \"\u{1F44D}\", \"version\": 1}\r\n"
            + "--reaction\r\nContent-Type: text/html; charset=UTF-8\r\n\r\n<p>\u{1F44D}</p><p>Kate Kalda reacted via Gmail</p>\r\n"
            + "--reaction--\r\n")
        command(.sync)
        let replyPattern = "Subject: \(NSRegularExpression.escapedPattern(for: reply))"
        check(await waitUntil(30) { await self.seen(replyPattern) }, "the reaction email is read on the server")
        guard let row = await waitFor(20, { () -> Int? in
            guard let at = self.listIndex(subject: subject), self.main.mailbox.row(at)?.reactions.isEmpty == false else { return nil }
            return at
        }) else {
            throw Failed(description: "the reaction did not reach the message's row")
        }
        check(listIndex(subject: reply) == nil, "the reaction email is not in the Inbox list")
        check(main.mailbox.row(row)?.reactions == "\u{1F44D}",
              "the core gives the row its badge (\(main.mailbox.row(row)?.reactions ?? ""))")
        // nothing selected, so the picture is of the list (the step before leaves its message selected)
        onMain { self.list.deselectAll(nil) }
        list.scrollRowToVisible(row)
        check(subjectCell(row)?.reactionsShown == "\u{1F44D}",
              "the row shows the 👍 badge after its subject (\(subjectCell(row)?.reactionsShown ?? "no cell"))")
        await shot(main.window, "reactions-1-list")

        await selectRow(row)
        let reader = main.mailbox.reader
        check(await waitUntil(15) { reader.reactionChips == ["\u{1F44D} Kate Kalda"] },
              "selected, its header has Reactions: with \"👍 Kate Kalda\" (\(reader.reactionChips))")
        let row0: NSView? = find("reader.reactions", in: main.window)
        check(row0?.accessibilityLabel() == Text.uiReactionsLabel.text, "the row is named Reactions: for a screen reader")
        await shot(main.window, "reactions-2-header")

        // a menu runs in a tracking loop of its own, which a picture taken from inside the app does not see: its items
        // are checked instead
        let menu = reader.reactionMenu(at: 0)
        let titles = menu?.items.filter { !$0.isSeparatorItem }.map(\.title) ?? []
        check(titles.count == 3 && titles[0] == Text.uiReactionOpenEmail.text && titles[1] == Text.uiReactionShowAsEmail.text
              && titles[2].hasPrefix(lead(.uiReactionWhen)),
              "the chip's menu has Open Reaction Email, Show as Email and when Kate reacted (\(titles))")
        check(menu?.items.last?.isEnabled == false, "when is a line to read, not to choose")

        // Open Reaction Email: the email in a message window, as a message file is
        let before = MessageWindow.open.count
        onMain { reader.openReactionEmail(0) }
        let opened = await waitFor(10) { MessageWindow.open.count > before ? MessageWindow.open.last : nil }
        check(opened?.file != nil && opened?.reader.subject == reply,
              "Open Reaction Email shows the email in a message window (\(opened?.reader.subject ?? "none"))")
        if let opened { onMain { opened.window.close() } }

        // Show as Email: listed again for good, the chip gone
        onMain { reader.showReactionAsEmail(0) }
        // grouped by conversation, it is in Kate's conversation, under her message; otherwise a row of its own
        check(await waitUntil(30) {
            self.listIndex(subject: reply) != nil
                || self.listIndex(subject: subject).flatMap { self.main.mailbox.row($0)?.threadCount } == 2
        }, "Show as Email lists the reaction email again")
        // and opened, the conversation shows it under her message
        if main.mailbox.grouped, listIndex(subject: reply) == nil, let row = listIndex(subject: subject) {
            onMain { self.main.mailbox.setExpanded(true, row: row) }
            check(await waitUntil(10) { self.listIndex(subject: reply) != nil },
                  "opened, Kate's conversation has the reaction email under her message (\(listedSubjects()))")
            if let row = listIndex(subject: subject) { onMain { self.main.mailbox.setExpanded(false, row: row) } }
        }
        check(await waitUntil(10) { reader.reactionChips.isEmpty }, "and the chip is gone (\(reader.reactionChips))")
        let back = listIndex(subject: subject)
        check(back.flatMap { main.mailbox.row($0)?.reactions } == "", "the message's row has no badge any longer")
    }
}
