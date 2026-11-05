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

    /// what the main window selects when it opens: the first account's Inbox and its newest message (0 when empty)
    func startMessage() -> (folder: Int64, uid: UInt64)? {
        var folder: Int64 = 0
        var uid: UInt64 = 0
        return pe_start_message(handle, &folder, &uid) ? (folder, uid) : nil
    }

    /// what a search finds
    func messageCount(_ search: Search) -> (total: UInt64, unread: UInt64) {
        var total: UInt64 = 0
        var unread: UInt64 = 0
        _ = search.with { pe_message_count(handle, $0, &total, &unread) }
        return (total, unread)
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

    var unindexedCount: UInt64 { pe_search_unindexed_count(handle) }

    static func searchPlace(_ text: String) -> String {
        text.withCString { taken(pe_search_place($0)) } ?? ""
    }
}

/// What the message list shows: a folder, or words searched in every folder (folder 0)
struct Search {
    var folder: Int64
    var text: String

    func with<T>(_ body: (UnsafePointer<PeSearch>) -> T) -> T {
        text.withCString { words in
            var search = PeSearch(folder: folder, show: PE_SHOW_ALL, text: words)
            return withUnsafePointer(to: &search) { body($0) }
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
        specialUse = folder.special_use
        selectable = folder.selectable
        total = folder.total
        unread = folder.unread
        unreadBelow = folder.unread_below
    }

    /// the name mail programs of the Outlook Express kind give a special folder, the folder's own name otherwise
    var displayName: String {
        switch specialUse {
        case PE_SPECIAL_USE_INBOX: return "Inbox"
        case PE_SPECIAL_USE_SENT: return "Sent Items"
        case PE_SPECIAL_USE_TRASH: return "Deleted Items"
        case PE_SPECIAL_USE_DRAFTS: return "Drafts"
        case PE_SPECIAL_USE_JUNK: return "Junk E-mail"
        default: return name
        }
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
    let answered: Bool
    let hasAttachments: Bool

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
        answered = message.answered
        hasAttachments = message.has_attachments
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
    taken(pe_format_size(bytes)) ?? "\(bytes) bytes"
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
