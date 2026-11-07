// The Swift side of the Rust core (core/include/inbox_classic.h): its strings copied into Swift and given back with
// pe_string_free, its lists and views as classes that free their handle, and its events brought to the main thread.
// Nothing here parses data, that is the job of the core.
import CInboxClassic
import Foundation

/// A UTF-8 string of the core, nil as empty
func text(_ pointer: UnsafePointer<CChar>?) -> String {
    pointer.map { String(cString: $0) } ?? ""
}

/// A string the core returned for the caller to free: copied, then freed; nil for NULL
func taken(_ pointer: UnsafeMutablePointer<CChar>?) -> String? {
    guard let pointer else { return nil }
    defer { pe_string_free(pointer) }
    return String(cString: pointer)
}

/// C strings that live as long as this does, for the structs of the core that point to several
final class CStrings {
    private var kept: [UnsafeMutablePointer<CChar>] = []

    func add(_ value: String) -> UnsafePointer<CChar> {
        let copy = strdup(value)!
        kept.append(copy)
        return UnsafePointer(copy)
    }

    /// nil for an empty string
    func optional(_ value: String) -> UnsafePointer<CChar>? {
        value.isEmpty ? nil : add(value)
    }

    /// what `values` point to, as a C array of strings kept here too
    func array(_ values: [String]) -> UnsafePointer<UnsafePointer<CChar>?> {
        let pointers = UnsafeMutablePointer<UnsafePointer<CChar>?>.allocate(capacity: max(values.count, 1))
        for (i, value) in values.enumerated() {
            pointers[i] = add(value)
        }
        arrays.append(pointers)
        return UnsafePointer(pointers)
    }

    private var arrays: [UnsafeMutablePointer<UnsafePointer<CChar>?>] = []

    /// overwrites the strings (a password) before they are freed
    func wipe() {
        for pointer in kept {
            memset(pointer, 0, strlen(pointer))
        }
    }

    deinit {
        kept.forEach { free($0) }
        arrays.forEach { $0.deallocate() }
    }
}

/// An event of the core, copied off the worker thread it came on
struct CoreEvent {
    let kind: PeEventKind
    let account: Int64
    let folder: Int64
    let uid: UInt64
    let failure: PeFailureKind
    let message: String
    /// the Message-ID of a draft, for DraftSaved; the subject, for NewMail
    let detail: String
    /// how many messages, for NewMail
    let count: UInt64
}

/// Where the events go; a box the C callback finds through its context pointer
private final class EventSink {
    let deliver: (CoreEvent) -> Void
    init(_ deliver: @escaping (CoreEvent) -> Void) { self.deliver = deliver }
}

/// The C callback: on a worker thread, copies the event and hands it to the main thread, never waits
private let eventCallback: PeEventCallback = { context, event in
    guard let context, let event else { return }
    let sink = Unmanaged<EventSink>.fromOpaque(context).takeUnretainedValue()
    let copy = CoreEvent(
        kind: event.pointee.kind, account: event.pointee.account, folder: event.pointee.folder, uid: event.pointee.uid,
        failure: event.pointee.failure, message: text(event.pointee.message), detail: text(event.pointee.detail),
        count: event.pointee.count)
    onMain { sink.deliver(copy) }
}

/// Runs `block` on the main thread from the run loop, in its common modes: also while a modal window or a menu runs
/// its own loop. (A block of the main dispatch queue that runs a modal window holds up every other one until it
/// closes, the core's events and the windows' own work included, so nothing here goes through that queue.)
func onMain(_ block: @escaping @MainActor () -> Void) {
    let main = CFRunLoopGetMain()
    CFRunLoopPerformBlock(main, CFRunLoopMode.commonModes.rawValue) { MainActor.assumeIsolated { block() } }
    CFRunLoopWakeUp(main)
}

/// Runs `block` on the main thread after `seconds`, also while a modal window runs
func after(_ seconds: TimeInterval, _ block: @escaping @MainActor () -> Void) {
    let timer = Timer(timeInterval: seconds, repeats: false) { _ in MainActor.assumeIsolated { block() } }
    RunLoop.main.add(timer, forMode: .common)
}

/// The open core: one mail store, its accounts and their workers
final class Core {
    let handle: OpaquePointer
    private let sink: Unmanaged<EventSink>

    /// opens the store at `path`; nil when it (or the certificate file) can not be opened
    init?(path: String, memoryPasswords: Bool, certificate: String?, onEvent: @escaping (CoreEvent) -> Void) {
        let sink = Unmanaged.passRetained(EventSink(onEvent))
        let flags: UInt32 = memoryPasswords ? UInt32(PE_OPEN_MEMORY_PASSWORDS) : 0
        let opened: OpaquePointer? = path.withCString { path in
            if let certificate {
                return certificate.withCString { pe_core_open_with(path, flags, $0, eventCallback, sink.toOpaque()) }
            }
            return pe_core_open_with(path, flags, nil, eventCallback, sink.toOpaque())
        }
        guard let opened else {
            sink.release()
            return nil
        }
        handle = opened
        self.sink = sink
    }

    deinit {
        pe_core_close(handle)
        sink.release()
    }

    static var version: String { text(pe_version()) }

    // ---- accounts ----

    func accounts() -> [Account] {
        guard let list = pe_accounts(handle) else { return [] }
        defer { pe_account_list_free(list) }
        return (0..<pe_account_list_count(list)).compactMap { pe_account_list_get(list, $0).map { Account($0.pointee) } }
    }

    func folders(_ account: Int64) -> [Folder] {
        folderTree(account).folders
    }

    /// the folders of an account with the unread messages its row shows collapsed (not Junk E-mail or Deleted Items)
    func folderTree(_ account: Int64) -> (folders: [Folder], unread: UInt64) {
        guard let list = pe_folders(handle, account) else { return ([], 0) }
        defer { pe_folder_list_free(list) }
        let folders = (0..<pe_folder_list_count(list)).compactMap { pe_folder_list_get(list, $0).map { Folder($0.pointee) } }
        return (folders, pe_folder_list_unread(list))
    }

    func sync(_ account: Int64) { pe_sync(handle, account) }

    func syncAll() {
        accounts().forEach { sync($0.id) }
    }

    var inboxUnread: UInt64 { pe_inbox_unread(handle) }

    // ---- the message list ----

    /// the counts of a folder from its indexes
    func folderCounts(_ folder: Int64) -> (total: UInt64, unread: UInt64) {
        var total: UInt64 = 0
        var unread: UInt64 = 0
        pe_folder_counts(handle, folder, &total, &unread)
        return (total, unread)
    }

    /// what the main window selects when it opens: All Inboxes (two or more accounts) or the first account's Inbox,
    /// and the newest message (its folder, a uid of 0 when there is none)
    func startMessage() -> (allInboxes: Bool, folder: Int64, uid: UInt64)? {
        var allInboxes = false
        var folder: Int64 = 0
        var uid: UInt64 = 0
        return pe_start_message(handle, &allInboxes, &folder, &uid) ? (allInboxes, folder, uid) : nil
    }

    /// what a search finds
    func messageCount(_ search: Search) -> (total: UInt64, unread: UInt64) {
        var total: UInt64 = 0
        var unread: UInt64 = 0
        _ = search.with { pe_message_count(handle, $0, &total, &unread) }
        return (total, unread)
    }

    /// how many rows the list has: one a message, or grouped by conversation one a conversation and the messages
    /// under the open ones
    func listRows(_ search: Search) -> UInt64 {
        search.with { pe_list_rows(handle, $0) }
    }

    /// the conversation that hides the message `uid` of `folder` in the list (collapsed, the message not its first),
    /// which the list opens to select it; 0 when the message has a row of its own
    func hiddenThread(_ search: Search, folder: Int64, uid: UInt64) -> Int64 {
        search.with { pe_message_hidden_thread(handle, $0, folder, uid) }
    }

    /// whether the list names whom its messages went to (Sent Items, Drafts): the person column is then To
    func listsRecipients(_ search: Search) -> Bool {
        search.with { pe_lists_recipients(handle, $0) }
    }

    func messages(_ search: Search, sort: PeSortField, ascending: Bool, offset: UInt64, limit: UInt64) -> [Message] {
        search.with { search in
            guard let list = pe_messages(handle, search, sort, ascending, offset, limit) else { return [] }
            defer { pe_message_list_free(list) }
            return (0..<pe_message_list_count(list)).compactMap { pe_message_list_get(list, $0).map { Message($0.pointee) } }
        }
    }

    /// where a message is in the list, -1 when it is not there
    func messageIndex(_ search: Search, sort: PeSortField, ascending: Bool, folder: Int64, uid: UInt64) -> Int64 {
        search.with { pe_message_index(handle, $0, sort, ascending, folder, uid) }
    }

    /// the messages before and after the message `uid` of `folder` in the list, in one pass: what Previous and Next
    /// show, each nil at its end; nil as a whole when the message is not in the list (any more)
    func neighbours(_ search: Search, sort: PeSortField, ascending: Bool, folder: Int64, uid: UInt64)
        -> (previous: (folder: Int64, uid: UInt64)?, next: (folder: Int64, uid: UInt64)?)? {
        var previousFolder: Int64 = 0
        var previousUid: UInt64 = 0
        var nextFolder: Int64 = 0
        var nextUid: UInt64 = 0
        let found = search.with {
            pe_message_neighbours(handle, $0, sort, ascending, folder, uid, &previousFolder, &previousUid, &nextFolder, &nextUid)
        }
        guard found else { return nil }
        return (previousFolder != 0 ? (previousFolder, previousUid) : nil, nextFolder != 0 ? (nextFolder, nextUid) : nil)
    }

    /// the first unread message after the message `uid` of `folder` (0 for from the top) in the list; nil when none is
    func nextUnread(_ search: Search, sort: PeSortField, ascending: Bool, folder: Int64, uid: UInt64) -> NextUnread {
        var nextFolder: Int64 = 0
        var nextUid: UInt64 = 0
        var question: UnsafeMutablePointer<CChar>?
        let step = search.with {
            pe_next_unread_step(handle, $0, sort, ascending, folder, uid, &nextFolder, &nextUid, &question)
        }
        let asked = taken(question) ?? ""
        switch step {
        case PE_NEXT_UNREAD_MESSAGE: return .message(folder: nextFolder, uid: nextUid)
        case PE_NEXT_UNREAD_ASK: return .ask(folder: nextFolder, question: asked)
        default: return .none
        }
    }

    /// the conversations of the list with more than one message there: what Expand All opens
    func threadsWithReplies(_ search: Search) -> [Int64] {
        search.with { search in
            guard let list = pe_threads_with_replies(handle, search) else { return [] }
            defer { pe_thread_list_free(list) }
            return (0..<pe_thread_list_count(list)).map { pe_thread_list_get(list, $0) }
        }
    }

    /// whether the message `uid` is (still) in `folder`
    func messageExists(folder: Int64, uid: UInt64) -> Bool {
        pe_message_exists(handle, folder, uid)
    }

    /// where the messages of `selection` are in the list now, the rows to select again
    func positions(of selection: OpaquePointer, in search: Search, sort: PeSortField, ascending: Bool) -> IndexSet {
        guard let found = search.with({ pe_selection_positions(handle, selection, $0, sort, ascending) }) else { return [] }
        defer { pe_positions_free(found) }
        return IndexSet((0..<pe_positions_count(found)).map { Int(pe_positions_get(found, $0)) })
    }

    /// `action` on the messages of `selection`: what the status bar says, or why not
    func act(_ selection: OpaquePointer, _ action: PeAction, to: Int64 = 0) -> Result<String, Refusal> {
        var reason: UnsafeMutablePointer<CChar>?
        if let done = taken(pe_selection_act(handle, selection, action, to, &reason)) {
            return .success(done)
        }
        return .failure(Refusal(taken(reason) ?? Text.uiMessagesNotChanged.text))
    }

    /// what Edit > Undo takes back, "Undo Move"; nil when nothing
    var undoLabel: String? { taken(pe_undo_label(handle)) }

    func undo() -> Result<String, Refusal> {
        var reason: UnsafeMutablePointer<CChar>?
        if let done = taken(pe_undo(handle, &reason)) {
            return .success(done)
        }
        return .failure(Refusal(taken(reason) ?? Text.nothingToUndo.text))
    }

    var unindexedCount: UInt64 { pe_search_unindexed_count(handle) }

    static func searchPlace(_ text: String) -> String {
        text.withCString { taken(pe_search_place($0)) } ?? ""
    }
}

/// What Next Unread does next, as the core decides: select a message of the list, ask before going on to the folder
/// with unread mail (a heading, a blank line, the question), or nothing is left
enum NextUnread {
    case message(folder: Int64, uid: UInt64)
    case ask(folder: Int64, question: String)
    case none
}

extension Text {
    /// a command's word as the title of the window it opens, without its menu letter and its trailing dots
    var title: String {
        guard let title = pe_text_title(rawValue) else { return "" }
        defer { pe_string_free(title) }
        return String(cString: title)
    }
}

/// Why the core did not do something, in its words
struct Refusal: Error {
    let reason: String
    init(_ reason: String) { self.reason = reason }
}

/// What the message list shows: a folder, or words searched in every folder (folder 0)
struct Search {
    var folder: Int64
    /// with `folder` 0: every account's Inbox rather than every folder
    var allInboxes = false
    var text: String
    /// one row a conversation, the conversations `expanded` open
    var threads = false
    var expanded: [Int64] = []

    func with<T>(_ body: (UnsafePointer<PeSearch>) -> T) -> T {
        text.withCString { words in
            expanded.withUnsafeBufferPointer { open in
                var search = PeSearch(folder: folder, all_inboxes: allInboxes, show: PE_SHOW_ALL, text: words,
                                      threads: threads, expanded: open.baseAddress, expanded_count: open.count)
                return withUnsafePointer(to: &search) { body($0) }
            }
        }
    }
}

struct Account {
    let id: Int64
    let name: String
    let email: String
    let oauth: PeOAuthProvider
    let app: Int64
    let signsInWith: String
    let imapHost: String
    /// "Name <address>"
    let label: String
    /// what the folder tree shows for it
    let title: String

    init(_ account: PeAccount) {
        id = account.id
        name = text(account.name)
        email = text(account.email)
        oauth = account.oauth
        app = account.app
        signsInWith = text(account.signs_in_with)
        imapHost = text(account.imap_host)
        label = text(account.label)
        title = text(account.title)
    }
}

struct Folder {
    let id: Int64
    let account: Int64
    let path: String
    let name: String
    let depth: Int
    let fixed: Bool
    /// Deleted Items or Junk E-mail: Empty Folder applies when it has messages
    let emptiable: Bool
    let specialUse: PeSpecialUse
    let selectable: Bool
    let total: UInt64
    let unread: UInt64
    /// the unread messages of the folders under it, which its row shows while collapsed
    let unreadBelow: UInt64

    init(_ folder: PeFolder) {
        id = folder.id
        account = folder.account
        path = text(folder.path)
        name = text(folder.name)
        depth = Int(folder.depth)
        fixed = folder.fixed
        emptiable = folder.emptiable
        specialUse = folder.special_use
        selectable = folder.selectable
        total = folder.total
        unread = folder.unread
        unreadBelow = folder.unread_below
    }
}

struct Message {
    let folder: Int64
    let uid: UInt64
    let date: Int64?
    let size: UInt64
    let subject: String
    let from: String
    let fromAddress: String
    let recipients: String
    let seen: Bool
    let flagged: Bool
    /// the colour of its flag, Apple Mail's (1 red to 7 gray), 0 when not flagged
    let flagColor: UInt8
    let answered: Bool
    let hasAttachments: Bool
    /// bold: unread, or a collapsed conversation's row with an unread message (the core decides)
    let bold: Bool
    /// its place in a list grouped by conversation: the conversation (0 when not grouped), 0 for the conversation's
    /// row and 1 for a message under it, how many messages the conversation has there and how many are unread, and
    /// whether it is open
    let thread: Int64
    let threadDepth: UInt32
    let threadCount: UInt32
    let threadUnread: UInt32
    let threadExpanded: Bool
    /// the row opens and closes its conversation (a disclosure triangle)
    let opens: Bool
    /// the row stands for all of its conversation's messages, not shown under it
    let collapsed: Bool

    init(_ message: PeMessage) {
        folder = message.folder
        uid = message.uid
        date = message.has_date ? message.date : nil
        size = message.size
        subject = text(message.subject)
        from = text(message.from)
        fromAddress = text(message.from_address)
        recipients = text(message.recipients)
        seen = message.seen
        flagged = message.flagged
        flagColor = message.flag_color
        answered = message.answered
        hasAttachments = message.has_attachments
        thread = message.thread
        threadDepth = message.thread_depth
        threadCount = message.thread_count
        threadUnread = message.thread_unread
        threadExpanded = message.thread_expanded
        bold = message.bold
        opens = message.thread_opens
        collapsed = message.thread_collapsed
    }
}

/// A message view of the core: the header, the sanitized document, the attachments; freed with it
final class MessageView {
    let handle: OpaquePointer

    init?(_ handle: OpaquePointer?) {
        guard let handle else { return nil }
        self.handle = handle
    }

    deinit { pe_message_view_free(handle) }

    var info: UnsafePointer<PeMessageInfo>? { pe_message_view_info(handle) }

    func attachment(_ index: Int) -> (name: String, size: UInt64)? {
        guard let attachment = pe_message_view_attachment(handle, index) else { return nil }
        return (text(attachment.pointee.filename), attachment.pointee.size)
    }
}

/// A draft of the core (a reply, a forward, a saved draft, a mailto: link); freed with it
final class Draft {
    let handle: OpaquePointer

    init?(_ handle: OpaquePointer?) {
        guard let handle else { return nil }
        self.handle = handle
    }

    deinit { pe_draft_free(handle) }

    var info: UnsafePointer<PeDraftInfo>? { pe_draft_info(handle) }
}

/// Bytes the core returned (an attachment, a message source), freed with pe_bytes_free
func takenBytes(_ data: UnsafeMutablePointer<UInt8>?, _ length: Int) -> Data? {
    guard let data else { return nil }
    defer { pe_bytes_free(data, length) }
    return Data(bytes: data, count: length)
}

/// The words the windows show for a size, the core's
func formatSize(_ bytes: UInt64) -> String {
    taken(pe_format_size(bytes)) ?? Text.sizeBytes.text(["count": bytes])
}

/// A date as the user's settings write it, short date and time
func formatDate(_ seconds: Int64) -> String {
    let formatter = DateFormatter()
    formatter.dateStyle = .short
    formatter.timeStyle = .short
    return formatter.string(from: Date(timeIntervalSince1970: TimeInterval(seconds)))
}

/// The time of day now, without seconds
func timeNow() -> String {
    DateFormatter.localizedString(from: Date(), dateStyle: .none, timeStyle: .short)
}

/// The time of day of `seconds` since the Unix epoch, without seconds
func timeOfDay(_ seconds: Int64) -> String {
    DateFormatter.localizedString(from: Date(timeIntervalSince1970: TimeInterval(seconds)), dateStyle: .none, timeStyle: .short)
}
