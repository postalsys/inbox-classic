// The UI end-to-end test's step of the accounts' sign-in status: the same scenario as the other platforms'
// (scripts/ui-e2e/SCENARIO.md, "Account sign-in status"). ImapKit refuses the password, revokes and refuses the sign-in
// of an account that signs in through the browser (its OpenID Connect provider), wants an administrator's approval,
// signs the browser in to another address, and closes every connection; each time the folder list's mark, the bar over
// the list, the status bar and the one dialog say it in the core's words, and the bar's button, the mark or the dialog
// mends it. Every account and rule is as it was afterwards.
import AppKit
import CInboxClassic

extension UITest {
    func accountStatus() async throws {
        step("an account whose password the server refuses")
        var notified: [(String, String)] = []
        TestHooks.notified = { title, text in notified.append((title, text)) }
        defer { TestHooks.notified = nil }
        let core = main.core
        guard let first = core.accounts().first?.id, let inbox = inbox(ofAccount: 0)?.id else {
            throw Failed(description: "no account")
        }
        selectFolder(named: "Inbox")
        try await setServerPassword("testuser", "refused-by-the-test")
        let before = modalsOpened["form"]?.at
        await syncDropping(first, user: "testuser")
        let logon = await waitFor(60) { window("form").flatMap { $0.title == Text.uiLogon.text ? $0 : nil } }
        check(logon != nil, "a refused password asks for it once")
        check(alertText(logon).contains(Text.accountStateAppPasswordHint.text), "with the app password hint under the request")
        var status = await waitStatus(first) { $0.needsSignIn }
        check(status.needsSignIn && status.action == PE_STATUS_ACTION_ENTER_PASSWORD,
              "the account needs a sign-in, the core says by a password")
        await checkMark(row: treeRow { $0.folder == inbox }, PE_ACCOUNT_MARK_SIGN_IN, status.tooltip,
                  "the only account's Inbox has the yellow warning in its count's place, the core's words as its tooltip")
        await checkBar(status, "the bar over the list says it, with Enter Password")
        check(await waitUntil(20) { statusBar == core.accountsStatusText && core.accountsStatusText != nil },
              "the status bar says the account needs a sign-in, not Done (\(statusBar))")
        check(main.dockBadge == "!", "the Dock icon has a \"!\" (\(main.dockBadge ?? "none"))")
        check(notified.contains { $0 == (status.notificationTitle, status.notificationText) },
              "a notification says it, in the core's words (\(notified.map(\.0)))")
        check(main.signInAgainAccount == first && menuEnabled(.signInAgain), "Tools > Sign In Again is on")
        await shot(main.window, "status-1-sign-in")

        // Cancel: the dialog does not come back for the next sync, the marks stay
        press(logon.flatMap { find("form.cancel", in: $0) })
        _ = await waitUntil { logon?.isVisible != true }
        let asked = modalsOpened["form"]?.at
        await syncToEnd(first)
        check(await waitFor(5) { window("form") } == nil && modalsOpened["form"]?.at == asked && asked != before,
              "after Cancel the next Send/Recv asks no more")
        status = core.accountStatus(first)
        await checkMark(row: treeRow { $0.folder == inbox }, PE_ACCOUNT_MARK_SIGN_IN, status.tooltip, "the mark stays")
        await checkBar(status, "and so does the bar")
        await shot(main.window, "status-2-cancelled")

        step("writing from an account that is not signed in")
        try await composeAndOutbox(first, status)

        step("the bar's Enter Password")
        try await setServerPassword("testuser", "testpass")
        onMain { self.main.mailbox.pressAccountBar() }
        let again = await waitFor(20) { window("form").flatMap { $0.title == Text.uiLogon.text ? $0 : nil } }
        check(again != nil, "Enter Password asks for the password")
        type("testpass", into: again.flatMap { find("form.field.0", in: $0) })
        press(again.flatMap { find("form.ok", in: $0) })
        status = await waitStatus(first) { $0.connected }
        check(status.connected, "with the right password the account is signed in")
        check(await waitUntil(20) { self.mark(row: self.treeRow { $0.folder == inbox }) == PE_ACCOUNT_MARK_NONE },
              "the mark goes, the count is back in its place")
        check(await waitUntil(20) { main.mailbox.accountBarText.text.isEmpty }, "the bar goes")
        check(await waitUntil(20) { statusBar == Text.uiDone.text }, "the status bar says Done (\(statusBar))")
        check(main.dockBadge != "!" && !menuEnabled(.signInAgain), "the Dock's \"!\" goes, Sign In Again is off")
        await shot(main.window, "status-7-fixed")
        // the message that waited goes with the sign-in; taken off the server again for the steps after
        let pattern = "Subject: Waiting for a sign-in"
        check(await waitFor(60) { await findMessage("INBOX", pattern) } != nil, "the message that waited in the Outbox goes")
        for mailbox in ["INBOX", "Sent Items"] {
            if let sent = await waitFor(20, { await findMessage(mailbox, pattern) }), let uid = sent["uid"] {
                try await imapKit("DELETE", "/mailboxes/\(mailbox.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? mailbox)/messages/\(uid)")
            }
        }
        await syncToEnd(first)

        try await browserSignInStatus()
        try await serverDown(first, inbox)
        check(window("alert") == nil && window("form") == nil && ComposeWindow.open.isEmpty,
              "no dialog or compose window is left open (\(visibleWindows))")
    }

    // ---- an account that signs in through the browser ----

    /// an account added through ImapKit's OpenID Connect provider (a sign-in app with the client that always allows):
    /// its sign-in revoked, an administrator's approval wanted, the browser signed in to another address; then it and
    /// its sign-in app removed
    func browserSignInStatus() async throws {
        step("an account that signs in through the browser")
        let core = main.core
        let (app, alice) = try await addBrowserAccount()
        defer {
            pe_account_remove(core.handle, alice)
            pe_sign_in_app_remove(core.handle, app, nil)
            main.mailbox.reload()
        }
        guard let folder = await waitFor(60, { core.folders(alice).first { $0.specialUse == PE_SPECIAL_USE_INBOX }?.id }) else {
            throw Failed(description: "the account signed in to has no Inbox")
        }
        _ = await waitUntil(20) { self.treeRow { $0.folder == folder } != nil }
        let inboxRow = { self.treeRow { $0.folder == folder } }
        let heading = { self.treeRow { $0.kind == PE_TREE_ROW_KIND_ACCOUNT && $0.account == alice } }

        // the sign-in revoked: Sign in again? asked once, No leaves the marks
        try await imapKit("POST", "/oauth/tokens/revoke", ["user": "alice@example.com", "type": "refresh"])
        try await imapKit("POST", "/oauth/tokens/expire", ["user": "alice@example.com"])
        await syncDropping(alice, user: "alice@example.com")
        let question = await waitWindow("alert", 60)
        var status = await waitStatus(alice) { $0.needsSignIn }
        check(alertText(question).contains(hyphensKept(status.bar)) && status.prompt == PE_PROMPT_BROWSER_SIGN_IN,
              "a revoked sign-in asks once, in the bar's words, whether to sign in again")
        answer(question, Text.uiCancel.text)
        check(status.action == PE_STATUS_ACTION_SIGN_IN_AGAIN, "the account needs a sign-in in the browser")
        if let row = inboxRow() { tree.selectRowIndexes(IndexSet(integer: row), byExtendingSelection: false) }
        await checkMark(row: inboxRow(), PE_ACCOUNT_MARK_SIGN_IN, status.tooltip, "its Inbox under All Inboxes has the warning")
        await checkMark(row: heading(), PE_ACCOUNT_MARK_SIGN_IN, status.tooltip, "and its heading")
        await checkBar(status, "the bar over its list says the provider did not accept the sign-in, with Sign In Again")
        let menu = main.mailbox.accountMenu(alice).items.first { $0.title == Command.signInAgain.label }
        check(menu?.isEnabled == true, "the account's menu offers Sign In Again")
        await shot(main.window, "status-3-oauth")
        if let all = treeRow(PE_TREE_ROW_KIND_ALL_INBOXES) {
            tree.selectRowIndexes(IndexSet(integer: all), byExtendingSelection: false)
            check(await waitUntil(20) { main.mailbox.accountBarText.text == status.bar },
                  "All Inboxes has the bar of the account that needs a sign-in")
        }

        // a click on the mark signs in again
        if let row = heading(), let cell = tree.view(atColumn: 0, row: row, makeIfNecessary: true) as? HeadingCell {
            onMain { cell.mark.performClick(nil) }
        }
        let page = await signInPage()
        check(page?.contains("login_hint=alice%40example.com") == true, "a click on the mark opens the sign-in for its address")
        await follow(page)
        status = await waitStatus(alice) { $0.connected }
        check(status.connected, "signed in again, the account is connected")
        check(await waitUntil(20) { self.mark(row: heading()) == PE_ACCOUNT_MARK_NONE }, "and its marks go")

        // an organization that wants its administrator: the link copied
        step("an administrator's approval wanted")
        try await imapKit("POST", "/oauth/token-faults", [
            "grant": "refresh_token", "error": "invalid_grant", "status": 400, "count": 100,
            "description": "AADSTS65001: The user or administrator has not consented to use the application.",
        ])
        try await imapKit("POST", "/oauth/tokens/expire", ["user": "alice@example.com"])
        await syncDropping(alice, user: "alice@example.com")
        let admin = await waitWindow("alert", 60)
        status = await waitStatus(alice) { $0.reason == PE_SIGN_IN_REASON_ADMIN_CONSENT }
        check(status.action == PE_STATUS_ACTION_COPY_ADMIN_LINK && alertText(admin).contains(hyphensKept(status.bar)),
              "it asks once, in the bar's words")
        NSPasteboard.general.clearContents()
        answer(admin, status.button)
        check(await waitUntil(10) { NSPasteboard.general.string(forType: .string) == status.adminLink && !status.adminLink.isEmpty },
              "Copy Link for Administrator copies the approval link (\(NSPasteboard.general.string(forType: .string) ?? ""))")
        check(await waitUntil(10) { statusBar == Text.accountStateAdminLinkCopied.text }, "and the status bar says so (\(statusBar))")
        if let row = inboxRow() { tree.selectRowIndexes(IndexSet(integer: row), byExtendingSelection: false) }
        await checkBar(status, "the bar says an administrator must approve, with Copy Link for Administrator")
        await shot(main.window, "status-4-admin")
        try await imapKit("DELETE", "/oauth/token-faults")
        await syncToEnd(alice)
        check(await waitStatus(alice) { $0.connected }.connected, "approved, the next Send/Recv signs in")

        // the browser signed in to another address: Try Again asks for the account picker
        step("a sign-in with another address")
        try await imapKit("POST", "/oauth/tokens/revoke", ["user": "alice@example.com", "type": "refresh"])
        try await imapKit("POST", "/oauth/tokens/expire", ["user": "alice@example.com"])
        await syncDropping(alice, user: "alice@example.com")
        _ = await waitStatus(alice) { $0.needsSignIn }
        // the state's dialog again: Cancel, then the bar's Sign In Again
        await dismissDialogs()
        try await imapKit("POST", "/oauth/token-faults", ["grant": "authorization_code", "claims": ["email": "bob@example.com"]])
        onMain { self.main.mailbox.pressAccountBar() }
        await follow(await signInPage())
        status = await waitStatus(alice) { $0.reason == PE_SIGN_IN_REASON_OTHER_ADDRESS }
        check(status.reason == PE_SIGN_IN_REASON_OTHER_ADDRESS && status.action == PE_STATUS_ACTION_SIGN_IN_AGAIN,
              "signed in to another address, the account's state names it and offers to sign in again")
        // the bar says it; a dialog, if the state brings one, is answered
        await dismissDialogs()
        await checkBar(status, "the bar says which address the browser signed in to, with Try Again")
        check(status.bar.contains("bob@example.com") && status.bar.contains("alice@example.com"), "both addresses in it")
        await shot(main.window, "status-5-other-address")
        onMain { self.main.mailbox.pressAccountBar() }
        let picker = await signInPage()
        check(picker?.contains("prompt=select_account") == true, "Try Again asks the provider for its account picker")
        await follow(picker)
        check(await waitStatus(alice) { $0.connected }.connected, "the right account chosen, it is connected")
    }

    /// the sign-in app of ImapKit's provider and an account signed in with it, synced
    func addBrowserAccount() async throws -> (app: Int64, account: Int64) {
        let core = main.core
        let issuer = port("oauth")
        let check = issuer.withCString { pe_sign_in_app_check(core.handle, $0, nil) }
        guard await waitUntil(30, { main.requestsDone.contains(check) }) else { throw Failed(description: "the issuer was not checked") }
        var found: UnsafeMutablePointer<CChar>?
        _ = pe_sign_in_app_check_result(core.handle, check, &found)
        _ = taken(found)
        let strings = CStrings()
        var form = PeSignInAppForm(
            name: strings.add("ImapKit"), issuer: strings.add(issuer), client_id: strings.add("imapkit-approve"),
            scopes: strings.add("openid email profile offline_access mail"), imap_host: strings.add("127.0.0.1"),
            imap_port: UInt16(port("imaps")) ?? 0, imap_security: PE_SECURITY_TLS, smtp_host: strings.add("127.0.0.1"),
            smtp_port: UInt16(port("smtp")) ?? 0, smtp_security: PE_SECURITY_START_TLS)
        let app = pe_sign_in_app_save(core.handle, 0, &form, PE_SECRET_CHANGE_KEEP, nil, nil)
        guard app > 0 else { throw Failed(description: "the sign-in app was not saved") }
        var page: UnsafeMutablePointer<CChar>?
        let request = "alice@example.com".withCString { pe_sign_in_begin(core.handle, PE_O_AUTH_PROVIDER_APP, app, $0, &page) }
        await follow(taken(page))
        guard await waitUntil(30, { main.requestsDone.contains(request) }), pe_sign_in_result(core.handle, request, nil) else {
            throw Failed(description: "the browser sign-in did not finish")
        }
        let account = pe_account_add_signed_in(core.handle, request, nil)
        guard account > 0 else { throw Failed(description: "the account signed in to was not added") }
        main.mailbox.reload()
        await syncToEnd(account)
        return (app, account)
    }

    // ---- writing while signed out ----

    /// Compose says under From that the message will wait; the Outbox says why it waits, in the core's words; the
    /// message goes once the account is signed in again
    func composeAndOutbox(_ account: Int64, _ status: AccountStatus) async throws {
        command(.newMail)
        guard let compose = await waitCompose(), let window = ComposeWindow.open.first(where: { $0.window === compose }) else {
            throw Failed(description: "no compose window")
        }
        check(await waitUntil(10) { window.fromNoteText == status.composeNote && !status.composeNote.isEmpty },
              "a note under From says the account is not signed in (\(window.fromNoteText))")
        type("Fay <fay@example.com>", into: field("compose.to", compose))
        type("Waiting for a sign-in", into: field("compose.subject", compose))
        _ = await typeInEditor(compose, "This waits in the Outbox.")
        await shot(compose, "status-8-compose")
        send(compose)
        _ = await waitUntil(20) { !compose.isVisible }
        command(.outbox)
        guard let outbox = await waitWindow("outbox") else { throw Failed(description: "no Outbox") }
        let table: NSTableView? = find("outbox.list", in: outbox)
        let reason = await waitFor(20) { () -> String? in
            guard let table, table.numberOfRows == 1, let column = table.tableColumns.firstIndex(where: { $0.identifier.rawValue == "status" }),
                  let cell = table.view(atColumn: column, row: 0, makeIfNecessary: true) as? NSTableCellView else { return nil }
            return cell.textField?.stringValue
        }
        var problem = ""
        if let outboxList = pe_outbox(main.core.handle) {
            if pe_outbox_count(outboxList) == 1, let queued = pe_outbox_get(outboxList, 0)?.pointee, queued.account == account {
                problem = text(queued.problem)
            }
            pe_outbox_free(outboxList)
        }
        check(!problem.isEmpty && problem.contains(main.mailbox.accountName(account))
              && reason == problem,
              "the Outbox says the message waits for the account's sign-in (\(reason ?? "nothing"))")
        await shot(outbox, "status-9-outbox")
        NSApp.stopModal()
        _ = await waitUntil(10) { !outbox.isVisible }
        main.showOutbox()
    }

    // ---- the server down ----

    /// every connection closed at once: the grey mark once two syncs failed, no dialog, Try Again once it is back
    func serverDown(_ account: Int64, _ inbox: Int64) async throws {
        step("a server that can not be reached")
        selectFolder(named: "Inbox")
        let down = try await imapKit("POST", "/script/rules", ["on": "greeting", "close": "reset"])
        let dialogs = modalsOpened.mapValues(\.at)
        await syncDropping(account, user: "testuser")
        check(main.core.accountStatus(account).connected, "one failed sync alone shows nothing")
        await syncToEnd(account)
        let status = await waitStatus(account) { $0.state == PE_ACCOUNT_STATE_CANNOT_CONNECT }
        check(status.state == PE_ACCOUNT_STATE_CANNOT_CONNECT && status.action == PE_STATUS_ACTION_SYNC_NOW,
              "after two, the account can not connect")
        await checkMark(row: treeRow { $0.folder == inbox }, PE_ACCOUNT_MARK_CANNOT_CONNECT, status.tooltip,
                  "its Inbox has the quiet grey mark, the core's words as its tooltip")
        await checkBar(status, "the bar says it can not connect, with Try Again")
        check(await waitUntil(20) { statusBar == main.core.accountsStatusText && main.core.accountsStatusText != nil },
              "the status bar says it can not connect (\(statusBar))")
        check(modalsOpened.mapValues(\.at) == dialogs && main.dockBadge != "!", "no dialog, no \"!\" on the Dock")
        await shot(main.window, "status-6-cannot-connect")
        if let id = (down as? [String: Any])?["id"] {
            try await imapKit("DELETE", "/script/rules/\(id)")
        }
        let finished = main.syncsFinished[account] ?? 0
        onMain { self.main.mailbox.pressAccountBar() }
        _ = await waitUntil(60) { (self.main.syncsFinished[account] ?? 0) > finished }
        check(await waitStatus(account) { $0.connected }.connected, "Try Again, with the server back, connects")
        check(await waitUntil(20) { self.mark(row: self.treeRow { $0.folder == inbox }) == PE_ACCOUNT_MARK_NONE }
              && main.mailbox.accountBarText.text.isEmpty, "the mark and the bar go")
    }

    // ---- helpers ----

    /// the windows shown and what they say, for a failure's message
    var visibleWindows: String {
        NSApp.windows.filter(\.isVisible).map { "\($0.identifier?.rawValue ?? "?"): \(alertText($0).prefix(80))" }
            .joined(separator: "; ")
    }

    /// the status bar's words
    var statusBar: String {
        (find("status.text", in: main.window) as NSTextField?)?.stringValue ?? ""
    }

    /// a call of ImapKit's REST API (`path` after /v1), its answer
    @discardableResult
    func imapKit(_ method: String, _ path: String, _ body: Any? = nil) async throws -> Any? {
        try await restCall(method, rest.replacingOccurrences(of: "/mailboxes", with: path), body)
    }

    /// any dialog open now or coming within a few seconds answered as Cancel (or OK), as a user who reads the bar
    func dismissDialogs() async {
        while let open = await waitWindow("alert", 3) {
            let button: NSButton? = views(NSButton.self, in: open.contentView)
                .first { [Text.uiCancel.text, Text.uiNo.text, Text.uiOk.text].contains($0.title) }
            press(button)
            _ = await waitUntil(5) { !open.isVisible }
        }
    }

    func setServerPassword(_ user: String, _ password: String) async throws {
        try await imapKit("PUT", "/users/\(user)", ["password": password])
    }

    /// the connections of `user` to the server closed, as a sleep or a network change closes them, then Send/Recv of
    /// `account` to its end: the sync signs in again (the other account's connections stay)
    func syncDropping(_ account: Int64, user: String) async {
        if let sessions = try? await imapKit("GET", "/sessions") as? [[String: Any]] {
            for session in sessions where session["user"] as? String == user {
                if let id = session["session"] {
                    _ = try? await imapKit("DELETE", "/sessions/\(id)")
                }
            }
        }
        await syncToEnd(account)
    }

    /// Send/Recv of `account`, as its menu does, waited for to its end
    func syncToEnd(_ account: Int64) async {
        let finished = main.syncsFinished[account] ?? 0
        main.syncAsked()
        main.core.sync(account)
        _ = await waitUntil(60) { (self.main.syncsFinished[account] ?? 0) > finished }
    }

    /// the account's status once `matches` takes it (or as it is after a minute)
    func waitStatus(_ account: Int64, _ matches: (AccountStatus) -> Bool) async -> AccountStatus {
        await waitFor(60) { () -> AccountStatus? in
            let status = main.core.accountStatus(account)
            return matches(status) ? status : nil
        } ?? main.core.accountStatus(account)
    }

    /// the mark the tree's row `row` shows
    func mark(row: Int?) -> PeAccountMark {
        guard let row, let cell = tree.view(atColumn: 0, row: row, makeIfNecessary: true) else { return PE_ACCOUNT_MARK_NONE }
        return (cell as? FolderCell)?.mark.shown ?? (cell as? HeadingCell)?.mark.shown ?? PE_ACCOUNT_MARK_NONE
    }

    /// the tree's row `row` shows the mark `expected` with `tooltip` as its tooltip and its name for a screen reader,
    /// once the window heard of the change
    func checkMark(row: @autoclosure () -> Int?, _ expected: PeAccountMark, _ tooltip: String, _ what: String) async {
        func shown() -> AccountMark? {
            let cell = row().flatMap { tree.view(atColumn: 0, row: $0, makeIfNecessary: true) }
            return (cell as? FolderCell)?.mark ?? (cell as? HeadingCell)?.mark
        }
        let ok = await waitUntil(20) {
            let mark = shown()
            return mark?.shown == expected && mark?.toolTip == tooltip && mark?.accessibilityLabel() == tooltip && !tooltip.isEmpty
        }
        check(ok, "\(what) (\(shown()?.toolTip ?? "no mark"))")
    }

    /// the bar over the list says the status's words, with its button, once the window heard of the change
    func checkBar(_ status: AccountStatus, _ what: String) async {
        let ok = await waitUntil(20) {
            let bar = main.mailbox.accountBarText
            return bar.text == status.bar && bar.button == status.button && !bar.text.isEmpty && !bar.button.isEmpty
        }
        let bar = main.mailbox.accountBarText
        check(ok, "\(what) (\(bar.text) [\(bar.button)])")
    }

    /// the sign-in page the app opened (written to the test's file in place of the browser), taken
    func signInPage() async -> String? {
        let file = out.appendingPathComponent("sign-in-page.txt")
        let page = await waitFor(30) { try? String(contentsOf: file, encoding: .utf8) }
        try? FileManager.default.removeItem(at: file)
        return page?.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// what the browser does with the provider's page: ImapKit's client that always allows sends it back to the app
    func follow(_ page: String?) async {
        guard let page, let url = URL(string: page) else {
            check(false, "the app opened a sign-in page")
            return
        }
        _ = try? await URLSession.shared.data(from: url)
    }
}
