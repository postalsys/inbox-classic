// The UI end-to-end test's step of messages in dark mode (the Mac and Linux; Windows keeps the classic light look):
// the same scenario as the other platform's (scripts/ui-e2e/SCENARIO.md).
import AppKit
import CInboxClassic
import WebKit

extension UITest {
    /// the reading pane's web view
    var readerWeb: WKWebView? { views(WKWebView.self, in: main.mailbox.reader.view).first }

    /// a script's answer in the reading pane's document, as a string
    func readerAsk(_ script: String) async -> String {
        guard let web = readerWeb else { return "" }
        return (try? await web.evaluateJavaScript("String(\(script))")) as? String ?? ""
    }

    /// the background the reading pane's document is drawn on now
    func readerBackground() async -> String {
        await readerAsk("getComputedStyle(document.documentElement).backgroundColor")
    }

    /// shows the message of the Inbox whose subject is `subject`, once its text has `text`
    func showDark(_ subject: String, _ text: String) async -> Bool {
        selectFolder(named: "Inbox")
        guard let row = await waitFor(30, { listIndex(subject: subject) }) else { return false }
        list.scrollRowToVisible(row)
        await selectRow(row)
        return await waitUntil(15) { (await readerText()).contains(text) }
    }

    /// a plain message, one written in a mail program (no backgrounds of its own, a dark text color, a quote folded
    /// under "...") and a receipt with its own backgrounds, read in a dark window; a card; writing; and the switch in
    /// Settings turned off
    func darkMessages() async throws {
        step("messages in dark mode")
        let plain = "Trail conditions this weekend"
        let written = "The cabin is booked"
        let designed = "Your order is on its way"
        let date = { (day: Int) in "Date: Tue, \(day) Sep 2025 07:00:00 +0000\r\n" }
        try await addMessage("From: Sam Rivers <sam@example.com>\r\nTo: testuser@inboxclassic.test\r\nSubject: \(plain)\r\n"
            + "Message-ID: <dark-plain@example.com>\r\n\(date(2))MIME-Version: 1.0\r\nContent-Type: text/plain; charset=utf-8\r\n\r\n"
            + "Hi Alex,\r\n\r\nThe ridge path is open again after the storm. The lower bridge is still closed, so take the forest "
            + "road from the car park.\r\n\r\nMap of the detour: https://example.com/trails/detour\r\n\r\nSam\r\n", flags: ["\\Seen"])
        let writtenHtml = "<div dir=\"ltr\"><div>Hi Alex,</div><div><br></div>"
            + "<div>The cabin is booked for the weekend of the 14th. <font color=\"#000000\">Bring warm socks</font>, the "
            + "evenings get cold up there.</div><div><span style=\"color:rgb(34,34,34)\">Directions are on "
            + "<a href=\"https://example.com/cabin\">the cabin's page</a>.</span></div>"
            + "<div><span style=\"color:#cc0000\">Check-in closes at 8 pm.</span></div><div><br></div><div>Jamie</div></div><br>"
            + "<div class=\"gmail_quote\"><div dir=\"ltr\" class=\"gmail_attr\">On Mon, Sep 1, 2025 at 8:00 AM Alex Morgan "
            + "&lt;testuser@inboxclassic.test&gt; wrote:<br></div><blockquote class=\"gmail_quote\" "
            + "style=\"margin:0px 0px 0px 0.8ex;border-left:1px solid rgb(204,204,204);padding-left:1ex\">"
            + "Shall we book the cabin for September?</blockquote></div>"
        try await addMessage("From: Jamie Lee <jamie@example.com>\r\nTo: testuser@inboxclassic.test\r\nSubject: \(written)\r\n"
            + "Message-ID: <dark-written@example.com>\r\n\(date(3))MIME-Version: 1.0\r\n"
            + "Content-Type: text/html; charset=utf-8\r\n\r\n\(writtenHtml)\r\n", flags: ["\\Seen"])
        let row = { (item: String, price: String) in
            "<tr><td style=\"padding:6px 0;border-bottom:1px solid #e3e7ec\">\(item)</td>"
                + "<td align=\"right\" style=\"padding:6px 0;border-bottom:1px solid #e3e7ec\">\(price)</td></tr>"
        }
        let designedHtml = "<table width=\"100%\" bgcolor=\"#eef1f4\" cellpadding=\"0\" cellspacing=\"0\"><tr>"
            + "<td align=\"center\" style=\"padding:24px\"><table width=\"520\" bgcolor=\"#ffffff\" cellpadding=\"0\" cellspacing=\"0\">"
            + "<tr><td style=\"padding:24px;font-family:Helvetica,Arial,sans-serif;color:#1d2733;font-size:14px\">"
            + "<h1 style=\"font-size:22px;margin:0 0 12px\">Your order is on its way</h1>"
            + "<p style=\"margin:0 0 16px\">Good news, Alex: order 10442 left our warehouse this morning.</p>"
            + "<table width=\"100%\" cellpadding=\"0\" cellspacing=\"0\">" + row("Hiking boots, size 42", "129.00 EUR")
            + row("Wool socks, two pairs", "18.00 EUR") + row("<b>Total</b>", "<b>147.00 EUR</b>") + "</table>"
            + "<p style=\"margin:20px 0 0\"><a href=\"https://example.com/track\" style=\"display:inline-block;background:#0b6bcb;"
            + "color:#ffffff;padding:10px 18px;border-radius:4px;text-decoration:none\">Track your parcel</a></p></td></tr></table>"
            + "<p style=\"color:#7a8591;font-size:12px;font-family:Helvetica,Arial,sans-serif\">Northwind Outdoor, 1 Harbour Street</p>"
            + "</td></tr></table>"
        try await addMessage("From: Northwind Outdoor <orders@example.com>\r\nTo: testuser@inboxclassic.test\r\nSubject: \(designed)\r\n"
            + "Message-ID: <dark-designed@example.com>\r\n\(date(4))MIME-Version: 1.0\r\n"
            + "Content-Type: text/html; charset=utf-8\r\n\r\n\(designedHtml)\r\n", flags: ["\\Seen"])
        command(.sync)

        let before = NSApp.appearance
        let dark = "rgb(30, 31, 34)"
        let white = "rgb(255, 255, 255)"
        check(pe_dark_messages(main.core.handle), "Settings' dark messages are on at first")
        onMain { NSApp.appearance = NSAppearance(named: .darkAqua) }
        await pause(1)

        check(await showDark(plain, "ridge path"), "a plain message is shown in a dark window")
        check(await waitUntil(5) { await self.readerBackground() == dark },
              "on a dark background (\(await readerBackground()))")
        check(await readerAsk("document.querySelector('meta[name=color-scheme]').content") == "light dark",
              "its document carries both looks, so a change of the system's appearance needs no reload")
        await shot(main.window, "dark-1-plain")

        check(await showDark(written, "cabin is booked"), "a message as people write it is shown")
        check(await waitUntil(5) { await self.readerBackground() == dark },
              "dark too: it sets no backgrounds of its own (\(await readerBackground()))")
        check(await readerAsk("document.querySelectorAll('[data-pe-dark]').length") == "2",
              "its two text colors too dark to read there are marked to be lightened, the red one is not")
        check(await readerAsk("getComputedStyle(document.querySelector('font')).color") != "rgb(0, 0, 0)",
              "and are lightened (\(await readerAsk("getComputedStyle(document.querySelector('font')).color")))")
        check(await readerAsk("document.querySelector('details.pe-fold') !== null") == "true",
              "the quote is folded under the dark ... button")
        await shot(main.window, "dark-2-written")

        check(await showDark(designed, "order 10442"), "a receipt with backgrounds of its own is shown")
        check(await waitUntil(5) { await self.readerBackground() == white },
              "light, as it was designed (\(await readerBackground()))")
        check(await readerAsk("document.querySelector('meta[name=color-scheme]').content") == "light",
              "its document has only the light look")
        await shot(main.window, "dark-3-newsletter")

        check(await showDark("Undelivered Mail Returned to Sender", "Your message was not delivered"),
              "the delivery report is shown with its card")
        _ = try? await readerWeb?.evaluateJavaScript("document.querySelector('details').open = true")
        check(await waitUntil(5) { await self.readerBackground() == dark }, "around the dark card")
        await pause(0.5)
        await shot(main.window, "dark-4-cards")

        // writing: the editor dark too, and nothing about colors in what would be sent
        _ = await showDark(written, "cabin is booked")
        command(.reply)
        if let compose = await waitCompose() {
            check(await typeInEditor(compose, "Thanks, Jamie. Socks packed."), "a reply is written in a dark editor")
            let editor: EditorView? = views(EditorView.self, in: compose.contentView).first
            let background = (try? await editor?.evaluateJavaScript("getComputedStyle(document.documentElement).backgroundColor")) as? String
            check(background == dark, "the editor's page is dark (\(background ?? "none"))")
            let html = (try? await editor?.evaluateJavaScript("document.getElementById('body').innerHTML")) as? String ?? ""
            check(!html.isEmpty && !html.lowercased().contains("color"), "what is written carries no colors (\(html))")
            await pause(0.5)
            await shot(compose, "dark-5-compose")
            await closeCompose(compose)
        } else {
            check(false, "Reply opens a compose window")
        }

        // the switch in Settings off: the written message light in the dark window
        _ = await showDark(written, "cabin is booked")
        command(.options)
        guard await waitWindow("settings", 10) != nil, let options = SettingsWindow.current else {
            onMain { NSApp.appearance = before }
            throw Failed(description: "Settings did not open")
        }
        check(options.darkMessages.state == .on, "Settings has \"\(Text.uiDarkMessages.text)\", on")
        await shot(options.window, "dark-6b-settings")
        press(options.darkMessages)
        check(await waitUntil(5) { !pe_dark_messages(self.main.core.handle) }, "turning it off keeps it off")
        check(await waitUntil(15) {
            let scheme = await self.readerAsk("document.querySelector('meta[name=color-scheme]').content")
            let text = await self.readerText()
            return scheme == "light" && text.contains("cabin is booked")
        }, "the message shown is made again, light")
        check(await waitUntil(5) { await self.readerBackground() == white }, "on white in the dark window")
        check(await readerAsk("document.querySelectorAll('[data-pe-dark]').length") == "0", "with its colors as sent")
        onMain { options.window.close() }
        await pause(0.5)
        await shot(main.window, "dark-6-switch-off")

        // as it was for the steps after this one
        main.core.darkMessages = true
        Preview.dark = true
        onMain { NSApp.appearance = before }
        await pause(0.5)
        selectFolder(named: "Inbox")
    }
}
