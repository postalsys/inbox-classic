// The UI end-to-end test's step of a long conversation in the reading pane's stack: the same scenario as the other
// platforms' (scripts/ui-e2e/SCENARIO.md, "A long conversation").
import AppKit
import CInboxClassic

extension UITest {
    /// twenty messages of one conversation, the last one unread: its read middle folded into one row, every message
    /// open with Open All Messages (only the bodies near what is seen made), Fold All Messages, and the previous and
    /// next message. Dated in 2025, as the reactions are, so the later steps find their lists as they were.
    func longConversation() async throws {
        step("a long conversation")
        let subject = "Budget review"
        let count = 20
        for n in 1...count {
            let answers = n == 1 ? "" : "In-Reply-To: <budget\(n - 1)@example.com>\r\nReferences: <budget1@example.com> <budget\(n - 1)@example.com>\r\n"
            try await addMessage("From: Person \(n % 4) <person\(n % 4)@example.com>\r\nTo: testuser@inboxclassic.test\r\n"
                + "Subject: \(n == 1 ? "" : "Re: ")\(subject)\r\nDate: Tue, 9 Sep 2025 \(String(format: "%02d", 8 + n / 6)):\(String(format: "%02d", (n * 7) % 60)):00 +0000\r\n"
                + "Message-ID: <budget\(n)@example.com>\r\n\(answers)\r\nNumber \(n) on the budget.\r\n",
                flags: n == count ? [] : ["\\Seen"])
        }
        selectFolder(named: "Inbox")
        command(.sync)
        _ = await waitUntil(30) { self.listIndex(subject: subject) != nil }
        guard let row = listIndex(subject: subject) else {
            check(false, "the long conversation is listed")
            return
        }
        await selectRow(row)
        let stack = main.mailbox.reader.stack
        // the first message, one row for the read middle, the last two read ones, the unread last one open
        check(await waitUntil(20) { stack.gapViews.count == 1 && stack.shown.count == 4 && stack.frameViews.count == 1 },
              "the read middle of a long conversation is folded into one row (\(stack.shown.count) shown, \(stack.gapViews.count) folded)")
        check(stack.gapViews.first?.title.contains("16") == true, "which says how many it holds (\(stack.gapViews.first?.title ?? ""))")
        press(stack.gapViews.first)
        check(await waitUntil(20) { stack.shown.count == count && stack.gapViews.isEmpty }, "a click on it lists them all (\(stack.shown.count))")
        // every message open: the stack shows them at once, and only the bodies near what is seen are made
        let asked = Date()
        command(.openAllMessages)
        check(await waitUntil(20) { stack.frameViews.count == count }, "Open All Messages opens every message (\(stack.frameViews.count))")
        let took = Date().timeIntervalSince(asked)
        check(took < 5, "at once (\(String(format: "%.1f", took)) s)")
        let live = stack.frameViews.filter { $0.body != nil }.count
        check(live > 0 && live < count, "only the bodies near what is seen are made (\(live) of \(count))")
        await shot(main.window, "threads-7-long")
        // the previous message selected, then every one folded but it
        let selected = main.mailbox.reader.uid
        command(.previousInConversation)
        check(await waitUntil(15) { main.mailbox.reader.uid != selected && stack.frameViews.filter(\.selected).count == 1 },
              "Previous Message in Conversation selects the one before")
        command(.nextInConversation)
        check(await waitUntil(15) { main.mailbox.reader.uid == selected }, "Next Message in Conversation the one after")
        command(.foldAllMessages)
        check(await waitUntil(15) { stack.frameViews.count == 1 && stack.frameViews.first?.selected == true },
              "Fold All Messages folds every message but the selected one (\(stack.frameViews.count))")
        // the step's messages taken away from the server and the list, so the steps after it find the Inbox as before
        for message in await messages("INBOX") where raw(message).contains("@example.com>\r\n") && raw(message).contains("<budget") {
            guard let uid = message["uid"] as? Int else { continue }
            var remove = URLRequest(url: URL(string: "\(rest)/INBOX/messages/\(uid)")!)
            remove.httpMethod = "DELETE"
            _ = try? await URLSession.shared.data(for: remove)
        }
        command(.sync)
        _ = await waitUntil(20) { self.listIndex(subject: subject) == nil }
        list.deselectAll(nil)
    }
}
