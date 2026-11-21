// The deep test's driver of the Mac app (docs/deep-test-plan.md, core/crates/pe-deep/src/driver.rs): the UI test's
// host started with --deep by the conductor, with the store, passwords in memory and ImapKit's certificate it names.
// It reads one request a line from standard input, does it as a hand does (a row of the tree or the list selected, a
// menu command), and answers with a line that starts with `DEEP ` and a JSON object. Only the UI test's executable has
// it: the app's own does not.
import AppKit
import CInboxClassic

@MainActor
func runDeepDriver(_ arguments: [String]) -> Never {
    var store = "build/deep/mac/app/store.db"
    var cert = ""
    var rest = arguments.makeIterator()
    while let argument = rest.next() {
        switch argument {
        case "--store": store = rest.next() ?? store
        case "--pin-certificate": cert = rest.next() ?? cert
        default: break
        }
    }
    NSApplication.shared.setActivationPolicy(.regular)
    TestHooks.testing = true
    TestHooks.addsAccounts = true
    // a question or a note the app shows (nothing to undo, delete for good, empty the folder) answered with its first
    // button, as a user who goes on does
    TestHooks.modalOpened = { window in
        after(0.3) {
            if NSApp.modalWindow === window {
                NSApp.stopModal(withCode: .alertFirstButtonReturn)
            }
        }
    }
    Languages.apply("en")
    let delegate = AppDelegate(Arguments(["InboxClassic", "--store", store, "--memory-passwords", "--pin-certificate", cert]))
    NSApp.delegate = delegate
    delegate.applicationDidFinishLaunching(Notification(name: NSApplication.didFinishLaunchingNotification))
    delegate.layoutMode = PE_LAYOUT_MODE_CLASSIC
    let driver = DeepDriver(delegate: delegate)
    // requests read off the main thread, each handled on it in turn
    Thread.detachNewThread {
        while let line = readLine() {
            let done = DispatchSemaphore(value: 0)
            onMain {
                Task { @MainActor in
                    await driver.handle(line)
                    done.signal()
                }
            }
            done.wait()
            if driver.quitting { break }
        }
        onMain { exit(0) }
    }
    NSApp.run()
    exit(0)
}

@MainActor
final class DeepDriver {
    let delegate: AppDelegate
    var accounts: [(name: String, id: Int64)] = []
    var quitting = false
    var main: MainWindow { delegate.main }
    var mailbox: Mailbox { main.mailbox }
    var core: Core { main.core }

    init(delegate: AppDelegate) {
        self.delegate = delegate
    }

    func reply(_ value: [String: Any]) {
        let data = (try? JSONSerialization.data(withJSONObject: value)) ?? Data("{\"ok\":false}".utf8)
        print("DEEP " + String(decoding: data, as: UTF8.self))
        fflush(stdout)
    }

    func handle(_ line: String) async {
        guard let data = line.data(using: .utf8),
              let request = (try? JSONSerialization.jsonObject(with: data)) as? [String: Any] else {
            reply(["ok": false, "error": "not a request: \(line)"])
            return
        }
        do {
            var answer = try await respond(request)
            answer["ok"] = true
            reply(answer)
        } catch let error as DeepError {
            reply(["ok": false, "error": error.text])
        } catch {
            reply(["ok": false, "error": "\(error)"])
        }
    }

    struct DeepError: Error {
        let text: String
        init(_ text: String) { self.text = text }
    }

    func respond(_ request: [String: Any]) async throws -> [String: Any] {
        if request["quit"] != nil {
            quitting = true
            return [:]
        }
        if let start = request["start"] as? [String: Any] {
            try await startAccounts(start)
            return [:]
        }
        if let seconds = request["settle"] as? Double {
            try await settle(seconds)
            return [:]
        }
        if request["observe"] != nil {
            return ["seen": observe()]
        }
        if request["health"] != nil {
            return [:]
        }
        if let path = request["screenshot"] as? String {
            if let frame = main.window.contentView?.superview,
               let rep = frame.bitmapImageRepForCachingDisplay(in: frame.bounds) {
                frame.cacheDisplay(in: frame.bounds, to: rep)
                try? rep.representation(using: .png, properties: [:])?.write(to: URL(fileURLWithPath: path))
            }
            return [:]
        }
        guard let act = request["act"] as? String else { throw DeepError("not an act") }
        try await perform(act, request)
        return [:]
    }

    // ---- accounts ----

    func startAccounts(_ start: [String: Any]) async throws {
        core.downloadAhead = PE_DOWNLOAD_AHEAD_NEVER
        // a message sent goes at once
        pe_set_send_delay_index(core.handle, 0)
        // one row a message, as the conductor starts: Group asks for conversations
        delegate.groupByConversation = false
        for account in start["accounts"] as? [[String: Any]] ?? [] {
            let text = { (key: String) in account[key] as? String ?? "" }
            let port = { (key: String) in UInt16(account[key] as? Int ?? 0) }
            let id: Int64 = text("name").withCString { name in
                text("email").withCString { email in
                    text("username").withCString { user in
                        "127.0.0.1".withCString { host in
                            // ImapKit's SMTP server takes AUTH after STARTTLS only
                            var settings = PeAccountSettings(name: name, email: email, username: user, imap_host: host,
                                                             imap_port: port("imap"), imap_security: PE_SECURITY_PLAIN,
                                                             smtp_host: host, smtp_port: port("smtp"),
                                                             smtp_security: PE_SECURITY_START_TLS)
                            return text("password").withCString { pe_account_add(core.handle, &settings, $0) }
                        }
                    }
                }
            }
            guard id > 0 else { throw DeepError("the account \(text("name")) could not be added") }
            _ = text("name").withCString { pe_account_set_name(core.handle, id, $0) }
            accounts.append((text("name"), id))
            core.sync(id)
        }
        mailbox.reload()
        try await settle(1800)
    }

    func accountName(_ id: Int64) -> String {
        accounts.first { $0.id == id }?.name ?? ""
    }

    /// a folder's path as the user sees it, `/` between levels
    func userPath(_ path: String) -> String {
        path.withCString { taken(pe_folder_path_decoded($0)) } ?? path
    }

    func folderId(_ account: String, _ path: String) throws -> Int64 {
        guard let id = accounts.first(where: { $0.name == account })?.id,
              let folder = core.folders(id).first(where: { userPath($0.path) == path }) else {
            throw DeepError("no folder \(account)/\(path)")
        }
        return folder.id
    }

    func place(_ folder: Int64) -> (account: String, path: String)? {
        guard let info = mailbox.info(ofFolder: folder) else { return nil }
        return (accountName(info.account), userPath(info.path))
    }

    // ---- the tree ----

    /// every node of the tree, shown or under a closed row
    func nodes() -> [Mailbox.TreeNode] {
        func all(_ nodes: [Mailbox.TreeNode]) -> [Mailbox.TreeNode] { nodes.flatMap { [$0] + all($0.children) } }
        let tree = mailbox.tree
        let top = (0..<mailbox.outlineView(tree, numberOfChildrenOfItem: nil)).compactMap {
            mailbox.outlineView(tree, child: $0, ofItem: nil) as? Mailbox.TreeNode
        }
        return all(top)
    }

    func node(for list: [String: Any]?, or kind: String?) throws -> Mailbox.TreeNode {
        let wanted: (TreeRow) -> Bool
        switch kind {
        case "inboxes": wanted = { $0.list == PE_TREE_LIST_ALL_INBOXES }
        case "flagged": wanted = { $0.list == PE_TREE_LIST_FLAGGED }
        case "sent": wanted = { $0.list == PE_TREE_LIST_ALL_SENT }
        case "drafts": wanted = { $0.list == PE_TREE_LIST_ALL_DRAFTS }
        default:
            let id = try folderId(list?["account"] as? String ?? "", list?["path"] as? String ?? "")
            wanted = { $0.list == PE_TREE_LIST_FOLDER && $0.folder == id }
        }
        guard let node = nodes().first(where: { wanted($0.row) }) else { throw DeepError("not in the folder list") }
        return node
    }

    /// the row of `node` clicked, the rows above it opened first
    func click(_ node: Mailbox.TreeNode) {
        var above: [Mailbox.TreeNode] = []
        var parent = node.parent
        while let up = parent {
            above.insert(up, at: 0)
            parent = up.parent
        }
        let tree = mailbox.tree
        above.forEach { tree.expandItem($0) }
        let row = tree.row(forItem: node)
        if row >= 0 {
            tree.selectRowIndexes(IndexSet(integer: row), byExtendingSelection: false)
        }
    }

    // ---- acts ----

    func perform(_ act: String, _ request: [String: Any]) async throws {
        let list = mailbox.list
        let rows = Int(mailbox.rows)
        let last = max(rows - 1, 0)
        let row = request["row"] as? Int ?? 0
        switch act {
        case "open":
            click(try node(for: request["list"] as? [String: Any], or: request["list"] as? String))
        case "scroll":
            list.scrollRowToVisible(min(row, last))
            list.scroll(NSPoint(x: 0, y: list.rect(ofRow: min(row, last)).minY))
        case "home":
            list.scroll(.zero)
        case "end":
            list.scrollRowToVisible(last)
        case "pagedown":
            let sight = list.rows(in: list.visibleRect)
            let to = min(sight.location + sight.length * (request["times"] as? Int ?? 1), last)
            list.scroll(NSPoint(x: 0, y: list.rect(ofRow: to).minY))
        case "click":
            guard row < rows else { throw DeepError("no row \(row) in a list of \(rows)") }
            list.window?.makeFirstResponder(list)
            list.selectRowIndexes(IndexSet(integer: row), byExtendingSelection: false)
            list.scrollRowToVisible(row)
        case "shiftclick":
            let from = list.selectedRowIndexes.first ?? 0
            let to = min(row, last)
            list.selectRowIndexes(IndexSet(integersIn: min(from, to)...max(from, to)), byExtendingSelection: false)
        case "selectall": delegate.perform(.selectAll)
        case "delete": delegate.perform(.delete)
        case "move":
            let target = request["list"] as? [String: Any]
            let to = try folderId(target?["account"] as? String ?? "", target?["path"] as? String ?? "")
            mailbox.moveSelection(to: to)
        case "flag": delegate.perform(.flag)
        case "read": delegate.perform(.markRead)
        case "unread": delegate.perform(.markUnread)
        case "sort":
            let field: PeSortField
            switch request["by"] as? String {
            case "subject": field = PE_SORT_FIELD_SUBJECT
            case "from": field = PE_SORT_FIELD_FROM
            case "size": field = PE_SORT_FIELD_SIZE
            default: field = PE_SORT_FIELD_DATE
            }
            mailbox.sortBy(field)
            mailbox.setAscending(request["ascending"] as? Bool ?? false)
        case "search":
            main.searchField.stringValue = request["text"] as? String ?? ""
            mailbox.find(request["text"] as? String ?? "")
        case "group": delegate.groupByConversation = request["on"] as? Bool ?? false
        case "unreadonly": delegate.hideRead = request["on"] as? Bool ?? false
        case "undo": delegate.perform(.undo)
        case "sync": delegate.perform(.sync)
        case "markallread": delegate.perform(.markAllRead)
        case "emptyfolder": delegate.perform(.emptyFolder)
        case "send":
            let before = ComposeWindow.open.count
            delegate.perform(.newMail)
            var compose: ComposeWindow?
            for _ in 0..<100 {
                if ComposeWindow.open.count > before, let last = ComposeWindow.open.last, last.window.isVisible {
                    compose = last
                    break
                }
                try? await Task.sleep(nanoseconds: 100_000_000)
            }
            guard let compose else { throw DeepError("New Mail opened no window") }
            // its editor's page ready, as a user starts typing once the window shows
            if let editor = deepViews(EditorView.self, in: compose.window.contentView).first {
                for _ in 0..<100 {
                    if (try? await editor.evaluateJavaScript("!!window.pe")) as? Bool == true { break }
                    try? await Task.sleep(nanoseconds: 100_000_000)
                }
            }
            compose.to.stringValue = request["to"] as? String ?? ""
            compose.subject.stringValue = request["subject"] as? String ?? ""
            compose.sendClicked()
            for _ in 0..<200 where compose.window.isVisible {
                try? await Task.sleep(nanoseconds: 100_000_000)
            }
            if compose.window.isVisible { throw DeepError("the message was not sent: its window stays open") }
        case "restart": throw DeepError("unsupported")
        default: throw DeepError("not an act: \(act)")
        }
        // taken in a turn of the run loop later
        try? await Task.sleep(nanoseconds: 50_000_000)
    }

    // ---- quiet ----

    /// nothing under way: the core quiet (no sync, no action), then a sync of every account as a barrier (it finishes
    /// after the commands queued before it), then the list not being read
    func settle(_ seconds: Double) async throws {
        func quiet() -> Bool { pe_quiet(core.handle) && !mailbox.listLoading }
        func wait() async -> Bool {
            let until = Date().addingTimeInterval(seconds)
            while Date() < until {
                if quiet() { return true }
                try? await Task.sleep(nanoseconds: 100_000_000)
            }
            return quiet()
        }
        guard await wait() else { throw DeepError("still busy after \(Int(seconds)) s") }
        pe_sync_barrier(core.handle)
        try? await Task.sleep(nanoseconds: 300_000_000)
        guard await wait() else { throw DeepError("still busy after \(Int(seconds)) s") }
        try? await Task.sleep(nanoseconds: 300_000_000)
        guard await wait() else { throw DeepError("still busy after \(Int(seconds)) s") }
    }

    // ---- what is seen ----

    func message(_ folder: Int64, _ uid: UInt64) -> [String: Any]? {
        guard let (account, path) = place(folder) else { return nil }
        return ["account": account, "path": path, "uid": uid]
    }

    func observe() -> [String: Any] {
        let list = mailbox.list
        let rows = Int(mailbox.rows)
        let sight = list.rows(in: list.visibleRect)
        var seen: [[String: Any]] = []
        if rows > 0 {
            for row in sight.location..<min(sight.location + sight.length, rows) {
                if let m = mailbox.row(row) {
                    seen.append(["row": row, "blank": false, "message": message(m.folder, m.uid) as Any,
                                 "subject": m.subject, "date": m.date ?? 0])
                } else {
                    seen.append(["row": row, "blank": true])
                }
            }
        }
        let shown: Any = mailbox.reader.uid != 0 ? (message(mailbox.reader.folder, mailbox.reader.uid) as Any) : NSNull()
        var listed: Any = NSNull()
        if let row = (mailbox.tree.item(atRow: mailbox.tree.selectedRow) as? Mailbox.TreeNode)?.row {
            switch row.list {
            case PE_TREE_LIST_ALL_INBOXES: listed = "inboxes"
            case PE_TREE_LIST_FLAGGED: listed = "flagged"
            case PE_TREE_LIST_ALL_SENT: listed = "sent"
            case PE_TREE_LIST_ALL_DRAFTS: listed = "drafts"
            case PE_TREE_LIST_FOLDER:
                if let (account, path) = place(row.folder) { listed = ["account": account, "path": path] }
            default: break
            }
        }
        let tree: [[Any]] = accounts.flatMap { account in
            core.folders(account.id).map { [account.name, userPath($0.path), $0.unread] }
        }
        return [
            "list": listed, "rows": rows, "sight": seen, "selected": Array(list.selectedRowIndexes), "shown": shown,
            "search": main.searchField.stringValue, "grouped": delegate.groupByConversation,
            "unreadOnly": delegate.hideRead, "tree": tree,
        ]
    }
}

/// the views of a kind under `root`
@MainActor
func deepViews<T: NSView>(_ kind: T.Type, in root: NSView?) -> [T] {
    guard let root else { return [] }
    let own: [T] = (root as? T).map { [$0] } ?? []
    return own + root.subviews.flatMap { deepViews(kind, in: $0) }
}
