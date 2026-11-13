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
    /// the Message-ID of a draft, for DraftSaved; the notification's text, for NewMail (`message` its title)
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

/// The locale of the event cards' days and times: the windows' (set with their language), read on worker threads
nonisolated(unsafe) var instantLocale = Locale.current

/// The days and times of the event cards, as the windows write dates: the full date or the short time, in the reader's
/// time zone, or as written (UTC) when floating. Called by the core on a worker thread.
private let formatInstant: PeFormatInstant = { _, seconds, floating, time, out, capacity in
    guard let out else { return 0 }
    let formatter = DateFormatter()
    formatter.locale = instantLocale
    formatter.timeZone = floating ? TimeZone(secondsFromGMT: 0)! : TimeZone.current
    formatter.dateStyle = time ? .none : .full
    formatter.timeStyle = time ? .short : .none
    let words = Array(formatter.string(from: Date(timeIntervalSince1970: TimeInterval(seconds))).utf8)
    let length = min(words.count, capacity)
    words.withUnsafeBytes { bytes in
        UnsafeMutableRawPointer(out).copyMemory(from: bytes.baseAddress!, byteCount: length)
    }
    return length
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
        pe_set_instant_format(formatInstant, nil)
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

    // ---- pictures ----

    /// the senders whose pictures load by themselves, as Settings lists them (an address, or "Everyone at shop.com")
    func trustedSenders() -> [(id: Int64, label: String)] {
        guard let list = pe_trusted_senders(handle) else { return [] }
        defer { pe_trusted_sender_list_free(list) }
        return (0..<pe_trusted_sender_list_count(list)).compactMap { index in
            pe_trusted_sender_list_get(list, index).map { ($0.pointee.id, text($0.pointee.label)) }
        }
    }

    /// trusts `value`, an address or (`domain`) a whole domain; false for a value that is neither
    @discardableResult
    func trustSender(_ value: String, domain: Bool) -> Bool {
        value.withCString { pe_trust_sender(handle, $0, domain) }
    }

    /// Settings' "Download pictures in all messages"
    var alwaysLoadPictures: Bool {
        get { pe_always_load_pictures(handle) }
        set { pe_set_always_load_pictures(handle, newValue) }
    }

    /// Settings' "Download messages ahead"
    var downloadAhead: PeDownloadAhead {
        get { pe_download_ahead(handle) }
        set { pe_set_download_ahead(handle, newValue) }
    }

    /// Settings' "Downloaded messages kept for each account": its place among `Core.downloadLimits`
    var downloadLimitIndex: Int {
        get { pe_download_limit_index(handle) }
        set { pe_set_download_limit_index(handle, newValue) }
    }

    /// The limits of downloaded messages Settings offers, in words ("500 MB", "2 GB")
    static var downloadLimits: [String] {
        (0..<pe_download_limit_count()).map { taken(pe_download_limit_text($0)) ?? "" }
    }

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

    /// each account's Inbox, in the accounts' order, named as the account is: the rows under All Inboxes
    func inboxes() -> [SpecialFolder] {
        guard let list = pe_special_folders(handle, PE_SPECIAL_FOLDER_KIND_INBOX) else { return [] }
        defer { pe_special_folder_list_free(list) }
        return (0..<pe_special_folder_list_count(list)).compactMap {
            pe_special_folder_list_get(list, $0).map { SpecialFolder($0.pointee) }
        }
    }

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

    /// the counts of the status bar: the messages of the list (grouped or not, all of them) and how many are unread
    func counts(_ view: ListView) -> (total: UInt64, unread: UInt64) {
        var total: UInt64 = 0
        var unread: UInt64 = 0
        _ = pe_list_view_counts(handle, view.handle, &total, &unread)
        return (total, unread)
    }

    /// how many rows the list has: one a message, or grouped by conversation one a conversation and the messages
    /// under the open ones
    func rowCount(_ view: ListView) -> UInt64 {
        pe_list_view_row_count(handle, view.handle)
    }

    /// the conversation that hides the message `uid` of `folder` in the list opened, to show or select the message;
    /// false when it has a row of its own already (the list is the same)
    func reveal(_ view: ListView, folder: Int64, uid: UInt64) -> Bool {
        pe_list_view_reveal(handle, view.handle, folder, uid)
    }

    /// View > Expand All Conversations: every conversation of the list with more than one message there opened; false
    /// when that changed nothing
    func expandAll(_ view: ListView) -> Bool {
        pe_list_view_expand_all(handle, view.handle)
    }

    /// whether the list names whom its messages went to (Sent Items, Drafts): the person column is then To
    func listsRecipients(_ view: ListView) -> Bool {
        pe_list_view_lists_recipients(handle, view.handle)
    }

    func messages(_ view: ListView, offset: UInt64, limit: UInt64) -> [Message] {
        guard let list = pe_list_view_messages(handle, view.handle, offset, limit) else { return [] }
        defer { pe_message_list_free(list) }
        return (0..<pe_message_list_count(list)).compactMap { pe_message_list_get(list, $0).map { Message($0.pointee) } }
    }

    /// where a message is in the list (its conversation's row while that is collapsed), -1 when it is not there
    func messageIndex(_ view: ListView, folder: Int64, uid: UInt64) -> Int64 {
        pe_list_view_index(handle, view.handle, folder, uid)
    }

    /// the messages before and after the message `uid` of `folder` in the list, in one pass: what Previous and Next
    /// show, each nil at its end; nil as a whole when the message is not in the list (any more)
    func neighbours(_ view: ListView, folder: Int64, uid: UInt64)
        -> (previous: (folder: Int64, uid: UInt64)?, next: (folder: Int64, uid: UInt64)?)? {
        var previousFolder: Int64 = 0
        var previousUid: UInt64 = 0
        var nextFolder: Int64 = 0
        var nextUid: UInt64 = 0
        guard pe_list_view_neighbours(handle, view.handle, folder, uid, &previousFolder, &previousUid, &nextFolder,
                                      &nextUid) else { return nil }
        return (previousFolder != 0 ? (previousFolder, previousUid) : nil, nextFolder != 0 ? (nextFolder, nextUid) : nil)
    }

    /// the first unread message after the message `uid` of `folder` (0 for from the top) in the list; nil when none is
    func nextUnread(_ view: ListView, folder: Int64, uid: UInt64) -> NextUnread {
        var nextFolder: Int64 = 0
        var nextUid: UInt64 = 0
        var question: UnsafeMutablePointer<CChar>?
        let step = pe_list_view_next_unread_step(handle, view.handle, folder, uid, &nextFolder, &nextUid, &question)
        let asked = taken(question) ?? ""
        switch step {
        case PE_NEXT_UNREAD_MESSAGE: return .message(folder: nextFolder, uid: nextUid)
        case PE_NEXT_UNREAD_ASK: return .ask(folder: nextFolder, question: asked)
        default: return .none
        }
    }

    /// whether the message `uid` is (still) in `folder`
    func messageExists(folder: Int64, uid: UInt64) -> Bool {
        pe_message_exists(handle, folder, uid)
    }

    /// `selection` filled with the messages of the rows `ranges` of the list: a collapsed conversation's row stands
    /// for all of its messages
    func select(_ ranges: [Range<Int>], of view: ListView, into selection: OpaquePointer) {
        let starts = ranges.map { UInt64($0.lowerBound) }
        let ends = ranges.map { UInt64($0.upperBound) }
        _ = pe_list_view_select_ranges(handle, view.handle, selection, starts, ends, starts.count)
    }

    /// where the messages of `selection` are in the list now, the rows to select again
    func positions(of selection: OpaquePointer, in view: ListView) -> IndexSet {
        guard let found = pe_list_view_positions(handle, view.handle, selection) else { return [] }
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

/// What a message list shows, kept by the core: the folder (or All Inboxes), the words searched for, what is shown,
/// the order, grouping and the conversations open. The handle is freed with this.
final class ListView {
    let handle: OpaquePointer

    init() {
        handle = pe_list_view_new()!
    }

    private init(handle: OpaquePointer) {
        self.handle = handle
    }

    deinit {
        pe_list_view_free(handle)
    }

    /// a copy, its open conversations too: what a message window goes through
    func copy() -> ListView? {
        pe_list_view_clone(handle).map { ListView(handle: $0) }
    }

    /// the folder, or with `folder` 0 every Inbox (`allInboxes`) or nothing; false when it was shown already
    @discardableResult
    func setScope(folder: Int64, allInboxes: Bool) -> Bool {
        pe_list_view_set_scope(handle, folder, allInboxes)
    }

    /// the words typed in the search box, which search every folder; false when they are the same
    @discardableResult
    func setText(_ text: String) -> Bool {
        text.withCString { pe_list_view_set_text(handle, $0) }
    }

    func setSort(_ sort: PeSortField, ascending: Bool) {
        pe_list_view_set_sort(handle, sort, ascending)
    }

    /// one row a conversation, or one a message; false when it was so already
    @discardableResult
    func setGrouped(_ grouped: Bool) -> Bool {
        pe_list_view_set_grouped(handle, grouped)
    }

    func setHideIgnored(_ hide: Bool) {
        pe_list_view_set_hide_ignored(handle, hide)
    }

    /// View > Hide Read Messages: the unread messages only, a message read staying listed until the folder changes
    func setUnreadOnly(_ on: Bool) {
        pe_list_view_set_show(handle, on ? PE_SHOW_UNREAD : PE_SHOW_ALL)
    }

    var searching: Bool { pe_list_view_searching(handle) }
    /// a search or All Inboxes: messages of several folders
    var severalFolders: Bool { pe_list_view_several_folders(handle) }
    /// a folder, All Inboxes or words: not an account's own item
    var active: Bool { pe_list_view_active(handle) }
    var grouped: Bool { pe_list_view_grouped(handle) }

    func isExpanded(_ thread: Int64) -> Bool {
        pe_list_view_is_expanded(handle, thread)
    }

    /// the conversation `thread` opened; false when it was open or the list is not grouped
    func expand(_ thread: Int64) -> Bool {
        pe_list_view_expand(handle, thread)
    }

    /// the conversation `thread` closed; false when it was not open
    func collapse(_ thread: Int64) -> Bool {
        pe_list_view_collapse(handle, thread)
    }

    /// View > Collapse All Conversations; false when none was open
    func collapseAll() -> Bool {
        pe_list_view_collapse_all(handle)
    }

    /// whether `action` (to `to`) on the messages of `summary` takes them out of the list
    func leavesList(_ summary: PeSelectionSummary, _ action: PeAction, to: Int64 = 0) -> Bool {
        var summary = summary
        return pe_list_view_leaves_list(handle, &summary, action, to)
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
    /// its own name for the folder list ("Gmail"), empty for none: the Account name of its Properties
    let accountName: String

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
        accountName = text(account.account_name)
    }
}

/// An account's folder of a special use (its Inbox), with the account's title and the folder's unread messages
struct SpecialFolder {
    let account: Int64
    let folder: Int64
    let name: String
    /// "Inbox - Gmail", for the folder bar and the title
    let title: String
    let unread: UInt64

    init(_ row: PeSpecialFolder) {
        account = row.account
        folder = row.folder
        name = text(row.name)
        title = text(row.title)
        unread = row.unread
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
    /// a notice that a message was not delivered, or not yet: its mark in the attachment column's place
    let bounce: Bool
    /// its conversation watched (the Watch column's glasses) or ignored (the Watch column's sign)
    let mark: PeThreadMark
    /// the row grey, its conversation ignored (the core decides)
    let dimmed: Bool
    /// the first words of what the sender wrote, empty until the core has read them (text from the sender: shown as
    /// text only)
    let snippet: String

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
        bounce = message.bounce
        mark = message.mark
        dimmed = message.dimmed
        snippet = text(message.snippet)
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

/// A date of the column list's rows, short as the core says for its age: the time today, the weekday this week, the
/// day and month this year, the date before
func shortDate(_ seconds: Int64) -> String {
    let date = Date(timeIntervalSince1970: TimeInterval(seconds))
    let offset = Int64(TimeZone.current.secondsFromGMT(for: Date()))
    let formatter = DateFormatter()
    switch pe_date_style(seconds, Int64(Date().timeIntervalSince1970), offset) {
    case PE_DATE_STYLE_TIME: formatter.timeStyle = .short
    case PE_DATE_STYLE_WEEKDAY: formatter.setLocalizedDateFormatFromTemplate("EEEE")
    case PE_DATE_STYLE_DAY_MONTH: formatter.setLocalizedDateFormatFromTemplate("dMMM")
    default: formatter.dateStyle = .short
    }
    return formatter.string(from: date)
}

/// The time of day now, without seconds
func timeNow() -> String {
    DateFormatter.localizedString(from: Date(), dateStyle: .none, timeStyle: .short)
}

/// The time of day of `seconds` since the Unix epoch, without seconds
func timeOfDay(_ seconds: Int64) -> String {
    DateFormatter.localizedString(from: Date(timeIntervalSince1970: TimeInterval(seconds)), dateStyle: .none, timeStyle: .short)
}
